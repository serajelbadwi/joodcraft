/// تباعد الصفحات في «جود كاتب»: الفاصل بين الصفحات **‎15px‎ ثابتة على
/// الشاشة مهما كان التكبير** (المواصفة: 10-20 بكسل).
///
/// كان العطب: `Transform.scale` يُكبّر **الطلاء** وحده بينما فتحة التخطيط
/// `SizedBox(pageHeight * fit)` تبقى بمقاسها الأول — قياس فعلي قبل الإصلاح:
/// ‎−537px` تداخل عند ‎1.5×` و‎−1098px` عند ‎2×` و‎+361px` فراغ رمادي عند
/// ‎0.7×`. الإصلاح: الفتحة تُضرب في `zoomLevel` فيطابق الطلاء فتحته، فيبقى
/// الفاصل هو المُصرَّح به في كل تكبير — ويطابق ارتفاع الصفّ حساب التمرير
/// في `_scrollToBlockPage` حرفياً.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_block.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_document.dart';
import 'package:joodcraft/features/jood_writer/presentation/widgets/writer_canvas.dart';
import 'package:joodcraft/features/jood_writer/presentation/writer_document_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  WriterDocumentController makeController() {
    final WriterDocumentController controller = WriterDocumentController(
      initialDocument: JoodWriterDocument(
        title: 't',
        blocks: List<JoodWriterBlock>.generate(
          40,
          (int i) => JoodWriterBlock(
            text: List<String>.filled(
              4,
              'بلوك $i نصّ تجريبي طويل يمتد على أسطر كثيرة لضمان توليد عدة صفحات.',
            ).join(' '),
          ),
        ),
      ),
    );
    controller.setAutosaveEnabled(false);
    addTearDown(controller.dispose);
    return controller;
  }

  /// شاشة طويلة بما يكفي لبناء الصفحة الثانية حتى عند ‎2×‎
  /// (فتحتها تبدأ عندها عند ‎~2300px` من أعلى القائمة).
  Future<void> pumpCanvas(
    WidgetTester tester,
    WriterDocumentController controller,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: WriterCanvas(controller: controller)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  /// المسافة الرأسية المرسومة بين صفحتين متجاورتين (من أسفل الأولى إلى
  /// أعلى الثانية) — تشمل الطلاء لأن `getRect` يمرّ عبر `Transform`.
  double verticalGap(WidgetTester tester, String upper, String lower) {
    final Rect a = tester.getRect(find.byKey(ValueKey<String>(upper)));
    final Rect b = tester.getRect(find.byKey(ValueKey<String>(lower)));
    return b.top - a.bottom;
  }

  test('الفاصل المعلن داخل النطاق المطلوب (10-20) وقيمته ‎15.0‎', () {
    expect(WriterCanvas.pageGap, 15.0);
    expect(WriterCanvas.pageGap, inInclusiveRange(10, 20));
  });

  testWidgets('المسافة رأسياً ثابتة = pageGap عند كل تكبير (الوضع المفرد)', (
    WidgetTester tester,
  ) async {
    final WriterDocumentController controller = makeController();
    await pumpCanvas(tester, controller);

    for (final double zoom in <double>[1.0, 0.7, 1.5, 0.9, 2.0, 1.3]) {
      controller.setZoom(zoom);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        verticalGap(tester, 'writer-page-1', 'writer-page-2'),
        closeTo(WriterCanvas.pageGap, 0.5),
        reason: 'الفاصل خرج عن ‎15px‎ عند zoom=$zoom',
      );
    }
  });

  testWidgets('في طي الكتاب: الفاصل الرأسي بين الصفّات والفواصل الأفقية ثابتة', (
    WidgetTester tester,
  ) async {
    final WriterDocumentController controller = makeController();
    controller.setViewMode(WriterViewMode.spread);
    await pumpCanvas(tester, controller);

    for (final double zoom in <double>[1.0, 1.5]) {
      controller.setZoom(zoom);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // رأسيّاً: الصفحة الثالثة أول صفّ ثانٍ — يُبنى حتى ‎1.5×` في شاشة 2400.
      expect(
        verticalGap(tester, 'writer-page-1', 'writer-page-3'),
        closeTo(WriterCanvas.pageGap, 0.5),
        reason: 'فاصل الصفّات خرج عن ‎15px‎ عند zoom=$zoom',
      );
      // أفقيّاً: صفحتان متقابلتان بينهما SizedBox(pageGap).
      final Rect right = tester.getRect(
        find.byKey(const ValueKey<String>('writer-page-1')),
      );
      final Rect left = tester.getRect(
        find.byKey(const ValueKey<String>('writer-page-2')),
      );
      expect(
        right.left - left.right,
        closeTo(WriterCanvas.pageGap, 0.5),
        reason: 'الفاصل الأفقي بين الصفحتين المتقابلتين تغيّر عند zoom=$zoom',
      );
    }
  });
}
