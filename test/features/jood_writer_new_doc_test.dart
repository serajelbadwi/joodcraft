import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_block.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_document.dart';
import 'package:joodcraft/features/jood_writer/presentation/widgets/writer_canvas.dart';
import 'package:joodcraft/features/jood_writer/presentation/writer_document_controller.dart';

/// اختبارات «لا padding سالب» في لوحة «جود كاتب».
///
/// الحادثة: مستند جديد يُبنى بـErrorWidget بأكمله بشهادة
/// `padding.isNonNegative` من `RenderPadding` (`shifted_box.dart`) — أي أن
/// أحجيةً من الحسابات تمرّر قيمة سالبة إلى `EdgeInsets`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<WriterDocumentController> pumpWriter(
    WidgetTester tester,
    JoodWriterDocument document,
  ) async {
    final WriterDocumentController controller = WriterDocumentController(
      initialDocument: document,
    );
    controller.setAutosaveEnabled(false);
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: WriterCanvas(controller: controller))),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('مستند جديد: لا ErrorWidget ولا padding سالب', (
    WidgetTester tester,
  ) async {
    await pumpWriter(
      tester,
      const JoodWriterDocument(
        title: 'جديد',
        blocks: <JoodWriterBlock>[JoodWriterBlock(text: '')],
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ErrorWidget), findsNothing);
  });

  testWidgets('مستند بلا كتل: لا ArgumentError ولا padding سالب', (
    WidgetTester tester,
  ) async {
    await pumpWriter(
      tester,
      const JoodWriterDocument(title: 'بلا كتل', blocks: <JoodWriterBlock>[]),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ErrorWidget), findsNothing);
  });

  testWidgets('ورقة ضوئية فارغة: لا padding سالب', (
    WidgetTester tester,
  ) async {
    await pumpWriter(
      tester,
      const JoodWriterDocument(
        title: 'فارغة',
        blocks: <JoodWriterBlock>[JoodWriterBlock(text: 'سطر واحد')],
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ErrorWidget), findsNothing);
  });

  testWidgets('صفحة أصغر من هوامشها: لا padding سالب', (
    WidgetTester tester,
  ) async {
    await pumpWriter(
      tester,
      const JoodWriterDocument(
        title: 'ضيقة',
        pageSize: JoodWriterPageSize(
          widthMm: 60,
          heightMm: 60,
          label: 'صغيرة',
        ),
        margins: JoodWriterMargins(top: 40, right: 40, bottom: 40, left: 40),
        blocks: <JoodWriterBlock>[JoodWriterBlock(text: 'نصّ تجريبي بسيط')],
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ErrorWidget), findsNothing);
  });

  testWidgets('إزاحة سطر أول سالبة: لا padding سالب', (
    WidgetTester tester,
  ) async {
    await pumpWriter(
      tester,
      const JoodWriterDocument(
        title: 'إزاحة سالبة',
        blocks: <JoodWriterBlock>[
          JoodWriterBlock(text: 'فقرة بإزاحة سالبة', firstLineIndentCm: -2),
        ],
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ErrorWidget), findsNothing);
  });

  testWidgets('مسافة قبل كتلة سالبة: لا padding سالب', (
    WidgetTester tester,
  ) async {
    await pumpWriter(
      tester,
      const JoodWriterDocument(
        title: 'مسافة سالبة',
        blocks: <JoodWriterBlock>[
          JoodWriterBlock(text: 'فقرة أولى'),
          JoodWriterBlock(text: 'فقرة بمسافة سالبة', spaceBefore: -12),
        ],
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ErrorWidget), findsNothing);
  });
}
