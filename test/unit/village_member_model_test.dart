import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/village/domain/national_id.dart';
import 'package:joodcraft/features/village/domain/village_member.dart';

/// اختبارات نموذج العضو: التسجيل الجديد، قراءة صف قاعدة البيانات، والإدراج.
///
/// الرقم القومي المستخدم تجريبي بالبنية الصحيحة (1990/05/12 — الدقهلية).
void main() {
  const String nid = '29005121234565';

  EgyptianNationalId parseId([String raw = nid]) {
    final NationalIdParse parse = NationalIdValidator.validate(raw);
    expect(parse.isValid, isTrue, reason: parse.message);
    return parse.value!;
  }

  group('VillageMember.newRegistration', () {
    test('يبني عضواً من بيانات النموذج + الرقم القومي', () {
      final VillageMember member = VillageMember.newRegistration(
        villageId: 'v-1',
        name: '  محمد أحمد  ',
        phone: '٠١٠١٢٣٤٥٦٧٨',
        nationalId: parseId(),
      );

      expect(member.id, isEmpty, reason: 'المعرّف يولّده السيرفر لا العميل');
      expect(member.villageId, 'v-1');
      expect(member.name, 'محمد أحمد', reason: 'الاسم يُقصّ من طرفيه');
      expect(member.phone, '01012345678', reason: 'الأرقام تُطبيع إلى لاتينية');
      expect(member.nationalId, nid);
      expect(member.birthDate, DateTime(1990, 5, 12));
      expect(member.age, parseId().age);
      expect(member.createdAt, isNull);
    });

    test('السن مشتقّ من الرقم القومي لا من إدخال المستخدم', () {
      final EgyptianNationalId id = parseId();
      final VillageMember member = VillageMember.newRegistration(
        villageId: 'v-1',
        name: 'سالم علي',
        phone: '01112345678',
        nationalId: id,
      );
      expect(member.age, id.age);
      expect(member.birthDate, id.birthDate);
    });
  });

  group('VillageMember.fromRow', () {
    test('يقرأ صفاً كاملاً بأسماء الأعمدة في SQL', () {
      final VillageMember member = VillageMember.fromRow(<String, dynamic>{
        'id': 'm-1',
        'village_id': 'v-1',
        'name': 'سالم علي',
        'phone': '01112345678',
        'national_id': nid,
        'birth_date': '1990-05-12',
        'age': 36,
        'created_at': '2026-01-05T10:00:00Z',
      });

      expect(member.id, 'm-1');
      expect(member.villageId, 'v-1');
      expect(member.name, 'سالم علي');
      expect(member.phone, '01112345678');
      expect(member.nationalId, nid);
      expect(member.birthDate, DateTime(1990, 5, 12));
      expect(member.age, 36);
      expect(member.createdAt, isNotNull);
    });

    test('الصف الناقص لا يُسقط العملية — قيم افتراضية آمنة', () {
      final VillageMember member = VillageMember.fromRow(<String, dynamic>{});
      expect(member.id, isEmpty);
      expect(member.villageId, isEmpty);
      expect(member.name, isEmpty);
      expect(member.birthDate, DateTime(1900));
      expect(member.age, 0);
      expect(member.createdAt, isNull);
    });

    test('السن يُحسب من تاريخ الميلاد إن غاب من الصف', () {
      final VillageMember member = VillageMember.fromRow(<String, dynamic>{
        'birth_date': '1990-05-12',
      });
      final int expected = NationalIdValidator.ageAt(
        DateTime(1990, 5, 12),
        DateTime.now(),
      );
      expect(member.age, expected);
      expect(member.age, greaterThan(17));
    });

    test('تاريخ على صيغة DateTime يُقرأ كما هو', () {
      final DateTime created = DateTime(2026, 2, 3, 4, 5);
      final VillageMember member = VillageMember.fromRow(<String, dynamic>{
        'created_at': created,
        'birth_date': created,
      });
      expect(member.createdAt, created);
      expect(member.birthDate, created);
    });
  });

  group('VillageMember.toRow / toJson', () {
    test('toRow يحمل أسماء الأعمدة والتاريخ بلا وقت', () {
      final VillageMember member = VillageMember.newRegistration(
        villageId: 'v-9',
        name: 'نور محمد',
        phone: '01212345678',
        nationalId: parseId(),
      );
      final Map<String, dynamic> row = member.toRow();

      expect(
        row.keys.toSet(),
        <String>{'village_id', 'name', 'phone', 'national_id', 'birth_date',
          'age'},
      );
      expect(row['village_id'], 'v-9');
      expect(row['name'], 'نور محمد');
      expect(row['phone'], '01212345678');
      expect(row['national_id'], nid);
      expect(row['birth_date'], '1990-05-12');
      expect(row['age'], member.age);
    });

    test('toJson يضيف id و created_at فقط عند وجودهما', () {
      final VillageMember bare = VillageMember.newRegistration(
        villageId: 'v-1',
        name: 'سالم علي',
        phone: '01012345678',
        nationalId: parseId(),
      );
      expect(bare.toJson().containsKey('id'), isFalse);
      expect(bare.toJson().containsKey('created_at'), isFalse);

      final VillageMember full = VillageMember.fromRow(<String, dynamic>{
        'id': 'm-7',
        'village_id': 'v-1',
        'name': 'سالم علي',
        'phone': '01012345678',
        'national_id': nid,
        'birth_date': '1990-05-12',
        'age': 36,
        'created_at': '2026-01-05T10:00:00Z',
      });
      final Map<String, dynamic> json = full.toJson();
      expect(json['id'], 'm-7');
      expect(json['created_at'], full.createdAt!.toIso8601String());
    });

    test('toString يحمل الاسم والتليفون لتسهيل التتبع', () {
      final VillageMember member = VillageMember.newRegistration(
        villageId: 'v-1',
        name: 'سالم علي',
        phone: '01012345678',
        nationalId: parseId(),
      );
      expect(member.toString(), 'VillageMember(سالم علي — 01012345678)');
    });
  });
}
