import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/village/data/village_admin_repository.dart';
import 'package:joodcraft/features/village/data/village_repository.dart';
import 'package:joodcraft/features/village/domain/village.dart';
import 'package:joodcraft/features/village/domain/village_ad.dart';
import 'package:joodcraft/features/village/domain/village_admin_overview.dart';
import 'package:joodcraft/features/village/domain/village_admin_text.dart';
import 'package:joodcraft/features/village/domain/village_member.dart';
import 'package:joodcraft/features/village/domain/village_video.dart';
import 'package:joodcraft/features/village/presentation/admin/village_admin_detail_screen.dart';
import 'package:joodcraft/features/village/presentation/admin/village_admin_gate_screen.dart';
import 'package:joodcraft/features/village/presentation/admin/village_admin_panel_screen.dart';
import 'package:joodcraft/features/village/presentation/admin/village_ads_admin_screen.dart';
import 'package:joodcraft/features/village/presentation/admin/village_members_admin_screen.dart';
import 'package:joodcraft/features/village/presentation/admin/village_videos_admin_screen.dart';

/// مستودع وهمي في الذاكرة: كل سلوك اللوحة قابل للبرمجة بلا شبكة ولا Supabase.
class _FakeAdminRepository implements VillageAdminRepository {
  _FakeAdminRepository({
    this.available = true,
    this.signedIn = false,
    this.isAdmin = true,
    this.signInError,
    List<VillageAdminOverview>? overviews,
    List<VillageMember>? members,
    List<VillageVideo>? videos,
    List<VillageAd>? ads,
  })  : overviews = overviews ?? <VillageAdminOverview>[],
        members = members ?? <VillageMember>[],
        videos = videos ?? <VillageVideo>[],
        ads = ads ?? <VillageAd>[];

  bool available;
  bool signedIn;
  bool isAdmin;
  List<VillageAdminOverview> overviews;
  List<VillageMember> members;
  List<VillageVideo> videos;
  List<VillageAd> ads;

  String? signInError;
  final List<String> calls = <String>[];
  int _seq = 100;

  @override
  bool get isAvailable => available;

  @override
  bool get isSignedIn => signedIn;

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    calls.add('signIn $email');
    final String? error = signInError;
    if (error != null) {
      throw VillageException(VillageErrorKind.invalid, error);
    }
    signedIn = true;
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    signedIn = false;
  }

  @override
  Future<bool> isPlatformAdmin() async {
    calls.add('isPlatformAdmin');
    return isAdmin;
  }

  @override
  Future<List<VillageAdminOverview>> fetchOverviews() async =>
      List<VillageAdminOverview>.unmodifiable(overviews);

  @override
  Future<Village> createVillage({
    required String name,
    required String code,
  }) async {
    calls.add('createVillage $code');
    final String id = 'v${_seq++}';
    final Village village = Village.fromRow(<String, dynamic>{
      'id': id,
      'name': name,
      'code': code,
    });
    overviews = <VillageAdminOverview>[
      ...overviews,
      VillageAdminOverview(
        village: village,
        membersCount: 0,
        videosCount: 0,
        activeAdsCount: 0,
      ),
    ];
    return village;
  }

  @override
  Future<List<VillageMember>> fetchMembers({required String villageId}) async =>
      members;

  @override
  Future<void> deleteMember({required String memberId}) async {
    calls.add('deleteMember $memberId');
    members = members
        .where((VillageMember member) => member.id != memberId)
        .toList();
  }

  @override
  Future<List<VillageVideo>> fetchVideos({required String villageId}) async =>
      videos;

  @override
  Future<VillageVideo> saveVideo({
    String? id,
    required String villageId,
    required String title,
    required String youtubeUrl,
    String? description,
  }) async {
    final String videoId = id ?? 'vid${_seq++}';
    final VillageVideo saved = VillageVideo.fromRow(<String, dynamic>{
      'id': videoId,
      'village_id': villageId,
      'title': title,
      'youtube_url': youtubeUrl,
      'youtube_id': VillageYoutube.idFromUrl(youtubeUrl) ?? '',
      'description': description,
    });
    videos = <VillageVideo>[
      for (final VillageVideo video in videos)
        if (video.id == videoId) saved else video,
      if (id == null) saved,
    ];
    return saved;
  }

  @override
  Future<void> deleteVideo({required String videoId}) async {
    calls.add('deleteVideo $videoId');
    videos = videos
        .where((VillageVideo video) => video.id != videoId)
        .toList();
  }

  @override
  Future<List<VillageAd>> fetchAds({required String villageId}) async => ads;

  @override
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
  }) async {
    final String adId = id ?? 'ad${_seq++}';
    final VillageAd saved = VillageAd(
      id: adId,
      villageId: villageId,
      title: title,
      imageUrl: imageUrl,
      contactPhone: contactPhone,
      contactUrl: contactUrl,
      startsAt: startsAt,
      endsAt: endsAt,
      isActive: isActive,
    );
    ads = <VillageAd>[
      for (final VillageAd ad in ads)
        if (ad.id == adId) saved else ad,
      if (id == null) saved,
    ];
    return saved;
  }

  @override
  Future<void> deleteAd({required String adId}) async {
    calls.add('deleteAd $adId');
    ads = ads.where((VillageAd ad) => ad.id != adId).toList();
  }

  @override
  Future<String> uploadAdImage({
    required String villageId,
    required List<int> bytes,
    required String fileName,
  }) async =>
      'https://cdn.test/$fileName';
}

/// ملخّص قرية للاختبارات — نفس صيغة صفوف `admin_overview()`.
VillageAdminOverview _overview({
  String id = 'v1',
  String name = 'قرية النور',
  String code = 'NUR-2026',
  int members = 0,
  int videos = 0,
  int ads = 0,
}) =>
    VillageAdminOverview.fromRow(<String, dynamic>{
      'village_id': id,
      'village_name': name,
      'village_code': code,
      'members_count': members,
      'videos_count': videos,
      'active_ads_count': ads,
    });

Village _village() =>
    Village.fromRow(<String, dynamic>{'id': 'v1', 'name': 'قرية النور'});

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

VillageVideo _video({String id = 'vid1', String title = 'فيديو ترحيبي'}) =>
    VillageVideo.fromRow(<String, dynamic>{
      'id': id,
      'village_id': 'v1',
      'title': title,
      'youtube_url': 'https://youtu.be/dQw4w9WgXcQ',
      'youtube_id': 'dQw4w9WgXcQ',
    });

VillageAd _ad({String id = 'ad1', String title = 'إعلان المخبز'}) =>
    VillageAd.fromRow(<String, dynamic>{
      'id': id,
      'village_id': 'v1',
      'title': title,
      'is_active': true,
    });

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(1100, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: home));
  await tester.pumpAndSettle();
}

/// يُنهي مؤقّت رسالة SnackBar (٤ ثوانٍ) حتى لا يبقى مؤقّت معلّقاً في النهاية.
Future<void> _drainSnackbar(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  group('بوابة الدخول', () {
    testWidgets('بدون تهيئة Supabase ⇒ ملاحظة التهيئة لا النموذج', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        VillageAdminGateScreen(
          repository: _FakeAdminRepository(available: false),
        ),
      );

      expect(find.text(VillageAdminText.unavailableBody), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('village-admin-email')),
        findsNothing,
      );
    });

    testWidgets('كلمة سر خاطئة ⇒ رسالة الخطأ دون دخول', (
      WidgetTester tester,
    ) async {
      final _FakeAdminRepository fake = _FakeAdminRepository(
        signInError: VillageAdminText.invalidCredentials,
      );
      await _pump(tester, VillageAdminGateScreen(repository: fake));

      await tester.enterText(
        find.byKey(const ValueKey<String>('village-admin-email')),
        'owner@test.dev',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('village-admin-password')),
        'wrong',
      );
      await tester.tap(find.byKey(const ValueKey<String>('village-admin-submit')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('village-admin-gate-error')),
        findsOneWidget,
      );
      expect(find.text(VillageAdminText.invalidCredentials), findsOneWidget);
      expect(fake.signedIn, isFalse);
    });

    testWidgets('دخول صحيح بلا صلاحية ⇒ رفض وتسجيل خروج فوري', (
      WidgetTester tester,
    ) async {
      final _FakeAdminRepository fake = _FakeAdminRepository(isAdmin: false);
      await _pump(tester, VillageAdminGateScreen(repository: fake));

      await tester.enterText(
        find.byKey(const ValueKey<String>('village-admin-email')),
        'someone@test.dev',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('village-admin-password')),
        'secret',
      );
      await tester.tap(find.byKey(const ValueKey<String>('village-admin-submit')));
      await tester.pumpAndSettle();

      expect(find.text(VillageAdminText.notAdmin), findsOneWidget);
      expect(fake.calls, contains('signOut'));
      expect(fake.signedIn, isFalse);
    });

    testWidgets('جلسة محفوظة ومشرف ⇒ دخول مباشر إلى اللوحة', (
      WidgetTester tester,
    ) async {
      final _FakeAdminRepository fake = _FakeAdminRepository(
        signedIn: true,
        overviews: <VillageAdminOverview>[_overview()],
      );
      await _pump(tester, VillageAdminGateScreen(repository: fake));

      expect(find.text(VillageAdminText.panelTitle), findsOneWidget);
      expect(find.text('قرية النور'), findsOneWidget);
    });
  });

  group('اللوحة الرئيسية', () {
    Future<void> openPanel(WidgetTester tester, _FakeAdminRepository fake) async {
      await _pump(tester, VillageAdminGateScreen(repository: fake));
      await tester.enterText(
        find.byKey(const ValueKey<String>('village-admin-email')),
        'owner@test.dev',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('village-admin-password')),
        'secret',
      );
      await tester.tap(find.byKey(const ValueKey<String>('village-admin-submit')));
      await tester.pumpAndSettle();
    }

    testWidgets('العدّادات تجمع كل القرى', (WidgetTester tester) async {
      final _FakeAdminRepository fake = _FakeAdminRepository(
        overviews: <VillageAdminOverview>[
          _overview(members: 5, videos: 1, ads: 1),
          _overview(id: 'v2', name: 'قرية الفردوس', code: 'FRD-2026'),
        ],
      );
      await openPanel(tester, fake);

      expect(find.text(VillageAdminText.statVillages), findsOneWidget);
      expect(find.text(VillageAdminText.statMembers), findsOneWidget);
      // 5 + 0 مسجَّل — والعدّاد الثاني للقرى يعرض «2» منفصلاً.
      expect(find.text('5'), findsOneWidget);
      expect(find.text('قرية الفردوس'), findsOneWidget);
    });

    testWidgets('إضافة قرية من النافذة تُحدّث القائمة', (
      WidgetTester tester,
    ) async {
      final _FakeAdminRepository fake = _FakeAdminRepository(
        overviews: <VillageAdminOverview>[_overview()],
      );
      await openPanel(tester, fake);

      await tester.tap(
        find.byKey(const ValueKey<String>('village-admin-add-village')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('new-village-name')),
        'قرية الفتح',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('new-village-code')),
        'FTQ-2026',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('new-village-submit')),
      );
      await tester.pumpAndSettle();
      await _drainSnackbar(tester);

      expect(fake.calls, contains('createVillage FTQ-2026'));
      expect(find.text('قرية الفتح'), findsOneWidget);
    });

    testWidgets('كود غير بصيغة صحيحة يُمنع قبل الإرسال', (
      WidgetTester tester,
    ) async {
      final _FakeAdminRepository fake = _FakeAdminRepository(
        overviews: <VillageAdminOverview>[_overview()],
      );
      await openPanel(tester, fake);

      await tester.tap(
        find.byKey(const ValueKey<String>('village-admin-add-village')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('new-village-name')),
        'قرية الفتح',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('new-village-code')),
        'code',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('new-village-submit')),
      );
      await tester.pumpAndSettle();

      expect(find.text(VillageAdminText.addVillageTitle), findsOneWidget);
      expect(fake.calls, isNot(contains('createVillage code')));
    });
  });

  group('صفحة القرية والإدارة الثلاثة', () {
    testWidgets('تفاصيل القرية تعرض المداخل الثلاثة والعدّادات', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        VillageAdminDetailScreen(
          repository: _FakeAdminRepository(),
          overview: _overview(members: 5, videos: 3, ads: 1),
        ),
      );

      expect(find.text(VillageAdminText.sectionVideos), findsOneWidget);
      expect(find.text(VillageAdminText.sectionMembers), findsOneWidget);
      expect(find.text(VillageAdminText.sectionAds), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('الفيديوهات: رابط فاسد يُمنع ثم الحفظ يضيف القائمة', (
      WidgetTester tester,
    ) async {
      final _FakeAdminRepository fake = _FakeAdminRepository();
      await _pump(
        tester,
        VillageVideosAdminScreen(repository: fake, village: _village()),
      );
      expect(find.text(VillageAdminText.videosEmpty), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('add-video')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('video-title')),
        'فيديو العيد',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('video-url')),
        'هذا ليس رابطاً',
      );
      await tester.tap(find.byKey(const ValueKey<String>('video-submit')));
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('video-dialog-error')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('video-url')),
        'https://youtu.be/dQw4w9WgXcQ',
      );
      await tester.tap(find.byKey(const ValueKey<String>('video-submit')));
      await tester.pumpAndSettle();
      await _drainSnackbar(tester);

      expect(fake.videos, hasLength(1));
      expect(find.text('فيديو العيد'), findsOneWidget);
    });

    testWidgets('الفيديوهات: الحذف بتأكيد يزيل الصف', (
      WidgetTester tester,
    ) async {
      final _FakeAdminRepository fake = _FakeAdminRepository(
        videos: <VillageVideo>[_video()],
      );
      await _pump(
        tester,
        VillageVideosAdminScreen(repository: fake, village: _village()),
      );
      expect(find.text('فيديو ترحيبي'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('delete-video-vid1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(VillageAdminText.delete));
      await tester.pumpAndSettle();
      await _drainSnackbar(tester);

      expect(fake.videos, isEmpty);
      expect(find.text(VillageAdminText.videosEmpty), findsOneWidget);
    });

    testWidgets('الأعضاء: فلترة الجنس ثم البحث النصّي', (
      WidgetTester tester,
    ) async {
      final _FakeAdminRepository fake = _FakeAdminRepository(
        members: <VillageMember>[
          _member(id: 'm1', name: 'محمد أحمد'),
          _member(id: 'm2', name: 'أحمد علي', nationalId: '29001011234597'),
          _member(
            id: 'm3',
            name: 'فاطمة حسن',
            nationalId: '29001011234567',
            age: 40,
          ),
        ],
      );
      await _pump(
        tester,
        VillageMembersAdminScreen(repository: fake, village: _village()),
      );
      expect(find.byKey(const ValueKey<String>('member-m1')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('gender-female')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('member-m3')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('member-m1')), findsNothing);

      await tester.tap(find.byKey(const ValueKey<String>('gender-all')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('member-search')),
        'فاطمة',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('member-m3')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('member-m1')), findsNothing);
    });

    testWidgets('الأعضاء: حذف بتأكيد يعيد التحميل بلا العضو', (
      WidgetTester tester,
    ) async {
      final _FakeAdminRepository fake = _FakeAdminRepository(
        members: <VillageMember>[_member(id: 'm1')],
      );
      await _pump(
        tester,
        VillageMembersAdminScreen(repository: fake, village: _village()),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('delete-member-m1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(VillageAdminText.delete));
      await tester.pumpAndSettle();
      await _drainSnackbar(tester);

      expect(fake.members, isEmpty);
      expect(find.text(VillageAdminText.membersEmpty), findsOneWidget);
    });

    testWidgets('الإعلانات: إضافة إعلان جديد بلا صورة', (
      WidgetTester tester,
    ) async {
      final _FakeAdminRepository fake = _FakeAdminRepository();
      await _pump(
        tester,
        VillageAdsAdminScreen(repository: fake, village: _village()),
      );
      expect(find.text(VillageAdminText.adsEmpty), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('add-ad')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('ad-title')),
        'إعلان البقالة',
      );
      await tester.tap(find.byKey(const ValueKey<String>('ad-submit')));
      await tester.pumpAndSettle();
      await _drainSnackbar(tester);

      expect(fake.ads, hasLength(1));
      expect(find.text('إعلان البقالة'), findsOneWidget);
      // بلا صورة: أيقونة الحمل لا مصغّرة شبكة.
      expect(find.byIcon(Icons.campaign_outlined), findsWidgets);
    });

    testWidgets('الإعلانات: العنوان الفارغ يُمنع من الحفظ', (
      WidgetTester tester,
    ) async {
      final _FakeAdminRepository fake = _FakeAdminRepository(
        ads: <VillageAd>[_ad()],
      );
      await _pump(
        tester,
        VillageAdsAdminScreen(repository: fake, village: _village()),
      );

      await tester.tap(find.byKey(const ValueKey<String>('add-ad')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('ad-submit')));
      await tester.pump();

      expect(find.text(VillageAdminText.adTitleRequired), findsOneWidget);
      expect(fake.ads, hasLength(1));
    });
  });

  group('اتجاه الكتابة RTL مثبَّت لا بلغة المضيف', () {
    /// يضخّم الشاشة داخل تطبيق مضبوط على **الإنجليزية** صراحةً (LTR)، فيظهر
    /// أن اللوحة تفرض اتجاهها بنفسها ولا ترثه من لغة التطبيق — فكل نصوصها
    /// عربية ثابتة (`VillageAdminText`) بلا ترجمة.
    Future<void> pumpInEnglish(WidgetTester tester, Widget home) async {
      tester.view.physicalSize = const Size(1100, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const <Locale>[Locale('en')],
          home: home,
        ),
      );
      await tester.pumpAndSettle();
    }

    /// لوحة مفتوحة عليها قرية واحدة (حتى تظهر أزرار الإضافة).
    Widget panelWithOneVillage() => VillageAdminPanelScreen(
      repository: _FakeAdminRepository(
        overviews: <VillageAdminOverview>[_overview()],
      ),
      onSignOut: () {},
    );

    testWidgets('الشاشة: نصوصها RTL مع أن لغة التطبيق إنجليزية', (
      WidgetTester tester,
    ) async {
      await pumpInEnglish(tester, panelWithOneVillage());

      // لغة التطبيق المعتمِدة عند جذر الشجرة ⇒ LTR (قياس مقارن)...
      expect(
        Directionality.of(tester.element(find.byType(VillageAdminPanelScreen))),
        TextDirection.ltr,
      );
      // ...لكن محتوى اللوحة RTL بقرار منها لا من المضيف.
      expect(
        Directionality.of(
          tester.element(find.text(VillageAdminText.panelTitle)),
        ),
        TextDirection.rtl,
      );
    });

    testWidgets('النوافذ: RTL وهي فوق شجرة الـNavigator الجذرية', (
      WidgetTester tester,
    ) async {
      await pumpInEnglish(tester, panelWithOneVillage());

      await tester.tap(
        find.byKey(const ValueKey<String>('village-admin-add-village')),
      );
      await tester.pumpAndSettle();

      // النافذة تُبنى في الـOverlay الجذري فلا ترث اتجاه الشاشة، ولذلك
      // لُفّت بـ`VillageAdminDirection` صراحةً.
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(AlertDialog))),
        TextDirection.rtl,
      );
    });
  });
}
