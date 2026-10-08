// تلوين صور الـ PDF بمعنى `BlendMode.srcIn` — مطابق تماماً لما يراه المستخدم
// في لوحة المحرّر.
//
// لماذا معالجة البكسلات؟ حزمة `pdf` لا توفّر مرشّح لون للصور النقطية
// (`colorFilter` فيها للـ SVG وحده)، فلا مفرّ من تجهيز البايتات قبل تضمينها.
//
// القاعدة: لكل بكسل **مرسوم** (شفافيته > 0) يُستبدل RGB بلون التلوين، وتبقى
// قناة A كما هي — تماماً كـ`ColorFilter.mode(color, srcIn)`. ولذلك لا يتسرّب
// اللون إلى المناطق الشفافة: قلب الإطار الشفاف يبقى شفافاً.

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../models/template_element.dart';

/// مفتاح الصورة في خرائط محرّك الطباعة — يُبنى بنفس دالة المحرّر
/// ([imageKeyFor]) فيطابق `ImageElement.imageKey`/`tintedImageKey` تماماً،
/// ويشترك فيه مسارا الـ PDF (المباشر وداخل isolate) بلا حساب موازٍ ينحرف.
String pdfImageCacheKey(
  String path,
  ImageSourceKind kind, {
  String? tintHex,
  String? adjustKey,
}) =>
    imageKeyFor(kind, path, tintHex: tintHex, adjustKey: adjustKey);

/// حدّ الحجم الذي فوقه يُنفَّذ التلوين في isolate منفصل (كي لا تتجمّد الواجهة
/// عند تلوين إطار عالي الدقة).
const int tintOffThreadThresholdBytes = 48 * 1024;

/// يلوّن بايتات الصورة باللون [tintHex] ويعيد PNG (بشفافيته).
///
/// يعيد `null` إن تعذّر فكّ ترميز الصورة أو كان اللون غير صالح — ولا يرمي أبداً.
Uint8List? tintImageBytes(Uint8List source, String tintHex) {
  final (int, int, int)? rgb = tintRgbOf(tintHex);
  if (rgb == null || source.isEmpty) return null;
  try {
    final img.Image? decoded = img.decodeImage(source);
    if (decoded == null) return null;
    final int red = rgb.$1;
    final int green = rgb.$2;
    final int blue = rgb.$3;
    for (final img.Pixel pixel in decoded) {
      // المنطقة الشفافة لا تُمَس إطلاقاً (سلوك srcIn: اللون يأخذ شفافيته من
      // الصورة نفسها، فلا يزحف إلى الفراغ).
      if (pixel.a == 0) continue;
      pixel.r = red;
      pixel.g = green;
      pixel.b = blue;
    }
    return img.encodePng(decoded);
  } on Object catch (_) {
    return null;
  }
}

/// نسخة غير حاجزة للواجهة: تُنفَّذ في isolate منفصل للصور الكبيرة.
///
/// تُرجع البكسلات الأصلية عند فشل التلوين (لون غير صالح/صورة تالفة) فلا يضيع
/// الأصل من ملف الطباعة بسبب التلوين.
Future<Uint8List> tintImageBytesSafely(
  Uint8List source,
  String tintHex,
) async {
  final Uint8List? tinted = source.lengthInBytes >= tintOffThreadThresholdBytes
      ? await compute(_tintEntry, (source, tintHex))
      : tintImageBytes(source, tintHex);
  return tinted ?? source;
}

Uint8List? _tintEntry((Uint8List, String) args) =>
    tintImageBytes(args.$1, args.$2);

/// يحلّل لوناً نصياً (`#RRGGBB` أو `RRGGBB` أو `#RGB` أو `#AARRGGBB`) إلى
/// مكوّنات RGB، أو `null` إن كان غير صالح.
///
/// قناة الشفافية تُهمَل عمداً: شفافية الرسم تأتي من الصورة نفسها (srcIn).
(int, int, int)? tintRgbOf(String? hex) {
  if (hex == null) return null;
  String value = hex.trim();
  if (value.startsWith('#')) value = value.substring(1);
  if (value.length == 3) {
    value = value.split('').map((String char) => '$char$char').join();
  }
  if (value.length != 6 && value.length != 8) return null;
  final int? parsed = int.tryParse(value, radix: 16);
  if (parsed == null) return null;
  return ((parsed >> 16) & 0xFF, (parsed >> 8) & 0xFF, parsed & 0xFF);
}
