import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/editor/widgets/custom_font_panel.dart';
import 'package:joodcraft/core/editor/widgets/element_view.dart';
import 'package:joodcraft/core/fonts/custom_font_controller.dart';
import 'package:joodcraft/core/fonts/custom_font_face.dart';
import 'package:joodcraft/core/fonts/custom_font_store.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/pdf/custom_pdf_fonts.dart';
import 'package:joodcraft/core/pdf/pdf_font_catalog.dart';
import 'package:joodcraft/core/services/pdf_generator_service.dart';
import 'package:joodcraft/core/theme/app_theme.dart';

// ignore: depend_on_referenced_packages
import 'package:cross_file/cross_file.dart';

/// رحلة الخط المخصص كاملة كما يراها المستخدم:
/// رفع (منتقي الملفات) ← تسجيل (FontLoader + محرّك الطباعة) ← ظهور فوري في
/// المحرر وقائمة الخطوط ← تضمينه في ملف الـ PDF. كل ذلك بلا شبكة.
///
/// نُحاكي منتقي الملفات على مستوى واجهة المنصّة (`FilePickerPlatform`) لا على
/// مستوى زر الواجهة، فيمرّ الاختبار عبر دالة الرفع الحقيقية `uploadCustomFonts`
/// ويصطدم بنفس المسار الذي يصطدم به المستخدم.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryCustomFontStore store;
  late CustomFontController controller;
  late Uint8List notoBoldBytes;
  late String notoFamily;

  setUpAll(() async {
    final ByteData data = await rootBundle.load(AppAssets.pdfNotoArabicBold);
    notoBoldBytes = data.buffer.asUint8List();
  });

  setUp(() {
    CustomPdfFonts.clear();
    store = InMemoryCustomFontStore();
    controller = CustomFontController(store: store);
    CustomFontController.instance = controller;
    // اسم العائلة مشتق من الاسم الداخلي للخط لا من اسم الملف.
    notoFamily = CustomFontFace.familyKeyFor('Noto Sans Arabic');
  });

  tearDown(() => CustomPdfFonts.clear());

  /// يشغّل الحلقة الزمنية الحقيقية حتى ينتهي الرفع غير المتزامن (FontLoader).
  Future<void> settleUpload(WidgetTester tester) async {
    await tester.runAsync(() async {
      final Stopwatch watch = Stopwatch()..start();
      while (controller.isEmpty &&
          watch.elapsed < const Duration(seconds: 15)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pumpAndSettle();
  }

  testWidgets('رفع خط مخصص يظهر فوراً في المحرر ويُضمَّن في الـ PDF',
      (WidgetTester tester) async {
    // منتقي ملفات مزيّف يعيد ملف TTF حقيقي من أصول التطبيق.
    FilePickerPlatform.instance = _FakeFilePicker(<PlatformFile>[
      _FakePlatformFile(
        name: 'NotoSansArabic-Bold.ttf',
        bytes: notoBoldBytes,
        uri: Uri.file('C:/fake/NotoSansArabic-Bold.ttf'),
      ),
    ]);

    await tester.pumpWidget(const _JourneyHarness());
    await tester.pumpAndSettle();

    // قبل الرفع: لا خطوط مخصصة والقسم يعرض تنبيه الحفظ المحلي.
    expect(controller.isEmpty, isTrue);
    expect(find.textContaining('تُحفظ على جهازك'), findsOneWidget);

    // (1) الرفع عبر الزر الحقيقي.
    await tester.tap(find.byTooltip('رفع خط مخصص (.ttf / .otf)'));
    await tester.pump();
    await settleUpload(tester);

    // (2) التسجيل: مكتبة الواجهة + محرّك الطباعة + FontLoader نفسه.
    expect(controller.faces.length, 1);
    expect(controller.families, contains(notoFamily));
    expect(controller.displayNameOf(notoFamily), 'Noto Sans Arabic');
    expect(controller.isRegisteredWithUi(notoFamily), isTrue);
    expect(CustomPdfFonts.contains(notoFamily), isTrue);
    expect(CustomPdfFonts.resolve(notoFamily, 700), isNotNull);
    // حُفظ محلياً فوراً (يلزم للاستعادة بعد إعادة التشغيل).
    expect(store.faces.length, 1);

    // (3) الظهور الفوري: المنتقي الموحّد يضمّ الخط المرفوع في مجموعته.
    expect(find.byKey(const ValueKey<String>('custom-font-picker')),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('custom-font-picker')));
    await tester.pumpAndSettle();
    expect(find.text('خطوطي المرفوعة · 1'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey<String>('font-option-$notoFamily')));
    await tester.pumpAndSettle();

    // (4) المحرر يرسم النص بالخط المخصص مباشرةً بعد الاختيار.
    final Text rendered = tester.widget<Text>(find.text('نص بالخط المخصص'));
    expect(rendered.style?.fontFamily, notoFamily);

    // (5) الطباعة/المعاينة: الخط نفسه يُضمَّن في ملف الـ PDF.
    PdfFontSet.resetCache();
    final PdfGeneratorService? service = await tester.runAsync(
      () => PdfGeneratorService.create(compress: false),
    );
    final PdfGenerationReport? report = await tester.runAsync(
      () => service!.generate(
        document: TemplateDocument(
          elements: <TemplateElement>[
            TextElement(
              id: 'text-1',
              box: const ElementBox(x: 40, y: 40, width: 480, height: 80),
              text: 'نص بالخط المخصص',
              customFont: notoFamily,
              fontSize: 28,
            ),
          ],
        ),
      ),
    );

    final String raw = latin1.decode(report!.bytes, allowInvalid: true);
    expect(raw, isNot(contains('IBMPlexSansArabic')));
    expect(raw, contains('NotoSansArabic'));
  }, timeout: const Timeout(Duration(minutes: 2)));
}

/// واجهة تجمع قسم «خطوطي المخصصة» الحقيقي مع عنصر محرر يتبع الخط المختار.
class _JourneyHarness extends StatefulWidget {
  const _JourneyHarness();

  @override
  State<_JourneyHarness> createState() => _JourneyHarnessState();
}

class _JourneyHarnessState extends State<_JourneyHarness> {
  String? _family;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16),
                child: FontSelectorSection(
                  bundledFamily: PdfFontFamily.plex,
                  customFamily: _family,
                  onBundledSelected: (PdfFontFamily _) =>
                      setState(() => _family = null),
                  onCustomSelected: (String? family) =>
                      setState(() => _family = family),
                ),
              ),
              Expanded(
                child: ElementView(
                  element: TextElement(
                    id: 'text-1',
                    box: const ElementBox(x: 0, y: 0, width: 400, height: 80),
                    text: 'نص بالخط المخصص',
                    customFont: _family,
                    fontSize: 24,
                  ),
                  document: const TemplateDocument(
                    elements: <TemplateElement>[],
                  ),
                  scale: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// منتقي ملفات مزيّف يعيد ملفات ثابتة بدل فتح الحوار الأصلي.
final class _FakeFilePicker extends FilePickerPlatform {
  _FakeFilePicker(this._files);

  final List<PlatformFile> _files;

  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async =>
      _files;
}

/// ملف منصّة مزيّف يحمل بايتات الخط في الذاكرة بلا أي قرص.
final class _FakePlatformFile extends PlatformFile {
  _FakePlatformFile({
    required this.name,
    required Uint8List bytes,
    required Uri uri,
  })  : _bytes = bytes,
        _uri = uri;

  @override
  final String name;

  final Uint8List _bytes;
  final Uri _uri;

  @override
  Uri get uri => _uri;

  @override
  XFile get xFile => throw UnimplementedError();

  @override
  int? lengthSync() => _bytes.length;

  @override
  Future<int?> length() async => _bytes.length;

  @override
  Future<Uint8List> readAsBytes() async => _bytes;

  @override
  Stream<Uint8List> readAsByteStream() async* {
    yield _bytes;
  }
}
