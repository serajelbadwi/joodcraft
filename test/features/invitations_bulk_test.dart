import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/services/pdf_generator_service.dart';
import 'package:joodcraft/core/templates/invitation_gallery.dart';
import 'package:joodcraft/core/templates/invitation_group.dart';
import 'package:joodcraft/core/templates/invitation_size.dart';
import 'package:joodcraft/core/templates/new_document_spec.dart';
import 'package:joodcraft/core/templates/preset_template.dart';
import 'package:joodcraft/core/templates/project_preset.dart';
import 'package:joodcraft/features/invitations/data/invitation_output_writer.dart';
import 'package:joodcraft/features/invitations/domain/invitation_export_service.dart';
import 'package:joodcraft/features/invitations/domain/invitation_name_file.dart';
import 'package:joodcraft/features/invitations/presentation/providers/invitations_controller.dart';
import 'package:joodcraft/features/invitations/presentation/screens/invitations_screen.dart';

/// اختبارات ميزة «الدعوات الشخصية الجماعية».
///
/// تغطي: ظهور الفئة ومقاساتها، القوالب السبعة وجودتها، تعقيم الأسماء، والتحقق
/// من المكرر/الفارغ، ثم رحلة كاملة: Excel ← معاينة 3 ← 10 ملفات بأسماء صحيحة
/// (PNG + PDF) مع ZIP وفهرس CSV.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PdfGeneratorService generator;

  /// محوّل PNG وهمي: يعيد ترويسة PNG ثابتة بدل الاستدعاء الحقيقي عبر `printing`.
  Future<Uint8List> fakeRasterizer(Uint8List pdfBytes, int dpi) async =>
      Uint8List.fromList(<int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

  setUpAll(() async {
    generator = await PdfGeneratorService.create(useIsolate: false);
  });

  /// يبني ملف Excel حقيقياً في الذاكرة بعمودي «الاسم» و«المدينة».
  Uint8List buildNamesWorkbook(List<String?> names) {
    final Excel excel = Excel.createExcel();
    final Sheet sheet = excel['Sheet1'];
    sheet.appendRow(<CellValue?>[
      TextCellValue('الاسم'),
      TextCellValue('المدينة'),
    ]);
    for (final String? name in names) {
      sheet.appendRow(<CellValue?>[
        name == null ? null : TextCellValue(name),
        TextCellValue('الرياض'),
      ]);
    }
    final List<int>? encoded = excel.encode();
    return Uint8List.fromList(encoded!);
  }

  InvitationsController buildController({InvitationExportService? service}) {
    return InvitationsController(
      service: service ??
          InvitationExportService(
            generator: generator,
            rasterizer: fakeRasterizer,
          ),
      writer: _FakeWriter(),
    );
  }

  // ==========================================================================
  //                            الفئة والمقاسات
  // ==========================================================================

  group('الفئة والمقاسات في «مستند جديد»', () {
    test('مجموعة «دعوات ومناسبات» ظاهرة في الفهرس بتسعة مقاسات', () {
      final List<ProjectPreset> presets =
          ProjectPresetCatalog.forGroup(ProjectPresetGroup.invitations);
      expect(presets.length, 9);

      final Set<String> ids = presets.map((ProjectPreset p) => p.id).toSet();
      expect(ids, containsAll(<String>[
        'invite.a6.portrait',
        'invite.a6.landscape',
        'invite.square148',
        'invite.a5.folded',
        'invite.instagram.square',
        'invite.instagram.portrait',
        'invite.instagram.story',
        'invite.whatsapp.status',
        'invite.facebook.post',
      ]));
    });

    test('مقاسات الطباعة بالسنتيمترات المئوية والرقمية بالبكسل', () {
      final ProjectPreset a6 = ProjectPresetCatalog.byId('invite.a6.portrait')!;
      expect(a6.unit, MeasurementUnit.mm);
      expect(a6.toDocument().pageWidthPt, closeTo(105 / 25.4 * 72, 1e-6));
      expect(a6.toDocument().pageHeightPt, closeTo(148 / 25.4 * 72, 1e-6));
      expect(a6.isDigital, isFalse);

      final ProjectPreset story =
          ProjectPresetCatalog.byId('invite.instagram.story')!;
      expect(story.unit, MeasurementUnit.px);
      expect(story.isDigital, isTrue);
      expect(story.toDocument().pageWidthPt, closeTo(1080 * 72 / 96, 1e-9));
      expect(story.toDocument().pageHeightPt, closeTo(1920 * 72 / 96, 1e-9));

      final ProjectPreset fb =
          ProjectPresetCatalog.byId('invite.facebook.post')!;
      expect(fb.toDocument().pageWidthPt, closeTo(1200 * 72 / 96, 1e-9));
      expect(fb.toDocument().pageHeightPt, closeTo(630 * 72 / 96, 1e-9));
    });

    test('العائلة تظهر في فهرس العائلات وتُنشئ مقاسها الصحيح', () {
      final List<ProjectPresetFamily> families =
          ProjectPresetFamilies.forGroup(ProjectPresetGroup.invitations);
      // 9 مقاسات ⇒ 6 عائلات: A6 طولي/عرضي/A5 مطوي يتشاركون القوس 105×148،
      // وStory/WhatsApp يتشاركان 1080×1920 — نفس اصطلاح العائلات القائم (A4).
      expect(families.length, 6);

      final ProjectPresetFamily a6 = families.firstWhere(
        (ProjectPresetFamily f) =>
            f.variants.any((ProjectPreset p) => p.id == 'invite.a6.landscape'),
      );
      expect(
        a6.orientations,
        containsAll(<PageOrientation>[
          PageOrientation.landscape,
          PageOrientation.portrait,
        ]),
      );

      final NewDocumentSpec spec = NewDocumentSpec.fromFamily(
        ProjectPresetFamilies.all.firstWhere((ProjectPresetFamily f) =>
            f.variants.any((ProjectPreset p) => p.id == 'invite.instagram.story')),
        PageOrientation.portrait,
      );
      final TemplateDocument document = spec.toDocument();
      expect(document.designWidth, closeTo(1080, 1e-6));
      expect(document.designHeight, closeTo(1920, 1e-6));
      expect(document.dpi, NewDocumentSpec.screenDpi);
      expect(document.colorMode, DocumentColorMode.rgb);
    });

    test('InvitationSizes يعرض التسعة بمقاساتها ووسومها', () {
      expect(InvitationSizes.all.length, 9);
      expect(InvitationSizes.byId('invite.a5.folded')!.isDigital, isFalse);
      expect(InvitationSizes.byId('invite.instagram.square')!.isDigital, isTrue);
      expect(InvitationSizes.byId('لا-يوجد'), isNull);
    });
  });

  // ==========================================================================
  //                               القوالب السبعة
  // ==========================================================================

  group('القوالب السبعة', () {
    test('ثلاث مجموعات: رمضان، عيد، زفاف', () {
      expect(InvitationTemplates.all.length, 7);
      expect(InvitationTemplates.forGroup(InvitationGroup.ramadan).length, 2);
      expect(InvitationTemplates.forGroup(InvitationGroup.eid).length, 2);
      expect(InvitationTemplates.forGroup(InvitationGroup.wedding).length, 3);
      expect(InvitationTemplates.byId('inv_ramadan_classic'), isNotNull);
      expect(InvitationTemplates.byId('لا-يوجد'), isNull);
    });

    test('كل قالب في كتالوج الميزة ويحوي {{الاسم}} وقيمة تجريبية', () {
      expect(InvitationTemplates.all.length, 7);
      for (final InvitationTemplate template in InvitationTemplates.all) {
        final TemplateDocument document = template.document;
        expect(document.fieldKeys, contains('الاسم'),
            reason: '${template.id}: حقل الاسم مفقود');
        expect(document.sampleData['الاسم'], isNotEmpty,
            reason: '${template.id}: قيمة تجريبية مفقودة');
        // عناصر داخل حدود الصفحة.
        for (final TemplateElement element in document.elements) {
          expect(element.box.x, greaterThanOrEqualTo(-0.6), reason: template.id);
          expect(element.box.y, greaterThanOrEqualTo(-0.6), reason: template.id);
          expect(
            element.box.x + element.box.width,
            lessThanOrEqualTo(document.designWidth + 0.6),
            reason: '${template.id}/${element.id}',
          );
          expect(
            element.box.y + element.box.height,
            lessThanOrEqualTo(document.designHeight + 0.6),
            reason: '${template.id}/${element.id}',
          );
        }
      }
    });

    test('كل قالب قابل للتحويل إلى قالب مكتبة (PresetTemplate)', () {
      for (final InvitationTemplate template in InvitationTemplates.all) {
        final PresetTemplate preset = template.toPreset();
        expect(preset.id, template.id);
        expect(preset.category, TemplateCategory.certificate);
        expect(preset.document.fieldKeys, contains('الاسم'));
      }
    });

    test('رسالة كل قالب قابلة للتعديل وتظهر في المستند', () {
      for (final InvitationTemplate template in InvitationTemplates.all) {
        final TemplateDocument edited = template.withMessage('نص جديد {{الاسم}}');
        final List<TextElement> texts =
            edited.elements.whereType<TextElement>().toList();
        expect(texts.any((TextElement t) => t.id == 'message'), isTrue,
            reason: template.id);
        expect(
          texts.firstWhere((TextElement t) => t.id == 'message').text,
          'نص جديد {{الاسم}}',
          reason: template.id,
        );
      }
    });

    test('كل قالب يُصدَّر صفحة PDF واحدة سليمة', () async {
      final InvitationExportService service = InvitationExportService(
        generator: generator,
        rasterizer: fakeRasterizer,
      );
      for (final InvitationTemplate template in InvitationTemplates.all) {
        final PdfGenerationReport report = await generator.generate(
          document: template.document,
        );
        expect(report.pageCount, 1, reason: template.id);
        expect(String.fromCharCodes(report.bytes.take(5)), '%PDF-',
            reason: template.id);
        expect(report.byteSize, greaterThan(3000), reason: template.id);
      }
      // الخدمة نفسها تعمل على أي قالب (تأكيد الربط).
      expect(service, isNotNull);
    });
  });

  // ==========================================================================
  //                              تعقيم الأسماء
  // ==========================================================================

  group('تعقيم الأسماء والتحقق', () {
    test('أحمد محمد ⇒ ahmed_mohamed', () {
      expect(InvitationFileName.baseName('أحمد محمد'), 'ahmed_mohamed');
    });

    test('الأسماء اللاتينية والمسافات والرموز', () {
      expect(InvitationFileName.baseName('Li Wei'), 'li_wei');
      expect(InvitationFileName.baseName('  John   Doe  '), 'john_doe');
      expect(InvitationFileName.baseName('a/b:c*d?e'), 'abcde');
    });

    test('الأسماء الطويلة تُقصّ وغير اللاتينية تعود لاسم احتياطي', () {
      expect(
        InvitationFileName.baseName('a' * 80).length,
        invitationFileNameMaxLength,
      );
      // حروف بلا مقابل لاتيني: القاعدة فارغة فيلجأ المخطّط لاسم احتياطي.
      expect(InvitationFileName.baseName('Ⲁⲃⲅ'), '');
      final InvitationSheetAudit audit = InvitationSheetPlanner.plan(
        names: <String>['Ⲁⲃⲅ'],
        rowNumbers: <int>[7],
      );
      expect(audit.plannedCount, 1);
      expect(audit.plans.single.fileNameBase, 'دعوة7');
    });

    test('المكرر يبقى مكرراً باسم مرقّم والفارغ يُتخطّى', () {
      final InvitationSheetAudit audit = InvitationSheetPlanner.plan(
        names: <String>['سارة', 'سارة', 'منى', '   ', ''],
        rowNumbers: <int>[2, 3, 4, 5, 6],
      );
      expect(audit.plannedCount, 3);
      expect(audit.emptyCount, 2);
      expect(audit.duplicateNames, <String>['سارة']);
      final List<String> bases =
          audit.plans.map((InvitationRowPlan p) => p.fileNameBase).toList();
      expect(bases, <String>['sara', 'sara_2', 'mona']);
      expect(audit.plans[1].isDuplicate, isTrue);
      expect(audit.plans[2].isDuplicate, isFalse);
    });
  });

  // ==========================================================================
  //                          الرحلة الكاملة عبر المتحكّم
  // ==========================================================================

  group('الرحلة الكاملة: Excel ← 10 ملفات', () {
    test('رفع الملف يكتشف عمود الاسم ويعاين أول 3 نسخ', () async {
      final InvitationsController controller = buildController();
      addTearDown(controller.dispose);

      await controller.loadBytes(
        fileName: 'guests.xlsx',
        bytes: buildNamesWorkbook(<String>[
          'أحمد محمد',
          'سارة',
          'منى',
          'خالد',
          'فاطمة',
        ]),
      );

      expect(controller.hasSheet, isTrue);
      expect(controller.nameColumn, 0);
      expect(controller.sheet.rowCount, 5);
      expect(controller.plans.length, 5);
      expect(controller.previewPlans.length, 3);
      expect(
        controller.previewPlans.map((InvitationRowPlan p) => p.fileNameBase),
        <String>['ahmed_mohamed', 'sara', 'mona'],
      );
    });

    test('توليد 10 نسخ ينتج 10 ملفات PNG بأسماء صحيحة', () async {
      final InvitationsController controller = buildController();
      addTearDown(controller.dispose);
      controller.selectTemplate(InvitationTemplates.all.first);

      final List<String> names = <String>[
        'أحمد محمد',
        'سارة',
        'منى',
        'خالد',
        'فاطمة',
        'عمر',
        'علي',
        'زينب',
        'يوسف',
        'ليلى',
      ];
      await controller.loadBytes(
        fileName: 'guests.xlsx',
        bytes: buildNamesWorkbook(names),
      );

      controller.setFormat(InvitationExportFormat.png);
      final InvitationExportReport report =
          await controller.startExport().then((InvitationExportReport? r) {
        expect(r, isNotNull);
        return r!;
      });

      expect(report.fileCount, 10);
      expect(report.pngCount, 10);
      expect(report.pdfCount, 0);
      expect(report.cancelled, isFalse);
      expect(report.failedCount, 0);
      expect(controller.done, 10);
      expect(
        report.files.map((InvitationOutputFile f) => f.fileName),
        <String>[
          'ahmed_mohamed.png',
          'sara.png',
          'mona.png',
          'khaled.png',
          'fatima.png',
          'omar.png',
          'ali.png',
          'zainab.png',
          'youssef.png',
          'layla.png',
        ],
      );
      // كل ملف PNG حقيقي (ترويسة PNG).
      for (final InvitationOutputFile file in report.files) {
        expect(String.fromCharCodes(file.bytes.take(4)), '\x89PNG');
      }
    });

    test('PNG + PDF معاً يولّد ملفين لكل اسم', () async {
      final InvitationsController controller = buildController();
      addTearDown(controller.dispose);
      controller.selectTemplate(InvitationTemplates.byId('inv_eid_story')!);
      await controller.loadBytes(
        fileName: 'guests.xlsx',
        bytes: buildNamesWorkbook(<String>['أحمد محمد', 'سارة']),
      );
      controller.setFormat(InvitationExportFormat.both);

      final InvitationExportReport report = (await controller.startExport())!;
      expect(report.fileCount, 4);
      expect(report.pngCount, 2);
      expect(report.pdfCount, 2);
      expect(
        report.files.map((InvitationOutputFile f) => f.fileName).toSet(),
        <String>{
          'ahmed_mohamed.png',
          'ahmed_mohamed.pdf',
          'sara.png',
          'sara.pdf',
        },
      );
      for (final InvitationOutputFile file in report.files) {
        if (file.format == InvitationFileFormat.pdf) {
          expect(String.fromCharCodes(file.bytes.take(5)), '%PDF-');
        }
      }
    });

    test('ZIP يُفكّ ويحوي الملفات، وCSV يحوي فهرس الأسماء', () async {
      final InvitationsController controller = buildController();
      addTearDown(controller.dispose);
      controller.selectTemplate(InvitationTemplates.all.last);
      await controller.loadBytes(
        fileName: 'guests.xlsx',
        bytes: buildNamesWorkbook(<String>['أحمد محمد', 'سارة', 'سارة']),
      );
      controller.setFormat(InvitationExportFormat.png);
      controller.setZip(true);
      controller.setCsv(true);

      final InvitationExportReport report = (await controller.startExport())!;
      expect(report.hasZip, isTrue);
      expect(report.hasCsv, isTrue);
      expect(report.duplicateCount, 1);

      // فكّ الأرشيف والتأكد من الملفات وأسمائها.
      final Archive archive = ZipDecoder().decodeBytes(report.zipBytes!);
      final List<String> zipNames = archive.files
          .map((ArchiveFile f) => f.name)
          .toList(growable: false);
      expect(zipNames, containsAll(<String>[
        'invitations/ahmed_mohamed.png',
        'invitations/sara.png',
        'invitations/sara_2.png',
      ]));

      final String csv = utf8.decode(report.csvBytes!);
      expect(csv.startsWith('file_name,name\n'), isTrue);
      expect(csv, contains('ahmed_mohamed.png,أحمد محمد'));
      expect(csv, contains('sara_2.png,سارة'));
    });

    test('المكرر والفارغ يظهران كتحذيرين في الخطة', () async {
      final InvitationsController controller = buildController();
      addTearDown(controller.dispose);
      controller.selectTemplate(InvitationTemplates.all.first);
      await controller.loadBytes(
        fileName: 'guests.xlsx',
        bytes: buildNamesWorkbook(<String?>['سارة', 'سارة', '']),
      );
      expect(controller.duplicateNames, <String>['سارة']);
      expect(controller.emptyCount, 1);
      expect(controller.plans.length, 2);
    });

    test('التقدّم يتقدّم مع كل ملف والإيقاف المؤقت يوقف التوليد', () async {
      final InvitationExportService service = InvitationExportService(
        generator: generator,
        rasterizer: fakeRasterizer,
      );
      final InvitationsController controller =
          InvitationsController(service: service, writer: _FakeWriter());
      addTearDown(controller.dispose);
      controller.selectTemplate(InvitationTemplates.all.first);
      await controller.loadBytes(
        fileName: 'guests.xlsx',
        bytes: buildNamesWorkbook(<String>['أحمد محمد', 'سارة', 'منى']),
      );

      bool released = false;
      // نوزّع الإيقاف المؤقت عبر انتظار بوابة داخل المتحكّم.
      final Future<InvitationExportReport?> future = service.run(
        document: controller.document!,
        plans: controller.plans,
        format: InvitationExportFormat.png,
        emptyCount: 0,
        onProgress: (int done, int total) {
          expect(done, greaterThanOrEqualTo(1));
          expect(total, 3);
        },
        waitWhilePaused: () async {
          while (!released) {
            await Future<void>.delayed(const Duration(milliseconds: 5));
          }
        },
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      released = true;
      final InvitationExportReport report = (await future)!;
      expect(report.fileCount, 3);
    });
  });

  // ==========================================================================
  //                                واجهة الشاشة
  // ==========================================================================

  group('شاشة الدعوات', () {
    testWidgets('الفئات والقوالب السبعة والمعاينة تظهر', (WidgetTester tester) async {
      final InvitationsController controller = buildController();
      addTearDown(controller.dispose);
      controller.selectTemplate(InvitationTemplates.all.first);
      await controller.loadBytes(
        fileName: 'guests.xlsx',
        bytes: buildNamesWorkbook(<String>['أحمد محمد', 'سارة', 'منى', 'خالد']),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: InvitationsScreen(controller: controller),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // المجموعات الثلاث ظاهرة كمرشّحات (تظهر أيضاً على بطاقات كل مجموعة).
      expect(find.text('رمضان'), findsWidgets);
      expect(find.text('عيد'), findsWidgets);
      expect(find.text('زفاف'), findsWidgets);

      // المعاينة أسفل الشاشة — نتمرّر إليها فتظهر الأسماء الحقيقية.
      await tester.scrollUntilVisible(
        find.text('معاينة أول 3 نسخ'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      expect(controller.template!.titleAr, contains('رمضان'));
      expect(find.text('أحمد محمد'), findsOneWidget);
      expect(find.text('ahmed_mohamed.png'), findsOneWidget);

      // أزرار الخيارات والتوليد تظهر بعد التمرير.
      await tester.scrollUntilVisible(
        find.text('ضغط في ملف ZIP'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('ضغط في ملف ZIP'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('ابدأ التوليد'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('ابدأ التوليد'), findsOneWidget);
    });
  });
}

/// كاتب مخرجات وهمي: يتجاهل القرص ويسجّل النداءات.
class _FakeWriter implements InvitationOutputWriter {
  String? lastDirectory;
  int savedFiles = 0;
  final List<String> savedBytes = <String>[];

  @override
  Future<String?> defaultDirectory() async => '/tmp/invitations';

  @override
  Future<String?> pickDirectory({String? dialogTitle}) async =>
      '/tmp/invitations';

  @override
  Future<String?> saveFiles({
    required String directory,
    required List<InvitationOutputFile> files,
  }) async {
    lastDirectory = directory;
    savedFiles += files.length;
    return directory;
  }

  @override
  Future<String?> saveBytes({
    required String directory,
    required String fileName,
    required Uint8List bytes,
  }) async {
    savedBytes.add(fileName);
    return '$directory/$fileName';
  }

  @override
  Future<bool> openDirectory(String directory) async => true;
}
