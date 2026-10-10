import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/editor/widgets/element_effects.dart';
import 'package:joodcraft/core/editor/widgets/element_painters.dart';
import 'package:joodcraft/core/editor/widgets/element_view.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/theme/app_theme.dart';

/// اختبارات **رسم التأثيرات على اللوحة** (Prompt 1.4):
/// * النص: ظل متوسّع (حلقة نسخ) + توهّج خارجي في `TextStyle.shadows`،
///   وتوهّج داخلي كطبقة نص ثانية بحدّ مطموس إلى الداخل.
/// * الصورة: مصفوفة `ColorFilter` للضبط اللوني + طبقات الظل/التوهّج.
/// * الشكل: التوهّج يُرسم فعلاً **خارج** حدود الشكل (فحص بكسل حقيقي) والداخلي
///   داخله.
void main() {
  Widget host(Widget child) => MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(child: SizedBox(width: 300, height: 160, child: child)),
        ),
      );

  Widget view(TemplateElement element, {double scale = 1}) => host(
        ElementView(
          element: element,
          document: TemplateDocument(elements: <TemplateElement>[element]),
          scale: scale,
        ),
      );

  const ElementBox box = ElementBox(x: 0, y: 0, width: 260, height: 80);

  group('تأثيرات النص', () {
    testWidgets('التوهّج الخارجي بلا توسيع = ظل واحد بلا إزاحة',
        (WidgetTester tester) async {
      const TextElement text = TextElement(
        id: 't',
        box: box,
        text: 'نص متوهّج',
        outerGlow: GlowEffect(colorHex: '#FFD166', radius: 10, opacity: 0.9),
      );
      final List<Shadow>? shadows = editorTextShadows(
        null,
        1,
        outerGlow: text.outerGlow,
      );
      expect(shadows, hasLength(1));
      expect(shadows!.single.offset, Offset.zero);
      expect(shadows.single.blurRadius, 10);
      expect(shadows.single.color.a, closeTo(0.9, 0.01));

      await tester.pumpWidget(view(text));
      await tester.pump();
      final Text rendered = tester.widget<Text>(find.text('نص متوهّج'));
      expect(rendered.style!.shadows, hasLength(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('التوسيع يضيف حلقة نسخ مُزاحة حول النص',
        (WidgetTester tester) async {
      const TextElement text = TextElement(
        id: 't2',
        box: box,
        text: 'متوسّع',
        outerGlow: GlowEffect(radius: 4, spread: 6),
      );
      final List<Shadow>? shadows = editorTextShadows(
        null,
        1,
        outerGlow: text.outerGlow,
      );
      // نسخة مركزية + ثمانية اتجاهات على المحيط.
      expect(shadows, hasLength(9));
      final Iterable<Shadow> ring = shadows!.skip(1);
      for (final Shadow shadow in ring) {
        expect(
          shadow.offset.distance,
          closeTo(6, 1e-6),
          reason: 'كل نسخ الحلقة على بعد التوسيع نفسه',
        );
      }

      await tester.pumpWidget(view(text));
      await tester.pump();
      final Text rendered = tester.widget<Text>(find.text('متوسّع'));
      expect(rendered.style!.shadows, hasLength(9));
    });

    testWidgets('ظل النص المتوسّع والظل العادي يجتمعان',
        (WidgetTester tester) async {
      const TextShadow shadow = TextShadow(blurRadius: 3, spread: 5);
      expect(editorTextShadows(shadow, 1), hasLength(9));
      // بلا توسيع يبقى ظلاً واحداً كما كان (لا انحدار في السلوك القديم).
      expect(
        editorTextShadows(const TextShadow(blurRadius: 3), 1),
        hasLength(1),
      );
    });

    testWidgets('التوهّج الداخلي يضيف طبقة نص بحدّ مطموس إلى الداخل',
        (WidgetTester tester) async {
      const TextElement text = TextElement(
        id: 't3',
        box: box,
        text: 'داخلي',
        innerGlow: GlowEffect(colorHex: '#EF6C00', radius: 6),
      );
      await tester.pumpWidget(view(text));
      await tester.pump();

      // طبقتان: الأصل + التوهّج الداخلي فوقه.
      final Finder texts = find.text('داخلي');
      expect(texts, findsNWidgets(2));

      final Text base = tester.widget<Text>(texts.first);
      expect(base.style!.foreground, isNull);
      expect(base.style!.color, isNotNull);

      final Text glowLayer = tester.widget<Text>(texts.last);
      final Paint? paint = glowLayer.style!.foreground;
      expect(paint, isNotNull);
      expect(paint!.maskFilter, isNotNull);
      expect(paint.color.r, closeTo(0xEF / 255, 0.002));
      expect(paint.color.g, closeTo(0x6C / 255, 0.002));
      expect(paint.color.b, closeTo(0, 0.002));
      expect(paint.color.a, closeTo(0.85, 0.01));
      expect(tester.takeException(), isNull);
    });

    testWidgets('بلا توهّج داخلي تبقى طبقة نص واحدة', (WidgetTester tester) async {
      const TextElement text = TextElement(id: 't4', box: box, text: 'عادي');
      await tester.pumpWidget(view(text));
      await tester.pump();
      expect(find.text('عادي'), findsOneWidget);
      expect(editorTextInnerGlowPaint(text, 1), isNull);
    });
  });

  group('ضبط الصورة اللوني على اللوحة', () {
    ImageElement image({ElementAdjustments? adjustments, ShapeShadow? shadow, GlowEffect? glow}) =>
        ImageElement(
          id: 'i',
          box: box,
          sourceKind: ImageSourceKind.asset,
          path: 'assets/images/logo.png',
          adjustments: adjustments,
          shadow: shadow,
          outerGlow: glow,
        );

    testWidgets('الضبط الفعّال يُغلّف الصورة بـColorFiltered واحد',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        view(image(adjustments: const ElementAdjustments(brightness: 0.3))),
      );
      await tester.pump();

      expect(find.byType(ColorFiltered), findsOneWidget);
      final ColorFiltered filtered =
          tester.widget<ColorFiltered>(find.byType(ColorFiltered));
      expect(filtered.colorFilter, isA<ColorFilter>());
      expect(tester.takeException(), isNull);
    });

    testWidgets('بلا ضبط لا تُضاف أي طبقة تصفية', (WidgetTester tester) async {
      await tester.pumpWidget(view(image()));
      await tester.pump();
      expect(find.byType(ColorFiltered), findsNothing);
      expect(elementAdjustmentFilter(null), isNull);
      expect(elementAdjustmentFilter(ElementAdjustments.none), isNull);
    });

    testWidgets('الظل والتوهّج يضيفان طبقات حول الصورة',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        view(image(
          shadow: const ShapeShadow(colorHex: '#000000', opacity: 0.5),
          glow: const GlowEffect(colorHex: '#FFD166', radius: 6),
        )),
      );
      await tester.pump();

      // طبقتان ظلّيتان (ظل + توهّج) كلٌّ منهما مُلوّنة بـsrcIn.
      final Iterable<ColorFiltered> filters =
          tester.widgetList<ColorFiltered>(find.byType(ColorFiltered));
      expect(filters.length, greaterThanOrEqualTo(2));
      expect(tester.takeException(), isNull);
    });
  });

  group('توهّج الشكل — فحص بكسل حقيقي', () {
    /// يرسم الشكل على لوحة **أكبر منه** (120×120 والشكل 80×80 في وسطها)
    /// ثم يعيد بكسلات الناتج `RGBA`.
    ///
    /// هامش الـ20 بكسل حول الشكل هو جوهر الاختبار: التوهّج الخارجي يجب أن
    /// يُرسم فيه، ولو كان الرسم محصوراً في حدود الشكل لما ظهر أي أثر.
    ///
    /// يُستعمل `toImageSync` عمداً — النسخة غير المتزامنة لا تُكمل في بيئة
    /// الأختبار (لا مهبط رسم)، وما زلنا نقرأ البكسلات عبر `toByteData`.
    Future<Uint8List> rasterize(WidgetTester tester, ShapeElement shape) async {
      final Uint8List? bytes = await tester.runAsync<Uint8List?>(() async {
        final ui.PictureRecorder recorder = ui.PictureRecorder();
        final Canvas canvas = Canvas(recorder);
        canvas.translate(20, 20);
        ShapePainter(shape: shape, scale: 1).paint(canvas, const Size(80, 80));
        final ui.Image image = recorder.endRecording().toImageSync(120, 120);
        final ByteData? data =
            await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        return data == null
            ? null
            : Uint8List.view(data.buffer, data.offsetInBytes, data.lengthInBytes);
      });
      expect(bytes, isNotNull);
      return bytes!;
    }

    /// قراءة بكسل من بايتات `rawRgba` (ترتيب R,G,B,A).
    ({int r, int g, int b, int a}) pixelAt(Uint8List bytes, int x, int y) {
      final int index = (y * 120 + x) * 4;
      return (
        r: bytes[index],
        g: bytes[index + 1],
        b: bytes[index + 2],
        a: bytes[index + 3],
      );
    }

    const ShapeElement plainWhite = ShapeElement(
      id: 's',
      kind: ShapeKind.rect,
      box: ElementBox(x: 0, y: 0, width: 80, height: 80),
      fillHex: '#FFFFFF',
    );

    testWidgets('بلا توهّج: لا شيء يُرسم خارج حدود الشكل',
        (WidgetTester tester) async {
      final Uint8List bytes = await rasterize(tester, plainWhite);
      // خارج الشكل (المستطيل 20..100) قريباً من حدّه.
      expect(pixelAt(bytes, 106, 60).a, 0);
      expect(pixelAt(bytes, 60, 60).a, 255);
    });

    testWidgets('التوهّج الخارجي يرسم خارج الحد ويحمل لونه',
        (WidgetTester tester) async {
      const ShapeElement glowing = ShapeElement(
        id: 's2',
        kind: ShapeKind.rect,
        box: ElementBox(x: 0, y: 0, width: 80, height: 80),
        fillHex: '#FFFFFF',
        outerGlow: GlowEffect(
          colorHex: '#FF0000',
          radius: 10,
          spread: 2,
          opacity: 1,
        ),
      );
      final Uint8List bytes = await rasterize(tester, glowing);

      final ({int r, int g, int b, int a}) near = pixelAt(bytes, 105, 60);
      expect(near.a, greaterThan(0), reason: 'التوهّج يجب أن يخرج عن الحدّ');
      expect(near.r, greaterThan(near.g), reason: 'ولونه أحمر');
      expect(near.r, greaterThan(near.b));

      // ويبهت كلما ابتعدنا عن الحد.
      expect(pixelAt(bytes, 114, 60).a, lessThanOrEqualTo(near.a));
    });

    testWidgets('التوهّج الداخلي يلوّن الحدّ من الداخل وليس المركز',
        (WidgetTester tester) async {
      const ShapeElement glowing = ShapeElement(
        id: 's3',
        kind: ShapeKind.rect,
        box: ElementBox(x: 0, y: 0, width: 80, height: 80),
        fillHex: '#FFFFFF',
        innerGlow: GlowEffect(
          colorHex: '#FF0000',
          radius: 12,
          spread: 2,
          opacity: 1,
        ),
      );
      final Uint8List bytes = await rasterize(tester, glowing);

      // داخل الحدّ بقليل: أحمر متقدّم على الأخضر/الأزرق.
      final ({int r, int g, int b, int a}) edge = pixelAt(bytes, 24, 60);
      expect(edge.a, 255);
      expect(edge.r, greaterThan(edge.g));

      // وفي المركز يعود التعبئة البيضاء كما هي.
      final ({int r, int g, int b, int a}) center = pixelAt(bytes, 60, 60);
      expect(center.r, greaterThan(200));
      expect(center.g, greaterThan(200));
      expect(center.b, greaterThan(200));
      expect(center.r, closeTo(center.g, 30));
    });

    testWidgets('شفافية الظل تُنقص كثافته المرسومة', (WidgetTester tester) async {
      const ShapeElement shape = ShapeElement(
        id: 's4',
        kind: ShapeKind.rect,
        box: ElementBox(x: 0, y: 0, width: 80, height: 80),
        fillHex: '#FFFFFF',
        shadow: ShapeShadow(
          colorHex: '#000000',
          blurRadius: 0,
          offsetX: 10,
          offsetY: 10,
          opacity: 1,
        ),
      );
      final ShapeElement faint = shape.copyWith(
        shadow: shape.shadow!.copyWith(opacity: 0.25),
      );

      final Uint8List strong = await rasterize(tester, shape);
      final Uint8List weak = await rasterize(tester, faint);

      // خارج الشكل في اتجاه الإزاحة (20+80+10 = 110).
      final int strongAlpha = pixelAt(strong, 108, 108).a;
      final int weakAlpha = pixelAt(weak, 108, 108).a;
      expect(strongAlpha, greaterThan(0));
      expect(weakAlpha, lessThan(strongAlpha));
    });
  });

  group('عزل طبقات التأثير — لا تسرّب إلى مساحة العمل', () {
    /// يرسم [paint] لعنصر بمقياس [elementSize] داخل لوحة أكبر ([canvasSize])
    /// بإزاحة (20،20) ثم يعيد بايتات `rawRgba` (ترتيب R,G,B,A).
    Future<Uint8List> rasterizeIsolated(
      WidgetTester tester, {
      required Size canvasSize,
      required Size elementSize,
      required void Function(Canvas canvas, Size size) paint,
    }) async {
      final Uint8List? bytes = await tester.runAsync<Uint8List?>(() async {
        final ui.PictureRecorder recorder = ui.PictureRecorder();
        final Canvas canvas = Canvas(recorder);
        canvas.translate(20, 20);
        paint(canvas, elementSize);
        final ui.Image image = recorder
            .endRecording()
            .toImageSync(canvasSize.width.toInt(), canvasSize.height.toInt());
        final ByteData? data =
            await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        return data == null
            ? null
            : Uint8List.view(data.buffer, data.offsetInBytes, data.lengthInBytes);
      });
      expect(bytes, isNotNull);
      return bytes!;
    }

    int alphaAt(Uint8List bytes, int width, int x, int y) =>
        bytes[(y * width + x) * 4 + 3];

    testWidgets('ظلّ الشكل الممتد لا يخرج عن صندوق العنصر + الانتشار',
        (WidgetTester tester) async {
      // شكل ممتد (200×50): يُوسَّع الظلّ بمعاملٍ نسبيّ فيتجاوز مسافة `spread`
      // الفعلية، لولا عزل الطبقة (`saveLayer`) لزاد خارج الحدّ مباشرة.
      const ShapeElement wide = ShapeElement(
        id: 'wide',
        kind: ShapeKind.rect,
        box: ElementBox(x: 0, y: 0, width: 200, height: 50),
        fillHex: '#FFFFFF',
        shadow: ShapeShadow(
          colorHex: '#000000',
          blurRadius: 0,
          spread: 10,
          offsetX: 0,
          offsetY: 0,
          opacity: 1,
        ),
      );
      final Uint8List bytes = await rasterizeIsolated(
        tester,
        canvasSize: const Size(300, 150),
        elementSize: const Size(200, 50),
        paint: (Canvas canvas, Size size) =>
            ShapePainter(shape: wide, scale: 1).paint(canvas, size),
      );

      // العنصر يمتد حتى 220 بكسل، ومسافة الانتشار 10 ⇒ آخر بكسل للظلّ 230.
      expect(
        alphaAt(bytes, 300, 225, 45),
        greaterThan(0),
        reason: 'الظلّ يظهر حتى مسافة انتشاره المحدّدة',
      );
      expect(
        alphaAt(bytes, 300, 235, 45),
        0,
        reason: 'ولا يُرسم شيء بعدها مهما وسّع الظلّ نفسه',
      );
    });

    testWidgets('حدود طبقة الصورة = صندوق العنصر + مسافة التوهج',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 400,
              height: 100,
              child: wrapRasterEffects(
                child: const SizedBox.expand(),
                scale: 1,
                outerGlow: const GlowEffect(
                  colorHex: '#FFD166',
                  radius: 10,
                  spread: 2,
                  opacity: 1,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final EffectBoundsClipper clipper = tester
          .widgetList<ClipRect>(find.byType(ClipRect))
          .map((ClipRect clip) => clip.clipper)
          .whereType<EffectBoundsClipper>()
          .single;
      // 2 (انتشار) + 3×10 (مدى التمويه 3σ) من كل جهة، ومستقلّة عن نِسَب
      // الصندوق حتى لا يتغيّر عزل التأثير بتغيّر مقاس العنصر.
      expect(
        clipper.getClip(const Size(400, 100)),
        const Rect.fromLTRB(-32, -32, 432, 132),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('توهّج النص يُقصّ عند صندوق الفقرة + مسافة أثره',
        (WidgetTester tester) async {
      const TextElement glowing = TextElement(
        id: 'tg',
        box: box,
        text: 'نص متوهّج',
        outerGlow: GlowEffect(
          colorHex: '#FFD166',
          radius: 10,
          spread: 2,
          opacity: 1,
        ),
      );
      await tester.pumpWidget(view(glowing));
      await tester.pump();

      final EffectBoundsClipper clipper = tester
          .widgetList<ClipRect>(find.byType(ClipRect))
          .map((ClipRect clip) => clip.clipper)
          .whereType<EffectBoundsClipper>()
          .single;
      expect(clipper.reach, 32);
      expect(tester.takeException(), isNull);

      // بلا تأثير خارجي لا تُضاف طبقة قصّ زائدة أصلاً.
      const TextElement plain = TextElement(
        id: 'tp',
        box: box,
        text: 'نص عادي',
      );
      await tester.pumpWidget(view(plain));
      await tester.pump();
      expect(
        tester
            .widgetList<ClipRect>(find.byType(ClipRect))
            .map((ClipRect clip) => clip.clipper)
            .whereType<EffectBoundsClipper>(),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
