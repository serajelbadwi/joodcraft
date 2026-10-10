import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/audit/export_audit_log.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../data/admin_config_cipher.dart';
import '../../domain/admin_account.dart';
import '../providers/admin_accounts_controller.dart';

/// **إدارة المديرين محلياً** — ثلاث تبويبات:
///
/// 1. **المديرون**: إضافة مدير وتعديل بياناته وتغيير كلمة مروره وحذفه، وكلها
///    تُخزَّن على هذا الجهاز بكلمات مرور مُجزّأة بـPBKDF2.
/// 2. **النقل بين الأجهزة**: تصدير الحسابات في شفرة/ملف **مشفّر بعبارة مرور**
///    واستيرادها في جهاز آخر، فيعمل بنفس الحسابات والصلاحيات بلا شبكة.
/// 3. **سجل التصدير**: أرشيف محلي لكل شهادة/عقد صدر، بتاريخه والمدير الذي صدره.
class AdminAccountsScreen extends StatefulWidget {
  const AdminAccountsScreen({super.key, this.controller, this.auditLog});

  /// للاختبارات وشاشات المعاينة: يُمرَّر المتحكّم مباشرةً بلا توفير من الأب.
  final AdminAccountsController? controller;
  final ExportAuditLog? auditLog;

  @override
  State<AdminAccountsScreen> createState() => _AdminAccountsScreenState();
}

class _AdminAccountsScreenState extends State<AdminAccountsScreen> {
  late AdminAccountsController _admins;
  late ExportAuditLog _audit;
  bool _initialized = false;

  final TextEditingController _exportPassphrase = TextEditingController();
  final TextEditingController _exportConfirm = TextEditingController();
  final TextEditingController _importPassphrase = TextEditingController();
  final TextEditingController _importCode = TextEditingController();
  bool _replaceExisting = false;
  String? _exportedCode;
  bool _acceptRisk = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    _admins = widget.controller ?? _lookup<AdminAccountsController>(
      () => context.read<AdminAccountsController>(),
      fallback: AdminAccountsController(null),
    );
    _audit = widget.auditLog ??
        _lookup<ExportAuditLog>(
          () => context.read<ExportAuditLog>(),
          fallback: ExportAuditLog.instance,
        );

    // **الجلب يبدأ بعد بناء أول إطار**: إطلاقه مباشرةً من هنا كان يُبلغ
    // المزوّدات أثناء بناء الشجرة، فيرمي إطار Flutter خطأ
    // «setState() or markNeedsBuild() called during build» ويحلّ `ErrorWidget`
    // محلّ الشاشة — فلا يظهر جدول المديرين على الجهاز المحلي.
    // **الجلب يبدأ بعد بناء أول إطار**: إطلاقه مباشرةً من هنا كان يُبلغ
    // المزوّدات أثناء بناء الشجرة، فيرمي إطار Flutter خطأ
    // «setState() or markNeedsBuild() called during build» ويحلّ `ErrorWidget`
    // محلّ الشاشة — فلا يظهر جدول المديرين على الجهاز المحلي.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_admins.load());
      unawaited(_audit.restore());
    });
  }

  /// قراءة مزوّد من الشجرة مع بديل آمن إن لم يكن مُوفَّراً (اختبار شاشة منفردة).
  T _lookup<T>(T Function() read, {required T fallback}) {
    try {
      return read();
    } catch (_) {
      return fallback;
    }
  }

  @override
  void dispose() {
    _exportPassphrase.dispose();
    _exportConfirm.dispose();
    _importPassphrase.dispose();
    _importCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        appBar: AppBar(
          title: Text(context.l10n?.admTitle ?? 'إدارة المديرين المحليين'),
          actions: <Widget>[
            IconButton(
              key: const ValueKey<String>('adm-refresh'),
              tooltip: context.l10n?.admRefresh ?? 'تحديث',
              onPressed: _admins.isBusy ? null : () => unawaited(_admins.load()),
              icon: const Icon(Icons.refresh_rounded),
            ),
            const SizedBox(width: AppTheme.space8),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: <Widget>[
              Tab(
                key: const ValueKey<String>('adm-tab-admins'),
                icon: const Icon(Icons.admin_panel_settings_rounded, size: 18),
                text: context.l10n?.admTabAdmins ?? 'المديرون',
              ),
              Tab(
                key: const ValueKey<String>('adm-tab-transfer'),
                icon: const Icon(Icons.devices_rounded, size: 18),
                text: context.l10n?.admTabTransfer ?? 'النقل بين الأجهزة',
              ),
              Tab(
                key: const ValueKey<String>('adm-tab-audit'),
                icon: const Icon(Icons.history_edu_rounded, size: 18),
                text: context.l10n?.admTabAudit ?? 'سجل التصدير',
              ),
            ],
          ),
        ),
        body: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[_admins, _audit]),
          builder: (BuildContext context, Widget? _) => TabBarView(
            children: <Widget>[
              _adminsTab(),
              _transferTab(),
              _auditTab(),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  //                        التبويب 1: المديرون
  // ==========================================================================

  Widget _adminsTab() {
    if (!_admins.isAvailable) return _unavailableCard();

    final List<AdminAccount> admins = _admins.admins;
    final AdminAccount? current =
        admins.where((AdminAccount a) => a.isCurrent).firstOrNull;
    return _scroll(
      children: <Widget>[
        if (current != null) _currentAccountCard(current),
        _card(
          key: const ValueKey<String>('adm-list-card'),
          title: context.l10n?.admListTitle ?? 'حسابات المديرين على هذا الجهاز',
          icon: Icons.admin_panel_settings_rounded,
          // الأزرار داخل صف تحتاج `minimumSize` منتهياً: الثيم العام يضبط
          // العرض الأدنى على ما لا نهاية (Size.fromHeight) — صحيح داخل عمود
          // ممتدّ لكنه غير صالح داخل صف، فيهبط تخطيط البطاقة كلها ولا يظهر
          // الجدول.
          trailing: FilledButton.icon(
            key: const ValueKey<String>('adm-add'),
            onPressed: _admins.isBusy ? null : _openCreateDialog,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, AppTheme.controlHeight),
            ),
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
            label: Text(context.l10n?.admAdd ?? 'إضافة مدير'),
          ),
          child: _adminsListBody(admins),
        ),
        if (_admins.errorMessage != null)
          _errorBanner(_admins.errorMessage!),
      ],
    );
  }

  /// محتوى قائمة المديرين — ثلاث حالات متبادلة **حتى لا يختفي الجدول كلياً**:
  ///
  /// 1. صفوف الجدول (ترويسة + سجلات) متى وُجدت بيانات.
  /// 2. مؤشّر تحميل أثناء جلب أولي أو تحديث (لا رسالة «لا حسابات» الكاذبة).
  /// 3. حالة الفراغ الحقيقية بعد اكتمال التحميل بنجاح.
  Widget _adminsListBody(List<AdminAccount> admins) {
    if (admins.isNotEmpty) {
      return Column(
        children: <Widget>[
          _adminsTableHeader(),
          const SizedBox(height: AppTheme.space8),
          for (final AdminAccount admin in admins) _adminRow(admin),
        ],
      );
    }
    if (!_admins.isLoaded || _admins.isBusy) {
      return _loadingRow(context.l10n?.admLoading ??
          'جارٍ تحميل حسابات المديرين على هذا الجهاز…');
    }
    return _emptyHint(context.l10n?.admNoAdmins ?? 'لا حسابات مديرين بعد.');
  }

  /// صفّ التحميل: مؤشّر دوّار مع نصّ — يحلّ محلّ نصّ «لا حسابات» الفارغ
  /// طوال فترة جلب البيانات من المخزن المحلي.
  Widget _loadingRow(String label) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      key: const ValueKey<String>('adm-loading'),
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space12),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  /// بطاقة الحساب الحالي: المدير المسجّل دخوله على هذا الجهاز الآن.
  Widget _currentAccountCard(AdminAccount admin) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space16),
      child: Card(
        key: const ValueKey<String>('adm-current-card'),
        color: scheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space20),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 24,
                backgroundColor: scheme.primary,
                child: Text(
                  admin.initials,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      context.l10n?.admCurrentCardTitle ?? 'الحساب الحالي على الجهاز',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            admin.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _chip(
                          admin.role == AdminRole.owner
                              ? (context.l10n?.admRoleOwner ??
                                  AdminRole.owner.labelAr)
                              : (context.l10n?.admRoleAdmin ??
                                  AdminRole.admin.labelAr),
                          color: admin.role == AdminRole.owner
                              ? AppColors.goldDeep
                              : scheme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      admin.email,
                      textDirection: TextDirection.ltr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: context.l10n?.admChangePassword ?? 'تغيير كلمة المرور',
                child: IconButton.filledTonal(
                  key: const ValueKey<String>('adm-current-password'),
                  onPressed: _admins.isBusy
                      ? null
                      : () => _openPasswordDialog(admin),
                  icon: const Icon(Icons.lock_reset_rounded, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// عرض أعمدة الجدول: [المدير, اسم المستخدم المحلي, الصلاحية, تاريخ الإضافة].
  /// يتشاركه الترويسة والصفوف فتبقى الأعمدة متحاذية تماماً.
  static const List<int> _adminColFlex = <int>[3, 2, 2, 2];

  /// عرض خانة الإجراءات (تعديل/كلمة المرور/حذف + قائمة كاملة).
  static const double _adminActionsWidth = 184;

  /// ترويسة جدول المديرين — عناوين الأعمدة فوق الصفوف.
  Widget _adminsTableHeader() {
    final TextTheme text = Theme.of(context).textTheme;
    final Color color = Theme.of(context).colorScheme.onSurfaceVariant;

    Widget cell(String label, int flex) => Expanded(
          flex: flex,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        );

    return Container(
      key: const ValueKey<String>('adm-table-header'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space12,
        vertical: AppTheme.space8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        children: <Widget>[
          cell(context.l10n?.admColAdmin ?? 'المدير', _adminColFlex[0]),
          cell(
            context.l10n?.admColUsername ?? 'اسم المستخدم المحلي',
            _adminColFlex[1],
          ),
          cell(context.l10n?.admColRole ?? 'الصلاحية', _adminColFlex[2]),
          cell(context.l10n?.admColCreated ?? 'تاريخ الإضافة', _adminColFlex[3]),
          SizedBox(
            width: _adminActionsWidth,
            child: Text(
              context.l10n?.admColActions ?? 'إجراءات',
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// صفّ جدول واحد (بطاقة) بأعمدة متحاذية مع الترويسة.
  Widget _adminRow(AdminAccount admin) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      key: ValueKey<String>('adm-row-${admin.id}'),
      padding: const EdgeInsets.only(bottom: AppTheme.space8),
      child: Card(
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: scheme.outline),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space12,
            vertical: AppTheme.space10,
          ),
          child: Row(
            children: <Widget>[
              // العمود 1: المدير (الصورة الرمزية + الاسم + البريد).
              Expanded(
                flex: _adminColFlex[0],
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: admin.isOwner
                          ? AppColors.goldSoft
                          : scheme.surfaceContainerHighest,
                      child: Text(
                        admin.initials,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: admin.isOwner
                              ? AppColors.goldDeep
                              : scheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  admin.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.titleSmall,
                                ),
                              ),
                              if (admin.isCurrent) ...<Widget>[
                                const SizedBox(width: 6),
                                _chip(
                                  context.l10n?.admCurrent ?? 'أنت',
                                  color: scheme.primary,
                                ),
                              ],
                            ],
                          ),
                          Text(
                            admin.email,
                            textDirection: TextDirection.ltr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // العمود 2: اسم المستخدم المحلي للتبديل السريع.
              Expanded(
                flex: _adminColFlex[1],
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    '@${admin.effectiveUsername}',
                    key: ValueKey<String>('adm-username-${admin.id}'),
                    textDirection: TextDirection.ltr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              // العمود 3: الصلاحية / الدور.
              Expanded(
                flex: _adminColFlex[2],
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: admin.isOwner
                      ? _chip(
                          context.l10n?.admRoleOwner ?? AdminRole.owner.labelAr,
                          color: AppColors.goldDeep,
                        )
                      : _chip(
                          context.l10n?.admRoleAdmin ?? AdminRole.admin.labelAr,
                          color: scheme.onSurfaceVariant,
                        ),
                ),
              ),
              // العمود 4: تاريخ الإضافة.
              Expanded(
                flex: _adminColFlex[3],
                child: Text(
                  _formatDate(admin.createdAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall,
                ),
              ),
              // عمود الإجراءات: تعديل/كلمة المرور/حذف + قائمة كاملة.
              SizedBox(
                width: _adminActionsWidth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    IconButton(
                      key: ValueKey<String>('adm-edit-${admin.id}'),
                      tooltip: context.l10n?.admEdit ?? 'تعديل البيانات',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 38,
                        minHeight: 38,
                      ),
                      iconSize: 18,
                      onPressed: _admins.isBusy
                          ? null
                          : () => _onAdminAction(_AdminAction.edit, admin),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      key: ValueKey<String>('adm-password-${admin.id}'),
                      tooltip:
                          context.l10n?.admChangePassword ?? 'تغيير كلمة المرور',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 38,
                        minHeight: 38,
                      ),
                      iconSize: 18,
                      onPressed: _admins.isBusy
                          ? null
                          : () => _onAdminAction(_AdminAction.password, admin),
                      icon: const Icon(Icons.lock_reset_rounded),
                    ),
                    IconButton(
                      key: ValueKey<String>('adm-delete-${admin.id}'),
                      tooltip: context.l10n?.admDelete ?? 'حذف الحساب',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 38,
                        minHeight: 38,
                      ),
                      iconSize: 18,
                      onPressed: admin.isCurrent || _admins.isBusy
                          ? null
                          : () => _onAdminAction(_AdminAction.delete, admin),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: admin.isCurrent ? null : scheme.error,
                      ),
                    ),
                    PopupMenuButton<_AdminAction>(
                      key: ValueKey<String>('adm-menu-${admin.id}'),
                      tooltip: '',
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                      onSelected: (_AdminAction action) =>
                          _onAdminAction(action, admin),
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<_AdminAction>>[
                        PopupMenuItem<_AdminAction>(
                          value: _AdminAction.edit,
                          child: _menuRow(
                            Icons.edit_outlined,
                            context.l10n?.admEdit ?? 'تعديل البيانات',
                          ),
                        ),
                        PopupMenuItem<_AdminAction>(
                          value: _AdminAction.password,
                          child: _menuRow(
                            Icons.lock_reset_rounded,
                            context.l10n?.admChangePassword ??
                                'تغيير كلمة المرور',
                          ),
                        ),
                        if (admin.isOwner)
                          PopupMenuItem<_AdminAction>(
                            value: _AdminAction.demote,
                            child: _menuRow(
                              Icons.arrow_downward_rounded,
                              context.l10n?.admDemote ?? 'تخفيض إلى «مدير»',
                            ),
                          )
                        else
                          PopupMenuItem<_AdminAction>(
                            value: _AdminAction.promote,
                            child: _menuRow(
                              Icons.arrow_upward_rounded,
                              context.l10n?.admPromote ??
                                  'ترقية إلى «مدير رئيسي»',
                            ),
                          ),
                        const PopupMenuDivider(),
                        PopupMenuItem<_AdminAction>(
                          value: _AdminAction.delete,
                          child: _menuRow(
                            Icons.delete_outline_rounded,
                            context.l10n?.admDelete ?? 'حذف الحساب',
                            danger: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onAdminAction(_AdminAction action, AdminAccount admin) async {
    switch (action) {
      case _AdminAction.edit:
        await _openEditDialog(admin);
      case _AdminAction.password:
        await _openPasswordDialog(admin);
      case _AdminAction.promote:
        await _run(
          () => _admins.updateProfile(
            id: admin.id,
            fullName: admin.fullName ?? admin.displayName,
            organizationName: admin.organizationName,
            role: AdminRole.owner,
          ),
          success: context.l10n?.admPromoted ?? 'تمت الترقية إلى «مدير رئيسي».',
        );
      case _AdminAction.demote:
        await _run(
          () => _admins.updateProfile(
            id: admin.id,
            fullName: admin.fullName ?? admin.displayName,
            organizationName: admin.organizationName,
            role: AdminRole.admin,
          ),
          success: context.l10n?.admDemoted ?? 'تم التخفيض إلى «مدير».',
        );
      case _AdminAction.delete:
        // تُلتقط النصوص **قبل** الانتظار حتى لا يُقرأ السياق بعد فجوة async.
        final String title = context.l10n?.admDelete ?? 'حذف الحساب';
        final String message = context.l10n?.admDeleteConfirm(admin.displayName) ??
            'سيُحذف «${admin.displayName}» من هذا الجهاز نهائياً.';
        final String success = context.l10n?.admDeleted ?? 'حُذف الحساب.';
        final bool? confirmed = await _confirm(title: title, message: message);
        if (confirmed != true) return;
        await _run(() => _admins.remove(admin.id), success: success);
    }
  }

  // ==========================================================================
  //                    التبويب 2: النقل بين الأجهزة
  // ==========================================================================

  Widget _transferTab() {
    return _scroll(
      children: <Widget>[
        _infoCard(
          key: const ValueKey<String>('adm-transfer-info'),
          icon: Icons.info_outline_rounded,
          title: context.l10n?.admTransferInfoTitle ?? 'كيف يعمل النقل؟',
          lines: <String>[
            context.l10n?.admTransferInfo1 ??
                'يُصدَّر جدول الحسابات (ببصمات كلمات المرور لا كلماتها) داخل ملف '
                    'مشفّر بعبارة مرور تختارها.',
            context.l10n?.admTransferInfo2 ??
                'انقل الملف أو الشفرة إلى الجهاز الآخر، ثم استوردها هناك '
                    'بالعبارة نفسها لتعمل الحسابات بنفس الصلاحيات.',
            context.l10n?.admTransferInfo3 ??
                'لا يُرسل شيء إلى أي سيرفر: النقل يدوي بالكامل بين أجهزة محلية.',
          ],
        ),
        _exportCard(),
        _importCard(),
      ],
    );
  }

  Widget _exportCard() {
    final bool busy = _admins.isBusy || !_admins.isAvailable;
    return _card(
      key: const ValueKey<String>('adm-export-card'),
      title: context.l10n?.admExport ?? 'تصدير الحسابات',
      icon: Icons.ios_share_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _passphraseField(
            key: const ValueKey<String>('adm-export-pass'),
            controller: _exportPassphrase,
            label: context.l10n?.admExportPassphrase ?? 'عبارة مرور التصدير',
            enabled: !busy,
          ),
          const SizedBox(height: AppTheme.space12),
          _passphraseField(
            key: const ValueKey<String>('adm-export-pass2'),
            controller: _exportConfirm,
            label: context.l10n?.admPassphraseConfirm ?? 'تأكيد العبارة',
            enabled: !busy,
          ),
          const SizedBox(height: AppTheme.space12),
          CheckboxListTile(
            key: const ValueKey<String>('adm-accept-risk'),
            value: _acceptRisk,
            onChanged: busy
                ? null
                : (bool? value) => setState(() => _acceptRisk = value ?? false),
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              context.l10n?.admExportRisk ??
                  'أفهم أن من يملك هذه الشفرة وعبارتها يستطيع الدخول بالحسابات.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          Wrap(
            spacing: AppTheme.space8,
            runSpacing: AppTheme.space8,
            children: <Widget>[
              FilledButton.icon(
                key: const ValueKey<String>('adm-export-run'),
                onPressed: busy ? null : _runExport,
                icon: const Icon(Icons.key_rounded, size: 16),
                label: Text(
                  context.l10n?.admExportGenerate ?? 'توليد الشفرة المشفّرة',
                ),
              ),
              OutlinedButton.icon(
                key: const ValueKey<String>('adm-export-file'),
                onPressed: busy || _exportedCode == null ? null : _saveCodeToFile,
                icon: const Icon(Icons.save_alt_rounded, size: 16),
                label: Text(context.l10n?.admExportFile ?? 'حفظ في ملف خاص'),
              ),
            ],
          ),
          if (_exportedCode != null) ...<Widget>[
            const SizedBox(height: AppTheme.space12),
            Container(
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: SelectableText(
                _exportedCode!,
                key: const ValueKey<String>('adm-export-code'),
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontSize: 11.5, height: 1.35),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _importCard() {
    final bool busy = _admins.isBusy || !_admins.isAvailable;
    return _card(
      key: const ValueKey<String>('adm-import-card'),
      title: context.l10n?.admImport ?? 'استيراد الحسابات',
      icon: Icons.download_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            key: const ValueKey<String>('adm-import-code'),
            controller: _importCode,
            enabled: !busy,
            maxLines: 4,
            minLines: 3,
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontSize: 11.5),
            decoration: InputDecoration(
              labelText: context.l10n?.admImportCode ?? 'شفرة الحسابات',
              hintText: '${AdminConfigCipher.header}.…',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          _passphraseField(
            key: const ValueKey<String>('adm-import-pass'),
            controller: _importPassphrase,
            label: context.l10n?.admImportPassphrase ?? 'عبارة مرور الملف',
            enabled: !busy,
          ),
          SwitchListTile(
            key: const ValueKey<String>('adm-import-replace'),
            value: _replaceExisting,
            onChanged: busy
                ? null
                : (bool value) => setState(() => _replaceExisting = value),
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              context.l10n?.admImportReplace ??
                  'استبدال كلمات مرور الحسابات الموجودة',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          Wrap(
            spacing: AppTheme.space8,
            runSpacing: AppTheme.space8,
            children: <Widget>[
              OutlinedButton.icon(
                key: const ValueKey<String>('adm-import-pick'),
                onPressed: busy ? null : _pickCodeFile,
                icon: const Icon(Icons.folder_open_rounded, size: 16),
                label: Text(context.l10n?.admImportPick ?? 'اختيار ملف'),
              ),
              FilledButton.icon(
                key: const ValueKey<String>('adm-import-run'),
                onPressed: busy ? null : _runImport,
                icon: const Icon(Icons.file_download_done_rounded, size: 16),
                label: Text(context.l10n?.admImportRun ?? 'استيراد الآن'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _runExport() async {
    final String passphrase = _exportPassphrase.text;
    if (passphrase.trim().length < 6) {
      context.showWarning(
        context.l10n?.admPassphraseTooShort ??
            'اجعل عبارة المرور 6 أحرف على الأقل.',
      );
      return;
    }
    if (passphrase != _exportConfirm.text) {
      context.showWarning(
        context.l10n?.admPassphraseMismatch ?? 'العبارتان غير متطابقتين.',
      );
      return;
    }
    if (!_acceptRisk) {
      context.showWarning(
        context.l10n?.admAcceptRiskRequired ??
            'أكّد أولاً أنك تفهم مخاطر مشاركة الشفرة.',
      );
      return;
    }
    try {
      final String code = await _admins.exportConfig(passphrase: passphrase);
      if (!mounted) return;
      setState(() => _exportedCode = code);
      context.showSuccess(
        context.l10n?.admExportDone ?? 'توليدت الشفرة المشفّرة. انسخها أو احفظها.',
      );
    } on AppException catch (error) {
      if (mounted) context.showError(error.message);
    }
  }

  Future<void> _saveCodeToFile() async {
    final String? code = _exportedCode;
    if (code == null) return;
    try {
      final Uri? saved = await FilePicker.saveFile(
        dialogTitle: context.l10n?.admExport ?? 'تصدير الحسابات',
        fileName: AdminConfigCipher.suggestedFileName,
        bytes: Uint8List.fromList(utf8.encode(code)),
        mimeType: AdminConfigCipher.mimeType,
        type: FileType.custom,
        allowedExtensions: <String>[AdminConfigCipher.fileExtension],
      );
      if (!mounted || saved == null) return;
      context.showSuccess(
        context.l10n?.admExportFileSaved ?? 'حُفظ ملف الحسابات المشفّر.',
      );
    } on Object catch (error) {
      if (mounted) {
        context.showError(
          context.l10n?.admFileError(error) ?? 'تعذّر حفظ الملف: $error',
        );
      }
    }
  }

  Future<void> _pickCodeFile() async {
    final List<PlatformFile> picked;
    try {
      picked = await FilePicker.pickFiles(
        dialogTitle: context.l10n?.admImportPick ?? 'اختيار ملف',
        type: FileType.custom,
        allowedExtensions: <String>[
          AdminConfigCipher.fileExtension,
          'txt',
        ],
      );
    } catch (error) {
      if (mounted) {
        context.showError(
          context.l10n?.admFileError(error) ?? 'تعذّر فتح منتقي الملفات: $error',
        );
      }
      return;
    }
    if (picked.isEmpty) return;
    try {
      final Uint8List bytes = await picked.first.readAsBytes();
      if (!mounted) return;
      setState(() => _importCode.text = utf8.decode(bytes));
    } catch (error) {
      if (mounted) {
        context.showError(
          context.l10n?.admFileError(error) ?? 'تعذّر قراءة الملف: $error',
        );
      }
    }
  }

  Future<void> _runImport() async {
    final String code = _importCode.text.trim();
    if (code.isEmpty) {
      context.showWarning(
        context.l10n?.admImportCodeRequired ?? 'ألصق الشفرة أو اختر ملفاً أولاً.',
      );
      return;
    }
    if (_importPassphrase.text.isEmpty) {
      context.showWarning(
        context.l10n?.admImportPassphraseRequired ?? 'أدخل عبارة مرور الملف.',
      );
      return;
    }
    try {
      final AdminImportReport report = await _admins.importConfig(
        code: code,
        passphrase: _importPassphrase.text,
        replaceExisting: _replaceExisting,
      );
      if (!mounted) return;
      context.showSuccess(
        context.l10n?.admImportDone(
              report.added,
              report.updated,
              report.skipped,
            ) ??
            'تمّ الاستيراد: ${report.added} جديد، '
                '${report.updated} مُحدَّث، ${report.skipped} مُتخطّى.',
      );
      setState(() => _importCode.clear());
    } on AppException catch (error) {
      if (mounted) context.showError(error.message);
    }
  }

  // ==========================================================================
  //                        التبويب 3: سجل التصدير
  // ==========================================================================

  Widget _auditTab() {
    final List<ExportAuditEntry> entries = _audit.entries;
    return _scroll(
      children: <Widget>[
        _card(
          key: const ValueKey<String>('adm-audit-card'),
          title: context.l10n?.admAuditTitle ?? 'سجل الشهادات والمستندات الصادرة',
          icon: Icons.history_edu_rounded,
          trailing: TextButton.icon(
            key: const ValueKey<String>('adm-audit-clear'),
            onPressed: entries.isEmpty ? null : _clearAudit,
            icon: const Icon(Icons.delete_sweep_rounded, size: 16),
            label: Text(context.l10n?.admAuditClear ?? 'تفريغ السجل'),
          ),
          child: entries.isEmpty
              ? _emptyHint(
                  context.l10n?.admAuditEmpty ??
                      'لا سجلات تصدير بعد. كل شهادة أو عقد تصدّره سيُسجَّل هنا '
                          'بالتاريخ والمدير.',
                )
              : Column(
                  children: <Widget>[
                    for (final ExportAuditEntry entry in entries)
                      _auditRow(entry),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _auditRow(ExportAuditEntry entry) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space8),
      child: Container(
        key: ValueKey<String>('adm-audit-${entry.id}'),
        padding: const EdgeInsets.all(AppTheme.space12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: scheme.outline),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              switch (entry.kind) {
                ExportKind.certificate => Icons.workspace_premium_rounded,
                ExportKind.contract => Icons.article_rounded,
                ExportKind.batch => Icons.table_view_rounded,
                ExportKind.project => Icons.folder_zip_rounded,
                ExportKind.preview => Icons.print_rounded,
              },
              size: 18,
              color: scheme.goldDeep,
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    entry.documentTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      _chip(entry.kind.labelAr, color: scheme.primary),
                      _chip(
                        '${context.l10n?.admAuditBy ?? 'بواسطة'}: ${entry.adminLabel}',
                        color: AppColors.goldDeep,
                      ),
                      if (entry.pageCount > 1)
                        _chip(
                          '${entry.pageCount} ${context.l10n?.admAuditPages ?? 'صفحة'}',
                          color: scheme.onSurfaceVariant,
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(entry.at) +
                        (entry.fileName == null ? '' : '  ·  ${entry.fileName}'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearAudit() async {
    final bool? confirmed = await _confirm(
      title: context.l10n?.admAuditClear ?? 'تفريغ السجل',
      message: context.l10n?.admAuditClearConfirm ??
          'سيُحذف كل سجل التصدير من هذا الجهاز. لا يمكن التراجع.',
    );
    if (confirmed != true) return;
    await _audit.clear();
    if (mounted) {
      context.showSuccess(context.l10n?.admAuditCleared ?? 'تم تفريغ السجل.');
    }
  }

  // ==========================================================================
  //                             نوافذ الحوار
  // ==========================================================================

  Future<void> _openCreateDialog() async {
    final _AdminDraft? draft = await showDialog<_AdminDraft>(
      context: context,
      builder: (BuildContext dialogContext) => _AdminEditorDialog(
        title: context.l10n?.admAdd ?? 'إضافة مدير',
        requirePassword: true,
      ),
    );
    if (draft == null || !mounted) return;
    await _run<void>(
      () => _admins.create(
        email: draft.email,
        password: draft.password ?? '',
        fullName: draft.fullName,
        organizationName: draft.organizationName,
        username: draft.username,
        role: draft.role,
      ),
      success: context.l10n?.admCreated ?? 'أُضيف المدير الجديد.',
    );
  }

  Future<void> _openEditDialog(AdminAccount admin) async {
    final _AdminDraft? draft = await showDialog<_AdminDraft>(
      context: context,
      builder: (BuildContext dialogContext) => _AdminEditorDialog(
        title: context.l10n?.admEdit ?? 'تعديل البيانات',
        requirePassword: false,
        email: admin.email,
        username: admin.username ?? '',
        fullName: admin.fullName ?? '',
        organizationName: admin.organizationName ?? '',
        role: admin.role,
      ),
    );
    if (draft == null || !mounted) return;
    await _run(
      () => _admins.updateProfile(
        id: admin.id,
        fullName: draft.fullName,
        organizationName: draft.organizationName,
        username: draft.username,
        role: draft.role,
      ),
      success: context.l10n?.admUpdated ?? 'حُدّثت بيانات المدير.',
    );
  }

  Future<void> _openPasswordDialog(AdminAccount admin) async {
    final _PasswordDraft? draft = await showDialog<_PasswordDraft>(
      context: context,
      builder: (BuildContext dialogContext) => _PasswordDialog(
        title: context.l10n?.admChangePassword ?? 'تغيير كلمة المرور',
        requiresCurrent: admin.isCurrent,
        subject: admin.displayName,
      ),
    );
    if (draft == null || !mounted) return;
    await _run(
      () => _admins.setPassword(
        id: admin.id,
        newPassword: draft.newPassword,
        currentPassword: draft.currentPassword,
      ),
      success: context.l10n?.admPasswordChanged ?? 'تغيّرت كلمة المرور.',
    );
  }

  // ==========================================================================
  //                             أدوات بناء الواجهة
  // ==========================================================================

  Widget _scroll({required List<Widget> children}) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      );

  Widget _card({
    required Key key,
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space16),
      child: Card(
        key: key,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(icon,
                      size: 18, color: Theme.of(context).colorScheme.goldDeep),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(title,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  ?trailing,
                ],
              ),
              const SizedBox(height: AppTheme.space16),
              child,
            ],
          ),
        ),
      ),
    );
  }

  /// لون النص الداكن الثابت داخل بطاقات المعلومات — الخلفية `goldSoft` فاتحة
  /// دائماً، فالنص لا يأخذ لون الثيم (كان يصبح فاتحاً في الوضع الداكن فلا
  /// يُقرأ) بل يبقى داكناً صريحاً في الوضعين.
  static const Color _infoInk = Colors.black87;
  static const Color _infoInkSoft = Color(0xFF424242); // Colors.grey[800]

  Widget _infoCard({
    required Key key,
    required IconData icon,
    required String title,
    required List<String> lines,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space16),
      child: Card(
        key: key,
        color: AppColors.goldSoft,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget> [
              Row(
                children: <Widget>[
                  Icon(icon, size: 18, color: AppColors.goldDeep),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium!
                          .copyWith(color: _infoInk),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space8),
              for (final String line in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('•  ',
                          style: const TextStyle(color: _infoInkSoft)),
                      Expanded(
                        child: Text(
                          line,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(color: _infoInkSoft, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _unavailableCard() => _scroll(
        children: <Widget>[
          _infoCard(
            key: const ValueKey<String>('adm-unavailable'),
            icon: Icons.info_outline_rounded,
            title: context.l10n?.admUnavailableTitle ?? 'الإدارة غير متاحة الآن',
            lines: <String>[
              context.l10n?.admUnavailableBody ??
                  'إدارة المديرين تعمل عندما يُشغَّل التطبيق بحساب محلي '
                      '(LocalAuthRepository).',
            ],
          ),
        ],
      );

  Widget _passphraseField({
    required Key key,
    required TextEditingController controller,
    required String label,
    required bool enabled,
  }) {
    return TextField(
      key: key,
      controller: controller,
      enabled: enabled,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Widget _emptyHint(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      );

  Widget _errorBanner(String message) => Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Text(
            message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ),
      );

  Widget _chip(String label, {required Color color}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: color),
        ),
      );

  Widget _menuRow(IconData icon, String label, {bool danger = false}) => Row(
        children: <Widget>[
          Icon(icon, size: 16),
          const SizedBox(width: AppTheme.space8),
          Text(
            label,
            style: danger
                ? TextStyle(color: Theme.of(context).colorScheme.error)
                : null,
          ),
        ],
      );

  /// ينفّذ عملية على المتحكّم موحّداً: انشغال + رسالة نجاح/خطأ.
  Future<T?> _run<T>(Future<T> Function() action, {required String success}) async {
    try {
      final T result = await action();
      if (mounted) context.showSuccess(success);
      return result;
    } on AppException catch (error) {
      if (mounted) context.showError(error.message);
      return null;
    }
  }

  Future<bool?> _confirm({required String title, required String message}) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n?.editorCancel ?? 'إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n?.editorConfirm ?? 'تأكيد'),
          ),
        ],
      ),
    );
  }

  /// تنسيق تاريخ بلا اعتماد على `intl`: `yyyy/MM/dd HH:mm`.
  static String _formatDate(DateTime? value) {
    if (value == null) return '—';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}/${two(value.month)}/${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}';
  }
}

/// إجراءات سطر المدير.
enum _AdminAction { edit, password, promote, demote, delete }

/// بيانات نافذة الإضافة/التعديل.
class _AdminDraft {
  const _AdminDraft({
    required this.email,
    required this.fullName,
    required this.role,
    this.organizationName,
    this.username,
    this.password,
  });

  final String email;
  final String fullName;
  final String? organizationName;

  /// اسم المستخدم المحلي (اختياري — يُشتقّ من البريد إن غاب).
  final String? username;
  final AdminRole role;
  final String? password;
}

/// بيانات نافذة تغيير كلمة المرور.
class _PasswordDraft {
  const _PasswordDraft({required this.newPassword, this.currentPassword});

  final String newPassword;
  final String? currentPassword;
}

/// نافذة إضافة مدير أو تعديل بياناته.
class _AdminEditorDialog extends StatefulWidget {
  const _AdminEditorDialog({
    required this.title,
    required this.requirePassword,
    this.email = '',
    this.username = '',
    this.fullName = '',
    this.organizationName = '',
    this.role = AdminRole.admin,
  });

  final String title;
  final bool requirePassword;
  final String email;
  final String username;
  final String fullName;
  final String organizationName;
  final AdminRole role;

  @override
  State<_AdminEditorDialog> createState() => _AdminEditorDialogState();
}

class _AdminEditorDialogState extends State<_AdminEditorDialog> {
  late final TextEditingController _email =
      TextEditingController(text: widget.email);
  late final TextEditingController _username =
      TextEditingController(text: widget.username);
  late final TextEditingController _name =
      TextEditingController(text: widget.fullName);
  late final TextEditingController _org =
      TextEditingController(text: widget.organizationName);
  final TextEditingController _password = TextEditingController();
  late AdminRole _role = widget.role;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _username.dispose();
    _name.dispose();
    _org.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    final String email = _email.text.trim().toLowerCase();
    final String name = _name.text.trim();
    if (!widget.requirePassword && email.isEmpty) {
      setState(() => _error = 'البريد الإلكتروني مطلوب.');
      return;
    }
    if (!email.contains('@') || email.contains(' ')) {
      setState(() => _error = 'أدخل بريداً إلكترونياً صالحاً.');
      return;
    }
    if (name.isEmpty) {
      setState(() => _error = 'اسم المدير مطلوب.');
      return;
    }
    if (widget.requirePassword) {
      if (_password.text.length < AppConstants.minPasswordLength) {
        setState(() => _error =
            'كلمة المرور ${AppConstants.minPasswordLength} أحرف على الأقل.');
        return;
      }
    }
    Navigator.of(context).pop(
      _AdminDraft(
        email: email,
        fullName: name,
        organizationName: _org.text.trim().isEmpty ? null : _org.text.trim(),
        username:
            _username.text.trim().isEmpty ? null : _username.text.trim(),
        role: _role,
        password: widget.requirePassword ? _password.text : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                key: const ValueKey<String>('adm-dialog-email'),
                controller: _email,
                enabled: widget.requirePassword,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppTheme.space12),
              TextField(
                key: const ValueKey<String>('adm-dialog-username'),
                controller: _username,
                decoration: const InputDecoration(
                  labelText: 'اسم المستخدم المحلي (للتبديل السريع)',
                  helperText: 'اتركه فارغاً ليُشتقّ تلقائياً من البريد',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppTheme.space12),
              TextField(
                key: const ValueKey<String>('adm-dialog-name'),
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'اسم المدير',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppTheme.space12),
              TextField(
                key: const ValueKey<String>('adm-dialog-org'),
                controller: _org,
                decoration: const InputDecoration(
                  labelText: 'المؤسسة (اختياري)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppTheme.space12),
              DropdownButtonFormField<AdminRole>(
                key: const ValueKey<String>('adm-dialog-role'),
                initialValue: _role,
                decoration: const InputDecoration(
                  labelText: 'الرتبة',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: <DropdownMenuItem<AdminRole>>[
                  for (final AdminRole role in AdminRole.selectable)
                    DropdownMenuItem<AdminRole>(
                      value: role,
                      child: Text(role.labelAr),
                    ),
                ],
                onChanged: (AdminRole? role) =>
                    setState(() => _role = role ?? AdminRole.admin),
              ),
              if (widget.requirePassword) ...<Widget>[
                const SizedBox(height: AppTheme.space12),
                TextField(
                  key: const ValueKey<String>('adm-dialog-password'),
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
              if (_error != null) ...<Widget>[
                const SizedBox(height: AppTheme.space12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
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
          key: const ValueKey<String>('adm-dialog-save'),
          onPressed: _submit,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

/// نافذة تغيير كلمة مرور مدير.
class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({
    required this.title,
    required this.requiresCurrent,
    required this.subject,
  });

  final String title;

  /// هل الحساب هو حساب المستخدم الحالي؟ (فتُطلب كلمته الحالية)
  final bool requiresCurrent;
  final String subject;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final TextEditingController _current = TextEditingController();
  final TextEditingController _next = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.requiresCurrent && _current.text.isEmpty) {
      setState(() => _error = 'أدخل كلمة مرورك الحالية.');
      return;
    }
    if (_next.text.length < AppConstants.minPasswordLength) {
      setState(() => _error =
          'كلمة المرور الجديدة ${AppConstants.minPasswordLength} أحرف على الأقل.');
      return;
    }
    if (_next.text != _confirm.text) {
      setState(() => _error = 'كلمتا المرور غير متطابقتين.');
      return;
    }
    Navigator.of(context).pop(
      _PasswordDraft(
        newPassword: _next.text,
        currentPassword: widget.requiresCurrent ? _current.text : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                widget.requiresCurrent
                    ? 'تغيير كلمة مرور حسابك «${widget.subject}».'
                    : 'إعادة تعيين كلمة مرور «${widget.subject}».',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppTheme.space12),
              if (widget.requiresCurrent) ...<Widget>[
                TextField(
                  key: const ValueKey<String>('adm-pass-current'),
                  controller: _current,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور الحالية',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: AppTheme.space12),
              ],
              TextField(
                key: const ValueKey<String>('adm-pass-new'),
                controller: _next,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور الجديدة',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppTheme.space12),
              TextField(
                key: const ValueKey<String>('adm-pass-confirm'),
                controller: _confirm,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'تأكيد كلمة المرور',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: AppTheme.space12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
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
          key: const ValueKey<String>('adm-pass-save'),
          onPressed: _submit,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
