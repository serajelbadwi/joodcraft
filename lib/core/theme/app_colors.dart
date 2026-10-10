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
  // لوحة **سليت موحّدة** (Unified Slate): هجرنا الدرجات شبه السوداء
  // (‎#1A1A1A‎/‎#222222‎/‎#2A2A2A‎) التي كانت تُظلم اللوحات والأشرطة، ورفعنا
  // الأسطح الخارجية كلّها — اللوحة الجانبية، شريط الأدوات العائم، والأشرطة
  // العلوية/السفلية — إلى الطنّ الرمادي المتوسّط `#3E3E3E`، وهو الطنّ نفسه
  // الذي كانت عليه مساحة العمل. فيصير الهيكل هادئاً موحّداً بلا أي كتلة سوداء
  // شاذّة، وتُترك مساحة العمل **أفتح درجةً** (`#4A4A4A`) لتبقى الورقة البيضاء
  // مريحة على العين ومحدّدة بظل ناعم. تبقى الحدود أفتح قليلاً فتظلّ الفواصل
  // مرئية، والنصوص فاتحة بتباين WCAG كافٍ.
  //
  // ترتيب الإضاءة (الأغمق ← الأفتح):
  //   هيكل `#3E3E3E` ← مرتفع `#454545` ← مساحة عمل `#4A4A4A` ← حدود `#4F4F4F`
  // ولا وجود لأي درجة شبه سوداء بعد اليوم.

  /// الخلفية الأساسية العامة (مساحة العمل/المحاكاة) — `#3E3E3E`.
  static const Color darkBackground = Color(0xFF3E3E3E);

  /// أسطح اللوحات والقوائم وأشرطة الأدوات (اللوحة الجانبية، الشريط العائم،
  /// والأشرطة العلوية) — `#3E3E3E`، موحّدة مع الخلفية فلا فرق مُظلم بينها.
  static const Color darkSurface = Color(0xFF3E3E3E);

  /// الأسطح المرتفعة: البطاقات والنوافذ المنبثقة والمودالات — `#454545`
  /// (Macro-step خفيف فوق الهيكل فتبقى النوافذ المنبثقة مقروءة كسطح أعلى).
  static const Color darkElevated = Color(0xFF454545);

  /// مساحة عمل اللوحة (المنطقة المحيطة بورقة التصميم) — الأفتح `#4A4A4A`.
  ///
  /// **لماذا أفتح من الهيكل؟** أدوات التحرير الاحترافية (Photoshop/Figma)
  /// تجعل مساحة العمل **أفتح** من اللوحات والأشرطة المحيطة بها؛ فينخفض التباين
  /// الحادّ بين الورقة البيضاء ومحيطها فيقلّ إجهاد العين بدرجة ملموسة، وتبقى
  /// حدود الورقة واضحة بظل ناعم فوق الطنّ المتوسّط.
  static const Color darkCanvas = Color(0xFF4A4A4A);

  /// الحدود والفواصل الناعمة — `#5A5A5A` (أفتح بوضوح من كل الأسطح،
  /// فتبقى حدود الحقول والفواصل مقروءة على الطنّ الأفتح).
  static const Color darkBorder = Color(0xFF5A5A5A);

  /// حدّ أخفت للفواصل الداخلية والحدود الثانوية — `#4E4E4E`.
  static const Color darkBorderFaint = Color(0xFF4E4E4E);

  /// النص الأساسي والأيقونات النشطة — `#F5F5F5` (تباين عالٍ على الأسطح الأفتح).
  static const Color darkInk = Color(0xFFF5F5F5);

  /// النص الثانوي والتسميات والأيقونات الخاملة — `#D1D5DB` (فاتح بوضوح،
  /// فتبقى أوصاف الحقول والتلميحات مقروءة على الهيكل السليت بدل الرمادي الباهت).
  static const Color darkInkMuted = Color(0xFFD1D5DB);

  /// النص المعطّل/التلميحات — `#B5B5B5` (أخفت من الثانوي لكنه يبقى مقروءاً).
  static const Color darkInkDisabled = Color(0xFFB5B5B5);

  /// مقابل `navyWash` — حاوية محايدة مرتفعة على الأسطح — `#454545`.
  static const Color darkNavyWash = Color(0xFF454545);

  /// مقابل `goldSoft` — حاوية ذهبية داكنة دافئة على الأسطح — `#4A3E28`.
  static const Color darkGoldSoft = Color(0xFF4A3E28);

  /// حالات مُضيئة للنص فوق الأسطح الداكنة (تباين كافٍ لاكتساب WCAG AA).
  static const Color darkSuccess = Color(0xFF4ADE80);
  static const Color darkWarning = Color(0xFFFBBF24);
  static const Color darkDanger = Color(0xFFF07167);

  // -------------------- نافذة «مستند جديد» العائمة ---------------------
  // لوحة **مستقلة عن مظهر التطبيق**: الحوار نافذة عمل داكنة الطراز تظهر فوق
  // أي مساحة عمل، فتبقى هي نفسها في الوضعين الفاتح والداكن (كما تفعل نوافذ
  // برامج التحرير الاحترافية) — ولهذا لا تُشتقّ من `colorScheme` الخاص بالمظهر.

  /// خلفية الستارة خلف النافذة — أسود بشفافية 80% (`0xCC`).
  static const Color dialogBackdrop = Color(0xCC000000);

  /// سطح النافذة — `#232323`.
  static const Color dialogSurface = Color(0xFF232323);

  /// شريط العنوان (أغمق قليلاً) — `#1E1E1E`.
  static const Color dialogHeader = Color(0xFF1E1E1E);

  /// سطح مرتفع داخل النافذة (البطاقات والبطاقة المختارة) — `#2A2A2A`.
  static const Color dialogElevated = Color(0xFF2A2A2A);

  /// حدود النافذة والفواصل — `#333333`.
  static const Color dialogBorder = Color(0xFF333333);

  /// النص الأساسي على السطح الداكن — `#E6E6E6`.
  static const Color dialogInk = Color(0xFFE6E6E6);

  /// النص الثانوي والتسميات — `#9A9A9A`.
  static const Color dialogInkMuted = Color(0xFF9A9A9A);

  /// الأزرق الأساسي (زر «إنشاء») — `#2D8CEB`.
  static const Color dialogAccent = Color(0xFF2D8CEB);

  /// حاوية الأزرق (خلفية العنصر المختار) — `#1B3B5F`.
  static const Color dialogAccentContainer = Color(0xFF1B3B5F);
}

/// ألوان دلالية تتكيّف مع سطوع الثيم الحالي عبر `Theme.of(context).colorScheme`.
///
/// تُستخدم في الشاشات لكل ما كان يُكتب سابقاً كقيمة ثابتة في `AppColors`
/// (مثل `goldDeep` كنص ثانوي) — فتبقى الهوية ذهبية في الوضعين مع تباين كافٍ.
extension AppSchemeColors on ColorScheme {
  /// ذهبي داكن لنصوص/أيقونات ثانوية — يُضيء ليلاً حفاظاً على التباين.
  Color get goldDeep =>
      brightness == Brightness.dark ? AppColors.gold : AppColors.goldDeep;

  // --------------------- أسطح الهوية المتكيّفة مع السطوع ---------------------
  // قاعدة التوحيد: **الكحلي لون هُوية نهاري فقط**. في المظهر الداكن تستبدله
  // الأسطح السليت الموحّدة (الهيكل `#3E3E3E` والمرتفع `#454545`) فتبقى كل
  // اللوحات والأشرطة واللوائح والبطاقات متجانسة بلا أي كتلة كحلية أو سوداء
  // شاذّة. الذهبي يبقى لون الإبراز الوحيد الدافئ (راجع `AppColors.gold`).

  /// السطح الكحلي للهوية: كحلي `#1B2539` نهاراً، سليت `#3E3E3E` ليلاً.
  Color get brandSurface =>
      brightness == Brightness.dark ? AppColors.darkSurface : AppColors.navy;

  /// أعمق خلفية للهوية: كحلي عميق نهاراً، سليت `#3E3E3E` ليلاً.
  Color get brandSurfaceDeep => brightness == Brightness.dark
      ? AppColors.darkBackground
      : AppColors.navyDeep;

  /// سطح الهوية المرتفع (شرائح/حدود): كحلي فاتح نهاراً، سليت `#454545` ليلاً.
  Color get brandSurfaceSoft => brightness == Brightness.dark
      ? AppColors.darkElevated
      : AppColors.navySoft;

  /// لون المحتوى فوق سطح الهوية (كحلي أو فحمي) — فاتح في الحالتين.
  Color get onBrandSurface => AppColors.onNavy;

  /// خلفية مساحة عمل اللوحة (المنطقة حول ورقة التصميم).
  ///
  /// ليلاً: رمادي `#4A4A4A` — أفتح درجةً من الهيكل الموحّد (‎#3E3E3E‎) فلا
  /// يكون ورق التصميم الأبيض صادماً في محيط غامق.
  /// نهاراً: غسيل كحلي باهت كما كان — أفتح من اللوحات البيضاء أيضاً.
  Color get canvasViewport => brightness == Brightness.dark
      ? AppColors.darkCanvas
      : AppColors.navyWash.withValues(alpha: 0.6);

  /// لون ظل الورقة الناعم فوق مساحة العمل (أسود شفّاف ليلاً، كحلي خفيف نهاراً).
  ///
  /// ليلاً نرفع الشفافية قليلاً (`black38`) لأن مساحة العمل صارت أفتح
  /// (`#4A4A4A`)، فيبقى الظل مرئياً وتبقى الورقة تبدو "طافية" بأمان.
  Color get paperShadow => brightness == Brightness.dark
      ? Colors.black38
      : AppColors.navyShadow(0.16);

  /// نجاح / تحذير / خطر بتباين آمن فوق أي سطح في الوضعين.
  Color get success =>
      brightness == Brightness.dark ? AppColors.darkSuccess : AppColors.success;
  Color get warning =>
      brightness == Brightness.dark ? AppColors.darkWarning : AppColors.warning;
  Color get danger =>
      brightness == Brightness.dark ? AppColors.darkDanger : AppColors.danger;
}
