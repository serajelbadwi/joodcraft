/// نموذج نطاق من لوحة الإدارة — إضافة أو تعديل.
///
/// * **الإضافة**: الاسم (عربي/إنجليزي) والمحافظة والمركز + قسم اختياري:
///   الرمز البريدي وPlus Code (وليدهما الكود) والإحداثيات (للخريطة)، مع
///   **معاينة حيّة** للكود الذي سينشئه الخادم — [DomainCodeGenerator] مطابق
///   لخوارزمية الدالة في القاعدة.
/// * **التعديل**: الاسم العربي والمحافظة.
///
/// المصطلحات في الواجهة: «إضافة نطاق» و«تعديل النطاق» (لا «قرية»).
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/domain_repository.dart';
import '../domain/domain.dart';
import '../domain/domain_code_generator.dart';

class DomainFormDialog extends StatefulWidget {
  const DomainFormDialog({super.key, required this.repository, this.initial});

  final DomainRepository repository;

  /// نطاق قيد التعديل — `null` في وضع الإضافة.
  final Domain? initial;

  @override
  State<DomainFormDialog> createState() => _DomainFormDialogState();
}

class _DomainFormDialogState extends State<DomainFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameAr = TextEditingController(
    text: widget.initial?.nameAr,
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
  late final TextEditingController _postal = TextEditingController(
    text: widget.initial?.postalCode,
  );
  late final TextEditingController _plus = TextEditingController(
    text: widget.initial?.plusCode,
  );
  late final TextEditingController _latitude = TextEditingController(
    text: widget.initial?.latitude?.toString(),
  );
  late final TextEditingController _longitude = TextEditingController(
    text: widget.initial?.longitude?.toString(),
  );

  bool _busy = false;
  String? _error;

  bool get _isEdit => widget.initial != null;

  @override
  void dispose() {
    _nameAr.dispose();
    _nameEn.dispose();
    _governorate.dispose();
    _center.dispose();
    _postal.dispose();
    _plus.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  /// الكود المعروض حيّاً في وضع الإضافة — نفس منطق الخادم.
  String get _previewCode => DomainCodeGenerator.generate(
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
        await widget.repository.updateDomain(
          id: widget.initial!.id,
          nameAr: _nameAr.text,
          governorate: _governorate.text,
        );
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        final String code = await widget.repository.createDomain(
          nameAr: _nameAr.text,
          nameEn: _nameEn.text,
          governorate: _governorate.text,
          center: _center.text,
          postalCode: _postal.text,
          plusCode: _plus.text,
          latitude: double.tryParse(_latitude.text.trim()),
          longitude: double.tryParse(_longitude.text.trim()),
        );
        if (!mounted) return;
        Navigator.of(context).pop(code);
      }
    } on DomainAdminException catch (exception) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = exception.message;
      });
    }
  }

  String? _nameArValidator(String? raw) {
    final String value = (raw ?? '').trim();
    if (value.isEmpty) return 'اكتب اسم النطاق';
    if (!_containsArabic(value)) return 'اكتب الاسم بحروف عربية';
    return null;
  }

  String? _required(String? raw, String message) =>
      (raw ?? '').trim().isEmpty ? message : null;

  /// إحداثي اختياري: رقم عشري صالح، وداخل مدى الأرض.
  String? _coordinateValidator(String? raw, {required bool isLatitude}) {
    final String value = (raw ?? '').trim();
    if (value.isEmpty) return null;
    final double? parsed = double.tryParse(value);
    if (parsed == null) return 'اكتب رقماً — مثال: 30.8124';
    final double limit = isLatitude ? 90 : 180;
    if (parsed.abs() > limit) {
      return isLatitude
          ? 'خط العرض بين -90 و 90'
          : 'خط الطول بين -180 و 180';
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
      title: Text(_isEdit ? 'تعديل النطاق' : 'إضافة نطاق'),
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
                  key: const ValueKey<String>('domain-name-ar'),
                  controller: _nameAr,
                  decoration: _decoration('اسم النطاق (عربي)'),
                  validator: _nameArValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey<String>('domain-name-en'),
                  controller: _nameEn,
                  decoration: _decoration('اسم النطاق (إنجليزي)'),
                  validator: (String? raw) => _required(
                    raw,
                    'اكتب الاسم اللاتيني — أساس بادئة الكود',
                  ),
                  onChanged: (String _) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey<String>('domain-gov'),
                  controller: _governorate,
                  decoration: _decoration('المحافظة'),
                  validator: (String? raw) => _required(raw, 'اكتب المحافظة'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey<String>('domain-center'),
                  controller: _center,
                  decoration: _decoration('المركز'),
                  validator: (String? raw) => _required(raw, 'اكتب المركز'),
                ),
                if (!_isEdit) ...<Widget>[
                  const SizedBox(height: 16),
                  _buildCodeSection(),
                ],
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    key: const ValueKey<String>('domain-form-error'),
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
          key: const ValueKey<String>('domain-form-save'),
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

  /// قسم توليد الكود: مدخلان اختياريان + معاينة حيّة.
  Widget _buildCodeSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold),
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
            key: const ValueKey<String>('domain-postal'),
            controller: _postal,
            decoration: _decoration('الرمز البريدي (اختياري)'),
            keyboardType: TextInputType.number,
            onChanged: (String _) => setState(() {}),
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: const ValueKey<String>('domain-plus'),
            controller: _plus,
            decoration: _decoration('Plus Code من خرائط جوجل (اختياري)'),
            onChanged: (String _) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  key: const ValueKey<String>('domain-lat'),
                  controller: _latitude,
                  decoration: _decoration('خط العرض (اختياري)'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  validator: (String? raw) => _coordinateValidator(
                    raw,
                    isLatitude: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  key: const ValueKey<String>('domain-lng'),
                  controller: _longitude,
                  decoration: _decoration('خط الطول (اختياري)'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  validator: (String? raw) => _coordinateValidator(
                    raw,
                    isLatitude: false,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'الكود المولَّد: $_previewCode',
            key: const ValueKey<String>('domain-code-preview'),
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.goldDeep,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
