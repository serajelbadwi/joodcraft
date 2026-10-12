/// نموذج إصدار ترخيص «صاحب الفرح» من لوحة المالك.
///
/// الاشتراك: اختيار القرية + اسم صاحب المكتب + رقم التليفون + المدة
/// (شهر / 3 شهور / سنة). الكود `FRH-<بادئة القرية>-<تسلسل>` يولّده الخادم
/// في دالة `owner_create_license` ويعيده — تراه الشاشة في تنبيه فوري.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../data/owner_admin_repository.dart';
import '../domain/owner_models.dart';

class LicenseFormDialog extends StatefulWidget {
  const LicenseFormDialog({
    super.key,
    required this.repository,
    required this.villages,
  });

  final OwnerAdminRepository repository;

  /// قرى القائمة المنسدلة — مُجلبة مسبقاً من التبويب.
  final List<OwnerVillage> villages;

  @override
  State<LicenseFormDialog> createState() => _LicenseFormDialogState();
}

class _LicenseFormDialogState extends State<LicenseFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();

  String? _villageId;

  /// المدة بالأشهر — السنة هي الافتراضي.
  int _months = 12;

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final String code = await widget.repository.createLicense(
        villageId: _villageId!,
        subscriberName: _name.text,
        phone: _phone.text,
        months: _months,
      );
      if (!mounted) return;
      Navigator.of(context).pop(code);
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
    return AlertDialog(
      title: const Text('إصدار ترخيص'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                DropdownButtonFormField<String>(
                  key: const ValueKey<String>('license-village'),
                  initialValue: _villageId,
                  decoration: const InputDecoration(
                    labelText: 'القرية',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  // تلميح منفصل عن نصّ الخطأ كي لا يتكرّر النصّان معاً.
                  hint: const Text('اختر قرية'),
                  validator: (String? value) =>
                      value == null ? 'اختر القرية' : null,
                  items: <DropdownMenuItem<String>>[
                    for (final OwnerVillage village in widget.villages)
                      DropdownMenuItem<String>(
                        value: village.id,
                        child: Text(village.name),
                      ),
                  ],
                  onChanged: (String? value) =>
                      setState(() => _villageId = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey<String>('license-name'),
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'اسم صاحب المكتب',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (String? raw) =>
                      (raw ?? '').trim().isEmpty ? 'اكتب اسم صاحب المكتب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey<String>('license-phone'),
                  controller: _phone,
                  decoration: const InputDecoration(
                    labelText: 'رقم التليفون',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                  validator: _phoneValidator,
                ),
                const SizedBox(height: 16),
                const Text(
                  'مدة الترخيص',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  key: const ValueKey<String>('license-months'),
                  segments: const <ButtonSegment<int>>[
                    ButtonSegment<int>(value: 1, label: Text('شهر')),
                    ButtonSegment<int>(value: 3, label: Text('3 شهور')),
                    ButtonSegment<int>(value: 12, label: Text('سنة')),
                  ],
                  selected: <int>{_months},
                  onSelectionChanged: (Set<int> selection) =>
                      setState(() => _months = selection.first),
                ),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    key: const ValueKey<String>('license-form-error'),
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          key: const ValueKey<String>('license-form-save'),
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('إصدار'),
        ),
      ],
    );
  }

  /// التليفون: 7..15 رقماً — أرقام فقط عبر المرشّح أعلاه.
  static String? _phoneValidator(String? raw) {
    final String value = (raw ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (value.isEmpty) return 'اكتب رقم التليفون';
    if (value.length < 7) return 'رقم قصير جداً';
    if (value.length > 15) return 'رقم طويل جداً';
    return null;
  }
}
