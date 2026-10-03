import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/assets/asset_store.dart';
import 'package:joodcraft/core/assets/assets_controller.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/widgets/template_editor_view.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/theme/app_theme.dart';

import '../support/fake_template_repository.dart';

/// زر «تصدير PDF» في شريط المحرّر: وجوده، وعدم إيقاف التصدير عند غياب أصل
/// (يُرسم بقية المستند بلا شريط تحذير يحجب العملية).
void main() {
  late AssetsController previousAssets;

  setUp(() {
    previousAssets = AssetsController.instance;
    // مكتبة فارغة ⇒ مرجع `asset_missing` يبدو مفقوداً.
    AssetsController.instance = AssetsController(store: InMemoryAssetStore());
  });

  tearDown(() => AssetsController.instance = previousAssets);

  TemplateDocument document({bool withMissingAsset = true}) =>
      TemplateDocument(
        orientation: PageOrientation.landscape,
        elements: <TemplateElement>[
          const TextElement(
            id: 'text-1',
            box: ElementBox(x: 200, y: 200, width: 400, height: 80),
            text: 'شهادة إتمام',
          ),
          if (withMissingAsset)
            const ImageElement(
              id: 'frame',
              box: ElementBox(x: 0, y: 0, width: 400, height: 300),
              sourceKind: ImageSourceKind.userAsset,
              path: 'asset_missing',
              fit: ImageFit.fill,
            ),
        ],
      );

  Future<void> pumpEditor(
    WidgetTester tester, {
    required TemplateDocument doc,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TemplateEditorView(
            category: TemplateCategory.certificate,
            initialTemplateAsset: AppAssets.sampleCertificateTemplate,
            exportFileName: 'joodcraft-certificate.pdf',
            repository: FakeTemplateRepository(),
            title: 'شهادة جديدة',
            document: doc,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('زر «تصدير PDF» معروض في شريط المحرّر',
      (WidgetTester tester) async {
    await pumpEditor(tester, doc: document(withMissingAsset: false));

    expect(
      find.byKey(const ValueKey<String>('editor-export-pdf')),
      findsOneWidget,
    );
    expect(find.text('تصدير PDF'), findsOneWidget);
  });

  testWidgets('التصدير لا يُحجب بسبب أصل محذوف ولا يظهر شريط الخطأ',
      (WidgetTester tester) async {
    await pumpEditor(tester, doc: document());

    await tester.tap(find.byKey(const ValueKey<String>('editor-export-pdf')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // لا شريط «تعذّر التصدير» ولا ذكر لمرجع الأصل المفقود — التصدير يُكمل
    // مساره (قد يفشل لاحقاً فقط في قناة المشاركة في بيئة الاختبار).
    expect(find.textContaining('تعذّر التصدير'), findsNothing);
    expect(find.textContaining('asset_missing'), findsNothing);

    await tester.pump(const Duration(seconds: 5));
  });
}
