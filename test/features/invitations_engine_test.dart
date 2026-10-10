import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/app/router/app_routes.dart';
import 'package:joodcraft/core/locale/app_locale.dart';
import 'package:joodcraft/core/locale/locale_controller.dart';
import 'package:joodcraft/core/services/pdf_generator_service.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/core/theme/theme_controller.dart';
import 'package:joodcraft/features/auth/presentation/providers/auth_provider.dart';
import 'package:joodcraft/features/dashboard/presentation/widgets/top_nav_bar.dart';
import 'package:joodcraft/features/invitations/data/invitation_output_writer.dart';
import 'package:joodcraft/features/invitations/domain/invitation_export_service.dart';
import 'package:joodcraft/features/invitations/presentation/providers/invitations_controller.dart';
import 'package:joodcraft/features/invitations/presentation/screens/invitations_screen.dart';
import 'package:joodcraft/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_auth_repository.dart';

/// اختبارات توحيد الدعوات في «محرك الدعوات»:
///
/// 1. القائمة المنسدلة «المحرّكات» تحمل بنداً واحداً نظيفاً للدعوات (اسم فقط
///    بلا وصف) بدل البنود الثلاثة المكرّرة (رمضان/عيد/زفاف).
/// 2. الضغط عليه ينقل إلى `/invitations`.
/// 3. صفحة المحرّك تعرض الفئات الثلاث «داخلياً» والقوالب السبعة وإعدادات
///    التصدير (PNG/PDF/Both + ZIP + CSV).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PdfGeneratorService generator;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    generator = await PdfGeneratorService.create(useIsolate: false);
  });

  InvitationsController buildController() {
    return InvitationsController(
      generator: generator,
      service: InvitationExportService(
        generator: generator,
        rasterizer: (Uint8List bytes, int dpi) async =>
            Uint8List.fromList(<int>[0x89, 0x50, 0x4E, 0x47]),
      ),
      writer: _FakeWriter(),
    );
  }

  // --------------------------------------------------------------------------
  //                        القائمة المنسدلة «المحرّكات»
  // --------------------------------------------------------------------------
  group('قائمة المحرّكات', () {
    testWidgets('«محرك الدعوات» بند واحد نظيف بلا وصف، ولا أثر لرمضان/عيد/زفاف',
        (WidgetTester tester) async {
      String? navigatedTo;
      await tester.pumpWidget(_menuHarness(
        onNavigate: (String path) => navigatedTo = path,
      ));
      await tester.pump();

      // افتح قائمة «المحرّكات».
      await tester.tap(find.byKey(const ValueKey<String>('top-menu-editors')));
      await tester.pumpAndSettle();

      // بند الدعوات موجود باسمه وحده (لا يوجد وصف في بنية TopNavMenuEntry).
      expect(find.text('محرك الدعوات'), findsOneWidget);

      // ولا وجود لبنود رمضان/عيد/زفاف المكرّرة التي كانت تُعرض سابقاً.
      for (final String removed in <String>[
        'دعوات رمضان',
        'دعوات العيد',
        'دعوات الزفاف',
      ]) {
        expect(find.text(removed), findsNothing, reason: 'لا يجب أن يظهر: $removed');
      }

      // البنود المحفوظة كما هي.
      expect(find.text('محـرّك الشهادات'), findsOneWidget);
      expect(find.text('محـرّك العقود'), findsOneWidget);
      expect(find.text('جود كاتب'), findsOneWidget);

      // الضغط على «محرك الدعوات» ينقل إلى مسار الدعوات.
      await tester.tap(find.text('محرك الدعوات'));
      await tester.pumpAndSettle();
      expect(navigatedTo, AppRoutes.invitations);
    });
  });

  // --------------------------------------------------------------------------
  //                          صفحة «محرك الدعوات»
  // --------------------------------------------------------------------------
  group('صفحة محرك الدعوات', () {
    testWidgets('تعرض الفئات الثلاث والقوالب السبعة وإعدادات التصدير',
        (WidgetTester tester) async {
      final InvitationsController controller = buildController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppLocales.locales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: InvitationsScreen(controller: controller),
          ),
        ),
      );
      await tester.pump();

      // الفئات الثلاث الداخلية ظاهرة (كمصفّحات داخل الصفحة لا في الشريط).
      for (final String category in <String>['رمضان', 'عيد', 'زفاف']) {
        expect(find.text(category), findsWidgets,
            reason: 'الفئة الداخلية مفقودة: $category');
      }

      // كل قوالب المجموعات الثلاث معروضة على الشبكة (7 بطاقات).
      for (final String title in <String>[
        'رمضان كريم — كلاسيكي',
        'رمضان كريم — Story',
        'عيد مبارك — كلاسيكي',
        'عيد مبارك — Story',
        'زفاف كلاسيكي',
        'زفاف حديث',
        'زفاف Story',
      ]) {
        expect(find.text(title), findsOneWidget,
            reason: 'القالب مفقود من الشبكة: $title');
      }

      // اختيار قالب يُظهر المحرّر (المعاينة + نص الرسالة) وإعدادات التصدير.
      final Finder weddingCard = find.text('زفاف كلاسيكي');
      await tester.ensureVisible(weddingCard);
      await tester.pumpAndSettle();
      await tester.tap(weddingCard);
      await tester.pump();
      expect(controller.template?.id, 'inv_wedding_classic');
      await tester.scrollUntilVisible(
        find.text('نص الرسالة (قابل للتعديل)'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('نص الرسالة (قابل للتعديل)'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('ضغط في ملف ZIP'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      // إعدادات التصدير: الصيغ الثلاث + ZIP + الفهرس.
      expect(find.text('ضغط في ملف ZIP'), findsOneWidget);
      expect(find.text('إنشاء فهرس CSV'), findsOneWidget);
      expect(find.textContaining('PNG (للسوشيال ميديا)'), findsOneWidget);
      expect(find.text('PDF (للطباعة)'), findsOneWidget);
    });

    testWidgets('المجموعات تُصفّي القوالب المعروضة',
        (WidgetTester tester) async {
      final InvitationsController controller = buildController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppLocales.locales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: InvitationsScreen(controller: controller),
          ),
        ),
      );
      await tester.pump();

      // اختيار مجموعة رمضان يُظهر قالبَيها فقط.
      await tester.tap(find.widgetWithText(ChoiceChip, 'رمضان').first);
      await tester.pump();
      expect(controller.groupFilter?.name, 'ramadan');
      expect(find.text('رمضان كريم — كلاسيكي'), findsOneWidget);
      expect(find.text('رمضان كريم — Story'), findsOneWidget);
      expect(find.text('زفاف كلاسيكي'), findsNothing);

      // واختيار الزفاف يُظهر قوالبه الثلاثة.
      await tester.tap(find.widgetWithText(ChoiceChip, 'زفاف').first);
      await tester.pump();
      expect(controller.groupFilter?.name, 'wedding');
      expect(find.text('زفاف كلاسيكي'), findsOneWidget);
      expect(find.text('زفاف حديث'), findsOneWidget);
      expect(find.text('زفاف Story'), findsOneWidget);
      expect(find.text('رمضان كريم — كلاسيكي'), findsNothing);
    });
  });
}

/// حاضنة الشريط العلوي: توفّر المزوّدين المطلوبين (Auth/Theme/Locale) وتلتقط
/// مسار التنقّل الناتج عن الضغط على بنود القائمة المنسدلة.
Widget _menuHarness({required ValueChanged<String> onNavigate}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(
        value: AuthProvider(FakeAuthRepository()),
      ),
      ChangeNotifierProvider<ThemeController>.value(value: ThemeController()),
      ChangeNotifierProvider<LocaleController>.value(value: LocaleController()),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('ar'),
      supportedLocales: AppLocales.locales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: TopNavBar(
          currentPath: AppRoutes.dashboard,
          onNavigate: onNavigate,
        ),
      ),
    ),
  );
}

/// كاتب مخرجات وهمي: لا يلمس القرص.
class _FakeWriter implements InvitationOutputWriter {
  @override
  Future<String?> defaultDirectory() async => r'C:\temp';

  @override
  Future<String?> pickDirectory({String? dialogTitle}) async => r'C:\temp';

  @override
  Future<String?> saveFiles({
    required String directory,
    required List<InvitationOutputFile> files,
  }) async =>
      directory;

  @override
  Future<String?> saveBytes({
    required String directory,
    required String fileName,
    required Uint8List bytes,
  }) async =>
      '$directory/$fileName';

  @override
  Future<bool> openDirectory(String directory) async => true;
}
