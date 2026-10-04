import 'package:flutter/material.dart';

import '../l10n/app_l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// شاشة موحّدة تُعرض للميزات التي لم تُنفَّذ مرحلتها بعد.
///
/// تُستخدم كـ Placeholder في الراوتر حتى لا تبقى المسارات معلّقة، وتُستبدل
/// تدريجياً بشاشات الميزة الحقيقية مع كل مرحلة من خارطة الطريق.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.phase,
  });

  final String title;
  final String description;
  final IconData icon;

  /// رقم المرحلة التي ستُنجز هذه الميزة فيها.
  final int phase;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Icon(icon,
                          color: Theme.of(context).colorScheme.primary,
                          size: 26),
                    ),
                    const SizedBox(width: AppTheme.space16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(title, style: text.headlineSmall),
                          const SizedBox(height: 4),
                          Text(
                            context.l10n?.commonComingSoonPhase(phase) ??
                                'قيد التنفيذ — المرحلة $phase',
                            style: text.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.goldDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space20),
                Divider(color: Theme.of(context).colorScheme.secondaryContainer),
                const SizedBox(height: AppTheme.space20),
                Text(
                  description,
                  style: text.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
