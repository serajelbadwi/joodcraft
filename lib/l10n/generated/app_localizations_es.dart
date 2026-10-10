// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get editorDone => 'Listo';

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
  String get actionOpenMenu => 'Menú';

  @override
  String get editorFitToScreen => 'Ajustar a pantalla';

  @override
  String get editorNewTemplate => 'Nueva plantilla';

  @override
  String get editorNewConfirm =>
      'Una nueva plantilla comenzará desde el diseño predeterminado; los cambios sin guardar permanecerán en el historial. ¿Continuar?';

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
  String get destBrand => 'Identidad y perfil';

  @override
  String get destBrandDesc => 'Tu logotipo, sellos, firmas y colores de marca.';

  @override
  String get brandTitle => 'Ajustes de identidad y perfil';

  @override
  String get brandTabVisuals => 'Identidad visual';

  @override
  String get brandTabText => 'Datos de texto';

  @override
  String get brandTabColors => 'Colores y fuentes';

  @override
  String get brandTabPreview => 'Vista de identidad';

  @override
  String get brandPrimaryLogo => 'Logotipo principal';

  @override
  String get brandWatermarkLogo => 'Logotipo de marca de agua';

  @override
  String get brandSeals => 'Sellos oficiales';

  @override
  String get brandAddSeal => 'Añadir sello';

  @override
  String get brandSealName => 'Nombre del sello';

  @override
  String get brandSignatures => 'Firmas autorizadas';

  @override
  String get brandAddSignature => 'Añadir firma';

  @override
  String get brandSignatureName => 'Nombre del firmante';

  @override
  String get brandSignatureTitle => 'Cargo';

  @override
  String get brandRemove => 'Eliminar';

  @override
  String get brandNoSeals => 'Aún no se han añadido sellos.';

  @override
  String get brandNoSignatures => 'Aún no se han añadido firmas.';

  @override
  String get brandOrgNameAr => 'Nombre de la organización (árabe)';

  @override
  String get brandOrgNameEn => 'Nombre de la organización (inglés)';

  @override
  String get brandHeaderText => 'Texto de encabezado';

  @override
  String get brandFooterText => 'Texto de pie de página';

  @override
  String get brandRegNumber => 'Número fiscal / de registro';

  @override
  String get brandPrimaryColor => 'Color principal';

  @override
  String get brandSecondaryColor => 'Color secundario';

  @override
  String get brandAccentColor => 'Color de acento';

  @override
  String get brandHeaderFont => 'Fuente de títulos';

  @override
  String get brandBodyFont => 'Fuente del cuerpo';

  @override
  String get brandClear => 'Borrar identidad';

  @override
  String get brandClearConfirm =>
      'Se eliminará todo el contenido guardado. ¿Continuar?';

  @override
  String get brandSaved => 'Identidad guardada.';

  @override
  String get brandPresets => 'Elementos de identidad';

  @override
  String get brandInsertHeader => 'Insertar encabezado estándar';

  @override
  String get brandInsertFooter => 'Insertar pie estándar';

  @override
  String get brandApplyColors => 'Aplicar colores';

  @override
  String get brandQuickSeals => 'Sellos';

  @override
  String get brandQuickSignatures => 'Firmas';

  @override
  String get brandNoBrand => 'Tu identidad aún no está configurada.';

  @override
  String get brandOpenSettings => 'Abrir ajustes de identidad';

  @override
  String get brandHeaderInserted => 'Encabezado insertado.';

  @override
  String get brandFooterInserted => 'Pie de página insertado.';

  @override
  String get brandColorsApplied => 'Colores aplicados.';

  @override
  String get brandSealInserted => 'Sello insertado.';

  @override
  String get brandSignatureInserted => 'Firma insertada.';

  @override
  String get brandFontDefault => 'Predeterminada';

  @override
  String get paletteShapes => 'Formas';

  @override
  String get paletteRoundedRect => 'Rectángulo redondeado';

  @override
  String get paletteEllipse => 'Círculo / elipse';

  @override
  String get editorFillOpacity => 'Opacidad de relleno';

  @override
  String get editorCollapsePanel => 'Contraer el panel lateral';

  @override
  String get editorExpandPanel => 'Mostrar el panel lateral';

  @override
  String get editorCustomSize => 'Tamaño personalizado';

  @override
  String get editorStandardSize => 'Tamaño estándar';

  @override
  String get editorBackgroundTitle => 'Fondo de la hoja';

  @override
  String get editorGradientFrom => 'Desde';

  @override
  String get editorGradientTo => 'Hasta';

  @override
  String get editorGradientDirection => 'Dirección';

  @override
  String get editorGradientNone => 'Sin degradado';

  @override
  String get editorGradientVertical => 'Vertical';

  @override
  String get editorGradientHorizontal => 'Horizontal';

  @override
  String get editorGradientDiagonal => 'Diagonal';

  @override
  String get editorLayersTitle => 'Capas';

  @override
  String get editorLayerShow => 'Mostrar elemento';

  @override
  String get editorLayerHide => 'Ocultar elemento';

  @override
  String get editorLayerLock => 'Bloquear elemento';

  @override
  String get editorLayerUnlock => 'Desbloquear elemento';

  @override
  String get editorLayersEmpty => 'Aún no hay elementos en esta página.';

  @override
  String get editorGroupSelected => 'Agrupar selección';

  @override
  String get editorUngroupSelected => 'Desagrupar';

  @override
  String get editorAlignLeft => 'Alinear a la izquierda';

  @override
  String get editorAlignCenterH => 'Centrar horizontalmente';

  @override
  String get editorAlignRight => 'Alinear a la derecha';

  @override
  String get editorAlignTop => 'Alinear arriba';

  @override
  String get editorAlignCenterV => 'Centrar verticalmente';

  @override
  String get editorAlignBottom => 'Alinear abajo';

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
  String get editorImageTint => 'Tinte de la imagen';

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

  @override
  String get evSignatureEmptyLabel => 'Firma vacía';

  @override
  String get evSignatureEmptyDetail =>
      'Añade un cargo, un nombre y una imagen de firma';

  @override
  String get evSignatureMissingLabel => 'Firma faltante';

  @override
  String get evUploadToLibraryDetail =>
      'Sube la imagen a la biblioteca de recursos';

  @override
  String get evImageNotFoundLabel => 'Imagen no encontrada';

  @override
  String get evNoFileLabel => 'Ningún archivo seleccionado';

  @override
  String get evChooseFromAssetsDetail =>
      'Elige una imagen de la biblioteca de recursos';

  @override
  String get evAssetMissingLabel => 'Recurso faltante';

  @override
  String get evReselectAssetDetail =>
      'Vuelve a elegir el marco/recurso de la biblioteca';

  @override
  String get evInvalidImageLabel => 'Imagen no válida';

  @override
  String get evRenderDataFailedDetail => 'No se pudieron mostrar los datos';

  @override
  String get evInvalidDataLabel => 'Datos no válidos';

  @override
  String get evDecodeFailedDetail => 'No se pudo decodificar la imagen';

  @override
  String get evEmptyQrLabel => 'Código vacío';

  @override
  String get evEmptyQrDetail =>
      'Introduce el valor del código en la barra de propiedades';

  @override
  String evUnknownElementLabel(Object type) {
    return 'Elemento no compatible: $type';
  }

  @override
  String get alpFilterAll => 'Todos';

  @override
  String get alpEmptyHint =>
      'No hay recursos subidos de los tipos solicitados. Sube un marco o un logotipo desde la sección «Recursos y firmas» y vuelve a intentarlo.';

  @override
  String alpNoFilteredAssets(Object type) {
    return 'No hay recursos del tipo «$type».';
  }

  @override
  String get authWelcomeBack => 'Bienvenido a JoodCraft.';

  @override
  String get authResetLinkSent =>
      'Se ha enviado el enlace de restablecimiento. Revisa tu correo.';

  @override
  String get authLogin => 'Iniciar sesión';

  @override
  String get authLoginSubtitle =>
      'Tu correo y contraseña para continuar al panel.';

  @override
  String get authNoAccount => '¿No tienes una cuenta?';

  @override
  String get authCreateAccountLink => 'Crear una cuenta nueva';

  @override
  String get authConfirmEmailThenLogin =>
      'Tu cuenta ha sido creada. Confirma tu correo primero y luego inicia sesión.';

  @override
  String get authEmail => 'Correo electrónico';

  @override
  String get authPassword => 'Contraseña';

  @override
  String get authForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get authEnterDashboard => 'Entrar al panel';

  @override
  String get authResetPassword => 'Restablecer contraseña';

  @override
  String get authResetPasswordHint =>
      'Introduce tu correo y te enviaremos un enlace para restablecer la contraseña.';

  @override
  String get authSendLink => 'Enviar enlace';

  @override
  String get authConfirmEmailMessage =>
      'Tu cuenta ha sido creada. Revisa tu correo para confirmarla y luego inicia sesión.';

  @override
  String get authAccountCreatedWelcome =>
      'Tu cuenta ha sido creada. Bienvenido a JoodCraft.';

  @override
  String get authCreateAccount => 'Crear cuenta';

  @override
  String get authRegisterSubtitle =>
      'Tu cuenta guarda tus plantillas y recursos (logotipo, firma, sello) para reutilizarlos en todos tus proyectos.';

  @override
  String get authHaveAccount => '¿Ya tienes una cuenta?';

  @override
  String get authFullName => 'Nombre completo';

  @override
  String get authFullNameHint => 'p. ej.: Abdullah Al-Ahmad';

  @override
  String get authName => 'Nombre';

  @override
  String get authOrgName => 'Nombre de la organización (opcional)';

  @override
  String get authOrgNameHint => 'p. ej.: Asociación benéfica Jood';

  @override
  String get authOrgHelper =>
      'Se imprime automáticamente en certificados y contratos.';

  @override
  String get authOrgNameShort => 'Nombre de la organización';

  @override
  String get authPasswordHint => 'Al menos 8 caracteres';

  @override
  String authPasswordRule(Object min) {
    return 'Usa $min caracteres o más con números y símbolos.';
  }

  @override
  String get authConfirmPassword => 'Confirmar contraseña';

  @override
  String get authCreateAccountButton => 'Crear la cuenta';

  @override
  String get authFeatureLocalExcel =>
      'Procesamiento totalmente local de archivos Excel: tus datos no salen de tu dispositivo';

  @override
  String get authFeaturePdf =>
      'Generación de PDF con fuentes árabes de alta calidad y soporte RTL completo';

  @override
  String get authFeatureTemplates =>
      'Tus plantillas se guardan en tu cuenta y están listas para reutilizar';

  @override
  String get authTagline =>
      'Tus certificados y contratos oficiales… impresos con confianza.';

  @override
  String authVersion(Object name, Object version) {
    return '$name • Versión $version';
  }

  @override
  String get dashModules => 'Módulos de la plataforma';

  @override
  String dashWelcome(Object name) {
    return 'Bienvenido, $name';
  }

  @override
  String dashSubscription(Object tier) {
    return 'Suscripción: $tier';
  }

  @override
  String dashOrg(Object name) {
    return 'Organización: $name';
  }

  @override
  String get dashOrgMissing =>
      'Aún no has definido el nombre de tu organización; se imprimirá automáticamente en certificados y contratos.';

  @override
  String get dashOpenModule => 'Abrir el módulo';

  @override
  String get destDashboard => 'Panel';

  @override
  String get destDashboardDesc =>
      'Una visión general de tus proyectos y plantillas.';

  @override
  String get destCertificates => 'Motor de certificados';

  @override
  String get destCertificatesDesc =>
      'Diseña certificados horizontales desde una plantilla editable.';

  @override
  String get destContracts => 'Motor de contratos';

  @override
  String get destContractsDesc =>
      'Redacta contratos verticales con campos dinámicos.';

  @override
  String get destBatch => 'Generación por lotes';

  @override
  String get destBatchDesc =>
      'Lee un archivo Excel localmente y genera cientos de certificados de una vez.';

  @override
  String get destTemplates => 'Biblioteca de plantillas';

  @override
  String get destTemplatesDesc =>
      'Gestiona, clasifica y reutiliza tus plantillas guardadas.';

  @override
  String get destAssets => 'Recursos y firmas';

  @override
  String get destAssetsDesc => 'Tu logotipo, sello, firma y marcos.';

  @override
  String get dashUser => 'Usuario';

  @override
  String get dashLogoutSuccess => 'Has cerrado sesión correctamente.';

  @override
  String get dashLogoutError => 'No se pudo cerrar sesión. Inténtalo de nuevo.';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonPreview => 'Vista previa';

  @override
  String get commonOptions => 'Opciones';

  @override
  String get tplDelete => 'Eliminar';

  @override
  String get tplSortRecentlyUpdated => 'Modificados recientemente';

  @override
  String get tplSortTitleAsc => 'Nombre (A–Z)';

  @override
  String get tplSortLabel => 'Ordenar';

  @override
  String get tplSubtitle =>
      'Plantillas profesionales listas + las tuyas guardadas: buscar, filtrar, abrir e importar, totalmente sin conexión.';

  @override
  String get tplRefreshTooltip => 'Actualizar la lista';

  @override
  String get tplSearchHint => 'Buscar plantillas…';

  @override
  String get tplNoResultsTitle => 'Sin resultados coincidentes';

  @override
  String get tplNoResultsMessage =>
      'Prueba otro término de búsqueda o restablece el filtro.';

  @override
  String tplAddedToLocal(Object title) {
    return 'Se añadió «$title» a tus plantillas locales.';
  }

  @override
  String get tplCloudRequiresConnection =>
      'Guardar plantillas en la nube requiere conexión a un proyecto Supabase. Guárdala localmente.';

  @override
  String tplSavedToCloud(Object title) {
    return 'Se guardó «$title» en la nube.';
  }

  @override
  String get tplRenamed => 'Se renombró la plantilla.';

  @override
  String tplCopySuffix(Object title) {
    return '$title (copia)';
  }

  @override
  String tplCopyCreated(Object title) {
    return 'Se creó una copia de «$title».';
  }

  @override
  String get tplNowPrivate => 'La plantilla ahora es privada.';

  @override
  String get tplNowPublic =>
      'La plantilla ahora es pública (solo lectura para otros).';

  @override
  String tplConfirmCloudDelete(Object title) {
    return '«$title» se eliminará permanentemente de la nube. No se puede deshacer.';
  }

  @override
  String tplCloudDeleted(Object title) {
    return 'Se eliminó la plantilla «$title».';
  }

  @override
  String tplConfirmLocalDelete(Object title) {
    return '«$title» se eliminará de este dispositivo. La plantilla original lista sigue disponible en la biblioteca.';
  }

  @override
  String tplLocalDeleted(Object title) {
    return 'Se eliminó la plantilla local «$title».';
  }

  @override
  String get tplDeleteTitle => 'Eliminar plantilla';

  @override
  String get tplRenameTitle => 'Título de la plantilla';

  @override
  String get tplFieldTitle => 'Título';

  @override
  String tplPreviewLabel(Object title) {
    return 'Vista previa: $title';
  }

  @override
  String tplCount(Object count) {
    return '$count plantilla(s)';
  }

  @override
  String tplCloudLoadError(Object message) {
    return 'No se pudieron cargar las plantillas en la nube: $message';
  }

  @override
  String get tplPublicBadge => 'Plantilla pública';

  @override
  String get tplOrientationLandscape => 'Horizontal';

  @override
  String get tplOrientationPortrait => 'Vertical';

  @override
  String get tplPresetOffline => 'Plantilla lista • disponible sin conexión';

  @override
  String tplSchemaVersion(Object version) {
    return 'Esquema v$version';
  }

  @override
  String get tplOpenAsTemplate => 'Abrir como plantilla';

  @override
  String get tplOpen => 'Abrir';

  @override
  String get tplUseInBatch => 'Usar en generación por lotes';

  @override
  String get tplImportLocal => 'Importar localmente';

  @override
  String get tplSaveToCloud => 'Guardar en la nube';

  @override
  String get tplDeleteLocal => 'Eliminar localmente';

  @override
  String get tplRename => 'Renombrar';

  @override
  String get tplMakePrivate => 'Hacerlo privado';

  @override
  String get tplMakePublic => 'Hacerlo público';

  @override
  String get tplNoDate => 'Sin fecha';

  @override
  String get amSubtitle =>
      'Sube tu logotipo, sello y firma una vez, e insértalos en cualquier plantilla: se guardan en tu dispositivo y se reutilizan sin conexión.';

  @override
  String get amSearchHint => 'Buscar recursos…';

  @override
  String get amTypeLabel => 'Tipo';

  @override
  String get amUploadTooltip => 'Subir un recurso nuevo';

  @override
  String get amUpload => 'Subir recurso';

  @override
  String get amEmptyTitle => 'Aún no hay recursos';

  @override
  String get amEmptyMessage =>
      'Sube el logotipo, la firma o el sello de tu organización, e insértalos en cualquier plantilla desde la barra de propiedades de la imagen.';

  @override
  String get amNoResultsMessage => 'Prueba otro nombre o restablece el filtro.';

  @override
  String get amRenamed => 'Se renombró el recurso.';

  @override
  String amMovedToType(Object type) {
    return 'El recurso se movió a «$type».';
  }

  @override
  String get amDeleteTitle => 'Eliminar recurso';

  @override
  String amConfirmDelete(Object name) {
    return '«$name» se eliminará de este dispositivo. Las plantillas que lo usan perderán la imagen (sin fallo de impresión).';
  }

  @override
  String amDeleted(Object name) {
    return 'Se eliminó el recurso «$name».';
  }

  @override
  String get amRenameTitle => 'Renombrar recurso';

  @override
  String amCount(Object count) {
    return '$count recurso(s)';
  }

  @override
  String amMakeType(Object type) {
    return 'Definir tipo: $type';
  }

  @override
  String get amCacheLabel => 'Caché de imágenes en disco';

  @override
  String amCacheUsage(Object count, Object size) {
    return '$count archivo(s) · $size';
  }

  @override
  String amCacheUsageOf(Object count, Object used, Object limit) {
    return '$count archivo(s) · $used de $limit';
  }

  @override
  String get amCacheEmpty => 'Aún no hay caché en disco';

  @override
  String get amCacheClear => 'Vaciar caché';

  @override
  String get amCacheCleared => 'Se vació el caché de imágenes en disco.';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonPrint => 'Imprimir';

  @override
  String get commonExportPdf => 'Exportar PDF';

  @override
  String get commonExportFailed => 'No se pudo exportar el archivo PDF.';

  @override
  String get commonPrintFailed =>
      'No se pudo enviar el archivo a la impresora.';

  @override
  String commonExportReady(Object name) {
    return 'El archivo está listo para guardar como $name.';
  }

  @override
  String get commonGenerating => 'Generando…';

  @override
  String get commonDataPanelTitle => 'Datos de ejemplo';

  @override
  String evElementCount(Object count) {
    return '$count elemento(s)';
  }

  @override
  String get evStatusDynamicFields => ' • campos dinámicos';

  @override
  String get evStatusUnsaved => ' • cambios sin guardar';

  @override
  String get tevNewTemplateTitle => 'Nueva plantilla';

  @override
  String get tevUnsavedTitle => 'Cambios sin guardar';

  @override
  String tevUnsavedMessage(Object title) {
    return 'Tienes cambios sin guardar en «$title». ¿Quieres guardarlos antes de salir?';
  }

  @override
  String get tevLeaveWithoutSaving => 'Salir sin guardar';

  @override
  String get tevSaveAndLeave => 'Guardar y salir';

  @override
  String get tevViewMode => 'Modo de vista';

  @override
  String get tevModeEditor => 'Editor';

  @override
  String get tevModePreview => 'Vista previa PDF';

  @override
  String get tevPaperDirection => 'Orientación del papel';

  @override
  String get tevWidthCm => 'Ancho (cm)';

  @override
  String get tevHeightCm => 'Alto (cm)';

  @override
  String get tevUndo => 'Deshacer (Ctrl+Z)';

  @override
  String get tevRedo => 'Rehacer (Ctrl+Y)';

  @override
  String get tevSnapGrid => 'Cuadrícula imantada';

  @override
  String get tevGuidesOn => 'Guías inteligentes: activadas (desactivar)';

  @override
  String get tevGuidesOff => 'Guías inteligentes: desactivadas (activar)';

  @override
  String get tevZoom => 'Zoom';

  @override
  String get tevDocumentBackground => 'Fondo del documento';

  @override
  String get tevFrameFromLibrary => 'Marco desde mi biblioteca';

  @override
  String get tevChangeTitle => 'Cambiar el título de la plantilla';

  @override
  String get tevMyTemplates => 'Mis plantillas';

  @override
  String get tevSaveAs => 'Guardar como';

  @override
  String get tevSaveTemplate => 'Guardar plantilla';

  @override
  String get tevSaveUnavailable => 'Guardado no disponible';

  @override
  String get tevSaveNeedsSupabase =>
      'Guardar requiere conexión a un proyecto Supabase. Ejecuta la app con tus claves (env.json) para guardar plantillas.';

  @override
  String tevMissingAssets(Object list) {
    return 'Recursos faltantes: $list: vuelve a elegir el marco/recurso en «Mi biblioteca» para evitar vacíos.';
  }

  @override
  String get tevTemplateLibraryNeedsSupabase =>
      'La biblioteca de plantillas requiere conexión a un proyecto Supabase.';

  @override
  String tevOpenedTemplate(Object title) {
    return 'Se abrió «$title».';
  }

  @override
  String get tevTitleHint =>
      'p. ej.: certificado de finalización del curso de gestión de proyectos';

  @override
  String get tevContinue => 'Continuar';

  @override
  String get tevSavedTemplates => 'Mis plantillas guardadas';

  @override
  String get tevNoSavedTemplates =>
      'Aún no hay plantillas guardadas. Guarda una con el botón «Guardar plantilla».';

  @override
  String get ecIncrease => 'Aumentar';

  @override
  String get ecDecrease => 'Disminuir';

  @override
  String get ecQuickPalette => 'Paleta rápida';

  @override
  String get ecFullPicker => 'Selector de color completo';

  @override
  String get ecRemoveColor => 'Quitar color';

  @override
  String get ecNone => 'Ninguno';

  @override
  String get ecPickColorTitle => 'Elegir un color';

  @override
  String get ecApply => 'Aplicar';

  @override
  String tevBackgroundAdded(Object name) {
    return 'Se añadió «$name» como fondo del documento.';
  }

  @override
  String get cfpUploadTooltip => 'Subir una fuente personalizada (.ttf / .otf)';

  @override
  String get cfpManageTooltip => 'Gestionar las fuentes subidas';

  @override
  String get cfpNotice =>
      'Las fuentes subidas se guardan solo en tu dispositivo y se usan de inmediato aquí y al imprimir, sin internet.';

  @override
  String get cfpMyFonts => 'Mis fuentes personalizadas';

  @override
  String get cfpNoFonts => 'Aún no has subido fuentes';

  @override
  String get cfpBuiltinOption => 'Ninguna (fuente integrada)';

  @override
  String get cfpGroupBuiltin => 'Fuentes integradas';

  @override
  String get cfpGroupUploaded => 'Mis fuentes subidas';

  @override
  String get cfpGroupSystem => 'Fuentes del sistema';

  @override
  String get cfpSearchHint => 'Buscar fuentes…';

  @override
  String get cfpNoMatch => 'No hay fuentes coincidentes.';

  @override
  String get cfpPickTitle => 'Elige un archivo de fuente (TTF u OTF)';

  @override
  String cfpPickerError(Object error) {
    return 'No se pudo abrir el selector de archivos: $error';
  }

  @override
  String cfpReadError(Object name, Object error) {
    return 'No se pudo leer \"$name\": $error';
  }

  @override
  String get cfpFontAdded => 'La fuente se añadió y se aplicó de inmediato.';

  @override
  String cfpFontsAdded(Object count) {
    return 'Se añadieron $count fuentes.';
  }

  @override
  String get cfpLibraryTitle => 'Mi biblioteca de fuentes';

  @override
  String get cfpLibraryNotice =>
      'Todas las fuentes se guardan solo en tu dispositivo. Aviso: eliminar una fuente usada por una plantilla la revierte a la fuente integrada en lugar de fallar.';

  @override
  String get cfpEmpty => 'Aún no hay fuentes subidas.';

  @override
  String get cfpCoverageFull => 'Cobertura árabe completa';

  @override
  String get cfpCoveragePartial => 'Cobertura árabe parcial';

  @override
  String get cfpUploadNew => 'Subir una fuente nueva';

  @override
  String get ptpPrepError =>
      'No se pudo preparar la vista previa. Comprueba el archivo de la plantilla.';

  @override
  String ptpElapsedSize(Object ms, Object kb) {
    return '$ms ms — $kb KB';
  }

  @override
  String get ptpGeneratingNote =>
      '— la vista previa se actualiza automáticamente';

  @override
  String get ptpGenerateFailedTitle => 'No se pudo generar la vista previa';

  @override
  String get ptpPreparingTitle => 'Preparando el motor…';

  @override
  String get ptpPreparingMessage =>
      'Se están cargando las fuentes incluidas y generando la primera versión del archivo.';

  @override
  String get ptpShowFailedTitle => 'No se pudo mostrar la vista previa';

  @override
  String cfgOverride(Object override) {
    return 'Una compilación alternativa con valores explícitos reemplaza al archivo: $override';
  }

  @override
  String get tevBackgroundTitle => 'Fondo del documento desde mi biblioteca';

  @override
  String get tevAddElement => 'Añadir elemento';

  @override
  String get commonUndo => 'Deshacer';

  @override
  String get bpTitle => 'Generación por lotes desde Excel';

  @override
  String get bpSubtitle =>
      'Importa un archivo .xlsx o .csv, asocia sus columnas a los campos de la plantilla y genera un PDF con una página por registro, todo en tu dispositivo y sin conexión.';

  @override
  String get bpStepTemplate => '1) Plantilla';

  @override
  String get bpLoadingSampleTemplate => 'Cargando la plantilla de ejemplo…';

  @override
  String bpTemplateInfo(Object name) {
    return 'Plantilla: $name • campos requeridos:';
  }

  @override
  String get bpLoadingTemplates => 'Cargando tus plantillas…';

  @override
  String get bpNoTemplates =>
      'Aún no hay plantillas guardadas: crea una en el editor o impórtala desde la biblioteca de plantillas.';

  @override
  String get bpTemplateFromMine => 'Plantilla de mis plantillas';

  @override
  String get bpSampleTemplatesHeader => '— plantillas de ejemplo —';

  @override
  String bpTemplateEntry(Object title, Object source) {
    return '$title  •  $source';
  }

  @override
  String get bpSourceCloud => 'Nube';

  @override
  String get bpSourceLocal => 'Local';

  @override
  String get bpStepDataFile => '2) Archivo de datos';

  @override
  String get bpReadingFile => 'Leyendo el archivo…';

  @override
  String get bpNoFileChosen =>
      'Aún no se ha elegido archivo: formatos compatibles:';

  @override
  String bpFileSummary(Object name, Object rows, Object cols) {
    return '$name — $rows filas, $cols columnas';
  }

  @override
  String bpSheetSuffix(Object name) {
    return ' (hoja: $name)';
  }

  @override
  String get bpChooseFile => 'Elegir archivo';

  @override
  String get bpRemove => 'Quitar';

  @override
  String get bpHeaderRow => 'Fila de encabezados';

  @override
  String bpAutoRow(Object n) {
    return 'Automática (fila $n)';
  }

  @override
  String bpRow(Object n) {
    return 'Fila $n';
  }

  @override
  String bpAutoRowLong(Object n) {
    return 'Automática — fila $n';
  }

  @override
  String bpRowPreview(Object n, Object preview) {
    return 'Fila $n: $preview';
  }

  @override
  String get bpEmptyRow => '(fila vacía)';

  @override
  String get bpWorksheet => 'Hoja de cálculo';

  @override
  String get bpPickDataFile => 'Elegir el archivo de datos (Excel o CSV)';

  @override
  String bpReadFileError(Object error) {
    return 'No se pudo leer el archivo: $error';
  }

  @override
  String bpFileReadRows(Object rows, Object cols) {
    return 'El archivo se leyó localmente: $rows filas y $cols columnas.';
  }

  @override
  String bpSaveError(Object error) {
    return 'No se pudo guardar el cambio en la plantilla: $error';
  }

  @override
  String get bpMapFieldTitle => 'Asignar un campo dinámico a este elemento';

  @override
  String get bpMapFieldBody =>
      'Solo se reemplazará el texto de este elemento por un campo; ningún otro elemento se verá afectado.';

  @override
  String get bpUndoConvert => 'Se deshizo la conversión.';

  @override
  String get bpUndoConvertSaved =>
      'Se deshizo la conversión y se restauró el texto en la plantilla.';

  @override
  String bpRestoreError(Object error) {
    return 'No se pudo restaurar el texto en la plantilla: $error';
  }

  @override
  String bpGeneratedReport(Object count) {
    return 'Se generaron $count registro(s)';
  }

  @override
  String bpSkippedSuffix(Object count) {
    return ' y se omitieron $count';
  }

  @override
  String get bpReadyToSave => 'El archivo está listo para guardar.';

  @override
  String get bpStepMapping => '3) Asignar columnas a campos';

  @override
  String get bpChooseFileFirst =>
      'Elige primero un archivo para mostrar la tabla de asignación.';

  @override
  String get bpNoDynamicFields =>
      'No hay campos dinámicos en la plantilla actual.';

  @override
  String bpMappedCount(Object mapped, Object total) {
    return '$mapped de $total columnas asignadas';
  }

  @override
  String get bpAutoMapHint =>
      'Tras elegir el archivo se propone una asignación automática inteligente; puedes editar cada columna.';

  @override
  String get bpNoFieldsHelp =>
      'La plantilla elegida no tiene campos dinámicos, así que no hay nada que asignar a las columnas del archivo. Abre la plantilla en el editor, inserta un «campo dinámico» en el espacio del nombre, guarda y vuelve a intentarlo.';

  @override
  String get bpAutoMap => 'Asignar automáticamente';

  @override
  String get bpClearMapping => 'Borrar asignación';

  @override
  String get bpNameFieldWarning =>
      'Esta plantilla no tiene un campo de nombre dinámico: no asignes la columna del nombre a un campo de fecha o referencia, o el nombre podría imprimirse en el lugar equivocado. Elige la clave del nombre en la lista de la columna, o convierte el texto fijo del nombre en el editor en un campo dinámico.';

  @override
  String bpStaticNameHints(Object preview) {
    return 'Texto fijo que parece un nombre: «$preview»: ningún campo dinámico lo reemplaza.';
  }

  @override
  String get bpConvertToNameField =>
      'Convertirlo en campo de nombre del aprendiz';

  @override
  String bpDuplicateField(Object field) {
    return 'El campo «$field» está asignado a más de una columna. Asigna cada campo a una sola columna.';
  }

  @override
  String bpUnmappedColumns(Object count) {
    return '$count columna(s) sin asignar: sus datos no se usarán en los certificados.';
  }

  @override
  String bpColumn(Object n) {
    return 'Columna $n';
  }

  @override
  String get bpEmptyCell => '(vacío)';

  @override
  String get bpUnmapped => '— sin asignar —';

  @override
  String get bpStepMissing => '4) Celdas vacías y datos faltantes';

  @override
  String get bpNoNotes => 'Sin notas antes de elegir el archivo.';

  @override
  String get bpStepGenerate => '5) Generar';

  @override
  String bpGenerating(Object progress) {
    return 'Generando… $progress';
  }

  @override
  String get bpGenerateHint =>
      'Un solo archivo PDF, una página por registro generado.';

  @override
  String get bpGeneratePickFile =>
      'Elige primero un archivo de datos para habilitar la generación.';

  @override
  String get bpMappingInvalid =>
      'La asignación no es válida: el mismo campo está asignado a dos columnas.';

  @override
  String get bpMapAtLeastOne =>
      'Asigna al menos una columna a un campo de la plantilla para habilitar la generación.';

  @override
  String get bpGenerateCertificates => 'Generar certificados';

  @override
  String get bpRegenerate => 'Regenerar';

  @override
  String get bpStatGenerated => 'Generados';

  @override
  String get bpStatSkipped => 'Omitidos';

  @override
  String get bpStatPages => 'Páginas';

  @override
  String get bpStatSize => 'Tamaño';

  @override
  String bpKilobytes(Object value) {
    return '$value KB';
  }

  @override
  String get bpStatTime => 'Tiempo';

  @override
  String bpMilliseconds(Object value) {
    return '$value ms';
  }

  @override
  String bpCompletion(Object pct, Object total) {
    return '$pct% completado de $total filas.';
  }

  @override
  String get bpSkippedRows => 'Filas no generadas:';

  @override
  String bpRowSkipReason(Object n, Object reason) {
    return 'Fila $n: $reason';
  }

  @override
  String get bpPreviewHere => 'La vista previa aparece aquí';

  @override
  String get bpPreviewHint =>
      'Elige el archivo de datos, ajusta la asignación y pulsa «Generar certificados»: verás la primera página del archivo generado aquí.';

  @override
  String get bpAssignByTapTitle => 'Asignar campos tocando';

  @override
  String get bpAssignByTapBody =>
      'Toca cualquier texto de la plantilla para asignarlo tú mismo a un campo dinámico. Ningún otro elemento se ve afectado: ni la fecha, ni el nombre del director, ni ningún texto fijo.';

  @override
  String get bpNoTexts => 'No hay textos en esta plantilla.';

  @override
  String get bpEmptyText => '(texto vacío)';

  @override
  String get bpDynamicFieldTap => 'Campo dinámico: toca para cambiar';

  @override
  String get bpStaticTextTap => 'Texto fijo: toca para asignar';

  @override
  String get bpAssignField => 'Asignar campo';

  @override
  String get bpKindCertificate => 'Certificado';

  @override
  String get bpKindContract => 'Contrato';

  @override
  String bpLoadSampleError(Object error) {
    return 'No se pudo cargar la plantilla de ejemplo: $error';
  }

  @override
  String bpReadSheetError(Object error) {
    return 'No se pudo leer la hoja: $error';
  }

  @override
  String bpUpdateHeaderRowError(Object error) {
    return 'No se pudo actualizar la fila de encabezados: $error';
  }

  @override
  String get bpChooseTemplateFirst =>
      'Elige una plantilla (certificado o contrato) antes de generar.';

  @override
  String bpBatchTitle(Object kind) {
    return '$kind por lotes — JoodCraft';
  }

  @override
  String bpGenerateError(Object error) {
    return 'No se pudo ejecutar la generación por lotes: $error';
  }

  @override
  String get bpWarnNoDynamicFields =>
      'Esta plantilla no tiene campos dinámicos: los datos no cambiarán entre registros. Añade un campo «nombre del aprendiz» desde la barra del editor y guarda la plantilla.';

  @override
  String get bpWarnNoNameField =>
      'Esta plantilla no tiene un campo de nombre dinámico: la columna del nombre podría asignarse a un campo de fecha o referencia y el nombre imprimirse en el lugar equivocado. Convierte el texto fijo del nombre en un campo o rediseña la plantilla.';

  @override
  String bpAssignedTemp(Object token) {
    return 'Este elemento se asignó a $token para la generación actual; los demás elementos no se ven afectados. Guarda la plantilla para conservar el cambio.';
  }

  @override
  String bpAssignedSaved(Object token) {
    return 'Este elemento se asignó a $token y el cambio se guardó en la plantilla. Los demás elementos no se ven afectados.';
  }

  @override
  String get commonShow => 'Mostrar';

  @override
  String get commonHide => 'Ocultar';

  @override
  String get themeSwitchToLight => 'Cambiar al tema claro';

  @override
  String get themeSwitchToDark => 'Cambiar al tema oscuro';

  @override
  String commonComingSoonPhase(Object phase) {
    return 'En curso — fase $phase';
  }

  @override
  String get cbNewCertificateTitle => 'Nuevo certificado';

  @override
  String get cbNewContractTitle => 'Nuevo contrato';

  @override
  String get cbBeneficiaryDataTitle => 'Datos del beneficiario (muestra)';

  @override
  String get cbContractDataTitle => 'Datos del contrato (muestra)';

  @override
  String get editorSendBackward => 'Enviar atrás';

  @override
  String get editorRotateLeft => 'Girar 90° a la izquierda';

  @override
  String get editorRotateRight => 'Girar 90° a la derecha';

  @override
  String get editorFlipH => 'Voltear horizontal';

  @override
  String get editorFlipV => 'Voltear vertical';

  @override
  String get editorTransform => 'Transformaciones';

  @override
  String get editorToolSelect => 'Selección';

  @override
  String get editorToolShapes => 'Formas';

  @override
  String get editorFillType => 'Tipo de relleno';

  @override
  String get editorFillSolid => 'Sólido';

  @override
  String get editorGradientLinear => 'Degradado lineal';

  @override
  String get editorGradientRadial => 'Degradado radial';

  @override
  String get editorGradientAngle => 'Ángulo del degradado';

  @override
  String get editorShadowEnable => 'Añadir sombra';

  @override
  String get editorShadowColor => 'Color de sombra';

  @override
  String get editorShadowBlur => 'Desenfoque';

  @override
  String get editorShadowOffsetX => 'Desplazamiento X';

  @override
  String get editorShadowOffsetY => 'Desplazamiento Y';

  @override
  String get editorShadowSpread => 'Propagación';

  @override
  String get editorShadowRemove => 'Quitar sombra';

  @override
  String get editorPoints => 'Puntos';

  @override
  String get editorInnerRadius => 'Radio interior';

  @override
  String get editorCornerTopLeft => 'Arriba izquierda';

  @override
  String get editorCornerTopRight => 'Arriba derecha';

  @override
  String get editorCornerBottomRight => 'Abajo derecha';

  @override
  String get editorCornerBottomLeft => 'Abajo izquierda';

  @override
  String get editorDashPattern => 'Patrón de guiones';

  @override
  String get editorBooleanOps => 'Operaciones booleanas';

  @override
  String get editorBooleanUnion => 'Unir';

  @override
  String get editorBooleanSubtract => 'Restar';

  @override
  String get editorBooleanIntersect => 'Intersección';

  @override
  String get editorBooleanUngroup => 'Separar';

  @override
  String get paletteStar => 'Estrella';

  @override
  String get palettePolygon => 'Polígono';

  @override
  String get editorBooleanExclude => 'Exclusión';

  @override
  String get editorBooleanHint =>
      'La ruta fusionada es un único resultado booleano (sin bordes interiores) y se puede separar en cualquier momento.';

  @override
  String get editorDockTools => 'Panel de herramientas';

  @override
  String get editorDockAnchor => 'Posición de acoplamiento';

  @override
  String get editorDockTopBar => 'Barra superior';

  @override
  String get editorDockInspector => 'Panel lateral';

  @override
  String get editorDockLeftRail => 'Barra lateral';

  @override
  String get editorDockFloating => 'Flotante';

  @override
  String get editorDockCollapse => 'Contraer herramientas';

  @override
  String get editorDockExpand => 'Expandir herramientas';

  @override
  String get editorDockResize => 'Arrastra para redimensionar';

  @override
  String get editorDockDropHint => 'Suelta para acoplar en';

  @override
  String get editorMoreTools => 'Más herramientas';

  @override
  String get editorDocumentProperties => 'Propiedades del documento';

  @override
  String get editorDockReset => 'Restaurar el acoplamiento predeterminado';

  @override
  String get editorTextShadow => 'Sombra del texto';

  @override
  String get editorTextShadowAdd => 'Añadir sombra al texto';

  @override
  String get editorShadowOpacity => 'Opacidad de la sombra';

  @override
  String get genderMale => 'Masculino';

  @override
  String get genderFemale => 'Femenino';

  @override
  String get genderPreviewAutoHint =>
      'Clic para anular la forzada (automático)';

  @override
  String get genderPresetCompleted => '«completed» (m./f.)';

  @override
  String get genderPresetPassed => '«passed» (m./f.)';

  @override
  String get genderPresetForStudent => '«para el estudiante» (m./f.)';

  @override
  String get genderPresetStudent => '«el estudiante» (m./f.)';

  @override
  String get genderPresetToHim => '«para él / para ella»';

  @override
  String get genderPresetHonoring => '«el alumno destacado» (m./f.)';

  @override
  String get editorGenderSnippet => 'Insertar fragmento condicional';

  @override
  String get editorGenderSnippetHint =>
      'Inserta una frase que cambia automáticamente según el género del beneficiario.';

  @override
  String get bpGenderReviewTitle => 'Revisión de género (masculino/femenino)';

  @override
  String get bpGenderReviewSubtitle =>
      'El género se detecta por el nombre o una columna «Género» — corrige los casos límite antes de imprimir.';

  @override
  String get bpGenderRow => 'Fila';

  @override
  String get bpGenderDetected => 'Detectado';

  @override
  String get bpGenderEffective => 'Aplicado';

  @override
  String get bpGenderNameColumn => 'Nombre';

  @override
  String get bpGenderEditName => 'Editar nombre';

  @override
  String get bpGenderNameHint => 'Escriba el nombre correcto';

  @override
  String get bpGenderClearOverrides => 'Borrar correcciones';

  @override
  String get bpGenderOverridden => 'Corregido manualmente';

  @override
  String get bpGenderUnknownName => '—';

  @override
  String get bpOutputTitle => 'Destino de guardado de certificados';

  @override
  String get bpOutputHint =>
      'Elige la carpeta donde guardar el PDF generado, o empieza con la ubicación predeterminada.';

  @override
  String get bpOutputPickFolder => 'Elegir carpeta…';

  @override
  String get bpOutputStart => 'Iniciar generación';

  @override
  String get bpOutputPathLabel => 'Carpeta seleccionada';

  @override
  String get bpOutputNoFolder =>
      'Ninguna carpeta seleccionada — solo impresión y exportación.';

  @override
  String get bpOpenFolder => 'Abrir carpeta';

  @override
  String get bpOutputSavedTitle => 'Archivo PDF guardado';

  @override
  String get bpOpenFolderFailed => 'No se pudo abrir la carpeta.';

  @override
  String get bpOutputNameLabel => 'Nombre del archivo de exportación';

  @override
  String get bpOutputNameHint => 'Escriba un nombre sin extensión';

  @override
  String get bpOutputNamePreviewLabel => 'Se guardará como';

  @override
  String get bpOutputModeLabel => 'Modo de guardado';

  @override
  String get bpOutputModeCombined => 'Un único archivo combinado';

  @override
  String get bpOutputModeIndividual => 'Un archivo por persona';

  @override
  String get hubTitle => 'Nuevo proyecto';

  @override
  String get hubSubtitle =>
      'Elige un tamaño listo o define el tuyo: el lienzo se abre con el tamaño y la proporción exactos.';

  @override
  String get hubKindSingle => 'Impresos y documentos de una hoja';

  @override
  String get hubKindMulti => 'Libros y publicaciones de varias páginas';

  @override
  String get hubKindSingleHint =>
      'Una hoja: certificados, contratos, tarjetas, números de asiento, felicitaciones.';

  @override
  String get hubKindMultiHint =>
      'Varias páginas: libro, revista, folleto, informe, catálogo.';

  @override
  String get hubGroupCertificates => 'Certificados y contratos';

  @override
  String get hubGroupCards => 'Tarjetas y credenciales';

  @override
  String get hubGroupSeat => 'Números de asiento y etiquetas';

  @override
  String get hubGroupGreeting => 'Tarjetas de felicitación';

  @override
  String get hubGroupPublications => 'Libros y publicaciones';

  @override
  String get hubGroupCustom => 'Tamaño personalizado';

  @override
  String get hubDigitalBadge => 'Digital';

  @override
  String get hubCreate => 'Crear';

  @override
  String get hubCustomCardBody =>
      'Introduce tus medidas en la unidad que quieras y empieza con un lienzo a tu tamaño.';

  @override
  String get hubCustomName => 'Nombre del proyecto';

  @override
  String get hubCustomNameHint => 'p. ej. Tarjeta de invitación';

  @override
  String get hubCustomPreview => 'Tamaño final';

  @override
  String get hubCustomCreate => 'Crear lienzo';

  @override
  String get hubCustomType => 'Tipo de proyecto';

  @override
  String get hubSearchHint => 'Buscar tamaños…';

  @override
  String get hubNoResults => 'Ningún tamaño coincide: prueba otra palabra.';

  @override
  String get hubAspectRatio => 'Proporción';

  @override
  String get destNewProject => 'Nuevo proyecto';

  @override
  String get destNewProjectDesc =>
      'Elige un tamaño listo o personalizado y empieza a diseñar.';

  @override
  String get ptpImpositionToggle => 'Imposición de impresión';

  @override
  String get ptpImpositionNoFit =>
      'La hoja es demasiado pequeña para este elemento: reduce los márgenes o elige una hoja mayor.';

  @override
  String get editorEffectsTitle => 'Efectos y ajustes de color';

  @override
  String get editorShadowGroup => 'Sombra';

  @override
  String get editorOuterGlow => 'Brillo exterior';

  @override
  String get editorInnerGlow => 'Brillo interior';

  @override
  String get editorGlowAdd => 'Añadir brillo';

  @override
  String get editorGlowRemove => 'Quitar brillo';

  @override
  String get editorGlowColor => 'Color del brillo';

  @override
  String get editorGlowRadius => 'Radio del brillo';

  @override
  String get editorGlowSpread => 'Propagación del brillo';

  @override
  String get editorGlowOpacity => 'Opacidad del brillo';

  @override
  String get editorAdjustGroup => 'Ajustes de color';

  @override
  String get editorAdjustBrightness => 'Brillo';

  @override
  String get editorAdjustContrast => 'Contraste';

  @override
  String get editorAdjustSaturation => 'Saturación';

  @override
  String get editorAdjustHue => 'Tono';

  @override
  String get editorAdjustReset => 'Restablecer';

  @override
  String get bpOutputSavedFolderTitle =>
      'Archivos guardados en una carpeta dedicada';

  @override
  String get hubDetailsTitle => 'Detalles del tamaño';

  @override
  String get hubDetailsHint =>
      'Especificación por defecto rellenada — elige un tamaño de la cuadrícula o edita las dimensiones.';

  @override
  String get hubFilterAll => 'Todo';

  @override
  String get hubFilterRecent => 'Tamaños recientes';

  @override
  String get hubFilterSeat => 'Números de asiento';

  @override
  String get hubFilterGreeting => 'Felicitaciones y pantallas';

  @override
  String get hubRecentEmpty =>
      'Aún no hay tamaños recientes — cualquier proyecto que crees aparecerá aquí.';

  @override
  String get hubDocTitle => 'Nombre del proyecto';

  @override
  String get hubDocTitleHint => 'Proyecto nuevo - 1';

  @override
  String get hubWidth => 'Ancho';

  @override
  String get hubHeight => 'Alto';

  @override
  String get hubUnitLabel => 'Unidad';

  @override
  String get hubOrientationLabel => 'Orientación';

  @override
  String get hubPortrait => 'Vertical';

  @override
  String get hubLandscape => 'Horizontal';

  @override
  String get hubVariantLabel => 'Tipo';

  @override
  String get hubResolutionLabel => 'Resolución';

  @override
  String get hubResolutionUnitLabel => 'Unidad de resolución';

  @override
  String get hubColorModeLabel => 'Modo de color';

  @override
  String get hubBackgroundLabel => 'Color de fondo';

  @override
  String get hubBackgroundWhite => 'Blanco';

  @override
  String get hubBackgroundTransparent => 'Transparente';

  @override
  String get hubBackgroundBlack => 'Negro';

  @override
  String get hubBackgroundCustom => 'Color personalizado';

  @override
  String get hubCreateProject => 'Crear proyecto';

  @override
  String get hubCustomFamilyTitle => 'Tamaño personalizado';

  @override
  String get newDocTitle => 'Documento nuevo';

  @override
  String get newDocScopeSocial => 'Pantallas y felicitaciones';

  @override
  String get newDocFilterCertificates => 'Certificados';

  @override
  String get newDocFilterCards => 'Tarjetas';

  @override
  String get newDocFilterGreeting => 'Felicitaciones';

  @override
  String get newDocFilterPublications => 'Publicaciones';

  @override
  String get menuFile => 'Archivo';

  @override
  String get menuEdit => 'Edición';

  @override
  String get menuView => 'Ver';

  @override
  String get menuTools => 'Herramientas';

  @override
  String get menuHelp => 'Ayuda';

  @override
  String get menuNewDocument => 'Documento nuevo…';

  @override
  String get menuPurgeRecent => 'Vaciar tamaños recientes';

  @override
  String get menuPurgeImageCache => 'Vaciar la caché de imágenes';

  @override
  String get menuPreviewCertificate => 'Previsualizar certificado de ejemplo';

  @override
  String get menuPreviewContract => 'Previsualizar contrato de ejemplo';

  @override
  String get menuAbout => 'Acerca de JoodCraft';

  @override
  String get actionNewShort => '+ Nuevo';

  @override
  String get dashLocalMode => 'Local';

  @override
  String get dashLocalStorage =>
      'Guardado localmente en este dispositivo — ningún proyecto se sube a un servidor.';

  @override
  String get dashRecentProjects => 'Proyectos recientes';

  @override
  String get dashRecentEmpty =>
      'Aún no hay proyectos guardados en este dispositivo: cree un documento y aparecerá aquí al instante.';

  @override
  String get dashRecentOpen => 'Abrir proyecto';

  @override
  String get editorTransformPosition => 'Transformación y posición';

  @override
  String get editorTransformPositionHint =>
      'Posición, tamaño y ángulo de rotación';

  @override
  String get editorAppearanceEffects => 'Apariencia y efectos';

  @override
  String get editorAppearanceEffectsHint => 'Relleno, borde, brillo y sombras';

  @override
  String get editorTypographyHint => 'Fuente, tamaño, alineación y espaciado';

  @override
  String get editorPageSettingsHint => 'Tamaño y unidad de medida';

  @override
  String get editorBackgroundHint => 'Color o degradado de la página';

  @override
  String get editorPrecisionHint => 'Desplazamiento fino y escala';

  @override
  String get joodExportProject => 'Exportar proyecto (.jood)';

  @override
  String get joodImportProject => 'Abrir proyecto (.jood)';

  @override
  String get joodExportReady =>
      'El archivo del proyecto está listo para guardar.';

  @override
  String get joodExportFailed => 'No se pudo exportar el archivo del proyecto.';

  @override
  String get joodImportOpened => 'Proyecto importado abierto.';

  @override
  String get joodImportFailed => 'No se pudo abrir el archivo del proyecto.';

  @override
  String get joodRecoveryTitle => 'Borrador sin guardar';

  @override
  String get joodRecoveryMessage =>
      'Hay un borrador sin guardar de una sesión anterior. ¿Desea restaurarlo?';

  @override
  String get joodRecoveryRestore => 'Restaurar';

  @override
  String get joodRecoveryDiscard => 'Descartar';

  @override
  String get joodRecoveryRestored => 'Borrador restaurado.';

  @override
  String get joodAutosaveSaved => 'Guardado automáticamente';

  @override
  String get joodAutosaveSaving => 'Guardando…';

  @override
  String get editorConfirm => 'Confirmar';

  @override
  String get admTitle => 'Gestión de administradores locales';

  @override
  String get admRefresh => 'Actualizar';

  @override
  String get admTabAdmins => 'Administradores';

  @override
  String get admTabTransfer => 'Transferencia entre dispositivos';

  @override
  String get admTabAudit => 'Registro de exportaciones';

  @override
  String get admListTitle => 'Cuentas de administrador en este dispositivo';

  @override
  String get admAdd => 'Añadir administrador';

  @override
  String get admNoAdmins => 'Aún no hay cuentas de administrador.';

  @override
  String get admLoading =>
      'Cargando las cuentas de administrador de este dispositivo…';

  @override
  String get admRoleOwner => 'Administrador principal';

  @override
  String get admCurrent => 'Tú';

  @override
  String get admCurrentCardTitle => 'Cuenta actual en este dispositivo';

  @override
  String get admRoleAdmin => 'Administrador';

  @override
  String get admSwitchTitle => 'Cambio rápido de cuenta';

  @override
  String get admSwitchPrompt =>
      'Elige el nombre de usuario local de un subadministrador en este dispositivo e introduce su contraseña local para entrar directamente en su sesión: los borradores de proyectos abiertos se guardan primero y la licencia maestra no se ve afectada.';

  @override
  String get admSwitchNoOthers =>
      'No hay otros subadministradores en este dispositivo. Añade primero un administrador desde la pantalla de administradores.';

  @override
  String get admSwitchPick => 'Nombre de usuario local';

  @override
  String get admSwitchPassword => 'Contraseña local de la cuenta seleccionada';

  @override
  String get admSwitchPickPassword =>
      'Elige un nombre de usuario e introduce la contraseña.';

  @override
  String get admSwitchWrongPassword => 'Contraseña incorrecta.';

  @override
  String get admSwitchFailed =>
      'No se pudo cambiar de cuenta. Inténtalo de nuevo.';

  @override
  String get admSwitchSuccess => 'Cuenta cambiada correctamente.';

  @override
  String get admSwitchAccount => 'Cambiar cuenta';

  @override
  String get admSwitchAction => 'Cambiar ahora';

  @override
  String get admColAdmin => 'Administrador';

  @override
  String get admColUsername => 'Nombre de usuario local';

  @override
  String get admColRole => 'Rol';

  @override
  String get admColCreated => 'Añadido el';

  @override
  String get admColActions => 'Acciones';

  @override
  String get destJoodWriter => 'Jood Writer';

  @override
  String get destJoodWriterDesc =>
      'Documentos e informes de texto con páginas de flujo automático.';

  @override
  String get admCreatedAt => 'Creado';

  @override
  String get admEdit => 'Editar datos';

  @override
  String get admChangePassword => 'Cambiar contraseña';

  @override
  String get admPromote => 'Ascender a administrador principal';

  @override
  String get admDemote => 'Degradar a administrador';

  @override
  String get admDelete => 'Eliminar cuenta';

  @override
  String admDeleteConfirm(Object name) {
    return '“$name” se eliminará permanentemente de este dispositivo. Esta acción no se puede deshacer.';
  }

  @override
  String get admPromoted => 'Ascendido a administrador principal.';

  @override
  String get admDemoted => 'Degradado a administrador.';

  @override
  String get admDeleted => 'Cuenta eliminada.';

  @override
  String get admCreated => 'Nuevo administrador añadido.';

  @override
  String get admUpdated => 'Datos del administrador actualizados.';

  @override
  String get admPasswordChanged => 'Contraseña cambiada.';

  @override
  String get admTransferInfoTitle => '¿Cómo funciona la transferencia?';

  @override
  String get admTransferInfo1 =>
      'La tabla de cuentas (con los hashes de contraseña, nunca las contraseñas) se exporta dentro de un archivo cifrado con una frase de contraseña que tú eliges.';

  @override
  String get admTransferInfo2 =>
      'Mueve el archivo o el código al otro dispositivo e impórtalo allí con la misma frase de contraseña, y las cuentas funcionarán con los mismos permisos.';

  @override
  String get admTransferInfo3 =>
      'No se envía nada a ningún servidor: la transferencia es totalmente manual entre dispositivos locales.';

  @override
  String get admExport => 'Exportar cuentas';

  @override
  String get admExportPassphrase => 'Frase de contraseña de exportación';

  @override
  String get admPassphraseConfirm => 'Confirmar frase de contraseña';

  @override
  String get admExportRisk =>
      'Entiendo que cualquiera que posea este código y su frase de contraseña puede iniciar sesión con estas cuentas, así que lo compartiré con cuidado.';

  @override
  String get admExportGenerate => 'Generar código cifrado';

  @override
  String get admExportFile => 'Guardar en un archivo dedicado';

  @override
  String get admExportDone =>
      'Código cifrado generado. Cópialo o guárdalo en un archivo.';

  @override
  String get admExportFileSaved => 'Archivo cifrado de cuentas guardado.';

  @override
  String get admPassphraseTooShort =>
      'Usa al menos 6 caracteres para la frase de contraseña.';

  @override
  String get admPassphraseMismatch => 'Las frases de contraseña no coinciden.';

  @override
  String get admAcceptRiskRequired =>
      'Primero confirma que entiendes el riesgo de compartir el código.';

  @override
  String admFileError(Object error) {
    return 'No se pudo manejar el archivo: $error';
  }

  @override
  String get admImport => 'Importar cuentas';

  @override
  String get admImportCode => 'Código de cuentas';

  @override
  String get admImportPassphrase => 'Frase de contraseña del archivo';

  @override
  String get admImportReplace =>
      'Reemplazar las contraseñas de las cuentas existentes';

  @override
  String get admImportPick => 'Elegir un archivo';

  @override
  String get admImportRun => 'Importar ahora';

  @override
  String get admImportCodeRequired =>
      'Pega el código o elige un archivo primero.';

  @override
  String get admImportPassphraseRequired =>
      'Introduce la frase de contraseña del archivo.';

  @override
  String admImportDone(int added, int updated, int skipped) {
    return 'Importado: $added nuevas, $updated actualizadas, $skipped omitidas.';
  }

  @override
  String get admAuditTitle => 'Registro de certificados y documentos emitidos';

  @override
  String get admAuditClear => 'Borrar registro';

  @override
  String get admAuditEmpty =>
      'Aún no hay exportaciones. Cada certificado o contrato que exportes se registrará aquí con su fecha y el administrador que lo emitió.';

  @override
  String get admAuditBy => 'Por';

  @override
  String get admAuditPages => 'páginas';

  @override
  String get admAuditClearConfirm =>
      'Todo el registro de exportaciones se eliminará de este dispositivo. Esta acción no se puede deshacer.';

  @override
  String get admAuditCleared => 'Registro borrado.';

  @override
  String get admUnavailableTitle => 'La gestión no está disponible ahora mismo';

  @override
  String get admUnavailableBody =>
      'La gestión de administradores funciona cuando la aplicación se ejecuta con una cuenta local (LocalAuthRepository), de modo que las cuentas se leen de este dispositivo.';

  @override
  String get pdfExportTypeTitle => 'Tipo de exportación';

  @override
  String get pdfExportTypeHint =>
      'Elige el formato del archivo antes de exportar.';

  @override
  String get pdfExportTypeImages => 'Imágenes';

  @override
  String get pdfExportTypeImagesDesc =>
      'Coincidencia del 100 % — archivo más grande';

  @override
  String get pdfExportTypeImagesNotCopyable => 'El texto no se puede copiar';

  @override
  String get pdfExportTypeVector => 'Vector';

  @override
  String get pdfExportTypeVectorDesc => 'Texto copiable — archivo más pequeño';

  @override
  String get pdfExportTypeVectorCopyable =>
      'Texto que se puede copiar y buscar';

  @override
  String get pdfExportTypeVectorBestFor => 'Ideal para impresión profesional';

  @override
  String get pdfExportTypeComingSoon => 'Próximamente';

  @override
  String get pdfExportTypeComingSoonMessage =>
      'La exportación vectorial está en desarrollo — estará disponible pronto.';

  @override
  String get invCategoryTitle => 'Invitaciones y ocasiones';

  @override
  String get invCategoryRamadan => 'Ramadán';

  @override
  String get invCategoryEid => 'Eid';

  @override
  String get invCategoryWedding => 'Boda';

  @override
  String get invRamadan1Title => 'Ramadán Karim — Clásico';

  @override
  String get invRamadan2Title => 'Ramadán Karim — Story';

  @override
  String get invEid1Title => 'Eid Mubarak — Clásico';

  @override
  String get invEid2Title => 'Eid Mubarak — Story';

  @override
  String get invWedding1Title => 'Boda — Clásica';

  @override
  String get invWedding2Title => 'Boda — Moderna';

  @override
  String get invWedding3Title => 'Boda — Story';

  @override
  String get invSizeA6Portrait => 'A6 vertical (105×148 mm)';

  @override
  String get invSizeA6Landscape => 'A6 horizontal (148×105 mm)';

  @override
  String get invSizeSquare148 => 'Cuadrado para impresión (148×148 mm)';

  @override
  String get invSizeA5Folded => 'A5 plegado (105×148 mm)';

  @override
  String get invSizeInstagramSquare => 'Instagram cuadrado (1080×1080)';

  @override
  String get invSizeInstagramPortrait => 'Instagram vertical (1080×1350)';

  @override
  String get invSizeInstagramStory => 'Instagram Story (1080×1920)';

  @override
  String get invSizeWhatsAppStatus => 'WhatsApp Status (1080×1920)';

  @override
  String get invSizeFacebookPost => 'Facebook Post (1200×630)';

  @override
  String get invExportFormatPNG => 'PNG (para redes sociales)';

  @override
  String get invExportFormatPDF => 'PDF (para imprimir)';

  @override
  String get invExportFormatBoth => 'PNG + PDF';

  @override
  String get invBulkModeTitle => 'Invitaciones personales por lotes';

  @override
  String get invBulkModeHint =>
      'Una tarjeta por nombre — exportación individual.';

  @override
  String get invPreviewTitle => 'Vista previa de las 3 primeras copias';

  @override
  String get invExportFormat => 'Formato de exportación';

  @override
  String get invNameFieldMissing =>
      'Esta plantilla no tiene un campo de nombre';

  @override
  String invDuplicateNames(Object count) {
    return 'Nombres duplicados: $count';
  }

  @override
  String invEmptyNames(Object count) {
    return 'Celdas vacías: $count — se omitirán';
  }

  @override
  String get invZIPOption => 'Comprimir en un archivo ZIP';

  @override
  String get invIndexCSVOption => 'Crear un índice CSV';

  @override
  String invProgressText(Object done, Object total) {
    return 'Generadas $done de $total';
  }

  @override
  String get navEditors => 'Editores';

  @override
  String get navLibraries => 'Bibliotecas';

  @override
  String get navAdmin => 'Administración';

  @override
  String get navUser => 'Cuenta';

  @override
  String get bpWorkTypeLabel => 'Tipo de plantilla';

  @override
  String get bpExportFormatLabel => 'Tipo de exportación';

  @override
  String get bpKindInvitation => 'Invitación';

  @override
  String get invPackOptions => 'Opciones de salida';

  @override
  String get tplCertClassicTitle => 'Certificado clasico azul marino';

  @override
  String get tplCertClassicDesc =>
      'Certificado azul marino clasico con doble marco dorado y estrellas ornamentales.';

  @override
  String get tplCertMinimalTitle => 'Certificado minimal azul marino';

  @override
  String get tplCertMinimalDesc =>
      'Diseno minimalista azul marino limpio con una sola linea dorada y amplios espacios.';

  @override
  String get tplCertIslamicTitle => 'Certificado ornamento islamico';

  @override
  String get tplCertIslamicDesc =>
      'Certificado azul marino con bordes dorados, ornamentos geometricos islamicos y tipografia Amiri.';

  @override
  String get tplCertBandTitle => 'Certificado de bandas doradas';

  @override
  String get tplCertBandDesc =>
      'Certificado azul marino con bandas horizontales doradas arriba y abajo.';

  @override
  String get tplCertDiagonalTitle => 'Certificado diagonal dinamico';

  @override
  String get tplCertDiagonalDesc =>
      'Certificado azul marino con formas geometricas doradas inclinadas que sugieren movimiento.';

  @override
  String get tplCertSquareTitle => 'Certificado cuadrado elegante';

  @override
  String get tplCertSquareDesc =>
      'Certificado azul marino con marco cuadrado dorado simetrico y sello circular superior.';
}
