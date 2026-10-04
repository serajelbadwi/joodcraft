// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline =>
      'Generate official certificates and contracts offline';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navCertificates => 'Certificate Builder';

  @override
  String get navContracts => 'Contract Builder';

  @override
  String get navBatch => 'Batch Generation';

  @override
  String get navTemplates => 'Template Library';

  @override
  String get navAssets => 'Assets & Signatures';

  @override
  String get actionSignOut => 'Sign out';

  @override
  String get actionBackToDashboard => 'Back to dashboard';

  @override
  String get offlineProcessingLabel => 'Local processing';

  @override
  String get themeTooltip => 'Toggle theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageTooltip => 'Change language';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageUrdu => 'اردو';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageIndonesian => 'Bahasa Indonesia';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageChinese => '简体中文';

  @override
  String get configMissingKeysTitle => 'Connection keys not found';

  @override
  String get configMissingKeysBody =>
      'At startup the app looks for keys in three sources: the --dart-define flag, then an env.json file on disk (root or assets/env/), then the bundled copy inside the app — but none was found. Create the file, fill it once, then run with no flags:';

  @override
  String get configEnvNote =>
      'The bundle declares assets/env/ as an asset, so a missing file will not break a clean build. Create it from env.example.json or run: dart run tool/ensure_env.dart — only the anon/public key is required; service_role is never used in the app.';

  @override
  String get routeNotFoundTitle => 'Page not found';

  @override
  String get routeNotFoundBody =>
      'The requested route is not defined in the app:';

  @override
  String get editorPrecisionTitle => 'Precision controls';

  @override
  String get editorNudgeStep => 'Nudge step';

  @override
  String get editorNudgeStepHint =>
      'The arrows on the canvas also nudge by Shift = 10px.';

  @override
  String get editorNudgeUp => 'Nudge up';

  @override
  String get editorNudgeLeft => 'Nudge left';

  @override
  String get editorNudgeDown => 'Nudge down';

  @override
  String get editorNudgeRight => 'Nudge right';

  @override
  String get editorScale => 'Scale';

  @override
  String get editorScaleHint =>
      'Relative scaling around the element centre (scroll on the buttons for finer steps).';

  @override
  String get editorScaleUp => 'Zoom in';

  @override
  String get editorScaleDown => 'Zoom out';

  @override
  String get editorDecorTitle => 'Vector decoration';

  @override
  String get editorDecorKind => 'Decoration type';

  @override
  String get editorDecorPalette => 'Colour palette';

  @override
  String get editorDecorLayers => 'Layer count';

  @override
  String get editorDecorSeed => 'Seed';

  @override
  String get editorDecorThickness => 'Thickness';

  @override
  String get editorDecorPrimary => 'Primary colour';

  @override
  String get editorDecorSecondary => 'Secondary colour';

  @override
  String get editorDecorAccent => 'Accent colour';

  @override
  String get editorDecorGradient => 'Layer gradient';

  @override
  String get editorDecorGallery => 'Preset gallery';

  @override
  String get editorDecorGalleryTitle => 'Ready-made decoration gallery';

  @override
  String get editorClose => 'Close';

  @override
  String get editorDecorPaletteCustom => 'Custom';

  @override
  String get decorKindModernWave => 'Modern waves';

  @override
  String get decorKindPaperCut => 'Layered paper cut';

  @override
  String get decorKindClassicCorner => 'Classic ornate frame';

  @override
  String get decorKindGuilloche => 'Guilloche pattern';

  @override
  String get decorKindRibbonBanner => 'Ribbon banner';

  @override
  String get decorPaletteRoyalGold => 'Royal gold';

  @override
  String get decorPaletteRoyalBlue => 'Royal blue';

  @override
  String get decorPaletteEmerald => 'Emerald';

  @override
  String get decorPaletteBurgundy => 'Burgundy';

  @override
  String get decorPaletteMidnight => 'Midnight navy';

  @override
  String get decorPaletteMono => 'Monochrome grey';

  @override
  String get editorSignatureTitle => 'Signature block';

  @override
  String get editorSignatureCount => 'Number of signatures';

  @override
  String get signatureCountOne => 'One signature';

  @override
  String get signatureCountTwo => 'Two signatures';

  @override
  String get signatureCountThree => 'Three signatures';

  @override
  String get editorSignatureOrder => 'Slot order';

  @override
  String get editorSignatureOrderHint =>
      'In Arabic documents the first slot sits at the far right.';

  @override
  String get editorSignatureFirstRight => 'First on the right';

  @override
  String get editorSignatureFirstLeft => 'First on the left';

  @override
  String get editorDirectionAuto => 'Automatic';

  @override
  String get editorSignatureImageAlign => 'Image alignment';

  @override
  String get editorAlignStart => 'Start';

  @override
  String get editorAlignCenter => 'Centre';

  @override
  String get editorAlignEnd => 'End';

  @override
  String get editorSignatureDivider => 'Signature line';

  @override
  String get editorVisible => 'Visible';

  @override
  String get editorHidden => 'Hidden';

  @override
  String get editorSignatureNameSize => 'Name size';

  @override
  String get editorSignatureRoleSize => 'Role size';

  @override
  String get editorSignatureSpacing => 'Spacing';

  @override
  String get editorSignatureImageSize => 'Image size';

  @override
  String get editorSignatureNameColor => 'Name colour';

  @override
  String get editorSignatureRoleColor => 'Role colour';

  @override
  String get editorFont => 'Font';

  @override
  String get editorImageSource => 'Image source';

  @override
  String get imageSourceAppAssets => 'App assets';

  @override
  String get imageSourceMyLibrary => 'My asset library';

  @override
  String get imageSourceLocalFile => 'Local file';

  @override
  String get imageSourceEmbedded => 'Embedded data';

  @override
  String get editorSignatureChangeImage => 'Change signature image';

  @override
  String get editorSignatureAddImage => 'Add signature image';

  @override
  String get editorSignatureRemoveImage => 'Remove signature image';

  @override
  String get editorSignaturePickImageTitle =>
      'Pick a signature image from my asset library';

  @override
  String get editorSignatureSlot => 'Slot';

  @override
  String get editorSignatureRoleField => 'Role (e.g. General Manager)';

  @override
  String get editorSignatureNameField =>
      'Signer name (accepts a dynamic field)';

  @override
  String get editorFromMyLibrary => 'From my asset library';

  @override
  String get paletteSignatureBlock => 'Signatures';

  @override
  String get editorInsertFromLibraryTooltip =>
      'Insert an uploaded frame or logo directly';

  @override
  String get unsupportedElementVersionNote =>
      'This element is from a newer editor version — it is kept as is and cannot be edited here.';

  @override
  String editorSelectedCount(Object count) {
    return '$count selected';
  }

  @override
  String get editorClearSelection => 'Clear selection';

  @override
  String get editorGroup => 'Group';

  @override
  String get editorOpacity => 'Opacity';

  @override
  String get editorBringToFront => 'Bring to front';

  @override
  String get editorSendToBack => 'Send to back';

  @override
  String get editorDuplicate => 'Duplicate';

  @override
  String get editorDeleteSelected => 'Delete selected';

  @override
  String get editorGroupDragHint =>
      'Drag the group with the mouse, use the arrows for fine nudging (Shift = 10px), and Ctrl + click to adjust the selection.';

  @override
  String get editorBringForward => 'Bring forward';

  @override
  String get editorDuplicateElement => 'Duplicate element';

  @override
  String get editorDeleteElement => 'Delete element';

  @override
  String get editorPageSettings => 'Page settings';

  @override
  String get editorPageSize => 'Size';

  @override
  String get editorUnit => 'Unit';

  @override
  String get editorWidth => 'Width';

  @override
  String get editorHeight => 'Height';

  @override
  String get editorLabelText => 'Text';

  @override
  String get editorLabelShape => 'Shape';

  @override
  String get editorLabelSeal => 'Seal';

  @override
  String get editorLabelDecoration => 'Vector decoration';

  @override
  String get editorLabelSignature => 'Signature block';

  @override
  String get editorLabelImage => 'Image / logo';

  @override
  String get editorLabelQr => 'QR code';

  @override
  String get editorLabelUnknown => 'Unsupported element';

  @override
  String get editorLabelDynamicField => 'Dynamic field';

  @override
  String get editorPositionAndSize => 'Position and size';

  @override
  String get editorPosX => 'X';

  @override
  String get editorPosY => 'Y';

  @override
  String get editorRotation => 'Rotation';

  @override
  String get editorTextFormat => 'Text formatting';

  @override
  String get editorConvertToField => 'Convert to dynamic field';

  @override
  String get editorFontWeight => 'Weight';

  @override
  String get editorWeightRegular => 'Regular';

  @override
  String get editorWeightSemiBold => 'Medium';

  @override
  String get editorWeightBold => 'Bold';

  @override
  String get editorFontSize => 'Font size';

  @override
  String get editorLetterSpacing => 'Letter spacing';

  @override
  String get editorLineHeight => 'Line height';

  @override
  String get editorTextColor => 'Text colour';

  @override
  String get editorTextBackground => 'Text background';

  @override
  String get editorTextAlign => 'Alignment';

  @override
  String get editorAlignJustify => 'Justify';

  @override
  String get editorJustifyMode => 'Justification method';

  @override
  String get editorJustifyHint =>
      'Kashida is applied in the PDF file (the preview shows space justification)';

  @override
  String get editorJustifySpaces => 'Spaces';

  @override
  String get editorJustifyKashida => 'Kashida';

  @override
  String get editorVerticalAlign => 'Vertical alignment';

  @override
  String get editorVerticalTop => 'Top';

  @override
  String get editorVerticalBottom => 'Bottom';

  @override
  String get editorDirection => 'Direction';

  @override
  String get editorDirectionHint => 'Toggle shortcut: Ctrl+Shift+D';

  @override
  String get editorDirectionRtl => 'Arabic (RTL)';

  @override
  String get editorDirectionLtr => 'Latin (LTR)';

  @override
  String get editorImage => 'Image';

  @override
  String get editorSource => 'Source';

  @override
  String get editorImageFit => 'Image fit';

  @override
  String get editorFitContain => 'Contain';

  @override
  String get editorFitCover => 'Cover';

  @override
  String get editorFitFill => 'Fill';

  @override
  String get assetPickerEmptyHint =>
      'You haven’t uploaded any assets yet. Upload a logo, signature or seal to use it here and in printing.';

  @override
  String get assetPickerNoneOption => 'None (other source)';

  @override
  String get assetPickerTitle => 'Pick an image from my asset library';

  @override
  String assetUploadType(Object type) {
    return 'Upload $type';
  }

  @override
  String get editorSeal => 'Seal';

  @override
  String get editorSealColor => 'Seal colour';

  @override
  String get editorSealRingColor => 'Ring colour';

  @override
  String get editorSealStarColor => 'Star colour';

  @override
  String get editorSealStarSize => 'Star size';

  @override
  String get editorShape => 'Shape';

  @override
  String get editorFillColor => 'Fill colour';

  @override
  String get editorBorderColor => 'Border colour';

  @override
  String get editorBorderWidth => 'Border width';

  @override
  String get editorCornerRadius => 'Corner radius';

  @override
  String get editorQrVerify => 'Verification code';

  @override
  String get editorQrData => 'Code data';

  @override
  String get editorQrColor => 'Code colour';

  @override
  String get editorQrBackground => 'Code background';

  @override
  String editorConvertDialogMessage(Object text) {
    return 'The conversion turns the text “$text” into a dynamic marker that can be bound in batch generation.';
  }

  @override
  String get editorFieldKeyHint => 'Field key (e.g. name, date, reference)';

  @override
  String get editorCustomKeyHint =>
      'Enter a custom key (without braces — it will be added automatically)';

  @override
  String get editorCancel => 'Cancel';

  @override
  String get editorConvert => 'Convert';

  @override
  String get editorPath => 'Path';

  @override
  String get editorTextContent => 'Text content';

  @override
  String editorInsertFieldToken(Object token) {
    return 'Insert $token';
  }

  @override
  String editorAddLabel(Object label) {
    return 'Add $label';
  }

  @override
  String assetInsertedSnack(Object name) {
    return '“$name” was inserted into the template.';
  }

  @override
  String get paletteHeading => 'Heading';

  @override
  String get paletteFrame => 'Rectangle / frame';

  @override
  String get paletteDivider => 'Divider';

  @override
  String get paletteLogo => 'Logo / signature';
}
