/// قسم «فيديوهات القرية»: بطاقات فيديوهات يوتيوب مخزَّنة في جدول `videos`.
///
/// التخطيط شبكة مرنة: عمودان على الشاشات العريضة وعمود واحد على الضيّقة،
/// وكل بطاقة **16:9** فوقها العنوان والوصف وزر الفتح على يوتيوب. القسم لا
/// يُبنى من الفراغ: الشاشة تعرضه فقط حين تعود قائمة الفيديوهات المنشورة،
/// فإخفاؤه عند الخدمة غير المتاحة أو الجدول غير المنشأ هو السلوك الأصيل.
library;

import 'package:flutter/material.dart';

import '../../domain/village_validators.dart';
import '../../domain/village_video.dart';
import '../village_theme.dart';
import 'village_external_link.dart';
import 'village_section_card.dart';
import 'village_video_embed.dart';

class VillageVideosSection extends StatelessWidget {
  const VillageVideosSection({super.key, required this.videos});

  /// الفيديوهات المنشورة — يรอَّها الشاشة من المستودع (الأحدث أولاً).
  final List<VillageVideo> videos;

  /// عرض العمود عند التوسّع يبدأ من هنا إلى عمودين.
  static const double _twoColumnsFrom = 720;

  @override
  Widget build(BuildContext context) {
    return VillageSectionCard(
      title: VillageText.videosTitle,
      icon: Icons.smart_display_rounded,
      accent: VillageColors.tealSoft,
      subtitle: VillageText.videosSubtitle,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double available = constraints.maxWidth;
          final double gap = VillageMetrics.space16;
          final bool wide =
              available.isFinite && available >= _twoColumnsFrom;
          final double width = wide ? (available - gap) / 2 : available;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: <Widget>[
              for (final VillageVideo video in videos)
                SizedBox(
                  width: width,
                  child: _VideoCard(video: video),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// بطاقة فيديو واحدة: الصندوق + العنوان + الوصف + زر يوتيوب.
class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.video});

  final VillageVideo video;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String? description = video.description;
    return Container(
      key: ValueKey<String>('village-video-${video.id}'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: VillageColors.surfaceHigh,
        borderRadius: BorderRadius.circular(VillageMetrics.radiusMd),
        border: Border.all(color: VillageColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          VillageVideoEmbed(video: video),
          Padding(
            padding: const EdgeInsets.all(VillageMetrics.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  video.title,
                  style: text.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description != null) ...<Widget>[
                  const SizedBox(height: VillageMetrics.space8),
                  Text(
                    description,
                    style: text.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: VillageMetrics.space8),
                TextButton.icon(
                  onPressed: video.watchUrl.isEmpty
                      ? null
                      : () => VillageExternalLink.open(video.watchUrl),
                  icon: const Icon(Icons.open_in_new_rounded, size: 17),
                  label: const Text(VillageText.videosOpenOnYoutube),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
