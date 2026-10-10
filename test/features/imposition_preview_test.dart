import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/locale/app_locale.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/pdf/pdf_font_catalog.dart';
import 'package:joodcraft/core/print/crop_marks.dart';
import 'package:joodcraft/core/print/imposition_calculator.dart';
import 'package:joodcraft/core/print/widgets/imposition_preview.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/core/widgets/pdf_template_preview.dart';
import 'package:joodcraft/l10n/generated/app_localizations.dart';

/// اختبارات عرض **معاينة التجميع** على الشاشة:
///
/// 1. الطبقات الثلاث تُرسم فعلاً: الورقة/القطع، وعلامات القصّ المتجهية،
///    وخط أمان النزف (غير القابل للطباعة).
/// 2. كل طبقة تُخفى وحدها عبر مفتاحها بلا تأثير على البقية.
/// 3. الورقة التي لا تتسع للقطعة تُظهر رسالة عربية واضحة بدل رسم فارغ.
/// 4. شاشة التصدير تُظهر مفتاح «تجميع للطباعة» للمقاسات الصغيرة فقط،
///    وتبديله يستبدل معاينة الصفحة بشبكة التجميع.
void main() {
  // الخطوط تُخزَّن مؤقتاً كـ Future مرتبط بالنطاق الزمني (zone): لو بقيت من
  // اختبار ودجة سابق لما اكتملت أبداً في اختبار لاحق، فيبدو المستند "عالقاً
  // في التحميل". لذلك يُصفَّر المخزون قبل كل اختبار.
  setUp(PdfFontSet.resetCache);
  tearDown(PdfFontSet.resetCache);

  /// بطاقة 90×55 ملم — مقاس صغير يصلح للتجميع.
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

  /// مستند A4 — أطول من حدود التجميع فلا يُتاح له المفتاح.
  TemplateDocument a4() => TemplateDocument(
        orientation: PageOrientation.portrait,
        paperSize: PaperSize.a4,
        elements: <TemplateElement>[
          const TextElement(
            id: 'body',
            box: ElementBox(x: 40, y: 40, width: 480, height: 80),
            text: 'عقد',
          ),
        ],
      );

  Future<void> pumpHarness(WidgetTester tester, Widget child) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // مندوبو الترجمة الحقيقيون: تُفحص نصوص ARB الفعلية لا الاحتياطية.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('ar'),
        supportedLocales: AppLocales.locales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: child),
      ),
    );
    // إطار واحد يكفي لبناء الطبقات؛ أما انتظار العمل الحقيقي (تحميل الخطوط
    // وتوليد الـ PDF) فله [waitFor] لأن مؤشّرات التحميل لا "تستقرّ" أبداً هنا.
    await tester.pump();
  }

  Finder layer(String key) => find.byKey(ValueKey<String>(key));

  Finder toggle() =>
      find.byKey(const ValueKey<String>('ptp-imposition-toggle'));

  Finder impositionPreview() =>
      find.byKey(const ValueKey<String>('imposition-preview'));

  /// النصوص المرئية حالياً — تُطبع عند فشل الانتظار لتسهيل التشخيص.
  List<String> visibleTexts(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((Text text) => text.data ?? '')
      .where((String value) => value.isNotEmpty)
      .toList();

  /// ينتظر ظهور [finder] مع السماح للعمل الحقيقي (تحميل الخطوط المحزومة
  /// وتوليد ملف PDF) بالاكتمال.
  ///
  /// لا يُستخدم `pumpAndSettle` هنا: مؤشّر التحميل داخلياً يدور بلا توقّف
  /// في بيئة الاختبار (لا إضافة طباعة)، فيظلّ الـ settle ينتظر إلى الأبد.
  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    for (int i = 0; i < 600; i++) {
      if (finder.evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 16));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
    }
    fail('لم يظهر العنصر المنتظر خلال المهلة: $finder');
  }

  /// ينتظر حتى يختفي [finder] (مع إتاحة العمل الحقيقي للاكتمال).
  Future<void> waitUntilGone(WidgetTester tester, Finder finder) async {
    for (int i = 0; i < 600; i++) {
      if (finder.evaluate().isEmpty) return;
      await tester.pump(const Duration(milliseconds: 16));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
    }
    fail('لم يختفِ العنصر المنتظر خلال المهلة: $finder'
        '\nالنصوص الظاهرة: ${visibleTexts(tester)}');
  }

  /// تعطّش عدة إطارات قصيرة مع إتاحة العمل الحقيقي (توليد الـ PDF في الخلفية).
  Future<void> drain(WidgetTester tester, {int rounds = 60}) async {
    for (int i = 0; i < rounds; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
    }
  }

  CropMarksPainter cropPainter(WidgetTester tester) => tester
      .widget<CustomPaint>(layer(ImpositionPreview.cropMarksKey))
      .painter! as CropMarksPainter;

  BleedSafetyPainter bleedPainter(WidgetTester tester) => tester
      .widget<CustomPaint>(layer(ImpositionPreview.bleedSafetyKey))
      .painter! as BleedSafetyPainter;

  // ==========================================================================
  //  طبقات المعاينة
  // ==========================================================================
  group('طبقات معاينة التجميع', () {
    testWidgets('الطبقات الثلاث تُرسم: الورقة وعلامات القصّ وخط الأمان',
        (WidgetTester tester) async {
      final TemplateDocument document = card();
      final ImpositionSpec spec = ImpositionSpec.fromDocument(
        document,
        sheet: ImpositionSheet.a3,
      );
      await pumpHarness(
        tester,
        ImpositionPreview(spec: spec, document: document),
      );

      expect(layer(ImpositionPreview.sheetKey), findsOneWidget);
      expect(layer(ImpositionPreview.cropMarksKey), findsOneWidget);
      expect(layer(ImpositionPreview.bleedSafetyKey), findsOneWidget);

      final ImpositionResult layout = spec.layout();
      expect(layout.count, greaterThan(0));

      // علامات القصّ: ثماني علامات لكل قطعة موزّعة على الأركان.
      final List<CropMarkLine> marks = cropPainter(tester).marks;
      expect(marks, hasLength(layout.count * 8));
      for (final CropMarkLine mark in marks) {
        expect(mark.lengthMm, greaterThan(0));
        expect(mark.x1, greaterThanOrEqualTo(0));
        expect(mark.y1, greaterThanOrEqualTo(0));
        expect(mark.x2, lessThanOrEqualTo(layout.sheetWidthMm + 1e-9));
        expect(mark.y2, lessThanOrEqualTo(layout.sheetHeightMm + 1e-9));
      }

      // خط أمان النزف = المساحة داخل الهامش (وسمك النزف إن وُجد).
      final Rect safe = bleedPainter(tester).rect;
      expect(safe.left, spec.marginMm + spec.bleedMm);
      expect(safe.right, layout.sheetWidthMm - spec.marginMm - spec.bleedMm);
    });

    testWidgets('إخفاء علامات القصّ يُخفي طبقتها وحدها',
        (WidgetTester tester) async {
      final TemplateDocument document = card();
      final ImpositionSpec spec = ImpositionSpec.fromDocument(
        document,
        sheet: ImpositionSheet.a3,
      );
      await pumpHarness(
        tester,
        ImpositionPreview(
          spec: spec,
          document: document,
          showCropMarks: false,
        ),
      );

      expect(layer(ImpositionPreview.cropMarksKey), findsNothing);
      expect(layer(ImpositionPreview.sheetKey), findsOneWidget);
      expect(layer(ImpositionPreview.bleedSafetyKey), findsOneWidget);
    });

    testWidgets('إخفاء خط الأمان يُخفي طبقته وحدها',
        (WidgetTester tester) async {
      final TemplateDocument document = card();
      final ImpositionSpec spec = ImpositionSpec.fromDocument(
        document,
        sheet: ImpositionSheet.a3,
      );
      await pumpHarness(
        tester,
        ImpositionPreview(
          spec: spec,
          document: document,
          showBleedSafety: false,
        ),
      );

      expect(layer(ImpositionPreview.bleedSafetyKey), findsNothing);
      expect(layer(ImpositionPreview.sheetKey), findsOneWidget);
      expect(layer(ImpositionPreview.cropMarksKey), findsOneWidget);
    });

    testWidgets('قطعة لا تتسعها الورقة تُظهر رسالة عربية بلا ورقة',
        (WidgetTester tester) async {
      final TemplateDocument document = card();
      // هامش 100 ملم على A4 لا يترك متسعاً للبطاقة.
      final ImpositionSpec spec = ImpositionSpec.fromDocument(
        document,
        sheet: ImpositionSheet.a4,
        marginMm: 100,
        gutterXMm: 0,
        gutterYMm: 0,
      );
      expect(spec.layout().isEmpty, isTrue);

      await pumpHarness(
        tester,
        ImpositionPreview(spec: spec, document: document),
      );

      // لا ورقة ولا طبقات زخرفية — رسالة إرشادية فقط.
      expect(layer(ImpositionPreview.sheetKey), findsNothing);
      expect(layer(ImpositionPreview.cropMarksKey), findsNothing);

      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(ImpositionPreview)),
      );
      expect(find.text(l10n.ptpImpositionNoFit), findsOneWidget);
      expect(find.textContaining('A4'), findsOneWidget);
    });
  });

  // ==========================================================================
  //  شاشة التصدير: مفتاح «تجميع للطباعة»
  // ==========================================================================
  group('مفتاح التجميع في شاشة التصدير', () {
    testWidgets('المقاس الصغير يُتاح له المفتاح ويبدّل المعاينة',
        (WidgetTester tester) async {
      final TemplateDocument document = card();
      await pumpHarness(
        tester,
        PdfTemplatePreview(
          exportFileName: 'card.pdf',
          document: document,
        ),
      );

      // يُنتظر تحميل المستند (يظهر المفتاح بعد ذلك) — والمفتاح معطّل مبدئياً.
      await waitFor(tester, toggle());
      expect(tester.widget<Switch>(toggle()).value, isFalse);
      expect(impositionPreview(), findsNothing);

      // التبديل ⇒ شبكة التجميع بطبقاتها الثلاث (تُرسم من المواصفة فوراً).
      await tester.tap(toggle());
      await waitFor(tester, impositionPreview());

      expect(tester.widget<Switch>(toggle()).value, isTrue);
      expect(layer(ImpositionPreview.sheetKey), findsOneWidget);
      expect(layer(ImpositionPreview.cropMarksKey), findsOneWidget);
      expect(layer(ImpositionPreview.bleedSafetyKey), findsOneWidget);
      // شبكة التجميع تحمل أكثر من قطعة على الورقة (تكرار البطاقة).
      expect(cropPainter(tester).marks.length, greaterThan(8));

      // الرجوع ⇒ تعود معاينة الصفحة العادية.
      await tester.tap(toggle());
      await drain(tester);

      expect(tester.widget<Switch>(toggle()).value, isFalse);
      expect(impositionPreview(), findsNothing);
    });

    testWidgets('مقاس A4 لا يُتاح له مفتاح التجميع',
        (WidgetTester tester) async {
      await pumpHarness(
        tester,
        PdfTemplatePreview(
          exportFileName: 'contract.pdf',
          document: a4(),
        ),
      );

      // يُنتظر انتهاء التوليد أوّلاً حتى لا يكون الغياب مجرّد «ما زال يحمّل».
      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(PdfTemplatePreview)),
      );
      await waitUntilGone(tester, find.text(l10n.commonGenerating));

      // المستند حُمّل فعلاً (شارة المقاس ظاهرة) بلا خطأ توليد...
      expect(find.textContaining('A4'), findsOneWidget);
      expect(find.text(l10n.ptpGenerateFailedTitle), findsNothing);
      // ...ومع ذلك لا يُتاح مفتاح التجميع لهذا المقاس الكبير.
      expect(toggle(), findsNothing);
      expect(impositionPreview(), findsNothing);
    });
  });
}
