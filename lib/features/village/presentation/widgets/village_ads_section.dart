/// قسم «إعلانات»: شبكة صور كبيرة فقط — بلا نصّ ولا زرّ ولا اسم معلن داخل
/// البطاقة. الضغط على أي صورة يفتح نافذة التفاصيل: الصورة كاملة + العنوان +
/// رقم المعلن وزرّ الاتصال + رابط اختياري + إغلاق (X).
///
/// * **الصور من Google Drive تعمل هنا**: `VillageAd.fromRow` يطبّع رابط صفحة
///   العرض إلى رابط المُصغّرة المباشر قبل أن يصل إلى هذا القسم، فلا تعرف
///   البطاقة شيئاً عن درايف — وكل رابط صورة يُعرض بـ`Image.network`
///   (`<img>` على الويب) فلا تمنعه قيود CORS.
/// * **فشل تحميل الصورة لا يُسقط الإعلان**: تحلّ محلّها بقعة داكنة بأيقونة،
///   ويبقى الإعلان قابلاً للضغط لعرض تفاصيله في النافذة.
/// * **الشبكة تتكيف مع العرض**: عمودٌ على الموبايل، واثنان على التابلت،
///   وثلاثة على الديسكتوب — والصورة تملأ البطاقة بنسبة 4:3.
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

  /// عدد الأعمدة حسب العرض المتاح: موبايل (1) ← تابلت (2) ← ديسكتوب (3).
  static int _columnCount(double width) {
    if (width >= 900) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return VillageSectionCard(
      key: const ValueKey<String>('village-ads-section'),
      // «إعلانات» فقط — بلا «القرية» وبلا سطر توضيحي.
      title: 'إعلانات',
      icon: Icons.campaign_rounded,
      accent: VillageColors.gold,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final int columns = _columnCount(constraints.maxWidth);
          const double spacing = VillageMetrics.space16;
          final double cardWidth =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: <Widget>[
              for (final VillageAd ad in ads)
                SizedBox(
                  width: cardWidth,
                  child: _AdThumb(ad: ad),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// بطاقة إعلان: **صورة فقط** بنسبة 4:3 تملأها، والضغط يفتح التفاصيل.
class _AdThumb extends StatelessWidget {
  const _AdThumb({required this.ad});

  final VillageAd ad;

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = ad.imageUrl;
    return Material(
      key: ValueKey<String>('village-ad-${ad.id}'),
      color: VillageColors.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VillageMetrics.radiusMd),
        side: const BorderSide(color: VillageColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showDialog<void>(
          context: context,
          builder: (BuildContext context) => _AdDialog(ad: ad),
        ),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: imageUrl != null
              ? _AdImage(url: imageUrl, fit: BoxFit.cover)
              : const _AdImageFallback(),
        ),
      ),
    );
  }
}

/// نافذة تفاصيل الإعلان: الصورة كاملة + العنوان + الاتصال + الرابط + إغلاق.
class _AdDialog extends StatelessWidget {
  const _AdDialog({required this.ad});

  final VillageAd ad;

  /// أقصى عرض للنافذة — تبقى متمركزة ومقروءة على كل الشاشات.
  static const double _maxWidth = 520;

  /// أقصى ارتفاع لصورة النافذة (العرض يملأها والقصّ `contain` يُظهرها كاملة).
  static const double _imageHeight = 320;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String? phone = ad.contactPhone;
    final String? url = ad.contactUrl?.trim();
    final String? imageUrl = ad.imageUrl;
    return Dialog(
      backgroundColor: VillageColors.surfaceHigh,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VillageMetrics.radiusMd),
        side: const BorderSide(color: VillageColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // العنوان + زرّ الإغلاق (X).
            Row(
              children: <Widget>[
                const SizedBox(width: VillageMetrics.space16),
                Expanded(
                  child: Text(
                    ad.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleLarge,
                  ),
                ),
                IconButton(
                  key: const ValueKey<String>('village-ad-dialog-close'),
                  tooltip: 'إغلاق',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            // الصورة كاملة (`contain` لا تقصّ من الإعلان المطبوع).
            SizedBox(
              height: _imageHeight,
              child: imageUrl != null
                  ? _AdImage(url: imageUrl, fit: BoxFit.contain)
                  : const _AdImageFallback(),
            ),
            if (phone != null) ...<Widget>[
              const SizedBox(height: VillageMetrics.space12),
              Text(
                phone,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: VillageColors.gold,
                ),
              ),
            ],
            if (phone != null || (url?.isNotEmpty ?? false)) ...<Widget>[
              Padding(
                padding: const EdgeInsets.all(VillageMetrics.space16),
                child: Wrap(
                  spacing: VillageMetrics.space8,
                  runSpacing: VillageMetrics.space8,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    if (phone != null)
                      FilledButton.icon(
                        key: const ValueKey<String>('village-ad-dialog-call'),
                        onPressed: () =>
                            VillageExternalLink.open('tel:$phone'),
                        icon: const Icon(Icons.phone_rounded, size: 18),
                        label: const Text(VillageText.adsCall),
                      ),
                    if (url != null && url.isNotEmpty)
                      FilledButton.icon(
                        key: const ValueKey<String>('village-ad-dialog-link'),
                        onPressed: () => VillageExternalLink.open(url),
                        icon: const Icon(
                          Icons.open_in_new_rounded,
                          size: 18,
                        ),
                        label: const Text('رابط'),
                      ),
                  ],
                ),
              ),
            ] else
              const SizedBox(height: VillageMetrics.space16),
          ],
        ),
      ),
    );
  }
}

/// صورة الإعلان — وشبكة إن فشل تحميلها (رابط ميت/غير مشترك في Drive).
class _AdImage extends StatelessWidget {
  const _AdImage({required this.url, required this.fit});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: double.infinity,
      height: double.infinity,
      fit: fit,
      filterQuality: FilterQuality.medium,
      // فشل الصورة لا يُسقط البطاقة: بقعة داكنة بأيقونة بدلها.
      errorBuilder: (
        BuildContext context,
        Object error,
        StackTrace? stackTrace,
      ) =>
          const _AdImageFallback(failed: true),
    );
  }
}

/// موضع الصورة حين تغيب أو تفشل: لوح داكن بأيقونة فقط (بلا نصّ).
class _AdImageFallback extends StatelessWidget {
  const _AdImageFallback({this.failed = false});

  /// هل فشل تحميل صورة موجودة أم غابت أصلاً (لا حقل صورة)؟
  final bool failed;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: VillageColors.surface.withValues(alpha: 0.6),
      child: Icon(
        failed ? Icons.broken_image_outlined : Icons.campaign_outlined,
        size: 34,
        color: VillageColors.muted,
      ),
    );
  }
}
