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
import '../dashboard_destinations.dart';

/// الشريط العلوي الأفقي للتطبيق (بديل اللوحة الجانبية العمودية).
///
/// يجمع في صفٍّ واحد مضغوط (**ارتفاعه [height]** فقط): العلامة التجارية، ثم
/// تبويبات محرّكات العمل، ثم أدوات المستخدم (اللغة، المظهر، الحساب، الخروج).
///
/// * **واعٍ بالاتجاه (RTL):** يعتمد على `Directionality` فلا يحتاج أي منطق
///   يدوي — في العربية تبدأ العلامة التجارية من اليمين والأدوات في الطرف
///   المقابل، وينعكس كل شيء تلقائياً عند التبديل إلى لغة LTR.
/// * **متجاوب:** [showBrandTitle] و[showAccountDetails] يخفيان النصوص الضيّقة
///   على النوافذ الصغيرة، و[onMenuTap] يظهر زر القائمة حين تلزم لوحة منسدلة.
/// * التبويبات قابلة للتمرير أفقياً، فلا تُسبّب أي تجاوز تخطيط مهما ضاق العرض.
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

  /// يُستدعى عند اختيار تبويب — التنقّل الفعلي مسؤولية الهيكل الأب.
  final ValueChanged<String> onNavigate;

  /// إن كان غير null يظهر زر القائمة (فتح اللوحة المنسدلة) في الطرف.
  final VoidCallback? onMenuTap;

  /// إظهار التسميات النصية بجانب أيقونات التبويبات.
  final bool showLabels;

  /// إظهار اسم التطبيق بجانب الشعار.
  final bool showBrandTitle;

  /// إظهار اسم المستخدم وبريده بجانب الصورة الرمزية.
  final bool showAccountDetails;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    // التنقّل وحده: «مستند جديد» ليس تبويباً بل نافذة عائمة يُفتح من قائمة
    // «ملف» (أو بـ`Ctrl+N`)، فلا يزاحم تبويبات المحرّكات.
    final List<DashboardDestination> destinations = dashboardDestinations(context)
        .where((DashboardDestination item) => item.inNavigation)
        .toList(growable: false);

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
            // تبويبات المحرّكات — قابلة للتمرير أفقياً عند ضيق العرض.
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    for (final DashboardDestination item in destinations)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space2,
                          vertical: AppTheme.space8,
                        ),
                        child: _TopTab(
                          key: ValueKey<String>('top-tab-${item.path}'),
                          destination: item,
                          selected: item.path == currentPath,
                          showLabel: showLabels,
                          onTap: () => onNavigate(item.path),
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
//  تبويب محرّك واحد
// ===========================================================================
class _TopTab extends StatelessWidget {
  const _TopTab({
    super.key,
    required this.destination,
    required this.selected,
    required this.showLabel,
    required this.onTap,
  });

  final DashboardDestination destination;
  final bool selected;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final Color foreground =
        selected ? scheme.primary : scheme.onSurfaceVariant;

    final Widget content = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: AnimatedContainer(
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(destination.icon, size: 19, color: foreground),
            if (showLabel) ...<Widget>[
              const SizedBox(width: AppTheme.space6),
              Text(
                destination.label,
                style: text.bodyMedium?.copyWith(
                  fontSize: 13.5,
                  color: foreground,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (showLabel) return content;
    return Tooltip(message: destination.label, child: content);
  }
}

// ===========================================================================
//  قسم الحساب والأدوات
// ===========================================================================
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

    // الوضع المحلي هو الأصل الآن: بلا حساب بعيد تُعرض شارة «محلي» بدل زرّ
    // الخروج (فلا يُعرض إجراء لا معنى له في تطبيق بلا حساب).
    final bool localOnly = !auth.isServiceAvailable;
    final String name =
        auth.user?.displayName ?? context.l10n?.dashUser ?? 'مستخدم';
    final String email = auth.user?.email ?? '';
    final String initials = auth.user?.initials ?? 'JC';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (showDetails && email.isNotEmpty) ...<Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
              Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.ltr,
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppTheme.space8),
        ],
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
        // تبديل الحساب السريع — للمديرين الفرعيين المحليين فقط (مخزن محلي
        // يدعم المصادقة باسم المستخدم)، فلا يظهر بلا فائدة في وضع الخادم.
        if (auth.isAuthenticated && auth.isLocalSwitchAvailable) ...<Widget>[
          const SizedBox(width: AppTheme.space4),
          Tooltip(
            message: context.l10n?.admSwitchAccount ?? 'تبديل الحساب',
            child: IconButton(
              key: const ValueKey<String>('dash-switch-account'),
              tooltip: '',
              onPressed: () => _fastSwitch(context),
              iconSize: 19,
              icon: const Icon(Icons.swap_horiz_rounded),
            ),
          ),
        ],
        if (localOnly)
          _LocalModeBadge(
            label: context.l10n?.dashLocalMode ?? 'محلي',
          )
        else
          IconButton(
            tooltip: context.l10n?.actionSignOut ?? 'تسجيل الخروج',
            onPressed: () => _signOut(context),
            iconSize: 19,
            icon: const Icon(Icons.logout_rounded),
          ),
      ],
    );
  }
}

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
