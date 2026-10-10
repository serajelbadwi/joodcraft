import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../errors/app_exception.dart';
import '../theme/app_colors.dart';
import 'assets_controller.dart';

/// امتدادات الصور المقبولة في رفع الأصول.
const List<String> kUserAssetExtensions = <String>[
  'png',
  'jpg',
  'jpeg',
  'gif',
  'webp',
  'bmp',
];

/// رفع صورة (شعار/ختم/توقيع/إطار) إلى مكتبة الأصول المحلية.
///
/// يعيد عدد الصور التي أُضيفت فعلاً. يعمل بلا شبكة، ويرفض ما ليس صورة مدعومة
/// برسالة عربية واضحة.
Future<int> uploadUserAssets(
  BuildContext context, {
  AssetType type = AssetType.logo,
  AssetsController? controller,
}) async {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final AssetsController assets = controller ?? AssetsController.instance;

  final List<PlatformFile> picked;
  try {
    picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: kUserAssetExtensions,
      dialogTitle: 'اختر صورة ${type.labelAr} (PNG، JPG، WebP…)',
    );
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('تعذّر فتح منتقي الملفات: $error')),
    );
    return 0;
  }
  if (picked.isEmpty) return 0;

  int added = 0;
  final List<String> warnings = <String>[];
  for (final PlatformFile file in picked) {
    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (error) {
      warnings.add('تعذّر قراءة «${file.name}»: $error');
      continue;
    }
    try {
      await assets.addAsset(
        type: type,
        name: '',
        fileName: file.name,
        bytes: bytes,
      );
      added++;
    } on AppException catch (error) {
      warnings.add('"${file.name}": ${error.message}');
    } catch (error) {
      warnings.add('"${file.name}": $error');
    }
  }

  if (!context.mounted) return added;
  if (added > 0) {
    messenger.showSnackBar(
      SnackBar(content: Text('أُضيف $added ${type.labelAr} إلى مكتبة الأصول.')),
    );
  }
  if (warnings.isNotEmpty) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(warnings.join('\n')),
        backgroundColor: Theme.of(context).colorScheme.brandSurface,
        duration: const Duration(seconds: 8),
      ),
    );
  }
  return added;
}
