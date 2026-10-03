import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_l10n.dart';
import '../locale/app_locale.dart';
import '../locale/locale_controller.dart';

/// منتقي اللغة (🌐) — قائمة منسدلة بكل اللغات المدعومة بأسمائها الأصلية.
///
/// يقرأ اللغة الحالية من [LocaleController] ويضبطها عند الاختيار، فيُعيد
/// `MaterialApp` البناء باللغة والاتجاه الجديدين فوراً بلا إعادة تشغيل. اسم
/// اللغة يُعرض **بلغتها الأصلية** دائماً حتى يجدها المستخدم مهما كانت لغة
/// الواجهة الحالية.
class LanguageMenuButton extends StatelessWidget {
  const LanguageMenuButton({super.key, this.showLabel = false});

  /// إظهار اسم اللغة الحالية بجانب الأيقونة (مناسب لشاشة الإعدادات).
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final LocaleController controller = context.watch<LocaleController>();
    final AppLocale current = controller.appLocale;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String tooltip = context.l10n?.languageTooltip ?? 'تغيير اللغة';

    return PopupMenuButton<AppLocale>(
      tooltip: tooltip,
      initialValue: current,
      position: PopupMenuPosition.under,
      onSelected: (AppLocale value) => controller.setLocale(value.locale),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<AppLocale>>[
        for (final AppLocale entry in supportedAppLocales)
          PopupMenuItem<AppLocale>(
            value: entry,
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 20,
                  child: entry.code == current.code
                      ? Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: scheme.primary,
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.nativeName,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.translate_rounded,
              size: 21,
              color: scheme.onSurfaceVariant,
            ),
            if (showLabel) ...<Widget>[
              const SizedBox(width: 8),
              Text(
                current.nativeName,
                style: TextStyle(fontSize: 13, color: scheme.onSurface),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.arrow_drop_down_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
