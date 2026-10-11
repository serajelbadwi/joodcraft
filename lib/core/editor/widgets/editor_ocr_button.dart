/// زر استخراج نص من صورة داخل محرّر القوالب (الشهادات/العقود).
///
/// ودجة مستقلّة عن `template_editor_view.dart` كي لا تتعارض مع أي تعديل
/// موازٍ في المحرّر: تُضاف بسطر واحد (ودّتها + استدعاؤها) وتعتمد على API
/// العام للمتحكّم فقط (`addElement` ثم `updateText`) — فلا تُمدّ يدها إلى
/// ملفات تبويبات أخرى.
library;

import 'package:flutter/material.dart';

import '../../../../core/editor/element_factory.dart';
import '../../../../core/editor/template_editor_controller.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../features/ocr/presentation/screens/ocr_screen.dart';

/// زر «استخراج نص» في شريط أدوات المحرّر.
class EditorOcrButton extends StatelessWidget {
  const EditorOcrButton({
    super.key,
    required this.controller,
    this.iconOnly = true,
  });

  /// متحكّم التحرير — تُقرأ حالته وتُستدعى واجهته العامة فقط.
  final TemplateEditorController controller;

  /// أيقونة فقط (للشريط) أو أيقونة + نصّ.
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = context.l10n;
    final String label = l10n?.ocrTitle ?? 'استخراج نص من صورة';

    if (iconOnly) {
      return IconButton(
        key: const Key('editor_ocr_button'),
        tooltip: label,
        icon: const Icon(Icons.document_scanner_outlined),
        onPressed: () => _open(context),
      );
    }
    return OutlinedButton.icon(
      key: const Key('editor_ocr_button'),
      icon: const Icon(Icons.document_scanner_outlined),
      label: Text(label),
      onPressed: () => _open(context),
    );
  }

  Future<void> _open(BuildContext context) async {
    await showOcrScreen(context, onInsert: _insertText);
  }

  /// يُنشئ عنصراً نصّياً جديداً ويملؤه بالنصّ المستخرَج.
  void _insertText(String text) {
    controller.addElement(NewElementKind.text);
    controller.updateText(text);
  }
}
