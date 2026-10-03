import 'dart:math' as math;
import 'dart:ui';

import '../models/template_element.dart';

/// هندسة عرض ورقة التصميم على الشاشة.
///
/// **قاعدة الاتساق مع محرّك الطباعة**: الورقة تُعرض دائماً بنسبة العرض إلى
/// الارتفاع نفسها المستخدمة في الـ PDF، فما يراه المستخدم في المحرر هو ما
/// يُطبع حرفياً (نفس الترتيب، نفس النِسب). ما يتغيّر فقط هو معامل التقريب
/// بين "وحدة تصميم" و"بكسل شاشة".
class CanvasGeometry {
  const CanvasGeometry({required this.scale, required this.origin});

  /// عدد بكسلات الشاشة لكل وحدة تصميم.
  final double scale;

  /// موضع الزاوية العليا اليسرى للورقة داخل مساحة العرض.
  final Offset origin;

  /// هندسة تُلائم الورقة كاملة داخل المساحة المتاحة (بلا تجاوز).
  factory CanvasGeometry.fit({
    required Size viewport,
    required Size design,
    double padding = 28,
  }) {
    if (design.width <= 0 || design.height <= 0) {
      return const CanvasGeometry(scale: 1, origin: Offset.zero);
    }
    final double availableWidth = math.max(viewport.width - padding * 2, 40);
    final double availableHeight = math.max(viewport.height - padding * 2, 40);
    final double raw = math.min(
      availableWidth / design.width,
      availableHeight / design.height,
    );
    final double safeScale = raw.isFinite && raw > 0 ? raw : 1;
    return CanvasGeometry(
      scale: safeScale,
      origin: Offset(
        (viewport.width - design.width * safeScale) / 2,
        (viewport.height - design.height * safeScale) / 2,
      ),
    );
  }

  /// نسخة بمعامل تقريب مضروب (أداة التكبير/التصغير).
  CanvasGeometry zoomed(double factor) => CanvasGeometry(
        scale: scale * factor,
        origin: origin,
      );

  /// حجم الورقة المعروض بالبكسل.
  Size pageSize(Size design) =>
      Size(design.width * scale, design.height * scale);

  /// تحويل نقطة من إحداثيات التصميم إلى إحداثيات الشاشة.
  Offset toScreen(Offset design) => origin + design * scale;

  /// تحويل نقطة من إحداثيات الشاشة إلى إحداثيات التصميم.
  Offset toDesign(Offset screen) => (screen - origin) / scale;

  /// تحويل مستطيل من إحداثيات التصميم إلى إحداثيات الشاشة.
  Rect rectToScreen(Rect design) => Rect.fromLTWH(
        origin.dx + design.left * scale,
        origin.dy + design.top * scale,
        design.width * scale,
        design.height * scale,
      );

  @override
  bool operator ==(Object other) =>
      other is CanvasGeometry && other.scale == scale && other.origin == origin;

  @override
  int get hashCode => Object.hash(scale, origin);
}

/// مغناطيس المحاذاة: يجذب حدود العنصر إلى حدود الورقة ومركزها.
///
/// هذا ما يمنح المحرر "إحساساً دقيقاً" بلا الحاجة إلى تحريك بالبكسل الواحد.
abstract final class ElementSnapper {
  const ElementSnapper._();

  /// المسافة (بوحدات التصميم) التي يبدأ عندها الالتصاق.
  static const double tolerance = 6;

  /// يُعيد صندوقاً مُعدَّلاً بعد تطبيق الالتصاق الأفقي/الرأسي إن كان قريباً.
  static ElementBox snap({
    required ElementBox box,
    required Size design,
    double toleranceUnits = tolerance,
  }) {
    final double width = box.width > 0 ? box.width : 0;
    final double height = box.height > 0 ? box.height : 0;

    double x = box.x;
    double y = box.y;

    // المرشّحات الأفقية: حدّ اليسار، مركز الورقة، حدّ اليمين.
    final List<double> xTargets = <double>[
      0,
      (design.width - width) / 2,
      design.width - width,
    ];
    for (final double target in xTargets) {
      if ((x - target).abs() <= toleranceUnits) {
        x = target;
        break;
      }
    }

    // المرشّحات الرأسية: الأعلى، المنتصف، الأسفل.
    final List<double> yTargets = <double>[
      0,
      (design.height - height) / 2,
      design.height - height,
    ];
    for (final double target in yTargets) {
      if ((y - target).abs() <= toleranceUnits) {
        y = target;
        break;
      }
    }

    return box.copyWith(x: x, y: y);
  }
}

/// خط إرشاد ذكي يربط حافتين/مركزين متوازيين أثناء السحب.
///
/// [vertical] = true يعني خطاً رأسياً عند موضع X = [position] يمتد رأسياً بين
/// [start] و[end] (بوحدات التصميم). وfalse يعني خطاً أفقياً عند Y = [position]
/// يمتد أفقياً بين [start] و[end].
class SmartGuide {
  const SmartGuide({
    required this.vertical,
    required this.position,
    required this.start,
    required this.end,
  });

  final bool vertical;
  final double position;
  final double start;
  final double end;
}

/// ناتج الالتصاق الذكي: الصندوق المُعدَّل + الخطوط الإرشادية النشطة.
class SnapOutcome {
  const SnapOutcome({required this.box, required this.guides});

  final ElementBox box;
  final List<SmartGuide> guides;

  bool get hasGuides => guides.isNotEmpty;
}

/// محرّك "خطوط الإرشاد الذكية": يمحاذي العنصر المسحوب مع مركز اللوحة وحدود
/// باقي العناصر، ويعيد خطوط الإرشاد المرسومة.
///
/// يجمع بين المحاذاة الرأسية (X: يسار/مركز/يمين) والمحاذاة الأفقية
/// (Y: أعلى/منتصف/أسفل)، ويختار أقرب هدف داخل [tolerance] لكل محور على حدة —
/// فيمكن أن يلتصق المحوران معاً (زاوية) بلا تعارض.
abstract final class SmartGuides {
  const SmartGuides._();

  /// مسافة الالتصاق الافتراضية بوحدات التصميم (5–8 حسب الطلب: نأخذ 6).
  static const double tolerance = 6;

  static SnapOutcome snap({
    required ElementBox box,
    required Size design,
    Iterable<ElementBox> others = const <ElementBox>[],
    double tolerance = tolerance,
  }) {
    final Rect moving = _rect(box, design);

    final List<_SnapTarget> xTargets = <_SnapTarget>[];
    final List<_SnapTarget> yTargets = <_SnapTarget>[];
    for (final ElementBox other in others) {
      final Rect rect = _rect(other, design);
      xTargets.add(_SnapTarget(
        edges: <double>[rect.left, rect.center.dx, rect.right],
        crossStart: rect.top,
        crossEnd: rect.bottom,
      ));
      yTargets.add(_SnapTarget(
        edges: <double>[rect.top, rect.center.dy, rect.bottom],
        crossStart: rect.left,
        crossEnd: rect.right,
      ));
    }

    final _AxisSnap x = _solveAxis(
      movingEdges: <double>[moving.left, moving.center.dx, moving.right],
      movingCrossStart: moving.top,
      movingCrossEnd: moving.bottom,
      canvasExtent: design.width,
      canvasCrossExtent: design.height,
      targets: xTargets,
      tolerance: tolerance,
    );
    final _AxisSnap y = _solveAxis(
      movingEdges: <double>[moving.top, moving.center.dy, moving.bottom],
      movingCrossStart: moving.left,
      movingCrossEnd: moving.right,
      canvasExtent: design.height,
      canvasCrossExtent: design.width,
      targets: yTargets,
      tolerance: tolerance,
    );

    final List<SmartGuide> guides = <SmartGuide>[
      if (x.found)
        SmartGuide(
          vertical: true,
          position: x.at!,
          start: x.spanStart,
          end: x.spanEnd,
        ),
      if (y.found)
        SmartGuide(
          vertical: false,
          position: y.at!,
          start: y.spanStart,
          end: y.spanEnd,
        ),
    ];

    return SnapOutcome(
      box: box.copyWith(
        x: box.x + (x.found ? x.delta : 0),
        y: box.y + (y.found ? y.delta : 0),
      ),
      guides: guides,
    );
  }

  /// حلّ محور واحد: أقرب هدف من حواف/مركز اللوحة والعناصر الأخرى.
  static _AxisSnap _solveAxis({
    required List<double> movingEdges,
    required double movingCrossStart,
    required double movingCrossEnd,
    required double canvasExtent,
    required double canvasCrossExtent,
    required List<_SnapTarget> targets,
    required double tolerance,
  }) {
    double bestDistance = tolerance;
    double bestDelta = 0;
    double? at;
    double spanStart = 0;
    double spanEnd = 0;
    bool found = false;

    void consider(
      double moveEdge,
      double target,
      double targetCrossStart,
      double targetCrossEnd,
    ) {
      final double distance = (target - moveEdge).abs();
      // أول تطابق داخل المدى يفوز عند التساوي (أولوية للوحة ثم للعناصر).
      if (found) {
        if (distance >= bestDistance) return;
      } else if (distance > tolerance) {
        return;
      }
      bestDistance = distance;
      bestDelta = target - moveEdge;
      at = target;
      spanStart = math.min(movingCrossStart, targetCrossStart);
      spanEnd = math.max(movingCrossEnd, targetCrossEnd);
      found = true;
    }

    // حواف ومنتصف اللوحة (الأولوية لها عند التساوي).
    for (final double target in <double>[0, canvasExtent / 2, canvasExtent]) {
      for (final double edge in movingEdges) {
        consider(edge, target, 0, canvasCrossExtent);
      }
    }
    // حدود ومراكز العناصر الأخرى.
    for (final _SnapTarget target in targets) {
      for (final double point in target.edges) {
        for (final double edge in movingEdges) {
          consider(edge, point, target.crossStart, target.crossEnd);
        }
      }
    }

    return _AxisSnap(
      found: found,
      delta: bestDelta,
      at: at,
      spanStart: spanStart,
      spanEnd: spanEnd,
    );
  }

  static Rect _rect(ElementBox box, Size design) {
    final double width = box.width > 0
        ? box.width
        : math.max(0, design.width - box.x);
    final double height = box.height > 0
        ? box.height
        : math.max(0, design.height - box.y);
    return Rect.fromLTWH(box.x, box.y, width, height);
  }
}

class _AxisSnap {
  const _AxisSnap({
    required this.found,
    required this.delta,
    required this.at,
    required this.spanStart,
    required this.spanEnd,
  });

  final bool found;
  final double delta;
  final double? at;
  final double spanStart;
  final double spanEnd;
}

class _SnapTarget {
  const _SnapTarget({
    required this.edges,
    required this.crossStart,
    required this.crossEnd,
  });

  final List<double> edges;
  final double crossStart;
  final double crossEnd;
}
