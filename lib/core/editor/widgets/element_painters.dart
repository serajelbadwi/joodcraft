import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

import '../../models/decoration.dart';
import '../../utils/hex_color.dart';
import '../canvas_geometry.dart';

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
