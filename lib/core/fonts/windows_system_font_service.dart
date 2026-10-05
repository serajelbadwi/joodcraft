import 'package:flutter/foundation.dart';

import 'system_font_cache.dart';
import 'system_font_models.dart';
import 'system_font_scanner_stub.dart'
    if (dart.library.io) 'system_font_scanner_io.dart';

export 'system_font_models.dart';

/// خادم اكتشاف خطوط نظام التشغيل المثبتة (Windows) — مشابه لقائمة الخطوط في
/// Word أو Photoshop.
///
/// هذا الملف **واجهة بلا `dart:io`**: التنفيذ الفعلي يُستورد شرطياً، فيعمل نفس
/// الكود على الويب والجوال بلا كسر البناء (يُرجع فراغاً هناك).
///
/// **التخزين المؤقت:** نتيجة الفحص وبايتات الخطوط المقرؤة تُحفظ كسولاً في
/// [SystemFontCache]، فلا يُعاد فحص نظام الملفات ولا السجل ولا تُعاد قراءة ملف
/// الخط عند كل فتح لمنتقي الخطوط أو كل تبديل لخط نظامي.
abstract final class WindowsSystemFontService {
  const WindowsSystemFontService._();

  /// الدليل الرئيسي لخطوط النظام على Windows.
  static const String defaultFontsDir = r'C:\Windows\Fonts';

  /// مفتاح السجل الذي يسرد الخطوط المثبتة.
  static const String registryFontsKey =
      r'SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts';

  /// أقصى عدد ملفات خطوط تُحفظ بايتاتها في الذاكرة (حدّ أعلى LRU).
  ///
  /// الخطوط النظامية قد تكون ثقيلة، فنُبقي أحدث ملفات مُختارة فقط؛ وما يُسقط
  /// يُعاد قراءته من القرص لاحقاً بلا خطأ.
  static const int defaultMaxCachedFontFiles = 8;

  /// كاش نتيجة الفحص — المفتاح هو محدّد المنصة (‎`auto` لغير الفحص الصريح).
  static final SystemFontCache<WindowsFontDiscoveryResult> _discoveryCache =
      SystemFontCache<WindowsFontDiscoveryResult>();

  /// كاش بايتات ملفات الخطوط — المفتاح هو مسار الملف، مع حدّ أعلى LRU.
  static final SystemFontCache<ByteData?> _bytesCache =
      SystemFontCache<ByteData?>(maxEntries: defaultMaxCachedFontFiles);

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
  /// * [force] يعيد الفحص من الصفر ويتجاهل النتيجة المخزّنة.
  static Future<WindowsFontDiscoveryResult> discover({
    String? platform,
    void Function(String source, String error)? onError,
    bool force = false,
  }) =>
      _discoveryCache.get(
        platform == null || platform.isEmpty
            ? 'auto'
            : platform.toLowerCase(),
        () => discoverSystemFonts(platform: platform, onError: onError),
        force: force,
      );

  /// يقرأ بايتات ملف خط نظام من القرص، أو `null` إن تعذّر.
  ///
  /// * [force] يعيد القراءة من القرص ويتجاهل البايتات المخزّنة.
  static Future<ByteData?> readFontBytes(String path, {bool force = false}) =>
      _bytesCache.get(path, () => readSystemFontBytes(path), force: force);

  /// هل الفحص مخزّن للمنصة الافتراضية (بلا تحديد صريح)؟
  static bool get hasCachedDiscovery => _discoveryCache.containsKey('auto');

  /// هل بايتات [path] مخزّنة في الذاكرة؟
  static bool isFontCached(String path) => _bytesCache.containsKey(path);

  /// يفرّغ كاش الفحص والبايتات (لأداة «تحديث» أو إعادة ضبط كاملة).
  static void clearCache() {
    _discoveryCache.clear();
    _bytesCache.clear();
  }

  /// كاش الفحص — لأغراض التخزين/التشخيص والاختبارات فقط.
  @visibleForTesting
  static SystemFontCache<WindowsFontDiscoveryResult> get debugDiscoveryCache =>
      _discoveryCache;

  /// كاش البايتات — لأغراض التخزين/التشخيص والاختبارات فقط.
  @visibleForTesting
  static SystemFontCache<ByteData?> get debugBytesCache => _bytesCache;
}
