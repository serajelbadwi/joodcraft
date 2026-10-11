/// نموذج قرية واحدة كما تُخزَّن في جدول `public.villages`.
///
/// القرية هي وحدة العزل في المشروع كله: كل الأعضاء يتبعون قرية واحدة، وكود
/// القرية هو البوابة الوحيدة للتسجيل. إضافة قرى جديدة لا تحتاج أي تعديل على
/// الكود — صف جديد في هذا الجدول يكفي.
library;

import 'package:flutter/foundation.dart';

@immutable
class Village {
  const Village({
    required this.id,
    required this.name,
    required this.code,
    this.createdAt,
  });

  /// معرّف القرية (uuid).
  final String id;

  /// اسم القرية كما يُعرض («منشأة الأمراء ومحلة حسن»).
  final String name;

  /// كود التسجيل (‎MAA-2026‎).
  final String code;

  /// لحظة الإنشاء.
  final DateTime? createdAt;

  /// بناء من صف PostgREST أو من JSON محلي — قراءة **متسامحة**: حقل ناقص لا
  /// يُسقِط العملية كلها.
  factory Village.fromRow(Map<String, dynamic> row) {
    final Object? rawDate = row['created_at'];
    return Village(
      id: '${row['id'] ?? ''}',
      name: '${row['name'] ?? ''}'.trim(),
      code: '${row['code'] ?? ''}'.trim(),
      createdAt: rawDate is DateTime
          ? rawDate
          : (rawDate is String ? DateTime.tryParse(rawDate) : null),
    );
  }

  /// هل الصف يحمل أقل ما يلزم لعرضه والاعتماد عليه؟
  bool get isUsable => id.isNotEmpty && name.isNotEmpty && code.isNotEmpty;

  Village copyWith({String? name, String? code}) => Village(
        id: id,
        name: name ?? this.name,
        code: code ?? this.code,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'code': code,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  @override
  String toString() => 'Village($code — $name)';
}
