/// شريط **Ribbon** المُطوَّر لـ«جود كاتب»: خمسة تبويبات في الأعلى، يفتح
/// النشط محتواه ويطوّي البقية.
///
/// البنية:
/// * صفّ التبويبات (34px) + محتوى التبويب (84px) = 118px ضمن نطاق 90-120.
/// * الضغطة على التبويب النشط يطوي المحتوى ويعيده (نقرتان = طيّ/فتح).
/// * المحتوى أفقي التمرير: الشريط يتجاوز عرض الشاشات المتوسطة كما في Word،
///   وقسم «الكتل» أول قسم في الرئيسية كي تبقى أدوات النصّ سريعة في المتناول.
/// * الخدمات (العصا السحرية، التاريخ، البحث، التعليقات) تُنشأ هنا وتُمرَّر
///   إلى الألسنة؛ وتمريرها يُغلق نافذة التعليقات مع شريطها.
library;

import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_l10n.dart';
import '../../theme/writer_ribbon_theme.dart';
import '../../writer_document_controller.dart';
import 'writer_format_painter.dart';
import 'writer_find_replace.dart';
import 'writer_ribbon_comments.dart';
import 'writer_ribbon_design.dart';
import 'writer_ribbon_file.dart';
import 'writer_ribbon_history.dart';
import 'writer_ribbon_home.dart';
import 'writer_ribbon_review.dart';
import 'writer_ribbon_setup.dart';

class WriterTabbedRibbonBar extends StatefulWidget {
  const WriterTabbedRibbonBar({super.key, required this.controller});

  final WriterDocumentController controller;

  @override
  State<WriterTabbedRibbonBar> createState() => _WriterTabbedRibbonBarState();
}

class _WriterTabbedRibbonBarState extends State<WriterTabbedRibbonBar> {
  int _activeTab = 0;
  bool _collapsed = false;

  late final WriterFormatPainter _painter;
  late final WriterRibbonHistory _history;
  late final WriterFindState _find;
  late final WriterCommentsStore _comments;

  static const List<String> _tabKeys = <String>[
    'ribbon-tab-home',
    'ribbon-tab-setup',
    'ribbon-tab-design',
    'ribbon-tab-file',
    'ribbon-tab-review',
  ];

  @override
  void initState() {
    super.initState();
    _painter = WriterFormatPainter(widget.controller);
    _history = WriterRibbonHistory(widget.controller);
    _find = WriterFindState(widget.controller);
    _comments = WriterCommentsStore(widget.controller.document.title);
    // تحميل التعليقات المحفوظة — بلا فشل يُسقط الواجهة.
    _comments.ensureLoaded();
  }

  @override
  void dispose() {
    _painter.dispose();
    _history.dispose();
    _find.dispose();
    _comments.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    setState(() {
      if (_activeTab == index) {
        // الضغطة على التبويب النشط يطوي/يفتح محتواه.
        _collapsed = !_collapsed;
      } else {
        _activeTab = index;
        _collapsed = false;
      }
    });
  }

  Widget _contentFor(int index) {
    switch (index) {
      case 0:
        return WriterRibbonHomeTab(
          controller: widget.controller,
          painter: _painter,
        );
      case 1:
        return WriterRibbonSetupTab(controller: widget.controller);
      case 2:
        return WriterRibbonDesignTab(controller: widget.controller);
      case 3:
        return WriterRibbonFileTab(
          controller: widget.controller,
          history: _history,
        );
      case 4:
        return WriterRibbonReviewTab(
          controller: widget.controller,
          find: _find,
          comments: _comments,
          history: _history,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _tabLabel(BuildContext context, int index) {
    final l10n = context.l10n;
    return switch (index) {
      0 => l10n?.jwRibbonHome ?? 'الرئيسية',
      1 => l10n?.jwRibbonSetup ?? 'التهيئة',
      2 => l10n?.jwRibbonDesign ?? 'التصميم',
      3 => l10n?.jwRibbonFile ?? 'الحفظ',
      _ => l10n?.jwRibbonReview ?? 'المراجعة',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: WriterRibbonTheme.bar,
        border: Border(
          bottom: BorderSide(color: WriterRibbonTheme.border),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // ------------------------- صفّ التبويبات -------------------------
          SizedBox(
            height: WriterRibbonTheme.tabsRowHeight,
            child: Row(
              children: <Widget>[
                for (int i = 0; i < _tabKeys.length; i++)
                  _RibbonTabButton(
                    key: ValueKey<String>(_tabKeys[i]),
                    label: _tabLabel(context, i),
                    active: _activeTab == i && !_collapsed,
                    onTap: () => _selectTab(i),
                  ),
              ],
            ),
          ),
          // ------------------------- محتوى التبويب -------------------------
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _collapsed
                ? const SizedBox.shrink()
                : SizedBox(
                    key: ValueKey<String>('ribbon-content-$_activeTab'),
                    width: double.infinity,
                    height: WriterRibbonTheme.contentHeight,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _contentFor(_activeTab),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// زر تبويب واحد في أعلى الشريط.
class _RibbonTabButton extends StatelessWidget {
  const _RibbonTabButton({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: active
              ? WriterRibbonTheme.tabActive
              : WriterRibbonTheme.tabInactive,
          border: const Border(
            right: BorderSide(color: WriterRibbonTheme.border),
            bottom: BorderSide(
              color: WriterRibbonTheme.tabActive,
              width: 2,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Text(label, style: WriterRibbonTheme.tabLabel(active: active)),
      ),
    );
  }
}
