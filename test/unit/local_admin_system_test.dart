import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/audit/export_audit_log.dart';
import 'package:joodcraft/core/errors/app_error_code.dart';
import 'package:joodcraft/core/errors/app_exception.dart';
import 'package:joodcraft/features/auth/data/admin_config_cipher.dart';
import 'package:joodcraft/features/auth/data/local_auth_repository.dart';
import 'package:joodcraft/features/auth/data/password_hashing.dart';
import 'package:joodcraft/features/auth/data/pbkdf2.dart';
import 'package:joodcraft/features/auth/domain/admin_account.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// اختبارات **نظام إدارة المديرين المحلي**: التقطير المفتاحي، تجزئة كلمات
/// المرور، عمليات الحسابات، النقل المشفّر بين الأجهزة، وسجل التصدير.
///
/// ملف مستقلّ عن واجهة المحرّر عن قصد: يتحقّق من الطبقة المحلية وحدها.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String hex(List<int> bytes) =>
      bytes.map((int b) => b.toRadixString(16).padLeft(2, '0')).join();

  // ==========================================================================
  //  PBKDF2
  // ==========================================================================
  group('PBKDF2-HMAC-SHA256', () {
    test('يطابق المتجهات المعيارية المعروفة', () {
      final List<int> password = utf8.encode('password');
      final List<int> salt = utf8.encode('salt');

      expect(
        hex(Pbkdf2.deriveKey(
          password: password,
          salt: salt,
          iterations: 1,
          keyLength: 32,
        )),
        '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
      );
      expect(
        hex(Pbkdf2.deriveKey(
          password: password,
          salt: salt,
          iterations: 2,
          keyLength: 32,
        )),
        'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43',
      );
      expect(
        hex(Pbkdf2.deriveKey(
          password: password,
          salt: salt,
          iterations: 4096,
          keyLength: 32,
        )),
        'c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a',
      );
    });

    test('ملح مختلف ⇒ مفتاح مختلف، وكلمة مختلفة ⇒ مفتاح مختلف', () {
      final Uint8ListLike a = _key('secret', 'salt-a');
      final Uint8ListLike b = _key('secret', 'salt-b');
      final Uint8ListLike c = _key('secrez', 'salt-a');
      expect(a.bytes, isNot(equals(b.bytes)));
      expect(a.bytes, isNot(equals(c.bytes)));
    });

    test('طول المفتاح المطلوب محترم، والعدد غير الصالح يُرفض', () {
      expect(
        Pbkdf2.deriveKey(
          password: utf8.encode('p'),
          salt: utf8.encode('s'),
          iterations: 2,
          keyLength: 20,
        ).length,
        20,
      );
      expect(
        () => Pbkdf2.deriveKey(
          password: utf8.encode('p'),
          salt: utf8.encode('s'),
          iterations: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('المقارنة ثابتة الزمن تُقرّ بالتساوي وترفض أي اختلاف', () {
      expect(Pbkdf2.constantTimeEquals(<int>[1, 2, 3], <int>[1, 2, 3]), isTrue);
      expect(Pbkdf2.constantTimeEquals(<int>[1, 2, 3], <int>[1, 2, 4]), isFalse);
      expect(Pbkdf2.constantTimeEquals(<int>[1, 2], <int>[1, 2, 3]), isFalse);
    });

    test('البايتات العشوائية لا تتكرّر', () {
      final List<String> seen = <String>{
        hex(Pbkdf2.randomBytes(16)),
        hex(Pbkdf2.randomBytes(16)),
        hex(Pbkdf2.randomBytes(16)),
      }.toList();
      expect(seen, hasLength(3));
      expect(Pbkdf2.randomBytes(16), hasLength(16));
    });
  });

  // ==========================================================================
  //  تجزئة كلمات المرور
  // ==========================================================================
  group('PasswordHasher', () {
    test('البصمة تحمل صيغتها ومعاملاتها ولا تكشف كلمة المرور', () {
      final String stored = PasswordHasher.hash('Passw0rd!', iterations: 1000);
      expect(stored.startsWith('pbkdf2_sha256\$1000\$'), isTrue);
      expect(stored.contains('Passw0rd!'), isFalse);
      expect(PasswordHasher.isModernHash(stored), isTrue);
      expect(stored.split(r'$'), hasLength(4));
    });

    test('التحقّق: صحيحة/خاطئة/بلا بصمة', () {
      final String stored = PasswordHasher.hash('Passw0rd!', iterations: 1000);
      expect(
        PasswordHasher.verify('Passw0rd!', stored),
        PasswordVerification.match,
      );
      expect(
        PasswordHasher.verify('passw0rd!', stored),
        PasswordVerification.mismatch,
      );
      expect(
        PasswordHasher.verify('anything', null),
        PasswordVerification.mismatch,
      );
      expect(
        PasswordHasher.verify('anything', 'لا شيء هنا'),
        PasswordVerification.mismatch,
      );
      expect(
        PasswordHasher.verify('x', 'pbkdf2_sha256\$abc\$xx\$yy'),
        PasswordVerification.mismatch,
      );
    });

    test('بصمة SHA-256 القديمة تُقبل وتُطلب ترقيتها', () {
      // sha256('legacy') — بصمة قديمة كما كان يكتبها الإصدار السابق.
      const String legacyHash =
          '1d7b4d0b2d0a1f6c0d0e6f4b0e0e5f9b1f6b6e0b0c0b0b0b0b0b0b0b0b0b0b0b';
      // نُولّد البصمة فعلاً حتى لا يعتمد الاختبار على ثابت مخمّن.
      const String password = 'legacy-pass';
      final String realLegacy = _sha256Hex(password);
      expect(
        PasswordHasher.verify(password, realLegacy),
        PasswordVerification.needsUpgrade,
      );
      expect(
        PasswordHasher.verify(password, legacyHash),
        PasswordVerification.mismatch,
      );
    });

    test('ملح مختلف لكلمتين متطابقتين ⇒ بصمتان مختلفتان', () {
      final String a = PasswordHasher.hash('same', iterations: 500);
      final String b = PasswordHasher.hash('same', iterations: 500);
      expect(a, isNot(equals(b)));
      expect(
        PasswordHasher.verify('same', a),
        PasswordVerification.match,
      );
      expect(
        PasswordHasher.verify('same', b),
        PasswordVerification.match,
      );
    });
  });

  // ==========================================================================
  //  المغلّف المشفّر
  // ==========================================================================
  group('AdminConfigCipher', () {
    const String payload = '{"format":"joodcraft.admin-config","accounts":[]}';

    test('دورة تشفير/فكّ تعيد النصّ نفسه', () {
      final String code = AdminConfigCipher.encrypt(
        payload: payload,
        passphrase: 'top-secret',
        iterationsOverride: 1000,
      );
      expect(code.startsWith('${AdminConfigCipher.header}.'), isTrue);
      // ٦ أجزاء: الوسم + عدد الدورات + الملح + الرقم + المشفّر + وسم المصادقة.
      expect(code.split('.'), hasLength(6));
      expect(code.split('.')[1], '1000');
      expect(AdminConfigCipher.looksLikeCode(code), isTrue);
      expect(
        AdminConfigCipher.decrypt(code: code, passphrase: 'top-secret'),
        payload,
      );
      // تلتفّ بياض الأسطر التي يضيفها النسخ من ملف نصّي.
      expect(
        AdminConfigCipher.decrypt(
          code: '  ${code.replaceAll('.', '.\n')}  ',
          passphrase: 'top-secret',
        ),
        payload,
      );
    });

    test('عبارة مرور خاطئة تُرفض بخطأ اعتماد لا بفكّ خاطئ', () {
      final String code = AdminConfigCipher.encrypt(
        payload: payload,
        passphrase: 'right-pass',
        iterationsOverride: 1000,
      );
      expect(
        () => AdminConfigCipher.decrypt(code: code, passphrase: 'wrong-pass'),
        throwsA(
          isA<AppException>().having(
            (AppException e) => e.code,
            'code',
            AppErrorCode.invalidCredentials,
          ),
        ),
      );
    });

    test('أي تعديل بايت في الشفرة يُكشف (Encrypt-then-MAC)', () {
      final String code = AdminConfigCipher.encrypt(
        payload: payload,
        passphrase: 'right-pass',
        iterationsOverride: 1000,
      );
      final List<String> parts = code.split('.');
      final String tamperedCipher = parts[4].startsWith('A')
          ? 'B${parts[4].substring(1)}'
          : 'A${parts[4].substring(1)}';
      final String tampered = <String>[
        parts[0],
        parts[1],
        parts[2],
        parts[3],
        tamperedCipher,
        parts[5],
      ].join('.');
      expect(
        () => AdminConfigCipher.decrypt(
          code: tampered,
          passphrase: 'right-pass',
        ),
        throwsA(isA<AppException>()),
      );
    });

    test('شفرة مشوّهة أو من إصدار آخر تُرفض بخطأ تحقّق', () {
      expect(
        () => AdminConfigCipher.decrypt(code: 'nope', passphrase: 'whatever'),
        throwsA(
          isA<AppException>().having(
            (AppException e) => e.code,
            'code',
            AppErrorCode.validation,
          ),
        ),
      );
      expect(
        () => AdminConfigCipher.decrypt(
          code: 'JCAC9.a.b.c.d',
          passphrase: 'whatever',
        ),
        throwsA(isA<AppException>()),
      );
    });

    test('عبارة المرور القصيرة تُرفض عند التصدير', () {
      expect(
        () => AdminConfigCipher.encrypt(payload: payload, passphrase: '123'),
        throwsA(
          isA<AppException>().having(
            (AppException e) => e.code,
            'code',
            AppErrorCode.weakPassword,
          ),
        ),
      );
    });
  });

  // ==========================================================================
  //  المستودع المحلي: حسابات ومصادقة وإدارة
  // ==========================================================================
  group('LocalAuthRepository', () {
    late LocalAuthRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      repository = LocalAuthRepository(
        sharedPreferences: await SharedPreferences.getInstance(),
      );
    });

    test('أول حساب يصبح «مديراً رئيسياً» والتالي «مدير»، ويُخزَّن ببصمة PBKDF2',
        () async {
      await repository.signUpWithPassword(
        email: 'owner@joodcraft.dev',
        password: 'Owner!2345',
        fullName: 'المدير الرئيسي',
      );
      final AdminAccount created = await repository.createAdmin(
        email: 'admin@joodcraft.dev',
        password: 'Admin!2345',
        fullName: 'مدير فرع',
      );

      final List<AdminAccount> admins = await repository.listAdmins();
      expect(admins, hasLength(2));
      // الرئيسي في المقدمة دائماً.
      expect(admins.first.email, 'owner@joodcraft.dev');
      expect(admins.first.role, AdminRole.owner);
      expect(created.role, AdminRole.admin);

      // كلمة المرور لم تُخزَّن أبداً، والبصمة بالصيغة الحديثة.
      final String raw = (await SharedPreferences.getInstance())
              .getString('joodcraft.local_auth_accounts.v1') ??
          '';
      expect(raw.contains('Owner!2345'), isFalse);
      expect(raw.contains('pbkdf2_sha256'), isTrue);
      expect(raw.contains('pbkdf2_sha256\$100000\$'), isTrue);
    });

    test('الدخول يتحقّق من البصمة ويرفض الخطأ، والجلسة تُستعاد', () async {
      await repository.signUpWithPassword(
        email: 'owner@joodcraft.dev',
        password: 'Owner!2345',
        fullName: 'المدير الرئيسي',
      );
      await repository.signOut();
      expect(repository.currentUser, isNull);

      await expectLater(
        repository.signInWithPassword(
          email: 'owner@joodcraft.dev',
          password: 'wrong-pass',
        ),
        throwsA(
          isA<AppException>().having(
            (AppException e) => e.code,
            'code',
            AppErrorCode.invalidCredentials,
          ),
        ),
      );

      final user = await repository.signInWithPassword(
        email: 'OWNER@joodcraft.dev',
        password: 'Owner!2345',
      );
      expect(user.email, 'owner@joodcraft.dev');
      expect(repository.currentUser?.id, user.id);
    });

    test('ترحيل البصمة القديمة يقع عند أول دخول ناجح', () async {
      // نزرع حساباً بصيغة قديمة (sha256 مفرد) كما كان الإصدار السابق.
      const String email = 'legacy@joodcraft.dev';
      final Map<String, dynamic> legacyAccount = <String, dynamic>{
        'id': 'local_legacy',
        'email': email,
        'passwordHash': _sha256Hex('Legacy!2345'),
        'fullName': 'حساب قديم',
        'organizationName': null,
        'role': 'admin',
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': null,
      };
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'joodcraft.local_auth_accounts.v1',
        jsonEncode(<String, String>{email: jsonEncode(legacyAccount)}),
      );

      await repository.signInWithPassword(
        email: email,
        password: 'Legacy!2345',
      );

      final String raw =
          prefs.getString('joodcraft.local_auth_accounts.v1') ?? '';
      expect(raw.contains('pbkdf2_sha256'), isTrue);
      expect(raw.contains(_sha256Hex('Legacy!2345')), isFalse);
    });

    test('إنشاء مدير: يرفض التكرار والبريد غير الصالح وكلمة المرور الضعيفة',
        () async {
      await repository.signUpWithPassword(
        email: 'owner@joodcraft.dev',
        password: 'Owner!2345',
        fullName: 'المدير الرئيسي',
      );

      await expectLater(
        repository.createAdmin(
          email: 'not-an-email',
          password: 'Admin!2345',
          fullName: 'مدير',
        ),
        throwsA(isA<AppException>().having(
          (AppException e) => e.code,
          'code',
          AppErrorCode.validation,
        )),
      );
      await expectLater(
        repository.createAdmin(
          email: 'owner@joodcraft.dev',
          password: 'Admin!2345',
          fullName: 'مدير',
        ),
        throwsA(isA<AppException>().having(
          (AppException e) => e.code,
          'code',
          AppErrorCode.emailAlreadyInUse,
        )),
      );
      await expectLater(
        repository.createAdmin(
          email: 'weak@joodcraft.dev',
          password: '123',
          fullName: 'مدير',
        ),
        throwsA(isA<AppException>().having(
          (AppException e) => e.code,
          'code',
          AppErrorCode.weakPassword,
        )),
      );
    });

    test('تعديل البيانات يحدّث الجلسة، وتغيير كلمة المرور يحترم الحالية',
        () async {
      final AppUserLike owner = await _signUpOwner(repository);

      await repository.updateAdminProfile(
        id: owner.id,
        fullName: 'الاسم الجديد',
        organizationName: 'مؤسسة النور',
      );
      expect(repository.currentUser?.fullName, 'الاسم الجديد');
      expect(repository.currentUser?.organizationName, 'مؤسسة النور');

      // تغيير كلمة مرورك يتطلّب الحالية.
      await expectLater(
        repository.setAdminPassword(
          id: owner.id,
          newPassword: 'NewPass!2345',
        ),
        throwsA(isA<AppException>().having(
          (AppException e) => e.code,
          'code',
          AppErrorCode.validation,
        )),
      );
      await expectLater(
        repository.setAdminPassword(
          id: owner.id,
          newPassword: 'NewPass!2345',
          currentPassword: 'Wrong!2345',
        ),
        throwsA(isA<AppException>().having(
          (AppException e) => e.code,
          'code',
          AppErrorCode.invalidCredentials,
        )),
      );
      await repository.setAdminPassword(
        id: owner.id,
        newPassword: 'NewPass!2345',
        currentPassword: 'Owner!2345',
      );
      await repository.signOut();
      final user = await repository.signInWithPassword(
        email: 'owner@joodcraft.dev',
        password: 'NewPass!2345',
      );
      expect(user.id, owner.id);
    });

    test('مدير آخر يمكنه إعادة تعيين كلمة مرور زميله', () async {
      await _signUpOwner(repository);
      final AdminAccount colleague = await repository.createAdmin(
        email: 'admin@joodcraft.dev',
        password: 'Admin!2345',
        fullName: 'مدير فرع',
      );
      await repository.setAdminPassword(
        id: colleague.id,
        newPassword: 'Reset!2345',
      );
      await repository.signOut();
      final user = await repository.signInWithPassword(
        email: 'admin@joodcraft.dev',
        password: 'Reset!2345',
      );
      expect(user.id, colleague.id);
    });

    test('لا يُحذف الحساب الحالي ولا يُجرَّد الرئيسي من رتبته', () async {
      final AppUserLike owner = await _signUpOwner(repository);

      await expectLater(
        repository.deleteAdmin(owner.id),
        throwsA(isA<AppException>().having(
          (AppException e) => e.code,
          'code',
          AppErrorCode.permissionDenied,
        )),
      );
      await expectLater(
        repository.updateAdminProfile(
          id: owner.id,
          fullName: 'المدير الرئيسي',
          role: AdminRole.admin,
        ),
        throwsA(isA<AppException>().having(
          (AppException e) => e.code,
          'code',
          AppErrorCode.permissionDenied,
        )),
      );

      final AdminAccount other = await repository.createAdmin(
        email: 'admin@joodcraft.dev',
        password: 'Admin!2345',
        fullName: 'مدير فرع',
      );
      await repository.deleteAdmin(other.id);
      expect(await repository.listAdmins(), hasLength(1));
    });
  });

  // ==========================================================================
  //  النقل بين الأجهزة
  // ==========================================================================
  group('نقل الحسابات بين أجهزة محلية', () {
    test('جهاز ثانٍ يستورد الحسابات ويعمل بنفس كلمات المرور والصلاحيات',
        () async {
      // الجهاز الأول: رئيسي + مدير.
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final LocalAuthRepository deviceA = LocalAuthRepository(
        sharedPreferences: await SharedPreferences.getInstance(),
      );
      await deviceA.signUpWithPassword(
        email: 'owner@joodcraft.dev',
        password: 'Owner!2345',
        fullName: 'المدير الرئيسي',
      );
      await deviceA.createAdmin(
        email: 'admin@joodcraft.dev',
        password: 'Admin!2345',
        fullName: 'مدير فرع',
        organizationName: 'مؤسسة النور',
      );

      final String code = await deviceA.exportAdminConfig(
        passphrase: 'transfer-pass',
      );

      // الجهاز الثاني: مخزن مستقلّ تماماً.
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final LocalAuthRepository deviceB = LocalAuthRepository(
        sharedPreferences: await SharedPreferences.getInstance(),
      );
      expect(await deviceB.listAdmins(), isEmpty);

      final AdminImportReport report = await deviceB.importAdminConfig(
        code: code,
        passphrase: 'transfer-pass',
      );
      expect(report.added, 2);
      expect(report.updated, 0);
      expect(report.skipped, 0);

      final List<AdminAccount> imported = await deviceB.listAdmins();
      expect(imported, hasLength(2));
      expect(imported.first.role, AdminRole.owner);

      // **نفس كلمات المرور** تعمل على الجهاز الجديد.
      final owner = await deviceB.signInWithPassword(
        email: 'owner@joodcraft.dev',
        password: 'Owner!2345',
      );
      expect(owner.fullName, 'المدير الرئيسي');
      await deviceB.signOut();
      final admin = await deviceB.signInWithPassword(
        email: 'admin@joodcraft.dev',
        password: 'Admin!2345',
      );
      expect(admin.organizationName, 'مؤسسة النور');
    });

    test('عبارة مرور خاطئة لا تُغيّر شيئاً على الجهاز المستورد', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final LocalAuthRepository deviceA = LocalAuthRepository(
        sharedPreferences: await SharedPreferences.getInstance(),
      );
      await deviceA.signUpWithPassword(
        email: 'owner@joodcraft.dev',
        password: 'Owner!2345',
        fullName: 'المدير الرئيسي',
      );
      final String code =
          await deviceA.exportAdminConfig(passphrase: 'transfer-pass');

      SharedPreferences.setMockInitialValues(<String, Object>{});
      final LocalAuthRepository deviceB = LocalAuthRepository(
        sharedPreferences: await SharedPreferences.getInstance(),
      );
      await expectLater(
        deviceB.importAdminConfig(code: code, passphrase: 'nope-nope'),
        throwsA(isA<AppException>()),
      );
      expect(await deviceB.listAdmins(), isEmpty);
    });

    test('بلا استبدال يتخطّى الموجود، ومعه يُحدّث', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final LocalAuthRepository deviceA = LocalAuthRepository(
        sharedPreferences: await SharedPreferences.getInstance(),
      );
      await deviceA.signUpWithPassword(
        email: 'owner@joodcraft.dev',
        password: 'Owner!2345',
        fullName: 'المدير الرئيسي',
      );
      final String code =
          await deviceA.exportAdminConfig(passphrase: 'transfer-pass');

      // الجهاز الثاني عنده الحساب نفسه بكلمة مرور مختلفة.
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final LocalAuthRepository deviceB = LocalAuthRepository(
        sharedPreferences: await SharedPreferences.getInstance(),
      );
      await deviceB.signUpWithPassword(
        email: 'owner@joodcraft.dev',
        password: 'Local!2345',
        fullName: 'حساب محلي',
      );

      final AdminImportReport skipped = await deviceB.importAdminConfig(
        code: code,
        passphrase: 'transfer-pass',
      );
      expect(skipped.added, 0);
      expect(skipped.skipped, 1);

      final AdminImportReport replaced = await deviceB.importAdminConfig(
        code: code,
        passphrase: 'transfer-pass',
        replaceExisting: true,
      );
      expect(replaced.updated, 1);
      await deviceB.signOut();
      await deviceB.signInWithPassword(
        email: 'owner@joodcraft.dev',
        password: 'Owner!2345',
      );
    });

    test('تصدير بلا حسابات يُرفض برسالة واضحة', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final LocalAuthRepository empty = LocalAuthRepository(
        sharedPreferences: await SharedPreferences.getInstance(),
      );
      await expectLater(
        empty.exportAdminConfig(passphrase: 'transfer-pass'),
        throwsA(
          isA<AppException>().having(
            (AppException e) => e.code,
            'code',
            AppErrorCode.notFound,
          ),
        ),
      );
    });

    test('ملف ليس ملف حسابات معروفاً يُرفض', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final LocalAuthRepository device = LocalAuthRepository(
        sharedPreferences: await SharedPreferences.getInstance(),
      );
      final String notConfig = AdminConfigCipher.encrypt(
        payload: '{"format":"something-else"}',
        passphrase: 'transfer-pass',
        iterationsOverride: 1000,
      );
      await expectLater(
        device.importAdminConfig(code: notConfig, passphrase: 'transfer-pass'),
        throwsA(isA<AppException>()),
      );
    });
  });

  // ==========================================================================
  //  سجل التصدير
  // ==========================================================================
  group('ExportAuditLog', () {
    test('يسجّل المُصدِر والوقت والعدد ويرتّب الأحدث أولاً', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      ExportAuditLog.currentAdmin =
          () => (id: 'local_1', email: 'owner@joodcraft.dev', name: 'المدير');
      addTearDown(() => ExportAuditLog.currentAdmin = null);

      final ExportAuditLog log =
          ExportAuditLog(store: InMemoryExportAuditStore());

      await log.record(
        documentTitle: 'شهادة التميّز',
        kind: ExportKind.certificate,
        pageCount: 1,
        fileName: 'cert.pdf',
        at: DateTime(2026, 5, 1, 10),
      );
      await log.record(
        documentTitle: 'دفعة الفصل الأول',
        kind: ExportKind.batch,
        pageCount: 42,
        at: DateTime(2026, 5, 2, 9),
      );

      expect(log.entries, hasLength(2));
      expect(log.entries.first.documentTitle, 'دفعة الفصل الأول');
      expect(log.entries.first.pageCount, 42);
      expect(log.entries.first.kind, ExportKind.batch);
      // المدير مأخوذ من الربط العام بلا أن يعرف مسار التصدير الواجهة.
      expect(log.entries.first.adminEmail, 'owner@joodcraft.dev');
      expect(log.entries.first.adminLabel, 'المدير');
      expect(log.entries.last.documentTitle, 'شهادة التميّز');
    });

    test('يُستعاد من المخزن، ويُفرَّغ', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final InMemoryExportAuditStore store = InMemoryExportAuditStore();
      ExportAuditLog.currentAdmin = null;

      final ExportAuditLog writer = ExportAuditLog(store: store);
      await writer.record(
        documentTitle: 'عقد العمل',
        kind: ExportKind.contract,
        adminEmail: null,
        at: DateTime(2026, 6, 1),
      );
      expect(writer.entries.first.adminLabel, 'محلي');

      final ExportAuditLog reader = ExportAuditLog(store: store);
      await reader.restore();
      expect(reader.entries, hasLength(1));
      expect(reader.entries.first.documentTitle, 'عقد العمل');

      await reader.clear();
      expect(reader.entries, isEmpty);
      final ExportAuditLog afterClear = ExportAuditLog(store: store);
      await afterClear.restore();
      expect(afterClear.entries, isEmpty);
    });

    test('العنوان الفارغ يُستبدل، والحدّ الأقصى يحمي الملف', () async {
      final ExportAuditLog log =
          ExportAuditLog(store: InMemoryExportAuditStore());
      await log.record(documentTitle: '   ', kind: ExportKind.project);
      expect(log.entries.first.documentTitle, 'مستند بلا عنوان');

      for (int i = 0; i < ExportAuditLog.maxEntries + 5; i++) {
        await log.record(documentTitle: 'وثيقة $i', kind: ExportKind.certificate);
      }
      expect(log.entries, hasLength(ExportAuditLog.maxEntries));
      expect(log.entries.first.documentTitle.startsWith('وثيقة'), isTrue);
    });

    test('JSON الملف يحمل الحقول الوصفية بلا محتوى المستند', () {
      final ExportAuditEntry entry = ExportAuditEntry(
        id: 'exp_1',
        at: DateTime(2026, 7, 1, 12, 30),
        documentTitle: 'شهادة',
        kind: ExportKind.certificate,
        fileName: 'cert.pdf',
        pageCount: 3,
        adminEmail: 'a@b.c',
        recipient: 'أحمد',
      );
      final Map<String, dynamic> json = entry.toJson();
      expect(json['kind'], 'certificate');
      expect(json['pageCount'], 3);
      expect(json.containsKey('elements'), isFalse);

      final ExportAuditEntry? restored =
          ExportAuditEntry.fromJson(Map<String, dynamic>.from(json));
      expect(restored?.documentTitle, 'شهادة');
      expect(restored?.kind, ExportKind.certificate);
      expect(restored?.at, DateTime(2026, 7, 1, 12, 30));
      expect(ExportAuditEntry.fromJson(<String, dynamic>{'id': 'x'}), isNull);
    });
  });
}

// ============================================================================
//  أدوات الاختبار
// ============================================================================

/// واجهة صغيرة تُغلّف بايتات مفتاح لتسهيل المقارنة.
class Uint8ListLike {
  const Uint8ListLike(this.bytes);
  final List<int> bytes;
}

Uint8ListLike _key(String password, String salt) => Uint8ListLike(
      Pbkdf2.deriveKey(
        password: utf8.encode(password),
        salt: utf8.encode(salt),
        iterations: 100,
      ),
    );

/// بصمة SHA-256 مفردة — تحاكي صيغة التخزين القديمة.
String _sha256Hex(String value) =>
    sha256.convert(utf8.encode(value)).toString();

/// مستخدم مختصر (نتفادى استيراد طبقة الواجهة هنا).
class AppUserLike {
  const AppUserLike({required this.id, required this.fullName});
  final String id;
  final String fullName;
}

Future<AppUserLike> _signUpOwner(LocalAuthRepository repository) async {
  final outcome = await repository.signUpWithPassword(
    email: 'owner@joodcraft.dev',
    password: 'Owner!2345',
    fullName: 'المدير الرئيسي',
  );
  return AppUserLike(id: outcome.user.id, fullName: outcome.user.fullName ?? '');
}
