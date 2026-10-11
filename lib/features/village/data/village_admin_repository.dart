/// عقد لوحة تحكم القرى — المستودع الذي تتواصل معه الشاشات، مستقلّ عن Supabase.
///
/// الفصل هنا هو ما يجعل **كل** شاشات اللوحة قابلة للاختبار بمستودع وهمي في
/// الذاكرة بلا شبكة: الشاشة تعرف `VillageAdminRepository` فقط، ولا تعرف
/// PostgREST ولا التخزين ولا Supabase Auth.
///
/// الصلاحيات مفروضة على السيرفر (سياسات RLS + دالة `is_platform_admin`)؛
/// هذه الواجهة تعكس العمليات التي يسمح بها التصميم لصاحب المكتب وحده.
library;

import 'dart:typed_data';

import '../domain/village.dart';
import '../domain/village_ad.dart';
import '../domain/village_admin_overview.dart';
import '../domain/village_member.dart';
import '../domain/village_video.dart';
import 'village_repository.dart';

/// واجهة إدارة كل القرى من مكان واحد.
abstract interface class VillageAdminRepository {
  /// هل الخدمة متاحة للاستخدام (مفاتيح مضبوطة وعميل جاهز)؟
  bool get isAvailable;

  /// هل يوجد جلسة Supabase Auth محفوظة (دخول سابق)؟
  bool get isSignedIn;

  /// يسجّل الدخول إلى Supabase Auth بريده وكلمة سره، أو يرمي
  /// [VillageException] برسالة عربية (`invalid` للبيانات الخاطئة).
  Future<void> signIn({required String email, required String password});

  /// ينهي الجلسة الحالية (صامت إن لم تكن هناك جلسة).
  Future<void> signOut();

  /// هل هذا الحساب مُصرَّحاً له بإدارة كل القرى؟ — يُستدعى بعد الدخول؛
  /// `false` يعني رفض الدخول للوحة ولو كانت بيانات الدخول صحيحة.
  Future<bool> isPlatformAdmin();

  /// كل القرى بعداداتها (نداء واحد من `admin_overview()`).
  Future<List<VillageAdminOverview>> fetchOverviews();

  /// ينشئ قرية جديدة ويعيدها، أو يرمي [VillageException] (كود مكرّر مثلاً).
  Future<Village> createVillage({required String name, required String code});

  /// أعضاء القرية (الأحدث تسجيلاً أولاً).
  Future<List<VillageMember>> fetchMembers({required String villageId});

  /// يحذف عضواً من السجل — لا يمكن التراجع.
  Future<void> deleteMember({required String memberId});

  /// كل فيديوهات القرية **بما فيها المجدولة** (اللوحة ترى ما لا تراه
  /// الصفحة العامة).
  Future<List<VillageVideo>> fetchVideos({required String villageId});

  /// يضيف فيديو جديداً أو يعدّل قائماً (`id != null`) ويعيد الصف المحفوظ —
  /// `youtube_id` يستخرج من الرابط على السيرفر، وإن غاب استُخرج في النموذج.
  Future<VillageVideo> saveVideo({
    String? id,
    required String villageId,
    required String title,
    required String youtubeUrl,
    String? description,
  });

  /// يحذف فيديو.
  Future<void> deleteVideo({required String videoId});

  /// إعلانات القرية (بما فيها الموقوفة والمنتهية).
  Future<List<VillageAd>> fetchAds({required String villageId});

  /// يضيف إعلاناً جديداً أو يعدّل قائماً (`id != null`) ويعيد الصف المحفوظ.
  Future<VillageAd> saveAd({
    String? id,
    required String villageId,
    required String title,
    String? imageUrl,
    String? contactPhone,
    String? contactUrl,
    DateTime? startsAt,
    DateTime? endsAt,
    required bool isActive,
  });

  /// يحذف إعلاناً.
  Future<void> deleteAd({required String adId});

  /// يرفع صورة إعلان إلى الدلو العام `village-ads` ويعيد رابطها العام.
  Future<String> uploadAdImage({
    required String villageId,
    required Uint8List bytes,
    required String fileName,
  });
}
