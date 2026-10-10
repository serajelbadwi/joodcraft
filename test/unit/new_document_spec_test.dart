import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/templates/new_document_spec.dart';
import 'package:joodcraft/core/templates/project_preset.dart';

/// اختبارات «مستند جديد» بطراز Photoshop على مستوى النموذج:
///
/// * **بلا تكرار للاتجاه** — مقاس A4 بطاقة واحدة تجمع الرأسي والأفقي.
/// * **تغطية كاملة** — كل مقاس في الفهرس ينتمي إلى عائلة واحدة بالضبط.
/// * **زر إنشاء صادق** — كل حقل في اللوحة (أبعاد، دقّة، نمط لون، خلفية) يظهر
///   فعلاً في المستند الذي يُفتح على اللوحة.
void main() {
  /// البوصلة: تحويل وحدة إلى نقاط (كيف يفكّر المحرّك).
  double pt(double value, MeasurementUnit unit) => unit.toPoints(value);

  group('عائلات المقاسات', () {
    test('مقاس A4 عائلة واحدة تجمع الاتجاهين ولا تتكرر بطاقة', () {
      final List<ProjectPresetFamily> families =
          ProjectPresetFamilies.forKind(ProjectKind.singleSheet);
      final List<ProjectPresetFamily> a4 = families
          .where((ProjectPresetFamily f) => f.paperSize == PaperSize.a4)
          .toList();

      expect(a4.length, 1, reason: 'يجب أن تكون A4 عائلة واحدة لا بطاقتين');
      final ProjectPresetFamily family = a4.single;
      expect(family.title, 'A4');
      expect(family.orientations,
          containsAll(<PageOrientation>[
            PageOrientation.landscape,
            PageOrientation.portrait,
          ]));
      expect(family.variantFor(PageOrientation.landscape)!.id,
          'doc.a4.landscape');
      expect(family.variantFor(PageOrientation.portrait)!.id,
          'doc.a4.portrait');
      expect(family.dimensionsLabelFor(PageOrientation.portrait),
          '21 × 29.7 سم');
      expect(family.dimensionsLabelFor(PageOrientation.landscape),
          '29.7 × 21 سم');
    });

    test('عناوين كلمة الاتجاه مجرَّدة: «A4 أفقي» ⇒ «A4»', () {
      for (final ProjectPresetFamily family in ProjectPresetFamilies.all) {
        expect(family.title.contains('أفقي'), isFalse, reason: family.id);
        expect(family.title.contains('رأسي'), isFalse, reason: family.id);
      }
    });

    test('كل مقاس في الفهرس ينتمي إلى عائلة واحدة بالضبط', () {
      final List<ProjectPreset> covered = <ProjectPreset>[
        for (final ProjectPresetFamily family in ProjectPresetFamilies.all)
          ...family.variants,
      ];
      expect(covered.length, ProjectPresetCatalog.all.length);
      expect(
        covered.map((ProjectPreset p) => p.id).toSet().length,
        ProjectPresetCatalog.all.length,
      );
      for (final ProjectPreset preset in ProjectPresetCatalog.all) {
        final int matches = ProjectPresetFamilies.all
            .where((ProjectPresetFamily f) => f.variants.contains(preset))
            .length;
        expect(matches, 1, reason: preset.id);
      }
    });

    test('لا تتكرر بطاقتان بالمقاس نفسه داخل المجموعة نفسها', () {
      final Set<String> seen = <String>{};
      for (final ProjectPresetFamily family in ProjectPresetFamilies.all) {
        final String signature = '${family.group.jsonValue}|'
            '${family.unit.toPoints(family.widthFor(PageOrientation.portrait)).toStringAsFixed(2)}x'
            '${family.unit.toPoints(family.heightFor(PageOrientation.portrait)).toStringAsFixed(2)}';
        expect(seen.add(signature), isTrue,
            reason: 'تكرار مقاس في ${family.group.jsonValue}');
      }
    });

    test('المنشورات A4 عائلة واحدة بثلاثة أنواع (كتاب/مجلة/تقرير)', () {
      final ProjectPresetFamily family = ProjectPresetFamilies.all.firstWhere(
        (ProjectPresetFamily f) =>
            f.kind == ProjectKind.multiPage && f.paperSize == PaperSize.a4,
      );
      final List<ProjectPreset> portrait =
          family.variantsFor(PageOrientation.portrait);
      expect(portrait.length, 3);
      expect(
        portrait.map((ProjectPreset p) => p.id),
        containsAll(<String>[
          'pub.book.a4',
          'pub.magazine.a4',
          'pub.report.a4',
        ]),
      );
      // كتاب A4 وتقرير A4 يتشاركان المقاس ويتفرّقان في التصنيف (شهادة/عقد).
      expect(
        portrait
            .map((ProjectPreset p) => p.category)
            .toSet()
            .length,
        2,
      );
    });

    test('البحث يعبر كل متغيّرات العائلة (اسم «مجلة» يجد عائلة A4)', () {
      final ProjectPresetFamily family = ProjectPresetFamilies.all.firstWhere(
        (ProjectPresetFamily f) => f.variants
            .any((ProjectPreset p) => p.id == 'pub.magazine.a4'),
      );
      expect(family.matches('مجلة'), isTrue);
      expect(family.matches('كتاب'), isTrue);
      expect(family.matches('تقرير'), isTrue);
      expect(family.matches('لا-شيء'), isFalse);
    });

    test('المقاسات الرقمية عائلات مستقلة ومعلَّمة', () {
      final ProjectPresetFamily story = ProjectPresetFamilies.all.firstWhere(
        (ProjectPresetFamily f) =>
            f.variants.any((ProjectPreset p) => p.id == 'greeting.story'),
      );
      expect(story.isDigital, isTrue);
      expect(story.unit, MeasurementUnit.px);
      expect(story.aspectRatio, closeTo(1080 / 1920, 1e-9));
    });
  });

  group('مواصفة المستند الجديد', () {
    ProjectPresetFamily familyOf(String presetId) =>
        ProjectPresetFamilies.all.firstWhere(
          (ProjectPresetFamily f) =>
              f.variants.any((ProjectPreset p) => p.id == presetId),
        );

    test('A4 بلا تعديل يبقى مقاساً قياسياً (paper: a4) لا مخصّصاً', () {
      final NewDocumentSpec spec = NewDocumentSpec.fromFamily(
        familyOf('doc.a4.landscape'),
        PageOrientation.landscape,
      );
      expect(spec.unit, MeasurementUnit.cm);
      expect(spec.width, 29.7);
      expect(spec.height, 21);
      expect(spec.orientation, PageOrientation.landscape);
      expect(spec.isDigital, isFalse);
      expect(spec.dpi, 300);
      expect(spec.colorMode, DocumentColorMode.cmyk,
          reason: 'الطباعة تبدأ بنيّة CMYK');

      final TemplateDocument document = spec.toDocument();
      expect(document.paperSize, PaperSize.a4);
      expect(document.customPageSize, isNull);
      expect(document.orientation, PageOrientation.landscape);
      expect(document.dpi, 300);
      expect(document.colorMode, DocumentColorMode.cmyk);
      expect(document.backgroundHex, '#FFFFFF');
    });

    test('المقاس الرقمي يبدأ بـ72 نقطة/بوصة ونمط RGB', () {
      final NewDocumentSpec spec = NewDocumentSpec.fromFamily(
        familyOf('greeting.story'),
        PageOrientation.portrait,
      );
      expect(spec.isDigital, isTrue);
      expect(spec.dpi, NewDocumentSpec.screenDpi);
      expect(spec.colorMode, DocumentColorMode.rgb);
      // 1080×1920 بكسل ⇒ 810×1440 نقطة عند 96dpi.
      expect(spec.toDocument().pageWidthPt, closeTo(810, 0.01));
      expect(spec.toDocument().pageHeightPt, closeTo(1440, 0.01));
    });

    test('تعديل رقم واحد يخرج عن الفهرس إلى مقاس مخصّص مضبوط', () {
      final NewDocumentSpec spec = NewDocumentSpec.fromFamily(
        familyOf('card.business'),
        PageOrientation.landscape,
      );
      final NewDocumentSpec edited = spec.copyWith(width: 100, height: 60);
      final TemplateDocument document = edited.toDocument();

      expect(document.customPageSize, isNotNull,
          reason: 'بطاقة العمل تُبنى كمقاس مخصّص بالمليمتر (لا مقاس قياسي)');
      expect(document.customPageSize!.unit, MeasurementUnit.mm,
          reason: 'الوحدة المختارة تُحفظ كما هي');
      expect(document.pageWidthPt, closeTo(pt(100, MeasurementUnit.mm), 1e-6));
      expect(document.pageHeightPt, closeTo(pt(60, MeasurementUnit.mm), 1e-6));

      // A4 بعد التعديل يفقد مقاسه القياسي (فلا يكذب على المحرّك).
      final NewDocumentSpec a4 = NewDocumentSpec.fromFamily(
        familyOf('doc.a4.landscape'),
        PageOrientation.landscape,
      );
      final TemplateDocument editedA4 =
          a4.copyWith(width: 30, height: 21).toDocument();
      expect(editedA4.customPageSize, isNotNull);
      expect(editedA4.pageWidthPt, closeTo(pt(30, MeasurementUnit.cm), 1e-6));
    });

    test('تغيير الوحدة يحفظ المقاس الفيزيائي نفسه', () {
      final NewDocumentSpec spec =
          NewDocumentSpec.fromFamily(
            familyOf('doc.a4.landscape'),
            PageOrientation.landscape,
          ).copyWith(
            unit: MeasurementUnit.mm,
            width: 297,
            height: 210,
          );
      final NewDocumentSpec switched = spec.copyWith(
        unit: MeasurementUnit.cm,
        width: MeasurementUnit.cm.fromPoints(spec.widthPt),
        height: MeasurementUnit.cm.fromPoints(spec.heightPt),
      );
      expect(switched.unit, MeasurementUnit.cm);
      expect(switched.width, closeTo(29.7, 1e-6));
      expect(switched.height, closeTo(21, 1e-6));
      // ولا يفقد مقاس A4 القياسي لأنه ما زال مطابقاً بالنقاط.
      final TemplateDocument document = switched.toDocument();
      expect(document.paperSize, PaperSize.a4);
      expect(document.customPageSize, isNull);
    });

    test('زر الاتجاه يقلب الأبعاد ويتبنّى متغيّر العائلة المقابل', () {
      final ProjectPresetFamily family = familyOf('doc.a4.landscape');
      final NewDocumentSpec landscape = NewDocumentSpec.fromFamily(
        family,
        PageOrientation.landscape,
      );
      final NewDocumentSpec portrait = landscape.flipped(family);

      expect(portrait.width, 21);
      expect(portrait.height, 29.7);
      expect(portrait.orientation, PageOrientation.portrait);
      expect(portrait.presetId, 'doc.a4.portrait');
      expect(portrait.category, TemplateCategory.contract,
          reason: 'A4 الرأسي يفتح محرّر العقود');
      // والعكس يعيدنا للمقاس الأفقي نفسه بلا فقد.
      expect(portrait.flipped(family).width, 29.7);
      expect(portrait.flipped(family).category, TemplateCategory.certificate);
    });

    test('اتجاه بلا متغيّر في الفهرس يُقلب على مقاس مخصّص', () {
      final ProjectPresetFamily family = familyOf('seat.a6');
      final NewDocumentSpec portrait = NewDocumentSpec.fromFamily(
        family,
        PageOrientation.portrait,
      );
      expect(portrait.width, 105);
      expect(portrait.height, 148);
      expect(portrait.presetId, 'seat.a6');

      final NewDocumentSpec landscape = portrait.flipped(family);
      expect(landscape.width, 148);
      expect(landscape.height, 105);
      expect(landscape.presetId, isNull);
      expect(landscape.orientation, PageOrientation.landscape);

      final TemplateDocument document = landscape.toDocument();
      expect(document.pageWidthPt, closeTo(pt(148, MeasurementUnit.mm), 1e-6));
      expect(document.pageHeightPt, closeTo(pt(105, MeasurementUnit.mm), 1e-6));
    });

    test('تبنّي نوع آخر بالمقاس نفسه ينقل التصنيف والاسم', () {
      final ProjectPresetFamily family = ProjectPresetFamilies.all.firstWhere(
        (ProjectPresetFamily f) =>
            f.variants.any((ProjectPreset p) => p.id == 'pub.book.a4'),
      );
      final NewDocumentSpec book = NewDocumentSpec.fromFamily(
        family,
        PageOrientation.portrait,
      );
      expect(book.category, TemplateCategory.certificate);

      final ProjectPreset report = ProjectPresetCatalog.byId('pub.report.a4')!;
      final NewDocumentSpec asReport = book.adoptVariant(report);
      expect(asReport.presetId, 'pub.report.a4');
      expect(asReport.category, TemplateCategory.contract);
      expect(asReport.toDocument().paperSize, PaperSize.a4);
    });

    test('كل حقول اللوحة تصل إلى المستند: العنوان والدقّة والنمط والخلفية', () {
      final NewDocumentSpec spec = NewDocumentSpec.fromFamily(
        familyOf('card.business'),
        PageOrientation.landscape,
      ).copyWith(
        title: 'بطاقة عمل 2026',
        dpi: 150,
        colorMode: DocumentColorMode.rgb,
        backgroundHex: NewDocumentSpec.transparentHex,
      );

      final TemplateDocument document = spec.toDocument();
      expect(document.dpi, 150);
      expect(document.colorMode, DocumentColorMode.rgb);
      expect(document.backgroundHex, '#00000000');
      expect(document.pageWidthPt, closeTo(pt(90, MeasurementUnit.mm), 1e-6));
      expect(document.pageHeightPt, closeTo(pt(55, MeasurementUnit.mm), 1e-6));

      final draft = spec.toDraft();
      expect(draft.title, 'بطاقة عمل 2026');
      expect(draft.category, TemplateCategory.certificate);
    });

    test('بلا اسم يُستخدم عنوان العائلة ثم «مقاس مخصّص»', () {
      final NewDocumentSpec a4 = NewDocumentSpec.fromFamily(
        familyOf('doc.a4.landscape'),
        PageOrientation.landscape,
      );
      expect(a4.toDraft().title, 'A4');

      final NewDocumentSpec custom = NewDocumentSpec.custom();
      expect(custom.toDraft().title, 'مقاس مخصّص');
      expect(custom.unit, MeasurementUnit.mm);
      expect(custom.width, 120);
      expect(custom.height, 80);
    });

    test('وحدة الدقّة تُحوَّل إلى نقطة/بوصة والعكس', () {
      expect(ResolutionUnit.ppi.toDpi(300), 300);
      expect(ResolutionUnit.ppcm.toDpi(118), closeTo(299.72, 1e-6));
      expect(ResolutionUnit.ppcm.fromDpi(300), closeTo(118.11, 0.01));
      expect(ResolutionUnit.fromJson('ppcm'), ResolutionUnit.ppcm);
      expect(ResolutionUnit.fromJson(null), ResolutionUnit.ppi);
    });
  });

  group('دقّة المستند ونمط اللون في التخزين', () {
    test('القيم الافتراضية لا تُكتب في JSON (توافق خلفي كامل)', () {
      const TemplateDocument plain = TemplateDocument(elements: <TemplateElement>[]);
      final Map<String, dynamic> json = plain.toJson();
      expect(json.containsKey('dpi'), isFalse);
      expect(json.containsKey('color_mode'), isFalse);
      expect(json.containsKey('resolution_unit'), isFalse);

      final TemplateDocument back = TemplateDocument.fromJson(json);
      expect(back.dpi, TemplateDocument.defaultDpi);
      expect(back.colorMode, DocumentColorMode.rgb);
      expect(back.resolutionUnit, ResolutionUnit.ppi);
    });

    test('القيم غير الافتراضية تُحفظ وتُقرأ', () {
      const TemplateDocument document = TemplateDocument(
        elements: <TemplateElement>[],
        dpi: 72,
        resolutionUnit: ResolutionUnit.ppcm,
        colorMode: DocumentColorMode.cmyk,
        backgroundHex: '#00000000',
      );
      final Map<String, dynamic> json = document.toJson();
      expect(json['dpi'], 72);
      expect(json['color_mode'], 'cmyk');
      expect(json['resolution_unit'], 'ppcm');

      final TemplateDocument back = TemplateDocument.fromJson(json);
      expect(back.dpi, 72);
      expect(back.colorMode, DocumentColorMode.cmyk);
      expect(back.resolutionUnit, ResolutionUnit.ppcm);
      expect(back.backgroundHex, '#00000000');
    });

    test('copyWith يحفظ الدقّة والنمط عند تغيير الاتجاه', () {
      const TemplateDocument document = TemplateDocument(
        elements: <TemplateElement>[],
        dpi: 150,
        colorMode: DocumentColorMode.cmyk,
      );
      final TemplateDocument flippedDoc =
          document.refit(orientation: PageOrientation.portrait);
      expect(flippedDoc.dpi, 150);
      expect(flippedDoc.colorMode, DocumentColorMode.cmyk);
    });
  });
}
