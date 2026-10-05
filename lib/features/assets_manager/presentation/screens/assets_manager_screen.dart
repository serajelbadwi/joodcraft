import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/assets/asset_image_cache.dart';
import '../../../../core/assets/asset_image_disk_cache.dart';
import '../../../../core/assets/asset_type_ui.dart';
import '../../../../core/assets/asset_upload.dart';
import '../../../../core/assets/assets_controller.dart';
import '../../../../core/assets/user_asset.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/editor/widgets/editor_controls.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/ui_feedback.dart';

/// مدير الأصول (المرحلة 5ب): الشعار والختم والتوقيع والإطار.
///
/// كل الأصول محلية على جهاز المستخدم (تُستعاد أوفلاين عند بدء التشغيل)، وتُربط
/// بالقوالب عبر عنصر صورة مصدره `مكتبة أصولي`، ويُرسمها محرّك الطباعة مباشرةً.
class AssetsManagerScreen extends StatefulWidget {
  const AssetsManagerScreen({
    super.key,
    this.controller,
    this.cacheStats,
    this.onClearCache,
    this.cacheMaxBytes,
  });

  /// متحكّم الأصول — يُحقن في الاختبارات (نسخة في الذاكرة).
  final AssetsController? controller;

  /// قارئ حجم كاش الصور القرصي — يُحقن في الاختبارات لتفادي قراءة قرص حقيقية
  /// (والتي لا تكتمل داخل منطقة `testWidgets` الزمنية المزيّفة).
  final Future<AssetImageCacheStats> Function()? cacheStats;

  /// منظّف الكاش — يُحقن في الاختبارات.
  final Future<void> Function()? onClearCache;

  /// سقف كاش القرص (بايتات) المعروض مقابل الاستهلاك — يُحقن في الاختبارات،
  /// وافتراضه سقف المخزن نفسه (`AssetImageDiskCache.maxBytes`).
  final int? cacheMaxBytes;

  @override
  State<AssetsManagerScreen> createState() => _AssetsManagerScreenState();
}

class _AssetsManagerScreenState extends State<AssetsManagerScreen> {
  late final AssetsController _controller =
      widget.controller ?? AssetsController.instance;
  final TextEditingController _search = TextEditingController();

  AssetType? _type;

  /// إحصاء كاش الصور القرصي — `null` ما دام يُقرأ.
  AssetImageCacheStats? _cacheStats;
  bool _clearingCache = false;

  @override
  void initState() {
    super.initState();
    if (!_controller.isRestored) unawaited(_controller.restore());
    unawaited(_refreshCacheStats());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _header(context),
            Expanded(child: _body(context)),
          ],
        );
      },
    );
  }

  // ==========================================================================
  //  الترويسة
  // ==========================================================================
  Widget _header(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.folder_special_rounded,
                  color: Theme.of(context).colorScheme.primary, size: 22),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(context.l10n?.destAssets ?? 'الأصول والتوقيعات',
                        style: text.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n?.amSubtitle ??
                          'ارفع شعارك وختمك وتوقيعك مرة واحدة، ثم أدرجه في أي قالب — '
                              'يُحفظ على جهازك ويُستعاد أوفلاين.',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              _CountChip(count: _controller.count),
              const SizedBox(width: AppTheme.space8),
              _uploadButton(context),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          Wrap(
            spacing: AppTheme.space12,
            runSpacing: AppTheme.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 260,
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    hintText: context.l10n?.amSearchHint ?? 'بحث في الأصول…',
                    hintStyle: const TextStyle(fontSize: 12.5),
                  ),
                ),
              ),
              DropdownField<AssetType?>(
                label: context.l10n?.amTypeLabel ?? 'النوع',
                value: _type,
                items: <AssetType?>[null, ...AssetType.values],
                labelOf: (AssetType? type) =>
                    type?.labelAr ?? context.l10n?.alpFilterAll ?? 'الكل',
                width: 160,
                onChanged: (AssetType? type) => setState(() => _type = type),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space8),
          _cacheBar(context),
        ],
      ),
    );
  }

  // ==========================================================================
  //  كاش الصور على القرص (حجمه ومسحه)
  // ==========================================================================

  /// يقرأ حجم الكاش القرصي ويحدّث الواجهة (لا يرمي).
  Future<void> _refreshCacheStats() async {
    AssetImageCacheStats stats;
    try {
      stats = await (widget.cacheStats?.call() ??
          AssetImageDiskCache.instance.stats());
    } on Object catch (_) {
      stats = AssetImageCacheStats.empty;
    }
    if (!mounted) return;
    setState(() => _cacheStats = stats);
  }

  /// يمسح كاش الصور القرصي (والنسخ الساخنة في الذاكرة) ثم يعيد قراءة الحجم.
  Future<void> _clearCache() async {
    if (_clearingCache) return;
    setState(() => _clearingCache = true);
    final Future<void> Function()? clear = widget.onClearCache;
    if (clear != null) {
      await clear();
    } else {
      await AssetImageDiskCache.instance.clear();
      AssetImageCache.instance.clear();
    }
    await _refreshCacheStats();
    if (!mounted) return;
    setState(() => _clearingCache = false);
    context.showSuccess(
      context.l10n?.amCacheCleared ?? 'تم مسح ذاكرة الصور على القرص.',
    );
  }

  /// شريط يعرض استهلاك الكاش القرصي **مقابل سقفه** وزرّ مسحه.
  Widget _cacheBar(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AssetImageCacheStats? stats = _cacheStats;
    final int maxBytes = widget.cacheMaxBytes ??
        AssetImageDiskCache.instance.maxBytes;
    final bool enabled = !_clearingCache && stats != null && !stats.isEmpty;

    final String usage;
    if (stats == null) {
      usage = '…';
    } else if (stats.isEmpty) {
      usage = context.l10n?.amCacheEmpty ?? 'لا ذاكرة قرصية بعد';
    } else {
      usage = context.l10n?.amCacheUsageOf(
            '${stats.files}',
            _formatBytes(stats.bytes),
            _formatBytes(maxBytes),
          ) ??
          '${stats.files} ملف · ${_formatBytes(stats.bytes)} من '
              '${_formatBytes(maxBytes)}';
    }

    // نسبة الاستهلاك من السقف (0..1) — تُرسم شريطاً تحت السطر ليفهم المستخدم
    // قرب امتلاء الكاش قبل أن يبدأ الطرف بحذف الأقدم.
    final double ratio = (stats == null || maxBytes <= 0)
        ? 0
        : (stats.bytes / maxBytes).clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(Icons.sd_storage_outlined,
                size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppTheme.space8),
            Text(
              context.l10n?.amCacheLabel ?? 'ذاكرة الصور على القرص',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(width: AppTheme.space8),
            Expanded(
              child: Text(
                usage,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton.icon(
              onPressed: enabled ? () => unawaited(_clearCache()) : null,
              icon: const Icon(Icons.delete_sweep_rounded, size: 16),
              label: Text(context.l10n?.amCacheClear ?? 'مسح الذاكرة'),
            ),
          ],
        ),
        if (stats != null && !stats.isEmpty) ...<Widget>[
          const SizedBox(height: AppTheme.space4),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            child: LinearProgressIndicator(
              key: const Key('cache-usage-progress'),
              value: ratio,
              minHeight: 4,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ],
    );
  }

  /// صيغة مقروئة لحجم بالبايتات.
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final int kb = bytes ~/ 1024;
    if (kb < 1024) return '$kb KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  Widget _uploadButton(BuildContext context) {
    return PopupMenuButton<AssetType>(
      tooltip: context.l10n?.amUploadTooltip ?? 'رفع أصل جديد',
      onSelected: (AssetType type) =>
          unawaited(uploadUserAssets(context, type: type, controller: _controller)),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<AssetType>>[
        for (final AssetType type in AssetType.values)
          PopupMenuItem<AssetType>(
            value: type,
            child: Row(
              children: <Widget>[
                Icon(type.icon, size: 17, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  context.l10n?.assetUploadType(type.labelAr) ??
                      'رفع ${type.labelAr}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.upload_file_rounded,
                size: 17, color: AppColors.navy),
            const SizedBox(width: 8),
            Text(
              context.l10n?.amUpload ?? 'رفع أصل',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  //  المحتوى
  // ==========================================================================
  Widget _body(BuildContext context) {
    final List<UserAsset> visible = _visibleAssets();
    if (_controller.isEmpty) {
      return _NoticeCard(
        icon: Icons.add_photo_alternate_outlined,
        title: context.l10n?.amEmptyTitle ?? 'لا توجد أصول بعد',
        message: context.l10n?.amEmptyMessage ??
            'ارفع شعار مؤسستك أو توقيعك أو ختمك، ثم أدرجه في أي قالب من '
                'شريط خصائص الصورة.',
      );
    }
    if (visible.isEmpty) {
      return _NoticeCard(
        icon: Icons.search_off_rounded,
        title: context.l10n?.tplNoResultsTitle ?? 'لا نتائج مطابقة',
        message: context.l10n?.amNoResultsMessage ??
            'جرّب اسماً آخر أو أعد ضبط عامل التصفية.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppTheme.space16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisExtent: 260,
        crossAxisSpacing: AppTheme.space12,
        mainAxisSpacing: AppTheme.space12,
      ),
      itemCount: visible.length,
      itemBuilder: (BuildContext context, int index) => _AssetCard(
        asset: visible[index],
        onRename: _rename,
        onDelete: _delete,
        onReassign: _reassign,
      ),
    );
  }

  List<UserAsset> _visibleAssets() {
    final String needle = _search.text.trim().toLowerCase();
    return _controller.assets
        .where(
          (UserAsset asset) =>
              (_type == null || asset.type == _type) &&
              (needle.isEmpty ||
                  asset.name.toLowerCase().contains(needle) ||
                  asset.typeLabelAr.contains(needle)),
        )
        .toList(growable: false);
  }

  // ==========================================================================
  //  الإجراءات
  // ==========================================================================

  Future<void> _rename(UserAsset asset) async {
    // الحقل يملكه ودجت النافذة نفسه (يتنظّف في `dispose`) بدل إنشائه هنا
    // وإتلافه فور ارتجاع `showDialog`: الإتلاف المبكر يقع أثناء حركة إغلاق
    // النافذة بينما `TextField` لا يزال يشير إلى المتحكّم.
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) =>
          _RenameAssetDialog(initial: asset.name),
    );
    if (name == null || !mounted) return;
    await _controller.renameAsset(asset.id, name);
    if (mounted) {
      context.showSuccess(context.l10n?.amRenamed ?? 'أُعيدت تسمية الأصل.');
    }
  }

  Future<void> _reassign(UserAsset asset, AssetType type) async {
    if (asset.type == type) return;
    // تغيير النوع: نُضيف النسخة الجديدة بالنوع المطلوب **أولاً**، ثم نحذف
    // الأصل القديم — فإن فشلت الإضافة (لأي سبب) لا يضيع الأصل الأصلي.
    await _controller.addAsset(
      type: type,
      name: asset.name,
      fileName: asset.fileName,
      bytes: asset.bytes,
    );
    await _controller.removeAsset(asset.id);
    if (!mounted) return;
    context.showSuccess(
      context.l10n?.amMovedToType(type.labelAr) ??
          'نُقل الأصل إلى «${type.labelAr}».',
    );
  }

  Future<void> _delete(UserAsset asset) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(context.l10n?.amDeleteTitle ?? 'حذف الأصل'),
        content: Text(
          context.l10n?.amConfirmDelete(asset.name) ??
              'سيُحذف «${asset.name}» من هذا الجهاز. القوالب التي تستخدمه ستفقد '
                  'الصورة (دون فشل الطباعة).',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n?.editorCancel ?? 'إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n?.tplDelete ?? 'حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _controller.removeAsset(asset.id);
    if (mounted) {
      context.showSuccess(
        context.l10n?.amDeleted(asset.name) ?? 'حُذف الأصل «${asset.name}».',
      );
    }
  }
}

/// نافذة إعادة تسمية أصل — تملك متحكّم حقلها وتُنظّفه بنفسها.
class _RenameAssetDialog extends StatefulWidget {
  const _RenameAssetDialog({required this.initial});

  final String initial;

  @override
  State<_RenameAssetDialog> createState() => _RenameAssetDialogState();
}

class _RenameAssetDialogState extends State<_RenameAssetDialog> {
  late final TextEditingController _field =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n?.amRenameTitle ?? 'إعادة تسمية الأصل'),
      content: TextField(
        controller: _field,
        autofocus: true,
        maxLength: AppConstants.maxNameLength,
        decoration: InputDecoration(
          labelText: context.l10n?.authName ?? 'الاسم',
        ),
        onSubmitted: (String value) => Navigator.of(context).pop(value.trim()),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n?.editorCancel ?? 'إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_field.text.trim()),
          child: Text(context.l10n?.commonSave ?? 'حفظ'),
        ),
      ],
    );
  }
}

/// شريحة عدد الأصول في الترويسة.
class _CountChip extends StatelessWidget {
  const _CountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Text(
        context.l10n?.amCount(count) ?? '$count أصل',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// بطاقة أصل واحد.
class _AssetCard extends StatelessWidget {
  const _AssetCard({
    required this.asset,
    required this.onRename,
    required this.onDelete,
    required this.onReassign,
  });

  final UserAsset asset;
  final ValueChanged<UserAsset> onRename;
  final ValueChanged<UserAsset> onDelete;
  final void Function(UserAsset asset, AssetType type) onReassign;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      key: ValueKey<String>('asset-card-${asset.id}'),
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              padding: const EdgeInsets.all(8),
              // موفّر مُخزَّن (تفكّ البايتات مرة واحدة) بدل `Image.memory`
              // الذي يعيد فكّ Base64 في كل بناء ويُبطل imageCache.
              child: Image(
                image: AssetImageCache.instance.providerForAsset(asset),
                fit: BoxFit.contain,
                gaplessPlayback: true,
                errorBuilder: (
                  BuildContext context,
                  Object error,
                  StackTrace? stackTrace,
                ) =>                    const Center(
                  child: Icon(Icons.broken_image_outlined,
                      color: AppColors.inkMuted),
                    ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          Row(
            children: <Widget>[
              Icon(asset.type.icon, size: 15, color: Theme.of(context).colorScheme.goldDeep),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  asset.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall,
                ),
              ),
              PopupMenuButton<_CardAction>(
                tooltip: context.l10n?.commonOptions ?? 'خيارات',
                onSelected: (_CardAction action) {
                  switch (action) {
                    case _CardAction.rename:
                      onRename(asset);
                    case _CardAction.delete:
                      onDelete(asset);
                    case _CardAction.typeLogo:
                      onReassign(asset, AssetType.logo);
                    case _CardAction.typeSignature:
                      onReassign(asset, AssetType.signature);
                    case _CardAction.typeStamp:
                      onReassign(asset, AssetType.stamp);
                    case _CardAction.typeBorder:
                      onReassign(asset, AssetType.border);
                  }
                },
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<_CardAction>>[
                  PopupMenuItem<_CardAction>(
                    value: _CardAction.rename,
                    child: _MenuRow(
                      icon: Icons.drive_file_rename_outline_rounded,
                      label: context.l10n?.tplRename ?? 'إعادة التسمية',
                    ),
                  ),
                  const PopupMenuDivider(),
                  for (final AssetType type in AssetType.values)
                    PopupMenuItem<_CardAction>(
                      value: _CardActionX.of(type),
                      child: _MenuRow(
                        icon: type.icon,
                        label: context.l10n?.amMakeType(type.labelAr) ??
                            'اجعل النوع: ${type.labelAr}',
                        selected: type == asset.type,
                      ),
                    ),
                  const PopupMenuDivider(),
                  PopupMenuItem<_CardAction>(
                    value: _CardAction.delete,
                    child: _MenuRow(
                      icon: Icons.delete_outline_rounded,
                      label: context.l10n?.tplDelete ?? 'حذف',
                      danger: true,
                    ),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Icon(Icons.more_vert_rounded,
                      size: 19,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          Text(
            '${asset.typeLabelAr} • ${asset.sizeLabel}',
            style: text.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// خيارات بطاقة الأصل.
enum _CardAction { rename, delete, typeLogo, typeSignature, typeStamp, typeBorder }

abstract final class _CardActionX {
  static _CardAction of(AssetType type) => switch (type) {
        AssetType.logo => _CardAction.typeLogo,
        AssetType.signature => _CardAction.typeSignature,
        AssetType.stamp => _CardAction.typeStamp,
        AssetType.border => _CardAction.typeBorder,
      };
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.danger = false,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool danger;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = danger
        ? scheme.danger
        : selected
            ? scheme.goldDeep
            : scheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

/// بطاقة حالة موحّدة (فراغ/لا نتائج).
class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 34, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: AppTheme.space12),
              Text(title, style: text.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: AppTheme.space8),
              Text(message, style: text.bodyMedium, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
