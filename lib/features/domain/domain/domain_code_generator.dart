/// توليد كود النطاق تلقائياً — الصيغة `MAA-31951-25GF989`.
///
/// ثلاثة أجزاء يفصلها شرطة:
/// * **البادئة** (3 حروف لاتينية): من الاسم الإنجليزي، تُقصّ إلى 3 وتُملأ
///   بـ`X` (`Maarra` ⇒ `MAA`).
/// * **الرمز البريدي** (5 أرقام): كما هو؛ وإن خالف فبديل «0 + السنة»
///   (`02026`) لتبقى الصيغة ثابتة.
/// * **الجزء الأخير** (7 أحرف بأقصاها): **4 أحرف قبل علامة `+`** في Plus
///   Code + **3 أحرف بعدها** (`25GF+989` ⇒ `25GF989`). إن قصر عن 4 أحرف
///   فبديل سنتين + حرفين من الاسم (`26MA`)؛ وإن بقي أقصر من 4 يُحشو بـ`Q`.
///
/// الخوارزمية مطابقة حرفياً لدالة `owner_generate_domain_code` في
/// `supabase_domains.sql` — المعاينة هنا تُظهر الكود الذي سينشئه الخادم،
/// والقاعدة وحدها تفحص التكرار وتحسم التسلسل عند التصادم.
///
/// الصيغة مقصودة على أن تُقبل في بوابة التسجيل (`VillageCode.pattern`
/// الموسّعة: `^[A-Z]{3}-[0-9]{5}-[A-Z0-9]{4,}$`) فتعمل مع شاشات التطبيق
/// القائمة بلا تعديل.
library;

import 'package:flutter/foundation.dart';

abstract final class DomainCodeGenerator {
  const DomainCodeGenerator._();

  /// صيغة الكود المولَّد: بادئة 3 حروف، بريد 5 أرقام، ثم 4..7 من الأحرف
  /// والأرقام (4 قبل `+` في Plus Code + 3 بعده).
  static final RegExp pattern = RegExp(
    r'^[A-Z]{3}-[0-9]{5}-[A-Z0-9]{4,7}$',
  );

  /// طول الجزء الأخير: 4 قبل `+` و3 بعده ⇒ 7 بأقصى تقدير.
  static const int _plusHead = 4;
  static const int _plusTail = 3;
  static const int _maxLocal = _plusHead + _plusTail;

  /// أول [n] محارف بأمان — النص الأقصر يعود كما هو بلا RangeError.
  static String _take(String value, int n) =>
      value.length <= n ? value : value.substring(0, n);

  /// يولّد الكود من الاسم الإنجليزي + (اختيارياً) الرمز البريدي وPlus Code.
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
    final String prefix = _take(letters.toUpperCase().padRight(3, 'X'), 3);

    // الرمز البريدي: خمسة أرقام كما في الرموز المصرية؛ إن خالف فبديل
    // «0 + السنة» (02026) — فيبقى للكود صيغته الجديدة دوماً.
    String postal = (postalCode ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (postal.length != 5) {
      postal = '0${clock.year}';
    }

    // الجزء الأخير: 4 أحرف قبل علامة + و3 بعدها.
    final String cleaned = (plusCode ?? '')
        .replaceAll(RegExp(r'[^0-9A-Za-z+]'), '')
        .toUpperCase();
    final int plusAt = cleaned.indexOf('+');
    final String head =
        _take(plusAt >= 0 ? cleaned.substring(0, plusAt) : cleaned, _plusHead);
    final String tail =
        plusAt < 0 ? '' : _take(cleaned.substring(plusAt + 1), _plusTail);
    String local = head + tail;

    if (local.length < 4) {
      // البديل: سنتان + حرفان من الاسم اللاتيني (مطابق للخادم).
      final String fallback = _twoDigitYear(clock) + letters.toUpperCase();
      local = _take(fallback, 4);
    }
    local = local.padRight(4, 'Q');

    // سقف 7 أحرف (4 + 3) — لا يتجاوزه المحرف المقتطع أعلاه أصلاً، لكن
    // القيد يضمن الصيغة لو غُيّرت الحدود لاحقاً.
    local = _take(local, _maxLocal);

    return '$prefix-$postal-$local';
  }

  /// هل الكود مطابق للصيغة (بلا تطبيع — المدخل مُطبّع أصلاً)؟
  static bool isValid(String code) => pattern.hasMatch(code);

  /// سنتان من السنة (`2026` ⇒ `26`).
  static String _twoDigitYear(DateTime clock) {
    final String year = clock.year.toString();
    return year.substring(year.length - 2);
  }
}

/// كود نطاق مُتحقَّق منه — يمنع تمرير نصوص غير مطابقة إلى بقية التطبيق.
@immutable
class DomainCodeValue {
  const DomainCodeValue._(this.value);

  /// الكود المعياري (‎MAA-31951-25GF989‎).
  final String value;

  /// يبني قيمة من نص خام، أو `null` إن كان النص غير مطابق للصيغة.
  ///
  /// يقبل مسافات وشرطات طويلة وأرقاماً عربية كما يفعل تطبيع الكود في
  /// القاعدة؛ فالنسخ من رسالة أو ورقة لا يُسقِط التحقق.
  static DomainCodeValue? tryParse(String raw) {
    final String normalized = normalize(raw);
    if (!DomainCodeGenerator.pattern.hasMatch(normalized)) return null;
    return DomainCodeValue._(normalized);
  }

  /// تطبيع النص إلى صيغة الكود المعيارية.
  static String normalize(String raw) {
    final StringBuffer buffer = StringBuffer();
    for (final int rune in raw.runes) {
      final String ch = String.fromCharCode(rune);
      if (ch == ' ' ||
          ch == '\u00A0' ||
          ch == '\u200F' ||
          ch == '\u200E' ||
          ch == '\t' ||
          ch == '\n' ||
          ch == '\r') {
        continue;
      }
      // شرطة عربية/طويلة ← شرطة لاتينية موحّدة.
      if (ch == '\u2010' ||
          ch == '\u2011' ||
          ch == '\u2012' ||
          ch == '\u2013' ||
          ch == '\u2014' ||
          ch == 'ـ') {
        buffer.write('-');
        continue;
      }
      // أرقام عربية-هندية ← لاتينية.
      if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.writeCharCode(0x30 + (rune - 0x0660));
        continue;
      }
      if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.writeCharCode(0x30 + (rune - 0x06F0));
        continue;
      }
      buffer.write(ch.toUpperCase());
    }
    return buffer.toString();
  }

  /// البادئة (`MAA`).
  String get prefix => value.split('-').first;

  /// الرمز البريدي (`31951`).
  String get postal => value.split('-')[1];

  /// الجزء الأخير (`25GF989`).
  String get local => value.split('-')[2];

  @override
  bool operator ==(Object other) =>
      other is DomainCodeValue && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
