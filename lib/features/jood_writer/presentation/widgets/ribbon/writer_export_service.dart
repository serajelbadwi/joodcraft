/// تصدير مستند «جود كاتب»: PDF، PNG، DOCX، HTML، وطباعة — خط أنابيب حقيقي
/// يقرأ نموذج المستند مباشرة (كتل + إعدادات صفحة) بلا وسيط.
///
/// * **PDF/طباعة**: حزمة `pdf` بخط Cairo العربي (يُحمَّل من الأصول)، وصفحة
///   لكل صفحة من صفحات المستند التقديرية، والنصّ باتجاه RTL.
/// * **PNG**: تمويه الصفحة الأولى من الـPDF عبر `Printing.raster`.
/// * **DOCX**: ملف OOXML مبسّط (‎document.xml + ‎[Content_Types]‎ + ‎rels‎)
///   مبني بحزمة `archive`.
/// * **HTML**: مستند HTML بأنماط inline — يفتح في أي متصفّح.
///
/// الحفظ يمرّ بـ`FilePicker.saveFile` حين توفّر المنصّة (ويندوز/ويب يُنزّل
/// الملف) ويسقط إلى مجلد مؤقت مع إظهار المسار إن تعذّر.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../domain/jood_writer_block.dart';
import '../../../domain/jood_writer_document.dart';
import 'writer_file_writer_stub.dart'
    if (dart.library.io) 'writer_file_writer_io.dart' as fw;

abstract final class WriterExportService {
  // ==========================================================================
  //  PDF
  // ==========================================================================

  /// بناء بايتات PDF من المستند — متاحة للاختبارات بلا حوار حفظ.
  static Future<Uint8List> buildPdfBytes(JoodWriterDocument doc) async {
    final pw.Font regular = pw.Font.ttf(
      await rootBundle.load(AppAssets.pdfCairoRegular),
    );
    final pw.Font bold = pw.Font.ttf(
      await rootBundle.load(AppAssets.pdfCairoBold),
    );
    final pw.ThemeData theme = pw.ThemeData.withFont(
      base: regular,
      bold: bold,
      fontFallback: <pw.Font>[regular],
    );

    final JoodWriterPageSize page = doc.effectivePageSize;
    final PdfPageFormat format = PdfPageFormat(
      page.widthMm,
      page.heightMm,
      marginTop: doc.margins.top,
      marginBottom: doc.margins.bottom,
      marginLeft: doc.margins.left,
      marginRight: doc.margins.right,
    );

    final pw.Document pdf = pw.Document(theme: theme);
    // تقدير بسيط لعدد الصفحات: ٤٠ سطراً لكل صفحة (حجم ١٣.٥).
    const int linesPerPage = 40;
    final List<List<JoodWriterBlock>> pages = <List<JoodWriterBlock>>[];
    List<JoodWriterBlock> current = <JoodWriterBlock>[];
    int lines = 0;
    for (final JoodWriterBlock block in doc.blocks) {
      final int blockLines =
          (block.text.length / 70).ceil().clamp(1, 20) +
          (block.pageBreakBefore ? linesPerPage : 0);
      if (lines + blockLines > linesPerPage || block.pageBreakBefore) {
        pages.add(current);
        current = <JoodWriterBlock>[];
        lines = 0;
      }
      current.add(block);
      lines += blockLines;
    }
    pages.add(current);

    for (int i = 0; i < pages.length; i++) {
      pdf.addPage(
        pw.Page(
          pageFormat: format,
          textDirection: pw.TextDirection.rtl,
          build: (pw.Context context) {
            final List<pw.Widget> children = <pw.Widget>[];
            for (final JoodWriterBlock block in pages[i]) {
              final double size = block.fontSize ??
                  (block.kind == JoodWriterBlockKind.heading1
                      ? 22
                      : block.kind == JoodWriterBlockKind.heading2
                      ? 17
                      : 13.5);
              children.add(
                pw.Padding(
                  padding: pw.EdgeInsets.only(
                    top: block.spaceBefore,
                    bottom: block.spaceAfter,
                    right: block.indentCm * 10,
                  ),
                  child: pw.Text(
                    (block.kind == JoodWriterBlockKind.bullet
                        ? '• ${block.text}'
                        : block.kind == JoodWriterBlockKind.numbered
                        ? '${i + 1}. ${block.text}'
                        : block.text),
                    style: pw.TextStyle(
                      font: block.isBold ? bold : regular,
                      fontSize: size,
                      fontStyle: block.isItalic
                          ? pw.FontStyle.italic
                          : pw.FontStyle.normal,
                      decoration: block.isUnderline
                          ? pw.TextDecoration.underline
                          : block.isStrikethrough
                          ? pw.TextDecoration.lineThrough
                          : pw.TextDecoration.none,
                      height: block.lineSpacing,
                      color: PdfColor.fromInt(
                        block.fontColor?.toARGB32() ?? 0xFF000000,
                      ),
                    ),
                    textAlign: switch (block.align) {
                      JoodWriterAlign.center => pw.TextAlign.center,
                      JoodWriterAlign.end => pw.TextAlign.left,
                      JoodWriterAlign.justify => pw.TextAlign.justify,
                      JoodWriterAlign.start => pw.TextAlign.right,
                    },
                  ),
                ),
              );
            }
            return pw.Stack(
              children: <pw.Widget>[
                if (doc.watermark != null && doc.watermark!.isNotEmpty)
                  pw.Center(
                    child: pw.Transform.rotate(
                      angle: -0.5,
                      child: pw.Opacity(
                        opacity: 0.12,
                        child: pw.Text(
                          doc.watermark!,
                          style: pw.TextStyle(font: bold, fontSize: 60),
                        ),
                      ),
                    ),
                  ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: children,
                ),
              ],
            );
          },
        ),
      );
    }
    return pdf.save();
  }

  /// تصدير PDF ومشاركته/حفظه.
  static Future<void> exportPdf(
    BuildContext context,
    JoodWriterDocument doc,
  ) async {
    final Uint8List bytes = await buildPdfBytes(doc);
    final bool shared = await Printing.sharePdf(
      bytes: bytes,
      filename: '${doc.title}.pdf',
    );
    if (!shared && context.mounted) {
      await _saveWithPicker(context, '${doc.title}.pdf', bytes);
    }
  }

  /// طباعة مباشرة عبر طابعة النظام.
  static Future<void> printDocument(JoodWriterDocument doc) async {
    final Uint8List bytes = await buildPdfBytes(doc);
    await Printing.layoutPdf(onLayout: (PdfPageFormat _) async => bytes);
  }

  /// تصدير الصفحة الأولى كصورة PNG بدقة ١٥٠ نقطة/بوصة.
  static Future<void> exportPng(
    BuildContext context,
    JoodWriterDocument doc,
  ) async {
    final Uint8List pdfBytes = await buildPdfBytes(doc);
    await for (final r in Printing.raster(pdfBytes, dpi: 150)) {
      // الصفحة الأولى فقط — باقي الصفحات متتالية لو اتسعت الخدمة لاحقاً.
      final Uint8List png = await r.toPng();
      if (!context.mounted) return;
      await _saveWithPicker(context, '${doc.title}.png', png);
      return;
    }
  }

  // ==========================================================================
  //  DOCX
  // ==========================================================================

  /// ملف DOCX مبسّط: ‎[Content_Types].xml‎ + ‎_rels/.rels‎ + ‎word/document.xml‎
  /// بنصّ كتل بتنسيق أساسي (عريض/مائل/حجم/محاذاة).
  static Uint8List buildDocxBytes(JoodWriterDocument doc) {
    final StringBuffer body = StringBuffer();
    for (final JoodWriterBlock block in doc.blocks) {
      final String align = switch (block.align) {
        JoodWriterAlign.center => 'center',
        JoodWriterAlign.end => 'left',
        JoodWriterAlign.justify => 'both',
        JoodWriterAlign.start => 'right',
      };
      final String style = <String>[
        if (block.isBold) 'w:b',
        if (block.isItalic) 'w:i',
        if (block.isUnderline) 'w:u',
        if (block.isStrikethrough) 'w:strike',
      ].map((String s) => '<$s/>').join();
      final String heading = block.kind == JoodWriterBlockKind.heading1
          ? '<w:pStyle w:val="Heading1"/>'
          : block.kind == JoodWriterBlockKind.heading2
          ? '<w:pStyle w:val="Heading2"/>'
          : '';
      body.write(
        '<w:p><w:pPr>$heading<w:jc w:val="$align"/></w:pPr>'
        '<w:r><w:rPr>$style'
        '<w:sz w:val="${((block.fontSize ?? 13.5) * 2).round()}"/>'
        '</w:rPr><w:t xml:space="preserve">${_xmlEscape(block.text)}</w:t></w:r></w:p>',
      );
    }

    const String contentTypes =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
        '</Types>';
    const String rels =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
        '</Relationships>';
    final String document =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
        '<w:body>${body.toString()}<w:sectPr/></w:body></w:document>';

    final Archive archive = Archive()
      ..addFile(ArchiveFile('[Content_Types].xml', contentTypes.length, contentTypes.codeUnits))
      ..addFile(ArchiveFile('_rels/.rels', rels.length, rels.codeUnits))
      ..addFile(ArchiveFile('word/document.xml', document.length, utf8.encode(document)));
    return Uint8List.fromList(ZipEncoder().encode(archive)!);
  }

  static String _xmlEscape(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  static Future<void> exportDocx(
    BuildContext context,
    JoodWriterDocument doc,
  ) async {
    final Uint8List bytes = buildDocxBytes(doc);
    await _saveWithPicker(context, '${doc.title}.docx', bytes);
  }

  // ==========================================================================
  //  HTML
  // ==========================================================================

  static Uint8List buildHtmlBytes(JoodWriterDocument doc) {
    final StringBuffer body = StringBuffer();
    for (final JoodWriterBlock block in doc.blocks) {
      final String tag = block.kind == JoodWriterBlockKind.heading1
          ? 'h1'
          : block.kind == JoodWriterBlockKind.heading2
          ? 'h2'
          : 'p';
      final String align = switch (block.align) {
        JoodWriterAlign.center => 'center',
        JoodWriterAlign.end => 'left',
        JoodWriterAlign.justify => 'justify',
        JoodWriterAlign.start => 'right',
      };
      final String decorations = <String>[
        if (block.isUnderline) 'underline',
        if (block.isStrikethrough) 'line-through',
      ].join(' ');
      final String css = <String>[
        'text-align:$align',
        if (block.fontFamily != null) 'font-family:${block.fontFamily}',
        if (block.fontSize != null) 'font-size:${block.fontSize}px',
        if (block.fontColor != null)
          'color:#${block.fontColor!.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
        if (block.isBold) 'font-weight:bold',
        if (block.isItalic) 'font-style:italic',
        if (decorations.isNotEmpty) 'text-decoration:$decorations',
        if (block.highlightColor != null)
          'background-color:#${block.highlightColor!.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
        'line-height:${block.lineSpacing}',
        'margin-top:${block.spaceBefore}px',
        'margin-bottom:${block.spaceAfter}px',
        'padding-right:${block.indentCm * 10}px',
      ].join(';');
      final String content = block.kind == JoodWriterBlockKind.bullet
          ? '• ${_htmlEscape(block.text)}'
          : _htmlEscape(block.text);
      body.write('<$tag dir="rtl" style="$css">$content</$tag>\n');
    }
    return Uint8List.fromList(
      utf8.encode(
        '<!DOCTYPE html><html dir="rtl" lang="ar"><head>'
        '<meta charset="utf-8"><title>${_htmlEscape(doc.title)}</title>'
        '</head><body style="font-family:Cairo,Tahoma,sans-serif;max-width:800px;margin:24px auto">'
        '$body</body></html>',
      ),
    );
  }

  static String _htmlEscape(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  static Future<void> exportHtml(
    BuildContext context,
    JoodWriterDocument doc,
  ) async {
    await _saveWithPicker(context, '${doc.title}.html', buildHtmlBytes(doc));
  }

  // ==========================================================================
  //  الحفظ
  // ==========================================================================

  /// حوار «حفظ باسم» متعدد المنصّات بواجهة file_picker 13:
  /// * `FilePicker.saveFile(bytes:)` نفسه يتولّى الكتابة/التنزيل على كل
  ///   المنصّات المدعومة ويعيد URI للملف المحفوظ (`null` = إلغاء).
  /// * إن فشل حوار المنصّة تماماً: نسقط إلى المجلد المؤقت ونُظهر المسار.
  static Future<void> _saveWithPicker(
    BuildContext context,
    String name,
    Uint8List bytes,
  ) async {
    try {
      final Uri? saved = await FilePicker.saveFile(
        dialogTitle: name,
        fileName: name,
        bytes: bytes,
        mimeType: _mimeTypeFor(name),
      );
      if (saved == null) return; // أُلغي الحفظ (أو فشل حوار المنصّة بهدوء).
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حفظ: ${saved.path}')),
        );
      }
      return;
    } catch (_) {
      // المنصّة لا تدعم الحوار — نسقط إلى المجلد المؤقت.
    }
    if (kIsWeb) return;
    try {
      final dir = await getTemporaryDirectory();
      final String fallback = '${dir.path}/$name';
      await fw.writeFileTo(fallback, bytes);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم الحفظ في: $fallback')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذّر حفظ الملف: $name')),
        );
      }
    }
  }

  /// نوع MIME للصيغ الشائعة المستخدمة في التصدير.
  static String _mimeTypeFor(String name) {
    final String ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      'html' => 'text/html',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      _ => 'application/octet-stream',
    };
  }
}
