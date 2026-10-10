import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_l10n.dart';
import '../../core/projects/local_project_repository.dart';
import '../../core/projects/projects_controller.dart';
import '../../core/projects/projects_template_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/templates/template_draft.dart';
import '../../core/templates/template_record.dart';
import '../../core/templates/template_repository.dart';
import '../../features/assets_manager/presentation/screens/assets_manager_screen.dart';
import '../../features/about/presentation/screens/about_screen.dart';
import '../../features/brand/presentation/screens/brand_settings_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/admin_accounts_screen.dart';
import '../../features/batch_processor/presentation/screens/batch_processor_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/certificate_builder/presentation/screens/certificate_preview_screen.dart';
import '../../features/certificate_builder/presentation/screens/template_editor_screen.dart';
import '../../features/contract_builder/presentation/screens/contract_preview_screen.dart';
import '../../features/contract_builder/presentation/screens/template_editor_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/dashboard/presentation/widgets/dashboard_shell.dart';
import '../../features/invitations/presentation/screens/invitations_screen.dart';
import '../../features/jood_writer/presentation/screens/jood_writer_screen.dart';
import '../../features/project_hub/presentation/screens/new_project_screen.dart';
import '../../features/templates/presentation/screens/template_library_screen.dart';
import 'app_routes.dart';

/// موجّه التطبيق الوحيد.
///
/// الحماية هنا **إلزامية**: كل مسار غير مسموح يُعاد التوجيه إلى شاشة الدخول.
/// (حماية البيانات الفعلية تبقى في تخزين الجهاز نفسه — لا على الواجهة.)
abstract final class AppRouter {
  const AppRouter._();

  static GoRouter create(AuthProvider auth) {
    // مستودع واحد للمشاريع تُحقن فيه كل شاشات التحرير — وتنفيذه **محلي 100%**:
    // يكتب صفوفاً في جدول المشاريع المحلي ([ProjectsController]) بلا أي رفع إلى
    // سيرفر، ويعمل بلا إنترنت بالكامل. الشاشات لا تعرف إلا واجهة
    // `TemplateRepository`، فلم تحتج أي منها إلى تعديل.
    final TemplateRepository templateRepository = LocalProjectRepository();

    return GoRouter(
      initialLocation: AppRoutes.dashboard,
      // أي تغيّر في حالة الدخول يُعيد تقييم إعادة التوجيه فوراً.
      refreshListenable: auth,
      // **بوابة تسجيل الدخول إلزامية**: بلا مستخدم مُتحقَّق منه لا تُفتح أي شاشة
      // غير شاشتي الدخول/الإنشاء. المصادقة محلية بالكامل، ولا شبكة معنيّة.
      //
      // شرط `isServiceAvailable`: غياب مستودع مصادقة (تشغيل بلا حساب مُهيّأ
      // كحال اختبارات الودجات) يعني أن لا وسيلة لدخول، فلا بوابة — وإلا حبسنا
      // المستخدم في شاشة لا يمكن تجاوزها.
      redirect: (BuildContext context, GoRouterState state) {
        final String location = state.matchedLocation;
        final bool onAuthRoute = location == AppRoutes.login ||
            location == AppRoutes.register;

        if (!auth.isServiceAvailable) return null;

        // غير مسجّل ⇒ إلى الدخول. المسجّل على شاشة دخول/إنشاء ⇒ إلى اللوحة.
        if (!auth.isAuthenticated) {
          return onAuthRoute ? null : AppRoutes.login;
        }
        return onAuthRoute ? AppRoutes.dashboard : null;
      },
      routes: <RouteBase>[
        // ------------------------------ المصادقة ------------------------------
        GoRoute(
          path: AppRoutes.login,
          name: 'login',
          builder: (BuildContext context, GoRouterState state) =>
              const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.register,
          name: 'register',
          builder: (BuildContext context, GoRouterState state) =>
              const RegisterScreen(),
        ),

        // ------------- الوحدات (داخل هيكل الشريط العلوي) -------------
        //
        // `StatefulShellRoute.indexedStack` يُبقي كل قسم **حيّاً** في IndexedStack
        // بدل هدمه عند التنقّل، فلا يفقد المستخدم محرّراً مفتوحاً ولا جلسة توليد
        // جماعي ولا تعديلات غير محفوظة عند تبديل التبويبات. ترتيب الفروع مطابق
        // لترتيب `dashboardDestinations` (يُعتمد عليه في تبديل الفرع).
        StatefulShellRoute.indexedStack(
          builder: (
            BuildContext context,
            GoRouterState state,
            StatefulNavigationShell navigationShell,
          ) =>
              DashboardShell(navigationShell: navigationShell),
          branches: <StatefulShellBranch>[
            _branch('dashboard', <RouteBase>[
              GoRoute(
                path: AppRoutes.dashboard,
                name: 'dashboard',
                builder: (BuildContext context, GoRouterState state) =>
                    const DashboardScreen(),
              ),
            ]),
            // مسار «مشروع جديد» يبقى للروابط المباشرة فقط: مداخل التطبيق كلها
            // تفتح نافذة «مستند جديد» العائمة بلا تنقّل، وهذه الصفحة تفتحها
            // فور الوصول ثم تُعيد المستخدم إلى لوحة التحكم عند الإلغاء.
            _branch('new-project', <RouteBase>[
              GoRoute(
                path: AppRoutes.newProject,
                name: 'new-project',
                builder: (BuildContext context, GoRouterState state) =>
                    const NewProjectScreen(),
              ),
            ]),
            _branch('certificate-builder', <RouteBase>[
              GoRoute(
                path: AppRoutes.certificateBuilder,
                name: 'certificate-builder',
                builder: (BuildContext context, GoRouterState state) {
                  final TemplateRecord? record = _recordFromExtra(state.extra);
                  final TemplateDraft? draft = _draftFromExtra(state.extra);
                  // مفتاح الجلسة يثبّت المحرّر وبعمله ما دام القالب نفسه، ويُعيد
                  // بناءه عند فتح قالب آخر من المكتبة فلا يظهر القالب القديم.
                  return CertificateTemplateEditorScreen(
                    key: const ValueKey('certificate_workspace'),
                    repository: templateRepository,
                    record: record,
                    draft: draft,
                  );
                },
                routes: <RouteBase>[
                  GoRoute(
                    path: 'sample-preview',
                    name: 'certificate-sample-preview',
                    builder: (BuildContext context, GoRouterState state) =>
                        const CertificatePreviewScreen(),
                  ),
                ],
              ),
            ]),
            _branch('contract-builder', <RouteBase>[
              GoRoute(
                path: AppRoutes.contractBuilder,
                name: 'contract-builder',
                builder: (BuildContext context, GoRouterState state) {
                  final TemplateRecord? record = _recordFromExtra(state.extra);
                  final TemplateDraft? draft = _draftFromExtra(state.extra);
                  return ContractTemplateEditorScreen(
                    key: const ValueKey('contract_workspace'),
                    repository: templateRepository,
                    record: record,
                    draft: draft,
                  );
                },
                routes: <RouteBase>[
                  GoRoute(
                    path: 'sample-preview',
                    name: 'contract-sample-preview',
                    builder: (BuildContext context, GoRouterState state) =>
                        const ContractPreviewScreen(),
                  ),
                ],
              ),
            ]),
            _branch('batch-processor', <RouteBase>[
              GoRoute(
                path: AppRoutes.batchProcessor,
                name: 'batch-processor',
                builder: (BuildContext context, GoRouterState state) {
                  final TemplateRecord? record = _recordFromExtra(state.extra);
                  // جلسة التوليد (الملف المستورد وتصحيحات الأسماء/الجنس) تبقى
                  // حيّة؛ ولا تُبنى من جديد إلا عند استخدام قالب مختلف صراحةً.
                  // المخزن المحلي وحده مصدر القوالب هنا: تمرير المستودع أيضاً
                  // كان يعرض المشروع مرّتين (قائمة محلية + قائمة المستودع).
                  return BatchProcessorScreen(
                    key: _sessionKey('batch', record?.id, null),
                    localStore: ProjectsTemplateStore(
                      controller: ProjectsController.instance,
                    ),
                    record: record,
                  );
                },
              ),
            ]),
            _branch('templates', <RouteBase>[
              GoRoute(
                path: AppRoutes.templates,
                name: 'templates',
                // المكتبة محلية 100%: تقرأ جدول المشاريع المحلي مباشرةً، فلا
                // مستودع يُمرَّر (ومن يمرّره يرى كل مشروع مرتين).
                builder: (BuildContext context, GoRouterState state) =>
                    const TemplateLibraryScreen(),
              ),
            ]),
            _branch('assets', <RouteBase>[
              GoRoute(
                path: AppRoutes.assets,
                name: 'assets',
                builder: (BuildContext context, GoRouterState state) =>
                    const AssetsManagerScreen(),
              ),
            ]),
            _branch('brand', <RouteBase>[
              GoRoute(
                path: AppRoutes.brand,
                name: 'brand',
                builder: (BuildContext context, GoRouterState state) =>
                    const BrandSettingsScreen(),
              ),
            ]),
            // إدارة المديرين المحليين: الحسابات على هذا الجهاز، ونقلها المشفّر
            // بين أجهزة محلية، وسجل التصدير. ترتيب الفرع مطابق لترتيب
            // `dashboardDestinations` (وفي النهاية فلا تُزحزح فهارس الأقسام).
            _branch('admin-accounts', <RouteBase>[
              GoRoute(
                path: AppRoutes.admins,
                name: 'admin-accounts',
                builder: (BuildContext context, GoRouterState state) =>
                    const AdminAccountsScreen(),
              ),
            ]),
            // «جود كاتب»: مستندات وتقارير نصّية بتدفّق صفحات تلقائي. يُضاف فرعه
            // في النهاية مع نظيره في `dashboardDestinations` فلا تُزحزح
            // فهارس الأقسام القائمة.
            _branch('jood-writer', <RouteBase>[
              GoRoute(
                path: AppRoutes.joodWriter,
                name: 'jood-writer',
                builder: (BuildContext context, GoRouterState state) =>
                    const JoodWriterScreen(),
              ),
            ]),
            // الدعوات الشخصية: قالب واحد ← ملف أسماء ← ملف لكل مدعو. فرع جديد
            // في النهاية (كالسابق) فلا تُزحزح فهارس الأقسام القائمة.
            _branch('invitations', <RouteBase>[
              GoRoute(
                path: AppRoutes.invitations,
                name: 'invitations',
                builder: (BuildContext context, GoRouterState state) =>
                    const InvitationsScreen(),
              ),
            ]),
          ],
        ),

        // ------------------------- حول البرنامج -------------------------
        // **خارج** هيكل الفروع مقصود: صفحة معلومات تُفتح فوق القسم الحالي
        // (من قائمة «مساعدة») فتبقى حالة القسم حيّة، ولا تُزحزح إضافة هذا
        // المسار فهارس الفروع القائمة.
        GoRoute(
          path: AppRoutes.about,
          name: 'about',
          builder: (BuildContext context, GoRouterState state) =>
              const AboutScreen(),
        ),
      ],
      errorBuilder: (BuildContext context, GoRouterState state) =>
          _RouteNotFoundScreen(location: state.uri.toString()),
    );
  }

  /// فرع تنقّل واحد: مفتاح تنقّل ثابت + مساراته (بما فيها المسارات المتداخلة).
  static StatefulShellBranch _branch(String name, List<RouteBase> routes) =>
      StatefulShellBranch(
        navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'shell-branch-$name'),
        routes: routes,
      );

  /// مفتاح جلسة شاشة: يثبّت الحالة ما دام الكيان نفسه، ويُعيد بناء الشاشة عند
  /// الانتقال إلى كيان مختلف (قالب آخر) فلا يُعرض المحتوى القديم مكانه.
  static Key _sessionKey(String kind, String? id, String? fallback) =>
      ValueKey<String>('$kind:${id ?? fallback ?? 'new'}');

  /// يحوّل `extra` القادم من مكتبة القوالب إلى سجل قالب (أو `null`).
  ///
  /// نتحقّق من النوع بدل الاعتماد الأعمى حتى لا يُسقط تحديث الصفحة أو فتح
  /// المسار مباشرةً التطبيق عند غياب `extra`.
  static TemplateRecord? _recordFromExtra(Object? extra) =>
      extra is TemplateRecord ? extra : null;

  /// يحوّل `extra` إلى قالب غير محفوظ (قادم من المكتبة الجاهزة).
  static TemplateDraft? _draftFromExtra(Object? extra) =>
      extra is TemplateDraft ? extra : null;
}

/// شاشة مسار غير معروف.
class _RouteNotFoundScreen extends StatelessWidget {
  const _RouteNotFoundScreen({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.explore_off_rounded,
                    color: AppColors.gold,
                    size: 28,
                  ),
                  const SizedBox(height: AppTheme.space16),
                  Text(
                    context.l10n?.routeNotFoundTitle ?? 'الصفحة غير موجودة',
                    style: text.titleLarge,
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    context.l10n?.routeNotFoundBody ??
                        'المسار المطلوب غير معرّف في التطبيق:',
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: AppTheme.space8),
                  SelectableText(
                    location,
                    textDirection: TextDirection.ltr,
                    style: text.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space24),
                  FilledButton(
                    onPressed: () => context.go(AppRoutes.dashboard),
                    child: Text(
                      context.l10n?.actionBackToDashboard ??
                          'العودة إلى لوحة التحكم',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
