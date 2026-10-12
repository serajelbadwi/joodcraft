/// شاشة افتتاح «Jood Reach» — هويّة التطبيق الجديدة في **خمس ثوانٍ** كاملة.
///
/// خلفية كحلية داكنة متدرّجة قطرياً (‎`#0F1B3C` → `#1A2A4A`‎) واسم التطبيق
/// يُكتب **حرفًا حرفًا** بخط Amiri الذهبي، ثم **رسالة مجنّحة** تطير إلى
/// الأعلى مثل عصفور، ثم توقّف لامع — وبعدها انتقال تلقائي إلى شاشة الدخول.
///
/// الزمن كله من متحكّم واحد ‎5000ms‎ و`Interval` لكل مرحلة:
///
/// | المرحلة | الزمن | ماذا تفعل |
/// |---------|-------|-----------|
/// | الحروف | ‎0.0–1.5s‎ | كل حرف يظهر بالتتابع: تأخير ‎150ms‎ بينها، fade-in + scale ‎0.5→1.0‎ (`easeOutBack`) |
/// | الطيران | ‎1.5–3.0s‎ | رسالة وسط الشاشة تفتح جناحين ورقيين ثم تطير للأعلى (‎0→-200px‎) — الجناحان بدوران وتكبير ورفرفة + لمعة، والمسار `easeInOut` |
/// | التوقّف | ‎3.0–4.5s‎ | الاسم ثابت + شريط لمعة ذهبي يعبره + نبض كل ‎0.5s‎ |
/// | الخروج | ‎4.5–5.0s‎ | تلاشٍ + انزلاق للأعلى (`easeIn`) |
///
/// وعند ‎5.0s‎: `pushReplacement` إلى [FarahLoginScreen] بانتقال باهت — فلا
/// يستطيع زرّ الرجوع إعادة الافتتاح (البداية الحقيقية هي الدخول).
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../data/farah_repository.dart';
import '../../domain/farah_text.dart';
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

  /// الذهبي الثلاثي: غامق ← فاتح ← غامق (تدرّج الاسم والجناحين).
  static const Color _goldDark = Color(0xFFB8932E);
  static const Color _goldLight = Color(0xFFD4AF4F);

  /// لون اللمعة — ذهبي فاتح شبه أبيض يعبر الاسم والجناحين.
  static const Color _shimmerColor = Color(0xFFFFE9A8);

  // ── الزمن والمراحل (كسور من ‎5.0s‎) ───────────────────────────────────
  static const Duration _total = Duration(milliseconds: 5000);

  /// الطيران ‎1.5–3.0s‎ — مسار الرسالة والجناحين (`easeInOut` كما في المهمة).
  static const Interval _flight = Interval(
    0.3,
    0.6,
    curve: Curves.easeInOut,
  );

  /// التوقّف ‎3.0–4.5s‎ — لمعة الاسم ونبضه.
  static const Interval _hold = Interval(0.6, 0.9);

  /// لمعة الاسم خلال التوقّف — شريط يعبره مرة واحدة.
  static const Interval _shimmerPhase = Interval(
    0.6,
    0.9,
    curve: Curves.easeInOut,
  );

  /// الخروج ‎4.5–5.0s‎ — تلاشٍ + انزلاق للأعلى (`easeIn`).
  static const Interval _exit = Interval(0.9, 1.0, curve: Curves.easeIn);

  /// ظهور الرسالة ‎1.5–1.65s‎ واختفاؤها ‎2.85–3.0s‎ (تختفي قبل التوقّف).
  static const Interval _envelopeIn = Interval(0.3, 0.33);
  static const Interval _envelopeOut = Interval(0.57, 0.6);

  /// انفتاح الجناحين ‎1.5–2.0s‎ — `easeOutBack` يعطي اندفاعاً طبيعياً.
  static const Interval _wingsOpen = Interval(
    0.3,
    0.4,
    curve: Curves.easeOutBack,
  );

  // ── الحروف ────────────────────────────────────────────────────────────
  /// تأخير ‎150ms‎ بين كل حرف وآخر، ومدّة ظهور كل حرف ‎450ms‎.
  static const double _letterStaggerMs = 150;
  static const double _letterDurationMs = 450;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _total,
  )..forward();

  Timer? _timer;

  /// الزمن المنقضي بالملي ثانية (‎0..5000‎) — أساس تتابع الحروف.
  double get _elapsedMs => _controller.value * _total.inMilliseconds;

  /// تقدّم الطيران ‎0→1‎ (مسار جيبّي حرج بين الظهور والاختفاء).
  double get _flightProgress => _flight.transform(_controller.value);

  /// شفافية الرسالة: تظهر مع بدء الطيران وتنكسر عند نهايته.
  double get _envelopeOpacity {
    final double fadeIn = _envelopeIn.transform(_controller.value);
    final double fadeOut = 1.0 - _envelopeOut.transform(_controller.value);
    return math.min(fadeIn, fadeOut);
  }

  /// تقدّم انفتاح الجناحين ‎0→1‎.
  double get _wingsOpenProgress => _wingsOpen.transform(_controller.value);

  /// رفرفة: دورة جيبّيتين خلال الطيران بعد انفتاح الجناحين (‎≈2 رفرفة‎).
  double get _flap {
    final double active = ((_flightProgress - 0.34) / 0.66).clamp(0.0, 1.0);
    return math.sin(_flightProgress * 4 * math.pi) * 0.22 * active;
  }

  /// نبض التوقّف: 3 دوّارات كل ‎0.5s‎ خلال ‎1.5s‎ — ‎0‎ خارج التوقّف.
  double get _pulse {
    final double t = _hold.transform(_controller.value);
    if (t <= 0.0 || t >= 1.0) return 0.0;
    return (math.sin(t * 3 * 2 * math.pi) + 1.0) / 2.0;
  }

  @override
  void initState() {
    super.initState();
    // الانتقال عند اكتمال الخروج تماماً (‎5.0s‎).
    _timer = Timer(_total, _goToLogin);
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
            // الخروج يلفّ المشهد كله: تلاشٍ ثم انزلاق للأعلى.
            child: FadeTransition(
              opacity: _exitFade,
              child: SlideTransition(
                position: _exitSlide,
                // كل ما يقرأ `_controller.value` (الحروف والجناحين والنبض)
                // يُعاد بناؤه مع كل إطار — فلا يتجمّد المشهد على أول رسمة.
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (BuildContext context, Widget? child) {
                    return Center(
                      child: LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints box) {
                          // ‎72‎ على الشاشات المعتدلة وما دونها ‎56‎ (حدّا المهمة).
                          final double fontSize = box.maxWidth < 480
                              ? 56.0
                              : 72.0;
                          return Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              // (١) الاسم بحروفه المتتابعة + اللمعة والنبض.
                              _buildName(fontSize),
                              // (٢) الرسالة المجنّحة تطير فوقه ثم تختفي.
                              _buildEnvelopeFlight(fontSize),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// تلاشٍ الخروج ‎1→0‎ وانزلاقه ‎5%‎ من ارتفاع المشهد للأعلى (‎≈40px‎).
  Animation<double> get _exitFade => Tween<double>(begin: 1.0, end: 0.0)
      .animate(CurvedAnimation(parent: _controller, curve: _exit));

  Animation<Offset> get _exitSlide => Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(0, -0.05),
  ).animate(CurvedAnimation(parent: _controller, curve: _exit));

  // ── الاسم ─────────────────────────────────────────────────────────────

  /// الاسم بثلاث طبقات: توهّج النبض خلفه، الذهب المتدرّج، ثم شريط اللمعة.
  Widget _buildName(double fontSize) {
    return Transform.scale(
      scale: 1.0 + 0.012 * _pulse,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // (١) توهّج خلف الاسم — ينبض في مرحلة التوقّف.
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
          // (٢) الذهب المتدرّج — الحروف الأساسية.
          ShaderMask(
            shaderCallback: (Rect rect) => const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: <Color>[_goldDark, _goldLight, _goldDark],
              stops: <double>[0.0, 0.5, 1.0],
            ).createShader(rect),
            blendMode: BlendMode.srcIn,
            child: _lettersRow(fontSize, keyName: true),
          ),
          // (٣) اللمعة — شريط ذهبي فاتح يعبر الاسم في التوقّف.
          ShaderMask(
            shaderCallback: (Rect rect) => LinearGradient(
              begin: Alignment(_shimmerSweep - 0.9, 0.0),
              end: Alignment(_shimmerSweep + 0.9, 0.0),
              colors: const <Color>[
                Color(0x00000000),
                _shimmerColor,
                Color(0x00000000),
              ],
              stops: const <double>[0.35, 0.5, 0.65],
            ).createShader(rect),
            blendMode: BlendMode.srcIn,
            child: _lettersRow(fontSize, keyName: false),
          ),
        ],
      ),
    );
  }

  /// موضع شريط اللمعة: يعبر الاسم كاملاً خلال مرحلة التوقّف.
  double get _shimmerSweep {
    final double t = _shimmerPhase.transform(_controller.value);
    return -1.6 + 3.2 * t;
  }

  /// صفّ الحروف: كل حرف Text مستقلّ يظهر بالتتابع (‎150ms‎ فارق) بـ
  /// fade-in وتكبير ‎0.5→1.0‎ (`easeOutBack`) — والمسافة بين الكلمتين
  /// حرف كما هو فلا يزاح التتابع.
  Widget _lettersRow(double fontSize, {required bool keyName}) {
    final String name = FarahText.joodReachName;
    return Row(
      key: keyName
          ? const ValueKey<String>('jood-reach-splash-name')
          : null,
      mainAxisSize: MainAxisSize.min,
      // الاسم إنجليزي LTR داخل صفحة عربية.
      textDirection: TextDirection.ltr,
      children: <Widget>[
        for (int i = 0; i < name.length; i++)
          Transform.scale(
            scale: 0.5 + 0.5 * Curves.easeOutBack.transform(_letterIn(i)),
            child: Opacity(
              opacity: Curves.easeOut.transform(_letterIn(i)),
              child: Text(
                name[i],
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontFamily: AppAssets.amiriFont,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// تقدّم ظهور الحرف رقم ‎i‎ (‎0..1‎) — يبدأ عند ‎i × 150ms‎ ويستغرق ‎450ms‎.
  double _letterIn(int index) {
    final double local = (_elapsedMs - index * _letterStaggerMs) /
        _letterDurationMs;
    return local.clamp(0.0, 1.0);
  }

  // ── الرسالة المجنّحة ──────────────────────────────────────────────────

  /// الرسالة تظهر تحت الاسم وتطير إلى الأعلى (‎100 → -100px‎ بإزاحة ‎200px‎
  /// كاملة كما في المهمة) مع رفرفة وتذبذب جانبي خفيف كطيران العصفور —
  /// وتحلّق **خلف** الاسم فلا تحجبه.
  Widget _buildEnvelopeFlight(double fontSize) {
    final double open = _wingsOpenProgress.clamp(0.0, 1.0);
    // اندفاع الانفتاح (‎easeOutBack‎) يتجاوز 1 قليلاً — جناحان يتركان.
    final double wingScale = 0.25 + 0.75 * open;
    // زاوية الجناح: مطويّ عموديّاً على الرسالة ← مفرود قليلاً للأعلى.
    final double wingAngle = -1.25 + 1.1 * open + _flap;
    // تذبذب جانبي صغير أثناء الطيران.
    final double swayX = math.sin(_flightProgress * 2 * math.pi) * 8;
    final double offsetY = 100 - 200 * _flightProgress;

    return Align(
      alignment: Alignment.center,
      child: Transform.translate(
        offset: Offset(swayX, offsetY),
        child: Opacity(
          opacity: _envelopeOpacity,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              // (١) الرسالة والجناحان بلونهم الذهبي الأساسي.
              ShaderMask(
                shaderCallback: (Rect rect) => const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: <Color>[_goldDark, _goldLight, _goldDark],
                  stops: <double>[0.0, 0.5, 1.0],
                ).createShader(rect),
                blendMode: BlendMode.srcIn,
                child: _wingsAndEnvelope(
                  wingScale: wingScale,
                  wingAngle: wingAngle,
                ),
              ),
              // (٢) لمعة تعبر الجناحين أثناء الطيران.
              ShaderMask(
                shaderCallback: (Rect rect) => LinearGradient(
                  begin: Alignment(_flightProgress * 3 - 1.5, 0.0),
                  end: Alignment(_flightProgress * 3 - 0.6, 0.0),
                  colors: const <Color>[
                    Color(0x00000000),
                    _shimmerColor,
                    Color(0x00000000),
                  ],
                  stops: const <double>[0.35, 0.5, 0.65],
                ).createShader(rect),
                blendMode: BlendMode.srcIn,
                child: _wingsAndEnvelope(
                  wingScale: wingScale,
                  wingAngle: wingAngle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// صفّ: [جناح أيسر] رسالة [جناح أيمن] — الجناحان بدوران حول جذرهما
  /// الملاصق للرسالة (‎alignment‎ على حافة الطرف).
  Widget _wingsAndEnvelope({
    required double wingScale,
    required double wingAngle,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Transform.rotate(
          angle: -wingAngle,
          alignment: Alignment.centerRight,
          child: Transform.scale(
            scale: wingScale,
            child: const CustomPaint(
              size: Size(58, 36),
              painter: _PaperWingPainter(mirror: true),
            ),
          ),
        ),
        const SizedBox(width: 2),
        const Icon(
          Icons.mail_rounded,
          size: 36,
          color: Colors.white,
          semanticLabel: 'رسالة',
        ),
        const SizedBox(width: 2),
        Transform.rotate(
          angle: wingAngle,
          alignment: Alignment.centerLeft,
          child: Transform.scale(
            scale: wingScale,
            child: const CustomPaint(
              size: Size(58, 36),
              painter: _PaperWingPainter(mirror: false),
            ),
          ),
        ),
      ],
    );
  }
}

/// جناح ورقيّ بحوافّ مقصوصة (مسار مقعّر بثلاث حوافّ خلفية كريشة طائر) —
/// يُرسم أبيضاً وتلوينه الذهبي يأتي من ‎`ShaderMask`‎ فوقه.
class _PaperWingPainter extends CustomPainter {
  const _PaperWingPainter({required this.mirror});

  /// ‎true‎ = الجناح الأيسر (جذره على يمينه) يُرسم بمرآة المسار.
  final bool mirror;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final Path path = Path()
      // الجذر عند طرف الجناح الملاصق للرسالة.
      ..moveTo(0, size.height * 0.45)
      // الحافة العلوية إلى سنّ الجناح الخارجي.
      ..quadraticBezierTo(
        size.width * 0.30,
        -size.height * 0.12,
        size.width,
        size.height * 0.12,
      )
      // الحوافّ الخلفية المقصوصة (ثلاث قصّات كريشة).
      ..quadraticBezierTo(
        size.width * 0.55,
        size.height * 0.30,
        size.width * 0.80,
        size.height * 0.55,
      )
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.45,
        size.width * 0.55,
        size.height * 0.88,
      )
      // العودة إلى الجذر بالإسفل.
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.65,
        0,
        size.height * 0.45,
      )
      ..close();

    if (mirror) {
      canvas.save();
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
      canvas.drawPath(path, paint);
      canvas.restore();
    } else {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_PaperWingPainter oldDelegate) =>
      oldDelegate.mirror != mirror;
}
