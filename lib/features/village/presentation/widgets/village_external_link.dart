/// فتح رابط خارجي في تبويب جديد — بواجهة واحدة تعمل على الويب وفي الاختبارات.
///
/// التنفيذ الحقيقي في `village_external_link_web.dart` (يحتاج متصفحاً)، ونسخة
/// بديلة صامتة لغير الويب حتى تُبنى الاختبارات وأدوات التحليل بلا اعتماد على
/// مكتبات المتصفح.
library;

import 'village_external_link_stub.dart'
    if (dart.library.js_interop) 'village_external_link_web.dart' as impl;

abstract final class VillageExternalLink {
  const VillageExternalLink._();

  /// يفتح [url] في تبويب جديد. يُعيد `false` إن تعذّر (بيئة غير متصفح).
  static bool open(String url) => impl.openInNewTab(url);
}
