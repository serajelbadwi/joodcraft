import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/errors/app_exception.dart';
import 'package:joodcraft/core/fonts/custom_font_controller.dart';
import 'package:joodcraft/core/fonts/custom_font_face.dart';
import 'package:joodcraft/core/fonts/custom_font_store.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/pdf/custom_pdf_fonts.dart';
import 'package:joodcraft/core/services/pdf_generator_service.dart';

Future<Uint8List> _fontBytes(String asset) async {
  final ByteData data = await rootBundle.load(asset);
  return data.buffer.asUint8List();
}

/// خط CFF اصطناعي (ترويسة OTTO بلا `glyf`/`loca`) — يمثّل ملفات .otf التي
/// لا يستطيع محرّك الطباعة رسم محيطاتها.
Uint8List _fakeCffFont() {
  const int numTables = 6;
  const List<String> tags = <String>['head', 'cmap', 'name', 'hhea', 'hmtx', 'maxp'];
  const int dirStart = 12;
  const int dataStart = dirStart + numTables * 16;
  final Uint8List bytes = Uint8List(dataStart + 32);
  final ByteData data = ByteData.sublistView(bytes);
  data.setUint32(0, 0x4F54544F); // 'OTTO'
  data.setUint16(4, numTables);
  for (int i = 0; i < numTables; i++) {
    final int record = dirStart + i * 16;
    for (int c = 0; c < 4; c++) {
      bytes[record + c] = tags[i].codeUnitAt(c);
    }
    data.setUint32(record + 8, dataStart);
    data.setUint32(record + 12, 4);
  }
  return bytes;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryCustomFontStore store;
  late CustomFontController controller;

  setUp(() {
    CustomPdfFonts.clear();
    store = InMemoryCustomFontStore();
    controller = CustomFontController(store: store);
    CustomFontController.instance = controller;
  });

  tearDown(() => CustomPdfFonts.clear());

  group('إضافة خط مخصص', () {
    test('يُسجّل الخط في المحرّك ويُحفظ محلياً فوراً', () async {
      final Uint8List bytes = await _fontBytes(AppAssets.pdfTajawalBold);

      final CustomFontAddResult result = await controller.addFont(
        fileName: 'Tajawal-Bold.ttf',
        bytes: bytes,
      );

      expect(result.replaced, isFalse);
      expect(result.face.displayName, 'Tajawal');
      expect(result.face.weight, 700);
      expect(result.face.arabicReady, isTrue);
      expect(result.warningsAr, isEmpty);
      expect(result.inspection.supportsArabicPdf, isTrue);

      final String family = CustomFontFace.familyKeyFor('Tajawal');
      expect(result.face.family, family);
      expect(CustomPdfFonts.contains(family), isTrue);
      expect(CustomPdfFonts.resolve(family, 700), isNotNull);

      // محفوظ محلياً (بلاه أي شبكة) ويمكن استرجاعه.
      expect(store.faces.length, 1);
      expect(controller.faces.length, 1);
      expect(controller.families, <String>[family]);
      expect(controller.totalBytes, greaterThan(1000));
      expect(controller.displayNameOf(family), 'Tajawal');
    });

    test('أوزان العائلة نفسها تُجمَع تحت عائلة واحدة', () async {
      await controller.addFont(
        fileName: 'Tajawal-Regular.ttf',
        bytes: await _fontBytes(AppAssets.pdfTajawalRegular),
      );
      final CustomFontAddResult bold = await controller.addFont(
        fileName: 'Tajawal-Bold.ttf',
        bytes: await _fontBytes(AppAssets.pdfTajawalBold),
      );

      expect(CustomPdfFonts.familyCount, 1);
      expect(controller.families.length, 1);
      expect(controller.faces.length, 2);
      expect(CustomPdfFonts.variantsOf(bold.face.family),
          containsAll(<String>['regular', 'bold']));
    });

    test('إعادة رفع الوجه نفسه تستبدله ولا تُكرّره', () async {
      final Uint8List bytes = await _fontBytes(AppAssets.pdfCairoRegular);
      await controller.addFont(fileName: 'Cairo-Regular.ttf', bytes: bytes);
      final CustomFontAddResult again = await controller.addFont(
        fileName: 'Cairo-Regular.ttf',
        bytes: bytes,
      );
      expect(again.replaced, isTrue);
      expect(controller.faces.length, 1);
      expect(store.faces.length, 1);
    });

    test('يرفض ما ليس ملف خط برسالة عربية واضحة', () async {
      await expectLater(
        controller.addFont(
          fileName: 'logo.png',
          bytes: Uint8List.fromList(<int>[0x89, 0x50, 0x4E, 0x47, 0, 0, 0, 0]),
        ),
        throwsA(isA<AppException>()),
      );
      expect(controller.isEmpty, isTrue);
      expect(CustomPdfFonts.familyCount, 0);
    });

    test('يرفض خط CFF/PostScript (‎.otf) برسالة عربية واضحة', () async {
      await expectLater(
        controller.addFont(
          fileName: 'Amiri.otf',
          bytes: _fakeCffFont(),
        ),
        throwsA(
          isA<AppException>().having(
            (AppException e) => e.message,
            'message',
            allOf(contains('CFF'), contains('.ttf')),
          ),
        ),
      );
      expect(controller.isEmpty, isTrue);
      expect(CustomPdfFonts.familyCount, 0);
    });

    test('يرفض الملفات الأكبر من الحد المسموح', () async {
      final CustomFontController small = CustomFontController(
        store: InMemoryCustomFontStore(),
        maxBytes: 1024,
      );
      await expectLater(
        small.addFont(
          fileName: 'Big.ttf',
          bytes: Uint8List(4096),
        ),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('الاستعادة والحذف', () {
    test('يستعيد الخطوط عند بدء التشغيل ويعيد تسجيلها', () async {
      await controller.addFont(
        fileName: 'Amiri-Bold.ttf',
        bytes: await _fontBytes(AppAssets.pdfAmiriBold),
      );

      // جلسة جديدة تماماً على المخزن نفسه (كما بعد إعادة تشغيل التطبيق).
      CustomPdfFonts.clear();
      final CustomFontController fresh =
          CustomFontController(store: InMemoryCustomFontStore(store.faces));
      expect(fresh.isRestored, isFalse);

      await fresh.restore();
      expect(fresh.isRestored, isTrue);
      expect(fresh.faces.length, 1);
      expect(CustomPdfFonts.contains(fresh.faces.first.family), isTrue);
      expect(CustomPdfFonts.resolve(fresh.faces.first.family, 700), isNotNull);
    });

    test('يُستعاد الخط المخصص تلقائياً من المخزن الدائم بعد إعادة التشغيل',
        () async {
      // مخزن دائم حقيقي (SharedPreferences) محاكى في الذاكرة — نفس مسار
      // التشغيل الفعلي في `main()` الذي يستدعي الاستعادة قبل `runApp`.
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final CustomFontController first =
          CustomFontController(store: SharedPreferencesCustomFontStore());

      final CustomFontAddResult added = await first.addFont(
        fileName: 'Amiri-Regular.ttf',
        bytes: await _fontBytes(AppAssets.pdfAmiriBold),
      );

      // محاكاة إعادة تشغيل التطبيق: مخزن ومتحكّم جديدان تماماً، ثم الاستعادة
      // التلقائية نفسها التي ينفّذها `main()`.
      CustomPdfFonts.clear();
      final CustomFontController restarted =
          CustomFontController(store: SharedPreferencesCustomFontStore());
      expect(restarted.isEmpty, isTrue);

      await restarted.restore();

      expect(restarted.faces.length, 1);
      expect(restarted.families, contains(added.face.family));
      expect(CustomPdfFonts.contains(added.face.family), isTrue);
      expect(CustomPdfFonts.resolve(added.face.family, 700), isNotNull);
      expect(restarted.isRegisteredWithUi(added.face.family), isTrue);
    });

    test('لا ترمي الاستعادة عند وجود سجل تالف', () async {
      final InMemoryCustomFontStore broken = InMemoryCustomFontStore();
      await broken.saveAll(<CustomFontFace>[
        CustomFontFace(
          family: 'JoodCustom:Torn',
          displayName: 'Torn',
          fileName: 'torn.ttf',
          base64Data: 'AAECAw==',
          addedAt: DateTime.utc(2026),
        ),
      ]);
      final CustomFontController c = CustomFontController(store: broken);
      await c.restore();
      expect(c.isEmpty, isTrue);
    });

    test('الحذف يمنع الرسم بالخط فوراً ويُفرغ المخزن', () async {
      final CustomFontAddResult added = await controller.addFont(
        fileName: 'Cairo-Regular.ttf',
        bytes: await _fontBytes(AppAssets.pdfCairoRegular),
      );
      await controller.removeFont(added.face.family);
      expect(controller.isEmpty, isTrue);
      expect(CustomPdfFonts.contains(added.face.family), isFalse);
      expect(store.faces, isEmpty);
    });
  });

  group('التكامل مع محرّك الطباعة', () {
    late PdfGeneratorService service;

    setUpAll(() async {
      service = await PdfGeneratorService.create(compress: false);
    });

    TemplateDocument docWith({required String? customFont}) {
      return TemplateDocument.fromJson(<String, dynamic>{
        'schema_version': 1,
        'orientation': 'portrait',
        'elements': <Map<String, dynamic>>[
          <String, dynamic>{
            'type': 'text',
            'x': 20,
            'y': 20,
            'w': 500,
            'h': 60,
            'text': 'نص بالخط المخصص',
            'size': 24,
            'font_custom': ?customFont,
          },
        ],
      });
    }

    String probe(Uint8List bytes) =>
        latin1.decode(bytes, allowInvalid: true);

    test('يُرسم الخط المخصص ويُضمَّن في ملف الـ PDF', () async {
      final CustomFontAddResult added = await controller.addFont(
        fileName: 'Tajawal-Bold.ttf',
        bytes: await _fontBytes(AppAssets.pdfTajawalBold),
      );

      final TemplateDocument document =
          docWith(customFont: added.face.family);
      expect(
        (document.elements.first as TextElement).customFont,
        added.face.family,
      );

      final PdfGenerationReport report =
          await service.generate(document: document);
      final String text = probe(report.bytes);
      expect(text, contains('Tajawal'));
      expect(text, isNot(contains('IBMPlexSansArabic')));
    });

    test('قالب يشير لخط مخصص غير مسجَّل يرجع للخط المضمّن بلا فشل', () async {
      final PdfGenerationReport report = await service.generate(
        document: docWith(customFont: CustomFontFace.familyKeyFor('خط محذوف')),
      );
      final String text = probe(report.bytes);
      expect(text, contains('IBMPlexSansArabic'));
    });
  });
}
