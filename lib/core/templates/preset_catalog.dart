import '../constants/app_constants.dart';
import 'preset_template.dart';

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
  ];

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
}
