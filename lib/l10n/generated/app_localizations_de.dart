// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

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
  String get dashRoadmapSupabase =>
      'Supabase-Datenbank einrichten (Tabellen + RLS + Trigger)';

  @override
  String get dashRoadmapModular =>
      'Eine skalierbare modulare Feature-First-Struktur';

  @override
  String get dashRoadmapTheme =>
      'Das visuelle Markenthema mit RTL-Unterstützung in der Schrift Cairo';

  @override
  String get dashRoadmapAuth =>
      'Authentifizierung: Anmeldung, Kontoerstellung und Passwort-Reset';

  @override
  String get dashPhaseOneDone => 'Erste Phase abgeschlossen';

  @override
  String get dashNextPhase =>
      'Als Nächstes: die Offline-PDF-Engine und arabische Schriften, dann der visuelle Vorlageneditor.';

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
}
