/// قراءة ملف البيئة من القرص — يختلف التنفيذ حسب المنصة:
/// على سطح المكتب (Windows/macOS/Linux) يُبحث الملف فعلياً على القرص،
/// وعلى الويب تُرجع `null` ويكفل أصل التطبيق المحزوم (الـ asset) التغطية.
///
/// الاستيراد الشرطي يمنع دخول `dart:io` إلى بناء الويب إطلاقاً.
library;

export 'env_file_reader_stub.dart'
    if (dart.library.io) 'env_file_reader_io.dart';
