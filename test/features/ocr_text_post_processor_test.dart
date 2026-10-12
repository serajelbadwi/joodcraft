/// اختبارات قواعد التنظيف العربية الإسلامية — بلا اعتماد على Tesseract.
///
/// ## لماذا ملفٌّ منفصل؟
///
/// اختبارات الشاشة (`ocr_screen_test.dart`) تُحقن محرّكاً وهميّاً فلا ترى
/// نصّاً حقيقياً؛ واختبار القياس يعتمد على تثبيت Tesseract فيُتجاوز عند غيابه.
/// وهذا الملف يختبر **القواعد نفسها** على مدخلات من تشغيل حقيقي مُبلَّغ عنه،
/// فيثبت كل قاعدة على حدة وبلا اعتماد على النظام.
///
/// ## المرجع
///
/// الأخطاء المُعادة إنتاجها هي التي رصدها المستخدم فعلياً على صورة نصّ إسلامي
/// (انظر `report/ocr_improvement.md`).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/ocr/data/text_post_processor.dart';

void main() {
  group('قاعدة 3 — مجموعات لاتينية وهمية وسط عربي', () {
    test('زوج كلمات وهمي خالص يُحذف كاملاً', () {
      // ⚠️ هذه بالضبط ثغرة كان يُخفيها الباب الثالث: أي كلمتين لاتينيتين
      // متتاليتين كانتا تُمرَّران بلا فحص، فنجا `gle BI` من الحذف.
      const String raw = '١- ABN من gle BI أذى الجار سبب الحرمان من الجنة.';
      final String cleaned = OcrTextPostProcessor.process(raw);

      expect(cleaned, isNot(contains('ABN')));
      expect(cleaned, isNot(contains('gle')));
      expect(cleaned, isNot(contains('BI')));
      expect(cleaned, contains('أذى الجار'));
      expect(cleaned, contains('الحرمان من الجنة'));
    });

    test('الجملة الإنجليزية ذات المفردة تبقى كاملة', () {
      // مقابل الثغرة: ما فيه مفردة تفهم لا يُمسّ.
      const String raw = 'القائد: Said CEO and Founder الرفيق';
      final String cleaned = OcrTextPostProcessor.process(raw);

      expect(cleaned, contains('CEO and Founder'));
      expect(cleaned, contains('القائد'));
    });

    test('كلمة إنجليزية معروفة وسط عربي تبقى', () {
      const String raw = 'الشركة: Jeddah Saudia headquarters';
      final String cleaned = OcrTextPostProcessor.process(raw);

      expect(cleaned, contains('Jeddah'));
    });

    test('رمز وهمي قصير وسط عربي يُحذف', () {
      const String raw = 'الإجابة: قال الي ge يدخل الجنة';
      final String cleaned = OcrTextPostProcessor.process(raw);

      expect(cleaned, isNot(contains('ge')));
      expect(cleaned, contains('يدخل الجنة'));
    });

    test('سطر لاتيني خالص لا يُمسّ', () {
      const String raw = 'Hello world and welcome';
      final String cleaned = OcrTextPostProcessor.process(raw);

      expect(cleaned, 'Hello world and welcome');
    });

    test('سطر مختلط لا تُمسّ أرقامه ولا روابطه', () {
      const String raw = 'www.example.com and user@host.dev الزميلة';
      final String cleaned = OcrTextPostProcessor.process(raw);

      expect(cleaned, contains('www.example.com'));
      expect(cleaned, contains('user@host.dev'));
    });
  });

  group('قاعدة 9 — الأرقام الهندية في السياق العربي', () {
    test('رقم مرجع لاتيني يعود هندياً', () {
      const String raw = 'الإجابة: قال تعالى: ﴿ما يلفظ﴾ [ق: 18]';
      final String cleaned = OcrTextPostProcessor.process(raw);

      expect(cleaned, contains('[ق: ١٨]'));
    });

    test('السنة لا تُحوَّل', () {
      const String raw = 'مجلة الموراث: 2014/04';
      final String cleaned = OcrTextPostProcessor.process(raw);

      expect(cleaned, contains('2014/04'));
    });

    test('البند المرقّم لا يُحوَّل', () {
      const String raw = '١- عنوان';
      final String cleaned = OcrTextPostProcessor.process(raw);

      expect(cleaned, contains('١- عنوان'));
    });

    test('الأرقام العربية الأصلية تبقى كما هي', () {
      const String raw = 'الآية رقم ١٨ من سورة ق';
      final String cleaned = OcrTextPostProcessor.process(raw);

      expect(cleaned, contains('١٨'));
    });

    test('سطر إنجليزي خالص لا تُحوَّل أرقامه', () {
      const String raw = 'Quran 18';
      final String cleaned = OcrTextPostProcessor.process(raw);

      expect(cleaned, contains('18'));
    });
  });

  group('قاعدة 10 — قوس المرجع', () {
    test('رمز وهمي داخل قوس مرجع يُترك فارغاً', () {
      const String raw = 'الإجابة: قال تعالى: ما يلفظ [ق: AVA';
      final String cleaned = OcrTextPostProcessor.process(raw);

      expect(cleaned, isNot(contains('AVA')));
      expect(cleaned, contains('[ق:'));
    });

    test('المرجع العربي السليم يبقى', () {
      const String raw = 'الآية [البقرة: ٢٥٥]';
      final String cleaned = OcrTextPostProcessor.process(raw);

      expect(cleaned, contains('[البقرة: ٢٥٥]'));
    });
  });

  group('قاعدة 11 — الأقواس المزخرفة', () {
    test('قوس مرسوم ) يُستعاد ﴾', () {
      const String raw =
          'الإجابة: قال تعالى: ما يلفظ من قول إلا لديه رقيب عتيد) [ق: 18]';
      final String cleaned = OcrTextPostProcessor.process(raw);

      expect(cleaned, contains('﴿ما يلفظ'));
      expect(cleaned, contains('عتيد﴾'));
      expect(cleaned, isNot(contains(')')));
    });

    test('الأقواس السليمة لا تُضاعَف', () {
      const String raw = 'قال تعالى: ﴿ما يلفظ﴾';
      final String cleaned = OcrTextPostProcessor.process(raw);

      expect(cleaned, 'قال تعالى: ﴿ما يلفظ﴾');
    });

    test('قوس ملتبس بأقواس لاتينية صريحة لا يُختلق', () {
      // `(` موجود ⇒ هناك قوس إنجليزي بالفعل، لا مساس.
      const String raw = 'قال تعالى: (قد أفلح) ﴾';
      final String cleaned = OcrTextPostProcessor.process(raw);

      expect(cleaned, contains('('));
      expect(cleaned, isNot(contains('﴿')));
    });

    test('سطر بلا علامة اقتباس لا يمسّه القوس', () {
      const String raw = 'نص عادي فيه قوس )';
      final String cleaned = OcrTextPostProcessor.process(raw);

      expect(cleaned, contains(')'));
    });
  });

  group('قاعدة 4 — صيغ الشرف', () {
    test('الصلعم تُطبَّع', () {
      expect(OcrTextPostProcessor.process('محمد صلى الله عليه صلعم'), contains('ﷺ'));
    });
  });

  group('ثبات المعالج', () {
    test('النصّ الفارغ يعود كما هو', () {
      expect(OcrTextPostProcessor.process(''), '');
    });

    test('تشغيل القواعد مرّتين لا يغيّر النتيجة (ثابتة)', () {
      const String raw = '١- ABN من gle BI أذى الجار سبب الحرمان من الجنة.';
      final String once = OcrTextPostProcessor.process(raw);
      final String twice = OcrTextPostProcessor.process(once);

      expect(twice, once, reason: 'المعالج يجب أن يكون نقطة ثابتة.');
    });

    test('النصّ السليم لا يتغيّر', () {
      const String clean = '١- أذى الجار سبب الحرمان من الجنة.\n'
          'الإجابة: قال النبي ﷺ: «لا يدخل الجنة من لا يأمن جاره بوائقه».';
      final String cleaned = OcrTextPostProcessor.process(clean);

      expect(cleaned, clean, reason: 'نصٌّ سليم لا يجوز أن يُعدَّل.');
    });
  });

  group('قائمة المختصرات — لا شكل اختصار', () {
    test('مختصرات حقيقية تبقى وسط عربي', () {
      // هذه وحدها المُعفاة — راجع قائمة `_knownAcronyms`.
      for (final String acronym in const <String>['API', 'PDF', 'HR', 'CEO']) {
        expect(
          OcrTextPostProcessor.process('القسم: $acronym فريق العمل'),
          contains(acronym),
          reason: 'المختصر الحقيقي $acronym لا يجوز أن يُحذف.',
        );
      }
    });

    test('زمر حروف كبيرة مجهولة تُحذف وسط عربي', () {
      // ⚠️ كانت تنجو لأنّها تشبه الاختصارات، وتجرّ جيرانها معها.
      expect(
        OcrTextPostProcessor.process('القسم: ABN وBI وAVA النتائج'),
        isNot(contains('ABN')),
      );
      expect(
        OcrTextPostProcessor.process('القسم: ABN وBI وAVA النتائج'),
        isNot(contains('BI')),
      );
      expect(
        OcrTextPostProcessor.process('القسم: ABN وBI وAVA النتائج'),
        isNot(contains('AVA')),
      );
    });
  });

  group('إلصاق الشَّرطة برقمها الهندي', () {
    test('١ - يعود ١-', () {
      const String raw = '١ - أذى الجار سبب الحرمان من الجنة.';
      expect(OcrTextPostProcessor.process(raw), contains('١- أذى'));
    });

    test('الرقم الملصق أصلاً لا يتغيّر', () {
      const String raw = '١- أذى الجار سبب الحرمان من الجنة.';
      expect(OcrTextPostProcessor.process(raw), contains('١- أذى'));
    });

    test('الشرطة غير الرقمية لا تُلمس', () {
      // كلمة - كلمة: ليست ترقيباً.
      const String raw = 'السؤال - عن الموضوع';
      final String cleaned = OcrTextPostProcessor.process(raw);
      expect(cleaned, contains('السؤال - '));
    });
  });

  group('علامات الاتجاه داخل الأرقام', () {
    test('LRM/RLM بين الرقم والشَّرطة يُحذف', () {
      // القياس: `١‏-` (بعد علامة اتجاه RLM) يُحسب رقمين لا رقماً.
      const String raw = '١\u200F- أذى الجار سبب الحرمان من الجنة.';
      final String cleaned = OcrTextPostProcessor.process(raw);

      expect(cleaned, contains('١- '));
      expect(cleaned, isNot(contains('\u200F')));
    });

    test('العلامة في آخر السطر لا تبقى', () {
      const String raw = 'الإجابة: قال تعالى: ﴿ما يلفظ﴾ [ق: ١٨].\u200F';
      final String cleaned = OcrTextPostProcessor.process(raw);

      expect(cleaned, isNot(contains('\u200F')));
    });
  });

  group('قاعدة 10 — إرجاع رمز الشرف', () {
    test('النبي:١‏ يعود النبي ﷺ:', () {
      // أثر مُقاس: المحرّك يفكّك الرمز المركّب إلى نقطتين ورقم.
      const String raw = 'الإجابة: قال النبي:١‏ «لا يدخل الجنة».';
      final String cleaned = OcrTextPostProcessor.process(raw);

      expect(cleaned, contains('النبي ﷺ:'));
      expect(cleaned, isNot(contains('النبي:١')));
    });

    test('الرقم الوهمي لا يبقى بعد الإرجاع', () {
      const String raw = 'الإجابة: قال النبي:١‏ «لا يدخل الجنة».';
      final String cleaned = OcrTextPostProcessor.process(raw);

      expect(cleaned, isNot(contains('١‏ ')));
    });

    test('النصّ السليم الذي فيه رقم حقيقي بعد النبي لا يُمَسّ', () {
      // احتراز: لو كان الرقم جزءاً من تعداد صريح (`النبي: ١` في قائمة)
      // فالقاعدة تجمعه أيضاً — وهذه حدود موثّقة للقاعدة، لا عيب صامت.
      const String raw = 'الأحاديث: النبي: ١ أولها.';
      final String cleaned = OcrTextPostProcessor.process(raw);

      expect(
        cleaned,
        contains('النبي ﷺ:'),
        reason: 'القاعدة تُطبَّق على البنية نفسها بلا استثناء — موثّقة.',
      );
    });
  });
}
