import 'dart:async';

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/assets/assets_controller.dart';
import 'core/fonts/custom_font_controller.dart';
import 'core/locale/locale_controller.dart';
import 'core/pdf/pdf_font_catalog.dart';
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

  // خطوط النظام (Windows) تُفحص في الخلفية فلا تؤخّر الإقلاع؛ تظهر في منتقي
  // الخطوط بمجرّد انتهاء الفحص. على الويب/الجوال لا تفعل شيئاً.
  unawaited(CustomFontController.instance.scanSystemFonts());

  // مكتبة الأصول (الشعار/الختم/التوقيع) محلية أيضاً — تُستعاد قبل الواجهة.
  await AssetsController.instance.restore();

  // تنظيف كاش الصور القرصي: نحذف ملفات الأصول التي لم تعد في المكتبة (أصل
  // حُذف أو ملف بقي يتاماً) في الخلفية — لا يؤخّر الإقلاع ولا يرمي أبداً.
  unawaited(AssetsController.instance.pruneImageCache());

  // تفضيل المظهر (فاتح/داكن/النظام) — يُقرأ قبل البناء لتفادي وميض لحظي.
  final ThemeController themeController = ThemeController();
  await themeController.load();

  // لغة الواجهة واتجاهها — تُقرأ قبل البناء أيضاً فلا يظهر التطبيق بالعربية
  // لحظةً ثم يتبدّل إلى لغة المستخدم المختارة.
  final LocaleController localeController = LocaleController();
  await localeController.load();

  final bool supabaseReady = await SupabaseService.initialize();

  final AuthRepository? authRepository =
      supabaseReady ? SupabaseAuthRepository(SupabaseService.client) : null;

  runApp(
    JoodCraftApp(
      authRepository: authRepository,
      themeController: themeController,
      localeController: localeController,
    ),
  );

  // تسخين محرّك الطباعة: تحميل الخطوط المحزومة وتحليلها كسولاً في الخلفية
  // (وحساب تغطيتها في isolate منفصل) قبل أول تصدير، فلا يدفع المستخدم كلفة
  // التحميل عند أول طباعة. بعد `runApp` فلا يؤخّر الإقلاع إطلاقاً.
  unawaited(PdfFontSet.warmUp());
}
