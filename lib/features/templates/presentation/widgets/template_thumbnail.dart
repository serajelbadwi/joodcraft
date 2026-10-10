import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/models/decoration.dart';
import '../../../../core/models/template_document.dart';
import '../../../../core/models/template_element.dart';
import '../../../../core/utils/hex_color.dart';

/// صورة مصغّرة (Thumbnail) متجهية لقالب — تُرسم بالكامل برمجياً من
/// [TemplateDocument] بلا أي صورة نقطية أو جلب من الشبكة.
///
/// تعيد استخدام هندسة [TemplateDocument] نفسها (مقاس الصفحة، إزاحة التوسيط،
/// ومعامل التحجيم [TemplateDocument.scale]) التي يستخدمها المحرّر ومحرّك
/// الـ PDF، فتبقى المعاينة مطابقة للقالب الفعلي حتى قبل فتحه.
class TemplateThumbnail extends StatelessWidget {
  const TemplateThumbnail({
    super.key,
    required this.document,
    this.radius = 10,
    this.shadow = false,
  });

  final TemplateDocument document;

  /// نصف قطر حواف الورقة.
  final double radius;

  /// إضافة ظل خفيف تحت الورقة (يمنح إحساس الورق الحقيقي).
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final double ratio = document.pageWidthPt <= 0 || document.pageHeightPt <= 0
        ? 1.4142
        : document.pageWidthPt / document.pageHeightPt;

    final Widget paper = AspectRatio(
      aspectRatio: ratio,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _ThumbnailPainter(document),
          child: const SizedBox.expand(),
        ),
      ),
    );

    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: shadow
              ? <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: paper,
        ),
      ),
    );
  }
}

class _ThumbnailPainter extends CustomPainter {
  _ThumbnailPainter(this.document);

  final TemplateDocument document;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final Rect page = Offset.zero & size;
    canvas.drawRect(page, Paint()..color = const Color(0xFFFFFFFF));
    _paintBackground(canvas, page);
    canvas.save();
    canvas.clipRect(page);

    // تحويل وحدات التصميم ⇒ بكسلات الصورة المصغّرة.
    final double s = size.width / document.pageWidthPt;
    final double scale = document.scale;
    final double offsetX = document.offsetX;
    final double offsetY = document.offsetY;

    Offset mapPoint(double x, double y) => Offset(
          (offsetX + x * scale) * s,
          (offsetY + y * scale) * s,
        );

    Rect mapRect(ElementBox box) => Rect.fromPoints(
          mapPoint(box.x, box.y),
          mapPoint(box.x + box.width, box.y + box.height),
        );

    /// طول بوحدات التصميم ⇒ بكسلات.
    double len(double value) => value * scale * s;

    for (final TemplateElement element in document.visibleElements) {
      final Rect rect = mapRect(element.box);
      if (rect.isEmpty) continue;
      switch (element) {
        case TextElement():
          _paintText(canvas, rect, element, len, s * scale);
        case ShapeElement():
          _paintShape(canvas, rect, element, len);
        case SealElement():
          _paintSeal(canvas, rect, element, len);
        case DecorationElement():
          _paintDecoration(canvas, rect, element, mapPoint, len);
        case SignatureElement():
          _paintSignature(canvas, rect, element, len);
        case ImageElement():
          _paintImagePlaceholder(canvas, rect);
        case QrElement():
          _paintQr(canvas, rect, element);
        case UnknownElement():
          break;
      }
    }

    canvas.restore();

    // حدّ رقيق يعرّف حدود الورقة مهما كان لون الخلفية.
    canvas.drawRect(
      page.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black.withValues(alpha: 0.10),
    );
  }

  void _paintBackground(Canvas canvas, Rect page) {
    final BackgroundGradient? gradient = document.backgroundGradient;
    if (gradient != null) {
      final Color start = colorFromHex(gradient.startHex,
          fallback: colorFromHex(document.backgroundHex, fallback: Colors.white));
      final Color end = colorFromHex(gradient.endHex, fallback: start);
      canvas.drawRect(
        page,
        Paint()
          ..shader = LinearGradient(
            begin: _beginFor(gradient.direction),
            end: _endFor(gradient.direction),
            colors: <Color>[start, end],
          ).createShader(page),
      );
      return;
    }
    canvas.drawRect(
      page,
      Paint()..color = colorFromHex(document.backgroundHex, fallback: Colors.white),
    );
  }

  Alignment _beginFor(GradientDirection direction) => switch (direction) {
        GradientDirection.horizontal => Alignment.centerLeft,
        GradientDirection.diagonal => Alignment.topLeft,
        GradientDirection.vertical => Alignment.topCenter,
      };

  Alignment _endFor(GradientDirection direction) => switch (direction) {
        GradientDirection.horizontal => Alignment.centerRight,
        GradientDirection.diagonal => Alignment.bottomRight,
        GradientDirection.vertical => Alignment.bottomCenter,
      };

  /// يرسم النص كأشرطة رمادية داكنة تحاكي أسطر الكتابة (بلا خطوط فعلية).
  void _paintText(
    Canvas canvas,
    Rect rect,
    TextElement element,
    double Function(double) len,
    double k,
  ) {
    final Color color = colorFromHex(element.colorHex, fallback: Colors.black);
    final double alpha =
        (0.62 * element.opacity).clamp(0.05, 1.0).toDouble();

    final String? backgroundHex = element.backgroundHex;
    if (backgroundHex != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        Paint()
          ..color = colorFromHex(backgroundHex, fallback: Colors.transparent)
              .withValues(alpha: 0.9),
      );
    }

    final double fontPx = math.max(len(element.fontSize), 1.4);
    final double lineH = math.max(fontPx * element.lineHeight, 1.6);
    final double barH = math.max(fontPx * 0.52, 0.9);
    final int lines = math.max(1, (rect.height / lineH).floor()).clamp(1, 8);

    final Paint paint = Paint()..color = color.withValues(alpha: alpha);
    double top = rect.top + (rect.height - lines * lineH) / 2;
    for (int i = 0; i < lines; i++) {
      if (top + barH > rect.bottom + 0.5) break;
      final bool last = i == lines - 1 && lines > 1;
      final double width = last ? rect.width * 0.62 : rect.width;
      final double left = switch (element.align) {
        ElementTextAlign.center => rect.left + (rect.width - width) / 2,
        ElementTextAlign.end => rect.right - width,
        _ => rect.left,
      };
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, width, barH),
          Radius.circular(barH / 2),
        ),
        paint,
      );
      top += lineH;
    }
  }

  void _paintShape(
    Canvas canvas,
    Rect rect,
    ShapeElement element,
    double Function(double) len,
  ) {
    if (element.kind == ShapeKind.line) {
      final Paint stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(len(element.strokeWidth), 0.8)
        ..color = colorFromHex(element.strokeHex ?? element.fillHex ?? '#000000');
      canvas.drawLine(
        Offset(rect.left, rect.center.dy),
        Offset(rect.right, rect.center.dy),
        stroke,
      );
      return;
    }

    final Path path = _shapePath(rect, element);
    final Paint? fill = _shapeFill(rect, element);
    if (fill != null) canvas.drawPath(path, fill);
    if (element.strokeHex != null && element.strokeWidth > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(len(element.strokeWidth), 0.6)
          ..color = colorFromHex(element.strokeHex),
      );
    }
  }

  Paint? _shapeFill(Rect rect, ShapeElement element) {
    final ShapeGradient? gradient = element.gradient;
    if (gradient != null && gradient.kind.isGradient) {
      final Color start = colorFromHex(gradient.startHex, fallback: Colors.grey);
      final Color end = colorFromHex(gradient.endHex, fallback: start);
      if (gradient.kind == ShapeFillKind.radialGradient) {
        return Paint()
          ..shader = RadialGradient(colors: <Color>[start, end])
              .createShader(rect);
      }
      final double radians = gradient.angle * math.pi / 180;
      return Paint()
        ..shader = LinearGradient(
          begin: Alignment(-math.cos(radians), -math.sin(radians)),
          end: Alignment(math.cos(radians), math.sin(radians)),
          colors: <Color>[start, end],
        ).createShader(rect);
    }
    if (element.fillHex == null) return null;
    return Paint()
      ..color = colorFromHex(element.fillHex)
          .withValues(alpha: element.fillOpacity.clamp(0.0, 1.0));
  }

  Path _shapePath(Rect rect, ShapeElement element) {
    final Path path = Path();
    switch (element.kind) {
      case ShapeKind.rect:
      case ShapeKind.line:
        final double radius = element.cornerRadii != null &&
                element.cornerRadii!.isNotEmpty
            ? element.cornerRadii!.reduce(math.max)
            : element.radius;
        final double r = math.min(radius, math.min(rect.width, rect.height) / 2);
        path.addRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(math.max(r, 0))),
        );
      case ShapeKind.ellipse:
        path.addOval(rect);
      case ShapeKind.polygon:
        path.addPath(
          _starPath(rect.center, rect.shortestSide / 2, 1, element.points),
          Offset.zero,
        );
      case ShapeKind.star:
        path.addPath(
          _starPath(
            rect.center,
            rect.shortestSide / 2,
            element.innerRadius.clamp(0.05, 0.95),
            element.points < 3 ? 5 : element.points,
          ),
          Offset.zero,
        );
    }
    return path;
  }

  Path _starPath(Offset center, double radius, double inner, int points) {
    final int n = points < 3 ? 5 : points;
    final Path path = Path();
    final double step = math.pi / n;
    for (int i = 0; i < n * 2; i++) {
      final double r = i.isEven ? radius : radius * inner;
      final double angle = -math.pi / 2 + i * step;
      final Offset p = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  void _paintSeal(
    Canvas canvas,
    Rect rect,
    SealElement element,
    double Function(double) len,
  ) {
    final double side = len(element.squareSide(element.box));
    if (side <= 0) return;
    final Offset center = rect.center;
    final double radius = side / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()..color = colorFromHex(element.fillHex).withValues(alpha: element.opacity),
    );
    canvas.drawCircle(
      center,
      radius * 0.82,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(radius * 0.09, 0.5)
        ..color = colorFromHex(element.ringHex).withValues(alpha: element.opacity),
    );
    final Color star = colorFromHex(element.starHex).withValues(alpha: element.opacity);
    canvas.drawPath(
      _starPath(center, radius * element.starRatio.clamp(0.1, 0.95), 0.45, 5),
      Paint()..color = star,
    );
  }

  void _paintDecoration(
    Canvas canvas,
    Rect rect,
    DecorationElement element,
    Offset Function(double, double) mapPoint,
    double Function(double) len,
  ) {
    final List<DecorPath> paths =
        VectorDecor.build(element.spec, element.box.width, element.box.height);
    if (paths.isEmpty) return;

    canvas.save();
    canvas.clipRect(rect.inflate(1));
    for (final DecorPath decor in paths) {
      final Path path = Path();
      bool started = false;
      for (final DecorSegment segment in decor.segments) {
        switch (segment) {
          case DecorMove(:final double x, :final double y):
            final Offset p = mapPoint(element.box.x + x, element.box.y + y);
            path.moveTo(p.dx, p.dy);
            started = true;
          case DecorLine(:final double x, :final double y):
            final Offset p = mapPoint(element.box.x + x, element.box.y + y);
            if (!started) {
              path.moveTo(p.dx, p.dy);
              started = true;
            } else {
              path.lineTo(p.dx, p.dy);
            }
          case DecorCubic(
              :final double x1,
              :final double y1,
              :final double x2,
              :final double y2,
              :final double x,
              :final double y
            ):
            final Offset c1 = mapPoint(element.box.x + x1, element.box.y + y1);
            final Offset c2 = mapPoint(element.box.x + x2, element.box.y + y2);
            final Offset end = mapPoint(element.box.x + x, element.box.y + y);
            if (!started) {
              path.moveTo(c1.dx, c1.dy);
              started = true;
            }
            path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
        }
      }
      if (decor.closed) path.close();

      final Color color =
          colorFromHex(decor.colorHex).withValues(alpha: element.opacity);
      if (decor.stroke) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(len(decor.strokeWidth), 0.4)
            ..color = color,
        );
      } else {
        canvas.drawPath(path, Paint()..color = color);
      }
    }
    canvas.restore();
  }

  void _paintSignature(
    Canvas canvas,
    Rect rect,
    SignatureElement element,
    double Function(double) len,
  ) {
    final List<SignatureSlotRect> slots = element.slotLayout(element.box.width);
    final Paint line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = colorFromHex(element.nameColorHex, fallback: Colors.black54)
          .withValues(alpha: 0.65);
    final Paint text = Paint()
      ..color = Colors.black.withValues(alpha: 0.45 * element.opacity);

    for (final SignatureSlotRect slot in slots) {
      final double left = rect.left + slot.left * rect.width / element.box.width;
      final double width = slot.width * rect.width / element.box.width;
      final double baseline = rect.bottom - math.max(len(12), rect.height * 0.28);
      canvas.drawLine(
        Offset(left, baseline),
        Offset(left + width, baseline),
        line,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left + width * 0.18, baseline - len(16), width * 0.64, 1.6),
          const Radius.circular(1),
        ),
        text,
      );
    }
  }

  void _paintImagePlaceholder(Canvas canvas, Rect rect) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      Paint()..color = const Color(0x14000000),
    );
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = const Color(0x44000000);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      stroke,
    );
    final Path mountain = Path()
      ..moveTo(rect.left + rect.width * 0.18, rect.bottom - rect.height * 0.22)
      ..lineTo(rect.left + rect.width * 0.42, rect.top + rect.height * 0.42)
      ..lineTo(rect.left + rect.width * 0.6, rect.bottom - rect.height * 0.4)
      ..lineTo(rect.left + rect.width * 0.72, rect.top + rect.height * 0.55)
      ..lineTo(rect.right - rect.width * 0.16, rect.bottom - rect.height * 0.22)
      ..close();
    canvas.drawPath(mountain, Paint()..color = const Color(0x33000000));
  }

  void _paintQr(Canvas canvas, Rect rect, QrElement element) {
    canvas.drawRect(
      rect,
      Paint()..color = colorFromHex(element.backgroundHex, fallback: Colors.white),
    );
    final Color color =
        colorFromHex(element.colorHex, fallback: const Color(0xFF1B2539));
    final double unit = rect.width / 21;
    final Paint dark = Paint()..color = color;

    // ثلاث أنماط تحديد في الأركان — تُقرأ بصرياً كرمز QR مصغّر.
    void finder(Offset origin) {
      canvas.drawRect(Rect.fromLTWH(origin.dx, origin.dy, unit * 7, unit * 7), dark);
      canvas.drawRect(
        Rect.fromLTWH(origin.dx + unit, origin.dy + unit, unit * 5, unit * 5),
        Paint()..color = colorFromHex(element.backgroundHex, fallback: Colors.white),
      );
      canvas.drawRect(
        Rect.fromLTWH(origin.dx + unit * 2, origin.dy + unit * 2, unit * 3, unit * 3),
        dark,
      );
    }

    finder(rect.topLeft);
    finder(Offset(rect.right - unit * 7, rect.top));
    finder(Offset(rect.left, rect.bottom - unit * 7));

    for (int i = 8; i < 20; i += 2) {
      for (int j = 8; j < 20; j += 2) {
        if ((i + j) % 4 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(rect.left + i * unit, rect.top + j * unit, unit, unit),
            dark,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ThumbnailPainter oldDelegate) =>
      !identical(oldDelegate.document, document) ||
      oldDelegate.document != document;
}
