/// إدارة أعضاء القرية: بحث نصّي + فلترة بالجنس والسن + حذف + تصدير CSV.
///
/// الجنس **مستنتج** من الرقم القومي (الخانة الثالثة عشرة) لا مخزَّناً عموداً
/// منفصلاً، والتصدير ملف CSV بـ BOM وسطور CRLF يفتح في Excel عربياً بلا
/// رموز مشوّهة.
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/village_admin_repository.dart';
import '../../domain/members_csv.dart';
import '../../domain/village.dart';
import '../../domain/village_admin_text.dart';
import '../../domain/village_member.dart';
import 'village_admin_feedback.dart';

class VillageMembersAdminScreen extends StatefulWidget {
  const VillageMembersAdminScreen({
    super.key,
    required this.repository,
    required this.village,
  });

  final VillageAdminRepository repository;
  final Village village;

  @override
  State<VillageMembersAdminScreen> createState() =>
      _VillageMembersAdminScreenState();
}

class _VillageMembersAdminScreenState
    extends State<VillageMembersAdminScreen> {
  List<VillageMember>? _members;
  String? _error;

  String _query = '';

  /// `null` ⇒ الكل، `true` ⇒ ذكور، `false` ⇒ إناث.
  bool? _gender;

  VillageAgeBand _band = VillageAgeBand.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _members = null;
    });
    try {
      final List<VillageMember> members = await widget.repository.fetchMembers(
        villageId: widget.village.id,
      );
      if (!mounted) return;
      setState(() => _members = members);
    } catch (failure) {
      if (!mounted) return;
      setState(() => _error = adminErrorText(failure));
    }
  }

  /// القائمة بعد تطبيق كل الفلاتر الثلاثة.
  List<VillageMember> get _filtered {
    final List<VillageMember> all = _members ?? const <VillageMember>[];
    final String query = _query.trim();
    final bool? gender = _gender;
    return all.where((VillageMember member) {
      if (query.isNotEmpty &&
          !member.name.contains(query) &&
          !member.phone.contains(query) &&
          !member.nationalId.contains(query)) {
        return false;
      }
      if (gender != null && memberIsMale(member) != gender) return false;
      if (!_band.contains(member.age)) return false;
      return true;
    }).toList(growable: false);
  }

  Future<void> _exportCsv() async {
    final List<VillageMember> rows = _filtered;
    if (rows.isEmpty) {
      context.showError(VillageAdminText.membersEmpty);
      return;
    }
    final String fileName = '${widget.village.code}-members.csv';
    try {
      final Uri? saved = await FilePicker.saveFile(
        dialogTitle: VillageAdminText.exportCsv,
        fileName: fileName,
        bytes: encodeMembersCsv(rows),
        mimeType: 'text/csv',
        type: FileType.custom,
        allowedExtensions: const <String>['csv'],
      );
      if (!mounted || saved == null) return;
      context.showSuccess(VillageAdminText.exportSaved(fileName));
    } on Object {
      if (!mounted) return;
      context.showError(VillageAdminText.exportFailed);
    }
  }

  Future<void> _delete(VillageMember member) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text(VillageAdminText.deleteMemberTitle),
        content: Text(VillageAdminText.deleteMemberBody(member.name)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(VillageAdminText.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(VillageAdminText.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.repository.deleteMember(memberId: member.id);
      if (!mounted) return;
      context.showSuccess(VillageAdminText.memberDeleted);
      await _load();
    } catch (failure) {
      if (!mounted) return;
      context.showAdminError(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<VillageMember>? members = _members;
    return Scaffold(
      appBar: AppBar(title: const Text(VillageAdminText.membersTitle)),
      body: members == null ? _buildLoading() : _buildList(members),
    );
  }

  Widget _buildLoading() {
    final String? error = _error;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline_rounded, size: 40),
              const SizedBox(height: AppTheme.space12),
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: AppTheme.space16),
              FilledButton.tonal(
                onPressed: _load,
                child: const Text(VillageAdminText.retry),
              ),
            ],
          ),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildList(List<VillageMember> members) {
    final List<VillageMember> rows = _filtered;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space16,
            AppTheme.space16,
            AppTheme.space16,
            AppTheme.space8,
          ),
          child: TextField(
            key: const ValueKey<String>('member-search'),
            onChanged: (String value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: VillageAdminText.memberSearchHint,
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
          child: Wrap(
            spacing: AppTheme.space8,
            runSpacing: AppTheme.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              ChoiceChip(
                key: const ValueKey<String>('gender-all'),
                label: const Text(VillageAdminText.filterAll),
                selected: _gender == null,
                onSelected: (_) => setState(() => _gender = null),
              ),
              ChoiceChip(
                key: const ValueKey<String>('gender-male'),
                label: const Text(VillageAdminText.genderMale),
                selected: _gender == true,
                onSelected: (_) => setState(() => _gender = true),
              ),
              ChoiceChip(
                key: const ValueKey<String>('gender-female'),
                label: const Text(VillageAdminText.genderFemale),
                selected: _gender == false,
                onSelected: (_) => setState(() => _gender = false),
              ),
              const SizedBox(width: AppTheme.space8),
              DropdownButton<VillageAgeBand>(
                key: const ValueKey<String>('age-band'),
                value: _band,
                isDense: true,
                items: <DropdownMenuItem<VillageAgeBand>>[
                  for (final VillageAgeBand band in VillageAgeBand.values)
                    DropdownMenuItem<VillageAgeBand>(
                      value: band,
                      child: Text(band.label),
                    ),
                ],
                onChanged: (VillageAgeBand? value) => setState(
                  () => _band = value ?? VillageAgeBand.all,
                ),
              ),
              FilledButton.tonalIcon(
                key: const ValueKey<String>('export-csv'),
                onPressed: _exportCsv,
                icon: const Icon(Icons.save_alt_rounded, size: 18),
                label: const Text(VillageAdminText.exportCsv),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space16,
            AppTheme.space12,
            AppTheme.space16,
            AppTheme.space4,
          ),
          child: Row(
            children: <Widget>[
              Text(
                VillageAdminText.membersCount(rows.length),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.space24),
                    child: Text(
                      VillageAdminText.membersEmpty,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.space16,
                      AppTheme.space4,
                      AppTheme.space16,
                      AppTheme.space24,
                    ),
                    itemCount: rows.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(height: AppTheme.space8),
                    itemBuilder: (BuildContext context, int index) {
                      final VillageMember member = rows[index];
                      final bool? isMale = memberIsMale(member);
                      return Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          key: ValueKey<String>('member-${member.id}'),
                          leading: Icon(
                            isMale == null
                                ? Icons.person_outline_rounded
                                : isMale
                                    ? Icons.person_rounded
                                    : Icons.person_outline_rounded,
                          ),
                          title: Text(member.name),
                          subtitle: Text(
                            '${member.phone} — ${member.age} سنة'
                            '${isMale == null ? '' : ' — ${genderLabel(isMale)}'}',
                          ),
                          trailing: IconButton(
                            key: ValueKey<String>('delete-member-${member.id}'),
                            icon: const Icon(Icons.delete_outline_rounded),
                            tooltip: VillageAdminText.delete,
                            onPressed: () => _delete(member),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

/// أطقم أعمار الفلترة — الحدود محسوبة على السن المخزَّن لحظة التسجيل.
enum VillageAgeBand {
  all(VillageAdminText.ageAll),
  from18to30(VillageAdminText.age18to30),
  from31to45(VillageAdminText.age31to45),
  from46to60(VillageAdminText.age46to60),
  over60(VillageAdminText.age60plus);

  const VillageAgeBand(this.label);

  /// التسمية العربية للفلترة.
  final String label;

  /// هل يقع [age] داخل هذا الطقم؟
  bool contains(int age) => switch (this) {
        VillageAgeBand.all => true,
        VillageAgeBand.from18to30 => age >= 18 && age <= 30,
        VillageAgeBand.from31to45 => age >= 31 && age <= 45,
        VillageAgeBand.from46to60 => age >= 46 && age <= 60,
        VillageAgeBand.over60 => age > 60,
      };
}
