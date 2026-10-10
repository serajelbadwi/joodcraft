import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_l10n.dart';
import '../../models/template_document.dart';
import '../../theme/app_theme.dart';
import '../crop_marks.dart';
import '../imposition_calculator.dart';

/// معاينة **ورقة التجميع** — الواجهة غير القابلة للطباعة من محرّك الحصر.
///
/// ترسم في طبقات منفصلة حتى تكون كل واحدة قابلة للفحص والاختبار وحدها:
/// 1. الورقة والقطع (طبقة [sheetKey]).
/// 2. **علامات القصّ المتجهية** عند أركان كل قطعة وتقاطعاتها الخارجية
///    (طبقة [cropMarksKey]).
/// 3. **خط أمان النزف** المتقطّع وغير القابل للطباعة (طبقة [bleedSafetyKey]).
///
/// الطبقتان الأخيرتان **غير قابلتان للطباعة أصلاً**: الـ PDF لا يعرف عنهما
/// شيئاً — هما إرشاد بصري فقط ليري المستخدم حدّ القطع وحدود الأمان قبل
/// إرسال الملف للمطبعة.
class ImpositionPreview extends StatelessWidget {
  const ImpositionPreview({
    super.key,
    required this.spec,
    required this.document,
    this.itemCount = 1,
    this.showCropMarks = true,
    this.showBleedSafety = true,
    this.showLabels = true,
    this.padding = const EdgeInsets.all(AppTheme.space16),
  });

  /// مفتاح طبقة الورقة والقطع.
  static const String sheetKey = 'imposition-sheet-layer';

  /// مفتاح طبقة علامات القصّ.
  static const String cropMarksKey = 'imposition-crop-marks-layer';

  /// مفتاح طبقة خط أمان النزف.
  static const String bleedSafetyKey = 'imposition-bleed-safety-layer';

  /// مواصفة الحصر (الورقة والقطعة والفواصل والهوامش).
  final ImpositionSpec spec;

  /// المستند الأصلي — يُقتبس لون خلفيته لتعبئة كل قطعة كما ستبدو.
  final TemplateDocument document;

  /// عدد القطع المعروضة فعلاً (يحدّد ترقيم الأركان).
  final int itemCount;

  final bool showCropMarks;
  final bool showBleedSafety;

  /// إظهار رقم القطعة داخلها (مفيد في التجميع الجماعي).
  final bool showLabels;

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final ImpositionResult layout = spec.layout();

    if (layout.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.grid_off_rounded,
                size: 36,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppTheme.space12),
              Text(
                context.l10n?.ptpImpositionNoFit ??
                    'لا تتسع الورقة لهذه القطعة — صغّر الهوامش أو اختر '
                        'ورقة أكبر.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              Text(
                '${spec.sheet.labelAr} — ${_sizeLabel(spec)}',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double ratio =
            layout.sheetWidthMm / math.max(layout.sheetHeightMm, 1e-9);
        final double availableW =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 720;
        final double availableH =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 540;

        double width = availableW;
        double height = width / ratio;
        if (height > availableH) {
          height = availableH;
          width = height * ratio;
        }

        return Padding(
          padding: padding,
          child: Center(
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  CustomPaint(
                    key: const ValueKey<String>(sheetKey),
                    painter: _SheetPainter(
                      layout: layout,
                      document: document,
                      itemCount: itemCount,
                      showLabels: showLabels,
                    ),
                  ),
                  if (showCropMarks)
                    CustomPaint(
                      key: const ValueKey<String>(cropMarksKey),
                      painter: CropMarksPainter(
                        layout: layout,
                        style: spec.markStyle,
                      ),
                    ),
                  if (showBleedSafety)
                    CustomPaint(
                      key: const ValueKey<String>(bleedSafetyKey),
                      painter: BleedSafetyPainter(layout: layout),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// عنوان مقاس القطعة بالملم — يُستخدم في رسائل عدم الملاءمة.
String _sizeLabel(ImpositionSpec spec) =>
    '${_trim(spec.itemWidthMm)}×${_trim(spec.itemHeightMm)} ملم';

String _trim(double value) =>
    value == value.roundToDouble() ? value.round().toString() : '$value';

// ===========================================================================
//  طبقة 1: الورقة والقطع
// ===========================================================================

/// يرسم الورقة وقطعها: خلفية كل قطعة بلون المستند + حدّ قطع رفيع + رقمها.
class _SheetPainter extends CustomPainter {
  _SheetPainter({
    required this.layout,
    required this.document,
    required this.itemCount,
    required this.showLabels,
  });

  final ImpositionResult layout;
  final TemplateDocument document;
  final int itemCount;
  final bool showLabels;

  /// كم بكسل في المليمتر الواحد داخل هذا الرسم.
  double _scale(Size size) => size.width / math.max(layout.sheetWidthMm, 1e-9);

  @override
  void paint(Canvas canvas, Size size) {
    final double s = _scale(size);
    final Rect sheet = Offset.zero & size;

    // الورقة نفسها.
    canvas.drawRect(
      sheet,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      sheet,
      Paint()
        ..color = const Color(0xFF9E9E9E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final Color cellBackground = _hexColor(
      document.backgroundHex,
      fallback: const Color(0xFFF7F7F5),
    );
    final Paint fill = Paint()..color = cellBackground;
    final Paint trim = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final int shown = math.min(itemCount, layout.count);

    for (int i = 0; i < layout.count; i++) {
      final ImpositionPlacement p = layout.placements[i];
      final Rect rect = Rect.fromLTWH(
        p.leftMm * s,
        p.topMm * s,
        p.widthMm * s,
        p.heightMm * s,
      );
      if (i < shown) {
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, trim);
        if (showLabels) _drawLabel(canvas, rect, '${i + 1}');
      } else {
        // خلية فارغة (التوزيع الجماعي لم يملأها): إطار متقطّع خفيف فقط.
        canvas.drawRect(rect, trim..strokeWidth = 1);
      }
    }
  }

  void _drawLabel(Canvas canvas, Rect rect, String text) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: const Color(0xFF616161),
          fontSize: math.max(9.0, rect.shortestSide * 0.18),
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width);
    tp.paint(
      canvas,
      Offset(
        rect.center.dx - tp.width / 2,
        rect.center.dy - tp.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_SheetPainter oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.document != document ||
      oldDelegate.itemCount != itemCount ||
      oldDelegate.showLabels != showLabels;
}

// ===========================================================================
//  طبقة 2: علامات القصّ المتجهية
// ===========================================================================

/// علامات القصّ (Crosshairs / Cut Lines) — خطوط متجهية عند أركان كل قطعة
/// وتقاطعاتها الخارجية.
class CropMarksPainter extends CustomPainter {
  CropMarksPainter({required this.layout, required this.style});

  final ImpositionResult layout;

  /// مظهر العلامات (ابتعاد، طول، سُمك، لون).
  final CropMarkStyle style;

  /// العلامات المحسوبة — تُفحص في الاختبارات دون الحاجة لرسمها.
  List<CropMarkLine> get marks => cropMarksForSheet(layout, style: style);

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / math.max(layout.sheetWidthMm, 1e-9);
    final Paint paint = Paint()
      ..color = style.color
      ..strokeWidth = math.max(style.thicknessMm * s, 1)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    for (final CropMarkLine line in marks) {
      canvas.drawLine(
        Offset(line.x1 * s, line.y1 * s),
        Offset(line.x2 * s, line.y2 * s),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CropMarksPainter oldDelegate) =>
      oldDelegate.layout != layout || oldDelegate.style != style;
}

// ===========================================================================
//  طبقة 3: خط أمان النزف (غير قابل للطباعة)
// ===========================================================================

/// مستطيل الأمان المتقطّع — يُشير إلى الحدّ الذي لا يجوز تجاوزه.
///
/// **غير قابل للطباعة**: لا يدخل ملف الـ PDF مطلقاً؛ وجوده هنا وفي المعاينة
/// فقط هو ما يميّزه عن علامات القصّ.
class BleedSafetyPainter extends CustomPainter {
  BleedSafetyPainter({required this.layout, this.color = const Color(0xFFEF6C00)});

  final ImpositionResult layout;
  final Color color;

  /// المستطيل المحسوب (بالملم) — يُفحص في الاختبارات.
  Rect get rect => bleedSafetyRect(layout);

  @override
  void paint(Canvas canvas, Size size) {
    if (layout.isEmpty) return;
    final double s = size.width / math.max(layout.sheetWidthMm, 1e-9);
    final Rect safe = Rect.fromLTRB(
      rect.left * s,
      rect.top * s,
      rect.right * s,
      rect.bottom * s,
    );

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    const double dash = 7;
    const double gap = 5;

    // أربعة حواف: كل واحدة سلسلة خطوط قصيرة (بلا مسار متقطّع جاهز في Flutter).
    _dashHorizontal(canvas, safe.top, safe.left, safe.right, paint, dash, gap);
    _dashHorizontal(canvas, safe.bottom, safe.left, safe.right, paint, dash, gap);
    _dashVertical(canvas, safe.left, safe.top, safe.bottom, paint, dash, gap);
    _dashVertical(canvas, safe.right, safe.top, safe.bottom, paint, dash, gap);
  }

  static void _dashHorizontal(
    Canvas canvas,
    double y,
    double from,
    double to,
    Paint paint,
    double dash,
    double gap,
  ) {
    double x = from;
    while (x < to) {
      final double end = math.min(x + dash, to);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x = end + gap;
    }
  }

  static void _dashVertical(
    Canvas canvas,
    double x,
    double from,
    double to,
    Paint paint,
    double dash,
    double gap,
  ) {
    double y = from;
    while (y < to) {
      final double end = math.min(y + dash, to);
      canvas.drawLine(Offset(x, y), Offset(x, end), paint);
      y = end + gap;
    }
  }

  @override
  bool shouldRepaint(BleedSafetyPainter oldDelegate) =>
      oldDelegate.layout != layout || oldDelegate.color != color;
}

/// قراءة لون `#RRGGBB`/`RRGGBB` مع بديل آمن عند قيمة غير صالحة.
Color _hexColor(String? hex, {required Color fallback}) {
  String value = (hex ?? '').trim();
  if (value.startsWith('#')) value = value.substring(1);
  if (value.length == 8) value = value.substring(2);
  if (value.length != 6) return fallback;
  final int? parsed = int.tryParse(value, radix: 16);
  if (parsed == null) return fallback;
  return Color(0xFF000000 | parsed);
}
