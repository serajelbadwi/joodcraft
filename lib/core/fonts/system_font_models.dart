import 'package:flutter/foundation.dart';

/// عائلة خط نظامية واحدة (‎Windows) مع مسارات ملفاتها على القرص.
///
/// هذا النموذج **نقي** ولا يستورد `dart:io`، فيُستخدم من الويب والجوال أيضاً
/// بلا كسر البناء — راجع `system_font_scanner_stub.dart`.
class WindowsSystemFontFamily {
  const WindowsSystemFontFamily({
    required this.displayName,
    required this.filePaths,
    this.isSystemFont = true,
  });

  /// الاسم المعروض للمستخدم (يطابق اسم العائلة في محرّك الخطوط).
  final String displayName;

  /// مسارات الملفات الكاملة للعائلة (مثل `C:\Windows\Fonts\arial.ttf`).
  final List<String> filePaths;

  /// `true` إذا كان خطاً نظامياً (لا خطاً رفعه المستخدم).
  final bool isSystemFont;

  @override
  bool operator ==(Object other) =>
      other is WindowsSystemFontFamily &&
      other.displayName == displayName &&
      listEquals(other.filePaths, filePaths);

  @override
  int get hashCode => Object.hash(displayName, Object.hashAll(filePaths));

  @override
  String toString() => '$displayName (${filePaths.length} files)';
}

/// نتيجة فحص خطوط النظام.
class WindowsFontDiscoveryResult {
  const WindowsFontDiscoveryResult({
    required this.families,
    required this.scannedDirs,
    this.error,
  });

  /// العائلات المكتشفة (بلا تكرار)، كل عائلة تحمل ملفاتها.
  final List<WindowsSystemFontFamily> families;

  /// المجلدات التي قُرئت فعلاً (للتشخيص).
  final List<String> scannedDirs;

  /// رسالة خطأ مجمّعة إن فشل مصدر (لا يمنع إرجاع ما نجح).
  final String? error;

  bool get isEmpty => families.isEmpty;
}
