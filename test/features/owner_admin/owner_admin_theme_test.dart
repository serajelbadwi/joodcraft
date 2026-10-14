import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/theme/app_colors.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/features/owner_admin/domain/owner_models.dart';

import 'owner_admin_test_helpers.dart';

/// لوحة المالك كانت **المنطقة البيضاء الوحيدة** في تطبيق داكن: الشاشة
/// والتبويبان والحوارات كلها كانت تكتب ثوابت `AppColors` النهارية
/// (`background`/`navy`/`inkMuted`…) بلا أي مرجع للسطوع.
///
/// هذه الاختبارات تقفل الإصلاح: كل سطح في اللوحة يشتقّ من
/// `Theme.of(context)` فيتبع الوضع الليلي كما بقيّة JoodCraft.
void main() {
  group('إدارة المالك — الوضع الليلي', () {
    testWidgets('هيكل الشاشة يتبنّى سليت الوضع الليلي بلا بقية بيضاء',
        (WidgetTester tester) async {
      await pumpOwnerAdmin(
        tester,
        FakeOwnerAdminRepository(
          villages: <OwnerVillage>[seedVillage()],
          licenses: <OwnerLicense>[
            _license(isActive: true, months: 12),
          ],
        ),
        brightness: Brightness.dark,
      );

      final ThemeData dark = AppTheme.dark;
      final ColorScheme scheme = dark.colorScheme;

      final Scaffold scaffold = tester.widget<Scaffold>(
        find.byType(Scaffold).first,
      );
      expect(scaffold.backgroundColor, dark.scaffoldBackgroundColor);
      // الانحدار الذي أُصلح: خلفية نهارية ثابتة داخل تطبيق داكن.
      expect(scaffold.backgroundColor, isNot(AppColors.background));

      final AppBar appBar = tester.widget<AppBar>(
        find.byType(AppBar).first,
      );
      expect(appBar.backgroundColor, scheme.surface);
      expect(appBar.foregroundColor, scheme.onSurface);
      expect(appBar.backgroundColor, isNot(AppColors.navy));
    });

    testWidgets('ألوان شريط التبويبات من colorScheme', (WidgetTester tester) async {
      await pumpOwnerAdmin(
        tester,
        FakeOwnerAdminRepository(villages: <OwnerVillage>[seedVillage()]),
        brightness: Brightness.dark,
      );

      final ColorScheme scheme = AppTheme.dark.colorScheme;
      final TabBar tabBar = tester.widget<TabBar>(
        find.byType(TabBar).first,
      );
      expect(tabBar.indicatorColor, scheme.secondary);
      expect(tabBar.labelColor, scheme.onSurface);
      expect(tabBar.unselectedLabelColor, scheme.onSurfaceVariant);
    });

    testWidgets('بطاقة الترخيص وشارتها من colorScheme', (WidgetTester tester) async {
      await pumpOwnerAdmin(
        tester,
        FakeOwnerAdminRepository(
          villages: <OwnerVillage>[seedVillage()],
          licenses: <OwnerLicense>[_license(isActive: true, months: 12)],
        ),
        brightness: Brightness.dark,
      );
      await tester.tap(find.text('التراخيص'));
      await tester.pumpAndSettle();

      final ColorScheme scheme = AppTheme.dark.colorScheme;

      // شارة «مفعّل»: حاوية وخلفية من المظهر لا من ثوابت النجاح النهارية.
      final BoxDecoration badge = tester.widget<Container>(
        find.ancestor(
          of: find.text('مفعّل'),
          matching: find.byType(Container),
        ).first,
      ).decoration! as BoxDecoration;
      expect(badge.color, isNot(AppColors.successSoft));

      // النص الثانوي (التاريخ/المدة) يستعمل لون النص الثانوي للمظهر.
      final Text muted = tester.widget<Text>(
        find.textContaining('المدة:'),
      );
      expect(muted.style?.color, scheme.onSurfaceVariant);
      expect(muted.style?.color, isNot(AppColors.inkMuted));
    });

    testWidgets('بوابة الدخول تتبع الوضع الليلي أيضاً',
        (WidgetTester tester) async {
      await pumpOwnerGate(
        tester,
        FakeOwnerAdminRepository(isAdmin: false),
        brightness: Brightness.dark,
      );

      final ThemeData dark = AppTheme.dark;
      final Scaffold scaffold = tester.widget<Scaffold>(
        find.byType(Scaffold).first,
      );
      expect(scaffold.backgroundColor, dark.scaffoldBackgroundColor);
      expect(scaffold.backgroundColor, isNot(AppColors.background));

      final AppBar appBar = tester.widget<AppBar>(
        find.byType(AppBar).first,
      );
      expect(appBar.backgroundColor, dark.colorScheme.surface);
      expect(appBar.foregroundColor, dark.colorScheme.onSurface);
    });

    testWidgets('الوضع الفاتح لم يتغيّر — لا انحدار في الاتجاه الآخر',
        (WidgetTester tester) async {
      await pumpOwnerAdmin(
        tester,
        FakeOwnerAdminRepository(villages: <OwnerVillage>[seedVillage()]),
      );

      final ThemeData light = AppTheme.light;
      final Scaffold scaffold = tester.widget<Scaffold>(
        find.byType(Scaffold).first,
      );
      expect(scaffold.backgroundColor, light.scaffoldBackgroundColor);

      final AppBar appBar = tester.widget<AppBar>(
        find.byType(AppBar).first,
      );
      expect(appBar.backgroundColor, light.colorScheme.surface);
      expect(appBar.foregroundColor, light.colorScheme.onSurface);
    });
  });
}

OwnerLicense _license({
  required bool isActive,
  required int months,
}) => OwnerLicense(
  id: 'l1',
  code: 'FRH-MAA-001',
  villageId: 'v1',
  villageName: 'قرية التجارب',
  subscriberName: 'مكتب الأمل',
  subscriberPhone: '01001234567',
  months: months,
  isActive: isActive,
  createdAt: DateTime(2026, 10, 1),
);
