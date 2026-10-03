import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import '../../../../core/errors/app_error_code.dart';
import '../../../../core/errors/app_exception.dart';
import '../domain/sheet_reader.dart';

/// وسوم رسائل الـ isolate الواردة.
const int _tagDone = 1;
const int _tagError = 2;

/// طلب قراءة ورقة بيانات قابل للإرسال بين الـ isolates.
///
/// لا يحمل إلا بايتات الملف واسمه واسم الورقة المطلوبة — كلها قابل للنقل، ولا
/// يُنقل أي كائن من مكتبة `excel` بين الخيوط.
class SheetParseRequest {
  const SheetParseRequest({
    required this.fileName,
    required this.bytes,
    this.sheetName,
    this.headerRowIndex,
  });

  final String fileName;
  final Uint8List bytes;

  /// اسم الورقة المطلوب قراءتها؛ `null` = أول ورقة في المصنّف.
  final String? sheetName;

  /// فهرس صف العناوين (يبدأ من صفر)؛ `null` = اكتشاف تلقائي.
  final int? headerRowIndex;
}

/// قراءة وتفكيك ملف Excel داخل isolate خلفي — بلا تجميد خيط الواجهة.
///
/// ملفات Excel بآلاف الصفوف يستغرق تفكيكها زمناً ملموساً؛ نقلها إلى الخلفية
/// يُبقي الواجهة سلسة (نفس نمط توليد الـ PDF في `renderPdfInBackground`).
/// يعيد [SheetReadResult] (الورقة + أسماء كل الأوراق) أو يرمي [AppException]
/// برسالة عربية جاهزة للعرض.
Future<SheetReadResult> parseSheetInBackground(SheetParseRequest request) async {
  final ReceivePort receive = ReceivePort();
  final Completer<SheetReadResult> completer = Completer<SheetReadResult>();
  Isolate? isolate;

  final StreamSubscription<dynamic> subscription = receive.listen(
    (Object? message) {
      if (message is! List || message.isEmpty) return;
      switch (message[0]) {
        case _tagDone:
          if (!completer.isCompleted) {
            completer.complete(message[1] as SheetReadResult);
          }
        case _tagError:
          if (!completer.isCompleted) {
            completer.completeError(
              AppException(
                AppErrorCode.excelImport,
                message: message[1] as String,
              ),
            );
          }
      }
    },
    onError: (Object error) {
      if (!completer.isCompleted) completer.completeError(error);
    },
  );

  try {
    isolate = await Isolate.spawn(
      _sheetIsolateEntry,
      <Object?>[receive.sendPort, request],
      debugName: 'joodcraft-sheet',
    );
    return await completer.future;
  } finally {
    isolate?.kill(priority: Isolate.immediate);
    await subscription.cancel();
    receive.close();
  }
}

/// نقطة دخول الـ isolate — تقرأ الملف وتبثّ النتيجة أو رسالة الخطأ.
void _sheetIsolateEntry(Object? message) {
  final List<Object?> args = message as List<Object?>;
  final SendPort send = args[0] as SendPort;
  final SheetParseRequest request = args[1] as SheetParseRequest;
  try {
    final SheetReadResult result = SheetReaders.readResult(
      request.bytes,
      fileName: request.fileName,
      sheetName: request.sheetName,
      headerRowIndex: request.headerRowIndex,
    );
    send.send(<Object?>[_tagDone, result]);
  } on AppException catch (error) {
    send.send(<Object?>[_tagError, error.message]);
  } catch (error) {
    send.send(<Object?>[_tagError, 'تعذّر قراءة الملف: $error']);
  }
}
