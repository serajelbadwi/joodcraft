import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
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
import '../pdf/pdf_font_catalog.dart';
import '../pdf/pdf_generation_isolate.dart';
import '../pdf/pdf_render_engine.dart';
import '../pdf/pdf_script_coverage.dart';

// يبقى `PdfDocumentMetadata` متاحاً من هذا الملف لمن يستورده تاريخياً.
export '../pdf/pdf_render_engine.dart' show PdfDocumentMetadata;

/// مزوّد الصور للقالب (شعار/توقيع/ختم).
///
/// واجهة قابلة للحقن حتى لا يعتمد المحرك على أي مصدر شبكي: التنفيذ الافتراضي
/// يقرأ من أصول التطبيق المحزومة فقط.
abstract interface class PdfImageResolver {
  /// حلّ صورة من مرجعها كـ[مزوّد رسم] جاهز (للمسار المتزامن على الخيط الرئيسي).
  Future<pw.ImageProvider?> resolve(
    String path,
    ImageSourceKind kind, {
    String? inlineData,
  });

  /// بايتات الصورة نفسها — تُستخدم لتوليد داخل isolate (لا تُنقل كائنات `pw.*`).
  Future<Uint8List?> resolveBytes(
    String path,
    ImageSourceKind kind, {
    String? inlineData,
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
  }) async {
    final String key = '${kind.jsonValue}:$path';
    final pw.ImageProvider? cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached; // أعِده للمؤخّرة = «أحدث استخداماً».
      return cached;
    }

    final Uint8List? bytes =
        await resolveBytes(path, kind, inlineData: inlineData);
    // ⚠️ لا نُخزّن الفشل: الأصل قد يكون غير مستعادٍ بعد (بدء التشغيل) أو يُضاف
    // لاحقاً؛ فحفظ `null` كان يجعل الصورة تختفي نهائياً في المعاينة التالية.
    if (bytes == null) return null;
    final pw.ImageProvider image = pw.MemoryImage(bytes);
    _cache[key] = image;
    _trim();
    return image;
  }

  @override
  Future<Uint8List?> resolveBytes(
    String path,
    ImageSourceKind kind, {
    String? inlineData,
  }) async {
    // الترتيب: المرجع الحيّ أولاً (الأصل/الأصل المحزوم)، ثم النسخة المضمّنة
    // احتياطاً — فلو حُذف الأصل من المكتبة يبقى الإطار قابلاً للرسم.
    return await _loadBytes(path, kind) ?? _decodeInlineBytes(inlineData);
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

  Future<Uint8List?> _loadBytes(String path, ImageSourceKind kind) async {
    try {
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
    } catch (_) {
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
  Future<PdfGenerationReport> generate({
    required TemplateDocument document,
    Map<String, String>? data,
    PdfDocumentMetadata? metadata,
  }) {
    return generateBatch(
      document: document,
      rows: <Map<String, String>>[data ?? const <String, String>{}],
      metadata: metadata,
    );
  }

  /// توليد ورقة لكل صف (التوليد الجماعي — المرحلة 4).
  ///
  /// يُستدعى التقدّم (`onProgress`) بعد كل صفحة مكتملة. عند تجاوز الحدّ يُبثّ
  /// التقدّم لحظياً من الـ isolate الخلفي.
  Future<PdfGenerationReport> generateBatch({
    required TemplateDocument document,
    required List<Map<String, String>> rows,
    PdfDocumentMetadata? metadata,
    void Function(int done, int total)? onProgress,
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    final List<String> warnings = <String>[...document.warnings];
    // سجّل الخطوط المخصّصة التي يشير إليها المستند أولاً، حتى يعرف فحص التغطية
    // أنها متاحة ويمنع تحذيرات كاذبة عن كتابات يتكفّل بها خط المستخدم.
    _ensureCustomFonts(document);
    // تحذيرات تغطية الكتابات (سيريلية/صينية بلا خط محزوم) قبل أي رسم.
    for (final PdfScript script in PdfScriptCoverage.unsupportedInDocument(
      document,
      isCustomFontAvailable: _fonts.hasRegisteredCustomFamily,
    )) {
      warnings.add(PdfScriptCoverage.warningFor(script));
    }

    if (rows.isEmpty) {
      throw const AppException(
        AppErrorCode.pdfGeneration,
        message: 'لا توجد صفوف بيانات لتوليدها.',
      );
    }

    final Uint8List bytes = _shouldUseIsolate(rows.length)
        ? await _generateInBackground(document, rows, metadata, warnings, onProgress)
        : await _generateInline(document, rows, metadata, warnings, onProgress);

    stopwatch.stop();
    return PdfGenerationReport(
      bytes: bytes,
      pageCount: rows.length,
      elapsed: stopwatch.elapsed,
      warnings: warnings,
    );
  }

  /// هل يُنفَّذ البناء في isolate خلفي؟ (يُعطَّل على الويب — لا isolates فيه.)
  bool _shouldUseIsolate(int rowCount) =>
      useIsolate && !kIsWeb && rowCount >= isolateThreshold;

  /// المسار المباشر على الخيط الرئيسي (يُستخدم للمعاينة المفردة والصغيرة).
  Future<Uint8List> _generateInline(
    TemplateDocument document,
    List<Map<String, String>> rows,
    PdfDocumentMetadata? metadata,
    List<String> warnings,
    void Function(int done, int total)? onProgress,
  ) async {
    // تأكيد تضمين الخطوط المخصصة التي يشير إليها المستند من مخزن الخطوط.
    _ensureCustomFonts(document);
    final Map<String, pw.ImageProvider?> images =
        await _resolveImages(document, warnings);
    final PdfRenderer renderer = PdfRenderer(fonts: _fonts, compress: compress);
    try {
      return await renderer.build(
        document: document,
        rows: rows,
        images: images,
        metadata: metadata,
        onProgress: onProgress,
      );
    } catch (error) {
      throw AppException(
        AppErrorCode.pdfGeneration,
        message: 'تعذّر تجميع ملف PDF: $error',
        cause: error,
      );
    }
  }

  /// المسار الخلفي: بايتات الخطوط والصور ← isolate ← بايتات الـ PDF.
  Future<Uint8List> _generateInBackground(
    TemplateDocument document,
    List<Map<String, String>> rows,
    PdfDocumentMetadata? metadata,
    List<String> warnings,
    void Function(int done, int total)? onProgress,
  ) async {
    final Map<String, Uint8List> imageBytes =
        await _resolveImageBytes(document, warnings);
    final PdfRenderRequest request = PdfRenderRequest(
      document: document,
      rows: rows,
      imageBytes: imageBytes,
      // كل الخطوط المضمّنة: الرسم قد يرجع إليها عند عائلة غير صالحة أو ناقصة.
      embeddedFontBytes: _fonts.bytesByKey,
      customFonts: _customFontBytes(document),
      compress: compress,
      metadata: metadata,
    );
    try {
      return await renderPdfInBackground(request, onProgress: onProgress);
    } catch (error) {
      throw AppException(
        AppErrorCode.pdfGeneration,
        message: 'تعذّر توليد ملف PDF في الخلفية: $error',
        cause: error,
      );
    }
  }

  /// يضمّن خطوطاً مخصصة يشير إليها المستند عبر `customFont`.
  void _ensureCustomFonts(TemplateDocument document) {
    final CustomFontController store = CustomFontController.instance;
    for (final String family in _customFontFamilies(document)) {
      if (CustomPdfFonts.contains(family)) continue;
      final CustomFontFace? face = store.faceOf(family);
      if (face == null) continue;
      try {
        CustomPdfFonts.register(face.family, face.bytes, weight: face.weight);
      } catch (_) {
        // يبقى الخط المضمّن هو البديل الآمن.
      }
    }
  }

  /// بايتات الخطوط المخصصة التي يحتاجها الـ isolate لتسجيلها هناك.
  List<PdfCustomFontBytes> _customFontBytes(TemplateDocument document) {
    final CustomFontController store = CustomFontController.instance;
    final List<PdfCustomFontBytes> payload = <PdfCustomFontBytes>[];
    for (final String family in _customFontFamilies(document)) {
      final CustomFontFace? face = store.faceOf(family);
      if (face == null) continue;
      payload.add(
        PdfCustomFontBytes(
          family: face.family,
          weight: face.weight,
          bytes: face.bytes,
        ),
      );
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
        final String key = '${element.sourceKind.jsonValue}:${element.path}';
        if (!seen.add(key)) continue;
        yield _ImageRef(
          key: key,
          path: element.path,
          kind: element.sourceKind,
          inlineData: inlineImageBase64(element, document),
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
  });

  final String key;
  final String path;
  final ImageSourceKind kind;
  final String? inlineData;
}
