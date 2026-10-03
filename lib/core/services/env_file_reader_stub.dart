/// على الويب لا يوجد نظام ملفات يُقرأ من Dart — يُرجَع الفراغ هنا ويكفل
/// الأصل المحزوم (`assets/env/env.json` المُعلن في `pubspec.yaml`) بجلب المفاتيح.
Future<String?> readEnvFile(String fileName) async => null;
