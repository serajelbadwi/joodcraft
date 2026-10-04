import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'windows_system_font_service.dart';

/// نتيجة تحميل خط نظام وتسجيله في محرّك خطوط فلاتر.
class SystemFontLoadResult {
  const SystemFontLoadResult({
    required this.family,
    required this.byteData,
    required this.filePath,
  });

  final String family;
  final ByteData byteData;
  final String filePath;

  @override
  String toString() => 'SystemFontLoadResult($family, $filePath)';
}

/// محمّل ديناميكي لخطوط النظام (Windows).
///
/// عند اختيار المستخدم خطاً نظامياً يُقرأ ملفه من القرص، ثم يُسجَّل في
/// `FontLoader` الخاص بفلاتر فيظهر فوراً في المحرر، ويُتاح لمحرّك الطباعة.
///
/// التهدئة: على المنصات غير المدعومة (الويب/الجوال) يُرجع `null` بهدوء بلا
/// أي استثناء — راجع `WindowsSystemFontService`.
abstract final class SystemFontFontLoader {
  SystemFontFontLoader._();

  /// العائلات المسجّلة فعلاً — تسجيل نفس العائلة مرتين مضياع للعمل، فنمنعه.
  static final Set<String> _registered = <String>{};

  /// هل سُجّلت العائلة في محرّك خطوط فلاتر مسبقاً في هذه الجلسة؟
  static bool isRegistered(String family) => _registered.contains(family);

  /// يحمّل خط النظام [family] ويسجّله في محرّك الخطوط.
  ///
  /// * [onProgress] يُستدعَى عند اكتمال التحميل (اختياري).
  /// * [onError] يُستدعَى عند الفشل بلا رمي (اختياري).
  ///
  /// يُرجع نتيجة التحميل عند النجاح، أو `null` إن تعذّر.
  static Future<SystemFontLoadResult?> loadSystemFont(
    String family, {
    void Function(int loaded, int total)? onProgress,
    void Function(String error)? onError,
  }) async {
    if (!WindowsSystemFontService.isSupported) {
      debugPrint(
        '[SystemFontFontLoader] منصة غير مدعومة — تخطّي تحميل «$family» '
        '(تهدئة سليمة).',
      );
      return null;
    }

    final String normalized = family.trim();
    if (normalized.isEmpty) {
      onError?.call('اسم عائلة الخط فارغ.');
      return null;
    }

    final WindowsFontDiscoveryResult discovery =
        await WindowsSystemFontService.discover(
      onError: (String source, String error) => debugPrint(
        '[SystemFontFontLoader] فشل مصدر $source: $error',
      ),
    );

    final WindowsSystemFontFamily? target = _find(discovery.families, normalized);
    if (target == null || target.filePaths.isEmpty) {
      onError?.call('لم يُعثر على ملف خط للعائلة «$normalized».');
      return null;
    }

    for (final String path in target.filePaths) {
      final ByteData? bytes = await WindowsSystemFontService.readFontBytes(path);
      if (bytes == null) continue;
      try {
        final FontLoader loader = FontLoader(normalized)
          ..addFont(Future<ByteData>.value(bytes));
        await loader.load();
        _registered.add(normalized);
        onProgress?.call(1, 1);
        return SystemFontLoadResult(
          family: normalized,
          byteData: bytes,
          filePath: path,
        );
      } on Object catch (error) {
        onError?.call('تعذّر تسجيل «$normalized» من $path: $error');
      }
    }
    return null;
  }

  static WindowsSystemFontFamily? _find(
    List<WindowsSystemFontFamily> families,
    String family,
  ) {
    final String needle = family.toLowerCase();
    for (final WindowsSystemFontFamily candidate in families) {
      if (candidate.displayName.toLowerCase() == needle) return candidate;
    }
    return null;
  }
}
