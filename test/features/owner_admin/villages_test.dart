import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/owner_admin/domain/owner_models.dart';
import 'package:joodcraft/features/owner_admin/domain/village_code_generator.dart';

import 'owner_admin_test_helpers.dart';

void main() {
  group('VillageCodeGenerator — توليد الكود', () {
    test('الصيغة الكاملة — مثال المهمة MAA-31951-25GF', () {
      final String code = VillageCodeGenerator.generate(
        nameEn: 'Maarra',
        postalCode: '31951',
        plusCode: '25GF+PQ',
      );
      expect(code, 'MAA-31951-25GF');
      expect(VillageCodeGenerator.isValid(code), isTrue);
    });

    test('بديل «0 + السنة» عند غياب الرمز البريدي وPlus Code', () {
      final String code = VillageCodeGenerator.generate(
        nameEn: 'Maarra',
        now: DateTime(2025, 7),
      );
      expect(code, 'MAA-02025-25MA');
      expect(VillageCodeGenerator.isValid(code), isTrue);
    });

    test('اسم بلا حروف لاتينية ⇒ بادئة XXX وبديل صيغة', () {
      final String code = VillageCodeGenerator.generate(
        nameEn: '  ',
        now: DateTime(2025, 7),
      );
      expect(code, 'XXX-02025-25QQ');
      expect(VillageCodeGenerator.isValid(code), isTrue);
    });

    test('Plus Code كامل يُقتطع قبل علامة +', () {
      final String code = VillageCodeGenerator.generate(
        nameEn: 'Maarra',
        plusCode: '8FW4V7WC+R8',
        now: DateTime(2025, 7),
      );
      expect(code, 'MAA-02025-8FW4');
    });

    test('الصيغة القديمة AAA-YYYY غير مطابقة لمولّد اللوحة', () {
      // المولّد لا يُنتج الصيغة القديمة (جزآن) ولا بريدياً من 4 أرقام —
      // البديل حين يفقد الرمز البريدي هو «0 + السنة» (5 أرقام).
      expect(VillageCodeGenerator.isValid('MAA-2026'), isFalse);
      expect(VillageCodeGenerator.isValid('MAA-2026-26MA'), isFalse);
      expect(VillageCodeGenerator.isValid('MAA-02026-26MA'), isTrue);
    });
  });

  group('بوابة إدارة المالك — الصلاحية', () {
    testWidgets('حساب غير مالك ⇒ «غير مصرَّح»', (WidgetTester tester) async {
      final FakeOwnerAdminRepository fake = FakeOwnerAdminRepository(
        isAdmin: false,
      );
      await pumpOwnerGate(tester, fake);
      expect(find.byKey(const ValueKey<String>('owner-gate-denied')),
          findsOneWidget);
      expect(find.text('غير مصرَّح'), findsOneWidget);
      expect(find.text('القرى'), findsNothing);
    });

    testWidgets('المالك ⇒ تُفتح اللوحة مباشرة', (WidgetTester tester) async {
      final FakeOwnerAdminRepository fake = FakeOwnerAdminRepository();
      await pumpOwnerGate(tester, fake);
      expect(find.text('إدارة المالك'), findsOneWidget);
      expect(find.text('القرى'), findsOneWidget);
      expect(find.text('التراخيص'), findsOneWidget);
    });

    testWidgets('بلا مفاتيح Supabase ⇒ ملاحظة التهيئة',
        (WidgetTester tester) async {
      final FakeOwnerAdminRepository fake = FakeOwnerAdminRepository(
        available: false,
      );
      await pumpOwnerGate(tester, fake);
      expect(find.text('خدمة Supabase غير مهيّأة'), findsOneWidget);
      expect(find.text('القرى'), findsNothing);
    });

    testWidgets('بلا جلسة ⇒ نموذج الدخول ثم اللوحة',
        (WidgetTester tester) async {
      final FakeOwnerAdminRepository fake = FakeOwnerAdminRepository(
        signedIn: false,
        isAdmin: true,
      );
      await pumpOwnerGate(tester, fake);
      expect(
        find.byKey(const ValueKey<String>('owner-login-email')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('owner-login-email')),
        'owner@jood.app',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('owner-login-password')),
        'secret',
      );
      await tester.tap(find.byKey(const ValueKey<String>('owner-login-submit')));
      await tester.pumpAndSettle();

      expect(find.text('القرى'), findsOneWidget);
      expect(fake.calls, contains('signIn owner@jood.app'));
      expect(fake.calls, contains('isPlatformAdmin'));
    });

    testWidgets('دخول بحساب غير مالك ⇒ «غير مصرَّح»',
        (WidgetTester tester) async {
      final FakeOwnerAdminRepository fake = FakeOwnerAdminRepository(
        signedIn: false,
        isAdmin: false,
      );
      await pumpOwnerGate(tester, fake);
      await tester.enterText(
        find.byKey(const ValueKey<String>('owner-login-email')),
        'user@jood.app',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('owner-login-password')),
        'secret',
      );
      await tester.tap(find.byKey(const ValueKey<String>('owner-login-submit')));
      await tester.pumpAndSettle();
      expect(find.text('غير مصرَّح'), findsOneWidget);
    });
  });

  group('شاشة القرى', () {
    testWidgets('القائمة تعرض الاسم والكود والمحافظة وعدد الأعضاء',
        (WidgetTester tester) async {
      final FakeOwnerAdminRepository fake = FakeOwnerAdminRepository(
        villages: <OwnerVillage>[seedVillage()],
        memberCounts: <String, int>{'v1': 3},
      );
      await pumpOwnerAdmin(tester, fake);
      expect(find.text('منشأة الأمراء'), findsOneWidget);
      expect(find.text('Maarra'), findsOneWidget);
      expect(find.text('MAA-2026'), findsOneWidget);
      expect(find.text('الغربية • ميت غمر'), findsOneWidget);
      expect(find.text('أعضاء: 3'), findsOneWidget);
    });

    testWidgets('البحث يصفّي بالاسم أو الكود', (WidgetTester tester) async {
      final FakeOwnerAdminRepository fake = FakeOwnerAdminRepository(
        villages: <OwnerVillage>[
          seedVillage(),
          seedVillage(
            id: 'v2',
            name: 'قرية الملوك',
            nameEn: 'Qalya',
            code: 'QLY-2026',
            governorate: 'القاهرة',
            center: 'مدينة نصر',
          ),
        ],
      );
      await pumpOwnerAdmin(tester, fake);
      await tester.enterText(
        find.byKey(const ValueKey<String>('owner-village-search')),
        'QLY',
      );
      await tester.pump();
      expect(find.text('قرية الملوك'), findsOneWidget);
      expect(find.text('منشأة الأمراء'), findsNothing);
    });

    testWidgets('فلترة المحافظة يُخفي غيرها', (WidgetTester tester) async {
      final FakeOwnerAdminRepository fake = FakeOwnerAdminRepository(
        villages: <OwnerVillage>[
          seedVillage(),
          seedVillage(
            id: 'v2',
            name: 'قرية الملوك',
            nameEn: 'Qalya',
            code: 'QLY-2026',
            governorate: 'القاهرة',
            center: 'مدينة نصر',
          ),
        ],
      );
      await pumpOwnerAdmin(tester, fake);
      await tester.tap(find.text('كل المحافظات')); // تلميح القائمة
      await tester.pumpAndSettle();
      await tester.tap(find.text('القاهرة')); // بند الفلترة
      await tester.pumpAndSettle();
      expect(find.text('قرية الملوك'), findsOneWidget);
      expect(find.text('منشأة الأمراء'), findsNothing);
    });

    testWidgets('إضافة قرية بمعاينة كود حيّ ثم ظهورها في القائمة',
        (WidgetTester tester) async {
      final FakeOwnerAdminRepository fake = FakeOwnerAdminRepository();
      await pumpOwnerAdmin(tester, fake);
      expect(find.text('لا توجد قرى بعد — ابدأ بزر «إضافة قرية».'),
          findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('owner-add-village')));
      await tester.pumpAndSettle();
      // حفظ وهو فارغ ⇒ أخطاء التحقّق.
      await tester.tap(find.byKey(const ValueKey<String>('village-form-save')));
      await tester.pumpAndSettle();
      expect(find.text('اكتب اسم القرية'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey<String>('village-name-ar')),
        'كفر النملة',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('village-name-en')),
        'Kafr',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('village-gov')),
        'الدقهلية',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('village-center')),
        'ميت غمر',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('village-postal')),
        '31951',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('village-plus')),
        '25GF+PQ',
      );
      await tester.pump();
      // معاينة حيّة مطابقة لخوارزمية الخادم.
      expect(find.text('الكود المولَّد: KAF-31951-25GF'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('village-form-save')));
      await tester.pumpAndSettle();
      expect(find.text('أنشئت القرية — الكود KAF-31951-25GF'), findsOneWidget);
      expect(find.text('كفر النملة'), findsOneWidget);
      expect(find.text('KAF-31951-25GF'), findsOneWidget);
    });

    testWidgets('تعديل الاسم والكود والمحافظة — والكود الخاطئ مرفوض',
        (WidgetTester tester) async {
      final FakeOwnerAdminRepository fake = FakeOwnerAdminRepository(
        villages: <OwnerVillage>[seedVillage()],
      );
      await pumpOwnerAdmin(tester, fake);

      await tester.tap(
        find.byKey(const ValueKey<String>('village-edit-v1')),
      );
      await tester.pumpAndSettle();
      expect(find.text('تعديل القرية'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey<String>('village-code')),
        'خطأ',
      );
      await tester.tap(find.byKey(const ValueKey<String>('village-form-save')));
      await tester.pumpAndSettle();
      expect(
        find.text('صيغة غير صحيحة — مثال: MAA-31951-25GF'),
        findsOneWidget,
      );
      expect(find.text('تعديل القرية'), findsOneWidget); // الحوار باقٍ

      await tester.enterText(
        find.byKey(const ValueKey<String>('village-name-ar')),
        'منشأة الأمراء الجديدة',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('village-gov')),
        'القاهرة',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('village-code')),
        'QLY-2026',
      );
      await tester.tap(find.byKey(const ValueKey<String>('village-form-save')));
      await tester.pumpAndSettle();

      expect(find.text('حُفظت التعديلات'), findsOneWidget);
      expect(find.text('منشأة الأمراء الجديدة'), findsOneWidget);
      expect(find.text('QLY-2026'), findsOneWidget);
      expect(fake.villages.single.governorate, 'القاهرة');
      expect(fake.villages.single.code, 'QLY-2026');
    });

    testWidgets('حذف القرية بتأكيد — والإلغاء يُبقيها',
        (WidgetTester tester) async {
      final FakeOwnerAdminRepository fake = FakeOwnerAdminRepository(
        villages: <OwnerVillage>[seedVillage()],
      );
      await pumpOwnerAdmin(tester, fake);

      await tester.tap(
        find.byKey(const ValueKey<String>('village-delete-v1')),
      );
      await tester.pumpAndSettle();
      expect(find.text('حذف القرية'), findsOneWidget);
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
      expect(find.text('منشأة الأمراء'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('village-delete-v1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('village-delete-confirm')),
      );
      await tester.pumpAndSettle();
      expect(find.text('منشأة الأمراء'), findsNothing);
      expect(find.text('حُذفت القرية'), findsOneWidget);
      expect(fake.villages, isEmpty);
    });

    testWidgets('خطأ الجلب ⇐ عرض الخطأ ثم إعادة المحاولة',
        (WidgetTester tester) async {
      final FakeOwnerAdminRepository fake = FakeOwnerAdminRepository(
        villages: <OwnerVillage>[seedVillage()],
      )..fetchVillagesFailures = 1;
      await pumpOwnerAdmin(tester, fake);
      expect(find.text('تعذّر جلب القرى'), findsOneWidget);

      await tester.tap(find.text('إعادة المحاولة'));
      await tester.pumpAndSettle();
      expect(find.text('منشأة الأمراء'), findsOneWidget);
    });
  });

  group('حوار توليد الكود المستقلّ', () {
    testWidgets('معاينة حيّة من الاسم والبريد وPlus Code',
        (WidgetTester tester) async {
      final FakeOwnerAdminRepository fake = FakeOwnerAdminRepository();
      await pumpOwnerAdmin(tester, fake);
      await tester.tap(find.byKey(const ValueKey<String>('owner-generate-code')));
      await tester.pumpAndSettle();
      expect(find.text('اكتب الاسم لعرض الكود'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey<String>('generate-name-en')),
        'Maarra',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('generate-postal')),
        '31951',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('generate-plus')),
        '25GF+PQ',
      );
      await tester.pump();
      expect(find.text('MAA-31951-25GF'), findsOneWidget);
    });
  });
}
