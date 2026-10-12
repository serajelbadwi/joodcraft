/// ترويسة الصفحة: **شعار القرية** (صورة `logo.png` بخط العربي المذهّب) بدل
/// اسم النصّ + شارة المبادرة + المركز.
///
/// الشعار يحلّ محلّ جملة «منشأة الأمراء ومحلة حسن» تماماً: لا يُعرض اسم
/// القرية نصّاً في الترويسة بعد اليوم، ويبقى الاسم معطىً للترويسة لسببين:
/// تسمية الصورة لقارئ الشاشة (`semanticLabel`)، ونصّ بديل يظهر تلقائياً إن
/// تعذّر تحميل الأصل (نفس مبدأ الإمضاء في `village_signature.dart`).
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../domain/village_validators.dart';
import '../village_theme.dart';

class VillageHeader extends StatelessWidget {
  const VillageHeader({super.key, required this.villageName});

  /// اسم القرية — لا يُعرض نصّاً، بل تسمية للشعار وبديل عند فشل تحميله.
  final String villageName;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        // الشعار عريض جداً (نسبة ‎2.69:1‎ — ‎2056×765‎ بسطرين من الخطّ الذهبي
        // ثلاثي الأبعاد) فيُقيَّد بعرضه لا بارتفاعه: ضيق ⇒ نِسَب من العرض،
        // وعريض ⇒ حدّ أقصى يمنع تمدّده فوق اللائق. لاتّساعه الزائد يصير
        // ارتفاعه عند الحدّ الأقصى ‎≈175px‎ (كانت صورة السطر الواحد ‎235px‎)
        // فتنكمش الحروف بصرياً — إن أردنا عين الحجم القديم يُرفع السقف لا
        // النسبة. خلفية الأصل شفّافة فتندمج مع لون الصفحة بدل أن تعلوه
        // كصندوق (سلوك الصورة ذات الخلفية السوداء الأولى).
        final double logoWidth =
            width < 520 ? width * 0.82 : (width < 820 ? 400 : 470);
        final double titleSize = width < 520
            ? 30
            : (width < 820 ? 38 : 48);
        return Column(
          key: const ValueKey<String>('village-header'),
          children: <Widget>[
            const Icon(
              Icons.location_city_rounded,
              color: VillageColors.tealSoft,
              size: 34,
            ),
            const SizedBox(height: VillageMetrics.space12),
            _VillageLogo(
              villageName: villageName,
              width: logoWidth,
              fallbackTitleSize: titleSize,
            ),
            const SizedBox(height: VillageMetrics.space16),
            _OrnamentDivider(width: width < 520 ? 180 : 320),
            const SizedBox(height: VillageMetrics.space16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VillageMetrics.space20,
                vertical: VillageMetrics.space8,
              ),
              decoration: BoxDecoration(
                color: VillageColors.teal.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: VillageColors.tealSoft.withValues(alpha: 0.7),
                ),
              ),
              child: const Text(
                VillageText.appSubtitle,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: VillageColors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: VillageMetrics.space12),
            Text(
              VillageText.villageRegion,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14.5,
                color: VillageColors.muted,
                height: 1.7,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// شعار القرية — صورة `logo.png` تحلّ محلّ عنوان النصّ.
///
/// تحميل الأصل يفشل فقط لو غابت الصورة عن الحزمة (خطأ توزيع)، فيظهر النصّ
/// الذهبي القديم بدل فراغ — فلا تنكسر الترويسة أبداً.
class _VillageLogo extends StatelessWidget {
  const _VillageLogo({
    required this.villageName,
    required this.width,
    required this.fallbackTitleSize,
  });

  /// الاسم المُستعمل تسميةً للصورة وللنصّ البديل.
  final String villageName;

  /// عرض الشعار المحتسب من عرض الصفحة.
  final double width;

  /// حجم خط النصّ البديل (نفس سلّم العنوان القديم).
  final double fallbackTitleSize;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.villageLogoImage,
      key: const ValueKey<String>('village-logo'),
      width: width,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      // بلا حركة عند تبدّل اسم القرية بعد قبول الكود.
      gaplessPlayback: true,
      // قارئ الشاشة يسمع اسم القرية رغم أنّ المعروض صورة.
      semanticLabel: villageName,
      excludeFromSemantics: false,
      errorBuilder: (
        BuildContext context,
        Object error,
        StackTrace? stackTrace,
      ) =>
          Text(
        villageName,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: Theme.of(context).textTheme.displayLarge?.fontFamily,
          fontSize: fallbackTitleSize,
          fontWeight: FontWeight.w700,
          color: VillageColors.gold,
          height: 1.35,
        ),
      ),
    );
  }
}

/// فاصل زخرفي: خط ذهبي متلاشٍ — معيّن — خط.
class _OrnamentDivider extends StatelessWidget {
  const _OrnamentDivider({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Row(
        children: const <Widget>[
          Expanded(child: _GradientRule(reverse: false)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: VillageMetrics.space8),
            child: Icon(
              Icons.diamond_rounded,
              size: 10,
              color: VillageColors.gold,
            ),
          ),
          Expanded(child: _GradientRule(reverse: true)),
        ],
      ),
    );
  }
}

class _GradientRule extends StatelessWidget {
  const _GradientRule({required this.reverse});

  final bool reverse;

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = <Color>[
      VillageColors.gold.withValues(alpha: 0.05),
      VillageColors.gold.withValues(alpha: 0.75),
    ];
    return Container(
      height: 1.2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: reverse ? colors.reversed.toList() : colors,
        ),
      ),
    );
  }
}
