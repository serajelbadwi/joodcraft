// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get editorDone => 'Done';

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
  String get actionOpenMenu => 'Menu';

  @override
  String get editorFitToScreen => 'Fit to screen';

  @override
  String get editorNewTemplate => 'New template';

  @override
  String get editorNewConfirm =>
      'A new template will start from the default design; unsaved changes remain in the undo history. Continue?';

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
  String get destBrand => 'Brand & Profile';

  @override
  String get destBrandDesc => 'Your logo, seals, signatures and brand colors.';

  @override
  String get brandTitle => 'Brand & Profile Settings';

  @override
  String get brandTabVisuals => 'Visual identity';

  @override
  String get brandTabText => 'Text data';

  @override
  String get brandTabColors => 'Colors & fonts';

  @override
  String get brandTabPreview => 'Identity preview';

  @override
  String get brandPrimaryLogo => 'Primary logo';

  @override
  String get brandWatermarkLogo => 'Watermark logo';

  @override
  String get brandSeals => 'Official seals';

  @override
  String get brandAddSeal => 'Add seal';

  @override
  String get brandSealName => 'Seal name';

  @override
  String get brandSignatures => 'Authorized signatures';

  @override
  String get brandAddSignature => 'Add signature';

  @override
  String get brandSignatureName => 'Signer name';

  @override
  String get brandSignatureTitle => 'Job title';

  @override
  String get brandRemove => 'Remove';

  @override
  String get brandNoSeals => 'No seals added yet.';

  @override
  String get brandNoSignatures => 'No signatures added yet.';

  @override
  String get brandOrgNameAr => 'Organization name (Arabic)';

  @override
  String get brandOrgNameEn => 'Organization name (English)';

  @override
  String get brandHeaderText => 'Header text';

  @override
  String get brandFooterText => 'Footer text';

  @override
  String get brandRegNumber => 'Tax / registration number';

  @override
  String get brandPrimaryColor => 'Primary color';

  @override
  String get brandSecondaryColor => 'Secondary color';

  @override
  String get brandAccentColor => 'Accent color';

  @override
  String get brandHeaderFont => 'Heading font';

  @override
  String get brandBodyFont => 'Body font';

  @override
  String get brandClear => 'Clear brand';

  @override
  String get brandClearConfirm =>
      'All saved brand content will be deleted. Continue?';

  @override
  String get brandSaved => 'Brand saved.';

  @override
  String get brandPresets => 'Brand presets';

  @override
  String get brandInsertHeader => 'Insert standard header';

  @override
  String get brandInsertFooter => 'Insert standard footer';

  @override
  String get brandApplyColors => 'Apply brand colors';

  @override
  String get brandQuickSeals => 'Seals';

  @override
  String get brandQuickSignatures => 'Signatures';

  @override
  String get brandNoBrand => 'Your brand isn\'t set up yet.';

  @override
  String get brandOpenSettings => 'Open brand settings';

  @override
  String get brandHeaderInserted => 'Standard header inserted.';

  @override
  String get brandFooterInserted => 'Standard footer inserted.';

  @override
  String get brandColorsApplied => 'Brand colors applied.';

  @override
  String get brandSealInserted => 'Seal inserted.';

  @override
  String get brandSignatureInserted => 'Signature inserted.';

  @override
  String get brandFontDefault => 'Default';

  @override
  String get paletteShapes => 'Shapes';

  @override
  String get paletteRoundedRect => 'Rounded rectangle';

  @override
  String get paletteEllipse => 'Circle / ellipse';

  @override
  String get editorFillOpacity => 'Fill opacity';

  @override
  String get editorCollapsePanel => 'Collapse side panel';

  @override
  String get editorExpandPanel => 'Show side panel';

  @override
  String get editorCustomSize => 'Custom size';

  @override
  String get editorStandardSize => 'Standard size';

  @override
  String get editorBackgroundTitle => 'Sheet background';

  @override
  String get editorGradientFrom => 'From';

  @override
  String get editorGradientTo => 'To';

  @override
  String get editorGradientDirection => 'Direction';

  @override
  String get editorGradientNone => 'No gradient';

  @override
  String get editorGradientVertical => 'Vertical';

  @override
  String get editorGradientHorizontal => 'Horizontal';

  @override
  String get editorGradientDiagonal => 'Diagonal';

  @override
  String get editorLayersTitle => 'Layers';

  @override
  String get editorLayerShow => 'Show element';

  @override
  String get editorLayerHide => 'Hide element';

  @override
  String get editorLayerLock => 'Lock element';

  @override
  String get editorLayerUnlock => 'Unlock element';

  @override
  String get editorLayersEmpty => 'No elements on this page yet.';

  @override
  String get editorGroupSelected => 'Group selection';

  @override
  String get editorUngroupSelected => 'Ungroup';

  @override
  String get editorAlignLeft => 'Align left';

  @override
  String get editorAlignCenterH => 'Center horizontally';

  @override
  String get editorAlignRight => 'Align right';

  @override
  String get editorAlignTop => 'Align top';

  @override
  String get editorAlignCenterV => 'Center vertically';

  @override
  String get editorAlignBottom => 'Align bottom';

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
  String get editorImageTint => 'Image tint';

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

  @override
  String get evSignatureEmptyLabel => 'Empty signature';

  @override
  String get evSignatureEmptyDetail =>
      'Add a role, a name and a signature image';

  @override
  String get evSignatureMissingLabel => 'Missing signature';

  @override
  String get evUploadToLibraryDetail => 'Upload the image to the asset library';

  @override
  String get evImageNotFoundLabel => 'Image not found';

  @override
  String get evNoFileLabel => 'No file selected';

  @override
  String get evChooseFromAssetsDetail =>
      'Choose an image from the asset library';

  @override
  String get evAssetMissingLabel => 'Missing asset';

  @override
  String get evReselectAssetDetail =>
      'Re-select the frame/asset from the library';

  @override
  String get evInvalidImageLabel => 'Invalid image';

  @override
  String get evRenderDataFailedDetail => 'Unable to display the data';

  @override
  String get evInvalidDataLabel => 'Invalid data';

  @override
  String get evDecodeFailedDetail => 'Unable to decode the image';

  @override
  String get evEmptyQrLabel => 'Empty code';

  @override
  String get evEmptyQrDetail => 'Enter the code value in the properties bar';

  @override
  String evUnknownElementLabel(Object type) {
    return 'Unsupported element: $type';
  }

  @override
  String get alpFilterAll => 'All';

  @override
  String get alpEmptyHint =>
      'No uploaded assets of the required types. Upload a frame or logo from the “Assets & signatures” section, then try again.';

  @override
  String alpNoFilteredAssets(Object type) {
    return 'No assets of type “$type”.';
  }

  @override
  String get authWelcomeBack => 'Welcome to JoodCraft.';

  @override
  String get authResetLinkSent =>
      'The reset link has been sent. Check your email.';

  @override
  String get authLogin => 'Sign in';

  @override
  String get authLoginSubtitle =>
      'Your email and password to continue to the dashboard.';

  @override
  String get authNoAccount => 'Don’t have an account?';

  @override
  String get authCreateAccountLink => 'Create a new account';

  @override
  String get authConfirmEmailThenLogin =>
      'Your account has been created. Please confirm your email first, then sign in.';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authForgotPassword => 'Forgot your password?';

  @override
  String get authEnterDashboard => 'Enter the dashboard';

  @override
  String get authResetPassword => 'Reset password';

  @override
  String get authResetPasswordHint =>
      'Enter your email and we’ll send you a password reset link.';

  @override
  String get authSendLink => 'Send link';

  @override
  String get authConfirmEmailMessage =>
      'Your account has been created. Check your email to confirm it, then sign in.';

  @override
  String get authAccountCreatedWelcome =>
      'Your account has been created. Welcome to JoodCraft.';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authRegisterSubtitle =>
      'Your account saves your templates and assets (logo, signature, seal) to reuse across all your projects.';

  @override
  String get authHaveAccount => 'Already have an account?';

  @override
  String get authFullName => 'Full name';

  @override
  String get authFullNameHint => 'e.g. Abdullah Al-Ahmad';

  @override
  String get authName => 'Name';

  @override
  String get authOrgName => 'Organisation name (optional)';

  @override
  String get authOrgNameHint => 'e.g. Jood Charity Association';

  @override
  String get authOrgHelper =>
      'Printed automatically on certificates and contracts.';

  @override
  String get authOrgNameShort => 'Organisation name';

  @override
  String get authPasswordHint => 'At least 8 characters';

  @override
  String authPasswordRule(Object min) {
    return 'Use $min characters or more with numbers and symbols.';
  }

  @override
  String get authConfirmPassword => 'Confirm password';

  @override
  String get authCreateAccountButton => 'Create the account';

  @override
  String get authFeatureLocalExcel =>
      'Full local processing of Excel files — your data never leaves your device';

  @override
  String get authFeaturePdf =>
      'PDF generation with high-quality Arabic fonts and full RTL support';

  @override
  String get authFeatureTemplates =>
      'Your templates are saved in your account and ready to reuse';

  @override
  String get authTagline =>
      'Your official certificates and contracts… printed with confidence.';

  @override
  String authVersion(Object name, Object version) {
    return '$name • Version $version';
  }

  @override
  String get dashModules => 'Platform modules';

  @override
  String dashWelcome(Object name) {
    return 'Welcome, $name';
  }

  @override
  String dashSubscription(Object tier) {
    return 'Subscription: $tier';
  }

  @override
  String dashOrg(Object name) {
    return 'Organisation: $name';
  }

  @override
  String get dashOrgMissing =>
      'You haven’t set your organisation name yet — it will be printed automatically on certificates and contracts.';

  @override
  String get dashOpenModule => 'Open the module';

  @override
  String get destDashboard => 'Dashboard';

  @override
  String get destDashboardDesc => 'An overview of your projects and templates.';

  @override
  String get destCertificates => 'Certificate engine';

  @override
  String get destCertificatesDesc =>
      'Design landscape certificates from an editable template.';

  @override
  String get destContracts => 'Contract engine';

  @override
  String get destContractsDesc =>
      'Draft portrait contracts with dynamic fields.';

  @override
  String get destBatch => 'Batch generation';

  @override
  String get destBatchDesc =>
      'Read an Excel file locally and generate hundreds of certificates at once.';

  @override
  String get destTemplates => 'Template library';

  @override
  String get destTemplatesDesc =>
      'Manage, organise and reuse your saved templates.';

  @override
  String get destAssets => 'Assets & signatures';

  @override
  String get destAssetsDesc => 'Your logo, seal, signature and frames.';

  @override
  String get dashUser => 'User';

  @override
  String get dashLogoutSuccess => 'You have signed out successfully.';

  @override
  String get dashLogoutError => 'Couldn’t sign out. Please try again.';

  @override
  String get commonSave => 'Save';

  @override
  String get commonPreview => 'Preview';

  @override
  String get commonOptions => 'Options';

  @override
  String get tplDelete => 'Delete';

  @override
  String get tplSortRecentlyUpdated => 'Recently updated';

  @override
  String get tplSortTitleAsc => 'Name (A–Z)';

  @override
  String get tplSortLabel => 'Sort';

  @override
  String get tplSubtitle =>
      'Professional ready-made templates + your saved ones — search, filter, open and import, fully offline.';

  @override
  String get tplRefreshTooltip => 'Refresh the list';

  @override
  String get tplSearchHint => 'Search templates…';

  @override
  String get tplNoResultsTitle => 'No matching results';

  @override
  String get tplNoResultsMessage =>
      'Try another search term or reset the filter.';

  @override
  String tplAddedToLocal(Object title) {
    return '“$title” was added to your local templates.';
  }

  @override
  String get tplCloudRequiresConnection =>
      'Saving templates to the cloud requires a connection to a Supabase project. Save it locally instead.';

  @override
  String tplSavedToCloud(Object title) {
    return '“$title” was saved to the cloud.';
  }

  @override
  String get tplRenamed => 'The template was renamed.';

  @override
  String tplCopySuffix(Object title) {
    return '$title (copy)';
  }

  @override
  String tplCopyCreated(Object title) {
    return 'A copy of “$title” was created.';
  }

  @override
  String get tplNowPrivate => 'The template is now private.';

  @override
  String get tplNowPublic =>
      'The template is now public (read-only for others).';

  @override
  String tplConfirmCloudDelete(Object title) {
    return '“$title” will be permanently deleted from the cloud. This cannot be undone.';
  }

  @override
  String tplCloudDeleted(Object title) {
    return 'The template “$title” was deleted.';
  }

  @override
  String tplConfirmLocalDelete(Object title) {
    return '“$title” will be deleted from this device. The original ready-made template remains available in the library.';
  }

  @override
  String tplLocalDeleted(Object title) {
    return 'The local template “$title” was deleted.';
  }

  @override
  String get tplDeleteTitle => 'Delete template';

  @override
  String get tplRenameTitle => 'Template title';

  @override
  String get tplFieldTitle => 'Title';

  @override
  String tplPreviewLabel(Object title) {
    return 'Preview: $title';
  }

  @override
  String tplCount(Object count) {
    return '$count template(s)';
  }

  @override
  String tplCloudLoadError(Object message) {
    return 'Couldn’t load cloud templates: $message';
  }

  @override
  String get tplPublicBadge => 'Public template';

  @override
  String get tplOrientationLandscape => 'Landscape';

  @override
  String get tplOrientationPortrait => 'Portrait';

  @override
  String get tplPresetOffline => 'Ready-made template • available offline';

  @override
  String tplSchemaVersion(Object version) {
    return 'Schema v$version';
  }

  @override
  String get tplOpenAsTemplate => 'Open as template';

  @override
  String get tplOpen => 'Open';

  @override
  String get tplUseInBatch => 'Use in batch generation';

  @override
  String get tplImportLocal => 'Import locally';

  @override
  String get tplSaveToCloud => 'Save to the cloud';

  @override
  String get tplDeleteLocal => 'Delete locally';

  @override
  String get tplRename => 'Rename';

  @override
  String get tplMakePrivate => 'Make it private';

  @override
  String get tplMakePublic => 'Make it public';

  @override
  String get tplNoDate => 'No date';

  @override
  String get amSubtitle =>
      'Upload your logo, seal and signature once, then insert them into any template — saved on your device and reused offline.';

  @override
  String get amSearchHint => 'Search assets…';

  @override
  String get amTypeLabel => 'Type';

  @override
  String get amUploadTooltip => 'Upload a new asset';

  @override
  String get amUpload => 'Upload asset';

  @override
  String get amEmptyTitle => 'No assets yet';

  @override
  String get amEmptyMessage =>
      'Upload your organisation’s logo, signature or seal, then insert it into any template from the image properties bar.';

  @override
  String get amNoResultsMessage => 'Try another name or reset the filter.';

  @override
  String get amRenamed => 'The asset was renamed.';

  @override
  String amMovedToType(Object type) {
    return 'The asset was moved to “$type”.';
  }

  @override
  String get amDeleteTitle => 'Delete asset';

  @override
  String amConfirmDelete(Object name) {
    return '“$name” will be deleted from this device. Templates using it will lose the image (without printing failure).';
  }

  @override
  String amDeleted(Object name) {
    return 'The asset “$name” was deleted.';
  }

  @override
  String get amRenameTitle => 'Rename asset';

  @override
  String amCount(Object count) {
    return '$count asset(s)';
  }

  @override
  String amMakeType(Object type) {
    return 'Make type: $type';
  }

  @override
  String get amCacheLabel => 'Image cache on disk';

  @override
  String amCacheUsage(Object count, Object size) {
    return '$count file(s) · $size';
  }

  @override
  String amCacheUsageOf(Object count, Object used, Object limit) {
    return '$count file(s) · $used of $limit';
  }

  @override
  String get amCacheEmpty => 'No disk cache yet';

  @override
  String get amCacheClear => 'Clear cache';

  @override
  String get amCacheCleared => 'Disk image cache cleared.';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonPrint => 'Print';

  @override
  String get commonExportPdf => 'Export PDF';

  @override
  String get commonExportFailed => 'Couldn’t export the PDF file.';

  @override
  String get commonPrintFailed => 'Couldn’t send the file to the printer.';

  @override
  String commonExportReady(Object name) {
    return 'The file is ready to save as $name.';
  }

  @override
  String get commonGenerating => 'Generating…';

  @override
  String get commonDataPanelTitle => 'Sample data';

  @override
  String evElementCount(Object count) {
    return '$count element(s)';
  }

  @override
  String get evStatusDynamicFields => ' • dynamic fields';

  @override
  String get evStatusUnsaved => ' • unsaved changes';

  @override
  String get tevNewTemplateTitle => 'New template';

  @override
  String get tevUnsavedTitle => 'Unsaved changes';

  @override
  String tevUnsavedMessage(Object title) {
    return 'You have unsaved changes to “$title”. Do you want to save them before leaving?';
  }

  @override
  String get tevLeaveWithoutSaving => 'Leave without saving';

  @override
  String get tevSaveAndLeave => 'Save and leave';

  @override
  String get tevViewMode => 'View mode';

  @override
  String get tevModeEditor => 'Editor';

  @override
  String get tevModePreview => 'PDF preview';

  @override
  String get tevPaperDirection => 'Paper orientation';

  @override
  String get tevWidthCm => 'Width (cm)';

  @override
  String get tevHeightCm => 'Height (cm)';

  @override
  String get tevUndo => 'Undo (Ctrl+Z)';

  @override
  String get tevRedo => 'Redo (Ctrl+Y)';

  @override
  String get tevSnapGrid => 'Snap grid';

  @override
  String get tevGuidesOn => 'Smart guides: on (turn off)';

  @override
  String get tevGuidesOff => 'Smart guides: off (turn on)';

  @override
  String get tevZoom => 'Zoom';

  @override
  String get tevDocumentBackground => 'Document background';

  @override
  String get tevFrameFromLibrary => 'Frame from my asset library';

  @override
  String get tevChangeTitle => 'Change template title';

  @override
  String get tevMyTemplates => 'My templates';

  @override
  String get tevSaveAs => 'Save as';

  @override
  String get tevSaveTemplate => 'Save template';

  @override
  String get tevSaveUnavailable => 'Saving unavailable';

  @override
  String get tevSaveNeedsSupabase =>
      'Local saving is unavailable in this session — the projects store could not be opened on this device.';

  @override
  String tevMissingAssets(Object list) {
    return 'Missing assets: $list — re-select the frame/asset from “My asset library” to avoid blanks.';
  }

  @override
  String get tevTemplateLibraryNeedsSupabase =>
      'The local projects library is unavailable in this session.';

  @override
  String tevOpenedTemplate(Object title) {
    return '“$title” was opened.';
  }

  @override
  String get tevTitleHint =>
      'e.g. Project Management course completion certificate';

  @override
  String get tevContinue => 'Continue';

  @override
  String get tevSavedTemplates => 'My saved templates';

  @override
  String get tevNoSavedTemplates =>
      'No saved templates yet. Save one from the “Save template” button.';

  @override
  String get ecIncrease => 'Increase';

  @override
  String get ecDecrease => 'Decrease';

  @override
  String get ecQuickPalette => 'Quick palette';

  @override
  String get ecFullPicker => 'Full colour picker';

  @override
  String get ecRemoveColor => 'Remove colour';

  @override
  String get ecNone => 'None';

  @override
  String get ecPickColorTitle => 'Pick a colour';

  @override
  String get ecApply => 'Apply';

  @override
  String tevBackgroundAdded(Object name) {
    return '“$name” was added as the document background.';
  }

  @override
  String get cfpUploadTooltip => 'Upload a custom font (.ttf / .otf)';

  @override
  String get cfpManageTooltip => 'Manage uploaded fonts';

  @override
  String get cfpNotice =>
      'Uploaded fonts are saved on your device only and used immediately here and in printing — without internet.';

  @override
  String get cfpMyFonts => 'My custom fonts';

  @override
  String get cfpNoFonts => 'No fonts uploaded yet';

  @override
  String get cfpBuiltinOption => 'None (built-in font)';

  @override
  String get cfpGroupBuiltin => 'Built-in fonts';

  @override
  String get cfpGroupUploaded => 'My uploaded fonts';

  @override
  String get cfpGroupSystem => 'System fonts';

  @override
  String get cfpSearchHint => 'Search fonts…';

  @override
  String get cfpNoMatch => 'No matching fonts.';

  @override
  String get cfpPickTitle => 'Pick a font file (TTF or OTF)';

  @override
  String cfpPickerError(Object error) {
    return 'Couldn’t open the file picker: $error';
  }

  @override
  String cfpReadError(Object name, Object error) {
    return 'Couldn’t read \"$name\": $error';
  }

  @override
  String get cfpFontAdded => 'The font was added and applied immediately.';

  @override
  String cfpFontsAdded(Object count) {
    return '$count fonts were added.';
  }

  @override
  String get cfpLibraryTitle => 'My custom fonts library';

  @override
  String get cfpLibraryNotice =>
      'All fonts are saved on your device only. Warning: deleting a font used by a template reverts that template to the built-in font instead of failing.';

  @override
  String get cfpEmpty => 'No uploaded fonts yet.';

  @override
  String get cfpCoverageFull => 'Full Arabic coverage';

  @override
  String get cfpCoveragePartial => 'Partial Arabic coverage';

  @override
  String get cfpUploadNew => 'Upload a new font';

  @override
  String get ptpPrepError =>
      'Couldn’t prepare the preview. Check the template file.';

  @override
  String ptpElapsedSize(Object ms, Object kb) {
    return '$ms ms — $kb KB';
  }

  @override
  String get ptpGeneratingNote => '— the preview updates automatically';

  @override
  String get ptpGenerateFailedTitle => 'Couldn’t generate the preview';

  @override
  String get ptpPreparingTitle => 'Preparing the engine…';

  @override
  String get ptpPreparingMessage =>
      'Bundled fonts are being loaded and the first file version generated.';

  @override
  String get ptpShowFailedTitle => 'Couldn’t display the preview';

  @override
  String cfgOverride(Object override) {
    return 'An alternative build with explicit values overrides the file: $override';
  }

  @override
  String get tevBackgroundTitle => 'Document background from my asset library';

  @override
  String get tevAddElement => 'Add element';

  @override
  String get commonUndo => 'Undo';

  @override
  String get bpTitle => 'Batch generation from Excel';

  @override
  String get bpSubtitle =>
      'Import an .xlsx or .csv file, map its columns to template fields, then generate a PDF with a page per record — all on your device, offline.';

  @override
  String get bpStepTemplate => '1) Template';

  @override
  String get bpLoadingSampleTemplate => 'Loading the sample template…';

  @override
  String bpTemplateInfo(Object name) {
    return 'Template: $name • required fields:';
  }

  @override
  String get bpLoadingTemplates => 'Loading your templates…';

  @override
  String get bpNoTemplates =>
      'No saved templates yet — create one in the editor or import it from the template library to show it here.';

  @override
  String get bpTemplateFromMine => 'Template from my templates';

  @override
  String get bpSampleTemplatesHeader => '— sample templates —';

  @override
  String bpTemplateEntry(Object title, Object source) {
    return '$title  •  $source';
  }

  @override
  String get bpSourceCloud => 'Cloud';

  @override
  String get bpSourceLocal => 'Local';

  @override
  String get bpStepDataFile => '2) Data file';

  @override
  String get bpReadingFile => 'Reading the file…';

  @override
  String get bpNoFileChosen => 'No file chosen yet — supported formats:';

  @override
  String bpFileSummary(Object name, Object rows, Object cols) {
    return '$name — $rows rows, $cols columns';
  }

  @override
  String bpSheetSuffix(Object name) {
    return ' (sheet: $name)';
  }

  @override
  String get bpChooseFile => 'Choose file';

  @override
  String get bpRemove => 'Remove';

  @override
  String get bpHeaderRow => 'Header row';

  @override
  String bpAutoRow(Object n) {
    return 'Automatic (row $n)';
  }

  @override
  String bpRow(Object n) {
    return 'Row $n';
  }

  @override
  String bpAutoRowLong(Object n) {
    return 'Automatic — row $n';
  }

  @override
  String bpRowPreview(Object n, Object preview) {
    return 'Row $n: $preview';
  }

  @override
  String get bpEmptyRow => '(empty row)';

  @override
  String get bpWorksheet => 'Worksheet';

  @override
  String get bpPickDataFile => 'Choose the data file (Excel or CSV)';

  @override
  String bpReadFileError(Object error) {
    return 'Couldn’t read the file: $error';
  }

  @override
  String bpFileReadRows(Object rows, Object cols) {
    return 'The file was read locally: $rows rows and $cols columns.';
  }

  @override
  String bpSaveError(Object error) {
    return 'Couldn’t save the change to the template: $error';
  }

  @override
  String get bpMapFieldTitle => 'Assign a dynamic field to this element';

  @override
  String get bpMapFieldBody =>
      'Only this element’s text will be replaced by a field; no other element is affected.';

  @override
  String get bpUndoConvert => 'The conversion was undone.';

  @override
  String get bpUndoConvertSaved =>
      'The conversion was undone and the text restored in the template.';

  @override
  String bpRestoreError(Object error) {
    return 'Couldn’t restore the text in the template: $error';
  }

  @override
  String bpGeneratedReport(Object count) {
    return 'Generated $count record(s)';
  }

  @override
  String bpSkippedSuffix(Object count) {
    return ' and skipped $count';
  }

  @override
  String get bpReadyToSave => 'The file is ready to save.';

  @override
  String get bpStepMapping => '3) Map columns to fields';

  @override
  String get bpChooseFileFirst =>
      'Choose a file first to show the mapping table.';

  @override
  String get bpNoDynamicFields => 'No dynamic fields in the current template.';

  @override
  String bpMappedCount(Object mapped, Object total) {
    return 'Mapped $mapped of $total columns';
  }

  @override
  String get bpAutoMapHint =>
      'After choosing the file, a smart auto-mapping is suggested; you can edit each column.';

  @override
  String get bpNoFieldsHelp =>
      'The chosen template has no dynamic fields, so there is nothing to map to the file columns. Open the template in the editor, insert a “dynamic field” in the name slot, save the template, then try again.';

  @override
  String get bpAutoMap => 'Auto-map';

  @override
  String get bpClearMapping => 'Clear mapping';

  @override
  String get bpNameFieldWarning =>
      'This template has no dynamic name field — don’t map the name column to a date or reference field, or the name may print in the wrong place. Pick the name key from the column list, or convert the fixed name text in the editor into a dynamic field.';

  @override
  String bpStaticNameHints(Object preview) {
    return 'Fixed text that looks like a name: “$preview” — no dynamic field replaces it.';
  }

  @override
  String get bpConvertToNameField => 'Convert it to a trainee-name field';

  @override
  String bpDuplicateField(Object field) {
    return 'The field “$field” is mapped to more than one column. Map each field to one column.';
  }

  @override
  String bpUnmappedColumns(Object count) {
    return '$count unmapped column(s) — their data won’t be used in the certificates.';
  }

  @override
  String bpColumn(Object n) {
    return 'Column $n';
  }

  @override
  String get bpEmptyCell => '(empty)';

  @override
  String get bpUnmapped => '— unmapped —';

  @override
  String get bpStepMissing => '4) Empty cells and missing data';

  @override
  String get bpNoNotes => 'No notes before choosing the file.';

  @override
  String get bpStepGenerate => '5) Generate';

  @override
  String bpGenerating(Object progress) {
    return 'Generating… $progress';
  }

  @override
  String get bpGenerateHint => 'One PDF file, a page per generated record.';

  @override
  String get bpGeneratePickFile =>
      'Choose a data file first to enable generation.';

  @override
  String get bpMappingInvalid =>
      'The mapping is invalid — the same field is mapped to two columns.';

  @override
  String get bpMapAtLeastOne =>
      'Map at least one column to a template field to enable generation.';

  @override
  String get bpGenerateCertificates => 'Generate certificates';

  @override
  String get bpRegenerate => 'Regenerate';

  @override
  String get bpStatGenerated => 'Generated';

  @override
  String get bpStatSkipped => 'Skipped';

  @override
  String get bpStatPages => 'Pages';

  @override
  String get bpStatSize => 'Size';

  @override
  String bpKilobytes(Object value) {
    return '$value KB';
  }

  @override
  String get bpStatTime => 'Time';

  @override
  String bpMilliseconds(Object value) {
    return '$value ms';
  }

  @override
  String bpCompletion(Object pct, Object total) {
    return '$pct% complete of $total rows.';
  }

  @override
  String get bpSkippedRows => 'Rows not generated:';

  @override
  String bpRowSkipReason(Object n, Object reason) {
    return 'Row $n: $reason';
  }

  @override
  String get bpPreviewHere => 'The preview appears here';

  @override
  String get bpPreviewHint =>
      'Choose the data file, adjust the mapping, then press “Generate certificates” — you’ll see the first page of the generated file here directly.';

  @override
  String get bpAssignByTapTitle => 'Assign fields by tapping';

  @override
  String get bpAssignByTapBody =>
      'Tap any text in the template to assign it to a dynamic field yourself. No other element is affected — not the date, the manager name, or any fixed text.';

  @override
  String get bpNoTexts => 'No texts in this template.';

  @override
  String get bpEmptyText => '(empty text)';

  @override
  String get bpDynamicFieldTap => 'Dynamic field — tap to change';

  @override
  String get bpStaticTextTap => 'Fixed text — tap to assign';

  @override
  String get bpAssignField => 'Assign field';

  @override
  String get bpKindCertificate => 'Certificate';

  @override
  String get bpKindContract => 'Contract';

  @override
  String bpLoadSampleError(Object error) {
    return 'Couldn’t load the sample template: $error';
  }

  @override
  String bpReadSheetError(Object error) {
    return 'Couldn’t read the sheet: $error';
  }

  @override
  String bpUpdateHeaderRowError(Object error) {
    return 'Couldn’t update the header row: $error';
  }

  @override
  String get bpChooseTemplateFirst =>
      'Choose a template (certificate or contract) before generating.';

  @override
  String bpBatchTitle(Object kind) {
    return '$kind batch — JoodCraft';
  }

  @override
  String bpGenerateError(Object error) {
    return 'Couldn’t run batch generation: $error';
  }

  @override
  String get bpWarnNoDynamicFields =>
      'This template has no dynamic fields — data won’t change between records. Add a “trainee name” field from the editor toolbar, then save the template.';

  @override
  String get bpWarnNoNameField =>
      'This template has no dynamic name field — the name column may map to a date or reference field and the name prints in the wrong place. Convert the fixed name text into a field or redesign the template.';

  @override
  String bpAssignedTemp(Object token) {
    return 'This element was assigned to $token for the current generation — the other elements are untouched. Save the template to keep the change permanently.';
  }

  @override
  String bpAssignedSaved(Object token) {
    return 'This element was assigned to $token and the change was saved to the template. The other elements are untouched.';
  }

  @override
  String get commonShow => 'Show';

  @override
  String get commonHide => 'Hide';

  @override
  String get themeSwitchToLight => 'Switch to light theme';

  @override
  String get themeSwitchToDark => 'Switch to dark theme';

  @override
  String commonComingSoonPhase(Object phase) {
    return 'In progress — phase $phase';
  }

  @override
  String get cbNewCertificateTitle => 'New certificate';

  @override
  String get cbNewContractTitle => 'New contract';

  @override
  String get cbBeneficiaryDataTitle => 'Beneficiary data (sample)';

  @override
  String get cbContractDataTitle => 'Contract data (sample)';

  @override
  String get editorSendBackward => 'Send backward';

  @override
  String get editorRotateLeft => 'Rotate 90° left';

  @override
  String get editorRotateRight => 'Rotate 90° right';

  @override
  String get editorFlipH => 'Flip horizontal';

  @override
  String get editorFlipV => 'Flip vertical';

  @override
  String get editorTransform => 'Transform';

  @override
  String get editorToolSelect => 'Select';

  @override
  String get editorToolShapes => 'Shapes';

  @override
  String get editorFillType => 'Fill type';

  @override
  String get editorFillSolid => 'Solid';

  @override
  String get editorGradientLinear => 'Linear gradient';

  @override
  String get editorGradientRadial => 'Radial gradient';

  @override
  String get editorGradientAngle => 'Gradient angle';

  @override
  String get editorShadowEnable => 'Add shadow';

  @override
  String get editorShadowColor => 'Shadow color';

  @override
  String get editorShadowBlur => 'Shadow blur';

  @override
  String get editorShadowOffsetX => 'Offset X';

  @override
  String get editorShadowOffsetY => 'Offset Y';

  @override
  String get editorShadowSpread => 'Spread';

  @override
  String get editorShadowRemove => 'Remove shadow';

  @override
  String get editorPoints => 'Points';

  @override
  String get editorInnerRadius => 'Inner radius';

  @override
  String get editorCornerTopLeft => 'Top-left';

  @override
  String get editorCornerTopRight => 'Top-right';

  @override
  String get editorCornerBottomRight => 'Bottom-right';

  @override
  String get editorCornerBottomLeft => 'Bottom-left';

  @override
  String get editorDashPattern => 'Dash pattern';

  @override
  String get editorBooleanOps => 'Boolean operations';

  @override
  String get editorBooleanUnion => 'Union';

  @override
  String get editorBooleanSubtract => 'Subtract';

  @override
  String get editorBooleanIntersect => 'Intersect';

  @override
  String get editorBooleanUngroup => 'Separate compound';

  @override
  String get paletteStar => 'Star';

  @override
  String get palettePolygon => 'Polygon';

  @override
  String get editorBooleanExclude => 'Exclude';

  @override
  String get editorBooleanHint =>
      'The merged path is a single Boolean result (no inner borders) and can be separated at any time.';

  @override
  String get editorDockTools => 'Tool panel';

  @override
  String get editorDockAnchor => 'Dock position';

  @override
  String get editorDockTopBar => 'Top bar';

  @override
  String get editorDockInspector => 'Side panel';

  @override
  String get editorDockLeftRail => 'Side rail';

  @override
  String get editorDockFloating => 'Floating';

  @override
  String get editorDockCollapse => 'Collapse tools';

  @override
  String get editorDockExpand => 'Expand tools';

  @override
  String get editorDockResize => 'Drag to resize';

  @override
  String get editorDockDropHint => 'Release to snap to';

  @override
  String get editorMoreTools => 'More tools';

  @override
  String get editorDocumentProperties => 'Document properties';

  @override
  String get editorDockReset => 'Restore default docking';

  @override
  String get editorTextShadow => 'Text shadow';

  @override
  String get editorTextShadowAdd => 'Add text shadow';

  @override
  String get editorShadowOpacity => 'Shadow opacity';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderPreviewAutoHint => 'Click to clear the override (automatic)';

  @override
  String get genderPresetCompleted => 'completed (m./f.)';

  @override
  String get genderPresetPassed => 'passed (m./f.)';

  @override
  String get genderPresetForStudent => 'for the student (m./f.)';

  @override
  String get genderPresetStudent => 'the student (m./f.)';

  @override
  String get genderPresetToHim => 'to him / to her';

  @override
  String get genderPresetHonoring => 'the outstanding trainee (m./f.)';

  @override
  String get editorGenderSnippet => 'Insert conditional snippet';

  @override
  String get editorGenderSnippetHint =>
      'Inserts a phrase that switches automatically with the recipient\'s gender.';

  @override
  String get bpGenderReviewTitle => 'Gender review (masculine/feminine)';

  @override
  String get bpGenderReviewSubtitle =>
      'Gender is detected from the name or a \"Gender\" column — fix edge cases before printing.';

  @override
  String get bpGenderRow => 'Row';

  @override
  String get bpGenderDetected => 'Detected';

  @override
  String get bpGenderEffective => 'Applied';

  @override
  String get bpGenderNameColumn => 'Name';

  @override
  String get bpGenderEditName => 'Edit name';

  @override
  String get bpGenderNameHint => 'Type the correct name';

  @override
  String get bpGenderClearOverrides => 'Clear overrides';

  @override
  String get bpGenderOverridden => 'Manually overridden';

  @override
  String get bpGenderUnknownName => '—';

  @override
  String get bpOutputTitle => 'Certificate save destination';

  @override
  String get bpOutputHint =>
      'Choose the folder to save the generated PDF in, or start with the default location.';

  @override
  String get bpOutputPickFolder => 'Choose folder…';

  @override
  String get bpOutputStart => 'Start generation';

  @override
  String get bpOutputPathLabel => 'Selected folder';

  @override
  String get bpOutputNoFolder =>
      'No folder selected — printing and export only.';

  @override
  String get bpOpenFolder => 'Open folder';

  @override
  String get bpOutputSavedTitle => 'PDF file saved';

  @override
  String get bpOpenFolderFailed => 'Could not open the folder.';

  @override
  String get bpOutputNameLabel => 'Export filename';

  @override
  String get bpOutputNameHint => 'Type a name without the extension';

  @override
  String get bpOutputNamePreviewLabel => 'Will be saved as';

  @override
  String get bpOutputModeLabel => 'Save mode';

  @override
  String get bpOutputModeCombined => 'Single combined file';

  @override
  String get bpOutputModeIndividual => 'Separate file per person';

  @override
  String get hubTitle => 'New project';

  @override
  String get hubSubtitle =>
      'Pick a ready-made size or set your own — the canvas opens at the exact size and ratio.';

  @override
  String get hubKindSingle => 'Single-sheet prints and documents';

  @override
  String get hubKindMulti => 'Multi-page books and publications';

  @override
  String get hubKindSingleHint =>
      'One sheet: certificates, contracts, cards, seat numbers, greeting cards.';

  @override
  String get hubKindMultiHint =>
      'Multi-page: book, magazine, booklet, report, catalog.';

  @override
  String get hubGroupCertificates => 'Certificates and contracts';

  @override
  String get hubGroupCards => 'Cards and ID badges';

  @override
  String get hubGroupSeat => 'Seat numbers and tags';

  @override
  String get hubGroupGreeting => 'Greeting cards';

  @override
  String get hubGroupPublications => 'Books and publications';

  @override
  String get hubGroupCustom => 'Custom size';

  @override
  String get hubDigitalBadge => 'Digital';

  @override
  String get hubCreate => 'Create';

  @override
  String get hubCustomCardBody =>
      'Enter your dimensions in any unit and start with a canvas at your own size.';

  @override
  String get hubCustomName => 'Project name';

  @override
  String get hubCustomNameHint => 'e.g. Invitation card';

  @override
  String get hubCustomPreview => 'Final size';

  @override
  String get hubCustomCreate => 'Create canvas';

  @override
  String get hubCustomType => 'Project type';

  @override
  String get hubSearchHint => 'Search sizes…';

  @override
  String get hubNoResults => 'No matching size — try another keyword.';

  @override
  String get hubAspectRatio => 'Ratio';

  @override
  String get destNewProject => 'New project';

  @override
  String get destNewProjectDesc =>
      'Pick a ready-made or custom size and start designing right away.';

  @override
  String get ptpImpositionToggle => 'Print imposition';

  @override
  String get ptpImpositionNoFit =>
      'The sheet is too small for this item — reduce margins or pick a larger sheet.';

  @override
  String get editorEffectsTitle => 'Effects & color adjustments';

  @override
  String get editorShadowGroup => 'Shadow';

  @override
  String get editorOuterGlow => 'Outer glow';

  @override
  String get editorInnerGlow => 'Inner glow';

  @override
  String get editorGlowAdd => 'Add glow';

  @override
  String get editorGlowRemove => 'Remove glow';

  @override
  String get editorGlowColor => 'Glow color';

  @override
  String get editorGlowRadius => 'Glow radius';

  @override
  String get editorGlowSpread => 'Glow spread';

  @override
  String get editorGlowOpacity => 'Glow opacity';

  @override
  String get editorAdjustGroup => 'Color adjustments';

  @override
  String get editorAdjustBrightness => 'Brightness';

  @override
  String get editorAdjustContrast => 'Contrast';

  @override
  String get editorAdjustSaturation => 'Saturation';

  @override
  String get editorAdjustHue => 'Hue';

  @override
  String get editorAdjustReset => 'Reset';

  @override
  String get bpOutputSavedFolderTitle => 'Files saved to a dedicated folder';

  @override
  String get hubDetailsTitle => 'Preset details';

  @override
  String get hubDetailsHint =>
      'Pre-filled default spec — pick a size from the grid or edit the dimensions to start.';

  @override
  String get hubFilterAll => 'All';

  @override
  String get hubFilterRecent => 'Recent';

  @override
  String get hubFilterSeat => 'Seat numbers';

  @override
  String get hubFilterGreeting => 'Greetings & screens';

  @override
  String get hubRecentEmpty =>
      'No recent sizes yet — any project you create shows up here.';

  @override
  String get hubDocTitle => 'Project name';

  @override
  String get hubDocTitleHint => 'New project - 1';

  @override
  String get hubWidth => 'Width';

  @override
  String get hubHeight => 'Height';

  @override
  String get hubUnitLabel => 'Unit';

  @override
  String get hubOrientationLabel => 'Orientation';

  @override
  String get hubPortrait => 'Portrait';

  @override
  String get hubLandscape => 'Landscape';

  @override
  String get hubVariantLabel => 'Type';

  @override
  String get hubResolutionLabel => 'Resolution';

  @override
  String get hubResolutionUnitLabel => 'Resolution unit';

  @override
  String get hubColorModeLabel => 'Color mode';

  @override
  String get hubBackgroundLabel => 'Background color';

  @override
  String get hubBackgroundWhite => 'White';

  @override
  String get hubBackgroundTransparent => 'Transparent';

  @override
  String get hubBackgroundBlack => 'Black';

  @override
  String get hubBackgroundCustom => 'Custom color';

  @override
  String get hubCreateProject => 'Create project';

  @override
  String get hubCustomFamilyTitle => 'Custom size';

  @override
  String get newDocTitle => 'New document';

  @override
  String get newDocScopeSocial => 'Social & Mobile';

  @override
  String get newDocFilterCertificates => 'Certificates';

  @override
  String get newDocFilterCards => 'Cards';

  @override
  String get newDocFilterGreeting => 'Greetings';

  @override
  String get newDocFilterPublications => 'Publications';

  @override
  String get menuFile => 'File';

  @override
  String get menuEdit => 'Edit';

  @override
  String get menuView => 'View';

  @override
  String get menuTools => 'Tools';

  @override
  String get menuHelp => 'Help';

  @override
  String get menuNewDocument => 'New document…';

  @override
  String get menuPurgeRecent => 'Clear recent sizes';

  @override
  String get menuPurgeImageCache => 'Clear image cache';

  @override
  String get menuPreviewCertificate => 'Preview sample certificate';

  @override
  String get menuPreviewContract => 'Preview sample contract';

  @override
  String get menuAbout => 'About JoodCraft';

  @override
  String get actionNewShort => '+ New';

  @override
  String get dashLocalMode => 'Local';

  @override
  String get dashLocalStorage =>
      'Saved locally on this device — no project is uploaded to a server.';

  @override
  String get dashRecentProjects => 'Recent projects';

  @override
  String get dashRecentEmpty =>
      'No saved projects on this device yet — create a new document and it appears here instantly.';

  @override
  String get dashRecentOpen => 'Open project';

  @override
  String get editorTransformPosition => 'Transform & Position';

  @override
  String get editorTransformPositionHint => 'Position, size and rotation angle';

  @override
  String get editorAppearanceEffects => 'Appearance & Effects';

  @override
  String get editorAppearanceEffectsHint => 'Fill, stroke, glow and shadows';

  @override
  String get editorTypographyHint => 'Font, size, alignment and spacing';

  @override
  String get editorPageSettingsHint => 'Size and measurement unit';

  @override
  String get editorBackgroundHint => 'Page colour or gradient';

  @override
  String get editorPrecisionHint => 'Fine nudge and scale';

  @override
  String get joodExportProject => 'Export project (.jood)';

  @override
  String get joodImportProject => 'Open project (.jood)';

  @override
  String get joodExportReady => 'Project file is ready to save.';

  @override
  String get joodExportFailed => 'Could not export the project file.';

  @override
  String get joodImportOpened => 'Imported project opened.';

  @override
  String get joodImportFailed => 'Could not open the project file.';

  @override
  String get joodRecoveryTitle => 'Unsaved draft';

  @override
  String get joodRecoveryMessage =>
      'There is an unsaved draft from a previous session. Do you want to restore it?';

  @override
  String get joodRecoveryRestore => 'Restore';

  @override
  String get joodRecoveryDiscard => 'Discard';

  @override
  String get joodRecoveryRestored => 'Draft restored.';

  @override
  String get joodAutosaveSaved => 'Saved automatically';

  @override
  String get joodAutosaveSaving => 'Saving…';

  @override
  String get editorConfirm => 'Confirm';

  @override
  String get admTitle => 'Local admin management';

  @override
  String get admRefresh => 'Refresh';

  @override
  String get admTabAdmins => 'Admins';

  @override
  String get admTabTransfer => 'Device transfer';

  @override
  String get admTabAudit => 'Export log';

  @override
  String get admListTitle => 'Admin accounts on this device';

  @override
  String get admAdd => 'Add admin';

  @override
  String get admNoAdmins => 'No admin accounts yet.';

  @override
  String get admLoading => 'Loading admin accounts on this device…';

  @override
  String get admRoleOwner => 'Primary admin';

  @override
  String get admCurrent => 'You';

  @override
  String get admCurrentCardTitle => 'Current account on this device';

  @override
  String get admRoleAdmin => 'Admin';

  @override
  String get admSwitchTitle => 'Fast account switch';

  @override
  String get admSwitchPrompt =>
      'Pick the local username of a sub-admin on this device and enter their local password to jump straight into their session — open project drafts are saved first, and the master subscription licence is unaffected.';

  @override
  String get admSwitchNoOthers =>
      'No other sub-admins on this device. Add a new admin from the admins screen first.';

  @override
  String get admSwitchPick => 'Local username';

  @override
  String get admSwitchPassword => 'Local password of the selected account';

  @override
  String get admSwitchPickPassword => 'Pick a username and enter the password.';

  @override
  String get admSwitchWrongPassword => 'Incorrect password.';

  @override
  String get admSwitchFailed => 'Could not switch accounts. Try again.';

  @override
  String get admSwitchSuccess => 'Account switched successfully.';

  @override
  String get admSwitchAccount => 'Switch account';

  @override
  String get admSwitchAction => 'Switch now';

  @override
  String get admColAdmin => 'Admin';

  @override
  String get admColUsername => 'Local username';

  @override
  String get admColRole => 'Role';

  @override
  String get admColCreated => 'Added on';

  @override
  String get admColActions => 'Actions';

  @override
  String get destJoodWriter => 'Jood Writer';

  @override
  String get destJoodWriterDesc =>
      'Text documents and reports with flowing, self-paginating pages.';

  @override
  String get admCreatedAt => 'Created';

  @override
  String get admEdit => 'Edit details';

  @override
  String get admChangePassword => 'Change password';

  @override
  String get admPromote => 'Promote to primary admin';

  @override
  String get admDemote => 'Demote to admin';

  @override
  String get admDelete => 'Delete account';

  @override
  String admDeleteConfirm(Object name) {
    return '“$name” will be permanently deleted from this device. This cannot be undone.';
  }

  @override
  String get admPromoted => 'Promoted to primary admin.';

  @override
  String get admDemoted => 'Demoted to admin.';

  @override
  String get admDeleted => 'Account deleted.';

  @override
  String get admCreated => 'New admin added.';

  @override
  String get admUpdated => 'Admin details updated.';

  @override
  String get admPasswordChanged => 'Password changed.';

  @override
  String get admTransferInfoTitle => 'How does transfer work?';

  @override
  String get admTransferInfo1 =>
      'The account table (with password hashes, never the passwords) is exported inside a file encrypted with a passphrase you choose.';

  @override
  String get admTransferInfo2 =>
      'Move the file or code to the other device and import it there with the same passphrase, and the accounts work with the same permissions.';

  @override
  String get admTransferInfo3 =>
      'Nothing is sent to any server: the transfer is fully manual between local devices.';

  @override
  String get admExport => 'Export accounts';

  @override
  String get admExportPassphrase => 'Export passphrase';

  @override
  String get admPassphraseConfirm => 'Confirm passphrase';

  @override
  String get admExportRisk =>
      'I understand that anyone holding this code and its passphrase can sign in with these accounts, so I will share it carefully.';

  @override
  String get admExportGenerate => 'Generate encrypted code';

  @override
  String get admExportFile => 'Save to a dedicated file';

  @override
  String get admExportDone =>
      'Encrypted code generated. Copy it or save it to a file.';

  @override
  String get admExportFileSaved => 'Encrypted accounts file saved.';

  @override
  String get admPassphraseTooShort =>
      'Use at least 6 characters for the passphrase.';

  @override
  String get admPassphraseMismatch => 'The passphrases do not match.';

  @override
  String get admAcceptRiskRequired =>
      'First confirm that you understand the risk of sharing the code.';

  @override
  String admFileError(Object error) {
    return 'Could not handle the file: $error';
  }

  @override
  String get admImport => 'Import accounts';

  @override
  String get admImportCode => 'Accounts code';

  @override
  String get admImportPassphrase => 'File passphrase';

  @override
  String get admImportReplace => 'Replace passwords of existing accounts';

  @override
  String get admImportPick => 'Choose a file';

  @override
  String get admImportRun => 'Import now';

  @override
  String get admImportCodeRequired => 'Paste the code or choose a file first.';

  @override
  String get admImportPassphraseRequired => 'Enter the file passphrase.';

  @override
  String admImportDone(int added, int updated, int skipped) {
    return 'Imported: $added new, $updated updated, $skipped skipped.';
  }

  @override
  String get admAuditTitle => 'Issued certificates and documents log';

  @override
  String get admAuditClear => 'Clear log';

  @override
  String get admAuditEmpty =>
      'No exports yet. Every certificate or contract you export will be logged here with its date and the admin who issued it.';

  @override
  String get admAuditBy => 'By';

  @override
  String get admAuditPages => 'pages';

  @override
  String get admAuditClearConfirm =>
      'The whole export log will be deleted from this device. This cannot be undone.';

  @override
  String get admAuditCleared => 'Log cleared.';

  @override
  String get admUnavailableTitle => 'Management is unavailable right now';

  @override
  String get admUnavailableBody =>
      'Admin management works when the app runs with a local account (LocalAuthRepository), so accounts are read from this device.';

  @override
  String get pdfExportTypeTitle => 'Export type';

  @override
  String get pdfExportTypeHint => 'Choose the file format before exporting.';

  @override
  String get pdfExportTypeImages => 'Images';

  @override
  String get pdfExportTypeImagesDesc => '100% match — larger file';

  @override
  String get pdfExportTypeImagesNotCopyable => 'Text can\'t be copied';

  @override
  String get pdfExportTypeVector => 'Vector';

  @override
  String get pdfExportTypeVectorDesc => 'Copyable text — smaller file';

  @override
  String get pdfExportTypeVectorCopyable => 'Text you can copy and search';

  @override
  String get bpPdfEngineLabel => 'Drawing engine';

  @override
  String get pdfExportTypeVectorBestFor => 'Ideal for professional printing';

  @override
  String get invCategoryTitle => 'Invitations & occasions';

  @override
  String get invCategoryRamadan => 'Ramadan';

  @override
  String get invCategoryEid => 'Eid';

  @override
  String get invCategoryWedding => 'Wedding';

  @override
  String get invRamadan1Title => 'Ramadan Kareem — Classic';

  @override
  String get invRamadan2Title => 'Ramadan Kareem — Story';

  @override
  String get invEid1Title => 'Eid Mubarak — Classic';

  @override
  String get invEid2Title => 'Eid Mubarak — Story';

  @override
  String get invWedding1Title => 'Wedding — Classic';

  @override
  String get invWedding2Title => 'Wedding — Modern';

  @override
  String get invWedding3Title => 'Wedding — Story';

  @override
  String get invSizeA6Portrait => 'A6 portrait (105×148 mm)';

  @override
  String get invSizeA6Landscape => 'A6 landscape (148×105 mm)';

  @override
  String get invSizeSquare148 => 'Print square (148×148 mm)';

  @override
  String get invSizeA5Folded => 'A5 folded (105×148 mm)';

  @override
  String get invSizeInstagramSquare => 'Instagram square (1080×1080)';

  @override
  String get invSizeInstagramPortrait => 'Instagram portrait (1080×1350)';

  @override
  String get invSizeInstagramStory => 'Instagram Story (1080×1920)';

  @override
  String get invSizeWhatsAppStatus => 'WhatsApp Status (1080×1920)';

  @override
  String get invSizeFacebookPost => 'Facebook Post (1200×630)';

  @override
  String get invExportFormatPNG => 'PNG (for social media)';

  @override
  String get invExportFormatPDF => 'PDF (for printing)';

  @override
  String get invExportFormatBoth => 'PNG + PDF';

  @override
  String get invBulkModeTitle => 'Bulk personal invitations';

  @override
  String get invBulkModeHint => 'One card per name — individual export.';

  @override
  String get invPreviewTitle => 'Preview of the first 3 copies';

  @override
  String get invExportFormat => 'Export format';

  @override
  String get invNameFieldMissing => 'This template has no name field';

  @override
  String invDuplicateNames(Object count) {
    return 'Duplicate names: $count';
  }

  @override
  String invEmptyNames(Object count) {
    return 'Empty cells: $count — they will be skipped';
  }

  @override
  String get invZIPOption => 'Compress into a ZIP file';

  @override
  String get invIndexCSVOption => 'Create a CSV index';

  @override
  String invProgressText(Object done, Object total) {
    return 'Generated $done of $total';
  }

  @override
  String get navEditors => 'Editors';

  @override
  String get navLibraries => 'Libraries';

  @override
  String get navAdmin => 'Admin';

  @override
  String get navUser => 'Account';

  @override
  String get bpWorkTypeLabel => 'Template type';

  @override
  String get bpExportFormatLabel => 'Export type';

  @override
  String get bpKindInvitation => 'Invitation';

  @override
  String get invPackOptions => 'Output options';

  @override
  String get tplCertClassicTitle => 'Classic Navy Certificate';

  @override
  String get tplCertClassicDesc =>
      'Classic navy certificate with a double gold frame and ornamental corner stars.';

  @override
  String get tplCertMinimalTitle => 'Minimal Navy Certificate';

  @override
  String get tplCertMinimalDesc =>
      'Clean minimal navy design with a single gold rule and generous whitespace.';

  @override
  String get tplCertIslamicTitle => 'Islamic Ornament Certificate';

  @override
  String get tplCertIslamicDesc =>
      'Navy certificate with gold edging, Islamic geometric ornaments and Amiri type.';

  @override
  String get tplCertBandTitle => 'Gold Band Certificate';

  @override
  String get tplCertBandDesc =>
      'Navy certificate with horizontal gold bands above and below and a tidy footer.';

  @override
  String get tplCertDiagonalTitle => 'Dynamic Diagonal Certificate';

  @override
  String get tplCertDiagonalDesc =>
      'Navy certificate with slanted gold geometric shapes conveying motion.';

  @override
  String get tplCertSquareTitle => 'Elegant Square Certificate';

  @override
  String get tplCertSquareDesc =>
      'Navy certificate with a symmetric square gold frame and a top circular seal.';

  @override
  String get navInvitationsEngine => 'Invitations Engine';

  @override
  String get aboutTitle => 'About JoodCraft';

  @override
  String get aboutTagline =>
      'Generate official Arabic certificates and contracts';

  @override
  String aboutVersion(Object version) {
    return 'Version $version';
  }

  @override
  String get aboutSummaryTitle => 'Overview';

  @override
  String get aboutSummaryBody =>
      'JoodCraft is a desktop and web app that runs entirely on your device: it reads Excel files and generates certificates and contracts as PDF with Arabic fonts bundled inside the app. All projects, templates and assets stay in a local database on your machine — nothing is ever uploaded, so your data remains yours alone.';

  @override
  String get aboutFeaturesTitle => 'Key features';

  @override
  String get aboutFeatureOffline =>
      'Fully offline: no internet needed, nothing uploaded';

  @override
  String get aboutFeatureArabicFonts =>
      'Bundled Arabic fonts with precise shaping and RTL';

  @override
  String get aboutFeatureExcel =>
      'Reads Excel and CSV, mapping columns to template fields automatically';

  @override
  String get aboutFeatureBatch =>
      'Generate hundreds of certificates at once — one combined file or one per person';

  @override
  String get aboutFeatureVisualEditor =>
      'Visual drag-and-drop editor with multi-select, undo and redo';

  @override
  String get aboutFeatureInvitations =>
      'Ready-made Ramadan, Eid and wedding invitations in print and social media sizes';

  @override
  String get aboutFeatureExports =>
      'Exports PDF, PNG and shareable Jood project files';

  @override
  String get aboutDeveloperTitle => 'Developer';

  @override
  String get aboutDeveloperName => 'Seraj Abdullah Al-Badawi';

  @override
  String get aboutDeveloperEmail => 'serajelroh@gmail.com';

  @override
  String get aboutDeveloperStatus =>
      'Personal project — under active development';

  @override
  String get aboutLicenses => 'View licenses';

  @override
  String get aboutFeedback => 'Send feedback';

  @override
  String get aboutFeedbackCopied =>
      'Email copied — your feedback is always welcome';

  @override
  String get aboutCreditsTitle => 'Credits';

  @override
  String get aboutCreditsBody =>
      'Built with Flutter and open-source libraries — thanks to the Flutter community and to everyone who contributes to those libraries.';

  @override
  String get jwPagesSettings => 'Page settings';

  @override
  String get jwPagesMultiple => 'Multiple pages';

  @override
  String get jwPagesMultipleHint =>
      'Split the sheet in half to print two pages on one sheet';

  @override
  String get jwPagesSingle => 'Normal (single page)';

  @override
  String get jwPagesA4ToA5Portrait => 'A4 → 2 × A5 portrait (booklet)';

  @override
  String get jwPagesA4ToA5Landscape => 'A4 → 2 × A5 landscape';

  @override
  String get jwPagesPreview => 'Preview';

  @override
  String get aboutLinksTitle => 'Links';

  @override
  String get aboutDescription =>
      'JoodCraft is a complete Arabic platform for generating certificates, contracts and invitations with professional quality. Design a single template visually, then link it to an Excel file to produce hundreds of documents with precise Arabic typography and correct direction — offline and with no server.';

  @override
  String get aboutFeatures => 'Features';

  @override
  String get aboutFeature10Languages => '10 supported languages';

  @override
  String get aboutFeatureArabicText => 'Precise Arabic shaping';

  @override
  String get aboutFeatureBulkGeneration => 'Bulk generation from Excel';

  @override
  String get aboutFeaturePdfExport => 'High-quality PDF export';

  @override
  String get aboutDeveloper => 'Developer';

  @override
  String get aboutDeveloperNote => 'Personal project — under development';

  @override
  String get aboutLinks => 'Links';

  @override
  String get aboutViewLicenses => 'View licenses';

  @override
  String get aboutSendFeedback => 'Send feedback';

  @override
  String get aboutCredits => 'Credits';

  @override
  String get aboutCreditsText =>
      'JoodCraft is built with Flutter and Dart, and open-source libraries. Thanks to everyone who contributed.';

  @override
  String get navInvitationTemplates => 'Invitation templates';

  @override
  String get ocrTitle => 'Extract text from image';

  @override
  String get ocrSubtitle => 'Import an image or PDF and extract its text';

  @override
  String get ocrImportImage => 'Import image';

  @override
  String get ocrImportPdf => 'Import PDF';

  @override
  String get ocrExtractText => 'Extract text';

  @override
  String get ocrProcessing => 'Processing...';

  @override
  String get ocrPreview => 'Text preview';

  @override
  String get ocrInsertInEditor => 'Insert into editor';

  @override
  String get ocrCopyToClipboard => 'Copy';

  @override
  String get ocrRetry => 'Retry';

  @override
  String get ocrAccept => 'Accept';

  @override
  String get ocrCancel => 'Cancel';

  @override
  String get ocrLanguageLabel => 'Language';

  @override
  String get ocrLanguageArabic => 'Arabic';

  @override
  String get ocrLanguageEnglish => 'English';

  @override
  String get ocrLanguageBoth => 'Arabic and English';

  @override
  String get ocrAccuracyNote =>
      'Extraction accuracy may not be 100% — review the text before saving.';

  @override
  String get ocrNoTextFound => 'No text was found in the image.';

  @override
  String get ocrInvalidImage => 'Invalid image.';

  @override
  String get ocrError => 'Could not extract the text. Try again.';

  @override
  String get ocrEngineMissing =>
      'Tesseract was not found — install it, then try again.';

  @override
  String get ocrLanguageDataMissing =>
      'Language data is not installed with Tesseract.';

  @override
  String get ocrNoImage => 'Import an image or PDF first.';

  @override
  String get ocrCopyDone => 'Text copied to the clipboard.';

  @override
  String get ocrConfidence => 'Confidence';

  @override
  String get ocrPsmLabel => 'Segmentation';

  @override
  String get ocrPsmAuto => 'Automatic';

  @override
  String get ocrPsmBlock => 'Single text block';

  @override
  String get ocrPsmLine => 'Single line';

  @override
  String get ocrPsmSparse => 'Sparse text';

  @override
  String get ocrScaleLabel => 'Zoom';

  @override
  String get ocrPdfPages => 'Pages';

  @override
  String get ocrInsertInWriter => 'Insert into Jood Writer';

  @override
  String get ocrTessHint =>
      'Requires Tesseract to be installed on this device.';
}
