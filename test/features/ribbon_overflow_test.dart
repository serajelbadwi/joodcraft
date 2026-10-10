import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/widgets/template_canvas.dart';
import 'package:joodcraft/core/editor/widgets/template_editor_view.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/theme/app_theme.dart';

/// اختبارات تنظيف الشريط العلوي:
///
/// * خصائص المستند الكلّية (الاتجاه/المقاس/الخلفية/الإطار) مجموعة في **قائمة
///   منسدلة واحدة** أعلى الشريط.
/// * ما لا يتّسع من أدوات ينتقل إلى قائمة «أدوات أخرى» **في الشريط نفسه** —
///   لا إلى درج في اللوحة الجانبية.
/// * لا يبقى أيّ نصّ إرشادي موجّه للمطوّر.
void main() {
  const TemplateDocument document = TemplateDocument(
    orientation: PageOrientation.landscape,
    elements: <TemplateElement>[
      TextElement(
        id: 'text-1',
        box: ElementBox(x: 200, y: 200, width: 400, height: 80),
        text: 'شهادة إتمام',
      ),
    ],
  );

  Future<void> pumpEditor(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: TemplateEditorView(
            category: TemplateCategory.certificate,
            initialTemplateAsset: AppAssets.sampleCertificateTemplate,
            exportFileName: 'joodcraft-certificate.pdf',
            title: 'شهادة جديدة',
            document: document,
          ),
        ),
      ),
    );
    // إطار للبناء وإطار لتثبيت قياسات الشريط بعد حساب الفيض.
    await tester.pump();
    await tester.pump();
  }

  Finder byKey(String key) => find.byKey(ValueKey<String>(key));

  testWidgets('الشاشة الواسعة تُظهر الأدوات كلها بلا قائمة فيض',
      (WidgetTester tester) async {
    await pumpEditor(tester, const Size(3600, 1000));

    expect(byKey('dock-overflow-chip'), findsNothing);
    expect(byKey('editor-export-pdf'), findsOneWidget);
    expect(find.textContaining('عنصراً'), findsOneWidget);
    expect(byKey('editor-document-menu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('خصائص المستند مجموعة في قائمة منسدلة واحدة أعلى الشريط',
      (WidgetTester tester) async {
    await pumpEditor(tester, const Size(3600, 1000));

    // لا شيء من خصائص المستند على الشريط قبل فتح القائمة.
    expect(find.text('اتجاه الورقة'), findsNothing);
    expect(find.text('خلفية المستند'), findsNothing);

    await tester.tap(byKey('editor-document-menu'));
    await tester.pumpAndSettle();

    // الاتجاه والمقاس والخلفية والإطار كلها في القائمة نفسها.
    expect(find.text('اتجاه الورقة'), findsOneWidget);
    expect(find.byTooltip('رأسي'), findsOneWidget);
    expect(byKey('custom-size-button'), findsOneWidget);
    expect(find.text('خلفية المستند'), findsOneWidget);
    expect(byKey('document-background-library'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('الشاشة الضيقة تُخلي الأدوات الأدنى أولوية إلى قائمة «أدوات أخرى»',
      (WidgetTester tester) async {
    await pumpEditor(tester, const Size(1000, 900));

    expect(byKey('dock-overflow-chip'), findsOneWidget);
    // لم يبقَ أيّ درج في اللوحة الجانبية.
    expect(byKey('editor-overflow-drawer'), findsNothing);

    await tester.tap(byKey('dock-overflow-chip'));
    await tester.pumpAndSettle();

    // الأدوات المُخلاة كاملةً داخل القائمة: إجراءات الحفظ/التصدير وحالة القالب.
    expect(byKey('editor-export-pdf'), findsOneWidget);
    expect(find.text('الحفظ غير متاح'), findsOneWidget);
    expect(find.textContaining('عنصراً'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('قائمة الفيض تُتيح الوصول إلى خصائص المستند نفسها',
      (WidgetTester tester) async {
    await pumpEditor(tester, const Size(1000, 900));

    await tester.tap(byKey('dock-overflow-chip'));
    await tester.pumpAndSettle();

    // منيو خصائص المستند نفسها صارت داخل قائمة الفيض — تُفتح وتعمل بلا تعارض.
    await tester.tap(byKey('editor-document-menu'));
    await tester.pumpAndSettle();

    expect(byKey('document-background-library'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('بلا لوحة جانبية (شاشة ضيقة جداً) تبقى الأدوات في الشريط',
      (WidgetTester tester) async {
    await pumpEditor(tester, const Size(640, 700));

    expect(byKey('dock-overflow-chip'), findsOneWidget);
    // لا لوحة جانبية على هذه الشاشة.
    expect(byKey('panel-collapse-button'), findsNothing);

    await tester.tap(byKey('dock-overflow-chip'));
    await tester.pumpAndSettle();

    expect(byKey('editor-export-pdf'), findsOneWidget);
    expect(find.textContaining('عنصراً'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('وضع معاينة PDF لا يُفقد أدوات الشريط',
      (WidgetTester tester) async {
    await pumpEditor(tester, const Size(1000, 900));

    // مبدّل طريقة العرض يظهر على الشريط أو داخل قائمة الفيض حسب المساحة.
    if (byKey('dock-overflow-chip').evaluate().isNotEmpty) {
      await tester.tap(byKey('dock-overflow-chip'));
      await tester.pumpAndSettle();
    }

    await tester.ensureVisible(find.byTooltip('معاينة PDF'));
    await tester.tap(find.byTooltip('معاينة PDF'));
    // `pump` لا `pumpAndSettle`: المعاينة تبني PDF وقد تُبقي مؤشّر تقدّم دائماً.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(TemplateCanvas), findsNothing);
    expect(byKey('editor-overflow-drawer'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('لا يظهر أيّ نصّ إرشادي موجّه للمطوّر في الشريط أو قوائمه',
      (WidgetTester tester) async {
    await pumpEditor(tester, const Size(1000, 900));

    expect(find.textContaining('لضيق مساحة الشريط العلوي'), findsNothing);

    await tester.tap(byKey('dock-overflow-chip'));
    await tester.pumpAndSettle();

    expect(find.textContaining('انتقلت هذه الأدوات'), findsNothing);
    expect(find.textContaining('لضيق مساحة الشريط العلوي'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
