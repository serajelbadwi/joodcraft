import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/features/owner_admin/data/owner_admin_repository.dart';
import 'package:joodcraft/features/owner_admin/domain/owner_models.dart';
import 'package:joodcraft/features/owner_admin/domain/domain_code_generator.dart';
import 'package:joodcraft/features/owner_admin/presentation/owner_admin_gate_screen.dart';
import 'package:joodcraft/features/owner_admin/presentation/owner_admin_screen.dart';

/// مستودع وهمي في الذاكرة: كل سلوك لوحة المالك قابل للبرمجة بلا شبكة
/// ولا Supabase — والتوليد فيه يعكس الخوارزمية الحقيقية للمولّد والخادم.
class FakeOwnerAdminRepository implements OwnerAdminRepository {
  FakeOwnerAdminRepository({
    this.available = true,
    this.signedIn = true,
    this.isAdmin = true,
    List<OwnerDomain>? domains,
    List<OwnerLicense>? licenses,
    Map<String, int>? memberCounts,
    this.signInError,
    this.createDomainError,
    this.createLicenseError,
  }) : domains = domains ?? <OwnerDomain>[],
       licenses = licenses ?? <OwnerLicense>[],
       memberCounts = memberCounts ?? <String, int>{};

  bool available;
  bool signedIn;
  bool isAdmin;
  List<OwnerDomain> domains;
  List<OwnerLicense> licenses;
  Map<String, int> memberCounts;

  String? signInError;
  OwnerAdminException? createDomainError;
  OwnerAdminException? createLicenseError;

  /// عدد مرات فشل الجلب القادم — يُستعمل لاختبار شاشة الخطأ وإعادة المحاولة.
  int fetchDomainsFailures = 0;
  int fetchLicensesFailures = 0;

  final List<String> calls = <String>[];
  int _domainSeq = 0;

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
  Future<List<OwnerDomain>> fetchDomains() async {
    calls.add('fetchDomains');
    if (fetchDomainsFailures > 0) {
      fetchDomainsFailures -= 1;
      throw const OwnerAdminException('تعذّر جلب النطاقات');
    }
    return List<OwnerDomain>.of(domains);
  }

  @override
  Future<Map<String, int>> fetchMemberCounts() async {
    calls.add('fetchMemberCounts');
    return Map<String, int>.of(memberCounts);
  }

  @override
  Future<String> createDomain({
    required String nameAr,
    required String nameEn,
    required String governorate,
    required String center,
    String? postalCode,
    String? plusCode,
  }) async {
    calls.add('createDomain $nameAr');
    final OwnerAdminException? error = createDomainError;
    if (error != null) throw error;
    final String code = DomainCodeGenerator.generate(
      nameEn: nameEn,
      postalCode: postalCode,
      plusCode: plusCode,
    );
    _domainSeq += 1;
    domains = <OwnerDomain>[
      ...domains,
      OwnerDomain(
        // بادئة `nv` تفصل المُنشأة عن المزروع (`v1`) فلا يتصادم المعرّف.
        id: 'nv$_domainSeq',
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
  Future<void> updateDomain({
    required String id,
    String? name,
    String? code,
    String? governorate,
  }) async {
    calls.add('updateDomain $id');
    domains = <OwnerDomain>[
      for (final OwnerDomain domain in domains)
        domain.id == id
            ? domain.copyWith(
                name: name,
                code: code,
                governorate: governorate,
              )
            : domain,
    ];
  }

  @override
  Future<void> deleteDomain(String id) async {
    calls.add('deleteDomain $id');
    domains = domains
        .where((OwnerDomain domain) => domain.id != id)
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
    required String domainId,
    required String subscriberName,
    required String phone,
    required int months,
  }) async {
    calls.add('createLicense $domainId $months');
    final OwnerAdminException? error = createLicenseError;
    if (error != null) throw error;
    final OwnerDomain domain = domains.firstWhere(
      (OwnerDomain item) => item.id == domainId,
    );
    final String prefix = domain.code.split('-').first;

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
        domainId: domainId,
        domainName: domain.name,
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

/// نطاق بذرة سريعة للاختبارات.
OwnerDomain seedDomain({
  String id = 'v1',
  String name = 'منشأة الأمراء',
  String nameEn = 'Maarra',
  String code = 'MAA-2026',
  String? governorate = 'الغربية',
  String? center = 'ميت غمر',
}) => OwnerDomain(
  id: id,
  name: name,
  nameEn: nameEn,
  code: code,
  governorate: governorate,
  center: center,
);

/// يفتح شاشة اللوحة مباشرةً (بلا بوابة) — لاختبارات التبويبين.
///
/// [brightness] يضبط المظهر: فاتح افتراضياً (يوافق بقيّة اختبارات اللوحة
/// التي لا تعنى بالثيم)، وداكن لاختبارات الوضع الليلي.
Future<void> pumpOwnerAdmin(
  WidgetTester tester,
  OwnerAdminRepository repository, {
  Brightness brightness = Brightness.light,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      home: OwnerAdminScreen(repository: repository),
    ),
  );
  await tester.pumpAndSettle();
}

/// يفتح بوابة اللوحة — لاختبارات الصلاحية والدخول.
///
/// [brightness] مثل [pumpOwnerAdmin]: يضبط المظهر فاتحاً أو داكناً.
Future<void> pumpOwnerGate(
  WidgetTester tester,
  OwnerAdminRepository repository, {
  Brightness brightness = Brightness.light,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      home: OwnerAdminGateScreen(repository: repository),
    ),
  );
  await tester.pumpAndSettle();
}
