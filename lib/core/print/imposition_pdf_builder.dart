import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../errors/app_error_code.dart';
import '../errors/app_exception.dart';
import '../models/template_document.dart';
import '../pdf/offscreen_widget_renderer.dart';
import '../pdf/pdf_font_catalog.dart';
import '../pdf/pdf_render_engine.dart';
import 'crop_marks.dart';
import 'imposition_calculator.dart';

/// مخرج بناء ملف التجميع.
class ImpositionPdfArtifact {
  const ImpositionPdfArtifact({
    required this.bytes,
    required this.sheetCount,
    required this.layout,
    required this.itemCount,
  });

  /// بايتات ملف الـ PDF الجاهز.
  final Uint8List bytes;

  /// عدد أوراق الطباعة المُخرَجة.
  final int sheetCount;

  /// شبكة الحصر المستخدمة.
  final ImpositionResult layout;

  /// إجمالي عدد القطع الموزّعة على الأوراق.
  final int itemCount;
}

/// محرّك بناء **ورقة التجميع** (Imposition Sheet) كملف PDF عالي الدقة.
abstract final class ImpositionPdfBuilder {
  const ImpositionPdfBuilder._();

  /// دقّة تحليل الصور المضمّنة داخل ورقة التجميع (نقطة/بوصة).
  static const double exportDpi = 300;

  /// **تجميع مفرد**: قطعة واحدة مكرّرة [copies] مرة على أوراق التجميع.
  static Future<ImpositionPdfArtifact> buildSingle({
    required PdfFontSet fonts,
    required TemplateDocument document,
    required ImpositionSpec spec,
    required Map<String, pw.ImageProvider?> images,
    int copies = 1,
    Map<String, String> data = const <String, String>{},
    PdfDocumentMetadata? metadata,
    bool compress = true,
    bool printCropMarks = true,
    void Function(int done, int total)? onProgress,
  }) =>
      build(
        fonts: fonts,
        document: document,
        spec: spec,
        images: images,
        items: List<Map<String, String>>.filled(
          math.max(1, copies),
          data,
          growable: false,
        ),
        metadata: metadata,
        compress: compress,
        printCropMarks: printCropMarks,
        onProgress: onProgress,
      );

  /// **تجميع جماعي**: كل صف قطعة مختلفة، توزَّع عبر أوراق متتالية.
  static Future<ImpositionPdfArtifact> buildBulk({
    required PdfFontSet fonts,
    required TemplateDocument document,
    required ImpositionSpec spec,
    required Map<String, pw.ImageProvider?> images,
    required List<Map<String, String>> rows,
    PdfDocumentMetadata? metadata,
    bool compress = true,
    bool printCropMarks = true,
    void Function(int done, int total)? onProgress,
  }) =>
      build(
        fonts: fonts,
        document: document,
        spec: spec,
        images: images,
        items: rows,
        metadata: metadata,
        compress: compress,
        printCropMarks: printCropMarks,
        onProgress: onProgress,
      );

  static Future<ImpositionPdfArtifact> build({
    required PdfFontSet fonts,
    required TemplateDocument document,
    required ImpositionSpec spec,
    required Map<String, pw.ImageProvider?> images,
    required List<Map<String, String>> items,
    PdfDocumentMetadata? metadata,
    bool compress = true,
    bool printCropMarks = true,
    void Function(int done, int total)? onProgress,
  }) async {
    if (items.isEmpty) {
      throw const AppException(
        AppErrorCode.pdfGeneration,
        message: 'لا توجد قطع لتجميعها على الورقة.',
      );
    }

    final ImpositionResult layout = spec.layout();
    if (layout.count == 0) {
      throw AppException(
        AppErrorCode.pdfGeneration,
        message: 'لا تتسع الورقة (${spec.sheet.labelAr}) لقطعة '
            '${spec.itemWidthMm}×${spec.itemHeightMm} ملم بهذه الهوامش.',
      );
    }

    final int perSheet = layout.count;
    final int sheetCount = (items.length + perSheet - 1) ~/ perSheet;

    final pw.Document pdf = pw.Document(
      title: metadata?.title ?? 'JoodCraft Imposition',
      author: metadata?.author,
      subject: metadata?.subject,
      keywords: metadata?.keywords,
      creator: metadata?.creator ?? 'JoodCraft Raster Imposition',
      producer: 'JoodCraft (High-Fidelity)',
      compress: compress,
    );

    final PdfPageFormat sheetFormat = PdfPageFormat(
      mmToPt(layout.sheetWidthMm),
      mmToPt(layout.sheetHeightMm),
      marginAll: 0,
    );

    // 1. توليد صور القطع برسم بدقة 300 DPI لضمان المطابقة 100%
    final List<pw.MemoryImage> itemImages = <pw.MemoryImage>[];
    for (int i = 0; i < items.length; i++) {
      final Uint8List imageBytes = await OffscreenWidgetRenderer.renderDocumentToImageBytes(
        document,
        rowData: items[i],
        pixelRatio: document.dpi / 72.0,
      );
      itemImages.add(pw.MemoryImage(imageBytes));
    }

    for (int sheet = 0; sheet < sheetCount; sheet++) {
      final int start = sheet * perSheet;
      final int end = math.min(start + perSheet, items.length);

      final List<pw.Widget> markWidgets = printCropMarks
          ? cropMarksForSheet(layout, style: spec.markStyle)
              .map((CropMarkLine line) => _markWidget(line, spec.markStyle))
              .toList(growable: false)
          : const <pw.Widget>[];

      pdf.addPage(
        pw.Page(
          pageFormat: sheetFormat,
          build: (pw.Context context) {
            return pw.Stack(
              children: <pw.Widget>[
                pw.Positioned.fill(
                  child: pw.Container(color: PdfColors.white),
                ),
                for (int i = start; i < end; i++)
                  _itemWidget(
                    itemImage: itemImages[i],
                    placement: layout.placements[i - start],
                  ),
                ...markWidgets,
              ],
            );
          },
        ),
      );
      onProgress?.call(sheet + 1, sheetCount);
    }

    return ImpositionPdfArtifact(
      bytes: await pdf.save(),
      sheetCount: sheetCount,
      layout: layout,
      itemCount: items.length,
    );
  }

  static pw.Widget _itemWidget({
    required pw.MemoryImage itemImage,
    required ImpositionPlacement placement,
  }) {
    return pw.Positioned(
      left: mmToPt(placement.leftMm),
      top: mmToPt(placement.topMm),
      child: pw.SizedBox(
        width: mmToPt(placement.widthMm),
        height: mmToPt(placement.heightMm),
        child: pw.Image(itemImage, fit: pw.BoxFit.cover),
      ),
    );
  }

  static pw.Widget _markWidget(CropMarkLine line, CropMarkStyle style) {
    final double thickness = math.max(style.thicknessMm, 0.05);
    final double left = line.isHorizontal ? line.x1 : line.x1 - thickness / 2;
    final double top = line.isHorizontal ? line.y1 - thickness / 2 : line.y1;
    final double width = line.isHorizontal ? line.lengthMm : thickness;
    final double height = line.isHorizontal ? thickness : line.lengthMm;

    return pw.Positioned(
      left: mmToPt(left),
      top: mmToPt(top),
      child: pw.SizedBox(
        width: mmToPt(width),
        height: mmToPt(height),
        child: pw.Container(color: _pdfColorOf(style.color)),
      ),
    );
  }

  static PdfColor _pdfColorOf(Color color) =>
      PdfColor.fromInt(color.toARGB32());
}
