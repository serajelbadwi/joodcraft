import 'dart:math' as math;

/// أنواع الزخارف المتجهية الإجرائية (بلا أي صورة — تُولَّد هندسياً).
///
/// كل نوع يُنتَج كنمط **حتمي** من [DecorSpec]: نفس المدخلات ⇒ نفس المسارات،
/// فيتطابق المحرر والـ PDF تماماً ويصبح الاختبار ممكناً.
enum DecorKind {
  modernWave('موجات حديثة'),
  paperCut('قصّ ورقي متعدد الطبقات'),
  classicCorner('إطار كلاسيكي مزخرف'),
  guilloche('نمط غيوش الأمني'),
  ribbonBanner('شريط/وسام');

  const DecorKind(this.labelAr);

  final String labelAr;

  static DecorKind fromJson(Object? value) {
    final String needle = '${value ?? ''}'.trim().toLowerCase();
    return values.firstWhere(
      (DecorKind kind) => kind.name.toLowerCase() == needle,
      orElse: () => DecorKind.modernWave,
    );
  }
}

/// وصف زخرفة واحدة — وحدة تُحفظ في القالب وتُعيد إنتاج الشكل نفسه.
class DecorSpec {
  const DecorSpec({
    this.kind = DecorKind.modernWave,
    this.primaryHex = '#0D3B66',
    this.secondaryHex = '#C7A26B',
    this.accentHex = '#F4D58D',
    this.layers = 3,
    this.thickness = 2,
    this.seed = 7,
  });

  final DecorKind kind;

  /// اللون الأساسي (يبدأ منه التدرّج).
  final String primaryHex;

  /// اللون الثاني (ينتهي عنده التدرّج).
  final String secondaryHex;

  /// لون اللمسات (الأوسمة/النقاط الزخرفية).
  final String accentHex;

  /// عدد الطبقات/الخطوط — يتيح إحساس التدرّج الطبقي.
  final int layers;

  /// سماكة الخطوط (بنسب عرض الزخرفة).
  final double thickness;

  /// بذرة التنويع الحتمي (تغييرها يغيّر الأطوار لا الشكل العام).
  final int seed;

  DecorSpec copyWith({
    DecorKind? kind,
    String? primaryHex,
    String? secondaryHex,
    String? accentHex,
    int? layers,
    double? thickness,
    int? seed,
  }) =>
      DecorSpec(
        kind: kind ?? this.kind,
        primaryHex: primaryHex ?? this.primaryHex,
        secondaryHex: secondaryHex ?? this.secondaryHex,
        accentHex: accentHex ?? this.accentHex,
        layers: layers ?? this.layers,
        thickness: thickness ?? this.thickness,
        seed: seed ?? this.seed,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'kind': kind.name,
        'primary': primaryHex,
        'secondary': secondaryHex,
        'accent': accentHex,
        if (layers != 3) 'layers': layers,
        if (thickness != 2) 'thickness': thickness,
        if (seed != 7) 'seed': seed,
      };

  factory DecorSpec.fromJson(Map<String, dynamic> json) => DecorSpec(
        kind: DecorKind.fromJson(json['kind']),
        primaryHex: '${json['primary'] ?? '#0D3B66'}',
        secondaryHex: '${json['secondary'] ?? '#C7A26B'}',
        accentHex: '${json['accent'] ?? '#F4D58D'}',
        layers: (json['layers'] as num?)?.toInt() ?? 3,
        thickness: (json['thickness'] as num?)?.toDouble() ?? 2,
        seed: (json['seed'] as num?)?.toInt() ?? 7,
      );

  @override
  bool operator ==(Object other) =>
      other is DecorSpec &&
      other.kind == kind &&
      other.primaryHex == primaryHex &&
      other.secondaryHex == secondaryHex &&
      other.accentHex == accentHex &&
      other.layers == layers &&
      other.thickness == thickness &&
      other.seed == seed;

  @override
  int get hashCode => Object.hash(
        kind,
        primaryHex,
        secondaryHex,
        accentHex,
        layers,
        thickness,
        seed,
      );
}

// ===========================================================================
//  نموذج الهندسة (مستقلّ عن محرّكي الرسم — يُترجَم إلى PDF وFlutter معاً)
// ===========================================================================

/// قطعة رسم واحدة داخل مسار.
sealed class DecorSegment {
  const DecorSegment();
}

class DecorMove extends DecorSegment {
  const DecorMove(this.x, this.y);
  final double x;
  final double y;
}

class DecorLine extends DecorSegment {
  const DecorLine(this.x, this.y);
  final double x;
  final double y;
}

class DecorCubic extends DecorSegment {
  const DecorCubic(this.x1, this.y1, this.x2, this.y2, this.x, this.y);
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double x;
  final double y;
}

/// مسار هندسي بلون واحد — يُملأ أو يُرسم كخط.
class DecorPath {
  const DecorPath({
    required this.segments,
    required this.colorHex,
    this.closed = true,
    this.stroke = false,
    this.strokeWidth = 0,
  });

  final List<DecorSegment> segments;
  final String colorHex;
  final bool closed;
  final bool stroke;
  final double strokeWidth;
}

// ===========================================================================
//  المولّد الإجرائي
// ===========================================================================

/// مولّد الزخارف المتجهية الإجرائية.
///
/// الإحداثيات بنظام **أعلى-يسار** (كما المحرر)، ومحرّك الـ PDF يقلب الرأسي عند
/// الرسم (أصله أسفل-يسار). يضمن ذلك تطابق المعاينة والطباعة.
abstract final class VectorDecor {
  const VectorDecor._();

  /// سقف الطبقات لتجنّب ملفات PDF منتفخة.
  static const int maxLayers = 6;

  /// يبني مسارات الزخرفة لمقاس معطّى (وحدات التصميم).
  static List<DecorPath> build(DecorSpec spec, double width, double height) {
    if (width <= 0 || height <= 0) return const <DecorPath>[];
    return switch (spec.kind) {
      DecorKind.modernWave => _modernWave(spec, width, height),
      DecorKind.paperCut => _paperCut(spec, width, height),
      DecorKind.classicCorner => _classicCorner(spec, width, height),
      DecorKind.guilloche => _guilloche(spec, width, height),
      DecorKind.ribbonBanner => _ribbonBanner(spec, width, height),
    };
  }

  // ------------------------------ موجات حديثة ------------------------------
  static List<DecorPath> _modernWave(DecorSpec spec, double w, double h) {
    final int layers = spec.layers.clamp(1, maxLayers);
    final double band = h * 0.24;
    final double amp = band * 0.32;
    final List<DecorPath> paths = <DecorPath>[];
    for (int i = 0; i < layers; i++) {
      final double t = layers == 1 ? 0 : i / (layers - 1);
      final double baseY = h - band * (0.30 + 0.70 * t);
      final double phase = (spec.seed % 6) * math.pi / 6 + i * math.pi / 3;
      final int steps = 6;
      final List<DecorSegment> segs = <DecorSegment>[DecorMove(0, baseY)];
      double prevX = 0;
      double prevY = baseY;
      for (int s = 1; s <= steps; s++) {
        final double x = w * s / steps;
        final double y = baseY + math.sin(phase + s * math.pi / steps) * amp;
        segs.add(DecorCubic(
          prevX + (x - prevX) / 3, prevY,
          prevX + 2 * (x - prevX) / 3, y,
          x, y,
        ));
        prevX = x;
        prevY = y;
      }
      segs
        ..add(DecorLine(w, h))
        ..add(DecorLine(0, h));
      paths.add(DecorPath(
        segments: segs,
        colorHex: lerpHex(spec.primaryHex, spec.secondaryHex, t),
      ));
    }
    return paths;
  }

  // --------------------------- قصّ ورقي متعدد ---------------------------
  static List<DecorPath> _paperCut(DecorSpec spec, double w, double h) {
    final int layers = spec.layers.clamp(1, maxLayers);
    final List<DecorPath> paths = <DecorPath>[];
    for (int i = 0; i < layers; i++) {
      final double t = layers == 1 ? 0 : i / (layers - 1);
      final double y0 = h * (0.35 + 0.5 * t);
      final double peak = h * (0.10 + 0.04 * (i % 3));
      final List<DecorSegment> segs = <DecorSegment>[
        DecorMove(0, y0),
        DecorLine(w * 0.20, y0 - peak),
        DecorLine(w * 0.40, y0 - peak * 0.4),
        DecorLine(w * 0.60, y0 - peak * 0.9),
        DecorLine(w * 0.80, y0 - peak * 0.35),
        DecorLine(w, y0 - peak * 0.7),
        DecorLine(w, h),
        DecorLine(0, h),
      ];
      paths.add(DecorPath(
        segments: segs,
        colorHex: lerpHex(spec.secondaryHex, spec.primaryHex, t),
      ));
    }
    return paths;
  }

  // --------------------------- إطار كلاسيكي مزخرف ---------------------------
  static List<DecorPath> _classicCorner(DecorSpec spec, double w, double h) {
    final double m = math.min(w, h);
    final double inset = m * 0.06;
    final double arc = m * 0.14;
    final double sw = (spec.thickness <= 0 ? 2 : spec.thickness) * m / 500;
    final String main = lerpHex(spec.secondaryHex, spec.accentHex, 0.25);
    final List<DecorPath> paths = <DecorPath>[];
    for (final bool right in <bool>[false, true]) {
      for (final bool bottom in <bool>[false, true]) {
        final double ox = right ? w : 0;
        final double oy = bottom ? h : 0;
        final double sx = right ? -1 : 1;
        final double sy = bottom ? -1 : 1;
        // قوس الرفرفة (ربع دائرة) عبر منحنيين تكعيبيين.
        final List<DecorSegment> arcSegs = <DecorSegment>[
          DecorMove(ox + sx * inset, oy + sy * (inset + arc)),
          DecorCubic(
            ox + sx * inset, oy + sy * (inset + arc * 0.45),
            ox + sx * (inset + arc * 0.45), oy + sy * inset,
            ox + sx * (inset + arc), oy + sy * inset,
          ),
        ];
        paths.add(DecorPath(
          segments: arcSegs,
          colorHex: main,
          closed: false,
          stroke: true,
          strokeWidth: sw,
        ));
        // معيّن زخرفي صغير عند الزاوية.
        final double c = inset * 1.35;
        final double d = m * 0.035;
        paths.add(DecorPath(
          segments: <DecorSegment>[
            DecorMove(ox + sx * c, oy + sy * (c - d)),
            DecorLine(ox + sx * (c + d), oy + sy * c),
            DecorLine(ox + sx * c, oy + sy * (c + d)),
            DecorLine(ox + sx * (c - d), oy + sy * c),
          ],
          colorHex: spec.accentHex,
          closed: true,
        ));
      }
    }
    return paths;
  }

  // ------------------------------ نمط غيوش ------------------------------
  static List<DecorPath> _guilloche(DecorSpec spec, double w, double h) {
    final double cx = w / 2;
    final double cy = h / 2;
    final double r = math.min(w, h) * 0.42;
    final int steps = 240;
    final List<DecorSegment> segs = <DecorSegment>[];
    final double phase = (spec.seed % 12) * math.pi / 12;
    for (int i = 0; i <= steps; i++) {
      final double a = i / steps * math.pi * 2;
      final double rr = r * (0.72 + 0.28 * math.cos(9 * a + phase));
      final double x = cx + rr * math.cos(a);
      final double y = cy + rr * math.sin(a);
      if (i == 0) {
        segs.add(DecorMove(x, y));
      } else {
        segs.add(DecorLine(x, y));
      }
    }
    return <DecorPath>[
      DecorPath(
        segments: segs,
        colorHex: lerpHex(spec.primaryHex, spec.secondaryHex, 0.5),
        closed: false,
        stroke: true,
        strokeWidth: (spec.thickness <= 0 ? 1.5 : spec.thickness) * 0.6,
      ),
    ];
  }

  // ------------------------------ شريط/وسام ------------------------------
  static List<DecorPath> _ribbonBanner(DecorSpec spec, double w, double h) {
    final double bandH = h * 0.34;
    final double top = h * 0.33;
    final double fold = math.min(w, h) * 0.10;
    final String body = lerpHex(spec.primaryHex, spec.secondaryHex, 0.35);
    return <DecorPath>[
      // الشريط الرئيسي.
      DecorPath(
        segments: <DecorSegment>[
          DecorMove(fold, top),
          DecorLine(w - fold, top),
          DecorLine(w - fold, top + bandH),
          DecorLine(fold, top + bandH),
        ],
        colorHex: body,
      ),
      // الطرف الأيسر (مثلث مطويّ).
      DecorPath(
        segments: <DecorSegment>[
          DecorMove(fold, top),
          DecorLine(0, top + bandH * 0.2),
          DecorLine(0, top + bandH * 0.8),
          DecorLine(fold, top + bandH),
        ],
        colorHex: lerpHex(body, '#000000', 0.18),
      ),
      // الطرف الأيمن.
      DecorPath(
        segments: <DecorSegment>[
          DecorMove(w - fold, top),
          DecorLine(w, top + bandH * 0.2),
          DecorLine(w, top + bandH * 0.8),
          DecorLine(w - fold, top + bandH),
        ],
        colorHex: lerpHex(body, '#000000', 0.18),
      ),
      // خط زخرفي أفقي بلون اللمسة.
      DecorPath(
        segments: <DecorSegment>[
          DecorMove(w * 0.18, top + bandH / 2),
          DecorLine(w * 0.82, top + bandH / 2),
        ],
        colorHex: spec.accentHex,
        closed: false,
        stroke: true,
        strokeWidth: (spec.thickness <= 0 ? 2 : spec.thickness) * 0.6,
      ),
    ];
  }

  // ==========================================================================
  //  الأدوات اللونية
  // ==========================================================================

  /// تدرّج خطّي بين لونين بنسبة `t` (0..1) — يعطي إحساس التدرّج بطبقات صلبة.
  static String lerpHex(String from, String to, double t) {
    final double k = t.clamp(0, 1).toDouble();
    final List<int> a = _rgb(from);
    final List<int> b = _rgb(to);
    return _hex(
      (a[0] + (b[0] - a[0]) * k).round(),
      (a[1] + (b[1] - a[1]) * k).round(),
      (a[2] + (b[2] - a[2]) * k).round(),
    );
  }

  static List<int> _rgb(String hex) {
    String value = hex.trim();
    if (value.startsWith('#')) value = value.substring(1);
    if (value.length == 3) {
      value = value.split('').map((String c) => '$c$c').join();
    }
    if (value.length < 6) return <int>[0, 0, 0];
    return <int>[
      int.tryParse(value.substring(0, 2), radix: 16) ?? 0,
      int.tryParse(value.substring(2, 4), radix: 16) ?? 0,
      int.tryParse(value.substring(4, 6), radix: 16) ?? 0,
    ];
  }

  static String _hex(int r, int g, int b) =>
      '#${_two(r)}${_two(g)}${_two(b)}';

  static String _two(int v) => v.clamp(0, 255).toRadixString(16).padLeft(2, '0');
}
