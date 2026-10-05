import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/assets/asset_image_cache.dart';
import 'package:joodcraft/core/assets/asset_image_disk_cache.dart';
import 'package:joodcraft/core/assets/asset_store.dart';
import 'package:joodcraft/core/assets/assets_controller.dart';
import 'package:joodcraft/core/assets/embedded_assets.dart';
import 'package:joodcraft/core/assets/user_asset.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';

import '../support/sample_image.dart';

/// إعادة تسخين ذاكرة الصور عند فتح قالب: نجمع معرّفات الأصول المرجعية من
/// المستند، ثم نقرأ بايتاتها المفكوكة من الكاش القرصي بدل إعادة فكّ Base64.
void main() {
  late Directory temp;
  late AssetImageDiskCache previousDisk;
  late AssetsController previousAssets;

  setUp(() {
    AssetImageCache.instance.clear();
    temp = Directory.systemTemp.createTempSync('jood_warm_test');
    previousDisk = AssetImageDiskCache.instance;
    AssetImageDiskCache.instance =
        AssetImageDiskCache(rootPath: '${temp.path}/cache');
    previousAssets = AssetsController.instance;
    AssetsController.instance = AssetsController(store: InMemoryAssetStore());
  });

  tearDown(() {
    AssetImageCache.instance.clear();
    AssetImageDiskCache.instance = previousDisk;
    AssetsController.instance = previousAssets;
    try {
      if (temp.existsSync()) temp.deleteSync(recursive: true);
    } on FileSystemException {
      // قد يبقى ملف مقفولاً لحظياً على ويندوز — لا يُسقط الاختبار.
    }
  });

  Future<UserAsset> addAsset() => AssetsController.instance.addAsset(
        type: AssetType.border,
        name: 'إطار',
        fileName: 'border.png',
        bytes: samplePngBytes(),
      );

  TemplateDocument docWithImage(String path) => TemplateDocument(
        elements: <TemplateElement>[
          ImageElement(
            id: 'frame',
            box: const ElementBox(x: 0, y: 0, width: 400, height: 300),
            sourceKind: ImageSourceKind.userAsset,
            path: path,
            fit: ImageFit.fill,
          ),
        ],
      );

  /// ينتظر حتى تصير نسخة القرص للأصل [id] تساوي [bytes].
  Future<void> waitForDisk(String id, Uint8List bytes) async {
    for (int i = 0; i < 100; i++) {
      final Uint8List? disk = await AssetImageDiskCache.instance.read(id);
      if (disk != null && disk.length == bytes.length) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  group('referencedAssetIds', () {
    test('يجمع معرّفات صور العناصر وخانات التوقيع بترتيب الظهور وبلا تكرار', () {
      final TemplateDocument document = TemplateDocument(
        elements: <TemplateElement>[
          const ImageElement(
            id: 'a',
            box: ElementBox(x: 0, y: 0, width: 10, height: 10),
            sourceKind: ImageSourceKind.userAsset,
            path: 'asset_1',
          ),
          const ImageElement(
            id: 'b',
            box: ElementBox(x: 0, y: 0, width: 10, height: 10),
            sourceKind: ImageSourceKind.userAsset,
            path: 'asset_2',
          ),
          const ImageElement(
            id: 'c',
            box: ElementBox(x: 0, y: 0, width: 10, height: 10),
            sourceKind: ImageSourceKind.userAsset,
            path: 'asset_1', // مكرّر ⇒ يُحذف
          ),
          const ImageElement(
            id: 'd',
            box: ElementBox(x: 0, y: 0, width: 10, height: 10),
            sourceKind: ImageSourceKind.asset,
            path: 'asset_ignored', // ليس أصلاً من المكتبة
          ),
          const SignatureElement(
            id: 'sig',
            box: ElementBox(x: 0, y: 0, width: 100, height: 40),
            slots: <SignatureSlot>[
              SignatureSlot(imagePath: 'asset_3'),
              SignatureSlot(imagePath: ''), // فراغ ⇒ يُتجاهل
            ],
          ),
        ],
      );

      expect(
        referencedAssetIds(document),
        <String>['asset_1', 'asset_2', 'asset_3'],
      );
    });

    test('مستند بلا مراجع أصول يعيد قائمة فارغة', () {
      expect(
        referencedAssetIds(
          const TemplateDocument(elements: <TemplateElement>[]),
        ),
        isEmpty,
      );
    });
  });

  group('warmDocumentImageCache', () {
    test('يسخّن من الكاش القرصي أولاً (لا من Base64)', () async {
      final UserAsset asset = await addAsset();
      // ننتظر أوّلاً كتابة addAsset غير الحاجزة للقرص كي لا تتجاوز نسختنا.
      await waitForDisk(asset.id, samplePngBytes());
      // نسخة قرصية مختلفة عن Base64 العنصر: إن ظهرت في الذاكرة فالمصدر القرص.
      final Uint8List fromDisk = Uint8List.fromList(<int>[9, 9, 9, 9]);
      await AssetImageDiskCache.instance.write(asset.id, fromDisk);
      // كأن التطبيق أُغلق: الذاكرة فارغة والقرص هو المصدر.
      AssetImageCache.instance.clear();

      await warmDocumentImageCache(docWithImage(asset.id));

      expect(AssetImageCache.instance.length, greaterThan(0));
      expect(AssetImageCache.instance.bytesForAsset(asset), fromDisk);
    });

    test('يُعيد التسخين حتى بعد تفريغ الذاكرة (إعادة فتح القالب)', () async {
      final UserAsset asset = await addAsset();
      await AssetImageDiskCache.instance.write(asset.id, samplePngBytes());

      // المحرّر يُفرّغ الذاكرة عند فتح قالب جديد.
      AssetImageCache.instance.clear();
      expect(AssetImageCache.instance.length, 0);

      await warmDocumentImageCache(docWithImage(asset.id));

      expect(AssetImageCache.instance.bytesForAsset(asset), samplePngBytes());
    });

    test('يفكّ من Base64 ويحفظ على القرص عند غياب النسخة', () async {
      final UserAsset asset = await addAsset();
      await waitForDisk(asset.id, samplePngBytes()); // اكتمال الكتابة الأولية
      await AssetImageDiskCache.instance.clear();
      AssetImageCache.instance.clear();

      await warmDocumentImageCache(docWithImage(asset.id));

      expect(AssetImageCache.instance.bytesForAsset(asset), samplePngBytes());
      await waitForDisk(asset.id, samplePngBytes());
      expect(await AssetImageDiskCache.instance.read(asset.id), samplePngBytes());
    });

    test('يسخّن صور خانات التوقيع أيضاً', () async {
      final UserAsset asset = await addAsset();
      await AssetImageDiskCache.instance.write(asset.id, samplePngBytes());
      AssetImageCache.instance.clear();

      final TemplateDocument document = TemplateDocument(
        elements: <TemplateElement>[
          SignatureElement(
            id: 'sig',
            box: const ElementBox(x: 0, y: 0, width: 200, height: 40),
            slots: <SignatureSlot>[
              SignatureSlot(name: 'أحمد', imagePath: asset.id),
            ],
          ),
        ],
      );

      await warmDocumentImageCache(document);
      expect(AssetImageCache.instance.length, greaterThan(0));
    });

    test('يتجاهل المراجع غير الموجودة ولا يرمي', () async {
      await warmDocumentImageCache(docWithImage('asset_ghost'));
      expect(AssetImageCache.instance.length, 0);
    });
  });

  group('warmDocumentsImageCache (مكتبة القوالب)', () {
    test('يدفأ أصول مستندات عدّة دفعة واحدة وبلا تكرار', () async {
      final UserAsset first = await addAsset();
      final UserAsset second = await addAsset();
      await AssetImageDiskCache.instance.write(first.id, samplePngBytes());
      await AssetImageDiskCache.instance.write(second.id, samplePngBytes());
      // كأن التطبيق أُغلق: الذاكرة فارغة والقرص هو المصدر.
      AssetImageCache.instance.clear();

      await warmDocumentsImageCache(<TemplateDocument>[
        docWithImage(first.id), // مرجع مكرّر عبر مستندَين.
        docWithImage(first.id),
        docWithImage(second.id),
      ]);

      expect(AssetImageCache.instance.bytesForAsset(first), samplePngBytes());
      expect(AssetImageCache.instance.bytesForAsset(second), samplePngBytes());
    });

    test('قائمة فارغة لا تفعل شيئاً ولا ترمي', () async {
      await warmDocumentsImageCache(const <TemplateDocument>[]);
      expect(AssetImageCache.instance.length, 0);
    });

    test('مستند بلا مراجع لا يمسّ القرص', () async {
      await warmDocumentsImageCache(<TemplateDocument>[
        const TemplateDocument(elements: <TemplateElement>[]),
      ]);
      expect(AssetImageCache.instance.length, 0);
    });
  });
}
