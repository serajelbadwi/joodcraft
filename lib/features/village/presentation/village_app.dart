/// تطبيق صفحة القرية المستقل — يُشغَّل من `lib/main_village.dart`.
///
/// لماذا تطبيق منفصل؟ لأن قرى المبادرة تحتاج **صفحة عامة**: أي زائر يفتحها
/// ويُدخل كود القرية ويسجّل بياناته بلا حساب ولا تسجيل دخول. تشغيل هذه الصفحة
/// كنقطة دخول مستقلة يحقّق ذلك بلا لمس بوابة الدخول الإلزامية في تطبيق
/// JoodCraft (المحلي أولاً)، ويجعل نشرها على Vercel مستقلةً تماماً.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../data/village_repository.dart';
import '../domain/village_validators.dart';
import 'screens/village_registration_screen.dart';
import 'village_theme.dart';

class VillageApp extends StatelessWidget {
  const VillageApp({super.key, required this.repository});

  /// مستودع بيانات القرية (Supabase في الواقع، وهمي في الاختبارات).
  final VillageRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: VillageText.appTitle,
      debugShowCheckedModeBanner: false,
      theme: VillageTheme.dark,
      // الصفحة عربية فقط عمداً: جمهورها أهل القرية، والاتجاه RTL من اللغة.
      locale: const Locale('ar'),
      supportedLocales: const <Locale>[Locale('ar')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: VillageRegistrationScreen(repository: repository),
    );
  }
}
