import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/errors/app_error_code.dart';
import 'package:joodcraft/core/errors/app_exception.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/pdf/pdf_font_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('قراءة قالب الشهادة النموذجي', () {
    late TemplateDocument document;

    setUpAll(() async {
      document = TemplateDocument.fromJsonString(
        await rootBundle.loadString(AppAssets.sampleCertificateTemplate),
      );
    });

    test('يقرأ الإصدار والورق والاتجاه', () {
      expect(document.schemaVersion, AppConstants.layoutSchemaVersion);
      expect(document.paperSize, PaperSize.a4);
      expect(document.orientation, PageOrientation.landscape);
      expect(document.isLandscape, isTrue);
      expect(document.warnings, isEmpty);
    });

    test('يحسب أبعاد الصفحة ووحّدها مع مساحة التصميم', () {
      // A4 أفقي = 841.89×595.28 نقطة، ومساحة التصميم 1123×794 بكسل.
      expect(document.pageWidthPt, closeTo(841.89, 0.01));
      expect(document.pageHeightPt, closeTo(595.28, 0.01));
      expect(document.designWidth, 1123);
      expect(document.designHeight, 794);
      // معامل التحويل ≈ 0.75 (96dpi ← 72pt).
      expect(document.scale, closeTo(0.7497, 0.0005));
      // نِسبة مساحة التصميم تختلف بجزء ضئيل عن نِسبة A4 ⇒ إزاحة أفقية < 0.02pt
      // (أقل من 0.01 مم) لا تُذكر، لكنها تُحسب وتُعوَّض منعاً لانحراف تراكمي.
      expect(document.offsetX.abs(), lessThan(0.1));
      expect(document.offsetY.abs(), lessThan(0.1));
    });

    test('يقرأ كل أنواع العناصر الموجودة في القالب', () {
      // 10 نصوص + 7 أشكال (إطارات وخطوط) + ختم واحد.
      expect(document.elements.length, 18);
      expect(document.drawableElementCount, 18);
      expect(document.elements.whereType<TextElement>().length, 10);
      expect(document.elements.whereType<ShapeElement>().length, 7);
      expect(document.elements.whereType<SealElement>().length, 1);
    });

    test('يستخرج الحقول الديناميكية من النصوص', () {
      expect(
        document.fieldKeys,
        containsAll(<String>[
          'student_name',
          'program_name',
          'date',
          'verify_code',
        ]),
      );
      expect(document.hasDynamicFields, isTrue);
    });

    test('يستبدل الحقول بالقيم ثم بالبيانات التجريبية', () {
      expect(
        document.resolveFields('المستفيد: {{student_name}}', <String, String>{
          'student_name': 'منى',
        }),
        'المستفيد: منى',
      );
      // بلا بيانات صريحة → القيم التجريبية من القالب.
      expect(
        document.resolveFields('{{student_name}}', null),
        document.sampleData['student_name'],
      );
      // حقل غير موجود → نص فارغ بلا استثناء.
      expect(document.resolveFields('[{{missing_key}}]', null), '[]');
      // المسافات حول اسم الحقل مقبولة.
      expect(
        document.resolveFields('{{  date  }}', <String, String>{'date': 'اليوم'}),
        'اليوم',
      );
    });

    test('يقرأ نمط النص ومحاذاته وألوانه', () {
      final TextElement title =
          document.elements.whereType<TextElement>().firstWhere(
                (TextElement e) => e.id == 'title',
              );
      expect(title.family, PdfFontFamily.plex);
      expect(title.weight, PdfFontWeight.bold);
      expect(title.fontSize, 40);
      expect(title.align, ElementTextAlign.center);
      expect(title.verticalAlign, ElementVerticalAlign.middle);
      expect(title.colorHex, '#FFFFFF');
    });

    test('الدوران ذهاباً وإياباً يحفظ بنية القالب', () {
      final TemplateDocument restored =
          TemplateDocument.fromJson(document.toJson());

      expect(restored.elements.length, document.elements.length);
      expect(restored.orientation, document.orientation);
      expect(restored.paperSize, document.paperSize);
      expect(restored.schemaVersion, document.schemaVersion);
      expect(restored.designWidth, document.designWidth);
      expect(restored.designHeight, document.designHeight);

      for (int i = 0; i < document.elements.length; i++) {
        expect(restored.elements[i].runtimeType, document.elements[i].runtimeType);
        expect(restored.elements[i].id, document.elements[i].id);
      }
    });
  });

  group('قراءة قالب العقد النموذجي', () {
    test('رأسي و A4 بحقول ديناميكية متعددة', () async {
      final TemplateDocument document = TemplateDocument.fromJsonString(
        await rootBundle.loadString(AppAssets.sampleContractTemplate),
      );

      expect(document.orientation, PageOrientation.portrait);
      expect(document.isLandscape, isFalse);
      expect(document.pageWidthPt, closeTo(595.28, 0.01));
      expect(document.pageHeightPt, closeTo(841.89, 0.01));
      expect(
        document.fieldKeys,
        containsAll(<String>['contract_no', 'party_1', 'party_2', 'amount']),
      );
      // نصوص العقد مكتوبة بخط Amiri (نسخ تقليدي).
      expect(
        document.elements.whereType<TextElement>().any(
              (TextElement e) => e.family == PdfFontFamily.amiri,
            ),
        isTrue,
      );
    });
  });

  group('التحقق من صحة القالب', () {
    test('يرفض JSON تالفاً', () {
      expect(
        () => TemplateDocument.fromJsonString('{oops'),
        throwsA(
          isA<AppException>().having(
            (AppException e) => e.code,
            'code',
            AppErrorCode.templateFormat,
          ),
        ),
      );
    });

    test('يرفض جذراً ليس كائناً', () {
      expect(
        () => TemplateDocument.fromJsonString('[1, 2, 3]'),
        throwsA(isA<AppException>()),
      );
    });

    test('يرفض إصدار مخطط أحدث من المدعوم', () {
      expect(
        () => TemplateDocument.fromJsonString('{"schema_version": 2}'),
        throwsA(
          isA<AppException>().having(
            (AppException e) => e.code,
            'code',
            AppErrorCode.unsupportedSchema,
          ),
        ),
      );
    });

    test('يحذّر عند غياب schema_version ويواصل العمل', () {
      final TemplateDocument document =
          TemplateDocument.fromJson(<String, dynamic>{'elements': <dynamic>[]});
      expect(document.schemaVersion, 1);
      expect(document.warnings, isNotEmpty);
    });

    test('يحفظ العناصر مجهولة النوع بدل إسقاط القالب', () {
      final TemplateDocument document =
          TemplateDocument.fromJson(<String, dynamic>{
        'schema_version': 1,
        'elements': <Map<String, dynamic>>[
          <String, dynamic>{
            'type': 'chart',
            'x': 10,
            'y': 10,
            'w': 200,
            'h': 100,
            'series': <int>[1, 2, 3],
          },
          <String, dynamic>{'type': 'text', 'text': 'نص سليم', 'size': 14},
        ],
      });

      expect(document.elements.length, 2);
      expect(document.elements.first, isA<UnknownElement>());
      expect(document.drawableElementCount, 1);
      expect(document.warnings.single, contains('chart'));
      // العنصر المجهول يُعاد كما هو عند الحفظ (توافق أمامي).
      final Map<String, dynamic> raw =
          (document.elements.first as UnknownElement).toJson();
      expect(raw['series'], <int>[1, 2, 3]);
    });
  });

  group('قراءة العناصر المفردة', () {
    test('تقرأ الاختصارات والبدائل وتُطبّق الافتراضيات', () {
      final TextElement element = TemplateElement.fromJson(<String, dynamic>{
        'id': 'x',
        'type': 'text',
        'x': 10,
        'y': 20,
        'width': 300,
        'height': 40,
        'text': 'مرحباً',
        'font': 'amiri',
        'weight': 700,
        'size': 18,
        'align': 'right',
      }, 0) as TextElement;

      expect(element.box.width, 300);
      expect(element.box.height, 40);
      expect(element.family, PdfFontFamily.amiri);
      expect(element.weight, PdfFontWeight.bold);
      // في قالب عربي: align=right يعني نهاية السطر منطقياً.
      expect(element.align, ElementTextAlign.end);
      expect(element.direction, ElementDirection.rtl);
      expect(element.lineHeight, 1.4);
    });

    test('تولّد معرّفاً تلقائياً عند غيابه', () {
      final TextElement element = TemplateElement.fromJson(
        <String, dynamic>{'type': 'text', 'text': 'بلا معرّف'},
        3,
      ) as TextElement;
      expect(element.id, 'element_3');
    });

    test('أسماء الخطوط غير المعروفة ترجع للافتراضي بأمان', () {
      final TextElement element = TemplateElement.fromJson(<String, dynamic>{
        'type': 'text',
        'text': 'x',
        'font': 'some-unknown-font',
      }, 0) as TextElement;
      expect(element.family, PdfFontFamily.plex);
      expect(element.family.usableInPdf, isTrue);
    });
  });
}
