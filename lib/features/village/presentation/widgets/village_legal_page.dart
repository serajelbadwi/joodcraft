/// قشرة مشتركة لصفحتَي الشروط والخصوصية: خلفية القرية الداكنة + ترويسة
/// بعنوان النصّ وإصداره + زر «رجوع» + أقسام النصّ في بطاقات مقروءة.
///
/// إبقاء التخطيط في مكان واحد يجعل الصفحتين متطابقتين تماماً ويمنع تكرار
/// التهيئة (الخلفية/التمرير/التوسيع) في كل صفحة على حدة.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../domain/village_legal.dart';
import '../village_theme.dart';

/// صفحة قانونية كاملة: [title] + [versionLabel] + [sections] + زر رجوع.
class VillageLegalPage extends StatelessWidget {
  const VillageLegalPage({
    super.key,
    required this.title,
    required this.version,
    required this.lead,
    required this.sections,
  });

  /// عنوان الصفحة (يظهر في الترويسة).
  final String title;

  /// إصدار النصّ المعتمد وقت التسجيل (يُحفظ مع كل تسجيل).
  final String version;

  /// مقدّمة تمهيدية تحت شارة الإصدار (الإطار القانوني بجملتين).
  final String lead;

  /// أقسام النصّ — كل قسم بطاقة مستقلة بعنوانها ونصّها.
  final List<VillageLegalSection> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VillageColors.background,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: _LegalGlow()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: VillageMetrics.maxContentWidth,
                ),
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VillageMetrics.space20,
                    vertical: VillageMetrics.space24,
                  ),
                  children: <Widget>[
                    const _BackBar(),
                    const SizedBox(height: VillageMetrics.space8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppAssets.amiriFont,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: VillageColors.gold,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: VillageMetrics.space4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: VillageMetrics.space12,
                        vertical: VillageMetrics.space4,
                      ),
                      decoration: BoxDecoration(
                        color: VillageColors.teal.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(
                          VillageMetrics.radiusSm,
                        ),
                        border: Border.all(
                          color: VillageColors.tealSoft.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        VillageLegal.versionLabel(version),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: VillageColors.inkSoft,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: VillageMetrics.space16),
                    Text(
                      lead,
                      style: const TextStyle(
                        fontSize: 14,
                        color: VillageColors.muted,
                        height: 1.9,
                      ),
                    ),
                    const SizedBox(height: VillageMetrics.space24),
                    for (final VillageLegalSection section in sections) ...<Widget>[
                      section,
                      const SizedBox(height: VillageMetrics.space16),
                    ],
                    const SizedBox(height: VillageMetrics.space16),
                    const _BackBar(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// قسم واحد: عنوان ذهبي + نصّه.
class VillageLegalSection extends StatelessWidget {
  const VillageLegalSection({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VillageMetrics.space20,
        vertical: VillageMetrics.space16,
      ),
      decoration: BoxDecoration(
        color: VillageColors.surface,
        borderRadius: BorderRadius.circular(VillageMetrics.radiusMd),
        border: Border.all(
          color: VillageColors.border.withValues(alpha: 0.8),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: VillageColors.goldSoft,
              height: 1.6,
            ),
          ),
          const SizedBox(height: VillageMetrics.space8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14.5,
              color: VillageColors.inkSoft,
              height: 1.9,
            ),
          ),
        ],
      ),
    );
  }
}

/// زر «رجوع» في أعلى وأسفل الصفحة.
class _BackBar extends StatelessWidget {
  const _BackBar();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        key: const ValueKey<String>('village-legal-back'),
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_forward_rounded, size: 20),
        label: const Text('رجوع'),
      ),
    );
  }
}

/// هالتان لونيتان خفيفتان تتّحدان مع خلفية الصفحة الرئيسية.
class _LegalGlow extends StatelessWidget {
  const _LegalGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -120,
            right: -90,
            child: _glow(VillageColors.teal, 380),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: _glow(VillageColors.gold, 340),
          ),
        ],
      ),
    );
  }

  Widget _glow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[
            color.withValues(alpha: 0.14),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
