import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
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

  TemplateDocument documentWith(String text) => TemplateDocument(
        orientation: PageOrientation.landscape,
        elements: <TemplateElement>[
          TextElement(
            id: 'text-1',
            box: const ElementBox(x: 40, y: 40, width: 500, height: 80),
            text: text,
          ),
        ],
      );

  test('يولّد نصاً روسياً وصينياً بخط عربي بلا انهيار ويحذّر من الكتابات الناقصة',
      () async {
    final TemplateDocument document =
        documentWith('تقرير Русский 中文 {{اسم_المتدرب}}');

    final PdfGenerationReport report = await service.generate(
      document: document,
      data: const <String, String>{'اسم_المتدرب': 'Иван Петров'},
    );

    // الملف يُنتَج فعلاً رغم غياب الخطوط الكاملة.
    expect(report.bytes.lengthInBytes, greaterThan(1000));
    // وتحذير واضح لكل كتابة غير مغطّاة بدل فشل صامت.
    expect(
      report.warnings.any((String w) => w.contains('السيريلية')),
      isTrue,
    );
    expect(
      report.warnings.any((String w) => w.contains('الصينية')),
      isTrue,
    );
  });

  test('اللغات اللاتينية الممتدة (FR/TR/DE) لا تُنتج تحذير تغطية', () async {
    final TemplateDocument document = documentWith('Élève ğ İ Straße ç ñ');

    final PdfGenerationReport report =
        await service.generate(document: document);

    expect(report.bytes.lengthInBytes, greaterThan(1000));
    expect(
      report.warnings.any(
        (String w) => w.contains('لا يغطّيها أي خط محزوم'),
      ),
      isFalse,
    );
  });
}
