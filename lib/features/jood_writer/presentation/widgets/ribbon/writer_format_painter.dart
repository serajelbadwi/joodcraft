/// «العصا السحرية» (Format Painter) — نسخ تنسيق الكتلة النشطة إلى كتل أخرى.
///
/// سلوك وورد المطلوب:
/// * ضغطة واحدة = نسخ إلى **كتلة واحدة** ثم يعود للطفيل (on).
/// * ضغطتان = النسخ المستمر حتى الضغطة الثالثة (locked).
/// * ضغطة ثالثة (أو أي ضغطة على زر بوضع on) = الإنهاء (off).
///
/// التطبيق يتم داخل الشريط لا داخل الـController: يستمع إلى إشارة الكتلة
/// النشطة، وحين يكون المصباح مُشعلًا ويتحقّق تحرير كتلة جديدة، ينسخ تنسيق
/// الكتلة المُلتقطة إليها ويُطفئ المصباح إن كان وضع «مرة واحدة».
library;

import 'package:flutter/foundation.dart';

import '../../../domain/jood_writer_block.dart';
import '../../writer_document_controller.dart';

enum WriterPainterMode {
  /// مطفأ — لا ينسخ شيئاً.
  off,

  /// ضغطة واحدة: ينسخ إلى الكتلة التالية ثم ينطفئ.
  once,

  /// ضغطتان: نسخ مستمر حتى الضغطة الثالثة.
  locked,
}

class WriterFormatPainter extends ChangeNotifier {
  WriterFormatPainter(this._controller) {
    _activeListener = _onActiveBlockChanged;
    _controller.activeBlockSignal.addListener(_activeListener);
  }

  final WriterDocumentController _controller;
  late final VoidCallback _activeListener;

  WriterPainterMode _mode = WriterPainterMode.off;

  /// التنسيق المُلتقط (خط وحجم ولون…) — كتلة كاملة يُدمج نموذجها على الهدف.
  JoodWriterBlock? _captured;

  /// كتلة النشاط وقت الالتقاط — لمنع النسخ عليها نفسها.
  int? _sourceIndex;

  WriterPainterMode get mode => _mode;
  bool get isActive => _mode != WriterPainterMode.off;
  JoodWriterBlock? get captured => _captured;

  /// الضغطة على زر العصا: مطفأ ← التقاط ← نسخ مستمر ← مطفأ.
  void press() {
    switch (_mode) {
      case WriterPainterMode.off:
        final JoodWriterBlock? block = _controller.activeBlock;
        if (block == null) return;
        _captured = block;
        _sourceIndex = _controller.activeBlockIndex;
        _mode = WriterPainterMode.once;
      case WriterPainterMode.once:
        // ضغطة ثانية بوضع «مرة واحدة» = تثبيت النسخ المستمر.
        _mode = WriterPainterMode.locked;
      case WriterPainterMode.locked:
        _cancel();
        return;
    }
    notifyListeners();
  }

  /// إنهاء يدوي (زر الإلغاء أو الضغطة الثالثة).
  void cancel() {
    if (_mode == WriterPainterMode.off) return;
    _cancel();
  }

  void _cancel() {
    _mode = WriterPainterMode.off;
    _captured = null;
    _sourceIndex = null;
    notifyListeners();
  }

  void _onActiveBlockChanged() {
    if (_mode == WriterPainterMode.off) return;
    final int index = _controller.activeBlockIndex;
    final JoodWriterBlock? target = _controller.activeBlock;
    final JoodWriterBlock? style = _captured;
    if (target == null || style == null) return;
    if (index == _sourceIndex) return; // ما زلنا على الكتلة المصدر.

    // نسخ التنسيق فقط — النصّ يبقى كما هو.
    _controller.updateActiveBlock(
      target.copyWith(
        kind: style.kind,
        fontFamily: style.fontFamily,
        clearFontFamily: style.fontFamily == null,
        fontSize: style.fontSize,
        clearFontSize: style.fontSize == null,
        fontColor: style.fontColor,
        clearFontColor: style.fontColor == null,
        isBold: style.isBold,
        isItalic: style.isItalic,
        isUnderline: style.isUnderline,
        isStrikethrough: style.isStrikethrough,
        highlightColor: style.highlightColor,
        clearHighlight: style.highlightColor == null,
        lineSpacing: style.lineSpacing,
        spaceBefore: style.spaceBefore,
        spaceAfter: style.spaceAfter,
        indentCm: style.indentCm,
        firstLineIndentCm: style.firstLineIndentCm,
      ),
    );
    _sourceIndex = index;
    if (_mode == WriterPainterMode.once) {
      _mode = WriterPainterMode.off;
      _captured = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _controller.activeBlockSignal.removeListener(_activeListener);
    super.dispose();
  }
}
