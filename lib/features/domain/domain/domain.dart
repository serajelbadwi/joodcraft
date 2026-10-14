/// نموذج النطاق — وحدة العزل الجديدة في JoodCraft، وهي «القرية» في المصطلح
/// القديم. كل ما يتبع نطاقاً واحداً (أعضاء، فيديوهات، إعلانات) يصير مثيلاً من
/// هذا النموذج؛ والكود هو بوابة التسجيل الوحيدة.
///
/// الكود يُولَّد تلقائياً في القاعدة من ثلاثة مدخلات: بادئة الاسم اللاتيني
/// (3 حروف) + الرمز البريدي (5 أرقام) + ما قبل/بعد علامة `+` في Plus Code
/// (7 أحرف بأقصاها) — مثل `MAA-31951-25GF989`.
library;

import 'package:flutter/foundation.dart';

/// نطاق واحد كما يُخزَّن في جدول `public.domains`.
@immutable
class Domain {
  const Domain({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.governorate,
    required this.center,
    required this.code,
    this.postalCode,
    this.plusCode,
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  /// معرّف النطاق (uuid).
  final String id;

  /// الاسم العربي — كما يُعرض في الواجهة.
  final String nameAr;

  /// الاسم الإنجليزي — أساس بادئة الكود.
  final String nameEn;

  /// المحافظة.
  final String governorate;

  /// المركز/القسم.
  final String center;

  /// الرمز البريدي المصري (5 أرقام).
  final String? postalCode;

  /// Google Plus Code كما كُتب (`25GF+989`).
  final String? plusCode;

  /// خط العرض — `null` إن لم تُرسل إحداثيات.
  final double? latitude;

  /// خط الطول — `null` إن لم تُرسل إحداثيات.
  final double? longitude;

  /// كود التسجيل المولَّد (`MAA-31951-25GF989`).
  final String code;

  /// لحظة الإنشاء.
  final DateTime? createdAt;

  /// هل للنطاق إحداثيات صالحة؟ (لا خط الاستواء/غرينتش كـ«غير محدد»)
  bool get hasCoordinates =>
      latitude != null && longitude != null && (latitude != 0 || longitude != 0);

  /// هل الصف يحمل أقل ما يلزم لعرضه والاعتماد عليه؟
  bool get isUsable =>
      id.isNotEmpty && nameAr.isNotEmpty && code.isNotEmpty;

  /// موقع مبسّط للعرض: «المحافظة • المركز» أو «—».
  String get locationLabel {
    final String location = <String>[
      if (governorate.isNotEmpty) governorate,
      if (center.isNotEmpty) center,
    ].join(' • ');
    return location.isEmpty ? '—' : location;
  }

  /// بناء من صف PostgREST أو JSON محلي — قراءة **متسامحة**: حقل ناقص لا
  /// يُسقِط العملية كلها. النصوص الفارغة تُطبَّع إلى `null` اختيارية.
  factory Domain.fromRow(Map<String, dynamic> row) {
    final Object? rawDate = row['created_at'];
    return Domain(
      id: '${row['id'] ?? ''}',
      nameAr: _blankToNull(row['name_ar']) ?? '',
      nameEn: _blankToNull(row['name_en']) ?? '',
      governorate: _blankToNull(row['governorate']) ?? '',
      center: _blankToNull(row['center']) ?? '',
      postalCode: _blankToNull(row['postal_code']),
      plusCode: _blankToNull(row['plus_code']),
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
      code: '${row['code'] ?? ''}'.trim().toUpperCase(),
      createdAt: rawDate is DateTime
          ? rawDate
          : (rawDate is String ? DateTime.tryParse(rawDate) : null),
    );
  }

  /// نصّ مُطبَّع أو `null` إن كان غائباً/فارغاً — الحقول الاختيارية في الصف
  /// لا تُخزَّن كنصوص فارغة.
  static String? _blankToNull(Object? value) {
    final String text = '${value ?? ''}'.trim();
    return text.isEmpty ? null : text;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name_ar': nameAr,
        'name_en': nameEn,
        'governorate': governorate,
        'center': center,
        'postal_code': postalCode,
        'plus_code': plusCode,
        'latitude': latitude,
        'longitude': longitude,
        'code': code,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  Domain copyWith({
    String? nameAr,
    String? nameEn,
    String? governorate,
    String? center,
    String? postalCode,
    String? plusCode,
    double? latitude,
    double? longitude,
    String? code,
    DateTime? createdAt,
  }) => Domain(
        id: id,
        nameAr: nameAr ?? this.nameAr,
        nameEn: nameEn ?? this.nameEn,
        governorate: governorate ?? this.governorate,
        center: center ?? this.center,
        postalCode: postalCode ?? this.postalCode,
        plusCode: plusCode ?? this.plusCode,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        code: code ?? this.code,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) =>
      other is Domain && other.id == id && other.code == code;

  @override
  int get hashCode => Object.hash(id, code);

  @override
  String toString() => 'Domain($code — $nameAr)';
}
