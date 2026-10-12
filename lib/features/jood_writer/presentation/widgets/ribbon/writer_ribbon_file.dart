/// تبويب «الحفظ» (File) في شريط Ribbon — الملف، والتصدير، والتراجع،
/// والإعدادات.
///
/// ربط حقيقي بالنظام القائم:
/// * فتح/حفظ/حفظ باسم/جديد/مستندات حديثة → `WriterDocumentController`
///   (التخزين الدائم نفسه المستعمل في اللوحة الجانبية).
/// * التصدير → [WriterExportService] (PDF/PNG/DOCX/HTML/طباعة).
/// * التراجع والإعادة → [WriterRibbonHistory] (لقطات JSON بلا تعديل
///   على الـController).
/// * الإعدادات: خصائص المستند، إعداد الصفحة (حوار الهوامش)، اللغة، والحفظ
///   التلقائي (`setAutosaveEnabled`).
library;

import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_l10n.dart';
import '../../../domain/jood_writer_block.dart';
import '../../writer_document_controller.dart';
import 'writer_export_service.dart';
import 'writer_ribbon_common.dart';
import 'writer_ribbon_design.dart' show showWriterTemplatesDialog;
import 'writer_ribbon_history.dart';
import 'writer_ribbon_insert.dart';
import 'writer_ribbon_setup.dart' show showWriterMarginsDialog;

class WriterRibbonFileTab extends StatelessWidget {
  const WriterRibbonFileTab({
    super.key,
    required this.controller,
    required this.history,
  });

  final WriterDocumentController controller;
  final WriterRibbonHistory history;

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _guarded(
    BuildContext context,
    Future<void> Function(BuildContext context) action,
  ) async {
    try {
      await action(context);
    } catch (_) {
      if (context.mounted) {
        final l10n = context.l10n;
        _snack(context, l10n?.jwActionFailed ?? 'تعذّر إتمام العملية');
      }
    }
  }

  // ------------------------------ الملف ------------------------------

  Future<void> _newDocument(BuildContext context) async {
    final l10n = context.l10n;
    if (controller.isDirty) {
      final bool? ok = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: Text(l10n?.jwNewDocConfirm ?? 'مستند جديد'),
          content: Text(
            l10n?.jwNewDocConfirmMessage ??
                'لديك تغييرات غير محفوظة. هل تريد البدء بمستند جديد؟',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n?.jwCancel ?? 'إلغاء'),
            ),
            FilledButton(
              key: const ValueKey<String>('file-new-confirm'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n?.jwOk ?? 'موافق'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    controller.createNewDocument();
    if (context.mounted) {
      _snack(context, l10n?.jwNewDocument ?? 'مستند جديد');
    }
  }

  Future<void> _openDocument(BuildContext context) async {
    final l10n = context.l10n;
    final List<WriterDocumentSummary> items =
        await controller.listSavedDocuments();
    if (!context.mounted) return;
    if (items.isEmpty) {
      _snack(context, l10n?.jwRecentFilesEmpty ?? 'لا مستندات محفوظة بعد');
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n?.jwRecentFiles ?? 'المستندات الأخيرة'),
        content: SizedBox(
          width: 440,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (BuildContext context, int i) {
                final WriterDocumentSummary item = items[i];
                return ListTile(
                  key: ValueKey<String>('file-recent-${item.id}'),
                  dense: true,
                  leading: const Icon(Icons.description_outlined),
                  title: Text(item.title),
                  subtitle: Text(item.updatedAt.toString().split('.').first),
                  onTap: () async {
                    final bool loaded =
                        await controller.loadSavedDocument(item.id);
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                    if (context.mounted && loaded) {
                      _snack(
                        context,
                        '${l10n?.jwOpenDocument ?? 'فُتح'}: ${item.title}',
                      );
                    }
                  },
                );
              },
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n?.jwCancel ?? 'إلغاء'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAs(BuildContext context) async {
    final l10n = context.l10n;
    final TextEditingController title = TextEditingController(
      text: controller.document.title,
    );
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n?.jwSaveAs ?? 'حفظ باسم'),
        content: TextField(
          key: const ValueKey<String>('save-as-title'),
          controller: title,
          decoration: InputDecoration(
            labelText: l10n?.jwDocumentTitle ?? 'عنوان المستند',
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (String v) => Navigator.of(dialogContext).pop(v),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n?.jwCancel ?? 'إلغاء'),
          ),
          FilledButton(
            key: const ValueKey<String>('save-as-ok'),
            onPressed: () => Navigator.of(dialogContext).pop(title.text),
            child: Text(l10n?.jwOk ?? 'موافق'),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    controller.renameDocument(name.trim());
    await controller.saveDocument();
    if (context.mounted) {
      _snack(context, '${l10n?.jwSaved ?? 'حُفظ'}: ${name.trim()}');
    }
  }

  // ------------------------------ التصدير ------------------------------

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[controller, history]),
      builder: (BuildContext context, _) {
        final l10n = context.l10n;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // ------------------------- 1. الملف -------------------------
            RibbonSection(
              title: l10n?.jwSectionFile ?? 'الملف',
              child: Row(
                children: <Widget>[
                  RibbonToolButton(
                    key: const ValueKey<String>('file-new'),
                    tooltip: l10n?.jwNewDocument ?? 'مستند جديد',
                    icon: Icons.note_add_outlined,
                    label: l10n?.jwNewShort ?? 'جديد',
                    onPressed: () => _newDocument(context),
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('file-open'),
                    tooltip: l10n?.jwOpenDocument ?? 'فتح مستند',
                    icon: Icons.folder_open,
                    label: l10n?.jwOpenShort ?? 'فتح',
                    onPressed: () => _guarded(context, (BuildContext c) => _openDocument(c)),
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('file-save'),
                    tooltip: l10n?.jwSave ?? 'حفظ (Ctrl+S)',
                    icon: Icons.save_outlined,
                    label: l10n?.jwSaveShort ?? 'حفظ',
                    onPressed: () => _guarded(context, (BuildContext c) async {
                      await controller.saveDocument();
                      if (c.mounted) {
                        _snack(c, l10n?.jwSaved ?? 'حُفظ المستند');
                      }
                    }),
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('file-save-as'),
                    tooltip: l10n?.jwSaveAs ?? 'حفظ باسم (Ctrl+Shift+S)',
                    icon: Icons.save_as_outlined,
                    onPressed: () => _guarded(context, (BuildContext c) => _saveAs(c)),
                  ),
                  RibbonSeparator(),
                  RibbonToolButton(
                    key: const ValueKey<String>('file-recent'),
                    tooltip: l10n?.jwRecentFiles ?? 'المستندات الأخيرة',
                    icon: Icons.history,
                    onPressed: () => _guarded(context, (BuildContext c) => _openDocument(c)),
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('file-templates'),
                    tooltip: l10n?.jwTemplates ?? 'القوالب',
                    icon: Icons.dashboard_customize_outlined,
                    onPressed: () => showWriterTemplatesDialog(
                      context,
                      controller: controller,
                      onApplied: (t) => controller.loadDocument(t.build()),
                    ),
                  ),
                ],
              ),
            ),
            RibbonVerticalDivider(),

            // ------------------------- 2. التصدير -------------------------
            RibbonSection(
              title: l10n?.jwSectionExport ?? 'التصدير',
              child: Row(
                children: <Widget>[
                  RibbonToolButton(
                    key: const ValueKey<String>('file-export-pdf'),
                    tooltip: l10n?.jwExportPdf ?? 'تصدير PDF',
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'PDF',
                    onPressed: () => _guarded(context, (BuildContext c) async {
                      await WriterExportService.exportPdf(
                        c,
                        controller.document,
                      );
                    }),
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('file-export-png'),
                    tooltip: l10n?.jwExportPng ?? 'تصدير PNG',
                    icon: Icons.image_outlined,
                    label: 'PNG',
                    onPressed: () => _guarded(context, (BuildContext c) async {
                      await WriterExportService.exportPng(
                        c,
                        controller.document,
                      );
                    }),
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('file-export-docx'),
                    tooltip: l10n?.jwExportDocx ?? 'تصدير DOCX',
                    icon: Icons.article_outlined,
                    label: 'DOCX',
                    onPressed: () => _guarded(context, (BuildContext c) async {
                      await WriterExportService.exportDocx(
                        c,
                        controller.document,
                      );
                    }),
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('file-export-html'),
                    tooltip: l10n?.jwExportHtml ?? 'تصدير HTML',
                    icon: Icons.html_outlined,
                    label: 'HTML',
                    onPressed: () => _guarded(context, (BuildContext c) async {
                      await WriterExportService.exportHtml(
                        c,
                        controller.document,
                      );
                    }),
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('file-print'),
                    tooltip: l10n?.jwPrint ?? 'طباعة (Ctrl+P)',
                    icon: Icons.print_outlined,
                    label: l10n?.jwPrintShort ?? 'طباعة',
                    onPressed: () => _guarded(context, (BuildContext c) async {
                      await WriterExportService.printDocument(
                        controller.document,
                      );
                    }),
                  ),
                ],
              ),
            ),
            RibbonVerticalDivider(),

            // ------------------------- 3. التراجع -------------------------
            RibbonSection(
              title: l10n?.jwSectionUndo ?? 'التراجع',
              child: Row(
                children: <Widget>[
                  RibbonToolButton(
                    key: const ValueKey<String>('file-undo'),
                    tooltip: l10n?.jwUndo ?? 'تراجع (Ctrl+Z)',
                    icon: Icons.undo,
                    onPressed: history.canUndo ? history.undo : null,
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('file-redo'),
                    tooltip: l10n?.jwRedo ?? 'إعادة (Ctrl+Y)',
                    icon: Icons.redo,
                    onPressed: history.canRedo ? history.redo : null,
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('file-history'),
                    tooltip: l10n?.jwUndoHistory ?? 'سجل التراجع',
                    icon: Icons.history_toggle_off,
                    label: l10n?.jwHistoryShort ?? 'السجل',
                    onPressed: () => showWriterHistoryDialog(
                      context,
                      history: history,
                    ),
                  ),
                ],
              ),
            ),
            RibbonVerticalDivider(),

            // ------------------------- 4. الإعدادات -------------------------
            RibbonSection(
              title: l10n?.jwSectionSettings ?? 'الإعدادات',
              child: Row(
                children: <Widget>[
                  RibbonToolButton(
                    key: const ValueKey<String>('file-properties'),
                    tooltip: l10n?.jwDocumentProperties ?? 'خصائص المستند',
                    icon: Icons.info_outline,
                    onPressed: () => _showProperties(context),
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('file-page-setup'),
                    tooltip: l10n?.jwPageSetup ?? 'إعداد الصفحة',
                    icon: Icons.settings_outlined,
                    onPressed: () =>
                        showWriterMarginsDialog(context, controller: controller),
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('file-language'),
                    tooltip: l10n?.jwLanguage ?? 'اللغة',
                    icon: Icons.translate,
                    onPressed: () => _showLanguage(context),
                  ),
                  RibbonToggle(
                    key: const ValueKey<String>('file-autosave'),
                    tooltip: l10n?.jwAutoSave ?? 'الحفظ التلقائي',
                    icon: Icons.sync,
                    active: controller.autosaveEnabled,
                    label: l10n?.jwAutoSaveShort ?? 'تلقائي',
                    onPressed: () => controller
                        .setAutosaveEnabled(!controller.autosaveEnabled),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showProperties(BuildContext context) {
    final l10n = context.l10n;
    final WriterDocumentStats stats = WriterDocumentStats.of(
      controller.document.blocks.map((JoodWriterBlock b) => b.text).toList(),
    );
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        final TextEditingController title = TextEditingController(
          text: controller.document.title,
        );
        return AlertDialog(
          title: Text(l10n?.jwDocumentProperties ?? 'خصائص المستند'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextField(
                  key: const ValueKey<String>('properties-title'),
                  controller: title,
                  decoration: InputDecoration(
                    labelText: l10n?.jwDocumentTitle ?? 'عنوان المستند',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${l10n?.jwWordCount ?? 'كلمة'}: ${stats.words}  •  '
                  '${l10n?.jwCharacterCount ?? 'حرف'}: ${stats.characters}  •  '
                  '${l10n?.jwParagraphsCount ?? 'فقرة'}: ${stats.paragraphs}',
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  '${l10n?.jwPageSize ?? 'مقاس الصفحة'}: '
                  '${controller.document.pageSize.label} — '
                  '${controller.document.orientation.labelAr}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n?.jwCancel ?? 'إلغاء'),
            ),
            FilledButton(
              key: const ValueKey<String>('properties-save'),
              onPressed: () {
                if (title.text.trim().isNotEmpty) {
                  controller.renameDocument(title.text.trim());
                }
                Navigator.of(dialogContext).pop();
              },
              child: Text(l10n?.jwOk ?? 'موافق'),
            ),
          ],
        );
      },
    );
  }

  void _showLanguage(BuildContext context) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n?.jwLanguage ?? 'اللغة'),
        content: Text(
          l10n?.jwLanguageArabic ??
              'لغة المحرّر: العربية — واجهة الشريط تدعم عشر لغات حسب إعدادات التطبيق.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n?.jwClose ?? 'إغلاق'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
//  نافذة سجل التراجع/الإعادة
// =============================================================================

Future<void> showWriterHistoryDialog(
  BuildContext context, {
  required WriterRibbonHistory history,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) =>
        WriterHistoryDialog(history: history),
  );
}

class WriterHistoryDialog extends StatelessWidget {
  const WriterHistoryDialog({super.key, required this.history});

  final WriterRibbonHistory history;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final List<String> snapshots = history.snapshots;
    final int cursor = history.cursor;

    return AlertDialog(
      title: Text(l10n?.jwUndoHistory ?? 'سجل التراجع'),
      content: SizedBox(
        width: 440,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 340),
          child: ListenableBuilder(
            listenable: history,
            builder: (BuildContext context, _) => ListView.builder(
              shrinkWrap: true,
              itemCount: snapshots.length,
              itemBuilder: (BuildContext context, int i) {
                final int step = i + 1;
                final bool isCurrent = i == cursor;
                return ListTile(
                  key: ValueKey<String>('history-step-$i'),
                  dense: true,
                  selected: isCurrent,
                  leading: Icon(
                    isCurrent ? Icons.radio_button_checked : Icons.history,
                    size: 18,
                  ),
                  title: Text(
                    '${l10n?.jwHistoryStep ?? 'خطوة'} $step'
                    '${isCurrent ? ' — ${l10n?.jwHistoryCurrent ?? 'الحالية'}' : ''}',
                  ),
                  trailing: const Text('↩', style: TextStyle(fontSize: 16)),
                  onTap: isCurrent
                      ? null
                      : () {
                          history.jumpTo(i);
                        },
                );
              },
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('history-close'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n?.jwClose ?? 'إغلاق'),
        ),
      ],
    );
  }
}
