/// حماية النصّ الديني من المعالج اللاحق.
///
/// ما يُقيَس هنا أخطاءٌ **وُجدت فعلاً** في القياس على ‎10‎ صور، لا مخاوف
/// نظرية: المعالج نفسه كان يُفسد قراءةً سليمةً قبل أن يُصلحها.
///
/// 1. **أقواس الشرف تُبتلع من القاموس.** المحرّك يلصق `﴾` بالكلمة
///    (`السيئة﴾`)، فتدخل النواةَ فتغيب عن المعجم ثمّ يُوجد منها على مسافة
///    حذفٍ واحدة فتُحذف. وكان الناتج `﴿آية [سورة: ١]` بدل `﴿آية﴾ [سورة: ١]`.
///
/// 2. **مفردات التنزيل تُبدَل بصنيع الويب.** قائمة التكرار مأخوذة من نصوص
///    ويب، فتنقصها `رحمن` و`رحيم`. وتُعدّ مجهولةً ثمّ يُوجد لها على مسافة
///    تبديلٍ واحدة `رحمة` و`جحيم` — فتخرج الآية `رب العالمين الرحمة الجحيم`.
///
/// والعلاجان مقيسان قبلَ وبعدَ في هذا الاختبار، لا مُفترَيان.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/ocr/data/text_post_processor.dart';

void main() {
  group('الأقواس المزخرفة تحمى من المعجم', () {
    test('مغلقٌ ملتصق بكلمة لا يُحذف في التصحيح', () {
      const String raw = 'قال تعالى: ﴿الآية﴾ [سورة: ١]';
      expect(OcrTextPostProcessor.process(raw), contains('﴾'));
      expect(OcrTextPostProcessor.process(raw), contains('﴿الآية﴾'));
    });

    test('مغلقٌ مفقود يُستعاد ولا يُبتكر قوسٌ يتيم', () {
      expect(
        OcrTextPostProcessor.process('قال تعالى: ﴿الآية الكريمة.'),
        'قال تعالى: ﴿الآية الكريمة﴾.',
      );
    });

    test('لا مساس حين يقترن القوس المرفوع بالمرجع', () {
      expect(
        OcrTextPostProcessor.process('قال تعالى: ﴿الآية [هود: ١١٤]'),
        contains('﴾ [هود:'),
      );
    });

    test('قَوسان مفتوحان ⇒ الغموض ولا يُخترَق', () {
      const String raw = 'قال تعالى: ﴿أ وَ ﴿ب';
      expect(OcrTextPostProcessor.process(raw), isNot(contains('﴾')));
    });
  });

  group('مفردات التنزيل تُحمى ولا تُبدَل', () {
    test('الرحمن الرحيم لا تُحوَّل إلى الرحمة الجحيم', () {
      const String raw = 'الحمد لله رب العالمين الرحمن الرحيم مالك يوم الدين.';
      expect(OcrTextPostProcessor.process(raw), contains('الرحمن الرحيم'));
      expect(OcrTextPostProcessor.process(raw), isNot(contains('الرحمة الجحيم')));
    });

    test('الكلمة المقيَّدة في المعجم لا تُصحَّح', () {
      // `الحرمان` معلومةٌ لا مجهولة؛ ولو جُرِّب تصحيحُ جذعها العارى
      // لحُوِّلت إلى `الحرمنا`.
      expect(
        OcrTextPostProcessor.process('١- أذى الجار سبب الحرمان من الجنة.'),
        contains('الحرمان'),
      );
      expect(
        OcrTextPostProcessor.process('- الكلمة الخبيثة سبب دخول النار.'),
        contains('الخبيثة'),
      );
    });

    test('المعجم يبقى نشِطاً: الجذع المجهول يُصلَح', () {
      expect(
        OcrTextPostProcessor.process('الكتااب على الطاولة'),
        contains('الكتاب'),
      );
    });
  });

  group('ثبات: النصّ السليم لا يتغيّر', () {
    test('آية وحديث وبند مرقّم', () {
      const List<String> clean = <String>[
        'قال تعالى: ﴿ما يلفظ من قولٍ إلا لديه رقيب عتيد﴾ [ق: ١٨].',
        '١- أذى الجار سبب الحرمان من الجنة.',
        'قال النبي ﷺ: «لا يدخل الجنة من لا يأمن جاره بوائقه».',
      ];
      for (final String line in clean) {
        expect(OcrTextPostProcessor.process(line), line, reason: line);
      }
    });
  });
}
