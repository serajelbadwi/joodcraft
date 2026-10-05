import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/fonts/system_font_disk_cache.dart';

void main() {
  late Directory temp;
  late Directory sourceDir;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('jood_font_cache_test');
    sourceDir = Directory('${temp.path}/src')..createSync(recursive: true);
  });

  tearDown(() {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  SystemFontDiskCache cache({int maxEntries = SystemFontDiskCache.defaultMaxEntries}) =>
      SystemFontDiskCache(root: Directory('${temp.path}/cache'), maxEntries: maxEntries);

  File font(String name, List<int> bytes) =>
      File('${sourceDir.path}/$name')..writeAsBytesSync(bytes);

  test('يحفظ البايتات ثم يعيدها من الكاش بلا قراءة المصدر', () async {
    final File file = font('a.ttf', <int>[1, 2, 3, 4]);
    final SystemFontDiskCache c = cache();

    expect(await c.read(file.path), isNull, reason: 'لا نسخة بعد.');

    await c.write(file.path, Uint8List.fromList(<int>[1, 2, 3, 4]));
    final Uint8List? read = await c.read(file.path);
    expect(read, isNotNull);
    expect(read, <int>[1, 2, 3, 4]);
  });

  test('يُبطل النسخة تلقائياً عند تغيّر الملف المصدر', () async {
    final File file = font('b.ttf', <int>[1, 2, 3]);
    final SystemFontDiskCache c = cache();
    await c.write(file.path, Uint8List.fromList(<int>[1, 2, 3]));
    expect(await c.read(file.path), isNotNull);

    // تغيير حجم الملف يغيّر المفتاح ⇒ لا نسخة مطابقة.
    file.writeAsBytesSync(<int>[9, 9, 9, 9, 9]);
    expect(await c.read(file.path), isNull);
  });

  test('ملف مصدر مفقود يُرجع null', () async {
    final SystemFontDiskCache c = cache();
    expect(await c.read('${temp.path}/missing.ttf'), isNull);
  });

  test('يُسقط الأقدم عند تجاوز الحدّ الأعلى (LRU)', () async {
    final SystemFontDiskCache c = cache(maxEntries: 2);
    final List<File> files = <File>[
      font('r1.ttf', <int>[1]),
      font('r2.ttf', <int>[2]),
      font('r3.ttf', <int>[3]),
    ];
    for (final File f in files) {
      await c.write(f.path, Uint8List.fromList(<int>[f.path.length]));
      // فاصل زمني بسيط ليختلف زمن آخر تعديل.
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    final int kept = Directory('${temp.path}/cache')
        .listSync()
        .where((FileSystemEntity e) => e.path.endsWith('.bin'))
        .length;
    expect(kept, lessThanOrEqualTo(2));
  });

  test('clear يمسح الكاش كله', () async {
    final File file = font('c.ttf', <int>[1, 2]);
    final SystemFontDiskCache c = cache();
    await c.write(file.path, Uint8List.fromList(<int>[1, 2]));
    expect(await c.read(file.path), isNotNull);

    await c.clear();
    expect(await c.read(file.path), isNull);
  });
}
