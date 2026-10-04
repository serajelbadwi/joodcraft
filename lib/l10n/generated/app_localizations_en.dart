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
  String get dashRoadmapSupabase =>
      'Set up the Supabase database (tables + RLS + triggers)';

  @override
  String get dashRoadmapModular => 'A scalable Modular Feature-First structure';

  @override
  String get dashRoadmapTheme =>
      'The brand’s visual theme with RTL support in the Cairo font';

  @override
  String get dashRoadmapAuth =>
      'Authentication: sign-in, account creation and password reset';

  @override
  String get dashPhaseOneDone => 'Phase one complete';

  @override
  String get dashNextPhase =>
      'Next: the offline PDF engine and Arabic fonts, then the visual template editor.';

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
}
