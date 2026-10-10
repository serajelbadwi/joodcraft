import 'dart:math' as math;

import '../constants/app_constants.dart';
import '../models/template_document.dart';
import '../models/template_element.dart';
import '../pdf/pdf_font_catalog.dart';
import 'preset_template.dart';
import 'invitation_group.dart';
import 'invitation_size.dart';

/// معرّف عنصر اسم صاحب الدعوة (`{{الاسم}}`) داخل كل القوالب.
const String invitationNameElementId = 'recipient_name';

/// معرّف عنصر نص الرسالة القابل للتعديل.
const String invitationMessageElementId = 'message';

/// قالب دعوة واحد: هندسة جاهزة + مجموعة + مقاس + رسالة افتراضية.
class InvitationTemplate {
  const InvitationTemplate({
    required this.id,
    required this.group,
    required this.size,
    required this.titleAr,
    required this.titleKey,
    required this.descriptionAr,
    required this.tags,
    required this.message,
    required this.document,
  });

  final String id;
  final InvitationGroup group;
  final InvitationSize size;
  final String titleAr;
  final String titleKey;
  final String descriptionAr;
  final List<String> tags;
  final String message;
  final TemplateDocument document;

  /// المجموعة الدلالية في مكتبة القوالب.
  TemplateCollection get collection => switch (group) {
        InvitationGroup.ramadan => TemplateCollection.ramadan,
        InvitationGroup.eid => TemplateCollection.eid,
        InvitationGroup.wedding => TemplateCollection.wedding,
      };

  TemplateCategory get category => TemplateCategory.certificate;

  PageOrientation get orientation => document.orientation;

  bool get isDigital => size.isDigital;

  /// الاسم الكامل بعد التعقيم ليس مطلوباً هنا — الاسم العربي هو المعرّف.
  bool matches(String needle) {
    final String query = needle.trim().toLowerCase();
    if (query.isEmpty) return true;
    return titleAr.toLowerCase().contains(query) ||
        descriptionAr.toLowerCase().contains(query) ||
        group.labelAr.contains(query) ||
        tags.any((String tag) => tag.toLowerCase().contains(query));
  }

  /// المستند بعد استبدال نص الرسالة (بقية العناصر كما هي).
  TemplateDocument withMessage(String nextMessage) {
    return document.copyWith(
      elements: <TemplateElement>[
        for (final TemplateElement element in document.elements)
          if (element is TextElement && element.id == invitationMessageElementId)
            element.copyWith(text: nextMessage)
          else
            element,
      ],
    );
  }

  /// تحويل إلى قالب مكتبة جاهز (`PresetTemplate`) بنفس الهوية.
  PresetTemplate toPreset() => PresetTemplate.fromDocument(
        id: id,
        titleAr: titleAr,
        descriptionAr: descriptionAr,
        collection: collection,
        orientation: orientation,
        tags: tags,
        document: document,
      );
}

/// القوالب السبعة الجاهزة + أدوات البناء المشتركة.
abstract final class InvitationTemplates {
  const InvitationTemplates._();

  /// القيمة التجريبية الوحيدة المطلوبة: حقل الاسم.
  static const Map<String, String> sampleData = <String, String>{
    'الاسم': 'أحمد محمد',
  };

  /// كل القوالب بترتيب العرض: رمضان، عيد، زفاف.
  static final List<InvitationTemplate> all = <InvitationTemplate>[
    ramadanClassic,
    ramadanStory,
    eidClassic,
    eidStory,
    weddingClassic,
    weddingModern,
    weddingStory,
  ];

  static List<InvitationTemplate> forGroup(InvitationGroup group) => all
      .where((InvitationTemplate template) => template.group == group)
      .toList(growable: false);

  static InvitationTemplate? byId(String? id) {
    for (final InvitationTemplate template in all) {
      if (template.id == id) return template;
    }
    return null;
  }

  /// نفس القوالب جاهزة للتسجيل في فهرس المكتبة.
  static List<PresetTemplate> get presets => <PresetTemplate>[
        for (final InvitationTemplate template in all) template.toPreset(),
      ];
}

// ==========================================================================
//                            أدوات البناء المشتركة
// ==========================================================================

/// مساحة التصميم بالبكسل عند 96dpi — نفس اصطلاح محرّك اللوحة.
double _designWidth(InvitationSize size) => size.unit == MeasurementUnit.px
    ? size.width
    : size.width / 25.4 * 96;

double _designHeight(InvitationSize size) => size.unit == MeasurementUnit.px
    ? size.height
    : size.height / 25.4 * 96;

/// موقع/مقاس نسبي داخل مساحة التصميم (كسور من العرض والارتفاع).
class _Frac {
  _Frac(this.w, this.h);

  final double w;
  final double h;

  double get min => math.min(w, h);

  /// حجم خط نسبي من أصغر بُعد (فيتناسب مع كل المقاسات).
  double fs(double frac) => min * frac;

  ElementBox box(double x, double y, double bw, double bh) =>
      ElementBox(x: w * x, y: h * y, width: w * bw, height: h * bh);

  /// مستطيل (يُستخدم للإطارات والأشرطة).
  ShapeElement rect(
    String id,
    double x,
    double y,
    double bw,
    double bh, {
    String? fill,
    String? stroke,
    double strokeWidth = 0,
    double? radius,
    List<double>? corners,
    double opacity = 1,
  }) =>
      ShapeElement(
        id: id,
        box: box(x, y, bw, bh),
        kind: ShapeKind.rect,
        fillHex: fill,
        strokeHex: stroke,
        strokeWidth: strokeWidth,
        radius: radius ?? 0,
        cornerRadii: corners,
        opacity: opacity,
      );

  /// دائرة/قطع ناقص (يُستخدم للأقواس والقصعة والورود).
  ShapeElement ellipse(
    String id,
    double x,
    double y,
    double bw,
    double bh, {
    String? fill,
    String? stroke,
    double strokeWidth = 0,
    double opacity = 1,
  }) =>
      ShapeElement(
        id: id,
        box: box(x, y, bw, bh),
        kind: ShapeKind.ellipse,
        fillHex: fill,
        strokeHex: stroke,
        strokeWidth: strokeWidth,
        opacity: opacity,
      );

  /// نجمة/معيّن زخرفي — بحجم بالبكسل حول مركز نسبي.
  ShapeElement star(
    String id,
    double centerX,
    double centerY,
    double sidePx, {
    String fill = '#C9A227',
    int points = 5,
    double innerRadius = 0.45,
    String? stroke,
    double strokeWidth = 0,
    double opacity = 1,
  }) =>
      ShapeElement(
        id: id,
        box: ElementBox(
          x: w * centerX - sidePx / 2,
          y: h * centerY - sidePx / 2,
          width: sidePx,
          height: sidePx,
        ),
        kind: ShapeKind.star,
        fillHex: fill,
        strokeHex: stroke,
        strokeWidth: strokeWidth,
        points: points,
        innerRadius: innerRadius,
        opacity: opacity,
      );

  /// خط فاصل (سماكة رقيقة).
  ShapeElement line(
    String id,
    double x,
    double y,
    double length, {
    required String stroke,
    double strokeWidth = 1,
    List<double>? dash,
  }) =>
      ShapeElement(
        id: id,
        box: ElementBox(x: w * x, y: h * y, width: w * length, height: 0),
        kind: ShapeKind.line,
        strokeHex: stroke,
        strokeWidth: strokeWidth,
        dashPattern: dash,
      );

  /// نص.
  TextElement text(
    String id,
    double x,
    double y,
    double bw,
    double bh,
    String value, {
    required double fontSize,
    required String color,
    PdfFontFamily family = PdfFontFamily.plex,
    PdfFontWeight weight = PdfFontWeight.regular,
    ElementTextAlign align = ElementTextAlign.center,
    ElementVerticalAlign verticalAlign = ElementVerticalAlign.middle,
    double lineHeight = 1.4,
    double letterSpacing = 0,
    int? maxLines,
    ElementDirection direction = ElementDirection.rtl,
  }) =>
      TextElement(
        id: id,
        box: box(x, y, bw, bh),
        text: value,
        family: family,
        weight: weight,
        fontSize: fontSize,
        colorHex: color,
        align: align,
        verticalAlign: verticalAlign,
        direction: direction,
        lineHeight: lineHeight,
        letterSpacing: letterSpacing,
        maxLines: maxLines,
      );

  /// بتلات وردة دائرية حول مركز نسبي (أبعاد البتلات بالبكسل).
  List<ShapeElement> rose(
    String prefix,
    double centerX,
    double centerY, {
    required double radiusPx,
    required double petalWidth,
    required double petalHeight,
    required String petalFill,
    required String coreFill,
    int petals = 8,
  }) {
    final double cx = w * centerX;
    final double cy = h * centerY;
    final List<ShapeElement> out = <ShapeElement>[];
    for (int i = 0; i < petals; i++) {
      final double angle = 2 * math.pi * i / petals;
      final double px = cx + radiusPx * math.cos(angle);
      final double py = cy + radiusPx * math.sin(angle);
      out.add(ShapeElement(
        id: '${prefix}_petal$i',
        box: ElementBox(
          x: px - petalWidth / 2,
          y: py - petalHeight / 2,
          width: petalWidth,
          height: petalHeight,
        ),
        kind: ShapeKind.rect,
        fillHex: petalFill,
        radius: petalWidth / 2,
        opacity: 0.95,
      ));
    }
    out.add(ShapeElement(
      id: '${prefix}_core',
      box: ElementBox(
        x: cx - petalWidth / 2,
        y: cy - petalWidth / 2,
        width: petalWidth,
        height: petalWidth,
      ),
      kind: ShapeKind.ellipse,
      fillHex: coreFill,
    ));
    return out;
  }
}

/// مستند قالب دعوة بهندسة [size] وخلفية [background] (وتدرّج اختياري).
TemplateDocument _doc({
  required InvitationSize size,
  required List<TemplateElement> elements,
  required String background,
  BackgroundGradient? gradient,
}) =>
    size.toDocument().copyWith(
      elements: elements,
      backgroundHex: background,
      backgroundGradient: gradient,
      sampleData: InvitationTemplates.sampleData,
    );

/// هلال: قرص ذهبي يُحفر عنه قرص بلون الخلفية (يبقى المدار واضحاً).
List<ShapeElement> _crescent(
  _Frac f, {
  required String id,
  required String gold,
  required String carve,
  required double cx,
  required double cy,
  required double diameter,
}) {
  final double cxp = f.w * cx;
  final double cyp = f.h * cy;
  return <ShapeElement>[
    ShapeElement(
      id: '${id}_moon',
      box: ElementBox(
        x: cxp - diameter / 2,
        y: cyp - diameter / 2,
        width: diameter,
        height: diameter,
      ),
      kind: ShapeKind.ellipse,
      fillHex: gold,
    ),
    ShapeElement(
      id: '${id}_carve',
      box: ElementBox(
        x: cxp - diameter / 2 + diameter * 0.3,
        y: cyp - diameter / 2 - diameter * 0.12,
        width: diameter * 0.96,
        height: diameter * 0.96,
      ),
      kind: ShapeKind.ellipse,
      fillHex: carve,
    ),
  ];
}

/// فانوس رمضاني: جسم كبسولي + غطاء + شرّابة.
List<ShapeElement> _lantern(
  _Frac f, {
  required String id,
  required String gold,
  required double cx,
  required double top,
  required double width,
  required double height,
}) {
  final double cxp = f.w * cx;
  final double topp = f.h * top;
  return <ShapeElement>[
    ShapeElement(
      id: '${id}_body',
      box: ElementBox(x: cxp - width / 2, y: topp, width: width, height: height),
      kind: ShapeKind.rect,
      fillHex: gold,
      radius: width / 2,
    ),
    ShapeElement(
      id: '${id}_cap',
      box: ElementBox(
        x: cxp - width * 0.34,
        y: topp - width * 0.22,
        width: width * 0.68,
        height: width * 0.22,
      ),
      kind: ShapeKind.rect,
      fillHex: gold,
      radius: width * 0.06,
    ),
    ShapeElement(
      id: '${id}_tassel',
      box: ElementBox(
        x: cxp - width * 0.05,
        y: topp + height,
        width: width * 0.1,
        height: height * 0.4,
      ),
      kind: ShapeKind.rect,
      fillHex: gold,
      radius: width * 0.05,
    ),
  ];
}

// ==========================================================================
//                               القوالب السبعة
// ==========================================================================

/// 🌙 رمضان كريم — كلاسيكي (Instagram مربّع، ذهبي/كحلي).
final InvitationTemplate ramadanClassic = InvitationTemplate(
  id: 'inv_ramadan_classic',
  group: InvitationGroup.ramadan,
  size: InvitationSizes.instagramSquare,
  titleAr: 'رمضان كريم — كلاسيكي',
  titleKey: 'invRamadan1Title',
  descriptionAr:
      'دعوة رمضان بالأزرق الكحلي والذهبي: قوس إسلامي وفانوس وهلال ونجوم، مع اسم صاحب الدعوة في الوسط.',
  tags: <String>['دعوة', 'رمضان', 'كلاسيكي', 'ذهبي', 'كحلي', 'فانوس', 'انستغرام'],
  message: 'تقبل الله منك صالح الأعمال — وكل عام وأنت بخير',
  document: _doc(
    size: InvitationSizes.instagramSquare,
    background: '#0E1B33',
    gradient: const BackgroundGradient(
      startHex: '#16294A',
      endHex: '#0B1526',
      direction: GradientDirection.vertical,
    ),
    elements: _ramadanClassicElements(),
  ),
);

List<TemplateElement> _ramadanClassicElements() {
  final _Frac f = _Frac(
    _designWidth(InvitationSizes.instagramSquare),
    _designHeight(InvitationSizes.instagramSquare),
  );
  return <TemplateElement>[
    f.rect('rc_frame_outer', 0.03, 0.03, 0.94, 0.94,
        stroke: '#C9A227', strokeWidth: 3, radius: f.min * 0.017),
    f.rect('rc_frame_inner', 0.045, 0.045, 0.91, 0.91,
        stroke: '#C9A227', strokeWidth: 1, radius: f.min * 0.01),
    // قوس إسلامي (جسم كبسولي) يحوي الهلال.
    f.rect('rc_arch', 0.27, 0.13, 0.46, 0.30,
        fill: '#152A4E', stroke: '#C9A227', strokeWidth: 2, radius: f.min * 0.23),
    ..._crescent(f,
        id: 'rc_crescent',
        gold: '#C9A227',
        carve: '#152A4E',
        cx: 0.5,
        cy: 0.235,
        diameter: f.min * 0.13),
    ..._lantern(f,
        id: 'rc_lantern_left',
        gold: '#C9A227',
        cx: 0.13,
        top: 0.20,
        width: f.min * 0.075,
        height: f.min * 0.10),
    ..._lantern(f,
        id: 'rc_lantern_right',
        gold: '#C9A227',
        cx: 0.87,
        top: 0.20,
        width: f.min * 0.075,
        height: f.min * 0.10),
    f.star('rc_star_a', 0.30, 0.075, f.min * 0.022),
    f.star('rc_star_b', 0.50, 0.055, f.min * 0.018),
    f.star('rc_star_c', 0.70, 0.075, f.min * 0.022),
    f.text('rc_title', 0.10, 0.55, 0.80, 0.09, 'رمضان كريم',
        fontSize: f.fs(0.075),
        color: '#C9A227',
        family: PdfFontFamily.amiri,
        weight: PdfFontWeight.bold),
    f.text(invitationNameElementId, 0.08, 0.66, 0.84, 0.10, '{{الاسم}}',
        fontSize: f.fs(0.062),
        color: '#FFFFFF',
        weight: PdfFontWeight.bold,
        maxLines: 2),
    f.line('rc_rule', 0.30, 0.79, 0.40, stroke: '#C9A227', strokeWidth: 2),
    f.text(invitationMessageElementId, 0.10, 0.84, 0.80, 0.085,
        'تقبل الله منك صالح الأعمال — وكل عام وأنت بخير',
        fontSize: f.fs(0.032), color: '#E4EBF4', lineHeight: 1.7, maxLines: 3),
    f.text('rc_footer', 0.10, 0.925, 0.80, 0.04, 'جودكرافت',
        fontSize: f.fs(0.018), color: '#8FA3BC'),
  ];
}

/// 🌙 رمضان كريم — Story (1080×1920، بنفسجي/ذهبي).
final InvitationTemplate ramadanStory = InvitationTemplate(
  id: 'inv_ramadan_story',
  group: InvitationGroup.ramadan,
  size: InvitationSizes.instagramStory,
  titleAr: 'رمضان كريم — Story',
  titleKey: 'invRamadan2Title',
  descriptionAr:
      'دعوة رمضان عمودية: هلال كبير ونجوم وفوانيس، «كل عام وأنتم بخير» في الأسفل.',
  tags: <String>['دعوة', 'رمضان', 'قصة', 'بنفسجي', 'ذهبي', 'فانوس'],
  message: 'كل عام وأنتم بخير',
  document: _doc(
    size: InvitationSizes.instagramStory,
    background: '#241546',
    elements: _ramadanStoryElements(),
  ),
);

List<TemplateElement> _ramadanStoryElements() {
  final _Frac f = _Frac(
    _designWidth(InvitationSizes.instagramStory),
    _designHeight(InvitationSizes.instagramStory),
  );
  return <TemplateElement>[
    f.rect('rs_frame', 0.05, 0.03, 0.90, 0.94,
        stroke: '#C9A227', strokeWidth: 2, radius: f.min * 0.016),
    ..._crescent(f,
        id: 'rs_crescent',
        gold: '#E3C565',
        carve: '#241546',
        cx: 0.5,
        cy: 0.19,
        diameter: f.min * 0.26),
    f.star('rs_star_a', 0.30, 0.12, f.min * 0.02, fill: '#E3C565'),
    f.star('rs_star_b', 0.70, 0.12, f.min * 0.02, fill: '#E3C565'),
    f.star('rs_star_c', 0.22, 0.24, f.min * 0.016, fill: '#E3C565'),
    f.star('rs_star_d', 0.78, 0.24, f.min * 0.016, fill: '#E3C565'),
    f.star('rs_star_e', 0.50, 0.07, f.min * 0.013, fill: '#E3C565'),
    ..._lantern(f,
        id: 'rs_lantern_left',
        gold: '#E3C565',
        cx: 0.15,
        top: 0.30,
        width: f.min * 0.07,
        height: f.min * 0.09),
    ..._lantern(f,
        id: 'rs_lantern_right',
        gold: '#E3C565',
        cx: 0.85,
        top: 0.30,
        width: f.min * 0.07,
        height: f.min * 0.09),
    f.text('rs_title', 0.10, 0.42, 0.80, 0.07, 'رمضان كريم',
        fontSize: f.fs(0.055),
        color: '#F0D98C',
        family: PdfFontFamily.amiri,
        weight: PdfFontWeight.bold),
    f.line('rs_rule', 0.35, 0.51, 0.30, stroke: '#C9A227', strokeWidth: 2),
    f.star('rs_star_f', 0.5, 0.51, f.min * 0.018, fill: '#C9A227'),
    f.text(invitationNameElementId, 0.08, 0.56, 0.84, 0.12, '{{الاسم}}',
        fontSize: f.fs(0.05),
        color: '#FFFFFF',
        weight: PdfFontWeight.bold,
        maxLines: 2),
    f.line('rs_rule_bottom', 0.32, 0.72, 0.36, stroke: '#C9A227', strokeWidth: 2),
    f.text(invitationMessageElementId, 0.12, 0.78, 0.76, 0.08, 'كل عام وأنتم بخير',
        fontSize: f.fs(0.034), color: '#F4E3B2'),
    f.text('rs_sub', 0.12, 0.88, 0.76, 0.06, 'تقبل الله منكم صالح الأعمال',
        fontSize: f.fs(0.024), color: '#D7C8F0'),
  ];
}

/// 🎉 عيد مبارك — كلاسيكي (Instagram مربّع، ذهبي/أخضر).
final InvitationTemplate eidClassic = InvitationTemplate(
  id: 'inv_eid_classic',
  group: InvitationGroup.eid,
  size: InvitationSizes.instagramSquare,
  titleAr: 'عيد مبارك — كلاسيكي',
  titleKey: 'invEid1Title',
  descriptionAr:
      'دعوة عيد بالأخضر والذهبي: نجمة إسلامية ثمانية وهلال وزخارف زوايا، واسم المدعو في الوسط.',
  tags: <String>['دعوة', 'عيد', 'كلاسيكي', 'ذهبي', 'أخضر', 'زخرفة إسلامية'],
  message: 'تقبل الله منا ومنكم صالح الأعمال',
  document: _doc(
    size: InvitationSizes.instagramSquare,
    background: '#0F3D2E',
    gradient: const BackgroundGradient(
      startHex: '#14523D',
      endHex: '#0A2E22',
      direction: GradientDirection.vertical,
    ),
    elements: _eidClassicElements(),
  ),
);

List<TemplateElement> _eidClassicElements() {
  final _Frac f = _Frac(
    _designWidth(InvitationSizes.instagramSquare),
    _designHeight(InvitationSizes.instagramSquare),
  );
  return <TemplateElement>[
    f.rect('ec_frame_outer', 0.03, 0.03, 0.94, 0.94,
        stroke: '#D4AF37', strokeWidth: 3, radius: f.min * 0.017),
    f.rect('ec_frame_inner', 0.045, 0.045, 0.91, 0.91,
        stroke: '#D4AF37', strokeWidth: 1, radius: f.min * 0.01),
    // ميدالية صلبة يحفر فيها الهلال (فلا يتأثر بلون الخلفية المتدرّج).
    f.ellipse('ec_medallion', 0.39, 0.10, 0.22, 0.22, fill: '#0B3128'),
    f.star('ec_ornament', 0.5, 0.21, f.min * 0.265,
        points: 8, innerRadius: 0.42, stroke: '#D4AF37', strokeWidth: 2),
    ..._crescent(f,
        id: 'ec_crescent',
        gold: '#D4AF37',
        carve: '#0B3128',
        cx: 0.5,
        cy: 0.21,
        diameter: f.min * 0.12),
    f.star('ec_star_corner_1', 0.10, 0.10, f.min * 0.022, fill: '#D4AF37'),
    f.star('ec_star_corner_2', 0.90, 0.10, f.min * 0.022, fill: '#D4AF37'),
    f.star('ec_star_corner_3', 0.10, 0.90, f.min * 0.022, fill: '#D4AF37'),
    f.star('ec_star_corner_4', 0.90, 0.90, f.min * 0.022, fill: '#D4AF37'),
    f.text('ec_title', 0.10, 0.52, 0.80, 0.09, 'عيد مبارك',
        fontSize: f.fs(0.075),
        color: '#D4AF37',
        family: PdfFontFamily.amiri,
        weight: PdfFontWeight.bold),
    f.text(invitationNameElementId, 0.08, 0.63, 0.84, 0.10, '{{الاسم}}',
        fontSize: f.fs(0.062),
        color: '#FFFFFF',
        weight: PdfFontWeight.bold,
        maxLines: 2),
    f.line('ec_rule', 0.31, 0.76, 0.38, stroke: '#D4AF37', strokeWidth: 2),
    f.text(invitationMessageElementId, 0.10, 0.81, 0.80, 0.07,
        'تقبل الله منا ومنكم صالح الأعمال',
        fontSize: f.fs(0.03), color: '#DFF0E6', maxLines: 2),
    f.text('ec_footer', 0.10, 0.90, 0.80, 0.05, 'عيد سعيد',
        fontSize: f.fs(0.024), color: '#D4AF37'),
  ];
}

/// 🎉 عيد مبارك — Story (1080×1920، ذهبي/أسود).
final InvitationTemplate eidStory = InvitationTemplate(
  id: 'inv_eid_story',
  group: InvitationGroup.eid,
  size: InvitationSizes.instagramStory,
  titleAr: 'عيد مبارك — Story',
  titleKey: 'invEid2Title',
  descriptionAr:
      'دعوة عيد عمودية: هلال كبير ونجوم ذهبية على أسود، «كل عام وأنتم بخير» و«عيد سعيد».',
  tags: <String>['دعوة', 'عيد', 'قصة', 'ذهبي', 'أسود', 'هلال'],
  message: 'كل عام وأنتم بخير — عيد سعيد',
  document: _doc(
    size: InvitationSizes.instagramStory,
    background: '#101010',
    elements: _eidStoryElements(),
  ),
);

List<TemplateElement> _eidStoryElements() {
  final _Frac f = _Frac(
    _designWidth(InvitationSizes.instagramStory),
    _designHeight(InvitationSizes.instagramStory),
  );
  return <TemplateElement>[
    f.rect('es_frame', 0.05, 0.03, 0.90, 0.94,
        stroke: '#D4AF37', strokeWidth: 2, radius: f.min * 0.016),
    ..._crescent(f,
        id: 'es_crescent',
        gold: '#D4AF37',
        carve: '#101010',
        cx: 0.5,
        cy: 0.20,
        diameter: f.min * 0.34),
    f.star('es_star_a', 0.30, 0.12, f.min * 0.02, fill: '#D4AF37'),
    f.star('es_star_b', 0.70, 0.12, f.min * 0.02, fill: '#D4AF37'),
    f.star('es_star_c', 0.24, 0.22, f.min * 0.016, fill: '#D4AF37'),
    f.star('es_star_d', 0.76, 0.22, f.min * 0.016, fill: '#D4AF37'),
    f.star('es_star_e', 0.50, 0.09, f.min * 0.013, fill: '#D4AF37'),
    f.text('es_title', 0.10, 0.40, 0.80, 0.07, 'عيد مبارك',
        fontSize: f.fs(0.055),
        color: '#D4AF37',
        family: PdfFontFamily.amiri,
        weight: PdfFontWeight.bold),
    f.line('es_rule', 0.36, 0.49, 0.28, stroke: '#D4AF37', strokeWidth: 2),
    f.star('es_star_f', 0.5, 0.49, f.min * 0.018, fill: '#D4AF37'),
    f.text(invitationNameElementId, 0.08, 0.54, 0.84, 0.12, '{{الاسم}}',
        fontSize: f.fs(0.05),
        color: '#FFFFFF',
        weight: PdfFontWeight.bold,
        maxLines: 2),
    f.line('es_rule_bottom', 0.32, 0.70, 0.36, stroke: '#D4AF37', strokeWidth: 2),
    f.text(invitationMessageElementId, 0.10, 0.76, 0.80, 0.08,
        'كل عام وأنتم بخير — عيد سعيد',
        fontSize: f.fs(0.034), color: '#D4AF37'),
    f.text('es_sub', 0.10, 0.86, 0.80, 0.06, 'تقبل الله منكم صالح الأعمال',
        fontSize: f.fs(0.026), color: '#C9C9C9'),
  ];
}

/// 💍 زفاف كلاسيكي (A6 رأسي 105×148، ذهبي/كريمي).
final InvitationTemplate weddingClassic = InvitationTemplate(
  id: 'inv_wedding_classic',
  group: InvitationGroup.wedding,
  size: InvitationSizes.a6Portrait,
  titleAr: 'زفاف كلاسيكي',
  titleKey: 'invWedding1Title',
  descriptionAr:
      'دعوة زفاف مطبوعة على A6: وردة ذهبية وزخرفة، «يتشرف السيد/ة»، والمكان والتاريخ.',
  tags: <String>['دعوة', 'زفاف', 'كلاسيكي', 'ذهبي', 'كريمي', 'وردة', 'طباعة'],
  message: 'يتشرف السيد/ة {{الاسم}} بدعوتكم لحضور حفل زفاف',
  document: _doc(
    size: InvitationSizes.a6Portrait,
    background: '#FBF6EE',
    elements: _weddingClassicElements(),
  ),
);

List<TemplateElement> _weddingClassicElements() {
  final _Frac f = _Frac(
    _designWidth(InvitationSizes.a6Portrait),
    _designHeight(InvitationSizes.a6Portrait),
  );
  return <TemplateElement>[
    f.rect('wc_frame_outer', 0.05, 0.045, 0.90, 0.91,
        stroke: '#C08A5A', strokeWidth: 2, radius: f.min * 0.025),
    f.rect('wc_frame_inner', 0.075, 0.065, 0.85, 0.87,
        stroke: '#C08A5A', strokeWidth: 1, radius: f.min * 0.018),
    ...f.rose('wc_rose', 0.5, 0.16,
        radiusPx: f.min * 0.10,
        petalWidth: f.min * 0.06,
        petalHeight: f.min * 0.085,
        petalFill: '#D9B06A',
        coreFill: '#B8814A'),
    f.line('wc_rule_left', 0.34, 0.29, 0.12, stroke: '#C08A5A', strokeWidth: 1),
    f.line('wc_rule_right', 0.54, 0.29, 0.12, stroke: '#C08A5A', strokeWidth: 1),
    f.star('wc_ornament', 0.5, 0.29, f.min * 0.03,
        points: 4, innerRadius: 0.6, fill: '#C08A5A'),
    f.text('wc_title', 0.10, 0.34, 0.80, 0.06, 'دعوة زفاف',
        fontSize: f.fs(0.05),
        color: '#6B4F2E',
        family: PdfFontFamily.amiri,
        weight: PdfFontWeight.bold),
    f.text(invitationNameElementId, 0.08, 0.42, 0.84, 0.09, '{{الاسم}}',
        fontSize: f.fs(0.055),
        color: '#8A5A2B',
        family: PdfFontFamily.amiri,
        weight: PdfFontWeight.bold,
        maxLines: 2),
    f.line('wc_rule_middle', 0.36, 0.53, 0.28, stroke: '#C08A5A', strokeWidth: 1),
    f.text(invitationMessageElementId, 0.08, 0.58, 0.84, 0.14,
        'يتشرف السيد/ة {{الاسم}} بدعوتكم لحضور حفل زفاف',
        fontSize: f.fs(0.036), color: '#6B4F2E', lineHeight: 1.7, maxLines: 4),
    f.line('wc_rule_bottom', 0.38, 0.74, 0.24, stroke: '#C08A5A', strokeWidth: 1),
    f.text('wc_place', 0.08, 0.77, 0.84, 0.05, 'المكان: قاعة الأصيل — الرياض',
        fontSize: f.fs(0.03), color: '#6B4F2E'),
    f.text('wc_date', 0.08, 0.83, 0.84, 0.05, 'التاريخ: ٢٠ رمضان ١٤٤٨هـ',
        fontSize: f.fs(0.03), color: '#6B4F2E'),
    f.text('wc_footer', 0.08, 0.90, 0.84, 0.05, 'يسرنا حضوركم',
        fontSize: f.fs(0.028),
        color: '#C08A5A',
        family: PdfFontFamily.amiri),
  ];
}

/// 💍 زفاف حديث (Instagram مربّع، أبيض/أسود).
final InvitationTemplate weddingModern = InvitationTemplate(
  id: 'inv_wedding_modern',
  group: InvitationGroup.wedding,
  size: InvitationSizes.instagramSquare,
  titleAr: 'زفاف حديث',
  titleKey: 'invWedding2Title',
  descriptionAr:
      'دعوة زفاف مينيمال: خطوط هندسية بسيطة ودائرة أنيقة، اسم المدعو بخط مودرن.',
  tags: <String>['دعوة', 'زفاف', 'حديث', 'مينيمال', 'أبيض', 'أسود', 'هندسي'],
  message: 'يسعدنا دعوتكم لحضور حفل زفافنا',
  document: _doc(
    size: InvitationSizes.instagramSquare,
    background: '#FFFFFF',
    elements: _weddingModernElements(),
  ),
);

List<TemplateElement> _weddingModernElements() {
  final _Frac f = _Frac(
    _designWidth(InvitationSizes.instagramSquare),
    _designHeight(InvitationSizes.instagramSquare),
  );
  return <TemplateElement>[
    f.ellipse('wm_circle', 0.35, 0.12, 0.30, 0.30,
        stroke: '#1A1A1A', strokeWidth: 2),
    // خطوط هندسية رقيقة (أعمدة رفيعة بدل الخطوط لتغطية الاتجاهين).
    f.rect('wm_bar_vertical', 0.499, 0.05, 0.002, 0.37, fill: '#9AA0A6'),
    f.rect('wm_bar_horizontal', 0.05, 0.269, 0.90, 0.002, fill: '#9AA0A6'),
    f.star('wm_diamond', 0.5, 0.27, f.min * 0.06,
        points: 4, innerRadius: 0.62, fill: '#1A1A1A'),
    f.text('wm_invite', 0.10, 0.42, 0.80, 0.06, 'يسعدنا دعوتكم',
        fontSize: f.fs(0.028),
        color: '#6B7280',
        letterSpacing: 4,
        family: PdfFontFamily.cairo),
    f.text(invitationNameElementId, 0.08, 0.50, 0.84, 0.12, '{{الاسم}}',
        fontSize: f.fs(0.06),
        color: '#1A1A1A',
        weight: PdfFontWeight.bold,
        family: PdfFontFamily.cairo),
    f.rect('wm_rule', 0.35, 0.675, 0.30, 0.0025, fill: '#1A1A1A'),
    f.text(invitationMessageElementId, 0.10, 0.73, 0.80, 0.07,
        'لحضور حفل زفافنا',
        fontSize: f.fs(0.032), color: '#374151'),
    f.text('wm_details', 0.10, 0.83, 0.80, 0.05, 'قاعة الأصيل — الرياض',
        fontSize: f.fs(0.024), color: '#6B7280', letterSpacing: 2),
  ];
}

/// 💍 زفاف Story (1080×1920، وردي/ذهبي).
final InvitationTemplate weddingStory = InvitationTemplate(
  id: 'inv_wedding_story',
  group: InvitationGroup.wedding,
  size: InvitationSizes.instagramStory,
  titleAr: 'زفاف Story',
  titleKey: 'invWedding3Title',
  descriptionAr:
      'دعوة زفاف عمودية: خاتمان متشابكان وورود، «يسعدنا دعوتكم لحضور حفل زفافنا».',
  tags: <String>['دعوة', 'زفاف', 'قصة', 'وردي', 'ذهبي', 'خواتم', 'ورود'],
  message: 'يسعدنا دعوتكم لحضور حفل زفافنا',
  document: _doc(
    size: InvitationSizes.instagramStory,
    background: '#F7E8EC',
    elements: _weddingStoryElements(),
  ),
);

List<TemplateElement> _weddingStoryElements() {
  final _Frac f = _Frac(
    _designWidth(InvitationSizes.instagramStory),
    _designHeight(InvitationSizes.instagramStory),
  );
  return <TemplateElement>[
    // خاتمان متشابكان.
    f.ellipse('ws_ring_1', 0.27, 0.09, 0.26, 0.26,
        stroke: '#C08A5A', strokeWidth: 3),
    f.ellipse('ws_ring_2', 0.47, 0.09, 0.26, 0.26,
        stroke: '#C08A5A', strokeWidth: 3),
    ...f.rose('ws_rose_top_left', 0.14, 0.30,
        radiusPx: f.min * 0.05,
        petalWidth: f.min * 0.032,
        petalHeight: f.min * 0.045,
        petalFill: '#E7B7A8',
        coreFill: '#C98772'),
    ...f.rose('ws_rose_top_right', 0.86, 0.30,
        radiusPx: f.min * 0.05,
        petalWidth: f.min * 0.032,
        petalHeight: f.min * 0.045,
        petalFill: '#E7B7A8',
        coreFill: '#C98772'),
    ...f.rose('ws_rose_bottom_left', 0.14, 0.76,
        radiusPx: f.min * 0.05,
        petalWidth: f.min * 0.032,
        petalHeight: f.min * 0.045,
        petalFill: '#E7B7A8',
        coreFill: '#C98772'),
    ...f.rose('ws_rose_bottom_right', 0.86, 0.76,
        radiusPx: f.min * 0.05,
        petalWidth: f.min * 0.032,
        petalHeight: f.min * 0.045,
        petalFill: '#E7B7A8',
        coreFill: '#C98772'),
    f.text('ws_title', 0.10, 0.40, 0.80, 0.07, 'دعوة زفاف',
        fontSize: f.fs(0.052),
        color: '#C08A5A',
        family: PdfFontFamily.amiri,
        weight: PdfFontWeight.bold),
    f.text(invitationNameElementId, 0.08, 0.49, 0.84, 0.12, '{{الاسم}}',
        fontSize: f.fs(0.055),
        color: '#7A4A2E',
        family: PdfFontFamily.amiri,
        weight: PdfFontWeight.bold,
        maxLines: 2),
    f.rect('ws_rule', 0.36, 0.645, 0.28, 0.0025, fill: '#C08A5A'),
    f.text(invitationMessageElementId, 0.10, 0.70, 0.80, 0.08,
        'يسعدنا دعوتكم لحضور حفل زفافنا',
        fontSize: f.fs(0.034), color: '#7A4A2E'),
    f.text('ws_sub', 0.10, 0.80, 0.80, 0.06, 'وتشاركوننا فرحتنا',
        fontSize: f.fs(0.026), color: '#9C6B4A'),
  ];
}
