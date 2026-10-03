import '../models/template_document.dart';
import '../models/template_element.dart';
import 'assets_controller.dart';

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

/// أسماء/معرّفات الأصول المفقودة نهائياً (بلا أصل ولا Base64 مضمّن).
///
/// تُستخدم لتحذير المستخدم أثناء الحفظ/التصدير بأن عنصراً ما سيخرج فارغاً
/// وعليه إعادة اختيار الإطار/الأصل. تُعاد القيم بلا تكرار وبترتيب الظهور.
List<String> missingAssetReferences(TemplateDocument document) {
  final List<String> missing = <String>[];
  for (final TemplateElement element in document.elements) {
    if (element is! ImageElement) continue;
    if (element.sourceKind != ImageSourceKind.userAsset) continue;
    final String path = element.path.trim();
    if (path.isEmpty) continue;
    if (AssetsController.instance.byId(path) != null) continue;
    if (hasInlineFallback(element, document)) continue;
    if (!missing.contains(path)) missing.add(path);
  }
  return missing;
}
