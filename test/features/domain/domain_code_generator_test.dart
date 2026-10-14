import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/domain/domain/domain_code_generator.dart';

void main() {
  group('DomainCodeGenerator — توليد الكود', () {
    test('مثال المهمة: MAA-31951-25GF989', () {
      final String code = DomainCodeGenerator.generate(
        nameEn: 'Maarra',
        postalCode: '31951',
        plusCode: '25GF+989',
      );
      expect(code, 'MAA-31951-25GF989');
      expect(DomainCodeGenerator.isValid(code), isTrue);
    });

    test('4 أحرف قبل + و3 بعده — والقصور يُقتطع', () {
      // القبلي يُقتطع إلى 4 والبعدي إلى 3.
      expect(
        DomainCodeGenerator.generate(
          nameEn: 'Maarra',
          postalCode: '31951',
          plusCode: '25GFXY12+9876',
        ),
        'MAA-31951-25GF987',
      );
    });

    test('بلا علامة + ⇒ القبلي فقط', () {
      expect(
        DomainCodeGenerator.generate(
          nameEn: 'Maarra',
          postalCode: '31951',
          plusCode: '25GF',
        ),
        'MAA-31951-25GF',
      );
    });

    test('قصر عن 4 أحرف ⇒ بديل سنتان + حرفان من الاسم', () {
      // القبلي 2 والبعدي 1 ⇒ «259» أقصر من 4 ⇒ بديل (26 + MA).
      expect(
        DomainCodeGenerator.generate(
          nameEn: 'Maarra',
          postalCode: '31951',
          plusCode: '25+9',
          now: DateTime(2026, 3),
        ),
        'MAA-31951-26MA',
      );
    });

    test('بلا حروف لاتينية وPlus Code قصير ⇒ حشو Q', () {
      expect(
        DomainCodeGenerator.generate(
          nameEn: '  ',
          postalCode: '31951',
          plusCode: '25+9',
          now: DateTime(2026, 3),
        ),
        'XXX-31951-26QQ',
      );
    });

    test('غياب Plus Code ⇒ سنتان + حرفان من الاسم', () {
      final String code = DomainCodeGenerator.generate(
        nameEn: 'Maarra',
        postalCode: '31951',
        now: DateTime(2026, 3),
      );
      expect(code, 'MAA-31951-26MA');
      expect(DomainCodeGenerator.isValid(code), isTrue);
    });

    test('بلا رمز بريدي ولا Plus Code ⇒ بديل «0 + السنة»', () {
      final String code = DomainCodeGenerator.generate(
        nameEn: 'Maarra',
        now: DateTime(2025, 7),
      );
      expect(code, 'MAA-02025-25MA');
      expect(DomainCodeGenerator.isValid(code), isTrue);
    });

    test('اسم بلا حروف لاتينية ⇒ بادئة XXX وبدائل', () {
      final String code = DomainCodeGenerator.generate(
        nameEn: '  ',
        now: DateTime(2025, 7),
      );
      expect(code, 'XXX-02025-25QQ');
      expect(DomainCodeGenerator.isValid(code), isTrue);
    });

    test('اسم أقصر من 3 أحرف ⇒ يُحشى X', () {
      final String code = DomainCodeGenerator.generate(
        nameEn: 'Al',
        postalCode: '31951',
        plusCode: '25GF+989',
      );
      expect(code, 'ALX-31951-25GF989');
    });

    test('الرمز البريدي غير الخماسي ⇒ بديل «0 + السنة»', () {
      final String code = DomainCodeGenerator.generate(
        nameEn: 'Maarra',
        postalCode: '3195',
        plusCode: '25GF+989',
        now: DateTime(2026, 1),
      );
      expect(code, 'MAA-02026-25GF989');
    });

    test('الرمز البريدي بمسافات يُنقّى ثم يُفحص', () {
      // «31 951» ⇒ «31951» (5 أرقام) فيُقبل.
      expect(
        DomainCodeGenerator.generate(
          nameEn: 'Maarra',
          postalCode: '31 951',
          plusCode: '25GF+989',
        ),
        'MAA-31951-25GF989',
      );
    });

    test('Plus Code كامل: 4 قبل + و3 بعد — لا أول 7 من القبلي', () {
      final String code = DomainCodeGenerator.generate(
        nameEn: 'Maarra',
        postalCode: '31951',
        plusCode: '8FW4V7WC+R8M',
      );
      expect(code, 'MAA-31951-8FW4R8M');
      expect(DomainCodeGenerator.isValid(code), isTrue);
    });

    test('حالة صغيرة والمسافات لا تكسر التوليد', () {
      expect(
        DomainCodeGenerator.generate(
          nameEn: 'maarra',
          postalCode: '31951',
          plusCode: '25gf+989',
        ),
        'MAA-31951-25GF989',
      );
    });

    test('الصيغة القديمة AAA-YYYY غير مقبولة للمولّد', () {
      expect(DomainCodeGenerator.isValid('MAA-2026'), isFalse);
      expect(DomainCodeGenerator.isValid('MAA-31951-25GF'), isTrue);
      expect(DomainCodeGenerator.isValid('MAA-31951-25GF989'), isTrue);
      // ثمانية أحرف في الجزء الأخير تتجاوز الحد (4+3).
      expect(DomainCodeGenerator.isValid('MAA-31951-25GF9891'), isFalse);
      expect(DomainCodeGenerator.isValid('MAA-31951-25G'), isFalse);
      expect(DomainCodeGenerator.isValid('MA-31951-25GF'), isFalse);
      expect(DomainCodeGenerator.isValid('MAA-3195-25GF'), isFalse);
    });
  });

  group('DomainCodeValue — التحقق والتطبيع', () {
    test('tryParse يقبل الصيغة المعيارية', () {
      final DomainCodeValue? value = DomainCodeValue.tryParse('MAA-31951-25GF989');
      expect(value, isNotNull);
      expect(value!.value, 'MAA-31951-25GF989');
      expect(value.prefix, 'MAA');
      expect(value.postal, '31951');
      expect(value.local, '25GF989');
    });

    test('tryParse يطبّع المسافات والشرطات الطويلة والحالة', () {
      final DomainCodeValue? value =
          DomainCodeValue.tryParse(' maa – 31951 – 25gf989 ');
      expect(value?.value, 'MAA-31951-25GF989');
    });

    test('tryParse يطبّع الأرقام العربية-الهندية', () {
      final DomainCodeValue? value =
          DomainCodeValue.tryParse('MAA-٣١٩٥١-25GF989');
      expect(value?.value, 'MAA-31951-25GF989');
    });

    test('tryParse يرفض النص غير المطابق', () {
      expect(DomainCodeValue.tryParse('قرية'), isNull);
      expect(DomainCodeValue.tryParse('MAA-2026'), isNull);
      expect(DomainCodeValue.tryParse(''), isNull);
    });

    test('تساوي القيم بالنص لا بالهوية', () {
      expect(
        DomainCodeValue.tryParse('MAA-31951-25GF989'),
        DomainCodeValue.tryParse('maa-31951-25gf989'),
      );
    });
  });
}
