import 'package:pdf/pdf.dart';

import '../models/decoration.dart';
import 'pdf_color.dart';

/// يرسم مسارات [VectorDecor] على لوحة `PdfGraphics` في الـ PDF.
///
/// الإحداثيات تأتي بنظام **أعلى-يسار** (كما المحرر)، بينما أصل `PdfGraphics`
/// أسفل-يسار ⇒ نقلب الرأسي بـ `height - y` كما في رسم الختم، فيتطابق المعاينة
/// والطباعة تماماً.
void paintVectorDecor(
  PdfGraphics canvas,
  DecorSpec spec,
  double width,
  double height,
) {
  for (final DecorPath path in VectorDecor.build(spec, width, height)) {
    final PdfColor color = pdfColorFromHex(path.colorHex);
    if (path.stroke) {
      canvas
        ..setStrokeColor(color)
        ..setLineWidth(path.strokeWidth > 0 ? path.strokeWidth : 1);
    } else {
      canvas.setFillColor(color);
    }

    bool started = false;
    for (final DecorSegment segment in path.segments) {
      switch (segment) {
        case DecorMove(:final double x, :final double y):
          canvas.moveTo(x, height - y);
          started = true;
        case DecorLine(:final double x, :final double y):
          canvas.lineTo(x, height - y);
        case DecorCubic(
            :final double x1,
            :final double y1,
            :final double x2,
            :final double y2,
            :final double x,
            :final double y,
          ):
          canvas.curveTo(x1, height - y1, x2, height - y2, x, height - y);
      }
    }
    if (!started) continue;

    if (path.closed) canvas.closePath();
    if (path.stroke) {
      canvas.strokePath();
    } else {
      canvas.fillPath();
    }
  }
}
