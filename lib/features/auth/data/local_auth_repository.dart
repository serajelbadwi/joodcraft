import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_error_code.dart';
import '../../../../core/errors/app_exception.dart';
import '../domain/admin_account.dart';
import '../domain/admin_repository.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';
import '../domain/local_admin_authenticator.dart';
import 'admin_config_cipher.dart';
import 'password_hashing.dart';

/// تنفيذ [AuthRepository] و[AdminRepository] فوق **مخزن محلي واحد** على الجهاز.
///
/// * الحسابات تُخزَّن كـJSON في `SharedPreferences` تحت مفتاح واحد، وبصمة كلمة
///   المرور تُولَّد بـPBKDF2 ([PasswordHasher]) فلا تُخزَّن الكلمة نفسها أبداً.
/// * الجلسة الحالية معرّف مستخدم فقط — يكفي لاستعادة الدخول عند الإقلاع.
/// * النقل بين الأجهزة يتمّ بشفرة مشفّرة ([AdminConfigCipher])، فلا شبكة في أي
///   عملية: إضافة/تعديل/حذف/تصدير/استيراد كلها محلية بالكامل.
///
/// **ترحيل شفّاف:** البصمات القديمة (‎SHA-256‎ مفرد) تبقى تعمل، وتُرقّى إلى
/// PBKDF2 تلقائياً عند أول دخول ناجح — فلا يُقفل أي حساب قائم.
class LocalAuthRepository
    implements AuthRepository, AdminRepository, LocalAdminAuthenticator {
  LocalAuthRepository({SharedPreferences? sharedPreferences})
      : _sharedPreferences = sharedPreferences;

  static const _accountsKey = 'joodcraft.local_auth_accounts.v1';
  static const _currentUserKey = 'joodcraft.local_auth.current_user';
  static const _passwordResetKey = 'joodcraft.local_auth.password_reset_requested';

  /// وسم ملف الحسابات المُصدَّر (يُتحقَّق منه عند الاستيراد).
  static const String configFormat = 'joodcraft.admin-config';
  static const int configVersion = 1;

  final SharedPreferences? _sharedPreferences;

  /// ينشئ المستودع جاهزاً بقراءة التفضيلات، ويتراجع بأمان إن تعذّر ذلك
  /// (مثلاً في اختبارات بلا منفّذ منصّة) فيعمل في الذاكرة بلا انهيار.
  static Future<LocalAuthRepository> create() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return LocalAuthRepository(sharedPreferences: prefs);
    } catch (_) {
      return LocalAuthRepository(sharedPreferences: null);
    }
  }

  // ==========================================================================
  //                            مخزن الحسابات
  // ==========================================================================

  Map<String, String> _accounts() {
    final SharedPreferences? prefs = _sharedPreferences;
    if (prefs == null) return <String, String>{};
    final String? raw = prefs.getString(_accountsKey);
    if (raw == null) return <String, String>{};
    try {
      return Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return <String, String>{};
    }
  }

  Future<void> _saveAccounts(Map<String, String> accounts) async {
    final SharedPreferences? prefs = _sharedPreferences;
    if (prefs == null) return;
    await prefs.setString(_accountsKey, jsonEncode(accounts));
  }

  Future<void> _upsertAccount(AccountRecord account) async {
    final Map<String, String> accounts = _accounts();
    accounts[account.email] = jsonEncode(account.toJson());
    await _saveAccounts(accounts);
  }

  AccountRecord? _accountOf(String email) {
    final String? raw = _accounts()[email.trim().toLowerCase()];
    if (raw == null) return null;
    try {
      return AccountRecord.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  AccountRecord? _accountById(String id) {
    for (final AccountRecord record in _allRecords()) {
      if (record.id == id) return record;
    }
    return null;
  }

  /// كل الحسابات مقروءةً من المخزن (تتجاهل أي صفّ تالف).
  List<AccountRecord> _allRecords() {
    final List<AccountRecord> records = <AccountRecord>[];
    for (final String raw in _accounts().values) {
      try {
        records.add(
          AccountRecord.fromJson(jsonDecode(raw) as Map<String, dynamic>),
        );
      } catch (_) {
        continue;
      }
    }
    return records;
  }

  /// الحساب الذي يطابق اسم المستخدم المحلي (غير حسّاس لحالة الأحرف).
  AccountRecord? _accountByUsername(String username) {
    final String needle = username.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final AccountRecord record in _allRecords()) {
      if (record.effectiveUsername.toLowerCase() == needle) return record;
    }
    return null;
  }

  /// هل اسم المستخدم مشغول بحساب آخر؟ (يُستخدم قبل الإنشاء/التعديل)
  bool _usernameTaken(String? username, {String? exceptId}) {
    final String? raw = username?.trim();
    if (raw == null || raw.isEmpty) return false;
    final String needle = raw.toLowerCase();
    for (final AccountRecord record in _allRecords()) {
      if (record.id == exceptId) continue;
      if (record.effectiveUsername.toLowerCase() == needle) return true;
    }
    return false;
  }

  /// يُطبّع اسم المستخدم: فراغ ⇒ `null` (فيُشتقّ من البريد لاحقاً).
  static String? _normalizeUsername(String? username) {
    final String? raw = username?.trim();
    return (raw == null || raw.isEmpty) ? null : raw;
  }

  // ==========================================================================
  //                            الجلسة الحالية
  // ==========================================================================

  @override
  AppUser? get currentUser => _loadUser();

  AppUser? _loadUser() {
    final SharedPreferences? prefs = _sharedPreferences;
    if (prefs == null) return null;
    final String? raw = prefs.getString(_currentUserKey);
    if (raw == null) return null;
    try {
      final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
      return AppUser(
        id: json['id'] as String? ?? 'local_user',
        email: json['email'] as String?,
        fullName: json['fullName'] as String?,
        organizationName: json['organizationName'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveSession(AppUser? user) async {
    final SharedPreferences? prefs = _sharedPreferences;
    if (prefs == null) return;
    if (user == null) {
      await prefs.remove(_currentUserKey);
      return;
    }
    await prefs.setString(
      _currentUserKey,
      jsonEncode(<String, dynamic>{
        'id': user.id,
        'email': user.email,
        'fullName': user.fullName,
        'organizationName': user.organizationName,
        'createdAt': user.createdAt?.toIso8601String(),
      }),
    );
  }

  @override
  Stream<AppUser?> authStateChanges() => Stream<AppUser?>.value(currentUser);

  // ==========================================================================
  //                            تسجيل الدخول
  // ==========================================================================

  @override
  Future<AppUser> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final AccountRecord? account = _accountOf(email);
    if (account == null) {
      throw const AppException(
        AppErrorCode.invalidCredentials,
        message: 'البريد الإلكتروني أو كلمة المرور غير صحيح.',
      );
    }

    final PasswordVerification verification =
        PasswordHasher.verify(password, account.passwordHash);
    if (verification == PasswordVerification.mismatch) {
      throw const AppException(
        AppErrorCode.invalidCredentials,
        message: 'البريد الإلكتروني أو كلمة المرور غير صحيح.',
      );
    }

    var effective = account;
    // ترقية شفّافة: كلمة المرور صحيحة لكن بصمتها قديمة ⇒ تُعاد بـPBKDF2
    // الآن، فلا يبقى حساب واحد على SHA-256 المفرد بعد أول دخول.
    if (verification == PasswordVerification.needsUpgrade) {
      effective = account.copyWith(
        passwordHash: PasswordHasher.hash(password),
        updatedAt: DateTime.now().toIso8601String(),
      );
      await _upsertAccount(effective);
    }

    final AppUser user = effective.toUser();
    await _saveSession(user);
    return user;
  }

  // ==========================================================================
  //                 تبديل سريع: مصادقة الأدمن الفرعي محلياً
  // ==========================================================================

  /// التبديل المحلي متاح متى كان المخزن موجوداً (وهو كذلك افتراضياً).
  @override
  bool get isLocalSwitchAvailable => true;

  /// يتحقّق من **اسم المستخدم المحلي** وكلمة المرور ضد الحساب الفرعي المخزَّن
  /// على هذا الجهاز، ثم يحفظ الجلسة ويعيد مستخدمها — بلا أي شبكة ولا مسّ
  /// بترخيص الاشتراك الأساسي (Master License) الذي يبقى لصاحب الجهاز.
  ///
  /// الحساب يُطابَق بـ[AccountRecord.effectiveUsername]: الاسم المضبوط صراحةً
  /// إن وُجد، وإلا الجزء قبل `@` في البريد (فتعمل الحسابات القديمة فوراً).
  @override
  Future<AppUser> signInWithLocalUsername({
    required String username,
    required String password,
  }) async {
    final AccountRecord? account = _accountByUsername(username);
    if (account == null) {
      throw const AppException(
        AppErrorCode.invalidCredentials,
        message: 'اسم المستخدم أو كلمة المرور غير صحيح.',
      );
    }

    final PasswordVerification verification =
        PasswordHasher.verify(password, account.passwordHash);
    if (verification == PasswordVerification.mismatch) {
      throw const AppException(
        AppErrorCode.invalidCredentials,
        message: 'اسم المستخدم أو كلمة المرور غير صحيح.',
      );
    }

    var effective = account;
    // ترقية شفّافة: البصمة صحيحة لكنها قديمة ⇒ تُعاد بـPBKDF2 الآن.
    if (verification == PasswordVerification.needsUpgrade) {
      effective = account.copyWith(
        passwordHash: PasswordHasher.hash(password),
        updatedAt: DateTime.now().toIso8601String(),
      );
      await _upsertAccount(effective);
    }

    final AppUser user = effective.toUser();
    await _saveSession(user);
    return user;
  }

  @override
  Future<SignUpOutcome> signUpWithPassword({
    required String email,
    required String password,
    required String fullName,
    String? organizationName,
  }) async {
    final String normalizedEmail = email.trim().toLowerCase();

    if (_accounts().containsKey(normalizedEmail)) {
      throw const AppException(
        AppErrorCode.emailAlreadyInUse,
        message: 'هذا البريد الإلكتروني مسجّل مسبقاً.',
      );
    }

    if (password.length < AppConstants.minPasswordLength) {
      throw const AppException(
        AppErrorCode.weakPassword,
        message: 'كلمة المرور قصيرة. اختر كلمة مرور أقوى.',
      );
    }

    // **أول حساب على الجهاز يصبح المدير الرئيسي**: هو من يملك الجهاز ويُنشئ
    // بقية الحسابات وينقلها. أي حساب بعده «مدير» حتى تُغيَّر رتبته صراحةً.
    final bool firstAccount = _accounts().isEmpty;
    final DateTime now = DateTime.now();
    final AccountRecord account = AccountRecord(
      id: _newLocalUserId(),
      email: normalizedEmail,
      passwordHash: PasswordHasher.hash(password),
      fullName: fullName.trim(),
      organizationName: organizationName?.trim(),
      role: firstAccount ? AdminRole.owner : AdminRole.admin,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    );

    await _upsertAccount(account);

    final AppUser user = account.toUser();
    await _saveSession(user);
    return SignUpOutcome(user: user, requiresEmailConfirmation: false);
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    final SharedPreferences? prefs = _sharedPreferences;
    if (prefs == null) return;
    await prefs.setString(
      _passwordResetKey,
      jsonEncode(<String, String>{'email': email.trim().toLowerCase()}),
    );
  }

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    final AccountRecord? account = _accountById(userId);
    if (account == null) return null;
    return <String, dynamic>{
      'full_name': account.fullName ?? '',
      'organization_name': account.organizationName ?? '',
      'subscription_tier': 'free',
      'created_at': account.createdAt,
    };
  }

  @override
  Future<void> signOut() async {
    final SharedPreferences? prefs = _sharedPreferences;
    if (prefs == null) return;
    await prefs.remove(_currentUserKey);
    await prefs.remove(_passwordResetKey);
  }

  // ==========================================================================
  //                          إدارة المديرين (AdminRepository)
  // ==========================================================================

  @override
  Future<List<AdminAccount>> listAdmins() async {
    final String? currentId = currentUser?.id;
    final List<AccountRecord> records = <AccountRecord>[];
    for (final String raw in _accounts().values) {
      try {
        records.add(
          AccountRecord.fromJson(jsonDecode(raw) as Map<String, dynamic>),
        );
      } catch (_) {
        continue;
      }
    }

    records.sort((AccountRecord a, AccountRecord b) {
      // الرئيسي أولاً، ثم الأقدم إنشاءً (فالمدير الرئيسي يبقى في القمة دائماً).
      if (a.role != b.role) {
        return a.role == AdminRole.owner ? -1 : 1;
      }
      final String ca = a.createdAt ?? '';
      final String cb = b.createdAt ?? '';
      final int byDate = ca.compareTo(cb);
      return byDate != 0 ? byDate : a.email.compareTo(b.email);
    });

    return <AdminAccount>[
      for (final AccountRecord record in records)
        record.toAdminAccount(isCurrent: record.id == currentId),
    ];
  }

  @override
  Future<AdminAccount> createAdmin({
    required String email,
    required String password,
    required String fullName,
    String? organizationName,
    String? username,
    AdminRole role = AdminRole.admin,
  }) async {
    final String normalizedEmail = email.trim().toLowerCase();
    if (!_looksLikeEmail(normalizedEmail)) {
      throw const AppException(
        AppErrorCode.validation,
        message: 'أدخل بريداً إلكترونياً صالحاً.',
      );
    }
    if (_accounts().containsKey(normalizedEmail)) {
      throw const AppException(
        AppErrorCode.emailAlreadyInUse,
        message: 'هذا البريد الإلكتروني مسجّل مسبقاً.',
      );
    }
    if (password.length < AppConstants.minPasswordLength) {
      throw const AppException(
        AppErrorCode.weakPassword,
        message: 'كلمة مرور المدير قصيرة. اختر كلمة مرور أقوى.',
      );
    }
    if (fullName.trim().isEmpty) {
      throw const AppException(
        AppErrorCode.validation,
        message: 'اسم المدير مطلوب.',
      );
    }
    final String? normalizedUsername = _normalizeUsername(username);
    if (_usernameTaken(
      normalizedUsername ?? normalizedEmail.split('@').first,
    )) {
      throw const AppException(
        AppErrorCode.validation,
        message: 'اسم المستخدم المحلي مستخدم مسبقاً. اختر اسماً آخر.',
      );
    }

    final DateTime now = DateTime.now();
    final AccountRecord record = AccountRecord(
      id: _newLocalUserId(),
      email: normalizedEmail,
      username: normalizedUsername,
      passwordHash: PasswordHasher.hash(password),
      fullName: fullName.trim(),
      organizationName: organizationName?.trim(),
      role: role,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    );
    await _upsertAccount(record);
    return record.toAdminAccount(isCurrent: currentUser?.id == record.id);
  }

  @override
  Future<AdminAccount> updateAdminProfile({
    required String id,
    required String fullName,
    String? organizationName,
    String? username,
    AdminRole? role,
  }) async {
    final AccountRecord? existing = _accountById(id);
    if (existing == null) {
      throw const AppException(AppErrorCode.notFound, message: 'المدير غير موجود.');
    }
    if (fullName.trim().isEmpty) {
      throw const AppException(
        AppErrorCode.validation,
        message: 'اسم المدير مطلوب.',
      );
    }
    final String? normalizedUsername = _normalizeUsername(username);
    if (_usernameTaken(normalizedUsername, exceptId: id)) {
      throw const AppException(
        AppErrorCode.validation,
        message: 'اسم المستخدم المحلي مستخدم مسبقاً. اختر اسماً آخر.',
      );
    }

    final AdminRole nextRole = role ?? existing.role;
    if (existing.role == AdminRole.owner &&
        nextRole != AdminRole.owner &&
        id == currentUser?.id) {
      // تجريد النفس من الرتبة الرئيسية يترك الجهاز بلا رئيس — منع واضح.
      throw const AppException(
        AppErrorCode.permissionDenied,
        message: 'لا يمكن تجريد حسابك من صفة «المدير الرئيسي».',
      );
    }

    final AccountRecord updated = existing.copyWith(
      username: normalizedUsername,
      fullName: fullName.trim(),
      organizationName: organizationName?.trim(),
      role: nextRole,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _upsertAccount(updated);

    // إن عدّل المدير بياناته هو، تُحدَّث جلسة العرض فوراً بلا خروج ودخول.
    if (currentUser?.id == updated.id) {
      await _saveSession(updated.toUser());
    }
    return updated.toAdminAccount(isCurrent: currentUser?.id == updated.id);
  }

  @override
  Future<void> setAdminPassword({
    required String id,
    required String newPassword,
    String? currentPassword,
  }) async {
    final AccountRecord? existing = _accountById(id);
    if (existing == null) {
      throw const AppException(AppErrorCode.notFound, message: 'المدير غير موجود.');
    }
    if (newPassword.length < AppConstants.minPasswordLength) {
      throw const AppException(
        AppErrorCode.weakPassword,
        message: 'كلمة المرور الجديدة قصيرة. اختر كلمة مرور أقوى.',
      );
    }

    final bool isSelf = currentUser?.id == existing.id;
    if (isSelf && currentPassword != null) {
      if (PasswordHasher.verify(currentPassword, existing.passwordHash) !=
          PasswordVerification.match) {
        throw const AppException(
          AppErrorCode.invalidCredentials,
          message: 'كلمة المرور الحالية غير صحيحة.',
        );
      }
    } else if (isSelf && currentPassword == null) {
      // تغيير كلمة مرور نفسك **يتطلّب** الحالية: يمنع من فتح الجهاز مفتوحاً
      // من الاستيلاء على الحساب بتغيير كلمة مروره.
      throw const AppException(
        AppErrorCode.validation,
        message: 'أدخل كلمة المرور الحالية لتغيير كلمة مرورك.',
      );
    }

    await _upsertAccount(
      existing.copyWith(
        passwordHash: PasswordHasher.hash(newPassword),
        updatedAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  @override
  Future<void> deleteAdmin(String id) async {
    if (currentUser?.id == id) {
      throw const AppException(
        AppErrorCode.permissionDenied,
        message: 'لا يمكنك حذف الحساب الذي تستخدمه الآن.',
      );
    }
    final AccountRecord? existing = _accountById(id);
    if (existing == null) {
      throw const AppException(AppErrorCode.notFound, message: 'المدير غير موجود.');
    }

    final Map<String, String> accounts = _accounts()
      ..removeWhere((_, String raw) {
        try {
          final AccountRecord record =
              AccountRecord.fromJson(jsonDecode(raw) as Map<String, dynamic>);
          return record.id == id;
        } catch (_) {
          return false;
        }
      });
    await _saveAccounts(accounts);
  }

  // ==========================================================================
  //                     تصدير/استيراد الحسابات (بين الأجهزة)
  // ==========================================================================

  @override
  Future<String> exportAdminConfig({required String passphrase}) async {
    final String? currentId = currentUser?.id;
    final List<Map<String, dynamic>> payload = <Map<String, dynamic>>[];
    for (final String raw in _accounts().values) {
      try {
        final AccountRecord record =
            AccountRecord.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        payload.add(<String, dynamic>{
          ...record.toJson(),
          'isCurrentOnSource': record.id == currentId,
        });
      } catch (_) {
        continue;
      }
    }
    if (payload.isEmpty) {
      throw const AppException(
        AppErrorCode.notFound,
        message: 'لا توجد حسابات محلية لتصديرها.',
      );
    }
    // **البصمات تُنقل كما هي**: هي التي تُبقي كلمات المرور صالحة على الجهاز
    // الآخر بلا أن تُعرف أو تُعاد. لذا المغلّف مشفَّر إلزاماً.
    final String json = jsonEncode(<String, dynamic>{
      'format': configFormat,
      'version': configVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'accounts': payload,
    });
    return AdminConfigCipher.encrypt(payload: json, passphrase: passphrase);
  }

  @override
  Future<AdminImportReport> importAdminConfig({
    required String code,
    required String passphrase,
    bool replaceExisting = false,
  }) async {
    final String plain = AdminConfigCipher.decrypt(
      code: code,
      passphrase: passphrase,
    );

    final Object? decoded;
    try {
      decoded = jsonDecode(plain);
    } catch (_) {
      throw const AppException(
        AppErrorCode.templateFormat,
        message: 'محتوى ملف الحسابات ليس JSON صالحاً.',
      );
    }
    if (decoded is! Map ||
        decoded['format'] != configFormat ||
        decoded['accounts'] is! List) {
      throw const AppException(
        AppErrorCode.validation,
        message: 'هذا ليس ملف حسابات JoodCraft معروفاً.',
      );
    }

    final Map<String, String> accounts = _accounts();
    int added = 0;
    int updated = 0;
    int skipped = 0;

    for (final Object? entry in decoded['accounts'] as List<Object?>) {
      if (entry is! Map) continue;
      final AccountRecord incoming;
      try {
        incoming = AccountRecord.fromJson(
          Map<String, dynamic>.from(entry),
        );
      } catch (_) {
        continue;
      }
      if (!_looksLikeEmail(incoming.email)) continue;
      final String key = incoming.email.trim().toLowerCase();

      // حساب بلا بصمة كلمة مرور لا معنى له: يُتخطّى بدل إدخال حساب مفتوح.
      if (incoming.passwordHash == null || incoming.passwordHash!.isEmpty) {
        skipped++;
        continue;
      }

      if (!accounts.containsKey(key)) {
        accounts[key] = jsonEncode(incoming.toJson());
        added++;
      } else if (replaceExisting) {
        accounts[key] = jsonEncode(incoming.toJson());
        updated++;
      } else {
        skipped++;
      }
    }

    await _saveAccounts(accounts);
    return AdminImportReport(added: added, updated: updated, skipped: skipped);
  }

  // ==========================================================================
  //                              أدوات داخلية
  // ==========================================================================

  static bool _looksLikeEmail(String value) {
    final int at = value.indexOf('@');
    return at > 0 && at < value.length - 1 && !value.contains(' ');
  }

  static String _newLocalUserId() =>
      'local_${DateTime.now().microsecondsSinceEpoch}';
}

/// صفّ حساب واحد داخل ملف الحسابات المحلي.
///
/// يحمل **بصمة** كلمة المرور ([passwordHash]) لا كلمتها، والبصمة إمّا
/// `pbkdf2_sha256$…` ([PasswordHasher]) أو `sha256` قديمة تُرقّى عند الدخول.
class AccountRecord {
  AccountRecord({
    required this.id,
    required this.email,
    required this.passwordHash,
    this.username,
    this.fullName,
    this.organizationName,
    this.role = AdminRole.admin,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;

  /// اسم المستخدم المحلي المضبوط صراحةً (اختياري).
  final String? username;

  final String? passwordHash;
  final String? fullName;
  final String? organizationName;
  final AdminRole role;
  final String? createdAt;
  final String? updatedAt;

  /// اسم المستخدم المحلي الفعّال — المضبوط صراحةً أو المشتق من البريد.
  String get effectiveUsername {
    final String? raw = username?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    final int at = email.indexOf('@');
    return at > 0 ? email.substring(0, at) : email;
  }

  AccountRecord copyWith({
    String? username,
    String? passwordHash,
    String? fullName,
    String? organizationName,
    AdminRole? role,
    String? updatedAt,
  }) {
    return AccountRecord(
      id: id,
      email: email,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      fullName: fullName ?? this.fullName,
      organizationName: organizationName ?? this.organizationName,
      role: role ?? this.role,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// النموذج الذي تعرضه الواجهة (بلا أي بصمة).
  AdminAccount toAdminAccount({bool isCurrent = false}) => AdminAccount(
        id: id,
        email: email,
        username: username,
        fullName: fullName,
        organizationName: organizationName,
        role: role,
        createdAt: _parse(createdAt),
        updatedAt: _parse(updatedAt),
        isCurrent: isCurrent,
      );

  AppUser toUser() => AppUser(
        id: id,
        email: email,
        fullName: fullName,
        organizationName: organizationName,
        createdAt: _parse(createdAt),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'email': email,
        'username': username,
        'passwordHash': passwordHash,
        'fullName': fullName,
        'organizationName': organizationName,
        'role': role.dbValue,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  static AccountRecord fromJson(Map<String, dynamic> json) => AccountRecord(
        id: json['id'] as String,
        email: json['email'] as String,
        username: json['username'] as String?,
        passwordHash: json['passwordHash'] as String?,
        fullName: json['fullName'] as String?,
        organizationName: json['organizationName'] as String?,
        role: AdminRole.fromDb(json['role'] as String?),
        createdAt: json['createdAt'] as String?,
        updatedAt: json['updatedAt'] as String?,
      );

  static DateTime? _parse(String? value) =>
      value == null ? null : DateTime.tryParse(value);
}
