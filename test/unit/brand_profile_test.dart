import 'dart:ui' show Size;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/assets/user_asset.dart';
import 'package:joodcraft/core/brand/brand_presets.dart';
import 'package:joodcraft/core/brand/brand_profile.dart';
import 'package:joodcraft/core/brand/brand_profile_controller.dart';
import 'package:joodcraft/core/brand/brand_store.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/template_editor_controller.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';

/// اختبارات الهوية: النموذج، التخزين، المتحكم، وبواني الإدراج النقية.
void main() {
  const BrandProfile sample = BrandProfile(
    primaryLogoPath: 'a1',
    watermarkLogoPath: 'w1',
    officialSealPaths: <String, String>{'ختم الإدارة': 's1'},
    signatures: <BrandSignature>[
      BrandSignature(id: 'sig1', name: 'أحمد العلي', title: 'المدير', imagePath: 'i1'),
    ],
    orgNameAr: 'شركة الأمل',
    orgNameEn: 'Al-Amal Co',
    headerText: 'ترويسة',
    footerText: 'تذييل',
    taxOrRegNumber: '12345',
    primaryColorHex: '#111111',
    secondaryColorHex: '#222222',
    accentColorHex: '#333333',
    defaultHeaderFontFamily: 'cairo',
    defaultBodyFontFamily: 'amiri',
  );

  group('نموذج الهوية', () {
    test('الترميز وفك الترميز يعيدان البروفايل نفسه', () {
      final BrandProfile restored = BrandProfile.fromJson(sample.toJson());
      expect(restored, sample);
      expect(restored.displayName, 'شركة الأمل');
      expect(restored.hasSeals, isTrue);
      expect(restored.hasSignatures, isTrue);
      expect(restored.hasCustomPalette, isTrue);
    });

    test('بروفايل فارغ بألوان افتراضية', () {
      const BrandProfile empty = BrandProfile();
      expect(empty.isEmpty, isTrue);
      expect(empty.primaryColorHex, BrandProfile.defaultPrimaryHex);
      expect(empty.hasCustomPalette, isFalse);
      expect(BrandProfile.fromJson(<String, dynamic>{'garbage': true}).isEmpty,
          isTrue);
    });

    test('copyWith يميّز «لم يُمرَّر» عن «مُرِّر كـ null»', () {
      final BrandProfile cleared = sample.copyWith(primaryLogoPath: null);
      expect(cleared.hasPrimaryLogo, isFalse);
      // الحقل غير المُرَّر يبقى كما هو.
      expect(cleared.watermarkLogoPath, 'w1');
      // المسح الكامل يُعيد الافتراضي.
      expect(sample.cleared().isEmpty, isTrue);
    });
  });

  group('التخزين', () {
    test('ترميز/فك ترميز المخزن صالحان ويتحمّلان التلف', () {
      final String raw = SharedPreferencesBrandStore.encode(sample);
      expect(SharedPreferencesBrandStore.decode(raw), sample);
      expect(SharedPreferencesBrandStore.decode('{ليس JSON'),
          const BrandProfile());
    });

    test('المتحكم يستعيد ويحفظ ويمسح', () async {
      final InMemoryBrandStore store = InMemoryBrandStore();
      final BrandProfileController controller =
          BrandProfileController(store: store);
      addTearDown(controller.dispose);

      await controller.restore();
      expect(controller.isEmpty, isTrue);

      await controller.setOrgNameAr('شركة الأمل');
      expect(controller.profile.orgNameAr, 'شركة الأمل');
      expect(store.profile.orgNameAr, 'شركة الأمل');

      await controller.clear();
      expect(controller.isEmpty, isTrue);
      expect(store.profile.isEmpty, isTrue);
    });

    test('إدارة الأختام والتوقيعات', () async {
      final BrandProfileController controller =
          BrandProfileController(store: InMemoryBrandStore());
      addTearDown(controller.dispose);

      await controller.setSeal('ختم الشركة', 'seal-1');
      expect(controller.sealNames, <String>['ختم الشركة']);
      expect(controller.sealPath('ختم الشركة'), 'seal-1');

      await controller.upsertSignature(
        const BrandSignature(id: 's', name: 'أحمد', title: 'المدير'),
      );
      expect(controller.signatureById('s')?.name, 'أحمد');

      await controller.removeSeal('ختم الشركة');
      await controller.removeSignature('s');
      expect(controller.hasSeals, isFalse);
      expect(controller.hasSignatures, isFalse);
    });
  });

  group('بواني الهوية', () {
    UserAsset logo() => UserAsset(
          id: 'logo1',
          type: AssetType.logo,
          name: 'شعار',
          fileName: 'logo.png',
          base64Data: '',
          addedAt: DateTime(2026),
        );

    test('buildHeader يجمع الشعار والاسم والتفاصيل في مجموعة واحدة', () {
      final BrandBlock block = BrandPresets.buildHeader(
        profile: sample,
        design: const Size(1000, 700),
        logo: logo(),
      );
      // شعار + اسم + تفاصيل (نص الترويسة).
      expect(block.elements.length, 3);
      expect(block.elements.first, isA<ImageElement>());
      expect((block.elements.first as ImageElement).path, 'logo1');
      expect(block.groupId, isNotEmpty);
      expect(block.isEmpty, isFalse);
    });

    test('buildFooter يبني التذييل ورقم التسجيل', () {
      final BrandBlock block = BrandPresets.buildFooter(
        profile: sample,
        design: const Size(1000, 700),
      );
      expect(block.elements.length, 2);
      expect(block.elements.every((TemplateElement e) => e is TextElement),
          isTrue);
    });

    test('applyPalette يلوّن النصوص والأشكال والصور', () {
      const List<TemplateElement> elements = <TemplateElement>[
        TextElement(
          id: 't',
          box: ElementBox(x: 0, y: 0, width: 10, height: 10),
          text: 'x',
        ),
        ShapeElement(
          id: 's',
          kind: ShapeKind.rect,
          box: ElementBox(x: 0, y: 0, width: 10, height: 10),
          fillHex: '#FFFFFF',
          strokeHex: '#000000',
        ),
        ImageElement(
          id: 'i',
          box: ElementBox(x: 0, y: 0, width: 10, height: 10),
          sourceKind: ImageSourceKind.userAsset,
          path: 'p',
        ),
      ];
      final List<TemplateElement> out = BrandPresets.applyPalette(
        elements,
        primaryHex: '#111111',
        secondaryHex: '#222222',
      );
      expect((out[0] as TextElement).colorHex, '#111111');
      expect((out[1] as ShapeElement).strokeHex, '#111111');
      expect((out[1] as ShapeElement).fillHex, '#222222');
      expect((out[2] as ImageElement).tintHex, '#222222');
    });
  });

  group('تكامل المحرّر', () {
    test('إدراج كتلة الهوية يربط عناصرها كمجموعة واحدة', () {
      final TemplateEditorController controller = TemplateEditorController(
        document: const TemplateDocument(elements: <TemplateElement>[]),
        category: TemplateCategory.certificate,
      );
      addTearDown(controller.dispose);

      final BrandBlock block = BrandPresets.buildFooter(
        profile: sample,
        design: controller.designSize,
      );
      controller.insertBrandBlock(block);

      expect(controller.document.elements.length, block.elements.length);
      expect(controller.selectionCount, block.elements.length);
      expect(controller.selectionIsGrouped, isTrue);
    });

    test('تطبيق ألوان الهوية يغيّر ألوان تحديد المستند', () {
      final TemplateEditorController controller = TemplateEditorController(
        document: const TemplateDocument(
          elements: <TemplateElement>[
            TextElement(
              id: 't',
              box: ElementBox(x: 0, y: 0, width: 100, height: 30),
              text: 'نص',
            ),
          ],
        ),
        category: TemplateCategory.certificate,
      );
      addTearDown(controller.dispose);

      controller.applyBrandPalette(
        primaryHex: '#111111',
        secondaryHex: '#222222',
        selectionOnly: false,
      );
      expect((controller.document.elements.first as TextElement).colorHex,
          '#111111');
    });
  });
}
