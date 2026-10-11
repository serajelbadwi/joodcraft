/// فيديو واحد كما يُخزَّن في جدول `public.videos` (يُضاف يدوياً من SQL Editor).
///
/// العمودان `youtube_url` و`youtube_id` يُحفظان معاً عن قصد: الرابط هو ما
/// يكتبه مسؤول القرية، والمعرّف هو ما يُبنى منه إطار التضمين. وإن غاب المعرّف
/// استُخرج من الرابط هنا (كما يستخرجه السيرفر في مظلة `videos_fill_youtube_id`)
/// فالقسم لا يسقط أبداً بسبب صف ناقص.
library;

import 'package:flutter/foundation.dart';

@immutable
class VillageVideo {
  const VillageVideo({
    required this.id,
    required this.title,
    required this.youtubeUrl,
    required this.youtubeId,
    this.description,
    this.publishedAt,
  });

  /// بناء من صف PostgREST — قراءة **متسامحة**: حقل ناقص لا يُسقط القسم كلّه.
  factory VillageVideo.fromRow(Map<String, dynamic> row) {
    final Object? rawDate = row['published_at'];
    final String url = '${row['youtube_url'] ?? ''}'.trim();
    final String storedId = '${row['youtube_id'] ?? ''}'.trim();
    final String description = '${row['description'] ?? ''}'.trim();
    return VillageVideo(
      id: '${row['id'] ?? ''}',
      title: '${row['title'] ?? ''}'.trim(),
      youtubeUrl: url,
      youtubeId:
          storedId.isNotEmpty ? storedId : (VillageYoutube.idFromUrl(url) ?? ''),
      description: description.isEmpty ? null : description,
      publishedAt: rawDate is DateTime
          ? rawDate
          : (rawDate is String ? DateTime.tryParse(rawDate) : null),
    );
  }

  /// معرّف الصف (uuid).
  final String id;

  /// العنوان المعروض فوق الفيديو.
  final String title;

  /// الرابط كما أُدخل (‎watch?v=…‎ أو `youtu.be/…` أو `shorts/…`).
  final String youtubeUrl;

  /// معرّف الفيديو داخل يوتيوب — أساس إطار التضمين.
  final String youtubeId;

  /// وصف اختياري أسفل العنوان.
  final String? description;

  /// موعد النشر — تاريخٌ مستقبلي يعني مخفياً حتى موعده.
  final DateTime? publishedAt;

  /// هل المعرّف صالحاً لبناء إطار تضمين؟
  bool get isPlayable => VillageYoutube.isValidId(youtubeId);

  /// هل الفيديو منشور فعلاً؟ (غياب التاريخ أو سبقه الزمن ⇒ منشور).
  bool get isPublished {
    final DateTime? at = publishedAt;
    return at == null || !at.isAfter(DateTime.now());
  }

  /// رابط التضمين داخل الصفحة (`https://www.youtube.com/embed/…`) — لا يُستعمل
  /// إلا بعد [isPlayable].
  String get embedUrl => VillageYoutube.embedUrl(youtubeId);

  /// رابط المشاهدة على يوتيوب — الرابط الأصلي، أو رابط مبنيّ من المعرّف.
  String get watchUrl {
    if (youtubeUrl.isNotEmpty) return youtubeUrl;
    return isPlayable ? VillageYoutube.watchUrl(youtubeId) : '';
  }

  @override
  String toString() => 'VillageVideo($title — $youtubeId)';
}

/// صيغ روابط يوتيوب ومعرّفات الفيديو — مصدر واحد للتحويل في الواجهة.
abstract final class VillageYoutube {
  const VillageYoutube._();

  /// صيغة المعرّف المقبولة — نفسها المنطق المستخرج في `videos_fill_youtube_id`.
  static final RegExp idPattern = RegExp(r'^[A-Za-z0-9_-]{6,20}$');

  /// هل [raw] معرّف صالح؟
  static bool isValidId(String raw) => idPattern.hasMatch(raw.trim());

  /// رابط التضمين داخل الصفحة.
  static String embedUrl(String id) =>
      'https://www.youtube.com/embed/${id.trim()}';

  /// رابط المشاهدة المباشر.
  static String watchUrl(String id) =>
      'https://www.youtube.com/watch?v=${id.trim()}';

  /// استخراج المعرّف من أي صيغة رائجة — أو `null` إن لم يحمل الرابط معرّفاً.
  ///
  /// الصيغ المغطّاة: `youtu.be/ID` و`watch?v=ID` و`/embed/ID` و`/shorts/ID`
  /// و`/live/ID` و`/v/ID`، مع أي معاملات إضافية (`?t=30&list=…`)، إضافة إلى
  /// المعرّف الخام نفسه (بدون `https`).
  static String? idFromUrl(String raw) {
    final String value = raw.trim();
    if (value.isEmpty) return null;
    // معرّف خام — أسرع طريق وأكثرها شيوعاً عند اللصق.
    if (idPattern.hasMatch(value)) return value;

    final Uri? uri = Uri.tryParse(value);
    if (uri == null) return null;

    final String host = uri.host.toLowerCase();
    if (host == 'youtu.be' || host.endsWith('.youtu.be')) {
      final String id = uri.pathSegments.isEmpty ? '' : uri.pathSegments.first;
      return isValidId(id) ? id.trim() : null;
    }
    if (host == 'youtube.com' || host.endsWith('.youtube.com')) {
      final String? v = uri.queryParameters['v'];
      if (v != null && isValidId(v)) return v.trim();

      final List<String> segments = uri.pathSegments;
      const Set<String> idPaths = <String>{
        'embed',
        'shorts',
        'live',
        'v',
        'e',
      };
      if (segments.length >= 2 && idPaths.contains(segments.first)) {
        final String id = segments[1];
        if (isValidId(id)) return id.trim();
      }
    }
    return null;
  }
}
