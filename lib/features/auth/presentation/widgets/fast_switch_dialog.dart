import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/admin_account.dart';
import '../providers/admin_accounts_controller.dart';
import '../providers/auth_provider.dart';

/// يفتح حوار **تبديل الحساب السريع** (Fast Switch Admin) ويعيد `true` إن
/// تمّ التبديل بنجاح.
Future<bool?> showFastSwitchDialog(BuildContext context) => showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => const FastSwitchDialog(),
    );

/// حوار سريع لتبديل جلسة الأدمن: اختيار اسم أخر مدخل على الجهاز ثم كلمة
/// مروره — تُطبَّق فوراً عبر [AuthProvider.switchAccount] الذي يحفظ مسودّات
/// المشاريع المفتوحة قبل استبدال الجلسة.
class FastSwitchDialog extends StatefulWidget {
  const FastSwitchDialog({super.key});

  @override
  State<FastSwitchDialog> createState() => _FastSwitchDialogState();
}

class _FastSwitchDialogState extends State<FastSwitchDialog> {
  final TextEditingController _password = TextEditingController();

  /// **اسم المستخدم المحلي** للحساب الفرعي المختار.
  String? _selectedUsername;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // القائمة تُقرأ من متحكّم الإدارة؛ إن كانت فارغة (لم تُحمَّل بعد) تُجلب الآن.
    // الجلب **مؤجَّل إلى ما بعد أول إطار**: إطلاقه أثناء بناء الحوار كان يُبلغ
    // مزوّد الإدارة أثناء البناء فيرمي إطار Flutter خطأ
    // «setState() or markNeedsBuild() called during build».
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final AdminAccountsController admins =
          context.read<AdminAccountsController>();
      if (admins.isAvailable && admins.admins.isEmpty && !admins.isBusy) {
        unawaited(admins.load());
      }
    });
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  /// الحسابات الفرعية الأخرى على هذا الجهاز (باستثناء المسجّل دخوله الآن).
  List<AdminAccount> _others(BuildContext context) {
    final AuthProvider auth = context.read<AuthProvider>();
    final AdminAccountsController admins =
        context.read<AdminAccountsController>();
    final String? currentId = auth.user?.id;
    final String currentEmail = (auth.user?.email ?? '').trim().toLowerCase();
    return admins.admins.where((AdminAccount a) {
      if (currentId != null && a.id == currentId) return false;
      return a.email.trim().toLowerCase() != currentEmail;
    }).toList(growable: false);
  }

  Future<void> _submit(BuildContext context) async {
    final AuthProvider auth = context.read<AuthProvider>();
    final l10n = context.l10n;
    final NavigatorState nav = Navigator.of(context);
    final String? username = _selectedUsername;
    final String password = _password.text;
    if (username == null || username.isEmpty || password.isEmpty) {
      setState(() => _error =
          l10n?.admSwitchPickPassword ?? 'اختر اسم المستخدم وأدخل كلمة المرور.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await auth.switchAccount(username: username, password: password);
      nav.pop(true);
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.message.isEmpty
            ? (l10n?.admSwitchWrongPassword ?? 'كلمة المرور غير صحيحة.')
            : error.message;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error =
            l10n?.admSwitchFailed ?? 'تعذّر تبديل الحساب. حاول مرة أخرى.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<AdminAccount> others = _others(context);
    // حماية القيمة المختارة: بعد نجاح التبديل تتغيّر قائمة «الآخرين» (يصبح
    // الحالي هو الفرعي)، فلا تصلح القيمة القديمة كقيمة للقائمة — وإلا فشل
    // بناء القائمة أثناء إغلاق الحوار.
    final bool selectionStillValid = _selectedUsername != null &&
        others.any((AdminAccount a) =>
            a.effectiveUsername == _selectedUsername);
    final String? dropdownValue = selectionStillValid ? _selectedUsername : null;

    return AlertDialog(
      title: Text(l10n?.admSwitchTitle ?? 'تبديل الحساب السريع'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n?.admSwitchPrompt ??
                  'اختر حساباً آخر على هذا الجهاز وأدخل كلمة مروره للانتقال '
                      'إلى جلساته فوراً — تُحفظ مسودّات المشاريع المفتوحة أولاً.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: AppTheme.space16),
            if (others.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.info_outline_rounded,
                        size: 18, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n?.admSwitchNoOthers ??
                            'لا حسابات أخرى على هذا الجهاز. أضِف مديراً '
                                'جديداً من شاشة إدارة المديرين أولاً.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              )
            else ...<Widget>[
              DropdownButtonFormField<String>(
                key: const ValueKey<String>('fast-switch-pick'),
                initialValue: dropdownValue,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n?.admSwitchPick ?? 'اسم المستخدم المحلي',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: <DropdownMenuItem<String>>[
                  for (final AdminAccount admin in others)
                    DropdownMenuItem<String>(
                      value: admin.effectiveUsername,
                      child: Text(
                        '@${admin.effectiveUsername} — ${admin.displayName}'
                        ' (${admin.role.labelAr})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: _busy
                    ? null
                    : (String? value) =>
                        setState(() => _selectedUsername = value),
              ),
              const SizedBox(height: AppTheme.space12),
              TextField(
                key: const ValueKey<String>('fast-switch-password'),
                controller: _password,
                enabled: !_busy,
                obscureText: true,
                autofocus: true,
                onSubmitted: (_) => _submit(context),
                decoration: InputDecoration(
                  labelText:
                      l10n?.admSwitchPassword ?? 'كلمة المرور المحلية للحساب',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
            if (_error != null) ...<Widget>[
              const SizedBox(height: AppTheme.space8),
              Text(
                _error!,
                key: const ValueKey<String>('fast-switch-error'),
                style: TextStyle(
                    fontSize: 12, color: scheme.error, height: 1.4),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n?.editorCancel ?? 'إلغاء'),
        ),
        FilledButton.icon(
          key: const ValueKey<String>('fast-switch-submit'),
          onPressed: others.isEmpty || _busy ? null : () => _submit(context),
          icon: _busy
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.swap_horiz_rounded, size: 17),
          label: Text(l10n?.admSwitchAction ?? 'تبديل الآن'),
        ),
      ],
    );
  }
}
