import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/village/domain/members_csv.dart';
import 'package:joodcraft/features/village/domain/village_member.dart';

/// عضو مبنيّ من صفّ كما يعيده السيرفر — الحقول كلها تحت سيطرة الاختبار.
VillageMember _member({
  String id = 'm1',
  String name = 'محمد أحمد',
  String nationalId = '29001011234557',
  int age = 30,
}) =>
    VillageMember.fromRow(<String, dynamic>{
      'id': id,
      'village_id': 'v1',
      'name': name,
      'phone': '01012345678',
      'national_id': nationalId,
      'birth_date': '1996-01-01',
      'age': age,
    });

void main() {
  group('memberIsMale — الاستنتاج من الرقم القومي', () {
    test('خانة عشرية فردية (…5…) ⇒ ذكر', () {
      expect(memberIsMale(_member(nationalId: '29001011234557')), isTrue);
    });

    test('خانة عشرية زوجية (…6…) ⇒ أنثى', () {
      expect(memberIsMale(_member(nationalId: '29001011234567')), isFalse);
    });

    test('رقم غير صالح ⇒ `null` لا حكم خاطئ', () {
      expect(memberIsMale(_member(nationalId: '123')), isNull);
      expect(memberIsMale(_member(nationalId: '٢٩٠٠١٠١١٢٣٤٥٥٧')), isTrue);
      expect(memberIsMale(_member(nationalId: 'أرقام')), isNull);
    });
  });

  group('genderLabel', () {
    test('تسميات عربية ثابتة', () {
      expect(genderLabel(true), 'ذكر');
      expect(genderLabel(false), 'أنثى');
      expect(genderLabel(null), 'غير محدَّد');
    });
  });

  group('buildMembersCsv', () {
    test('يبدأ بـ BOM (يعرّف Excel بـ UTF-8) وترويسة الأعمدة', () {
      final String csv = buildMembersCsv(const <VillageMember>[]);
      expect(csv, startsWith('\uFEFF'));
      expect(
        csv,
        contains(
          'الاسم,التليفون,الرقم القومي,تاريخ الميلاد,السن,الجنس,تاريخ التسجيل',
        ),
      );
    });

    test('عدد السطور = عدد الأعضاء + الترويسة', () {
      final String csv = buildMembersCsv(<VillageMember>[
        _member(id: 'm1'),
        _member(id: 'm2', name: 'أحمد علي', nationalId: '29001011234567'),
        _member(id: 'm3', name: 'فاطمة حسن', nationalId: '29001011234587'),
      ]);
      // CRLF: الترويسة + ثلاثة أعضاء.
      expect('\r\n'.allMatches(csv).length, 4);
    });

    test('الجنس يُشتق في السطر نفسه', () {
      final String csv = buildMembersCsv(<VillageMember>[
        _member(id: 'm1', nationalId: '29001011234557'),
        _member(id: 'm2', nationalId: '29001011234567'),
      ]);
      expect(csv, contains('ذكر'));
      expect(csv, contains('أنثى'));
    });

    test('خانة تحوي فاصلة تُغلَّف باقتباس وفق RFC 4180', () {
      final String csv = buildMembersCsv(<VillageMember>[
        _member(name: 'علي, حسن'),
      ]);
      expect(csv, contains('"علي, حسن"'));
    });

    test('علامة الاقتباس داخل الخانة تُضاعف بين اقتباسين', () {
      final String csv = buildMembersCsv(<VillageMember>[
        _member(name: 'قال "أهلاً"'),
      ]);
      expect(csv, contains('"قال ""أهلاً"""'));
    });

    test('الترميز يحفظ العربية بـ UTF-8 فوق الـ BOM', () {
      final List<int> bytes = encodeMembersCsv(<VillageMember>[
        _member(name: 'محمد'),
      ]);
      expect(bytes[0], 0xEF);
      expect(bytes[1], 0xBB);
      expect(bytes[2], 0xBF);
      expect(utf8.decode(bytes), contains('محمد'));
    });
  });
}
