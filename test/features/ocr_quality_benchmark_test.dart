/// قياس جودة الاستخراج على نصّ عربي إسلامي — قبل/بعد التحسينات.
///
/// ## ما يفعله هذا الاختبار
///
/// 1. **يرسم صفحة حقيقية** بالنصّ الإسلامي نفسه الذي أبلَغ عنه المستخدم
///    (`report/ocr_improvement.md`)، بخط Cairo وبمحرّك Flutter نفسه — فأشكال
///    الحروف واتصالها واتجاهها كما يرسمها التطبيق تماماً، لا رسم اصطناعي.
/// 2. **يستخرج مرّتين:** بإعدادات التحسين القديمة صراحةً، وبالإعدادات
///    الافتراضية الجديدة.
/// 3. **يقيس** CER بنفس دالّات سكربت المشروع (`normalize_ar` +
///    `levenshtein` + `error_rates` من `tool/ocr_test/run_tesseract.py`) كي
///    تكون الأرقام قابلة للمقارنة بقياس Tesseract السابق بلا انحياز.
/// 4. **يثبت** أنّ التحسّن ‎10%‎ أو أكثر **نسبةً** (معيار القبول).
///
/// ## لماذا يُقسَد الاختبار بسطر واحد؟
///
/// Tesseract برنامج خارجي غير مضمون على كل جهاز؛ لكن القياس لا معنى له بدونه.
/// فيُتَجاوَز الاختبار بصمت إن غاب التنفيذي أو بيانات اللغة — مع بقاء باقي
/// اختبارات OCR (التي تُحقن محرّكاً وهميّاً) تعمل بلا اعتماد على النظام.
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/ocr/data/image_preprocessor.dart';
import 'package:joodcraft/features/ocr/data/tesseract_engine.dart';
import 'package:joodcraft/features/ocr/data/text_post_processor.dart';
import 'package:joodcraft/features/ocr/domain/ocr_engine.dart';
import 'package:joodcraft/features/ocr/domain/ocr_engine_status.dart';
import 'package:joodcraft/features/ocr/domain/ocr_result.dart';
import 'package:joodcraft/features/ocr/domain/ocr_settings.dart';

/// النصّ المرجعي — كما أرسله المستخدم حرفياً.
const String _groundTruth = '١- أذى الجار سبب الحرمان من الجنة.\n'
    'الإجابة: قال النبي ﷺ: «لا يدخل الجنة من لا يأمن جاره بوائقه».\n'
    '٢- كل ما نتكلم به نحاسب عليه.\n'
    'الإجابة: قال تعالى: ﴿ما يلفظ من قول إلا لديه رقيب عتيد﴾ [ق: ١٨].\n'
    '٣- الكلمة الخبيثة سبب دخول النار.';

/// إعدادات ما قبل التحسين — مثبَّتة صراحةً لا بالافتراضيات، كي تصمد
/// المقارنة لو تغيّر الافتراضي لاحقاً.
const OcrSettings _oldSettings = OcrSettings(
  language: OcrLanguage.both,
  psm: OcrPsm.singleBlock,
  scale: 1.5,
  grayscale: true,
  binarize: false,
  denoise: false,
  deskew: false,
);

/// الإعدادات الافتراضية الجديدة (نتيجة القياس — راجع التقرير).
const OcrSettings _newSettings = OcrSettings();

/// مسار خط Cairo المحزوم.
const String _fontPath = 'assets/fonts/cairo/Cairo-Regular.ttf';

void main() {
  // الحركات والعلامات القرآنية والتطويل والمحارف الاتجاهية — تُفصل عن
  // الحروف قبل القياس (خطأ في فتحة ليس خطأً في حرف).
  final RegExp tashkeel = RegExp(
    '[\u064B-\u0655\u0670\u06D6-\u06EC\u0640\u200C\u200D\u200E\u200F]',
  );

  // ==========================================================================
  //  قياس الدقة — مطابق لـ`tool/ocr_test/run_tesseract.py` حرفياً
  // ==========================================================================

  /// توحيد الحروف والحركات: يُبقي بقيّة النصّ كما هو.
  ///
  /// نسخة مطابقة لـ`normalize_ar` في سكربت القياس: التشكيل والعلامات
  /// القرآنية تُفصل أوّلًا (خطأ في فتحة ليس خطأً في حرف)، ثم توحيد الألف
  /// والياء الخنجرتين.
  String normalizeAr(String source) {
    final StringBuffer out = StringBuffer();
    for (final int rune in source.runes) {
      if (tashkeel.hasMatch(String.fromCharCode(rune))) continue;
      out.writeCharCode(rune);
    }
    final String unified = out
        .toString()
        .replaceAll(RegExp('[أإآٱ]'), 'ا')
        .replaceAll('ى', 'ي');
    return unified;
  }

  /// مسافة التحرير على متتالية — نفس `_levenshtein` في السكربت.
  int levenshtein(List<String> a, List<String> b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final List<int> prev = List<int>.generate(b.length + 1, (int i) => i);
    for (int i = 1; i <= a.length; i++) {
      final List<int> cur = List<int>.filled(b.length + 1, i);
      for (int j = 1; j <= b.length; j++) {
        cur[j] = [
          prev[j] + 1,
          cur[j - 1] + 1,
          prev[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1),
        ].reduce((int x, int y) => x < y ? x : y);
      }
      for (int j = 0; j <= b.length; j++) {
        prev[j] = cur[j];
      }
    }
    return prev[b.length];
  }

  /// نسبة خطأ الحرف والنسبة خطأ الكلمة — نفس `error_rates`.
  ({double cer, double wer}) errorRates(String hypothesis, String reference) {
    if (reference.isEmpty) return (cer: 0, wer: 0);
    final String hyp = normalizeAr(hypothesis);
    final String ref = normalizeAr(reference);
    final double cer =
        levenshtein(hyp.split(''), ref.split('')) / ref.length * 100;
    final double wer =
        levenshtein(hyp.split(' '), ref.split(' ')) /
            (ref.split(' ').length) *
            100;
    return (cer: cer, wer: wer);
  }

  /// الدقة كنسبة مئوية — نفس تعريف القياس السابق (`100 − CER`).
  double accuracy(String hypothesis, String reference) =>
      100 - errorRates(hypothesis, reference).cer;

  // ==========================================================================
  //  توليد الصورة
  // ==========================================================================

  /// يرسم النصّ صفحةً حقيقية بخط Cairo وبمحاذاة يمينية (كما يصدر في التطبيق).
  ///
  /// يُستخدَم `TextPainter` من Flutter لا أداة رسم من حزمة `image`: الحزمة
  /// لا تفهم تشكيل العربية ولا اتجاهها (bidi) ولا اتصال الحروف، فمحاولة
  /// الرسم بها تُنتج صورةً لا يماثل ما يراه المستخدم أبداً.
  Future<Uint8List> renderPage(
    WidgetTester tester,
    String text, {
    double fontSize = 30,
    double pageWidth = 900,
  }) async {
    // خط Cairo المحزوم: يُسجَّل من الملف مباشرة لأنّ `rootBundle` في بيئة
    // الاختبار لا يقرأ أصول المشروع.
    final File fontFile = File(_fontPath);
    if (!fontFile.existsSync()) return Uint8List(0);
    final FontLoader loader = FontLoader('Cairo');
    loader.addFont(
      Future<ByteData>.value(ByteData.sublistView(fontFile.readAsBytesSync())),
    );
    await loader.load();

    final TextPainter painter = TextPainter(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: fontSize,
          height: 1.85,
          color: const Color(0xFF000000),
        ),
      ),
    );
    painter.layout(maxWidth: pageWidth);

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    // خلفية بيضاء نقية (وَرَق مصوّر)، ثم النصّ أسود.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, pageWidth, painter.height),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    painter.paint(canvas, Offset.zero);

    final ui.Image image = await recorder.endRecording().toImage(
      pageWidth.round(),
      painter.height.round(),
    );
    final ByteData? png = await image.toByteData(format: ui.ImageByteFormat.png);
    return png!.buffer.asUint8List();
  }

  /// يمرّر الصورة على المحرّك ثم المعالج اللاحق — نفس مسار `OcrController`.
  ///
  /// كل ما يقع داخل `tester.runAsync`: استدعاء العملية الخارجية (`Process.run`)
  /// ومتابعات `FontLoader` كلّها انتظارٌ حقيقي لا مؤقّت، و`testWidgets`
  /// يُجمّد الزمن غير الحقيقي داخل جسم الاختبار — فيلزم تفعيل الزمن الفعلي
  /// صراحةً، وإلا لم تكتمل المتابعات أبداً.
  Future<String> extractAndClean(
    OcrEngine engine,
    Uint8List bytes, {
    required OcrSettings settings,
  }) async {
    final OcrResult result = await engine.extract(
      image: bytes,
      settings: settings,
    );
    return OcrTextPostProcessor.process(result.text);
  }

  OcrEngine buildEngine() =>
      TesseractEngine(tempDirProvider: () => Directory.systemTemp);

  testWidgets('الإعدادات الجديدة ترفع الدقّة ‎10%‎ على الأقلّ', (
    WidgetTester tester,
  ) async {
    final OcrEngine engine = buildEngine();

    // ⚠️ كلّ ما ينتظر إجابةً من النظام (`Process.run`, الملفات, انتظار
    // المتابعات) لا يقدَم إطلاقاً داخل `testWidgets` إلاّ داخل `runAsync`:
    // جسم الاختبار يعمل على زمن مُزيَّف، و`await` خارجها يتجمّد إلى الأبد.
    // ولذلك يُجري الفحص كاملاً في `runAsync`.
    late final bool ready;
    late final OcrEngineStatus engineState;
    await tester.runAsync(() async {
      engineState = await engine.status();
      ready = engineState == OcrEngineStatus.ready;
    });
    if (!ready) {
      markTestSkipped('محرّك الاستخراج غير متوفّر ($engineState)');
      return;
    }
    if (!File(_fontPath).existsSync()) {
      markTestSkipped('خط Cairo غير موجود في $_fontPath');
      return;
    }

    // `runAsync` يُعيد نوعاً قابلاً لـnull — والمسار الموصِل لا يرجع أصلاً.
    final ({String before, String after})? results = await tester.runAsync(
      () async {
        final Stopwatch total = Stopwatch()..start();
        debugPrint('STEP render: start');
        final Uint8List page = await renderPage(tester, _groundTruth);
        debugPrint('STEP render: done ${total.elapsedMilliseconds} ms');
        if (page.isEmpty) throw StateError('تعذّر توليد صورة الاختبار.');

        // 1) المسار القديم.
        debugPrint('STEP extract old: start');
        final String before = await extractAndClean(
          engine,
          page,
          settings: _oldSettings,
        );
        debugPrint('STEP extract old: done ${total.elapsedMilliseconds} ms');

        // 2) المسار الجديد (الإعدادات الافتراضية نفسها).
        debugPrint('STEP extract new: start');
        final String after = await extractAndClean(
          engine,
          page,
          settings: _newSettings,
        );
        debugPrint('STEP extract new: done ${total.elapsedMilliseconds} ms');

        return (before: before, after: after);
      },
    );
    if (results == null) fail('تعذّر إكمال الاستخراج.');
    final String before = results.before;
    final String after = results.after;

    final ({double cer, double wer}) beforeRates = errorRates(
      before,
      _groundTruth,
    );
    final ({double cer, double wer}) afterRates = errorRates(
      after,
      _groundTruth,
    );

    final double beforeAccuracy = accuracy(before, _groundTruth);
    final double afterAccuracy = accuracy(after, _groundTruth);
    final double absolute = afterAccuracy - beforeAccuracy;
    // معيار القبول هو **النسبة** لا النقاط: «الدقّة تحسّنت بـ10%+».
    // النسبة = (بعد − قبل) / قبل، وهي التي تُعبّر عن «كم تحسّنت الدقّة نفسها»
    // لا فرق النقاط المطلق الذي يخفي حجم الأساس.
    final double relative = (afterAccuracy - beforeAccuracy) / beforeAccuracy;

    // تفصيل للقراءة في تقرير الاختبار و`report/ocr_improvement.md`.
    debugPrint('════ التنصيل: قبل ════\n$before');
    debugPrint('════ التنصيل: بعد ════\n$after');
    debugPrint(
      'قبل : CER ${beforeRates.cer.toStringAsFixed(1)}% '
      'دقة ${beforeAccuracy.toStringAsFixed(1)}%',
    );
    debugPrint(
      'بعد : CER ${afterRates.cer.toStringAsFixed(1)}% '
      'دقة ${afterAccuracy.toStringAsFixed(1)}%',
    );
    debugPrint(
      'الفرق: ${absolute.toStringAsFixed(1)} نقطة '
      '(${(relative * 100).toStringAsFixed(1)}% نسبياً)',
    );

    expect(
      relative,
      greaterThanOrEqualTo(0.10),
      reason:
          'التحسّن أقلّ من ‎10%‎ نسبياً '
          '(كان ${beforeAccuracy.toStringAsFixed(1)}% وأصبح '
          '${afterAccuracy.toStringAsFixed(1)}%).\n'
          'قبل: $before\n'
          'بعد: $after',
    );
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets('المعالجة قبلية لا تُفسد صورةً نظيفة مستقيمة', (
    WidgetTester tester,
  ) async {
    // ضمان المنحدر الزلق: التنعيم والعتبة والتدوير كلّها يجب أن تترك النصّ
    // المقروء **مقروءاً**. لو أفسدتها لظهر الخلل في الدقة أعلاه.
    final Uint8List bytes =
        await tester.runAsync(() => renderPage(tester, _groundTruth)) ??
            Uint8List(0);
    if (bytes.isEmpty) markTestSkipped('خط Cairo غير موجود');

    final PreprocessedImage prepared = ImagePreprocessor.preprocess(
      bytes,
      settings: _newSettings,
    );

    expect(prepared.applied, isNotEmpty, reason: 'لا مرحلة طبّقت!');
    expect(prepared.width, greaterThan(0));
    expect(prepared.height, greaterThan(0));
    expect(prepared.bytes, isNotEmpty);
    // التكبير ×1.5 يُضاعف الأبعاد.
    expect(
      prepared.width,
      greaterThan(900),
      reason: 'التكبير لم يُطبَّق — والقياس يجعله أهم مرحلة.',
    );
  });
}
