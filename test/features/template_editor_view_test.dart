import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/widgets/element_view.dart';
import 'package:joodcraft/core/editor/widgets/template_canvas.dart';
import 'package:joodcraft/core/editor/widgets/template_editor_view.dart';
import 'package:joodcraft/core/errors/app_error_code.dart';
import 'package:joodcraft/features/contract_builder/presentation/screens/template_editor_screen.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/templates/unsaved_changes_guard.dart';
import 'package:joodcraft/core/theme/app_theme.dart';

import '../support/fake_template_repository.dart';

void main() {
  TemplateDocument document() => const TemplateDocument(
        orientation: PageOrientation.landscape,
        elements: <TemplateElement>[
          TextElement(
            id: 'text-1',
            box: ElementBox(x: 200, y: 200, width: 400, height: 80),
            text: 'شهادة إتمام',
          ),
        ],
      );

  late FakeTemplateRepository repository;

  setUp(() => repository = FakeTemplateRepository());

  Future<void> pumpEditor(
    WidgetTester tester, {
    bool withRepository = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TemplateEditorView(
            category: TemplateCategory.certificate,
            initialTemplateAsset: AppAssets.sampleCertificateTemplate,
            exportFileName: 'joodcraft-certificate.pdf',
            repository: withRepository ? repository : null,
            title: 'شهادة جديدة',
            document: document(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('البناء العام', () {
    testWidgets('تُعرض الترويسة واللوحة وشريط إضافة العناصر',
        (WidgetTester tester) async {
      await pumpEditor(tester);

      expect(find.text('شهادة جديدة'), findsOneWidget);
      expect(find.byType(TemplateCanvas), findsOneWidget);
      expect(find.text('إضافة عنصر'), findsOneWidget);
      expect(find.textContaining('عنصراً'), findsOneWidget);
      expect(find.byType(ElementView), findsOneWidget);
    });

    testWidgets('الترويسة تُظهر أن الحفظ غير متاح بلا مستودع',
        (WidgetTester tester) async {
      await pumpEditor(tester, withRepository: false);

      expect(find.text('الحفظ غير متاح'), findsOneWidget);
    });

    testWidgets('تبديل الاتجاه إلى رأسي يقلب أبعاد الورقة',
        (WidgetTester tester) async {
      await pumpEditor(tester);

      // الأزرار المدمجة بأيقونات تُعنون بالتلميح (Tooltip).
      await tester.tap(find.byTooltip('رأسي'));
      await tester.pump();

      final TemplateCanvas canvas =
          tester.widget<TemplateCanvas>(find.byType(TemplateCanvas));
      final Size design = canvas.controller.designSize;
      expect(design.height, greaterThan(design.width));
    });

    testWidgets('زر التراجع يُعيد آخر تعديل', (WidgetTester tester) async {
      await pumpEditor(tester);

      expect(find.byTooltip('تراجع (Ctrl+Z)'), findsOneWidget);
      await tester.tap(find.byTooltip('تراجع (Ctrl+Z)'));
      await tester.pump();

      expect(find.byType(ElementView), findsOneWidget);
    });
  });

  group('التحديد الابتدائي ومحرر العقود', () {
    testWidgets('تحديد عنصر ابتدائياً يُظهر شريط خصائصه فوراً',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: TemplateEditorView(
              category: TemplateCategory.certificate,
              initialTemplateAsset: AppAssets.sampleCertificateTemplate,
              exportFileName: 'joodcraft-certificate.pdf',
              repository: repository,
              document: document(),
              initialSelectionId: 'text-1',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('الموضع والحجم'), findsOneWidget);
      expect(find.text('تنسيق النص'), findsOneWidget);
    });

    testWidgets('محرّر العقود يفتح بورقة رأسية', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ContractTemplateEditorScreen(repository: repository),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final TemplateCanvas canvas =
          tester.widget<TemplateCanvas>(find.byType(TemplateCanvas));
      final Size design = canvas.controller.designSize;
      expect(design.height, greaterThan(design.width));
      expect(canvas.controller.category, TemplateCategory.contract);
    });
  });

  group('شريط الخصائص', () {
    testWidgets('النقر على عنصر داخل اللوحة يُظهر شريط خصائصه',
        (WidgetTester tester) async {
      await pumpEditor(tester);
      expect(find.text('الموضع والحجم'), findsNothing);

      await tester.tap(find.byType(ElementView));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('الموضع والحجم'), findsOneWidget);
      expect(find.text('تنسيق النص'), findsOneWidget);
    });
  });

  group('الحفظ', () {
    testWidgets('الحفظ بلا مستودع يُظهر تحذيراً ولا يُنشئ شيئاً',
        (WidgetTester tester) async {
      await pumpEditor(tester, withRepository: false);

      await tester.tap(find.text('الحفظ غير متاح'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('يتطلب الاتصال بمشروع Supabase'), findsOneWidget);
      expect(repository.createCalls, 0);

      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('الحفظ الأول يطلب العنوان ثم يُنشئ القالب في المستودع',
        (WidgetTester tester) async {
      await pumpEditor(tester);

      await tester.tap(find.text('حفظ القالب'));
      await tester.pumpAndSettle();

      expect(find.text('عنوان القالب'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'العنوان'),
        'شهادة الاختبار',
      );
      await tester.tap(find.text('متابعة'));
      await tester.pumpAndSettle();

      expect(repository.createCalls, 1);
      expect(repository.records.single.title, 'شهادة الاختبار');
      expect(
        repository.records.single.layoutData['schema_version'],
        AppConstants.layoutSchemaVersion,
      );
      expect(find.textContaining('تم حفظ القالب'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('الحفظ الثاني يُحدّث السجل نفسه بلا نافذة عنوان جديدة',
        (WidgetTester tester) async {
      await pumpEditor(tester);

      await tester.tap(find.text('حفظ القالب'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'العنوان'),
        'قالب مُكرَّر الحفظ',
      );
      await tester.tap(find.text('متابعة'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));

      await tester.tap(find.text('حفظ القالب'));
      await tester.pumpAndSettle();

      expect(repository.createCalls, 1);
      expect(repository.updateCalls, 1);
      expect(find.text('عنوان القالب'), findsNothing);

      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('فشل الحفظ يُعرض كرسالة خطأ عربية',
        (WidgetTester tester) async {
      repository.failWith = AppErrorCode.permissionDenied;
      await pumpEditor(tester);

      await tester.tap(find.text('حفظ القالب'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'العنوان'),
        'قالب سيفشل',
      );
      await tester.tap(find.text('متابعة'));
      await tester.pumpAndSettle();

      expect(
        find.text(AppErrorCode.permissionDenied.messageAr),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 5));
    });
  });

  group('حماية التعديلات غير المحفوظة', () {
    testWidgets('بلا تعديلات: المغادرة مسموحة فوراً بلا نافذة',
        (WidgetTester tester) async {
      await pumpEditor(tester);

      final bool allowed = await UnsavedChangesGuard.instance.canLeave();

      expect(allowed, isTrue);
      expect(find.text('تعديلات غير محفوظة'), findsNothing);
    });

    testWidgets('بعد تعديل: «إلغاء» يمنع المغادرة',
        (WidgetTester tester) async {
      await pumpEditor(tester);
      await tester.tap(find.byTooltip('إضافة نص'));
      await tester.pump();

      bool? allowed;
      unawaited(
        UnsavedChangesGuard.instance.canLeave().then((bool v) => allowed = v),
      );
      await tester.pumpAndSettle();

      expect(find.text('تعديلات غير محفوظة'), findsOneWidget);
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();

      expect(allowed, isFalse);
    });

    testWidgets('بعد تعديل: «المغادرة دون حفظ» تسمح بالخروج',
        (WidgetTester tester) async {
      await pumpEditor(tester);
      await tester.tap(find.byTooltip('إضافة نص'));
      await tester.pump();

      bool? allowed;
      unawaited(
        UnsavedChangesGuard.instance.canLeave().then((bool v) => allowed = v),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('المغادرة دون حفظ'));
      await tester.pumpAndSettle();

      expect(allowed, isTrue);
    });

    testWidgets('«حفظ والمغادرة» يحفظ فعلاً ثم يسمح بالخروج',
        (WidgetTester tester) async {
      await pumpEditor(tester);
      await tester.tap(find.byTooltip('إضافة نص'));
      await tester.pump();

      bool? allowed;
      unawaited(
        UnsavedChangesGuard.instance.canLeave().then((bool v) => allowed = v),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('حفظ والمغادرة'));
      await tester.pumpAndSettle();

      // الحفظ الأول يطلب عنواناً قبل الإنشاء.
      expect(find.text('عنوان القالب'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'العنوان'),
        'قالب محفوظ قبل المغادرة',
      );
      await tester.tap(find.text('متابعة'));
      await tester.pumpAndSettle();

      expect(repository.createCalls, 1);
      expect(allowed, isTrue);
      await tester.pump(const Duration(seconds: 5));
    });
  });

  group('مكتبة القوالب', () {
    testWidgets('فتح «قوالبي» يعرض القوالب المحفوظة ويحمّل المختار',
        (WidgetTester tester) async {
      await repository.create(
        title: 'شهادة تدريب 2026',
        category: TemplateCategory.certificate,
        orientation: PageOrientation.landscape,
        layoutData: document().toJson(),
      );
      await pumpEditor(tester);

      await tester.tap(find.text('قوالبي'));
      await tester.pumpAndSettle();

      expect(find.text('قوالبي المحفوظة'), findsOneWidget);
      expect(find.text('شهادة تدريب 2026'), findsOneWidget);

      await tester.tap(find.text('شهادة تدريب 2026'));
      await tester.pumpAndSettle();

      // القالب المفتوح يصبح هو عنوان المحرر الحالي.
      expect(find.text('شهادة تدريب 2026'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('مكتبة بلا مستودع تُظهر تحذيراً', (WidgetTester tester) async {
      await pumpEditor(tester, withRepository: false);

      await tester.tap(find.text('قوالبي'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.textContaining('مكتبة القوالب تتطلب الاتصال'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 5));
    });
  });

  group('المعاينة', () {
    testWidgets('التبديل إلى «معاينة PDF» يستبدل اللوحة بالمعاينة',
        (WidgetTester tester) async {
      await pumpEditor(tester);
      expect(find.byType(TemplateCanvas), findsOneWidget);

      await tester.tap(find.byTooltip('معاينة PDF'));
      await tester.pump();

      expect(find.byType(TemplateCanvas), findsNothing);
      expect(find.text('إضافة عنصر'), findsNothing);

      await tester.tap(find.byTooltip('المحرر'));
      await tester.pump();
      expect(find.byType(TemplateCanvas), findsOneWidget);
    });
  });
}
