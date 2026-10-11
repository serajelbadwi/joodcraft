/// ترويسة الصفحة: اسم القرية بخط Amiri الذهبي + شارة المبادرة + المركز.
library;

import 'package:flutter/material.dart';

import '../../domain/village_validators.dart';
import '../village_theme.dart';

class VillageHeader extends StatelessWidget {
  const VillageHeader({super.key, required this.villageName});

  /// اسم القرية المعروض (يُعاد تحديثه بعد قبول الكود).
  final String villageName;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final double titleSize = width < 520
            ? 30
            : (width < 820 ? 38 : 48);
        return Column(
          key: const ValueKey<String>('village-header'),
          children: <Widget>[
            const Icon(
              Icons.location_city_rounded,
              color: VillageColors.tealSoft,
              size: 34,
            ),
            const SizedBox(height: VillageMetrics.space12),
            Text(
              villageName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: Theme.of(context).textTheme.displayLarge?.fontFamily,
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
                color: VillageColors.gold,
                height: 1.35,
              ),
            ),
            const SizedBox(height: VillageMetrics.space16),
            _OrnamentDivider(width: width < 520 ? 180 : 320),
            const SizedBox(height: VillageMetrics.space16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VillageMetrics.space20,
                vertical: VillageMetrics.space8,
              ),
              decoration: BoxDecoration(
                color: VillageColors.teal.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: VillageColors.tealSoft.withValues(alpha: 0.7),
                ),
              ),
              child: const Text(
                VillageText.appSubtitle,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: VillageColors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: VillageMetrics.space12),
            Text(
              VillageText.villageRegion,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14.5,
                color: VillageColors.muted,
                height: 1.7,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// فاصل زخرفي: خط ذهبي متلاشٍ — معيّن — خط.
class _OrnamentDivider extends StatelessWidget {
  const _OrnamentDivider({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Row(
        children: const <Widget>[
          Expanded(child: _GradientRule(reverse: false)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: VillageMetrics.space8),
            child: Icon(
              Icons.diamond_rounded,
              size: 10,
              color: VillageColors.gold,
            ),
          ),
          Expanded(child: _GradientRule(reverse: true)),
        ],
      ),
    );
  }
}

class _GradientRule extends StatelessWidget {
  const _GradientRule({required this.reverse});

  final bool reverse;

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = <Color>[
      VillageColors.gold.withValues(alpha: 0.05),
      VillageColors.gold.withValues(alpha: 0.75),
    ];
    return Container(
      height: 1.2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: reverse ? colors.reversed.toList() : colors,
        ),
      ),
    );
  }
}
