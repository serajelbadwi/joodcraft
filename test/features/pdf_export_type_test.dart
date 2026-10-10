import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/locale/app_locale.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/pdf/pdf_font_catalog.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/core/widgets/pdf_template_preview.dart';
import 'package:joodcraft/l10n/generated/app_localizations.dart';

/// اختيار **نوع التصدير** في شاشة تصدير PDF (`PdfTemplatePreview`):
///
/// 1. الضغط على «تصدير PDF» يفتح حوار «نوع التصدير» بخياري «صور» و«فيكتور».
/// 2. «صور» مختار افتراضياً (علامة صحّة ممتلئة) وهو الخيار المفعّل.
/// 3. «فيكتور» معطّل: دائرة فارغة + شارة «قريباً»، وضغطه يعرض رسالة «قريباً»
///    بلا تغيير الاختيار وبلا إغلاق الحوار.
/// 4. التأكيد يغلق الحوار ويسلك مسار «صور» (دالة التصدير الحالية)، والإلغاء
///    يغلق بلا تصدير.
void main() {
  // الخطوط تُخزَّن مؤقتاً كـ Future مرتبط بالنطاق الزمني (zone): يجب تصفيرها
  // قبل كل اختبار حتى لا يتسرّب كاش من اختبار ودجة سابق.
  setUp(PdfFontSet.resetCache);
  tearDown(PdfFontSet.resetCache);

  TemplateDocument document() => TemplateDocument(
    orientation: PageOrientation.landscape,
    elements: const <TemplateElement>[
      TextElement(
        id: 'title',
        box: ElementBox(x: 200, y: 200, width: 400, height: 80),
        text: 'شهادة إتمام',
      ),
    ],
  );

  Finder dialog() =>
      find.byKey(const ValueKey<String>('pdf-export-type-dialog'));

  Finder option(String kind) =>
      find.byKey(ValueKey<String>('pdf-export-option-$kind'));

  Finder confirmButton() =>
      find.byKey(const ValueKey<String>('pdf-export-confirm'));

  Finder cancelButton() =>
      find.byKey(const ValueKey<String>('pdf-export-cancel'));

  /// بناء شاشة التصدير كاملة (معاينة + ترويسة) بمندوبي ترجمة حقيقيين.
  Future<void> pumpExportScreen(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('ar'),
        supportedLocales: AppLocales.locales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: PdfTemplatePreview(
            exportFileName: 'joodcraft-certificate.pdf',
            document: document(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(PdfTemplatePreview)));

  Finder exportLabel(WidgetTester tester) =>
      find.text(l10nOf(tester).commonExportPdf);

  /// زر «تصدير PDF» في الترويسة — يُقصد عبر `ButtonStyleButton` لأن
  /// `FilledButton.icon` يبني صنفاً فرعياً خاصاً (`_FilledButtonWithIcon`).
  Finder exportButton(WidgetTester tester) => find.ancestor(
    of: exportLabel(tester),
    matching: find.byWidgetPredicate((Widget w) => w is ButtonStyleButton),
  );

  /// ينتظر اكتمال التوليد (الخطوط المحزومة + أول ملف PDF) فيصير الزر متاحاً.
  Future<void> waitForEnabledExportButton(WidgetTester tester) async {
    for (int i = 0; i < 600; i++) {
      final Finder button = exportButton(tester);
      if (button.evaluate().length == 1 &&
          tester.widget<ButtonStyleButton>(button).enabled) {
        return;
      }
      await tester.pump(const Duration(milliseconds: 16));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
    }
    fail('لم يتاح زر «تصدير PDF» خلال المهلة');
  }

  /// ينتظر ظهور [finder] مع السماح للعمل الحقيقي (تحميل الخطوط وتوليد الـ PDF)
  /// بالاكتمال — لا `pumpAndSettle` لأن مؤشّر التحميل يدور بلا توقّف في الاختبار.
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

  /// يفتح حوار «نوع التصدير» من زر «تصدير PDF» في الترويسة.
  Future<AppLocalizations> openExportTypeDialog(WidgetTester tester) async {
    await pumpExportScreen(tester);
    await waitForEnabledExportButton(tester);
    await tester.tap(exportLabel(tester));
    await tester.pump();
    await waitFor(tester, dialog());
    return l10nOf(tester);
  }

  testWidgets('زر «تصدير PDF» يفتح «نوع التصدير» بخياري «صور» و«فيكتور»', (
    WidgetTester tester,
  ) async {
    final AppLocalizations l10n = await openExportTypeDialog(tester);

    expect(dialog(), findsOneWidget);
    expect(find.text(l10n.pdfExportTypeTitle), findsOneWidget);
    expect(find.text(l10n.pdfExportTypeImages), findsOneWidget);
    expect(find.text(l10n.pdfExportTypeVector), findsOneWidget);
    expect(find.text(l10n.pdfExportTypeImagesDesc), findsOneWidget);
    expect(find.text(l10n.pdfExportTypeVectorDesc), findsOneWidget);
    expect(
      find.text(l10n.pdfExportTypeImagesNotCopyable),
      findsOneWidget,
      reason: 'بطاقة «صور» تذكر أن النص غير قابل للنسخ',
    );
  });

  testWidgets('«صور» هو الخيار المختار افتراضياً', (WidgetTester tester) async {
    await openExportTypeDialog(tester);

    // علامة صحّة ممتلئة داخل بطاقة «صور» وحدها.
    expect(
      find.descendant(
        of: option('images'),
        matching: find.byIcon(Icons.check_circle_rounded),
      ),
      findsOneWidget,
    );
    // بطاقة «فيكتور» بدائرة فارغة (غير مختارة).
    expect(
      find.descendant(
        of: option('vector'),
        matching: find.byIcon(Icons.radio_button_unchecked),
      ),
      findsOneWidget,
    );
  });

  testWidgets('«فيكتور» معطّل مع شارة «قريباً»', (WidgetTester tester) async {
    final AppLocalizations l10n = await openExportTypeDialog(tester);

    expect(
      find.descendant(
        of: option('vector'),
        matching: find.byIcon(Icons.auto_awesome_outlined),
      ),
      findsOneWidget,
      reason: 'بطاقة الفيكتور تحمل أيقونة الوصف المميّز',
    );
    expect(
      find.descendant(
        of: option('vector'),
        matching: find.byKey(
          const ValueKey<String>('pdf-export-coming-soon-badge'),
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(l10n.pdfExportTypeComingSoon), findsOneWidget);
    // التعطيل مرئي: البطاقة معتمة جزئياً (‎Opacity 0.6‎) بلا إطار اختيار.
    final Opacity faded = tester.widget<Opacity>(
      find.descendant(of: option('vector'), matching: find.byType(Opacity)),
    );
    expect(faded.opacity, 0.6);
  });

  testWidgets(
    'الضغط على «فيكتور» يُظهر «قريباً» ولا يُصدّر ولا يُغيّر الاختيار',
    (WidgetTester tester) async {
      final AppLocalizations l10n = await openExportTypeDialog(tester);

      await tester.tap(option('vector'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(l10n.pdfExportTypeComingSoonMessage), findsOneWidget);
      // الحوار ما زال مفتوحاً والاختيار لم ينتقل عن «صور».
      expect(dialog(), findsOneWidget);
      expect(
        find.descendant(
          of: option('images'),
          matching: find.byIcon(Icons.check_circle_rounded),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('تأكيد «صور» يغلق الحوار ويسلك مسار التصدير الحالي', (
    WidgetTester tester,
  ) async {
    await openExportTypeDialog(tester);

    await tester.tap(confirmButton());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(dialog(), findsNothing, reason: 'الحوار يُقفل بعد التأكيد');
    // التأكيد أسقط مسار «صور» الحالي (منتقي الحفظ) — في بيئة الاختبار بلا
    // إضافة ملفات قد يظهر شريط فشل، وهو دليل على أن المسار استُدعي أصلاً.
    expect(exportLabel(tester), findsOneWidget);
  });

  testWidgets('الإلغاء يغلق الحوار بلا تصدير', (WidgetTester tester) async {
    await openExportTypeDialog(tester);

    await tester.tap(cancelButton());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(dialog(), findsNothing);
  });
}
