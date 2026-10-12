/// تذييل (فاتور) شاشات «فرح» — ثلاث قطع:
///
/// * **يمين**: شعار JoodCraft + «من أعمال» — التطبيق من إنتاج منصّة القرية.
/// * **وسط**: بطاقة المطوّر — «المطور» + الاسم + التليفون + الإمضاء.
/// * **يسار**: حقوق النشر.
///
/// الترتيب بـ`Wrap` لا `Row`: على عريض يجلس الثلاثة في صفّ واحد (RTL يمين ←
/// يسار)، وعلى ضيّق ينزل الزائد سطراً تحته — **ولا نسكاب بأي عرض**، حتى بخطّ
/// الاختبارات الأوسع من خط Cairo الحقيقي بمرّتين.
///
/// الشريط لا يحمل خلفية ملوّنة بل **نفس لون الصفحة** `#3D3D3D` عمداً: هالات
/// `_FarahGlow` خلف المحتوى تلوّن الشريط لو كان شفّافاً، وثبات اللون هو ما
/// يجعل حيلة إزالة أسود الإمضاء (‎`BlendMode.screen`‎) تطابق الشريط حرفياً.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../domain/farah_text.dart';
import '../../../village/presentation/village_theme.dart';

class FarahFooter extends StatelessWidget {
  const FarahFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('farah-footer'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: VillageMetrics.space16,
        vertical: VillageMetrics.space12,
      ),
      decoration: BoxDecoration(
        color: VillageColors.background,
        border: Border(
          top: BorderSide(
            color: VillageColors.border.withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
      ),
      // `Wrap` لا `Row`: الأول في RTL يمين، والزائد عند الضيق ينزل سطراً
      // جديداً بدل أن ينسكب. كلّ نصّ بداخله مرن (`Flexible`/الالتفاف التلقائي)
      // فلا يزيد ارتفاع الصفّ على ما تتّسع له القطعة نفسها.
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: VillageMetrics.space24,
        runSpacing: VillageMetrics.space8,
        children: <Widget>[
          const _FooterBrand(),
          const _FooterDeveloper(),
          const _FooterCopyright(),
        ],
      ),
    );
  }
}

/// يمين الشريط: شعار JoodCraft + «من أعمال».
class _FooterBrand extends StatelessWidget {
  const _FooterBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Image.asset(
          AppAssets.villageLogoImage,
          key: const ValueKey<String>('farah-footer-brand-logo'),
          height: 26,
          fit: BoxFit.contain,
          // غياب الشعار لا يكسر الفوتر — يبقى نصّ «من أعمال» وحده.
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stackTrace,
          ) =>
              const SizedBox.shrink(),
        ),
        const SizedBox(width: VillageMetrics.space8),
        Flexible(
          // مرن: على صفّ ضيّق يلتفّ نصّ «من أعمال» ولا يدفع الشعار للخارج.
          child: const Text(
            FarahText.footerFrom,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: VillageColors.muted,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

/// وسط الشريط: بطاقة المطوّر.
class _FooterDeveloper extends StatelessWidget {
  const _FooterDeveloper();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Flexible(
          // مرن: على صفّ ضيّق يأخذ العمود ما يتّسع له من العرض فتلتفّ
          // الأسماء والتليفون سطرياً — والإمضاء يبقى بحجمه الثابت بجواره.
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Text(
                FarahText.footerDeveloperLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: VillageColors.muted,
                  height: 1.4,
                ),
              ),
              const Text(
                FarahText.footerDeveloperName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: VillageColors.white,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                FarahText.footerPhone,
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 12.5,
                  color: VillageColors.goldSoft,
                  height: 1.4,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: VillageMetrics.space12),
        // الإمضاء: حبر أبيض على أسود (JPEG بلا قناة شفافية). حيلة `screen`
        // مع لون الشريط: الأسود يصير لون الشريط بالضبط (‎#3D3D3D‎ — يذوب
        // في الخلفية) والأبيض يبقى أبيضاً: إمضاء بلا ورقة ولا صندوق أسود.
        Image.asset(
          AppAssets.developerSignatureImage,
          key: const ValueKey<String>('farah-footer-signature'),
          height: 34,
          fit: BoxFit.contain,
          color: VillageColors.background,
          colorBlendMode: BlendMode.screen,
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stackTrace,
          ) =>
              const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// يسار الشريط: حقوق النشر.
class _FooterCopyright extends StatelessWidget {
  const _FooterCopyright();

  @override
  Widget build(BuildContext context) {
    return const Text(
      FarahText.footerCopyright,
      // الالتفاف التلقائي: على ضيّق ينزل السطر الثاني بتوسيط بدل النسكاب.
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 11.5,
        color: VillageColors.muted,
        height: 1.5,
      ),
    );
  }
}
