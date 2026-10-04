// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

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
  String get dashRoadmapSupabase =>
      'Mise en place de la base Supabase (tables + RLS + triggers)';

  @override
  String get dashRoadmapModular =>
      'Une structure modulaire « Feature-First » évolutive';

  @override
  String get dashRoadmapTheme =>
      'Le thème visuel de la marque avec support RTL en police Cairo';

  @override
  String get dashRoadmapAuth =>
      'Authentification : connexion, création de compte et réinitialisation du mot de passe';

  @override
  String get dashPhaseOneDone => 'Première phase terminée';

  @override
  String get dashNextPhase =>
      'Ensuite : le moteur PDF hors ligne et les polices arabes, puis l’éditeur visuel de modèles.';

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
}
