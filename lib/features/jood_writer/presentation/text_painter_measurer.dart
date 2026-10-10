import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/flow_paginator.dart';
import '../domain/jood_writer_block.dart';
import 'jood_writer_text_styles.dart';

/// يقيس الكتل بـ`TextPainter` عند عرض محتوى معيّن — التنفيذ الحقيقي لواجهة
/// [BlockMeasurer] الذي يستهلكه [FlowPaginator] في المعاينة والطباعة.
///
/// القياس والرسم يستخدمان **نفس** [JoodWriterTextStyles] ونفس العرض والاتجاه،
/// فيتطابق عدد الأسطر المحسوب مع المرسوم تماماً.
class TextPainterBlockMeasurer implements BlockMeasurer {
  TextPainterBlockMeasurer({
    required this.contentWidth,
    this.scale = 1,
    this.textScaler = TextScaler.noScaling,
    this.textDirection = TextDirection.rtl,
    this.fontFamily,
    this.fontFamilyFallback,
  });

  final double contentWidth;
  final double scale;

  /// مقياس تكبير النص **الفعّال** (من `MediaQuery`): تكبير نظام التشغيل أو
  /// اليدوي. يُمرَّر إلى `TextPainter` نفسه، فيتطابق عدد الأسطر وارتفاعها
  /// مع الرسم حرفياً — وإلا قيس نصٌّ أصغر ممّا يُرسم فتفيض الصفحة.
  final TextScaler textScaler;
  final TextDirection textDirection;
  final String? fontFamily;
  final List<String>? fontFamilyFallback;

  TextStyle _styleOf(JoodWriterBlock block) {
    final TextStyle base = JoodWriterTextStyles.of(block, scale: scale);
    if (fontFamily == null && fontFamilyFallback == null) return base;
    return base.copyWith(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
    );
  }

  /// عرض السطر المتاح لهذه الكتلة: عرض المحتوى ناقص الإزاحة الكاملة، وناقص
  /// إزاحة السطر الأول (يقيس المحرّر نفسه مع `prefix` لكل الأسطر)، وناقص
  /// مقدمة القائمة (إن وُجدت). قياسٌ **محافظ**: الأسطر المرسومة لا تطول أبداً
  /// على مُقاسها، فلا يزيد ارتفاع الكتلة عن المحسوب ولا يفيض إطار الصفحة.
  double _lineWidthOf(JoodWriterBlock block) {
    // نسبة تكبير النص: مقدمة القائمة (• / 12.) تُرسم بخط مكبّر ⇒ عرضها
    // المخصّص يتكبّر معها، فتُخصم بالحجم المرسوم لا بالمحسوب.
    final double fontSize = JoodWriterTextStyles.fontSizeOf(block);
    final double ratio = fontSize > 0
        ? textScaler.scale(fontSize) / fontSize
        : 1;
    final double used =
        JoodWriterTextStyles.indentPx(block, scale: scale) +
        JoodWriterTextStyles.firstLineIndentPx(block, scale: scale) +
        JoodWriterTextStyles.listPrefixWidth(block, scale: scale) * ratio;
    return math.max(contentWidth - used, 8.0);
  }

  TextPainter _layout(JoodWriterBlock block) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: block.text.isEmpty ? ' ' : block.text,
        style: _styleOf(block),
      ),
      textDirection: textDirection,
      textAlign: JoodWriterTextStyles.textAlign(block.align),
      // نفس مقياس تكبير النص الذي يُطبَّق في الرسم: القياس والعرض توأمان.
      textScaler: textScaler,
    )..layout(maxWidth: _lineWidthOf(block));
    return painter;
  }

  @override
  List<String> linesOf(JoodWriterBlock block) {
    if (block.text.isEmpty) return const <String>[''];
    final TextPainter painter = _layout(block);
    final List<String> lines = <String>[];
    final int length = block.text.length;
    int start = 0;
    while (start < length) {
      final TextRange range = painter.getLineBoundary(
        TextPosition(offset: start),
      );
      final int end = range.end.clamp(start, length);
      lines.add(block.text.substring(start, end));
      if (end <= start) break; // حماية من حلقة لا نهائية.
      start = end;
    }
    if (lines.isEmpty) lines.add('');
    return lines;
  }

  @override
  double lineHeightOf(JoodWriterBlock block) =>
      _layout(block).preferredLineHeight;

  @override
  double spacingBeforeOf(JoodWriterBlock block) => block.spaceBefore * scale;

  @override
  double spacingAfterOf(JoodWriterBlock block) => block.spaceAfter * scale;
}
