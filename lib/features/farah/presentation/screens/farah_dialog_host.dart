/// مضيف «فرح» داخل تطبيق JoodCraft — **صفحة حوار ملء الشاشة بزرّ إغلاق X**.
///
/// لماذا هذا المضيف أصلاً؟ فتح مسار `/farah` كان يذهب إلى `context.go`
/// (فرح خارج `_overlayRoutes`) فيستبدل موقع التنقّل كاملاً بشاشة بلا شريط
/// ولا سهم رجوع — فيعلق المستخدم خارج لوحته. الآن يُفتح المسار **فوق** ما
/// يعمل عليه ضمن `_overlayRoutes` كصفحة حوار: زرّ X في الأعلى يُرجعه إلى
/// موضعه بالضبط، وأقسامه تبقى حيّة تحته ( IndexedStack ).
///
/// **لماذا `FarahLoginScreen` لا `FarahApp`؟**‏ `FarahApp` حاوية `MaterialApp`
/// كاملة (شاشة افتتاح + تهيئة Supabase) مصمّمة للويب المنفصل؛ تغليف
/// `MaterialApp` بآخر يضاعف الثيمات ولا يضيف شاشة. المضيف يعرض المحتوى
/// نفسه مباشرة: نفس الدخول ونفس شاشاته التالية.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../data/farah_repository.dart';
import '../../data/supabase_farah_repository.dart';
import '../../domain/farah_text.dart';
import '../../../village/presentation/village_theme.dart';
import '../farah_theme.dart';
import 'farah_login_screen.dart';

class FarahDialogHost extends StatelessWidget {
  const FarahDialogHost({
    super.key,
    this.repository = const SupabaseFarahRepository(),
  });

  /// مستودع البيانات — يُمرَّر إلى شاشة الدخول كما في مسار الويب المستقلّ.
  final FarahRepository repository;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Theme(
        data: FarahTheme.dark,
        child: Scaffold(
          backgroundColor: VillageColors.background,
          appBar: AppBar(
            key: const ValueKey<String>('farah-dialog-bar'),
            backgroundColor: VillageColors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            // لا سهم رجوع افتراضي: **X وحده** هو مفتاح الخروج — رمز دولي
            // لا يحتاج تفسيراً، ويتوافق مع طبيعة الصفحة كـ«حوار» يُفتح
            // فوق العمل لا كقسم جديد يُستبدل به.
            automaticallyImplyLeading: false,
            leading: IconButton(
              key: const ValueKey<String>('farah-dialog-close'),
              tooltip: FarahText.closeDialog,
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(
                Icons.close_rounded,
                color: VillageColors.white,
                size: 26,
              ),
            ),
            title: const Text(
              FarahText.appName,
              style: TextStyle(
                fontFamily: AppAssets.amiriFont,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: VillageColors.gold,
                height: 1.5,
              ),
            ),
          ),
          // المحتوى: نفس شاشة الدخول — وبها الشعار بدل النصّ والأيقونة.
          body: FarahLoginScreen(repository: repository),
        ),
      ),
    );
  }
}
