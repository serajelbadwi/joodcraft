/// معالجة قبلية للصورة قبل الاستخراج: تكبير، رمادي، عتبة (Otsu)،
/// إزالة ضوضاء، وتصحيح الميل.
///
/// **لماذا؟** التقرير المقيس يقول بالرقم: التكبير ×1.5 وحده أضاف ‎+7.6 نقاط
/// دقة على أصعب صورة، لأن Tesseract يعمل أحسن ما يكون على نصّ بمدى ~300dpi.
/// حزمة `image` (موجودة أصلاً في المشروع) تكفي — بلا أي تبعية جديدة.
///
/// ## ترتيب المراحل (مقصود — لا يُبدَّل)
///
/// ```
/// 1) ضبط الاتجاه (EXIF)          — الجوال يسجّل «أفقية» ويعرضها يدوياً
/// 2) رمادي                       — يوحّد القناة ويُبسّط كل ما بعده
/// 3) تكبير                       — قبل أي تدوير كي لا تُفقد حِدّة الحرف
/// 4) تصحيح الميل                 — التدوير يزيد حِدّةً زائفة، فالتنعيم بعده
/// 5) إزالة الضوضاء               — يمحو آثار التدوير وبقع الغبار
/// 6) عتبة Otsu (أبيض/أسود)       — آخراً، على صورة نظيفة
/// ```
library;

import 'dart:math' as math;
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
  /// عرض الصورة المُصغَّرة المستخدَمة في تقدير الميل فقط.
  ///
  /// تقدير الزاوية لا يحتاج دقة الأصل — يكفي ~400 بكسل لعرض صفحة كاملة،
  /// والتصغير يُخفّض زمن البحث عن الزاوية إلى جزء من الثانية.
  static const int _probeWidth = 400;

  /// نافذة ثابتة تُقتطع من النسخة المدوّرة قبل حساب الإسقاط.
  ///
  /// التدوير يُكبّر اللوطة بمقدار يختلف باختلاف الزاوية، فلو قيس الإسقاط على
  /// كامل اللوطة لخرجت زوايا أكبر بلوطة أكبر فتُرجَّح بغير استحقاق. النافذة
  /// الثابتة تجعل المقارنة بين الزوايا عادلة.
  static const double _windowRatio = 0.92;

  /// خطوة البحث الأول عن الزاوية (درجات).
  static const double _coarseStep = 1.0;

  /// خطوة التنقيح الثانية حول الأفضل (درجات).
  static const double _fineStep = 0.25;

  /// أقلّ هامش يُجيز دوران صورة مستقيمة (نسبة من تباين الاستقامة).
  ///
  /// الميل الحقّ يرفع التباين رفعاً بيّناً لأن الأسطر تستقيم على الصفوف.
  /// وما دون هذا الهامش فرقٌ ضئيل لا يُبنى عليه تدوير يُضيف ضبابيةً مؤكّدة
  /// مقابل فائدة مشكوك فيها — فتُترك الصورة على استقامتها.
  static const double _minSkewMargin = 1.08;

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
    if (image.exif.imageIfd.hasOrientation) {
      image = img.bakeOrientation(image);
      applied.add('ضبط الاتجاه');
    }

    // 2) الرمادي — يُوحّد القناة ويُبسّط كل ما بعده.
    if (settings.grayscale && image.numChannels > 1) {
      image = img.grayscale(image);
      applied.add('رمادي');
    }

    // 3) التكبير — أعلى مردود مقيس.
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

    // 4) تصحيح الميل — يُقاس أولا، ولا يُدوَّر إن كان الميل تحت الحدّ.
    if (settings.deskew) {
      final double angle = detectSkewDegrees(image);
      if (angle.abs() >= OcrSettings.deskewThreshold) {
        image = rotateCorrecting(image, angle);
        applied.add('تصحيح ميل ${angle.toStringAsFixed(1)}°');
      } else {
        applied.add('مستقيم');
      }
    }

    // 5) إزالة الضوضاء — بعد التدوير كي تمحو حِدّته الزائفة.
    if (settings.denoise) {
      image = img.gaussianBlur(image, radius: 1);
      applied.add('إزالة ضوضاء');
    }

    // 6) رفع التباين — قبل العتبة كي تُبنى العتبة على مدى أوسع.
    //
    // `normalize` يمدّ القيم على كامل المدى (0..255) بدل أن تتجمّع في شريحة
    // ضيّقة منه. النصّ الباهت (حبر خفيف، صورة مظلّلة، كاميرا قديمة) يخرج
    // من ذلك واضحاً بدل رمادي شبه موحّد لا يفصل Otsu فيه شيئاً — وهي الحالة
    // التي تُخرج Tesseract نصّاً فارغاً أو ضعيفاً.
    if (settings.contrast) {
      image = img.normalize(image, min: 0, max: 255);
      applied.add('رفع تباين');
    }

    // 7) العتبة (أبيض/أسود صافي) — آخراً، على صورة نظيفة.
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

  // ==========================================================================
  //  تصحيح الميل
  // ==========================================================================

  /// يولّد زوايا البحث: خشن أولاً ثم تنقيح حول الأفضل.
  static List<double> _candidateAngles(
    img.Image image, {
    required double maxDegrees,
  }) {
    // لا يُبحث عن ميل أوسع من نصف أقصر بعد — ما زاد على ذلك يعني صورةً
    // مقطوعة أو مُدارة عمداً، والتدوير عندها يزيد الصورة اختلالاً.
    final double shortest = math.min(image.width, image.height).toDouble();
    final double effective = math.min(maxDegrees, shortest * 0.5);
    final List<double> angles = <double>[];
    for (
      double angle = -effective;
      angle <= effective + 0.001;
      angle += _coarseStep
    ) {
      angles.add(angle);
    }
    return angles;
  }

  /// يقيس ميل الصورة بـ**الملف الإسقاطي** (`projection profile`) على صورة
  /// مصغّرة.
  ///
  /// الطريقة الكلاسيكية: لكل زاوية مرشّحة يُدوَّر النصّ ثم يُحسب توزيع الحبر
  /// على الأسطر الأفقية. حين تُحاذي الأسطرُ صفوفَ الصورة يكون التوزيع
  /// **حادّاً**: كل صف إمّا حبرٌ وإمّا فراغ، فترتفع تباينه. وعند الميل تذوب
  /// الأسطر في ما حولها فينهار التباين. فأفضل زاوية = أعلى تباين.
  ///
  /// يُعيد `0.0` إن كان الميل المقيس تحت [OcrSettings.deskewThreshold]،
  /// فالصورة المستقيمة **لا تُدوَّر أبداً** (لا ضبابية بلا مقابل).
  static double detectSkewDegrees(
    img.Image image, {
    double? maxDegrees,
  }) {
    if (image.width < 32 || image.height < 32) return 0.0;
    final double limit = maxDegrees ?? OcrSettings.maxDeskewDegrees;

    // نسخة العمل: مصغّرة ومثنّاة (أسرع كثيراً والبؤرة لا تحتاج دقة).
    img.Image probe = image;
    if (image.width > _probeWidth) {
      probe = img.copyResize(
        image,
        width: _probeWidth,
        height: (image.height * _probeWidth / image.width).round(),
      );
    }
    if (probe.numChannels > 1) probe = img.grayscale(probe);

    final int threshold = otsuThreshold(probe);
    final img.Image ink = img.luminanceThreshold(
      probe,
      threshold: threshold / 255,
    );

    // ⚠️ **حاسم:** `copyRotate` يُكبّر اللوطة لتحتوي الدوران، والزوايا الجديدة
    // التي لم تأتِ من الأصل تكون **سوداء** (لا خلفية مُمرَّرة). والسواد في
    // هذه الصورة ثنائية اللون **= حبر**، فتُحسب زوايا الدوران «نصّاً» فيعلو
    // تباينها بلا حقّ. القياس كان لذلك يُرجع **أقصى زاوية** على صورة
    // مستقيمة تماماً (–12° لصورة ميلها صفر) ثم يدوّرها فيهافسد النصّ كلّه.
    // تبييض الخلفية يجعل الزوايا فراغاً لا حبراً، فيُقاس الحبر الحقيقي وحده.
    ink.backgroundColor = img.ColorRgb8(255, 255, 255);

    // النافذة الثابتة: نفس القياس لكل الزوايا كي تكون المقارنة عادلة.
    final int winW = (ink.width * _windowRatio).round();
    final int winH = (ink.height * _windowRatio).round();
    if (winW < 16 || winH < 16) return 0.0;

    // مرجع الاستقامة: تباين الإسقاط بلا دوران يُحسب مرّة واحدة ويقارن به
    // الأفضل. فإن لم يتغلّب عليه بهامش واضح فالصورة مستقيمة — ولا يُدوَّر
    // نصٌّ مستقيم أبداً (لا فائدة، وضبابية مؤكّدة).
    final double straightScore = _rowProjectionScore(ink, 0, winW, winH);

    double bestAngle = 0.0;
    double bestScore = straightScore;

    for (final double angle in _candidateAngles(
      probe,
      maxDegrees: limit,
    )) {
      if (angle.abs() < _fineStep) continue; // 0 محسوبة أصلاً
      final double score = _rowProjectionScore(ink, angle, winW, winH);
      if (score > bestScore) {
        bestScore = score;
        bestAngle = angle;
      }
    }

    // حافة المجال: إن وقَع الأفضل عند الحدّ فالقياس غير حاسم (لا يُعرف إن
    // كان الميل أكبر أو أن القياس انحرف) — فلا يُخاطر بالتدوير.
    if (bestAngle.abs() >= limit - _coarseStep) return 0.0;

    // التنقيح حول الأفضل بخطوة أرقّ.
    double refined = bestAngle;
    double refinedScore = bestScore;
    for (
      double angle = bestAngle - _coarseStep;
      angle <= bestAngle + _coarseStep + 0.001;
      angle += _fineStep
    ) {
      if (angle < -limit || angle > limit) continue;
      final double score = _rowProjectionScore(ink, angle, winW, winH);
      if (score > refinedScore) {
        refinedScore = score;
        refined = angle;
      }
    }

    // حافة الاستقامة: إن لم يتغلّب أفضل زاوية على **بلا دوران** بهامش واضح
    // فالصورة مستقيمة (أو الميل تحت حدّ الضجيج). تدويرها عندها ضبابيةٌ بلا
    // مقابل ⇒ يُعاد 0 ولا يمسّها الدوران.
    if (refinedScore < straightScore * _minSkewMargin) return 0.0;

    return refined;
  }

  /// تباين توزيع الحبر على الصفوف عند تدوير [ink] بزاوية [angle].
  ///
  /// يُدوَّر ثم تُقتطع نافذة مركزيّة بحجم ثابت، ثم يُحسب تباين إسقاط الصفوف
  /// (الحبر ⩾ نصف النطاع يُحسب أسود).
  ///
  /// [ink.backgroundColor] **يجب** أن يكون أبيضاً قبل النداء — وإلا عادت
  /// زوايا التدوير سوداء فزادت التباين بلا حقّ. (يضبطه [_detectSkewAngles].)
  static double _rowProjectionScore(
    img.Image ink,
    double angle,
    int winW,
    int winH,
  ) {
    if (angle.abs() < 0.001) {
      return _varianceOfRows(ink, 0, 0, winW, winH);
    }
    final img.Image rotated = img.copyRotate(
      ink,
      angle: angle,
      interpolation: img.Interpolation.nearest,
    );
    final int left = ((rotated.width - winW) / 2).floor();
    final int top = ((rotated.height - winH) / 2).floor();
    if (left < 0 || top < 0) return 0.0;
    return _varianceOfRows(rotated, left, top, winW, winH);
  }

  /// تباين عدد بكسلات الحبر في كل صف داخل النافذة، ثم مقارنته بمرجع
  /// الاستقامة. القرار النهائي في [_detectSkewAngles].
  ///
  /// التباين — لا المتوسط — هو المقياس: الميل لا يغيّر كمّ الحبر بل يذيب
  /// توزّعه، فينهار التباين عند الزاوية الخاطئة ولو بقيت كمّية الحبر ثابتة.
  static double _varianceOfRows(
    img.Image image,
    int left,
    int top,
    int winW,
    int winH,
  ) {
    final List<double> rows = List<double>.filled(winH, 0);
    final num cutoff = image.maxChannelValue ~/ 2;

    for (int y = 0; y < winH; y++) {
      final int row = top + y;
      if (row < 0 || row >= image.height) break;
      double count = 0;
      for (int x = 0; x < winW; x++) {
        final int col = left + x;
        if (col < 0 || col >= image.width) break;
        if (image.getPixel(col, row).r <= cutoff) count++;
      }
      rows[y] = count;
    }

    final double mean = rows.reduce((double a, double b) => a + b) / rows.length;
    double variance = 0;
    for (final double value in rows) {
      final double delta = value - mean;
      variance += delta * delta;
    }
    return variance / rows.length;
  }

  /// يدوّر الصورة لكي يصحّح ميلها: الزاوية المقيسة هي ميل النصّ، فالتدوير
  /// العكسي بها يُعيد الأسطر أفقيّةً.
  static img.Image rotateCorrecting(img.Image image, double degrees) {
    if (degrees.abs() < 0.001) return image;
    return img.copyRotate(image, angle: degrees);
  }

  /// فكّ ترميز فقط (لمعاينة القياسات في الواجهة).
  static img.Image? decode(Uint8List bytes) => img.decodeImage(bytes);
}
