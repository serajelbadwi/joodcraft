import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/pdf/pdf_script_coverage.dart';

void main() {
  // تُصفَّر التغطية المسجّلة وقت التشغيل قبل كل اختبار كي لا تتسرّب بينها.
  setUp(PdfScriptCoverage.resetRuntimeCoverage);
  tearDown(PdfScriptCoverage.resetRuntimeCoverage);

  test('يكتشف الكتابات الأساسية', () {
    expect(PdfScriptCoverage.scriptsIn('مرحبا'), <PdfScript>{PdfScript.arabic});
    expect(PdfScriptCoverage.scriptsIn('Hello_123'),
        <PdfScript>{PdfScript.latin});
    expect(PdfScriptCoverage.scriptsIn('Héllo'), <PdfScript>{PdfScript.latin});
    expect(
      PdfScriptCoverage.scriptsIn('Привет'),
      <PdfScript>{PdfScript.cyrillic},
    );
    expect(PdfScriptCoverage.scriptsIn('证书'), <PdfScript>{PdfScript.cjk});
    expect(PdfScriptCoverage.scriptsIn('اردو'), <PdfScript>{PdfScript.arabic});
  });

  test('العربية واللاتينية (بالأكسنت) مغطّاة', () {
    expect(
      PdfScriptCoverage.unsupportedIn('مدرسة Élève ğ İ ñ ß'),
      isEmpty,
    );
    expect(PdfScriptCoverage.covers(<PdfScript>{PdfScript.arabic}), isTrue);
    expect(PdfScriptCoverage.covers(<PdfScript>{PdfScript.latin}), isTrue);
  });

  test('السيريلية والصينية غير مغطّاة', () {
    expect(
      PdfScriptCoverage.unsupportedIn('Русский'),
      <PdfScript>{PdfScript.cyrillic},
    );
    expect(
      PdfScriptCoverage.unsupportedIn('中文'),
      <PdfScript>{PdfScript.cjk},
    );
    expect(
      PdfScriptCoverage.unsupportedIn('مرحبا Привет 中文'),
      <PdfScript>{PdfScript.cyrillic, PdfScript.cjk},
    );
  });

  test('الترقيم والرموز لا تُنتج تحذير تغطية', () {
    // النقاط/الرموز إمّا لا تُصنَّف أو تُصنَّف لاتينية مغطّاة — فلا تحذير.
    expect(PdfScriptCoverage.unsupportedIn('— • … € «» %'), isEmpty);
    // الأرقام العربية الهندية (١٢٣) تُصنَّف عربيةً لكنها مغطّاة فلا تحذير.
    expect(PdfScriptCoverage.unsupportedIn('١٢٣'), isEmpty);
  });

  test('unsupportedInDocument يفحص نصوص العناصر والقيم التجريبية', () {
    final TemplateDocument document = TemplateDocument(
      orientation: PageOrientation.landscape,
      elements: const <TemplateElement>[
        TextElement(
          id: 't',
          box: ElementBox(x: 0, y: 0, width: 100, height: 20),
          text: 'تشهد بأن {{اسم_المتدرب}} أتمّ',
        ),
      ],
      sampleData: const <String, String>{'اسم_المتدرب': 'Иван Петров'},
    );

    expect(
      PdfScriptCoverage.unsupportedInDocument(document),
      <PdfScript>{PdfScript.cyrillic},
    );
  });

  test('رسالة التحذير تذكر الكتابة صريحةً', () {
    expect(
      PdfScriptCoverage.warningFor(PdfScript.cjk),
      contains('الصينية'),
    );
    expect(
      PdfScriptCoverage.warningFor(PdfScript.cyrillic),
      contains('السيريلية'),
    );
    expect(
      PdfScriptCoverage.warningFor(PdfScript.cjk),
      contains('Noto Sans'),
    );
  });

  test('تسجيل تغطية وقت التشغيل يلغي تحذير الصينية', () {
    expect(PdfScriptCoverage.unsupportedIn('中文'), <PdfScript>{PdfScript.cjk});

    PdfScriptCoverage.registerCovered(<PdfScript>{PdfScript.cjk});

    expect(PdfScriptCoverage.coveredScripts, contains(PdfScript.cjk));
    expect(PdfScriptCoverage.unsupportedIn('中文'), isEmpty);
    expect(PdfScriptCoverage.covers(<PdfScript>{PdfScript.cjk}), isTrue);
  });

  test('الخط المخصّص المتاح يحجب تحذير تغطية النص', () {
    TemplateDocument withFont(String? font) => TemplateDocument(
          elements: <TemplateElement>[
            TextElement(
              id: 't',
              box: const ElementBox(x: 0, y: 0, width: 100, height: 20),
              text: '中文',
              customFont: font,
            ),
          ],
        );

    // بلا خط مخصّص: الصينية غير مغطّاة.
    expect(
      PdfScriptCoverage.unsupportedInDocument(withFont(null)),
      <PdfScript>{PdfScript.cjk},
    );

    // خط مخصّص متاح (مسجَّل): لا تحذير.
    expect(
      PdfScriptCoverage.unsupportedInDocument(
        withFont('custom-cjk'),
        isCustomFontAvailable: (String family) => family == 'custom-cjk',
      ),
      isEmpty,
    );

    // خط مخصّص غير مسجَّل: التحذير يبقى (لا نَعد بتغطية لم نتحقّق منها).
    expect(
      PdfScriptCoverage.unsupportedInDocument(
        withFont('custom-cjk'),
        isCustomFontAvailable: (String family) => false,
      ),
      <PdfScript>{PdfScript.cjk},
    );
  });
}
