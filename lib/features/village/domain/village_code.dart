/// كود القرية — مفتاح التسجيل الذي يُوزَّع على الأهالي لفتح نموذج البيانات.
///
/// الصيغة المتّفق عليها: **ثلاثة حروف لاتينية + شرطة + سنة الميلاد/التأسيس**،
/// مثال البذرة الأولى: `MAA-2026` — أي «م ن ش أ ة ا ل أ م ر ا ء» (MAA) وسنة 2026.
/// ومنذ لوحة تحكم المالك أُضيفت صيغة ثانیة: `MAA-31951-25GF` (بادئة + رمز
/// بريدي + Plus Code مختصر) — وتقبل شاشات التطبيق الصيغتين.
library;

import 'package:flutter/foundation.dart';

abstract final class VillageCode {
  const VillageCode._();

  /// صيغتا الكود المعتمدتان:
  /// * القديمة: ثلاثة حروف لاتينية كبيرة، شرطة، أربعة أرقام (`MAA-2026`).
  /// * الجديدة (لوحة تحكم المالك): بادئة + رمز بريدي من خمسة أرقام +
  ///   Plus Code مختصر (`MAA-31951-25GF`).
  static final RegExp pattern = RegExp(
    r'^[A-Z]{3}-([0-9]{4}|[0-9]{5}-[A-Z0-9]{4,})$',
  );

  /// أكواد البذرة المعروفة: اسم القرية ← بادئته الرسمية.
  ///
  /// لماذا خريطة صريحة؟ لأن «MAA» اختصار متعارف عليه لأهل القرية (م ن ش أ ة/
  /// ا ل أ م ر ا ء) ولا يمكن اشتقاقه آلياً من الحروف الأولى (`م أ م ح`)، فنثبّته
  /// هنا، ويبقى الاشتقاق الآلي ([suggestFor]) تلقائياً لأي قرية جديدة.
  static const Map<String, String> knownPrefixes = <String, String>{
    'منشأة الأمراء ومحلة حسن': 'MAA',
    'منشأة الامراء ومحلة حسن': 'MAA',
  };

  /// السنة الافتراضية لتوليد الأكواد.
  static const int defaultYear = 2026;

  /// يحوّل حرفاً عربياً إلى ما يقابله لاتينياً (للأحرف الأولى فقط).
  static const Map<String, String> _latinByArabic = <String, String>{
    'ا': 'A', 'أ': 'A', 'إ': 'A', 'آ': 'A', 'ء': 'A', 'ئ': 'A', 'ؤ': 'A',
    'ع': 'A', 'ى': 'A',
    'ب': 'B', 'ت': 'T', 'ث': 'T', 'ج': 'G', 'ح': 'H', 'خ': 'K', 'د': 'D',
    'ذ': 'Z', 'ر': 'R', 'ز': 'Z', 'س': 'S', 'ش': 'S', 'ص': 'S', 'ض': 'D',
    'ط': 'T', 'ظ': 'Z', 'غ': 'G', 'ف': 'F', 'ق': 'Q', 'ك': 'K', 'ل': 'L',
    'م': 'M', 'ن': 'N', 'ه': 'H', 'و': 'W', 'ي': 'Y', 'ة': 'H', 'پ': 'B',
    'چ': 'G', 'ڤ': 'V', 'گ': 'G',
  };

  /// يُطبّع الكود: حذف المسافات ومحارف الاتجاه، وتوحيد الحالة إلى لاتينية كبيرة.
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
      if (ch == '\u2010' || ch == '\u2011' || ch == '\u2012' ||
          ch == '\u2013' || ch == '\u2014' || ch == 'ـ') {
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

  /// هل الكود مطابق للصيغة المعتمدة (بعد التطبيع)؟
  static bool isValid(String raw) => pattern.hasMatch(normalize(raw));

  /// الكود بصورته المعيارية — يُستدعى قبل الحفظ أو الاستعلام.
  static String canonical(String raw) => normalize(raw);

  /// يبني كوداً من بادئة لاتينية وسنة: `MAA` + `2026` ⇒ `MAA-2026`.
  static String generate({required String latinPrefix, int? year}) {
    final String prefix = latinPrefix
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z]'), '')
        .padRight(3, 'X')
        .substring(0, 3);
    return '$prefix-${year ?? defaultYear}';
  }

  /// يقترح كوداً لاسم قرية عربي: البادئة الرسمية المعروفة إن وُجدت، وإلا أول
  /// ثلاثة **حروف مختلفة** من كلمات الاسم (بحذف «ال» التعريف وواو العطف)
  /// مُحوَّلة إلى لاتينية.
  ///
  /// أمثلة:
  /// * `منشأة الأمراء ومحلة حسن` ⇒ `MAA-2026` (بادئة مثبّتة في [knownPrefixes]،
  ///   لأن اختصار أهل القرية المتعارف عليه لا يُشتقّ آلياً من الحروف الأولى).
  /// * `كفر الشيخ` ⇒ `KFR-2026` (ك ⇒ K، ف ⇒ F، ر ⇒ R).
  ///
  /// الاقتراح نقطة بداية لا حكم نهائي: المسؤول يراجعه ويمكنه تعديله قبل الحفظ،
  /// والقيد `villages_code_unique` هو الفيصل.
  static String suggestFor(String villageName, {int? year}) {
    final String name = villageName.trim();
    final String? known = knownPrefixes[name];
    if (known != null) return generate(latinPrefix: known, year: year);

    final List<String> words = name
        .split(RegExp(r'[\s\-_\.]+'))
        .where((String w) => w.trim().isNotEmpty)
        .toList();

    final List<String> letters = <String>[];
    for (final String word in words) {
      // حذف «ال» التعريف من أول الكلمة، وواو العطف المفردة.
      String stem = word;
      if (stem.length > 2 && stem.startsWith('ال')) {
        stem = stem.substring(2);
      } else if (stem.length > 3 && stem.startsWith('و')) {
        stem = stem.substring(1);
      }

      for (final String ch in stem.split('')) {
        final String latin = _latinByArabic[ch] ?? '';
        // حرف غير عربي (رقم/رمز) لا يصلح للبادئة، والمكرّر يُستبعد.
        if (latin.isEmpty || letters.contains(latin)) continue;
        letters.add(latin);
        if (letters.length == 3) break;
      }
      if (letters.length == 3) break;
    }

    return generate(
      latinPrefix: letters.isEmpty ? 'VIL' : letters.join(),
      year: year,
    );
  }
}

/// كود قرية مُتحقَّق منه — يمنع تمرير نصوص غير مطابقة إلى الواجهة.
@immutable
class VillageCodeValue {
  const VillageCodeValue._(this.value);

  /// الكود المعياري (‎MAA-2026‎).
  final String value;

  /// يبني قيمة من نص خام، أو `null` إن كان النص غير مطابق للصيغة.
  static VillageCodeValue? tryParse(String raw) {
    final String normalized = VillageCode.normalize(raw);
    if (!VillageCode.pattern.hasMatch(normalized)) return null;
    return VillageCodeValue._(normalized);
  }

  /// سنة الكود (‎2026‎).
  String get year => value.split('-').last;

  /// بادئة الكود (‎MAA‎).
  String get prefix => value.split('-').first;

  @override
  bool operator ==(Object other) =>
      other is VillageCodeValue && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
