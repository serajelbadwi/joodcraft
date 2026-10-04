import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../assets/asset_type_ui.dart';
import '../../assets/asset_upload.dart';
import '../../assets/assets_controller.dart';
import '../../assets/user_asset.dart';
import '../../constants/app_constants.dart';
import '../../constants/dynamic_fields.dart';
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
                      color: AppColors.navy,
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
            color: AppColors.navy,
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
        IconAction(
          icon: Icons.flip_to_front_rounded,
          tooltip: context.l10n?.editorBringForward ?? 'إلى الأمام',
          onPressed: controller.bringForward,
        ),
        const SizedBox(width: 4),
        IconAction(
          icon: Icons.flip_to_back_rounded,
          tooltip: context.l10n?.editorSendToBack ?? 'إلى الخلف',
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
      children: <Widget>[
        if (controller.document.customPageSize == null)
          DropdownField<PaperSize>(
            label: context.l10n?.editorPageSize ?? 'المقاس',
            value: controller.document.paperSize,
            items: PaperSize.values,
            labelOf: (PaperSize size) => size.labelAr,
            onChanged: controller.setPaperSize,
          )
        else
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
            ],
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
      label: context.l10n?.editorPositionAndSize ?? 'الموضع والحجم',
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
        // مفتاح العنصر يجعل حقل النص يُعاد تهيئته عند تغيير التحديد.
        ElementTextEditor(
          key: ValueKey<String>('text-editor-${element.id}'),
          element: element,
          focusNode: widget.textFocusNode,
          onChanged: controller.updateText,
        ),
        DropdownField<PdfFontFamily>(
          label: context.l10n?.editorFont ?? 'الخط',
          value: element.family,
          items: PdfFontFamily.pdfFamilies,
          labelOf: (PdfFontFamily family) => family.labelAr,
          // اختيار خط مضمّن يلغي أي خط مخصص مرتبط بالعنصر.
          onChanged: (PdfFontFamily family) =>
              controller.updateTextStyle(family: family, customFont: null),
        ),
        CustomFontSection(
          selected: element.customFont,
          onChanged: (String? family) =>
              controller.updateTextStyle(customFont: family),
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
        ColorField(
          label: context.l10n?.editorTextColor ?? 'لون النص',
          hex: element.colorHex,
          onChanged: (String hex) =>
              controller.updateTextStyle(colorHex: hex),
        ),
        ColorField(
          label: context.l10n?.editorTextBackground ?? 'خلفية النص',
          hex: element.backgroundHex,
          onChanged: (String hex) =>
              controller.updateTextStyle(backgroundHex: hex),
          onClear: () => controller.updateTextStyle(backgroundHex: null),
        ),
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
    return ControlSection(
      icon: Icons.crop_square_rounded,
      label: context.l10n?.editorShape ?? 'الشكل',
      children: <Widget>[
        ColorField(
          label: context.l10n?.editorFillColor ?? 'لون التعبئة',
          hex: element.fillHex,
          onChanged: (String hex) =>
              controller.setSelectedShapeStyle(fillHex: hex),
          onClear: () => controller.setSelectedShapeStyle(fillHex: null),
        ),
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
        NumberField(
          label: context.l10n?.editorCornerRadius ?? 'استدارة الزوايا',
          value: element.radius,
          min: 0,
          max: 200,
          onChanged: (double value) =>
              controller.setSelectedShapeStyle(radius: value),
        ),
      ],
    );
  }

  // ==========================================================================
  //  رمز QR
  // ==========================================================================
  Widget _qrSection(TemplateEditorController controller, QrElement element) {
    return ControlSection(
      icon: Icons.qr_code_2_rounded,
      label: context.l10n?.editorQrVerify ?? 'رمز التحقق',
      children: <Widget>[
        SizedBox(
          width: 320,
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
            // الاتجاه الفعلي للعنصر: عربي ⇒ rtl فتتحرّك مفاتيح الأسهم والمؤشر
            // منطقيّاً مع الكلمة العربية، وللاتيني ltr. (كان مثبّتاً rtl دائماً
            // فيختل تنقّل المؤشر في العناصر اللاتينية.)
            textDirection: editorTextIsRtl(widget.element, widget.element.text)
                ? TextDirection.rtl
                : TextDirection.ltr,
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
      kind: NewElementKind.rectangle,
      label: context.l10n?.paletteFrame ?? 'مستطيل/برواز',
      icon: Icons.crop_square_rounded,
    ),
    _PaletteEntry(
      kind: NewElementKind.divider,
      label: context.l10n?.paletteDivider ?? 'خط فاصل',
      icon: Icons.horizontal_rule_rounded,
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
