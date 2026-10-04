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
  String get dashRoadmapSupabase =>
      'Configuración de la base de datos Supabase (tablas + RLS + triggers)';

  @override
  String get dashRoadmapModular =>
      'Una estructura modular Feature-First escalable';

  @override
  String get dashRoadmapTheme =>
      'El tema visual de la marca con soporte RTL en la fuente Cairo';

  @override
  String get dashRoadmapAuth =>
      'Autenticación: inicio de sesión, creación de cuenta y restablecimiento de contraseña';

  @override
  String get dashPhaseOneDone => 'Primera fase completada';

  @override
  String get dashNextPhase =>
      'Siguiente: el motor de PDF sin conexión y las fuentes árabes, luego el editor visual de plantillas.';

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
}
