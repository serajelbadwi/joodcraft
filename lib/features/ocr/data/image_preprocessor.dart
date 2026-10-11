/// معالجة قبلية للصورة قبل الاستخراج: تكبير، رمادي، عتبة (Otsu).
///
/// **لماذا؟** التقرير المقيس يقول بالرقم: التكبير ×1.5 وحده أضاف ‎+7.6 نقاط
/// دقة على أصعب صورة، لأن Tesseract يعمل أحسن ما يكون على نصّ بمدى ~300dpi.
/// حزمة `image` (موجودة أصلاً في المشروع) تكفي — بلا أي تبعية جديدة.
library;

import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../domain/ocr_settings.dart';

/// نتيجة المعالجة: الصورة الجاهزة + أبعادها (للتقرير والمطابقة).
class PreprocessedImage {
  const PreprocessedImage({
    required this.bytes,
    required this.width,
    required this.height,
    required this.applied,
  });

  /// بايتات PNG جاهزة لـTesseract.
  final Uint8List bytes;

  final int width;
  final int height;

  /// ما طُبّق فعلاً (للعرض في الواجهة).
  final List<String> applied;
}

/// معالج صور صرف (دوال ثابتة بلا حالة) — قابل للاختبار بلا أي ملف تنفيذي.
abstract final class ImagePreprocessor {
  /// يطبّق الإعدادات على صورة ويُعيد PNG جاهزاً.
  ///
  /// يفشل بـ`FormatException` إن كانت البايتات ليست صورة معروفة (أو تالفة).
  static PreprocessedImage preprocess(
    Uint8List source, {
    required OcrSettings settings,
  }) {
    // فكّ الترميز قد يرمي استثناءات أخرى (RangeError من فاحصي الصيغ) —
    // فتُوحَّد إلى FormatException كي يكون العقد واحداً للاستدعاء.
    img.Image? decoded;
    try {
      decoded = img.decodeImage(source);
    } on Object {
      decoded = null;
    }
    if (decoded == null) {
      throw const FormatException('تعذّر فكّ ترميز الصورة.');
    }

    final List<String> applied = <String>[];
    img.Image image = decoded;

    // 1) الاتجاه (EXIF): صورة الجوال غالباً تكون مسجّلة «أفقية» وتُعرض يدوياً.
    //    `bakeOrientation` مدمج في فكّ الترميز عادةً، لكن لا ضرر من ضمانه.
    if (image.exif.imageIfd.hasOrientation) {
      image = img.bakeOrientation(image);
      applied.add('ضبط الاتجاه');
    }

    // 2) التكبير — أعلى مردود مقيس.
    if (settings.scale != 1.0) {
      final int width = (image.width * settings.scale).round();
      final int height = (image.height * settings.scale).round();
      image = img.copyResize(
        image,
        width: width,
        height: height,
        interpolation: img.Interpolation.cubic,
      );
      applied.add('تكبير ×${settings.scale.toStringAsFixed(1)}');
    }

    // 3) الرمادي — يُبسّط الباينية وينظّف التشويش اللوني.
    if (settings.grayscale) {
      image = img.grayscale(image);
      applied.add('رمادي');
    }

    // 4) العتبة (أبيض/أسود صافي) — اختياري.
    if (settings.binarize) {
      final int threshold = otsuThreshold(image);
      image = img.luminanceThreshold(image, threshold: threshold / 255);
      applied.add('عتبة $threshold');
    }

    final Uint8List encoded = img.encodePng(image);
    return PreprocessedImage(
      bytes: encoded,
      width: image.width,
      height: image.height,
      applied: applied,
    );
  }

  /// عتبة Otsu (0..255): العتبة التي تُقلّل التباين داخل كل من الفئتين
  /// (خلفية/حبر) — أفضل عتبة ثابتة للوثائق دون اعتماد على بياض الصفحة.
  static int otsuThreshold(img.Image image) {
    final List<int> histogram = List<int>.filled(256, 0);
    for (final img.Pixel pixel in image) {
      final num luminance = pixel.luminanceNormalized * 255;
      histogram[luminance.round().clamp(0, 255)]++;
    }

    final int total = image.width * image.height;
    double sum = 0;
    for (int level = 0; level < 256; level++) {
      sum += level * histogram[level];
    }

    double sumBackground = 0;
    int weightBackground = 0;
    double bestVariance = -1;
    int bestThreshold = 128;

    for (int threshold = 0; threshold < 256; threshold++) {
      weightBackground += histogram[threshold];
      if (weightBackground == 0) continue;
      final int weightForeground = total - weightBackground;
      if (weightForeground == 0) break;

      sumBackground += threshold * histogram[threshold];
      final double meanBackground = sumBackground / weightBackground;
      final double meanForeground = (sum - sumBackground) / weightForeground;
      final double variance =
          weightBackground.toDouble() *
          weightForeground.toDouble() *
          (meanBackground - meanForeground) *
          (meanBackground - meanForeground);
      if (variance > bestVariance) {
        bestVariance = variance;
        bestThreshold = threshold;
      }
    }
    return bestThreshold;
  }

  /// فكّ ترميز فقط (لمعاينة القياسات في الواجهة).
  static img.Image? decode(Uint8List bytes) => img.decodeImage(bytes);
}
