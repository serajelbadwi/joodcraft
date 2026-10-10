import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joodcraft/app/router/app_router.dart';
import 'package:joodcraft/app/router/app_routes.dart';
import 'package:joodcraft/core/assets/asset_store.dart';
import 'package:joodcraft/core/assets/assets_controller.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/widgets/template_editor_view.dart';
import 'package:joodcraft/core/locale/app_locale.dart';
import 'package:joodcraft/core/locale/locale_controller.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/projects/local_projects_database.dart';
import 'package:joodcraft/core/projects/projects_controller.dart';
import 'package:joodcraft/core/templates/template_record.dart';
import 'package:joodcraft/core/templates/unsaved_changes_guard.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/core/theme/theme_controller.dart';
import 'package:joodcraft/features/auth/presentation/providers/auth_provider.dart';
import 'package:joodcraft/features/batch_processor/presentation/screens/batch_processor_screen.dart';
import 'package:joodcraft/features/templates/presentation/screens/template_library_screen.dart';
import 'package:joodcraft/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_auth_repository.dart';

/// اختبارات الاحتفاظ بحالة العمل عند التنقّل بين أقسام التطبيق.
///
/// الجوهر: الأقسام تعيش في `StatefulShellRoute.indexedStack`، فتبقى كل جلسة
/// (محرّر قوالب، توليد جماعي) حيّةً عند تبديل التبويبات، ولا تُسأل عن عمل غير
/// محفوظ عند مجرّد الانتقال.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthRepository repository;
  late AuthProvider auth;
  late ThemeController themeController;
  late LocaleController localeController;
  late GoRouter router;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    AssetsController.instance = AssetsController(store: InMemoryAssetStore());
    // قاعدة المشاريع المحلية في الذاكرة: في اختبارات الودجات لا يوجد منفّذ
    // منصّة لـ path_provider، فتخزين القرص الحقيقي يترك مؤقّتات معلّقة.
    ProjectsController.instance = ProjectsController(
      database: InMemoryProjectsDatabase(),
    );
    repository = FakeAuthRepository();
    auth = AuthProvider(repository);
    await auth.signIn(email: 'user@joodcraft.dev', password: 'secret');
    themeController = ThemeController();
    localeController = LocaleController();
    router = AppRouter.create(auth);
  });

  tearDown(() {
    router.dispose();
    auth.dispose();
    themeController.dispose();
    localeController.dispose();
    repository.close();
    ProjectsController.instance.dispose();
    ProjectsController.instance = ProjectsController();
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    Size size = const Size(1600, 900),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeController>.value(value: themeController),
          ChangeNotifierProvider<LocaleController>.value(
            value: localeController,
          ),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('ar'),
          supportedLocales: AppLocales.locales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// ينقر تبويباً في الشريط العلوي (لا بطاقة في اللوحة) ثم يستقرّ.
  ///
  /// يُستهدف بمفتاح ثابت لا بالنص، لأن التسمية قد تُخفى في العرض الضيّق وتظهر
  /// في تلميح فقط.
  Future<void> tapTab(WidgetTester tester, String path) async {
    await tester.tap(find.byKey(ValueKey<String>('top-tab-$path')));
    await tester.pumpAndSettle();
  }

  /// سجل قالب بسيط بمعرّف وعنوان — لفتح المحرّر مباشرةً من الموجّه.
  TemplateRecord record(String id, String title) => TemplateRecord(
        id: id,
        userId: 'u-1',
        title: title,
        category: TemplateCategory.certificate,
        orientation: PageOrientation.landscape,
        layoutData: TemplateDocument(
          orientation: PageOrientation.landscape,
          elements: const <TemplateElement>[
            TextElement(
              id: 'text-1',
              box: ElementBox(x: 100, y: 100, width: 400, height: 60),
              text: '{{اسم_المتدرب}}',
            ),
          ],
        ).toJson(),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

  testWidgets('التبديل بين الأقسام يحافظ على جلسة التوليد الجماعي',
      (WidgetTester tester) async {
    await pumpApp(tester);

    await tapTab(tester, AppRoutes.batchProcessor);
    expect(find.text('التوليد الجماعي من Excel'), findsOneWidget);
    final State<StatefulWidget> first =
        tester.state(find.byType(BatchProcessorScreen));

    // نغادر إلى قسم آخر: الشاشة تُخفى في الـ IndexedStack لا تُهدم.
    await tapTab(tester, AppRoutes.templates);
    expect(find.text('التوليد الجماعي من Excel'), findsNothing);

    await tapTab(tester, AppRoutes.batchProcessor);
    expect(find.text('التوليد الجماعي من Excel'), findsOneWidget);
    final State<StatefulWidget> second =
        tester.state(find.byType(BatchProcessorScreen));

    // الحالة نفسها (والملف المستورد والتصحيحات داخلها) لم تُهدم.
    expect(identical(first, second), isTrue);
  });

  testWidgets('تعديلات غير محفوظة لا تُعطّل التنقّل بين الأقسام',
      (WidgetTester tester) async {
    await pumpApp(tester);

    // حارس "يرفض" المغادرة كما يفعل محرّر القوالب عند وجود تعديلات غير محفوظة.
    Future<bool> refuse() async => false;
    UnsavedChangesGuard.instance.register(refuse);
    addTearDown(() => UnsavedChangesGuard.instance.unregister(refuse));

    await tapTab(tester, AppRoutes.batchProcessor);
    expect(find.text('التوليد الجماعي من Excel'), findsOneWidget);

    // التنقّل يمرّ رغم رفض الحارس — لا سؤال عند تبديل الأقسام.
    await tapTab(tester, AppRoutes.templates);
    expect(find.text('التوليد الجماعي من Excel'), findsNothing);
    expect(find.byType(TemplateLibraryScreen), findsOneWidget);
  });

  testWidgets('التبديل بين الأقسام يحافظ على محرّر القوالب',
      (WidgetTester tester) async {
    await pumpApp(tester);

    await tapTab(tester, AppRoutes.certificateBuilder);
    expect(find.byType(TemplateEditorView), findsOneWidget);
    final State<StatefulWidget> first =
        tester.state(find.byType(TemplateEditorView));

    await tapTab(tester, AppRoutes.templates);
    await tapTab(tester, AppRoutes.certificateBuilder);
    expect(find.byType(TemplateEditorView), findsOneWidget);
    final State<StatefulWidget> second =
        tester.state(find.byType(TemplateEditorView));

    expect(identical(first, second), isTrue);
  });

  testWidgets('فتح قالب مختلف يُعيد بناء المحرّر (لا محتوى قديم)',
      (WidgetTester tester) async {
    await pumpApp(tester);

    router.go(AppRoutes.certificateBuilder, extra: record('a', 'قالب أ'));
    await tester.pumpAndSettle();
    final State<StatefulWidget> before =
        tester.state(find.byType(TemplateEditorView));

    // قالب آخر من المكتبة ← يجب أن يُبنى المحرّر من جديد لا أن يُعرض القديم.
    router.go(AppRoutes.certificateBuilder, extra: record('b', 'قالب ب'));
    await tester.pumpAndSettle();
    final State<StatefulWidget> after =
        tester.state(find.byType(TemplateEditorView));

    expect(identical(before, after), isFalse);
    expect(find.text('قالب ب'), findsWidgets);
  });
}
