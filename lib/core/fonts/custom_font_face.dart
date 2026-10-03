import 'dart:convert';
import 'dart:typed_data';

/// خط واحد رفعه المستخدم بنفسه ووُجد محلياً على جهازه.
///
/// الوحدة هي **ملف واحد = وجه واحد (weight)**. رفع `Cairo-Regular.ttf`
/// و`Cairo-Bold.ttf` يُنتج **عائلة واحدة** بوزنين، لأن العائلة تُشتق من اسم
/// الخط الداخلي لا من اسم الملف.
class CustomFontFace {
  const CustomFontFace({
    required this.family,
    required this.displayName,
    required this.fileName,
    required this.base64Data,
    this.weight = 400,
    this.arabicReady = true,
    required this.addedAt,
  });

  /// مفتاح التسجيل الفريد (واجهة فلاتر + محرّك الـ PDF + ملف القالب).
  ///
  /// يحمل بادئة تحيّد الاصطدام مع الخطوط المحزومة، فلا يمكن لخط رفعه المستخدم
  /// أن يحلّ محل `IBMPlexSansArabic` مثلاً.
  final String family;

  /// الاسم المعروض للمستخدم (بلا البادئة).
  final String displayName;

  final String fileName;
  final String base64Data;
  final int weight;

  /// هل يحقق الخط تغطية صور الحروف المتصلة (117/117 + لام-ألف 8/8)؟
  final bool arabicReady;

  final DateTime addedAt;

  /// بادئة مفاتيح الخطوط المخصصة.
  static const String familyPrefix = 'JoodCustom:';

  Uint8List get bytes => base64Decode(base64Data);

  /// الحجم التقريبي للخط بعد فك الترميز.
  int get byteSize => base64Data.length * 3 ~/ 4;

  String get sizeLabel {
    final int kb = byteSize ~/ 1024;
    if (kb < 1024) return '$kb KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  String get weightLabelAr => switch (weight) {
        >= 700 => 'عريض',
        >= 600 => 'متوسط',
        _ => 'عادي',
      };

  Map<String, dynamic> toJson() => <String, dynamic>{
        'family': family,
        'display_name': displayName,
        'file_name': fileName,
        'data': base64Data,
        'weight': weight,
        'arabic_ready': arabicReady,
        'added_at': addedAt.toIso8601String(),
      };

  /// قراءة آمنة من JSON؛ تعيد `null` لأي سجل تالف بدل إسقاط كل المكتبة.
  static CustomFontFace? fromJson(Object? json) {
    if (json is! Map) return null;
    final Object? family = json['family'];
    final Object? data = json['data'];
    if (family is! String || data is! String) return null;
    if (family.trim().isEmpty || data.trim().isEmpty) return null;
    final Object? rawWeight = json['weight'];
    return CustomFontFace(
      family: family,
      displayName: '${json['display_name'] ?? family}',
      fileName: '${json['file_name'] ?? family}',
      base64Data: data,
      weight: rawWeight is num ? rawWeight.toInt() : 400,
      arabicReady: json['arabic_ready'] != false,
      addedAt:
          DateTime.tryParse('${json['added_at']}') ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  /// مفتاح التسجيل المشتق من اسم الخط الداخلي.
  static String familyKeyFor(String displayName) {
    final String slug = displayName
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '');
    return '$familyPrefix${slug.isEmpty ? 'خط مخصص' : slug}';
  }

  /// إزالة اسم الوزن من نهاية اسم الملف: `Cairo-Bold.ttf` ← `Cairo`.
  static String displayNameFromFileName(String fileName) {
    String base = fileName.replaceAll('\\', '/').split('/').last;
    final int dot = base.lastIndexOf('.');
    if (dot > 0) base = base.substring(0, dot);
    base = base.replaceAll(RegExp(r'[_-]+'), ' ').trim();
    final String stripped = stripWeightSuffix(base);
    return stripped.isEmpty ? base : stripped;
  }

  /// حذف الكلمات الدالة على الوزن من نهاية اسم الخط أو الملف.
  static String stripWeightSuffix(String value) {
    final String stripped = value.replaceAll(
      RegExp(
        r'\s*(regular|normal|book|roman|bold|semibold|semi|medium|light|thin|black|heavy|italic|oblique)\s*$',
        caseSensitive: false,
      ),
      '',
    );
    return stripped.trim();
  }
}
