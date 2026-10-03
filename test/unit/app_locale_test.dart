import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/locale/app_locale.dart';

void main() {
  group('اللغات المدعومة', () {
    test('عشر لغات، والعربية أولاً (الافتراضية)', () {
      expect(supportedAppLocales, hasLength(10));
      expect(supportedAppLocales.first.code, 'ar');
      expect(defaultAppLocale.code, 'ar');
    });

    test('الأكواد المطلوبة كلها موجودة بلا تكرار', () {
      final List<String> codes = AppLocales.codes;
      expect(codes, <String>[
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
      ]);
      expect(codes.toSet().length, codes.length);
    });

    test('العربية والأوردو RTL والباقي LTR', () {
      expect(AppLocales.byCode('ar')!.isRtl, isTrue);
      expect(AppLocales.byCode('ur')!.isRtl, isTrue);
      for (final String code in <String>['en', 'fr', 'es', 'tr', 'de', 'id', 'ru', 'zh']) {
        expect(AppLocales.byCode(code)!.isRtl, isFalse, reason: code);
      }
    });

    test('اسم اللغة يُعرض بلغتها الأصلية', () {
      expect(AppLocales.byCode('ar')!.nativeName, 'العربية');
      expect(AppLocales.byCode('zh')!.nativeName, '简体中文');
      expect(AppLocales.byCode('ru')!.nativeName, 'Русский');
    });

    test('locales تُطابق الرموز بترتيبها نفسه', () {
      expect(
        AppLocales.locales.map((Locale l) => l.languageCode).toList(),
        AppLocales.codes,
      );
    });
  });

  group('التحليل والرجوع للافتراضية', () {
    test('parse يقبل الأكواد المعروفة ويردّ المجهول للافتراضية', () {
      expect(AppLocales.parse('fr').code, 'fr');
      expect(AppLocales.parse('ZH').code, 'zh');
      expect(AppLocales.parse('xx').code, 'ar');
      expect(AppLocales.parse(null).code, 'ar');
      expect(AppLocales.parse('').code, 'ar');
    });

    test('resolve يحوّل Locale غير مدعومة للافتراضية', () {
      expect(AppLocales.resolve(const Locale('es')).code, 'es');
      expect(AppLocales.resolve(const Locale('ja')).code, 'ar');
      expect(AppLocales.resolve(null).code, 'ar');
    });

    test('directionOf يشتقّ الاتجاه من اللغة', () {
      expect(AppLocales.directionOf(const Locale('ar')), TextDirection.rtl);
      expect(AppLocales.directionOf(const Locale('ur')), TextDirection.rtl);
      expect(AppLocales.directionOf(const Locale('en')), TextDirection.ltr);
      expect(AppLocales.directionOf(const Locale('ja')), TextDirection.rtl);
    });
  });
}
