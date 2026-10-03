import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/templates/preset_catalog.dart';
import 'package:joodcraft/core/templates/preset_template.dart';
import 'package:joodcraft/core/templates/template_record.dart';

/// اختبارات فهرس القوالب الجاهزة (المرحلة 5).
///
/// القوالب الجاهزة محزومة في الكود (لا شبكة ولا ملف)، وكل اختبار هنا يثبت أن
/// حمولتها صالحة وقابلة للتحويل إلى مستند/سجل بلا أي مصدر خارجي.
void main() {
  test('الفهرس غير فارغ وله معرّفات فريدة', () {
    expect(PresetCatalog.all, isNotEmpty);

    final Set<String> ids =
        PresetCatalog.all.map((PresetTemplate preset) => preset.id).toSet();
    expect(ids.length, PresetCatalog.all.length);
  });

  test('كل قالب جاهز يُترجم إلى مستند صالح بعناصر وحقول ديناميكية', () {
    for (final PresetTemplate preset in PresetCatalog.all) {
      final TemplateDocument document = preset.document;
      expect(document.drawableElementCount, greaterThan(0),
          reason: 'القالب ${preset.id} بلا عناصر قابلة للرسم');
      expect(document.orientation, preset.orientation,
          reason: 'اتجاه الحمولة لا يطابق الوصف في ${preset.id}');
      expect(document.fieldKeys, isNotEmpty,
          reason: 'القالب ${preset.id} بلا حقول ديناميكية');
      expect(preset.category, preset.collection.category);
    }
  });

  test('التحويل إلى سجل يحفظ المخطط ويوسمه كمصدر جاهز', () {
    final PresetTemplate preset = PresetCatalog.all.first;
    final TemplateRecord record = preset.toRecord();

    expect(record.id, 'preset:${preset.id}');
    expect(PresetTemplate.isPresetRecordId(record.id), isTrue);
    expect(record.userId, PresetTemplate.presetUserId);
    expect(record.title, preset.titleAr);
    expect(record.layoutData['schema_version'], AppConstants.layoutSchemaVersion);
    expect(record.toDocument().drawableElementCount, greaterThan(0));
  });

  test('البحث يطابق العنوان والوصف والوسوم', () {
    final PresetTemplate appreciation =
        PresetCatalog.byId('appreciation_certificate')!;

    expect(appreciation.matches(''), isTrue);
    expect(appreciation.matches('شكر'), isTrue);
    expect(appreciation.matches('تكريم'), isTrue); // وسم
    expect(appreciation.matches('عقد'), isFalse);
  });

  test('byId يعيد القالب الصحيح أو null', () {
    expect(PresetCatalog.byId('employment_contract')?.titleAr, 'عقد عمل');
    expect(PresetCatalog.byId('لا-يوجد'), isNull);
  });

  test('تغطي المكتبة شهادات وعقوداً وإفادة', () {
    final Set<TemplateCollection> collections = PresetCatalog.all
        .map((PresetTemplate preset) => preset.collection)
        .toSet();

    expect(collections, contains(TemplateCollection.appreciation));
    expect(collections, contains(TemplateCollection.employmentContract));
    expect(collections, contains(TemplateCollection.experience));
    expect(
      PresetCatalog.all.any(
        (PresetTemplate preset) => preset.category == TemplateCategory.contract,
      ),
      isTrue,
    );
  });
}
