/// تبويب «الرئيسية» في شريط Ribbon — أقسام: الكتل (وصول سريع)، والخطوط،
/// والمحاذاة، والقوائم والمسافات، والفقرة (نافذة + عصا سحرية).
///
/// قسم الكتل أول قسم عمداً: أدوات الإضافة والحذف والفصل تبقى ظاهرة على
/// الشاشات المتوسطة دون تمرير أفقي.
///
/// كل أداة هنا تُنفَّذ فوراً على الكتلة النشطة عبر [WriterDocumentController]
/// (خطوط وألوان ومحاذاة وقوائم وإزاحات) أو عبر طبقات الشريط (العصا
/// السحرية ونافذة الفقرة).
library;

import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_l10n.dart';
import '../../../domain/jood_writer_block.dart';
import '../../writer_document_controller.dart';
import 'writer_format_painter.dart';
import 'writer_paragraph_dialog.dart';
import 'writer_ribbon_common.dart';
import 'writer_ribbon_insert.dart';

class WriterRibbonHomeTab extends StatelessWidget {
  const WriterRibbonHomeTab({
    super.key,
    required this.controller,
    required this.painter,
  });

  final WriterDocumentController controller;
  final WriterFormatPainter painter;

  /// تشكيلة الخطوط المتاحة في منتقي الخط.
  static const List<String> fonts = <String>[
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

  /// أحجام الخط المتاحة.
  static const List<double> sizes = <double>[
    10, 11, 12, 13.5, 14, 16, 18, 20, 24, 28, 32, 36, 48, 72,
  ];

  /// تباعد الأسطر السريع.
  static const List<double> lineSpacings = <double>[1.0, 1.15, 1.5, 2.0];

  /// تباعد الفقرات السريع (قبل و بعد بالبكسل).
  static const List<double> paragraphSpacings = <double>[0, 6, 12, 18];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[controller, painter]),
      builder: (BuildContext context, _) {
        final l10n = context.l10n;
        final JoodWriterBlock? active = controller.activeBlock;
        if (active == null) return const SizedBox.shrink();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // ------------------ 1. الكتل (وصول سريع) ------------------
            // مقصوداً أول قسم: أدوات التحرير الأساسية (إضافة/حذف/فصل)
            // تبقى في متناول اليد على كل عروض الشاشات دون تمرير أفقي.
            RibbonSection(
              title: l10n?.jwSectionBlocks ?? 'الكتل',
              child: Row(
                children: <Widget>[
                  RibbonToolButton(
                    key: const ValueKey<String>('ribbon-add-block'),
                    tooltip: l10n?.jwAddBlock ?? 'إضافة كتلة',
                    icon: Icons.add_box_outlined,
                    onPressed: controller.addBlockAfterActive,
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('ribbon-delete-block'),
                    tooltip: l10n?.jwDeleteBlock ?? 'حذف كتلة',
                    icon: Icons.delete_outline,
                    onPressed: controller.document.blocks.length > 1
                        ? controller.deleteActiveBlock
                        : null,
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('ribbon-page-break'),
                    tooltip: l10n?.jwPageBreak ?? 'فاصل صفحات (صفحة جديدة عند المؤشر)',
                    icon: Icons.insert_page_break,
                    onPressed: controller.insertPageBreakAtCaret,
                  ),
                  RibbonToggle(
                    key: const ValueKey<String>('ribbon-spread-view'),
                    tooltip: l10n?.jwSpreadView ?? 'عرض صفحتين متقابلتين (طي الكتاب)',
                    icon: Icons.menu_book,
                    active: controller.viewMode == WriterViewMode.spread,
                    onPressed: controller.toggleViewMode,
                  ),
                ],
              ),
            ),
            RibbonVerticalDivider(),

            // ------------------------- 2. الخطوط -------------------------
            RibbonSection(
              title: l10n?.jwSectionFonts ?? 'الخطوط',
              child: Row(
                children: <Widget>[
                  RibbonMenu<String>(
                    key: const ValueKey<String>('ribbon-font-family'),
                    tooltip: l10n?.jwFontFamily ?? 'عائلة الخط',
                    icon: Icons.font_download_outlined,
                    buttonLabel: active.fontFamily ?? 'Cairo',
                    items: <RibbonMenuItem<String>>[
                      for (final String f in fonts)
                        RibbonMenuItem<String>(
                          value: f,
                          label: f,
                          checked: (active.fontFamily ?? 'Cairo') == f,
                        ),
                    ],
                    onSelected: (String f) =>
                        controller.setFontFamily(f == 'Cairo' ? null : f),
                  ),
                  RibbonSeparator(),
                  RibbonToolButton(
                    key: const ValueKey<String>('ribbon-font-size-down'),
                    tooltip: l10n?.jwFontSizeDown ?? 'تصغير الخط',
                    icon: Icons.exposure_minus_1,
                    onPressed: () {
                      final double current = active.fontSize ?? 13.5;
                      final int i = sizes.indexWhere(
                        (double s) => s >= current,
                      );
                      final int next = (i <= 0 ? 0 : i - 1).clamp(0, sizes.length - 1);
                      controller.setFontSize(sizes[next]);
                    },
                  ),
                  RibbonMenu<double>(
                    key: const ValueKey<String>('ribbon-font-size'),
                    tooltip: l10n?.jwFontSizeLabel ?? 'حجم الخط',
                    icon: Icons.format_size,
                    buttonLabel: (active.fontSize ?? 13.5)
                        .toString()
                        .replaceFirst('.0', ''),
                    items: <RibbonMenuItem<double>>[
                      for (final double s in sizes)
                        RibbonMenuItem<double>(
                          value: s,
                          label: s.toString().replaceFirst('.0', ''),
                        ),
                    ],
                    onSelected: controller.setFontSize,
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('ribbon-font-size-up'),
                    tooltip: l10n?.jwFontSizeUp ?? 'تكبير الخط',
                    icon: Icons.exposure_plus_1,
                    onPressed: () {
                      final double current = active.fontSize ?? 13.5;
                      final int i = sizes.lastIndexWhere(
                        (double s) => s <= current,
                      );
                      final int next = (i < 0 ? 0 : i + 1).clamp(0, sizes.length - 1);
                      controller.setFontSize(sizes[next]);
                    },
                  ),
                  RibbonSeparator(),
                  RibbonToggle(
                    key: const ValueKey<String>('ribbon-bold'),
                    tooltip: l10n?.jwBold ?? 'غامق',
                    icon: Icons.format_bold,
                    active: active.isBold,
                    onPressed: controller.toggleBold,
                  ),
                  RibbonToggle(
                    key: const ValueKey<String>('ribbon-italic'),
                    tooltip: l10n?.jwItalic ?? 'مائل',
                    icon: Icons.format_italic,
                    active: active.isItalic,
                    onPressed: controller.toggleItalic,
                  ),
                  RibbonToggle(
                    key: const ValueKey<String>('ribbon-underline'),
                    tooltip: l10n?.jwUnderline ?? 'تسطير',
                    icon: Icons.format_underline,
                    active: active.isUnderline,
                    onPressed: controller.toggleUnderline,
                  ),
                  RibbonToggle(
                    key: const ValueKey<String>('ribbon-strikethrough'),
                    tooltip: l10n?.jwStrikethrough ?? 'شطب',
                    icon: Icons.strikethrough_s,
                    active: active.isStrikethrough,
                    onPressed: controller.toggleStrikethrough,
                  ),
                  RibbonSeparator(),
                  RibbonColorTool(
                    key: const ValueKey<String>('ribbon-text-color'),
                    tooltip: l10n?.jwTextColor ?? 'لون النص',
                    icon: Icons.format_color_text,
                    selected: active.fontColor,
                    allowClear: true,
                    clearLabel: l10n?.jwNoColor ?? 'بلا لون',
                    onSelected: controller.setFontColor,
                  ),
                  RibbonColorTool(
                    key: const ValueKey<String>('ribbon-highlight-color'),
                    tooltip: l10n?.jwHighlightColor ?? 'تمييز النص',
                    icon: Icons.format_color_fill,
                    selected: active.highlightColor,
                    allowClear: true,
                    clearLabel: l10n?.jwNoColor ?? 'بلا لون',
                    onSelected: controller.setHighlightColor,
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('ribbon-clear-format'),
                    tooltip: l10n?.jwClearFormatting ?? 'مسح التنسيق',
                    icon: Icons.format_clear,
                    onPressed: controller.clearFormatting,
                  ),
                ],
              ),
            ),
            RibbonVerticalDivider(),

            // ------------------------- 3. المحاذاة -------------------------
            RibbonSection(
              title: l10n?.jwSectionAlignment ?? 'المحاذاة',
              child: Row(
                children: <Widget>[
                  RibbonToggle(
                    key: const ValueKey<String>('ribbon-align-right'),
                    tooltip: l10n?.jwAlignRight ?? 'محاذاة لليمين',
                    icon: Icons.format_align_right,
                    active: active.align == JoodWriterAlign.start,
                    onPressed: () =>
                        controller.setBlockAlign(JoodWriterAlign.start),
                  ),
                  RibbonToggle(
                    key: const ValueKey<String>('ribbon-align-center'),
                    tooltip: l10n?.jwAlignCenter ?? 'توسيط',
                    icon: Icons.format_align_center,
                    active: active.align == JoodWriterAlign.center,
                    onPressed: () =>
                        controller.setBlockAlign(JoodWriterAlign.center),
                  ),
                  RibbonToggle(
                    key: const ValueKey<String>('ribbon-align-left'),
                    tooltip: l10n?.jwAlignLeft ?? 'محاذاة لليسار',
                    icon: Icons.format_align_left,
                    active: active.align == JoodWriterAlign.end,
                    onPressed: () =>
                        controller.setBlockAlign(JoodWriterAlign.end),
                  ),
                  RibbonToggle(
                    key: const ValueKey<String>('ribbon-align-justify'),
                    tooltip: l10n?.jwJustify ?? 'ضبط',
                    icon: Icons.format_align_justify,
                    active: active.align == JoodWriterAlign.justify,
                    onPressed: () =>
                        controller.setBlockAlign(JoodWriterAlign.justify),
                  ),
                  RibbonSeparator(),
                  RibbonMenu<double>(
                    key: const ValueKey<String>('ribbon-line-spacing'),
                    tooltip: l10n?.jwLineSpacing ?? 'تباعد الأسطر',
                    icon: Icons.height,
                    buttonLabel: active.lineSpacing
                        .toString()
                        .replaceFirst('.0', ''),
                    items: <RibbonMenuItem<double>>[
                      for (final double s in lineSpacings)
                        RibbonMenuItem<double>(
                          value: s,
                          label: s.toString().replaceFirst('.0', ''),
                          checked: active.lineSpacing == s,
                        ),
                    ],
                    onSelected: controller.setLineSpacing,
                  ),
                  RibbonMenu<double>(
                    key: const ValueKey<String>('ribbon-paragraph-spacing'),
                    tooltip: l10n?.jwParagraphSpacing ?? 'تباعد الفقرات',
                    icon: Icons.vertical_align_center,
                    items: <RibbonMenuItem<double>>[
                      for (final double s in paragraphSpacings)
                        RibbonMenuItem<double>(
                          value: s,
                          label: s == 0
                              ? (l10n?.jwSpacingNone ?? 'بلا تباعد')
                              : '${l10n?.jwSpacingValue ?? 'تباعد'} '
                                    '${s.toString().replaceFirst('.0', '')}',
                        ),
                    ],
                    onSelected: (double s) =>
                        controller.setParagraphSpacing(before: s, after: s),
                  ),
                  RibbonSeparator(),
                  // اتجاه الكتابة: يُدرج علامة اتجاه صريحة عند المؤشّر
                  // (RTL/LRM) فلا يتغيّر سلوك التطبيق كله بقرار كتلة واحدة.
                  RibbonToolButton(
                    key: const ValueKey<String>('ribbon-direction-rtl'),
                    tooltip: l10n?.jwDirectionRtl ?? 'اتجاه من اليمين (RTL)',
                    icon: Icons.format_textdirection_r_to_l,
                    onPressed: () => _insertDirectionMark(controller, '‏'),
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('ribbon-direction-ltr'),
                    tooltip: l10n?.jwDirectionLtr ?? 'اتجاه من اليسار (LTR)',
                    icon: Icons.format_textdirection_l_to_r,
                    onPressed: () => _insertDirectionMark(controller, '‎'),
                  ),
                ],
              ),
            ),
            RibbonVerticalDivider(),

            // ------------------- 4. القوائم والمسافات -------------------
            RibbonSection(
              title: l10n?.jwSectionLists ?? 'القوائم والمسافات',
              child: Row(
                children: <Widget>[
                  RibbonToggle(
                    key: const ValueKey<String>('ribbon-bullet-list'),
                    tooltip: l10n?.jwBulletList ?? 'قائمة نقطية',
                    icon: Icons.format_list_bulleted,
                    active: active.kind == JoodWriterBlockKind.bullet,
                    onPressed: () =>
                        controller.setBlockKind(JoodWriterBlockKind.bullet),
                  ),
                  RibbonToggle(
                    key: const ValueKey<String>('ribbon-numbered-list'),
                    tooltip: l10n?.jwNumberedList ?? 'قائمة رقمية',
                    icon: Icons.format_list_numbered,
                    active: active.kind == JoodWriterBlockKind.numbered,
                    onPressed: () =>
                        controller.setBlockKind(JoodWriterBlockKind.numbered),
                  ),
                  RibbonSeparator(),
                  RibbonToolButton(
                    key: const ValueKey<String>('ribbon-indent-increase'),
                    tooltip: l10n?.jwIndentIncrease ?? 'زيادة الإزاحة',
                    icon: Icons.format_indent_increase,
                    onPressed: () =>
                        controller.setIndentCm(active.indentCm + 0.5),
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('ribbon-indent-decrease'),
                    tooltip: l10n?.jwIndentDecrease ?? 'إنقاص الإزاحة',
                    icon: Icons.format_indent_decrease,
                    onPressed: () =>
                        controller.setIndentCm(active.indentCm - 0.5),
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('ribbon-first-line-increase'),
                    tooltip: l10n?.jwFirstLineIndentIncrease ??
                        'زيادة إزاحة السطر الأول',
                    icon: Icons.keyboard_tab,
                    onPressed: () => controller.setFirstLineIndent(
                      (active.firstLineIndentCm + 0.5).clamp(0.0, 10.0),
                    ),
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('ribbon-first-line-decrease'),
                    tooltip: l10n?.jwFirstLineIndentDecrease ??
                        'إنقاص إزاحة السطر الأول',
                    icon: Icons.keyboard_return,
                    onPressed: () => controller.setFirstLineIndent(
                      (active.firstLineIndentCm - 0.5).clamp(0.0, 10.0),
                    ),
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('ribbon-hanging-indent'),
                    tooltip: l10n?.jwHangingIndent ?? 'إزاحة معلّقة',
                    icon: Icons.subject,
                    onPressed: () {
                      controller.setIndentCm(active.indentCm + 0.5);
                      controller.setFirstLineIndent(0);
                    },
                  ),
                ],
              ),
            ),
            RibbonVerticalDivider(),

            // ------------------------- 5. الفقرة -------------------------
            RibbonSection(
              title: l10n?.jwSectionParagraph ?? 'الفقرة',
              child: Row(
                children: <Widget>[
                  RibbonToolButton(
                    key: const ValueKey<String>('ribbon-paragraph-dialog'),
                    tooltip: l10n?.jwParagraphDialog ?? 'نافذة الفقرة',
                    icon: Icons.tune,
                    label: l10n?.jwParagraphDialog ?? 'الفقرة',
                    onPressed: () =>
                        showWriterParagraphDialog(context, controller: controller),
                  ),
                  const SizedBox(width: 6),
                  // العصا السحرية: ضغطة = كتلة واحدة، ضغطتان = مستمر،
                  // ضغطة ثالثة = إنهاء (سلوك وورد).
                  RibbonToggle(
                    key: const ValueKey<String>('ribbon-format-painter'),
                    tooltip: painter.mode == WriterPainterMode.once
                        ? (l10n?.jwFormatPainterOnce ??
                              'نسخ التنسيق — كتلة واحدة')
                        : painter.mode == WriterPainterMode.locked
                        ? (l10n?.jwFormatPainterLocked ??
                              'نسخ التنسيق — مستمر (اضغط للإيقاف)')
                        : (l10n?.jwFormatPainter ?? 'نسخ التنسيق'),
                    icon: Icons.brush_outlined,
                    active: painter.isActive,
                    label: l10n?.jwFormatPainterShort ?? 'تنسيق',
                    onPressed: painter.press,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// إدراج علامة اتجاه (RTL/LRM) عند المؤشّر — تُحفظ مع النصّ وتحرّك
  /// موضع التفاف الأسطر دون تغيير اتجاه التطبيق كله.
  static void _insertDirectionMark(
    WriterDocumentController controller,
    String mark,
  ) => WriterRibbonInsert.atCaret(controller, mark);
}
