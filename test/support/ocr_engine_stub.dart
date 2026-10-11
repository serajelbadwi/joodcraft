/// محرّك OCR وهمي للاختبارات — لا يشغّل Tesseract ولا يحتاج تثبيته.
///
/// يحقن النتيجة أو الخطأ أو حالة التوفّر مباشرةً، ويحصي نداءات الاستخراج
/// كي تُتحقق الاختبارات من أن المستخدم «لم يُطلق العملية مرتين».
library;

import 'dart:typed_data';

import 'package:joodcraft/features/ocr/domain/ocr_engine.dart';
import 'package:joodcraft/features/ocr/domain/ocr_engine_status.dart';
import 'package:joodcraft/features/ocr/domain/ocr_result.dart';
import 'package:joodcraft/features/ocr/domain/ocr_settings.dart';

class FakeOcrEngine extends OcrEngine {
  FakeOcrEngine({
    OcrResult? result,
    this.statusValue = OcrEngineStatus.ready,
    this.error,
  }) : _result = result;

  /// النتيجة الافتراضية إن لم يُحدَّد [error].
  final OcrResult? _result;

  /// حالة التوفّر التي يُعيدها `status()`.
  final OcrEngineStatus statusValue;

  /// إن وُجد يُرمى في `extract` (بديل النتيجة).
  final Object? error;

  int extractCalls = 0;
  OcrSettings? lastSettings;

  @override
  Future<OcrResult> extract({
    required Uint8List image,
    required OcrSettings settings,
    String? sourceName,
  }) async {
    extractCalls++;
    lastSettings = settings;
    final Object? thrown = error;
    if (thrown != null) throw thrown;
    return _result ??
        OcrResult(
          text: 'نصّ تجريبي مستخرج',
          confidence: 0.61,
          wordBoxes: const <WordBox>[],
          language: settings.language.tesseractCode,
          elapsedMs: 900,
          imageWidth: 100,
          imageHeight: 50,
          sourceName: sourceName,
        );
  }

  @override
  Future<OcrEngineStatus> status() async => statusValue;

  @override
  String get executableLabel => 'fake-tesseract';
}
