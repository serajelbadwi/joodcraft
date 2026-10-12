/// لقطات شاشة لشريط Ribbon (خمسة تبويبات) تُحفظ في `build/ribbon_screenshots/`.
///
/// الرسم الحقيقي يتطلّب خطوطاً فعلية: خط Cairo من أصول التطبيق وخط
/// MaterialIcons من ذاكرة Flutter — يُحمَّلان عبر `FontLoader` قبل الضخّ.
/// الالتقاط داخل `tester.runAsync` لأن `toImage` عمل غير وهمي الزمن.
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/jood_writer/presentation/widgets/ribbon/writer_ribbon_bar.dart';
import 'package:joodcraft/features/jood_writer/presentation/writer_document_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ribbon_test_helpers.dart';

/// مسار ملف خط الأيقونات داخل ذاكرة Flutter — يُبحث عنه صعوداً من مسار
/// المُنفِّذ حتى لا يرتبط الاختبار بمسار SDK معيّن.
File? _materialIconsFont() {
  final List<String> relative = <String>[
    'bin/cache/artifacts/material_fonts/materialicons-regular.otf',
    'cache/artifacts/material_fonts/materialicons-regular.otf',
    'artifacts/material_fonts/materialicons-regular.otf',
  ];
  final List<Directory> roots = <Directory>[
    if (Platform.environment['FLUTTER_ROOT'] != null)
      Directory(Platform.environment['FLUTTER_ROOT']!),
    File(Platform.resolvedExecutable).parent,
  ];
  for (final Directory root in roots) {
    Directory? dir = root;
    for (int up = 0; up < 8 && dir != null; up++) {
      for (final String rel in relative) {
        final File file = File('${dir.path}/$rel');
        if (file.existsSync()) return file;
      }
      dir = dir.parent;
    }
  }
  return null;
}

Future<void> _loadFonts() async {
  final FontLoader cairo = FontLoader('Cairo')
    ..addFont(rootBundle.load('assets/fonts/cairo/Cairo-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/cairo/Cairo-SemiBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/cairo/Cairo-Bold.ttf'));
  await cairo.load();

  final File? iconsFont = _materialIconsFont();
  if (iconsFont != null) {
    final Uint8List bytes = iconsFont.readAsBytesSync();
    final ByteData data = ByteData.view(
      bytes.buffer,
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    );
    final FontLoader icons = FontLoader('MaterialIcons')
      ..addFont(Future<ByteData>.value(data));
    await icons.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_loadFonts);

  const String outputDir = 'build/ribbon_screenshots';

  Future<File> captureTab(
    WidgetTester tester, {
    required int tab,
    required String name,
  }) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(1600, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final WriterDocumentController controller = WriterDocumentController();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Cairo', useMaterial3: true),
        home: Scaffold(
          backgroundColor: const Color(0xFFF1F3F7),
          body: RibbonTestHost(
            controller: controller,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                RepaintBoundary(
                  key: const ValueKey<String>('ribbon-shot'),
                  child: WriterTabbedRibbonBar(
                    key: const ValueKey<String>('writer-ribbon'),
                    controller: controller,
                  ),
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (tab != 0) await selectRibbonTab(tester, tab);

    final File out = File('$outputDir/$name.png');
    ui.Image? image;
    final bool? saved = await tester.runAsync(() async {
      final RenderRepaintBoundary boundary =
          tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey<String>('ribbon-shot')),
      );
      image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? png = await image!.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (png == null) return false;
      out.parent.createSync(recursive: true);
      out.writeAsBytesSync(png.buffer.asUint8List());
      return true;
    });

    expect(saved, isTrue, reason: 'تعذّر توليد PNG لـ$name');
    image!.dispose();
    expect(out.existsSync(), isTrue, reason: name);
    expect(out.lengthSync(), greaterThan(5000), reason: name);
    return out;
  }

  testWidgets('لقطة التبويب: الرئيسية', (WidgetTester tester) async {
    await captureTab(tester, tab: 0, name: 'ribbon_home');
  });

  testWidgets('لقطة التبويب: التهيئة', (WidgetTester tester) async {
    await captureTab(tester, tab: 1, name: 'ribbon_setup');
  });

  testWidgets('لقطة التبويب: التصميم', (WidgetTester tester) async {
    await captureTab(tester, tab: 2, name: 'ribbon_design');
  });

  testWidgets('لقطة التبويب: الحفظ', (WidgetTester tester) async {
    await captureTab(tester, tab: 3, name: 'ribbon_file');
  });

  testWidgets('لقطة التبويب: المراجعة', (WidgetTester tester) async {
    await captureTab(tester, tab: 4, name: 'ribbon_review');
  });
}
