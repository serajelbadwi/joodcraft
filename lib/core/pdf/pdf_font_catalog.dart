import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

import '../constants/app_assets.dart';
import '../errors/app_error_code.dart';
import '../errors/app_exception.dart';
import '../fonts/font_inspector.dart';
import 'custom_pdf_fonts.dart';

/// عائلات الخطوط المدعومة في محرّك الـ PDF.
///
/// ⚠️ قاعدة تقنية مهمة اكتُشفت بالقياس الفعلي لملفات الخطوط:
/// محرّك الطباعة في دارت يرسم الحروف العربية **بصيغ العرض المتصلة**
/// (Arabic Presentation Forms-B / U+FE70..FEFC) لأن جداول GSUB لا تُنفَّذ هنا.
/// لذلك يجب أن يحتوي الخط على هذه الصيغ داخل `cmap`، وإلا ظهرت مربعات فارغة.
///
/// | الخط | تغطية U+FE80..FEF4 |
/// | --- | --- |
/// | IBM Plex Sans Arabic | 117/117 ✅ |
/// | Amiri | 117/117 ✅ |
/// | Cairo | 117/117 ✅ (بعد وصْل صور الحروف المعزولة إلى محارفها الأم) |
/// | Tajawal | 117/117 ✅ (بعد الوصْل نفسه) |
/// | Noto Sans Arabic | 117/117 ✅ |
///
/// ملفات الخطوط المحزومة تُفحَص آلياً في `test/unit/font_inspector_test.dart`،
/// وأداة الوصْل التي أصلحت Cairo وTajawal هي `tool/patch_arabic_cmaps.py`.
enum PdfFontFamily {
  plex(
    jsonValue: 'plex',
    labelAr: 'IBM Plex Sans Arabic',
    descriptionAr: 'خط حديث Sans — مناسب للشهادات والترويسات',
    uiFamily: AppAssets.plexArabicFont,
  ),
  amiri(
    jsonValue: 'amiri',
    labelAr: 'Amiri',
    descriptionAr: 'خط نسخ تقليدي — مناسب للعقود والوثائق الرسمية',
    uiFamily: AppAssets.amiriFont,
  ),
  cairo(
    jsonValue: 'cairo',
    labelAr: 'Cairo',
    descriptionAr: 'Sans عصري دقيق — مناسب للعناوين والترويسات',
    uiFamily: AppAssets.cairoFont,
  ),
  tajawal(
    jsonValue: 'tajawal',
    labelAr: 'Tajawal',
    descriptionAr: 'Sans هندسي أنيق — مناسب للشهادات الحديثة',
    uiFamily: AppAssets.tajawalFont,
  ),
  noto(
    jsonValue: 'noto',
    labelAr: 'Noto Sans Arabic',
    descriptionAr: 'الأوسع تغطية للمحارف العربية — مناسب للنصوص المختلطة',
    uiFamily: AppAssets.notoArabicFont,
  );

  const PdfFontFamily({
    required this.jsonValue,
    required this.labelAr,
    required this.descriptionAr,
    required this.uiFamily,
    // يُحتفظ بالمعامل لتوسيع القائمة لاحقاً؛ لا عائلة محزومة تحقّق القيمة بعد
    // أن صارت تغطية صور الحروف كاملة في كل الملفات المضمّنة (فَحصها في
    // test/unit/font_inspector_test.dart).
    // ignore: unused_element_parameter
    this.usableInPdf = true,
  });

  final String jsonValue;
  final String labelAr;
  final String descriptionAr;

  /// اسم العائلة المسجَّل في `pubspec.yaml` والمستخدم في واجهة فلاتر
  /// (يجب أن يطابق اسم الخط في `ThemeData` كي تكون المعاينة مطابقة للطباعة).
  final String uiFamily;

  /// هل يصلح الرسم في الـ PDF (يحتوي صور الحروف المتصلة)؟
  final bool usableInPdf;

  /// العائلات التي يجوز استخدامها داخل قوالب الـ PDF.
  static List<PdfFontFamily> get pdfFamilies =>
      values.where((PdfFontFamily f) => f.usableInPdf).toList();

  /// قراءة آمنة من الـ JSON مع الرجوع للافتراضي عند قيمة غير معروفة.
  static PdfFontFamily fromJson(String? value) {
    if (value == null) return plex;
    final String needle = value.trim().toLowerCase();
    return values.firstWhere(
      (PdfFontFamily f) => f.jsonValue == needle || f.labelAr == value.trim(),
      orElse: () => plex,
    );
  }
}

/// أوزان الخطوط المدعومة.
enum PdfFontWeight {
  regular(400, 'regular'),
  semiBold(600, 'semiBold'),
  bold(700, 'bold');

  const PdfFontWeight(this.value, this.jsonValue);

  final int value;
  final String jsonValue;

  static PdfFontWeight fromJson(Object? value) {
    if (value is int) return fromValue(value);
    if (value is num) return fromValue(value.toInt());
    final String needle = '${value ?? ''}'.trim().toLowerCase();
    if (needle == 'bold' || needle == '700' || needle == '800') return bold;
    if (needle == 'semibold' || needle == '600' || needle == 'medium') {
      return semiBold;
    }
    if (needle == '500') return semiBold;
    return regular;
  }

  static PdfFontWeight fromValue(int value) {
    if (value >= 700) return bold;
    if (value >= 500) return semiBold;
    return regular;
  }
}

/// مجموعة الخطوط الجاهزة للرسم (تُحمَّل مرة واحدة).
class PdfFontSet {
  const PdfFontSet._(
    this._fonts,
    this._bytesByKey,
    this.loadedFontFileCount,
    this._familyCodePoints,
    this._bundledCodePoints,
  );

  final Map<String, pw.Font> _fonts;

  /// بايتات كل خط بالمفتاح `family:weight` — تُستخدم لإعادة بناء المجموعة داخل
  /// isolate آخر (لا تُنقل كائنات `pw.Font`، بل بايتات TTF).
  final Map<String, Uint8List> _bytesByKey;

  /// عدد ملفات الخطوط المقروءة فعلياً من الأصول (بلا تكرار).
  final int loadedFontFileCount;

  /// مفتاح خط الاحتياط العالمي في `_fonts`/`_bytesByKey` (الخط الكامل للصينية).
  static const String notoScFontKey = 'jood:notoSc';

  /// مفتاح خط احتياط السيريلية (Noto Sans المُصغَّر) في `_fonts`/`_bytesByKey`.
  static const String notoCyrillicFontKey = 'jood:notoCyrillic';

  /// محارف كل عائلة محزومة (لاختيار الخط حسب كتابة النص).
  final Map<PdfFontFamily, Set<int>> _familyCodePoints;

  /// اتحاد محارف كل الخطوط المحزومة (بما فيها خط الاحتياط العالمي) — أساس
  /// فحص التغطية الدقيق: أي محرف هنا يُرسم فعلاً، فلا تحذير كاذب.
  final Set<int> _bundledCodePoints;

  static const Map<PdfFontFamily, Map<PdfFontWeight, String>> _sources =
      <PdfFontFamily, Map<PdfFontWeight, String>>{
    PdfFontFamily.plex: <PdfFontWeight, String>{
      PdfFontWeight.regular: AppAssets.pdfPlexRegular,
      PdfFontWeight.semiBold: AppAssets.pdfPlexSemiBold,
      PdfFontWeight.bold: AppAssets.pdfPlexBold,
    },
    PdfFontFamily.amiri: <PdfFontWeight, String>{
      PdfFontWeight.regular: AppAssets.pdfAmiriRegular,
      // Amiri لا يملك وزناً متوسطاً — نستخدم العريض بدلاً منه.
      PdfFontWeight.semiBold: AppAssets.pdfAmiriBold,
      PdfFontWeight.bold: AppAssets.pdfAmiriBold,
    },
    PdfFontFamily.cairo: <PdfFontWeight, String>{
      PdfFontWeight.regular: AppAssets.pdfCairoRegular,
      PdfFontWeight.semiBold: AppAssets.pdfCairoSemiBold,
      PdfFontWeight.bold: AppAssets.pdfCairoBold,
    },
    PdfFontFamily.tajawal: <PdfFontWeight, String>{
      PdfFontWeight.regular: AppAssets.pdfTajawalRegular,
      PdfFontWeight.semiBold: AppAssets.pdfTajawalMedium,
      PdfFontWeight.bold: AppAssets.pdfTajawalBold,
    },
    PdfFontFamily.noto: <PdfFontWeight, String>{
      PdfFontWeight.regular: AppAssets.pdfNotoArabicRegular,
      PdfFontWeight.semiBold: AppAssets.pdfNotoArabicSemiBold,
      PdfFontWeight.bold: AppAssets.pdfNotoArabicBold,
    },
  };

  static Future<PdfFontSet>? _cached;

  /// الخط المطلوب، مع الرجوع التلقائي إلى خط آمن عند عائلة غير صالحة للطباعة.
  ///
  /// إن مُرِّر [customFamily] (خط رفعه المستخدم عبر المحرّك الديناميكي) فهو
  /// **المقدَّم**، ويُرجَع الخط المضمّن تلقائياً إن لم يكن الخط المخصص مسجَّلاً
  /// بعد (قالب محفوظ على جهاز آخر مثلاً).
  pw.Font resolve(
    PdfFontFamily family, [
    PdfFontWeight weight = PdfFontWeight.regular,
    String? customFamily,
  ]) {
    if (customFamily != null && customFamily.trim().isNotEmpty) {
      final pw.Font? custom =
          CustomPdfFonts.resolve(customFamily.trim(), weight.value);
      if (custom != null) return custom;
    }
    final PdfFontFamily safeFamily = family.usableInPdf ? family : defaultFamily;
    final pw.Font? font = _fonts['${safeFamily.jsonValue}:${weight.jsonValue}'];
    if (font != null) return font;
    final pw.Font? fallback =
        _fonts['${defaultFamily.jsonValue}:${PdfFontWeight.regular.jsonValue}'];
    if (fallback == null) {
      throw const AppException(
        AppErrorCode.unknown,
        message: 'لم تُحمَّل الخطوط المضمّنة. تأكد من تنفيذ PdfFontSet.load.',
      );
    }
    return fallback;
  }

  /// العائلات المخصّصة (التي رفعها المستخدم) المتاحة للرسم الآن.
  ///
  /// تُستخدم لفحص تغطية الكتابات غير العربية: الخط المخصّص الذي يذكره العنصر
  /// صراحةً هو آلية الاحتياط المتاحة لما لا يغطّيه خط محزوم (كالصينية). راجع
  /// `PdfScriptCoverage.unsupportedInDocument`.
  Set<String> get registeredCustomFamilies => CustomPdfFonts.families;

  /// الخطوط الاحتياطية العالمية المُمرَّرة مع كل نمط نصّي.
  ///
  /// محرّك الـ PDF يستبدل المحرف الواحد بخط بديل إذا لم يدعمه الخط الأساسي
  /// (`pw.TextStyle.fontFallback`)، فتضمن هذه القائمة رسم السيريلية واللاتينية
  /// الممتدة التركية (Noto Sans) والصينية (Noto Sans SC) وصور العرض الأوردية
  /// (Noto Sans Arabic) بلا مربعات فارغة. وما يُستخدم منها فقط يُضمَّن مصغَّراً،
  /// فلا يتضخّم الملف.
  ///
  /// **الترتيب مقصود:** خط Noto Sans (لاتيني/سيريلي) **أوّلًا** كي تُرسم المحارف
  /// التركية الممتدة (ğ/ş/İ/ı) بأسلوب لاتيني محايد، لا بأساليب عربية (Cairo/
  /// Tajawal) مخالفة لروح خط المستخدم — فالمحرّك يأخذ أول خط يدعم المحرف.
  List<pw.Font> get fallbackFonts => <pw.Font>[
        if (_fonts[notoCyrillicFontKey] != null)
          _fonts[notoCyrillicFontKey]!,
        if (_fonts['cairo:regular'] != null) _fonts['cairo:regular']!,
        if (_fonts['noto:regular'] != null) _fonts['noto:regular']!,
        if (_fonts[notoScFontKey] != null) _fonts[notoScFontKey]!,
      ];

  /// اتحاد محارف كل الخطوط المحزومة (بما فيها خط الاحتياط).
  Set<int> get bundledCodePoints => _bundledCodePoints;

  /// هل يرسم أي خط محزوم المحرف [codePoint]؟
  bool coversCodePoint(int codePoint) => _bundledCodePoints.contains(codePoint);

  /// هل يغطّي الخط المخصّص/النظامي [family] المحرف [codePoint]؟
  bool customFontCovers(String? family, int codePoint) {
    if (family == null || family.trim().isEmpty) return false;
    final Set<int>? codePoints = CustomPdfFonts.codePointsOf(family.trim());
    return codePoints != null && codePoints.contains(codePoint);
  }

  /// أفضل عائلة محزومة لنصّ ما: يُحترم الخط المختار إن كان يغطّي كل محارف النص،
  /// وإلا يُختار الخط الذي يغطّي أكبر عدد منها (للكتابات غير اللاتينية). ما لا
  /// تغطّيه أي عائلة يُعالجه خط الاحتياط العالمي.
  ///
  /// **النص اللاتيني الممتد (التركية ğ/ş/İ/ı وغيرها): لا يُنتقل لعائلة عربية**
  /// إطلاقاً — يُحترم الخط المختار، ويرسم خط الاحتياط اللاتيني المحزوم (Noto
  /// Sans) المحارف الممتدة بأسلوب لاتيني موحّد. (سابقاً كان يُنتقل إلى Amiri
  /// السيريفي أو Cairo العربي فيبدو النص التركي غريباً عن بقيته اللاتينية.)
  PdfFontFamily familyForText(String text, {PdfFontFamily? preferred}) {
    final PdfFontFamily fallback = preferred ?? defaultFamily;
    if (text.isEmpty) return fallback;
    final List<int> codePoints =
        text.runes.where((int rune) => rune >= 0x80).toList(growable: false);
    if (codePoints.isEmpty) return fallback;
    if (codePoints.every(_isLatinScript)) return fallback;
    final Set<int> preferredCoverage =
        _familyCodePoints[fallback] ?? const <int>{};
    if (codePoints.every(preferredCoverage.contains)) return fallback;
    int bestScore = codePoints.where(preferredCoverage.contains).length;
    PdfFontFamily best = fallback;
    for (final PdfFontFamily family in PdfFontFamily.pdfFamilies) {
      if (family == fallback) continue;
      final Set<int> coverage = _familyCodePoints[family] ?? const <int>{};
      final int score = codePoints.where(coverage.contains).length;
      if (score > bestScore) {
        bestScore = score;
        best = family;
      }
    }
    return best;
  }

  /// هل المحرف [rune] من الكتابة اللاتينية (الأساسية أو الممتدة)؟
  ///
  /// النص اللاتيني لا يُعيد اختيار عائلة (خط عربي مثلاً)، بل يبقى على الخط
  /// المختار ويُكمل خط الاحتياط اللاتيني المحزوم ما يغيب عنه.
  static bool _isLatinScript(int rune) =>
      (rune >= 0x00A0 && rune <= 0x024F) || // Latin-1 Sup + Extended A/B
      (rune >= 0x1E00 && rune <= 0x1EFF); // Latin Extended Additional

  /// هل الخط المخصّص [family] مسجَّل وجاهز للرسم فعلاً؟
  bool hasRegisteredCustomFamily(String family) =>
      family.trim().isNotEmpty && CustomPdfFonts.contains(family.trim());

  /// العائلة الافتراضية للـ PDF.
  static const PdfFontFamily defaultFamily = PdfFontFamily.plex;

  /// تحميل كل الخطوط من أصول التطبيق (بلا شبكة).
  ///
  /// يُقرأ كل ملف خط **مرة واحدة** فقط حتى لو استُخدم لأكثر من وزن (كما في
  /// Amiri الذي يخدم الوسط والعريض بالملف العريض نفسه).
  static Future<PdfFontSet> load({AssetBundle? bundle}) async {
    final AssetBundle assets = bundle ?? rootBundle;
    final Map<String, Uint8List> bytesByPath = <String, Uint8List>{};
    final Map<String, pw.Font> byPath = <String, pw.Font>{};
    final Map<String, pw.Font> fonts = <String, pw.Font>{};
    final Map<String, Uint8List> bytesByKey = <String, Uint8List>{};

    for (final MapEntry<PdfFontFamily, Map<PdfFontWeight, String>> family
        in _sources.entries) {
      for (final MapEntry<PdfFontWeight, String> variant in family.value.entries) {
        // يُقرأ كل ملف خط مرة واحدة فقط حتى لو خدم أكثر من وزن.
        final Uint8List bytes = bytesByPath[variant.value] ??=
            (await assets.load(variant.value)).buffer.asUint8List();
        final String key = '${family.key.jsonValue}:${variant.key.jsonValue}';
        byPath[variant.value] ??= pw.Font.ttf(bytes.buffer.asByteData());
        fonts[key] = byPath[variant.value]!;
        bytesByKey[key] = bytes;
      }
    }

    // خط الاحتياط العالمي: Noto Sans SC (الصينية) ثم Noto Sans (السيريلية) —
    // يُضمَّنان عبر `fontFallback` فيرسمان ما لا تغطّيه الخطوط العربية بلا
    // مربعات فارغة.
    final Uint8List notoScBytes =
        (await assets.load(AppAssets.notoScFontFile)).buffer.asUint8List();
    fonts[notoScFontKey] = pw.Font.ttf(notoScBytes.buffer.asByteData());
    bytesByKey[notoScFontKey] = notoScBytes;

    // خط احتياط السيريلية: Noto Sans المُصغَّر — خط الصينية أعلاه لا يملك إلا
    // الأبجدية الروسية الأساسية، فلا يغطي الأوكرانية/الصربية/البلغارية.
    final Uint8List cyrillicBytes =
        (await assets.load(AppAssets.notoCyrillicFontFile)).buffer.asUint8List();
    fonts[notoCyrillicFontKey] = pw.Font.ttf(cyrillicBytes.buffer.asByteData());
    bytesByKey[notoCyrillicFontKey] = cyrillicBytes;

    // حساب التغطية في isolate خلفي: مسح `cmap` لكل خط ثقيل على الخيط الرئيسي
    // كان يُجمّد الإقلاع/أول تصدير (قِيس ~37ms)، فنُخرجه من الخيط الرئيسي.
    final (Map<PdfFontFamily, Set<int>> byFamily, Set<int> bundled) =
        await _coverageOffMainThread(bytesByKey);
    return PdfFontSet._(
      fonts,
      bytesByKey,
      bytesByPath.length,
      byFamily,
      bundled,
    );
  }

  /// مفتاح خط الاحتياط في حمولة حساب التغطية (نصّي وقابل للإرسال).
  static const String _notoScCoverageKey = '__notoSc__';
  static const String _notoCyrillicCoverageKey = '__notoCyrillic__';

  /// يبني خريطة تغطية المحارف من بايتات الخطوط (بلا قراءة أصول).
  ///
  /// يُحسب من كل ملف `regular` لكل عائلة، ثم يُضمّ خط الاحتياط العالمي. الناتج
  /// أساس اختيار الخط حسب كتابة النص وفحص التغطية الدقيق.
  static (Map<PdfFontFamily, Set<int>>, Set<int>) _coverageFromBytes(
    Map<String, Uint8List> bytesByKey,
  ) {
    final Map<PdfFontFamily, Set<int>> byFamily =
        <PdfFontFamily, Set<int>>{};
    final Set<int> bundled = <int>{};
    for (final PdfFontFamily family in PdfFontFamily.pdfFamilies) {
      final Uint8List? bytes = bytesByKey['${family.jsonValue}:regular'];
      if (bytes == null) continue;
      final Set<int> codePoints = FontInspector.inspect(bytes).codePoints;
      byFamily[family] = codePoints;
      bundled.addAll(codePoints);
    }
    final Uint8List? notoSc = bytesByKey[notoScFontKey];
    if (notoSc != null) {
      bundled.addAll(FontInspector.inspect(notoSc).codePoints);
    }
    final Uint8List? cyrillic = bytesByKey[notoCyrillicFontKey];
    if (cyrillic != null) {
      bundled.addAll(FontInspector.inspect(cyrillic).codePoints);
    }
    return (byFamily, bundled);
  }

  /// يحسب التغطية في **isolate خلفي** فلا يتجمّد الخيط الرئيسي أثناء التحميل.
  ///
  /// يمرّر بايتات ملفات `regular` فقط (مع خط الاحتياط) لتقليل النسخ، ويعيد
  /// النتيجة كمفاتيح نصية/قوائم قابلة للإرسال بين الـisolates.
  static Future<(Map<PdfFontFamily, Set<int>>, Set<int>)> _coverageOffMainThread(
    Map<String, Uint8List> bytesByKey,
  ) async {
    final Map<String, Uint8List> inputs = <String, Uint8List>{};
    for (final PdfFontFamily family in PdfFontFamily.pdfFamilies) {
      final Uint8List? bytes = bytesByKey['${family.jsonValue}:regular'];
      if (bytes != null) inputs[family.jsonValue] = bytes;
    }
    final Uint8List? notoSc = bytesByKey[notoScFontKey];
    if (notoSc != null) inputs[_notoScCoverageKey] = notoSc;
    final Uint8List? cyrillic = bytesByKey[notoCyrillicFontKey];
    if (cyrillic != null) inputs[_notoCyrillicCoverageKey] = cyrillic;

    final Map<String, List<int>> raw =
        await compute<Map<String, Uint8List>, Map<String, List<int>>>(
      _coverageEntry,
      inputs,
    );
    final Map<PdfFontFamily, Set<int>> byFamily =
        <PdfFontFamily, Set<int>>{};
    final Set<int> bundled = <int>{};
    for (final PdfFontFamily family in PdfFontFamily.pdfFamilies) {
      final List<int>? codePoints = raw[family.jsonValue];
      if (codePoints == null) continue;
      final Set<int> set = codePoints.toSet();
      byFamily[family] = set;
      bundled.addAll(set);
    }
    final List<int>? notoScCodePoints = raw[_notoScCoverageKey];
    if (notoScCodePoints != null) bundled.addAll(notoScCodePoints);
    final List<int>? cyrillicCodePoints = raw[_notoCyrillicCoverageKey];
    if (cyrillicCodePoints != null) bundled.addAll(cyrillicCodePoints);
    return (byFamily, bundled);
  }

  /// إعادة بناء المجموعة من بايتات نمطها المصدر (تُستعمل داخل isolate).
  ///
  /// لا تلمس `rootBundle` إطلاقاً — كل الخطوط تأتي من البايتات الممرَّرة.
  factory PdfFontSet.fromBytes(Map<String, Uint8List> bytesByKey) {
    final Map<String, pw.Font> fonts = <String, pw.Font>{};
    bytesByKey.forEach((String key, Uint8List bytes) {
      fonts[key] = pw.Font.ttf(bytes.buffer.asByteData());
    });
    // داخل isolate التصدير نحن أصلاً خارج الخيط الرئيسي، فنحسب التغطية مباشرة
    // بلا إنشاء isolate إضافي.
    final (Map<PdfFontFamily, Set<int>> byFamily, Set<int> bundled) =
        _coverageFromBytes(bytesByKey);
    return PdfFontSet._(
      fonts,
      bytesByKey,
      bytesByKey.length,
      byFamily,
      bundled,
    );
  }

  /// بايتات كل خط بالمفتاح `family:weight` (نسخة غير قابلة للتعديل).
  Map<String, Uint8List> get bytesByKey =>
      Map<String, Uint8List>.unmodifiable(_bytesByKey);

  /// تحميل مخزَّن مؤقتاً — يُستخدم في الواجهة لتجنّب إعادة قراءة ملفات الخطوط
  /// (‎~1.7MB) عند كل إعادة توليد للمعاينة.
  static Future<PdfFontSet> loadCached({AssetBundle? bundle}) {
    final Future<PdfFontSet>? cached = _cached;
    if (cached != null) return cached;
    final Future<PdfFontSet> loading = load(bundle: bundle).catchError(
      (Object error, StackTrace stackTrace) {
        _cached = null; // لا نحتفظ بالفشل حتى يمكن إعادة المحاولة.
        throw error;
      },
    );
    _cached = loading;
    return loading;
  }

  /// تسخين مسبق: يبدأ تحميل الخطوط المحزومة وتحليلها كسولاً **في الخلفية** عند
  /// الإقلاع، فلا يدفع المستخدم كلفة التحميل (قراءة الأصول + تحليل الخطوط +
  /// حساب التغطية) عند أول تصدير. لا يؤخّر الإقلاع ولا يرمي أبداً.
  static Future<void> warmUp({AssetBundle? bundle}) async {
    try {
      await loadCached(bundle: bundle);
    } on Object catch (error) {
      debugPrint('[PdfFontSet] تعذّر التسخين المسبق للخطوط: $error');
    }
  }

  /// مسح الذاكرة المؤقتة (للاختبارات).
  static void resetCache() => _cached = null;

  /// عدد الخطوط المتاحة للاختيار (عائلة × وزن) — بلا خط الاحتياط العالمي
  /// الذي ليس عائلة قابلة للاختيار.
  int get loadedCount =>
      _fonts.length -
      (_fonts.containsKey(notoScFontKey) ? 1 : 0) -
      (_fonts.containsKey(notoCyrillicFontKey) ? 1 : 0);
}

/// نقطة دخول حساب التغطية داخل isolate (يجب أن تكون دالة عُليا).
///
/// تُرجع المفاتيح نصية/قوائم أعداد صحيحة فقط، وكلها قابلة للإرسال بين
/// الـisolates، فتُبنى خريطة العائلات على الخيط الرئيسي بلا نسخ كائنات ثقيلة.
Map<String, List<int>> _coverageEntry(Map<String, Uint8List> inputs) {
  final Map<String, List<int>> out = <String, List<int>>{};
  inputs.forEach((String key, Uint8List bytes) {
    out[key] = FontInspector.inspect(bytes).codePoints.toList(growable: false);
  });
  return out;
}
