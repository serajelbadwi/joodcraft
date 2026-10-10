import 'dart:typed_data';

import 'package:flutter/painting.dart';

/// كتابة الصور المصغّرة على الويب: بلا مسارات ملفات — نُرجع `null` دائماً
/// فتبقى البطاقة على رسمها المتجهي بلا كسر للبناء.
Future<String?> writeThumbnail(Uint8List bytes, String projectId) async => null;

/// حذف صورة مصغّرة — لا شيء على الويب.
Future<void> deleteThumbnail(String? path) async {}

/// مزوّد صورة من مسار ملف — لا مسارات على الويب.
ImageProvider<Object>? thumbnailImage(String? path) => null;
