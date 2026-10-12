import 'package:flutter/material.dart';

import '../../domain/jood_writer_block.dart';
import '../writer_document_controller.dart';
import 'ribbon/writer_ribbon_bar.dart';

/// الشريط العلوي لشاشة «جود كاتب» — غلاف رفيع فوق شريط **Ribbon المُطوَّر**
/// (خمسة تبويبات: الرئيسية/التهيئة/التصميم/الحفظ/المراجعة).
///
/// يحفظ عقود الشاشة والاختبارات القائمة:
/// * المفتاح `writer-ribbon` يظهر مرة واحدة فقط.
/// * لا يظهر إطلاقاً ما لم تكن هناك كتلة نشطة (سلوك الشريط القديم).
class WriterRibbonBar extends StatelessWidget {
  const WriterRibbonBar({super.key, required this.controller});

  final WriterDocumentController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, _) {
        final JoodWriterBlock? active = controller.activeBlock;
        if (active == null) return const SizedBox.shrink();

        return WriterTabbedRibbonBar(
          key: const ValueKey<String>('writer-ribbon'),
          controller: controller,
        );
      },
    );
  }
}
