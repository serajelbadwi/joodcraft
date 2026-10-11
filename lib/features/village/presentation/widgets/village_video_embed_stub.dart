/// نسخة غير الويب: لا متصفح ⇒ لا iframe، فتُعرض بطاقة بديلة أنيقة.
///
/// نفس منطق قسم الخريطة: الشاشة لا تُكسر، والفيديو يكتمل في نسخة الويب.
library;

import 'package:flutter/material.dart';

import '../village_theme.dart';

Widget buildVideoEmbed({
  required String embedUrl,
  required String youtubeId,
}) =>
    const _VideoPlaceholder();

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[VillageColors.surfaceHigh, VillageColors.surface],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.smart_display_rounded,
              color: VillageColors.tealSoft,
              size: 34,
            ),
            SizedBox(height: VillageMetrics.space8),
            Text(
              'الفيديو التفاعلي يظهر في نسخة الويب',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: VillageColors.inkSoft,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
