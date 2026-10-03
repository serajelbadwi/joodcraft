import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/errors/app_error_code.dart';
import 'package:joodcraft/core/errors/app_exception.dart';
import 'package:joodcraft/core/templates/local_template_store.dart';
import 'package:joodcraft/core/templates/preset_catalog.dart';
import 'package:joodcraft/core/templates/preset_template.dart';
import 'package:joodcraft/core/templates/template_library_controller.dart';
import 'package:joodcraft/core/templates/template_library_entry.dart';
import 'package:joodcraft/core/templates/template_record.dart';

import '../support/fake_template_repository.dart';

void main() {
  group('بلا مستودع سحابي (أوفلاين)', () {
    late InMemoryLocalTemplateStore store;
    late TemplateLibraryController controller;

    setUp(() {
      store = InMemoryLocalTemplateStore();
      controller = TemplateLibraryController(null, localStore: store);
    });

    test('القوالب الجاهزة متاحة دائماً بلا شبكة وبلا خطأ', () async {
      await controller.refresh();

      expect(controller.errorMessage, isNull);
      expect(controller.entries.length, PresetCatalog.all.length);
      expect(
        controller.entries.every(
          (TemplateLibraryEntry entry) =>
              entry.source == TemplateSource.preset,
        ),
        isTrue,
      );
    });

    test('importPreset يحفظ محلياً ويُستعاد عند إعادة فتح التطبيق', () async {
      final PresetTemplate preset =
          PresetCatalog.byId('appreciation_certificate')!;

      final TemplateRecord imported = await controller.importPreset(preset);
      expect(imported.id, startsWith('local_'));
      expect(imported.title, preset.titleAr);
      expect(controller.localTemplates.length, 1);
      expect(store.records.length, 1);

      // إعادة تشغيل: متحكّم ومخزن جديدان على نفس البيانات المحفوظة.
      final TemplateLibraryController restarted = TemplateLibraryController(
        null,
        localStore: InMemoryLocalTemplateStore(store.records),
      );
      await restarted.refresh();

      expect(restarted.localTemplates.length, 1);
      expect(restarted.localTemplates.single.title, preset.titleAr);
      expect(
        restarted.entries.any(
          (TemplateLibraryEntry entry) => entry.source == TemplateSource.local,
        ),
        isTrue,
      );
    });

    test('removeLocal يحذف من الذاكرة ومن المخزن', () async {
      final TemplateRecord imported =
          await controller.importPreset(PresetCatalog.all.first);
      await controller.removeLocal(imported.id);

      expect(controller.localTemplates, isEmpty);
      expect(store.records, isEmpty);
    });

    test('save يحفظ في السحابة يرمي notConfigured', () async {
      await expectLater(
        controller.save(
          title: 'x',
          category: PresetCatalog.all.first.category,
          orientation: PresetCatalog.all.first.orientation,
          layoutData: <String, dynamic>{'schema_version': 1},
        ),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('مع مستودع سحابي', () {
    late FakeTemplateRepository repository;
    late InMemoryLocalTemplateStore store;
    late TemplateLibraryController controller;

    setUp(() {
      repository = FakeTemplateRepository();
      store = InMemoryLocalTemplateStore();
      controller = TemplateLibraryController(repository, localStore: store);
    });

    test('refresh يجمع السحابي والمحلي مع الجاهز', () async {
      repository.records.add(
        TemplateRecord(
          id: 'cloud-1',
          userId: 'user-1',
          title: 'قالب سحابي',
          category: PresetCatalog.all.first.category,
          orientation: PresetCatalog.all.first.orientation,
          layoutData: <String, dynamic>{'schema_version': 1},
        ),
      );
      await controller.importPreset(PresetCatalog.all.first);

      await controller.refresh();

      final List<TemplateSource> sources =
          controller.entries.map((TemplateLibraryEntry e) => e.source).toSet()
              .toList();
      expect(sources, containsAll(<TemplateSource>[
        TemplateSource.preset,
        TemplateSource.local,
        TemplateSource.cloud,
      ]));
      expect(controller.totalCount, PresetCatalog.all.length + 2);
    });

    test('saveAsCustom ينشئ قالباً سحابياً من مدخل جاهز', () async {
      final TemplateLibraryEntry preset = controller.entries.firstWhere(
        (TemplateLibraryEntry entry) => entry.isPreset,
      );

      final TemplateRecord created = await controller.saveAsCustom(
        title: 'نسختي المخصصة',
        entry: preset,
      );

      expect(repository.createCalls, 1);
      expect(created.title, 'نسختي المخصصة');
      expect(created.layoutData['schema_version'], isNotNull);
      expect(controller.templates.single.id, created.id);
    });

    test('فشل السحابة لا يمنع القوالب الجاهزة ويُعرض رسالة', () async {
      repository.failWith = AppErrorCode.network;

      await controller.refresh();

      expect(controller.errorMessage, isNotNull);
      expect(controller.entries.length, PresetCatalog.all.length);
    });

    test('remove يحذف السحابي ويحدّث القائمة', () async {
      repository.records.add(
        TemplateRecord(
          id: 'cloud-1',
          userId: 'user-1',
          title: 'قالب',
          category: PresetCatalog.all.first.category,
          orientation: PresetCatalog.all.first.orientation,
          layoutData: <String, dynamic>{'schema_version': 1},
        ),
      );
      await controller.refresh();

      await controller.remove('cloud-1');

      expect(repository.deleteCalls, 1);
      expect(controller.templates, isEmpty);
    });
  });
}
