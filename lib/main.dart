import 'dart:async';

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/assets/assets_controller.dart';
import 'core/audit/export_audit_log.dart';
import 'core/brand/brand_profile_controller.dart';
import 'core/fonts/custom_font_controller.dart';
import 'core/locale/locale_controller.dart';
import 'core/pdf/pdf_font_catalog.dart';
import 'core/projects/projects_controller.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/data/local_auth_repository.dart';

/// نقطة انطلاق JoodCraft.
///
/// الترتيب مقصود:
/// 1) تهيئة ارتباط Flutter بالمنصة.
/// 2) استعادة مكتبة الخطوط المخصصة التي رفعها المستخدم محلياً — لتكون جاهزة
///    في محرر القوالب وفي الطباعة من اللحظة الأولى، بلا شبكة.
/// 3) فتح **قاعدة المشاريع المحلية** وقراءة جدولها مرة واحدة — فتعرض كل الشاشات
///    المشاريع فوراً من الذاكرة.
/// 4) تجهيز **حساب محلي** على القرص (بريد وكلمة مرور) — فالتطبيق يطلب تسجيل
///    الدخول قبل أي شاشة، والهوية تُتحقَّق محلياً بلا شبكة.
/// 5) تشغيل التطبيق — بلا أي تهيئة شبكة: لا Supabase ولا رفع ولا تزامن.
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

  // هوية المؤسسة (شعار/أختام/توقيعات/ألوان/خطوط) — تُستعاد قبل الواجهة
  // لتكون جاهزة في المحرّر من اللحظة الأولى.
  await BrandProfileController.instance.restore();

  // تفضيل المظهر (فاتح/داكن/النظام) — يُقرأ قبل البناء لتفادي وميض لحظي.
  final ThemeController themeController = ThemeController();
  await themeController.load();

  // لغة الواجهة واتجاهها — تُقرأ قبل البناء أيضاً فلا يظهر التطبيق بالعربية
  // لحظةً ثم يتبدّل إلى لغة المستخدم المختارة.
  final LocaleController localeController = LocaleController();
  await localeController.load();

  // قاعدة المشاريع المحلية: تُفتح قبل الواجهة، فيصبح جدول المشاريع في الذاكرة
  // وتُعرض القوائم (لوحة التحكم/المكتبة) فوراً بلا أي انتظار ولا شبكة.
  await ProjectsController.instance.restore();

  // الحساب المحلي: يقرأ جدول الحسابات والجلسة الحالية من تفضيلات الجهاز، فإذا
  // كان المستخدم مسجّلاً سابقاً دخل مباشرةً؛ وإلا أوقفه الموجّه على شاشة الدخول.
  final LocalAuthRepository authRepository = await LocalAuthRepository.create();

  // سجل الشهادات الصادرة: يُستعاد قبل الواجهة فيرى المدير أرشيفه فور فتح
  // «الإدارة» بلا انتظار ولا شبكة.
  final ExportAuditLog auditLog = ExportAuditLog.instance;
  await auditLog.restore();

  runApp(
    JoodCraftApp(
      authRepository: authRepository,
      themeController: themeController,
      localeController: localeController,
      auditLog: auditLog,
    ),
  );

  // تسخين محرّك الطباعة: تحميل الخطوط المحزومة وتحليلها كسولاً في الخلفية
  // (وحساب تغطيتها في isolate منفصل) قبل أول تصدير، فلا يدفع المستخدم كلفة
  // التحميل عند أول طباعة. بعد `runApp` فلا يؤخّر الإقلاع إطلاقاً.
  unawaited(PdfFontSet.warmUp());
}
