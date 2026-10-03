import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/models/decoration.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/services/pdf_generator_service.dart';

void main() {
  late PdfGeneratorService service;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    service = await PdfGeneratorService.create(
      compress: false,
      useIsolate: false,
    );
  });

  test('الزخرفة الإجرائية تُرسم في ملف PDF صالح', () async {
    final TemplateDocument document = TemplateDocument(
      orientation: PageOrientation.landscape,
      elements: <TemplateElement>[
        for (final DecorKind kind in DecorKind.values)
          DecorationElement(
            id: 'decor-${kind.name}',
            box: const ElementBox(x: 40, y: 40, width: 480, height: 320),
            spec: DecorSpec(kind: kind),
          ),
      ],
    );

    final PdfGenerationReport report =
        await service.generate(document: document);

    expect(report.pageCount, 1);
    expect(report.bytes.lengthInBytes, greaterThan(1000));
    // رأس ملف PDF سليم.
    expect(String.fromCharCodes(report.bytes.take(5)), '%PDF-');
    // لا تحذيرات تغطية/رسم جديدة من الزخرفة.
    expect(
      report.warnings.any((String w) => w.contains('الزخرفة')),
      isFalse,
    );
  });
}
