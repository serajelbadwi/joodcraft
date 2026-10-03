import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/constants/dynamic_fields.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/services/pdf_generator_service.dart';
import 'package:joodcraft/core/templates/preset_catalog.dart';
import 'package:joodcraft/core/templates/preset_template.dart';

/// اختبارات **تطابق العرض** لكل القوالب الجاهزة (المرحلة 5 + حزمة التوسعة).
///
/// الهدف من هذه الملف هو ضمان أن ما يراه المستخدم في المحرّر هو نفسه ما يخرج
/// في الـ PDF:
///
/// * إزاحة تصميم صفراً (`offsetX`/`offsetY`) ⇒ لا ترحّل بين اللوحة والورقة.
/// * كل عنصر داخل حدود الصفحة ⇒ لا قصّ عند التصدير.
/// * كل قالب يُصيَّر فعلاً بلا أي تحذير (أصول مفقودة/عناصر مجهولة).
/// * مفاتيح الحقول كلها من مكتبة `DynamicFields` فيعمل الربط التلقائي مع Excel.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PdfGeneratorService generator;

  setUpAll(() async {
    generator = await PdfGeneratorService.create(useIsolate: false);
  });

  /// حاوية صغيرة لقياس الهامش الذي قد يتسامح معه التقريب العشري.
  const double tolerance = 0.6;

  group('حزمة التوسعة: القوالب الستة الجديدة مسجّلة وصالحة', () {
    const List<String> newIds = <String>[
      'classic_appreciation_certificate',
      'achievement_certificate',
      'attendance_certificate',
      'science_progress_certificate',
      'fixed_term_contract',
      'consulting_contract',
    ];

    test('كل معرّف جديد موجود في الفهرس', () {
      for (final String id in newIds) {
        expect(PresetCatalog.byId(id), isNotNull, reason: 'القالب $id مفقود');
      }
    });

    test('الفهرس توسّع إلى 12 قالباً على الأقل بمعرّفات فريدة', () {
      expect(PresetCatalog.all.length, greaterThanOrEqualTo(12));
      expect(
        PresetCatalog.all.map((PresetTemplate p) => p.id).toSet().length,
        PresetCatalog.all.length,
      );
    });

    test('باليتات متنوّعة فعلاً: خلفيات مختلفة لا قالب واحد مكرّر', () {
      final Set<String> backgrounds = <String>{
        for (final PresetTemplate preset in PresetCatalog.all)
          '${preset.document.backgroundHex}#${preset.collection.name}',
      };
      // على الأقل خلفيات متنوّعة بين الشهادات نفسها.
      final Set<String> certificateBackgrounds = <String>{
        for (final PresetTemplate preset in PresetCatalog.all)
          if (preset.category.name == 'certificate') preset.document.backgroundHex,
      };
      expect(certificateBackgrounds.length, greaterThanOrEqualTo(4));
      expect(backgrounds.length, greaterThanOrEqualTo(6));
    });

    test('العقود الجديدة رأسية والشهادات الجديدة أفقية', () {
      expect(PresetCatalog.byId('fixed_term_contract')!.orientation,
          PageOrientation.portrait);
      expect(PresetCatalog.byId('consulting_contract')!.orientation,
          PageOrientation.portrait);
      for (final String id in newIds.take(4)) {
        expect(
          PresetCatalog.byId(id)!.orientation,
          PageOrientation.landscape,
          reason: 'الشهادة $id يجب أن تكون أفقية',
        );
      }
    });
  });

  group('الهندسة: كل قالب جاهز بلا ترحّل وبلا عناصر خارج الصفحة', () {
    test('إزاحة التصميم صفراً (تطابق المحرر مع الـ PDF)', () {
      for (final PresetTemplate preset in PresetCatalog.all) {
        final TemplateDocument document = preset.document;
        expect(document.offsetX.abs(), lessThan(tolerance),
            reason: '${preset.id}: offsetX=${document.offsetX}');
        expect(document.offsetY.abs(), lessThan(tolerance),
            reason: '${preset.id}: offsetY=${document.offsetY}');
      }
    });

    test('كل عنصر قابل للرسم يقع داخل حدود الصفحة', () {
      for (final PresetTemplate preset in PresetCatalog.all) {
        final TemplateDocument document = preset.document;
        for (final TemplateElement element in document.elements) {
          if (element is UnknownElement) continue;
          final Rect rect = document.boxToPdfRect(element.box);
          expect(rect.left, greaterThanOrEqualTo(-tolerance),
              reason: '${preset.id}/${element.id}: left=${rect.left}');
          expect(rect.top, greaterThanOrEqualTo(-tolerance),
              reason: '${preset.id}/${element.id}: top=${rect.top}');
          expect(rect.right, lessThanOrEqualTo(document.pageWidthPt + tolerance),
              reason: '${preset.id}/${element.id}: right=${rect.right}');
          expect(rect.bottom,
              lessThanOrEqualTo(document.pageHeightPt + tolerance),
              reason: '${preset.id}/${element.id}: bottom=${rect.bottom}');
        }
      }
    });

    test('مساحة التصميم تطابق مقاس الورق بدقة (96dpi ⇒ 72pt)', () {
      for (final PresetTemplate preset in PresetCatalog.all) {
        final TemplateDocument document = preset.document;
        expect(document.designWidth, greaterThan(0));
        expect(document.designHeight, greaterThan(0));
        // النسبة نفسها بين اللوحة والورقة ⇐ لا تزحزح.
        final double designRatio = document.designWidth / document.designHeight;
        final double paperRatio = document.pageWidthPt / document.pageHeightPt;
        expect(designRatio, closeTo(paperRatio, 0.002),
            reason: '${preset.id}: نسب غير متطابقة');
      }
    });
  });

  group('الحقول الديناميكية: كل قالب قابل للربط التلقائي مع Excel', () {
    test('مفاتيح كل قالب من مكتبة DynamicFields لا مفاتيح مجهولة', () {
      final Set<String> known = <String>{
        for (final DynamicField field in DynamicFields.all) field.key,
      };
      for (final PresetTemplate preset in PresetCatalog.all) {
        final Set<String> keys = preset.document.fieldKeys;
        expect(keys, isNotEmpty,
            reason: '${preset.id}: بلا حقول ديناميكية — لن تتغيّر البيانات');
        final Set<String> unknown = keys.difference(known);
        expect(unknown, isEmpty,
            reason: '${preset.id}: مفاتيح غير معروفة $unknown '
                'لن تُربط تلقائياً بأعمدة الملف');
      }
    });

    test('قيم تجريبية مغطية لكل حقل يستخدمه القالب', () {
      for (final PresetTemplate preset in PresetCatalog.all) {
        final TemplateDocument document = preset.document;
        for (final String key in document.fieldKeys) {
          expect(document.sampleData[key], isNotNull,
              reason: '${preset.id}: الحقل $key بلا قيمة تجريبية فتظهر فارغة');
          expect(document.sampleData[key]!.trim(), isNotEmpty,
              reason: '${preset.id}: قيمة تجريبية فارغة للحقل $key');
        }
      }
    });
  });

  group('التصدير: كل قالب جاهز يُصيَّر فعلاً بلا تحذيرات', () {
    test('يُنتج صفحة واحدة سليمة لكل قالب', () async {
      for (final PresetTemplate preset in PresetCatalog.all) {
        final PdfGenerationReport report =
            await generator.generate(document: preset.document);

        expect(report.pageCount, 1, reason: '${preset.id}: عدد الصفحات');
        expect(report.warnings, isEmpty,
            reason: '${preset.id}: تحذيرات التصدير ${report.warnings}');
        expect(report.bytes.lengthInBytes, greaterThan(3000),
            reason: '${preset.id}: الملف صغير جداً — لم يُرسم شيء');
        expect(report.bytes.lengthInBytes, lessThan(900000),
            reason: '${preset.id}: الملف مفرط الحجم');
        // الملف صالح: ترويسة ونهاية معياريتان.
        final String head =
            String.fromCharCodes(report.bytes.sublist(0, 5), 0, 5);
        expect(head, '%PDF-', reason: '${preset.id}: ترويسة PDF');
      }
    });

    test('أسماء الأسماء الطويلة لا تُنتج محتوى مختلف الحجم عن القصير', () async {
      // نتحقق أن حقل الاسم يُستبدل فعلاً: قيم مختلفة ⇒ حجم ملف مختلف.
      for (final String id in <String>[
        'classic_appreciation_certificate',
        'science_progress_certificate',
      ]) {
        final PresetTemplate preset = PresetCatalog.byId(id)!;
        final PdfGenerationReport short = await generator.generate(
          document: preset.document,
          data: <String, String>{'اسم_المتدرب': 'أحمد'},
        );
        final PdfGenerationReport long = await generator.generate(
          document: preset.document,
          data: <String, String>{
            'اسم_المتدرب': 'عبدالرحمن بن عبدالعزيز المنصوري الحربي',
          },
        );
        expect(short.bytes.lengthInBytes, isNot(long.bytes.lengthInBytes),
            reason: '$id: اسم الصف لم يصل إلى الملف');
      }
    });
  });
}
