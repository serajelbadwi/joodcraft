/// تضمين فيديو يوتيوب داخل الصفحة — وسم `iframe` حقيقي على الويب، وبطاقة
/// بديلة في أي بيئة أخرى (اختبارات/سطح مكتب) فلا تُكسر الشاشة.
///
/// لماذا منصّة عرض؟ لأن `HtmlElementView` متوفر على الويب وحده، بينما تُبنى
/// الصفحة لكل المنصات (التحليل والاختبارات) — نفس نهج قسم الخريطة تمامًا.
///
/// نسبة الإطار 16:9 كما اعتادت يوتيوب، وسطحه أسود ليبقى الفيديو أول ما يُرى.
library;

import 'package:flutter/material.dart';

import '../../domain/village_validators.dart';
import '../../domain/village_video.dart';
import '../village_theme.dart';
import 'village_video_embed_stub.dart'
    if (dart.library.js_interop) 'village_video_embed_web.dart' as impl;

/// إطار فيديو واحد.
class VillageVideoEmbed extends StatelessWidget {
  const VillageVideoEmbed({super.key, required this.video});

  /// الفيديو المعروض.
  final VillageVideo video;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      width: double.infinity,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        // معرّف ناقص/بلا صيغة ⇒ لا نبني iframe برابط باطل، بل توضيح بدل الفيديو.
        child: video.isPlayable
            ? impl.buildVideoEmbed(
                embedUrl: video.embedUrl,
                youtubeId: video.youtubeId,
              )
            : const _VideoNotEmbeddable(),
      ),
    );
  }
}

/// توضيح ظهوره عند غياب معرّف صالح لل삽ج (بيانات ناقصة من مدخل الصف).
class _VideoNotEmbeddable extends StatelessWidget {
  const _VideoNotEmbeddable();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[VillageColors.surfaceHigh, VillageColors.surface],
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(VillageMetrics.space16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.smart_display_rounded,
                color: VillageColors.goldSoft,
                size: 34,
              ),
              SizedBox(height: VillageMetrics.space8),
              Text(
                VillageText.videosEmbedUnavailable,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: VillageColors.inkSoft,
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
