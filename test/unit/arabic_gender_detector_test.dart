import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/gender/arabic_gender.dart';

/// **محرّك التذكير والتأنيث**: الصيغة الشرطية `{{الجنس: ذكر | أنثى}}` وكاشف
/// جنس الاسم العربي المحلّي وحلّ الجنس من بيانات السجل.
void main() {
  group('Gender.fromValue', () {
    test('يفهم الصيغ العربية والإنجليزية الشائعة', () {
      for (final String value in <String>['ذكر', 'مذكر', 'male', 'M', '1']) {
        expect(Gender.fromValue(value), Gender.male, reason: value);
      }
      for (final String value in <String>[
        'أنثى',
        'انثى',
        'أنثي',
        'مؤنث',
        'بنت',
        'female',
        'F',
        '2',
      ]) {
        expect(Gender.fromValue(value), Gender.female, reason: value);
      }
    });

    test('القيم الغامضة تُعيد null والمقابل يتبدّل', () {
      expect(Gender.fromValue('غير محدد'), isNull);
      expect(Gender.fromValue(''), isNull);
      expect(Gender.fromValue(null), isNull);
      expect(Gender.male.opposite, Gender.female);
      expect(Gender.female.opposite, Gender.male);
      expect(Gender.male.labelAr, 'ذكر');
      expect(Gender.female.labelAr, 'أنثى');
    });
  });

  group('الصيغة الشرطية', () {
    test('البناء والحل بالجنسين مع الرجوع إلى المذكّر', () {
      expect(GenderGrammar.snippet('اجتاز', 'اجازت'), contains('|'));
      expect(
        GenderGrammar.apply('قد {{الجنس: اجتاز | اجتازت}} الاختبار', Gender.male),
        'قد اجتاز الاختبار',
      );
      expect(
        GenderGrammar.apply(
          'قد {{الجنس: اجتاز | اجتازت}} الاختبار',
          Gender.female,
        ),
        'قد اجتازت الاختبار',
      );
      // الافتراض عند غياب الجنس: الفرع الأول (المذكّر).
      expect(
        GenderGrammar.apply('قد {{الجنس: اجتاز | اجتازت}} الاختبار', null),
        'قد اجتاز الاختبار',
      );
    });

    test('يدعم مسافات حرة ومفاتيح مرادفة وصيغاً متعددة في نص واحد', () {
      const String text =
          'بناءً على طلب{{الجنس: ه | ها}} نتمنى {{gender: له | لها}} التوفيق';
      expect(GenderGrammar.containsCondition(text), isTrue);
      expect(
        GenderGrammar.apply(text, Gender.female),
        'بناءً على طلبها نتمنى لها التوفيق',
      );
      expect(
        GenderGrammar.apply(text, Gender.male),
        'بناءً على طلبه نتمنى له التوفيق',
      );
      expect(GenderGrammar.conditionsIn(text), hasLength(2));
      expect(GenderGrammar.conditionsIn(text).first.male, 'ه');
      expect(GenderGrammar.conditionsIn(text).first.female, 'ها');
    });

    test('النص بلا صيغة لا يتغيّر', () {
      expect(GenderGrammar.apply('شهادة إتمام', Gender.female), 'شهادة إتمام');
      expect(GenderGrammar.containsCondition('شهادة إتمام'), isFalse);
      expect(GenderGrammar.conditionsIn(''), isEmpty);
    });

    test('التمييز بين الصيغة الشرطية وحقل ديناميكي عادي', () {
      expect(GenderGrammar.isConditionInner('الجنس: له | لها'), isTrue);
      expect(GenderGrammar.isConditionInner('gender: he | she'), isTrue);
      // حقل عادي أو نص بلا شرط ليس صيغة شرطية.
      expect(GenderGrammar.isConditionInner('اسم_المتدرب'), isFalse);
      expect(GenderGrammar.isConditionInner('اسم له | لها'), isFalse);
      expect(GenderGrammar.isConditionInner('الجنس'), isFalse);
    });
  });

  group('ArabicGenderDetector', () {
    test('أسماء أنثوية شائعة يُعيدها أنثى', () {
      for (final String name in <String>[
        'سارة',
        'ساره العتيبي',
        'مريم',
        'فاطمة',
        'نورة',
        'أروى',
        'هند',
        'ليلى',
        'سلمى',
        'هدى',
        'منى',
        'ياسمين',
        'شهد',
        'رغد',
      ]) {
        expect(ArabicGenderDetector.detect(name), Gender.female, reason: name);
      }
    });

    test('الأسماء المذكّرة والقيم الفارغة ترجع ذكراً', () {
      for (final String name in <String>[
        'محمد',
        'محمد بن عبد الله الشمري',
        'أحمد',
        'خالد',
        'عبدالله',
        'يوسف',
        'عمر',
        '',
        '   ',
      ]) {
        expect(ArabicGenderDetector.detect(name), Gender.male, reason: '«$name»');
      }
      expect(ArabicGenderDetector.detect(null), Gender.male);
    });

    test('القواعد الصرفية: تاء مربوطة وألف ممدودة ومقصورة', () {
      expect(ArabicGenderDetector.detect('سلمى'), Gender.female);
      expect(ArabicGenderDetector.detect('صفاء'), Gender.female);
      expect(ArabicGenderDetector.detect('لطيفة'), Gender.female);
      // استثناءات مذكّرة تنتهي بصيغة أنثوية.
      expect(ArabicGenderDetector.detect('حمزة'), Gender.male);
      expect(ArabicGenderDetector.detect('مصطفى'), Gender.male);
      expect(ArabicGenderDetector.detect('عيسى'), Gender.male);
      expect(ArabicGenderDetector.detect('علاء'), Gender.male);
      expect(ArabicGenderDetector.detect('معاوية'), Gender.male);
      expect(ArabicGenderDetector.detect('أسامة'), Gender.male);
    });

    test('البادئات المركّبة: عبد وأبو وابن وآل وبنت وأم', () {
      expect(ArabicGenderDetector.detect('عبد الرحمن'), Gender.male);
      expect(ArabicGenderDetector.detect('عبدالرحمن'), Gender.male);
      expect(ArabicGenderDetector.detect('أبو بكر'), Gender.male);
      expect(ArabicGenderDetector.detect('ابن سينا'), Gender.male);
      expect(ArabicGenderDetector.detect('آل سعيد'), Gender.male);
      expect(ArabicGenderDetector.detect('بنت سعيد'), Gender.female);
      expect(ArabicGenderDetector.detect('أم كلثوم'), Gender.female);
    });

    test('الألقاب تُجرَّد قبل الحكم، واللقب الأنثوي يحكم فوراً', () {
      expect(ArabicGenderDetector.detect('د. سارة العتيبي'), Gender.female);
      expect(ArabicGenderDetector.detect('د. خالد'), Gender.male);
      expect(ArabicGenderDetector.detect('أستاذة نورة'), Gender.female);
      expect(ArabicGenderDetector.detect('الدكتورة مريم'), Gender.female);
      expect(ArabicGenderDetector.detect('المهندس أحمد'), Gender.male);
      expect(ArabicGenderDetector.detect('الأستاذ محمد'), Gender.male);
    });

    test('التشكيل والهمزات لا تكسر الكشف', () {
      expect(ArabicGenderDetector.detect('سَارَة'), Gender.female);
      expect(ArabicGenderDetector.detect('نُوْرَة'), Gender.female);
      expect(ArabicGenderDetector.detect('إيمان'), Gender.female);
    });
  });

  group('GenderResolver', () {
    test('عمود الجنس الصريح يتقدّم على الاسم', () {
      final Map<String, String> data = <String, String>{
        'اسم_المتدرب': 'أحمد الشمري',
        'الجنس': 'أنثى',
      };
      expect(GenderResolver.resolve(data), Gender.female);
    });

    test('غياب عمود الجنس ← كشف الاسم، وإلا فالذكر', () {
      expect(
        GenderResolver.resolve(<String, String>{'اسم_المتدرب': 'سارة العتيبي'}),
        Gender.female,
      );
      expect(
        GenderResolver.resolve(<String, String>{'اسم_المتدرب': 'خالد'}),
        Gender.male,
      );
      expect(GenderResolver.resolve(<String, String>{}), Gender.male);
      expect(GenderResolver.resolve(null), Gender.male);
    });

    test('التصحيح اليدوي (override) يتقدّم على كل شيء', () {
      final Map<String, String> data = <String, String>{
        'اسم_المتدرب': 'سارة',
        'الجنس': 'أنثى',
      };
      expect(
        GenderResolver.resolve(data, override: Gender.male),
        Gender.male,
      );
    });

    test('الرجوع إلى القيم التجريبية عند غياب بيانات الاسم', () {
      expect(
        GenderResolver.resolve(
          <String, String>{},
          fallback: <String, String>{'اسم_المتدرب': 'مريم'},
        ),
        Gender.female,
      );
    });

    test('labelFor تُعيد التسمية العربية الجاهزة للحقن', () {
      expect(
        GenderResolver.labelFor(<String, String>{'اسم_المتدرب': 'نورة'}),
        'أنثى',
      );
      expect(GenderResolver.labelFor(<String, String>{'اسم_المتدرب': 'خالد'}),
          'ذكر');
    });
  });

  group('صيغ الإدراج الجاهزة', () {
    test('كل صيغة تحمل فرعين مختلفين ومفتاح ترجمة', () {
      expect(GenderGrammar.presets, isNotEmpty);
      for (final GenderSnippetPreset preset in GenderGrammar.presets) {
        expect(preset.male.trim(), isNotEmpty);
        expect(preset.female.trim(), isNotEmpty);
        expect(preset.male, isNot(preset.female));
        expect(preset.labelKey, startsWith('genderPreset'));
        expect(preset.snippet, contains('{{الجنس:'));
        expect(preset.snippet, contains('|'));
      }
    });
  });
}
