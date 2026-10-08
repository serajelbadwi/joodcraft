// منطق اختبار الإصابة لعناصر المحرّر: أي عنصرٍ تحت مؤشر النقر؟
//
// المشكلة التي يحلّها: كل طبقة عنصر تملك كاشف نقر يغطّي صندوقها كاملة
// بسلوك `opaque`، فيفوز الأعلى طبقة مهما كان حجمه — فعناصر صغيرة موضوعة داخل
// عنصر كبير (إطار/مستطيل/حاوية) كانت تُخطَف من نقرتها الأولى.
//
// القواعد (بهذا الترتيب):
// 1) يُجمع كل عنصر تحت النقطة: صندوقه يحتويها بعد عكس دورانه حول مركزه.
// 2) الحاويات المفرغة (شكل حدودي بلا تعبئة، أو صورة إطار) لا تُعَد إلا إذا
//    وقعت النقطة على حدّها؛ فراغها الداخلي يمرّ إلى ما تحتها فلا تسرق النقرة.
//    (الأشكال الشفافة تماماً — بلا تعبئة ولا حدّ — لا تُعَد أبداً.)
// 3) يُختار الأصغر مساحة (أضيق/الأدقّ)، وعند تساوي المساحات يُقدّم الأعلى في
//    الترتيب (z-index: آخر عنصر في القائمة هو الأعلى طبقة).
//
// الدوال نقيّة بلا أي اعتماد على الواجهة، فتُختبر مباشرة في اختبارات الوحدة.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../models/template_element.dart';
import '../utils/hex_color.dart';

/// يُرجع العنصر المستهدف تحت [point] (بإحداثيات التصميم)، أو `null` إن لم يكن
/// تحته شيء.
///
/// [elements] بترتيب المستند: الأقدم أولاً والأعلى طبقة أخيراً (z = الفهرس).
/// [resolveBox] يحلّ صندوق العنصر (عرض/ارتفاع تلقائي للنص مثل المحرّر نفسه).
/// [frameIds] معرّفات صور الإطارات (أصول من نوع «إطار») — تُعامَل حاويات مفرغة.
TemplateElement? pickElementAt(
  List<TemplateElement> elements, {
  required Offset point,
  ElementBox Function(TemplateElement element) resolveBox =
      _boxAsIs,
  Set<String> frameIds = const <String>{},
}) {
  TemplateElement? best;
  double bestArea = double.infinity;

  for (int z = 0; z < elements.length; z++) {
    final TemplateElement element = elements[z];
    if (isTransparentElement(element)) continue;

    final ElementBox box = resolveBox(element);
    if (box.width <= 0 || box.height <= 0) continue;

    final Rect rect = Rect.fromLTWH(box.x, box.y, box.width, box.height);
    final Offset local = _toLocal(rect, point, element.rotation);
    if (!rect.contains(local)) continue;

    // الحاوية المفرغة تُلتقط على حدّها فقط.
    if (isHollowContainerElement(element, isFrame: frameIds.contains(element.id)) &&
        !_onHollowBand(rect, local, hollowBandFor(box))) {
      continue;
    }

    // المساحة الأصغر تفوز؛ وعند تساويها يفوز الأحدث في المسار (z الأعلى).
    if (box.width * box.height <= bestArea) {
      best = element;
      bestArea = box.width * box.height;
    }
  }
  return best;
}

/// هل الحاوية مفرغة (حدود فقط) تُستقبل النقرة على حدّها لا في فراغها؟
///
/// * الشكل بلا تعبئة ظاهرة (ملء شفاف/غائب) وحدّه ظاهر → مفرغ.
/// * صورة إطار ([isFrame]) → مفرغة لأن قلبها شفاف في الصورة نفسها.
/// * غير ذلك (نص/صورة/ختم/توقيع/ملء ظاهر) → صندوق مصمت يستقبل النقرة أينما وقع.
bool isHollowContainerElement(
  TemplateElement element, {
  required bool isFrame,
}) {
  if (element is ImageElement) return isFrame;
  if (element is! ShapeElement) return false;
  if (isTransparentElement(element)) return false;
  return !_hasVisibleFill(element);
}

/// هل العنصر غير مرئي تماماً (بلا تعبئة ولا حدّ) فلا يعترض النقر إطلاقاً؟
bool isTransparentElement(TemplateElement element) {
  if (element is! ShapeElement) return false;
  final bool hasFill = _hasVisibleFill(element);
  final bool hasStroke = (element.strokeHex ?? '').trim().isNotEmpty ||
      element.strokeWidth > 0;
  return !hasFill && !hasStroke;
}

/// عرض مسكة الحاوية المفرغة بوحدات التصميم: حسب أضيق بُعد في صندوقها،
/// محصوراً بين 8 و48 وحدة كي تبقى قابلة للنقر على الشاشة (نقرة بحدود شعرة
/// المستحيلة، ونقرة على نصف الحاوية ليست على الحدّ).
double hollowBandFor(ElementBox box) {
  final double shortSide = math.min(box.width, box.height);
  return (shortSide * 0.12).clamp(8.0, 48.0);
}

ElementBox _boxAsIs(TemplateElement element) => element.box;

/// عكس دوران العنصر حول مركز صندوقه: النقطة تُؤخَذ بعوامض الصندوق نفسه.
Offset _toLocal(Rect rect, Offset point, double rotationDegrees) {
  if (rotationDegrees == 0) return point;
  final double radians = -rotationDegrees * math.pi / 180;
  final double cos = math.cos(radians);
  final double sin = math.sin(radians);
  final Offset delta = point - rect.center;
  return rect.center +
      Offset(delta.dx * cos - delta.dy * sin, delta.dx * sin + delta.dy * cos);
}

/// هل تقع النقطة (بعوامض الصندوق) على مسكة الحاوية المفرغة؟
bool _onHollowBand(Rect rect, Offset local, double band) {
  final double inset = math.min(
    math.min(local.dx - rect.left, rect.right - local.dx),
    math.min(local.dy - rect.top, rect.bottom - local.dy),
  );
  return inset <= band;
}

/// هل يحمل الشكل تعبئة ظاهرة (لون صلب أو تدرّج بميل غير معدوم)؟
bool _hasVisibleFill(ShapeElement element) {
  if (element.fillOpacity <= 0) return false;
  // التدرّج تعبئة ظاهرة حتى بلا لون صلب.
  if (element.gradient != null) return true;
  final String hex = (element.fillHex ?? '').trim();
  if (hex.isEmpty || hex.toLowerCase() == 'transparent') return false;
  return colorFromHex(hex).a > 0;
}
