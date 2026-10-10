import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/errors/app_exception.dart';
import 'package:joodcraft/core/projects/jood/jood_autosave_service.dart';
import 'package:joodcraft/core/projects/jood/jood_autosave_store.dart';
import 'package:joodcraft/features/auth/data/local_auth_repository.dart';
import 'package:joodcraft/features/auth/domain/admin_account.dart';
import 'package:joodcraft/features/auth/domain/app_user.dart';
import 'package:joodcraft/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// اختبارات **تبديل الحساب السريع (Fast Switch Admin)**:
///
/// 1. `JoodAutosaveService`: سجلّ الخدمات النشطة وتفريغ مسودّات كل المشاريع
///    المفتوحة دفعةً واحدة قبل التبديل.
/// 2. `AuthProvider.switchAccount`: استبدال الجلسة فوراً بكلمة مرور صحيحة، ورفض
///    كلمة المرور الخاطئة ببقاء الجلسة كما هي.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalAuthRepository repository;

  Future<void> seedTwoAdmins() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    repository = await LocalAuthRepository.create();
    await repository.signUpWithPassword(
      email: 'owner@jood.test',
      password: 'OwnerPass123!',
      fullName: 'المدير الرئيسي',
    );
    await repository.signUpWithPassword(
      email: 'editor@jood.test',
      password: 'EditorPass456!',
      fullName: 'المدير المساعد',
    );
  }

  // ==========================================================================
  //  سجلّ خدمات الحفظ التلقائي
  // ==========================================================================
  group('JoodAutosaveService: سجلّ الخدمات النشطة', () {
    test('الإنشاء يسجّل الخدمة، والتخلّص يزيلها', () async {
      final InMemoryJoodAutosaveStore store = InMemoryJoodAutosaveStore();
      final JoodAutosaveService service = JoodAutosaveService(
        build: () async => Uint8List.fromList(<int>[1, 2, 3]),
        store: store,
      );
      expect(JoodAutosaveService.activeServices, contains(service));
      service.dispose();
      expect(JoodAutosaveService.activeServices, isNot(contains(service)));
    });

    test('flushAll يكتب مسودّات كل الخدمات النشطة', () async {
      final InMemoryJoodAutosaveStore storeA = InMemoryJoodAutosaveStore();
      final InMemoryJoodAutosaveStore storeB = InMemoryJoodAutosaveStore();
      final JoodAutosaveService a = JoodAutosaveService(
        build: () async => Uint8List.fromList(<int>[10, 11]),
        store: storeA,
      );
      final JoodAutosaveService b = JoodAutosaveService(
        build: () async => Uint8List.fromList(<int>[20, 21]),
        store: storeB,
      );
      addTearDown(a.dispose);
      addTearDown(b.dispose);

      // كل منهما «مشروع مفتوح» لديه تعديلات لم تُكتب بعد.
      a.schedule();
      b.schedule();

      await JoodAutosaveService.flushAll();

      expect(storeA.isEmpty, isFalse, reason: 'مسودّة المشروع الأول كُتبت');
      expect(storeB.isEmpty, isFalse, reason: 'مسودّة المشروع الثاني كُتبت');
      expect(storeA.bytes, Uint8List.fromList(<int>[10, 11]));
      expect(storeB.bytes, Uint8List.fromList(<int>[20, 21]));
    });

    test('flushAll يمرّ حتى لو فشلت كتابة مسودّة واحدة', () async {
      // مخزن يرمي دائماً — يحاكي فشل كتابة القرص.
      final JoodAutosaveService broken = JoodAutosaveService(
        build: () async => Uint8List.fromList(<int>[9]),
        store: _ThrowingStore(),
      );
      final InMemoryJoodAutosaveStore good = InMemoryJoodAutosaveStore();
      final JoodAutosaveService healthy = JoodAutosaveService(
        build: () async => Uint8List.fromList(<int>[7]),
        store: good,
      );
      addTearDown(broken.dispose);
      addTearDown(healthy.dispose);

      broken.schedule();
      healthy.schedule();

      // لا يرمي أبداً (تبديل الحساب يجب أن يمرّ مهما تعذّرت مسودّة).
      await expectLater(JoodAutosaveService.flushAll(), completes);
      expect(good.isEmpty, isFalse,
          reason: 'الخدمة السليمة كتبت مسودّتها رغم تعذّر الأخرى');
    });
  });

  // ==========================================================================
  //  AuthProvider.switchAccount
  // ==========================================================================
  group('AuthProvider.switchAccount', () {
    setUp(seedTwoAdmins);

    test('كلمة مرور صحيحة ⇒ جلسة جديدة فوراً', () async {
      final AuthProvider auth = AuthProvider(repository);
      // الجلسة الأولى: المالك.
      await auth.signIn(email: 'owner@jood.test', password: 'OwnerPass123!');
      expect(auth.user?.email, 'owner@jood.test');

      // التبديل السريع إلى المساعد باسمه المحلي.
      await auth.switchAccount(
        username: 'editor',
        password: 'EditorPass456!',
      );

      expect(auth.user?.email, 'editor@jood.test');
      expect(auth.user?.displayName, 'المدير المساعد');
      // الجلسة محفوظة في المستودع نفسه (تُستعاد بعد إعادة الإنشاء).
      expect(repository.currentUser?.email, 'editor@jood.test');
    });

    test('كلمة مرور خاطئة ⇒ خطأ وبقاء الجلسة الحالية', () async {
      final AuthProvider auth = AuthProvider(repository);
      await auth.signIn(email: 'owner@jood.test', password: 'OwnerPass123!');

      await expectLater(
        auth.switchAccount(username: 'editor', password: 'wrong-pass'),
        throwsA(isA<AppException>()),
      );

      expect(auth.user?.email, 'owner@jood.test',
          reason: 'الجلسة الحالية تبقى سليمة عند الفشل');
      expect(repository.currentUser?.email, 'owner@jood.test');
    });

    test('بريد غير موجود ⇒ خطأ', () async {
      final AuthProvider auth = AuthProvider(repository);
      await auth.signIn(email: 'owner@jood.test', password: 'OwnerPass123!');

      await expectLater(
        auth.switchAccount(username: 'ghost', password: 'anything'),
        throwsA(isA<AppException>()),
      );
      expect(auth.user?.email, 'owner@jood.test');
    });

    test('التبديل يمرّ بعد تفريغ مسوّدات المشاريع المفتوحة', () async {
      // مشروع مفتوح عليه تعديلات غير مكتوبة.
      final InMemoryJoodAutosaveStore draft = InMemoryJoodAutosaveStore();
      final JoodAutosaveService openProject = JoodAutosaveService(
        build: () async => Uint8List.fromList(<int>[4, 2]),
        store: draft,
      );
      addTearDown(openProject.dispose);
      openProject.schedule();
      expect(draft.isEmpty, isTrue, reason: 'المسودّة لم تُكتب بعد (مؤجّلة)');

      final AuthProvider auth = AuthProvider(repository);
      await auth.signIn(email: 'owner@jood.test', password: 'OwnerPass123!');

      await auth.switchAccount(
        username: 'editor',
        password: 'EditorPass456!',
      );

      expect(auth.user?.email, 'editor@jood.test');
      expect(draft.isEmpty, isFalse,
          reason: 'حالة المشروع المفتوح حُفظت قبل تبديل الجلسة');
      expect(draft.bytes, Uint8List.fromList(<int>[4, 2]));
    });

    test('حقل isCurrent يتبع الجلسة بعد التبديل', () async {
      final AuthProvider auth = AuthProvider(repository);
      await auth.signIn(email: 'owner@jood.test', password: 'OwnerPass123!');
      final List<AdminAccount> before = await repository.listAdmins();
      expect(before.firstWhere((AdminAccount a) => a.isCurrent).email,
          'owner@jood.test');

      await auth.switchAccount(
        username: 'editor',
        password: 'EditorPass456!',
      );

      final List<AdminAccount> after = await repository.listAdmins();
      expect(after.firstWhere((AdminAccount a) => a.isCurrent).email,
          'editor@jood.test');
      expect(after.where((AdminAccount a) => a.isCurrent), hasLength(1),
          reason: 'حساب واحد فقط هو «الحالي» في كل وقت');
    });
  });

  // ==========================================================================
  //  المصادقة المحلية باسم المستخدم (Local Username Authentication)
  // ==========================================================================
  group('LocalAuthRepository.signInWithLocalUsername', () {
    setUp(seedTwoAdmins);

    test('اسم مستخدم مشتق من البريد + كلمة المرور الصحيحة ⇒ جلسة', () async {
      final AppUser user = await repository.signInWithLocalUsername(
        username: 'editor',
        password: 'EditorPass456!',
      );
      expect(user.email, 'editor@jood.test');
      expect(repository.currentUser?.email, 'editor@jood.test');
    });

    test('اسم المستخدم غير حسّاس لحالة الأحرف', () async {
      final AppUser user = await repository.signInWithLocalUsername(
        username: 'EDITOR',
        password: 'EditorPass456!',
      );
      expect(user.email, 'editor@jood.test');
    });

    test('اسم مستخدم مخصّص مضبوط عند الإنشاء', () async {
      await repository.createAdmin(
        email: 'sub@jood.test',
        password: 'SubPass789!',
        fullName: 'أدمن فرعي',
        username: 'far3_1',
      );
      final AppUser user = await repository.signInWithLocalUsername(
        username: 'far3_1',
        password: 'SubPass789!',
      );
      expect(user.email, 'sub@jood.test');
    });

    test('كلمة مرور خاطئة ⇒ خطأ بلا تغيير الجلسة', () async {
      await repository.signInWithLocalUsername(
        username: 'owner',
        password: 'OwnerPass123!',
      );
      await expectLater(
        repository.signInWithLocalUsername(
          username: 'editor',
          password: 'wrong',
        ),
        throwsA(isA<AppException>()),
      );
      expect(repository.currentUser?.email, 'owner@jood.test');
    });

    test('اسم مستخدم غير موجود ⇒ خطأ', () async {
      await expectLater(
        repository.signInWithLocalUsername(
          username: 'ghost',
          password: 'anything',
        ),
        throwsA(isA<AppException>()),
      );
    });

    test('رفض اسم مستخدم مكرّر عند الإنشاء', () async {
      await expectLater(
        repository.createAdmin(
          email: 'copy@jood.test',
          password: 'CopyPass123!',
          fullName: 'مكرر',
          username: 'editor',
        ),
        throwsA(isA<AppException>()),
      );
    });

    test('AuthProvider يعرض التبديل المحلي كمُتاح', () async {
      final AuthProvider auth = AuthProvider(repository);
      expect(auth.isLocalSwitchAvailable, isTrue);
    });

    test('مخزن لا يدعم المصادقة المحلية ⇒ التبديل يُرفض', () async {
      final AuthProvider auth = AuthProvider(null);
      expect(auth.isLocalSwitchAvailable, isFalse);
      await expectLater(
        auth.switchAccount(username: 'editor', password: 'EditorPass456!'),
        throwsA(isA<AppException>()),
      );
    });
  });
}

/// مخزن يرمي دائماً — يحاكي فشل كتابة المسودّة على القرص.
class _ThrowingStore implements JoodAutosaveStore {
  @override
  Future<void> write(Uint8List bytes) async => throw StateError('disk full');

  @override
  Future<Uint8List?> read() async => null;

  @override
  Future<void> delete() async {}
}
