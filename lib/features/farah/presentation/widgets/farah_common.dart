/// عناصر صغيرة مشتركة بين شاشات «فرح»: عنوان ذهبي بخط Amiri، وشريط «رجوع»،
/// وشريط خطأ أحمر — لتبقى الشاشات متطابقة بلا تكرار كود زخرفي.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../domain/farah_text.dart';
import '../../../village/presentation/village_theme.dart';

/// عنوان الشاشة — بخط Amiri الذهبي (نفس ترويسة صفحة القرية).
class FarahTitle extends StatelessWidget {
  const FarahTitle({super.key, required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, color: VillageColors.gold, size: 26),
          const SizedBox(width: VillageMetrics.space12),
        ],
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: AppAssets.amiriFont,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: VillageColors.gold,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

/// الشريط العلوي الموحّد لكل شاشات «فرح» (ما عدا الدخول): سهم رجوع حقيقي
/// جهة البداية (يمين في RTL) + عنوان الشاشة بخط Amiri الذهبي، بنفس خلفية
/// القرية `#3D3D3D` بلا ظل — فتبقى الشاشات متطابقة ولا يعلق أحدٌ في أيٍّ منها.
class FarahAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FarahAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.showBack = true,
    this.actions = const <Widget>[],
  });

  /// عنوان الشاشة (عربي دائماً).
  final String title;

  /// بديل مرئّي للعنوان (شعار التطبيق…) — يحلّ محلّ النصّ إن وُجد، ويبقى
  /// [title] نصّاً لقارئ الشاشة فلا تفقد الشاشة اسمها بإبدال الرمز بالصورة.
  final Widget? titleWidget;

  /// هل يظهر سهم الرجوع؟ يُطفأ على الشاشة الرئيسية لأنها جذر التطبيق.
  final bool showBack;

  /// إجراءات جهة النهاية (تحديث… / خروج).
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: VillageColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: showBack
          ? IconButton(
              key: const ValueKey<String>('farah-back'),
              tooltip: 'رجوع',
              // maybePop: يعود للشاشة السابقة، ويتجاهل النقر إن لم يكن هناك ما
              // يُرجع له (بلا انهيار).
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: VillageColors.goldSoft,
                size: 26,
              ),
            )
          : null,
      title: titleWidget ??
          Semantics(
            header: true,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppAssets.amiriFont,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: VillageColors.gold,
                height: 1.5,
              ),
            ),
          ),
      actions: actions,
    );
  }
}

/// شريط خطأ أحمر (تحقّق/شبكة/حدّ رسائل).
class FarahErrorBanner extends StatelessWidget {
  const FarahErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VillageMetrics.space16,
        vertical: VillageMetrics.space12,
      ),
      decoration: BoxDecoration(
        color: VillageColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(VillageMetrics.radiusSm),
        border: Border.all(color: VillageColors.danger.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color: VillageColors.danger,
            size: 20,
          ),
          const SizedBox(width: VillageMetrics.space12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13.5,
                color: VillageColors.danger,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة توضيحية بلون هادئ (معلومات بلا خطأ).
class FarahNote extends StatelessWidget {
  const FarahNote({super.key, required this.message, this.icon});

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(VillageMetrics.space16),
      decoration: BoxDecoration(
        color: VillageColors.surface,
        borderRadius: BorderRadius.circular(VillageMetrics.radiusMd),
        border: Border.all(
          color: VillageColors.border.withValues(alpha: 0.8),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            icon ?? Icons.info_outline_rounded,
            color: VillageColors.goldSoft,
            size: 20,
          ),
          const SizedBox(width: VillageMetrics.space12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13.5,
                color: VillageColors.inkSoft,
                height: 1.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// مؤشّر «جارٍ…» داخل زرّ ذهبي (نفس نمط أزرار صفحة القرية).
class FarahBusyLabel extends StatelessWidget {
  const FarahBusyLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
        const SizedBox(width: VillageMetrics.space12),
        Text(label),
      ],
    );
  }
}

/// شارة «صاحب الفرح» الصغيرة (ذهبية) أمام اسم صاحب الفرح.
class FarahOwnerBadge extends StatelessWidget {
  const FarahOwnerBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VillageMetrics.space8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: VillageColors.gold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(VillageMetrics.radiusSm),
        border: Border.all(color: VillageColors.gold.withValues(alpha: 0.5)),
      ),
      child: const Text(
        FarahText.ownerBadge,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: VillageColors.goldSoft,
          height: 1.5,
        ),
      ),
    );
  }
}
