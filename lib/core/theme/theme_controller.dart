import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// محرّك مظهر التطبيق: يدير `ThemeMode` ويخزّن تفضيل المستخدم محلياً.
///
/// الحل المعتمد في المشروع للتخزين هو `SharedPreferences` (نفسه المستخدم في
/// مكتبة الأصول والخطوط) — فيعود التطبيق للوضع المختار عند إغلاقه وإعادة فتحه.
///
/// القراءة والكتابة غير متزامنتين عمداً: [load] تُستدعى مرة واحدة قبل
/// `runApp` (وضع أولي ثابت بلا وميض)، ثم [setMode] تحفظ في الخلفية فور
/// التغيير. القيم الفاسدة أو المجهولة تُعامَل كـ [ThemeMode.system].
class ThemeController extends ChangeNotifier {
  ThemeController({SharedPreferences? preferences})
      : _preferences = preferences;

  /// مفتاح التفضيل في `SharedPreferences`.
  static const String prefsKey = 'app_theme_mode';

  /// القيم المخزّنة المقبولة (مطابقة لـ `ThemeMode.name`).
  static const String systemValue = 'system';
  static const String lightValue = 'light';
  static const String darkValue = 'dark';

  SharedPreferences? _preferences;
  ThemeMode _mode = ThemeMode.system;

  /// الوضع المُخزَّن (الأولى عند الإقلاع).
  ThemeMode get mode => _mode;

  /// هل المظهر الداكن معروض حالياً (مع احتساب وضع النظام من إعدادات الجهاز).
  bool get isDark => _effectiveBrightness == Brightness.dark;

  /// السطوع الفعلي المُعرَض: وضع النظام يقرأ سطوع المنصة.
  Brightness get _effectiveBrightness {
    switch (_mode) {
      case ThemeMode.system:
        return WidgetsBinding
            .instance.platformDispatcher.platformBrightness;
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
    }
  }

  /// يقرأ التفضيل المخزَّن (إن وُجد) — يُستدعى قبل `runApp`.
  Future<void> load() async {
    final SharedPreferences preferences =
        _preferences ??= await SharedPreferences.getInstance();
    _mode = parse(preferences.getString(prefsKey));
    notifyListeners();
  }

  /// يضبط الوضع ويحفظه محلياً.
  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final SharedPreferences preferences =
        _preferences ??= await SharedPreferences.getInstance();
    await preferences.setString(prefsKey, encode(mode));
  }

  /// تبديل بنقرة واحدة: ينقل إلى عكس المظهر المعروض حالياً،
  /// فيتحوّل نظام→داكن إذا كان النظام فاتحاً (والعكس) فلا يبدو النقر بلا أثر.
  Future<void> toggle() => setMode(
        isDark ? ThemeMode.light : ThemeMode.dark,
      );

  /// تحويل نص مخزَّن إلى وضع — أي قيمة مجهولة تعود إلى [ThemeMode.system].
  static ThemeMode parse(String? raw) {
    switch (raw) {
      case lightValue:
        return ThemeMode.light;
      case darkValue:
        return ThemeMode.dark;
      case systemValue:
      default:
        return ThemeMode.system;
    }
  }

  /// تحويل الوضع إلى نص للتخزين.
  static String encode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return lightValue;
      case ThemeMode.dark:
        return darkValue;
      case ThemeMode.system:
        return systemValue;
    }
  }
}
