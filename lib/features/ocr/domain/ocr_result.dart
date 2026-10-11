/// نتيجة استخراج OCR: النص + الثقة + مواضع الكلمات.
///
/// **لماذا نموذج مستقل؟** لأن «الدقة» في OCR ليست رقماً واحداً: نصّ قد يكون
/// صحيحاً حرفياً وبلا ترتيب (فشل تقطيع)، والعكس. لذلك نحتفظ بثلاثة أشياء:
/// النص كما يُسلَّم للمستخدم، ونسبة الثقة المتوسطة للكلمات (من Tesseract)،
/// ومربّعات الكلمات بصفحتها — تفيد لاحقاً في التطابق البصري وفي تشخيص
/// الأخطاء، ولا تُحمَّل على الواجهة شيئاً إن لم تحتجها.
library;

import 'dart:typed_data';

/// مربّع كلمة واحدة داخل الصورة بوحدات البكسل.
class WordBox {
  const WordBox({
    required this.text,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.confidence,
  });

  /// الكلمة كما قرأها المحرّك (قد تكون فارغة أو تشويشاً).
  final String text;

  /// موضع الكلمة في الصورة (بكسل) — يسار/أعلى/عرض/ارتفاع.
  final int left;
  final int top;
  final int width;
  final int height;

  /// ثقة Tesseract للكلمة على مقياس 0..100 (‎-1 تعني «بلا نتيجة»).
  final double confidence;

  Rect2 get rect => Rect2(left, top, width, height);
}

/// مستطيل صريح (بلا `dart:ui` كي يبقى النموذج قابلاً للاختبار في Dart خالص).
class Rect2 {
  const Rect2(this.left, this.top, this.width, this.height);

  final int left;
  final int top;
  final int width;
  final int height;
}

/// نتيجة استخراج واحدة.
class OcrResult {
  const OcrResult({
    required this.text,
    required this.confidence,
    required this.wordBoxes,
    required this.language,
    required this.elapsedMs,
    required this.imageWidth,
    required this.imageHeight,
    this.sourceName,
    this.totalWordsOverride,
  });

  /// النص المستخرَج كما يُعرض للمستخدم — **قابل للتعديل دائماً**.
  final String text;

  /// متوسط ثقة الكلمات المعروفة على مقياس 0..1 (‎0 = بلا ثقة معروفة).
  final double confidence;

  /// مواضع الكلمات داخل الصورة (بترتيب القراءة) — قد تكون فارغة.
  final List<WordBox> wordBoxes;

  /// اللغة المطلوبة فعلياً (مثل `ara+eng`).
  final String language;

  /// زمن الاستخراج على هذه الصفحة (ميلي ثانية).
  final int elapsedMs;

  /// أبعاد الصورة التي عُولجت (بعد أي تكبير) — تفيد في مطابقة الصناديق.
  final int imageWidth;
  final int imageHeight;

  /// اسم ملف المصدر (للعرض فقط).
  final String? sourceName;

  /// عدّاد كلمات إضافي لتجميع صفحات PDF (حين لا يكفي عدّ صناديق الصفحة الأخيرة).
  final int? totalWordsOverride;

  /// هل في النص ما يُفيد؟ (Tesseract قد يُعيد صفحة بلا كلمات).
  bool get hasText => text.trim().isNotEmpty;

  /// عدد الكلمات التي قُرئت بثقة معروفة.
  int get recognizedWords =>
      totalWordsOverride ??
      wordBoxes.where((WordBox box) => box.text.trim().isNotEmpty).length;

  /// نسخة بحقول معدّلة — تُستخدم لتجميع نتائج صفحات PDF في نتيجة واحدة.
  OcrResult copyWith({
    String? text,
    double? confidence,
    List<WordBox>? wordBoxes,
    String? language,
    int? elapsedMs,
    int? recognizedWords,
  }) {
    return OcrResult(
      text: text ?? this.text,
      confidence: confidence ?? this.confidence,
      wordBoxes: wordBoxes ?? this.wordBoxes,
      language: language ?? this.language,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      sourceName: sourceName,
      totalWordsOverride: recognizedWords ?? totalWordsOverride,
    );
  }

  /// الصيغة القصيرة للعرض: «الدقة 61% · 132 كلمة · 0.9 ثانية».
  String summaryAr() {
    final String percent = '${(confidence * 100).round()}%';
    final String words = '$recognizedWords كلمة';
    final String seconds = '${(elapsedMs / 1000).toStringAsFixed(1)} ثانية';
    return 'الدقة $percent · $words · $seconds';
  }
}

/// استثناء: فشل الاستخراج نفسه (صورة تالفة، مهلة، خطأ داخلي).
class OcrExtractionException implements Exception {
  const OcrExtractionException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'OcrExtractionException($message)';
}

/// حجم الصورة بعد المعالجة — يُستخدم في تقرير النتيجة.
typedef OcrImageSize = ({int width, int height});

/// بايتات صورة جاهزة للاستخراج.
typedef OcrImage = Uint8List;
