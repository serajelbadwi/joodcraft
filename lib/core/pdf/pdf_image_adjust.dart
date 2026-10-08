// الضبط اللوني للصور في محرّك الطباعة — بنفس دلالة اللوحة (Prompt 1.4).
//
// لماذا معالجة البكسلات؟ حزمة `pdf` لا تعرف مصفوفات الألوان ولا مرشّحات الصور
// النقطية، فلا مفرّ من تجهيز البايتات قبل تضمينها — تماماً كأسلوب التلوين في
// `pdf_image_tint.dart` (الذي يشرح السبب نفسه).
//
// المعاملات مطابقة لمصفوفة اللوحة: السطوع والتباين والتشبّع مضاعِفات (1 = بلا
// تغيير) والتدوير اللوني بالدرجات، فيرى المستخدم في الطباعة ما رآه على اللوحة.

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../models/template_element.dart';

/// حدّ الحجم الذي فوقه يُنفَّذ الضبط في isolate (بلا تجميد الواجهة).
const int adjustOffThreadThresholdBytes = 48 * 1024;

/// يطبّق [adjustments] على بايتات الصورة ويعيد PNG.
///
/// يعيد `null` إن تعذّر فكّ الترميز — ولا يرمي أبداً، فيبقى الأصل هو الاحتياط
/// الذي يستعمله [adjustImageBytesSafely].
Uint8List? adjustImageBytes(Uint8List source, ElementAdjustments adjustments) {
  if (source.isEmpty || adjustments.isIdentity) return null;
  try {
    final img.Image? decoded = img.decodeImage(source);
    if (decoded == null) return null;
    final img.Image adjusted = img.adjustColor(
      decoded,
      brightness: adjustments.brightnessFactor,
      contrast: adjustments.contrastFactor,
      saturation: adjustments.saturationFactor,
      hue: adjustments.hue,
    );
    return img.encodePng(adjusted);
  } on Object catch (_) {
    return null;
  }
}

/// نسخة غير حاجزة للواجهة: تُنفَّذ في isolate للصور الكبيرة.
///
/// تُرجع البكسلات الأصلية عند الفشل أو عند غياب الضبط — فلا يسقط العنصر من
/// ملف الطباعة بسبب ضبط لوني.
Future<Uint8List> adjustImageBytesSafely(
  Uint8List source,
  ElementAdjustments? adjustments,
) async {
  if (adjustments == null || adjustments.isIdentity) return source;
  final Uint8List? adjusted =
      source.lengthInBytes >= adjustOffThreadThresholdBytes
          ? await compute(_adjustEntry, (source, adjustments))
          : adjustImageBytes(source, adjustments);
  return adjusted ?? source;
}

Uint8List? _adjustEntry((Uint8List, ElementAdjustments) args) =>
    adjustImageBytes(args.$1, args.$2);
