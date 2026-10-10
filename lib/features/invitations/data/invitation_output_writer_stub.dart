import 'dart:typed_data';

import '../domain/invitation_export_service.dart';
import 'invitation_output_writer.dart';

/// تنفيذ الويب: لا نظام ملفات، فتُرجع كل العمليات قيماً محايدة بلا كسر البناء.
InvitationOutputWriter createInvitationOutputWriter() =>
    const _WebInvitationOutputWriter();

class _WebInvitationOutputWriter implements InvitationOutputWriter {
  const _WebInvitationOutputWriter();

  @override
  Future<String?> defaultDirectory() async => null;

  @override
  Future<String?> pickDirectory({String? dialogTitle}) async => null;

  @override
  Future<String?> saveFiles({
    required String directory,
    required List<InvitationOutputFile> files,
  }) async =>
      null;

  @override
  Future<String?> saveBytes({
    required String directory,
    required String fileName,
    required Uint8List bytes,
  }) async =>
      null;

  @override
  Future<bool> openDirectory(String directory) async => false;
}
