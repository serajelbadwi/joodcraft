/// نموذج قرية من لوحة المالك — إضافة أو تعديل.
///
/// * **الإضافة**: الاسم (عربي/لاتيني) والمحافظة والمركز + قسم اختياري لتوليد
///   الكود (الرمز البريدي وPlus Code) مع معاينة حيّة للكود الذي سينشئه
///   الخادم ([VillageCodeGenerator] مطابق لخوارزمية الدالة في القاعدة).
/// * **التعديل**: الاسم والكود والمحافظة — والكود يقبل الصيغة القديمة
///   `AAA-YYYY` وصيغة اللوحة `بادئة-بريد-Plus مختصر`.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/owner_admin_repository.dart';
import '../domain/owner_models.dart';
import '../domain/village_code_generator.dart';

class VillageFormDialog extends StatefulWidget {
  const VillageFormDialog({super.key, required this.repository, this.initial});

  final OwnerAdminRepository repository;

  /// قرية قيد التعديل — `null` في وضع الإضافة.
  final OwnerVillage? initial;

  @override
  State<VillageFormDialog> createState() => _VillageFormDialogState();
}

class _VillageFormDialogState extends State<VillageFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameAr = TextEditingController(
    text: widget.initial?.name,
  );
  late final TextEditingController _nameEn = TextEditingController(
    text: widget.initial?.nameEn,
  );
  late final TextEditingController _governorate = TextEditingController(
    text: widget.initial?.governorate,
  );
  late final TextEditingController _center = TextEditingController(
    text: widget.initial?.center,
  );
  late final TextEditingController _code = TextEditingController(
    text: widget.initial?.code,
  );
  final TextEditingController _postal = TextEditingController();
  final TextEditingController _plus = TextEditingController();

  bool _busy = false;
  String? _error;

  bool get _isEdit => widget.initial != null;

  @override
  void dispose() {
    _nameAr.dispose();
    _nameEn.dispose();
    _governorate.dispose();
    _center.dispose();
    _code.dispose();
    _postal.dispose();
    _plus.dispose();
    super.dispose();
  }

  /// الكود المعروض حيّاً في وضع الإضافة — نفس منطق الخادم.
  String get _previewCode => VillageCodeGenerator.generate(
    nameEn: _nameEn.text,
    postalCode: _postal.text,
    plusCode: _plus.text,
  );

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_isEdit) {
        await widget.repository.updateVillage(
          id: widget.initial!.id,
          name: _nameAr.text,
          code: _normalizeCode(_code.text),
          governorate: _governorate.text,
        );
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        final String code = await widget.repository.createVillage(
          nameAr: _nameAr.text,
          nameEn: _nameEn.text,
          governorate: _governorate.text,
          center: _center.text,
          postalCode: _postal.text,
          plusCode: _plus.text,
        );
        if (!mounted) return;
        Navigator.of(context).pop(code);
      }
    } on OwnerAdminException catch (exception) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = exception.message;
      });
    }
  }

  /// تطبيع الكود قبل الإرسال: أرقام عربية ← لاتينية، شرطط طويلة ← عادية.
  static String _normalizeCode(String raw) {
    String value = raw.trim().toUpperCase();
    const List<String> arabicDigits = <String>[
      '٠',
      '١',
      '٢',
      '٣',
      '٤',
      '٥',
      '٦',
      '٧',
      '٨',
      '٩',
    ];
    for (int i = 0; i < arabicDigits.length; i++) {
      value = value.replaceAll(arabicDigits[i], '$i');
    }
    return value.replaceAll('–', '-').replaceAll('—', '-');
  }

  String? _nameValidator(String? raw) {
    final String value = (raw ?? '').trim();
    if (value.isEmpty) return 'اكتب اسم القرية';
    if (!_containsArabic(value)) return 'اكتب الاسم بحروف عربية';
    return null;
  }

  String? _required(String? raw, String message) =>
      (raw ?? '').trim().isEmpty ? message : null;

  String? _codeValidator(String? raw) {
    if ((raw ?? '').trim().isEmpty) return 'اكتب كود القرية';
    final String code = _normalizeCode(raw!);
    final bool legacy = RegExp(r'^[A-Z]{3}-[0-9]{4}$').hasMatch(code);
    if (!legacy && !VillageCodeGenerator.isValid(code)) {
      return 'صيغة غير صحيحة — مثال: MAA-31951-25GF';
    }
    return null;
  }

  static bool _containsArabic(String text) =>
      RegExp(r'[\u0600-\u06FF]').hasMatch(text);

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    isDense: true,
    border: const OutlineInputBorder(),
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'تعديل القرية' : 'إضافة قرية'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  key: const ValueKey<String>('village-name-ar'),
                  controller: _nameAr,
                  decoration: _decoration('اسم القرية (عربي)'),
                  validator: _nameValidator,
                ),
                if (!_isEdit) ...<Widget>[
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey<String>('village-name-en'),
                    controller: _nameEn,
                    decoration: _decoration('اسم القرية (إنجليزي)'),
                    validator: (String? raw) => _required(
                      raw,
                      'اكتب الاسم اللاتيني — أساس بادئة الكود',
                    ),
                    onChanged: (String _) => setState(() {}),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey<String>('village-gov'),
                  controller: _governorate,
                  decoration: _decoration('المحافظة'),
                  validator: (String? raw) => _required(raw, 'اكتب المحافظة'),
                ),
                if (!_isEdit) ...<Widget>[
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey<String>('village-center'),
                    controller: _center,
                    decoration: _decoration('المركز'),
                    validator: (String? raw) => _required(raw, 'اكتب المركز'),
                  ),
                  const SizedBox(height: 16),
                  _buildCodeSection(),
                ],
                if (_isEdit) ...<Widget>[
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey<String>('village-code'),
                    controller: _code,
                    decoration: _decoration('كود القرية'),
                    validator: _codeValidator,
                    onChanged: (String _) => setState(() {}),
                  ),
                ],
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    key: const ValueKey<String>('village-form-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
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
          key: const ValueKey<String>('village-form-save'),
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEdit ? 'حفظ' : 'إضافة'),
        ),
      ],
    );
  }

  /// قسم توليد الكود في وضع الإضافة: مدخلان اختياريان + معاينة حيّة.
  Widget _buildCodeSection() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // حاوية ذهبية دافئة: `darkGoldSoft` ليلاً و`goldSoft` نهاراً.
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.secondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'توليد الكود (اختياري)',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: const ValueKey<String>('village-postal'),
            controller: _postal,
            decoration: _decoration('الرمز البريدي (اختياري)'),
            keyboardType: TextInputType.number,
            onChanged: (String _) => setState(() {}),
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: const ValueKey<String>('village-plus'),
            controller: _plus,
            decoration: _decoration('Plus Code من خرائط جوجل (اختياري)'),
            onChanged: (String _) => setState(() {}),
          ),
          const SizedBox(height: 10),
          Text(
            'الكود المولَّد: $_previewCode',
            key: const ValueKey<String>('village-code-preview'),
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: scheme.goldDeep,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
