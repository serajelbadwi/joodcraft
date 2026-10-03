import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_locale.dart';

/// محرّك لغة التطبيق: يحمل اللغة المختارة، يطبّقها فوراً، ويخزّنها محلياً.
///
/// يتبع النمط المعتمد في المشروع نفسه في `ThemeController` — `SharedPreferences`
/// بلا شبكة، مع قراءة أولية قبل `runApp` (بلا وميض) وكتابة في الخلفية عند كل
/// تغيير. أي قيمة مخزَّنة غير مدعومة تُعامَل كالافتراضية (العربية).
///
/// تغيير اللغة عبر [setLocale] يُطلق [notifyListeners]، فيُعيد `MaterialApp`
/// البناء باللغة والاتجاه الجديدين **بلا إعادة تشغيل التطبيق**.
class LocaleController extends ChangeNotifier {
  LocaleController({SharedPreferences? preferences})
      : _preferences = preferences;

  /// مفتاح التفضيل في `SharedPreferences` (يخزّن رمز اللغة، مثل `ar`).
  static const String prefsKey = 'app_locale';

  SharedPreferences? _preferences;

  /// اللغة الحالية — تبدأ بالافتراضية حتى تُقرأ القيمة المخزَّنة.
  Locale _locale = AppLocales.fallback;

  /// اللغة الحالية (غير قابلة للعدم؛ الافتراضية العربية).
  Locale get locale => _locale;

  /// كائن اللغة الكامل (الاسم الأصلي والاتجاه).
  AppLocale get appLocale => AppLocales.resolve(_locale);

  /// اتجاه الواجهة الموافق للغة الحالية (RTL للعربية والأوردو).
  TextDirection get textDirection => appLocale.direction;

  /// هل اللغة الحالية RTL؟
  bool get isRtl => appLocale.isRtl;

  /// يقرأ اللغة المخزَّنة (إن وُجدت) — يُستدعى قبل `runApp`.
  Future<void> load() async {
    final SharedPreferences preferences =
        _preferences ??= await SharedPreferences.getInstance();
    _locale = AppLocales.parse(preferences.getString(prefsKey)).locale;
    notifyListeners();
  }

  /// يضبط اللغة ويحفظها محلياً. تغيير اللغة نفسها لا يُحدث أثراً.
  Future<void> setLocale(Locale locale) async {
    final Locale next = AppLocales.resolve(locale).locale;
    if (_locale == next) return;
    _locale = next;
    notifyListeners();
    final SharedPreferences preferences =
        _preferences ??= await SharedPreferences.getInstance();
    await preferences.setString(prefsKey, next.languageCode);
  }
}
