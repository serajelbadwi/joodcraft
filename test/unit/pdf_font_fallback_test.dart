import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/fonts/custom_font_controller.dart';
import 'package:joodcraft/core/fonts/custom_font_store.dart';
import 'package:joodcraft/core/fonts/font_inspector.dart';
import 'package:joodcraft/core/fonts/windows_system_font_service.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/pdf/pdf_font_catalog.dart';
import 'package:joodcraft/core/services/pdf_generator_service.dart';

/// اختبارات خط الاحتياط العالمي في الطباعة: تغطية السيريلية/الصينية، واختيار
/// الخط حسب كتابة النص (التركية تبقى على خطها اللاتيني ولا تُنتقل لعائلة
/// عربية)، وتمرير خطوط النظام إلى تصدير الدُفعات.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PdfFontSet fonts;

  setUpAll(() async {
    fonts = await PdfFontSet.load();
  });

  test('خط الاحتياط يغطّي السيريلية والصينية والتركية الممتدة', () {
    expect(fonts.coversCodePoint(0x430), isTrue, reason: 'السيريلية а');
    expect(fonts.coversCodePoint(0x410), isTrue, reason: 'السيريلية А');
    expect(fonts.coversCodePoint(0x6587), isTrue, reason: 'الصينية 文');
    expect(fonts.coversCodePoint(0x011F), isTrue, reason: 'التركية ğ');
    expect(fonts.coversCodePoint(0xFBAE), isTrue, reason: 'الأوردو ے');
  });

  test('اختيار الخط حسب الكتابة يحترم الاختيار إن كان يغطّي النص', () {
    // نص لاتيني خالص: يُحترم الاختيار كما هو.
    expect(
      fonts.familyForText('Hello world', preferred: PdfFontFamily.plex),
      PdfFontFamily.plex,
    );
    // خط يغطّي النص التركي الممتد يُحترم كما هو.
    expect(
      fonts.familyForText('ğ ş İ ç', preferred: PdfFontFamily.cairo),
      PdfFontFamily.cairo,
    );
    // النص التركي الممتد لاتيني: يبقى على خطه المختار (Plex) ولا يُنتقل إلى
    // عائلة عربية؛ المحارف الممتدة يرسمها خط الاحتياط اللاتيني (Noto Sans).
    final PdfFontFamily chosen =
        fonts.familyForText('ğ ş İ ç', preferred: PdfFontFamily.plex);
    expect(chosen, PdfFontFamily.plex);
  });

  Future<String> generateRaw(String text) async {
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
            text: text,
          ),
        ],
      ),
    );
    return latin1.decode(report.bytes, allowInvalid: true);
  }

  test('النص التركي الممتد يُرسم بخط الاحتياط اللاتيني (Noto Sans) لا بخط عربي',
      () async {
    final String postScript = FontInspector.inspect(
      (await rootBundle.load(AppAssets.notoCyrillicFontFile))
          .buffer
          .asUint8List(),
    ).postScriptName ??
        '';
    expect(postScript, isNotEmpty, reason: 'لا بد أن يحمل الخط اسماً داخلاً.');

    final String raw = await generateRaw('Türkçe ğ ş İ ı ö ü ç');
    expect(
      raw,
      contains(postScript),
      reason: 'خط الاحتياط اللاتيني «$postScript» اختفى من الـ PDF التركي.',
    );
  });

  test('النص الروسي يُضمَّن فيه خط الاحتياط المحزوم (Noto Sans)', () async {
    // خط Noto Sans (اللاتيني/السيريلي) يتقدّم الآن سلاسل الاحتياط، فيرسم
    // السيريلية بأسلوبها الصحيح بدل خط الصينية الذي يملك الروسية الأساسية فقط.
    final String postScript = FontInspector.inspect(
      (await rootBundle.load(AppAssets.notoCyrillicFontFile))
          .buffer
          .asUint8List(),
    ).postScriptName ??
        '';
    expect(postScript, isNotEmpty, reason: 'لا بد أن يحمل الخط اسماً داخلاً.');

    final String raw = await generateRaw('Привет мир');
    expect(raw, contains(postScript));
  });

  test('تصدير الدُفعات يضمّن خط النظام المختار (isolate)', () async {
    // نجبر المنصة على ويندوز لتفعيل اكتشاف خطوط النظام (الافتراضي في الاختبارات
    // أندرويد). على جهاز غير ويندوز يتخطّى الاختبار بأمان.
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    if (!Platform.isWindows) return;
    final WindowsFontDiscoveryResult discovery =
        await WindowsSystemFontService.discover();
    final WindowsSystemFontFamily target = discovery.families.firstWhere(
      (WindowsSystemFontFamily f) =>
          f.filePaths.any((String p) => p.toLowerCase().endsWith('.ttf')),
      orElse: () => const WindowsSystemFontFamily(
        displayName: '',
        filePaths: <String>[],
      ),
    );
    if (target.displayName.isEmpty) return; // لا خط TrueType متاح — تخطّ.

    final ByteData? data =
        await WindowsSystemFontService.readFontBytes(target.filePaths.first);
    if (data == null) return;
    final Uint8List bytes = data.buffer
        .asUint8List(data.offsetInBytes, data.lengthInBytes);
    final String? postScript = FontInspector.inspect(bytes).postScriptName;
    if (postScript == null || postScript.isEmpty) return;

    final CustomFontController store =
        CustomFontController(store: InMemoryCustomFontStore());
    CustomFontController.instance = store;

    // تصدير جماعي (isolate) بصفّين ليُفعَّل مسار الخلفية.
    final PdfGeneratorService service = await PdfGeneratorService.create(
      compress: false,
      useIsolate: true,
      isolateThreshold: 1,
    );
    final PdfGenerationReport report = await service.generateBatch(
      document: TemplateDocument(
        elements: <TemplateElement>[
          TextElement(
            id: 't',
            box: const ElementBox(x: 40, y: 40, width: 500, height: 80),
            text: 'System font sample',
            customFont: target.displayName,
          ),
        ],
      ),
      rows: const <Map<String, String>>[
        <String, String>{'a': '1'},
        <String, String>{'a': '2'},
      ],
    );

    final String raw = latin1.decode(report.bytes, allowInvalid: true);
    expect(
      raw,
      contains(postScript),
      reason: 'خط النظام «${target.displayName}» اختفى من تصدير الدُفعات.',
    );
  }, timeout: const Timeout(Duration(minutes: 2)));
}
