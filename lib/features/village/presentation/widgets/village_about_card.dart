/// «كلمة عن القرية» — تعريف موجز بالمبادرة والغرض من السجل.
library;

import 'package:flutter/material.dart';

import '../../domain/village_validators.dart';
import '../village_theme.dart';
import 'village_section_card.dart';

class VillageAboutCard extends StatelessWidget {
  const VillageAboutCard({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return VillageSectionCard(
      title: VillageText.aboutTitle,
      icon: Icons.groups_rounded,
      accent: VillageColors.tealSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            VillageText.aboutParagraph,
            style: text.bodyLarge,
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: VillageMetrics.space20),
          Wrap(
            spacing: VillageMetrics.space12,
            runSpacing: VillageMetrics.space12,
            children: const <Widget>[
              _FeatureChip(
                icon: Icons.folder_shared_rounded,
                label: 'سجل موحّد لكل الأهالي',
              ),
              _FeatureChip(
                icon: Icons.lock_rounded,
                label: 'بيانات مؤمَّنة ومقصورة على مسؤولي القرية',
              ),
              _FeatureChip(
                icon: Icons.travel_explore_rounded,
                label: 'قابل للتوسّع لقرى أخرى بنفس الكود',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// شارة ميزة صغيرة.
class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VillageMetrics.space16,
        vertical: VillageMetrics.space8,
      ),
      decoration: BoxDecoration(
        color: VillageColors.surfaceHigh,
        borderRadius: BorderRadius.circular(VillageMetrics.radiusSm),
        border: Border.all(color: VillageColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 17, color: VillageColors.goldSoft),
          const SizedBox(width: VillageMetrics.space8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              color: VillageColors.inkSoft,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
