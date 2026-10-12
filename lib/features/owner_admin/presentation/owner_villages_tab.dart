/// تبويب «القرى» في لوحة تحكم المالك.
///
/// القائمة تعرض كل قرية بالاسم والكود والمحافظة/المركز وعدد الأعضاء،
/// مع بحث بالاسم أو الكود وفلترة بالمحافظة. الأزرار: إضافة قرية (نموذج
/// بتوليد كود حيّ)، توليد كود مستقلّ (معاينة + نسخ)، تعديل (الاسم/الكود/
/// المحافظة)، وحذف بتأكيد.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/owner_admin_repository.dart';
import '../domain/owner_models.dart';
import 'generate_code_dialog.dart';
import 'village_form_dialog.dart';
import 'widgets/owner_admin_states.dart';

class OwnerVillagesTab extends StatefulWidget {
  const OwnerVillagesTab({super.key, required this.repository});

  final OwnerAdminRepository repository;

  @override
  State<OwnerVillagesTab> createState() => _OwnerVillagesTabState();
}

class _OwnerVillagesTabState extends State<OwnerVillagesTab> {
  final TextEditingController _searchController = TextEditingController();

  List<OwnerVillage> _villages = const <OwnerVillage>[];
  bool _loading = true;
  String? _error;

  /// نصّ البحث — يطابق الاسم أو الاسم اللاتيني أو الكود (بلا تمييز حالة).
  String _query = '';

  /// فلترة المحافظة — `null` = كل المحافظات.
  String? _governorate;

  @override
  void initState() {
    super.initState();
    // _loading تبدأ true في الحقل — لا setState قبل أول إطار.
    _fetch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final List<OwnerVillage> villages = await widget.repository
          .fetchVillages();
      final Map<String, int> counts = await widget.repository
          .fetchMemberCounts();
      if (!mounted) return;
      setState(() {
        _villages = <OwnerVillage>[
          for (final OwnerVillage village in villages)
            village.copyWith(memberCount: counts[village.id] ?? 0),
        ];
        // فلترة تعود `null` إن لم تعد محافظتها موجودة في البيانات.
        if (_governorate != null && !_governorates.contains(_governorate)) {
          _governorate = null;
        }
        _loading = false;
        _error = null;
      });
    } on OwnerAdminException catch (exception) {
      if (!mounted) return;
      setState(() {
        _error = exception.message;
        _loading = false;
      });
    }
  }

  /// إعادة تحميل مع مؤشّر تحميل — تُستدعى من تصرّفات المستخدم فقط
  /// (بعد أول إطار) فلا تعارض مع `setState` أثناء البناء.
  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _fetch();
  }

  /// المحافظات الموجودة فعلياً — أساس قائمة الفلترة.
  Set<String> get _governorates => <String>{
    for (final OwnerVillage village in _villages)
      if (village.governorate != null &&
          village.governorate!.trim().isNotEmpty)
        village.governorate!.trim(),
  };

  /// القائمة بعد تطبيق البحث والفلترة.
  List<OwnerVillage> get _filtered {
    final String query = _query.trim().toLowerCase();
    return _villages.where((OwnerVillage village) {
      final bool matchesQuery =
          query.isEmpty ||
          village.name.toLowerCase().contains(query) ||
          (village.nameEn ?? '').toLowerCase().contains(query) ||
          village.code.toLowerCase().contains(query);
      final bool matchesGovernorate =
          _governorate == null || village.governorate == _governorate;
      return matchesQuery && matchesGovernorate;
    }).toList(growable: false);
  }

  // ------------------------------- التصرّفات -------------------------------

  Future<void> _addVillage() async {
    final String? code = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) =>
          VillageFormDialog(repository: widget.repository),
    );
    if (code == null || !mounted) return;
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('أنشئت القرية — الكود $code')),
    );
  }

  Future<void> _editVillage(OwnerVillage village) async {
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => VillageFormDialog(
        repository: widget.repository,
        initial: village,
      ),
    );
    if (saved != true || !mounted) return;
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('حُفظت التعديلات')));
  }

  Future<void> _deleteVillage(OwnerVillage village) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('حذف القرية'),
        content: Text(
          'سيُحذف «${village.name}» وكل بياناتها (الأعضاء والفيديوهات '
          'والإعلانات). هل أنت متأكد؟',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            key: const ValueKey<String>('village-delete-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.repository.deleteVillage(village.id);
    } on OwnerAdminException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(exception.message)));
      return;
    }
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('حُذفت القرية')));
  }

  Future<void> _openGenerateCode() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => const GenerateCodeDialog(),
    );
  }

  // -------------------------------- البناء ---------------------------------

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return OwnerAdminErrorView(message: _error!, onRetry: _reload);
    }

    final List<OwnerVillage> visible = _filtered;
    return Column(
      children: <Widget>[
        _buildToolbar(),
        Expanded(
          child: visible.isEmpty
              ? OwnerAdminEmptyView(
                  message: _villages.isEmpty
                      ? 'لا توجد قرى بعد — ابدأ بزر «إضافة قرية».'
                      : 'لا نتائج مطابقة للبحث.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: visible.length,
                  itemBuilder: (BuildContext context, int index) =>
                      _buildRow(visible[index]),
                ),
        ),
      ],
    );
  }

  /// شريط الأدوات: بحث + فلترة المحافظة + زرّا التوليد والإضافة.
  Widget _buildToolbar() {
    final List<String> governorates = _governorates.toList()..sort();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 260,
            child: TextField(
              key: const ValueKey<String>('owner-village-search'),
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'بحث بالاسم أو الكود',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (String value) =>
                  setState(() => _query = value),
            ),
          ),
          DropdownButton<String?>(
            key: const ValueKey<String>('owner-gov-filter'),
            value: _governorate,
            hint: const Text('كل المحافظات'),
            items: <DropdownMenuItem<String?>>[
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('كل المحافظات'),
              ),
              for (final String governorate in governorates)
                DropdownMenuItem<String?>(
                  value: governorate,
                  child: Text(governorate),
                ),
            ],
            onChanged: (String? value) =>
                setState(() => _governorate = value),
          ),
          FilledButton.icon(
            key: const ValueKey<String>('owner-generate-code'),
            onPressed: _openGenerateCode,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('توليد الكود'),
          ),
          FilledButton.icon(
            key: const ValueKey<String>('owner-add-village'),
            onPressed: _addVillage,
            icon: const Icon(Icons.add),
            label: const Text('إضافة قرية'),
          ),
        ],
      ),
    );
  }

  /// بطاقة قرية: الاسم والكود والمحافظة/المركز وعدد الأعضاء + إجراءها.
  Widget _buildRow(OwnerVillage village) {
    final String location = <String>[
      if (village.governorate != null && village.governorate!.isNotEmpty)
        village.governorate!,
      if (village.center != null && village.center!.isNotEmpty)
        village.center!,
    ].join(' • ');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    village.name,
                    key: ValueKey<String>('village-name-${village.id}'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (village.nameEn != null &&
                      village.nameEn!.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      village.nameEn!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    village.code,
                    key: ValueKey<String>('village-code-${village.id}'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.goldDeep,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    location.isEmpty ? '—' : location,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'أعضاء: ${village.memberCount}',
                    key: ValueKey<String>('village-members-${village.id}'),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  key: ValueKey<String>('village-edit-${village.id}'),
                  tooltip: 'تعديل',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editVillage(village),
                ),
                IconButton(
                  key: ValueKey<String>('village-delete-${village.id}'),
                  tooltip: 'حذف',
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                  ),
                  onPressed: () => _deleteVillage(village),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
