import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

/// يكتب بايتات PNG للمشروع في مجلد بيانات التطبيق ويعيد مساره الكامل.
///
/// الصورة المصغّرة **محلية بحتة**: ملف صغير بجانب قاعدة المشاريع، بلا أي رفع.
/// لا يرمي أبداً — أي فشل يُرجع `null` فيتابع الحفظ بلا صورة مصغّرة.
Future<String?> writeThumbnail(Uint8List bytes, String projectId) async {
  try {
    final Directory support = await getApplicationSupportDirectory();
    final String separator = Platform.pathSeparator;
    final Directory folder =
        Directory('${support.path}${separator}thumbnails');
    if (!folder.existsSync()) {
      await folder.create(recursive: true);
    }
    final File file = File('${folder.path}$separator$projectId.png');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  } catch (error) {
    debugPrint('[المشاريع المحلية] تعذّر كتابة الصورة المصغّرة: $error');
    return null;
  }
}

/// حذف ملف صورة مصغّرة (عند حذف مشروع أو استبداله). لا يرمي.
Future<void> deleteThumbnail(String? path) async {
  final String target = (path ?? '').trim();
  if (target.isEmpty) return;
  try {
    final File file = File(target);
    if (await file.exists()) await file.delete();
  } catch (error) {
    debugPrint('[المشاريع المحلية] تعذّر حذف الصورة المصغّرة: $error');
  }
}

/// مزوّد صورة من مسار ملف محلي — `null` إن لم يوجد الملف (فلا رسم مكسور).
ImageProvider<Object>? thumbnailImage(String? path) {
  final String target = (path ?? '').trim();
  if (target.isEmpty) return null;
  final File file = File(target);
  return file.existsSync() ? FileImage(file) : null;
}
