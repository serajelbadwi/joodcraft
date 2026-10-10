import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'batch_output_service.dart';

/// تنفيذ سطح المكتب: يختار مجلداً عبر [`FilePicker`]، ويكتب ملف الـ PDF فيه،
/// ويفتحه في مستكشف النظام (explorer/open/xdg-open) بلا أي حزمة إضافية.
BatchOutputService createBatchOutputService() =>
    const _DesktopBatchOutputService();

class _DesktopBatchOutputService implements BatchOutputService {
  const _DesktopBatchOutputService();

  @override
  Future<String?> pickDirectory({String? dialogTitle}) async {
    try {
      return await FilePicker.getDirectoryPath(
        dialogTitle: dialogTitle,
        initialDirectory: await defaultDirectory(),
      );
    } on Object {
      // منتقي غير متاح (بيئة بلا واجهة مثلاً) — نُرجع للتلقائي بلا خطأ.
      return null;
    }
  }

  @override
  Future<String?> defaultDirectory() async {
    final Map<String, String> env = Platform.environment;
    final String? home = env['USERPROFILE'] ?? env['HOME'];
    if (home == null || home.trim().isEmpty) return null;
    for (final String name in const <String>['Downloads', 'Documents']) {
      final Directory candidate = Directory(_join(home, name));
      if (candidate.existsSync()) return candidate.path;
    }
    return Directory(home).path;
  }

  @override
  Future<String?> savePdf({
    required String directory,
    required String fileName,
    required Uint8List bytes,
  }) async {
    try {
      final Directory dir = Directory(directory);
      if (!await dir.exists()) await dir.create(recursive: true);
      final File file = File(_join(directory, fileName));
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } on Object {
      return null;
    }
  }

  @override
  Future<String?> createSubdirectory({
    required String directory,
    required String name,
  }) async {
    try {
      final String path = _join(directory, name);
      final Directory dir = Directory(path);
      if (!await dir.exists()) await dir.create(recursive: true);
      return dir.path;
    } on Object {
      return null;
    }
  }

  @override
  Future<bool> openDirectory(String directory) async {
    try {
      if (!await Directory(directory).exists()) return false;
      if (Platform.isWindows) {
        await Process.run('explorer', <String>[directory]);
      } else if (Platform.isMacOS) {
        await Process.run('open', <String>[directory]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', <String>[directory]);
      } else {
        return false;
      }
      return true;
    } on Object {
      return false;
    }
  }
}

String _join(String directory, String name) =>
    directory.endsWith(Platform.pathSeparator)
        ? '$directory$name'
        : '$directory${Platform.pathSeparator}$name';
