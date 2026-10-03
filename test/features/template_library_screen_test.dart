import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/errors/app_error_code.dart';
import 'package:joodcraft/core/templates/local_template_store.dart';
import 'package:joodcraft/core/templates/preset_template.dart';
import 'package:joodcraft/core/templates/template_draft.dart';
import 'package:joodcraft/core/templates/template_record.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/features/templates/presentation/screens/template_library_screen.dart';

import '../support/fake_template_repository.dart';

/// اختبارات مكتبة القوالب (المرحلة 5): القوالب الجاهزة أوفلاين، الاستيراد
/// المحلي، الحذف، والتكامل مع المحرّرين ومحرّك التوليد الجماعي.
void main() {
  late FakeTemplateRepository repository;
  late InMemoryLocalTemplateStore store;

  const String templatesRoute = '/templates';
  const String certificateRoute = '/certificate-builder';
  const String contractRoute = '/contract-builder';
  const String batchRoute = '/batch-processor';

  setUp(() {
    repository = FakeTemplateRepository();
    store = InMemoryLocalTemplateStore();
  });

  TemplateRecord cloudRecord({
    String id = 'cloud-1',
    String title = 'قالب سحابي',
    TemplateCategory category = TemplateCategory.certificate,
  }) {
    return TemplateRecord(
      id: id,
      userId: 'user-1',
      title: title,
      category: category,
      orientation: category.defaultOrientation,
      layoutData: <String, dynamic>{'schema_version': 1},
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 3, 15),
    );
  }

  /// وصف `extra` كما تراه الشاشة المستهدفة (سجل أم مسودة).
  String describeExtra(Object? extra) {
    if (extra is TemplateDraft) return 'مسودة-${extra.title}';
    if (extra is TemplateRecord) return 'سجل-${extra.id}';
    return 'بلا-قالب';
  }

  Future<void> pumpLibrary(WidgetTester tester) async {
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
            ),
          ),
        ),
        GoRoute(
          path: certificateRoute,
          builder: (BuildContext context, GoRouterState state) =>
              Scaffold(body: Text('محرر شهادة:${describeExtra(state.extra)}')),
        ),
        GoRoute(
          path: contractRoute,
          builder: (BuildContext context, GoRouterState state) =>
              Scaffold(body: Text('محرر عقد:${describeExtra(state.extra)}')),
        ),
        GoRoute(
          path: batchRoute,
          builder: (BuildContext context, GoRouterState state) {
            final Object? extra = state.extra;
            final String id = extra is TemplateRecord ? extra.id : '';
            return Scaffold(body: Text('توليد:$id'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
  }

  Finder card(String id) => find.byKey(ValueKey<String>('library-entry-$id'));

  testWidgets('بلا سحابة تعرض القوالب الجاهزة وتعمل أوفلاين',
      (WidgetTester tester) async {
    await pumpLibrary(tester);

    expect(
      find.descendant(
        of: card('preset:appreciation_certificate'),
        matching: find.text('شهادة شكر وتقدير'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card('preset:employment_contract'),
        matching: find.text('عقد عمل'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card('preset:experience_declaration'),
        matching: find.text('إفادة خبرة'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('متاح أوفلاين'), findsWidgets);
    // لا رسالة تمنع المكتبة بلا اتصال.
    expect(find.text('المكتبة تتطلب الاتصال'), findsNothing);
  });

  testWidgets('فشل السحابة لا يحجب الجاهز ويعرض ملاحظة',
      (WidgetTester tester) async {
    repository.failWith = AppErrorCode.network;
    await pumpLibrary(tester);

    expect(find.text('شهادة شكر وتقدير'), findsOneWidget);
    expect(find.textContaining('تعذّر تحميل القوالب السحابية'), findsOneWidget);
  });

  testWidgets('البحث يُصفّي القوالب الجاهزة', (WidgetTester tester) async {
    await pumpLibrary(tester);

    await tester.enterText(find.byType(TextField).first, 'عقد');
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: card('preset:employment_contract'),
        matching: find.text('عقد عمل'),
      ),
      findsOneWidget,
    );
    expect(find.text('شهادة شكر وتقدير'), findsNothing);
  });

  testWidgets('تصفية المصدر تُظهر المحلي فقط (ولا نتائج قبل الاستيراد)',
      (WidgetTester tester) async {
    await pumpLibrary(tester);

    await tester.tap(find.byType(DropdownButton<TemplateSource?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('محلي').last);
    await tester.pumpAndSettle();

    expect(find.text('شهادة شكر وتقدير'), findsNothing);
    expect(find.text('لا نتائج مطابقة'), findsOneWidget);
  });

  testWidgets('استيراد قالب جاهز محلياً يظهر في المكتبة ويُحفظ في المخزن',
      (WidgetTester tester) async {
    await pumpLibrary(tester);

    await tester.tap(
      find.descendant(
        of: card('preset:appreciation_certificate'),
        matching: find.byIcon(Icons.more_vert_rounded),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('استيراد محلياً'));
    await tester.pumpAndSettle();

    expect(store.records.length, 1);
    expect(card(store.records.single.id), findsOneWidget);
    expect(find.text('محلي'), findsWidgets);
  });

  testWidgets('حذف قالب محلي يطلب تأكيداً ثم يُزيله',
      (WidgetTester tester) async {
    await pumpLibrary(tester);

    // استيراد أولاً.
    await tester.tap(
      find.descendant(
        of: card('preset:appreciation_certificate'),
        matching: find.byIcon(Icons.more_vert_rounded),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('استيراد محلياً'));
    await tester.pumpAndSettle();

    final String localId = store.records.single.id;
    await tester.tap(
      find.descendant(
        of: card(localId),
        matching: find.byIcon(Icons.more_vert_rounded),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف محلياً'));
    await tester.pumpAndSettle();

    expect(find.text('حذف القالب'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'حذف'));
    await tester.pumpAndSettle();

    expect(store.records, isEmpty);
    expect(card(localId), findsNothing);
  });

  testWidgets('فتح قالب جاهز ينقل إلى محرّر الشهادات كمسودة',
      (WidgetTester tester) async {
    await pumpLibrary(tester);

    await tester.tap(
      find.descendant(
        of: card('preset:appreciation_certificate'),
        matching: find.text('فتح كقالب'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('محرر شهادة:مسودة-شهادة شكر وتقدير'),
      findsOneWidget,
    );
  });

  testWidgets('فتح عقد جاهز ينقل إلى محرّر العقود', (WidgetTester tester) async {
    await pumpLibrary(tester);

    await tester.tap(
      find.descendant(
        of: card('preset:employment_contract'),
        matching: find.text('فتح كقالب'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('محرر عقد:مسودة-عقد عمل'), findsOneWidget);
  });

  testWidgets('فتح قالب سحابي ينقل إلى المحرّر مع السجل',
      (WidgetTester tester) async {
    repository.records.add(cloudRecord());
    await pumpLibrary(tester);

    await tester.tap(
      find.descendant(of: card('cloud-1'), matching: find.text('فتح')),
    );
    await tester.pumpAndSettle();

    expect(find.text('محرر شهادة:سجل-cloud-1'), findsOneWidget);
  });

  testWidgets('استخدام القالب في التوليد الجماعي ينقل مع السجل',
      (WidgetTester tester) async {
    await pumpLibrary(tester);

    await tester.tap(
      find.descendant(
        of: card('preset:service_contract'),
        matching: find.byIcon(Icons.more_vert_rounded),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('استخدام في التوليد الجماعي'));
    await tester.pumpAndSettle();

    expect(find.text('توليد:preset:service_contract'), findsOneWidget);
  });
}
