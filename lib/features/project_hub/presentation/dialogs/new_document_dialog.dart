import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/editor/widgets/editor_controls.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/templates/new_document_spec.dart';
import '../../../../core/templates/project_preset.dart';
import '../../../../core/templates/template_draft.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/hex_color.dart';
import '../providers/new_document_controller.dart';
import '../widgets/photoshop_paper_icon.dart';

/// مفاتيح ثابتة للنافذة — مصدر واحد للاختبارات والتنقّل البرمجي.
abstract final class NewDocumentKeys {
  const NewDocumentKeys._();

  static const String window = 'new-doc-window';
  static const String backdrop = 'new-doc-backdrop';
  static const String closeButton = 'new-doc-close';
  static const String searchField = 'new-doc-search';
  static const String grid = 'new-doc-grid';
  static const String filterAll = 'new-doc-filter-all';
  static const String filterCustom = 'new-doc-filter-custom';
  static const String customTile = 'new-doc-custom-tile';
  static const String detailsPane = 'new-doc-details';
  static const String detailsHint = 'new-doc-details-hint';
  static const String titleField = 'new-doc-title';
  static const String widthField = 'new-doc-width';
  static const String heightField = 'new-doc-height';
  static const String unitField = 'new-doc-unit';
  static const String portrait = 'new-doc-orientation-portrait';
  static const String landscape = 'new-doc-orientation-landscape';
  static const String dpiField = 'new-doc-dpi';
  static const String resolutionUnit = 'new-doc-resolution-unit';
  static const String colorMode = 'new-doc-color-mode';
  static const String background = 'new-doc-background';
  static const String createButton = 'new-doc-create';
  static const String cancelButton = 'new-doc-cancel';

  static String tab(NewDocumentScope scope) => 'new-doc-tab-${scope.jsonValue}';

  static String family(String id) => 'new-doc-family-$id';

  static String groupFilter(ProjectPresetGroup group) =>
      'new-doc-filter-${group.jsonValue}';
}

/// يفتح «مستند جديد» كنافذة عائمة فوق مساحة العمل الحالية ويُعيد المسودة.
///
/// * تُستدعى من أي شاشة (لوحة التحكم، محرّك الشهادات، محرّك العقود…) بلا مغادرة
///   السياق: النافذة تظهر فوق ما يعمل عليه المستخدم لا في صفحة منفصلة.
/// * [initialCategory] يوجّه النافذة إلى الوحدة التي جاء منها الطلب: تفتح على
///   مجموعة مقاساتها، ويكون **الاتجاه المفضّل** لأول اختيار هو اتجاه تلك الوحدة
///   (أفقي للشهادات، رأسي للعقود).
/// * تُعيد `null` عند الإلغاء أو الإغلاق أو النقر على الخلفية.
Future<TemplateDraft?> showNewDocumentDialog(
  BuildContext context, {
  NewDocumentScope? initialScope,
  ProjectPresetGroup? initialGroup,
  TemplateCategory? initialCategory,
}) {
  return showGeneralDialog<TemplateDraft?>(
    context: context,
    // الستارة الخاصة بنا (تلطّي الخلفية وتتولّى الإغلاق بالنقر) فتحلّ محل
    // ستارة الطريق القياسية وتسمح بتمويه مساحة العمل خلف النافذة.
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (
      BuildContext dialogContext,
      Animation<double> primary,
      Animation<double> secondary,
    ) =>
        NewDocumentDialog(
      initialScope: initialScope,
      initialGroup: initialGroup,
      initialCategory: initialCategory,
    ),
    transitionBuilder: (
      BuildContext dialogContext,
      Animation<double> animation,
      Animation<double> secondary,
      Widget child,
    ) {
      final Animation<double> curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// يفتح النافذة ثم **يفتح المحرّر بالمسودة المختارة** عند «إنشاء».
///
/// إن أُلغيت النافذة لا يحدث شيء — فلا تنقّل بلا قرار من المستخدم.
Future<void> openNewDocumentDialog(
  BuildContext context, {
  NewDocumentScope? initialScope,
  ProjectPresetGroup? initialGroup,
  TemplateCategory? initialCategory,
}) async {
  final TemplateDraft? draft = await showNewDocumentDialog(
    context,
    initialScope: initialScope,
    initialGroup: initialGroup,
    initialCategory: initialCategory,
  );
  if (draft == null || !context.mounted) return;
  context.go(
    draft.category == TemplateCategory.contract
        ? AppRoutes.contractBuilder
        : AppRoutes.certificateBuilder,
    extra: draft,
  );
}

/// نافذة «مستند جديد» العائمة — بطراز نوافذ برامج التحرير الاحترافية.
///
/// * نافذة بمقاس ثابت **800×550** في وسط الشاشة، بزوايا 8px وحدّ `#333333`
///   (تتقلّص بأمان فقط إن ضاقت مساحة الطريق عن المقاس، فلا تُقتطع أبداً).
/// * سطح داكن ثابت (‎`#232323`/`#1E1E1E`‎) **مستقلّ عن مظهر التطبيق**: يظهر
///   هو نفسه في الوضعين الفاتح والداكن عبر [Theme] محلي خاص بالنافذة.
/// * خلفها ستارة `0xCC000000` مع تمويه خفيف لمساحة العمل، والنقر عليها يُلغِي.
class NewDocumentDialog extends StatefulWidget {
  const NewDocumentDialog({
    super.key,
    this.initialScope,
    this.initialGroup,
    this.initialCategory,
  });

  final NewDocumentScope? initialScope;
  final ProjectPresetGroup? initialGroup;
  final TemplateCategory? initialCategory;

  /// عرض النافذة الثابت (px) — مقاس نافذة «مستند جديد» المعتمد.
  static const double windowWidth = 800;

  /// ارتفاع النافذة الثابت (px) — يجعل الشبكة ولوحة التفاصيل مرئيتين معاً
  /// بلا تمرير رأسي مزدحم، كما في حوارات Photoshop.
  static const double windowHeight = 550;

  @override
  State<NewDocumentDialog> createState() => _NewDocumentDialogState();
}

class _NewDocumentDialogState extends State<NewDocumentDialog> {
  late final NewDocumentController _controller = NewDocumentController(
    initialScope: widget.initialScope,
    initialGroup: widget.initialGroup,
    initialCategory: widget.initialCategory,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// إغلاق بلا إنشاء.
  void _cancel() => Navigator.of(context).pop();

  /// إنشاء: تُغلق النافذة أولاً ثم تُعاد المسودة إلى طالبها.
  ///
  /// المسودة غير قابلة للعدم: لوحة التفاصيل معبّأة دائماً بمواصفة (المختارة
  /// أو الافتراضية)، فزرّ «إنشاء» لا يبدو معطّلاً بلا سبب.
  void _create() => Navigator.of(context).pop(_controller.buildDraft());

  @override
  Widget build(BuildContext context) {
    // المقاس من المساحة المتاحة فعلاً للطريق (لا من مقاس الشاشة): على الشاشات
    // الصغيرة تتقلّص النافذة مع هوامش آمنة بدل أن تُقتطع.
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): _cancel,
      },
      child: Focus(
        autofocus: true,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double availableWidth = constraints.maxWidth;
            final double availableHeight = constraints.maxHeight;
            final double width = (availableWidth.isFinite
                    ? availableWidth - AppTheme.space48
                    : NewDocumentDialog.windowWidth)
                .clamp(280, NewDocumentDialog.windowWidth);
            final double height = (availableHeight.isFinite
                    ? availableHeight - AppTheme.space48
                    : NewDocumentDialog.windowHeight)
                .clamp(280, NewDocumentDialog.windowHeight);
            return Stack(
          children: <Widget>[
            // الستارة: تمويه خلفي + طبقة داكنة ‎0xCC000000‎ + نقر للإلغاء.
            Positioned.fill(
              child: GestureDetector(
                key: const ValueKey<String>(NewDocumentKeys.backdrop),
                behavior: HitTestBehavior.opaque,
                onTap: _cancel,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(color: AppColors.dialogBackdrop),
                ),
              ),
            ),
            Center(
              child: Theme(
                // ثيم النافذة المحلي: أسطح Photoshop الداكنة والأزرق الأساسي.
                data: _dialogTheme(context),
                child: ChangeNotifierProvider<NewDocumentController>.value(
                  value: _controller,
                  child: Container(
                    key: const ValueKey<String>(NewDocumentKeys.window),
                    width: width,
                    height: height,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.dialogSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.dialogBorder),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 28,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    // `Material` ضروري: نافذة `showGeneralDialog` ليست `Dialog`،
                    // فبلا سطح Material لا تعمل أشرطة الحبر (InkWell) ولا
                    // الخلفيات المعتمدة على السطح داخل النافذة.
                    child: Material(
                      color: AppColors.dialogSurface,
                      child: Column(
                        children: <Widget>[
                          _header(context),
                          Expanded(
                            child: NewDocumentBody(
                              onCreate: _create,
                              onCancel: _cancel,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// شريط عنوان النافذة: العنوان ثم زر الإغلاق (يُقلب تلقائياً في RTL).
  Widget _header(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsetsDirectional.only(
        start: AppTheme.space16,
        end: AppTheme.space6,
      ),
      decoration: const BoxDecoration(
        color: AppColors.dialogHeader,
        border: Border(
          bottom: BorderSide(color: AppColors.dialogBorder),
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.insert_drive_file_outlined,
              size: 16, color: AppColors.dialogAccent),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            child: Text(
              context.l10n?.newDocTitle ?? 'مستند جديد',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.dialogInk,
              ),
            ),
          ),
          IconButton(
            key: const ValueKey<String>(NewDocumentKeys.closeButton),
            onPressed: _cancel,
            tooltip: context.l10n?.editorClose ?? 'إغلاق',
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            color: AppColors.dialogInkMuted,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

/// ثيم داكن خاص بالنافذة — لا يُشتقّ من مظهر التطبيق عن قصد.
///
/// نافذة «مستند جديد» لوحة عمل داكنة الطراز: تبقى هي نفسها في الوضعين الفاتح
/// والداكن (كما تفعل نوافذ Photoshop)، ونُعيد هنا تلوين كل الأسطح والحدود
/// والنصوص عبر `colorScheme` فيتبعها كل حقل وزر جاهز في التطبيق بلا تعديله.
ThemeData _dialogTheme(BuildContext context) {
  const ColorScheme scheme = ColorScheme.dark(
    primary: AppColors.dialogAccent,
    onPrimary: Colors.white,
    primaryContainer: AppColors.dialogAccentContainer,
    onPrimaryContainer: Color(0xFFD3E7FF),
    secondary: AppColors.dialogAccent,
    onSecondary: Colors.white,
    surface: AppColors.dialogSurface,
    onSurface: AppColors.dialogInk,
    onSurfaceVariant: AppColors.dialogInkMuted,
    outline: AppColors.dialogBorder,
    outlineVariant: AppColors.dialogBorder,
    surfaceContainerHighest: AppColors.dialogElevated,
    surfaceContainerHigh: AppColors.dialogElevated,
    error: Color(0xFFE5484D),
    onError: Colors.white,
  );
  // نبدأ من المظهر الداكن الرسمي (فنرث الخطوط والكثافة وسلوك الأزرار) ثم
  // نستبدل الأسطح والحقول بألوان النافذة، فتبقى نافذة واحدة متناسقة.
  final ThemeData base = AppTheme.dark;
  return base.copyWith(
    brightness: Brightness.dark,
    colorScheme: scheme,
    canvasColor: AppColors.dialogSurface,
    dividerColor: AppColors.dialogBorder,
    scaffoldBackgroundColor: AppColors.dialogSurface,
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.dialogInk,
      displayColor: AppColors.dialogInk,
    ),
    // حقول مدمجة داكنة: خلفية `#1E1E1E` وحدّ `#333333` وتركيز أزرق.
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: AppColors.dialogHeader,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space10,
        vertical: AppTheme.space10,
      ),
      hintStyle: const TextStyle(
        fontSize: 12,
        color: AppColors.dialogInkMuted,
      ),
      labelStyle: const TextStyle(
        fontSize: 11.5,
        color: AppColors.dialogInkMuted,
      ),
      floatingLabelStyle: const TextStyle(
        fontSize: 11.5,
        color: AppColors.dialogAccent,
      ),
      prefixIconColor: AppColors.dialogInkMuted,
      suffixIconColor: AppColors.dialogInkMuted,
      border: _dialogBorderField(AppColors.dialogBorder),
      enabledBorder: _dialogBorderField(AppColors.dialogBorder),
      focusedBorder: _dialogBorderField(AppColors.dialogAccent, width: 1.4),
      errorBorder: _dialogBorderField(scheme.error),
      focusedErrorBorder: _dialogBorderField(scheme.error, width: 1.4),
      disabledBorder: _dialogBorderField(AppColors.dialogBorder),
    ),
    iconTheme: const IconThemeData(color: AppColors.dialogInk, size: 18),
    splashColor: AppColors.dialogAccent.withValues(alpha: 0.10),
    highlightColor: AppColors.dialogAccent.withValues(alpha: 0.06),
  );
}

/// حدّ حقل داخل النافذة (زوايا ناعمة 8px).
OutlineInputBorder _dialogBorderField(Color color, {double width = 1}) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      borderSide: BorderSide(color: color, width: width),
    );

/// جسم النافذة: الشبكة المصغّرة (يسار) ولوحة «تفاصيل المقاس» (يمين).
///
/// منفصل عن غلاف النافذة (`NewDocumentDialog`) ليُختبر وحده بلا خيمة، وليُعاد
/// استخدامه في أي حاضر آخر (نافذة منبثقة داخل المحرّر مثلاً).
class NewDocumentBody extends StatelessWidget {
  const NewDocumentBody({
    super.key,
    required this.onCreate,
    required this.onCancel,
  });

  /// يُنفَّذ عند «إنشاء» (الغلاف يغلق النافذة ويعيد المسودة).
  final VoidCallback onCreate;

  /// يُنفَّذ عند «إلغاء».
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final NewDocumentController controller =
        context.watch<NewDocumentController>();
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Widget grid = _presetsArea(context, controller);
        final Widget details = _detailsPane(context, controller);
        // على نافذة ضيّقة تُكدَّس لوحة التفاصيل تحت الشبكة بدل أن تُقتطع.
        if (constraints.maxWidth < 780) {
          return Column(
            children: <Widget>[
              Expanded(child: grid),
              const Divider(height: 1),
              SizedBox(height: 300, child: details),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(child: grid),
            Container(width: 1, color: AppColors.dialogBorder),
            SizedBox(width: 330, child: details),
          ],
        );
      },
    );
  }

  // ==========================================================================
  //                     اليسار: التبويبات والمرشّحات والشبكة
  // ==========================================================================

  Widget _presetsArea(BuildContext context, NewDocumentController controller) {
    final List<ProjectPresetFamily> families = controller.visibleFamilies;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space16,
            AppTheme.space12,
            AppTheme.space16,
            0,
          ),
          child: Row(
            children: <Widget>[
              Expanded(child: _scopeTabs(context, controller)),
              const SizedBox(width: AppTheme.space12),
              SizedBox(
                width: 190,
                child: TextField(
                  key: const ValueKey<String>(NewDocumentKeys.searchField),
                  controller: controller.search,
                  onChanged: controller.setQuery,
                  style: const TextStyle(fontSize: 12.5),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search_rounded, size: 16),
                    hintText: context.l10n?.hubSearchHint ?? 'بحث في المقاسات…',
                    hintStyle: const TextStyle(fontSize: 12),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space16,
            AppTheme.space10,
            AppTheme.space16,
            0,
          ),
          child: _filterPills(context, controller),
        ),
        Expanded(
          child: controller.isEmptyScope
              ? _emptyState(context, controller)
              : GridView(
                  key: const ValueKey<String>(NewDocumentKeys.grid),
                  padding: const EdgeInsets.all(AppTheme.space16),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 186,
                    mainAxisExtent: 136,
                    crossAxisSpacing: AppTheme.space12,
                    mainAxisSpacing: AppTheme.space12,
                  ),
                  children: <Widget>[
                    for (final ProjectPresetFamily family in families)
                      _PresetFamilyCard(
                        key: ValueKey<String>(
                            NewDocumentKeys.family(family.id)),
                        family: family,
                        selected: controller.spec?.familyId == family.id,
                        onTap: () => controller.selectFamily(family),
                      ),
                    if (controller.showCustomTile)
                      _CustomTile(
                        key: const ValueKey<String>(
                            NewDocumentKeys.customTile),
                        title: context.l10n?.hubCustomFamilyTitle ?? 'مقاس مخصّص',
                        onTap: () => controller.selectCustom(
                          context.l10n?.hubCustomFamilyTitle ?? 'مقاس مخصّص',
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  /// تبويبات النطاق: الأحدث | المطبوعات المفردة | المنشورات | الشاشات والمعايدات.
  Widget _scopeTabs(BuildContext context, NewDocumentController controller) {
    final List<({NewDocumentScope scope, String label, IconData icon})> tabs =
        <({NewDocumentScope scope, String label, IconData icon})>[
      (
        scope: NewDocumentScope.recent,
        label: context.l10n?.hubFilterRecent ?? 'الأبعاد الأخيرة',
        icon: Icons.history_rounded,
      ),
      (
        scope: NewDocumentScope.singleSheet,
        label: context.l10n?.hubKindSingle ?? 'المطبوعات والوثائق المفردة',
        icon: Icons.description_outlined,
      ),
      (
        scope: NewDocumentScope.multiPage,
        label: context.l10n?.hubKindMulti ?? 'الكتب والمنشورات متعددة الصفحات',
        icon: Icons.menu_book_outlined,
      ),
      (
        scope: NewDocumentScope.social,
        label: context.l10n?.newDocScopeSocial ?? 'الشاشات والمعايدات',
        icon: Icons.smartphone_rounded,
      ),
    ];
    // بلا فواصل بين التبويبات: مؤشّرات الخطّ السفلي تتلاصق فتصنع شريط تبويبات
    // واحداً متّصلاً كما في Photoshop بدل أقراص منفصلة.
    return Row(
      children: <Widget>[
        for (int i = 0; i < tabs.length; i++)
          Expanded(
            child: _ScopeTab(
              key: ValueKey<String>(NewDocumentKeys.tab(tabs[i].scope)),
              label: tabs[i].label,
              icon: tabs[i].icon,
              selected: controller.scope == tabs[i].scope,
              onTap: () => controller.selectScope(tabs[i].scope),
            ),
          ),
      ],
    );
  }

  /// مرشّحات فرعية: الكل + مجموعات النطاق + مقاس مخصّص.
  Widget _filterPills(BuildContext context, NewDocumentController controller) {
    final List<Widget> pills = <Widget>[
      _FilterPill(
        key: const ValueKey<String>(NewDocumentKeys.filterAll),
        label: context.l10n?.hubFilterAll ?? 'الكل',
        selected: controller.groupFilter == null && !controller.customOnly,
        onTap: controller.showAll,
      ),
      for (final ProjectPresetGroup group in controller.availableGroups)
        _FilterPill(
          key: ValueKey<String>(NewDocumentKeys.groupFilter(group)),
          label: _groupLabel(context, group),
          icon: group.icon,
          selected: controller.groupFilter == group && !controller.customOnly,
          onTap: () => controller.toggleGroupFilter(group),
        ),
      if (controller.customAvailable)
        _FilterPill(
          key: const ValueKey<String>(NewDocumentKeys.filterCustom),
          label: context.l10n?.hubCustomFamilyTitle ?? 'مقاس مخصّص',
          icon: Icons.add_rounded,
          selected: controller.customOnly,
          onTap: () {
            if (controller.customOnly) {
              controller.showAll();
            } else {
              controller.selectCustom(
                context.l10n?.hubCustomFamilyTitle ?? 'مقاس مخصّص',
              );
            }
          },
        ),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (int i = 0; i < pills.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: AppTheme.space6),
            pills[i],
          ],
        ],
      ),
    );
  }

  /// تسمية المرشّح الفرعي — **مختصرة عن قصد**: أقراص النافذة تقف في سطر واحد
  /// بلا تمرير (اسم «الكروت وبطاقات الهوية» يدفع البقية خارج الشاشة).
  String _groupLabel(BuildContext context, ProjectPresetGroup group) =>
      switch (group) {
        ProjectPresetGroup.certificatesAndContracts =>
          context.l10n?.newDocFilterCertificates ?? 'الشهادات',
        ProjectPresetGroup.cardsAndBadges =>
          context.l10n?.newDocFilterCards ?? 'الكروت',
        ProjectPresetGroup.seatNumbersAndTags =>
          context.l10n?.hubFilterSeat ?? 'أرقام الجلوس',
        ProjectPresetGroup.greetingCards =>
          context.l10n?.newDocFilterGreeting ?? 'المعايدات',
        ProjectPresetGroup.publications =>
          context.l10n?.newDocFilterPublications ?? 'المنشورات',
        ProjectPresetGroup.invitations =>
          context.l10n?.invCategoryTitle ?? 'دعوات ومناسبات',
      };

  Widget _emptyState(BuildContext context, NewDocumentController controller) {
    final String message = controller.scope == NewDocumentScope.recent
        ? (context.l10n?.hubRecentEmpty ??
            'لا مقاسات أخيرة بعد — أي مشروع تنشئه يظهر هنا.')
        : (context.l10n?.hubNoResults ??
            'لا يوجد مقاس مطابق — جرّب كلمة بحث أخرى.');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.search_off_rounded,
                size: 18, color: AppColors.dialogInkMuted),
            const SizedBox(width: AppTheme.space8),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.dialogInkMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  //                     اليمين: لوحة «تفاصيل المقاس»
  // ==========================================================================

  /// لوحة التفاصيل + شريط الإجراءات — **معبّأة دائماً**.
  ///
  /// حين لا يكون هناك مقاس مختار تعرض اللوحة **مواصفة افتراضية** (أول مقاس في
  /// النطاق باتجاه الوحدة التي فُتحت منها النافذة) بدل نصٍّ فارغ، ومعها سطر
  /// تنبيه يوضّح أنها افتراضية. وشريط «إنشاء/إلغاء» صار جزءاً من اللوحة نفسها
  /// فلا يختفي الإجراء الأساسي قبل الاختيار الأول كما كان يحدث سابقاً.
  Widget _detailsPane(BuildContext context, NewDocumentController controller) {
    return Container(
      key: const ValueKey<String>(NewDocumentKeys.detailsPane),
      color: AppColors.dialogSurface,
      child: _detailsContent(context, controller, controller.activeSpec),
    );
  }

  Widget _detailsContent(
    BuildContext context,
    NewDocumentController controller,
    NewDocumentSpec spec,
  ) {
    final ProjectPresetFamily? family =
        ProjectPresetFamilies.byId(spec.familyId);
    final List<ProjectPreset> variants =
        family?.variantsFor(spec.orientation) ?? const <ProjectPreset>[];
    // ما دام المستخدم لم يختر مقاساً فالقيم المعروضة **افتراضية**: نعرضها
    // كاملة (فلا لوحة فارغة) ونعلّم أعلى اللوحة بسطر يوضّح ذلك.
    final bool isDefault = !controller.hasSelection;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        context.l10n?.hubDetailsTitle ?? 'تفاصيل المقاس',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dialogInk,
                        ),
                      ),
                    ),
                    if (spec.isDigital) const _Badge(label: 'رقمي'),
                  ],
                ),
                if (isDefault) ...<Widget>[
                  const SizedBox(height: AppTheme.space6),
                  _DefaultSpecNote(
                    key: const ValueKey<String>(NewDocumentKeys.detailsHint),
                    text: context.l10n?.hubDetailsHint ??
                        'مواصفة افتراضية معبّأة مسبقاً — اختر مقاساً من الشبكة '
                            'أو عدّل الأبعاد لتبدأ.',
                  ),
                ],
                const SizedBox(height: AppTheme.space10),
                _SheetPreview(spec: spec),
                const SizedBox(height: AppTheme.space12),
                TextField(
                  key: const ValueKey<String>(NewDocumentKeys.titleField),
                  controller: controller.title,
                  onChanged: controller.setTitle,
                  style: const TextStyle(fontSize: 12.5),
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: context.l10n?.hubDocTitle ?? 'اسم المشروع',
                    hintText: context.l10n?.hubDocTitleHint ?? 'مشروع جديد - 1',
                    hintStyle: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: AppTheme.space12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: NumberField(
                        key: const ValueKey<String>(NewDocumentKeys.widthField),
                        label: context.l10n?.hubWidth ?? 'العرض',
                        value: spec.width,
                        decimals: 2,
                        min: 1,
                        max: 20000,
                        width: 128,
                        onChanged: controller.setWidth,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space8),
                    Expanded(
                      child: NumberField(
                        key:
                            const ValueKey<String>(NewDocumentKeys.heightField),
                        label: context.l10n?.hubHeight ?? 'الارتفاع',
                        value: spec.height,
                        decimals: 2,
                        min: 1,
                        max: 20000,
                        width: 128,
                        onChanged: controller.setHeight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: DropdownField<MeasurementUnit>(
                        key: const ValueKey<String>(
                            NewDocumentKeys.unitField),
                        label: context.l10n?.hubUnitLabel ?? 'الوحدة',
                        value: spec.unit,
                        items: MeasurementUnit.values,
                        width: 132,
                        labelOf: (MeasurementUnit unit) => unit.labelAr,
                        onChanged: controller.setUnit,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space8),
                    Expanded(
                      child: NumberField(
                        key: const ValueKey<String>(NewDocumentKeys.dpiField),
                        label: context.l10n?.hubResolutionLabel ?? 'الدقّة',
                        value: spec.dpi.toDouble(),
                        min: 24,
                        max: 1200,
                        step: 1,
                        width: 132,
                        unit: 'DPI',
                        onChanged: (double value) =>
                            controller.setDpi(value.round()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space10),
                DropdownField<ResolutionUnit>(
                  key: const ValueKey<String>(NewDocumentKeys.resolutionUnit),
                  label:
                      context.l10n?.hubResolutionUnitLabel ?? 'وحدة الدقّة',
                  value: spec.resolutionUnit,
                  items: ResolutionUnit.values,
                  width: 272,
                  labelOf: (ResolutionUnit unit) => unit.labelAr,
                  onChanged: controller.setResolutionUnit,
                ),
                const SizedBox(height: AppTheme.space12),
                _FieldLabel(
                  text: context.l10n?.hubOrientationLabel ?? 'الاتجاه',
                ),
                const SizedBox(height: AppTheme.space6),
                _OrientationToggle(
                  orientation: spec.orientation,
                  onChanged: controller.setOrientation,
                ),
                if (variants.length > 1) ...<Widget>[
                  const SizedBox(height: AppTheme.space12),
                  _FieldLabel(text: context.l10n?.hubVariantLabel ?? 'النوع'),
                  const SizedBox(height: AppTheme.space6),
                  Wrap(
                    spacing: AppTheme.space6,
                    runSpacing: AppTheme.space6,
                    children: <Widget>[
                      for (final ProjectPreset variant in variants)
                        _FilterPill(
                          label: variant.titleAr,
                          selected: spec.presetId == variant.id,
                          onTap: () => controller.adoptVariant(variant),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AppTheme.space12),
                DropdownField<DocumentColorMode>(
                  key: const ValueKey<String>(NewDocumentKeys.colorMode),
                  label: context.l10n?.hubColorModeLabel ?? 'نمط اللون',
                  value: spec.colorMode,
                  items: DocumentColorMode.values,
                  width: 272,
                  labelOf: (DocumentColorMode mode) => mode.labelAr,
                  onChanged: controller.setColorMode,
                ),
                const SizedBox(height: AppTheme.space12),
                _BackgroundPicker(
                  hex: spec.backgroundHex,
                  onChanged: controller.setBackground,
                ),
              ],
            ),
          ),
        ),
        // شريط الإجراءات السفلي: «إنشاء» الأساسي و«إلغاء» الثانوي — ثابت
        // داخل اللوحة فلا يختفي مع تبدّل الاختيار.
        Container(
          padding: const EdgeInsets.all(AppTheme.space12),
          decoration: const BoxDecoration(
            color: AppColors.dialogHeader,
            border: Border(top: BorderSide(color: AppColors.dialogBorder)),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: FilledButton(
                  key: const ValueKey<String>(NewDocumentKeys.createButton),
                  onPressed: onCreate,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.dialogAccent,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppTheme.space10),
                  ),
                  child: Text(context.l10n?.hubCreate ?? 'إنشاء'),
                ),
              ),
              const SizedBox(width: AppTheme.space8),
              Expanded(
                child: OutlinedButton(
                  key: const ValueKey<String>(NewDocumentKeys.cancelButton),
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.dialogInk,
                    side: const BorderSide(color: AppColors.dialogBorder),
                    padding:
                        const EdgeInsets.symmetric(vertical: AppTheme.space10),
                  ),
                  child: Text(context.l10n?.editorCancel ?? 'إلغاء'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
//                              ودجات مساعدة
// ============================================================================

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 11.5,
          color: AppColors.dialogInkMuted,
        ),
      );
}

/// سطر تنبيه داخل لوحة التفاصيل: يوضّح أن القيم المعروضة **افتراضية** لم
/// يخترها المستخدم بعد — فيبدو الامتلاء المسبق مقصوداً لا خطأً، ويختفي السطر
/// فور اختيار مقاس من الشبكة.
class _DefaultSpecNote extends StatelessWidget {
  const _DefaultSpecNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space8,
        vertical: AppTheme.space6,
      ),
      decoration: BoxDecoration(
        color: AppColors.dialogElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppColors.dialogBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.info_outline_rounded,
              size: 13,
              color: AppColors.dialogAccent,
            ),
          ),
          const SizedBox(width: AppTheme.space6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 10.5,
                height: 1.4,
                color: AppColors.dialogInkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// تبويب نطاق في أعلى الشبكة — **بطراز تبويبات Photoshop**.
///
/// لا إطار ولا قرص ملوّن: أيقونةٌ ونصّ فقط، والمختار وحده يحمل خطّاً سفلياً
/// أزرق رقيقاً (‎2px‎) يمتدّ على عرض التبويب كله فيصير شريط التبويبات متّصلاً
/// ونظيفاً كما في نوافذ أدوبي.
class _ScopeTab extends StatelessWidget {
  const _ScopeTab({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color foreground =
        selected ? AppColors.dialogInk : AppColors.dialogInkMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Padding(
        padding: const EdgeInsets.only(top: AppTheme.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  icon,
                  size: 14,
                  color: selected ? AppColors.dialogAccent : foreground,
                ),
                const SizedBox(width: AppTheme.space6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space6),
            // مؤشّر الاختيار: ينمو من نقطة إلى عرض التبويب كله عند الاختيار.
            // (نُحرّك **نسبة** عرض محصورة لا عرضاً لا نهائياً: لا يستطيع أي
            //  `AnimatedContainer` التوفيق بين قيد محدود وقيد لا نهائي.)
            SizedBox(
              height: 2,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                alignment: Alignment.center,
                widthFactor: selected ? 1 : 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.dialogAccent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// قرص مرشّح (الكل/مجموعة/مقاس مخصّص).
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final IconData? icon = this.icon;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space10,
          vertical: AppTheme.space6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.dialogAccent
              : AppColors.dialogElevated,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(
            color: selected ? AppColors.dialogAccent : AppColors.dialogBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(
                icon,
                size: 13,
                color: selected ? Colors.white : AppColors.dialogInkMuted,
              ),
              const SizedBox(width: AppTheme.space4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                color: selected ? Colors.white : AppColors.dialogInk,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// شارة صغيرة (رقمي…).
class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.dialogAccentContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: AppColors.dialogAccent),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, color: Color(0xFFD3E7FF)),
      ),
    );
  }
}

/// بطاقة مقاس واحدة في الشبكة المصغّرة (ورقة متجهية + عنوان + أبعاد).
///
/// الحالة الوحيدة المحفوظة هنا هي **المرور**: ورقة البطاقة تُضيء بحدّ ذهبي
/// حين يمرّ المؤشّر فوقها، فيُقرأ المُقسّم كهدف قابل للنقر قبل الضغط.
class _PresetFamilyCard extends StatefulWidget {
  const _PresetFamilyCard({
    super.key,
    required this.family,
    required this.selected,
    required this.onTap,
  });

  final ProjectPresetFamily family;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_PresetFamilyCard> createState() => _PresetFamilyCardState();
}

class _PresetFamilyCardState extends State<_PresetFamilyCard> {
  bool _hovered = false;

  /// نسبة الورقة كما تُعرض على البطاقة.
  ///
  /// [ProjectPresetFamily.aspectRatio] تُحسب دائماً على الوضع الرأسي، فنقلبها
  /// للمقاسات ذات المتغيّر الأفقي — فتبدو A4 الأفقية عريضةً فعلاً لا مربّعاً
  /// مصغّراً، ويبقى المربّع مربّعاً وقصة 16:9 نحيلة طويلة.
  double get _displayRatio {
    final double base = widget.family.aspectRatio;
    if (!base.isFinite || base <= 0) return 1;
    return widget.family.variants.first.orientation.isLandscape
        ? 1 / base
        : base;
  }

  @override
  Widget build(BuildContext context) {
    final ProjectPresetFamily family = widget.family;
    final bool selected = widget.selected;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: _CardShell(
        selected: selected,
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                PhotoshopPaperIcon(
                  aspectRatio: _displayRatio,
                  selected: selected,
                  hovered: _hovered,
                ),
                const Spacer(),
                if (family.isDigital) const _Badge(label: 'رقمي'),
              ],
            ),
            const Spacer(),
            Text(
              family.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.dialogAccent : AppColors.dialogInk,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              family.dimensionsLabelFor(family.variants.first.orientation),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.dialogInkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة «مقاس مخصّص» (تظهر بطلب قرص Custom).
class _CustomTile extends StatelessWidget {
  const _CustomTile({super.key, required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      selected: true,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(color: AppColors.dialogBorder),
            ),
            child: const Icon(Icons.add_rounded,
                size: 16, color: AppColors.dialogAccent),
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.dialogInk,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            context.l10n?.hubCustomCardBody ??
                'أدخل أبعادك بالوحدة التي تريدها لتبدأ بلوحة على مقاسك.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.dialogInkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// هيكل البطاقة: إطار + تحديد + تمرير.
class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.child,
    required this.selected,
    required this.onTap,
  });

  final Widget child;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(AppTheme.space10),
        decoration: BoxDecoration(
          color: selected ? AppColors.dialogAccentContainer : AppColors.dialogElevated,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color:
                selected ? AppColors.dialogAccent : AppColors.dialogBorder,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// معاينة مصغّرة للورقة في لوحة التفاصيل (شكل + أبعاد + دقّة).
class _SheetPreview extends StatelessWidget {
  const _SheetPreview({required this.spec});

  final NewDocumentSpec spec;

  @override
  Widget build(BuildContext context) {
    final double ratio = spec.height <= 0 ? 1 : spec.width / spec.height;
    final bool transparent =
        spec.backgroundHex.toUpperCase() == NewDocumentSpec.transparentHex;
    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(AppTheme.space4),
          decoration: BoxDecoration(
            color: AppColors.dialogHeader,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(color: AppColors.dialogBorder),
          ),
          child: SizedBox(
            height: 48,
            width: (48 * ratio.clamp(0.2, 2.5)).clamp(22.0, 120.0),
            child: Container(
              decoration: BoxDecoration(
                color: transparent
                    ? Colors.transparent
                    : colorFromHex(spec.backgroundHex),
                border: Border.all(color: AppColors.dialogBorder),
              ),
              child: transparent
                  ? const Icon(Icons.grid_4x4_rounded,
                      size: 13, color: AppColors.dialogInkMuted)
                  : null,
            ),
          ),
        ),
        const SizedBox(width: AppTheme.space10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                spec.dimensionsLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dialogInk,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${context.l10n?.hubAspectRatio ?? 'النسبة'}: '
                '${ProjectPreset.formatDimension(spec.width)}:'
                '${ProjectPreset.formatDimension(spec.height)} · '
                '${spec.dpi} DPI',
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.dialogInkMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// زرّا الاتجاه: رأسي/أفقي — يقلبان الأبعاد فعلاً.
class _OrientationToggle extends StatelessWidget {
  const _OrientationToggle({
    required this.orientation,
    required this.onChanged,
  });

  final PageOrientation orientation;
  final ValueChanged<PageOrientation> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _OrientationButton(
            key: const ValueKey<String>(NewDocumentKeys.portrait),
            icon: Icons.crop_portrait_rounded,
            label: context.l10n?.hubPortrait ?? 'رأسي',
            selected: orientation == PageOrientation.portrait,
            onTap: () => onChanged(PageOrientation.portrait),
          ),
        ),
        const SizedBox(width: AppTheme.space8),
        Expanded(
          child: _OrientationButton(
            key: const ValueKey<String>(NewDocumentKeys.landscape),
            icon: Icons.crop_landscape_rounded,
            label: context.l10n?.hubLandscape ?? 'أفقي',
            selected: orientation == PageOrientation.landscape,
            onTap: () => onChanged(PageOrientation.landscape),
          ),
        ),
      ],
    );
  }
}

class _OrientationButton extends StatelessWidget {
  const _OrientationButton({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
        decoration: BoxDecoration(
          color: selected ? AppColors.dialogAccentContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: selected ? AppColors.dialogAccent : AppColors.dialogBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: 16,
              color:
                  selected ? AppColors.dialogAccent : AppColors.dialogInkMuted,
            ),
            const SizedBox(width: AppTheme.space6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                color: selected ? AppColors.dialogInk : AppColors.dialogInkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// خيارات الخلفية في القائمة المنسدلة.
enum _BackgroundOption { white, transparent, black, custom }

/// لون الخلفية: قائمة منسدلة بمعاينة لونية + منتقي كامل عند «مخصّص».
class _BackgroundPicker extends StatelessWidget {
  const _BackgroundPicker({required this.hex, required this.onChanged});

  final String hex;
  final ValueChanged<String> onChanged;

  static const String _white = '#FFFFFF';
  static const String _black = '#000000';

  static bool _isCustom(String value) {
    final String upper = value.toUpperCase();
    return upper != _white &&
        upper != _black &&
        upper != NewDocumentSpec.transparentHex;
  }

  @override
  Widget build(BuildContext context) {
    final bool custom = _isCustom(hex);
    final _BackgroundOption selected = hex.toUpperCase() == _white
        ? _BackgroundOption.white
        : hex.toUpperCase() == NewDocumentSpec.transparentHex
            ? _BackgroundOption.transparent
            : hex.toUpperCase() == _black
                ? _BackgroundOption.black
                : _BackgroundOption.custom;

    String labelOf(_BackgroundOption option) => switch (option) {
          _BackgroundOption.white =>
            context.l10n?.hubBackgroundWhite ?? 'أبيض',
          _BackgroundOption.transparent =>
            context.l10n?.hubBackgroundTransparent ?? 'شفاف',
          _BackgroundOption.black =>
            context.l10n?.hubBackgroundBlack ?? 'أسود',
          _BackgroundOption.custom =>
            context.l10n?.hubBackgroundCustom ?? 'لون مخصّص',
        };

    Color swatchOf(_BackgroundOption option) => switch (option) {
          _BackgroundOption.white => Colors.white,
          _BackgroundOption.transparent => Colors.transparent,
          _BackgroundOption.black => Colors.black,
          _BackgroundOption.custom =>
            custom ? colorFromHex(hex) : AppColors.dialogElevated,
        };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _FieldLabel(
          text: context.l10n?.hubBackgroundLabel ?? 'لون الخلفية',
        ),
        const SizedBox(height: AppTheme.space6),
        SizedBox(
          width: 272,
          child: InputDecorator(
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<_BackgroundOption>(
                key: const ValueKey<String>(NewDocumentKeys.background),
                value: selected,
                isDense: true,
                isExpanded: true,
                dropdownColor: AppColors.dialogElevated,
                icon: const Icon(Icons.expand_more_rounded, size: 16),
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.dialogInk,
                ),
                items: <DropdownMenuItem<_BackgroundOption>>[
                  for (final _BackgroundOption option
                      in _BackgroundOption.values)
                    DropdownMenuItem<_BackgroundOption>(
                      value: option,
                      child: Row(
                        children: <Widget>[
                          _Swatch(color: swatchOf(option)),
                          const SizedBox(width: AppTheme.space8),
                          Text(
                            labelOf(option),
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                ],
                onChanged: (_BackgroundOption? option) {
                  if (option == null) return;
                  switch (option) {
                    case _BackgroundOption.white:
                      onChanged(_white);
                    case _BackgroundOption.transparent:
                      onChanged(NewDocumentSpec.transparentHex);
                    case _BackgroundOption.black:
                      onChanged(_black);
                    case _BackgroundOption.custom:
                      // «مخصّص» يفتح المنتقي الكامل أدناه مباشرةً.
                      onChanged(custom ? hex : '#1B2539');
                  }
                },
              ),
            ),
          ),
        ),
        if (custom) ...<Widget>[
          const SizedBox(height: AppTheme.space8),
          ColorField(
            label: context.l10n?.hubBackgroundCustom ?? 'لون مخصّص',
            hex: hex,
            width: 172,
            onChanged: onChanged,
          ),
        ],
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.dialogInkMuted),
      ),
    );
  }
}
