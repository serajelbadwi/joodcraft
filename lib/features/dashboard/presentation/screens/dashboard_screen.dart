import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/projects/project_record.dart';
import '../../../../core/projects/project_thumbnails.dart';
import '../../../../core/projects/projects_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/app_user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../dashboard_destinations.dart';

/// لوحة التحكم الرئيسية.
///
/// أول ما تعرضه بعد الترحيب: **المشاريع الأخيرة** من المخزن المحلي. القائمة
/// تُقرأ من الذاكرة (قُرئت مرة واحدة عند الإقلاع) فتظهر فوراً بلا شاشة تحميل،
/// وتُحدَّث وحدها عند كل حفظ في المحرّر لأنها تستمع إلى [ProjectsController].
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, this.projects});

  /// محرّك المشاريع المحلي — يُحقن في الاختبارات، والافتراضي النسخة العامة.
  final ProjectsController? projects;

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final AppUser? user = auth.user;
    final ProjectsController projects =
        this.projects ?? ProjectsController.instance;
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
          _RecentProjectsCard(projects: projects),
          const SizedBox(height: AppTheme.space24),
          const _FoundationCard(),
        ],
      ),
    );
  }
}

// ===========================================================================
//  المشاريع الأخيرة (من المخزن المحلي)
// ===========================================================================
/// بطاقة «المشاريع الأخيرة»: مصدرها **جدول المشاريع المحلي** مباشرةً.
///
/// لماذا هنا؟ لأن هذه أول شاشة تُفتح، فوجود آخر المشاريع فيها يعني متابعة العمل
/// بنقرة واحدة بدل التنقّل إلى المكتبة والبحث. القراءة من الذاكرة (والحفظ يحدّثها
/// وحده) يجعلها بلا أي تأخير محسوس.
class _RecentProjectsCard extends StatelessWidget {
  const _RecentProjectsCard({required this.projects});

  final ProjectsController projects;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: projects,
      builder: (BuildContext context, Widget? _) {
        final List<ProjectRecord> recent = projects.recent();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.photo_library_rounded,
                      size: 20,
                      color: scheme.goldDeep,
                    ),
                    const SizedBox(width: AppTheme.space8),
                    Text(
                      context.l10n?.dashRecentProjects ?? 'المشاريع الأخيرة',
                      style: text.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      '${projects.count}',
                      style: text.titleMedium?.copyWith(
                        color: scheme.goldDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space4),
                Text(
                  context.l10n?.dashLocalStorage ??
                      'الحفظ محلي على هذا الجهاز — لا يُرفع أي مشروع إلى سيرفر.',
                  style: text.bodySmall,
                ),
                const SizedBox(height: AppTheme.space16),
                if (recent.isEmpty)
                  _RecentEmptyState()
                else
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
                          for (final ProjectRecord project in recent)
                            SizedBox(
                              width: itemWidth,
                              child: _ProjectTile(project: project),
                            ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// حالة «لا مشاريع بعد» — مع باب مباشر لإنشاء مستند جديد.
class _RecentEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.l10n?.dashRecentEmpty ??
                'لا توجد مشاريع محفوظة على هذا الجهاز بعد — أنشئ مستنداً جديداً '
                    'وستجده هنا فوراً.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: AppTheme.space12),
          FilledButton.tonalIcon(
            key: const ValueKey<String>('dash-recent-new-project'),
            onPressed: () => navigateToDestination(
              context,
              AppRoutes.newProject,
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(
              context.l10n?.menuNewDocument ?? 'مستند جديد…',
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة مشروع واحد: صورته المصغّرة المحلية (إن وُجدت) وأبعاده وتاريخ تعديله.
class _ProjectTile extends StatelessWidget {
  const _ProjectTile({required this.project});

  final ProjectRecord project;

  /// يفتح المشروع في محرّكه (شهادات/عقود) كما يفعل أي مدخل آخر في التطبيق.
  void _open(BuildContext context) {
    final String path = project.category == TemplateCategory.contract
        ? AppRoutes.contractBuilder
        : AppRoutes.certificateBuilder;
    context.go(path, extra: project.toTemplateRecord());
  }

  /// الأبعاد بالمليمتر — لغة المستخدم في الشهادات والعقود (النقطة الفاحصة
  /// وحدة داخلية لا يعرفها أحد خارج المحرّك).
  String get _sizeLabel {
    final double w = project.width * 25.4 / 72;
    final double h = project.height * 25.4 / 72;
    return '${w.round()} × ${h.round()} mm';
  }

  String get _dateLabel {
    final DateTime date = project.updatedAt;
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}/${two(date.month)}/${two(date.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final ImageProvider<Object>? thumbnail =
        ProjectThumbnails.imageOf(project.thumbnailPath);

    return InkWell(
      key: ValueKey<String>('dash-project-${project.id}'),
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 54,
              height: 54,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: scheme.brandSurfaceSoft,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                image: thumbnail == null
                    ? null
                    : DecorationImage(image: thumbnail, fit: BoxFit.cover),
              ),
              child: thumbnail != null
                  ? null
                  : Icon(
                      Icons.description_outlined,
                      size: 22,
                      color: scheme.onSurfaceVariant,
                    ),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    project.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _sizeLabel,
                    style: text.bodySmall,
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${context.l10n?.dashRecentOpen ?? 'فتح المشروع'} · $_dateLabel',
                    style: text.labelSmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_back_rounded,
              size: 14,
              color: scheme.goldDeep,
            ),
          ],
        ),
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
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space32),
      decoration: BoxDecoration(
        // كحلي نهاراً، وتدرّج سليت هادئ ليلاً (‎#3E3E3E‎) بلا أي كتلة كحلية
        // شاذّة داخل اللوحة الداكنة.
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: <Color>[scheme.brandSurface, scheme.brandSurfaceDeep],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: scheme.brightness == Brightness.dark
              ? scheme.outline
              : Colors.transparent,
        ),
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
      // التنقّل عبر الفرع الحيّ يحافظ على حالة القسم الهدف بدل إعادة بنائه.
      onTap: () => navigateToDestination(context, destination.path),
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
      context.l10n?.dashRoadmapLocal ??
          'قاعدة مشاريع محلية (جدول projects) وحفظ محلي 100%',
      context.l10n?.dashRoadmapModular ??
          'هيكل Modular Feature-First قابل للتوسّع',
      context.l10n?.dashRoadmapTheme ??
          'الثيم البصري للهوية ودعم RTL بخط Cairo',
      context.l10n?.dashRoadmapOffline ??
          'العمل أوفلاين بالكامل: لا رفع للمشاريع ولا حاجة إلى شبكة',
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
