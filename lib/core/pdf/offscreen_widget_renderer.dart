import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../assets/asset_image_cache.dart';
import '../assets/assets_controller.dart';
import '../assets/embedded_assets.dart';
import '../assets/user_asset.dart';
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
      // (١) تهيئة الصور قبل بناء الشجرة: تُفكّ وتُرَستر كل صورة الآن فتدخل
      // `imageCache` قبل أول بناء، فتُرسم من الصفحة الأولى — وهي باردة دائماً
      // عند أول تصدير — بدل أن تصل الصورة بعد التقاط اللقطة فيخرج
      // الشعار/التوقيع غائباً.
      await _prewarmImages(document);

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
    // (٢) `onBuildScheduled` يُبلّغنا أن عنصراً اكتسب صورة متأخرة وطلب إعادة
    // بناء؛ بدونه يبقى العنصر متسخاً إلى الأبد ولا يُعاد رسمه — وهو السبب
    // الجذري لغياب الصور من «الشهادة الأولى».
    bool rebuildScheduled = false;
    final BuildOwner buildOwner = BuildOwner(
      focusManager: FocusManager(),
      onBuildScheduled: () => rebuildScheduled = true,
    );

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

    void rebuildAndFlush() {
      buildOwner.buildScope(rootElement);
      buildOwner.finalizeTree();
      pipelineOwner.flushLayout();
      pipelineOwner.flushCompositingBits();
      pipelineOwner.flushPaint();
    }

    // (٣) البناء الأول ثم حلقة سكون بديلة عن انتظار الـ100ms الأعمى: أي صورة
    // (أو مكوّن آخر) تصل بعد البناء تستدعي `onBuildScheduled`، فنُعيد البناء
    // والطلاء فوراً — حتى هدوءٍ تام متتالٍ وبحدٍّ أقصى يمنع التعليق.
    rebuildAndFlush();

    const int maxSettleRounds = 125; // ≈ ثانيتان كحدٍّ أقصى
    const Duration settleStep = Duration(milliseconds: 16);
    int quietRounds = 0;
    for (int round = 0; round < maxSettleRounds && quietRounds < 2; round++) {
      await Future<void>.delayed(settleStep);
      if (!rebuildScheduled) {
        quietRounds += 1;
        continue;
      }
      rebuildScheduled = false;
      quietRounds = 0;
      rebuildAndFlush();
    }

    debugPrint('📸 [OffscreenWidgetRenderer] Taking snapshot with toImage...');
    if (repaintBoundary.size.width <= 0 || repaintBoundary.size.height <= 0) {
      throw StateError('Invalid surface size: RenderRepaintBoundary is empty (${repaintBoundary.size}). Constraints likely failed.');
    }
    
    final ui.Image image = await repaintBoundary.toImage(pixelRatio: pixelRatio);
    debugPrint('📸 [OffscreenWidgetRenderer] snapshot complete.');
    // Keep reference alive momentarily just in case
    return image;
  }

  /// تهيئة صور المستند قبل بناء الشجرة: تُحلّ كل صورة الآن في
  /// `PaintingBinding.imageCache` فتُرسم من أول بناء.
  ///
  /// تُطابق قواعد [ElementView] حرفياً (نفس المصدر ونفس الموفّر بنفس المفتاح)
  /// لكل من [ImageElement] وخانات [SignatureElement] — فلا يخرج التصدير بشعار
  /// غائب في «الصفحة الأولى»، وهي الباردة دائماً عند أول تصدير.
  static Future<void> _prewarmImages(TemplateDocument document) async {
    final List<ImageProvider> providers = _documentImageProviders(document);
    if (providers.isEmpty) return;
    try {
      await Future.wait(providers.map(_resolveFirstFrame))
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      // صورة تأخّرت سراً: لا نوقف التصدير — حلقة السكون تلتقطها إن جاءت.
      debugPrint(
        '⚠️ [OffscreenWidgetRenderer] Images did not pre-warm within 10s; '
        'continuing with the settle loop.',
      );
    } on Object catch (error) {
      // أي فشل غير متوقّع في التسخين لا يُسقط التصدير لوجود حلقة السكون.
      debugPrint('⚠️ [OffscreenWidgetRenderer] Image pre-warm failed: $error');
    }
  }

  /// موفّرات صور المستند — نسخة طبق الأصل من منطق عرض [ElementView].
  ///
  /// تُجمع كل صورة يمكن أن يبنيها العارض: صور [ImageElement] (أصل حيّ ←
  /// Base64 مضمّن ← بيانات مضمّنة ← أصل ملفي) وصور خانات [SignatureElement].
  static List<ImageProvider> _documentImageProviders(
    TemplateDocument document,
  ) {
    final List<ImageProvider> providers = <ImageProvider>[];

    void add(String path, ImageSourceKind kind, String? Function() inline) {
      if (path.trim().isEmpty) return;
      try {
        switch (kind) {
          case ImageSourceKind.userAsset:
            final UserAsset? asset = AssetsController.instance.byId(path);
            if (asset != null) {
              providers.add(AssetImageCache.instance.providerForAsset(asset));
            } else {
              final String? data = inline();
              if (data != null && data.trim().isNotEmpty) {
                providers.add(
                  AssetImageCache.instance.providerForBase64(data),
                );
              }
            }
          case ImageSourceKind.dataUri:
            providers.add(AssetImageCache.instance.providerForBase64(path));
          case ImageSourceKind.asset:
            providers.add(AssetImage(path));
          case ImageSourceKind.file:
            break; // الملف المحلي يُعرض بطاقة تنبيه لا صورة.
        }
      } on Object catch (_) {
        // بيانات تالفة: [ElementView] يعرض بطاقة تنبيه بدل الصورة — لا يجوز
        // أن يُسقط التصدير، ولا نتسخّن موفّراً غير صالح.
      }
    }

    for (final TemplateElement element in document.elements) {
      if (element is ImageElement) {
        add(
          element.path,
          element.sourceKind,
          () => inlineImageBase64(element, document),
        );
      } else if (element is SignatureElement) {
        for (final SignatureSlot slot in element.slots) {
          if (!slot.hasImage) continue;
          add(
            slot.imagePath,
            slot.imageSource,
            () => inlineSlotBase64(slot, document),
          );
        }
      }
    }
    return providers;
  }

  /// ينتظر أول إطار لصورة — أو فشلها — دون أن يُسقط التصدير.
  ///
  /// الصورة تبقى في `imageCache` بعد انتهاء الانتظار، فيجد [Element] الصورة
  /// محلولة أثناء أول بناء وتُرسم متزامنة بدل أن تصل متأخرة بعد اللقطة.
  static Future<void> _resolveFirstFrame(ImageProvider provider) {
    final Completer<void> completer = Completer<void>();
    final ImageStream stream = provider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    void settle() {
      stream.removeListener(listener);
      if (!completer.isCompleted) completer.complete();
    }

    listener = ImageStreamListener(
      (ImageInfo image, bool synchronousCall) => settle(),
      onError: (Object error, StackTrace? stackTrace) => settle(),
    );
    stream.addListener(listener);
    return completer.future;
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
