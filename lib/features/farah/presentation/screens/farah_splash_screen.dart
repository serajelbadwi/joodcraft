/// شاشة افتتاح «فرح» — شعار التطبيق يدخل بتلاشٍ وتكبير ثم يخرج، ومن بعده
/// تُفتح شاشة الدخول.
///
/// **لماذا شاشة افتتاح أصلاً؟** لأن التطبيق يُفتح من رابط مباشرة على الويب
/// (Vercel) وفيه تهيئة عميل Supabase تأخذ لحظة: الواجهة الذهبية على الرمادي
/// الداكن تُبقي العين مشدودة место رسالة خطأ أو شاشة بيضاء.
///
/// **الزمن كله محسوب لا محسوس**: دخول ‎1.2s‎ (`easeOutBack` يعطي الشعار
/// «قفزة» طفيفة عند الوصول — حياة لا ميتة)، ثبات ‎0.7s‎، خروج ‎0.7s‎،
/// ثم انتقال عند ‎2.8s‎ — أي **بلا ضغطة زر** على الإطلاق.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../data/farah_repository.dart';
import '../../domain/farah_text.dart';
import '../../../village/presentation/village_theme.dart';
import '../farah_theme.dart';
import 'farah_login_screen.dart';

class FarahSplashScreen extends StatefulWidget {
  const FarahSplashScreen({super.key, required this.repository});

  /// المستودع يُمرَّر إلى شاشة الدخول بعد انتهاء العرض (الشاشة لا تقرأ بيانات).
  final FarahRepository repository;

  @override
  State<FarahSplashScreen> createState() => _FarahSplashScreenState();
}

class _FarahSplashScreenState extends State<FarahSplashScreen>
    with SingleTickerProviderStateMixin {
  /// زمن الحركة كاملاً: دخول ‎1.2s‎ + ثبات ‎0.7s‎ + خروج ‎0.7s‎.
  static const Duration _total = Duration(milliseconds: 2600);

  /// لحظة الانتقال إلى الدخول — بعد خروج الشعار بقليل فيهدأ الانتقال.
  static const Duration _navigateAfter = Duration(milliseconds: 2800);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _total,
  )..forward();

  /// تكبير الشعار ‎0.5 → 1.0‎ في أول ‎1.2s‎ (‎0.4615 = 1200/2600‎ من الزمن).
  /// `easeOutBack` يتجاوز ‎1.0‎ قليلاً قبل الاستقرار — وهي «القفزة» المقصودة.
  late final Animation<double> _scale = Tween<double>(begin: 0.5, end: 1.0)
      .animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.4615, curve: Curves.easeOutBack),
        ),
      );

  /// تلاشٍ متتابع: دخول (‎0→1‎) + ثبات + خروج (‎1→0‎) — بأوزان ميلي‑ثانية
  /// تُترجم إلى أزمنة المتحكّم الحقيقية فلا يختلّ التوقيت بتغيير المدة.
  late final Animation<double> _opacity = TweenSequence<double>(
    <TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 800,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 1100,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 700,
      ),
    ],
  ).animate(_controller);

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_navigateAfter, _goToLogin);
  }

  /// الانتقال: `pushReplacement` لا `push` — فلا يستطيع زرّ الرجوع إعادة
  /// العاطل (البداية الحقيقية هي الدخول).
  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            FarahLoginScreen(repository: widget.repository),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Theme(
        data: FarahTheme.dark,
        child: Scaffold(
          // خلفية القرية نفسها `#3D3D3D`: الشاشة امتداد للوحة لا صندوق جديد.
          backgroundColor: VillageColors.background,
          body: Center(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double logoWidth = switch (constraints.maxWidth) {
                  < 520 => constraints.maxWidth * 0.62,
                  < 820 => 300.0,
                  _ => 340.0,
                };
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    FadeTransition(
                      opacity: _opacity,
                      child: ScaleTransition(
                        scale: _scale,
                        child: Image.asset(
                          AppAssets.farahLogoImage,
                          key: const ValueKey<String>('farah-splash-logo'),
                          width: logoWidth,
                          fit: BoxFit.contain,
                          // غياب الأصل = خطأ توزيع: يظهر اسم التطبيق نصّاً
                          // بدل شاشة عرض فارغة تماماً (نفس مبدأ ترويسة القرية).
                          errorBuilder: (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) =>
                              const _SplashFallback(),
                        ),
                      ),
                    ),
                    const SizedBox(height: VillageMetrics.space24),
                    FadeTransition(
                      opacity: _opacity,
                      child: const Text(
                        FarahText.appName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppAssets.amiriFont,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: VillageColors.goldSoft,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// البديل عند غياب الأصل من الحزمة — اسم التطبيق بخط Amiri الذهبي.
class _SplashFallback extends StatelessWidget {
  const _SplashFallback();

  @override
  Widget build(BuildContext context) {
    return const Text(
      FarahText.appName,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: AppAssets.amiriFont,
        fontSize: 42,
        fontWeight: FontWeight.w700,
        color: VillageColors.gold,
        height: 1.3,
      ),
    );
  }
}
