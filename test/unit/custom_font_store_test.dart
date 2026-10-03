import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/fonts/custom_font_controller.dart';
import 'package:joodcraft/core/fonts/custom_font_face.dart';
import 'package:joodcraft/core/fonts/custom_font_store.dart';
import 'package:joodcraft/core/pdf/custom_pdf_fonts.dart';

/// إثبات استمرارية الخطوط (المرحلة 5 — البند 1):
/// الخط المرفوع يُحفظ في المخزن المحلي، ويُستعاد تلقائياً عند إعادة فتح التطبيق
/// (مخزن ومتحكّم جديدان تماماً) بلا أي شبكة.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Uint8List> fontBytes(String asset) async {
    final ByteData data = await rootBundle.load(asset);
    return data.buffer.asUint8List();
  }

  setUp(() {
    CustomPdfFonts.clear();
    // مخزن دائم حقيقي (SharedPreferences) محاكى في الذاكرة — نفس مسار
    // التشغيل الفعلي الذي يستدعيه `main()` قبل `runApp`.
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() => CustomPdfFonts.clear());

  group('SharedPreferencesCustomFontStore', () {
    test('حفظ ثم تحميل من مخزن جديد يعيد الأوجه كما هي', () async {
      final CustomFontFace face = CustomFontFace(
        family: CustomFontFace.familyKeyFor('خط الاختبار'),
        displayName: 'خط الاختبار',
        fileName: 'test.ttf',
        base64Data: 'AAECAwQFBgc=',
        weight: 700,
        addedAt: DateTime.utc(2026, 1, 2),
      );

      final CustomFontFace decoded = SharedPreferencesCustomFontStore
          .decodeFaces(
            SharedPreferencesCustomFontStore.encodeFaces(
              <CustomFontFace>[face],
            ),
          )
          .single;

      expect(decoded.family, face.family);
      expect(decoded.displayName, 'خط الاختبار');
      expect(decoded.weight, 700);
      expect(decoded.base64Data, face.base64Data);
    });

    test('المخزن الفعلي يقرأ ما كُتب فيه عبر نسخة مستقلة', () async {
      final SharedPreferencesCustomFontStore first =
          SharedPreferencesCustomFontStore();
      expect(await first.loadAll(), isEmpty);

      await first.saveAll(<CustomFontFace>[
        CustomFontFace(
          family: 'JoodCustom:حفظ',
          displayName: 'حفظ',
          fileName: 'h.ttf',
          base64Data: 'AAECAw==',
          addedAt: DateTime.utc(2026),
        ),
      ]);

      // نسخة جديدة تماماً (كأن العملية أعيد تشغيلها) تقرأ من المخزن نفسه.
      final SharedPreferencesCustomFontStore second =
          SharedPreferencesCustomFontStore();
      final List<CustomFontFace> loaded = await second.loadAll();
      expect(loaded.length, 1);
      expect(loaded.single.family, 'JoodCustom:حفظ');

      // حفظ قائمة فارغة يمسح المفتاح فلا يبقى سجل قديم.
      await second.saveAll(<CustomFontFace>[]);
      expect(await SharedPreferencesCustomFontStore().loadAll(), isEmpty);
    });

    test('لا يرمي على محتوى تالف ويعيد قائمة فارغة', () {
      expect(
        SharedPreferencesCustomFontStore.decodeFaces('{ليس JSON صالحاً'),
        isEmpty,
      );
      expect(
        SharedPreferencesCustomFontStore.decodeFaces('{"a":1}'),
        isEmpty,
      );
    });
  });

  test('الخط المرفوع يُستعاد تلقائياً من المخزن المحلي بعد إعادة فتح التطبيق',
      () async {
    // جلسة أولى: رفع خط فعلي عبر المتحكّم الحقيقي (يُحفظ محلياً فوراً).
    final CustomFontController first =
        CustomFontController(store: SharedPreferencesCustomFontStore());
    final CustomFontAddResult added = await first.addFont(
      fileName: 'Cairo-Regular.ttf',
      bytes: await fontBytes(AppAssets.pdfCairoRegular),
    );
    expect(added.face.arabicReady, isTrue);

    // إعادة تشغيل التطبيق: مخزن ومتحكّم جديدان، ومحرّك الطباعة فارغ.
    CustomPdfFonts.clear();
    final CustomFontController restarted =
        CustomFontController(store: SharedPreferencesCustomFontStore());
    expect(restarted.isEmpty, isTrue);

    await restarted.restore();

    // الخط عاد تلقائياً: في القائمة، وفي الواجهة، وفي محرّك الطباعة.
    expect(restarted.isRestored, isTrue);
    expect(restarted.families, contains(added.face.family));
    expect(restarted.isRegisteredWithUi(added.face.family), isTrue);
    expect(CustomPdfFonts.contains(added.face.family), isTrue);
    expect(CustomPdfFonts.resolve(added.face.family, 400), isNotNull);
  });
}
