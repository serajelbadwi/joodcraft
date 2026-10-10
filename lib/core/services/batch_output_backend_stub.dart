import 'dart:typed_data';

import 'batch_output_service.dart';

/// تنفيذ الويب: لا نظام ملفات ولا مستكشف، فتُرجع كل العمليات قيماً محايدة
/// بلا رمي، وتبقى واجهة التوليد قابلة للاستخدام (تصدير/طباعة فقط).
BatchOutputService createBatchOutputService() => const _WebBatchOutputService();

class _WebBatchOutputService implements BatchOutputService {
  const _WebBatchOutputService();

  @override
  Future<String?> pickDirectory({String? dialogTitle}) async => null;

  @override
  Future<String?> defaultDirectory() async => null;

  @override
  Future<String?> savePdf({
    required String directory,
    required String fileName,
    required Uint8List bytes,
  }) async =>
      null;

  @override
  Future<String?> createSubdirectory({
    required String directory,
    required String name,
  }) async =>
      null;

  @override
  Future<bool> openDirectory(String directory) async => false;
}
