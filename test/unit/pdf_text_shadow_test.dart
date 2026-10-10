import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/pdf/pdf_render_engine.dart';
import 'package:joodcraft/core/services/pdf_generator_service.dart';

/// اختبارات ظل النص في الـ PDF: طبقاته المحسوبة نصيّاً، ووصوله فعلاً إلى الملف
/// المولَّد (لا مجرد حفظه في النموذج).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const ElementBox box =
      ElementBox(x: 60, y: 80, width: 400, height: 60);

  TemplateDocument documentWith(TextShadow? shadow) => TemplateDocument(
        orientation: PageOrientation.landscape,
        elements: <TemplateElement>[
          TextElement(
            id: 't',
            box: box,
            text: 'شهادة تقدير',
            fontSize: 32,
            shadow: shadow,
          ),
        ],
      );

  /// عدد مرات رسم نص في ملف الـ PDF (كل رسم يبدأ بـ`BT `).
  ///
  /// البيانات الثنائية للخطوط قد تحتوي المصادفة نفسها، لكنها **متطابقة** بين
  /// الملفين المقارَنين (الفرق الوحيد هو الظل) فيصحّ الاعتماد على الفرق.
  int textDrawCount(List<int> bytes) =>
      RegExp('BT ').allMatches(latin1.decode(bytes, allowInvalid: true)).length;

  Future<int> drawsOf(TextShadow? shadow) async {
    final PdfGeneratorService service =
        await PdfGeneratorService.create(compress: false);
    final PdfGenerationReport report =
        await service.generate(document: documentWith(shadow));
    expect(report.warnings, isEmpty);
    return textDrawCount(report.bytes);
  }

  group('حساب طبقات ظل النص في الـ PDF', () {
    test('الظل الحادّ طبقة واحدة بإزاحة الظل وشفافيته', () {
      final List<PdfTextShadowLayer> layers = pdfTextShadowLayers(
        const TextShadow(
          colorHex: '#000000',
          opacity: 0.6,
          blurRadius: 0,
          offsetX: 2,
          offsetY: 3,
        ),
        1,
      );
      expect(layers, hasLength(1));
      expect(layers.single.dx, 2);
      expect(layers.single.dy, 3);
      expect(layers.single.opacity, 0.6);
    });

    test('الظل المموّه يضيف أربع طبقات محيطة بنصف الشفافية', () {
      final List<PdfTextShadowLayer> layers = pdfTextShadowLayers(
        const TextShadow(opacity: 0.8, blurRadius: 8, offsetX: 0, offsetY: 0),
        1,
      );
      expect(layers, hasLength(5));
      expect(layers.first.dx, 0);
      expect(layers.first.opacity, 0.8);

      final Set<String> ring = <String>{
        for (final PdfTextShadowLayer layer in layers.skip(1))
          '${layer.dx},${layer.dy}',
      };
      expect(ring, <String>{'4.0,0.0', '-4.0,0.0', '0.0,4.0', '0.0,-4.0'});
      for (final PdfTextShadowLayer layer in layers.skip(1)) {
        expect(layer.opacity, 0.4);
      }
    });

    test('المقياس يُطبَّق على الإزاحة ونصف قطر التمويه', () {
      final List<PdfTextShadowLayer> layers = pdfTextShadowLayers(
        const TextShadow(opacity: 1, blurRadius: 6, offsetX: 1, offsetY: 1),
        2,
      );
      expect(layers.first.dx, 2);
      expect(layers.first.dy, 2);
      expect(layers[1].dx, 2 + 6);
    });

    test('ظل غير مرئي لا يُنتج أي طبقة', () {
      expect(pdfTextShadowLayers(const TextShadow(opacity: 0), 1), isEmpty);
      expect(
        pdfTextShadowLayers(
          const TextShadow(blurRadius: 0, offsetX: 0, offsetY: 0),
          1,
        ),
        isEmpty,
      );
    });
  });

  group('وصل الظل إلى ملف الـ PDF المولَّد', () {
    test('الظل يضيف نسخة لكل طبقة تُحسب له', () async {
      // مستند فيه عنصر نصّ واحد بلا ظل: عدد ظهور `BT ` يقابل رسمة نصّ واحدة
      // (المعامل ثابت في المحرّك، فيُستخرج من الأساس بدل تثبيته في الاختبار).
      final int baseline = await drawsOf(null);
      expect(baseline, greaterThan(0));

      final int crisp = await drawsOf(
        const TextShadow(opacity: 0.5, blurRadius: 0, offsetX: 2, offsetY: 2),
      );
      final int blurred = await drawsOf(
        const TextShadow(opacity: 0.5, blurRadius: 6, offsetX: 1, offsetY: 1),
      );

      // ظل حادّ: طبقة واحدة فقط زيادةً على النص الأصلي.
      expect(crisp - baseline, baseline);
      // ظل مموّه: خمس طبقات (النسخة المزاحة + محيط التمويه الرباعي).
      expect(blurred - baseline, baseline * 5);
    });

    test('الظل لا يُفقد في ملف الـ PDF (ملف صالح وأكبر من بلا ظل)', () async {
      final PdfGeneratorService service =
          await PdfGeneratorService.create(compress: false);
      final PdfGenerationReport plain =
          await service.generate(document: documentWith(null));
      final PdfGenerationReport shadowed = await service.generate(
        document: documentWith(const TextShadow(blurRadius: 6)),
      );

      final String header =
          latin1.decode(shadowed.bytes.take(5).toList(), allowInvalid: true);
      expect(header.startsWith('%PDF'), isTrue);
      expect(
        shadowed.bytes.lengthInBytes,
        greaterThan(plain.bytes.lengthInBytes),
      );
    });
  });
}
