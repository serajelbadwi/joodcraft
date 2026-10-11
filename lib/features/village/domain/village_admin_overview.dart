/// صف إحصائي واحد لشاشة لوحة التحكم: قرية + عدّاداتها.
///
/// يأتي من دالة `admin_overview()` على السيرفر (نداء واحد يعيد كل القرى
/// بعداداتها) فلا تُضرب الشاشة في استعلامات لكل قرية.
library;

import 'package:flutter/foundation.dart';

import 'village.dart';

@immutable
class VillageAdminOverview {
  const VillageAdminOverview({
    required this.village,
    required this.membersCount,
    required this.videosCount,
    required this.activeAdsCount,
  });

  /// بناء من صف دالة `admin_overview()` — أسماء أعمدتها `village_*` مميّزة.
  factory VillageAdminOverview.fromRow(Map<String, dynamic> row) {
    return VillageAdminOverview(
      village: Village(
        id: '${row['village_id'] ?? ''}',
        name: '${row['village_name'] ?? ''}'.trim(),
        code: '${row['village_code'] ?? ''}'.trim(),
        createdAt: _date(row['created_at']),
      ),
      membersCount: _count(row['members_count']),
      videosCount: _count(row['videos_count']),
      activeAdsCount: _count(row['active_ads_count']),
    );
  }

  /// القرية وبياناتها.
  final Village village;

  /// عدد الأعضاء المسجَّلين.
  final int membersCount;

  /// عدد فيديوهاتها (منشورة أو مجدولة).
  final int videosCount;

  /// عدد إعلاناتها المفعَّلة.
  final int activeAdsCount;

  @override
  String toString() =>
      'VillageAdminOverview(${village.name}: $membersCount/$videosCount/$activeAdsCount)';
}

/// عدّاد PostgREST قد يعود `int` أو `num` أو نصّاً — يُوحَّد إلى `int`.
int _count(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return int.tryParse('${raw ?? ''}'.trim()) ?? 0;
}

/// قراءة تاريخ PostgREST (`ISO-8601`) أو قيمة `DateTime` — أو `null`.
DateTime? _date(Object? raw) {
  if (raw is DateTime) return raw;
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}
