import 'dart:math' as math;
import 'dart:typed_data';

import 'package:barcode/barcode.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/shape_geometry.dart';
import '../models/template_document.dart';
import '../models/template_element.dart';
import '../models/text_flow.dart';
import '../models/text_styling.dart';
import 'arabic_text_engine.dart';
import 'pdf_color.dart';
import 'pdf_gradient.dart';
import 'pdf_decor_painter.dart';
import 'pdf_font_catalog.dart';

/// طبقة ظل نص واحدة في الـ PDF: إزاحة بالكسر ونقاط + شفافية.
final class PdfTextShadowLayer {
  const PdfTextShadowLayer({
    required this.dx,
    required this.dy,
    required this.opacity,
  });

  /// الإزاحة الأفقية بالكسر ونقاط الطباعة (الموجب يميناً).
  final double dx;

  /// الإزاحة الرأسية (الموجب أسفل).
  final double dy;

  final double opacity;
}

/// يبني طبقات ظل النص بنفس ترتيب رسمها (من الخلف إلى الأمام).
///
/// * ظل حادّ (بلا تمويه): طبقة واحدة بإزاحة الظل وشفافيته.
/// * ظل مموّه: نفس الطبقة + أربع طبقات على محيط دائرة نصف قطرها `blur/2`
///   بنصف الشفافية — تقريب بصري للتمويه لأن ملفات PDF لا تعرف التمويه.
///
/// دالة نقية تُختبر وحدها، والمحرّك يبني منها طبقاته فعلاً فيَستحيل أن يختلف
/// ما يُختبر عمّا يُرسم.
List<PdfTextShadowLayer> pdfTextShadowLayers(TextShadow shadow, double scale) {
  if (!shadow.isVisible) return const <PdfTextShadowLayer>[];

  final double opacity = shadow.opacity.clamp(0, 1);
  final double blur = math.max(0, shadow.blurRadius) * scale;
  final double spread = math.max(0, shadow.spread) * scale;
  final double dx = shadow.offsetX * scale;
  final double dy = shadow.offsetY * scale;

  return <PdfTextShadowLayer>[
    PdfTextShadowLayer(dx: dx, dy: dy, opacity: opacity),
    if (blur > 0)        for (final (double offsetX, double offsetY) in <(double, double)>[
          (blur / 2, 0),
          (-blur / 2, 0),
          (0, blur / 2),
          (0, -blur / 2),
        ])
        PdfTextShadowLayer(
          dx: dx + offsetX,
          dy: dy + offsetY,
          opacity: opacity * 0.5,
        ),
    // التوسيع (Spread): نسخ إضافية على محيط دائرة نصف قطرها التوسيع بشفافية
    // الظل نفسها — نفس ما تفعله اللوحة (حلقة نسخ) فلا ينحرف المطبوع عن الشاشة.
    if (spread > 0)
      for (final (double offsetX, double offsetY) in <(double, double)>[
        (spread, 0),
        (-spread, 0),
        (0, spread),
        (0, -spread),
        (spread * 0.7, spread * 0.7),
        (-spread * 0.7, -spread * 0.7),
        (spread * 0.7, -spread * 0.7),
        (-spread * 0.7, spread * 0.7),
      ])
        PdfTextShadowLayer(
          dx: dx + offsetX,
          dy: dy + offsetY,
          opacity: opacity,
        ),
  ];
}

/// طبقات **التوهّج الخارجي** للنص في الـ PDF (بلا تمويه حقيقي في الحزمة،
/// فتُمثَّل الحلقة بإزاحات محيطة: النصف بنصف الشفافية والربع المتعلّق بالتوسيع).
///
/// دالة نقية تُختبر وحدها، تماماً كـ[pdfTextShadowLayers].
List<PdfTextShadowLayer> pdfTextGlowLayers(GlowEffect? glow, double scale) {
  if (glow == null || !glow.isVisible) return const <PdfTextShadowLayer>[];

  final double opacity = glow.opacity.clamp(0, 1);
  final double blur = math.max(0, glow.radius) * scale;
  final double spread = math.max(0, glow.spread) * scale;

  return <PdfTextShadowLayer>[
    PdfTextShadowLayer(dx: 0, dy: 0, opacity: opacity * 0.6),
    if (blur > 0)
      for (final (double offsetX, double offsetY) in <(double, double)>[
        (blur / 2, 0),
        (-blur / 2, 0),
        (0, blur / 2),
        (0, -blur / 2),
      ])
        PdfTextShadowLayer(
          dx: offsetX,
          dy: offsetY,
          opacity: opacity * 0.35,
        ),
    if (spread > 0)
      for (final (double offsetX, double offsetY) in <(double, double)>[
        (spread, 0),
        (-spread, 0),
        (0, spread),
        (0, -spread),
      ])
        PdfTextShadowLayer(
          dx: offsetX,
          dy: offsetY,
          opacity: opacity * 0.6,
        ),
  ];
}

/// تحويل تدرّج خلفية المستند إلى تدرّج `pdf` — نفس اتجاه اللوحة بالضبط.
///
/// وُضِع هنا (لا في الموديل) لأن [BackgroundGradient] موديل `dart:ui` نقيّ
/// لا يعرف شيئاً عن حزمة `pdf`، ولأن الدلالة تُترجم مرّة واحدة في مكان واحد.
///
/// **عالي الدقة ومضادّ للترصيف:** يُمرَّر سلّم عيّنات كثيف مُشوَّش
/// ([pdfGradientRamp]) **بلا `stops`**، فتبني الحزمة منه دالة تنعيم واحدة
/// (`/FunctionType 0`) داخل ملف الـ PDF. النتيجة: خلفية الورقة تبقى **متجهة
/// بالكامل** (لا صورة رسترة، فلا حاجة لضغط صور ولا مواريه)، ولا تظهر فيها
/// خطوط تكميم (Banding) لأن انتقالات اللون تفتّتت ضجيجاً غير مرئي.
pw.LinearGradient pdfPaperGradient(BackgroundGradient gradient) {
  final (pw.Alignment begin, pw.Alignment end) = switch (gradient.direction) {
    GradientDirection.vertical => (pw.Alignment.topCenter, pw.Alignment.bottomCenter),
    GradientDirection.horizontal =>
      (pw.Alignment.centerLeft, pw.Alignment.centerRight),
    GradientDirection.diagonal => (pw.Alignment.topLeft, pw.Alignment.bottomRight),
  };
  return pw.LinearGradient(
    begin: begin,
    end: end,
    colors: pdfGradientRamp(
      pdfColorFromHex(gradient.startHex, fallback: PdfColors.white),
      pdfColorFromHex(gradient.endHex, fallback: PdfColors.white),
    ),
  );
}

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
/// **عقد الإحداثيات (1:1 Matrix Mapping):** كل ما يُرسم هنا يمرّ من
/// [TemplateDocument.boxToPdfRect] و[TemplateDocument.scale] وحدهما — تشابه
/// واحد بوحدة تصميم ← ‎0.75‎ نقطة (‎72/96‎)، بلا أي إعادة حساب لاحقة لموضع نصّ
/// أو صورة، ولا قصّ على حواف الصفحة، ولا تقدير لارتفاع النصّ (المحاذاة
/// الرأسية تُترك للتخطيط نفسه). فالموقع ومقاس الخطّ على الشاشة هما نفسهما في
/// الملف المطبوع بلا انزياح.
///
/// **عقد الطباعة عالية الدقة:** الخلفيات والتدرّجات تبقى **متجهة** (لا تُرسر
/// ولا تُضغط صورةً) مع سلّم ألوان كثيف مُشوَّش يمنع التخطيط المزدوج (Banding)،
/// والصور تُضمَّن بمرشّح **FlateDecode غير المتلف** (أو `DCTDecode` بلا إعادة
/// ترميز لملف JPEG الأصل) — فتصدير الـ 300dpi لا يفقد حدة ولا يولّد مواريه.
///
/// **لماذا منفصل عن `PdfGeneratorService`؟** لأن هذا الجزء **خالص** (لا يلمس
/// `rootBundle` ولا أي قناة منصة): يأخذ خطوطاً جاهزة (`PdfFontSet`) وصوراً
/// جاهزة (`pw.ImageProvider`)، فيمكن تشغيله في أي isolate — بما في ذلك isolate
/// خلفي لتفادي تجميد الواجهة أثناء التوليد الجماعي.
class PdfRenderer {
  const PdfRenderer({required this.fonts, this.compress = true, this.dpi});

  /// هامش أمان أفقي بنقاط الطباعة يُخصَّص من عرض الصندوق قبل الالتفاف.
  ///
  /// يقيس محرّكنا عرض السطر بـ`stringMetrics` على النص **البصري كاملاً**، بينما
  /// تُعيد حزمة `pdf` تخطيط السطر **كلمةً كلمةً** وتضيف `letterSpacing` بعد كل
  /// كلمة. الفرق قد يكون جزءاً من النقطة، فإن ساوى عرضُ السطر عرضَ الصندوق
  /// ملامساً حدّه انقصّ آخرُ حرف (نزول الكاف في «فيك» مثلاً). هامش ‎0.5‎ نقطة
  /// يمحو هذا الفرق تماماً وهو أصغر من أن يُغيّر تقسيم الأسطر المرئيّ.
  static const double _textWrapSafety = 0.5;

  final PdfFontSet fonts;
  final bool compress;

  /// دقّة تحليل الصور المضمّنة (نقطة/بوصة).
  ///
  /// `null` = كما هي الصورة (سلوك التصدير العادي). عند تحديد القيمة تُعاد
  /// الصور فعلياً عند تلك الدقّة لمقاسها المطبوع — وهو ما يجعل ورقة التجميع
  /// عالية الدقّة (300 نقطة/بوصة) حتى لمن أراد تكبير الطبعة.
  final double? dpi;

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
      build: (pw.Context context) =>
          buildContent(context: context, document: document, data: data, images: images),
    );
  }

  /// محتوى المستند كاملًا كويدجت بحجمه الطبيعي (خلفية + عناصر).
  ///
  /// [pw.Page] تستدعيه للصفحة العادية، و**محرّك الحصر** يستدعيه ليضع نسخاً
  /// متعددة من العنصر داخل ورقة أكبر — نفس التحويل نفسه بالضبط، فيخرج ما
  /// يراه المستخدم في المعاينة مطابقاً لما يُطبع في ملف التجميع.
  pw.Widget buildContent({
    required pw.Context context,
    required TemplateDocument document,
    required Map<String, String> data,
    required Map<String, pw.ImageProvider?> images,
  }) {
    final BackgroundGradient? gradient = document.backgroundGradient;
    return pw.Container(
      width: document.pageWidthPt,
      height: document.pageHeightPt,
      // الخلفية لون مفرد أو تدرّج — والتدرّج يتقدّم عند وجوده (مطابق تماماً
      // لما ترسمه اللوحة).
      decoration: gradient == null
          ? null
          : pw.BoxDecoration(gradient: pdfPaperGradient(gradient)),
      color: gradient == null
          ? pdfColorFromHex(document.backgroundHex, fallback: PdfColors.white)
          : null,
      child: pw.Stack(
        children: <pw.Widget>[
          // العنصر المخفي لا يُطبع أصلاً — نفس سلوك اللوحة بالضبط.
          for (final TemplateElement element in document.elements)
            if (document.isVisible(element))
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
    final double width = rect.width;

    switch (element) {
      case UnknownElement():
        return null;

      case final ShapeElement shape:
        // ارتفاع صريح دائماً — لا نتركه `null` أبداً (نفس القاعدة التي
        // يستخدمها الرسّام داخلياً) كي لا يتمدّد العنصر في مكدّس الصفحة.
        final double shapeHeight = shape.box.height > 0
            ? shape.box.height * s
            : (shape.kind == ShapeKind.line
                ? math.max(shape.strokeWidth, 1) * s
                : width);
        return _positioned(
          left: left,
          top: top,
          width: width,
          height: shapeHeight,
          rotation: shape.rotation,
          child: _shapeWidget(
            shape,
            document,
            width,
            shapeHeight,
            context.document,
          ),
        );

      case final SealElement seal:
        // مربّع بأصغر ضلعين — نفس قاعدة المحرر (‎SealPainter‎).
        final double size = seal.squareSide() * s;
        return _positioned(
          left: left,
          top: top,
          width: size,
          height: size,
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
          height: decorHeight,
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
        final double signatureHeight =
            _signatureBlockHeight(signature, s, width);
        return _positioned(
          left: left,
          top: top,
          width: width,
          height: signatureHeight,
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
              blockHeight: signatureHeight,
            ),
          ),
        );

      case final ImageElement image:
        // النسخة المعالجة أولاً (تلوين و/أو ضبط لوني، إن وُجد أحدهما)، ثم
        // الأصلية كاحتياط كي لا يسقط العنصر لو لم يُجهَّز مفتاح المعالجة.
        final String? processedKey = image.processedImageKey;
        final pw.ImageProvider? resolved =
            (processedKey == null ? null : images[processedKey]) ??
                images[image.imageKey];
        if (resolved == null) return null;
        final double height =
            image.box.height > 0 ? image.box.height * s : width;
        return _positioned(
          left: left,
          top: top,
          width: width,
          height: height,
          rotation: image.rotation,
          child: pw.Opacity(
            opacity: image.opacity.clamp(0, 1),
            child: pw.Image(
              resolved,
              width: width,
              height: height,
              dpi: dpi,
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
          height: size,
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
        );
    }
  }

  // ==========================================================================
  //                    التوقيعات المتعددة (رؤية PDF)
  // ==========================================================================

  /// ارتفاع كتلة التوقيع بالنقاط — **صريح دائماً** (لا `height: null` أبداً).
  ///
  /// عند تحديد ارتفاع الصندوق يُستخدم كما هو؛ وعند `0` (ارتفاع تلقائي) يُشتقّ
  /// من محتوى أطول خانة (صورة + خط فاصل + الاسم + الدور) بنفس القواعد التي
  /// يُبنى بها المحتوى فعلاً، فيصير للكتلة حدّ أعلى معروف يمنعها من الهبوط على
  /// الطبقة السفلى أو التمدّد في مكدّس الصفحة.
  double _signatureBlockHeight(
    SignatureElement element,
    double scale,
    double printWidth,
  ) {
    if (element.box.height > 0) return element.box.height * scale;

    final List<SignatureSlot> slots = element.orderedSlots;
    final double designWidth = element.box.width > 0
        ? element.box.width
        : (scale > 0 ? printWidth / scale : printWidth);
    final List<SignatureSlotRect> rects =
        element.slotLayout(designWidth, slotCountOverride: slots.length);
    if (rects.isEmpty) {
      return (element.nameFontSize + element.roleFontSize) * 1.3 * scale +
          40 * scale;
    }

    double tallest = 0;
    for (int i = 0; i < rects.length && i < slots.length; i++) {
      final SignatureSlot slot = slots[i];
      double h = 0;
      if (slot.hasImage) {
        h += element.imageHeightFor(rects[i].width, boxHeight: 0) * scale;
      }
      if (element.showDivider) {
        h += (slot.hasImage ? 4 : 0) * scale + 1 + 5 * scale;
      }
      final bool hasName = slot.name.trim().isNotEmpty;
      final bool hasRole = slot.role.trim().isNotEmpty;
      if (hasName) {
        h += element.nameFontSize * 1.3 * scale;
      }
      // فاصل رأسي حتمي بين الاسم والدور — يطابق SizedBox(height: 1*scale)
      // المضاف في _signatureSlotWidget لضمان عدم التداخل.
      if (hasName && hasRole) {
        h += 1 * scale;
      }
      if (hasRole) {
        h += element.roleFontSize * 1.3 * scale;
      }
      tallest = math.max(tallest, h);
    }
    return tallest > 0
        ? tallest
        : (element.nameFontSize + element.roleFontSize) * 1.3 * scale;
  }

  /// كتلة التوقيعات: خانات متساوية العرض بفاصل [SignatureElement.spacing].
  ///
  /// تستخدم `element.slotLayout` نفسها التي يستخدمها المحرر (مصدر حساب وحيد)
  /// فلا يختلف التوزيع بين المعاينة والطباعة. تُبنى كـ`Row` بأعراض صريحة
  /// (مجموعها = عرض العنصر) وارتفاع صريح مؤكّد لكل خانة، فلا يعتمد أي شيء على
  /// قياس ارتفاع تلقائي يسمح بالتمدّد.
  pw.Widget _signatureWidget({
    required SignatureElement element,
    required List<SignatureSlot> slots,
    required TemplateDocument document,
    required Map<String, String> data,
    required Map<String, pw.ImageProvider?> images,
    required double width,
    required double blockHeight,
  }) {
    final double s = document.scale;
    final double designWidth =
        element.box.width > 0 ? element.box.width : (s > 0 ? width / s : width);
    final List<SignatureSlotRect> rects =
        element.slotLayout(designWidth, slotCountOverride: slots.length);

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: <pw.Widget>[
        for (int i = 0; i < rects.length && i < slots.length; i++) ...<pw.Widget>[
          if (i > 0) pw.SizedBox(width: element.spacing * s),
          pw.SizedBox(
            width: rects[i].width * s,
            height: blockHeight,
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

    final pw.Alignment lineAlignment = switch (align) {
      pw.TextAlign.center => pw.Alignment.center,
      pw.TextAlign.right => pw.Alignment.centerRight,
      _ => pw.Alignment.centerLeft,
    };

    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      mainAxisAlignment: pw.MainAxisAlignment.center,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: <pw.Widget>[
        if (provider != null)
          pw.SizedBox(
            height: imageHeight * scale,
            child: pw.Padding(
              padding: pw.EdgeInsets.symmetric(horizontal: 6 * scale),
              child: pw.Image(provider, fit: pw.BoxFit.contain, dpi: dpi),
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
          pw.Container(
            height: element.nameFontSize * scale * 1.3,
            alignment: lineAlignment,
            child: pw.Text(
              ArabicTextEngine.toVisual(name),
              textAlign: align,
              textDirection: pw.TextDirection.ltr,
              style: pw.TextStyle(
                font: nameFont,
                fontFallback: fonts.fallbackFonts,
                fontSize: element.nameFontSize * scale,
                color: pdfColorFromHex(element.nameColorHex),
              ),
            ),
          ),
        if (name.trim().isNotEmpty && role.trim().isNotEmpty)
          pw.SizedBox(height: 1 * scale),
        if (role.trim().isNotEmpty)
          pw.Container(
            height: element.roleFontSize * scale * 1.3,
            alignment: lineAlignment,
            child: pw.Text(
              ArabicTextEngine.toVisual(role),
              textAlign: align,
              textDirection: pw.TextDirection.ltr,
              style: pw.TextStyle(
                font: roleFont,
                fontFallback: fonts.fallbackFonts,
                fontSize: element.roleFontSize * scale,
                color: pdfColorFromHex(element.roleColorHex),
              ),
            ),
          ),
      ],
    );
  }

  /// وضع العنصر بإحداثيات مطلقة مع تطبيق الدوران حول **مركز العنصر**.
  ///
  /// [height] اختياري: يُمرَّر صريحاً للعناصر التي يُحدَّد ارتفاع صندوقها في
  /// المستند (مثل النص) حتى تُحاذي داخله بلا تقديرات جانبية.
  ///
  /// [clipPad] = نصف قطر **مساحة أثر** العنصر (ظل/توهّج بنقاط الطباعة).
  ///
  /// **لماذا القصّ إلى صندوق العنصر؟** لأن عناصر النص تُرسم بـ
  /// `overflow: visible` (كي لا يقتطع قارئ الحزمة آخر حرف من السطر)، وهذا
  /// يسمح لنصّ أطول من صندوقه بأن يتسرّب فوق العناصر المجاورة فيبدو الملف
  /// «متراكباً». الحلّ: قصٌّ على **صندوق العنصر موسّعاً بمقدار أثر ظلّه/توهّجه
  /// فقط** — نفس ما تفعله اللوحة تماماً (`EffectBoundsClipper` في المحرّر):
  /// النص لا يخرج عن حدوده، ومع ذلك يظهر ظلّه/توهّجه كاملاً.
  ///
  /// عند `confine == false` (الأشكال/الصور/الأختام التي ترسم داخل مقاسها
  /// بنفسها) لا يُضاف أي قصّ فيبقى الخرج مطابقاً لما كان عليه حرفياً.
  pw.Widget _positioned({
    required double left,
    required double top,
    required double width,
    double? height,
    bool confine = false,
    double clipPad = 0,
    required pw.Widget child,
    double rotation = 0,
  }) {
    final double w = width > 0 ? width : 0;
    final double pad = confine && clipPad > 0 ? clipPad : 0;

    pw.Widget body = w > 0
        ? pw.SizedBox(width: w, height: height, child: child)
        : pw.SizedBox(height: height, child: child);

    // القصّ إلى **صندوق العنصر** (موسّعاً بأثر التأثيرات فقط): يوضع المحتوى
    // داخل حشوة [pad] ويُعاد الصندوق موسّعاً بـ[pad] من كل جهة ثم يُقصّ، فيبقى
    // مركز العنصر (ومحور دورانه) في مكانه بالضبط.
    if (confine) {
      body = pw.ClipRect(
        child: pw.SizedBox(
          width: w > 0 ? w + pad * 2 : null,
          height: height == null ? null : height + pad * 2,
          child: pw.Padding(
            padding: pw.EdgeInsets.all(pad),
            child: body,
          ),
        ),
      );
    }

    final pw.Widget inner = rotation == 0
        ? body
        : pw.Transform.rotate(
            angle: rotation * math.pi / 180,
            child: body,
          );

    return pw.Positioned(
      left: left - pad,
      top: top - pad,
      child: inner,
    );
  }

  /// نصف قطر **مساحة أثر** ظل/توهّج النصّ بنقاط الطباعة.
  ///
  /// يحاكي حساب `_textEffectReach` في محرّر اللوحة حتى يُقصّ النصّ في الـ PDF
  /// عند نفس الحدّ الذي يُقصّ عنده على الشاشة — فلا يبدو المطبوع «متراكباً»
  /// ولا يضيع الظلّ في الوقت نفسه. يُعيد `0` عند غياب أي أثر خارجي (فلا يُضاف
  /// قصّ أصلاً، ويبقى الخرج كما هو).
  double _textEffectReach(TextElement element, double scale) {
    double reach = 0;
    final TextShadow? shadow = element.shadow;
    if (shadow != null && shadow.isVisible) {
      final double blur = math.max(0, shadow.blurRadius) * scale;
      reach = math.max(
        reach,
        math.max(shadow.offsetX.abs(), shadow.offsetY.abs()) * scale +
            math.max(0, shadow.spread) * scale +
            blur,
      );
    }
    final GlowEffect? glow = element.outerGlow;
    if (glow != null && glow.isVisible) {
      final double blur = math.max(0, glow.radius) * scale;
      reach = math.max(
        reach,
        math.max(0, glow.spread) * scale + blur,
      );
    }
    return reach;
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

    // **التنسيق الجزئي** يشترط أن يكون النصّ بعد حلّ الحقول هو النصّ الأصلي
    // حرفياً؛ وإلا انزلقت حدود النطاقات عن كلماتها فصُبغ لون في موضع خاطئ.
    // تحقّق بسيط يمنع خطأً صامتاً بدل تخمين إزاحات.
    final bool useSpans = element.hasSpans && logical == element.text;
    final List<StyledTextSpan>? spans = useSpans
        ? StyledTextSpan.normalize(element.spans, logical.length)
        : null;

    // عرض الالتفاف مع هامش الأمان — لا يتغيّر تقسيم الأسطر المرئيّ، لكن يبقى
    // لآخر حرف فراغٌ فلا يلامس حدَّ القصّ.
    final double wrapWidth =
        width > _textWrapSafety ? width - _textWrapSafety : width;

    // **الضبط (Justify) يُطفأ عمداً عند وجود تنسيق جزئي**: يزيد فراغات أو
    // كشيدة داخل السطر فيصبح نصّه المرسوم أطول من مقطعه الأصلي، فلا يمكن
    // إسناد نطاق اللون إليه بصدق. البديل الأسوأ صبغٌ خاطئ، فنُضخِّم هنا
    // بعرض الصندوق نفسه ويظلّ التمديد مُعطَّلاً حتى يُرفع التنسيق الجزئي.
    final bool justify =
        element.align == ElementTextAlign.justify && spans == null;
    final List<WrappedLine> wrapped = ArabicTextEngine.wrapRanges(
      text: logical,
      maxWidth: wrapWidth,
      measureWidth: measure,
      maxLines: element.maxLines,
      justify: justify,
      justifyMode: element.justifyMode,
    );

    // ارتفاع صندوق العنصر بالنقاط — `0` يعني ارتفاعاً تلقائياً.
    final double boxHeight =
        element.box.height > 0 ? element.box.height * s : 0;

    // **خطوة السطر الفعلية** في حزمة `pdf` = ‎(ascent − descent) × مقاس الخط‎،
    // والحزمة **تتجاهل `TextStyle.height` تماماً في التخطيط** (تخزّنه فقط).
    // فتقدير المسافة من `lineHeight` وحده كان يمكن أن ينقص عن ارتفاع النصّ
    // الحقيقي (مثلاً `lineHeight = 1.0` بينما الطبيعي ≈ 1.13) فيُقصّ أسفل
    // السطر بمقدار قطعة — وهي بعينها علّة «انقلاع الحروف» وتراكب النصّ مع
    // الطبقة السفلى. نأخذ الطبيعي من مقاييس الخطّ نفسه، ونمرّر الزيادة كـ
    // `lineSpacing` ليطابق تباعد الأسطر ما يراه المستخدم على اللوحة.
    final double naturalLineStep = metricsFont.emptyLineHeight * fontSize;

    // **لا صندوق سطر أقصر من الارتفاع الطبيعي للخطّ**: ارتفاع السطر يحدّد
    // صندوق كل سطر، وهذا الصندوق نفسه هو مسار القصّ. فلو احترمنا `lineHeight`
    // طلباً حرفياً أدنى من الطبيعي (‎1.0‎ مثلاً = ‎15pt‎ بينما الحروف تحتاج
    // ‎≈16.9pt‎) لقُصّت أذيال الحروف العربية وأسافل الكلمات — وهو بالضبط ما يجعل
    // المطبوع يبدو «متراكباً» أو مقلوع الحروف على خلاف اللوحة. نأخذ الأكبر من
    // الطلب والطبيعي: نحترم تباعد المستخدم عندما يزيد، ولا نقتطع الحروف أبداً.
    final double flutterLineHeight = element.lineHeight > 0
        ? math.max(element.lineHeight * fontSize, naturalLineStep)
        : naturalLineStep;

    final pw.Alignment lineAlignment = switch (element.align) {
      ElementTextAlign.center => pw.Alignment.center,
      ElementTextAlign.start => rtl ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
      ElementTextAlign.end => rtl ? pw.Alignment.centerLeft : pw.Alignment.centerRight,
      ElementTextAlign.justify => rtl ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
    };

    final double layoutHeight = boxHeight > 0
        ? boxHeight
        : wrapped.length * flutterLineHeight;

    // نمط السطر الأصلي — أساس كل المقاطع ومعيار طبقات الظل.
    pw.TextStyle lineStyle({PdfColor? color, pw.BoxDecoration? background}) =>
        pw.TextStyle(
          font: font,
          fontFallback: fonts.fallbackFonts,
          fontSize: fontSize,
          color: color ?? pdfColorFromHex(element.colorHex),
          letterSpacing: element.letterSpacing * s,
          background: background,
          // تمت إزالة `height` و `lineSpacing` كلياً. حزمة `pdf` سترسم النص
          // بأبعاده الطبيعية، بينما يفرض `Container` مساحة السطر ويوسّط النص
          // بداخلها بشكل مطابق لمحرك Flutter.
        );

    // نصّ واحد يُعاد بناؤه بلون مختلف لطبقة الظل: نفس التقسيم والقياس والمحاذاة
    // فالظل مطابق للنص الأصلي تماماً (لا إزاحة ناتجة عن اختلاف التخطيط).
    //
    // طبقات الظل تُرسم **بلون واحد** عمداً: لون الظل يغطي النص كله، فلا
    // معنى لاستمرار ألوان المقاطع فيه.
    pw.Widget textWidget({PdfColor? color, pw.BoxDecoration? background}) {
      final List<pw.Widget> lineWidgets = <pw.Widget>[
        for (final WrappedLine line in wrapped)
          pw.Container(
            height: flutterLineHeight,
            alignment: lineAlignment,
            child: _lineChild(
              element: element,
              spans: color == null ? spans : null,
              logical: logical,
              line: line,
              fontSize: fontSize,
              scale: s,
              rtl: rtl,
              align: _alignFor(element.align, rtl),
              lineStyle: lineStyle(color: color, background: background),
            ),
          ),
      ];

      return pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: lineWidgets,
      );
    }

    final pw.BoxDecoration? background = element.backgroundHex == null
        ? null
        : pw.BoxDecoration(color: pdfColorFromHex(element.backgroundHex!));

    // شفافية العنصر **مضروبةً في ألفا اللون** إن كان مكتوباً بصيغة `#AARRGGBB`:
    // `setFillColor` في حزمة `pdf` يكتب `rg` بلا قناة ألفا، فتمرير اللون الثمانيّ
    // إلى [pdfColorFromHex] يُسقط الألفا صامتاً ويخرج النصّ معتماً على الشاشة
    // شفافاً — انزياح لونيّ كامل. نرفع الألفا إلى [pw.Opacity] فلا يضيع شيء.
    final pw.Widget body = pw.Opacity(
      opacity:
          element.opacity.clamp(0, 1) * pdfAlphaFromHex(element.colorHex),
      child: _withTextShadow(
        text: textWidget(background: background),
        shadow: element.shadow,
        outerGlow: element.outerGlow,
        scale: s,
        // أبعاد صريحة تُمرَّر لطبقات الظل/التوهّج: كل `pw.Positioned` داخل
        // `pw.Stack` يرث قيوداً **مفتوحة العرض** من الحزمة، فيحتاج بُعداً
        // محدداً وإلا انفجر التخطيط (‎"BoxConstraints forces an infinite
        // width"‎) وسقط التصدير كله.
        width: width,
        height: layoutHeight,
        buildShadow: (PdfColor color) => textWidget(color: color),
      ),
    );

    // المحاذاة الرأسية لكتلة النص بالكامل داخل الصندوق الكلي للعنصر.
    return _positioned(
      left: left,
      top: top,
      width: width,
      height: layoutHeight,
      confine: true,
      clipPad: _textEffectReach(element, s),
      rotation: element.rotation,
      child: pw.Container(
        height: layoutHeight,
        alignment: switch (element.verticalAlign) {
          ElementVerticalAlign.top => pw.Alignment.topCenter,
          ElementVerticalAlign.middle => pw.Alignment.center,
          ElementVerticalAlign.bottom => pw.Alignment.bottomCenter,
        },
        child: body,
      ),
    );
  }

  /// محتوى سطر واحد: `pw.RichText` بمقاطع متعدّدة عند وجود تنسيق جزئي، وإلا
  /// `pw.Text` اعتيادي **حرفياً كما كان** — فالمسار البسيط لا يتغيّر أبداً،
  /// فيبقى ملف PDF بلا تنسيق جزئي مطابقاً لما كان عليه قبل هذه الإضافة.
  ///
  /// ويُرجَع المسار البسيط أيضاً حين تعذّر إسناد المقاطع بصدق (راجع
  /// [_lineSpans]) — السلامة أولاً: لا حرف مكسور ولا لون في موضع خاطئ.
  pw.Widget _lineChild({
    required TextElement element,
    required List<StyledTextSpan>? spans,
    required String logical,
    required WrappedLine line,
    required double fontSize,
    required double scale,
    required bool rtl,
    required pw.TextAlign align,
    required pw.TextStyle lineStyle,
  }) {
    final pw.Text plain = pw.Text(
      line.visual,
      textDirection: pw.TextDirection.ltr,
      textAlign: align,
      softWrap: false,
      overflow: pw.TextOverflow.visible,
      style: lineStyle,
    );
    if (spans == null || spans.isEmpty || line.visual.isEmpty) return plain;

    final List<pw.TextSpan>? children = _lineSpans(
      element: element,
      spans: spans,
      logical: logical,
      line: line,
      fontSize: fontSize,
      scale: scale,
      rtl: rtl,
    );
    if (children == null) return plain;

    return pw.RichText(
      text: pw.TextSpan(children: children, style: lineStyle),
      textDirection: pw.TextDirection.ltr,
      textAlign: align,
      softWrap: false,
      overflow: pw.TextOverflow.visible,
    );
  }

  /// مقاطع سطر واحد بتنسيقاتها، أو `null` إن تعذّر إسنادها بصدق.
  ///
  /// **لماذا يُشترط التحقّق؟** الـ PDF يرسم نصّاً **بصرياً** بعد تشكيل
  /// [ArabicTextEngine.toVisual]، والتشكيل عملية ترقيم/تبديل على الفقرة كلها.
  /// تشكيل كل مقطع منفرداً لا يعطي بالضرورة ما ينتجه تشكيل الفقرة كاملة؛
  /// فالحرف العربي يتّصل بما قبله. لذلك:
  ///
  /// 1. نُشكّل كل مقطع، ونرتّب المقاطع بترتيب الاتجاه البصري (العربي مقلوب).
  /// 2. نقارن التركيبة بالسطر المرسوم فعلياً — إن تساويا نُصدِّر المقاطع.
  /// 3. إن اختلفت نجرّب الترتيب المعاكس.
  /// 4. وإن اختلفت أيضاً نُرجع `null` فيُرسم السطر ب STYLE الأساسي كاملاً.
  ///
  /// الحدود المقطّعة داخل كلمة عربية متوالية هي التي تفشل التحقّق، فتتحوّل
  /// النتيجة إلى سطر غير ملوّن بدل أن يخرج حرفٌ مشوّه — خسارة تجميلية صغيرة
  /// مقابل سلامة الطباعة.
  List<pw.TextSpan>? _lineSpans({
    required TextElement element,
    required List<StyledTextSpan> spans,
    required String logical,
    required WrappedLine line,
    required double fontSize,
    required double scale,
    required bool rtl,
  }) {
    if (line.start < 0 || line.end > logical.length || line.end <= line.start) {
      return null;
    }
    final String original = logical.substring(line.start, line.end);
    // الضبط أضاف فراغات أو كشيدة أو علامة حذف داخل المقطع ⇒ الإزاحات لم
    // تعد تطابق النصّ المرسوم.
    if (line.logical != original) return null;

    // إزاحات النطاقات داخل هذا السطر فقط (مقصوصة ومقحومة).
    final List<StyledTextSpan> shifted = <StyledTextSpan>[];
    for (final StyledTextSpan span in spans) {
      if (span.end <= line.start || span.start >= line.end) continue;
      final int start = math.max(span.start, line.start) - line.start;
      final int end = math.min(span.end, line.end) - line.start;
      if (end <= start) continue;
      shifted.add(StyledTextSpan(
        start: start,
        end: end,
        family: span.family,
        customFont: span.customFont,
        weight: span.weight,
        italic: span.italic,
        underline: span.underline,
        size: span.size,
        colorHex: span.colorHex,
        backgroundHex: span.backgroundHex,
      ));
    }
    if (shifted.isEmpty) return null;

    final List<StyledTextRun> runs = splitStyledRuns(original, shifted);
    if (runs.isEmpty) return null;

    final List<String> pieces = <String>[
      for (final StyledTextRun run in runs) run.textOf(original),
    ];

    String shape(List<int> order) {
      final StringBuffer buffer = StringBuffer();
      for (final int index in order) {
        buffer.write(ArabicTextEngine.toVisual(pieces[index]));
      }
      return buffer.toString();
    }

    final List<int> forward =
        List<int>.generate(runs.length, (int index) => index, growable: false);
    final List<int> backward = List<int>.from(forward.reversed);
    final List<int> order = rtl ? backward : forward;
    String shaped = shape(order);
    if (shaped != line.visual) {
      final List<int> alternate = rtl ? forward : backward;
      shaped = shape(alternate);
      if (shaped != line.visual) return null;
      return <pw.TextSpan>[
        for (final int index in alternate)
          _runSpan(runs[index], pieces[index], element, fontSize, scale),
      ];
    }
    return <pw.TextSpan>[
      for (final int index in order)
        _runSpan(runs[index], pieces[index], element, fontSize, scale),
    ];
  }

  /// مقطع واحد بتنسيقه المستقل — الحقول غير المذكورة تُورَّث من نمط السطر
  /// الأساسي (الحجم، تباعد الحروف، لون العنصر…) فلا يتكرّر شيء ولا ينحرف
  /// تباعد الأسطر بين كلمة ملوّنة وأخرى في السطر نفسه.
  pw.TextSpan _runSpan(
    StyledTextRun run,
    String text,
    TextElement element,
    double fontSize,
    double scale,
  ) {
    final ResolvedSpanStyle style = run.style;
    if (style.isBase) return pw.TextSpan(text: text);

    // الخط يُحلَّ فقط إن تغيّر شيء يخصّه؛ وإلا فنمط السطر كافٍ ويظلّ اتساق
    // الأوزان داخل الفقرة واحدة.
    final bool needsFont =
        style.family != null || style.weight != null || style.customFont != null;
    final PdfFontWeight weight = style.weight ?? element.weight;
    final String? custom = style.customFont ??
        (style.family == null ? element.customFont : null);

    return pw.TextSpan(
      text: text,
      style: pw.TextStyle(
        font: needsFont
            ? fonts.resolve(style.family ?? element.family, weight, custom)
            : null,
        fontSize: style.size == null ? null : style.size! * scale,
        color: style.colorHex == null
            ? null
            : pdfColorFromHex(style.colorHex!),
        background: style.backgroundHex == null
            ? null
            : pw.BoxDecoration(
                color: pdfColorFromHex(style.backgroundHex!),
              ),
        // `italic` مُسجَّل في ملف الـ PDF، وتُرسمه حزمة `pdf` ما دام الخط
        // يحمل ملفاً مائلاً؛ الخطوط العربية المضمّنة لا تحمله فتبقى قائمة.
        fontStyle: style.italic ? pw.FontStyle.italic : null,
        decoration: style.underline ? pw.TextDecoration.underline : null,
        decorationColor: style.colorHex == null
            ? null
            : pdfColorFromHex(style.colorHex!),
      ),
    );
  }

  /// ظل النص في الـ PDF — الحزمة `pdf` لا تدعم `TextStyle.shadows`، فتُرسم
  /// نسخة من النص بلون الظل **خلف** النص الأصلي:
  ///
  /// * ظل حادّ (بلا تمويه): نسخة واحدة مُزاحة بإزاحة الظل وحدها.
  /// * ظل مموّه: النسخة المزاحة + أربع نسخ على محيط دائرة نصف قطرها `blur/2`
  ///   بشفافية أنصاف — تقريب بصري متّسق مع `blurRadius` في اللوحة (ملفات PDF
  ///   لا تعرف التمويه الحقيقي، فلا يوجد غيره).
  /// وتُضاف فوقها طبقات **التوهّج الخارجي** إن وُجد (`outerGlow`) بنفس
  /// الآلية: التوهّج ظلٌّ بإزاحة صفرية وتوسيع/تمويه محيطي.
  pw.Widget _withTextShadow({
    required pw.Widget text,
    required TextShadow? shadow,
    GlowEffect? outerGlow,
    required double scale,
    required double width,
    required double height,
    required pw.Widget Function(PdfColor color) buildShadow,
  }) {
    final bool hasShadow = shadow != null && shadow.isVisible;
    final bool hasGlow = outerGlow != null && outerGlow.isVisible;
    if (!hasShadow && !hasGlow) return text;

    return pw.Stack(
      // الإفلات المرئي ضروري: النسخ المموّهة تخرج قليلاً عن صندوق النص.
      overflow: pw.Overflow.visible,
      children: <pw.Widget>[
        if (hasGlow)
          for (final PdfTextShadowLayer layer
              in pdfTextGlowLayers(outerGlow, scale))
            pw.Positioned(
              left: layer.dx,
              top: layer.dy,
              child: pw.SizedBox(
                width: width,
                height: height,
                child: pw.Opacity(
                  opacity: layer.opacity,
                  child: buildShadow(pdfColorFromHex(outerGlow.colorHex)),
                ),
              ),
            ),
        if (hasShadow)
          for (final PdfTextShadowLayer layer
              in pdfTextShadowLayers(shadow, scale))
            pw.Positioned(
              left: layer.dx,
              top: layer.dy,
              child: pw.SizedBox(
                width: width,
                height: height,
                child: pw.Opacity(
                  opacity: layer.opacity,
                  child: buildShadow(pdfColorFromHex(shadow.colorHex)),
                ),
              ),
            ),
        // النص الأصلي: العنصر غير المحدَّد الموضع الذي يحدّد حجم المكدّس.
        text,
      ],
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

  /// رسم الشكل المتجهي في الـ PDF — بنفس هندسة المحرر ([shapeOutline])، وهو
  /// يغطّي التعبئة الصلبة والتدرّج والإطار المتقطّع والظل والقلب والدمج المنطقي.
  pw.Widget _shapeWidget(
    ShapeElement shape,
    TemplateDocument document,
    double width,
    double height,
    PdfDocument pdfDocument,
  ) {
    final double s = document.scale;
    final double w = width > 0 ? width : 1;
    final double h = height > 0
        ? height
        : (shape.kind == ShapeKind.line
            ? math.max(shape.strokeWidth, 1) * s
            : w);
    return pw.CustomPaint(
      size: PdfPoint(w, h),
      painter: (PdfGraphics canvas, PdfPoint _) =>
          _paintShape(canvas, w, h, shape, s, pdfDocument),
    );
  }

  /// يضبط شفافية التعبئة عبر **حالة الرسوم** (`ExtGState` · `/ca`).
  ///
  /// لا يمكن حمل الشفافية في لون الصبغة: `setFillColor` في حزمة `pdf` يكتب
  /// `r g b rg` وهي **بلا قناة ألفا إطلاقاً**؛ فتمرير ألفا داخل [PdfColor] كان
  /// يضيع صامتاً (ظل معتم، توهّج معتم، وتعبئة شبه شفافة تُطبع صلبة) — أي انزياح
  /// بصري كامل بين الشاشة والورقة. الـ`ExtGState` هو ما يعرفه كل قارئ PDF.
  ///
  /// [alpha] من 0 إلى 1، و`1` لا تحتاج أي حالة (تعبئة معتمة أصلية).
  void _applyFillAlpha(PdfGraphics canvas, double alpha) {
    final double value = alpha.clamp(0.0, 1.0);
    if (value >= 1) return;
    canvas.setGraphicState(PdfGraphicState(fillOpacity: value));
  }

  void _paintShape(
    PdfGraphics canvas,
    double w,
    double h,
    ShapeElement shape,
    double s,
    PdfDocument pdfDocument,
  ) {
    // الترتيب نفسه في اللوحة: توهّج خارجي ← ظل ← تعبئة/إطار.
    final GlowEffect? glow = shape.outerGlow;
    if (glow != null && glow.isVisible) {
      _paintShapeGlow(canvas, w, h, shape, s, glow);
    }
    final ShapeShadow? shadow = shape.shadow;
    if (shadow != null) _paintShapeShadow(canvas, w, h, shape, s, shadow);
    if (shape.gradient != null || shape.fillHex != null) {
      _paintShapeFill(canvas, w, h, shape, s, pdfDocument);
    }
    _paintShapeStroke(canvas, w, h, shape, s);
  }

  /// أوامر مسار جزء واحد من شكل مركّب (بإحداثيات محلية للشكل).
  List<ShapeCommand> _partCommands(ShapeElement part, double s) => shapeOutline(
        kind: part.kind,
        width: part.box.width * s,
        height: part.box.height * s,
        radius: part.radius * s,
        cornerRadii: part.cornerRadii == null
            ? null
            : <double>[for (final double r in part.cornerRadii!) r * s],
        points: part.points,
        innerRadius: part.innerRadius,
        rotationDeg: part.rotation,
      );

  /// كتابة أوامر مسار في لوحة الـ PDF مع تحويل نظام الإحداثيات (أعلى-يسار
  /// كما المحرر ← أسفل-يسار كما `PdfGraphics`) وتطبيق القلب/الإزاحة/التوسيع.
  void _emitCommands(
    PdfGraphics canvas,
    double w,
    double h,
    ShapeElement shape,
    List<ShapeCommand> commands, {
    double dx = 0,
    double dy = 0,
    double grow = 1,
  }) {
    final double cx = w / 2;
    final double cy = h / 2;
    double tx(double x) {
      final double v = cx + (x - cx) * grow + dx;
      return shape.flipH ? w - v : v;
    }

    double ty(double yTop) {
      final double v = cy + (yTop - cy) * grow + dy;
      final double flipped = shape.flipV ? h - v : v;
      return h - flipped;
    }

    for (final ShapeCommand command in commands) {
      switch (command) {
        case ShapeMove(:final double x, :final double y):
          canvas.moveTo(tx(x), ty(y));
        case ShapeLine(:final double x, :final double y):
          canvas.lineTo(tx(x), ty(y));
        case ShapeCubic(
            :final double x1,
            :final double y1,
            :final double x2,
            :final double y2,
            :final double x3,
            :final double y3,
          ):
          canvas.curveTo(tx(x1), ty(y1), tx(x2), ty(y2), tx(x3), ty(y3));
        case ShapeClose():
          canvas.closePath();
      }
    }
  }

  /// كتابة مسار الشكل كاملاً (شكل واحد أو كل أجزاء الشكل المركّب).
  void _emitShape(
    PdfGraphics canvas,
    double w,
    double h,
    ShapeElement shape,
    double s, {
    double dx = 0,
    double dy = 0,
    double grow = 1,
  }) {
    if (!shape.isCompound) {
      _emitCommands(
        canvas,
        w,
        h,
        shape,
        shapeOutline(
          kind: shape.kind,
          width: w,
          height: h,
          radius: shape.radius * s,
          cornerRadii: shape.cornerRadii == null
              ? null
              : <double>[for (final double r in shape.cornerRadii!) r * s],
          points: shape.points,
          innerRadius: shape.innerRadius,
        ),
        dx: dx,
        dy: dy,
        grow: grow,
      );
      return;
    }
    for (final ShapeElement part in shape.booleanParts) {
      _emitCommands(
        canvas,
        w,
        h,
        shape,
        _partCommands(part, s),
        dx: dx + part.box.x * s,
        dy: dy + part.box.y * s,
        grow: grow,
      );
    }
  }

  /// كتابة مسار جزء واحد فقط من شكل مركّب (بإحداثيات محلية للشكل).
  void _emitPart(
    PdfGraphics canvas,
    double w,
    double h,
    ShapeElement shape,
    ShapeElement part,
    double s,
  ) {
    _emitCommands(
      canvas,
      w,
      h,
      shape,
      _partCommands(part, s),
      dx: part.box.x * s,
      dy: part.box.y * s,
    );
  }

  void _paintShapeShadow(
    PdfGraphics canvas,
    double w,
    double h,
    ShapeElement shape,
    double s,
    ShapeShadow shadow,
  ) {
    final double grow = shadow.spread > 0
        ? 1 + (shadow.spread * s) / math.max(1, math.min(w, h))
        : 1;
    // شفافية الظل وحدها تُضرب في كثافة الطبقات الأساسية، فلا يتغيّر ظل قديم
    // (قيمته الافتراضية 1) ويتحكّم المنزلق الجديد في حدّته فعلاً.
    final double opacity = shadow.opacity.clamp(0, 1);
    // داخل `q`/`Q`: الشفافية حالة رسوم لا صبغة، فنعيدها إلى 1 بعد الظل كي لا
    // تُورَّث للتعبئة والإطار اللاحقين.
    canvas.saveContext();
    canvas.setFillColor(pdfColorFromHex(shadow.colorHex));
    _applyFillAlpha(canvas, (shadow.blurRadius > 0 ? 0.5 : 0.85) * opacity);
    _emitShape(
      canvas,
      w,
      h,
      shape,
      s,
      dx: shadow.offsetX * s,
      dy: shadow.offsetY * s,
      grow: grow,
    );
    canvas.fillPath();
    canvas.restoreContext();
  }

  /// توهّج خارجي للشكل: نسخة موسّعة من الشكل بلون التوهّج خلفه.
  ///
  /// ملفات PDF لا تعرف التمويه، فيُمثَّل النطاق بطبقتين موسّعتين (واحدة
  /// بمدى التوسيع والأخرى بنصف التمويه) بشفافية مخفّفة — تقريب بصري متّسق
  /// مع ما تراه العين على اللوحة.
  void _paintShapeGlow(
    PdfGraphics canvas,
    double w,
    double h,
    ShapeElement shape,
    double s,
    GlowEffect glow,
  ) {
    final double shortest = math.max(1, math.min(w, h));
    final double spread = math.max(0, glow.spread) * s;
    final double halo = math.max(0, glow.radius) * s * 0.5;
    final double opacity = glow.opacity.clamp(0, 1);

    canvas.saveContext();
    for (final (double growPx, double alpha) in <(double, double)>[
      (spread + halo, opacity * 0.35),
      (spread * 0.5, opacity * 0.55),
    ]) {
      if (growPx <= 0 || alpha <= 0) continue;
      canvas.setFillColor(pdfColorFromHex(glow.colorHex));
      _applyFillAlpha(canvas, alpha);
      _emitShape(
        canvas,
        w,
        h,
        shape,
        s,
        grow: 1 + (growPx * 2) / shortest,
      );
      canvas.fillPath();
    }
    canvas.restoreContext();
  }

  /// يُطبّق على لوحة الـ PDF قصّاً يعادل نتيجة العملية المنطقية للشكل المركّب.
  ///
  /// بديل `Path.combine` الذي لا يتوفّر داخل عزل الـ PDF (لا `dart:ui` هناك)،
  /// فيبقى بناء المسار بقصّين متتاليين: قصّ بالنتيجة ثم (عند الحاجة) قصّ
  /// بقاعدة الزوجي-الفردي لطرح التقاطع.
  void _clipBooleanResult(
    PdfGraphics canvas,
    double w,
    double h,
    ShapeElement shape,
    double s,
  ) {
    final List<ShapeElement> parts = shape.booleanParts;
    switch (shape.booleanOp!) {
      case ShapeBooleanOp.union:
        _emitShape(canvas, w, h, shape, s);
        canvas.clipPath();
      case ShapeBooleanOp.subtract:
        // قصّ الشكل السفلي ثم اقتطاع الجزء المتقاطع بقاعدة الزوجي-الفردي.
        _emitPart(canvas, w, h, shape, parts.first, s);
        canvas.clipPath();
        _emitShape(canvas, w, h, shape, s);
        canvas.clipPath(evenOdd: true);
      case ShapeBooleanOp.intersect:
        for (final ShapeElement part in parts) {
          _emitPart(canvas, w, h, shape, part, s);
          canvas.clipPath();
        }
      case ShapeBooleanOp.exclude:
        // (A ∪ B) − (A ∩ B): الدمج كاملاً ثم طرح منطقة التقاطع.
        _emitShape(canvas, w, h, shape, s);
        canvas.clipPath();
        _emitShape(canvas, w, h, shape, s);
        canvas.clipPath(evenOdd: true);
    }
  }

  void _paintShapeFill(
    PdfGraphics canvas,
    double w,
    double h,
    ShapeElement shape,
    double s,
    PdfDocument pdfDocument,
  ) {
    canvas.saveContext();
    if (!shape.isCompound) {
      _emitShape(canvas, w, h, shape, s);
      canvas.clipPath();
    } else {
      _clipBooleanResult(canvas, w, h, shape, s);
    }

    // الشفافية أولاً عبر حالة الرسوم: تُطبَّق على التدرّج والصبغة معاً، ولا
    // تعتمد على قناة ألفا في اللون (التي تُهملها الحزمة في مسار التظليل).
    _applyFillAlpha(canvas, shape.fillOpacity);

    final ShapeGradient? gradient = shape.gradient;
    if (gradient != null) {
      // سلّم كثيف مُشوَّش داخل دالة تنعيم واحدة: تدرّج متجه عالي الدقة بلا
      // خطوط تكميم ولا صورة رسترة (وبالتالي بلا حاجة لضغط صور ولا مواريه).
      final PdfBaseFunction fn = PdfFunction.fromColors(
        pdfDocument,
        pdfGradientRamp(
          pdfColorFromHex(gradient.startHex),
          pdfColorFromHex(gradient.endHex),
        ),
      );
      final PdfRect bounds = PdfRect.fromLBRT(0, 0, w, h);
      if (gradient.kind == ShapeFillKind.radialGradient) {
        canvas.applyShader(PdfShading(
          pdfDocument,
          shadingType: PdfShadingType.radial,
          boundingBox: bounds,
          function: fn,
          start: PdfPoint(w / 2, h / 2),
          end: PdfPoint(w / 2, h / 2),
          radius0: 0,
          radius1: math.sqrt(w * w + h * h) / 2,
          extendStart: true,
          extendEnd: true,
        ));
      } else {
        final ({double sx, double sy, double ex, double ey}) axis =
            gradientAxis(w, h, gradient.angle);
        canvas.applyShader(PdfShading(
          pdfDocument,
          shadingType: PdfShadingType.axial,
          boundingBox: bounds,
          function: fn,
          start: PdfPoint(axis.sx, h - axis.sy),
          end: PdfPoint(axis.ex, h - axis.ey),
          extendStart: true,
          extendEnd: true,
        ));
      }
    } else {
      canvas.setFillColor(pdfColorFromHex(shape.fillHex));
      canvas.drawRect(0, 0, w, h);
      canvas.fillPath();
    }
    canvas.restoreContext();
  }

  void _paintShapeStroke(
    PdfGraphics canvas,
    double w,
    double h,
    ShapeElement shape,
    double s,
  ) {
    final String? strokeHex = shape.strokeHex;
    if (strokeHex == null || shape.strokeWidth <= 0) return;
    canvas
      ..setStrokeColor(pdfColorFromHex(strokeHex))
      ..setLineWidth(shape.strokeWidth * s)
      ..setLineJoin(PdfLineJoin.round)
      ..setLineCap(PdfLineCap.round);
    final List<double>? dash = shape.dashPattern;
    if (dash != null && dash.isNotEmpty) {
      canvas.setLineDashPattern(
        <num>[for (final double d in dash) d * s],
      );
    }
    // الإطار يُقصّ أيضاً على نتيجة العملية المنطقية (على اللوحة يُبنى المسار
    // المدمَج بـ `Path.combine`، وهنا نقصّه بدلاً من ذلك) فلا تتسرّب حدود
    // الأجزاء إلى خارج النتيجة.
    if (shape.isCompound) canvas.saveContext();
    if (shape.isCompound) _clipBooleanResult(canvas, w, h, shape, s);
    _emitShape(canvas, w, h, shape, s);
    canvas.strokePath();
    if (shape.isCompound) canvas.restoreContext();
    if (dash != null && dash.isNotEmpty) {
      canvas.setLineDashPattern(<num>[]);
    }
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
