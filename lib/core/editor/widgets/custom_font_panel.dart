import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../errors/app_exception.dart';
import '../../fonts/custom_font_controller.dart';
import '../../fonts/custom_font_face.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'editor_controls.dart';

/// امتدادات ملفات الخطوط المقبولة في الرفع.
const List<String> kCustomFontExtensions = <String>['ttf', 'otf'];

/// قسم «خطوطي المخصصة» داخل شريط الخصائص.
///
/// يعرض قائمة الخطوط التي رفعها المستخدم + أزرار الرفع والإدارة، ويستمع لمحرّك
/// الخطوط الديناميكي مباشرة (نسخة واحدة للتطبيق) فيتحدّث فوراً بعد أي رفع.
class CustomFontSection extends StatelessWidget {
  const CustomFontSection({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  /// اسم عائلة الخط المخصص المختار للعنصر (أو `null`).
  final String? selected;

  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CustomFontController.instance,
      builder: (BuildContext context, Widget? _) {
        final CustomFontController fonts = CustomFontController.instance;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: _picker(fonts)),
                const SizedBox(width: AppTheme.space8),
                Tooltip(
                  message: 'رفع خط مخصص (.ttf / .otf)',
                  child: IconButton.filledTonal(
                    onPressed: () => uploadCustomFonts(context),
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                Tooltip(
                  message: 'إدارة الخطوط المرفوعة',
                  child: IconButton(
                    onPressed: fonts.isEmpty
                        ? null
                        : () => showCustomFontManager(context),
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            if (fonts.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'الخطوط المرفوعة تُحفظ على جهازك فقط وتُستخدم فوراً هنا وفي '
                  'الطباعة — بلا إنترنت.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _picker(CustomFontController fonts) {
    final List<String> keys = <String>['', ...fonts.families];
    if (selected != null &&
        selected!.trim().isNotEmpty &&
        !keys.contains(selected)) {
      keys.add(selected!);
    }
    if (keys.length == 1) {
      return DropdownField<String>(
        label: 'خطوطي المخصصة',
        value: '',
        items: keys,
        labelOf: (String _) => 'لم ترفع خطوطاً بعد',
        onChanged: (String value) => onChanged(value.isEmpty ? null : value),
      );
    }
    return DropdownField<String>(
      key: const ValueKey<String>('custom-font-picker'),
      label: 'خطوطي المخصصة',
      value: selected?.trim().isNotEmpty == true && keys.contains(selected)
          ? selected!
          : '',
      items: keys,
      labelOf: (String key) => key.isEmpty
          ? 'بلا (الخط المضمّن)'
          : fonts.displayNameOf(key),
      onChanged: (String value) => onChanged(value.isEmpty ? null : value),
    );
  }
}

/// فتح منتقي الملفات ورفع خط واحد أو أكثر إلى المكتبة المحلية.
///
/// يعيد عدد الملفات التي أُضيفت فعلاً (لأغراض الاختبار/الإبلاغ).
Future<int> uploadCustomFonts(BuildContext context) async {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final CustomFontController fonts = CustomFontController.instance;

  final List<PlatformFile> picked;
  try {
    picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: kCustomFontExtensions,
      dialogTitle: 'اختر ملف خط (TTF أو OTF)',
    );
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('تعذّر فتح منتقي الملفات: $error')),
    );
    return 0;
  }
  if (picked.isEmpty) return 0;

  int added = 0;
  final List<String> warnings = <String>[];
  for (final PlatformFile file in picked) {
    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (error) {
      warnings.add('تعذّر قراءة "${file.name}": $error');
      continue;
    }
    try {
      final CustomFontAddResult result = await fonts.addFont(
        fileName: file.name,
        bytes: bytes,
      );
      added++;
      for (final String warning in result.warningsAr) {
        warnings.add('"${result.face.displayName}": $warning');
      }
    } on AppException catch (error) {
      warnings.add('"${file.name}": ${error.message}');
    } catch (error) {
      warnings.add('"${file.name}": $error');
    }
  }

  if (!context.mounted) return added;
  if (added > 0) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          added == 1 ? 'أُضيف الخط واستُخدم فوراً.' : 'أُضيف $added خطوط.',
        ),
      ),
    );
  }
  if (warnings.isNotEmpty) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(warnings.join('\n')),
        backgroundColor: AppColors.navy,
        duration: const Duration(seconds: 8),
      ),
    );
  }
  return added;
}

/// نافذة إدارة مكتبة الخطوط المخصصة: الحجم، التغطية العربية، والحذف.
Future<void> showCustomFontManager(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) => const _CustomFontManagerDialog(),
  );
}

class _CustomFontManagerDialog extends StatelessWidget {
  const _CustomFontManagerDialog();

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: CustomFontController.instance,
      builder: (BuildContext context, Widget? _) {
        final CustomFontController fonts = CustomFontController.instance;
        return AlertDialog(
          title: const Text('مكتبة خطوطي المخصصة'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'كل الخطوط محفوظة على جهازك فقط. تحذير: حذف خط يستخدمه قالب '
                  'يُرجع ذلك القالب إلى الخط المضمّن بدل الفشل.',
                  style: text.bodySmall,
                ),
                const SizedBox(height: AppTheme.space12),
                if (fonts.isEmpty)
                  Text('لا توجد خطوط مرفوعة بعد.', style: text.bodyMedium)
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: fonts.faces.length,
                      separatorBuilder: (BuildContext _, int _) =>
                          const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final CustomFontFace face = fonts.faces[index];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.font_download_outlined),
                          title: Text(
                            '${face.displayName} — ${face.weightLabelAr}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          subtitle: Text(
                            '${face.fileName} • ${face.sizeLabel} • '
                            '${face.arabicReady ? 'تغطية عربية كاملة' : 'تغطية عربية ناقصة'}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: IconButton(
                            tooltip: 'حذف',
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18),
                            onPressed: () => fonts.removeFont(face.family),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton.icon(
              onPressed: () => uploadCustomFonts(context),
              icon: const Icon(Icons.upload_file_rounded, size: 16),
              label: const Text('رفع خط جديد'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }
}
