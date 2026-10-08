import 'dart:typed_data';

import 'package:image/image.dart' as im;
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;

/// مزوّد صورة عالي الجودة لمحرّك الطباعة: إعادة تحجيم صحيحة + تضمين بلا فقدان.
///
/// **المشكلة في المسار الافتراضي (`pw.MemoryImage`):** عند تحديد دقّة للمستند
/// (مسار التصدير عالي الدقة/ورقة التجميع) تُعاد الصورة إلى الدقّة المطلوبة بـ
/// `copyResize` **بأقرب جار** (افتراضي حزمة `image`). «أقرب جار» عند التصغير
/// يُهمل بكسلات كاملة، فيتحوّل أي نمط رفيع (نقش إطار، خطوط، تدرّج ناعم، شعار
/// عالي الدقة) إلى **مواريه وتشويه** — وهو تحديداً ما يشتكي منه المطبوع.
///
/// **الحل هنا:**
/// * **تصغير** ← متوسط المساحة ([im.Interpolation.average]): كل بكسل ناتج هو
///   متوسط *كل* بكسلات المصدر التي يغطيها، فهو مرشّح تمرير-منخفض صحيح يُلغي
///   التردّدات العالية بدل أن يعيّنها بعشوائياً ⇒ لا مواريه.
/// * **تكبير** ← استيفاء تكعيبي ([im.Interpolation.cubic]): انتقالات ناعمة بلا
///   الحواف المتدرّجة التي يُنتجها أقرب جار.
/// * **الصور المفهرسة (PNG-8)** تُحوَّل أولاً إلى صبغة كاملة قبل التحجيم، لأن
///   الحزمة تُجبر «أقرب جار» على أي صورة بقائمة ألوان (فيرجع المواريه من الباب
///   الخلفي). التحويل لا يغيّر الألوان إطلاقاً.
/// * **التضمين بلا فقدان:** الصورة المُعاد تحجيمها تُكتب صبغة خام (RGBA) في
///   الملف، ويضغطها الـ PDF بمرشّح **FlateDecode غير المتلف** — بلا ضغط JPEG
///   للصور المُعاد تحجيمها فلا تتولّد إضافةً إلى المواريه «هالات» فقدانية.
/// * **بلا إعادة تحجيم:** تُضمَّن بايتات الأصل كما هي حرفياً ⇒ صفر فقدان إضافي،
///   وJPEG المصدر يبقى `DCTDecode` (بلا إعادة ترميز).
class PdfQualityImage extends pw.ImageProvider {
  factory PdfQualityImage(
    Uint8List bytes, {
    double? dpi,
    pdf.PdfImageOrientation? orientation,
  }) {
    final im.Decoder? decoder = im.findDecoderForData(bytes);
    if (decoder == null) {
      throw ArgumentError(
        'Unable to guess the image type (${bytes.length} bytes)',
      );
    }
    final im.DecodeInfo? info = decoder.startDecode(bytes);
    if (info == null) {
      throw ArgumentError('Unable to decode the image');
    }
    return PdfQualityImage._(
      bytes,
      info.width,
      info.height,
      orientation ?? pdf.PdfImageOrientation.topLeft,
      dpi,
    );
  }

  PdfQualityImage._(
    this.bytes,
    int? width,
    int height,
    pdf.PdfImageOrientation orientation,
    double? dpi,
  ) : super(width, height, orientation, dpi);

  /// بايتات الصورة الأصلية (كما وصلت من المخزن/الأصل).
  final Uint8List bytes;

  @override
  pdf.PdfImage buildImage(pw.Context context, {int? width, int? height}) {
    // بلا دقّة مطلوبة: الأصل يُضمَّن حرفياً — أسرع وأصغر وبلا فقدان إضافي.
    if (width == null || width <= 0) {
      return pdf.PdfImage.file(
        context.document,
        bytes: bytes,
        orientation: orientation,
      );
    }

    final im.Image? decoded = im.decodeImage(bytes);
    if (decoded == null) {
      // فكّ الترميز مستحيل الآن (ملف تالف رغم نجاح قراءة الترويسة): نرجع
      // للأصل بدل إسقاط العنصر من الصفحة.
      return pdf.PdfImage.file(
        context.document,
        bytes: bytes,
        orientation: orientation,
      );
    }

    return pdf.PdfImage.fromImage(
      context.document,
      image: pdfResampleForPrint(decoded, width),
      orientation: orientation,
    );
  }
}

/// إعادة تحجيم صورة لطباعة عالية الجودة إلى عرض [targetWidth] بكسل.
///
/// تُختبر وحدها (بلا مستند PDF) لأن جوهر مقاومة المواريه في اختيار المرشّح،
/// لا في المسار المحيط. الارتفاع يُشتق من نِسَب المصدر كما في المسار الافتراضي.
im.Image pdfResampleForPrint(im.Image source, int targetWidth) {
  final int width = targetWidth < 1 ? 1 : targetWidth;

  if (width == source.width) return source;

  // قائمة ألوان ⇒ صبغة كاملة، لأن `copyResize` تُجبر «أقرب جار» على المفهرسة.
  final im.Image src = source.hasPalette
      ? source.convert(format: im.Format.uint8, numChannels: 4)
      : source;

  if (width > src.width) {
    return im.copyResize(
      src,
      width: width,
      interpolation: im.Interpolation.cubic,
    );
  }

  return im.copyResize(
    src,
    width: width,
    interpolation: im.Interpolation.average,
  );
}
