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
}
