import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/domain/domain/domain.dart';

void main() {
  group('Domain — النموذج', () {
    test('fromRow يقرأ صفاً كاملاً', () {
      final Domain domain = Domain.fromRow(<String, dynamic>{
        'id': 'a1b2',
        'name_ar': 'منشأة الأمراء',
        'name_en': 'Maarra',
        'governorate': 'الغربية',
        'center': 'ميت غمر',
        'postal_code': '31951',
        'plus_code': '25GF+989',
        'latitude': 30.8124,
        'longitude': 31.2345,
        'code': 'maa-31951-25gf989',
        'created_at': '2026-03-01T10:00:00.000Z',
      });

      expect(domain.id, 'a1b2');
      expect(domain.nameAr, 'منشأة الأمراء');
      expect(domain.nameEn, 'Maarra');
      expect(domain.governorate, 'الغربية');
      expect(domain.center, 'ميت غمر');
      expect(domain.postalCode, '31951');
      expect(domain.plusCode, '25GF+989');
      expect(domain.latitude, 30.8124);
      expect(domain.longitude, 31.2345);
      // الكود يُطبَّع إلى لاتينية كبيرة.
      expect(domain.code, 'MAA-31951-25GF989');
      expect(domain.createdAt, DateTime.parse('2026-03-01T10:00:00.000Z'));
      expect(domain.isUsable, isTrue);
    });

    test('مناطق الأرض تُقرأ أرقاماً', () {
      final Domain domain = Domain.fromRow(<String, dynamic>{
        'id': 'x',
        'name_ar': 'نطاق',
        'name_en': 'Domain',
        'latitude': 30,
        'longitude': 31,
        'code': 'DOM-31951-25GF989',
      });
      expect(domain.latitude, 30.0);
      expect(domain.longitude, 31.0);
      expect(domain.hasCoordinates, isTrue);
    });

    test('قراءة متسامحة: صف ناقص لا يُسقِط العملية', () {
      final Domain domain = Domain.fromRow(<String, dynamic>{
        'id': 'z',
        'name_ar': '  نطاق بلا بيانات  ',
        'code': 'zzz-00000-0000',
      });

      expect(domain.nameEn, isEmpty);
      expect(domain.governorate, isEmpty);
      expect(domain.postalCode, isNull);
      expect(domain.latitude, isNull);
      expect(domain.longitude, isNull);
      expect(domain.hasCoordinates, isFalse);
      expect(domain.locationLabel, '—');
      // الاسم وحده لا يكفي — الكود مطلوب للاعتماد على الصف.
      expect(domain.isUsable, isTrue);
    });

    test('إحداثي (0,0) بلا غيره ⇒ غير محدّد', () {
      final Domain domain = Domain(
        id: 'o',
        nameAr: 'نطاق',
        nameEn: 'D',
        governorate: 'g',
        center: 'c',
        code: 'DDD-00000-0000',
        latitude: 0,
        longitude: 0,
        createdAt: DateTime(2026),
      );
      expect(domain.hasCoordinates, isFalse);
    });

    test('copyWith يبدّل المطلوب ويُبقي الباقي', () {
      final Domain base = Domain.fromRow(<String, dynamic>{
        'id': 'c1',
        'name_ar': 'أ',
        'name_en': 'A',
        'governorate': 'الغربية',
        'center': 'ميت غمر',
        'postal_code': '31951',
        'plus_code': '25GF+989',
        'latitude': 30.5,
        'longitude': 31.5,
        'code': 'AAA-31951-25GF989',
      });

      final Domain updated = base.copyWith(governorate: 'الدقهلية');

      expect(updated.id, 'c1');
      expect(updated.governorate, 'الدقهلية');
      expect(updated.nameAr, 'أ');
      expect(updated.code, 'AAA-31951-25GF989');
      expect(updated.latitude, 30.5);
      expect(updated.longitude, 31.5);
      expect(updated.postalCode, '31951');
      // الأصل لم يتغيّر.
      expect(base.governorate, 'الغربية');
    });

    test('toJson ↔ fromRow رحلة ذهاب وعودة', () {
      final Domain original = Domain.fromRow(<String, dynamic>{
        'id': 'r1',
        'name_ar': 'منشأة الأمراء',
        'name_en': 'Maarra',
        'governorate': 'الغربية',
        'center': 'ميت غمر',
        'postal_code': '31951',
        'plus_code': '25GF+989',
        'latitude': 30.8124,
        'longitude': 31.2345,
        'code': 'MAA-31951-25GF989',
        'created_at': '2026-03-01T10:00:00.000Z',
      });

      final Domain round = Domain.fromRow(original.toJson());

      expect(round.id, original.id);
      expect(round.nameAr, original.nameAr);
      expect(round.code, original.code);
      expect(round.postalCode, original.postalCode);
      expect(round.latitude, original.latitude);
      expect(round.longitude, original.longitude);
      expect(round.createdAt, original.createdAt);
    });

    test('التساوي بالمعرّف والكود', () {
      Domain build(String id) => Domain(
            id: id,
            nameAr: 'ن',
            nameEn: 'N',
            governorate: 'g',
            center: 'c',
            code: 'NNN-00000-0000',
            createdAt: DateTime(2026),
          );

      expect(build('same'), build('same'));
      expect(build('same') == build('other'), isFalse);
    });
  });
}
