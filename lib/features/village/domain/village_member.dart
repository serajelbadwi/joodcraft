/// نموذج العضو (المزارع المسجَّل) في جدول `public.members`.
///
/// تاريخ الميلاد والسن **مشتقّان من الرقم القومي** لا من إدخال المستخدم، ويُعاد
/// التحقق منهما على السيرفر عند الإدراج (دالة `village_register_member`).
library;

import 'package:flutter/foundation.dart';

import 'national_id.dart';

@immutable
class VillageMember {
  const VillageMember({
    required this.id,
    required this.villageId,
    required this.name,
    required this.phone,
    required this.nationalId,
    required this.birthDate,
    required this.age,
    this.createdAt,
  });

  /// معرّف العضو (uuid).
  final String id;

  /// القرية التابع لها.
  final String villageId;

  /// الاسم بالكامل.
  final String name;

  /// رقم التليفون (11 رقماً يبدأ بـ 01).
  final String phone;

  /// الرقم القومي (14 رقماً).
  final String nationalId;

  /// تاريخ الميلاد المستخرج من الرقم القومي.
  final DateTime birthDate;

  /// السن بالسنوات الكاملة لحظة التسجيل.
  final int age;

  final DateTime? createdAt;

  /// يبني عضو تسجيل جديد من بيانات النموذج + الرقم القومي المُتحقَّق منه.
  factory VillageMember.newRegistration({
    required String villageId,
    required String name,
    required String phone,
    required EgyptianNationalId nationalId,
  }) =>
      VillageMember(
        id: '',
        villageId: villageId,
        name: name.trim(),
        phone: NationalIdValidator.normalize(phone),
        nationalId: nationalId.digits,
        birthDate: nationalId.birthDate,
        age: nationalId.age,
      );

  /// بناء من صف PostgREST — متسامح مع الحقول الناقصة.
  factory VillageMember.fromRow(Map<String, dynamic> row) {
    final DateTime? birth = _parseDate(row['birth_date']);
    final int? parsedAge = int.tryParse('${row['age'] ?? ''}');
    return VillageMember(
      id: '${row['id'] ?? ''}',
      villageId: '${row['village_id'] ?? ''}',
      name: '${row['name'] ?? ''}',
      phone: '${row['phone'] ?? ''}',
      nationalId: '${row['national_id'] ?? ''}',
      birthDate: birth ?? DateTime(1900),
      age: parsedAge ?? (birth == null ? 0 : NationalIdValidator.ageAt(birth, DateTime.now())),
      createdAt: _parseDate(row['created_at']),
    );
  }

  /// صف الإدراج في قاعدة البيانات (أسماء الأعمدة كما في SQL).
  Map<String, dynamic> toRow() => <String, dynamic>{
        'village_id': villageId,
        'name': name,
        'phone': phone,
        'national_id': nationalId,
        'birth_date': _dateOnly(birthDate),
        'age': age,
      };

  Map<String, dynamic> toJson() => <String, dynamic>{
        ...toRow(),
        if (id.isNotEmpty) 'id': id,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  static String _dateOnly(DateTime date) {
    final String y = date.year.toString().padLeft(4, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime? _parseDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  String toString() => 'VillageMember($name — $phone)';
}
