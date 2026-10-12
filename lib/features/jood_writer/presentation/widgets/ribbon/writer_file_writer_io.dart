/// كتابة ملفات حقيقية على المنصّات المكتبية/الجوّالة (dart:io).
library;

import 'dart:io';
import 'dart:typed_data';

Future<void> writeFileTo(String path, Uint8List bytes) async {
  final File file = File(path);
  await file.create(recursive: true);
  await file.writeAsBytes(bytes, flush: true);
}
