import 'dart:typed_data';

/// صورة موضوعة على صفحة معيّنة داخل مستند «جود كاتب».
class WriterImage {
  const WriterImage({
    required this.pageIndex,
    required this.xMm,
    required this.yMm,
    required this.widthMm,
    required this.heightMm,
    this.bytes,
    this.assetPath,
    this.label = '',
  });

  /// فهرس الصفحة (يبدأ من 0).
  final int pageIndex;

  /// الموقع والأبعاد بالمليمتر داخل الصفحة.
  final double xMm;
  final double yMm;
  final double widthMm;
  final double heightMm;

  /// بيانات الصورة الخام — تُستخدم عند التضمين المباشر.
  final Uint8List? bytes;

  /// مسار مورد الصورة — بديل للبيانات الخام.
  final String? assetPath;

  /// تسمية وصفية.
  final String label;

  WriterImage copyWith({
    int? pageIndex,
    double? xMm,
    double? yMm,
    double? widthMm,
    double? heightMm,
    Uint8List? bytes,
    String? assetPath,
    String? label,
  }) {
    return WriterImage(
      pageIndex: pageIndex ?? this.pageIndex,
      xMm: xMm ?? this.xMm,
      yMm: yMm ?? this.yMm,
      widthMm: widthMm ?? this.widthMm,
      heightMm: heightMm ?? this.heightMm,
      bytes: bytes ?? this.bytes,
      assetPath: assetPath ?? this.assetPath,
      label: label ?? this.label,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'page': pageIndex,
    'x': xMm,
    'y': yMm,
    'w': widthMm,
    'h': heightMm,
    if (assetPath != null) 'asset': assetPath,
    if (label.isNotEmpty) 'label': label,
    // bytes ليست قابلة للتسلسل مباشرة — تُخزّن في ملف خارجي.
  };

  static WriterImage fromJson(Map<String, dynamic> json) {
    return WriterImage(
      pageIndex: json['page'] as int? ?? 0,
      xMm: (json['x'] as num?)?.toDouble() ?? 0,
      yMm: (json['y'] as num?)?.toDouble() ?? 0,
      widthMm: (json['w'] as num?)?.toDouble() ?? 40,
      heightMm: (json['h'] as num?)?.toDouble() ?? 30,
      assetPath: json['asset'] as String?,
      label: json['label'] as String? ?? '',
    );
  }
}
