import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'jood_autosave_store.dart';
import 'jood_autosave_store_stub.dart'
    if (dart.library.io) 'jood_autosave_store_io.dart' as io;

/// دالة بناء أرشيف المسودّة — تُستدعى عند لحظة الكتابة لا عند الجدولة، فتقرأ
/// المستند **الأحدث** دائماً. قد تكون متزامنة أو غير متزامنة.
typedef JoodArchiveBuilder = FutureOr<Uint8List> Function();

/// الحفظ التلقائي للمشروع بصيغة ‎.jood‎ مع التعافي من الإغلاق المفاجئ.
///
/// **كيف يعمل؟** كل تعديل يستدعي [schedule] فيُعاد ضبط مؤقّت (Debounce): لا
/// تُكتب المسودّة إلا بعد مرور [debounce] من **آخر** تعديل، فلا تُثقل الكتابة
/// القرص أثناء السحب المتواصل. البناء والكتابة غير حاجزين (‎async I/O‎) فلا
/// تتجمّد الواجهة، والكتابة على القرص ذرّية (انظر [FileJoodAutosaveStore]).
///
/// **التعافي:** المسودّة تُكتب في ملف واحد (`autosave_draft.jood`)؛ عند الإقلاع
/// يستدعي المحرّر [recover] فيعيد بايتات آخر جلسة — ملف ‎.jood‎ كامل قابل للفتح
/// كأنه مشروع عادي. وبعد حفظ صريح ينجح يستدعي المحرّر [discard] فتُمسح المسودّة.
class JoodAutosaveService extends ChangeNotifier {
  JoodAutosaveService({
    required JoodArchiveBuilder build,
    JoodAutosaveStore? store,
    this.debounce = const Duration(seconds: 3),
  })  : _build = build,
        _store = store ?? io.defaultJoodAutosaveStore() {
    _active.add(this);
  }

  /// كل خدمات الحفظ التلقائي النشطة الآن (محرّر واحد لكل مثيل) — سجلّ خفيف
  /// يتيح تفريغ مسودّات **كل** المشاريع المفتوحة دفعةً واحدة قبل إجراءٍ قد
  /// يُنهي الجلسة، كتبديل الحساب السريع، فلا يضيع ما لم يُكتب بعد.
  static final Set<JoodAutosaveService> _active = <JoodAutosaveService>{};

  /// الخدمات النشطة حالياً (المحرّرات المفتوحة).
  static List<JoodAutosaveService> get activeServices =>
      List<JoodAutosaveService>.unmodifiable(_active);

  /// يكتب كل مسودّات المشاريع المفتوحة فوراً (حاجزاً بلا استثناء).
  ///
  /// لا يرمي: كل خدمة تبتلع خطأ كتابتها في [lastError]، فيمرّ تبديل الحساب
  /// حتى لو تعذّرت كتابة مسودّة واحدة.
  static Future<void> flushAll() async {
    for (final JoodAutosaveService service
        in List<JoodAutosaveService>.of(_active)) {
      await service.flush();
    }
  }

  /// المهلة الافتراضية: الكتابة بعد 3 ثوانٍ من آخر تعديل.
  final Duration debounce;

  final JoodArchiveBuilder _build;
  final JoodAutosaveStore _store;

  Timer? _timer;
  bool _dirty = false;
  bool _writing = false;
  bool _pendingWhileWriting = false;
  DateTime? _lastSavedAt;
  Object? _lastError;

  /// هل هناك تعديلات لم تُكتب بعد؟
  bool get isDirty => _dirty;

  /// هل الكتابة جارية الآن؟ (يستخدمه مؤشّر الحالة في شريط المحرّر)
  bool get isSaving => _writing;

  /// هل جرت كتابة ناجحة مرة واحدة على الأقل في هذه الجلسة؟
  bool get hasSavedOnce => _lastSavedAt != null;

  /// زمن آخر كتابة ناجحة للمسودّة (أو `null`).
  DateTime? get lastSavedAt => _lastSavedAt;

  /// آخر خطأ كتابة، إن وقع (للتشخيص والعرض).
  Object? get lastError => _lastError;

  /// يجدول كتابة مؤجّلة — يُستدعى من **كل** تعديل على المستند.
  ///
  /// إعادة الضبط عند كل نداء هي جوهر التمهيد: الموقّت يُلغى ويُعاد إنشاؤه، فلا
  /// تُكتب المسودّة إلا بعد سكون المستخدم.
  void schedule() {
    _dirty = true;
    _timer?.cancel();
    _timer = Timer(debounce, () {
      _timer = null;
      unawaited(_writeNow());
    });
    _notify();
  }

  /// يكتب المسودّة **فوراً** (حاجزاً) — عند الإغلاق أو قبل تصدير/حفظ صريح.
  ///
  /// لا يرمي: ينتظر أي كتابة جارية ثم يكتب النسخة الأحدث.
  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    // ننتظر انتهاء الكتابة الجارية إن وُجدت (بلا تجميد: تخطيط دوري قصير).
    while (_writing) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
    _dirty = true;
    await _writeNow();
  }

  /// يقرأ بايتات آخر مسودّة محفوظة — للاستعادة التلقائية بعد إغلاق مفاجئ.
  ///
  /// يعيد `null` إن لم تكن هناك مسودّة (الويب، أو أول تشغيل، أو مسودّة حُذفت
  /// بعد حفظ صريح).
  Future<Uint8List?> recover() async {
    final Uint8List? bytes = await _store.read();
    return (bytes == null || bytes.isEmpty) ? null : bytes;
  }

  /// يمسح المسودّة (يُستدعى بعد حفظ صريح ناجح فلا تظهر استعادة زائفة لاحقاً).
  Future<void> discard() async {
    _timer?.cancel();
    _timer = null;
    _dirty = false;
    await _store.delete();
  }

  /// يُلغي الموقّت عند التخلّص من المحرّر. لا يكتب (الكتابة قبلها عبر [flush]).
  @override
  void dispose() {
    _active.remove(this);
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  /// إعلام آمن للواجهة — لا يُسقط الإطار إن وقع أثناء طور البناء.
  void _notify() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      scheduleMicrotask(notifyListeners);
      return;
    }
    notifyListeners();
  }

  Future<void> _writeNow() async {
    if (_writing) {
      // كتابة جارية: اطلب كتابة أخرى بعدها كي لا تفوت أحدث نسخة.
      _pendingWhileWriting = true;
      return;
    }
    _writing = true;
    _notify();
    try {
      do {
        _pendingWhileWriting = false;
        final Uint8List bytes = await _build();
        await _store.write(bytes);
        _lastSavedAt = DateTime.now();
        _lastError = null;
        // لم يَعُد هناك تعديل أحدث من المكتوب.
        _dirty = _pendingWhileWriting;
      } while (_pendingWhileWriting);
    } catch (error, stackTrace) {
      // الفشل لا يُسقط التطبيق: نُبقي [isDirty] صحيحاً ليُعاد المحاولة.
      _lastError = error;
      debugPrint('[الحفظ التلقائي] تعذّر بناء/كتابة المسودّة: '
          '$error\n$stackTrace');
    } finally {
      _writing = false;
      _notify();
    }
  }
}
