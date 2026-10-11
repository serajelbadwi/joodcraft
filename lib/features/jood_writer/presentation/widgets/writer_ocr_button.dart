/// زر استخراج نص من صورة داخل Jood Writer — ودجت مستقلّة عن الشريط الجانبي.
///
/// **لماذا ملف مستقل؟** الشريط الجانبي (`writer_sidebar.dart`) ومالكه
/// (`writer_document_controller.dart`) مملوكان لتوابع متوازية، والتعليمات
/// تُلزم بعدم تعديلهما. فهذه الودجة تستدعي API العام الموجود أصلاً
/// (`activeBlock` / `updateActiveBlock` / `addBlockAfterActive`) وتُضاف
/// إلى أي مكان في واجهة Writer بسطر واحد بلا أي تعديل في الملفات المحظورة.
///
/// سلوك الإدراج: إن كان الكتلة النشطة فارغة تُملأ بها؛ وإلا أُضيفت كتلة
/// جديدة بعد النشطة ووُضعت فيها — فلا يضيع نصّ موجود أبداً.
library;

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_l10n.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../ocr/presentation/screens/ocr_screen.dart';
import '../../domain/jood_writer_block.dart';
import '../../presentation/writer_document_controller.dart';

/// زر «استخراج نص» في شريط Jood Writer.
class WriterOcrButton extends StatelessWidget {
  const WriterOcrButton({
    super.key,
    required this.controller,
    this.iconOnly = true,
  });

  /// متحكّم المستند الحالي — تُقرأ حالته فقط ولا تُعدَّل من هنا.
  final WriterDocumentController controller;

  /// أيقونة فقط (للشريط العلوي) أو أيقونة + نصّ.
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = context.l10n;
    final String label = l10n?.ocrTitle ?? 'استخراج نص من صورة';

    if (iconOnly) {
      return IconButton(
        key: const Key('writer_ocr_button'),
        tooltip: label,
        icon: const Icon(Icons.document_scanner_outlined),
        onPressed: () => _open(context),
      );
    }
    return OutlinedButton.icon(
      key: const Key('writer_ocr_button'),
      icon: const Icon(Icons.document_scanner_outlined),
      label: Text(label),
      onPressed: () => _open(context),
    );
  }

  Future<void> _open(BuildContext context) async {
    await showOcrScreen(context, onInsert: _insertText);
  }

  /// يدرَج النصّ في الكتلة النشطة (إن فارغة) أو كتلة جديدة بعدها.
  void _insertText(String text) {
    final JoodWriterBlock? block = controller.activeBlock;
    if (block == null) return;
    if (block.text.trim().isEmpty) {
      controller.updateActiveBlock(block.copyWith(text: text));
      return;
    }
    controller.addBlockAfterActive();
    final JoodWriterBlock? created = controller.activeBlock;
    if (created != null) {
      controller.updateActiveBlock(created.copyWith(text: text));
    }
  }
}
