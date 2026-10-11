/// خطوة النجاح: تأكيد التسجيل + دعوة لتحميل تطبيق «فرح».
library;

import 'package:flutter/material.dart';

import '../../domain/village_validators.dart';
import '../village_theme.dart';
import 'village_external_link.dart';

/// رابط تحميل تطبيق «فرح» — يُمرَّر وقت البناء:
/// ```bash
/// flutter build web -t lib/main_village.dart \
///   --dart-define=FARAH_APK_URL=https://example.com/farah.apk
/// ```
/// وبلا الرابط تُعرض دعوة «قريباً» بلا زر معطّل يوهم المستخدم.
const String kFarahApkUrl = String.fromEnvironment('FARAH_APK_URL');

class VillageSuccessCard extends StatelessWidget {
  const VillageSuccessCard({
    super.key,
    required this.memberName,
    required this.villageName,
    required this.onRegisterAnother,
    this.farahApkUrl = kFarahApkUrl,
  });

  /// اسم المُسجَّل — يظهر في رسالة الترحيب.
  final String memberName;

  /// اسم القرية.
  final String villageName;

  /// إعادة التدفّق لتسجيل فرد آخر.
  final VoidCallback onRegisterAnother;

  /// رابط تحميل التطبيق (فارغ ⇒ «قريباً»).
  final String farahApkUrl;

  @override
  Widget build(BuildContext context) {
    final bool hasApk = farahApkUrl.trim().isNotEmpty;
    return Column(
      key: const ValueKey<String>('village-success'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VillageColors.success.withValues(alpha: 0.14),
              border: Border.all(
                color: VillageColors.success.withValues(alpha: 0.55),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: VillageColors.success,
              size: 42,
            ),
          ),
        ),
        const SizedBox(height: VillageMetrics.space20),
        Text(
          VillageText.successTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: VillageMetrics.space12),
        Text(
          VillageText.successBody(memberName, villageName),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15.5,
            color: VillageColors.inkSoft,
            height: 1.9,
          ),
        ),
        const SizedBox(height: VillageMetrics.space24),
        Container(
          padding: const EdgeInsets.all(VillageMetrics.space20),
          decoration: BoxDecoration(
            color: VillageColors.teal.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(VillageMetrics.radiusLg),
            border: Border.all(
              color: VillageColors.tealSoft.withValues(alpha: 0.55),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.celebration_rounded,
                    color: VillageColors.goldSoft,
                    size: 22,
                  ),
                  const SizedBox(width: VillageMetrics.space12),
                  Text(
                    VillageText.farahTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: VillageMetrics.space12),
              const Text(
                VillageText.farahBody,
                style: TextStyle(
                  fontSize: 14,
                  color: VillageColors.inkSoft,
                  height: 1.85,
                ),
              ),
              const SizedBox(height: VillageMetrics.space16),
              if (hasApk)
                FilledButton.icon(
                  key: const ValueKey<String>('village-farah-cta'),
                  onPressed: () => VillageExternalLink.open(farahApkUrl),
                  icon: const Icon(Icons.download_rounded, size: 20),
                  label: const Text(VillageText.farahCta),
                )
              else
                Row(
                  children: const <Widget>[
                    Icon(
                      Icons.schedule_rounded,
                      color: VillageColors.goldSoft,
                      size: 19,
                    ),
                    SizedBox(width: VillageMetrics.space8),
                    Expanded(
                      child: Text(
                        VillageText.farahSoon,
                        style: TextStyle(
                          fontSize: 13,
                          color: VillageColors.muted,
                          height: 1.7,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: VillageMetrics.space24),
        OutlinedButton.icon(
          key: const ValueKey<String>('village-register-another'),
          onPressed: onRegisterAnother,
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 19),
          label: const Text(VillageText.createAnother),
        ),
      ],
    );
  }
}
