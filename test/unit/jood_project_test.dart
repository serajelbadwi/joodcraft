import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/assets/asset_store.dart';
import 'package:joodcraft/core/assets/assets_controller.dart';
import 'package:joodcraft/core/assets/user_asset.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/template_editor_controller.dart';
import 'package:joodcraft/core/fonts/custom_font_controller.dart';
import 'package:joodcraft/core/fonts/custom_font_store.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/pdf/custom_pdf_fonts.dart';
import 'package:joodcraft/core/projects/jood/jood_archive.dart';
import 'package:joodcraft/core/projects/jood/jood_autosave_service.dart';
import 'package:joodcraft/core/projects/jood/jood_autosave_store.dart';
import 'package:joodcraft/core/projects/jood/jood_project.dart';
import 'package:joodcraft/core/projects/jood/jood_project_exporter.dart';
import 'package:joodcraft/core/projects/jood/jood_project_importer.dart';

/// أصغر بايتات PNG صالحة البصمة — تكفي `detectImageMime` بلا فكّ ترميز.
Uint8List _pngBytes() => Uint8List.fromList(<int>[
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // signature
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR length + type
    ]);

Future<Uint8List> _fontBytes(String asset) async {
  final ByteData data = await rootBundle.load(asset);
  return data.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JoodArchive (طبقة ZIP)', () {
    test('ترميز وفكّ يحافظان على البايتات والأسماء', () {
      final JoodArchive archive = JoodArchive()
        ..addText('document.json', '{"a":1}')
        ..add('assets/a.png', _pngBytes());
      final Uint8List encoded = archive.encode();

      final JoodArchive decoded = JoodArchive.decode(encoded);
      expect(decoded.length, 2);
      expect(decoded.textOf('document.json'), '{"a":1}');
      expect(decoded.bytesOf('assets/a.png'), _pngBytes());
      expect(decoded.jsonOf('document.json'), <String, dynamic>{'a': 1});
    });

    test('ملف تالف يرمي خطأ صيغة واضحاً', () {
      expect(
        () => JoodArchive.decode(<int>[1, 2, 3, 4, 5]),
        throwsA(isA<JoodArchiveException>()),
      );
      expect(() => JoodArchive.decode(<int>[]), throwsA(isA<JoodArchiveException>()));
    });

    test('امتداد `.jood` يُتعرَّف عليه بلا حساسية لحالة الأحرف', () {
      expect(JoodFormat.isJoodFileName('cert.jood'), isTrue);
      expect(JoodFormat.isJoodFileName('CERT.JOOD'), isTrue);
      expect(JoodFormat.isJoodFileName('cert.pdf'), isFalse);
    });
  });

  group('تصدير/استيراد ‎.jood‎', () {
    late AssetsController assets;
    late CustomFontController fonts;
    late String assetId;
    late String fontFamily;

    setUp(() async {
      CustomPdfFonts.clear();
      assets = AssetsController(store: InMemoryAssetStore());
      AssetsController.instance = assets;
      fonts = CustomFontController(store: InMemoryCustomFontStore());
      CustomFontController.instance = fonts;

      final UserAsset asset = await assets.addAsset(
        type: AssetType.logo,
        name: 'شعار',
        fileName: 'logo.png',
        bytes: _pngBytes(),
      );
      assetId = asset.id;

      // خط حقيقي محزوم حتى يجتاز الفحص ويُسجَّل فعلاً.
      await fonts.addFont(
        fileName: 'Cairo-Regular.ttf',
        bytes: await _fontBytes(AppAssets.pdfCairoRegular),
      );
      fontFamily = fonts.faces.first.family;
    });

    tearDown(() => CustomPdfFonts.clear());

    TemplateDocument buildDocument() => TemplateDocument(
          orientation: PageOrientation.landscape,
          elements: <TemplateElement>[
            ImageElement(
              id: 'img1',
              box: const ElementBox(x: 40, y: 60, width: 120, height: 80),
              sourceKind: ImageSourceKind.userAsset,
              path: assetId,
            ),
            TextElement(
              id: 'txt1',
              box: const ElementBox(x: 200, y: 300, width: 420, height: 60),
              text: 'شهادة تقدير',
              customFont: fontFamily,
            ),
          ],
        );

    test('الملف يحوي المخطّط والأصول والخطوط داخل الأرشيف', () {
      final Uint8List bytes = const JoodProjectExporter().export(
        document: buildDocument(),
        title: 'شهادة اختبار',
        assets: assets,
        fonts: fonts,
        thumbnailPng: _pngBytes(),
      );

      final JoodArchive archive = JoodArchive.decode(bytes);
      expect(archive.contains(JoodFormat.documentFile), isTrue);
      expect(archive.contains(JoodFormat.assetsIndexFile), isTrue);
      expect(archive.contains(JoodFormat.fontsIndexFile), isTrue);
      expect(archive.contains(JoodFormat.thumbnailFile), isTrue);
      expect(
        archive.names.any((String n) => n.startsWith(JoodFormat.assetsPrefix)),
        isTrue,
      );
      expect(
        archive.names.any((String n) => n.startsWith(JoodFormat.fontsPrefix)),
        isTrue,
      );
    });

    test('رحلة كاملة: تصدير ← استيراد ← إعادة بناء المستند والملحقات', () {
      final TemplateDocument document = buildDocument();
      final Uint8List bytes = const JoodProjectExporter().export(
        document: document,
        title: 'شهادة اختبار',
        assets: assets,
        fonts: fonts,
        thumbnailPng: _pngBytes(),
      );

      final JoodProject project = const JoodProjectImporter().read(bytes);
      expect(project.title, 'شهادة اختبار');
      expect(project.isSelfContained, isTrue);
      expect(project.hasThumbnail, isTrue);

      // المستند يعود مطابقاً حرفياً (نفس JSON ⇒ نفس الإحداثيات والألوان).
      expect(
        jsonEncode(project.document.toJson()),
        jsonEncode(document.toJson()),
      );

      // الأصل بمعرّفه الأصلي وبايتاته الكاملة.
      expect(project.assets, hasLength(1));
      expect(project.assets.first.id, assetId);
      expect(project.assets.first.bytes, _pngBytes());

      // الخط بمفتاح تسجيله نفسه وبايتاته الكاملة.
      expect(project.fonts, hasLength(1));
      expect(project.fonts.first.family, fontFamily);
      expect(project.fonts.first.byteSize, greaterThan(1000));
    });

    test('الاستعادة تدمج الملحقات في مكتبة فارغة بمعرّفاتها الأصلية', () async {
      final Uint8List bytes = const JoodProjectExporter().export(
        document: buildDocument(),
        title: 'شهادة',
        assets: assets,
        fonts: fonts,
      );

      // مكتبتان فارغتان جديدتان — كجهاز آخر تماماً.
      final AssetsController freshAssets =
          AssetsController(store: InMemoryAssetStore());
      final CustomFontController freshFonts =
          CustomFontController(store: InMemoryCustomFontStore());

      final JoodProject project = await const JoodProjectImporter()
          .readAndRestore(bytes, assets: freshAssets, fonts: freshFonts);

      expect(freshAssets.byId(assetId), isNotNull);
      expect(freshFonts.faceOf(fontFamily), isNotNull);
      expect(project.document.elements, hasLength(2));
    });

    test('مرجع أصل غائب يُسجَّل في missing بلا إسقاط التصدير', () {
      final String ghostId = 'asset_missing_1';
      final TemplateDocument document = TemplateDocument(
        orientation: PageOrientation.landscape,
        elements: <TemplateElement>[
          ImageElement(
            id: 'img1',
            box: const ElementBox(x: 0, y: 0, width: 100, height: 100),
            sourceKind: ImageSourceKind.userAsset,
            path: ghostId,
          ),
        ],
      );

      final Uint8List bytes = const JoodProjectExporter().export(
        document: document,
        title: 'ناقص',
        assets: assets,
      );
      final JoodProject project = const JoodProjectImporter().read(bytes);
      expect(project.missingAssetIds, contains(ghostId));
      expect(project.isSelfContained, isFalse);
    });

    test('ملف ليس من JoodCraft يرفض برسالة واضحة', () {
      final Uint8List bytes = (JoodArchive()
            ..addText(JoodFormat.documentFile, '{"format":"other"}'))
          .encode();
      expect(
        () => const JoodProjectImporter().read(bytes),
        throwsA(isA<JoodArchiveException>()),
      );
    });
  });

  group('الحفظ التلقائي (Debounce + تعافٍ)', () {
    test('التعديلات المتتابعة تُجمع في كتابة واحدة بعد السكون', () async {
      final InMemoryJoodAutosaveStore store = InMemoryJoodAutosaveStore();
      int builds = 0;
      final JoodAutosaveService service = JoodAutosaveService(
        build: () async {
          builds++;
          return Uint8List.fromList(<int>[1, 2, 3]);
        },
        store: store,
        debounce: const Duration(milliseconds: 40),
      );

      service.schedule();
      service.schedule();
      service.schedule();
      expect(service.isDirty, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(store.writeCount, 1);
      expect(builds, 1);
      expect(service.isDirty, isFalse);
      expect(service.lastSavedAt, isNotNull);
      service.dispose();
    });

    test('flush يكتب فوراً وrecover يعيد آخر مسودّة ثم discard يمسحها', () async {
      final InMemoryJoodAutosaveStore store = InMemoryJoodAutosaveStore();
      final JoodAutosaveService service = JoodAutosaveService(
        build: () => Uint8List.fromList(<int>[9, 8, 7]),
        store: store,
        debounce: const Duration(seconds: 5),
      );

      await service.flush();
      expect(store.writeCount, 1);
      expect(await service.recover(), <int>[9, 8, 7]);

      await service.discard();
      expect(await service.recover(), isNull);
      service.dispose();
    });

    test('فشل البناء لا يُسقط الخدمة ويُبقي isDirty صحيحاً', () async {
      final InMemoryJoodAutosaveStore store = InMemoryJoodAutosaveStore();
      bool fail = true;
      final JoodAutosaveService service = JoodAutosaveService(
        build: () {
          if (fail) throw StateError('boom');
          return Uint8List.fromList(<int>[1]);
        },
        store: store,
        debounce: const Duration(milliseconds: 20),
      );

      service.schedule();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(store.writeCount, 0);
      expect(service.isDirty, isTrue);
      expect(service.lastError, isNotNull);

      fail = false;
      await service.flush();
      expect(store.writeCount, 1);
      service.dispose();
    });
  });

  group('ربط الحفظ التلقائي بالمحرّر', () {
    test('كل تعديل يجدول كتابة مسودّة', () async {
      final InMemoryJoodAutosaveStore store = InMemoryJoodAutosaveStore();
      final JoodAutosaveService service = JoodAutosaveService(
        build: () => Uint8List.fromList(<int>[5]),
        store: store,
        debounce: const Duration(milliseconds: 30),
      );
      final TemplateEditorController controller = TemplateEditorController(
        document: const TemplateDocument(
          orientation: PageOrientation.landscape,
          elements: <TemplateElement>[],
        ),
        category: TemplateCategory.certificate,
      );
      controller.attachAutosave(service);

      controller.rename('عنوان جديد');
      expect(service.isDirty, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(store.writeCount, 1);
      controller.dispose();
    });
  });
}
