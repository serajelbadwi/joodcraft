import 'package:flutter/foundation.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/template_document.dart';
import 'offscreen_widget_renderer.dart';
import 'pdf_render_engine.dart';

/// Builds a PDF where each page is a single, high-fidelity rasterized image
/// of the [TemplateDocument], ensuring 100% parity with the editor visual.
class RasterizedPdfBuilder {
  static Future<Uint8List> build({
    required TemplateDocument document,
    required List<Map<String, String>> rows,
    PdfDocumentMetadata? metadata,
    bool compress = true,
    void Function(int done, int total)? onProgress,
  }) async {
    // ====================================================================
    // Phase 1: Render each row to a PNG image on the main thread
    //          (requires Flutter's rendering pipeline)
    // ====================================================================
    final List<Uint8List> pageImages = <Uint8List>[];
    int done = 0;
    for (final Map<String, String> row in rows) {
      try {
        debugPrint('🚀 [RasterizedPdfBuilder] Rendering row $done...');
        final Uint8List imageBytes =
            await OffscreenWidgetRenderer.renderDocumentToImageBytes(
          document,
          rowData: row,
        );
        pageImages.add(imageBytes);
        done++;
        debugPrint('🚀 [RasterizedPdfBuilder] Row $done rendered (${imageBytes.lengthInBytes} bytes).');
        onProgress?.call(done, rows.length);
      } catch (e, stackTrace) {
        debugPrint('❌ PDF Render Error [RasterizedPdfBuilder]: $e');
        debugPrint('📍 StackTrace: $stackTrace');
        rethrow;
      }
    }

    // ====================================================================
    // Phase 2: Assemble & compress the PDF in a background isolate
    //          (keeps UI 100% responsive during heavy byte work)
    // ====================================================================
    debugPrint('📦 [RasterizedPdfBuilder] جاري تجميع وحفظ ملف الـ PDF النهائي...');
    onProgress?.call(rows.length, rows.length); // signal: entering save phase

    final Uint8List pdfBytes = await compute(
      _assemblePdf,
      _PdfAssemblyRequest(
        pageImages: pageImages,
        pageWidthPt: document.pageWidthPt,
        pageHeightPt: document.pageHeightPt,
        compress: compress,
        title: metadata?.title,
        author: metadata?.author,
        subject: metadata?.subject,
        keywords: metadata?.keywords,
        creator: metadata?.creator ?? 'JoodCraft Raster Engine',
      ),
    );

    debugPrint('✅ [RasterizedPdfBuilder] PDF saved (${(pdfBytes.lengthInBytes / 1024 / 1024).toStringAsFixed(1)} MB).');
    return pdfBytes;
  }
}

// ============================================================================
//  Isolate-safe data & entry point (no Flutter / dart:ui dependencies)
// ============================================================================

/// Serializable request sent to the background isolate.
class _PdfAssemblyRequest {
  const _PdfAssemblyRequest({
    required this.pageImages,
    required this.pageWidthPt,
    required this.pageHeightPt,
    required this.compress,
    this.title,
    this.author,
    this.subject,
    this.keywords,
    this.creator,
  });

  final List<Uint8List> pageImages;
  final double pageWidthPt;
  final double pageHeightPt;
  final bool compress;
  final String? title;
  final String? author;
  final String? subject;
  final String? keywords;
  final String? creator;
}

/// Top-level function executed inside a background isolate.
/// Assembles the PDF from pre-rendered PNG page images and returns
/// the final compressed bytes.
Future<Uint8List> _assemblePdf(_PdfAssemblyRequest request) async {
  final pw.Document pdf = pw.Document(
    title: request.title,
    author: request.author,
    subject: request.subject,
    keywords: request.keywords,
    creator: request.creator ?? 'JoodCraft Raster Engine',
    producer: 'JoodCraft (High-Fidelity)',
    compress: request.compress,
  );

  final PdfPageFormat format = PdfPageFormat(
    request.pageWidthPt,
    request.pageHeightPt,
    marginAll: 0,
  );

  for (final Uint8List imageBytes in request.pageImages) {
    final pw.MemoryImage memoryImage = pw.MemoryImage(imageBytes);
    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          return pw.FullPage(
            ignoreMargins: true,
            child: pw.Image(memoryImage, fit: pw.BoxFit.cover),
          );
        },
      ),
    );
  }

  return await pdf.save();
}
