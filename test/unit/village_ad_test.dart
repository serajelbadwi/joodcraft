import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/village/domain/village_ad.dart';

void main() {
  group('VillageAd.fromRow', () {
    test('يقرأ الصف الكامل ويطبّع الفراغات', () {
      final VillageAd ad = VillageAd.fromRow(<String, dynamic>{
        'id': 'ad-1',
        'village_id': 'v-1',
        'title': '  إعلان المخبز  ',
        'image_url': ' https://cdn.test/a.png ',
        'contact_phone': ' 01012345678 ',
        'contact_url': '',
        'starts_at': '2026-01-01T00:00:00+00:00',
        'ends_at': '2026-12-31T23:59:59+00:00',
        'is_active': false,
        'created_at': '2025-12-30T10:00:00+00:00',
      });

      expect(ad.id, 'ad-1');
      expect(ad.villageId, 'v-1');
      expect(ad.title, 'إعلان المخبز');
      expect(ad.imageUrl, 'https://cdn.test/a.png');
      expect(ad.contactPhone, '01012345678');
      // خانة فارغة تُقرأ `null` لا نصّاً فارغاً.
      expect(ad.contactUrl, isNull);
      expect(ad.startsAt, isNotNull);
      expect(ad.endsAt, isNotNull);
      expect(ad.isActive, isFalse);
      expect(ad.createdAt, isNotNull);
    });

    test('الصف الأدنى: الحقول الناقصة لا تسقط النموذج', () {
      final VillageAd ad = VillageAd.fromRow(<String, dynamic>{
        'id': 'ad-2',
        'village_id': 'v-1',
        'title': 'إعلان بسيط',
      });

      expect(ad.imageUrl, isNull);
      expect(ad.startsAt, isNull);
      expect(ad.endsAt, isNull);
      // غياب العمود يعني المفعَّل افتراضياً (المتوقع في الإدراج).
      expect(ad.isActive, isTrue);
      expect(ad.isLiveNow, isTrue);
    });

    test('قيمة is_active غير المنطقية تُقرأ `false`', () {
      final VillageAd ad = VillageAd.fromRow(<String, dynamic>{
        'id': 'ad-3',
        'village_id': 'v-1',
        'title': 'إعلان',
        'is_active': 'yes',
      });
      expect(ad.isActive, isFalse);
    });

    test('رابط Google Drive يُطبَّع إلى صورة مباشرة عند القراءة', () {
      final VillageAd ad = VillageAd.fromRow(<String, dynamic>{
        'id': 'ad-4',
        'village_id': 'v-1',
        'title': 'إعلان بdrive',
        'image_url':
            'https://drive.google.com/file/d/1AbC_dEf9ijkLnOp/view?usp=sharing',
      });

      expect(
        ad.imageUrl,
        'https://drive.google.com/thumbnail?id=1AbC_dEf9ijkLnOp&sz=w1000',
        reason: 'صفوف قديمة بصفحة العرض تُصلح قراءةً بلا تنظيف يدوي',
      );
    });

    test('رابط دلو مباشر لا يتأثر بالتطبيع', () {
      final VillageAd ad = VillageAd.fromRow(<String, dynamic>{
        'id': 'ad-5',
        'village_id': 'v-1',
        'title': 'إعلان بالدلو',
        'image_url': 'https://cdn.test/village-ads/poster.png',
      });
      expect(ad.imageUrl, 'https://cdn.test/village-ads/poster.png');
    });
  });

  group('نافذة العرض isActiveAt', () {
    final DateTime start = DateTime(2026, 3, 1);
    final DateTime end = DateTime(2026, 3, 31);

    VillageAd build({
      bool isActive = true,
      DateTime? startsAt,
      DateTime? endsAt,
    }) =>
        VillageAd(
          id: 'a',
          villageId: 'v',
          title: 'ت',
          isActive: isActive,
          startsAt: startsAt,
          endsAt: endsAt,
        );

    test('موقوف لا يظهر مهما كان الزمن', () {
      final VillageAd ad = build(isActive: false, startsAt: start, endsAt: end);
      expect(ad.isActiveAt(DateTime(2026, 3, 15)), isFalse);
      expect(ad.statusLabel(DateTime(2026, 3, 15)), VillageAdStatus.paused);
    });

    test('قبل البداية ⇒ مجدول', () {
      final VillageAd ad = build(startsAt: start, endsAt: end);
      expect(ad.isActiveAt(DateTime(2026, 2, 28)), isFalse);
      expect(ad.statusLabel(DateTime(2026, 2, 28)), VillageAdStatus.scheduled);
    });

    test('بعد النهاية ⇒ منتهٍ', () {
      final VillageAd ad = build(startsAt: start, endsAt: end);
      expect(ad.isActiveAt(DateTime(2026, 4, 1)), isFalse);
      expect(ad.statusLabel(DateTime(2026, 4, 1)), VillageAdStatus.expired);
    });

    test('داخل النافذة ⇒ سارٍ', () {
      final VillageAd ad = build(startsAt: start, endsAt: end);
      expect(ad.isActiveAt(DateTime(2026, 3, 15)), isTrue);
      expect(ad.statusLabel(DateTime(2026, 3, 15)), VillageAdStatus.live);
    });

    test('بلا نافذة ⇒ سارٍ من الآن', () {
      final VillageAd ad = build();
      expect(ad.isActiveAt(DateTime(2020, 1, 1)), isTrue);
    });
  });

  group('toRow', () {
    test('يرمّز التواريخ ISO-8601 ويُخرج null للحقول الفارغة', () {
      final DateTime start = DateTime.utc(2026, 3, 1);
      final Map<String, dynamic> row = VillageAd(
        id: 'ad-9',
        villageId: 'v-1',
        title: 'إعلان',
        startsAt: start,
        isActive: false,
      ).toRow();

      expect(row.containsKey('id'), isFalse);
      expect(row['village_id'], 'v-1');
      expect(row['title'], 'إعلان');
      expect(row['starts_at'], start.toIso8601String());
      expect(row['ends_at'], isNull);
      expect(row['image_url'], isNull);
      expect(row['is_active'], isFalse);
    });
  });
}
