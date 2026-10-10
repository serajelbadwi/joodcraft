import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

import '../assets/asset_image_cache.dart';
import '../assets/assets_controller.dart';
import '../assets/embedded_assets.dart';
import '../assets/user_asset.dart';
import '../errors/app_error_code.dart';
import '../errors/app_exception.dart';
import '../fonts/custom_font_controller.dart';
import '../fonts/custom_font_face.dart';
import '../models/template_document.dart';
import '../models/template_element.dart';
import '../pdf/custom_pdf_fonts.dart';
import '../pdf/pdf_export_type.dart';
import '../pdf/pdf_font_catalog.dart';
import '../pdf/pdf_generation_isolate.dart';
import '../pdf/pdf_image_adjust.dart';
import '../pdf/pdf_quality_image.dart';
import '../pdf/pdf_image_tint.dart';
import '../pdf/pdf_render_engine.dart';
import '../pdf/pdf_script_coverage.dart';
import '../print/crop_marks.dart';
import '../print/imposition_pdf_builder.dart';
import '../pdf/rasterized_pdf_builder.dart';

// يبقى `PdfDocumentMetadata` متاحاً من هذا الملف لمن يستورده تاريخياً.
export '../pdf/pdf_render_engine.dart' show PdfDocumentMetadata;

/// مزوّد الصور للقالب (شعار/توقيع/ختم).
///
/// واجهة قابلة للحقن حتى لا يعتمد المحرك على أي مصدر شبكي: التنفيذ الافتراضي
/// يقرأ من أصول التطبيق المحزومة فقط.
abstract interface class PdfImageResolver {
  /// حلّ صورة من مرجعها كـ[مزوّد رسم] جاهز (للمسار المتزامن على الخيط الرئيسي).
  ///
  /// [tintHex] لون تلوين اختياري (`#RRGGBB`) يُطبَّق كما في المحرّر،
  /// و[adjustments] ضبط لوني اختياري (سطوع/تباين/تدوير لوني/تشبّع) يُطبَّق
  /// على البكسلات **قبل** التلوين — بنفس ترتيب اللوحة تماماً.
  Future<pw.ImageProvider?> resolve(
    String path,
    ImageSourceKind kind, {
    String? inlineData,
    String? tintHex,
    ElementAdjustments? adjustments,
  });

  /// بايتات الصورة نفسها — تُستخدم لتوليد داخل isolate (لا تُنقل كائنات `pw.*`).
  ///
  /// بوجود [tintHex] تُعاد البايتات **ملوّنة** جاهزة (`BlendMode.srcIn`)، أو
  /// الأصلية إن تعذّر التلوين — فلا يسقط العنصر من الملف بسبب لون غير صالح.
  /// وبوجود [adjustments] تُعاد **مضبوطة لونياً** قبل التلوين.
  Future<Uint8List?> resolveBytes(
    String path,
    ImageSourceKind kind, {
    String? inlineData,
    String? tintHex,
    ElementAdjustments? adjustments,
  });
}

/// تنفيذ يقرأ الصور من أصول التطبيق المحزومة ومن مكتبة أصول المستخدم
/// المحلية (وضع Offline تماماً).
class AssetPdfImageResolver implements PdfImageResolver {
  AssetPdfImageResolver({
    AssetBundle? bundle,
    UserAsset? Function(String id)? userAssetsProvider,
    this.maxEntries = defaultMaxEntries,
  })  : _bundle = bundle ?? rootBundle,
        _userAssets = userAssetsProvider ??
            ((String id) => AssetsController.instance.byId(id));

  /// سقف عدد الصور المحفوظة (LRU) — يمنع تضخّم الذاكرة مع القوالب الثقيلة.
  static const int defaultMaxEntries = 64;

  final AssetBundle _bundle;
  final UserAsset? Function(String id) _userAssets;
  final int maxEntries;

  // `Map` يحفظ ترتيب الإدخال ⇒ أول مفتاح هو «الأقل استخداماً».
  final Map<String, pw.ImageProvider> _cache = <String, pw.ImageProvider>{};

  @override
  Future<pw.ImageProvider?> resolve(
    String path,
    ImageSourceKind kind, {
    String? inlineData,
    String? tintHex,
    ElementAdjustments? adjustments,
  }) async {
    final String key = pdfImageCacheKey(
      path,
      kind,
      tintHex: tintHex,
      adjustKey: adjustments?.key,
    );
    final pw.ImageProvider? cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached; // أعِده للمؤخّرة = «أحدث استخداماً».
      return cached;
    }

    final Uint8List? bytes = await resolveBytes(
      path,
      kind,
      inlineData: inlineData,
      tintHex: tintHex,
      adjustments: adjustments,
    );
    // ⚠️ لا نُخزّن الفشل: الأصل قد يكون غير مستعادٍ بعد (بدء التشغيل) أو يُضاف
    // لاحقاً؛ فحفظ `null` كان يجعل الصورة تختفي نهائياً في المعاينة التالية.
    if (bytes == null) return null;
    // مُزوّد الطباعة عالي الدقة: تحجيم بمتوسط المساحة (لا «أقرب جار») وتضمين
    // بلا فقدان — لا مواريه ولا خطوط تكميم في التصدير 300dpi.
    final pw.ImageProvider image = PdfQualityImage(bytes);
    _cache[key] = image;
    _trim();
    return image;
  }

  @override
  Future<Uint8List?> resolveBytes(
    String path,
    ImageSourceKind kind, {
    String? inlineData,
    String? tintHex,
    ElementAdjustments? adjustments,
  }) async {
    // الترتيب: المرجع الحيّ أولاً (الأصل/الأصل المحزوم)، ثم النسخة المضمّنة
    // احتياطاً — فلو حُذف الأصل من المكتبة يبقى الإطار قابلاً للرسم.
    final Uint8List? bytes =
        await _loadBytes(path, kind) ?? _decodeInlineBytes(inlineData);
    if (bytes == null) return null;

    // الترتيب نفسه المتبع في اللوحة: الضبط اللوني أولاً (يغيّر البكسلات)
    // ثم التلوين (يستبدل اللون). وفشل أيّهما يُبقي ما قبله بلا فقدان العنصر.
    try {
      final Uint8List adjusted =
          await adjustImageBytesSafely(bytes, adjustments);
      final String tint = (tintHex ?? '').trim();
      if (tint.isEmpty) return adjusted;
      return tintImageBytesSafely(adjusted, tint);
    } catch (e, trace) {
      debugPrint('⚠️ Image Adjust/Tint Error: $e');
      debugPrint('📍 Trace: $trace');
      return bytes;
    }
  }

  /// إسقاط الأقدم (الأقل استخداماً) حتى لا يتجاوز المخزن الحدّ الأعلى.
  void _trim() {
    while (_cache.length > maxEntries) {
      _cache.remove(_cache.keys.first);
    }
  }

  /// فكّ ترميز صورة Base64 مضمّنة؛ يعيد `null` للبيانات الغائبة أو التالفة.
  static Uint8List? _decodeInlineBytes(String? data) {
    // نزيل أي بادئة data URI كي تُقبل الصيغتان (خام أو كامل).
    final String clean = stripBase64DataUri(data ?? '');
    if (clean.isEmpty) return null;
    try {
      return base64Decode(clean);
    } catch (_) {
      return null;
    }
  }

  /// تفريغ ذاكرة الصور (عند تغيير المستند أو إعادة توليد المعاينة).
  void clearCache() => _cache.clear();

  /// عدد الصور المخزّنة (للتشخيص والاختبارات — يثبت فصل نسخ التلوين).
  @visibleForTesting
  int get cacheLength => _cache.length;

  Future<Uint8List?> _loadBytes(String path, ImageSourceKind kind) async {
    try {
      return await Future.any<Uint8List?>(<Future<Uint8List?>>[
        _loadBytesActual(path, kind),
        Future<Uint8List?>.delayed(const Duration(seconds: 4), () {
          debugPrint('⚠️ Image load timeout for path: $path');
          return null;
        }),
      ]);
    } catch (e, stackTrace) {
      debugPrint('❌ Image Load Exception: $e');
      debugPrint('📍 Trace: $stackTrace');
      return null;
    }
  }

  Future<Uint8List?> _loadBytesActual(String path, ImageSourceKind kind) async {
    switch (kind) {
        case ImageSourceKind.asset:
          final ByteData data = await _bundle.load(path);
          return data.buffer.asUint8List();
        case ImageSourceKind.dataUri:
          return base64Decode(stripBase64DataUri(path));
        case ImageSourceKind.userAsset:
          // أصل محلي رفعه المستخدم — يُحلّ من مكتبة الأصول المحفوظة أوفلاين.
          final UserAsset? asset = _userAssets(path);
          if (asset != null) {
            return AssetImageCache.instance.bytesForAsset(asset);
          }
          // احتياط: بايتات رُسمت على اللوحة سابقاً ولم يعد المتحكم يعرف الأصل.
          return AssetImageCache.instance.cachedBytesForAsset(path);
        case ImageSourceKind.file:
          // غير مدعوم في الوضع غير المتصل: يجب أن يُرفع الملف إلى مكتبة الأصول.
          return null;
      }
    }
}

/// نتيجة التوليد: الملف + معلومات مفيدة للواجهة (زمن، عدد صفحات، تحذيرات).
class PdfGenerationReport {
  const PdfGenerationReport({
    required this.bytes,
    required this.pageCount,
    required this.elapsed,
    required this.warnings,
  });

  final Uint8List bytes;
  final int pageCount;
  final Duration elapsed;

  /// تحذيرات غير مُعطِّلة (صورة مفقودة، عنصر مجهول…) يمكن عرضها للمستخدم.
  final List<String> warnings;

  int get byteSize => bytes.lengthInBytes;
}

/// محرّك توليد الـ PDF المحلي.
///
/// المسار: `TemplateDocument` (JSON) ← تحجيم إلى A4 ← تشكيل عربي بصري ← رسم.
/// كل العمل يجري محلياً على الجهاز، بلا أي طلب شبكة.
///
/// **التوليد الجماعي في الخلفية:** عند تجاوز [isolateThreshold] صفاً يُنقل البناء
/// إلى isolate خلفي (على المنصات التي تدعمها) فيبقى شريط التقدّم سلساً ولا
/// تتجمّد الواجهة. أما التوليد المفرد (معاينة المحرّر) فيبقى على الخيط الرئيسي
/// لأنه أسرع (بلا نسخ بايتات الخطوط).
class PdfGeneratorService {
  PdfGeneratorService({
    required PdfFontSet fonts,
    PdfImageResolver? imageResolver,
    this.compress = true,
    this.useIsolate = true,
    this.isolateThreshold = defaultIsolateThreshold,
  })  : _fonts = fonts,
        _imageResolver = imageResolver ?? AssetPdfImageResolver();

  /// أصغر عدد صفوف يُشغّل مسار الـ isolate (ما دونه يبقى على الخيط الرئيسي).
  static const int defaultIsolateThreshold = 2;

  final PdfFontSet _fonts;
  final PdfImageResolver _imageResolver;

  /// ضغط محتوى الملف (مفعّل افتراضياً).
  final bool compress;

  /// هل يُسمح باستخدام isolate للتوليد الجماعي؟
  final bool useIsolate;

  /// عند بلوغ هذا العدد من الصفوف يُستخدم الـ isolate.
  final int isolateThreshold;

  /// إنشاء الخدمة مع تحميل الخطوط المحزومة (تُحمَّل مرة واحدة وتُخزَّن مؤقتاً).
  static Future<PdfGeneratorService> create({
    AssetBundle? bundle,
    PdfImageResolver? imageResolver,
    bool compress = true,
    bool useIsolate = true,
    int isolateThreshold = defaultIsolateThreshold,
  }) async {
    final PdfFontSet fonts = await PdfFontSet.loadCached(bundle: bundle);
    return PdfGeneratorService(
      fonts: fonts,
      imageResolver: imageResolver,
      compress: compress,
      useIsolate: useIsolate,
      isolateThreshold: isolateThreshold,
    );
  }

  /// وصول للخطوط (يحتاجه محرر القوالب في المرحلة 3 لعرض المقاسات).
  PdfFontSet get fonts => _fonts;

  // ==========================================================================
  //                              التوليد
  // ==========================================================================

  /// توليد صفحة واحدة (شهادة أو عقد).
  ///
  /// [type] محرّك الرسم: [PdfExportType.images] (النقطي، افتراضي) أو
  /// [PdfExportType.vector] (المتجه — نصّه قابل للنسخ).
  Future<PdfGenerationReport> generate({
    required TemplateDocument document,
    Map<String, String>? data,
    PdfDocumentMetadata? metadata,
    PdfExportType type = PdfExportType.images,
  }) {
    return generateBatch(
      document: document,
      rows: <Map<String, String>>[data ?? const <String, String>{}],
      metadata: metadata,
      type: type,
    );
  }

  /// توليد ورقة لكل صف (التوليد الجماعي — المرحلة 4).
  ///
  /// يُستدعى التقدّم (`onProgress`) بعد كل صفحة مكتملة. عند تجاوز الحدّ يُبثّ
  /// التقدّم لحظياً من الـ isolate الخلفي.
  ///
  /// [type] يختار المحرّك: النقطي (افتراضي، مطابق للمحرّر) أو المتجه —
  /// كلاهما يُخرج نفس المستند نفسه والفريق الوحيد هو طريقة الرسم.
  Future<PdfGenerationReport> generateBatch({
    required TemplateDocument document,
    required List<Map<String, String>> rows,
    PdfDocumentMetadata? metadata,
    void Function(int done, int total)? onProgress,
    PdfExportType type = PdfExportType.images,
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    final List<String> warnings = <String>[...document.warnings];
    // سجّل الخطوط المخصّصة/النظامية التي يشير إليها المستند أولاً، حتى يعرف
    // فحص التغطية أنها متاحة ويمنع تحذيرات كاذبة عن كتابات يتكفّل بها الخط.
    await _ensureCustomFonts(document);
    // تحذيرات تغطية الكتابات قبل أي رسم — بدقّة حسب الخطوط المتاحة فعلاً:
    // المحزومة (بما فيها خط الاحتياط Noto Sans SC) + الخطوط المخصّصة/النظامية.
    // فلا يُحذَّر على كتابة تُرسم فعلاً، ولا يمرّ محرف بلا أي خط بلا تحذير.
    addCoverageWarnings(document, warnings);

    if (rows.isEmpty) {
      throw const AppException(
        AppErrorCode.pdfGeneration,
        message: 'لا توجد صفوف بيانات لتوليدها.',
      );
    }

    try {
      debugPrint(
        '📄 [PdfGeneratorService] Starting batch generation '
        '(${rows.length} rows) using '
        '${type == PdfExportType.vector ? 'Vector' : 'Rasterized'} Engine...',
      );

      final Uint8List bytes = switch (type) {
        // المسار النقطي عالي الدقة (Rasterized): صورة كاملة لكل صفحة، فتطابق
        // المحرر بصرياً 100% — وهو المسار الافتراضي منذ كانت الصيغة الوحيدة.
        PdfExportType.images => await RasterizedPdfBuilder.build(
          document: document,
          rows: rows,
          metadata: metadata,
          compress: compress,
          onProgress: onProgress,
        ),
        // المسار المتجه: نصّ حقيقي مضمّن كمحارف وأشكال أوامر مسار، فيتسرّب
        // النص ويُبحث ويُصدَّر بحجم أصغر.
        PdfExportType.vector => await _buildVector(
          document: document,
          rows: rows,
          warnings: warnings,
          metadata: metadata,
          onProgress: onProgress,
        ),
      };

      stopwatch.stop();
      debugPrint('📄 [PdfGeneratorService] Batch generation complete in ${stopwatch.elapsedMilliseconds} ms.');
      
      return PdfGenerationReport(
        bytes: bytes,
        pageCount: rows.length,
        elapsed: stopwatch.elapsed,
        warnings: warnings,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ PDF Batch Generation Error [PdfGeneratorService]: $e');
      debugPrint('📍 StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// توليد PDF **متجهي** (Vector) — نصّه حروف مضمّنة لا بكسلات.
  ///
  /// بديل [generate] لمن أراد ملفاً أصغر ونصّاً قابلاً للنسخ والبحث: نفس
  /// المستند ونفس الصفوف، لكن الرسم أوامر مسار ونصوص بدل صورة كاملة للصفحة.
  ///
  /// لا يُستعمل مع وضع التجميع (Imposition): ورقة التجميع تكرّر قطعاً مرسومة
  /// صورةً على ورقة أكبر، فلا معنى لمسار متجهي فيها.
  Future<PdfGenerationReport> exportVector({
    required TemplateDocument document,
    Map<String, String>? data,
    PdfDocumentMetadata? metadata,
    void Function(int done, int total)? onProgress,
  }) {
    return generateBatch(
      document: document,
      rows: <Map<String, String>>[data ?? const <String, String>{}],
      metadata: metadata,
      onProgress: onProgress,
      type: PdfExportType.vector,
    );
  }

  // ==========================================================================
  //                        المسار المتجهي (Vector)
  // ==========================================================================

  /// بناء ملف PDF متجهي للصفوف — مساران **متطابقا النتيجة**:
  ///
  /// * **مجزّأ** (`useIsolate` مع تجاوز [isolateThreshold]): بايتات الصور
  ///   والخطوط تُنقل إلى isolate يُبنى فيه الملف، فلا يتجمّد الخيط الرئيسي
  ///   أثناء ترميز مئات المحارف — ويبثّ التقدّم من هناك لحظياً.
  /// * **على الخيط الرئيسي** (المسار الشائع في المعاينة: صفحة واحدة): أسرع
  ///   من نقل ميجابايتات الخطوط إلى isolate آخر ثم إعادة بناء المجموعة منها.
  ///
  /// لا يختلف المخرَج بين المسارين: المستند والصفوف والدقّة والضغط نفسها في
  /// الطرفين، والخطوط تُبنى من بايتاتها في المسار الأول ومن [PdfFontSet]
  /// نفسه في الثاني.
  Future<Uint8List> _buildVector({
    required TemplateDocument document,
    required List<Map<String, String>> rows,
    required List<String> warnings,
    PdfDocumentMetadata? metadata,
    void Function(int done, int total)? onProgress,
  }) async {
    if (useIsolate && rows.length >= isolateThreshold) {
      return renderPdfInBackground(
        PdfRenderRequest(
          document: document,
          rows: rows,
          imageBytes: await _resolveImageBytes(document, warnings),
          embeddedFontBytes: _fonts.bytesByKey,
          customFonts: await _customFontBytes(document),
          compress: compress,
          metadata: metadata,
        ),
        onProgress: onProgress,
      );
    }

    return PdfRenderer(
      fonts: _fonts,
      compress: compress,
      // دقّة المستند نفسها كما في المسار المجزّأ أعلاه.
      dpi: document.dpi.toDouble(),
    ).build(
      document: document,
      rows: rows,
      images: await _resolveImages(document, warnings),
      metadata: metadata,
      onProgress: onProgress,
    );
  }

  // ==========================================================================
  //                           التجميع للطباعة
  // ==========================================================================

  /// توليد **ورقة تجميع** (تجميع للطباعة) بعلامات قصّ متجهية وبدقّة 300 نقطة/بوصة.
  ///
  /// المساران المدعومان:
  /// * **تجميع مفرد**: مرّر [copies] (و[data] اختياري) فيُكرَّر العنصر على
  ///   الورقة كاملة حتى يمتلئ، ثم تُضاف ورقة أخرى إن فضل.
  /// * **تجميع جماعي**: مرّر [rows] (عشرة أرقام جلوس مثلاً) فتُوزَّع القطع
  ///   بترتيبها عبر أوراق متتالية، يكتمل كلٌّ منها قبل التالي.
  ///
  /// التوزيع يُحسب من [spec] **نفسه** المستخدم في معاينة المحرّر، فالملف
  /// الخارج مطابق تماماً لما رآه المستخدم قبل التصدير.
  Future<PdfGenerationReport> generateImposition({
    required TemplateDocument document,
    required ImpositionSpec spec,
    List<Map<String, String>>? rows,
    Map<String, String>? data,
    int copies = 1,
    PdfDocumentMetadata? metadata,
    void Function(int done, int total)? onProgress,
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    final List<String> warnings = <String>[...document.warnings];
    await _ensureCustomFonts(document);
    addCoverageWarnings(document, warnings);

    final Map<String, pw.ImageProvider?> images =
        await _resolveImages(document, warnings);

    final ImpositionPdfArtifact artifact;
    if (rows != null && rows.isNotEmpty) {
      artifact = await ImpositionPdfBuilder.buildBulk(
        fonts: _fonts,
        document: document,
        spec: spec,
        images: images,
        rows: rows,
        metadata: metadata,
        compress: compress,
        onProgress: onProgress,
      );
    } else {
      artifact = await ImpositionPdfBuilder.buildSingle(
        fonts: _fonts,
        document: document,
        spec: spec,
        images: images,
        copies: copies,
        data: data ?? document.sampleData,
        metadata: metadata,
        compress: compress,
        onProgress: onProgress,
      );
    }

    stopwatch.stop();
    return PdfGenerationReport(
      bytes: artifact.bytes,
      pageCount: artifact.sheetCount,
      elapsed: stopwatch.elapsed,
      warnings: warnings,
    );
  }

  /// تحذيرات تغطية الكتابات لمستند — تُضاف إلى [warnings].
  ///
  /// تُسجَّل الخطوط المخصّصة/النظامية أولاً حتى يعرف فحص التغطية أنها متاحة
  /// ويمنع تحذيرات كاذبة عن كتابات يتكفّل بها الخط؛ والفحص بدقّة حسب الخطوط
  /// المتاحة فعلاً (المحزومة بما فيها خطوط CJK/السريلية) فلا يُحذَّر على كتابة
  /// تُرسم فعلاً، ولا مرّ محرف بلا أي خط بلا تحذير.
  void addCoverageWarnings(TemplateDocument document, List<String> warnings) {
    final Set<int> bundledCoverage = _fonts.bundledCodePoints;
    final Set<PdfScript> runtimeCovered = PdfScriptCoverage.runtimeCovered;
    for (final PdfScript script in PdfScriptCoverage.unsupportedInDocument(
      document,
      isCustomFontAvailable: _fonts.hasRegisteredCustomFamily,
      isCodePointCovered: (String? customFamily, int codePoint) {
        if (bundledCoverage.contains(codePoint)) return true;
        if (_fonts.customFontCovers(customFamily, codePoint)) return true;
        final PdfScript? script = PdfScriptCoverage.scriptOf(codePoint);
        return script != null && runtimeCovered.contains(script);
      },
    )) {
      warnings.add(PdfScriptCoverage.warningFor(script));
    }
  }

  /// مجموعة الخطوط المحمّلة — تُستخدم في الاختبارات لبناء [PdfRenderer] يدوياً
  /// بلا إعادة تحميل الخطوط.
  @visibleForTesting
  PdfFontSet get debugFonts => _fonts;

  /// يضمّن الخطوط المخصّصة **وخطوط النظام** التي يشير إليها المستند.
  ///
  /// خط النظام المختار في القالب لا يوجد في مخزن الخطوط المرفوعة، فنقرأ
  /// بايتاته من الكاش (بلا إعادة مسح)، وإلا عاد الرسم صامتاً للخط المحزوم.
  Future<void> _ensureCustomFonts(TemplateDocument document) async {
    final CustomFontController store = CustomFontController.instance;
    for (final String family in _customFontFamilies(document)) {
      if (CustomPdfFonts.contains(family)) continue;
      final CustomFontFace? face = store.faceOf(family);
      if (face != null) {
        try {
          CustomPdfFonts.register(face.family, face.bytes, weight: face.weight);
        } catch (_) {
          // يبقى الخط المضمّن هو البديل الآمن.
        }
        continue;
      }
      final Uint8List? systemBytes = await store.systemFontBytes(family);
      if (systemBytes == null) continue;
      try {
        CustomPdfFonts.register(family, systemBytes);
      } catch (_) {
        // خط نظام غير قابل للتضمين (CFF/ttc) — يبقى الخط المضمّن بديلاً.
      }
    }
  }

  /// بايتات الخطوط (المرفوعة وخطوط النظام) التي يحتاجها isolate التصدير.
  ///
  /// **إصلاح الدُفعات:** كان يُقرأ فقط من `store.faceOf` (المرفوعة)، فتختفي
  /// خطوط النظام المختارة في التصدير الجماعي. الآن تُضمَّن بايتاتها المخزّنة
  /// صراحةً فتُسجَّل داخل الـisolate وترسم كما في المعاينة المفردة.
  Future<List<PdfCustomFontBytes>> _customFontBytes(
    TemplateDocument document,
  ) async {
    final CustomFontController store = CustomFontController.instance;
    final List<PdfCustomFontBytes> payload = <PdfCustomFontBytes>[];
    for (final String family in _customFontFamilies(document)) {
      final List<CustomFontFace> faces =
          store.faces.where((CustomFontFace f) => f.family == family).toList();
      if (faces.isNotEmpty) {
        for (final CustomFontFace face in faces) {
          payload.add(
            PdfCustomFontBytes(
              family: face.family,
              weight: face.weight,
              bytes: face.bytes,
            ),
          );
        }
        continue;
      }
      // خط نظام: بايتاته من الكاش بدل إسقاطه صامتاً للخط المحزوم.
      final Uint8List? systemBytes = await store.systemFontBytes(family);
      if (systemBytes != null) {
        payload.add(
          PdfCustomFontBytes(
            family: family,
            weight: PdfFontWeight.regular.value,
            bytes: systemBytes,
          ),
        );
      }
    }
    return payload;
  }

  /// عائلات الخطوط المخصصة التي يشير إليها المستند.
  Set<String> _customFontFamilies(TemplateDocument document) => <String>{
        for (final TemplateElement element in document.elements)
          if (element is TextElement &&
              element.customFont != null &&
              element.customFont!.trim().isNotEmpty)
            element.customFont!.trim(),
      };

  // ==========================================================================
  //                              الصور
  // ==========================================================================

  /// مراجع الصور الفريدة في المستند مع نسختها المضمّنة الاحتياطية.
  Iterable<_ImageRef> _imageRefs(TemplateDocument document) sync* {
    final Set<String> seen = <String>{};
    for (final TemplateElement element in document.elements) {
      if (element is ImageElement) {
        // المفتاح يضمّ التلوين والضبط اللوني: نفس الصورة بلونين/ضبطين مختلفين
        // = مراجع (ونسخ معالجة) مستقلة.
        final String key =
            element.processedImageKey ?? element.imageKey;
        if (!seen.add(key)) continue;
        yield _ImageRef(
          key: key,
          path: element.path,
          kind: element.sourceKind,
          inlineData: inlineImageBase64(element, document),
          tintHex: element.hasTint ? element.tintHex : null,
          adjustments: element.adjustments,
        );
        continue;
      }
      // صور خانات التوقيع تُحمّل بنفس مفتاح النوع:المسار الذي يستعلم به محرّك
      // الرسم، فتخرج التوقيعات في الـ PDF بلا مسار تحميل موازٍ.
      if (element is SignatureElement) {
        for (final SignatureSlot slot in element.slots) {
          if (!slot.hasImage) continue;
          final String key =
              '${slot.imageSource.jsonValue}:${slot.imagePath}';
          if (!seen.add(key)) continue;
          yield _ImageRef(
            key: key,
            path: slot.imagePath,
            kind: slot.imageSource,
            inlineData: inlineSlotBase64(slot, document),
          );
        }
      }
    }
  }

  Future<Map<String, pw.ImageProvider?>> _resolveImages(
    TemplateDocument document,
    List<String> warnings,
  ) async {
    final Map<String, pw.ImageProvider?> images =
        <String, pw.ImageProvider?>{};
    for (final _ImageRef ref in _imageRefs(document)) {
      final pw.ImageProvider? image = await _imageResolver.resolve(
        ref.path,
        ref.kind,
        inlineData: ref.inlineData,
        tintHex: ref.tintHex,
        adjustments: ref.adjustments,
      );
      if (image == null) warnings.add(_missingAssetWarning(ref.path));
      images[ref.key] = image;
    }
    return images;
  }

  Future<Map<String, Uint8List>> _resolveImageBytes(
    TemplateDocument document,
    List<String> warnings,
  ) async {
    final Map<String, Uint8List> images = <String, Uint8List>{};
    for (final _ImageRef ref in _imageRefs(document)) {
      final Uint8List? bytes = await _imageResolver.resolveBytes(
        ref.path,
        ref.kind,
        inlineData: ref.inlineData,
        tintHex: ref.tintHex,
        adjustments: ref.adjustments,
      );
      // التحذير يُسجَّل مرة واحدة هنا (المصدر الوحيد لغياب الصورة).
      if (bytes == null) {
        warnings.add(_missingAssetWarning(ref.path));
        continue;
      }
      images[ref.key] = bytes;
    }
    return images;
  }

  static String _missingAssetWarning(String path) =>
      'أصل محذوف: ${path.trim().isEmpty ? '(بلا مرجع)' : path} '
      '— أعد اختيار الإطار/الأصل من مكتبة أصولي.';
}

/// مرجع صورة واحد داخل المستند (للتحميل مرة واحدة لكل مرجع فريد).
class _ImageRef {
  const _ImageRef({
    required this.key,
    required this.path,
    required this.kind,
    required this.inlineData,
    this.tintHex,
    this.adjustments,
  });

  final String key;
  final String path;
  final ImageSourceKind kind;
  final String? inlineData;

  /// لون التلوين المطلوب لهذا المرجع (`#RRGGBB`) أو `null`.
  final String? tintHex;

  /// الضبط اللوني المطلوب لهذا المرجع، أو `null` إن كان بلا ضبط.
  final ElementAdjustments? adjustments;
}
