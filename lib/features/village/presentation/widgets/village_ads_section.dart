/// قسم «إعلانات القرية»: شبكة بطاقات إعلانات سارية الآن — صورة + عنوان +
/// وسيلة تواصل (هاتف أو رابط).
///
/// * **الصور من Google Drive تعمل هنا**: `VillageAd.fromRow` يطبّع رابط صفحة
///   العرض إلى رابط المُصغّرة المباشر قبل أن يصل إلى هذا القسم، فلا تعرف
///   البطاقة شيئاً عن درايف — وكل رابط صورة يُعرض بـ`Image.network`
///   (`<img>` على الويب) فلا تمنعه قيود CORS.
/// * **فشل تحميل الصورة لا يُسقط الإعلان**: تحلّ محلّها بطاقة توضيحية
///   وتبقى العنوان وأزرار التواصل ظاهرين — الإعلان يصل ل الأهالي ولو مات
///   الرابط.
///
/// القسم لا يُبنى من الفراغ: الشاشة تعرضه فقط حين تعود إعلانات سارية،
/// وإخفاؤه عند الخدمة غير المتاحة أو فشل الجلب هو السلوك الأصيل (زينة لا
/// تعطيل).
library;

import 'package:flutter/material.dart';

import '../../domain/village_ad.dart';
import '../../domain/village_validators.dart';
import '../village_theme.dart';
import 'village_external_link.dart';
import 'village_section_card.dart';

class VillageAdsSection extends StatelessWidget {
  const VillageAdsSection({super.key, required this.ads});

  /// الإعلانات السارية — يجمعها الشاشة من المستودع (الأحدث أولاً).
  final List<VillageAd> ads;

  @override
  Widget build(BuildContext context) {
    return VillageSectionCard(
      key: const ValueKey<String>('village-ads-section'),
      title: VillageText.adsTitle,
      icon: Icons.campaign_rounded,
      accent: VillageColors.gold,
      subtitle: VillageText.adsSubtitle,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double available = constraints.maxWidth;
          // عمودان على العرض الواسع (يبقى لكل إعلان ≈ 300px+) وعمود واحد
          // على الضيق (الموبايل).
          final double cardWidth =
              available >= 700 ? (available - VillageMetrics.space16) / 2
                  : available;
          return Wrap(
            spacing: VillageMetrics.space16,
            runSpacing: VillageMetrics.space16,
            children: <Widget>[
              for (final VillageAd ad in ads)
                SizedBox(
                  width: cardWidth,
                  child: _AdCard(ad: ad),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// بطاقة إعلان واحد: صورة (إن وُجدت) + عنوان + أزرار التواصل.
class _AdCard extends StatelessWidget {
  const _AdCard({required this.ad});

  final VillageAd ad;

  /// ارتفاع ثابت لصورة الإعلان — العرض يملأ البطاقة والقصّ `cover`.
  static const double _imageHeight = 170;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String? imageUrl = ad.imageUrl;
    return Container(
      key: ValueKey<String>('village-ad-${ad.id}'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: VillageColors.surfaceHigh,
        borderRadius: BorderRadius.circular(VillageMetrics.radiusMd),
        border: Border.all(color: VillageColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (imageUrl != null)
            _AdImage(url: imageUrl, height: _imageHeight)
          else
            const _AdImageFallback(height: _imageHeight, withoutImage: true),
          Padding(
            padding: const EdgeInsets.all(VillageMetrics.space12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  ad.title,
                  style: text.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (ad.contactPhone != null || ad.contactUrl != null) ...<Widget>[
                  const SizedBox(height: VillageMetrics.space4),
                  Wrap(
                    spacing: VillageMetrics.space4,
                    runSpacing: VillageMetrics.space4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      if (ad.contactPhone != null)
                        TextButton.icon(
                          key: ValueKey<String>(
                            'village-ad-call-${ad.id}',
                          ),
                          onPressed: () =>
                              VillageExternalLink.open('tel:${ad.contactPhone}'),
                          icon: const Icon(Icons.phone_rounded, size: 16),
                          label: Text(VillageText.adsCall),
                        ),
                      if (ad.contactUrl != null)
                        TextButton.icon(
                          key: ValueKey<String>(
                            'village-ad-link-${ad.id}',
                          ),
                          onPressed: ad.contactUrl!.trim().isEmpty
                              ? null
                              : () => VillageExternalLink.open(
                                    ad.contactUrl!.trim(),
                                  ),
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          label: const Text(VillageText.adsOpenLink),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// صورة الإعلان — وشبكة إن فشل تحميلها (رابط ميت/غير مشترك في Drive).
class _AdImage extends StatelessWidget {
  const _AdImage({required this.url, required this.height});

  final String url;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      // فشل الصورة يُخفيها ويُبقي الإعلان (عنوانه وأرقامه تصل على كل حال).
      errorBuilder: (
        BuildContext context,
        Object error,
        StackTrace? stackTrace,
      ) =>
          _AdImageFallback(height: height),
    );
  }
}

/// موضع الصورة حين تغيب أو تفشل: لوح داكن بأيقونة حمل.
class _AdImageFallback extends StatelessWidget {
  const _AdImageFallback({required this.height, this.withoutImage = false});

  final double height;

  /// هل غابت الصورة أصلاً (لا حقل صورة) أم فشل تحميلها؟ — يُظهر توضيحاً
  /// في الحالة الثانية حتى يعرف مسؤول القرية أن الرابط يحتاج إصلاحاً.
  final bool withoutImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: VillageColors.surface.withValues(alpha: 0.6),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            withoutImage
                ? Icons.campaign_outlined
                : Icons.broken_image_outlined,
            size: 30,
            color: VillageColors.muted,
          ),
          if (!withoutImage) ...<Widget>[
            const SizedBox(height: VillageMetrics.space4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: VillageMetrics.space12),
              child: Text(
                VillageText.adsImageUnavailable,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: VillageColors.muted,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
