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
}
