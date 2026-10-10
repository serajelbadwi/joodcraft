import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/widgets/joodcraft_logo.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../dashboard_destinations.dart';
import 'app_menu_bar.dart';
import 'top_nav_bar.dart';

/// الهيكل العام للتطبيق بعد تسجيل الدخول.
///
/// بُني على **شريط تنقّل أفقي مضغوط** ([TopNavBar]) بدل اللوحة الجانبية
/// العمودية، فتمتد منطقة المحتوى (المحرّر/اللوحة) على كامل عرض الشاشة.
///
/// المقاسات المتجاوبة:
/// * `>= 1180`: تبويبات كاملة بالتسميات.
/// * `760 – 1180`: تبويبات بأيقوناتٍ فقط (تلميح عند المرور) لتوفير العرض.
/// * `< 760`: زر قائمة يفتح لوحة منسدلة (Drawer) عمودية.
class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key, required this.navigationShell});

  /// هيكل الفروع الحيّ (‏`StatefulShellRoute.indexedStack`): يمنح التنقّل بين
  /// الأقسام دون إتلاف حالة أي فرع، ويقود التبويب النشط عبر [currentIndex].
  final StatefulNavigationShell navigationShell;

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// التنقّل بين الأقسام — **بلا أي سؤال عن عمل غير محفوظ**.
  ///
  /// كل فرع يبقى حيّاً في `IndexedStack`، فالتنقّل لا يُتلف شيئاً (محرّر
  /// مفتوح، جلسة توليد جماعي، أسماء مُصحَّحة…). التأكيد مطلوب فقط عند إجراء
  /// إتلافي **صريح** داخل الشاشة نفسها (قالب جديد/مسح البيانات).
  void _navigate(String next, {bool popDrawer = false}) {
    if (popDrawer) Navigator.of(context).pop();
    navigateToDestination(context, next);
  }

  /// أمر «مستند جديد…» — نفس أمر قائمة `ملف`، تنفيذه هو فتح النافذة العائمة
  /// بلا مغادرة مساحة العمل الحالية.
  void _newDocument() => _navigate(AppRoutes.newProject);

  @override
  Widget build(BuildContext context) {
    // المسار النشط من فهرس الفرع الحيّ — أدقّ من مطابقة العنوان عند وجود
    // مسارات متداخلة، ويُبقي التبويب مُبرَزاً صحيحاً.
    final List<DashboardDestination> destinations = dashboardDestinations(context);
    final int rawIndex = widget.navigationShell.currentIndex;
    final int branchIndex =
        (rawIndex >= 0 && rawIndex < destinations.length) ? rawIndex : 0;
    final String path = destinations[branchIndex].path;
    final double width = MediaQuery.sizeOf(context).width;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool showDrawer = width < 760;
    final bool showLabels = width >= 1180;
    final bool showBrandTitle = width >= 900;
    final bool showAccountDetails = width >= 1080;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      drawer: showDrawer
          ? Drawer(
              width: 286,
              // كحلي نهاراً، سليت `#3E3E3E` ليلاً — اتساق مع اللوحة الداكنة.
              backgroundColor: scheme.brandSurface,
              child: _NavDrawer(
                currentPath: path,
                onNavigate: (String next) => _navigate(next, popDrawer: true),
              ),
            )
          : null,
      // اختصارات سطح المكتب على مستوى الهيكل كله: `Ctrl+N` (و`⌘N` على macOS)
      // يفتحان «مستند جديد…» فعلياً — والاختصار في قائمة `ملف` ليس تلميحاً
      // مكتوباً بل مفتاحاً عاملاً من أي شاشة.
      body: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.keyN, control: true):
              _newDocument,
          const SingleActivator(LogicalKeyboardKey.keyN, meta: true):
              _newDocument,
        },
        // عقدة تركيز في الهيكل من أول لحظة: تعمل الاختصارات بلا نقرة تمهيدية،
        // وحقول النص تأخذ التركيز عند النقر عليها فتستهلك مفاتيحها وحدها.
        child: Focus(
          autofocus: true,
          child: Column(
            children: <Widget>[
              // شريط القوائم أولاً (كما في تطبيقات سطح المكتب)، ثم الشريط
              // العلوي: فيرتفع «مستند جديد» عن التبويبات إلى مكانه الطبيعي في
              // قائمة «ملف».
              AppMenuBar(onNavigate: _navigate),
              TopNavBar(
                currentPath: path,
                showLabels: showLabels,
                showBrandTitle: showBrandTitle,
                showAccountDetails: showAccountDetails,
                onMenuTap: showDrawer
                    ? () => _scaffoldKey.currentState?.openDrawer()
                    : null,
                onNavigate: _navigate,
              ),
              Expanded(child: widget.navigationShell),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
//  اللوحة المنسدلة (الشاشات الصغيرة)
// ===========================================================================
class _NavDrawer extends StatelessWidget {
  const _NavDrawer({required this.currentPath, required this.onNavigate});

  final String currentPath;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final ColorScheme scheme = Theme.of(context).colorScheme;
    // اللوحة المنسدلة تنقّل أيضاً: بلا «مستند جديد» الذي يبقى في مكانه
    // الجديد (زر «‎+ جديد» وقائمة «ملف»).
    final List<DashboardDestination> items = dashboardDestinations(context)
        .where((DashboardDestination item) => item.inNavigation)
        .toList(growable: false);

    return ColoredBox(
      color: scheme.brandSurface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.space20,
                vertical: AppTheme.space20,
              ),
              child: JoodCraftWordmark(markSize: 40, onDark: true),
            ),
            Divider(color: scheme.brandSurfaceSoft, height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space8,
                  vertical: AppTheme.space8,
                ),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int index) {
                  final DashboardDestination item = items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.space4),
                    child: _DrawerItem(
                      destination: item,
                      selected: item.path == currentPath,
                      onTap: () => onNavigate(item.path),
                    ),
                  );
                },
              ),
            ),
            Divider(color: scheme.brandSurfaceSoft, height: 1),
            Padding(
              padding: const EdgeInsets.all(AppTheme.space12),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.gold,
                    child: Text(
                      auth.user?.initials ?? 'JC',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space8),
                  Expanded(
                    child: Text(
                      auth.user?.displayName ??
                          context.l10n?.dashUser ??
                          'مستخدم',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.onNavy,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: context.l10n?.actionSignOut ?? 'تسجيل الخروج',
                    onPressed: () => _signOut(context),
                    iconSize: 18,
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.onNavy,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final DashboardDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color foreground =
        selected ? AppColors.gold : AppColors.onNavy.withValues(alpha: 0.72);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space16,
          vertical: AppTheme.space12,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.gold.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: <Widget>[
            Icon(destination.icon, size: 20, color: foreground),
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
        ),
      ),
    );
  }
}
