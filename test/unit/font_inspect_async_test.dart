import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/fonts/font_inspector.dart';

/// اختبار التحليل غير الحاجز: يجب أن يطابق التحليل المتزامن تماماً، سواء جرى
/// على الخيط الحالي (خط صغير) أو في isolate خلفي (خط ثقيل).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('inspectAsync يطابق inspect للخط الصغير (مسار الخيط الحالي)', () async {
    final Uint8List bytes =
        (await rootBundle.load(AppAssets.pdfCairoRegular)).buffer.asUint8List();
    expect(bytes.lengthInBytes,
        lessThan(FontInspector.heavyFontThresholdBytes));

    final FontInspection sync = FontInspector.inspect(bytes);
    final FontInspection async = await FontInspector.inspectAsync(bytes);

    expect(async.isValid, sync.isValid);
    expect(async.codePoints, sync.codePoints);
    expect(async.postScriptName, sync.postScriptName);
  });

  test('inspectAsync يطابق inspect للخط الثقيل (مسار isolate)', () async {
    final Uint8List bytes =
        (await rootBundle.load(AppAssets.notoScFontFile)).buffer.asUint8List();
    expect(bytes.lengthInBytes,
        greaterThanOrEqualTo(FontInspector.heavyFontThresholdBytes));

    final FontInspection sync = FontInspector.inspect(bytes);
    final FontInspection async = await FontInspector.inspectAsync(bytes);

    expect(async.isValid, sync.isValid);
    expect(async.codePoints, sync.codePoints);
    expect(async.postScriptName, sync.postScriptName);
  });
}
