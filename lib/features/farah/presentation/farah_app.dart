/// تطبيق «فرح» المستقل — يُشغَّل من `lib/main_farah.dart`.
///
/// لماذا تطبيق منفصل؟ لأن «فرح» تواصل أهل القرية: عضو يدخل برقم تليفونه
/// (بلا OTP كما صُمِّمت صفحة القرية) ويراسل أهل قريته بهدوء. تشغيله كنقطة
/// دخول مستقلة يحقّق ذلك **بلا بوابة الدخول الإلزامية في تطبيق JoodCraft**
/// (المحلي أولاً)، ويجعل نشره على Vercel مستقلّاً تماماً كصفحة القرية.
///
/// الألوان والخطوط **هي نفسها تماماً** كصفحة القرية — مصدرها واحد
/// (`VillageTheme` عبر `FarahTheme`) فلا تتفرّع اللوحة بين الصفحتين.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../data/supabase_farah_repository.dart';
import '../data/farah_repository.dart';
import '../domain/farah_text.dart';
import 'screens/jood_reach_splash_screen.dart';
import 'farah_theme.dart';

class FarahApp extends StatelessWidget {
  const FarahApp({super.key, this.repository = const SupabaseFarahRepository()});

  /// مستودع بيانات «فرح» (Supabase في الواقع، وهمي في الاختبارات) —
  /// وقابليته الافتراضي يجعل تشغيل التطبيق بسطر واحد ممكناً:
  /// `runApp(const FarahApp())`.
  final FarahRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // عنوان النافذة/تبويب المتصفح: هوية **Jood Reach** (لا الاسم القديم).
      title: FarahText.joodReachName,
      debugShowCheckedModeBanner: false,
      theme: FarahTheme.dark,
      // التطبيق عربي فقط عمداً: جمهوره أهل القرية، والاتجاه RTL من اللغة
      // (وشاشاته تُثبِّت RTL أيضاً حتى لو غيّر مضيفها اللغة).
      locale: const Locale('ar'),
      supportedLocales: const <Locale>[Locale('ar')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // البداية شاشة افتتاح «Jood Reach» (الاسم الذهبي ‎5s‎ مع لمعة ونبض)
      // ثم الدخول تلقائياً بانتقال باهت — ولا تُعدَّ الشاشة الأولى الدخول
      // مباشرةً بعد اليوم.
      home: JoodReachSplashScreen(repository: repository),
    );
  }
}
