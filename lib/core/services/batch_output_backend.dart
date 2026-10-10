/// تنفيذ حفظ مخرجات التوليد الجماعي حسب المنصة.
///
/// على سطح المكتب (Windows/macOS/Linux) يُختار مجلد ويكتب الملف ويُفتح في
/// المستكشف فعلياً، وعلى الويب تُرجع كل العمليات قيماً محايدة بلا كسر البناء —
/// فالاستيراد الشرطي يمنع دخول `dart:io` إلى بناء الويب إطلاقاً.
library;

export 'batch_output_backend_stub.dart'
    if (dart.library.io) 'batch_output_backend_io.dart';
