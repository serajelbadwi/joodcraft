import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/template_document.dart';
import '../../models/template_element.dart';
import '../../theme/app_colors.dart';
import '../../utils/hex_color.dart';
import '../canvas_geometry.dart';
import '../element_factory.dart';
import '../template_editor_controller.dart';
import 'element_painters.dart';
import 'element_view.dart';

/// مقابس التحجيم والتدوير حول العنصر المحدد.
enum _HandleKind {
  topLeft,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left,
  rotate;

  bool get isCorner =>
      this == topLeft || this == topRight || this == bottomRight || this == bottomLeft;

  bool get isEdge =>
      this == top || this == bottom || this == left || this == right;

  /// موضع المقبس داخل المستطيل (من -1 إلى 1).
  Offset get anchor => switch (this) {
        topLeft => const Offset(-1, -1),
        top => const Offset(0, -1),
        topRight => const Offset(1, -1),
        right => const Offset(1, 0),
        bottomRight => const Offset(1, 1),
        bottom => const Offset(0, 1),
        bottomLeft => const Offset(-1, 1),
        left => const Offset(-1, 0),
        rotate => const Offset(0, -1),
      };

  MouseCursor get cursor => switch (this) {
        topLeft || bottomRight => SystemMouseCursors.resizeUpLeftDownRight,
        topRight || bottomLeft => SystemMouseCursors.resizeUpRightDownLeft,
        top || bottom => SystemMouseCursors.resizeUpDown,
        left || right => SystemMouseCursors.resizeLeftRight,
        rotate => SystemMouseCursors.grab,
      };
}

/// لوحة تحرير A4 التفاعلية.
///
/// * الورقة تُعرض بنفس نِسب الطباعة (A4 أفقي/رأسي).
/// * السحب ينقل العنصر، والمقابس تُحجّمه من ثماني جهات، ومقبض أعلى الوسط يدوّره.
/// * مغناطيس المحاذاة يجذب العناصر إلى حواف الورقة ومنتصفها.
/// * أي حركة تُسجَّل مرة واحدة في سجل التراجع (begin/end interaction).
class TemplateCanvas extends StatefulWidget {
  const TemplateCanvas({
    super.key,
    required this.controller,
    this.zoom = 1,
    this.showGrid = true,
    this.snapToGuides = true,
    this.onRequestTextEdit,
  });

  final TemplateEditorController controller;

  /// معامل تكبير إضافي فوق "ملاءمة الشاشة".
  final double zoom;

  /// إظهار شبكة توجيه خفيفة.
  final bool showGrid;

  /// تفعيل خطوط الإرشاد الذكية والالتصاق المغناطيسي أثناء السحب.
  final bool snapToGuides;

  /// يُستدعى عند النقر المزدوج على نص (لتركيز حقل التحرير في شريط الخصائص).
  final ValueChanged<TextElement>? onRequestTextEdit;

  @override
  State<TemplateCanvas> createState() => _TemplateCanvasState();
}

class _TemplateCanvasState extends State<TemplateCanvas> {
  static const double _handleSize = 11;
  static const double _rotateHandleSize = 24;
  static const double _rotateHandleGap = 26;

  /// هامش طبقة التحديد حول العنصر.
  ///
  /// ⚠️ مهم جداً: مقابس التحجيم تقع **على** حواف العنصر ومقبض التدوير فوق
  /// حده الأعلى، ولأن `RenderBox.hitTest` يرفض أي نقطة خارج صندوق العنصر،
  /// يجب أن تكون الطبقة الحاملة للمقابس أكبر من العنصر نفسه وإلا صارت
  /// الحواف مناطق ميتة لا تستجيب للسحب.
  static const double _selectionMargin = _rotateHandleGap + _rotateHandleSize;

  final GlobalKey _paperKey = GlobalKey();

  ElementBox? _startBox;

  /// صناديق بداية كل عنصر محدد عند بدء سحب المجموعة.
  Map<String, ElementBox> _startBoxes = <String, ElementBox>{};

  Rect? _startRect;
  Offset _accumulated = Offset.zero;
  double _rotateGrabOffset = 0;
  bool _interacting = false;

  /// مستطيل التحديد بالسحب (إحداثيات الورقة) وأصله وحالته التراكمية.
  Rect? _marquee;
  Offset? _marqueeOrigin;
  bool _marqueeAdditive = false;

  /// خطوط الإرشاد الذكية النشطة أثناء السحب (تُخفى فور الإفلات).
  List<SmartGuide> _guides = const <SmartGuide>[];

  /// هل مفتاح التحديد المتعدد (Ctrl/⌘) مضغوط الآن؟
  static bool get _multiSelectPressed {
    final HardwareKeyboard keyboard = HardwareKeyboard.instance;
    return keyboard.isControlPressed || keyboard.isMetaPressed;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (BuildContext context, Widget? _) {
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final TemplateEditorController controller = widget.controller;
            final Size design = controller.designSize;
            final CanvasGeometry geometry = CanvasGeometry.fit(
              viewport: Size(constraints.maxWidth, constraints.maxHeight),
              design: design,
            ).zoomed(widget.zoom);
            final double scale = geometry.scale;
            final Size paperSize = geometry.pageSize(design);

            return GestureDetector(
              // النقر خارج الورقة يُلغي التحديد (داخل الورقة تترجّح أولويات
              // النقر إلى العناصر التي تحته مباشرة).
              behavior: HitTestBehavior.opaque,
              onTap: controller.clearSelection,
              child: Center(
                child: SizedBox(
                  width: paperSize.width,
                  height: paperSize.height,
                  child: Stack(
                    key: _paperKey,
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      // طبقة مستقلّة للخلفية: رَستَرتها (والصورة عالية الدقة)
                      // تُخزَّن فلا تُعاد عند تحريك عنصر أو رسم خطوط الإرشاد.
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: _paperBackground(controller, paperSize),
                        ),
                      ),
                      for (final TemplateElement element
                          in controller.document.elements)
                        _elementLayer(element, controller, design, scale),
                      // خطوط الإرشاد الذكية على طبقة أوفلاي معزولة تماماً
                      // (‎RepaintBoundary + IgnorePointer‎) فلا تلمس رَستَرة العناصر.
                      if (_guides.isNotEmpty)
                        Positioned.fill(
                          child: RepaintBoundary(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: SmartGuidesPainter(
                                  guides: _guides,
                                  scale: scale,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_marquee != null)
                        Positioned.fromRect(
                          rect: _marquee!,
                          child: RepaintBoundary(
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: EditorColors.selection
                                      .withValues(alpha: 0.12),
                                  border: Border.all(
                                    color: EditorColors.selection,
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // المقابس تظهر فقط لعنصر واحد؛ في التحديد الجماعي يكفي
                      // إطار كل عنصر (يُرسم داخل طبقة العنصر نفسها).
                      if (controller.selectionCount == 1 &&
                          controller.selected != null)
                        ..._selectionLayer(
                          controller.selected!,
                          controller,
                          design,
                          scale,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================================================
  //  خلفية الورقة
  // ==========================================================================
  Widget _paperBackground(
    TemplateEditorController controller,
    Size paperSize,
  ) {
    final TemplateDocument document = controller.document;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: controller.clearSelection,
      // السحب على فراغ الورقة يرسم مستطيل تحديد جماعي.
      onPanStart: _onMarqueeStart,
      onPanUpdate: _onMarqueeUpdate,
      onPanEnd: (_) => _endMarquee(controller),
      onPanCancel: _cancelMarquee,
      onDoubleTapDown: (TapDownDetails details) =>
          _addTextAt(details.localPosition),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorFromHex(document.backgroundHex, fallback: Colors.white),
          // حدود واضحة للورقة في الوضعين: خيط باهت فوق مساحة العمل الداكنة
          // والفاتحة معاً حتى لا تلتصق ألوان التصميم بخلفية البرنامج.
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          boxShadow: <BoxShadow>[
            BoxShadow(
              // الظل الكحلي يكفي على الفاتح؛ الداكن يحتاج ظلاً أعمق ليُبرز
              // حدود الورقة البيضاء عن مساحة العمل الليلية.
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withValues(alpha: 0.55)
                  : AppColors.navyShadow(0.16),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: widget.showGrid
            ? CustomPaint(painter: const GridPainter(step: 24))
            : const SizedBox.expand(),
      ),
    );
  }

  // ==========================================================================
  //  طبقة العناصر
  // ==========================================================================
  Widget _elementLayer(
    TemplateElement element,
    TemplateEditorController controller,
    Size design,
    double scale,
  ) {
    final Rect rect = _screenRect(element, design, scale);
    final bool selected = controller.isSelected(element.id);
    final double radians = element.rotation * math.pi / 180;

    // `RepaintBoundary` حول محتوى العنصر: يبقى محتواه (خاصةً الصور الكبيرة)
    // مخزّناً كطبقة رَسم مستقلّة، فلا يُعاد رسمه عند تحريك عنصر آخر أو رسم
    // خطوط الإرشاد. والإطار/المقابس تُرسم في طبقة منفصلة عنه.
    final Widget content = RepaintBoundary(
      child: SizedBox(
        width: rect.width,
        height: rect.height,
        child: ElementView(
          element: element,
          document: controller.document,
          scale: scale,
        ),
      ),
    );

    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: Transform.rotate(
        angle: radians,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _onElementTap(element, controller),
          onDoubleTap: () {
            controller.select(element.id);
            if (element is TextElement) widget.onRequestTextEdit?.call(element);
          },
          onPanStart: (_) => _startMove(element, controller),
          onPanUpdate: (DragUpdateDetails details) =>
              _updateMove(details.delta / scale, controller),
          onPanEnd: (_) => _endInteraction(controller),
          onPanCancel: () => _endInteraction(controller),
          child: selected
              ? Stack(
                  clipBehavior: Clip.none,
                  fit: StackFit.expand,
                  children: <Widget>[
                    content,
                    // إطار التحديد يُرسم داخل العنصر نفسه لأن العنصر مُدوَّر.
                    IgnorePointer(
                      child: CustomPaint(
                        painter: const BorderPainter(
                          color: EditorColors.selection,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ],
                )
              : content,
        ),
      ),
    );
  }

  // ==========================================================================
  //  طبقة التحديد (المقابس)
  // ==========================================================================
  List<Widget> _selectionLayer(
    TemplateElement element,
    TemplateEditorController controller,
    Size design,
    double scale,
  ) {
    final Rect rect = _screenRect(element, design, scale);
    final double radians = element.rotation * math.pi / 180;

    return <Widget>[
      Positioned(
        left: rect.left - _selectionMargin,
        top: rect.top - _selectionMargin,
        width: rect.width + _selectionMargin * 2,
        height: rect.height + _selectionMargin * 2,
        child: Transform.rotate(
          // الدوران حول مركز العنصر تماماً (الطبقة متماثلة حوله).
          angle: radians,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              for (final _HandleKind handle in _HandleKind.values)
                _handleWidget(handle, element, controller, rect, scale),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _handleWidget(
    _HandleKind handle,
    TemplateElement element,
    TemplateEditorController controller,
    Rect rect,
    double scale,
  ) {
    final bool isRotate = handle == _HandleKind.rotate;
    final double size = isRotate ? _rotateHandleSize : _handleSize;
    final Offset anchor = handle.anchor;

    // موضع مركز المقبس داخل طبقة التحديد (بإضافة هامش المقابس).
    final double cx = _selectionMargin + (rect.width / 2) * (1 + anchor.dx);
    final double cy = _selectionMargin +
        (rect.height / 2) * (1 + anchor.dy) -
        (isRotate ? _rotateHandleGap : 0);

    return Positioned(
      key: Key('handle-${handle.name}'),
      left: cx - size / 2,
      top: cy - size / 2,
      width: size,
      height: size,
      child: MouseRegion(
        cursor: handle.cursor,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (DragStartDetails details) =>
              _startHandle(handle, element, controller, rect, details),
          onPanUpdate: (DragUpdateDetails details) =>
              _updateHandle(handle, details, controller, rect, scale),
          onPanEnd: (_) => _endInteraction(controller),
          onPanCancel: () => _endInteraction(controller),
          child: isRotate
              ? _rotateHandleDecoration()
              : _resizeHandleDecoration(handle),
        ),
      ),
    );
  }

  Widget _resizeHandleDecoration(_HandleKind handle) {
    return Center(
      child: Container(
        width: _handleSize,
        height: _handleSize,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: EditorColors.handle, width: 1.6),
          borderRadius: BorderRadius.circular(2.5),
        ),
      ),
    );
  }

  Widget _rotateHandleDecoration() {
    return Center(
      child: Container(
        width: _rotateHandleSize,
        height: _rotateHandleSize,
        decoration: BoxDecoration(
          color: AppColors.navy,
          shape: BoxShape.circle,
          border: Border.all(color: EditorColors.handle, width: 1.6),
        ),
        child: const Icon(
          Icons.rotate_right_rounded,
          size: 14,
          color: AppColors.gold,
        ),
      ),
    );
  }

  // ==========================================================================
  //  السحب (النقل)
  // ==========================================================================

  /// نقر عنصر: مع Ctrl/⌘ يُبدّل عضويته، وإلا يُفرد التحديد عليه.
  void _onElementTap(
    TemplateElement element,
    TemplateEditorController controller,
  ) {
    if (_multiSelectPressed) {
      controller.toggleSelection(element.id);
    } else {
      controller.select(element.id);
    }
  }

  void _startMove(TemplateElement element, TemplateEditorController controller) {
    // العنصر إن كان جزءاً من تحديد جماعي يبقى التحديد ويُحرّك الكل ككتلة.
    if (!controller.isSelected(element.id)) {
      controller.select(element.id);
    }
    _interacting = true;
    _startBox = _designBox(element, controller.designSize);
    _startBoxes = <String, ElementBox>{
      for (final TemplateElement selected in controller.selectedElements)
        selected.id: _designBox(selected, controller.designSize),
    };
    _accumulated = Offset.zero;
    _guides = const <SmartGuide>[];
    controller.beginInteraction();
  }

  void _updateMove(Offset deltaInDesignUnits, TemplateEditorController controller) {
    final ElementBox? start = _startBox;
    if (!_interacting || start == null) return;
    _accumulated += deltaInDesignUnits;

    if (controller.selectionCount <= 1) {
      final ElementBox desired = start.copyWith(
        x: start.x + _accumulated.dx,
        y: start.y + _accumulated.dy,
      );
      if (widget.snapToGuides) {
        final SnapOutcome outcome = SmartGuides.snap(
          box: desired,
          design: controller.designSize,
          others: _guideTargets(controller),
        );
        controller.setSelectedBox(outcome.box, snap: false);
        _setGuides(outcome.guides);
      } else {
        controller.setSelectedBox(desired, snap: false);
        _setGuides(const <SmartGuide>[]);
      }
      return;
    }

    // المجموعة تتحرك بنفس الفرق مع حفظ المسافات بين عناصرها.
    controller.setSelectionBoxes(
      <String, ElementBox>{
        for (final MapEntry<String, ElementBox> entry in _startBoxes.entries)
          entry.key: entry.value.copyWith(
            x: entry.value.x + _accumulated.dx,
            y: entry.value.y + _accumulated.dy,
          ),
      },
    );
  }

  // ==========================================================================
  //  التحجيم
  // ==========================================================================
  void _startHandle(
    _HandleKind handle,
    TemplateElement element,
    TemplateEditorController controller,
    Rect rect,
    DragStartDetails details,
  ) {
    controller.select(element.id);
    controller.beginInteraction();
    _interacting = true;
    _accumulated = Offset.zero;
    _startBox = _designBox(element, controller.designSize);
    _startRect = rect;

    if (handle == _HandleKind.rotate) {
      _rotateGrabOffset = _pointerAngle(details.globalPosition, rect) -
          element.rotation;
    }
  }

  void _updateHandle(
    _HandleKind handle,
    DragUpdateDetails details,
    TemplateEditorController controller,
    Rect rect,
    double scale,
  ) {
    if (handle == _HandleKind.rotate) {
      final double angle =
          _pointerAngle(details.globalPosition, _startRect ?? rect) -
              _rotateGrabOffset;
      controller.setSelectedRotation(angle);
      return;
    }

    final ElementBox? start = _startBox;
    if (start == null) return;

    // إزاحة المؤشر بمعزل عن دوران العنصر حتى يبقى التحجيم "طبيعياً" بصرياً.
    final TemplateElement? current = controller.selected;
    final double radians = (current?.rotation ?? 0) * math.pi / 180;
    _accumulated += _rotateOffset(details.delta / scale, -radians);

    controller.setSelectedBox(
      _applyResize(handle, start, _accumulated),
      snap: true,
    );
  }

  /// حساب الصندوق الجديد من الصندوق الأصلي + الإزاحة المتراكمة.
  static ElementBox _applyResize(
    _HandleKind handle,
    ElementBox start,
    Offset delta,
  ) {
    double x = start.x;
    double y = start.y;
    double width = start.width;
    double height = start.height;

    final bool movesLeft = handle == _HandleKind.topLeft ||
        handle == _HandleKind.left ||
        handle == _HandleKind.bottomLeft;
    final bool movesRight = handle == _HandleKind.topRight ||
        handle == _HandleKind.right ||
        handle == _HandleKind.bottomRight;
    final bool movesTop = handle == _HandleKind.topLeft ||
        handle == _HandleKind.top ||
        handle == _HandleKind.topRight;
    final bool movesBottom = handle == _HandleKind.bottomLeft ||
        handle == _HandleKind.bottom ||
        handle == _HandleKind.bottomRight;

    if (movesLeft) {
      final double nextX = start.x + delta.dx;
      final double maxX = start.x + start.width - TemplateEditorController.minElementSize;
      x = math.min(nextX, maxX);
      width = start.width + (start.x - x);
    } else if (movesRight) {
      width = math.max(
        start.width + delta.dx,
        TemplateEditorController.minElementSize,
      );
    }

    if (movesTop) {
      final double nextY = start.y + delta.dy;
      final double maxY =
          start.y + start.height - TemplateEditorController.minElementSize;
      y = math.min(nextY, maxY);
      height = start.height + (start.y - y);
    } else if (movesBottom) {
      height = math.max(
        start.height + delta.dy,
        TemplateEditorController.minElementSize,
      );
    }

    return ElementBox(x: x, y: y, width: width, height: height);
  }

  /// زاوية المؤشر حول مركز المستطيل (بالدرجات).
  double _pointerAngle(Offset globalPosition, Rect rect) {
    final RenderBox? render =
        _paperKey.currentContext?.findRenderObject() as RenderBox?;
    if (render == null) return 0;
    final Offset local = render.globalToLocal(globalPosition);
    final Offset center = rect.center;
    return math.atan2(local.dy - center.dy, local.dx - center.dx) *
        180 /
        math.pi;
  }

  static Offset _rotateOffset(Offset offset, double radians) {
    final double cos = math.cos(radians);
    final double sin = math.sin(radians);
    return Offset(
      offset.dx * cos - offset.dy * sin,
      offset.dx * sin + offset.dy * cos,
    );
  }

  void _endInteraction(TemplateEditorController controller) {
    if (_interacting) controller.endInteraction();
    _interacting = false;
    _startBox = null;
    _startBoxes = <String, ElementBox>{};
    _startRect = null;
    _accumulated = Offset.zero;
    // إخفاء كل الخطوط الإرشادية فور الإفلات.
    if (_guides.isNotEmpty) setState(() => _guides = const <SmartGuide>[]);
  }

  /// صناديق باقي العناصر (بوحدات التصميم) كأهداف للمحاذاة الذكية.
  List<ElementBox> _guideTargets(TemplateEditorController controller) {
    final String? activeId = controller.selectedId;
    return <ElementBox>[
      for (final TemplateElement element in controller.document.elements)
        if (element.id != activeId) _designBox(element, controller.designSize),
    ];
  }

  void _setGuides(List<SmartGuide> guides) {
    if (guides.isEmpty) {
      if (_guides.isEmpty) return;
      setState(() => _guides = const <SmartGuide>[]);
      return;
    }
    setState(() => _guides = guides);
  }

  // ==========================================================================
  //  أدوات القياس
  // ==========================================================================

  /// صندوق العنصر بوحدات التصميم، مع حلّ العرض/الارتفاع التلقائي.
  ElementBox _designBox(TemplateElement element, Size design) {
    final double width = element.box.width > 0
        ? element.box.width
        : math.max(0, design.width - element.box.x);
    double height = element.box.height;
    if (height <= 0) height = _autoHeight(element, width);
    return ElementBox(
      x: element.box.x,
      y: element.box.y,
      width: width,
      height: height,
    );
  }

  /// ارتفاع العنصر عندما لا يُحدَّد صراحةً (`height: 0` = تلقائي).
  double _autoHeight(TemplateElement element, double width) {
    if (element is! TextElement) return width > 0 ? width : 24;
    final String resolved = widget.controller.document
        .resolveFields(element.text, null, keepUnknownTokens: true);
    final bool rtl = editorTextIsRtl(element, resolved);
    final TextPainter painter = TextPainter(
      text: TextSpan(text: resolved, style: editorTextStyle(element, 1)),
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
    )..layout(maxWidth: width > 0 ? width : double.infinity);
    return painter.height;
  }

  /// مستطيل العنصر بإحداثيات اللوحة (بكسل).
  Rect _screenRect(TemplateElement element, Size design, double scale) {
    final ElementBox box = _designBox(element, design);
    return Rect.fromLTWH(
      box.x * scale,
      box.y * scale,
      box.width * scale,
      box.height * scale,
    );
  }

  // ==========================================================================
  //  التحديد الجماعي بالسحب (Marquee / Selection Box)
  // ==========================================================================
  void _onMarqueeStart(DragStartDetails details) {
    setState(() {
      _marqueeOrigin = details.localPosition;
      _marquee = Rect.fromPoints(details.localPosition, details.localPosition);
      // مع Ctrl/⌘ يُضاف المستطيل إلى التحديد الحالي بدل استبداله.
      _marqueeAdditive = _multiSelectPressed;
    });
  }

  void _onMarqueeUpdate(DragUpdateDetails details) {
    final Offset? origin = _marqueeOrigin;
    if (origin == null) return;
    setState(() => _marquee = Rect.fromPoints(origin, details.localPosition));
  }

  void _cancelMarquee() {
    if (_marquee == null && _marqueeOrigin == null) return;
    setState(() {
      _marquee = null;
      _marqueeOrigin = null;
      _marqueeAdditive = false;
    });
  }

  void _endMarquee(TemplateEditorController controller) {
    final Rect? rect = _marquee;
    if (rect == null) return;

    final RenderBox? render =
        _paperKey.currentContext?.findRenderObject() as RenderBox?;
    if (render != null && render.size.width > 0) {
      final Size design = controller.designSize;
      final double scale = render.size.width / design.width;
      controller.selectWithin(
        Rect.fromLTWH(
          rect.left / scale,
          rect.top / scale,
          rect.width / scale,
          rect.height / scale,
        ),
        additive: _marqueeAdditive,
      );
    }

    setState(() {
      _marquee = null;
      _marqueeOrigin = null;
      _marqueeAdditive = false;
    });
  }

  /// إضافة نص جديد عند موضع النقر المزدوج (النقر على فراغ الورقة).
  void _addTextAt(Offset localPosition) {
    final TemplateEditorController controller = widget.controller;
    final Size design = controller.designSize;

    final RenderBox? render =
        _paperKey.currentContext?.findRenderObject() as RenderBox?;
    if (render == null) return;
    final Size paper = render.size;
    final double scale = paper.width / design.width;

    final TemplateElement element =
        ElementFactory.create(kind: NewElementKind.text, design: design);
    final double width = element.box.width;
    final double height = element.box.height;
    controller.addElementInstance(
      element.withBox(
        ElementBox(
          x: (localPosition.dx / scale - width / 2)
              .clamp(0.0, math.max(0, design.width - width)),
          y: (localPosition.dy / scale - height / 2)
              .clamp(0.0, math.max(0, design.height - height)),
          width: width,
          height: height,
        ),
      ),
    );
  }
}

/// إطار بسيط حول العنصر المحدد.
class BorderPainter extends CustomPainter {
  const BorderPainter({required this.color, required this.width});

  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(width / 2, width / 2, size.width - width, size.height - width),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  @override
  bool shouldRepaint(BorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.width != width;
}
