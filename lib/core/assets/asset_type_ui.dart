import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/template_element.dart';

/// واجهة العرض لأنواع الأصول — أيقونة وتلميح وملاءمة افتراضية عند الإدراج.
extension AssetTypeUi on AssetType {
  IconData get icon => switch (this) {
        AssetType.logo => Icons.business_rounded,
        AssetType.signature => Icons.draw_rounded,
        AssetType.stamp => Icons.verified_rounded,
        AssetType.border => Icons.crop_original_rounded,
      };

  String get hintAr => switch (this) {
        AssetType.logo => 'شعار المؤسسة — يُعرض عادةً في الترويسة.',
        AssetType.signature => 'التوقيع المعتمد — يُدرج أسفل المستند.',
        AssetType.stamp => 'الختم/الحية الرسمية — يُوضع قرب التوقيع.',
        AssetType.border => 'إطار الخلفية — يغطي الصفحة كاملة.',
      };

  /// ملاءمة الصورة الافتراضية لهذا النوع عند إدراجه في القالب.
  ImageFit get defaultFit => switch (this) {
        AssetType.border => ImageFit.fill,
        _ => ImageFit.contain,
      };
}
