import 'dart:convert';

import 'package:flutter/material.dart';

enum JoodWriterBlockKind {
  heading1('عنوان رئيسي', 'h1'),
  heading2('عنوان فرعي', 'h2'),
  paragraph('فقرة', 'p'),
  bullet('نقطة', 'bullet'),
  numbered('مرقمة', 'numbered');

  const JoodWriterBlockKind(this.labelAr, this.jsonValue);

  final String labelAr;
  final String jsonValue;

  static JoodWriterBlockKind fromJson(String? value) {
    for (final JoodWriterBlockKind kind in values) {
      if (kind.jsonValue == value) return kind;
    }
    return JoodWriterBlockKind.paragraph;
  }

  bool get isHeading =>
      this == JoodWriterBlockKind.heading1 ||
      this == JoodWriterBlockKind.heading2;
}

enum JoodWriterAlign {
  start('بداية', 'start'),
  center('وسط', 'center'),
  end('نهاية', 'end'),
  justify('ضبط', 'justify');

  const JoodWriterAlign(this.labelAr, this.jsonValue);
  final String labelAr;
  final String jsonValue;

  static JoodWriterAlign fromJson(String? value) {
    for (final JoodWriterAlign align in values) {
      if (align.jsonValue == value) return align;
    }
    return JoodWriterAlign.start;
  }
}

class JoodWriterBlock {
  /// المسافة البادئة الافتراضية للسطر الأول في الفقرات الجديدة (سنتيمتر).
  static const double defaultFirstLineIndentCm = 0.5;

  const JoodWriterBlock({
    required this.text,
    this.kind = JoodWriterBlockKind.paragraph,
    this.align = JoodWriterAlign.start,
    this.fontFamily,
    this.fontSize,
    this.fontColor,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.highlightColor,
    this.lineSpacing = 1.5,
    this.spaceBefore = 0.0,
    this.spaceAfter = 8.0,
    this.indentCm = 0.0,
    this.firstLineIndentCm = 0.0,
    this.pageBreakBefore = false,
  });

  final String text;
  final JoodWriterBlockKind kind;
  final JoodWriterAlign align;
  final String? fontFamily;
  final double? fontSize;
  final Color? fontColor;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final Color? highlightColor;

  /// المستجدات لتطابق MS Word:
  final double lineSpacing;
  final double spaceBefore;
  final double spaceAfter;
  final double indentCm; // المسافة البادئة بالسنتيمتر
  final double firstLineIndentCm; // المسافة البادئة للسطر الأول

  /// فاصل صفحات يدوي: تبدأ هذه الكتلة صفحة جديدة **دائماً** مهما بقي مساحة
  /// في الصفحة السابقة — كزر «فاصل صفحات» في وورد.
  final bool pageBreakBefore;

  bool get isBlank => text.trim().isEmpty;

  JoodWriterBlock copyWith({
    String? text,
    JoodWriterBlockKind? kind,
    JoodWriterAlign? align,
    String? fontFamily,
    bool clearFontFamily = false,
    double? fontSize,
    bool clearFontSize = false,
    Color? fontColor,
    bool clearFontColor = false,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    Color? highlightColor,
    bool clearHighlight = false,
    double? lineSpacing,
    double? spaceBefore,
    double? spaceAfter,
    double? indentCm,
    double? firstLineIndentCm,
    bool? pageBreakBefore,
  }) {
    return JoodWriterBlock(
      text: text ?? this.text,
      kind: kind ?? this.kind,
      align: align ?? this.align,
      fontFamily: clearFontFamily ? null : (fontFamily ?? this.fontFamily),
      fontSize: clearFontSize ? null : (fontSize ?? this.fontSize),
      fontColor: clearFontColor ? null : (fontColor ?? this.fontColor),
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      highlightColor: clearHighlight
          ? null
          : (highlightColor ?? this.highlightColor),
      lineSpacing: lineSpacing ?? this.lineSpacing,
      spaceBefore: spaceBefore ?? this.spaceBefore,
      spaceAfter: spaceAfter ?? this.spaceAfter,
      indentCm: indentCm ?? this.indentCm,
      firstLineIndentCm: firstLineIndentCm ?? this.firstLineIndentCm,
      pageBreakBefore: pageBreakBefore ?? this.pageBreakBefore,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'text': text,
    'kind': kind.jsonValue,
    'align': align.jsonValue,
    if (fontFamily != null) 'fontFamily': fontFamily,
    if (fontSize != null) 'fontSize': fontSize,
    if (fontColor != null) 'fontColor': fontColor!.toARGB32(),
    if (isBold) 'bold': true,
    if (isItalic) 'italic': true,
    if (isUnderline) 'underline': true,
    if (highlightColor != null) 'highlightColor': highlightColor!.toARGB32(),
    'lineSpacing': lineSpacing,
    'spaceBefore': spaceBefore,
    'spaceAfter': spaceAfter,
    'indentCm': indentCm,
    'firstLineIndentCm': firstLineIndentCm,
    if (pageBreakBefore) 'pageBreakBefore': true,
  };

  static JoodWriterBlock fromJson(Map<String, dynamic> json) {
    return JoodWriterBlock(
      text: json['text'] as String? ?? '',
      kind: JoodWriterBlockKind.fromJson(json['kind'] as String?),
      align: JoodWriterAlign.fromJson(json['align'] as String?),
      fontFamily: json['fontFamily'] as String?,
      fontSize: (json['fontSize'] as num?)?.toDouble(),
      fontColor: json['fontColor'] is int
          ? Color(json['fontColor'] as int)
          : null,
      isBold: json['bold'] as bool? ?? false,
      isItalic: json['italic'] as bool? ?? false,
      isUnderline: json['underline'] as bool? ?? false,
      highlightColor: json['highlightColor'] is int
          ? Color(json['highlightColor'] as int)
          : null,
      lineSpacing: (json['lineSpacing'] as num?)?.toDouble() ?? 1.5,
      spaceBefore: (json['spaceBefore'] as num?)?.toDouble() ?? 0.0,
      spaceAfter: (json['spaceAfter'] as num?)?.toDouble() ?? 8.0,
      indentCm: (json['indentCm'] as num?)?.toDouble() ?? 0.0,
      firstLineIndentCm: (json['firstLineIndentCm'] as num?)?.toDouble() ?? 0.0,
      pageBreakBefore: json['pageBreakBefore'] as bool? ?? false,
    );
  }

  static String encodeList(List<JoodWriterBlock> blocks) =>
      jsonEncode(<dynamic>[for (final JoodWriterBlock b in blocks) b.toJson()]);

  static List<JoodWriterBlock> decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return <JoodWriterBlock>[];
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return <JoodWriterBlock>[];
      return <JoodWriterBlock>[
        for (final Object? entry in decoded)
          if (entry is Map)
            JoodWriterBlock.fromJson(Map<String, dynamic>.from(entry)),
      ];
    } catch (_) {
      return <JoodWriterBlock>[];
    }
  }
}
