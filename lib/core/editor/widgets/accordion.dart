import 'package:flutter/material.dart';

/// متحكّم **التوسّع الحصري** لأقسام الشريط الجانبي (سلوك الأكورديون).
///
/// الفكرة: قسم واحد مفتوح في كل لحظة. حين يفتح المستخدم قسماً يُغلق ما سواه
/// تلقائياً، فيبقى الشريط مضغوطاً ومركّزاً على الأداة النشطة.
///
/// يبدأ بلا اختيار صريح (`hasExplicitSelection == false`) فيتبع كل قسم قيمته
/// الافتراضية [ControlSection.initiallyExpanded] — فلا تتغيّر الواجهة قبل أن
/// يتفاعل المستخدم — ثم يصبح الاختيار حصرياً من أول نقرة.
class AccordionController extends ChangeNotifier {
  AccordionController({String? initialId}) : _expandedId = initialId;

  /// القيمة التي تعني «كل الأقسام مطويّة» (تمييزاً عن «بلا اختيار صريح»).
  static const String none = '';

  String? _expandedId;

  /// هل اختار المستخدم قسماً صراحةً؟ (بعدها يصبح السلوك حصرياً.)
  bool get hasExplicitSelection => _expandedId != null;

  /// معرّف القسم المفتوح، أو [none] حين لا شيء مفتوح، أو `null` قبل أول تفاعل.
  String? get expandedId => _expandedId;

  bool isExpanded(String id) => _expandedId == id;

  /// يفتح [id] ويُغلق ما سواه.
  void expand(String id) {
    if (_expandedId == id) return;
    _expandedId = id;
    notifyListeners();
  }

  /// يطوي [id] إن كان مفتوحاً (فيَبقى كل شيء مطويّاً).
  void collapse(String id) {
    if (_expandedId != id) return;
    _expandedId = none;
    notifyListeners();
  }

  /// يبدّل حالة قسم: إغلاقه إن كان مفتوحاً، وإلّا فتحه وحده.
  void toggle(String id) =>
      _expandedId == id ? collapse(id) : expand(id);

  /// يطوي كل الأقسام صراحةً.
  void collapseAll() {
    if (_expandedId == none) return;
    _expandedId = none;
    notifyListeners();
  }

  /// يعود إلى حالة «بلا اختيار صريح» فتتبع الأقسام قيمها الافتراضية.
  ///
  /// يُستدعى عند تغيّر السياق (نوع العنصر المحدَّد) فلا يبقى قسم مخفي عنصرُه
  /// هو الوحيد «المفتوح».
  void reset() {
    if (_expandedId == null) return;
    _expandedId = null;
    notifyListeners();
  }
}

/// نطاق يوزّع [AccordionController] على كل [ControlSection] في شجرته.
///
/// بوّابة `InheritedNotifier` فيُعاد بناء الأقسام تلقائياً عند كل تبديل، بلا
/// تمرير يدوي للمتحكّم عبر كل طبقة.
class AccordionScope extends InheritedNotifier<AccordionController> {
  const AccordionScope({
    super.key,
    required AccordionController controller,
    required super.child,
  }) : super(notifier: controller);

  static AccordionController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AccordionScope>()?.notifier;
}
