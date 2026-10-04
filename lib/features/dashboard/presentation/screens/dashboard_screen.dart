import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/app_user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../dashboard_destinations.dart';

/// لوحة التحكم الرئيسية.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final AppUser? user = auth.user;
    final List<DashboardDestination> modules = dashboardDestinations(context)
        .where((DashboardDestination item) => item.path != AppRoutes.dashboard)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _WelcomeCard(user: user),
          const SizedBox(height: AppTheme.space24),
          Text(
            context.l10n?.dashModules ?? 'وحدات المنصة',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.space12),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final int columns = constraints.maxWidth >= 1180
                  ? 3
                  : constraints.maxWidth >= 720
                      ? 2
                      : 1;
              const double gap = AppTheme.space16;
              final double itemWidth =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: <Widget>[
                  for (final DashboardDestination module in modules)
                    SizedBox(
                      width: itemWidth,
                      child: _ModuleCard(destination: module),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppTheme.space24),
          const _FoundationCard(),
        ],
      ),
    );
  }
}

// ===========================================================================
//  بطاقة الترحيب
// ===========================================================================
class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: <Color>[AppColors.navy, AppColors.navyDeep],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  context.l10n?.dashWelcome(
                        user?.displayName ?? 'مستخدم جودكرافت',
                      ) ??
                      'أهلاً بك، ${user?.displayName ?? 'مستخدم جودكرافت'}',
                  style: text.headlineSmall?.copyWith(
                    color: AppColors.onNavy,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  context.l10n?.dashSubscription(
                        user?.subscriptionTier.labelAr ?? 'مجاني',
                      ) ??
                      'الاشتراك: ${user?.subscriptionTier.labelAr ?? 'مجاني'}',
                  style: text.labelSmall?.copyWith(color: AppColors.gold),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            user?.hasOrganization ?? false
                ? (context.l10n?.dashOrg(user!.organizationName ?? '') ??
                    'الجهة: ${user!.organizationName}')
                : context.l10n?.dashOrgMissing ??
                    'لم تُسجّل اسم جهتك بعد — سيُطبع تلقائياً على الشهادات والعقود.',
            style: text.bodyLarge?.copyWith(
              color: AppColors.onNavy.withValues(alpha: 0.78),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppTheme.space20),
          Container(
            width: 56,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
//  بطاقة وحدة
// ===========================================================================
class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.destination});

  final DashboardDestination destination;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => context.go(destination.path),
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(
                  destination.icon,
                  size: 22,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppTheme.space16),
              Text(destination.label, style: text.titleMedium),
              const SizedBox(height: 6),
              Text(destination.description, style: text.bodySmall),
              const SizedBox(height: AppTheme.space12),
              Row(
                children: <Widget>[
                  Text(
                    context.l10n?.dashOpenModule ?? 'فتح الوحدة',
                    style: text.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.goldDeep,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 14,
                    color: Theme.of(context).colorScheme.goldDeep,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
//  بطاقة حالة التأسيس (توثيق المرحلة الأولى داخل الواجهة)
// ===========================================================================
class _FoundationCard extends StatelessWidget {
  const _FoundationCard();

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final List<String> done = <String>[
      context.l10n?.dashRoadmapSupabase ??
          'تأسيس قاعدة بيانات Supabase (جداول + RLS + Triggers)',
      context.l10n?.dashRoadmapModular ??
          'هيكل Modular Feature-First قابل للتوسّع',
      context.l10n?.dashRoadmapTheme ??
          'الثيم البصري للهوية ودعم RTL بخط Cairo',
      context.l10n?.dashRoadmapAuth ??
          'المصادقة: تسجيل الدخول وإنشاء الحساب واستعادة كلمة المرور',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.verified_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.success,
                ),
                const SizedBox(width: AppTheme.space8),
                Text(context.l10n?.dashPhaseOneDone ?? 'المرحلة الأولى مكتملة', style: text.titleMedium),
              ],
            ),
            const SizedBox(height: AppTheme.space16),
            for (final String item in done)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.space8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.success,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space8),
                    Expanded(child: Text(item, style: text.bodyMedium)),
                  ],
                ),
              ),
            const SizedBox(height: AppTheme.space8),
            const Divider(),
            const SizedBox(height: AppTheme.space12),
            Text(
              context.l10n?.dashNextPhase ?? 'التالية: محرك PDF والخطوط العربية أوفلاين، ثم محرر القوالب البصري.',
              style: text.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.goldDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
