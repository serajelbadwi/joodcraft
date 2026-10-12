/// تبويب «المراجعة» في شريط Ribbon — التدقيق والإحصاء، والبحث والاستبدال،
/// والإدراج (تاريخ/وقت/رموز/معادلة/حاشية)، والتعليقات وسجل التغييرات.
///
/// ربط حقيقي بلا قاموس تدقيق خارجي:
/// * الإحصاءات (كلمات/حروف/أسطر/وقت قراءة) تُحسب من كتل المستند لحظياً.
/// * التدقيق البسيط يكشف تكرار الكلمات المتتالية (أداة مساعدة صريحة).
/// * البحث/الاستبدال/الانتقال كلّها عبر [WriterFindState] + نموذج الكتل.
/// * التعليقات مخزن مستقلّ مثبّت على فهرس الكتلة (لا يظهر في الطباعة).
library;

import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_l10n.dart';
import '../../../domain/jood_writer_block.dart';
import '../../theme/writer_ribbon_theme.dart';
import '../../writer_document_controller.dart';
import 'writer_find_replace.dart';
import 'writer_ribbon_comments.dart';
import 'writer_ribbon_common.dart';
import 'writer_ribbon_design.dart' show writerSymbols;
import 'writer_ribbon_file.dart' show showWriterHistoryDialog;
import 'writer_ribbon_history.dart';
import 'writer_ribbon_insert.dart';

class WriterRibbonReviewTab extends StatelessWidget {
  const WriterRibbonReviewTab({
    super.key,
    required this.controller,
    required this.find,
    required this.comments,
    required this.history,
  });

  final WriterDocumentController controller;
  final WriterFindState find;
  final WriterCommentsStore comments;
  final WriterRibbonHistory history;

  WriterDocumentStats get _stats => WriterDocumentStats.of(
    controller.document.blocks.map((JoodWriterBlock b) => b.text).toList(),
  );

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _insertFootnote() {
    WriterRibbonInsert.atCaret(controller, '¹');
    final int last = controller.document.blocks.length - 1;
    controller.setActiveBlock(last);
    controller.addBlockAfterActive();
    controller.updateActiveBlock(
      controller.activeBlock!.copyWith(
        text: '١) ',
        fontSize: 11,
        spaceBefore: 12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[controller, find, comments]),
      builder: (BuildContext context, _) {
        final l10n = context.l10n;
        final WriterDocumentStats stats = _stats;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // ------------------------- 1. التدقيق -------------------------
            RibbonSection(
              title: l10n?.jwSectionProofing ?? 'التدقيق',
              child: Row(
                children: <Widget>[
                  RibbonToolButton(
                    key: const ValueKey<String>('ribbon-spelling'),
                    tooltip: l10n?.jwSpelling ?? 'التدقيق الإملائي (تكرار الكلمات)',
                    icon: Icons.spellcheck,
                    label: l10n?.jwSpellingShort ?? 'تدقيق',
                    onPressed: () => showWriterStatsDialog(
                      context,
                      controller: controller,
                      proofing: true,
                    ),
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('ribbon-grammar'),
                    tooltip: l10n?.jwGrammar ?? 'القواعد (إحصاءات وتكرار)',
                    icon: Icons.rule,
                    onPressed: () => showWriterStatsDialog(
                      context,
                      controller: controller,
                      proofing: true,
                    ),
                  ),
                  RibbonSeparator(),
                  _StatTile(
                    key: const ValueKey<String>('ribbon-word-count'),
                    label: l10n?.jwWordCount ?? 'كلمة',
                    value: '${stats.words}',
                  ),
                  _StatTile(
                    key: const ValueKey<String>('ribbon-char-count'),
                    label: l10n?.jwCharacterCount ?? 'حرف',
                    value: '${stats.characters}',
                  ),
                  _StatTile(
                    key: const ValueKey<String>('ribbon-reading-time'),
                    label: l10n?.jwReadingTime ?? 'دقيقة قراءة',
                    value: '${stats.readingMinutes}',
                  ),
                ],
              ),
            ),
            RibbonVerticalDivider(),

            // ------------------------- 2. البحث -------------------------
            RibbonSection(
              title: l10n?.jwSectionFind ?? 'البحث',
              child: Row(
                children: <Widget>[
                  RibbonToolButton(
                    key: const ValueKey<String>('ribbon-find'),
                    tooltip: l10n?.jwFind ?? 'بحث (Ctrl+F)',
                    icon: Icons.search,
                    label: l10n?.jwFindShort ?? 'بحث',
                    onPressed: () => showWriterFindDialog(
                      context,
                      controller: controller,
                      find: find,
                    ),
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('ribbon-replace'),
                    tooltip: l10n?.jwReplace ?? 'استبدال (Ctrl+H)',
                    icon: Icons.find_replace,
                    onPressed: () => showWriterFindDialog(
                      context,
                      controller: controller,
                      find: find,
                      showReplace: true,
                    ),
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('ribbon-goto'),
                    tooltip: l10n?.jwGoTo ?? 'الانتقال إلى (Ctrl+G)',
                    icon: Icons.my_location,
                    onPressed: () => showWriterGoToDialog(
                      context,
                      find: find,
                    ),
                  ),
                  RibbonSeparator(),
                  RibbonToolButton(
                    key: const ValueKey<String>('ribbon-find-next'),
                    tooltip: l10n?.jwFindNext ?? 'البحث عن التالي',
                    icon: Icons.keyboard_arrow_down,
                    onPressed: () {
                      if (!find.hasQuery) {
                        showWriterFindDialog(
                          context,
                          controller: controller,
                          find: find,
                        );
                        return;
                      }
                      final WriterFindMatch? match = find.next();
                      if (match == null) {
                        _snack(context, l10n?.jwNoMatches ?? 'لا نتائج');
                      }
                    },
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('ribbon-find-prev'),
                    tooltip: l10n?.jwFindPrevious ?? 'البحث عن السابق',
                    icon: Icons.keyboard_arrow_up,
                    onPressed: () {
                      if (!find.hasQuery) {
                        showWriterFindDialog(
                          context,
                          controller: controller,
                          find: find,
                        );
                        return;
                      }
                      final WriterFindMatch? match = find.previous();
                      if (match == null) {
                        _snack(context, l10n?.jwNoMatches ?? 'لا نتائج');
                      }
                    },
                  ),
                ],
              ),
            ),
            RibbonVerticalDivider(),

            // ------------------------- 3. الإدراج -------------------------
            RibbonSection(
              title: l10n?.jwSectionInsertReview ?? 'الإدراج',
              child: Row(
                children: <Widget>[
                  RibbonToolButton(
                    key: const ValueKey<String>('ribbon-insert-date'),
                    tooltip: l10n?.jwInsertDate ?? 'إدراج التاريخ',
                    icon: Icons.today,
                    onPressed: () =>
                        WriterRibbonInsert.atCaret(controller, WriterRibbonInsert.today()),
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('ribbon-insert-time'),
                    tooltip: l10n?.jwInsertTime ?? 'إدراج الوقت',
                    icon: Icons.schedule,
                    onPressed: () =>
                        WriterRibbonInsert.atCaret(controller, WriterRibbonInsert.nowTime()),
                  ),
                  RibbonMenu<String>(
                    key: const ValueKey<String>('ribbon-insert-symbol-menu'),
                    tooltip: l10n?.jwInsertSymbol ?? 'إدراج رمز',
                    icon: Icons.emoji_symbols_outlined,
                    items: <RibbonMenuItem<String>>[
                      for (final String s in writerSymbols)
                        RibbonMenuItem<String>(value: s, label: s),
                    ],
                    onSelected: (String s) =>
                        WriterRibbonInsert.atCaret(controller, s),
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('ribbon-insert-equation'),
                    tooltip: l10n?.jwInsertEquation ?? 'إدراج معادلة',
                    icon: Icons.functions,
                    onPressed: () =>
                        WriterRibbonInsert.atCaret(controller, 'ناتج = ( ) × ( )'),
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('ribbon-insert-footnote'),
                    tooltip: l10n?.jwInsertFootnote ?? 'إدراج حاشية',
                    icon: Icons.notes,
                    onPressed: _insertFootnote,
                  ),
                ],
              ),
            ),
            RibbonVerticalDivider(),

            // ----------------------- 4. التعليقات -----------------------
            RibbonSection(
              title: l10n?.jwSectionComments ?? 'التعليقات',
              child: Row(
                children: <Widget>[
                  RibbonToolButton(
                    key: const ValueKey<String>('ribbon-new-comment'),
                    tooltip: l10n?.jwNewComment ?? 'تعليق جديد',
                    icon: Icons.add_comment_outlined,
                    label: l10n?.jwNewCommentShort ?? 'تعليق',
                    onPressed: () => showWriterNewCommentDialog(
                      context,
                      controller: controller,
                      comments: comments,
                    ),
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('ribbon-show-comments'),
                    tooltip: l10n?.jwShowComments ?? 'إظهار التعليقات',
                    icon: Icons.comment,
                    onPressed: () => showWriterCommentsDialog(
                      context,
                      controller: controller,
                      comments: comments,
                    ),
                  ),
                  RibbonToolButton(
                    key: const ValueKey<String>('ribbon-delete-comment'),
                    tooltip: l10n?.jwDeleteComment ?? 'حذف تعليقات هذه الكتلة',
                    icon: Icons.block,
                    onPressed: comments.forBlock(controller.activeBlockIndex).isEmpty
                        ? null
                        : () async {
                            for (final WriterComment c in comments.forBlock(
                              controller.activeBlockIndex,
                            )) {
                              await comments.remove(c.id);
                            }
                            if (context.mounted) {
                              _snack(context, l10n?.jwCommentDeleted ?? 'حُذف التعليق');
                            }
                          },
                  ),
                  RibbonSeparator(),
                  RibbonToggle(
                    key: const ValueKey<String>('ribbon-track-changes'),
                    tooltip: l10n?.jwTrackChanges ?? 'سجل التغييرات (التراجع)',
                    icon: Icons.history,
                    active: history.undoDepth > 0,
                    onPressed: () => showWriterHistoryDialog(
                      context,
                      history: history,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// بلاطة إحصاء صغيرة داخل قسم التدقيق.
class _StatTile extends StatelessWidget {
  const _StatTile({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.only(end: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: WriterRibbonTheme.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(value, style: WriterRibbonTheme.toolLabel),
          Text(label, style: WriterRibbonTheme.sectionLabel),
        ],
      ),
    );
  }
}

// =============================================================================
//  نافذة الإحصاءات والتدقيق
// =============================================================================

Future<void> showWriterStatsDialog(
  BuildContext context, {
  required WriterDocumentController controller,
  bool proofing = false,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) =>
        WriterStatsDialog(controller: controller, proofing: proofing),
  );
}

class WriterStatsDialog extends StatelessWidget {
  const WriterStatsDialog({
    super.key,
    required this.controller,
    this.proofing = false,
  });

  final WriterDocumentController controller;
  final bool proofing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final List<String> texts = controller.document.blocks
        .map((JoodWriterBlock b) => b.text)
        .toList();
    final WriterDocumentStats stats = WriterDocumentStats.of(texts);
    final List<WriterRepeatedWords> repeated =
        WriterRepeatedWords.find(texts);

    return AlertDialog(
      title: Text(
        proofing
            ? (l10n?.jwProofingTitle ?? 'التدقيق والإحصاء')
            : (l10n?.jwStatsTitle ?? 'إحصاءات المستند'),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _StatChip(label: l10n?.jwWordCount ?? 'كلمة', value: '${stats.words}'),
                _StatChip(
                  label: l10n?.jwCharacterCount ?? 'حرف',
                  value: '${stats.characters}',
                ),
                _StatChip(
                  label: l10n?.jwCharacterCountNoSpaces ?? 'حرف بلا مسافات',
                  value: '${stats.charactersNoSpaces}',
                ),
                _StatChip(label: l10n?.jwLinesCount ?? 'سطر', value: '${stats.lines}'),
                _StatChip(
                  label: l10n?.jwParagraphsCount ?? 'فقرة',
                  value: '${stats.paragraphs}',
                ),
                _StatChip(
                  label: l10n?.jwReadingTime ?? 'دقيقة قراءة',
                  value: '${stats.readingMinutes}',
                ),
              ],
            ),
            if (proofing) ...<Widget>[
              const SizedBox(height: 16),
              Text(
                l10n?.jwRepeatedWords ?? 'تكرار كلمات متتالية',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              if (repeated.isEmpty)
                Text(
                  l10n?.jwNoRepeatedWords ?? 'لا توجد كلمات مكرّرة — نصّ سليم.',
                  style: const TextStyle(color: Colors.greenAccent),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        for (final WriterRepeatedWords r in repeated)
                          Text(
                            '«${r.word}» × ${r.count}',
                            style: const TextStyle(fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('stats-close'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n?.jwClose ?? 'إغلاق'),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: WriterRibbonTheme.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

// =============================================================================
//  نافذة البحث والاستبدال
// =============================================================================

Future<void> showWriterFindDialog(
  BuildContext context, {
  required WriterDocumentController controller,
  required WriterFindState find,
  bool showReplace = false,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => WriterFindDialog(
      controller: controller,
      find: find,
      showReplace: showReplace,
    ),
  );
}

class WriterFindDialog extends StatefulWidget {
  const WriterFindDialog({
    super.key,
    required this.controller,
    required this.find,
    this.showReplace = false,
  });

  final WriterDocumentController controller;
  final WriterFindState find;
  final bool showReplace;

  @override
  State<WriterFindDialog> createState() => _WriterFindDialogState();
}

class _WriterFindDialogState extends State<WriterFindDialog> {
  late final TextEditingController _query =
      TextEditingController(text: widget.find.query);
  late final TextEditingController _replace =
      TextEditingController(text: widget.find.replacement);

  @override
  void initState() {
    super.initState();
    if (widget.find.hasQuery) {
      widget.find.refresh(resetIndex: true);
    }
  }

  @override
  void dispose() {
    _query.dispose();
    _replace.dispose();
    super.dispose();
  }

  String get _countLabel {
    final l10n = context.l10n;
    if (!widget.find.hasQuery) return l10n?.jwFindPlaceholder ?? 'اكتب كلمة البحث…';
    if (widget.find.matches.isEmpty) {
      return l10n?.jwNoMatches ?? 'لا نتائج';
    }
    final int at = (widget.find.currentIndex + 1).clamp(
      1,
      widget.find.matches.length,
    );
    if (l10n != null) {
      // `jwMatchesCount` تُولَّد كدالة بسبب placeholders داخل نصّها.
      return l10n.jwMatchesCount(at, widget.find.matches.length);
    }
    return 'النتيجة $at من ${widget.find.matches.length}';
  }

  void _syncQuery() {
    widget.find.setQuery(_query.text);
    widget.find.replacement = _replace.text;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n?.jwFindTitle ?? 'بحث واستبدال'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              key: const ValueKey<String>('find-query'),
              controller: _query,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n?.jwFindPlaceholder ?? 'ابحث…',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (_) => _syncQuery(),
            ),
            if (widget.showReplace) ...<Widget>[
              const SizedBox(height: 10),
              TextField(
                key: const ValueKey<String>('find-replace'),
                controller: _replace,
                decoration: InputDecoration(
                  labelText: l10n?.jwReplacePlaceholder ?? 'استبدل بـ…',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.find_replace),
                ),
                onChanged: (_) => _syncQuery(),
              ),
            ],
            const SizedBox(height: 10),
            ListenableBuilder(
              listenable: widget.find,
              builder: (BuildContext context, _) => Text(
                _countLabel,
                key: const ValueKey<String>('find-count'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n?.jwClose ?? 'إغلاق'),
        ),
        if (widget.showReplace) ...<Widget>[
          TextButton(
            key: const ValueKey<String>('find-replace-one'),
            onPressed: () {
              _syncQuery();
              widget.find.replaceCurrent();
            },
            child: Text(l10n?.jwReplaceButton ?? 'استبدال'),
          ),
          TextButton(
            key: const ValueKey<String>('find-replace-all'),
            onPressed: () {
              _syncQuery();
              final int n = widget.find.replaceAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${l10n?.jwReplacedBlocks ?? 'كُتل مبدَلة'}: $n',
                    ),
                  ),
                );
              }
            },
            child: Text(l10n?.jwReplaceAll ?? 'استبدال الكل'),
          ),
        ],
        TextButton.icon(
          key: const ValueKey<String>('find-prev'),
          icon: const Icon(Icons.keyboard_arrow_up),
          label: Text(l10n?.jwFindPrevious ?? 'السابق'),
          onPressed: () {
            _syncQuery();
            widget.find.previous();
          },
        ),
        FilledButton.icon(
          key: const ValueKey<String>('find-next'),
          icon: const Icon(Icons.keyboard_arrow_down),
          label: Text(l10n?.jwFindNext ?? 'التالي'),
          onPressed: () {
            _syncQuery();
            widget.find.next();
          },
        ),
      ],
    );
  }
}

// =============================================================================
//  نافذة الانتقال إلى كتلة
// =============================================================================

Future<void> showWriterGoToDialog(
  BuildContext context, {
  required WriterFindState find,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => WriterGoToDialog(find: find),
  );
}

class WriterGoToDialog extends StatefulWidget {
  const WriterGoToDialog({super.key, required this.find});

  final WriterFindState find;

  @override
  State<WriterGoToDialog> createState() => _WriterGoToDialogState();
}

class _WriterGoToDialogState extends State<WriterGoToDialog> {
  final TextEditingController _number = TextEditingController();

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n?.jwGoTo ?? 'الانتقال إلى'),
      content: SizedBox(
        width: 300,
        child: TextField(
          key: const ValueKey<String>('goto-number'),
          controller: _number,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n?.jwGoToBlockLabel ?? 'رقم الكتلة',
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) {
            widget.find.goToBlock(int.tryParse(_number.text) ?? 0);
            Navigator.of(context).pop();
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n?.jwCancel ?? 'إلغاء'),
        ),
        FilledButton(
          key: const ValueKey<String>('goto-ok'),
          onPressed: () {
            widget.find.goToBlock(int.tryParse(_number.text) ?? 0);
            Navigator.of(context).pop();
          },
          child: Text(l10n?.jwOk ?? 'موافق'),
        ),
      ],
    );
  }
}

// =============================================================================
//  حوار التعليق الجديد وعرض التعليقات
// =============================================================================

Future<void> showWriterNewCommentDialog(
  BuildContext context, {
  required WriterDocumentController controller,
  required WriterCommentsStore comments,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => WriterNewCommentDialog(
      controller: controller,
      comments: comments,
    ),
  );
}

class WriterNewCommentDialog extends StatefulWidget {
  const WriterNewCommentDialog({
    super.key,
    required this.controller,
    required this.comments,
  });

  final WriterDocumentController controller;
  final WriterCommentsStore comments;

  @override
  State<WriterNewCommentDialog> createState() => _WriterNewCommentDialogState();
}

class _WriterNewCommentDialogState extends State<WriterNewCommentDialog> {
  final TextEditingController _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n?.jwNewComment ?? 'تعليق جديد'),
      content: SizedBox(
        width: 420,
        child: TextField(
          key: const ValueKey<String>('comment-text'),
          controller: _text,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: l10n?.jwCommentHint ?? 'نصّ التعليق على الكتلة النشطة',
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n?.jwCancel ?? 'إلغاء'),
        ),
        FilledButton(
          key: const ValueKey<String>('comment-save'),
          onPressed: () async {
            await widget.comments.add(
              blockIndex: widget.controller.activeBlockIndex,
              text: _text.text,
            );
            if (context.mounted) Navigator.of(context).pop();
          },
          child: Text(l10n?.jwOk ?? 'موافق'),
        ),
      ],
    );
  }
}

Future<void> showWriterCommentsDialog(
  BuildContext context, {
  required WriterDocumentController controller,
  required WriterCommentsStore comments,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => WriterCommentsDialog(
      controller: controller,
      comments: comments,
    ),
  );
}

class WriterCommentsDialog extends StatelessWidget {
  const WriterCommentsDialog({
    super.key,
    required this.controller,
    required this.comments,
  });

  final WriterDocumentController controller;
  final WriterCommentsStore comments;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final List<WriterComment> items = comments.comments;

    return AlertDialog(
      title: Text(l10n?.jwCommentsTitle ?? 'تعليقات المستند'),
      content: SizedBox(
        width: 460,
        child: items.isEmpty
            ? Text(l10n?.jwCommentsEmpty ?? 'لا توجد تعليقات بعد.')
            : ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int i) {
                    final WriterComment c = items[i];
                    return ListTile(
                      key: ValueKey<String>('comment-${c.id}'),
                      dense: true,
                      leading: const Icon(Icons.comment),
                      title: Text(c.text),
                      subtitle: Text(
                        '${l10n?.jwCommentAtBlock ?? 'الكتلة'} ${c.blockIndex + 1}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            tooltip: l10n?.jwJumpToBlock ?? 'انتقال',
                            icon: const Icon(Icons.my_location, size: 18),
                            onPressed: () {
                              controller.setActiveBlock(c.blockIndex);
                              controller.requestBlockFocus(c.blockIndex);
                              Navigator.of(context).pop();
                            },
                          ),
                          IconButton(
                            tooltip: l10n?.jwDeleteComment ?? 'حذف',
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () => comments.remove(c.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n?.jwClose ?? 'إغلاق'),
        ),
      ],
    );
  }
}
