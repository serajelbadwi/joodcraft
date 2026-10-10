import 'dart:typed_data';

/// مخزن حفظ تلقائي لمسودّة ‎.jood‎ واحدة.
///
/// الواجهة تفصل منطق التمهيد (Debounce/استعادة) عن وسيط التخزين: التنفيذ
/// الافتراضي ملف واحد في مجلد بيانات التطبيق ([FileJoodAutosaveStore] على سطح
/// المكتب)، ولا شيء على الويب، و[InMemoryJoodAutosaveStore] للاختبارات.
abstract interface class JoodAutosaveStore {
  /// يكتب المسودّة كاملة (كتابة استبدالية). لا يرمي — الفشل يُسجَّل فقط.
  Future<void> write(Uint8List bytes);

  /// يقرأ المسودّة المحفوظة، أو `null` إن لم توجد.
  Future<Uint8List?> read();

  /// يحذف المسودّة. لا يرمي.
  Future<void> delete();
}

/// مخزن حفظ تلقائي في الذاكرة — للاختبارات وللتشغيل بلا قرص.
class InMemoryJoodAutosaveStore implements JoodAutosaveStore {
  InMemoryJoodAutosaveStore([Uint8List? initial]) : _bytes = initial;

  Uint8List? _bytes;

  /// عدد عمليات الكتابة الفعلية (للتحقّق من التمهيد في الاختبارات).
  int writeCount = 0;

  Uint8List? get bytes => _bytes;

  bool get isEmpty => _bytes == null || _bytes!.isEmpty;

  @override
  Future<void> write(Uint8List bytes) async {
    _bytes = Uint8List.fromList(bytes);
    writeCount++;
  }

  @override
  Future<Uint8List?> read() async => _bytes;

  @override
  Future<void> delete() async {
    _bytes = null;
  }
}
