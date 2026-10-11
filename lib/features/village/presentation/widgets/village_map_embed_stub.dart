/// نسخة غير الويب: لا متصفح ⇒ بطاقة بديلة تعرض اسم الموقع وسببه.
library;

import 'package:flutter/material.dart';

import '../village_theme.dart';

Widget buildMapEmbed({
  required String iframeUrl,
  required String query,
  required double height,
}) =>
    const _MapPlaceholder();

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            VillageColors.surfaceHigh,
            VillageColors.surface,
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.public_rounded,
              color: VillageColors.tealSoft,
              size: 34,
            ),
            SizedBox(height: VillageMetrics.space12),
            Text(
              'الخريطة التفاعلية تظهر في نسخة الويب',
              style: TextStyle(
                fontSize: 14,
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
