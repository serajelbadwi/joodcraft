/// بوابة دخول **لوحة تحكم المالك**: تتحقق من جلسة Supabase ومن صفّ الحساب
/// في `platform_admins` قبل فتح اللوحة.
///
/// الحالات:
/// * `unavailable` — لم تُضبط مفاتيح Supabase (‎`SupabaseService.isInitialized`‎)
///   فتُعرض ملاحظة التهيئة بدل لوحة بلا اتصال.
/// * `login` — لا جلسة قائمة: نموذج دخول بريد/كلمة سرّ (Supabase Auth).
/// * `denied` — جلسة قائمة لكن بلا صفّ في `platform_admins`.
/// * `panel` — المالك: تُفتح [OwnerAdminScreen].
///
/// بوابات القرى والأمان تبقى في القاعدة نفسها: دوال `security definer`
/// تفحص `is_platform_admin()` وسياسات RLS تُبقي الصفوف عند المالك —
/// هذه البوابة طبقة تجربة لا طبقة حماية وحدها.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../data/owner_admin_repository.dart';
import '../data/supabase_owner_admin_repository.dart';
import '../domain/owner_models.dart';
import 'owner_admin_screen.dart';

class OwnerAdminGateScreen extends StatefulWidget {
  const OwnerAdminGateScreen({super.key, this.repository});

  /// المستودع — `null` في التطبيق (يبنى فوق `SupabaseService`)، وهميّ في
  /// الاختبارات.
  final OwnerAdminRepository? repository;

  @override
  State<OwnerAdminGateScreen> createState() => _OwnerAdminGateScreenState();
}

enum _GateStage { checking, unavailable, login, denied, panel }

class _OwnerAdminGateScreenState extends State<OwnerAdminGateScreen> {
  late final OwnerAdminRepository _repository =
      widget.repository ?? const SupabaseOwnerAdminRepository();

  _GateStage _stage = _GateStage.checking;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // _stage يبدأ `checking` — لا setState قبل أول إطار.
    _resolve();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    if (!_repository.isAvailable) {
      if (!mounted) return;
      setState(() => _stage = _GateStage.unavailable);
      return;
    }
    if (_repository.isSignedIn) {
      await _checkAdmin();
      return;
    }
    if (!mounted) return;
    setState(() => _stage = _GateStage.login);
  }

  Future<void> _checkAdmin() async {
    final bool admin = await _repository.isPlatformAdmin();
    if (!mounted) return;
    setState(() => _stage = admin ? _GateStage.panel : _GateStage.denied);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _repository.signIn(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      await _checkAdmin();
    } on OwnerAdminException catch (exception) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = exception.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_stage) {
      _GateStage.checking => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      _GateStage.unavailable => _UnavailableView(
        onBack: () => context.go(AppRoutes.dashboard),
      ),
      _GateStage.login => _buildLogin(context),
      _GateStage.denied => _DeniedView(
        onBack: () => context.go(AppRoutes.dashboard),
      ),
      _GateStage.panel => OwnerAdminScreen(repository: _repository),
    };
  }

  Widget _buildLogin(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إدارة المالك'),
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.onNavy,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Container(
              width: 380,
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      'دخول صاحب المنصّة',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'هذه اللوحة مخصّصة لصاحب المشروع فقط — سجّل دخول '
                      'حساب المنصّة على Supabase.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const ValueKey<String>('owner-login-email'),
                      controller: _email,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (String? raw) {
                        final String value = (raw ?? '').trim();
                        if (value.isEmpty) return 'اكتب البريد الإلكتروني';
                        if (!value.contains('@')) return 'بريد غير صحيح';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey<String>('owner-login-password'),
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'كلمة السرّ',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      validator: (String? raw) =>
                          (raw ?? '').isEmpty ? 'اكتب كلمة السرّ' : null,
                      onFieldSubmitted: (String _) => _submit(),
                    ),
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        key: const ValueKey<String>('owner-login-error'),
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const ValueKey<String>('owner-login-submit'),
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('دخول'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// لا خدمة Supabase مهيّأة — لا بوابة ولا لوحة بلا اتصال.
class _UnavailableView extends StatelessWidget {
  const _UnavailableView({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إدارة المالك'),
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.onNavy,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.cloud_off_rounded,
                size: 44,
                color: AppColors.inkMuted,
              ),
              const SizedBox(height: 12),
              const Text(
                'خدمة Supabase غير مهيّأة',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'أضِف مفاتيح Supabase عبر --dart-define أو env.json ثم أعد '
                'التشغيل — اللوحة تعمل على قاعدة البيانات المباشرة.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.inkMuted),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onBack,
                child: const Text('العودة للوحة التحكم'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// الجلسة قائمة لكن الحساب ليس صاحب المنصّة.
class _DeniedView extends StatelessWidget {
  const _DeniedView({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إدارة المالك'),
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.onNavy,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.lock_outline, size: 44, color: AppColors.danger),
              const SizedBox(height: 12),
              const Text(
                'غير مصرَّح',
                key: ValueKey<String>('owner-gate-denied'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'هذه اللوحة مخصّصة لصاحب المنصّة فقط — حسابك الحالي غير '
                'مُسجَّل في `platform_admins`.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.inkMuted),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onBack,
                child: const Text('العودة للوحة التحكم'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
