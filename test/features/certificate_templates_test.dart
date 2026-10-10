import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/constants/dynamic_fields.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/templates/preset_catalog.dart';
import 'package:joodcraft/core/templates/preset_template.dart';
import 'package:joodcraft/core/templates/preset_ui_text.dart';
import 'package:joodcraft/core/templates/royal_gold_gallery.dart';
import 'package:joodcraft/core/templates/template_draft.dart';
import 'package:joodcraft/core/templates/template_record.dart';

/// اختبارات **مجموعة «ستايل الكحلي/الذهبي»**: 6 قوالب شهادة بلوحة ألوان موحّدة
/// (كحلي `#0F1B3C` + ذهبي `#C9A961` + نص أبيض) على A4 أفقي، بتصميمات مختلفة.
///
/// تحرس هذه الاختبارات:
/// * التسجيل في الفهرس وعدم تكرار المعرّفات.
/// * مواصفة A4 الأفقي والتصنيف «شهادات تقدير».
/// * وجود الحقول الديناميكية والتحقق من قيمها التجريبية.
/// * مطابقة لوحة الألوان المرجعية (خلفية كحلية + عنصر ذهبي + ختم).
/// * التجاوب: بقاء العناصر داخل الورقة بعد تبديل الاتجاه/المقاس.
/// * وجود مفاتيح الترجمة `tplCert*` في كل اللغات العشر عبر `PresetUiText`.
void main() {
  const List<String> royalIds = <String>[
    'classic_navy_gold_certificate',
    'minimal_navy_gold_certificate',
    'islamic_ornament_navy_gold_certificate',
    'gold_band_navy_certificate',
    'dynamic_diagonal_navy_gold_certificate',
    'square_elegant_navy_gold_certificate',
  ];

  const List<String> locales = <String>[
    'ar',
    'en',
    'fr',
    'es',
    'tr',
    'ur',
    'de',
    'id',
    'ru',
    'zh',
  ];

  /// ألوان اللوحة المرجعية كما تُستخدم في باني المجموعة.
  const String navy = RoyalGoldGallery.navy;
  const String gold = RoyalGoldGallery.gold;

  /// قوالب المجموعة الستة مستخرجةً من الفهرس (تتحقق من التسجيل فعلياً).
  final List<PresetTemplate> presets = PresetCatalog.all
      .where((PresetTemplate p) => royalIds.contains(p.id))
      .toList(growable: false);

  group('التسجيل والهوية', () {
    test('القوالبة الستة موجودة في الفهرس', () {
      for (final String id in royalIds) {
        expect(PresetCatalog.byId(id), isNotNull, reason: 'القالب $id مفقود');
      }
    });

    test('لا معرّفات مكرّرة في الفهرس كلّه', () {
      final Set<String> ids = PresetCatalog.all.map((PresetTemplate p) => p.id).toSet();
      expect(ids.length, PresetCatalog.all.length);
    });

    test('عدد قوالب المجموعة ستة بالضبط', () {
      expect(RoyalGoldGallery.presets.length, 6);
      expect(presets.length, 6);
    });

    test('كلها شهادات تقدير على A4 أفقي', () {
      for (final PresetTemplate preset in presets) {
        expect(preset.category, TemplateCategory.certificate, reason: preset.id);
        expect(preset.collection, TemplateCollection.appreciation,
            reason: preset.id);
        expect(preset.orientation, PageOrientation.landscape,
            reason: preset.id);
        final TemplateDocument document = preset.document;
        expect(document.paperSize, PaperSize.a4, reason: preset.id);
        expect(document.orientation, PageOrientation.landscape,
            reason: preset.id);
      }
    });

    test('لكل قالب عنوان ووصف ووسوم عربية غير فارغة', () {
      for (final PresetTemplate preset in presets) {
        expect(preset.titleAr.trim(), isNotEmpty, reason: preset.id);
        expect(preset.descriptionAr.trim(), isNotEmpty, reason: preset.id);
        expect(preset.tags, isNotEmpty, reason: preset.id);
        for (final String tag in preset.tags) {
          expect(tag.trim(), isNotEmpty, reason: '${preset.id}: وسم فارغ');
        }
      }
    });

    test('العناوين الستة مختلفة بعضها عن بعض', () {
      final Set<String> titles = presets.map((PresetTemplate p) => p.titleAr).toSet();
      expect(titles.length, presets.length);
    });
  });

  group('الحقول الديناميكية والقيم التجريبية', () {
    test('كل قالب يحمل حقولاً معروفة ولها قيم تجريبية', () {
      final Set<String> known = <String>{
        for (final DynamicField field in DynamicFields.all) field.key,
      };
      for (final PresetTemplate preset in presets) {
        final TemplateDocument document = preset.document;
        expect(document.fieldKeys, isNotEmpty, reason: preset.id);
        expect(document.fieldKeys.difference(known), isEmpty,
            reason: '${preset.id}: مفاتيح مجهولة');
        for (final String key in document.fieldKeys) {
          expect(document.sampleData[key]?.trim(), isNotEmpty,
              reason: '${preset.id}: قيمة تجريبية ناقصة للحقل $key');
        }
      }
    });

    test('كل قالب يحوي حقلي الاسم والتاريخ', () {
      for (final PresetTemplate preset in presets) {
        final TemplateDocument document = preset.document;
        expect(document.fieldKeys, contains('اسم_المتدرب'), reason: preset.id);
        expect(document.fieldKeys, contains('التاريخ'), reason: preset.id);
      }
    });

    test('قابلية الرسم: كل عنصر غير مجهول وداخل صفحة التصميم', () {
      for (final PresetTemplate preset in presets) {
        final TemplateDocument document = preset.document;
        expect(document.drawableElementCount, greaterThan(0),
            reason: preset.id);
        for (final TemplateElement element in document.elements) {
          expect(element, isNot(isA<UnknownElement>()), reason: preset.id);
          expect(element.box.width, greaterThanOrEqualTo(0),
              reason: '${preset.id}/${element.id}: عرض سالب');
          expect(element.box.height, greaterThanOrEqualTo(0),
              reason: '${preset.id}/${element.id}: ارتفاع سالب');
        }
      }
    });
  });

  group('لوحة الألوان الموحّدة', () {
    test('خلفية كل القوالبة كحلية داكنة', () {
      for (final PresetTemplate preset in presets) {
        expect(preset.document.backgroundHex.toUpperCase(), navy.toUpperCase(),
            reason: preset.id);
      }
    });

    test('كل قالب يحوي عنصراً ذهبياً وختماً دائرياً', () {
      for (final PresetTemplate preset in presets) {
        final List<TemplateElement> elements = preset.document.elements;

        final bool hasGold = elements.any((TemplateElement e) =>
            (e is ShapeElement && e.fillHex?.toUpperCase() == gold.toUpperCase()) ||
            (e is ShapeElement && e.strokeHex?.toUpperCase() == gold.toUpperCase()) ||
            (e is TextElement && e.colorHex.toUpperCase() == gold.toUpperCase()) ||
            (e is SealElement && e.fillHex.toUpperCase() == gold.toUpperCase()));

        expect(hasGold, isTrue, reason: '${preset.id}: لا عنصر ذهبي');

        final bool hasSeal = elements.any((TemplateElement e) => e is SealElement);
        expect(hasSeal, isTrue, reason: '${preset.id}: لا ختم دائري');
      }
    });

    test('النص الرئيسي أبيض في كل القوالبة', () {
      for (final PresetTemplate preset in presets) {
        final List<TemplateElement> elements = preset.document.elements;
        expect(
          elements.any((TemplateElement e) =>
              e is TextElement &&
              e.text.contains('{{') &&
              e.colorHex.toUpperCase() == '#FFFFFF'),
          isTrue,
          reason: '${preset.id}: لا نص أبيض',
        );
      }
    });

    test('ثوابت اللوحة تطابق المواصفة المطلوبة', () {
      expect(RoyalGoldGallery.navy.toUpperCase(), '#0F1B3C');
      expect(RoyalGoldGallery.gold.toUpperCase(), '#C9A961');
      expect(RoyalGoldGallery.white.toUpperCase(), '#FFFFFF');
    });
  });

  group('الترجمة (tplCert*) في عشر لغات', () {
    test(' عنوان ووصف كل قالب مترجمان في كل لغة', () {
      for (final String locale in locales) {
        for (final PresetTemplate preset in presets) {
          final String? title = PresetUiText.title(locale, preset.id);
          final String? description = PresetUiText.description(locale, preset.id);

          expect(title, isNotNull,
              reason: '$locale: عنوان ${preset.id} مفقود من ARB');
          expect(description, isNotNull,
              reason: '$locale: وصف ${preset.id} مفقود من ARB');

          expect(title!.trim(), isNotEmpty);
          expect(description!.trim(), isNotEmpty);
          expect(title, isNot(preset.id));
          expect(description, isNot(preset.id));
        }
      }
    });

    test('العربية تعيد العنوان العربي نفسه', () {
      for (final PresetTemplate preset in presets) {
        expect(PresetUiText.title('ar', preset.id), preset.titleAr,
            reason: preset.id);
        expect(PresetUiText.description('ar', preset.id), preset.descriptionAr,
            reason: preset.id);
      }
    });

    test('titleFor يفضّل مفتاح ARB على النصّ العربي', () {
      for (final PresetTemplate preset in presets) {
        expect(preset.titleFor('en'), PresetUiText.title('en', preset.id));
        expect(preset.titleFor('en'), isNot(preset.titleAr));
        // بلا لغة ⇒ الرجوع إلى العنوان العربي.
        expect(preset.titleFor(null), preset.titleAr);
      }
    });

    test('لغة غير مدعومة ترجع إلى العربية بلا انهيار', () {
      for (final PresetTemplate preset in presets) {
        expect(PresetUiText.title('ja', preset.id), preset.titleAr);
      }
    });
  });

  group('التجاوب: بقاء العناصر داخل الورقة', () {
    test('التبديل إلى رأسي لا يخرج العناصر', () {
      for (final PresetTemplate preset in presets) {
        final TemplateDocument portrait =
            preset.document.refit(orientation: PageOrientation.portrait);
        expect(portrait.orientation, PageOrientation.portrait);
        for (final TemplateElement element in portrait.elements) {
          final Rect rect = portrait.boxToPdfRect(element.box);
          expect(rect.left, greaterThanOrEqualTo(-0.6),
              reason: '${preset.id}/${element.id}: left');
          expect(rect.top, greaterThanOrEqualTo(-0.6),
              reason: '${preset.id}/${element.id}: top');
          expect(rect.right, lessThanOrEqualTo(portrait.pageWidthPt + 0.6),
              reason: '${preset.id}/${element.id}: right');
          expect(rect.bottom, lessThanOrEqualTo(portrait.pageHeightPt + 0.6),
              reason: '${preset.id}/${element.id}: bottom');
        }
      }
    });

    test('تبديل المقاس إلى A5 يحجّم المساحة ولا يخرج العناصر', () {
      for (final PresetTemplate preset in presets) {
        final TemplateDocument a5 = preset.document.refit(paperSize: PaperSize.a5);
        expect(a5.designWidth, lessThan(preset.document.designWidth));
        for (final TemplateElement element in a5.elements) {
          final Rect rect = a5.boxToPdfRect(element.box);
          expect(rect.right, lessThanOrEqualTo(a5.pageWidthPt + 0.6),
              reason: '${preset.id}/${element.id}: right');
          expect(rect.bottom, lessThanOrEqualTo(a5.pageHeightPt + 0.6),
              reason: '${preset.id}/${element.id}: bottom');
        }
      }
    });
  });

  group('التحويل إلى سجل', () {
    test('تحويل قالب إلى سجل يحفظ المخطط ووسم المصدر', () {
      for (final PresetTemplate preset in presets) {
        final TemplateRecord record = preset.toRecord();
        expect(record.id, 'preset:${preset.id}');
        expect(record.userId, PresetTemplate.presetUserId);
        expect(record.layoutData['schema_version'],
            AppConstants.layoutSchemaVersion);
        expect(record.toDocument().drawableElementCount, greaterThan(0),
            reason: preset.id);
      }
    });

    test('فتح القالب في المحرّر يعطي مسودة بعنوان مترجم', () {
      for (final PresetTemplate preset in presets) {
        final TemplateDraft draft = preset.toDraft(languageCode: 'en');
        expect(draft.category, TemplateCategory.certificate);
        expect(draft.title, isNot(preset.titleAr));
        expect(draft.document.drawableElementCount, greaterThan(0));
      }
    });
  });
}
