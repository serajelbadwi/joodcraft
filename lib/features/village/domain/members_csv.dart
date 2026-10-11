/// تصدير أعضاء القرية إلى فهرس CSV عربي جاهز لـ Excel — دوال نقية بلا I/O.
///
/// صيغة الملف محسوبة لتفتح في Excel بلا «رموز مشوّهة»: **BOM** في البداية
/// (يعرّف Excel الترميز UTF-8) وسطور بفواصل CRLF، مع تدقيق RFC 4180 لمن
/// تحوي الخانة فاصلة أو علامة اقتباس أو سطراً.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'national_id.dart';
import 'village_member.dart';

/// توليد متن ملف CSV (بما فيه BOM وسطور الترويسة).
String buildMembersCsv(Iterable<VillageMember> members) {
  final StringBuffer out = StringBuffer();
  out.write(_bom);
  out.write(_header.map(_cell).join(','));
  out.write(_crlf);
  for (final VillageMember member in members) {
    out.write(
      <String>[
        member.name,
        member.phone,
        member.nationalId,
        _label(member.birthDate),
        '${member.age}',
        genderLabel(memberIsMale(member)),
        _label(member.createdAt),
      ].map(_cell).join(','),
    );
    out.write(_crlf);
  }
  return out.toString();
}

/// ترميز [buildMembersCsv] جاهزاً للكتابة على القرص.
Uint8List encodeMembersCsv(Iterable<VillageMember> members) =>
    Uint8List.fromList(utf8.encode(buildMembersCsv(members)));

/// ترويسة الأعمدة — بالترتيب نفسه الذي تُكتب به البيانات.
const List<String> _header = <String>[
  'الاسم',
  'التليفون',
  'الرقم القومي',
  'تاريخ الميلاد',
  'السن',
  'الجنس',
  'تاريخ التسجيل',
];

/// البادئة التي تجعل Excel يقرأ الملف بـ UTF-8.
const String _bom = '\uFEFF';

const String _crlf = '\r\n';

/// نسبة عضو إلى **الذكور** استنتاجاً من رقمه القومي (الخانة الثالثة عشرة:
/// فردي ⇒ ذكر) — أو `null` إن لم يكن الرقم صالحاً للقراءة.
bool? memberIsMale(VillageMember member) {
  final String digits = NationalIdValidator.normalize(member.nationalId);
  if (digits.length != NationalIdValidator.length ||
      !NationalIdValidator.isAllDigits(digits)) {
    return null;
  }
  final int century = int.parse(digits[0]);
  if (century != 2 && century != 3) return null;
  return int.parse(digits[12]).isOdd;
}

/// تسمية الجنس للعرض/التصدير — «غير محدَّد» عند غياب الدليل.
String genderLabel(bool? isMale) {
  if (isMale == null) return 'غير محدَّد';
  return isMale ? 'ذكر' : 'أنثى';
}

/// تاريخ بصيغة `YYYY-MM-DD` (أو شَرَط فارغ إن لم يوجد).
String _label(DateTime? at) {
  final DateTime? date = at;
  if (date == null) return '';
  final String y = date.year.toString().padLeft(4, '0');
  final String m = date.month.toString().padLeft(2, '0');
  final String d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// خانة واحدة وفق RFC 4180: اقتباس مزدوج لما يحتوي رموزاً حسّاسة.
String _cell(String raw) {
  final String value = raw.trim();
  final bool needsQuotes = value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r');
  if (!needsQuotes) return value;
  return '"${value.replaceAll('"', '""')}"';
}
