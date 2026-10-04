import 'dart:typed_data';

import 'system_font_models.dart';

/// تنفيذ الويب/الجوال الفارغ لفحص خطوط النظام.
///
/// الغرض: التهدئة (graceful degradation) — على المنصات التي لا تملك نظام ملفات
/// (الويب) يُرجَع فراغ دائماً بلا أي استثناء، فلا ينكسر البناء ولا الواجهة.
Future<WindowsFontDiscoveryResult> discoverSystemFonts({
  String? platform,
  void Function(String source, String error)? onError,
}) async =>
    const WindowsFontDiscoveryResult(
      families: <WindowsSystemFontFamily>[],
      scannedDirs: <String>[],
      error: null,
    );

/// لا نظام ملفات على الويب — لا بايتات لقراءتها.
Future<ByteData?> readSystemFontBytes(String path) async => null;
