import '../constants/app_constants.dart';
import 'certificate_gallery.dart';
import 'preset_template.dart';
import 'royal_gold_gallery.dart';

/// فهرس القوالب الجاهزة المحزومة داخل التطبيق (Preset Templates).
///
/// كل قالب حمولته JSON مضمّنة في الكود (لا ملف ولا شبكة)، فيعمل أوفلاين في كل
/// البيئات، وتُترجم عند الطلب إلى `TemplateDocument`/`TemplateRecord` كأي قالب.
/// الحقول الديناميكية تستخدم مفاتيح `DynamicFields` العربية ليعمل الربط التلقائي
/// في محرّك Excel بلا تدخّل.
abstract final class PresetCatalog {
  const PresetCatalog._();

  /// كل القوالب الجاهزة — المصدر الثابت الذي تبني منه المكتبة أوفلاين.
  static final List<PresetTemplate> all = <PresetTemplate>[
    _appreciation,
    _completion,
    _excellence,
    _experienceDeclaration,
    _employmentContract,
    _serviceContract,
    // ------- حزمة التوسعة: باقة باليتات عصرية متنوعة -------
    _classicAppreciation,
    _achievementCertificate,
    _attendanceCertificate,
    _scienceProgressCertificate,
    _fixedTermContract,
    _consultingContract,
    // ---- معرض الشهادات الموسّع: 12 تصميماً ليصل مجموع الشهادات إلى 20 ----
    ...CertificateGallery.presets,
    // ---- ستايل الكحلي/الذهبي: 6 تصاميم بلوحة ألوان موحّدة (A4 أفقي) ----
    ...RoyalGoldGallery.presets,
  ];

  /// كل قوالب **الشهادات** فقط (بلا العقود) — لعدّها وتصفيتها في واجهة المكتبة.
  static List<PresetTemplate> get certificates => all
      .where((PresetTemplate preset) =>
          preset.category == TemplateCategory.certificate)
      .toList(growable: false);

  /// كل قوالب **العقود** فقط.
  static List<PresetTemplate> get contracts => all
      .where((PresetTemplate preset) =>
          preset.category == TemplateCategory.contract)
      .toList(growable: false);

  /// بحث قالب جاهز بمعرّفه (بلا بادئة السجل).
  static PresetTemplate? byId(String id) {
    for (final PresetTemplate preset in all) {
      if (preset.id == id) return preset;
    }
    return null;
  }

  // ==========================================================================
  //                            الشهادات (أفقية)
  // ==========================================================================

  static final PresetTemplate _appreciation = PresetTemplate(
    id: 'appreciation_certificate',
    titleAr: 'شهادة شكر وتقدير',
    descriptionAr: 'قالب رسمي أنيق لإكرام المتميزين وإثبات الجهود المبذولة.',
    collection: TemplateCollection.appreciation,
    orientation: PageOrientation.landscape,
    tags: <String>['شهادة', 'تقدير', 'شكر', 'تكريم'],
    layoutJson: r'''
{
  "schema_version": 1,
  "paper": "a4",
  "orientation": "landscape",
  "background": "#FFFDF8",
  "canvas": { "width": 1123, "height": 794, "unit": "px" },
  "sample_data": {
    "اسم_المتدرب": "عبدالله بن أحمد الأحمد",
    "الجهة_المانحة": "منصة جودكرافت",
    "التاريخ": "١٥ محرم ١٤٤٨هـ",
    "رقم_الشهادة": "JC-2026-000112",
    "رابط_التحقق": "https://joodcraft.app/v/JC-2026-000112"
  },
  "elements": [
    { "id": "frame_outer", "type": "rect", "x": 30, "y": 30, "w": 1063, "h": 734, "stroke": "#C7A26B", "strokeWidth": 2.5, "radius": 10 },
    { "id": "frame_inner", "type": "rect", "x": 44, "y": 44, "w": 1035, "h": 706, "stroke": "#1B2539", "strokeWidth": 1, "radius": 6 },
    { "id": "header_band", "type": "rect", "x": 44, "y": 44, "w": 1035, "h": 104, "fill": "#1B2539", "radius": 6 },
    { "id": "title", "type": "text", "x": 44, "y": 64, "w": 1035, "h": 54, "text": "شهادة شكر وتقدير", "font": "plex", "weight": "bold", "size": 38, "color": "#FFFFFF", "align": "center", "valign": "middle" },
    { "id": "subtitle", "type": "text", "x": 44, "y": 118, "w": 1035, "h": 20, "text": "CERTIFICATE OF APPRECIATION", "font": "plex", "size": 11, "color": "#C7A26B", "align": "center", "direction": "ltr", "letterSpacing": 3.2 },
    { "id": "rule_top", "type": "line", "x": 461, "y": 180, "w": 200, "stroke": "#C7A26B", "strokeWidth": 4 },
    { "id": "intro", "type": "text", "x": 111, "y": 202, "w": 900, "h": 32, "text": "تشهد إدارة {{الجهة_المانحة}} بأن", "font": "plex", "size": 21, "color": "#6B7280", "align": "center" },
    { "id": "recipient", "type": "text", "x": 61, "y": 240, "w": 1000, "h": 80, "text": "{{اسم_المتدرب}}", "font": "plex", "weight": "bold", "size": 44, "color": "#1B2539", "align": "center", "valign": "middle" },
    { "id": "rule_name", "type": "line", "x": 361, "y": 336, "w": 400, "stroke": "#C7A26B", "strokeWidth": 2 },
    { "id": "body", "type": "text", "x": 131, "y": 368, "w": 860, "h": 130, "text": "قدّم جهوداً متميزة وأداءً مشرفاً يستحق التقدير والثناء، سائلين الله له دوام التوفيق والسداد.", "font": "plex", "size": 19, "color": "#374151", "align": "center", "lineHeight": 1.9, "maxLines": 4 },
    { "id": "date", "type": "text", "x": 703, "y": 590, "w": 330, "h": 28, "text": "التاريخ: {{التاريخ}}", "font": "plex", "size": 16, "color": "#1B2539", "align": "center" },
    { "id": "sign_line_right", "type": "line", "x": 763, "y": 650, "w": 250, "stroke": "#1B2539", "strokeWidth": 1 },
    { "id": "sign_label_right", "type": "text", "x": 763, "y": 656, "w": 250, "h": 24, "text": "المدير التنفيذي — {{الجهة_المانحة}}", "font": "plex", "size": 13, "color": "#6B7280", "align": "center" },
    { "id": "sign_line_left", "type": "line", "x": 110, "y": 650, "w": 250, "stroke": "#1B2539", "strokeWidth": 1 },
    { "id": "sign_label_left", "type": "text", "x": 110, "y": 656, "w": 250, "h": 24, "text": "التوقيع المعتمد", "font": "plex", "size": 13, "color": "#6B7280", "align": "center" },
    { "id": "seal", "type": "seal", "x": 497, "y": 548, "w": 130, "h": 130, "fill": "#C7A26B", "ring": "#FFFDF8", "star": "#1B2539" },
    { "id": "footer_verify", "type": "text", "x": 60, "y": 722, "w": 420, "h": 22, "text": "للتحقق من صحة الشهادة: {{رقم_الشهادة}}", "font": "plex", "size": 11, "color": "#9CA3AF", "align": "start" },
    { "id": "qr", "type": "qr", "x": 1003, "y": 652, "w": 90, "h": 90, "data": "{{رابط_التحقق}}", "color": "#1B2539", "background": "#FFFDF8" }
  ]
}
''',
  );

  static final PresetTemplate _completion = PresetTemplate(
    id: 'completion_certificate',
    titleAr: 'شهادة إتمام دورة تدريبية',
    descriptionAr: 'إثبات إتمام برنامج تدريبي مع اسم الدورة والمدرب والمدة.',
    collection: TemplateCollection.completion,
    orientation: PageOrientation.landscape,
    tags: <String>['شهادة', 'إتمام', 'دورة', 'تدريب'],
    layoutJson: r'''
{
  "schema_version": 1,
  "paper": "a4",
  "orientation": "landscape",
  "background": "#FFFFFF",
  "canvas": { "width": 1123, "height": 794, "unit": "px" },
  "sample_data": {
    "اسم_المتدرب": "سارة محمد العتيبي",
    "اسم_الدورة": "إدارة المشاريع الاحترافية",
    "المدرب": "د. خالد الحربي",
    "مدة_الدورة": "40 ساعة تدريبية",
    "التاريخ": "١٢ صفر ١٤٤٨هـ",
    "الجهة_المانحة": "الأكاديمية السعودية للتدريب"
  },
  "elements": [
    { "id": "frame_outer", "type": "rect", "x": 30, "y": 30, "w": 1063, "h": 734, "stroke": "#1B2539", "strokeWidth": 1.5, "radius": 8 },
    { "id": "side_band", "type": "rect", "x": 30, "y": 30, "w": 16, "h": 734, "fill": "#C7A26B" },
    { "id": "header_band", "type": "rect", "x": 46, "y": 30, "w": 1047, "h": 120, "fill": "#1B2539" },
    { "id": "title", "type": "text", "x": 46, "y": 58, "w": 1047, "h": 50, "text": "شهادة إتمام دورة تدريبية", "font": "plex", "weight": "bold", "size": 36, "color": "#FFFFFF", "align": "center", "valign": "middle" },
    { "id": "subtitle", "type": "text", "x": 46, "y": 112, "w": 1047, "h": 20, "text": "CERTIFICATE OF COMPLETION", "font": "plex", "size": 11, "color": "#C7A26B", "align": "center", "direction": "ltr", "letterSpacing": 3.2 },
    { "id": "intro", "type": "text", "x": 131, "y": 196, "w": 860, "h": 32, "text": "تشهد {{الجهة_المانحة}} بأن", "font": "plex", "size": 21, "color": "#6B7280", "align": "center" },
    { "id": "recipient", "type": "text", "x": 61, "y": 234, "w": 1000, "h": 78, "text": "{{اسم_المتدرب}}", "font": "plex", "weight": "bold", "size": 42, "color": "#1B2539", "align": "center", "valign": "middle" },
    { "id": "rule_name", "type": "line", "x": 361, "y": 326, "w": 400, "stroke": "#C7A26B", "strokeWidth": 2 },
    { "id": "body", "type": "text", "x": 131, "y": 358, "w": 860, "h": 150, "text": "قد أتمّ بنجاح البرنامج التدريبي «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}، وأظهر التزاماً وتميّزاً في الأداء.", "font": "plex", "size": 19, "color": "#374151", "align": "center", "lineHeight": 1.9, "maxLines": 4 },
    { "id": "date", "type": "text", "x": 703, "y": 600, "w": 330, "h": 28, "text": "التاريخ: {{التاريخ}}", "font": "plex", "size": 16, "color": "#1B2539", "align": "center" },
    { "id": "sign_line", "type": "line", "x": 110, "y": 660, "w": 300, "stroke": "#1B2539", "strokeWidth": 1 },
    { "id": "sign_label", "type": "text", "x": 110, "y": 666, "w": 300, "h": 24, "text": "مدير الأكاديمية", "font": "plex", "size": 13, "color": "#6B7280", "align": "center" },
    { "id": "seal", "type": "seal", "x": 497, "y": 560, "w": 130, "h": 130, "fill": "#1B2539", "ring": "#FFFFFF", "star": "#C7A26B" }
  ]
}
''',
  );

  static final PresetTemplate _excellence = PresetTemplate(
    id: 'excellence_certificate',
    titleAr: 'شهادة تفوق وتميّز',
    descriptionAr: 'تكريم أصحاب المستويات المتقدمة مع إبراز مستوى الأداء.',
    collection: TemplateCollection.excellence,
    orientation: PageOrientation.landscape,
    tags: <String>['شهادة', 'تفوق', 'تميز', 'دراسي'],
    layoutJson: r'''
{
  "schema_version": 1,
  "paper": "a4",
  "orientation": "landscape",
  "background": "#FFFDF8",
  "canvas": { "width": 1123, "height": 794, "unit": "px" },
  "sample_data": {
    "اسم_المتدرب": "ريم عبدالعزيز القحطاني",
    "مستوى_الأداء": "المركز الأول",
    "اسم_الدورة": "الرياضيات المتقدمة",
    "التاريخ": "٢٠ محرم ١٤٤٨هـ",
    "الجهة_المانحة": "مدارس الرواد الأهلية"
  },
  "elements": [
    { "id": "frame_outer", "type": "rect", "x": 34, "y": 34, "w": 1055, "h": 726, "stroke": "#C7A26B", "strokeWidth": 3, "radius": 4 },
    { "id": "frame_inner", "type": "rect", "x": 48, "y": 48, "w": 1027, "h": 698, "stroke": "#C7A26B", "strokeWidth": 1, "radius": 4 },
    { "id": "medal", "type": "seal", "x": 496, "y": 78, "w": 130, "h": 130, "fill": "#C7A26B", "ring": "#FFFDF8", "star": "#1B2539" },
    { "id": "title", "type": "text", "x": 148, "y": 224, "w": 826, "h": 56, "text": "شهادة تفوق وتميّز", "font": "plex", "weight": "bold", "size": 40, "color": "#1B2539", "align": "center", "valign": "middle" },
    { "id": "subtitle", "type": "text", "x": 148, "y": 280, "w": 826, "h": 20, "text": "CERTIFICATE OF EXCELLENCE", "font": "plex", "size": 11, "color": "#C7A26B", "align": "center", "direction": "ltr", "letterSpacing": 3.2 },
    { "id": "rule", "type": "line", "x": 461, "y": 322, "w": 200, "stroke": "#C7A26B", "strokeWidth": 3 },
    { "id": "recipient", "type": "text", "x": 61, "y": 348, "w": 1000, "h": 78, "text": "{{اسم_المتدرب}}", "font": "plex", "weight": "bold", "size": 42, "color": "#1B2539", "align": "center", "valign": "middle" },
    { "id": "body", "type": "text", "x": 131, "y": 440, "w": 860, "h": 120, "text": "لتحقيقه {{مستوى_الأداء}} في {{اسم_الدورة}}، تقديراً لما أبداه من اجتهاد وتفوّق وحرص على التعلّم.", "font": "plex", "size": 19, "color": "#374151", "align": "center", "lineHeight": 1.9, "maxLines": 4 },
    { "id": "date", "type": "text", "x": 397, "y": 588, "w": 330, "h": 28, "text": "{{الجهة_المانحة}} — {{التاريخ}}", "font": "plex", "size": 16, "color": "#1B2539", "align": "center" },
    { "id": "sign_line", "type": "line", "x": 412, "y": 668, "w": 300, "stroke": "#1B2539", "strokeWidth": 1 },
    { "id": "sign_label", "type": "text", "x": 412, "y": 674, "w": 300, "h": 24, "text": "مدير المدرسة", "font": "plex", "size": 13, "color": "#6B7280", "align": "center" }
  ]
}
''',
  );

  // ==========================================================================
  //                              الإفادات (رأسية)
  // ==========================================================================

  static final PresetTemplate _experienceDeclaration = PresetTemplate(
    id: 'experience_declaration',
    titleAr: 'إفادة خبرة',
    descriptionAr: 'خطاب رسمي يوثّق مدة الخبرة والمسمى الوظيفي لموظف.',
    collection: TemplateCollection.experience,
    orientation: PageOrientation.portrait,
    tags: <String>['إفادة', 'خبرة', 'توظيف', 'خطاب'],
    layoutJson: r'''
{
  "schema_version": 1,
  "paper": "a4",
  "orientation": "portrait",
  "background": "#FFFFFF",
  "canvas": { "width": 794, "height": 1123, "unit": "px" },
  "sample_data": {
    "اسم_المنشأة": "شركة جود للتجارة",
    "اسم_الطرف_الثاني": "محمد سعيد الغامدي",
    "تاريخ_البداية": "١ محرم ١٤٤٠هـ",
    "تاريخ_النهاية": "١ محرم ١٤٤٨هـ",
    "التاريخ": "١٥ محرم ١٤٤٨هـ"
  },
  "elements": [
    { "id": "frame", "type": "rect", "x": 28, "y": 28, "w": 738, "h": 1067, "stroke": "#1B2539", "strokeWidth": 1.2, "radius": 4 },
    { "id": "header_band", "type": "rect", "x": 28, "y": 28, "w": 738, "h": 96, "fill": "#1B2539", "radius": 4 },
    { "id": "company", "type": "text", "x": 28, "y": 48, "w": 738, "h": 30, "text": "{{اسم_المنشأة}}", "font": "plex", "weight": "bold", "size": 22, "color": "#FFFFFF", "align": "center" },
    { "id": "title", "type": "text", "x": 28, "y": 80, "w": 738, "h": 30, "text": "إفادة خبرة", "font": "plex", "size": 16, "color": "#C7A26B", "align": "center" },
    { "id": "ref", "type": "text", "x": 60, "y": 150, "w": 674, "h": 26, "text": "التاريخ: {{التاريخ}}", "font": "plex", "size": 15, "color": "#6B7280", "align": "start" },
    { "id": "salutation", "type": "text", "x": 60, "y": 200, "w": 674, "h": 30, "text": "إلى من يهمه الأمر،", "font": "plex", "weight": "bold", "size": 18, "color": "#1B2539", "align": "start" },
    { "id": "body_1", "type": "text", "x": 60, "y": 246, "w": 674, "h": 130, "text": "نشهد بأن السيد/ {{اسم_الطرف_الثاني}} قد عمل لدى {{اسم_المنشأة}} خلال الفترة من {{تاريخ_البداية}} إلى {{تاريخ_النهاية}}، وقد اتّسم خلالها بالكفاءة والانضباط والالتزام بأداء المهام الموكلة إليه على أكمل وجه.", "font": "plex", "size": 17.5, "color": "#374151", "align": "justify", "lineHeight": 2, "maxLines": 5 },
    { "id": "body_2", "type": "text", "x": 60, "y": 392, "w": 674, "h": 90, "text": "وقد أُعطيت له هذه الإفادة بناءً على طلبه لتقديمها إلى الجهات المختصة عند الحاجة، دون أدنى مسؤولية على المنشأة.", "font": "plex", "size": 17.5, "color": "#374151", "align": "justify", "lineHeight": 2, "maxLines": 4 },
    { "id": "closing", "type": "text", "x": 60, "y": 512, "w": 674, "h": 30, "text": "وتفضلوا بقبول فائق الاحترام والتقدير.", "font": "plex", "size": 17.5, "color": "#374151", "align": "start" },
    { "id": "seal", "type": "seal", "x": 337, "y": 700, "w": 120, "h": 120, "fill": "#C7A26B", "ring": "#FFFFFF", "star": "#1B2539" },
    { "id": "sign_line", "type": "line", "x": 400, "y": 872, "w": 334, "stroke": "#1B2539", "strokeWidth": 1 },
    { "id": "sign_label", "type": "text", "x": 400, "y": 878, "w": 334, "h": 26, "text": "المدير التنفيذي — {{اسم_المنشأة}}", "font": "plex", "size": 14, "color": "#6B7280", "align": "center" },
    { "id": "footer", "type": "text", "x": 60, "y": 1050, "w": 674, "h": 24, "text": "صدرت هذه الإفادة إلكترونياً عبر منصة جودكرافت.", "font": "plex", "size": 12, "color": "#9CA3AF", "align": "center" }
  ]
}
''',
  );

  // ==========================================================================
  //                              العقود (رأسية)
  // ==========================================================================

  static final PresetTemplate _employmentContract = PresetTemplate(
    id: 'employment_contract',
    titleAr: 'عقد عمل',
    descriptionAr: 'عقد توظيف رأسـي يتضمن الطرفين والمدة والمقابل المالي.',
    collection: TemplateCollection.employmentContract,
    orientation: PageOrientation.portrait,
    tags: <String>['عقد', 'عمل', 'توظيف', 'راتب'],
    layoutJson: r'''
{
  "schema_version": 1,
  "paper": "a4",
  "orientation": "portrait",
  "background": "#FFFFFF",
  "canvas": { "width": 794, "height": 1123, "unit": "px" },
  "sample_data": {
    "اسم_المنشأة": "مؤسسة الأفق للمقاولات",
    "اسم_الطرف_الثاني": "عمر ناصر الدوسري",
    "رقم_العقد": "JC-HR-2026-0142",
    "تاريخ_البداية": "١ صفر ١٤٤٨هـ",
    "تاريخ_النهاية": "١ صفر ١٤٤٩هـ",
    "قيمة_العقد": "ثمانية آلاف ريال شهرياً",
    "طريقة_الدفع": "تُصرف الأجرة في نهاية كل شهر ميلادي عبر التحويل البنكي."
  },
  "elements": [
    { "id": "frame", "type": "rect", "x": 28, "y": 28, "w": 738, "h": 1067, "stroke": "#1B2539", "strokeWidth": 1.4, "radius": 6 },
    { "id": "header_band", "type": "rect", "x": 28, "y": 28, "w": 738, "h": 92, "fill": "#1B2539", "radius": 6 },
    { "id": "title", "type": "text", "x": 28, "y": 50, "w": 738, "h": 42, "text": "عقد عمل", "font": "amiri", "weight": "bold", "size": 30, "color": "#FFFFFF", "align": "center", "valign": "middle" },
    { "id": "contract_no", "type": "text", "x": 60, "y": 140, "w": 674, "h": 24, "text": "الرقم المرجعي: {{رقم_العقد}}", "font": "amiri", "size": 15, "color": "#6B7280", "align": "start" },
    { "id": "preamble", "type": "text", "x": 60, "y": 178, "w": 674, "h": 32, "text": "إنه في يوم {{تاريخ_البداية}}، تم الاتفاق بين كل من:", "font": "amiri", "size": 18, "color": "#1B2539", "align": "start", "lineHeight": 1.9 },
    { "id": "party_1", "type": "text", "x": 60, "y": 220, "w": 674, "h": 32, "text": "الطرف الأول (صاحب العمل): {{اسم_المنشأة}}", "font": "amiri", "weight": "bold", "size": 18, "color": "#1B2539", "align": "start", "lineHeight": 1.9 },
    { "id": "party_2", "type": "text", "x": 60, "y": 258, "w": 674, "h": 32, "text": "الطرف الثاني (العامل): {{اسم_الطرف_الثاني}}", "font": "amiri", "weight": "bold", "size": 18, "color": "#1B2539", "align": "start", "lineHeight": 1.9 },
    { "id": "sep_1", "type": "line", "x": 60, "y": 310, "w": 674, "stroke": "#E5E7EB", "strokeWidth": 1 },
    { "id": "clause_1_title", "type": "text", "x": 60, "y": 326, "w": 674, "h": 30, "text": "البند الأول: المدة", "font": "amiri", "weight": "bold", "size": 19, "color": "#1B2539", "align": "start" },
    { "id": "clause_1_body", "type": "text", "x": 60, "y": 360, "w": 674, "h": 60, "text": "تبدأ مدة هذا العقد من تاريخ {{تاريخ_البداية}} وتنتهي في {{تاريخ_النهاية}}، ويجوز تجديده باتفاق كتابي بين الطرفين.", "font": "amiri", "size": 17, "color": "#374151", "align": "justify", "lineHeight": 2, "maxLines": 3 },
    { "id": "clause_2_title", "type": "text", "x": 60, "y": 446, "w": 674, "h": 30, "text": "البند الثاني: الأجر", "font": "amiri", "weight": "bold", "size": 19, "color": "#1B2539", "align": "start" },
    { "id": "clause_2_body", "type": "text", "x": 60, "y": 480, "w": 674, "h": 80, "text": "يستحق الطرف الثاني أجراً وقدره {{قيمة_العقد}}. و{{طريقة_الدفع}}", "font": "amiri", "size": 17, "color": "#374151", "align": "justify", "lineHeight": 2, "maxLines": 4 },
    { "id": "clause_3_title", "type": "text", "x": 60, "y": 586, "w": 674, "h": 30, "text": "البند الثالث: الأحكام العامة", "font": "amiri", "weight": "bold", "size": 19, "color": "#1B2539", "align": "start" },
    { "id": "clause_3_body", "type": "text", "x": 60, "y": 620, "w": 674, "h": 80, "text": "يخضع هذا العقد لأنظمة العمل السارية في المملكة العربية السعودية، وأي نزاع ينشأ عنه يُحال إلى الجهة المختصة.", "font": "amiri", "size": 17, "color": "#374151", "align": "justify", "lineHeight": 2, "maxLines": 3 },
    { "id": "seal", "type": "seal", "x": 337, "y": 740, "w": 120, "h": 120, "fill": "#1B2539", "ring": "#FFFFFF", "star": "#C7A26B" },
    { "id": "sign_line_1", "type": "line", "x": 60, "y": 900, "w": 250, "stroke": "#1B2539", "strokeWidth": 1 },
    { "id": "sign_label_1", "type": "text", "x": 60, "y": 906, "w": 250, "h": 26, "text": "الطرف الأول", "font": "amiri", "size": 15, "color": "#6B7280", "align": "center" },
    { "id": "sign_line_2", "type": "line", "x": 484, "y": 900, "w": 250, "stroke": "#1B2539", "strokeWidth": 1 },
    { "id": "sign_label_2", "type": "text", "x": 484, "y": 906, "w": 250, "h": 26, "text": "الطرف الثاني", "font": "amiri", "size": 15, "color": "#6B7280", "align": "center" },
    { "id": "footer", "type": "text", "x": 60, "y": 1050, "w": 674, "h": 24, "text": "حُرّر هذا العقد إلكترونياً عبر منصة جودكرافت.", "font": "amiri", "size": 13, "color": "#9CA3AF", "align": "center" }
  ]
}
''',
  );

  static final PresetTemplate _serviceContract = PresetTemplate(
    id: 'service_contract',
    titleAr: 'عقد تقديم خدمات',
    descriptionAr: 'عقد خدمات رأسـي يشمل نطاق العمل والمقابل وطريقة السداد.',
    collection: TemplateCollection.serviceContract,
    orientation: PageOrientation.portrait,
    tags: <String>['عقد', 'خدمات', 'اتفاقية', 'مقاولات'],
    layoutJson: r'''
{
  "schema_version": 1,
  "paper": "a4",
  "orientation": "portrait",
  "background": "#FFFFFF",
  "canvas": { "width": 794, "height": 1123, "unit": "px" },
  "sample_data": {
    "اسم_الطرف_الأول": "شركة جود للتجارة",
    "اسم_الطرف_الثاني": "مؤسسة الأفق للمقاولات",
    "رقم_العقد": "JC-C-2026-0044",
    "تاريخ_العقد": "١٥ محرم ١٤٤٨هـ",
    "قيمة_العقد": "مبلغ وقدره خمسون ألف ريال",
    "طريقة_الدفع": "يُسدَّد على ثلاث دفعات متساوية وفق الجدول الزمني المرفق."
  },
  "elements": [
    { "id": "frame", "type": "rect", "x": 28, "y": 28, "w": 738, "h": 1067, "stroke": "#1B2539", "strokeWidth": 1.4, "radius": 6 },
    { "id": "header_band", "type": "rect", "x": 28, "y": 28, "w": 738, "h": 92, "fill": "#1B2539", "radius": 6 },
    { "id": "title", "type": "text", "x": 28, "y": 50, "w": 738, "h": 42, "text": "عقد تقديم خدمات", "font": "amiri", "weight": "bold", "size": 30, "color": "#FFFFFF", "align": "center", "valign": "middle" },
    { "id": "contract_no", "type": "text", "x": 60, "y": 140, "w": 674, "h": 24, "text": "الرقم المرجعي: {{رقم_العقد}}", "font": "amiri", "size": 15, "color": "#6B7280", "align": "start" },
    { "id": "preamble", "type": "text", "x": 60, "y": 178, "w": 674, "h": 32, "text": "إنه في يوم {{تاريخ_العقد}}، تم الاتفاق بين كل من:", "font": "amiri", "size": 18, "color": "#1B2539", "align": "start", "lineHeight": 1.9 },
    { "id": "party_1", "type": "text", "x": 60, "y": 220, "w": 674, "h": 32, "text": "الطرف الأول: {{اسم_الطرف_الأول}}", "font": "amiri", "weight": "bold", "size": 18, "color": "#1B2539", "align": "start", "lineHeight": 1.9 },
    { "id": "party_2", "type": "text", "x": 60, "y": 258, "w": 674, "h": 32, "text": "الطرف الثاني: {{اسم_الطرف_الثاني}}", "font": "amiri", "weight": "bold", "size": 18, "color": "#1B2539", "align": "start", "lineHeight": 1.9 },
    { "id": "sep_1", "type": "line", "x": 60, "y": 310, "w": 674, "stroke": "#E5E7EB", "strokeWidth": 1 },
    { "id": "clause_1_title", "type": "text", "x": 60, "y": 326, "w": 674, "h": 30, "text": "البند الأول: نطاق العمل", "font": "amiri", "weight": "bold", "size": 19, "color": "#1B2539", "align": "start" },
    { "id": "clause_1_body", "type": "text", "x": 60, "y": 360, "w": 674, "h": 100, "text": "يلتزم الطرف الثاني بتقديم الخدمات المتفق عليها وفق المواصفات والشروط الواردة في الملحق الفني لهذا العقد.", "font": "amiri", "size": 17, "color": "#374151", "align": "justify", "lineHeight": 2, "maxLines": 4 },
    { "id": "clause_2_title", "type": "text", "x": 60, "y": 480, "w": 674, "h": 30, "text": "البند الثاني: المقابل المالي", "font": "amiri", "weight": "bold", "size": 19, "color": "#1B2539", "align": "start" },
    { "id": "clause_2_body", "type": "text", "x": 60, "y": 514, "w": 674, "h": 80, "text": "يستحق الطرف الثاني مقابل خدماته {{قيمة_العقد}}. و{{طريقة_الدفع}}", "font": "amiri", "size": 17, "color": "#374151", "align": "justify", "lineHeight": 2, "maxLines": 4 },
    { "id": "clause_3_title", "type": "text", "x": 60, "y": 620, "w": 674, "h": 30, "text": "البند الثالث: الأحكام العامة", "font": "amiri", "weight": "bold", "size": 19, "color": "#1B2539", "align": "start" },
    { "id": "clause_3_body", "type": "text", "x": 60, "y": 654, "w": 674, "h": 80, "text": "يخضع هذا العقد لأنظمة المملكة العربية السعودية، وأي نزاع ينشأ عنه يُحال إلى الجهة القضائية المختصة.", "font": "amiri", "size": 17, "color": "#374151", "align": "justify", "lineHeight": 2, "maxLines": 3 },
    { "id": "seal", "type": "seal", "x": 337, "y": 790, "w": 120, "h": 120, "fill": "#C7A26B", "ring": "#FFFFFF", "star": "#1B2539" },
    { "id": "sign_line_1", "type": "line", "x": 60, "y": 940, "w": 250, "stroke": "#1B2539", "strokeWidth": 1 },
    { "id": "sign_label_1", "type": "text", "x": 60, "y": 946, "w": 250, "h": 26, "text": "الطرف الأول", "font": "amiri", "size": 15, "color": "#6B7280", "align": "center" },
    { "id": "sign_line_2", "type": "line", "x": 484, "y": 940, "w": 250, "stroke": "#1B2539", "strokeWidth": 1 },
    { "id": "sign_label_2", "type": "text", "x": 484, "y": 946, "w": 250, "h": 26, "text": "الطرف الثاني", "font": "amiri", "size": 15, "color": "#6B7280", "align": "center" },
    { "id": "footer", "type": "text", "x": 60, "y": 1050, "w": 674, "h": 24, "text": "حُرّر هذا العقد إلكترونياً عبر منصة جودكرافت بتاريخ {{تاريخ_العقد}}", "font": "amiri", "size": 13, "color": "#9CA3AF", "align": "center" }
  ]
}
''',
  );

  // ==========================================================================
  //                 حزمة التوسعة — باليتات عصرية متنوّعة
  //
  // كل قالب هنا يعيد استخدام مفاتيح `DynamicFields` العربية نفسها (لا مفاتيح
  // جديدة) حتى يعمل الربط التلقائي مع Excel كما هو بلا تعديل. وكل حمولة
  // تستخدم مقاس لوح مطابق تماماً لمقاس الورق (1123×794 / 794×1123) فتبقى
  // الإزاحات `offsetX`/`offsetY` صفراً ⇒ نفس كسر المحرر في الـ PDF دون ترحّل.
  // ==========================================================================

  /// كحلي فاخر مع ذهبي — خلفية داكنة كاملة وأطراف ذهبية مزدوجة.
  static final PresetTemplate _classicAppreciation = PresetTemplate(
    id: 'classic_appreciation_certificate',
    titleAr: 'شهادة تقدير كلاسيكية',
    descriptionAr: 'قالب كحلي فاخر بإطار ذهبي وخلفية داكنة لإكرام المتميزين.',
    collection: TemplateCollection.appreciation,
    orientation: PageOrientation.landscape,
    tags: <String>['شهادة', 'تقدير', 'كلاسيكي', 'فاخر', 'ذهبي'],
    layoutJson: r'''
{
  "schema_version": 1,
  "paper": "a4",
  "orientation": "landscape",
  "background": "#12294A",
  "canvas": { "width": 1123, "height": 794, "unit": "px" },
  "sample_data": {
    "اسم_المتدرب": "منيرة سعد القرني",
    "الجهة_المانحة": "الأكاديمية الوطنية للتطوير",
    "التاريخ": "٣ رجب ١٤٤٨هـ",
    "رقم_الشهادة": "JC-2026-0187",
    "رابط_التحقق": "https://joodcraft.app/v/JC-2026-0187"
  },
  "elements": [
    { "id": "frame_outer", "type": "rect", "x": 24, "y": 24, "w": 1075, "h": 746, "stroke": "#C9A227", "strokeWidth": 3, "radius": 14 },
    { "id": "frame_inner", "type": "rect", "x": 40, "y": 40, "w": 1043, "h": 714, "stroke": "#C9A227", "strokeWidth": 1, "radius": 8 },
    { "id": "title", "type": "text", "x": 60, "y": 66, "w": 1003, "h": 58, "text": "شهادة تقدير كلاسيكية", "font": "plex", "weight": "bold", "size": 40, "color": "#F4E3B2", "align": "center", "valign": "middle" },
    { "id": "subtitle", "type": "text", "x": 60, "y": 126, "w": 1003, "h": 22, "text": "CERTIFICATE OF APPRECIATION", "font": "plex", "size": 12, "color": "#C9A227", "align": "center", "direction": "ltr", "letterSpacing": 3.4 },
    { "id": "rule_top", "type": "rect", "x": 461, "y": 172, "w": 201, "h": 4, "fill": "#C9A227", "radius": 2 },
    { "id": "intro", "type": "text", "x": 111, "y": 198, "w": 901, "h": 34, "text": "تشهد {{الجهة_المانحة}} بأن", "font": "plex", "size": 21, "color": "#D7E1EE", "align": "center" },
    { "id": "recipient", "type": "text", "x": 61, "y": 234, "w": 1001, "h": 112, "text": "{{اسم_المتدرب}}", "font": "plex", "weight": "bold", "size": 42, "color": "#FFFFFF", "align": "center", "valign": "middle", "lineHeight": 1.25, "maxLines": 2 },
    { "id": "rule_name", "type": "rect", "x": 361, "y": 358, "w": 401, "h": 2, "fill": "#C9A227" },
    { "id": "body", "type": "text", "x": 131, "y": 384, "w": 861, "h": 132, "text": "تقديرًا لجهوده المتميزة وأدائه البارز الذي يليق بقيمنا، واحتفاله قدوةً في الإتقان والالتزام، متمنين له دوام التوفيق.", "font": "plex", "size": 19, "color": "#E4EBF4", "align": "center", "lineHeight": 1.9, "maxLines": 4 },
    { "id": "date", "type": "text", "x": 361, "y": 552, "w": 401, "h": 30, "text": "التاريخ: {{التاريخ}}", "font": "plex", "size": 16, "color": "#F4E3B2", "align": "center" },
    { "id": "seal", "type": "seal", "x": 497, "y": 596, "w": 112, "h": 112, "fill": "#C9A227", "ring": "#12294A", "star": "#12294A" },
    { "id": "sign_line_left", "type": "line", "x": 110, "y": 664, "w": 250, "stroke": "#C9A227", "strokeWidth": 1 },
    { "id": "sign_label_left", "type": "text", "x": 110, "y": 670, "w": 250, "h": 26, "text": "التوقيع المعتمد", "font": "plex", "size": 13, "color": "#C8D4E4", "align": "center" },
    { "id": "sign_line_right", "type": "line", "x": 763, "y": 664, "w": 250, "stroke": "#C9A227", "strokeWidth": 1 },
    { "id": "sign_label_right", "type": "text", "x": 763, "y": 670, "w": 250, "h": 26, "text": "مدير البرنامج — {{الجهة_المانحة}}", "font": "plex", "size": 13, "color": "#C8D4E4", "align": "center" },
    { "id": "footer", "type": "text", "x": 60, "y": 724, "w": 700, "h": 22, "text": "للتحقق من صحة الشهادة: {{رقم_الشهادة}}", "font": "plex", "size": 11, "color": "#8FA3BC", "align": "start" },
    { "id": "qr", "type": "qr", "x": 990, "y": 646, "w": 88, "h": 88, "data": "{{رابط_التحقق}}", "color": "#F4E3B2", "background": "#12294A" }
  ]
}
''',
  );

  /// عنابي كلاسيكي مع ذهبي — شريط علوي عنواني وخط نسخ تقليدي.
  static final PresetTemplate _achievementCertificate = PresetTemplate(
    id: 'achievement_certificate',
    titleAr: 'شهادة إنجاز بارز',
    descriptionAr: 'قالب عنابي كلاسيكي بخط نسخ لتكريم أصحاب الإنجاز البارز.',
    collection: TemplateCollection.excellence,
    orientation: PageOrientation.landscape,
    tags: <String>['شهادة', 'إنجاز', 'عنابي', 'كلاسيكي', 'تكريم'],
    layoutJson: r'''
{
  "schema_version": 1,
  "paper": "a4",
  "orientation": "landscape",
  "background": "#FCF7F0",
  "canvas": { "width": 1123, "height": 794, "unit": "px" },
  "sample_data": {
    "اسم_المتدرب": "عبدالعزيز فهد الشهري",
    "مستوى_الأداء": "المركز الأول",
    "اسم_الدورة": "التصميم الداخلي المتقدم",
    "التاريخ": "٢٥ رجب ١٤٤٨هـ",
    "الجهة_المانحة": "بيت الخبرة للتطوير"
  },
  "elements": [
    { "id": "header_band", "type": "rect", "x": 24, "y": 24, "w": 1075, "h": 150, "fill": "#6B1E2E", "radius": 12 },
    { "id": "frame", "type": "rect", "x": 24, "y": 24, "w": 1075, "h": 746, "stroke": "#6B1E2E", "strokeWidth": 3, "radius": 12 },
    { "id": "frame_inner", "type": "rect", "x": 44, "y": 44, "w": 1035, "h": 706, "stroke": "#D4A857", "strokeWidth": 1, "radius": 6 },
    { "id": "title", "type": "text", "x": 64, "y": 56, "w": 995, "h": 56, "text": "شهادة إنجاز بارز", "font": "amiri", "weight": "bold", "size": 40, "color": "#FFFFFF", "align": "center", "valign": "middle" },
    { "id": "subtitle", "type": "text", "x": 64, "y": 118, "w": 995, "h": 24, "text": "CERTIFICATE OF ACHIEVEMENT", "font": "plex", "size": 12, "color": "#E7C9A0", "align": "center", "direction": "ltr", "letterSpacing": 3.4 },
    { "id": "rule_top", "type": "rect", "x": 461, "y": 196, "w": 201, "h": 4, "fill": "#D4A857", "radius": 2 },
    { "id": "intro", "type": "text", "x": 111, "y": 224, "w": 901, "h": 34, "text": "يُكرَّم المتدرب", "font": "amiri", "size": 21, "color": "#7A5A60", "align": "center" },
    { "id": "recipient", "type": "text", "x": 61, "y": 264, "w": 1001, "h": 112, "text": "{{اسم_المتدرب}}", "font": "amiri", "weight": "bold", "size": 44, "color": "#6B1E2E", "align": "center", "valign": "middle", "lineHeight": 1.25, "maxLines": 2 },
    { "id": "rule_name", "type": "rect", "x": 361, "y": 392, "w": 401, "h": 2, "fill": "#D4A857" },
    { "id": "body", "type": "text", "x": 131, "y": 420, "w": 861, "h": 140, "text": "لحصوله على {{مستوى_الأداء}} في {{اسم_الدورة}}، تقديرًا لتفوقه واجتهاده المستمر وحرصه على التميّز.", "font": "amiri", "size": 20, "color": "#4A3A40", "align": "center", "lineHeight": 1.9, "maxLines": 4 },
    { "id": "date", "type": "text", "x": 361, "y": 578, "w": 401, "h": 30, "text": "{{الجهة_المانحة}} — {{التاريخ}}", "font": "plex", "size": 16, "color": "#6B1E2E", "align": "center" },
    { "id": "seal", "type": "seal", "x": 497, "y": 610, "w": 112, "h": 112, "fill": "#6B1E2E", "ring": "#FCF7F0", "star": "#D4A857" },
    { "id": "sign_line_left", "type": "line", "x": 110, "y": 668, "w": 250, "stroke": "#6B1E2E", "strokeWidth": 1 },
    { "id": "sign_label_left", "type": "text", "x": 110, "y": 674, "w": 250, "h": 26, "text": "التوقيع المعتمد", "font": "plex", "size": 13, "color": "#7A5A60", "align": "center" },
    { "id": "sign_line_right", "type": "line", "x": 763, "y": 668, "w": 250, "stroke": "#6B1E2E", "strokeWidth": 1 },
    { "id": "sign_label_right", "type": "text", "x": 763, "y": 674, "w": 250, "h": 26, "text": "مدير التحكيم", "font": "plex", "size": 13, "color": "#7A5A60", "align": "center" },
    { "id": "footer", "type": "text", "x": 64, "y": 736, "w": 995, "h": 22, "text": "حُرّرت هذه الشهادة إلكترونياً عبر منصة جودكرافت.", "font": "plex", "size": 11, "color": "#A08A8F", "align": "center" }
  ]
}
''',
  );

  /// زيتي ورمادي معاصر — تصميم مينيمال بشريط جانبي وخط Tajawal الهندسي.
  static final PresetTemplate _attendanceCertificate = PresetTemplate(
    id: 'attendance_certificate',
    titleAr: 'شهادة حضور وتدريب',
    descriptionAr: 'قالب مينيمال زيتي ورمادي لإثبات حضور البرنامج التدريبي.',
    collection: TemplateCollection.completion,
    orientation: PageOrientation.landscape,
    tags: <String>['شهادة', 'حضور', 'تدريب', 'مينيمال', 'عصري'],
    layoutJson: r'''
{
  "schema_version": 1,
  "paper": "a4",
  "orientation": "landscape",
  "background": "#F7F6F1",
  "canvas": { "width": 1123, "height": 794, "unit": "px" },
  "sample_data": {
    "اسم_المتدرب": "ريما عبدالله السبيعي",
    "اسم_الدورة": "أساسيات إدارة الوقت",
    "المدرب": "أ. هند القحطاني",
    "مدة_الدورة": "12 ساعة تدريبية",
    "التاريخ": "٨ رجب ١٤٤٨هـ",
    "الجهة_المانحة": "مركز الإتقان للتدريب",
    "رقم_الشهادة": "JC-2026-0233"
  },
  "elements": [
    { "id": "side_band", "type": "rect", "x": 0, "y": 0, "w": 26, "h": 794, "fill": "#4B5D2A" },
    { "id": "frame", "type": "rect", "x": 54, "y": 40, "w": 1025, "h": 714, "stroke": "#C6C2B4", "strokeWidth": 1.5, "radius": 4 },
    { "id": "title", "type": "text", "x": 62, "y": 92, "w": 1001, "h": 60, "text": "شهادة حضور وتدريب", "font": "tajawal", "weight": "bold", "size": 40, "color": "#3E4A22", "align": "center", "valign": "middle" },
    { "id": "subtitle", "type": "text", "x": 62, "y": 154, "w": 1001, "h": 22, "text": "CERTIFICATE OF ATTENDANCE", "font": "tajawal", "size": 12, "color": "#7A8467", "align": "center", "direction": "ltr", "letterSpacing": 3.4 },
    { "id": "accent_top", "type": "rect", "x": 54, "y": 208, "w": 1025, "h": 3, "fill": "#4B5D2A" },
    { "id": "intro", "type": "text", "x": 111, "y": 236, "w": 901, "h": 34, "text": "تشهد {{الجهة_المانحة}} بأن", "font": "tajawal", "size": 21, "color": "#5F5B54", "align": "center" },
    { "id": "recipient", "type": "text", "x": 61, "y": 278, "w": 1001, "h": 112, "text": "{{اسم_المتدرب}}", "font": "tajawal", "weight": "bold", "size": 44, "color": "#3E4A22", "align": "center", "valign": "middle", "lineHeight": 1.25, "maxLines": 2 },
    { "id": "rule_name", "type": "rect", "x": 411, "y": 408, "w": 301, "h": 4, "fill": "#4B5D2A", "radius": 2 },
    { "id": "body", "type": "text", "x": 131, "y": 438, "w": 861, "h": 136, "text": "قد حضر واجتاز البرنامج التدريبي «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}، مُظهرًا التزاماً وانضباطاً ممتازاً.", "font": "tajawal", "size": 19, "color": "#4B4740", "align": "center", "lineHeight": 1.9, "maxLines": 4 },
    { "id": "date", "type": "text", "x": 361, "y": 592, "w": 401, "h": 30, "text": "التاريخ: {{التاريخ}}", "font": "tajawal", "size": 16, "color": "#5F5B54", "align": "center" },
    { "id": "verify", "type": "text", "x": 361, "y": 624, "w": 401, "h": 24, "text": "رقم الشهادة: {{رقم_الشهادة}}", "font": "tajawal", "size": 12, "color": "#7A8467", "align": "center" },
    { "id": "seal", "type": "seal", "x": 497, "y": 652, "w": 100, "h": 100, "fill": "#4B5D2A", "ring": "#F7F6F1", "star": "#F7F6F1" },
    { "id": "sign_line_left", "type": "line", "x": 120, "y": 700, "w": 250, "stroke": "#7A8467", "strokeWidth": 1 },
    { "id": "sign_label_left", "type": "text", "x": 120, "y": 706, "w": 250, "h": 26, "text": "المدرّب المعتمد", "font": "tajawal", "size": 13, "color": "#5F5B54", "align": "center" },
    { "id": "sign_line_right", "type": "line", "x": 753, "y": 700, "w": 250, "stroke": "#7A8467", "strokeWidth": 1 },
    { "id": "sign_label_right", "type": "text", "x": 753, "y": 706, "w": 250, "h": 26, "text": "مدير المركز", "font": "tajawal", "size": 13, "color": "#5F5B54", "align": "center" }
  ]
}
''',
  );

  /// أزرق داكن ساطع وتصميم مودرن — شريط علوي وأشكال هندسية بزوايا لونية.
  static final PresetTemplate _scienceProgressCertificate = PresetTemplate(
    id: 'science_progress_certificate',
    titleAr: 'شهادة تقدّم علمي',
    descriptionAr: 'قالب مودرن بأزرق ساطع وشريط علوي لتكريم التقدّم العلمي.',
    collection: TemplateCollection.excellence,
    orientation: PageOrientation.landscape,
    tags: <String>['شهادة', 'تقدّم', 'علمي', 'مودرن', 'أزرق'],
    layoutJson: r'''
{
  "schema_version": 1,
  "paper": "a4",
  "orientation": "landscape",
  "background": "#FFFFFF",
  "canvas": { "width": 1123, "height": 794, "unit": "px" },
  "sample_data": {
    "اسم_المتدرب": "سلطان ناصر الحارثي",
    "مستوى_الأداء": "ممتاز مع مرتبة الشرف",
    "اسم_الدورة": "هندسة البرمجيات الحديثة",
    "الجهة_المانحة": "معهد التقنيات المتقدمة",
    "التاريخ": "١٢ رجب ١٤٤٨هـ",
    "رقم_الشهادة": "JC-2026-0301"
  },
  "elements": [
    { "id": "top_bar", "type": "rect", "x": 0, "y": 0, "w": 1123, "h": 120, "fill": "#0B1B3A" },
    { "id": "accent_bar", "type": "rect", "x": 0, "y": 120, "w": 1123, "h": 8, "fill": "#1D4ED8" },
    { "id": "title", "type": "text", "x": 60, "y": 32, "w": 1000, "h": 56, "text": "شهادة تقدّم علمي", "font": "cairo", "weight": "bold", "size": 38, "color": "#FFFFFF", "align": "center", "valign": "middle" },
    { "id": "header_seal", "type": "seal", "x": 1016, "y": 14, "w": 92, "h": 92, "fill": "#1D4ED8", "ring": "#0B1B3A", "star": "#FFFFFF" },
    { "id": "subtitle", "type": "text", "x": 60, "y": 150, "w": 1003, "h": 22, "text": "CERTIFICATE OF PROGRESS", "font": "cairo", "size": 12, "color": "#1D4ED8", "align": "center", "direction": "ltr", "letterSpacing": 3.4 },
    { "id": "corner_left", "type": "rect", "x": 44, "y": 640, "w": 60, "h": 60, "fill": "#EFF6FF", "radius": 14 },
    { "id": "corner_right", "type": "rect", "x": 1019, "y": 640, "w": 60, "h": 60, "fill": "#EFF6FF", "radius": 14 },
    { "id": "intro", "type": "text", "x": 111, "y": 212, "w": 901, "h": 34, "text": "يتقدّم المعهد بالتهنئة إلى", "font": "cairo", "size": 21, "color": "#64748B", "align": "center" },
    { "id": "recipient", "type": "text", "x": 61, "y": 254, "w": 1001, "h": 116, "text": "{{اسم_المتدرب}}", "font": "cairo", "weight": "bold", "size": 46, "color": "#0B1B3A", "align": "center", "valign": "middle", "lineHeight": 1.25, "maxLines": 2 },
    { "id": "rule_name", "type": "rect", "x": 461, "y": 390, "w": 201, "h": 4, "fill": "#1D4ED8", "radius": 2 },
    { "id": "body", "type": "text", "x": 131, "y": 422, "w": 861, "h": 148, "text": "قد أتمّ برنامج «{{اسم_الدورة}}» بنجاح وتميّز، ويُكرَّم لحصوله على {{مستوى_الأداء}} حفلاً لعطائه العلمي المتميّز.", "font": "cairo", "size": 19, "color": "#334155", "align": "center", "lineHeight": 1.9, "maxLines": 4 },
    { "id": "badge", "type": "rect", "x": 361, "y": 596, "w": 401, "h": 46, "fill": "#EFF6FF", "stroke": "#1D4ED8", "strokeWidth": 1.5, "radius": 23 },
    { "id": "badge_text", "type": "text", "x": 361, "y": 604, "w": 401, "h": 30, "text": "{{الجهة_المانحة}}", "font": "cairo", "weight": "bold", "size": 18, "color": "#1D4ED8", "align": "center", "valign": "middle", "maxLines": 1 },
    { "id": "date", "type": "text", "x": 361, "y": 660, "w": 401, "h": 30, "text": "التاريخ: {{التاريخ}}", "font": "cairo", "size": 16, "color": "#64748B", "align": "center" },
    { "id": "sign_line_left", "type": "line", "x": 110, "y": 728, "w": 250, "stroke": "#0B1B3A", "strokeWidth": 1 },
    { "id": "sign_label_left", "type": "text", "x": 110, "y": 734, "w": 250, "h": 26, "text": "التوقيع المعتمد", "font": "cairo", "size": 13, "color": "#64748B", "align": "center" },
    { "id": "sign_line_right", "type": "line", "x": 763, "y": 728, "w": 250, "stroke": "#0B1B3A", "strokeWidth": 1 },
    { "id": "sign_label_right", "type": "text", "x": 763, "y": 734, "w": 250, "h": 26, "text": "عميد المعهد", "font": "cairo", "size": 13, "color": "#64748B", "align": "center" },
    { "id": "footer", "type": "text", "x": 60, "y": 766, "w": 1003, "h": 22, "text": "رقم الشهادة: {{رقم_الشهادة}}", "font": "cairo", "size": 11, "color": "#94A3B8", "align": "center" }
  ]
}
''',
  );

  /// عقد عمل مؤقت — كحلي مع ذهبي على خلفية فاتحة هادئة.
  static final PresetTemplate _fixedTermContract = PresetTemplate(
    id: 'fixed_term_contract',
    titleAr: 'عقد عمل مؤقت',
    descriptionAr: 'عقد توظيف بفترة محددة مع الأجر وطريقة الدفع والأحكام.',
    collection: TemplateCollection.employmentContract,
    orientation: PageOrientation.portrait,
    tags: <String>['عقد', 'عمل', 'مؤقت', 'توظيف', 'كحلي'],
    layoutJson: r'''
{
  "schema_version": 1,
  "paper": "a4",
  "orientation": "portrait",
  "background": "#F5F7FA",
  "canvas": { "width": 794, "height": 1123, "unit": "px" },
  "sample_data": {
    "اسم_المنشأة": "شركة رواد التقنية",
    "اسم_الطرف_الثاني": "فهد سليمان المطيري",
    "رقم_العقد": "JC-TM-2026-0088",
    "تاريخ_البداية": "١ شعبان ١٤٤٨هـ",
    "تاريخ_النهاية": "١ محرم ١٤٤٩هـ",
    "قيمة_العقد": "ستة آلاف ريال شهرياً",
    "طريقة_الدفع": "يُدفع في نهاية كل شهر ميلادي عبر حساب بنكي مسجّل لدى الطرفين."
  },
  "elements": [
    { "id": "frame", "type": "rect", "x": 28, "y": 28, "w": 738, "h": 1067, "stroke": "#112A4D", "strokeWidth": 1.6, "radius": 8 },
    { "id": "header_band", "type": "rect", "x": 28, "y": 28, "w": 738, "h": 96, "fill": "#112A4D", "radius": 8 },
    { "id": "accent", "type": "rect", "x": 28, "y": 124, "w": 738, "h": 4, "fill": "#C9A227" },
    { "id": "title", "type": "text", "x": 28, "y": 50, "w": 738, "h": 44, "text": "عقد عمل مؤقت", "font": "amiri", "weight": "bold", "size": 30, "color": "#F4E3B2", "align": "center", "valign": "middle" },
    { "id": "contract_no", "type": "text", "x": 60, "y": 152, "w": 674, "h": 26, "text": "الرقم المرجعي: {{رقم_العقد}}", "font": "amiri", "size": 15, "color": "#112A4D", "align": "start" },
    { "id": "preamble", "type": "text", "x": 60, "y": 192, "w": 674, "h": 40, "text": "إنه في يوم {{تاريخ_البداية}}، تم الاتفاق بين كل من:", "font": "amiri", "size": 18, "color": "#1B2539", "align": "start", "lineHeight": 1.9, "maxLines": 2 },
    { "id": "party_1", "type": "text", "x": 60, "y": 244, "w": 674, "h": 40, "text": "الطرف الأول (صاحب العمل): {{اسم_المنشأة}}", "font": "amiri", "weight": "bold", "size": 18, "color": "#112A4D", "align": "start", "lineHeight": 1.9, "maxLines": 2 },
    { "id": "party_2", "type": "text", "x": 60, "y": 288, "w": 674, "h": 40, "text": "الطرف الثاني (العامل): {{اسم_الطرف_الثاني}}", "font": "amiri", "weight": "bold", "size": 18, "color": "#112A4D", "align": "start", "lineHeight": 1.9, "maxLines": 2 },
    { "id": "sep_1", "type": "line", "x": 60, "y": 350, "w": 674, "stroke": "#C9A227", "strokeWidth": 1.5 },
    { "id": "clause_1_title", "type": "text", "x": 60, "y": 364, "w": 674, "h": 30, "text": "البند الأول: مدة العقد", "font": "amiri", "weight": "bold", "size": 19, "color": "#112A4D", "align": "start" },
    { "id": "clause_1_body", "type": "text", "x": 60, "y": 398, "w": 674, "h": 110, "text": "أُبرم هذا العقد لفترة مؤقتة تبدأ من {{تاريخ_البداية}} وتنتهي في {{تاريخ_النهاية}}، ولا يجوز تمديده إلا باتفاق مكتوب مسبق بين الطرفين.", "font": "amiri", "size": 17, "color": "#374151", "align": "justify", "lineHeight": 2, "maxLines": 3 },
    { "id": "clause_2_title", "type": "text", "x": 60, "y": 522, "w": 674, "h": 30, "text": "البند الثاني: الأجر وطريقة الدفع", "font": "amiri", "weight": "bold", "size": 19, "color": "#112A4D", "align": "start" },
    { "id": "clause_2_body", "type": "text", "x": 60, "y": 556, "w": 674, "h": 110, "text": "يستحق الطرف الثاني أجراً وقدره {{قيمة_العقد}}، تُصرف بانتظام وفق {{طريقة_الدفع}}", "font": "amiri", "size": 17, "color": "#374151", "align": "justify", "lineHeight": 2, "maxLines": 3 },
    { "id": "clause_3_title", "type": "text", "x": 60, "y": 680, "w": 674, "h": 30, "text": "البند الثالث: الأحكام العامة", "font": "amiri", "weight": "bold", "size": 19, "color": "#112A4D", "align": "start" },
    { "id": "clause_3_body", "type": "text", "x": 60, "y": 714, "w": 674, "h": 110, "text": "يخضع هذا العقد لأنظمة العمل السارية، وأي نزاع ينشأ عنه يُحال إلى الجهة المختصة وفق الإجراءات المعمول بها.", "font": "amiri", "size": 17, "color": "#374151", "align": "justify", "lineHeight": 2, "maxLines": 3 },
    { "id": "seal", "type": "seal", "x": 337, "y": 846, "w": 120, "h": 120, "fill": "#C9A227", "ring": "#F5F7FA", "star": "#112A4D" },
    { "id": "sign_line_1", "type": "line", "x": 60, "y": 990, "w": 250, "stroke": "#112A4D", "strokeWidth": 1 },
    { "id": "sign_label_1", "type": "text", "x": 60, "y": 996, "w": 250, "h": 26, "text": "الطرف الأول", "font": "amiri", "size": 15, "color": "#5B6B80", "align": "center" },
    { "id": "sign_line_2", "type": "line", "x": 484, "y": 990, "w": 250, "stroke": "#112A4D", "strokeWidth": 1 },
    { "id": "sign_label_2", "type": "text", "x": 484, "y": 996, "w": 250, "h": 26, "text": "الطرف الثاني", "font": "amiri", "size": 15, "color": "#5B6B80", "align": "center" },
    { "id": "footer", "type": "text", "x": 60, "y": 1044, "w": 674, "h": 24, "text": "حُرّر هذا العقد إلكترونياً عبر منصة جودكرافت.", "font": "amiri", "size": 13, "color": "#9CA3AF", "align": "center" }
  ]
}
''',
  );

  /// عقد تقديم استشارات — عنابي كلاسيكي مع إطار ذهبي مزدوج وخط نسخ.
  static final PresetTemplate _consultingContract = PresetTemplate(
    id: 'consulting_contract',
    titleAr: 'عقد تقديم استشارات',
    descriptionAr: 'عقد خدمات استشارية بإطار عنابي وذهبي وبنود نطاق العمل.',
    collection: TemplateCollection.serviceContract,
    orientation: PageOrientation.portrait,
    tags: <String>['عقد', 'استشارات', 'خدمات', 'اتفاقية', 'عنابي'],
    layoutJson: r'''
{
  "schema_version": 1,
  "paper": "a4",
  "orientation": "portrait",
  "background": "#FCF7F0",
  "canvas": { "width": 794, "height": 1123, "unit": "px" },
  "sample_data": {
    "اسم_الطرف_الأول": "شركة مدار للاستشارات",
    "اسم_الطرف_الثاني": "مؤسسة نسيج للتجارة",
    "رقم_العقد": "JC-SC-2026-0156",
    "تاريخ_العقد": "١٨ رجب ١٤٤٨هـ",
    "قيمة_العقد": "مبلغ وقدره ثمانون ألف ريال",
    "طريقة_الدفع": "يُسدَّد على أربع دفعات ربع سنوية وفق جدول زمني مرفق."
  },
  "elements": [
    { "id": "frame", "type": "rect", "x": 26, "y": 26, "w": 742, "h": 1071, "stroke": "#6B1E2E", "strokeWidth": 2, "radius": 10 },
    { "id": "header_band", "type": "rect", "x": 26, "y": 26, "w": 742, "h": 104, "fill": "#6B1E2E", "radius": 10 },
    { "id": "frame_inner", "type": "rect", "x": 40, "y": 40, "w": 714, "h": 1043, "stroke": "#D4A857", "strokeWidth": 1, "radius": 6 },
    { "id": "title", "type": "text", "x": 40, "y": 46, "w": 714, "h": 46, "text": "عقد تقديم استشارات", "font": "amiri", "weight": "bold", "size": 30, "color": "#FCF7F0", "align": "center", "valign": "middle" },
    { "id": "gold_rule", "type": "rect", "x": 60, "y": 152, "w": 674, "h": 3, "fill": "#D4A857" },
    { "id": "contract_no", "type": "text", "x": 60, "y": 168, "w": 674, "h": 26, "text": "الرقم المرجعي: {{رقم_العقد}}", "font": "amiri", "size": 15, "color": "#6B1E2E", "align": "start" },
    { "id": "preamble", "type": "text", "x": 60, "y": 206, "w": 674, "h": 40, "text": "إنه في يوم {{تاريخ_العقد}}، تم الاتفاق بين كل من:", "font": "amiri", "size": 18, "color": "#1B2539", "align": "start", "lineHeight": 1.9, "maxLines": 2 },
    { "id": "party_1", "type": "text", "x": 60, "y": 258, "w": 674, "h": 40, "text": "الطرف الأول: {{اسم_الطرف_الأول}}", "font": "amiri", "weight": "bold", "size": 18, "color": "#6B1E2E", "align": "start", "lineHeight": 1.9, "maxLines": 2 },
    { "id": "party_2", "type": "text", "x": 60, "y": 302, "w": 674, "h": 40, "text": "الطرف الثاني: {{اسم_الطرف_الثاني}}", "font": "amiri", "weight": "bold", "size": 18, "color": "#6B1E2E", "align": "start", "lineHeight": 1.9, "maxLines": 2 },
    { "id": "sep_1", "type": "line", "x": 60, "y": 364, "w": 674, "stroke": "#E3CDBA", "strokeWidth": 1.5 },
    { "id": "clause_1_title", "type": "text", "x": 60, "y": 378, "w": 674, "h": 30, "text": "البند الأول: نطاق العمل", "font": "amiri", "weight": "bold", "size": 19, "color": "#6B1E2E", "align": "start" },
    { "id": "clause_1_body", "type": "text", "x": 60, "y": 412, "w": 674, "h": 110, "text": "يلتزم الطرف الثاني بتقديم الاستشارات المتفق عليها وفق المواصفات والشروط الواردة في الملحق الفني المرفق بهذا العقد.", "font": "amiri", "size": 17, "color": "#374151", "align": "justify", "lineHeight": 2, "maxLines": 3 },
    { "id": "clause_2_title", "type": "text", "x": 60, "y": 536, "w": 674, "h": 30, "text": "البند الثاني: المقابل المالي", "font": "amiri", "weight": "bold", "size": 19, "color": "#6B1E2E", "align": "start" },
    { "id": "clause_2_body", "type": "text", "x": 60, "y": 570, "w": 674, "h": 110, "text": "يستحق الطرف الثاني مقابل استشاراته {{قيمة_العقد}}. و{{طريقة_الدفع}}", "font": "amiri", "size": 17, "color": "#374151", "align": "justify", "lineHeight": 2, "maxLines": 3 },
    { "id": "clause_3_title", "type": "text", "x": 60, "y": 694, "w": 674, "h": 30, "text": "البند الثالث: الأحكام العامة", "font": "amiri", "weight": "bold", "size": 19, "color": "#6B1E2E", "align": "start" },
    { "id": "clause_3_body", "type": "text", "x": 60, "y": 728, "w": 674, "h": 110, "text": "يخضع هذا العقد لأنظمة المملكة العربية السعودية، وأي نزاع ينشأ عنه يُحال إلى الجهة القضائية المختصة.", "font": "amiri", "size": 17, "color": "#374151", "align": "justify", "lineHeight": 2, "maxLines": 3 },
    { "id": "seal", "type": "seal", "x": 337, "y": 858, "w": 118, "h": 118, "fill": "#6B1E2E", "ring": "#FCF7F0", "star": "#D4A857" },
    { "id": "sign_line_1", "type": "line", "x": 60, "y": 1000, "w": 250, "stroke": "#6B1E2E", "strokeWidth": 1 },
    { "id": "sign_label_1", "type": "text", "x": 60, "y": 1006, "w": 250, "h": 26, "text": "الطرف الأول", "font": "amiri", "size": 15, "color": "#7A5A60", "align": "center" },
    { "id": "sign_line_2", "type": "line", "x": 484, "y": 1000, "w": 250, "stroke": "#6B1E2E", "strokeWidth": 1 },
    { "id": "sign_label_2", "type": "text", "x": 484, "y": 1006, "w": 250, "h": 26, "text": "الطرف الثاني", "font": "amiri", "size": 15, "color": "#7A5A60", "align": "center" },
    { "id": "footer", "type": "text", "x": 60, "y": 1048, "w": 674, "h": 24, "text": "حُرّر هذا العقد إلكترونياً عبر منصة جودكرافت بتاريخ {{تاريخ_العقد}}", "font": "amiri", "size": 13, "color": "#A08A8F", "align": "center" }
  ]
}
''',
  );
}
