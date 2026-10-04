import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/assets/assets_controller.dart';
import 'package:joodcraft/core/assets/asset_store.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/element_factory.dart';
import 'package:joodcraft/core/editor/template_editor_controller.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/pdf/pdf_script_coverage.dart';
import 'package:joodcraft/core/services/pdf_generator_service.dart';

import '../support/sample_image.dart';

/// اختبارات عنصر التوقيعات المتعددة (حتى 3 خانات): التحويل من/إلى JSON،
/// التوزيع التلقائي، الربط بالحقول الديناميكية، والرسم في الـ PDF.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const SignatureElement sample = SignatureElement(
    id: 'sig-1',
    box: ElementBox(x: 10, y: 20, width: 400, height: 140),
    rotation: 5,
    slotCount: 2,
    slots: <SignatureSlot>[
      SignatureSlot(
        role: 'المدير العام',
        name: 'أحمد حمدي',
        imagePath: 'asset-9',
        imageSource: ImageSourceKind.userAsset,
        imageData: 'iVBORw0KGgo=',
      ),
      SignatureSlot(role: 'الموارد البشرية', name: '{{اسم_المتدرب}}'),
      SignatureSlot(role: 'خانة غير معروضة'),
    ],
    roleFontSize: 11,
    nameFontSize: 14,
    roleColorHex: '#111111',
    nameColorHex: '#222222',
    spacing: 30,
    imageScale: 1.2,
    align: SignatureAlign.start,
    showDivider: false,
    direction: ElementDirection.ltr,
    opacity: 0.8,
  );

  group('التحويل من/إلى JSON', () {
    test('الدورة الكاملة تحفظ الخانات والأنماط', () {
      final SignatureElement restored =
          SignatureElement.fromJson(sample.toJson(), 'sig-1');

      expect(restored.slotCount, 2);
      expect(restored.slots.length, 3);
      expect(restored.slots.first.role, 'المدير العام');
      expect(restored.slots.first.name, 'أحمد حمدي');
      expect(restored.slots.first.imagePath, 'asset-9');
      expect(restored.slots.first.imageSource, ImageSourceKind.userAsset);
      // نسخة Base64 الاحتياطية تُحفظ — وإلا ابيضّ التوقيع في الطباعة.
      expect(restored.slots.first.imageData, 'iVBORw0KGgo=');
      expect(restored.roleFontSize, 11);
      expect(restored.nameFontSize, 14);
      expect(restored.spacing, 30);
      expect(restored.imageScale, 1.2);
      expect(restored.align, SignatureAlign.start);
      expect(restored.showDivider, isFalse);
      expect(restored.direction, ElementDirection.ltr);
      expect(restored.opacity, 0.8);
      expect(restored.rotation, 5);
    });

    test('fromJson العام ينشئ SignatureElement من النوع signature', () {
      final TemplateElement element = TemplateElement.fromJson(
        <String, dynamic>{
          'type': 'signature',
          'id': 's1',
          'x': 5,
          'y': 6,
          'w': 300,
          'h': 100,
          'slots': <Map<String, dynamic>>[
            <String, dynamic>{'role': 'المدير', 'name': 'سارة'},
          ],
        },
        0,
      );

      expect(element, isA<SignatureElement>());
      final SignatureElement signature = element as SignatureElement;
      expect(signature.box.width, 300);
      expect(signature.slots.single.name, 'سارة');
    });

    test('النوع signatures/ornament البديلان مدعومان', () {
      expect(
        TemplateElement.fromJson(<String, dynamic>{'type': 'signatures'}, 1),
        isA<SignatureElement>(),
      );
      expect(
        TemplateElement.fromJson(
          <String, dynamic>{'type': 'signature_block'},
          2,
        ),
        isA<SignatureElement>(),
      );
    });

    test('الخانات تُقصّ على 3 كحد أقصى', () {
      final SignatureElement element = SignatureElement.fromJson(
        <String, dynamic>{
          'slots': <Map<String, dynamic>>[
            for (int i = 0; i < 5; i++)
              <String, dynamic>{'role': 'دور $i', 'name': 'اسم $i'},
          ],
        },
        'sig',
      );

      expect(element.slots.length, SignatureSlots.max);
      expect(SignatureSlots.max, 3);
    });

    test('غياب النوع/العدد يستخدم القيم الافتراضية', () {
      final SignatureElement element =
          SignatureElement.fromJson(<String, dynamic>{}, 'sig');

      expect(element.slots, isEmpty);
      expect(element.slotCount, SignatureSlots.max);
      expect(element.roleColorHex, '#5B6779');
      expect(element.nameColorHex, '#1B2539');
      expect(element.showDivider, isTrue);
      expect(element.direction, ElementDirection.rtl);
    });

    test('slotCount يتجاهل ما بعد العدد المطلوب', () {
      final SignatureElement trimmed = sample.withSlotCount(1);
      expect(trimmed.slotCount, 1);
      // المحتوى محفوظ حتى لا يُفقَد عند إعادة الزيادة.
      expect(trimmed.slots.length, 3);
      expect(trimmed.activeSlots.length, 1);
      expect(trimmed.activeSlots.single.role, 'المدير العام');

      final SignatureElement restored = trimmed.withSlotCount(3);
      expect(restored.activeSlots.length, 3);
    });

    test('slotCount يُقصّ إلى المدى 1..3', () {
      expect(sample.withSlotCount(0).slotCount, 1);
      expect(sample.withSlotCount(9).slotCount, SignatureSlots.max);
    });
  });

  group('التوزيع التلقائي (placement)', () {
    test('الخانات متساوية العرض ومتباعدة بالفراغ المطلوب', () {
      const SignatureElement element = SignatureElement(
        id: 's',
        box: ElementBox(x: 0, y: 0, width: 400, height: 120),
        spacing: 20,
        slots: <SignatureSlot>[
          SignatureSlot(role: 'أ'),
          SignatureSlot(role: 'ب'),
          SignatureSlot(role: 'ج'),
        ],
      );

      final List<SignatureSlotRect> rects = element.slotLayout(400);

      expect(rects.length, 3);
      // ‎(400 - 2×20) ÷ 3 = 120‎
      for (final SignatureSlotRect rect in rects) {
        expect(rect.width, closeTo(120, 0.001));
      }
      expect(rects[0].left, closeTo(0, 0.001));
      expect(rects[1].left, closeTo(140, 0.001));
      expect(rects[2].left, closeTo(280, 0.001));
      // لا تتجاوز الخانات عرض الصندوق.
      expect(rects.last.left + rects.last.width, lessThanOrEqualTo(400.001));
    });

    test('الترتيب العربي يضع الخانة الأولى يميناً', () {
      expect(
        sample.orderedSlots.first.role,
        'المدير العام',
        reason: 'العنصر في الاختبار بترتيب لاتيني',
      );

      final SignatureElement rtl = sample.copyWith(
        direction: ElementDirection.rtl,
      );
      expect(rtl.orderedSlots.first.role, 'الموارد البشرية');
      expect(rtl.orderedSlots.last.role, 'المدير العام');
    });

    test('الخانة الفارغة تماماً لا تُرسم ولا تُحسب', () {
      const SignatureElement element = SignatureElement(
        id: 's',
        box: ElementBox(x: 0, y: 0, width: 300, height: 100),
        slots: <SignatureSlot>[
          SignatureSlot(role: 'أ'),
          SignatureSlot(),
          SignatureSlot(name: 'ب'),
        ],
      );

      expect(element.activeSlots.length, 2);
      // خانة فارغة واحدة ⇒ عرضان متساويان لا ثلاثة.
      expect(element.slotLayout(300).length, 2);
    });

    test('صندوق بعرض صفر أو خانات فارغة لا يُنتج توزيعاً', () {
      expect(sample.slotLayout(0), isEmpty);
      const SignatureElement empty = SignatureElement(
        id: 's',
        box: ElementBox(),
      );
      expect(empty.slotLayout(300), isEmpty);
    });

    test('ارتفاع صورة التوقيع يتبع عرض الخانة ومعامل التحجيم', () {
      const SignatureElement element = SignatureElement(
        id: 's',
        box: ElementBox(x: 0, y: 0, width: 300, height: 200),
        imageScale: 1,
      );

      // ‎120 × 0.42 = 50.4‎
      expect(element.imageHeightFor(120), closeTo(50.4, 0.001));
      expect(
        element.copyWith(imageScale: 2).imageHeightFor(120),
        closeTo(100.8, 0.001),
      );
      // سقف العرض: لا تتجاوز الصورة عرض خنتها.
      expect(element.copyWith(imageScale: 9).imageHeightFor(120), 120);
      // سقف الارتفاع: لا تتجاوز 70% من ارتفاع الصندوق.
      expect(
        element.copyWith(imageScale: 9).imageHeightFor(120, boxHeight: 100),
        70,
      );
    });

    test('withSlot يوسّع القائمة عند الكتابة في خانة غير موجودة', () {
      const SignatureElement element = SignatureElement(
        id: 's',
        box: ElementBox(),
        slots: <SignatureSlot>[SignatureSlot(role: 'أ')],
      );

      final SignatureElement updated = element.withSlot(
        2,
        const SignatureSlot(role: 'ج'),
      );
      expect(updated.slots.length, 3);
      expect(updated.slots[2].role, 'ج');
      // فهرس خارج الحدود لا يغيّر شيئاً.
      expect(element.withSlot(9, const SignatureSlot(role: '×')).slots.length, 1);
    });
  });

  group('الحقول الديناميكية', () {
    test('اسم المُوقّع يُربط كحقل ديناميكي في المستند', () {
      final TemplateDocument document = TemplateDocument(
        elements: <TemplateElement>[sample],
      );

      expect(document.hasDynamicFields, isTrue);
      expect(document.fieldKeys, contains('اسم_المتدرب'));
    });

    test('دور/اسم بلا حقول لا يُعلن حاجة للحقول', () {
      const SignatureElement plain = SignatureElement(
        id: 's',
        box: ElementBox(),
        slots: <SignatureSlot>[SignatureSlot(role: 'المدير', name: 'أحمد')],
      );
      final TemplateDocument document = TemplateDocument(
        elements: <TemplateElement>[plain],
      );

      expect(document.hasDynamicFields, isFalse);
      expect(document.fieldKeys, isEmpty);
    });

    test('resolveFields يستبدل اسم المُوقّع ببيانات الصف', () {
      const SignatureElement element = SignatureElement(
        id: 's',
        box: ElementBox(),
        slots: <SignatureSlot>[
          SignatureSlot(role: 'المدير العام', name: '{{اسم_المتدرب}}'),
        ],
      );
      final TemplateDocument document =
          TemplateDocument(elements: <TemplateElement>[element]);

      expect(
        document.resolveFields(
          element.slots.single.name,
          <String, String>{'اسم_المتدرب': 'محمد الشمري'},
        ),
        'محمد الشمري',
      );
    });
  });

  group('المحرر', () {
    test('التكرار يحفظ الخانات وعددها (‎_withId‎)', () {
      final TemplateEditorController controller = TemplateEditorController(
        document: TemplateDocument(elements: <TemplateElement>[sample]),
        category: TemplateCategory.certificate,
      );
      addTearDown(controller.dispose);

      controller.select('sig-1');
      controller.duplicateSelected();

      final SignatureElement copy = controller.selected! as SignatureElement;
      expect(copy.id, isNot('sig-1'));
      expect(copy.slotCount, 2);
      expect(copy.slots.length, 3);
      expect(copy.slots.first.name, 'أحمد حمدي');
      expect(copy.direction, ElementDirection.ltr);
    });

    test('تعديل خانة واحدة يحدّث العنصر المحدد', () {
      final TemplateEditorController controller = TemplateEditorController(
        document: TemplateDocument(elements: <TemplateElement>[sample]),
        category: TemplateCategory.certificate,
      );
      addTearDown(controller.dispose);

      controller.select('sig-1');
      controller.updateSelectedSignatureSlot(
        1,
        const SignatureSlot(role: 'الموارد البشرية', name: 'ليلى'),
      );

      final SignatureElement updated = controller.selected! as SignatureElement;
      expect(updated.slots[1].name, 'ليلى');
      expect(updated.slots[1].role, 'الموارد البشرية');
    });

    test('تغيير العدد والأنماط يصل إلى المستند', () {
      final TemplateEditorController controller = TemplateEditorController(
        document: TemplateDocument(elements: <TemplateElement>[sample]),
        category: TemplateCategory.certificate,
      );
      addTearDown(controller.dispose);

      controller.select('sig-1');
      controller.setSelectedSignatureSlotCount(3);
      controller.setSelectedSignatureStyle(
        nameFontSize: 18,
        spacing: 40,
        showDivider: true,
        direction: ElementDirection.rtl,
      );

      final SignatureElement updated = controller.selected! as SignatureElement;
      expect(updated.slotCount, 3);
      expect(updated.nameFontSize, 18);
      expect(updated.spacing, 40);
      expect(updated.showDivider, isTrue);
      expect(updated.direction, ElementDirection.rtl);

      // استبدال المستند بنسخة محوّلة يحفظ نفس القيم (دورة كاملة عبر Document).
      final TemplateDocument restored =
          TemplateDocument.fromJson(controller.document.toJson());
      final SignatureElement fromJson =
          restored.elements.single as SignatureElement;
      expect(fromJson.slotCount, 3);
      expect(fromJson.nameFontSize, 18);
      expect(fromJson.direction, ElementDirection.rtl);
    });

    test('المصنع ينشئ كتلة بثلاث خانات وحقول ديناميكية', () {
      final SignatureElement element = ElementFactory.createSignature(
        design: const Size(1123, 794),
        index: 0,
      );

      expect(element.slots.length, 3);
      expect(element.slotCount, 3);
      expect(element.hasDynamicFields, isTrue);
      expect(element.activeSlots.length, 3);
      expect(element.box.width, greaterThan(0));
      expect(element.box.y + element.box.height, lessThanOrEqualTo(794));
    });

    test('شريط العناصر يعرض زر كتلة التوقيعات', () {
      expect(NewElementKind.values, contains(NewElementKind.signature));
    });
  });

  group('تغطية الكتابات', () {
    test('اسم بكتابة صينية داخل خانة يُكتشف كغير مغطّى', () {
      const SignatureElement element = SignatureElement(
        id: 's',
        box: ElementBox(),
        slots: <SignatureSlot>[
          SignatureSlot(role: 'المدير العام', name: '李雷'),
        ],
      );
      final TemplateDocument document = TemplateDocument(
        elements: <TemplateElement>[element],
      );

      expect(
        PdfScriptCoverage.unsupportedInDocument(document),
        contains(PdfScript.cjk),
      );
    });

    test('دور واسم عربيان لا يُنتجان تحذيراً', () {
      final TemplateDocument document = TemplateDocument(
        elements: <TemplateElement>[sample],
      );

      expect(PdfScriptCoverage.unsupportedInDocument(document), isEmpty);
    });
  });

  group('الطباعة (PDF)', () {
    test('كتلة التوقيعات تُرسم في ملف PDF صالح', () async {
      final AssetsController assets = AssetsController(
        store: InMemoryAssetStore(),
      );
      AssetsController.instance = assets;

      final PdfGeneratorService service =
          await PdfGeneratorService.create(compress: false, useIsolate: false);
      final TemplateDocument document = TemplateDocument(
        orientation: PageOrientation.landscape,
        elements: <TemplateElement>[
          const SignatureElement(
            id: 'sig',
            box: ElementBox(x: 60, y: 520, width: 800, height: 160),
            slots: <SignatureSlot>[
              SignatureSlot(role: 'المدرب', name: 'أحمد حمدي'),
              SignatureSlot(role: 'الموارد البشرية', name: 'ليلى حسن'),
              SignatureSlot(role: 'المدير العام', name: 'سارة العتيبي'),
            ],
          ),
        ],
      );

      final PdfGenerationReport report =
          await service.generate(document: document);

      expect(report.pageCount, 1);
      expect(report.bytes.lengthInBytes, greaterThan(1000));
      expect(String.fromCharCodes(report.bytes.take(5)), '%PDF-');
      // لا تحذيرات تغطية/رسم من كتلة التوقيعات.
      expect(
        report.warnings.any((String warning) => warning.contains('التوقيع')),
        isFalse,
      );
    });

    test('صورة توقيع مضمّنة (Base64) تُدمج بلا تحذير أصل محذوف', () async {
      AssetsController.instance = AssetsController(
        store: InMemoryAssetStore(),
      );
      final PdfGeneratorService service =
          await PdfGeneratorService.create(compress: false, useIsolate: false);

      final TemplateDocument document = TemplateDocument(
        elements: <TemplateElement>[
          SignatureElement(
            id: 'sig',
            box: const ElementBox(x: 40, y: 60, width: 600, height: 160),
            slots: <SignatureSlot>[
              SignatureSlot(
                role: 'المدير العام',
                name: 'أحمد حمدي',
                imageSource: ImageSourceKind.dataUri,
                imagePath: samplePngBase64(),
              ),
            ],
          ),
        ],
      );

      final PdfGenerationReport report =
          await service.generate(document: document);

      expect(report.pageCount, 1);
      expect(
        report.warnings.any((String w) => w.contains('أصل محذوف')),
        isFalse,
      );
    });

    test('صورة توقيع من أصل محذوف تُنتج تحذيراً بلا إسقاط الطباعة', () async {
      AssetsController.instance = AssetsController(
        store: InMemoryAssetStore(),
      );
      final PdfGeneratorService service =
          await PdfGeneratorService.create(compress: false, useIsolate: false);

      final TemplateDocument document = TemplateDocument(
        elements: <TemplateElement>[
          const SignatureElement(
            id: 'sig',
            box: ElementBox(x: 40, y: 60, width: 600, height: 160),
            slots: <SignatureSlot>[
              SignatureSlot(
                role: 'المدير العام',
                name: 'أحمد حمدي',
                imagePath: 'asset-مفقود',
                imageSource: ImageSourceKind.userAsset,
              ),
            ],
          ),
        ],
      );

      final PdfGenerationReport report =
          await service.generate(document: document);

      expect(report.pageCount, 1);
      expect(
        report.warnings.any((String w) => w.contains('أصل محذوف')),
        isTrue,
      );
    });

    test('عنصر توقيعات بلا خانات لا يُسقط توليد الصفحة', () async {
      AssetsController.instance = AssetsController(
        store: InMemoryAssetStore(),
      );
      final PdfGeneratorService service =
          await PdfGeneratorService.create(compress: false, useIsolate: false);

      final PdfGenerationReport report = await service.generate(
        document: const TemplateDocument(
          elements: <TemplateElement>[
            SignatureElement(
              id: 'sig',
              box: ElementBox(x: 40, y: 60, width: 400, height: 120),
            ),
          ],
        ),
      );

      expect(report.pageCount, 1);
      expect(String.fromCharCodes(report.bytes.take(5)), '%PDF-');
    });
  });
}
