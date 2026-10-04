import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_l10n.dart';
import '../theme/theme_controller.dart';

/// أيقونة تبديل المظهر (☀️ فاتح / 🌙 داكن) بنقرة واحدة.
///
/// تُوضع في الشريط العلوي؛ تقرأ حالتها من [ThemeController] فتتحدّث فور
/// التبديل، وتنقل إلى **عكس** المظهر المعروض حالياً دائماً (حتى لو كان
/// الوضع «حسب النظام») فلا يبدو النقر بلا أثر.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController theme = context.watch<ThemeController>();
    final bool dark = theme.isDark;
    return IconButton(
      tooltip: dark
          ? (context.l10n?.themeSwitchToLight ?? 'التبديل إلى المظهر الفاتح')
          : (context.l10n?.themeSwitchToDark ?? 'التبديل إلى المظهر الداكن'),
      onPressed: theme.toggle,
      icon: Icon(
        dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        key: ValueKey<bool>(dark),
        size: 21,
      ),
    );
  }
}
