import 'package:flutter/material.dart';

import '../../assets/assets_controller.dart';
import '../../assets/user_asset.dart';
import '../../brand/brand_presets.dart';
import '../../brand/brand_profile.dart';
import '../../brand/brand_profile_controller.dart';
import '../../l10n/app_l10n.dart';
import '../../theme/app_theme.dart';
import '../template_editor_controller.dart';
import 'editor_controls.dart';

/// قسم «عناصر الهوية الجاهزة» داخل المحرّر: إدراج سريع للأختام والتوقيعات،
/// وبناء الترويسة/التذييل القياسي ككتلة مجمّعة، وتطبيق ألوان الهوية.
class BrandPresetsPanel extends StatelessWidget {
  const BrandPresetsPanel({
    super.key,
    required this.controller,
    this.brand,
    this.assets,
    this.onOpenSettings,
  });

  final TemplateEditorController controller;
  final BrandProfileController? brand;
  final AssetsController? assets;

  /// يُستدعى من زرّ «فتح إعدادات الهوية» (المضيف ينتقل إلى الشاشة).
  final VoidCallback? onOpenSettings;

  BrandProfileController get _brand => brand ?? BrandProfileController.instance;
  AssetsController get _assets => assets ?? AssetsController.instance;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _brand,
      builder: (BuildContext context, Widget? _) {
        final BrandProfile profile = _brand.profile;
        return ControlSection(
          icon: Icons.business_center_rounded,
          label: context.l10n?.brandPresets ?? 'عناصر الهوية الجاهزة',
          children: <Widget>[
            if (_brand.isEmpty || profile.isEmpty)
              _empty(context)
            else ...<Widget>[
              _insertRow(context, profile),
              if (_brand.hasSeals) _sealsRow(context, profile),
              if (_brand.hasSignatures) _signaturesRow(context, profile),
              _applyColorsRow(context, profile),
            ],
          ],
        );
      },
    );
  }

  Widget _empty(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.l10n?.brandNoBrand ?? 'لم تُعدّ هويتك بعد.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppTheme.space8),
        if (onOpenSettings != null)
          OutlinedButton.icon(
            key: const ValueKey<String>('brand-open-settings'),
            onPressed: onOpenSettings,
            icon: const Icon(Icons.settings_rounded, size: 16),
            label: Text(
                context.l10n?.brandOpenSettings ?? 'فتح إعدادات الهوية'),
          ),
      ],
    );
  }

  Widget _insertRow(BuildContext context, BrandProfile profile) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        FilledButton.tonalIcon(
          key: const ValueKey<String>('brand-insert-header'),
          onPressed: () => _insertHeader(context, profile),
          icon: const Icon(Icons.vertical_align_top_rounded, size: 16),
          label: Text(
              context.l10n?.brandInsertHeader ?? 'إدراج الترويسة القياسية'),
        ),
        OutlinedButton.icon(
          key: const ValueKey<String>('brand-insert-footer'),
          onPressed: () => _insertFooter(context, profile),
          icon: const Icon(Icons.vertical_align_bottom_rounded, size: 16),
          label: Text(
              context.l10n?.brandInsertFooter ?? 'إدراج التذييل القياسي'),
        ),
      ],
    );
  }

  Widget _sealsRow(BuildContext context, BrandProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(context.l10n?.brandQuickSeals ?? 'أختام',
            style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final String name in _brand.sealNames)
              OutlinedButton.icon(
                key: ValueKey<String>('brand-seal-quick-$name'),
                onPressed: () => _insertSeal(context, name),
                icon: const Icon(Icons.verified_rounded, size: 15),
                label: Text(name),
              ),
          ],
        ),
      ],
    );
  }

  Widget _signaturesRow(BuildContext context, BrandProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(context.l10n?.brandQuickSignatures ?? 'توقيعات',
            style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final BrandSignature signature in profile.signatures)
              OutlinedButton.icon(
                key: ValueKey<String>('brand-signature-quick-${signature.id}'),
                onPressed: () => _insertSignature(context, signature),
                icon: const Icon(Icons.draw_rounded, size: 15),
                label: Text(
                  signature.title.trim().isEmpty
                      ? signature.name
                      : '${signature.name} — ${signature.title}',
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _applyColorsRow(BuildContext context, BrandProfile profile) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        OutlinedButton.icon(
          key: const ValueKey<String>('brand-apply-colors'),
          onPressed: () {
            controller.applyBrandPalette(
              primaryHex: profile.primaryColorHex,
              secondaryHex: profile.secondaryColorHex,
            );
            _toast(context, context.l10n?.brandColorsApplied ?? 'طُبّقت ألوان الهوية.');
          },
          icon: const Icon(Icons.palette_rounded, size: 16),
          label: Text(context.l10n?.brandApplyColors ?? 'تطبيق ألوان الهوية'),
        ),
      ],
    );
  }

  // ==========================================================================
  //  الإدراج
  // ==========================================================================

  void _insertHeader(BuildContext context, BrandProfile profile) {
    final UserAsset? logo = _assets.byId(profile.primaryLogoPath);
    final BrandBlock block = BrandPresets.buildHeader(
      profile: profile,
      design: controller.designSize,
      logo: logo,
      index: controller.document.elements.length,
    );
    if (block.isEmpty) return;
    controller.insertBrandBlock(block);
    _toast(context, context.l10n?.brandHeaderInserted ?? 'أُدرجت الترويسة القياسية.');
  }

  void _insertFooter(BuildContext context, BrandProfile profile) {
    final BrandBlock block = BrandPresets.buildFooter(
      profile: profile,
      design: controller.designSize,
      index: controller.document.elements.length,
    );
    if (block.isEmpty) return;
    controller.insertBrandBlock(block);
    _toast(context, context.l10n?.brandFooterInserted ?? 'أُدرج التذييل القياسي.');
  }

  void _insertSeal(BuildContext context, String name) {
    final UserAsset? asset = _assets.byId(_brand.sealPath(name));
    if (asset == null) return;
    controller.addElementInstance(
      BrandPresets.buildSealImage(
        asset: asset,
        design: controller.designSize,
        index: controller.document.elements.length,
      ),
    );
    _toast(context, context.l10n?.brandSealInserted ?? 'أُدرج الختم.');
  }

  void _insertSignature(BuildContext context, BrandSignature signature) {
    final UserAsset? asset = _assets.byId(signature.imagePath);
    if (asset == null) return;
    controller.addElementInstance(
      BrandPresets.buildSealImage(
        asset: asset,
        design: controller.designSize,
        index: controller.document.elements.length,
      ),
    );
    _toast(context, context.l10n?.brandSignatureInserted ?? 'أُدرج التوقيع.');
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(message)));
  }
}
