/// شاشة افتتاح «Jood Reach» — منصّة الوصول والإشعارات.
///
/// هويّة مستقلّة عن لوحة القرية: خلفية كحلية داكنة متدرّجة قطرياً
/// (‎`#0F1B3C` → `#1A2A4A`‎) والاسم بخط Amiri الحادي بلون ذهبي متدرّج،
/// وشريط لمعة ذهبي يعبره ثم نبض خفيف حتى الخروج — ثم انتقال تلقائي إلى
/// شاشة الدخول **بلا ضغطة زرّ**.
///
/// الزمن كله محسوب لا محسوس من مدة واحدة ‎3.0s‎ (‎`AnimationController`‎
/// + `Interval` لكل مرحلة):
///
/// | المرحلة | الزمن | ماذا تفعل |
/// |---------|-------|-----------|
/// | الظهور | ‎0.0–0.8s‎ | تلاشٍ ‎0→1‎ + تكبير ‎0.8→1.0‎ (`easeOutCubic`)، والاسم الفرعي ‎0.3–1.05s‎ |
/// | اللمعان | ‎0.8–1.4s‎ | شريط ذهبي فاتح يعبر الاسم من اليسار لليمين |
/// | التوقّف | ‎1.4–2.6s‎ | الاسم ثابت + نبض كل ‎0.5s‎ (توهّج + تكبير ‎1.2%‎) |
/// | الخروج | ‎2.6–3.0s‎ | تلاشٍ ‎1→0‎ + انزلاق للأعلى (`easeInCubic`) |
///
/// وعند ‎3.0s‎: `pushReplacement` إلى [FarahLoginScreen] بانتقال باهت — فلا
/// يستطيع زرّ الرجوع إعادة الافتتاح (البداية الحقيقية هي الدخول).
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../data/farah_repository.dart';
import '../farah_theme.dart';
import 'farah_login_screen.dart';

class JoodReachSplashScreen extends StatefulWidget {
  const JoodReachSplashScreen({super.key, required this.repository});

  /// المستودع يُمرَّر إلى شاشة الدخول بعد انتهاء العرض (الشاشة لا تقرأ بيانات).
  final FarahRepository repository;

  @override
  State<JoodReachSplashScreen> createState() => _JoodReachSplashScreenState();
}

class _JoodReachSplashScreenState extends State<JoodReachSplashScreen>
    with SingleTickerProviderStateMixin {
  // ── هويّة Jood Reach — قيم المهمة حرفيةً ──────────────────────────────
  /// كحلي داكن (بداية التدرّج) وفاتحه (نهايته) — تدرّج قطري.
  static const Color _navyDeep = Color(0xFF0F1B3C);
  static const Color _navySoft = Color(0xFF1A2A4A);

  /// الذهبي الثلاثي: غامق ← فاتح ← غامق (تدرّج الاسم).
  static const Color _goldDark = Color(0xFFB8932E);
  static const Color _goldLight = Color(0xFFD4AF4F);

  /// لون اللمعة — ذهبي فاتح شبه أبيض يعبر الاسم.
  static const Color _shimmerColor = Color(0xFFFFE9A8);

  /// اسم التطبيق هويّة إنجليزية (‎J‎ كبيرة‎)‎ — نصّ لا يُترجم.
  static const String _appName = 'Jood Reach';

  /// الاسم الفرعي العربي أسفله.
  static const String _tagline = 'منصة الوصول والإشعارات';

  // ── الزمن والمراحل ────────────────────────────────────────────────────
  static const Duration _total = Duration(milliseconds: 3000);

  /// ظهور ‎0.0–0.8s‎: تلاشٍ + تكبير ‎0.8→1.0‎.
  static const Interval _appear = Interval(
    0.0,
    0.8 / 3.0,
    curve: Curves.easeOutCubic,
  );

  /// لمعان ‎0.8–1.4s‎: الشريط يعبر الاسم.
  static const Interval _shimmerPhase = Interval(
    0.8 / 3.0,
    1.4 / 3.0,
    curve: Curves.easeInOut,
  );

  /// توقّف ‎1.4–2.6s‎: الاسم ثابت والنبض يعمل.
  static const Interval _holdPhase = Interval(1.4 / 3.0, 2.6 / 3.0);

  /// خروج ‎2.6–3.0s‎: تلاشٍ + انزلاق للأعلى.
  static const Interval _exit = Interval(
    2.6 / 3.0,
    1.0,
    curve: Curves.easeInCubic,
  );

  /// الاسم الفرعي يظهر متأخّراً ‎0.3s‎ عن الاسم (‎0.3–1.05s‎).
  static const Interval _taglinePhase = Interval(0.1, 0.35);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _total,
  )..forward();

  /// مرحلة الظهور المشتركة (تلاشٍ + تكبير).
  late final CurvedAnimation _appearCurve = CurvedAnimation(
    parent: _controller,
    curve: _appear,
  );

  /// تكبير الاسم ‎0.8 → 1.0‎.
  late final Animation<double> _scale = Tween<double>(
    begin: 0.8,
    end: 1.0,
  ).animate(_appearCurve);

  /// موضع الشريط المضيء: من ‎-1.6‎ (خارج الحافة اليسرى) إلى ‎+1.6‎ (خارج
  /// اليمنى) — أي عبور كامل من اليسار لليمين خلال مرحلة اللمعان.
  late final Animation<double> _shimmerSweep = Tween<double>(
    begin: -1.6,
    end: 1.6,
  ).animate(
    CurvedAnimation(parent: _controller, curve: _shimmerPhase),
  );

  /// قيمة مرحلة التوقّف ‎0→1‎ — أساس دورة النبض.
  late final Animation<double> _hold = CurvedAnimation(
    parent: _controller,
    curve: _holdPhase,
  );

  /// تلاشٍ الخروج ‎1→0‎.
  late final Animation<double> _exitOpacity = Tween<double>(
    begin: 1.0,
    end: 0.0,
  ).animate(
    CurvedAnimation(parent: _controller, curve: _exit),
  );

  /// انزلاق الخروج: ‎5%‎ من ارتفاع المحتوى للأعلى (‎≈40px‎ على الهاتف).
  late final Animation<Offset> _exitSlide = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(0, -0.05),
  ).animate(
    CurvedAnimation(parent: _controller, curve: _exit),
  );

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // الانتقال عند اكتمال الخروج تماماً (‎3.0s‎).
    _timer = Timer(_total, _goToLogin);
  }

  /// نبض كل ‎0.5s‎ خلال التوقّف ‎1.2s‎ (‎2.4 دورة‎) — موجة جيبية ناعمة
  /// ‎0→1→0‎، وتقرأ ‎0‎ خارج مرحلة التوقّف فلا يهتزّ الاسم في الظهور
  /// ولا أثناء الخروج.
  double get _pulse {
    final double t = _hold.value;
    if (t <= 0.0 || t >= 1.0) return 0.0;
    return (math.sin(t * 2.4 * 2 * math.pi) + 1.0) / 2.0;
  }

  /// الانتقال: `pushReplacement` لا `push` — فلا يستطيع زرّ الرجوع إعادة
  /// الافتتاح، والانتقال نفسه باهت ‎400ms‎ كامتداد للخروج.
  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement<void, void>(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) => FadeTransition(
              opacity: animation,
              child: FarahLoginScreen(repository: widget.repository),
            ),
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
          key: const ValueKey<String>('jood-reach-splash'),
          backgroundColor: _navyDeep,
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              // تدرّج قطري ناعم من الأعلى-اليسار إلى الأسفل-اليمين.
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[_navyDeep, _navySoft],
              ),
            ),
            // الخروج يلفّ المحتوى كله: تلاشٍ ثم انزلاق للأعلى.
            child: FadeTransition(
              opacity: _exitOpacity,
              child: SlideTransition(
                position: _exitSlide,
                child: Center(
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints box) {
                      // ‎72‎ على الشاشات المعتدلة وما دونها ‎56‎ (حدّا المهمة).
                      final double fontSize = box.maxWidth < 480 ? 56.0 : 72.0;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          ScaleTransition(
                            scale: _scale,
                            child: FadeTransition(
                              opacity: _appearCurve,
                              child: _buildName(fontSize),
                            ),
                          ),
                          const SizedBox(height: 20),
                          FadeTransition(
                            opacity: CurvedAnimation(
                              parent: _controller,
                              curve: _taglinePhase,
                            ),
                            child: const Text(
                              _tagline,
                              key: ValueKey<String>(
                                'jood-reach-splash-tagline',
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppAssets.cairoFont,
                                fontSize: 16,
                                color: Color(0x99FFFFFF), // أبيض @ 0.6
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
          ),
        ),
      ),
    );
  }

  /// الاسم بثلاث طبقات فوق بعضها: توهّج النبض خلفه، ثم الذهب المتدرّج،
  /// ثم شريط اللمعة — كلها على النصّ نفسه فلا يزاح الشكل بتغيّر الحجم.
  Widget _buildName(double fontSize) {
    // تكبير النبض: ‎1.2%‎ فقط — يُحسّ ولا يُلاحَظ.
    final double pulseScale = 1.0 + 0.012 * _pulse;
    return Transform.scale(
      scale: pulseScale,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // (١) توهّج خلف الاسم — ينبض مع الصوت نفسه للنبض.
          Opacity(
            opacity: 0.30 * _pulse,
            child: Container(
              width: 320,
              height: fontSize * 1.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    _goldLight.withValues(alpha: 0.55),
                    _navySoft.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // (٢) الذهب المتدرّج — الاسم الأساسي.
          ShaderMask(
            shaderCallback: (Rect rect) => const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: <Color>[_goldDark, _goldLight, _goldDark],
              stops: <double>[0.0, 0.5, 1.0],
            ).createShader(rect),
            blendMode: BlendMode.srcIn,
            child: _nameText(fontSize, Colors.white),
          ),
          // (٣) اللمعة — شريط ضوئي يعبر الاسم من اليسار لليمين.
          ShaderMask(
            shaderCallback: (Rect rect) => LinearGradient(
              begin: Alignment(_shimmerSweep.value - 0.9, 0.0),
              end: Alignment(_shimmerSweep.value + 0.9, 0.0),
              colors: const <Color>[
                Color(0x00000000),
                _shimmerColor,
                Color(0x00000000),
              ],
              stops: const <double>[0.35, 0.5, 0.65],
            ).createShader(rect),
            blendMode: BlendMode.srcIn,
            child: _nameText(fontSize, Colors.white),
          ),
        ],
      ),
    );
  }

  /// نصّ الاسم نفسه — LTR دائماً (اسم إنجليزي داخل صفحة عربية).
  Widget _nameText(double fontSize, Color color) {
    return Text(
      _appName,
      key: const ValueKey<String>('jood-reach-splash-name'),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: AppAssets.amiriFont,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.2,
      ),
    );
  }
}
