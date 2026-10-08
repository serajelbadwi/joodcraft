import 'dart:math' as math;
import 'dart:ui' show Color, Rect;

import 'package:flutter/foundation.dart' show immutable;

import '../models/template_document.dart';
import 'imposition_calculator.dart';

// ===========================================================================
//  تحويلات الوحدات
// ===========================================================================

/// مليمتر ← نقطة طباعة (1 بوصة = 25.4 ملم = 72 نقطة).
double mmToPt(double mm) => mm / 25.4 * 72;

/// نقطة طباعة ← مليمتر.
double ptToMm(double pt) => pt * 25.4 / 72;

// ===========================================================================
//  علامات القصّ
// ===========================================================================

/// خطّ قصّ محوري واحد على الورقة (بالمليمتر، من الزاوية العليا اليسرى).
@immutable
class CropMarkLine {
  const CropMarkLine({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  final double x1;
  final double y1;
  final double x2;
  final double y2;

  /// هل الخط أفقي؟ (الخطوط هنا محورية دائماً).
  bool get isHorizontal => (y1 - y2).abs() < 1e-9;

  /// الطول بالملم.
  double get lengthMm =>
      isHorizontal ? (x2 - x1).abs() : (y2 - y1).abs();

  @override
  String toString() =>
      'CropMarkLine($x1,$y1 → $x2,$y2)';
}

/// مظهر علامات القصّ: ابتعادها عن خطّ القطع وطولها وسُمكها ولونها.
///
/// القيم الافتراضية مقيسة على معايير الطباعة: العلامة تبدأ بعد ابتعاد صغير
/// عن حدّ القطع حتى لا تلمس المطبوع، وطويلة بما يكفي لتُرى على الطاولة.
@immutable
class CropMarkStyle {
  const CropMarkStyle({
    this.offsetMm = 1,
    this.lengthMm = 3,
    this.thicknessMm = 0.15,
    this.color = const Color(0xFF1A1A1A),
  });

  /// المسافة بين حدّ القطع وببداية العلامة.
  final double offsetMm;

  /// طول كل علامة.
  final double lengthMm;

  /// سُمك الخط (يُستخدم في الـ PDF والمعاينة معاً).
  final double thicknessMm;

  /// لون العلامات (أسود شبه صافٍ في المعاينة).
  final Color color;

  /// إجمالي المسافة التي تحتاجها العلامة خارج حدّ القطع (ابتعاد + طول).
  double get reachMm => offsetMm + lengthMm;
}

/// يبني علامات القصّ لنقطة واحدة: **ثماني خطوط** (اثنان لكل ركن).
///
/// في كل ركن: خط أفقي وخط رأسي يبدآن بعد [CropMarkStyle.offsetMm] من حدّ
/// القطع ويمتدّان للخارج. العلامات المرسومة **خارج** الصندوق لا تلمس المطبوع
/// أبداً، وتُدمج مع علامات القطع المجاورة لتُعطي خطّ قصّ متصلاً عند
/// التقاطعات الخارجية (وهذا المقصود بـ«التقاطعات الخارجية» في المواصفة).
///
/// كل علامة تُحدَّد إلى حدود الورقة، وتُحذف إن صارت صفراً (لا مساحة خارجية
/// كافية — مثل الصندوق الملاصق لحافة الورقة عند هامش صفر).
List<CropMarkLine> cropMarksFor(
  ImpositionPlacement placement, {
  required double sheetWidthMm,
  required double sheetHeightMm,
  CropMarkStyle style = const CropMarkStyle(),
}) {
  if (style.lengthMm <= 0 || style.offsetMm < 0) return const <CropMarkLine>[];

  final double left = placement.leftMm;
  final double top = placement.topMm;
  final double right = placement.rightMm;
  final double bottom = placement.bottomMm;
  final double offset = style.offsetMm;
  final double reach = style.reachMm;

  final List<CropMarkLine> marks = <CropMarkLine>[];

  // الأركان الأربعة: (الس، الص) مع اتجاه الامتداد للخارج على كل محور.
  const List<(int, int, int, int)> corners = <(int, int, int, int)>[
    (0, 0, -1, -1), // أعلى يسار
    (1, 0, 1, -1), // أعلى يمين
    (0, 1, -1, 1), // أسفل يسار
    (1, 1, 1, 1), // أسفل يمين
  ];

  for (final (int rightward, int downward, int dx, int dy) in corners) {
    final double x = rightward == 1 ? right : left;
    final double y = downward == 1 ? bottom : top;

    // علامة أفقيّة تمتدّ جانبياً من الركن.
    final CropMarkLine? horizontal = _horizontalMark(
      y: y,
      from: x + dx * offset,
      to: x + dx * reach,
      limit: sheetWidthMm,
    );
    if (horizontal != null) marks.add(horizontal);

    // علامة رأسيّة تمتدّ عمودياً من الركن.
    final CropMarkLine? vertical = _verticalMark(
      x: x,
      from: y + dy * offset,
      to: y + dy * reach,
      limit: sheetHeightMm,
    );
    if (vertical != null) marks.add(vertical);
  }

  return marks;
}

/// علامة أفقية محصورة داخل عرض الورقة (أو `null` إن انعدمت).
CropMarkLine? _horizontalMark({
  required double y,
  required double from,
  required double to,
  required double limit,
}) {
  final double a = from.clamp(0.0, limit);
  final double b = to.clamp(0.0, limit);
  final double lo = math.min(a, b);
  final double hi = math.max(a, b);
  if (hi - lo < 1e-9) return null;
  return CropMarkLine(x1: lo, y1: y, x2: hi, y2: y);
}

/// علامة رأسية محصورة داخل ارتفاع الورقة (أو `null` إن انعدمت).
CropMarkLine? _verticalMark({
  required double x,
  required double from,
  required double to,
  required double limit,
}) {
  final double a = from.clamp(0.0, limit);
  final double b = to.clamp(0.0, limit);
  final double lo = math.min(a, b);
  final double hi = math.max(a, b);
  if (hi - lo < 1e-9) return null;
  return CropMarkLine(x1: x, y1: lo, x2: x, y2: hi);
}

/// كل علامات الورقة: تُجمَّع لكل نسخة على الشبكة.
List<CropMarkLine> cropMarksForSheet(
  ImpositionResult result, {
  CropMarkStyle style = const CropMarkStyle(),
}) {
  if (result.isEmpty) return const <CropMarkLine>[];
  final List<CropMarkLine> marks = <CropMarkLine>[];
  for (final ImpositionPlacement placement in result.placements) {
    marks.addAll(
      cropMarksFor(
        placement,
        sheetWidthMm: result.sheetWidthMm,
        sheetHeightMm: result.sheetHeightMm,
        style: style,
      ),
    );
  }
  return marks;
}

/// مستطيل **خط الأمان (النزف)** — منطقة الطباعة الآمنة داخل الهامش والاحتياط.
///
/// **غير قابل للطباعة**: يُرسم في المعاينة فقط ليري المستخدم الحدّ الذي لا
/// يجوز تجاوزه، ولا يدخل في ملف الـ PDF إطلاقاً.
Rect bleedSafetyRect(ImpositionResult result) => Rect.fromLTRB(
      result.insetMm,
      result.insetMm,
      result.sheetWidthMm - result.insetMm,
      result.sheetHeightMm - result.insetMm,
    );

// ===========================================================================
//  مواصفة الحصر — مدخل واحد للمعاينة والتصدير
// ===========================================================================

/// كل ما يحتاجه الحصر: الورقة + العنصر + الفواصل والهوامش + مظهر العلامات.
///
/// وجود هذه الفئة في موضع واحد يضمن أن **ما يراه المستخدم في المعاينة هو ما
/// يخرج في ملف الـ PDF بالضبط** — كلاهما يبني [layout] من هذه المواصفة نفسها.
@immutable
class ImpositionSpec {
  const ImpositionSpec({
    required this.sheet,
    required this.itemWidthMm,
    required this.itemHeightMm,
    this.gutterXMm = 8,
    this.gutterYMm = 8,
    this.marginMm = 5,
    this.bleedMm = 0,
    this.allowRotation = true,
    this.sheetLandscape = false,
    this.markStyle = const CropMarkStyle(),
  });

  /// الورقة المستهدفة.
  final ImpositionSheet sheet;

  /// أبعاد العنصر الواحد (ملم).
  final double itemWidthMm;
  final double itemHeightMm;

  /// الفاصل بين النسخ أفقياً ورأسياً (ملم).
  final double gutterXMm;
  final double gutterYMm;

  /// هامش الورقة + احتياط النزف (ملم).
  final double marginMm;
  final double bleedMm;

  final bool allowRotation;
  final bool sheetLandscape;

  /// مظهر علامات القصّ.
  final CropMarkStyle markStyle;

  /// الحساب — نفس النتيجة تماماً في المعاينة وفي الـ PDF.
  ImpositionResult layout() => ImpositionCalculator.calculate(
        itemWidthMm: itemWidthMm,
        itemHeightMm: itemHeightMm,
        sheet: sheet,
        gutterXMm: gutterXMm,
        gutterYMm: gutterYMm,
        marginMm: marginMm,
        bleedMm: bleedMm,
        allowRotation: allowRotation,
        sheetLandscape: sheetLandscape,
      );

  ImpositionSpec copyWith({
    ImpositionSheet? sheet,
    double? gutterXMm,
    double? gutterYMm,
    double? marginMm,
    double? bleedMm,
    bool? allowRotation,
    CropMarkStyle? markStyle,
  }) =>
      ImpositionSpec(
        sheet: sheet ?? this.sheet,
        itemWidthMm: itemWidthMm,
        itemHeightMm: itemHeightMm,
        gutterXMm: gutterXMm ?? this.gutterXMm,
        gutterYMm: gutterYMm ?? this.gutterYMm,
        marginMm: marginMm ?? this.marginMm,
        bleedMm: bleedMm ?? this.bleedMm,
        allowRotation: allowRotation ?? this.allowRotation,
        sheetLandscape: sheetLandscape,
        markStyle: markStyle ?? this.markStyle,
      );

  /// مواصفة مشتقّة من مقاس صفحة المستند نفسه: **الخلية = صفحة العنصر بالضبط**
  /// (الدورة مليمتر ← نقطة ← مليمتر لا تُحدث انزياحاً يُذكر)، فلا تتغيّر
  /// هندسة التصميم عند التجميع.
  factory ImpositionSpec.fromDocument(
    TemplateDocument document, {
    required ImpositionSheet sheet,
    double gutterXMm = 8,
    double gutterYMm = 8,
    double marginMm = 5,
    double bleedMm = 0,
    bool allowRotation = true,
    bool sheetLandscape = false,
    CropMarkStyle markStyle = const CropMarkStyle(),
  }) =>
      ImpositionSpec(
        sheet: sheet,
        itemWidthMm: ptToMm(document.pageWidthPt),
        itemHeightMm: ptToMm(document.pageHeightPt),
        gutterXMm: gutterXMm,
        gutterYMm: gutterYMm,
        marginMm: marginMm,
        bleedMm: bleedMm,
        allowRotation: allowRotation,
        sheetLandscape: sheetLandscape,
        markStyle: markStyle,
      );

  // ------------------------------ أهلية التجميع ------------------------------

  /// أطول ضلع يُعدّ «صغيراً» إذا بلغ هذا الحدّ (ملم).
  ///
  /// ‎210‎ = الطول الأطول لمقاس A5: البطاقات (90/85.6) وA6 وA5 وDL وكل
  /// المقاسات الرقمية الصغيرة تدخل، بينما A4 وA3 وLetter تخرج.
  static const double smallFormatLimitMm = 210;

  /// هل يستحق هذا المستند التجميع للطباعة؟
  ///
  /// شرط «المقاسات الصغيرة» فقط: التجميع على ورقة أكبر مفيد للمقاسات التي
  /// تُطبع عادةً مجمّعةً (كروت، أرقام جلوس، معايدات)، لا للأوراق الكبيرة.
  static bool isEligible(TemplateDocument document) {
    final double widthMm = ptToMm(document.pageWidthPt);
    final double heightMm = ptToMm(document.pageHeightPt);
    if (widthMm <= 0 || heightMm <= 0) return false;
    final double longest = math.max(widthMm, heightMm);
    return longest <= smallFormatLimitMm + 0.5;
  }

  /// الورقة المقترحة تلقائياً لمقاس هذا المستند (أكبر ورقة تتسع له بفائدة).
  ///
  /// اختيار أولي منطقي يُظهره الواجهة قابلاً للتغيير: لا داعي لحصر A4 داخل
  /// A4، والبطاقة الصغيرة تُجمَّع فوراً على ربع الفرخ مثلاً.
  static ImpositionSheet suggestSheetFor(TemplateDocument document) {
    final double widthMm = ptToMm(document.pageWidthPt);
    final double heightMm = ptToMm(document.pageHeightPt);
    final double longest = math.max(widthMm, heightMm);
    if (longest <= 105) return ImpositionSheet.quarter; // A6 فما دون
    if (longest <= 210) return ImpositionSheet.a3;
    if (longest <= 297) return ImpositionSheet.a3;
    return ImpositionSheet.quarter;
  }
}
