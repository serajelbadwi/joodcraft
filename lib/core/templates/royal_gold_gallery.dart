import '../constants/app_constants.dart';
import '../models/template_document.dart';
import '../models/template_element.dart';
import '../pdf/pdf_font_catalog.dart';
import 'preset_template.dart';

/// مجموعة **«ستايل الكحلي والذهبي»** — 6 قوالب شهادة بأسلوب موحّد فاخر.
///
/// المرجع البصري: قالب «شهادة الاستحقاق الملكي» (`imperial_medallion_certificate`)
/// بلوحة الألوان نفسها — كحلي داكن `#0F1B3C`، ذهبي `#C9A961`، نصّ أبيض نقي —
/// مع ستة تخطيطات مختلفة تماماً في البنية لا في اللون فقط.
///
/// كل القوالب:
/// * A4 أفقي (297×210 ملم) ومساحة تصميم قدرها 1123×793 وحدة (96dpi).
/// * تصنيف «شهادات تقدير» ([TemplateCollection.appreciation]).
/// * حقول ديناميكية من مكتبة `DynamicFields` — يعمل الربط التلقائي مع Excel.
/// * رمز QR للتحقق + ختم دائري ذهبي بنجمة (حسب التخطيط).
///
/// **قاعدة الصيانة:** أي تعديل على لوحة الألوان يُطبَّق على [Colors] أدناه فقط
/// فتنتقل إلى القوالبة الستة كلها بلا تعارض.
abstract final class RoyalGoldGallery {
  const RoyalGoldGallery._();

  // ==========================================================================
  //                            لوحة الألوان الموحّدة
  // ==========================================================================

  /// كحلي داكن — خلفية كل القوالب الستة.
  static const String navy = '#0F1B3C';

  /// كحلي أعمق — للتدرّجات والحلقات الداخلية.
  static const String navyDeep = '#08102A';

  /// ذهبي — لون التمييز الأساسي.
  static const String gold = '#C9A961';

  /// ذهبي داكن — للحدود الفرعية والتدرّجات.
  static const String goldDeep = '#A8894A';

  /// ذهبي فاتح — للعناوين والنصوص البارزة.
  static const String goldLight = '#E6D3A3';

  /// أبيض نقي — النص الرئيسي.
  static const String white = '#FFFFFF';

  /// رمادي مائل للأزرق — النصوص الثانوية.
  static const String muted = '#9FADCC';

  // ==========================================================================
  //                            الحقول التجريبية
  // ==========================================================================

  /// قيم تجريبية تغطي كل حقول الشهادات — فتظهر كل القوالب مكتملة في المعاينة.
  static const Map<String, String> _sample = <String, String>{
    'اسم_المتدرب': 'عبدالله بن أحمد الأحمد',
    'اسم_الدورة': 'إدارة المشاريع الاحترافية',
    'رقم_الشهادة': 'JC-2026-000145',
    'التاريخ': '١٥ محرم ١٤٤٨هـ',
    'الجهة_المانحة': 'منصة جودكرافت',
    'المدرب': 'د. سارة العتيبي',
    'مدة_الدورة': '40 ساعة تدريبية',
    'مستوى_الأداء': 'ممتاز مع مرتبة الشرف',
    'رابط_التحقق': 'https://joodcraft.app/v/JC-2026-000145',
  };

  // ==========================================================================
  //                             بُناة العناصر
  // ==========================================================================

  static TemplateDocument _doc(List<TemplateElement> elements) =>
      TemplateDocument(
        elements: elements,
        paperSize: PaperSize.a4,
        orientation: PageOrientation.landscape,
        backgroundHex: navy,
        sampleData: _sample,
      );

  static ElementBox _b(double x, double y, double w, double h) =>
      ElementBox(x: x, y: y, width: w, height: h);

  static ShapeElement _rect(
    String id,
    double x,
    double y,
    double w,
    double h, {
    String? fill,
    String? stroke,
    double strokeWidth = 0,
    double radius = 0,
    List<double>? corners,
    ShapeGradient? gradient,
    ShapeShadow? shadow,
    double fillOpacity = 1,
    double opacity = 1,
    double rotation = 0,
  }) =>
      ShapeElement(
        id: id,
        box: _b(x, y, w, h),
        kind: ShapeKind.rect,
        fillHex: fill,
        strokeHex: stroke,
        strokeWidth: strokeWidth,
        radius: radius,
        cornerRadii: corners,
        gradient: gradient,
        shadow: shadow,
        fillOpacity: fillOpacity,
        opacity: opacity,
        rotation: rotation,
      );

  static ShapeElement _ellipse(
    String id,
    double x,
    double y,
    double w,
    double h, {
    String? fill,
    String? stroke,
    double strokeWidth = 0,
    double opacity = 1,
  }) =>
      ShapeElement(
        id: id,
        box: _b(x, y, w, h),
        kind: ShapeKind.ellipse,
        fillHex: fill,
        strokeHex: stroke,
        strokeWidth: strokeWidth,
        opacity: opacity,
      );

  static ShapeElement _star(
    String id,
    double x,
    double y,
    double side, {
    String fill = gold,
    int points = 5,
    double innerRadius = 0.45,
    double opacity = 1,
    double rotation = 0,
  }) =>
      ShapeElement(
        id: id,
        box: _b(x, y, side, side),
        kind: ShapeKind.star,
        fillHex: fill,
        points: points,
        innerRadius: innerRadius,
        opacity: opacity,
        rotation: rotation,
      );

  static ShapeElement _polygon(
    String id,
    double x,
    double y,
    double side, {
    String? fill,
    String? stroke,
    double strokeWidth = 0,
    int points = 6,
    double opacity = 1,
    double rotation = 0,
  }) =>
      ShapeElement(
        id: id,
        box: _b(x, y, side, side),
        kind: ShapeKind.polygon,
        fillHex: fill,
        strokeHex: stroke,
        strokeWidth: strokeWidth,
        points: points,
        opacity: opacity,
        rotation: rotation,
      );

  static ShapeElement _line(
    String id,
    double x,
    double y,
    double w, {
    required String stroke,
    double strokeWidth = 1,
    List<double>? dash,
    double rotation = 0,
  }) =>
      ShapeElement(
        id: id,
        box: _b(x, y, w, 0),
        kind: ShapeKind.line,
        strokeHex: stroke,
        strokeWidth: strokeWidth,
        dashPattern: dash,
        rotation: rotation,
      );

  static TextElement _text(
    String id,
    double x,
    double y,
    double w,
    double h,
    String text, {
    double size = 16,
    String color = white,
    PdfFontWeight weight = PdfFontWeight.regular,
    PdfFontFamily family = PdfFontFamily.amiri,
    ElementTextAlign align = ElementTextAlign.center,
    ElementVerticalAlign valign = ElementVerticalAlign.top,
    double lineHeight = 1.4,
    int? maxLines,
    double letterSpacing = 0,
    ElementDirection direction = ElementDirection.rtl,
  }) =>
      TextElement(
        id: id,
        box: _b(x, y, w, h),
        text: text,
        family: family,
        weight: weight,
        fontSize: size,
        colorHex: color,
        align: align,
        verticalAlign: valign,
        direction: direction,
        lineHeight: lineHeight,
        letterSpacing: letterSpacing,
        maxLines: maxLines,
      );

  static SealElement _seal(
    String id,
    double x,
    double y,
    double side, {
    String fill = gold,
    String ring = navy,
    String star = navyDeep,
    double starRatio = 0.5,
  }) =>
      SealElement(
        id: id,
        box: _b(x, y, side, side),
        fillHex: fill,
        ringHex: ring,
        starHex: star,
        starRatio: starRatio,
      );

  static QrElement _qr(
    String id,
    double x,
    double y,
    double side,
    String data, {
    String color = goldLight,
    String background = navyDeep,
  }) =>
      QrElement(
        id: id,
        box: _b(x, y, side, side),
        data: data,
        colorHex: color,
        backgroundHex: background,
      );

  // ==========================================================================
  //                         كتلة المحتوى المشتركة
  // ==========================================================================

  /// مقدّمة + اسم + سطر تزيين + نص الجسم + تاريخ — تُبنى داخل كل قالب.
  static List<TemplateElement> _body(
    double top, {
    String intro = 'تشهد {{الجهة_المانحة}} بأن',
    String body =
        'تقديرًا لجهوده المتميّزة وأدائه البارز في {{اسم_الدورة}} بمدة {{مدة_الدورة}}، وإشراف {{المدرب}}، مع تمنياتنا له بدوام التوفيق.',
    String dateLabel = 'التاريخ: {{التاريخ}}',
  }) =>
      <TemplateElement>[
        _text('intro', 111, top, 900, 34, intro,
            size: 20, color: muted, valign: ElementVerticalAlign.middle),
        _text('recipient', 61, top + 42, 1000, 104, '{{اسم_المتدرب}}',
            size: 42,
            weight: PdfFontWeight.bold,
            color: white,
            valign: ElementVerticalAlign.middle,
            lineHeight: 1.25,
            maxLines: 2),
        _rect('rule_name', 361, top + 156, 400, 2, fill: gold),
        _text('body', 131, top + 178, 860, 120, body,
            size: 19, color: white, lineHeight: 1.9, maxLines: 4),
        _text('date', 361, top + 306, 400, 30, dateLabel,
            size: 16, color: goldLight),
      ];

  /// سطرّان للتوقيع + ختم + تذييل + QR — القاسم المشترك في التذييل.
  static List<TemplateElement> _footer({
    required double y,
    String leftLabel = 'التوقيع المعتمد',
    String rightLabel = 'المدير التنفيذي',
    required String footerText,
    bool showQr = true,
  }) =>
      <TemplateElement>[
        _line('sign_line_left', 110, y, 250, stroke: gold),
        _text('sign_label_left', 110, y + 6, 250, 26, leftLabel,
            size: 13, color: muted),
        _line('sign_line_right', 762, y, 250, stroke: gold),
        _text('sign_label_right', 762, y + 6, 250, 26, rightLabel,
            size: 13, color: muted),
        _text('footer', 60, 726, 700, 22, footerText,
            size: 11,
            color: muted,
            align: ElementTextAlign.start),
        if (showQr)
          _qr('qr', 990, 650, 88, '{{رابط_التحقق}}',
              color: goldLight, background: navyDeep),
      ];

  /// ترويسة موحّدة: عنوان عربي رئيسي + سطر لاتيني فرعي + خط فاصل ذهبي.
  static List<TemplateElement> _header(
    double top,
    String title,
    String subtitle, {
    PdfFontFamily family = PdfFontFamily.amiri,
    double size = 40,
  }) =>
      <TemplateElement>[
        _text('title', 60, top, 1002, 60, title,
            size: size, weight: PdfFontWeight.bold, family: family,
            color: goldLight, valign: ElementVerticalAlign.middle),
        _text('subtitle', 60, top + 62, 1002, 22, subtitle,
            size: 12,
            color: gold,
            direction: ElementDirection.ltr,
            letterSpacing: 3.4),
        _rect('rule_top', 461, top + 104, 200, 4, fill: gold, radius: 2),
      ];

  // ==========================================================================
  //                        1) أفقي كلاسيكي — إطار مزدوج وزوايا مزخرفة
  // ==========================================================================

  static final PresetTemplate _classicNavyGold = PresetTemplate.fromDocument(
    id: 'classic_navy_gold_certificate',
    titleAr: 'شهادة كلاسيكية كحلية',
    descriptionAr: 'قالب كحلي كلاسيكي بإطار ذهبي مزدوج وزوايا مزخرفة بالنجوم.',
    collection: TemplateCollection.appreciation,
    orientation: PageOrientation.landscape,
    tags: <String>['شهادة', 'كلاسيكي', 'كحلي', 'ذهبي', 'ملكي', 'إطار'],
    document: _doc(
      <TemplateElement>[
        ...<TemplateElement>[
          _rect('frame_outer', 24, 24, 1074, 746,
              stroke: gold, strokeWidth: 3, radius: 18),
          _rect('frame_inner', 44, 44, 1034, 706,
              stroke: gold, strokeWidth: 1, radius: 10),
          _star('corner_tl', 54, 54, 34),
          _star('corner_tr', 1034, 54, 34),
          _star('corner_bl', 54, 706, 34),
          _star('corner_br', 1034, 706, 34),
        ],
        ..._header(66, 'شهادة تقدير كلاسيكية', 'CLASSIC CERTIFICATE OF MERIT'),
        _ellipse('intro_rule_left', 331, 178, 24, 2, fill: gold),
        _ellipse('intro_rule_right', 767, 178, 24, 2, fill: gold),
        ..._body(200),
        _seal('seal', 497, 592, 112, fill: gold, ring: navy, star: navyDeep),
        ..._footer(
          y: 666,
          footerText: 'رقم الشهادة: {{رقم_الشهادة}} — للتحقق امسح الرمز',
        ),
      ],
    ),
  );

  // ==========================================================================
  //                      2) مينيمال حديث — خلفية نظيفة وخط ذهبي واحد
  // ==========================================================================

  static final PresetTemplate _minimalNavyGold = PresetTemplate.fromDocument(
    id: 'minimal_navy_gold_certificate',
    titleAr: 'شهادة مينيمال كحلية',
    descriptionAr: 'تصميم مينيمال كحلي نظيف بخط ذهبي واحد ومساحات واسعة.',
    collection: TemplateCollection.appreciation,
    orientation: PageOrientation.landscape,
    tags: <String>['شهادة', 'مينيمال', 'حديث', 'كحلي', 'ذهبي', 'نظيف'],
    document: _doc(
      <TemplateElement>[
        _rect('rule_single', 111, 88, 900, 3, fill: gold, radius: 2),
        _text('kicker', 111, 108, 900, 26, 'شهادة',
            size: 15,
            family: PdfFontFamily.cairo,
            color: gold,
            align: ElementTextAlign.start,
            letterSpacing: 4),
        _text('title', 111, 140, 900, 58, 'شهادة تقدير',
            size: 42,
            weight: PdfFontWeight.bold,
            family: PdfFontFamily.cairo,
            color: white,
            align: ElementTextAlign.start,
            valign: ElementVerticalAlign.middle),
        _text('intro', 111, 214, 900, 34, 'تشهد {{الجهة_المانحة}} بأن',
            size: 20,
            family: PdfFontFamily.cairo,
            color: muted,
            align: ElementTextAlign.start),
        _text('recipient', 111, 250, 900, 104, '{{اسم_المتدرب}}',
            size: 44,
            weight: PdfFontWeight.bold,
            family: PdfFontFamily.cairo,
            color: white,
            align: ElementTextAlign.start,
            valign: ElementVerticalAlign.middle,
            lineHeight: 1.25,
            maxLines: 2),
        _rect('rule_body', 111, 372, 900, 1, fill: goldDeep),
        _text('body', 111, 394, 900, 130,
            'تقديرًا لجهوده المتميّزة وأدائه البارز في {{اسم_الدورة}} بمدة {{مدة_الدورة}}، وإشراف {{المدرب}}، مع تمنياتنا له بدوام التوفيق.',
            size: 19,
            family: PdfFontFamily.cairo,
            color: white,
            align: ElementTextAlign.start,
            lineHeight: 1.9,
            maxLines: 4),
        _text('date', 111, 548, 400, 30, '{{التاريخ}}',
            size: 16, family: PdfFontFamily.cairo, color: goldLight),
        _line('sign_line_left', 111, 650, 250, stroke: gold),
        _text('sign_label_left', 111, 656, 250, 26, 'التوقيع المعتمد',
            size: 13, family: PdfFontFamily.cairo, color: muted),
        _seal('seal', 902, 578, 108,
            fill: gold, ring: navy, star: navyDeep, starRatio: 0.42),
        _qr('qr', 990, 650, 88, '{{رابط_التحقق}}'),
        _text('footer', 111, 726, 700, 22,
            'رقم الشهادة: {{رقم_الشهادة}} — للتحقق امسح الرمز',
            size: 11,
            family: PdfFontFamily.cairo,
            color: muted,
            align: ElementTextAlign.start),
      ],
    ),
  );

  // ==========================================================================
  //                    3) زخرفة إسلامية — حواف ذهبية وخط أميري
  // ==========================================================================

  static final PresetTemplate _islamicOrnamentNavyGold =
      PresetTemplate.fromDocument(
    id: 'islamic_ornament_navy_gold_certificate',
    titleAr: 'شهادة زخرفية إسلامية',
    descriptionAr: 'قالب كحلي بحواف ذهبية وزخارف هندسية إسلامية وخط أميري.',
    collection: TemplateCollection.appreciation,
    orientation: PageOrientation.landscape,
    tags: <String>['شهادة', 'إسلامي', 'زخرفة', 'أميري', 'كحلي', 'ذهبي'],
    document: _doc(
      <TemplateElement>[
        // حواف ذهبية علوية وسفلية بخطّين متوازيين.
        _rect('band_top', 0, 0, 1122, 34, fill: gold),
        _rect('band_top_inner', 0, 34, 1122, 4, fill: goldDeep),
        _rect('band_bottom', 0, 759, 1122, 34, fill: gold),
        _rect('band_bottom_inner', 0, 755, 1122, 4, fill: goldDeep),
        // زخرفة علوية: نجمة ثمانية مركزية داخل مضلّعين سدسيين.
        _polygon('ornament_hex_outer', 466, 62, 190,
            stroke: gold, strokeWidth: 2, points: 8),
        _polygon('ornament_hex_inner', 486, 82, 150,
            stroke: goldDeep, strokeWidth: 1, points: 8),
        _star('ornament_core', 531, 127, 60,
            fill: gold, points: 8, innerRadius: 0.38),
        _star('ornament_flare_l', 396, 129, 22,
            fill: goldLight, points: 8, innerRadius: 0.4),
        _star('ornament_flare_r', 704, 129, 22,
            fill: goldLight, points: 8, innerRadius: 0.4),
        ..._header(272, 'شهادة تقدير مباركة', 'CERTIFICATE OF APPRECIATION'),
        ..._body(392),
        _seal('seal', 497, 640, 104,
            fill: gold, ring: navy, star: navyDeep, starRatio: 0.45),
        _line('sign_line_left', 110, 700, 250, stroke: gold),
        _text('sign_label_left', 110, 706, 250, 26, 'التوقيع المعتمد',
            size: 13, color: muted),
        _line('sign_line_right', 762, 700, 250, stroke: gold),
        _text('sign_label_right', 762, 706, 250, 26, 'المدير التنفيذي',
            size: 13, color: muted),
      ],
    ),
  );

  // ==========================================================================
  //                      4) شريط ذهبي — شرائط أفقية أعلى وأسفل
  // ==========================================================================

  static final PresetTemplate _goldBandNavyGold = PresetTemplate.fromDocument(
    id: 'gold_band_navy_certificate',
    titleAr: 'شهادة الشرائط الذهبية',
    descriptionAr: 'قالب كحلي بشرائط ذهبية أفقية أعلى وأسفل وتذييل منسّق.',
    collection: TemplateCollection.appreciation,
    orientation: PageOrientation.landscape,
    tags: <String>['شهادة', 'شرائط', 'ذهبي', 'كحلي', 'رسمي'],
    document: _doc(
      <TemplateElement>[
        // شريط علوي سميك + خطّان رقيقان.
        _rect('band_top', 0, 0, 1122, 96, fill: gold),
        _rect('band_top_line1', 0, 100, 1122, 3, fill: goldDeep),
        _rect('band_top_line2', 0, 108, 1122, 2, fill: gold),
        // شريط سفني مكافئ.
        _rect('band_bottom', 0, 697, 1122, 96, fill: gold),
        _rect('band_bottom_line1', 0, 691, 1122, 3, fill: goldDeep),
        _rect('band_bottom_line2', 0, 682, 1122, 2, fill: gold),
        _text('org_top', 60, 26, 700, 44, '{{الجهة_المانحة}}',
            size: 24,
            weight: PdfFontWeight.bold,
            color: navy,
            align: ElementTextAlign.start,
            valign: ElementVerticalAlign.middle),
        _text('subtitle_top', 840, 30, 222, 36, 'CERTIFICATE',
            size: 15,
            color: navyDeep,
            direction: ElementDirection.ltr,
            letterSpacing: 3.4),
        _seal('header_seal', 1024, 16, 64,
            fill: navy, ring: navyDeep, star: gold),
        _text('title', 111, 148, 900, 56, 'شهادة تقدير معتمدة',
            size: 38,
            weight: PdfFontWeight.bold,
            color: goldLight,
            valign: ElementVerticalAlign.middle),
        _rect('rule_top', 461, 220, 200, 3, fill: gold, radius: 2),
        ..._body(240),
        _seal('seal', 497, 566, 104, fill: gold, ring: navy, star: navyDeep),
        _line('sign_line_left', 110, 626, 250, stroke: gold),
        _text('sign_label_left', 110, 632, 250, 26, 'التوقيع المعتمد',
            size: 13, color: muted),
        _line('sign_line_right', 762, 626, 250, stroke: gold),
        _text('sign_label_right', 762, 632, 250, 26, 'المدير التنفيذي',
            size: 13, color: muted),
      ],
    ),
  );

  // ==========================================================================
  //                    5) مائل ديناميكي — أشكال هندسية ذهبية مائلة
  // ==========================================================================

  static final PresetTemplate _dynamicDiagonalNavyGold =
      PresetTemplate.fromDocument(
    id: 'dynamic_diagonal_navy_gold_certificate',
    titleAr: 'شهادة ديناميكية مائلة',
    descriptionAr: 'قالب كحلي بأشكال هندسية ذهبية مائلة وإحساس بالحركة.',
    collection: TemplateCollection.appreciation,
    orientation: PageOrientation.landscape,
    tags: <String>['شهادة', 'ديناميكي', 'مائل', 'هندسي', 'كحلي', 'ذهبي'],
    document: _doc(
      <TemplateElement>[
        // أشكال مائلة: أضلاع متوازية أعلى اليسار وأسفل اليمين.
        // الصناديق كلها داخل مساحة التصميم؛ الميل يأتي من الدوران حول مركز
        // الصندوق فتخرج الأطراف بصرياً خارج الورقة (تأثير «النزيف» المقصود).
        _rect('slant_bar_1', 70, 120, 320, 24,
            fill: gold, opacity: 0.9, rotation: -32),
        _rect('slant_bar_2', 70, 156, 220, 12,
            fill: goldDeep, opacity: 0.9, rotation: -32),
        _rect('slant_bar_3', 732, 636, 320, 24,
            fill: gold, opacity: 0.9, rotation: -32),
        _rect('slant_bar_4', 832, 672, 220, 12,
            fill: goldDeep, opacity: 0.9, rotation: -32),
        // مثلثان ذهبيان صغيران عند الزوايا المقابلة.
        _polygon('triangle_tl', 44, 40, 86,
            fill: gold, points: 3, rotation: 180),
        _polygon('triangle_br', 992, 668, 86, fill: gold, points: 3),
        // نجمات صغيرة على القطر.
        _star('spark_1', 118, 108, 26, fill: goldLight, points: 4,
            innerRadius: 0.3),
        _star('spark_2', 978, 660, 26, fill: goldLight, points: 4,
            innerRadius: 0.3),
        _text('title', 111, 118, 900, 58, 'شهادة تميّز',
            size: 40,
            weight: PdfFontWeight.bold,
            family: PdfFontFamily.cairo,
            color: goldLight,
            align: ElementTextAlign.start,
            valign: ElementVerticalAlign.middle),
        _text('subtitle', 111, 180, 900, 22, 'CERTIFICATE OF EXCELLENCE',
            size: 12,
            color: gold,
            direction: ElementDirection.ltr,
            letterSpacing: 3.6),
        _rect('rule_slant', 111, 224, 300, 6, fill: gold, rotation: -12),
        _text('intro', 111, 258, 900, 34, 'تشهد {{الجهة_المانحة}} بأن',
            size: 20,
            family: PdfFontFamily.cairo,
            color: muted,
            align: ElementTextAlign.start),
        _text('recipient', 111, 296, 900, 104, '{{اسم_المتدرب}}',
            size: 42,
            weight: PdfFontWeight.bold,
            family: PdfFontFamily.cairo,
            color: white,
            align: ElementTextAlign.start,
            valign: ElementVerticalAlign.middle,
            lineHeight: 1.25,
            maxLines: 2),
        _rect('rule_name', 111, 414, 400, 2, fill: gold),
        _text('body', 111, 434, 900, 120,
            'تقديرًا لجهوده المتميّزة وأدائه البارز في {{اسم_الدورة}} بمدة {{مدة_الدورة}}، وإشراف {{المدرب}}، مع تمنياتنا له بدوام التوفيق.',
            size: 19,
            family: PdfFontFamily.cairo,
            color: white,
            align: ElementTextAlign.start,
            lineHeight: 1.9,
            maxLines: 4),
        _text('date', 111, 574, 400, 30, 'التاريخ: {{التاريخ}}',
            size: 16, family: PdfFontFamily.cairo, color: goldLight),
        _line('sign_line_left', 111, 652, 250, stroke: gold),
        _text('sign_label_left', 111, 658, 250, 26, 'التوقيع المعتمد',
            size: 13, family: PdfFontFamily.cairo, color: muted),
        _seal('seal', 902, 560, 108,
            fill: gold, ring: navy, star: navyDeep, starRatio: 0.42),
        _qr('qr', 990, 650, 88, '{{رابط_التحقق}}'),
        _text('footer', 111, 726, 700, 22,
            'رقم الشهادة: {{رقم_الشهادة}} — للتحقق امسح الرمز',
            size: 11,
            family: PdfFontFamily.cairo,
            color: muted,
            align: ElementTextAlign.start),
      ],
    ),
  );

  // ==========================================================================
  //                     6) مربع أنيق — إطار مربع + ختم علوي
  // ==========================================================================

  static final PresetTemplate _squareElegantNavyGold =
      PresetTemplate.fromDocument(
    id: 'square_elegant_navy_gold_certificate',
    titleAr: 'شهادة مربعة أنيقة',
    descriptionAr: 'قالب كحلي بإطار ذهبي مربّع متناظر وختم دائري علوي.',
    collection: TemplateCollection.appreciation,
    orientation: PageOrientation.landscape,
    tags: <String>['شهادة', 'مربع', 'أنيق', 'ختم', 'كحلي', 'ذهبي'],
    document: _doc(
      <TemplateElement>[
        // إطار مربّع: هامش أفقي أكبر ليخرج المربع متناظقاً داخل الورقة الأفقية.
        _rect('frame_outer', 168, 24, 786, 746,
            stroke: gold, strokeWidth: 3, radius: 6),
        _rect('frame_inner', 186, 42, 750, 710,
            stroke: goldDeep, strokeWidth: 1, radius: 3),
        // ختم دائري أعلى الإطار.
        _seal('top_seal', 511, 40, 100,
            fill: gold, ring: navy, star: navyDeep, starRatio: 0.46),
        _text('title', 196, 158, 730, 56, 'شهادة تقدير أنيقة',
            size: 38,
            weight: PdfFontWeight.bold,
            color: goldLight,
            valign: ElementVerticalAlign.middle),
        _text('subtitle', 196, 220, 730, 22, 'CERTIFICATE OF MERIT',
            size: 12,
            color: gold,
            direction: ElementDirection.ltr,
            letterSpacing: 3.2),
        _rect('rule_top', 461, 260, 200, 3, fill: gold, radius: 2),
        _text('intro', 246, 286, 630, 34, 'تشهد {{الجهة_المانحة}} بأن',
            size: 20, color: muted, valign: ElementVerticalAlign.middle),
        _text('recipient', 196, 322, 730, 100, '{{اسم_المتدرب}}',
            size: 40,
            weight: PdfFontWeight.bold,
            color: white,
            valign: ElementVerticalAlign.middle,
            lineHeight: 1.25,
            maxLines: 2),
        _rect('rule_name', 361, 430, 400, 2, fill: gold),
        _text('body', 246, 450, 630, 130,
            'تقديرًا لجهوده المتميّزة وأدائه البارز في {{اسم_الدورة}} بمدة {{مدة_الدورة}}، وإشراف {{المدرب}}، مع تمنياتنا له بدوام التوفيق.',
            size: 19, color: white, lineHeight: 1.9, maxLines: 5),
        _text('date', 246, 592, 630, 30, 'التاريخ: {{التاريخ}}',
            size: 16, color: goldLight),
        _line('sign_line_left', 246, 660, 220, stroke: gold),
        _text('sign_label_left', 246, 666, 220, 26, 'التوقيع المعتمد',
            size: 13, color: muted),
        _line('sign_line_right', 656, 660, 220, stroke: gold),
        _text('sign_label_right', 656, 666, 220, 26, 'المدير التنفيذي',
            size: 13, color: muted),
        _qr('qr', 830, 620, 88, '{{رابط_التحقق}}'),
        _text('footer', 246, 726, 630, 22,
            'رقم الشهادة: {{رقم_الشهادة}} — للتحقق امسح الرمز',
            size: 11,
            color: muted,
            align: ElementTextAlign.start),
      ],
    ),
  );

  // ==========================================================================
  //                                الفهرس
  // ==========================================================================

  /// كل قوالب ستايل الكحلي/الذهبي الستة بترتيب العرض.
  static final List<PresetTemplate> presets = <PresetTemplate>[
    _classicNavyGold,
    _minimalNavyGold,
    _islamicOrnamentNavyGold,
    _goldBandNavyGold,
    _dynamicDiagonalNavyGold,
    _squareElegantNavyGold,
  ];
}
