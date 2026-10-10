import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/widgets/joodcraft_logo.dart';
import '../../../../core/widgets/language_menu_button.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/fast_switch_dialog.dart';
import '../top_nav_groups.dart';

/// الشريط العلوي الأفقي للتطبيق (بديل اللوحة الجانبية العمودية).
///
/// الشريط مرّ بمرحلتين:
///
/// 1. **النسخة الأولى:** كل وجهة تبويباً مستقلاً → ١١ تبويباً تزاحموا على
///    العرض وصعب الوصول منها على النوافذ الضيّقة.
/// 2. **النسخة الحالية (٥ مجموعات + الحساب):** خمسة عناصر تنقّل فقط —
///    لوحة التحكم، المحرّكات ▾، التوليد الجماعي، المكتبات ▾، الإدارة ▾ —
///    وصورة الحساب في الطرف. الوجهات المخفية صارت بنود قوائم منسدلة.
///
/// المجموعات نفسها معرّفة في [topNavGroups] (طبقة تمثيلية لا تمسّ ترتيب
/// فروع الموجّه).
///
/// * **واعٍ بالاتجاه (RTL):** يعتمد على `Directionality` فلا يحتاج أي منطق
///   يدوي — في العربية تبدأ العلامة التجارية من اليمين والأدوات في الطرف
///   المقابل، وينعكس كل شيء تلقائياً عند التبديل إلى لغة LTR.
/// * **متجاوب:** [showBrandTitle] و[showAccountDetails] يخفيان النصوص الضيّقة
///   على النوافذ الصغيرة، و[onMenuTap] يظهر زر القائمة حين تلزم لوحة منسدلة.
/// * العناصر الخمسة قليلةٌ فلا حاجة للتمرير، مع الإبقاء على تمرير أفقي
///   احترازاً (لا يُسبّب أي تجاوز تخطيط مهما ضاق العرض).
class TopNavBar extends StatelessWidget {
  const TopNavBar({
    super.key,
    required this.currentPath,
    required this.onNavigate,
    this.onMenuTap,
    this.showLabels = true,
    this.showBrandTitle = true,
    this.showAccountDetails = true,
  });

  /// الارتفاع الرسمي المضغوط للشريط (يحافظ على مساحة الرسم العمودية).
  static const double height = 56;

  /// المسار الحالي لتحديد التبويب النشط.
  final String currentPath;

  /// يُستدعى عند اختيار تبويب أو بند قائمة — التنقّل الفعلي مسؤولية الهيكل الأب.
  final ValueChanged<String> onNavigate;

  /// إن كان غير null يظهر زر القائمة (فتح اللوحة المنسدلة) في الطرف.
  final VoidCallback? onMenuTap;

  /// إظهار التسميات النصية بجانب أيقونات التبويبات.
  final bool showLabels;

  /// إظهار اسم التطبيق بجانب الشعار.
  final bool showBrandTitle;

  /// إظهار اسم المستخدم وبريده داخل قائمة الحساب.
  final bool showAccountDetails;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    // خمس مجموعات فقط — «مستند جديد» ليس تبويباً بل نافذة عائمة تُفتح من
    // قائمة «ملف» (أو بـ`Ctrl+N`)، و«الدعوات» صارت جزءاً من التوليد الجماعي.
    final List<TopNavGroup> groups = topNavGroups(context);

    return Material(
      color: scheme.surface,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: scheme.outline)),
        ),
        child: Row(
          children: <Widget>[
            if (onMenuTap != null)
              IconButton(
                onPressed: onMenuTap,
                tooltip: context.l10n?.actionOpenMenu ?? 'القائمة',
                icon: const Icon(Icons.menu_rounded, size: 22),
              ),
            _Branding(showTitle: showBrandTitle),
            const SizedBox(width: AppTheme.space8),
            Container(
              width: 1,
              height: 26,
              color: scheme.outline,
            ),
            const SizedBox(width: AppTheme.space8),
            // عناصر التنقّل الخمسة — قليلةٌ لكنها قابلة للتمرير احترازاً.
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    for (final TopNavGroup group in groups)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space2,
                          vertical: AppTheme.space8,
                        ),
                        child: group.hasMenu
                            ? _TopMenuGroup(
                                key: ValueKey<String>('top-menu-${group.id}'),
                                group: group,
                                selected:
                                    group.containsPath(currentPath),
                                showLabel: showLabels,
                                onNavigate: onNavigate,
                              )
                            : _TopTab(
                                key: ValueKey<String>(
                                  'top-tab-${group.path}',
                                ),
                                group: group,
                                selected: group.containsPath(currentPath),
                                showLabel: showLabels,
                                onTap: () => onNavigate(group.path!),
                              ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppTheme.space8),
            const LanguageMenuButton(),
            const ThemeToggleButton(),
            const SizedBox(width: AppTheme.space4),
            _AccountSection(showDetails: showAccountDetails),
            const SizedBox(width: AppTheme.space8),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
//  العلامة التجارية
// ===========================================================================
class _Branding extends StatelessWidget {
  const _Branding({required this.showTitle});

  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // أيقونة البرنامج المحزومة (بضبط لون يكيّفه مع سطوع الثيم).
          JoodCraftLogo(
            size: 28,
            onDark: Theme.of(context).brightness == Brightness.dark,
          ),
          if (showTitle) ...<Widget>[
            const SizedBox(width: AppTheme.space8),
            const BrandWordmark(fontSize: 17),
          ],
        ],
      ),
    );
  }
}

// ===========================================================================
//  مظهر الزر المشترك (تبويب مباشر أو رأس قائمة منسدلة)
// ===========================================================================
/// الغلاف البصري المشترك بين [_TopTab] و[_TopMenuGroup] ليبقى الشريط متسقاً:
/// نفس الحشو، ونفس كبسولة التمييز، ونفس التلميح في الوضع المضغوط.
///
/// [child] يمرّر المحتوى كاملاً (أيقونة + تسمية + سهم القائمة إن وُجد) فيبقى
/// السهم داخل منطقة الضغط الملوّنة لا خارجها.
class _TopButtonShell extends StatelessWidget {
  const _TopButtonShell({
    required this.selected,
    required this.showLabel,
    required this.tooltip,
    required this.child,
    this.onTap,
  });

  final bool selected;
  final bool showLabel;

  /// التلميح — يظهر حين تُخفى التسمية، ويسدّ مكانها في الوضع المضغوط.
  final String tooltip;

  /// المحتوى كاملاً: الأيقونة + التسمية (+ سهم القائمة اختيارياً).
  final Widget child;

  /// `null` حين يتولّى الضغط عنصر أب ([PopupMenuButton]) فلا نضع كاشف لمس
  /// آخر فوقه (يتنافس على النقر).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    final Widget padded = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: EdgeInsets.symmetric(
        horizontal: showLabel ? AppTheme.space12 : AppTheme.space8,
        vertical: AppTheme.space6,
      ),
      decoration: BoxDecoration(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: child,
    );

    final Widget interactive = onTap == null
        ? padded
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: padded,
          );

    if (showLabel) return interactive;
    return Tooltip(message: tooltip, child: interactive);
  }
}

// ===========================================================================
//  تبويب مباشر (لوحة التحكم / التوليد الجماعي)
// ===========================================================================
class _TopTab extends StatelessWidget {
  const _TopTab({
    super.key,
    required this.group,
    required this.selected,
    required this.showLabel,
    required this.onTap,
  });

  final TopNavGroup group;
  final bool selected;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final Color foreground =
        selected ? scheme.primary : scheme.onSurfaceVariant;

    return _TopButtonShell(
      selected: selected,
      showLabel: showLabel,
      tooltip: group.label,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(group.icon, size: 19, color: foreground),
          if (showLabel) ...<Widget>[
            const SizedBox(width: AppTheme.space6),
            Text(
              group.label,
              style: text.bodyMedium?.copyWith(
                fontSize: 13.5,
                color: foreground,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ===========================================================================
//  رأس قائمة منسدلة (المحرّكات / المكتبات / الإدارة)
// ===========================================================================
/// زر واحد يفتح قائمة ببنود الوجهات.
///
/// تُغلق القائمة تلقائياً عند اختيار أي بند (سلوك `PopupMenuButton` الافتراضي)
/// ثم يُستدعى [onNavigate] بالمسار المختار.
class _TopMenuGroup extends StatelessWidget {
  const _TopMenuGroup({
    super.key,
    required this.group,
    required this.selected,
    required this.showLabel,
    required this.onNavigate,
  });

  final TopNavGroup group;
  final bool selected;
  final bool showLabel;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final Color foreground =
        selected ? scheme.primary : scheme.onSurfaceVariant;

    return PopupMenuButton<String>(
      // الشكل والتلميح يوفّرهما [_TopButtonShell] تحته — فلا نكرّر تلميحاً.
      tooltip: '',
      position: PopupMenuPosition.under,
      color: scheme.surfaceContainerHighest,
      elevation: 8,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: scheme.outline),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      onSelected: onNavigate,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        for (final TopNavMenuEntry entry in group.entries)
          PopupMenuItem<String>(
            value: entry.path,
            height: 40,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(entry.icon, size: 17, color: scheme.onSurfaceVariant),
                const SizedBox(width: AppTheme.space10),
                // بلا Flexible يتجاوز بند القائمة عرض النافذة المنسدلة حين
                // يطول عنوانه (كان يرمي RenderFlex overflow).
                Flexible(
                  child: Text(
                    entry.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                      fontSize: 13.5,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
      // `onTap: null` في القشرة: زر القائمة هو من يلتقط النقر، فلا كاشفان.
      child: _TopButtonShell(
        selected: selected,
        showLabel: showLabel,
        tooltip: group.label,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(group.icon, size: 19, color: foreground),
            if (showLabel) ...<Widget>[
              const SizedBox(width: AppTheme.space6),
              Text(
                group.label,
                style: text.bodyMedium?.copyWith(
                  fontSize: 13.5,
                  color: foreground,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
            // سهم القائمة — داخل منطقة الضغط الملوّنة.
            const SizedBox(width: AppTheme.space2),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 20,
              color: foreground,
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
//  قسم الحساب والأدوات
// ===========================================================================
/// صورة المستخدم في طرف الشريط + قائمة منسدلة: بروفايل ثم تسجيل الخروج.
///
/// التغيير عن النسخة السابقة: كان الاسم/البريد وزر الخروج عناصر مستقلة
/// تزاحم العرض، فصارت كلها بنود قائمة واحدة خلف صورة المستخدم.
class _AccountSection extends StatelessWidget {
  const _AccountSection({required this.showDetails});

  final bool showDetails;

  Future<void> _signOut(BuildContext context) async {
    final AuthProvider auth = context.read<AuthProvider>();
    try {
      await auth.signOut();
      if (!context.mounted) return;
      context.showSuccess(
        context.l10n?.dashLogoutSuccess ?? 'تم تسجيل الخروج بنجاح.',
      );
    } on Object {
      if (!context.mounted) return;
      context.showError(
        context.l10n?.dashLogoutError ?? 'تعذّر تسجيل الخروج. حاول مرة أخرى.',
      );
    }
  }

  /// تبديل الحساب السريع: حوار اختيار حساب آخر + كلمة مروره، ثم استبدال
  /// الجلسة فوراً (تُحفظ مسودّات المشاريع المفتوحة قبل التبديل).
  Future<void> _fastSwitch(BuildContext context) async {
    final l10n = context.l10n;
    final bool? switched = await showFastSwitchDialog(context);
    if (switched != true || !context.mounted) return;
    context.showSuccess(
      l10n?.admSwitchSuccess ?? 'تم تبديل الحساب بنجاح.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final l10n = context.l10n;

    // الوضع المحلي هو الأصل الآن: بلا حساب بعيد تُعرض شارة «محلي» بدل زرّ
    // الخروج (فلا يُعرض إجراء لا معنى له في تطبيق بلا حساب).
    final bool localOnly = !auth.isServiceAvailable;
    final String name = auth.user?.displayName ?? l10n?.dashUser ?? 'مستخدم';
    final String email = auth.user?.email ?? '';
    final String initials = auth.user?.initials ?? 'JC';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // شارة الوضع المحلي تبقى ظاهرة في الشريط: إعلان دائم أن الحفظ على
        // هذا الجهاز وحده، ولا يُطلب من المستخدم فتح قائمة لمعرفته.
        if (localOnly)
          _LocalModeBadge(label: l10n?.dashLocalMode ?? 'محلي'),
        PopupMenuButton<_AccountAction>(
          key: const ValueKey<String>('top-account-menu'),
          tooltip: l10n?.navUser ?? 'الحساب',
          position: PopupMenuPosition.under,
          color: scheme.surfaceContainerHighest,
          elevation: 8,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: scheme.outline),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          onSelected: (_AccountAction action) {
            switch (action) {
              case _AccountAction.switchAccount:
                unawaited(_fastSwitch(context));
              case _AccountAction.signOut:
                unawaited(_signOut(context));
            }
          },
          itemBuilder: (BuildContext context) =>
              <PopupMenuEntry<_AccountAction>>[
            // البروفايل: اسم المستخدم وبريده (يُخفى في النوافذ الضيّقة).
            if (showDetails) ...<PopupMenuEntry<_AccountAction>>[
              PopupMenuItem<_AccountAction>(
                enabled: false,
                height: 52,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      name,
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        textDirection: TextDirection.ltr,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
            ],
            // تبديل الحساب السريع — لمن يملك أكثر من حساب محلي.
            if (auth.isAuthenticated && auth.isLocalSwitchAvailable)
              PopupMenuItem<_AccountAction>(
                value: _AccountAction.switchAccount,
                height: 40,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.swap_horiz_rounded,
                        size: 17, color: scheme.onSurfaceVariant),
                    const SizedBox(width: AppTheme.space10),
                    Text(
                      l10n?.admSwitchAccount ?? 'تبديل الحساب',
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            if (localOnly)
              // وضع محلي: لا خروج ولا تبديل — سطر توضيحي فقط.
              PopupMenuItem<_AccountAction>(
                enabled: false,
                height: 40,
                child: Text(
                  l10n?.dashLocalStorage ??
                      'الحفظ محلي على هذا الجهاز — لا يُرفع أي مشروع إلى سيرفر.',
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              )
            else ...<PopupMenuEntry<_AccountAction>>[
              const PopupMenuDivider(),
              PopupMenuItem<_AccountAction>(
                value: _AccountAction.signOut,
                height: 40,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.logout_rounded,
                        size: 17, color: scheme.onSurfaceVariant),
                    const SizedBox(width: AppTheme.space10),
                    Text(
                      l10n?.actionSignOut ?? 'تسجيل الخروج',
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Tooltip(
                  message: name,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.gold,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

}

/// بنود قائمة الحساب.
enum _AccountAction { switchAccount, signOut }

// ===========================================================================
//  شارة الوضع المحلي
// ===========================================================================
/// شارة صغيرة تعلن أن العمل محلي أوفلاين: لا حساب ولا خادم ولا رفع.
class _LocalModeBadge extends StatelessWidget {
  const _LocalModeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: context.l10n?.dashLocalStorage ??
          'الحفظ محلي على هذا الجهاز — لا يُرفع أي مشروع إلى سيرفر.',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space8,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: scheme.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(color: scheme.success.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.offline_bolt_rounded,
              size: 13,
              color: scheme.success,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: scheme.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
