import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/constants/dynamic_fields.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/templates/preset_catalog.dart';
import 'package:joodcraft/core/templates/preset_template.dart';

/// اختبارات **معرض الشهادات الموسّع** (§3): مكتبة الشهادات تصل إلى 20 تصميماً
/// موزّعة على أربع عائلات أسلوبية، وكلها قابلة للتجاوب (إعادة التخطيط) عند
/// تبديل الاتجاه أو المقاس بلا خروج عن حدود الصفحة.
void main() {
  group('عرض 20 قالب شهادة', () {
    test('معرّفات المعرض الجديدة كلها مسجّلة', () {
      const List<String> galleryIds = <String>[
        'royal_navy_gold_certificate',
        'burgundy_laurel_certificate',
        'imperial_medallion_certificate',
        'minimal_pastel_certificate',
        'geometric_blue_certificate',
        'soft_gradient_certificate',
        'corporate_official_certificate',
        'executive_blue_certificate',
        'corporate_grey_badge_certificate',
        'academic_seal_certificate',
        'appreciation_elegant_certificate',
        'academic_honors_certificate',
      ];
      for (final String id in galleryIds) {
        expect(PresetCatalog.byId(id), isNotNull, reason: 'القالب $id مفقود');
      }
    });

    test('عدد قوالب الشهادات صار 20 على الأقل بمعرّفات فريدة', () {
      final List<PresetTemplate> certificates = PresetCatalog.certificates;
      expect(certificates.length, greaterThanOrEqualTo(20));
      expect(
        certificates.map((PresetTemplate p) => p.id).toSet().length,
        certificates.length,
      );
      for (final PresetTemplate preset in certificates) {
        expect(preset.category, TemplateCategory.certificate);
        // الاتجاه المعلن يطابق حمولة المستند فعلاً.
        expect(preset.document.orientation, preset.orientation,
            reason: preset.id);
      }
      // أغلب الشهادات أفقية (تبقى الإفادة رأسية بخلاف ذلك).
      final int landscape = certificates
          .where((PresetTemplate p) => p.orientation == PageOrientation.landscape)
          .length;
      expect(landscape, greaterThanOrEqualTo(19));
    });

    test('العائلات الأربع مغطّاة: كلاسيكي/مينيمال/مؤسسي/أكاديمي', () {
      final List<String> tags = <String>[
        for (final PresetTemplate preset in PresetCatalog.certificates)
          ...preset.tags,
      ];
      bool has(String needle) => tags.any((String tag) => tag.contains(needle));
      expect(has('ملكي') || has('كلاسيكي'), isTrue);
      expect(has('مينيمال') || has('عصري') || has('حديث'), isTrue);
      expect(has('مؤسسي') || has('رسمي'), isTrue);
      expect(has('أكاديمي') || has('تقدير'), isTrue);
    });

    test('كل شهادة لها عناصر وحقول ديناميكية معروفة بقيم تجريبية', () {
      final Set<String> known = <String>{
        for (final DynamicField field in DynamicFields.all) field.key,
      };
      for (final PresetTemplate preset in PresetCatalog.certificates) {
        final TemplateDocument document = preset.document;
        expect(document.drawableElementCount, greaterThan(0),
            reason: preset.id);
        expect(document.fieldKeys.difference(known), isEmpty,
            reason: '${preset.id}: مفاتيح مجهولة');
        for (final String key in document.fieldKeys) {
          expect(document.sampleData[key]?.trim(), isNotEmpty,
              reason: '${preset.id}: قيمة تجريبية ناقصة للحقل $key');
        }
      }
    });
  });

  group('التجاوب: كل شهادة تُعاد تخطيطها بلا خروج عن الحدود (§2+§3)', () {
    test('التبديل إلى رأسي يبقي كل العناصر داخل الورقة', () {
      for (final PresetTemplate preset in PresetCatalog.certificates) {
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

    test('تبديل المقاس إلى A5 يحجّم مساحة التصميم ولا يخرج العناصر', () {
      for (final PresetTemplate preset in PresetCatalog.certificates) {
        final TemplateDocument a5 = preset.document.refit(paperSize: PaperSize.a5);
        expect(a5.designWidth, lessThan(preset.document.designWidth));
        for (final TemplateElement element in a5.elements) {
          final Rect rect = a5.boxToPdfRect(element.box);
          expect(rect.right, lessThanOrEqualTo(a5.pageWidthPt + 0.6),
              reason: '${preset.id}/${element.id}');
          expect(rect.bottom, lessThanOrEqualTo(a5.pageHeightPt + 0.6),
              reason: '${preset.id}/${element.id}');
        }
      }
    });
  });
}
