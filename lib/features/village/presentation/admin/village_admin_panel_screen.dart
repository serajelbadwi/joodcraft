/// **الشاشة الرئيسية للوحة تحكم القرى**: عدّادات عامة (قرى/مسجَّلون/فيديوهات/
/// إعلانات نشطة) + قائمة كل القرى + إضافة قرية جديدة.
///
/// البيانات كلها تأتي من نداء واحد `admin_overview()`، فالشاشة تفتح بجولة
/// واحدة وتُحدَّث كاملةً عند العودة أو بالسحب للتحديث.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/village_admin_repository.dart';
import '../../data/village_repository.dart';
import '../../domain/village.dart';
import '../../domain/village_admin_overview.dart';
import '../../domain/village_admin_text.dart';
import '../../domain/village_validators.dart';
import 'village_admin_feedback.dart';

class VillageAdminPanelScreen extends StatefulWidget {
  const VillageAdminPanelScreen({
    super.key,
    required this.repository,
    required this.onSignOut,
  });

  /// مستودع العمليات (وهمي في الاختبارات).
  final VillageAdminRepository repository;

  /// يُستدعى عند طلب الخروج — البوابة هي من تُعيد عرض نموذج الدخول.
  final VoidCallback onSignOut;

  @override
  State<VillageAdminPanelScreen> createState() =>
      _VillageAdminPanelScreenState();
}

class _VillageAdminPanelScreenState extends State<VillageAdminPanelScreen> {
  List<VillageAdminOverview>? _items;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<VillageAdminOverview> items =
          await widget.repository.fetchOverviews();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (failure) {
      if (!mounted) return;
      setState(() {
        _error = adminErrorText(failure);
        _loading = false;
      });
      // أثناء تحدّث قائمة قائمة يبقى ما هو ظاهر، والرسالة تمرّ برسالة سفلية.
      if (_items != null) context.showAdminError(failure);
    }
  }

  Future<void> _showAddVillage() async {
    final Village? created = await showDialog<Village>(
      context: context,
      builder: (BuildContext dialogContext) =>
          _AddVillageDialog(repository: widget.repository),
    );
    if (created == null || !mounted) return;
    context.showSuccess(VillageAdminText.villageCreated);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final List<VillageAdminOverview>? items = _items;
    final bool showFab = items != null && items.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(VillageAdminText.panelTitle),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('village-admin-signout'),
            icon: const Icon(Icons.logout_rounded),
            tooltip: VillageAdminText.signOut,
            onPressed: widget.onSignOut,
          ),
        ],
      ),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              key: const ValueKey<String>('village-admin-add-village'),
              onPressed: _showAddVillage,
              icon: const Icon(Icons.add_business_rounded),
              label: const Text(VillageAdminText.addVillage),
            )
          : null,
      body: Column(
        children: <Widget>[
          // شريط تقدّم رفيع أثناء التحدّث الصامت فوق قائمة ظاهرة.
          if (_loading && _items != null) const LinearProgressIndicator(),
          Expanded(child: _buildBody(items)),
        ],
      ),
    );
  }

  Widget _buildBody(List<VillageAdminOverview>? items) {
    if (items == null) {
      final String? error = _error;
      if (error != null) {
        return _ErrorState(message: error, onRetry: _load);
      }
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppTheme.space20,
          AppTheme.space20,
          AppTheme.space20,
          AppTheme.space48,
        ),
        children: <Widget>[
          _StatsRow(items: items),
          const SizedBox(height: AppTheme.space16),
          if (items.isEmpty)
            _EmptyVillages(onAdd: _showAddVillage)
          else
            ...items.map(_villageCard),
        ],
      ),
    );
  }

  Widget _villageCard(VillageAdminOverview overview) {
    final Village village = overview.village;
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.space12),
      child: ListTile(
        key: ValueKey<String>('village-card-${village.id}'),
        leading: const Icon(Icons.villa_rounded),
        title: Text(village.name),
        subtitle: Text(
          '${village.code} — ${VillageAdminText.membersCount(overview.membersCount)}'
          '، ${overview.videosCount} فيديو'
          '، ${overview.activeAdsCount} إعلان نشط',
        ),
        trailing: const Icon(Icons.chevron_left_rounded),
        onTap: () => context.push(
          '${AppRoutes.villageAdmin}/village',
          extra: overview,
        ),
      ),
    );
  }
}

/// صفّ العدّادات الأربعة أعلى اللوحة.
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.items});

  final List<VillageAdminOverview> items;

  @override
  Widget build(BuildContext context) {
    final int members =
        items.fold<int>(0, (int sum, VillageAdminOverview o) => sum + o.membersCount);
    final int videos =
        items.fold<int>(0, (int sum, VillageAdminOverview o) => sum + o.videosCount);
    final int ads = items.fold<int>(
      0,
      (int sum, VillageAdminOverview o) => sum + o.activeAdsCount,
    );

    return Wrap(
      spacing: AppTheme.space12,
      runSpacing: AppTheme.space12,
      children: <Widget>[
        _StatCard(value: '${items.length}', label: VillageAdminText.statVillages),
        _StatCard(value: '$members', label: VillageAdminText.statMembers),
        _StatCard(value: '$videos', label: VillageAdminText.statVideos),
        _StatCard(value: '$ads', label: VillageAdminText.statAds),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space16,
            vertical: AppTheme.space12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppTheme.space2),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// حالة «لا قرى بعد» مع زر الإضافة.
class _EmptyVillages extends StatelessWidget {
  const _EmptyVillages({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: AppTheme.space40),
        const Icon(Icons.villa_outlined, size: 48),
        const SizedBox(height: AppTheme.space16),
        Text(
          VillageAdminText.emptyVillages,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppTheme.space16),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: const Text(VillageAdminText.addVillage),
        ),
      ],
    );
  }
}

/// حالة الخطأ الكاملة مع إعادة المحاولة.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline_rounded, size: 40),
            const SizedBox(height: AppTheme.space12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.space16),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text(VillageAdminText.retry),
            ),
          ],
        ),
      ),
    );
  }
}

/// نافذة «قرية جديدة»: الاسم والكود بتحقّق القرية نفسها قبل الإرسال.
class _AddVillageDialog extends StatefulWidget {
  const _AddVillageDialog({required this.repository});

  final VillageAdminRepository repository;

  @override
  State<_AddVillageDialog> createState() => _AddVillageDialogState();
}

class _AddVillageDialogState extends State<_AddVillageDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final Village created = await widget.repository.createVillage(
        name: _nameController.text,
        code: _codeController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } on VillageException catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = failure.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(VillageAdminText.addVillageTitle),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                key: const ValueKey<String>('new-village-name'),
                controller: _nameController,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: VillageAdminText.villageNameLabel,
                ),
                validator: (String? value) =>
                    VillageValidators.name(value ?? ''),
              ),
              const SizedBox(height: AppTheme.space16),
              TextFormField(
                key: const ValueKey<String>('new-village-code'),
                controller: _codeController,
                enabled: !_saving,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: VillageAdminText.villageCodeLabel,
                  helperText: VillageAdminText.villageCodeHint,
                ),
                validator: (String? value) =>
                    VillageValidators.code(value ?? ''),
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: AppTheme.space12),
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text(VillageAdminText.cancel),
        ),
        FilledButton(
          key: const ValueKey<String>('new-village-submit'),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(VillageAdminText.save),
        ),
      ],
    );
  }
}
