import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/pdf/arabic_text_engine.dart';

/// هل كل محارف النص من صيغ العرض العربية أو مسموح بها كما هي؟
bool _isShaped(String value) {
  for (final int rune in value.runes) {
    final bool presentationForm = rune >= 0xFE70 && rune <= 0xFEFF;
    final bool untouched = rune == 0x20 || rune == 0x0A || rune < 0x0590;
    if (!presentationForm && !untouched) return false;
  }
  return true;
}

/// مقاس تقريبي: كل حرف بعرض 10 (يكفي لاختبار تقسيم الأسطر بلا خط حقيقي).
double _fakeMeasure(String visualText) => visualText.runes.length * 10.0;

void main() {
  group('التشكيل والترتيب البصري', () {
    test('يوصل الحروف العربية في صيغ العرض المتصلة', () {
      const String logical = 'شهادة';
      final String shaped = ArabicTextEngine.toVisual(logical);

      expect(shaped, isNot(logical));
      expect(shaped.runes.length, logical.runes.length);
      expect(_isShaped(shaped), isTrue,
          reason: 'كل حرف يجب أن يتحوّل إلى صيغة عرض متصلة: $shaped');
    });

    test('يرتّب النص العربي ترتيباً بصرياً (آخر حرف منطقي أولاً)', () {
      const String logical = 'شهادة تقدير';
      final String shaped = ArabicTextEngine.toVisual(logical);

      // أوّل حرف في النص البصري هو آخر حرف منطقي (ر في «تقدير»)
      // بصيغته النهائية U+FEAE.
      expect(shaped.runes.first, 0xFEAE);
    });

    test('يحفظ الأرقام والحروف اللاتينية داخل النص العربي', () {
      const String logical = 'عقد رقم 1234 لعام 2026 م';
      final String shaped = ArabicTextEngine.toVisual(logical);

      expect(shaped.contains('1234'), isTrue);
      expect(shaped.contains('2026'), isTrue);
      expect(_isShaped(shaped), isTrue);
    });

    test('النص اللاتيني يبقى كما هو', () {
      const String logical = 'JoodCraft Official';
      expect(ArabicTextEngine.toVisual(logical), logical);
    });

    test('يحفظ التشكيل (الحركات) على الحروف', () {
      const String logical = 'مُحَمَّد';
      final String shaped = ArabicTextEngine.toVisual(logical);

      // التشكيل يبقى إمّا كعلامات (U+064B..U+0652) أو كصيغ مركّبة
      // (U+FC5E..U+FC63) — كلاهما صحيح، والمهم ألّا يُحذف التشكيل.
      bool hasDiacritic(int rune) =>
          (rune >= 0x064B && rune <= 0x0652) ||
          (rune >= 0xFC5E && rune <= 0xFC63) ||
          rune == 0x0670;

      expect(shaped.runes.any(hasDiacritic), isTrue,
          reason: 'يجب الحفاظ على علامات التشكيل في النص المشكَّل');
    });

    test('يتعامل مع النص الفارغ والأسطر المتعددة', () {
      expect(ArabicTextEngine.toVisual(''), '');
      final String multi = ArabicTextEngine.toVisualText('شهادة\nتقدير');
      expect(multi.split('\n').length, 2);
    });

    test('لا يعيد ترتيب نص بصري مسبقاً (صور عرض متصلة)', () {
      // نص نسخه المستخدم من ملف PDF آخر: لا يجوز تشكيله/ترتيبه مرة ثانية.
      const String preShaped = '\uFE8E\uFEE0\uFEDF\uFEB7';
      expect(ArabicTextEngine.toVisual(preShaped), preShaped);
    });
  });

  group('تقسيم الأسطر', () {
    test('يقسّم حسب العرض الأقصى بلا تجاوز', () {
      final List<String> lines = ArabicTextEngine.wrap(
        text: 'شهادة تقدير وامتنان للجهود المبذولة في خدمة المجتمع',
        maxWidth: 100,
        measureWidth: _fakeMeasure,
      );

      expect(lines.length, greaterThan(1));
      for (final String line in lines) {
        expect(_fakeMeasure(line), lessThanOrEqualTo(100));
      }
    });

    test('يحترم الترتيب البصري لكل سطر على حدة', () {
      // سطران: يجب أن يكون ترتيب كل سطر معكوساً داخل حدوده، لا أن تُقلب الفقرة
      // كاملة ثم تُقسَّم (وهو الخطأ الشائع).
      final List<String> lines = ArabicTextEngine.wrap(
        text: 'أ ب ج د هـ و ز',
        maxWidth: 45,
        measureWidth: _fakeMeasure,
      );

      expect(lines.length, greaterThan(1));
      // أول سطر منطقيًا يبدأ بـ «أ» ⇒ يصبح «أ» في أقصى يمين السطر البصري،
      // أي آخر محرف في السطر (بصيغته المنفصلة U+FE83).
      expect(lines.first.runes.last, 0xFE83);
    });

    test('يضيف علامة الحذف عند تجاوز عدد الأسطر', () {
      final List<String> lines = ArabicTextEngine.wrap(
        text: 'كلمة1 كلمة2 كلمة3 كلمة4 كلمة5 كلمة6',
        maxWidth: 60,
        measureWidth: _fakeMeasure,
        maxLines: 2,
      );

      expect(lines.length, 2);
      // الحذف في نهاية النص المنطقي ⇒ أقصى يسار السطر البصري (بدايته).
      expect(lines.last.startsWith(ArabicTextEngine.ellipsis), isTrue);
    });

    test('يحفظ الأسطر الفارغة (فقرات منفصلة)', () {
      final List<String> lines = ArabicTextEngine.wrap(
        text: 'الفقرة الأولى\n\nالفقرة الثانية',
        maxWidth: 500,
        measureWidth: _fakeMeasure,
      );
      expect(lines.length, 3);
      expect(lines[1], isEmpty);
    });

    test('يقسم الكلمة الأطول من السطر بدل تجاوز الحد', () {
      final List<String> lines = ArabicTextEngine.wrap(
        text: 'كلمهطويلهجداجدا',
        maxWidth: 40,
        measureWidth: _fakeMeasure,
      );
      expect(lines.length, greaterThan(1));
      for (final String line in lines) {
        expect(_fakeMeasure(line), lessThanOrEqualTo(40));
      }
    });

    test('يعيد السطر الواحد كما هو عند اتساع المساحة', () {
      final List<String> lines = ArabicTextEngine.wrap(
        text: 'شهادة شكر',
        maxWidth: 2000,
        measureWidth: _fakeMeasure,
      );
      expect(lines.length, 1);
      expect(_isShaped(lines.single), isTrue);
    });
  });

  group('محاذاة الضبط (Justify)', () {
    test('توسّع الأسطر غير الأخيرة إلى عرض الصندوق مع بقاء النص مشكَّلاً', () {
      final List<String> lines = ArabicTextEngine.wrap(
        text: 'كلمة1 كلمة2 كلمة3 كلمة4 كلمة5 كلمة6',
        maxWidth: 200,
        measureWidth: _fakeMeasure,
        justify: true,
      );

      expect(lines.length, greaterThan(1));
      // كل سطر غير أخير يُمدَّد إلى عرض الصندوق (تقريباً) بلا تجاوز.
      for (int i = 0; i < lines.length - 1; i++) {
        expect(_fakeMeasure(lines[i]), lessThanOrEqualTo(200));
        expect(_fakeMeasure(lines[i]), greaterThanOrEqualTo(190));
      }
      // السطر الأخير يبقى طبيعياً غير ممدَّد.
      expect(_fakeMeasure(lines.last), lessThan(200));
      for (final String line in lines) {
        expect(_isShaped(line), isTrue);
      }
    });

    test('لا تمسّ السطر ذا الكلمة الواحدة', () {
      final List<String> lines = ArabicTextEngine.wrap(
        text: 'كلمة',
        maxWidth: 500,
        measureWidth: _fakeMeasure,
        justify: true,
      );
      expect(lines.length, 1);
      expect(_fakeMeasure(lines.single), 40);
    });
  });

  group('محاذاة الضبط بالكشيدة (Tatweel Justify)', () {
    /// قياس منطقي تقريبي: كل محرف (ومنها الكشيدة) بعرض 10.
    double logicalMeasure(String text) => text.runes.length * 10.0;

    test('تُدرِج الكشيدة في مواضع الوصل الصحيحة فقط', () {
      // ش/ه قابلان للوصل أماماً، ا/د/ة لا → موضعان صحيحان فقط.
      final String stretched = ArabicTextEngine.justifyWithKashida(
        'شهادة',
        80,
        logicalMeasure,
      );

      expect(stretched.runes.where((int r) => r == 0x640).length, 3);
      expect(logicalMeasure(stretched), 80);
      // لا كلمة زائدة ولا نص ضائع: إزالة الكشيدة تعيد الكلمة الأصلية.
      expect(stretched.replaceAll('\u0640', ''), 'شهادة');
    });

    test('لا تُدرِج كشيدة في كلمة كل حروفها لا تتّصل أماماً', () {
      // د/ا/د حروف «يمينية» لا تتّصل بما بعدها ⇒ لا موضع تطويل.
      expect(
        ArabicTextEngine.justifyWithKashida('داد', 200, logicalMeasure),
        'داد',
      );
    });

    test('لا تتجاوز عرض الصندوق أبداً', () {
      const String line = 'شهادة تقدير للجهود';
      final double base = logicalMeasure(line);
      for (final double target in <double>[base + 20, base + 60, base + 130]) {
        final String stretched =
            ArabicTextEngine.justifyWithKashida(line, target, logicalMeasure);
        expect(
          logicalMeasure(stretched),
          lessThanOrEqualTo(target),
          reason: 'target=$target',
        );
        // واقترب من الهدف (الفارق أقل من عرض كشيدة واحدة).
        expect(logicalMeasure(stretched), greaterThan(target - 10));
      }
    });

    test('لا تمسّ السطر إذا كان أكبر من العرض أصلاً أو حتى متساوياً', () {
      expect(
        ArabicTextEngine.justifyWithKashida('شهادة تقدير', 50, logicalMeasure),
        'شهادة تقدير',
      );
    });

    test('الضبط بالكشيدة يحفظ أسطر الانكسار ويُنتج نصاً مشكَّلاً', () {
      const String text =
          'قد أتمّ بنجاح البرنامج التدريبي المكثّف في إدارة المشاريع وقيادة الفرق';

      final List<String> spaces = ArabicTextEngine.wrap(
        text: text,
        maxWidth: 200,
        measureWidth: _fakeMeasure,
        justify: true,
      );
      final List<String> kashida = ArabicTextEngine.wrap(
        text: text,
        maxWidth: 200,
        measureWidth: _fakeMeasure,
        justify: true,
        justifyMode: JustifyMode.kashida,
      );

      // الانكسار لا يختلف بين الطريقتين (الضبط يُطبَّق بعد التقسيم).
      expect(kashida.length, spaces.length);
      // الكشيدة تُطبَّق فعلاً: عدد الفراغات الداخلية لا يتضاعف كما في طريقة الفراغات.
      int spacesCount(String line) => ' '.allMatches(line).length;
      expect(
        kashida.first.runes.where((int r) => r == 0x640).isNotEmpty,
        isTrue,
      );
      expect(spacesCount(kashida.first), lessThan(spacesCount(spaces.first)));
      // لا يبقى أي حرف أساسي غير مشكَّل (صور العرض تبدأ من 0xFE70؛ الكشيدة
      // 0x0640 والتشكيل 0x064B+ مسموحان كما هما).
      for (final int rune in kashida.expand((String l) => l.runes)) {
        final bool unshapedLetter =
            rune >= 0x0621 && rune <= 0x064A && rune != 0x640;
        expect(unshapedLetter, isFalse,
            reason: 'rune=0x${rune.toRadixString(16)}');
      }
    });
  });
}
