import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/templates/template_record.dart';

void main() {
  group('قراءة صف من قاعدة البيانات', () {
    test('الصف الكامل يُقرأ بكل حقوله', () {
      final TemplateRecord record = TemplateRecord.fromRow(<String, dynamic>{
        'id': 'abc',
        'user_id': 'user-1',
        'title': 'شهادة إتمام',
        'category': 'certificate',
        'orientation': 'landscape',
        'layout_data': <String, dynamic>{
          'schema_version': 1,
          'elements': <dynamic>[],
        },
        'is_public': true,
        'created_at': '2026-02-01T10:00:00Z',
        'updated_at': '2026-02-02T11:30:00Z',
      });

      expect(record.id, 'abc');
      expect(record.userId, 'user-1');
      expect(record.title, 'شهادة إتمام');
      expect(record.category, TemplateCategory.certificate);
      expect(record.orientation, PageOrientation.landscape);
      expect(record.isPublic, isTrue);
      expect(record.updatedAt!.year, 2026);
      expect(record.hasLayout, isTrue);
    });

    test('صف ناقص لا يُسقط القراءة ويأخذ القيم الافتراضية', () {
      final TemplateRecord record =
          TemplateRecord.fromRow(<String, dynamic>{'id': 'x'});

      expect(record.title, 'قالب بلا عنوان');
      expect(record.category, TemplateCategory.certificate);
      expect(record.orientation, PageOrientation.landscape);
      expect(record.isPublic, isFalse);
      expect(record.layoutData, isEmpty);
      expect(record.hasLayout, isFalse);
      expect(record.createdAt, isNull);
    });

    test('layout_data غير كائن يُتجاهل بدل أن ينهار', () {
      final TemplateRecord record = TemplateRecord.fromRow(<String, dynamic>{
        'id': 'x',
        'layout_data': 'نص غير متوقع',
      });

      expect(record.layoutData, isEmpty);
    });

    test('تصنيفات واتجاهات غير معروفة ترجع للافتراضي', () {
      final TemplateRecord record = TemplateRecord.fromRow(<String, dynamic>{
        'id': 'x',
        'category': 'unknown-kind',
        'orientation': 'sideways',
      });

      expect(record.category, TemplateCategory.certificate);
      expect(record.orientation, PageOrientation.landscape);

      expect(
        TemplateCategory.fromDb('contract'),
        TemplateCategory.contract,
      );
      expect(
        PageOrientation.fromDb('PORTRAIT'),
        PageOrientation.portrait,
      );
    });
  });

  group('التحويل إلى مستند', () {
    test('layout_data يُقرأ كمستند قابل للطباعة', () {
      final TemplateRecord record = TemplateRecord.fromRow(<String, dynamic>{
        'id': 'x',
        'layout_data': <String, dynamic>{
          'schema_version': 1,
          'paper': 'a4',
          'orientation': 'portrait',
          'elements': <dynamic>[
            <String, dynamic>{
              'id': 't1',
              'type': 'text',
              'x': 10,
              'y': 20,
              'w': 300,
              'h': 60,
              'text': 'عقد بين {{اسم_الطرف_الأول}}',
            },
          ],
        },
      });

      final TemplateDocument document = record.toDocument();
      expect(document.orientation, PageOrientation.portrait);
      expect(document.elements.length, 1);
      expect(document.fieldKeys, contains('اسم_الطرف_الأول'));
    });

    test('نسخة السجل لا تشارك المستند الأصلي في المراجع', () {
      final Map<String, dynamic> layout = <String, dynamic>{
        'schema_version': 1,
        'elements': <dynamic>[],
      };
      final TemplateRecord record = TemplateRecord.fromRow(<String, dynamic>{
        'id': 'x',
        'layout_data': layout,
      });

      expect(record.toDocument().schemaVersion, 1);
    });
  });

  group('بناء صف للحفظ', () {
    test('toRow يستخدم القيم الممرّرة ويتجاوز الأصل', () {
      const TemplateRecord record = TemplateRecord(
        id: 'x',
        userId: 'user-9',
        title: 'قديم',
        category: TemplateCategory.certificate,
        orientation: PageOrientation.landscape,
        layoutData: <String, dynamic>{},
      );

      final Map<String, dynamic> row = record.toRow(
        userId: 'user-9',
        layoutData: <String, dynamic>{'schema_version': 1},
        title: 'جديد',
        category: TemplateCategory.contract,
        orientation: PageOrientation.portrait,
      );

      expect(row['user_id'], 'user-9');
      expect(row['title'], 'جديد');
      expect(row['category'], 'contract');
      expect(row['orientation'], 'portrait');
      expect(row['layout_data'], <String, dynamic>{'schema_version': 1});
    });

    test('copyWith يحفظ الحقول غير المذكورة', () {
      final TemplateRecord record = TemplateRecord(
        id: 'x',
        userId: 'u',
        title: 'عنوان',
        category: TemplateCategory.contract,
        orientation: PageOrientation.portrait,
        layoutData: <String, dynamic>{'schema_version': 1},
        createdAt: DateTime(2026),
      );

      final TemplateRecord renamed = record.copyWith(title: 'عنوان آخر');
      expect(renamed.title, 'عنوان آخر');
      expect(renamed.category, TemplateCategory.contract);
      expect(renamed.createdAt, DateTime(2026));
    });
  });
}
