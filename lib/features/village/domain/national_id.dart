/// محرّك **الرقم القومي المصري**: تحقّق + استخراج تاريخ الميلاد والسن.
///
/// بنية الرقم (14 رقماً، بلا فواصل):
/// ```
///  2  | 90 05 12 | 12 | 345 6 | 7
///  ↑     ↑        ↑     ↑     ↑
///  القرن  التاريخ  المحافظة  السلسلة/النوع  خانة التحقق
/// ```
/// * **خانة القرن**: `2` ⇒ 1900–1999، `3` ⇒ 2000–2099.
/// * **التاريخ**: YYMMDD — يُتحقَّق منه كتاريخ حقيقي (لا 31 فبراير ولا 30 في
///   الشهر الثاني)، مع السنوات الكبيسة.
/// * **خانة المحافظة**: من القائمة الرسمية المعروفة (‎01‎–‎35‎، و`88` للمولودين
///   خارج مصر)، وأي كود خارجها يعني رقماً غير صحيح.
/// * **النوع**: الرقم الثالث عشر (من الشريحة) فردي ⇒ ذكر، زوجي ⇒ أنثى.
/// * **خانة التحقق** (الأخيرة): تُفحص بخوارزمية `mod 11` **غير رسمية** —
///   انظر [EgyptianNationalId.validate] و`strictChecksum`.
///
/// قاعدة التحقق الحاسمة في هذا المشروع: الرفض القطعي للطول والرقمية وصحة
/// التاريخ والمحافظة والسن (‎< 18‎)، **ولا يمرّ صف إلى قاعدة البيانات إلا
/// بالتحقق نفسه على السيرفر** (دالة `village_register_member`).
library;

import 'package:flutter/foundation.dart';

/// أخطاء التحقق من الرقم القومي — كل خطأ يحمل رسالته العربية الجاهزة للعرض.
enum NationalIdError {
  /// الحقل فارغ.
  empty('اكتب الرقم القومي (14 رقماً)'),

  /// وُجد حرف أو رمز غير الأرقام (بعد تطبيع الأرقام العربية).
  notDigits('الرقم القومي أرقام فقط — بلا حروف أو رموز'),

  /// العدد بعد التطبيع ليس 14 رقماً.
  wrongLength('الرقم القومي يجب أن يكون 14 رقماً بالضبط'),

  /// خانة القرن ليست 2 ولا 3.
  badCentury('خانة القرن في الرقم غير صحيحة (يجب أن تبدأ بـ 2 أو 3)'),

  /// التاريخ المستخرج لا وجود له في التقويم.
  badDate('تاريخ الميلاد المستخرج من الرقم غير صحيح'),

  /// التاريخ المستخرج في المستقبل.
  futureDate('تاريخ الميلاد المستخرج من الرقم مستقبلي — راجع الرقم'),

  /// كود محافظة غير معروف.
  unknownGovernorate('كود المحافظة داخل الرقم غير معروف'),

  /// السن أقل من 18.
  tooYoung('التسجيل متاح لمن أتمّ 18 سنة على الأقل'),

  /// خانة التحقق الأخيرة غير مطابقة.
  badChecksum('خانة التحقق في آخر الرقم غير مطابقة — راجع الرقم'),

  /// الرقم سليم لكن السن تُحسب من تاريخ لم يُتحقَّق منه؟ (لا يُستخدم — احتياط).
  none('');

  const NationalIdError(this.message);

  /// الرسالة العربية المعروضة للمستخدم.
  final String message;
}

/// نتيجة تحليل رقم قومي: إما قيمة صالحة أو خطأ واحد واضح.
@immutable
class NationalIdParse {
  /// تحليل ناجح.
  const NationalIdParse.valid(this.value) : error = null;

  /// تحليل فاشل.
  const NationalIdParse.invalid(this.error) : value = null;

  /// الرقم المُحلَّل (‎null‎ عند الفشل).
  final EgyptianNationalId? value;

  /// سبب الفشل (‎null‎ عند النجاح).
  final NationalIdError? error;

  /// هل الرقم صالح؟
  bool get isValid => value != null;

  /// رسالة الخطأ العربية (‎null‎ عند النجاح).
  String? get message => error?.message;
}

/// رقم قومي مُتحقَّق منه ببياناته المستخرجة.
@immutable
class EgyptianNationalId {
  const EgyptianNationalId({
    required this.digits,
    required this.birthDate,
    required this.age,
    required this.governorateCode,
    required this.isMale,
    required this.checksumMatches,
  });

  /// الرقم بعد التطبيع (14 رقماً لاتينياً).
  final String digits;

  /// تاريخ الميلاد المستخرج من الرقم.
  final DateTime birthDate;

  /// السن بالسنوات الكاملة وقت التحليل.
  final int age;

  /// كود المحافظة داخل الرقم (مثل `12`).
  final String governorateCode;

  /// الرقم الثالث عشر فردي ⇒ ذكر.
  final bool isMale;

  /// هل طابقت خانة التحقق الأخيرة خوارزمية `mod 11` غير الرسمية؟
  final bool checksumMatches;

  /// اسم المحافظة بالعربية (من القائمة المعروفة).
  String get governorateName =>
      governorateNames[governorateCode] ?? 'محافظة غير معروفة';

  /// تاريخ الميلاد بصيغة `YYYY/MM/DD`.
  String get birthDateLabel {
    final String y = birthDate.year.toString().padLeft(4, '0');
    final String m = birthDate.month.toString().padLeft(2, '0');
    final String d = birthDate.day.toString().padLeft(2, '0');
    return '$y/$m/$d';
  }

  /// الوصف المعروض أسفل الحقل: «تاريخ الميلاد: … — العمر: … سنة».
  String get previewLabel =>
      'تاريخ الميلاد: $birthDateLabel — العمر: $age سنة';
}

/// خريطة أكواد المحافظات المعروفة → أسماؤها.
///
/// المصدر: أكواد المواليد المتعارف عليها في الرقم القومي المصري (‎01‎–‎35‎)،
/// و`88` لمن وُلد خارج مصر.
const Map<String, String> governorateNames = <String, String>{
  '01': 'القاهرة',
  '02': 'الإسكندرية',
  '03': 'بورسعيد',
  '04': 'السويس',
  '11': 'دمياط',
  '12': 'الدقهلية',
  '13': 'الشرقية',
  '14': 'القليوبية',
  '15': 'كفر الشيخ',
  '16': 'الغربية',
  '17': 'المنوفية',
  '18': 'البحيرة',
  '19': 'الإسماعيلية',
  '21': 'الجيزة',
  '22': 'بني سويف',
  '23': 'الفيوم',
  '24': 'المنيا',
  '25': 'أسيوط',
  '26': 'سوهاج',
  '27': 'قنا',
  '28': 'أسوان',
  '29': 'الأقصر',
  '31': 'البحر الأحمر',
  '32': 'الوادي الجديد',
  '33': 'مطروح',
  '34': 'شمال سيناء',
  '35': 'جنوب سيناء',
  '88': 'خارج مصر',
};

/// أدوات التحقق من الرقم القومي — كلها دوال نقية بلا أي اعتماد خارجي.
abstract final class NationalIdValidator {
  const NationalIdValidator._();

  /// طول الرقم القومي الثابت.
  static const int length = 14;

  /// الحدّ الأدنى للسن (بالسنوات الكاملة).
  static const int minimumAge = 18;

  /// أوزان خانة التحقق (خوارزمية `mod 11` **غير رسمية** ومُطفأة افتراضياً).
  static const List<int> _checksumWeights = <int>[
    2, 7, 6, 5, 4, 3, 2, 7, 6, 5, 4, 3, 2,
  ];

  /// يطبّع المُدخَل: أرقام عربية-هندية/فارسية ← لاتينية، ويحذف المسافات
  /// والشرطات ومحارف الاتجاه غير المرئية.
  static String normalize(String raw) {
    final StringBuffer buffer = StringBuffer();
    for (final int rune in raw.runes) {
      // ٠..٩ (U+0660..U+0669)
      if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.writeCharCode(0x30 + (rune - 0x0660));
        continue;
      }
      // ۰..۹ (U+06F0..U+06F9)
      if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.writeCharCode(0x30 + (rune - 0x06F0));
        continue;
      }
      final String ch = String.fromCharCode(rune);
      if (ch == ' ' ||
          ch == '\u00A0' ||
          ch == '-' ||
          ch == '\u2010' ||
          ch == '\u2013' ||
          ch == '\u200F' ||
          ch == '\u200E' ||
          ch == '\t' ||
          ch == '\n' ||
          ch == '\r') {
        continue;
      }
      buffer.write(ch);
    }
    return buffer.toString();
  }

  /// هل كل المحارف أرقام لاتينية؟
  static bool isAllDigits(String value) =>
      value.isNotEmpty && RegExp(r'^[0-9]+$').hasMatch(value);

  /// تاريخ الميلاد من رقم قومي **بعد** التحقق من شكله — أو `null` إن كان
  /// التاريخ غير موجود فعلاً.
  static DateTime? birthDateOf(String digits) {
    if (digits.length != length || !isAllDigits(digits)) return null;
    final int centuryDigit = int.parse(digits[0]);
    if (centuryDigit != 2 && centuryDigit != 3) return null;

    final int year =
        (centuryDigit == 2 ? 1900 : 2000) + int.parse(digits.substring(1, 3));
    final int month = int.parse(digits.substring(3, 5));
    final int day = int.parse(digits.substring(5, 7));
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;

    final DateTime date = DateTime(year, month, day);
    // إعادة التحقق: `DateTime` تُدوّر التواريخ المستحيلة (31 فبراير ⇒ 2 مارس).
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  /// السن بالسنوات الكاملة بين تاريخين.
  static int ageAt(DateTime birthDate, DateTime today) {
    int age = today.year - birthDate.year;
    final bool hadBirthday = today.month > birthDate.month ||
        (today.month == birthDate.month && today.day >= birthDate.day);
    if (!hadBirthday) age -= 1;
    return age < 0 ? 0 : age;
  }

  /// هل خانة التحقق الأخيرة مطابقة لخوارزمية `mod 11` (غير الرسمية)؟
  static bool checksumMatches(String digits) {
    if (digits.length != length || !isAllDigits(digits)) return false;
    int sum = 0;
    for (int i = 0; i < _checksumWeights.length; i++) {
      sum += int.parse(digits[i]) * _checksumWeights[i];
    }
    final int expected = (11 - (sum % 11)) % 11;
    if (expected > 9) return false;
    return expected == int.parse(digits[13]);
  }

  /// يتحقق من رقم قومي ويُعيد نتيجة تحليل واحدة واضحة.
  ///
  /// [strictChecksum]: عند `true` تُرفض الأرقام التي لا تطابق خانة تحققها
  /// الخوارزمية أعلاه. **مُطفأ افتراضياً عن قصد**: قاعدة الخانة الأخيرة غير
  /// موثَّقة رسمياً، فتشغيلها قد يرفض أرقاماً حقيقية لأهالٍ يستحقون التسجيل.
  /// الملاحظات الصارمة (الطول/التاريخ/المحافظة/السن) تكفي لرفض الأرقام
  /// العشوائية، والخانة تُحفظ في [EgyptianNationalId.checksumMatches] للعلم.
  static NationalIdParse validate(
    String raw, {
    bool strictChecksum = false,
    DateTime? now,
  }) {
    if (raw.trim().isEmpty) {
      return const NationalIdParse.invalid(NationalIdError.empty);
    }

    final String digits = normalize(raw);
    if (digits.isEmpty) {
      return const NationalIdParse.invalid(NationalIdError.empty);
    }
    if (!isAllDigits(digits)) {
      return const NationalIdParse.invalid(NationalIdError.notDigits);
    }
    if (digits.length != length) {
      return const NationalIdParse.invalid(NationalIdError.wrongLength);
    }

    final int centuryDigit = int.parse(digits[0]);
    if (centuryDigit != 2 && centuryDigit != 3) {
      return const NationalIdParse.invalid(NationalIdError.badCentury);
    }

    final DateTime? birthDate = birthDateOf(digits);
    if (birthDate == null) {
      return const NationalIdParse.invalid(NationalIdError.badDate);
    }

    final DateTime today = now ?? DateTime.now();
    final DateTime dateOnly = DateTime(today.year, today.month, today.day);
    if (birthDate.isAfter(dateOnly)) {
      return const NationalIdParse.invalid(NationalIdError.futureDate);
    }

    final String governorate = digits.substring(7, 9);
    if (!governorateNames.containsKey(governorate)) {
      return const NationalIdParse.invalid(NationalIdError.unknownGovernorate);
    }

    final int age = ageAt(birthDate, dateOnly);
    if (age < minimumAge) {
      return const NationalIdParse.invalid(NationalIdError.tooYoung);
    }

    final bool checksum = checksumMatches(digits);
    if (strictChecksum && !checksum) {
      return const NationalIdParse.invalid(NationalIdError.badChecksum);
    }

    return NationalIdParse.valid(
      EgyptianNationalId(
        digits: digits,
        birthDate: birthDate,
        age: age,
        governorateCode: governorate,
        isMale: int.parse(digits[12]).isOdd,
        checksumMatches: checksum,
      ),
    );
  }
}
