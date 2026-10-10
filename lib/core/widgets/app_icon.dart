import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// **أيقونة البرنامج (Program Icon)** — تُرسم متجهياً بالكامل برمجياً بلا أي
/// ملف صورة.
///
/// لماذا رسم برمجي بدل أصل صورة؟ لأن المشروع يعمل بلا أي مورد خارجي وبلا شبكة،
/// فالرمز المحزوم كصورة عرضة للفقد ولكسر النسب وتفقد حدّتها عند التكبير. هذه
/// الأيقونة تُرسم بـ[CustomPainter] فتبقى حادّة عند أي مقاس وبنفس ألوان الهوية
/// (كحلي + ذهبي) في الوضعين الفاتح والداكن.
///
/// الشكل: لوح كحلي بحافة ذهبية يحوي «ورقة شهادة» بشريط عنوان ذهبي وسطور ونقش
/// ختم ذهبي — رمز مباشر لما تنتجه المنصة (شهادات وعقود).
class AppIcon extends StatelessWidget {
  const AppIcon({
    super.key,
    this.size = 40,
    this.onDark = false,
    this.semanticLabel,
  });

  /// طول ضلع الرمز بالبكسل (مربّع دائماً).
  final double size;

  /// إن كان الرمز موضوعاً على خلفية داكنة — يفتح ألوان اللوح قليلاً للتباين.
  final bool onDark;

  /// وصف نصّي لقارئ الشاشة (اختياري).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final Widget mark = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _AppIconPainter(onDark: onDark),
        isComplex: false,
      ),
    );
    final String? label = semanticLabel;
    if (label == null) return mark;
    return Semantics(label: label, image: true, child: mark);
  }
}

/// رسم الرمز: لوح + ورقة + شريط ذهبي + سطور + ختم.
///
/// كل الإحداثيات بنسب من ضلع الرمز (0..1) مضروبةً في المقاس، فتبقى النسب
/// ثابتة عند أي مقاس.
class _AppIconPainter extends CustomPainter {
  const _AppIconPainter({required this.onDark});

  final bool onDark;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    Rect u(double l, double t, double r, double b) =>
        Rect.fromLTRB(l * s, t * s, r * s, b * s);

    final Color plateTop =
        onDark ? const Color(0xFF26334F) : AppColors.navySoft;
    const Color plateBottom = AppColors.navyDeep;
    final Color gold = AppColors.gold;
    final Color paper = onDark ? const Color(0xFFF4F6FA) : Colors.white;
    final Color ink = AppColors.navy;

    // ---------------------------- لوح كحلي متدرّج ----------------------------
    final Rect plate = u(0, 0, 1, 1);
    final RRect plateRRect =
        RRect.fromRectAndRadius(plate, Radius.circular(s * 0.26));
    canvas.drawRRect(
      plateRRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[plateTop, plateBottom],
        ).createShader(plate),
    );

    // حافة ذهبية رفيعة داخلية.
    final RRect border = RRect.fromRectAndRadius(
      u(0.075, 0.075, 0.925, 0.925),
      Radius.circular(s * 0.2),
    );
    canvas.drawRRect(
      border,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.035
        ..color = gold.withValues(alpha: 0.9),
    );

    // ------------------------------ ورقة الشهادة ------------------------------
    final RRect page = RRect.fromRectAndRadius(
      u(0.27, 0.19, 0.73, 0.78),
      Radius.circular(s * 0.06),
    );
    canvas.drawRRect(
      page,
      Paint()
        ..color = paper
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.03),
    );
    canvas.drawRRect(page, Paint()..color = paper);

    // محتوى الورقة مقصوص على حدودها (الشريط والسطور).
    canvas.save();
    canvas.clipRRect(page);
    canvas.drawRect(
      u(0.27, 0.19, 0.73, 0.31),
      Paint()..color = gold,
    );
    final Paint line = Paint()..color = ink.withValues(alpha: 0.55);
    final Paint lineSoft = Paint()..color = ink.withValues(alpha: 0.28);
    canvas.drawRRect(
      RRect.fromRectAndRadius(u(0.35, 0.235, 0.65, 0.265), Radius.circular(s * 0.02)),
      Paint()..color = ink.withValues(alpha: 0.85),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(u(0.33, 0.39, 0.67, 0.415), Radius.circular(s * 0.02)),
      line,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(u(0.33, 0.45, 0.67, 0.475), Radius.circular(s * 0.02)),
      lineSoft,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(u(0.37, 0.51, 0.63, 0.535), Radius.circular(s * 0.02)),
      lineSoft,
    );
    canvas.restore();

    // -------------------------------- الختم الذهبي --------------------------------
    final Offset sealCenter = Offset(0.5 * s, 0.74 * s);
    final double sealR = 0.155 * s;
    canvas.drawCircle(
      sealCenter,
      sealR,
      Paint()
        ..color = gold
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.02),
    );
    canvas.drawCircle(sealCenter, sealR, Paint()..color = gold);
    canvas.drawCircle(
      sealCenter,
      sealR * 0.78,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.02
        ..color = ink.withValues(alpha: 0.5),
    );
    canvas.drawPath(
      _starPath(sealCenter, sealR * 0.62, sealR * 0.27, 5),
      Paint()..color = ink,
    );
  }

  /// مسار نجمة متعدّدة الرؤوس (خارجي/داخلي بالتناوب).
  Path _starPath(Offset center, double outer, double inner, int points) {
    final Path path = Path();
    final double step = math.pi / points;
    for (int i = 0; i < points * 2; i++) {
      final double radius = i.isEven ? outer : inner;
      final double angle = -math.pi / 2 + i * step;
      final Offset p = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_AppIconPainter oldDelegate) =>
      oldDelegate.onDark != onDark;
}
