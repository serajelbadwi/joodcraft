import 'dart:convert';
import 'dart:typed_data';

import '../constants/app_constants.dart';

/// أصل واحد من أصول المستخدم (شعار/ختم/توقيع/إطار).
///
/// مثل الخطوط المخصصة: يُحفظ محلياً بصيغة Base64 داخل ملف بيانات التطبيق
/// (`SharedPreferences`)، فلا يمرّ أي بايت عبر الشبكة، ويُستعاد عند بدء التشغيل.
class UserAsset {
  const UserAsset({
    required this.id,
    required this.type,
    required this.name,
    required this.fileName,
    required this.base64Data,
    this.mime = 'image/png',
    this.width,
    this.height,
    required this.addedAt,
  });

  /// معرّف فريد يُشار إليه من عنصر الصورة في القالب (`ImageSourceKind.userAsset`).
  final String id;

  final AssetType type;

  /// الاسم المعروض للمستخدم (قابل للتعديل).
  final String name;

  final String fileName;

  /// بايتات الصورة بترميز Base64 (بلا بادئة data URI).
  final String base64Data;

  final String mime;

  /// أبعاد الصورة الأصلية إن عُرفت (تُستخدم حين توفّرها بايتات الصورة).
  final int? width;
  final int? height;

  final DateTime addedAt;

  Uint8List get bytes => base64Decode(base64Data);

  /// الحجم التقريبي للصورة بعد فك الترميز.
  int get byteSize => base64Data.length * 3 ~/ 4;

  String get sizeLabel {
    final int kb = byteSize ~/ 1024;
    if (kb < 1024) return '$kb KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  String get typeLabelAr => type.labelAr;

  UserAsset copyWith({String? name, AssetType? type}) => UserAsset(
        id: id,
        type: type ?? this.type,
        name: name ?? this.name,
        fileName: fileName,
        base64Data: base64Data,
        mime: mime,
        width: width,
        height: height,
        addedAt: addedAt,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type.dbValue,
        'name': name,
        'file_name': fileName,
        'data': base64Data,
        'mime': mime,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        'added_at': addedAt.toIso8601String(),
      };

  /// قراءة آمنة من JSON؛ تعيد `null` لأي سجل تالف بدل إسقاط كل المكتبة.
  static UserAsset? fromJson(Object? json) {
    if (json is! Map) return null;
    final Object? id = json['id'];
    final Object? data = json['data'];
    if (id is! String || data is! String) return null;
    if (id.trim().isEmpty || data.trim().isEmpty) return null;
    return UserAsset(
      id: id,
      type: _typeFromDb('${json['type'] ?? ''}'),
      name: '${json['name'] ?? 'أصل بلا اسم'}',
      fileName: '${json['file_name'] ?? ''}',
      base64Data: data,
      mime: '${json['mime'] ?? 'image/png'}',
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      addedAt: DateTime.tryParse('${json['added_at']}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static AssetType _typeFromDb(String value) {
    for (final AssetType type in AssetType.values) {
      if (type.dbValue == value) return type;
    }
    return AssetType.logo;
  }

  static int _sequence = 0;

  /// معرّف فريد جديد.
  ///
  /// عدّاد متسلسل مع الطابع الزمني حتى لا يتصادم معرّفان عند رفع عدة صور في
  /// اللحظة نفسها (ساعة الجهاز قد لا تتقدّم بين إضافتين متتاليتين).
  static String newId() =>
      'asset_${DateTime.now().microsecondsSinceEpoch}_${++_sequence}';
}
