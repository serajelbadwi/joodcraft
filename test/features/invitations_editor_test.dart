import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joodcraft/app/router/app_router.dart';
import 'package:joodcraft/app/router/app_routes.dart';
import 'package:joodcraft/core/assets/asset_store.dart';
import 'package:joodcraft/core/assets/assets_controller.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/locale/app_locale.dart';
import 'package:joodcraft/core/locale/locale_controller.dart';
import 'package:joodcraft/core/projects/local_projects_database.dart';
import 'package:joodcraft/core/projects/projects_controller.dart';
import 'package:joodcraft/core/templates/invitation_gallery.dart';
import 'package:joodcraft/core/templates/template_draft.dart';
import 'package:joodcraft/core/templates/template_record.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/core/theme/theme_controller.dart';
import 'package:joodcraft/features/auth/presentation/providers/auth_provider.dart';
import 'package:joodcraft/features/certificate_builder/presentation/screens/template_editor_screen.dart';
import 'package:joodcraft/features/invitations/presentation/screens/invitations_editor_screen.dart';
import 'package:joodcraft/features/invitations/presentation/screens/invitations_screen.dart';
import 'package:joodcraft/features/invitations/presentation/widgets/invitation_picker_panel.dart';
import 'package:joodcraft/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_auth_repository.dart';

/// «محرك الدعوات» = محرّر الشهادات والعقود نفسه **بعرضه كاملاً**.
///
/// 1. مسار `/invitations` يفتح **نفس** المحرّر
///    (`CertificateTemplateEditorScreen`) ولا يستدعي شاشة العرض القديمة.
/// 2. **لا لوحة جانبية**: `InvitationPickerPanel` أُزيلت لأنها كانت مكرِّرة
///    (القوالب تُفتح من المكتبة) وكانت تقتطع 268px من عرض المحرّر.
/// 3. القوالب تُفتح من **المكتبة**: مسوّدة أو سجل أو قالب دعوة ممرَّر — كلٌّ
///    يُفتح تبويباً في المحرّر، وإعادة فتحه لا تكرّر التبويب.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthRepository repository;
  late AuthProvider auth;
  late GoRouter router;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    AssetsController.instance = AssetsController(store: InMemoryAssetStore());
    ProjectsController.instance = ProjectsController(
      database: InMemoryProjectsDatabase(),
    );
    repository = FakeAuthRepository();
    auth = AuthProvider(repository);
    await auth.signIn(email: 'user@joodcraft.dev', password: 'secret');
    router = AppRouter.create(auth);
  });

  tearDown(() {
    router.dispose();
    auth.dispose();
    repository.close();
    ProjectsController.instance.dispose();
    ProjectsController.instance = ProjectsController();
  });

  /// حاضنة المحرّك عبر **الموجّه الحقيقي** (نفس مسار المستخدم الفعلي).
  Future<void> pumpRouter(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final ThemeController theme = ThemeController();
    final LocaleController locale = LocaleController();
    addTearDown(() {
      theme.dispose();
      locale.dispose();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeController>.value(value: theme),
          ChangeNotifierProvider<LocaleController>.value(value: locale),
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

  /// ضخّ مباشر للشاشة (بلا موجّه) لاختبار عرض المحرّر وفتح مكتبة القوالب.
  Future<void> pumpEditor(
    WidgetTester tester, {
    TemplateDraft? draft,
    TemplateRecord? record,
    InvitationTemplate? invitation,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('ar'),
        supportedLocales: AppLocales.locales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: InvitationsEditorScreen(
              draft: draft,
              record: record,
              invitation: invitation,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  TemplateRecord savedRecord() => TemplateRecord(
        id: 'saved-invitation-1',
        userId: 'user-1',
        title: 'قالب دعوة محفوظ',
        category: TemplateCategory.certificate,
        orientation: PageOrientation.portrait,
        layoutData: <String, dynamic>{'schema_version': 1},
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 3, 15),
      );

  // --------------------------------------------------------------------------
  //                     1) المسار: محرّر موحّد لا شاشة عرض
  // --------------------------------------------------------------------------
  group('مسار /invitations عبر الموجّه الحقيقي', () {
    testWidgets(
        'يفتح CertificateTemplateEditorScreen بلا لوحة اختيار ولا شاشة عرض',
        (WidgetTester tester) async {
      await pumpRouter(tester);
      router.go(AppRoutes.invitations);
      await tester.pumpAndSettle();

      // المحرّر الكامل نفسه المستخدم في محركي الشهادات والعقود.
      expect(
        find.byType(CertificateTemplateEditorScreen),
        findsOneWidget,
        reason: 'محرك الدعوات يجب أن يكون TemplateEditorScreen نفسه.',
      );
      // لا لوحة جانبية — القوالب تُفتح من المكتبة.
      expect(
        find.byType(InvitationPickerPanel),
        findsNothing,
        reason: 'لوحة اختيار القوالب أُزيلت من محرك الدعوات.',
      );
      expect(
        find.byType(InvitationsScreen),
        findsNothing,
        reason: 'شاشة العرض القديمة لا تُستدعى من المسار بعد التوحيد.',
      );

      // يفتح على محتوى (أول قالب جاهز) لا على فراغ.
      expect(
        find.text('رمضان كريم — كلاسيكي'),
        findsWidgets,
        reason: 'التبويب الأول يحمل عنوان أول قالب دعوة جاهز.',
      );
    });
  });

  // --------------------------------------------------------------------------
  //               2) لا لوحة جانبية: المحرّر يأخذ العرض كاملاً
  // --------------------------------------------------------------------------
  group('غياب اللوحة الجانبية', () {
    testWidgets('InvitationPickerPanel غير مبنية إطلاقاً',
        (WidgetTester tester) async {
      await pumpEditor(tester);

      expect(
        find.byType(InvitationPickerPanel),
        findsNothing,
        reason: 'اللوحة لم تُعرض بعد إزالتها.',
      );
      // عناوين اللوحة القديمة (مجموعاتها الثلاث) لا تظهر كتسميات أقسام.
      expect(find.text('قوالب الدعوات'), findsNothing);
    });

    testWidgets('المحرّر يملأ المساحة كاملة بلا عمود جانبي مقتطع',
        (WidgetTester tester) async {
      await pumpEditor(tester);

      final Size editor = tester.getSize(
        find.byType(CertificateTemplateEditorScreen),
      );
      // عرض السطح 1400؛ اللوحة القديمة كانت تأخذ 268 + فاصل = 269px.
      expect(
        editor.width,
        greaterThan(1300),
        reason: 'المحرّر يجب أن يأخذ العرض كاملاً بعد إزالة اللوحة '
            '(سابقاً كان ~1131px).',
      );
    });

    testWidgets('المحرّر يبقى معقول الارتفاع (لا فقدان تخطيط)',
        (WidgetTester tester) async {
      await pumpEditor(tester);

      final Size editor = tester.getSize(
        find.byType(CertificateTemplateEditorScreen),
      );
      expect(editor.height, greaterThan(400));
      expect(tester.takeException(), isNull);
    });
  });

  // --------------------------------------------------------------------------
  //                    3) القوالب تُفتح من المكتبة
  // --------------------------------------------------------------------------
  group('فتح القوالب من المكتبة', () {
    testWidgets('مسوّدة المكتبة تُفتح كالتبويب الأول', (
      WidgetTester tester,
    ) async {
      final TemplateDraft libraryDraft =
          InvitationTemplates.all[3].toPreset().toDraft(); // عيد مبارك — Story
      await pumpEditor(tester, draft: libraryDraft);

      expect(
        find.text('عيد مبارك — Story'),
        findsWidgets,
        reason: 'مسوّدة المكتبة تُفتح مباشرة في المحرّر.',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('سجل محفوظ يُفتح كتبويب أول', (WidgetTester tester) async {
      await pumpEditor(tester, record: savedRecord());

      expect(
        find.text('قالب دعوة محفوظ'),
        findsWidgets,
        reason: 'السجل الممرَّر من المكتبة يُفتح كما هو.',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('قالب دعوة ممرَّر من المكتبة يُفتح مباشرةً',
        (WidgetTester tester) async {
      await pumpEditor(
        tester,
        invitation: InvitationTemplates.all[4], // زفاف كلاسيكي
      );

      expect(
        find.text('زفاف كلاسيكي'),
        findsWidgets,
        reason: 'القالب المختار من المكتبة يُفتح في المحرّر.',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('إعادة فتح نفس القالب لا تكرّر التبويب',
        (WidgetTester tester) async {
      final InvitationTemplate template = InvitationTemplates.all[6];
      await pumpEditor(tester, invitation: template);
      final int before = find.text(template.titleAr).evaluate().length;
      expect(before, greaterThan(0));

      // ضخّ ثانٍ بنفس القالب (نفس مفتاح الجلسة) ⇒ لا تبويب مكرّر.
      await pumpEditor(tester, invitation: template);

      expect(
        find.text(template.titleAr).evaluate().length,
        before,
        reason: 'إعادة فتح القالب نفسه لا تكرّر تبويبه.',
      );
      expect(tester.takeException(), isNull);
    });
  });
}
