import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joodcraft/app/router/app_routes.dart';
import 'package:joodcraft/core/locale/app_locale.dart';
import 'package:joodcraft/core/locale/locale_controller.dart';
import 'package:joodcraft/core/templates/local_template_store.dart';
import 'package:joodcraft/core/templates/template_draft.dart';
import 'package:joodcraft/core/templates/template_record.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/core/theme/theme_controller.dart';
import 'package:joodcraft/features/auth/presentation/providers/auth_provider.dart';
import 'package:joodcraft/features/dashboard/presentation/widgets/top_nav_bar.dart';
import 'package:joodcraft/features/templates/presentation/screens/template_library_screen.dart';
import 'package:joodcraft/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_auth_repository.dart';
import '../support/fake_template_repository.dart';

/// نقل قائمة قوالب الدعوات إلى **مكتبة القوالب**:
///
/// 1. قسم «قوالب الدعوات» يجمع القوالب السبعة (لا تبقى أقسام رمضان/عيد/زفاف
///    منفصلة كما كانت تعرض داخل شاشة العرض القديمة).
/// 2. الضغط على قالب دعوة يفتح `/invitations` (محرك الدعوات = المحرّر) بمسوّدة
///    ذلك القالب.
/// 3. بند «قوالب الدعوات» في قائمة «المكتبات ▾» يفتح المكتبة.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeTemplateRepository repository;
  late InMemoryLocalTemplateStore store;

  const String templatesRoute = '/templates';
  const String invitationsRoute = '/invitations';

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    repository = FakeTemplateRepository();
    store = InMemoryLocalTemplateStore();
  });

  /// وصف `extra` كما تراه شاشة المحرّك (مسوّدة من المكتبة).
  String describeExtra(Object? extra) {
    if (extra is TemplateDraft) return 'مسودة-${extra.title}';
    if (extra is TemplateRecord) return 'سجل-${extra.id}';
    return 'بلا-قالب';
  }

  Future<GoRouter> pumpLibrary(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final GoRouter router = GoRouter(
      initialLocation: templatesRoute,
      routes: <RouteBase>[
        GoRoute(
          path: templatesRoute,
          builder: (BuildContext context, GoRouterState state) => Scaffold(
            body: TemplateLibraryScreen(
              repository: repository,
              localStore: store,
              // نفس سلوك الموجّه: `?section=invitations` يفتح القسم موسّعاً.
              initialSection: state.uri.queryParameters['section'],
            ),
          ),
        ),
        GoRoute(
          path: invitationsRoute,
          builder: (BuildContext context, GoRouterState state) => Scaffold(
            body: Text('محرر دعوات:${describeExtra(state.extra)}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        locale: const Locale('ar'),
        supportedLocales: AppLocales.locales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Finder card(String id) => find.byKey(ValueKey<String>('library-entry-$id'));

  Future<void> expandAll(WidgetTester tester) async {
    await tester.tap(find.byTooltip('توسيع الكل'));
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  // --------------------------------------------------------------------------
  //                     1) قسم «قوالب الدعوات» في المكتبة
  // --------------------------------------------------------------------------
  group('قسم قوالب الدعوات', () {
    testWidgets('قسم واحد يجمع القوالب السبعة ولا تبقى أقسام رمضان/عيد/زفاف منفصلة',
        (WidgetTester tester) async {
      await pumpLibrary(tester);

      // القسم موجود بعنوانه ومفتاحه، ولم تبقَ ثلاثة أقسام منفصلة مكانه.
      expect(
        find.byKey(const ValueKey<String>('library-section-invitations')),
        findsOneWidget,
        reason: 'قسم «قوالب الدعوات» مفقود.',
      );
      expect(find.text('قوالب الدعوات'), findsOneWidget);
      for (final String collection in <String>['ramadan', 'eid', 'wedding']) {
        expect(
          find.byKey(ValueKey<String>('library-section-collection:$collection')),
          findsNothing,
          reason: 'القسم المنفصل يجب أن يكون مدموجاً: collection:$collection',
        );
      }

      // بعد التوسعة: القوالب السبعة كاملة داخل القسم.
      await expandAll(tester);
      for (final String id in <String>[
        'inv_ramadan_classic',
        'inv_ramadan_story',
        'inv_eid_classic',
        'inv_eid_story',
        'inv_wedding_classic',
        'inv_wedding_modern',
        'inv_wedding_story',
      ]) {
        expect(
          card('preset:$id'),
          findsOneWidget,
          reason: 'بطاقة القالب مفقودة من القسم: $id',
        );
      }
    });
  });

  // --------------------------------------------------------------------------
  //              2) الضغط على قالب دعوة → /invitations بمسوّدته
  // --------------------------------------------------------------------------
  group('فتح قالب دعوة من المكتبة', () {
    testWidgets('ينتقل إلى /invitations بمسوّدة ذلك القالب',
        (WidgetTester tester) async {
      await pumpLibrary(tester);
      await expandAll(tester);

      await tapVisible(
        tester,
        find.descendant(
          of: card('preset:inv_wedding_classic'),
          matching: find.text('فتح كقالب'),
        ),
      );

      // المسار المستقبِل هو محرك الدعوات بمسوّدة «زفاف كلاسيكي».
      expect(
        find.text('محرر دعوات:مسودة-زفاف كلاسيكي'),
        findsOneWidget,
        reason: 'القالب يجب أن يُفتح في /invitations كمسوّدة.',
      );
    });
  });

  // --------------------------------------------------------------------------
  //                 3) بند القائمة «المكتبات ▾»
  // --------------------------------------------------------------------------
  group('قائمة المكتبات', () {
    testWidgets('تحمل بنداً «قوالب الدعوات» يفتح مكتبة القوالب',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      String? navigatedTo;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(
              value: AuthProvider(FakeAuthRepository()),
            ),
            ChangeNotifierProvider<ThemeController>.value(
              value: ThemeController(),
            ),
            ChangeNotifierProvider<LocaleController>.value(
              value: LocaleController(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('ar'),
            supportedLocales: AppLocales.locales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: TopNavBar(
                currentPath: AppRoutes.dashboard,
                onNavigate: (String path) => navigatedTo = path,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey<String>('top-menu-libraries')));
      await tester.pumpAndSettle();

      expect(find.text('قوالب الدعوات'), findsOneWidget);

      await tester.tap(find.text('قوالب الدعوات'));
      await tester.pumpAndSettle();
      expect(navigatedTo, '${AppRoutes.templates}?section=invitations');
    });

    testWidgets('المسار بوسم section=invitations يفتح المكتبة على القسم موسّعاً',
        (WidgetTester tester) async {
      final GoRouter router = await pumpLibrary(tester);

      router.go('$templatesRoute?section=invitations');
      await tester.pumpAndSettle();

      // القسم موسّع بلا ضغط «توسيع الكل»: بطاقاته ظاهرة مباشرةً.
      expect(
        find.byKey(const ValueKey<String>('library-section-invitations')),
        findsOneWidget,
      );
      expect(
        card('preset:inv_ramadan_classic'),
        findsOneWidget,
        reason: 'بوسم القسم يجب أن تظهر البطاقة موسّعة فور الدخول.',
      );
    });
  });
}
