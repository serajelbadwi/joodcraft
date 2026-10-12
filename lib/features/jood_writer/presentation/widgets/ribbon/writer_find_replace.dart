/// البحث والاستبدال في مستند «جود كاتب» — منطق خالص قابل للاختبار بلا واجهة.
///
/// المستند بنموذج كتل: كل كتلة نصّ واحد. البحث يمسح كل الكتل ويجمع مواضع
/// التطابق (كتلة + إزاحة)؛ والاستبدال يُنفَّذ على الكتل مباشرة عبر
/// `setActiveBlock` + `updateActiveBlock` من الـController.
library;

import 'package:flutter/foundation.dart';

import '../../../domain/jood_writer_block.dart';
import '../../writer_document_controller.dart';

/// تطابق واحد: فهرس الكتلة + موضع البداية + طول المطابقة.
class WriterFindMatch {
  const WriterFindMatch({
    required this.blockIndex,
    required this.start,
    required this.length,
  });

  final int blockIndex;
  final int start;
  final int length;

  String textOf(List<JoodWriterBlock> blocks) =>
      blocks[blockIndex].text.substring(start, start + length);
}

abstract final class WriterFindReplace {
  /// كل تطابقات [query] في [blocks] — غير حساسة لحالة الأحرف.
  ///
  /// استعلام فارغ ⇒ لا نتائج (لا يُمسح المستند بتطابقات صفرية).
  static List<WriterFindMatch> findAll(List<JoodWriterBlock> blocks, String query) {
    final String needle = query.trim();
    if (needle.isEmpty) return const <WriterFindMatch>[];
    final String lower = needle.toLowerCase();
    final List<WriterFindMatch> matches = <WriterFindMatch>[];
    for (int i = 0; i < blocks.length; i++) {
      final String hay = blocks[i].text.toLowerCase();
      int from = 0;
      while (true) {
        final int at = hay.indexOf(lower, from);
        if (at < 0) break;
        matches.add(WriterFindMatch(blockIndex: i, start: at, length: needle.length));
        from = at + needle.length;
      }
    }
    return matches;
  }

  /// يُبدّل أول تطابق في الكتلة [blockIndex] — أو في المستند كله إن غاب
  /// الفهرس. يُعيد الكتلة الجديدة أو `null` إن لم يُبدَّل شيء.
  static JoodWriterBlock? replaceFirstIn(
    List<JoodWriterBlock> blocks,
    int blockIndex,
    String query,
    String replacement,
  ) {
    final String needle = query.trim();
    if (needle.isEmpty) return null;
    final int index = blockIndex.clamp(0, blocks.length - 1);
    final String text = blocks[index].text;
    final int at = text.toLowerCase().indexOf(needle.toLowerCase());
    if (at < 0) return null;
    final String changed =
        text.replaceRange(at, at + needle.length, replacement);
    return blocks[index].copyWith(text: changed);
  }

  /// يستبدل **كل** التطابقات في الكتلة [blockIndex] — تُعاد الكتلة أو `null`.
  static JoodWriterBlock? replaceAllIn(
    List<JoodWriterBlock> blocks,
    int blockIndex,
    String query,
    String replacement,
  ) {
    final String needle = query.trim();
    if (needle.isEmpty || indexInvalid(blocks, blockIndex)) return null;
    final String text = blocks[blockIndex].text;
    final String lower = text.toLowerCase();
    final String lowerNeedle = needle.toLowerCase();
    if (!lower.contains(lowerNeedle)) return null;
    // بناء يدوي بحروف أصلية: استبدال الحالة الصغيرة يحفظ بقية النصّ كما هو.
    final StringBuffer out = StringBuffer();
    int from = 0;
    while (true) {
      final int at = lower.indexOf(lowerNeedle, from);
      if (at < 0) break;
      out.write(text.substring(from, at));
      out.write(replacement);
      from = at + needle.length;
    }
    out.write(text.substring(from));
    return blocks[blockIndex].copyWith(text: out.toString());
  }

  static bool indexInvalid(List<JoodWriterBlock> blocks, int index) =>
      blocks.isEmpty || index < 0 || index >= blocks.length;

  /// يقف بالـController على أول تطابق (أو التالي/السابق من [from]) —
  /// يُعيد المؤشّر إلى التطابق أو `null` إن لم يوجد.
  static WriterFindMatch? jumpTo(
    WriterDocumentController controller,
    List<WriterFindMatch> matches,
    int from, {
    required int direction,
  }) {
    if (matches.isEmpty) return null;
    final int next = (from + direction).clamp(0, matches.length - 1);
    final WriterFindMatch match = matches[next];
    controller.setActiveBlock(match.blockIndex);
    controller.requestBlockFocus(match.blockIndex);
    return match;
  }
}

/// حالة بحث حيّة تربط نافذة «بحث واستبدال» بأزرار الشريط (التالي/السابق):
/// تحتفظ بالاستعلام ونتائجها الحالية، وتعيد حسابها بعد كل تغيير في المستند.
class WriterFindState extends ChangeNotifier {
  WriterFindState(this._controller);

  final WriterDocumentController _controller;

  String query = '';
  String replacement = '';
  List<WriterFindMatch> matches = const <WriterFindMatch>[];
  int currentIndex = -1;

  bool get hasQuery => query.trim().isNotEmpty;
  WriterFindMatch? get current =>
      currentIndex >= 0 && currentIndex < matches.length
      ? matches[currentIndex]
      : null;

  /// تعديل الاستعلام وتحديث النتائج من أول تطابق.
  void setQuery(String value) {
    query = value;
    refresh(resetIndex: true);
  }

  /// إعادة حساب التطابقات من مستند الـController (بعد أي تحرير).
  void refresh({bool resetIndex = false}) {
    matches = WriterFindReplace.findAll(_controller.document.blocks, query);
    if (resetIndex || currentIndex >= matches.length) {
      currentIndex = matches.isEmpty ? -1 : 0;
    }
    notifyListeners();
  }

  /// التحرير: يقف على التطابق الحالي أو ينعش النتائج إن كانت فارغة.
  WriterFindMatch? next() {
    if (matches.isEmpty) refresh(resetIndex: true);
    if (matches.isEmpty) return null;
    currentIndex = (currentIndex + 1).clamp(0, matches.length - 1);
    final WriterFindMatch match = matches[currentIndex];
    _controller.setActiveBlock(match.blockIndex);
    _controller.requestBlockFocus(match.blockIndex);
    notifyListeners();
    return match;
  }

  WriterFindMatch? previous() {
    if (matches.isEmpty) refresh(resetIndex: true);
    if (matches.isEmpty) return null;
    currentIndex = (currentIndex - 1).clamp(0, matches.length - 1);
    final WriterFindMatch match = matches[currentIndex];
    _controller.setActiveBlock(match.blockIndex);
    _controller.requestBlockFocus(match.blockIndex);
    notifyListeners();
    return match;
  }

  /// استبدال التطابق الحالي — يُعيد `true` إن استُبدل شيء.
  bool replaceCurrent() {
    final WriterFindMatch? match = current;
    if (match == null && matches.isNotEmpty) refresh(resetIndex: true);
    final WriterFindMatch? target = current;
    if (target == null) return false;
    final JoodWriterBlock? changed = WriterFindReplace.replaceFirstIn(
      _controller.document.blocks,
      target.blockIndex,
      query,
      replacement,
    );
    if (changed == null) return false;
    _apply(target.blockIndex, changed);
    refresh();
    return true;
  }

  /// استبدال كل التطابقات في كل الكتل — يُرجع عدد الكتل المبدَلة.
  int replaceAll() {
    if (!hasQuery) return 0;
    int changed = 0;
    for (int i = 0; i < _controller.document.blocks.length; i++) {
      final JoodWriterBlock? block = WriterFindReplace.replaceAllIn(
        _controller.document.blocks,
        i,
        query,
        replacement,
      );
      if (block != null) {
        _apply(i, block);
        changed++;
      }
    }
    refresh(resetIndex: true);
    return changed;
  }

  /// قفز بلوحة الترقيم إلى كتلة (١-based).
  bool goToBlock(int oneBased) {
    final int index = oneBased - 1;
    if (WriterFindReplace.indexInvalid(_controller.document.blocks, index)) {
      return false;
    }
    _controller.setActiveBlock(index);
    _controller.requestBlockFocus(index);
    return true;
  }

  void _apply(int blockIndex, JoodWriterBlock block) {
    _controller.setActiveBlock(blockIndex);
    _controller.updateActiveBlock(block);
  }
}
