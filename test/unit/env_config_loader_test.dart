import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/services/env_config_loader.dart';

void main() {
  const String validJson = '''
{
  "SUPABASE_URL": "https://demo-project.supabase.co",
  "SUPABASE_ANON_KEY": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.demo.payload.value"
}
''';

  group('EnvConfigLoader.parse', () {
    test('يقبل الصيغة القياسية (--dart-define-from-file)', () {
      final EnvConfig? config =
          EnvConfigLoader.parse(validJson, EnvConfigSource.file);
      expect(config, isNotNull);
      expect(config!.url, 'https://demo-project.supabase.co');
      expect(config.anonKey, contains('eyJhbGci'));
      expect(config.source, EnvConfigSource.file);
    });

    test('يقبل صيغة Supabase CLI (API_URL / ANON_KEY)', () {
      const String cliJson = '{"API_URL":"https://cli.supabase.co",'
          '"ANON_KEY":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.cli.payload"}';
      final EnvConfig? config =
          EnvConfigLoader.parse(cliJson, EnvConfigSource.asset);
      expect(config, isNotNull);
      expect(config!.url, 'https://cli.supabase.co');
      expect(config.source, EnvConfigSource.asset);
    });

    test('يرفض نص المثال قبل ملئه (قيم env.example.json)', () {
      const String example = '{"SUPABASE_URL":'
          '"https://xxxxxxxxxxxx.supabase.co",'
          '"SUPABASE_ANON_KEY":"ضع-هنا-مفتاح-anon-public"}';
      expect(EnvConfigLoader.parse(example, EnvConfigSource.file), isNull);
    });

    test('يرفض JSON التالف أو غير الكائن', () {
      expect(EnvConfigLoader.parse('هذا ليس JSON', EnvConfigSource.file),
          isNull);
      expect(EnvConfigLoader.parse('[]', EnvConfigSource.file), isNull);
      expect(EnvConfigLoader.parse('42', EnvConfigSource.file), isNull);
      expect(EnvConfigLoader.parse('', EnvConfigSource.file), isNull);
      expect(EnvConfigLoader.parse(null, EnvConfigSource.file), isNull);
    });

    test('يرفض مفاتيح ناقصة أو رابطاً غير HTTP', () {
      expect(
        EnvConfigLoader.parse(
            '{"SUPABASE_ANON_KEY":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.x"}',
            EnvConfigSource.file),
        isNull,
        reason: 'بلا رابط',
      );
      expect(
        EnvConfigLoader.parse(
            '{"SUPABASE_URL":"ftp://x.supabase.co",'
            '"SUPABASE_ANON_KEY":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.x"}',
            EnvConfigSource.file),
        isNull,
        reason: 'بروتوكول غير HTTP',
      );
    });

    test('لا يقرأ service_role كمفتاح عام مهما طال', () {
      const String serviceOnly = '{"SUPABASE_URL":"https://a.supabase.co",'
          '"SERVICE_ROLE_KEY":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
          'this-is-the-super-secret-admin-key-indeed"}';
      expect(EnvConfigLoader.parse(serviceOnly, EnvConfigSource.file), isNull,
          reason: 'مفتاح المشرف لا يُستخدم في التطبيق أبداً');
    });
  });

  group('EnvConfigLoader.load', () {
    test('القرص أولاً، ولا يُستدعى الأصل المحزوم إن نجح', () async {
      final List<String> calls = <String>[];
      final EnvConfigLoader loader = EnvConfigLoader(
        readFile: (String name) async {
          calls.add('file:$name');
          return validJson;
        },
        readAsset: (String name) async {
          calls.add('asset:$name');
          return validJson;
        },
      );

      final EnvConfig? config = await loader.load();
      expect(config, isNotNull);
      expect(config!.source, EnvConfigSource.file);
      expect(calls, <String>['file:env.json']);
    });

    test('عند غياب القرص ينتقل إلى الأصل المحزوم', () async {
      final List<String> calls = <String>[];
      final EnvConfigLoader loader = EnvConfigLoader(
        readFile: (String name) async {
          calls.add('file:$name');
          return null;
        },
        readAsset: (String name) async {
          calls.add('asset:$name');
          return validJson;
        },
      );

      final EnvConfig? config = await loader.load();
      expect(config!.source, EnvConfigSource.asset);
      expect(calls, <String>[
        'file:env.json',
        'file:assets/env/env.json',
        'asset:assets/env/env.json',
      ]);
    });

    test('استثناء القراءة يُعامَل كغياب ولا يُسقط التحميل', () async {
      final EnvConfigLoader loader = EnvConfigLoader(
        readFile: (String _) async => throw Exception('أصل غير مُعلن'),
        readAsset: (String _) async => validJson,
      );

      final EnvConfig? config = await loader.load();
      expect(config, isNotNull);
      expect(config!.source, EnvConfigSource.asset);
    });

    test('حين لا يوجد أي صالح يُرجع null', () async {
      final EnvConfigLoader loader = EnvConfigLoader(
        readFile: (String _) async => null,
        readAsset: (String _) async => null,
      );
      expect(await loader.load(), isNull);
    });

    test('ملف على القرص يحمل نص المثال لا يُعتمد (يُرفض ولا يعوق الأصل)',
        () async {
      const String unfilled = '{"SUPABASE_URL":'
          '"https://xxxxxxxxxxxx.supabase.co",'
          '"SUPABASE_ANON_KEY":"ضع-هنا-مفتاح-anon-public"}';
      final EnvConfigLoader loader = EnvConfigLoader(
        readFile: (String _) async => unfilled,
        readAsset: (String _) async => validJson,
      );

      final EnvConfig? config = await loader.load();
      expect(config!.source, EnvConfigSource.asset,
          reason: 'القيم النموذجية ليست مفاتيح فتُتخطى إلى المصدر التالي');
    });
  });

  test('env.json مُعلن كأصل ويصل فعلاً عبر rootBundle', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // قارئ قرص وهمي يعيد الفراغ لعزل مسار الأصل المحزوم وحده.
    final EnvConfigLoader loader =
        EnvConfigLoader(readFile: (String _) async => null);

    final EnvConfig? config = await loader.load();
    expect(config, isNotNull,
        reason: 'env.json يجب أن يكون محزوماً في pubspec.yaml وأن يُقرأ');
    expect(config!.source, EnvConfigSource.asset);
    expect(config.url, startsWith('http'));
    expect(config.anonKey.length, greaterThan(20));
  });
}
