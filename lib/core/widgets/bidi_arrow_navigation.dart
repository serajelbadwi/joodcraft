import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/text_flow.dart';

/// اتجاه المقطع القوي الأول الذي يقع حول مؤشر الكتابة.
enum _StrongDirection { rtl, ltr }

/// تنقّل مفاتيح الأسهم البصرية داخل حقول النص ثنائية الاتجاه (BIDI).
///
/// حركة المؤشر في flutter **منطقية بحتة**: `arrowLeft` تعني «المحرف السابق في
/// السلسلة» مهما كان اتجاه النص — وفي نص `DirectionalTextEditingIntent`
/// صراحةً: «uses the logical order … and is not affected by the writing
/// direction of the text». داخل النص العربي (يُكتب من اليمين لليسار) يصبح
/// «المحرف السابق» موضعاً بصرياً على **اليمين**، فتتحرك المؤشر عكس السهم:
/// `←` يزيحها يميناً و`→` يزيحها يساراً — وهذا هو خطأ التنقّل المُبلَّغ عنه.
///
/// [BidiArrowNavigation] يُعيد توجيه الأسهم لتعمل **بصرياً** داخل المقاطع
/// العربية: `←` تتقدّم يساراً (للأمام منطقياً في العربية) و`→` تعود يميناً
/// (للخلف منطقياً)، تماماً كتطبيقات تحرير النص الأصلية.
///
/// قواعد التطبيق:
/// * القرار يعتمد على المقطع **حول المؤشر** لا على لغة الواجهة: حقل عربي
///   بمحتوى لاتيني صرف لا ينقلب، وحقل لاتيني يحوي عربياً ينقلب عند موضع
///   المؤشر العربي — والمحايد (أرقام ومسافات ورموز) لا يُغيّر القرار.
/// * يُثبَّت مرّة واحدة فوق شجرة التطبيق (الراوتر والحوارات والقوائم) فلا
///   يُضاف لكل حقل، وحين لا يكون المستخدم داخل حقل نصي يُمرَّر المفتاح
///   سليماً إلى اختصارات اللوحة (تحريك العناصر…) كما كانت.
/// * لا يمسّ `Backspace`/`Delete`: الحذف يتبع الترتيب المنطقي وهو السلوك
///   الأصلي الصحيح في النص العربي.
class BidiArrowNavigation extends StatelessWidget {
  const BidiArrowNavigation({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Focus(
      debugLabel: 'BidiArrowNavigation',
      // عقدة اختصار لا تُستهدَف بالتركيز — بالضبط كما تفعل `Shortcuts`.
      canRequestFocus: false,
      onKeyEvent: _handleKeyEvent,
      child: child,
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final Intent? intent = _visualIntent(
      event.logicalKey,
      HardwareKeyboard.instance,
    );
    if (intent == null) return KeyEventResult.ignored;

    // الهدف: حقل النص الذي يحمل التركيز فعلاً (إن وُجد).
    final BuildContext? target = FocusManager.instance.primaryFocus?.context;
    if (target == null) return KeyEventResult.ignored;
    final EditableText? editable = target
        .findAncestorWidgetOfExactType<EditableText>();
    if (editable == null) return KeyEventResult.ignored;
    if (!_caretRunsRightToLeft(editable, target)) {
      return KeyEventResult.ignored;
    }

    // نفس مسار flutter الداخلي: إيجاد الفعل عند موضع التركيز ثم تنفيذه إن
    // كان ممكناً، وإلا يُمرَّر المفتاح إلى الخرائط الافتراضية بلا تغيير.
    final Action<Intent>? action = Actions.maybeFind<Intent>(
      target,
      intent: intent,
    );
    if (action == null) return KeyEventResult.ignored;
    final (bool enabled, Object? invokeResult) = Actions.of(
      target,
    ).invokeActionIfEnabled(action, intent, target);
    if (!enabled) return KeyEventResult.ignored;
    // نفس نتيجة `ShortcutManager.handleKeypress` حرفياً.
    return action.toKeyEventResult(intent, invokeResult);
  }

  /// نية حركة مؤشر **بصرية** لسهم يسار/يمين داخل مقطع RTL.
  ///
  /// منطق flutter: `forward:true` = المحرف التالي في السلسلة (نحو نهاية
  /// النص). داخل RTL هذا متجه بصرياً نحو **اليسار**، فيصبح `←` = forward
  /// و`→` = backward، مع قلب باقي المفاتيح المعدِّلة (Shift للتحديد،
  /// Ctrl/Cmd للكلمة، Alt لحد السطر) بالطريقة نفسها.
  static Intent? _visualIntent(LogicalKeyboardKey key, HardwareKeyboard kb) {
    final bool left = key == LogicalKeyboardKey.arrowLeft;
    final bool right = key == LogicalKeyboardKey.arrowRight;
    if (!left && !right) return null;

    final bool shift = kb.isShiftPressed;
    final bool alt = kb.isAltPressed;
    final bool control = kb.isControlPressed || kb.isMetaPressed;
    // تركيبة خارج خرائط flutter المعتادة (Ctrl+Alt+سهم) — تمرّ كما هي.
    if (alt && control) return null;

    // داخل مقطع RTL: البصري عكس المنطقي — `←` يتقدّم منطقياً نحو اليسار.
    final bool forward = left;
    if (alt) {
      return ExtendSelectionToLineBreakIntent(
        forward: forward,
        collapseSelection: !shift,
      );
    }
    if (control) {
      return ExtendSelectionToNextWordBoundaryIntent(
        forward: forward,
        collapseSelection: !shift,
      );
    }
    return ExtendSelectionByCharacterIntent(
      forward: forward,
      collapseSelection: !shift,
    );
  }

  /// هل يقع المقطع العربي حول المؤشر داخل [editable]؟
  ///
  /// يبحث عن أول محرف قوي الاتجاه (عربي أو لاتيني) بدءاً من موضع المؤشر
  /// نحو الخارج: العربية تطلب قلب الأسهم، واللاتينية تطلب افتراضي flutter.
  /// الفراغ/الأرقام/الرموز محايدة فلا تُنهي البحث، وعند انتهاء النافذة يُحسم
  /// القرار باتجاه النص كاملاً ثم باتجاه الحقل المُعلن.
  static bool _caretRunsRightToLeft(
    EditableText editable,
    BuildContext target,
  ) {
    final String text = editable.controller.text;
    if (text.isEmpty) {
      final TextDirection declared =
          editable.textDirection ??
          Directionality.maybeOf(target) ??
          TextDirection.ltr;
      return declared == TextDirection.rtl;
    }

    final TextSelection selection = editable.controller.selection;
    final int caret = selection.isValid ? selection.extentOffset : text.length;
    const int window = 64;
    final int floor = math.max(0, caret - window);
    final int ceil = math.min(text.length, caret + window);

    for (int i = 0; i < window; i++) {
      final int before = caret - 1 - i;
      if (before >= floor) {
        final _StrongDirection? direction = _strongDirectionAt(text, before);
        if (direction != null) return direction == _StrongDirection.rtl;
      }
      final int after = caret + i;
      if (after < ceil) {
        final _StrongDirection? direction = _strongDirectionAt(text, after);
        if (direction != null) return direction == _StrongDirection.rtl;
      }
      if (before < floor && after >= ceil) break;
    }
    return TextFlow.looksRightToLeft(text);
  }

  /// اتجاه محرف واحد: عربي/عربي-مجدول ⇒ rtl، لاتيني/يوناني/سيريلي ⇒ ltr،
  /// وما عداهما (مسافات وأرقام وعلامات) ⇒ محايد `null`.
  static final RegExp _ltrStrong = RegExp(
    r'[A-Za-z\u00C0-\u024F\u0370-\u058F]',
  );

  static _StrongDirection? _strongDirectionAt(String text, int index) {
    if (index < 0 || index >= text.length) return null;
    final String char = text[index];
    if (char.trim().isEmpty) return null;
    if (TextFlow.looksRightToLeft(char)) return _StrongDirection.rtl;
    if (_ltrStrong.hasMatch(char)) return _StrongDirection.ltr;
    return null;
  }
}
