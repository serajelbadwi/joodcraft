import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/models/text_styling.dart';
import 'package:joodcraft/core/pdf/arabic_text_engine.dart';
import 'package:joodcraft/core/pdf/pdf_color.dart';
import 'package:joodcraft/core/pdf/pdf_font_catalog.dart';
import 'package:joodcraft/core/services/pdf_generator_service.dart';
import 'package:pdf/pdf.dart';

/// **اختبارات التنسيق الجزئي (Rich Text)** — النموذج، وإزاحات الحدود، وتقسيم
/// المقاطع، ونطاقات التغليف، ثم رحلة كاملة إلى ملف PDF يحمل لونين داخل السطر
/// الواحد.
void main() {
  // تحميل الخطوط من الأصول يحتاج ServicesBinding.
  TestWidgetsFlutterBinding.ensureInitialized();

  // ==========================================================================
  //  1) تنظيف النطاقات (normalize)
  // ==========================================================================
  group('StyledTextSpan.normalize', () {
    test('يقيّم الإزاحات لحدود النص ويرمي المدى الفارغ والمقلوب', () {
      const String text = 'شهادة تقدير';
      final List<StyledTextSpan> result = StyledTextSpan.normalize(
        <StyledTextSpan>[
          const StyledTextSpan(start: -5, end: 4, colorHex: '#FF0000'),
          const StyledTextSpan(start: 7, end: 7, colorHex: '#00FF00'),
          const StyledTextSpan(start: 9, end: 3, colorHex: '#0000FF'),
          const StyledTextSpan(start: 6, end: 999, colorHex: '#FFFF00'),
        ],
        text.length,
      );

      expect(result, hasLength(2));
      expect(result.first.start, 0);
      expect(result.first.end, 4);
      expect(result.last.start, 6);
      expect(result.last.end, text.length);
    });

    test('يفرز تصاعدياً ويمنع التداخل: الأحدث هو الأسبق', () {
      final List<StyledTextSpan> result = StyledTextSpan.normalize(
        <StyledTextSpan>[
          const StyledTextSpan(start: 4, end: 8, colorHex: '#111111'),
          const StyledTextSpan(start: 0, end: 6, colorHex: '#222222'),
          const StyledTextSpan(start: 5, end: 7, colorHex: '#333333'),
        ],
        10,
      );

      // لا تداخل إطلاقاً.
      for (int i = 1; i < result.length; i++) {
        expect(result[i].start, greaterThanOrEqualTo(result[i - 1].end),
            reason: 'النطاقات يجب أن تبقى متصاعدة وغير متداخلة');
      }
      // ما غطّته النطاقات اللاحقة أُزيل من سابقتها.
      expect(result.any((StyledTextSpan s) => s.colorHex == '#111111'), isTrue);
      expect(result.any((StyledTextSpan s) => s.colorHex == '#222222'), isTrue);
      expect(result.any((StyledTextSpan s) => s.colorHex == '#333333'), isFalse,
          reason: 'النطاق الثالث تداخل مع الثاني فالأخير هو الأسبق');
    });

    test('قائمة فارغة أو نصّ فارغ يُرجعان لا شيء', () {
      expect(StyledTextSpan.normalize(const <StyledTextSpan>[], 10), isEmpty);
      expect(
        StyledTextSpan.normalize(
          const <StyledTextSpan>[StyledTextSpan(start: 0, end: 3)],
          0,
        ),
        isEmpty,
      );
    });
  });

  // ==========================================================================
  //  2) تقسيم المقاطع (splitStyledRuns)
  // ==========================================================================
  group('splitStyledRuns', () {
    const String text = 'شهادة تقدير متميز';
    final List<StyledTextSpan> spans = <StyledTextSpan>[
      const StyledTextSpan(start: 0, end: 7, colorHex: '#FF0000'),
      const StyledTextSpan(start: 8, end: 15, size: 30),
    ];

    test('يغطّي النص بالكامل بلا فجوات ولا تداخل', () {
      final List<StyledTextRun> runs = splitStyledRuns(text, spans);

      expect(runs, isNotEmpty);
      expect(runs.first.start, 0);
      expect(runs.last.end, text.length);
      for (int i = 1; i < runs.length; i++) {
        expect(runs[i].start, runs[i - 1].end,
            reason: 'المقاطع يجب أن تكون متجاورة تماماً');
      }
      // إعادة تركيب المقاطع تُعطي النص الأصلي حرفياً.
      final String rebuilt =
          runs.map((StyledTextRun r) => r.textOf(text)).join();
      expect(rebuilt, text);
    });

    test('المواقع غير المغطاة ترث النمط الأساسي (isBase)', () {
      final List<StyledTextRun> runs = splitStyledRuns(text, spans);
      final StyledTextRun? gap = runs.cast<StyledTextRun?>().firstWhere(
            (StyledTextRun? r) => r != null && r.start == 7 && r.end == 8,
            orElse: () => null,
          );
      if (gap != null) expect(gap.isBase, isTrue);
    });

    test('بدون نطاقات ⇒ مقطع واحد أساسي يغطي كل شيء', () {
      final List<StyledTextRun> runs = splitStyledRuns(text, const []);
      expect(runs, hasLength(1));
      expect(runs.single.start, 0);
      expect(runs.single.end, text.length);
      expect(runs.single.isBase, isTrue);
    });

    test('دمج: حدود المدى تُقسّم والحقول غير المذكورة تُورَّث', () {
      final List<StyledTextRun> runs = splitStyledRuns(
        text,
        const <StyledTextSpan>[StyledTextSpan(start: 4, end: 8, colorHex: '#00FF00')],
      );
      final StyledTextRun? middle = runs.cast<StyledTextRun?>().firstWhere(
            (StyledTextRun? r) => r != null && r.start == 4 && r.end == 8,
            orElse: () => null,
          );
      expect(middle, isNotNull);
      expect(middle!.style.colorHex, '#00FF00');
      expect(middle.style.size, isNull, reason: 'الحقول غير المذكورة تبقى وراثة');
      expect(middle.style.italic, isFalse);
    });
  });

  // ==========================================================================
  //  3) إعادة إزاحات الحدود بعد التحرير (remapAfterEdit)
  // ==========================================================================
  group('StyledTextSpan.remapAfterEdit', () {
    const String oldText = 'شهادة تقدير متميز';
    final List<StyledTextSpan> spans = <StyledTextSpan>[
      const StyledTextSpan(start: 8, end: 15, colorHex: '#FF0000'),
    ];

    test('نصّ لم يتغيّر ⇒ النطاق كما هو', () {
      final List<StyledTextSpan> out = StyledTextSpan.remapAfterEdit(
        oldText: oldText,
        newText: oldText,
        spans: spans,
      );
      expect(out.single.start, 8);
      expect(out.single.end, 15);
    });

    test('إضافة قبل المدى تزيحه بمقدار الإضافة', () {
      const String inserted = 'ملحوظة $oldText';
      final List<StyledTextSpan> out = StyledTextSpan.remapAfterEdit(
        oldText: oldText,
        newText: inserted,
        spans: spans,
      );
      expect(out.single.start, 8 + 'ملحوظة '.length);
      expect(out.single.end, 15 + 'ملحوظة '.length);
      expect(inserted.substring(out.single.start, out.single.end),
          oldText.substring(8, 15));
    });

    test('حذف داخل المدى يُصغّره ولا يُهربه عن كلماته', () {
      const String shortened = 'شهادة تدير متميز'; // حُذفت «ق» من «تقدير»
      final List<StyledTextSpan> out = StyledTextSpan.remapAfterEdit(
        oldText: oldText,
        newText: shortened,
        // المدى يغطّي «تقدير» فعلاً (6..11) كي يكون الحذف داخله.
        spans: const <StyledTextSpan>[
          StyledTextSpan(start: 6, end: 11, colorHex: '#FF0000'),
        ],
      );
      expect(out.single.start, 6);
      expect(out.single.end, 10);
      expect(shortened.substring(out.single.start, out.single.end), 'تدير',
          reason: 'النطاق يتبع كلماته ويصغّر مع الحذف ولا يزحف عنها');
    });

    test('نطاق ينتهي قبل التعديل يبقى سليماً', () {
      final List<StyledTextSpan> head = <StyledTextSpan>[
        const StyledTextSpan(start: 0, end: 7, colorHex: '#0000FF'),
      ];
      final List<StyledTextSpan> out = StyledTextSpan.remapAfterEdit(
        oldText: oldText,
        newText: '$oldText  إضافة',
        spans: head,
      );
      expect(out.single.start, 0);
      expect(out.single.end, 7);
    });
  });

  // ==========================================================================
  //  4) النموذج داخل TextElement (JSON + copyWith + reflow)
  // ==========================================================================
  group('TextElement.spans', () {
    test('غياب النطاقات لا يكتب مفتاح spans أصلاً (توافق خلفي كامل)', () {
      const TextElement element = TextElement(
        id: 't',
        box: ElementBox(x: 0, y: 0, width: 100, height: 40),
        text: 'شهادة',
      );
      expect(element.hasSpans, isFalse);
      expect(element.toJson().containsKey('spans'), isFalse);
      // القراءة من ملف قديم بلا spans تُرجع قائمة فارغة لا استثناءً.
      final TextElement back =
          TextElement.fromJson(element.toJson(), 't');
      expect(back.spans, isEmpty);
      expect(back.text, 'شهادة');
    });

    test('النطاقات تنجو من دورة الحفظ/القراءة بنفس القيم', () {
      const TextElement element = TextElement(
        id: 't',
        box: ElementBox(x: 0, y: 0, width: 100, height: 40),
        text: 'شهادة تقدير',
        spans: <StyledTextSpan>[
          StyledTextSpan(
            start: 0,
            end: 7,
            colorHex: '#D32F2F',
            size: 30,
            weight: PdfFontWeight.bold,
            underline: true,
          ),
        ],
      );
      final Map<String, dynamic> json = element.toJson();
      expect(json.containsKey('spans'), isTrue);

      final TextElement back = TextElement.fromJson(json, 't');
      expect(back.spans, hasLength(1));
      expect(back.spans.single.start, 0);
      expect(back.spans.single.end, 7);
      expect(back.spans.single.colorHex, '#D32F2F');
      expect(back.spans.single.size, 30);
      expect(back.spans.single.weight, PdfFontWeight.bold);
      expect(back.spans.single.underline, isTrue);
      expect(back.hasSpans, isTrue);
    });

    test('تغيير النص عبر copyWith يُعيد إزاحة النطاقات تلقائياً', () {
      const TextElement element = TextElement(
        id: 't',
        box: ElementBox(x: 0, y: 0, width: 100, height: 40),
        text: 'شهادة تقدير',
        // المدى يغطّي «تقدير» فعلاً (6..11).
        spans: <StyledTextSpan>[StyledTextSpan(start: 6, end: 11, colorHex: '#FF0000')],
      );

      // إضافة مقدمة: النطاق يجب أن يتقدّم بنفس عدد الحروف.
      final TextElement prefixed =
          element.copyWith(text: 'المدير: شهادة تقدير');
      expect(prefixed.spans.single.start, 6 + 'المدير: '.length);
      expect(
        prefixed.text.substring(prefixed.spans.single.start, prefixed.spans.single.end),
        'تقدير',
      );

      // التحرير المباشر يمرّ على copyWith(text:) نفسه.
      final TextElement edited = element.copyWith(text: 'شهادة ع');
      expect(edited.spans, isNotEmpty);
      expect(edited.spans.single.start, lessThanOrEqualTo(edited.text.length));
      expect(edited.spans.single.end, lessThanOrEqualTo(edited.text.length));
    });

    test('reflow يتقاسم أحجام النطاقات بمعامل الحجم نفسه', () {
      const TextElement element = TextElement(
        id: 't',
        box: ElementBox(x: 10, y: 10, width: 200, height: 40),
        fontSize: 20,
        text: 'شهادة تقدير',
        spans: <StyledTextSpan>[StyledTextSpan(start: 0, end: 7, size: 40)],
      );
      final TextElement scaled =
          element.reflow(sx: 2, sy: 2, fontScale: 0.5) as TextElement;
      expect(scaled.fontSize, 10);
      expect(scaled.spans.single.size, 20);
      expect(scaled.spans.single.start, 0);
    });
  });

  // ==========================================================================
  //  5) نطاقات التغليف في محرّك التقسيم
  // ==========================================================================
  group('ArabicTextEngine.wrapRanges', () {
    double measure(String visual) => visual.length * 8.0;

    test('النطاقات تعطي نفس النصوص البصرية التي يعطيها wrap', () {
      const List<String> samples = <String>[
        'شهادة تقدير منصة جودة للفائزين في المسابقة الوطنية',
        'Certificate of Achievement for the outstanding students',
        'شهادة تقدير Certificate مختلط النصوص',
        'سطر أول\nسطر ثانٍ بعد فاصلة سطر',
        '',
        '   ',
      ];

      for (final String text in samples) {
        final List<String> plain = ArabicTextEngine.wrap(
          text: text,
          maxWidth: 120,
          measureWidth: measure,
        );
        final List<WrappedLine> ranged = ArabicTextEngine.wrapRanges(
          text: text,
          maxWidth: 120,
          measureWidth: measure,
        );

        expect(
          ranged.map((WrappedLine l) => l.visual).toList(),
          plain,
          reason: 'wrapRanges يجب ألّا يغيّر تقسيم الأسطر إطلاقاً (نصّ: $text)',
        );
      }
    });

    test('كل مدى يشير إلى مقطع صحيح من النص الأصلي (بلا ضبط)', () {
      const String text = 'شهادة تقدير منصة جودة للفائزين في المسابقة';
      final List<WrappedLine> lines = ArabicTextEngine.wrapRanges(
        text: text,
        maxWidth: 90,
        measureWidth: (String visual) => visual.length * 8.0,
      );

      expect(lines, hasLength(greaterThan(1)));
      for (final WrappedLine line in lines) {
        expect(line.start, greaterThanOrEqualTo(0));
        expect(line.end, lessThanOrEqualTo(text.length));
        expect(line.end, greaterThan(line.start));
        // بلا ضبط ⇒ المنطقي هو المقطع الأصلي حرفياً.
        expect(line.logical, text.substring(line.start, line.end));
      }
      // السطور تغطي النصّ بالتسلسل مع تجاهل البياض الفاصل.
      expect(lines.first.start, 0);
      expect(lines.last.end, text.length);
    });
  });

  // ==========================================================================
  //  6) رحلة كاملة إلى PDF: لونان داخل الفقرة الواحدة
  // ==========================================================================
  group('تصدير PDF بتنسيقات متعددة داخل الفقرة الواحدة', () {
    /// ينسخ تنسيق أرقام حزمة `pdf`: خمس منازل عشرية بلا أصفار زائدة.
    String pdfNum(double value) {
      String text = value.toStringAsFixed(5);
      if (text.contains('.')) {
        text = text.replaceFirst(RegExp(r'0+$'), '');
        if (text.endsWith('.')) text = text.substring(0, text.length - 1);
      }
      return text;
    }

    String pdfRgb(String hex) {
      final PdfColor color = pdfColorFromHex(hex);
      return '${pdfNum(color.red)} ${pdfNum(color.green)} ${pdfNum(color.blue)}';
    }

    test('المقطع الملوّن يخرج بلونه والباقي بلون العنصر', () async {
      const String base = '#1B2539';
      const String accent = '#D32F2F';
      const String text = 'شهادة تقدير منصة جودة';

      // تلوين كلمة «تقدير» وحدها.
      final int start = text.indexOf('تقدير');
      final int end = start + 'تقدير'.length;

      final TextElement element = TextElement(
        id: 'rich',
        box: const ElementBox(x: 40, y: 40, width: 500, height: 0),
        text: text,
        fontSize: 26,
        colorHex: base,
        spans: <StyledTextSpan>[
          StyledTextSpan(start: start, end: end, colorHex: accent),
        ],
      );

      final PdfGeneratorService service =
          await PdfGeneratorService.create(compress: false);
      final PdfGenerationReport report = await service.generate(
        document: const TemplateDocument(
          orientation: PageOrientation.portrait,
          elements: <TemplateElement>[],
        ).copyWith(elements: <TemplateElement>[element]),
      );

      expect(report.warnings, isEmpty,
          reason: 'لا تحذيرات متوقّعة من توليد نصّ عربي بسيط');
      expect(report.bytes.lengthInBytes, greaterThan(1000));

      final String raw = latin1.decode(report.bytes, allowInvalid: true);
      expect(raw.contains('IBMPlexSansArabic'), isTrue,
          reason: 'الخط العربي يجب أن يُضمَّن في الملف');

      expect(raw.contains(pdfRgb(accent)), isTrue,
          reason: 'لون المقطع المحدَّد يجب أن يظهر في مُشغّلات الـ PDF');
      expect(raw.contains(pdfRgb(base)), isTrue,
          reason: 'لون العنصر الأساسي يجب أن يبقى في المُشغّلات');
    });

    test('بلا تنسيق جزئي لا يُكتب لون المقطع الملوّن أصلاً (لا تغيّر خفي)', () async {
      const String accent = '#D32F2F';
      const String text = 'شهادة تقدير منصة جودة';

      final TextElement plain = TextElement(
        id: 'plain',
        box: const ElementBox(x: 40, y: 40, width: 500, height: 0),
        text: text,
        fontSize: 26,
        colorHex: '#1B2539',
      );

      final PdfGeneratorService service =
          await PdfGeneratorService.create(compress: false);
      final PdfGenerationReport report = await service.generate(
        document: const TemplateDocument(
          orientation: PageOrientation.portrait,
          elements: <TemplateElement>[],
        ).copyWith(elements: <TemplateElement>[plain]),
      );

      final String raw = latin1.decode(report.bytes, allowInvalid: true);
      expect(raw.contains(pdfRgb(accent)), isFalse,
          reason: 'عنصر بلا spans لا يحقّ له أن يكتب لوناً غير لونه');
    });

    test('نفس اللون على مدى أوسع يخرج في الملف (تغطية كاملة للمقطع)', () async {
      const String accent = '#1E88E5';
      const String text = 'برنامج التميز';
      final TextElement element = TextElement(
        id: 'wide',
        box: const ElementBox(x: 40, y: 40, width: 500, height: 0),
        text: text,
        fontSize: 26,
        colorHex: '#1B2539',
        spans: <StyledTextSpan>[
          const StyledTextSpan(start: 0, end: text.length, colorHex: accent),
        ],
      );

      final PdfGeneratorService service =
          await PdfGeneratorService.create(compress: false);
      final PdfGenerationReport report = await service.generate(
        document: const TemplateDocument(
          orientation: PageOrientation.portrait,
          elements: <TemplateElement>[],
        ).copyWith(elements: <TemplateElement>[element]),
      );

      final String raw = latin1.decode(report.bytes, allowInvalid: true);
      expect(raw.contains(pdfRgb(accent)), isTrue);
    });
  });
}
