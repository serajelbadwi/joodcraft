import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/fonts/custom_font_face.dart';
import 'package:joodcraft/core/fonts/font_inspector.dart';

/// خط "CFF" اصطناعي: ترويسة OTTO وجداول أساسية بلا `glyf`/`loca` — أي خط
/// ‎.otf بحدود PostScript لا يستطيع محرّك الطباعة رسمه.
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
    data.setUint32(record + 8, dataStart); // offset
    data.setUint32(record + 12, 4); // length
  }
  return bytes;
}

/// كل ملفات الخطوط المحزومة مع الاسم المتوقَّع داخلها.
const Map<String, String> _bundledFonts = <String, String>{
  AppAssets.pdfPlexRegular: 'IBM Plex Sans Arabic',
  AppAssets.pdfPlexSemiBold: 'IBM Plex Sans Arabic',
  AppAssets.pdfPlexBold: 'IBM Plex Sans Arabic',
  AppAssets.pdfAmiriRegular: 'Amiri',
  AppAssets.pdfAmiriBold: 'Amiri',
  AppAssets.pdfCairoRegular: 'Cairo',
  AppAssets.pdfCairoSemiBold: 'Cairo',
  AppAssets.pdfCairoBold: 'Cairo',
  AppAssets.pdfTajawalRegular: 'Tajawal',
  AppAssets.pdfTajawalMedium: 'Tajawal',
  AppAssets.pdfTajawalBold: 'Tajawal',
  AppAssets.pdfNotoArabicRegular: 'Noto Sans Arabic',
  AppAssets.pdfNotoArabicSemiBold: 'Noto Sans Arabic',
  AppAssets.pdfNotoArabicBold: 'Noto Sans Arabic',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('فحص ملفات الخطوط', () {
    test('كل خط محزوم يغطي صور الحروف العربية كاملة (117/117 + 8/8)', () async {
      expect(_bundledFonts.length, 14);

      for (final MapEntry<String, String> entry in _bundledFonts.entries) {
        final ByteData data = await rootBundle.load(entry.key);
        final FontInspection info =
            FontInspector.inspect(data.buffer.asUint8List());

        expect(info.isValid, isTrue, reason: '${entry.key}: ${info.errorAr}');
        expect(info.errorAr, isNull);
        expect(
          info.presentationForms.length,
          FontInspection.requiredPresentationFormCount,
          reason: 'تغطية صور الحروف ناقصة في ${entry.key}',
        );
        expect(
          info.lamAlefForms.length,
          FontInspection.requiredLamAlefFormCount,
          reason: 'صور لام-ألف ناقصة في ${entry.key}',
        );
        expect(info.supportsArabicPdf, isTrue, reason: entry.key);
        expect(info.arabicCoverageLabel, '117/117');
        expect(info.lamAlefCoverageLabel, '8/8');

        // الأسماء الداخلية صحيحة (تُشتق منها عائلة الخط المخصص).
        expect(info.familyName, entry.value, reason: entry.key);
        expect(info.unitsPerEm, isNotNull);
        expect(info.tables, containsAll(<String>['head', 'cmap', 'name']));
        // محيطات TrueType متاحة ⇒ يرسمها محرّك الطباعة بلا تشوّه.
        expect(info.hasTrueTypeOutlines, isTrue, reason: entry.key);
        expect(info.isPdfRenderable, isTrue, reason: entry.key);
      }
    });

    test('يميّز الأوزان من الاسم الداخلي', () async {
      Future<int> weightOf(String path) async {
        final ByteData data = await rootBundle.load(path);
        return FontInspector.inspect(data.buffer.asUint8List()).inferredWeight;
      }

      expect(await weightOf(AppAssets.pdfPlexRegular), 400);
      expect(await weightOf(AppAssets.pdfPlexSemiBold), 600);
      expect(await weightOf(AppAssets.pdfPlexBold), 700);
      expect(await weightOf(AppAssets.pdfTajawalBold), 700);
    });

    test('يميّز خط CFF/PostScript (.otf) بلا محيطات TrueType', () {
      final FontInspection cff = FontInspector.inspect(_fakeCffFont());
      expect(cff.isValid, isTrue);
      expect(cff.isOpenTypeCff, isTrue);
      expect(cff.hasTrueTypeOutlines, isFalse);
      expect(cff.isPdfRenderable, isFalse);
    });

    test('يرفض الملفات التي ليست خطاً', () {
      final FontInspection garbage =
          FontInspector.inspect(Uint8List.fromList(<int>[1, 2, 3]));
      expect(garbage.isValid, isFalse);
      expect(garbage.errorAr, isNotNull);

      final Uint8List fake = Uint8List(64);
      fake[0] = 0x50; // 'P'
      fake[1] = 0x4B; // 'K' — ترويسة ملف مضغوط لا خط.
      expect(FontInspector.inspect(fake).isValid, isFalse);

      // توقيع صحيح لكن جدول محتويات فارغ.
      final Uint8List headerOnly = Uint8List(32);
      headerOnly[3] = 1; // 0x00010000
      expect(FontInspector.inspect(headerOnly).isValid, isFalse);
    });
  });

  group('أسماء الخطوط المخصصة', () {
    test('يستخرج اسم العرض من اسم الملف ويحذف كلمة الوزن', () {
      expect(
        CustomFontFace.displayNameFromFileName('Cairo-Bold.ttf'),
        'Cairo',
      );
      expect(
        CustomFontFace.displayNameFromFileName('NotoSansArabic_SemiBold.otf'),
        'NotoSansArabic',
      );
      expect(
        CustomFontFace.displayNameFromFileName('خط-الشركة.otf'),
        'خط الشركة',
      );
    });

    test('مفتاح العائلة يمنع الاصطدام مع الخطوط المضمّنة', () {
      final String key = CustomFontFace.familyKeyFor('Cairo');
      expect(key, startsWith(CustomFontFace.familyPrefix));
      expect(key, isNot(AppAssets.cairoFont));
      expect(CustomFontFace.familyKeyFor(' Cairo '), key);
    });

    test('دورة JSON كاملة بلا فقد', () {
      final CustomFontFace face = CustomFontFace(
        family: CustomFontFace.familyKeyFor('Cairo'),
        displayName: 'Cairo',
        fileName: 'Cairo-Bold.ttf',
        base64Data: 'AAECAw==',
        weight: 700,
        arabicReady: true,
        addedAt: DateTime.utc(2026, 2, 3, 4, 5, 6),
      );
      final CustomFontFace? back = CustomFontFace.fromJson(face.toJson());
      expect(back, isNotNull);
      expect(back!.family, face.family);
      expect(back.displayName, 'Cairo');
      expect(back.weight, 700);
      expect(back.bytes, Uint8List.fromList(<int>[0, 1, 2, 3]));
      expect(back.addedAt, face.addedAt);
      expect(back.weightLabelAr, 'عريض');
    });

    test('يتجاهل السجلات التالفة بلا رمي', () {
      expect(CustomFontFace.fromJson(null), isNull);
      expect(CustomFontFace.fromJson('نص'), isNull);
      expect(CustomFontFace.fromJson(<String, dynamic>{}), isNull);
      expect(
        CustomFontFace.fromJson(<String, dynamic>{'family': 'x'}),
        isNull,
      );
      expect(
        CustomFontFace.fromJson(<String, dynamic>{'family': 'x', 'data': ''}),
        isNull,
      );
    });
  });
}
