import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// خيار خط واحد في منتقي الخطوط الموحّد.
///
/// **مستقلّ عن مصدر الخط:** هو مجرّد (مفتاح ثابت + اسم معروض + عائلة معاينة)،
/// ويتولّى المستدعي ترجمة اختياره إلى فعل عبر [id] — فيبقى هذا الودجت صالحاً
/// للخطوط المضمّنة والمرفوعة وخطوط النظام كلها.
class FontSelectorItem {
  const FontSelectorItem({
    required this.id,
    required this.label,
    this.previewFamily,
  });

  /// مفتاح ثابت يميّز الخيار ويوجّه سلوك الاختيار عند المستدعي.
  final String id;

  /// الاسم المعروض للمستخدم.
  final String label;

  /// اسم عائلة فلاتر لمعاينة شكل الخط داخل القائمة (قد تكون `null`).
  final String? previewFamily;
}

/// مجموعة خطوط معنونة داخل المنتقي (مضمّنة/مرفوعة/نظامية).
class FontSelectorGroup {
  const FontSelectorGroup({required this.title, required this.items});

  final String title;
  final List<FontSelectorItem> items;
}

/// حقل مدمج يعرض الخط المختار (بخطه نفسه) ويفتح منتقي الخطوط عند النقر.
class FontSelectorField extends StatelessWidget {
  const FontSelectorField({
    super.key,
    required this.selected,
    required this.onTap,
    this.label,
    this.width = 210,
  });

  /// الخيار المعروض حالياً، أو `null` حين لا يُعرف (يُعرض فراغ).
  final FontSelectorItem? selected;

  final VoidCallback onTap;

  /// تسمية الحقل (مثل «الخط»).
  final String? label;

  final double width;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: InputDecorator(
          decoration: InputDecoration(
            isDense: true,
            labelText: label,
            labelStyle: const TextStyle(fontSize: 11.5),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  selected?.label ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.onSurface,
                    fontFamily: selected?.previewFamily,
                  ),
                ),
              ),
              Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// يفتح منتقي الخطوط الموحّد ويعيد الخيار المختار (أو `null` عند الإلغاء).
///
/// المزايا:
/// * **بحث فوري (search-as-you-type):** يرشّح العائلات بالاسم لحظياً — ضروري
///   حين يبلغ عدد خطوط النظام المئات فلا يمكن التمرير يدوياً.
/// * **مجموعات معنونة:** كل مصدر (مضمّن/مرفوع/نظامي) تحت عنوانه مع عدد عناصره،
///   فتصبح البنية واضحة بنظرة.
/// * **معاينة حقيقية:** كل اسم يُرسم بخطه نفسه متى كان مسجّلاً في فلاتر.
Future<FontSelectorItem?> showFontSelectorDialog(
  BuildContext context, {
  required List<FontSelectorGroup> groups,
  required String searchHint,
  required String noMatchText,
  String? title,
  String? selectedId,
}) {
  return showDialog<FontSelectorItem>(
    context: context,
    builder: (BuildContext _) => _FontSelectorDialog(
      groups: groups,
      searchHint: searchHint,
      noMatchText: noMatchText,
      title: title,
      selectedId: selectedId,
    ),
  );
}

class _FontSelectorDialog extends StatefulWidget {
  const _FontSelectorDialog({
    required this.groups,
    required this.searchHint,
    required this.noMatchText,
    this.title,
    this.selectedId,
  });

  final List<FontSelectorGroup> groups;
  final String searchHint;
  final String noMatchText;
  final String? title;
  final String? selectedId;

  @override
  State<_FontSelectorDialog> createState() => _FontSelectorDialogState();
}

class _FontSelectorDialogState extends State<_FontSelectorDialog> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  /// المجموعات بعد ترشيح البحث (تُسقط المجموعة الفارغة تماماً).
  List<FontSelectorGroup> get _filtered {
    final String needle = _query.text.trim().toLowerCase();
    if (needle.isEmpty) return widget.groups;
    final List<FontSelectorGroup> result = <FontSelectorGroup>[];
    for (final FontSelectorGroup group in widget.groups) {
      final List<FontSelectorItem> items = group.items
          .where((FontSelectorItem item) =>
              item.label.toLowerCase().contains(needle))
          .toList(growable: false);
      if (items.isNotEmpty) {
        result.add(FontSelectorGroup(title: group.title, items: items));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<FontSelectorGroup> groups = _filtered;
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (widget.title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        widget.title!,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(context)
                          .closeButtonTooltip,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: TextField(
                controller: _query,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (String _) => setState(() {}),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: groups.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 36,
                      ),
                      child: Text(
                        widget.noMatchText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      children: <Widget>[
                        for (final FontSelectorGroup group in groups)
                          ...<Widget>[
                            _GroupHeader(
                              title: group.title,
                              count: group.items.length,
                            ),
                            for (final FontSelectorItem item in group.items)
                              _FontItemTile(
                                item: item,
                                selected: item.id == widget.selectedId,
                                onTap: () =>
                                    Navigator.of(context).pop(item),
                              ),
                          ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ترويسة مجموعة داخل القائمة: العنوان + عدد الخطوط.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        '$title · $count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: scheme.primary,
        ),
      ),
    );
  }
}

/// سطر خط واحد — يُرسم بخطه للمعاينة، مع علامة صحّ على المختار.
class _FontItemTile extends StatelessWidget {
  const _FontItemTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final FontSelectorItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ListTile(
      key: ValueKey<String>('font-option-${item.id}'),
      dense: true,
      selected: selected,
      selectedTileColor: scheme.primary.withValues(alpha: 0.08),
      leading: Icon(
        selected ? Icons.check_rounded : Icons.text_fields_rounded,
        size: 17,
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
      title: Text(
        item.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 14, fontFamily: item.previewFamily),
      ),
      onTap: onTap,
    );
  }
}
