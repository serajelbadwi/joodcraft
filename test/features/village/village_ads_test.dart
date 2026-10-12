/// اختبارات قسم «إعلانات» المصغّر: صور فقط بلا نصوص داخل البطاقة، وشبكة
/// تتكيف (1/2/3 أعمدة)، ونافذة تفاصيل بالصورة كاملة + الاتصال + الرابط.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:joodcraft/features/village/domain/village_ad.dart';
import 'package:joodcraft/features/village/domain/village_validators.dart';
import 'package:joodcraft/features/village/presentation/widgets/village_ads_section.dart';

/// إعلان نموذجي بكل الحقول (لاختبار النافذة الكاملة).
VillageAd _fullAd({
  String id = 'a1',
  String title = 'صالون النور للمناسبات',
}) => VillageAd(
      id: id,
      villageId: 'v-1',
      title: title,
      imageUrl: 'https://example.com/ads/$id.jpg',
      contactPhone: '01012345678',
      contactUrl: 'https://wa.me/201012345678',
    );

/// إعلان بلا صورة وبلا تواصل (أدنى حالات المدخلات).
VillageAd _bareAd({String id = 'b1'}) =>
    VillageAd(id: id, villageId: 'v-1', title: 'إعلان بلا صورة');

Future<void> _pumpSection(
  WidgetTester tester, {
  required List<VillageAd> ads,
  double width = 390,
  // الارتفاع كبير بما يكفي لثلاث بطاقات تحت بعضها (الصفحة الحقيقية تمريرية).
  double height = 1200,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        // صفحة القرية كلها RTL — والقسم يُبنى داخلها كذلك.
        textDirection: TextDirection.rtl,
        child: Scaffold(body: VillageAdsSection(ads: ads)),
      ),
    ),
  );
  // صور الشبكة تفشل في بيئة الاختبار عمداً — تحلّها البطاقة البديلة.
  await tester.pump();
}

/// فتح نافذة التفاصيل بالضغط على بطاقة [id].
Future<void> _openDialog(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(ValueKey<String>('village-ad-$id')));
  await tester.pumpAndSettle();
}

void main() {
  group('العنوان والبطاقة', () {
    testWidgets('العنوان «إعلانات» فقط: بلا «القرية» وبلا سطر توضيحي', (
      WidgetTester tester,
    ) async {
      await _pumpSection(tester, ads: <VillageAd>[_fullAd()]);

      expect(find.text('إعلانات'), findsOneWidget);
      expect(find.textContaining('القرية'), findsNothing);
      expect(find.text(VillageText.adsSubtitle), findsNothing);
      expect(find.text(VillageText.adsTitle), findsNothing);
    });

    testWidgets('البطاقة صورة فقط: بلا نصّ ولا أزرار ولا اسم معلن', (
      WidgetTester tester,
    ) async {
      await _pumpSection(
        tester,
        ads: <VillageAd>[_fullAd(), _fullAd(id: 'a2', title: 'مكتب الأفراح')],
      );

      // بطاقتان قابلتان للتحديد بمعرّفيهما.
      expect(find.byKey(const ValueKey<String>('village-ad-a1')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('village-ad-a2')), findsOneWidget);

      // ولا نصّ ولا زرّ على البطاقة نفسها.
      expect(find.text('صالون النور للمناسبات'), findsNothing);
      expect(find.text('مكتب الأفراح'), findsNothing);
      expect(find.text('01012345678'), findsNothing);
      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('بلا صورة: أيقونة بدلها والبطاقة تبقى قابلة للضغط', (
      WidgetTester tester,
    ) async {
      await _pumpSection(tester, ads: <VillageAd>[_bareAd()]);

      expect(find.byIcon(Icons.campaign_outlined), findsOneWidget);

      await _openDialog(tester, 'b1');
      expect(find.text('إعلان بلا صورة'), findsOneWidget);
    });
  });

  group('الشبكة التكيفية', () {
    testWidgets('موبايل (ضيق): عمودٌ واحد — البطاقات تحت بعضها', (
      WidgetTester tester,
    ) async {
      await _pumpSection(
        tester,
        width: 390,
        ads: <VillageAd>[
          _fullAd(id: 'c1'),
          _fullAd(id: 'c2'),
          _fullAd(id: 'c3'),
        ],
      );

      final Offset one = tester.getTopLeft(
        find.byKey(const ValueKey<String>('village-ad-c1')),
      );
      final Offset two = tester.getTopLeft(
        find.byKey(const ValueKey<String>('village-ad-c2')),
      );
      final Offset three = tester.getTopLeft(
        find.byKey(const ValueKey<String>('village-ad-c3')),
      );

      expect(two.dx, closeTo(one.dx, 0.1), reason: 'عمود واحد');
      expect(three.dx, closeTo(one.dx, 0.1), reason: 'عمود واحد');
      expect(two.dy, greaterThan(one.dy), reason: 'تحت الأولى');
      expect(three.dy, greaterThan(two.dy), reason: 'تحت الثانية');
    });

    testWidgets('تابلت (متوسط): عمودان — الثالث ينزل لصفٍّ ثانٍ', (
      WidgetTester tester,
    ) async {
      await _pumpSection(
        tester,
        width: 700,
        ads: <VillageAd>[
          _fullAd(id: 'c1'),
          _fullAd(id: 'c2'),
          _fullAd(id: 'c3'),
        ],
      );

      final Offset one = tester.getTopLeft(
        find.byKey(const ValueKey<String>('village-ad-c1')),
      );
      final Offset two = tester.getTopLeft(
        find.byKey(const ValueKey<String>('village-ad-c2')),
      );
      final Offset three = tester.getTopLeft(
        find.byKey(const ValueKey<String>('village-ad-c3')),
      );

      expect(two.dy, closeTo(one.dy, 0.1), reason: 'الثانية في صفّ الأولى');
      expect(two.dx, lessThan(one.dx), reason: 'لها العمود المجاور');
      expect(three.dy, greaterThan(one.dy), reason: 'الثالث صفّ جديد');
    });

    testWidgets('ديسكتوب (عريض): ثلاثة أعمدة في صفٍّ واحد', (
      WidgetTester tester,
    ) async {
      await _pumpSection(
        tester,
        width: 1200,
        ads: <VillageAd>[
          _fullAd(id: 'c1'),
          _fullAd(id: 'c2'),
          _fullAd(id: 'c3'),
        ],
      );

      final Offset one = tester.getTopLeft(
        find.byKey(const ValueKey<String>('village-ad-c1')),
      );
      final Offset two = tester.getTopLeft(
        find.byKey(const ValueKey<String>('village-ad-c2')),
      );
      final Offset three = tester.getTopLeft(
        find.byKey(const ValueKey<String>('village-ad-c3')),
      );

      expect(two.dy, closeTo(one.dy, 0.1), reason: 'صفّ واحد');
      expect(three.dy, closeTo(one.dy, 0.1), reason: 'صفّ واحد');
      expect(two.dx, lessThan(one.dx), reason: 'عمودان متجاوران');
      expect(three.dx, lessThan(two.dx), reason: 'الأعمدة الثلاثة متجاورة');
    });
  });

  group('نافذة التفاصيل', () {
    testWidgets('الضغط على الصورة يفتحها: الصورة + العنوان + الاتصال + الرابط', (
      WidgetTester tester,
    ) async {
      await _pumpSection(tester, ads: <VillageAd>[_fullAd()]);
      await _openDialog(tester, 'a1');

      // الصورة كاملة (contain لا تقصّ الإعلان) + العنوان + رقم المعلن.
      expect(find.byType(Image), findsWidgets);
      expect(find.text('صالون النور للمناسبات'), findsOneWidget);
      expect(find.text('01012345678'), findsOneWidget);

      // الأزرار الثلاثة.
      expect(
        find.byKey(const ValueKey<String>('village-ad-dialog-call')),
        findsOneWidget,
      );
      expect(find.text(VillageText.adsCall), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('village-ad-dialog-link')),
        findsOneWidget,
      );
      expect(find.text('رابط'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('village-ad-dialog-close')),
        findsOneWidget,
      );

      // ضغط الاتصال (نسخة صامتة في الاختبارات) لا يُسقط شيئاً.
      await tester.tap(
        find.byKey(const ValueKey<String>('village-ad-dialog-call')),
      );
      await tester.pumpAndSettle();
      expect(find.text('صالون النور للمناسبات'), findsOneWidget);
    });

    testWidgets('زرّ الإغلاق (X) يُغلق النافذة', (WidgetTester tester) async {
      await _pumpSection(tester, ads: <VillageAd>[_fullAd()]);
      await _openDialog(tester, 'a1');

      await tester.tap(
        find.byKey(const ValueKey<String>('village-ad-dialog-close')),
      );
      await tester.pumpAndSettle();

      expect(find.text('صالون النور للمناسبات'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('village-ad-dialog-close')),
        findsNothing,
      );
      // البطاقة ما زالت في مكانها.
      expect(find.byKey(const ValueKey<String>('village-ad-a1')), findsOneWidget);
    });

    testWidgets('بلا رقم وبلا رابط: نافذة الصورة والعنوان فقط', (
      WidgetTester tester,
    ) async {
      await _pumpSection(tester, ads: <VillageAd>[_bareAd()]);
      await _openDialog(tester, 'b1');

      expect(find.text('إعلان بلا صورة'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('village-ad-dialog-call')), findsNothing);
      expect(find.byKey(const ValueKey<String>('village-ad-dialog-link')), findsNothing);
      expect(find.text('رابط'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('village-ad-dialog-close')),
        findsOneWidget,
      );
    });
  });
}
