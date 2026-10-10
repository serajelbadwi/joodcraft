import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HardwareKeyboard;

import '../../l10n/app_l10n.dart';
import '../../models/template_element.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../template_editor_controller.dart';
import 'editor_controls.dart';

/// لوحة الطبقات (Figma-style): تعرض العناصر بترتيب Z من الأعلى إلى الأسفل،
/// وتتيح إعادة الترتيب بالسحب، والقفل، وإظهار/إخفاء، والتحديد المباشر.
///
/// **لماذا لوحة مستقلّة عن شريط الخصائص؟** لأن مشكلة التداخل على اللوحة قد
/// تجعل عنصراً غير قابل للنقر أصلاً؛ هنا يصل المستخدم إلى أي عنصر بالاسم مهما
/// كان مغطّى، ويرتّب المساحة كما في برامج التصميم الاحترافية.
class LayersPanel extends StatelessWidget {
  const LayersPanel({
    super.key,
    required this.controller,
    this.maxRows = 8,
  });

  final TemplateEditorController controller;

  /// أقصى عدد صفوف تُعرض بارتفاع صريح قبل أن تصير اللائحة قابلة للتمرير.
  final int maxRows;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? _) {
        final List<TemplateElement> layers = controller.layerOrder;
        final double rowHeight = 40;

        return ControlSection(
          icon: Icons.layers_rounded,
          label: context.l10n?.editorLayersTitle ?? 'الطبقات',
          children: <Widget>[
            if (layers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  context.l10n?.editorLayersEmpty ??
                      'لا توجد عناصر على هذه الصفحة بعد.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              SizedBox(
                width: 300,
                height: layers.length <= maxRows
                    ? layers.length * rowHeight
                    : maxRows * rowHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    itemCount: layers.length,
                    onReorder: (int oldIndex, int newIndex) =>
                        _onReorder(oldIndex, newIndex, layers),
                    itemBuilder: (BuildContext context, int index) {
                      final TemplateElement element = layers[index];
                      return _LayerTile(
                        key: ValueKey<String>('layer-tile-${element.id}'),
                        controller: controller,
                        element: element,
                        index: index,
                      );
                    },
                  ),
                ),
              ),
            if (controller.selectedIds.length > 1)
              _MultiSelectionActions(controller: controller),
          ],
        );
      },
    );
  }

  /// تحويل ترتيب اللائحة المعروض (الأعلى أولاً) إلى فهرس ترتيب الرسم.
  void _onReorder(
    int oldIndex,
    int newIndex,
    List<TemplateElement> layers,
  ) {
    if (newIndex > oldIndex) newIndex -= 1;
    if (newIndex == oldIndex) return;
    final int length = layers.length;
    // اللائحة معروفة بترتيب معكوس، فالمعروض `i` يقابل `length - 1 - i` في الرسم.
    final int documentTarget = length - 1 - newIndex;
    controller.moveElementTo(layers[oldIndex].id, documentTarget);
  }
}

/// صف طبقة واحدة: الظهور، القفل، الاسم، ومقبض السحب.
class _LayerTile extends StatelessWidget {
  const _LayerTile({
    super.key,
    required this.controller,
    required this.element,
    required this.index,
  });

  final TemplateEditorController controller;
  final TemplateElement element;
  final int index;

  @override
  Widget build(BuildContext context) {
    final bool selected = controller.isSelected(element.id);
    final bool hidden = controller.isElementHidden(element.id);
    final bool locked = controller.isElementLocked(element.id);
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? scheme.primary.withValues(alpha: 0.14)
          : Colors.transparent,
      child: InkWell(
        key: ValueKey<String>('layer-select-${element.id}'),
        onTap: () => controller.selectFromLayer(
          element.id,
          additive: HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed,
        ),
        child: Row(
          children: <Widget>[
            IconAction(
              key: ValueKey<String>('layer-visibility-${element.id}'),
              icon: hidden
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              tooltip: hidden
                  ? (context.l10n?.editorLayerShow ?? 'إظهار العنصر')
                  : (context.l10n?.editorLayerHide ?? 'إخفاء العنصر'),
              selected: hidden,
              size: 30,
              onPressed: () => controller.toggleElementVisibility(element.id),
            ),
            IconAction(
              key: ValueKey<String>('layer-lock-${element.id}'),
              icon: locked ? Icons.lock_rounded : Icons.lock_open_rounded,
              tooltip: locked
                  ? (context.l10n?.editorLayerUnlock ?? 'فك قفل العنصر')
                  : (context.l10n?.editorLayerLock ?? 'قفل العنصر'),
              selected: locked,
              size: 30,
              onPressed: () => controller.toggleElementLock(element.id),
            ),
            const SizedBox(width: 6),
            Icon(_iconFor(element), size: 15, color: scheme.goldDeep),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _labelFor(element, context),
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: hidden
                          ? scheme.onSurface.withValues(alpha: 0.45)
                          : scheme.onSurface,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
            ),
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                child: Icon(
                  Icons.drag_indicator_rounded,
                  size: 16,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// أدوات التحديد المتعدد: المحاذاة والتجميع/فك التجميع.
class _MultiSelectionActions extends StatelessWidget {
  const _MultiSelectionActions({required this.controller});

  final TemplateEditorController controller;

  @override
  Widget build(BuildContext context) {
    final bool grouped = controller.selectionIsGrouped;
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.space8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              _align(context, Icons.align_horizontal_left_rounded,
                  LayerAlign.left, context.l10n?.editorAlignLeft ?? 'محاذاة لليسار'),
              _align(context, Icons.align_horizontal_center_rounded,
                  LayerAlign.centerH, context.l10n?.editorAlignCenterH ?? 'توسيط أفقياً'),
              _align(context, Icons.align_horizontal_right_rounded,
                  LayerAlign.right, context.l10n?.editorAlignRight ?? 'محاذاة لليمين'),
              _align(context, Icons.align_vertical_top_rounded,
                  LayerAlign.top, context.l10n?.editorAlignTop ?? 'محاذاة للأعلى'),
              _align(context, Icons.align_vertical_center_rounded,
                  LayerAlign.centerV, context.l10n?.editorAlignCenterV ?? 'توسيط رأسياً'),
              _align(context, Icons.align_vertical_bottom_rounded,
                  LayerAlign.bottom, context.l10n?.editorAlignBottom ?? 'محاذاة للأسفل'),
            ],
          ),
          if (controller.hasSelectedImage) ...<Widget>[
            const SizedBox(height: 6),
            // تلوين كل صور المجموعة دفعةً واحدة بلون الهوية.
            ColorField(
              key: const ValueKey<String>('layer-tint-field'),
              label: context.l10n?.editorImageTint ?? 'تلوين الصورة',
              hex: _sharedTint(controller),
              width: 190,
              onChanged: controller.setSelectionImageTint,
              onClear: controller.clearSelectionImageTint,
            ),
          ],
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              OutlinedButton.icon(
                key: const ValueKey<String>('layer-group-button'),
                onPressed: grouped ? null : controller.groupSelection,
                icon: const Icon(Icons.workspaces_rounded, size: 15),
                label: Text(context.l10n?.editorGroupSelected ?? 'تجميع المحدد'),
              ),
              OutlinedButton.icon(
                key: const ValueKey<String>('layer-ungroup-button'),
                onPressed: grouped ? controller.ungroupSelection : null,
                icon: const Icon(Icons.scatter_plot_rounded, size: 15),
                label: Text(context.l10n?.editorUngroupSelected ?? 'فك التجميع'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// لون التلوين المشترك لكل صور التحديد، أو `null` إن اختلفت ألوانها.
  String? _sharedTint(TemplateEditorController controller) {
    bool initialized = false;
    String? shared;
    for (final TemplateElement element in controller.selectedElements) {
      if (element is! ImageElement) continue;
      if (!initialized) {
        shared = element.tintHex;
        initialized = true;
        continue;
      }
      if (shared != element.tintHex) return null;
    }
    return shared;
  }

  Widget _align(
    BuildContext context,
    IconData icon,
    LayerAlign align,
    String tooltip,
  ) =>
      IconAction(
        key: ValueKey<String>('layer-align-${align.name}'),
        icon: icon,
        tooltip: tooltip,
        size: 30,
        onPressed: () => controller.alignSelection(align),
      );
}

/// أيقونة نوع العنصر (مطابقة لدلالة لوحة الخصائص).
IconData _iconFor(TemplateElement element) => switch (element) {
      TextElement() => Icons.title_rounded,
      ShapeElement() => Icons.category_rounded,
      SealElement() => Icons.verified_rounded,
      DecorationElement() => Icons.auto_awesome_rounded,
      SignatureElement() => Icons.draw_rounded,
      ImageElement() => Icons.image_rounded,
      QrElement() => Icons.qr_code_2_rounded,
      UnknownElement() => Icons.help_outline_rounded,
    };

/// اسم نوع العنصر المعروض في اللائحة.
String _labelFor(TemplateElement element, BuildContext context) =>
    switch (element) {
      TextElement(:final bool hasDynamicFields) => hasDynamicFields
          ? context.l10n?.editorLabelDynamicField ?? 'حقل ديناميكي'
          : context.l10n?.editorLabelText ?? 'نص',
      ShapeElement() => context.l10n?.editorLabelShape ?? 'شكل',
      SealElement() => context.l10n?.editorLabelSeal ?? 'ختم',
      DecorationElement() =>
        context.l10n?.editorLabelDecoration ?? 'زخرفة متجهية',
      SignatureElement() => context.l10n?.editorLabelSignature ?? 'كتلة توقيعات',
      ImageElement() => context.l10n?.editorLabelImage ?? 'صورة/شعار',
      QrElement() => context.l10n?.editorLabelQr ?? 'رمز QR',
      UnknownElement() => context.l10n?.editorLabelUnknown ?? 'عنصر غير مدعوم',
    };
