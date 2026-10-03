import 'package:flutter/material.dart';

/// لوحة ألوان الهوية البصرية الرسمية لمنصة JoodCraft.
///
/// الألوان الأربعة الأولى هي "قيم الهوية المعتمدة" ولا يجوز تغييرها إلا بقرار
/// تصميمي رسمي. باقي الألوان مشتقة منها لتغطية الحالات الدلالية (نجاح/تحذير…).
abstract final class AppColors {
  const AppColors._();

  // ------------------------------- الهوية الرسمية -------------------------------
  /// الأزرق الكحلي — اللون الأساسي (Primary Navy).
  static const Color navy = Color(0xFF1B2539);

  /// الذهبي الفاخر — لون الإبراز (Accent Gold).
  static const Color gold = Color(0xFFC7A26B);

  /// خلفية التطبيق العامة.
  static const Color background = Color(0xFFF9FAFB);

  /// سطح البطاقات والحقول.
  static const Color surface = Color(0xFFFFFFFF);

  // ------------------------------ مشتقات الكحلي -------------------------------
  /// كحلي أغمق — للخلفيات العميقة واللوحات الجانبية.
  static const Color navyDeep = Color(0xFF141C2B);

  /// كحلي فاتح — للحالات النشطة والأسطح الملطفة.
  static const Color navySoft = Color(0xFF2A3852);

  /// كحلي باهت جداً — خلفيات خفيفة داخل المحتوى.
  static const Color navyWash = Color(0xFFEEF1F6);

  // ------------------------------ مشتقات الذهبي -------------------------------
  /// ذهبي فاتح — خلفيات الشارات والأشرطة.
  static const Color goldSoft = Color(0xFFF5EDDF);

  /// ذهبي داكن — للاستخدام على خلفيات فاتحة عند الحاجة لتباين أعلى.
  static const Color goldDeep = Color(0xFF9E7B45);

  // -------------------------------- النصوص --------------------------------
  /// لون النص الأساسي.
  static const Color ink = Color(0xFF1B2539);

  /// نص ثانوي (وصف/تلميح).
  static const Color inkMuted = Color(0xFF6B7280);

  /// نص معطّل.
  static const Color inkDisabled = Color(0xFF9CA3AF);

  /// نص على خلفية كحلية.
  static const Color onNavy = Color(0xFFF4F6FA);

  // ------------------------------ الحدود والفواصل ------------------------------
  static const Color border = Color(0xFFE5E7EB);

  /// حدود وظلال كحلية شفافة (تُستخدم بتدرّج ألفا فقط — بدون تغيير الصبغة).
  static Color navyShadow([double opacity = 0.08]) =>
      navy.withValues(alpha: opacity);

  // -------------------------------- الحالات --------------------------------
  static const Color success = Color(0xFF15803D);
  static const Color successSoft = Color(0xFFE7F5EC);
  static const Color warning = Color(0xFFB45309);
  static const Color warningSoft = Color(0xFFFDF3E3);
  static const Color danger = Color(0xFFB42318);
  static const Color dangerSoft = Color(0xFFFDECEA);

  // --------------------------- المظهر الداكن ---------------------------
  // مشتقات الهوية نفسها بإضاءة معكوسة: نفس العلاقات (الخلفية أغمق من
  // السطح، النص فاتح…) كي يبدو التطبيق «نفسه» ليلاً لا نسخةً منفصلة.
  // تُستعمل عبر `ColorScheme` الداكن في `AppTheme.dark`.

  /// خلفية التطبيق العامة في المظهر الداكن (أغمق من السطح).
  static const Color darkBackground = Color(0xFF0F1522);

  /// سطح البطاقات والحقول في المظهر الداكن.
  static const Color darkSurface = Color(0xFF171F30);

  /// حدود وفواصل في المظهر الداكن.
  static const Color darkBorder = Color(0xFF2A3448);

  /// نص أساسي فاتح.
  static const Color darkInk = Color(0xFFE9EDF5);

  /// نص ثانوي فاتح.
  static const Color darkInkMuted = Color(0xFF9CA6BA);

  /// نص معطّل فاتح.
  static const Color darkInkDisabled = Color(0xFF6A7488);

  /// مقابل `navyWash` — حاوية كحلية باهتة على الأسطح الداكنة.
  static const Color darkNavyWash = Color(0xFF1F2A40);

  /// مقابل `goldSoft` — حاوية ذهبية باهتة على الأسطح الداكنة.
  static const Color darkGoldSoft = Color(0xFF3B3222);

  /// حالات مُضيئة للنص فوق الأسطح الداكنة (تباين كافٍ لاكتساب WCAG AA).
  static const Color darkSuccess = Color(0xFF4ADE80);
  static const Color darkWarning = Color(0xFFFBBF24);
  static const Color darkDanger = Color(0xFFF07167);
}

/// ألوان دلالية تتكيّف مع سطوع الثيم الحالي عبر `Theme.of(context).colorScheme`.
///
/// تُستخدم في الشاشات لكل ما كان يُكتب سابقاً كقيمة ثابتة في `AppColors`
/// (مثل `goldDeep` كنص ثانوي) — فتبقى الهوية ذهبية في الوضعين مع تباين كافٍ.
extension AppSchemeColors on ColorScheme {
  /// ذهبي داكن لنصوص/أيقونات ثانوية — يُضيء ليلاً حفاظاً على التباين.
  Color get goldDeep =>
      brightness == Brightness.dark ? AppColors.gold : AppColors.goldDeep;

  /// نجاح / تحذير / خطر بتباين آمن فوق أي سطح في الوضعين.
  Color get success =>
      brightness == Brightness.dark ? AppColors.darkSuccess : AppColors.success;
  Color get warning =>
      brightness == Brightness.dark ? AppColors.darkWarning : AppColors.warning;
  Color get danger =>
      brightness == Brightness.dark ? AppColors.darkDanger : AppColors.danger;
}
