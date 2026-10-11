/// بطاقة قسم موحّدة في صفحة القرية (عنوان + أيقونة + فاصل + محتوى).
///
/// توحيد الغلاف يجعل أقسام الصفحة (كلمة عن القرية، الموقع، التسجيل…) متسقة
/// بصرياً بلا تكرار كود زخرفي في كل قسم.
library;

import 'package:flutter/material.dart';

import '../village_theme.dart';

class VillageSectionCard extends StatelessWidget {
  const VillageSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.accent = VillageColors.gold,
    this.trailing,
    this.subtitle,
  });

  /// عنوان القسم (يُعرض بخط Amiri).
  final String title;

  /// أيقونة القسم.
  final IconData icon;

  /// محتوى القسم.
  final Widget child;

  /// لون لمسة القسم (ذهبي افتراضياً).
  final Color accent;

  /// عنصر اختياري في نهاية صف العنوان.
  final Widget? trailing;

  /// سطر توضيحي أسفل العنوان.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(VillageMetrics.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(VillageMetrics.radiusMd),
                    border: Border.all(color: accent.withValues(alpha: 0.45)),
                  ),
                  child: Icon(icon, color: accent, size: 22),
                ),
                const SizedBox(width: VillageMetrics.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: text.headlineSmall,
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: VillageMetrics.space4),
                        Text(subtitle!, style: text.bodySmall),
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: VillageMetrics.space16),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    accent.withValues(alpha: 0.55),
                    accent.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
            const SizedBox(height: VillageMetrics.space16),
            child,
          ],
        ),
      ),
    );
  }
}
