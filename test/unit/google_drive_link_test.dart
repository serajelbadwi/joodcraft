import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/village/domain/google_drive_link.dart';

void main() {
  group('normalizeGoogleDriveUrl', () {
    test('رابط المشاركة /file/d/ يتحول إلى صورة مباشرة', () {
      expect(
        normalizeGoogleDriveUrl(
          'https://drive.google.com/file/d/1AbC_dEf9ijkLnOp/view?usp=sharing',
        ),
        'https://lh3.googleusercontent.com/d/1AbC_dEf9ijkLnOp=w1000',
      );
    });

    test('صفحة العرض بلا معامل مشاركة تُعامَل كما هي', () {
      expect(
        normalizeGoogleDriveUrl(
          'https://drive.google.com/file/d/1AbC_dEf9ijkLnOp/view',
        ),
        'https://lh3.googleusercontent.com/d/1AbC_dEf9ijkLnOp=w1000',
      );
    });

    test('open?id= وuc?export=view&id= يُستخرج منهما المعرّف نفسه', () {
      expect(
        normalizeGoogleDriveUrl('https://drive.google.com/open?id=FILE_9x'),
        'https://lh3.googleusercontent.com/d/FILE_9x=w1000',
      );
      expect(
        normalizeGoogleDriveUrl(
          'https://drive.google.com/uc?export=view&id=FILE_9x',
        ),
        'https://lh3.googleusercontent.com/d/FILE_9x=w1000',
      );
    });

    test('الصيغة القديمة thumbnail?id= تُرقَّع إلى الرابط المباشر', () {
      expect(
        normalizeGoogleDriveUrl(
          'https://drive.google.com/thumbnail?id=FILE_9x&sz=w1000',
        ),
        'https://lh3.googleusercontent.com/d/FILE_9x=w1000',
        reason: 'التحويل يكسر CORS على الويب — المباشر يخدمه بترخيص *',
      );
    });

    test('الرابط المباشر لا يتغيّر (التطبيع لا يكسر المُطبَّع)', () {
      const String direct = 'https://lh3.googleusercontent.com/d/FILE_9x=w1000';
      expect(normalizeGoogleDriveUrl(direct), direct);
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
        'https://lh3.googleusercontent.com/d/ID_1=w1000',
      );
    });

    test('رابط مجلد Drive ⇒ null — مجلد ليس صورة', () {
      expect(
        normalizeGoogleDriveUrl(
          'https://drive.google.com/drive/folders/1yF_otCk4Q7kOnUpngnAYtO-sWdIz9t5E',
        ),
        isNull,
        reason: 'لا يمكن عرض مجلد كصورة — الحقل يبقى فارغاً لا رابط HTML ميت',
      );
      expect(normalizeGoogleDriveUrl('  https://drive.google.com/drive/folders/AbC  '), isNull);
    });
  });

  group('isGoogleDriveFolderUrl', () {
    test('روابط المجلدات على درايف تُعرف كمجلد', () {
      expect(
        isGoogleDriveFolderUrl(
          'https://drive.google.com/drive/folders/1yF_otCk4Q7kOnUpngnAYtO-sWdIz9t5E',
        ),
        isTrue,
      );
      expect(isGoogleDriveFolderUrl('https://www.drive.google.com/drive/folders/x'), isTrue);
      expect(isGoogleDriveFolderUrl('  https://drive.google.com/drive/folders/x  '), isTrue);
    });

    test('روابط الملفات والصور ومواقع أخرى ليست مجلدات', () {
      expect(
        isGoogleDriveFolderUrl('https://drive.google.com/file/d/FILE_9x/view'),
        isFalse,
      );
      expect(isGoogleDriveFolderUrl('https://drive.google.com/thumbnail?id=FILE_9x'), isFalse);
      expect(isGoogleDriveFolderUrl('https://example.com/drive/folders/x'), isFalse);
      expect(isGoogleDriveFolderUrl(''), isFalse);
    });
  });
}
