import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/canvas_geometry.dart';
import 'package:joodcraft/core/editor/element_factory.dart';
import 'package:joodcraft/core/editor/template_editor_controller.dart';
import 'package:joodcraft/core/errors/app_error_code.dart';
import 'package:joodcraft/core/errors/app_exception.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/pdf/pdf_font_catalog.dart';
import 'package:joodcraft/core/templates/template_library_controller.dart';
import 'package:joodcraft/core/templates/template_record.dart';
import '../support/fake_template_repository.dart';

void main() {
  late TemplateEditorController controller;

  /// قالب اختباري: عنصر نصي واحد + ختم واحد على ورقة A4 أفقية.
  TemplateDocument document() => TemplateDocument(
        orientation: PageOrientation.landscape,
        elements: <TemplateElement>[
          const TextElement(
            id: 'text-1',
            box: ElementBox(x: 100, y: 100, width: 300, height: 80),
            text: 'مرحباً {{اسم_المتدرب}}',
          ),
          const SealElement(
            id: 'seal-1',
            box: ElementBox(x: 500, y: 400, width: 120, height: 120),
          ),
        ],
      );

  TemplateEditorController build({FakeTemplateRepository? repository}) {
    return TemplateEditorController(
      document: document(),
      category: TemplateCategory.certificate,
      repository: repository,
      title: 'قالب اختبار',
    );
  }

  setUp(() => controller = build());

  tearDown(() => controller.dispose());

  group('التحديد', () {
    test('يبدأ بلا تحديد', () {
      expect(controller.hasSelection, isFalse);
      expect(controller.selected, isNull);
    });

    test('تحديد عنصر يُعيده من القائمة', () {
      controller.select('text-1');
      expect(controller.selected, isA<TextElement>());
      expect(controller.selected!.id, 'text-1');
    });

    test('تحديد معرّف غير موجود يُتجاهل', () {
      controller.select('ghost');
      expect(controller.hasSelection, isFalse);
    });

    test('إلغاء التحديد يعمل', () {
      controller.select('seal-1');
      controller.clearSelection();
      expect(controller.hasSelection, isFalse);
    });
  });

  group('السحب والتحجيم والتدوير', () {
    test('السحب يُزيح العنصر بمقدار الإزاحة', () {
      controller.select('text-1');
      controller.moveSelectedBy(40, 25, snap: false);

      final ElementBox box = controller.selected!.box;
      expect(box.x, closeTo(140, 0.001));
      expect(box.y, closeTo(125, 0.001));
    });

    test('السحب لا يُخرج العنصر من حدود الورقة', () {
      controller.select('seal-1');
      controller.moveSelectedBy(9999, 9999, snap: false);

      final ElementBox box = controller.selected!.box;
      expect(box.x, lessThanOrEqualTo(controller.designSize.width - box.width));
      expect(box.y, lessThanOrEqualTo(controller.designSize.height - box.height));
    });

    test('مغناطيس المحاذاة يثبّت العنصر عند مركز الورقة', () {
      final double centerX = (controller.designSize.width - 300) / 2;
      controller.select('text-1');
      // إزاحة تُقرّب الحد إلى المركز بمسافة أقل من حدّ الالتصاق.
      controller.moveSelectedBy(centerX - 100 + 2, 0);

      expect(controller.selected!.box.x, closeTo(centerX, 0.001));
    });

    test('التحجيم يضبط العرض والارتفاع', () {
      controller.select('seal-1');
      controller.setSelectedBox(
        const ElementBox(x: 500, y: 400, width: 200, height: 220),
      );

      expect(controller.selected!.box.width, 200);
      expect(controller.selected!.box.height, 220);
    });

    test('التحجيم لا يقبل حجماً أصغر من الحد الأدنى', () {
      controller.select('seal-1');
      controller.setSelectedBox(
        const ElementBox(x: 10, y: 10, width: 1, height: 1),
      );

      expect(
        controller.selected!.box.width,
        TemplateEditorController.minElementSize,
      );
      expect(
        controller.selected!.box.height,
        TemplateEditorController.minElementSize,
      );
    });

    test('التدوير يُطبَّع داخل ‎-180..180‎', () {
      controller.select('seal-1');
      controller.setSelectedRotation(200);
      expect(controller.selected!.rotation, closeTo(-160, 0.001));

      controller.setSelectedRotation(-200);
      expect(controller.selected!.rotation, closeTo(160, 0.001));
    });

    test('التدوير النسبي يُضاف إلى الزاوية الحالية', () {
      controller.select('seal-1');
      controller.setSelectedRotation(30);
      controller.rotateSelectedBy(15);
      expect(controller.selected!.rotation, closeTo(45, 0.001));
    });

    test('العنصر المُدوَّر يُحفظ دوره في JSON', () {
      controller.select('seal-1');
      controller.setSelectedRotation(35);

      final Map<String, dynamic> json = controller.document.toJson();
      final Map<String, dynamic> seal = (json['elements']! as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere((Map<String, dynamic> element) => element['id'] == 'seal-1');
      expect(seal['rotation'], 35);
    });
  });

  group('الإضافة والحذف والتكرار', () {
    test('إضافة عنصر تُدرجه في المستند وتُحدِّده', () {
      final TemplateElement added = controller.addElement(NewElementKind.text);

      expect(controller.document.elements.length, 3);
      expect(controller.selectedId, added.id);
    });

    test('قائمة المصنع تحتوي كل الأنواع المدعومة بلا تكرار معرّفات', () {
      final Set<String> ids = <String>{};
      for (final NewElementKind kind in NewElementKind.values) {
        ids.add(controller.addElement(kind).id);
      }
      expect(ids.length, NewElementKind.values.length);
      expect(
        controller.document.elements.length,
        NewElementKind.values.length + 2,
      );
    });

    test('الحذف يُزيل العنصر ويُلغي تحديده', () {
      controller.select('text-1');
      controller.deleteSelected();

      expect(controller.document.elements.length, 1);
      expect(controller.hasSelection, isFalse);
    });

    test('التكرار ينسخ العنصر بإزاحة وبمعرّف جديد', () {
      controller.select('text-1');
      controller.duplicateSelected();

      expect(controller.document.elements.length, 3);
      final TemplateElement copy = controller.selected!;
      expect(copy.id, isNot('text-1'));
      expect(copy.box.x, closeTo(118, 0.001));
      expect((copy as TextElement).text, 'مرحباً {{اسم_المتدرب}}');
    });

    test('ترتيب الرسم يتبدّل مع «إلى الأمام»', () {
      controller.select('text-1');
      controller.bringForward();

      expect(controller.document.elements.first.id, 'seal-1');
      expect(controller.document.elements.last.id, 'text-1');
    });

    test('ترتيب الرسم لا يتجاوز حدوده', () {
      List<String> ids() => controller.document.elements
          .map((TemplateElement element) => element.id)
          .toList(growable: false);

      // العنصر الأخير لا يمكن تمريره للأمام أكثر.
      controller.select('seal-1');
      controller.bringForward();
      expect(ids().last, 'seal-1');

      // العنصر الأول لا يمكن تمريره للخلف أكثر.
      controller.select('text-1');
      controller.sendBackward();
      expect(ids().first, 'text-1');
    });
  });

  group('خصائص النص والأصول', () {
    test('تعديل النص يُحدّث العنصر المحدد', () {
      controller.select('text-1');
      controller.updateText('نص محدّث');

      expect((controller.selected! as TextElement).text, 'نص محدّث');
    });

    test('إدراج حقل ديناميكي يُلحق الصيغة بالنص', () {
      controller.select('text-1');
      controller.insertFieldToken('{{اسم_الدورة}}');

      expect(
        (controller.selected! as TextElement).text,
        contains('{{اسم_الدورة}}'),
      );
    });

    test('إدراج حقل على عنصر غير نصي لا يُغيّر شيئاً', () {
      controller.select('seal-1');
      controller.insertFieldToken('{{التاريخ}}');

      expect(controller.selected, isA<SealElement>());
    });

    test('تحديث نمط النص يجمع كل الخصائص', () {
      controller.select('text-1');
      controller.updateTextStyle(
        family: PdfFontFamily.amiri,
        weight: PdfFontWeight.bold,
        fontSize: 42,
        colorHex: '#C7A26B',
        align: ElementTextAlign.center,
        direction: ElementDirection.ltr,
        letterSpacing: 1.5,
        lineHeight: 1.8,
      );

      final TextElement text = controller.selected! as TextElement;
      expect(text.family, PdfFontFamily.amiri);
      expect(text.weight, PdfFontWeight.bold);
      expect(text.fontSize, 42);
      expect(text.colorHex, '#C7A26B');
      expect(text.align, ElementTextAlign.center);
      expect(text.direction, ElementDirection.ltr);
      expect(text.letterSpacing, 1.5);
      expect(text.lineHeight, 1.8);
    });

    test('خلفية النص تُضاف وتُزال عبر null', () {
      controller.select('text-1');
      controller.updateTextStyle(backgroundHex: '#EEF1F6');
      expect((controller.selected! as TextElement).backgroundHex, '#EEF1F6');

      controller.updateTextStyle(backgroundHex: null);
      expect((controller.selected! as TextElement).backgroundHex, isNull);
    });

    test('الشفافية تُقيَّد بين 0 و1', () {
      controller.select('seal-1');
      controller.setSelectedOpacity(3);
      expect((controller.selected! as SealElement).opacity, 1);

      controller.setSelectedOpacity(-1);
      expect((controller.selected! as SealElement).opacity, 0);
    });

    test('ألوان الختم تُحدَّث كلها', () {
      controller.select('seal-1');
      controller.setSelectedSealColors(
        fillHex: '#000000',
        ringHex: '#FFFFFF',
        starHex: '#C7A26B',
        starRatio: 0.7,
      );

      final SealElement seal = controller.selected! as SealElement;
      expect(seal.fillHex, '#000000');
      expect(seal.ringHex, '#FFFFFF');
      expect(seal.starHex, '#C7A26B');
      expect(seal.starRatio, closeTo(0.7, 0.001));
    });

    test('تعديل خصائص نوع لا يطابق العنصر المحدد لا يُغيّر شيئاً', () {
      controller.select('seal-1');
      controller.setSelectedShapeStyle(fillHex: '#123456');

      expect(controller.selected, isA<SealElement>());
    });
  });

  group('تبديل اتجاه النص', () {
    test('يبدّل عربي ← لاتيني ويتكرّر ذهاباً وإياباً', () {
      controller.select('text-1');
      expect(
        (controller.selected! as TextElement).direction,
        ElementDirection.rtl,
      );

      expect(controller.toggleSelectedTextDirection(), ElementDirection.ltr);
      expect(
        (controller.selected! as TextElement).direction,
        ElementDirection.ltr,
      );

      expect(controller.toggleSelectedTextDirection(), ElementDirection.rtl);
      expect(
        (controller.selected! as TextElement).direction,
        ElementDirection.rtl,
      );
    });

    test('«auto» مع نص عربي يتحوّل إلى لاتيني (الاتجاه الفعلي أساس القرار)', () {
      controller.select('text-1');
      controller.updateTextStyle(direction: ElementDirection.auto);

      expect(controller.toggleSelectedTextDirection(), ElementDirection.ltr);
    });

    test('«auto» مع نص لاتيني يتحوّل إلى عربي', () {
      controller.select('text-1');
      controller.updateTextStyle(direction: ElementDirection.auto);
      controller.updateText('JoodCraft');

      expect(controller.toggleSelectedTextDirection(), ElementDirection.rtl);
    });

    test('لا يتأثّر عنصر غير نصي ويعيد null', () {
      controller.select('seal-1');
      expect(controller.toggleSelectedTextDirection(), isNull);
      expect(controller.selected, isA<SealElement>());
    });

    test('يُطبَّق على كل عناصر النص في التحديد الجماعي', () {
      controller.addElementInstance(
        const TextElement(
          id: 'text-2',
          box: ElementBox(x: 500, y: 100, width: 300, height: 80),
          text: 'الثاني',
        ),
      );
      // تحديد جماعي: العنصران النصيان معاً.
      controller.selectMany(<String>['text-1', 'text-2']);

      expect(controller.toggleSelectedTextDirection(), ElementDirection.ltr);
      for (final TemplateElement element in controller.document.elements) {
        if (element is TextElement) {
          expect(element.direction, ElementDirection.ltr, reason: element.id);
        }
      }
    });

    test('التبديل قابل للتراجع', () {
      controller.select('text-1');
      controller.toggleSelectedTextDirection();

      controller.undo();
      expect(
        (controller.selected! as TextElement).direction,
        ElementDirection.rtl,
      );
    });
  });

  group('طريقة الضبط (فراغات/كشيدة)', () {
    test('updateTextStyle يضبط طريقة الضبط', () {
      controller.select('text-1');
      controller.updateTextStyle(
        align: ElementTextAlign.justify,
        justifyMode: JustifyMode.kashida,
      );

      final TextElement text = controller.selected! as TextElement;
      expect(text.align, ElementTextAlign.justify);
      expect(text.justifyMode, JustifyMode.kashida);
    });
  });

  group('التراجع والإعادة', () {
    test('التراجع يُعيد الحالة السابقة', () {
      controller.select('text-1');
      controller.updateText('أ');
      controller.updateText('ب');

      expect((controller.selected! as TextElement).text, 'ب');
      controller.undo();
      expect((controller.selected! as TextElement).text, 'أ');
      controller.undo();
      expect((controller.selected! as TextElement).text, 'مرحباً {{اسم_المتدرب}}');
    });

    test('الإعادة تُطبّق التعديل الملغى', () {
      controller.select('text-1');
      controller.updateText('جديد');
      controller.undo();
      controller.redo();

      expect((controller.selected! as TextElement).text, 'جديد');
    });

    test('التعديل بعد التراجع يُفرغ مكدّس الإعادة', () {
      controller.select('text-1');
      controller.updateText('أ');
      controller.undo();
      expect(controller.canRedo, isTrue);

      controller.updateText('ب');
      expect(controller.canRedo, isFalse);
    });

    test('حركة سحب كاملة تُسجَّل في التراجع مرة واحدة', () {
      controller.select('text-1');
      controller.beginInteraction();
      for (int i = 0; i < 20; i++) {
        controller.moveSelectedBy(1, 1, snap: false);
      }
      controller.endInteraction();

      expect(controller.selected!.box.x, closeTo(120, 0.001));

      controller.undo();
      expect(controller.selected!.box.x, closeTo(100, 0.001));
      expect(controller.canUndo, isFalse);
    });

    test('لا تراجع بلا تعديلات', () {
      expect(controller.canUndo, isFalse);
      controller.undo();
      expect(controller.document.elements.length, 2);
    });

    test('حذف العنصر ثم التراجع يُعيده بلا تحديد', () {
      controller.select('seal-1');
      controller.deleteSelected();
      expect(controller.document.elements.length, 1);

      controller.undo();
      expect(controller.document.elements.length, 2);
      expect(controller.hasSelection, isFalse);
    });
  });

  group('النقل والحذف عبر اختصارات اللوحة', () {
    test('حذف تحديد جماعي ثم التراجع يُعيد الجميع في خطوة واحدة', () {
      controller.selectAll();
      controller.deleteSelected();
      expect(controller.document.elements, isEmpty);

      controller.undo();
      expect(controller.document.elements.length, 2);
    });

    test('الحذف ثم الإعادة (redo) يُعيد الحذف', () {
      controller.select('seal-1');
      controller.deleteSelected();
      expect(controller.document.elements.length, 1);

      controller.undo();
      expect(controller.document.elements.length, 2);

      controller.redo();
      expect(controller.document.elements.length, 1);
    });

    test('جلسة نقل واحدة (أسهم) تُسجَّل كخطوة تراجع واحدة', () {
      controller.select('text-1');
      controller.beginInteraction();
      controller.moveSelectedBy(1, 0, snap: false);
      controller.moveSelectedBy(1, 0, snap: false);
      controller.moveSelectedBy(10, 0, snap: false);
      controller.endInteraction();

      expect(controller.selected!.box.x, closeTo(112, 0.001));
      controller.undo();
      expect(controller.selected!.box.x, closeTo(100, 0.001));
      expect(controller.canUndo, isFalse);
    });

    test('ضغطات مستقلّة (جلسات متتالية) تتراجع خطوة بخطوة', () {
      controller.select('text-1');
      controller.beginInteraction();
      controller.moveSelectedBy(1, 0, snap: false);
      controller.endInteraction();
      controller.moveSelectedBy(1, 0, snap: false);

      expect(controller.selected!.box.x, closeTo(102, 0.001));
      controller.undo();
      expect(controller.selected!.box.x, closeTo(101, 0.001));
      controller.undo();
      expect(controller.selected!.box.x, closeTo(100, 0.001));
    });

    test('النقل بلا تحديد لا يُسجَّل في التاريخ', () {
      controller.moveSelectedBy(5, 5, snap: false);

      expect(controller.canUndo, isFalse);
      expect(controller.document.elements.length, 2);
    });

    test('الحذف بلا تحديد لا يُسجَّل في التاريخ', () {
      controller.deleteSelected();

      expect(controller.canUndo, isFalse);
      expect(controller.document.elements.length, 2);
    });
  });

  group('إعدادات الورقة', () {
    test('تغيير الاتجاه يُغيّر أبعاد الصفحة', () {
      final double before = controller.document.pageWidthPt;
      controller.setOrientation(PageOrientation.portrait);

      expect(controller.document.orientation, PageOrientation.portrait);
      expect(controller.document.pageWidthPt, lessThan(before));
    });

    test('تغيير المقاس والخلفية يُسجَّل', () {
      controller.setPaperSize(PaperSize.a5);
      controller.setBackgroundHex('#FFFDF7');

      expect(controller.document.paperSize, PaperSize.a5);
      expect(controller.document.backgroundHex, '#FFFDF7');
    });

    test('تحميل مستند جديد يُصفّر التحديد ويُعلّمه نظيفاً', () {
      controller.select('seal-1');
      controller.updateText('x');
      controller.loadDocument(document(), asClean: true);

      expect(controller.hasSelection, isFalse);
      expect(controller.hasUnsavedChanges, isFalse);
    });
  });

  group('الحفظ في Supabase', () {
    test('الحفظ بلا مستودع يرمي خطأ الإعداد', () async {
      expect(controller.canPersist, isFalse);
      await expectLater(
        controller.save(),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.code,
            'code',
            AppErrorCode.notConfigured,
          ),
        ),
      );
    });

    test('أول حفظ يُنشئ سجلاً ويُخزّن مخططه بإصدار صحيح', () async {
      final FakeTemplateRepository repository = FakeTemplateRepository();
      final TemplateEditorController writer = build(repository: repository);
      addTearDown(writer.dispose);

      final TemplateRecord record = await writer.save(title: 'شهادة الدورة');

      expect(repository.createCalls, 1);
      expect(record.title, 'شهادة الدورة');
      expect(record.category, TemplateCategory.certificate);
      expect(writer.recordId, record.id);
      expect(writer.hasUnsavedChanges, isFalse);
      expect(record.layoutData['schema_version'], AppConstants.layoutSchemaVersion);
      expect(record.orientation, PageOrientation.landscape);
    });

    test('الحفظ الثاني يُحدّث السجل نفسه بلا إنشاء جديد', () async {
      final FakeTemplateRepository repository = FakeTemplateRepository();
      final TemplateEditorController writer = build(repository: repository);
      addTearDown(writer.dispose);

      await writer.save(title: 'قالب');
      writer.select('text-1');
      writer.updateText('نص مُحدَّث');
      await writer.save();

      expect(repository.createCalls, 1);
      expect(repository.updateCalls, 1);
      expect(repository.records.length, 1);
    });

    test('عنوان فارغ يُستبدل بعنوان افتراضي', () async {
      final FakeTemplateRepository repository = FakeTemplateRepository();
      final TemplateEditorController writer = build(repository: repository);
      addTearDown(writer.dispose);

      final TemplateRecord record = await writer.save(title: '   ');
      expect(record.title, 'قالب بلا عنوان');
    });

    test('الدوران يبقى محفوظاً بعد دورة حفظ/استرجاع', () async {
      final FakeTemplateRepository repository = FakeTemplateRepository();
      final TemplateEditorController writer = build(repository: repository);
      addTearDown(writer.dispose);

      writer.select('seal-1');
      writer.setSelectedRotation(42);
      final TemplateRecord record = await writer.save(title: 'قالب مُدوَّر');

      final TemplateDocument restored = record.toDocument();
      final SealElement seal = restored.elements
          .whereType<SealElement>()
          .first;
      expect(seal.rotation, closeTo(42, 0.001));
    });

    test('فشل الحفظ يرمي خطأً عربياً ويُبقي التعديلات غير محفوظة', () async {
      final FakeTemplateRepository repository = FakeTemplateRepository()
        ..failWith = AppErrorCode.permissionDenied;
      final TemplateEditorController writer = build(repository: repository);
      addTearDown(writer.dispose);

      await expectLater(
        writer.save(),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.message,
            'message',
            AppErrorCode.permissionDenied.messageAr,
          ),
        ),
      );
      expect(writer.isSaving, isFalse);
    });

    test('رسالة النجاح تُعرض مرة واحدة ثم تُمسح', () async {
      final FakeTemplateRepository repository = FakeTemplateRepository();
      final TemplateEditorController writer = build(repository: repository);
      addTearDown(writer.dispose);

      await writer.save(title: 'قالب');
      expect(writer.statusMessage, contains('تم حفظ القالب'));

      writer.clearStatusMessage();
      expect(writer.statusMessage, isNull);
    });
  });

  group('مكتبة القوالب', () {
    test('بلا مستودع تبقى المكتبة أوفلاين بلا خطأ (قوالب جاهزة)', () async {
      final TemplateLibraryController library = TemplateLibraryController(null);
      await library.refresh();

      expect(library.isAvailable, isFalse);
      // لم تعد المكتبة تشترط الاتصال: القوالب الجاهزة متاحة دائماً.
      expect(library.errorMessage, isNull);
      expect(library.entries, isNotEmpty);
    });

    test('الحفظ يُحدّث القائمة مباشرة بلا طلب إضافي', () async {
      final FakeTemplateRepository repository = FakeTemplateRepository();
      final TemplateLibraryController library =
          TemplateLibraryController(repository);

      await library.save(
        title: 'قالب أول',
        category: TemplateCategory.certificate,
        orientation: PageOrientation.landscape,
        layoutData: document().toJson(),
      );
      await library.save(
        title: 'قالب ثانٍ',
        category: TemplateCategory.contract,
        orientation: PageOrientation.portrait,
        layoutData: document().toJson(),
      );

      expect(library.templates.length, 2);
      expect(repository.createCalls, 2);

      // التحديث يُعيد الترتيب من الخادم (الأحدث أولاً).
      await library.refresh();
      expect(library.templates.first.title, 'قالب ثانٍ');
      expect(library.errorMessage, isNull);
    });

    test('الحذف يُزيل القالب من القائمة', () async {
      final FakeTemplateRepository repository = FakeTemplateRepository();
      final TemplateLibraryController library =
          TemplateLibraryController(repository);

      final TemplateRecord record = await library.save(
        title: 'للحذف',
        category: TemplateCategory.certificate,
        orientation: PageOrientation.landscape,
        layoutData: document().toJson(),
      );
      await library.remove(record.id);

      expect(library.templates, isEmpty);
      expect(repository.deleteCalls, 1);
    });

    test('فشل التحميل يُترجم إلى رسالة عربية', () async {
      final FakeTemplateRepository repository = FakeTemplateRepository()
        ..failWith = AppErrorCode.network;
      final TemplateLibraryController library =
          TemplateLibraryController(repository);

      await library.refresh();
      expect(library.errorMessage, AppErrorCode.network.messageAr);
      expect(library.isBusy, isFalse);
    });
  });

  group('هندسة اللوحة', () {
    test('الملاءمة تحفظ نِسب الورقة وتُركزها', () {
      const Size design = Size(1122.52, 793.7);
      final CanvasGeometry geometry = CanvasGeometry.fit(
        viewport: const Size(800, 600),
        design: design,
      );

      expect(geometry.scale, greaterThan(0));
      expect(design.width * geometry.scale, lessThanOrEqualTo(800));
      expect(design.height * geometry.scale, lessThanOrEqualTo(600));
      expect(geometry.toDesign(geometry.toScreen(const Offset(50, 60))).dx,
          closeTo(50, 0.001));
    });

    test('التصغير/التكبير يضرب المعامل', () {
      final CanvasGeometry base = CanvasGeometry.fit(
        viewport: const Size(800, 600),
        design: const Size(1122.52, 793.7),
      );
      expect(base.zoomed(2).scale, closeTo(base.scale * 2, 0.0001));
    });

    test('المغناطيس يلتقط حافة الورقة من مسافة قريبة فقط', () {
      const Size design = Size(1000, 600);
      final ElementBox near = ElementSnapper.snap(
        box: const ElementBox(x: 3, y: 200, width: 100, height: 50),
        design: design,
      );
      expect(near.x, 0);

      final ElementBox far = ElementSnapper.snap(
        box: const ElementBox(x: 40, y: 200, width: 100, height: 50),
        design: design,
      );
      expect(far.x, 40);
    });
  });

  // -------------------------------------------------------------------------
  //  تلوين الصورة المحددة
  // -------------------------------------------------------------------------
  group('تلوين الصورة المحددة', () {
    TemplateEditorController withImage({String? tintHex}) {
      final TemplateEditorController tintedController =
          TemplateEditorController(
        document: TemplateDocument(
          orientation: PageOrientation.landscape,
          elements: <TemplateElement>[
            ImageElement(
              id: 'img-1',
              box: const ElementBox(x: 100, y: 100, width: 200, height: 100),
              sourceKind: ImageSourceKind.dataUri,
              path: 'AAAA',
              tintHex: tintHex,
            ),
          ],
        ),
        category: TemplateCategory.certificate,
      );
      addTearDown(tintedController.dispose);
      tintedController.select('img-1');
      return tintedController;
    }

    test('ضبط اللون يُحدّث العنصر ويُحفظ في JSON', () {
      final TemplateEditorController subject = withImage();

      subject.setSelectedImageTint('#C7A26B');

      final ImageElement updated = subject.selected! as ImageElement;
      expect(updated.tintHex, '#C7A26B');
      expect(updated.tintedImageKey, 'data:AAAA#c7a26b');
      expect(subject.document.elements.single.toJson()['tint'], '#C7A26B');
    });

    test('إزالة اللون تُعيد البكسلات الأصلية', () {
      final TemplateEditorController subject = withImage(tintHex: '#FF0000');

      subject.clearSelectedImageTint();

      expect((subject.selected! as ImageElement).tintHex, isNull);
      expect(
        subject.document.elements.single.toJson().containsKey('tint'),
        isFalse,
      );
    });

    test('لون فارغ أو مسافات يُعامَل كإزالة للتلوين', () {
      final TemplateEditorController subject = withImage(tintHex: '#FF0000');

      subject.setSelectedImageTint('   ');

      expect((subject.selected! as ImageElement).tintHex, isNull);
    });

    test('لا يُسجَّل تعديل حين لا تتغيّر القيمة فعلاً', () {
      final TemplateEditorController same = withImage(tintHex: '#FF0000');
      final TemplateEditorController clear = withImage();

      same.setSelectedImageTint('#FF0000'); // نفس اللون
      clear.clearSelectedImageTint(); // لا لون أصلاً

      expect(same.hasUnsavedChanges, isFalse, reason: 'لا خطوة تراجع زائفة.');
      expect(clear.hasUnsavedChanges, isFalse, reason: 'لا خطوة تراجع زائفة.');
    });
  });
}
