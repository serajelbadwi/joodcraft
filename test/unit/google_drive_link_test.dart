import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/village/domain/google_drive_link.dart';

void main() {
  group('normalizeGoogleDriveUrl', () {
    test('رابط المشاركة /file/d/ يتحول إلى مُصغّرة مباشرة', () {
      expect(
        normalizeGoogleDriveUrl(
          'https://drive.google.com/file/d/1AbC_dEf9ijkLnOp/view?usp=sharing',
        ),
        'https://drive.google.com/thumbnail?id=1AbC_dEf9ijkLnOp&sz=w1000',
      );
    });

    test('صفحة العرض بلا معامل مشاركة تُعامَل كما هي', () {
      expect(
        normalizeGoogleDriveUrl(
          'https://drive.google.com/file/d/1AbC_dEf9ijkLnOp/view',
        ),
        'https://drive.google.com/thumbnail?id=1AbC_dEf9ijkLnOp&sz=w1000',
      );
    });

    test('open?id= وuc?export=view&id= يُستخرج منهما المعرّف نفسه', () {
      expect(
        normalizeGoogleDriveUrl('https://drive.google.com/open?id=FILE_9x'),
        'https://drive.google.com/thumbnail?id=FILE_9x&sz=w1000',
      );
      expect(
        normalizeGoogleDriveUrl(
          'https://drive.google.com/uc?export=view&id=FILE_9x',
        ),
        'https://drive.google.com/thumbnail?id=FILE_9x&sz=w1000',
      );
    });

    test('المُصغّرة نفسها لا تتغيّر (التطبيع لا يكسر المُطبَّع)', () {
      const String thumb =
          'https://drive.google.com/thumbnail?id=FILE_9x&sz=w1000';
      expect(normalizeGoogleDriveUrl(thumb), thumb);
    });

    test('روابط غير Drive تعود كما هي دون تغيير', () {
      expect(
        normalizeGoogleDriveUrl('https://cdn.test/village-ads/poster.png'),
        'https://cdn.test/village-ads/poster.png',
      );
      // `id=` على غير Drive لا يُخطف.
      expect(
        normalizeGoogleDriveUrl('https://example.com/page?id=abc123'),
        'https://example.com/page?id=abc123',
      );
    });

    test('الفراغ والمسافات ⇒ null (حقل فارغ لا سلسلة فارغة)', () {
      expect(normalizeGoogleDriveUrl(''), isNull);
      expect(normalizeGoogleDriveUrl('   '), isNull);
    });

    test('مسافات حول الرابط تُقتطع قبل المطابقة', () {
      expect(
        normalizeGoogleDriveUrl(
          '  https://drive.google.com/file/d/ID_1/view?usp=sharing  ',
        ),
        'https://drive.google.com/thumbnail?id=ID_1&sz=w1000',
      );
    });
  });
}
