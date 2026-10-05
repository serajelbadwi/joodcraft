import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/pdf/pdf_font_catalog.dart';

/// حرس التسخين المسبق: يجب أن يُحضّر الخطوط المحزومة في الخلفية، وأن يبقى آمنًا
/// (لا يرمي) إن تعذّرت قراءة الأصول.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(PdfFontSet.resetCache);
  tearDown(PdfFontSet.resetCache);

  test('warmUp يُحضّر الخطوط فتصبح متاحة فوراً وتُخزَّن مؤقتاً', () async {
    await PdfFontSet.warmUp();

    final PdfFontSet first = await PdfFontSet.loadCached();
    final PdfFontSet second = await PdfFontSet.loadCached();
    // نفس المجموعة المخزّنة (لا إعادة تحميل).
    expect(identical(first, second), isTrue);
    expect(first.loadedCount, greaterThan(0));
  });

  test('التغطية المحسوبة في isolate خلفي صحيحة', () async {
    final PdfFontSet fonts = await PdfFontSet.load();

    expect(fonts.coversCodePoint(0x430), isTrue, reason: 'السيريلية а');
    expect(fonts.coversCodePoint(0x6587), isTrue, reason: 'الصينية 文');
    expect(fonts.coversCodePoint(0x011F), isTrue, reason: 'التركية ğ');
    // النص التركي لاتيني ممتد: يبقى على عائلته (Plex) ولا يُنتقل لعائلة عربية.
    expect(
      fonts.familyForText('ğ ş İ', preferred: PdfFontFamily.plex),
      PdfFontFamily.plex,
    );
  });

  test('warmUp لا يرمي عند فشل قراءة الأصول', () async {
    // يجب ألا ينكسر الإقلاع إن تعذّر تحميل الخطوط.
    await PdfFontSet.warmUp(bundle: _ThrowingBundle());
  });
}

/// حزمة أصول فاشلة لمحاكاة تعذّر قراءة الخطوط المحزومة.
class _ThrowingBundle extends AssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      throw StateError('أصول غير متاحة في هذا الاختبار');

  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      throw StateError('أصول غير متاحة في هذا الاختبار');
}
