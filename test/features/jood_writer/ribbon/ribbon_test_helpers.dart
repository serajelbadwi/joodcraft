/// أدوات مشتركة لاختبارات شريط **Ribbon** لـ«جود كاتب».
///
/// التصميم يراعي بيئة `flutter test`:
/// * سطح واسع (2400px) كي تظهر كل أقسام التبويب دون تمرير أفقي.
/// * `SharedPreferences.setMockInitialValues` قبل ضخّ الشريط (الحفظ التلقائي
///   والتعليقات يستدعيان التفضيلات، وبدون محاكاة يقذف MissingPluginException).
/// * [RibbonTestHost] يستضفي المتحكّم ويقتله عند تفكيك الشجرة — services
///   الشريط (التاريخ/العصا/التعليقات) تُقفل أولاً لأنها أبناء الشجرة، ثم
///   يُقتل المتحكّم فيُلغى مؤقّت الحفظ التلقائي **قبل** فحص الاختبارات
///   للمؤقّتات المعلّقة (يُنهي الاختبار فشلاً لو بقي مؤقّت حيّاً).
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodCall, MethodChannel;
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/jood_writer/domain/jood_writer_document.dart';
import 'package:joodcraft/features/jood_writer/presentation/widgets/ribbon/writer_ribbon_bar.dart';
import 'package:joodcraft/features/jood_writer/presentation/writer_document_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مفاتيح أزرار التبويبات الخمسة بالترتيب.
const List<String> kRibbonTabKeys = <String>[
  'ribbon-tab-home',
  'ribbon-tab-setup',
  'ribbon-tab-design',
  'ribbon-tab-file',
  'ribbon-tab-review',
];

/// عنوان قسم داخل الشريط — يُرسم بـ`RichText` (انظر [RibbonSection]).
Finder ribbonSection(String title) =>
    find.text(title, findRichText: true);

/// مضيف الشريط: يُقتل المتحكّم عند تفكيك الشجرة (انظر وثيقة الملف).
class RibbonTestHost extends StatefulWidget {
  const RibbonTestHost({
    super.key,
    required this.controller,
    required this.child,
  });

  final WriterDocumentController controller;
  final Widget child;

  @override
  State<RibbonTestHost> createState() => _RibbonTestHostState();
}

class _RibbonTestHostState extends State<RibbonTestHost> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// يضخّ الشريط في شاشة واسعة ويعيد المتحكّم المستعمل.
///
/// [initialDocument] يسمح بتهيئة نصّ/كتل المستند قبل بناء الشريط.
/// [tab] يبدّل التبويب الابتدائي (0 = الرئيسية).
Future<WriterDocumentController> pumpRibbon(
  WidgetTester tester, {
  int tab = 0,
  Size size = const Size(2400, 900),
  JoodWriterDocument? initialDocument,
}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final WriterDocumentController controller = WriterDocumentController(
    initialDocument: initialDocument,
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RibbonTestHost(
          controller: controller,
          child: WriterTabbedRibbonBar(
            key: const ValueKey<String>('writer-ribbon'),
            controller: controller,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (tab != 0) await selectRibbonTab(tester, tab);
  return controller;
}

/// يضغط تبويباً بقائمته وينتظر استقرار انتقال المحتوى.
Future<void> selectRibbonTab(WidgetTester tester, int index) async {
  await tester.tap(find.byKey(ValueKey<String>(kRibbonTabKeys[index])));
  await tester.pumpAndSettle();
}

/// يحاكي قناة `path_provider` بمجلد حقيقي.
///
/// قنوات المنصّة غير المُحاكاة لا تردّ في `flutter test` (تبقى معلّقة إلى
/// الأبد) — فيتعثّر السقوط إلى المجلد المؤقت ولا يظهر أي تنبيه حفظ.
void mockPathProvider() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (MethodCall call) async {
      if (call.method == 'getTemporaryDirectory') {
        return Directory.systemTemp.path;
      }
      return null;
    },
  );
}
