import 'package:joodcraft/features/domain/data/domain_repository.dart';
import 'package:joodcraft/features/domain/domain/domain.dart';
import 'package:joodcraft/features/domain/domain/domain_code_generator.dart';

/// مستودع نطاقات وهمي في الذاكرة — بلا شبكة ولا Supabase.
///
/// التوليد فيه يطابق خوارزمية المولّد (ومن ثمّ خادم القاعدة)، فيختبر
/// التدفّق كاملاً بما فيه «التصادم ⇒ رقم محاولة».
class FakeDomainRepository implements DomainRepository {
  FakeDomainRepository({
    this.available = true,
    List<Domain>? domains,
    this.createError,
    this.deleteError,
  }) : domains = domains ?? <Domain>[],
       _seq = domains?.length ?? 0;

  bool available;
  List<Domain> domains;

  DomainAdminException? createError;
  DomainAdminException? deleteError;
  int _seq;

  int fetchFailures = 0;

  final List<String> calls = <String>[];

  /// آخر معاملات `createDomain` — للتحقق من الإحداثيات الممرَّرة.
  double? lastLatitude;
  double? lastLongitude;

  @override
  bool get isAvailable => available;

  @override
  Future<List<Domain>> fetchDomains() async {
    calls.add('fetchDomains');
    if (fetchFailures > 0) {
      fetchFailures -= 1;
      throw const DomainAdminException('تعذّر جلب النطاقات');
    }
    return List<Domain>.of(domains);
  }

  @override
  Future<String> createDomain({
    required String nameAr,
    required String nameEn,
    required String governorate,
    required String center,
    String? postalCode,
    String? plusCode,
    double? latitude,
    double? longitude,
  }) async {
    calls.add('createDomain $nameAr');
    final DomainAdminException? error = createError;
    if (error != null) throw error;

    lastLatitude = latitude;
    lastLongitude = longitude;

    String code = DomainCodeGenerator.generate(
      nameEn: nameEn,
      postalCode: postalCode,
      plusCode: plusCode,
    );
    // «المحاولة التالية» عند التكرار — نفس منطق دالة القاعدة (حتى 99).
    int attempt = 0;
    while (domains.any((Domain item) => item.code == code)) {
      attempt += 1;
      if (attempt > 99) {
        throw const DomainAdminException(
          'تعذّر توليد كود فريد — جرّب رمزاً بريدياً أو Plus Code آخر',
        );
      }
      code = '$code$attempt';
    }

    _seq += 1;
    domains = <Domain>[
      ...domains,
      Domain(
        id: 'd$_seq',
        nameAr: nameAr,
        nameEn: nameEn,
        code: code,
        governorate: governorate,
        center: center,
        postalCode: postalCode,
        plusCode: plusCode,
        latitude: latitude,
        longitude: longitude,
        createdAt: DateTime(2026),
      ),
    ];
    return code;
  }

  @override
  Future<void> updateDomain({
    required String id,
    String? nameAr,
    String? governorate,
  }) async {
    calls.add('updateDomain $id');
    domains = <Domain>[
      for (final Domain domain in domains)
        domain.id == id
            ? domain.copyWith(nameAr: nameAr, governorate: governorate)
            : domain,
    ];
  }

  @override
  Future<void> deleteDomain(String id) async {
    calls.add('deleteDomain $id');
    final DomainAdminException? error = deleteError;
    if (error != null) throw error;
    domains = domains
        .where((Domain domain) => domain.id != id)
        .toList(growable: false);
  }
}

/// نطاق بذرة سريعة للاختبارات — بمثال المهمة `MAA-31951-25GF989`.
Domain seedDomain({
  String id = 'd1',
  String nameAr = 'منشأة الأمراء',
  String nameEn = 'Maarra',
  String code = 'MAA-31951-25GF989',
  String governorate = 'الغربية',
  String center = 'ميت غمر',
  String? postalCode = '31951',
  String? plusCode = '25GF+989',
  double? latitude = 30.8124,
  double? longitude = 31.2345,
}) => Domain(
  id: id,
  nameAr: nameAr,
  nameEn: nameEn,
  code: code,
  governorate: governorate,
  center: center,
  postalCode: postalCode,
  plusCode: plusCode,
  latitude: latitude,
  longitude: longitude,
  createdAt: DateTime(2026),
);
