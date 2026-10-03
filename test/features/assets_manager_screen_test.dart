import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/assets/asset_store.dart';
import 'package:joodcraft/core/assets/assets_controller.dart';
import 'package:joodcraft/core/assets/user_asset.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/features/assets_manager/presentation/screens/assets_manager_screen.dart';

// ignore: depend_on_referenced_packages
import 'package:cross_file/cross_file.dart';

import '../support/sample_image.dart';

/// اختبارات مدير الأصول (المرحلة 5ب).
void main() {
  late AssetsController controller;

  setUp(() {
    controller = AssetsController(store: InMemoryAssetStore());
    AssetsController.instance = controller;
  });

  Future<UserAsset> seed({
    AssetType type = AssetType.logo,
    String name = 'شعار الشركة',
  }) {
    return controller.addAsset(
      type: type,
      name: name,
      fileName: 'logo.png',
      bytes: samplePngBytes(),
    );
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: AssetsManagerScreen(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('بلا أصول تعرض حالة الفراغ', (WidgetTester tester) async {
    await pump(tester);
    expect(find.text('لا توجد أصول بعد'), findsOneWidget);
  });

  testWidgets('تعرض الأصول المرفوعة باسمها ونوعها', (WidgetTester tester) async {
    await seed();
    await pump(tester);

    expect(find.text('شعار الشركة'), findsOneWidget);
    expect(find.textContaining('شعار'), findsWidgets);
    expect(find.text('1 أصل'), findsOneWidget);
  });

  testWidgets('تصفية النوع تُخفي غير المطابق', (WidgetTester tester) async {
    await seed();
    await seed(type: AssetType.stamp, name: 'الختم الرسمي');
    await pump(tester);

    await tester.tap(find.byType(DropdownButton<AssetType?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('شعار').last);
    await tester.pumpAndSettle();

    expect(find.text('شعار الشركة'), findsOneWidget);
    expect(find.text('الختم الرسمي'), findsNothing);
  });

  testWidgets('حذف أصل يطلب تأكيداً ثم يُزيله', (WidgetTester tester) async {
    final UserAsset asset = await seed();
    await pump(tester);

    await tester.tap(
      find.descendant(
        of: find.byKey(ValueKey<String>('asset-card-${asset.id}')),
        matching: find.byIcon(Icons.more_vert_rounded),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();

    expect(find.text('حذف الأصل'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'حذف'));
    await tester.pumpAndSettle();

    expect(controller.isEmpty, isTrue);
    expect(find.text('لا توجد أصول بعد'), findsOneWidget);
  });

  testWidgets('إعادة التسمية تفتح نافذة وتُحدّث الاسم', (WidgetTester tester) async {
    final UserAsset asset = await seed();
    await pump(tester);

    await tester.tap(
      find.descendant(
        of: find.byKey(ValueKey<String>('asset-card-${asset.id}')),
        matching: find.byIcon(Icons.more_vert_rounded),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('إعادة التسمية'));
    await tester.pumpAndSettle();

    expect(find.text('إعادة تسمية الأصل'), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'شعار محدّث',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
    await tester.pumpAndSettle();

    // النافذة أُغلقت بلا استثناء استخدام-بعد-التخلص، والاسم تحدّث.
    expect(find.text('إعادة تسمية الأصل'), findsNothing);
    expect(controller.byId(asset.id)!.name, 'شعار محدّث');
  });

  testWidgets('تغيير النوع لا يفقد الأصل', (WidgetTester tester) async {
    final UserAsset asset = await seed();
    await pump(tester);

    await tester.tap(
      find.descendant(
        of: find.byKey(ValueKey<String>('asset-card-${asset.id}')),
        matching: find.byIcon(Icons.more_vert_rounded),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('اجعل النوع: ختم'));
    await tester.pumpAndSettle();

    expect(controller.count, 1);
    final List<UserAsset> stamps = controller.byType(AssetType.stamp);
    expect(stamps.length, 1);
    expect(stamps.single.name, 'شعار الشركة');
  });

  testWidgets('الرفع عبر منتقي الملفات يُضيف أصلاً', (WidgetTester tester) async {
    FilePickerPlatform.instance = _FakeFilePicker(<PlatformFile>[
      _FakePlatformFile(name: 'logo.png', bytes: samplePngBytes()),
    ]);

    await pump(tester);

    await tester.tap(find.text('رفع أصل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('رفع شعار').last);
    await tester.pumpAndSettle();

    expect(controller.count, 1);
    expect(find.text('logo'), findsOneWidget);
  });
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

/// ملف منصّة مزيّف يحمل بايتات الصورة في الذاكرة بلا أي قرص.
final class _FakePlatformFile extends PlatformFile {
  _FakePlatformFile({required this.name, required Uint8List bytes})
      : _bytes = bytes;

  @override
  final String name;

  final Uint8List _bytes;

  @override
  Uri get uri => Uri.file(name);

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
