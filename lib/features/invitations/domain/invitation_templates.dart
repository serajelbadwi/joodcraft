import 'dart:math' as math;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/template_document.dart';
import '../../../../core/models/template_element.dart';
import '../../../../core/pdf/pdf_font_catalog.dart';
import '../../../../core/templates/preset_template.dart';
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
  static const List<InvitationTemplate> all = <InvitationTemplate>[
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
