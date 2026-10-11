/// حالة توفّر محرّك الاستخراج على هذا الجهاز.
///
/// **لماذا enum لا رسالة؟** الرسالة تحتاج ترجمة (مفاتيح `ocr*`)، والحالة
/// بيانات قابلة للاختبار. تُبنى الرسالة في الواجهة من الحالة.
library;

enum OcrEngineStatus {
  /// جاهز للعمل.
  ready,

  /// `tesseract.exe` غير موجود — يحتاج تثبيت Tesseract.
  missingBinary,

  /// التنفيذي موجود لكن بيانات اللغة (`ara.traineddata`) مفقودة.
  missingLanguageData,

  /// التنفيذي موجود لكن لم يعمل (إصدار غير مدعوم أو تالف).
  binaryNotRunnable;

  bool get isReady => this == OcrEngineStatus.ready;
}
