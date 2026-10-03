// أداة تهيئة بسيطة لملف مفاتيح Supabase — تعمل من نسخة نظيفة من الريبو.
//
// الغرض: ضمان وجود الملف الذي يقرأه التطبيق (وقت التطوير وبعض الاختبارات):
//   * env.json                ← يقرأه قارئ القرص في جذر المشروع أثناء التطوير.
//   * assets/env/env.json     ← الملف المحزوم داخل التطبيق في نسخ الإنتاج.
//
// لا تكتب أي مفاتيح حقيقية هنا: القيم النموذجية من `env.example.json` تُرفَض
// تلقائياً في `EnvConfigLoader` (يُعرَض شاشة التهيئة) حتى لا تُعامل كإعداد صالح.
//
// التشغيل:
//   dart run tool/ensure_env.dart
//
// لا يعتمد على Flutter ولا على أي حزمة خارجية.
import 'dart:io';

/// مسار الملف المحزوم (مجلد `assets/env/` مُعلن كأصل في pubspec.yaml).
const String bundledPath = 'assets/env/env.json';

/// مسار القرص أثناء التطوير.
const String diskPath = 'env.json';

/// ملف النموذج الذي يُنسخ منه إن لم يوجد ملف حقيقي.
const String examplePath = 'env.example.json';

Future<void> main() async {
  final File example = File(examplePath);
  if (!example.existsSync()) {
    stderr.writeln('✗ لم يُعثر على $examplePath — لا يمكن التهيئة.');
    exitCode = 1;
    return;
  }

  final String exampleContent = example.readAsStringSync();

  // 1) ملف القرص (التطوير).
  final File disk = File(diskPath);
  if (disk.existsSync()) {
    stdout.writeln('• $diskPath موجود بالفعل — لن يُلمَس.');
  } else {
    disk.writeAsStringSync(exampleContent);
    stdout.writeln('✓ أُنشئ $diskPath من $examplePath (املأه بمفاتيحك).');
  }

  // 2) الملف المحزوم (الإنتاج) — مجلد مُعلن كأصل، فلا يُسقط غيابه البناء.
  final File bundled = File(bundledPath);
  if (bundled.existsSync()) {
    stdout.writeln('• $bundledPath موجود بالفعل — لن يُلمَس.');
  } else {
    bundled.parent.createSync(recursive: true);
    // نُفضّل نسخة القرص إن كانت مملوءة، وإلا انسخ النموذج.
    final String source = disk.existsSync() ? disk.readAsStringSync() : exampleContent;
    bundled.writeAsStringSync(source);
    stdout.writeln('✓ أُنشئ $bundledPath من $examplePath.');
  }

  stdout.writeln('\nالخطوة التالية: املأ SUPABASE_URL و SUPABASE_ANON_KEY ثم:');
  stdout.writeln('  flutter run -d windows');
}
