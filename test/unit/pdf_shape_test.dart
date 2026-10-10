import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/services/pdf_generator_service.dart';

/// اختبار انحدار لمحرّك الـ PDF: كل خصائص الشكل الجديدة تُصدَّر في ملف صالح.
void main() {
  late PdfGeneratorService service;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    service = await PdfGeneratorService.create(
      compress: false,
      useIsolate: false,
    );
  });

  test('الأشكال الموسّعة (تدرّج/ظل/شرطات/نجمة/دمج) تُصدَّر كـ PDF صالح',
      () async {
    const TemplateDocument document = TemplateDocument(
      orientation: PageOrientation.landscape,
      elements: <TemplateElement>[
        // تدرّج خطي.
        ShapeElement(
          id: 'gradient',
          kind: ShapeKind.rect,
          box: ElementBox(x: 40, y: 40, width: 200, height: 120),
          gradient: ShapeGradient(
            startHex: '#C7A26B',
            endHex: '#1B2539',
            angle: 45,
          ),
        ),
        // نجمة بظل وإطار متقطّع.
        ShapeElement(
          id: 'star',
          kind: ShapeKind.star,
          box: ElementBox(x: 280, y: 40, width: 160, height: 160),
          points: 6,
          innerRadius: 0.4,
          fillHex: '#F3E3C3',
          strokeHex: '#9E7B45',
          strokeWidth: 2,
          dashPattern: <double>[6, 3],
          shadow: ShapeShadow(
            colorHex: '#000000',
            blurRadius: 10,
            offsetX: 4,
            offsetY: 4,
            spread: 2,
          ),
        ),
        // شكل مركّب بالطرح.
        ShapeElement(
          id: 'compound',
          kind: ShapeKind.rect,
          box: ElementBox(x: 40, y: 220, width: 160, height: 160),
          fillHex: '#1B2539',
          booleanOp: ShapeBooleanOp.subtract,
          booleanParts: <ShapeElement>[
            ShapeElement(
              id: 'compound_a',
              kind: ShapeKind.rect,
              box: ElementBox(width: 160, height: 160),
              fillHex: '#1B2539',
            ),
            ShapeElement(
              id: 'compound_b',
              kind: ShapeKind.ellipse,
              box: ElementBox(x: 40, y: 40, width: 80, height: 80),
            ),
          ],
        ),
        // مضلّع بعدد أضلاع مخصّص.
        ShapeElement(
          id: 'polygon',
          kind: ShapeKind.polygon,
          box: ElementBox(x: 280, y: 220, width: 140, height: 140),
          points: 6,
          fillHex: '#C7A26B',
        ),
      ],
    );

    final PdfGenerationReport report =
        await service.generate(document: document);

    expect(report.pageCount, 1);
    expect(report.bytes.lengthInBytes, greaterThan(1000));
    expect(String.fromCharCodes(report.bytes.take(5)), '%PDF-');
  });
}
