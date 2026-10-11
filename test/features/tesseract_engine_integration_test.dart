/// اختبار تكامل حقيقي مع Tesseract — يشغّل المحرّك على صورة العيّنة فعلاً.
///
/// **يتخطّى نفسه بلطف إن غاب Tesseract** (بيئة CI أو جهاز بلا تثبيت) عبر
/// [markTestSkipped]، فلا يكسر حزمة الاختبارات على جهاز لا تخصّه الأداة.
/// وجود هذا الاختبار يحمي من انزلاق «تبسيط» يُفسد استدعاء العملية الجانبية
/// أو تفسير ملف TSV — أي عطل لا تكشفه اختبارات المحرّك الوهمي.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/ocr/data/tesseract_engine.dart';
import 'package:joodcraft/features/ocr/domain/ocr_engine_status.dart';
import 'package:joodcraft/features/ocr/domain/ocr_result.dart';
import 'package:joodcraft/features/ocr/domain/ocr_settings.dart';

void main() {
  // `path_provider` (إن لم يُحقن المزوّد) يحتاج الـbinding.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('استخراج حقيقي من صورة العيّنة (يتخطّى إن غاب Tesseract)', () async {
    final TesseractEngine engine = TesseractEngine(
      tempDirProvider: () => Directory.systemTemp,
    );

    final OcrEngineStatus status = await engine.status();
    if (status != OcrEngineStatus.ready) {
      markTestSkipped('Tesseract غير متاح على هذا الجهاز ($status).');
      return;
    }

    final File sample = File('tool/ocr_test/sample_medium.PNG');
    if (!sample.existsSync()) {
      markTestSkipped('صورة العيّنة غير موجودة (tool/ocr_test).');
      return;
    }

    final OcrResult result = await engine.extract(
      image: sample.readAsBytesSync(),
      settings: const OcrSettings(scale: 1.5, psm: OcrPsm.singleBlock),
      sourceName: sample.path,
    );

    // نصّ مجلّة عربية معروفة — استخراج بلا أي كلمة يعني فشل الاتصال بالمحرّك.
    expect(result.hasText, isTrue);
    expect(result.recognizedWords, greaterThan(10));
    expect(result.wordBoxes, isNotEmpty);
    expect(result.confidence, greaterThan(0.2));
    expect(result.elapsedMs, greaterThan(0));
    expect(result.language, 'ara+eng');
    // نظافة الملفات المؤقتة: مجلد العمل يُحذف بعد الاستخراج.
    final Directory temp = await Directory.systemTemp.createTemp('jood_ocr_it_');
    final String tempPath = temp.path;
    await temp.delete(recursive: true);
    expect(Directory(tempPath).existsSync(), isFalse);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
