import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/owner_admin/data/owner_admin_repository.dart';
import 'package:joodcraft/features/owner_admin/domain/owner_models.dart';
import 'package:joodcraft/features/owner_admin/domain/village_code_generator.dart';
import 'package:joodcraft/features/owner_admin/presentation/owner_admin_gate_screen.dart';
import 'package:joodcraft/features/owner_admin/presentation/owner_admin_screen.dart';

/// مستودع وهمي في الذاكرة: كل سلوك لوحة المالك قابل للبرمجة بلا شبكة
/// ولا Supabase — والتوليد فيه يعكس الخوارزمية الحقيقية للمولّد والخادم.
class FakeOwnerAdminRepository implements OwnerAdminRepository {
  FakeOwnerAdminRepository({
    this.available = true,
    this.signedIn = true,
    this.isAdmin = true,
    List<OwnerVillage>? villages,
    List<OwnerLicense>? licenses,
    Map<String, int>? memberCounts,
    this.signInError,
    this.createVillageError,
    this.createLicenseError,
  }) : villages = villages ?? <OwnerVillage>[],
       licenses = licenses ?? <OwnerLicense>[],
       memberCounts = memberCounts ?? <String, int>{};

  bool available;
  bool signedIn;
  bool isAdmin;
  List<OwnerVillage> villages;
  List<OwnerLicense> licenses;
  Map<String, int> memberCounts;

  String? signInError;
  OwnerAdminException? createVillageError;
  OwnerAdminException? createLicenseError;

  /// عدد مرات فشل الجلب القادم — يُستعمل لاختبار شاشة الخطأ وإعادة المحاولة.
  int fetchVillagesFailures = 0;
  int fetchLicensesFailures = 0;

  final List<String> calls = <String>[];
  int _villageSeq = 0;

  @override
  bool get isAvailable => available;

  @override
  bool get isSignedIn => signedIn;

  @override
  Future<void> signIn({required String email, required String password}) async {
    calls.add('signIn $email');
    final String? error = signInError;
    if (error != null) throw OwnerAdminException(error);
  }

  @override
  Future<bool> isPlatformAdmin() async {
    calls.add('isPlatformAdmin');
    return isAdmin;
  }

  @override
  Future<List<OwnerVillage>> fetchVillages() async {
    calls.add('fetchVillages');
    if (fetchVillagesFailures > 0) {
      fetchVillagesFailures -= 1;
      throw const OwnerAdminException('تعذّر جلب القرى');
    }
    return List<OwnerVillage>.of(villages);
  }

  @override
  Future<Map<String, int>> fetchMemberCounts() async {
    calls.add('fetchMemberCounts');
    return Map<String, int>.of(memberCounts);
  }

  @override
  Future<String> createVillage({
    required String nameAr,
    required String nameEn,
    required String governorate,
    required String center,
    String? postalCode,
    String? plusCode,
  }) async {
    calls.add('createVillage $nameAr');
    final OwnerAdminException? error = createVillageError;
    if (error != null) throw error;
    final String code = VillageCodeGenerator.generate(
      nameEn: nameEn,
      postalCode: postalCode,
      plusCode: plusCode,
    );
    _villageSeq += 1;
    villages = <OwnerVillage>[
      ...villages,
      OwnerVillage(
        // بادئة `nv` تفصل المُنشأة عن المزروع (`v1`) فلا يتصادم المعرّف.
        id: 'nv$_villageSeq',
        name: nameAr,
        nameEn: nameEn,
        code: code,
        governorate: governorate,
        center: center,
      ),
    ];
    return code;
  }

  @override
  Future<void> updateVillage({
    required String id,
    String? name,
    String? code,
    String? governorate,
  }) async {
    calls.add('updateVillage $id');
    villages = <OwnerVillage>[
      for (final OwnerVillage village in villages)
        village.id == id
            ? village.copyWith(
                name: name,
                code: code,
                governorate: governorate,
              )
            : village,
    ];
  }

  @override
  Future<void> deleteVillage(String id) async {
    calls.add('deleteVillage $id');
    villages = villages
        .where((OwnerVillage village) => village.id != id)
        .toList(growable: false);
  }

  @override
  Future<List<OwnerLicense>> fetchLicenses() async {
    calls.add('fetchLicenses');
    if (fetchLicensesFailures > 0) {
      fetchLicensesFailures -= 1;
      throw const OwnerAdminException('تعذّر جلب التراخيص');
    }
    return List<OwnerLicense>.of(licenses);
  }

  @override
  Future<String> createLicense({
    required String villageId,
    required String subscriberName,
    required String phone,
    required int months,
  }) async {
    calls.add('createLicense $villageId $months');
    final OwnerAdminException? error = createLicenseError;
    if (error != null) throw error;
    final OwnerVillage village = villages.firstWhere(
      (OwnerVillage item) => item.id == villageId,
    );
    final String prefix = village.code.split('-').first;

    // «التسلسل التالي الشاغر» — نفس منطق دالة الخادم: يتجاوز الأكواد
    // القائمة بنفس البادئة ولا يكرّرها.
    int seq = 1;
    for (final OwnerLicense license in licenses) {
      final Match? match = RegExp(
        r'^FRH-[A-Z]+-(\d+)$',
      ).firstMatch(license.code);
      if (match != null && license.code.startsWith('FRH-$prefix-')) {
        final int existing = int.parse(match.group(1)!);
        if (existing >= seq) seq = existing + 1;
      }
    }
    final String code =
        'FRH-$prefix-${seq.toString().padLeft(3, '0')}';
    licenses = <OwnerLicense>[
      ...licenses,
      OwnerLicense(
        id: 'l${licenses.length + 1}',
        code: code,
        villageId: villageId,
        villageName: village.name,
        subscriberName: subscriberName,
        subscriberPhone: phone,
        months: months,
        isActive: false,
        createdAt: DateTime(2026, 10, 12),
      ),
    ];
    return code;
  }
}

/// قرية بذرة سريعة للاختبارات.
OwnerVillage seedVillage({
  String id = 'v1',
  String name = 'منشأة الأمراء',
  String nameEn = 'Maarra',
  String code = 'MAA-2026',
  String? governorate = 'الغربية',
  String? center = 'ميت غمر',
}) => OwnerVillage(
  id: id,
  name: name,
  nameEn: nameEn,
  code: code,
  governorate: governorate,
  center: center,
);

/// يفتح شاشة اللوحة مباشرةً (بلا بوابة) — لاختبارات التبويبين.
Future<void> pumpOwnerAdmin(
  WidgetTester tester,
  OwnerAdminRepository repository,
) async {
  await tester.pumpWidget(
    MaterialApp(home: OwnerAdminScreen(repository: repository)),
  );
  await tester.pumpAndSettle();
}

/// يفتح بوابة اللوحة — لاختبارات الصلاحية والدخول.
Future<void> pumpOwnerGate(
  WidgetTester tester,
  OwnerAdminRepository repository,
) async {
  await tester.pumpWidget(
    MaterialApp(home: OwnerAdminGateScreen(repository: repository)),
  );
  await tester.pumpAndSettle();
}
