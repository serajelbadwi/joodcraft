import 'dart:convert' show latin1;
import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/errors/app_exception.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/print/crop_marks.dart';
import 'package:joodcraft/core/print/imposition_calculator.dart';
import 'package:joodcraft/core/print/imposition_pdf_builder.dart';
import 'package:joodcraft/core/services/pdf_generator_service.dart';

/// اختبارات بنية ملف التجميع (Imposition PDF): عدد الأوراق، أبعادها،
/// علامات القصّ، والدقّة المعلنة — وكذلك المساراتين (مفرد/جماعي).
void main() {
  late PdfGeneratorService service;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    service = await PdfGeneratorService.create(
      compress: false,
      useIsolate: false,
    );
  });

  /// بطاقة 90×55 ملم (مقاس بطاقة العمل القياسي).
  TemplateDocument card() => TemplateDocument(
        orientation: PageOrientation.landscape,
        customPageSize: const CustomPageSize(
          width: 55,
          height: 90,
          unit: MeasurementUnit.mm,
        ),
        elements: <TemplateElement>[
          const TextElement(
            id: 'title',
            box: ElementBox(x: 12, y: 12, width: 300, height: 70),
            text: 'بطاقة عمل',
          ),
        ],
      );

  /// رقم جلوس بمقاس A6 (105×148 ملم).
  TemplateDocument seat() => TemplateDocument(
        orientation: PageOrientation.portrait,
        customPageSize: const CustomPageSize(
          width: 105,
          height: 148,
          unit: MeasurementUnit.mm,
        ),
        elements: <TemplateElement>[
          const TextElement(
            id: 'seat',
            box: ElementBox(x: 60, y: 300, width: 500, height: 200),
            text: '{{الرقم}}',
          ),
        ],
        sampleData: <String, String>{'الرقم': '7'},
      );

  /// عدد صفح الـ PDF الفعلي (يميّز `/Type /Page` عن `/Type /Pages`).
  int pageCountOf(List<int> bytes) {
    final String source = latin1.decode(bytes);
    return RegExp(r'/Type\s*/Page(?![s\d])').allMatches(source).length;
  }

  /// أول `[0 0 عرض ارتفاع]` في الملف (أبعاد الصفحة بالنقاط).
  (double, double)? firstMediaBox(List<int> bytes) {
    final Match? match = RegExp(
      r'/MediaBox\s*\[\s*0\s+0\s+([0-9.]+)\s+([0-9.]+)',
    ).firstMatch(latin1.decode(bytes));
    if (match == null) return null;
    return (
      double.parse(match.group(1)!),
      double.parse(match.group(2)!),
    );
  }

  // ==========================================================================
  //  الدقّة والملف
  // ==========================================================================
  group('دقّة التصدير', () {
    test('الصور تُحلّ عند 300 نقطة/بوصة', () {
      expect(ImpositionPdfBuilder.exportDpi, 300);
    });

    test('الملف يبدأ بـ %PDF ويُختم بـ %%EOF', () async {
      final PdfGenerationReport report = await service.generateImposition(
        document: card(),
        spec: ImpositionSpec.fromDocument(
          card(),
          sheet: ImpositionSheet.a4,
        ),
        copies: 2,
      );
      final String text = latin1.decode(report.bytes);
      expect(text.startsWith('%PDF-'), isTrue);
      expect(text.trimRight().endsWith('%%EOF'), isTrue);
      expect(report.pageCount, greaterThanOrEqualTo(1));
    });

    test('أبعاد الورقة في الملف = المليمتر محوّلاً إلى نقاط بالضبط', () async {
      final PdfGenerationReport report = await service.generateImposition(
        document: seat(),
        spec: ImpositionSpec.fromDocument(
          seat(),
          sheet: ImpositionSheet.a3,
        ),
        copies: 1,
      );
      final (double, double)? box = firstMediaBox(report.bytes);
      expect(box, isNotNull);
      // A3 = 297×420 ملم ⇒ 841.88976×1190.55118 نقطة (بالطول لأن القطعة رأسية).
      // مكتبة PDF تكتب الأرقام بدقة خمس خانات عشرية ⇒ التسامح 1e-4.
      expect(box!.$1, closeTo(mmToPt(297), 1e-4));
      expect(box.$2, closeTo(mmToPt(420), 1e-4));
      // المعامل نفسه: 72 نقطة لكل بوصة (25.4 ملم).
      expect(box.$1 / 297, closeTo(72 / 25.4, 1e-7));
    });
  });

  // ==========================================================================
  //  التجميع المفرد
  // ==========================================================================
  group('التجميع المفرد', () {
    test('قطعة واحدة ⇒ ورقة واحدة وشبكة تملؤها', () async {
      final ImpositionSpec spec = ImpositionSpec.fromDocument(
        card(),
        sheet: ImpositionSheet.a3,
      );
      final PdfGenerationReport report = await service.generateImposition(
        document: card(),
        spec: spec,
        copies: 1,
      );
      expect(report.pageCount, 1);
      expect(pageCountOf(report.bytes), 1);
      expect(spec.layout().count, greaterThan(1));
    });

    test('40 قطعة على A3 ⇒ تُقسَّم على عدة أوراق مكتملة', () async {
      final ImpositionSpec spec = ImpositionSpec.fromDocument(
        card(),
        sheet: ImpositionSheet.a3,
      );
      final int perSheet = spec.layout().count;
      expect(perSheet, greaterThan(0));

      final PdfGenerationReport report = await service.generateImposition(
        document: card(),
        spec: spec,
        copies: 40,
      );
      final int expectedSheets = (40 + perSheet - 1) ~/ perSheet;
      expect(expectedSheets, greaterThan(1), reason: 'التوزيع يتجاوز ورقة');
      expect(report.pageCount, expectedSheets);
      expect(pageCountOf(report.bytes), expectedSheets);
    });

    test('تقدّم التوليد يُبلغ بعد كل ورقة', () async {
      final ImpositionSpec spec = ImpositionSpec.fromDocument(
        card(),
        sheet: ImpositionSheet.a3,
      );
      final List<(int, int)> progress = <(int, int)>[];
      final PdfGenerationReport report = await service.generateImposition(
        document: card(),
        spec: spec,
        copies: 40,
        onProgress: (int done, int total) => progress.add((done, total)),
      );
      expect(progress, hasLength(report.pageCount));
      expect(progress.last.$1, report.pageCount);
      expect(progress.last.$2, report.pageCount);
    });
  });

  // ==========================================================================
  //  التجميع الجماعي
  // ==========================================================================
  group('التجميع الجماعي', () {
    test('عشرة أرقام جلوس A6 تتوزّع على عدة أوراق A3', () async {
      final ImpositionSpec spec = ImpositionSpec.fromDocument(
        seat(),
        sheet: ImpositionSheet.a3,
      );
      final int perSheet = spec.layout().count;
      // أبعاد A6 على A3: 2×2 القطع ⇒ أربعة في الورقة الواحدة.
      expect(perSheet, 4);

      final List<Map<String, String>> rows = <Map<String, String>>[
        for (int i = 1; i <= 10; i++) <String, String>{'الرقم': '$i'},
      ];

      final PdfGenerationReport report = await service.generateImposition(
        document: seat(),
        spec: spec,
        rows: rows,
      );
      // 10 قطع ÷ 4 في الورقة = 3 أوراق (4 + 4 + 2).
      expect(report.pageCount, 3);
      expect(pageCountOf(report.bytes), 3);
      expect(firstMediaBox(report.bytes)!.$1, closeTo(mmToPt(297), 1e-4));
    });

    test('الصفوف الأقل من سعة الورقة تبقى في ورقة واحدة', () async {
      final ImpositionSpec spec = ImpositionSpec.fromDocument(
        seat(),
        sheet: ImpositionSheet.a3,
      );
      final List<Map<String, String>> rows = <Map<String, String>>[
        <String, String>{'الرقم': '1'},
        <String, String>{'الرقم': '2'},
        <String, String>{'الرقم': '3'},
      ];
      final PdfGenerationReport report = await service.generateImposition(
        document: seat(),
        spec: spec,
        rows: rows,
      );
      expect(report.pageCount, 1);
      expect(pageCountOf(report.bytes), 1);
    });

    test('قطعة لا تتسعها الورقة ترفض برسالة عربية واضحة', () async {
      // هامش 100 ملم على A4 يترك 10 ملم فقط — أصغر من البطاقة نفسها.
      final ImpositionSpec spec = ImpositionSpec.fromDocument(
        card(),
        sheet: ImpositionSheet.a4,
        marginMm: 100,
        gutterXMm: 0,
        gutterYMm: 0,
      );
      expect(spec.layout().count, 0);

      await expectLater(
        service.generateImposition(
          document: card(),
          spec: spec,
          copies: 1,
        ),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.message,
            'message',
            contains('لا تتسع'),
          ),
        ),
      );
    });
  });

  // ==========================================================================
  //  علامات القصّ وهندسة الورقة
  // ==========================================================================
  group('علامات القصّ وهندسة الورقة', () {
    test('لكل قطعة ثماني علامات ضمن حدود الورقة', () {
      final ImpositionSpec spec = ImpositionSpec.fromDocument(
        card(),
        sheet: ImpositionSheet.a3,
      );
      final ImpositionResult layout = spec.layout();
      final List<CropMarkLine> marks = cropMarksForSheet(
        layout,
        style: spec.markStyle,
      );

      expect(marks, isNotEmpty);
      expect(marks.length, layout.count * 8);
      for (final CropMarkLine mark in marks) {
        expect(mark.lengthMm, greaterThan(0));
        expect(mark.x1, greaterThanOrEqualTo(0));
        expect(mark.x2, lessThanOrEqualTo(layout.sheetWidthMm));
        expect(mark.y1, greaterThanOrEqualTo(0));
        expect(mark.y2, lessThanOrEqualTo(layout.sheetHeightMm));
        expect(mark.isHorizontal || mark.x1 == mark.x2, isTrue);
      }
    });

    test('العلامات لا تلمس حدّ القطع (تبدأ بعد الابتعاد)', () {
      final ImpositionSpec spec = ImpositionSpec.fromDocument(
        card(),
        sheet: ImpositionSheet.a3,
      );
      final ImpositionResult layout = spec.layout();
      final double offset = spec.markStyle.offsetMm;
      expect(offset, greaterThan(0));

      for (final ImpositionPlacement p in layout.placements) {
        for (final CropMarkLine mark in cropMarksFor(
          p,
          sheetWidthMm: layout.sheetWidthMm,
          sheetHeightMm: layout.sheetHeightMm,
          style: spec.markStyle,
        )        ) {
          if (mark.isHorizontal) {
            // العلامة الأفقية تعيش **خارج** مدى الصندوق الأفقي دائماً.
            final double lo = math.min(mark.x1, mark.x2);
            final double hi = math.max(mark.x1, mark.x2);
            expect(
              hi <= p.leftMm - offset + 1e-9 ||
                  lo >= p.rightMm + offset - 1e-9,
              isTrue,
              reason: 'علامة أفقية تعبر الصندوق: $mark',
            );
          } else {
            final double lo = math.min(mark.y1, mark.y2);
            final double hi = math.max(mark.y1, mark.y2);
            expect(
              hi <= p.topMm - offset + 1e-9 ||
                  lo >= p.bottomMm + offset - 1e-9,
              isTrue,
              reason: 'علامة رأسية تعبر الصندوق: $mark',
            );
          }
        }
      }
    });

    test('خط أمان النزف يساوي المساحة داخل الهامش والاحتياط', () {
      final ImpositionSpec spec = ImpositionSpec.fromDocument(
        card(),
        sheet: ImpositionSheet.a3,
        marginMm: 5,
        bleedMm: 3,
      );
      final ImpositionResult layout = spec.layout();
      final Rect safe = bleedSafetyRect(layout);
      expect(layout.insetMm, 8);
      expect(safe.left, 8);
      expect(safe.top, 8);
      expect(safe.right, layout.sheetWidthMm - 8);
      expect(safe.bottom, layout.sheetHeightMm - 8);
    });

    test('المقاسات الصغيرة فقط تصلح للتجميع', () {
      expect(ImpositionSpec.isEligible(card()), isTrue);
      expect(ImpositionSpec.isEligible(seat()), isTrue);
      // A4 أطول ضلعه 297 ملم ⇒ خارج نطاق التجميع.
      expect(
        ImpositionSpec.isEligible(
          TemplateDocument(
            orientation: PageOrientation.landscape,
            paperSize: PaperSize.a4,
            elements: <TemplateElement>[],
          ),
        ),
        isFalse,
      );
    });
  });
}
