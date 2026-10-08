import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../editor/widgets/element_view.dart';
import '../gender/arabic_gender.dart';
import '../models/template_document.dart';
import '../models/template_element.dart';
import '../utils/hex_color.dart';

/// Renders a Flutter Widget tree entirely off-screen to a [ui.Image] or [Uint8List].
/// Used to generate High-Fidelity Rasterized PDFs where 100% exact visual parity is needed.
class OffscreenWidgetRenderer {
  /// Takes a [TemplateDocument] and renders it precisely as it appears on canvas.
  static Future<Uint8List> renderDocumentToImageBytes(
    TemplateDocument document, {
    Map<String, String>? rowData,
    Gender? gender,
    double? pixelRatio,
  }) async {
    // Clamp the pixel ratio to prevent memory overflow on large templates.
    final double rawDpiRatio = document.dpi / 72.0;
    final double targetPixelRatio = pixelRatio ?? rawDpiRatio;
    
    double safePixelRatio = targetPixelRatio;
    // Use designWidth/designHeight (96dpi canvas) — same as the editor
    final double canvasW = document.designWidth;
    final double canvasH = document.designHeight;
    final double maxDimension = math.max(canvasW, canvasH);
    if (maxDimension * safePixelRatio > 4096) {
      safePixelRatio = 4096 / maxDimension;
    }
    // Ensure safePixelRatio stays ≥ 2.0 for print quality
    safePixelRatio = safePixelRatio.clamp(2.0, 3.5);
    
    debugPrint('📸 [OffscreenWidgetRenderer] Canvas: ${canvasW}x$canvasH, PixelRatio: $safePixelRatio');

    try {
      final ui.Image image = await _renderWidgetToImage(
        _DocumentPreview(
          document: document,
          rowData: rowData,
          gender: gender,
        ),
        Size(canvasW, canvasH),
        pixelRatio: safePixelRatio,
      );

      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('Failed to encode off-screen image to PNG.');
      }
      debugPrint('📸 [OffscreenWidgetRenderer] Successfully captured and encoded PNG: ${byteData.lengthInBytes} bytes');
      return byteData.buffer.asUint8List();
    } catch (e, stackTrace) {
      debugPrint('❌ PDF Export Error [OffscreenWidgetRenderer]: $e');
      debugPrint('📍 StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Low-level function that pumps a widget into a headless flutter render tree.
  static Future<ui.Image> _renderWidgetToImage(
    Widget widget,
    Size size, {
    required double pixelRatio,
  }) async {
    final RenderRepaintBoundary repaintBoundary = RenderRepaintBoundary();
    final PipelineOwner pipelineOwner = PipelineOwner();
    final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager());

    // Connect to the first available flutter view to trick the engine.
    final ui.FlutterView view = ui.PlatformDispatcher.instance.views.first;

    final BoxConstraints logicalBox = BoxConstraints.tight(size);
    // devicePixelRatio = 1.0 → logical == physical. The actual hi-res
    // upscaling is handled exclusively by toImage(pixelRatio: ...).
    final BoxConstraints physicalBox = logicalBox;

    final RenderView renderView = RenderView(
      view: view,
      child: RenderConstrainedBox(
        additionalConstraints: BoxConstraints.tight(size),
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration(
        logicalConstraints: logicalBox,
        physicalConstraints: physicalBox,
        devicePixelRatio: 1.0,
      ),
    );

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final RenderObjectToWidgetElement<RenderBox> rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: MediaQuery(
        data: MediaQueryData(
          size: size,
          devicePixelRatio: 1.0,
        ),
        child: Theme(
          data: ThemeData.light(),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: widget,
            ),
          ),
        ),
      ),
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    // Extra wait for frame rendering
    await Future<void>.delayed(const Duration(milliseconds: 100));

    debugPrint('📸 [OffscreenWidgetRenderer] Waiting for microtasks & frame to settle...');

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    debugPrint('📸 [OffscreenWidgetRenderer] Taking snapshot with toImage...');
    if (repaintBoundary.size.width <= 0 || repaintBoundary.size.height <= 0) {
      throw StateError('Invalid surface size: RenderRepaintBoundary is empty (${repaintBoundary.size}). Constraints likely failed.');
    }
    
    final ui.Image image = await repaintBoundary.toImage(pixelRatio: pixelRatio);
    debugPrint('📸 [OffscreenWidgetRenderer] snapshot complete.');
    // Keep reference alive momentarily just in case
    return image;
  }
}

/// A read-only widget that perfectly matches the physical layout of [TemplateDocument].
class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({
    required this.document,
    this.rowData,
    this.gender,
  });

  final TemplateDocument document;
  final Map<String, String>? rowData;
  final Gender? gender;

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

  double _autoHeight(TemplateElement element, double width) {
    if (element is! TextElement) return width > 0 ? width : 24;
    final String resolved = document.resolveFields(
      element.text,
      rowData,
      keepUnknownTokens: true,
      gender: gender,
    );
    final bool rtl = editorTextIsRtl(element, resolved);
    final TextPainter painter = TextPainter(
      text: TextSpan(text: resolved, style: editorTextStyle(element, 1.0)),
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
    )..layout(maxWidth: width > 0 ? width : double.infinity);
    return painter.height;
  }

  @override
  Widget build(BuildContext context) {
    BoxDecoration? paperDecoration;
    final String bgHex = document.backgroundHex;
    final BackgroundGradient? bgGradient = document.backgroundGradient;

    if (bgGradient != null) {
      final (Alignment begin, Alignment end) = switch (bgGradient.direction) {
        GradientDirection.vertical => (Alignment.topCenter, Alignment.bottomCenter),
        GradientDirection.horizontal => (Alignment.centerLeft, Alignment.centerRight),
        GradientDirection.diagonal => (Alignment.topLeft, Alignment.bottomRight),
      };
      paperDecoration = BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: <Color>[
            colorFromHex(bgGradient.startHex, fallback: Colors.white),
            colorFromHex(bgGradient.endHex, fallback: Colors.white),
          ],
        ),
      );
    } else if (bgHex.isNotEmpty) {
      paperDecoration = BoxDecoration(
        color: colorFromHex(bgHex, fallback: Colors.white),
      );
    } else {
      paperDecoration = const BoxDecoration(color: Colors.white);
    }

    final Size designSize = Size(document.designWidth, document.designHeight);

    return Container(
      width: designSize.width,
      height: designSize.height,
      decoration: paperDecoration,
      child: Stack(
        clipBehavior: Clip.none,
        children: document.elements.map((TemplateElement el) {
          final ElementBox box = _designBox(el, designSize);
          return Positioned(
            left: box.x,
            top: box.y,
            width: box.width,
            height: box.height,
            child: Transform.rotate(
              angle: el.rotation * math.pi / 180,
              alignment: Alignment.center,
              child: ElementView(
                element: el,
                document: document,
                scale: 1.0,
                gender: gender,
                rowData: rowData,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
