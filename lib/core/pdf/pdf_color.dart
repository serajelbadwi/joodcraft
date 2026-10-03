import 'package:pdf/pdf.dart';

/// تحويل لون HEX نصي (كما في قوالب JSON) إلى [PdfColor].
///
/// الصيغ المقبولة: `#RRGGBB` و`RRGGBB` و`#AARRGGBB` (يُتجاهل قناة الشفافية
/// لأنها تُدار عبر خاصية `opacity` لكل عنصر).
PdfColor pdfColorFromHex(String? hex, {PdfColor fallback = PdfColors.black}) {
  if (hex == null) return fallback;
  String value = hex.trim();
  if (value.startsWith('#')) value = value.substring(1);
  if (value.length == 8) {
    // AARRGGBB — نتجاهل قناة الألفا ونستخدم RGB.
    value = value.substring(2);
  }
  if (value.length != 6) return fallback;
  final int? parsed = int.tryParse(value, radix: 16);
  if (parsed == null) return fallback;
  return PdfColor.fromInt(parsed | 0xFF000000);
}
