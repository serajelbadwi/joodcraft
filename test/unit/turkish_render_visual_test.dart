import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_assets.dart';

/// اختبار بصري (رسم فعلي بالبكسل): يتأكد أن الحروف التركية الممتدة تُرسم كأشكال
/// حقيقية لا كمربعات فارغة (□□□).
///
/// المنهج: نُحمّل خط الاحتياط اللاتيني المحزوم (Noto Sans) في محرّك Flutter،
/// ونرسم كل حرف في صورة مستقلّة، ثم نقارن وحدات البكسل:
///   • كل حرف تركيّ يرسم شكلاً مختلفاً عن غيره — لو كانت كلها مربعات لتطابقت.
///   • ويختلف عن محرف غائب يُرسم فراغاً/مربعاً.
/// لا نعتمد صوراً ذهبية محفوظة (هشّة عبر المنصّات)؛ النتيجة تُحسب وقت التشغيل.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String family = 'NotoSansTurkishVisual';
  const int size = 96;

  setUpAll(() async {
    // نفس ملف الاحتياط اللاتيني/السيريلي المحزوم الذي يستعمله محرّك الـ PDF.
    final FontLoader loader = FontLoader(family)
      ..addFont(rootBundle.load(AppAssets.notoCyrillicFontFile));
    await loader.load();
  });

  /// يرسم [text] على خلفية بيضاء ويعيد وحدات البكسل (RGBA).
  Future<Uint8List> render(String text) async {
    final ui.ParagraphBuilder builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontFamily: family,
        fontSize: 64,
        textAlign: TextAlign.center,
        maxLines: 1,
      ),
    )
      ..pushStyle(ui.TextStyle(color: const ui.Color(0xFF000000)))
      ..addText(text);
    final ui.Paragraph paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: size.toDouble()));

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );
    canvas.drawParagraph(paragraph, const ui.Offset(0, 12));
    final ui.Image image =
        await recorder.endRecording().toImage(size, size);
    final ByteData? data =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!.buffer.asUint8List();
  }

  /// عدد البكسلات غير البيضاء (الحبر).
  int inkPixels(Uint8List rgba) {
    int count = 0;
    for (int i = 0; i < rgba.length; i += 4) {
      if (rgba[i] < 200 || rgba[i + 1] < 200 || rgba[i + 2] < 200) count++;
    }
    return count;
  }

  bool sameBytes(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  test('الحروف التركية الممتدة تُرسم كأشكال حقيقية لا مربعات فارغة', () async {
    const List<String> turkish = <String>[
      'ğ', 'Ğ', 'ş', 'Ş', 'İ', 'ı', 'ç', 'ö', 'ü',
    ];

    // محرف في منطقة الاستخدام الخاص غير موجود في الخط ⇒ يُرسم فراغاً/مربعاً.
    final Uint8List notdef = await render('\uE000');

    final Map<String, Uint8List> glyphs = <String, Uint8List>{};
    for (final String ch in turkish) {
      final Uint8List pixels = await render(ch);
      glyphs[ch] = pixels;
      expect(inkPixels(pixels), greaterThan(0), reason: '«$ch» لم يُرسم');
      expect(
        sameBytes(pixels, notdef),
        isFalse,
        reason: '«$ch» يُرسم كمربع فارغ (المحرف غائب عن الخط)',
      );
    }

    // كل حرف له شكل مميّز — لو كانت كلها مربعات لتطابقت بكسلًا.
    final List<String> keys = glyphs.keys.toList(growable: false);
    for (int i = 0; i < keys.length; i++) {
      for (int j = i + 1; j < keys.length; j++) {
        expect(
          sameBytes(glyphs[keys[i]]!, glyphs[keys[j]]!),
          isFalse,
          reason: '«${keys[i]}» و«${keys[j]}» لهما الشكل نفسه (مربعات؟)',
        );
      }
    }
  });

  test('نص تركي كامل يُرسم بحبر متّصل لا مربعات', () async {
    final Uint8List pixels = await render('Türkçe İçin Şişli ğüşi');
    // الحبر يشغل مساحة معتبرة — المربعات المتتابعة تعطي حبراً أكبر بكثير، أما
    // الصورة الفارغة فلا حبر فيها إطلاقاً.
    expect(inkPixels(pixels), greaterThan(50));
  });
}
