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
}
