import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/village/domain/national_id.dart';

/// اختبارات محرّك **الرقم القومي المصري**.
///
/// الأرقام المستخدمة تجريبية بالبنية الصحيحة: خانة القرن + تاريخ الميلاد +
/// كود المحافظة + السلسلة + خانة التحقق، ولا تخصّ أشخاصاً حقيقيين.
void main() {
  /// رقم من الثمانينيات (القرن 2) — 1990/05/12، الدقهلية، خانة تحقق `5`.
  const String nid1990 = '29005121234565';

  group('التطبيع وقراءة الإدخال', () {
    test('يحذف المسافات والشرطات ومحارف الاتجاه', () {
      expect(NationalIdValidator.normalize(' 2900-5121 2345 65 '), nid1990);
      expect(NationalIdValidator.normalize('29\u200f0051\u200e21234565'), nid1990);
    });

    test('يحوّل الأرقام العربية-الهندية والفارسية إلى لاتينية', () {
      expect(
        NationalIdValidator.normalize('٢٩٠٠٥١٢١٢٣٤٥٦٥'),
        nid1990,
      );
      expect(
        NationalIdValidator.normalize('۲۹۰۰۵۱۲۱۲۳۴۵۶۵'),
        nid1990,
      );
    });

    test('يُعيد الرقم مُتحقَّقاً منه بعد التطبيع', () {
      final NationalIdParse parse =
          NationalIdValidator.validate('٢٩٠٠٥١٢١٢٣٤٥٦٥');
      expect(parse.isValid, isTrue);
      expect(parse.value!.digits, nid1990);
    });
  });

  group('الرفض القطعي', () {
    test('الحقل الفارغ', () {
      final NationalIdParse parse = NationalIdValidator.validate('   ');
      expect(parse.isValid, isFalse);
      expect(parse.error, NationalIdError.empty);
      expect(parse.message, contains('14'));
    });

    test('وجود حروف أو رموز', () {
      final NationalIdParse parse =
          NationalIdValidator.validate('2900512123456a');
      expect(parse.error, NationalIdError.notDigits);
    });

    test('الطول غير 14', () {
      expect(
        NationalIdValidator.validate('290051212345').error,
        NationalIdError.wrongLength,
      );
      expect(
        NationalIdValidator.validate('290051212345655').error,
        NationalIdError.wrongLength,
      );
    });

    test('خانة القرن غير صحيحة', () {
      expect(
        NationalIdValidator.validate('19005121234565').error,
        NationalIdError.badCentury,
      );
    });

    test('تاريخ ميلاد غير موجود في التقويم', () {
      // الشهر 13
      expect(
        NationalIdValidator.validate('29013021234565').error,
        NationalIdError.badDate,
      );
      // 31 فبراير
      expect(
        NationalIdValidator.validate('29002311234565').error,
        NationalIdError.badDate,
      );
      // 30 فبراير
      expect(
        NationalIdValidator.validate('29002301234565').error,
        NationalIdError.badDate,
      );
      // 29 فبراير 1900 — ليست سنة كبيسة
      expect(
        NationalIdValidator.validate('20002291234565').error,
        NationalIdError.badDate,
      );
    });

    test('29 فبراير 2000 سنة كبيسة ⇒ مقبولة', () {
      final NationalIdParse parse =
          NationalIdValidator.validate('30002291234565');
      expect(parse.isValid, isTrue);
      expect(parse.value!.birthDate, DateTime(2000, 2, 29));
    });

    test('تاريخ ميلاد مستقبلي', () {
      final NationalIdParse parse = NationalIdValidator.validate(
        '32701011234565',
        now: DateTime(2026, 10, 11),
      );
      expect(parse.error, NationalIdError.futureDate);
    });

    test('كود محافظة غير معروف', () {
      expect(
        NationalIdValidator.validate('29005129934565').error,
        NationalIdError.unknownGovernorate,
      );
      // 88 مقبول (مولود خارج مصر)
      expect(
        NationalIdValidator.validate('29005128834565').isValid,
        isTrue,
      );
    });
  });

  group('السن وحدّ 18', () {
    test('حدّ السن: يوم عيد الميلاد الثامن عشر يُقبل، وقبله بيوم يُرفض', () {
      final DateTime today = DateTime(2026, 10, 11);

      // مولود 2008/10/11 ⇒ أتمّ 18 اليوم بالضبط.
      final NationalIdParse onBirthday =
          NationalIdValidator.validate('30810111234565', now: today);
      expect(onBirthday.isValid, isTrue);
      expect(onBirthday.value!.age, 18);

      // مولود 2008/10/12 ⇒ ما زال 17.
      final NationalIdParse oneDayShort =
          NationalIdValidator.validate('30810121234565', now: today);
      expect(oneDayShort.error, NationalIdError.tooYoung);
      expect(oneDayShort.message, contains('18'));
    });

    test('قبل عيد الميلاد بيوم في نفس الشهر يُنقص سنة', () {
      expect(
        NationalIdValidator.ageAt(DateTime(1990, 12, 31), DateTime(2026, 12, 30)),
        35,
      );
      expect(
        NationalIdValidator.ageAt(DateTime(1990, 12, 31), DateTime(2026, 12, 31)),
        36,
      );
    });

    test('يستخرج السن والمحافظة والنوع والتاريخ', () {
      final NationalIdParse parse = NationalIdValidator.validate(
        nid1990,
        now: DateTime(2026, 10, 11),
      );
      final EgyptianNationalId value = parse.value!;
      expect(value.age, 36);
      expect(value.birthDate, DateTime(1990, 5, 12));
      expect(value.birthDateLabel, '1990/05/12');
      expect(value.governorateCode, '12');
      expect(value.governorateName, 'الدقهلية');
      expect(value.previewLabel, 'تاريخ الميلاد: 1990/05/12 — العمر: 36 سنة');
      // الرقم الثالث عشر `6` زوجي ⇒ أنثى.
      expect(value.isMale, isFalse);
    });

    test('الرقم الثالث عشر الفردي ⇒ ذكر', () {
      final NationalIdParse parse =
          NationalIdValidator.validate('29005121234555');
      expect(parse.value!.isMale, isTrue);
    });
  });

  group('خانة التحقق (اختيارية)', () {
    test('تُحسب وتُحفظ لكن لا تمنع التسجيل افتراضياً', () {
      final NationalIdParse loose =
          NationalIdValidator.validate('29005121234567');
      expect(loose.isValid, isTrue);
      expect(loose.value!.checksumMatches, isFalse);
    });

    test('مع strictChecksum يُرفض الرقم غير المطابق ويُقبل المطابق', () {
      expect(
        NationalIdValidator.validate('29005121234567', strictChecksum: true)
            .error,
        NationalIdError.badChecksum,
      );
      expect(
        NationalIdValidator.validate(nid1990, strictChecksum: true).isValid,
        isTrue,
      );
      expect(NationalIdValidator.checksumMatches(nid1990), isTrue);
    });
  });
}
