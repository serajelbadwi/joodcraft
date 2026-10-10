import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/templates/new_document_spec.dart';
import 'package:joodcraft/core/templates/project_preset.dart';
import 'package:joodcraft/features/project_hub/presentation/providers/new_document_controller.dart';

/// اختبارات متحكّم «مستند جديد» بلا واجهة: النطاقات والمرشّحات، الاختيار
/// والاتجاه المفضّل، الوحدات والدقّة والنمط والخلفية، وما يعود عند الإنشاء.
void main() {
  late NewDocumentController controller;

  setUp(() {
    NewDocumentController.debugClearRecent();
    controller = NewDocumentController();
  });

  tearDown(() => controller.dispose());

  ProjectPresetFamily familyOf(String presetId) =>
      ProjectPresetFamilies.all.firstWhere(
        (ProjectPresetFamily f) =>
            f.variants.any((ProjectPreset p) => p.id == presetId),
      );

  test('يبدأ على المطبوعات المفردة بمواصفة افتراضية معبّأة مسبقاً', () {
    expect(controller.scope, NewDocumentScope.singleSheet);
    expect(controller.customOnly, isFalse);
    expect(controller.visibleFamilies, isNotEmpty);
    // لا بطاقة مختارة بعد، لكن اللوحة ليست فارغة: مواصفة افتراضية جاهزة
    // (أوّل مقاس في النطاق باتجاه رأسي محايد) تُعرض وتُحرَّر منها الحقول.
    expect(controller.hasSelection, isFalse);
    final NewDocumentSpec fallback = controller.activeSpec;
    expect(fallback.familyId, 'doc.a4.landscape');
    expect(fallback.presetId, 'doc.a4.portrait');
    expect(fallback.width, 21);
    expect(fallback.height, 29.7);
    expect(fallback.colorMode, DocumentColorMode.cmyk);
    // و«إنشاء» لا يصمت: يُنشئ المواصفة المعروضة نفسها.
    expect(controller.buildDraft().title, 'A4');
    expect(controller.hasSelection, isFalse,
        reason: 'الإنشاء لا يحوّل الافتراضية إلى اختيار');
  });

  test('الاتجاه المفضّل يوجّه المواصفة الافتراضية أيضاً', () {
    final NewDocumentController asCertificate = NewDocumentController(
      initialCategory: TemplateCategory.certificate,
    );
    addTearDown(asCertificate.dispose);
    expect(asCertificate.activeSpec.orientation, PageOrientation.landscape);
    expect(asCertificate.activeSpec.presetId, 'doc.a4.landscape');

    final NewDocumentController asContract = NewDocumentController(
      initialCategory: TemplateCategory.contract,
    );
    addTearDown(asContract.dispose);
    expect(asContract.activeSpec.orientation, PageOrientation.portrait);
  });

  test('أوّل تعديل على المواصفة الافتراضية يُثبّتها اختياراً', () {
    expect(controller.hasSelection, isFalse);
    controller.setWidth(30);
    expect(controller.hasSelection, isTrue);
    expect(controller.spec!.width, 30);
    expect(controller.spec!.height, 29.7,
        reason: 'البقية تبقى من الافتراضية');
  });

  test('تبديل النطاق يحدّث الافتراضية ما دام لا اختيار', () {
    expect(controller.activeSpec.familyId, 'doc.a4.landscape');
    controller.selectScope(NewDocumentScope.social);
    expect(controller.activeSpec.familyId, 'greeting.story');
    expect(controller.activeSpec.isDigital, isTrue);
    // وبعد الاختيار لا تُلمس المواصفة عند تبديل النطاق.
    controller.selectFamily(familyOf('greeting.story'));
    controller.selectScope(NewDocumentScope.singleSheet);
    expect(controller.spec!.familyId, 'greeting.story');
  });

  test('تفريغ الأبعاد الأخيرة يعمل من نسخة ساكنة ومن متحكّم', () {
    controller.selectFamily(familyOf('card.business'));
    controller.buildDraft();
    expect(NewDocumentController.recentFamilyIds, isNotEmpty);

    NewDocumentController.clearRecentSizes();
    expect(NewDocumentController.recentFamilyIds, isEmpty);

    controller.selectFamily(familyOf('card.business'));
    controller.buildDraft();
    controller.clearRecent();
    expect(NewDocumentController.recentFamilyIds, isEmpty);
  });

  test('النطاقات الحصرية: المفردة بلا رقمي، والرقمي في نطاقه، والمنشورات وحدها', () {
    final List<String> single = controller.visibleFamilies
        .map((ProjectPresetFamily f) => f.id)
        .toList();
    expect(single, contains('doc.a4.landscape'));
    expect(single, contains('card.business'));
    expect(single.contains('greeting.story'), isFalse);

    controller.selectScope(NewDocumentScope.social);
    final List<String> social = controller.visibleFamilies
        .map((ProjectPresetFamily f) => f.id)
        .toList();
    expect(social, containsAll(<String>['greeting.story', 'greeting.square']));
    expect(social.contains('doc.a4.landscape'), isFalse);
    expect(controller.customAvailable, isFalse);

    controller.selectScope(NewDocumentScope.multiPage);
    expect(
      controller.visibleFamilies
          .every((ProjectPresetFamily f) => f.kind == ProjectKind.multiPage),
      isTrue,
    );
    expect(controller.availableGroups, <ProjectPresetGroup>[
      ProjectPresetGroup.publications,
    ]);
  });

  test('تغيير النطاق يصفّر المرشّح الفرعي والاختيار المخصّص', () {
    controller.selectCustom('مقاس مخصّص');
    expect(controller.customOnly, isTrue);
    expect(controller.visibleFamilies, isEmpty);

    controller.selectScope(NewDocumentScope.multiPage);
    expect(controller.customOnly, isFalse);
    expect(controller.groupFilter, isNull);
    expect(controller.visibleFamilies, isNotEmpty);
  });

  test('الاتجاه المفضّل: الفتح من العقود يبدأ رأسياً ومن الشهادات أفقياً', () {
    final ProjectPresetFamily a4 = familyOf('doc.a4.landscape');

    final NewDocumentController asContract = NewDocumentController(
      initialCategory: TemplateCategory.contract,
    );
    addTearDown(asContract.dispose);
    asContract.selectFamily(a4);
    expect(asContract.spec!.orientation, PageOrientation.portrait);
    expect(asContract.spec!.presetId, 'doc.a4.portrait');

    final NewDocumentController asCertificate = NewDocumentController(
      initialCategory: TemplateCategory.certificate,
    );
    addTearDown(asCertificate.dispose);
    asCertificate.selectFamily(a4);
    expect(asCertificate.spec!.orientation, PageOrientation.landscape);
    expect(asCertificate.spec!.presetId, 'doc.a4.landscape');

    // ومقاس بلا متغيّر في الاتجاه المفضّل يرجع لاتجاهه الطبيعي.
    asContract.selectFamily(familyOf('greeting.dl'));
    expect(asContract.spec!.orientation, PageOrientation.portrait);
  });

  test('اختيار العائلة نفسها ثانيةً يحفظ الاتجاه الذي ضبطه المستخدم', () {
    final ProjectPresetFamily a4 = familyOf('doc.a4.landscape');
    controller.selectFamily(a4);
    expect(controller.spec!.orientation, PageOrientation.landscape);

    controller.setOrientation(PageOrientation.portrait);
    controller.selectFamily(a4);
    expect(controller.spec!.orientation, PageOrientation.portrait);
    expect(controller.spec!.presetId, 'doc.a4.portrait');
  });

  test('تبديل الوحدة يحفظ المقاس الفيزيائي والدقّة تُحوَّل مع وحدتها', () {
    controller.selectFamily(familyOf('card.business'));
    final double widthPt = controller.spec!.widthPt;

    controller.setUnit(MeasurementUnit.inch);
    expect(controller.spec!.unit, MeasurementUnit.inch);
    // تغيير الوحدة يقرّب المعروض إلى خانتين (كما تُعرض الحقول)، فالفرق مسموح
    // بمقدار ‎0.01 بوصة‎ ≈ ‎0.25 نقطة‎ ولا يتجاوز الدقّة التي يراها المستخدم.
    expect(controller.spec!.widthPt, closeTo(widthPt, 0.3));

    controller.setDpi(300);
    controller.setResolutionUnit(ResolutionUnit.ppcm);
    expect(controller.spec!.dpi, 300, reason: 'القيمة الداخلية تبقى بالنقطة/بوصة');
    expect(controller.spec!.dpiInUnit, closeTo(118.11, 0.01));

    controller.setResolutionUnit(ResolutionUnit.ppi);
    expect(controller.spec!.dpi, 300);
  });

  test('الاتجاه واللون والخلفية تُحفظ في المواصفة', () {
    controller.selectFamily(familyOf('card.business'));
    controller.setOrientation(PageOrientation.portrait);
    controller.setColorMode(DocumentColorMode.cmyk);
    controller.setBackground('#00000000');
    controller.setDpi(150);

    final NewDocumentSpec spec = controller.spec!;
    expect(spec.orientation, PageOrientation.portrait);
    expect(spec.width, 55);
    expect(spec.height, 90);
    expect(spec.colorMode, DocumentColorMode.cmyk);
    expect(spec.backgroundHex, '#00000000');
    expect(spec.dpi, 150);
  });

  test('قرص «مقاس مخصّص» يُظهر بطاقته ويضبط 120×80 ملم بلا عائلة', () {
    controller.selectCustom('مقاس مخصّص');
    expect(controller.customOnly, isTrue);
    expect(controller.showCustomTile, isTrue);
    expect(controller.isEmptyScope, isFalse);
    expect(controller.spec!.familyId, isNull);
    expect(controller.spec!.width, 120);
    expect(controller.spec!.colorMode, DocumentColorMode.cmyk);

    controller.setWidth(100);
    controller.setHeight(50);
    expect(controller.buildDraft().title, 'مقاس مخصّص');

    controller.showAll();
    expect(controller.customOnly, isFalse);
    expect(controller.visibleFamilies, isNotEmpty);
  });

  test('البحث يضيّق الشبكة والأحدث يُسجَّل عند الإنشاء', () {
    controller.setQuery('بطاقة');
    final Set<String> found = controller.visibleFamilies
        .map((ProjectPresetFamily f) => f.id)
        .toSet();
    expect(found, containsAll(<String>['card.business', 'card.id-badge']));
    expect(found.contains('doc.a4.landscape'), isFalse);

    controller.setQuery('لا-مقاس-كهذا');
    expect(controller.visibleFamilies, isEmpty);
    expect(controller.isEmptyScope, isTrue);

    controller.setQuery('');
    controller.selectFamily(familyOf('card.business'));
    expect(controller.buildDraft(), isNotNull);
    expect(NewDocumentController.recentFamilyIds.first, 'card.business');

    controller.selectScope(NewDocumentScope.recent);
    expect(controller.visibleFamilies.single.id, 'card.business');
  });

  test('قائمة الأحدث محدودة بثمانية بلا تكرار', () {
    for (final ProjectPresetFamily family in ProjectPresetFamilies.all) {
      controller.selectFamily(family);
      controller.buildDraft();
    }
    expect(NewDocumentController.recentFamilyIds.length, lessThanOrEqualTo(8));
    expect(
      NewDocumentController.recentFamilyIds.toSet().length,
      NewDocumentController.recentFamilyIds.length,
    );
  });

  test('كل تحويلة تُعلم المستمعين', () {
    final List<String> events = <String>[];
    void listener() => events.add('change');
    controller.addListener(listener);
    addTearDown(() => controller.removeListener(listener));

    controller.selectFamily(familyOf('doc.a4.landscape'));
    final int afterSelect = events.length;
    expect(afterSelect, greaterThan(0));

    controller.setWidth(30);
    controller.setHeight(20);
    controller.setUnit(MeasurementUnit.mm);
    controller.setOrientation(PageOrientation.portrait);
    controller.setDpi(120);
    controller.setResolutionUnit(ResolutionUnit.ppcm);
    controller.setColorMode(DocumentColorMode.rgb);
    controller.setBackground('#FFFFFF');
    controller.setQuery('a');
    controller.selectScope(NewDocumentScope.multiPage);
    controller.showAll();
    expect(events.length, greaterThan(afterSelect + 10));

    // قيمة مكرّرة لا تُحدث إشعاراً بلا داعٍ (فتُوفّر إعادة بناء كاملة).
    final int before = events.length;
    controller.setQuery('a');
    controller.setOrientation(PageOrientation.portrait);
    expect(events.length, before);
  });
}
