import 'package:pdf/pdf.dart';

/// **البوابة الوحيدة** للألوان في محرّك التصدير: من قناة `ARGB` صريحة إلى
/// [PdfColor] مباشرة عبر `PdfColor.fromInt` — وهو يقسم كل قناة على ‎255‎ فقط
/// ويكتبها في المُشغّل كـ`r g b rg`.
///
/// **لا ملف تعريف طباعة، ولا تحويل CMYK ضمني، ولا إسقاط للقنوات**: قيم الـ
/// RGB الحقيقية (البيج والكحلي) تصل إلى الـ PDF كما هي مليمتراً بمليمتر مع
/// شاشة المحرّر. لا تستخدم أي دالة أخرى لتوليد الألوان في محرّك الـ PDF.
PdfColor pdfColorFromArgb(int argb) => PdfColor.fromInt(argb);

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

/// قناة الشفافية من HEX نصيّ بصيغة `#AARRGGBB` (أو `AARRGGBB`).
///
/// تُعيد `1.0` لكل لون بلا قناة ألفا (‎`#RRGGBB`‎) — وهو الوضع الافتراضي في
/// كل قوالب JoodCraft. أما اللون الثمانيّ فيُفقد منه الألفا لو مرّ عبر
/// [pdfColorFromHex] وحده (لأن `setFillColor` يكتب `rg` بلا قناة ألفا)، فلا بدّ
/// من استخراجه هنا وتطبيقه عبر الشفافية/`ExtGState`.
///
/// مثال: `#80FF0000` ⇒ `128 / 255 ≈ 0.502`.
double pdfAlphaFromHex(String? hex) {
  if (hex == null) return 1;
  String value = hex.trim();
  if (value.startsWith('#')) value = value.substring(1);
  if (value.length != 8) return 1;
  final int? parsed = int.tryParse(value, radix: 16);
  if (parsed == null) return 1;
  return ((parsed >> 24) & 0xFF) / 255;
}
