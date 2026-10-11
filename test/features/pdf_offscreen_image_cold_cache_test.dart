import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/pdf/offscreen_widget_renderer.dart';

/// اختبار رجعية لـ[OffscreenWidgetRenderer]: كل صفحة تصدير تحمل صورها.
///
/// الحادثة القديمة: «الشهادة الأولى بلا لوجو ولا توقيع»، والثانيات سليمة.
/// السبب الجذري أن `BuildOwner` كان يُبنى بلا `onBuildScheduled`، فلا يُعاد
/// بناء عنصر `Image` الذي تصل صورته من محرّك الرسم بعد الشجرة التي بُنيت
/// مرة واحدة — و`await 100ms` لا يحلّ ذلك لأن المشكلة **غياب إعادة البناء
/// لا توقيت**. ولهذا تظهر الحادثة في «الأولى» تحديداً: `imageCache` عامّة
/// بين الصفحات، فالأولى تكون باردة والثانيات دافئة.
///
/// يقيس هذا الاختبار ذلك **حتمياً** بمسح الذاكرة قبل كل تصدير، فلا يمكن أن
/// تخدعه إعادة استخدام الذاكرة بين الصفحات.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// يمسح الذاكرة العامة كي يكون كل تصدير «صفحة أولى» فعلاً.
  void goCold() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  /// PNG صلب 32×32 بلون أحمر صريح (`#FFFF0000`)، معقّد Base64ً خاماً —
  /// بنفس صيغة [ImageSourceKind.dataUri] التي يقرأها [AssetImageCache].
  Future<String> solidRedPngBase64() async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, 32, 32),
      ui.Paint()..color = const ui.Color(0xFFFF0000),
    );
    final ui.Image source = await recorder.endRecording().toImage(32, 32);
    final ByteData? png = await source.toByteData(
      format: ui.ImageByteFormat.png,
    );
    source.dispose();
    return base64Encode(png!.buffer.asUint8List());
  }

  /// القالب المُختبَر: صورة «لوجو» بلون أحمر صريح + سطر نصّ.
  ///
  /// اللوجو يحتلّ صندوقاً معلوماً في اللحظة الهرمية، فيُبثّت على بكسلات
  /// محسوبة في الصورة الناتجة.
  Future<TemplateDocument> certificateWithLogo() async => TemplateDocument(
    canvasWidth: 400,
    canvasHeight: 300,
    dpi: 96,
    elements: <TemplateElement>[
      ImageElement(
        id: 'logo',
        box: const ElementBox(x: 40, y: 40, width: 120, height: 120),
        sourceKind: ImageSourceKind.dataUri,
        path: await solidRedPngBase64(),
        fit: ImageFit.fill,
      ),
      TextElement(
        id: 'director',
        box: const ElementBox(x: 40, y: 200, width: 320, height: 40),
        text: 'مدير المدرسة',
        fontSize: 18,
      ),
    ],
  );

  /// البكسلات الخام للّقطة، ومعها أبعادها.
  Future<(Uint8List, int, int)> rawPixels(Uint8List pngBytes) async {
    final ui.Image decoded = await decodeImageFromList(pngBytes);
    final int w = decoded.width;
    final int h = decoded.height;
    final ByteData? raw = await decoded.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    decoded.dispose();
    return (raw!.buffer.asUint8List(), w, h);
  }

  /// هل البكسل عند (x، y) أحمر صريح؟
  bool isRed(Uint8List px, int width, int x, int y) {
    final int i = (y * width + x) * 4;
    return px[i] > 240 && px[i + 1] < 20 && px[i + 2] < 20;
  }

  /// هل البكسل عند (x، y) أبيض تقريباً؟
  bool isWhite(Uint8List px, int width, int x, int y) {
    final int i = (y * width + x) * 4;
    return px[i] > 245 && px[i + 1] > 245 && px[i + 2] > 245;
  }

  test('الشهادة تحمل صورتها حتى والذاكرة باردة تماماً', () async {
    final TemplateDocument doc = await certificateWithLogo();

    goCold();
    final Uint8List bytes = await OffscreenWidgetRenderer
        .renderDocumentToImageBytes(doc);
    final (Uint8List px, int w, int h) = await rawPixels(bytes);

    // 400×300 منطقيًّا، ومعدّل لا يقلّ عن 2.0 ⇒ اللقطة 800×600 على الأقل.
    expect(w, greaterThanOrEqualTo(800), reason: 'عرض اللقطة');
    expect(h, greaterThanOrEqualTo(600), reason: 'ارتفاع اللقطة');

    // الصندوق الحومي للّوجو: (40,40) بطول 120 ⇒ مركزه (100,100) منطقيًّا.
    final int cx = (100 * w) ~/ 400;
    final int cy = (100 * h) ~/ 300;
    expect(
      isRed(px, w, cx, cy),
      isTrue,
      reason:
          'قلب الصورة في اللقطة يجب أن يكون أحمر — إذا كان أبيض فقد خرج '
          'اللوجو غائباً كما في العطل القديم (ذاكرة باردة بلا إعادة بناء).',
    );
  });

  test('تحكّم سلبي: نقطة بلا عنصر تبقى بيضاء فالقياس لا يخدع', () async {
    final TemplateDocument doc = await certificateWithLogo();

    goCold();
    final Uint8List bytes = await OffscreenWidgetRenderer
        .renderDocumentToImageBytes(doc);
    final (Uint8List px, int w, int h) = await rawPixels(bytes);

    // نقطة بلا عنصر: (350, 280) منطقيًّا — خارج كل صندوق.
    final int blankX = (350 * w) ~/ 400;
    final int blankY = (280 * h) ~/ 300;
    expect(
      isWhite(px, w, blankX, blankY),
      isTrue,
      reason: 'الخلفية بلا عنصر يجب أن تبقى بيضاء — وإلا فقراءة البكسل خاطئة.',
    );

    // وينبغي أن تبقى بيضاء **أيضاً** عند إفراغ الصندوق: يثبت أن أحمر الصورة
    // مصدره صورة العنصر لا مزج عامّ في الصورة كلها.
    final int insideBoxBlank = (300 * w) ~/ 400;
    expect(
      isWhite(px, w, insideBoxBlank, (100 * h) ~/ 300),
      isTrue,
      reason: 'يمين صندوق اللوجو فراغ — فالخلفية بيضاء داخله أيضاً.',
    );
    expect(isWhite(px, w, blankX, blankY), isTrue);
  });

  test('ثلاث صفحات متتالية بذاكرة باردة: الصورة في الثلاث', () async {
    final TemplateDocument doc = await certificateWithLogo();

    final List<int> logoByteCounts = <int>[];

    // «الأولى» باردة دائماً، و«الثانيات» دافئة في التطبيق — هنا نُجبر الثلاث
    // على أن تكون أولى، فلا تفيد إعادة استخدام الذاكرة في إخفاء العطل.
    for (int page = 0; page < 3; page++) {
      goCold();
      final Uint8List bytes = await OffscreenWidgetRenderer
          .renderDocumentToImageBytes(doc);
      final (Uint8List px, int w, int h) = await rawPixels(bytes);

      final int cx = (100 * w) ~/ 400;
      final int cy = (100 * h) ~/ 300;
      expect(
        isRed(px, w, cx, cy),
        isTrue,
        reason: 'الصفحة ${page + 1}: الصورة غائبة رغم أن الذاكرة مسحوبة.',
      );

      // عدّ البكسلات الحمراء داخل صندوق اللوجو — يقيس «كم من الصورة رُسم».
      int red = 0;
      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          if (isRed(px, w, x, y)) red++;
        }
      }
      logoByteCounts.add(red);
    }

    // لا يكفي أن تظهر بقعة واحدة: يجب أن يكون حجمها نفسه في الثلاث صفحات،
    // وإلا فبعضها رُسم ناقصاً.
    expect(logoByteCounts[1], logoByteCounts[0], reason: 'الصفحة 2 ≠ 1');
    expect(logoByteCounts[2], logoByteCounts[0], reason: 'الصفحة 3 ≠ 1');
    expect(
      logoByteCounts[0],
      greaterThan(100 * 100),
      reason: 'صورة 120×120 منطقية لا بدّ أن تغطّي أكثر من 100×100 بكسل.',
    );
  });
}
