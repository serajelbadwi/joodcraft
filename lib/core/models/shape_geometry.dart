import 'dart:math' as math;

import 'template_element.dart';

/// أوامر رسم مسار واحد — وصف هندسي **نقيّ** (لا يعرف فلاتر ولا `pdf`).
///
/// المحرر ومحرّك الطباعة يبنيان مساراتهما من هذه الأوامر نفسها، فلا يختلف شكل
/// الشكل بين ما يراه المستخدم على اللوحة وما يخرج في الورقة.
sealed class ShapeCommand {
  const ShapeCommand();
}

/// بداية مسار فرعي جديد عند الإحداثي (x, y).
final class ShapeMove extends ShapeCommand {
  const ShapeMove(this.x, this.y);
  final double x;
  final double y;
}

/// خط مستقيم إلى الإحداثي (x, y).
final class ShapeLine extends ShapeCommand {
  const ShapeLine(this.x, this.y);
  final double x;
  final double y;
}

/// منحنى بيزييه تكعيبي بنقطتي تحكّم (x1,y1) و(x2,y2) ونهاية (x3,y3).
final class ShapeCubic extends ShapeCommand {
  const ShapeCubic(this.x1, this.y1, this.x2, this.y2, this.x3, this.y3);
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double x3;
  final double y3;
}

/// إغلاق المسار الفرعي الحالي.
final class ShapeClose extends ShapeCommand {
  const ShapeClose();
}

/// معامل تقريب ربع الدائرة بمنحنى تكعيبي (ثابت بيزيه القياسي).
const double _kappa = 0.5522847498307936;

/// بناء أوامر مسار شكل واحد داخل صندوق عرضه [width] وارتفاعه [height].
///
/// * [radius] استدارة موحّدة (تُستخدم إن لم تُمرَّر [cornerRadii]).
/// * [cornerRadii] أنصاف أقطار الزوايا الأربع (أعلى-يسار، أعلى-يمين،
///   أسفل-يمين، أسفل-يسار) — للمستطيل المنحني.
/// * [points] عدد رؤوس النجمة/المضلّع.
/// * [innerRadius] نسبة نصف القطر الداخلي إلى الخارجي (النجمة).
/// * [rotationDeg] دوران موضعي حول مركز الصندوق.
List<ShapeCommand> shapeOutline({
  required ShapeKind kind,
  required double width,
  required double height,
  double radius = 0,
  List<double>? cornerRadii,
  int points = 5,
  double innerRadius = 0.45,
  double rotationDeg = 0,
}) {
  final double w = width > 0 ? width : 0;
  final double h = height > 0 ? height : 0;
  final List<ShapeCommand> commands = switch (kind) {
    ShapeKind.line => <ShapeCommand>[
        ShapeMove(0, h / 2),
        ShapeLine(w, h / 2),
      ],
    ShapeKind.ellipse => _ellipse(w, h),
    ShapeKind.rect => (cornerRadii != null && cornerRadii.any((double r) => r > 0))
        ? _roundedRect(w, h, _normalizeCorners(cornerRadii, w, h))
        : radius > 0
            ? _roundedRect(
                w,
                h,
                _normalizeCorners(<double>[radius, radius, radius, radius], w, h),
              )
            : _rect(w, h),
    ShapeKind.star => _star(w, h, points: points, innerRatio: innerRadius),
    ShapeKind.polygon => _polygon(w, h, sides: points),
  };
  if (rotationDeg == 0) return commands;
  return _rotate(commands, w / 2, h / 2, rotationDeg);
}

/// تقييد أنصاف الأقطار بحيث لا تتجاوز نصف أصغر ضلع (كما يفعل `BorderRadius`).
List<double> _normalizeCorners(List<double> radii, double w, double h) {
  final double limit = math.min(w, h) / 2;
  return <double>[
    for (int i = 0; i < 4; i++)
      (radii.length > i ? radii[i] : 0).clamp(0, limit).toDouble(),
  ];
}

List<ShapeCommand> _rect(double w, double h) => <ShapeCommand>[
      const ShapeMove(0, 0),
      ShapeLine(w, 0),
      ShapeLine(w, h),
      ShapeLine(0, h),
      const ShapeClose(),
    ];

List<ShapeCommand> _roundedRect(double w, double h, List<double> r) {
  final double tl = r[0];
  final double tr = r[1];
  final double br = r[2];
  final double bl = r[3];
  final List<ShapeCommand> commands = <ShapeCommand>[
    ShapeMove(tl, 0),
    ShapeLine(w - tr, 0),
    if (tr > 0) ...<ShapeCommand>[
      ShapeCubic(w - tr + tr * _kappa, 0, w, tr - tr * _kappa, w, tr),
    ],
    ShapeLine(w, h - br),
    if (br > 0) ...<ShapeCommand>[
      ShapeCubic(w, h - br + br * _kappa, w - br + br * _kappa, h, w - br, h),
    ],
    ShapeLine(bl, h),
    if (bl > 0) ...<ShapeCommand>[
      ShapeCubic(bl - bl * _kappa, h, 0, h - bl + bl * _kappa, 0, h - bl),
    ],
    ShapeLine(0, tl),
    if (tl > 0) ...<ShapeCommand>[
      ShapeCubic(0, tl - tl * _kappa, tl - tl * _kappa, 0, tl, 0),
    ],
    const ShapeClose(),
  ];
  return commands;
}

List<ShapeCommand> _ellipse(double w, double h) {
  final double rx = w / 2;
  final double ry = h / 2;
  final double cx = rx;
  final double cy = ry;
  final double kx = rx * _kappa;
  final double ky = ry * _kappa;
  return <ShapeCommand>[
    ShapeMove(cx, cy - ry),
    ShapeCubic(cx + kx, cy - ry, cx + rx, cy - ky, cx + rx, cy),
    ShapeCubic(cx + rx, cy + ky, cx + kx, cy + ry, cx, cy + ry),
    ShapeCubic(cx - kx, cy + ry, cx - rx, cy + ky, cx - rx, cy),
    ShapeCubic(cx - rx, cy - ky, cx - kx, cy - ry, cx, cy - ry),
    const ShapeClose(),
  ];
}

/// نجمة بعدد [points] رأساً خارجياً ونسبة [innerRatio] للداخل.
List<ShapeCommand> _star(
  double w,
  double h, {
  required int points,
  required double innerRatio,
}) {
  final int n = points.clamp(3, 60);
  final double cx = w / 2;
  final double cy = h / 2;
  final double rx = w / 2;
  final double ry = h / 2;
  final double inner = innerRatio.clamp(0.05, 1.0);
  final List<ShapeCommand> commands = <ShapeCommand>[];
  final int total = n * 2;
  for (int i = 0; i < total; i++) {
    final bool outer = i.isEven;
    final double factor = outer ? 1 : inner;
    final double angle = (math.pi / n) * i - math.pi / 2;
    final double x = cx + rx * factor * math.cos(angle);
    final double y = cy + ry * factor * math.sin(angle);
    if (i == 0) {
      commands.add(ShapeMove(x, y));
    } else {
      commands.add(ShapeLine(x, y));
    }
  }
  commands.add(const ShapeClose());
  return commands;
}

/// مضلّع منتظم بعدد [sides] ضلعاً.
List<ShapeCommand> _polygon(double w, double h, {required int sides}) {
  final int n = sides.clamp(3, 60);
  final double cx = w / 2;
  final double cy = h / 2;
  final double rx = w / 2;
  final double ry = h / 2;
  final List<ShapeCommand> commands = <ShapeCommand>[];
  for (int i = 0; i < n; i++) {
    final double angle = (2 * math.pi / n) * i - math.pi / 2;
    final double x = cx + rx * math.cos(angle);
    final double y = cy + ry * math.sin(angle);
    if (i == 0) {
      commands.add(ShapeMove(x, y));
    } else {
      commands.add(ShapeLine(x, y));
    }
  }
  commands.add(const ShapeClose());
  return commands;
}

/// محور التدرّج داخل صندوق عرضه [width] وارتفاعه [height] بزاوية [angleDeg].
///
/// الزاوية 0 تعني من الأعلى إلى الأسفل، وتزداد مع اتجاه عقارب الساعة.
/// تُرجع نقطة البداية والنهاية بإحداثيات محلية (أصلها الركن الأيسر العلوي)،
/// ويستخدمها المحرر ومحرّك الطباعة معاً فلا يختلف اتجاه التدرّج بينهما.
({double sx, double sy, double ex, double ey}) gradientAxis(
  double width,
  double height,
  double angleDeg,
) {
  final double cx = width / 2;
  final double cy = height / 2;
  final double rad = angleDeg * math.pi / 180;
  final double dx = math.sin(rad);
  final double dy = math.cos(rad);
  // نصف طول الخط يغطّي أقطار الصندوق في أي اتجاه.
  final double half = math.sqrt(width * width + height * height) / 2;
  return (
    sx: cx - dx * half,
    sy: cy - dy * half,
    ex: cx + dx * half,
    ey: cy + dy * half,
  );
}

/// تدوير جميع إحداثيات الأوامر حول (cx, cy) بزاوية بالدرجات.
List<ShapeCommand> _rotate(
  List<ShapeCommand> commands,
  double cx,
  double cy,
  double deg,
) {
  final double rad = deg * math.pi / 180;
  final double cos = math.cos(rad);
  final double sin = math.sin(rad);
  double px(double x, double y) => cx + (x - cx) * cos - (y - cy) * sin;
  double py(double x, double y) => cy + (x - cx) * sin + (y - cy) * cos;
  return <ShapeCommand>[
    for (final ShapeCommand command in commands)
      switch (command) {
        ShapeMove(:final double x, :final double y) =>
          ShapeMove(px(x, y), py(x, y)),
        ShapeLine(:final double x, :final double y) =>
          ShapeLine(px(x, y), py(x, y)),
        ShapeCubic(
          :final double x1,
          :final double y1,
          :final double x2,
          :final double y2,
          :final double x3,
          :final double y3,
        ) =>
          ShapeCubic(
            px(x1, y1),
            py(x1, y1),
            px(x2, y2),
            py(x2, y2),
            px(x3, y3),
            py(x3, y3),
          ),
        ShapeClose() => const ShapeClose(),
      },
  ];
}
