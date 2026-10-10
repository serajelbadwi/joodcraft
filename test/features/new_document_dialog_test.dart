import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/widgets/editor_controls.dart';
import 'package:joodcraft/core/locale/app_locale.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/templates/project_preset.dart';
import 'package:joodcraft/core/templates/template_draft.dart';
import 'package:joodcraft/core/theme/app_colors.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/features/project_hub/presentation/dialogs/new_document_dialog.dart';
import 'package:joodcraft/features/project_hub/presentation/providers/new_document_controller.dart';
import 'package:joodcraft/features/project_hub/presentation/widgets/photoshop_paper_icon.dart';
import 'package:joodcraft/l10n/generated/app_localizations.dart';

/// اختبارات نافذة «مستند جديد» العائمة.
///
/// نتحقّق من ثلاثة مستويات معاً، لأن الخلل يقع بينها عادةً:
/// 1. **خيمة النافذة**: مقاس ثابت **800×550**، سطح داكن `#232323` وحدّ `#333333`
///    وستارة `0xCC000000` — حتى فوق مظهر فاتح.
/// 2. **الاختيار**: بطاقة واحدة لكل مقاس، المرشّحات، والبحث، والأحدث.
/// 3. **ما يعود فعلاً**: المسودة التي تُسلَّم عند «إنشاء» (الاتجاه والأبعاد
///    بالنقاط والوحدة والدقّة ونمط اللون ولون الخلفية).
void main() {
  /// حصيلة فتح النافذة (تصل بعد إغلاقها).
  late List<TemplateDraft?> results;

  String describe(TemplateDraft? draft) {
    if (draft == null) return 'بلا-مسودة';
    final TemplateDocument document = draft.document;
    final CustomPageSize? custom = document.customPageSize;
    return '${draft.title}|${document.orientation.name}|'
        '${document.pageWidthPt.toStringAsFixed(2)}x'
        '${document.pageHeightPt.toStringAsFixed(2)}|'
        '${custom?.unit.jsonValue ?? document.paperSize.jsonValue}|'
        'dpi${document.dpi}|${document.colorMode.jsonValue}|'
        '${document.backgroundHex}';
  }

  /// يبني شاشة مضيفة (لوحة تحكم مصغّرة) فيها زرّ يفتح النافذة.
  Future<void> pumpHost(
    WidgetTester tester, {
    Size surface = const Size(1280, 900),
    NewDocumentScope? scope,
    ProjectPresetGroup? group,
    TemplateCategory? category,
  }) async {
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        // **مظهر فاتح عن قصد**: النافذة يجب أن تبقى داكنة بذاتها.
        theme: AppTheme.light,
        locale: const Locale('ar'),
        supportedLocales: AppLocales.locales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => Center(
              child: FilledButton(
                key: const ValueKey<String>('host-open'),
                onPressed: () async {
                  final TemplateDraft? draft = await showNewDocumentDialog(
                    context,
                    initialScope: scope,
                    initialGroup: group,
                    initialCategory: category,
                  );
                  results.add(draft);
                },
                child: const Text('فتح النافذة'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('host-open')));
    await tester.pumpAndSettle();
  }

  Finder byKey(String key) => find.byKey(ValueKey<String>(key));

  Finder familyCard(String id) =>
      byKey(NewDocumentKeys.family(id));

  /// يختار مقاساً من الشبكة.
  Future<void> selectFamily(WidgetTester tester, String id) async {
    final Finder card = familyCard(id);
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();
  }

  /// يضغط قرصاً بعد التأكد من ظهوره (سطر الأقراص قابل للتمرير أفقياً).
  Future<void> tapPill(WidgetTester tester, Finder pill) async {
    await tester.ensureVisible(pill);
    await tester.pumpAndSettle();
    await tester.tap(pill);
    await tester.pumpAndSettle();
  }

  Future<void> tapCreate(WidgetTester tester) async {
    await tester.tap(byKey(NewDocumentKeys.createButton));
    await tester.pumpAndSettle();
  }

  Future<void> typeNumber(
    WidgetTester tester,
    String key,
    String value,
  ) async {
    await tester.enterText(
      find.descendant(of: byKey(key), matching: find.byType(TextField)),
      value,
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
  }

  double numberValue(WidgetTester tester, String key) =>
      tester.widget<NumberField>(byKey(key)).value;

  T dropdownValue<T>(WidgetTester tester, String key) =>
      tester.widget<DropdownField<T>>(byKey(key)).value;

  Color windowColor(WidgetTester tester) {
    final Container container = tester.widget<Container>(
      byKey(NewDocumentKeys.window),
    );
    return (container.decoration! as BoxDecoration).color!;
  }

  Color backdropColor(WidgetTester tester) {
    final Container container = tester.widget<Container>(
      find.descendant(
        of: byKey(NewDocumentKeys.backdrop),
        matching: find.byType(Container),
      ),
    );
    return container.color!;
  }

  setUp(() {
    results = <TemplateDraft?>[];
    NewDocumentController.debugClearRecent();
  });

  // ==========================================================================
  //  خيمة النافذة
  // ==========================================================================
  group('خيمة النافذة العائمة', () {
    testWidgets('نافذة بمقاس ثابت وسطح داكن فوق مظهر فاتح',
        (WidgetTester tester) async {
      await pumpHost(tester);

      expect(byKey(NewDocumentKeys.window), findsOneWidget);
      final Size size = tester.getSize(byKey(NewDocumentKeys.window));
      expect(size.width, lessThanOrEqualTo(NewDocumentDialog.windowWidth));
      expect(size.height, lessThanOrEqualTo(NewDocumentDialog.windowHeight));
      expect(size.width, NewDocumentDialog.windowWidth,
          reason: 'على شاشة 1280 تُفتح بالعرض الثابت 800');
      expect(size.height, NewDocumentDialog.windowHeight);

      expect(windowColor(tester), AppColors.dialogSurface);
      expect(backdropColor(tester), AppColors.dialogBackdrop);
      expect(find.text('مستند جديد'), findsWidgets);
      expect(byKey(NewDocumentKeys.closeButton), findsOneWidget);
      // شريط الإجراءات صار جزءاً من اللوحة: «إنشاء/إلغاء» ظاهران من أول لحظة
      // (كانا يختفيان قبل اختيار مقاس لأن الشريط كان داخل محتوى التفاصيل).
      expect(byKey(NewDocumentKeys.createButton), findsOneWidget);
      expect(byKey(NewDocumentKeys.cancelButton), findsOneWidget);
      // واللوحة معبّأة مسبقاً بمواصفة افتراضية (لا نص فارغ) مع سطر يوضّح ذلك.
      expect(byKey(NewDocumentKeys.detailsHint), findsOneWidget);
      expect(numberValue(tester, NewDocumentKeys.widthField), 21);
      expect(numberValue(tester, NewDocumentKeys.heightField), 29.7);
      expect(
        dropdownValue<MeasurementUnit>(tester, NewDocumentKeys.unitField),
        MeasurementUnit.cm,
      );
      expect(numberValue(tester, NewDocumentKeys.dpiField), 300);
    });

    testWidgets('زر الإغلاق يُغلق بلا إنشاء', (WidgetTester tester) async {
      await pumpHost(tester);
      await tester.tap(byKey(NewDocumentKeys.closeButton));
      await tester.pumpAndSettle();

      expect(byKey(NewDocumentKeys.window), findsNothing);
      expect(results, <TemplateDraft?>[null]);
    });

    testWidgets('مفتاح Escape يُغلق ومفتاح الخلفية يُلغي',
        (WidgetTester tester) async {
      await pumpHost(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(byKey(NewDocumentKeys.window), findsNothing);
      expect(results, <TemplateDraft?>[null]);

      await tester.tap(find.byKey(const ValueKey<String>('host-open')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(8, 8)); // النقر على الستارة
      await tester.pumpAndSettle();
      expect(results.length, 2);
      expect(results.last, isNull);
    });

    testWidgets('«إلغاء» يُغلق ويعيد null', (WidgetTester tester) async {
      await pumpHost(tester);
      await selectFamily(tester, 'card.business');
      await tester.tap(byKey(NewDocumentKeys.cancelButton));
      await tester.pumpAndSettle();

      expect(byKey(NewDocumentKeys.window), findsNothing);
      expect(results.single, isNull);
    });

    testWidgets('تصغر النافذة على الشاشات الصغيرة بلا فيض',
        (WidgetTester tester) async {
      await pumpHost(tester, surface: const Size(700, 520));
      final Size size = tester.getSize(byKey(NewDocumentKeys.window));
      expect(size.width, lessThan(NewDocumentDialog.windowWidth));
      expect(size.height, lessThan(NewDocumentDialog.windowHeight));
      expect(size.width, lessThanOrEqualTo(700 - 48));

      // وعلى الضيق تُكدَّس لوحة التفاصيل تحت الشبكة ويكتمل الإنشاء.
      await selectFamily(tester, 'card.business');
      await tapCreate(tester);
      expect(results.single, isNotNull);
    });
  });

  // ==========================================================================
  //  الشبكة: عائلة واحدة لكل مقاس
  // ==========================================================================
  group('الشبكة والتبويبات', () {
    testWidgets('تبويبات النطاق الأربعة ظاهرة', (WidgetTester tester) async {
      await pumpHost(tester);
      for (final NewDocumentScope scope in NewDocumentScope.values) {
        expect(byKey(NewDocumentKeys.tab(scope)), findsOneWidget,
            reason: scope.jsonValue);
      }
    });

    testWidgets('المطبوعات المفردة: بطاقة واحدة لكل مقاس بلا تكرار للاتجاه',
        (WidgetTester tester) async {
      await pumpHost(tester);

      expect(familyCard('doc.a4.landscape'), findsOneWidget);
      expect(familyCard('doc.a4.portrait'), findsNothing,
          reason: 'لا بطاقة ثانية للاتجاه الآخر');
      for (final String id in <String>[
        'card.business',
        'card.id-badge',
        'seat.a6',
        'greeting.dl',
      ]) {
        expect(familyCard(id), findsOneWidget, reason: id);
      }
      // المقاسات الرقمية انتقلت إلى نطاقها الخاص.
      expect(familyCard('greeting.story'), findsNothing);
      expect(find.text('29.7 × 21 سم'), findsOneWidget);
      // «مقاس مخصّص» صار قرصاً لا بطاقة في الشبكة.
      expect(byKey(NewDocumentKeys.filterCustom), findsOneWidget);
      expect(byKey(NewDocumentKeys.customTile), findsNothing);
    });

    testWidgets('نطاق المنشورات يعرض منشوراته وحدها', (WidgetTester tester) async {
      await pumpHost(tester);
      await tester.tap(byKey(NewDocumentKeys.tab(NewDocumentScope.multiPage)));
      await tester.pumpAndSettle();

      expect(familyCard('pub.book.a5'), findsOneWidget);
      expect(familyCard('pub.book.a4'), findsOneWidget);
      expect(familyCard('pub.magazine.a4'), findsNothing,
          reason: 'كتاب/مجلة/تقرير A4 عائلة واحدة');
      expect(familyCard('doc.a4.landscape'), findsNothing);
      expect(byKey(NewDocumentKeys.filterCustom), findsNothing,
          reason: 'المقاس المخصّص للمطبوعات المفردة');
    });

    testWidgets('نطاق الشاشات والمعايدات يجمع المقاسات الرقمية',
        (WidgetTester tester) async {
      await pumpHost(tester);
      await tester.tap(byKey(NewDocumentKeys.tab(NewDocumentScope.social)));
      await tester.pumpAndSettle();

      expect(familyCard('greeting.story'), findsOneWidget);
      expect(familyCard('greeting.square'), findsOneWidget);
      expect(familyCard('doc.a4.landscape'), findsNothing);
      expect(familyCard('pub.book.a5'), findsNothing);
    });

    testWidgets('نطاق «الأحدث» فارغ قبل أي إنشاء', (WidgetTester tester) async {
      await pumpHost(tester);
      await tester.tap(byKey(NewDocumentKeys.tab(NewDocumentScope.recent)));
      await tester.pumpAndSettle();

      expect(find.textContaining('لا مقاسات أخيرة'), findsOneWidget);
      expect(familyCard('doc.a4.landscape'), findsNothing);
    });

    testWidgets('المرشّحات والبحث يضيّقان الشبكة', (WidgetTester tester) async {
      await pumpHost(tester);

      await tapPill(
        tester,
        byKey(NewDocumentKeys.groupFilter(
            ProjectPresetGroup.seatNumbersAndTags)),
      );
      expect(familyCard('seat.a6'), findsOneWidget);
      expect(familyCard('doc.a4.landscape'), findsNothing);

      await tapPill(tester, byKey(NewDocumentKeys.filterAll));
      await tester.enterText(byKey(NewDocumentKeys.searchField), 'بطاقة');
      await tester.pumpAndSettle();
      expect(familyCard('card.business'), findsOneWidget);
      expect(familyCard('doc.a4.landscape'), findsNothing);

      await tester.enterText(
          byKey(NewDocumentKeys.searchField), 'لا-مقاس-كهذا');
      await tester.pumpAndSettle();
      expect(find.textContaining('لا يوجد مقاس مطابق'), findsOneWidget);
    });

    testWidgets('قرص «مقاس مخصّص» يفتح بطاقته ويضبط 120×80 ملم',
        (WidgetTester tester) async {
      await pumpHost(tester);
      await tapPill(tester, byKey(NewDocumentKeys.filterCustom));

      expect(byKey(NewDocumentKeys.customTile), findsOneWidget);
      expect(familyCard('card.business'), findsNothing);
      expect(numberValue(tester, NewDocumentKeys.widthField), 120);
      expect(numberValue(tester, NewDocumentKeys.heightField), 80);
      expect(
        dropdownValue<MeasurementUnit>(tester, NewDocumentKeys.unitField),
        MeasurementUnit.mm,
      );
    });
  });

  // ==========================================================================
  //  لوحة تفاصيل المقاس
  // ==========================================================================
  group('لوحة تفاصيل المقاس', () {
    testWidgets('اختيار A4 يعبّئ اللوحة بقيمه الحقيقية',
        (WidgetTester tester) async {
      await pumpHost(tester);
      await selectFamily(tester, 'doc.a4.landscape');

      expect(byKey(NewDocumentKeys.detailsHint), findsNothing);
      expect(numberValue(tester, NewDocumentKeys.widthField), 29.7);
      expect(numberValue(tester, NewDocumentKeys.heightField), 21);
      expect(dropdownValue<MeasurementUnit>(tester, NewDocumentKeys.unitField),
          MeasurementUnit.cm);
      expect(
        dropdownValue<DocumentColorMode>(tester, NewDocumentKeys.colorMode),
        DocumentColorMode.cmyk,
      );
      expect(numberValue(tester, NewDocumentKeys.dpiField), 300);
      expect(byKey(NewDocumentKeys.createButton), findsOneWidget);
      expect(byKey(NewDocumentKeys.cancelButton), findsOneWidget);
    });

    testWidgets('زرّا الاتجاه يقلبان الأبعاد ويختاران نوع العائلة',
        (WidgetTester tester) async {
      await pumpHost(tester);
      await selectFamily(tester, 'doc.a4.landscape');

      await tester.tap(byKey(NewDocumentKeys.portrait));
      await tester.pumpAndSettle();
      expect(numberValue(tester, NewDocumentKeys.widthField), 21);
      expect(numberValue(tester, NewDocumentKeys.heightField), 29.7);

      await tapCreate(tester);
      // A4 الرأسي: 595.28×841.89 نقطة بما أنه متغيّر العائلة المقابل.
      expect(describe(results.single),
          'A4|portrait|595.28x841.89|a4|dpi300|cmyk|#FFFFFF');
      expect(results.single!.category, TemplateCategory.contract);
    });

    testWidgets('تغيير الوحدة يحفظ المقاس الفيزيائي والمقاس القياسي',
        (WidgetTester tester) async {
      await pumpHost(tester);
      await selectFamily(tester, 'doc.a4.landscape');

      await tester.tap(byKey(NewDocumentKeys.unitField));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ملم').last);
      await tester.pumpAndSettle();

      expect(numberValue(tester, NewDocumentKeys.widthField), 297);
      expect(numberValue(tester, NewDocumentKeys.heightField), 210);
      await tapCreate(tester);
      expect(describe(results.single),
          'A4|landscape|841.89x595.28|a4|dpi300|cmyk|#FFFFFF');
    });

    testWidgets('كل الحقول تعود في المسودة: الاسم والدقّة والنمط والخلفية',
        (WidgetTester tester) async {
      await pumpHost(tester);
      await selectFamily(tester, 'card.business');

      await tester.enterText(byKey(NewDocumentKeys.titleField), 'بطاقة عمل 2026');
      await typeNumber(tester, NewDocumentKeys.widthField, '100');
      await typeNumber(tester, NewDocumentKeys.heightField, '60');
      await typeNumber(tester, NewDocumentKeys.dpiField, '150');

      // نافذة 800×550: حقول النمط/الخلفية أسفل الطيّة، فتُمرَّر إليها أولاً
      // (كما يفعل المستخدم بعجلة الفأرة داخل لوحة التفاصيل).
      await tester.ensureVisible(byKey(NewDocumentKeys.colorMode));
      await tester.pumpAndSettle();
      await tester.tap(byKey(NewDocumentKeys.colorMode));
      await tester.pumpAndSettle();
      await tester.tap(find.text('RGB — 8 بت (شاشة وويب)').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(byKey(NewDocumentKeys.background));
      await tester.pumpAndSettle();
      await tester.tap(byKey(NewDocumentKeys.background));
      await tester.pumpAndSettle();
      await tester.tap(find.text('شفاف').last);
      await tester.pumpAndSettle();

      await tapCreate(tester);
      expect(describe(results.single),
          'بطاقة عمل 2026|landscape|283.46x170.08|mm|dpi150|rgb|#00000000');
    });

    testWidgets('نوع المنشور يُختار داخل اللوحة (كتاب/مجلة/تقرير)',
        (WidgetTester tester) async {
      await pumpHost(tester, scope: NewDocumentScope.multiPage);
      await selectFamily(tester, 'pub.book.a4');

      expect(find.text('تقرير A4'), findsOneWidget);
      await tester.ensureVisible(find.text('تقرير A4'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تقرير A4'));
      await tester.pumpAndSettle();
      await tapCreate(tester);

      expect(describe(results.single),
          'تقرير A4|portrait|595.28x841.89|a4|dpi300|cmyk|#FFFFFF');
      expect(results.single!.category, TemplateCategory.contract);
    });

    testWidgets('الإنشاء يسجّل المقاس في «الأحدث» فيظهر في تبويبها',
        (WidgetTester tester) async {
      await pumpHost(tester);
      await selectFamily(tester, 'card.business');
      await tapCreate(tester);

      expect(NewDocumentController.recentFamilyIds.first, 'card.business');

      await tester.tap(find.byKey(const ValueKey<String>('host-open')));
      await tester.pumpAndSettle();
      await tester.tap(byKey(NewDocumentKeys.tab(NewDocumentScope.recent)));
      await tester.pumpAndSettle();
      expect(familyCard('card.business'), findsOneWidget);
    });
  });

  // ==========================================================================
  //  أيقونة الورقة المتجهية (بطراز Photoshop)
  // ==========================================================================
  group('أيقونة الورقة المتجهية', () {
    PhotoshopPaperIcon iconOf(WidgetTester tester, String familyId) =>
        tester.widget<PhotoshopPaperIcon>(
          find.descendant(
            of: familyCard(familyId),
            matching: find.byType(PhotoshopPaperIcon),
          ),
        );

    testWidgets('تتبع النسبة الحقيقية للمقاس وتُضيء عند التحديد',
        (WidgetTester tester) async {
      await pumpHost(tester);

      // A4 عريضة فعلاً (‎29.7:21‎) لا مربّعاً مصغّراً موحّداً للجميع.
      final PhotoshopPaperIcon a4 =
          iconOf(tester, 'doc.a4.landscape');
      expect(a4.aspectRatio, closeTo(29.7 / 21, 0.001));
      expect(a4.selected, isFalse);
      expect(a4.hovered, isFalse);

      // وقصة الجوال 16:9 نحيلة طويلة، ونسبة المقاس المربّع 1.
      await tester.tap(byKey(NewDocumentKeys.tab(NewDocumentScope.social)));
      await tester.pumpAndSettle();
      expect(iconOf(tester, 'greeting.story').aspectRatio,
          closeTo(1080 / 1920, 0.001));
      expect(iconOf(tester, 'greeting.square').aspectRatio, closeTo(1, 0.001));

      // والحدّ المُضيء يتبع التحديد.
      await tester.tap(byKey(NewDocumentKeys.tab(NewDocumentScope.singleSheet)));
      await tester.pumpAndSettle();
      await selectFamily(tester, 'doc.a4.landscape');
      expect(iconOf(tester, 'doc.a4.landscape').selected, isTrue);
    });

    testWidgets('المرور فوق البطاقة يُضيء ورقته ثم يطفئها',
        (WidgetTester tester) async {
      await pumpHost(tester);
      final Finder card = familyCard('card.business');
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();

      expect(iconOf(tester, 'card.business').hovered, isFalse);

      final TestGesture mouse =
          await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: tester.getCenter(card));
      await tester.pumpAndSettle();
      expect(iconOf(tester, 'card.business').hovered, isTrue);

      await mouse.moveTo(const Offset(1, 1));
      await tester.pumpAndSettle();
      expect(iconOf(tester, 'card.business').hovered, isFalse);
    });
  });

  // ==========================================================================
  //  الوعي بالوحدة التي جاء منها الطلب
  // ==========================================================================
  group('الوعي بالسياق', () {
    testWidgets('الفتح من محرّك الشهادات يبدأ بالاتجاه الأفقي (شهادة)',
        (WidgetTester tester) async {
      await pumpHost(tester, category: TemplateCategory.certificate);
      await tapPill(tester, byKey(NewDocumentKeys.filterAll));
      await selectFamily(tester, 'doc.a4.landscape');
      await tapCreate(tester);

      expect(describe(results.single),
          'A4|landscape|841.89x595.28|a4|dpi300|cmyk|#FFFFFF');
      expect(results.single!.category, TemplateCategory.certificate);
    });

    testWidgets('الفتح من محرّك العقود يبدأ بالاتجاه الرأسي (عقد)',
        (WidgetTester tester) async {
      await pumpHost(tester, category: TemplateCategory.contract);
      await tapPill(tester, byKey(NewDocumentKeys.filterAll));
      await selectFamily(tester, 'doc.a4.landscape');
      await tapCreate(tester);

      expect(describe(results.single),
          'A4|portrait|595.28x841.89|a4|dpi300|cmyk|#FFFFFF');
      expect(results.single!.category, TemplateCategory.contract);
    });

    testWidgets('الفتح على مجموعة المنشورات يبدأ بنطاقها',
        (WidgetTester tester) async {
      await pumpHost(
        tester,
        group: ProjectPresetGroup.publications,
      );
      // بلا تبديل أي تبويب: المنشورات ظاهرة من البداية.
      expect(familyCard('pub.book.a5'), findsOneWidget);
      expect(familyCard('doc.a4.landscape'), findsNothing);
    });
  });
}
