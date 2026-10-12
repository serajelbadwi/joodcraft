/// كتابة ملفات على المنصّات غير المتصلة بالملفات (ويب) — لا تفعل شيئاً؛
/// التنزيل على الويب يتم داخل `FilePicker.saveFile(bytes:)`.
library;

import 'dart:typed_data';

Future<void> writeFileTo(String path, Uint8List bytes) async {}
