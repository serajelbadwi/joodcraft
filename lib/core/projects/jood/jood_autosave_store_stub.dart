import 'dart:typed_data';

import 'jood_autosave_store.dart';

/// حفظ تلقائي على الويب: بلا نظام ملفات، فلا مسودّة قرصية.
///
/// الواجهة تبقى تعمل بلا كسر: الكتابة/القراءة/الحذف عمليات صامتة، فيظل المنطق
/// المشترك (التمهيد والاستعادة) قابلاً للاستدعاء على كل المنصات.
class WebJoodAutosaveStore implements JoodAutosaveStore {
  @override
  Future<void> write(Uint8List bytes) async {}

  @override
  Future<Uint8List?> read() async => null;

  @override
  Future<void> delete() async {}
}

/// المخزن الافتراضي على الويب.
JoodAutosaveStore defaultJoodAutosaveStore() => WebJoodAutosaveStore();
