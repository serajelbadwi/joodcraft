import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joodcraft/core/locale/locale_controller.dart';
import 'package:joodcraft/core/templates/local_template_store.dart';
import 'package:joodcraft/core/templates/template_draft.dart';
import 'package:joodcraft/core/templates/template_record.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/features/templates/presentation/screens/template_library_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_template_repository.dart';

/// **محتوى القوالب بلغة البلد**: عندما تكون لغة التطبيق فرنسية، يعرض مدخل
/// القوالب عنواناً فرنسياً، وفتحه يمرّر مسودة بمحتوى فرنسي فعلي (أسماء وصيغ
/// البلد) إلى المحرّر — لا مجرد واجهة فرنسية حول نصّ عربي.
void main() {
  late FakeTemplateRepository repository;
  late InMemoryLocalTemplateStore store;

  const String templatesRoute = '/templates';
  const String certificateRoute = '/certificate-builder';

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    repository = FakeTemplateRepository();
    store = InMemoryLocalTemplateStore();
  });

  String describeExtra(Object? extra) {
    if (extra is TemplateDraft) return 'مسودة-${extra.title}';
    if (extra is TemplateRecord) return 'سجل-${extra.id}';
    return 'بلا-قالب';
  }

  Finder card(String id) => find.byKey(ValueKey<String>('library-entry-$id'));

  Future<void> pumpLibrary(WidgetTester tester, String languageCode) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final LocaleController locale = LocaleController();
    addTearDown(locale.dispose);
    await locale.setLocale(Locale(languageCode));

    final GoRouter router = GoRouter(
      initialLocation: templatesRoute,
      routes: <RouteBase>[
        GoRoute(
          path: templatesRoute,
          builder: (BuildContext context, GoRouterState state) =>
              Scaffold(body: TemplateLibraryScreen(repository: repository, localStore: store)),
        ),
        GoRoute(
          path: certificateRoute,
          builder: (BuildContext context, GoRouterState state) =>
              Scaffold(body: Text('محرر شهادة:${describeExtra(state.extra)}')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<LocaleController>.value(
        value: locale,
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    // الأقسام مطويّة افتراضياً.
    await tester.tap(find.byTooltip('توسيع الكل'));
    await tester.pumpAndSettle();
  }

  testWidgets('لغة فرنسية: العنوان فرنسي والفتح ينقل مسودة فرنسية',
      (WidgetTester tester) async {
    await pumpLibrary(tester, 'fr');

    // عنوان القالب الجاهز بلغة البلد.
    expect(
      find.descendant(
        of: card('preset:appreciation_certificate'),
        matching: find.text('Certificat de reconnaissance'),
      ),
      findsOneWidget,
    );

    // وفتحه يمرّر مسودةً بمحتوى فرنسي (لا العربية).
    final Finder open = find.descendant(
      of: card('preset:appreciation_certificate'),
      matching: find.text('فتح كقالب'),
    );
    await tester.ensureVisible(open);
    await tester.pumpAndSettle();
    await tester.tap(open);
    await tester.pumpAndSettle();

    expect(
      find.text('محرر شهادة:مسودة-Certificat de reconnaissance'),
      findsOneWidget,
    );
  });

  testWidgets('بلا محرّك لغة: يبقى المحتوى عربياً كما هو (لا تراجع)',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final GoRouter router = GoRouter(
      initialLocation: templatesRoute,
      routes: <RouteBase>[
        GoRoute(
          path: templatesRoute,
          builder: (BuildContext context, GoRouterState state) =>
              Scaffold(body: TemplateLibraryScreen(repository: repository, localStore: store)),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('توسيع الكل'));
    await tester.pumpAndSettle();

    expect(find.text('شهادة شكر وتقدير'), findsOneWidget);
  });
}
