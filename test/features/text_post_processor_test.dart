import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/ocr/data/text_post_processor.dart';
import 'package:joodcraft/features/ocr/domain/ocr_result.dart';
import 'package:joodcraft/features/ocr/presentation/providers/ocr_controller.dart';

import '../support/ocr_engine_stub.dart';

/// اختبارات المعالج اللاحق لنصّ OCR.
///
/// الفكرة: Tesseract يقرأ مستنداً عربياً فيُنتج رموزاً لاتينية **وهمية**
/// (`by`, `so`, `ne`, `dal`, `cai`, `Land`) وأخطاء عربية (`الالرحمن`، `وو`)؛
/// والمعالج يحذف الوهمي ويُبقي الحقيقي ويصحّح العربي.
void main() {
  group('أ) حذف الرموز الإنجليزية الوهمية', () {
    test('يحذف by و so و ne وسط نصّ عربي', () {
      const String raw = 'هذا by نص so فيه ne كثير';
      expect(OcrTextPostProcessor.process(raw), 'هذا نص فيه كثير');
    });

    test('يحذف الرموز المُبلَّغ عنها: dal و cai و land', () {
      const String raw = 'قرأت dal الملف cai من land المجلد';
      expect(OcrTextPostProcessor.process(raw), 'قرأت الملف من المجلد');
    });

    test('يحذف كلمة طويلة غير معروفة وسط عربي', () {
      const String raw = 'تم zzzzz تحديث النظام بنجاح';
      expect(OcrTextPostProcessor.process(raw), 'تم تحديث النظام بنجاح');
    });

    test('يحذف اللاتيني الملتصق بالعربي ويبقي الحروف العربية', () {
      expect(OcrTextPostProcessor.process('بby'), 'ب');
      expect(OcrTextPostProcessor.process('تمbyالعمل'), 'تمالعمل');
      expect(OcrTextPostProcessor.process('نسخةPro'), 'نسخة');
    });

    test('لا يحذف رمزاً وهمياً في سطر لاتيني خالص', () {
      // سطر بلا حروف عربي: خارج نطاق المعالجة كله.
      const String raw = 'by so ne';
      expect(OcrTextPostProcessor.process(raw), raw);
    });

    test('يبقى كلمة حقيقية حتى لو كانت في قوائم التباس شائعة', () {
      // «one» حقيقية لغوياً لكنها ضمن قوائم الالتباس — تُحذف وسط عربي فقط.
      expect(
        OcrTextPostProcessor.process('الرقم one في النص'),
        'الرقم في النص',
      );
    });
  });

  group('ب) الإنجليزي الحقيقي يبقى', () {
    test('يحافظ على hello world كاملة', () {
      const String raw = 'مرحبا hello world كيف حالك';
      expect(OcrTextPostProcessor.process(raw), raw);
    });

    test('يحافظ على جملة إنجليزية من ثلاثة كلمات', () {
      const String raw = 'العنوان Welcome to our wedding';
      expect(OcrTextPostProcessor.process(raw), raw);
    });

    test('يحافظ على الاختصارات كلّها أحرف كبيرة: API و PDF و URL', () {
      const String raw = 'المؤتمر API القادم بصيغة PDF من URL';
      expect(OcrTextPostProcessor.process(raw), raw);
    });

    test('يحافظ على العناوين المختلطة case مع الأرقام', () {
      const String raw = 'الإصدار iPad Pro 2024 جاهز';
      expect(OcrTextPostProcessor.process(raw), raw);
    });

    test('يحافظ على البريد والروابط بلا تغيير', () {
      const String raw = 'راسلنا على user@host.com أو example.com الآن';
      expect(OcrTextPostProcessor.process(raw), raw);
    });

    test('لا يمسّ نصّاً إنجليزياً خالصاً', () {
      const String raw = 'Hello World by the way, so long!';
      expect(OcrTextPostProcessor.process(raw), raw);
    });
  });

  group('ج) التصحيحات العربية', () {
    test('يدمج «ال» المكرّرة', () {
      expect(OcrTextPostProcessor.process('الالرحمن'), 'الرحمن');
      expect(OcrTextPostProcessor.process('الالاله'), 'اله');
    });

    test('يدمج الواو المكرّرة', () {
      expect(OcrTextPostProcessor.process('ووكان'), 'وكان');
      expect(OcrTextPostProcessor.process('وو نص'), 'و نص');
    });

    test('يصحّح صيغ الشرف المشوّهة', () {
      expect(OcrTextPostProcessor.process('قال صلعم رضي الله عنه'),
          'قال ﷺ رضي الله عنه');
      expect(OcrTextPostProcessor.process('جلجلاله'), 'ﷻ');
    });

    test('يطوّي المسافات المتكرّرة ويزيل ما قبل الترقيم', () {
      expect(OcrTextPostProcessor.process('نص   فيه   مسافات'),
          'نص فيه مسافات');
      expect(OcrTextPostProcessor.process('أول ، ثاني'), 'أول، ثاني');
    });

    test('يدمج علامات الترقيم المكرّرة ويحفظ القاطع الثلاثي', () {
      expect(OcrTextPostProcessor.process('ممتاز!! حقاً..'), 'ممتاز! حقاً.');
      expect(OcrTextPostProcessor.process('انتظر ... قليلاً'), 'انتظر ... قليلاً');
      expect(OcrTextPostProcessor.process('فهو .... رائع'), 'فهو ... رائع');
    });

    test('يصحّح ازدواج الياء الأخير ويستثني الكلمات الصحيحة', () {
      // ازدواج الياء أثر قراءة مضاعف — يُصحَّح.
      expect(OcrTextPostProcessor.process('التقويى'), 'التقويي');
      // كلمات صحيحة تنتهي بـ`ى` لا تُمسّ إطلاقاً.
      expect(OcrTextPostProcessor.process('على المنبر'), 'على المنبر');
      expect(OcrTextPostProcessor.process('الأولى'), 'الأولى');
      expect(OcrTextPostProcessor.process('مصطفى'), 'مصطفى');
      expect(OcrTextPostProcessor.process('موسى'), 'موسى');
      expect(OcrTextPostProcessor.process('وعلى'), 'وعلى');
      // «الصفحة الأولى» سليمة بـ`ى` — قاعدة عامة كانت أفسدتها.
      expect(
        OcrTextPostProcessor.process('الصفحة الأولى نص'),
        'الصفحة الأولى نص',
      );
    });

    test('يزيل الرسم المتكرّر والمحارف غير المرئية', () {
      expect(OcrTextPostProcessor.process('كتـاب'), 'كتاب');
      // Zero-Width Space تُحذف بلا مسافة (لا تُقسّم الكلمة).
      expect(OcrTextPostProcessor.process('نص​خفي'), 'نصخفي');
      // مسافة NBSP تصير مسافة عادية (لا تُحذف كي لا تلتصق الكلمتان).
      expect(OcrTextPostProcessor.process('مس افة'), 'مس افة');
    });
  });

  group('د) الحالات الحدّية', () {
    test('النصّ الفارغ يُعاد فارغاً', () {
      expect(OcrTextPostProcessor.process(''), '');
    });

    test('النصّ السليم يُعاد كما هو (لا عمل للافارغ)', () {
      const String raw = 'بسم الله الرحمن الرحيم';
      expect(OcrTextPostProcessor.process(raw), raw);
    });

    test('الرقم في طرف السطر لا يُحذف — يُحوَّل هندياً (القاعدة 9)', () {
      // رقم بجوار عربي ليس «كلمة لاتينية» فلا يدخل باب الحذف أصلاً،
      // ويُحوَّله تحويل الأرقام الهندية غيراً لا منتمياً للرموز الوهمية.
      expect(OcrTextPostProcessor.process('عنوان 123'), 'عنوان ١٢٣');
      // بلا أي سياق عربي: لا تُمسّ أرقامه إطلاقاً.
      expect(OcrTextPostProcessor.process('123'), '123');
    });

    test('يحذف أكثر من سطرين متتاليين إلى سطرين', () {
      const String raw = 'أول\n\n\n\nثاني';
      expect(OcrTextPostProcessor.process(raw), 'أول\n\nثاني');
    });

    test('changed() تكشف ما إذا عُدِّل النصّ', () {
      expect(OcrTextPostProcessor.changed('هذا by نص', 'هذا نص'), isTrue);
      expect(OcrTextPostProcessor.changed('هذا نص', 'هذا نص'), isFalse);
    });
  });

  group('هـ) سيناريو المستند العربي الكامل', () {
    test('نصّ مستند ممزوج بالكامل يخرج نظيفاً', () {
      const String raw = 'دعوة  by حضور to المؤتمر  العلمي .. !!\n'
          'العنوان:   قاعة الملك عبدالله، الرياض ...\n'
          'التاريخ ١٤٤٧هـ على  land المكان  دal'
          '\n\n\nالتوقيع: د. مصطفى على المنبر';
      final String cleaned = OcrTextPostProcessor.process(raw);
      expect(cleaned.contains('by'), isFalse);
      expect(cleaned.contains('to'), isFalse);
      expect(cleaned.contains('land'), isFalse);
      expect(cleaned.contains('dal'), isFalse);
      expect(cleaned.contains('قاعة الملك عبدالله، الرياض ...'), isTrue);
      expect(cleaned.contains('مصطفى على المنبر'), isTrue);
      expect(cleaned.contains('\n\n\n'), isFalse);
    });

    test('يتناول نتيجة محرّك وهمي متعدّدة الصفحات (سطر لكل صفحة)', () {
      const String raw = 'الصفحة الأولى by نص\n\nالصفحة الثانية so نص';
      final String cleaned = OcrTextPostProcessor.process(raw);
      expect(cleaned, 'الصفحة الأولى نص\n\nالصفحة الثانية نص');
    });
  });

  // ==========================================================================
  //  و) التكامل مع متحكّم الشاشة
  // ==========================================================================

  group('و) التكامل: المعالج يعمل بعد كل استخراج', () {
    OcrResult dirtyResult() => const OcrResult(
      text: 'هذا by نص so مستخرج',
      confidence: 0.6,
      wordBoxes: <WordBox>[],
      language: 'ara+eng',
      elapsedMs: 100,
      imageWidth: 10,
      imageHeight: 10,
    );

    OcrResult cleanResult() => const OcrResult(
      text: 'بسم الله الرحمن الرحيم',
      confidence: 0.6,
      wordBoxes: <WordBox>[],
      language: 'ara',
      elapsedMs: 100,
      imageWidth: 10,
      imageHeight: 10,
    );

    Future<OcrController> controllerFor(OcrResult result) async {
      final OcrController controller = OcrController(
        engine: FakeOcrEngine(result: result),
      );
      addTearDown(controller.dispose);
      await controller.loadImageBytes(
        Uint8List.fromList(<int>[1, 2, 3]),
        name: 'test.png',
      );
      await controller.extract();
      return controller;
    }

    test('يعرض النصّ المصحّح لا الخام بعد الاستخراج', () async {
      final OcrController controller = await controllerFor(dirtyResult());
      expect(controller.editedText, 'هذا نص مستخرج');
      expect(controller.result!.text, 'هذا نص مستخرج');
      expect(controller.cleanupApplied, isTrue);
    });

    test('يحفظ الخام للمقارنة ويرجع إليه عند الطلب', () async {
      final OcrController controller = await controllerFor(dirtyResult());
      expect(controller.rawText, 'هذا by نص so مستخرج');
      controller.restoreRawText();
      expect(controller.editedText, 'هذا by نص so مستخرج');
      controller.revertToExtracted();
      expect(controller.editedText, 'هذا نص مستخرج');
    });

    test('لا يعلّم التنظيف حين يكون النصّ سليماً', () async {
      final OcrController controller = await controllerFor(cleanResult());
      expect(controller.cleanupApplied, isFalse);
      expect(controller.editedText, controller.rawText);
    });
  });
}
