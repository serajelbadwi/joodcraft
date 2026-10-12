/// إعلان محلّي واحد كما يُخزَّن في جدول `public.local_ads`.
///
/// الإعلان ملك للقرية (`village_id`) ويظهر في صفحتها العامّة ما دام نشطاً
/// (`is_active`)؛ ونافذته الزمنية (`starts_at` ← `ends_at`) تُحسب في الواجهة
/// لعرض حالة الإعلان (مجدول/منتهي/نشط) بينما يبقى الحكم النهائي لسياسة
/// `ads_select_public` على السيرفر.
library;

import 'package:flutter/foundation.dart';

import 'google_drive_link.dart';

@immutable
class VillageAd {
  const VillageAd({
    required this.id,
    required this.villageId,
    required this.title,
    this.imageUrl,
    this.contactPhone,
    this.contactUrl,
    this.startsAt,
    this.endsAt,
    this.isActive = true,
    this.createdAt,
  });

  /// بناء من صف PostgREST — قراءة **متسامحة**: حقل ناقص لا يُسقط القائمة.
  ///
  /// رابط صورة Google Drive يُطبَّع هنا إلى صيغة مباشرة (`thumbnail…`)، فتُعرض
  /// الصورة سواء أُدخل الرابط قديماً بصفحة العرض أو حُفظ حديثاً مُطبَّعاً.
  factory VillageAd.fromRow(Map<String, dynamic> row) {
    final String imageUrl = '${row['image_url'] ?? ''}'.trim();
    final String phone = '${row['contact_phone'] ?? ''}'.trim();
    final String url = '${row['contact_url'] ?? ''}'.trim();
    return VillageAd(
      id: '${row['id'] ?? ''}',
      villageId: '${row['village_id'] ?? ''}',
      title: '${row['title'] ?? ''}'.trim(),
      imageUrl: normalizeGoogleDriveUrl(imageUrl),
      contactPhone: phone.isEmpty ? null : phone,
      contactUrl: url.isEmpty ? null : url,
      startsAt: _date(row['starts_at']),
      endsAt: _date(row['ends_at']),
      // غياب العمود يعني المفعَّل افتراضياً (المتوقع في الإدراج).
      isActive: row['is_active'] == null ? true : row['is_active'] == true,
      createdAt: _date(row['created_at']),
    );
  }

  /// معرّف الصف (uuid).
  final String id;

  /// القرية التابع لها الإعلان.
  final String villageId;

  /// عنوان الإعلان.
  final String title;

  /// رابط الصورة المرفوعة في الدلو العام (اختياري).
  final String? imageUrl;

  /// رقم هاتف للتواصل (اختياري).
  final String? contactPhone;

  /// رابط خارجي للتواصل (اختياري).
  final String? contactUrl;

  /// بداية النافذة الزمنية (افتراضياً لحظة الإنشاء في الجدول).
  final DateTime? startsAt;

  /// نهاية النافذة الزمنية (`null` ⇒ بلا انتهاء).
  final DateTime? endsAt;

  /// هل الإعلان مفعَّل؟
  final bool isActive;

  /// لحظة الإنشاء.
  final DateTime? createdAt;

  /// هل يقع [at] داخل نافذة عرض الإعلان (مفعَّل + بين البداية والنهاية)؟
  bool isActiveAt(DateTime at) {
    if (!isActive) return false;
    final DateTime? start = startsAt;
    if (start != null && at.isBefore(start)) return false;
    final DateTime? end = endsAt;
    if (end != null && at.isAfter(end)) return false;
    return true;
  }

  /// هل الإعلان سارٍ الآن؟
  bool get isLiveNow => isActiveAt(DateTime.now());

  /// حالة العرض للتبويب: منتهي ← مفعَّل (سارٍ) ← مجدول ← موقوف.
  String statusLabel(DateTime now) {
    if (!isActive) return VillageAdStatus.paused;
    final DateTime? start = startsAt;
    if (start != null && now.isBefore(start)) return VillageAdStatus.scheduled;
    final DateTime? end = endsAt;
    if (end != null && now.isAfter(end)) return VillageAdStatus.expired;
    return VillageAdStatus.live;
  }

  /// صف الإدراج أو التحديث — `id` لا يدخل الخريطة (يحدده السيرفر).
  Map<String, dynamic> toRow() => <String, dynamic>{
        'village_id': villageId,
        'title': title,
        'image_url': imageUrl,
        'contact_phone': contactPhone,
        'contact_url': contactUrl,
        'starts_at': startsAt?.toUtc().toIso8601String(),
        'ends_at': endsAt?.toUtc().toIso8601String(),
        'is_active': isActive,
      };

  @override
  String toString() => 'VillageAd($title — $villageId)';
}

/// تسميات حالة الإعلان — ثابتة لتُقارَن في الاختبارات وتُعرض في الواجهة.
abstract final class VillageAdStatus {
  const VillageAdStatus._();

  static const String live = 'سارٍ';
  static const String scheduled = 'مجدول';
  static const String expired = 'منتهٍ';
  static const String paused = 'موقوف';
}

/// قراءة تاريخ PostgREST (`ISO-8601`) أو قيمة `DateTime` — أو `null`.
DateTime? _date(Object? raw) {
  if (raw is DateTime) return raw;
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}
