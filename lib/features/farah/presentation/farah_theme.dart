/// قشرة تطبيق «فرح»: **الألوان والخطوط هي نفسها تماماً** كصفحة القرية
/// (رمادي داكن `#3D3D3D` + تركواز `#0E6B6B` + رمادي `#5C5C5C` + ذهبي
/// `#B8932E`، ونصّ أبيض، وAmiri للعناوين وCairo للنصوص) — مصدرها واحد هو
/// `VillageTheme` حتى لا تتفرّع اللوحة مطلقاً بين الصفحتين.
///
/// ولأن تطبيق JoodCraft يغلّف الشجرة باتجاه ولغة المضيف (قد يختار المستخدم
/// إنجليزية)، يُثبَّت هنا الاتجاه RTL على المحتوى نفسه — كما تفعل
/// `VillageAdminDirection` لشاشة لوحة التحكم.
library;

import 'package:flutter/material.dart';

import '../../village/presentation/village_theme.dart';
import 'widgets/farah_footer.dart';

/// مظهر «فرح» — اشتقاق من مظهر القرية لا من مظهر المنصة.
abstract final class FarahTheme {
  const FarahTheme._();

  /// المظهر الداكن الوحيد للتطبيق.
  static ThemeData get dark => VillageTheme.dark;
}

/// غلاف كل شاشات «فرح»: RTL + المظهر الداكن + خلفية القرية (تدرّج داكن
/// وهالتان تركواز/ذهبي) + توسيع بمحدّد عرض.
class FarahShell extends StatelessWidget {
  const FarahShell({
    super.key,
    required this.child,
    this.appBar,
    this.maxWidth = VillageMetrics.maxFormWidth,
    this.scroll = true,
    this.showFooter = true,
  });

  /// محتوى الشاشة.
  final Widget child;

  /// شريط علوي اختياري (لكل شاشة **ما عدا الدخول**): يحمل سهم الرجوع
  /// واسم الشاشة بنفس مظهر القرية. ويُرفض به `SafeArea` الأعلى لأن
  /// الـAppBar نفسه يمتد تحت شريط الحالة.
  final PreferredSizeWidget? appBar;

  /// أقصى عرض للمحتوى.
  final double maxWidth;

  /// هل يوضع المحتوى داخل تمرير رأسي؟
  final bool scroll;

  /// هل يظهر الفوتر (شعار JoodCraft + المطوّر + حقوق النشر) أسفل المحتوى؟
  /// مُفعَّل افتراضياً لكل الشاشات — يُطفأ على من يبني شاشته بنفسه.
  final bool showFooter;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Theme(
        data: FarahTheme.dark,
        child: Scaffold(
          backgroundColor: VillageColors.background,
          appBar: appBar,
          body: Stack(
            children: <Widget>[
              const Positioned.fill(child: _FarahGlow()),
              SafeArea(
                top: appBar == null,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: scroll
                        ? ListView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: VillageMetrics.space20,
                              vertical: VillageMetrics.space24,
                            ),
                            // الفوتر آخر ما يُقرأ في التمرير: مع المحتوى لا
                            // فوقه، فيظهر أسفل كل شاشة تمرير بلا تدخّل في
                            // بنية شاشاتها.
                            children: showFooter
                                ? <Widget>[child, const FarahFooter()]
                                : <Widget>[child],
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: VillageMetrics.space20,
                              vertical: VillageMetrics.space24,
                            ),
                            // بلا تمرير (شاشة المحادثة): الفوتر أسفل العمود
                            // تحت المحتوى المتمدّد — تحت حقل الإرسال لا فوقه.
                            child: showFooter
                                ? Column(
                                    children: <Widget>[
                                      Expanded(child: child),
                                      const FarahFooter(),
                                    ],
                                  )
                                : child,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// هالتان لونيتان خفيفتان تتّحدان مع خلفية صفحة القرية.
class _FarahGlow extends StatelessWidget {
  const _FarahGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -120,
            right: -90,
            child: _glow(VillageColors.teal, 380),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: _glow(VillageColors.gold, 340),
          ),
        ],
      ),
    );
  }

  Widget _glow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[
            color.withValues(alpha: 0.14),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
