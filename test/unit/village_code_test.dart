import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/village/domain/village_code.dart';

/// اختبارات كود القرية: التطبيع، الصيغة، التوليد، والاقتراح من اسم عربي.
void main() {
  group('التطبيع', () {
    test('يحذف المسافات ويوحّد الحالة', () {
      expect(VillageCode.normalize('  maa-2026 '), 'MAA-2026');
      expect(VillageCode.normalize('MaA-2026'), 'MAA-2026');
    });

    test('يحوّل الأرقام العربية-الهندية والشرطات الطويلة', () {
      expect(VillageCode.normalize('maa-٢٠٢٦'), 'MAA-2026');
      expect(VillageCode.normalize('MAA—2026'), 'MAA-2026');
      expect(VillageCode.normalize('MAA–2026'), 'MAA-2026');
    });
  });

  group('الصيغة', () {
    test('يقبل الصيغة المعتمدة فقط', () {
      expect(VillageCode.isValid('MAA-2026'), isTrue);
      expect(VillageCode.isValid('maa-2026'), isTrue);
      expect(VillageCode.isValid('MA-2026'), isFalse);
      expect(VillageCode.isValid('MAAA-2026'), isFalse);
      expect(VillageCode.isValid('MAA-26'), isFalse);
      expect(VillageCode.isValid('MAA2026'), isFalse);
      expect(VillageCode.isValid('123-2026'), isFalse);
    });

    test('يقبل صيغة لوحة المالك: بادئة + بريد 5 + Plus Code مختصر', () {
      expect(VillageCode.isValid('MAA-31951-25GF'), isTrue);
      expect(VillageCode.isValid('maa-31951-25gf'), isTrue);
      expect(VillageCode.normalize('maa-31951-25gf'), 'MAA-31951-25GF');
      // أجزاء ناقصة أو بريد قصير ⇒ مرفوض.
      expect(VillageCode.isValid('MAA-31951'), isFalse);
      expect(VillageCode.isValid('MAA-319-25GF'), isFalse);
      expect(VillageCode.isValid('MAA-31951-25'), isFalse);

      // القيمة المُتحقَّقة تُقرأ من الصيغتين (بادئة أول جزء في الحالتين).
      final VillageCodeValue? newFormat = VillageCodeValue.tryParse(
        'MAA-31951-25GF',
      );
      expect(newFormat, isNotNull);
      expect(newFormat!.prefix, 'MAA');
    });

    test('القيمة المُحلَّلة تُفكَّك إلى بادئة وسنة', () {
      final VillageCodeValue? value = VillageCodeValue.tryParse(' maa-2026 ');
      expect(value, isNotNull);
      expect(value!.value, 'MAA-2026');
      expect(value.prefix, 'MAA');
      expect(value.year, '2026');
      expect(VillageCodeValue.tryParse('خطأ'), isNull);
    });
  });

  group('التوليد', () {
    test('يبني الكود من البادئة والسنة', () {
      expect(VillageCode.generate(latinPrefix: 'maa', year: 2026), 'MAA-2026');
      expect(VillageCode.generate(latinPrefix: 'ABC'), 'ABC-2026');
    });

    test('يُكمل البادئة القصيرة ويقتطع الطويلة ويحذف غير اللاتيني', () {
      expect(VillageCode.generate(latinPrefix: 'm'), 'MXX-2026');
      expect(VillageCode.generate(latinPrefix: 'abcde'), 'ABC-2026');
      expect(VillageCode.generate(latinPrefix: 'منشأة'), 'XXX-2026');
    });

    test('السنة قابلة للتجاوز', () {
      expect(VillageCode.generate(latinPrefix: 'MAA', year: 2030), 'MAA-2030');
    });
  });

  group('الاقتراح من اسم القرية', () {
    test('بادئة القرية الأولى مثبّتة كما يتعارف عليها أهلها', () {
      expect(
        VillageCode.suggestFor('منشأة الأمراء ومحلة حسن'),
        'MAA-2026',
      );
      expect(
        VillageCode.suggestFor('منشأة الأمراء ومحلة حسن', year: 2027),
        'MAA-2027',
      );
    });

    test('قرية جديدة: أول ثلاثة حروف مختلفة بلا «ال» ولا واو العطف', () {
      expect(VillageCode.suggestFor('كفر الشيخ'), 'KFR-2026');
      // أول ثلاثة حروف مختلفة: م ح ل (لا يتكرّر «ح» ⇒ لا يُكتب H مرتين).
      expect(VillageCode.suggestFor('محلة حسن'), 'MHL-2026');
      expect(VillageCode.suggestFor('السنبلاوين'), 'SNB-2026');
    });

    test('الاسم بلا حروف عربية معروفة ⇒ بادئة افتراضية صالحة', () {
      final String code = VillageCode.suggestFor('12345');
      expect(VillageCode.isValid(code), isTrue);
      expect(code, 'VIL-2026');
    });
  });
}
