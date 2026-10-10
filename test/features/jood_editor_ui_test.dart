import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/widgets/template_editor_view.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/projects/jood/jood_autosave_store.dart';
import 'package:joodcraft/core/projects/jood/jood_project_exporter.dart';
import 'package:joodcraft/core/theme/app_theme.dart';

/// ترابط واجهة ‎.jood‎ بالمحرّر: أزرار التصدير/الفتح، شارة الحفظ التلقائي،
/// وحوار استعادة المسودة عند الإقلاع.
void main() {
  TemplateDocument documentWithText() => const TemplateDocument(
        orientation: PageOrientation.landscape,
        elements: <TemplateElement>[
          TextElement(
            id: 'text-1',
            box: ElementBox(x: 200, y: 200, width: 400, height: 80),
            text: 'نصّ المحرّر',
          ),
        ],
      );

  Future<void> pumpEditor(
    WidgetTester tester, {
    TemplateDocument? document,
    JoodAutosaveStore? store,
  }) async {
    await tester.binding.setSurfaceSize(const Size(3600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TemplateEditorView(
            category: TemplateCategory.certificate,
            initialTemplateAsset: AppAssets.sampleCertificateTemplate,
            exportFileName: 'joodcraft-certificate.pdf',
            title: 'شهادة جديدة',
            document: document,
            autosaveStore: store,
            autosaveDebounce: const Duration(milliseconds: 20),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('تظهر أزرار تصدير وفتح مشروع ‎.jood‎ في الشريط',
      (WidgetTester tester) async {
    await pumpEditor(tester, document: documentWithText());
    expect(find.byKey(const ValueKey<String>('editor-export-jood')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('editor-import-jood')),
        findsOneWidget);
  });

  testWidgets('شارة الحفظ التلقائي تظهر بعد أول كتابة مسودّة',
      (WidgetTester tester) async {
    final InMemoryJoodAutosaveStore store = InMemoryJoodAutosaveStore();
    await pumpEditor(tester, document: documentWithText(), store: store);

    // قبل أي تعديل: لا شارة.
    expect(find.text('تم الحفظ تلقائياً'), findsNothing);
    expect(store.writeCount, 0);

    // تعديل يوسم المستند متسخاً فيجدول المسودّة (تمهيد 20ms).
    await tester.tap(
      find.byKey(const ValueKey<String>('editor-document-menu')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('رأسي'));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.pumpAndSettle();

    expect(store.writeCount, greaterThanOrEqualTo(1));
    expect(find.text('تم الحفظ تلقائياً'), findsOneWidget);
  });

  testWidgets('حوار استعادة المسودة يظهر ويعيد تحميل المستند',
      (WidgetTester tester) async {
    // مسودة ‎.jood‎ سابقة محفوظة في المخزن المحقون.
    final JoodProjectExporter exporter = const JoodProjectExporter();
    final draftBytes = exporter.export(
      document: const TemplateDocument(
        orientation: PageOrientation.landscape,
        elements: <TemplateElement>[
          TextElement(
            id: 'draft-text',
            box: ElementBox(x: 100, y: 120, width: 500, height: 90),
            text: 'مسودة الجلسة السابقة',
          ),
        ],
      ),
      title: 'مسودة مستعادة',
    );
    final InMemoryJoodAutosaveStore store =
        InMemoryJoodAutosaveStore(draftBytes);

    await pumpEditor(tester, document: null, store: store);
    await tester.pumpAndSettle();

    expect(find.text('مسودة غير محفوظة'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('jood-recovery-restore')),
    );
    await tester.pumpAndSettle();

    expect(find.text('مسودة مستعادة'), findsOneWidget);
    expect(find.text('مسودة الجلسة السابقة'), findsOneWidget);
  });

  testWidgets('إهمال المسودة يحذفها ويتابع بالقالب النموذجي',
      (WidgetTester tester) async {
    final draftBytes = const JoodProjectExporter().export(
      document: documentWithText(),
      title: 'مسودة مهملة',
    );
    final InMemoryJoodAutosaveStore store =
        InMemoryJoodAutosaveStore(draftBytes);

    await pumpEditor(tester, document: null, store: store);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('jood-recovery-discard')),
    );
    await tester.pumpAndSettle();

    expect(await store.read(), isNull);
    expect(find.text('نصّ المحرّر'), findsNothing);
  });
}
