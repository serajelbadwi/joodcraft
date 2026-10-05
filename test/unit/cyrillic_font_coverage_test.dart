import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/fonts/font_inspector.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/pdf/pdf_font_catalog.dart';
import 'package:joodcraft/core/services/pdf_generator_service.dart';

/// حرس تغطية السيريلية: يمنع عودة مربعات فارغة (□□□) في النصوص السيريلية غير
/// الروسية (الأوكرانية والصربية والبلغارية والسلافية الكنسية القديمة).
///
/// الخلفية: خط الصينية المحزوم (Noto Sans SC) لا يملك من السيريلية إلا الأبجدية
/// الروسية الأساسية (‎66 محرفاً)، ولا خط عربي محزوم يغطي السيريلية إطلاقاً.
/// الحل: خط Noto Sans مُصغَّر (**محزوم** داخل الحزمة) يغطي الكتلة السيريلية
/// كاملة، ويمرّ خطاً احتياطياً في الواجهة وفي محرّك الـ PDF.
///
/// هذا الاختبار يثبت أن الملف المحزوم فعلاً يغطي الكتلة كاملة، وأن محرّك الـ PDF
/// يستعمله فيرسم الحروف التي كان يعجز عنها.
const List<(int, int, String)> _cyrillicRanges = <(int, int, String)>[
  (0x0400, 0x04FF, 'Cyrillic'),
  (0x0500, 0x052F, 'Cyrillic Supplement'),
  (0x2DE0, 0x2DFF, 'Cyrillic Extended-A'),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FontInspection cyrillic;

  setUpAll(() async {
    cyrillic = FontInspector.inspect(
      (await rootBundle.load(AppAssets.notoCyrillicFontFile)).buffer.asUint8List(),
    );
  });

  group('خط السيريلية المحزوم', () {
    test('ملف صالح بمحيطات TrueType واسم عائلة Noto Sans', () {
      expect(cyrillic.isValid, isTrue, reason: cyrillic.errorAr);
      expect(cyrillic.hasTrueTypeOutlines, isTrue);
      expect(cyrillic.familyName, AppAssets.notoCyrillicFont);
      expect(cyrillic.covers(0x0410), isTrue, reason: 'А الروسية');
    });

    test('يبقى خفيفاً — الخط الكامل يبلغ ‎~400KB', () {
      final File file = File(AppAssets.notoCyrillicFontFile);
      expect(file.existsSync(), isTrue, reason: 'الخط غير محزوم');
      // الخط الكامل (بلا تصغير) ‎~400KB؛ نضمن بقاءه صغيراً جداً في الحزمة.
      expect(
        file.lengthSync(),
        lessThan(256 * 1024),
        reason: 'الملف ${file.lengthSync()} بايت — هل نُسي التصغير؟',
      );
    });

    test('pubspec يسجّل العائلة بمسارها الفعلي', () {
      final String pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('family: Noto Sans'));
      expect(pubspec, contains('asset: ${AppAssets.notoCyrillicFontFile}'));
      expect(File(AppAssets.notoCyrillicFontFile).existsSync(), isTrue);
    });

    test('يُمرَّر خطاً احتياطياً في الواجهة (بعد خط الصينية)', () {
      expect(AppAssets.uiFontFallback, contains(AppAssets.notoCyrillicFont));
      expect(
        AppAssets.uiFontFallback.indexOf(AppAssets.notoCyrillicFont),
        greaterThan(AppAssets.uiFontFallback.indexOf(AppAssets.notoScFont)),
      );
    });
  });

  group('تغطية الكتلة السيريلية كاملة', () {
    for (final (int start, int end, String name) in _cyrillicRanges) {
      test('$name — U+${start.toRadixString(16)}..U+${end.toRadixString(16)}', () {
        final List<String> missing = <String>[];
        for (int code = start; code <= end; code++) {
          if (!cyrillic.covers(code)) missing.add(String.fromCharCode(code));
        }
        expect(
          missing,
          isEmpty,
          reason: 'محارف سيريلية يغيب عن الخط المحزوم: ${missing.join()}',
        );
      });
    }

    test('الخط يغطي الحروف التي لا يملكها خط الصينية', () {
      // هذه الحروف غائبة عن Noto Sans SC: أوكرانية وصربية/مقدونية وبلغارية.
      for (final int code in <int>[0x0404, 0x0407, 0x0409, 0x040A, 0x040B, 0x0490]) {
        expect(
          cyrillic.covers(code),
          isTrue,
          reason: 'U+${code.toRadixString(16)} غير مغطّى',
        );
      }
    });
  });

  group('محرّك الـ PDF يستعمل خط السيريلية', () {
    test('خطوط الاحتياط تغطّي السيريلية الموسّعة', () async {
      final PdfFontSet fonts = await PdfFontSet.load();
      // أوكرانية سيريلية (є، ї، ґ) وصربية/مقدونية (љ، њ، ћ، ѕ) — كلها خارج
      // الروسية الأساسية التي يغطيها خط الصينية.
      for (final int code in <int>[0x0454, 0x0457, 0x0491, 0x0459, 0x045A, 0x045B]) {
        expect(
          fonts.coversCodePoint(code),
          isTrue,
          reason: 'U+${code.toRadixString(16)} غير مغطّى في محرّك الـ PDF',
        );
      }
      // الحروف الروسية الأساسية تبقى مغطّاة أيضاً.
      expect(fonts.coversCodePoint(0x0410), isTrue);
    });

    test('النص الأوكراني/الصربي يُضمَّن فيه خط السيريلية المحزوم', () async {
      final String postScript = cyrillic.postScriptName ?? '';
      expect(postScript, isNotEmpty,
          reason: 'لا بد أن يحمل الخط اسماً داخلاً.');

      final PdfGeneratorService service = await PdfGeneratorService.create(
        compress: false,
        useIsolate: false,
      );
      final PdfGenerationReport report = await service.generate(
        document: TemplateDocument(
          elements: <TemplateElement>[
            TextElement(
              id: 't',
              box: const ElementBox(x: 40, y: 40, width: 500, height: 80),
              // أوكرانية (і، Ґ) وصربية/مقدونية (Љ، Ћ) — خارج الروسية الأساسية
              // التي يغطيها خط الصينية وحده.
              text: 'Привіт Ґанна Љуба Ћирилица',
            ),
          ],
        ),
      );
      final String raw = latin1.decode(report.bytes, allowInvalid: true);
      expect(
        raw,
        contains(postScript),
        reason: 'خط السيريلية «$postScript» اختفى من الـ PDF.',
      );
    });
  });
}
