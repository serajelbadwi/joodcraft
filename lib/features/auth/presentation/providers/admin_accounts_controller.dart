import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/errors/app_error_code.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/admin_account.dart';
import '../../domain/admin_repository.dart';

/// حالة شاشة إدارة المديرين — يحوّل استثناءات المستودع إلى رسائل عربية
/// ويحمل قائمة الحسابات، بلا أن تعرف الشاشة شيئاً عن التخزين.
///
/// `_repository == null` يعني أن التطبيق لم يُربط بمستودع إدارة محلي (تشغيل بلا
/// حساب)، فتُعلن الشاشة ذلك بلا انهيار.
class AdminAccountsController extends ChangeNotifier {
  AdminAccountsController(this._repository);

  final AdminRepository? _repository;

  List<AdminAccount> _admins = <AdminAccount>[];
  bool _busy = false;
  String? _errorMessage;

  /// هل أُنجزت **محاولة تحميل واحدة** على الأقل (نجحت أو فشلت)؟ يفرّق بذلك
  /// الواجهة بين «لم تبدأ الجلب بعد» و«القائمة فارغة فعلاً»، فلا تُعرض رسالة
  /// «لا حسابات» قبل أن تصل البيانات من المخزن المحلي.
  bool _loadedOnce = false;

  /// يمنع الإخطار بعد التحرير ([dispose]) — لا سيّما الإخطار المؤجَّل إلى ما
  /// بعد إطار الرسم في [_notify].
  bool _disposed = false;

  List<AdminAccount> get admins => List<AdminAccount>.unmodifiable(_admins);
  bool get isBusy => _busy;
  String? get errorMessage => _errorMessage;
  bool get isLoaded => _loadedOnce;

  /// هل إدارة المديرين متاحة في هذه النسخة؟
  bool get isAvailable => _repository != null;

  bool get hasAdmins => _admins.isNotEmpty;
  int get ownersCount =>
      _admins.where((AdminAccount a) => a.isOwner).length;

  /// المدير الرئيسي الحالي (لعمليات النقل بين الأجهزة).
  AdminAccount? get owner {
    for (final AdminAccount admin in _admins) {
      if (admin.isOwner) return admin;
    }
    return null;
  }

  AdminAccount? adminById(String id) {
    for (final AdminAccount admin in _admins) {
      if (admin.id == id) return admin;
    }
    return null;
  }

  /// يعيد تحميل القائمة من المخزن المحلي. لا يرمي.
  ///
  /// آمنٌ للاستدعاء أثناء بناء الشجرة (شاشة في `initState` مثلاً): الإخطار
  /// يُؤجَّل حينها إلى ما بعد الإطار الحالي بدل رمي خطأ
  /// «setState() or markNeedsBuild() called during build».
  Future<void> load() async {
    _errorMessage = null;
    _busy = true;
    _notify();
    try {
      _admins = await _require().listAdmins();
    } on AppException catch (error) {
      _errorMessage = error.message;
    } on Object catch (error) {
      _errorMessage = AppException(AppErrorCode.unknown, cause: error).message;
    } finally {
      _busy = false;
      _loadedOnce = true;
      _notify();
    }
  }

  /// ينشئ مديراً جديداً ثم يُحدّث القائمة. يرمي [AppException] للشاشة.
  Future<AdminAccount> create({
    required String email,
    required String password,
    required String fullName,
    String? organizationName,
    String? username,
    AdminRole role = AdminRole.admin,
  }) async {
    return _guard(() async {
      final AdminAccount created = await _require().createAdmin(
        email: email,
        password: password,
        fullName: fullName,
        organizationName: organizationName,
        username: username,
        role: role,
      );
      await _reloadQuietly();
      return created;
    });
  }

  /// يُحدّث بيانات مدير (الاسم/المؤسسة/الرتبة).
  Future<AdminAccount> updateProfile({
    required String id,
    required String fullName,
    String? organizationName,
    String? username,
    AdminRole? role,
  }) async {
    return _guard(() async {
      final AdminAccount updated = await _require().updateAdminProfile(
        id: id,
        fullName: fullName,
        organizationName: organizationName,
        username: username,
        role: role,
      );
      await _reloadQuietly();
      return updated;
    });
  }

  /// يُغيّر كلمة مرور مدير (الحالية مطلوبة لحسابك أنت).
  Future<void> setPassword({
    required String id,
    required String newPassword,
    String? currentPassword,
  }) async {
    return _guard(() async {
      await _require().setAdminPassword(
        id: id,
        newPassword: newPassword,
        currentPassword: currentPassword,
      );
      await _reloadQuietly();
    });
  }

  /// يحذف مديراً.
  Future<void> remove(String id) async {
    return _guard(() async {
      await _require().deleteAdmin(id);
      await _reloadQuietly();
    });
  }

  /// يُصدّر الحسابات في شفرة مشفّرة بعبارة المرور.
  Future<String> exportConfig({required String passphrase}) {
    return _guard(() => _require().exportAdminConfig(passphrase: passphrase));
  }

  /// يستورد حسابات من شفرة/ملف مشفّر.
  Future<AdminImportReport> importConfig({
    required String code,
    required String passphrase,
    bool replaceExisting = false,
  }) async {
    return _guard(() async {
      final AdminImportReport report = await _require().importAdminConfig(
        code: code,
        passphrase: passphrase,
        replaceExisting: replaceExisting,
      );
      await _reloadQuietly();
      return report;
    });
  }

  // ==========================================================================
  //                              أدوات داخلية
  // ==========================================================================

  AdminRepository _require() {
    final AdminRepository? repository = _repository;
    if (repository == null) {
      throw const AppException(
        AppErrorCode.notConfigured,
        message: 'إدارة المديرين غير مُهيّأة في هذه النسخة.',
      );
    }
    return repository;
  }

  /// يوحّد الأخطاء: يُمرّر [AppException] كما هي ويُغلّف ما عداها.
  Future<T> _guard<T>(Future<T> Function() action) async {
    _busy = true;
    _errorMessage = null;
    _notify();
    try {
      return await action();
    } catch (error) {
      final AppException wrapped = error is AppException
          ? error
          : AppException(AppErrorCode.unknown, cause: error);
      _errorMessage = wrapped.message;
      throw wrapped;
    } finally {
      _busy = false;
      _notify();
    }
  }

  /// إعادة تحميل صامتة بعد عملية ناجحة (فشلها لا يُبطل العملية نفسها).
  Future<void> _reloadQuietly() async {
    try {
      _admins = await _require().listAdmins();
      _loadedOnce = true;
    } catch (_) {
      // تبقى القائمة القديمة معروضة؛ العملية الأصلية نجحت وسيُبلغ عنها.
    }
  }

  /// إخطار المستمعين **بأمان** أثناء دورة البناء.
  ///
  /// إن كان الإخطار يحدث والشجرة تُبنى (تحميل أُطلق من `didChangeDependencies`
  /// أو من `initState`) رمي الإخطار مباشرةً كان يُسقط الواجهة بـ`setState() or
  /// markNeedsBuild() called during build` ويحلّ `ErrorWidget` محلّ شاشة
  /// إدارة المديرين — فلا يظهر جدول الحسابات على الجهاز. لذا يُؤجَّل الإخطار
  /// حينها إلى ما بعد إطار الرسم الحالي.
  void _notify() {
    if (_disposed) return;
    final SchedulerBinding scheduler = SchedulerBinding.instance;
    if (scheduler.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      scheduler.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
      return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
