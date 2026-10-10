import 'dart:typed_data';

/// عقد حفظ مخرجات التوليد الجماعي على القرص — بلا اعتماد على منصة بعينها.
///
/// الواجهة **نقية** (لا تستورد `dart:io`) ليُحقن تنفيذ وهمي في الاختبارات
/// بلا لمس نظام الملفات، ويُستورد التنفيذ الفعلي شرطياً في
/// `batch_output_backend.dart`.
abstract class BatchOutputService {
  const BatchOutputService();

  /// يفتح منتقي مجلدات أصلياً ويعيد المسار المختار، أو `null` إن أُلغي.
  Future<String?> pickDirectory({String? dialogTitle});

  /// مجلد الحفظ الافتراضي (التنزيلات ثم المستندات)، أو `null` إن تعذّر.
  ///
  /// يُستخدم كبديل حين يُغلق المستخدم منتقي المجلدات بلا اختيار.
  Future<String?> defaultDirectory();

  /// يكتب [bytes] باسم [fileName] داخل [directory] ويعيد المسار الكامل للملف.
  ///
  /// يعيد `null` إن فشل الحفظ أو لم تدعمه المنصة (الويب).
  Future<String?> savePdf({
    required String directory,
    required String fileName,
    required Uint8List bytes,
  });

  /// يُنشئ (أو يُعيد استخدام) مجلداً فرعياً باسم [name] داخل [directory]
  /// ويعيد مساره الكامل — وهو مسار حفظ ملفات الوضع المنفصل كي لا تُبعثَر
  /// في المجلد الأصل.
  ///
  /// يعيد `null` إن فشل الإنشاء أو لم تدعمه المنصة (الويب).
  Future<String?> createSubdirectory({
    required String directory,
    required String name,
  });

  /// يفتح [directory] في مستكشف ملفات النظام.
  ///
  /// يعيد `true` إن أُرسل الطلب، و`false` على المنصات غير المدعومة (الويب).
  Future<bool> openDirectory(String directory);
}
