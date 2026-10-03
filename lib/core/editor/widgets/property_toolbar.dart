import 'package:flutter/material.dart';

import '../../assets/asset_type_ui.dart';
import '../../assets/asset_upload.dart';
import '../../assets/assets_controller.dart';
import '../../assets/user_asset.dart';
import '../../constants/app_constants.dart';
import '../../constants/dynamic_fields.dart';
import '../../models/template_element.dart';
import '../../models/template_document.dart';
import '../../pdf/pdf_font_catalog.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../assets/asset_store.dart';
import '../../constants/app_assets.dart';
import '../element_factory.dart';
import '../template_editor_controller.dart';
import 'asset_library_picker.dart';
import 'custom_font_panel.dart';
import 'editor_controls.dart';
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
                  if (element is UnknownElement) ...<Widget>[
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      'هذا العنصر من إصدار أحدث من المحرر — يُحفظ كما هو '
                      'ولا يمكن تعديله هنا.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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
                    tooltip: 'إلغاء التحديد',
                    onPressed: controller.clearSelection,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space12),
              ControlSection(
                icon: Icons.opacity_rounded,
                label: 'المجموعة',
                children: <Widget>[
                  SliderField(
                    label: 'الشفافية',
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
                    label: const Text('إلى المقدمة'),
                    style: _groupButtonStyle,
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.sendToBack,
                    icon: const Icon(Icons.vertical_align_bottom_rounded,
                        size: 16),
                    label: const Text('إلى الخلف'),
                    style: _groupButtonStyle,
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.duplicateSelected,
                    icon: const Icon(Icons.copy_all_rounded, size: 16),
                    label: const Text('تكرار'),
                    style: _groupButtonStyle,
                  ),
                  FilledButton.icon(
                    key: const ValueKey<String>('group-delete'),
                    onPressed: controller.deleteSelected,
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('حذف المحدد'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
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
                _labelFor(element),
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
          tooltip: 'إلى الأمام',
          onPressed: controller.bringForward,
        ),
        const SizedBox(width: 4),
        IconAction(
          icon: Icons.flip_to_back_rounded,
          tooltip: 'إلى الخلف',
          onPressed: controller.sendBackward,
        ),
        const SizedBox(width: 4),
        IconAction(
          icon: Icons.copy_all_rounded,
          tooltip: 'تكرار العنصر',
          onPressed: controller.duplicateSelected,
        ),
        const SizedBox(width: 4),
        IconAction(
          icon: Icons.delete_outline_rounded,
          tooltip: 'حذف العنصر',
          danger: true,
          onPressed: controller.deleteSelected,
        ),
        const SizedBox(width: 4),
        IconAction(
          icon: Icons.close_rounded,
          tooltip: 'إلغاء التحديد',
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
      label: 'إعدادات الصفحة',
      children: <Widget>[
        if (controller.document.customPageSize == null)
          DropdownField<PaperSize>(
            label: 'المقاس',
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
                      label: 'الوحدة',
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
                      label: 'العرض',
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
                      label: 'الارتفاع',
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
        ImageElement() => Icons.image_outlined,
        QrElement() => Icons.qr_code_2_rounded,
        UnknownElement() => Icons.help_outline_rounded,
      };

  static String _labelFor(TemplateElement element) => switch (element) {
        TextElement(:final bool hasDynamicFields) =>
          hasDynamicFields ? 'حقل ديناميكي' : 'نص',
        ShapeElement() => 'شكل',
        SealElement() => 'ختم',
        ImageElement() => 'صورة/شعار',
        QrElement() => 'رمز QR',
        UnknownElement() => 'عنصر غير مدعوم',
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
      label: 'الموضع والحجم',
      children: <Widget>[
        NumberField(
          label: 'س',
          value: box.x,
          unit: 'px',
          min: 0,
          max: design.width,
          onChanged: (double value) =>
              controller.setSelectedBox(box.copyWith(x: value)),
        ),
        NumberField(
          label: 'ص',
          value: box.y,
          unit: 'px',
          min: 0,
          max: design.height,
          onChanged: (double value) =>
              controller.setSelectedBox(box.copyWith(y: value)),
        ),
        NumberField(
          label: 'العرض',
          value: box.width,
          unit: 'px',
          min: 0,
          max: design.width,
          step: 5,
          onChanged: (double value) =>
              controller.setSelectedBox(box.copyWith(width: value)),
        ),
        NumberField(
          label: 'الارتفاع',
          value: box.height,
          unit: 'px',
          min: 0,
          max: design.height,
          step: 5,
          onChanged: (double value) =>
              controller.setSelectedBox(box.copyWith(height: value)),
        ),
        SliderField(
          label: 'الدوران',
          value: element.rotation,
          min: -180,
          max: 180,
          divisions: 72,
          display: (double value) => '${value.round()}°',
          onChanged: controller.setSelectedRotation,
        ),
        SliderField(
          label: 'الشفافية',
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
        _ => 1,
      };

  // ==========================================================================
  //  النص: الخط والنمط والمحتوى والحقول الديناميكية
  // ==========================================================================
  Widget _textSection(
    TemplateEditorController controller,
    TextElement element,
  ) {
    return ControlSection(
      icon: Icons.text_fields_rounded,
      label: 'تنسيق النص',
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
              label: const Text('تحويل إلى حقل ديناميكي'),
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
          label: 'الخط',
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
          label: 'الوزن',
          value: element.weight,
          items: PdfFontWeight.values,
          labelOf: (PdfFontWeight weight) => switch (weight) {
            PdfFontWeight.regular => 'عادي',
            PdfFontWeight.semiBold => 'متوسط',
            PdfFontWeight.bold => 'عريض',
          },
          onChanged: (PdfFontWeight weight) =>
              controller.updateTextStyle(weight: weight),
        ),
        NumberField(
          label: 'حجم الخط',
          value: element.fontSize,
          min: 4,
          max: 240,
          onChanged: (double value) =>
              controller.updateTextStyle(fontSize: value),
        ),
        NumberField(
          label: 'تباعد الحروف',
          value: element.letterSpacing,
          decimals: 1,
          step: 0.5,
          min: -5,
          max: 20,
          onChanged: (double value) =>
              controller.updateTextStyle(letterSpacing: value),
        ),
        NumberField(
          label: 'ارتفاع السطر',
          value: element.lineHeight,
          decimals: 2,
          step: 0.05,
          min: 0.8,
          max: 3,
          onChanged: (double value) =>
              controller.updateTextStyle(lineHeight: value),
        ),
        ColorField(
          label: 'لون النص',
          hex: element.colorHex,
          onChanged: (String hex) =>
              controller.updateTextStyle(colorHex: hex),
        ),
        ColorField(
          label: 'خلفية النص',
          hex: element.backgroundHex,
          onChanged: (String hex) =>
              controller.updateTextStyle(backgroundHex: hex),
          onClear: () => controller.updateTextStyle(backgroundHex: null),
        ),
        SegmentedField<ElementTextAlign>(
          label: 'المحاذاة',
          value: element.align,
          options: ElementTextAlign.values,
          labelOf: (ElementTextAlign align) => switch (align) {
            ElementTextAlign.start => 'بداية',
            ElementTextAlign.center => 'وسط',
            ElementTextAlign.end => 'نهاية',
            ElementTextAlign.justify => 'ضبط',
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
            label: 'طريقة الضبط',
            hint: 'الكشيدة تُطبَّق في ملف PDF (المعاينة تُظهر ضبط الفراغات)',
            value: element.justifyMode,
            options: JustifyMode.values,
            labelOf: (JustifyMode mode) => switch (mode) {
              JustifyMode.spaces => 'فراغات',
              JustifyMode.kashida => 'كشيدة',
            },
            onChanged: (JustifyMode mode) =>
                controller.updateTextStyle(justifyMode: mode),
          ),
        SegmentedField<ElementVerticalAlign>(
          label: 'المحاذاة الرأسية',
          value: element.verticalAlign,
          options: ElementVerticalAlign.values,
          labelOf: (ElementVerticalAlign align) => switch (align) {
            ElementVerticalAlign.top => 'أعلى',
            ElementVerticalAlign.middle => 'وسط',
            ElementVerticalAlign.bottom => 'أسفل',
          },
          onChanged: (ElementVerticalAlign align) =>
              controller.updateTextStyle(verticalAlign: align),
        ),
        SegmentedField<ElementDirection>(
          label: 'الاتجاه',
          hint: 'اختصار التبديل: Ctrl+Shift+D',
          value: element.direction,
          options: ElementDirection.values,
          labelOf: (ElementDirection direction) => switch (direction) {
            ElementDirection.rtl => 'عربي',
            ElementDirection.ltr => 'لاتيني',
            ElementDirection.auto => 'تلقائي',
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
      label: 'الصورة',
      children: <Widget>[
        _assetPicker(controller, element),
        DropdownField<ImageSourceKind>(
          label: 'المصدر',
          value: element.sourceKind,
          items: ImageSourceKind.values,
          labelOf: (ImageSourceKind kind) => switch (kind) {
            ImageSourceKind.asset => 'أصول التطبيق',
            ImageSourceKind.userAsset => 'مكتبة أصولي',
            ImageSourceKind.file => 'ملف محلي',
            ImageSourceKind.dataUri => 'بيانات مضمّنة',
          },
          onChanged: (ImageSourceKind kind) =>
              controller.setSelectedImagePath(element.path, kind: kind),
        ),
        DropdownField<ImageFit>(
          label: 'ملاءمة الصورة',
          value: element.fit,
          items: ImageFit.values,
          labelOf: (ImageFit fit) => switch (fit) {
            ImageFit.contain => 'احتواء كامل',
            ImageFit.cover => 'تغطية',
            ImageFit.fill => 'تمديد',
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
                  'لم ترفع أصولاً بعد. ارفع شعاراً أو توقيعاً أو ختماً لتستخدمه '
                  'هنا وفي الطباعة.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              DropdownField<String>(
                key: const ValueKey<String>('asset-picker'),
                label: 'من مكتبة أصولي',
                value: element.sourceKind == ImageSourceKind.userAsset &&
                        assets.byId(element.path) != null
                    ? element.path
                    : '',
                items: <String>[
                  '',
                  ...library.map((UserAsset asset) => asset.id),
                ],
                labelOf: (String id) => id.isEmpty
                    ? 'بلا (مصدر آخر)'
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
                    title: 'اختر صورة من مكتبة أصولي',
                  );
                  if (asset == null) return;
                  controller.assignSelectedUserAsset(asset);
                },
                icon: const Icon(Icons.collections_bookmark_rounded, size: 15),
                label: const Text('من مكتبة أصولي'),
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
                    label: Text('رفع ${type.labelAr}'),
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
      label: 'الختم',
      children: <Widget>[
        ColorField(
          label: 'لون الختم',
          hex: element.fillHex,
          onChanged: (String hex) =>
              controller.setSelectedSealColors(fillHex: hex),
        ),
        ColorField(
          label: 'لون الحلقة',
          hex: element.ringHex,
          onChanged: (String hex) =>
              controller.setSelectedSealColors(ringHex: hex),
        ),
        ColorField(
          label: 'لون النجمة',
          hex: element.starHex,
          onChanged: (String hex) =>
              controller.setSelectedSealColors(starHex: hex),
        ),
        SliderField(
          label: 'حجم النجمة',
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
      label: 'الشكل',
      children: <Widget>[
        ColorField(
          label: 'لون التعبئة',
          hex: element.fillHex,
          onChanged: (String hex) =>
              controller.setSelectedShapeStyle(fillHex: hex),
          onClear: () => controller.setSelectedShapeStyle(fillHex: null),
        ),
        ColorField(
          label: 'لون الحدود',
          hex: element.strokeHex,
          onChanged: (String hex) =>
              controller.setSelectedShapeStyle(strokeHex: hex),
          onClear: () => controller.setSelectedShapeStyle(strokeHex: null),
        ),
        NumberField(
          label: 'سماكة الحدود',
          value: element.strokeWidth,
          decimals: 1,
          step: 0.5,
          min: 0,
          max: 40,
          onChanged: (double value) =>
              controller.setSelectedShapeStyle(strokeWidth: value),
        ),
        NumberField(
          label: 'استدارة الزوايا',
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
      label: 'رمز التحقق',
      children: <Widget>[
        SizedBox(
          width: 320,
          child: _PathField(
            label: 'بيانات الرمز',
            initial: element.data,
            onChanged: controller.setSelectedQrData,
          ),
        ),
        ColorField(
          label: 'لون الرمز',
          hex: element.colorHex,
          onChanged: (String hex) =>
              controller.updateSelected(
            (TemplateElement e) =>
                e is QrElement ? e.copyWith(colorHex: hex) : e,
          ),
        ),        ColorField(
          label: 'خلفية الرمز',
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

  void _showConvertToFieldDialog(TextElement element) {
    final List<String> suggestions = _suggestedFieldKeys();

    final TextEditingController controllerKeyboard =
        TextEditingController();

    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('تحويل إلى حقل ديناميكي'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'التحويل يغيّر النص «${element.text.isEmpty ? '(نص فارغ)' : element.text}» '
                'إلى علامة `{{...}}`، وتصبح قابلة للربط في التوليد الجماعي.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppTheme.space10),
              DropdownButtonFormField<String>(
                initialValue:
                    suggestions.isNotEmpty ? suggestions.first : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'مفتاح الحقل (مثل: الاسم، التاريخ، المرجع)',
                  border: OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  labelText: 'أدخل مفتاح مخصص (بدون {{}} — سيُضاف تلقائياً)',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 12.5),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
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
            child: const Text('تحويل'),
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
  const _PathField({required this.initial, required this.onChanged, this.label});

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
        labelText: widget.label ?? 'المسار',
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
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'محتوى النص',
              labelStyle: TextStyle(fontSize: 11.5),
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
                  message: 'إدراج ${field.token}',
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
        for (final _PaletteEntry entry in _entries)
          _PaletteButton(
            label: entry.label,
            icon: entry.icon,
            tooltip: 'إضافة ${entry.label}',
            onTap: () {
              final TemplateElement element = controller.addElement(entry.kind);
              if (element is TextElement) onTextAdded?.call(element);
            },
          ),
        _PaletteButton(
          label: 'من مكتبة أصولي',
          icon: Icons.collections_bookmark_rounded,
          tooltip: 'إدراج إطار أو شعار مرفوع مباشرةً',
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
      SnackBar(content: Text('أُدرج «${asset.name}» في القالب.')),
    );
  }

  static const List<_PaletteEntry> _entries = <_PaletteEntry>[
    _PaletteEntry(
      kind: NewElementKind.text,
      label: 'نص',
      icon: Icons.text_fields_rounded,
    ),
    _PaletteEntry(
      kind: NewElementKind.heading,
      label: 'عنوان',
      icon: Icons.title_rounded,
    ),
    _PaletteEntry(
      kind: NewElementKind.dynamicField,
      label: 'حقل ديناميكي',
      icon: Icons.data_object_rounded,
    ),
    _PaletteEntry(
      kind: NewElementKind.rectangle,
      label: 'مستطيل/برواز',
      icon: Icons.crop_square_rounded,
    ),
    _PaletteEntry(
      kind: NewElementKind.divider,
      label: 'خط فاصل',
      icon: Icons.horizontal_rule_rounded,
    ),
    _PaletteEntry(
      kind: NewElementKind.seal,
      label: 'ختم',
      icon: Icons.verified_rounded,
    ),
    _PaletteEntry(
      kind: NewElementKind.image,
      label: 'شعار/توقيع',
      icon: Icons.image_outlined,
    ),
    _PaletteEntry(
      kind: NewElementKind.qr,
      label: 'رمز QR',
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
      message: tooltip ?? 'إضافة $label',
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
