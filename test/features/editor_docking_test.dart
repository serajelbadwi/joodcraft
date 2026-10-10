import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/widgets/template_editor_view.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/theme/app_theme.dart';

/// اختبارات إرساء لوحة الأدوات داخل المحرّر: الموضع الافتراضي، والنقل إلى
/// الشريط العلوي واللوحة الجانبية والعوم — بلا فقدان أو تكرار للأدوات.
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

  Future<void> pumpEditor(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(2200, 900));
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
    await tester.pump();
  }

  Finder palette() => find.byKey(const ValueKey<String>('dockable-tool-palette'));

  /// يختار موضع إرساء من قائمة اللوحة.
  Future<void> dockTo(WidgetTester tester, String slot) async {
    await tester.tap(find.byKey(const ValueKey<String>('dock-anchor-editor-tools')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey<String>('dock-slot-$slot')));
    await tester.pumpAndSettle();
  }

  testWidgets('الافتراضي: لوحة الأدوات عائمة على يسار اللوحة',
      (WidgetTester tester) async {
    await pumpEditor(tester);

    expect(palette(), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('tool-text')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('tool-shapes')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('dock-collapse-editor-tools')),
        findsOneWidget);

    final Offset origin = tester.getTopLeft(palette());
    expect(origin.dx, lessThan(120));
    // موسّطة رأسياً: بعيدة عن أعلى الشاشة.
    expect(origin.dy, greaterThan(120));
  });

  testWidgets('الإرساء في الشريط العلوي ينقل اللوحة إلى الترويسة',
      (WidgetTester tester) async {
    await pumpEditor(tester);
    await dockTo(tester, 'top');

    expect(palette(), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('tool-text')), findsOneWidget);
    final Offset origin = tester.getTopLeft(palette());
    final Object? error = tester.takeException();
    if (error is FlutterError) {
      // ignore: avoid_print
      print(error.toStringDeep());
    }
    expect(origin.dy, lessThan(90));
    expect(error, isNull, reason: origin.toString());
  });

  testWidgets('الإرساء في اللوحة الجانبية ينقل اللوحة إلى اليمين',
      (WidgetTester tester) async {
    await pumpEditor(tester);
    await dockTo(tester, 'inspector');

    expect(palette(), findsOneWidget);
    final Offset origin = tester.getTopLeft(palette());
    expect(origin.dx, greaterThan(1500));
    expect(tester.takeException(), isNull);
  });

  testWidgets('العوم يعيد اللوحة إلى أعلى اليسار قابلة للسحب',
      (WidgetTester tester) async {
    await pumpEditor(tester);
    await dockTo(tester, 'floating');

    expect(palette(), findsOneWidget);
    final Offset before = tester.getTopLeft(palette());
    expect(before.dx, lessThan(120));
    expect(before.dy, lessThan(120));

    // سحب فعلي داخل مساحة العمل يُحرّك اللوحة فعلاً.
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey<String>('dock-drag-editor-tools'))),
    );
    await gesture.moveBy(const Offset(120, 20));
    await gesture.moveBy(const Offset(120, 20));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    final Offset after = tester.getTopLeft(palette());
    expect(after.dx, greaterThan(before.dx + 60));
    expect(find.byKey(const ValueKey<String>('tool-text')), findsOneWidget);
  });
}
