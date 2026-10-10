import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/jood_writer/domain/flow_paginator.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_block.dart';
import 'package:joodcraft/features/jood_writer/presentation/widgets/writer_canvas.dart';
import 'package:joodcraft/features/jood_writer/presentation/writer_document_controller.dart';

/// اختبارات سلوك صفحات «جود كاتب»:
///
/// 1. **ثبات الصفحات عند التنقّل**: الشطر الآلي لا يعمل إلا عند تغيّر النصّ
///    (`textRevision`)، فلا يُعاد ترقيم الصفحات عند النقر أو التكبير فيبدو
///    المحتوى «مختفياً».
/// 2. **لصق كبير من Word**: فواصل الأسطر الصريحة ('\n') لا تُمحى عند الشطر،
///    فيبقى عدد الصفحات مطابقاً لعدد الفقرات ولا ينهار المستند صفحةً واحدة.
/// 3. **توزيع الأسطر**: نصّ طويل فعلاً يولّد صفحات متعددة حقيقية.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const Key field0 = ValueKey<String>('writer-field-0');

  Future<void> setSurface(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }


  Future<void> pumpCanvas(
    WidgetTester tester,
    WriterDocumentController controller,
  ) async {
    await setSurface(tester, const Size(1400, 950));
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: WriterCanvas(controller: controller))),
    );
    await tester.pump();
  }

  /// يلصق نصّاً طويلاً في الحقل النشط (يحاكي لصق Word في كتلة واحدة).

  // -------------------------------------------------------------------------
  //  1) ثبات الصفحات عند التنقّل
  // -------------------------------------------------------------------------
  group('ثبات الصفحات عند التنقّل', () {
    test('textRevision لا يزيد عند التنقّل أو التكبير أو تبديل العرض', () {
      final WriterDocumentController controller = WriterDocumentController();
      addTearDown(controller.dispose);

      expect(controller.textRevision, 0);

      // تغييرات عرض لا تُنتج شطراً آلياً.
      controller.setActiveBlock(0);
      controller.zoomIn();
      controller.zoomOut();
      expect(controller.textRevision, 0, reason: 'العرض وحده لا يغيّر النصّ');
    });

    test('textRevision يزيد عند تغيّر النصّ (كتابة/لصق)', () {
      final WriterDocumentController controller = WriterDocumentController();
      addTearDown(controller.dispose);

      controller.controllers.first.text = 'سطر جديد';
      expect(controller.textRevision, greaterThan(0));
    });
  });

  // -------------------------------------------------------------------------
  //  2) لصق كبير من Word — حفظ فواصل الأسطر
  // -------------------------------------------------------------------------
  group('لصق نصّ متعدّد الفقرات (Word)', () {
    test('الشطر يحفظ كل \\n فلا ينهار المستند صفحةً واحدة', () {
      // 40 فقرة، كلٌّ في سطر صريح — وهي صيغة لصق Word المعتادة.
      final List<String> paragraphs = List<String>.generate(
        40,
        (int i) => 'الفقرة رقم $i نصّ عربي كافٍ ليملأ جزءاً من السطر.',
      );
      final String pasted = paragraphs.join('\n');

      final WriterDocumentController controller = WriterDocumentController();
      addTearDown(controller.dispose);
      controller.controllers.first.text = pasted;

      final String text = controller.document.blocks.first.text;

      // لا يُفقد أيّ سطر صريح: عددها ثابت بعد إدخال النصّ.
      expect(text.split('\n').length, paragraphs.length);
      expect(text, pasted);
    });

    testWidgets('لصق نصّ طويل يولّد أكثر من صفحة (لا صفحة واحدة)', (
      WidgetTester tester,
    ) async {
      // لصق Word يصل كتلة واحدة بفواصل أسطر صريحة. العدد مضاعفٌ عن سعة
      // صفحة A4 حتى يضمن الاختبار فيضاً حقيقياً (40 فقرة قصيرة تتّسع في
      // صفحة واحدة بطبيعة الحال).
      final String pasted = List<String>.generate(
        120,
        (int i) => 'الفقرة رقم $i نصّ عربي كافٍ ليملأ جزءاً من السطر.',
      ).join('\n');

      final WriterDocumentController controller = WriterDocumentController();
      addTearDown(controller.dispose);
      // حفظ تلقائي مُعطَّل: مؤقّته يبقى معلّقاً بعد التخلّص فيفشل الاختبار.
      controller.setAutosaveEnabled(false);
      await pumpCanvas(tester, controller);

      await tester.enterText(find.byKey(field0), pasted);
      await tester.pumpAndSettle();

      // الشطر الآلي يحوّلها إلى كتل متعدّدة ⇒ أكثر من صفحة.
      expect(
        controller.document.blocks.length,
        greaterThan(1),
        reason: 'لصق 120 فقرة يجب أن يولّد صفحات متعدّدة لا صفحة واحدة',
      );

      // ولا تُفقد أيّ فقرة. حدود الكتل تضيف فواصلاً إضافية، فالمقارنة
      // بالمجموعة لا بالعدد.
      final Set<String> expected = pasted.split('\n').toSet();
      final Set<String> actual = controller.document.blocks
          .expand((JoodWriterBlock b) => b.text.split('\n'))
          .toSet();
      expect(
        actual.containsAll(expected),
        isTrue,
        reason: 'لا فقرة مفقودة بعد التقسيم',
      );
    });
  });

  // -------------------------------------------------------------------------
  //  3) توزيع الأسطر فعلياً
  // -------------------------------------------------------------------------
  group('توزيع الأسطر على صفحات', () {
    test('مقاس تعجيزي يقسم الأسطر على أكثر من صفحة', () {
      const String source = 'a\nb\nc\nd\ne\nf\ng\nh';
      final _FakeMeasurer measurer = _FakeMeasurer();
      final List<JoodPage> pages = FlowPaginator.paginate(
        blocks: const <JoodWriterBlock>[JoodWriterBlock(text: source)],
        // يتّسع لسطرين فقط في كل صفحة.
        contentHeight: 2 * 20,
        measurer: measurer,
      );

      expect(pages.length, greaterThan(1));
      // لا سطر مفقود بين الصفحات: مجموع المقاطع = نصّ المصدر بفواصره.
      final List<String> rendered = <String>[];
      for (final JoodPage page in pages) {
        for (final JoodPageSlice slice in page.slices) {
          rendered.addAll(
            measurer.linesOf(slice.block).sublist(slice.lineStart, slice.lineEnd),
          );
        }
      }
      expect(rendered.join('\n'), source);
    });
  });
}

/// مقاس ثابت حتمي: سطر واحد لكل '\n'، وارتفاع سطر 20.
class _FakeMeasurer implements BlockMeasurer {
  @override
  List<String> linesOf(JoodWriterBlock block) => block.text.split('\n');

  @override
  double lineHeightOf(JoodWriterBlock block) => 20;

  @override
  double spacingBeforeOf(JoodWriterBlock block) => 0;

  @override
  double spacingAfterOf(JoodWriterBlock block) => 0;
}
