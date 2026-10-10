import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import '../models/template_document.dart';
import 'custom_pdf_fonts.dart';
import 'pdf_font_catalog.dart';
import 'pdf_quality_image.dart';
import 'pdf_render_engine.dart';

/// وسوم رسائل isolate الواردة.
const int _tagProgress = 1;
const int _tagDone = 2;
const int _tagError = 3;

/// بايتات خط مخصص refereced من المستند — تُنقل إلى isolate لتُسجَّل هناك.
class PdfCustomFontBytes {
  const PdfCustomFontBytes({
    required this.family,
    required this.weight,
    required this.bytes,
  });

  final String family;
  final int weight;
  final Uint8List bytes;
}

/// طلب توليد PDF قابل للإرسال بين الـ isolates (بلا أي كائن `pw.*`).
///
/// كل ما يحتاجه الرسم داخل الـ isolate: المستند + الصفوف + بايتات الخطوط +
/// بايتات الصور + الخطوط المخصصة. لا يلمس `rootBundle` ولا الشبكة.
class PdfRenderRequest {
  const PdfRenderRequest({
    required this.document,
    required this.rows,
    required this.imageBytes,
    required this.embeddedFontBytes,
    required this.customFonts,
    required this.compress,
    this.metadata,
  });

  final TemplateDocument document;
  final List<Map<String, String>> rows;

  /// بايتات الصور بالمفتاح `kind:path`.
  final Map<String, Uint8List> imageBytes;

  /// بايتات الخطوط المضمّنة بالمفتاح `family:weight`.
  final Map<String, Uint8List> embeddedFontBytes;

  final List<PdfCustomFontBytes> customFonts;
  final bool compress;
  final PdfDocumentMetadata? metadata;
}

/// توليد ملف PDF داخل isolate خلفي — بلا تجميد خيط الواجهة.
///
/// يبثّ تقدّم البناء عبر [onProgress] فور وصوله من الـ isolate (لا ينتظر
/// الانتهاء)، ويعيد البايتات النهائية. يرمي [StateError] برسالة الخطأ إن فشل
/// التوليد داخل الـ isolate.
Future<Uint8List> renderPdfInBackground(
  PdfRenderRequest request, {
  void Function(int done, int total)? onProgress,
}) async {
  final ReceivePort receive = ReceivePort();
  final Completer<Uint8List> completer = Completer<Uint8List>();
  Isolate? isolate;

  final StreamSubscription<dynamic> subscription = receive.listen(
    (Object? message) {
      if (message is! List || message.isEmpty) return;
      switch (message[0]) {
        case _tagProgress:
          onProgress?.call(message[1] as int, message[2] as int);
        case _tagDone:
          if (!completer.isCompleted) {
            completer.complete(message[1] as Uint8List);
          }
        case _tagError:
          if (!completer.isCompleted) {
            completer.completeError(StateError(message[1] as String));
          }
      }
    },
    onError: (Object error) {
      if (!completer.isCompleted) completer.completeError(error);
    },
  );

  try {
    isolate = await Isolate.spawn(
      _pdfIsolateEntry,
      <Object?>[receive.sendPort, request],
      debugName: 'joodcraft-pdf',
    );
    return await completer.future;
  } finally {
    isolate?.kill(priority: Isolate.immediate);
    await subscription.cancel();
    receive.close();
  }
}

/// نقطة دخول الـ isolate — تُعيد بناء الخطوط من البايتات ثم ترسم.
void _pdfIsolateEntry(Object? message) {
  unawaited(_renderRequest(message));
}

Future<void> _renderRequest(Object? message) async {
  final List<Object?> args = message as List<Object?>;
  final SendPort send = args[0] as SendPort;
  final PdfRenderRequest request = args[1] as PdfRenderRequest;
  try {
    final PdfFontSet fonts = PdfFontSet.fromBytes(request.embeddedFontBytes);
    for (final PdfCustomFontBytes custom in request.customFonts) {
      CustomPdfFonts.register(custom.family, custom.bytes, weight: custom.weight);
    }
    // `PdfQualityImage` لا `pw.MemoryImage`: تحجيم متوسط-المساحة عند تحديد
    // الدقّة (لا «أقرب جار» الذي يولّد المواريه) وتضمين بلا فقدان.
    final Map<String, pw.ImageProvider?> images = <String, pw.ImageProvider?>{
      for (final MapEntry<String, Uint8List> entry in request.imageBytes.entries)
        entry.key: PdfQualityImage(entry.value),
    };

    final PdfRenderer renderer = PdfRenderer(
      fonts: fonts,
      compress: request.compress,
      // دقّة المستند نفسها في المسار الخلفي، فلا تختلف النتيجة باختلاف
      // حجم الدفعة (خيط رئيسي / isolate).
      dpi: request.document.dpi.toDouble(),
    );
    final Uint8List bytes = await renderer.build(
      document: request.document,
      rows: request.rows,
      images: images,
      metadata: request.metadata,
      onProgress: (int done, int total) =>
          send.send(<Object?>[_tagProgress, done, total]),
    );
    send.send(<Object?>[_tagDone, bytes]);
  } catch (error) {
    send.send(<Object?>[_tagError, error.toString()]);
  }
}
