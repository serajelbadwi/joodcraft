/// نقطة انطلاق **صفحة القرية** (تطبيق ويب مستقل عن تطبيق JoodCraft).
///
/// التشغيل:
/// ```bash
/// flutter run -d chrome -t lib/main_village.dart
/// ```
/// البناء والنشر:
/// ```bash
/// flutter build web -t lib/main_village.dart --release \
///   --output build/web_village \
///   --dart-define=FARAH_APK_URL=https://example.com/farah.apk
/// ```
///
/// الترتيب:
/// 1) تهيئة Flutter.
/// 2) تهيئة عميل Supabase (المفاتيح تُقرأ من `--dart-define` أو
///    `assets/env/env.json` أو `env.json`). وإن غابت، لا ينهار شيء: الصفحة
///    تعرض أقسامها كاملة وتُوضّح أن الخدمة غير مُهيّأة في بطاقة التسجيل.
/// 3) تشغيل تطبيق القرية باللغة العربية في مظهره الداكن الخاص.
library;

import 'package:flutter/material.dart';

import 'core/services/supabase_service.dart';
import 'features/village/data/supabase_village_repository.dart';
import 'features/village/presentation/village_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // لا نُسقط الصفحة إن تعذّرت التهيئة — الواجهة تتصرّف حسب `isAvailable`.
  await SupabaseService.initialize();

  runApp(VillageApp(repository: SupabaseVillageRepository()));
}
