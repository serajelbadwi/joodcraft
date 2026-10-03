import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/app_user.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_scaffold.dart';

/// شاشة إنشاء حساب جديد.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _organization = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();

  @override
  void dispose() {
    _fullName.dispose();
    _organization.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final AuthProvider auth = context.read<AuthProvider>();
    try {
      final SignUpOutcome outcome = await auth.signUp(
        email: _email.text,
        password: _password.text,
        fullName: _fullName.text,
        organizationName: _organization.text,
      );

      if (!mounted) return;

      if (outcome.requiresEmailConfirmation) {
        context.showSuccess(
          'تم إنشاء حسابك. تحقّق من بريدك الإلكتروني لتأكيد الحساب ثم سجّل الدخول.',
        );
        context.go(AppRoutes.login);
      } else {
        context.showSuccess('تم إنشاء حسابك. أهلاً بك في جودكرافت.');
      }
    } on AppException catch (error) {
      if (!mounted) return;
      context.showError(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool busy = context.watch<AuthProvider>().isBusy;

    return AuthScaffold(
      title: 'إنشاء حساب',
      subtitle: 'حسابك يحفظ قوالبك وأصولك (الشعار، التوقيع، الختم) لإعادة '
          'استخدامها في كل مشاريعك.',
      // Wrap (لا Row) حتى لا يتجاوز السطر عرض النافذة الضيقة.
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Text(
            'لديك حساب بالفعل؟',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          TextButton(
            onPressed: busy ? null : () => context.go(AppRoutes.login),
            child: const Text('تسجيل الدخول'),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppTextField(
              controller: _fullName,
              label: 'الاسم الكامل',
              hint: 'مثال: عبدالله الأحمد',
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              autofillHints: const <String>[AutofillHints.name],
              enabled: !busy,
              validator: (String? value) =>
                  Validators.displayName(value, fieldName: 'الاسم'),
            ),
            const SizedBox(height: AppTheme.space16),
            AppTextField(
              controller: _organization,
              label: 'اسم الجهة / المؤسسة (اختياري)',
              hint: 'مثال: جمعية جود الخيرية',
              prefixIcon: Icons.apartment_rounded,
              textInputAction: TextInputAction.next,
              enabled: !busy,
              helperText: 'يُطبع على الشهادات والعقود تلقائياً.',
              validator: (String? value) =>
                  Validators.optionalName(value, fieldName: 'اسم الجهة'),
            ),
            const SizedBox(height: AppTheme.space16),
            AppTextField(
              controller: _email,
              label: 'البريد الإلكتروني',
              hint: 'name@organization.com',
              prefixIcon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const <String>[AutofillHints.email],
              textInputFormatterEnabled: false,
              enabled: !busy,
              validator: Validators.email,
            ),
            const SizedBox(height: AppTheme.space16),
            AppTextField(
              controller: _password,
              label: 'كلمة المرور',
              hint: '8 أحرف على الأقل',
              prefixIcon: Icons.lock_outline_rounded,
              obscure: true,
              textInputAction: TextInputAction.next,
              textInputFormatterEnabled: false,
              enabled: !busy,
              helperText:
                  'استخدم ${AppConstants.minPasswordLength} أحرف أو أكثر '
                  'مع أرقام ورموز.',
              validator: Validators.password,
            ),
            const SizedBox(height: AppTheme.space16),
            AppTextField(
              controller: _confirmPassword,
              label: 'تأكيد كلمة المرور',
              hint: '••••••••',
              prefixIcon: Icons.lock_reset_rounded,
              obscure: true,
              textInputAction: TextInputAction.done,
              textInputFormatterEnabled: false,
              enabled: !busy,
              onSubmitted: (_) => busy ? null : _submit(),
              validator: (String? value) =>
                  Validators.confirmPassword(value, _password.text),
            ),
            const SizedBox(height: AppTheme.space24),
            FilledButton(
              onPressed: busy ? null : _submit,
              child: busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Text('إنشاء الحساب'),
            ),
          ],
        ),
      ),
    );
  }
}
