import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show TextEditingController;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/templates/new_document_spec.dart';
import '../../../../core/templates/project_preset.dart';
import '../../../../core/templates/template_draft.dart';

/// نطاق العرض في تبويبات نافذة «مستند جديد».
///
/// التبويبات **نطاقات حصرية** لا مرشّحات متراكبة:
///
/// * [recent] — ما أنشأه المستخدم فعلاً في هذه الجلسة.
/// * [singleSheet] — المطبوعات المفردة المطبوعة (شهادات، بطاقات، أرقام جلوس،
///   كروت معايدة ورقية).
/// * [multiPage] — الكتب والمنشورات متعددة الصفحات.
/// * [social] — المقاسات **الرقمية** بالبكسل (قصة/حالة، منشور مربّع) أياً كان
///   قسمها، فتجدها من مكان واحد.
enum NewDocumentScope {
  recent('recent'),
  singleSheet('single'),
  multiPage('multi'),
  social('social');

  const NewDocumentScope(this.jsonValue);

  final String jsonValue;

  /// النطاق الذي تنتمي إليه عائلة مقاس (الرقمي يتقدّم على قسمه).
  static NewDocumentScope? of(ProjectPresetFamily family) {
    if (family.isDigital) return NewDocumentScope.social;
    return switch (family.kind) {
      ProjectKind.singleSheet => NewDocumentScope.singleSheet,
      ProjectKind.multiPage => NewDocumentScope.multiPage,
    };
  }

  /// النطاق المناسب لمجموعة مقاسات (عند الفتح من وحدة بعينها).
  static NewDocumentScope forGroup(ProjectPresetGroup group) =>
      group == ProjectPresetGroup.publications
          ? NewDocumentScope.multiPage
          : NewDocumentScope.singleSheet;
}

/// حالة نافذة «مستند جديد» كاملة في `ChangeNotifier` واحد.
///
/// سبب وجودها: الاختيار حالة **مشتركة** بين الشبكة المصغّرة (اليسار) ولوحة
/// التفاصيل (اليمين) — شبكة ترسل «اختير مقاس A4»، ولوحة تقرأ المقاس وتكتب
/// الحقول. حبسها في `setState` واحد كان يجبر التخطيط كله على إعادة البناء
/// ويجعل الاختيار غير قابل للاختبار وحده. هنا:
///
/// * الشبكة واللوحة تستهلكان `context.watch<NewDocumentController>()`.
/// * كل تحويلة صغيرة (اتجاه، وحدة، دقّة، خلفية…) دالة واحدة على الحالة تعرف
///   كيف تُترجم إلى [NewDocumentSpec]، ومعها اختباراتها بلا واجهة.
/// * [buildDraft] هي **نقطة الخروج الوحيدة**: ما تراه اللوحة هو ما يُفتح.
class NewDocumentController extends ChangeNotifier {
  /// [initialCategory] يضبط **الاتجاه المفضّل** للاختيار الأول: الفتح من محرّك
  /// الشهادات يجعل اختيار A4 يفتح نسخته الأفقية، والفتح من محرّك العقود يفتح
  /// نسخته الرأسية — بلا أن يُقيّد المستخدم بعد ذلك.
  NewDocumentController({
    NewDocumentScope? initialScope,
    ProjectPresetGroup? initialGroup,
    TemplateCategory? initialCategory,
  })  : _scope = initialScope ??
            (initialGroup != null
                ? NewDocumentScope.forGroup(initialGroup)
                : NewDocumentScope.singleSheet),
        _group = initialGroup,
        _preferredOrientation = switch (initialCategory) {
          TemplateCategory.certificate => PageOrientation.landscape,
          TemplateCategory.contract => PageOrientation.portrait,
          null => null,
        } {
    _fallback = _buildFallbackSpec();
  }

  /// حقل بحث الشبكة (تملكه الحالة لأن الكتابة مؤقتة لا تُحفظ في المستند).
  final TextEditingController search = TextEditingController();

  /// حقل اسم المشروع.
  final TextEditingController title = TextEditingController();

  final PageOrientation? _preferredOrientation;

  NewDocumentScope _scope;
  ProjectPresetGroup? _group;
  bool _customOnly = false;
  String _query = '';
  NewDocumentSpec? _spec;

  /// المواصفة المعروضة قبل أن يختار المستخدم مقاساً — تُبنى من أوّل مقاس في
  /// النطاق الحالي وتُعاد بناؤها عند تبديل النطاق ما دام الاختيار فارغاً.
  late NewDocumentSpec _fallback;

  /// مقاسات **أُنشئت فعلاً** في هذه الجلسة (تبويب «الأحدث»).
  ///
  /// ساكنة عن قصد: تبقى محفوظة أثناء تنقّل المستخدم بين النافذة والمحرّر في
  /// الجلسة نفسها، وتُصفَّر بإعادة تحميل التطبيق (لا تخزين دائم لها).
  static final List<String> recentFamilyIds = <String>[];

  static const int _maxRecent = 8;

  /// تصفير قائمة الأحدث (تستخدمه الاختبارات لتبقى معزولة).
  static void debugClearRecent() => clearRecentSizes();

  /// تفريغ قائمة «الأبعاد الأخيرة» بلا حاجة إلى نسخة متحكّم.
  ///
  /// القائمة **ساكنة** (عمرها عمر الجلسة لا عمر النافذة)، فتفريغها أمر عام
  /// تنفّذه قائمة «تعديل» في شريط القوائم من أي شاشة.
  static void clearRecentSizes() => recentFamilyIds.clear();

  NewDocumentScope get scope => _scope;
  ProjectPresetGroup? get groupFilter => _group;
  bool get customOnly => _customOnly;
  String get query => _query;
  NewDocumentSpec? get spec => _spec;

  /// المواصفة **الفعّالة** التي تعرضها لوحة التفاصيل وتُحرَّر منها الحقول.
  ///
  /// لا تكون فارغة أبداً: ما دام المستخدم لم يختر مقاساً تُعاد مواصفة
  /// **افتراضية** (أوّل مقاس في النطاق باتجاه الوحدة التي فُتحت منها النافذة)،
  /// فأوّل تعديل على أيّ حقل يُثبّتها اختياراً حقيقياً.
  NewDocumentSpec get activeSpec => _spec ?? _fallback;

  bool get hasSelection => _spec != null;

  /// المواصفة الافتراضية: أوّل مقاس في النطاق الحالي (وإلا أوّل مقاس في
  /// الفهرس حين يكون النطاق فارغاً — تبويب «الأحدث» قبل أي إنشاء مثلاً).
  NewDocumentSpec _buildFallbackSpec() {
    final List<ProjectPresetFamily> pool =
        scopedFamilies.isEmpty ? ProjectPresetFamilies.all : scopedFamilies;
    final ProjectPresetFamily family = pool.first;
    // الرأسي هو الافتراضي المحايد (وثائق)، ويفرض الاتجاه وحدةُ الطلب إن جاءت.
    final PageOrientation preferred =
        _preferredOrientation ?? PageOrientation.portrait;
    final PageOrientation orientation = family.variantFor(preferred) != null
        ? preferred
        : family.variants.first.orientation;
    return NewDocumentSpec.fromFamily(family, orientation);
  }

  /// كل عائلات النطاق الحالي (بلا مرشّحات فرعية).
  List<ProjectPresetFamily> get scopedFamilies => switch (_scope) {
        NewDocumentScope.recent => <ProjectPresetFamily>[
            for (final String id in recentFamilyIds)
              if (ProjectPresetFamilies.byId(id)
                  case final ProjectPresetFamily family)
                family,
          ],
        NewDocumentScope.singleSheet => ProjectPresetFamilies.all
            .where((ProjectPresetFamily f) =>
                NewDocumentScope.of(f) == NewDocumentScope.singleSheet)
            .toList(growable: false),
        NewDocumentScope.multiPage => ProjectPresetFamilies.all
            .where((ProjectPresetFamily f) =>
                NewDocumentScope.of(f) == NewDocumentScope.multiPage)
            .toList(growable: false),
        NewDocumentScope.social => ProjectPresetFamilies.all
            .where((ProjectPresetFamily f) =>
                NewDocumentScope.of(f) == NewDocumentScope.social)
            .toList(growable: false),
      };

  /// مجموعات النطاق الحالي **التي فيها مقاسات فعلاً** (لبطاقات التصفية).
  List<ProjectPresetGroup> get availableGroups {
    final Set<ProjectPresetGroup> used = <ProjectPresetGroup>{
      for (final ProjectPresetFamily family in scopedFamilies) family.group,
    };
    return ProjectPresetGroup.values
        .where(used.contains)
        .toList(growable: false);
  }

  /// هل يظهر قرص «مقاس مخصّص» في هذا النطاق؟ (المقاس المخصّص ورقي مفرد).
  bool get customAvailable =>
      _scope == NewDocumentScope.singleSheet ||
      _scope == NewDocumentScope.recent;

  /// ما تعرضه الشبكة الآن: النطاق ثم التصفية ثم البحث.
  List<ProjectPresetFamily> get visibleFamilies {
    if (_customOnly) return const <ProjectPresetFamily>[];
    List<ProjectPresetFamily> list = scopedFamilies;
    final ProjectPresetGroup? group = _group;
    if (group != null) {
      list = list
          .where((ProjectPresetFamily family) => family.group == group)
          .toList(growable: false);
    }
    return list
        .where((ProjectPresetFamily family) => family.matches(_query))
        .toList(growable: false);
  }

  /// هل تظهر بطاقة «مقاس مخصّص» في الشبكة الآن؟ (يطلبها قرص Custom).
  bool get showCustomTile {
    if (!_customOnly) return false;
    final String needle = _query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return 'مقاس مخصّص custom مخصص'.toLowerCase().contains(needle);
  }

  /// هل النطاق الحالي فارغ بعد المرشّحات (لرسالة الفراغ)؟
  bool get isEmptyScope => visibleFamilies.isEmpty && !showCustomTile;

  // ==========================================================================
  //                              التصفية
  // ==========================================================================

  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  /// تبديل تبويب النطاق — يُصفّر المرشّحات الفرعية والاختيار المخصّص.
  void selectScope(NewDocumentScope scope) {
    if (_scope == scope) return;
    _scope = scope;
    _group = null;
    _customOnly = false;
    // ما دام لا اختيار، فاللوحة تتبع النطاق الجديد بأوّل مقاس فيه.
    if (_spec == null) _fallback = _buildFallbackSpec();
    notifyListeners();
  }

  void setGroupFilter(ProjectPresetGroup? group) {
    _group = group;
    _customOnly = false;
    notifyListeners();
  }

  void toggleGroupFilter(ProjectPresetGroup group) {
    setGroupFilter(_group == group ? null : group);
  }

  void showAll() {
    _group = null;
    _customOnly = false;
    notifyListeners();
  }

  // ==========================================================================
  //                              الاختيار
  // ==========================================================================

  /// اختيار عائلة من الشبكة.
  ///
  /// الاتجاه الافتراضي: الاتجاه المفضّل (إن جاء من وحدة معروفة وكان متاحاً في
  /// هذه العائلة)، وإلا **الاتجاه الطبيعي للعائلة** نفسه الذي تعرضه البطاقة —
  /// فلا يخالف الاختيار ما رآه المستخدم. وإن أُعيد اختيار المقاس المفتوح حالياً
  /// يُحفظ الاتجاه الذي ضبطه بنفسه.
  void selectFamily(ProjectPresetFamily family) {
    final NewDocumentSpec? current = _spec;
    final PageOrientation preferred = _preferredOrientation ??
        family.variants.first.orientation;
    final PageOrientation orientation =
        current != null && current.familyId == family.id
            ? current.orientation
            : (family.variantFor(preferred) != null
                ? preferred
                : family.variants.first.orientation);
    _customOnly = false;
    _setSpec(NewDocumentSpec.fromFamily(family, orientation));
    title.text = '';
  }

  /// اختيار «مقاس مخصّص» — [fallbackTitle] يأتي من الترجمة في طبقة الواجهة.
  void selectCustom(String fallbackTitle) {
    _customOnly = true;
    _group = null;
    _setSpec(NewDocumentSpec.custom(fallbackTitle: fallbackTitle));
    title.text = '';
  }

  void setTitle(String value) =>
      _update((NewDocumentSpec spec) => spec.copyWith(title: value));

  void setWidth(double value) =>
      _update((NewDocumentSpec spec) => spec.copyWith(width: value));

  void setHeight(double value) =>
      _update((NewDocumentSpec spec) => spec.copyWith(height: value));

  /// تغيير وحدة العرض مع **الحفاظ على المقاس الفيزيائي** نفسه.
  void setUnit(MeasurementUnit unit) {
    final NewDocumentSpec spec = activeSpec;
    if (spec.unit == unit) return;
    _setSpec(
      spec.copyWith(
        unit: unit,
        width: _round2(unit.fromPoints(spec.widthPt)),
        height: _round2(unit.fromPoints(spec.heightPt)),
      ),
    );
  }

  /// زرّا الاتجاه: يقلبان الأبعاد فعلاً ويتبنّيان متغيّر العائلة المقابل.
  void setOrientation(PageOrientation orientation) {
    final NewDocumentSpec spec = activeSpec;
    if (spec.orientation == orientation) return;
    _setSpec(spec.flipped(ProjectPresetFamilies.byId(spec.familyId)));
  }

  void setDpi(int value) => _update(
      (NewDocumentSpec spec) => spec.copyWith(dpi: value < 1 ? 1 : value));

  void setResolutionUnit(ResolutionUnit unit) => _update(
        (NewDocumentSpec spec) => spec.copyWith(
          resolutionUnit: unit,
          dpi: unit.toDpi(unit.fromDpi(spec.dpi.toDouble())).round(),
        ),
      );

  void setColorMode(DocumentColorMode mode) =>
      _update((NewDocumentSpec spec) => spec.copyWith(colorMode: mode));

  void setBackground(String hex) =>
      _update((NewDocumentSpec spec) => spec.copyWith(backgroundHex: hex));

  /// تبنّي «نوع» آخر بالمقاس نفسه (كتاب/مجلة/تقرير A4).
  void adoptVariant(ProjectPreset variant) =>
      _update((NewDocumentSpec spec) => spec.adoptVariant(variant));

  /// مسودة المشروع الجاهزة للفتح، وتسجيل المقاس في «الأحدث».
  ///
  /// لا تُعيد `null` أبداً: لوحة التفاصيل معبّأة دائماً بمواصفة (المختارة أو
  /// الافتراضية) فيعمل «إنشاء» من أول لحظة بلا صمتٍ محيّر.
  TemplateDraft buildDraft() {
    final NewDocumentSpec spec = activeSpec;
    _rememberRecent(spec.familyId);
    return spec.toDraft();
  }

  /// تفريغ قائمة «الأبعاد الأخيرة» من داخل نافذة مفتوحة (مع إشعار الواجهة
  /// فتُحدَّث شبكة تبويب «الأحدث» فوراً).
  void clearRecent() {
    if (recentFamilyIds.isEmpty) return;
    clearRecentSizes();
    notifyListeners();
  }

  void _setSpec(NewDocumentSpec spec) {
    _spec = spec;
    notifyListeners();
  }

  /// تعديل حقل: يعمل على المواصفة الفعّالة، فأول تعديل على المواصفة
  /// الافتراضية **يُثبّتها** اختياراً حقيقياً بدل أن يضيع في الفراغ.
  void _update(NewDocumentSpec Function(NewDocumentSpec spec) update) =>
      _setSpec(update(activeSpec));

  static void _rememberRecent(String? familyId) {
    if (familyId == null) return;
    recentFamilyIds.remove(familyId);
    recentFamilyIds.insert(0, familyId);
    if (recentFamilyIds.length > _maxRecent) {
      recentFamilyIds.removeRange(_maxRecent, recentFamilyIds.length);
    }
  }

  static double _round2(double value) => (value * 100).roundToDouble() / 100;

  @override
  void dispose() {
    search.dispose();
    title.dispose();
    super.dispose();
  }
}
