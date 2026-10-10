library;

import 'dart:typed_data';

import '../domain/invitation_export_service.dart';

/// حفظ مخرجات دعوات: ملف فردي لكل اسم، بالإضافة إلى ZIP وفهرس CSV.
///
/// التنفيذ يُختار وقت البناء: سطح المكتب ( dart:io ) أو الويب (قيم محايدة).
export 'invitation_output_writer_stub.dart'
    if (dart.library.io) 'invitation_output_writer_io.dart';

abstract interface class InvitationOutputWriter {
  /// مجلد تنزيلات/مستندات الافتراضي (أو `null`).
  Future<String?> defaultDirectory();

  /// يفتح منتقي المجلدات ويعيد المسار المختار (أو `null`).
  Future<String?> pickDirectory({String? dialogTitle});

  /// يكتب كل الملفات الفردية في المجلد ويعيد مسار المجلد (أو `null`).
  Future<String?> saveFiles({
    required String directory,
    required List<InvitationOutputFile> files,
  });

  /// يكتب بايتات جاهزة (ZIP/CSV) ويعيد مسار الملف (أو `null`).
  Future<String?> saveBytes({
    required String directory,
    required String fileName,
    required Uint8List bytes,
  });

  /// يفتح المجلد في مستكشف النظام.
  Future<bool> openDirectory(String directory);
}
