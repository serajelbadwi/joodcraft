import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../constants/app_constants.dart';
import '../models/template_document.dart';
import 'local_projects_database.dart';
import 'project_record.dart';

/// محرّك المشاريع المحلية: قائمة واحدة في الذاكرة + صفّ واحد لكل مشروع على
/// القرص.
///
/// **لماذا في الذاكرة أصلاً؟** سرعة التحميل الفوري: تُقرأ القاعدة **مرة واحدة**
/// عند الإقلاع ([restore]) فتصبح كل القراءات اللاحقة في الشاشات (لوحة التحكم،
/// المكتبة، منتقي القوالب) قراءة قائمة من الذاكرة بلا أي إدخال/إخراج، وعند
/// الحفظ يُكتب الصفّ وحده على القرص ثم تُحدَّث القائمة في الذاكرة فوراً.
///
/// لا شبكة في هذا الملف إطلاقاً: لا Supabase ولا أي عنوان بعيد.
class ProjectsController extends ChangeNotifier {
  ProjectsController({LocalProjectsDatabase? database})
      : _database = database ?? HiveProjectsDatabase();

  /// نسخة واحدة للتطبيق كله (مثل `AssetsController`)، تُستهلك بلا تمرير يدوي.
  static ProjectsController? _instance;

  static ProjectsController get instance =>
      _instance ??= ProjectsController();

  static set instance(ProjectsController value) => _instance = value;

  final LocalProjectsDatabase _database;
  LocalProjectsDatabase? _active;
  bool _usingFallback = false;

  final List<ProjectRecord> _projects = <ProjectRecord>[];
  bool _loaded = false;
  bool _loading = false;

  /// هل قُرئت القاعدة في هذه الجلسة؟ (يعني أن القراءات فورية الآن.)
  bool get isLoaded => _loaded;

  bool get isLoading => _loading;

  /// هل نكتب فعلياً على القرص؟ `false` يعني أننا تراجعنا إلى الذاكرة فقط
  /// (منصة لا تدعم فتح المخزن) — يُعرض للمستخدم بصراحة بلا ادّعاء الحفظ.
  bool get isPersistent => _loaded && !_usingFallback;

  /// كل المشاريع، الأحدث تعديلاً أولاً.
  List<ProjectRecord> get projects =>
      List<ProjectRecord>.unmodifiable(_projects);

  int get count => _projects.length;

  bool get isEmpty => _projects.isEmpty;

  /// أحدث [limit] مشروع — لبطاقات «المشاريع الأخيرة» في لوحة التحكم.
  List<ProjectRecord> recent({int limit = 6}) => _projects.length <= limit
      ? List<ProjectRecord>.unmodifiable(_projects)
      : List<ProjectRecord>.unmodifiable(_projects.take(limit));

  ProjectRecord? findById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final ProjectRecord record in _projects) {
      if (record.id == id) return record;
    }
    return null;
  }

  /// يفتح القاعدة ويقرأ الجدول مرة واحدة عند الإقلاع.
  Future<void> restore() async {
    if (_loaded) return;
    await refresh();
  }

  /// إعادة قراءة الجدول من المخزن (بعد تعديل خارجي مثلاً).
  Future<void> refresh() async {
    _loading = true;
    _notify();
    try {
      final LocalProjectsDatabase database = await _databaseOrFallback();
      final List<ProjectRecord> records = await database.selectAll();
      _projects
        ..clear()
        ..addAll(records);
      _loaded = true;
    } catch (error) {
      debugPrint('[المشاريع المحلية] تعذّرت قراءة الجدول: $error');
      _loaded = true;
    } finally {
      _loading = false;
      _notify();
    }
  }

  /// حفظ مشروع (إنشاء أو تحديث) — يكتب صفّاً واحداً فقط ثم يحدّث الذاكرة.
  Future<ProjectRecord> save({
    String? id,
    required String title,
    required TemplateDocument document,
    required TemplateCategory category,
    bool isPublic = false,
    DateTime? now,
    String? thumbnailPath,
  }) async {
    final DateTime timestamp = now ?? DateTime.now();
    final ProjectRecord? existing = findById(id);
    final String finalId = (id ?? '').trim().isEmpty
        ? _newLocalId(timestamp)
        : id!.trim();
    final String cleanTitle =
        title.trim().isEmpty ? 'مشروع بلا عنوان' : title.trim();

    final ProjectRecord record = ProjectRecord(
      id: finalId,
      title: cleanTitle,
      width: document.pageWidthPt,
      height: document.pageHeightPt,
      layersData: _encodeLayers(document),
      updatedAt: timestamp,
      thumbnailPath: thumbnailPath ?? existing?.thumbnailPath,
      category: category,
      orientation: document.orientation,
      isPublic: isPublic,
      createdAt: existing?.createdAt ?? timestamp,
    );

    await upsert(record);
    return record;
  }

  /// إدراج/تحديث صفّ جاهز (تستعمله المحوّلات القادمة من واجهات القوالب).
  Future<void> upsert(ProjectRecord record) async {
    final LocalProjectsDatabase database = await _databaseOrFallback();
    try {
      await database.upsert(record);
    } catch (error) {
      debugPrint('[المشاريع المحلية] تعذّر حفظ المشروع: $error');
      throw StateError('تعذّر الحفظ في المخزن المحلي.');
    }
    final int index =
        _projects.indexWhere((ProjectRecord item) => item.id == record.id);
    if (index >= 0) {
      _projects[index] = record;
    } else {
      _projects.add(record);
    }
    _sortByUpdated();
    _loaded = true;
    _notify();
  }

  /// إدراج/تحديث دفعة صفوف بأقل كتابة ممكنة.
  Future<void> upsertAll(Iterable<ProjectRecord> records) async {
    final List<ProjectRecord> list = records.toList(growable: false);
    if (list.isEmpty) return;
    final LocalProjectsDatabase database = await _databaseOrFallback();
    try {
      await database.upsertAll(list);
    } catch (error) {
      debugPrint('[المشاريع المحلية] تعذّر حفظ المشاريع: $error');
      throw StateError('تعذّر الحفظ في المخزن المحلي.');
    }
    for (final ProjectRecord record in list) {
      final int index =
          _projects.indexWhere((ProjectRecord item) => item.id == record.id);
      if (index >= 0) {
        _projects[index] = record;
      } else {
        _projects.add(record);
      }
    }
    _sortByUpdated();
    _loaded = true;
    _notify();
  }

  /// ربط صورة مصغّرة محلية بمشروع بعد حفظه (بلا إعادة كتابة الشجرة).
  Future<void> attachThumbnail(String id, String path) async {
    final ProjectRecord? record = findById(id);
    if (record == null || path.trim().isEmpty) return;
    await upsert(record.copyWith(thumbnailPath: path.trim()));
  }

  /// حذف مشروع. لا يرمي.
  Future<void> remove(String id) async {
    final LocalProjectsDatabase database = await _databaseOrFallback();
    try {
      await database.delete(id);
    } catch (error) {
      debugPrint('[المشاريع المحلية] تعذّر حذف المشروع: $error');
    }
    _projects.removeWhere((ProjectRecord item) => item.id == id);
    _notify();
  }

  /// تفريغ الجدول بالكامل — يُستخدم في الاختبارات وفي إعادة الضبط.
  Future<void> clearAll() async {
    final LocalProjectsDatabase database = await _databaseOrFallback();
    try {
      await database.clear();
    } catch (error) {
      debugPrint('[المشاريع المحلية] تعذّر تفريغ الجدول: $error');
    }
    _projects.clear();
    _loaded = true;
    _notify();
  }

  /// إعلام آمن للشجرة.
  ///
  /// القراءة الأولى تُستدعى غالباً من `initState` شاشة تُبنى الآن (المكتبة
  /// مثلاً)، و`notifyListeners` في تلك اللحظة يُسقط الإطار بـ
  /// «markNeedsBuild during build» على أي شاشة تستمع إلى المشاريع (لوحة
  /// التحكم). فنؤجّل الإعلام ما دام الإطار في طور بناء الودجات.
  void _notify() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      scheduleMicrotask(notifyListeners);
      return;
    }
    notifyListeners();
  }

  /// يعيد المحرّك إلى حالته الأولى (بلا قراءة) — للاختبارات.
  @visibleForTesting
  Future<void> reset() async {
    await _active?.clear();
    _active = null;
    _projects.clear();
    _loaded = false;
    _usingFallback = false;
    _notify();
  }

  /// معرّف محلّي فريد.
  ///
  /// الختم الزمني بالميكروثانية لا يكفي وحده: ساعة Windows دقّتها أجزاء من
  /// الميلي ثانية، فحفظان متتاليان قد يحملان القيمة نفسها فيُدهس مشروع بمشروع.
  /// لذلك نُزامن ترقيمياً عند التصادم.
  String _newLocalId(DateTime timestamp) {
    final int stamp = timestamp.microsecondsSinceEpoch;
    String candidate = 'local_$stamp';
    int suffix = 1;
    while (findById(candidate) != null) {
      candidate = 'local_${stamp}_${suffix++}';
    }
    return candidate;
  }

  /// المستند كاملاً مع إصدار المخطط — الصفّ يُخزَّن صالحاً للفتح لاحقاً.
  static String _encodeLayers(TemplateDocument document) => jsonEncode(
        <String, dynamic>{
          ...document.toJson(),
          'schema_version': AppConstants.layoutSchemaVersion,
        },
      );

  /// المخزن الفعّال: التنفيذ المطلوب، وإن تعذّر فتحه (منصة بلا دعم) نتراجع إلى
  /// الذاكرة بدل إسقاط الشاشة.
  Future<LocalProjectsDatabase> _databaseOrFallback() async {
    final LocalProjectsDatabase? active = _active;
    if (active != null) return active;

    try {
      await _database.initialize();
      _active = _database;
      _usingFallback = false;
    } catch (error) {
      debugPrint('[المشاريع المحلية] تعذّر فتح المخزن، نعمل في الذاكرة: $error');
      final InMemoryProjectsDatabase fallback = InMemoryProjectsDatabase();
      await fallback.initialize();
      _active = fallback;
      _usingFallback = true;
    }
    return _active!;
  }

  void _sortByUpdated() {
    _projects.sort((ProjectRecord a, ProjectRecord b) {
      final int byTime = b.updatedAt.compareTo(a.updatedAt);
      return byTime != 0 ? byTime : b.id.compareTo(a.id);
    });
  }
}
