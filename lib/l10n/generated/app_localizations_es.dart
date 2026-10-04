// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTagline =>
      'Genera certificados y contratos oficiales sin conexión';

  @override
  String get navDashboard => 'Panel';

  @override
  String get navCertificates => 'Creador de certificados';

  @override
  String get navContracts => 'Creador de contratos';

  @override
  String get navBatch => 'Generación por lotes';

  @override
  String get navTemplates => 'Biblioteca de plantillas';

  @override
  String get navAssets => 'Recursos y firmas';

  @override
  String get actionSignOut => 'Cerrar sesión';

  @override
  String get actionBackToDashboard => 'Volver al panel';

  @override
  String get offlineProcessingLabel => 'Procesamiento local';

  @override
  String get themeTooltip => 'Cambiar tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get languageTooltip => 'Cambiar idioma';

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
  String get configMissingKeysTitle =>
      'No se encontraron las claves de conexión';

  @override
  String get configMissingKeysBody =>
      'Al iniciar, la aplicación busca las claves en tres fuentes: el indicador --dart-define, luego un archivo env.json en el disco (raíz o assets/env/) y, por último, la copia incluida en la aplicación; no se encontró ninguna. Cree el archivo, complételo una vez y ejecute sin indicadores:';

  @override
  String get configEnvNote =>
      'El paquete declara assets/env/ como recurso, así que la ausencia del archivo no rompe una compilación limpia. Créelo desde env.example.json o ejecute: dart run tool/ensure_env.dart — solo se requiere la clave anon/public; service_role nunca se usa en la aplicación.';

  @override
  String get routeNotFoundTitle => 'Página no encontrada';

  @override
  String get routeNotFoundBody =>
      'La ruta solicitada no está definida en la aplicación:';

  @override
  String get editorPrecisionTitle => 'Controles de precisión';

  @override
  String get editorNudgeStep => 'Paso de desplazamiento';

  @override
  String get editorNudgeStepHint =>
      'Las flechas del lienzo también desplazan con Shift = 10px.';

  @override
  String get editorNudgeUp => 'Desplazar arriba';

  @override
  String get editorNudgeLeft => 'Desplazar a la izquierda';

  @override
  String get editorNudgeDown => 'Desplazar abajo';

  @override
  String get editorNudgeRight => 'Desplazar a la derecha';

  @override
  String get editorScale => 'Escala';

  @override
  String get editorScaleHint =>
      'Escalado relativo alrededor del centro del elemento (rueda sobre los botones para pasos más finos).';

  @override
  String get editorScaleUp => 'Ampliar';

  @override
  String get editorScaleDown => 'Reducir';

  @override
  String get editorDecorTitle => 'Decoración vectorial';

  @override
  String get editorDecorKind => 'Tipo de decoración';

  @override
  String get editorDecorPalette => 'Paleta de colores';

  @override
  String get editorDecorLayers => 'Número de capas';

  @override
  String get editorDecorSeed => 'Semilla';

  @override
  String get editorDecorThickness => 'Grosor';

  @override
  String get editorDecorPrimary => 'Color principal';

  @override
  String get editorDecorSecondary => 'Color secundario';

  @override
  String get editorDecorAccent => 'Color de acento';

  @override
  String get editorDecorGradient => 'Degradado de capas';

  @override
  String get editorDecorGallery => 'Galería de ajustes';

  @override
  String get editorDecorGalleryTitle => 'Galería de decoraciones listas';

  @override
  String get editorClose => 'Cerrar';

  @override
  String get editorDecorPaletteCustom => 'Personalizada';

  @override
  String get decorKindModernWave => 'Ondas modernas';

  @override
  String get decorKindPaperCut => 'Corte de papel por capas';

  @override
  String get decorKindClassicCorner => 'Marco clásico decorado';

  @override
  String get decorKindGuilloche => 'Patrón guilloché';

  @override
  String get decorKindRibbonBanner => 'Cinta / banda';

  @override
  String get decorPaletteRoyalGold => 'Oro real';

  @override
  String get decorPaletteRoyalBlue => 'Azul real';

  @override
  String get decorPaletteEmerald => 'Esmeralda';

  @override
  String get decorPaletteBurgundy => 'Borgoña';

  @override
  String get decorPaletteMidnight => 'Azul medianoche';

  @override
  String get decorPaletteMono => 'Gris monocromo';

  @override
  String get editorSignatureTitle => 'Bloque de firmas';

  @override
  String get editorSignatureCount => 'Número de firmas';

  @override
  String get signatureCountOne => 'Una firma';

  @override
  String get signatureCountTwo => 'Dos firmas';

  @override
  String get signatureCountThree => 'Tres firmas';

  @override
  String get editorSignatureOrder => 'Orden de las casillas';

  @override
  String get editorSignatureOrderHint =>
      'En documentos árabes la primera casilla queda a la derecha del todo.';

  @override
  String get editorSignatureFirstRight => 'Primera a la derecha';

  @override
  String get editorSignatureFirstLeft => 'Primera a la izquierda';

  @override
  String get editorDirectionAuto => 'Automático';

  @override
  String get editorSignatureImageAlign => 'Alineación de la imagen';

  @override
  String get editorAlignStart => 'Inicio';

  @override
  String get editorAlignCenter => 'Centro';

  @override
  String get editorAlignEnd => 'Final';

  @override
  String get editorSignatureDivider => 'Línea de firma';

  @override
  String get editorVisible => 'Visible';

  @override
  String get editorHidden => 'Oculto';

  @override
  String get editorSignatureNameSize => 'Tamaño del nombre';

  @override
  String get editorSignatureRoleSize => 'Tamaño del cargo';

  @override
  String get editorSignatureSpacing => 'Espaciado';

  @override
  String get editorSignatureImageSize => 'Tamaño de la imagen';

  @override
  String get editorSignatureNameColor => 'Color del nombre';

  @override
  String get editorSignatureRoleColor => 'Color del cargo';

  @override
  String get editorFont => 'Fuente';

  @override
  String get editorImageSource => 'Origen de la imagen';

  @override
  String get imageSourceAppAssets => 'Recursos de la aplicación';

  @override
  String get imageSourceMyLibrary => 'Mi biblioteca de recursos';

  @override
  String get imageSourceLocalFile => 'Archivo local';

  @override
  String get imageSourceEmbedded => 'Datos incrustados';

  @override
  String get editorSignatureChangeImage => 'Cambiar imagen de firma';

  @override
  String get editorSignatureAddImage => 'Añadir imagen de firma';

  @override
  String get editorSignatureRemoveImage => 'Quitar imagen de firma';

  @override
  String get editorSignaturePickImageTitle =>
      'Elegir una imagen de firma de mi biblioteca';

  @override
  String get editorSignatureSlot => 'Casilla';

  @override
  String get editorSignatureRoleField => 'Cargo (p. ej. Director general)';

  @override
  String get editorSignatureNameField =>
      'Nombre del firmante (acepta un campo dinámico)';

  @override
  String get editorFromMyLibrary => 'Desde mi biblioteca';

  @override
  String get paletteSignatureBlock => 'Firmas';

  @override
  String get editorInsertFromLibraryTooltip =>
      'Insertar directamente un marco o un logo subido';

  @override
  String get unsupportedElementVersionNote =>
      'Este elemento proviene de una versión más reciente del editor: se conserva tal cual y no se puede editar aquí.';

  @override
  String editorSelectedCount(Object count) {
    return '$count seleccionados';
  }

  @override
  String get editorClearSelection => 'Borrar selección';

  @override
  String get editorGroup => 'Grupo';

  @override
  String get editorOpacity => 'Opacidad';

  @override
  String get editorBringToFront => 'Traer al frente';

  @override
  String get editorSendToBack => 'Enviar al fondo';

  @override
  String get editorDuplicate => 'Duplicar';

  @override
  String get editorDeleteSelected => 'Eliminar selección';

  @override
  String get editorGroupDragHint =>
      'Arrastra el grupo con el ratón, usa las flechas para mover con precisión (Shift = 10px) y Ctrl + clic para ajustar la selección.';

  @override
  String get editorBringForward => 'Traer adelante';

  @override
  String get editorDuplicateElement => 'Duplicar elemento';

  @override
  String get editorDeleteElement => 'Eliminar elemento';

  @override
  String get editorPageSettings => 'Ajustes de página';

  @override
  String get editorPageSize => 'Tamaño';

  @override
  String get editorUnit => 'Unidad';

  @override
  String get editorWidth => 'Ancho';

  @override
  String get editorHeight => 'Alto';

  @override
  String get editorLabelText => 'Texto';

  @override
  String get editorLabelShape => 'Forma';

  @override
  String get editorLabelSeal => 'Sello';

  @override
  String get editorLabelDecoration => 'Decoración vectorial';

  @override
  String get editorLabelSignature => 'Bloque de firmas';

  @override
  String get editorLabelImage => 'Imagen / logotipo';

  @override
  String get editorLabelQr => 'Código QR';

  @override
  String get editorLabelUnknown => 'Elemento no compatible';

  @override
  String get editorLabelDynamicField => 'Campo dinámico';

  @override
  String get editorPositionAndSize => 'Posición y tamaño';

  @override
  String get editorPosX => 'X';

  @override
  String get editorPosY => 'Y';

  @override
  String get editorRotation => 'Rotación';

  @override
  String get editorTextFormat => 'Formato de texto';

  @override
  String get editorConvertToField => 'Convertir en campo dinámico';

  @override
  String get editorFontWeight => 'Grosor';

  @override
  String get editorWeightRegular => 'Normal';

  @override
  String get editorWeightSemiBold => 'Medio';

  @override
  String get editorWeightBold => 'Negrita';

  @override
  String get editorFontSize => 'Tamaño de fuente';

  @override
  String get editorLetterSpacing => 'Espaciado entre letras';

  @override
  String get editorLineHeight => 'Altura de línea';

  @override
  String get editorTextColor => 'Color del texto';

  @override
  String get editorTextBackground => 'Fondo del texto';

  @override
  String get editorTextAlign => 'Alineación';

  @override
  String get editorAlignJustify => 'Justificado';

  @override
  String get editorJustifyMode => 'Método de justificación';

  @override
  String get editorJustifyHint =>
      'La kashida se aplica en el archivo PDF (la vista previa muestra el ajuste por espacios)';

  @override
  String get editorJustifySpaces => 'Espacios';

  @override
  String get editorJustifyKashida => 'Kashida';

  @override
  String get editorVerticalAlign => 'Alineación vertical';

  @override
  String get editorVerticalTop => 'Arriba';

  @override
  String get editorVerticalBottom => 'Abajo';

  @override
  String get editorDirection => 'Dirección';

  @override
  String get editorDirectionHint => 'Atajo de alternancia: Ctrl+Shift+D';

  @override
  String get editorDirectionRtl => 'Árabe (RTL)';

  @override
  String get editorDirectionLtr => 'Latino (LTR)';

  @override
  String get editorImage => 'Imagen';

  @override
  String get editorSource => 'Origen';

  @override
  String get editorImageFit => 'Ajuste de imagen';

  @override
  String get editorFitContain => 'Contener';

  @override
  String get editorFitCover => 'Cubrir';

  @override
  String get editorFitFill => 'Estirar';

  @override
  String get assetPickerEmptyHint =>
      'Aún no has subido recursos. Sube un logotipo, una firma o un sello para usarlo aquí y al imprimir.';

  @override
  String get assetPickerNoneOption => 'Ninguno (otro origen)';

  @override
  String get assetPickerTitle => 'Elegir una imagen de mi biblioteca';

  @override
  String assetUploadType(Object type) {
    return 'Subir $type';
  }

  @override
  String get editorSeal => 'Sello';

  @override
  String get editorSealColor => 'Color del sello';

  @override
  String get editorSealRingColor => 'Color del anillo';

  @override
  String get editorSealStarColor => 'Color de la estrella';

  @override
  String get editorSealStarSize => 'Tamaño de la estrella';

  @override
  String get editorShape => 'Forma';

  @override
  String get editorFillColor => 'Color de relleno';

  @override
  String get editorBorderColor => 'Color del borde';

  @override
  String get editorBorderWidth => 'Grosor del borde';

  @override
  String get editorCornerRadius => 'Radio de esquina';

  @override
  String get editorQrVerify => 'Código de verificación';

  @override
  String get editorQrData => 'Datos del código';

  @override
  String get editorQrColor => 'Color del código';

  @override
  String get editorQrBackground => 'Fondo del código';

  @override
  String editorConvertDialogMessage(Object text) {
    return 'La conversión transforma el texto «$text» en un marcador dinámico que se puede vincular en la generación por lotes.';
  }

  @override
  String get editorFieldKeyHint =>
      'Clave del campo (p. ej. nombre, fecha, referencia)';

  @override
  String get editorCustomKeyHint =>
      'Introduce una clave personalizada (sin llaves: se añadirá automáticamente)';

  @override
  String get editorCancel => 'Cancelar';

  @override
  String get editorConvert => 'Convertir';

  @override
  String get editorPath => 'Ruta';

  @override
  String get editorTextContent => 'Contenido del texto';

  @override
  String editorInsertFieldToken(Object token) {
    return 'Insertar $token';
  }

  @override
  String editorAddLabel(Object label) {
    return 'Añadir $label';
  }

  @override
  String assetInsertedSnack(Object name) {
    return 'Se insertó «$name» en la plantilla.';
  }

  @override
  String get paletteHeading => 'Título';

  @override
  String get paletteFrame => 'Rectángulo / marco';

  @override
  String get paletteDivider => 'Separador';

  @override
  String get paletteLogo => 'Logotipo / firma';
}
