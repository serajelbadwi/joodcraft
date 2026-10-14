/// توليد كود قرية مستقلّ — معاينة ونسخ بلا إنشاء قرية.
///
/// المستخدم يدخل الاسم اللاتيني + (اختيارياً) الرمز البريدي وPlus Code،
/// فيعرض الكود بصيغة `بادئة-بريد-Plus مختصر` مثل `MAA-31951-25GF`.
/// التوليد هنا مطابق لخوارزمية `owner_generate_village_code` في القاعدة؛
/// الفحص الفعلي للكود الفريد يكون عند إنشاء القرية أو تعديل كودها.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/village_code_generator.dart';

class GenerateCodeDialog extends StatefulWidget {
  const GenerateCodeDialog({super.key});

  @override
  State<GenerateCodeDialog> createState() => _GenerateCodeDialogState();
}

class _GenerateCodeDialogState extends State<GenerateCodeDialog> {
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
      _code = VillageCodeGenerator.generate(
        nameEn: _nameEn.text,
        postalCode: _postal.text,
        plusCode: _plus.text,
      );
    });
  }

  void _copy() {
    if (_code.isEmpty) return;
    // النسخة غير مُتوقَّعة الصدفة: النسخ واجهة، والتنبيه فوري بلا انتظار.
    Clipboard.setData(ClipboardData(text: _code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('نُسخ الكود')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('توليد الكود'),
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
                  key: const ValueKey<String>('generate-name-en'),
                  controller: _nameEn,
                  decoration: const InputDecoration(
                    labelText: 'اسم القرية (إنجليزي)',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (String? raw) =>
                      (raw ?? '').trim().isEmpty ? 'اكتب الاسم اللاتيني' : null,
                  onChanged: (String _) => _regenerate(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey<String>('generate-postal'),
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
                  key: const ValueKey<String>('generate-plus'),
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
                  key: const ValueKey<String>('generate-result'),
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    // ذهبي يُضيء ليلاً (`AppSchemeColors.goldDeep`).
                    color: Theme.of(context).colorScheme.goldDeep,
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
          key: const ValueKey<String>('generate-copy'),
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
