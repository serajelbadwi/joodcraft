/// توليد كود نطاق مستقلّ — معاينة ونسخ بلا إنشاء نطاق.
///
/// المستخدم يدخل الاسم الإنجليزي + (اختيارياً) الرمز البريدي وPlus Code،
/// فيعرض الكود بصيغة `MAA-31951-25GF989`. التوليد هنا مطابق لخوارزمية
/// `owner_generate_domain_code` في القاعدة؛ فحص الكود الفريد يكون عند
/// إنشاء النطاق فعلياً.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/domain_code_generator.dart';

class GenerateDomainCodeDialog extends StatefulWidget {
  const GenerateDomainCodeDialog({super.key});

  @override
  State<GenerateDomainCodeDialog> createState() =>
      _GenerateDomainCodeDialogState();
}

class _GenerateDomainCodeDialogState extends State<GenerateDomainCodeDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameEn = TextEditingController();
  final TextEditingController _postal = TextEditingController();
  final TextEditingController _plus = TextEditingController();

  String _code = '';

  @override
  void dispose() {
    _nameEn.dispose();
    _postal.dispose();
    _plus.dispose();
    super.dispose();
  }

  void _regenerate() {
    setState(() {
      _code = DomainCodeGenerator.generate(
        nameEn: _nameEn.text,
        postalCode: _postal.text,
        plusCode: _plus.text,
      );
    });
  }

  void _copy() {
    if (_code.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('نُسخ الكود')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('توليد كود نطاق'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  key: const ValueKey<String>('domain-generate-name-en'),
                  controller: _nameEn,
                  decoration: const InputDecoration(
                    labelText: 'اسم النطاق (إنجليزي)',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (String? raw) =>
                      (raw ?? '').trim().isEmpty ? 'اكتب الاسم اللاتيني' : null,
                  onChanged: (String _) => _regenerate(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey<String>('domain-generate-postal'),
                  controller: _postal,
                  decoration: const InputDecoration(
                    labelText: 'الرمز البريدي (اختياري)',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (String _) => _regenerate(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey<String>('domain-generate-plus'),
                  controller: _plus,
                  decoration: const InputDecoration(
                    labelText: 'Plus Code من خرائط جوجل (اختياري)',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (String _) => _regenerate(),
                ),
                const SizedBox(height: 16),
                Text(
                  _code.isEmpty ? 'اكتب الاسم لعرض الكود' : _code,
                  key: const ValueKey<String>('domain-generate-result'),
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldDeep,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
        FilledButton.icon(
          key: const ValueKey<String>('domain-generate-copy'),
          onPressed: _code.isEmpty
              ? null
              : () {
                  if (!(_formKey.currentState?.validate() ?? false)) return;
                  _copy();
                },
          icon: const Icon(Icons.copy_rounded),
          label: const Text('نسخ'),
        ),
      ],
    );
  }
}
