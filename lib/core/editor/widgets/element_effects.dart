/// التأثيرات البصرية المشتركة بين أنواع العناصر (نمط Photoshop):
/// ظل (Drop Shadow)، توهّج خارجي (Outer Glow)، وضبط لوني حيّ.
///
/// * **الضبط اللوني** يُترجم إلى مصفوفة `ColorFilter` واحدة تُطبَّق على شجرة
///   العنصر، فتتغيّر الصورة فوراً مع كل حركة منزلق بلا إعادة ترميز ولا نسخ.
/// * **الظل والتوهّج** يُبنيان من **الصورة الظلّية** (silhouette) للعنصر نفسه:
///   يُلوَّن العنصر بلون الظل/التوهّج (`BlendMode.srcIn`) ثم يُوسَّع ثم يُموَّه
///   ويُوضع خلفه — فتتبع الحدود شكل الصورة الحقيقي لا صندوقها.
/// * **عزل الطبقة**: كل تأثير يُرسم داخل حدود = صندوق العنصر + مسافة أثره
///   فقط ([blurReach] + الانتشار + الإزاحة)، فلا يتسرّب التمويه إلى العناصر
///   المجاورة ولا إلى بقية مساحة العمل، ولا يُقتطع شيء من التوهّج نفسه.
///
/// الشكل المتجهي والنص لا يُمرّان من هنا: لكلٍّ منهما مسار أدقّ (هندسة المسار
/// في [ShapePainter]، و`TextStyle.shadows`/`MaskFilter.blur(BlurStyle.inner)`
/// في النص).
library;

import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../models/template_element.dart';
import '../../utils/hex_color.dart';

/// مرشّح الضبط اللوني للعنصر النقطي، أو `null` إن كان بلا ضبط فعّال.
ColorFilter? elementAdjustmentFilter(ElementAdjustments? adjustments) {
  if (adjustments == null || adjustments.isIdentity) return null;
  return ColorFilter.matrix(adjustments.toMatrix());
}

/// مدى أثر التمويه الغاوسي بانحراف معياري [sigma] بالبكسل.
///
/// تبلغ كثافة التمويه نحو 3σ (99.7% من مجموع الكثافة) قبل أن تهمل، فتُتخذ
/// هذه المسافة **حدّاً دقيقاً** لعزل طبقة التأثير: أقل منها يقطع الحافّة
/// فيظهر خطٌّ حاد، وأكثر منها يترك فراغاً يتسرّب منه التمويه إلى ما حول
/// العنصر. [sigma] يكون بالبكسلات لا بالوحدات التصميمية.
double blurReach(double sigma) => math.max(0, sigma) * 3;

/// يلفّ عنصراً نقطياً بظلّه وتوهّجه الخارجي (إن وُجدا) بلا تغيير هندسة الصندوق.
///
/// **عزل التأثير:** كل طبقة ظلّية تعيش داخل صندوق موسّق بمقدار أثرها تحديداً
/// ([_silhouetteBox])، ثم يُقصّ المجموع كله على صندوق العنصر موسّقاً بمسافة
/// أقصى تأثير ([EffectBoundsClipper]) — فلا يخرج أي تمويه خارج «حدود العنصر +
/// مسافة التوهج»، ولا تظهر حافّة مقطوعة لأن الحدّ يقع حيث يبلغ التأيه صفراً.
///
/// [scale] بكسلات الشاشة لكل وحدة تصميم.
Widget wrapRasterEffects({
  required Widget child,
  required double scale,
  ShapeShadow? shadow,
  GlowEffect? outerGlow,
}) {
  final ShapeShadow? visibleShadow =
      (shadow != null && shadow.isVisible) ? shadow : null;
  final GlowEffect? visibleGlow =
      (outerGlow != null && outerGlow.isVisible) ? outerGlow : null;
  if (visibleShadow == null && visibleGlow == null) return child;

  final double glowDilation =
      visibleGlow == null ? 0 : math.max(0, visibleGlow.spread) * scale;
  final double glowSigma =
      visibleGlow == null ? 0 : math.max(0, visibleGlow.radius) * scale;
  final double shadowDilation =
      visibleShadow == null ? 0 : math.max(0, visibleShadow.spread) * scale;
  final double shadowSigma = visibleShadow == null
      ? 0
      : math.max(0, visibleShadow.blurRadius) * scale;
  final Offset shadowOffset =
      visibleShadow == null
          ? Offset.zero
          : Offset(visibleShadow.offsetX * scale, visibleShadow.offsetY * scale);

  // مسافة أثر كل طبقة خارج صندوق العنصر: الانتشار + التمويه (+ الإزاحة).
  final double glowReach = glowDilation + blurReach(glowSigma);
  final double shadowReach = shadowDilation + blurReach(shadowSigma);
  // أقصى امتداد لأي تأثير خارج الصندوق — به يُقصّ المجموع كله.
  final double reach =
      math.max(glowReach, shadowReach + shadowOffset.distance);

  return ClipRect(
    clipper: EffectBoundsClipper(reach: reach),
    child: Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: <Widget>[
        if (visibleGlow != null)
          _silhouetteBox(
            reach: glowReach,
            offset: Offset.zero,
            child: _silhouetteLayer(
              child: child,
              color: colorFromHex(visibleGlow.colorHex),
              opacity: visibleGlow.opacity,
              dilation: glowDilation,
              sigma: glowSigma,
            ),
          ),
        if (visibleShadow != null)
          _silhouetteBox(
            reach: shadowReach,
            offset: shadowOffset,
            child: _silhouetteLayer(
              child: child,
              color: colorFromHex(visibleShadow.colorHex),
              opacity: visibleShadow.opacity,
              dilation: shadowDilation,
              sigma: shadowSigma,
            ),
          ),
        child,
      ],
    ),
  );
}

/// صندوق الطبقة الظلّية: موسّق بمقدار [reach] من كل جهة (غرفة كافية
/// للتوسيع والتمويه داخل حدود الطبقة)، ومُزاح مع [offset] إن كان للظل إزاحة —
/// فتنتهي الحافة النهائية عند مسافة أثر التأثير بالضبط.
///
/// الحشو الداخلي يُعيد محتوى العنصر إلى صندوقه الأصلي، فلا تتغيّر هندسته.
Widget _silhouetteBox({
  required double reach,
  required Offset offset,
  required Widget child,
}) => Positioned(
      left: offset.dx - reach,
      top: offset.dy - reach,
      right: -offset.dx - reach,
      bottom: -offset.dy - reach,
      child: Padding(padding: EdgeInsets.all(reach), child: child),
    );

/// طبقة واحدة من الصورة الظلّية: توسيع (dilate) ← تلوين ← تمويه.
///
/// لا حاجة لتكبير المحتوى (الحلقة القديمة `Transform.scale`) بلقاء غرفة
/// الصندوق في [_silhouetteBox]: الحدود تُحسب من الأثر نفسه فلا يكبر الظلّ
/// فوق مسافته المحددة ولا يُقصّ عند حافة العنصر.
Widget _silhouetteLayer({
  required Widget child,
  required Color color,
  required double opacity,
  required double dilation,
  required double sigma,
}) {
  Widget layer = child;
  if (dilation > 0) {
    layer = ImageFiltered(
      imageFilter: ImageFilter.dilate(radiusX: dilation, radiusY: dilation),
      child: layer,
    );
  }
  layer = ColorFiltered(
    colorFilter: ColorFilter.mode(
      color.withValues(alpha: opacity.clamp(0, 1)),
      BlendMode.srcIn,
    ),
    child: layer,
  );
  if (sigma > 0) {
    layer = ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: layer,
    );
  }
  return layer;
}

/// قاصّ حدود التأثير: يوسّع صندوق العنصر إلى مسافة أقصى تأثير ([reach]).
///
/// يُوضع فوق طبقات [wrapRasterEffects] (وفوق تأثيرات النص) فيبقى ما ترسمه
/// الصورة الظلّية داخل «حدود العنصر + مسافة التوهج» بالضبط: لا تسرّب إلى
/// مساحة العمل أو إلى عنصر مجاور، ولا قصٌّ يظهر كخطٍّ حاد على التوهّج.
class EffectBoundsClipper extends CustomClipper<Rect> {
  const EffectBoundsClipper({required this.reach});

  /// أقصى بُعد للتأثير خارج صندوق العنصر (بكسلات الشاشة).
  final double reach;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(-reach, -reach, size.width + reach, size.height + reach);

  @override
  bool shouldReclip(EffectBoundsClipper oldClipper) =>
      oldClipper.reach != reach;
}

/// لون التوهّج الداخلي للنص: طبقة نص فوق الأصل بحدّ مطموس **إلى الداخل**
/// (`BlurStyle.inner`) فلا يخرج التوهّج عن حروف النص إطلاقاً.
///
/// يعيد `null` إن لم يكن للتوهّج أثر، فلا تُبنى طبقة زائدة أصلاً.
Paint? editorTextInnerGlowPaint(TextElement text, double scale) {
  final GlowEffect? glow = text.innerGlow;
  if (glow == null || !glow.isVisible) return null;
  final double radius = glow.radius * scale;
  return Paint()
    ..color = colorFromHex(glow.colorHex)
        .withValues(alpha: glow.opacity.clamp(0, 1))
    ..maskFilter = MaskFilter.blur(BlurStyle.inner, math.max(radius, 0.1));
}
