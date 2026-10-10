import 'package:flutter/material.dart';

import '../writer_document_controller.dart';
import '../widgets/writer_ribbon_bar.dart';
import '../widgets/writer_sidebar.dart';
import '../widgets/writer_canvas.dart';

/// شاشة **«جود كاتب»** بحلتها الجديدة — محرر مستندات بمظهر احترافي:
///
/// * شريط أدوات (Ribbon Bar) علوي للتنسيق الغني
/// * لوحة جانبية (Sidebar) لإعدادات الصفحة والتكبير
/// * مساحة عمل (Canvas) لعرض الصفحات
class JoodWriterScreen extends StatefulWidget {
  const JoodWriterScreen({super.key});

  @override
  State<JoodWriterScreen> createState() => _JoodWriterScreenState();
}

class _JoodWriterScreenState extends State<JoodWriterScreen> {
  late final WriterDocumentController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WriterDocumentController();
    // استئناف آخر مستند كان مفتوحاً (يُبلِّغ فشل الاستئناع بلا أخطاء).
    _controller.restoreLastDocument();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => Text(_controller.document.title),
        ),
        actions: [
          IconButton(
            tooltip: 'حفظ المستند',
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('تم حفظ المستند')));
            },
            icon: const Icon(Icons.save_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // الشريط العلوي (Ribbon Bar)
          WriterRibbonBar(controller: _controller),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // مساحة العمل (Canvas)
                Expanded(child: WriterCanvas(controller: _controller)),

                // اللوحة الجانبية يمين أو يسار حسب لغة الواجهة، هنا نضعها غالباً على الجانب
                WriterSidebar(controller: _controller),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
