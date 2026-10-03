import 'package:flutter/material.dart';

/// مسار شعار JoodCraft الرسمي (ملف الأصل) المستخدم في واجهات التطبيق.
///
/// ملاحظة هندسية: ملف الشعار داكن الألوان ومصمَّم لخلفية فاتحة، لذا عند وضعه
/// على الخلفيات الكحلية الداكنة يُعرض على لوح فاتح (`onDark`) ليبقى واضحاً.
const String kJoodCraftLogoAsset = 'assets/images/LOGO.png';

/// الشعار الرسمي لمنصة JoodCraft من ملف الأصل `assets/images/LOGO.png`،
/// بديلاً عن الشعار الذي كان يُرسم برمجياً.
class JoodCraftLogo extends StatelessWidget {
  const JoodCraftLogo({super.key, this.size = 48, this.onDark = false});

  /// ارتفاع الشعار بالبكسل (تُحفظ نسبة الأبعاد تلقائياً).
  final double size;

  /// إن كان الشعار موضوعاً على خلفية كحلية داكنة.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final Widget image = Image.asset(
      kJoodCraftLogoAsset,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );

    if (!onDark) return image;

    // لوح فاتح خلف الشعار الداكن ليبقى مقروءاً على السطوح الكحلية.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: size * 0.26,
          vertical: size * 0.16,
        ),
        child: image,
      ),
    );
  }
}

/// ترويسة الهوية: الشعار الرسمي الكامل (يحوي الاسم والسطر التعريفي داخله).
///
/// استُبدل الرسم البرمجي (العلامة + نص «JoodCraft») بملف الشعار نفسه.
class JoodCraftWordmark extends StatelessWidget {
  const JoodCraftWordmark({
    super.key,
    this.markSize = 46,
    this.onDark = false,
    this.showTagline = true,
  });

  /// ارتفاع الشعار بالبكسل.
  final double markSize;

  /// إن كان الشعار موضوعاً على خلفية كحلية داكنة.
  final bool onDark;

  /// محفوظ للتوافق مع الشاشات القائمة؛ لم يعد مستخدماً لأن ملف الشعار
  /// يحوي الاسم والسطر التعريفي داخل الصورة.
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    return JoodCraftLogo(size: markSize, onDark: onDark);
  }
}
