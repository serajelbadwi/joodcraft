import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/features/auth/domain/app_user.dart';

void main() {
  const AppUser user = AppUser(
    id: 'u-1',
    email: 'abdullah@jood.org',
    fullName: 'عبدالله الأحمد',
  );

  group('AppUser', () {
    test('displayName يعود للاسم الكامل إن وُجد', () {
      expect(user.displayName, 'عبدالله الأحمد');
    });

    test('displayName يعود للبريد إن غاب الاسم', () {
      const AppUser withoutName = AppUser(id: 'u-2', email: 'khalid@jood.org');
      expect(withoutName.displayName, 'khalid');
    });

    test('displayName يستخدم نصاً افتراضياً بلا بيانات', () {
      const AppUser empty = AppUser(id: 'u-3');
      expect(empty.displayName, 'مستخدم جودكرافت');
    });

    test('initials يأخذ أول حرفين من الكلمتين الأوليين', () {
      expect(user.initials, 'عا');
    });

    test('mergeProfile يدمج بيانات السجل ويحتفظ بالبريد', () {
      final AppUser merged = user.mergeProfile(<String, dynamic>{
        'full_name': 'عبدالله بن أحمد',
        'organization_name': 'جمعية جود الخيرية',
        'subscription_tier': 'pro',
        'created_at': '2026-01-01T10:00:00Z',
      });

      expect(merged.fullName, 'عبدالله بن أحمد');
      expect(merged.organizationName, 'جمعية جود الخيرية');
      expect(merged.subscriptionTier, SubscriptionTier.pro);
      expect(merged.email, 'abdullah@jood.org');
      expect(merged.hasOrganization, isTrue);
    });

    test('mergeProfile يتجاهل القيم الفارغة ويُبقي الأصلية', () {
      final AppUser merged = user.mergeProfile(<String, dynamic>{
        'full_name': null,
        'subscription_tier': null,
      });

      expect(merged.fullName, 'عبدالله الأحمد');
      expect(merged.subscriptionTier, SubscriptionTier.free);
    });
  });

  group('SubscriptionTier', () {
    test('fromDb يتعرف على القيم ويعود للافتراضي عند المجهول', () {
      expect(SubscriptionTier.fromDb('pro'), SubscriptionTier.pro);
      expect(SubscriptionTier.fromDb('enterprise'), SubscriptionTier.enterprise);
      expect(SubscriptionTier.fromDb('غير-معروف'), SubscriptionTier.free);
      expect(SubscriptionTier.fromDb(null), SubscriptionTier.free);
    });
  });
}
