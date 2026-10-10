import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../errors/app_exception.dart';
import '../../fonts/custom_font_controller.dart';
import '../../fonts/custom_font_face.dart';
import '../../l10n/app_l10n.dart';
import '../../pdf/pdf_font_catalog.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'font_selector.dart';

/// امتدادات ملفات الخطوط المقبولة في الرفع.
const List<String> kCustomFontExtensions = <String>['ttf', 'otf'];

/// منتقي الخطوط الموحّد داخل شريط الخصائص.
///
/// يجمع **ثلاثة مصادر** في عنصر واحد قابل للبحث:
/// 1. **الخطوط المضمّنة** ([PdfFontFamily] المحزومة في التطبيق).
/// 2. **خطوط المستخدم المرفوعة** (المكتبة المحلية).
/// 3. **خطوط نظام التشغيل** (Windows — قد تبلغ المئات).
///
/// يعرض أزرار الرفع والإدارة أيضاً، ويستمع لمحرّك الخطوط الديناميكي مباشرة
/// (نسخة واحدة للتطبيق) فيتحدّث فوراً بعد أي رفع.
///
/// التوجيه عند الاختيار: الخط المضمّن يمرّ عبر [onBundledSelected] (ويُلغي أي
/// خط مخصص)، أما المرفوع/النظامي فيمرّ عبر [onCustomSelected] بعد تسجيل الخط
/// النظامي ديناميكياً.
class FontSelectorSection extends StatelessWidget {
  const FontSelectorSection({
    super.key,
    required this.bundledFamily,
    required this.customFamily,
    required this.onBundledSelected,
    required this.onCustomSelected,
    this.onPreviewFamily,
  });

  /// عائلة الخط المضمّن المختارة (تُستخدم حين لا يوجد خط مخصص).
  final PdfFontFamily bundledFamily;

  /// مفتاح الخط المخصص/النظامي المختار، أو `null` للخط المضمّن.
  final String? customFamily;

  /// اختير خط مضمّن جديد.
  final ValueChanged<PdfFontFamily> onBundledSelected;

  /// اختير خط مرفوع/نظامي (أو `null` عند الرجوع للمضمّن).
  final ValueChanged<String?> onCustomSelected;

  /// معاينة حيّة للخط عند المرور فوق خيار في القائمة (اسم عائلة فلاتر أو
  /// `null` عند الخروج) — تُعرض على اللوحة فوراً بلا تثبيت.
  final ValueChanged<String?>? onPreviewFamily;

  /// بادئة معرّف الخيارات المضمّنة داخل المنتقي.
  static const String _builtinIdPrefix = 'builtin:';

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
                // مرن: يحتفظ بعرضه المريح (210) حين يتّسع، ويتقلّص بلا فيض
                // داخل بطاقات الضبط التي تقلّ فيها المساحة قليلاً.
                Flexible(child: _field(context, fonts)),
                const SizedBox(width: AppTheme.space8),
                Tooltip(
                  message: context.l10n?.cfpUploadTooltip ??
                      'رفع خط مخصص (.ttf / .otf)',
                  child: IconButton.filledTonal(
                    onPressed: () => uploadCustomFonts(context),
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                Tooltip(
                  message:
                      context.l10n?.cfpManageTooltip ?? 'إدارة الخطوط المرفوعة',
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
                  context.l10n?.cfpNotice ??
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

  Widget _field(BuildContext context, CustomFontController fonts) {
    final List<FontSelectorGroup> groups = _groups(context, fonts);
    final String selectedId = _selectedId();
    FontSelectorItem? selected;
    for (final FontSelectorGroup group in groups) {
      for (final FontSelectorItem item in group.items) {
        if (item.id == selectedId) {
          selected = item;
          break;
        }
      }
      if (selected != null) break;
    }
    // خط محفوظ في قالب لكن غير موجود في القوائم (حُذف مثلاً) — نعرض اسمه بلا
    // بادئة تقنية بدل إظهار مفتاح خام.
    selected ??= FontSelectorItem(
      id: selectedId,
      label: fonts.displayNameOf(selectedId),
      previewFamily: selectedId,
    );
    return FontSelectorField(
      key: const ValueKey<String>('custom-font-picker'),
      label: context.l10n?.editorFont ?? 'الخط',
      selected: selected,
      onTap: () => _openPicker(context, fonts),
    );
  }

  /// يبني المجموعات الثلاث (مضمّنة/مرفوعة/نظامية)، ويُخفي كل مجموعة فارغة.
  List<FontSelectorGroup> _groups(
    BuildContext context,
    CustomFontController fonts,
  ) {
    final l10n = context.l10n;
    // نُبعد خطوط النظام التي يطابق اسمها خطاً مرفوعاً (تفادي التكرار).
    final Set<String> uploadedNames =
        fonts.families.map(fonts.displayNameOf).toSet();
    final List<String> systemFamilies = fonts.systemFamilies
        .where((String name) => !uploadedNames.contains(name))
        .toList(growable: false);
    return <FontSelectorGroup>[
      FontSelectorGroup(
        title: l10n?.cfpGroupBuiltin ?? 'الخطوط المضمّنة',
        items: <FontSelectorItem>[
          for (final PdfFontFamily family in PdfFontFamily.pdfFamilies)
            FontSelectorItem(
              id: '$_builtinIdPrefix${family.jsonValue}',
              label: family.labelAr,
              previewFamily: family.uiFamily,
            ),
        ],
      ),
      if (fonts.families.isNotEmpty)
        FontSelectorGroup(
          title: l10n?.cfpGroupUploaded ?? 'خطوطي المرفوعة',
          items: <FontSelectorItem>[
            for (final String family in fonts.families)
              FontSelectorItem(
                id: family,
                label: fonts.displayNameOf(family),
                previewFamily: family,
              ),
          ],
        ),
      if (systemFamilies.isNotEmpty)
        FontSelectorGroup(
          title: l10n?.cfpGroupSystem ?? 'خطوط النظام',
          items: <FontSelectorItem>[
            for (final String family in systemFamilies)
              FontSelectorItem(
                id: family,
                label: family,
                previewFamily: family,
              ),
          ],
        ),
    ];
  }

  String _selectedId() {
    final String? custom = customFamily?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    return '$_builtinIdPrefix${bundledFamily.jsonValue}';
  }

  Future<void> _openPicker(
    BuildContext context,
    CustomFontController fonts,
  ) async {
    final l10n = context.l10n;
    final FontSelectorItem? chosen = await showFontSelectorDialog(
      context,
      groups: _groups(context, fonts),
      title: l10n?.editorFont ?? 'الخط',
      searchHint: l10n?.cfpSearchHint ?? 'ابحث في الخطوط…',
      noMatchText: l10n?.cfpNoMatch ?? 'لا توجد خطوط مطابقة.',
      selectedId: _selectedId(),
      onPreviewFamily: onPreviewFamily,
    );
    // إغلاق القائمة (بالاختيار أو الإلغاء) يُزيل أي معاينة معلّقة.
    onPreviewFamily?.call(null);
    if (chosen == null) return;
    await _apply(fonts, chosen);
  }

  /// يوجّه الخيار المختار إلى الفعل الصحيح حسب نوعه.
  Future<void> _apply(
    CustomFontController fonts,
    FontSelectorItem item,
  ) async {
    if (item.id.startsWith(_builtinIdPrefix)) {
      final String jsonValue = item.id.substring(_builtinIdPrefix.length);
      final PdfFontFamily family = PdfFontFamily.values.firstWhere(
        (PdfFontFamily f) => f.jsonValue == jsonValue,
        orElse: () => bundledFamily,
      );
      onBundledSelected(family);
      return;
    }
    // عائلات المستخدم تحمل البادئة التقنية؛ ما عداها خط نظام.
    if (item.id.startsWith(CustomFontFace.familyPrefix)) {
      onCustomSelected(item.id);
      return;
    }
    await fonts.registerSystemFont(item.id);
    onCustomSelected(item.id);
  }
}

/// فتح منتقي الملفات ورفع خط واحد أو أكثر إلى المكتبة المحلية.
///
/// يعيد عدد الملفات التي أُضيفت فعلاً (لأغراض الاختبار/الإبلاغ).
Future<int> uploadCustomFonts(BuildContext context) async {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final CustomFontController fonts = CustomFontController.instance;
  final l10n = context.l10n;

  final List<PlatformFile> picked;
  try {
    picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: kCustomFontExtensions,
      dialogTitle: context.l10n?.cfpPickTitle ?? 'اختر ملف خط (TTF أو OTF)',
    );
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          l10n?.cfpPickerError(error.toString()) ??
              'تعذّر فتح منتقي الملفات: $error',
        ),
      ),
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
      warnings.add(
        l10n?.cfpReadError(file.name, error.toString()) ??
            'تعذّر قراءة "${file.name}": $error',
      );
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
          added == 1
              ? (l10n?.cfpFontAdded ?? 'أُضيف الخط واستُخدم فوراً.')
              : (l10n?.cfpFontsAdded(added) ?? 'أُضيف $added خطوط.'),
        ),
      ),
    );
  }
  if (warnings.isNotEmpty) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(warnings.join('\n')),
        backgroundColor: Theme.of(context).colorScheme.brandSurface,
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
          title: Text(context.l10n?.cfpLibraryTitle ?? 'مكتبة خطوطي المخصصة'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.l10n?.cfpLibraryNotice ??
                      'كل الخطوط محفوظة على جهازك فقط. تحذير: حذف خط يستخدمه قالب '
                          'يُرجع ذلك القالب إلى الخط المضمّن بدل الفشل.',
                  style: text.bodySmall,
                ),
                const SizedBox(height: AppTheme.space12),
                if (fonts.isEmpty)
                  Text(
                    context.l10n?.cfpEmpty ?? 'لا توجد خطوط مرفوعة بعد.',
                    style: text.bodyMedium,
                  )
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
                            '${face.arabicReady ? (context.l10n?.cfpCoverageFull ?? 'تغطية عربية كاملة') : (context.l10n?.cfpCoveragePartial ?? 'تغطية عربية ناقصة')}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: IconButton(
                            tooltip: context.l10n?.tplDelete ?? 'حذف',
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
              label: Text(context.l10n?.cfpUploadNew ?? 'رفع خط جديد'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n?.editorClose ?? 'إغلاق'),
            ),
          ],
        );
      },
    );
  }
}
