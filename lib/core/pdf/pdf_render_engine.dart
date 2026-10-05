import 'dart:math' as math;
import 'dart:typed_data';

import 'package:barcode/barcode.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/template_document.dart';
import '../models/template_element.dart';
import '../models/text_flow.dart';
import 'arabic_text_engine.dart';
import 'pdf_color.dart';
import 'pdf_decor_painter.dart';
import 'pdf_font_catalog.dart';

/// بيانات وصفية تُكتب داخل ملف الـ PDF.
class PdfDocumentMetadata {
  const PdfDocumentMetadata({
    this.title,
    this.author,
    this.subject,
    this.keywords,
    this.creator = 'JoodCraft',
  });

  final String? title;
  final String? author;
  final String? subject;
  final String? keywords;
  final String creator;
}

/// محرّك الرسم النقيّ: `TemplateDocument` + صفوف + خطوط + صور ← بايتات PDF.
///
/// **لماذا منفصل عن `PdfGeneratorService`؟** لأن هذا الجزء **خالص** (لا يلمس
/// `rootBundle` ولا أي قناة منصة): يأخذ خطوطاً جاهزة (`PdfFontSet`) وصوراً
/// جاهزة (`pw.ImageProvider`)، فيمكن تشغيله في أي isolate — بما في ذلك isolate
/// خلفي لتفادي تجميد الواجهة أثناء التوليد الجماعي.
class PdfRenderer {
  const PdfRenderer({required this.fonts, this.compress = true});

  final PdfFontSet fonts;
  final bool compress;

  /// بناء ملف PDF كامل: صفحة لكل صف. يعيد البايتات فقط.
  Future<Uint8List> build({
    required TemplateDocument document,
    required List<Map<String, String>> rows,
    required Map<String, pw.ImageProvider?> images,
    PdfDocumentMetadata? metadata,
    void Function(int done, int total)? onProgress,
  }) async {
    final pw.Document pdf = pw.Document(
      title: metadata?.title ?? 'JoodCraft Document',
      author: metadata?.author,
      subject: metadata?.subject,
      keywords: metadata?.keywords,
      creator: metadata?.creator ?? 'JoodCraft',
      producer: 'JoodCraft',
      compress: compress,
      theme: pw.ThemeData.withFont(
        base: fonts.resolve(PdfFontSet.defaultFamily),
        bold: fonts.resolve(PdfFontSet.defaultFamily, PdfFontWeight.bold),
      ),
    );

    final PdfPageFormat format = PdfPageFormat(
      document.pageWidthPt,
      document.pageHeightPt,
      marginAll: 0,
    );

    for (int i = 0; i < rows.length; i++) {
      pdf.addPage(
        _buildPage(
          document: document,
          data: rows[i],
          images: images,
          formats: format,
        ),
      );
      onProgress?.call(i + 1, rows.length);
    }

    return pdf.save();
  }

  // ==========================================================================
  //                              الصفحة
  // ==========================================================================

  pw.Page _buildPage({
    required TemplateDocument document,
    required Map<String, String> data,
    required Map<String, pw.ImageProvider?> images,
    required PdfPageFormat formats,
  }) {
    return pw.Page(
      pageFormat: formats,
      build: (pw.Context context) {
        return pw.Container(
          width: document.pageWidthPt,
          height: document.pageHeightPt,
          color:
              pdfColorFromHex(document.backgroundHex, fallback: PdfColors.white),
          child: pw.Stack(
            children: <pw.Widget>[
              for (final TemplateElement element in document.elements)
                _buildElement(
                      context: context,
                      element: element,
                      document: document,
                      data: data,
                      images: images,
                    ) ??
                    pw.SizedBox(),
            ],
          ),
        );
      },
    );
  }

  /// تحويل عنصر واحد إلى ويدجت موضوع بإحداثياته (أو `null` إن تُجاهل).
  pw.Widget? _buildElement({
    required pw.Context context,
    required TemplateElement element,
    required TemplateDocument document,
    required Map<String, String> data,
    required Map<String, pw.ImageProvider?> images,
  }) {
    final double s = document.scale;
    // تحويل موحّد (تصميم ← نقاط طباعة) مشترك مع بقية المحرّك — بلا حسابات
    // مكرّرة تسمح بترحّل المحاذاة بين المحرر والـ PDF.
    final rect = document.boxToPdfRect(element.box);
    final double left = rect.left;
    final double top = rect.top;
    final double pageHeight = document.pageHeightPt;
    final double width = rect.width;

    switch (element) {
      case UnknownElement():
        return null;

      case final ShapeElement shape:
        return _positioned(
          left: left,
          top: top,
          width: width,
          rotation: shape.rotation,
          child: _shapeWidget(shape, document, width),
        );

      case final SealElement seal:
        // مربّع بأصغر ضلعين — نفس قاعدة المحرر (‎SealPainter‎).
        final double size = seal.squareSide() * s;
        return _positioned(
          left: left,
          top: top,
          width: size,
          rotation: seal.rotation,
          child: pw.Opacity(
            opacity: seal.opacity.clamp(0, 1),
            child: pw.CustomPaint(
              size: PdfPoint(size, size),
              painter: (PdfGraphics canvas, PdfPoint _) =>
                  _paintSeal(canvas, size, seal),
            ),
          ),
        );

      case final DecorationElement decor:
        final double decorHeight =
            decor.box.height > 0 ? decor.box.height * s : width;
        return _positioned(
          left: left,
          top: top,
          width: width,
          rotation: decor.rotation,
          child: pw.Opacity(
            opacity: decor.opacity.clamp(0, 1),
            child: pw.CustomPaint(
              size: PdfPoint(width, decorHeight),
              painter: (PdfGraphics canvas, PdfPoint _) =>
                  paintVectorDecor(canvas, decor.spec, width, decorHeight),
            ),
          ),
        );

      case final SignatureElement signature:
        final List<SignatureSlot> slots = signature.orderedSlots;
        if (slots.isEmpty) return null;
        return _positioned(
          left: left,
          top: top,
          width: width,
          rotation: signature.rotation,
          child: pw.Opacity(
            opacity: signature.opacity.clamp(0, 1),
            child: _signatureWidget(
              element: signature,
              slots: slots,
              document: document,
              data: data,
              images: images,
              width: width,
            ),
          ),
        );

      case final ImageElement image:
        final pw.ImageProvider? resolved =
            images['${image.sourceKind.jsonValue}:${image.path}'];
        if (resolved == null) return null;
        final double height =
            image.box.height > 0 ? image.box.height * s : width;
        return _positioned(
          left: left,
          top: top,
          width: width,
          rotation: image.rotation,
          child: pw.Opacity(
            opacity: image.opacity.clamp(0, 1),
            child: pw.Image(
              resolved,
              width: width,
              height: height,
              fit: switch (image.fit) {
                ImageFit.contain => pw.BoxFit.contain,
                ImageFit.cover => pw.BoxFit.cover,
                ImageFit.fill => pw.BoxFit.fill,
              },
            ),
          ),
        );

      case final QrElement qr:
        final String payload = document.resolveFields(qr.data, data);
        if (payload.trim().isEmpty) return null;
        final double size = qr.box.width > 0 ? qr.box.width * s : 60;
        return _positioned(
          left: left,
          top: top,
          width: size,
          rotation: qr.rotation,
          child: pw.BarcodeWidget(
            barcode: Barcode.qrCode(),
            data: payload,
            width: size,
            height: size,
            drawText: false,
            color: pdfColorFromHex(qr.colorHex),
            backgroundColor:
                pdfColorFromHex(qr.backgroundHex, fallback: PdfColors.white),
          ),
        );

      case final TextElement text:
        return _textElementWidget(
          context: context,
          element: text,
          document: document,
          data: data,
          left: left,
          top: top,
          width: width,
          pageHeight: pageHeight,
        );
    }
  }

  // ==========================================================================
  //                    التوقيعات المتعددة (رؤية PDF)
  // ==========================================================================

  /// كتلة التوقيعات: خانات متساوية العرض بفاصل [SignatureElement.spacing].
  ///
  /// تستخدم `element.slotLayout` نفسها التي يستخدمها المحرر (مصدر حساب وحيد)
  /// فلا يختلف التوزيع بين المعاينة والطباعة. تُبنى كـ`Row` بأعراض صريحة
  /// (مجموعها = عرض العنصر) بدل `Stack/Positioned` لأن موضع PDF النسبي يحتاج
  /// ارتفاعاً مؤكّداً لكل خانة، وهو غير معروف قبل قياس النص.
  pw.Widget _signatureWidget({
    required SignatureElement element,
    required List<SignatureSlot> slots,
    required TemplateDocument document,
    required Map<String, String> data,
    required Map<String, pw.ImageProvider?> images,
    required double width,
  }) {
    final double s = document.scale;
    final double designWidth =
        element.box.width > 0 ? element.box.width : (s > 0 ? width / s : width);
    final List<SignatureSlotRect> rects =
        element.slotLayout(designWidth, slotCountOverride: slots.length);
    final double blockHeight =
        element.box.height > 0 ? element.box.height * s : 0;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: <pw.Widget>[
        for (int i = 0; i < rects.length && i < slots.length; i++) ...<pw.Widget>[
          if (i > 0) pw.SizedBox(width: element.spacing * s),
          pw.SizedBox(
            width: rects[i].width * s,
            height: blockHeight > 0 ? blockHeight : null,
            child: _signatureSlotWidget(
              element: element,
              slot: slots[i],
              document: document,
              data: data,
              images: images,
              slotWidth: rects[i].width,
              scale: s,
            ),
          ),
        ],
      ],
    );
  }

  /// خانة توقيع واحدة: الصورة ← الخط ← الاسم ← الدور.
  pw.Widget _signatureSlotWidget({
    required SignatureElement element,
    required SignatureSlot slot,
    required TemplateDocument document,
    required Map<String, String> data,
    required Map<String, pw.ImageProvider?> images,
    required double slotWidth,
    required double scale,
  }) {
    final String role = document.resolveFields(slot.role, data);
    final String name = document.resolveFields(slot.name, data);
    final bool rtl = TextFlow.resolvesRtl(element.direction, '$name $role');
    final pw.TextAlign align = switch (element.align) {
      SignatureAlign.start => rtl ? pw.TextAlign.right : pw.TextAlign.left,
      SignatureAlign.end => rtl ? pw.TextAlign.left : pw.TextAlign.right,
      SignatureAlign.center => pw.TextAlign.center,
    };

    final pw.ImageProvider? provider = slot.hasImage
        ? images['${slot.imageSource.jsonValue}:${slot.imagePath}']
        : null;
    final double imageHeight = element.imageHeightFor(
      slotWidth,
      boxHeight: element.box.height,
    );
    final pw.Font nameFont = fonts.resolve(
      element.family,
      PdfFontWeight.semiBold,
      element.customFont,
    );
    final pw.Font roleFont = fonts.resolve(
      element.family,
      PdfFontWeight.regular,
      element.customFont,
    );

    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: <pw.Widget>[
        if (provider != null)
          pw.SizedBox(
            height: imageHeight * scale,
            child: pw.Padding(
              padding: pw.EdgeInsets.symmetric(horizontal: 6 * scale),
              child: pw.Image(provider, fit: pw.BoxFit.contain),
            ),
          ),
        if (element.showDivider)
          pw.Padding(
            padding: pw.EdgeInsets.only(
              top: (provider != null ? 4 : 0) * scale,
              left: 12 * scale,
              right: 12 * scale,
              bottom: 5 * scale,
            ),
            child: pw.Container(
              height: 1,
              color: PdfColor.fromInt(0xFF6B7280),
            ),
          ),
        if (name.trim().isNotEmpty)
          pw.Text(
            ArabicTextEngine.toVisual(name),
            textAlign: align,
            textDirection: pw.TextDirection.ltr,
            style: pw.TextStyle(
              font: nameFont,
              fontFallback: fonts.fallbackFonts,
              fontSize: element.nameFontSize * scale,
              color: pdfColorFromHex(element.nameColorHex),
              height: 1.3,
            ),
          ),
        if (role.trim().isNotEmpty)
          pw.Text(
            ArabicTextEngine.toVisual(role),
            textAlign: align,
            textDirection: pw.TextDirection.ltr,
            style: pw.TextStyle(
              font: roleFont,
              fontFallback: fonts.fallbackFonts,
              fontSize: element.roleFontSize * scale,
              color: pdfColorFromHex(element.roleColorHex),
              height: 1.3,
            ),
          ),
      ],
    );
  }

  /// وضع العنصر بإحداثيات مطلقة مع تطبيق الدوران حول **مركز العنصر**.
  pw.Widget _positioned({
    required double left,
    required double top,
    required double width,
    required pw.Widget child,
    double rotation = 0,
  }) {
    final pw.Widget inner = rotation == 0
        ? child
        : pw.Transform.rotate(
            angle: rotation * math.pi / 180,
            child: child,
          );
    return pw.Positioned(
      left: left,
      top: top,
      child: pw.SizedBox(width: width > 0 ? width : null, child: inner),
    );
  }

  // ==========================================================================
  //                              النص
  // ==========================================================================

  pw.Widget? _textElementWidget({
    required pw.Context context,
    required TextElement element,
    required TemplateDocument document,
    required Map<String, String> data,
    required double left,
    required double top,
    required double width,
    required double pageHeight,
  }) {
    final String logical = document.resolveFields(element.text, data);
    if (logical.trim().isEmpty) return null;

    final double s = document.scale;
    final double fontSize = element.fontSize * s;
    if (fontSize <= 0) return null;

    // اختيار تلقائي حسب الكتابة: بلا خط مخصص، إن لم يغطِّ الخط الحالي كل محارف
    // النص **غير اللاتينية** ننتقل لأقرب خط محزوم يغطّيها. أما اللاتينية الممتدة
    // (التركية ğ/ş/İ/ı) فلا تُغيّر العائلة إطلاقاً — يرسمها خط الاحتياط اللاتيني
    // المحزوم (Noto Sans) في `fontFallback` بأسلوب لاتيني موحّد، لا بخط عربي.
    final PdfFontFamily family = element.customFont == null
        ? fonts.familyForText(logical, preferred: element.family)
        : element.family;
    final pw.Font font =
        fonts.resolve(family, element.weight, element.customFont);
    final PdfFont metricsFont = font.getFont(context);

    final bool rtl = TextFlow.resolvesRtl(element.direction, logical);

    double measure(String visualText) =>
        (metricsFont.stringMetrics(visualText) * fontSize).advanceWidth +
        element.letterSpacing * s * visualText.length;

    final bool justify = element.align == ElementTextAlign.justify;
    final List<String> lines = ArabicTextEngine.wrap(
      text: logical,
      maxWidth: width,
      measureWidth: measure,
      maxLines: element.maxLines,
      justify: justify,
      justifyMode: element.justifyMode,
    );

    final double lineHeight = fontSize * element.lineHeight;
    final double textHeight = lineHeight * lines.length;
    final double boxHeight =
        element.box.height > 0 ? element.box.height * s : textHeight;

    final double verticalOffset = switch (element.verticalAlign) {
      ElementVerticalAlign.top => 0,
      ElementVerticalAlign.middle => (boxHeight - textHeight) / 2,
      ElementVerticalAlign.bottom => boxHeight - textHeight,
    };

    final pw.Widget body = pw.SizedBox(
      width: width > 0 ? width : null,
      child: pw.Opacity(
        opacity: element.opacity.clamp(0, 1),
        child: pw.Text(
          lines.join('\n'),
          textDirection: pw.TextDirection.ltr,
          textAlign: _alignFor(element.align, rtl),
          softWrap: false,
          overflow: pw.TextOverflow.clip,
          style: pw.TextStyle(
            font: font,
            fontFallback: fonts.fallbackFonts,
            fontSize: fontSize,
            color: pdfColorFromHex(element.colorHex),
            height: element.lineHeight,
            letterSpacing: element.letterSpacing * s,
            background: element.backgroundHex == null
                ? null
                : pw.BoxDecoration(
                    color: pdfColorFromHex(element.backgroundHex),
                  ),
          ),
        ),
      ),
    );

    return _positioned(
      left: left,
      top: (top + verticalOffset).clamp(0, pageHeight),
      width: width,
      rotation: element.rotation,
      child: body,
    );
  }

  /// تحويل المحاذاة المنطقية إلى محاذاة فيزيائية حسب اتجاه النص.
  static pw.TextAlign _alignFor(ElementTextAlign align, bool rtl) {
    return switch (TextFlow.anchorFor(align, rtl)) {
      TextAnchor.left => pw.TextAlign.left,
      TextAnchor.center => pw.TextAlign.center,
      TextAnchor.right => pw.TextAlign.right,
    };
  }

  // ==========================================================================
  //                              الأشكال
  // ==========================================================================

  pw.Widget _shapeWidget(
    ShapeElement shape,
    TemplateDocument document,
    double width,
  ) {
    final double s = document.scale;
    final double height = shape.box.height > 0 ? shape.box.height * s : 0;
    final PdfColor? fill =
        shape.fillHex == null ? null : pdfColorFromHex(shape.fillHex);
    final PdfColor? stroke =
        shape.strokeHex == null ? null : pdfColorFromHex(shape.strokeHex);

    if (shape.kind == ShapeKind.line) {
      final double thickness = shape.strokeWidth > 0 ? shape.strokeWidth * s : s;
      return pw.Container(
        width: width,
        height: thickness,
        color: stroke ?? fill ?? PdfColors.black,
      );
    }

    return pw.Container(
      width: width,
      height: height > 0 ? height : null,
      decoration: pw.BoxDecoration(
        color: fill,
        shape: shape.kind == ShapeKind.ellipse
            ? pw.BoxShape.circle
            : pw.BoxShape.rectangle,
        borderRadius: shape.kind == ShapeKind.rect && shape.radius > 0
            ? pw.BorderRadius.circular(shape.radius * s)
            : null,
        border: stroke == null || shape.strokeWidth <= 0
            ? null
            : pw.Border.all(color: stroke, width: shape.strokeWidth * s),
      ),
    );
  }

  /// رسم الختم متجهاً (بلا صور): دائرة + حلقة + نجمة خماسية.
  void _paintSeal(PdfGraphics canvas, double size, SealElement seal) {
    final double radius = size / 2;
    canvas
      ..setFillColor(pdfColorFromHex(seal.fillHex))
      ..drawEllipse(0, 0, size, size)
      ..fillPath()
      ..setStrokeColor(pdfColorFromHex(seal.ringHex))
      ..setLineWidth(size * 0.045)
      ..drawEllipse(size * 0.085, size * 0.085, size * 0.83, size * 0.83)
      ..strokePath();

    final double outer = radius * seal.starRatio.clamp(0.1, 0.95);
    final double inner = outer * 0.42;
    final double centerX = radius;
    final double centerY = radius;
    canvas.setFillColor(pdfColorFromHex(seal.starHex));
    for (int i = 0; i < 10; i++) {
      final double r = i.isEven ? outer : inner;
      final double angle = (math.pi / 5) * i - math.pi / 2;
      final double x = centerX + r * math.cos(angle);
      // إحداثيات PDF أصلها أسفل اليسار ⇒ نقلب الرأسي.
      final double y = centerY - r * math.sin(angle);
      if (i == 0) {
        canvas.moveTo(x, y);
      } else {
        canvas.lineTo(x, y);
      }
    }
    canvas
      ..closePath()
      ..fillPath();
  }
}
