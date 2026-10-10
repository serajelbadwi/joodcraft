import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'project_thumbnails_writer_stub.dart'
    if (dart.library.io) 'project_thumbnails_writer_io.dart' as writer;

/// الصور المصغّرة للمشاريع — تُلتقط من لوحة المحرّر وتُخزَّن محلياً.
///
/// مكانها في العمود `thumbnail_path` من جدول المشاريع: مسار ملف PNG صغير في
/// مجلد بيانات التطبيق (وعلى الويب يبقى `null` فالواجهة ترسم بديلاً متجهياً).
/// لا شبكة ولا رفع: الهدف أن تعرض بطاقة «المشاريع الأخيرة» شكل المشروع بلا فتحه.
abstract final class ProjectThumbnails {
  /// أقصى عرض للصورة المصغّرة بالبكسل — بلا تكبير فوق دقّة اللوحة.
  static const double maxWidth = 360;

  /// يلتقط محتوى عقدة الرسم PNG بالبايتات فقط (بلا كتابة على القرص).
  ///
  /// تُستخدم لتضمين الصورة المصغّرة داخل ملف ‎.jood‎ (‎`thumbnail.png`‎) بلا
  /// ملفات وسيطة. لا ترمي أبداً: أي فشل (نافذة مغلقة، ذاكرة ممتلئة) يعني
  /// «بلا صورة مصغّرة» لا فشل العملية.
  static Future<Uint8List?> captureBytes(GlobalKey boundaryKey) async {
    try {
      final BuildContext? context = boundaryKey.currentContext;
      final RenderObject? object = context?.findRenderObject();
      if (object is! RenderRepaintBoundary || object.size.width <= 0) {
        return null;
      }
      final double pixelRatio =
          (maxWidth / object.size.width).clamp(0.1, 2.0).toDouble();
      final ui.Image image = await object.toImage(pixelRatio: pixelRatio);
      try {
        final ByteData? data =
            await image.toByteData(format: ui.ImageByteFormat.png);
        return data?.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } catch (error) {
      debugPrint('[المشاريع المحلية] تعذّر التقاط الصورة المصغّرة: $error');
      return null;
    }
  }

  /// يلتقط محتوى عقدة الرسم ويحفظه PNG محلياً، ويعيد المسار (أو `null`).
  ///
  /// لا يرمي أبداً: فشل الالتقاط (نافذة مغلقة، منصة بلا دعم ملفات، الذاكرة
  /// ممتلئة) يعني «مشروع بلا صورة مصغّرة» لا فشل حفظ.
  static Future<String?> capture(
    GlobalKey boundaryKey, {
    required String projectId,
  }) async {
    if (projectId.trim().isEmpty) return null;
    final Uint8List? bytes = await captureBytes(boundaryKey);
    if (bytes == null || bytes.isEmpty) return null;
    return writer.writeThumbnail(bytes, projectId.trim());
  }

  /// مزوّد صورة من المسار المخزَّن — `null` يعني ارسم بديلاً.
  static ImageProvider<Object>? imageOf(String? path) =>
      writer.thumbnailImage(path);

  /// حذف ملف صورة مصغّرة بلا رمي.
  static Future<void> discard(String? path) => writer.deleteThumbnail(path);
}
