import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/templates/preset_catalog.dart';
import 'package:joodcraft/core/templates/preset_template.dart';
import 'package:joodcraft/core/templates/template_localization.dart';

/// **ترجمة محتوى القوالب**: كل لغة بنصوصها وأسماء بلدها، مع بقاء الهندسة
/// والألوان والربط مع Excel كما هي تماماً.
void main() {
  final RegExp token = RegExp(r'\{\{([^}]+)\}\}');
  Set<String> tokensOf(String value) =>
      token.allMatches(value).map((RegExpMatch m) => m.group(1)!).toSet();

  /// القوالب الستّة الأساسية (تقدير، إتمام، تفوق، إفادة، عقد عمل، عقد خدمات).
  const List<String> coreIds = <String>[
    'appreciation_certificate',
    'completion_certificate',
    'excellence_certificate',
    'experience_declaration',
    'employment_contract',
    'service_contract',
  ];

  group('اختيار الحزمة', () {
    test('الرمز القصير والاتجاه والتغطية', () {
      expect(TemplateLocalization.shortCode('fr-CA'), 'fr');
      expect(TemplateLocalization.shortCode(' AR '), 'ar');
      expect(TemplateLocalization.shortCode(null), 'ar');

      expect(TemplateLocalization.isRtl('ar'), isTrue);
      expect(TemplateLocalization.isRtl('ur'), isTrue);
      expect(TemplateLocalization.isRtl('fr'), isFalse);
      expect(TemplateLocalization.isRtl('en'), isFalse);

      // العربية أصل المحتوى فلا حزمة لها، وكل اللغات المعلنة لها محتوى.
      expect(TemplateLocalization.packFor('ar'), isNull);
      expect(TemplateLocalization.hasContent('ar'), isFalse);
      expect(TemplateLocalization.hasContent('xx'), isFalse);
      for (final String code in <String>[
        'en',
        'fr',
        'es',
        'de',
        'tr',
        'id',
        'ru',
        'zh',
        'ur'
      ]) {
        expect(TemplateLocalization.hasContent(code), isTrue, reason: code);
      }
    });
  });

  group('ترجمة المستند', () {
    test('العربية وبلا لغة تُرجع المستند نفسه بلا أي تغيير', () {
      final PresetTemplate preset =
          PresetCatalog.byId('appreciation_certificate')!;
      expect(identical(preset.documentFor('ar'), preset.document), isTrue);
      expect(identical(preset.documentFor(null), preset.document), isTrue);
      expect(identical(preset.documentFor('xx'), preset.document), isTrue);
    });

    test('الفرنسية تترجم النص وتستبدل الأسماء بالبلد', () {
      final PresetTemplate preset =
          PresetCatalog.byId('appreciation_certificate')!;
      final fr = preset.documentFor('fr');

      final TextElement title = fr.elements
          .whereType<TextElement>()
          .firstWhere((TextElement e) => e.id == 'title');
      expect(title.text, 'Certificat de reconnaissance');

      expect(fr.sampleData['اسم_المتدرب'], 'Camille Dubois');
      expect(fr.sampleData['التاريخ'], '15 janvier 2026');
      expect(fr.sampleData['الجهة_المانحة'], 'Académie JoodCraft');
    });

    test('الإنجليزية أسماء إنجليزية، والهندسة والألوان لا تُمسّ', () {
      final PresetTemplate preset =
          PresetCatalog.byId('appreciation_certificate')!;
      final en = preset.documentFor('en');
      final ar = preset.document;

      expect(en.sampleData['اسم_المتدرب'], 'Daniel Whitfield');
      expect(en.sampleData['التاريخ'], '15 January 2026');

      // نفس عدد العناصر ونفس الصناديق ونفس الألوان ونفس مقاس الصفحة.
      expect(en.elements.length, ar.elements.length);
      for (int i = 0; i < ar.elements.length; i++) {
        expect(en.elements[i].box.x, ar.elements[i].box.x);
        expect(en.elements[i].box.y, ar.elements[i].box.y);
        expect(en.elements[i].box.width, ar.elements[i].box.width);
        expect(en.elements[i].box.height, ar.elements[i].box.height);
        expect(en.elements[i].rotation, ar.elements[i].rotation);
        expect(en.elements[i].id, ar.elements[i].id);
        expect(
          en.elements[i].runtimeType,
          ar.elements[i].runtimeType,
        );
      }
      expect(en.backgroundHex, ar.backgroundHex);
      expect(en.pageWidthPt, ar.pageWidthPt);
      expect(en.orientation, ar.orientation);
      final TextElement arTitle = ar.elements
          .whereType<TextElement>()
          .firstWhere((TextElement e) => e.id == 'title');
      final TextElement enTitle = en.elements
          .whereType<TextElement>()
          .firstWhere((TextElement e) => e.id == 'title');
      expect(enTitle.colorHex, arTitle.colorHex);
      expect(enTitle.fontSize, arTitle.fontSize);
      expect(enTitle.align, arTitle.align);
    });

    test('الاتجاه يصبح LTR للاتينية فيصحّ معنى start (والعربية تبقى RTL)', () {
      final PresetTemplate preset =
          PresetCatalog.byId('employment_contract')!;

      final TextElement frPreamble = preset
          .documentFor('fr')
          .elements
          .whereType<TextElement>()
          .firstWhere((TextElement e) => e.id == 'preamble');
      expect(frPreamble.direction, ElementDirection.ltr);
      expect(frPreamble.text, startsWith('Le '));

      final TextElement arPreamble = preset.document.elements
          .whereType<TextElement>()
          .firstWhere((TextElement e) => e.id == 'preamble');
      expect(arPreamble.direction, ElementDirection.rtl);
    });

    test('نص بلا ترجمة يبقى عربياً كما هو (لا كسر لأي قالب)', () {
      final Set<String> mapped =
          TemplateLocalization.packs['fr']!.texts.keys.toSet();
      final PresetTemplate preset =
          PresetCatalog.byId('royal_navy_gold_certificate')!;
      final fr = preset.documentFor('fr');
      final ar = preset.document;

      int kept = 0;
      for (int i = 0; i < ar.elements.length; i++) {
        final TemplateElement element = ar.elements[i];
        if (element is! TextElement) continue;
        if (mapped.contains(element.text)) continue;
        expect(
          (fr.elements[i] as TextElement).text,
          element.text,
          reason: 'نص غير مترجم يجب أن يبقى عربياً: ${element.text}',
        );
        kept++;
      }
      expect(kept, greaterThan(0),
          reason: 'قالب المعرض يحمل نصوصاً غير مترجمة (تغطية تدريجية).');
    });

    test('رموز الحقول {{...}} محفوظة حرفياً في كل ترجمة (ربط Excel بلا كسر)',
        () {
      for (final MapEntry<String, TemplateContentPack> pack
          in TemplateLocalization.packs.entries) {
        pack.value.texts.forEach((String ar, String localized) {
          expect(
            tokensOf(localized),
            tokensOf(ar),
            reason: '${pack.key}: $ar',
          );
        });
      }
    });

    test('كل رمز في القوالب الأساسية له قيمة تجريبية بعد الترجمة', () {
      for (final String id in coreIds) {
        final PresetTemplate preset = PresetCatalog.byId(id)!;
        for (final String? language in <String?>[
          'ar',
          'en',
          'fr',
          'es',
          'de',
          'tr',
          'id',
          'ru',
          'zh',
          'ur',
        ]) {
          final document = preset.documentFor(language);
          for (final TextElement element
              in document.elements.whereType<TextElement>()) {
            for (final String key in tokensOf(element.text)) {
              expect(
                document.sampleData.containsKey(key),
                isTrue,
                reason: '$id / $language / $key',
              );
            }
          }
        }
      }
    });

    test('لا يبقى أي رمز غير محلول بعد الدمج مع البيانات التجريبية', () {
      // `resolveFields` هو ما يستخدمه المحرّر والمعاينة والـ PDF نفسه.
      for (final String id in coreIds) {
        final PresetTemplate preset = PresetCatalog.byId(id)!;
        for (final String language in <String>[
          'en',
          'fr',
          'es',
          'de',
          'tr',
          'id',
          'ru',
          'zh',
          'ur',
        ]) {
          final document = preset.documentFor(language);
          for (final TextElement element
              in document.elements.whereType<TextElement>()) {
            final String resolved =
                document.resolveFields(element.text, document.sampleData);
            expect(
              resolved.contains('{{'),
              isFalse,
              reason: '$id / $language: $resolved',
            );
          }
        }
      }
    });
  });

  group('تغطية كاملة لكل القوالب (20/20)', () {
    // كل اللغات المدعومة التي لها حزمة محتوى (العربية أصل فلا حزمة لها).
    const List<String> localized = <String>[
      'en',
      'fr',
      'es',
      'de',
      'tr',
      'id',
      'ru',
      'zh',
      'ur',
    ];
    final RegExp arabic = RegExp(r'[\u0600-\u06FF]');
    String stripTokens(String value) =>
        value.replaceAll(RegExp(r'\{\{[^}]*\}\}'), '');

    test('كل نص عربي في كل القوالب له ترجمة في كل اللغات', () {
      for (final String language in localized) {
        final Set<String> mapped =
            TemplateLocalization.packs[language]!.texts.keys.toSet();
        for (final PresetTemplate preset in PresetCatalog.all) {
          for (final TextElement element
              in preset.document.elements.whereType<TextElement>()) {
            // نص من رموز فقط (اسم المتدرّب/التاريخ) لا يحتاج ترجمة.
            if (stripTokens(element.text).trim().isEmpty) continue;
            // ونص لاتيني أصلاً مقروء كما هو في اللغات اللاتينية.
            if (!arabic.hasMatch(element.text)) continue;
            expect(
              mapped.contains(element.text),
              isTrue,
              reason: '$language: ${preset.id} → ${element.text}',
            );
          }
        }
      }
    });

    // الأردية تُكتب بالأبجدية العربية نفسها، فلا يمكن التمييز بمدى المحارف بين
    // نصّها المترجم والنصّ العربي الأصلي؛ تُغطّى الأردية باختبار مستقلّ أدناه.
    final List<String> scriptDistinct =
        localized.where((String l) => l != 'ur').toList();

    test('بعد الترجمة لا يبقى أي نص عربي في أي قالب (اللغات ذات خطّ مختلف)', () {
      for (final PresetTemplate preset in PresetCatalog.all) {
        for (final String language in scriptDistinct) {
          final document = preset.documentFor(language);
          for (final TextElement element
              in document.elements.whereType<TextElement>()) {
            final String bare = stripTokens(element.text);
            expect(
              arabic.hasMatch(bare),
              isFalse,
              reason: '${preset.id} / $language: ${element.text}',
            );
          }
          // والقيم التجريبية صارت من البلد كذلك.
          for (final MapEntry<String, String> entry
              in document.sampleData.entries) {
            expect(
              arabic.hasMatch(entry.value),
              isFalse,
              reason: '${preset.id} / $language / ${entry.key}: ${entry.value}',
            );
          }
        }
      }
    });

    test('الأردية تترجم كل نص عربي ثابت (لا يبقى النص العربي نفسه)', () {
      final Set<String> mapped =
          TemplateLocalization.packs['ur']!.texts.keys.toSet();
      for (final PresetTemplate preset in PresetCatalog.all) {
        final ar = preset.document;
        final ur = preset.documentFor('ur');
        for (int i = 0; i < ar.elements.length; i++) {
          final TemplateElement element = ar.elements[i];
          if (element is! TextElement) continue;
          // نص رمزي محض (بلا حروف ثابتة، مثل «{{الجهة}} — {{التاريخ}}»)
          // لا معنى لترجمته فيبقى كما هو.
          if (TemplateLocalization.isPlaceholderOnly(element.text)) continue;
          if (!arabic.hasMatch(element.text)) continue;
          expect(
            mapped.contains(element.text),
            isTrue,
            reason: '${preset.id} → ${element.text}',
          );
          // تُرجم فعلاً، فلا يبقى النص العربي الأصلي حرفياً.
          expect(
            (ur.elements[i] as TextElement).text == element.text,
            isFalse,
            reason: 'ليست مترجمة للأردية: ${preset.id} → ${element.text}',
          );
        }
      }
    });

    test('كل رمز في كل القوالب محلول بعد الترجمة (لا {{...}} معلّق)', () {
      for (final PresetTemplate preset in PresetCatalog.all) {
        for (final String language in localized) {
          final document = preset.documentFor(language);
          for (final TextElement element
              in document.elements.whereType<TextElement>()) {
            final String resolved =
                document.resolveFields(element.text, document.sampleData);
            expect(
              resolved.contains('{{'),
              isFalse,
              reason: '${preset.id} / $language: $resolved',
            );
          }
        }
      }
    });
  });

  group('الصيغ الشرطية للجنس داخل نصوص القوالب', () {
    TemplateDocument genderDocument({
      Map<String, String> sampleData = const <String, String>{},
      required String text,
    }) =>
        TemplateDocument(
          sampleData: sampleData,
          elements: <TemplateElement>[
            TextElement(
              id: 't1',
              box: const ElementBox(x: 100, y: 100, width: 600, height: 80),
              text: text,
            ),
          ],
        );

    test('استبدال الجملة المركّبة بالجنسين مع الرجوع إلى المذكّر', () {
      final TemplateDocument document = genderDocument(
        text: 'قد {{الجنس: اجتاز | اجازت}} الاختبار بنجاح',
      );

      expect(
        document.resolveFields('قد {{الجنس: اجتاز | اجازت}} الاختبار بنجاح',
            const <String, String>{'الجنس': 'ذكر'}),
        'قد اجتاز الاختبار بنجاح',
      );
      expect(
        document.resolveFields('قد {{الجنس: اجتاز | اجازت}} الاختبار بنجاح',
            const <String, String>{'الجنس': 'أنثى'}),
        'قد اجازت الاختبار بنجاح',
      );
      // بلا أي دليل على الجنس: الفرع الأول (المذكّر).
      expect(
        document.resolveFields(
          'قد {{الجنس: اجتاز | اجازت}} الاختبار بنجاح',
          null,
        ),
        'قد اجتاز الاختبار بنجاح',
      );
    });

    test('صيغتان في نص واحد تُحلّان معاً (ضمير الملكية وضمير الجر)', () {
      const String text =
          'بناءً على طلب{{الجنس: ه | ها}} نتمنى {{الجنس: له | لها}} التوفيق';
      expect(
        genderDocument(text: text).resolveFields(
          text,
          const <String, String>{'الجنس': 'أنثى'},
        ),
        'بناءً على طلبها نتمنى لها التوفيق',
      );
    });

    test('الجنس يُستنتج من اسم السجل عند غياب عمود الجنس', () {
      final TemplateDocument document = genderDocument(
        sampleData: const <String, String>{'اسم_المتدرب': 'سارة العتيبي'},
        text: 'تُمنح هذه الشهادة {{الجنس: للطالب | للطالبة}} {{اسم_المتدرب}}',
      );
      // بلا بيانات صف: يُستنتج من القيم التجريبية في القالب (سارة ← أنثى).
      expect(
        document.resolveFields(
          'تُمنح هذه الشهادة {{الجنس: للطالب | للطالبة}} {{اسم_المتدرب}}',
          null,
        ),
        'تُمنح هذه الشهادة للطالبة سارة العتيبي',
      );
      // ومع بيانات صف مذكّر يُتبدّل الفرع.
      expect(
        document.resolveFields(
          'تُمنح هذه الشهادة {{الجنس: للطالب | للطالبة}} {{اسم_المتدرب}}',
          const <String, String>{'اسم_المتدرب': 'أحمد الشمري'},
        ),
        'تُمنح هذه الشهادة للطالب أحمد الشمري',
      );
    });

    test('صيغة الجنس ليست حقلاً ديناميكياً يُربط بعمود', () {
      final TemplateDocument document = genderDocument(
        text: 'تُمنح هذه الشهادة {{الجنس: للطالب | للطالبة}} '
            '{{اسم_المتدرب}} في {{اسم_الدورة}}',
      );
      expect(document.fieldKeys, <String>{'اسم_المتدرب', 'اسم_الدورة'});
      // ولا ظهور لقيمة الجنس في الحقول المطلوبة مهما تكرّرت الصيغة.
      expect(
        document.fieldKeys.any((String key) => key.contains('الجنس')),
        isFalse,
      );
    });

    test('محتوى القوالب المترجَم يبقى سليماً بعد حلّ الجنس', () {
      // حلّ الصيغة الشرطية لا يمسّ ترجمة المحتوى (الطبقتان مستقلّتان).
      final PresetTemplate preset =
          PresetCatalog.byId('appreciation_certificate')!;
      final TemplateDocument french = preset.documentFor('fr');
      final TemplateDocument arabic = preset.documentFor('ar');
      expect(french.elements.length, arabic.elements.length);
      expect(french.fieldKeys, arabic.fieldKeys);
    });
  });

  group('العنوان والمسودة والسجل', () {
    test('عنوان القالب يترجم مع الرجوع إلى العربية', () {
      final PresetTemplate preset =
          PresetCatalog.byId('employment_contract')!;
      expect(preset.titleFor('fr'), 'Contrat de travail');
      expect(preset.titleFor('en'), 'Employment Contract');
      expect(preset.titleFor('ar'), preset.titleAr);
      expect(preset.titleFor('xx'), preset.titleAr);
    });

    test('المسودة والسجل يحملان محتوى اللغة المطلوبة', () {
      final PresetTemplate preset =
          PresetCatalog.byId('service_contract')!;

      final frDraft = preset.toDraft(languageCode: 'fr');
      expect(frDraft.title, 'Contrat de prestation de services');
      expect(frDraft.document.sampleData['اسم_الطرف_الأول'],
          'Société Jood Commerce');

      final arRecord = preset.toRecord();
      final enRecord = preset.toRecord(languageCode: 'en');
      expect(arRecord.title, preset.titleAr);
      expect(enRecord.title, 'Service Agreement');
      // حمولة السجل الإنجليزية تحمل النص الإنجليزي فعلاً.
      expect(
        enRecord.layoutData.toString().contains('Service Agreement'),
        isTrue,
      );
    });
  });
}
