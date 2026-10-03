import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

import '../errors/app_error_code.dart';
import '../errors/app_exception.dart';

/// سجل الخطوط التي رفعها المستخدم بنفسه (المحرّك الديناميكي للخطوط).
///
/// مصمَّم ليكون **مستقلاً** عن أي طبقة أعلى: لا يعرف شيئاً عن التخزين المحلي
/// ولا عن الواجهة. مهمته الوحيدة: تحويل بايتات ملف خط إلى كائن `pw.Font`
/// جاهز للرسم في الـ PDF، وإتاحته بالاسم الذي اختاره المستخدم.
///
/// لماذا سجل ثابت (static)؟ لأن `PdfFontSet` يُحمَّل مرة واحدة ويُخزَّن مؤقتاً،
/// وتغيير الخطوط المخصصة لا يجوز أن يُبطل ذلك التخزين (إعادة قراءة 14 ملفاً
/// ~4MB لكل تعديل). لذلك تُقرأ الخطوط المضمّنة مرة، وتُسجَّل المخصصة هنا بشكل
/// تراكمي.
abstract final class CustomPdfFonts {
  /// الاسم ← الوزن ← الخط.
  static final Map<String, Map<int, pw.Font>> _byFamily =
      <String, Map<int, pw.Font>>{};

  /// الأوزان الفعلية المتاحة لكل عائلة (لإعلام أداة التحرير).
  static final Map<String, Set<String>> _variants = <String, Set<String>>{};

  /// تسجيل خط مخصص. يُستبدل الخط السابق لنفس (العائلة، الوزن) إن وُجد.
  ///
  /// يرمي [AppException] برمز `fontUnavailable` إذا رفض محرّك الـ PDF الملف
  /// (تنسيق غير مدعوم، أو ملف CFF بلا جدول `glyf`… إلخ) — بلا انهيار.
  static pw.Font register(
    String family,
    Uint8List bytes, {
    int weight = 400,
  }) {
    final String name = family.trim();
    if (name.isEmpty) {
      throw const AppException(
        AppErrorCode.validation,
        message: 'اسم الخط المخصص فارغ.',
      );
    }
    final pw.Font font;
    try {
      font = pw.Font.ttf(ByteData.sublistView(bytes));
    } catch (error) {
      throw AppException(
        AppErrorCode.fontUnavailable,
        message: 'لم يتمكّن محرّك الطباعة من قراءة ملف الخط "$name".',
        cause: error,
      );
    }
    (_byFamily[name] ??= <int, pw.Font>{})[weight] = font;
    (_variants[name] ??= <String>{}).add(
      weight >= 700 ? 'bold' : (weight >= 500 ? 'semiBold' : 'regular'),
    );
    return font;
  }

  /// الخط المخصص للعائلة المطلوبة، أو `null` إن لم تُسجَّل إطلاقاً.
  ///
  /// عند غياب الوزن المطلوب يُرجَع الوزن العادي، ثم أي وزن متاح — لأن رفض
  /// الرسم بالقيمة الافتراضية أفضل من ظهور مربعات فارغة.
  static pw.Font? resolve(String family, int weight) {
    final Map<int, pw.Font>? variants = _byFamily[family];
    if (variants == null || variants.isEmpty) return null;
    return variants[weight] ?? variants[400] ?? variants.values.first;
  }

  static bool contains(String family) => _byFamily.containsKey(family);

  static Set<String> get families => _byFamily.keys.toSet();

  static int get familyCount => _byFamily.length;

  /// الأوزان المسجَّلة لعائلة مخصصة (مثل `{regular, bold}`).
  static Set<String> variantsOf(String family) =>
      Set<String>.from(_variants[family] ?? const <String>{});

  static void remove(String family) {
    _byFamily.remove(family);
    _variants.remove(family);
  }

  /// مسح كل الخطوط المخصصة (للاختبارات فقط).
  static void clear() {
    _byFamily.clear();
    _variants.clear();
  }
}
