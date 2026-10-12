// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get editorDone => 'Terminé';

  @override
  String get appTagline =>
      'Générez des certificats et des contrats officiels hors ligne';

  @override
  String get navDashboard => 'Tableau de bord';

  @override
  String get navCertificates => 'Créateur de certificats';

  @override
  String get navContracts => 'Créateur de contrats';

  @override
  String get navBatch => 'Génération en lot';

  @override
  String get navTemplates => 'Bibliothèque de modèles';

  @override
  String get navAssets => 'Ressources et signatures';

  @override
  String get actionSignOut => 'Se déconnecter';

  @override
  String get actionOpenMenu => 'Menu';

  @override
  String get editorFitToScreen => 'Ajuster à l\'écran';

  @override
  String get editorNewTemplate => 'Nouveau modèle';

  @override
  String get editorNewConfirm =>
      'Un nouveau modèle démarrera à partir du design par défaut ; les modifications non enregistrées resteront dans l\'historique. Continuer ?';

  @override
  String get actionBackToDashboard => 'Retour au tableau de bord';

  @override
  String get offlineProcessingLabel => 'Traitement local';

  @override
  String get themeTooltip => 'Changer le thème';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get languageTooltip => 'Changer de langue';

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
  String get configMissingKeysTitle => 'Clés de connexion introuvables';

  @override
  String get configMissingKeysBody =>
      'Au démarrage, l\'application cherche les clés dans trois sources : le drapeau --dart-define, puis un fichier env.json sur le disque (racine ou assets/env/), puis la copie intégrée — aucune n\'a été trouvée. Créez le fichier, remplissez-le une fois, puis lancez sans aucun drapeau :';

  @override
  String get configEnvNote =>
      'Le bundle déclare assets/env/ comme ressource, donc l\'absence du fichier ne casse pas une compilation propre. Créez-le depuis env.example.json ou exécutez : dart run tool/ensure_env.dart — seule la clé anon/public est requise ; service_role n\'est jamais utilisée dans l\'application.';

  @override
  String get routeNotFoundTitle => 'Page introuvable';

  @override
  String get routeNotFoundBody =>
      'La route demandée n\'est pas définie dans l\'application :';

  @override
  String get editorPrecisionTitle => 'Contrôles de précision';

  @override
  String get editorNudgeStep => 'Pas de déplacement';

  @override
  String get editorNudgeStepHint =>
      'Les flèches du plan de travail déplacent aussi de Shift = 10px.';

  @override
  String get editorNudgeUp => 'Déplacer vers le haut';

  @override
  String get editorNudgeLeft => 'Déplacer à gauche';

  @override
  String get editorNudgeDown => 'Déplacer vers le bas';

  @override
  String get editorNudgeRight => 'Déplacer à droite';

  @override
  String get editorScale => 'Échelle';

  @override
  String get editorScaleHint =>
      'Mise à l’échelle relative autour du centre de l’élément (molette sur les boutons pour un pas plus fin).';

  @override
  String get editorScaleUp => 'Agrandir';

  @override
  String get editorScaleDown => 'Réduire';

  @override
  String get editorDecorTitle => 'Décoration vectorielle';

  @override
  String get editorDecorKind => 'Type de décoration';

  @override
  String get editorDecorPalette => 'Palette de couleurs';

  @override
  String get editorDecorLayers => 'Nombre de calques';

  @override
  String get editorDecorSeed => 'Graine';

  @override
  String get editorDecorThickness => 'Épaisseur';

  @override
  String get editorDecorPrimary => 'Couleur principale';

  @override
  String get editorDecorSecondary => 'Couleur secondaire';

  @override
  String get editorDecorAccent => 'Couleur d’accent';

  @override
  String get editorDecorGradient => 'Dégradé des calques';

  @override
  String get editorDecorGallery => 'Galerie de modèles';

  @override
  String get editorDecorGalleryTitle =>
      'Galerie de décorations prêtes à l’emploi';

  @override
  String get editorClose => 'Fermer';

  @override
  String get editorDecorPaletteCustom => 'Personnalisée';

  @override
  String get decorKindModernWave => 'Vagues modernes';

  @override
  String get decorKindPaperCut => 'Découpe papier multicouche';

  @override
  String get decorKindClassicCorner => 'Cadre classique orné';

  @override
  String get decorKindGuilloche => 'Motif guilloché';

  @override
  String get decorKindRibbonBanner => 'Ruban / bannière';

  @override
  String get decorPaletteRoyalGold => 'Or royal';

  @override
  String get decorPaletteRoyalBlue => 'Bleu roi';

  @override
  String get decorPaletteEmerald => 'Émeraude';

  @override
  String get decorPaletteBurgundy => 'Bordeaux';

  @override
  String get decorPaletteMidnight => 'Bleu nuit';

  @override
  String get decorPaletteMono => 'Gris monochrome';

  @override
  String get editorSignatureTitle => 'Bloc de signatures';

  @override
  String get editorSignatureCount => 'Nombre de signatures';

  @override
  String get signatureCountOne => 'Une signature';

  @override
  String get signatureCountTwo => 'Deux signatures';

  @override
  String get signatureCountThree => 'Trois signatures';

  @override
  String get editorSignatureOrder => 'Ordre des emplacements';

  @override
  String get editorSignatureOrderHint =>
      'Dans les documents arabes, le premier emplacement est à l’extrême droite.';

  @override
  String get editorSignatureFirstRight => 'Première à droite';

  @override
  String get editorSignatureFirstLeft => 'Première à gauche';

  @override
  String get editorDirectionAuto => 'Automatique';

  @override
  String get editorSignatureImageAlign => 'Alignement de l’image';

  @override
  String get editorAlignStart => 'Début';

  @override
  String get editorAlignCenter => 'Centre';

  @override
  String get editorAlignEnd => 'Fin';

  @override
  String get editorSignatureDivider => 'Ligne de signature';

  @override
  String get editorVisible => 'Visible';

  @override
  String get editorHidden => 'Masqué';

  @override
  String get editorSignatureNameSize => 'Taille du nom';

  @override
  String get editorSignatureRoleSize => 'Taille du rôle';

  @override
  String get editorSignatureSpacing => 'Espacement';

  @override
  String get editorSignatureImageSize => 'Taille de l’image';

  @override
  String get editorSignatureNameColor => 'Couleur du nom';

  @override
  String get editorSignatureRoleColor => 'Couleur du rôle';

  @override
  String get editorFont => 'Police';

  @override
  String get editorImageSource => 'Source de l’image';

  @override
  String get imageSourceAppAssets => 'Ressources de l’application';

  @override
  String get imageSourceMyLibrary => 'Ma bibliothèque d’assets';

  @override
  String get imageSourceLocalFile => 'Fichier local';

  @override
  String get imageSourceEmbedded => 'Données intégrées';

  @override
  String get editorSignatureChangeImage => 'Changer l’image de signature';

  @override
  String get editorSignatureAddImage => 'Ajouter une image de signature';

  @override
  String get editorSignatureRemoveImage => 'Supprimer l’image de signature';

  @override
  String get editorSignaturePickImageTitle =>
      'Choisir une image de signature dans ma bibliothèque';

  @override
  String get editorSignatureSlot => 'Emplacement';

  @override
  String get editorSignatureRoleField => 'Rôle (ex. : Directeur général)';

  @override
  String get editorSignatureNameField =>
      'Nom du signataire (accepte un champ dynamique)';

  @override
  String get editorFromMyLibrary => 'Depuis ma bibliothèque';

  @override
  String get paletteSignatureBlock => 'Signatures';

  @override
  String get editorInsertFromLibraryTooltip =>
      'Insérer directement un cadre ou un logo importé';

  @override
  String get unsupportedElementVersionNote =>
      'Cet élément provient d’une version plus récente de l’éditeur — il est conservé tel quel et ne peut pas être modifié ici.';

  @override
  String editorSelectedCount(Object count) {
    return '$count sélectionné(s)';
  }

  @override
  String get editorClearSelection => 'Effacer la sélection';

  @override
  String get editorGroup => 'Groupe';

  @override
  String get editorOpacity => 'Opacité';

  @override
  String get editorBringToFront => 'Mettre au premier plan';

  @override
  String get editorSendToBack => 'Mettre en arrière-plan';

  @override
  String get editorDuplicate => 'Dupliquer';

  @override
  String get editorDeleteSelected => 'Supprimer la sélection';

  @override
  String get editorGroupDragHint =>
      'Faites glisser le groupe à la souris, utilisez les flèches pour un déplacement fin (Shift = 10px) et Ctrl + clic pour ajuster la sélection.';

  @override
  String get destBrand => 'Identité & profil';

  @override
  String get destBrandDesc =>
      'Votre logo, vos cachets, vos signatures et vos couleurs.';

  @override
  String get brandTitle => 'Paramètres d\'identité et de profil';

  @override
  String get brandTabVisuals => 'Identité visuelle';

  @override
  String get brandTabText => 'Données textuelles';

  @override
  String get brandTabColors => 'Couleurs et polices';

  @override
  String get brandTabPreview => 'Aperçu de l\'identité';

  @override
  String get brandPrimaryLogo => 'Logo principal';

  @override
  String get brandWatermarkLogo => 'Logo en filigrane';

  @override
  String get brandSeals => 'Cachets officiels';

  @override
  String get brandAddSeal => 'Ajouter un cachet';

  @override
  String get brandSealName => 'Nom du cachet';

  @override
  String get brandSignatures => 'Signatures autorisées';

  @override
  String get brandAddSignature => 'Ajouter une signature';

  @override
  String get brandSignatureName => 'Nom du signataire';

  @override
  String get brandSignatureTitle => 'Fonction';

  @override
  String get brandRemove => 'Supprimer';

  @override
  String get brandNoSeals => 'Aucun cachet ajouté pour l\'instant.';

  @override
  String get brandNoSignatures => 'Aucune signature ajoutée pour l\'instant.';

  @override
  String get brandOrgNameAr => 'Nom de l\'organisation (arabe)';

  @override
  String get brandOrgNameEn => 'Nom de l\'organisation (anglais)';

  @override
  String get brandHeaderText => 'Texte d\'en-tête';

  @override
  String get brandFooterText => 'Texte de pied de page';

  @override
  String get brandRegNumber => 'Numéro fiscal / d\'immatriculation';

  @override
  String get brandPrimaryColor => 'Couleur principale';

  @override
  String get brandSecondaryColor => 'Couleur secondaire';

  @override
  String get brandAccentColor => 'Couleur d\'accent';

  @override
  String get brandHeaderFont => 'Police des titres';

  @override
  String get brandBodyFont => 'Police du texte';

  @override
  String get brandClear => 'Effacer l\'identité';

  @override
  String get brandClearConfirm =>
      'Tout le contenu d\'identité enregistré sera supprimé. Continuer ?';

  @override
  String get brandSaved => 'Identité enregistrée.';

  @override
  String get brandPresets => 'Éléments d\'identité';

  @override
  String get brandInsertHeader => 'Insérer l\'en-tête standard';

  @override
  String get brandInsertFooter => 'Insérer le pied de page standard';

  @override
  String get brandApplyColors => 'Appliquer les couleurs';

  @override
  String get brandQuickSeals => 'Cachets';

  @override
  String get brandQuickSignatures => 'Signatures';

  @override
  String get brandNoBrand => 'Votre identité n\'est pas encore configurée.';

  @override
  String get brandOpenSettings => 'Ouvrir les paramètres d\'identité';

  @override
  String get brandHeaderInserted => 'En-tête standard inséré.';

  @override
  String get brandFooterInserted => 'Pied de page standard inséré.';

  @override
  String get brandColorsApplied => 'Couleurs appliquées.';

  @override
  String get brandSealInserted => 'Cachet inséré.';

  @override
  String get brandSignatureInserted => 'Signature insérée.';

  @override
  String get brandFontDefault => 'Par défaut';

  @override
  String get paletteShapes => 'Formes';

  @override
  String get paletteRoundedRect => 'Rectangle arrondi';

  @override
  String get paletteEllipse => 'Cercle / ellipse';

  @override
  String get editorFillOpacity => 'Opacité du remplissage';

  @override
  String get editorCollapsePanel => 'Réduire le panneau latéral';

  @override
  String get editorExpandPanel => 'Afficher le panneau latéral';

  @override
  String get editorCustomSize => 'Taille personnalisée';

  @override
  String get editorStandardSize => 'Taille standard';

  @override
  String get editorBackgroundTitle => 'Fond de la feuille';

  @override
  String get editorGradientFrom => 'De';

  @override
  String get editorGradientTo => 'À';

  @override
  String get editorGradientDirection => 'Direction';

  @override
  String get editorGradientNone => 'Sans dégradé';

  @override
  String get editorGradientVertical => 'Vertical';

  @override
  String get editorGradientHorizontal => 'Horizontal';

  @override
  String get editorGradientDiagonal => 'Diagonal';

  @override
  String get editorLayersTitle => 'Calques';

  @override
  String get editorLayerShow => 'Afficher l\'élément';

  @override
  String get editorLayerHide => 'Masquer l\'élément';

  @override
  String get editorLayerLock => 'Verrouiller l\'élément';

  @override
  String get editorLayerUnlock => 'Déverrouiller l\'élément';

  @override
  String get editorLayersEmpty =>
      'Aucun élément sur cette page pour l\'instant.';

  @override
  String get editorGroupSelected => 'Grouper la sélection';

  @override
  String get editorUngroupSelected => 'Dissocier';

  @override
  String get editorAlignLeft => 'Aligner à gauche';

  @override
  String get editorAlignCenterH => 'Centrer horizontalement';

  @override
  String get editorAlignRight => 'Aligner à droite';

  @override
  String get editorAlignTop => 'Aligner en haut';

  @override
  String get editorAlignCenterV => 'Centrer verticalement';

  @override
  String get editorAlignBottom => 'Aligner en bas';

  @override
  String get editorBringForward => 'Avancer';

  @override
  String get editorDuplicateElement => 'Dupliquer l’élément';

  @override
  String get editorDeleteElement => 'Supprimer l’élément';

  @override
  String get editorPageSettings => 'Paramètres de la page';

  @override
  String get editorPageSize => 'Format';

  @override
  String get editorUnit => 'Unité';

  @override
  String get editorWidth => 'Largeur';

  @override
  String get editorHeight => 'Hauteur';

  @override
  String get editorLabelText => 'Texte';

  @override
  String get editorLabelShape => 'Forme';

  @override
  String get editorLabelSeal => 'Sceau';

  @override
  String get editorLabelDecoration => 'Décoration vectorielle';

  @override
  String get editorLabelSignature => 'Bloc de signatures';

  @override
  String get editorLabelImage => 'Image / logo';

  @override
  String get editorLabelQr => 'Code QR';

  @override
  String get editorLabelUnknown => 'Élément non pris en charge';

  @override
  String get editorLabelDynamicField => 'Champ dynamique';

  @override
  String get editorPositionAndSize => 'Position et taille';

  @override
  String get editorPosX => 'X';

  @override
  String get editorPosY => 'Y';

  @override
  String get editorRotation => 'Rotation';

  @override
  String get editorTextFormat => 'Mise en forme du texte';

  @override
  String get editorConvertToField => 'Convertir en champ dynamique';

  @override
  String get editorFontWeight => 'Graisse';

  @override
  String get editorWeightRegular => 'Normal';

  @override
  String get editorWeightSemiBold => 'Moyen';

  @override
  String get editorWeightBold => 'Gras';

  @override
  String get editorFontSize => 'Taille de la police';

  @override
  String get editorLetterSpacing => 'Espacement des lettres';

  @override
  String get editorLineHeight => 'Hauteur de ligne';

  @override
  String get editorTextColor => 'Couleur du texte';

  @override
  String get editorTextBackground => 'Fond du texte';

  @override
  String get editorTextAlign => 'Alignement';

  @override
  String get editorAlignJustify => 'Justifié';

  @override
  String get editorJustifyMode => 'Méthode de justification';

  @override
  String get editorJustifyHint =>
      'La kashida est appliquée dans le fichier PDF (l’aperçu montre la justification par espaces)';

  @override
  String get editorJustifySpaces => 'Espaces';

  @override
  String get editorJustifyKashida => 'Kashida';

  @override
  String get editorVerticalAlign => 'Alignement vertical';

  @override
  String get editorVerticalTop => 'Haut';

  @override
  String get editorVerticalBottom => 'Bas';

  @override
  String get editorDirection => 'Direction';

  @override
  String get editorDirectionHint => 'Raccourci de bascule : Ctrl+Shift+D';

  @override
  String get editorDirectionRtl => 'Arabe (RTL)';

  @override
  String get editorDirectionLtr => 'Latin (LTR)';

  @override
  String get editorImage => 'Image';

  @override
  String get editorSource => 'Source';

  @override
  String get editorImageTint => 'Teinte de l’image';

  @override
  String get editorImageFit => 'Ajustement de l’image';

  @override
  String get editorFitContain => 'Contenir';

  @override
  String get editorFitCover => 'Couvrir';

  @override
  String get editorFitFill => 'Étirer';

  @override
  String get assetPickerEmptyHint =>
      'Vous n’avez encore importé aucune ressource. Importez un logo, une signature ou un sceau pour l’utiliser ici et à l’impression.';

  @override
  String get assetPickerNoneOption => 'Aucun (autre source)';

  @override
  String get assetPickerTitle => 'Choisir une image dans ma bibliothèque';

  @override
  String assetUploadType(Object type) {
    return 'Importer $type';
  }

  @override
  String get editorSeal => 'Sceau';

  @override
  String get editorSealColor => 'Couleur du sceau';

  @override
  String get editorSealRingColor => 'Couleur de l’anneau';

  @override
  String get editorSealStarColor => 'Couleur de l’étoile';

  @override
  String get editorSealStarSize => 'Taille de l’étoile';

  @override
  String get editorShape => 'Forme';

  @override
  String get editorFillColor => 'Couleur de remplissage';

  @override
  String get editorBorderColor => 'Couleur de bordure';

  @override
  String get editorBorderWidth => 'Épaisseur de la bordure';

  @override
  String get editorCornerRadius => 'Rayon des coins';

  @override
  String get editorQrVerify => 'Code de vérification';

  @override
  String get editorQrData => 'Données du code';

  @override
  String get editorQrColor => 'Couleur du code';

  @override
  String get editorQrBackground => 'Fond du code';

  @override
  String editorConvertDialogMessage(Object text) {
    return 'La conversion transforme le texte « $text » en un marqueur dynamique pouvant être lié lors de la génération groupée.';
  }

  @override
  String get editorFieldKeyHint => 'Clé du champ (ex. : nom, date, référence)';

  @override
  String get editorCustomKeyHint =>
      'Saisissez une clé personnalisée (sans accolades — elle sera ajoutée automatiquement)';

  @override
  String get editorCancel => 'Annuler';

  @override
  String get editorConvert => 'Convertir';

  @override
  String get editorPath => 'Chemin';

  @override
  String get editorTextContent => 'Contenu du texte';

  @override
  String editorInsertFieldToken(Object token) {
    return 'Insérer $token';
  }

  @override
  String editorAddLabel(Object label) {
    return 'Ajouter $label';
  }

  @override
  String assetInsertedSnack(Object name) {
    return '« $name » a été inséré dans le modèle.';
  }

  @override
  String get paletteHeading => 'Titre';

  @override
  String get paletteFrame => 'Rectangle / cadre';

  @override
  String get paletteDivider => 'Séparateur';

  @override
  String get paletteLogo => 'Logo / signature';

  @override
  String get evSignatureEmptyLabel => 'Signature vide';

  @override
  String get evSignatureEmptyDetail =>
      'Ajoutez un rôle, un nom et une image de signature';

  @override
  String get evSignatureMissingLabel => 'Signature manquante';

  @override
  String get evUploadToLibraryDetail =>
      'Importez l’image dans la bibliothèque d’assets';

  @override
  String get evImageNotFoundLabel => 'Image introuvable';

  @override
  String get evNoFileLabel => 'Aucun fichier sélectionné';

  @override
  String get evChooseFromAssetsDetail =>
      'Choisissez une image dans la bibliothèque d’assets';

  @override
  String get evAssetMissingLabel => 'Ressource manquante';

  @override
  String get evReselectAssetDetail =>
      'Resélectionnez le cadre/la ressource dans la bibliothèque';

  @override
  String get evInvalidImageLabel => 'Image invalide';

  @override
  String get evRenderDataFailedDetail => 'Impossible d’afficher les données';

  @override
  String get evInvalidDataLabel => 'Données invalides';

  @override
  String get evDecodeFailedDetail => 'Impossible de décoder l’image';

  @override
  String get evEmptyQrLabel => 'Code vide';

  @override
  String get evEmptyQrDetail =>
      'Saisissez la valeur du code dans la barre de propriétés';

  @override
  String evUnknownElementLabel(Object type) {
    return 'Élément non pris en charge : $type';
  }

  @override
  String get alpFilterAll => 'Tous';

  @override
  String get alpEmptyHint =>
      'Aucune ressource importée des types demandés. Importez un cadre ou un logo depuis la section « Ressources et signatures », puis réessayez.';

  @override
  String alpNoFilteredAssets(Object type) {
    return 'Aucune ressource de type « $type ».';
  }

  @override
  String get authWelcomeBack => 'Bienvenue dans JoodCraft.';

  @override
  String get authResetLinkSent =>
      'Le lien de réinitialisation a été envoyé. Vérifiez votre e-mail.';

  @override
  String get authLogin => 'Se connecter';

  @override
  String get authLoginSubtitle =>
      'Votre e-mail et votre mot de passe pour accéder au tableau de bord.';

  @override
  String get authNoAccount => 'Vous n’avez pas de compte ?';

  @override
  String get authCreateAccountLink => 'Créer un nouveau compte';

  @override
  String get authConfirmEmailThenLogin =>
      'Votre compte a été créé. Confirmez d’abord votre e-mail, puis connectez-vous.';

  @override
  String get authEmail => 'E-mail';

  @override
  String get authPassword => 'Mot de passe';

  @override
  String get authForgotPassword => 'Mot de passe oublié ?';

  @override
  String get authEnterDashboard => 'Accéder au tableau de bord';

  @override
  String get authResetPassword => 'Réinitialiser le mot de passe';

  @override
  String get authResetPasswordHint =>
      'Saisissez votre e-mail et nous vous enverrons un lien de réinitialisation.';

  @override
  String get authSendLink => 'Envoyer le lien';

  @override
  String get authConfirmEmailMessage =>
      'Votre compte a été créé. Vérifiez votre e-mail pour le confirmer, puis connectez-vous.';

  @override
  String get authAccountCreatedWelcome =>
      'Votre compte a été créé. Bienvenue dans JoodCraft.';

  @override
  String get authCreateAccount => 'Créer un compte';

  @override
  String get authRegisterSubtitle =>
      'Votre compte enregistre vos modèles et ressources (logo, signature, sceau) pour les réutiliser dans tous vos projets.';

  @override
  String get authHaveAccount => 'Vous avez déjà un compte ?';

  @override
  String get authFullName => 'Nom complet';

  @override
  String get authFullNameHint => 'ex. : Abdullah Al-Ahmad';

  @override
  String get authName => 'Nom';

  @override
  String get authOrgName => 'Nom de l’organisation (facultatif)';

  @override
  String get authOrgNameHint => 'ex. : Association caritative Jood';

  @override
  String get authOrgHelper =>
      'Imprimé automatiquement sur les certificats et contrats.';

  @override
  String get authOrgNameShort => 'Nom de l’organisation';

  @override
  String get authPasswordHint => 'Au moins 8 caractères';

  @override
  String authPasswordRule(Object min) {
    return 'Utilisez au moins $min caractères avec des chiffres et des symboles.';
  }

  @override
  String get authConfirmPassword => 'Confirmer le mot de passe';

  @override
  String get authCreateAccountButton => 'Créer le compte';

  @override
  String get authFeatureLocalExcel =>
      'Traitement 100 % local des fichiers Excel — vos données ne quittent pas votre appareil';

  @override
  String get authFeaturePdf =>
      'Génération PDF avec des polices arabes de haute qualité et un support RTL complet';

  @override
  String get authFeatureTemplates =>
      'Vos modèles sont enregistrés dans votre compte et prêts à être réutilisés';

  @override
  String get authTagline =>
      'Vos certificats et contrats officiels… imprimés en confiance.';

  @override
  String authVersion(Object name, Object version) {
    return '$name • Version $version';
  }

  @override
  String get dashModules => 'Modules de la plateforme';

  @override
  String dashWelcome(Object name) {
    return 'Bienvenue, $name';
  }

  @override
  String dashSubscription(Object tier) {
    return 'Abonnement : $tier';
  }

  @override
  String dashOrg(Object name) {
    return 'Organisation : $name';
  }

  @override
  String get dashOrgMissing =>
      'Vous n’avez pas encore défini le nom de votre organisation — il sera imprimé automatiquement sur les certificats et contrats.';

  @override
  String get dashOpenModule => 'Ouvrir le module';

  @override
  String get destDashboard => 'Tableau de bord';

  @override
  String get destDashboardDesc => 'Vue d’ensemble de vos projets et modèles.';

  @override
  String get destCertificates => 'Moteur de certificats';

  @override
  String get destCertificatesDesc =>
      'Concevez des certificats en paysage à partir d’un modèle modifiable.';

  @override
  String get destContracts => 'Moteur de contrats';

  @override
  String get destContractsDesc =>
      'Rédigez des contrats en portrait avec des champs dynamiques.';

  @override
  String get destBatch => 'Génération en masse';

  @override
  String get destBatchDesc =>
      'Lisez un fichier Excel localement et générez des centaines de certificats en une fois.';

  @override
  String get destTemplates => 'Bibliothèque de modèles';

  @override
  String get destTemplatesDesc =>
      'Gérez, classez et réutilisez vos modèles enregistrés.';

  @override
  String get destAssets => 'Ressources et signatures';

  @override
  String get destAssetsDesc => 'Votre logo, sceau, signature et cadres.';

  @override
  String get dashUser => 'Utilisateur';

  @override
  String get dashLogoutSuccess => 'Vous vous êtes déconnecté avec succès.';

  @override
  String get dashLogoutError => 'Impossible de se déconnecter. Réessayez.';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonPreview => 'Aperçu';

  @override
  String get commonOptions => 'Options';

  @override
  String get tplDelete => 'Supprimer';

  @override
  String get tplSortRecentlyUpdated => 'Modifiés récemment';

  @override
  String get tplSortTitleAsc => 'Nom (A–Z)';

  @override
  String get tplSortLabel => 'Tri';

  @override
  String get tplSubtitle =>
      'Des modèles professionnels prêts à l’emploi + les vôtres — rechercher, filtrer, ouvrir et importer, entièrement hors ligne.';

  @override
  String get tplRefreshTooltip => 'Actualiser la liste';

  @override
  String get tplSearchHint => 'Rechercher des modèles…';

  @override
  String get tplNoResultsTitle => 'Aucun résultat correspondant';

  @override
  String get tplNoResultsMessage =>
      'Essayez un autre terme de recherche ou réinitialisez le filtre.';

  @override
  String tplAddedToLocal(Object title) {
    return '« $title » a été ajouté à vos modèles locaux.';
  }

  @override
  String get tplCloudRequiresConnection =>
      'Enregistrer des modèles dans le cloud nécessite une connexion à un projet Supabase. Enregistrez-le localement.';

  @override
  String tplSavedToCloud(Object title) {
    return '« $title » a été enregistré dans le cloud.';
  }

  @override
  String get tplRenamed => 'Le modèle a été renommé.';

  @override
  String tplCopySuffix(Object title) {
    return '$title (copie)';
  }

  @override
  String tplCopyCreated(Object title) {
    return 'Une copie de « $title » a été créée.';
  }

  @override
  String get tplNowPrivate => 'Le modèle est désormais privé.';

  @override
  String get tplNowPublic =>
      'Le modèle est désormais public (lecture seule pour les autres).';

  @override
  String tplConfirmCloudDelete(Object title) {
    return '« $title » sera définitivement supprimé du cloud. Action irréversible.';
  }

  @override
  String tplCloudDeleted(Object title) {
    return 'Le modèle « $title » a été supprimé.';
  }

  @override
  String tplConfirmLocalDelete(Object title) {
    return '« $title » sera supprimé de cet appareil. Le modèle prêt à l’emploi d’origine reste disponible dans la bibliothèque.';
  }

  @override
  String tplLocalDeleted(Object title) {
    return 'Le modèle local « $title » a été supprimé.';
  }

  @override
  String get tplDeleteTitle => 'Supprimer le modèle';

  @override
  String get tplRenameTitle => 'Titre du modèle';

  @override
  String get tplFieldTitle => 'Titre';

  @override
  String tplPreviewLabel(Object title) {
    return 'Aperçu : $title';
  }

  @override
  String tplCount(Object count) {
    return '$count modèle(s)';
  }

  @override
  String tplCloudLoadError(Object message) {
    return 'Impossible de charger les modèles cloud : $message';
  }

  @override
  String get tplPublicBadge => 'Modèle public';

  @override
  String get tplOrientationLandscape => 'Paysage';

  @override
  String get tplOrientationPortrait => 'Portrait';

  @override
  String get tplPresetOffline =>
      'Modèle prêt à l’emploi • disponible hors ligne';

  @override
  String tplSchemaVersion(Object version) {
    return 'Schéma v$version';
  }

  @override
  String get tplOpenAsTemplate => 'Ouvrir comme modèle';

  @override
  String get tplOpen => 'Ouvrir';

  @override
  String get tplUseInBatch => 'Utiliser dans la génération en masse';

  @override
  String get tplImportLocal => 'Importer localement';

  @override
  String get tplSaveToCloud => 'Enregistrer dans le cloud';

  @override
  String get tplDeleteLocal => 'Supprimer localement';

  @override
  String get tplRename => 'Renommer';

  @override
  String get tplMakePrivate => 'Rendre privé';

  @override
  String get tplMakePublic => 'Rendre public';

  @override
  String get tplNoDate => 'Sans date';

  @override
  String get amSubtitle =>
      'Importez une fois votre logo, sceau et signature, puis insérez-les dans n’importe quel modèle — enregistrés sur votre appareil et réutilisables hors ligne.';

  @override
  String get amSearchHint => 'Rechercher des ressources…';

  @override
  String get amTypeLabel => 'Type';

  @override
  String get amUploadTooltip => 'Importer une nouvelle ressource';

  @override
  String get amUpload => 'Importer une ressource';

  @override
  String get amEmptyTitle => 'Aucune ressource pour l’instant';

  @override
  String get amEmptyMessage =>
      'Importez le logo, la signature ou le sceau de votre organisation, puis insérez-les dans n’importe quel modèle depuis la barre de propriétés de l’image.';

  @override
  String get amNoResultsMessage =>
      'Essayez un autre nom ou réinitialisez le filtre.';

  @override
  String get amRenamed => 'La ressource a été renommée.';

  @override
  String amMovedToType(Object type) {
    return 'La ressource a été déplacée vers « $type ».';
  }

  @override
  String get amDeleteTitle => 'Supprimer la ressource';

  @override
  String amConfirmDelete(Object name) {
    return '« $name » sera supprimé de cet appareil. Les modèles qui l’utilisent perdront l’image (sans échec d’impression).';
  }

  @override
  String amDeleted(Object name) {
    return 'La ressource « $name » a été supprimée.';
  }

  @override
  String get amRenameTitle => 'Renommer la ressource';

  @override
  String amCount(Object count) {
    return '$count ressource(s)';
  }

  @override
  String amMakeType(Object type) {
    return 'Définir le type : $type';
  }

  @override
  String get amCacheLabel => 'Cache d’images sur disque';

  @override
  String amCacheUsage(Object count, Object size) {
    return '$count fichier(s) · $size';
  }

  @override
  String amCacheUsageOf(Object count, Object used, Object limit) {
    return '$count fichier(s) · $used sur $limit';
  }

  @override
  String get amCacheEmpty => 'Pas encore de cache disque';

  @override
  String get amCacheClear => 'Vider le cache';

  @override
  String get amCacheCleared => 'Le cache d’images sur disque a été vidé.';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonPrint => 'Imprimer';

  @override
  String get commonExportPdf => 'Exporter en PDF';

  @override
  String get commonExportFailed => 'Impossible d’exporter le fichier PDF.';

  @override
  String get commonPrintFailed =>
      'Impossible d’envoyer le fichier à l’imprimante.';

  @override
  String commonExportReady(Object name) {
    return 'Le fichier est prêt à être enregistré sous $name.';
  }

  @override
  String get commonGenerating => 'Génération…';

  @override
  String get commonDataPanelTitle => 'Données d’exemple';

  @override
  String evElementCount(Object count) {
    return '$count élément(s)';
  }

  @override
  String get evStatusDynamicFields => ' • champs dynamiques';

  @override
  String get evStatusUnsaved => ' • modifications non enregistrées';

  @override
  String get tevNewTemplateTitle => 'Nouveau modèle';

  @override
  String get tevUnsavedTitle => 'Modifications non enregistrées';

  @override
  String tevUnsavedMessage(Object title) {
    return 'Vous avez des modifications non enregistrées sur « $title ». Voulez-vous les enregistrer avant de partir ?';
  }

  @override
  String get tevLeaveWithoutSaving => 'Quitter sans enregistrer';

  @override
  String get tevSaveAndLeave => 'Enregistrer et quitter';

  @override
  String get tevViewMode => 'Mode d’affichage';

  @override
  String get tevModeEditor => 'Éditeur';

  @override
  String get tevModePreview => 'Aperçu PDF';

  @override
  String get tevPaperDirection => 'Orientation du papier';

  @override
  String get tevWidthCm => 'Largeur (cm)';

  @override
  String get tevHeightCm => 'Hauteur (cm)';

  @override
  String get tevUndo => 'Annuler (Ctrl+Z)';

  @override
  String get tevRedo => 'Rétablir (Ctrl+Y)';

  @override
  String get tevSnapGrid => 'Grille magnétique';

  @override
  String get tevGuidesOn => 'Repères intelligents : activés (désactiver)';

  @override
  String get tevGuidesOff => 'Repères intelligents : désactivés (activer)';

  @override
  String get tevZoom => 'Zoom';

  @override
  String get tevDocumentBackground => 'Arrière-plan du document';

  @override
  String get tevFrameFromLibrary => 'Cadre depuis ma bibliothèque';

  @override
  String get tevChangeTitle => 'Changer le titre du modèle';

  @override
  String get tevMyTemplates => 'Mes modèles';

  @override
  String get tevSaveAs => 'Enregistrer sous';

  @override
  String get tevSaveTemplate => 'Enregistrer le modèle';

  @override
  String get tevSaveUnavailable => 'Enregistrement indisponible';

  @override
  String get tevSaveNeedsSupabase =>
      'L’enregistrement nécessite une connexion à un projet Supabase. Lancez l’application avec vos clés (env.json) pour enregistrer des modèles.';

  @override
  String tevMissingAssets(Object list) {
    return 'Ressources manquantes : $list — resélectionnez le cadre/la ressource dans « Ma bibliothèque » pour éviter les vides.';
  }

  @override
  String get tevTemplateLibraryNeedsSupabase =>
      'La bibliothèque de modèles nécessite une connexion à un projet Supabase.';

  @override
  String tevOpenedTemplate(Object title) {
    return '« $title » a été ouvert.';
  }

  @override
  String get tevTitleHint =>
      'ex. : certificat d’achèvement du cours de gestion de projet';

  @override
  String get tevContinue => 'Continuer';

  @override
  String get tevSavedTemplates => 'Mes modèles enregistrés';

  @override
  String get tevNoSavedTemplates =>
      'Aucun modèle enregistré. Enregistrez-en un via le bouton « Enregistrer le modèle ».';

  @override
  String get ecIncrease => 'Augmenter';

  @override
  String get ecDecrease => 'Diminuer';

  @override
  String get ecQuickPalette => 'Palette rapide';

  @override
  String get ecFullPicker => 'Sélecteur de couleurs complet';

  @override
  String get ecRemoveColor => 'Supprimer la couleur';

  @override
  String get ecNone => 'Aucun';

  @override
  String get ecPickColorTitle => 'Choisir une couleur';

  @override
  String get ecApply => 'Appliquer';

  @override
  String tevBackgroundAdded(Object name) {
    return '« $name » a été ajouté comme arrière-plan du document.';
  }

  @override
  String get cfpUploadTooltip =>
      'Importer une police personnalisée (.ttf / .otf)';

  @override
  String get cfpManageTooltip => 'Gérer les polices importées';

  @override
  String get cfpNotice =>
      'Les polices importées sont enregistrées sur votre appareil uniquement et utilisées immédiatement ici et à l’impression — sans internet.';

  @override
  String get cfpMyFonts => 'Mes polices personnalisées';

  @override
  String get cfpNoFonts => 'Aucune police importée';

  @override
  String get cfpBuiltinOption => 'Aucune (police intégrée)';

  @override
  String get cfpGroupBuiltin => 'Polices intégrées';

  @override
  String get cfpGroupUploaded => 'Mes polices importées';

  @override
  String get cfpGroupSystem => 'Polices système';

  @override
  String get cfpSearchHint => 'Rechercher des polices…';

  @override
  String get cfpNoMatch => 'Aucune police correspondante.';

  @override
  String get cfpPickTitle => 'Choisir un fichier de police (TTF ou OTF)';

  @override
  String cfpPickerError(Object error) {
    return 'Impossible d’ouvrir le sélecteur de fichiers : $error';
  }

  @override
  String cfpReadError(Object name, Object error) {
    return 'Impossible de lire « $name » : $error';
  }

  @override
  String get cfpFontAdded =>
      'La police a été ajoutée et appliquée immédiatement.';

  @override
  String cfpFontsAdded(Object count) {
    return '$count polices ont été ajoutées.';
  }

  @override
  String get cfpLibraryTitle => 'Ma bibliothèque de polices';

  @override
  String get cfpLibraryNotice =>
      'Toutes les polices sont enregistrées uniquement sur votre appareil. Attention : supprimer une police utilisée par un modèle ramène ce modèle à la police intégrée au lieu d’échouer.';

  @override
  String get cfpEmpty => 'Aucune police importée.';

  @override
  String get cfpCoverageFull => 'Couverture arabe complète';

  @override
  String get cfpCoveragePartial => 'Couverture arabe partielle';

  @override
  String get cfpUploadNew => 'Importer une nouvelle police';

  @override
  String get ptpPrepError =>
      'Impossible de préparer l’aperçu. Vérifiez le fichier du modèle.';

  @override
  String ptpElapsedSize(Object ms, Object kb) {
    return '$ms ms — $kb Ko';
  }

  @override
  String get ptpGeneratingNote => '— l’aperçu se met à jour automatiquement';

  @override
  String get ptpGenerateFailedTitle => 'Impossible de générer l’aperçu';

  @override
  String get ptpPreparingTitle => 'Préparation du moteur…';

  @override
  String get ptpPreparingMessage =>
      'Les polices intégrées sont chargées et la première version du fichier est générée.';

  @override
  String get ptpShowFailedTitle => 'Impossible d’afficher l’aperçu';

  @override
  String cfgOverride(Object override) {
    return 'Une compilation alternative avec des valeurs explicites remplace le fichier : $override';
  }

  @override
  String get tevBackgroundTitle =>
      'Arrière-plan du document depuis ma bibliothèque';

  @override
  String get tevAddElement => 'Ajouter un élément';

  @override
  String get commonUndo => 'Annuler';

  @override
  String get bpTitle => 'Génération en masse depuis Excel';

  @override
  String get bpSubtitle =>
      'Importez un fichier .xlsx ou .csv, associez ses colonnes aux champs du modèle, puis générez un PDF avec une page par enregistrement — le tout sur votre appareil, hors ligne.';

  @override
  String get bpStepTemplate => '1) Modèle';

  @override
  String get bpLoadingSampleTemplate => 'Chargement du modèle d’exemple…';

  @override
  String bpTemplateInfo(Object name) {
    return 'Modèle : $name • champs requis :';
  }

  @override
  String get bpLoadingTemplates => 'Chargement de vos modèles…';

  @override
  String get bpNoTemplates =>
      'Aucun modèle enregistré — créez-en un dans l’éditeur ou importez-le depuis la bibliothèque de modèles.';

  @override
  String get bpTemplateFromMine => 'Modèle depuis mes modèles';

  @override
  String get bpSampleTemplatesHeader => '— modèles d’exemple —';

  @override
  String bpTemplateEntry(Object title, Object source) {
    return '$title  •  $source';
  }

  @override
  String get bpSourceCloud => 'Cloud';

  @override
  String get bpSourceLocal => 'Local';

  @override
  String get bpStepDataFile => '2) Fichier de données';

  @override
  String get bpReadingFile => 'Lecture du fichier…';

  @override
  String get bpNoFileChosen =>
      'Aucun fichier choisi — formats pris en charge :';

  @override
  String bpFileSummary(Object name, Object rows, Object cols) {
    return '$name — $rows lignes, $cols colonnes';
  }

  @override
  String bpSheetSuffix(Object name) {
    return ' (feuille : $name)';
  }

  @override
  String get bpChooseFile => 'Choisir un fichier';

  @override
  String get bpRemove => 'Retirer';

  @override
  String get bpHeaderRow => 'Ligne d’en-tête';

  @override
  String bpAutoRow(Object n) {
    return 'Automatique (ligne $n)';
  }

  @override
  String bpRow(Object n) {
    return 'Ligne $n';
  }

  @override
  String bpAutoRowLong(Object n) {
    return 'Automatique — ligne $n';
  }

  @override
  String bpRowPreview(Object n, Object preview) {
    return 'Ligne $n : $preview';
  }

  @override
  String get bpEmptyRow => '(ligne vide)';

  @override
  String get bpWorksheet => 'Feuille de calcul';

  @override
  String get bpPickDataFile => 'Choisir le fichier de données (Excel ou CSV)';

  @override
  String bpReadFileError(Object error) {
    return 'Impossible de lire le fichier : $error';
  }

  @override
  String bpFileReadRows(Object rows, Object cols) {
    return 'Le fichier a été lu localement : $rows lignes et $cols colonnes.';
  }

  @override
  String bpSaveError(Object error) {
    return 'Impossible d’enregistrer la modification dans le modèle : $error';
  }

  @override
  String get bpMapFieldTitle => 'Associer un champ dynamique à cet élément';

  @override
  String get bpMapFieldBody =>
      'Seul le texte de cet élément sera remplacé par un champ ; aucun autre élément n’est touché.';

  @override
  String get bpUndoConvert => 'La conversion a été annulée.';

  @override
  String get bpUndoConvertSaved =>
      'La conversion a été annulée et le texte restauré dans le modèle.';

  @override
  String bpRestoreError(Object error) {
    return 'Impossible de restaurer le texte dans le modèle : $error';
  }

  @override
  String bpGeneratedReport(Object count) {
    return '$count enregistrement(s) généré(s)';
  }

  @override
  String bpSkippedSuffix(Object count) {
    return ' et $count ignoré(s)';
  }

  @override
  String get bpReadyToSave => 'Le fichier est prêt à être enregistré.';

  @override
  String get bpStepMapping => '3) Associer les colonnes aux champs';

  @override
  String get bpChooseFileFirst =>
      'Choisissez d’abord un fichier pour afficher la table d’association.';

  @override
  String get bpNoDynamicFields =>
      'Aucun champ dynamique dans le modèle actuel.';

  @override
  String bpMappedCount(Object mapped, Object total) {
    return '$mapped sur $total colonnes associées';
  }

  @override
  String get bpAutoMapHint =>
      'Après avoir choisi le fichier, une association automatique intelligente est proposée ; vous pouvez modifier chaque colonne.';

  @override
  String get bpNoFieldsHelp =>
      'Le modèle choisi n’a pas de champs dynamiques : rien à associer aux colonnes du fichier. Ouvrez le modèle dans l’éditeur, insérez un « champ dynamique » dans l’emplacement du nom, enregistrez, puis réessayez.';

  @override
  String get bpAutoMap => 'Association auto';

  @override
  String get bpClearMapping => 'Effacer l’association';

  @override
  String get bpNameFieldWarning =>
      'Ce modèle n’a pas de champ de nom dynamique — n’associez pas la colonne du nom à un champ date ou référence, sinon le nom risque d’être imprimé au mauvais endroit. Choisissez la clé du nom dans la liste de la colonne, ou convertissez le texte du nom fixe dans l’éditeur en champ dynamique.';

  @override
  String bpStaticNameHints(Object preview) {
    return 'Texte fixe qui ressemble à un nom : « $preview » — aucun champ dynamique ne le remplace.';
  }

  @override
  String get bpConvertToNameField => 'Convertir en champ de nom de stagiaire';

  @override
  String bpDuplicateField(Object field) {
    return 'Le champ « $field » est associé à plusieurs colonnes. Associez chaque champ à une seule colonne.';
  }

  @override
  String bpUnmappedColumns(Object count) {
    return '$count colonne(s) non associée(s) — leurs données ne seront pas utilisées dans les certificats.';
  }

  @override
  String bpColumn(Object n) {
    return 'Colonne $n';
  }

  @override
  String get bpEmptyCell => '(vide)';

  @override
  String get bpUnmapped => '— non associé —';

  @override
  String get bpStepMissing => '4) Cellules vides et données manquantes';

  @override
  String get bpNoNotes => 'Aucune note avant de choisir le fichier.';

  @override
  String get bpStepGenerate => '5) Génération';

  @override
  String bpGenerating(Object progress) {
    return 'Génération… $progress';
  }

  @override
  String get bpGenerateHint =>
      'Un seul fichier PDF, une page par enregistrement généré.';

  @override
  String get bpGeneratePickFile =>
      'Choisissez d’abord un fichier de données pour activer la génération.';

  @override
  String get bpMappingInvalid =>
      'L’association est invalide — le même champ est associé à deux colonnes.';

  @override
  String get bpMapAtLeastOne =>
      'Associez au moins une colonne à un champ du modèle pour activer la génération.';

  @override
  String get bpGenerateCertificates => 'Générer les certificats';

  @override
  String get bpRegenerate => 'Régénérer';

  @override
  String get bpStatGenerated => 'Générés';

  @override
  String get bpStatSkipped => 'Ignorés';

  @override
  String get bpStatPages => 'Pages';

  @override
  String get bpStatSize => 'Taille';

  @override
  String bpKilobytes(Object value) {
    return '$value Ko';
  }

  @override
  String get bpStatTime => 'Temps';

  @override
  String bpMilliseconds(Object value) {
    return '$value ms';
  }

  @override
  String bpCompletion(Object pct, Object total) {
    return '$pct% de $total lignes traitées.';
  }

  @override
  String get bpSkippedRows => 'Lignes non générées :';

  @override
  String bpRowSkipReason(Object n, Object reason) {
    return 'Ligne $n : $reason';
  }

  @override
  String get bpPreviewHere => 'L’aperçu s’affiche ici';

  @override
  String get bpPreviewHint =>
      'Choisissez le fichier de données, ajustez l’association, puis appuyez sur « Générer les certificats » — la première page du fichier généré s’affichera ici.';

  @override
  String get bpAssignByTapTitle => 'Assigner les champs en touchant';

  @override
  String get bpAssignByTapBody =>
      'Touchez n’importe quel texte du modèle pour l’associer vous-même à un champ dynamique. Aucun autre élément n’est touché — ni la date, ni le nom du directeur, ni aucun texte fixe.';

  @override
  String get bpNoTexts => 'Aucun texte dans ce modèle.';

  @override
  String get bpEmptyText => '(texte vide)';

  @override
  String get bpDynamicFieldTap => 'Champ dynamique — touchez pour changer';

  @override
  String get bpStaticTextTap => 'Texte fixe — touchez pour assigner';

  @override
  String get bpAssignField => 'Assigner un champ';

  @override
  String get bpKindCertificate => 'Certificat';

  @override
  String get bpKindContract => 'Contrat';

  @override
  String bpLoadSampleError(Object error) {
    return 'Impossible de charger le modèle d’exemple : $error';
  }

  @override
  String bpReadSheetError(Object error) {
    return 'Impossible de lire la feuille : $error';
  }

  @override
  String bpUpdateHeaderRowError(Object error) {
    return 'Impossible de mettre à jour la ligne d’en-tête : $error';
  }

  @override
  String get bpChooseTemplateFirst =>
      'Choisissez un modèle (certificat ou contrat) avant de générer.';

  @override
  String bpBatchTitle(Object kind) {
    return '$kind en masse — JoodCraft';
  }

  @override
  String bpGenerateError(Object error) {
    return 'Impossible d’exécuter la génération en masse : $error';
  }

  @override
  String get bpWarnNoDynamicFields =>
      'Ce modèle n’a pas de champs dynamiques — les données ne changeront pas d’un enregistrement à l’autre. Ajoutez un champ « nom du stagiaire » depuis la barre de l’éditeur, puis enregistrez le modèle.';

  @override
  String get bpWarnNoNameField =>
      'Ce modèle n’a pas de champ de nom dynamique — la colonne du nom pourrait être associée à un champ date ou référence et le nom s’imprimer au mauvais endroit. Convertissez le texte de nom fixe en champ ou refaites le modèle.';

  @override
  String bpAssignedTemp(Object token) {
    return 'Cet élément a été associé à $token pour la génération en cours — les autres éléments ne sont pas touchés. Enregistrez le modèle pour conserver la modification.';
  }

  @override
  String bpAssignedSaved(Object token) {
    return 'Cet élément a été associé à $token et la modification a été enregistrée dans le modèle. Les autres éléments ne sont pas touchés.';
  }

  @override
  String get commonShow => 'Afficher';

  @override
  String get commonHide => 'Masquer';

  @override
  String get themeSwitchToLight => 'Passer au thème clair';

  @override
  String get themeSwitchToDark => 'Passer au thème sombre';

  @override
  String commonComingSoonPhase(Object phase) {
    return 'En cours — phase $phase';
  }

  @override
  String get cbNewCertificateTitle => 'Nouveau certificat';

  @override
  String get cbNewContractTitle => 'Nouveau contrat';

  @override
  String get cbBeneficiaryDataTitle => 'Données du bénéficiaire (exemple)';

  @override
  String get cbContractDataTitle => 'Données du contrat (exemple)';

  @override
  String get editorSendBackward => 'Reculer';

  @override
  String get editorRotateLeft => 'Pivoter 90° à gauche';

  @override
  String get editorRotateRight => 'Pivoter 90° à droite';

  @override
  String get editorFlipH => 'Miroir horizontal';

  @override
  String get editorFlipV => 'Miroir vertical';

  @override
  String get editorTransform => 'Transformations';

  @override
  String get editorToolSelect => 'Sélection';

  @override
  String get editorToolShapes => 'Formes';

  @override
  String get editorFillType => 'Type de remplissage';

  @override
  String get editorFillSolid => 'Uni';

  @override
  String get editorGradientLinear => 'Dégradé linéaire';

  @override
  String get editorGradientRadial => 'Dégradé radial';

  @override
  String get editorGradientAngle => 'Angle du dégradé';

  @override
  String get editorShadowEnable => 'Ajouter une ombre';

  @override
  String get editorShadowColor => 'Couleur de l\'ombre';

  @override
  String get editorShadowBlur => 'Flou de l\'ombre';

  @override
  String get editorShadowOffsetX => 'Décalage X';

  @override
  String get editorShadowOffsetY => 'Décalage Y';

  @override
  String get editorShadowSpread => 'Propagation';

  @override
  String get editorShadowRemove => 'Supprimer l\'ombre';

  @override
  String get editorPoints => 'Points';

  @override
  String get editorInnerRadius => 'Rayon interne';

  @override
  String get editorCornerTopLeft => 'Haut gauche';

  @override
  String get editorCornerTopRight => 'Haut droite';

  @override
  String get editorCornerBottomRight => 'Bas droite';

  @override
  String get editorCornerBottomLeft => 'Bas gauche';

  @override
  String get editorDashPattern => 'Motif de tirets';

  @override
  String get editorBooleanOps => 'Opérations booléennes';

  @override
  String get editorBooleanUnion => 'Fusionner';

  @override
  String get editorBooleanSubtract => 'Soustraire';

  @override
  String get editorBooleanIntersect => 'Intersection';

  @override
  String get editorBooleanUngroup => 'Séparer';

  @override
  String get paletteStar => 'Étoile';

  @override
  String get palettePolygon => 'Polygone';

  @override
  String get editorBooleanExclude => 'Exclusion';

  @override
  String get editorBooleanHint =>
      'Le tracé fusionné est un seul résultat booléen (sans bordures internes) et peut être séparé à tout moment.';

  @override
  String get editorDockTools => 'Panneau d\'outils';

  @override
  String get editorDockAnchor => 'Position d\'ancrage';

  @override
  String get editorDockTopBar => 'Barre supérieure';

  @override
  String get editorDockInspector => 'Panneau latéral';

  @override
  String get editorDockLeftRail => 'Rail latéral';

  @override
  String get editorDockFloating => 'Flottant';

  @override
  String get editorDockCollapse => 'Réduire les outils';

  @override
  String get editorDockExpand => 'Développer les outils';

  @override
  String get editorDockResize => 'Glisser pour redimensionner';

  @override
  String get editorDockDropHint => 'Relâchez pour ancrer à';

  @override
  String get editorMoreTools => 'Autres outils';

  @override
  String get editorDocumentProperties => 'Propriétés du document';

  @override
  String get editorDockReset => 'Rétablir l\'ancrage par défaut';

  @override
  String get editorTextShadow => 'Ombre du texte';

  @override
  String get editorTextShadowAdd => 'Ajouter une ombre au texte';

  @override
  String get editorShadowOpacity => 'Opacité de l\'ombre';

  @override
  String get genderMale => 'Masculin';

  @override
  String get genderFemale => 'Féminin';

  @override
  String get genderPreviewAutoHint =>
      'Cliquer pour annuler le forçage (automatique)';

  @override
  String get genderPresetCompleted => '« completed » (m./f.)';

  @override
  String get genderPresetPassed => '« passed » (m./f.)';

  @override
  String get genderPresetForStudent => '« pour l\'étudiant » (m./f.)';

  @override
  String get genderPresetStudent => '« l\'étudiant » (m./f.)';

  @override
  String get genderPresetToHim => '« à lui / à elle »';

  @override
  String get genderPresetHonoring => '« le stagiaire distingué » (m./f.)';

  @override
  String get editorGenderSnippet => 'Insérer un segment conditionnel';

  @override
  String get editorGenderSnippetHint =>
      'Insère une phrase qui change automatiquement selon le genre du bénéficiaire.';

  @override
  String get bpGenderReviewTitle => 'Vérification du genre (masculin/féminin)';

  @override
  String get bpGenderReviewSubtitle =>
      'Le genre est détecté à partir du nom ou d\'une colonne « Genre » — corrigez les cas limites avant l\'impression.';

  @override
  String get bpGenderRow => 'Ligne';

  @override
  String get bpGenderDetected => 'Détecté';

  @override
  String get bpGenderEffective => 'Appliqué';

  @override
  String get bpGenderNameColumn => 'Nom';

  @override
  String get bpGenderEditName => 'Modifier le nom';

  @override
  String get bpGenderNameHint => 'Saisissez le nom correct';

  @override
  String get bpGenderClearOverrides => 'Effacer les corrections';

  @override
  String get bpGenderOverridden => 'Corrigé manuellement';

  @override
  String get bpGenderUnknownName => '—';

  @override
  String get bpOutputTitle => 'Destination d\'enregistrement des certificats';

  @override
  String get bpOutputHint =>
      'Choisissez le dossier où enregistrer le PDF généré, ou démarrez à l\'emplacement par défaut.';

  @override
  String get bpOutputPickFolder => 'Choisir un dossier…';

  @override
  String get bpOutputStart => 'Lancer la génération';

  @override
  String get bpOutputPathLabel => 'Dossier sélectionné';

  @override
  String get bpOutputNoFolder =>
      'Aucun dossier sélectionné — impression et export uniquement.';

  @override
  String get bpOpenFolder => 'Ouvrir le dossier';

  @override
  String get bpOutputSavedTitle => 'Fichier PDF enregistré';

  @override
  String get bpOpenFolderFailed => 'Impossible d\'ouvrir le dossier.';

  @override
  String get bpOutputNameLabel => 'Nom du fichier d\'export';

  @override
  String get bpOutputNameHint => 'Saisissez un nom sans extension';

  @override
  String get bpOutputNamePreviewLabel => 'Sera enregistré sous';

  @override
  String get bpOutputModeLabel => 'Mode d\'enregistrement';

  @override
  String get bpOutputModeCombined => 'Fichier unique combiné';

  @override
  String get bpOutputModeIndividual => 'Un fichier par personne';

  @override
  String get hubTitle => 'Nouveau projet';

  @override
  String get hubSubtitle =>
      'Choisissez un format prêt ou définissez le vôtre — le canevas s\'ouvre au format et au ratio exacts.';

  @override
  String get hubKindSingle => 'Impressions et documents d\'une page';

  @override
  String get hubKindMulti => 'Livres et publications multipages';

  @override
  String get hubKindSingleHint =>
      'Une page : certificats, contrats, cartes, numéros de place, cartes de vœux.';

  @override
  String get hubKindMultiHint =>
      'Multipage : livre, magazine, brochure, rapport, catalogue.';

  @override
  String get hubGroupCertificates => 'Certificats et contrats';

  @override
  String get hubGroupCards => 'Cartes et badges d\'identité';

  @override
  String get hubGroupSeat => 'Numéros de place et étiquettes';

  @override
  String get hubGroupGreeting => 'Cartes de vœux';

  @override
  String get hubGroupPublications => 'Livres et publications';

  @override
  String get hubGroupCustom => 'Format personnalisé';

  @override
  String get hubDigitalBadge => 'Numérique';

  @override
  String get hubCreate => 'Créer';

  @override
  String get hubCustomCardBody =>
      'Saisissez vos dimensions dans l\'unité de votre choix pour démarrer à votre format.';

  @override
  String get hubCustomName => 'Nom du projet';

  @override
  String get hubCustomNameHint => 'ex. Carte d\'invitation';

  @override
  String get hubCustomPreview => 'Format final';

  @override
  String get hubCustomCreate => 'Créer le canevas';

  @override
  String get hubCustomType => 'Type de projet';

  @override
  String get hubSearchHint => 'Rechercher un format…';

  @override
  String get hubNoResults =>
      'Aucun format correspondant — essayez un autre mot-clé.';

  @override
  String get hubAspectRatio => 'Ratio';

  @override
  String get destNewProject => 'Nouveau projet';

  @override
  String get destNewProjectDesc =>
      'Choisissez un format prêt ou personnalisé et commencez tout de suite.';

  @override
  String get ptpImpositionToggle => 'Imposition d\'impression';

  @override
  String get ptpImpositionNoFit =>
      'La feuille est trop petite pour cet élément : réduisez les marges ou choisissez une feuille plus grande.';

  @override
  String get editorEffectsTitle => 'Effets et réglages colorimétriques';

  @override
  String get editorShadowGroup => 'Ombre';

  @override
  String get editorOuterGlow => 'Lueur externe';

  @override
  String get editorInnerGlow => 'Lueur interne';

  @override
  String get editorGlowAdd => 'Ajouter une lueur';

  @override
  String get editorGlowRemove => 'Supprimer la lueur';

  @override
  String get editorGlowColor => 'Couleur de la lueur';

  @override
  String get editorGlowRadius => 'Rayon de la lueur';

  @override
  String get editorGlowSpread => 'Propagation de la lueur';

  @override
  String get editorGlowOpacity => 'Opacité de la lueur';

  @override
  String get editorAdjustGroup => 'Réglages colorimétriques';

  @override
  String get editorAdjustBrightness => 'Luminosité';

  @override
  String get editorAdjustContrast => 'Contraste';

  @override
  String get editorAdjustSaturation => 'Saturation';

  @override
  String get editorAdjustHue => 'Teinte';

  @override
  String get editorAdjustReset => 'Réinitialiser';

  @override
  String get bpOutputSavedFolderTitle =>
      'Fichiers enregistrés dans un dossier dédié';

  @override
  String get hubDetailsTitle => 'Détails du format';

  @override
  String get hubDetailsHint =>
      'Spécification par défaut pré-remplie — choisissez un format dans la grille ou modifiez les dimensions.';

  @override
  String get hubFilterAll => 'Tout';

  @override
  String get hubFilterRecent => 'Formats récents';

  @override
  String get hubFilterSeat => 'Numéros de siège';

  @override
  String get hubFilterGreeting => 'Vœux et écrans';

  @override
  String get hubRecentEmpty =>
      'Aucun format récent — tout projet créé apparaîtra ici.';

  @override
  String get hubDocTitle => 'Nom du projet';

  @override
  String get hubDocTitleHint => 'Nouveau projet - 1';

  @override
  String get hubWidth => 'Largeur';

  @override
  String get hubHeight => 'Hauteur';

  @override
  String get hubUnitLabel => 'Unité';

  @override
  String get hubOrientationLabel => 'Orientation';

  @override
  String get hubPortrait => 'Portrait';

  @override
  String get hubLandscape => 'Paysage';

  @override
  String get hubVariantLabel => 'Type';

  @override
  String get hubResolutionLabel => 'Résolution';

  @override
  String get hubResolutionUnitLabel => 'Unité de résolution';

  @override
  String get hubColorModeLabel => 'Mode colorimétrique';

  @override
  String get hubBackgroundLabel => 'Couleur de fond';

  @override
  String get hubBackgroundWhite => 'Blanc';

  @override
  String get hubBackgroundTransparent => 'Transparent';

  @override
  String get hubBackgroundBlack => 'Noir';

  @override
  String get hubBackgroundCustom => 'Couleur personnalisée';

  @override
  String get hubCreateProject => 'Créer le projet';

  @override
  String get hubCustomFamilyTitle => 'Format personnalisé';

  @override
  String get newDocTitle => 'Nouveau document';

  @override
  String get newDocScopeSocial => 'Écrans et vœux';

  @override
  String get newDocFilterCertificates => 'Certificats';

  @override
  String get newDocFilterCards => 'Cartes';

  @override
  String get newDocFilterGreeting => 'Vœux';

  @override
  String get newDocFilterPublications => 'Publications';

  @override
  String get menuFile => 'Fichier';

  @override
  String get menuEdit => 'Édition';

  @override
  String get menuView => 'Affichage';

  @override
  String get menuTools => 'Outils';

  @override
  String get menuHelp => 'Aide';

  @override
  String get menuNewDocument => 'Nouveau document…';

  @override
  String get menuPurgeRecent => 'Vider les tailles récentes';

  @override
  String get menuPurgeImageCache => 'Vider le cache des images';

  @override
  String get menuPreviewCertificate => 'Aperçu du certificat type';

  @override
  String get menuPreviewContract => 'Aperçu du contrat type';

  @override
  String get menuAbout => 'À propos de JoodCraft';

  @override
  String get actionNewShort => '+ Nouveau';

  @override
  String get dashLocalMode => 'Local';

  @override
  String get dashLocalStorage =>
      'Enregistré localement sur cet appareil — aucun projet n\'est envoyé à un serveur.';

  @override
  String get dashRecentProjects => 'Projets récents';

  @override
  String get dashRecentEmpty =>
      'Aucun projet enregistré sur cet appareil — créez un document et il apparaîtra ici aussitôt.';

  @override
  String get dashRecentOpen => 'Ouvrir le projet';

  @override
  String get editorTransformPosition => 'Transformation et position';

  @override
  String get editorTransformPositionHint =>
      'Position, taille et angle de rotation';

  @override
  String get editorAppearanceEffects => 'Apparence et effets';

  @override
  String get editorAppearanceEffectsHint =>
      'Remplissage, contour, lueur et ombres';

  @override
  String get editorTypographyHint => 'Police, taille, alignement et espacement';

  @override
  String get editorPageSettingsHint => 'Taille et unité de mesure';

  @override
  String get editorBackgroundHint => 'Couleur ou dégradé de la page';

  @override
  String get editorPrecisionHint => 'Déplacement précis et mise à l\'échelle';

  @override
  String get joodExportProject => 'Exporter le projet (.jood)';

  @override
  String get joodImportProject => 'Ouvrir le projet (.jood)';

  @override
  String get joodExportReady =>
      'Le fichier du projet est prêt à être enregistré.';

  @override
  String get joodExportFailed => 'Impossible d\'exporter le fichier du projet.';

  @override
  String get joodImportOpened => 'Projet importé ouvert.';

  @override
  String get joodImportFailed => 'Impossible d\'ouvrir le fichier du projet.';

  @override
  String get joodRecoveryTitle => 'Brouillon non enregistré';

  @override
  String get joodRecoveryMessage =>
      'Un brouillon non enregistré d\'une session précédente existe. Voulez-vous le restaurer ?';

  @override
  String get joodRecoveryRestore => 'Restaurer';

  @override
  String get joodRecoveryDiscard => 'Ignorer';

  @override
  String get joodRecoveryRestored => 'Brouillon restauré.';

  @override
  String get joodAutosaveSaved => 'Enregistré automatiquement';

  @override
  String get joodAutosaveSaving => 'Enregistrement…';

  @override
  String get editorConfirm => 'Confirmer';

  @override
  String get admTitle => 'Gestion locale des administrateurs';

  @override
  String get admRefresh => 'Actualiser';

  @override
  String get admTabAdmins => 'Administrateurs';

  @override
  String get admTabTransfer => 'Transfert entre appareils';

  @override
  String get admTabAudit => 'Journal d\'export';

  @override
  String get admListTitle => 'Comptes administrateurs sur cet appareil';

  @override
  String get admAdd => 'Ajouter un administrateur';

  @override
  String get admNoAdmins => 'Aucun compte administrateur pour l\'instant.';

  @override
  String get admLoading =>
      'Chargement des comptes administrateurs de cet appareil…';

  @override
  String get admRoleOwner => 'Administrateur principal';

  @override
  String get admCurrent => 'Vous';

  @override
  String get admCurrentCardTitle => 'Compte actuel sur cet appareil';

  @override
  String get admRoleAdmin => 'Administrateur';

  @override
  String get admSwitchTitle => 'Changement rapide de compte';

  @override
  String get admSwitchPrompt =>
      'Choisissez le nom d\'utilisateur local d\'un sous-administrateur de cet appareil et saisissez son mot de passe local pour basculer immédiatement vers sa session — les brouillons de projets ouverts sont enregistrés d\'abord, et la licence principale n\'est pas affectée.';

  @override
  String get admSwitchNoOthers =>
      'Aucun autre sous-administrateur sur cet appareil. Ajoutez d\'abord un administrateur depuis l\'écran des administrateurs.';

  @override
  String get admSwitchPick => 'Nom d\'utilisateur local';

  @override
  String get admSwitchPassword => 'Mot de passe local du compte sélectionné';

  @override
  String get admSwitchPickPassword =>
      'Choisissez un nom d’utilisateur et saisissez le mot de passe.';

  @override
  String get admSwitchWrongPassword => 'Mot de passe incorrect.';

  @override
  String get admSwitchFailed => 'Impossible de changer de compte. Réessayez.';

  @override
  String get admSwitchSuccess => 'Compte changé avec succès.';

  @override
  String get admSwitchAccount => 'Changer de compte';

  @override
  String get admSwitchAction => 'Basculer maintenant';

  @override
  String get admColAdmin => 'Administrateur';

  @override
  String get admColUsername => 'Nom d\'utilisateur local';

  @override
  String get admColRole => 'Rôle';

  @override
  String get admColCreated => 'Ajouté le';

  @override
  String get admColActions => 'Actions';

  @override
  String get destJoodWriter => 'Jood Writer';

  @override
  String get destJoodWriterDesc =>
      'Documents et rapports texte à pagination automatique.';

  @override
  String get admCreatedAt => 'Créé';

  @override
  String get admEdit => 'Modifier les données';

  @override
  String get admChangePassword => 'Changer le mot de passe';

  @override
  String get admPromote => 'Promouvoir en administrateur principal';

  @override
  String get admDemote => 'Rétrograder en administrateur';

  @override
  String get admDelete => 'Supprimer le compte';

  @override
  String admDeleteConfirm(Object name) {
    return '« $name » sera définitivement supprimé de cet appareil. Action irréversible.';
  }

  @override
  String get admPromoted => 'Promu administrateur principal.';

  @override
  String get admDemoted => 'Rétrogradé en administrateur.';

  @override
  String get admDeleted => 'Compte supprimé.';

  @override
  String get admCreated => 'Nouvel administrateur ajouté.';

  @override
  String get admUpdated => 'Données de l\'administrateur mises à jour.';

  @override
  String get admPasswordChanged => 'Mot de passe modifié.';

  @override
  String get admTransferInfoTitle => 'Comment fonctionne le transfert ?';

  @override
  String get admTransferInfo1 =>
      'Le tableau des comptes (avec les empreintes des mots de passe, jamais les mots de passe) est exporté dans un fichier chiffré par une phrase secrète que vous choisissez.';

  @override
  String get admTransferInfo2 =>
      'Déplacez le fichier ou le code vers l\'autre appareil et importez-le avec la même phrase secrète : les comptes fonctionnent avec les mêmes droits.';

  @override
  String get admTransferInfo3 =>
      'Rien n\'est envoyé à un serveur : le transfert est entièrement manuel entre appareils locaux.';

  @override
  String get admExport => 'Exporter les comptes';

  @override
  String get admExportPassphrase => 'Phrase secrète d\'export';

  @override
  String get admPassphraseConfirm => 'Confirmer la phrase secrète';

  @override
  String get admExportRisk =>
      'Je comprends que quiconque possède ce code et sa phrase secrète peut se connecter avec ces comptes ; je le partagerai avec prudence.';

  @override
  String get admExportGenerate => 'Générer le code chiffré';

  @override
  String get admExportFile => 'Enregistrer dans un fichier dédié';

  @override
  String get admExportDone =>
      'Code chiffré généré. Copiez-le ou enregistrez-le dans un fichier.';

  @override
  String get admExportFileSaved => 'Fichier de comptes chiffré enregistré.';

  @override
  String get admPassphraseTooShort =>
      'Utilisez au moins 6 caractères pour la phrase secrète.';

  @override
  String get admPassphraseMismatch =>
      'Les phrases secrètes ne correspondent pas.';

  @override
  String get admAcceptRiskRequired =>
      'Confirmez d\'abord que vous comprenez le risque de partager le code.';

  @override
  String admFileError(Object error) {
    return 'Impossible de traiter le fichier : $error';
  }

  @override
  String get admImport => 'Importer des comptes';

  @override
  String get admImportCode => 'Code des comptes';

  @override
  String get admImportPassphrase => 'Phrase secrète du fichier';

  @override
  String get admImportReplace =>
      'Remplacer les mots de passe des comptes existants';

  @override
  String get admImportPick => 'Choisir un fichier';

  @override
  String get admImportRun => 'Importer maintenant';

  @override
  String get admImportCodeRequired =>
      'Collez d\'abord le code ou choisissez un fichier.';

  @override
  String get admImportPassphraseRequired =>
      'Saisissez la phrase secrète du fichier.';

  @override
  String admImportDone(int added, int updated, int skipped) {
    return 'Importation : $added nouveaux, $updated mis à jour, $skipped ignorés.';
  }

  @override
  String get admAuditTitle => 'Journal des certificats et documents délivrés';

  @override
  String get admAuditClear => 'Vider le journal';

  @override
  String get admAuditEmpty =>
      'Aucun export pour l\'instant. Chaque certificat ou contrat exporté sera consigné ici avec sa date et l\'administrateur qui l\'a délivré.';

  @override
  String get admAuditBy => 'Par';

  @override
  String get admAuditPages => 'pages';

  @override
  String get admAuditClearConfirm =>
      'Tout le journal d\'export sera supprimé de cet appareil. Action irréversible.';

  @override
  String get admAuditCleared => 'Journal vidé.';

  @override
  String get admUnavailableTitle =>
      'La gestion est indisponible pour le moment';

  @override
  String get admUnavailableBody =>
      'La gestion des administrateurs fonctionne lorsque l\'application tourne avec un compte local (LocalAuthRepository) : les comptes sont alors lus depuis cet appareil.';

  @override
  String get pdfExportTypeTitle => 'Type d\'export';

  @override
  String get pdfExportTypeHint =>
      'Choisissez le format du fichier avant d\'exporter.';

  @override
  String get pdfExportTypeImages => 'Images';

  @override
  String get pdfExportTypeImagesDesc =>
      'Correspondance à 100 % — fichier plus volumineux';

  @override
  String get pdfExportTypeImagesNotCopyable => 'Le texte n\'est pas copiable';

  @override
  String get pdfExportTypeVector => 'Vecteur';

  @override
  String get pdfExportTypeVectorDesc => 'Texte copiable — fichier plus léger';

  @override
  String get pdfExportTypeVectorCopyable => 'Texte copiable et recherchable';

  @override
  String get bpPdfEngineLabel => 'Moteur de rendu';

  @override
  String get pdfExportTypeVectorBestFor =>
      'Idéal pour l\'impression professionnelle';

  @override
  String get invCategoryTitle => 'Invitations et occasions';

  @override
  String get invCategoryRamadan => 'Ramadan';

  @override
  String get invCategoryEid => 'Aïd';

  @override
  String get invCategoryWedding => 'Mariage';

  @override
  String get invRamadan1Title => 'Ramadan Karim — Classique';

  @override
  String get invRamadan2Title => 'Ramadan Karim — Story';

  @override
  String get invEid1Title => 'Aïd Moubarak — Classique';

  @override
  String get invEid2Title => 'Aïd Moubarak — Story';

  @override
  String get invWedding1Title => 'Mariage — Classique';

  @override
  String get invWedding2Title => 'Mariage — Moderne';

  @override
  String get invWedding3Title => 'Mariage — Story';

  @override
  String get invSizeA6Portrait => 'A6 portrait (105×148 mm)';

  @override
  String get invSizeA6Landscape => 'A6 paysage (148×105 mm)';

  @override
  String get invSizeSquare148 => 'Carré pour impression (148×148 mm)';

  @override
  String get invSizeA5Folded => 'A5 plié (105×148 mm)';

  @override
  String get invSizeInstagramSquare => 'Instagram carré (1080×1080)';

  @override
  String get invSizeInstagramPortrait => 'Instagram portrait (1080×1350)';

  @override
  String get invSizeInstagramStory => 'Instagram Story (1080×1920)';

  @override
  String get invSizeWhatsAppStatus => 'WhatsApp Status (1080×1920)';

  @override
  String get invSizeFacebookPost => 'Facebook Post (1200×630)';

  @override
  String get invExportFormatPNG => 'PNG (pour les réseaux sociaux)';

  @override
  String get invExportFormatPDF => 'PDF (pour l\'impression)';

  @override
  String get invExportFormatBoth => 'PNG + PDF';

  @override
  String get invBulkModeTitle => 'Invitations personnelles en lot';

  @override
  String get invBulkModeHint => 'Une carte par nom — export individuel.';

  @override
  String get invPreviewTitle => 'Aperçu des 3 premières copies';

  @override
  String get invExportFormat => 'Format d\'export';

  @override
  String get invNameFieldMissing => 'Ce modèle ne contient pas de champ de nom';

  @override
  String invDuplicateNames(Object count) {
    return 'Noms en double : $count';
  }

  @override
  String invEmptyNames(Object count) {
    return 'Cellules vides : $count — elles seront ignorées';
  }

  @override
  String get invZIPOption => 'Compresser dans un fichier ZIP';

  @override
  String get invIndexCSVOption => 'Créer un index CSV';

  @override
  String invProgressText(Object done, Object total) {
    return '$done sur $total générés';
  }

  @override
  String get navEditors => 'Éditeurs';

  @override
  String get navLibraries => 'Bibliothèques';

  @override
  String get navAdmin => 'Administration';

  @override
  String get navUser => 'Compte';

  @override
  String get bpWorkTypeLabel => 'Type de modèle';

  @override
  String get bpExportFormatLabel => 'Type d’export';

  @override
  String get bpKindInvitation => 'Invitation';

  @override
  String get invPackOptions => 'Options de sortie';

  @override
  String get tplCertClassicTitle => 'Certificat classique bleu marine';

  @override
  String get tplCertClassicDesc =>
      'Certificat bleu marine classique a double cadre dore et etoiles ornementales.';

  @override
  String get tplCertMinimalTitle => 'Certificat minimal bleu marine';

  @override
  String get tplCertMinimalDesc =>
      'Design minimal epure bleu marine avec un seul filet dore et de larges espaces.';

  @override
  String get tplCertIslamicTitle => 'Certificat ornement islamique';

  @override
  String get tplCertIslamicDesc =>
      'Certificat bleu marine a bordures dorees, ornements geometriques islamiques et typographie Amiri.';

  @override
  String get tplCertBandTitle => 'Certificat a bandes dorees';

  @override
  String get tplCertBandDesc =>
      'Certificat bleu marine a bandes horizontales dorees en haut et en bas.';

  @override
  String get tplCertDiagonalTitle => 'Certificat diagonal dynamique';

  @override
  String get tplCertDiagonalDesc =>
      'Certificat bleu marine aux formes geometriques dorees inclinees evoquant le mouvement.';

  @override
  String get tplCertSquareTitle => 'Certificat carre elegant';

  @override
  String get tplCertSquareDesc =>
      'Certificat bleu marine a cadre carre dore symetrique et sceau circulaire superieur.';

  @override
  String get navInvitationsEngine => 'Moteur d\'invitations';

  @override
  String get aboutTitle => 'À propos de JoodCraft';

  @override
  String get aboutTagline =>
      'Générez des certificats et contrats officiels en arabe';

  @override
  String aboutVersion(Object version) {
    return 'Version $version';
  }

  @override
  String get aboutSummaryTitle => 'Aperçu';

  @override
  String get aboutSummaryBody =>
      'JoodCraft est une application de bureau et web qui fonctionne entièrement sur votre appareil : elle lit les fichiers Excel et génère des certificats et contrats en PDF avec des polices arabes intégrées. Projets, modèles et ressources restent dans une base locale — rien n\'est envoyé sur un serveur.';

  @override
  String get aboutFeaturesTitle => 'Fonctionnalités principales';

  @override
  String get aboutFeatureOffline =>
      'Entièrement hors ligne : pas d\'internet, aucune donnée envoyée';

  @override
  String get aboutFeatureArabicFonts =>
      'Polices arabes intégrées avec mise en forme RTL précise';

  @override
  String get aboutFeatureExcel =>
      'Lecture Excel et CSV avec liaison automatique des colonnes aux champs';

  @override
  String get aboutFeatureBatch =>
      'Générez des centaines de certificats en une fois — fichier groupé ou un par personne';

  @override
  String get aboutFeatureVisualEditor =>
      'Éditeur visuel par glisser-déposer avec sélection multiple, annulation et rétablissement';

  @override
  String get aboutFeatureInvitations =>
      'Invitations prêtes pour le Ramadan, l\'Aïd et les mariages, aux formats impression et réseaux sociaux';

  @override
  String get aboutFeatureExports =>
      'Export PDF, PNG et projets Jood partageables';

  @override
  String get aboutDeveloperTitle => 'Développeur';

  @override
  String get aboutDeveloperName => 'Seraj Abdullah Al-Badawi';

  @override
  String get aboutDeveloperEmail => 'serajelroh@gmail.com';

  @override
  String get aboutDeveloperStatus =>
      'Projet personnel — en cours de développement';

  @override
  String get aboutLicenses => 'Voir les licences';

  @override
  String get aboutFeedback => 'Envoyer un avis';

  @override
  String get aboutFeedbackCopied =>
      'E-mail copié — vos retours sont les bienvenus';

  @override
  String get aboutCreditsTitle => 'Remerciements';

  @override
  String get aboutCreditsBody =>
      'Application bâtie avec Flutter et des bibliothèques open source — merci à la communauté Flutter et à tous les contributeurs de ces bibliothèques.';

  @override
  String get jwPagesSettings => 'Mise en page';

  @override
  String get jwPagesMultiple => 'Pages multiples';

  @override
  String get jwPagesMultipleHint =>
      'Diviser la feuille en deux pour imprimer deux pages sur une seule feuille';

  @override
  String get jwPagesSingle => 'Normal (page unique)';

  @override
  String get jwPagesA4ToA5Portrait => 'A4 → 2 × A5 portrait (livret)';

  @override
  String get jwPagesA4ToA5Landscape => 'A4 → 2 × A5 paysage';

  @override
  String get jwPagesPreview => 'Aperçu';

  @override
  String get aboutLinksTitle => 'Liens';

  @override
  String get aboutDescription =>
      'JoodCraft est une plateforme arabe complète pour générer certificats, contrats et invitations avec une qualité professionnelle. Concevez un seul modèle visuellement, puis reliez-le à un fichier Excel pour produire des centaines de documents avec une typographie arabe précise et un sens de lecture correct — hors ligne et sans serveur.';

  @override
  String get aboutFeatures => 'Fonctionnalités';

  @override
  String get aboutFeature10Languages => '10 langues prises en charge';

  @override
  String get aboutFeatureArabicText => 'Mise en forme arabe précise';

  @override
  String get aboutFeatureBulkGeneration => 'Génération en lot depuis Excel';

  @override
  String get aboutFeaturePdfExport => 'Export PDF de haute qualité';

  @override
  String get aboutDeveloper => 'Développeur';

  @override
  String get aboutDeveloperNote => 'Projet personnel — en développement';

  @override
  String get aboutLinks => 'Liens';

  @override
  String get aboutViewLicenses => 'Voir les licences';

  @override
  String get aboutSendFeedback => 'Envoyer un avis';

  @override
  String get aboutCredits => 'Remerciements';

  @override
  String get aboutCreditsText =>
      'JoodCraft est construit avec Flutter et Dart, ainsi que des bibliothèques open source. Merci à tous ceux qui ont contribué.';

  @override
  String get navInvitationTemplates => 'Modèles d\'invitations';

  @override
  String get ocrTitle => 'Extraire le texte d\'une image';

  @override
  String get ocrShowRaw => 'Afficher le texte original';

  @override
  String get ocrSubtitle =>
      'Importez une image ou un PDF et extrayez son texte';

  @override
  String get ocrImportImage => 'Importer une image';

  @override
  String get ocrImportPdf => 'Importer un PDF';

  @override
  String get ocrExtractText => 'Extraire le texte';

  @override
  String get ocrProcessing => 'Traitement en cours...';

  @override
  String get ocrPreview => 'Aperçu du texte';

  @override
  String get ocrInsertInEditor => 'Insérer dans l\'éditeur';

  @override
  String get ocrCopyToClipboard => 'Copier';

  @override
  String get ocrRetry => 'Réessayer';

  @override
  String get ocrAccept => 'Accepter';

  @override
  String get ocrCleanupNote =>
      'Le texte a été nettoyé automatiquement — vérifiez-le avant l\'enregistrement.';

  @override
  String get ocrCancel => 'Annuler';

  @override
  String get ocrLanguageLabel => 'Langue';

  @override
  String get ocrLanguageArabic => 'Arabe';

  @override
  String get ocrLanguageEnglish => 'Anglais';

  @override
  String get ocrLanguageBoth => 'Arabe et anglais';

  @override
  String get ocrAccuracyNote =>
      'La précision de l\'extraction peut être inférieure à 100 % — relisez le texte avant d\'enregistrer.';

  @override
  String get ocrNoTextFound => 'Aucun texte trouvé dans l\'image.';

  @override
  String get ocrInvalidImage => 'Image non valide.';

  @override
  String get ocrError => 'Impossible d\'extraire le texte. Réessayez.';

  @override
  String get ocrEngineMissing =>
      'Tesseract est introuvable — installez-le, puis réessayez.';

  @override
  String get ocrLanguageDataMissing =>
      'Les données linguistiques ne sont pas installées avec Tesseract.';

  @override
  String get ocrNoImage => 'Importez d\'abord une image ou un PDF.';

  @override
  String get ocrCopyDone => 'Texte copié dans le presse-papiers.';

  @override
  String get ocrConfidence => 'Confiance';

  @override
  String get ocrPsmLabel => 'Segmentation';

  @override
  String get ocrPsmAuto => 'Automatique';

  @override
  String get ocrPsmBlock => 'Un seul bloc de texte';

  @override
  String get ocrPsmLine => 'Une seule ligne';

  @override
  String get ocrPsmSparse => 'Texte dispersé';

  @override
  String get ocrScaleLabel => 'Zoom';

  @override
  String get ocrPdfPages => 'Pages';

  @override
  String get ocrInsertInWriter => 'Insérer dans Jood Writer';

  @override
  String get ocrTessHint =>
      'Nécessite l\'installation de Tesseract sur cet appareil.';
}
