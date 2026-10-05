import 'package:flutter/foundation.dart';

import '../models/template_document.dart';
import '../models/template_element.dart';
import 'asset_image_cache.dart';
import 'assets_controller.dart';
import 'user_asset.dart';

/// أدوات مشتركة بين المحرر ومحرّك الطباعة لحلّ أصول القوالب:
/// * النسخة المضمّنة (Base64) داخل العنصر (`ImageElement.data`) أو على القالب
///   (`TemplateDocument.assets[assetId]`).
/// * المراجع المفقودة فعلاً (لا أصل في المكتبة ولا Base64 مضمّن).

/// Base64 المضمّن لعنصر صورة، أو `null` إن لم يوجد.
///
/// الأولوية: نسخة العنصر الخاصة ([ImageElement.data]) ثم نسخة القالب المشتركة
/// ([TemplateDocument.assets]). النسخة المضمّنة **احتياطية فقط** — المرجع الحيّ
/// ([ImageElement.path]) يبقى مقدَّماً ما دام الأصل موجوداً في المكتبة.
String? inlineImageBase64(ImageElement image, TemplateDocument document) {
  final String own = stripBase64DataUri(image.data ?? '');
  if (own.isNotEmpty) return own;
  final String path = image.path.trim();
  if (path.isEmpty) return null;
  final String shared = stripBase64DataUri(document.assets[path] ?? '');
  if (shared.isNotEmpty) return shared;
  return null;
}

/// هل يمكن رسم هذا العنصر رغم غياب الأصل من المكتبة؟
bool hasInlineFallback(ImageElement image, TemplateDocument document) =>
    inlineImageBase64(image, document) != null;

/// Base64 المضمّن لصورة خانة توقيع، أو `null` إن لم يوجد.
///
/// نفس قواعد [inlineImageBase64]: نسخة الخانة أولاً ثم أصول القالب المشتركة،
/// فالمرجع الحيّ يبقى مقدَّماً ما دام الأصل موجوداً في المكتبة.
String? inlineSlotBase64(SignatureSlot slot, TemplateDocument document) {
  final String own = stripBase64DataUri(slot.imageData ?? '');
  if (own.isNotEmpty) return own;
  final String path = slot.imagePath.trim();
  if (path.isEmpty) return null;
  final String shared = stripBase64DataUri(document.assets[path] ?? '');
  return shared.isEmpty ? null : shared;
}

/// هل لصورة الخانة نسخة مضمّنة تكفي للرسم بلا أصل حيّ؟
bool hasInlineSlotFallback(SignatureSlot slot, TemplateDocument document) =>
    inlineSlotBase64(slot, document) != null;

/// معرّفات أصول المستخدم التي يشير إليها القالب (صور العناصر وخانات التوقيع).
///
/// تُعاد **بلا تكرار وبترتيب الظهور**، وتشمل ما غاب عن المكتبة أيضاً — فهي
/// وصف للمراجع لا للمتاح. تُستخدم لتسخين ذاكرة الصور عند فتح القالب.
List<String> referencedAssetIds(TemplateDocument document) {
  final List<String> ids = <String>[];
  void add(String path) {
    final String clean = path.trim();
    if (clean.isEmpty) return;
    if (!ids.contains(clean)) ids.add(clean);
  }

  for (final TemplateElement element in document.elements) {
    if (element is ImageElement) {
      if (element.sourceKind == ImageSourceKind.userAsset) add(element.path);
      continue;
    }
    if (element is SignatureElement) {
      for (final SignatureSlot slot in element.slots) {
        if (slot.imageSource == ImageSourceKind.userAsset) add(slot.imagePath);
      }
    }
  }
  return ids;
}

/// يسخّن ذاكرة الصور المفكوكة بأصول [document] المرجعية.
///
/// **لماذا؟** عند فتح قالب تُفرّغ [AssetImageCache] الذاكرة، فيُعاد فكّ Base64
/// لكل صورة عند أول رسم. هنا نقرأ النسخ المفكوكة المحفوظة على القرص (من فتحات
/// سابقة) فتُرسم فوراً؛ وما غاب عن القرص يُفكّ من Base64 ويُحفظ للفتحة التالية.
///
/// لا يرمي أبداً: أي فشل يُسجَّل فقط، ويُستدعى غير حاجز من المحرّر.
Future<void> warmDocumentImageCache(TemplateDocument document) =>
    warmDocumentsImageCache(<TemplateDocument>[document]);

/// يسخّن ذاكرة الصور لأصول عدة مستندات في نداء **واحد**.
///
/// تُجمع المعرّفات من المستندات كلها بلا تكرار (بحسب أول ظهور) ثم تُحشَد من
/// المكتبة مرة واحدة، فتُقرأ ملفات القرص في دورٍ واحد بدل نداء لكل قالب — وهذا
/// ما تستعمله مكتبة القوالب عند فتحها لتصبح معاينات القوالب جاهزة فوراً.
///
/// لا يرمي أبداً: أي فشل يُسجَّل فقط، ويُستدعى غير حاجز.
Future<void> warmDocumentsImageCache(List<TemplateDocument> documents) async {
  try {
    if (documents.isEmpty) return;
    final AssetsController assets = AssetsController.instance;
    if (!assets.isRestored) await assets.restore();
    final List<String> ids = <String>[];
    for (final TemplateDocument document in documents) {
      for (final String id in referencedAssetIds(document)) {
        if (!ids.contains(id)) ids.add(id);
      }
    }
    if (ids.isEmpty) return;
    final List<UserAsset> referenced = <UserAsset>[];
    for (final String id in ids) {
      final UserAsset? asset = assets.byId(id);
      if (asset != null) referenced.add(asset);
    }
    if (referenced.isEmpty) return;
    await AssetImageCache.instance.preload(referenced);
  } on Object catch (error) {
    debugPrint('[الأصول] تعذّر تسخين ذاكرة الصور: $error');
  }
}

/// أسماء/معرّفات الأصول المفقودة نهائياً (بلا أصل ولا Base64 مضمّن).
///
/// تُستخدم لتحذير المستخدم أثناء الحفظ/التصدير بأن عنصراً ما سيخرج فارغاً
/// وعليه إعادة اختيار الإطار/الأصل. تُعاد القيم بلا تكرار وبترتيب الظهور.
List<String> missingAssetReferences(TemplateDocument document) {
  final List<String> missing = <String>[];
  for (final TemplateElement element in document.elements) {
    if (element is ImageElement) {
      if (element.sourceKind != ImageSourceKind.userAsset) continue;
      final String path = element.path.trim();
      if (path.isEmpty) continue;
      if (AssetsController.instance.byId(path) != null) continue;
      if (hasInlineFallback(element, document)) continue;
      if (!missing.contains(path)) missing.add(path);
      continue;
    }
    // صور خانات التوقيع مفقودة فعلاً إن غاب الأصل ولم توجد نسخة مضمّنة.
    if (element is SignatureElement) {
      for (final SignatureSlot slot in element.slots) {
        if (slot.imageSource != ImageSourceKind.userAsset) continue;
        final String path = slot.imagePath.trim();
        if (path.isEmpty) continue;
        if (AssetsController.instance.byId(path) != null) continue;
        if (hasInlineSlotFallback(slot, document)) continue;
        if (!missing.contains(path)) missing.add(path);
      }
    }
  }
  return missing;
}
