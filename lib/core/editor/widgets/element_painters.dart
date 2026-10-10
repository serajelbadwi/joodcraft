import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui' show PathMetric;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

import '../../models/decoration.dart';
import '../../models/shape_geometry.dart';
import '../../models/template_element.dart';
import '../../utils/hex_color.dart';
import '../canvas_geometry.dart';
import 'element_effects.dart';

/// رسم الختم متجهاً — مطابق تماماً لما يرسمه محرّك الـ PDF.
///
/// التطابق مقصود: دائرة مُعبّأة + حلقة داخلية + نجمة خماسية بنفس النِسب
/// (`starRatio`)، فيرى المستخدم في المحرر نفس ما سيخرج في الورقة.
class SealPainter extends CustomPainter {
  const SealPainter({
    required this.fillHex,
    required this.ringHex,
    required this.starHex,
    required this.starRatio,
  });

  final String fillHex;
  final String ringHex;
  final String starHex;
  final double starRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final double side = math.min(size.width, size.height);
    final double radius = side / 2;
    final Offset center = Offset(radius, radius);

    canvas.drawCircle(center, radius, Paint()..color = colorFromHex(fillHex));
    canvas.drawCircle(
      center,
      radius * 0.83,
      Paint()
        ..color = colorFromHex(ringHex)
        ..style = PaintingStyle.stroke
        ..strokeWidth = side * 0.045,
    );

    final double outer = radius * starRatio.clamp(0.1, 0.95);
    final double inner = outer * 0.42;
    final Path star = Path();
    for (int i = 0; i < 10; i++) {
      final double r = i.isEven ? outer : inner;
      final double angle = (math.pi / 5) * i - math.pi / 2;
      final Offset point = center +
          Offset(r * math.cos(angle), r * math.sin(angle));
      if (i == 0) {
        star.moveTo(point.dx, point.dy);
      } else {
        star.lineTo(point.dx, point.dy);
      }
    }
    star.close();
    canvas.drawPath(star, Paint()..color = colorFromHex(starHex));
  }

  @override
  bool shouldRepaint(SealPainter oldDelegate) =>
      oldDelegate.fillHex != fillHex ||
      oldDelegate.ringHex != ringHex ||
      oldDelegate.starHex != starHex ||
      oldDelegate.starRatio != starRatio;
}

/// رسم رمز استجابة سريعة حقيقي (نفس بيانات الباركود المستخدمة في الـ PDF).
class QrCodePainter extends CustomPainter {
  QrCodePainter({
    required this.data,
    required this.colorHex,
    required this.backgroundHex,
  });

  final String data;
  final String colorHex;
  final String backgroundHex;

  @override
  void paint(Canvas canvas, Size size) {
    final QrImage? image = buildQrImage(data);
    if (image == null) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = const Color(0xFFEEF1F6),
      );
      return;
    }

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = colorFromHex(backgroundHex, fallback: Colors.white),
    );

    final double module = size.shortestSide / image.moduleCount;
    final Paint paint = Paint()..color = colorFromHex(colorHex);
    for (int row = 0; row < image.moduleCount; row++) {
      for (int col = 0; col < image.moduleCount; col++) {
        if (!image.isDark(row, col)) continue;
        canvas.drawRect(
          Rect.fromLTWH(col * module, row * module, module + 0.4, module + 0.4),
          paint,
        );
      }
    }
  }

  /// بناء صورة QR بدرجة تصحيح عالية تتناسب مع طول النص.
  static QrImage? buildQrImage(String data) {
    final String payload = data.trim();
    if (payload.isEmpty) return null;
    try {
      final QrCode code = QrCode(
        _typeNumberFor(payload.length),
        QrErrorCorrectLevel.M,
      )..addData(payload);
      return QrImage(code);
    } catch (_) {
      return null;
    }
  }

  /// اختيار نسخة الرمز (1..10) بحسب حجم البيانات — بلا أي استثناءات.
  static int _typeNumberFor(int length) {
    if (length <= 14) return 1;
    if (length <= 26) return 2;
    if (length <= 42) return 3;
    if (length <= 62) return 4;
    if (length <= 84) return 5;
    if (length <= 106) return 6;
    if (length <= 122) return 7;
    if (length <= 152) return 8;
    if (length <= 180) return 9;
    return 10;
  }

  @override
  bool shouldRepaint(QrCodePainter oldDelegate) =>
      oldDelegate.data != data ||
      oldDelegate.colorHex != colorHex ||
      oldDelegate.backgroundHex != backgroundHex;
}

/// إطار متقطّع لعنصر غير معروف أو صورة مفقودة (تنبيه بصري لا يكسر العرض).
class DashedRectPainter extends CustomPainter {
  const DashedRectPainter({
    this.color = const Color(0xFF9CA3AF),
    this.strokeWidth = 1.4,
    this.dash = 6,
    this.gap = 4,
  });

  final Color color;
  final double strokeWidth;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final Path path = Path()..addRect(Offset.zero & size);
    canvas.drawPath(_dashPath(path, dash, gap), paint);
  }

  static Path _dashPath(Path source, double dash, double gap) {
    final Path result = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double end = math.min(distance + dash, metric.length);
        result.addPath(metric.extractPath(distance, end), Offset.zero);
        distance = end + gap;
      }
    }
    return result;
  }

  @override
  bool shouldRepaint(DashedRectPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.dash != dash ||
      oldDelegate.gap != gap;
}

/// شبكة توجيه خفيفة داخل ورقة التصميم.
class GridPainter extends CustomPainter {
  const GridPainter({required this.step, this.color = const Color(0x14000000)});

  final double step;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (step <= 4) return;
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) =>
      oldDelegate.step != step || oldDelegate.color != color;
}

/// تحويل أوامر المسار الهندسي المشتركة إلى [Path] لفلاتر.
Path shapePathFromCommands(List<ShapeCommand> commands) {
  final Path path = Path();
  for (final ShapeCommand command in commands) {
    switch (command) {
      case ShapeMove(:final double x, :final double y):
        path.moveTo(x, y);
      case ShapeLine(:final double x, :final double y):
        path.lineTo(x, y);
      case ShapeCubic(
          :final double x1,
          :final double y1,
          :final double x2,
          :final double y2,
          :final double x3,
          :final double y3,
        ):
        path.cubicTo(x1, y1, x2, y2, x3, y3);
      case ShapeClose():
        path.close();
    }
  }
  return path;
}

/// مسار جزء واحد من شكل مركّب — بإحداثيات **الشكل المركّب** وبالبكسل.
///
/// صندوق الجزء نسبي لأصل الشكل المركّب (انظر `applyShapeBoolean`)، ويُطبَّق
/// دورانه الموضعي هنا لأن الشكل الأمّ وحده يحمل دوران العنصر.
Path shapePartPath(ShapeElement part, double scale) => shapePathFromCommands(
      shapeOutline(
        kind: part.kind,
        width: part.box.width * scale,
        height: part.box.height * scale,
        radius: part.radius * scale,
        cornerRadii: part.cornerRadii == null
            ? null
            : <double>[for (final double r in part.cornerRadii!) r * scale],
        points: part.points,
        innerRadius: part.innerRadius,
        rotationDeg: part.rotation,
      ),
    ).shift(Offset(part.box.x * scale, part.box.y * scale));

/// عملية `dart:ui` المقابلة لكل عملية دمج منطقي.
PathOperation pathOperationFor(ShapeBooleanOp op) => switch (op) {
      ShapeBooleanOp.union => PathOperation.union,
      ShapeBooleanOp.subtract => PathOperation.difference,
      ShapeBooleanOp.intersect => PathOperation.intersect,
      ShapeBooleanOp.exclude => PathOperation.xor,
    };

/// **المسار الحقيقي** الناتج عن العملية المنطقية بين أجزاء الشكل المركّب.
///
/// يُبنى بـ [Path.combine] على هندسة المسارات نفسها (لا بقصّ اللوحة)، فيصير
/// الناتج مساراً واحداً قابلاً للتعديل: تُحذف الحدود المتداخلة في الدمج،
/// ويُفرَّغ المطروح، ويُقتطع التقاطع، ويُستثنى المتقاطع مع بقاء الأطراف.
Path compoundBooleanPath(ShapeElement shape, double scale) {
  final List<Path> parts = <Path>[
    for (final ShapeElement part in shape.booleanParts)
      shapePartPath(part, scale)..fillType = PathFillType.nonZero,
  ];
  if (parts.isEmpty) return Path();
  if (parts.length == 1 || shape.booleanOp == null) return parts.first;
  final PathOperation operation = pathOperationFor(shape.booleanOp!);
  final Path merged = parts.reduce(
    (Path a, Path b) => Path.combine(operation, a, b),
  );
  // نتيجة `Path.combine` تُملأ بقاعدة اللاتصفير فتبقى الفجوات المطروحة فارغة.
  merged.fillType = PathFillType.nonZero;
  return merged;
}

/// رسم الشكل المتجهي في المحرر — بنفس هندسة محرّك الـ PDF (تعبئة/تدرّج/
/// إطار متقطّع/ظل/قلب/عمليات دمج منطقي)، فيرى المستخدم ما سيُطبع بالضبط.
class ShapePainter extends CustomPainter {
  const ShapePainter({required this.shape, required this.scale});

  final ShapeElement shape;

  /// بكسلات الشاشة لكل وحدة تصميم.
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    if (w <= 0 || h <= 0) return;

    final bool flipped = shape.flipH || shape.flipV;
    if (flipped) {
      canvas.save();
      canvas.translate(w / 2, h / 2);
      canvas.scale(shape.flipH ? -1 : 1, shape.flipV ? -1 : 1);
      canvas.translate(-w / 2, -h / 2);
    }

    final Path outline = _outlinePath(w, h);
    // صندوق العنصر: مرجع كل طبقة عزل تُبنى أدناه.
    final Rect elementBounds = Offset.zero & Size(w, h);

    // الترتيب نفسه في Photoshop: توهّج خارجي ← ظل ← تعبئة/إطار ← توهّج داخلي.
    _paintOuterGlow(canvas, outline, elementBounds);
    _paintShadow(canvas, outline, elementBounds);
    _paintFill(canvas, outline, w, h);
    _paintStroke(canvas, outline);
    _paintInnerGlow(canvas, outline, elementBounds);

    if (flipped) canvas.restore();
  }

  /// يعزل رسم **تأثير واحد** في طبقة محفوظة ([Canvas.saveLayer]) محدودة بـ
  /// [bounds] = صندوق العنصر + مسافة أثر ذلك التأثير تحديداً (الانتشار +
  /// التمويه + الإزاحة).
  ///
  /// ما خارج [bounds] لا يُرسم مطلقاً: التمويه والتوهّج لا يتسرّبان إلى عنصر
  /// مجاور ولا إلى خلفية مساحة العمل، ولا يتشوّه أثرٌ بفعل ما تحته — ثم تُستعاد
  /// الطبقة بـ [Canvas.restore] فور انتهاء التأثير فلا تتراكم الطبقات.
  void _isolateEffect(
    Canvas canvas,
    Rect bounds,
    void Function(Canvas canvas) draw,
  ) {
    if (bounds.width <= 0 || bounds.height <= 0) return;
    canvas.saveLayer(bounds, Paint());
    // قصٌّ صريح داخل الطبقة: ضمانة إضافية أن الحدود محترمة حتى على المنصات
    // التي تعامل `bounds` بوصفها تقدير منطقة الطبقة لا قصّاً صريحاً لها.
    canvas.clipRect(bounds);
    draw(canvas);
    canvas.restore();
  }

  /// حدود طبقة التأثير: صندوق العنصر **ومساره إن خرج عنه** موسّقاً بمقدار
  /// [reach] في كل اتجاه، مع إزاحة [shift] لاتجاه الظل.
  Rect _effectBounds(
    Rect elementBounds,
    Path outline,
    double reach, {
    Offset shift = Offset.zero,
  }) {
    final Rect base = elementBounds.expandToInclude(outline.getBounds());
    return Rect.fromLTRB(
      base.left - reach + math.min(0, shift.dx),
      base.top - reach + math.min(0, shift.dy),
      base.right + reach + math.max(0, shift.dx),
      base.bottom + reach + math.max(0, shift.dy),
    );
  }

  /// **توهّج خارجي**: يُوسّع حدّ المسار (spread) ثم يُموّه (radius).
  ///
  /// التوسيع يُنفَّذ بحدّ (stroke) متّصل دائري بسماكة `2×spread` فوق التعبئة،
  /// فيتقدّم المسار من كل جهة بمقدار `spread` تماماً بلا تشويه هندسة المسار
  /// المركّب (لا حاجة لمضاعفة الإحداثيات).
  ///
  /// الرسم كله داخل طبقة معزولة محدودة بـ «صندوق العنصر + مسافة التوهج»
  /// (`spread` + مدى التمويه) فلا يتسرّب التوهّج إلى ما حول العنصر.
  void _paintOuterGlow(Canvas canvas, Path outline, Rect elementBounds) {
    final GlowEffect? glow = shape.outerGlow;
    if (glow == null || !glow.isVisible) return;

    final double radius = glow.radius * scale;
    final double spread = glow.spread * scale;
    final Rect bounds = _effectBounds(
      elementBounds,
      outline,
      spread + blurReach(radius / 2),
    );
    _isolateEffect(canvas, bounds, (Canvas canvas) {
      final Paint paint = Paint()
        ..color = colorFromHex(glow.colorHex)
            .withValues(alpha: glow.opacity.clamp(0, 1))
        ..style = PaintingStyle.fill
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..strokeWidth = spread * 2;
      if (radius > 0) {
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, radius / 2);
      }
      if (spread > 0) {
        // التعبئة توسّع الشكل، والحدّ يوسّع محيطه: النتيجة زيادة `spread` من
        // كل جهة للشكل المملوء أو المحدَّد على السواء.
        canvas.drawPath(outline, paint);
        paint.style = PaintingStyle.stroke;
      }
      canvas.drawPath(outline, paint);
    });
  }

  /// **توهّج داخلي**: حدّ عريض مطموس يُقتطع على المسار من الداخل.
  ///
  /// يُرسم في طبقة معزولة محدودة بصندوق العنصر: القصّ على المسار يكفي
  /// لمنع أي تسرّب، والطبقة تضمن ألّا يتجاوز الرسم صندوق العنصر أصلاً.
  void _paintInnerGlow(Canvas canvas, Path outline, Rect elementBounds) {
    final GlowEffect? glow = shape.innerGlow;
    if (glow == null || !glow.isVisible) return;

    final double radius = glow.radius * scale;
    final double spread = glow.spread * scale;
    _isolateEffect(canvas, elementBounds, (Canvas canvas) {
      canvas.clipPath(outline);
      final Paint paint = Paint()
        ..color = colorFromHex(glow.colorHex)
            .withValues(alpha: glow.opacity.clamp(0, 1))
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(radius + spread, 1) * 2;
      if (radius > 0) {
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, radius / 2);
      }
      canvas.drawPath(outline, paint);
    });
  }

  /// المسار الكامل (شكل واحد أو مسار مركّب ناتج عن عملية دمج منطقي).
  ///
  /// الشكل المركّب يُبنى بـ [Path.combine] فيصير **مساراً واحداً** حقيقياً:
  /// تُحذف الحدود المتداخلة ويُفرَّغ المطروح ويُقتطع التقاطع ويُستثنى المتقاطع.
  Path _outlinePath(double w, double h) {
    if (!shape.isCompound) {
      return shapePathFromCommands(shapeOutline(
        kind: shape.kind,
        width: w,
        height: h,
        radius: shape.radius * scale,
        cornerRadii: shape.cornerRadii == null
            ? null
            : <double>[for (final double r in shape.cornerRadii!) r * scale],
        points: shape.points,
        innerRadius: shape.innerRadius,
      ));
    }
    return compoundBooleanPath(shape, scale);
  }

  /// **ظل متقدّم**: نسخة من المسار مُوسّعة بالانتشار ومُزاحة بإزاحة الظل،
  /// مموّهة إن كان لها تمويه.
  ///
  /// الرسم محصور في طبقة محدودة بـ «صندوق العنصر + الانتشار + الإزاحة +
  /// التمويه»: ما يتجاوز المسار مسافة الانتشار الفعلية (كما يحدث للأشكال
  /// الممتدة حيث يُوسَّع الظلّ بمعامل نسبيّ) يُقصّ عند الحدّ، فيبقى الظلّ في
  /// مسافته المحددة ولا يتسرّب إلى العناصر المجاورة أو مساحة العمل.
  void _paintShadow(Canvas canvas, Path outline, Rect elementBounds) {
    final ShapeShadow? shadow = shape.shadow;
    if (shadow == null) return;
    // المسار المركّب مسار واحد حقيقي من `Path.combine`، فيرسم ظلّه بلا
    // حدود داخلية زائدة (لا حاجة لقصّ ولا لقاعدة الزوجي-الفردي).
    final double spread = shadow.spread * scale;
    Path target = outline;
    if (spread > 0) {
      target = outline.shift(Offset.zero);
      final Rect bounds = outline.getBounds();
      if (bounds.width > 0 && bounds.height > 0) {
        final double factor =
            1 + spread / math.min(bounds.width, bounds.height);
        target = outline.transform(
          (Matrix4.identity()
                ..translateByDouble(bounds.center.dx, bounds.center.dy, 0, 1)
                ..scaleByDouble(factor, factor, 1, 1)
                ..translateByDouble(-bounds.center.dx, -bounds.center.dy, 0, 1))
              .storage,
        );
      }
    }
    final Path moved = target.shift(Offset(
      shadow.offsetX * scale,
      shadow.offsetY * scale,
    ));
    final double alpha = (shadow.blurRadius > 0 ? 0.55 : 0.9) *
        shadow.opacity.clamp(0, 1);
    final Paint paint = Paint()
      ..color = colorFromHex(shadow.colorHex).withValues(alpha: alpha)
      ..style = PaintingStyle.fill;
    if (shadow.blurRadius > 0) {
      paint.maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        shadow.blurRadius * scale / 2,
      );
    }
    final Rect bounds = _effectBounds(
      elementBounds,
      outline,
      spread + blurReach(shadow.blurRadius * scale / 2),
      shift: Offset(shadow.offsetX * scale, shadow.offsetY * scale),
    );
    _isolateEffect(canvas, bounds, (Canvas canvas) {
      canvas.drawPath(moved, paint);
    });
  }

  /// التعبئة ترسم المسار النهائي **مباشرة** — للمركّب مسار واحد مدمَج، فلا
  /// قصّ ولا تراكب: ما يُملأ هو نتيجة العملية المنطقية بالضبط.
  void _paintFill(Canvas canvas, Path outline, double w, double h) {
    final bool hasFill = shape.gradient != null || shape.fillHex != null;
    if (!hasFill) return;
    canvas.drawPath(outline, _fillPaint(w, h));
  }

  Paint _fillPaint(double w, double h) {
    final double alpha = shape.fillOpacity.clamp(0.0, 1.0);
    final ShapeGradient? gradient = shape.gradient;
    if (gradient != null) {
      final Color start = colorFromHex(gradient.startHex).withValues(alpha: alpha);
      final Color end = colorFromHex(gradient.endHex).withValues(alpha: alpha);
      final Shader shader;
      if (gradient.kind == ShapeFillKind.radialGradient) {
        shader = ui.Gradient.radial(
          Offset(w / 2, h / 2),
          math.sqrt(w * w + h * h) / 2,
          <Color>[start, end],
        );
      } else {
        final ({double sx, double sy, double ex, double ey}) axis =
            gradientAxis(w, h, gradient.angle);
        shader = ui.Gradient.linear(
          Offset(axis.sx, axis.sy),
          Offset(axis.ex, axis.ey),
          <Color>[start, end],
        );
      }
      return Paint()..shader = shader;
    }
    return Paint()
      ..color = colorFromHex(shape.fillHex).withValues(alpha: alpha);
  }

  void _paintStroke(Canvas canvas, Path outline) {
    final String? strokeHex = shape.strokeHex;
    if (strokeHex == null || shape.strokeWidth <= 0) return;
    final Paint paint = Paint()
      ..color = colorFromHex(strokeHex)
      ..style = PaintingStyle.stroke
      ..strokeWidth = shape.strokeWidth * scale
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final List<double>? dash = shape.dashPattern;
    final Path target = (dash == null || dash.isEmpty)
        ? outline
        : _dashed(outline, dash);
    canvas.drawPath(target, paint);
  }

  /// تقطيع المسار إلى شرطات حسب [pattern] (تبدأ بشرطة ثم فجوة...).
  Path _dashed(Path source, List<double> pattern) {
    final Path result = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0;
      int index = 0;
      while (distance < metric.length) {
        final double segment = pattern[index % pattern.length] * scale;
        if (segment <= 0) {
          index++;
          if (index > pattern.length * 2) break;
          continue;
        }
        final double end = math.min(distance + segment, metric.length);
        if (index.isEven) {
          result.addPath(metric.extractPath(distance, end), Offset.zero);
        }
        distance = end;
        index++;
      }
    }
    return result;
  }

  @override
  bool shouldRepaint(ShapePainter oldDelegate) =>
      oldDelegate.shape != shape || oldDelegate.scale != scale;
}

/// خصائص بصرية مركزية للعناصر المشتركة بين الشاشات.
abstract final class EditorColors {
  const EditorColors._();

  /// لون إطار التحديد.
  static const Color selection = Color(0xFFC7A26B);

  /// لون مقابس التحجيم.
  static const Color handle = Color(0xFFC7A26B);

  /// لون العنصر غير المعروف.
  static const Color unknown = Color(0xFF9CA3AF);

  /// لون خطوط الإرشاد الذكية (أزرق سماوي مميز).
  static const Color guide = Color(0xFF22B8CF);
}

/// رسم خطوط الإرشاد الذكية فوق اللوحة أثناء السحب فقط.
///
/// الخطوط تأتي بوحدات التصميم، وتُحوَّل إلى بكسلات اللوحة بمعامل [scale].
class SmartGuidesPainter extends CustomPainter {
  const SmartGuidesPainter({required this.guides, required this.scale});

  final List<SmartGuide> guides;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    if (guides.isEmpty) return;
    final Paint paint = Paint()
      ..color = EditorColors.guide
      ..strokeWidth = 1;
    for (final SmartGuide guide in guides) {
      if (guide.vertical) {
        final double x = guide.position * scale;
        canvas.drawLine(
          Offset(x, guide.start * scale),
          Offset(x, guide.end * scale),
          paint,
        );
      } else {
        final double y = guide.position * scale;
        canvas.drawLine(
          Offset(guide.start * scale, y),
          Offset(guide.end * scale, y),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(SmartGuidesPainter oldDelegate) =>
      oldDelegate.scale != scale ||
      !listEquals(oldDelegate.guides, guides);
}

/// رسم الزخرفة المتجهية الإجرائية في المحرر — مطابق تماماً لما يرسمه محرّك
/// الـ PDF (نفس [VectorDecor.build])، فيرى المستخدم ما سيُطبع بالضبط.
class DecorationPainter extends CustomPainter {
  const DecorationPainter({required this.spec});

  final DecorSpec spec;

  @override
  void paint(Canvas canvas, Size size) {
    for (final DecorPath path in VectorDecor.build(spec, size.width, size.height)) {
      final Paint paint = Paint()
        ..color = colorFromHex(path.colorHex)
        ..style = path.stroke ? PaintingStyle.stroke : PaintingStyle.fill
        ..strokeWidth = path.strokeWidth > 0 ? path.strokeWidth : 1;

      final Path target = Path();
      for (final DecorSegment segment in path.segments) {
        switch (segment) {
          case DecorMove(:final double x, :final double y):
            target.moveTo(x, y);
          case DecorLine(:final double x, :final double y):
            target.lineTo(x, y);
          case DecorCubic(
              :final double x1,
              :final double y1,
              :final double x2,
              :final double y2,
              :final double x,
              :final double y,
            ):
            target.cubicTo(x1, y1, x2, y2, x, y);
        }
      }
      if (path.closed) target.close();
      canvas.drawPath(target, paint);
    }
  }

  @override
  bool shouldRepaint(DecorationPainter oldDelegate) => oldDelegate.spec != spec;
}
