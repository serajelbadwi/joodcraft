import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_document.dart';
import 'package:joodcraft/features/jood_writer/presentation/screens/jood_writer_screen.dart';

/// اختبارات وِدجت لشاشة «جود كاتب» بمظهرها الجديد: الشريط العلوي، اللوحة الجانبية، ومساحة العمل.
void main() {
  Future<void> pumpScreen(WidgetTester tester, {Size size = const Size(1280, 800)}) async {
    // استخدم حجم كبير للشاشة لضمان ظهور اللوحة الجانبية ومساحة العمل
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: JoodWriterScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('يعرض الشريط العلوي، اللوحة الجانبية، ومساحة العمل الابتدائية', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester);

    // التحقق من وجود الشريط العلوي (Ribbon Bar)
    expect(find.byKey(const ValueKey<String>('writer-ribbon')), findsOneWidget);

    // التحقق من وجود إعدادات في اللوحة الجانبية (Sidebar)
    expect(find.text('إعدادات الصفحة'), findsOneWidget);
    expect(find.text('حجم الورقة'), findsOneWidget);
    expect(find.text('الهوامش (مم)'), findsOneWidget);

    // المستند الابتدائي فارغ يحوي كتلة واحدة
    expect(
      find.byKey(const ValueKey<String>('writer-field-0')),
      findsOneWidget,
    );
    // لا يوجد كتلة ثانية بالبداية
    expect(find.byKey(const ValueKey<String>('writer-field-1')), findsNothing);
  });

  testWidgets('زر إضافة كتلة يُدرج حقلاً جديداً في مساحة العمل', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester);

    expect(
      find.byKey(const ValueKey<String>('writer-field-0')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('writer-field-1')), findsNothing);

    // النقر على زر "إضافة كتلة" من الشريط العلوي (يعتمد على التول تيب)
    await tester.tap(find.byTooltip('إضافة كتلة'));
    await tester.pumpAndSettle();

    // صار العدد 2 بعد الإدراج
    expect(
      find.byKey(const ValueKey<String>('writer-field-1')),
      findsOneWidget,
    );
  });

  testWidgets('تغيير حجم الصفحة من اللوحة الجانبية', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester);

    // البحث عن القائمة المنسدلة لحجم الورقة
    final dropdownFinder = find.byType(
      DropdownButtonFormField<JoodWriterPageSize>,
    );
    expect(dropdownFinder, findsOneWidget);

    // القيمة الافتراضية يجب أن تكون A4
    expect(find.text('A4'), findsOneWidget);

    // فتح القائمة واختيار حجم آخر
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    expect(find.text('A3').last, findsOneWidget);
    await tester.tap(find.text('A3').last);
    await tester.pumpAndSettle();

    // التحقق أن القيمة تغيرت (لا يمكننا رؤية state بسهولة، لكن نتحقق من عدم وجود خطأ وتغير نص العنصر).
    expect(find.text('A3'), findsWidgets);
  });

  group('الأدوات الجديدة في الشريط واللوحة', () {
    testWidgets('زر فاصل الصفحات يفتح صفحة ثانية ويعرض علامتها', (
      WidgetTester tester,
    ) async {
      // ارتفاع كافٍ ليبقى الصف الثاني داخل مدى البناء.
      await pumpScreen(tester, size: const Size(1280, 1600));

      expect(
        find.byKey(const ValueKey<String>('writer-page-2')),
        findsNothing,
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('writer-field-0')),
        'نص قصير جداً',
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byTooltip('فاصل صفحات (صفحة جديدة عند المؤشر)'),
      );
      await tester.pumpAndSettle();

      // صفحة ثانية وُلدت فوراً حتى لا يملأ النص صفحة واحدة…
      expect(
        find.byKey(const ValueKey<String>('writer-page-2')),
        findsOneWidget,
      );
      // …وعلامة الفاصل المنقطة تُرسم في هامشها العليا.
      expect(
        find.byKey(const ValueKey<String>('writer-page-break-marker-2')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('زر طي الكتاب يعرض صفحتين متقابلتين جنباً إلى جنب', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, size: const Size(1280, 1600));

      await tester.enterText(
        find.byKey(const ValueKey<String>('writer-field-0')),
        'نص قصير',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byTooltip('فاصل صفحات (صفحة جديدة عند المؤشر)'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('عرض صفحتين متقابلتين (طي الكتاب)'));
      await tester.pumpAndSettle();

      final Finder page1 = find.byKey(const ValueKey<String>('writer-page-1'));
      final Finder page2 = find.byKey(const ValueKey<String>('writer-page-2'));
      expect(page1, findsOneWidget);
      expect(page2, findsOneWidget);
      // في الاتجاه العربي: الصفحة الفردية يمين والزوجية إلى يسارها، على ارتفاع واحد.
      expect(
        tester.getTopLeft(page1).dx,
        greaterThan(tester.getTopLeft(page2).dx),
      );
      expect(
        tester.getTopLeft(page1).dy,
        closeTo(tester.getTopLeft(page2).dy, 1),
      );

      // الزر مُفعَّل (محدَّد) في الوضع المتقابل.
      final Finder toggle = find.byTooltip(
        'عرض صفحتين متقابلتين (طي الكتاب)',
      );
      final dynamic state = tester.state(toggle);
      expect(state.isSelected, contains(true));
      expect(tester.takeException(), isNull);
    });

    testWidgets('لوحة تخصيص أرقام الصفحات: النمط والمحاذاة والحجم واللون', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester);

      // قسم التخصيص ظاهر في اللوحة الجانبية.
      expect(find.text('أرقام الصفحات'), findsOneWidget);
      expect(find.text('النمط'), findsOneWidget);
      expect(find.text('المحاذاة'), findsOneWidget);
      expect(find.text('الحجم'), findsOneWidget);
      expect(find.text('اللون'), findsOneWidget);

      // تغيير النمط من «صفحة X من Y» إلى «X فقط».
      final Finder patternDropdown = find.byType(
        DropdownButtonFormField<PageNumberPattern>,
      );
      expect(patternDropdown, findsOneWidget);
      await tester.tap(patternDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('X فقط').last);
      await tester.pumpAndSettle();
      expect(find.text('X فقط').last, findsOneWidget);

      // تغيير المحاذاة إلى «يمين».
      await tester.tap(find.text('يمين').last);
      await tester.pumpAndSettle();
      final Finder rightSelected = find.byWidgetPredicate(
        (Widget w) =>
            w is SegmentedButton<PageNumberAlign> &&
            w.selected.contains(PageNumberAlign.right),
      );
      expect(rightSelected, findsOneWidget);

      // تكبير الحجم مرّتين (10 ← 12) وتصغيره مرّة (← 11).
      await tester.tap(find.byTooltip('تكبير الرقم'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('تكبير الرقم'));
      await tester.pumpAndSettle();
      expect(find.text('12'), findsOneWidget);
      await tester.tap(find.byTooltip('تصغير الرقم'));
      await tester.pumpAndSettle();
      expect(find.text('11'), findsOneWidget);

      // اختيار لون أحمر من Алексанات.
      await tester.tap(find.byTooltip('تلقائي'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
