import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/errors/app_error_code.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/templates/local_template_store.dart';
import 'package:joodcraft/core/templates/preset_catalog.dart';
import 'package:joodcraft/core/templates/preset_template.dart';
import 'package:joodcraft/core/templates/template_draft.dart';
import 'package:joodcraft/core/templates/template_record.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/features/templates/presentation/screens/template_library_screen.dart';
import 'package:joodcraft/features/templates/presentation/widgets/template_thumbnail.dart';

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

  Future<void> pumpLibrary(
    WidgetTester tester, {
    Future<void> Function(List<TemplateDocument> documents)? warmImageCache,
  }) async {
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
              warmImageCache: warmImageCache,
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

  testWidgets('فتح المكتبة يسخّن ذاكرة صور مستندات القوالب',
      (WidgetTester tester) async {
    // قالب محلي يشير إلى أصل من المكتبة: معاينته لا بدّ أن تُسخَّن عند الفتح.
    store = InMemoryLocalTemplateStore(<TemplateRecord>[
      TemplateRecord(
        id: 'local_with_frame',
        userId: 'local',
        title: 'قالب بإطار',
        category: TemplateCategory.certificate,
        orientation: PageOrientation.portrait,
        layoutData: TemplateDocument(
          elements: <TemplateElement>[
            const ImageElement(
              id: 'frame',
              box: ElementBox(x: 0, y: 0, width: 400, height: 300),
              sourceKind: ImageSourceKind.userAsset,
              path: 'asset_thumb',
              fit: ImageFit.fill,
            ),
          ],
        ).toJson(),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 3, 15),
      ),
    ]);

    final List<TemplateDocument> warmed = <TemplateDocument>[];
    await pumpLibrary(
      tester,
      warmImageCache: (List<TemplateDocument> documents) async {
        warmed.addAll(documents);
      },
    );

    // سُخِّنت مستندات كل القوالب بعد التحميل — لا عند أول رسم لمعاينة.
    expect(warmed, isNotEmpty);
    expect(warmed.length, greaterThan(1));
    expect(
      warmed.any(
        (TemplateDocument document) => document.elements.any(
          (TemplateElement element) =>
              element is ImageElement && element.path == 'asset_thumb',
        ),
      ),
      isTrue,
      reason: 'مستند القالب المحلي (ومراجع أصوله) يجب أن يصل إلى التسخين.',
    );
  });


  /// ينقل البطاقة إلى داخل العرض ثم ينقر الهدف (بعض البطاقات تقع أسفل
  /// حدود نافذة الاختبار فيفشل النقر بلا تمرير).
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// يفتح كل أقسام الأكورديون (الافتراضي: كلها مطويّة عند فتح المكتبة).
  Future<void> expandAll(WidgetTester tester) async {
    await tester.tap(find.byTooltip('توسيع الكل'));
    await tester.pumpAndSettle();
  }

  testWidgets('بلا سحابة تعرض القوالب الجاهزة وتعمل أوفلاين',
      (WidgetTester tester) async {
    await pumpLibrary(tester);
    await expandAll(tester);

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
    await expandAll(tester);

    expect(find.text('شهادة شكر وتقدير'), findsOneWidget);
    expect(find.textContaining('تعذّر تحميل القوالب السحابية'), findsOneWidget);
  });

  testWidgets('البحث يُصفّي القوالب الجاهزة', (WidgetTester tester) async {
    await pumpLibrary(tester);
    await expandAll(tester);

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
    await expandAll(tester);

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
    await expandAll(tester);

    await tapVisible(
      tester,
      find.descendant(
        of: card('preset:appreciation_certificate'),
        matching: find.byIcon(Icons.more_vert_rounded),
      ),
    );
    await tester.tap(find.text('استيراد محلياً'));
    await tester.pumpAndSettle();

    // القالب المستورد يظهر في قسم "قوالبي المحفوظة" — نفتحه بعد الاستيراد.
    await expandAll(tester);

    expect(store.records.length, 1);
    expect(card(store.records.single.id), findsOneWidget);
    expect(find.text('محلي'), findsWidgets);
  });

  testWidgets('حذف قالب محلي يطلب تأكيداً ثم يُزيله',
      (WidgetTester tester) async {
    await pumpLibrary(tester);
    await expandAll(tester);

    // استيراد أولاً.
    await tapVisible(
      tester,
      find.descendant(
        of: card('preset:appreciation_certificate'),
        matching: find.byIcon(Icons.more_vert_rounded),
      ),
    );
    await tester.tap(find.text('استيراد محلياً'));
    await tester.pumpAndSettle();

    // القالب المستورد يظهر في قسم "قوالبي المحفوظة" — نفتحه بعد الاستيراد.
    await expandAll(tester);

    final String localId = store.records.single.id;
    await tapVisible(
      tester,
      find.descendant(
        of: card(localId),
        matching: find.byIcon(Icons.more_vert_rounded),
      ),
    );
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
    await expandAll(tester);

    await tapVisible(
      tester,
      find.descendant(
        of: card('preset:appreciation_certificate'),
        matching: find.text('فتح كقالب'),
      ),
    );

    expect(
      find.text('محرر شهادة:مسودة-شهادة شكر وتقدير'),
      findsOneWidget,
    );
  });

  testWidgets('فتح عقد جاهز ينقل إلى محرّر العقود', (WidgetTester tester) async {
    await pumpLibrary(tester);
    await expandAll(tester);

    await tapVisible(
      tester,
      find.descendant(
        of: card('preset:employment_contract'),
        matching: find.text('فتح كقالب'),
      ),
    );

    expect(find.text('محرر عقد:مسودة-عقد عمل'), findsOneWidget);
  });

  testWidgets('فتح قالب سحابي ينقل إلى المحرّر مع السجل',
      (WidgetTester tester) async {
    repository.records.add(cloudRecord());
    await pumpLibrary(tester);
    await expandAll(tester);

    await tapVisible(
      tester,
      find.descendant(of: card('cloud-1'), matching: find.text('فتح')),
    );

    expect(find.text('محرر شهادة:سجل-cloud-1'), findsOneWidget);
  });

  testWidgets('استخدام القالب في التوليد الجماعي ينقل مع السجل',
      (WidgetTester tester) async {
    await pumpLibrary(tester);
    await expandAll(tester);

    await tapVisible(
      tester,
      find.descendant(
        of: card('preset:service_contract'),
        matching: find.byIcon(Icons.more_vert_rounded),
      ),
    );
    await tester.tap(find.text('استخدام في التوليد الجماعي'));
    await tester.pumpAndSettle();

    expect(find.text('توليد:preset:service_contract'), findsOneWidget);
  });

  // ========================================================================
  //  إعادة تصميم المكتبة: أكورديون الأقسام + الصور المصغّرة
  // ========================================================================

  Finder section(String key) =>
      find.byKey(ValueKey<String>('library-section-$key'));

  Finder sectionHeader(String key) =>
      find.byKey(ValueKey<String>('library-section-header-$key'));

  testWidgets('الأقسام مطويّة افتراضياً وتُفتح بالنقر على البانر',
      (WidgetTester tester) async {
    await pumpLibrary(tester);

    // كل بانرات التصنيفات ظاهرة، وكل البطاقات مخفيّة افتراضياً.
    expect(section('collection:appreciation'), findsOneWidget);
    expect(section('collection:completion'), findsOneWidget);
    expect(section('contracts'), findsOneWidget);
    expect(card('preset:appreciation_certificate'), findsNothing);
    expect(card('preset:employment_contract'), findsNothing);

    // البانر يحمل اسم التصنيف + سهم الفتح.
    final Finder header = sectionHeader('collection:appreciation');
    expect(
      find.descendant(of: header, matching: find.text('شهادات تقدير')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: header,
        matching: find.byIcon(Icons.expand_more_rounded),
      ),
      findsOneWidget,
    );

    // النقر على البانر يفتح القسم، والنقر ثانيةً يطويه.
    await tapVisible(tester, header);
    expect(card('preset:appreciation_certificate'), findsOneWidget);
    await tapVisible(tester, sectionHeader('collection:appreciation'));
    expect(card('preset:appreciation_certificate'), findsNothing);
  });

  testWidgets('القسم الموسّع له منطقة تمرير داخلية بذراع تمرير مرئي',
      (WidgetTester tester) async {
    await pumpLibrary(tester);
    await expandAll(tester);

    final Finder drawer = find.descendant(
      of: section('collection:appreciation'),
      matching: find.byType(Scrollbar),
    );
    expect(drawer, findsOneWidget);
    expect(
      find.descendant(
        of: drawer,
        matching: find.byType(SingleChildScrollView),
      ),
      findsOneWidget,
    );

    // ارتفاع القسم محدود، فلا يمدّ المحتوى الصفحة بلا نهاية.
    final double height =
        tester.getSize(section('collection:appreciation')).height;
    expect(height, lessThan(700));
  });

  testWidgets('أزرار طي الكل/توسيع الكل تعمل على كل الأقسام',
      (WidgetTester tester) async {
    await pumpLibrary(tester);

    expect(card('preset:appreciation_certificate'), findsNothing);

    await tester.tap(find.byTooltip('توسيع الكل'));
    await tester.pumpAndSettle();
    expect(card('preset:appreciation_certificate'), findsOneWidget);
    expect(card('preset:employment_contract'), findsOneWidget);

    await tester.tap(find.byTooltip('طي الكل'));
    await tester.pumpAndSettle();
    expect(card('preset:appreciation_certificate'), findsNothing);
    expect(card('preset:employment_contract'), findsNothing);
  });

  testWidgets('كل بطاقة تعرض صورة مصغّرة متجهية للقالب',
      (WidgetTester tester) async {
    await pumpLibrary(tester);
    await expandAll(tester);

    expect(
      find.descendant(
        of: card('preset:appreciation_certificate'),
        matching: find.byType(TemplateThumbnail),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card('preset:employment_contract'),
        matching: find.byType(TemplateThumbnail),
      ),
      findsOneWidget,
    );
  });

  testWidgets('تفضيل قالب يفعّل زر النجمة في بطاقته',
      (WidgetTester tester) async {
    await pumpLibrary(tester);
    await expandAll(tester);

    final Finder star = find.descendant(
      of: card('preset:experience_declaration'),
      matching: find.byTooltip('تفضيل'),
    );
    expect(star, findsOneWidget);

    await tapVisible(tester, star);

    expect(
      find.descendant(
        of: card('preset:experience_declaration'),
        matching: find.byTooltip('إزالة التفضيل'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('تصفية الاتجاه تُخفي القوالب ذات الاتجاه المعاكس',
      (WidgetTester tester) async {
    await pumpLibrary(tester);
    await expandAll(tester);

    final PresetTemplate preset =
        PresetCatalog.byId('appreciation_certificate')!;
    final PageOrientation opposite = preset.document.isLandscape
        ? PageOrientation.portrait
        : PageOrientation.landscape;

    await tester.tap(find.byType(DropdownButton<PageOrientation?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(opposite.labelAr).last);
    await tester.pumpAndSettle();

    expect(card('preset:appreciation_certificate'), findsNothing);
  });
}
