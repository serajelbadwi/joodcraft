import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/templates/project_preset.dart';
import 'package:joodcraft/core/templates/template_draft.dart';

/// اختبارات فهرس مقاسات المشاريع (§إنشاء المشروع).
///
/// الجوهر هنا واحد: **اختيار أي بطاقة يجب أن يُنشئ لوحة بمقاسها الحقيقي
/// بالضبط وبالنسبة الصحيحة** لا بمقاس مقرَّب. لذلك تتحقّق الاختبارات من أبعاد
/// المستند بالنقاط (ما يطبعه محرّك الـ PDF) ومن مساحة التصميم بالبكسل عند
/// 96dpi (ما تراه اللوحة)، ومن نسبة العرض/الارتفاع في الحالتين.
void main() {
  /// مليمتر → نقطة طباعة (1 بوصة = 25.4 ملم = 72 نقطة).
  double mmToPt(double mm) => mm / 25.4 * 72;

  /// بكسل (96dpi) → نقطة طباعة.
  double pxToPt(double px) => px * 72 / 96;

  /// يحوّل معرّف مقاس إلى مستند المشروع الناتج عنه.
  TemplateDocument documentOf(String id) {
    final ProjectPreset? preset = ProjectPresetCatalog.byId(id);
    expect(preset, isNotNull, reason: 'المقاس $id غير موجود في الفهرس');
    return preset!.toDocument();
  }

  // ==========================================================================
  //  وحدات القياس
  // ==========================================================================
  group('وحدات القياس', () {
    test('المليمتر يُحوَّل إلى النقاط بالمعامل الصحيح (‎72/25.4‎)', () {
      expect(MeasurementUnit.mm.toPoints(25.4), closeTo(72, 1e-9));
      expect(MeasurementUnit.mm.fromPoints(72), closeTo(25.4, 1e-9));
      // 90 ملم = 255.118 نقطة — لا 648 (وهو الخطأ الشائع بمضاعفة ‎2.54‎).
      expect(MeasurementUnit.mm.toPoints(90), closeTo(255.1181, 1e-3));
      expect(MeasurementUnit.mm.toPoints(90), lessThan(300));
    });

    test('البكسل عند 96dpi: ‎96px = 72pt‎ والعكس', () {
      expect(MeasurementUnit.px.toPoints(96), closeTo(72, 1e-9));
      expect(MeasurementUnit.px.fromPoints(72), closeTo(96, 1e-9));
      expect(MeasurementUnit.px.toPoints(1080), closeTo(810, 1e-9));
    });

    test('كل الوحدات تُرجع قيمتها بعد جولة ذهاب وإياب', () {
      for (final MeasurementUnit unit in MeasurementUnit.values) {
        expect(
          unit.fromPoints(unit.toPoints(37.5)),
          closeTo(37.5, 1e-9),
          reason: 'فشلت الجولة للوحدة ${unit.jsonValue}',
        );
      }
    });

    test('قراءة الوحدة من JSON تقبل الرموز والكلمات العربية', () {
      expect(MeasurementUnit.fromJson('mm'), MeasurementUnit.mm);
      expect(MeasurementUnit.fromJson('مم'), MeasurementUnit.mm);
      expect(MeasurementUnit.fromJson('px'), MeasurementUnit.px);
      expect(MeasurementUnit.fromJson('بكسل'), MeasurementUnit.px);
      expect(MeasurementUnit.fromJson('inch'), MeasurementUnit.inch);
      expect(MeasurementUnit.fromJson('بوصة'), MeasurementUnit.inch);
      expect(MeasurementUnit.fromJson('cm'), MeasurementUnit.cm);
      expect(MeasurementUnit.fromJson(null), MeasurementUnit.cm);
      expect(MeasurementUnit.fromJson('مجهول'), MeasurementUnit.cm);
    });
  });

  // ==========================================================================
  //  الهندسة العامة لكل المقاسات
  // ==========================================================================
  group('هندسة كل المقاسات', () {
    test('كل مقاس يُنشئ مستنداً فارغاً بأبعاد موجبة ونسبة صحيحة', () {
      expect(ProjectPresetCatalog.all, isNotEmpty);
      for (final ProjectPreset preset in ProjectPresetCatalog.all) {
        final TemplateDocument document = preset.toDocument();
        expect(document.elements, isEmpty, reason: preset.id);
        expect(document.pageWidthPt, greaterThan(0), reason: preset.id);
        expect(document.pageHeightPt, greaterThan(0), reason: preset.id);
        // النسبة بالنقاط تطابق النسبة المعلنة (المطبوعة).
        expect(
          document.pageWidthPt / document.pageHeightPt,
          closeTo(preset.pageWidth / preset.pageHeight, 1e-4),
          reason: 'النسبة بالنقاط مختلفة عند ${preset.id}',
        );
        // والنسبة في مساحة التصميم كذلك (لا تشوّه عند الاشتقاق بالبكسل).
        expect(
          document.designWidth / document.designHeight,
          closeTo(preset.pageWidth / preset.pageHeight, 1e-4),
          reason: 'النسبة بالتصميم مختلفة عند ${preset.id}',
        );
      }
    });

    test('اتجاه الصفحة يُشتقّ من الأبعاد نفسها', () {
      for (final ProjectPreset preset in ProjectPresetCatalog.all) {
        final TemplateDocument document = preset.toDocument();
        expect(
          document.orientation,
          preset.isLandscape
              ? PageOrientation.landscape
              : PageOrientation.portrait,
          reason: preset.id,
        );
        // العرض الفعّال هو الأكبر عند الاتجاه الأفقي.
        if (preset.isLandscape) {
          expect(document.pageWidthPt, greaterThan(document.pageHeightPt),
              reason: preset.id);
        } else {
          expect(document.pageWidthPt, lessThanOrEqualTo(document.pageHeightPt),
              reason: preset.id);
        }
      }
    });

    test('لا مقاس يُنتج مستنداً بمقاس مخصّص سالب أو بلا وحدة', () {
      for (final ProjectPreset preset in ProjectPresetCatalog.all) {
        final CustomPageSize? custom = preset.toDocument().customPageSize;
        if (custom == null) continue; // مقاس قياسي (A4/A5/Letter).
        expect(custom.width, greaterThan(0), reason: preset.id);
        expect(custom.height, greaterThan(0), reason: preset.id);
        expect(preset.unit, isNotNull);
      }
    });
  });

  // ==========================================================================
  //  المقاسات المطلوبة صراحةً في التبويب الأول
  // ==========================================================================
  group('بطاقات التبويب الأول', () {
    test('الشهادات والعقود: A4 و A3 و Letter بالاتجاهين', () {
      const List<String> ids = <String>[
        'doc.a4.landscape',
        'doc.a4.portrait',
        'doc.a3.landscape',
        'doc.a3.portrait',
        'doc.letter.landscape',
        'doc.letter.portrait',
      ];
      for (final String id in ids) {
        final ProjectPreset? preset = ProjectPresetCatalog.byId(id);
        expect(preset, isNotNull, reason: id);
        expect(
          preset!.group,
          ProjectPresetGroup.certificatesAndContracts,
          reason: id,
        );
        expect(preset.kind, ProjectKind.singleSheet, reason: id);
      }
    });

    test('A4 أفقي = 841.89×595.28 نقطة، ورأسي = العكس بالضبط', () {
      final TemplateDocument landscape = documentOf('doc.a4.landscape');
      expect(landscape.paperSize, PaperSize.a4);
      expect(landscape.orientation, PageOrientation.landscape);
      expect(landscape.pageWidthPt, closeTo(841.89, 1e-9));
      expect(landscape.pageHeightPt, closeTo(595.28, 1e-9));
      expect(landscape.customPageSize, isNull);

      final TemplateDocument portrait = documentOf('doc.a4.portrait');
      expect(portrait.paperSize, PaperSize.a4);
      expect(portrait.orientation, PageOrientation.portrait);
      expect(portrait.pageWidthPt, closeTo(595.28, 1e-9));
      expect(portrait.pageHeightPt, closeTo(841.89, 1e-9));
    });

    test('A3 يُبنى بمقاس مخصّص 42×29.7 سم', () {
      final TemplateDocument document = documentOf('doc.a3.landscape');
      expect(document.customPageSize, isNotNull);
      expect(document.customPageSize!.unit, MeasurementUnit.cm);
      expect(
        document.pageWidthPt,
        closeTo(MeasurementUnit.cm.toPoints(42), 1e-9),
      );
      expect(
        document.pageHeightPt,
        closeTo(MeasurementUnit.cm.toPoints(29.7), 1e-9),
      );
    });

    test('Letter أفقي = 792×612 نقطة', () {
      final TemplateDocument document = documentOf('doc.letter.landscape');
      expect(document.paperSize, PaperSize.letter);
      expect(document.pageWidthPt, closeTo(792, 1e-9));
      expect(document.pageHeightPt, closeTo(612, 1e-9));
    });

    test('الأفقي شهادةٌ والرأسي عقدٌ (مطابقةً لاصطلاح المنصة)', () {
      for (final String id in <String>[
        'doc.a4.landscape',
        'doc.a3.landscape',
        'doc.letter.landscape',
      ]) {
        expect(ProjectPresetCatalog.byId(id)!.category,
            TemplateCategory.certificate, reason: id);
      }
      for (final String id in <String>[
        'doc.a4.portrait',
        'doc.a3.portrait',
        'doc.letter.portrait',
      ]) {
        expect(ProjectPresetCatalog.byId(id)!.category,
            TemplateCategory.contract, reason: id);
      }
    });

    test('الكروت وبطاقات الهوية: 90×55 ملم و85.6×53.9 ملم بالنقطة الحقيقية',
        () {
      final ProjectPreset business = ProjectPresetCatalog.byId('card.business')!;
      expect(business.group, ProjectPresetGroup.cardsAndBadges);
      expect(business.pageWidth, 90);
      expect(business.pageHeight, 55);
      expect(business.unit, MeasurementUnit.mm);
      expect(business.isLandscape, isTrue);
      expect(business.dimensionsLabel, '90 × 55 ملم');

      final TemplateDocument card = business.toDocument();
      expect(card.orientation, PageOrientation.landscape);
      expect(card.pageWidthPt, closeTo(mmToPt(90), 1e-6));
      expect(card.pageHeightPt, closeTo(mmToPt(55), 1e-6));
      // مساحة التصميم بالبكسل = الأبعاد الفعلية عند 96dpi.
      expect(card.designWidth, closeTo(90 / 25.4 * 96, 1e-3));
      expect(card.designHeight, closeTo(55 / 25.4 * 96, 1e-3));

      final ProjectPreset badge = ProjectPresetCatalog.byId('card.id-badge')!;
      expect(badge.pageWidth, 85.6);
      expect(badge.pageHeight, 53.9);
      expect(badge.unit, MeasurementUnit.mm);
      expect(badge.isLandscape, isTrue);
      final TemplateDocument badgeDoc = badge.toDocument();
      expect(badgeDoc.pageWidthPt, closeTo(mmToPt(85.6), 1e-6));
      expect(badgeDoc.pageHeightPt, closeTo(mmToPt(53.9), 1e-6));
      expect(
        badgeDoc.pageWidthPt / badgeDoc.pageHeightPt,
        closeTo(85.6 / 53.9, 1e-9),
      );
    });

    test('أرقام الجلوس: A6 (105×148) و A5 (148×210) رأسيَّان', () {
      final ProjectPreset a6 = ProjectPresetCatalog.byId('seat.a6')!;
      expect(a6.group, ProjectPresetGroup.seatNumbersAndTags);
      expect(a6.pageWidth, 105);
      expect(a6.pageHeight, 148);
      expect(a6.isLandscape, isFalse);
      expect(a6.toDocument().pageWidthPt, closeTo(mmToPt(105), 1e-6));

      final ProjectPreset a5 = ProjectPresetCatalog.byId('seat.a5')!;
      expect(a5.pageWidth, 148);
      expect(a5.pageHeight, 210);
      expect(a5.paperSize, PaperSize.a5);
      expect(a5.isLandscape, isFalse);
      final TemplateDocument a5Doc = a5.toDocument();
      // المقاس القياسي A5 مخزّن بالنقاط بقيمة مقرّبة (419.53×595.28)، فالتفاوت
      // هنا أوسع قليلاً من المقاسات المخصّصة المحسوبة بدقة الوحدة.
      expect(a5Doc.pageWidthPt, closeTo(MeasurementUnit.mm.toPoints(148), 0.01));
      expect(a5Doc.pageHeightPt,
          closeTo(MeasurementUnit.mm.toPoints(210), 0.01));
    });

    test('كروت المعايدات المطبوعة: DL 99×210 و A6 و A5', () {
      final ProjectPreset dl = ProjectPresetCatalog.byId('greeting.dl')!;
      expect(dl.group, ProjectPresetGroup.greetingCards);
      expect(dl.pageWidth, 99);
      expect(dl.pageHeight, 210);
      expect(dl.isDigital, isFalse);
      expect(dl.toDocument().pageWidthPt, closeTo(mmToPt(99), 1e-6));

      for (final String id in <String>['greeting.a6', 'greeting.a5']) {
        final ProjectPreset preset = ProjectPresetCatalog.byId(id)!;
        expect(preset.group, ProjectPresetGroup.greetingCards, reason: id);
        expect(preset.isDigital, isFalse, reason: id);
      }
      expect(ProjectPresetCatalog.byId('greeting.a6')!.pageWidth, 105);
      expect(ProjectPresetCatalog.byId('greeting.a5')!.pageWidth, 148);
    });

    test('المقاسات الرقمية تعود بالبكسل الدقيق بنسبتها', () {
      final ProjectPreset story = ProjectPresetCatalog.byId('greeting.story')!;
      expect(story.unit, MeasurementUnit.px);
      expect(story.isDigital, isTrue);
      expect(story.pageWidth, 1080);
      expect(story.pageHeight, 1920);
      expect(story.isLandscape, isFalse);

      final TemplateDocument storyDoc = story.toDocument();
      expect(storyDoc.designWidth, closeTo(1080, 1e-6));
      expect(storyDoc.designHeight, closeTo(1920, 1e-6));
      expect(storyDoc.pageWidthPt, closeTo(pxToPt(1080), 1e-9));
      expect(storyDoc.pageHeightPt, closeTo(pxToPt(1920), 1e-9));
      // 1080×1920 = 9:16.
      expect(storyDoc.designWidth / storyDoc.designHeight, closeTo(9 / 16, 1e-9));

      final ProjectPreset square = ProjectPresetCatalog.byId('greeting.square')!;
      expect(square.unit, MeasurementUnit.px);
      expect(square.isDigital, isTrue);
      final TemplateDocument squareDoc = square.toDocument();
      expect(squareDoc.designWidth, closeTo(1080, 1e-6));
      expect(squareDoc.designHeight, closeTo(1080, 1e-6));
      // مربّع: النسبة 1:1 بالضبط.
      expect(
        squareDoc.designWidth / squareDoc.designHeight,
        closeTo(1, 1e-9),
      );
    });

    test('التبويب الأول يحوي كل المقاسات المطلوبة', () {
      final Set<String> ids = <String>{
        for (final ProjectPreset preset
            in ProjectPresetCatalog.forKind(ProjectKind.singleSheet))
          preset.id,
      };
      for (final String required in <String>[
        'doc.a4.landscape',
        'doc.a4.portrait',
        'doc.a3.landscape',
        'doc.a3.portrait',
        'doc.letter.landscape',
        'doc.letter.portrait',
        'card.business',
        'card.id-badge',
        'seat.a6',
        'seat.a5',
        'greeting.dl',
        'greeting.a6',
        'greeting.a5',
        'greeting.story',
        'greeting.square',
      ]) {
        expect(ids, contains(required));
      }
    });
  });

  // ==========================================================================
  //  التبويب الثاني: الكتب والمنشورات
  // ==========================================================================
  group('بطاقات التبويب الثاني', () {
    test('كلها متعددة الصفحات وفي مجموعة المنشورات وحدها', () {
      final List<ProjectPreset> multi =
          ProjectPresetCatalog.forKind(ProjectKind.multiPage);
      expect(multi, isNotEmpty);
      for (final ProjectPreset preset in multi) {
        expect(preset.kind, ProjectKind.multiPage, reason: preset.id);
        expect(preset.group, ProjectPresetGroup.publications, reason: preset.id);
      }
      expect(
        ProjectPresetCatalog.groupsForKind(ProjectKind.multiPage),
        <ProjectPresetGroup>[ProjectPresetGroup.publications],
      );
    });

    test('كتاب A5 وكتاب A4 بمقاس صفحة الكتاب الصحيح', () {
      final TemplateDocument bookA5 = documentOf('pub.book.a5');
      expect(bookA5.paperSize, PaperSize.a5);
      expect(bookA5.orientation, PageOrientation.portrait);
      final TemplateDocument bookA4 = documentOf('pub.book.a4');
      expect(bookA4.paperSize, PaperSize.a4);
      expect(bookA4.orientation, PageOrientation.portrait);
    });

    test('الكتيّب A5 صفحه أفقي 210×148', () {
      final ProjectPreset booklet = ProjectPresetCatalog.byId('pub.booklet.a5')!;
      expect(booklet.isLandscape, isTrue);
      final TemplateDocument document = booklet.toDocument();
      expect(document.orientation, PageOrientation.landscape);
      expect(document.pageWidthPt, closeTo(mmToPt(210), 1e-6));
      expect(document.pageHeightPt, closeTo(mmToPt(148), 1e-6));
    });
  });

  // ==========================================================================
  //  الفهرس والأدوات
  // ==========================================================================
  group('الفهرس والأدوات', () {
    test('byId يعيد null بلا رمي عند معرّف مجهول', () {
      expect(ProjectPresetCatalog.byId('لا-يوجد'), isNull);
      expect(ProjectPresetCatalog.byId('card.business'), isNotNull);
    });

    test('المعرّفات فريدة', () {
      final List<String> ids =
          ProjectPresetCatalog.all.map((ProjectPreset p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('البحث يطابق العنوان والوصف والوسوم', () {
      final ProjectPreset card = ProjectPresetCatalog.byId('card.business')!;
      expect(card.matches(''), isTrue);
      expect(card.matches('بطاقة'), isTrue);
      expect(card.matches('90x55'), isTrue);
      expect(card.matches('business'), isTrue);
      expect(card.matches('لا-شيء'), isFalse);
    });

    test('تنسيق الأبعاد بلا أصفار معلّقة', () {
      expect(ProjectPreset.formatDimension(21), '21');
      expect(ProjectPreset.formatDimension(29.7), '29.7');
      expect(ProjectPreset.formatDimension(85.6), '85.6');
      expect(ProjectPreset.formatDimension(53.9), '53.9');
      expect(ProjectPreset.formatDimension(1080), '1080');
      expect(ProjectPreset.formatDimension(21.0), '21');
    });

    test('المسودة تحمل العنوان والتصنيف والمستند نفسه', () {
      final ProjectPreset preset = ProjectPresetCatalog.byId('doc.a4.portrait')!;
      final TemplateDraft draft = preset.toDraft();
      expect(draft.title, preset.titleAr);
      expect(draft.category, TemplateCategory.contract);
      expect(draft.document.paperSize, PaperSize.a4);
      expect(draft.document.orientation, PageOrientation.portrait);
    });

    test('عنوان مخصّص يتقدّم على العنوان الافتراضي', () {
      final ProjectPreset preset = ProjectPresetCatalog.byId('card.business')!;
      expect(preset.toDraft(title: 'بطاقة أحمد').title, 'بطاقة أحمد');
    });
  });

  // ==========================================================================
  //  المقاس المخصّص
  // ==========================================================================
  group('المقاس المخصّص', () {
    test('أبعاد يغلب فيها العرض ⇒ لوحة أفقية بالمقاس الصحيح', () {
      final TemplateDocument document = buildCustomDocument(
        width: 90,
        height: 55,
        unit: MeasurementUnit.mm,
      );
      expect(document.orientation, PageOrientation.landscape);
      // تُخزَّن الأبعاد «طبيعية» ثم يقلبها الاتجاه — فالنتيجة 90 عرضاً و55 طولاً.
      expect(document.customPageSize!.width, 55);
      expect(document.customPageSize!.height, 90);
      expect(document.pageWidthPt, closeTo(mmToPt(90), 1e-9));
      expect(document.pageHeightPt, closeTo(mmToPt(55), 1e-9));
      expect(document.elements, isEmpty);
    });

    test('أبعاد يغلب فيها الارتفاع ⇒ لوحة رأسية', () {
      final TemplateDocument document = buildCustomDocument(
        width: 21,
        height: 29.7,
        unit: MeasurementUnit.cm,
      );
      expect(document.orientation, PageOrientation.portrait);
      expect(
        document.pageWidthPt,
        closeTo(MeasurementUnit.cm.toPoints(21), 1e-9),
      );
      expect(
        document.pageHeightPt,
        closeTo(MeasurementUnit.cm.toPoints(29.7), 1e-9),
      );
    });

    test('المقاس المربّع يُعامل رأسياً ويحفظ النسبة 1:1', () {
      final TemplateDocument document = buildCustomDocument(
        width: 1080,
        height: 1080,
        unit: MeasurementUnit.px,
      );
      expect(document.orientation, PageOrientation.portrait);
      expect(document.designWidth, closeTo(1080, 1e-6));
      expect(document.designHeight, closeTo(1080, 1e-6));
    });

    test('الدخول المخصّص بالمليمتر يعطي المقاس الحقيقي (لا مضاعفاً)', () {
      final TemplateDocument document = buildCustomDocument(
        width: 100,
        height: 50,
        unit: MeasurementUnit.mm,
      );
      // 100 ملم = 10 سم = ‎283.46‎ نقطة، لا 720.
      expect(document.pageWidthPt, closeTo(283.465, 1e-3));
      expect(document.pageHeightPt, closeTo(141.732, 1e-3));
      expect(document.customPageSize!.unit, MeasurementUnit.mm);
    });
  });
}
