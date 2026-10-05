import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/errors/app_exception.dart';
import 'package:joodcraft/core/pdf/custom_pdf_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// حرس تصغير الخطوط في الـ PDF.
///
/// يثبت أن الخط المضمّن يُقصّ على **المحارف المستخدمة في المستند** فقط (بدل
/// تضمين ملف الخط كاملاً فيتضخّم التصدير)، وأن الخطوط غير القابلة للقصّ
/// (‎OTTO/CFF أو مجموعات ttc) تُرفض بدل تضمينها كاملة.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Uint8List> cairoBytes() async =>
      (await rootBundle.load(AppAssets.pdfCairoRegular)).buffer.asUint8List();

  /// حجم ملف PDF يحوي نصاً واحداً بخط معيّن (بلا ضغط لأجل قياس ثابت).
  Future<int> pdfSize(pw.Font font, String text) async {
    final pw.Document doc = pw.Document(compress: false);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context _) =>
            pw.Text(text, style: pw.TextStyle(font: font, fontSize: 20)),
      ),
    );
    final List<int> bytes = await doc.save();
    return bytes.length;
  }

  setUp(CustomPdfFonts.clear);
  tearDown(CustomPdfFonts.clear);

  test('الخط المضمّن يُقصّ على المحارف المستخدمة بدل تضمين الملف كاملاً', () async {
    final Uint8List bytes = await cairoBytes();
    final pw.Font font = CustomPdfFonts.register('subset-probe', bytes);

    final int size = await pdfSize(font, 'أ ب ج');

    // ملف Cairo المضمّن ~91KB؛ قصّ ثلاثة محارف يجب أن يبقى كسراً صغيراً منه.
    expect(
      size,
      lessThan(bytes.lengthInBytes ~/ 4),
      reason: 'يبدو أن الخط ضُمِّن كاملاً بدل قصّ المحارف المستخدمة '
          '(PDF=$size، الملف=${bytes.lengthInBytes}).',
    );
  });

  test('حجم الخط المضمّن يكبر مع المحارف المستخدمة لكن يبقى دون حجم الملف',
      () async {
    final Uint8List bytes = await cairoBytes();
    final pw.Font font = CustomPdfFonts.register('subset-probe', bytes);

    final int few = await pdfSize(font, 'أ ب ج');
    final int many = await pdfSize(
      font,
      'ابتثجحخدذرزسشصضطظعغفقكلمنهوي٠١٢٣٤٥٦٧٨٩ ،.؟!؛«»—',
    );

    expect(many, greaterThan(few), reason: 'القصّ يجب أن يتبع المحارف المستخدمة.');
    expect(many, lessThan(bytes.lengthInBytes),
        reason: 'حتى مع محارف كثيرة يبقى المضمَّن أصغر من ملف الخط كاملاً.');
  });

  test('يُرفض الخط غير القابل للقصّ (رأس OTTO/CFF) بدل تضمينه كاملاً', () async {
    final Uint8List cff = Uint8List.fromList(await cairoBytes());
    // نستبدل رأس TrueType (‎0x00010000) برأس OTTO (‎CFF/PostScript).
    cff[0] = 0x4F;
    cff[1] = 0x54;
    cff[2] = 0x54;
    cff[3] = 0x4F;

    expect(
      () => CustomPdfFonts.register('cff-probe', cff),
      throwsA(isA<AppException>()),
    );
    expect(CustomPdfFonts.contains('cff-probe'), isFalse);
  });

  test('ملف أقصر من رأس sfnt يُرفض بلطف بلا انهيار', () {
    expect(
      () => CustomPdfFonts.register('tiny', Uint8List.fromList(<int>[1, 2])),
      throwsA(isA<AppException>()),
    );
  });

  test('isSubsettableTrueType يميّز رؤوس الملفات', () async {
    expect(CustomPdfFonts.isSubsettableTrueType(await cairoBytes()), isTrue);
    expect(
      CustomPdfFonts.isSubsettableTrueType(Uint8List.fromList(<int>[0, 0, 0, 0])),
      isFalse,
    );
  });
}
