import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/assets/asset_store.dart';
import 'package:joodcraft/core/assets/assets_controller.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/locale/app_locale.dart';
import 'package:joodcraft/core/locale/locale_controller.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/projects/local_projects_database.dart';
import 'package:joodcraft/core/projects/projects_controller.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/core/theme/theme_controller.dart';
import 'package:joodcraft/features/auth/presentation/providers/auth_provider.dart';
import 'package:joodcraft/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:joodcraft/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// بطاقة «المشاريع الأخيرة» في لوحة التحكم: مصدرها **قاعدة المشاريع المحلية**
/// مباشرةً، وتُقرأ من الذاكرة فتَظهر فوراً بلا شاشة تحميل.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProjectsController projects;
  late LocaleController locale;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    AssetsController.instance = AssetsController(store: InMemoryAssetStore());
    locale = LocaleController();
    await locale.load();
    projects = ProjectsController(database: InMemoryProjectsDatabase());
  });

  tearDown(() {
    projects.dispose();
    locale.dispose();
  });

  Future<void> pumpDashboard(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: AuthProvider(null)),
          ChangeNotifierProvider<LocaleController>.value(value: locale),
          ChangeNotifierProvider<ThemeController>.value(
            value: ThemeController(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ar'),
          supportedLocales: AppLocales.locales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: DashboardScreen(projects: projects)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('يعرض أحدث المشاريع المحفوظة بالاسم والمقاس',
      (WidgetTester tester) async {
    await projects.save(
      title: 'شهادة التميّز',
      document: const TemplateDocument(
        orientation: PageOrientation.landscape,
        elements: <TemplateElement>[],
      ),
      category: TemplateCategory.certificate,
    );
    await projects.save(
      title: 'عقد العمل',
      document: const TemplateDocument(
        orientation: PageOrientation.portrait,
        elements: <TemplateElement>[],
      ),
      category: TemplateCategory.contract,
      now: DateTime(2026, 5, 1),
    );

    await pumpDashboard(tester);

    expect(find.text('المشاريع الأخيرة'), findsOneWidget);
    expect(find.text('عقد العمل'), findsOneWidget);
    expect(find.text('شهادة التميّز'), findsOneWidget);
    // المقاس بالمليمتر (A4 عرضي ≈ 297 × 210 ملم).
    expect(find.textContaining('mm'), findsNWidgets(2));
    // ولا رسالة «لا مشاريع» بعد وجود مشاريع.
    expect(find.textContaining('لا توجد مشاريع محفوظة'), findsNothing);
  });

  testWidgets('حالة الفراغ تعرض دعوة لإنشاء مستند جديد',
      (WidgetTester tester) async {
    await pumpDashboard(tester);

    expect(find.textContaining('لا توجد مشاريع محفوظة'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('dash-recent-new-project')),
      findsOneWidget,
    );
  });

  testWidgets('تُحدَّث البطاقة وحدها عند حفظ مشروع جديد',
      (WidgetTester tester) async {
    await pumpDashboard(tester);
    expect(find.textContaining('لا توجد مشاريع محفوظة'), findsOneWidget);

    await projects.save(
      title: 'شهادة الفصل الأول',
      document: const TemplateDocument(
        orientation: PageOrientation.portrait,
        elements: <TemplateElement>[],
      ),
      category: TemplateCategory.certificate,
    );
    await tester.pumpAndSettle();

    expect(find.text('شهادة الفصل الأول'), findsOneWidget);
    expect(find.textContaining('لا توجد مشاريع محفوظة'), findsNothing);
  });
}
