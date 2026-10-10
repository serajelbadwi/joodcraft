import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/material.dart' show IconData, Icons;

import '../constants/app_constants.dart';
import '../models/template_document.dart';
import '../models/template_element.dart';
import 'template_draft.dart';

/// القسم الرئيسي في مركز إنشاء المشاريع.
///
/// * [singleSheet]: مطبوعات ووثائق من **ورقة واحدة** (شهادة، بطاقة، كرت معايدة…).
/// * [multiPage]: كتب ومنشورات متعددة الصفحات (كتاب، مجلة، تقرير…).
enum ProjectKind {
  singleSheet('single'),
  multiPage('multi');

  const ProjectKind(this.jsonValue);

  final String jsonValue;
}

/// مجموعة بصرية داخل القسم — تُعرض كقسم بعنوان وأيقونة يجمع بطاقات مقاساته.
enum ProjectPresetGroup {
  certificatesAndContracts('certificates', Icons.workspace_premium_rounded),
  cardsAndBadges('cards', Icons.badge_rounded),
  seatNumbersAndTags('seat', Icons.event_seat_rounded),
  greetingCards('greeting', Icons.celebration_rounded),
  publications('publications', Icons.menu_book_rounded);

  const ProjectPresetGroup(this.jsonValue, this.icon);

  final String jsonValue;
  final IconData icon;
}

/// مقاس مشروع جاهز داخل المركز.
///
/// **الهندسة صريحة:** [pageWidth] و[pageHeight] هما أبعاد الصفحة **النهائية**
/// كما ستظهر للمستخدم (بوحدة [unit])، ويُشتقّ الاتجاه منهما تلقائياً: إن كان
/// العرض أكبر من الارتفاع فالصفحة أفقية، وإلا فهي رأسية. هذا يجعل اختيار أي
/// بطاقة يُنشئ لوحةً بمقاسها ونسبتها بالضبط لا تقريباً.
///
/// * [paperSize] غير `null` للمقاسات القياسية المعروفة للورق (A4/A5/Letter)،
///   فيُبنى المستند على المقاس القياسي نفسه ويستفيد من تسعير الـ PDF واسمه.
/// * خلاف ذلك يُبنى المستند بمقاس مخصّص ([CustomPageSize]) بالوحدة المطلوبة —
///   وهو ما يغطّي A3 وA6 وDL والبطاقات والمقاسات الرقمية بالبكسل.
@immutable
class ProjectPreset {
  const ProjectPreset({
    required this.id,
    required this.titleAr,
    required this.descriptionAr,
    required this.kind,
    required this.group,
    required this.pageWidth,
    required this.pageHeight,
    required this.unit,
    this.paperSize,
    this.category = TemplateCategory.certificate,
    this.isDigital = false,
    this.tags = const <String>[],
  });

  /// معرّف ثابت فريد داخل الفهرس.
  final String id;

  /// العنوان العربي (يُترجَم في الواجهة، ويُستخدم احتياطياً كعنوان المشروع).
  final String titleAr;

  final String descriptionAr;

  /// القسم الرئيسي (ورقة واحدة / متعدد الصفحات).
  final ProjectKind kind;

  /// المجموعة البصرية داخل القسم.
  final ProjectPresetGroup group;

  /// عرض الصفحة النهائي بوحدة [unit].
  final double pageWidth;

  /// ارتفاع الصفحة النهائي بوحدة [unit].
  final double pageHeight;

  /// وحدة الأبعاد (سم/ملم/بوصة/بكسل).
  final MeasurementUnit unit;

  /// المقاس القياسي المقابل إن وُجد (A4/A5/Letter) — وإلا `null` فيُستخدم مقاس مخصّص.
  final PaperSize? paperSize;

  /// تصنيف المحرّر الذي يُفتح به المشروع (شهادة/عقد) — يحدّد المسار والاتجاه الافتراضي.
  final TemplateCategory category;

  /// هل المقاس رقمي (بالبكسل) لا مطبوع؟ يُستخدم لوصف البطاقة وتنبيه المستخدم.
  final bool isDigital;

  /// كلمات مفتاحية للبحث والتصفية.
  final List<String> tags;

  /// هل الصفحة النهائية أفقية؟ (العرض أكبر من الارتفاع).
  ///
  /// المقاس المربّع (1080×1080) يُعدّ هنا «رأسياً» لأن الاتجاه ملتبس فيه أصلاً
  /// ولا يغيّر الهندسة — فيبقى السلوك ثابتاً وقابلاً للاختبار.
  bool get isLandscape => pageWidth > pageHeight;

  /// الاتجاه المقابل لهذه الهندسة.
  PageOrientation get orientation =>
      isLandscape ? PageOrientation.landscape : PageOrientation.portrait;

  /// وصف المقاس «21 × 29.7 سم».
  String get dimensionsLabel =>
      '${formatDimension(pageWidth)} × ${formatDimension(pageHeight)} '
      '${unit.labelAr}';

  /// صيغة النسبة «21:29.7» — مفيدة للعرض على البطاقة.
  String get ratioLabel =>
      '${formatDimension(pageWidth)}:${formatDimension(pageHeight)}';

  /// مسودة فارغة بمقاس هذا المشروع — يُفتح بها المحرّر مباشرةً.
  ProjectDraft toDraft({String? title}) => ProjectDraft(
        title: title ?? titleAr,
        category: category,
        document: toDocument(),
      );

  /// مستند فارغ (بلا عناصر) يطابق هندسة هذا المقاس بالضبط.
  TemplateDocument toDocument() {
    final PaperSize? standard = paperSize;
    if (standard != null) {
      // المقاس القياسي يحمل أبعاده بالنقاط أصلاً، والاتجاه يدير التبديل.
      return TemplateDocument(
        elements: const <TemplateElement>[],
        paperSize: standard,
        orientation: orientation,
      );
    }
    return buildCustomDocument(
      width: pageWidth,
      height: pageHeight,
      unit: unit,
    );
  }

  /// هل يطابق نص البحث (العنوان أو الوصف أو الوسوم)؟
  bool matches(String needle) {
    final String query = needle.trim().toLowerCase();
    if (query.isEmpty) return true;
    return titleAr.toLowerCase().contains(query) ||
        descriptionAr.toLowerCase().contains(query) ||
        dimensionsLabel.toLowerCase().contains(query) ||
        tags.any((String tag) => tag.toLowerCase().contains(query));
  }

  /// يُنسّق رقماً بلا أصفار معلّقة: ‎29.7‎ تبقى `29.7` و‎1080‎ تبقى `1080`.
  static String formatDimension(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    final String text = value.toStringAsFixed(2);
    return text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
}

/// مستند فارغ من أبعاد مخصّصة، مطبَّع على اصطلاح الاتجاه في المحرّك.
///
/// المحرّك يخزّن `CustomPageSize` في هيئة «طبيعية» ثم **يقلب** العرض والارتفاع
/// عند الاتجاه الأفقي (`landscapeWidthPt = heightPT`). لذلك نُخزّن هنا الأبعاد
/// بحيث يخرج المستند **بالاتجاه المتوقّع من الأبعاد المُدخلة**: ما يُدخله
/// المستخدم عرضاً يبقى عرضاً على اللوحة.
TemplateDocument buildCustomDocument({
  required double width,
  required double height,
  required MeasurementUnit unit,
}) {
  final bool landscape = width > height;
  return TemplateDocument(
    elements: const <TemplateElement>[],
    orientation:
        landscape ? PageOrientation.landscape : PageOrientation.portrait,
    customPageSize: CustomPageSize(
      width: landscape ? height : width,
      height: landscape ? width : height,
      unit: unit,
    ),
  );
}

/// مسودة مشروع جاهزة للفتح في المحرّر (اسم مرادف لـ[TemplateDraft] لتوضيح النية).
typedef ProjectDraft = TemplateDraft;

/// فهرس مقاسات المشاريع الجاهزة — مصدر واحد تبني منه شاشة الإنشاء بطاقاتها.
///
/// لا يُقرأ من الشبكة ولا من ملف: كل المقاسات محسوبة في الكود بدقة الوحدة
/// المعلنة، فتبقى متاحة أوفلاين وبلا أي انزياح تقريب.
abstract final class ProjectPresetCatalog {
  const ProjectPresetCatalog._();

  /// مقاسات الورقة الواحدة القياسية للشهادات والعقود (A4/A3/Letter).
  ///
  /// الأفقي يُصنّف «شهادة» والرأسي «عقد»، مطابقةً لاصطلاح المنصة
  /// ([TemplateCategory.defaultOrientation]).
  static const List<ProjectPreset> _documents = <ProjectPreset>[
    ProjectPreset(
      id: 'doc.a4.landscape',
      titleAr: 'A4 أفقي',
      descriptionAr: 'شهادة أو وثيقة رسمية على ورقة A4 بالعرض.',
      kind: ProjectKind.singleSheet,
      group: ProjectPresetGroup.certificatesAndContracts,
      pageWidth: 29.7,
      pageHeight: 21,
      unit: MeasurementUnit.cm,
      paperSize: PaperSize.a4,
      tags: <String>['a4', 'landscape', 'شهادة', 'certificate'],
    ),
    ProjectPreset(
      id: 'doc.a4.portrait',
      titleAr: 'A4 رأسي',
      descriptionAr: 'عقد أو خطاب رسمي على ورقة A4 بالطول.',
      kind: ProjectKind.singleSheet,
      group: ProjectPresetGroup.certificatesAndContracts,
      pageWidth: 21,
      pageHeight: 29.7,
      unit: MeasurementUnit.cm,
      paperSize: PaperSize.a4,
      category: TemplateCategory.contract,
      tags: <String>['a4', 'portrait', 'عقد', 'contract'],
    ),
    ProjectPreset(
      id: 'doc.a3.landscape',
      titleAr: 'A3 أفقي',
      descriptionAr: 'شهادة كبيرة المقاس تُطبع على ورقة A3 بالعرض.',
      kind: ProjectKind.singleSheet,
      group: ProjectPresetGroup.certificatesAndContracts,
      pageWidth: 42,
      pageHeight: 29.7,
      unit: MeasurementUnit.cm,
      tags: <String>['a3', 'landscape', 'شهادة'],
    ),
    ProjectPreset(
      id: 'doc.a3.portrait',
      titleAr: 'A3 رأسي',
      descriptionAr: 'وثيقة أو عقد بمقاس A3 بالطول.',
      kind: ProjectKind.singleSheet,
      group: ProjectPresetGroup.certificatesAndContracts,
      pageWidth: 29.7,
      pageHeight: 42,
      unit: MeasurementUnit.cm,
      category: TemplateCategory.contract,
      tags: <String>['a3', 'portrait', 'عقد'],
    ),
    ProjectPreset(
      id: 'doc.letter.landscape',
      titleAr: 'Letter أفقي',
      descriptionAr: 'شهادة بمقاس Letter الأمريكي بالعرض (8.5×11 بوصة).',
      kind: ProjectKind.singleSheet,
      group: ProjectPresetGroup.certificatesAndContracts,
      pageWidth: 11,
      pageHeight: 8.5,
      unit: MeasurementUnit.inch,
      paperSize: PaperSize.letter,
      tags: <String>['letter', 'landscape', 'شهادة'],
    ),
    ProjectPreset(
      id: 'doc.letter.portrait',
      titleAr: 'Letter رأسي',
      descriptionAr: 'عقد أو خطاب بمقاس Letter بالطول.',
      kind: ProjectKind.singleSheet,
      group: ProjectPresetGroup.certificatesAndContracts,
      pageWidth: 8.5,
      pageHeight: 11,
      unit: MeasurementUnit.inch,
      paperSize: PaperSize.letter,
      category: TemplateCategory.contract,
      tags: <String>['letter', 'portrait', 'عقد'],
    ),
  ];

  /// الكروت وبطاقات الهوية — أحجام الجيب القياسية.
  static const List<ProjectPreset> _cards = <ProjectPreset>[
    ProjectPreset(
      id: 'card.business',
      titleAr: 'بطاقة عمل',
      descriptionAr: 'البطاقة الشخصية القياسية 90×55 ملم بحدود قطع 3 ملم.',
      kind: ProjectKind.singleSheet,
      group: ProjectPresetGroup.cardsAndBadges,
      pageWidth: 90,
      pageHeight: 55,
      unit: MeasurementUnit.mm,
      tags: <String>['بطاقة', 'business card', '90x55'],
    ),
    ProjectPreset(
      id: 'card.id-badge',
      titleAr: 'بطاقة هوية / شارة',
      descriptionAr: 'شارة صدر أو بطاقة هوية بمقاس بطاقة البنك 85.6×53.9 ملم.',
      kind: ProjectKind.singleSheet,
      group: ProjectPresetGroup.cardsAndBadges,
      pageWidth: 85.6,
      pageHeight: 53.9,
      unit: MeasurementUnit.mm,
      tags: <String>['هوية', 'id badge', '85.6x53.9'],
    ),
  ];

  /// أرقام الجلوس والبطاقات — مقاسات صغيرة تُوضع على الطاولات والأدراج.
  static const List<ProjectPreset> _seatNumbers = <ProjectPreset>[
    ProjectPreset(
      id: 'seat.a6',
      titleAr: 'A6 — 105×148 ملم',
      descriptionAr: 'رقم جلوس أو بطاقة تعريف على مقاس A6.',
      kind: ProjectKind.singleSheet,
      group: ProjectPresetGroup.seatNumbersAndTags,
      pageWidth: 105,
      pageHeight: 148,
      unit: MeasurementUnit.mm,
      tags: <String>['a6', 'رقم جلوس', 'seat'],
    ),
    ProjectPreset(
      id: 'seat.a5',
      titleAr: 'A5 — 148×210 ملم',
      descriptionAr: 'لوحة اسم أو بطاقة جلوس على مقاس A5.',
      kind: ProjectKind.singleSheet,
      group: ProjectPresetGroup.seatNumbersAndTags,
      pageWidth: 148,
      pageHeight: 210,
      unit: MeasurementUnit.mm,
      paperSize: PaperSize.a5,
      tags: <String>['a5', 'رقم جلوس', 'seat'],
    ),
  ];

  /// كروت المعايدات — مقاسات طباعة ورقية وأخرى رقمية للجوال.
  static const List<ProjectPreset> _greetingCards = <ProjectPreset>[
    ProjectPreset(
      id: 'greeting.dl',
      titleAr: 'DL — 99×210 ملم',
      descriptionAr: 'كرت معايدة مطوي على مقاس DL (ثلث A4).',
      kind: ProjectKind.singleSheet,
      group: ProjectPresetGroup.greetingCards,
      pageWidth: 99,
      pageHeight: 210,
      unit: MeasurementUnit.mm,
      tags: <String>['dl', 'معايدة', 'greeting'],
    ),
    ProjectPreset(
      id: 'greeting.a6',
      titleAr: 'A6 — 105×148 ملم',
      descriptionAr: 'كرت معايدة مطبوع على مقاس A6.',
      kind: ProjectKind.singleSheet,
      group: ProjectPresetGroup.greetingCards,
      pageWidth: 105,
      pageHeight: 148,
      unit: MeasurementUnit.mm,
      tags: <String>['a6', 'معايدة', 'greeting'],
    ),
    ProjectPreset(
      id: 'greeting.a5',
      titleAr: 'A5 — 148×210 ملم',
      descriptionAr: 'كرت معايدة كبير على مقاس A5.',
      kind: ProjectKind.singleSheet,
      group: ProjectPresetGroup.greetingCards,
      pageWidth: 148,
      pageHeight: 210,
      unit: MeasurementUnit.mm,
      paperSize: PaperSize.a5,
      tags: <String>['a5', 'معايدة', 'greeting'],
    ),
    ProjectPreset(
      id: 'greeting.story',
      titleAr: 'قصة / حالة عمودية',
      descriptionAr: 'مقاس رقمي للجوال 1080×1920 بكسل بنسبة 16:9.',
      kind: ProjectKind.singleSheet,
      group: ProjectPresetGroup.greetingCards,
      pageWidth: 1080,
      pageHeight: 1920,
      unit: MeasurementUnit.px,
      isDigital: true,
      tags: <String>['story', 'status', '1080x1920', '16:9', 'digital'],
    ),
    ProjectPreset(
      id: 'greeting.square',
      titleAr: 'منشور مربّع',
      descriptionAr: 'مقاس رقمي للتواصل الاجتماعي 1080×1080 بكسل بنسبة 1:1.',
      kind: ProjectKind.singleSheet,
      group: ProjectPresetGroup.greetingCards,
      pageWidth: 1080,
      pageHeight: 1080,
      unit: MeasurementUnit.px,
      isDigital: true,
      tags: <String>['square', 'post', '1080x1080', '1:1', 'digital'],
    ),
  ];

  /// الكتب والمنشورات متعددة الصفحات — هندسة صفحة الكتاب قبل الترقيم والطيّ.
  static const List<ProjectPreset> _publications = <ProjectPreset>[
    ProjectPreset(
      id: 'pub.book.a5',
      titleAr: 'كتاب A5',
      descriptionAr: 'كتاب بحجم الجيب بمقاس صفحة A5 (148×210 ملم).',
      kind: ProjectKind.multiPage,
      group: ProjectPresetGroup.publications,
      pageWidth: 148,
      pageHeight: 210,
      unit: MeasurementUnit.mm,
      paperSize: PaperSize.a5,
      tags: <String>['كتاب', 'book', 'a5'],
    ),
    ProjectPreset(
      id: 'pub.book.a4',
      titleAr: 'كتاب A4',
      descriptionAr: 'كتاب أو مذكرة بمقاس صفحة A4 (210×297 ملم).',
      kind: ProjectKind.multiPage,
      group: ProjectPresetGroup.publications,
      pageWidth: 210,
      pageHeight: 297,
      unit: MeasurementUnit.mm,
      paperSize: PaperSize.a4,
      tags: <String>['كتاب', 'book', 'a4'],
    ),
    ProjectPreset(
      id: 'pub.magazine.a4',
      titleAr: 'مجلة A4',
      descriptionAr: 'مجلة أو مطبوعة دورية بمقاس صفحة A4.',
      kind: ProjectKind.multiPage,
      group: ProjectPresetGroup.publications,
      pageWidth: 210,
      pageHeight: 297,
      unit: MeasurementUnit.mm,
      paperSize: PaperSize.a4,
      tags: <String>['مجلة', 'magazine', 'a4'],
    ),
    ProjectPreset(
      id: 'pub.booklet.a5',
      titleAr: 'كتيّب / نشرة A5 أفقي',
      descriptionAr: 'كتيّب مطوي بنصف ورقة A4 (صفحة 210×148 ملم).',
      kind: ProjectKind.multiPage,
      group: ProjectPresetGroup.publications,
      pageWidth: 210,
      pageHeight: 148,
      unit: MeasurementUnit.mm,
      tags: <String>['كتيب', 'نشرة', 'booklet'],
    ),
    ProjectPreset(
      id: 'pub.report.a4',
      titleAr: 'تقرير A4',
      descriptionAr: 'تقرير أو دراسة بمقاس صفحة A4 مع هوية الجهة.',
      kind: ProjectKind.multiPage,
      group: ProjectPresetGroup.publications,
      pageWidth: 210,
      pageHeight: 297,
      unit: MeasurementUnit.mm,
      paperSize: PaperSize.a4,
      category: TemplateCategory.contract,
      tags: <String>['تقرير', 'report', 'a4'],
    ),
    ProjectPreset(
      id: 'pub.catalog.a4',
      titleAr: 'كتالوج A4 أفقي',
      descriptionAr: 'كتالوج منتجات بصفحة أفقية عريضة (297×210 ملم).',
      kind: ProjectKind.multiPage,
      group: ProjectPresetGroup.publications,
      pageWidth: 297,
      pageHeight: 210,
      unit: MeasurementUnit.mm,
      tags: <String>['كتالوج', 'catalog', 'a4', 'landscape'],
    ),
  ];

  /// كل المقاسات الجاهزة (المطبوعات المفردة ثم المنشورات).
  static const List<ProjectPreset> all = <ProjectPreset>[
    ..._documents,
    ..._cards,
    ..._seatNumbers,
    ..._greetingCards,
    ..._publications,
  ];

  /// مقاسات القسم المطلوب مرتّبة بمجموعاتها.
  static List<ProjectPreset> forKind(ProjectKind kind) =>
      all.where((ProjectPreset preset) => preset.kind == kind).toList(
            growable: false,
          );

  /// مجموعات القسم المطلوب **التي تحوي مقاسات فعلاً**، بترتيبها البصري.
  static List<ProjectPresetGroup> groupsForKind(ProjectKind kind) {
    final Set<ProjectPresetGroup> used = <ProjectPresetGroup>{
      for (final ProjectPreset preset in all)
        if (preset.kind == kind) preset.group,
    };
    return ProjectPresetGroup.values
        .where(used.contains)
        .toList(growable: false);
  }

  /// مقاسات مجموعة واحدة بترتيب الفهرس.
  static List<ProjectPreset> forGroup(ProjectPresetGroup group) =>
      all.where((ProjectPreset preset) => preset.group == group).toList(
            growable: false,
          );

  /// بحث بالمعرّف (يعيد `null` عند الغياب بدل أن يرمي).
  static ProjectPreset? byId(String id) {
    for (final ProjectPreset preset in all) {
      if (preset.id == id) return preset;
    }
    return null;
  }
}
