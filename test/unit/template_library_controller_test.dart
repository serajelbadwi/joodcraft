import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/errors/app_error_code.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
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

    test('updateDocument يثبّت الحقل الجديد في القالب المحلي على القرص',
        () async {
      final TemplateRecord imported =
          await controller.importPreset(PresetCatalog.all.first);
      final TemplateLibraryEntry local = controller.entries.firstWhere(
        (TemplateLibraryEntry entry) => entry.id == imported.id,
      );

      final TemplateDocument updated = TemplateDocument(
        orientation: PageOrientation.landscape,
        elements: const <TemplateElement>[
          TextElement(
            id: 'name',
            box: ElementBox(x: 0, y: 0, width: 10, height: 10),
            text: 'تحولت إلى {{اسم_المتدرب}}',
          ),
        ],
      );

      final TemplateRecord? saved = await controller.updateDocument(
        entry: local,
        document: updated,
      );

      expect(saved, isNotNull);
      expect(saved!.id, imported.id);
      // المخزن على الجهاز يحوي الحقل فعلاً (لا في الذاكرة فقط).
      final TemplateRecord onDisk = store.records.single;
      expect(onDisk.toDocument().fieldKeys, contains('اسم_المتدرب'));

      // وإعادة تشغيل بمخزن جديد على نفس البيانات تُعيده.
      final TemplateLibraryController restarted = TemplateLibraryController(
        null,
        localStore: InMemoryLocalTemplateStore(store.records),
      );
      await restarted.refresh();
      expect(
        restarted.localTemplates.single.toDocument().fieldKeys,
        contains('اسم_المتدرب'),
      );
    });

    test('save بلا مستودع يحفظ محلياً في المخزن (لا يرمي)', () async {
      final TemplateRecord saved = await controller.save(
        title: 'قالب محلي',
        category: PresetCatalog.all.first.category,
        orientation: PresetCatalog.all.first.orientation,
        layoutData: <String, dynamic>{'schema_version': 1},
      );

      expect(saved.id.startsWith('local_'), isTrue);
      expect(saved.title, 'قالب محلي');
      expect(controller.localTemplates.single.id, saved.id);
      // مكتوب على الجهاز فعلاً لا في الذاكرة فقط.
      expect(store.records.single.id, saved.id);
    });

    test('save بمعرّف قائم يُحدّث الصفّ نفسه ولا يُنشئ نسخة', () async {
      final TemplateRecord saved = await controller.save(
        title: 'أول',
        category: PresetCatalog.all.first.category,
        orientation: PresetCatalog.all.first.orientation,
        layoutData: <String, dynamic>{'schema_version': 1},
      );
      final TemplateRecord updated = await controller.save(
        id: saved.id,
        title: 'ثانٍ',
        category: PresetCatalog.all.first.category,
        orientation: PresetCatalog.all.first.orientation,
        layoutData: <String, dynamic>{'schema_version': 1},
      );

      expect(updated.id, saved.id);
      expect(updated.title, 'ثانٍ');
      expect(controller.localTemplates.length, 1);
      expect(store.records.length, 1);
    });

    test('remove بلا مستودع يحذف المحلي بدل الرمي', () async {
      final TemplateRecord saved = await controller.save(
        title: 'x',
        category: PresetCatalog.all.first.category,
        orientation: PresetCatalog.all.first.orientation,
        layoutData: <String, dynamic>{'schema_version': 1},
      );

      await controller.remove(saved.id);

      expect(controller.localTemplates, isEmpty);
      expect(store.records, isEmpty);
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

    test('updateDocument يحدّث القالب السحابي في مكانه', () async {
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
      await controller.refresh();
      final TemplateLibraryEntry cloud = controller.entries.firstWhere(
        (TemplateLibraryEntry entry) => entry.id == 'cloud-1',
      );

      final TemplateDocument updated = TemplateDocument(
        elements: const <TemplateElement>[
          TextElement(
            id: 'name',
            box: ElementBox(x: 0, y: 0, width: 10, height: 10),
            text: '{{اسم_المتدرب}}',
          ),
        ],
      );

      await controller.updateDocument(entry: cloud, document: updated);

      expect(repository.updateCalls, 1);
      expect(
        repository.records.single.toDocument().fieldKeys,
        contains('اسم_المتدرب'),
      );
    });

    test('updateDocument لا يمسّ القوالب الجاهزة', () async {
      await controller.refresh();
      final TemplateLibraryEntry preset = controller.entries.firstWhere(
        (TemplateLibraryEntry entry) => entry.isPreset,
      );

      final TemplateRecord? result = await controller.updateDocument(
        entry: preset,
        document: const TemplateDocument(elements: <TemplateElement>[]),
      );

      expect(result, isNull);
      expect(repository.updateCalls, 0);
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
