/// نقطة انطلاق **تطبيق «فرح»** (تطبيق ويب مستقل عن تطبيق JoodCraft).
///
/// التشغيل:
/// ```bash
/// flutter run -d chrome -t lib/main_farah.dart
/// ```
/// البناء والنشر:
/// ```bash
/// flutter build web -t lib/main_farah.dart --release \
///   --output build/web_farah
/// ```
///
/// الترتيب:
/// 1) تهيئة Flutter.
/// 2) تهيئة عميل Supabase (المفاتيح تُقرأ من `--dart-define` أو
///    `assets/env/env.json` أو `env.json`). وإن غاب، لا ينهار شيء: شاشة
///    الدخول تعرض نفسها وتُوضّح أن الخدمة غير مُهيّأة بدل الانهيار.
/// 3) تشغيل تطبيق «فرح» باللغة العربية في مظهره الداكن (نفس لوحة صفحة
///    القرية تماماً) — والاتجاه والترجمة يضبطهما `FarahApp` بنفسه.
library;

import 'package:flutter/material.dart';

import 'core/services/supabase_service.dart';
import 'features/farah/presentation/farah_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // لا يُسقط التطبيق إن تعذّرت التهيئة — الشاشات تتصرّف حسب `isAvailable`.
  await SupabaseService.initialize();

  runApp(const FarahApp());
}
