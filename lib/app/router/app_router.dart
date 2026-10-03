import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/supabase_service.dart';
import '../../core/templates/local_template_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/templates/template_draft.dart';
import '../../core/templates/template_record.dart';
import '../../core/templates/template_repository.dart';
import '../../features/assets_manager/presentation/screens/assets_manager_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/batch_processor/presentation/screens/batch_processor_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/certificate_builder/presentation/screens/certificate_preview_screen.dart';
import '../../features/certificate_builder/presentation/screens/template_editor_screen.dart';
import '../../features/contract_builder/presentation/screens/contract_preview_screen.dart';
import '../../features/contract_builder/presentation/screens/template_editor_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/dashboard/presentation/widgets/dashboard_shell.dart';
import '../../features/templates/data/supabase_template_repository.dart';
import '../../features/templates/presentation/screens/template_library_screen.dart';
import 'app_routes.dart';

/// موجّه التطبيق الوحيد.
///
/// الحماية هنا **إلزامية**: أي مسار غير مسموح يُعاد التوجيه إلى شاشة الدخول.
/// (حماية البيانات الفعلية تبقى على RLS في قاعدة البيانات — لا على الواجهة.)
abstract final class AppRouter {
  const AppRouter._();

  static GoRouter create(AuthProvider auth) {
    // مستودع واحد للقوالب تُحقن فيه كل شاشات التحرير — يعتمد على واجهة
    // `TemplateRepository`، فلا تعرف الشاشات أن التنفيذ على Supabase.
    final TemplateRepository? templateRepository = SupabaseService.isInitialized
        ? SupabaseTemplateRepository(SupabaseService.client)
        : null;

    return GoRouter(
      initialLocation: AppRoutes.dashboard,
      // أي تغيّر في حالة الدخول يُعيد تقييم إعادة التوجيه فوراً.
      refreshListenable: auth,
      redirect: (BuildContext context, GoRouterState state) {
        final bool loggedIn = auth.isAuthenticated;
        final String location = state.matchedLocation;
        final bool onAuthRoute = location == AppRoutes.login ||
            location == AppRoutes.register;

        if (!loggedIn) return onAuthRoute ? null : AppRoutes.login;
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

        // ------------- الوحدات (داخل هيكل اللوحة الجانبية) -------------
        ShellRoute(
          builder: (BuildContext context, GoRouterState state, Widget child) =>
              DashboardShell(child: child),
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.dashboard,
              name: 'dashboard',
              builder: (BuildContext context, GoRouterState state) =>
                  const DashboardScreen(),
            ),
            GoRoute(
              path: AppRoutes.certificateBuilder,
              name: 'certificate-builder',
              builder: (BuildContext context, GoRouterState state) =>
                  CertificateTemplateEditorScreen(
                repository: templateRepository,
                record: _recordFromExtra(state.extra),
                draft: _draftFromExtra(state.extra),
              ),
              routes: <RouteBase>[
                GoRoute(
                  path: 'sample-preview',
                  name: 'certificate-sample-preview',
                  builder: (BuildContext context, GoRouterState state) =>
                      const CertificatePreviewScreen(),
                ),
              ],
            ),
            GoRoute(
              path: AppRoutes.contractBuilder,
              name: 'contract-builder',
              builder: (BuildContext context, GoRouterState state) =>
                  ContractTemplateEditorScreen(
                repository: templateRepository,
                record: _recordFromExtra(state.extra),
                draft: _draftFromExtra(state.extra),
              ),
              routes: <RouteBase>[
                GoRoute(
                  path: 'sample-preview',
                  name: 'contract-sample-preview',
                  builder: (BuildContext context, GoRouterState state) =>
                      const ContractPreviewScreen(),
                ),
              ],
            ),
            GoRoute(
              path: AppRoutes.batchProcessor,
              name: 'batch-processor',
              builder: (BuildContext context, GoRouterState state) =>
                  BatchProcessorScreen(
                repository: templateRepository,
                localStore: SharedPreferencesLocalTemplateStore(),
                record: _recordFromExtra(state.extra),
              ),
            ),
            GoRoute(
              path: AppRoutes.templates,
              name: 'templates',
              builder: (BuildContext context, GoRouterState state) =>
                  TemplateLibraryScreen(repository: templateRepository),
            ),
            GoRoute(
              path: AppRoutes.assets,
              name: 'assets',
              builder: (BuildContext context, GoRouterState state) =>
                  const AssetsManagerScreen(),
            ),
          ],
        ),
      ],
      errorBuilder: (BuildContext context, GoRouterState state) =>
          _RouteNotFoundScreen(location: state.uri.toString()),
    );
  }

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
                  Text('الصفحة غير موجودة', style: text.titleLarge),
                  const SizedBox(height: AppTheme.space8),
                  Text('المسار المطلوب غير معرّف في التطبيق:',
                      style: text.bodyMedium),
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
                    child: const Text('العودة إلى لوحة التحكم'),
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
