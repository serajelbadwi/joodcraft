import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/templates/local_template_store.dart';
import 'package:joodcraft/core/templates/template_record.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TemplateRecord record({String id = 'local_1', String title = 'قالب محلي'}) {
    return TemplateRecord(
      id: id,
      userId: 'local',
      title: title,
      category: TemplateCategory.certificate,
      orientation: PageOrientation.landscape,
      layoutData: <String, dynamic>{'schema_version': 1, 'elements': <dynamic>[]},
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
    );
  }

  group('SharedPreferencesLocalTemplateStore', () {
    setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

    test('حفظ ثم قراءة من نسخة جديدة يعيد السجلات كما هي', () async {
      final SharedPreferencesLocalTemplateStore first =
          SharedPreferencesLocalTemplateStore();
      expect(await first.loadAll(), isEmpty);

      await first.saveAll(<TemplateRecord>[record()]);

      // نسخة مستقلة = إعادة تشغيل التطبيق.
      final List<TemplateRecord> loaded =
          await SharedPreferencesLocalTemplateStore().loadAll();
      expect(loaded.length, 1);
      expect(loaded.single.title, 'قالب محلي');
      expect(loaded.single.category, TemplateCategory.certificate);
      expect(loaded.single.updatedAt, DateTime.utc(2026, 1, 2));
    });

    test('حفظ قائمة فارغة يمسح المفتاح', () async {
      final SharedPreferencesLocalTemplateStore store =
          SharedPreferencesLocalTemplateStore();
      await store.saveAll(<TemplateRecord>[record()]);
      expect((await store.loadAll()).length, 1);

      await store.saveAll(<TemplateRecord>[]);
      expect(await store.loadAll(), isEmpty);
    });

    test('فك الترميز لا يرمي على محتوى تالف', () {
      expect(
        SharedPreferencesLocalTemplateStore.decodeTemplates('ليس JSON'),
        isEmpty,
      );
      expect(
        SharedPreferencesLocalTemplateStore.decodeTemplates('{"a":1}'),
        isEmpty,
      );
      // عناصر بلا معرّف تُتجاهل بدل إدخال سجل تالف للمكتبة.
      expect(
        SharedPreferencesLocalTemplateStore.decodeTemplates(
          '[{"title":"بلا معرّف"}]',
        ),
        isEmpty,
      );
    });
  });

  test('المخزن في الذاكرة يعيد نسخة مستقلة (لا يشارك المراجع)', () async {
    final InMemoryLocalTemplateStore store = InMemoryLocalTemplateStore();
    await store.saveAll(<TemplateRecord>[record()]);

    final List<TemplateRecord> first = await store.loadAll();
    first.add(record(id: 'local_2'));
    expect((await store.loadAll()).length, 1);
  });
}
