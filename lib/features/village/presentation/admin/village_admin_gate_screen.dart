/// بوابة دخول **لوحة تحكم القرى**: تسجيل دخول Supabase Auth ثم تحقّق أن
/// الحساب يملك صفّه في `platform_admins`.
///
/// المسار مستقل عن بوابة الدخول المحلية لـ JoodCraft (لا يُفترض أن مفتاح
/// Supabase مهيّأ أصلاً): إن لم تُضبط المفاتيح تُعرض ملاحظة التهيئة، وإن كان
/// هناك جلسة محفوظة ومشرِفاً تُفتح اللوحة مباشرةً دون إعادة إدخال كلمة السر.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/supabase_village_admin_repository.dart';
import '../../data/village_admin_repository.dart';
import '../../data/village_repository.dart';
import '../../domain/village_admin_text.dart';
import 'village_admin_direction.dart';
import 'village_admin_panel_screen.dart';

class VillageAdminGateScreen extends StatefulWidget {
  const VillageAdminGateScreen({super.key, this.repository});

  /// المستودع — `null` في التطبيق (يُبنى فوق `SupabaseService`)، وهميّ في
  /// الاختبارات.
  final VillageAdminRepository? repository;

  @override
  State<VillageAdminGateScreen> createState() => _VillageAdminGateScreenState();
}

class _VillageAdminGateScreenState extends State<VillageAdminGateScreen> {
  late final VillageAdminRepository _repository =
      widget.repository ?? const SupabaseVillageAdminRepository();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _busy = false;
  bool _authenticated = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resumeIfSignedIn();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// جلسة سابقة + صلاحية مشرف ⇒ دخول مباشر إلى اللوحة.
  Future<void> _resumeIfSignedIn() async {
    if (!_repository.isAvailable || !_repository.isSignedIn) return;
    try {
      final bool admin = await _repository.isPlatformAdmin();
      if (!mounted || !admin) return;
      setState(() {
        _authenticated = true;
      });
    } on VillageException {
      // جلسة منتهية أو رفض — نبقى على نموذج الدخول.
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    if (email.isEmpty) {
      setState(() => _error = VillageAdminText.emailRequired);
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = VillageAdminText.passwordRequired);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _repository.signIn(email: email, password: password);
      final bool admin = await _repository.isPlatformAdmin();
      if (!mounted) return;
      if (!admin) {
        // بيانات صحيحة لكن بلا صلاحية: تُغلق الجلسة فوراً.
        await _repository.signOut();
        if (!mounted) return;
        setState(() {
          _busy = false;
          _error = VillageAdminText.notAdmin;
        });
        return;
      }
      setState(() {
        _busy = false;
        _authenticated = true;
      });
    } on VillageException catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = failure.message;
      });
    }
  }

  void _signOut() {
    _repository.signOut();
    setState(() => _authenticated = false);
  }

  @override
  Widget build(BuildContext context) => VillageAdminDirection(
    child: _buildContent(context),
  );

  /// محتوى الشاشة — يُغلَّف بـ[VillageAdminDirection] في [build].
  Widget _buildContent(BuildContext context) {
    if (!_repository.isAvailable) return const _UnavailableNote();

    if (_authenticated) {
      return VillageAdminPanelScreen(
        repository: _repository,
        onSignOut: _signOut,
      );
    }

    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(VillageAdminText.gateTitle),
        leading: IconButton(
          key: const ValueKey<String>('village-admin-gate-back'),
          icon: const Icon(Icons.arrow_forward_rounded),
          tooltip: 'رجوع',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).maybePop();
            }
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 44,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: AppTheme.space12),
                      Text(
                        VillageAdminText.gateTitle,
                        textAlign: TextAlign.center,
                        style: text.headlineSmall,
                      ),
                      const SizedBox(height: AppTheme.space8),
                      Text(
                        VillageAdminText.gateSubtitle,
                        textAlign: TextAlign.center,
                        style: text.bodySmall?.copyWith(
                          color: text.bodySmall?.color?.withValues(alpha: 0.75),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space20),
                      TextFormField(
                        key: const ValueKey<String>('village-admin-email'),
                        controller: _emailController,
                        enabled: !_busy,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          labelText: VillageAdminText.emailLabel,
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: AppTheme.space16),
                      TextFormField(
                        key: const ValueKey<String>('village-admin-password'),
                        controller: _passwordController,
                        enabled: !_busy,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: VillageAdminText.passwordLabel,
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      if (_error != null) ...<Widget>[
                        const SizedBox(height: AppTheme.space12),
                        Text(
                          _error!,
                          key: const ValueKey<String>(
                            'village-admin-gate-error',
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppTheme.space20),
                      FilledButton(
                        key: const ValueKey<String>('village-admin-submit'),
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(VillageAdminText.signIn),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ملاحظة غياب تهيئة Supabase — منطق نفسه لملاحظة الصفحة العامة.
class _UnavailableNote extends StatelessWidget {
  const _UnavailableNote();

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text(VillageAdminText.gateTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.cloud_off_rounded, size: 40),
                const SizedBox(height: AppTheme.space12),
                Text(VillageAdminText.unavailableBody, style: text.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
