/// إمضاء المطوّر: يعرض الصورة من الأصول، وإن تعذّرت فسطر إمضاء بخط Amiri.
///
/// الصورة الحالية `assets/images/serag_signature.jpeg` مُصوَّرة على خلفية
/// سوداء، و`JPEG` لا يدعم قناة الشفافية — فلو عُرضت كما هي لظهر مستطيل أسود
/// فوق خلفية الصفحة. لذلك تُمرَّر الصورة في مرشّح يجعل الإضاءة هي الشفافية
/// (أسود = شفاف، أبيض = معتم) فتندمج مع أي خلفية.
///
/// المجلد `assets/images/` مُعلن كأصل في `pubspec`، فلا حاجة لتعديل الأصول.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../domain/village_validators.dart';
import '../village_theme.dart';

class VillageSignature extends StatelessWidget {
  const VillageSignature({
    super.key,
    this.assetPath = _darkSignatureAsset,
    this.height = 78,
    this.showName = true,
  });

  /// الإمضاء الحالي في الأصول — خلفيته سوداء تتطلّب التصفية قبل العرض.
  static const String _darkSignatureAsset =
      'assets/images/serag_signature.jpeg';

  /// مرشّح «الإضاءة ← الشفافية»: القنوات تبقى كما هي، والشفافية = الإضاءة.
  static const List<double> _luminanceToAlpha = <double>[
    1,
    0,
    0,
    0,
    0, // الأحمر كما هو
    0,
    1,
    0,
    0,
    0, // الأخضر كما هو
    0,
    0,
    1,
    0,
    0, // الأزرق كما هو
    0.2126,
    0.7152,
    0.0722,
    0,
    0, // الشفافية = إضاءة Rec.709
  ];

  /// مسار صورة الإمضاء داخل الحزمة.
  final String assetPath;

  /// ارتفاع الصورة عند وجودها.
  final double height;

  /// إظهار الاسم أسفل/جانب الإمضاء.
  final bool showName;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey<String>('village-signature'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildImage(),
          if (showName) ...<Widget>[
            const SizedBox(height: VillageMetrics.space8),
            SizedBox(
              width: 190,
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      VillageColors.gold.withValues(alpha: 0.05),
                      VillageColors.gold.withValues(alpha: 0.6),
                      VillageColors.gold.withValues(alpha: 0.05),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// صورة الإمضاء: مُصفّاة إن كانت خلفيتها سوداء، وإلا تُعرض كما هي.
  Widget _buildImage() {
    final Image image = Image.asset(
      assetPath,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (
        BuildContext context,
        Object error,
        StackTrace? stackTrace,
      ) =>
          const _SignatureFallback(),
    );
    if (assetPath != _darkSignatureAsset) {
      return image;
    }
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(_luminanceToAlpha),
      child: image,
    );
  }
}

/// الإمضاء البديل: الاسم بخط Amiri الذهبي بميل خفيف — يُشبه خط اليد الرسمي.
class _SignatureFallback extends StatelessWidget {
  const _SignatureFallback();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VillageMetrics.space16,
        vertical: VillageMetrics.space8,
      ),
      child: Text(
        VillageText.footerDeveloper,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: AppAssets.amiriFont,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
          color: VillageColors.goldSoft,
          letterSpacing: 0.6,
          height: 1.6,
        ),
      ),
    );
  }
}
