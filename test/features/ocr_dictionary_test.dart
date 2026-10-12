/// اختبار **القاعدة 15** — تصحيح الكلمة العربية بالقاموس.
///
/// القاعدة الأخيرة في `OcrTextPostProcessor`، وهي الوحيدة التي تقرأ ملفاً
/// خارجياً (`arabic_word_list.dart` — أوّل ‎10,000‎ كلمة عربية بترتيب التكرار).
///
/// المحاكاة التي اعتمدت هذه الحالات تُجري **خوارزمية الاختبار نفسها**
/// (تفليت السوابق ← مفتاح مُطبَّع ← مسافة تحرير 1 ← مرشّح وحيد).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/ocr/data/arabic_word_list.dart';
import 'package:joodcraft/features/ocr/data/text_post_processor.dart';

void main() {
  group('القاموس العربي — القاعدة 15', () {
    test('القاموس محمَّل بأوّل ‎10,000‎ كلمة عربية', () {
      final List<String> words = ArabicWordList.raw.split('\n');
      expect(words, hasLength(10000));
      // لا كلمة فارغة في الوسط — وإلا لاختلّ مفتاح البحث عن المرشّحات.
      expect(words.where((String w) => w.isEmpty), isEmpty);
      // كل كلمة ثلاثة حروف فأكثر (شرط التوليد — القِصَر خطر لا فائدة).
      expect(
        words.where((String w) => w.length < 3),
        isEmpty,
        reason: 'كلمة أقصر من ثلاثة حروف تعطّل قاعدة أقل طول للتصحيح.',
      );
    });

    test('حرف زائد يُحذف: الكتااب ← الكتاب', () {
      // الخطأ هنا حذفُ حرف (`كتاب` ← `كتااب`)، والمرشّح الوحيد هو `كتاب`.
      expect(OcrTextPostProcessor.process('الكتااب'), 'الكتاب');
    });

    test('السابقة تُفصَل ثم تُعاد: والكتااب ← والكتاب', () {
      expect(OcrTextPostProcessor.process('والكتااب'), 'والكتاب');
    });

    test('كلمة موجودة في القاموس لا تُمَسّ', () {
      const List<String> correct = <String>['مرحبا', 'الكتاب', 'الناس'];
      for (final String word in correct) {
        expect(OcrTextPostProcessor.process(word), word, reason: 'كلمة: $word');
      }
    });

    test('كلمة قصيرة (أقلّ من 4 بعد سابقتها) لا تُصحَّح إطلاقاً', () {
      // كلمتان بثلاثة حروف بينهما تعديل واحد قد تنقلبان معنى الجملة:
      // `من` ← `فن`، `على` ← `علن`. الخطأ المعروف أسلم من «تصحيح» يخطئ.
      const List<String> short = <String>['من', 'على', 'في', 'عن'];
      for (final String word in short) {
        expect(OcrTextPostProcessor.process(word), word, reason: 'كلمة: $word');
      }
    });

    test('تكرار حرفٍ ملتبس لا يُصحَّح — ولا يُخمَّن', () {
      // `الحلاال` ← فيها مرشّحات عدّة على مسافة واحدة، فالمتغيّر لا يُرجَّح
      // على غيره بدليل. هذا **حدٌّ معروف ومقصود** لا سهو.
      const String ambiguous = 'الحلاال';
      expect(OcrTextPostProcessor.process(ambiguous), ambiguous);
    });

    test('إطفاء القاموس يُبقي النصّ كما هو', () {
      const String broken = 'الكتااب';
      expect(
        OcrTextPostProcessor.process(broken, useDictionary: false),
        broken,
        reason: 'الوسيط صريح: `useDictionary: false` يوقف القاعدة 15.',
      );
    });

    test('التصحيح ثابت — تشغيله مرّتين لا يغيّر النتيجة', () {
      final String once = OcrTextPostProcessor.process('الكتااب');
      expect(OcrTextPostProcessor.process(once), once);
    });

    test('سطر لاتيني خالص لا يدخله تصحيح عربي', () {
      const String english = 'CEO and Founder of the company';
      expect(OcrTextPostProcessor.process(english), english);
    });
  });
}
