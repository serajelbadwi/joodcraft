/// تبويب «الحفظ»: الملف (جديد/حفظ/خصائص)، التصدير (PDF/DOCX/HTML)،
/// التراجع والإعادة عبر لقطات الشريط، والإعدادات (حفظ تلقائي/صفحة/قالب).
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/jood_writer/presentation/widgets/ribbon/writer_export_service.dart';
import 'package:joodcraft/features/jood_writer/presentation/widgets/ribbon/writer_ribbon_common.dart';
import 'package:joodcraft/features/jood_writer/presentation/writer_document_controller.dart';

import 'ribbon_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('أقسام التبويب الأربعة', (WidgetTester tester) async {
    await pumpRibbon(tester, tab: 3);
    expect(ribbonSection('الملف'), findsOneWidget);
    expect(ribbonSection('التصدير'), findsOneWidget);
    expect(ribbonSection('التراجع'), findsOneWidget);
    expect(ribbonSection('الإعدادات'), findsOneWidget);
  });

  testWidgets('مفتاح الحفظ التلقائي يعاكس', (WidgetTester tester) async {
    final WriterDocumentController controller = await pumpRibbon(tester, tab: 3);
    expect(controller.autosaveEnabled, isTrue);

    await tester.tap(find.byKey(const ValueKey<String>('file-autosave')));
    await tester.pump();
    expect(controller.autosaveEnabled, isFalse);

    await tester.tap(find.byKey(const ValueKey<String>('file-autosave')));
    await tester.pump();
    expect(controller.autosaveEnabled, isTrue);
  });

  testWidgets('التراجع والإعادة عبر لقطات الشريط', (
    WidgetTester tester,
  ) async {
    final WriterDocumentController controller = await pumpRibbon(tester);
    expect(controller.document.blocks[0].isBold, isFalse);

    // تعديل ثم إتاحة الشريط لتسجيل اللقطة (رصف 700ms + حفظ تلقائي 800ms).
    controller.toggleBold();
    await selectRibbonTab(tester, 3);
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    // التراجع مفعّل والإعادة لا تزال معطّلة.
    expect(
      tester
          .widget<RibbonToolButton>(
            find.byKey(const ValueKey<String>('file-undo')),
          )
          .onPressed,
      isNotNull,
    );
    expect(
      tester
          .widget<RibbonToolButton>(
            find.byKey(const ValueKey<String>('file-redo')),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey<String>('file-undo')));
    await tester.pumpAndSettle();
    expect(controller.document.blocks[0].isBold, isFalse); // عاد كما قبل.

    await tester.tap(find.byKey(const ValueKey<String>('file-redo')));
    await tester.pumpAndSettle();
    expect(controller.document.blocks[0].isBold, isTrue);
  });

  testWidgets('مستند جديد بتأكيد فوق تغييرات غير محفوظة', (
    WidgetTester tester,
  ) async {
    final WriterDocumentController controller = await pumpRibbon(tester, tab: 3);
    controller.toggleBold(); // يجعل المستند قذِراً.
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey<String>('file-new')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('file-new-confirm')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('file-new-confirm')));
    await tester.pumpAndSettle();
    expect(controller.document.blocks.length, 1);
    expect(controller.document.blocks[0].isBold, isFalse);
  });

  testWidgets('نافذة الخصائص: تسمية المستند', (WidgetTester tester) async {
    final WriterDocumentController controller = await pumpRibbon(tester, tab: 3);

    await tester.tap(find.byKey(const ValueKey<String>('file-properties')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('properties-title')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('properties-title')),
      'تقرير نهائي',
    );
    await tester.tap(find.byKey(const ValueKey<String>('properties-save')));
    await tester.pumpAndSettle();

    expect(controller.document.title, 'تقرير نهائي');
    expect(find.byKey(const ValueKey<String>('properties-title')), findsNothing);
  });

  testWidgets('لوحة السجلّ تُفتح وتُغلق', (WidgetTester tester) async {
    await pumpRibbon(tester, tab: 3);

    await tester.tap(find.byKey(const ValueKey<String>('file-history')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('history-step-0')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('history-close')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('history-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('history-step-0')), findsNothing);
  });

  testWidgets('الحفظ والتصدير بلا انهيار في بيئة الاختبار', (
    WidgetTester tester,
  ) async {
    final WriterDocumentController controller = await pumpRibbon(
      tester,
      tab: 3,
    );

    // تصدير HTML: منتقي المنصّة غير مفعّل ⇒ سقوط إلى المجلد المؤقت المُحاكى.
    // الكتابة على القرص I/O حقيقية لا تكتمل داخل FakeAsync، لذا ننفّذ
    // السلسلة كاملة داخل runAsync (حلقة حقيقية) ثم نبني التنبيه.
    // يُنفَّذ أولاً لأن تنبيهات ScaffoldMessenger تعاق (الطابور): تنبيه الحفظ
    // اللاحق كان يدفع تنبيه التصدير خارج الشجرة وقت الفحص.
    mockPathProvider();
    final BuildContext context = tester.element(
      find.byKey(const ValueKey<String>('file-export-html')),
    );
    await tester.runAsync(
      () => WriterExportService.exportHtml(context, controller.document),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('تم الحفظ في:'), findsOneWidget);

    // حفظ فوري على تفضيلات مُحاكاة (تنبيهه يصطفّ خلف تنبيه التصدير).
    await tester.tap(find.byKey(const ValueKey<String>('file-save')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('بُناة التصدير تُنتج محتوى فعلياً', () async {
    final WriterDocumentController controller = WriterDocumentController();
    addTearDown(controller.dispose);
    controller.updateActiveBlock(
      controller.activeBlock!.copyWith(text: 'مرحبا بالعالم — نصّ للاختبار.'),
    );

    final Uint8List html = WriterExportService.buildHtmlBytes(
      controller.document,
    );
    expect(html.isNotEmpty, isTrue);
    expect(utf8.decode(html, allowMalformed: true), contains('مرحبا بالعالم'));

    final Uint8List docx = WriterExportService.buildDocxBytes(
      controller.document,
    );
    expect(docx.length, greaterThan(100));
    // DOCX ملف ZIP يبدأ بتوقيع PK.
    expect(docx[0], 0x50);
    expect(docx[1], 0x4B);

    final Uint8List pdf = await WriterExportService.buildPdfBytes(
      controller.document,
    );
    expect(pdf.length, greaterThan(500));
    expect(String.fromCharCodes(pdf.sublist(0, 5)), '%PDF-');
  });
}
