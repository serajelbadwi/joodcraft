import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/pdf/pdf_script_coverage.dart';
import 'package:joodcraft/core/services/pdf_generator_service.dart';

void main() {
  late PdfGeneratorService service;

  setUp(PdfScriptCoverage.resetRuntimeCoverage);
  tearDown(PdfScriptCoverage.resetRuntimeCoverage);

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

  test('النص الروسي والصيني يُرسم بخط الاحتياط المحزوم بلا تحذير تغطية',
      () async {
    final TemplateDocument document =
        documentWith('تقرير Русский 中文 {{اسم_المتدرب}}');

    final PdfGenerationReport report = await service.generate(
      document: document,
      data: const <String, String>{'اسم_المتدرب': 'Иван Петров'},
    );

    expect(report.bytes.lengthInBytes, greaterThan(1000));
    // Noto Sans SC صار محزوماً ومربوطاً كخط احتياط، فيرسم السيريلية والصينية
    // معاً، فلا تحذير تغطية كاذب.
    expect(
      report.warnings.any((String w) => w.contains('لا يغطّيها أي خط محزوم')),
      isFalse,
      reason: 'السيريلية والصينية مغطّاتان بالخط المحزوم: ${report.warnings}',
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

  test('النص العربي وحده لا يُنتج أي تحذير تغطية إطلاقاً', () async {
    // الخطوط المحزومة تغطي العربية 117/117 ⇒ لا تنبيه ولا مربعات.
    final TemplateDocument document = documentWith(
      'تشهد بأن {{اسم_المتدرب}} أتمّ الدورة التدريبية بنجاح.',
    );

    final PdfGenerationReport report = await service.generate(
      document: document,
      data: const <String, String>{'اسم_المتدرب': 'محمد بن عبدالله الشمري'},
    );

    expect(report.bytes.lengthInBytes, greaterThan(1000));
    expect(report.warnings, isEmpty,
        reason: 'العربية مغطّاة فلا يجوز أي تحذير تغطية: ${report.warnings}');
  });

  test('الصينية تُرسم بخط الاحتياط المحزوم بلا تحذير تغطية', () async {
    final TemplateDocument document = documentWith('结业证书 {{الاسم}}');

    final PdfGenerationReport report =
        await service.generate(document: document, data: <String, String>{'الاسم': '张三'});

    expect(report.bytes.lengthInBytes, greaterThan(1000));
    expect(
      report.warnings.any((String w) => w.contains('لا يغطّيها أي خط محزوم')),
      isFalse,
      reason: 'الصينية مغطّاة بخط الاحتياط المحزوم: ${report.warnings}',
    );
  });
}
