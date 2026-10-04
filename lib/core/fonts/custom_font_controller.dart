import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../errors/app_error_code.dart';
import '../errors/app_exception.dart';
import '../pdf/custom_pdf_fonts.dart';
import 'custom_font_face.dart';
import 'custom_font_store.dart';
import 'font_inspector.dart';
import 'system_font_font_loader.dart';
import 'windows_system_font_service.dart';

/// نتيجة إضافة خط مخصص — تحمل التحذيرات غير المُعطِّلة لعرضها للمستخدم.
class CustomFontAddResult {
  const CustomFontAddResult({
    required this.face,
    required this.inspection,
    required this.replaced,
  });

  final CustomFontFace face;
  final FontInspection inspection;

  /// هل استبدلت الإضافة وجهاً سابقاً بنفس (العائلة، الوزن)؟
  final bool replaced;

  /// تحذيرات واضحة للمستخدم (لا تمنع الاستخدام).
  List<String> get warningsAr => <String>[
        if (!inspection.supportsArabicPdf)
          'هذا الخط لا يغطي كل صور الحروف العربية المتصلة '
              '(${inspection.arabicCoverageLabel} + لام-ألف '
              '${inspection.lamAlefCoverageLabel})، لذلك قد تظهر مربعات فارغة '
              'في الطباعة. الخط مناسب للنصوص اللاتينية أو العرض في الواجهة.',
      ];
}

/// المحرّك الديناميكي للخطوط المخصصة.
///
/// المسؤولية: استقبال بايتات ملف خط من المستخدم ← فحصه ← تسجيله في
/// **مكانين** ← حفظه محلياً:
/// 1) `FontLoader` الخاص بفلاتر: ليظهر الخط فوراً في محرر القوالب.
/// 2) `CustomPdfFonts`: ليرسم به محرّك الـ PDF داخل نفس الجلسة.
///
/// الحالة تُحفظ محلياً فقط (‎SharedPreferences/ملف في مجلد بيانات التطبيق)،
/// ويُعاد تسجيلها عند بدء التشغيل عبر [restore] — بلا أي طلب شبكة.
class CustomFontController extends ChangeNotifier {
  CustomFontController({
    CustomFontStore? store,
    this.maxBytes = 4 * 1024 * 1024,
  }) : _store = store ?? SharedPreferencesCustomFontStore();

  /// نسخة واحدة للتطبيق كله (تُحقن في شجرة الواجهة بلا تمرير يدوي).
  static CustomFontController? _instance;

  static CustomFontController get instance =>
      _instance ??= CustomFontController();

  static set instance(CustomFontController value) => _instance = value;

  /// أكبر حجم مسموح لملف خط واحد (4MB).
  final int maxBytes;

  final CustomFontStore _store;

  final List<CustomFontFace> _faces = <CustomFontFace>[];

  /// مفاتيح سُجّلت فعلاً في `FontLoader` — التسجيل عملية لا تُلغى في فلاتر،
  /// لذلك نتتبّعها هنا حتى لا نكرّرها (التكرار يرمي استثناء).
  static final Set<String> _uiRegistered = <String>{};

  /// عائلات خطوط النظام المكتشفة (Windows فقط) — تُعرض في منتقي الخطوط.
  List<String> _systemFamilies = const <String>[];

  /// هل جرى فحص خطوط النظام مرة واحدة على الأقل؟
  bool _systemFontsScanned = false;

  bool _restored = false;
  bool get isRestored => _restored;

  /// كل الأوجه المرفوعة، مرتبة بالاسم ثم بالوزن (لثبات ترتيب القوائم).
  List<CustomFontFace> get faces {
    final List<CustomFontFace> sorted = <CustomFontFace>[..._faces];
    sorted.sort((CustomFontFace a, CustomFontFace b) {
      final int byName = a.displayName.compareTo(b.displayName);
      return byName != 0 ? byName : a.weight.compareTo(b.weight);
    });
    return List<CustomFontFace>.unmodifiable(sorted);
  }

  /// أسماء العائلات المخصصة (بلا تكرار) — بقائمة اختيار الخط في المحرر.
  List<String> get families {
    final Set<String> names = <String>{};
    for (final CustomFontFace face in faces) {
      names.add(face.family);
    }
    return names.toList(growable: false);
  }

  bool get isEmpty => _faces.isEmpty;

  /// مجموع الحجم المحفوظ محلياً.
  int get totalBytes =>
      _faces.fold<int>(0, (int sum, CustomFontFace f) => sum + f.byteSize);

  CustomFontFace? faceOf(String? family, {int? weight}) {
    if (family == null) return null;
    for (final CustomFontFace face in _faces) {
      if (face.family == family && (weight == null || face.weight == weight)) {
        return face;
      }
    }
    return null;
  }

  /// الاسم المعروض لعائلة مخصصة (بلا بادئة).
  ///
  /// إن لم تُعرف العائلة (قالب يشير لخط محذوف) يُعرض الاسم بلا البادئة التقنية
  /// بدل إظهار مفتاح التسجيل الخام للمستخدم.
  String displayNameOf(String family) {
    final CustomFontFace? face = faceOf(family);
    if (face != null) return face.displayName;
    return family.startsWith(CustomFontFace.familyPrefix)
        ? family.substring(CustomFontFace.familyPrefix.length)
        : family;
  }

  /// هل الخط مسجَّل وجاهز في الواجهة؟
  bool isRegisteredWithUi(String family) => _uiRegistered.contains(family);

  /// عائلات خطوط النظام المكتشفة على هذا الجهاز (Windows).
  List<String> get systemFamilies => _systemFamilies;

  bool get hasSystemFonts => _systemFamilies.isNotEmpty;

  // ==========================================================================
  //  خطوط النظام (Windows)
  // ==========================================================================

  /// يفحص خطوط النظام المثبتة ويملأ [systemFamilies] بها.
  ///
  /// آمن للاستدعاء أكثر من مرة (يعمل مرة واحدة إلا مع `force`)، ولا يرمي:
  /// على الويب/الجوال يبقى الفراغ فوراً بلا أي خطأ.
  Future<void> scanSystemFonts({bool force = false}) async {
    if (_systemFontsScanned && !force) return;
    _systemFontsScanned = true;
    if (!WindowsSystemFontService.isSupported) return;
    try {
      final WindowsFontDiscoveryResult result =
          await WindowsSystemFontService.discover(
        onError: (String source, String error) => debugPrint(
          '[الخطوط المخصصة] فحص خطوط النظام ($source): $error',
        ),
      );
      _systemFamilies = result.families
          .where((WindowsSystemFontFamily f) => f.filePaths.isNotEmpty)
          .map((WindowsSystemFontFamily f) => f.displayName)
          .toList(growable: false);
    } on Object catch (error) {
      debugPrint('[الخطوط المخصصة] تعذّر فحص خطوط النظام: $error');
    }
    notifyListeners();
  }

  /// يسجّل عائلة خط نظام في محرّك خطوط فلاتر عند اختيارها (تحميل ديناميكي).
  ///
  /// يُرجع `true` عند الجهوزية للرسم. يُضاف الخط لمحرّك الطباعة أيضاً متى كان
  /// TrueType؛ خطوط النظام قد تكون CFF فلا يقبلها المحرّك — نتعامل مع الفشل
  /// بهدوء بدل الانهيار.
  Future<bool> registerSystemFont(String family) async {
    final String normalized = family.trim();
    if (normalized.isEmpty) return false;
    if (_uiRegistered.contains(normalized)) return true;

    final SystemFontLoadResult? loaded =
        await SystemFontFontLoader.loadSystemFont(
      normalized,
      onError: (String error) =>
          debugPrint('[الخطوط المخصصة] $error'),
    );
    if (loaded == null) return false;

    _uiRegistered.add(normalized);

    try {
      final bytes = loaded.byteData.buffer.asUint8List(
        loaded.byteData.offsetInBytes,
        loaded.byteData.lengthInBytes,
      );
      CustomPdfFonts.register(normalized, bytes);
    } on Object catch (error) {
      debugPrint(
        '[الخطوط المخصصة] تعذّر تسجيل «$normalized» في الطباعة: $error',
      );
    }

    notifyListeners();
    return true;
  }

  // ==========================================================================
  //  الاستعادة عند بدء التشغيل
  // ==========================================================================

  /// يقرأ المكتبة المحفوظة ويعيد تسجيل كل خط في الواجهة ومحرّك الطباعة.
  ///
  /// آمن للاستدعاء أكثر من مرة، ولا يرمي: أي خط تالف يُتجاهل ويُسجَّل تحذير في
  /// وضع التصحيح حتى لا يمنع خط واحد التطبيق من الإقلاع.
  Future<void> restore({bool force = false}) async {
    if (_restored && !force) return;
    _faces.clear();
    try {
      final List<CustomFontFace> saved = await _store.loadAll();
      for (final CustomFontFace face in saved) {
        if (!await _register(face)) continue;
        _faces.add(face);
      }
    } catch (error, stackTrace) {
      debugPrint('[الخطوط المخصصة] تعذّرت الاستعادة: $error\n$stackTrace');
    }
    _restored = true;
    notifyListeners();
  }

  // ==========================================================================
  //  الإضافة والحذف
  // ==========================================================================

  /// إضافة خط من بايتاته (يأتي من منتقي الملفات — لا يُقرأ من القرص هنا حتى
  /// يعمل الكود على الويب وسطح المكتب بلا فروع).
  Future<CustomFontAddResult> addFont({
    required String fileName,
    required Uint8List bytes,
  }) async {
    if (bytes.lengthInBytes > maxBytes) {
      throw AppException(
        AppErrorCode.validation,
        message: 'حجم ملف الخط يتجاوز ${(maxBytes / (1024 * 1024)).round()}MB. '
            'اختر ملفاً أصغر أو نسخة مضغوطة من الخط.',
      );
    }

    final FontInspection inspection = FontInspector.inspect(bytes);
    if (!inspection.isValid) {
      throw AppException(
        AppErrorCode.validation,
        message: inspection.errorAr ?? 'ملف الخط غير صالح.',
      );
    }
    // خطوط CFF/PostScript (‎.otf) بلا محيطات `glyf` يرسمها محرّك الطباعة
    // بحروف مشوّهة أو فارغة — نرفضها هنا برسالة عربية واضحة بدل مفاجأة عند
    // التصدير. الخطوط المضمّنة كلها TrueType فتُمرّ.
    if (!inspection.hasTrueTypeOutlines) {
      throw const AppException(
        AppErrorCode.validation,
        message: 'هذا الخط بحدود CFF/PostScript (ملف .otf) لا يستطيع محرّك '
            'الطباعة رسمها، فتظهر الحروف العربية مشوّهة أو فارغة. استخدم نسخة '
            'TrueType (‎.ttf) من الخط نفسه.',
      );
    }

    final String displayName = CustomFontFace.stripWeightSuffix(
      inspection.familyName?.isNotEmpty == true
          ? inspection.familyName!
          : CustomFontFace.displayNameFromFileName(fileName),
    );
    final int weight = inspection.inferredWeight;
    final String family = CustomFontFace.familyKeyFor(displayName);

    final CustomFontFace face = CustomFontFace(
      family: family,
      displayName: displayName,
      fileName: fileName.replaceAll('\\', '/').split('/').last,
      base64Data: base64Encode(bytes),
      weight: weight,
      arabicReady: inspection.supportsArabicPdf,
      addedAt: DateTime.now(),
    );

    final int existingIndex = _faces.indexWhere(
      (CustomFontFace f) => f.family == family && f.weight == weight,
    );
    final bool replaced = existingIndex >= 0;

    // التسجيل في محرّك الطباعة أولاً: إن رفض الملف لا نُفسد المكتبة المحفوظة.
    CustomPdfFonts.register(family, bytes, weight: weight);
    await _registerWithUi(face);

    if (replaced) {
      _faces[existingIndex] = face;
    } else {
      _faces.add(face);
    }

    await _persist();
    notifyListeners();
    return CustomFontAddResult(
      face: face,
      inspection: inspection,
      replaced: replaced,
    );
  }

  /// حذف عائلة كاملة (كل أوزانها) من المكتبة المحلية.
  ///
  /// ملاحظة معمارية: لا يمكن إلغاء تسجيل خط من `FontLoader` في فلاتر، لذلك
  /// يبقى الخط صالحاً للعرض في الجلسة الحالية، بينما يُمنع فوراً في تدفق
  /// الطباعة (لأن `CustomPdfFonts` يُنظّف) ويختفي من القوائم. القوالب التي
  /// تشير إليه ترجع تلقائياً للخط المضمّن بدل الفشل.
  Future<void> removeFont(String family) async {
    final bool had = _faces.any((CustomFontFace f) => f.family == family);
    _faces.removeWhere((CustomFontFace f) => f.family == family);
    CustomPdfFonts.remove(family);
    if (!had) return;
    await _persist();
    notifyListeners();
  }

  /// حذف الكل (تُستخدم في الاختبارات وأداة «إعادة تعيين»).
  Future<void> clear() async {
    _faces.clear();
    CustomPdfFonts.clear();
    await _persist();
    notifyListeners();
  }

  // ==========================================================================
  //  داخلي
  // ==========================================================================

  Future<void> _persist() => _store.saveAll(List<CustomFontFace>.from(_faces));

  /// تسجيل كامل (واجهة + طباعة). يعيد `false` إن تعذّر أي منهما.
  ///
  /// يُعاد الفحص هنا (لا عند الحفظ فقط) لأن المكتبة المحفوظة قد تكون تالفة أو
  /// مبتورة، ولا يجوز لسجل واحد أن يُدخل خطاً معطوباً إلى محرّك الطباعة.
  Future<bool> _register(CustomFontFace face) async {
    final Uint8List bytes;
    try {
      bytes = face.bytes;
    } catch (error) {
      debugPrint('[الخطوط المخصصة] تجاهل سجلاً ببيانات تالفة '
          '${face.displayName}: $error');
      return false;
    }
    final FontInspection inspection = FontInspector.inspect(bytes);
    if (!inspection.isValid || !inspection.hasTrueTypeOutlines) {
      debugPrint('[الخطوط المخصصة] تجاهل خطاً غير قابل للرسم في الـ PDF '
          '${face.displayName} (محيطات CFF؟ ${inspection.isOpenTypeCff})');
      return false;
    }
    try {
      CustomPdfFonts.register(face.family, bytes, weight: face.weight);
    } catch (error) {
      debugPrint('[الخطوط المخصصة] تجاهل خط غير قابل للطباعة '
          '${face.displayName}: $error');
      return false;
    }
    await _registerWithUi(face);
    return true;
  }

  Future<void> _registerWithUi(CustomFontFace face) async {
    if (!_uiRegistered.add(face.family)) return;
    try {
      final FontLoader loader = FontLoader(face.family)
        ..addFont(
          Future<ByteData>.value(ByteData.sublistView(face.bytes)),
        );
      await loader.load();
    } catch (error) {
      _uiRegistered.remove(face.family);
      debugPrint('[الخطوط المخصصة] تعذّر عرض ${face.displayName} في الواجهة: '
          '$error');
    }
  }
}
