import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('يقبل بريداً صحيحاً', () {
      expect(Validators.email('name@organization.com'), isNull);
      expect(Validators.email('a.b+tag@sub.domain.sa'), isNull);
    });

    test('يرفض الفراغ والصيغ غير الصحيحة', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email(null), isNotNull);
      expect(Validators.email('name@@mail.com'), isNotNull);
      expect(Validators.email('name@mail'), isNotNull);
      expect(Validators.email('name mail.com'), isNotNull);
    });

    test('يتجاهل المسافات الطرفية', () {
      expect(Validators.email('  name@mail.com  '), isNull);
    });
  });

  group('Validators.password', () {
    test('يرفض كلمة مرور أقل من الحد الأدنى', () {
      expect(Validators.password('1234567'), isNotNull);
    });

    test('يقبل كلمة مرور بطول الحد الأدنى أو أكثر', () {
      expect(Validators.password('12345678'), isNull);
      expect(Validators.password('Str0ng!Pass'), isNull);
    });

    test('يرفض الفراغ', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password(null), isNotNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('يرفض عدم التطابق', () {
      expect(Validators.confirmPassword('abcdefgh', 'abcdefgX'), isNotNull);
    });

    test('يقبل التطابق', () {
      expect(Validators.confirmPassword('abcdefgh', 'abcdefgh'), isNull);
    });
  });

  group('Validators.displayName', () {
    test('يرفض الأسماء القصيرة جداً أو الطويلة جداً', () {
      expect(Validators.displayName('ع'), isNotNull);
      expect(Validators.displayName('ع '), isNotNull);
      expect(Validators.displayName('م' * 200), isNotNull);
    });

    test('يقبل الاسم المنطقي', () {
      expect(Validators.displayName('عبدالله الأحمد'), isNull);
    });
  });

  group('Validators.optionalName', () {
    test('يسمح بالفراغ', () {
      expect(Validators.optionalName(''), isNull);
      expect(Validators.optionalName(null), isNull);
    });

    test('يرفض الطول المفرط', () {
      expect(Validators.optionalName('م' * 200), isNotNull);
    });
  });
}
