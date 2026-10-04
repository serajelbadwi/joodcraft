import 'package:flutter/foundation.dart';

import 'system_font_models.dart';
import 'system_font_scanner_stub.dart'
    if (dart.library.io) 'system_font_scanner_io.dart';

export 'system_font_models.dart';

/// خادم اكتشاف خطوط نظام التشغيل المثبتة (Windows) — مشابه لقائمة الخطوط في
/// Word أو Photoshop.
///
/// هذا الملف **واجهة بلا `dart:io`**: التنفيذ الفعلي يُستورد شرطياً، فيعمل نفس
/// الكود على الويب والجوال بلا كسر البناء (يُرجع فراغاً هناك).
abstract final class WindowsSystemFontService {
  const WindowsSystemFontService._();

  /// الدليل الرئيسي لخطوط النظام على Windows.
  static const String defaultFontsDir = r'C:\Windows\Fonts';

  /// مفتاح السجل الذي يسرد الخطوط المثبتة.
  static const String registryFontsKey =
      r'SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts';

  /// هل يمكن فحص خطوط النظام على المنصة الحالية؟
  ///
  /// `true` على سطح المكتب (Windows) فقط؛ الويب والجوال يُرجعان `false` فتتراجع
  /// الواجهة إلى الخطوط المضمّنة بلا أي أخطاء.
  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  /// يفحص خطوط النظام المتاحة على الجهاز.
  ///
  /// * [platform] يُمرَّر عادةً من الاختبارات (`'windows'`/`'web'`…) لضبط السلوك.
  /// * [onError] يُستدعَى عند فشل مصدر (صلاحيات مثلاً) بلا رمي.
  static Future<WindowsFontDiscoveryResult> discover({
    String? platform,
    void Function(String source, String error)? onError,
  }) =>
      discoverSystemFonts(platform: platform, onError: onError);

  /// يقرأ بايتات ملف خط نظام من القرص، أو `null` إن تعذّر.
  static Future<ByteData?> readFontBytes(String path) =>
      readSystemFontBytes(path);
}
