import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_env.dart';
import 'package:joodcraft/core/services/env_config_loader.dart';

void main() {
  const String validJson = '''
{
  "SUPABASE_URL": "https://demo-project.supabase.co",
  "SUPABASE_ANON_KEY": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.demo.payload.value"
}
''';

  setUp(AppEnv.resetForTesting);
  tearDown(AppEnv.resetForTesting);

  test('load يقرأ أفضل مصدر ويخزّنه، والاستدعاء الثاني لا يعيد البحث',
      () async {
    int fileCalls = 0;
    bool assetTouched = false;
    final EnvConfigLoader loader = EnvConfigLoader(
      readFile: (String _) async {
        fileCalls++;
        return validJson;
      },
      readAsset: (String _) async {
        assetTouched = true;
        return validJson;
      },
    );

    // الحالة الابتدائية (بلا --dart-define في الاختبارات): غير مضبوطة.
    expect(AppEnv.isSupabaseConfigured, isFalse);
    expect(AppEnv.source, EnvConfigSource.none);

    await AppEnv.load(loader: loader);
    expect(AppEnv.isSupabaseConfigured, isTrue);
    expect(AppEnv.supabaseUrl, 'https://demo-project.supabase.co');
    expect(AppEnv.supabaseAnonKey, contains('eyJhbGci'));
    expect(AppEnv.source, EnvConfigSource.file);
    expect(fileCalls, 1);
    expect(assetTouched, isFalse);

    await AppEnv.load(loader: loader);
    expect(fileCalls, 1, reason: 'load() لا يبحث مجدداً بعد نجاحه');
  });

  test('حين لا يوجد أي مصدر تبقى الحالة غير مضبوطة ومصدرها none', () async {
    final EnvConfigLoader loader = EnvConfigLoader(
      readFile: (String _) async => null,
      readAsset: (String _) async => null,
    );

    await AppEnv.load(loader: loader);
    expect(AppEnv.isSupabaseConfigured, isFalse);
    expect(AppEnv.supabaseUrl, '');
    expect(AppEnv.supabaseAnonKey, '');
    expect(AppEnv.source, EnvConfigSource.none);
  });

  test('مصدر فاشل لا يمنع إعادة المحاولة بعد resetForTesting', () async {
    await AppEnv.load(
      loader: EnvConfigLoader(
        readFile: (String _) async => null,
        readAsset: (String _) async => null,
      ),
    );
    expect(AppEnv.isSupabaseConfigured, isFalse);

    AppEnv.resetForTesting();
    await AppEnv.load(
      loader: EnvConfigLoader(
        readFile: (String _) async => validJson,
        readAsset: (String _) async => null,
      ),
    );
    expect(AppEnv.isSupabaseConfigured, isTrue);
    expect(AppEnv.source, EnvConfigSource.file);
  });
}
