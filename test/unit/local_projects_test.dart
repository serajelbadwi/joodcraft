import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/errors/app_exception.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/projects/local_project_repository.dart';
import 'package:joodcraft/core/projects/local_projects_database.dart';
import 'package:joodcraft/core/projects/project_record.dart';
import 'package:joodcraft/core/projects/projects_controller.dart';
import 'package:joodcraft/core/projects/projects_template_store.dart';
import 'package:joodcraft/core/templates/template_record.dart';

/// اختبارات **الحفظ المحلي**: صفّ `projects`، والقاعدة، والمحرّك، والمحوّلات
/// التي تجعل المحرّر والمكتبة يكتبان في نفس الجدول بلا أي سيرفر.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TemplateDocument documentOf({
    PageOrientation orientation = PageOrientation.portrait,
    String text = 'شهادة تقدير',
  }) {
    return TemplateDocument(
      orientation: orientation,
      elements: <TemplateElement>[
        TextElement(
          id: 'title',
          box: ElementBox(x: 10, y: 10, width: 120, height: 24),
          text: text,
        ),
      ],
    );
  }

  TemplateRecord recordOf({
    String id = 'local_1',
    String title = 'قالب',
    TemplateCategory category = TemplateCategory.certificate,
    PageOrientation orientation = PageOrientation.portrait,
  }) {
    return TemplateRecord(
      id: id,
      userId: 'local',
      title: title,
      category: category,
      orientation: orientation,
      layoutData: documentOf(orientation: orientation).toJson(),
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 2),
    );
  }

  group('صفّ المشروع (جدول projects)', () {
    test('يُكتب بأعمدة المواصفة حرفياً و`layers_data` نصّ JSON', () {
      final ProjectRecord record = ProjectRecord.fromTemplateRecord(
        recordOf(),
      );
      final Map<String, dynamic> row = record.toRow();

      expect(
        row.keys,
        containsAll(<String>[
          'id',
          'title',
          'width',
          'height',
          'layers_data',
          'updated_at',
          'thumbnail_path',
        ]),
      );
      // النصّ لا الخريطة: العمود `TEXT (JSON)` كما في المواصفة.
      expect(row['layers_data'], isA<String>());
      expect(row['updated_at'], isA<String>());
      expect(record.layersToJson(), isNotEmpty);

      // الأبعاد مأخوذة من المستند نفسه (لا رقم مكتوب يدوياً).
      final TemplateDocument document = documentOf();
      expect(record.width, document.pageWidthPt);
      expect(record.height, document.pageHeightPt);
    });

    test('قراءة الصفّ متسامحة: صفّ تالف لا يُسقط القائمة', () {
      final ProjectRecord broken = ProjectRecord.fromRow(<dynamic, dynamic>{
        'id': 'x',
        'title': null,
        'width': 'غير رقم',
        'layers_data': 'ليست JSON',
        'updated_at': 'تاريخ غير صالح',
      });

      expect(broken.id, 'x');
      expect(broken.title, 'مشروع بلا عنوان');
      expect(broken.width, 0);
      expect(broken.height, 0);
      expect(broken.layersToJson(), isEmpty);
      expect(broken.updatedAt, isNotNull);
    });

    test('يقبل `layers_data` خريطة أيضاً (تخزين قديم)', () {
      final Map<String, dynamic> layers = documentOf().toJson();
      final ProjectRecord record = ProjectRecord.fromRow(<dynamic, dynamic>{
        'id': 'old',
        'layers_data': layers,
      });

      expect(record.layersToJson()['elements'], isNotEmpty);
      expect(record.copyWith(title: 'جديد').title, 'جديد');
      // النسخة غير المعدَّلة تحفظ معرّفها.
      expect(record.copyWith(title: 'جديد').id, 'old');
    });

    test('الانتقال بين سجلّ القالب والصفّ يحفظ الاتجاه والتصنيف', () {
      final ProjectRecord landscape = ProjectRecord.fromTemplateRecord(
        recordOf(
          category: TemplateCategory.contract,
          orientation: PageOrientation.landscape,
        ),
      );
      expect(landscape.category, TemplateCategory.contract);
      expect(landscape.orientation, PageOrientation.landscape);
      expect(landscape.aspectRatio, greaterThan(1));

      final TemplateRecord back = landscape.toTemplateRecord();
      expect(back.id, landscape.id);
      expect(back.orientation, PageOrientation.landscape);
      expect(back.toDocument().pageWidthPt, landscape.width);
      expect(back.toDocument().pageHeightPt, landscape.height);
    });
  });

  group('قاعدة المشاريع المحلية (في الذاكرة)', () {
    late InMemoryProjectsDatabase database;

    setUp(() => database = InMemoryProjectsDatabase());

    ProjectRecord rowOf(String id, DateTime updatedAt) =>
        ProjectRecord.fromTemplateRecord(
          recordOf(id: id, title: id),
          updatedAt: updatedAt,
        );

    test('القراءة مرتّبة بالأحدث تعديلاً', () async {
      await database.upsertAll(<ProjectRecord>[
        rowOf('a', DateTime(2026, 1, 1)),
        rowOf('b', DateTime(2026, 3, 1)),
        rowOf('c', DateTime(2026, 2, 1)),
      ]);

      final List<ProjectRecord> rows = await database.selectAll();
      expect(rows.map((ProjectRecord r) => r.id), <String>['b', 'c', 'a']);
    });

    test('الإدراج يتحدّث في مكانه ولا يُكرّر الصفّ', () async {
      await database.upsert(rowOf('a', DateTime(2026, 1, 1)));
      await database.upsert(
        rowOf('a', DateTime(2026, 4, 1)).copyWith(title: 'محدَّث'),
      );

      final List<ProjectRecord> rows = await database.selectAll();
      expect(rows.length, 1);
      expect(rows.single.title, 'محدَّث');
    });

    test('selectById وdelete وclear', () async {
      await database.upsert(rowOf('a', DateTime(2026, 1, 1)));
      expect((await database.selectById('a'))!.id, 'a');
      expect(await database.selectById('ghost'), isNull);

      await database.delete('a');
      expect(await database.selectAll(), isEmpty);

      await database.upsert(rowOf('b', DateTime(2026, 1, 1)));
      await database.clear();
      expect(await database.selectAll(), isEmpty);
      expect(database.isInitialized, isTrue);
    });
  });

  group('محرّك المشاريع (ProjectsController)', () {
    late InMemoryProjectsDatabase database;
    late ProjectsController projects;

    setUp(() {
      database = InMemoryProjectsDatabase();
      projects = ProjectsController(database: database);
    });

    tearDown(() => projects.dispose());

    test('restore يقرأ الجدول مرة واحدة ويستمر في الذاكرة', () async {
      await database.upsert(
        ProjectRecord.fromTemplateRecord(recordOf(id: 'p1')),
      );

      await projects.restore();
      expect(projects.isLoaded, isTrue);
      expect(projects.count, 1);

      // إضافة صفّ خلف ظهر المحرّك لا تُقرأ حتى يُطلب تحديث صريح.
      await database.upsert(
        ProjectRecord.fromTemplateRecord(recordOf(id: 'p2')),
      );
      expect(projects.count, 1);
      await projects.refresh();
      expect(projects.count, 2);
    });

    test('save يُنشئ معرّفاً محلياً ويكتب صفّاً واحداً', () async {
      final ProjectRecord saved = await projects.save(
        title: ' شهادة 2026 ',
        document: documentOf(),
        category: TemplateCategory.certificate,
      );

      expect(saved.id.startsWith('local_'), isTrue);
      expect(saved.title, 'شهادة 2026');
      expect(database.rows.single.id, saved.id);
      expect(projects.recent().first.id, saved.id);
    });

    test('save بمعرّف قائم يُحدّث ولا يُكرّر ويحفظ تاريخ الإنشاء', () async {
      final ProjectRecord first = await projects.save(
        title: 'أول',
        document: documentOf(),
        category: TemplateCategory.certificate,
        now: DateTime(2026, 1, 1),
      );
      final ProjectRecord second = await projects.save(
        id: first.id,
        title: 'ثانٍ',
        document: documentOf(text: 'نصّ آخر'),
        category: TemplateCategory.certificate,
        now: DateTime(2026, 2, 1),
      );

      expect(projects.count, 1);
      expect(second.title, 'ثانٍ');
      expect(second.createdAt, DateTime(2026, 1, 1));
      expect(second.updatedAt, DateTime(2026, 2, 1));
    });

    test('عنوان فارغ يُحفظ بعنوان افتراضي بدل صفّ بلا اسم', () async {
      final ProjectRecord saved = await projects.save(
        title: '   ',
        document: documentOf(),
        category: TemplateCategory.contract,
      );
      expect(saved.title, 'مشروع بلا عنوان');
    });

    test('attachThumbnail يربط المسار ويبقى في الصفّ', () async {
      final ProjectRecord saved = await projects.save(
        title: 'بصورة',
        document: documentOf(),
        category: TemplateCategory.certificate,
      );
      await projects.attachThumbnail(saved.id, 'C:/tmp/thumb.png');

      expect(projects.findById(saved.id)!.thumbnailPath, 'C:/tmp/thumb.png');
      expect(projects.findById(saved.id)!.hasThumbnail, isTrue);
      // المسار محفوظ على القرص أيضاً لا في الذاكرة فقط.
      expect(database.rows.single.thumbnailPath, 'C:/tmp/thumb.png');

      // حفظ لاحق لا يمحو الصورة المصغّرة.
      await projects.save(
        id: saved.id,
        title: 'بصورة 2',
        document: documentOf(),
        category: TemplateCategory.certificate,
      );
      expect(projects.findById(saved.id)!.thumbnailPath, 'C:/tmp/thumb.png');
    });

    test('remove يحذف من الذاكرة ومن القاعدة', () async {
      final ProjectRecord saved = await projects.save(
        title: 'للحذف',
        document: documentOf(),
        category: TemplateCategory.certificate,
      );
      await projects.remove(saved.id);

      expect(projects.count, 0);
      expect(database.rows, isEmpty);
    });

    test('يُعلم المستمعين عند الحفظ (فتتحدّث لوحة التحكم وحدها)', () async {
      int notifications = 0;
      projects.addListener(() => notifications++);

      await projects.save(
        title: 'x',
        document: documentOf(),
        category: TemplateCategory.certificate,
      );
      expect(notifications, greaterThan(0));
    });

    test('recent يحصر القائمة ويبقيها مرتّبة', () async {
      for (int i = 1; i <= 4; i++) {
        await projects.save(
          title: 'م$i',
          document: documentOf(),
          category: TemplateCategory.certificate,
          now: DateTime(2026, 1, i),
        );
      }

      expect(projects.recent(limit: 2).map((ProjectRecord r) => r.title),
          <String>['م4', 'م3']);
      expect(projects.recent().length, 4);
    });
  });

  group('مستودع المشاريع المحلي (TemplateRepository)', () {
    late ProjectsController projects;
    late LocalProjectRepository repository;

    setUp(() {
      projects = ProjectsController(database: InMemoryProjectsDatabase());
      repository = LocalProjectRepository(controller: projects);
    });

    tearDown(() => projects.dispose());

    test('create ثم listMine ثم findById', () async {
      final TemplateRecord created = await repository.create(
        title: 'شهادة محلية',
        category: TemplateCategory.certificate,
        orientation: PageOrientation.landscape,
        layoutData: documentOf().toJson(),
      );

      expect(created.orientation, PageOrientation.landscape);
      final List<TemplateRecord> mine = await repository.listMine();
      expect(mine.single.id, created.id);
      expect((await repository.findById(created.id))!.title, 'شهادة محلية');
      expect(await repository.findById('ghost'), isNull);
    });

    test('update يغيّر العنوان والهيكل ويُثبّت الاتجاه المطلوب', () async {
      final TemplateRecord created = await repository.create(
        title: 'قديم',
        category: TemplateCategory.certificate,
        orientation: PageOrientation.landscape,
        layoutData: documentOf().toJson(),
      );

      final TemplateRecord updated = await repository.update(
        id: created.id,
        title: 'جديد',
        orientation: PageOrientation.portrait,
        layoutData: documentOf(text: 'نصّ محدَّث').toJson(),
      );

      expect(updated.id, created.id);
      expect(updated.title, 'جديد');
      expect(updated.orientation, PageOrientation.portrait);
      expect(updated.toDocument().elements.single, isA<TextElement>());
      expect((updated.toDocument().elements.single as TextElement).text,
          'نصّ محدَّث');
    });

    test('update بلا layoutData يحفظ الهيكل القائم', () async {
      final TemplateRecord created = await repository.create(
        title: 'قديم',
        category: TemplateCategory.certificate,
        orientation: PageOrientation.portrait,
        layoutData: documentOf(text: 'يبقى').toJson(),
      );

      final TemplateRecord renamed = await repository.update(
        id: created.id,
        title: 'بلا هيكل',
      );

      expect(renamed.title, 'بلا هيكل');
      expect(
        (renamed.toDocument().elements.single as TextElement).text,
        'يبقى',
      );
    });

    test('update لمعرّف غير موجود يرمي notFound', () async {
      await expectLater(
        repository.update(id: 'ghost', title: 'x'),
        throwsA(isA<AppException>()),
      );
    });

    test('delete يحذف الصفّ المحلي', () async {
      final TemplateRecord created = await repository.create(
        title: 'للحذف',
        category: TemplateCategory.contract,
        orientation: PageOrientation.portrait,
        layoutData: documentOf().toJson(),
      );
      await repository.delete(created.id);

      expect(await repository.listMine(), isEmpty);
      expect(projects.count, 0);
    });
  });

  group('محوّل مخزن القوالب (LocalTemplateStore)', () {
    late ProjectsController projects;
    late ProjectsTemplateStore store;

    setUp(() {
      projects = ProjectsController(database: InMemoryProjectsDatabase());
      store = ProjectsTemplateStore(controller: projects);
    });

    tearDown(() => projects.dispose());

    test('loadAll يعرض المشاريع كسجلّات قوالب', () async {
      await projects.save(
        title: 'شهادة',
        document: documentOf(),
        category: TemplateCategory.certificate,
      );

      final List<TemplateRecord> records = await store.loadAll();
      expect(records.single.title, 'شهادة');
      expect(records.single.userId, ProjectRecord.localUserId);
      expect(records.single.layoutData, isNotEmpty);
    });

    test('saveAll يكتب الصفوف ويحفظ الصور المصغّرة القائمة', () async {
      final ProjectRecord saved = await projects.save(
        title: 'بصورة',
        document: documentOf(),
        category: TemplateCategory.certificate,
      );
      await projects.attachThumbnail(saved.id, 'thumb.png');

      await store.loadAll();
      await store.saveAll(<TemplateRecord>[
        (await store.loadAll()).single.copyWith(title: 'مُعاد'),
      ]);

      final ProjectRecord after = projects.findById(saved.id)!;
      expect(after.title, 'مُعاد');
      expect(after.thumbnailPath, 'thumb.png');
    });

    test('saveAll يحذف ما حُذف من اللقطة ولا يمسّ صفّاً جديداً', () async {
      final ProjectRecord kept = await projects.save(
        title: 'يبقى',
        document: documentOf(),
        category: TemplateCategory.certificate,
      );
      final ProjectRecord removed = await projects.save(
        title: 'يُحذف',
        document: documentOf(),
        category: TemplateCategory.certificate,
      );

      final List<TemplateRecord> snapshot = await store.loadAll();
      expect(snapshot.length, 2);

      // مشروع أُنشئ بعد اللقطة (من المحرّر مثلاً) — لا يجوز أن يُمحى.
      final ProjectRecord fresh = await projects.save(
        title: 'جديد',
        document: documentOf(),
        category: TemplateCategory.certificate,
      );

      await store.saveAll(
        snapshot
            .where((TemplateRecord record) => record.id != removed.id)
            .toList(),
      );

      expect(projects.findById(kept.id), isNotNull);
      expect(projects.findById(removed.id), isNull);
      expect(projects.findById(fresh.id), isNotNull);
    });
  });
}
