/// نماذج لوحة تحكم المالك: القرى والتراخيص.
library;

import 'package:flutter/foundation.dart';

/// قرية كما تراها لوحة المالك — مع عدد الأعضاء المحسوب من `members`.
@immutable
class OwnerVillage {
  const OwnerVillage({
    required this.id,
    required this.name,
    required this.code,
    this.nameEn,
    this.governorate,
    this.center,
    this.memberCount = 0,
  });

  final String id;
  final String name;

  /// الاسم اللاتيني (أساس بادئة الكود).
  final String? nameEn;

  /// الكود بصيغته الحالية — `AAA-YYYY` أو صيغة اللوحة الجديدة.
  final String code;
  final String? governorate;
  final String? center;
  final int memberCount;

  /// صفّا `villages` — الأعمدة الجديدة قد تغيب قبل تشغيل قسم 20 من SQL،
  /// فتقرأ اختيارية بسلام.
  factory OwnerVillage.fromRow(Map<String, dynamic> row) => OwnerVillage(
    id: '${row['id']}',
    name: '${row['name'] ?? ''}',
    nameEn: row['name_en'] as String?,
    code: '${row['code'] ?? ''}',
    governorate: row['governorate'] as String?,
    center: row['center'] as String?,
  );

  OwnerVillage copyWith({
    String? name,
    String? nameEn,
    String? code,
    String? governorate,
    String? center,
    int? memberCount,
  }) => OwnerVillage(
    id: id,
    name: name ?? this.name,
    nameEn: nameEn ?? this.nameEn,
    code: code ?? this.code,
    governorate: governorate ?? this.governorate,
    center: center ?? this.center,
    memberCount: memberCount ?? this.memberCount,
  );

  @override
  bool operator ==(Object other) => other is OwnerVillage && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// ترخيص «صاحب الفرح» كما يصدره مالك المنصّة.
@immutable
class OwnerLicense {
  const OwnerLicense({
    required this.id,
    required this.code,
    required this.villageId,
    this.villageName,
    this.subscriberName,
    this.subscriberPhone,
    this.months,
    this.isActive = false,
    this.createdAt,
  });

  final String id;

  /// الكود المُصدر: `FRH-MAA-001`.
  final String code;
  final String villageId;
  final String? villageName;
  final String? subscriberName;
  final String? subscriberPhone;

  /// المدة بالأشهر (1 أو 3 أو 12).
  final int? months;
  final bool isActive;
  final DateTime? createdAt;

  /// صفّا `farah_licenses` (أعمدة قسم 20 اختيارية قبل تشغيله).
  factory OwnerLicense.fromRow(Map<String, dynamic> row) {
    final Object? created = row['created_at'];
    return OwnerLicense(
      id: '${row['id']}',
      code: '${row['code'] ?? ''}',
      villageId: '${row['village_id'] ?? ''}',
      subscriberName: row['subscriber_name'] as String?,
      subscriberPhone: row['subscriber_phone'] as String?,
      months: (row['months'] as num?)?.toInt(),
      isActive: row['is_active'] == true,
      createdAt: created is String ? DateTime.tryParse(created) : null,
    );
  }

  /// ملصق المدة للعرض (`1` ⇒ «شهر»، `3` ⇒ «3 شهور»، `12` ⇒ «سنة»).
  String get durationLabel => switch (months) {
    1 => 'شهر',
    3 => '3 شهور',
    12 => 'سنة',
    null => '—',
    final int? other => '$other شهراً',
  };

  OwnerLicense copyWith({String? villageName}) => OwnerLicense(
    id: id,
    code: code,
    villageId: villageId,
    villageName: villageName ?? this.villageName,
    subscriberName: subscriberName,
    subscriberPhone: subscriberPhone,
    months: months,
    isActive: isActive,
    createdAt: createdAt,
  );

  @override
  bool operator ==(Object other) => other is OwnerLicense && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// خطأ مُترجم ترفعه مستودعات اللوحة — رسالته عربية جاهزة للعرض.
class OwnerAdminException implements Exception {
  const OwnerAdminException(this.message);

  final String message;

  @override
  String toString() => message;
}
