/// واجهة محرّك الاستخراج — عقد واحد بين الواجهة وأي تنفيذ.
///
/// **لماذا واجهة؟** لأن `TesseractEngine` يعتمد على ملف تنفيذي خارجي غير
/// موجود في بيئة الاختبارات، والاختبارات تحتاج بديلاً خفيفاً. كما تُتيح
/// استبدال المحرّك لاحقاً (FFI أو خدمة) بلا لمس الواجهة.
library;

import 'dart:typed_data';

import 'ocr_engine_status.dart';
import 'ocr_result.dart';
import 'ocr_settings.dart';

/// محرّك استخراج نص من صورة.
abstract class OcrEngine {
  const OcrEngine();

  /// يستخرج النص من بايتات صورة (PNG/JPEG/TIFF…) بالإعدادات المطلوبة.
  ///
  /// يُلقي [OcrExtractionException] عند فشل الاستخراج (صورة تالفة، مهلة، خطأ).
  Future<OcrResult> extract({
    required Uint8List image,
    required OcrSettings settings,
    String? sourceName,
  });

  /// فحص توفّر المحرّك على هذا الجهاز (بايتات اللغة مثلاً).
  Future<OcrEngineStatus> status();

  /// مسار الملف التنفيذي المستخدم — يُعرض للمستخدم عند غيابه.
  String get executableLabel;
}

/// استثناء: المحرّك غير متاح على هذا الجهاز (Tesseract أو بيانات اللغة).
class OcrEngineUnavailableException implements Exception {
  const OcrEngineUnavailableException(this.status);

  /// سبب عدم التوفّر — تُبنى منه رسالة عربية في الواجهة.
  final OcrEngineStatus status;

  @override
  String toString() => 'OcrEngineUnavailableException($status)';
}
