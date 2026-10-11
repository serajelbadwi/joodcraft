import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/pdf/offscreen_widget_renderer.dart';
import 'package:joodcraft/core/services/pdf_generator_service.dart';

import '../support/sample_image.dart';

/// علاج «الشهادة الأولى بلا لوجو/توقيع».
///
/// كل صفحة في مسار التصدير النقطي تمرّ بـ[OffscreenWidgetRenderer]، وأول صفحة
/// تكون ذاكرة الصور فيها باردة دائماً — فكانت الصور تغيب لأن العنصر لا يُعاد
/// بناؤه بعد وصول الصورة. الاختبار يبدأ بذاكرة باردة فعلياً ويرسم ثلاث
/// صفحات متتالية (كصفحات شهادة جماعية) ويتحقق أن الشعار والتوقيع حاضران في
/// **الثلاث**، ثم يولّد PDF حقيقياً من مسار التصدير نفسه للتحقّق البصري.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final String magenta = magentaPngBase64();

  TemplateDocument certificate() => TemplateDocument(
        canvasWidth: 300,
        canvasHeight: 200,
        backgroundHex: '#FFFFFF',
        elements: <TemplateElement>[
          // الشعار: صورة مربّعة تملأ صندوقها.
          ImageElement(
            id: 'logo',
            box: const ElementBox(x: 20, y: 20, width: 80, height: 80),
            sourceKind: ImageSourceKind.dataUri,
            path: magenta,
            fit: ImageFit.fill,
          ),
          // التوقيع: خانة واحدة بصورة بلا اسم/دور حتى لا تشوّه النصوص القياس.
          SignatureElement(
            id: 'signature',
            box: const ElementBox(x: 100, y: 130, width: 180, height: 60),
            slots: <SignatureSlot>[
              SignatureSlot(
                imagePath: magenta,
                imageSource: ImageSourceKind.dataUri,
              ),
            ],
            slotCount: 1,
          ),
        ],
      );

  /// مجلد مخرجات للتحقّق البصري من اللوجو في كل صفحة (مُتجاهل في Git).
  Directory outDir() {
    final String base =
        Platform.environment['JOODCRAFT_TEST_OUT'] ?? Directory.systemTemp.path;
    final Directory dir =
        Directory('$base${Platform.pathSeparator}joodcraft_offscreen_fix');
    dir.createSync(recursive: true);
    return dir;
  }

  /// يعدّ بكسلات الماجنتا داخل مستطيل تصميمي من ملف PNG مرسوم.
  Future<({int logo, int sign})> magentaCounts(
    Uint8List png,
    TemplateDocument doc,
  ) async {
    final ui.Image image = await decodeImageFromList(png);
    final ByteData? raw =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    expect(raw, isNotNull, reason: 'تعذّر قراءة بكسلات الصفحة');
    final Uint8List rgba =
        raw!.buffer.asUint8List(raw.offsetInBytes, raw.lengthInBytes);
    final double sx = image.width / doc.designWidth;
    final double sy = image.height / doc.designHeight;

    int countIn(double x0, double y0, double x1, double y1) {
      int count = 0;
      final int px0 = (x0 * sx).floor();
      final int px1 = (x1 * sx).ceil();
      final int py0 = (y0 * sy).floor();
      final int py1 = (y1 * sy).ceil();
      for (int py = py0; py < py1; py++) {
        for (int px = px0; px < px1; px++) {
          final int i = (py * image.width + px) * 4;
          if (rgba[i] >= 250 &&
              rgba[i + 1] <= 5 &&
              rgba[i + 2] >= 250 &&
              rgba[i + 3] > 0) {
            count++;
          }
        }
      }
      return count;
    }

    // داخل صندوق الشعار (بلا حوافّ مموّهة) وداخل صندوق عنصر التوقيع.
    final int logo = countIn(24, 24, 96, 96);
    final int sign = countIn(104, 134, 276, 186);
    image.dispose();
    return (logo: logo, sign: sign);
  }

  test(
    'الصفحة الأولى الباردة لا تفقد الشعار ولا التوقيع — ثلاث صفحات متتالية',
    () async {
      // ذاكرة صور باردة فعلياً: هذا حال أول صفحة عند أول تصدير.
      PaintingBinding.instance.imageCache.clear();

      final TemplateDocument doc = certificate();
      final Directory out = outDir();

      for (int page = 1; page <= 3; page++) {
        final Uint8List png =
            await OffscreenWidgetRenderer.renderDocumentToImageBytes(doc);
        File('${out.path}${Platform.pathSeparator}page_$page.png')
            .writeAsBytesSync(png);

        final ({int logo, int sign}) counts = await magentaCounts(png, doc);
        expect(
          counts.logo,
          greaterThan(1000),
          reason: 'الشعار غائب من الصفحة $page — أول صفحة بذاكرة باردة',
        );
        expect(
          counts.sign,
          greaterThan(1000),
          reason: 'التوقيع غائب من الصفحة $page — أول صفحة بذاكرة باردة',
        );
      }
    },
  );

  test('مسار التصدير النقطي يُخرج شهادة ثلاث صفحات كاملة', () async {
    final PdfGeneratorService service =
        await PdfGeneratorService.create(compress: false);
    final PdfGenerationReport report = await service.generateBatch(
      document: certificate(),
      rows: const <Map<String, String>>[
        <String, String>{},
        <String, String>{},
        <String, String>{},
      ],
    );

    expect(report.pageCount, 3);
    expect(report.bytes, isNotEmpty);

    // نسخة PDF للتحقّق البصري من أن كل صفحة تحمل الشعار والتوقيع.
    File('${outDir().path}${Platform.pathSeparator}certificate_3pages.pdf')
        .writeAsBytesSync(report.bytes);
    debugPrint('📄 [test] شهادة ثلاث صفحات جاهزة للتحقّق البصري.');
  });
}
