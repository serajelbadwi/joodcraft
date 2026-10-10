import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../assets/assets_controller.dart';
import '../../assets/user_asset.dart';
import '../../constants/app_constants.dart';
import '../../models/template_document.dart';
import '../../models/template_element.dart';
import '../../models/text_styling.dart';
import '../../pdf/pdf_font_catalog.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/hex_color.dart';
import '../canvas_geometry.dart';
import '../element_factory.dart';
import '../element_hit_picker.dart';
import '../../fonts/custom_font_controller.dart';
import '../template_editor_controller.dart';
import 'editor_controls.dart';
import 'element_painters.dart';
import 'element_view.dart';

/// تحويل تدرّج خلفية المستند إلى [LinearGradient] للوحة — أو `null` إن لم يوجد.
///
/// مشترك بين اللوحة وبقية واجهات المحرّر حتى تكون دلالة الاتجاه واحدة، فلا
/// يختلف ما يراه المستخدم عمّا يُطبع في الـ PDF.
LinearGradient? paperGradient(BackgroundGradient? gradient) {
  if (gradient == null) return null;
  final (Alignment begin, Alignment end) = switch (gradient.direction) {
    GradientDirection.vertical => (Alignment.topCenter, Alignment.bottomCenter),
    GradientDirection.horizontal => (
        Alignment.centerLeft,
        Alignment.centerRight
      ),
    GradientDirection.diagonal => (Alignment.topLeft, Alignment.bottomRight),
  };
  return LinearGradient(
    begin: begin,
    end: end,
    colors: <Color>[
      colorFromHex(gradient.startHex, fallback: Colors.white),
      colorFromHex(gradient.endHex, fallback: Colors.white),
    ],
  );
}

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
    this.paperKey,
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

  /// مفتاح رَسم الورقة — يمرّره المحرّر ليلتقط منه **الصورة المصغّرة** للمشروع
  /// عند الحفظ (راجع `ProjectThumbnails`). `null` يعني مفتاحاً داخلياً خاصاً
  /// باللوحة، فلا يلزم أحداً.
  final GlobalKey? paperKey;

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

  final GlobalKey _localPaperKey = GlobalKey();

  /// مفتاح الورقة الفعّال: الممرَّر من المحرّر إن وُجد وإلا المفتاح الداخلي.
  GlobalKey get _paperKey => widget.paperKey ?? _localPaperKey;

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

  // ==========================================================================
  //                   التحرير المباشر على اللوحة
  // ==========================================================================

  /// معرّف العنصر قيد التحرير المباشر — `null` يعني أنه لا تحرير جارٍ.
  ///
  /// وجوده يُبطِل رسم إطار التحديد ومقابسه لهذا العنصر ويحلّ حقل كتابة محلّه،
  /// فتختفي كل الحواجز أثناء الكتابة تماماً كما في Word وفوتوشوب.
  String? _editingId;

  /// متحكّم حقل التحرير وعقدة تركيزه — يُخلَّقان عند الدخول ويُتلفان عند الخروج.
  TextEditingController? _editController;
  FocusNode? _editFocus;

  /// هل فُتحت خطوة تراجع لهذه الجلسة؟ (تُفتح أوّل تغيير وحده، فجلسة تحرير
  /// بلا تعديل لا تترك خطوة تراجع فارغة في السجل.)
  bool _editHistoryOpen = false;

  /// حدود التحديد داخل الحقل — بها يعرف الشريط العائم أيّ جزء يُنسَّق.
  TextSelection _editSelection = const TextSelection.collapsed(offset: -1);

  /// هل بدأت الشجرة بالتلاشي؟ — يمنع `setState` على عنصر متوفّى أثناء
  /// التفكيك (كان يرمي استثناءً في نهاية كل اختبار يفتح التحرير المباشر).
  bool _disposed = false;

  /// هل مفتاح التحديد المتعدد (Ctrl/⌘) مضغوط الآن؟
  static bool get _multiSelectPressed {
    final HardwareKeyboard keyboard = HardwareKeyboard.instance;
    return keyboard.isControlPressed || keyboard.isMetaPressed;
  }

  @override
  void dispose() {
    // خروج نظيف من التحرير المباشر: يُكتب النص المتبقي ثم يُتلف الحقل والعقدة.
    _disposed = true;
    _commitTextEdit();
    super.dispose();
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
            // معرّفات صور الإطارات (حُسبت مرة واحدة للبناء تُمرَّر إلى بوابات
            // الإصابة بدل تكرار البحث في المكتبة لكل طبقة).
            final Set<String> frameIds = _frameImageIds(controller);

            // العنصر قيد التحرير المباشر يُستخرج من الطبقة العادية ليُرسم حقل
            // كتابة فوقها؛ فلا يُغطّيه عنصر أحدث، ولا يبقى له إطار ولا مقابس.
            final TemplateElement? editing = _editingElement(controller);

            return GestureDetector(
              // النقر خارج الورقة يُلغي التحديد (داخل الورقة تترجّح أولويات
              // النقر إلى العناصر التي تحته مباشرة).
              behavior: HitTestBehavior.opaque,
              onTap: () => _onBlankTap(controller),
              child: Center(
                child: SizedBox(
                  width: paperSize.width,
                  height: paperSize.height,
                  child: ClipRect(
                    child: Stack(
                      key: _paperKey,
                      clipBehavior: Clip.hardEdge,
                      children: <Widget>[
                      // طبقة مستقلّة للخلفية: رَستَرتها (والصورة عالية الدقة)
                      // تُخزَّن فلا تُعاد عند تحريك عنصر أو رسم خطوط الإرشاد.
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: _paperBackground(controller, paperSize),
                        ),
                      ),
                      // العناصر المخفية لا تُرسم أصلاً (كما لا تُطبع)، وكذلك
                      // العنصر قيد التحرير المباشر: مكانه طبقة الحقل بعد قليل.
                      for (final TemplateElement element
                          in controller.document.elements)
                        if (!controller.isElementHidden(element.id) &&
                            element.id != _editingId)
                          _elementLayer(
                            element,
                            controller,
                            design,
                            scale,
                            frameIds,
                          ),
                      if (editing is TextElement)
                        _editingLayer(editing, controller, design, scale),
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
                      // إطار كل عنصر (يُرسم داخل طبقة العنصر نفسها)، وتُخفى كلياً
                      // أثناء التحرير المباشر لأن الإطار نفسه مطلوب اختفاءه.
                      if (controller.selectionCount == 1 &&
                          controller.selected != null &&
                          controller.selected!.id != _editingId)
                        ..._selectionLayer(
                          controller.selected!,
                          controller,
                          design,
                          scale,
                        ),
                      // الشريط العائم آخر الطبقة كي يعلو كل شيء ويبقى قابلاً للنقر.
                      if (editing is TextElement && _hasEditSelection)
                        _floatingTextToolbar(editing, design, scale),
                    ],
                  ),
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
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onBlankTap(controller),
      // السحب على فراغ الورقة يرسم مستطيل تحديد جماعي.
      onPanStart: _onMarqueeStart,
      onPanUpdate: _onMarqueeUpdate,
      onPanEnd: (_) => _endMarquee(controller),
      onPanCancel: _cancelMarquee,
      onDoubleTapDown: (TapDownDetails details) =>
          _addTextAt(details.localPosition),
      child: DecoratedBox(
        decoration: BoxDecoration(
          // الخلفية إما لون مفرد أو تدرّج — والتدرّج يتقدّم عند وجوده، تماماً
          // كما يُصدَّر في الـ PDF.
          gradient: paperGradient(document.backgroundGradient),
          color: document.backgroundGradient == null
              ? colorFromHex(document.backgroundHex, fallback: Colors.white)
              : null,
          // حدود واضحة للورقة في الوضعين: خيط باهت فوق مساحة العمل الداكنة
          // والفاتحة معاً حتى لا تلتصق ألوان التصميم بخلفية البرنامج.
          border: Border.all(color: scheme.outline),
          // ظل **ناعم متدرّج** (12px تمويهاً + 2px انتشاراً) يرفع الورقة عن
          // مساحة العمل ذات الطنّ المتوسط بلا حدّة، كما في أدوات التصميم
          // الاحترافية. لونه يكيفيّ مع السطوع: أسود شفّاف ليلاً، كحلي خفيف
          // نهاراً — راجع `paperShadow`.
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: scheme.paperShadow,
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
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
    Set<String> frameIds,
  ) {
    final Rect rect = _screenRect(element, design, scale);
    final bool selected = controller.isSelected(element.id);
    final double radians = element.rotation * math.pi / 180;

    // `RepaintBoundary` حول محتوى العنصر: يبقى محتواه (خاصةً الصور الكبيرة)
    // مخزّناً كطبقة رَسم مستقلّة، فلا يُعاد رسمه عند تحريك عنصر آخر أو رسم
    // خطوط الإرشاد. والإطار/المقابس تُرسم في طبقة منفصلة عنه.
    // معاينة الخط الحية للعنصر المحدد (من منتقي الشريط الجانبي): عائلة مؤقتة
    // تُفرض على العنصر بصريّة فقط — الوثيقة لم تتغيّر.
    final TemplateElement shown =
        _fontPreviewElement(element, controller, selected);
    final Widget content = RepaintBoundary(
      child: SizedBox(
        width: rect.width,
        height: rect.height,
        child: ElementView(
          element: shown,
          document: controller.document,
          scale: scale,
          gender: controller.previewGender,
        ),
      ),
    );

    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      // بوابة اختبار الإصابة: تستقبل النقر (والنقل والتحرير) لهذه الطبقة فقط
      // إذا كان هذا العنصر هو الهدف الأصغر/الأعلى تحت المؤشر؛ وإلا ترفض ليمرّ
      // النقر إلى ما تحتها (العناصر الأدلى) ثم إلى الورقة. والعنصر المقفل
      // يرفض دائماً فيبقى النقر للعناصر تحته (لا يُزاحم ولا يُحدَّد).
      child: _ElementHitGate(
        origin: Offset(rect.left, rect.top),
        shouldHit: (Offset paperPoint) =>
            controller.document.isInteractive(element) &&
            _isElementPick(
              paperPoint,
              element,
              controller,
              design,
              scale,
              frameIds,
            ),
        child: Transform.rotate(
          angle: radians,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _onElementTap(element, controller),
            onDoubleTap: () {
              controller.select(element.id);
              if (element is TextElement) {
                // تحرير مباشر في موضع العنصر نفسه: بلا لوحة جانبية وبلا إطار.
                _startTextEdit(element, controller);
                widget.onRequestTextEdit?.call(element);
              }
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
      ),
    );
  }

  // ==========================================================================
  //  اختبار الإصابة (أي عنصر تحت المؤشر؟)
  // ==========================================================================

  /// معرّفات صور الإطارات (أصول من نوع «إطار»): حاويات مفرغة تُنقر على حدّها.
  Set<String> _frameImageIds(TemplateEditorController controller) {
    final Set<String> ids = <String>{};
    for (final TemplateElement element in controller.document.elements) {
      if (element is! ImageElement) continue;
      if (element.sourceKind != ImageSourceKind.userAsset) continue;
      final UserAsset? asset = AssetsController.instance.byId(element.path);
      if (asset != null && asset.type == AssetType.border) ids.add(element.id);
    }
    return ids;
  }

  /// هل [element] هو الهدف المستهدف تحت النقطة [paperPoint] (بكسلات اللوحة)؟
  ///
  /// تُحوَّل النقطة إلى إحداثيات التصميم ثم يُستدعى المنطق النقي في
  /// [pickElementAt]: الأصغر مساحة أولاً، وعند التساوي الأعلى طبقة (z).
  bool _isElementPick(
    Offset paperPoint,
    TemplateElement element,
    TemplateEditorController controller,
    Size design,
    double scale,
    Set<String> frameIds,
  ) {
    if (!(scale > 0)) return true; // حماية: بلا مقياس صالح لا نُسقط النقر.
    final TemplateElement? pick = pickElementAt(
      controller.document.elements
          .where(controller.document.isInteractive)
          .toList(growable: false),
      point: paperPoint / scale,
      resolveBox: (TemplateElement item) => _designBox(item, design),
      frameIds: frameIds,
    );
    return pick != null && pick.id == element.id;
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
          // مقبض التدوير: فحمي ليلاً وكحلي نهاراً (لا كتلة كحلية في الداكن).
          color: Theme.of(context).colorScheme.brandSurfaceSoft,
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
    // النقر على عنصر آخر يُنهي التحرير المباشر للعنصر الجاري أولاً.
    _commitIfEditingOther(element.id);
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
    final String resolved = widget.controller.document.resolveFields(
      element.text,
      null,
      keepUnknownTokens: true,
      gender: widget.controller.previewGender,
    );
    final bool rtl = editorTextIsRtl(element, resolved);
    final TextPainter painter = TextPainter(
      text: TextSpan(text: resolved, style: editorTextStyle(element, 1)),
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
    )..layout(maxWidth: width > 0 ? width : double.infinity);
    return painter.height;
  }

  /// نسخة العنصر للمعاينة الحيّة للخط: تُفرض عليها عائلة الخط المؤقتة إن كان
  /// العنصر المحدد نصّاً؛ وإلا يُعاد كما هو.
  TemplateElement _fontPreviewElement(
    TemplateElement element,
    TemplateEditorController controller,
    bool selected,
  ) {
    final String? preview = controller.fontPreviewUiFamily;
    if (preview == null || preview.isEmpty || !selected) return element;
    if (element is! TextElement) return element;
    return element.copyWith(customFont: preview);
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
  //                 التحرير المباشر على اللوحة (Inline Editing)
  // ==========================================================================

  /// العنصر قيد التحرير المباشر — يُرجَع `null` إن اختفى أو خرج من التحرير.
  TextElement? _editingElement(TemplateEditorController controller) {
    final String? id = _editingId;
    if (id == null || _editController == null || _editFocus == null) return null;
    final TemplateElement? element = _elementById(controller, id);
    if (element is! TextElement) return null;
    if (controller.isElementHidden(element.id)) return null;
    return element;
  }

  TemplateElement? _elementById(
    TemplateEditorController controller,
    String id,
  ) {
    for (final TemplateElement element in controller.document.elements) {
      if (element.id == id) return element;
    }
    return null;
  }

  /// هل يُظلَّل مقطع صالح داخل الحقل؟ (به يظهر الشريط العائم)
  bool get _hasEditSelection {
    final TextSelection selection = _editSelection;
    if (!selection.isValid || selection.isCollapsed) return false;
    final String text = _editController?.text ?? '';
    final int start = math.min(selection.start, selection.end);
    final int end = math.max(selection.start, selection.end);
    return start >= 0 && end <= text.length && end > start;
  }

  /// يفتح خطوة تراجع واحدة للجلسة كاملة (نصّ + أحجام + تنسيق جزئي).
  void _openEditHistory(TemplateEditorController controller) {
    if (_editHistoryOpen) return;
    _editHistoryOpen = true;
    controller.beginInteraction();
  }

  /// يبدأ التحرير المباشر لـ[element] في موضعه على اللوحة.
  void _startTextEdit(TextElement element, TemplateEditorController controller) {
    if (_editingId == element.id) return;
    _commitTextEdit();

    final TextEditingController field = TextEditingController(text: element.text);
    final FocusNode focus = FocusNode(debugLabel: 'inline-${element.id}');
    _editHistoryOpen = false;
    _editSelection = const TextSelection.collapsed(offset: -1);
    field.addListener(_onEditChanged);

    setState(() {
      _editingId = element.id;
      _editController = field;
      _editFocus = focus;
    });

    // المؤشر في نهاية النص — بعد بناء الحقل فعلاً وإلا ضاع التركيز.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted || _editController != field) return;
      field.selection = TextSelection.collapsed(offset: field.text.length);
      focus.requestFocus();
    });
  }

  void _onEditChanged() {
    if (_editingId == null) return;
    final TextSelection selection = _editController?.selection ??
        const TextSelection.collapsed(offset: -1);
    if (selection == _editSelection) return;
    setState(() => _editSelection = selection);
  }

  /// يُلتزم التحرير: يكتب النص والصندوق المُلاءَم مرّة واحدة ثم يُغلق الحقل.
  void _commitTextEdit() {
    final String? id = _editingId;
    if (id == null && _editController == null && _editFocus == null) return;

    final TextEditingController? field = _editController;
    final FocusNode? focus = _editFocus;
    _editingId = null;
    _editController = null;
    _editFocus = null;
    _editSelection = const TextSelection.collapsed(offset: -1);

    final TemplateEditorController controller = widget.controller;
    field?.removeListener(_onEditChanged);
    final bool opened = _editHistoryOpen;
    _editHistoryOpen = false;

    try {
      final TemplateElement? current =
          id == null ? null : _elementById(controller, id);
      if (current is TextElement &&
          field != null &&
          field.text != current.text) {
        if (!opened) controller.beginInteraction();
        controller.replaceElement(
          current.copyWith(
            text: field.text,
            box: _autoFitBox(current, field.text, controller.designSize),
          ),
        );
        controller.endInteraction();
      } else if (opened) {
        controller.endInteraction();
      }
    } on Object catch (error) {
      // عند التفكيك قد تكون الشجرة وقد أُزيل مستمعوها؛ التعديل نفسه مسجَّل
      // في المستند، فلا نُسقط إغلاق المحرّر بسبب فشل إشعار.
      debugPrint('[canvas] تعذّر إنهاء تحرير النص: $error');
    } finally {
      // إلغاء التركيز قبل التلف: يُغلق مقبض الإدخال ويتحرّر مؤشر النقر فوراً
      // ليعود سحب العناصر بالمؤشر (GestureDetector) دون أي تعليق أو تدخّل مع
      // حقل النص المتوفّق.
      focus?.unfocus();
      field?.dispose();
      focus?.dispose();
    }

    if (!_disposed && mounted) setState(() {});
  }

  /// يغلق التحرير المباشر إن كان المُستدعي آخر غير العنصر الجاري — يُستدعى
  /// عند النقر على عنصر آخر أو على فراغ الورقة، فيُلتزم ما كُتب ويتحرّر الحقل.
  void _commitIfEditingOther(String? elementId) {
    if (_editingId == null) return;
    if (elementId != null && elementId == _editingId) return;
    _commitTextEdit();
  }

  /// نقر على فراغ (خارج الورقة أو داخلها): يُلتزم التحرير المباشر إن كان
  /// مفتوحاً، ثم يُلغي التحديد — إلا أن العنصر الذي انتهى تحريره يبقى
  /// محدَّداً كي تعود أطاره ومقابسه فوراً كما في Word.
  void _onBlankTap(TemplateEditorController controller) {
    final String? editingId = _editingId;
    _commitIfEditingOther(null);
    if (editingId != null && _elementById(controller, editingId) != null) {
      controller.select(editingId);
    } else {
      controller.clearSelection();
    }
  }

  /// يكتب النص الجاري في الحقل إلى المستند **من دون** إنهاء التحرير.
  ///
  /// يُستدعى قبل تطبيق تنسيق جزئي كي تُحسب الإزاحات على نصٍّ واحد هو نفسه في
  /// الحقل وفي المستند — وإلا لانزلقت حدود التحديد عن كلماتها.
  void _flushLiveText(TemplateEditorController controller) {
    final String? id = _editingId;
    final TextEditingController? field = _editController;
    if (id == null || field == null) return;
    final TemplateElement? current = _elementById(controller, id);
    if (current is! TextElement || field.text == current.text) return;
    _openEditHistory(controller);
    controller.replaceElement(
      current.copyWith(
        text: field.text,
        box: _autoFitBox(current, field.text, controller.designSize),
      ),
    );
  }

  /// النطاقات المعمول بها للنص الجاري في الحقل.
  List<StyledTextSpan> _liveSpans(TextElement element, String current) {
    if (current == element.text) return element.spans;
    return StyledTextSpan.remapAfterEdit(
      oldText: element.text,
      newText: current,
      spans: element.spans,
    );
  }

  /// صندوق العنصر بعد ملاءمة **ارتفاعه** للنص (« resize shape to fit text »).
  ///
  /// يُحسب **دون لمس المستند** أثناء الكتابة، فيكبر الحقل مع كل حرف ويُكتب
  /// التعديل مرّة واحدة عند الالتزام — فلا خطوة تراجع لكل ضغطة مفتاح ولا
  /// إشعار إعادة رسم لكل حرف. الصندوق تلقائي الارتفاع (‎0‎) يبقى تلقائياً
  /// لأن محلّه يحتسبه من المحتوى أصلاً.
  ElementBox _autoFitBox(TextElement element, String text, Size design) {
    if (element.box.height <= 0) return element.box;
    final double width = element.box.width > 0
        ? element.box.width
        : math.max(1, design.width - element.box.x);
    return element.box.copyWith(
      height: math.max(1, _measureTextHeight(element, text, width)),
    );
  }

  /// ارتفاع النص بوحدات التصميم عند عرض [maxWidth].
  double _measureTextHeight(
    TextElement element,
    String text,
    double maxWidth,
  ) {
    final List<StyledTextSpan> spans = _liveSpans(element, text);
    final TextPainter painter = TextPainter(
      text: spans.isEmpty
          ? TextSpan(text: text, style: editorTextStyle(element, 1))
          : editorTextSpan(text, element, spans, 1),
      textDirection:
          editorTextIsRtl(element, text) ? TextDirection.rtl : TextDirection.ltr,
      textAlign: editorTextAlign(element.align),
      maxLines: element.maxLines,
    )..layout(maxWidth: maxWidth > 0 ? maxWidth : double.infinity);
    final double height = painter.height;
    painter.dispose();
    return height;
  }

  /// طبقة الكتابة: حقل بلا إطار وبلا حدود في موضع العنصر تماماً.
  Widget _editingLayer(
    TextElement element,
    TemplateEditorController controller,
    Size design,
    double scale,
  ) {
    final TextEditingController field = _editController!;
    final FocusNode focus = _editFocus!;
    final String current = field.text;
    final ElementBox box = _autoFitBox(element, current, design);
    final Rect rect = Rect.fromLTWH(
      box.x * scale,
      box.y * scale,
      box.width * scale,
      box.height * scale,
    );
    final bool rtl = editorTextIsRtl(element, current);
    final TextDirection direction = rtl ? TextDirection.rtl : TextDirection.ltr;
    final TextAlign align = editorTextAlign(element.align);
    final TextStyle base = editorTextStyle(element, scale);
    final List<StyledTextSpan> spans = _liveSpans(element, current);
    // معاينة الخط الحية: عائلة مؤقتة من قوائم الخطوط تُفرض على النمط الأساسي
    // (نطاقات الخط في المقطع المظلل تبقى أسبق منها — المعاينة لا تلغي تدخّلاً
    // صريحاً).
    final String? previewFamily = controller.fontPreviewUiFamily;
    final TextStyle previewBase = previewFamily == null
        ? base
        : base.copyWith(
            fontFamily: previewFamily,
            fontWeight: FontWeight.w400,
          );

    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: Transform.rotate(
        angle: element.rotation * math.pi / 180,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: <Widget>[
            // طبقة التنسيق الجزئي أسفل الحقل: الحقل شفّاف فتظهر طبقته عبره،
            // وبقائها تحت يعني أن مؤشر الكتابة يُرسم فوق النص فلا يختفي.
            if (spans.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: Text.rich(
                    editorTextSpan(current, element, spans, scale,
                        familyOverride: previewFamily),
                    textDirection: direction,
                    textAlign: align,
                    maxLines: element.maxLines,
                    overflow: TextOverflow.clip,
                  ),
                ),
              ),
            // تظليل التحديد **شبه شفّاف (35%)** كي تبقى الحروف المظللة مرئية
            // تماماً خلف التظليل أثناء التحديد والتنسيق.
            Theme(
              data: Theme.of(context).copyWith(
                textSelectionTheme: const TextSelectionThemeData(
                  selectionColor: Color(0x592196F3), // أزرق 35%
                  selectionHandleColor: Color(0xFF1565C0),
                ),
              ),
              child: TextField(
                key: const ValueKey<String>('canvas-inline-text'),
                controller: field,
                focusNode: focus,
                // نص الحقل شفّاف: ما يُرى هو طبقة [Text.rich] أو نمط [base]
                // في الحقل نفسه عندما لا يوجد تنسيق جزئي.
                style: spans.isEmpty
                    ? previewBase
                    : previewBase.copyWith(color: const Color(0x00000000)),
                cursorColor:
                    colorFromHex(element.colorHex, fallback: Colors.black),
                cursorWidth: 1.6,
                textDirection: direction,
                textAlign: align,
                textAlignVertical: TextAlignVertical.top,
                maxLines: element.maxLines,
                minLines: 1,
                expands: false,
                decoration: InputDecoration.collapsed(hintText: ''),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// مستطيل التحديد الحالي بإحداثيات اللوحة (بكسل) — فوقه يظهر الشريط العائم.
  Rect? _selectionScreenRect(TextElement element, Size design, double scale) {
    final TextEditingController? field = _editController;
    if (field == null || !_hasEditSelection) return null;
    final String current = field.text;
    final TextSelection selection = field.selection;
    final int start = math.min(selection.start, selection.end);
    final int end = math.max(selection.start, selection.end);

    final ElementBox box = _autoFitBox(element, current, design);
    final double width = box.width > 0
        ? box.width
        : math.max(1, design.width - box.x);
    final List<StyledTextSpan> spans = _liveSpans(element, current);
    final TextPainter painter = TextPainter(
      text: spans.isEmpty
          ? TextSpan(text: current, style: editorTextStyle(element, 1))
          : editorTextSpan(current, element, spans, 1),
      textDirection:
          editorTextIsRtl(element, current) ? TextDirection.rtl : TextDirection.ltr,
      textAlign: editorTextAlign(element.align),
      maxLines: element.maxLines,
    )..layout(maxWidth: width);
    final List<TextBox> boxes = painter.getBoxesForSelection(
      TextSelection(baseOffset: start, extentOffset: end),
    );
    painter.dispose();
    if (boxes.isEmpty) return null;
    Rect union = boxes.first.toRect();
    for (final TextBox rect in boxes.skip(1)) {
      union = union.expandToInclude(rect.toRect());
    }
    return Rect.fromLTWH(
      (box.x + union.left) * scale,
      (box.y + union.top) * scale,
      union.width * scale,
      union.height * scale,
    );
  }

  /// التنسيق الأساسي الفعلي للعنصر — أرضية تُحسب عليه أنواع المقاطع.
  ResolvedSpanStyle _baseResolved(TextElement element) => ResolvedSpanStyle(
        family: element.family,
        customFont: element.customFont,
        weight: element.weight,
        size: element.fontSize,
        colorHex: element.colorHex,
      );

  /// يطبّق تنسيقاً على **المقطع المظلل وحده**.
  ///
  /// المنطق قابل للعكس: ما يتحقّق قيمته على المقاطع كلها يُزال منها، وما لا
  /// يتحقّق يُعطى قيمة صريحة — فزرّ «عريض» يبدّل حرفياً لا يبقى عالقاً.
  void _applySpanStyle(
    TemplateEditorController controller, {
    PdfFontFamily? family,
    String? customFont,
    PdfFontWeight? weight,
    bool? italic,
    bool? underline,
    double? size,
    String? colorHex,
  }) {
    final TextEditingController? field = _editController;
    if (field == null) return;
    _flushLiveText(controller);

    final TemplateElement? fresh =
        _editingId == null ? null : _elementById(controller, _editingId!);
    if (fresh is! TextElement) return;

    final TextSelection selection = field.selection;
    if (!selection.isValid || selection.isCollapsed) return;
    final int start = math.min(selection.start, selection.end);
    final int end = math.max(selection.start, selection.end);
    if (start < 0 || end > fresh.text.length || end <= start) return;

    final bool setFamily = family != null || customFont != null;
    final bool setWeight = weight != null;
    final bool setItalic = italic != null;
    final bool setUnderline = underline != null;
    final bool setSize = size != null;
    final bool setColor = colorHex != null;

    final List<StyledTextSpan> next = <StyledTextSpan>[];
    for (final StyledTextSpan span
        in StyledTextSpan.normalize(fresh.spans, fresh.text.length)) {
      if (span.end <= start || span.start >= end) {
        next.add(span);
        continue;
      }
      if (span.start < start) {
        final StyledTextSpan? left = _sliceSpan(span, span.start, start);
        if (left != null) next.add(left);
      }
      final int midStart = math.max(span.start, start);
      final int midEnd = math.min(span.end, end);
      final StyledTextSpan? mid = _sliceSpan(
        span,
        midStart,
        midEnd,
        dropFamily: setFamily,
        dropWeight: setWeight,
        dropItalic: setItalic,
        dropUnderline: setUnderline,
        dropSize: setSize,
        dropColor: setColor,
      );
      if (mid != null) next.add(mid);
      if (span.end > end) {
        final StyledTextSpan? right = _sliceSpan(span, end, span.end);
        if (right != null) next.add(right);
      }
    }

    final StyledTextSpan applied = StyledTextSpan(
      start: start,
      end: end,
      family: family,
      customFont: customFont,
      weight: weight,
      italic: italic,
      underline: underline,
      size: size,
      colorHex: colorHex,
    );
    if (!applied.isBase) next.add(applied);

    _openEditHistory(controller);
    controller.replaceElement(fresh.copyWith(
      spans: StyledTextSpan.normalize(next, fresh.text.length),
    ));
    if (mounted) setState(() {});
  }

  /// قصّ جزء من نطاق مع إمكانية إفراغ حقوله التي ستُعطى من جديد.
  static StyledTextSpan? _sliceSpan(
    StyledTextSpan span,
    int start,
    int end, {
    bool dropFamily = false,
    bool dropWeight = false,
    bool dropItalic = false,
    bool dropUnderline = false,
    bool dropSize = false,
    bool dropColor = false,
  }) {
    if (end <= start) return null;
    final StyledTextSpan out = StyledTextSpan(
      start: start,
      end: end,
      family: dropFamily ? null : span.family,
      customFont: dropFamily ? null : span.customFont,
      weight: dropWeight ? null : span.weight,
      italic: dropItalic ? null : span.italic,
      underline: dropUnderline ? null : span.underline,
      size: dropSize ? null : span.size,
      colorHex: dropColor ? null : span.colorHex,
      backgroundHex: span.backgroundHex,
    );
    return out.isBase ? null : out;
  }

  // ==========================================================================
  //                 الشريط العائم فوق المقطع المظلل
  // ==========================================================================

  /// الشريط العائم: اختيار الخط والحجم واللون والمحاذاة + عريض/مائل/سفلي.
  ///
  /// يظهر فور تظليل أي مقطع ويوضع فوقه مباشرة (وينقلب أسفله إن لم يتسع ما
  /// فوقه، تماماً كما في Word)، وكل ما فيه يُطبَّق على المقطع المظلل وحده.
  Widget _floatingTextToolbar(TextElement element, Size design, double scale) {
    final TextEditingController? field = _editController;
    if (field == null) return const SizedBox.shrink();

    final Rect anchor = _selectionScreenRect(element, design, scale) ??
        _screenRect(element, design, scale);
    const double barHeight = 38;
    const double gap = 6;
    double top = anchor.top - barHeight - gap;
    if (top < 2) top = anchor.bottom + gap;

    const double estimatedWidth = 300;
    final double paperWidth = design.width * scale;
    final double left = (anchor.center.dx - estimatedWidth / 2)
        .clamp(4.0, math.max(4.0, paperWidth - estimatedWidth - 4.0));

    final TextSelection selection = field.selection;
    final int start = math.min(selection.start, selection.end);
    final int end = math.max(selection.start, selection.end);

    final TemplateEditorController controller = widget.controller;
    return Positioned(
      left: left,
      top: top,
      child: _TextSpanToolbar(
        key: const ValueKey<String>('canvas-text-toolbar'),
        style: _effectiveSelectionStyle(element, start, end),
        element: element,
        onFont: (PdfFontFamily value) =>
            _applySpanStyle(controller, family: value),
        onCustomFont: (String value) =>
            _applySpanStyle(controller, customFont: value),
        // المعاينة الحيّة للخط: عائلة مؤقتة تُعرض فور المرور فوق الخيار.
        onPreviewFont: (String? uiFamily) =>
            controller.setFontPreview(uiFamily),
        onSize: (double value) => _applySpanStyle(controller, size: value),
        onColor: (String value) =>
            _applySpanStyle(controller, colorHex: value),
        onAlign: (ElementTextAlign value) => _applyAlign(controller, value),
        onWeight: (PdfFontWeight value) =>
            _applySpanStyle(controller, weight: value),
        onItalic: (bool value) => _applySpanStyle(controller, italic: value),
        onUnderline: (bool value) =>
            _applySpanStyle(controller, underline: value),
      ),
    );
  }

  /// التنسيق الفعلي للمقطع المظلل (بالدمج مع أساس العنصر) — به تُميَّز القيم
  /// الحالية في الشريط (أيّ خط؟ أيّ حجم؟ هل هو عريض أصلاً؟).
  ResolvedSpanStyle _effectiveSelectionStyle(
    TextElement element,
    int start,
    int end,
  ) {
    for (final StyledTextRun run in splitStyledRuns(
      element.text,
      element.spans,
      base: _baseResolved(element),
    )) {
      if (run.end <= start || run.start >= end) continue;
      return run.style;
    }
    return _baseResolved(element);
  }

  /// المحاذاة خاصية **الفقرة** كلها لا المقطع وحده (كما في Word): تعديلها
  /// يُسجَّل كخطوة واحدة مع بقية التحرير.
  void _applyAlign(TemplateEditorController controller, ElementTextAlign align) {
    _flushLiveText(controller);
    final TemplateElement? current =
        _editingId == null ? null : _elementById(controller, _editingId!);
    if (current is! TextElement || current.align == align) return;
    _openEditHistory(controller);
    controller.replaceElement(current.copyWith(align: align));
    if (mounted) setState(() {});
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
    // إنشاء نصّ جديد وهو ما زال تحرير سابق مفتوحاً ⇒ نُلتزمه أولاً.
    _commitIfEditingOther(null);
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

/// الشريط العائم الصغير فوق المقطع المظلل داخل الكانفاس.
///
/// يعرض **القيم الفعلية** للتحديد الحالي (أيّ خط؟ أيّ حجم؟ هل هو عريض؟) ويعيد
/// كل تغيير عبر النداءات الممرَّرة — فلا يعرف شيئاً عن المستند ولا عن الحقل،
/// فيبقى قابلاً للاختبار وحده.
class _TextSpanToolbar extends StatelessWidget {
  const _TextSpanToolbar({
    super.key,
    required this.style,
    required this.element,
    required this.onFont,
    required this.onCustomFont,
    required this.onPreviewFont,
    required this.onSize,
    required this.onColor,
    required this.onAlign,
    required this.onWeight,
    required this.onItalic,
    required this.onUnderline,
  });

  /// التنسيق الفعلي للمقطع المظلل (أساس العنصر مدموجاً بما فوقه).
  final ResolvedSpanStyle style;
  final TextElement element;

  final ValueChanged<PdfFontFamily> onFont;

  /// اختير خط مرفوع/نظامي باسم عائلته.
  final ValueChanged<String> onCustomFont;

  /// مرّ المؤشر فوق خيار خط (أو خرج): معاينة حيّة بلا تثبيت.
  final ValueChanged<String?> onPreviewFont;
  final ValueChanged<double> onSize;
  final ValueChanged<String> onColor;
  final ValueChanged<ElementTextAlign> onAlign;
  final ValueChanged<PdfFontWeight> onWeight;
  final ValueChanged<bool> onItalic;
  final ValueChanged<bool> onUnderline;

  /// قيمة بعيدة عن أي لون ‎`#RRGGBB`‎ تفتح المنتقي الشامل عند اختيارها.
  static const String _customColorValue = '#__full_picker__#';

  /// بادئة خيارات الخطوط المرفوعة/النظامية في القائمة المختلطة.
  static const String _customIdPrefix = 'custom-font:';

  /// مقاسات الخط المنشورة في القائمة.
  static const List<double> sizes = <double>[
    8, 9, 10, 11, 12, 14, 16, 18, 20, 24, 28, 32, 40, 48, 56, 64, 72,
  ];

  /// لوحة الألوان المنشورة — نفس ألوان الشريط الجانبي حتى لا يتشتّت المستخدم.
  static const List<String> palette = <String>[
    '#000000', '#FFFFFF', '#E53935', '#FB8C00', '#FDD835', '#43A047',
    '#00ACC1', '#1E88E5', '#3949AB', '#8E24AA', '#D81B60', '#6D4C41',
    '#757575', '#1B2539',
  ];

  static const Map<ElementTextAlign, IconData> _alignIcons =
      <ElementTextAlign, IconData>{
    ElementTextAlign.start: Icons.format_align_left_rounded,
    ElementTextAlign.center: Icons.format_align_center_rounded,
    ElementTextAlign.end: Icons.format_align_right_rounded,
    ElementTextAlign.justify: Icons.format_align_justify_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    // الخط الفعلي للمقطع المظلل (نطاقه الصريح أو أساس العنصر).
    final PdfFontFamily family = style.family ?? element.family;
    final double fontSize = style.size ?? element.fontSize;

    return Material(
      color: scheme.surface,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space4,
          vertical: AppTheme.space2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // اختيار الخط — المضمّن والمرفوع وخطوط النظام، مع معاينة حيّة
            // فورية عند المرور فوق أي خيار.
            ListenableBuilder(
              listenable: CustomFontController.instance,
              builder: (BuildContext context, Widget? _) {
                final CustomFontController fonts = CustomFontController.instance;
                return PopupMenuButton<String>(
                  tooltip: 'نوع الخط',
                  padding: EdgeInsets.zero,
                  onOpened: () => fonts.scanSystemFonts(),
                  onSelected: (String value) {
                    onPreviewFont(null);
                    if (value.startsWith(_customIdPrefix)) {
                      onCustomFont(value.substring(_customIdPrefix.length));
                    } else {
                      onFont(PdfFontFamily.fromJson(value));
                    }
                  },
                  onCanceled: () => onPreviewFont(null),
                  iconSize: 18,
                  icon: const Icon(Icons.font_download_outlined, size: 18),
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    for (final PdfFontFamily option in PdfFontFamily.values)
                      _fontItem(
                        context,
                        value: option.jsonValue,
                        label: option.labelAr,
                        previewFamily: option.uiFamily,
                        selected: style.customFont == null &&
                            family == option,
                      ),
                    if (fonts.families.isNotEmpty) ...<PopupMenuEntry<String>>[
                      const PopupMenuDivider(),
                      for (final String name in fonts.families)
                        _fontItem(
                          context,
                          value: '$_customIdPrefix$name',
                          label: fonts.displayNameOf(name),
                          previewFamily: name,
                          selected: style.customFont == name ||
                              element.customFont == name,
                        ),
                    ],
                    if (fonts.hasSystemFonts) ...<PopupMenuEntry<String>>[
                      const PopupMenuDivider(),
                      for (final String name in fonts.systemFamilies
                          .where((String n) => !fonts.families.contains(n)))
                        _fontItem(
                          context,
                          value: '$_customIdPrefix$name',
                          label: name,
                          previewFamily: name,
                          selected: style.customFont == name ||
                              element.customFont == name,
                        ),
                    ],
                  ],
                );
              },
            ),
            _divider(),
            // حجم الخط.
            PopupMenuButton<double>(
              tooltip: 'حجم الخط',
              padding: EdgeInsets.zero,
              onSelected: onSize,
              iconSize: 18,
              icon: Text(
                fontSize % 1 == 0
                    ? '${fontSize.toInt()}'
                    : fontSize.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<double>>[
                for (final double option in sizes)
                  PopupMenuItem<double>(
                    value: option,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if ((option - fontSize).abs() < 0.01)
                          Icon(Icons.check_rounded,
                              size: 16, color: scheme.primary)
                        else
                          const SizedBox(width: 16),
                        const SizedBox(width: 6),
                        Text('${option.toInt()}'),
                      ],
                    ),
                  ),
              ],
            ),
            _divider(),
            // لون النص — لوحة سريعة + منتقي شامل لأي درجة HEX/RGB.
            PopupMenuButton<String>(
              tooltip: 'لون النص',
              padding: EdgeInsets.zero,
              onSelected: (String value) {
                if (value == _customColorValue) {
                  _openFullPicker(context);
                  return;
                }
                onColor(value);
              },
              iconSize: 18,
              icon: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: colorFromHex(
                    style.colorHex ?? element.colorHex,
                    fallback: Colors.black,
                  ),
                  border: Border.all(color: scheme.outline, width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                for (final String hex in palette)
                  PopupMenuItem<String>(
                    value: hex,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: colorFromHex(hex, fallback: Colors.black),
                            border: Border.all(color: scheme.outline, width: 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(hex.toUpperCase()),
                      ],
                    ),
                  ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: _customColorValue,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.colorize_rounded,
                  size: 16, color: scheme.primary),
              const SizedBox(width: 8),
              // مرن ليبقى داخل عرض القائمة حتى بأحرف عريضة (خطوط الاختبار).
              const Flexible(
                child: Text(
                  'منتقي الألوان الشامل…',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
              ],
            ),
            _divider(),
            _toggle(
              context,
              icon: Icons.format_bold_rounded,
              tooltip: 'عريض',
              active: style.weight == PdfFontWeight.bold,
              onTap: () => onWeight(
                style.weight == PdfFontWeight.bold
                    ? PdfFontWeight.regular
                    : PdfFontWeight.bold,
              ),
            ),
            _toggle(
              context,
              icon: Icons.format_italic_rounded,
              tooltip: 'مائل',
              active: style.italic,
              onTap: () => onItalic(!style.italic),
            ),
            _toggle(
              context,
              icon: Icons.format_underlined_rounded,
              tooltip: 'خط سفلي',
              active: style.underline,
              onTap: () => onUnderline(!style.underline),
            ),
            _divider(),
            // المحاذاة — خاصية الفقرة كلها (كما في Word).
            PopupMenuButton<ElementTextAlign>(
              tooltip: 'المحاذاة',
              padding: EdgeInsets.zero,
              onSelected: onAlign,
              iconSize: 18,
              icon: Icon(
                _alignIcons[element.align] ?? Icons.format_align_left_rounded,
                size: 18,
              ),
              itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<ElementTextAlign>>[
                for (final ElementTextAlign option in ElementTextAlign.values)
                  PopupMenuItem<ElementTextAlign>(
                    value: option,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (option == element.align)
                          Icon(Icons.check_rounded,
                              size: 16, color: scheme.primary)
                        else
                          const SizedBox(width: 16),
                        const SizedBox(width: 6),
                        Icon(_alignIcons[option], size: 16),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 20,
        margin: const EdgeInsets.symmetric(horizontal: AppTheme.space2),
        color: const Color(0x1A000000),
      );

  Widget _toggle(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required bool active,
    required VoidCallback onTap,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.space4),
          decoration: BoxDecoration(
            color: active ? scheme.primary.withValues(alpha: 0.16) : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(
            icon,
            size: 18,
            color: active ? scheme.primary : scheme.onSurface,
          ),
        ),
      ),
    );
  }

  /// خيار خط واحد في القائمة: يُرسم بخطه نفسه، ويرسل معاينة حيّة عند المرور
  /// فوقه فتتغيّر صيغة النص المظلل فوراً قبل الضغط أو الإغلاق.
  PopupMenuItem<String> _fontItem(
    BuildContext context, {
    required String value,
    required String label,
    required String previewFamily,
    required bool selected,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: MouseRegion(
        onEnter: (_) => onPreviewFont(previewFamily),
        onExit: (_) => onPreviewFont(null),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (selected)
              Icon(Icons.check_rounded, size: 16, color: Theme.of(context).colorScheme.primary)
            else
              const SizedBox(width: 16),
            const SizedBox(width: 6),
            // مرن مع قصّ: أسماء خطوط النظام قد تفوق عرض القائمة (256px).
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: previewFamily),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// يفتح المنتقي الشامل (HEX/RGB) ويُرجع اختياره عبر [onColor].
  Future<void> _openFullPicker(BuildContext context) async {
    final String initial = style.colorHex ?? element.colorHex;
    final String? picked = await showEditorColorPicker(
      context,
      initialHex: initial,
    );
    if (picked != null) onColor(picked);
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
  }  @override
  bool shouldRepaint(BorderPainter oldDelegate) => oldDelegate.color != color || oldDelegate.width != width;
}

// ==========================================================================
//  بوابة اختبار الإصابة
// ==========================================================================

/// بوابة اختبار الإصابة لطبقة عنصر واحد.
///
/// لا تمسّ الرسم إطلاقاً؛ تسمح أو تمنع باستقبال النقر فقط، اعتماداً على
/// [shouldHit] (نفس نتيجة [pickElementAt] للنقطة). إن رُفضت الطبقة مرّ النقر
/// إلى ما تحتها في الـ Stack، فيُنتقي دائماً **الأصغر/الأعلى** تحت المؤشر بدل
/// الأعلى طبقة وحده — وبذلك لا تسرق الحاويات الكبيرة (بخاصة المفرغة) نقرات
/// العناصر الصغيرة داخلها.
class _ElementHitGate extends SingleChildRenderObjectWidget {
  const _ElementHitGate({
    required this.origin,
    required this.shouldHit,
    required Widget child,
  }) : super(child: child);

  /// موضع الطبقة داخل اللوحة (بكسلات الورقة) لتحويل النقطة المحلية إليها.
  final Offset origin;

  /// هل تستقبل هذه الطبقة النقرة عند هذه النقطة؟
  final bool Function(Offset paperPoint) shouldHit;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderElementHitGate(origin: origin, shouldHit: shouldHit);

  @override
  void updateRenderObject(BuildContext context, _RenderElementHitGate render) {
    render.origin = origin;
    render.shouldHit = shouldHit;
  }
}

/// الكاشف الفعلي: يرفض النقطة قبل أن تصل إلى كاشف النقر أسفله.
class _RenderElementHitGate extends RenderProxyBox {
  _RenderElementHitGate({
    required Offset origin,
    required bool Function(Offset) shouldHit,
    RenderBox? child,
  })  : _origin = origin,
        _shouldHit = shouldHit,
        super(child);

  Offset _origin;
  bool Function(Offset) _shouldHit;

  set origin(Offset value) => _origin = value;
  set shouldHit(bool Function(Offset) value) => _shouldHit = value;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // النقطة هنا بعوامض الطبقة؛ تُضاف الإزاحة للحصول على موضعها في اللوحة.
    if (!_shouldHit(position + _origin)) return false;
    return super.hitTest(result, position: position);
  }
}
