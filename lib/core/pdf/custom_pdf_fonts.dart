import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

import '../errors/app_error_code.dart';
import '../errors/app_exception.dart';
import '../fonts/font_inspector.dart';

/// سجل الخطوط التي رفعها المستخدم بنفسه (المحرّك الديناميكي للخطوط).
///
/// مصمَّم ليكون **مستقلاً** عن أي طبقة أعلى: لا يعرف شيئاً عن التخزين المحلي
/// ولا عن الواجهة. مهمته الوحيدة: تحويل بايتات ملف خط إلى كائن `pw.Font`
/// جاهز للرسم في الـ PDF، وإتاحته بالاسم الذي اختاره المستخدم.
///
/// **تصغير الخط عند التضمين:** محرّك الـ PDF (حزمة `pdf`) يُضمِّن خط TrueType
/// القياسي كـ`Type0` ثم يقصّ جدول `glyf` على **المحارف المستخدمة في المستند
/// فقط**، فيبقى ملف التصدير صغيراً (‎90KB ← ~3KB لنص قصير). لكن هذا القصّ لا
/// يحدث إلا حين يكون رأس ملف الخط ‎`0x00010000` (TrueType/glyf)؛ أما رأس
/// `OTTO` (‎CFF/PostScript) أو `ttcf` (مجموعة) فيُضمَّن الملف **كاملاً** فيتضخّم
/// التصدير كثيراً — لذلك نرفضها هنا (بلا كسر الواجهة) بدل مفاجأة الحجم.
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

  /// نسخة من بايتات أول وزن مسجَّل لكل عائلة (لحساب التغطية كسولاً).
  static final Map<String, Uint8List> _bytesByFamily = <String, Uint8List>{};

  /// تغطية محارف كل عائلة (تُحسب عند أول طلب فقط).
  static final Map<String, Set<int>> _coverageCache = <String, Set<int>>{};

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
    // لا نُضمِّن إلا TrueType قياسياً قابلاً للقصّ على المحارف المستخدمة؛ غيره
    // يُضمَّن كاملاً فيتضخّم ملف التصدير (راجع الشرح في أعلى الملف). هذا مهم
    // خصوصاً لخطوط النظام التي قد تكون .otf/CFF فلا يمرّ عليها فحص الرفع.
    if (!isSubsettableTrueType(bytes)) {
      throw AppException(
        AppErrorCode.fontUnavailable,
        message: 'الخط "$name" ليس TrueType قياسياً (.ttf)، فلا يستطيع محرّك '
            'الـ PDF قصّ محارفه عند التضمين ويتضخّم ملف التصدير. استخدم نسخة '
            '.ttf منه — أو اختر خطاً مضمّناً.',
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
    _bytesByFamily.putIfAbsent(name, () => bytes);
    _coverageCache.remove(name);
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

  /// رأس ملف TrueType القياسي (`sfnt version` = ‎0x00010000) — وهو الوحيد الذي
  /// يستطيع محرّك الـ PDF قصّ محارفه على المستخدم في المستند.
  static const int _trueTypeSfntVersion = 0x00010000;

  /// هل الملف TrueType قياسي قابل للتصغير (بدل تضمينه كاملاً)؟
  ///
  /// يقرأ أول أربعة بايتات (رأس `sfnt`) ويقبل `0x00010000` فقط؛ أما `OTTO`
  /// (‎CFF) و`ttcf` (مجموعة) فتُرفض لأن محرّك الـ PDF يُضمِّنها كاملة.
  static bool isSubsettableTrueType(Uint8List bytes) {
    if (bytes.lengthInBytes < 4) return false;
    final int sfnt =
        (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
    return sfnt == _trueTypeSfntVersion;
  }

  static bool contains(String family) => _byFamily.containsKey(family);

  static Set<String> get families => _byFamily.keys.toSet();

  static int get familyCount => _byFamily.length;

  /// الأوزان المسجَّلة لعائلة مخصصة (مثل `{regular, bold}`).
  static Set<String> variantsOf(String family) =>
      Set<String>.from(_variants[family] ?? const <String>{});

  /// محارف عائلة مخصّصة/نظامية مسجّلة (لحساب فحص التغطية بدقّة)، أو `null` إن
  /// لم تُسجَّل. تُحسب مرة واحدة من بايتات أول وزن وتُخزَّن.
  static Set<int>? codePointsOf(String family) {
    final String name = family.trim();
    if (!_bytesByFamily.containsKey(name)) return null;
    return _coverageCache[name] ??=
        FontInspector.inspect(_bytesByFamily[name]!).codePoints;
  }

  static void remove(String family) {
    _byFamily.remove(family);
    _variants.remove(family);
    _bytesByFamily.remove(family);
    _coverageCache.remove(family);
  }

  /// مسح كل الخطوط المخصصة (للاختبارات فقط).
  static void clear() {
    _byFamily.clear();
    _variants.clear();
    _bytesByFamily.clear();
    _coverageCache.clear();
  }
}
