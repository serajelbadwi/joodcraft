/// شريط أدوات **يتخلّص من الازدحام** بدل أن يُقتطع.
///
/// يقيس عرض كل مجموعة فعلياً من الشاشة (لا بتقدير ثابت)، ثم يجمع الأدوات الأدنى
/// أولوية تحت شارة **قائمة منسدلة أعلى الشريط نفسه** — فلا تختفي أي أداة خارج
/// حافة الشريط، ولا تحتاج تمريراً أفقيّاً، ولا تسقط إلى مكانٍ بعيد عن سياقها.
library;

import 'package:flutter/foundation.dart' show listEquals, mapEquals;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../dock/dock_layout.dart';

/// عنصر واحد في شريط الأدوات القابل للتخلّص من الازدحام.
class DockOverflowItem {
  const DockOverflowItem({
    required this.id,
    required this.child,
    this.priority = 0,
    this.pinned = false,
  });

  /// معرّف ثابت (يُستخدم لتتبّع العرض المُقاس وحالة الإخفاء).
  final String id;

  final Widget child;

  /// أولوية البقاء: الأعلى يبقى ظاهراً أطول ما أمكن.
  final int priority;

  /// مثبّت لا يُخفى أبداً مهما ضاق العرض.
  final bool pinned;
}

/// شريط أفقي يرتّب عناصره حسب الأولوية وما يتّسع فعلاً في العرض المتاح.
class DockOverflowBar extends StatefulWidget {
  const DockOverflowBar({
    super.key,
    required this.items,
    this.spacing = 8,
    this.overflowButtonWidth = 96,
    this.minVisible = 1,
    this.onHiddenChanged,
    this.overflowLabel,
  });

  final List<DockOverflowItem> items;

  /// المسافة بين العناصر.
  final double spacing;

  /// عرض شارة الدرج (تُحجز من المساحة عند وجود أي أداة مُخلاة).
  final double overflowButtonWidth;

  /// أقلّ عدد عناصر تبقى ظاهرة.
  final int minVisible;

  /// يُنادى عند تغيّر مجموعة المعرّفات المُخلاة (مرّة واحدة لكل تغيير).
  final ValueChanged<List<String>>? onHiddenChanged;

  /// نصّ شارة القائمة المنسدلة التي تجمع الأدوات المُخلاة.
  final String? overflowLabel;

  @override
  State<DockOverflowBar> createState() => _DockOverflowBarState();
}

class _DockOverflowBarState extends State<DockOverflowBar> {
  /// آخر عرض مُقاس لكل عنصر (يُحدَّث أثناء التخطيط ثم يُثبَّت في الإطار التالي).
  final Map<String, double> _reported = <String, double>{};
  Map<String, double> _widths = <String, double>{};
  List<String> _hiddenIds = const <String>[];
  bool _flushScheduled = false;

  /// آخر عرض متاح من [LayoutBuilder] — يُستخدم لحساب الخطة داخل ما بعد الإطار.
  double _available = double.infinity;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final List<DockOverflowItem> items = widget.items;
        _available = constraints.maxWidth;
        _scheduleFlush();

        final bool measuring = items.any(
          (DockOverflowItem item) => !_widths.containsKey(item.id),
        );

        final DockOverflowPlan plan = measuring
            ? DockOverflowPlan(
                visible: <int>[
                  for (int i = 0; i < items.length; i++) i,
                ],
                hidden: const <int>[],
              )
            : resolveDockOverflow(
                widths: <double>[
                  for (final DockOverflowItem item in items)
                    _widths[item.id] ?? 0,
                ],
                priorities: <int>[
                  for (final DockOverflowItem item in items)
                    item.pinned ? pinnedDockPriority : item.priority,
                ],
                available: constraints.maxWidth,
                spacing: widget.spacing,
                overflowButtonWidth: widget.overflowButtonWidth,
                minVisible: widget.minVisible,
              );

        if (!measuring) {
          // شبكة أمان: الحساب الفعلي يقع في ما بعد الإطار نفسه الذي تُثبَّت
          // فيه المقاسات، فلا يحتاج المستخدم إطاراً ثالثاً لرؤية الدرج.
          _publishPlan(items: items, widths: _widths);
        }

        final List<Widget> children = <Widget>[];
        for (final int index in plan.visible) {
          if (children.isNotEmpty) {
            children.add(SizedBox(width: widget.spacing));
          }
          final DockOverflowItem item = items[index];
          children.add(
            _MeasureReporter(
              onMeasured: (double width) => _onMeasured(item.id, width),
              child: item.child,
            ),
          );
        }
        if (plan.hasOverflow) {
          if (children.isNotEmpty) {
            children.add(SizedBox(width: widget.spacing));
          }
          children.add(
            _OverflowMenu(
              label: widget.overflowLabel,
              // الأدوات المُخلاة نفسها — لا مجرّد تنبيه بها — فيبقى الوصول
              // إليها بنقرة واحدة من الشريط.
              children: <Widget>[
                for (final int index in plan.hidden) items[index].child,
              ],
            ),
          );
        }

        // التمرير احتياط أمان فقط: العناصر المعروضة تتّسع بالحساب، ولا يُقتطع
        // شيء أبداً لأن ما لا يتّسع ينتقل إلى الدرج.
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        );
      },
    );
  }

  /// يُنادى من الطبقة أثناء **التخطيط** (كل العناصر تُرسم بعرضها الطبيعي داخل
  /// التمرير الأفقي) فلا نعتمد على أي تقدير — ولا نلمس أي عنصر بعد إطاره.
  void _onMeasured(String id, double width) {
    if (_reported[id] == width) return;
    _reported[id] = width;
    _scheduleFlush();
  }

  /// يُثبّت المقاسات المقيسة بعد الإطار (لا يجوز `setState` أثناء التخطيط)،
  /// ويحسب خطة العرض في اللحظة نفسها فلا يبقى عنصر خارج الشجرة إطاراً كاملاً.
  void _scheduleFlush() {
    if (_flushScheduled) return;
    _flushScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _flushScheduled = false;
      if (!mounted) return;
      final Map<String, double> next = Map<String, double>.of(_reported);
      final bool changed = !mapEquals(next, _widths);
      final List<DockOverflowItem> items = widget.items;
      if (changed) setState(() => _widths = next);
      _publishPlan(items: items, widths: next, immediate: true);
    });
  }

  /// يحسب الخطة ويُبلّغ الأب بالمعرّفات المُخلاة.
  void _publishPlan({
    required List<DockOverflowItem> items,
    required Map<String, double> widths,
    bool immediate = false,
  }) {
    if (items.any((DockOverflowItem item) => !widths.containsKey(item.id))) {
      return;
    }
    final DockOverflowPlan plan = resolveDockOverflow(
      widths: <double>[
        for (final DockOverflowItem item in items) widths[item.id] ?? 0,
      ],
      priorities: <int>[
        for (final DockOverflowItem item in items)
          item.pinned ? pinnedDockPriority : item.priority,
      ],
      available: _available,
      spacing: widget.spacing,
      overflowButtonWidth: widget.overflowButtonWidth,
      minVisible: widget.minVisible,
    );
    _scheduleHiddenUpdate(
      <String>[for (final int index in plan.hidden) items[index].id],
      immediate: immediate,
    );
  }

  void _scheduleHiddenUpdate(List<String> ids, {bool immediate = false}) {
    if (listEquals(ids, _hiddenIds)) return;
    _hiddenIds = ids;
    final ValueChanged<List<String>>? callback = widget.onHiddenChanged;
    if (callback == null) return;
    if (immediate) {
      callback(ids);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      callback(ids);
    });
  }
}

/// يقيس عرض محتواه أثناء التخطيط ويُبلّغ به (بلا مفاتيح عامة ولا إطار زائد).
class _MeasureReporter extends SingleChildRenderObjectWidget {
  const _MeasureReporter({required this.onMeasured, required Widget child})
      : super(child: child);

  final ValueChanged<double> onMeasured;

  @override
  _RenderMeasureReporter createRenderObject(BuildContext context) =>
      _RenderMeasureReporter(onMeasured);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderMeasureReporter renderObject,
  ) {
    renderObject.onMeasured = onMeasured;
  }
}

class _RenderMeasureReporter extends RenderProxyBox {
  _RenderMeasureReporter(this.onMeasured);

  ValueChanged<double> onMeasured;
  double _lastReported = double.nan;

  @override
  void performLayout() {
    super.performLayout();
    final double width = size.width;
    if (width == _lastReported) return;
    _lastReported = width;
    onMeasured(width);
  }
}

/// شارة صغيرة تفتح **قائمة منسدلة** بكل الأدوات التي لم تتّسع في الشريط.
///
/// نستعمل [MenuAnchor] (لا `PopupMenuButton`) لأن محتوى القائمة تفاعلي (منتقيات
/// وأزرار وشارات)، ولا يصحّ أن تُغلق عند أول لمسة. والقائمة تحصل على عرضها
/// الطبيعي من محتواها (قياس تلقائي)، فلا تُقتطع أي أداة داخلها.
class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu({this.label, required this.children});

  final String? label;

  /// أدوات الشريط التي أخلاها حساب الفيض — بترتيبها الأصلي.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: const MenuStyle(
        // سقف عرض معقول للأدوات العريضة، بلا أن يُفرَض عرض ضيّق يُفيضها.
        maximumSize: WidgetStatePropertyAll<Size>(Size(420, 640)),
        padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
          EdgeInsets.all(AppTheme.space12),
        ),
      ),
      menuChildren: <Widget>[
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final Widget child in children) ...<Widget>[
              child,
              const SizedBox(height: AppTheme.space12),
            ],
          ],
        ),
      ],
      builder: (
        BuildContext context,
        MenuController controller,
        Widget? _,
      ) {
        final bool open = controller.isOpen;
        return Tooltip(
          message: label ?? 'أدوات أخرى',
          child: InkWell(
            onTap: () => open ? controller.close() : controller.open(),
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            child: Container(
              key: const ValueKey<String>('dock-overflow-chip'),
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: open ? scheme.primary : scheme.brandSurface,
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                border: Border.all(color: scheme.outline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    open
                        ? Icons.expand_less_rounded
                        : Icons.more_horiz_rounded,
                    size: 16,
                    color: open ? scheme.onPrimary : scheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label ?? 'أدوات أخرى',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: open ? scheme.onPrimary : null,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
