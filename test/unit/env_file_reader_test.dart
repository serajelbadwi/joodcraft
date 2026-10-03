import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/services/env_file_reader.dart';

void main() {
  late Directory originalCwd;
  late Directory tempDir;

  setUp(() {
    originalCwd = Directory.current;
    tempDir = Directory.systemTemp.createTempSync('joodcraft_env_');
  });

  tearDown(() {
    Directory.current = originalCwd;
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  String join(String dir, String name) =>
      '$dir${Platform.pathSeparator}$name';

  test('يقرأ env.json من مجلد التشغيل', () async {
    Directory.current = tempDir.path;
    File(join(tempDir.path, 'env.json')).writeAsStringSync(
      '{"SUPABASE_URL":"https://disk.supabase.co"}',
    );

    final String? raw = await readEnvFile('env.json');
    expect(raw, isNotNull);
    expect(raw, contains('disk.supabase.co'));
  });

  test('يعتد إلى المجلدات العليا حتى يجده', () async {
    File(join(tempDir.path, 'env.json')).writeAsStringSync(
      '{"SUPABASE_URL":"https://parent.supabase.co"}',
    );
    final Directory sub = Directory(join(tempDir.path, 'sub'))..createSync();
    Directory.current = sub.path;

    final String? raw = await readEnvFile('env.json');
    expect(raw, isNotNull);
    expect(raw, contains('parent.supabase.co'));
  });

  test('يرجع null إن لم يوجد الملف', () async {
    Directory.current = tempDir.path;
    expect(await readEnvFile('env.json'), isNull);
  });

  test('لا يقرأ الملفات الأخرى بالمصادقة نفسها', () async {
    Directory.current = tempDir.path;
    File(join(tempDir.path, 'other.json')).writeAsStringSync('{"x":1}');
    expect(await readEnvFile('env.json'), isNull);
  });
}
