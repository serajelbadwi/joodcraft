import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_block.dart';
import 'package:joodcraft/features/jood_writer/presentation/jood_writer_text_styles.dart';
import 'package:joodcraft/features/jood_writer/presentation/text_painter_measurer.dart';

/// اختبارات **P1 — توحيد خط القياس مع خط الرسم** في «جود كاتب».
///
/// ## العلة
///
/// المُقاس `TextPainter` **مُنعزل عن شجرة الودجات فلا يرث `DefaultTextStyle`**،
/// بينما العارضات (`Text` / `TextField`) ترث من الثيم عائلة الخط
/// `AppAssets.cairoFont` + `fontFamilyFallback`
/// (`app_theme.dart:159‑162`).
///
/// فحين كانت عائلة الخط في النمط `null` كان المُقاس يسقط على خط النظام
/// (Segoe UI على ويندوز، Roboto على أندرويد) والعارض يرسم بـ**Cairo**.
/// عروض المحارف تختلف جذّاً بينهما ⇒ تختلف نقطة التفاف السطر ⇒ يختلف عدد
/// الأسطر ⇒ **يتغيّر شكل الفقرة عند كل نقرة** (الوقوف يبدّل الطبقة المقيسة).
///
/// ## ما يثبته هذا الملف
///
/// 1. **العقد:** خطّ القياس = خطّ الرسم — مقارنة **فعلية** بين ما يحمله
///    النمط المشترك وما يرثه `Text` داخل ثيم التطبيق الحقيقي.
/// 2. **الحتمية:** فقرة عربية طويلة تُقاس ‎50‎ مرة فتخرج النتيجة نفسها.
/// 3. **ثبات التفاعل:** التركيز والإلغاء والكتابة لا يغيّران شكل القياس.
///
/// ## حيال خطوط الاختبار
///
/// بيئة `flutter test` تُعوّض كل الخطوط بخط الاختبار (صندوق ثابت لكل محرف)،
/// فلا يمكن تمييز Cairo من Segoe **بالبكسل** هنا. ولهذا يُختبر **العقد**
/// (ما يطلبه كلٌّ من القياس والرسم حرفياً) لا النتيجة المرسومة؛ والعقد وحده
/// هو ما يضمن على الجهاز أن يتحدا الخطان. (وهو بالضبط ما أخفاه P1: اختبارات
/// القياس القائمة تحقن مُقاساً ثابتاً فلا ترى خطوطاً إطلاقاً.)
void main() {
  /// فقرة عربية طويلة تكفي لعدة أسطر — موضع الحساسية الأعلى لاختلاف الخط.
  JoodWriterBlock longArabicParagraph() => const JoodWriterBlock(
        text: 'هذا نصٌّ عربيٌّ طويلٌ يُستخدم لاختبار ثبات القياس وتوحيد خط '
            'الرسم مع خط المُقاس، ويتضمّن كلماتٍ متفاوتة الأطوال حتى تُختبر '
            'نقطة التفاف السطر على حافّة الصفحة لا في وسطها، فما دام الخطّ '
            'واحداً بين القياس والعرض يبقى عدد الأسطر وارتفاعها محدَّداً '
            'حتماً ولا يتغيّر بتغيّر التركيز أو الكتابة أو ترتيب الكتل.',
      );

  TextPainterBlockMeasurer buildMeasurer({
    double contentWidth = 500,
    TextScaler textScaler = TextScaler.noScaling,
  }) =>
      TextPainterBlockMeasurer(
        contentWidth: contentWidth,
        scale: 1,
        textScaler: textScaler,
      );

  group('P1 — عقد الخط: خط القياس = خط الرسم', () {
    test('النمط المشترك يحمل Cairo حين لا يختار المستخدم خطّاً', () {
      const JoodWriterBlock block = JoodWriterBlock(text: 'فقرة');

      expect(
        JoodWriterTextStyles.of(block).fontFamily,
        AppAssets.cairoFont,
        reason: 'النمط يجب أن يحمل خط الرسم صريحاً لا `null` — وإلا قيس بخط '
            'النظام ورسم بـCairo فتتبدّل الأسطر عند كل نقرة (P1).',
      );
      expect(
        JoodWriterTextStyles.of(block).fontFamilyFallback,
        AppAssets.uiFontFallback,
        reason: 'قائمة الاحتياط تؤثّر في المحلّل البديل، فلا بدّ أن تدخل '
            'القياس كما تدخل الرسم.',
      );
    });

    test('خط الكتلة المختار يتصدّر ولا يُلغى بـCairo', () {
      // المستخدم اختار خطّاً ⇒ به يُرسم وبه يُقاس، فلا يفرض Cairo نفسه.
      const JoodWriterBlock block = JoodWriterBlock(
        text: 'نصّ بخطّ مختار',
        fontFamily: AppAssets.amiriFont,
      );

      expect(JoodWriterTextStyles.of(block).fontFamily, AppAssets.amiriFont);
      expect(
        JoodWriterTextStyles.of(block).fontFamilyFallback,
        AppAssets.uiFontFallback,
        reason: 'الاحتياط يبقى قائماً حتى مع خط مختار.',
      );
    });

    test('افتراضات المُقاس هي نفس ثوابت خط الرسم', () {
      // المُقاس يبدأ من نفس القيم التي يرثها العارض، فلا يستطيع المساران
      // أن يفترقا حتى لو نسي موقع استدعاء أن يمرّرهما.
      final TextPainterBlockMeasurer measurer = buildMeasurer();

      expect(measurer.fontFamily, AppAssets.cairoFont);
      expect(measurer.fontFamilyFallback, AppAssets.uiFontFallback);
    });

    testWidgets(
      'ما يرثه Text من الثيم = ما يحمله النمط المشترك (مقارنة فعلية)',
      (WidgetTester tester) async {
        const JoodWriterBlock block = JoodWriterBlock(text: 'اختبار');

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: Text('اختبار')),
          ),
        );

        // الـ`Text` هنا يرث خطّه من الثيم بالضبط كما ترثه ودجات المحرّر.
        final RichText rendered = tester.widget<RichText>(find.byType(RichText));
        final String? rendererFont = rendered.text.style?.fontFamily;
        final List<String>? rendererFallback =
            rendered.text.style?.fontFamilyFallback;

        expect(
          rendererFont,
          JoodWriterTextStyles.of(block).fontFamily,
          reason: 'خطّ الرسم الموروث من الثيم يختلف عن خطّ النمط المشترك — '
              'وهذا هو P1 بعينه.',
        );
        expect(
          rendererFallback,
          JoodWriterTextStyles.of(block).fontFamilyFallback,
          reason: 'قائمة الاحتياط الموروثة تختلف عن قائمة النمط المشترك.',
        );
      },
    );

    testWidgets('المُقاس بالافتراض يقيس كما يقيس المُقاس صريحاً بـCairo', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: SizedBox()),
        ),
      );

      final JoodWriterBlock block = longArabicParagraph();

      // الافتراض (خط الرسم الموروث) يجب أن يطابق التمرير الصريح حرفياً —
      // وإلا كان الافتراض خطّاً مختلفاً يُخفى عن المستدعي.
      final _Measure implicit = _measure(buildMeasurer(), block);
      final _Measure explicit = _measure(
        TextPainterBlockMeasurer(
          contentWidth: 500,
          scale: 1,
          textScaler: TextScaler.noScaling,
          fontFamily: AppAssets.cairoFont,
          fontFamilyFallback: AppAssets.uiFontFallback,
        ),
        block,
      );

      expect(explicit.lines, implicit.lines);
      expect(explicit.lineHeight, implicit.lineHeight);
    });
  });

  group('P1 — الحتمية: فقرة عربية طويلة', () {
    test('قياس ‎50‎ مرة يعطي النتيجة نفسها حرفياً', () {
      final TextPainterBlockMeasurer measurer = buildMeasurer();
      final JoodWriterBlock block = longArabicParagraph();

      final _Measure first = _measure(measurer, block);
      expect(first.lines, isNotEmpty);
      expect(first.lines.length, greaterThan(1));

      for (int i = 0; i < 50; i++) {
        final _Measure again = _measure(measurer, block);
        expect(
          again.lines,
          first.lines,
          reason: 'خطّ القياس تغيّر في التكرار ${i + 1} — الخط غير موحّد.',
        );
        expect(again.lineHeight, first.lineHeight);
      }
    });

    test('مقياسان مستقلان بنفس الخط يتفقان', () {
      // كما يحدث عند إعادة بناء اللوحة: خطٌّ موحّد ينتج قياساً واحداً.
      final JoodWriterBlock block = longArabicParagraph();

      expect(
        _measure(buildMeasurer(), block).lines,
        _measure(buildMeasurer(), block).lines,
      );
      expect(
        _measure(buildMeasurer(), block).lineHeight,
        _measure(buildMeasurer(), block).lineHeight,
      );
    });

    test('تكبير النظام يدخل القياس بالقيمة نفسها التي يدخل بها الرسم', () {
      // نفس المقياس على الطرفين — وإلا قيس نصّاً أصغر ممّا يُرسم.
      final JoodWriterBlock block = longArabicParagraph();

      final _Measure scaled = _measure(
        buildMeasurer(textScaler: const TextScaler.linear(1.5)),
        block,
      );
      final _Measure plain = _measure(buildMeasurer(), block);

      expect(scaled.lines.length, greaterThanOrEqualTo(plain.lines.length));
      expect(scaled.lineHeight, greaterThan(plain.lineHeight));
    });
  });

  group('P1 — ثبات التفاعل: التركيز والإلغاء والكتابة', () {
    test('دورة تركيز كاملة لا تغيّر شكل القياس', () {
      final TextPainterBlockMeasurer measurer = buildMeasurer();
      final JoodWriterBlock block = longArabicParagraph();

      final _Measure before = _measure(measurer, block);

      // التركيز هو ما يبدّل الطبقة المقيسة بين المحرّر والنصّ الثابت —
      // وبوحّدة الخطّ لا ينبغي أن يُحدث فرقاً في القياس إطلاقاً.
      final FocusNode node = FocusNode();
      node.requestFocus();
      node.unfocus();
      node.requestFocus();
      addTearDown(node.dispose);

      expect(_measure(measurer, block).lines, before.lines);
      expect(_measure(measurer, block).lineHeight, before.lineHeight);
    });

    test('كتابة ثم مسح تُرجع القياس الأصلي حرفياً', () {
      final TextPainterBlockMeasurer measurer = buildMeasurer();
      final JoodWriterBlock block = longArabicParagraph();

      final _Measure original = _measure(measurer, block);

      // كتابة تدريجية: كل ضغطة حرف تبني كتلة جديدة بنصّ أطول.
      JoodWriterBlock editing = block;
      for (final String addition in <String>[' و', ' نصّ', ' إضافي', ' جداً']) {
        editing = editing.copyWith(text: '${editing.text}$addition');
        expect(
          _measure(measurer, editing).lines.length,
          greaterThanOrEqualTo(original.lines.length),
        );
      }

      // المسح يعود إلى النصّ الأصلي ⇒ نفس القياس السابق بالضبط، لأنّ الخط
      // ثابت ولا يتأثّر بمحتوى النصّ ولا بحالة التحرير.
      expect(_measure(measurer, block).lines, original.lines);
      expect(_measure(measurer, block).lineHeight, original.lineHeight);
    });

    test('إعادة ترتيب الكتل لا تغيّر قياس أي كتلة', () {
      final TextPainterBlockMeasurer measurer = buildMeasurer();
      final List<JoodWriterBlock> blocks = <JoodWriterBlock>[
        longArabicParagraph(),
        const JoodWriterBlock(text: 'عنوان رئيسي', kind: JoodWriterBlockKind.heading1),
        const JoodWriterBlock(text: 'عنوان فرعي', kind: JoodWriterBlockKind.heading2),
        const JoodWriterBlock(text: 'نقطة أولى', kind: JoodWriterBlockKind.bullet),
        const JoodWriterBlock(text: 'بند مرقّم', kind: JoodWriterBlockKind.numbered),
      ];

      final Map<String, List<String>> byText = <String, List<String>>{
        for (final JoodWriterBlock b in blocks) b.text: measurer.linesOf(b),
      };

      for (final JoodWriterBlock b in blocks.reversed) {
        expect(
          measurer.linesOf(b),
          byText[b.text],
          reason: 'قياس الكتلة تغيّر بتغيّر ترتيبها: ${b.text}',
        );
      }
    });
  });
}

/// لقطة قياس — الخطان (الأسطر والارتفاع) كل ما يعتمد عليه التدفّق.
typedef _Measure = ({List<String> lines, double lineHeight});

_Measure _measure(TextPainterBlockMeasurer measurer, JoodWriterBlock block) =>
    (
      lines: measurer.linesOf(block),
      lineHeight: measurer.lineHeightOf(block),
    );
