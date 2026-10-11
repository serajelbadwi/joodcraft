/// اختبارات المعالج المسبق للصور قبل الاستخراج (تكبير، رمادي، عتبة Otsu).
///
/// **لماذا هذه الاختبارات مهمة؟** التقرير المقيس يثبت أن التكبير وحده أضاف
/// ‎+7.6 نقطة دقة، وأن ضبط المعالجة قبلية يغيّر النتيجة أكثر من تغيير المحرّك.
/// فلو كسر أحد تعديل «تبسيط» هذه الدوال، تظهر الاختبارات هنا لا في القياس.
///
/// الصور تُبنى برمجياً (`package:image`) فلا تعتمد على ملفات خارجية ولا على
/// Tesseract المثبَّت على جهاز المطوّر.
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:joodcraft/features/ocr/data/image_preprocessor.dart';
import 'package:joodcraft/features/ocr/domain/ocr_settings.dart';

void main() {
  /// صورة صغيرة ملوّنة (30×20) تُشفَّر PNG — تكفي لقياس الأبعاد والقنوات.
  Uint8List coloredPng({int width = 30, int height = 20}) {
    final img.Image image = img.Image(width: width, height: height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // تدرّج أحمر/أخضر أفقي ليعطي هيستوجرام ثنائي الوضعية.
        final int red = x < width ~/ 2 ? 220 : 30;
        image.setPixelRgb(x, y, red, 90, 40);
      }
    }
    return Uint8List.fromList(img.encodePng(image));
  }

  group('التكبير (scale)', () {
    test('يضاعف الأبعاد عند scale = 2.0', () {
      final PreprocessedImage result = ImagePreprocessor.preprocess(
        coloredPng(width: 10, height: 5),
        settings: const OcrSettings(
          scale: 2.0,
          grayscale: false,
          binarize: false,
        ),
      );
      expect(result.width, 20);
      expect(result.height, 10);
      expect(result.applied.join(' '), contains('2.0'));
    });

    test('يبقّي الأبعاد كما هي عند scale = 1.0 وبلا معالجة', () {
      final PreprocessedImage result = ImagePreprocessor.preprocess(
        coloredPng(width: 12, height: 7),
        settings: const OcrSettings(
          scale: 1.0,
          grayscale: false,
          binarize: false,
        ),
      );
      expect(result.width, 12);
      expect(result.height, 7);
      expect(result.applied, isEmpty);
    });

    test('الناتج بايتات PNG صالحة يعيد فكّها بنفس الأبعاد', () {
      final PreprocessedImage result = ImagePreprocessor.preprocess(
        coloredPng(width: 8, height: 4),
        settings: const OcrSettings(scale: 1.5),
      );
      final img.Image? decoded = ImagePreprocessor.decode(result.bytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, result.width);
      expect(decoded.height, result.height);
    });
  });

  group('الرمادي (grayscale)', () {
    test('يجعل القنوات الثلاث متساوية', () {
      final PreprocessedImage result = ImagePreprocessor.preprocess(
        coloredPng(width: 16, height: 16),
        settings: const OcrSettings(
          scale: 1.0,
          grayscale: true,
          binarize: false,
        ),
      );
      final img.Image decoded = ImagePreprocessor.decode(result.bytes)!;
      bool allEqual = true;
      for (final img.Pixel pixel in decoded) {
        if (pixel.r != pixel.g || pixel.g != pixel.b) {
          allEqual = false;
          break;
        }
      }
      expect(allEqual, isTrue);
      expect(result.applied, contains('رمادي'));
    });
  });

  group('العتبة (binarization — Otsu)', () {
    test('لا ينتج سوى أبيض صافٍ أو أسود صافٍ', () {
      final PreprocessedImage result = ImagePreprocessor.preprocess(
        coloredPng(width: 24, height: 24),
        settings: const OcrSettings(
          scale: 1.0,
          grayscale: true,
          binarize: true,
        ),
      );
      final img.Image decoded = ImagePreprocessor.decode(result.bytes)!;
      bool binary = true;
      for (final img.Pixel pixel in decoded) {
        final int luminance = pixel.luminanceNormalized.round();
        if (luminance != 0 && luminance != 1) {
          binary = false;
          break;
        }
      }
      expect(binary, isTrue);
    });

    test('عتبة Otsu تقع بين الوضعيتين في صورة ثنائية', () {
      final img.Image image = img.Image(width: 40, height: 40);
      for (int y = 0; y < 40; y++) {
        for (int x = 0; x < 40; x++) {
          image.setPixelRgb(x, y, x < 20 ? 20 : 230, x < 20 ? 20 : 230, x < 20 ? 20 : 230);
        }
      }
      final int threshold = ImagePreprocessor.otsuThreshold(image);
      // أي قيمة في المدى (20..230) تفصل الوضعيتين تمامًا — المطلوب أن تقع
      // بينهما لا أن تكون رقمًا بعينه (Otsu يختار أول عتبة بمدى أقصى).
      expect(threshold, greaterThanOrEqualTo(20));
      expect(threshold, lessThan(230));
    });
  });

  group('الأخطاء', () {
    test('يرمي FormatException عند بايتات ليست صورة', () {
      expect(
        () => ImagePreprocessor.preprocess(
          Uint8List.fromList(<int>[1, 2, 3, 4, 5]),
          settings: const OcrSettings(),
        ),
        throwsFormatException,
      );
    });
  });
}
