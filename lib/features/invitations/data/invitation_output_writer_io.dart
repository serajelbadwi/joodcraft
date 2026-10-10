import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../domain/invitation_export_service.dart';
import 'invitation_output_writer.dart';

/// تنفيذ سطح المكتب: يختار مجلداً ويكتب الملفات ويفتح المستكشف.
InvitationOutputWriter createInvitationOutputWriter() =>
    const _DesktopInvitationOutputWriter();

class _DesktopInvitationOutputWriter implements InvitationOutputWriter {
  const _DesktopInvitationOutputWriter();

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
  Future<String?> pickDirectory({String? dialogTitle}) async {
    try {
      return await FilePicker.getDirectoryPath(
        dialogTitle: dialogTitle,
        initialDirectory: await defaultDirectory(),
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<String?> saveFiles({
    required String directory,
    required List<InvitationOutputFile> files,
  }) async {
    try {
      final Directory dir = Directory(directory);
      if (!await dir.exists()) await dir.create(recursive: true);
      for (final InvitationOutputFile file in files) {
        final File target = File(_join(directory, file.fileName));
        await target.writeAsBytes(file.bytes, flush: true);
      }
      return dir.path;
    } on Object {
      return null;
    }
  }

  @override
  Future<String?> saveBytes({
    required String directory,
    required String fileName,
    required Uint8List bytes,
  }) async {
    try {
      final Directory dir = Directory(directory);
      if (!await dir.exists()) await dir.create(recursive: true);
      final File target = File(_join(directory, fileName));
      await target.writeAsBytes(bytes, flush: true);
      return target.path;
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
