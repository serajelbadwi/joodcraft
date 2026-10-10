import 'package:flutter/material.dart';

/// نوع الشكل الهندسي.
enum WriterShapeKind {
  rectangle('مستطيل', 'rect'),
  circle('دائرة', 'circle'),
  line('خط', 'line'),
  arrow('سهم', 'arrow');

  const WriterShapeKind(this.labelAr, this.jsonValue);
  final String labelAr;
  final String jsonValue;

  static WriterShapeKind fromJson(String? value) {
    for (final WriterShapeKind kind in values) {
      if (kind.jsonValue == value) return kind;
    }
    return WriterShapeKind.rectangle;
  }
}

/// شكل هندسي موضوع على صفحة معيّنة داخل مستند «جود كاتب».
class WriterShape {
  const WriterShape({
    required this.kind,
    required this.pageIndex,
    required this.xMm,
    required this.yMm,
    required this.widthMm,
    required this.heightMm,
    this.strokeColor = Colors.black,
    this.fillColor,
    this.strokeWidth = 1.5,
  });

  final WriterShapeKind kind;

  /// فهرس الصفحة (يبدأ من 0).
  final int pageIndex;

  /// الموقع والأبعاد بالمليمتر داخل الصفحة.
  final double xMm;
  final double yMm;
  final double widthMm;
  final double heightMm;

  /// لون الحد.
  final Color strokeColor;

  /// لون التعبئة — `null` = بلا تعبئة.
  final Color? fillColor;

  /// سمك الحد.
  final double strokeWidth;

  WriterShape copyWith({
    WriterShapeKind? kind,
    int? pageIndex,
    double? xMm,
    double? yMm,
    double? widthMm,
    double? heightMm,
    Color? strokeColor,
    Color? fillColor,
    bool clearFill = false,
    double? strokeWidth,
  }) {
    return WriterShape(
      kind: kind ?? this.kind,
      pageIndex: pageIndex ?? this.pageIndex,
      xMm: xMm ?? this.xMm,
      yMm: yMm ?? this.yMm,
      widthMm: widthMm ?? this.widthMm,
      heightMm: heightMm ?? this.heightMm,
      strokeColor: strokeColor ?? this.strokeColor,
      fillColor: clearFill ? null : (fillColor ?? this.fillColor),
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'kind': kind.jsonValue,
    'page': pageIndex,
    'x': xMm,
    'y': yMm,
    'w': widthMm,
    'h': heightMm,
    'stroke': strokeColor.toARGB32(),
    if (fillColor != null) 'fill': fillColor!.toARGB32(),
    'strokeWidth': strokeWidth,
  };

  static WriterShape fromJson(Map<String, dynamic> json) {
    return WriterShape(
      kind: WriterShapeKind.fromJson(json['kind'] as String?),
      pageIndex: json['page'] as int? ?? 0,
      xMm: (json['x'] as num?)?.toDouble() ?? 0,
      yMm: (json['y'] as num?)?.toDouble() ?? 0,
      widthMm: (json['w'] as num?)?.toDouble() ?? 40,
      heightMm: (json['h'] as num?)?.toDouble() ?? 30,
      strokeColor: json['stroke'] is int
          ? Color(json['stroke'] as int)
          : Colors.black,
      fillColor: json['fill'] is int ? Color(json['fill'] as int) : null,
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 1.5,
    );
  }
}
