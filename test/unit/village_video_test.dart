import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/village/domain/village_video.dart';

/// اختبارات نموذج الفيديو: قراءة صف `videos`، اشتقاق المعرّف من الرابط،
/// وقواعد النشر (المستقبلي مخفياً حتى موعده).
void main() {
  /// صف كاملاً كما يعيده PostgREST بأسماء الأعمدة في `supabase_village.sql`.
  Map<String, dynamic> fullRow() => <String, dynamic>{
        'id': 'vid-1',
        'village_id': 'v-1',
        'title': '  افتتاح المدرسة  ',
        'youtube_url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'youtube_id': 'dQw4w9WgXcQ',
        'description': ' وصف الفيديو ',
        'published_at': '2026-01-05T10:00:00Z',
        'created_at': '2026-01-05T10:00:00Z',
      };

  group('VillageVideo.fromRow', () {
    test('يقرأ الصف بأسماء الأعمدة في SQL ويقصّ الزوايد', () {
      final VillageVideo video = VillageVideo.fromRow(fullRow());

      expect(video.id, 'vid-1');
      expect(video.title, 'افتتاح المدرسة', reason: 'العنوان يُقصّ من طرفيه');
      expect(video.youtubeUrl, 'https://www.youtube.com/watch?v=dQw4w9WgXcQ');
      expect(video.youtubeId, 'dQw4w9WgXcQ');
      expect(video.description, 'وصف الفيديو');
      expect(video.publishedAt, isNotNull);
      expect(video.isPlayable, isTrue);
      expect(video.isPublished, isTrue);
    });

    test('youtube_id فارغ ⇒ يُستخرج من الرابط ولا يُسقط القسم', () {
      final Map<String, dynamic> row = fullRow()
        ..['youtube_id'] = ''
        ..['youtube_url'] = 'https://youtu.be/abc12345678?t=42';

      final VillageVideo video = VillageVideo.fromRow(row);

      expect(video.youtubeId, 'abc12345678');
      expect(video.isPlayable, isTrue);
    });

    test('رابط غير صالح ومسجَّل فارغ ⇒ بلا تضمين مع بقاء البطاقة قابلة للفتح',
        () {
      final Map<String, dynamic> row = fullRow()
        ..['youtube_id'] = ''
        ..['youtube_url'] = 'ليست رابطاً';

      final VillageVideo video = VillageVideo.fromRow(row);

      expect(video.isPlayable, isFalse);
      expect(video.watchUrl, 'ليست رابطاً', reason: 'الرابط الأصلي هو الفرج');
    });

    test('الصف الفارغ لا يُسقط العملية — قيم آمنة', () {
      final VillageVideo video = VillageVideo.fromRow(<String, dynamic>{});

      expect(video.id, isEmpty);
      expect(video.title, isEmpty);
      expect(video.youtubeId, isEmpty);
      expect(video.description, isNull);
      expect(video.publishedAt, isNull);
      expect(video.isPlayable, isFalse);
      expect(video.isPublished, isTrue, reason: 'غياب التاريخ يعني منشوراً');
    });

    test('تاريخ على صيغة DateTime يُقرأ كما هو', () {
      final DateTime published = DateTime(2026, 2, 3, 4, 5);
      final VillageVideo video =
          VillageVideo.fromRow(<String, dynamic>{'published_at': published});
      expect(video.publishedAt, published);
    });
  });

  group('VillageVideo — النشر والروابط', () {
    test('published_at مستقبلي ⇒ مجدول لا يُعرض', () {
      final VillageVideo video = VillageVideo.fromRow(<String, dynamic>{
        'title': 'قادم',
        'youtube_id': 'abc12345678',
        'published_at':
            DateTime.now().add(const Duration(days: 3)).toIso8601String(),
      });

      expect(video.isPublished, isFalse, reason: 'يبقى مخفياً حتى موعده');
    });

    test('embedUrl مبنيّ من المعرّف وwatchUrl هو الرابط الأصلي', () {
      const VillageVideo video = VillageVideo(
        id: 'vid-1',
        title: 'فيديو',
        youtubeUrl: 'https://youtu.be/abc12345678',
        youtubeId: 'abc12345678',
      );

      expect(video.embedUrl, 'https://www.youtube.com/embed/abc12345678');
      expect(video.watchUrl, 'https://youtu.be/abc12345678');
    });

    test('بلا رابط أصلي يُبنى watchUrl من المعرّف', () {
      const VillageVideo video = VillageVideo(
        id: 'vid-1',
        title: 'فيديو',
        youtubeUrl: '',
        youtubeId: 'abc12345678',
      );

      expect(video.watchUrl, 'https://www.youtube.com/watch?v=abc12345678');
    });

    test('toString يحمل العنوان والمعرّف لتسهيل التتبع', () {
      const VillageVideo video = VillageVideo(
        id: 'vid-1',
        title: 'افتتاح المدرسة',
        youtubeUrl: 'x',
        youtubeId: 'abc12345678',
      );
      expect(video.toString(), 'VillageVideo(افتتاح المدرسة — abc12345678)');
    });
  });

  group('VillageYoutube.idFromUrl', () {
    test('كل صيغ الروابط الرائجة تُعيد المعرّف نفسه', () {
      const String id = 'dQw4w9WgXcQ';
      const Map<String, String> urls = <String, String>{
        'https://www.youtube.com/watch?v=$id': id,
        'https://youtube.com/watch?v=$id&list=PL123&t=30s': id,
        'https://m.youtube.com/watch?v=$id': id,
        'https://music.youtube.com/watch?v=$id&feature=share': id,
        'https://youtu.be/$id': id,
        'https://youtu.be/$id?t=42': id,
        'https://www.youtube.com/embed/$id': id,
        'https://www.youtube.com/shorts/$id': id,
        'https://www.youtube.com/live/$id': id,
        'https://www.youtube.com/v/$id': id,
        id: id, // معرّف خام بلا https
      };

      urls.forEach((String url, String expected) {
        expect(VillageYoutube.idFromUrl(url), expected, reason: url);
      });
    });

    test('روابط خارج يوتيوب أو ناقصة تُعيد null', () {
      const List<String> invalid = <String>[
        '',
        '   ',
        'https://example.com/watch?v=dQw4w9WgXcQ',
        'https://www.youtube.com/feed/subscriptions',
        'https://www.youtube.com/playlist?list=PL1234567890',
        'ليست رابطاً',
      ];

      for (final String url in invalid) {
        expect(VillageYoutube.idFromUrl(url), isNull, reason: url);
      }
    });

    test('isValidId يرفض ما يخالف صيغة المعرّف', () {
      expect(VillageYoutube.isValidId('dQw4w9WgXcQ'), isTrue);
      expect(VillageYoutube.isValidId('  dQw4w9WgXcQ  '), isTrue);
      expect(VillageYoutube.isValidId(''), isFalse);
      expect(VillageYoutube.isValidId('abc'), isFalse, reason: 'قصير جداً');
      expect(
        VillageYoutube.isValidId('dQw4w9WgXcQ/extra'),
        isFalse,
        reason: 'رموز غير مسموحة',
      );
    });
  });
}
