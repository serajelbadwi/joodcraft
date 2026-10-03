import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/assets/assets_controller.dart';
import 'core/fonts/custom_font_controller.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/data/supabase_auth_repository.dart';
import 'features/auth/domain/auth_repository.dart';

/// نقطة انطلاق JoodCraft.
///
/// الترتيب مقصود:
/// 1) تهيئة ارتباط Flutter بالمنصة.
/// 2) تهيئة Supabase — تجلب المفاتيح تلقائياً (‎--dart-define‎ ثم env.json)
///    وتفشل بهدوء إن لم يُعثر على أي مصدر صالح.
/// 3) استعادة مكتبة الخطوط المخصصة التي رفعها المستخدم محلياً — لتكون جاهزة
///    في محرر القوالب وفي الطباعة من اللحظة الأولى، بلا شبكة.
/// 4) تشغيل التطبيق — بمستودع مصادقة حقيقي أو بواجهة تهيئة.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await CustomFontController.instance.restore();

  // مكتبة الأصول (الشعار/الختم/التوقيع) محلية أيضاً — تُستعاد قبل الواجهة.
  await AssetsController.instance.restore();

  // تفضيل المظهر (فاتح/داكن/النظام) — يُقرأ قبل البناء لتفادي وميض لحظي.
  final ThemeController themeController = ThemeController();
  await themeController.load();

  final bool supabaseReady = await SupabaseService.initialize();

  final AuthRepository? authRepository =
      supabaseReady ? SupabaseAuthRepository(SupabaseService.client) : null;

  runApp(
    JoodCraftApp(
      authRepository: authRepository,
      themeController: themeController,
    ),
  );
}
