import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';

/// نموذج المستخدم داخل التطبيق.
///
/// لا نستخدم `User` من Supabase مباشرة في طبقة العرض أبداً: النموذج هنا يعزل
/// الواجهة عن مزوّد الخدمة، ويدمج بيانات `auth.users` مع سجل `public.profiles`.
class AppUser {
  const AppUser({
    required this.id,
    this.email,
    this.fullName,
    this.organizationName,
    this.subscriptionTier = SubscriptionTier.free,
    this.createdAt,
  });

  final String id;
  final String? email;
  final String? fullName;
  final String? organizationName;
  final SubscriptionTier subscriptionTier;
  final DateTime? createdAt;

  /// الاسم المعروض — يرجع إلى البريد إن لم يُسجَّل الاسم.
  String get displayName {
    final String? name = fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final String? mail = email;
    if (mail != null && mail.contains('@')) return mail.split('@').first;
    return 'مستخدم جودكرافت';
  }

  /// الحرفان الأولان للصورة الرمزية.
  String get initials {
    final List<String> parts = displayName
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'JC';
    if (parts.length == 1) {
      final String word = parts.first;
      return (word.length >= 2 ? word.substring(0, 2) : word).toUpperCase();
    }
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'
        .toUpperCase();
  }

  /// هل المؤسسة مسجّلة؟ (تظهر في ترويسة الشهادات لاحقاً)
  bool get hasOrganization =>
      organizationName != null && organizationName!.trim().isNotEmpty;

  /// بناء النموذج من مستخدم Supabase (البيانات المتوفرة فوراً من الجلسة).
  factory AppUser.fromSupabaseUser(User user) {
    final Map<String, dynamic> meta = user.userMetadata ?? <String, dynamic>{};
    return AppUser(
      id: user.id,
      email: user.email,
      fullName: (meta['full_name'] ?? meta['name']) as String?,
      organizationName: meta['organization_name'] as String?,
      subscriptionTier:
          SubscriptionTier.fromDb(meta['subscription_tier'] as String?),
      createdAt: DateTime.tryParse(user.createdAt),
    );
  }

  /// دمج بيانات سجل `public.profiles` (المصدر الأدق بعد إنشائه بالـ trigger).
  AppUser mergeProfile(Map<String, dynamic> row) {
    return AppUser(
      id: id,
      email: email,
      fullName: (row['full_name'] as String?) ?? fullName,
      organizationName:
          (row['organization_name'] as String?) ?? organizationName,
      subscriptionTier: SubscriptionTier.fromDb(
        row['subscription_tier'] as String?,
      ),
      createdAt:
          DateTime.tryParse('${row['created_at']}') ?? createdAt,
    );
  }

  AppUser copyWith({
    String? fullName,
    String? organizationName,
    SubscriptionTier? subscriptionTier,
  }) {
    return AppUser(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      organizationName: organizationName ?? this.organizationName,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      createdAt: createdAt,
    );
  }
}

/// نتيجة إنشاء حساب جديد.
class SignUpOutcome {
  const SignUpOutcome({
    required this.user,
    required this.requiresEmailConfirmation,
  });

  final AppUser user;

  /// صحيح عندما يكون تأكيد البريد مُفعّلاً في مشروع Supabase
  /// (لا توجد جلسة بعد، ويجب على المستخدم تأكيد بريده قبل الدخول).
  final bool requiresEmailConfirmation;
}
