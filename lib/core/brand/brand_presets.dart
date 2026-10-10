import 'dart:ui' show Size;

import '../assets/asset_type_ui.dart';
import '../assets/user_asset.dart';
import '../constants/app_constants.dart';
import '../models/template_element.dart';
import '../pdf/pdf_font_catalog.dart';
import 'brand_profile.dart';

/// كتلة هوية جاهزة: عناصرها + معرّف المجموعة المنطقية التي تُختم بها.
///
/// المجموعة تُخزَّن في خريطة طبقات المستند (لا داخل العنصر)، لذا يُرجع الباني
/// معرّفها ليُطبّقه المتحكم بعد الإدراج.
class BrandBlock {
  const BrandBlock({required this.elements, required this.groupId});

  final List<TemplateElement> elements;
  final String groupId;

  bool get isEmpty => elements.isEmpty;
}

/// بناء عناصر «الهوية الجاهزة» من البروفايل — منطق نقيّ بلا أي واجهة.
///
/// كل الدوال هنا تُرجع عناصر جديدة فقط؛ لا تلمس المستند ولا المتحكم، فيسهل
/// اختبارها وحدها ثم تُدرجها [TemplateEditorController].
abstract final class BrandPresets {
  /// ترويسة قياسية: (الشعار + اسم المؤسسة + رقم التسجيل/النص الترويسي) في
  /// مجموعة واحدة أعلى الورقة. تتجاهل أي جزء غير متوفّر في البروفايل.
  static BrandBlock buildHeader({
    required BrandProfile profile,
    required Size design,
    required UserAsset? logo,
    int index = 0,
  }) {
    final double shortSide =
        design.width < design.height ? design.width : design.height;
    final String group = TemplateElement.newGroupId();
    final List<TemplateElement> elements = <TemplateElement>[];
    int seq = 0;
    String nextId(String prefix) =>
        'brand_${prefix}_${DateTime.now().microsecondsSinceEpoch}_${index}_${seq++}';

    double left = design.width * 0.06;
    final double right = design.width * 0.94;
    if (logo != null) {
      final double size = shortSide * 0.13;
      elements.add(
        ImageElement(
          id: nextId('logo'),
          box: ElementBox(
            x: left,
            y: design.height * 0.035,
            width: size,
            height: size,
          ),
          sourceKind: ImageSourceKind.userAsset,
          path: logo.id,
          fit: AssetType.logo.defaultFit,
          data: logo.base64Data.trim().isEmpty ? null : logo.base64Data,
        ),
      );
      left += size + design.width * 0.02;
    }

    final String name = profile.displayName;
    if (name.isNotEmpty) {
      elements.add(
        TextElement(
          id: nextId('name'),
          box: ElementBox(
            x: left,
            y: design.height * 0.04,
            width: right - left,
            height: shortSide * 0.06,
          ),
          text: name,
          family: _familyOf(profile.defaultHeaderFontFamily),
          weight: PdfFontWeight.bold,
          fontSize: shortSide * 0.042,
          colorHex: profile.primaryColorHex,
          align: ElementTextAlign.start,
          verticalAlign: ElementVerticalAlign.middle,
        ),
      );
    }

    final String detail = _headerDetail(profile);
    if (detail.isNotEmpty) {
      elements.add(
        TextElement(
          id: nextId('detail'),
          box: ElementBox(
            x: left,
            y: design.height * 0.04 + shortSide * 0.062,
            width: right - left,
            height: shortSide * 0.04,
          ),
          text: detail,
          family: _familyOf(profile.defaultBodyFontFamily),
          fontSize: shortSide * 0.022,
          colorHex: profile.secondaryColorHex,
          align: ElementTextAlign.start,
          verticalAlign: ElementVerticalAlign.middle,
        ),
      );
    }

    return BrandBlock(elements: elements, groupId: group);
  }

  /// تذييل قياسي: (نص التذييل + رقم التسجيل) أسفل الورقة في مجموعة واحدة.
  static BrandBlock buildFooter({
    required BrandProfile profile,
    required Size design,
    int index = 0,
  }) {
    final double shortSide =
        design.width < design.height ? design.width : design.height;
    final String group = TemplateElement.newGroupId();
    final List<TemplateElement> elements = <TemplateElement>[];
    int seq = 0;
    String nextId(String prefix) =>
        'brand_${prefix}_${DateTime.now().microsecondsSinceEpoch}_${index}_${seq++}';

    final String footer = profile.footerText.trim();
    if (footer.isNotEmpty) {
      elements.add(
        TextElement(
          id: nextId('footer'),
          box: ElementBox(
            x: design.width * 0.07,
            y: design.height * 0.94,
            width: design.width * 0.86,
            height: shortSide * 0.035,
          ),
          text: footer,
          family: _familyOf(profile.defaultBodyFontFamily),
          fontSize: shortSide * 0.021,
          colorHex: profile.primaryColorHex,
          align: ElementTextAlign.center,
          verticalAlign: ElementVerticalAlign.middle,
        ),
      );
    }

    final String reg = _registrationLine(profile);
    if (reg.isNotEmpty) {
      elements.add(
        TextElement(
          id: nextId('reg'),
          box: ElementBox(
            x: design.width * 0.07,
            y: design.height * 0.966,
            width: design.width * 0.86,
            height: shortSide * 0.028,
          ),
          text: reg,
          family: _familyOf(profile.defaultBodyFontFamily),
          fontSize: shortSide * 0.018,
          colorHex: profile.secondaryColorHex,
          align: ElementTextAlign.center,
          verticalAlign: ElementVerticalAlign.middle,
        ),
      );
    }

    return BrandBlock(elements: elements, groupId: group);
  }

  /// عنصر صورة لختم محفوظ (يُدرج في المقدمة بحجم معقول).
  static ImageElement buildSealImage({
    required UserAsset asset,
    required Size design,
    int index = 0,
  }) {
    final double shortSide =
        design.width < design.height ? design.width : design.height;
    final double size = shortSide * 0.2;
    return ImageElement(
      id: 'brand_seal_${DateTime.now().microsecondsSinceEpoch}_$index',
      box: ElementBox(
        x: design.width * 0.72,
        y: design.height * 0.6,
        width: size,
        height: size,
      ),
      sourceKind: ImageSourceKind.userAsset,
      path: asset.id,
      fit: AssetType.stamp.defaultFit,
      data: asset.base64Data.trim().isEmpty ? null : asset.base64Data,
    );
  }

  /// تطبيق ألوان الهوية: الإطارات/الحدود والنصوص بالأساسي، والتعبئات والصور
  /// بالثانوي. [onlyIds] يحدّ الأثر على تحديد معيّن، وإلا يُطبَّق على الكل.
  static List<TemplateElement> applyPalette(
    List<TemplateElement> elements, {
    required String primaryHex,
    required String secondaryHex,
    Set<String>? onlyIds,
  }) {
    return elements.map((TemplateElement element) {
      if (onlyIds != null && !onlyIds.contains(element.id)) return element;
      switch (element) {
        case TextElement():
          return element.colorHex == primaryHex
              ? element
              : element.copyWith(colorHex: primaryHex);
        case ShapeElement():
          final bool hasFill = (element.fillHex ?? '').trim().isNotEmpty;
          return element.copyWith(
            strokeHex: primaryHex,
            fillHex: hasFill ? secondaryHex : element.fillHex,
          );
        case SealElement():
          return element.copyWith(fillHex: secondaryHex, starHex: primaryHex);
        case SignatureElement():
          return element.copyWith(
            nameColorHex: primaryHex,
            roleColorHex: secondaryHex,
          );
        case ImageElement():
          return element.tintHex == secondaryHex
              ? element
              : element.copyWith(tintHex: secondaryHex);
        case DecorationElement():
        case QrElement():
        case UnknownElement():
          return element;
      }
    }).toList(growable: false);
  }

  static String _headerDetail(BrandProfile profile) {
    final String header = profile.headerText.trim();
    if (header.isNotEmpty) return header;
    return _registrationLine(profile);
  }

  static String _registrationLine(BrandProfile profile) {
    final String reg = profile.taxOrRegNumber.trim();
    if (reg.isEmpty) return '';
    return 'س.ت / رقم التسجيل: $reg';
  }

  /// عائلة الخط المخزّنة (jsonValue) → قيمة النوع، مع الافتراض الآمن.
  static PdfFontFamily _familyOf(String? jsonValue) {
    if (jsonValue == null || jsonValue.trim().isEmpty) return PdfFontFamily.plex;
    return PdfFontFamily.fromJson(jsonValue);
  }
}
