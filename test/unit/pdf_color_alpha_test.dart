import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/pdf/pdf_color.dart';
import 'package:pdf/pdf.dart';

/// تحويل الألوان: RGB دقيق بلا تحويل CMYK، مع استخراج قناة الألفا من صيغة
/// `#AARRGGBB` كي لا تُفقد صامتةً في `setFillColor` (الذي يكتب `rg` بلا ألفا).
void main() {
  group('pdfColorFromHex', () {
    test('الصيغة الستية تُترجم إلى RGB كامل بلا تحويل لوني', () {
      final PdfColor navy = pdfColorFromHex('#1B2A4A');
      expect(navy.red, closeTo(0x1B / 255, 1e-9));
      expect(navy.green, closeTo(0x2A / 255, 1e-9));
      expect(navy.blue, closeTo(0x4A / 255, 1e-9));
    });

    test('تتجاهل قناة الألفا وتُرجع RFC (الألفا تُدار عبر الشفافية لا اللون)', () {
      final PdfColor color = pdfColorFromHex('#80FF0000');
      expect(color.red, closeTo(1, 1e-9));
      expect(color.green, closeTo(0, 1e-9));
      expect(color.blue, closeTo(0, 1e-9));
    });

    test('الصيغة غير الصالحة ترجع اللون الاحتياطي', () {
      final PdfColor fallback = pdfColorFromHex('nope');
      expect(fallback.red, 0);
      expect(fallback.green, 0);
      expect(fallback.blue, 0);
    });
  });

  group('pdfAlphaFromHex', () {
    test('الألوان الستية بلا ألفا ⇒ شفافية تامة 1.0', () {
      expect(pdfAlphaFromHex('#1B2A4A'), 1);
      expect(pdfAlphaFromHex('1B2A4A'), 1);
      expect(pdfAlphaFromHex(null), 1);
    });

    test('الصيغة الثمانية تُستخرج ألفاها بالضبط', () {
      expect(pdfAlphaFromHex('#80FF0000'), closeTo(128 / 255, 1e-9));
      expect(pdfAlphaFromHex('#00FF0000'), 0);
      expect(pdfAlphaFromHex('#FFFF0000'), 1);
    });

    test('صيغة غير صالحة لا تكسر التصدير (ترجع 1.0)', () {
      expect(pdfAlphaFromHex('#ZZZ'), 1);
      expect(pdfAlphaFromHex(''), 1);
    });
  });
}
