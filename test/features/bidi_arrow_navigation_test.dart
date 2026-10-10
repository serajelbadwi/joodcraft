import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:joodcraft/core/widgets/bidi_arrow_navigation.dart';

/// تنقّل الأسهم داخل حقول النص العربية.
///
/// flutter يحرّك المؤشر **بترتيب منطقي** مهما كان اتجاه النص (انظر
/// `DirectionalTextEditingIntent.forward`: «uses the logical order … is not
/// affected by the writing direction»)، فيمشي السهم عكس الحركة البصرية داخل
/// العربية. الاختبارات هنا تؤكّد:
/// 1. أن هذا هو سلوك flutter الافتراضي (الخطأ المُصلَح) — لو تغيّر في إصدار
///    قادم يسقط الاختبار فينبّه إلى أن قلب الأسهم لم يعد ضرورياً/صار مضاعفاً.
/// 2. أن [BidiArrowNavigation] يجعل `←` تتقدّم يساراً و`→` تعود يميناً في
///    المقطع العربي.
/// 3. أن المقطع اللاتيني/المحايد يبقى على افتراضي flutter بلا قلب.
/// 4. أن المفتاح يُمرَّر سليماً عندما لا يكون المستخدم داخل حقل نصي.
void main() {
  const String arabic = 'مرحبا بالعالم';

  /// يبني التطبيق كما يبنيه `JoodCraftApp`: `Directionality` ثم — إن رُكب —
  /// [BidiArrowNavigation] فوق الراوتر، ثم حقل النص في الصفحة.
  Future<void> pumpField(
    WidgetTester tester, {
    required TextEditingController controller,
    required bool install,
    TextDirection ambient = TextDirection.rtl,
    TextDirection? fieldDirection = TextDirection.rtl,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? routed) {
          final Widget tree = routed ?? const SizedBox.shrink();
          return Directionality(
            textDirection: ambient,
            child: install ? BidiArrowNavigation(child: tree) : tree,
          );
        },
        home: Scaffold(
          body: TextField(
            key: const ValueKey<String>('bidi-field'),
            controller: controller,
            autofocus: true,
            textDirection: fieldDirection,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus?.hasFocus,
      isTrue,
      reason: 'يجب أن يكون حقل النص حاملاً للتركيز قبل إرسال المفاتيح',
    );
  }

  testWidgets(
    'افتراضي flutter: السهم الأيسر يحرّك المؤشر بترتيب منطقي في العربية',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: arabic,
      );
      addTearDown(controller.dispose);
      await pumpField(tester, controller: controller, install: false);

      controller.selection = const TextSelection.collapsed(offset: 3);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      // المنطق يعني «المحرف السابق» = offset أصغر — وهو داخل العربية موضع
      // بصري على اليمين: هذا بالضبط الخطأ المُبلَّغ عنه.
      expect(controller.selection.extentOffset, 2);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(controller.selection.extentOffset, 3);
    },
  );

  testWidgets(
    'BidiArrowNavigation: ← تتقدّم يساراً و→ تعود يميناً في النص العربي',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: arabic,
      );
      addTearDown(controller.dispose);
      await pumpField(tester, controller: controller, install: true);

      controller.selection = const TextSelection.collapsed(offset: 4);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(
        controller.selection.extentOffset,
        5,
        reason: '← داخل العربية: للأمام منطقياً = بصرياً يساراً',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(
        controller.selection.extentOffset,
        4,
        reason: '→ داخل العربية: للخلف منطقياً = بصرياً يميناً',
      );
    },
  );

  testWidgets(
    'BidiArrowNavigation: تحديد Shift+سهم يتبع الاتجاه البصري أيضاً',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: arabic,
      );
      addTearDown(controller.dispose);
      await pumpField(tester, controller: controller, install: true);

      controller.selection = const TextSelection.collapsed(offset: 2);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      expect(controller.selection.baseOffset, 2);
      expect(
        controller.selection.extentOffset,
        3,
        reason: 'Shift+← يوسّع التحديد نحو اليسار (المنطقي للأمام)',
      );
    },
  );

  testWidgets(
    'BidiArrowNavigation: المقطع اللاتيني داخل حقل RTL يبقى افتراضي flutter',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'Hello world',
      );
      addTearDown(controller.dispose);
      await pumpField(tester, controller: controller, install: true);

      controller.selection = const TextSelection.collapsed(offset: 5);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(
        controller.selection.extentOffset,
        4,
        reason: 'حرف لاتيني قوي: بلا قلب — السهم الأيسر يعود منطقياً/بصرياً',
      );
    },
  );

  testWidgets(
    'BidiArrowNavigation: القرار حسب المقطع حول المؤشر في النص المختلط',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'Hello مرحبا',
      );
      addTearDown(controller.dispose);
      await pumpField(tester, controller: controller, install: true);

      // المؤشر داخل الكلمة اللاتينية: بلا قلب.
      controller.selection = const TextSelection.collapsed(offset: 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(controller.selection.extentOffset, 1);

      // المؤشر داخل المقطع العربي: قلب كامل.
      controller.selection = const TextSelection.collapsed(offset: 8);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(controller.selection.extentOffset, 9);
    },
  );

  testWidgets('BidiArrowNavigation: لا تبتلع الأسهم خارج حقول النص', (
    WidgetTester tester,
  ) async {
    final List<LogicalKeyboardKey> seen = <LogicalKeyboardKey>[];
    await tester.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? routed) => Directionality(
          textDirection: TextDirection.rtl,
          // عقدة التسجيل أعلى [BidiArrowNavigation] فيسلسل الحدث إليها بعد
          // أن يمرّ عليها هو دون استهلاك — كما تفعل اختصارات اللوحة.
          child: Focus(
            onKeyEvent: (FocusNode node, KeyEvent event) {
              if (event is KeyDownEvent) seen.add(event.logicalKey);
              return KeyEventResult.ignored;
            },
            child: BidiArrowNavigation(
              child: routed ?? const SizedBox.shrink(),
            ),
          ),
        ),
        home: const Scaffold(body: Focus(autofocus: true, child: SizedBox())),
      ),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();

    expect(
      seen,
      contains(LogicalKeyboardKey.arrowLeft),
      reason: 'خارج حقل نصي يجب أن يصل السهم إلى اختصارات اللوحة كما كان',
    );
  });
}
