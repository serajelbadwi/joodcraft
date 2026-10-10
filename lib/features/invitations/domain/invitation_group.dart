import 'package:flutter/material.dart' show IconData, Icons;

/// المجموعات الثلاث للدعوات والمناسبات.
///
/// كل مجموعة تجمع قوالبها في واجهة «الدعوات الشخصية» وتظهر كقسم مستقل في
/// المكتبة، ولكل منها مفتاح ترجمة في ملفات الـ arb (`invCategory*`).
enum InvitationGroup {
  ramadan(
    jsonValue: 'ramadan',
    labelAr: 'رمضان',
    labelKey: 'invCategoryRamadan',
    icon: Icons.nightlight_round,
    accentHex: '#C9A227',
  ),
  eid(
    jsonValue: 'eid',
    labelAr: 'عيد',
    labelKey: 'invCategoryEid',
    icon: Icons.celebration_rounded,
    accentHex: '#D4AF37',
  ),
  wedding(
    jsonValue: 'wedding',
    labelAr: 'زفاف',
    labelKey: 'invCategoryWedding',
    icon: Icons.favorite_rounded,
    accentHex: '#C08A5A',
  );

  const InvitationGroup({
    required this.jsonValue,
    required this.labelAr,
    required this.labelKey,
    required this.icon,
    required this.accentHex,
  });

  /// القيمة المخزّنة في JSON والحالة المحفوظة.
  final String jsonValue;

  /// الاسم العربي — يُستخدم احتياطياً حين تغيب الترجمة.
  final String labelAr;

  /// مفتاح الترجمة في arb.
  final String labelKey;

  final IconData icon;

  /// اللون المميّز للمجموعة (يظهر على بطاقة القالب).
  final String accentHex;

  /// المجموعة الدلالية في مكتبة القوالب (`TemplateCollection`).
  String get collectionName => jsonValue;

  static InvitationGroup? fromJson(String? value) {
    final String needle = (value ?? '').trim().toLowerCase();
    for (final InvitationGroup group in values) {
      if (group.jsonValue == needle || group.labelAr == needle) return group;
    }
    return null;
  }
}
