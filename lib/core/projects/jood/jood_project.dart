import 'dart:typed_data';

import '../../assets/user_asset.dart';
import '../../fonts/custom_font_face.dart';
import '../../models/template_document.dart';
import '../../models/template_element.dart';

/// مشروع JoodCraft كامل بعد فكّ ملف ‎.jood‎: المستند + ملحقاته المضمّنة.
///
/// هذا هو **الوسيط النقيّ** بين الأرشيف والواجهات: لا يعرف القرص ولا الشبكة،
/// ويحمل كل ما يلزم لاستعادة المشروع على جهاز آخر بلا روابط مفقودة.
class JoodProject {
  const JoodProject({
    required this.document,
    required this.title,
    required this.exportedAt,
    this.schemaVersion,
    this.thumbnailPng,
    this.assets = const <UserAsset>[],
    this.fonts = const <CustomFontFace>[],
    this.missingAssetIds = const <String>[],
    this.missingFontFamilies = const <String>[],
  });

  /// المستند القابل للتحرير والطباعة.
  final TemplateDocument document;

  final String title;

  /// زمن التصدير كما هو مكتوب في المخطّط.
  final DateTime exportedAt;

  /// إصدار مخطط المستند (‎`TemplateDocument`‎) وقت التصدير — للتوافق المستقبلي.
  final int? schemaVersion;

  /// بايتات `thumbnail.png` إن وُجدت.
  final Uint8List? thumbnailPng;

  /// أصول المستخدم المضمّنة (بمعرّفاتها الأصلية فتظل مراجع المستند صالحة).
  final List<UserAsset> assets;

  /// الخطوط المخصصة المضمّنة (بنفس مفاتيح التسجيل فتظل عناصر النص صالحة).
  final List<CustomFontFace> fonts;

  /// معرّفات أصول يشير إليها المستند لكنها لم تُضمَّن (غابت عن الكاتب).
  final List<String> missingAssetIds;

  /// عائلات خطوط مخصصة يشير إليها المستند لكنها لم تُضمَّن.
  final List<String> missingFontFamilies;

  bool get hasThumbnail => thumbnailPng != null && thumbnailPng!.isNotEmpty;

  /// هل الملف مستقلّ تماماً (كل الملحقات المطلوبة مضمّنة)؟
  bool get isSelfContained =>
      missingAssetIds.isEmpty && missingFontFamilies.isEmpty;

  JoodProject copyWith({
    TemplateDocument? document,
    String? title,
    DateTime? exportedAt,
    int? schemaVersion,
    Uint8List? thumbnailPng,
    List<UserAsset>? assets,
    List<CustomFontFace>? fonts,
    List<String>? missingAssetIds,
    List<String>? missingFontFamilies,
  }) =>
      JoodProject(
        document: document ?? this.document,
        title: title ?? this.title,
        exportedAt: exportedAt ?? this.exportedAt,
        schemaVersion: schemaVersion ?? this.schemaVersion,
        thumbnailPng: thumbnailPng ?? this.thumbnailPng,
        assets: assets ?? this.assets,
        fonts: fonts ?? this.fonts,
        missingAssetIds: missingAssetIds ?? this.missingAssetIds,
        missingFontFamilies: missingFontFamilies ?? this.missingFontFamilies,
      );
}

/// عائلات الخطوط المخصصة التي يشير إليها المستند (بلا تكرار وبترتيب الظهور).
///
/// يجمعها من عناصر النص وخانات التوقيع على السواء، لأن كليهما يحمل حقل
/// `customFont` (مفتاح تسجيل `JoodCustom:…`). تُستخدم لتضمين الخطوط فعلاً في
/// ملف ‎.jood‎ بدل الاعتماد على مكتبة الخطوط على جهاز القارئ.
List<String> referencedCustomFontFamilies(TemplateDocument document) {
  final List<String> families = <String>[];
  void add(String? family) {
    final String clean = (family ?? '').trim();
    if (clean.isEmpty) return;
    if (!families.contains(clean)) families.add(clean);
  }

  for (final TemplateElement element in document.elements) {
    if (element is TextElement) {
      add(element.customFont);
      continue;
    }
    if (element is SignatureElement) {
      add(element.customFont);
    }
  }
  return families;
}
