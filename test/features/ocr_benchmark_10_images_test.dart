/// المرحلة 5 — قياس شامل على ‎10‎ صور متنوعة بثلاث درجات صعوبة.
///
/// ## ما يفعله هذا الاختبار
///
/// 1. **يرسم** ‎10‎ نصوص عربية إسلامية بخط Cairo وبمحرّك Flutter نفسه —
///    فالحروف متّصلة ومشكّلة كما يرسمها التطبيق بالضبط، لا رسم اصطناعي.
/// 2. **يُدهِس** كل صورة تدهوراً مضبوطاً بحزمة `image` (تصغير، دوران، ضوضاء
///    غاوسية، تمويه، ضبابية حبر، ضغط JPEG) عبر **بذرة ثابتة** — فالنتيجة
///    قابلة لإعادة الإنتاج حرفياً على أيّ جهاز.
/// 3. **يستخرج مرّتين** لكل صورة: بالإعدادات القديمة صراحةً وبالحالية.
/// 4. **يقيس** CER وWER وزمن الاستخراج لكل صورة، ثم المتوسط والانحراف
///    المعياري، بنفس دالّات `tool/ocr_test/run_tesseract.py` كي تكون الأرقام
///    قابلة للمقارنة بقياس Tesseract السابق بلا انحياز.
///
/// ## لماذا الصور مولَّدة لا مصوّرة؟
///
/// لأنّ **المرجع** هو شرط القياس: لا يمكن قياس CER على صورة لا نعرف نصّها
/// حرفياً. والصور الفوتوغرافية الحقيقية في `tool/ocr_test` مقيسة وحدها في
/// `report/tesseract_benchmark.md` (‎42–100%‎ CER) وتخضع لقيود لا يملك
/// المعالج اللاحق حلّها — فمزيجٌ منهما يُخفي أثر التحسين بدل أن يكشفه.
///
/// ## الدرجات الثلاث
///
/// | درجة | الصور | ما يمثّله |
/// |------|-------|-----------|
/// | نظيفة | 3 | شاشة عرض / PDF نصّي — الحالة المثلى |
/// | متوسطة | 3 | صورة جوال لورقة مطبوعة |
/// | صعبة | 4 | مسح ضوئي قديم: صغير، مائل، مضوّج، مضغوط |
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:joodcraft/features/ocr/data/text_post_processor.dart';
import 'package:joodcraft/features/ocr/data/tesseract_engine.dart';
import 'package:joodcraft/features/ocr/domain/ocr_engine.dart';
import 'package:joodcraft/features/ocr/domain/ocr_engine_status.dart';
import 'package:joodcraft/features/ocr/domain/ocr_result.dart';
import 'package:joodcraft/features/ocr/domain/ocr_settings.dart';

// =============================================================================
//  مواصفة تدهور صورة واحدة
// =============================================================================

/// كلّ معاملات التدهور في سجلّ واحد: ما لا يُذكر يبقى على وضعه الحيادي.
typedef _Degradation = ({
  double resize, // معامل القياس الأصلي (1.0 = بلا تغيير)
  double rotate, // درجات — 0 تعني بلا دوران
  num noise, // انحراف معياري للضوضاء الغاوسية — 0 بلا
  int blur, // نصف قطر التمويه — 0 بلا
  int jpeg, // جودة JPEG — 0 يعني PNG بلا ضغط
  num fade, // ارتفاع نقطة السوداء (0..1) — يحاكي الحبر الباهت
});

/// تدهور حيادي: صورة سليمة كما هي.
const _Degradation _none = (
  resize: 1.0,
  rotate: 0,
  noise: 0,
  blur: 0,
  jpeg: 0,
  fade: 0,
);

/// صنف الصورة + نصّها المرجعي + معاملات تدهورها.
class _Sample {
  const _Sample({
    required this.name,
    required this.tier,
    required this.text,
    required this.fontSize,
    required this.deg,
  });

  final String name;
  final String tier; // نظيفة / متوسطة / صعبة
  final String text;
  final double fontSize;
  final _Degradation deg;
}

// =============================================================================
//  مجموعة الصور العشر
// =============================================================================

/// متن إسلامي متنوّع — من القرآن والحديث والأخلاق — كي لا يتحصّل التحسين
/// على نصّ واحد محفوظ.
///
/// **معايرة التدهور مقيسة لا تخمينية:** كلّ درجة مُضبَطت حتى يقع متوسط
/// CERّها في نطاق يقيس فعلاً (نظيفة ‎<8%‎، متوسطة ‎8–25%‎، صعبة ‎25–50%‎).
/// تدهورٌ أعنف من ذلك يجعل النصّ غير مقروء أصلاً (CER ‎≈ 100%‎) فلا يقيس
/// المعالج اللاحق شيئاً — وقد حدث أوّلاً حين رُفعت «بُعد الحبر» إلى ‎0.5‎
/// فخرجت أربع صور ميتة تماماً.
final List<_Sample> _samples = <_Sample>[
  // ---------------------------------------------------------------- نظيفة
  _Sample(
    name: 'img01_clean',
    tier: 'نظيفة',
    fontSize: 30,
    deg: _none,
    text: '١- أذى الجار سبب الحرمان من الجنة.\n'
        'الإجابة: قال النبي ﷺ: «لا يدخل الجنة من لا يأمن جاره بوائقه».',
  ),
  _Sample(
    name: 'img02_clean',
    tier: 'نظيفة',
    fontSize: 30,
    deg: _none,
    text: '٢- كل ما نتكلّم به نحاسب عليه.\n'
        'الإجابة: قال تعالى: ﴿ما يلفظ من قولٍ إلا لديه رقيبٌ عتيد﴾ [ق: ١٨].',
  ),
  _Sample(
    name: 'img03_clean',
    tier: 'نظيفة',
    fontSize: 30,
    deg: _none,
    text: '٣- الكلمة الطيّبة سبب دخول الجنة.\n'
        'قال تعالى: ﴿وقل اعملوا فسيرى الله عملكم ورسوله﴾ [التوبة: ١٠٥].',
  ),

  // ---------------------------------------------------------------- متوسطة
  _Sample(
    name: 'img04_medium',
    tier: 'متوسطة',
    fontSize: 30,
    deg: (resize: 0.85, rotate: 0, noise: 3, blur: 0, jpeg: 75, fade: 0),
    text: '٤- الصبر مفتاح الفرج.\n'
        'قال ﷺ: «عجبًا لأمر المؤمن إن أمره كله خير» [مسلم].',
  ),
  _Sample(
    name: 'img05_medium',
    tier: 'متوسطة',
    fontSize: 30,
    deg: (resize: 0.85, rotate: 1.5, noise: 3, blur: 1, jpeg: 72, fade: 0),
    text: 'الحمد لله رب العالمين الرحمن الرحيم مالك يوم الدين.\n'
        'إيّاك نعبد وإيّاك نستعين [ق: ٤-٥].',
  ),
  _Sample(
    name: 'img06_medium',
    tier: 'متوسطة',
    fontSize: 28,
    deg: (resize: 0.8, rotate: 0, noise: 4, blur: 1, jpeg: 65, fade: 0.1),
    text: '٥- برّ الوالدين من أعظم القربات.\n'
        'قال تعالى: ﴿و قضى ربك ألا تعبدوا إلا إيّاه وبالوالدين إحسانًا﴾.',
  ),

  // ---------------------------------------------------------------- صعبة
  _Sample(
    name: 'img07_hard',
    tier: 'صعبة',
    fontSize: 28,
    deg: (resize: 0.7, rotate: 0, noise: 5, blur: 1, jpeg: 52, fade: 0.12),
    text: '٦- مَن دلّل عالمة فقد فتن قرينه.\n'
        'الإجابة: ﴿ولقد يسّرنا القرآن للذكر فهل من مذكر﴾ [القمر: ١٧].',
  ),
  _Sample(
    name: 'img08_hard',
    tier: 'صعبة',
    fontSize: 26,
    deg: (resize: 0.68, rotate: 2.0, noise: 5, blur: 1, jpeg: 50, fade: 0.12),
    text: '٧- لا ضرر ولا ضرار.\n'
        'قال ﷺ: «لا يجلد اللسان أحدًا فوق جسدته» [رواه الترمذي].',
  ),
  _Sample(
    name: 'img09_hard',
    tier: 'صعبة',
    fontSize: 26,
    deg: (resize: 0.65, rotate: -1.8, noise: 6, blur: 1, jpeg: 46, fade: 0.15),
    text: 'قال تعالى: ﴿إنّ الحسنة تذهب السيئة﴾ [هود: ١١٤].\n'
        '٨- الميزان يوم القيامة أثقل من الكلمات.',
  ),
  _Sample(
    name: 'img10_hard',
    tier: 'صعبة',
    fontSize: 24,
    deg: (resize: 0.62, rotate: 1.8, noise: 6, blur: 1, jpeg: 44, fade: 0.15),
    text: '٩- الدعاء مخّ العبادة.\n'
        'الإجابة: قال تعالى: ﴿و إذ سألت عبادي عني فإنّي قريب﴾ [البقرة: ١٨٦].',
  ),
];

/// صفّ قياس واحد — نتيجة صورة قبل المعالجة الحالية وبعدها.
class _Row {
  const _Row({
    required this.name,
    required this.tier,
    required this.oldCer,
    required this.newCer,
    required this.oldWer,
    required this.newWer,
    required this.oldMs,
    required this.newMs,
  });

  final String name;
  final String tier;
  final double oldCer;
  final double newCer;
  final double oldWer;
  final double newWer;
  final int oldMs;
  final int newMs;
}

/// كل صفوف القياس — يُمرَّر خارج `runAsync` لأنّه يُجمّد الزمن.
typedef _Rows = List<_Row>;

// =============================================================================
//  إعدادات ما قبل التحسين — مثبَّتة صراحةً لا بالافتراضيات
// =============================================================================

/// نفس `_oldSettings` في `ocr_quality_benchmark_test.dart`: لغة `ara+eng`
/// وPSM 6 ومعالجة قبلية جزئية بلا تعدد ممرّات.
const OcrSettings _oldSettings = OcrSettings(
  language: OcrLanguage.both,
  psm: OcrPsm.singleBlock,
  scale: 1.5,
  grayscale: true,
  binarize: false,
  denoise: false,
  deskew: false,
  multiPass: false,
  contrast: false,
);

/// الإعدادات الافتراضية الحالية (نتيجة القياس — راجع التقرير).
const OcrSettings _newSettings = OcrSettings();

const String _fontPath = 'assets/fonts/cairo/Cairo-Regular.ttf';

void main() {
  // ---------------------------------------------------------------------------
  //  المقاييس — مطابقة لـ`tool/ocr_test/run_tesseract.py` حرفياً
  // ---------------------------------------------------------------------------

  final RegExp tashkeel = RegExp(
    '[\u064B-\u0655\u0670\u06D6-\u06EC\u0640\u200C\u200D\u200E\u200F]',
  );

  String normalizeAr(String source) {
    final StringBuffer out = StringBuffer();
    for (final int rune in source.runes) {
      if (tashkeel.hasMatch(String.fromCharCode(rune))) continue;
      out.writeCharCode(rune);
    }
    return out
        .toString()
        .replaceAll(RegExp('[أإآٱ]'), 'ا')
        .replaceAll('ى', 'ي');
  }

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

  ({double cer, double wer}) errorRates(String hypothesis, String reference) {
    if (reference.isEmpty) return (cer: 0, wer: 0);
    final String hyp = normalizeAr(hypothesis);
    final String ref = normalizeAr(reference);
    return (
      cer: levenshtein(hyp.split(''), ref.split('')) / ref.length * 100,
      wer: levenshtein(hyp.split(' '), ref.split(' ')) /
          ref.split(' ').length *
          100,
    );
  }

  /// الانحراف المعياري لمتوسط العيّنة (Bessel) — يُظهر تشتّت الصور لا متوسطها
  /// وحده؛ فمتوسط ‎5%‎ على صورتين نظيفتين وصعبتين ‎15%‎ يخفي كارثةً.
  double stddev(List<double> values) {
    if (values.length < 2) return 0;
    final double mean =
        values.reduce((double a, double b) => a + b) / values.length;
    final double sum = values
        .map((double v) => (v - mean) * (v - mean))
        .reduce((double a, double b) => a + b);
    return math.sqrt(sum / (values.length - 1));
  }

  // ---------------------------------------------------------------------------
  //  الرسم والتجهيز
  // ---------------------------------------------------------------------------

  /// يرسم النصّ صفحةً بخط Cairo ويحوّلها إلى بايتات صورة.
  ///
  /// لا تشكيل يدوي ولا إعادة ترتيب: Flutter يطبّق تشكيل العربية وترتيبها
  /// ثنائي الاتجاه بنفسه، وأيّ تدخّل يدوي فوقه يُنتج نصّاً معكوساً.
  Future<Uint8List> renderPage(String text, double fontSize) async {
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
    )..layout(maxWidth: 900);

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 900, painter.height),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    painter.paint(canvas, Offset.zero);

    final ui.Image image = await recorder
        .endRecording()
        .toImage(900.round(), painter.height.round());
    final ByteData? png = await image.toByteData(format: ui.ImageByteFormat.png);
    return png!.buffer.asUint8List();
  }

  /// يطبّق التدهور المضبوط — **بذرة ثابتة** كي تتّسق الضوضاء بين المرّات.
  ///
  /// ⚠️ **أخطاء قِيست لا اعتُمدت** (كلّها أسودت الصورة فقِيست ‎CER ≈ 100%‎
  /// قبل أن تُضبط — البايتات وحدها كشفتها: صفحة نصّ ‎2 KB‎ تعني صورة موحّدة):
  ///
  /// 1. `copyRotate` يملأ ما حول الصورة بلون `backgroundColor`، وهو `null`
  ///    فيملأ **أسود**. والإصلاح: ضبط الخلفية بيضاء قبل الدوران صراحةً.
  /// 2. `copyRotate` يفترض `Interpolation.nearest` افتراضياً، وهو يصنع
  ///    سُلّم الحافّات — دمارٌ خاصّ بالحرف العربي المتّصل لا بشيء آخر.
  /// 3. `adjustColor(blacks:)` **لا تمدّ المدى بل تُعيد تعيينه**، فجعلت
  ///    الصورة سوداء كلّها (أقصى قيمة ‎4/255‎). والحبر الباهت يُحاكى
  ///    بضغطٍ صريح للمدى الرماديّ نحو الأعلى.
  Uint8List degrade(Uint8List pngBytes, _Degradation deg) {
    img.Image? source = img.decodeImage(pngBytes);
    if (source == null) return pngBytes;

    if (deg.rotate != 0) {
      source.backgroundColor = img.ColorRgb8(255, 255, 255);
      source = img.copyRotate(source, angle: deg.rotate, interpolation: img.Interpolation.linear);
    }
    if (deg.resize != 1.0) {
      source = img.copyResize(
        source,
        width: math.max(1, (source.width * deg.resize).round()),
        interpolation: img.Interpolation.linear,
      );
    }
    if (deg.fade != 0) {
      // الحبر الباهت: يُرفع حدّ الأسود وحده — الحبر يصير رمادياً والورق
      // يبقى أبيض، فتنكمش المدى الرماديّ كلّه نحو الورق.
      final num k = 1 - deg.fade;
      for (final img.Pixel p in source) {
        p.setRgb(
          255 - (255 - p.r) * k,
          255 - (255 - p.g) * k,
          255 - (255 - p.b) * k,
        );
      }
    }
    if (deg.noise != 0) {
      // بذرة مثبّتة: `Random(0)` يجعل الضوضاء نفسها بالضبط في كل تشغيل،
      // وإلّا لكان لكل صورة نتيجة مختلفة ولا معنى للجدول.
      source = img.noise(source, deg.noise, random: math.Random(0));
    }
    if (deg.blur != 0) {
      source = img.gaussianBlur(source, radius: deg.blur);
    }
    if (deg.jpeg != 0) {
      return img.encodeJpg(source, quality: deg.jpeg);
    }
    return img.encodePng(source);
  }

  /// يمرّر الصورة على المحرّك ثم المعالج اللاحق — نفس مسار `OcrController`.
  ///
  /// كل ما يقع داخل `tester.runAsync`: `Process.run` انتظارٌ حقيقي، و`testWidgets`
  /// يُجمّد الزمن غير الحقيقي داخل جسم الاختبار.
  Future<({String text, int ms})> extract(
    OcrEngine engine,
    Uint8List bytes, {
    required OcrSettings settings,
    required bool useDictionary,
  }) async {
    final OcrResult result = await engine.extract(image: bytes, settings: settings);
    return (
      text: OcrTextPostProcessor.process(result.text, useDictionary: useDictionary),
      ms: result.elapsedMs,
    );
  }

  OcrEngine buildEngine() =>
      TesseractEngine(tempDirProvider: () => Directory.systemTemp);

  // ==========================================================================
  //  القياس
  // ==========================================================================

  testWidgets('المعالجة الحالية تتفوّق على القديمة على ‎10‎ صور متنوعة', (
    WidgetTester tester,
  ) async {
    final OcrEngine engine = buildEngine();

    late final bool ready;
    await tester.runAsync(() async {
      ready = await engine.status() == OcrEngineStatus.ready;
    });
    if (!ready) {
      markTestSkipped('محرّك الاستخراج غير متوفّر');
      return;
    }
    if (!File(_fontPath).existsSync()) {
      markTestSkipped('خط Cairo غير موجود في $_fontPath');
      return;
    }

    final _Rows? measured = await tester.runAsync(() async {
      final List<_Row> out = <_Row>[];

      for (final _Sample sample in _samples) {
        final Uint8List png = await renderPage(sample.text, sample.fontSize);
        if (png.isEmpty) throw StateError('تعذّر توليد ${sample.name}.');
        final Uint8List bytes = degrade(png, sample.deg);

        final ({String text, int ms}) old = await extract(
          engine,
          bytes,
          settings: _oldSettings,
          useDictionary: false,
        );
        final ({String text, int ms}) fresh = await extract(
          engine,
          bytes,
          settings: _newSettings,
          useDictionary: true,
        );

        final ({double cer, double wer}) o = errorRates(old.text, sample.text);
        final ({double cer, double wer}) n = errorRates(fresh.text, sample.text);
        out.add(
          _Row(
            name: sample.name,
            tier: sample.tier,
            oldCer: o.cer,
            newCer: n.cer,
            oldWer: o.wer,
            newWer: n.wer,
            oldMs: old.ms,
            newMs: fresh.ms,
          ),
        );
      }
      return out;
    });
    final List<_Row> rows = measured ?? <_Row>[];
    if (rows.isEmpty) fail('تعذّر إكمال القياس.');

    // -------------------------------------------------------------------------
    //  الجدول
    // -------------------------------------------------------------------------

    final StringBuffer table = StringBuffer()
      ..writeln('')
      ..writeln('┌─────────────────┬──────────┬───────────────────'
          '┬───────────────────┬────────────┐')
      ..writeln('│ الصورة          │ الدرجة   │     CER قبل/بعد  '
          '│     WER قبل/بعد  │ زمن (قبل/بعد)│')
      ..writeln('├─────────────────┼──────────┼───────────────────'
          '┬───────────────────┼────────────┤');
    for (final _Row r in rows) {
      table.writeln(
        '│ ${r.name.padRight(15)} │ '
        '${r.tier.padRight(8)} │ '
        '${r.oldCer.toStringAsFixed(1).padLeft(6)}% → '
        '${r.newCer.toStringAsFixed(1).padLeft(6)}% │ '
        '${r.oldWer.toStringAsFixed(1).padLeft(6)}% → '
        '${r.newWer.toStringAsFixed(1).padLeft(6)}% │ '
        '${r.oldMs.toString().padLeft(5)}/'
        '${r.newMs.toString().padLeft(5)} │',
      );
    }
    table.writeln('└─────────────────┴──────────┴───────────────────'
        '┴───────────────────┴────────────┘');

    double meanOf(double Function(_Row) pick) =>
        rows.map(pick).reduce((double a, double b) => a + b) / rows.length;

    final double oldCerMean = meanOf((_Row r) => r.oldCer);
    final double newCerMean = meanOf((_Row r) => r.newCer);
    final double oldWerMean = meanOf((_Row r) => r.oldWer);
    final double newWerMean = meanOf((_Row r) => r.newWer);
    final double oldMsMean = meanOf((_Row r) => r.oldMs.toDouble());
    final double newMsMean = meanOf((_Row r) => r.newMs.toDouble());

    table
      ..writeln('')
      ..writeln('المتوسط العام   '
          'CER ${oldCerMean.toStringAsFixed(2)}% → '
          '${newCerMean.toStringAsFixed(2)}%  '
          '(Δ ${(oldCerMean - newCerMean).toStringAsFixed(2)} نقطة، '
          '${((oldCerMean - newCerMean) / oldCerMean * 100).toStringAsFixed(1)}% نسبةً)')
      ..writeln('                 '
          'WER ${oldWerMean.toStringAsFixed(2)}% → '
          '${newWerMean.toStringAsFixed(2)}%')
      ..writeln('الانحراف المعياري لـCER  '
          'قبل ${stddev(rows.map((_Row r) => r.oldCer).toList()).toStringAsFixed(2)} '
          'بعد ${stddev(rows.map((_Row r) => r.newCer).toList()).toStringAsFixed(2)}')
      ..writeln('زمن الاستخراج    '
          '${oldMsMean.toStringAsFixed(0)} ms → '
          '${newMsMean.toStringAsFixed(0)} ms للصفحة');

    double tierMean(String tier, double Function(_Row) pick) {
      final List<_Row> group = rows.where((_Row r) => r.tier == tier).toList();
      if (group.isEmpty) return 0;
      return group.map(pick).reduce((double a, double b) => a + b) /
          group.length;
    }

    for (final String tier in <String>['نظيفة', 'متوسطة', 'صعبة']) {
      final int count = rows.where((_Row r) => r.tier == tier).length;
      if (count == 0) continue;
      table.writeln('  $tier ($count صور): '
          'CER ${tierMean(tier, (_Row r) => r.oldCer).toStringAsFixed(2)}% → '
          '${tierMean(tier, (_Row r) => r.newCer).toStringAsFixed(2)}%');
    }

    debugPrint(table.toString());

    // -------------------------------------------------------------------------
    //  معيار القبول
    // -------------------------------------------------------------------------

    // التحسين يُقاس **نسبةً** لا بنقاط مطلقة: «انخفض CER بـ20%+» عبارة عن
    // تحسين في أداء المعالج نفسه مهما كان حجم الأساس، والنقاط المطلقة
    // تُخفي تحسيناً كبيراً على أساس صغير وبالعكس.
    final double relative =
        (oldCerMean - newCerMean) / oldCerMean * 100;
    expect(
      relative,
      greaterThan(15),
      reason: 'انخفاض CER النسبي ${relative.toStringAsFixed(1)}% — '
          'الحدّ الأدنى 15%. التفاصيل في الجدول أعلاه.',
    );

    // لا تدهور على أيّ درجة من درجات الصعوبة الثلاث — وإلّا كان التحسين
    // مكتسباً على درجة واحدة وفادحاً على أخرى.
    for (final String tier in <String>['نظيفة', 'متوسطة', 'صعبة']) {
      final double o = tierMean(tier, (_Row r) => r.oldCer);
      final double n = tierMean(tier, (_Row r) => r.newCer);
      if (o == 0 && n == 0) continue;
      expect(
        n,
        lessThanOrEqualTo(o + 0.5),
        reason: 'تدهور في درجة «$tier»: '
            '${o.toStringAsFixed(2)}% ← ${n.toStringAsFixed(2)}%',
      );
    }

    // حدّ الزمن: الاستخراج يبقى عمليّاً على شاشة الجوال.
    expect(
      newMsMean,
      lessThan(8000),
      reason: 'زمن الاستخراج ${newMsMean.toStringAsFixed(0)} ms '
          'فوق الحدّ العملي — التعدّد متعدّد الممرّات وقد يُخفَّض.',
    );
  });
}
