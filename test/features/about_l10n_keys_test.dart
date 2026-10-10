import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/l10n/generated/app_localizations.dart';
import 'package:joodcraft/l10n/generated/app_localizations_ar.dart';
import 'package:joodcraft/l10n/generated/app_localizations_de.dart';
import 'package:joodcraft/l10n/generated/app_localizations_en.dart';
import 'package:joodcraft/l10n/generated/app_localizations_es.dart';
import 'package:joodcraft/l10n/generated/app_localizations_fr.dart';
import 'package:joodcraft/l10n/generated/app_localizations_id.dart';
import 'package:joodcraft/l10n/generated/app_localizations_ru.dart';
import 'package:joodcraft/l10n/generated/app_localizations_tr.dart';
import 'package:joodcraft/l10n/generated/app_localizations_ur.dart';
import 'package:joodcraft/l10n/generated/app_localizations_zh.dart';

/// اختبارات **مفاتيح الترجمة الخاصة بشاشة «حول»** (بادئة `about*`).
///
/// تغطي المتطلّب: «كل الأقسام موجودة + المفاتيح في 10 لغات».
///
/// تعمل هذه الاختبارات على **ملفات ARB مباشرةً** (لا على الشاشة)، فتقيس
/// المتطلّب الذي تملّكه هذه المهمة فعلاً — اكتمال لوحة المفاتيح وتطابقها بين
/// اللغات العشر — بلا اعتماد على ملف الشاشة الذي تعمل عليه مهمة أخرى بالتوازي.
void main() {
  /// اللغات العشر المدعومة — نفس قائمة `l10n_arb_parity_test.dart`.
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

  /// مفاتيح شاشة «حول» التي تطلبها المهمة، بترتيبها المنطقي.
  ///
  /// `aboutVersion` **دالة** بمعامل `version` (لا نصّ ثابت)، وباقي المفاتيح
  /// نصوصّ عادية — وهذا ما يفحصه اختبار «لوحة المفاتيح» أدناه.
  const List<String> requiredKeys = <String>[
    'aboutTitle',
    'aboutTagline',
    'aboutDescription',
    'aboutFeatures',
    'aboutFeatureVisualEditor',
    'aboutFeature10Languages',
    'aboutFeatureArabicText',
    'aboutFeatureBulkGeneration',
    'aboutFeatureOffline',
    'aboutFeaturePdfExport',
    'aboutDeveloper',
    'aboutDeveloperName',
    'aboutDeveloperNote',
    'aboutLinks',
    'aboutViewLicenses',
    'aboutSendFeedback',
    'aboutCredits',
    'aboutCreditsText',
    'aboutVersion',
  ];

  Map<String, dynamic> readArb(String locale) {
    final File file = File('lib/l10n/app_$locale.arb');
    expect(file.existsSync(), isTrue, reason: 'ملف الترجمة مفقود: ${file.path}');
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  group('اكتمال لوحة مفاتيح شاشة «حول»', () {
    test('كل مفتاح مطلوب موجود في العربية', () {
      final Map<String, dynamic> arb = readArb('ar');
      for (final String key in requiredKeys) {
        expect(arb.containsKey(key), isTrue, reason: 'المفتاح $key مفقود من ar');
      }
    });

    test('كل مفتاح مطلوب موجود في كل لغة من العشر', () {
      for (final String locale in locales) {
        final Map<String, dynamic> arb = readArb(locale);
        for (final String key in requiredKeys) {
          expect(
            arb.containsKey(key),
            isTrue,
            reason: '$locale: المفتاح $key مفقود',
          );
        }
      }
    });

    test('كل قيمة نصّية غير فارغة ولا مساوية لمفتاحها', () {
      for (final String locale in locales) {
        final Map<String, dynamic> arb = readArb(locale);
        for (final String key in requiredKeys) {
          final Object? value = arb[key];
          expect(value, isA<String>(), reason: '$locale:$key ليست نصاً');
          final String text = (value as String).trim();
          expect(text, isNotEmpty, reason: '$locale:$key قيمة فارغة');
          expect(text, isNot(key), reason: '$locale:$key بقيت على المفتاح');
        }
      }
    });

    test('عدد مفاتيح about* متساوٍ في كل اللغات (بلا نقص أو زيادة)', () {
      final Map<String, int> counts = <String, int>{};
      for (final String locale in locales) {
        final Map<String, dynamic> arb = readArb(locale);
        counts[locale] = arb.keys
            .where((String k) => k.startsWith('about') && !k.startsWith('@'))
            .length;
      }
      // 36 = 19 مفتاحاً مطلوباً + 17 مفتاحاً إضافياً للمحتوى التفصيلي.
      expect(counts.values.every((int c) => c == 36), isTrue, reason: '$counts');
    });

    test('مجموعات مفاتيح about* مطابقة بين العربية وكل لغة', () {
      final Set<String> template = readArb('ar')
          .keys
          .where((String k) => k.startsWith('about'))
          .toSet();
      for (final String locale in locales) {
        final Set<String> keys =
            readArb(locale).keys.where((String k) => k.startsWith('about')).toSet();
        expect(keys.difference(template), isEmpty, reason: 'مفاتيح زائدة في $locale');
        expect(template.difference(keys), isEmpty, reason: 'مفاتيح ناقصة في $locale');
      }
    });
  });

  group('لوحة المفاتيح المولّدة (AppLocalizations)', () {
    test('aboutVersion دالة بمعامل يعيد الرمز داخل النصّ', () {
      // حرس مهم: لو تحوّل المفتاح إلى نصّ ثابت اختفى رقم الإصدار من الشاشة.
      const String probe = '9.9.9-probe';
      for (final String locale in locales) {
        final AppLocalizations l10n = _localizationsOf(locale);
        expect(
          l10n.aboutVersion(probe),
          contains(probe),
          reason: '$locale: aboutVersion لا يحمل رقم الإصدار',
        );
      }
    });

    test('المفاتيح النصية غير فارغة في كل اللغات', () {
      for (final String locale in locales) {
        final AppLocalizations l10n = _localizationsOf(locale);
        for (final String key in const <String>[
          'aboutTitle',
          'aboutTagline',
          'aboutDescription',
          'aboutFeatures',
          'aboutLinks',
          'aboutDeveloper',
          'aboutDeveloperNote',
          'aboutViewLicenses',
          'aboutSendFeedback',
          'aboutCredits',
          'aboutCreditsText',
        ]) {
          expect(
            switch (key) {
              'aboutTitle' => l10n.aboutTitle,
              'aboutTagline' => l10n.aboutTagline,
              'aboutDescription' => l10n.aboutDescription,
              'aboutFeatures' => l10n.aboutFeatures,
              'aboutLinks' => l10n.aboutLinks,
              'aboutDeveloper' => l10n.aboutDeveloper,
              'aboutDeveloperNote' => l10n.aboutDeveloperNote,
              'aboutViewLicenses' => l10n.aboutViewLicenses,
              'aboutSendFeedback' => l10n.aboutSendFeedback,
              'aboutCredits' => l10n.aboutCredits,
              _ => l10n.aboutCreditsText,
            }.trim().isNotEmpty,
            isTrue,
            reason: '$locale: $key فارغ',
          );
        }
      }
    });

    test('العناوين العربية والآنكليزية مختلفة (ترجمة فعلية لا نسخ)', () {
      final AppLocalizations ar = _localizationsOf('ar');
      final AppLocalizations en = _localizationsOf('en');

      expect(ar.aboutTitle, isNot(en.aboutTitle));
      expect(ar.aboutFeatures, isNot(en.aboutFeatures));
      expect(ar.aboutViewLicenses, isNot(en.aboutViewLicenses));
      expect(ar.aboutSendFeedback, isNot(en.aboutSendFeedback));
      expect(ar.aboutCreditsText, isNot(en.aboutCreditsText));
    });

    test('لغة غير مدعومة لا تُسقط الاستدعاء', () {
      // `_localizationsOf` يرجع العربية كافتراضية — بلا رمي.
      expect(_localizationsOf('ja').aboutTitle, isNotEmpty);
    });
  });

  group('مفاتيح المميزات الستّ', () {
    test('كل العناوين الفرعية للمميزات موجودة ومترجمة', () {
      for (final String locale in locales) {
        final AppLocalizations l10n = _localizationsOf(locale);
        final List<String> labels = <String>[
          l10n.aboutFeatureVisualEditor,
          l10n.aboutFeature10Languages,
          l10n.aboutFeatureArabicText,
          l10n.aboutFeatureBulkGeneration,
          l10n.aboutFeatureOffline,
          l10n.aboutFeaturePdfExport,
        ];
        for (final String label in labels) {
          expect(label.trim().isNotEmpty, isTrue, reason: locale);
        }
        // كل ميزة عنوان مستقل — لا تكرار.
        expect(labels.toSet().length, labels.length, reason: locale);
      }
    });
  });
}

/// الترجمات المولَّدة للغة المطلوبة (العربية عند غيابها).
///
/// الكلاسات المولَّدة بناة عاديون بلا حالة، فالإنشاء رخيص وآمن للنداء المتكرر.
AppLocalizations _localizationsOf(String locale) => switch (locale) {
      'ar' => AppLocalizationsAr('ar'),
      'de' => AppLocalizationsDe('de'),
      'en' => AppLocalizationsEn('en'),
      'es' => AppLocalizationsEs('es'),
      'fr' => AppLocalizationsFr('fr'),
      'id' => AppLocalizationsId('id'),
      'ru' => AppLocalizationsRu('ru'),
      'tr' => AppLocalizationsTr('tr'),
      'ur' => AppLocalizationsUr('ur'),
      'zh' => AppLocalizationsZh('zh'),
      _ => AppLocalizationsAr('ar'),
    };
