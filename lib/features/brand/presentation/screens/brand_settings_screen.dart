import 'package:flutter/material.dart';

import '../../../../core/assets/asset_upload.dart';
import '../../../../core/assets/assets_controller.dart';
import '../../../../core/assets/user_asset.dart';
import '../../../../core/brand/brand_profile.dart';
import '../../../../core/brand/brand_profile_controller.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/editor/widgets/asset_library_picker.dart';
import '../../../../core/editor/widgets/editor_controls.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/models/text_flow.dart';
import '../../../../core/pdf/pdf_font_catalog.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/hex_color.dart';

/// شاشة «إعدادات الهوية والبروفايل» — أربعة تبويبات:
/// البصريات، البيانات النصية، الألوان والخطوط، والمعاينة الحيّة.
///
/// كل تعديل يُحفظ فوراً محلياً عبر [BrandProfileController] (بلا زر حفظ عام)،
/// والصور تُشار إليها بمعرّفات أصول في مكتبة الأصول فلا تُكرَّر البايتات.
class BrandSettingsScreen extends StatefulWidget {
  const BrandSettingsScreen({super.key, this.controller, this.assets});

  final BrandProfileController? controller;
  final AssetsController? assets;

  @override
  State<BrandSettingsScreen> createState() => _BrandSettingsScreenState();
}

class _BrandSettingsScreenState extends State<BrandSettingsScreen> {
  BrandProfileController get _brand =>
      widget.controller ?? BrandProfileController.instance;

  AssetsController get _assets => widget.assets ?? AssetsController.instance;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        appBar: AppBar(
          title: Text(context.l10n?.brandTitle ?? 'إعدادات الهوية والبروفايل'),
          actions: <Widget>[
            TextButton.icon(
              key: const ValueKey<String>('brand-clear'),
              onPressed: _confirmClear,
              icon: const Icon(Icons.delete_sweep_rounded, size: 18),
              label: Text(context.l10n?.brandClear ?? 'مسح الهوية'),
            ),
            const SizedBox(width: AppTheme.space8),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: <Widget>[
              Tab(
                key: const ValueKey<String>('brand-tab-visuals'),
                icon: const Icon(Icons.business_rounded, size: 18),
                text: context.l10n?.brandTabVisuals ?? 'الهوية والبصريات',
              ),
              Tab(
                key: const ValueKey<String>('brand-tab-text'),
                icon: const Icon(Icons.article_rounded, size: 18),
                text: context.l10n?.brandTabText ?? 'البيانات النصية',
              ),
              Tab(
                key: const ValueKey<String>('brand-tab-colors'),
                icon: const Icon(Icons.palette_rounded, size: 18),
                text: context.l10n?.brandTabColors ?? 'الألوان والخطوط',
              ),
              Tab(
                key: const ValueKey<String>('brand-tab-preview'),
                icon: const Icon(Icons.preview_rounded, size: 18),
                text: context.l10n?.brandTabPreview ?? 'معاينة الهوية',
              ),
            ],
          ),
        ),
        body: AnimatedBuilder(
          animation: _brand,
          builder: (BuildContext context, Widget? _) => TabBarView(
            children: <Widget>[
              _visualsTab(),
              _textTab(),
              _colorsTab(),
              _previewTab(),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  //  التبويب 1: الهوية والبصريات
  // ==========================================================================
  Widget _visualsTab() {
    final BrandProfile profile = _brand.profile;
    return _scroll(
      children: <Widget>[
        _logoCard(
          key: const ValueKey<String>('brand-primary-logo'),
          label: context.l10n?.brandPrimaryLogo ?? 'الشعار الرئيسي',
          assetId: profile.primaryLogoPath,
          onPick: () => _pickLogo(forWatermark: false),
          onUpload: () => _uploadLogo(forWatermark: false),
          onClear: () => _brand.setPrimaryLogo(null),
        ),
        _logoCard(
          key: const ValueKey<String>('brand-watermark-logo'),
          label: context.l10n?.brandWatermarkLogo ?? 'شعار العلامة المائية',
          assetId: profile.watermarkLogoPath,
          onPick: () => _pickLogo(forWatermark: true),
          onUpload: () => _uploadLogo(forWatermark: true),
          onClear: () => _brand.setWatermarkLogo(null),
        ),
        _sealsCard(),
        _signaturesCard(),
      ],
    );
  }

  Widget _logoCard({
    required Key key,
    required String label,
    required String? assetId,
    required VoidCallback onPick,
    required VoidCallback onUpload,
    required VoidCallback onClear,
  }) {
    return _card(
      key: key,
      title: label,
      icon: Icons.image_outlined,
      child: Row(
        children: <Widget>[
          _assetPreview(assetId, size: 72),
          const SizedBox(width: AppTheme.space16),
          Expanded(
            child: Wrap(
              spacing: AppTheme.space8,
              runSpacing: AppTheme.space8,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: onPick,
                  icon: const Icon(Icons.collections_bookmark_rounded, size: 16),
                  label: Text(
                      context.l10n?.editorFromMyLibrary ?? 'من مكتبة أصولي'),
                ),
                FilledButton.tonalIcon(
                  onPressed: onUpload,
                  icon: const Icon(Icons.upload_rounded, size: 16),
                  label: const Text('رفع صورة'),
                ),
                if (assetId != null)
                  TextButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: Text(context.l10n?.brandRemove ?? 'إزالة'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sealsCard() {
    final List<String> names = _brand.sealNames;
    return _card(
      key: const ValueKey<String>('brand-seals'),
      title: context.l10n?.brandSeals ?? 'الأختام الرسمية',
      icon: Icons.verified_rounded,
      trailing: TextButton.icon(
        key: const ValueKey<String>('brand-seal-add'),
        onPressed: _addSeal,
        icon: const Icon(Icons.add_rounded, size: 16),
        label: Text(context.l10n?.brandAddSeal ?? 'إضافة ختم'),
      ),
      child: names.isEmpty
          ? _emptyHint(context.l10n?.brandNoSeals ?? 'لم تُضف أختاماً بعد.')
          : Wrap(
              spacing: AppTheme.space12,
              runSpacing: AppTheme.space12,
              children: <Widget>[
                for (final String name in names)
                  _assetChip(
                    key: ValueKey<String>('brand-seal-$name'),
                    title: name,
                    assetId: _brand.sealPath(name),
                    onRemove: () => _brand.removeSeal(name),
                  ),
              ],
            ),
    );
  }

  Widget _signaturesCard() {
    final List<BrandSignature> signatures = _brand.profile.signatures;
    return _card(
      key: const ValueKey<String>('brand-signatures'),
      title: context.l10n?.brandSignatures ?? 'التوقيعات المعتمدة',
      icon: Icons.draw_rounded,
      trailing: TextButton.icon(
        key: const ValueKey<String>('brand-signature-add'),
        onPressed: _addSignature,
        icon: const Icon(Icons.add_rounded, size: 16),
        label: Text(context.l10n?.brandAddSignature ?? 'إضافة توقيع'),
      ),
      child: signatures.isEmpty
          ? _emptyHint(
              context.l10n?.brandNoSignatures ?? 'لم تُضف توقيعات بعد.')
          : Column(
              children: <Widget>[
                for (final BrandSignature signature in signatures)
                  _signatureRow(signature),
              ],
            ),
    );
  }

  Widget _signatureRow(BrandSignature signature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space8),
      child: Row(
        children: <Widget>[
          _assetPreview(signature.imagePath, size: 52),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(signature.name,
                    style: Theme.of(context).textTheme.titleSmall),
                if (signature.title.trim().isNotEmpty)
                  Text(signature.title,
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(
            key: ValueKey<String>('brand-signature-remove-${signature.id}'),
            tooltip: context.l10n?.brandRemove ?? 'إزالة',
            onPressed: () => _brand.removeSignature(signature.id),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }

  Widget _assetChip({
    required Key key,
    required String title,
    required String? assetId,
    required VoidCallback onRemove,
  }) {
    return Container(
      key: key,
      width: 150,
      padding: const EdgeInsets.all(AppTheme.space8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        children: <Widget>[
          _assetPreview(assetId, size: 64),
          const SizedBox(height: 6),
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium),
          IconButton(
            onPressed: onRemove,
            iconSize: 18,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  //  التبويب 2: البيانات النصية
  // ==========================================================================
  Widget _textTab() {
    final BrandProfile profile = _brand.profile;
    return _scroll(
      children: <Widget>[
        _card(
          key: const ValueKey<String>('brand-text-card'),
          title: context.l10n?.brandTabText ?? 'البيانات النصية',
          icon: Icons.article_rounded,
          child: Column(
            children: <Widget>[
              _field(
                key: const ValueKey<String>('brand-org-name-ar'),
                label: context.l10n?.brandOrgNameAr ?? 'اسم المؤسسة (عربي)',
                value: profile.orgNameAr,
                onChanged: _brand.setOrgNameAr,
              ),
              _field(
                key: const ValueKey<String>('brand-org-name-en'),
                label: context.l10n?.brandOrgNameEn ?? 'اسم المؤسسة (إنجليزي)',
                value: profile.orgNameEn,
                onChanged: _brand.setOrgNameEn,
              ),
              _field(
                key: const ValueKey<String>('brand-header-text'),
                label: context.l10n?.brandHeaderText ?? 'نص الترويسة',
                value: profile.headerText,
                onChanged: _brand.setHeaderText,
              ),
              _field(
                key: const ValueKey<String>('brand-footer-text'),
                label: context.l10n?.brandFooterText ?? 'نص التذييل',
                value: profile.footerText,
                onChanged: _brand.setFooterText,
              ),
              _field(
                key: const ValueKey<String>('brand-reg-number'),
                label: context.l10n?.brandRegNumber ??
                    'الرقم الضريبي/السجل التجاري',
                value: profile.taxOrRegNumber,
                onChanged: _brand.setTaxOrRegNumber,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  //  التبويب 3: الألوان والخطوط
  // ==========================================================================
  Widget _colorsTab() {
    final BrandProfile profile = _brand.profile;
    return _scroll(
      children: <Widget>[
        _card(
          key: const ValueKey<String>('brand-colors-card'),
          title: context.l10n?.brandTabColors ?? 'الألوان والخطوط',
          icon: Icons.palette_rounded,
          child: Wrap(
            spacing: AppTheme.space16,
            runSpacing: AppTheme.space16,
            children: <Widget>[
              ColorField(
                key: const ValueKey<String>('brand-primary-color'),
                label: context.l10n?.brandPrimaryColor ?? 'اللون الأساسي',
                hex: profile.primaryColorHex,
                onChanged: _brand.setPrimaryColor,
              ),
              ColorField(
                key: const ValueKey<String>('brand-secondary-color'),
                label: context.l10n?.brandSecondaryColor ?? 'اللون الثانوي',
                hex: profile.secondaryColorHex,
                onChanged: _brand.setSecondaryColor,
              ),
              ColorField(
                key: const ValueKey<String>('brand-accent-color'),
                label: context.l10n?.brandAccentColor ?? 'لون التمييز',
                hex: profile.accentColorHex,
                onChanged: _brand.setAccentColor,
              ),
            ],
          ),
        ),
        _card(
          key: const ValueKey<String>('brand-fonts-card'),
          title: context.l10n?.brandHeaderFont ?? 'خط العناوين',
          icon: Icons.text_fields_rounded,
          child: Wrap(
            spacing: AppTheme.space16,
            runSpacing: AppTheme.space16,
            children: <Widget>[
              _fontDropdown(
                key: const ValueKey<String>('brand-header-font'),
                label: context.l10n?.brandHeaderFont ?? 'خط العناوين',
                value: profile.defaultHeaderFontFamily,
                onChanged: _brand.setHeaderFontFamily,
              ),
              _fontDropdown(
                key: const ValueKey<String>('brand-body-font'),
                label: context.l10n?.brandBodyFont ?? 'خط المتن',
                value: profile.defaultBodyFontFamily,
                onChanged: _brand.setBodyFontFamily,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fontDropdown({
    required Key key,
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    final List<Object?> items = <Object?>[null, ...PdfFontFamily.values];
    return DropdownField<Object?>(
      key: key,
      label: label,
      value: items.contains(value) ? value : null,
      items: items,
      width: 220,
      labelOf: (Object? item) => item == null
          ? (context.l10n?.brandFontDefault ?? 'الافتراضي')
          : (item as PdfFontFamily).labelAr,
      onChanged: (Object? item) => onChanged(item as String?),
    );
  }

  // ==========================================================================
  //  التبويب 4: المعاينة
  // ==========================================================================
  Widget _previewTab() {
    final BrandProfile profile = _brand.profile;
    return _scroll(
      children: <Widget>[
        _card(
          key: const ValueKey<String>('brand-preview-card'),
          title: context.l10n?.brandTabPreview ?? 'معاينة الهوية',
          icon: Icons.preview_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  _assetPreview(profile.primaryLogoPath, size: 76),
                  const SizedBox(width: AppTheme.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          profile.displayName.isEmpty
                              ? (context.l10n?.brandNoBrand ??
                                  'لم تُعدّ هويتك بعد.')
                              : profile.displayName,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: _hex(profile.primaryColorHex)),
                        ),
                        if (profile.headerText.trim().isNotEmpty)
                          Text(
                            profile.headerText,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        if (profile.taxOrRegNumber.trim().isNotEmpty)
                          Text(
                            profile.taxOrRegNumber,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: _hex(profile.secondaryColorHex)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: AppTheme.space24),
              if (_brand.hasSeals)
                Wrap(
                  spacing: AppTheme.space12,
                  runSpacing: AppTheme.space12,
                  children: <Widget>[
                    for (final String name in _brand.sealNames)
                      Column(
                        children: <Widget>[
                          _assetPreview(_brand.sealPath(name), size: 64),
                          Text(name,
                              style: Theme.of(context).textTheme.labelSmall),
                        ],
                      ),
                  ],
                ),
              if (_brand.hasSignatures)
                Padding(
                  padding: const EdgeInsets.only(top: AppTheme.space12),
                  child: Wrap(
                    spacing: AppTheme.space24,
                    runSpacing: AppTheme.space12,
                    children: <Widget>[
                      for (final BrandSignature signature
                          in profile.signatures)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            _assetPreview(signature.imagePath, size: 56),
                            Text(signature.name,
                                style: Theme.of(context).textTheme.labelMedium),
                            if (signature.title.trim().isNotEmpty)
                              Text(signature.title,
                                  style:
                                      Theme.of(context).textTheme.labelSmall),
                          ],
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  //  الإجراءات
  // ==========================================================================

  Future<void> _pickLogo({required bool forWatermark}) async {
    final UserAsset? asset = await showAssetLibraryPicker(
      context,
      assets: _assets,
      title: forWatermark
          ? (context.l10n?.brandWatermarkLogo ?? 'شعار العلامة المائية')
          : (context.l10n?.brandPrimaryLogo ?? 'الشعار الرئيسي'),
    );
    if (asset == null) return;
    if (forWatermark) {
      await _brand.setWatermarkLogo(asset.id);
    } else {
      await _brand.setPrimaryLogo(asset.id);
    }
  }

  Future<void> _uploadLogo({required bool forWatermark}) async {
    final int added = await uploadUserAssets(
      context,
      controller: _assets,
      type: AssetType.logo,
    );
    if (added == 0 || !mounted) return;
    final List<UserAsset> logos = _assets.byType(AssetType.logo);
    if (logos.isEmpty) return;
    // أحدث شعار مرفوع (الترتيب داخل النوع أبجدي، فنبحث عن الأحدث زمنياً).
    final UserAsset newest = logos.reduce(
      (UserAsset a, UserAsset b) => a.addedAt.isAfter(b.addedAt) ? a : b,
    );
    if (forWatermark) {
      await _brand.setWatermarkLogo(newest.id);
    } else {
      await _brand.setPrimaryLogo(newest.id);
    }
  }

  Future<void> _addSeal() async {
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => _TextPromptDialog(
        title: context.l10n?.brandAddSeal ?? 'إضافة ختم',
        label: context.l10n?.brandSealName ?? 'اسم الختم',
      ),
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    final UserAsset? asset = await showAssetLibraryPicker(
      context,
      assets: _assets,
      title: name,
    );
    if (asset == null) return;
    await _brand.setSeal(name, asset.id);
    if (mounted) _toast(context.l10n?.brandSaved ?? 'حُفظت الهوية.');
  }

  Future<void> _addSignature() async {
    final _SignatureDraft? draft = await showDialog<_SignatureDraft>(
      context: context,
      builder: (BuildContext dialogContext) => _SignatureDialog(
        nameLabel: context.l10n?.brandSignatureName ?? 'اسم صاحب التوقيع',
        titleLabel: context.l10n?.brandSignatureTitle ?? 'المسمّى الوظيفي',
      ),
    );
    if (draft == null || !mounted) return;
    String? imageId;
    if (draft.pickImage) {
      final UserAsset? asset = await showAssetLibraryPicker(
        context,
        assets: _assets,
        title: draft.name,
      );
      imageId = asset?.id;
    }
    await _brand.upsertSignature(
      BrandSignature(
        id: 'sig_${DateTime.now().microsecondsSinceEpoch}',
        name: draft.name,
        title: draft.title,
        imagePath: imageId,
      ),
    );
    if (mounted) _toast(context.l10n?.brandSaved ?? 'حُفظت الهوية.');
  }

  Future<void> _confirmClear() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(context.l10n?.brandClear ?? 'مسح الهوية'),
        content:
            Text(context.l10n?.brandClearConfirm ?? 'سيُحذف كل محتوى الهوية.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n?.brandClear ?? 'مسح الهوية'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _brand.clear();
    if (mounted) _toast(context.l10n?.brandSaved ?? 'حُفظت الهوية.');
  }

  // ==========================================================================
  //  أدوات بناء الواجهة
  // ==========================================================================

  Widget _scroll({required List<Widget> children}) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      );

  Widget _card({
    required Key key,
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space16),
      child: Card(
        key: key,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(icon,
                      size: 18, color: Theme.of(context).colorScheme.goldDeep),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(title,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  ?trailing,
                ],
              ),
              const SizedBox(height: AppTheme.space16),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required Key key,
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space12),
      child: _BrandTextField(
        key: key,
        label: label,
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _emptyHint(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      );

  /// معاينة أصل بمعرّفه، أو مربّع فارغ أنيق عند غيابه.
  Widget _assetPreview(String? assetId, {required double size}) {
    final UserAsset? asset = _assets.byId(assetId);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: asset == null
          ? Icon(Icons.image_not_supported_outlined,
              size: size * 0.4,
              color: Theme.of(context).colorScheme.onSurfaceVariant)
          : Image.memory(
              asset.bytes,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              errorBuilder: (BuildContext c, Object e, StackTrace? s) => Icon(
                Icons.broken_image_outlined,
                size: size * 0.4,
                color: AppColors.inkMuted,
              ),
            ),
    );
  }

  Color _hex(String hex) => colorFromHex(hex, fallback: AppColors.navy);

  void _toast(String message) {
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}

/// حقل نصي يُزامن قيمته مع البروفايل بلا إعادة بناء تُفقد المؤشّر.
class _BrandTextField extends StatefulWidget {
  const _BrandTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_BrandTextField> createState() => _BrandTextFieldState();
}

class _BrandTextFieldState extends State<_BrandTextField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_BrandTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // مزامنة عند تغيّر القيمة من الخارج (مثلاً بعد مسح الهوية) بلا مقاطعة الكتابة.
    if (widget.value != _controller.text &&
        !_controller.value.composing.isValid) {
      _controller.text = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    // بيانات العلامة مختلطة: «اسم المؤسسة (عربي)» عربي و«(إنجليزي)» لاتيني،
    // فالاتجاه يُستمدّ من المحتوى لا من لغة الواجهة — فتُحاذاة النص وتتحرّك
    // مؤشر الأسهم في اتجاهه الصحيح في الحالتين.
    final TextDirection direction = _controller.text.isEmpty
        ? Directionality.of(context)
        : (TextFlow.looksRightToLeft(_controller.text)
              ? TextDirection.rtl
              : TextDirection.ltr);
    return TextField(
      controller: _controller,
      textDirection: direction,
      textAlign: TextAlign.start,
      onChanged: (String value) {
        widget.onChanged(value);
        // إعادة بناء لحظية كي يتبدّل الاتجاه فور اقتحام النص العربي/اللاتيني.
        setState(() {});
      },
      decoration: InputDecoration(
        labelText: widget.label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

/// نافذة طلب نص واحد (اسم الختم).
class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({required this.title, required this.label});

  final String title;
  final String label;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const ValueKey<String>('brand-seal-name-field'),
        controller: _controller,
        autofocus: true,
        // اسم الختم عربي — اتجاه صريح يمنع انعكاس تنقّل الأسهم.
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        decoration: InputDecoration(labelText: widget.label),
        onSubmitted: (String value) => Navigator.of(context).pop(value),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          key: const ValueKey<String>('brand-seal-name-confirm'),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(context.l10n?.commonSave ?? 'حفظ'),
        ),
      ],
    );
  }
}

/// مسودة توقيع تُجمع من نافذة الإضافة.
class _SignatureDraft {
  const _SignatureDraft({
    required this.name,
    required this.title,
    required this.pickImage,
  });

  final String name;
  final String title;
  final bool pickImage;
}

/// نافذة إضافة توقيع (الاسم + المسمّى + خيار اختيار صورة).
class _SignatureDialog extends StatefulWidget {
  const _SignatureDialog({required this.nameLabel, required this.titleLabel});

  final String nameLabel;
  final String titleLabel;

  @override
  State<_SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<_SignatureDialog> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _title = TextEditingController();
  bool _pickImage = true;

  @override
  void dispose() {
    _name.dispose();
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n?.brandAddSignature ?? 'إضافة توقيع'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            key: const ValueKey<String>('brand-signature-name-field'),
            controller: _name,
            autofocus: true,
            // الاسم والدور عربيّان — اتجاه صريح يمنع انعكاس تنقّل الأسهم.
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            decoration: InputDecoration(labelText: widget.nameLabel),
          ),
          const SizedBox(height: AppTheme.space8),
          TextField(
            key: const ValueKey<String>('brand-signature-title-field'),
            controller: _title,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            decoration: InputDecoration(labelText: widget.titleLabel),
          ),
          CheckboxListTile(
            value: _pickImage,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (bool? value) =>
                setState(() => _pickImage = value ?? false),
            title: Text(
                context.l10n?.editorFromMyLibrary ?? 'من مكتبة أصولي'),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          key: const ValueKey<String>('brand-signature-confirm'),
          onPressed: () {
            final String name = _name.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop(
              _SignatureDraft(
                name: name,
                title: _title.text.trim(),
                pickImage: _pickImage,
              ),
            );
          },
          child: Text(context.l10n?.commonSave ?? 'حفظ'),
        ),
      ],
    );
  }
}
