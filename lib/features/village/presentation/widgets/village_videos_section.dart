/// قسم «فيديوهات القرية»: مشغّل رئيسي لفيديو واحد فوق شريط اختيار أفقي
/// لبقية الفيديوهات — بدل شبكة أطراف تضمين تُبطئ الصفحة.
///
/// * **المشغّل الرئيسي**: بطاقة الفيديو المختار، و`AspectRatio` فيها يتبع
///   نسبة الفيديو (16:9 / 9:16 / 1:1 / 4:5) بعرض الحاوية كاملة على الويب
///   وعرض الشاشة على الموبايل.
/// * **الشريط**: مصغّرات لكل فيديو بنسبة حقيقية داخل صندوق ثابت الارتفاع،
///   عرض البطاقة على الويب حدّه 400px وما دونها عرض المتاح (الموبايل)؛
///   اللمس يبدّل الفيديو في المشغّل.
///
/// القسم لا يُبنى من الفراغ: الشاشة تعرضه فقط حين تعود قائمة الفيديوهات
/// المنشورة، فإخفاؤه عند الخدمة غير المتاحة هو السلوك الأصيل.
library;

import 'package:flutter/material.dart';

import '../../domain/village_validators.dart';
import '../../domain/village_video.dart';
import '../village_theme.dart';
import 'village_external_link.dart';
import 'village_section_card.dart';
import 'village_video_embed.dart';

class VillageVideosSection extends StatefulWidget {
  const VillageVideosSection({super.key, required this.videos});

  /// الفيديوهات المنشورة — يรอَّها الشاشة من المستودع (الأحدث أولاً).
  final List<VillageVideo> videos;

  @override
  State<VillageVideosSection> createState() => _VillageVideosSectionState();
}

class _VillageVideosSectionState extends State<VillageVideosSection> {
  /// موضع الفيديو المعروض حالياً في المشغّل الرئيسي.
  int _selected = 0;

  /// أقصى عرض لبطاقة الشريط على الويب — والموبايل يأخذ المتاح كاملاً.
  static const double _chipMaxWidth = 400;

  /// ارتفاع مصغّرة الشريط — ثابت يجمع بطاقات النِّسَب المختلفة.
  static const double _chipThumbHeight = 132;

  /// ارتفاع بطاقة الشريط كاملاً (المصغّرة + سطر العنوان).
  static const double _chipHeight = _chipThumbHeight + 58;

  @override
  Widget build(BuildContext context) {
    final List<VillageVideo> videos = widget.videos;
    final VillageVideo current = videos[_selected];
    return VillageSectionCard(
      title: VillageText.videosTitle,
      icon: Icons.smart_display_rounded,
      accent: VillageColors.tealSoft,
      subtitle: VillageText.videosSubtitle,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double available = constraints.maxWidth;
          final double chipWidth =
              available > _chipMaxWidth ? _chipMaxWidth : available;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _HeroPlayer(video: current),
              // شريط الاختيار يظهر مع تعدّد الفيديوهات فقط.
              if (videos.length > 1) ...<Widget>[
                const SizedBox(height: VillageMetrics.space12),
                SizedBox(
                  height: _chipHeight,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: videos.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(width: VillageMetrics.space12),
                    itemBuilder: (BuildContext context, int index) {
                      final VillageVideo video = videos[index];
                      return SizedBox(
                        width: chipWidth,
                        child: _VideoChip(
                          video: video,
                          selected: index == _selected,
                          onTap: () => setState(() => _selected = index),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// المشغّل الرئيسي: إطار الفيديو بنسبة نسبته + العنوان والوصف وزر يوتيوب.
class _HeroPlayer extends StatelessWidget {
  const _HeroPlayer({required this.video});

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
                Text(video.title, style: text.titleMedium),
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

/// مصغّرة في الشريط: صندوق أسود بنسبة الفيديو الحقيقية + العنوان. اللسها
/// يرفع الفيديو إلى المشغّل الرئيسي، والمختار يظهر بحدّ ذهبي.
class _VideoChip extends StatelessWidget {
  const _VideoChip({
    required this.video,
    required this.selected,
    required this.onTap,
  });

  final VillageVideo video;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color border =
        selected ? VillageColors.gold : VillageColors.border;
    return InkWell(
      key: ValueKey<String>('village-video-chip-${video.id}'),
      borderRadius: BorderRadius.circular(VillageMetrics.radiusMd),
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: VillageColors.surfaceHigh,
          borderRadius: BorderRadius.circular(VillageMetrics.radiusMd),
          border: Border.all(
            color: border,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              height: _VillageVideosSectionState._chipThumbHeight,
              child: ColoredBox(
                color: Colors.black,
                child: Center(
                  // نسبة الفيديو الحقيقية داخل صندوق ثابت — مثل مشغّل يوتيوب.
                  child: AspectRatio(
                    aspectRatio: video.aspect.ratio,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            VillageColors.surfaceHigh.withValues(alpha: 0.55),
                            VillageColors.surface.withValues(alpha: 0.9),
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        size: 30,
                        color: selected
                            ? VillageColors.gold
                            : VillageColors.inkSoft,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(VillageMetrics.space8),
              child: Text(
                video.title,
                style: const TextStyle(fontSize: 12.5, height: 1.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
