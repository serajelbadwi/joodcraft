/// توليد كود قرية بصيغة لوحة تحكم المالك.
///
/// الصيغة: `بادئة-رمز بريدي-Plus Code مختصر` مثل `MAA-31951-25GF`:
/// * **البادئة**: أولى حروف الاسم اللاتيني كبيرة، تُقصّ إلى 3 وتُملأ بـ`X`
///   (`Maarra` ⇒ `MAA`) — نفس منطق `village_code_from_name` في القاعدة.
/// * **الرمز البريدي**: أرقام فقط كما يكتبه المستخدم (4..6)؛ إن قصّر عن 4
///   فبديل السنة الحالية (`2026`) بيدوم الكود صيغة صحيحة بلا مدخلات.
/// * **Plus Code مختصر**: الجزء القبلي لعلامة `+` (`25GF+PQ` ⇒ `25GF`)؛
///   إن غاب أو قصر فبديل سنتان + حرفان من الاسم (`26MA`).
///
/// الخوارزمية مطابقة حرفياً لدالة `owner_generate_village_code` في
/// `supabase_village.sql` — المعاينة هنا تُظهر الكود الذي سينشئه الخادم.
/// (وحدها القاعدة تفحص التكرار بين القرى وتحسم التسلسل عند التصادم.)
///
/// لا يُخلط هذا المولّد بـ`VillageCode` القديم (صيغة `AAA-YYYY`): تلك الصيغة
/// ما تزال تمرّ في شاشات التسجيل القديمة، وهذه صيغة لوحة المالك الجديدة.
library;

abstract final class VillageCodeGenerator {
  const VillageCodeGenerator._();

  /// صيغة الكود المولَّد: بادئة 2..3 حروف، بريد 4..6 رقماً، وآخر جزء 4..6
  /// من الأحرف والأرقام (الأخير يمتدّ بأرقام المحاولة عند تكرار الكود).
  static final RegExp pattern = RegExp(
    r'^[A-Z]{2,3}-[0-9]{4,6}-[A-Z0-9]{4,6}$',
  );

  /// يولّد الكود من الاسم اللاتيني + (اختيارياً) الرمز البريدي وPlus Code.
  ///
  /// [now] يُحقن في الاختبارات لتثبيت بديل السنة؛ الافتراضي الوقت الحالي.
  static String generate({
    required String nameEn,
    String? postalCode,
    String? plusCode,
    DateTime? now,
  }) {
    final DateTime clock = now ?? DateTime.now();

    // البادئة: حروف لاتينية كبيرة فقط، padRight بـX إلى 3 ثم قصّ.
    final String letters = nameEn.replaceAll(RegExp(r'[^A-Za-z]'), '');
    final String prefix = letters.toUpperCase().padRight(3, 'X').substring(0, 3);

    // الرمز البريدي: أرقام فقط؛ أقل من 4 ⇒ السنة الحالية.
    String postal = (postalCode ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (postal.length < 4) {
      postal = clock.year.toString();
    }
    postal = postal.substring(0, postal.length > 6 ? 6 : postal.length);

    // Plus Code: نقيّ من الرموز غير alphanumeric/+ ثم نأخذ ما قبل علامة +.
    String plus = (plusCode ?? '')
        .replaceAll(RegExp(r'[^0-9A-Za-z+]'), '')
        .toUpperCase();
    final int plusAt = plus.indexOf('+');
    if (plusAt >= 0) {
      plus = plus.substring(0, plusAt);
    }
    plus = plus.substring(0, plus.length > 4 ? 4 : plus.length);
    if (plus.length < 4) {
      // البديل: سنتان + حرفان من الاسم اللاتيني (مطابق للخادم).
      final String fallback =
          _twoDigitYear(clock) +
          letters.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
      plus = fallback.substring(0, fallback.length > 4 ? 4 : fallback.length);
    }
    plus = plus.padRight(4, 'Q');

    return '$prefix-$postal-$plus';
  }

  /// هل الكود مطابق للصيغة (بلا تطبيع — المدخل مُطبّع أصلاً)?
  static bool isValid(String code) => pattern.hasMatch(code);

  /// سنتان من السنة (`2026` ⇒ `26`).
  static String _twoDigitYear(DateTime clock) {
    final String year = clock.year.toString();
    return year.substring(year.length - 2);
  }
}
