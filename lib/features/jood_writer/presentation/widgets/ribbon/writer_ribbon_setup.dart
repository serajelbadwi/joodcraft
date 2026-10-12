/// تبويب «التهيئة» في شريط Ribbon — إعداد الصفحة (مقاس/اتجاه/هوامش)،
/// خلفية الصفحة (لون/علامة مائية/إطار)، وترقيم الصفحات.
///
/// ملاحظات ربط صريح:
/// * الهوامش والمقاس والاتجاه والترقيم كلّها إعدادات المستند الحقيقية
///   عبر [WriterDocumentController]، فتظهر فوراً على اللوحة والمعاينة.
/// * «الأعمدة» غير مضمّنة هنا: تقتضي تعديل محرّك التدفّق [FlowPaginator]
///   نفسه (تقسيم كل صفحة إلى أعمدة) — خارج نطاق شريط Ribbon.
/// * «مصدر الورق» يُدار من حوار الطباعة لا من نموذج المستند.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/l10n/app_l10n.dart';
import '../../../domain/jood_writer_document.dart';
import '../../writer_document_controller.dart';
import 'writer_ribbon_common.dart';

class WriterRibbonSetupTab extends StatelessWidget {
  const WriterRibbonSetupTab({super.key, required this.controller});

  final WriterDocumentController controller;

  /// هوامش جاهزة (مليمتر): ضيق، متوسط (المعياري)، واسع.
  static const Map<String, JoodWriterMargins> marginPresets =
      <String, JoodWriterMargins>{
        'narrow': JoodWriterMargins(top: 12.7, right: 12.7, bottom: 12.7, left: 12.7),
        'normal': JoodWriterMargins.standard,
        'wide': JoodWriterMargins(top: 25.4, right: 25.4, bottom: 25.4, left: 25.4),
      };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, _) {
        final l10n = context.l10n;
        final JoodWriterDocument doc = controller.document;
        final PageNumberingConfig numbering = doc.pageNumbering;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // ------------------------- 1. إعداد الصفحة -------------------------
            RibbonSection(
              title: l10n?.jwSectionPageSetup ?? 'إعداد الصفحة',
              child: Row(
                children: <Widget>[
                  RibbonMenu<String>(
                    key: const ValueKey<String>('ribbon-page-size'),
                    tooltip: l10n?.jwPageSize ?? 'مقاس الصفحة',
                    icon: Icons.article_outlined,
                    buttonLabel: doc.pageSize.label,
                    items: <RibbonMenuItem<String>>[
                      for (final JoodWriterPageSize size
                          in JoodWriterPageSize.all)
                        RibbonMenuItem<String>(
                          value: size.label,
                          label: size.label,
                          checked: size.label == doc.pageSize.label,
                        ),
                    ],
                    onSelected: (String label) =>
                        controller.setPageSize(JoodWriterPageSize.fromLabel(label)),
                  ),
                  RibbonSeparator(),
                  RibbonMenu<WriterOrientation>(
                    key: const ValueKey<String>('ribbon-orientation'),
                    tooltip: l10n?.jwOrientation ?? 'اتجاه الصفحة',
                    icon: Icons.screen_rotation_alt,
                    items: <RibbonMenuItem<WriterOrientation>>[
                      RibbonMenuItem<WriterOrientation>(
                        value: WriterOrientation.portrait,
                        label: l10n?.jwPortrait ?? 'طولي',
                        checked:
                            doc.orientation == WriterOrientation.portrait,
                      ),
                      RibbonMenuItem<WriterOrientation>(
                        value: WriterOrientation.landscape,
                        label: l10n?.jwLandscape ?? 'عرضي',
                        checked:
                            doc.orientation == WriterOrientation.landscape,
                      ),
                    ],
                    onSelected: controller.setOrientation,
                  ),
                  RibbonSeparator(),
                  RibbonMenu<String>(
                    key: const ValueKey<String>('ribbon-margins'),
                    tooltip: l10n?.jwPageMargins ?? 'هوامش الصفحة',
                    icon: Icons.crop_portrait,
                    items: <RibbonMenuItem<String>>[
                      RibbonMenuItem<String>(
                        value: 'narrow',
                        label: l10n?.jwMarginsNarrow ?? 'ضيقة',
                      ),
                      RibbonMenuItem<String>(
                        value: 'normal',
                        label: l10n?.jwMarginsNormal ?? 'متوسطة',
                      ),
                      RibbonMenuItem<String>(
                        value: 'wide',
                        label: l10n?.jwMarginsWide ?? 'واسعة',
                      ),
                      RibbonMenuItem<String>(
                        value: 'custom',
                        label: l10n?.jwMarginsCustom ?? 'مخصصة…',
                      ),
                    ],
                    onSelected: (String choice) {
                      if (choice == 'custom') {
                        showWriterMarginsDialog(context, controller: controller);
                      } else {
                        controller.setMargins(marginPresets[choice]!);
                      }
                    },
                  ),
                  RibbonSeparator(),
                  // تبديل سريع بين طولي/عرضي بأيقونة واحدة.
                  RibbonToggle(
                    key: const ValueKey<String>('ribbon-landscape'),
                    tooltip: l10n?.jwLandscape ?? 'عرضي',
                    icon: Icons.stay_current_landscape,
                    active: doc.orientation == WriterOrientation.landscape,
                    onPressed: () => controller.setOrientation(
                      doc.orientation == WriterOrientation.landscape
                          ? WriterOrientation.portrait
                          : WriterOrientation.landscape,
                    ),
                  ),
                ],
              ),
            ),
            RibbonVerticalDivider(),

            // ------------------------- 2. خلفية الصفحة -------------------------
            RibbonSection(
              title: l10n?.jwSectionPageBackground ?? 'خلفية الصفحة',
              child: Row(
                children: <Widget>[
                  RibbonColorTool(
                    key: const ValueKey<String>('ribbon-page-color'),
                    tooltip: l10n?.jwPageColor ?? 'لون الصفحة',
                    icon: Icons.format_color_fill_outlined,
                    selected:
                        doc.pageColor != null ? Color(doc.pageColor!) : null,
                    allowClear: true,
                    clearLabel: l10n?.jwPageColorClear ?? 'أبيض (افتراضي)',
                    onSelected: controller.setPageColor,
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('ribbon-watermark'),
                    tooltip: l10n?.jwWatermark ?? 'علامة مائية',
                    icon: Icons.branding_watermark_outlined,
                    label: l10n?.jwWatermarkShort ?? 'علامة',
                    onPressed: () =>
                        showWriterWatermarkDialog(context, controller: controller),
                  ),
                  RibbonToggle(
                    key: const ValueKey<String>('ribbon-page-border'),
                    tooltip: l10n?.jwPageBorder ?? 'إطار الصفحة',
                    icon: Icons.border_all,
                    active: doc.pageBorder,
                    onPressed: () => controller.setPageBorder(!doc.pageBorder),
                  ),
                  // الأعمدة (1/2/3) تتطلّب تعديل محرّك التدفّق نفسه — لا
                  // تُعرض زرّاً ميتاً هنا؛ الميزة تُنفَّذ في محرك التخطيط.
                ],
              ),
            ),
            RibbonVerticalDivider(),

            // ----------------------- 3. ترقيم الصفحات -----------------------
            RibbonSection(
              title: l10n?.jwSectionPageNumbering ?? 'ترقيم الصفحات',
              trailing: RibbonToggle(
                key: const ValueKey<String>('ribbon-page-number-toggle'),
                tooltip: l10n?.jwPageNumberEnable ?? 'إظهار أرقام الصفحات',
                icon: Icons.tag,
                active: numbering.enabled,
                onPressed: () => controller
                    .setPageNumberingEnabled(!numbering.enabled),
              ),
              child: Row(
                children: <Widget>[
                  RibbonMenu<PageNumberAlign>(
                    key: const ValueKey<String>('ribbon-page-number-align'),
                    tooltip: l10n?.jwPageNumberAlignLabel ?? 'محاذاة الرقم',
                    icon: Icons.vertical_align_bottom,
                    buttonLabel: numbering.align.labelAr,
                    items: <RibbonMenuItem<PageNumberAlign>>[
                      for (final PageNumberAlign align in PageNumberAlign.values)
                        RibbonMenuItem<PageNumberAlign>(
                          value: align,
                          label: align.labelAr,
                          checked: align == numbering.align,
                        ),
                    ],
                    onSelected: (PageNumberAlign align) =>
                        controller.setPageNumbering(
                      numbering.copyWith(align: align),
                    ),
                  ),
                  RibbonSeparator(),
                  RibbonMenu<PageNumberPattern>(
                    key: const ValueKey<String>('ribbon-page-number-pattern'),
                    tooltip: l10n?.jwPageNumberFormat ?? 'صيغة الرقم',
                    icon: Icons.numbers,
                    buttonLabel: numbering.pattern.labelAr,
                    items: <RibbonMenuItem<PageNumberPattern>>[
                      for (final PageNumberPattern pattern
                          in PageNumberPattern.values)
                        RibbonMenuItem<PageNumberPattern>(
                          value: pattern,
                          label: pattern.labelAr,
                          checked: pattern == numbering.pattern,
                        ),
                    ],
                    onSelected: (PageNumberPattern pattern) =>
                        controller.setPageNumbering(
                      numbering.copyWith(pattern: pattern),
                    ),
                  ),
                  RibbonSeparator(),
                  RibbonMenu<int>(
                    key: const ValueKey<String>('ribbon-page-number-start'),
                    tooltip: l10n?.jwPageNumberStartAt ?? 'يبدأ من',
                    icon: Icons.exposure,
                    buttonLabel: '${numbering.startPage}',
                    items: <RibbonMenuItem<int>>[
                      for (final int n in const <int>[1, 3, 5, 10])
                        RibbonMenuItem<int>(
                          value: n,
                          label: '$n',
                          checked: numbering.startPage == n,
                        ),
                    ],
                    onSelected: (int n) => controller.setPageNumbering(
                      numbering.copyWith(startPage: n),
                    ),
                  ),
                  RibbonToggle(
                    key: const ValueKey<String>('ribbon-page-number-first'),
                    tooltip: l10n?.jwPageNumberDifferentFirst ??
                        'تجاهل الصفحة الأولى (غلاف)',
                    icon: Icons.first_page,
                    active: numbering.excludeFirstN > 0,
                    onPressed: () => controller.setPageNumberingExcludeFirst(
                      numbering.excludeFirstN > 0 ? 0 : 1,
                    ),
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('ribbon-page-number-remove'),
                    tooltip: l10n?.jwPageNumberRemove ?? 'إزالة أرقام الصفحات',
                    icon: Icons.tag_faces_outlined,
                    onPressed: numbering.enabled
                        ? () => controller.setPageNumbering(
                              const PageNumberingConfig(enabled: false),
                            )
                        : null,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// =============================================================================
//  حوار الهوامش المخصّصة
// =============================================================================

Future<void> showWriterMarginsDialog(
  BuildContext context, {
  required WriterDocumentController controller,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) =>
        WriterMarginsDialog(controller: controller),
  );
}

class WriterMarginsDialog extends StatefulWidget {
  const WriterMarginsDialog({super.key, required this.controller});

  final WriterDocumentController controller;

  @override
  State<WriterMarginsDialog> createState() => _WriterMarginsDialogState();
}

class _WriterMarginsDialogState extends State<WriterMarginsDialog> {
  late final TextEditingController _top;
  late final TextEditingController _bottom;
  late final TextEditingController _right;
  late final TextEditingController _left;

  @override
  void initState() {
    super.initState();
    final JoodWriterMargins m = widget.controller.document.margins;
    _top = TextEditingController(text: '${m.top}');
    _bottom = TextEditingController(text: '${m.bottom}');
    _right = TextEditingController(text: '${m.right}');
    _left = TextEditingController(text: '${m.left}');
  }

  @override
  void dispose() {
    _top.dispose();
    _bottom.dispose();
    _right.dispose();
    _left.dispose();
    super.dispose();
  }

  static double _parse(TextEditingController c, double fallback) =>
      double.tryParse(c.text.trim()) ?? fallback;

  void _apply() {
    widget.controller.setMargins(
      JoodWriterMargins(
        top: _parse(_top, 25).clamp(0.0, 100.0),
        bottom: _parse(_bottom, 25).clamp(0.0, 100.0),
        right: _parse(_right, 20).clamp(0.0, 100.0),
        left: _parse(_left, 20).clamp(0.0, 100.0),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n?.jwCustomMarginsTitle ?? 'هوامش مخصصة (مليمتر)'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: _MarginField(
                    key: const ValueKey<String>('margin-top'),
                    label: l10n?.jwMarginTop ?? 'أعلى',
                    controller: _top,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MarginField(
                    key: const ValueKey<String>('margin-bottom'),
                    label: l10n?.jwMarginBottom ?? 'أسفل',
                    controller: _bottom,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: _MarginField(
                    key: const ValueKey<String>('margin-right'),
                    label: l10n?.jwMarginRight ?? 'يمين',
                    controller: _right,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MarginField(
                    key: const ValueKey<String>('margin-left'),
                    label: l10n?.jwMarginLeft ?? 'يسار',
                    controller: _left,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('margins-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n?.jwCancel ?? 'إلغاء'),
        ),
        FilledButton(
          key: const ValueKey<String>('margins-ok'),
          onPressed: _apply,
          child: Text(l10n?.jwOk ?? 'موافق'),
        ),
      ],
    );
  }
}

class _MarginField extends StatelessWidget {
  const _MarginField({
    super.key,
    required this.label,
    required this.controller,
  });

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

// =============================================================================
//  حوار العلامة المائية
// =============================================================================

Future<void> showWriterWatermarkDialog(
  BuildContext context, {
  required WriterDocumentController controller,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) =>
        WriterWatermarkDialog(controller: controller),
  );
}

class WriterWatermarkDialog extends StatefulWidget {
  const WriterWatermarkDialog({super.key, required this.controller});

  final WriterDocumentController controller;

  @override
  State<WriterWatermarkDialog> createState() => _WriterWatermarkDialogState();
}

class _WriterWatermarkDialogState extends State<WriterWatermarkDialog> {
  late final TextEditingController _text;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(
      text: widget.controller.document.watermark ?? '',
    );
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _apply() {
    widget.controller.setWatermark(_text.text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n?.jwWatermarkTitle ?? 'العلامة المائية'),
      content: SizedBox(
        width: 420,
        child: TextField(
          key: const ValueKey<String>('watermark-text'),
          controller: _text,
          maxLength: 40,
          decoration: InputDecoration(
            labelText: l10n?.jwWatermarkHint ??
                'نصّ خلفي شفّاف (اتركه فارغاً للإزالة)',
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('watermark-clear'),
          onPressed: () {
            widget.controller.setWatermark(null);
            Navigator.of(context).pop();
          },
          child: Text(l10n?.jwWatermarkClear ?? 'إزالة'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n?.jwCancel ?? 'إلغاء'),
        ),
        FilledButton(
          key: const ValueKey<String>('watermark-ok'),
          onPressed: _apply,
          child: Text(l10n?.jwOk ?? 'موافق'),
        ),
      ],
    );
  }
}
