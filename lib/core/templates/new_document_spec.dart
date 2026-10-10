import 'dart:math' as math;

import 'package:flutter/foundation.dart' show immutable;

import '../constants/app_constants.dart';
import '../models/template_document.dart';
import 'project_preset.dart';
import 'template_draft.dart';

/// **عائلة مقاس واحدة** في شبكة نافذة المستند الجديد.
///
/// نافذة المستند الجديد لا تعرض بطاقةً لكل اتجاه: مقاس A4 بطاقةٌ واحدة
/// («A4») تجمع متغيّرَيه الرأسي والأفقي، والاتجاه يُختار من لوحة التفاصيل على
/// اليمين. هذا يطابق سلوك Photoshop ويُقصّي نصف البطاقات المتطابقة.
///
/// * [variants] قد تحمل أكثر من متغيّر للاتجاه الواحد حين تختلف **الغرض**
///   بالمقاس نفسه (كتاب/مجلة/تقرير A4 مثلاً)؛ تُعرض حينها كخيارات «النوع»
///   داخل لوحة التفاصيل، ولا تتكرّر البطاقة.
/// * [title] يأتي من عناوين المتغيّرات بعد تجريد كلمة الاتجاه («A4 أفقي» ⇒
///   «A4»)، فإن تعددت العناوين استُخدم اسم المقاس القياسي أو الأبعاد.
@immutable
class ProjectPresetFamily {
  const ProjectPresetFamily({
    required this.id,
    required this.title,
    required this.group,
    required this.kind,
    required this.variants,
    required this.paperSize,
  });

  /// معرّف ثابت (معرّف أول متغيّر داخل الفهرس) — يُستخدم في المفاتيح والاختبارات.
  final String id;

  /// العنوان المعروض بلا كلمة اتجاه («A4»، «بطاقة عمل»…).
  final String title;

  final ProjectPresetGroup group;
  final ProjectKind kind;

  /// متغيّرات المقاس بترتيب الفهرس (أول عنصر هو المتغيّر الممثّل للعائلة).
  final List<ProjectPreset> variants;

  /// المقاس القياسي المشترك (A4/A5/Letter) إن وُجد — يُستخدم للعنوان والتسعير.
  final PaperSize? paperSize;

  /// هل العائلة رقمية (بالبكسل) لا مطبوعة؟
  bool get isDigital => variants.any((ProjectPreset p) => p.isDigital);

  /// وحدة أبعاد العائلة (وحدات المتغيّرات متطابقة داخل العائلة).
  MeasurementUnit get unit => variants.first.unit;

  /// معرّف المقاس المخصّص الافتراضي في الشبكة.
  static const String customId = 'custom';

  /// الاتجاهات المتاحة فعلاً في الفهرس (أفقي ثم رأسي).
  List<PageOrientation> get orientations {
    final List<PageOrientation> list = <PageOrientation>[];
    for (final ProjectPreset variant in variants) {
      if (!list.contains(variant.orientation)) list.add(variant.orientation);
    }
    return List<PageOrientation>.unmodifiable(list);
  }

  /// المتغيّر المقابل لاتجاه [orientation]، أو `null` إن لم يكن في الفهرس.
  ProjectPreset? variantFor(PageOrientation orientation) {
    for (final ProjectPreset variant in variants) {
      if (variant.orientation == orientation) return variant;
    }
    return null;
  }

  /// كل متغيّرات الاتجاه [orientation] (كتاب/مجلة/تقرير بالمقاس نفسه).
  List<ProjectPreset> variantsFor(PageOrientation orientation) => variants
      .where((ProjectPreset p) => p.orientation == orientation)
      .toList(growable: false);

  /// عرض المقاس بوحدة العائلة في اتجاه [orientation].
  ///
  /// يرجع إلى أبعاد أول متغيّر مقلوبةً عند غياب متغيّر للاتجاه المطلوب، فيبقى
  /// مفتاح الاتجاه فعّالاً لتعريف المقاس بغضّ النظر عن الفهرس.
  double widthFor(PageOrientation orientation) {
    final ProjectPreset? variant = variantFor(orientation);
    if (variant != null) return variant.pageWidth;
    final ProjectPreset first = variants.first;
    return orientation.isLandscape
        ? math.max(first.pageWidth, first.pageHeight)
        : math.min(first.pageWidth, first.pageHeight);
  }

  /// ارتفاع المقاس بوحدة العائلة في اتجاه [orientation].
  double heightFor(PageOrientation orientation) {
    final ProjectPreset? variant = variantFor(orientation);
    if (variant != null) return variant.pageHeight;
    final ProjectPreset first = variants.first;
    return orientation.isLandscape
        ? math.min(first.pageWidth, first.pageHeight)
        : math.max(first.pageWidth, first.pageHeight);
  }

  /// «210 × 297 ملم» في اتجاه [orientation].
  String dimensionsLabelFor(PageOrientation orientation) =>
      '${ProjectPreset.formatDimension(widthFor(orientation))} × '
      '${ProjectPreset.formatDimension(heightFor(orientation))} '
      '${unit.labelAr}';

  /// نسبة العرض إلى الارتفاع (لرسم معاينة الورقة الصغيرة على البطاقة).
  double get aspectRatio =>
      widthFor(PageOrientation.portrait) /
      heightFor(PageOrientation.portrait);

  /// هل تطابق نص البحث؟ (كل المتغيّرات: العنوان والوصف والوسوم والأبعاد).
  bool matches(String needle) {
    if (needle.trim().isEmpty) return true;
    if (title.toLowerCase().contains(needle.trim().toLowerCase())) return true;
    if (dimensionsLabelFor(PageOrientation.portrait)
        .toLowerCase()
        .contains(needle.trim().toLowerCase())) {
      return true;
    }
    return variants.any((ProjectPreset p) => p.matches(needle));
  }
}

/// عائلات المقاسات — تُبنى مرة واحدة من فهرس [ProjectPresetCatalog].
abstract final class ProjectPresetFamilies {
  const ProjectPresetFamilies._();

  /// كل العائلات بترتيب المجموعات ثم ترتيب الفهرس.
  static final List<ProjectPresetFamily> all = _build();

  static List<ProjectPresetFamily> _build() {
    final Map<String, List<ProjectPreset>> buckets =
        <String, List<ProjectPreset>>{};
    for (final ProjectPreset preset in ProjectPresetCatalog.all) {
      buckets
          .putIfAbsent(_signatureOf(preset), () => <ProjectPreset>[])
          .add(preset);
    }
    final List<ProjectPresetFamily> families = <ProjectPresetFamily>[
      for (final MapEntry<String, List<ProjectPreset>> entry in buckets.entries)
        _familyOf(entry.value),
    ];
    families.sort((ProjectPresetFamily a, ProjectPresetFamily b) {
      final int byGroup =
          a.group.index.compareTo(b.group.index);
      if (byGroup != 0) return byGroup;
      return _catalogIndex(a.id).compareTo(_catalogIndex(b.id));
    });
    return List<ProjectPresetFamily>.unmodifiable(families);
  }

  static int _catalogIndex(String id) {
    for (int i = 0; i < ProjectPresetCatalog.all.length; i++) {
      if (ProjectPresetCatalog.all[i].id == id) return i;
    }
    return ProjectPresetCatalog.all.length;
  }

  /// بصمة التجميع: المجموعة + الأبعاد **مرتّبة** بالنقاط (فالاتجاه لا يفرّق).
  ///
  /// الأبعاد بالنقاط لأنها الوحدة الحقيقية للمحرّك: 29.7 سم و297 ملم يقعان في
  /// العائلة نفسها مهما اختلفت وحدات الإدخال.
  static String _signatureOf(ProjectPreset preset) {
    final double a = preset.unit.toPoints(preset.pageWidth);
    final double b = preset.unit.toPoints(preset.pageHeight);
    final double short = math.min(a, b);
    final double long = math.max(a, b);
    return '${preset.group.jsonValue}|'
        '${short.toStringAsFixed(2)}x${long.toStringAsFixed(2)}';
  }

  static ProjectPresetFamily _familyOf(List<ProjectPreset> variants) {
    final Set<String> titles = <String>{
      for (final ProjectPreset v in variants) _baseTitle(v.titleAr),
    };
    PaperSize? paperSize;
    for (final ProjectPreset v in variants) {
      if (v.paperSize != null) {
        paperSize = v.paperSize;
        break;
      }
    }
    final String title;
    if (titles.length == 1) {
      title = titles.first;
    } else if (paperSize != null) {
      title = paperSize.labelAr;
    } else {
      final MeasurementUnit unit = variants.first.unit;
      final List<double> dims = <double>[
        for (final ProjectPreset v in variants) v.pageWidth,
        for (final ProjectPreset v in variants) v.pageHeight,
      ];
      title =
          '${ProjectPreset.formatDimension(dims.reduce(math.min))} × '
          '${ProjectPreset.formatDimension(dims.reduce(math.max))} '
          '${unit.labelAr}';
    }
    return ProjectPresetFamily(
      id: variants.first.id,
      title: title,
      group: variants.first.group,
      kind: variants.first.kind,
      variants: List<ProjectPreset>.unmodifiable(variants),
      paperSize: paperSize,
    );
  }

  /// عنوان بلا كلمة الاتجاه («A4 أفقي» ⇒ «A4»).
  static String _baseTitle(String titleAr) {
    for (final String suffix in const <String>[' أفقي', ' رأسي']) {
      if (titleAr.endsWith(suffix)) {
        return titleAr.substring(0, titleAr.length - suffix.length);
      }
    }
    return titleAr;
  }

  /// عائلات قسم واحد (ورقة واحدة / متعدد الصفحات) بترتيبها البصري.
  static List<ProjectPresetFamily> forKind(ProjectKind kind) => all
      .where((ProjectPresetFamily family) => family.kind == kind)
      .toList(growable: false);

  /// عائلات مجموعة واحدة.
  static List<ProjectPresetFamily> forGroup(ProjectPresetGroup group) => all
      .where((ProjectPresetFamily family) => family.group == group)
      .toList(growable: false);

  /// بحث بالمعرّف (يعيد `null` عند الغياب).
  static ProjectPresetFamily? byId(String? id) {
    if (id == null) return null;
    for (final ProjectPresetFamily family in all) {
      if (family.id == id) return family;
    }
    return null;
  }
}

/// مواصفة المستند الجديد — **المصدر الوحيد** لما يُنشئه زر «إنشاء المشروع».
///
/// تحتوي كل ما تسمح به لوحة التفاصيل: الاسم، العرض والارتفاع والوحدة، الاتجاه
/// (مشتقّ من الأبعاد لا منفصل عنها فلا يتعارض الاثنان أبداً)، الدقّة ووحدتها،
/// نمط اللون، ولون الخلفية.
///
/// **دقّة الأبعاد:** إن بقيت الأبعاد مطابقة لمقاس جاهز ([presetId]) يُبنى
/// المستند من ذلك المقاس القياسي نفسه (فيحمل `paper: a4` واسمه في الطباعة)،
/// وإلا يُبنى بمقاس مخصّص بالنقاط بالوحدة المختارة — فالمستخدم الذي عدّل رقماً
/// واحداً يحصل على مقاسه هو لا على تقريب.
@immutable
class NewDocumentSpec {
  const NewDocumentSpec({
    this.title = '',
    required this.width,
    required this.height,
    required this.unit,
    required this.category,
    this.familyId,
    this.presetId,
    this.fallbackTitle = 'مقاس مخصّص',
    this.dpi = TemplateDocument.defaultDpi,
    this.resolutionUnit = ResolutionUnit.ppi,
    this.colorMode = DocumentColorMode.rgb,
    this.backgroundHex = '#FFFFFF',
    this.isDigital = false,
  });

  /// اسم المشروع كما كتبه المستخدم (قد يكون فارغاً).
  final String title;

  final double width;
  final double height;
  final MeasurementUnit unit;

  /// التصنيف الذي يفتح محرّره (شهادة/عقد).
  final TemplateCategory category;

  /// العائلة المختارة في الشبكة (أو `null` للمقاس المخصّص).
  final String? familyId;

  /// متغيّر المقاس الجاهز المطابق للأبعاد الحالية (عند التطابق التام).
  final String? presetId;

  /// العنوان المستخدم عندما يترك المستخدم حقل الاسم فارغاً.
  final String fallbackTitle;

  /// الدقّة بالنقطة/بوصة (300 للطباعة، 72 للشاشة).
  final int dpi;

  /// وحدة عرض الدقّة (PPI/PPCM).
  final ResolutionUnit resolutionUnit;

  final DocumentColorMode colorMode;

  /// لون الخلفية `#RRGGBB` أو `#AARRGGBB` (وشفاف = `#00000000`).
  final String backgroundHex;

  final bool isDigital;

  /// الدقّة الافتراضية للشاشة والويب.
  static const int screenDpi = 72;

  /// [dpi] بوحدة المستخدم المختارة ([resolutionUnit]) — للعرض والإدخال.
  double get dpiInUnit => resolutionUnit.fromDpi(dpi.toDouble());

  /// الاتجاه مشتقّ من الأبعاد: العرض الأكبر = أفقي.
  PageOrientation get orientation => width > height
      ? PageOrientation.landscape
      : PageOrientation.portrait;

  double get widthPt => unit.toPoints(width);
  double get heightPt => unit.toPoints(height);

  /// اللون الشفاف — يُبنى به «خلفية شفافة» في لوحة التفاصيل.
  static const String transparentHex = '#00000000';

  /// مواصفة أولية لعائلة مقاس: تُختار أبعاد الاتجاه المطلوب ودقّته الافتراضية.
  factory NewDocumentSpec.fromFamily(
    ProjectPresetFamily family,
    PageOrientation orientation, {
    NewDocumentSpec? keep,
  }) {
    final ProjectPreset? variant = family.variantFor(orientation);
    final bool digital = family.isDigital;
    return NewDocumentSpec(
      title: keep?.title ?? '',
      width: family.widthFor(orientation),
      height: family.heightFor(orientation),
      unit: family.unit,
      category: variant?.category ?? TemplateCategory.certificate,
      familyId: family.id,
      presetId: variant?.id,
      fallbackTitle: family.title,
      dpi: keep?.dpi ?? (digital ? screenDpi : TemplateDocument.defaultDpi),
      resolutionUnit: keep?.resolutionUnit ?? ResolutionUnit.ppi,
      colorMode:
          keep?.colorMode ??
              (digital ? DocumentColorMode.rgb : DocumentColorMode.cmyk),
      backgroundHex: keep?.backgroundHex ?? '#FFFFFF',
      isDigital: digital,
    );
  }

  /// مواصفة مقاس مخصّص (بلا مقاس جاهز) — 120×80 ملم افتراضاً.
  ///
  /// تبدأ بنيّة طباعة (CMYK و300 نقطة/بوصة) لأن المقاس المخصّص في هذه المنصّة
  /// مقاس طباعة في الغالب؛ ومن أراد الشاشة يبدّل النمط والدقّة من اللوحة.
  factory NewDocumentSpec.custom({
    double width = 120,
    double height = 80,
    MeasurementUnit unit = MeasurementUnit.mm,
    String fallbackTitle = 'مقاس مخصّص',
  }) =>
      NewDocumentSpec(
        width: width,
        height: height,
        unit: unit,
        category: TemplateCategory.certificate,
        fallbackTitle: fallbackTitle,
        colorMode: DocumentColorMode.cmyk,
      );

  /// نسخة معدّلة. تُفرّق `_unset` بين «لم تُمرَّر» و«صُفِّرت» لـ[presetId].
  NewDocumentSpec copyWith({
    String? title,
    double? width,
    double? height,
    MeasurementUnit? unit,
    TemplateCategory? category,
    Object? familyId = _unset,
    Object? presetId = _unset,
    String? fallbackTitle,
    int? dpi,
    ResolutionUnit? resolutionUnit,
    DocumentColorMode? colorMode,
    String? backgroundHex,
    bool? isDigital,
  }) =>
      NewDocumentSpec(
        title: title ?? this.title,
        width: width ?? this.width,
        height: height ?? this.height,
        unit: unit ?? this.unit,
        category: category ?? this.category,
        familyId: familyId == _unset ? this.familyId : familyId as String?,
        presetId: presetId == _unset ? this.presetId : presetId as String?,
        fallbackTitle: fallbackTitle ?? this.fallbackTitle,
        dpi: dpi ?? this.dpi,
        resolutionUnit: resolutionUnit ?? this.resolutionUnit,
        colorMode: colorMode ?? this.colorMode,
        backgroundHex: backgroundHex ?? this.backgroundHex,
        isDigital: isDigital ?? this.isDigital,
      );

  /// نسخة بالاتجاه المعاكس: تُقلب الأبعاد ويُتبنّى متغيّر العائلة المقابل إن وُجد.
  ///
  /// هذا هو ما يجعل زرّي «رأسي/أفقي» يبدّلان القيم فعلاً بدل أن يكونا زينة:
  /// A4 أفقي (29.7×21 سم) يصبح A4 رأسي (21×29.7 سم) بمقاسه القياسي، ومقاساً
  /// بلا متغيّر مقابل يُقلب على مقاس مخصّص.
  NewDocumentSpec flipped(ProjectPresetFamily? family) {
    final NewDocumentSpec swapped = copyWith(width: height, height: width);
    final ProjectPreset? variant = family?.variantFor(swapped.orientation);
    if (variant == null) {
      return swapped.copyWith(presetId: null);
    }
    return swapped.copyWith(
      width: variant.pageWidth,
      height: variant.pageHeight,
      unit: variant.unit,
      presetId: variant.id,
      category: variant.category,
    );
  }

  /// تبنّي «نوع» آخر بالمقاس نفسه (كتاب/مجلة/تقرير A4).
  ///
  /// يُحدَّث العنوان الاحتياطي أيضاً كي يكون الاسم الافتراضي للمشروع هو اسم
  /// النوع المختار («تقرير A4») لا اسم العائلة العام («A4»).
  NewDocumentSpec adoptVariant(ProjectPreset variant) => copyWith(
        width: variant.pageWidth,
        height: variant.pageHeight,
        unit: variant.unit,
        presetId: variant.id,
        category: variant.category,
        isDigital: variant.isDigital,
        fallbackTitle: variant.titleAr,
      );

  /// هل تطابق الأبعاد الحالية مقاس المتغيّر [preset] (بتسامح نصف نقطة)؟
  bool matchesPreset(ProjectPreset preset) {
    const double tolerance = 0.5;
    return (preset.unit.toPoints(preset.pageWidth) - widthPt).abs() <= tolerance &&
        (preset.unit.toPoints(preset.pageHeight) - heightPt).abs() <= tolerance;
  }

  /// الأبعاد معروضةً بوحدة [unit] (تُستخدم في المعاينة النصّية).
  String get dimensionsLabel =>
      '${ProjectPreset.formatDimension(width)} × '
      '${ProjectPreset.formatDimension(height)} ${unit.labelAr}';

  /// المستند الفعلي الذي يُفتح في اللوحة — بالمقاس والدقّة والنمط والخلفية.
  TemplateDocument toDocument() {
    final ProjectPreset? preset =
        presetId == null ? null : ProjectPresetCatalog.byId(presetId!);
    final TemplateDocument base = preset != null && matchesPreset(preset)
        ? preset.toDocument()
        : buildCustomDocument(width: width, height: height, unit: unit);
    return base.copyWith(
      dpi: dpi,
      resolutionUnit: resolutionUnit,
      colorMode: colorMode,
      backgroundHex: backgroundHex,
    );
  }

  /// مسودة المحرّر: العنوان المكتوب أو عنوان العائلة/المقاس المخصّص.
  TemplateDraft toDraft() {
    final String name = title.trim();
    return TemplateDraft(
      title: name.isEmpty ? fallbackTitle : name,
      category: category,
      document: toDocument(),
    );
  }
}

/// قيمة «غير مُمرَّرة» للتفريق بين تمرير `null` صراحةً وعدم التمرير.
const Object _unset = Object();
