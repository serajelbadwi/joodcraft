import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// أيقونة ورقة بطراز Photoshop — مرسومة **متجهياً** لا أيقونة جاهزة.
///
/// العناصر الأربعة التي تجعلها مطابقة لأيقونات مقاسات Photoshop:
///
/// * **مستطيل بنسبة المقاس الحقيقية:** البطاقة تمرّر نسبة العرض/الارتفاع
///   الفعلية للمقاس، فتبدو A4 الأفقية عريضة، وقصة الجوال 16:9 نحيلة طويلة،
///   والمربّع مربّعاً — بلا أي صورة مسبقة التصميم لكل اتجاه.
/// * **زاوية مطويّة أعلى اليمين:** صفحة مثقوبة الزاوية مع ورقة الطيّة، فتُقرأ
///   «ورقة» لا «مستطيل».
/// * **علامات قصّ دقيقة:** خيطان قصيران يخرجان من كل زاوية (نمط أهداف الطباعة)
///   خارج حدود الورقة تماماً — ولهذا تحتاج الأيقونة هامشاً حول الصفحة.
/// * **سطح رمادي داكن وحدّ مُضيء:** الحدّ يصير أزرق أساسي عند التحديد وذهبياً
///   عند المرور، مع هالة خارجية خفيفة تجعل الورقة تبدو «مُضاءة».
class PhotoshopPaperIcon extends StatelessWidget {
  const PhotoshopPaperIcon({
    super.key,
    required this.aspectRatio,
    this.selected = false,
    this.hovered = false,
    this.height = 30,
  });

  /// نسبة عرض الصفحة إلى ارتفاعها (‎> 1‎ للأفقية، و‎= 1‎ للمربّعة).
  final double aspectRatio;

  /// المقاس مختار الآن في الشبكة — حدّ أزرق أساسي.
  final bool selected;

  /// المؤشّر فوق البطاقة — حدّ ذهبي.
  final bool hovered;

  /// ارتفاع الصفحة (بلا هامش علامات القصّ).
  final double height;

  /// الهامش حول الصفحة: مساحة علامات القصّ.
  static const double margin = 4;

  /// أضيق نسبة نقبل رسمها (حتى لا تنكمش الأيقونة إلى خيط).
  static const double minRatio = 0.42;

  /// أعرض نسبة نقبل رسمها.
  static const double maxRatio = 2.4;

  @override
  Widget build(BuildContext context) {
    final double raw = aspectRatio.isFinite && aspectRatio > 0
        ? aspectRatio
        : 1.0;
    final double clamped = raw.clamp(minRatio, maxRatio);
    return SizedBox(
      height: height + margin * 2,
      width: height * clamped + margin * 2,
      child: CustomPaint(
        painter: PhotoshopPaperPainter(
          aspectRatio: clamped,
          selected: selected,
          hovered: hovered,
        ),
      ),
    );
  }
}

/// راسم أيقونة الورقة — منطق الرسم كله هنا ليُختبر ويُعاد استخدامه.
class PhotoshopPaperPainter extends CustomPainter {
  const PhotoshopPaperPainter({
    required this.aspectRatio,
    this.selected = false,
    this.hovered = false,
    this.margin = PhotoshopPaperIcon.margin,
  });

  final double aspectRatio;
  final bool selected;
  final bool hovered;
  final double margin;

  @override
  void paint(Canvas canvas, Size size) {
    final double pageWidth = math.max(6, size.width - margin * 2);
    final double pageHeight = math.max(6, size.height - margin * 2);
    final Rect page = Rect.fromLTWH(margin, margin, pageWidth, pageHeight);

    final bool lit = selected || hovered;
    // الأزرق الأساسي للمقاس المختار، والذهبي (هوية المنصة) للمرور فقط.
    final Color accent = selected ? AppColors.dialogAccent : AppColors.gold;

    // 1) سطح الورقة: رمادي داكن، مع غسلة إضاءة عند التحديد/المرور.
    canvas.drawRect(page, Paint()..color = AppColors.dialogHeader);
    if (lit) {
      canvas.drawRect(page, Paint()..color = accent.withValues(alpha: 0.16));
    }

    // 2) هندسة الطيّة: زاوية عليا يمنى مقطوعة بمقدار نسبي من الورقة.
    final double fold = math.min(math.min(pageWidth, pageHeight) * 0.34, 9);
    final double foldX = page.right - fold;
    final double foldY = page.top + fold;

    final Path body = Path()
      ..moveTo(page.left, page.top)
      ..lineTo(foldX, page.top)
      ..lineTo(page.right, foldY)
      ..lineTo(page.right, page.bottom)
      ..lineTo(page.left, page.bottom)
      ..close();

    final Path flap = Path()
      ..moveTo(foldX, page.top)
      ..lineTo(foldX, foldY)
      ..lineTo(page.right, foldY)
      ..close();

    // ورقة الطيّة أفتح قليلاً فتبدو مطويّةً لا مقطوعة.
    canvas.drawPath(
      flap,
      Paint()..color = accent.withValues(alpha: lit ? 0.34 : 0.16),
    );

    // 3) علامات القصّ: خيطان خارج الزوايا الأربع (خارج الورقة تماماً).
    const double gap = 1.2;
    final double tick = math.max(1.5, margin - gap);
    final Paint mark = Paint()
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..color = (lit ? accent : AppColors.dialogInkMuted)
          .withValues(alpha: lit ? 0.9 : 0.55);
    for (final Offset corner in <Offset>[
      page.topLeft,
      page.topRight,
      page.bottomLeft,
      page.bottomRight,
    ]) {
      final double hx = corner.dx == page.left ? -1 : 1;
      final double vy = corner.dy == page.top ? -1 : 1;
      canvas.drawLine(
        Offset(corner.dx + hx * gap, corner.dy),
        Offset(corner.dx + hx * (gap + tick), corner.dy),
        mark,
      );
      canvas.drawLine(
        Offset(corner.dx, corner.dy + vy * gap),
        Offset(corner.dx, corner.dy + vy * (gap + tick)),
        mark,
      );
    }

    // 4) الحدّ: هالة خارجية خفيفة أولاً ثم خطّ حادّ فوقها.
    if (lit) {
      canvas.drawPath(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = accent.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 2.5),
      );
    }
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = lit ? 1.5 : 1
      ..strokeJoin = StrokeJoin.round
      ..color = lit ? accent : AppColors.dialogInkMuted;
    canvas.drawPath(body, stroke);
    canvas.drawPath(flap, stroke);
  }

  @override
  bool shouldRepaint(PhotoshopPaperPainter oldDelegate) =>
      oldDelegate.aspectRatio != aspectRatio ||
      oldDelegate.selected != selected ||
      oldDelegate.hovered != hovered ||
      oldDelegate.margin != margin;
}
