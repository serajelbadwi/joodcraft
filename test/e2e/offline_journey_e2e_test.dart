import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:joodcraft/core/assets/asset_store.dart';
import 'package:joodcraft/core/assets/assets_controller.dart';
import 'package:joodcraft/core/assets/user_asset.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/templates/local_template_store.dart';
import 'package:joodcraft/core/templates/preset_catalog.dart';
import 'package:joodcraft/core/templates/preset_template.dart';
import 'package:joodcraft/core/templates/template_draft.dart';
import 'package:joodcraft/core/templates/template_record.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/features/assets_manager/presentation/screens/assets_manager_screen.dart';
import 'package:joodcraft/features/batch_processor/presentation/providers/batch_processor_controller.dart';
import 'package:joodcraft/features/certificate_builder/presentation/screens/template_editor_screen.dart';
import 'package:joodcraft/features/templates/presentation/screens/template_library_screen.dart';

// ignore: depend_on_referenced_packages
import 'package:cross_file/cross_file.dart';

import '../support/sample_image.dart';

/// اختبار طرف-إلى-طرف للرحلة الأوفلاين كاملة (المرحلة 6):
/// رفع أصول ← فتح قالب جاهز في المحرّر ← ربط الأصول والبيانات ← التوليد الجماعي
/// ← التحقق من سلامة ملف PDF الناتج. كل ذلك بلا أي شبكة.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AssetsController assets;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    assets = AssetsController(store: InMemoryAssetStore());
    AssetsController.instance = assets;
  });

  testWidgets('رحلة الواجهة: رفع شعار من المدير ثم فتح قالب جاهز في المحرّر',
      (WidgetTester tester) async {
    FilePickerPlatform.instance = _FakeFilePicker(<PlatformFile>[
      _FakePlatformFile(name: 'logo.png', bytes: samplePngBytes()),
    ]);

    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final GoRouter router = GoRouter(
      initialLocation: '/assets',
      routes: <RouteBase>[
        GoRoute(
          path: '/assets',
          builder: (BuildContext context, GoRouterState state) =>
              Scaffold(body: AssetsManagerScreen(controller: assets)),
        ),
        GoRoute(
          path: '/templates',
          builder: (BuildContext context, GoRouterState state) => Scaffold(
            body: TemplateLibraryScreen(
              localStore: InMemoryLocalTemplateStore(),
            ),
          ),
        ),
        GoRoute(
          path: '/certificate-builder',
          builder: (BuildContext context, GoRouterState state) {
            final Object? extra = state.extra;
            return Scaffold(
              body: CertificateTemplateEditorScreen(
                draft: extra is TemplateDraft ? extra : null,
                record: extra is TemplateRecord ? extra : null,
              ),
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();

    // (1) رفع الشعار عبر المدير الحقيقي.
    await tester.tap(find.text('رفع أصل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('رفع شعار').last);
    await tester.pumpAndSettle();
    expect(assets.count, 1);
    expect(find.text('logo'), findsOneWidget);

    // (2) الانتقال إلى مكتبة القوالب وفتح قالب جاهز.
    router.go('/templates');
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(
          const ValueKey<String>('library-entry-preset:appreciation_certificate'),
        ),
        matching: find.text('فتح كقالب'),
      ),
    );
    await tester.pumpAndSettle();

    // (3) المحرّر الحقيقي فتح القالب الجاهز (عنوانه وعناصره ظاهرة).
    expect(find.text('شهادة شكر وتقدير'), findsWidgets);
    expect(find.textContaining('عنصراً'), findsOneWidget);
  });

  test('رحلة التوليد: أصول + قالب جاهز + بيانات Excel ← ملف PDF سليم', () async {
    // (1) رفع شعار وتوقيع محليين.
    final UserAsset logo = await assets.addAsset(
      type: AssetType.logo,
      name: 'شعار المؤسسة',
      fileName: 'logo.png',
      bytes: samplePngBytes(),
    );
    final UserAsset signature = await assets.addAsset(
      type: AssetType.signature,
      name: 'التوقيع المعتمد',
      fileName: 'sign.png',
      bytes: samplePngBytes(),
    );
    expect(assets.count, 2);

    // (2) القالب الجاهز + ربط الأصلين كعناصر صورة.
    final PresetTemplate preset =
        PresetCatalog.byId('appreciation_certificate')!;
    final TemplateDocument base = preset.document;
    final TemplateDocument document = base.copyWith(
      elements: <TemplateElement>[
        ...base.elements,
        ImageElement(
          id: 'logo_el',
          box: const ElementBox(x: 70, y: 70, width: 120, height: 120),
          sourceKind: ImageSourceKind.userAsset,
          path: logo.id,
        ),
        ImageElement(
          id: 'sign_el',
          box: const ElementBox(x: 800, y: 600, width: 190, height: 70),
          sourceKind: ImageSourceKind.userAsset,
          path: signature.id,
        ),
      ],
    );
    expect(document.elements.whereType<ImageElement>().length, 2);

    // (3) بيانات Excel (CSV) وربطها تلقائياً بمحرّك التوليد الجماعي.
    final BatchProcessorController controller = BatchProcessorController();
    controller.useDocument(document);

    const String csv = 'اسم_المتدرب,رقم_الشهادة\n'
        'عبدالله بن أحمد الشمري,JC-2026-000145\n'
        'سارة محمد العتيبي,JC-2026-000146\n';
    controller.loadBytes(
      fileName: 'graduates.csv',
      bytes: Uint8List.fromList(utf8.encode(csv)),
    );
    expect(controller.errorAr, isNull);
    expect(controller.mapping.isNotEmpty, isTrue);
    expect(controller.canGenerate, isTrue);

    // (4) التوليد الفعلي عبر محرّك الـ PDF الحقيقي.
    await controller.generate();
    expect(controller.errorAr, isNull);

    final report = controller.report;
    expect(report, isNotNull);
    expect(report!.generatedCount, 2);
    expect(report.pageCount, 2);
    expect(report.hasOutput, isTrue);
    expect(
      report.warnings
          .where((String w) => w.contains('صورة مفقودة') || w.contains('تعذّر تحميل الصورة')),
      isEmpty,
      reason: 'يجب أن تُحلّ أصول المكتبة داخل ملف الـ PDF بلا تحذيرات',
    );

    // (5) التحقق من سلامة بنية ملف الـ PDF الناتج.
    final Uint8List bytes = report.combinedPdf!;
    final String head = latin1.decode(bytes.sublist(0, 5), allowInvalid: true);
    final String tail =
        latin1.decode(bytes.sublist(bytes.length - 8), allowInvalid: true);
    final String raw = latin1.decode(bytes, allowInvalid: true);
    expect(head, startsWith('%PDF'));
    expect(tail, contains('%%EOF'));
    expect(raw, contains('/Image'));
    expect(report.byteSize, greaterThan(1000));

    controller.dispose();
  });
}

/// منتقي ملفات مزيّف يعيد ملفات ثابتة بدل فتح الحوار الأصلي.
final class _FakeFilePicker extends FilePickerPlatform {
  _FakeFilePicker(this._files);

  final List<PlatformFile> _files;

  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async =>
      _files;
}

/// ملف منصّة مزيّف يحمل بايتات الصورة في الذاكرة بلا أي قرص.
final class _FakePlatformFile extends PlatformFile {
  _FakePlatformFile({required this.name, required Uint8List bytes})
      : _bytes = bytes;

  @override
  final String name;

  final Uint8List _bytes;

  @override
  Uri get uri => Uri.file(name);

  @override
  XFile get xFile => throw UnimplementedError();

  @override
  int? lengthSync() => _bytes.length;

  @override
  Future<int?> length() async => _bytes.length;

  @override
  Future<Uint8List> readAsBytes() async => _bytes;

  @override
  Stream<Uint8List> readAsByteStream() async* {
    yield _bytes;
  }
}
