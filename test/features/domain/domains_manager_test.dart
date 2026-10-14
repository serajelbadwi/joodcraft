import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/domain/data/domain_repository.dart';
import 'package:joodcraft/features/domain/domain/domain.dart';
import 'package:joodcraft/features/domain/presentation/domains_manager_tab.dart';

import 'domain_test_helpers.dart';

void main() {
  group('نموذج إضافة نطاق', () {
    testWidgets('معاينة حيّة للكود ثم إضافة ناجحة',
        (WidgetTester tester) async {
      final FakeDomainRepository fake = FakeDomainRepository();
      await _pumpTab(tester, fake);

      await tester.tap(find.byKey(const ValueKey<String>('domain-add')));
      await tester.pumpAndSettle();
      expect(_dialogText('إضافة نطاق'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('domain-name-ar')),
          findsOneWidget);

      // حفظ وهو فارغ ⇒ أخطاء التحقّق.
      await tester.tap(find.byKey(const ValueKey<String>('domain-form-save')));
      await tester.pumpAndSettle();
      expect(find.text('اكتب اسم النطاق'), findsOneWidget);
      expect(
        find.text('اكتب الاسم اللاتيني — أساس بادئة الكود'),
        findsOneWidget,
      );
      expect(find.text('اكتب المحافظة'), findsOneWidget);
      expect(find.text('اكتب المركز'), findsOneWidget);

      // اسم عربي مطلوب — اللاتيني وحده مرفوض.
      await tester.enterText(
        find.byKey(const ValueKey<String>('domain-name-ar')),
        'Maarra',
      );
      await tester.tap(find.byKey(const ValueKey<String>('domain-form-save')));
      await tester.pumpAndSettle();
      expect(find.text('اكتب الاسم بحروف عربية'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey<String>('domain-name-ar')),
        'منشأة الأمراء',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('domain-name-en')),
        'Maarra',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('domain-gov')),
        'الغربية',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('domain-center')),
        'ميت غمر',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('domain-postal')),
        '31951',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('domain-plus')),
        '25GF+989',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('domain-lat')),
        '30.8124',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('domain-lng')),
        '31.2345',
      );
      await tester.pump();
      expect(
        find.text('الكود المولَّد: MAA-31951-25GF989'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey<String>('domain-form-save')));
      await tester.pumpAndSettle();
      expect(
        find.text('أُضيف النطاق — الكود MAA-31951-25GF989'),
        findsOneWidget,
      );
      expect(find.text('منشأة الأمراء'), findsOneWidget);
      expect(find.text('MAA-31951-25GF989'), findsOneWidget);
      expect(fake.calls, contains('createDomain منشأة الأمراء'));
      // الإحداثيات الاختيارية تُمرَّر للمستودع كما كُتبت.
      expect(fake.lastLatitude, 30.8124);
      expect(fake.lastLongitude, 31.2345);
      expect(fake.domains.single.latitude, 30.8124);
    });

    testWidgets('إحداثي خارج المدى ⇒ رفض مع رسالة', (WidgetTester tester) async {
      final FakeDomainRepository fake = FakeDomainRepository();
      await _pumpTab(tester, fake);

      await tester.tap(find.byKey(const ValueKey<String>('domain-add')));
      await tester.pumpAndSettle();
      await _fillDomainForm(tester);

      await tester.enterText(
        find.byKey(const ValueKey<String>('domain-lat')),
        '200',
      );
      await tester.tap(find.byKey(const ValueKey<String>('domain-form-save')));
      await tester.pumpAndSettle();
      expect(find.text('خط العرض بين -90 و 90'), findsOneWidget);
      // لم يُنشأ شيء.
      expect(fake.domains, isEmpty);

      await tester.enterText(
        find.byKey(const ValueKey<String>('domain-lat')),
        'abc',
      );
      await tester.tap(find.byKey(const ValueKey<String>('domain-form-save')));
      await tester.pumpAndSettle();
      expect(find.text('اكتب رقماً — مثال: 30.8124'), findsOneWidget);
    });

    testWidgets('خطأ الخادم يُعرب ويبقى الحوار مفتوحاً',
        (WidgetTester tester) async {
      final FakeDomainRepository fake = FakeDomainRepository(
        createError:
            const DomainAdminException('هذا الكود مستخدم لنطاق آخر'),
      );
      await _pumpTab(tester, fake);

      await tester.tap(find.byKey(const ValueKey<String>('domain-add')));
      await tester.pumpAndSettle();
      await _fillDomainForm(tester);
      await tester.tap(find.byKey(const ValueKey<String>('domain-form-save')));
      await tester.pumpAndSettle();

      expect(find.text('هذا الكود مستخدم لنطاق آخر'), findsOneWidget);
      expect(_dialogText('إضافة نطاق'), findsOneWidget); // الحوار باقٍ
      expect(fake.domains, isEmpty);
    });

    testWidgets('تعديل نطاق — الاسم والمحافظة', (WidgetTester tester) async {
      final FakeDomainRepository fake = FakeDomainRepository(
        domains: <Domain>[seedDomain()],
      );
      await _pumpTab(tester, fake);

      await tester.tap(find.byKey(const ValueKey<String>('domain-edit-d1')));
      await tester.pumpAndSettle();
      expect(find.text('تعديل النطاق'), findsOneWidget);
      // في التعديل لا قسم توليد الكود — الكود ثابت.
      expect(find.text('توليد الكود (اختياري)'), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey<String>('domain-name-ar')),
        'منشأة الأمراء الجديدة',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('domain-gov')),
        'الدقهلية',
      );
      await tester.tap(find.byKey(const ValueKey<String>('domain-form-save')));
      await tester.pumpAndSettle();

      expect(find.text('حُفظت التعديلات'), findsOneWidget);
      expect(find.text('منشأة الأمراء الجديدة'), findsOneWidget);
      expect(fake.domains.single.governorate, 'الدقهلية');
    });
  });

  group('إدارة النطاقات — القائمة', () {
    testWidgets('قائمة فارغة ⇒ رسالة «إضافة نطاق»', (WidgetTester tester) async {
      final FakeDomainRepository fake = FakeDomainRepository();
      await _pumpTab(tester, fake);
      expect(find.text('لا توجد نطاقات بعد — ابدأ بزر «إضافة نطاق».'),
          findsOneWidget);
    });

    testWidgets('عرض النطاقات مع الاسم والكود والموقع',
        (WidgetTester tester) async {
      final FakeDomainRepository fake = FakeDomainRepository(
        domains: <Domain>[seedDomain()],
      );
      await _pumpTab(tester, fake);

      expect(find.text('منشأة الأمراء'), findsOneWidget);
      expect(find.text('Maarra'), findsOneWidget);
      expect(find.text('MAA-31951-25GF989'), findsOneWidget);
      expect(find.text('الغربية • ميت غمر'), findsOneWidget);
    });

    testWidgets('البحث بالاسم أو الكود', (WidgetTester tester) async {
      final FakeDomainRepository fake = FakeDomainRepository(
        domains: <Domain>[
          seedDomain(),
          seedDomain(
            id: 'd2',
            nameAr: 'كفر النملة',
            nameEn: 'Kafr',
            code: 'KAF-35111-9G7F+22',
            governorate: 'الدقهلية',
          ),
        ],
      );
      await _pumpTab(tester, fake);

      await tester.enterText(
        find.byKey(const ValueKey<String>('domain-search')),
        'كفر',
      );
      await tester.pumpAndSettle();
      expect(find.text('منشأة الأمراء'), findsNothing);
      expect(find.text('كفر النملة'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey<String>('domain-search')),
        'MAA-31951',
      );
      await tester.pumpAndSettle();
      expect(find.text('كفر النملة'), findsNothing);
      expect(find.text('منشأة الأمراء'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey<String>('domain-search')),
        'لا شيء',
      );
      await tester.pumpAndSettle();
      expect(find.text('لا نتائج مطابقة للبحث.'), findsOneWidget);
    });

    testWidgets('الفلترة بالمحافظة', (WidgetTester tester) async {
      final FakeDomainRepository fake = FakeDomainRepository(
        domains: <Domain>[
          seedDomain(),
          seedDomain(
            id: 'd2',
            nameAr: 'كفر النملة',
            nameEn: 'Kafr',
            code: 'KAF-35111-9G7F+22',
            governorate: 'الدقهلية',
          ),
        ],
      );
      await _pumpTab(tester, fake);

      await tester.tap(find.byKey(const ValueKey<String>('domain-gov-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الدقهلية').last);
      await tester.pumpAndSettle();

      expect(find.text('كفر النملة'), findsOneWidget);
      expect(find.text('منشأة الأمراء'), findsNothing);
    });

    testWidgets('حذف نطاق بتأكيد — والإلغاء يُبقيه', (WidgetTester tester) async {
      final FakeDomainRepository fake = FakeDomainRepository(
        domains: <Domain>[seedDomain()],
      );
      await _pumpTab(tester, fake);

      await tester.tap(find.byKey(const ValueKey<String>('domain-delete-d1')));
      await tester.pumpAndSettle();
      expect(find.text('حذف النطاق'), findsOneWidget);
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
      expect(find.text('منشأة الأمراء'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('domain-delete-d1')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('domain-delete-confirm')),
      );
      await tester.pumpAndSettle();
      expect(find.text('منشأة الأمراء'), findsNothing);
      expect(find.text('حُذف النطاق'), findsOneWidget);
      expect(fake.domains, isEmpty);
    });

    testWidgets('خطأ الجلب ⇐ عرض الخطأ ثم إعادة المحاولة',
        (WidgetTester tester) async {
      final FakeDomainRepository fake = FakeDomainRepository(
        domains: <Domain>[seedDomain()],
      )..fetchFailures = 1;
      await _pumpTab(tester, fake);
      expect(find.text('تعذّر جلب النطاقات'), findsOneWidget);

      await tester.tap(find.text('إعادة المحاولة'));
      await tester.pumpAndSettle();
      expect(find.text('منشأة الأمراء'), findsOneWidget);
    });
  });

  group('حوار توليد كود النطاق المستقلّ', () {
    testWidgets('معاينة حيّة من الاسم والبريد وPlus Code',
        (WidgetTester tester) async {
      final FakeDomainRepository fake = FakeDomainRepository();
      await _pumpTab(tester, fake);

      await tester.tap(
        find.byKey(const ValueKey<String>('domain-generate-code')),
      );
      await tester.pumpAndSettle();
      expect(find.text('توليد كود نطاق'), findsOneWidget);
      expect(find.text('اكتب الاسم لعرض الكود'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey<String>('domain-generate-name-en')),
        'Maarra',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('domain-generate-postal')),
        '31951',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('domain-generate-plus')),
        '25GF+989',
      );
      await tester.pump();
      expect(find.text('MAA-31951-25GF989'), findsOneWidget);

      // التوليد لا يُنشئ نطاقاً.
      expect(fake.calls, isNot(contains('createDomain')));
    });
  });
}

/// يفتح تبويب النطاقات مباشرةً (مستودع وهمي) — بلا بوابة ولا شبكة.
Future<void> _pumpTab(
  WidgetTester tester,
  DomainRepository repository,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: DomainsManagerTab(repository: repository)),
    ),
  );
  await tester.pumpAndSettle();
}

/// نصّ داخل الحوار المفتوح فقط — لا يطابق زرّ الشريط خلفه.
Finder _dialogText(String text) => find.descendant(
  of: find.byType(AlertDialog),
  matching: find.text(text),
);

Future<void> _fillDomainForm(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey<String>('domain-name-ar')),
    'منشأة الأمراء',
  );
  await tester.enterText(
    find.byKey(const ValueKey<String>('domain-name-en')),
    'Maarra',
  );
  await tester.enterText(
    find.byKey(const ValueKey<String>('domain-gov')),
    'الغربية',
  );
  await tester.enterText(
    find.byKey(const ValueKey<String>('domain-center')),
    'ميت غمر',
  );
  await tester.enterText(
    find.byKey(const ValueKey<String>('domain-postal')),
    '31951',
  );
  await tester.enterText(
    find.byKey(const ValueKey<String>('domain-plus')),
    '25GF+989',
  );
  await tester.enterText(
    find.byKey(const ValueKey<String>('domain-lat')),
    '30.8124',
  );
  await tester.enterText(
    find.byKey(const ValueKey<String>('domain-lng')),
    '31.2345',
  );
  await tester.pump();
}
