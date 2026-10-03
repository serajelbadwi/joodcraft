import 'package:flutter/material.dart';

import '../../assets/asset_image_cache.dart';
import '../../assets/asset_type_ui.dart';
import '../../assets/assets_controller.dart';
import '../../assets/user_asset.dart';
import '../../constants/app_constants.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// نافذة «من مكتبة أصولي»: اختيار أصل مرفوع (إطار/شعار/ختم/توقيع) لاستخدامه
/// في القالب مباشرةً.
///
/// تعيد الأصل المختار أو `null` عند الإلغاء. الواجهة تتصفّح الأنواع عبر شرائح
/// ([filterTypes]) مع فرز كل الأصول من النوع المطلوب — أوفلاين بالكامل.
Future<UserAsset?> showAssetLibraryPicker(
  BuildContext context, {
  String title = 'من مكتبة أصولي',
  List<AssetType>? filterTypes,
  AssetsController? assets,
}) {
  return showDialog<UserAsset>(
    context: context,
    builder: (BuildContext dialogContext) => _AssetLibraryDialog(
      title: title,
      filterTypes: filterTypes ?? AssetType.values,
      assets: assets ?? AssetsController.instance,
    ),
  );
}

class _AssetLibraryDialog extends StatefulWidget {
  const _AssetLibraryDialog({
    required this.title,
    required this.filterTypes,
    required this.assets,
  });

  final String title;
  final List<AssetType> filterTypes;
  final AssetsController assets;

  @override
  State<_AssetLibraryDialog> createState() => _AssetLibraryDialogState();
}

class _AssetLibraryDialogState extends State<_AssetLibraryDialog> {
  /// `null` يعني «الكل».
  AssetType? _filter;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: <Widget>[
          Icon(Icons.collections_bookmark_rounded,
              size: 18, color: Theme.of(context).colorScheme.goldDeep),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.title)),
        ],
      ),
      content: SizedBox(
        width: 470,
        height: 430,
        child: ListenableBuilder(
          listenable: widget.assets,
          builder: (BuildContext context, Widget? _) {
            final List<UserAsset> allowed = widget.assets.assets
                .where((UserAsset asset) =>
                    widget.filterTypes.contains(asset.type))
                .toList(growable: false);

            if (allowed.isEmpty) {
              return Center(
                child: Text(
                  'لا توجد أصول مرفوعة من الأنواع المطلوبة.\n'
                  'ارفع إطاراً أو شعاراً من قسم «الأصول والتوقيعات» ثم أعد المحاولة.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }

            final List<UserAsset> visible = _filter == null
                ? allowed
                : allowed
                    .where((UserAsset asset) => asset.type == _filter)
                    .toList(growable: false);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    ChoiceChip(
                      key: const ValueKey<String>('asset-filter-all'),
                      label: const Text('الكل'),
                      selected: _filter == null,
                      onSelected: (_) => setState(() => _filter = null),
                    ),
                    for (final AssetType type in widget.filterTypes)
                      if (allowed.any((UserAsset asset) => asset.type == type))
                        ChoiceChip(
                          key: ValueKey<String>('asset-filter-${type.dbValue}'),
                          avatar: Icon(type.icon, size: 15),
                          label: Text(type.labelAr),
                          selected: _filter == type,
                          onSelected: (_) => setState(() => _filter = type),
                        ),
                  ],
                ),
                const SizedBox(height: AppTheme.space12),
                Expanded(
                  child: visible.isEmpty
                      ? Center(
                          child: Text(
                            'لا توجد أصول من النوع «${_filter!.labelAr}».',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 170,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.86,
                          ),
                          itemCount: visible.length,
                          itemBuilder: (BuildContext context, int index) =>
                              _AssetOptionCard(
                            asset: visible[index],
                            onTap: () =>
                                Navigator.of(context).pop(visible[index]),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }
}

/// بطاقة أصل واحدة داخل النافذة: معاينة مصغّرة + الاسم + النوع والحجم.
class _AssetOptionCard extends StatelessWidget {
  const _AssetOptionCard({required this.asset, required this.onTap});

  final UserAsset asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey<String>('asset-option-${asset.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Column(
          children: <Widget>[
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                child: Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Image(
                    image: AssetImageCache.instance.providerForAsset(asset),
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    errorBuilder: (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) =>
                        Icon(
                      Icons.broken_image_outlined,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              asset.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              '${asset.type.labelAr} • ${asset.sizeLabel}',
              style: TextStyle(
                fontSize: 10.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
