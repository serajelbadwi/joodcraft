import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/village/domain/village_validators.dart';

/// اختبارات تحقّق حقول صفحة القرية: الاسم، التليفون، الكود، وتطبيع الأرقام.
void main() {
  group('الاسم', () {
    test('الحقل الفارغ والقصير والطويل', () {
      expect(VillageValidators.name('   '), 'اكتب الاسم بالكامل');
      expect(VillageValidators.name('سي'), 'الاسم قصير جداً');
      expect(
        VillageValidators.name('ا' * (VillageValidators.maxNameLength + 1)),
        'الاسم طويل جداً',
      );
    });

    test('الاسم يحوي أرقاماً يُرفض', () {
      expect(VillageValidators.name('محمد 123'), 'الاسم لا يحتوي أرقاماً');
      expect(VillageValidators.name('محمد ١٢٣'), 'الاسم لا يحتوي أرقاماً');
    });

    test('الاسم بحروف لاتينية أو رموز يُرفض', () {
      expect(VillageValidators.name('Mohamed Ahmed'), 'اكتب الاسم بحروف عربية');
      expect(VillageValidators.name('محمد@أحمد'), 'اكتب الاسم بحروف عربية');
    });

    test('الاسم الصحيح يُقبل مع توحيد المسافات', () {
      expect(VillageValidators.name('محمد أحمد عبد الله'), isNull);
      expect(VillageValidators.name('  محمد   أحمد  '), isNull);
      expect(VillageValidators.name('منشأة الأمراء ومحلة حسن'), isNull);
    });
  });

  group('التليفون', () {
    test('الحقل الفارغ', () {
      expect(VillageValidators.phone(''), 'اكتب رقم التليفون');
      expect(VillageValidators.phone('   '), 'اكتب رقم التليفون');
    });

    test('غير الرقمي والطول الخطأ', () {
      expect(VillageValidators.phone('01012ab4567'), 'رقم التليفون أرقام فقط');
      expect(
        VillageValidators.phone('0101234567'),
        'رقم التليفون 11 رقماً بالضبط',
      );
      expect(
        VillageValidators.phone('010123456789'),
        'رقم التليفون 11 رقماً بالضبط',
      );
    });

    test('بادئة غير مقبولة في مصر', () {
      expect(
        VillageValidators.phone('01712345678'),
        'رقم غير صحيح — يبدأ بـ 010 أو 011 أو 012 أو 015',
      );
    });

    test('كل البادئات المقبولة تُقبل', () {
      for (final String prefix in VillageValidators.phonePrefixes) {
        expect(VillageValidators.phone('${prefix}12345678'), isNull);
      }
    });

    test('الأرقام العربية-الهندية تُطبيع قبل التحقق', () {
      expect(VillageValidators.phone('٠١٠١٢٣٤٥٦٧٨'), isNull);
    });
  });

  group('كود القرية', () {
    test('الحقل الفارغ', () {
      expect(VillageValidators.code(''), 'اكتب كود القرية');
      expect(VillageValidators.code('   '), 'اكتب كود القرية');
    });

    test('الصيغة الخاطئة تحمل مثالاً في رسالتها', () {
      final String? error = VillageValidators.code('maa');
      expect(error, contains('صيغة الكود غير صحيحة'));
      expect(error, contains(VillageText.villageCode));
      expect(VillageValidators.code('1234'), isNotNull);
    });

    test('الصيغة الصحيحة مقبولة بأي حالة أو مسافات', () {
      expect(VillageValidators.code('MAA-2026'), isNull);
      expect(VillageValidators.code(' maa-2026 '), isNull);
      expect(VillageValidators.code('maa—2026'), isNull);
    });

    test('canonical يحوّل إلى الصورة المعيارية', () {
      expect(VillageValidators.canonicalCode(' maa—2026 '), 'MAA-2026');
      expect(VillageValidators.normalizeDigits('٠١٠ ١٢٣-٤٥٦'), '010123456');
    });
  });

  group('نصوص الصفحة', () {
    test('رسائل الترحيب والنجاح تحمل الأسماء', () {
      expect(
        VillageText.welcomeVillage('قرية النور'),
        contains('قرية النور'),
      );
      expect(
        VillageText.successBody('محمد', 'القرية'),
        contains('محمد'),
      );
      expect(VillageText.successBody('محمد', 'القرية'), contains('القرية'));
    });
  });
}
