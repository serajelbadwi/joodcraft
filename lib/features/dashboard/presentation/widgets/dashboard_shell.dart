import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/templates/unsaved_changes_guard.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/widgets/joodcraft_logo.dart';
import '../../../../core/widgets/language_menu_button.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../dashboard_destinations.dart';

/// الهيكل العام للتطبيق بعد تسجيل الدخول: لوحة جانبية كحلية + منطقة محتوى.
///
/// مقاسات متجاوبة:
/// * `>= 1080`: لوحة كاملة بالنص.
/// * `760 – 1080`: شريط أيقونات مصغّر.
/// * `< 760`: لوحة منسدلة (Drawer).
class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key, required this.child});

  final Widget child;

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// تنقّل آمن: يسأل [UnsavedChangesGuard] أولاً، فلا تُغادَر شاشةٌ بها عمل غير
  /// محفوظ (مثل محرّر القوالب) إلا بعد تأكيد المستخدم.
  Future<void> _navigate(
    BuildContext context,
    String next, {
    bool popDrawer = false,
  }) async {
    if (popDrawer) Navigator.of(context).pop();
    final bool allowed = await UnsavedChangesGuard.instance.canLeave();
    if (!allowed || !context.mounted) return;
    context.go(next);
  }

  @override
  Widget build(BuildContext context) {
    final String path = GoRouterState.of(context).matchedLocation;
    final bool showDrawer = MediaQuery.sizeOf(context).width < 760;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      drawer: showDrawer
          ? Drawer(
              width: 286,
              backgroundColor: AppColors.navy,
              child: _Sidebar(
                currentPath: path,
                compact: false,
                onNavigate: (String next) => _navigate(context, next, popDrawer: true),
              ),
            )
          : null,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth;
          final bool compact = width < 1080;
          final bool showSidebar = width >= 760;

          return Row(
            children: <Widget>[
              if (showSidebar)
                SizedBox(
                  width: compact ? 86 : 268,
                  child: _Sidebar(
                    currentPath: path,
                    compact: compact,
                    onNavigate: (String next) => _navigate(context, next),
                  ),
                ),
              Expanded(
                child: Column(
                  children: <Widget>[
                    _TopBar(
                      destination: destinationForPath(path),
                      onMenuTap: showDrawer
                          ? () => _scaffoldKey.currentState?.openDrawer()
                          : null,
                    ),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ===========================================================================
//  اللوحة الجانبية
// ===========================================================================
class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.currentPath,
    required this.compact,
    required this.onNavigate,
  });

  final String currentPath;
  final bool compact;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();

    return ColoredBox(
      color: AppColors.navy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? AppTheme.space12 : AppTheme.space20,
              vertical: AppTheme.space24,
            ),
            child: compact
                ? const Center(child: JoodCraftLogo(size: 40, onDark: true))
                : const JoodCraftWordmark(markSize: 44, onDark: true),
          ),
          const Divider(color: AppColors.navySoft, height: 1),
          const SizedBox(height: AppTheme.space12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space8,
                vertical: AppTheme.space8,
              ),
              itemCount: dashboardDestinations.length,
              itemBuilder: (BuildContext context, int index) {
                final DashboardDestination item = dashboardDestinations[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.space4),
                  child: _SidebarItem(
                    destination: item,
                    selected: item.path == currentPath,
                    compact: compact,
                    onTap: () => onNavigate(item.path),
                  ),
                );
              },
            ),
          ),
          const Divider(color: AppColors.navySoft, height: 1),
          Padding(
            padding: const EdgeInsets.all(AppTheme.space12),
            child: compact
                ? IconButton(
                    tooltip: context.l10n?.actionSignOut ?? 'تسجيل الخروج',
                    onPressed: () => _signOut(context),
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.onNavy,
                    ),
                  )
                : _AccountTile(
                    onSignOut: () => _signOut(context),
                    name: auth.user?.displayName ?? 'مستخدم',
                    email: auth.user?.email ?? '',
                    initials: auth.user?.initials ?? 'JC',
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final AuthProvider auth = context.read<AuthProvider>();
    try {
      await auth.signOut();
      if (!context.mounted) return;
      context.showSuccess('تم تسجيل الخروج بنجاح.');
    } on Object {
      if (!context.mounted) return;
      context.showError('تعذّر تسجيل الخروج. حاول مرة أخرى.');
    }
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final DashboardDestination destination;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color foreground =
        selected ? AppColors.gold : AppColors.onNavy.withValues(alpha: 0.72);

    final Widget content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppTheme.space12 : AppTheme.space16,
        vertical: AppTheme.space12,
      ),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.gold.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        mainAxisAlignment:
            compact ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: <Widget>[
          Icon(destination.icon, size: 20, color: foreground),
          if (!compact) ...<Widget>[
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Text(
                destination.label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: foreground,
                      fontSize: 14.5,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
            ),
          ],
        ],
      ),
    );

    return Tooltip(
      message: compact ? destination.label : '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: content,
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.name,
    required this.email,
    required this.initials,
    required this.onSignOut,
  });

  final String name;
  final String email;
  final String initials;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppColors.navySoft.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.gold,
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.onNavy,
                        fontSize: 13,
                      ),
                ),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onNavy.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: context.l10n?.actionSignOut ?? 'تسجيل الخروج',
            onPressed: onSignOut,
            iconSize: 18,
            icon: const Icon(Icons.logout_rounded, color: AppColors.onNavy),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
//  الشريط العلوي
// ===========================================================================
class _TopBar extends StatelessWidget {
  const _TopBar({required this.destination, this.onMenuTap});

  final DashboardDestination destination;
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outline)),
      ),
      child: Row(
        children: <Widget>[
          if (onMenuTap != null)
            IconButton(
              onPressed: onMenuTap,
              icon: const Icon(Icons.menu_rounded),
            ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(destination.label, style: text.titleMedium),
                const SizedBox(height: 2),
                Text(
                  destination.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.space16),
          // منتقي اللغة (🌐) — يبدّل الواجهة والاتجاه فوراً وبلا إعادة تشغيل.
          const LanguageMenuButton(),
          // تبديل المظهر بنقرة واحدة (☀️/🌙) — يقرأ حالة المحرّك ويحدّث فوراً.
          const ThemeToggleButton(),
          const SizedBox(width: AppTheme.space4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.wifi_off_rounded,
                  size: 15,
                  color: scheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n?.offlineProcessingLabel ?? 'معالجة محلية',
                  style: text.labelSmall?.copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
