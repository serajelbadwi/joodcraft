import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/owner_admin/domain/owner_models.dart';

import 'owner_admin_test_helpers.dart';

OwnerLicense _seedLicense({
  String id = 'l1',
  String code = 'FRH-MAA-001',
  String villageId = 'v0',
  String villageName = 'قرية قديمة',
  int? months = 3,
  bool isActive = false,
  DateTime? createdAt,
}) => OwnerLicense(
  id: id,
  code: code,
  villageId: villageId,
  villageName: villageName,
  subscriberName: 'مكتب الأمل',
  subscriberPhone: '01001234567',
  months: months,
  isActive: isActive,
  createdAt: createdAt ?? DateTime(2026, 10, 1),
);

Future<void> _openLicensesTab(WidgetTester tester) async {
  await tester.tap(find.text('التراخيص'));
  await tester.pumpAndSettle();
}

Future<void> _fillIssueDialog(WidgetTester tester, {String months = '3 شهور'}) async {
  await tester.tap(find.byKey(const ValueKey<String>('license-village')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('قرية التجارب')); // بند القائمة
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey<String>('license-name')),
    'مكتب النور',
  );
  await tester.enterText(
    find.byKey(const ValueKey<String>('license-phone')),
    '01234567890',
  );
  await tester.tap(find.text(months)); // المدة في SegmentedButton
  await tester.pump();
}

void main() {
  group('شاشة التراخيص', () {
    testWidgets('القائمة تعرض الكود والقرية والمشترك والتاريخ والمدة',
        (WidgetTester tester) async {
      final FakeOwnerAdminRepository fake = FakeOwnerAdminRepository(
        villages: <OwnerVillage>[
          seedVillage(id: 'v1', name: 'قرية التجارب', code: 'MAA-31951-25GF'),
        ],
        licenses: <OwnerLicense>[_seedLicense()],
      );
      await pumpOwnerAdmin(tester, fake);
      await _openLicensesTab(tester);

      expect(find.text('FRH-MAA-001'), findsOneWidget);
      expect(find.text('قرية قديمة'), findsOneWidget);
      expect(find.text('مكتب الأمل'), findsOneWidget);
      expect(find.text('01001234567'), findsOneWidget);
      expect(
        find.text('2026/10/01 · المدة: 3 شهور'),
        findsOneWidget,
      );
      expect(find.text('غير مفعّل'), findsOneWidget);
    });

    testWidgets('حالة فارغة بلا تراخيص', (WidgetTester tester) async {
      final FakeOwnerAdminRepository fake = FakeOwnerAdminRepository(
        villages: <OwnerVillage>[
          seedVillage(id: 'v1', name: 'قرية التجارب', code: 'MAA-31951-25GF'),
        ],
      );
      await pumpOwnerAdmin(tester, fake);
      await _openLicensesTab(tester);
      expect(
        find.text('لا تراخيص بعد — ابدأ بزر «إصدار ترخيص».'),
        findsOneWidget,
      );
    });

    testWidgets('تحقّق المدخلات قبل الإصدار', (WidgetTester tester) async {
      final FakeOwnerAdminRepository fake = FakeOwnerAdminRepository(
        villages: <OwnerVillage>[
          seedVillage(id: 'v1', name: 'قرية التجارب', code: 'MAA-31951-25GF'),
        ],
      );
      await pumpOwnerAdmin(tester, fake);
      await _openLicensesTab(tester);

      await tester.tap(
        find.byKey(const ValueKey<String>('owner-issue-license')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('license-form-save')),
      );
      await tester.pumpAndSettle();

      expect(find.text('اختر القرية'), findsOneWidget);
      expect(find.text('اكتب اسم صاحب المكتب'), findsOneWidget);
      expect(find.text('اكتب رقم التليفون'), findsOneWidget);
      // لا إصدار بلا مدخلات.
      expect(fake.licenses, isEmpty);

      // تليفون قصير ⇒ رفض.
      await tester.tap(find.byKey(const ValueKey<String>('license-village')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('قرية التجارب'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('license-phone')),
        '123',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('license-form-save')),
      );
      await tester.pumpAndSettle();
      expect(find.text('رقم قصير جداً'), findsOneWidget);
      expect(fake.licenses, isEmpty);
    });

    testWidgets('إصدار ترخيص FRH-MAA-002 — التسلسل بعد الشاغر',
        (WidgetTester tester) async {
      final FakeOwnerAdminRepository fake = FakeOwnerAdminRepository(
        villages: <OwnerVillage>[
          seedVillage(id: 'v1', name: 'قرية التجارب', code: 'MAA-31951-25GF'),
        ],
        licenses: <OwnerLicense>[_seedLicense()],
      );
      await pumpOwnerAdmin(tester, fake);
      await _openLicensesTab(tester);

      await tester.tap(
        find.byKey(const ValueKey<String>('owner-issue-license')),
      );
      await tester.pumpAndSettle();
      await _fillIssueDialog(tester, months: '3 شهور');
      await tester.tap(
        find.byKey(const ValueKey<String>('license-form-save')),
      );
      await tester.pumpAndSettle();

      expect(find.text('أُصدر الترخيص: FRH-MAA-002'), findsOneWidget);
      expect(fake.licenses.last.code, 'FRH-MAA-002');
      expect(fake.licenses.last.months, 3);
      expect(fake.licenses.last.subscriberName, 'مكتب النور');
      // صفّ جديد في القائمة بعد إعادة التحميل.
      expect(find.text('مكتب النور'), findsOneWidget);
      expect(find.text('2026/10/12 · المدة: 3 شهور'), findsOneWidget);
    });

    testWidgets('مدة «سنة» ⇐ 12 شهراً في المستودع',
        (WidgetTester tester) async {
      final FakeOwnerAdminRepository fake = FakeOwnerAdminRepository(
        villages: <OwnerVillage>[
          seedVillage(id: 'v1', name: 'قرية التجارب', code: 'MAA-31951-25GF'),
        ],
      );
      await pumpOwnerAdmin(tester, fake);
      await _openLicensesTab(tester);

      await tester.tap(
        find.byKey(const ValueKey<String>('owner-issue-license')),
      );
      await tester.pumpAndSettle();
      await _fillIssueDialog(tester, months: 'سنة');
      await tester.tap(
        find.byKey(const ValueKey<String>('license-form-save')),
      );
      await tester.pumpAndSettle();

      expect(fake.licenses.single.months, 12);
      expect(fake.licenses.single.code, 'FRH-MAA-001');
      expect(find.text('2026/10/12 · المدة: سنة'), findsOneWidget);
    });

    testWidgets('خطأ الجلب ⇐ عرض الخطأ ثم إعادة المحاولة',
        (WidgetTester tester) async {
      final FakeOwnerAdminRepository fake = FakeOwnerAdminRepository(
        licenses: <OwnerLicense>[_seedLicense()],
      )..fetchLicensesFailures = 1;
      await pumpOwnerAdmin(tester, fake);
      await _openLicensesTab(tester);

      expect(find.text('تعذّر جلب التراخيص'), findsOneWidget);
      await tester.tap(find.text('إعادة المحاولة'));
      await tester.pumpAndSettle();
      expect(find.text('FRH-MAA-001'), findsOneWidget);
    });
  });
}
