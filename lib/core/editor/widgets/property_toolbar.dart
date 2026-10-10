import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../assets/asset_type_ui.dart';
import '../../assets/asset_upload.dart';
import '../../assets/assets_controller.dart';
import '../../assets/user_asset.dart';
import '../../constants/app_constants.dart';
import '../../constants/dynamic_fields.dart';
import '../../gender/arabic_gender.dart';
import '../../l10n/app_l10n.dart';
import '../../models/decor_presets.dart';
import '../../models/decoration.dart';
import '../../models/template_element.dart';
import '../../models/template_document.dart';
import '../../pdf/pdf_font_catalog.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../constants/app_assets.dart';
import '../../utils/hex_color.dart';
import '../element_factory.dart';
import '../template_editor_controller.dart';
import 'asset_library_picker.dart';
import 'custom_font_panel.dart';
import 'editor_controls.dart';
import 'element_painters.dart';
import 'element_view.dart';

/// شريط الخصائص العائم: يظهر عند تحديد عنصر ويعرض أدوات **خاصة بنوعه** فقط.
///
/// * نص → الخط، الوزن، الحجم، اللون، المحاذاة، الاتجاه، التباعد، والنص نفسه
///   مع إدراج الحقول الديناميكية `{{...}}`.
/// * صورة/ختم/شكل → الشفافية، الدوران، الأبعاد، والألوان الخاصة.
/// * رمز QR → البيانات والألوان.
class PropertyToolbar extends StatefulWidget {
  const PropertyToolbar({
    super.key,
    required this.controller,
    this.textFocusNode,
    this.maxWidth = 980,
  });

  final TemplateEditorController controller;

  /// أقصى عرض للشريط.
  ///
  /// في المحرر يُمرَّر عرض ضيق (~420) فيصبح الشريط لوحاً جانبياً عائماً لا
  /// يحجب لوحة التصميم، وفي الاختبارات يبقى العرض الواسع لعرض كل الأدوات.
  final double maxWidth;

  /// عقدة تركيز حقل النص (يملكها الشاشة حتى يتمكن النقر المزدوج على اللوحة
  /// من تركيزها مباشرة).
  final FocusNode? textFocusNode;

  @override
  State<PropertyToolbar> createState() => _PropertyToolbarState();
}

class _PropertyToolbarState extends State<PropertyToolbar> {
  /// النواة المحرّرة للعنصر المحدّد (يُستخدم من أدوات الشريط).
  TemplateEditorController get controller => widget.controller;

  /// خطوة الضبط الدقيق (بوحدات التصميم) لأزرار النقل الاتجاهي.
  double _nudgeStep = 1;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (BuildContext context, Widget? _) {
        final TemplateEditorController controller = widget.controller;
        if (!controller.hasSelection) return const SizedBox.shrink();

        final TemplateElement? element = controller.selected;
        // تحديد جماعي: تُعرض أدوات المجموعة بدل أدوات العنصر الواحد.
        if (controller.selectionCount > 1 || element == null) {
          return _groupPanel(controller);
        }

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.maxWidth),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            color: Theme.of(context).colorScheme.surface,
            child: Container(
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _elementHeader(controller, element),
                  const SizedBox(height: AppTheme.space12),
                  _pageSizeSection(controller),
                  const SizedBox(height: AppTheme.space12),
                  _backgroundSection(controller),
                  _geometrySection(controller, element),
                  if (element is TextElement) ...<Widget>[
                    const SizedBox(height: AppTheme.space12),
                    _textSection(controller, element),
                  ],
                  if (element is ImageElement) ...<Widget>[
                    const SizedBox(height: AppTheme.space12),
                    _imageSection(controller, element),
                  ],
                  if (element is SealElement) ...<Widget>[
                    const SizedBox(height: AppTheme.space12),
                    _sealSection(controller, element),
                  ],
                  if (element is ShapeElement) ...<Widget>[
                    const SizedBox(height: AppTheme.space12),
                    _shapeSection(controller, element),
                  ],
                  if (element is QrElement) ...<Widget>[
                    const SizedBox(height: AppTheme.space12),
                    _qrSection(controller, element),
                  ],
                  if (element is DecorationElement) ...<Widget>[
                    const SizedBox(height: AppTheme.space12),
                    _decorationSection(controller, element),
                  ],
                  if (element is SignatureElement) ...<Widget>[
                    const SizedBox(height: AppTheme.space12),
                    _signatureSection(controller, element),
                  ],
                  // التأثيرات والضبط اللوني: بيت واحد للظل والتوهّج والضبط
                  // اللوني (نمط Photoshop). ودخوله في [AccordionScope] يجعل
                  // فتحه يُغلق بقية الأقسام تلقائياً كسائر الأقسام.
                  if (element is TextElement ||
                      element is ShapeElement ||
                      element is ImageElement) ...<Widget>[
                    const SizedBox(height: AppTheme.space12),
                    _effectsSection(controller, element),
                  ],
                  if (element is UnknownElement) ...<Widget>[
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      context.l10n?.unsupportedElementVersionNote ??
                          'هذا العنصر من إصدار أحدث من المحرر — يُحفظ كما هو '
                              'ولا يمكن تعديله هنا.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  // أدوات الضبط الدقيق تُوضع في **آخر** الشريط حتى لا تُزاح
                  // الأقسام القائمة (النص/الصورة/الختم) فتبقى مواقعها ثابتة.
                  if (element is! UnknownElement) ...<Widget>[
                    const SizedBox(height: AppTheme.space12),
                    _precisionSection(controller, element),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================================
  //  لوحة المجموعة (تحديد متعدد)
  // ==========================================================================
  static final ButtonStyle _groupButtonStyle = OutlinedButton.styleFrom(
    minimumSize: const Size(0, 40),
    padding: const EdgeInsets.symmetric(horizontal: 12),
  );

  /// زرّ عملية دمج منطقي واحدة (توحيد/طرح/تقاطع/استثناء).
  Widget _booleanOpButton({
    required String key,
    required ShapeBooleanOp op,
    required IconData icon,
    required String label,
  }) =>
      OutlinedButton.icon(
        key: ValueKey<String>(key),
        onPressed: () => controller.applyShapeBoolean(op),
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: _groupButtonStyle,
      );

  /// شفافية "العنصر الأساسي" كقيمة بداية للمنزلق الجماعي.
  static double _groupOpacity(TemplateEditorController controller) =>
      switch (controller.selected) {
        TextElement(:final double opacity) => opacity,
        ShapeElement(:final double opacity) => opacity,
        SealElement(:final double opacity) => opacity,
        ImageElement(:final double opacity) => opacity,
        DecorationElement(:final double opacity) => opacity,
        SignatureElement(:final double opacity) => opacity,
        _ => 1,
      };

  /// أدوات العمل الجماعي: ترتيب، تكرار، حذف، وشفافية على كل المحدد معاً.
  Widget _groupPanel(TemplateEditorController controller) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        color: Theme.of(context).colorScheme.surface,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.space12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.brandSurface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(Icons.layers_rounded,
                            size: 13, color: AppColors.gold),
                        const SizedBox(width: 6),
                        Text(
                          context.l10n?.editorSelectedCount(
                                controller.selectionCount,
                              ) ??
                              '${controller.selectionCount} عناصر محددة',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconAction(
                    icon: Icons.close_rounded,
                    tooltip: context.l10n?.editorClearSelection ?? 'إلغاء التحديد',
                    onPressed: controller.clearSelection,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space12),
              ControlSection(
                icon: Icons.opacity_rounded,
                label: context.l10n?.editorGroup ?? 'المجموعة',
                children: <Widget>[
                  SliderField(
                    label: context.l10n?.editorOpacity ?? 'الشفافية',
                    value: _groupOpacity(controller),
                    min: 0,
                    max: 1,
                    display: (double value) => '${(value * 100).round()}%',
                    onChanged: controller.setSelectedOpacity,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space12),
              Wrap(
                spacing: AppTheme.space8,
                runSpacing: AppTheme.space8,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: controller.bringToFront,
                    icon: const Icon(Icons.vertical_align_top_rounded, size: 16),
                    label: Text(context.l10n?.editorBringToFront ?? 'إلى المقدمة'),
                    style: _groupButtonStyle,
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.sendToBack,
                    icon: const Icon(Icons.vertical_align_bottom_rounded,
                        size: 16),
                    label: Text(context.l10n?.editorSendToBack ?? 'إلى الخلف'),
                    style: _groupButtonStyle,
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.duplicateSelected,
                    icon: const Icon(Icons.copy_all_rounded, size: 16),
                    label: Text(context.l10n?.editorDuplicate ?? 'تكرار'),
                    style: _groupButtonStyle,
                  ),
                  FilledButton.icon(
                    key: const ValueKey<String>('group-delete'),
                    onPressed: controller.deleteSelected,
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: Text(context.l10n?.editorDeleteSelected ?? 'حذف المحدد'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                  ),
                ],
              ),
              // عمليات الدمج المنطقي — تظهر فقط حين يكون التحديد قابلاً لها
              // (شكلان بسيطان فأكثر) أو حين يكون المركّب قابلاً للفصل.
              if (controller.canApplyShapeBoolean ||
                  controller.hasCompoundSelection) ...<Widget>[
                const SizedBox(height: AppTheme.space12),
                ControlSection(
                  icon: Icons.merge_type_rounded,
                  label: context.l10n?.editorBooleanOps ?? 'عمليات الدمج',
                  children: <Widget>[
                    Wrap(
                      spacing: AppTheme.space8,
                      runSpacing: AppTheme.space8,
                      children: <Widget>[
                        if (controller.canApplyShapeBoolean) ...<Widget>[
                          _booleanOpButton(
                            key: 'editor-boolean-union',
                            op: ShapeBooleanOp.union,
                            icon: Icons.join_full_rounded,
                            label: context.l10n?.editorBooleanUnion ?? 'دمج',
                          ),
                          _booleanOpButton(
                            key: 'editor-boolean-subtract',
                            op: ShapeBooleanOp.subtract,
                            icon: Icons.difference_rounded,
                            label: context.l10n?.editorBooleanSubtract ?? 'طرح',
                          ),
                          _booleanOpButton(
                            key: 'editor-boolean-intersect',
                            op: ShapeBooleanOp.intersect,
                            icon: Icons.join_inner_rounded,
                            label: context.l10n?.editorBooleanIntersect ?? 'تقاطع',
                          ),
                          _booleanOpButton(
                            key: 'editor-boolean-exclude',
                            op: ShapeBooleanOp.exclude,
                            icon: Icons.join_left_rounded,
                            label: context.l10n?.editorBooleanExclude ?? 'استثناء',
                          ),
                        ],
                        if (controller.hasCompoundSelection)
                          OutlinedButton.icon(
                            key: const ValueKey<String>(
                                'editor-boolean-ungroup'),
                            onPressed: controller.ungroupShapeBoolean,
                            icon: const Icon(Icons.call_split_rounded, size: 16),
                            label: Text(
                              context.l10n?.editorBooleanUngroup ??
                                  'فصل الشكل المركّب',
                            ),
                            style: _groupButtonStyle,
                          ),
                      ],
                    ),
                    Text(
                      context.l10n?.editorBooleanHint ??
                          'يُبنى المسار المدمج كناتج عملية منطقية واحدة '
                              '(بلا حدود متداخلة) ويمكن فكه في أي وقت.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppTheme.space8),
              Text(
                context.l10n?.editorGroupDragHint ??
                    'اسحب المجموعة بالماوس، والأسهم للتحريك الدقيق (Shift = 10px)، '
                        'و Ctrl + نقر لتعديل التحديد.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  //  الترويسة: نوع العنصر + ترتيب الرسم + تكرار/حذف
  // ==========================================================================
  Widget _elementHeader(
    TemplateEditorController controller,
    TemplateElement element,
  ) {
    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.brandSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(_iconFor(element), size: 13, color: AppColors.gold),
              const SizedBox(width: 6),
              Text(
                _labelFor(element, context),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onNavy,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // ترتيب الرسم: خطوة للأمام/الخلف (وإلى المقدمة/الخلف تماماً في
        // قسم «التحويلات» أسفل الشريط) — فلا يتكرر أي تلميح بين القسمين.
        IconAction(
          icon: Icons.flip_to_front_rounded,
          tooltip: context.l10n?.editorBringForward ?? 'إلى الأمام',
          onPressed: controller.bringForward,
        ),
        const SizedBox(width: 4),
        IconAction(
          icon: Icons.flip_to_back_rounded,
          tooltip: context.l10n?.editorSendBackward ?? 'إلى الخلف خطوة',
          onPressed: controller.sendBackward,
        ),
        const SizedBox(width: 4),
        IconAction(
          icon: Icons.copy_all_rounded,
          tooltip: context.l10n?.editorDuplicateElement ?? 'تكرار العنصر',
          onPressed: controller.duplicateSelected,
        ),
        const SizedBox(width: 4),
        IconAction(
          icon: Icons.delete_outline_rounded,
          tooltip: context.l10n?.editorDeleteElement ?? 'حذف العنصر',
          danger: true,
          onPressed: controller.deleteSelected,
        ),
        const SizedBox(width: 4),
        IconAction(
          icon: Icons.close_rounded,
          tooltip: context.l10n?.editorClearSelection ?? 'إلغاء التحديد',
          onPressed: controller.clearSelection,
        ),
      ],
    );
  }

  // ==========================================================================
  //  إعدادات الصفحة (المقاس + الوحدة)
  // ==========================================================================
  Widget _pageSizeSection(TemplateEditorController controller) {
    return ControlSection(
      icon: Icons.pageview_rounded,
      label: context.l10n?.editorPageSettings ?? 'إعدادات الصفحة',
      subtitle: context.l10n?.editorPageSettingsHint ?? 'المقاس ووحدة القياس',
      children: <Widget>[
        if (controller.document.customPageSize == null) ...<Widget>[
          DropdownField<PaperSize>(
            label: context.l10n?.editorPageSize ?? 'المقاس',
            value: controller.document.paperSize,
            items: PaperSize.values,
            labelOf: (PaperSize size) => size.labelAr,
            onChanged: controller.setPaperSize,
          ),
          // تفعيل الأبعاد الحُرّة بالسنتيمتر/البوصة من أي مقاس قياسي (أيقونة
          // مضغوطة في السطر نفسه فلا تزيد ارتفاع الشريط).
          IconAction(
            key: const ValueKey<String>('toolbar-custom-size-button'),
            icon: Icons.straighten_rounded,
            tooltip: context.l10n?.editorCustomSize ?? 'مقاس مخصّص',
            onPressed: controller.enableCustomPageSize,
          ),
        ] else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: DropdownField<MeasurementUnit>(
                      label: context.l10n?.editorUnit ?? 'الوحدة',
                      value: controller.document.customPageSize!.unit,
                      items: MeasurementUnit.values,
                      labelOf: (MeasurementUnit unit) => unit.labelAr,
                      onChanged: (MeasurementUnit unit) =>
                          controller.setCustomPageSize(
                            controller.document.customPageSize!.width,
                            controller.document.customPageSize!.height,
                            unit,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: NumberField(
                      label: context.l10n?.editorWidth ?? 'العرض',
                      value: controller.document.customPageSize!.width,
                      min: 1,
                      max: 500,
                      decimals: 2,
                      onChanged: (double width) =>
                          controller.setCustomPageSize(
                            width,
                            controller.document.customPageSize!.height,
                            controller.document.customPageSize!.unit,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: NumberField(
                      label: context.l10n?.editorHeight ?? 'الارتفاع',
                      value: controller.document.customPageSize!.height,
                      min: 1,
                      max: 500,
                      decimals: 2,
                      onChanged: (double height) =>
                          controller.setCustomPageSize(
                            controller.document.customPageSize!.width,
                            height,
                            controller.document.customPageSize!.unit,
                          ),
                    ),
                  ),
                ],
              ),
              Text(
                '${controller.document.customPageSize!.width.toStringAsFixed(2)} '
                '× ${controller.document.customPageSize!.height.toStringAsFixed(2)} '
                '${controller.document.customPageSize!.unit.labelAr} '
                '→ ${controller.paperSizeLabel}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: AppAssets.cairoFont,
                ),
              ),
              // العودة إلى المقاسات القياسية (A4/A5).
              IconAction(
                key: const ValueKey<String>('toolbar-standard-size-button'),
                icon: Icons.aspect_ratio_rounded,
                tooltip: context.l10n?.editorStandardSize ?? 'مقاس قياسي',
                onPressed: controller.clearCustomPageSize,
              ),
            ],
          ),
      ],
    );
  }

  // ==========================================================================
  //  خلفية الورقة (لون مفرد أو تدرّج)
  // ==========================================================================
  Widget _backgroundSection(TemplateEditorController controller) {
    final BackgroundGradient? gradient = controller.document.backgroundGradient;
    final GradientDirection direction =
        gradient?.direction ?? GradientDirection.vertical;
    // اللونان يبدآن من خلفية المستند الحالية حتى لا يقفز التدرّج إلى الأسود.
    final String start = gradient?.startHex ?? controller.document.backgroundHex;
    final String end = gradient?.endHex ?? controller.document.backgroundHex;

    BackgroundGradient make(String from, String to, GradientDirection dir) =>
        BackgroundGradient(startHex: from, endHex: to, direction: dir);

    return ControlSection(
      icon: Icons.gradient_rounded,
      label: context.l10n?.editorBackgroundTitle ?? 'خلفية الورقة',
      subtitle: context.l10n?.editorBackgroundHint ?? 'لون الورقة أو تدرّجها',
      children: <Widget>[
        ColorField(
          key: const ValueKey<String>('background-gradient-start'),
          label: context.l10n?.editorGradientFrom ?? 'من',
          hex: start,
          width: 150,
          onChanged: (String hex) =>
              controller.setBackgroundGradient(make(hex, end, direction)),
        ),
        ColorField(
          key: const ValueKey<String>('background-gradient-end'),
          label: context.l10n?.editorGradientTo ?? 'إلى',
          hex: end,
          width: 150,
          onChanged: (String hex) =>
              controller.setBackgroundGradient(make(start, hex, direction)),
        ),
        DropdownField<GradientDirection>(
          key: const ValueKey<String>('background-gradient-direction'),
          label: context.l10n?.editorGradientDirection ?? 'اتجاه',
          value: direction,
          items: GradientDirection.values,
          labelOf: (GradientDirection item) => switch (item) {
            GradientDirection.vertical =>
              context.l10n?.editorGradientVertical ?? 'رأسي',
            GradientDirection.horizontal =>
              context.l10n?.editorGradientHorizontal ?? 'أفقي',
            GradientDirection.diagonal =>
              context.l10n?.editorGradientDiagonal ?? 'قطري',
          },
          onChanged: (GradientDirection dir) =>
              controller.setBackgroundGradient(make(start, end, dir)),
        ),
        if (gradient != null)
          OutlinedButton.icon(
            key: const ValueKey<String>('background-gradient-clear'),
            onPressed: controller.clearBackgroundGradient,
            icon: const Icon(Icons.format_color_reset_rounded, size: 15),
            label: Text(context.l10n?.editorGradientNone ?? 'بلا تدرّج'),
          ),
      ],
    );
  }

  static IconData _iconFor(TemplateElement element) => switch (element) {
        TextElement(:final bool hasDynamicFields) =>
          hasDynamicFields ? Icons.data_object_rounded : Icons.text_fields_rounded,
        ShapeElement() => Icons.crop_square_rounded,
        SealElement() => Icons.verified_rounded,
        DecorationElement() => Icons.auto_awesome_rounded,
        SignatureElement() => Icons.draw_rounded,
        ImageElement() => Icons.image_outlined,
        QrElement() => Icons.qr_code_2_rounded,
        UnknownElement() => Icons.help_outline_rounded,
      };

  static String _labelFor(TemplateElement element, BuildContext context) =>
      switch (element) {
        TextElement(:final bool hasDynamicFields) =>
          hasDynamicFields ? context.l10n?.editorLabelDynamicField ?? 'حقل ديناميكي' : context.l10n?.editorLabelText ?? 'نص',
        ShapeElement() => context.l10n?.editorLabelShape ?? 'شكل',
        SealElement() => context.l10n?.editorLabelSeal ?? 'ختم',
        DecorationElement() => context.l10n?.editorLabelDecoration ?? 'زخرفة متجهية',
        SignatureElement() => context.l10n?.editorLabelSignature ?? 'كتلة توقيعات',
        ImageElement() => context.l10n?.editorLabelImage ?? 'صورة/شعار',
        QrElement() => context.l10n?.editorLabelQr ?? 'رمز QR',
        UnknownElement() => context.l10n?.editorLabelUnknown ?? 'عنصر غير مدعوم',
      };

  // ==========================================================================
  //  القسم الهندسي: الموضع، الحجم، الدوران، الشفافية
  // ==========================================================================
  Widget _geometrySection(
    TemplateEditorController controller,
    TemplateElement element,
  ) {
    final ElementBox box = element.box;
    final Size design = controller.designSize;

    return ControlSection(
      icon: Icons.open_with_rounded,
      label: context.l10n?.editorTransformPosition ?? 'التحويل والموضع',
      subtitle: context.l10n?.editorTransformPositionHint ??
          'الإحداثيات والأبعاد وزاوية الدوران',
      children: <Widget>[
        NumberField(
          label: context.l10n?.editorPosX ?? 'س',
          value: box.x,
          unit: 'px',
          min: 0,
          max: design.width,
          onChanged: (double value) =>
              controller.setSelectedBox(box.copyWith(x: value)),
        ),
        NumberField(
          label: context.l10n?.editorPosY ?? 'ص',
          value: box.y,
          unit: 'px',
          min: 0,
          max: design.height,
          onChanged: (double value) =>
              controller.setSelectedBox(box.copyWith(y: value)),
        ),
        NumberField(
          label: context.l10n?.editorWidth ?? 'العرض',
          value: box.width,
          unit: 'px',
          min: 0,
          max: design.width,
          step: 5,
          onChanged: (double value) =>
              controller.setSelectedBox(box.copyWith(width: value)),
        ),
        NumberField(
          label: context.l10n?.editorHeight ?? 'الارتفاع',
          value: box.height,
          unit: 'px',
          min: 0,
          max: design.height,
          step: 5,
          onChanged: (double value) =>
              controller.setSelectedBox(box.copyWith(height: value)),
        ),
        SliderField(
          label: context.l10n?.editorRotation ?? 'الدوران',
          value: element.rotation,
          min: -180,
          max: 180,
          divisions: 72,
          display: (double value) => '${value.round()}°',
          onChanged: controller.setSelectedRotation,
        ),
        SliderField(
          label: context.l10n?.editorOpacity ?? 'الشفافية',
          value: _opacityOf(element),
          min: 0,
          max: 1,
          display: (double value) => '${(value * 100).round()}%',
          onChanged: controller.setSelectedOpacity,
        ),
        // إجراءات التحويل السريعة: كانت في قسم «التحويلات» منفصلاً فيتكرّر
        // الدوران في بطاقتين — الآن مكانها الواحد هنا مع زاوية الدوران.
        Row(
          children: <Widget>[
            IconAction(
              key: const ValueKey<String>('rotate-left'),
              icon: Icons.rotate_left_rounded,
              tooltip: context.l10n?.editorRotateLeft ?? 'تدوير 90° يساراً',
              onPressed: () => controller.rotateSelectedBy(-90),
            ),
            const SizedBox(width: 4),
            IconAction(
              key: const ValueKey<String>('rotate-right'),
              icon: Icons.rotate_right_rounded,
              tooltip: context.l10n?.editorRotateRight ?? 'تدوير 90° يميناً',
              onPressed: () => controller.rotateSelectedBy(90),
            ),
            if (element is ShapeElement) ...<Widget>[
              const SizedBox(width: 4),
              IconAction(
                key: const ValueKey<String>('flip-horizontal'),
                icon: Icons.swap_horiz_rounded,
                tooltip: context.l10n?.editorFlipH ?? 'قلب أفقي',
                onPressed: controller.flipSelectedHorizontal,
              ),
              const SizedBox(width: 4),
              IconAction(
                key: const ValueKey<String>('flip-vertical'),
                icon: Icons.swap_vert_rounded,
                tooltip: context.l10n?.editorFlipV ?? 'قلب رأسي',
                onPressed: controller.flipSelectedVertical,
              ),
            ],
          ],
        ),
        // ترتيب الطبقات: إلى المقدمة/الخلف تماماً (والخطوة خطوة في الترويسة).
        Row(
          children: <Widget>[
            IconAction(
              key: const ValueKey<String>('z-bring-front'),
              icon: Icons.vertical_align_top_rounded,
              tooltip: context.l10n?.editorBringToFront ?? 'إلى المقدمة',
              onPressed: controller.bringToFront,
            ),
            const SizedBox(width: 4),
            IconAction(
              key: const ValueKey<String>('z-send-back'),
              icon: Icons.vertical_align_bottom_rounded,
              tooltip: context.l10n?.editorSendToBack ?? 'إلى الخلف',
              onPressed: controller.sendToBack,
            ),
          ],
        ),
      ],
    );
  }

  static double _opacityOf(TemplateElement element) => switch (element) {
        TextElement(:final double opacity) => opacity,
        ShapeElement(:final double opacity) => opacity,
        SealElement(:final double opacity) => opacity,
        ImageElement(:final double opacity) => opacity,
        DecorationElement(:final double opacity) => opacity,
        SignatureElement(:final double opacity) => opacity,
        _ => 1,
      };

  // ==========================================================================
  //  الضبط الدقيق: نقل بخطوة + تحجيم نسبي (عجلة الفأرة + أزرار)
  // ==========================================================================
  Widget _precisionSection(
    TemplateEditorController controller,
    TemplateElement element,
  ) {
    final String stepLabel = _stepLabel(_nudgeStep);
    return ControlSection(
      icon: Icons.tune_rounded,
      label: context.l10n?.editorPrecisionTitle ?? 'الضبط الدقيق',
      subtitle: context.l10n?.editorPrecisionHint ?? 'النقل الدقيق والتحجيم',
      children: <Widget>[
        SegmentedField<double>(
          label: context.l10n?.editorNudgeStep ?? 'خطوة النقل',
          hint: context.l10n?.editorNudgeStepHint ?? 'الأسهم في اللوحة تنقل بـ Shift = 10px أيضاً.',
          value: _nudgeStep,
          options: const <double>[1, 5, 10, 25],
          labelOf: (double step) => '${step.round()}',
          onChanged: (double step) => setState(() => _nudgeStep = step),
        ),
        // لوحة أسهم: نقل مباشر في الاتجاهات الأربعة بخطوة مختارة.
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconAction(
              key: const ValueKey<String>('nudge-up'),
              icon: Icons.keyboard_arrow_up_rounded,
              tooltip: '${context.l10n?.editorNudgeUp ?? 'نقل لأعلى'} ('
                  '$stepLabel)',
              onPressed: () => _nudge(controller, dy: -_nudgeStep),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconAction(
                  key: const ValueKey<String>('nudge-left'),
                  icon: Icons.keyboard_arrow_left_rounded,
                  tooltip:
                      '${context.l10n?.editorNudgeLeft ?? 'نقل لليسار'} '
                      '($stepLabel)',
                  onPressed: () => _nudge(controller, dx: -_nudgeStep),
                ),
                IconAction(
                  key: const ValueKey<String>('nudge-down'),
                  icon: Icons.keyboard_arrow_down_rounded,
                  tooltip:
                      '${context.l10n?.editorNudgeDown ?? 'نقل لأسفل'} '
                      '($stepLabel)',
                  onPressed: () => _nudge(controller, dy: _nudgeStep),
                ),
                IconAction(
                  key: const ValueKey<String>('nudge-right'),
                  icon: Icons.keyboard_arrow_right_rounded,
                  tooltip:
                      '${context.l10n?.editorNudgeRight ?? 'نقل لليمين'} '
                      '($stepLabel)',
                  onPressed: () => _nudge(controller, dx: _nudgeStep),
                ),
              ],
            ),
          ],
        ),
        // تحجيم نسبي تدريجي: كل نقرة ×خطوة، والعجلة فوق الزر تفعل الشيء نفسه.
        _ScaleField(
          key: ValueKey<String>('scale-${element.id}'),
          elementId: element.id,
          onScale: controller.scaleSelected,
        ),
      ],
    );
  }

  static String _stepLabel(double step) =>
      '${step.round()} px';

  /// نقل العنصر المحدد بخطوة صغيرة مع الالتزام بحدود الورقة.
  void _nudge(
    TemplateEditorController controller, {
    double dx = 0,
    double dy = 0,
  }) {
    final TemplateElement? element = controller.selected;
    if (element == null) return;
    controller.setSelectedBox(element.box.translated(dx: dx, dy: dy));
  }

  // ==========================================================================
  //  النص: الخط والنمط والمحتوى والحقول الديناميكية
  // ==========================================================================
  Widget _textSection(
    TemplateEditorController controller,
    TextElement element,
  ) {
    return ControlSection(
      icon: Icons.text_fields_rounded,
      label: context.l10n?.editorTextFormat ?? 'تنسيق النص',
      subtitle: context.l10n?.editorTypographyHint ??
          'الخط والحجم والمحاذاة والتباعد',
      children: <Widget>[
        // إجراء سريع: تحويل النص الحالي إلى حقل ديناميكي بـ مفتاح محدّد.
        if (controller.selectedTextElement != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space12,
              vertical: AppTheme.space8,
            ),
            child: OutlinedButton.icon(
              onPressed: () =>
                  _showConvertToFieldDialog(element),
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: Text(context.l10n?.editorConvertToField ?? 'تحويل إلى حقل ديناميكي'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ),
        // صيغة شرطية ذكية (تذكير/تأنيث): تُدرج `{{الجنس: ذكر | أنثى}}` بضغطة.
        Padding(
          key: const ValueKey<String>('gender-snippet-section'),
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  key: const ValueKey<String>('gender-snippet-button'),
                  onPressed: () => _showGenderSnippetDialog(controller),
                  icon: const Icon(Icons.alt_route_rounded, size: 16),
                  label: Text(
                    context.l10n?.editorGenderSnippet ?? 'إدراج صيغة شرطية',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space4),
              Text(
                context.l10n?.editorGenderSnippetHint ??
                    'تُدرج صيغة تتبدّل تلقائياً حسب جنس المستفيد.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        // مفتاح العنصر يجعل حقل النص يُعاد تهيئته عند تغيير التحديد.
        ElementTextEditor(
          key: ValueKey<String>('text-editor-${element.id}'),
          element: element,
          focusNode: widget.textFocusNode,
          onChanged: controller.updateText,
        ),
        // منتقٍ موحّد يجمع الخطوط المضمّنة والمرفوعة وخطوط النظام، قابل للبحث.
        FontSelectorSection(
          bundledFamily: element.family,
          customFamily: element.customFont,
          // اختيار خط مضمّن يلغي أي خط مخصص مرتبط بالعنصر.
          onBundledSelected: (PdfFontFamily family) =>
              controller.updateTextStyle(family: family, customFont: null),
          onCustomSelected: (String? family) =>
              controller.updateTextStyle(customFont: family),
          // معاينة حيّة: الخط يتغيّر على اللوحة فور المرور فوق الخيار.
          onPreviewFamily: controller.setFontPreview,
        ),
        DropdownField<PdfFontWeight>(
          label: context.l10n?.editorFontWeight ?? 'الوزن',
          value: element.weight,
          items: PdfFontWeight.values,
          labelOf: (PdfFontWeight weight) => switch (weight) {
            PdfFontWeight.regular => context.l10n?.editorWeightRegular ?? 'عادي',
            PdfFontWeight.semiBold => context.l10n?.editorWeightSemiBold ?? 'متوسط',
            PdfFontWeight.bold => context.l10n?.editorWeightBold ?? 'عريض',
          },
          onChanged: (PdfFontWeight weight) =>
              controller.updateTextStyle(weight: weight),
        ),
        NumberField(
          label: context.l10n?.editorFontSize ?? 'حجم الخط',
          value: element.fontSize,
          min: 4,
          max: 240,
          onChanged: (double value) =>
              controller.updateTextStyle(fontSize: value),
        ),
        NumberField(
          label: context.l10n?.editorLetterSpacing ?? 'تباعد الحروف',
          value: element.letterSpacing,
          decimals: 1,
          step: 0.5,
          min: -5,
          max: 20,
          onChanged: (double value) =>
              controller.updateTextStyle(letterSpacing: value),
        ),
        NumberField(
          label: context.l10n?.editorLineHeight ?? 'ارتفاع السطر',
          value: element.lineHeight,
          decimals: 2,
          step: 0.05,
          min: 0.8,
          max: 3,
          onChanged: (double value) =>
              controller.updateTextStyle(lineHeight: value),
        ),
        // لون النص وخلفيته انتقلا إلى بطاقة «المظهر والمؤثرات» (التعبئة وما
        // يلحقها تجتمع في مكان واحد).
        SegmentedField<ElementTextAlign>(
          label: context.l10n?.editorTextAlign ?? 'المحاذاة',
          value: element.align,
          options: ElementTextAlign.values,
          labelOf: (ElementTextAlign align) => switch (align) {
            ElementTextAlign.start => context.l10n?.editorAlignStart ?? 'بداية',
            ElementTextAlign.center => context.l10n?.editorAlignCenter ?? 'وسط',
            ElementTextAlign.end => context.l10n?.editorAlignEnd ?? 'نهاية',
            ElementTextAlign.justify => context.l10n?.editorAlignJustify ?? 'ضبط',
          },
          iconOf: (ElementTextAlign align) => switch (align) {
            ElementTextAlign.start => Icons.format_align_right_rounded,
            ElementTextAlign.center => Icons.format_align_center_rounded,
            ElementTextAlign.end => Icons.format_align_left_rounded,
            ElementTextAlign.justify => Icons.format_align_justify_rounded,
          },
          onChanged: (ElementTextAlign align) =>
              controller.updateTextStyle(align: align),
        ),
        // طريقة الضبط تظهر فقط عند اختيار «ضبط» — فلا تُشغل مساحةً في غيره.
        if (element.align == ElementTextAlign.justify)
          SegmentedField<JustifyMode>(
            label: context.l10n?.editorJustifyMode ?? 'طريقة الضبط',
            hint: context.l10n?.editorJustifyHint ??
                'الكشيدة تُطبَّق في ملف PDF (المعاينة تُظهر ضبط الفراغات)',
            value: element.justifyMode,
            options: JustifyMode.values,
            labelOf: (JustifyMode mode) => switch (mode) {
              JustifyMode.spaces => context.l10n?.editorJustifySpaces ?? 'فراغات',
              JustifyMode.kashida => context.l10n?.editorJustifyKashida ?? 'كشيدة',
            },
            onChanged: (JustifyMode mode) =>
                controller.updateTextStyle(justifyMode: mode),
          ),
        SegmentedField<ElementVerticalAlign>(
          label: context.l10n?.editorVerticalAlign ?? 'المحاذاة الرأسية',
          value: element.verticalAlign,
          options: ElementVerticalAlign.values,
          labelOf: (ElementVerticalAlign align) => switch (align) {
            ElementVerticalAlign.top => context.l10n?.editorVerticalTop ?? 'أعلى',
            ElementVerticalAlign.middle => context.l10n?.editorAlignCenter ?? 'وسط',
            ElementVerticalAlign.bottom => context.l10n?.editorVerticalBottom ?? 'أسفل',
          },
          onChanged: (ElementVerticalAlign align) =>
              controller.updateTextStyle(verticalAlign: align),
        ),
        SegmentedField<ElementDirection>(
          label: context.l10n?.editorDirection ?? 'الاتجاه',
          hint: context.l10n?.editorDirectionHint ??
              'اختصار التبديل: Ctrl+Shift+D',
          value: element.direction,
          options: ElementDirection.values,
          labelOf: (ElementDirection direction) => switch (direction) {
            ElementDirection.rtl => context.l10n?.editorDirectionRtl ?? 'عربي',
            ElementDirection.ltr => context.l10n?.editorDirectionLtr ?? 'لاتيني',
            ElementDirection.auto =>
              context.l10n?.editorDirectionAuto ?? 'تلقائي',
          },
          onChanged: (ElementDirection direction) =>
              controller.updateTextStyle(direction: direction),
        ),
      ],
    );
  }

  // ==========================================================================
  //  التأثيرات والضبط اللوني (نمط Photoshop)
  // ==========================================================================

  /// أدوات التعبئة والحدود لكل نوع عنصر — جزء «المظهر» من بطاقة المظهر
  /// والمؤثرات (لون النص للكتابة، والتعبئة والحدّ للأشكال).
  List<Widget> _appearancePaintControls(
    TemplateEditorController controller,
    TemplateElement element,
  ) {
    switch (element) {
      case TextElement text:
        return <Widget>[
          ColorField(
            label: context.l10n?.editorTextColor ?? 'لون النص',
            hex: text.colorHex,
            onChanged: (String hex) =>
                controller.updateTextStyle(colorHex: hex),
          ),
          ColorField(
            label: context.l10n?.editorTextBackground ?? 'خلفية النص',
            hex: text.backgroundHex,
            onChanged: (String hex) =>
                controller.updateTextStyle(backgroundHex: hex),
            onClear: () => controller.updateTextStyle(backgroundHex: null),
          ),
        ];
      case ShapeElement shape:
        return _shapeFillStrokeControls(controller, shape);
      default:
        return const <Widget>[];
    }
  }

  /// تعبئة الشكل (موحّدة أو متدرّجة) وحدوده.
  ///
  /// كانت في بطاقة «الشكل» منفصلةً عن الظل والتوهّج، وانتقلت إلى بطاقة
  /// «المظهر والمؤثرات» فتجتمع أدوات لون العنصر كلها في مكان واحد.
  List<Widget> _shapeFillStrokeControls(
    TemplateEditorController controller,
    ShapeElement element,
  ) {
    final ShapeGradient? gradient = element.gradient;
    final ShapeFillKind fillKind = gradient?.kind ?? ShapeFillKind.solid;

    void setFillKind(ShapeFillKind kind) {
      if (kind == ShapeFillKind.solid) {
        controller.setSelectedShapeStyle(gradient: null);
        return;
      }
      controller.setSelectedShapeStyle(
        gradient: ShapeGradient(
          startHex: gradient?.startHex ?? element.fillHex ?? '#C7A26B',
          endHex: gradient?.endHex ?? '#1B2539',
          angle: gradient?.angle ?? 90,
          kind: kind,
        ),
      );
    }

    return <Widget>[
      SegmentedField<ShapeFillKind>(
        key: const ValueKey<String>('shape-fill-kind'),
        label: context.l10n?.editorFillType ?? 'نوع التعبئة',
        value: fillKind,
        options: const <ShapeFillKind>[
          ShapeFillKind.solid,
          ShapeFillKind.linearGradient,
          ShapeFillKind.radialGradient,
        ],
        labelOf: (ShapeFillKind kind) => switch (kind) {
          ShapeFillKind.solid => context.l10n?.editorFillSolid ?? 'لون موحّد',
          ShapeFillKind.linearGradient =>
            context.l10n?.editorGradientLinear ?? 'تدرّج خطي',
          ShapeFillKind.radialGradient =>
            context.l10n?.editorGradientRadial ?? 'تدرّج شعاعي',
        },
        onChanged: setFillKind,
      ),
      if (gradient == null) ...<Widget>[
        ColorField(
          label: context.l10n?.editorFillColor ?? 'لون التعبئة',
          hex: element.fillHex,
          onChanged: (String hex) =>
              controller.setSelectedShapeStyle(fillHex: hex),
          onClear: () => controller.setSelectedShapeStyle(fillHex: null),
        ),
        // شفافية التعبئة وحدها (تبقى الحدود معتمة) — تظليل ناعم داخل الإطار.
        SliderField(
          label: context.l10n?.editorFillOpacity ?? 'شفافية التعبئة',
          value: element.fillOpacity,
          min: 0,
          max: 1,
          divisions: 20,
          display: (double value) => '${(value * 100).round()}%',
          onChanged: (double value) =>
              controller.setSelectedShapeStyle(fillOpacity: value),
        ),
      ] else ...<Widget>[
        ColorField(
          label: context.l10n?.editorGradientFrom ?? 'لون البداية',
          hex: gradient.startHex,
          onChanged: (String hex) => controller.setSelectedShapeStyle(
            gradient: gradient.copyWith(startHex: hex),
          ),
        ),
        ColorField(
          label: context.l10n?.editorGradientTo ?? 'لون النهاية',
          hex: gradient.endHex,
          onChanged: (String hex) => controller.setSelectedShapeStyle(
            gradient: gradient.copyWith(endHex: hex),
          ),
        ),
        SliderField(
          label: context.l10n?.editorGradientAngle ?? 'زاوية التدرّج',
          value: gradient.angle,
          min: 0,
          max: 360,
          divisions: 72,
          display: (double value) => '${value.round()}°',
          onChanged: (double value) => controller.setSelectedShapeStyle(
            gradient: gradient.copyWith(angle: value),
          ),
        ),
      ],
      ColorField(
        label: context.l10n?.editorBorderColor ?? 'لون الحدود',
        hex: element.strokeHex,
        onChanged: (String hex) =>
            controller.setSelectedShapeStyle(strokeHex: hex),
        onClear: () => controller.setSelectedShapeStyle(strokeHex: null),
      ),
      NumberField(
        label: context.l10n?.editorBorderWidth ?? 'سماكة الحدود',
        value: element.strokeWidth,
        decimals: 1,
        step: 0.5,
        min: 0,
        max: 40,
        onChanged: (double value) =>
            controller.setSelectedShapeStyle(strokeWidth: value),
      ),
    ];
  }

  /// قسم واحد يجمع **كل** التأثيرات: الظل (Drop Shadow)، التوهّج الخارجي
  /// والداخلي (Glow)، والضبط اللوني للصور النقطية (سطوع/تباين/تدوير لوني/تشبّع).
  ///
  /// لماذا قسم واحد؟ لأن التأثيرات تُجرَّب معاً (ظل + توهّج + ضبط) فيضيق عن
  /// نثرها على ثلاثة أقسام. وعنوان القسم «التأثيرات والضبط اللوني»، ودخوله
  /// في [AccordionScope] يجعل فتحه يُغلق الأقسام الأخرى تلقائياً.
  ///
  /// مفاتيح الأدوات الداخلية محفوظة كما كانت (`text-shadow-*` و`shape-shadow-*`)
  /// فلا تنكسر أدوات يعرفها المستخدم ولا اختباراتها.
  Widget _effectsSection(
    TemplateEditorController controller,
    TemplateElement element,
  ) {
    final List<Widget> children = <Widget>[
      // (0) التعبئة والحدود: ألوان العنصر (تعبئته وحدّه) تجتمع هنا مع مؤثراته،
      // فتصير البطاقة بيت «المظهر والمؤثرات» كاملاً كما في مفتشات Photoshop.
      ..._appearancePaintControls(controller, element),
    ];

    // (1) الظل — بحقول خاصة بكل نوع ومفاتيح موحّدة الفكر.
    switch (element) {
      case TextElement text:
        children.add(_effectGroup(
          context.l10n?.editorTextShadow ?? 'ظل النص',
          Icons.blur_on_rounded,
        ));
        children.addAll(_textShadowControls(controller, text));
      case ShapeElement shape:
        children.add(_effectGroup(
          context.l10n?.editorShadowGroup ?? 'الظل',
          Icons.blur_on_rounded,
        ));
        children.addAll(_shapeShadowControls(controller, shape));
      case ImageElement image:
        children.add(_effectGroup(
          context.l10n?.editorShadowGroup ?? 'الظل',
          Icons.blur_on_rounded,
        ));
        children.addAll(_imageShadowControls(controller, image));
      default:
        break;
    }

    // (2) التوهّج الخارجي — للنص والشكل والصورة.
    if (element is TextElement ||
        element is ShapeElement ||
        element is ImageElement) {
      children.add(_effectGroup(
        context.l10n?.editorOuterGlow ?? 'توهّج خارجي',
        Icons.auto_awesome_rounded,
      ));
      children.addAll(_glowControls(
        keyPrefix: 'outer-glow',
        glow: _outerGlowOf(element),
        onChanged: (GlowEffect? glow) =>
            controller.setSelectedGlow(outerGlow: glow),
      ));
    }

    // (3) التوهّج الداخلي — للنص والشكل (الصورة تحتاج قصّاً بكسلياً).
    if (element is TextElement || element is ShapeElement) {
      children.add(_effectGroup(
        context.l10n?.editorInnerGlow ?? 'توهّج داخلي',
        Icons.brightness_low_rounded,
      ));
      children.addAll(_glowControls(
        keyPrefix: 'inner-glow',
        glow: _innerGlowOf(element),
        onChanged: (GlowEffect? glow) =>
            controller.setSelectedGlow(innerGlow: glow),
      ));
    }

    // (4) الضبط اللوني — للصور النقطية وحدها.
    if (element is ImageElement) {
      children.add(_effectGroup(
        context.l10n?.editorAdjustGroup ?? 'الضبط اللوني',
        Icons.tune_rounded,
      ));
      children.addAll(_adjustmentControls(controller, element));
    }

    return ControlSection(
      key: ValueKey<String>('effects-section-${element.id}'),
      sectionId: 'effects',
      icon: Icons.auto_awesome_rounded,
      label: context.l10n?.editorAppearanceEffects ?? 'المظهر والمؤثرات',
      subtitle: context.l10n?.editorAppearanceEffectsHint ??
          'التعبئة والحدود والتوهّج والظلال',
      children: children,
    );
  }

  /// عنوان مجموعة داخل قسم التأثيرات (الظل / التوهّج الخارجي …).
  Widget _effectGroup(String label, IconData icon) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );

  GlowEffect? _outerGlowOf(TemplateElement element) => switch (element) {
        TextElement() => element.outerGlow,
        ShapeElement() => element.outerGlow,
        ImageElement() => element.outerGlow,
        _ => null,
      };

  GlowEffect? _innerGlowOf(TemplateElement element) => switch (element) {
        TextElement() => element.innerGlow,
        ShapeElement() => element.innerGlow,
        _ => null,
      };

  /// أدوات ظل النص (مفاتيح `text-shadow-*` كما كانت + التوسيع الجديد).
  List<Widget> _textShadowControls(
    TemplateEditorController controller,
    TextElement element,
  ) {
    final TextShadow? shadow = element.shadow;
    if (shadow == null) {
      return <Widget>[
        OutlinedButton.icon(
          key: const ValueKey<String>('text-shadow-add'),
          onPressed: () => controller.setSelectedTextShadow(const TextShadow()),
          icon: const Icon(Icons.blur_on_rounded, size: 16),
          label: Text(context.l10n?.editorTextShadowAdd ?? 'إضافة ظل للنص'),
        ),
      ];
    }
    return <Widget>[
      ColorField(
        key: const ValueKey<String>('text-shadow-color'),
        label: context.l10n?.editorShadowColor ?? 'لون الظل',
        hex: shadow.colorHex,
        onChanged: (String hex) =>
            controller.setSelectedTextShadow(shadow.copyWith(colorHex: hex)),
      ),
      SliderField(
        key: const ValueKey<String>('text-shadow-opacity'),
        label: context.l10n?.editorShadowOpacity ?? 'شفافية الظل',
        value: shadow.opacity.clamp(0, 1),
        min: 0,
        max: 1,
        display: (double value) => '${(value * 100).round()}%',
        onChanged: (double value) =>
            controller.setSelectedTextShadow(shadow.copyWith(opacity: value)),
      ),
      SliderField(
        key: const ValueKey<String>('text-shadow-blur'),
        label: context.l10n?.editorShadowBlur ?? 'تمويه الظل',
        value: shadow.blurRadius.clamp(0, 40),
        min: 0,
        max: 40,
        divisions: 40,
        display: (double value) => '${value.round()}',
        onChanged: (double value) => controller
            .setSelectedTextShadow(shadow.copyWith(blurRadius: value)),
      ),
      SliderField(
        key: const ValueKey<String>('text-shadow-spread'),
        label: context.l10n?.editorShadowSpread ?? 'انتشار الظل',
        value: shadow.spread.clamp(0, 40),
        min: 0,
        max: 40,
        divisions: 40,
        display: (double value) => '${value.round()}',
        onChanged: (double value) =>
            controller.setSelectedTextShadow(shadow.copyWith(spread: value)),
      ),
      NumberField(
        key: const ValueKey<String>('text-shadow-offset-x'),
        label: context.l10n?.editorShadowOffsetX ?? 'إزاحة أفقية',
        value: shadow.offsetX,
        min: -60,
        max: 60,
        onChanged: (double value) =>
            controller.setSelectedTextShadow(shadow.copyWith(offsetX: value)),
      ),
      NumberField(
        key: const ValueKey<String>('text-shadow-offset-y'),
        label: context.l10n?.editorShadowOffsetY ?? 'إزاحة رأسية',
        value: shadow.offsetY,
        min: -60,
        max: 60,
        onChanged: (double value) =>
            controller.setSelectedTextShadow(shadow.copyWith(offsetY: value)),
      ),
      TextButton.icon(
        key: const ValueKey<String>('text-shadow-remove'),
        onPressed: () => controller.setSelectedTextShadow(null),
        icon: const Icon(Icons.close_rounded, size: 16),
        label: Text(context.l10n?.editorShadowRemove ?? 'إزالة الظل'),
      ),
    ];
  }

  /// أدوات ظل الشكل (مفاتيح `shape-shadow-*` جديدة للفحص + شفافية الظل).
  List<Widget> _shapeShadowControls(
    TemplateEditorController controller,
    ShapeElement element,
  ) {
    final ShapeShadow? shadow = element.shadow;
    if (shadow == null) {
      return <Widget>[
        OutlinedButton.icon(
          key: const ValueKey<String>('shape-shadow-add'),
          onPressed: () =>
              controller.setSelectedShapeStyle(shadow: const ShapeShadow()),
          icon: const Icon(Icons.blur_on_rounded, size: 16),
          label: Text(context.l10n?.editorShadowEnable ?? 'إضافة ظل'),
        ),
      ];
    }
    return <Widget>[
      ColorField(
        key: const ValueKey<String>('shape-shadow-color'),
        label: context.l10n?.editorShadowColor ?? 'لون الظل',
        hex: shadow.colorHex,
        onChanged: (String hex) => controller
            .setSelectedShapeStyle(shadow: shadow.copyWith(colorHex: hex)),
      ),
      SliderField(
        key: const ValueKey<String>('shape-shadow-opacity'),
        label: context.l10n?.editorShadowOpacity ?? 'شفافية الظل',
        value: shadow.opacity.clamp(0, 1),
        min: 0,
        max: 1,
        display: (double value) => '${(value * 100).round()}%',
        onChanged: (double value) => controller
            .setSelectedShapeStyle(shadow: shadow.copyWith(opacity: value)),
      ),
      SliderField(
        key: const ValueKey<String>('shape-shadow-blur'),
        label: context.l10n?.editorShadowBlur ?? 'تمويه الظل',
        value: shadow.blurRadius.clamp(0, 40),
        min: 0,
        max: 40,
        divisions: 40,
        display: (double value) => '${value.round()}',
        onChanged: (double value) => controller
            .setSelectedShapeStyle(shadow: shadow.copyWith(blurRadius: value)),
      ),
      SliderField(
        key: const ValueKey<String>('shape-shadow-spread'),
        label: context.l10n?.editorShadowSpread ?? 'انتشار الظل',
        value: shadow.spread.clamp(0, 40),
        min: 0,
        max: 40,
        divisions: 40,
        display: (double value) => '${value.round()}',
        onChanged: (double value) => controller
            .setSelectedShapeStyle(shadow: shadow.copyWith(spread: value)),
      ),
      NumberField(
        key: const ValueKey<String>('shape-shadow-offset-x'),
        label: context.l10n?.editorShadowOffsetX ?? 'إزاحة أفقية',
        value: shadow.offsetX,
        min: -60,
        max: 60,
        onChanged: (double value) => controller
            .setSelectedShapeStyle(shadow: shadow.copyWith(offsetX: value)),
      ),
      NumberField(
        key: const ValueKey<String>('shape-shadow-offset-y'),
        label: context.l10n?.editorShadowOffsetY ?? 'إزاحة رأسية',
        value: shadow.offsetY,
        min: -60,
        max: 60,
        onChanged: (double value) => controller
            .setSelectedShapeStyle(shadow: shadow.copyWith(offsetY: value)),
      ),
      TextButton.icon(
        key: const ValueKey<String>('shape-shadow-remove'),
        onPressed: () => controller.setSelectedShapeStyle(shadow: null),
        icon: const Icon(Icons.close_rounded, size: 16),
        label: Text(context.l10n?.editorShadowRemove ?? 'إزالة الظل'),
      ),
    ];
  }

  /// أدوات ظل الصورة (مفاتيح `image-shadow-*`) — نفس دلالة ظل الشكل.
  List<Widget> _imageShadowControls(
    TemplateEditorController controller,
    ImageElement element,
  ) {
    final ShapeShadow? shadow = element.shadow;
    if (shadow == null) {
      return <Widget>[
        OutlinedButton.icon(
          key: const ValueKey<String>('image-shadow-add'),
          onPressed: () => controller.setSelectedImageShadow(const ShapeShadow()),
          icon: const Icon(Icons.blur_on_rounded, size: 16),
          label: Text(context.l10n?.editorShadowEnable ?? 'إضافة ظل'),
        ),
      ];
    }
    return <Widget>[
      ColorField(
        key: const ValueKey<String>('image-shadow-color'),
        label: context.l10n?.editorShadowColor ?? 'لون الظل',
        hex: shadow.colorHex,
        onChanged: (String hex) =>
            controller.setSelectedImageShadow(shadow.copyWith(colorHex: hex)),
      ),
      SliderField(
        key: const ValueKey<String>('image-shadow-opacity'),
        label: context.l10n?.editorShadowOpacity ?? 'شفافية الظل',
        value: shadow.opacity.clamp(0, 1),
        min: 0,
        max: 1,
        display: (double value) => '${(value * 100).round()}%',
        onChanged: (double value) =>
            controller.setSelectedImageShadow(shadow.copyWith(opacity: value)),
      ),
      SliderField(
        key: const ValueKey<String>('image-shadow-blur'),
        label: context.l10n?.editorShadowBlur ?? 'تمويه الظل',
        value: shadow.blurRadius.clamp(0, 40),
        min: 0,
        max: 40,
        divisions: 40,
        display: (double value) => '${value.round()}',
        onChanged: (double value) => controller
            .setSelectedImageShadow(shadow.copyWith(blurRadius: value)),
      ),
      NumberField(
        key: const ValueKey<String>('image-shadow-offset-x'),
        label: context.l10n?.editorShadowOffsetX ?? 'إزاحة أفقية',
        value: shadow.offsetX,
        min: -60,
        max: 60,
        onChanged: (double value) =>
            controller.setSelectedImageShadow(shadow.copyWith(offsetX: value)),
      ),
      NumberField(
        key: const ValueKey<String>('image-shadow-offset-y'),
        label: context.l10n?.editorShadowOffsetY ?? 'إزاحة رأسية',
        value: shadow.offsetY,
        min: -60,
        max: 60,
        onChanged: (double value) =>
            controller.setSelectedImageShadow(shadow.copyWith(offsetY: value)),
      ),
      TextButton.icon(
        key: const ValueKey<String>('image-shadow-remove'),
        onPressed: () => controller.setSelectedImageShadow(null),
        icon: const Icon(Icons.close_rounded, size: 16),
        label: Text(context.l10n?.editorShadowRemove ?? 'إزالة الظل'),
      ),
    ];
  }

  /// أدوات التوهّج (خارجي أو داخلي) — نفس الحقول بالمفاتيح المطلوبة.
  ///
  /// [onChanged] بـ`null` يعني «أزل التوهّج»، فلا يبقى توهّج مطفأ في JSON.
  List<Widget> _glowControls({
    required String keyPrefix,
    required GlowEffect? glow,
    required ValueChanged<GlowEffect?> onChanged,
  }) {
    if (glow == null) {
      return <Widget>[
        OutlinedButton.icon(
          key: ValueKey<String>('$keyPrefix-add'),
          onPressed: () => onChanged(const GlowEffect()),
          icon: const Icon(Icons.auto_awesome_rounded, size: 16),
          label: Text(context.l10n?.editorGlowAdd ?? 'إضافة توهّج'),
        ),
      ];
    }
    return <Widget>[
      ColorField(
        key: ValueKey<String>('$keyPrefix-color'),
        label: context.l10n?.editorGlowColor ?? 'لون التوهّج',
        hex: glow.colorHex,
        onChanged: (String hex) => onChanged(glow.copyWith(colorHex: hex)),
      ),
      SliderField(
        key: ValueKey<String>('$keyPrefix-radius'),
        label: context.l10n?.editorGlowRadius ?? 'نطاق التوهّج',
        value: glow.radius.clamp(0, 60),
        min: 0,
        max: 60,
        divisions: 60,
        display: (double value) => '${value.round()}',
        onChanged: (double value) => onChanged(glow.copyWith(radius: value)),
      ),
      SliderField(
        key: ValueKey<String>('$keyPrefix-spread'),
        label: context.l10n?.editorGlowSpread ?? 'توسّع التوهّج',
        value: glow.spread.clamp(0, 40),
        min: 0,
        max: 40,
        divisions: 40,
        display: (double value) => '${value.round()}',
        onChanged: (double value) => onChanged(glow.copyWith(spread: value)),
      ),
      SliderField(
        key: ValueKey<String>('$keyPrefix-opacity'),
        label: context.l10n?.editorGlowOpacity ?? 'شفافية التوهّج',
        value: glow.opacity.clamp(0, 1),
        min: 0,
        max: 1,
        display: (double value) => '${(value * 100).round()}%',
        onChanged: (double value) => onChanged(glow.copyWith(opacity: value)),
      ),
      TextButton.icon(
        key: ValueKey<String>('$keyPrefix-remove'),
        onPressed: () => onChanged(null),
        icon: const Icon(Icons.close_rounded, size: 16),
        label: Text(context.l10n?.editorGlowRemove ?? 'إزالة التوهّج'),
      ),
    ];
  }

  /// أدوات الضبط اللوني للصورة: سطوع، تباين، تدوير لوني، تشبّع + إعادة ضبط.
  List<Widget> _adjustmentControls(
    TemplateEditorController controller,
    ImageElement element,
  ) {
    final ElementAdjustments current =
        element.adjustments ?? ElementAdjustments.none;

    void update(ElementAdjustments next) =>
        controller.setSelectedImageAdjustments(next);

    return <Widget>[
      SliderField(
        key: const ValueKey<String>('adjust-brightness'),
        label: context.l10n?.editorAdjustBrightness ?? 'السطوع',
        value: current.brightness.clamp(-1, 1),
        min: -1,
        max: 1,
        display: (double value) => '${(value * 100).round()}%',
        onChanged: (double value) =>
            update(current.copyWith(brightness: value)),
      ),
      SliderField(
        key: const ValueKey<String>('adjust-contrast'),
        label: context.l10n?.editorAdjustContrast ?? 'التباين',
        value: current.contrast.clamp(-1, 1),
        min: -1,
        max: 1,
        display: (double value) => '${(value * 100).round()}%',
        onChanged: (double value) => update(current.copyWith(contrast: value)),
      ),
      SliderField(
        key: const ValueKey<String>('adjust-saturation'),
        label: context.l10n?.editorAdjustSaturation ?? 'التشبّع',
        value: current.saturation.clamp(-1, 1),
        min: -1,
        max: 1,
        display: (double value) => '${(value * 100).round()}%',
        onChanged: (double value) =>
            update(current.copyWith(saturation: value)),
      ),
      SliderField(
        key: const ValueKey<String>('adjust-hue'),
        label: context.l10n?.editorAdjustHue ?? 'تدوير اللون',
        value: current.hue.clamp(-180, 180),
        min: -180,
        max: 180,
        divisions: 72,
        display: (double value) => '${value.round()}°',
        onChanged: (double value) => update(current.copyWith(hue: value)),
      ),
      TextButton.icon(
        key: const ValueKey<String>('adjust-reset'),
        onPressed: controller.clearSelectedImageAdjustments,
        icon: const Icon(Icons.restart_alt_rounded, size: 16),
        label: Text(context.l10n?.editorAdjustReset ?? 'إعادة الضبط'),
      ),
    ];
  }

  // ==========================================================================
  //  الصورة
  // ==========================================================================
  Widget _imageSection(
    TemplateEditorController controller,
    ImageElement element,
  ) {
    return ControlSection(
      icon: Icons.image_outlined,
      label: context.l10n?.editorImage ?? 'الصورة',
      children: <Widget>[
        _assetPicker(controller, element),
        DropdownField<ImageSourceKind>(
          label: context.l10n?.editorSource ?? 'المصدر',
          value: element.sourceKind,
          items: ImageSourceKind.values,
          labelOf: (ImageSourceKind kind) => switch (kind) {
            ImageSourceKind.asset =>
              context.l10n?.imageSourceAppAssets ?? 'أصول التطبيق',
            ImageSourceKind.userAsset =>
              context.l10n?.imageSourceMyLibrary ?? 'مكتبة أصولي',
            ImageSourceKind.file =>
              context.l10n?.imageSourceLocalFile ?? 'ملف محلي',
            ImageSourceKind.dataUri =>
              context.l10n?.imageSourceEmbedded ?? 'بيانات مضمّنة',
          },
          onChanged: (ImageSourceKind kind) =>
              controller.setSelectedImagePath(element.path, kind: kind),
        ),
        DropdownField<ImageFit>(
          label: context.l10n?.editorImageFit ?? 'ملاءمة الصورة',
          value: element.fit,
          items: ImageFit.values,
          labelOf: (ImageFit fit) => switch (fit) {
            ImageFit.contain => context.l10n?.editorFitContain ?? 'احتواء كامل',
            ImageFit.cover => context.l10n?.editorFitCover ?? 'تغطية',
            ImageFit.fill => context.l10n?.editorFitFill ?? 'تمديد',
          },
          onChanged: controller.setSelectedImageFit,
        ),
        // تلوين الصورة (الخطوط/الزخرفة) بـ`BlendMode.srcIn`: يتغيّر لون الرسم
        // ويبقى الشفاف شفافاً. وزرّ «بلا» في الحقل يُعيد البكسلات الأصلية.
        ColorField(
          label: context.l10n?.editorImageTint ?? 'تلوين الصورة',
          hex: element.tintHex,
          onChanged: controller.setSelectedImageTint,
          onClear: controller.clearSelectedImageTint,
        ),
        SizedBox(
          width: 260,
          child: _PathField(
            initial: element.sourceKind == ImageSourceKind.userAsset
                ? _assetName(element.path)
                : element.path,
            onChanged: (String value) =>
                controller.setSelectedImagePath(value, kind: element.sourceKind),
          ),
        ),
      ],
    );
  }

  /// منتقي أصول المستخدم: اختيار أصل موجود أو رفع أصل جديد — كله أوفلاين.
  Widget _assetPicker(
    TemplateEditorController controller,
    ImageElement element,
  ) {
    return ListenableBuilder(
      listenable: AssetsController.instance,
      builder: (BuildContext context, Widget? _) {
        final AssetsController assets = AssetsController.instance;
        final List<UserAsset> library = assets.assets;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (library.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  context.l10n?.assetPickerEmptyHint ??
                      'لم ترفع أصولاً بعد. ارفع شعاراً أو توقيعاً أو ختماً لتستخدمه '
                          'هنا وفي الطباعة.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              DropdownField<String>(
                key: const ValueKey<String>('asset-picker'),
                label: context.l10n?.editorFromMyLibrary ?? 'من مكتبة أصولي',
                value: element.sourceKind == ImageSourceKind.userAsset &&
                        assets.byId(element.path) != null
                    ? element.path
                    : '',
                items: <String>[
                  '',
                  ...library.map((UserAsset asset) => asset.id),
                ],
                labelOf: (String id) => id.isEmpty
                    ? context.l10n?.assetPickerNoneOption ?? 'بلا (مصدر آخر)'
                    : '${assets.byId(id)!.name} • ${assets.byId(id)!.typeLabelAr}',
                onChanged: (String id) {
                  final UserAsset? asset = assets.byId(id);
                  if (asset == null) return;
                  // يضمّن Base64 احتياطياً أيضاً (لا يكتفي بالمعرّف).
                  controller.assignSelectedUserAsset(asset);
                },
              ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                key: const ValueKey<String>('asset-picker-button'),
                onPressed: () async {
                  final UserAsset? asset = await showAssetLibraryPicker(
                    context,
                    title: context.l10n?.assetPickerTitle ?? 'اختر صورة من مكتبة أصولي',
                  );
                  if (asset == null) return;
                  controller.assignSelectedUserAsset(asset);
                },
                icon: const Icon(Icons.collections_bookmark_rounded, size: 15),
                label: Text(context.l10n?.editorFromMyLibrary ?? 'من مكتبة أصولي'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                for (final AssetType type in AssetType.values)
                  OutlinedButton.icon(
                    onPressed: () => uploadUserAssets(
                      context,
                      type: type,
                      controller: assets,
                    ),
                    icon: Icon(type.icon, size: 15),
                    label: Text(
                      context.l10n?.assetUploadType(type.labelAr) ??
                          'رفع ${type.labelAr}',
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  static String _assetName(String id) =>
      AssetsController.instance.byId(id)?.name ?? id;

  // ==========================================================================
  //  الختم
  // ==========================================================================
  Widget _sealSection(
    TemplateEditorController controller,
    SealElement element,
  ) {
    return ControlSection(
      icon: Icons.verified_rounded,
      label: context.l10n?.editorSeal ?? 'الختم',
      children: <Widget>[
        ColorField(
          label: context.l10n?.editorSealColor ?? 'لون الختم',
          hex: element.fillHex,
          onChanged: (String hex) =>
              controller.setSelectedSealColors(fillHex: hex),
        ),
        ColorField(
          label: context.l10n?.editorSealRingColor ?? 'لون الحلقة',
          hex: element.ringHex,
          onChanged: (String hex) =>
              controller.setSelectedSealColors(ringHex: hex),
        ),
        ColorField(
          label: context.l10n?.editorSealStarColor ?? 'لون النجمة',
          hex: element.starHex,
          onChanged: (String hex) =>
              controller.setSelectedSealColors(starHex: hex),
        ),
        SliderField(
          label: context.l10n?.editorSealStarSize ?? 'حجم النجمة',
          value: element.starRatio,
          min: 0.1,
          max: 0.95,
          display: (double value) => '${(value * 100).round()}%',
          onChanged: (double value) =>
              controller.setSelectedSealColors(starRatio: value),
        ),
      ],
    );
  }

  // ==========================================================================
  //  الأشكال
  // ==========================================================================
  Widget _shapeSection(
    TemplateEditorController controller,
    ShapeElement element,
  ) {
    final bool isStar = element.kind == ShapeKind.star;
    final bool isPolygon = element.kind == ShapeKind.polygon;
    final bool isRect = element.kind == ShapeKind.rect;

    return ControlSection(
      icon: Icons.crop_square_rounded,
      label: context.l10n?.editorShape ?? 'الشكل',
      children: <Widget>[
        // تعبئة الشكل وحدوده انتقلتا إلى بطاقة «المظهر والمؤثرات»؛ هنا يبقى
        // **هندسة** الشكل وحده: الشرطات والرؤوس ونصف القطر والزوايا.
        // نمط الشرطات: قيمة واحدة تعني طول الشرطة (والفجوة 60% منها).
        NumberField(
          key: const ValueKey<String>('shape-dash'),
          label: context.l10n?.editorDashPattern ?? 'نمط الشرطات',
          value: element.dashPattern != null && element.dashPattern!.isNotEmpty
              ? element.dashPattern!.first
              : 0,
          decimals: 1,
          step: 1,
          min: 0,
          max: 60,
          onChanged: (double value) => controller.setSelectedShapeStyle(
            dashPattern: value <= 0
                ? null
                : <double>[value, value * 0.6],
          ),
        ),
        if (isStar || isPolygon)
          NumberField(
            label: context.l10n?.editorPoints ?? 'عدد الرؤوس',
            value: element.points.toDouble(),
            step: 1,
            decimals: 0,
            min: 3,
            max: 60,
            onChanged: (double value) =>
                controller.setSelectedShapeStyle(points: value.round()),
          ),
        if (isStar)
          SliderField(
            label: context.l10n?.editorInnerRadius ?? 'نصف القطر الداخلي',
            value: element.innerRadius,
            min: 0.05,
            max: 1,
            divisions: 19,
            display: (double value) => '${(value * 100).round()}%',
            onChanged: (double value) =>
                controller.setSelectedShapeStyle(innerRadius: value),
          ),
        if (isRect) ...<Widget>[
          NumberField(
            label: context.l10n?.editorCornerTopLeft ?? 'أعلى-يسار',
            value: _cornerAt(element, 0),
            min: 0,
            max: 200,
            onChanged: (double value) => _setCorner(controller, element, 0, value),
          ),
          NumberField(
            label: context.l10n?.editorCornerTopRight ?? 'أعلى-يمين',
            value: _cornerAt(element, 1),
            min: 0,
            max: 200,
            onChanged: (double value) => _setCorner(controller, element, 1, value),
          ),
          NumberField(
            label: context.l10n?.editorCornerBottomRight ?? 'أسفل-يمين',
            value: _cornerAt(element, 2),
            min: 0,
            max: 200,
            onChanged: (double value) => _setCorner(controller, element, 2, value),
          ),
          NumberField(
            label: context.l10n?.editorCornerBottomLeft ?? 'أسفل-يسار',
            value: _cornerAt(element, 3),
            min: 0,
            max: 200,
            onChanged: (double value) => _setCorner(controller, element, 3, value),
          ),
        ],
        if (element.isCompound)
          OutlinedButton.icon(
            onPressed: controller.ungroupShapeBoolean,
            icon: const Icon(Icons.call_split_rounded, size: 16),
            label: Text(
              context.l10n?.editorBooleanUngroup ?? 'فصل الشكل المركّب',
            ),
          ),
      ],
    );
  }

  /// نصف قطر الركن [index] (أعلى-يسار، أعلى-يمين، أسفل-يمين، أسفل-يسار).
  static double _cornerAt(ShapeElement element, int index) {
    final List<double>? radii = element.cornerRadii;
    if (radii != null && radii.length > index) return radii[index];
    return element.radius;
  }

  void _setCorner(
    TemplateEditorController controller,
    ShapeElement element,
    int index,
    double value,
  ) {
    final List<double> radii = <double>[
      for (int i = 0; i < 4; i++) _cornerAt(element, i),
    ];
    radii[index] = value;
    controller.setSelectedShapeStyle(cornerRadii: radii);
  }

  // ==========================================================================
  //  رمز QR
  // ==========================================================================
  Widget _qrSection(TemplateEditorController controller, QrElement element) {
    return ControlSection(
      icon: Icons.qr_code_2_rounded,
      label: context.l10n?.editorQrVerify ?? 'رمز التحقق',
      children: <Widget>[
        // حقل بعرض مرن أعلى 320: يتقلّص مع عرض البطاقة بدل أن يفيض عليها.
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: _PathField(
            label: context.l10n?.editorQrData ?? 'بيانات الرمز',
            initial: element.data,
            onChanged: controller.setSelectedQrData,
          ),
        ),
        ColorField(
          label: context.l10n?.editorQrColor ?? 'لون الرمز',
          hex: element.colorHex,
          onChanged: (String hex) =>
              controller.updateSelected(
            (TemplateElement e) =>
                e is QrElement ? e.copyWith(colorHex: hex) : e,
          ),
        ),        ColorField(
          label: context.l10n?.editorQrBackground ?? 'خلفية الرمز',
          hex: element.backgroundHex,
          onChanged: (String hex) =>
              controller.updateSelected(
            (TemplateElement e) =>
                e is QrElement ? e.copyWith(backgroundHex: hex) : e,
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  //  الزخرفة المتجهية (إجرائية — بلا صور)
  // ==========================================================================
  Widget _decorationSection(
    TemplateEditorController controller,
    DecorationElement element,
  ) {
    final DecorSpec spec = element.spec;
    return ControlSection(
      icon: Icons.auto_awesome_rounded,
      label: context.l10n?.editorDecorTitle ?? 'الزخرفة المتجهية',
      children: <Widget>[
        DropdownField<DecorKind>(
          key: const ValueKey<String>('decor-kind'),
          label: context.l10n?.editorDecorKind ?? 'نوع الزخرفة',
          value: spec.kind,
          items: DecorKind.values,
          // تسميات الأنواع واللوحات مترجمة (مع الرجوع إلى تسمية النموذج).
          labelOf: _decorKindLabel,
          onChanged: (DecorKind kind) =>
              controller.setSelectedDecorSpec(spec.copyWith(kind: kind)),
        ),
        DropdownField<DecorPalette>(
          key: const ValueKey<String>('decor-palette'),
          label: context.l10n?.editorDecorPalette ?? 'لوحة الألوان',
          value: _paletteFor(spec),
          items: _paletteItems(spec),
          keyOf: (DecorPalette palette) => palette.id,
          labelOf: _decorPaletteLabel,
          onChanged: (DecorPalette palette) =>
              controller.setSelectedDecorSpec(
            spec.copyWith(
              primaryHex: palette.primaryHex,
              secondaryHex: palette.secondaryHex,
              accentHex: palette.accentHex,
            ),
          ),
        ),
        SliderField(
          label: context.l10n?.editorDecorLayers ?? 'عدد الطبقات',
          value: spec.layers.toDouble(),
          min: 1,
          max: VectorDecor.maxLayers.toDouble(),
          divisions: VectorDecor.maxLayers - 1,
          display: (double value) => value.round().toString(),
          onChanged: (double value) => controller.setSelectedDecorSpec(
            spec.copyWith(layers: value.round()),
          ),
        ),
        NumberField(
          label: context.l10n?.editorDecorSeed ?? 'البذرة',
          value: spec.seed.toDouble(),
          min: 0,
          max: 48,
          step: 1,
          onChanged: (double value) => controller.setSelectedDecorSpec(
            spec.copyWith(seed: value.round()),
          ),
        ),
        NumberField(
          label: context.l10n?.editorDecorThickness ?? 'السماكة',
          value: spec.thickness,
          min: 0.5,
          max: 8,
          step: 0.5,
          decimals: 1,
          onChanged: (double value) =>
              controller.setSelectedDecorSpec(spec.copyWith(thickness: value)),
        ),
        ColorField(
          label: context.l10n?.editorDecorPrimary ?? 'اللون الأساسي',
          hex: spec.primaryHex,
          onChanged: (String hex) =>
              controller.setSelectedDecorSpec(spec.copyWith(primaryHex: hex)),
        ),
        ColorField(
          label: context.l10n?.editorDecorSecondary ?? 'اللون الثاني',
          hex: spec.secondaryHex,
          onChanged: (String hex) => controller.setSelectedDecorSpec(
            spec.copyWith(secondaryHex: hex),
          ),
        ),
        ColorField(
          label: context.l10n?.editorDecorAccent ?? 'لون اللمسة',
          hex: spec.accentHex,
          onChanged: (String hex) =>
              controller.setSelectedDecorSpec(spec.copyWith(accentHex: hex)),
        ),
        _decorGradientStrip(spec),
        OutlinedButton.icon(
          key: const ValueKey<String>('decor-preset-gallery'),
          onPressed: () => _showDecorPresetGallery(controller, element),
          icon: const Icon(Icons.grid_view_rounded, size: 16),
          label: Text(context.l10n?.editorDecorGallery ?? context.l10n?.editorDecorGallery ?? 'معرض الوصفات'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 38),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ],
    );
  }

  /// اسم نوع الزخرفة مترجماً — يرجع إلى تسمية النموذج عندما تغيب الترجمة
  /// (كما في الاختبارات التي تبني `MaterialApp` بلا مندوبي ترجمة).
  String _decorKindLabel(DecorKind kind) => switch (kind) {
        DecorKind.modernWave =>
          context.l10n?.decorKindModernWave ?? kind.labelAr,
        DecorKind.paperCut => context.l10n?.decorKindPaperCut ?? kind.labelAr,
        DecorKind.classicCorner =>
          context.l10n?.decorKindClassicCorner ?? kind.labelAr,
        DecorKind.guilloche =>
          context.l10n?.decorKindGuilloche ?? kind.labelAr,
        DecorKind.ribbonBanner =>
          context.l10n?.decorKindRibbonBanner ?? kind.labelAr,
      };

  /// اسم لوحة الألوان مترجماً (المعرّف هو المصدر، لا النص العربي).
  String _decorPaletteLabel(DecorPalette palette) => switch (palette.id) {
        'royal_gold' =>
          context.l10n?.decorPaletteRoyalGold ?? palette.labelAr,
        'royal_blue' =>
          context.l10n?.decorPaletteRoyalBlue ?? palette.labelAr,
        'emerald' => context.l10n?.decorPaletteEmerald ?? palette.labelAr,
        'burgundy' => context.l10n?.decorPaletteBurgundy ?? palette.labelAr,
        'midnight' => context.l10n?.decorPaletteMidnight ?? palette.labelAr,
        'mono' => context.l10n?.decorPaletteMono ?? palette.labelAr,
        _ => palette.labelAr,
      };

  /// عدد التوقيعات مترجماً.
  String _signatureCountLabel(SignatureSlots slots) => switch (slots) {
        SignatureSlots.one =>
          context.l10n?.signatureCountOne ?? slots.labelAr,
        SignatureSlots.two =>
          context.l10n?.signatureCountTwo ?? slots.labelAr,
        SignatureSlots.three =>
          context.l10n?.signatureCountThree ?? slots.labelAr,
      };

  /// عنوان بطاقة الوصفة: النوع واللوحة، كلاهما مترجَم.
  String _decorPresetLabel(DecorPreset preset) =>
      '${_decorKindLabel(preset.spec.kind)} — '
      '${_decorPaletteLabel(_paletteFor(preset.spec))}';

  /// عناصر قائمة اللوحات: لوحات الفهرس + لوحة «مخصصة» إن خرجت الألوان عنها.
  List<DecorPalette> _paletteItems(DecorSpec spec) {
    final DecorPalette matched = _paletteFor(spec);
    if (matched.id != _customPaletteId) return DecorPalette.all;
    return <DecorPalette>[
      ...DecorPalette.all,
      DecorPalette(
        id: _customPaletteId,
        labelAr: context.l10n?.editorDecorPaletteCustom ?? 'مخصصة',
        primaryHex: spec.primaryHex,
        secondaryHex: spec.secondaryHex,
        accentHex: spec.accentHex,
      ),
    ];
  }

  static const String _customPaletteId = 'custom';

  /// اللوحة المطابقة لألوان الوصفة، أو لوحة «مخصصة» إن لم تطابق أيًّا منها.
  DecorPalette _paletteFor(DecorSpec spec) {
    for (final DecorPalette palette in DecorPalette.all) {
      if (palette.primaryHex.toLowerCase() == spec.primaryHex.toLowerCase() &&
          palette.secondaryHex.toLowerCase() ==
              spec.secondaryHex.toLowerCase() &&
          palette.accentHex.toLowerCase() == spec.accentHex.toLowerCase()) {
        return palette;
      }
    }
    return DecorPalette(
      id: _customPaletteId,
      labelAr: context.l10n?.editorDecorPaletteCustom ?? 'مخصصة',
      primaryHex: spec.primaryHex,
      secondaryHex: spec.secondaryHex,
      accentHex: spec.accentHex,
    );
  }

  /// شريط رقيق يعرض تدرّج الألوان الثلاثة كما سيراها المستخدم في الطبقات.
  Widget _decorGradientStrip(DecorSpec spec) {
    return SizedBox(
      width: 190,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.l10n?.editorDecorGradient ?? 'تدرّج الطبقات',
            style: TextStyle(
              fontSize: 11.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            child: SizedBox(
              height: 12,
              child: Row(
                children: <Widget>[
                  for (int i = 0; i <= 6; i++)
                    Expanded(
                      child: ColoredBox(
                        color: colorFromHex(
                          VectorDecor.lerpHex(
                            spec.primaryHex,
                            spec.secondaryHex,
                            i / 6,
                          ),
                          fallback: AppColors.navy,
                        ),
                      ),
                    ),
                  Expanded(
                    child: ColoredBox(
                      color: colorFromHex(
                        spec.accentHex,
                        fallback: AppColors.gold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// معرض الوصفات: بطاقات مصغّرة (نوع × لوحة) تُطبَّق بنقرة واحدة.
  Future<void> _showDecorPresetGallery(
    TemplateEditorController controller,
    DecorationElement element,
  ) async {
    final DecorSpec current = element.spec;
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(context.l10n?.editorDecorGalleryTitle ?? context.l10n?.editorDecorGalleryTitle ?? 'معرض الزخارف الجاهزة'),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        content: SizedBox(
          width: 560,
          height: 400,
          // عمود داخل تمرير (لا قائمة كسولة) لأن عدد الوصفات صغير ومحدود،
          // فيبقى كل بطاقة في شجرة الواجهة ويُمكن التمرير إليها والتحقق منها.
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final DecorKind kind in DecorKind.values) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 4),
                    child: Text(
                      kind.labelAr,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      for (final DecorPreset preset in DecorPreset.forKind(kind))
                        _decorPresetCard(
                          preset: preset,
                          selected: current.kind == kind &&
                              current.primaryHex.toLowerCase() ==
                                  preset.spec.primaryHex.toLowerCase(),
                          onTap: () {
                            controller.setSelectedDecorSpec(preset.spec);
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n?.editorClose ?? context.l10n?.editorClose ?? 'إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _decorPresetCard({
    required DecorPreset preset,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return InkWell(
      key: ValueKey<String>('decor-preset-${preset.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Container(
        width: 150,
        height: 108,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          children: <Widget>[
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: CustomPaint(
                    painter: DecorationPainter(spec: preset.spec),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _decorPresetLabel(preset),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  //  كتلة التوقيعات (حتى 3 خانات)
  // ==========================================================================
  Widget _signatureSection(
    TemplateEditorController controller,
    SignatureElement element,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ControlSection(
          icon: Icons.draw_rounded,
          label: context.l10n?.editorSignatureTitle ?? 'كتلة التوقيعات',
          children: <Widget>[
            DropdownField<SignatureSlots>(
              key: const ValueKey<String>('signature-count'),
              label: context.l10n?.editorSignatureCount ?? 'عدد التوقيعات',
              value: SignatureSlots.fromCount(element.slotCount),
              items: SignatureSlots.values,
              labelOf: _signatureCountLabel,
              onChanged: (SignatureSlots slots) =>
                  controller.setSelectedSignatureSlotCount(slots.count),
            ),
            SegmentedField<ElementDirection>(
              label: context.l10n?.editorSignatureOrder ?? 'ترتيب الخانات',
              hint: context.l10n?.editorSignatureOrderHint ?? 'في المستندات العربية تقع الخانة الأولى في أقصى اليمين.',
              value: element.direction,
              options: ElementDirection.values,
              labelOf: (ElementDirection direction) => switch (direction) {
                ElementDirection.rtl => context.l10n?.editorSignatureFirstRight ?? 'الأولى يميناً',
                ElementDirection.ltr => context.l10n?.editorSignatureFirstLeft ?? 'الأولى يساراً',
                ElementDirection.auto => context.l10n?.editorDirectionAuto ?? 'تلقائي',
              },
              onChanged: (ElementDirection direction) =>
                  controller.setSelectedSignatureStyle(direction: direction),
            ),
            SegmentedField<SignatureAlign>(
              label: context.l10n?.editorSignatureImageAlign ?? 'محاذاة الصورة',
              value: element.align,
              options: SignatureAlign.values,
              labelOf: (SignatureAlign align) => switch (align) {
                SignatureAlign.start => context.l10n?.editorAlignStart ?? 'بداية',
                SignatureAlign.center => context.l10n?.editorAlignCenter ?? 'وسط',
                SignatureAlign.end => context.l10n?.editorAlignEnd ?? 'نهاية',
              },
              onChanged: (SignatureAlign align) =>
                  controller.setSelectedSignatureStyle(align: align),
            ),
            SegmentedField<bool>(
              label: context.l10n?.editorSignatureDivider ?? 'خط التوقيع',
              value: element.showDivider,
              options: const <bool>[true, false],
              labelOf: (bool value) => value ? context.l10n?.editorVisible ?? 'ظاهر' : context.l10n?.editorHidden ?? 'مخفي',
              onChanged: (bool value) => controller.setSelectedSignatureStyle(
                showDivider: value,
              ),
            ),
            NumberField(
              label: context.l10n?.editorSignatureNameSize ?? 'حجم الاسم',
              value: element.nameFontSize,
              min: 6,
              max: 96,
              onChanged: (double value) => controller.setSelectedSignatureStyle(
                nameFontSize: value,
              ),
            ),
            NumberField(
              label: context.l10n?.editorSignatureRoleSize ?? 'حجم الدور',
              value: element.roleFontSize,
              min: 6,
              max: 96,
              onChanged: (double value) =>
                  controller.setSelectedSignatureStyle(roleFontSize: value),
            ),
            NumberField(
              label: context.l10n?.editorSignatureSpacing ?? 'التباعد',
              value: element.spacing,
              min: 0,
              max: 240,
              step: 4,
              onChanged: (double value) =>
                  controller.setSelectedSignatureStyle(spacing: value),
            ),
            SliderField(
              label: context.l10n?.editorSignatureImageSize ?? 'حجم الصورة',
              value: element.imageScale,
              min: 0.2,
              max: 2,
              display: (double value) => '${(value * 100).round()}%',
              onChanged: (double value) =>
                  controller.setSelectedSignatureStyle(imageScale: value),
            ),
            ColorField(
              label: context.l10n?.editorSignatureNameColor ?? 'لون الاسم',
              hex: element.nameColorHex,
              onChanged: (String hex) =>
                  controller.setSelectedSignatureStyle(nameColorHex: hex),
            ),
            ColorField(
              label: context.l10n?.editorSignatureRoleColor ?? 'لون الدور',
              hex: element.roleColorHex,
              onChanged: (String hex) =>
                  controller.setSelectedSignatureStyle(roleColorHex: hex),
            ),
            DropdownField<PdfFontFamily>(
              label: context.l10n?.editorFont ?? 'الخط',
              value: element.family,
              items: PdfFontFamily.pdfFamilies,
              labelOf: (PdfFontFamily family) => family.labelAr,
              onChanged: (PdfFontFamily family) => controller
                  .setSelectedSignatureStyle(family: family, customFont: null),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space12),
        for (int i = 0; i < element.slotCount; i++) ...<Widget>[
          _signatureSlotEditor(controller, element, i),
          const SizedBox(height: AppTheme.space8),
        ],
      ],
    );
  }

  /// محرّر خانة توقيع واحدة: الدور + الاسم + صورة التوقيع.
  Widget _signatureSlotEditor(
    TemplateEditorController controller,
    SignatureElement element,
    int index,
  ) {
    final SignatureSlot slot = element.slotAt(index);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppTheme.space8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${context.l10n?.editorSignatureSlot ?? 'الخانة'} ${index + 1}',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          Wrap(
            spacing: AppTheme.space12,
            runSpacing: AppTheme.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 200,
                child: _PathField(
                  key: ValueKey<String>('signature-role-$index'),
                  label: context.l10n?.editorSignatureRoleField ?? 'الدور (مثل: المدير العام)',
                  initial: slot.role,
                  onChanged: (String value) => controller
                      .updateSelectedSignatureSlot(
                    index,
                    slot.copyWith(role: value),
                  ),
                ),
              ),
              SizedBox(
                width: 200,
                child: _PathField(
                  key: ValueKey<String>('signature-name-$index'),
                  label: context.l10n?.editorSignatureNameField ?? 'اسم المُوقّع (يقبل {{حقل}})',
                  initial: slot.name,
                  onChanged: (String value) => controller
                      .updateSelectedSignatureSlot(
                    index,
                    slot.copyWith(name: value),
                  ),
                ),
              ),
              DropdownField<ImageSourceKind>(
                label: context.l10n?.editorImageSource ?? 'مصدر الصورة',
                value: slot.imageSource,
                items: ImageSourceKind.values,
                labelOf: (ImageSourceKind kind) => switch (kind) {
                  ImageSourceKind.asset => context.l10n?.imageSourceAppAssets ?? 'أصول التطبيق',
                  ImageSourceKind.userAsset => context.l10n?.imageSourceMyLibrary ?? 'مكتبة أصولي',
                  ImageSourceKind.file => context.l10n?.imageSourceLocalFile ?? 'ملف محلي',
                  ImageSourceKind.dataUri => context.l10n?.imageSourceEmbedded ?? 'بيانات مضمّنة',
                },
                onChanged: (ImageSourceKind kind) => controller
                    .updateSelectedSignatureSlot(
                  index,
                  slot.copyWith(imageSource: kind),
                ),
              ),
              OutlinedButton.icon(
                key: ValueKey<String>('signature-image-$index'),
                onPressed: () => _pickSignatureImage(controller, index, slot),
                icon: const Icon(Icons.collections_bookmark_rounded, size: 15),
                label: Text(
                  slot.hasImage ? context.l10n?.editorSignatureChangeImage ?? 'تغيير صورة التوقيع' : context.l10n?.editorSignatureAddImage ?? 'إضافة صورة توقيع',
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
              if (slot.hasImage)
                IconAction(
                  icon: Icons.image_not_supported_outlined,
                  tooltip: context.l10n?.editorSignatureRemoveImage ?? 'إزالة صورة التوقيع',
                  danger: true,
                  onPressed: () => controller.updateSelectedSignatureSlot(
                    index,
                    slot.copyWith(imagePath: '', imageData: null),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// اختيار صورة توقيع من مكتبة الأصول مع تضمين نسخة Base64 احتياطية.
  Future<void> _pickSignatureImage(
    TemplateEditorController controller,
    int index,
    SignatureSlot slot,
  ) async {
    final UserAsset? asset = await showAssetLibraryPicker(
      context,
      title: context.l10n?.editorSignaturePickImageTitle ?? 'اختر صورة التوقيع من مكتبة أصولي',
    );
    if (asset == null) return;
    final String base64 = stripBase64DataUri(asset.base64Data);
    controller.updateSelectedSignatureSlot(
      index,
      slot.copyWith(
        imagePath: asset.id,
        imageSource: ImageSourceKind.userAsset,
        imageData: base64.isEmpty ? null : base64,
      ),
    );
  }

  /// نصّ جاهزة الصيغة الشرطية مترجَمة للعرض في نافذة الإدراج.
  String _genderPresetLabel(String labelKey) {
    final l10n = context.l10n;
    return switch (labelKey) {
      'genderPresetCompleted' => l10n?.genderPresetCompleted ?? 'أتمّ / أتمّت',
      'genderPresetPassed' => l10n?.genderPresetPassed ?? 'اجتاز / اجتازت',
      'genderPresetForStudent' =>
        l10n?.genderPresetForStudent ?? 'للطالب / للطالبة',
      'genderPresetStudent' => l10n?.genderPresetStudent ?? 'الطالب / الطالبة',
      'genderPresetToHim' => l10n?.genderPresetToHim ?? 'له / لها',
      'genderPresetHonoring' =>
        l10n?.genderPresetHonoring ?? 'المتدرّب / المتدرّبة',
      _ => labelKey,
    };
  }

  /// نافذة إدراج صيغة شرطية جاهزة في نهاية نص العنصر المحدد.
  ///
  /// الصيغ شائعة ومجرّبة، والنص المُدرَج **عربي دائماً** (هو نص الشهادة نفسه)
  /// بينما يتبدّل الوصف مع لغة الواجهة.
  Future<void> _showGenderSnippetDialog(
    TemplateEditorController controller,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        key: const ValueKey<String>('gender-snippet-dialog'),
        title: Text(context.l10n?.editorGenderSnippet ?? 'إدراج صيغة شرطية'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                context.l10n?.editorGenderSnippetHint ??
                    'تُدرج صيغة تتبدّل تلقائياً حسب جنس المستفيد.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppTheme.space8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    for (final GenderSnippetPreset preset
                        in GenderGrammar.presets)
                      ListTile(
                        key: ValueKey<String>(
                          'gender-snippet-${preset.labelKey}',
                        ),
                        dense: true,
                        title: Text(_genderPresetLabel(preset.labelKey)),
                        subtitle: Text(
                          '${preset.male} | ${preset.female}',
                          textDirection: TextDirection.rtl,
                        ),
                        trailing: const Icon(Icons.add_rounded, size: 18),
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          controller.insertFieldToken(preset.snippet);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            key: const ValueKey<String>('gender-snippet-close'),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n?.editorClose ?? 'إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showConvertToFieldDialog(TextElement element) {
    final List<String> suggestions = _suggestedFieldKeys();

    final TextEditingController controllerKeyboard =
        TextEditingController();

    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(context.l10n?.editorConvertToField ?? 'تحويل إلى حقل ديناميكي'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                context.l10n?.editorConvertDialogMessage(
                      element.text.isEmpty ? '(نص فارغ)' : element.text,
                    ) ??
                    'التحويل يغيّر النص «${element.text.isEmpty ? '(نص فارغ)' : element.text}» '
                        'إلى علامة `{{...}}`، وتصبح قابلة للربط في التوليد الجماعي.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppTheme.space10),
              DropdownButtonFormField<String>(
                initialValue:
                    suggestions.isNotEmpty ? suggestions.first : null,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.l10n?.editorFieldKeyHint ??
                      'مفتاح الحقل (مثل: الاسم، التاريخ، المرجع)',
                  border: const OutlineInputBorder(),
                ),
                items: <DropdownMenuItem<String>>[
                  for (final String key in suggestions)
                    DropdownMenuItem<String>(
                      value: key,
                      child: Text(key, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (String? value) =>
                    controllerKeyboard.text = value ?? '',
              ),
              const SizedBox(height: AppTheme.space10),
              TextField(
                controller: controllerKeyboard,
                // المفاتيح المقترحة عربية («اسم_المتدرب»…) فاتجاه الحقل
                // صراحةً rtl ليُحسم BIDI عند الإقلاع لا حسب لغة الواجهة.
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText: context.l10n?.editorCustomKeyHint ??
                      'أدخل مفتاح مخصص (بدون أقواس — سيُضاف تلقائياً)',
                  border: const OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 12.5),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n?.editorCancel ?? 'إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final String key =
                  controllerKeyboard.text.trim().isEmpty
                      ? (suggestions.isNotEmpty ? suggestions.first : '')
                      : controllerKeyboard.text.trim();
              if (key.isEmpty) return;
              controller.convertTextToDynamicField(key);
              Navigator.of(context).pop();
            },
            child: Text(context.l10n?.editorConvert ?? 'تحويل'),
          ),
        ],
      ),
    );
  }

  List<String> _suggestedFieldKeys() {
    final List<String> available = controller.document.fieldKeys.toList();
    if (available.isNotEmpty) return available;
    return DynamicFields.all.map((DynamicField field) => field.key).toList(growable: false);
  }
}


/// حقل محتوى نصي بسيط لمحتوى النص/المسار/بيانات الرمز.
class _PathField extends StatefulWidget {
  const _PathField({
    super.key,
    required this.initial,
    required this.onChanged,
    this.label,
  });

  final String initial;
  final ValueChanged<String> onChanged;
  final String? label;

  @override
  State<_PathField> createState() => _PathFieldState();
}

class _PathFieldState extends State<_PathField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void didUpdateWidget(_PathField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initial != _controller.text &&
        !(_controller.selection.isValid &&
            _controller.selection.start >= 0 &&
            _controller.selection.end > 0)) {
      _controller.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      style: const TextStyle(fontSize: 12.5),
      decoration: InputDecoration(
        isDense: true,
        labelText: widget.label ?? context.l10n?.editorPath ?? 'المسار',
        labelStyle: const TextStyle(fontSize: 11.5),
      ),
      onChanged: widget.onChanged,
    );
  }
}

/// محتوى نصي للعنصر النصي مع إدراج الحقول الديناميكية.
///
/// منفصل في ويدجت خاص حتى تبقى مزامنة `TextEditingController` معطاة على عنصر
/// واحد بلا إرباك حين يتغيّر التحديد.
class ElementTextEditor extends StatefulWidget {
  const ElementTextEditor({
    super.key,
    required this.element,
    required this.onChanged,
    this.focusNode,
  });

  final TextElement element;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;

  @override
  State<ElementTextEditor> createState() => _ElementTextEditorState();
}

class _ElementTextEditorState extends State<ElementTextEditor> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.element.text;
  }

  @override
  void didUpdateWidget(ElementTextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final FocusNode? focus = widget.focusNode;
    if (focus?.hasFocus ?? false) return;
    if (widget.element.text != _controller.text) {
      _controller.text = widget.element.text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _insertToken(String token) {
    final TextSelection selection = _controller.selection;
    final int start = selection.isValid ? selection.start : _controller.text.length;
    final int end = selection.isValid ? selection.end : _controller.text.length;

    // فاصل تلقائي حتى لا تلتصق الصيغتان (مثال: `{{التاريخ}}{{الجهة}}`).
    final String before = start > 0 ? _controller.text.substring(0, start) : '';
    final String separator =
        before.isEmpty || before.endsWith(' ') ? '' : ' ';

    final String next =
        _controller.text.replaceRange(start, end, '$separator$token');
    _controller
      ..text = next
      ..selection = TextSelection.collapsed(
        offset: start + separator.length + token.length,
      );
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _controller,
            focusNode: widget.focusNode,
            minLines: 1,
            maxLines: 3,
            // الاتجاه الفعلي للعنصر: عربي ⇒ rtl ولاتيني ltr — ومنه يُحلّ
            // BIDI ويُوجَّه تنقّل الأسهم بصرياً عبر [BidiArrowNavigation]
            // (كان مثبّتاً rtl دائماً فيختلّ تنقّل المؤشر في العناصر
            // اللاتينية).
            textDirection: editorTextIsRtl(widget.element, widget.element.text)
                ? TextDirection.rtl
                : TextDirection.ltr,
            // المحاذاة تتبع محاذاة المستخدم على اللوحة نفسها: start/end
            // تُحلّان باتجاه الحقل فيمثّلان يمين RTL ويسار LTR كما تُرسم
            // العناصر في الورقة («أو المحاذاة المعرّفة بالمستخدم»).
            textAlign: switch (widget.element.align) {
              ElementTextAlign.start => TextAlign.start,
              ElementTextAlign.center => TextAlign.center,
              ElementTextAlign.end => TextAlign.end,
              ElementTextAlign.justify => TextAlign.justify,
            },
            style: const TextStyle(fontSize: 12.5),
            decoration: InputDecoration(
              isDense: true,
              labelText: context.l10n?.editorTextContent ?? 'محتوى النص',
              labelStyle: const TextStyle(fontSize: 11.5),
            ),
            onChanged: widget.onChanged,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final DynamicField field in _fieldsFor(widget.element))
                Tooltip(
                  message: context.l10n?.editorInsertFieldToken(field.token) ??
                      'إدراج ${field.token}',
                  child: InkWell(
                    onTap: () => _insertToken(field.token),
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.goldSoft,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusPill),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        field.key,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.goldDeep,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// الحقول المقترحة: حقول القالب المستخدمة أولاً ثم المكتبة العامة.
  static List<DynamicField> _fieldsFor(TextElement element) {
    final List<DynamicField> preferred = <DynamicField>[];
    final List<DynamicField> library = DynamicFields.all;

    for (final String key in _keysIn(element.text)) {
      final DynamicField? field = DynamicFields.byKey(key);
      if (field != null) preferred.add(field);
    }
    for (final DynamicField field in library) {
      if (preferred.any((DynamicField item) => item.key == field.key)) continue;
      preferred.add(field);
    }
    return preferred.take(9).toList(growable: false);
  }

  static List<String> _keysIn(String text) {
    final RegExp pattern = RegExp(r'\{\{\s*([^}]+?)\s*\}\}');
    return <String>[
      for (final RegExpMatch match in pattern.allMatches(text))
        if (match.group(1) != null) match.group(1)!.trim(),
    ];
  }
}
class ElementPaletteBar extends StatelessWidget {
  const ElementPaletteBar({
    super.key,
    required this.controller,
    this.onTextAdded,
  });

  final TemplateEditorController controller;
  final ValueChanged<TextElement>? onTextAdded;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTheme.space8,
      runSpacing: AppTheme.space8,
      children: <Widget>[
        for (final _PaletteEntry entry in _entries(context))
          _PaletteButton(
            label: entry.label,
            icon: entry.icon,
            tooltip: context.l10n?.editorAddLabel(entry.label) ??
                'إضافة ${entry.label}',
            onTap: () {
              final TemplateElement element = controller.addElement(entry.kind);
              if (element is TextElement) onTextAdded?.call(element);
            },
          ),
        // قسم «أشكال هندسية» — قائمة مضغوطة تُبقي شريط الإضافة صغيراً.
        _ShapesMenuButton(
          onSelected: (NewElementKind kind) {
            final TemplateElement element = controller.addElement(kind);
            if (element is TextElement) onTextAdded?.call(element);
          },
        ),
        _PaletteButton(
          label: context.l10n?.editorFromMyLibrary ?? 'من مكتبة أصولي',
          icon: Icons.collections_bookmark_rounded,
          tooltip: context.l10n?.editorInsertFromLibraryTooltip ?? 'إدراج إطار أو شعار مرفوع مباشرةً',
          onTap: () => _insertFromLibrary(context),
        ),
      ],
    );
  }

  /// إدراج أصل مرفوع (إطار/شعار/ختم/توقيع) كعنصر صورة مربوط بـ `userAsset`.
  ///
  /// الأصول من نوع «إطار» تُدرج بحجم الصفحة كاملةً في الخلف؛ غيرها يُدرج
  /// بحجم معقول في المقدمة مع تحديده للتحرير.
  Future<void> _insertFromLibrary(BuildContext context) async {
    final UserAsset? asset = await showAssetLibraryPicker(context);
    if (asset == null || !context.mounted) return;

    final bool asBackground = asset.type == AssetType.border;
    final TemplateElement element = ElementFactory.fromUserAsset(
      asset: asset,
      design: controller.designSize,
      index: controller.document.elements.length,
      asBackground: asBackground,
    );
    controller.insertElement(element, index: asBackground ? 0 : -1);
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          context.l10n?.assetInsertedSnack(asset.name) ??
              'أُدرج «${asset.name}» في القالب.',
        ),
      ),
    );
  }

  static List<_PaletteEntry> _entries(BuildContext context) =>
      <_PaletteEntry>[
    _PaletteEntry(
      kind: NewElementKind.text,
      label: context.l10n?.editorLabelText ?? 'نص',
      icon: Icons.text_fields_rounded,
    ),
    _PaletteEntry(
      kind: NewElementKind.heading,
      label: context.l10n?.paletteHeading ?? 'عنوان',
      icon: Icons.title_rounded,
    ),
    _PaletteEntry(
      kind: NewElementKind.dynamicField,
      label: context.l10n?.editorLabelDynamicField ?? 'حقل ديناميكي',
      icon: Icons.data_object_rounded,
    ),
    _PaletteEntry(
      kind: NewElementKind.seal,
      label: context.l10n?.editorLabelSeal ?? 'ختم',
      icon: Icons.verified_rounded,
    ),
    _PaletteEntry(
      kind: NewElementKind.image,
      label: context.l10n?.paletteLogo ?? 'شعار/توقيع',
      icon: Icons.image_outlined,
    ),
    _PaletteEntry(
      kind: NewElementKind.signature,
      label: context.l10n?.paletteSignatureBlock ?? 'توقيعات',
      icon: Icons.draw_rounded,
    ),
    _PaletteEntry(
      kind: NewElementKind.qr,
      label: context.l10n?.editorLabelQr ?? 'رمز QR',
      icon: Icons.qr_code_2_rounded,
    ),
  ];
}

/// زرّ قائمة «أشكال هندسية»: يفتح قائمة منسدلة بالأشكال الأساسية (مستطيل،
/// مستطيل بحواف منحنية، دائرة/بيضاوي، خط فاصل) بدل زرّ لكل شكل.
class _ShapesMenuButton extends StatelessWidget {
  const _ShapesMenuButton({required this.onSelected});

  final ValueChanged<NewElementKind> onSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<NewElementKind>(
      key: const ValueKey<String>('palette-shapes'),
      tooltip: context.l10n?.paletteShapes ?? 'أشكال هندسية',
      onSelected: onSelected,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<NewElementKind>>[
        _shapeItem(
          context,
          NewElementKind.rectangle,
          Icons.crop_square_rounded,
          context.l10n?.paletteFrame ?? 'مستطيل/برواز',
        ),
        _shapeItem(
          context,
          NewElementKind.roundedRect,
          Icons.rounded_corner_rounded,
          context.l10n?.paletteRoundedRect ?? 'مستطيل بحواف منحنية',
        ),
        _shapeItem(
          context,
          NewElementKind.ellipse,
          Icons.circle_outlined,
          context.l10n?.paletteEllipse ?? 'دائرة/بيضاوي',
        ),
        _shapeItem(
          context,
          NewElementKind.star,
          Icons.star_outline_rounded,
          context.l10n?.paletteStar ?? 'نجمة',
        ),
        _shapeItem(
          context,
          NewElementKind.polygon,
          Icons.hexagon_outlined,
          context.l10n?.palettePolygon ?? 'مضلّع',
        ),
        _shapeItem(
          context,
          NewElementKind.divider,
          Icons.horizontal_rule_rounded,
          context.l10n?.paletteDivider ?? 'خط فاصل',
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: scheme.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.category_rounded, size: 16, color: scheme.primary),
            const SizedBox(width: 7),
            Text(
              context.l10n?.paletteShapes ?? 'أشكال هندسية',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
            Icon(Icons.expand_more_rounded, size: 16, color: scheme.primary),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<NewElementKind> _shapeItem(
    BuildContext context,
    NewElementKind kind,
    IconData icon,
    String label,
  ) =>
      PopupMenuItem<NewElementKind>(
        value: kind,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
}

class _PaletteEntry {
  const _PaletteEntry({
    required this.kind,
    required this.label,
    required this.icon,
  });

  final NewElementKind kind;
  final String label;
  final IconData icon;
}

/// تحجيم نسبي (نسبة مئوية) مع أزرار تكبير/تصغير وعجلة الفأرة.
///
/// القيمة المعروضة **نسبية لجلسة التحجيم الحالية**: تبدأ من 100% وتُصفَّر
/// تلقائياً عند تغيير العنصر المحدد، لأن المحرّك يطبّق معاملات تحجيم متتالية
/// على الصندوق الحالي (‎لا يوجد مقاس أساس محفوظ لكل عنصر‎).
class _ScaleField extends StatefulWidget {
  const _ScaleField({
    super.key,
    required this.elementId,
    required this.onScale,
  });

  /// نسبة الزيادة لكل نقرة (والعجلة تتحرّك بنصفها).
  static const double percentStep = 5;

  final String elementId;
  final ValueChanged<double> onScale;

  @override
  State<_ScaleField> createState() => _ScaleFieldState();
}

class _ScaleFieldState extends State<_ScaleField> {
  static const double _minPercent = 10;
  static const double _maxPercent = 400;

  double _percent = 100;
  bool _hovered = false;

  @override
  void didUpdateWidget(_ScaleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // عنصر آخر محدد ⇒ مقاس جديد، فنبدأ العدّ من 100% من جديد.
    if (widget.elementId != oldWidget.elementId) _percent = 100;
  }

  void _apply(double targetPercent) {
    final double clamped =
        targetPercent.clamp(_minPercent, _maxPercent).toDouble();
    if (clamped == _percent) return;
    widget.onScale(clamped / _percent);
    setState(() => _percent = clamped);
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (!_hovered || event is! PointerScrollEvent) return;
    final double delta = event.scrollDelta.dy;
    if (delta == 0) return;
    GestureBinding.instance.pointerSignalResolver.register(
      event,
      (PointerSignalEvent resolved) {
        if (resolved is! PointerScrollEvent) return;
        final double direction = resolved.scrollDelta.dy < 0 ? 1 : -1;
        _apply(_percent + direction * (_ScaleField.percentStep / 2));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (PointerEnterEvent _) => _hovered = true,
      onExit: (PointerExitEvent _) => _hovered = false,
      child: Listener(
        onPointerSignal: _onPointerSignal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  context.l10n?.editorScale ?? 'التحجيم',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_percent.round()}%',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  key: const ValueKey<String>('scale-down'),
                  onPressed: () => _apply(_percent - _ScaleField.percentStep),
                  icon: const Icon(Icons.zoom_out_rounded, size: 17),
                  tooltip: context.l10n?.editorScaleDown ?? 'تصغير',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 30, height: 30),
                ),
                IconButton(
                  key: const ValueKey<String>('scale-up'),
                  onPressed: () => _apply(_percent + _ScaleField.percentStep),
                  icon: const Icon(Icons.zoom_in_rounded, size: 17),
                  tooltip: context.l10n?.editorScaleUp ?? 'تكبير',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 30, height: 30),
                ),
              ],
            ),
            Text(
              context.l10n?.editorScaleHint ?? 'تحجيم نسبي حول مركز العنصر (عجلة الفأرة فوق الزر تسرّع الخطوة).',
              style: TextStyle(
                fontSize: 10.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaletteButton extends StatelessWidget {
  const _PaletteButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ??
          context.l10n?.editorAddLabel(label) ??
          'إضافة $label',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
