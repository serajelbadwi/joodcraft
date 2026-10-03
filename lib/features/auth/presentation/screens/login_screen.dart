import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_scaffold.dart';

/// شاشة تسجيل الدخول.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final AuthProvider auth = context.read<AuthProvider>();
    try {
      await auth.signIn(email: _email.text, password: _password.text);
      if (!mounted) return;
      context.showSuccess('مرحباً بك في جودكرافت.');
    } on AppException catch (error) {
      if (!mounted) return;
      context.showError(error.message);
    }
  }

  Future<void> _openResetPasswordDialog() async {
    // الحقل يملكه ودجت النافذة نفسه (يتنظّف في `dispose`) بدل إنشائه هنا
    // وإتلافه فور ارتجاع `showDialog`: الإتلاف المبكر يقع أثناء حركة إغلاق
    // النافذة بينما `TextField` لا يزال يشير إلى المتحكّم.
    final String? email = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) =>
          _ResetPasswordDialog(initialEmail: _email.text),
    );

    if (email == null || email.isEmpty || !mounted) return;

    try {
      await context.read<AuthProvider>().sendPasswordReset(email);
      if (!mounted) return;
      context.showSuccess('تم إرسال رابط الاستعادة. تحقّق من بريدك الإلكتروني.');
    } on AppException catch (error) {
      if (!mounted) return;
      context.showError(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final bool busy = auth.isBusy;

    return AuthScaffold(
      title: 'تسجيل الدخول',
      subtitle: 'بريدك الإلكتروني وكلمة المرور للمتابعة إلى لوحة التحكم.',
      // Wrap (لا Row) حتى لا يتجاوز السطر عرض النافذة الضيقة.
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Text(
            'ليس لديك حساب؟',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          TextButton(
            onPressed: busy ? null : () => context.go(AppRoutes.register),
            child: const Text('أنشئ حساباً جديداً'),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (auth.isEmailConfirmationPending) ...<Widget>[
              _InfoBanner(
                message: 'تم إنشاء حسابك. يرجى تأكيد بريدك الإلكتروني أولاً '
                    'ثم تسجيل الدخول.',
                onDismiss: auth.clearEmailConfirmationFlag,
              ),
              const SizedBox(height: AppTheme.space20),
            ],
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
            const SizedBox(height: AppTheme.space20),
            AppTextField(
              controller: _password,
              label: 'كلمة المرور',
              hint: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              obscure: true,
              textInputAction: TextInputAction.done,
              autofillHints: const <String>[AutofillHints.password],
              textInputFormatterEnabled: false,
              enabled: !busy,
              onSubmitted: (_) => busy ? null : _submit(),
              validator: Validators.password,
            ),
            const SizedBox(height: AppTheme.space8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: busy ? null : _openResetPasswordDialog,
                child: const Text('نسيت كلمة المرور؟'),
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            FilledButton(
              onPressed: busy ? null : _submit,
              child: busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.navy,
                      ),
                    )
                  : const Text('دخول إلى اللوحة'),
            ),
          ],
        ),
      ),
    );
  }
}

/// نافذة طلب بريد استعادة كلمة المرور — تملك متحكّم حقلها وتُنظّفه بنفسها.
class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({required this.initialEmail});

  final String initialEmail;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _email =
      TextEditingController(text: widget.initialEmail);

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_email.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('استعادة كلمة المرور'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة تعيين كلمة المرور.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.space20),
              AppTextField(
                controller: _email,
                label: 'البريد الإلكتروني',
                hint: 'name@organization.com',
                prefixIcon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputFormatterEnabled: false,
                validator: Validators.email,
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
          onPressed: _submit,
          child: const Text('إرسال الرابط'),
        ),
      ],
    );
  }
}

/// شريط تنبيه معلوماتي (كحلي رمادي بلمسة ذهبية).
class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message, this.onDismiss});

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.mark_email_unread_outlined,
            size: 18,
            color: AppColors.goldDeep,
          ),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.goldDeep,
                  ),
            ),
          ),
          if (onDismiss != null)
            InkWell(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.goldDeep,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
