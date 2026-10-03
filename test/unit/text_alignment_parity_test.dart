import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/widgets/element_view.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/models/text_flow.dart';
import 'package:joodcraft/core/pdf/arabic_text_engine.dart';
import 'package:joodcraft/core/pdf/pdf_font_catalog.dart';
import 'package:joodcraft/core/services/pdf_generator_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// **رحلات حقيقية** تقارن أسطر النص النهائية بين محرّر اللوحة (Flutter) ومخرجات
/// الـ PDF (مكتبة `pdf`) عند **كل** قيم `ElementTextAlign` × `ElementDirection`.
///
/// لماذا هما قابلة للمقارنة فعلاً؟ لأن الطرفين يقيسان بالخط نفسه:
/// - المحرر: `TextPainter` بنمط `editorTextStyle` والخط المسجَّل في فلاتر.
/// - الـ PDF: `ArabicTextEngine.wrap` بقياس `PdfFont.stringMetrics` من مكتبة
///   `pdf` نفسها (أي القياس الفعلي الذي يقرّر به المحرك أين ينكسر السطر).
///
/// أي انحدار مستقبلي في التشكيل/الترتيب/الاتجاه/تقسيم الأسطر أو في الضبط يكسر
/// هذه الاختبارات، فلا تترحّل المحاذاة بين المعاينة والطباعة بصمت.
int _wordCount(String line) =>
    line.split(' ').where((String w) => w.isNotEmpty).length;

/// الموضع الفيزيائي الذي تحسمه محاذاة فلاتر مع اتجاه النص.
TextAnchor _flutterPhysical(TextAlign align, bool rtl) => switch (align) {
      TextAlign.center => TextAnchor.center,
      TextAlign.start => rtl ? TextAnchor.right : TextAnchor.left,
      TextAlign.end => rtl ? TextAnchor.left : TextAnchor.right,
      TextAlign.justify => rtl ? TextAnchor.right : TextAnchor.left,
      // المحاذاة الطبيعية/الوراثية غير مستخدمة في عناصر النص، ونسقطها على
      // البداية حتى تبقى الدالة شاملة.
      _ => rtl ? TextAnchor.right : TextAnchor.left,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const double fontSize = 20;
  const double boxWidth = 450;

  late PdfFont pdfMetrics;

  setUpAll(() async {
    // نحمّل خط الـ PDF نفسه داخل فلاتر باسم عائلة المحرر، فيصبح القياسان من
    // ملف الخط ذاته لا من خط افتراضي (Ahem) مختلف المقاييس.
    final ByteData data = await rootBundle.load(AppAssets.pdfPlexRegular);
    final FontLoader loader = FontLoader(PdfFontFamily.plex.uiFamily);
    loader.addFont(Future<ByteData>.value(data));
    await loader.load();
    final pw.Font font = pw.Font.ttf(data);
    pdfMetrics = font.getFont(pw.Context(document: PdfDocument()));
  });

  /// قياس نص **بصري** بخط مكتبة `pdf` — نفس ما يستخدمه المحرك عند الطباعة.
  double measurePdf(String visual) =>
      (pdfMetrics.stringMetrics(visual) * fontSize).advanceWidth;

  TextElement textElement({
    required String text,
    ElementTextAlign align = ElementTextAlign.start,
    ElementDirection direction = ElementDirection.rtl,
    int? maxLines,
  }) =>
      TextElement(
        id: 'p',
        box: const ElementBox(x: 0, y: 0, width: boxWidth, height: 0),
        text: text,
        align: align,
        direction: direction,
        fontSize: fontSize,
        maxLines: maxLines,
      );

  /// أسطر المحرر: عدد الكلمات في كل سطر كما يقرّره مُقسِّم فلاتر.
  List<int> editorLineWordCounts(TextElement element, bool rtl) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: element.text, style: editorTextStyle(element, 1)),
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      textAlign: editorTextAlign(element.align),
    )..layout(maxWidth: boxWidth);

    final List<int> counts = <int>[];
    int offset = 0;
    while (offset < element.text.length) {
      final TextRange range =
          painter.getLineBoundary(TextPosition(offset: offset));
      counts.add(_wordCount(element.text.substring(range.start, range.end)));
      if (range.end <= offset) break;
      offset = range.end;
    }
    return counts;
  }

  /// أسطر الـ PDF: `ArabicTextEngine.wrap` بقياس الخط الحقيقي.
  List<String> pdfLines(TextElement element, {bool justify = false}) =>
      ArabicTextEngine.wrap(
        text: element.text,
        maxWidth: boxWidth,
        measureWidth: measurePdf,
        maxLines: element.maxLines,
        justify: justify,
      );

  const Map<String, String> samples = <String, String>{
    'عربي': 'قد أتمّ بنجاح البرنامج التدريبي المكثّف في إدارة المشاريع '
        'وقيادة الفرق، ونال شهادة تقدير معتمدة من الجهة المانحة.',
    'لاتيني': 'This certificate is awarded to the participant who completed '
        'the intensive training program with distinction and honor.',
    'مختلط': 'شهادة Certificate تقدير للجهود 2026 المتميّزة',
  };

  // -------------------------------------------------------------------------
  //  1) حلّ الاتجاه والمحاذاة الفيزيائية
  // -------------------------------------------------------------------------
  group('حلّ الاتجاه والمحاذاة موحّد بين المحرر والـ PDF', () {
    test('rtl/ltr صريحان، وauto يكشف العربية (لا اللاتينية)', () {
      expect(TextFlow.resolvesRtl(ElementDirection.rtl, 'JoodCraft'), isTrue);
      expect(TextFlow.resolvesRtl(ElementDirection.ltr, 'شهادة'), isFalse);
      expect(TextFlow.resolvesRtl(ElementDirection.auto, 'شهادة تقدير'), isTrue);
      expect(TextFlow.resolvesRtl(ElementDirection.auto, 'Certificate'), isFalse);
      // النص البصري المسبق (صور العرض U+FB1D..FEFF) يُكتشف أيضاً.
      expect(
        TextFlow.resolvesRtl(ElementDirection.auto, '\uFE8E\uFEE0'),
        isTrue,
      );
    });

    test('دالة المحرر تعيد نفس نتيجة الحلّ المشترك لكل اتجاه ونص', () {
      for (final MapEntry<String, String> sample in samples.entries) {
        for (final ElementDirection direction in ElementDirection.values) {
          final TextElement element =
              textElement(text: sample.value, direction: direction);
          expect(
            editorTextIsRtl(element, sample.value),
            TextFlow.resolvesRtl(direction, sample.value),
            reason: 'اتجاه «${sample.key}» مع $direction',
          );
        }
      }
    });

    test('محاذاة المحرر الفيزيائية = محاذاة المحرك (TextFlow.anchorFor)', () {
      for (final ElementTextAlign align in ElementTextAlign.values) {
        for (final bool rtl in <bool>[true, false]) {
          expect(
            _flutterPhysical(editorTextAlign(align), rtl),
            TextFlow.anchorFor(align, rtl),
            reason: 'محاذاة $align باتجاه rtl=$rtl',
          );
        }
      }
    });
  });

  // -------------------------------------------------------------------------
  //  2) الأسطر النهائية: كل محاذاة × كل اتجاه × كل نوع نص
  // -------------------------------------------------------------------------
  group('الأسطر النهائية متطابقة بين اللوحة والـ PDF', () {
    for (final ElementTextAlign align in ElementTextAlign.values) {
      for (final ElementDirection direction in ElementDirection.values) {
        test('محاذاة $align × اتجاه $direction', () {
          for (final MapEntry<String, String> sample in samples.entries) {
            final TextElement element = textElement(
              text: sample.value,
              align: align,
              direction: direction,
            );
            final bool rtl = editorTextIsRtl(element, sample.value);

            final List<int> editorLines = editorLineWordCounts(element, rtl);
            final List<String> engineLines =
                pdfLines(element, justify: align == ElementTextAlign.justify);
            final List<int> pdfLinesCounts =
                engineLines.map(_wordCount).toList();

            expect(editorLines, isNotEmpty, reason: sample.key);
            expect(
              pdfLinesCounts,
              editorLines,
              reason: '«${sample.key}» — انكسرت الأسطر بشكل مختلف بين '
                  'المحرر والـ PDF عند $align / $direction',
            );
            // مجموع الكلمات محفوظ: لا كلمة ضائعة ولا مكرّرة.
            expect(
              editorLines.fold<int>(0, (int a, int b) => a + b),
              _wordCount(sample.value),
            );
          }
        });
      }
    }
  });

  // -------------------------------------------------------------------------
  //  3) الضبط: تمديد الأسطر غير الأخيرة مع بقاء الأخير طبيعياً
  // -------------------------------------------------------------------------
  group('محاذاة الضبط تُنتج الأسطر نفسها ثم تمدّها', () {
    for (final ElementDirection direction in ElementDirection.values) {
      test('اتجاه $direction يمدّ الأسطر غير الأخيرة إلى العرض', () {
        final TextElement element = textElement(
          text: samples['عربي']!,
          align: ElementTextAlign.justify,
          direction: direction,
        );
        final bool rtl = editorTextIsRtl(element, element.text);
        final List<String> lines = pdfLines(element, justify: true);

        // الضبط لا يغيّر نقط انكسار الأسطر.
        expect(
          lines.map(_wordCount).toList(),
          editorLineWordCounts(element, rtl),
        );
        expect(lines.length, greaterThan(1));

        final double space = measurePdf(' ');
        for (int i = 0; i < lines.length; i++) {
          final double width = measurePdf(lines[i]);
          // لا يتجاوز أي سطر عرض الصندوق مهما مدّده الضبط.
          expect(width, lessThanOrEqualTo(boxWidth + 1e-6));
          if (i < lines.length - 1) {
            // الأسطر غير الأخيرة ممتدّة حتى حدود الصندوق (الفارق المتبقّي أقل
            // من عرض فراغ واحد لأن التوزيع يقعّد عدد الفراغات).
            expect(width, greaterThanOrEqualTo(boxWidth - space - 1e-6));
          }
        }
        // السطر الأخير يبقى طبيعياً غير ممدَّد.
        expect(measurePdf(lines.last), lessThan(boxWidth));
      });
    }
  });

  // -------------------------------------------------------------------------
  //  4) رحلة كاملة: توليد PDF فعلي لكل محاذاة واتجاه
  // -------------------------------------------------------------------------
  group('توليد PDF فعلي لكل قيمة محاذاة واتجاه (رحلة كاملة)', () {
    for (final ElementTextAlign align in ElementTextAlign.values) {
      for (final ElementDirection direction in ElementDirection.values) {
        test('$align × $direction يُصدِر ملفاً بخط عربي مضمَّن', () async {
          final PdfGeneratorService service =
              await PdfGeneratorService.create(compress: false);
          final PdfGenerationReport report = await service.generate(
            document: const TemplateDocument(
              orientation: PageOrientation.portrait,
              elements: <TemplateElement>[],
            ).copyWith(
              elements: <TemplateElement>[
                textElement(
                  text: samples['عربي']!,
                  align: align,
                  direction: direction,
                ),
              ],
            ),
          );

          final String raw =
              latin1.decode(report.bytes, allowInvalid: true);
          expect(report.warnings, isEmpty);
          expect(raw.contains('IBMPlexSansArabic'), isTrue,
              reason: 'الخط العربي يجب أن يُضمَّن في الملف');
          expect(report.bytes.lengthInBytes, greaterThan(1000));
        });
      }
    }
  });
}
