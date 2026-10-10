/// لوحة أدوات **قابلة للإرساء**: تُطوى، ويُغيّر حجمها، وتُسحب فتُلتقط
/// مغناطيسياً إلى الشريط العلوي أو الشريط الجانبي أو اللوحة الجانبية.
library;

import 'package:flutter/material.dart';

import '../../l10n/app_l10n.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../dock/dock_controller.dart';
import '../dock/dock_layout.dart';

/// تلميح مؤشّر الالتقاط: يترجم الموضع إلى نصّه المترجم.
typedef DockSlotLabel = String Function(DockSlot slot);

/// لوحة أدوات قابلة للإرساء حول أي محتوى.
///
/// * **الطيّ**: يبقى شريط العنوان وحده فيتحوّل إلى شريط رفيع.
/// * **الحجم**: مقبض سحب أسفل/يمين اللوحة.
/// * **النقل**: قائمة «موضع الإرساء» أو سحبٌ فعليّ — ومع اقتراب اللوحة من أي
///   حافة تظهر **شارة التقاط مغناطيسي** على الحافة المقصودة، فتُفلت فتُرسى فيها.
class DockableToolbar extends StatefulWidget {
  const DockableToolbar({
    super.key,
    required this.dock,
    required this.panelId,
    required this.title,
    required this.icon,
    required this.child,
    this.axis = Axis.vertical,
    this.viewportKey,
    this.slotLabel,
    this.bodyKey,
  });

  final DockController dock;

  /// مفتاح اللوحة في [DockLayout].
  final String panelId;

  final String title;
  final IconData icon;
  final Widget child;

  /// اتجاه الشريط: رأسي (جانبي) أو أفقي (مدمج في الأعلى).
  final Axis axis;

  /// مفتاح مساحة العمل التي تُحسب داخلها الإحداثيات — بلا هذا المفتاح
  /// يُعطَّل السحب ويبقى النقل من قائمة المواضع.
  final GlobalKey? viewportKey;

  /// مترجم اسم الموضع (يُمرَّر من الواجهة لتبقى هذه القطعة بلا لغة).
  final DockSlotLabel? slotLabel;

  /// مفتاح جسم اللوحة (للاختبارات).
  final Key? bodyKey;

  @override
  State<DockableToolbar> createState() => _DockableToolbarState();
}

class _DockableToolbarState extends State<DockableToolbar> {
  Rect _dragStartRect = Rect.zero;
  Offset _dragOffset = Offset.zero;
  Size _viewportSize = Size.zero;
  bool _dragging = false;

  bool get _canDrag => widget.viewportKey != null;

  DockPanelState get _state => widget.dock.stateOf(widget.panelId);

  /// مستطيل اللوحة داخل مساحة العمل (لا داخل النافذة) — أساس السحب والإرساء.
  Rect _rectInViewport() {
    final RenderBox? self = context.findRenderObject() as RenderBox?;
    final BuildContext? viewportContext = widget.viewportKey?.currentContext;
    final RenderBox? viewport =
        viewportContext?.findRenderObject() as RenderBox?;
    if (self == null || viewport == null || !self.hasSize) return Rect.zero;
    _viewportSize = viewport.size;
    return viewport.globalToLocal(self.localToGlobal(Offset.zero)) & self.size;
  }

  void _onDragStart(DragStartDetails details) {
    if (!_canDrag) return;
    _dragStartRect = _rectInViewport();
    if (_dragStartRect.isEmpty) return;
    _dragOffset = Offset.zero;
    _dragging = true;
    widget.dock.beginDrag();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_dragging) return;
    _dragOffset += details.delta;
    final Rect target = _dragStartRect.shift(_dragOffset);
    widget.dock.updateDrag(
      id: widget.panelId,
      x: target.left,
      y: target.top,
      width: _dragStartRect.width,
      height: _dragStartRect.height,
      viewportWidth: _viewportSize.width,
      viewportHeight: _viewportSize.height,
    );
  }

  void _onDragEnd() {
    if (!_dragging) return;
    _dragging = false;
    widget.dock.commitDrag(widget.panelId);
  }

  String _slotName(DockSlot slot) => widget.slotLabel?.call(slot) ?? slot.jsonValue;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.dock,
      builder: (BuildContext context, Widget? _) {
        final DockPanelState state = _state;
        final ColorScheme scheme = Theme.of(context).colorScheme;
        final bool vertical = widget.axis == Axis.vertical;
        return Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          color: scheme.surface,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _header(context, state),
                if (!state.collapsed) ...<Widget>[
                  ConstrainedBox(
                    key: widget.bodyKey,
                    constraints: vertical
                        ? BoxConstraints(maxHeight: state.size)
                        : BoxConstraints(maxWidth: state.size),
                    child: SingleChildScrollView(
                      scrollDirection: widget.axis,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: widget.child,
                      ),
                    ),
                  ),
                  _resizeHandle(context, vertical),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context, DockPanelState state) {
    // الشريط الجانبي المرسى يبقى **رفيعاً** (عرض جسمه) فلا يحجب الورقة:
    // رأسه أيقونات مضغوطة لا عنوان. أما العائمة فلها رأس كامل بالمطابقة.
    final bool compact = widget.axis == Axis.vertical && !state.isFloating;
    if (compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _dragHandle(context),
          _anchorMenu(context, state),
          _collapseToggle(context, state),
        ],
      );
    }
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 6, end: 2, top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _dragHandle(context),
          Icon(widget.icon, size: 14, color: scheme.primary),
          const SizedBox(width: 6),
          // عنوان قصير ثم أدوات الرأس مباشرةً — بلا `Spacer` لأن اللوحة قد
          // تُخطَّط بعرض غير محدود (عائمة داخل مساحة العمل).
          Text(
            widget.title,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(width: 6),
          _anchorMenu(context, state),
          _collapseToggle(context, state),
        ],
      ),
    );
  }

  /// بند قائمة موحّد العرض (أيقونة + نصّ).
  Widget _menuRow({
    required IconData icon,
    required Color color,
    required String label,
  }) =>
      SizedBox(
        width: 190,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );

  /// مقبض السحب (يُعطَّل ويبقى مرئياً حين لا تتوفّر مساحة عمل للحساب).
  Widget _dragHandle(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor:
          _canDrag ? SystemMouseCursors.grab : SystemMouseCursors.basic,
      child: GestureDetector(
        key: ValueKey<String>('dock-drag-${widget.panelId}'),
        behavior: HitTestBehavior.opaque,
        onPanStart: _canDrag ? _onDragStart : null,
        onPanUpdate: _canDrag ? _onDragUpdate : null,
        onPanEnd: _canDrag ? (_) => _onDragEnd() : null,
        onPanCancel: _canDrag ? () => _onDragEnd() : null,
        child: Tooltip(
          message: context.l10n?.editorDockTools ?? 'لوحة الأدوات',
          child: SizedBox(
            width: 36,
            height: 26,
            child: Icon(
              Icons.drag_indicator_rounded,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  /// زرّ الطيّ/التوسيع (يبقى في الرأس الرفيع أيضاً).
  Widget _collapseToggle(BuildContext context, DockPanelState state) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: state.collapsed
          ? (context.l10n?.editorDockExpand ?? 'توسيع الأدوات')
          : (context.l10n?.editorDockCollapse ?? 'طيّ الأدوات'),
      child: InkWell(
        key: ValueKey<String>('dock-collapse-${widget.panelId}'),
        onTap: () => widget.dock.toggleCollapsed(widget.panelId),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: SizedBox(
          width: 36,
          height: 26,
          child: Icon(
            state.collapsed
                ? Icons.keyboard_arrow_down_rounded
                : Icons.keyboard_arrow_up_rounded,
            size: 16,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  /// قائمة مواضع الإرساء الأربعة + العودة إلى الافتراضي.
  Widget _anchorMenu(BuildContext context, DockPanelState state) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<Object>(
      key: ValueKey<String>('dock-anchor-${widget.panelId}'),
      tooltip: context.l10n?.editorDockAnchor ?? 'موضع الإرساء',
      padding: EdgeInsets.zero,
      onSelected: (Object value) {
        if (value is DockSlot) {
          widget.dock.moveTo(widget.panelId, value);
        } else {
          widget.dock.reset();
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<Object>>[
        for (final DockSlot slot in DockSlot.values)
          PopupMenuItem<Object>(
            key: ValueKey<String>('dock-slot-${slot.jsonValue}'),
            value: slot,
            // عرض موحّد لكل بند: قائمة منسدلة منتظمة بلا فيض أي بند على
            // حاويتها مهما طال نصّ ترجمته.
            child: _menuRow(
              icon: slot == state.slot
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: slot == state.slot ? scheme.primary : scheme.outline,
              label: _slotName(slot),
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem<Object>(
          key: const ValueKey<String>('dock-reset'),
          value: 'reset',
          child: _menuRow(
            icon: Icons.restart_alt_rounded,
            color: scheme.outline,
            label: context.l10n?.editorDockReset ?? 'إعادة الإرساء الافتراضي',
          ),
        ),
      ],
      child: SizedBox(
        width: 36,
        height: 26,
        child: Icon(
          Icons.dashboard_customize_outlined,
          size: 15,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  /// مقبض تغيير الحجم (سحب رأسي/أفقي داخل الحدود).
  Widget _resizeHandle(BuildContext context, bool vertical) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: vertical
          ? SystemMouseCursors.resizeUpDown
          : SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        key: ValueKey<String>('dock-resize-${widget.panelId}'),
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (DragUpdateDetails details) => widget.dock.resizeBy(
          widget.panelId,
          vertical ? details.delta.dy : details.delta.dx,
        ),
        child: Tooltip(
          message: context.l10n?.editorDockResize ?? 'سحب لتغيير الحجم',
          child: SizedBox(
            height: 12,
            child: Center(
              child: Container(
                width: 30,
                height: 3,
                decoration: BoxDecoration(
                  color: scheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// مؤشّر **الالتقاط المغناطيسي**: شريط مضيء على الحافة المقصودة أثناء السحب.
class DockSnapIndicator extends StatelessWidget {
  const DockSnapIndicator({
    super.key,
    required this.dock,
    this.slotLabel,
  });

  final DockController dock;
  final DockSlotLabel? slotLabel;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: dock,
      builder: (BuildContext context, Widget? _) {
        final DockSnap? snap = dock.snapPreview;
        if (!dock.isDragging || snap == null) return const SizedBox.shrink();
        final Color color = Theme.of(context).colorScheme.primary;
        final Widget band = Container(
          key: ValueKey<String>('dock-snap-indicator-${snap.slot.jsonValue}'),
          color: color.withValues(alpha: 0.35),
        );
        final Widget marker = switch (snap.edge) {
          DockEdge.top => Align(
              alignment: Alignment.topCenter,
              child: SizedBox(height: 8, width: double.infinity, child: band),
            ),
          DockEdge.bottom => Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(height: 8, width: double.infinity, child: band),
            ),
          DockEdge.left => Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(width: 8, height: double.infinity, child: band),
            ),
          DockEdge.right => Align(
              alignment: Alignment.centerRight,
              child: SizedBox(width: 8, height: double.infinity, child: band),
            ),
        };
        final String label = slotLabel?.call(snap.slot) ?? snap.slot.jsonValue;
        return Stack(
          children: <Widget>[
            marker,
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.goldDeep,
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onNavy,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
