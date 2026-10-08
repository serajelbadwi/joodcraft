/// محرّك التدرّجات اللونية عالي الدقة للـ PDF (Anti-Banding / Dithering).
///
/// **المشكلة:** تدرّج بلونين فقط يُسقط على الورق/الشاشة عبر تكميم 8-بت، فتظهر
/// «الخطوط» (Banding) وحدود الانتقال مرئية — وهي أوضح ما يكون في الخلفيات
/// الفاتحة وفي التدرّجات الطويلة (خلفية الورقة كاملة).
///
/// **الحل:** لا نُصغّر عدد الألوان ولا نُحوّل الخلفية إلى صورة (فالصورة تفقد
/// حدّتها وتُنتج مواريه). بل نُغذّي الـ PDF بـ*سلّم عيّنات كثيف* (‎[pdfGradientSamples]
/// عيّنة) يُفسَّر داخل الملف بدالة تنعيم (`/FunctionType 0`) فيبقى التدرّج
/// **متجهاً (Vector) بالكامل**، ثم نُضيف على كل عيّنة داخلية **تشويش كسر
/// (Dither)** متمركزاً حول الصفر: خطوة نصف بكسل 8-بت. أثرُه أن انتقالات
/// التكميم تتفتّت ضجيجاً عالي التردّد غير مرئي بدل أن تتجسّد خطوطاً.
///
/// **الحتمية:** لا `Random` ولا زمن ولا ترتيب تنفيذ — الإزاحة دالة رياضية
/// بحتة في (المؤشّر، القناة)، فينتج الملف الواحد نفسه في كل تصدير، وتُختبر
/// الوحدة بلا تثبيت بذرة عشوائية.
library;

import 'package:pdf/pdf.dart';

/// عدد عيّنات سلّم التدرّج المصدَّر إلى PDF.
///
/// 64 عيّنة: كثيفة بما يكفي لتفتيت التكميم، وبخيفة على الملف (دالة تنعيم واحدة
/// لكل تدرّج، وكل عيّنة ثلاثة بايتات).
const int pdfGradientSamples = 64;

/// هل يُطبَّق تشويش الكسر على عيّنات التدرّج افتراضياً؟
const bool pdfGradientDither = true;

/// أساسات متتالية فريدة لكل قناة — تمنع تراصّ الضجيج المتماثل بين القنوات
/// فيظهر التدرّج رمادياً مزرقّاً بدل أن يبقى رمادياً محايداً.
const List<int> _ditherBases = <int>[2, 3, 5];

/// إزاحة التشويش لعيّنة [index] في القناة [channel] بمقياس 0..1.
///
/// توزيع مثلّثي (مجموع متغيّرين منتظمين) متمركز حول الصفر، مداه ‎±0.5/255‎
/// أي نصف خطوة تكميم 8-بت — أقوى ما يكسر الخطوط بأقل ما يُرى ضجيجاً.
double pdfDitherOffset(int index, int channel) {
  final int base = _ditherBases[channel % _ditherBases.length];
  final double a = _radicalInverse(index * 2 + 1, base);
  final double b = _radicalInverse(index * 2 + 2, base);
  return (a + b - 1.0) * (0.5 / 255);
}

/// عكس الجذر (Van der Corput) — تسلسل منخفض التباين يغطّي [0,1) بتوزيع متساوٍ
/// بلا تكرار قصير (بخلاف الضجيج الزائف العادي الذي يُنتج أنماطاً مرئية).
double _radicalInverse(int n, int base) {
  double value = 0;
  double factor = 1 / base;
  int remaining = n;
  while (remaining > 0) {
    value += factor * (remaining % base);
    remaining ~/= base;
    factor /= base;
  }
  return value;
}

/// سلّم تدرّج عالي الدقة بين [start] و[end] بعيّنات متساوية المسافة.
///
/// * الاستيفاء في فضاء sRGB **كما ترسمه اللوحة** (`ui.Gradient.linear`)، فلا
///   ينحرف اللون الأوسط في الطباعة عن الشاشة.
/// * الطرفان يُتركان **دقيقين تماماً** (بلا تشويش) فيبقى أول لون وآخره كما
///   اختاره المستخدم.
/// * العيّنات الداخلية تُشوَّش بـ[pdfDitherOffset] — الأثر صفريّ في المعدّل
///   (التشويش متمركز حول الصفر) فلا يتغيّر اللون المتوقّع، وتتفتّت الخطوط.
List<PdfColor> pdfGradientRamp(
  PdfColor start,
  PdfColor end, {
  int samples = pdfGradientSamples,
  bool dither = pdfGradientDither,
}) {
  final int count = samples < 2 ? 2 : samples;
  final List<PdfColor> ramp = <PdfColor>[];
  for (int i = 0; i < count; i++) {
    final double t = i / (count - 1);
    PdfColor color = _lerp(start, end, t);
    if (dither && i > 0 && i < count - 1) {
      color = _dithered(color, i);
    }
    ramp.add(color);
  }
  return List<PdfColor>.unmodifiable(ramp);
}

/// استيفاء خطّي في فضاء sRGB (نفس ما تفعله لوحة فلاتر بين لونَي التدرّج).
PdfColor _lerp(PdfColor start, PdfColor end, double t) {
  double mix(double a, double b) => (a + (b - a) * t).clamp(0.0, 1.0);
  return PdfColor(
    mix(start.red, end.red),
    mix(start.green, end.green),
    mix(start.blue, end.blue),
    mix(start.alpha, end.alpha),
  );
}

/// عيّنة مُشوَّشة — التنويض على 8-بت يتجاوز الطرفين بجزء من الخطوة فيُعاد ضبطه.
PdfColor _dithered(PdfColor color, int index) {
  double shift(double value, int channel) =>
      (value + pdfDitherOffset(index, channel)).clamp(0.0, 1.0);
  return PdfColor(
    shift(color.red, 0),
    shift(color.green, 1),
    shift(color.blue, 2),
    color.alpha,
  );
}
