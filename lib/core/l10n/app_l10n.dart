import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';

/// وصول مرن إلى نصوص الترجمة المولَّدة.
///
/// `AppLocalizations.of` غير قابلة للعدم وتُطلق استثناءً إن غاب المندوب — كما
/// في كثير من اختبارات الودجات التي تبني `MaterialApp` مجرّدة بلا مندوبي
/// الترجمة. استخدام `Localizations.of` هنا يُرجع `null` بهدوء، فتستطيع كل شاشة
/// أن تتبنّى الترجمة تدريجياً مع نص عربي احتياطي بلا كسر الاختبارات القائمة.
abstract final class AppL10n {
  const AppL10n._();

  /// نصوص الترجمة في السياق، أو `null` إن لم تُمرَّر مندوبي الترجمة.
  static AppLocalizations? of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations);
}

/// صيغة مختصرة لاستخدام الشاشات: `context.l10n?.someKey ?? 'احتياطي'`.
extension AppL10nContext on BuildContext {
  AppLocalizations? get l10n => AppL10n.of(this);
}
