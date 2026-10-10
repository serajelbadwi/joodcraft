import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/jood_writer_block.dart';
import '../../domain/jood_writer_document.dart';
import '../writer_document_controller.dart';

class WriterRibbonBar extends StatelessWidget {
  const WriterRibbonBar({super.key, required this.controller});

  final WriterDocumentController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final JoodWriterBlock? active = controller.activeBlock;
        if (active == null) return const SizedBox.shrink();

        final ColorScheme scheme = Theme.of(context).colorScheme;

        return Container(
          key: const ValueKey('writer-ribbon'),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space12,
            vertical: AppTheme.space8,
          ),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Wrap(
            spacing: AppTheme.space6,
            runSpacing: AppTheme.space6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // 1. نوع الكتلة
              _BlockTypeSelector(active: active, controller: controller),
              _Divider(color: scheme.outlineVariant),

              // 2. الخط والحجم
              _FontFamilySelector(active: active, controller: controller),
              _FontSizeSelector(active: active, controller: controller),
              _Divider(color: scheme.outlineVariant),

              // 3. التنسيق الغني
              _ToolToggle(
                tooltip: 'غامق',
                icon: Icons.format_bold,
                active: active.isBold,
                onPressed: controller.toggleBold,
              ),
              _ToolToggle(
                tooltip: 'مائل',
                icon: Icons.format_italic,
                active: active.isItalic,
                onPressed: controller.toggleItalic,
              ),
              _ToolToggle(
                tooltip: 'تسطير',
                icon: Icons.format_underline,
                active: active.isUnderline,
                onPressed: controller.toggleUnderline,
              ),
              _Divider(color: scheme.outlineVariant),

              // 4. المحاذاة والمسافات
              _ToolToggle(
                tooltip: 'قائمة نقطية',
                icon: Icons.format_list_bulleted,
                active: active.kind == JoodWriterBlockKind.bullet,
                onPressed: () =>
                    controller.setBlockKind(JoodWriterBlockKind.bullet),
              ),
              _ToolToggle(
                tooltip:
                    'قائمة رقمية '
                    '1. 2. 3.',
                icon: Icons.format_list_numbered,
                active: active.kind == JoodWriterBlockKind.numbered,
                onPressed: () =>
                    controller.setBlockKind(JoodWriterBlockKind.numbered),
              ),
              _Divider(color: scheme.outlineVariant),

              _ToolToggle(
                tooltip: 'محاذاة لليمين',
                icon: Icons.format_align_right,
                active: active.align == JoodWriterAlign.start,
                onPressed: () =>
                    controller.setBlockAlign(JoodWriterAlign.start),
              ),
              _ToolToggle(
                tooltip: 'توسيط',
                icon: Icons.format_align_center,
                active: active.align == JoodWriterAlign.center,
                onPressed: () =>
                    controller.setBlockAlign(JoodWriterAlign.center),
              ),
              _ToolToggle(
                tooltip: 'محاذاة لليسار',
                icon: Icons.format_align_left,
                active: active.align == JoodWriterAlign.end,
                onPressed: () => controller.setBlockAlign(JoodWriterAlign.end),
              ),
              _ToolToggle(
                tooltip: 'ضبط',
                icon: Icons.format_align_justify,
                active: active.align == JoodWriterAlign.justify,
                onPressed: () =>
                    controller.setBlockAlign(JoodWriterAlign.justify),
              ),
              _ToolToggle(
                tooltip: 'زيادة إزاحة بداية الفقرة (كاملة)',
                icon: Icons.format_indent_increase,
                active: active.indentCm > 0,
                onPressed: () {
                  if (active.indentCm < 5.0) {
                    controller.updateActiveBlock(
                      active.copyWith(indentCm: active.indentCm + 0.5),
                    );
                  }
                },
              ),
              _ToolToggle(
                tooltip: 'إنقاص الإزاحة (كاملة)',
                icon: Icons.format_indent_decrease,
                active: false,
                onPressed: () {
                  if (active.indentCm >= 0.5) {
                    controller.updateActiveBlock(
                      active.copyWith(indentCm: active.indentCm - 0.5),
                    );
                  }
                },
              ),
              _ToolToggle(
                tooltip: 'زيادة إزاحة السطر الأول',
                icon: Icons.keyboard_tab,
                active: active.firstLineIndentCm > 0,
                onPressed: () {
                  if (active.firstLineIndentCm < 5.0) {
                    controller.setFirstLineIndent(
                      active.firstLineIndentCm + 0.5,
                    );
                  }
                },
              ),
              _ToolToggle(
                tooltip: 'إنقاص إزاحة السطر الأول',
                icon: Icons.keyboard_return,
                active: false,
                onPressed: () {
                  if (active.firstLineIndentCm >= 0.5) {
                    controller.setFirstLineIndent(
                      active.firstLineIndentCm - 0.5,
                    );
                  }
                },
              ),
              _LineSpacingSelector(active: active, controller: controller),
              _Divider(color: scheme.outlineVariant),

              // 5. الألوان
              _ColorDropdown(
                tooltip: 'لون النص',
                icon: Icons.format_color_text,
                selectedColor: active.fontColor ?? Colors.black,
                onColorSelected: controller.setFontColor,
                allowClear: true,
              ),
              _ColorDropdown(
                tooltip: 'تمييز النص',
                icon: Icons.format_color_fill,
                selectedColor: active.highlightColor ?? Colors.transparent,
                onColorSelected: controller.setHighlightColor,
                allowClear: true,
              ),
              _Divider(color: scheme.outlineVariant),

              // 6. إضافة/حذف كتل
              _ToolToggle(
                tooltip: 'إضافة كتلة',
                icon: Icons.add_box_outlined,
                active: false,
                onPressed: controller.addBlockAfterActive,
              ),
              _ToolToggle(
                tooltip: 'حذف كتلة',
                icon: Icons.delete_outline,
                active: false,
                onPressed: controller.document.blocks.length > 1
                    ? controller.deleteActiveBlock
                    : null,
              ),
              _ToolToggle(
                tooltip: 'فاصل صفحات (صفحة جديدة عند المؤشر)',
                icon: Icons.insert_page_break,
                active: false,
                onPressed: controller.insertPageBreakAtCaret,
              ),
              _Divider(color: scheme.outlineVariant),

              // 7. ترقيم الصفحات الذكي
              _ToolToggle(
                tooltip: 'ترقيم الصفحات (صفحة X من Y)',
                icon: Icons.numbers,
                active: controller.document.pageNumbering.enabled,
                onPressed: () => controller.setPageNumberingEnabled(
                  !controller.document.pageNumbering.enabled,
                ),
              ),
              _PageNumberingExcludeMenu(controller: controller),
              _Divider(color: scheme.outlineVariant),

              // 8. وضع العرض: صفحة مفردة أو صفحتان متقابلتان (طي الكتاب)
              _ToolToggle(
                tooltip: 'عرض صفحتين متقابلتين (طي الكتاب)',
                icon: Icons.menu_book,
                active: controller.viewMode == WriterViewMode.spread,
                onPressed: controller.toggleViewMode,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BlockTypeSelector extends StatelessWidget {
  const _BlockTypeSelector({required this.active, required this.controller});
  final JoodWriterBlock active;
  final WriterDocumentController controller;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<JoodWriterBlockKind>(
        value: active.kind,
        isDense: true,
        style: Theme.of(context).textTheme.bodyMedium,
        items: JoodWriterBlockKind.values
            .map((k) => DropdownMenuItem(value: k, child: Text(k.labelAr)))
            .toList(),
        onChanged: (k) {
          if (k != null) controller.setBlockKind(k);
        },
      ),
    );
  }
}

class _FontFamilySelector extends StatelessWidget {
  const _FontFamilySelector({required this.active, required this.controller});
  final JoodWriterBlock active;
  final WriterDocumentController controller;

  @override
  Widget build(BuildContext context) {
    // تشكيلة اوسع من خطوط النظام و الويب القياسية
    const fonts = [
      'Cairo',
      'Arial',
      'Tahoma',
      'Segoe UI',
      'Times New Roman',
      'Amiri',
      'Tajawal',
      'Almarai',
      'Reem Kufi',
    ];
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: fonts.contains(active.fontFamily) ? active.fontFamily : 'Cairo',
        isDense: true,
        style: Theme.of(context).textTheme.bodyMedium,
        items: fonts
            .map(
              (f) => DropdownMenuItem(
                value: f,
                child: Text(f, style: TextStyle(fontFamily: f)),
              ),
            )
            .toList(),
        onChanged: (f) {
          controller.setFontFamily(f == 'Cairo' ? null : f);
        },
      ),
    );
  }
}

class _FontSizeSelector extends StatelessWidget {
  const _FontSizeSelector({required this.active, required this.controller});
  final JoodWriterBlock active;
  final WriterDocumentController controller;

  @override
  Widget build(BuildContext context) {
    const sizes = [
      10.0,
      11.0,
      12.0,
      13.5,
      14.0,
      16.0,
      18.0,
      20.0,
      24.0,
      28.0,
      32.0,
      36.0,
      48.0,
      72.0,
    ];
    // إذا لم يكن محدد بحجم، نظهر أقرب حجم افتراضي للكتلة.
    double current =
        active.fontSize ??
        (active.kind.isHeading
            ? (active.kind == JoodWriterBlockKind.heading1 ? 24.0 : 18.0)
            : 13.5);
    if (!sizes.contains(current)) {
      current = sizes.reduce(
        (a, b) => (current - a).abs() < (current - b).abs() ? a : b,
      );
    }

    return DropdownButtonHideUnderline(
      child: DropdownButton<double>(
        value: current,
        isDense: true,
        style: Theme.of(context).textTheme.bodyMedium,
        items: sizes
            .map((s) => DropdownMenuItem(value: s, child: Text(s.toString())))
            .toList(),
        onChanged: (s) {
          if (s != null) controller.setFontSize(s);
        },
      ),
    );
  }
}

class _ColorDropdown extends StatelessWidget {
  const _ColorDropdown({
    required this.tooltip,
    required this.icon,
    required this.selectedColor,
    required this.onColorSelected,
    required this.allowClear,
  });

  final String tooltip;
  final IconData icon;
  final Color selectedColor;
  final ValueChanged<Color?> onColorSelected;
  final bool allowClear;

  static const List<Color> _swatches = [
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<Color?>(
      tooltip: tooltip,
      icon: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 20, color: scheme.onSurface),
          Positioned(
            bottom: 0,
            child: Container(
              width: 14,
              height: 4,
              decoration: BoxDecoration(
                color: selectedColor == Colors.transparent
                    ? Colors.grey.shade300
                    : selectedColor,
                border: Border.all(color: scheme.outlineVariant, width: 0.5),
              ),
            ),
          ),
        ],
      ),
      onSelected: onColorSelected,
      itemBuilder: (context) {
        return [
          if (allowClear)
            const PopupMenuItem(
              value: null,
              child: Text('الافتراضي / بلا لون'),
            ),
          ..._swatches.map(
            (c) => PopupMenuItem(
              value: c,
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    color: c,
                    margin: const EdgeInsets.only(left: 8),
                  ),
                  Text(
                    '#${c.toARGB32().toRadixString(16).toUpperCase().substring(2)}',
                  ),
                ],
              ),
            ),
          ),
        ];
      },
    );
  }
}

class _ToolToggle extends StatelessWidget {
  const _ToolToggle({
    required this.tooltip,
    required this.icon,
    required this.active,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final bool active;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    final Color activeBg = scheme.primary.withValues(alpha: 0.12);
    final Color activeFg = scheme.primary;
    final Color normalFg = scheme.onSurfaceVariant;
    final Color disabledFg = scheme.onSurface.withValues(alpha: 0.38);

    Color fg = onPressed == null ? disabledFg : (active ? activeFg : normalFg);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: active ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 20, color: fg),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 24, color: color);
  }
}

/// قائمة استثناء الصفحات الأولى من الترقيم (غلاف أو مقدّمات).
class _PageNumberingExcludeMenu extends StatelessWidget {
  const _PageNumberingExcludeMenu({required this.controller});

  final WriterDocumentController controller;

  /// الخيارات المقدَّمة: 0 = بلا استثناء، ثم أول 1/2/3/5 صفحات.
  static const List<int> _choices = <int>[0, 1, 2, 3, 5];

  @override
  Widget build(BuildContext context) {
    final PageNumberingConfig numbering = controller.document.pageNumbering;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool enabled = numbering.enabled;

    return Tooltip(
      message: 'الصفحات المستثناة من الترقيم',
      child: PopupMenuButton<int>(
        enabled: enabled,
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.playlist_remove,
          size: 20,
          color: enabled
              ? scheme.onSurfaceVariant
              : scheme.onSurface.withValues(alpha: 0.38),
        ),
        onSelected: controller.setPageNumberingExcludeFirst,
        itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
          for (final int n in _choices)
            PopupMenuItem<int>(
              value: n,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    numbering.excludeFirstN == n
                        ? Icons.check
                        : Icons.check_box_outline_blank,
                    size: 14,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    n == 0
                        ? 'بلا استثناء'
                        : n == 1
                        ? 'استثناء الغلاف (أول صفحة)'
                        : 'استثناء أول $n صفحات',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LineSpacingSelector extends StatelessWidget {
  const _LineSpacingSelector({required this.active, required this.controller});
  final JoodWriterBlock active;
  final WriterDocumentController controller;

  @override
  Widget build(BuildContext context) {
    const spaces = [1.0, 1.15, 1.5, 2.0];
    double current = active.lineSpacing;
    if (!spaces.contains(current)) current = 1.5;

    return Tooltip(
      message: 'تباعد الأسطر',
      child: DropdownButtonHideUnderline(
        child: DropdownButton<double>(
          icon: const Icon(Icons.height, size: 18),
          value: current,
          isDense: true,
          style: Theme.of(context).textTheme.bodyMedium,
          items: spaces
              .map((s) => DropdownMenuItem(value: s, child: Text(s.toString())))
              .toList(),
          onChanged: (s) {
            if (s != null) {
              final block = controller.activeBlock;
              if (block != null) {
                controller.updateActiveBlock(block.copyWith(lineSpacing: s));
              }
            }
          },
        ),
      ),
    );
  }
}
