/// متحكّم شاشة OCR: اختيار ملف → معالجة → استخراج → تحرير → إدراج.
///
/// **لماذا `ChangeNotifier` خالص بلا Riverpod/Provider إضافي؟** المشروع يستخدم
/// `provider` أصلاً، والشاشة هنا معزولة (تُفتح كـ`showDialog`) فلا حاجة
/// لسلسلة اعتماديات طويلة. المتحكّم يقبل محرّكاً مجرّداً فيختبر بلا تثبيت
/// Tesseract على جهاز الاختبار.
///
/// **حيوي:** النصّ الناتج **قابل للتعديل دائماً** — فالدقة المقيسة 60%–76%
/// لا تكفي مستندات إدارية بلا مراجعة بشرية (قرار: `report/ocr_integration_decision.md`).
library;

import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../data/tesseract_engine.dart';
import '../../domain/ocr_engine.dart';
import '../../domain/ocr_engine_status.dart';
import '../../domain/ocr_result.dart';
import '../../domain/ocr_settings.dart';

/// حالة الشاشة — تُحدّد ما يُعرض (صورة/شريط تقدم/نص/خطأ).
enum OcrViewState {
  /// لم يُختر ملف بعد.
  idle,

  /// الصورة جاهزة ولم يبدأ الاستخراج.
  imageReady,

  /// الاستخراج جارٍ.
  processing,

  /// اكتمل الاستخراج والنصّ قابل للتحرير.
  done,

  /// تعذّر الاستخراج (سبب محفوظ في [OcrController.error]).
  error,
}

/// سبب الخطأ — تُترجم في الواجهة إلى نصّ عربي.
enum OcrError {
  /// Tesseract غير مثبّت على الجهاز.
  engineMissing,

  /// بيانات اللغة (`ara.traineddata`) مفقودة.
  languageDataMissing,

  /// البايتات ليست صورة صالحة.
  invalidImage,

  /// اكتمل الاستخراج بلا نصّ (صورة بلا كتابة مثلاً).
  noText,

  /// فشل داخلي (مهلة، صدفة، ملف تالف).
  extraction,
}

/// متحكّم شاشة استخراج النص من صورة.
class OcrController extends ChangeNotifier {
  OcrController({OcrEngine? engine}) : _engine = engine ?? TesseractEngine() {
    // فحص توفّر المحرّك عند الفتح حتى يظهر التلميح فوراً لو غاب Tesseract.
    unawaited(_refreshEngineStatus());
  }

  final OcrEngine _engine;

  OcrViewState _state = OcrViewState.idle;
  OcrError? _error;
  OcrResult? _result;
  OcrSettings _settings = const OcrSettings();
  OcrEngineStatus _engineStatus = OcrEngineStatus.ready;
  Uint8List? _imageBytes;
  String? _sourceName;
  String _editedText = '';
  int _pdfPageCount = 0;
  bool _disposed = false;

  OcrViewState get state => _state;
  OcrError? get error => _error;
  OcrResult? get result => _result;
  OcrSettings get settings => _settings;
  OcrEngineStatus get engineStatus => _engineStatus;
  Uint8List? get imageBytes => _imageBytes;
  String? get sourceName => _sourceName;

  /// النصّ الذي يراه المستخدم ويعدّله — هذا ما يُدرَج في المحرّر لا ناتج المحرّك.
  String get editedText => _editedText;

  /// عدد صور PDF المقطّعة إن كان المصدر PDF (0 = صورة واحدة).
  int get pdfPageCount => _pdfPageCount;

  /// هل يمكن الضغط على «استخراج النص» الآن؟
  bool get canExtract =>
      _imageBytes != null &&
      _state != OcrViewState.processing &&
      _engineStatus == OcrEngineStatus.ready;

  /// هل النصّ الحالي فارغ (لا معنى له إدراج فارغ).
  bool get hasTextToInsert => _editedText.trim().isNotEmpty;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  // ==========================================================================
  //  توفّر المحرّك
  // ==========================================================================

  Future<void> _refreshEngineStatus() async {
    try {
      _engineStatus = await _engine.status();
    } on Object {
      _engineStatus = OcrEngineStatus.missingBinary;
    }
    _notify();
  }

  /// يعيد فحص توفّر Tesseract (يُستدعى من زر إعادة المحاولة).
  Future<void> refreshEngineStatus() => _refreshEngineStatus();

  // ==========================================================================
  //  الاختيار
  // ==========================================================================

  /// يفتح حوار اختيار صورة (PNG/JPG/WebP/BMP/TIFF) ويحمّل أول واحدة.
  Future<bool> pickImage() async {
    final List<PlatformFile> picked;
    try {
      picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const <String>[
          'png',
          'jpg',
          'jpeg',
          'bmp',
          'tif',
          'tiff',
          'webp',
        ],
      );
    } on Object {
      _setState(OcrViewState.error, OcrError.invalidImage);
      return false;
    }
    if (picked.isEmpty) return false;

    final PlatformFile file = picked.first;
    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } on Object {
      _setState(OcrViewState.error, OcrError.invalidImage);
      return false;
    }
    return loadImageBytes(bytes, name: file.name);
  }

  /// يفتح حوار اختيار PDF ويقطّع صفحاته إلى صور (بحدّ أقصى 10 صفحات).
  ///
  /// **لماذا `Printing.raster`؟** لأنه تقطيع PDF المدمج في المشروع أصلاً
  /// (`printing` موجودة للتصدير) — فلا حاجة لفتح `lib/core/pdf/` المحظور،
  /// ولا تبعية جديدة.
  Future<bool> pickPdf() async {
    final List<PlatformFile> picked;
    try {
      picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const <String>['pdf'],
      );
    } on Object {
      _setState(OcrViewState.error, OcrError.invalidImage);
      return false;
    }
    if (picked.isEmpty) return false;

    final PlatformFile file = picked.first;
    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } on Object {
      _setState(OcrViewState.error, OcrError.invalidImage);
      return false;
    }
    return loadPdfBytes(bytes, name: file.name);
  }

  /// يحوّل بايتات PDF إلى صور صفحات ويحمّلها للاستخراج.
  Future<bool> loadPdfBytes(Uint8List pdfBytes, {required String name}) async {
    _setState(OcrViewState.processing);
    try {
      final List<Uint8List> pages = <Uint8List>[];
      await for (final PdfRaster page in Printing.raster(pdfBytes, dpi: 200)) {
        pages.add(await page.toPng());
        if (pages.length >= kMaxPdfPagesForOcr) break;
      }
      if (pages.isEmpty) {
        _setState(OcrViewState.error, OcrError.invalidImage);
        return false;
      }
      _pdfPageCount = pages.length;
      // تُحمّل كل الصفحات في صفّ داخلي — الاستخراج يُمرّ عليها واحدة واحدة.
      _pendingPages = pages;
      _imageBytes = pages.first;
      _sourceName = name;
      _result = null;
      _editedText = '';
      _error = null;
      _setState(OcrViewState.imageReady);
      return true;
    } on Object {
      _setState(OcrViewState.error, OcrError.invalidImage);
      return false;
    }
  }

  /// صفحات PDF المقطّعة غير المعالجة بعد (الصفحة الأولى محفوظة في [imageBytes]).
  List<Uint8List> _pendingPages = const <Uint8List>[];

  /// حدّ الصفحات المقطّعة من PDF (حماية من ملف ضخم يُعلّق الواجهة).
  static const int kMaxPdfPagesForOcr = 10;

  /// يحمّل بايتات صورة جاهزة (يُستخدم أيضاً في الاختبارات والحزم من مصادر أخرى).
  Future<bool> loadImageBytes(Uint8List bytes, {required String name}) async {
    _imageBytes = bytes;
    _sourceName = name;
    _pendingPages = const <Uint8List>[];
    _pdfPageCount = 0;
    _result = null;
    _editedText = '';
    _error = null;
    _setState(OcrViewState.imageReady);
    return true;
  }

  // ==========================================================================
  //  الاستخراج
  // ==========================================================================

  /// يستخرج النصّ من الصورة الحالية — كل الصفحات إن كان PDF.
  Future<void> extract() async {
    if (_imageBytes == null || _state == OcrViewState.processing) return;
    _setState(OcrViewState.processing);
    _error = null;
    try {
      final List<Uint8List> pages = _pendingPages.isEmpty
          ? <Uint8List>[_imageBytes!]
          : _pendingPages;
      final List<String> texts = <String>[];
      int words = 0;
      int elapsed = 0;
      double confidenceSum = 0;
      int confidenceCount = 0;
      OcrResult? last;

      for (int index = 0; index < pages.length; index++) {
        final OcrResult pageResult = await _engine.extract(
          image: pages[index],
          settings: _settings,
          sourceName: _sourceName == null
              ? null
              : pages.length == 1
              ? _sourceName
              : '$_sourceName (${index + 1}/${pages.length})',
        );
        texts.add(pageResult.text);
        words += pageResult.recognizedWords;
        elapsed += pageResult.elapsedMs;
        if (pageResult.confidence > 0) {
          confidenceSum += pageResult.confidence;
          confidenceCount++;
        }
        last = pageResult;
      }

      final String combined = texts.join('\n\n').trim();
      if (combined.isEmpty) {
        _setState(OcrViewState.error, OcrError.noText);
        return;
      }
      _result = last?.copyWith(
        text: combined,
        recognizedWords: words,
        elapsedMs: elapsed,
        confidence: confidenceCount == 0 ? 0 : confidenceSum / confidenceCount,
      );
      _editedText = combined;
      _setState(OcrViewState.done);
    } on OcrEngineUnavailableException catch (exception) {
      _engineStatus = exception.status;
      _setState(
        OcrViewState.error,
        exception.status == OcrEngineStatus.missingLanguageData
            ? OcrError.languageDataMissing
            : OcrError.engineMissing,
      );
    } on FormatException {
      _setState(OcrViewState.error, OcrError.invalidImage);
    } on Object {
      _setState(OcrViewState.error, OcrError.extraction);
    }
  }

  /// يعيد الاستخراج بعد تعديل الإعدادات (نفس الصورة).
  Future<void> retry() => extract();

  // ==========================================================================
  //  الإعدادات والتحرير
  // ==========================================================================

  void setLanguage(OcrLanguage language) {
    _settings = _settings.copyWith(language: language);
    _notify();
  }

  void setPsm(OcrPsm psm) {
    _settings = _settings.copyWith(psm: psm);
    _notify();
  }

  void setScale(double scale) {
    _settings = _settings.copyWith(
      scale: scale.clamp(OcrSettings.minScale, OcrSettings.maxScale),
    );
    _notify();
  }

  void setGrayscale(bool value) {
    _settings = _settings.copyWith(grayscale: value);
    _notify();
  }

  void setBinarize(bool value) {
    _settings = _settings.copyWith(binarize: value);
    _notify();
  }

  /// يحدّث النصّ المحرَّر (من حقل الإدخال).
  void updateText(String value) {
    if (_editedText == value) return;
    _editedText = value;
    _notify();
  }

  /// يعيد النصّ إلى آخر نتيجة استخراج (إلغاء التعديلات اليدوية).
  void revertToExtracted() {
    final OcrResult? current = _result;
    if (current == null) return;
    _editedText = current.text;
    _notify();
  }

  /// يمسح كل شيء ويعيد الشاشة إلى حالتها الأولى.
  void clear() {
    _imageBytes = null;
    _sourceName = null;
    _result = null;
    _editedText = '';
    _error = null;
    _pdfPageCount = 0;
    _pendingPages = const <Uint8List>[];
    _setState(OcrViewState.idle);
  }

  /// رسالة الخطأ العربية (تُستخدم في الواجهة بلا تمرير BuildContext هنا).
  String errorMessageAr() => switch (_error) {
    OcrError.engineMissing => 'لم يُعثر على Tesseract — ثبّته ثم أعد المحاولة.',
    OcrError.languageDataMissing =>
      'بيانات اللغة (ara.traineddata) غير مثبّتة مع Tesseract.',
    OcrError.invalidImage => 'صورة غير صالحة.',
    OcrError.noText => 'لم يُعثر على نص في الصورة.',
    OcrError.extraction => 'تعذّر استخراج النص. حاول مرة أخرى.',
    null => '',
  };

  void _setState(OcrViewState state, [OcrError? error]) {
    _state = state;
    if (state == OcrViewState.error) _error = error;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// امتداد لتسهيل عرض رسالة الخطأ بلغة الواجهة.
extension OcrErrorL10n on OcrError {
  /// نصّ الخطأ بلغة الواجهة (مع احتياطي عربي).
  String label(AppLocalizations? l10n) => switch (this) {
    OcrError.engineMissing =>
      l10n?.ocrEngineMissing ??
          'لم يُعثر على Tesseract — ثبّته ثم أعد المحاولة.',
    OcrError.languageDataMissing =>
      l10n?.ocrLanguageDataMissing ?? 'بيانات اللغة غير مثبّتة.',
    OcrError.invalidImage => l10n?.ocrInvalidImage ?? 'صورة غير صالحة.',
    OcrError.noText => l10n?.ocrNoTextFound ?? 'لم يُعثر على نص في الصورة.',
    OcrError.extraction =>
      l10n?.ocrError ?? 'تعذّر استخراج النص. حاول مرة أخرى.',
  };
}
