import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/village/data/village_repository.dart';
import 'package:joodcraft/features/village/domain/national_id.dart';
import 'package:joodcraft/features/village/domain/village.dart';
import 'package:joodcraft/features/village/domain/village_legal.dart';
import 'package:joodcraft/features/village/domain/village_validators.dart';
import 'package:joodcraft/features/village/domain/village_video.dart';
import 'package:joodcraft/features/village/presentation/screens/village_registration_screen.dart';
import 'package:joodcraft/features/village/presentation/village_theme.dart';
import 'package:joodcraft/features/village/presentation/widgets/village_videos_section.dart';

/// مستودع وهمي في الذاكرة: لا شبكة ولا Supabase — كله سلوك مقصود قابلاً
/// للبرمجة في كل اختبار.
class _FakeVillageRepository implements VillageRepository {
  _FakeVillageRepository({
    this.available = true,
    this.village,
    this.failRegisterWith,
    this.videos = const <VillageVideo>[],
    this.failVideos = false,
  });

  /// هل الخدمة مُهيّأة؟
  final bool available;

  /// القرية المعادة للكود الصحيح (`null` ⇒ كود غير مسجَّل).
  final Village? village;

  /// استثناء يُرمى عند التسجيل (تكرار/شبكة…).
  final VillageException? failRegisterWith;

  /// فيديوهات القرية المعادة عند كل جلب ناجح.
  final List<VillageVideo> videos;

  /// هل يُرمى جلب الفيديوهات استثناءً (جدول غير منشأ/شبكة…)؟
  final bool failVideos;

  /// سجلّ ما وصل إلى المستودع — للتحقق من التطبيع قبل الحفظ.
  final List<String> registered = <String>[];

  /// سجلّ الأكواد التي جُلبت فيديوهاتها — للتحقق من إعادة الجلب بتبدّل الكود.
  final List<String> videoRequests = <String>[];

  /// الكود الذي يُعِدّ [village] (مع التطبيع).
  static const String validCode = 'MAA-2026';

  @override
  bool get isAvailable => available;

  @override
  Future<Village?> lookupVillage(String code) async {
    final String canonical = VillageValidators.canonicalCode(code);
    if (canonical == validCode) return village;
    return null;
  }

  @override
  Future<String> registerMember({
    required String villageCode,
    required String name,
    required String phone,
    required String nationalId,
  }) async {
    final VillageException? failure = failRegisterWith;
    if (failure != null) throw failure;
    registered.add('$villageCode|$name|$phone|$nationalId');
    return 'member-1';
  }

  @override
  Future<List<VillageVideo>> fetchVideos({required String villageCode}) async {
    videoRequests.add(villageCode);
    if (failVideos) {
      throw const VillageException(
        VillageErrorKind.unknown,
        VillageText.genericError,
      );
    }
    return videos;
  }
}

/// رقم قومي صالح (1990/05/12 — الدقهلية) ومناسب لحدّ 18 سنة.
const String _validNationalId = '29005121234565';

Village _village() => const Village(
      id: 'v-1',
      name: 'منشأة الأمراء ومحلة حسن',
      code: 'MAA-2026',
    );

/// فيديو صالح بمعرّف يوتيوب — لكل اختبار عنوانه ومعرّفه.
VillageVideo _video(String id, String title) => VillageVideo(
      id: id,
      title: title,
      youtubeUrl: 'https://youtu.be/$id',
      youtubeId: id,
      description: 'وصف $title',
    );

Future<void> _pumpScreen(
  WidgetTester tester,
  _FakeVillageRepository repo, {
  String initialVillageCode = VillageText.villageCode,
}) async {
  // شاشة طويلة بما يكفي لعرض كامل التدفّق بلا تمرير إجباري.
  tester.view.physicalSize = const Size(1100, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: VillageTheme.dark,
      locale: const Locale('ar'),
      supportedLocales: const <Locale>[Locale('ar')],
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: VillageRegistrationScreen(
        repository: repo,
        initialVillageCode: initialVillageCode,
      ),
    ),
  );
  // ضربة pump إضافية قبل الاستقرار تُفرّغ جلب الفيديوهات الصامت (microtask)،
  // فلا تعتمد أي تحقّق على تسلسل الأزمنة داخل `pumpAndSettle`.
  await tester.pump();
  await tester.pumpAndSettle();
}

Future<void> _enterCodeAndSubmit(WidgetTester tester, String code) async {
  await tester.enterText(
    find.byKey(const ValueKey<String>('village-code-field')),
    code,
  );
  await tester.tap(find.byKey(const ValueKey<String>('village-code-submit')));
  await tester.pumpAndSettle();
}

/// تعبئة نموذج التسجيل والضغط على «تسجيل» (مع تفعيل الموافقة أولاً —
/// فالزر معطّل ما لم تُشَعّ الموافقة).
Future<void> _submitForm(
  WidgetTester tester, {
  required String name,
  required String phone,
  required String nationalId,
}) async {
  await tester.enterText(
    find.byKey(const ValueKey<String>('village-name-field')),
    name,
  );
  await tester.enterText(
    find.byKey(const ValueKey<String>('village-phone-field')),
    phone,
  );
  await tester.enterText(
    find.byKey(const ValueKey<String>('village-national-id-field')),
    nationalId,
  );
  await tester.pump();
  await tester.tap(
    find.byKey(const ValueKey<String>('village-terms-checkbox')),
  );
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey<String>('village-submit')));
  await tester.pumpAndSettle();
}

void main() {
  group('خطوة الكود', () {
    testWidgets('الكود بغير صيغته يُرفض محلياً بلا استعلام', (tester) async {
      final _FakeVillageRepository repo = _FakeVillageRepository();
      await _pumpScreen(tester, repo);

      expect(find.byKey(const ValueKey<String>('village-code-gate')),
          findsOneWidget);

      await _enterCodeAndSubmit(tester, 'abc');

      expect(
        find.text(
          'صيغة الكود غير صحيحة — مثال: ${VillageText.villageCode}',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey<String>('village-form')), findsNothing);
    });

    testWidgets('كود غير مسجَّل يعرض رسالة الكود غير صحيح', (tester) async {
      final _FakeVillageRepository repo = _FakeVillageRepository(
        village: _village(),
      );
      await _pumpScreen(tester, repo);

      await _enterCodeAndSubmit(tester, 'ZZZ-9999');

      expect(find.text(VillageText.codeNotFound), findsOneWidget);
    });

    testWidgets('الكود الصحيح يفتح النموذج باسم القرية', (tester) async {
      final _FakeVillageRepository repo = _FakeVillageRepository(
        village: _village(),
      );
      await _pumpScreen(tester, repo);

      // إدخال بحروف صغيرة — التطبيع (توحيد الحالة) قبل الاستعلام.
      await _enterCodeAndSubmit(tester, 'maa-2026');

      expect(find.byKey(const ValueKey<String>('village-form')), findsOneWidget);
      expect(
        find.text(VillageText.welcomeVillage(_village().name)),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey<String>('village-code-gate')),
          findsNothing);
    });
  });

  group('خطوة النموذج', () {
    testWidgets('الحقول الفارغة تُظهر أخطاء التحقق الثلاثة', (tester) async {
      final _FakeVillageRepository repo = _FakeVillageRepository(
        village: _village(),
      );
      await _pumpScreen(tester, repo);
      await _enterCodeAndSubmit(tester, 'MAA-2026');

      await _submitForm(
        tester,
        name: '',
        phone: '',
        nationalId: '',
      );

      expect(find.text('اكتب الاسم بالكامل'), findsOneWidget);
      expect(find.text('اكتب رقم التليفون'), findsOneWidget);
      expect(
        find.text(NationalIdError.empty.message),
        findsOneWidget,
      );
      expect(repo.registered, isEmpty, reason: 'لا استعلام بلا تحقق ناجح');
    });

    testWidgets('رقم قومي دون 18 سنة يُرفض قبل الإرسال', (tester) async {
      final _FakeVillageRepository repo = _FakeVillageRepository(
        village: _village(),
      );
      await _pumpScreen(tester, repo);
      await _enterCodeAndSubmit(tester, 'MAA-2026');

      // مولود 2015/01/01 ⇒ دون 18 سنة.
      await _submitForm(
        tester,
        name: 'أحمد علي',
        phone: '01012345678',
        nationalId: '31501011234565',
      );

      expect(find.text(NationalIdError.tooYoung.message), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('village-success')),
          findsNothing);
      expect(repo.registered, isEmpty);
    });

    testWidgets('تسجيل ناجح يمرّر المعطى المُطبَّع ثم يعرض بطاقة النجاح',
        (tester) async {
      final _FakeVillageRepository repo = _FakeVillageRepository(
        village: _village(),
      );
      await _pumpScreen(tester, repo);
      await _enterCodeAndSubmit(tester, 'MAA-2026');

      await _submitForm(
        tester,
        name: '  محمد أحمد عبد الله  ',
        phone: '01012345678',
        nationalId: _validNationalId,
      );

      expect(find.byKey(const ValueKey<String>('village-success')),
          findsOneWidget);
      expect(find.text(VillageText.successTitle), findsOneWidget);
      expect(
        find.text(
          VillageText.successBody('محمد أحمد عبد الله', _village().name),
        ),
        findsOneWidget,
      );

      expect(repo.registered, hasLength(1));
      expect(
        repo.registered.single,
        'MAA-2026|محمد أحمد عبد الله|01012345678|$_validNationalId',
        reason: 'الاسم يُقصّ والرقم القومي يُطبع قبل الحفظ',
      );
    });

    testWidgets('تكرار الرقم القومي يعرض الخطأ دون مغادرة النموذج',
        (tester) async {
      final _FakeVillageRepository repo = _FakeVillageRepository(
        village: _village(),
        failRegisterWith: const VillageException(
          VillageErrorKind.duplicate,
          VillageText.duplicateNationalId,
        ),
      );
      await _pumpScreen(tester, repo);
      await _enterCodeAndSubmit(tester, 'MAA-2026');

      await _submitForm(
        tester,
        name: 'محمد أحمد',
        phone: '01012345678',
        nationalId: _validNationalId,
      );

      expect(
        find.byKey(const ValueKey<String>('village-form-error')),
        findsOneWidget,
      );
      expect(find.text(VillageText.duplicateNationalId), findsWidgets);
      expect(find.byKey(const ValueKey<String>('village-form')), findsOneWidget);
    });

    testWidgets('انتهاء الكود أثناء التسجيل يُعيد لخطوة الكود', (tester) async {
      final _FakeVillageRepository repo = _FakeVillageRepository(
        village: _village(),
        failRegisterWith: const VillageException(
          VillageErrorKind.notFound,
          VillageText.codeNotFound,
        ),
      );
      await _pumpScreen(tester, repo);
      await _enterCodeAndSubmit(tester, 'MAA-2026');

      await _submitForm(
        tester,
        name: 'محمد أحمد',
        phone: '01012345678',
        nationalId: _validNationalId,
      );

      expect(find.byKey(const ValueKey<String>('village-code-gate')),
          findsOneWidget);
      expect(find.text(VillageText.codeNotFound), findsOneWidget);
    });

    testWidgets('«تسجيل فرد آخر» يفرّغ الحقول ويعيد النموذج', (tester) async {
      final _FakeVillageRepository repo = _FakeVillageRepository(
        village: _village(),
      );
      await _pumpScreen(tester, repo);
      await _enterCodeAndSubmit(tester, 'MAA-2026');
      await _submitForm(
        tester,
        name: 'محمد أحمد',
        phone: '01012345678',
        nationalId: _validNationalId,
      );
      expect(find.byKey(const ValueKey<String>('village-success')),
          findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('village-register-another')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('village-form')), findsOneWidget);
      final TextField name = tester.widget<TextField>(
        find.byKey(const ValueKey<String>('village-name-field')),
      );
      expect(name.controller!.text, isEmpty);
      expect(repo.registered, hasLength(1), reason: 'لا يُطلب إدراج ثانٍ');
    });
  });

  group('الموافقة القانونية', () {
    /// يفتح نموذج التسجيل مباشرة (كود صحيح).
    Future<void> openForm(
      WidgetTester tester,
      _FakeVillageRepository repo,
    ) async {
      await _pumpScreen(tester, repo);
      await _enterCodeAndSubmit(tester, 'MAA-2026');
    }

    testWidgets('زر التسجيل معطّل حتى تُفعَّل الموافقة ثم ينجح التسجيل',
        (tester) async {
      final _FakeVillageRepository repo = _FakeVillageRepository(
        village: _village(),
      );
      await openForm(tester, repo);

      await tester.enterText(
        find.byKey(const ValueKey<String>('village-name-field')),
        'محمد أحمد',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('village-phone-field')),
        '01012345678',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('village-national-id-field')),
        _validNationalId,
      );
      await tester.pump();

      final FilledButton before = tester.widget<FilledButton>(
        find.byKey(const ValueKey<String>('village-submit')),
      );
      expect(
        before.onPressed,
        isNull,
        reason: 'بلا موافقة يبقى الزر معطّلاً — الالتزام يسبق الإرسال',
      );
      expect(repo.registered, isEmpty);

      await tester.tap(
        find.byKey(const ValueKey<String>('village-terms-checkbox')),
      );
      await tester.pump();

      final FilledButton after = tester.widget<FilledButton>(
        find.byKey(const ValueKey<String>('village-submit')),
      );
      expect(after.onPressed, isNotNull, reason: 'الموافقة تُفعّل الزر');

      await tester.tap(find.byKey(const ValueKey<String>('village-submit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('village-success')),
          findsOneWidget);
      expect(repo.registered, hasLength(1));
    });

    testWidgets('سطر الموافقة يعرض جملة الموافقة والروابط والمربّع غير مفعّل',
        (tester) async {
      final _FakeVillageRepository repo = _FakeVillageRepository(
        village: _village(),
      );
      await openForm(tester, repo);

      final Checkbox box = tester.widget<Checkbox>(
        find.byKey(const ValueKey<String>('village-terms-checkbox')),
      );
      expect(box.value, isFalse, reason: 'يبدأ الموافقة غير مُفعَّلة');

      expect(find.text(VillageLegal.consentAgree), findsOneWidget);
      expect(find.text(VillageLegal.consentTerms), findsOneWidget);
      expect(find.text(VillageLegal.consentPrivacy), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('village-terms-link')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('village-privacy-link')),
        findsOneWidget,
      );
    });

    testWidgets('رابط «شروط الاستخدام» يفتح الصفحة ثم يعود بالرجوع',
        (tester) async {
      final _FakeVillageRepository repo = _FakeVillageRepository(
        village: _village(),
      );
      await openForm(tester, repo);

      await tester.tap(
        find.byKey(const ValueKey<String>('village-terms-link')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('village-terms')),
        findsOneWidget,
      );
      expect(find.text(VillageLegal.termsTitle), findsOneWidget);
      expect(find.text(VillageLegal.termsNoDuplicateTitle), findsOneWidget);
      expect(
        find.text(VillageLegal.versionLabel(VillageLegal.termsVersion)),
        findsOneWidget,
      );

      await tester
          .tap(find.byKey(const ValueKey<String>('village-legal-back')).first);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('village-terms')), findsNothing);
      expect(find.byKey(const ValueKey<String>('village-form')), findsOneWidget);
    });

    testWidgets('رابط «سياسة الخصوصية» يفتحها بقسم معالجة البيانات وحقّ الحذف',
        (tester) async {
      final _FakeVillageRepository repo = _FakeVillageRepository(
        village: _village(),
      );
      await openForm(tester, repo);

      await tester.tap(
        find.byKey(const ValueKey<String>('village-privacy-link')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('village-privacy-policy')),
        findsOneWidget,
      );
      expect(find.text(VillageLegal.privacyTitle), findsOneWidget);
      expect(find.text(VillageLegal.privacyCollectedTitle), findsOneWidget);
      expect(find.text(VillageLegal.privacyProcessingTitle), findsOneWidget);
      expect(find.text(VillageLegal.privacyDeletionTitle), findsOneWidget);
      expect(find.text(VillageLegal.privacySharingTitle), findsOneWidget);
      expect(
        find.text(
          VillageLegal.versionLabel(VillageLegal.privacyVersion),
        ),
        findsOneWidget,
      );

      await tester
          .tap(find.byKey(const ValueKey<String>('village-legal-back')).first);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('village-privacy-policy')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey<String>('village-form')), findsOneWidget);
    });

    testWidgets('«تسجيل فرد آخر» يُصفّر الموافقة ويعيد الزر معطّلاً',
        (tester) async {
      final _FakeVillageRepository repo = _FakeVillageRepository(
        village: _village(),
      );
      await openForm(tester, repo);
      await _submitForm(
        tester,
        name: 'محمد أحمد',
        phone: '01012345678',
        nationalId: _validNationalId,
      );
      expect(find.byKey(const ValueKey<String>('village-success')),
          findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('village-register-another')),
      );
      await tester.pumpAndSettle();

      final Checkbox box = tester.widget<Checkbox>(
        find.byKey(const ValueKey<String>('village-terms-checkbox')),
      );
      expect(box.value, isFalse, reason: 'موافقة كل فرد على حدة');
      final FilledButton submit = tester.widget<FilledButton>(
        find.byKey(const ValueKey<String>('village-submit')),
      );
      expect(submit.onPressed, isNull);
      expect(repo.registered, hasLength(1), reason: 'لا يُطلب إدراج ثانٍ');
    });
  });

  group('تخطيط الصفحة', () {
    testWidgets('العمود موسّط في شاشة عريضة وبعرض أقصى حدود', (tester) async {
      final _FakeVillageRepository repo = _FakeVillageRepository(
        village: _village(),
      );
      await _pumpScreen(tester, repo);

      final Rect page = tester.getRect(
        find.byKey(const ValueKey<String>('village-page')),
      );
      final double screen = tester.getSize(find.byType(MaterialApp)).width;

      expect(
        page.width,
        lessThanOrEqualTo(VillageMetrics.maxContentWidth),
        reason: 'لا يزيد عرض المحتوى عن الحد الأقصى',
      );
      expect(
        page.left,
        moreOrLessEquals((screen - page.width) / 2, epsilon: 1.0),
        reason: 'فرصتا اليسار واليمين متساويتان ⇒ الصفحة موسّطة',
      );
      expect(
        (screen - page.right) - page.left,
        moreOrLessEquals(0.0, epsilon: 1.0),
        reason: 'لا فراغ أكبر في جهة من الجهتين',
      );
    });

    testWidgets('الخلفية الداكنة تغطي الشاشة كاملة بلا فراغ أبيض',
        (tester) async {
      final _FakeVillageRepository repo = _FakeVillageRepository(
        village: _village(),
      );
      await _pumpScreen(tester, repo);

      // الخلفية تأتي من الثيم (scaffoldBackgroundColor) لا من Scaffold نفسه.
      final ThemeData theme = tester.widget<MaterialApp>(
        find.byType(MaterialApp),
      ).theme!;
      expect(theme.scaffoldBackgroundColor, VillageColors.background);
    });
  });

  group('فيديوهات القرية', () {
    testWidgets('عند عودة فيديوهات يظهر القسم بعناوينها وزر يوتيوب',
        (tester) async {
      final _FakeVillageRepository repo = _FakeVillageRepository(
        village: _village(),
        videos: <VillageVideo>[
          _video('aaa11111111', 'افتتاح المدرسة'),
          _video('bbb22222222', 'حصاد القرية'),
        ],
      );
      await _pumpScreen(tester, repo);

      expect(find.byType(VillageVideosSection), findsOneWidget);
      expect(find.text(VillageText.videosTitle), findsOneWidget);
      // العنوان يظهر مرتين: في المشغّل الرئيسي (المختار) وفي مصغّرته.
      expect(find.text('افتتاح المدرسة'), findsNWidgets(2));
      expect(
        find.text('حصاد القرية'),
        findsOneWidget,
        reason: 'غير المختار يظهر في الشريط فقط — المشغّل يعرض المختار وحده',
      );
      expect(
        find.byKey(const ValueKey<String>('village-video-aaa11111111')),
        findsOneWidget,
        reason: 'المشغّل الرئيسي يحمل مفتاح الفيديو المختار فلا تختلط البطاقات',
      );
      expect(
        find.byKey(const ValueKey<String>('village-video-chip-bbb22222222')),
        findsOneWidget,
        reason: 'لكل مصغّرة مفتاحها الخاص بها',
      );
      // زر يوتيوب في المشغّل الرئيسي وحده — المصغّرات للتبديل فقط.
      expect(find.text(VillageText.videosOpenOnYoutube), findsNWidgets(1));
      expect(
        repo.videoRequests,
        <String>[VillageText.villageCode],
        reason: 'جلب صامت واحد عند فتح الصفحة — لا ينتظر إدخال الكود',
      );
    });

    testWidgets('لمس مصغّرة الشريط يرفع فيديوها إلى المشغّل الرئيسي',
        (tester) async {
      final _FakeVillageRepository repo = _FakeVillageRepository(
        village: _village(),
        videos: <VillageVideo>[
          _video('aaa11111111', 'افتتاح المدرسة'),
          _video('bbb22222222', 'حصاد القرية'),
        ],
      );
      await _pumpScreen(tester, repo);

      await tester.tap(
        find.byKey(const ValueKey<String>('village-video-chip-bbb22222222')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('village-video-bbb22222222')),
        findsOneWidget,
        reason: 'المصغّرة الملوسة صارت هي المشغّل الرئيسي',
      );
      expect(
        find.byKey(const ValueKey<String>('village-video-aaa11111111')),
        findsNothing,
        reason: 'الفيديو السابق خرج من المشغّل (iframe واحد فقط دائماً)',
      );
    });

    testWidgets('القسم يظهر بعد خريطة القرية وقبل نموذج التسجيل',
        (tester) async {
      final _FakeVillageRepository repo = _FakeVillageRepository(
        village: _village(),
        videos: <VillageVideo>[_video('ccc33333333', 'فيديو القرية')],
      );
      await _pumpScreen(tester, repo);

      final double map = tester
          .getTopLeft(find.byKey(const ValueKey<String>('village-map')))
          .dy;
      final double videos = tester
          .getTopLeft(find.text(VillageText.videosTitle))
          .dy;
      final double form = tester
          .getTopLeft(find.byKey(const ValueKey<String>('village-code-gate')))
          .dy;

      expect(videos, greaterThan(map), reason: 'الخريطة أولاً');
      expect(videos, lessThan(form), reason: 'الفيديو محتوى لا نموذج');
    });

    testWidgets('بلا فيديوهات لا يُبنى القسم ولا يبقى فراغ مكانه',
        (tester) async {
      final _FakeVillageRepository repo =
          _FakeVillageRepository(village: _village());
      await _pumpScreen(tester, repo);

      expect(find.byType(VillageVideosSection), findsNothing);
      expect(find.text(VillageText.videosTitle), findsNothing);
      expect(find.byKey(const ValueKey<String>('village-code-gate')),
          findsOneWidget);
    });

    testWidgets('فشل جلب الفيديوهات يُخفي القسم ولا يعطّل الصفحة',
        (tester) async {
      final _FakeVillageRepository repo = _FakeVillageRepository(
        village: _village(),
        failVideos: true,
      );
      await _pumpScreen(tester, repo);

      expect(find.byType(VillageVideosSection), findsNothing);
      expect(find.byKey(const ValueKey<String>('village-code-gate')),
          findsOneWidget);

      // التسجيل يبقى يعمل كأن شيئاً لم يكن.
      await _enterCodeAndSubmit(tester, 'MAA-2026');
      expect(find.byKey(const ValueKey<String>('village-form')), findsOneWidget);
    });

    testWidgets('كود جديد يُعيد جلب فيديوهات قريته لا فيديوهات السابقة',
        (tester) async {
      final _FakeVillageRepository repo = _FakeVillageRepository(
        village: _village(),
        videos: <VillageVideo>[_video('ddd44444444', 'فيديو القرية')],
      );
      await _pumpScreen(tester, repo, initialVillageCode: 'AAA-2026');
      await _enterCodeAndSubmit(tester, 'MAA-2026');

      expect(
        repo.videoRequests,
        <String>['AAA-2026', VillageText.villageCode],
        reason: 'كودان مختلفان ⇒ طلبان؛ ولو تكرّر الكود لكان الطلب واحداً',
      );
    });

    testWidgets('إدخال الكود نفسه لا يكرّر جلب الفيديوهات', (tester) async {
      final _FakeVillageRepository repo =
          _FakeVillageRepository(village: _village());
      await _pumpScreen(tester, repo);
      await _enterCodeAndSubmit(tester, 'maa-2026');

      expect(repo.videoRequests, <String>[VillageText.villageCode]);
    });
  });

  group('حالة الخدمة', () {
    testWidgets('بلا مفاتيح Supabase تُعرض بطاقة التوضيح لا النموذج',
        (tester) async {
      final _FakeVillageRepository repo = _FakeVillageRepository(
        available: false,
        village: _village(),
      );
      await _pumpScreen(tester, repo);

      expect(
        find.byKey(const ValueKey<String>('village-service-unavailable')),
        findsOneWidget,
      );
      expect(find.text(VillageText.serviceTitle), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('village-code-gate')),
        findsNothing,
      );
    });
  });
}
