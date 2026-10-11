/// فوتر الصفحة: «من أعمال JoodCraft» + المطوّر (اسمه/رقم هاتفه/إمضاؤه) + الحقوق.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../domain/village_validators.dart';
import '../village_theme.dart';
import 'village_signature.dart';

class VillageFooter extends StatelessWidget {
  const VillageFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('village-footer'),
      margin: const EdgeInsets.only(top: VillageMetrics.space32),
      padding: const EdgeInsets.only(top: VillageMetrics.space24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: VillageColors.gold.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth >= 760;
          final List<Widget> sections = <Widget>[
            const _BrandBlock(),
            const _DeveloperBlock(),
            const _RightsBlock(),
          ];
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: sections[0]),
                Expanded(child: sections[1]),
                Expanded(child: sections[2]),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              sections[0],
              const SizedBox(height: VillageMetrics.space24),
              sections[1],
              const SizedBox(height: VillageMetrics.space24),
              sections[2],
            ],
          );
        },
      ),
    );
  }
}

/// «من أعمال JoodCraft» مع أيقونة المنصة.
class _BrandBlock extends StatelessWidget {
  const _BrandBlock();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Image.asset(
          AppAssets.appIconImage,
          width: 32,
          height: 32,
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stackTrace,
          ) =>
              const Icon(
            Icons.workspace_premium_rounded,
            color: VillageColors.gold,
            size: 30,
          ),
        ),
        const SizedBox(width: VillageMetrics.space12),
        const Flexible(
          child: Text(
            VillageText.footerBrand,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: VillageColors.white,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

/// المطوّر: عنوان «المطور» ← الاسم ← رقم التليفون ← الإمضاء.
///
/// الترتيب من فوق إلى تحت، والمسافات بين العناصر قصيرة عمداً ليبقى البلوك
/// متماسكاً داخل الشبكة الثلاثية للفوتر.
class _DeveloperBlock extends StatelessWidget {
  const _DeveloperBlock();

  /// رقم تليفون المطوّر.
  static const String _developerPhone = '+20 01020005439';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        // ١) عنوان صغير.
        const Text(
          'المطور',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: VillageColors.muted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: VillageMetrics.space4),
        // ٢) الاسم — بحجم أصغر من العادي.
        const Text(
          VillageText.footerDeveloper,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppAssets.amiriFont,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: VillageColors.white,
            height: 1.45,
          ),
        ),
        const SizedBox(height: VillageMetrics.space4),
        // ٣) رقم التليفون — اتجاه صريح ليبقى الرقم كما هو في أي اتجاه.
        const Text(
          _developerPhone,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          style: TextStyle(
            fontSize: 13.5,
            letterSpacing: 0.4,
            color: VillageColors.inkSoft,
            height: 1.4,
          ),
        ),
        const SizedBox(height: VillageMetrics.space8),
        // ٤) الإمضاء — مساره افتراضي داخل [VillageSignature].
        const VillageSignature(height: 56, showName: false),
      ],
    );
  }
}

/// الحقوق.
class _RightsBlock extends StatelessWidget {
  const _RightsBlock();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.center,
      child: Text(
        VillageText.footerRights,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          color: VillageColors.muted,
          height: 1.7,
        ),
      ),
    );
  }
}
