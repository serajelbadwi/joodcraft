// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get editorDone => 'Fertig';

  @override
  String get appTagline =>
      'Offizielle Zertifikate und Verträge offline erstellen';

  @override
  String get navDashboard => 'Übersicht';

  @override
  String get navCertificates => 'Zertifikats-Editor';

  @override
  String get navContracts => 'Vertrags-Editor';

  @override
  String get navBatch => 'Stapelverarbeitung';

  @override
  String get navTemplates => 'Vorlagenbibliothek';

  @override
  String get navAssets => 'Assets & Signaturen';

  @override
  String get actionSignOut => 'Abmelden';

  @override
  String get actionOpenMenu => 'Menü';

  @override
  String get editorFitToScreen => 'An Bildschirm anpassen';

  @override
  String get editorNewTemplate => 'Neue Vorlage';

  @override
  String get editorNewConfirm =>
      'Eine neue Vorlage startet vom Standarddesign; nicht gespeicherte Änderungen bleiben im Verlauf. Fortfahren?';

  @override
  String get actionBackToDashboard => 'Zurück zur Übersicht';

  @override
  String get offlineProcessingLabel => 'Lokale Verarbeitung';

  @override
  String get themeTooltip => 'Design wechseln';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get languageTooltip => 'Sprache ändern';

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
  String get configMissingKeysTitle => 'Verbindungsschlüssel nicht gefunden';

  @override
  String get configMissingKeysBody =>
      'Beim Start sucht die App nach Schlüsseln in drei Quellen: dem --dart-define-Flag, dann einer env.json-Datei auf der Festplatte (Stammverzeichnis oder assets/env/) und schließlich der eingebetteten Kopie — keine wurde gefunden. Erstellen Sie die Datei, füllen Sie sie einmal aus und starten Sie ohne Flags:';

  @override
  String get configEnvNote =>
      'Das Bundle deklariert assets/env/ als Asset, daher bricht ein fehlendes File einen sauberen Build nicht ab. Erstellen Sie es aus env.example.json oder führen Sie aus: dart run tool/ensure_env.dart — nur der anon/public-Schlüssel ist nötig; service_role wird nie in der App verwendet.';

  @override
  String get routeNotFoundTitle => 'Seite nicht gefunden';

  @override
  String get routeNotFoundBody =>
      'Die angeforderte Route ist in der App nicht definiert:';

  @override
  String get editorPrecisionTitle => 'Präzisionssteuerung';

  @override
  String get editorNudgeStep => 'Verschiebeschritt';

  @override
  String get editorNudgeStepHint =>
      'Die Pfeile auf der Arbeitsfläche verschieben ebenfalls um Shift = 10px.';

  @override
  String get editorNudgeUp => 'Nach oben';

  @override
  String get editorNudgeLeft => 'Nach links';

  @override
  String get editorNudgeDown => 'Nach unten';

  @override
  String get editorNudgeRight => 'Nach rechts';

  @override
  String get editorScale => 'Skalierung';

  @override
  String get editorScaleHint =>
      'Relative Skalierung um die Elementmitte (Mausrad auf den Schaltflächen für feinere Schritte).';

  @override
  String get editorScaleUp => 'Vergrößern';

  @override
  String get editorScaleDown => 'Verkleinern';

  @override
  String get editorDecorTitle => 'Vektordekoration';

  @override
  String get editorDecorKind => 'Dekorationsart';

  @override
  String get editorDecorPalette => 'Farbpalette';

  @override
  String get editorDecorLayers => 'Anzahl der Ebenen';

  @override
  String get editorDecorSeed => 'Zufallswert';

  @override
  String get editorDecorThickness => 'Stärke';

  @override
  String get editorDecorPrimary => 'Hauptfarbe';

  @override
  String get editorDecorSecondary => 'Zweitfarbe';

  @override
  String get editorDecorAccent => 'Akzentfarbe';

  @override
  String get editorDecorGradient => 'Ebenenverlauf';

  @override
  String get editorDecorGallery => 'Vorlagengalerie';

  @override
  String get editorDecorGalleryTitle => 'Galerie fertiger Dekorationen';

  @override
  String get editorClose => 'Schließen';

  @override
  String get editorDecorPaletteCustom => 'Benutzerdefiniert';

  @override
  String get decorKindModernWave => 'Moderne Wellen';

  @override
  String get decorKindPaperCut => 'Mehrschichtiger Papierschnitt';

  @override
  String get decorKindClassicCorner => 'Klassischer Zierrahmen';

  @override
  String get decorKindGuilloche => 'Guilloche-Muster';

  @override
  String get decorKindRibbonBanner => 'Band / Banner';

  @override
  String get decorPaletteRoyalGold => 'Königsgold';

  @override
  String get decorPaletteRoyalBlue => 'Königsblau';

  @override
  String get decorPaletteEmerald => 'Smaragd';

  @override
  String get decorPaletteBurgundy => 'Burgunder';

  @override
  String get decorPaletteMidnight => 'Mitternachtsblau';

  @override
  String get decorPaletteMono => 'Einfarbig grau';

  @override
  String get editorSignatureTitle => 'Signaturblock';

  @override
  String get editorSignatureCount => 'Anzahl der Signaturen';

  @override
  String get signatureCountOne => 'Eine Signatur';

  @override
  String get signatureCountTwo => 'Zwei Signaturen';

  @override
  String get signatureCountThree => 'Drei Signaturen';

  @override
  String get editorSignatureOrder => 'Reihenfolge der Felder';

  @override
  String get editorSignatureOrderHint =>
      'In arabischen Dokumenten steht das erste Feld ganz rechts.';

  @override
  String get editorSignatureFirstRight => 'Erste rechts';

  @override
  String get editorSignatureFirstLeft => 'Erste links';

  @override
  String get editorDirectionAuto => 'Automatisch';

  @override
  String get editorSignatureImageAlign => 'Bildausrichtung';

  @override
  String get editorAlignStart => 'Anfang';

  @override
  String get editorAlignCenter => 'Mitte';

  @override
  String get editorAlignEnd => 'Ende';

  @override
  String get editorSignatureDivider => 'Signaturlinie';

  @override
  String get editorVisible => 'Sichtbar';

  @override
  String get editorHidden => 'Ausgeblendet';

  @override
  String get editorSignatureNameSize => 'Namensgröße';

  @override
  String get editorSignatureRoleSize => 'Rollengröße';

  @override
  String get editorSignatureSpacing => 'Abstand';

  @override
  String get editorSignatureImageSize => 'Bildgröße';

  @override
  String get editorSignatureNameColor => 'Namensfarbe';

  @override
  String get editorSignatureRoleColor => 'Rollenfarbe';

  @override
  String get editorFont => 'Schriftart';

  @override
  String get editorImageSource => 'Bildquelle';

  @override
  String get imageSourceAppAssets => 'App-Ressourcen';

  @override
  String get imageSourceMyLibrary => 'Meine Bibliothek';

  @override
  String get imageSourceLocalFile => 'Lokale Datei';

  @override
  String get imageSourceEmbedded => 'Eingebettete Daten';

  @override
  String get editorSignatureChangeImage => 'Signaturbild ändern';

  @override
  String get editorSignatureAddImage => 'Signaturbild hinzufügen';

  @override
  String get editorSignatureRemoveImage => 'Signaturbild entfernen';

  @override
  String get editorSignaturePickImageTitle =>
      'Signaturbild aus meiner Bibliothek wählen';

  @override
  String get editorSignatureSlot => 'Feld';

  @override
  String get editorSignatureRoleField => 'Rolle (z. B. Geschäftsführer)';

  @override
  String get editorSignatureNameField =>
      'Name des Unterzeichners (akzeptiert ein dynamisches Feld)';

  @override
  String get editorFromMyLibrary => 'Aus meiner Bibliothek';

  @override
  String get paletteSignatureBlock => 'Signaturen';

  @override
  String get editorInsertFromLibraryTooltip =>
      'Hochgeladenen Rahmen oder Logo direkt einfügen';

  @override
  String get unsupportedElementVersionNote =>
      'Dieses Element stammt aus einer neueren Editor-Version – es bleibt unverändert und kann hier nicht bearbeitet werden.';

  @override
  String editorSelectedCount(Object count) {
    return '$count ausgewählt';
  }

  @override
  String get editorClearSelection => 'Auswahl aufheben';

  @override
  String get editorGroup => 'Gruppe';

  @override
  String get editorOpacity => 'Deckkraft';

  @override
  String get editorBringToFront => 'Nach vorne';

  @override
  String get editorSendToBack => 'Nach hinten';

  @override
  String get editorDuplicate => 'Duplizieren';

  @override
  String get editorDeleteSelected => 'Auswahl löschen';

  @override
  String get editorGroupDragHint =>
      'Ziehen Sie die Gruppe mit der Maus, nutzen Sie die Pfeile zum feinen Verschieben (Shift = 10px) und Ctrl + Klick zum Anpassen der Auswahl.';

  @override
  String get destBrand => 'Marke & Profil';

  @override
  String get destBrandDesc =>
      'Ihr Logo, Ihre Stempel, Unterschriften und Markenfarben.';

  @override
  String get brandTitle => 'Marken- und Profileinstellungen';

  @override
  String get brandTabVisuals => 'Visuelle Identität';

  @override
  String get brandTabText => 'Textdaten';

  @override
  String get brandTabColors => 'Farben & Schriften';

  @override
  String get brandTabPreview => 'Identitätsvorschau';

  @override
  String get brandPrimaryLogo => 'Hauptlogo';

  @override
  String get brandWatermarkLogo => 'Wasserzeichen-Logo';

  @override
  String get brandSeals => 'Offizielle Stempel';

  @override
  String get brandAddSeal => 'Stempel hinzufügen';

  @override
  String get brandSealName => 'Stempelname';

  @override
  String get brandSignatures => 'Autorisierte Unterschriften';

  @override
  String get brandAddSignature => 'Unterschrift hinzufügen';

  @override
  String get brandSignatureName => 'Name des Unterzeichners';

  @override
  String get brandSignatureTitle => 'Funktion';

  @override
  String get brandRemove => 'Entfernen';

  @override
  String get brandNoSeals => 'Noch keine Stempel hinzugefügt.';

  @override
  String get brandNoSignatures => 'Noch keine Unterschriften hinzugefügt.';

  @override
  String get brandOrgNameAr => 'Organisationsname (Arabisch)';

  @override
  String get brandOrgNameEn => 'Organisationsname (Englisch)';

  @override
  String get brandHeaderText => 'Kopfzeilentext';

  @override
  String get brandFooterText => 'Fußzeilentext';

  @override
  String get brandRegNumber => 'Steuer-/Registriernummer';

  @override
  String get brandPrimaryColor => 'Primärfarbe';

  @override
  String get brandSecondaryColor => 'Sekundärfarbe';

  @override
  String get brandAccentColor => 'Akzentfarbe';

  @override
  String get brandHeaderFont => 'Titel-Schrift';

  @override
  String get brandBodyFont => 'Text-Schrift';

  @override
  String get brandClear => 'Marke löschen';

  @override
  String get brandClearConfirm =>
      'Alle gespeicherten Markeninhalte werden gelöscht. Fortfahren?';

  @override
  String get brandSaved => 'Marke gespeichert.';

  @override
  String get brandPresets => 'Markenelemente';

  @override
  String get brandInsertHeader => 'Standardkopf einfügen';

  @override
  String get brandInsertFooter => 'Standardfuß einfügen';

  @override
  String get brandApplyColors => 'Markenfarben anwenden';

  @override
  String get brandQuickSeals => 'Stempel';

  @override
  String get brandQuickSignatures => 'Unterschriften';

  @override
  String get brandNoBrand => 'Ihre Marke ist noch nicht eingerichtet.';

  @override
  String get brandOpenSettings => 'Markeneinstellungen öffnen';

  @override
  String get brandHeaderInserted => 'Standardkopf eingefügt.';

  @override
  String get brandFooterInserted => 'Standardfuß eingefügt.';

  @override
  String get brandColorsApplied => 'Farben angewendet.';

  @override
  String get brandSealInserted => 'Stempel eingefügt.';

  @override
  String get brandSignatureInserted => 'Unterschrift eingefügt.';

  @override
  String get brandFontDefault => 'Standard';

  @override
  String get paletteShapes => 'Formen';

  @override
  String get paletteRoundedRect => 'Abgerundetes Rechteck';

  @override
  String get paletteEllipse => 'Kreis / Ellipse';

  @override
  String get editorFillOpacity => 'Füll-Deckkraft';

  @override
  String get editorCollapsePanel => 'Seitenleiste einklappen';

  @override
  String get editorExpandPanel => 'Seitenleiste anzeigen';

  @override
  String get editorCustomSize => 'Benutzerdefinierte Größe';

  @override
  String get editorStandardSize => 'Standardgröße';

  @override
  String get editorBackgroundTitle => 'Blatthintergrund';

  @override
  String get editorGradientFrom => 'Von';

  @override
  String get editorGradientTo => 'Bis';

  @override
  String get editorGradientDirection => 'Richtung';

  @override
  String get editorGradientNone => 'Kein Verlauf';

  @override
  String get editorGradientVertical => 'Vertikal';

  @override
  String get editorGradientHorizontal => 'Horizontal';

  @override
  String get editorGradientDiagonal => 'Diagonal';

  @override
  String get editorLayersTitle => 'Ebenen';

  @override
  String get editorLayerShow => 'Element anzeigen';

  @override
  String get editorLayerHide => 'Element ausblenden';

  @override
  String get editorLayerLock => 'Element sperren';

  @override
  String get editorLayerUnlock => 'Element entsperren';

  @override
  String get editorLayersEmpty => 'Noch keine Elemente auf dieser Seite.';

  @override
  String get editorGroupSelected => 'Auswahl gruppieren';

  @override
  String get editorUngroupSelected => 'Gruppierung aufheben';

  @override
  String get editorAlignLeft => 'Linksbündig';

  @override
  String get editorAlignCenterH => 'Horizontal zentrieren';

  @override
  String get editorAlignRight => 'Rechtsbündig';

  @override
  String get editorAlignTop => 'Oben ausrichten';

  @override
  String get editorAlignCenterV => 'Vertikal zentrieren';

  @override
  String get editorAlignBottom => 'Unten ausrichten';

  @override
  String get editorBringForward => 'Eine Ebene nach vorne';

  @override
  String get editorDuplicateElement => 'Element duplizieren';

  @override
  String get editorDeleteElement => 'Element löschen';

  @override
  String get editorPageSettings => 'Seiteneinstellungen';

  @override
  String get editorPageSize => 'Größe';

  @override
  String get editorUnit => 'Einheit';

  @override
  String get editorWidth => 'Breite';

  @override
  String get editorHeight => 'Höhe';

  @override
  String get editorLabelText => 'Text';

  @override
  String get editorLabelShape => 'Form';

  @override
  String get editorLabelSeal => 'Siegel';

  @override
  String get editorLabelDecoration => 'Vektordekoration';

  @override
  String get editorLabelSignature => 'Signaturblock';

  @override
  String get editorLabelImage => 'Bild / Logo';

  @override
  String get editorLabelQr => 'QR-Code';

  @override
  String get editorLabelUnknown => 'Nicht unterstütztes Element';

  @override
  String get editorLabelDynamicField => 'Dynamisches Feld';

  @override
  String get editorPositionAndSize => 'Position und Größe';

  @override
  String get editorPosX => 'X';

  @override
  String get editorPosY => 'Y';

  @override
  String get editorRotation => 'Drehung';

  @override
  String get editorTextFormat => 'Textformatierung';

  @override
  String get editorConvertToField => 'In dynamisches Feld umwandeln';

  @override
  String get editorFontWeight => 'Schriftschnitt';

  @override
  String get editorWeightRegular => 'Normal';

  @override
  String get editorWeightSemiBold => 'Halbfett';

  @override
  String get editorWeightBold => 'Fett';

  @override
  String get editorFontSize => 'Schriftgröße';

  @override
  String get editorLetterSpacing => 'Zeichenabstand';

  @override
  String get editorLineHeight => 'Zeilenhöhe';

  @override
  String get editorTextColor => 'Textfarbe';

  @override
  String get editorTextBackground => 'Texthintergrund';

  @override
  String get editorTextAlign => 'Ausrichtung';

  @override
  String get editorAlignJustify => 'Blocksatz';

  @override
  String get editorJustifyMode => 'Ausrichtungsmethode';

  @override
  String get editorJustifyHint =>
      'Kashida wird in der PDF-Datei angewendet (die Vorschau zeigt den Leerraumausgleich)';

  @override
  String get editorJustifySpaces => 'Leerzeichen';

  @override
  String get editorJustifyKashida => 'Kashida';

  @override
  String get editorVerticalAlign => 'Vertikale Ausrichtung';

  @override
  String get editorVerticalTop => 'Oben';

  @override
  String get editorVerticalBottom => 'Unten';

  @override
  String get editorDirection => 'Richtung';

  @override
  String get editorDirectionHint => 'Umschalt-Tastenkürzel: Ctrl+Shift+D';

  @override
  String get editorDirectionRtl => 'Arabisch (RTL)';

  @override
  String get editorDirectionLtr => 'Lateinisch (LTR)';

  @override
  String get editorImage => 'Bild';

  @override
  String get editorSource => 'Quelle';

  @override
  String get editorImageTint => 'Bildfarbe';

  @override
  String get editorImageFit => 'Bildanpassung';

  @override
  String get editorFitContain => 'Einpassen';

  @override
  String get editorFitCover => 'Füllen';

  @override
  String get editorFitFill => 'Strecken';

  @override
  String get assetPickerEmptyHint =>
      'Sie haben noch keine Ressourcen hochgeladen. Laden Sie ein Logo, eine Signatur oder ein Siegel hoch, um es hier und beim Drucken zu verwenden.';

  @override
  String get assetPickerNoneOption => 'Keine (andere Quelle)';

  @override
  String get assetPickerTitle => 'Bild aus meiner Bibliothek wählen';

  @override
  String assetUploadType(Object type) {
    return '$type hochladen';
  }

  @override
  String get editorSeal => 'Siegel';

  @override
  String get editorSealColor => 'Siegelfarbe';

  @override
  String get editorSealRingColor => 'Ringfarbe';

  @override
  String get editorSealStarColor => 'Sternenfarbe';

  @override
  String get editorSealStarSize => 'Sternengröße';

  @override
  String get editorShape => 'Form';

  @override
  String get editorFillColor => 'Füllfarbe';

  @override
  String get editorBorderColor => 'Rahmenfarbe';

  @override
  String get editorBorderWidth => 'Rahmenbreite';

  @override
  String get editorCornerRadius => 'Eckenradius';

  @override
  String get editorQrVerify => 'Bestätigungscode';

  @override
  String get editorQrData => 'Code-Daten';

  @override
  String get editorQrColor => 'Code-Farbe';

  @override
  String get editorQrBackground => 'Code-Hintergrund';

  @override
  String editorConvertDialogMessage(Object text) {
    return 'Die Umwandlung macht aus dem Text „$text“ eine dynamische Markierung, die in der Massengenerierung gebunden werden kann.';
  }

  @override
  String get editorFieldKeyHint =>
      'Feldschlüssel (z. B. Name, Datum, Referenz)';

  @override
  String get editorCustomKeyHint =>
      'Geben Sie einen benutzerdefinierten Schlüssel ein (ohne Klammern – wird automatisch ergänzt)';

  @override
  String get editorCancel => 'Abbrechen';

  @override
  String get editorConvert => 'Umwandeln';

  @override
  String get editorPath => 'Pfad';

  @override
  String get editorTextContent => 'Textinhalt';

  @override
  String editorInsertFieldToken(Object token) {
    return '$token einfügen';
  }

  @override
  String editorAddLabel(Object label) {
    return '$label hinzufügen';
  }

  @override
  String assetInsertedSnack(Object name) {
    return '„$name“ wurde in die Vorlage eingefügt.';
  }

  @override
  String get paletteHeading => 'Überschrift';

  @override
  String get paletteFrame => 'Rechteck / Rahmen';

  @override
  String get paletteDivider => 'Trennlinie';

  @override
  String get paletteLogo => 'Logo / Signatur';

  @override
  String get evSignatureEmptyLabel => 'Leere Signatur';

  @override
  String get evSignatureEmptyDetail =>
      'Rolle, Name und Signaturbild hinzufügen';

  @override
  String get evSignatureMissingLabel => 'Fehlende Signatur';

  @override
  String get evUploadToLibraryDetail =>
      'Laden Sie das Bild in die Ressourcenbibliothek';

  @override
  String get evImageNotFoundLabel => 'Bild nicht gefunden';

  @override
  String get evNoFileLabel => 'Keine Datei ausgewählt';

  @override
  String get evChooseFromAssetsDetail =>
      'Bild aus der Ressourcenbibliothek wählen';

  @override
  String get evAssetMissingLabel => 'Fehlende Ressource';

  @override
  String get evReselectAssetDetail =>
      'Rahmen/Ressource erneut aus der Bibliothek wählen';

  @override
  String get evInvalidImageLabel => 'Ungültiges Bild';

  @override
  String get evRenderDataFailedDetail => 'Daten können nicht angezeigt werden';

  @override
  String get evInvalidDataLabel => 'Ungültige Daten';

  @override
  String get evDecodeFailedDetail => 'Bild kann nicht dekodiert werden';

  @override
  String get evEmptyQrLabel => 'Leerer Code';

  @override
  String get evEmptyQrDetail =>
      'Geben Sie den Codewert in der Eigenschaftenleiste ein';

  @override
  String evUnknownElementLabel(Object type) {
    return 'Nicht unterstütztes Element: $type';
  }

  @override
  String get alpFilterAll => 'Alle';

  @override
  String get alpEmptyHint =>
      'Keine hochgeladenen Ressourcen der gewünschten Typen. Laden Sie einen Rahmen oder ein Logo im Bereich „Ressourcen & Signaturen“ hoch und versuchen Sie es erneut.';

  @override
  String alpNoFilteredAssets(Object type) {
    return 'Keine Ressourcen vom Typ „$type“.';
  }

  @override
  String get authWelcomeBack => 'Willkommen bei JoodCraft.';

  @override
  String get authResetLinkSent =>
      'Der Link zum Zurücksetzen wurde gesendet. Prüfen Sie Ihre E-Mail.';

  @override
  String get authLogin => 'Anmelden';

  @override
  String get authLoginSubtitle =>
      'Ihre E-Mail und Ihr Passwort für das Dashboard.';

  @override
  String get authNoAccount => 'Noch kein Konto?';

  @override
  String get authCreateAccountLink => 'Neues Konto erstellen';

  @override
  String get authConfirmEmailThenLogin =>
      'Ihr Konto wurde erstellt. Bestätigen Sie zuerst Ihre E-Mail und melden Sie sich dann an.';

  @override
  String get authEmail => 'E-Mail';

  @override
  String get authPassword => 'Passwort';

  @override
  String get authForgotPassword => 'Passwort vergessen?';

  @override
  String get authEnterDashboard => 'Zum Dashboard';

  @override
  String get authResetPassword => 'Passwort zurücksetzen';

  @override
  String get authResetPasswordHint =>
      'Geben Sie Ihre E-Mail ein, wir senden Ihnen einen Link zum Zurücksetzen.';

  @override
  String get authSendLink => 'Link senden';

  @override
  String get authConfirmEmailMessage =>
      'Ihr Konto wurde erstellt. Bestätigen Sie es per E-Mail und melden Sie sich dann an.';

  @override
  String get authAccountCreatedWelcome =>
      'Ihr Konto wurde erstellt. Willkommen bei JoodCraft.';

  @override
  String get authCreateAccount => 'Konto erstellen';

  @override
  String get authRegisterSubtitle =>
      'Ihr Konto speichert Ihre Vorlagen und Ressourcen (Logo, Signatur, Siegel) zur Wiederverwendung in allen Projekten.';

  @override
  String get authHaveAccount => 'Bereits ein Konto?';

  @override
  String get authFullName => 'Vollständiger Name';

  @override
  String get authFullNameHint => 'z. B. Abdullah Al-Ahmad';

  @override
  String get authName => 'Name';

  @override
  String get authOrgName => 'Name der Organisation (optional)';

  @override
  String get authOrgNameHint => 'z. B. Jood-Wohltätigkeitsverein';

  @override
  String get authOrgHelper =>
      'Wird automatisch auf Zertifikaten und Verträgen gedruckt.';

  @override
  String get authOrgNameShort => 'Organisationsname';

  @override
  String get authPasswordHint => 'Mindestens 8 Zeichen';

  @override
  String authPasswordRule(Object min) {
    return 'Verwenden Sie mindestens $min Zeichen mit Zahlen und Symbolen.';
  }

  @override
  String get authConfirmPassword => 'Passwort bestätigen';

  @override
  String get authCreateAccountButton => 'Konto erstellen';

  @override
  String get authFeatureLocalExcel =>
      'Vollständig lokale Verarbeitung von Excel-Dateien – Ihre Daten verlassen Ihr Gerät nicht';

  @override
  String get authFeaturePdf =>
      'PDF-Erstellung mit hochwertigen arabischen Schriften und vollständiger RTL-Unterstützung';

  @override
  String get authFeatureTemplates =>
      'Ihre Vorlagen sind in Ihrem Konto gespeichert und wiederverwendbar';

  @override
  String get authTagline =>
      'Ihre offiziellen Zertifikate und Verträge… mit Vertrauen gedruckt.';

  @override
  String authVersion(Object name, Object version) {
    return '$name • Version $version';
  }

  @override
  String get dashModules => 'Plattform-Module';

  @override
  String dashWelcome(Object name) {
    return 'Willkommen, $name';
  }

  @override
  String dashSubscription(Object tier) {
    return 'Abonnement: $tier';
  }

  @override
  String dashOrg(Object name) {
    return 'Organisation: $name';
  }

  @override
  String get dashOrgMissing =>
      'Sie haben noch keinen Organisationsnamen festgelegt – er wird automatisch auf Zertifikate und Verträge gedruckt.';

  @override
  String get dashOpenModule => 'Modul öffnen';

  @override
  String get destDashboard => 'Dashboard';

  @override
  String get destDashboardDesc =>
      'Ein Überblick über Ihre Projekte und Vorlagen.';

  @override
  String get destCertificates => 'Zertifikats-Engine';

  @override
  String get destCertificatesDesc =>
      'Entwerfen Sie Querformat-Zertifikate aus einer bearbeitbaren Vorlage.';

  @override
  String get destContracts => 'Vertrags-Engine';

  @override
  String get destContractsDesc =>
      'Erstellen Sie Hochformat-Verträge mit dynamischen Feldern.';

  @override
  String get destBatch => 'Massen-Generierung';

  @override
  String get destBatchDesc =>
      'Lesen Sie eine Excel-Datei lokal und erzeugen Sie Hunderte Zertifikate auf einmal.';

  @override
  String get destTemplates => 'Vorlagenbibliothek';

  @override
  String get destTemplatesDesc =>
      'Verwalten, ordnen und verwenden Sie Ihre gespeicherten Vorlagen wieder.';

  @override
  String get destAssets => 'Ressourcen & Signaturen';

  @override
  String get destAssetsDesc => 'Ihr Logo, Siegel, Ihre Signatur und Rahmen.';

  @override
  String get dashUser => 'Benutzer';

  @override
  String get dashLogoutSuccess => 'Sie wurden erfolgreich abgemeldet.';

  @override
  String get dashLogoutError =>
      'Abmelden fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonPreview => 'Vorschau';

  @override
  String get commonOptions => 'Optionen';

  @override
  String get tplDelete => 'Löschen';

  @override
  String get tplSortRecentlyUpdated => 'Zuletzt geändert';

  @override
  String get tplSortTitleAsc => 'Name (A–Z)';

  @override
  String get tplSortLabel => 'Sortierung';

  @override
  String get tplSubtitle =>
      'Professionelle Fertigvorlagen + Ihre gespeicherten – Suchen, Filtern, Öffnen und Importieren, vollständig offline.';

  @override
  String get tplRefreshTooltip => 'Liste aktualisieren';

  @override
  String get tplSearchHint => 'Vorlagen suchen…';

  @override
  String get tplNoResultsTitle => 'Keine passenden Ergebnisse';

  @override
  String get tplNoResultsMessage =>
      'Versuchen Sie einen anderen Suchbegriff oder setzen Sie den Filter zurück.';

  @override
  String tplAddedToLocal(Object title) {
    return '„$title“ wurde zu Ihren lokalen Vorlagen hinzugefügt.';
  }

  @override
  String get tplCloudRequiresConnection =>
      'Das Speichern von Vorlagen in der Cloud erfordert eine Verbindung zu einem Supabase-Projekt. Speichern Sie sie stattdessen lokal.';

  @override
  String tplSavedToCloud(Object title) {
    return '„$title“ wurde in der Cloud gespeichert.';
  }

  @override
  String get tplRenamed => 'Die Vorlage wurde umbenannt.';

  @override
  String tplCopySuffix(Object title) {
    return '$title (Kopie)';
  }

  @override
  String tplCopyCreated(Object title) {
    return 'Eine Kopie von „$title“ wurde erstellt.';
  }

  @override
  String get tplNowPrivate => 'Die Vorlage ist jetzt privat.';

  @override
  String get tplNowPublic =>
      'Die Vorlage ist jetzt öffentlich (schreibgeschützt für andere).';

  @override
  String tplConfirmCloudDelete(Object title) {
    return '„$title“ wird endgültig aus der Cloud gelöscht. Keine Rücknahme möglich.';
  }

  @override
  String tplCloudDeleted(Object title) {
    return 'Die Vorlage „$title“ wurde gelöscht.';
  }

  @override
  String tplConfirmLocalDelete(Object title) {
    return '„$title“ wird von diesem Gerät gelöscht. Die ursprüngliche Fertigvorlage bleibt in der Bibliothek verfügbar.';
  }

  @override
  String tplLocalDeleted(Object title) {
    return 'Die lokale Vorlage „$title“ wurde gelöscht.';
  }

  @override
  String get tplDeleteTitle => 'Vorlage löschen';

  @override
  String get tplRenameTitle => 'Vorlagentitel';

  @override
  String get tplFieldTitle => 'Titel';

  @override
  String tplPreviewLabel(Object title) {
    return 'Vorschau: $title';
  }

  @override
  String tplCount(Object count) {
    return '$count Vorlage(n)';
  }

  @override
  String tplCloudLoadError(Object message) {
    return 'Cloud-Vorlagen konnten nicht geladen werden: $message';
  }

  @override
  String get tplPublicBadge => 'Öffentliche Vorlage';

  @override
  String get tplOrientationLandscape => 'Querformat';

  @override
  String get tplOrientationPortrait => 'Hochformat';

  @override
  String get tplPresetOffline => 'Fertigvorlage • offline verfügbar';

  @override
  String tplSchemaVersion(Object version) {
    return 'Schema v$version';
  }

  @override
  String get tplOpenAsTemplate => 'Als Vorlage öffnen';

  @override
  String get tplOpen => 'Öffnen';

  @override
  String get tplUseInBatch => 'In Massen-Generierung verwenden';

  @override
  String get tplImportLocal => 'Lokal importieren';

  @override
  String get tplSaveToCloud => 'In die Cloud speichern';

  @override
  String get tplDeleteLocal => 'Lokal löschen';

  @override
  String get tplRename => 'Umbenennen';

  @override
  String get tplMakePrivate => 'Privat machen';

  @override
  String get tplMakePublic => 'Öffentlich machen';

  @override
  String get tplNoDate => 'Kein Datum';

  @override
  String get amSubtitle =>
      'Laden Sie Logo, Siegel und Signatur einmal hoch und fügen Sie sie in jede Vorlage ein – auf Ihrem Gerät gespeichert und offline wiederverwendbar.';

  @override
  String get amSearchHint => 'Ressourcen suchen…';

  @override
  String get amTypeLabel => 'Typ';

  @override
  String get amUploadTooltip => 'Neue Ressource hochladen';

  @override
  String get amUpload => 'Ressource hochladen';

  @override
  String get amEmptyTitle => 'Noch keine Ressourcen';

  @override
  String get amEmptyMessage =>
      'Laden Sie Logo, Signatur oder Siegel Ihrer Organisation hoch und fügen Sie es über die Bild-Eigenschaftenleiste in jede Vorlage ein.';

  @override
  String get amNoResultsMessage =>
      'Versuchen Sie einen anderen Namen oder setzen Sie den Filter zurück.';

  @override
  String get amRenamed => 'Die Ressource wurde umbenannt.';

  @override
  String amMovedToType(Object type) {
    return 'Die Ressource wurde nach „$type“ verschoben.';
  }

  @override
  String get amDeleteTitle => 'Ressource löschen';

  @override
  String amConfirmDelete(Object name) {
    return '„$name“ wird von diesem Gerät gelöscht. Vorlagen, die es verwenden, verlieren das Bild (ohne Druckfehler).';
  }

  @override
  String amDeleted(Object name) {
    return 'Die Ressource „$name“ wurde gelöscht.';
  }

  @override
  String get amRenameTitle => 'Ressource umbenennen';

  @override
  String amCount(Object count) {
    return '$count Ressource(n)';
  }

  @override
  String amMakeType(Object type) {
    return 'Typ festlegen: $type';
  }

  @override
  String get amCacheLabel => 'Bildcache auf dem Datenträger';

  @override
  String amCacheUsage(Object count, Object size) {
    return '$count Datei(en) · $size';
  }

  @override
  String amCacheUsageOf(Object count, Object used, Object limit) {
    return '$count Datei(en) · $used von $limit';
  }

  @override
  String get amCacheEmpty => 'Noch kein Datenträger-Cache';

  @override
  String get amCacheClear => 'Cache leeren';

  @override
  String get amCacheCleared =>
      'Der Bildcache auf dem Datenträger wurde geleert.';

  @override
  String get commonRetry => 'Erneut versuchen';

  @override
  String get commonPrint => 'Drucken';

  @override
  String get commonExportPdf => 'PDF exportieren';

  @override
  String get commonExportFailed =>
      'Die PDF-Datei konnte nicht exportiert werden.';

  @override
  String get commonPrintFailed =>
      'Die Datei konnte nicht an den Drucker gesendet werden.';

  @override
  String commonExportReady(Object name) {
    return 'Die Datei ist bereit zum Speichern als $name.';
  }

  @override
  String get commonGenerating => 'Wird generiert…';

  @override
  String get commonDataPanelTitle => 'Beispieldaten';

  @override
  String evElementCount(Object count) {
    return '$count Element(e)';
  }

  @override
  String get evStatusDynamicFields => ' • dynamische Felder';

  @override
  String get evStatusUnsaved => ' • ungespeicherte Änderungen';

  @override
  String get tevNewTemplateTitle => 'Neue Vorlage';

  @override
  String get tevUnsavedTitle => 'Ungespeicherte Änderungen';

  @override
  String tevUnsavedMessage(Object title) {
    return 'Sie haben ungespeicherte Änderungen an „$title“. Möchten Sie sie vor dem Verlassen speichern?';
  }

  @override
  String get tevLeaveWithoutSaving => 'Ohne Speichern verlassen';

  @override
  String get tevSaveAndLeave => 'Speichern und verlassen';

  @override
  String get tevViewMode => 'Ansichtsmodus';

  @override
  String get tevModeEditor => 'Editor';

  @override
  String get tevModePreview => 'PDF-Vorschau';

  @override
  String get tevPaperDirection => 'Papierausrichtung';

  @override
  String get tevWidthCm => 'Breite (cm)';

  @override
  String get tevHeightCm => 'Höhe (cm)';

  @override
  String get tevUndo => 'Rückgängig (Ctrl+Z)';

  @override
  String get tevRedo => 'Wiederholen (Ctrl+Y)';

  @override
  String get tevSnapGrid => 'Einrastraster';

  @override
  String get tevGuidesOn => 'Intelligente Hilfslinien: an (ausschalten)';

  @override
  String get tevGuidesOff => 'Intelligente Hilfslinien: aus (einschalten)';

  @override
  String get tevZoom => 'Zoom';

  @override
  String get tevDocumentBackground => 'Dokumenthintergrund';

  @override
  String get tevFrameFromLibrary => 'Rahmen aus meiner Bibliothek';

  @override
  String get tevChangeTitle => 'Vorlagentitel ändern';

  @override
  String get tevMyTemplates => 'Meine Vorlagen';

  @override
  String get tevSaveAs => 'Speichern unter';

  @override
  String get tevSaveTemplate => 'Vorlage speichern';

  @override
  String get tevSaveUnavailable => 'Speichern nicht verfügbar';

  @override
  String get tevSaveNeedsSupabase =>
      'Speichern erfordert eine Verbindung zu einem Supabase-Projekt. Starten Sie die App mit Ihren Projektschlüsseln (env.json), um Vorlagen zu speichern.';

  @override
  String tevMissingAssets(Object list) {
    return 'Fehlende Ressourcen: $list – wählen Sie Rahmen/Ressource erneut in „Meine Bibliothek“, um leere Stellen zu vermeiden.';
  }

  @override
  String get tevTemplateLibraryNeedsSupabase =>
      'Die Vorlagenbibliothek erfordert eine Verbindung zu einem Supabase-Projekt.';

  @override
  String tevOpenedTemplate(Object title) {
    return '„$title“ wurde geöffnet.';
  }

  @override
  String get tevTitleHint => 'z. B. Abschlusszertifikat Projektmanagement-Kurs';

  @override
  String get tevContinue => 'Weiter';

  @override
  String get tevSavedTemplates => 'Meine gespeicherten Vorlagen';

  @override
  String get tevNoSavedTemplates =>
      'Noch keine gespeicherten Vorlagen. Speichern Sie eine über „Vorlage speichern“.';

  @override
  String get ecIncrease => 'Erhöhen';

  @override
  String get ecDecrease => 'Verringern';

  @override
  String get ecQuickPalette => 'Schnellpalette';

  @override
  String get ecFullPicker => 'Vollständige Farbauswahl';

  @override
  String get ecRemoveColor => 'Farbe entfernen';

  @override
  String get ecNone => 'Keine';

  @override
  String get ecPickColorTitle => 'Farbe wählen';

  @override
  String get ecApply => 'Anwenden';

  @override
  String tevBackgroundAdded(Object name) {
    return '„$name“ wurde als Dokumenthintergrund hinzugefügt.';
  }

  @override
  String get cfpUploadTooltip =>
      'Benutzerdefinierte Schrift hochladen (.ttf / .otf)';

  @override
  String get cfpManageTooltip => 'Hochgeladene Schriften verwalten';

  @override
  String get cfpNotice =>
      'Hochgeladene Schriften werden nur auf Ihrem Gerät gespeichert und sofort hier und beim Drucken verwendet – ohne Internet.';

  @override
  String get cfpMyFonts => 'Meine benutzerdefinierten Schriften';

  @override
  String get cfpNoFonts => 'Noch keine Schriften hochgeladen';

  @override
  String get cfpBuiltinOption => 'Keine (integrierte Schrift)';

  @override
  String get cfpGroupBuiltin => 'Integrierte Schriften';

  @override
  String get cfpGroupUploaded => 'Meine hochgeladenen Schriften';

  @override
  String get cfpGroupSystem => 'Systemschriften';

  @override
  String get cfpSearchHint => 'Schriften suchen…';

  @override
  String get cfpNoMatch => 'Keine passenden Schriften.';

  @override
  String get cfpPickTitle => 'Schriftdatei wählen (TTF oder OTF)';

  @override
  String cfpPickerError(Object error) {
    return 'Dateiauswahl konnte nicht geöffnet werden: $error';
  }

  @override
  String cfpReadError(Object name, Object error) {
    return '\"$name\" konnte nicht gelesen werden: $error';
  }

  @override
  String get cfpFontAdded =>
      'Die Schrift wurde hinzugefügt und sofort angewendet.';

  @override
  String cfpFontsAdded(Object count) {
    return '$count Schriften wurden hinzugefügt.';
  }

  @override
  String get cfpLibraryTitle => 'Meine Schriftbibliothek';

  @override
  String get cfpLibraryNotice =>
      'Alle Schriften werden nur auf Ihrem Gerät gespeichert. Warnung: Das Löschen einer von einer Vorlage verwendeten Schrift setzt diese auf die integrierte Schrift zurück, statt fehlzuschlagen.';

  @override
  String get cfpEmpty => 'Noch keine hochgeladenen Schriften.';

  @override
  String get cfpCoverageFull => 'Vollständige arabische Abdeckung';

  @override
  String get cfpCoveragePartial => 'Teilweise arabische Abdeckung';

  @override
  String get cfpUploadNew => 'Neue Schrift hochladen';

  @override
  String get ptpPrepError =>
      'Die Vorschau konnte nicht vorbereitet werden. Prüfen Sie die Vorlagendatei.';

  @override
  String ptpElapsedSize(Object ms, Object kb) {
    return '$ms ms — $kb KB';
  }

  @override
  String get ptpGeneratingNote =>
      '— die Vorschau wird automatisch aktualisiert';

  @override
  String get ptpGenerateFailedTitle =>
      'Die Vorschau konnte nicht erzeugt werden';

  @override
  String get ptpPreparingTitle => 'Engine wird vorbereitet…';

  @override
  String get ptpPreparingMessage =>
      'Integrierte Schriften werden geladen und die erste Dateiversion erzeugt.';

  @override
  String get ptpShowFailedTitle => 'Die Vorschau konnte nicht angezeigt werden';

  @override
  String cfgOverride(Object override) {
    return 'Ein alternativer Build mit expliziten Werten überschreibt die Datei: $override';
  }

  @override
  String get tevBackgroundTitle => 'Dokumenthintergrund aus meiner Bibliothek';

  @override
  String get tevAddElement => 'Element hinzufügen';

  @override
  String get commonUndo => 'Rückgängig';

  @override
  String get bpTitle => 'Massen-Generierung aus Excel';

  @override
  String get bpSubtitle =>
      'Importieren Sie eine .xlsx- oder .csv-Datei, ordnen Sie ihre Spalten den Vorlagenfeldern zu und erzeugen Sie ein PDF mit einer Seite pro Datensatz – alles auf Ihrem Gerät, offline.';

  @override
  String get bpStepTemplate => '1) Vorlage';

  @override
  String get bpLoadingSampleTemplate => 'Beispielvorlage wird geladen…';

  @override
  String bpTemplateInfo(Object name) {
    return 'Vorlage: $name • erforderliche Felder:';
  }

  @override
  String get bpLoadingTemplates => 'Ihre Vorlagen werden geladen…';

  @override
  String get bpNoTemplates =>
      'Noch keine gespeicherten Vorlagen – erstellen Sie eine im Editor oder importieren Sie sie aus der Vorlagenbibliothek.';

  @override
  String get bpTemplateFromMine => 'Vorlage aus meinen Vorlagen';

  @override
  String get bpSampleTemplatesHeader => '— Beispielvorlagen —';

  @override
  String bpTemplateEntry(Object title, Object source) {
    return '$title  •  $source';
  }

  @override
  String get bpSourceCloud => 'Cloud';

  @override
  String get bpSourceLocal => 'Lokal';

  @override
  String get bpStepDataFile => '2) Datendatei';

  @override
  String get bpReadingFile => 'Datei wird gelesen…';

  @override
  String get bpNoFileChosen =>
      'Noch keine Datei gewählt – unterstützte Formate:';

  @override
  String bpFileSummary(Object name, Object rows, Object cols) {
    return '$name — $rows Zeilen, $cols Spalten';
  }

  @override
  String bpSheetSuffix(Object name) {
    return ' (Blatt: $name)';
  }

  @override
  String get bpChooseFile => 'Datei wählen';

  @override
  String get bpRemove => 'Entfernen';

  @override
  String get bpHeaderRow => 'Kopfzeile';

  @override
  String bpAutoRow(Object n) {
    return 'Automatisch (Zeile $n)';
  }

  @override
  String bpRow(Object n) {
    return 'Zeile $n';
  }

  @override
  String bpAutoRowLong(Object n) {
    return 'Automatisch — Zeile $n';
  }

  @override
  String bpRowPreview(Object n, Object preview) {
    return 'Zeile $n: $preview';
  }

  @override
  String get bpEmptyRow => '(leere Zeile)';

  @override
  String get bpWorksheet => 'Arbeitsblatt';

  @override
  String get bpPickDataFile => 'Datendatei wählen (Excel oder CSV)';

  @override
  String bpReadFileError(Object error) {
    return 'Die Datei konnte nicht gelesen werden: $error';
  }

  @override
  String bpFileReadRows(Object rows, Object cols) {
    return 'Die Datei wurde lokal gelesen: $rows Zeilen und $cols Spalten.';
  }

  @override
  String bpSaveError(Object error) {
    return 'Die Änderung konnte nicht in der Vorlage gespeichert werden: $error';
  }

  @override
  String get bpMapFieldTitle => 'Diesem Element ein dynamisches Feld zuweisen';

  @override
  String get bpMapFieldBody =>
      'Nur der Text dieses Elements wird durch ein Feld ersetzt; kein anderes Element wird verändert.';

  @override
  String get bpUndoConvert => 'Die Umwandlung wurde rückgängig gemacht.';

  @override
  String get bpUndoConvertSaved =>
      'Die Umwandlung wurde rückgängig gemacht und der Text in der Vorlage wiederhergestellt.';

  @override
  String bpRestoreError(Object error) {
    return 'Der Text konnte in der Vorlage nicht wiederhergestellt werden: $error';
  }

  @override
  String bpGeneratedReport(Object count) {
    return '$count Datensatz/Datensätze erzeugt';
  }

  @override
  String bpSkippedSuffix(Object count) {
    return ' und $count übersprungen';
  }

  @override
  String get bpReadyToSave => 'Die Datei ist bereit zum Speichern.';

  @override
  String get bpStepMapping => '3) Spalten Feldern zuordnen';

  @override
  String get bpChooseFileFirst =>
      'Wählen Sie zuerst eine Datei, um die Zuordnungstabelle anzuzeigen.';

  @override
  String get bpNoDynamicFields =>
      'Keine dynamischen Felder in der aktuellen Vorlage.';

  @override
  String bpMappedCount(Object mapped, Object total) {
    return '$mapped von $total Spalten zugeordnet';
  }

  @override
  String get bpAutoMapHint =>
      'Nach Auswahl der Datei wird eine intelligente Auto-Zuordnung vorgeschlagen; Sie können jede Spalte bearbeiten.';

  @override
  String get bpNoFieldsHelp =>
      'Die gewählte Vorlage hat keine dynamischen Felder, es gibt also nichts den Dateispalten zuzuordnen. Öffnen Sie die Vorlage im Editor, fügen Sie ein „dynamisches Feld“ in das Namensfeld ein, speichern Sie und versuchen Sie es erneut.';

  @override
  String get bpAutoMap => 'Automatisch zuordnen';

  @override
  String get bpClearMapping => 'Zuordnung löschen';

  @override
  String get bpNameFieldWarning =>
      'Diese Vorlage hat kein dynamisches Namensfeld – ordnen Sie die Namensspalte keinem Datums- oder Referenzfeld zu, sonst könnte der Name an der falschen Stelle gedruckt werden. Wählen Sie den Namensschlüssel aus der Spaltenliste oder wandeln Sie den festen Namenstext im Editor in ein dynamisches Feld um.';

  @override
  String bpStaticNameHints(Object preview) {
    return 'Fester Text, der wie ein Name aussieht: „$preview“ – kein dynamisches Feld ersetzt ihn.';
  }

  @override
  String get bpConvertToNameField => 'In ein Teilnehmernamen-Feld umwandeln';

  @override
  String bpDuplicateField(Object field) {
    return 'Das Feld „$field“ ist mehreren Spalten zugeordnet. Ordnen Sie jedem Feld eine Spalte zu.';
  }

  @override
  String bpUnmappedColumns(Object count) {
    return '$count nicht zugeordnete Spalte(n) – ihre Daten werden in den Zertifikaten nicht verwendet.';
  }

  @override
  String bpColumn(Object n) {
    return 'Spalte $n';
  }

  @override
  String get bpEmptyCell => '(leer)';

  @override
  String get bpUnmapped => '— nicht zugeordnet —';

  @override
  String get bpStepMissing => '4) Leere Zellen und fehlende Daten';

  @override
  String get bpNoNotes => 'Keine Hinweise vor Auswahl der Datei.';

  @override
  String get bpStepGenerate => '5) Generieren';

  @override
  String bpGenerating(Object progress) {
    return 'Wird generiert… $progress';
  }

  @override
  String get bpGenerateHint =>
      'Eine PDF-Datei, eine Seite pro erzeugtem Datensatz.';

  @override
  String get bpGeneratePickFile =>
      'Wählen Sie zuerst eine Datendatei, um die Generierung zu aktivieren.';

  @override
  String get bpMappingInvalid =>
      'Die Zuordnung ist ungültig – dasselbe Feld ist zwei Spalten zugeordnet.';

  @override
  String get bpMapAtLeastOne =>
      'Ordnen Sie mindestens eine Spalte einem Vorlagenfeld zu, um die Generierung zu aktivieren.';

  @override
  String get bpGenerateCertificates => 'Zertifikate erstellen';

  @override
  String get bpRegenerate => 'Neu generieren';

  @override
  String get bpStatGenerated => 'Erzeugt';

  @override
  String get bpStatSkipped => 'Übersprungen';

  @override
  String get bpStatPages => 'Seiten';

  @override
  String get bpStatSize => 'Größe';

  @override
  String bpKilobytes(Object value) {
    return '$value KB';
  }

  @override
  String get bpStatTime => 'Zeit';

  @override
  String bpMilliseconds(Object value) {
    return '$value ms';
  }

  @override
  String bpCompletion(Object pct, Object total) {
    return '$pct% von $total Zeilen abgeschlossen.';
  }

  @override
  String get bpSkippedRows => 'Nicht erzeugte Zeilen:';

  @override
  String bpRowSkipReason(Object n, Object reason) {
    return 'Zeile $n: $reason';
  }

  @override
  String get bpPreviewHere => 'Die Vorschau erscheint hier';

  @override
  String get bpPreviewHint =>
      'Wählen Sie die Datendatei, passen Sie die Zuordnung an und drücken Sie „Zertifikate erstellen“ – die erste Seite der erzeugten Datei erscheint hier.';

  @override
  String get bpAssignByTapTitle => 'Felder per Tippen zuweisen';

  @override
  String get bpAssignByTapBody =>
      'Tippen Sie auf einen beliebigen Text in der Vorlage, um ihn selbst einem dynamischen Feld zuzuweisen. Kein anderes Element wird verändert – weder Datum noch Name der Leitung noch fester Text.';

  @override
  String get bpNoTexts => 'Keine Texte in dieser Vorlage.';

  @override
  String get bpEmptyText => '(leerer Text)';

  @override
  String get bpDynamicFieldTap => 'Dynamisches Feld – zum Ändern tippen';

  @override
  String get bpStaticTextTap => 'Fester Text – zum Zuweisen tippen';

  @override
  String get bpAssignField => 'Feld zuweisen';

  @override
  String get bpKindCertificate => 'Zertifikat';

  @override
  String get bpKindContract => 'Vertrag';

  @override
  String bpLoadSampleError(Object error) {
    return 'Die Beispielvorlage konnte nicht geladen werden: $error';
  }

  @override
  String bpReadSheetError(Object error) {
    return 'Das Blatt konnte nicht gelesen werden: $error';
  }

  @override
  String bpUpdateHeaderRowError(Object error) {
    return 'Die Kopfzeile konnte nicht aktualisiert werden: $error';
  }

  @override
  String get bpChooseTemplateFirst =>
      'Wählen Sie vor dem Generieren eine Vorlage (Zertifikat oder Vertrag).';

  @override
  String bpBatchTitle(Object kind) {
    return '$kind Massen — JoodCraft';
  }

  @override
  String bpGenerateError(Object error) {
    return 'Die Massen-Generierung konnte nicht ausgeführt werden: $error';
  }

  @override
  String get bpWarnNoDynamicFields =>
      'Diese Vorlage hat keine dynamischen Felder – die Daten ändern sich nicht zwischen Datensätzen. Fügen Sie ein Feld „Name des Teilnehmers“ über die Editorleiste hinzu und speichern Sie die Vorlage.';

  @override
  String get bpWarnNoNameField =>
      'Diese Vorlage hat kein dynamisches Namensfeld – die Namensspalte könnte einem Datums- oder Referenzfeld zugeordnet werden und der Name an der falschen Stelle gedruckt werden. Wandeln Sie den festen Namenstext in ein Feld um oder gestalten Sie die Vorlage neu.';

  @override
  String bpAssignedTemp(Object token) {
    return 'Dieses Element wurde für die aktuelle Generierung $token zugewiesen – die anderen Elemente bleiben unberührt. Speichern Sie die Vorlage, um die Änderung dauerhaft zu machen.';
  }

  @override
  String bpAssignedSaved(Object token) {
    return 'Dieses Element wurde $token zugewiesen und die Änderung in der Vorlage gespeichert. Die anderen Elemente bleiben unberührt.';
  }

  @override
  String get commonShow => 'Anzeigen';

  @override
  String get commonHide => 'Ausblenden';

  @override
  String get themeSwitchToLight => 'Zum hellen Design wechseln';

  @override
  String get themeSwitchToDark => 'Zum dunklen Design wechseln';

  @override
  String commonComingSoonPhase(Object phase) {
    return 'In Arbeit — Phase $phase';
  }

  @override
  String get cbNewCertificateTitle => 'Neues Zertifikat';

  @override
  String get cbNewContractTitle => 'Neuer Vertrag';

  @override
  String get cbBeneficiaryDataTitle => 'Empfängerdaten (Beispiel)';

  @override
  String get cbContractDataTitle => 'Vertragsdaten (Beispiel)';

  @override
  String get editorSendBackward => 'Nach hinten';

  @override
  String get editorRotateLeft => '90° nach links drehen';

  @override
  String get editorRotateRight => '90° nach rechts drehen';

  @override
  String get editorFlipH => 'Horizontal spiegeln';

  @override
  String get editorFlipV => 'Vertikal spiegeln';

  @override
  String get editorTransform => 'Transformationen';

  @override
  String get editorToolSelect => 'Auswahl';

  @override
  String get editorToolShapes => 'Formen';

  @override
  String get editorFillType => 'Fülltyp';

  @override
  String get editorFillSolid => 'Einfarbig';

  @override
  String get editorGradientLinear => 'Linearer Verlauf';

  @override
  String get editorGradientRadial => 'Radialer Verlauf';

  @override
  String get editorGradientAngle => 'Verlaufswinkel';

  @override
  String get editorShadowEnable => 'Schatten hinzufügen';

  @override
  String get editorShadowColor => 'Schattenfarbe';

  @override
  String get editorShadowBlur => 'Weichzeichnen';

  @override
  String get editorShadowOffsetX => 'Versatz X';

  @override
  String get editorShadowOffsetY => 'Versatz Y';

  @override
  String get editorShadowSpread => 'Ausbreitung';

  @override
  String get editorShadowRemove => 'Schatten entfernen';

  @override
  String get editorPoints => 'Punkte';

  @override
  String get editorInnerRadius => 'Innenradius';

  @override
  String get editorCornerTopLeft => 'Oben links';

  @override
  String get editorCornerTopRight => 'Oben rechts';

  @override
  String get editorCornerBottomRight => 'Unten rechts';

  @override
  String get editorCornerBottomLeft => 'Unten links';

  @override
  String get editorDashPattern => 'Strichmuster';

  @override
  String get editorBooleanOps => 'Boolesche Operationen';

  @override
  String get editorBooleanUnion => 'Vereinigen';

  @override
  String get editorBooleanSubtract => 'Subtrahieren';

  @override
  String get editorBooleanIntersect => 'Schnittmenge';

  @override
  String get editorBooleanUngroup => 'Trennen';

  @override
  String get paletteStar => 'Stern';

  @override
  String get palettePolygon => 'Vieleck';

  @override
  String get editorBooleanExclude => 'Ausschluss';

  @override
  String get editorBooleanHint =>
      'Der zusammengeführte Pfad ist ein einziges boolesches Ergebnis (ohne Innenkanten) und lässt sich jederzeit trennen.';

  @override
  String get editorDockTools => 'Werkzeugpanel';

  @override
  String get editorDockAnchor => 'Andockposition';

  @override
  String get editorDockTopBar => 'Obere Leiste';

  @override
  String get editorDockInspector => 'Seitenpanel';

  @override
  String get editorDockLeftRail => 'Seitenleiste';

  @override
  String get editorDockFloating => 'Schwebend';

  @override
  String get editorDockCollapse => 'Werkzeuge einklappen';

  @override
  String get editorDockExpand => 'Werkzeuge ausklappen';

  @override
  String get editorDockResize => 'Zum Ändern der Größe ziehen';

  @override
  String get editorDockDropHint => 'Loslassen zum Andocken an';

  @override
  String get editorMoreTools => 'Weitere Werkzeuge';

  @override
  String get editorDocumentProperties => 'Dokumenteigenschaften';

  @override
  String get editorDockReset => 'Standard-Andocken wiederherstellen';

  @override
  String get editorTextShadow => 'Textschatten';

  @override
  String get editorTextShadowAdd => 'Textschatten hinzufügen';

  @override
  String get editorShadowOpacity => 'Schatten-Deckkraft';

  @override
  String get genderMale => 'Männlich';

  @override
  String get genderFemale => 'Weiblich';

  @override
  String get genderPreviewAutoHint =>
      'Klicken, um die Vorgabe aufzuheben (automatisch)';

  @override
  String get genderPresetCompleted => '„completed“ (m./w.)';

  @override
  String get genderPresetPassed => '„passed“ (m./w.)';

  @override
  String get genderPresetForStudent => '„für den Studenten“ (m./w.)';

  @override
  String get genderPresetStudent => '„der Student“ (m./w.)';

  @override
  String get genderPresetToHim => '„für ihn / für sie“';

  @override
  String get genderPresetHonoring => '„der ausgezeichnete Teilnehmer“ (m./w.)';

  @override
  String get editorGenderSnippet => 'Bedingten Abschnitt einfügen';

  @override
  String get editorGenderSnippetHint =>
      'Fügt eine Phrase ein, die automatisch mit dem Geschlecht wechselt.';

  @override
  String get bpGenderReviewTitle => 'Geschlechtsprüfung (männlich/weiblich)';

  @override
  String get bpGenderReviewSubtitle =>
      'Das Geschlecht wird aus dem Namen oder einer Spalte „Geschlecht“ erkannt — korrigieren Sie Sonderfälle vor dem Druck.';

  @override
  String get bpGenderRow => 'Zeile';

  @override
  String get bpGenderDetected => 'Erkannt';

  @override
  String get bpGenderEffective => 'Angewendet';

  @override
  String get bpGenderNameColumn => 'Name';

  @override
  String get bpGenderEditName => 'Namen bearbeiten';

  @override
  String get bpGenderNameHint => 'Geben Sie den richtigen Namen ein';

  @override
  String get bpGenderClearOverrides => 'Korrekturen löschen';

  @override
  String get bpGenderOverridden => 'Manuell korrigiert';

  @override
  String get bpGenderUnknownName => '—';

  @override
  String get bpOutputTitle => 'Speicherort für Zertifikate';

  @override
  String get bpOutputHint =>
      'Wählen Sie den Ordner zum Speichern der erzeugten PDF oder starten Sie am Standardspeicherort.';

  @override
  String get bpOutputPickFolder => 'Ordner wählen…';

  @override
  String get bpOutputStart => 'Generierung starten';

  @override
  String get bpOutputPathLabel => 'Ausgewählter Ordner';

  @override
  String get bpOutputNoFolder =>
      'Kein Ordner gewählt – nur Drucken und Export.';

  @override
  String get bpOpenFolder => 'Ordner öffnen';

  @override
  String get bpOutputSavedTitle => 'PDF-Datei gespeichert';

  @override
  String get bpOpenFolderFailed => 'Ordner konnte nicht geöffnet werden.';

  @override
  String get bpOutputNameLabel => 'Name der Exportdatei';

  @override
  String get bpOutputNameHint => 'Geben Sie einen Namen ohne Erweiterung ein';

  @override
  String get bpOutputNamePreviewLabel => 'Wird gespeichert als';

  @override
  String get bpOutputModeLabel => 'Speichermodus';

  @override
  String get bpOutputModeCombined => 'Eine kombinierte Datei';

  @override
  String get bpOutputModeIndividual => 'Eine eigene Datei pro Person';

  @override
  String get hubTitle => 'Neues Projekt';

  @override
  String get hubSubtitle =>
      'Wählen Sie ein fertiges Format oder legen Sie Ihr eigenes fest – die Leinwand öffnet im exakten Format und Seitenverhältnis.';

  @override
  String get hubKindSingle => 'Einzelblatt-Drucke und Dokumente';

  @override
  String get hubKindMulti => 'Mehrseitige Bücher und Publikationen';

  @override
  String get hubKindSingleHint =>
      'Ein Blatt: Zertifikate, Verträge, Karten, Sitzplatznummern, Grußkarten.';

  @override
  String get hubKindMultiHint =>
      'Mehrseitig: Buch, Magazin, Broschüre, Bericht, Katalog.';

  @override
  String get hubGroupCertificates => 'Zertifikate und Verträge';

  @override
  String get hubGroupCards => 'Karten und Ausweise';

  @override
  String get hubGroupSeat => 'Sitzplatznummern und Etiketten';

  @override
  String get hubGroupGreeting => 'Grußkarten';

  @override
  String get hubGroupPublications => 'Bücher und Publikationen';

  @override
  String get hubGroupCustom => 'Eigenes Format';

  @override
  String get hubDigitalBadge => 'Digital';

  @override
  String get hubCreate => 'Erstellen';

  @override
  String get hubCustomCardBody =>
      'Geben Sie Ihre Maße in der gewünschten Einheit ein und starten Sie im eigenen Format.';

  @override
  String get hubCustomName => 'Projektname';

  @override
  String get hubCustomNameHint => 'z. B. Einladungskarte';

  @override
  String get hubCustomPreview => 'Endgültiges Format';

  @override
  String get hubCustomCreate => 'Leinwand erstellen';

  @override
  String get hubCustomType => 'Projekttyp';

  @override
  String get hubSearchHint => 'Formate suchen…';

  @override
  String get hubNoResults =>
      'Kein passendes Format – versuchen Sie ein anderes Stichwort.';

  @override
  String get hubAspectRatio => 'Verhältnis';

  @override
  String get destNewProject => 'Neues Projekt';

  @override
  String get destNewProjectDesc =>
      'Wählen Sie ein fertiges oder eigenes Format und legen Sie sofort los.';

  @override
  String get ptpImpositionToggle => 'Druckauslegung';

  @override
  String get ptpImpositionNoFit =>
      'Das Blatt ist zu klein für dieses Element — verkleinern Sie die Ränder oder wählen Sie ein größeres Blatt.';

  @override
  String get editorEffectsTitle => 'Effekte & Farbanpassungen';

  @override
  String get editorShadowGroup => 'Schatten';

  @override
  String get editorOuterGlow => 'Äußerer Schein';

  @override
  String get editorInnerGlow => 'Innerer Schein';

  @override
  String get editorGlowAdd => 'Schein hinzufügen';

  @override
  String get editorGlowRemove => 'Schein entfernen';

  @override
  String get editorGlowColor => 'Scheinfarbe';

  @override
  String get editorGlowRadius => 'Scheinradius';

  @override
  String get editorGlowSpread => 'Schein-Ausbreitung';

  @override
  String get editorGlowOpacity => 'Schein-Deckkraft';

  @override
  String get editorAdjustGroup => 'Farbanpassungen';

  @override
  String get editorAdjustBrightness => 'Helligkeit';

  @override
  String get editorAdjustContrast => 'Kontrast';

  @override
  String get editorAdjustSaturation => 'Sättigung';

  @override
  String get editorAdjustHue => 'Farbton';

  @override
  String get editorAdjustReset => 'Zurücksetzen';

  @override
  String get bpOutputSavedFolderTitle =>
      'Dateien in einem eigenen Ordner gespeichert';

  @override
  String get hubDetailsTitle => 'Formatdetails';

  @override
  String get hubDetailsHint =>
      'Vorausgefüllte Standardvorgabe — Format im Raster wählen oder Maße direkt ändern.';

  @override
  String get hubFilterAll => 'Alle';

  @override
  String get hubFilterRecent => 'Zuletzt verwendet';

  @override
  String get hubFilterSeat => 'Sitzplatznummern';

  @override
  String get hubFilterGreeting => 'Grußkarten und Bildschirme';

  @override
  String get hubRecentEmpty =>
      'Noch keine zuletzt verwendeten Formate — jedes neue Projekt erscheint hier.';

  @override
  String get hubDocTitle => 'Projektname';

  @override
  String get hubDocTitleHint => 'Neues Projekt - 1';

  @override
  String get hubWidth => 'Breite';

  @override
  String get hubHeight => 'Höhe';

  @override
  String get hubUnitLabel => 'Einheit';

  @override
  String get hubOrientationLabel => 'Ausrichtung';

  @override
  String get hubPortrait => 'Hochformat';

  @override
  String get hubLandscape => 'Querformat';

  @override
  String get hubVariantLabel => 'Typ';

  @override
  String get hubResolutionLabel => 'Auflösung';

  @override
  String get hubResolutionUnitLabel => 'Auflösungseinheit';

  @override
  String get hubColorModeLabel => 'Farbmodus';

  @override
  String get hubBackgroundLabel => 'Hintergrundfarbe';

  @override
  String get hubBackgroundWhite => 'Weiß';

  @override
  String get hubBackgroundTransparent => 'Transparent';

  @override
  String get hubBackgroundBlack => 'Schwarz';

  @override
  String get hubBackgroundCustom => 'Eigene Farbe';

  @override
  String get hubCreateProject => 'Projekt erstellen';

  @override
  String get hubCustomFamilyTitle => 'Eigene Größe';

  @override
  String get newDocTitle => 'Neues Dokument';

  @override
  String get newDocScopeSocial => 'Bildschirme und Grußkarten';

  @override
  String get newDocFilterCertificates => 'Zertifikate';

  @override
  String get newDocFilterCards => 'Karten';

  @override
  String get newDocFilterGreeting => 'Grußkarten';

  @override
  String get newDocFilterPublications => 'Publikationen';

  @override
  String get menuFile => 'Datei';

  @override
  String get menuEdit => 'Bearbeiten';

  @override
  String get menuView => 'Ansicht';

  @override
  String get menuTools => 'Werkzeuge';

  @override
  String get menuHelp => 'Hilfe';

  @override
  String get menuNewDocument => 'Neues Dokument…';

  @override
  String get menuPurgeRecent => 'Zuletzt verwendete Größen leeren';

  @override
  String get menuPurgeImageCache => 'Bildcache leeren';

  @override
  String get menuPreviewCertificate => 'Beispielzertifikat anzeigen';

  @override
  String get menuPreviewContract => 'Beispielvertrag anzeigen';

  @override
  String get menuAbout => 'Über JoodCraft';

  @override
  String get actionNewShort => '+ Neu';

  @override
  String get dashLocalMode => 'Lokal';

  @override
  String get dashLocalStorage =>
      'Lokal auf diesem Gerät gespeichert — kein Projekt wird auf einen Server hochgeladen.';

  @override
  String get dashRecentProjects => 'Letzte Projekte';

  @override
  String get dashRecentEmpty =>
      'Noch keine gespeicherten Projekte auf diesem Gerät — erstelle ein Dokument, es erscheint sofort hier.';

  @override
  String get dashRecentOpen => 'Projekt öffnen';

  @override
  String get editorTransformPosition => 'Transformieren & Position';

  @override
  String get editorTransformPositionHint => 'Position, Größe und Drehwinkel';

  @override
  String get editorAppearanceEffects => 'Aussehen & Effekte';

  @override
  String get editorAppearanceEffectsHint =>
      'Füllung, Kontur, Leuchten und Schatten';

  @override
  String get editorTypographyHint => 'Schrift, Größe, Ausrichtung und Abstand';

  @override
  String get editorPageSettingsHint => 'Größe und Maßeinheit';

  @override
  String get editorBackgroundHint => 'Seitenfarbe oder Farbverlauf';

  @override
  String get editorPrecisionHint => 'Feines Verschieben und Skalieren';

  @override
  String get joodExportProject => 'Projekt exportieren (.jood)';

  @override
  String get joodImportProject => 'Projekt öffnen (.jood)';

  @override
  String get joodExportReady => 'Die Projektdatei ist zum Speichern bereit.';

  @override
  String get joodExportFailed =>
      'Die Projektdatei konnte nicht exportiert werden.';

  @override
  String get joodImportOpened => 'Importiertes Projekt geöffnet.';

  @override
  String get joodImportFailed =>
      'Die Projektdatei konnte nicht geöffnet werden.';

  @override
  String get joodRecoveryTitle => 'Nicht gespeicherter Entwurf';

  @override
  String get joodRecoveryMessage =>
      'Es gibt einen nicht gespeicherten Entwurf aus einer früheren Sitzung. Möchten Sie ihn wiederherstellen?';

  @override
  String get joodRecoveryRestore => 'Wiederherstellen';

  @override
  String get joodRecoveryDiscard => 'Verwerfen';

  @override
  String get joodRecoveryRestored => 'Entwurf wiederhergestellt.';

  @override
  String get joodAutosaveSaved => 'Automatisch gespeichert';

  @override
  String get joodAutosaveSaving => 'Speichern…';

  @override
  String get editorConfirm => 'Bestätigen';

  @override
  String get admTitle => 'Lokale Administratorenverwaltung';

  @override
  String get admRefresh => 'Aktualisieren';

  @override
  String get admTabAdmins => 'Administratoren';

  @override
  String get admTabTransfer => 'Geräteübertragung';

  @override
  String get admTabAudit => 'Exportprotokoll';

  @override
  String get admListTitle => 'Administratorkonten auf diesem Gerät';

  @override
  String get admAdd => 'Administrator hinzufügen';

  @override
  String get admNoAdmins => 'Noch keine Administratorkonten.';

  @override
  String get admLoading => 'Admin-Konten auf diesem Gerät werden geladen…';

  @override
  String get admRoleOwner => 'Hauptadministrator';

  @override
  String get admCurrent => 'Sie';

  @override
  String get admCurrentCardTitle => 'Aktuelles Konto auf diesem Gerät';

  @override
  String get admRoleAdmin => 'Administrator';

  @override
  String get admSwitchTitle => 'Schneller Kontowechsel';

  @override
  String get admSwitchPrompt =>
      'Wähle den lokalen Benutzernamen eines Unter-Administrators auf diesem Gerät und gib sein lokales Passwort ein, um sofort in seine Sitzung zu wechseln – offene Projektentwürfe werden zuvor gespeichert, die Master-Lizenz bleibt unberührt.';

  @override
  String get admSwitchNoOthers =>
      'Keine weiteren Unter-Administratoren auf diesem Gerät. Füge zuerst über den Administratoren-Bildschirm einen neuen Admin hinzu.';

  @override
  String get admSwitchPick => 'Lokaler Benutzername';

  @override
  String get admSwitchPassword => 'Lokales Passwort des gewählten Kontos';

  @override
  String get admSwitchPickPassword =>
      'Wähle einen Benutzernamen und gib das Passwort ein.';

  @override
  String get admSwitchWrongPassword => 'Falsches Passwort.';

  @override
  String get admSwitchFailed =>
      'Kontowechsel nicht möglich. Versuchen Sie es erneut.';

  @override
  String get admSwitchSuccess => 'Konto erfolgreich gewechselt.';

  @override
  String get admSwitchAccount => 'Konto wechseln';

  @override
  String get admSwitchAction => 'Jetzt wechseln';

  @override
  String get admColAdmin => 'Administrator';

  @override
  String get admColUsername => 'Lokaler Benutzername';

  @override
  String get admColRole => 'Rolle';

  @override
  String get admColCreated => 'Hinzugefügt am';

  @override
  String get admColActions => 'Aktionen';

  @override
  String get destJoodWriter => 'Jood Writer';

  @override
  String get destJoodWriterDesc =>
      'Textdokumente und Berichte mit automatisch fließenden Seiten.';

  @override
  String get admCreatedAt => 'Erstellt';

  @override
  String get admEdit => 'Daten bearbeiten';

  @override
  String get admChangePassword => 'Passwort ändern';

  @override
  String get admPromote => 'Zum Hauptadministrator befördern';

  @override
  String get admDemote => 'Zum Administrator herabstufen';

  @override
  String get admDelete => 'Konto löschen';

  @override
  String admDeleteConfirm(Object name) {
    return '„$name“ wird dauerhaft von diesem Gerät gelöscht. Das kann nicht rückgängig gemacht werden.';
  }

  @override
  String get admPromoted => 'Zum Hauptadministrator befördert.';

  @override
  String get admDemoted => 'Zum Administrator herabgestuft.';

  @override
  String get admDeleted => 'Konto gelöscht.';

  @override
  String get admCreated => 'Neuer Administrator hinzugefügt.';

  @override
  String get admUpdated => 'Administratordaten aktualisiert.';

  @override
  String get admPasswordChanged => 'Passwort geändert.';

  @override
  String get admTransferInfoTitle => 'Wie funktioniert die Übertragung?';

  @override
  String get admTransferInfo1 =>
      'Die Kontotabelle (mit Passwort-Hashes, niemals mit den Passwörtern) wird in einer Datei exportiert, die mit einer von Ihnen gewählten Passphrase verschlüsselt ist.';

  @override
  String get admTransferInfo2 =>
      'Übertragen Sie die Datei oder den Code auf das andere Gerät und importieren Sie sie dort mit derselben Passphrase – die Konten funktionieren mit denselben Rechten.';

  @override
  String get admTransferInfo3 =>
      'Nichts wird an einen Server gesendet: die Übertragung erfolgt vollständig manuell zwischen lokalen Geräten.';

  @override
  String get admExport => 'Konten exportieren';

  @override
  String get admExportPassphrase => 'Export-Passphrase';

  @override
  String get admPassphraseConfirm => 'Passphrase bestätigen';

  @override
  String get admExportRisk =>
      'Mir ist bewusst, dass jeder, der diesen Code und seine Passphrase besitzt, sich mit diesen Konten anmelden kann; ich werde ihn sorgsam weitergeben.';

  @override
  String get admExportGenerate => 'Verschlüsselten Code erzeugen';

  @override
  String get admExportFile => 'In eigener Datei speichern';

  @override
  String get admExportDone =>
      'Verschlüsselter Code erzeugt. Kopieren oder in einer Datei speichern.';

  @override
  String get admExportFileSaved => 'Verschlüsselte Kontodatei gespeichert.';

  @override
  String get admPassphraseTooShort =>
      'Verwenden Sie mindestens 6 Zeichen für die Passphrase.';

  @override
  String get admPassphraseMismatch => 'Die Passphrasen stimmen nicht überein.';

  @override
  String get admAcceptRiskRequired =>
      'Bestätigen Sie zuerst, dass Sie das Risiko des Teilens verstehen.';

  @override
  String admFileError(Object error) {
    return 'Die Datei konnte nicht verarbeitet werden: $error';
  }

  @override
  String get admImport => 'Konten importieren';

  @override
  String get admImportCode => 'Kontocode';

  @override
  String get admImportPassphrase => 'Datei-Passphrase';

  @override
  String get admImportReplace => 'Passwörter vorhandener Konten ersetzen';

  @override
  String get admImportPick => 'Datei wählen';

  @override
  String get admImportRun => 'Jetzt importieren';

  @override
  String get admImportCodeRequired =>
      'Fügen Sie zuerst den Code ein oder wählen Sie eine Datei.';

  @override
  String get admImportPassphraseRequired =>
      'Geben Sie die Datei-Passphrase ein.';

  @override
  String admImportDone(int added, int updated, int skipped) {
    return 'Importiert: $added neu, $updated aktualisiert, $skipped übersprungen.';
  }

  @override
  String get admAuditTitle =>
      'Protokoll ausgestellter Zertifikate und Dokumente';

  @override
  String get admAuditClear => 'Protokoll leeren';

  @override
  String get admAuditEmpty =>
      'Noch keine Exporte. Jedes exportierte Zertifikat oder jeder Vertrag wird hier mit Datum und ausstellendem Administrator protokolliert.';

  @override
  String get admAuditBy => 'Von';

  @override
  String get admAuditPages => 'Seiten';

  @override
  String get admAuditClearConfirm =>
      'Das gesamte Exportprotokoll wird von diesem Gerät gelöscht. Das kann nicht rückgängig gemacht werden.';

  @override
  String get admAuditCleared => 'Protokoll geleert.';

  @override
  String get admUnavailableTitle =>
      'Die Verwaltung ist derzeit nicht verfügbar';

  @override
  String get admUnavailableBody =>
      'Die Administratorenverwaltung funktioniert, wenn die App mit einem lokalen Konto läuft (LocalAuthRepository), sodass Konten von diesem Gerät gelesen werden.';

  @override
  String get pdfExportTypeTitle => 'Exporttyp';

  @override
  String get pdfExportTypeHint =>
      'Wählen Sie das Dateiformat vor dem Export aus.';

  @override
  String get pdfExportTypeImages => 'Bilder';

  @override
  String get pdfExportTypeImagesDesc =>
      '100 % Deckungsgleichheit — größere Datei';

  @override
  String get pdfExportTypeImagesNotCopyable => 'Text ist nicht kopierbar';

  @override
  String get pdfExportTypeVector => 'Vektor';

  @override
  String get pdfExportTypeVectorDesc => 'Kopierbarer Text — kleinere Datei';

  @override
  String get pdfExportTypeVectorCopyable =>
      'Text lässt sich kopieren und durchsuchen';

  @override
  String get bpPdfEngineLabel => 'Zeichen-Engine';

  @override
  String get pdfExportTypeVectorBestFor =>
      'Ideal für den professionellen Druck';

  @override
  String get invCategoryTitle => 'Einladungen und Anlässe';

  @override
  String get invCategoryRamadan => 'Ramadan';

  @override
  String get invCategoryEid => 'Eid';

  @override
  String get invCategoryWedding => 'Hochzeit';

  @override
  String get invRamadan1Title => 'Ramadan Karim — Klassisch';

  @override
  String get invRamadan2Title => 'Ramadan Karim — Story';

  @override
  String get invEid1Title => 'Eid Mubarak — Klassisch';

  @override
  String get invEid2Title => 'Eid Mubarak — Story';

  @override
  String get invWedding1Title => 'Hochzeit — Klassisch';

  @override
  String get invWedding2Title => 'Hochzeit — Modern';

  @override
  String get invWedding3Title => 'Hochzeit — Story';

  @override
  String get invSizeA6Portrait => 'A6 hochkant (105×148 mm)';

  @override
  String get invSizeA6Landscape => 'A6 quer (148×105 mm)';

  @override
  String get invSizeSquare148 => 'Druckquadrat (148×148 mm)';

  @override
  String get invSizeA5Folded => 'A5 gefaltet (105×148 mm)';

  @override
  String get invSizeInstagramSquare => 'Instagram Quadrat (1080×1080)';

  @override
  String get invSizeInstagramPortrait => 'Instagram hochkant (1080×1350)';

  @override
  String get invSizeInstagramStory => 'Instagram Story (1080×1920)';

  @override
  String get invSizeWhatsAppStatus => 'WhatsApp Status (1080×1920)';

  @override
  String get invSizeFacebookPost => 'Facebook Post (1200×630)';

  @override
  String get invExportFormatPNG => 'PNG (für soziale Medien)';

  @override
  String get invExportFormatPDF => 'PDF (zum Drucken)';

  @override
  String get invExportFormatBoth => 'PNG + PDF';

  @override
  String get invBulkModeTitle => 'Persönliche Einladungen im Stapel';

  @override
  String get invBulkModeHint => 'Eine Karte pro Name — Einzelexport.';

  @override
  String get invPreviewTitle => 'Vorschau der ersten 3 Exemplare';

  @override
  String get invExportFormat => 'Exportformat';

  @override
  String get invNameFieldMissing => 'Diese Vorlage hat kein Namensfeld';

  @override
  String invDuplicateNames(Object count) {
    return 'Doppelte Namen: $count';
  }

  @override
  String invEmptyNames(Object count) {
    return 'Leere Zellen: $count — werden übersprungen';
  }

  @override
  String get invZIPOption => 'In eine ZIP-Datei packen';

  @override
  String get invIndexCSVOption => 'CSV-Index erstellen';

  @override
  String invProgressText(Object done, Object total) {
    return '$done von $total erstellt';
  }

  @override
  String get navEditors => 'Editoren';

  @override
  String get navLibraries => 'Bibliotheken';

  @override
  String get navAdmin => 'Verwaltung';

  @override
  String get navUser => 'Konto';

  @override
  String get bpWorkTypeLabel => 'Vorlagentyp';

  @override
  String get bpExportFormatLabel => 'Exporttyp';

  @override
  String get bpKindInvitation => 'Einladung';

  @override
  String get invPackOptions => 'Ausgabeoptionen';

  @override
  String get tplCertClassicTitle => 'Klassisches Marineblaues Zertifikat';

  @override
  String get tplCertClassicDesc =>
      'Klassisches marineblaues Zertifikat mit doppeltem Goldrahmen und Ziersternen in den Ecken.';

  @override
  String get tplCertMinimalTitle => 'Minimales Marineblaues Zertifikat';

  @override
  String get tplCertMinimalDesc =>
      'Klares minimales Marineblaues Design mit einer einzigen goldenen Linie und viel Freiraum.';

  @override
  String get tplCertIslamicTitle => 'Zertifikat mit islamischem Ornament';

  @override
  String get tplCertIslamicDesc =>
      'Marineblaues Zertifikat mit goldenen Kanten, islamischen geometrischen Ornamenten und Amiri-Schrift.';

  @override
  String get tplCertBandTitle => 'Zertifikat mit Goldstreifen';

  @override
  String get tplCertBandDesc =>
      'Marineblaues Zertifikat mit waagerechten Goldstreifen oben und unten.';

  @override
  String get tplCertDiagonalTitle => 'Dynamisches diagonales Zertifikat';

  @override
  String get tplCertDiagonalDesc =>
      'Marineblaues Zertifikat mit schrag liegenden goldenen geometrischen Formen voller Bewegung.';

  @override
  String get tplCertSquareTitle => 'Elegantes quadratisches Zertifikat';

  @override
  String get tplCertSquareDesc =>
      'Marineblaues Zertifikat mit symmetrischem quadratischem Goldrahmen und rundem Siegel oben.';

  @override
  String get navInvitationsEngine => 'Einladungs-Engine';

  @override
  String get aboutTitle => 'Über JoodCraft';

  @override
  String get aboutTagline =>
      'Offizielle arabische Zertifikate und Verträge erstellen';

  @override
  String aboutVersion(Object version) {
    return 'Version $version';
  }

  @override
  String get aboutSummaryTitle => 'Überblick';

  @override
  String get aboutSummaryBody =>
      'JoodCraft ist eine Desktop- und Web-App, die vollständig auf Ihrem Gerät läuft: Sie liest Excel-Dateien und erzeugt Zertifikate und Verträge als PDF mit im Programm gebündelten arabischen Schriften. Projekte, Vorlagen und Assets bleiben in einer lokalen Datenbank — nichts wird hochgeladen.';

  @override
  String get aboutFeaturesTitle => 'Hauptfunktionen';

  @override
  String get aboutFeatureOffline =>
      'Vollständig offline: kein Internet, kein Upload';

  @override
  String get aboutFeatureArabicFonts =>
      'Gebündelte arabische Schriften mit präziser Formung und RTL';

  @override
  String get aboutFeatureExcel =>
      'Liest Excel und CSV und ordnet Spalten automatisch Feldern zu';

  @override
  String get aboutFeatureBatch =>
      'Hunderte Zertifikate auf einmal — eine Datei oder eine pro Person';

  @override
  String get aboutFeatureVisualEditor =>
      'Visueller Drag-and-Drop-Editor mit Mehrfachauswahl, Rückgängig und Wiederherstellen';

  @override
  String get aboutFeatureInvitations =>
      'Fertige Einladungen für Ramadan, Eid und Hochzeiten in Druck- und Social-Media-Formaten';

  @override
  String get aboutFeatureExports =>
      'Export von PDF, PNG und teilbaren Jood-Projekten';

  @override
  String get aboutDeveloperTitle => 'Entwickler';

  @override
  String get aboutDeveloperName => 'Seraj Abdullah Al-Badawi';

  @override
  String get aboutDeveloperEmail => 'serajelroh@gmail.com';

  @override
  String get aboutDeveloperStatus => 'Persönliches Projekt — in Entwicklung';

  @override
  String get aboutLicenses => 'Lizenzen anzeigen';

  @override
  String get aboutFeedback => 'Feedback senden';

  @override
  String get aboutFeedbackCopied =>
      'E-Mail kopiert — Ihr Feedback ist willkommen';

  @override
  String get aboutCreditsTitle => 'Danksagung';

  @override
  String get aboutCreditsBody =>
      'Diese App wurde mit Flutter und Open-Source-Bibliotheken entwickelt — Dank an die Flutter-Community und alle Beitragenden dieser Bibliotheken.';

  @override
  String get jwPagesSettings => 'Seiteneinstellungen';

  @override
  String get jwPagesMultiple => 'Mehrere Seiten';

  @override
  String get jwPagesMultipleHint =>
      'Blatt halbieren, um zwei Seiten auf einem Blatt zu drucken';

  @override
  String get jwPagesSingle => 'Normal (eine Seite)';

  @override
  String get jwPagesA4ToA5Portrait => 'A4 → 2 × A5 hochkant (Broschüre)';

  @override
  String get jwPagesA4ToA5Landscape => 'A4 → 2 × A5 querformat';

  @override
  String get jwPagesPreview => 'Vorschau';

  @override
  String get aboutLinksTitle => 'Links';

  @override
  String get aboutDescription =>
      'JoodCraft ist eine vollständige arabische Plattform zur Erstellung von Zertifikaten, Verträgen und Einladungen in Profiqualität. Entwerfen Sie eine Vorlage visuell und verknüpfen Sie sie mit einer Excel-Datei, um Hunderte Dokumente mit präziser arabischer Typografie und korrekter Schreibrichtung zu erzeugen — offline und ohne Server.';

  @override
  String get aboutFeatures => 'Funktionen';

  @override
  String get aboutFeature10Languages => '10 unterstützte Sprachen';

  @override
  String get aboutFeatureArabicText => 'Präzise arabische Formgebung';

  @override
  String get aboutFeatureBulkGeneration => 'Massenausgabe aus Excel';

  @override
  String get aboutFeaturePdfExport => 'Hochwertiger PDF-Export';

  @override
  String get aboutDeveloper => 'Entwickler';

  @override
  String get aboutDeveloperNote => 'Persönliches Projekt — in Entwicklung';

  @override
  String get aboutLinks => 'Links';

  @override
  String get aboutViewLicenses => 'Lizenzen anzeigen';

  @override
  String get aboutSendFeedback => 'Feedback senden';

  @override
  String get aboutCredits => 'Danksagung';

  @override
  String get aboutCreditsText =>
      'JoodCraft wurde mit Flutter und Dart sowie Open-Source-Bibliotheken erstellt. Danke an alle Mitwirkenden.';

  @override
  String get navInvitationTemplates => 'Einladungsvorlagen';

  @override
  String get ocrTitle => 'Text aus Bild extrahieren';

  @override
  String get ocrShowRaw => 'Originaltext anzeigen';

  @override
  String get ocrSubtitle => 'Bild oder PDF importieren und Text extrahieren';

  @override
  String get ocrImportImage => 'Bild importieren';

  @override
  String get ocrImportPdf => 'PDF importieren';

  @override
  String get ocrExtractText => 'Text extrahieren';

  @override
  String get ocrProcessing => 'Verarbeitung läuft...';

  @override
  String get ocrPreview => 'Textvorschau';

  @override
  String get ocrInsertInEditor => 'In Editor einfügen';

  @override
  String get ocrCopyToClipboard => 'Kopieren';

  @override
  String get ocrRetry => 'Erneut versuchen';

  @override
  String get ocrAccept => 'Übernehmen';

  @override
  String get ocrCleanupNote =>
      'Der Text wurde automatisch bereinigt — prüfen Sie ihn vor dem Speichern.';

  @override
  String get ocrCancel => 'Abbrechen';

  @override
  String get ocrLanguageLabel => 'Sprache';

  @override
  String get ocrLanguageArabic => 'Arabisch';

  @override
  String get ocrLanguageEnglish => 'Englisch';

  @override
  String get ocrLanguageBoth => 'Arabisch und Englisch';

  @override
  String get ocrAccuracyNote =>
      'Die Erkennungsgenauigkeit liegt vielleicht unter 100 % — prüfen Sie den Text vor dem Speichern.';

  @override
  String get ocrNoTextFound => 'Im Bild wurde kein Text gefunden.';

  @override
  String get ocrInvalidImage => 'Ungültiges Bild.';

  @override
  String get ocrError =>
      'Der Text konnte nicht extrahiert werden. Versuchen Sie es erneut.';

  @override
  String get ocrEngineMissing =>
      'Tesseract wurde nicht gefunden — installieren Sie es und versuchen Sie es erneut.';

  @override
  String get ocrLanguageDataMissing =>
      'Die Sprachdaten sind nicht mit Tesseract installiert.';

  @override
  String get ocrNoImage => 'Importieren Sie zuerst ein Bild oder PDF.';

  @override
  String get ocrCopyDone => 'Text in die Zwischenablage kopiert.';

  @override
  String get ocrConfidence => 'Konfidenz';

  @override
  String get ocrPsmLabel => 'Segmentierung';

  @override
  String get ocrPsmAuto => 'Automatisch';

  @override
  String get ocrPsmBlock => 'Ein Textblock';

  @override
  String get ocrPsmLine => 'Eine Zeile';

  @override
  String get ocrPsmSparse => 'Verstreuter Text';

  @override
  String get ocrScaleLabel => 'Zoom';

  @override
  String get ocrPdfPages => 'Seiten';

  @override
  String get ocrInsertInWriter => 'In Jood Writer einfügen';

  @override
  String get ocrTessHint =>
      'Erfordert die Installation von Tesseract auf diesem Gerät.';

  @override
  String get jwRibbonHome => 'Startseite';

  @override
  String get jwRibbonSetup => 'Layout';

  @override
  String get jwRibbonDesign => 'Gestaltung';

  @override
  String get jwRibbonFile => 'Datei';

  @override
  String get jwRibbonReview => 'Überprüfung';

  @override
  String get jwSectionFonts => 'Schriftarten';

  @override
  String get jwFontFamily => 'Schriftfamilie';

  @override
  String get jwFontSizeDown => 'Schriftgröße verkleinern';

  @override
  String get jwFontSizeLabel => 'Schriftgröße';

  @override
  String get jwFontSizeUp => 'Schriftgröße vergrößern';

  @override
  String get jwBold => 'Fett';

  @override
  String get jwItalic => 'Kursiv';

  @override
  String get jwUnderline => 'Unterstrichen';

  @override
  String get jwStrikethrough => 'Durchgestrichen';

  @override
  String get jwTextColor => 'Textfarbe';

  @override
  String get jwNoColor => 'Keine Farbe';

  @override
  String get jwHighlightColor => 'Text hervorheben';

  @override
  String get jwClearFormatting => 'Formatierung löschen';

  @override
  String get jwSectionAlignment => 'Ausrichtung';

  @override
  String get jwAlignRight => 'Rechtsbündig';

  @override
  String get jwAlignCenter => 'Zentrieren';

  @override
  String get jwAlignLeft => 'Linksbündig';

  @override
  String get jwJustify => 'Blocksatz';

  @override
  String get jwLineSpacing => 'Zeilenabstand';

  @override
  String get jwParagraphSpacing => 'Absatzabstand';

  @override
  String get jwSpacingNone => 'Keine';

  @override
  String get jwSpacingValue => 'Abstand';

  @override
  String get jwDirectionRtl => 'Rechts nach links (RTL)';

  @override
  String get jwDirectionLtr => 'Links nach rechts (LTR)';

  @override
  String get jwSectionLists => 'Listen und Abstand';

  @override
  String get jwBulletList => 'Aufzählungszeichen';

  @override
  String get jwNumberedList => 'Nummerierte Liste';

  @override
  String get jwIndentIncrease => 'Einzug vergrößern';

  @override
  String get jwIndentDecrease => 'Einzug verkleinern';

  @override
  String get jwFirstLineIndentIncrease => 'Einzug 1. Zeile +';

  @override
  String get jwFirstLineIndentDecrease => 'Einzug 1. Zeile −';

  @override
  String get jwHangingIndent => 'Hängender Einzug';

  @override
  String get jwSectionParagraph => 'Absatz';

  @override
  String get jwParagraphDialog => 'Absatzdialog';

  @override
  String get jwFormatPainter => 'Formatkopierer';

  @override
  String get jwFormatPainterOnce => 'Formatkopierer — ein Block';

  @override
  String get jwFormatPainterLocked =>
      'Formatkopierer — gesperrt (klicken zum Stoppen)';

  @override
  String get jwFormatPainterShort => 'Format';

  @override
  String get jwSectionBlocks => 'Blöcke';

  @override
  String get jwAddBlock => 'Block hinzufügen';

  @override
  String get jwDeleteBlock => 'Block löschen';

  @override
  String get jwPageBreak => 'Seitenumbruch (neue Seite am Cursor)';

  @override
  String get jwSpreadView => 'Doppelseite';

  @override
  String get jwParagraphDialogTitle => 'Absatz-Einstellungen';

  @override
  String get jwAlignLabel => 'Ausrichtung';

  @override
  String get jwIndentationLabel => 'Einzug (cm)';

  @override
  String get jwIndentGeneral => 'Absatz-Einzug';

  @override
  String get jwIndentFirstLine => 'Erste Zeile';

  @override
  String get jwSpacingLabel => 'Abstand';

  @override
  String get jwSpaceBefore => 'Vorher (px)';

  @override
  String get jwSpaceAfter => 'Nachher (px)';

  @override
  String get jwLineHeightLabel => 'Zeilenhöhe';

  @override
  String get jwCancel => 'Abbrechen';

  @override
  String get jwOk => 'OK';

  @override
  String get jwSectionPageSetup => 'Seiteneinrichtung';

  @override
  String get jwPageSize => 'Seitengröße';

  @override
  String get jwOrientation => 'Seitenausrichtung';

  @override
  String get jwPortrait => 'Hochformat';

  @override
  String get jwLandscape => 'Querformat';

  @override
  String get jwPageMargins => 'Seitenränder';

  @override
  String get jwMarginsNarrow => 'Schmal';

  @override
  String get jwMarginsNormal => 'Normal';

  @override
  String get jwMarginsWide => 'Weit';

  @override
  String get jwMarginsCustom => 'Benutzerdefiniert…';

  @override
  String get jwSectionPageBackground => 'Seitenhintergrund';

  @override
  String get jwPageColor => 'Seitenfarbe';

  @override
  String get jwPageColorClear => 'Weiß (Standard)';

  @override
  String get jwWatermark => 'Wasserzeichen';

  @override
  String get jwWatermarkShort => 'Zeichen';

  @override
  String get jwPageBorder => 'Seitenrahmen';

  @override
  String get jwSectionPageNumbering => 'Seitenzahlen';

  @override
  String get jwPageNumberEnable => 'Seitenzahlen anzeigen';

  @override
  String get jwPageNumberAlignLabel => 'Nummerausrichtung';

  @override
  String get jwPageNumberFormat => 'Zahlenformat';

  @override
  String get jwPageNumberStartAt => 'Beginnen bei';

  @override
  String get jwPageNumberDifferentFirst => 'Erste Seite anders';

  @override
  String get jwPageNumberRemove => 'Seitenzahlen entfernen';

  @override
  String get jwCustomMarginsTitle => 'Benutzerdefinierte Ränder (mm)';

  @override
  String get jwMarginTop => 'Oben';

  @override
  String get jwMarginBottom => 'Unten';

  @override
  String get jwMarginRight => 'Rechts';

  @override
  String get jwMarginLeft => 'Links';

  @override
  String get jwWatermarkTitle => 'Wasserzeichen';

  @override
  String get jwWatermarkHint =>
      'Transparenter Hintergrundtext (leer zum Entfernen)';

  @override
  String get jwWatermarkClear => 'Entfernen';

  @override
  String get jwSectionTemplates => 'Vorlagen';

  @override
  String get jwTemplateCategory => 'Vorlagenkategorie';

  @override
  String get jwTemplateAll => 'Alle Kategorien';

  @override
  String get jwTemplates => 'Vorlagen';

  @override
  String get jwSectionInsert => 'Einfügen';

  @override
  String get jwShapes => 'Formen';

  @override
  String get jwInsertImage => 'Bild einfügen';

  @override
  String get jwInsertImageShort => 'Bild';

  @override
  String get jwInsertTable => 'Tabelle einfügen';

  @override
  String get jwInsertSymbol => 'Symbol einfügen';

  @override
  String get jwSectionShapeFormat => 'Format von Formen';

  @override
  String get jwShapeFill => 'Füllung';

  @override
  String get jwShapeOutline => 'Kontur';

  @override
  String get jwShapeStrokeWidth => 'Konturstärke';

  @override
  String get jwShapeDefaultsHint => 'Wird beim Einfügen angewendet';

  @override
  String get jwActionFailed => 'Aktion fehlgeschlagen';

  @override
  String get jwNewDocConfirm => 'Neues Dokument';

  @override
  String get jwNewDocConfirmMessage =>
      'Sie haben ungespeicherte Änderungen. Neues Dokument beginnen?';

  @override
  String get jwNewDocument => 'Neues Dokument';

  @override
  String get jwRecentFilesEmpty => 'Noch keine gespeicherten Dokumente';

  @override
  String get jwRecentFiles => 'Zuletzt verwendet';

  @override
  String get jwOpenDocument => 'Dokument öffnen';

  @override
  String get jwSaveAs => 'Speichern unter';

  @override
  String get jwDocumentTitle => 'Dokumenttitel';

  @override
  String get jwSaved => 'Dokument gespeichert';

  @override
  String get jwSectionFile => 'Datei';

  @override
  String get jwNewShort => 'Neu';

  @override
  String get jwOpenShort => 'Öffnen';

  @override
  String get jwSave => 'Speichern (Ctrl+S)';

  @override
  String get jwSaveShort => 'Speichern';

  @override
  String get jwSectionExport => 'Exportieren';

  @override
  String get jwExportPdf => 'Als PDF exportieren';

  @override
  String get jwExportPng => 'Als PNG exportieren';

  @override
  String get jwExportDocx => 'Als DOCX exportieren';

  @override
  String get jwExportHtml => 'Als HTML exportieren';

  @override
  String get jwPrint => 'Drucken (Ctrl+P)';

  @override
  String get jwPrintShort => 'Drucken';

  @override
  String get jwSectionUndo => 'Widerrufen';

  @override
  String get jwUndo => 'Rückgängig (Ctrl+Z)';

  @override
  String get jwRedo => 'Wiederholen (Ctrl+Y)';

  @override
  String get jwUndoHistory => 'Widerrufsverlauf';

  @override
  String get jwHistoryShort => 'Verlauf';

  @override
  String get jwSectionSettings => 'Einstellungen';

  @override
  String get jwDocumentProperties => 'Dokumenteigenschaften';

  @override
  String get jwPageSetup => 'Seiteneinrichtung';

  @override
  String get jwLanguage => 'Sprache';

  @override
  String get jwAutoSave => 'Automatisch speichern';

  @override
  String get jwAutoSaveShort => 'Automatisch';

  @override
  String get jwLanguageArabic =>
      'Editor-Sprache: Arabisch — das Band unterstützt zehn Sprachen je Einstellung.';

  @override
  String get jwHistoryStep => 'Schritt';

  @override
  String get jwHistoryCurrent => 'Aktuell';

  @override
  String get jwClose => 'Schließen';

  @override
  String get jwSectionProofing => 'Prüfung';

  @override
  String get jwSpelling => 'Rechtschreibung (wiederholte Wörter)';

  @override
  String get jwSpellingShort => 'Prüfen';

  @override
  String get jwGrammar => 'Grammatik (Statistik & Wiederholung)';

  @override
  String get jwWordCount => 'Wörter';

  @override
  String get jwCharacterCount => 'Zeichen';

  @override
  String get jwReadingTime => 'Min. Lesezeit';

  @override
  String get jwSectionFind => 'Suchen';

  @override
  String get jwFind => 'Suchen (Ctrl+F)';

  @override
  String get jwFindShort => 'Suchen';

  @override
  String get jwReplace => 'Ersetzen (Ctrl+H)';

  @override
  String get jwGoTo => 'Gehe zu (Ctrl+G)';

  @override
  String get jwFindNext => 'Weitersuchen';

  @override
  String get jwFindPrevious => 'Vorheriges suchen';

  @override
  String get jwNoMatches => 'Keine Ergebnisse';

  @override
  String get jwSectionInsertReview => 'Einfügen';

  @override
  String get jwInsertDate => 'Datum einfügen';

  @override
  String get jwInsertTime => 'Uhrzeit einfügen';

  @override
  String get jwInsertEquation => 'Gleichung einfügen';

  @override
  String get jwInsertFootnote => 'Fußnote einfügen';

  @override
  String get jwSectionComments => 'Kommentare';

  @override
  String get jwNewComment => 'Neuer Kommentar';

  @override
  String get jwNewCommentShort => 'Kommentar';

  @override
  String get jwShowComments => 'Kommentare anzeigen';

  @override
  String get jwDeleteComment => 'Kommentare dieses Blocks löschen';

  @override
  String get jwCommentDeleted => 'Kommentar gelöscht';

  @override
  String get jwTrackChanges => 'Änderungen verfolgen (Verlauf)';

  @override
  String get jwProofingTitle => 'Prüfung & Statistik';

  @override
  String get jwStatsTitle => 'Dokumentstatistik';

  @override
  String get jwCharacterCountNoSpaces => 'Zeichen (ohne Leerzeichen)';

  @override
  String get jwLinesCount => 'Zeilen';

  @override
  String get jwParagraphsCount => 'Absätze';

  @override
  String get jwRepeatedWords => 'Wiederholte aufeinanderfolgende Wörter';

  @override
  String get jwNoRepeatedWords =>
      'Keine wiederholten Wörter — Text ist sauber.';

  @override
  String get jwFindPlaceholder => 'Zum Suchen eingeben…';

  @override
  String jwMatchesCount(Object current, Object total) {
    return 'Ergebnis $current von $total';
  }

  @override
  String get jwFindTitle => 'Suchen und Ersetzen';

  @override
  String get jwReplacePlaceholder => 'Ersetzen durch…';

  @override
  String get jwReplaceButton => 'Ersetzen';

  @override
  String get jwReplacedBlocks => 'Blöcke ersetzt';

  @override
  String get jwReplaceAll => 'Alle ersetzen';

  @override
  String get jwGoToBlockLabel => 'Blocknummer';

  @override
  String get jwCommentHint => 'Kommentartext für den aktiven Block';

  @override
  String get jwCommentsTitle => 'Dokumentkommentare';

  @override
  String get jwCommentsEmpty => 'Noch keine Kommentare.';

  @override
  String get jwCommentAtBlock => 'Block';

  @override
  String get jwJumpToBlock => 'Gehe zu';
}
