import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// اختبار حرس يقارن كل ملفات ARB بقالب العربية.
///
/// يمنع تسلل مفاتيح ناقصة أو مفاتيح زائدة عن القالب، أو قيم فارغة أو مساوية
/// لمفتاحها — وهي أخطاء شائعة عند إضافة مفتاح لقالب واحد وإغفال البقية.
void main() {
  const List<String> locales = <String>[
    'ar',
    'en',
    'fr',
    'es',
    'tr',
    'ur',
    'de',
    'id',
    'ru',
    'zh',
  ];

  Map<String, dynamic> readArb(String locale) {
    final File file = File('lib/l10n/app_$locale.arb');
    expect(file.existsSync(), isTrue, reason: 'ملف الترجمة مفقود: ${file.path}');
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  Set<String> messageKeys(Map<String, dynamic> arb) =>
      arb.keys.where((String key) => !key.startsWith('@')).toSet();

  test('القالب العربي موجود ويحوي مفاتيح فعلية', () {
    expect(messageKeys(readArb('ar')), isNotEmpty);
  });

  test('كل اللغات العشر موجودة برمز @@locale صحيح', () {
    for (final String locale in locales) {
      final Map<String, dynamic> arb = readArb(locale);
      expect(arb['@@locale'], locale, reason: 'رمز اللغة في $locale غير مطابق');
    }
  });

  test('كل ملفات ARB تطابق مفاتيح القالب بلا نقص أو زيادة', () {
    final Set<String> templateKeys = messageKeys(readArb('ar'));
    for (final String locale in locales) {
      final Set<String> keys = messageKeys(readArb(locale));
      expect(
        keys.difference(templateKeys),
        isEmpty,
        reason: 'مفاتيح زائدة في $locale',
      );
      expect(
        templateKeys.difference(keys),
        isEmpty,
        reason: 'مفاتيح ناقصة في $locale',
      );
    }
  });

  test('لا قيمة فارغة ولا قيمة مساوية لمفتاحها', () {
    for (final String locale in locales) {
      final Map<String, dynamic> arb = readArb(locale);
      for (final MapEntry<String, dynamic> entry in arb.entries) {
        if (entry.key.startsWith('@')) continue;
        final Object? value = entry.value;
        expect(value, isA<String>(), reason: '$locale:${entry.key} ليست نصاً');
        final String text = (value as String).trim();
        expect(text, isNotEmpty, reason: '$locale:${entry.key} قيمة فارغة');
        expect(
          text,
          isNot(entry.key),
          reason: '$locale:${entry.key} بقيت على المفتاح',
        );
      }
    }
  });
}
