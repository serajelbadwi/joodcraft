/// تبويب «إدارة النطاقات» في لوحة الإدارة.
///
/// القائمة تعرض كل نطاق بالاسم والكود والمحافظة/المركز، مع بحث بالاسم أو
/// الكود وفلترة بالمحافظة. الأزرار: إضافة نطاق (نموذج بتوليد كود حيّ)،
/// توليد كود مستقلّ، تعديل، وحذف بتأكيد.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/domain_repository.dart';
import '../domain/domain.dart';
import 'domain_form_dialog.dart';
import 'generate_domain_code_dialog.dart';
import 'widgets/domain_states.dart';

class DomainsManagerTab extends StatefulWidget {
  const DomainsManagerTab({super.key, required this.repository});

  final DomainRepository repository;

  @override
  State<DomainsManagerTab> createState() => _DomainsManagerTabState();
}

class _DomainsManagerTabState extends State<DomainsManagerTab> {
  final TextEditingController _searchController = TextEditingController();

  List<Domain> _domains = const <Domain>[];
  bool _loading = true;
  String? _error;

  /// نصّ البحث — يطابق الاسم العربي أو اللاتيني أو الكود (بلا تمييز حالة).
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
      final List<Domain> domains = await widget.repository.fetchDomains();
      if (!mounted) return;
      setState(() {
        _domains = domains;
        // فلترة تعود `null` إن لم يعد لها مقابل في البيانات.
        if (_governorate != null && !_governorates.contains(_governorate)) {
          _governorate = null;
        }
        _loading = false;
        _error = null;
      });
    } on DomainAdminException catch (exception) {
      if (!mounted) return;
      setState(() {
        _error = exception.message;
        _loading = false;
      });
    }
  }

  /// إعادة تحميل مع مؤشّر تحميل — تُستدعى من تصرّفات المستخدم فقط.
  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _fetch();
  }

  /// المحافظات الموجودة فعلياً — أساس قائمة الفلترة.
  Set<String> get _governorates => <String>{
    for (final Domain domain in _domains)
      if (domain.governorate.trim().isNotEmpty) domain.governorate.trim(),
  };

  /// القائمة بعد تطبيق البحث والفلترة.
  List<Domain> get _filtered {
    final String query = _query.trim().toLowerCase();
    return _domains.where((Domain domain) {
      final bool matchesQuery =
          query.isEmpty ||
          domain.nameAr.toLowerCase().contains(query) ||
          domain.nameEn.toLowerCase().contains(query) ||
          domain.code.toLowerCase().contains(query);
      final bool matchesGovernorate =
          _governorate == null || domain.governorate == _governorate;
      return matchesQuery && matchesGovernorate;
    }).toList(growable: false);
  }

  // ------------------------------- التصرّفات -------------------------------

  Future<void> _addDomain() async {
    final String? code = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) =>
          DomainFormDialog(repository: widget.repository),
    );
    if (code == null || !mounted) return;
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('أُضيف النطاق — الكود $code')),
    );
  }

  Future<void> _editDomain(Domain domain) async {
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => DomainFormDialog(
        repository: widget.repository,
        initial: domain,
      ),
    );
    if (saved != true || !mounted) return;
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('حُفظت التعديلات')));
  }

  Future<void> _deleteDomain(Domain domain) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('حذف النطاق'),
        content: Text('سيُحذف «${domain.nameAr}» وكل بياناته. هل أنت متأكد؟'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            key: const ValueKey<String>('domain-delete-confirm'),
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
      await widget.repository.deleteDomain(domain.id);
    } on DomainAdminException catch (exception) {
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
    ).showSnackBar(const SnackBar(content: Text('حُذف النطاق')));
  }

  Future<void> _openGenerateCode() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => const GenerateDomainCodeDialog(),
    );
  }

  // -------------------------------- البناء ---------------------------------

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return DomainErrorView(message: _error!, onRetry: _reload);
    }

    final List<Domain> visible = _filtered;
    return Column(
      children: <Widget>[
        _buildToolbar(),
        Expanded(
          child: visible.isEmpty
              ? DomainEmptyView(
                  message: _domains.isEmpty
                      ? 'لا توجد نطاقات بعد — ابدأ بزر «إضافة نطاق».'
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
              key: const ValueKey<String>('domain-search'),
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'بحث بالاسم أو الكود',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (String value) => setState(() => _query = value),
            ),
          ),
          DropdownButton<String?>(
            key: const ValueKey<String>('domain-gov-filter'),
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
            onChanged: (String? value) => setState(() => _governorate = value),
          ),
          FilledButton.icon(
            key: const ValueKey<String>('domain-generate-code'),
            onPressed: _openGenerateCode,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('توليد كود'),
          ),
          FilledButton.icon(
            key: const ValueKey<String>('domain-add'),
            onPressed: _addDomain,
            icon: const Icon(Icons.add),
            label: const Text('إضافة نطاق'),
          ),
        ],
      ),
    );
  }

  /// بطاقة نطاق: الاسم والكود والموقع + إجراءاها.
  Widget _buildRow(Domain domain) {
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
                    domain.nameAr,
                    key: ValueKey<String>('domain-name-${domain.id}'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (domain.nameEn.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      domain.nameEn,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    domain.code,
                    key: ValueKey<String>('domain-code-${domain.id}'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.goldDeep,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    domain.locationLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  key: ValueKey<String>('domain-edit-${domain.id}'),
                  tooltip: 'تعديل',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editDomain(domain),
                ),
                IconButton(
                  key: ValueKey<String>('domain-delete-${domain.id}'),
                  tooltip: 'حذف',
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                  ),
                  onPressed: () => _deleteDomain(domain),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
