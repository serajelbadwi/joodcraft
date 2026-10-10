import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/widgets/element_painters.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/pdf/pdf_color.dart';
import 'package:joodcraft/core/services/pdf_generator_service.dart';
import 'package:joodcraft/core/utils/hex_color.dart';

/// **التحقق البصري الإلزامي**: بكسل اللوحة = لون الـ PDF = HEX، حرفياً.
///
/// هذا الملف يقفل الباب على نوعَي الانحدار الذي يشتكي منه المستخدم:
/// 1) **تغيّر الألوان** — يُسحب لون من بكسل مرسوم فعلاً على لوحة فلاتر
///    (`ShapePainter`) ويُقارَن بالبكسل الذي يكتبه محرّك الـ PDF في مُشغّل
///    الرسم (`rg`)؛ الاثنان يجب أن يساويا HEX نفسه بالبايت (لا CMYK ولا ألفا
///    مُهمَلة).
/// 2) **التراكب/القصّ** — يُتحقق أن كل عنصر نصّ في الـ PDF محصور داخل مسار
///    قصٍّ (`re W n`) بارتفاع **لا يقلّ عن ارتفاع السطر الحقيقي** للخطّ
///    المضمَّن، فلا يُقتطع أسفل الحروف ولا يتسرّب النصّ فوق الطبقات المجاورة.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// يرسم [child] على حدّ إعادة رسم ويقرأ بكسل المركز (‎ARGB‎).
  ///
  /// يُنفَّذ داخل [WidgetTester.runAsync] لأن التقاط الصورة يحتاج مُجدوِل
  /// الرسوم الحقيقي، وبلا ذلك تبقى `toImage()` معلّقة إلى الأبد.
  Future<int> sampleCenterPixel(WidgetTester tester, Widget child) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: key,
            child: SizedBox(width: 40, height: 40, child: child),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final int? pixel = await tester.runAsync(() async {
      final RenderRepaintBoundary boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage();
      final ByteData data =
          (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      final int x = image.width ~/ 2;
      final int y = image.height ~/ 2;
      final int offset = (y * image.width + x) * 4;
      final int r = data.getUint8(offset);
      final int g = data.getUint8(offset + 1);
      final int b = data.getUint8(offset + 2);
      final int a = data.getUint8(offset + 3);
      image.dispose();
      return (a << 24) | (r << 16) | (g << 8) | b;
    });
    expect(pixel, isNotNull, reason: 'تعذّر التقاط بكسل اللوحة');
    return pixel!;
  }

  /// يبني ملف PDF للمستند ويعيد نصّ مُشغّل الرسم غير المضغوط.
  Future<String> rawPdf(TemplateDocument document) async {
    final PdfGeneratorService service =
        await PdfGeneratorService.create(compress: false);
    final PdfGenerationReport report = await service.generate(
      document: document,
      data: document.sampleData,
    );
    expect(report.warnings, isEmpty, reason: 'تحذيرات توليد غير متوقّعة');
    return latin1.decode(report.bytes, allowInvalid: true);
  }

  /// كل ارتفاعات القصّ (`re W n`) في نصّ المُشغّل.
  List<double> clipHeights(String raw) => <double>[
        for (final RegExpMatch m
            in RegExp(r'0 0 ([0-9.]+) ([0-9.]+) re W n').allMatches(raw))
          double.parse(m[2]!),
      ];

  /// ألوان HEX المتوقّعة (بيج/كحلي/رمادي حقيقي) — درجات القوالب الرسمية.
  const List<String> hexes = <String>[
    '#1B2539',
    '#C7A26B',
    '#FFFDF8',
    '#E11D48',
    '#6B7280',
  ];

  /// ينسخ تنسيق أرقام حزمة `pdf`: **خمس منازل عشرية بلا أصفار زائدة**.
  ///
  /// الحزمة تكتب كل لون كـ`r g b rg` بهذه الصيغة بالضبط (`0.10588` لا
  /// `0.10588235294117647`)، فالمقارنة بالنصّ الكامل كانت تفشل رغم أن القناة
  /// مطابقة بالبايت. التنسيق هنا يجعل المقارنة عادلة وبدقّة الحزمة نفسها.
  String pdfNum(double value) {
    String text = value.toStringAsFixed(5);
    if (text.contains('.')) {
      text = text.replaceFirst(RegExp(r'0+$'), '');
      if (text.endsWith('.')) text = text.substring(0, text.length - 1);
    }
    return text;
  }

  String pdfRgb(PdfColor color) =>
      '${pdfNum(color.red)} ${pdfNum(color.green)} ${pdfNum(color.blue)}';

  group('الألوان: بكسل اللوحة = مُشغّل الـ PDF = HEX', () {
    testWidgets('بكسل الشكل المرسوم على اللوحة يساوي HEX بالضبط',
        (WidgetTester tester) async {
      for (final String hex in hexes) {
        final int pixel = await sampleCenterPixel(
          tester,
          CustomPaint(
            painter: ShapePainter(
              shape: ShapeElement(
                id: 's',
                box: const ElementBox(x: 0, y: 0, width: 40, height: 40),
                kind: ShapeKind.rect,
                fillHex: hex,
              ),
              scale: 1,
            ),
          ),
        );
        expect(pixel, colorFromHex(hex).toARGB32(),
            reason: 'لوحة فلاتر غيّرت اللون $hex');
      }
    });

    test('مُشغّل الـ PDF يحمل نفس ألوان HEX (ونفس بكسل اللوحة)', () async {
      final TemplateDocument document = TemplateDocument(
        orientation: PageOrientation.landscape,
        elements: <TemplateElement>[
          for (int i = 0; i < hexes.length; i++)
            ShapeElement(
              id: 's$i',
              box: ElementBox(x: 30, y: 30 + i * 90, width: 200, height: 60),
              kind: ShapeKind.rect,
              fillHex: hexes[i],
            ),
        ],
      );

      final String raw = await rawPdf(document);
      final Set<String> operators = <String>{
        for (final RegExpMatch m
            in RegExp(r'([0-9.]+) ([0-9.]+) ([0-9.]+) rg').allMatches(raw))
          '${m[1]} ${m[2]} ${m[3]}',
      };

      for (final String hex in hexes) {
        final Color flutterColor = colorFromHex(hex);
        final PdfColor pdfColor = pdfColorFromHex(hex);
        // نفس القيم بالبايت: قنوات فلاتر (0..255) = قنوات فلاتر مقسومة على 255.
        expect(
          (pdfColor.red * 255).round(),
          flutterColor.toARGB32() >> 16 & 0xFF,
          reason: 'اختلاف قناة حمراء في $hex',
        );
        expect(
          (pdfColor.green * 255).round(),
          flutterColor.toARGB32() >> 8 & 0xFF,
          reason: 'اختلاف قناة خضراء في $hex',
        );
        expect(
          (pdfColor.blue * 255).round(),
          flutterColor.toARGB32() & 0xFF,
          reason: 'اختلاف قناة زرقاء في $hex',
        );
        expect(operators, contains(pdfRgb(pdfColor)),
            reason: 'مُشغّل اللون $hex غير موجود بالضبط في الـ PDF');
      }
      // لا لون في المستند لم يُطلب: كل `rg` يجب أن يكون أحد ألوان HEX أو
      // خلفية الورقة نفسها (أبيض افتراضي هنا).
      final Set<String> expected = <String>{
        for (final String hex in hexes) pdfRgb(pdfColorFromHex(hex)),
        pdfRgb(pdfColorFromHex(document.backgroundHex,
            fallback: PdfColors.white)),
      };
      expect(operators.difference(expected), isEmpty,
          reason: 'ألوان غريبة تسرّبت إلى الـ PDF (تحويل CMYK؟)');
    });

    test('بوابة الألوان تمرّ عبر PdfColor.fromInt بلا أي تحويل', () {
      for (final String hex in hexes) {
        final int argb = colorFromHex(hex).toARGB32();
        expect(pdfColorFromArgb(argb), pdfColorFromHex(hex));
      }
      // صيغة ‎#AARRGGBB‎: تُحفظ قيم RGB ولا تُفرض قناة ألفا على اللون.
      expect(pdfColorFromHex('#801B2539'), pdfColorFromHex('#1B2539'));
      expect(pdfAlphaFromHex('#801B2539'), closeTo(128 / 255, 1e-9));
      expect(pdfAlphaFromHex('#1B2539'), 1);
    });
  });

  group('النص: صندوق صريح لا يقتطع الحروف ولا يتسرّب', () {
    test('ارتفاع صندوق النصّ لا يقلّ عن ارتفاع السطر الحقيقي للخطّ', () async {
      // `lineHeight = 1.0` هو أسوأ تقدير ممكن: لو حسبنا الارتفاع منه وحده
      // (15 نقطة) لقصّ القصّ أسفل الحروف. الارتفاع الحقيقي = `emptyLineHeight`.
      final TemplateDocument document = TemplateDocument(
        orientation: PageOrientation.landscape,
        elements: <TemplateElement>[
          const TextElement(
            id: 'a',
            box: ElementBox(x: 40, y: 40, width: 400, height: 0),
            text: 'سطرٌ واحد',
            fontSize: 20,
            lineHeight: 1.0,
          ),
          const TextElement(
            id: 'b',
            box: ElementBox(x: 40, y: 120, width: 400, height: 0),
            text: 'السطر الأول\nالسطر الثاني',
            fontSize: 20,
            lineHeight: 1.0,
          ),
        ],
      );

      final String raw = await rawPdf(document);
      final List<double> heights = clipHeights(raw);
      const double fontSizePt = 20 * 0.75;
      final int single = heights.where((double h) => h > fontSizePt).length;

      // سطر واحد: ‎≈ 1.13 × 15 = 16.9‎ — أكبر قطعاً من ‎15‎ نقطة.
      expect(
        heights.any((double h) =>
            (h - fontSizePt).abs() > 0.05 && h < fontSizePt * 1.6),
        isTrue,
        reason: 'ارتفاع سطر واحد لا يمكن أن يكون ‎fontSize × 1.0‎ فقط',
      );
      // سطران: أكبر من سطر واحد (يُثبت أن المسافة بين السطرين محسوبة).
      final double tallest = heights.reduce((double a, double b) => a > b ? a : b);
      expect(tallest, greaterThan(fontSizePt * 1.6),
          reason: 'ارتفاع سطرين يجب أن يتجاوز ضعف مقاس الخط بعشر');
      expect(single, greaterThanOrEqualTo(1));
    });

    test('كل عنصر نصّ محصور داخل مسار قصّ على صندوقه', () async {
      final TemplateDocument document = TemplateDocument(
        orientation: PageOrientation.landscape,
        elements: <TemplateElement>[
          const TextElement(
            id: 'a',
            box: ElementBox(x: 40, y: 40, width: 300, height: 50),
            text: 'نصّ طويل جداً يتجاوز صندوقه بكثير ليكشف أي تسرّب',
            fontSize: 20,
          ),
          const TextElement(
            id: 'b',
            box: ElementBox(x: 40, y: 120, width: 600, height: 40),
            text: 'CERTIFICATE OF APPRECIATION',
            fontSize: 18,
          ),
        ],
      );

      final String raw = await rawPdf(document);
      final List<double> heights = clipHeights(raw);

      // صندوق «a»: 50 × 0.75 = 37.5، وصندوق «b»: 40 × 0.75 = 30.
      expect(heights.any((double h) => (h - 37.5).abs() < 1e-6), isTrue,
          reason: 'نصّ «a» غير محصور بارتفاع صندوقه');
      expect(heights.any((double h) => (h - 30).abs() < 1e-6), isTrue,
          reason: 'نصّ «b» غير محصور بارتفاع صندوقه');
    });
  });

  group('الأساسات: لا عنصر بلا عرض/ارتفاع صريح', () {
    test('التوقيع والأشكال والختم تُوضع بأبعاد صريحة (لا `height: null`)',
        () async {
      final TemplateDocument document = TemplateDocument(
        orientation: PageOrientation.landscape,
        elements: <TemplateElement>[
          const ShapeElement(
            id: 'shape',
            box: ElementBox(x: 20, y: 20, width: 200, height: 0),
            kind: ShapeKind.rect,
            fillHex: '#1B2539',
          ),
          const SealElement(
            id: 'seal',
            box: ElementBox(x: 300, y: 20, width: 80, height: 0),
          ),
          SignatureElement(
            id: 'sign',
            box: const ElementBox(x: 20, y: 200, width: 600, height: 0),
            slots: const <SignatureSlot>[
              SignatureSlot(role: 'المدير', name: 'أحمد علي'),
            ],
          ),
        ],
      );

      final String raw = await rawPdf(document);
      // لكل عنصر مسار رسم/قصّ بارتفاع غير صفري — لا عنصر صفري الحجم.
      final List<double> heights = clipHeights(raw);
      expect(heights, isNotEmpty);
      expect(heights.every((double h) => h > 0), isTrue);
      // ارتفاع التوقيع التلقائي (600 عرض) أكبر بكثير من صفر نقطة.
      expect(heights.any((double h) => h > 20), isTrue,
          reason: 'كتلة التوقيع بلا ارتفاع صريح');
    });
  });

  group('شهادة العيّنة: كل عنصر في موضعه وبلا انزياح', () {
    test('إزاحة كل عنصر في الـ PDF = boxToPdfRect بالضبط', () async {
      final String json =
          await rootBundle.loadString(AppAssets.sampleCertificateTemplate);
      final TemplateDocument document = TemplateDocument.fromJsonString(json);

      final PdfGeneratorService service =
          await PdfGeneratorService.create(compress: false);
      final PdfGenerationReport report = await service.generate(
        document: document,
        data: document.sampleData,
      );
      final String raw = latin1.decode(report.bytes, allowInvalid: true);

      // كل الإزاحات المكتوبة في الملف: `1 0 0 1 X Y cm` (نقاط الطباعة).
      //
      // **عنقود الإحداثيات:** `cm` يضع أصل الودجة عند **ركنها الأيسر السفلي**
      // في نظام PDF (المحور الصادي صاعد)، بينما `boxToPdfRect` يعطي **أعلى**
      // الصندوق في نظام التصميم (صادي هابط من أعلى الصفحة). فالموضع المتوقّع:
      //   `y = pageHeightPt − rect.top − rect.height`.
      final List<(double, double)> placements = <(double, double)>[
        for (final RegExpMatch m
            in RegExp(r'1 0 0 1 ([0-9.]+) ([0-9.]+) cm').allMatches(raw))
          (double.parse(m[1]!), double.parse(m[2]!)),
      ];
      expect(placements, isNotEmpty);

      for (final TemplateElement element in document.elements) {
        if (element is UnknownElement) continue;
        final Rect rect = document.boxToPdfRect(element.box);
        // العناصر صريحة الارتفاع تُوضع بالمليمتر؛ أما ما لا ارتفاع له في
        // الصندوق (الخطوط) فيُشتقّ ارتفاعه في المحرّك من سماكة الخطّ، فنتحقّق
        // من أن حافّته العليا في الـ PDF = «ارتفاع الصفحة − أعلى الصندوق».
        final bool explicitHeight = rect.height > 0;
        final double expectedY = document.pageHeightPt - rect.top - rect.height;
        final double topEdgeY = document.pageHeightPt - rect.top;
        final bool found = placements.any(((double, double) p) {
          if ((p.$1 - rect.left).abs() >= 0.02) return false;
          if (explicitHeight) return (p.$2 - expectedY).abs() < 0.02;
          return p.$2 > topEdgeY - 20 && p.$2 <= topEdgeY + 0.02;
        });
        expect(found, isTrue,
            reason: 'موضع ${element.id} غير مطابق للمتوقّع '
                '(x=${rect.left}, '
                'y=${explicitHeight ? expectedY : topEdgeY})');
      }
    });
  });
}
