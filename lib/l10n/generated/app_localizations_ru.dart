// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTagline =>
      'Создавайте официальные сертификаты и договоры офлайн';

  @override
  String get navDashboard => 'Панель управления';

  @override
  String get navCertificates => 'Конструктор сертификатов';

  @override
  String get navContracts => 'Конструктор договоров';

  @override
  String get navBatch => 'Пакетная генерация';

  @override
  String get navTemplates => 'Библиотека шаблонов';

  @override
  String get navAssets => 'Ресурсы и подписи';

  @override
  String get actionSignOut => 'Выйти';

  @override
  String get actionBackToDashboard => 'Вернуться к панели';

  @override
  String get offlineProcessingLabel => 'Локальная обработка';

  @override
  String get themeTooltip => 'Сменить тему';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get languageTooltip => 'Сменить язык';

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
  String get configMissingKeysTitle => 'Ключи подключения не найдены';

  @override
  String get configMissingKeysBody =>
      'При запуске приложение ищет ключи в трёх источниках: флаг --dart-define, затем файл env.json на диске (корень или assets/env/) и, наконец, встроенная копия — ни один не найден. Создайте файл, заполните его один раз и запустите без флагов:';

  @override
  String get configEnvNote =>
      'Пакет объявляет assets/env/ как ресурс, поэтому отсутствие файла не ломает чистую сборку. Создайте его из env.example.json или выполните: dart run tool/ensure_env.dart — требуется только ключ anon/public; service_role в приложении не используется.';

  @override
  String get routeNotFoundTitle => 'Страница не найдена';

  @override
  String get routeNotFoundBody =>
      'Запрошенный маршрут не определён в приложении:';

  @override
  String get editorPrecisionTitle => 'Точная настройка';

  @override
  String get editorNudgeStep => 'Шаг сдвига';

  @override
  String get editorNudgeStepHint =>
      'Стрелки на холсте также сдвигают на Shift = 10px.';

  @override
  String get editorNudgeUp => 'Сдвинуть вверх';

  @override
  String get editorNudgeLeft => 'Сдвинуть влево';

  @override
  String get editorNudgeDown => 'Сдвинуть вниз';

  @override
  String get editorNudgeRight => 'Сдвинуть вправо';

  @override
  String get editorScale => 'Масштаб';

  @override
  String get editorScaleHint =>
      'Относительное масштабирование вокруг центра элемента (колесо на кнопках — мельче шаг).';

  @override
  String get editorScaleUp => 'Увеличить';

  @override
  String get editorScaleDown => 'Уменьшить';

  @override
  String get editorDecorTitle => 'Векторное украшение';

  @override
  String get editorDecorKind => 'Тип украшения';

  @override
  String get editorDecorPalette => 'Палитра цветов';

  @override
  String get editorDecorLayers => 'Число слоёв';

  @override
  String get editorDecorSeed => 'Зерно';

  @override
  String get editorDecorThickness => 'Толщина';

  @override
  String get editorDecorPrimary => 'Основной цвет';

  @override
  String get editorDecorSecondary => 'Второй цвет';

  @override
  String get editorDecorAccent => 'Акцентный цвет';

  @override
  String get editorDecorGradient => 'Градиент слоёв';

  @override
  String get editorDecorGallery => 'Галерея шаблонов';

  @override
  String get editorDecorGalleryTitle => 'Галерея готовых украшений';

  @override
  String get editorClose => 'Закрыть';

  @override
  String get editorDecorPaletteCustom => 'Своя';

  @override
  String get decorKindModernWave => 'Современные волны';

  @override
  String get decorKindPaperCut => 'Многослойная бумажная вырезка';

  @override
  String get decorKindClassicCorner => 'Классическая рама с орнаментом';

  @override
  String get decorKindGuilloche => 'Гильош';

  @override
  String get decorKindRibbonBanner => 'Лента / баннер';

  @override
  String get decorPaletteRoyalGold => 'Королевское золото';

  @override
  String get decorPaletteRoyalBlue => 'Королевский синий';

  @override
  String get decorPaletteEmerald => 'Изумруд';

  @override
  String get decorPaletteBurgundy => 'Бордовый';

  @override
  String get decorPaletteMidnight => 'Полуночный синий';

  @override
  String get decorPaletteMono => 'Монохромный серый';

  @override
  String get editorSignatureTitle => 'Блок подписей';

  @override
  String get editorSignatureCount => 'Количество подписей';

  @override
  String get signatureCountOne => 'Одна подпись';

  @override
  String get signatureCountTwo => 'Две подписи';

  @override
  String get signatureCountThree => 'Три подписи';

  @override
  String get editorSignatureOrder => 'Порядок блоков';

  @override
  String get editorSignatureOrderHint =>
      'В арабских документах первый блок располагается крайним справа.';

  @override
  String get editorSignatureFirstRight => 'Первый справа';

  @override
  String get editorSignatureFirstLeft => 'Первый слева';

  @override
  String get editorDirectionAuto => 'Автоматически';

  @override
  String get editorSignatureImageAlign => 'Выравнивание изображения';

  @override
  String get editorAlignStart => 'Начало';

  @override
  String get editorAlignCenter => 'Центр';

  @override
  String get editorAlignEnd => 'Конец';

  @override
  String get editorSignatureDivider => 'Линия подписи';

  @override
  String get editorVisible => 'Видно';

  @override
  String get editorHidden => 'Скрыто';

  @override
  String get editorSignatureNameSize => 'Размер имени';

  @override
  String get editorSignatureRoleSize => 'Размер должности';

  @override
  String get editorSignatureSpacing => 'Интервал';

  @override
  String get editorSignatureImageSize => 'Размер изображения';

  @override
  String get editorSignatureNameColor => 'Цвет имени';

  @override
  String get editorSignatureRoleColor => 'Цвет должности';

  @override
  String get editorFont => 'Шрифт';

  @override
  String get editorImageSource => 'Источник изображения';

  @override
  String get imageSourceAppAssets => 'Ресурсы приложения';

  @override
  String get imageSourceMyLibrary => 'Моя библиотека';

  @override
  String get imageSourceLocalFile => 'Локальный файл';

  @override
  String get imageSourceEmbedded => 'Встроенные данные';

  @override
  String get editorSignatureChangeImage => 'Заменить изображение подписи';

  @override
  String get editorSignatureAddImage => 'Добавить изображение подписи';

  @override
  String get editorSignatureRemoveImage => 'Удалить изображение подписи';

  @override
  String get editorSignaturePickImageTitle =>
      'Выбрать изображение подписи из моей библиотеки';

  @override
  String get editorSignatureSlot => 'Блок';

  @override
  String get editorSignatureRoleField =>
      'Должность (напр. генеральный директор)';

  @override
  String get editorSignatureNameField =>
      'Имя подписанта (принимает динамическое поле)';

  @override
  String get editorFromMyLibrary => 'Из моей библиотеки';

  @override
  String get paletteSignatureBlock => 'Подписи';

  @override
  String get editorInsertFromLibraryTooltip =>
      'Вставить загруженную рамку или логотип напрямую';

  @override
  String get unsupportedElementVersionNote =>
      'Этот элемент из более новой версии редактора — он сохраняется как есть и не может быть здесь изменён.';

  @override
  String editorSelectedCount(Object count) {
    return '$count выбрано';
  }

  @override
  String get editorClearSelection => 'Снять выделение';

  @override
  String get editorGroup => 'Группа';

  @override
  String get editorOpacity => 'Непрозрачность';

  @override
  String get editorBringToFront => 'На передний план';

  @override
  String get editorSendToBack => 'На задний план';

  @override
  String get editorDuplicate => 'Дублировать';

  @override
  String get editorDeleteSelected => 'Удалить выбранное';

  @override
  String get editorGroupDragHint =>
      'Перетаскивайте группу мышью, используйте стрелки для точного сдвига (Shift = 10px) и Ctrl + щелчок для изменения выделения.';

  @override
  String get editorBringForward => 'На шаг вперёд';

  @override
  String get editorDuplicateElement => 'Дублировать элемент';

  @override
  String get editorDeleteElement => 'Удалить элемент';

  @override
  String get editorPageSettings => 'Настройки страницы';

  @override
  String get editorPageSize => 'Размер';

  @override
  String get editorUnit => 'Единица';

  @override
  String get editorWidth => 'Ширина';

  @override
  String get editorHeight => 'Высота';

  @override
  String get editorLabelText => 'Текст';

  @override
  String get editorLabelShape => 'Фигура';

  @override
  String get editorLabelSeal => 'Печать';

  @override
  String get editorLabelDecoration => 'Векторное украшение';

  @override
  String get editorLabelSignature => 'Блок подписей';

  @override
  String get editorLabelImage => 'Изображение / логотип';

  @override
  String get editorLabelQr => 'QR-код';

  @override
  String get editorLabelUnknown => 'Неподдерживаемый элемент';

  @override
  String get editorLabelDynamicField => 'Динамическое поле';

  @override
  String get editorPositionAndSize => 'Положение и размер';

  @override
  String get editorPosX => 'X';

  @override
  String get editorPosY => 'Y';

  @override
  String get editorRotation => 'Поворот';

  @override
  String get editorTextFormat => 'Форматирование текста';

  @override
  String get editorConvertToField => 'Преобразовать в динамическое поле';

  @override
  String get editorFontWeight => 'Насыщенность';

  @override
  String get editorWeightRegular => 'Обычный';

  @override
  String get editorWeightSemiBold => 'Полужирный';

  @override
  String get editorWeightBold => 'Жирный';

  @override
  String get editorFontSize => 'Размер шрифта';

  @override
  String get editorLetterSpacing => 'Межбуквенный интервал';

  @override
  String get editorLineHeight => 'Высота строки';

  @override
  String get editorTextColor => 'Цвет текста';

  @override
  String get editorTextBackground => 'Фон текста';

  @override
  String get editorTextAlign => 'Выравнивание';

  @override
  String get editorAlignJustify => 'По ширине';

  @override
  String get editorJustifyMode => 'Способ выравнивания';

  @override
  String get editorJustifyHint =>
      'Кашида применяется в PDF-файле (предпросмотр показывает выравнивание пробелами)';

  @override
  String get editorJustifySpaces => 'Пробелы';

  @override
  String get editorJustifyKashida => 'Кашида';

  @override
  String get editorVerticalAlign => 'Вертикальное выравнивание';

  @override
  String get editorVerticalTop => 'Сверху';

  @override
  String get editorVerticalBottom => 'Снизу';

  @override
  String get editorDirection => 'Направление';

  @override
  String get editorDirectionHint =>
      'Горячая клавиша переключения: Ctrl+Shift+D';

  @override
  String get editorDirectionRtl => 'Арабский (RTL)';

  @override
  String get editorDirectionLtr => 'Латинский (LTR)';

  @override
  String get editorImage => 'Изображение';

  @override
  String get editorSource => 'Источник';

  @override
  String get editorImageFit => 'Вписывание изображения';

  @override
  String get editorFitContain => 'Вписать';

  @override
  String get editorFitCover => 'Заполнить';

  @override
  String get editorFitFill => 'Растянуть';

  @override
  String get assetPickerEmptyHint =>
      'Вы ещё не загрузили ресурсы. Загрузите логотип, подпись или печать, чтобы использовать их здесь и при печати.';

  @override
  String get assetPickerNoneOption => 'Нет (другой источник)';

  @override
  String get assetPickerTitle => 'Выбрать изображение из моей библиотеки';

  @override
  String assetUploadType(Object type) {
    return 'Загрузить $type';
  }

  @override
  String get editorSeal => 'Печать';

  @override
  String get editorSealColor => 'Цвет печати';

  @override
  String get editorSealRingColor => 'Цвет кольца';

  @override
  String get editorSealStarColor => 'Цвет звезды';

  @override
  String get editorSealStarSize => 'Размер звезды';

  @override
  String get editorShape => 'Фигура';

  @override
  String get editorFillColor => 'Цвет заливки';

  @override
  String get editorBorderColor => 'Цвет границы';

  @override
  String get editorBorderWidth => 'Толщина границы';

  @override
  String get editorCornerRadius => 'Радиус углов';

  @override
  String get editorQrVerify => 'Код проверки';

  @override
  String get editorQrData => 'Данные кода';

  @override
  String get editorQrColor => 'Цвет кода';

  @override
  String get editorQrBackground => 'Фон кода';

  @override
  String editorConvertDialogMessage(Object text) {
    return 'Преобразование превращает текст «$text» в динамический маркер, который можно привязать при массовой генерации.';
  }

  @override
  String get editorFieldKeyHint => 'Ключ поля (напр. имя, дата, ссылка)';

  @override
  String get editorCustomKeyHint =>
      'Введите свой ключ (без скобок — будет добавлен автоматически)';

  @override
  String get editorCancel => 'Отмена';

  @override
  String get editorConvert => 'Преобразовать';

  @override
  String get editorPath => 'Путь';

  @override
  String get editorTextContent => 'Содержимое текста';

  @override
  String editorInsertFieldToken(Object token) {
    return 'Вставить $token';
  }

  @override
  String editorAddLabel(Object label) {
    return 'Добавить $label';
  }

  @override
  String assetInsertedSnack(Object name) {
    return '«$name» вставлен в шаблон.';
  }

  @override
  String get paletteHeading => 'Заголовок';

  @override
  String get paletteFrame => 'Прямоугольник / рамка';

  @override
  String get paletteDivider => 'Разделитель';

  @override
  String get paletteLogo => 'Логотип / подпись';

  @override
  String get evSignatureEmptyLabel => 'Пустая подпись';

  @override
  String get evSignatureEmptyDetail =>
      'Добавьте должность, имя и изображение подписи';

  @override
  String get evSignatureMissingLabel => 'Подпись отсутствует';

  @override
  String get evUploadToLibraryDetail =>
      'Загрузите изображение в библиотеку ресурсов';

  @override
  String get evImageNotFoundLabel => 'Изображение не найдено';

  @override
  String get evNoFileLabel => 'Файл не выбран';

  @override
  String get evChooseFromAssetsDetail =>
      'Выберите изображение из библиотеки ресурсов';

  @override
  String get evAssetMissingLabel => 'Ресурс отсутствует';

  @override
  String get evReselectAssetDetail =>
      'Повторно выберите рамку/ресурс из библиотеки';

  @override
  String get evInvalidImageLabel => 'Недопустимое изображение';

  @override
  String get evRenderDataFailedDetail => 'Не удалось отобразить данные';

  @override
  String get evInvalidDataLabel => 'Недопустимые данные';

  @override
  String get evDecodeFailedDetail => 'Не удалось декодировать изображение';

  @override
  String get evEmptyQrLabel => 'Пустой код';

  @override
  String get evEmptyQrDetail => 'Введите значение кода в панели свойств';

  @override
  String evUnknownElementLabel(Object type) {
    return 'Неподдерживаемый элемент: $type';
  }

  @override
  String get alpFilterAll => 'Все';

  @override
  String get alpEmptyHint =>
      'Нет загруженных ресурсов нужных типов. Загрузите рамку или логотип в разделе «Ресурсы и подписи» и повторите попытку.';

  @override
  String alpNoFilteredAssets(Object type) {
    return 'Нет ресурсов типа «$type».';
  }

  @override
  String get authWelcomeBack => 'Добро пожаловать в JoodCraft.';

  @override
  String get authResetLinkSent =>
      'Ссылка для сброса отправлена. Проверьте почту.';

  @override
  String get authLogin => 'Войти';

  @override
  String get authLoginSubtitle =>
      'Ваш электронный адрес и пароль для входа в панель.';

  @override
  String get authNoAccount => 'Нет аккаунта?';

  @override
  String get authCreateAccountLink => 'Создать новый аккаунт';

  @override
  String get authConfirmEmailThenLogin =>
      'Аккаунт создан. Сначала подтвердите почту, затем войдите.';

  @override
  String get authEmail => 'Электронная почта';

  @override
  String get authPassword => 'Пароль';

  @override
  String get authForgotPassword => 'Забыли пароль?';

  @override
  String get authEnterDashboard => 'Войти в панель';

  @override
  String get authResetPassword => 'Сбросить пароль';

  @override
  String get authResetPasswordHint =>
      'Введите почту, и мы отправим ссылку для сброса пароля.';

  @override
  String get authSendLink => 'Отправить ссылку';

  @override
  String get authConfirmEmailMessage =>
      'Аккаунт создан. Подтвердите его по почте, затем войдите.';

  @override
  String get authAccountCreatedWelcome =>
      'Аккаунт создан. Добро пожаловать в JoodCraft.';

  @override
  String get authCreateAccount => 'Создать аккаунт';

  @override
  String get authRegisterSubtitle =>
      'Аккаунт сохраняет ваши шаблоны и ресурсы (логотип, подпись, печать) для повторного использования.';

  @override
  String get authHaveAccount => 'Уже есть аккаунт?';

  @override
  String get authFullName => 'Полное имя';

  @override
  String get authFullNameHint => 'напр. Абдулла Аль-Ахмад';

  @override
  String get authName => 'Имя';

  @override
  String get authOrgName => 'Название организации (необязательно)';

  @override
  String get authOrgNameHint => 'напр. Благотворительная ассоциация Jood';

  @override
  String get authOrgHelper =>
      'Автоматически печатается на сертификатах и договорах.';

  @override
  String get authOrgNameShort => 'Название организации';

  @override
  String get authPasswordHint => 'Не менее 8 символов';

  @override
  String authPasswordRule(Object min) {
    return 'Используйте не менее $min символов с цифрами и символами.';
  }

  @override
  String get authConfirmPassword => 'Подтвердите пароль';

  @override
  String get authCreateAccountButton => 'Создать аккаунт';

  @override
  String get authFeatureLocalExcel =>
      'Полностью локальная обработка файлов Excel — данные не покидают устройство';

  @override
  String get authFeaturePdf =>
      'Создание PDF с качественными арабскими шрифтами и полной поддержкой RTL';

  @override
  String get authFeatureTemplates =>
      'Ваши шаблоны хранятся в аккаунте и готовы к повторному использованию';

  @override
  String get authTagline =>
      'Ваши официальные сертификаты и договоры… печатаются с уверенностью.';

  @override
  String authVersion(Object name, Object version) {
    return '$name • Версия $version';
  }

  @override
  String get dashModules => 'Модули платформы';

  @override
  String dashWelcome(Object name) {
    return 'Добро пожаловать, $name';
  }

  @override
  String dashSubscription(Object tier) {
    return 'Подписка: $tier';
  }

  @override
  String dashOrg(Object name) {
    return 'Организация: $name';
  }

  @override
  String get dashOrgMissing =>
      'Вы ещё не указали название организации — оно будет автоматически печататься на сертификатах и договорах.';

  @override
  String get dashOpenModule => 'Открыть модуль';

  @override
  String get dashRoadmapSupabase =>
      'Настройка базы данных Supabase (таблицы + RLS + триггеры)';

  @override
  String get dashRoadmapModular =>
      'Масштабируемая модульная структура Feature-First';

  @override
  String get dashRoadmapTheme =>
      'Визуальная тема бренда с поддержкой RTL в шрифте Cairo';

  @override
  String get dashRoadmapAuth =>
      'Аутентификация: вход, создание аккаунта и сброс пароля';

  @override
  String get dashPhaseOneDone => 'Первый этап завершён';

  @override
  String get dashNextPhase =>
      'Далее: офлайн-движок PDF и арабские шрифты, затем визуальный редактор шаблонов.';

  @override
  String get destDashboard => 'Панель управления';

  @override
  String get destDashboardDesc => 'Обзор ваших проектов и шаблонов.';

  @override
  String get destCertificates => 'Движок сертификатов';

  @override
  String get destCertificatesDesc =>
      'Создавайте альбомные сертификаты из редактируемого шаблона.';

  @override
  String get destContracts => 'Движок договоров';

  @override
  String get destContractsDesc =>
      'Составляйте книжные договоры с динамическими полями.';

  @override
  String get destBatch => 'Массовая генерация';

  @override
  String get destBatchDesc =>
      'Читайте файл Excel локально и создавайте сотни сертификатов за раз.';

  @override
  String get destTemplates => 'Библиотека шаблонов';

  @override
  String get destTemplatesDesc =>
      'Управляйте, сортируйте и повторно используйте сохранённые шаблоны.';

  @override
  String get destAssets => 'Ресурсы и подписи';

  @override
  String get destAssetsDesc => 'Ваши логотип, печать, подпись и рамки.';

  @override
  String get dashUser => 'Пользователь';

  @override
  String get dashLogoutSuccess => 'Вы успешно вышли.';

  @override
  String get dashLogoutError => 'Не удалось выйти. Повторите попытку.';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonPreview => 'Предпросмотр';

  @override
  String get commonOptions => 'Параметры';

  @override
  String get tplDelete => 'Удалить';

  @override
  String get tplSortRecentlyUpdated => 'Недавно изменённые';

  @override
  String get tplSortTitleAsc => 'Имя (А–Я)';

  @override
  String get tplSortLabel => 'Сортировка';

  @override
  String get tplSubtitle =>
      'Профессиональные готовые шаблоны + ваши сохранённые — поиск, фильтр, открытие и импорт полностью офлайн.';

  @override
  String get tplRefreshTooltip => 'Обновить список';

  @override
  String get tplSearchHint => 'Поиск шаблонов…';

  @override
  String get tplNoResultsTitle => 'Нет совпадающих результатов';

  @override
  String get tplNoResultsMessage =>
      'Попробуйте другой запрос или сбросьте фильтр.';

  @override
  String tplAddedToLocal(Object title) {
    return '«$title» добавлен в ваши локальные шаблоны.';
  }

  @override
  String get tplCloudRequiresConnection =>
      'Для сохранения шаблонов в облаке нужно подключение к проекту Supabase. Сохраните локально.';

  @override
  String tplSavedToCloud(Object title) {
    return '«$title» сохранён в облаке.';
  }

  @override
  String get tplRenamed => 'Шаблон переименован.';

  @override
  String tplCopySuffix(Object title) {
    return '$title (копия)';
  }

  @override
  String tplCopyCreated(Object title) {
    return 'Создана копия «$title».';
  }

  @override
  String get tplNowPrivate => 'Шаблон теперь приватный.';

  @override
  String get tplNowPublic => 'Шаблон теперь публичный (только для чтения).';

  @override
  String tplConfirmCloudDelete(Object title) {
    return '«$title» будет окончательно удалён из облака. Отменить нельзя.';
  }

  @override
  String tplCloudDeleted(Object title) {
    return 'Шаблон «$title» удалён.';
  }

  @override
  String tplConfirmLocalDelete(Object title) {
    return '«$title» будет удалён с этого устройства. Исходный готовый шаблон останется в библиотеке.';
  }

  @override
  String tplLocalDeleted(Object title) {
    return 'Локальный шаблон «$title» удалён.';
  }

  @override
  String get tplDeleteTitle => 'Удалить шаблон';

  @override
  String get tplRenameTitle => 'Название шаблона';

  @override
  String get tplFieldTitle => 'Название';

  @override
  String tplPreviewLabel(Object title) {
    return 'Предпросмотр: $title';
  }

  @override
  String tplCount(Object count) {
    return '$count шаблон(ов)';
  }

  @override
  String tplCloudLoadError(Object message) {
    return 'Не удалось загрузить облачные шаблоны: $message';
  }

  @override
  String get tplPublicBadge => 'Публичный шаблон';

  @override
  String get tplOrientationLandscape => 'Альбомная';

  @override
  String get tplOrientationPortrait => 'Книжная';

  @override
  String get tplPresetOffline => 'Готовый шаблон • доступен офлайн';

  @override
  String tplSchemaVersion(Object version) {
    return 'Схема v$version';
  }

  @override
  String get tplOpenAsTemplate => 'Открыть как шаблон';

  @override
  String get tplOpen => 'Открыть';

  @override
  String get tplUseInBatch => 'Использовать в массовой генерации';

  @override
  String get tplImportLocal => 'Импортировать локально';

  @override
  String get tplSaveToCloud => 'Сохранить в облако';

  @override
  String get tplDeleteLocal => 'Удалить локально';

  @override
  String get tplRename => 'Переименовать';

  @override
  String get tplMakePrivate => 'Сделать приватным';

  @override
  String get tplMakePublic => 'Сделать публичным';

  @override
  String get tplNoDate => 'Без даты';

  @override
  String get amSubtitle =>
      'Загрузите логотип, печать и подпись один раз, затем вставляйте в любой шаблон — сохраняются на устройстве и доступны офлайн.';

  @override
  String get amSearchHint => 'Поиск ресурсов…';

  @override
  String get amTypeLabel => 'Тип';

  @override
  String get amUploadTooltip => 'Загрузить новый ресурс';

  @override
  String get amUpload => 'Загрузить ресурс';

  @override
  String get amEmptyTitle => 'Ресурсов пока нет';

  @override
  String get amEmptyMessage =>
      'Загрузите логотип, подпись или печать организации, затем вставляйте в любой шаблон из панели свойств изображения.';

  @override
  String get amNoResultsMessage => 'Попробуйте другое имя или сбросьте фильтр.';

  @override
  String get amRenamed => 'Ресурс переименован.';

  @override
  String amMovedToType(Object type) {
    return 'Ресурс перемещён в «$type».';
  }

  @override
  String get amDeleteTitle => 'Удалить ресурс';

  @override
  String amConfirmDelete(Object name) {
    return '«$name» будет удалён с этого устройства. Шаблоны, использующие его, потеряют изображение (без сбоя печати).';
  }

  @override
  String amDeleted(Object name) {
    return 'Ресурс «$name» удалён.';
  }

  @override
  String get amRenameTitle => 'Переименовать ресурс';

  @override
  String amCount(Object count) {
    return '$count ресурс(ов)';
  }

  @override
  String amMakeType(Object type) {
    return 'Сделать тип: $type';
  }

  @override
  String get amCacheLabel => 'Кэш изображений на диске';

  @override
  String amCacheUsage(Object count, Object size) {
    return '$count файл(ов) · $size';
  }

  @override
  String amCacheUsageOf(Object count, Object used, Object limit) {
    return '$count файл(ов) · $used из $limit';
  }

  @override
  String get amCacheEmpty => 'Кэша на диске пока нет';

  @override
  String get amCacheClear => 'Очистить кэш';

  @override
  String get amCacheCleared => 'Кэш изображений на диске очищен.';

  @override
  String get commonRetry => 'Повторить';

  @override
  String get commonPrint => 'Печать';

  @override
  String get commonExportPdf => 'Экспорт PDF';

  @override
  String get commonExportFailed => 'Не удалось экспортировать PDF-файл.';

  @override
  String get commonPrintFailed => 'Не удалось отправить файл на печать.';

  @override
  String commonExportReady(Object name) {
    return 'Файл готов к сохранению как $name.';
  }

  @override
  String get commonGenerating => 'Генерация…';

  @override
  String get commonDataPanelTitle => 'Пример данных';

  @override
  String evElementCount(Object count) {
    return '$count элемент(ов)';
  }

  @override
  String get evStatusDynamicFields => ' • динамические поля';

  @override
  String get evStatusUnsaved => ' • несохранённые изменения';

  @override
  String get tevNewTemplateTitle => 'Новый шаблон';

  @override
  String get tevUnsavedTitle => 'Несохранённые изменения';

  @override
  String tevUnsavedMessage(Object title) {
    return 'У вас есть несохранённые изменения в «$title». Сохранить их перед выходом?';
  }

  @override
  String get tevLeaveWithoutSaving => 'Выйти без сохранения';

  @override
  String get tevSaveAndLeave => 'Сохранить и выйти';

  @override
  String get tevViewMode => 'Режим просмотра';

  @override
  String get tevModeEditor => 'Редактор';

  @override
  String get tevModePreview => 'Предпросмотр PDF';

  @override
  String get tevPaperDirection => 'Ориентация листа';

  @override
  String get tevWidthCm => 'Ширина (см)';

  @override
  String get tevHeightCm => 'Высота (см)';

  @override
  String get tevUndo => 'Отменить (Ctrl+Z)';

  @override
  String get tevRedo => 'Повторить (Ctrl+Y)';

  @override
  String get tevSnapGrid => 'Сетка привязки';

  @override
  String get tevGuidesOn => 'Умные направляющие: вкл. (отключить)';

  @override
  String get tevGuidesOff => 'Умные направляющие: выкл. (включить)';

  @override
  String get tevZoom => 'Масштаб';

  @override
  String get tevDocumentBackground => 'Фон документа';

  @override
  String get tevFrameFromLibrary => 'Рамка из моей библиотеки';

  @override
  String get tevChangeTitle => 'Изменить название шаблона';

  @override
  String get tevMyTemplates => 'Мои шаблоны';

  @override
  String get tevSaveAs => 'Сохранить как';

  @override
  String get tevSaveTemplate => 'Сохранить шаблон';

  @override
  String get tevSaveUnavailable => 'Сохранение недоступно';

  @override
  String get tevSaveNeedsSupabase =>
      'Для сохранения нужно подключение к проекту Supabase. Запустите приложение с ключами проекта (env.json).';

  @override
  String tevMissingAssets(Object list) {
    return 'Отсутствующие ресурсы: $list — выберите рамку/ресурс заново в «Моя библиотека».';
  }

  @override
  String get tevTemplateLibraryNeedsSupabase =>
      'Библиотека шаблонов требует подключения к проекту Supabase.';

  @override
  String tevOpenedTemplate(Object title) {
    return '«$title» открыт.';
  }

  @override
  String get tevTitleHint =>
      'напр. сертификат об окончании курса управления проектами';

  @override
  String get tevContinue => 'Продолжить';

  @override
  String get tevSavedTemplates => 'Мои сохранённые шаблоны';

  @override
  String get tevNoSavedTemplates =>
      'Сохранённых шаблонов пока нет. Сохраните через кнопку «Сохранить шаблон».';

  @override
  String get ecIncrease => 'Увеличить';

  @override
  String get ecDecrease => 'Уменьшить';

  @override
  String get ecQuickPalette => 'Быстрая палитра';

  @override
  String get ecFullPicker => 'Полный выбор цвета';

  @override
  String get ecRemoveColor => 'Убрать цвет';

  @override
  String get ecNone => 'Нет';

  @override
  String get ecPickColorTitle => 'Выбрать цвет';

  @override
  String get ecApply => 'Применить';

  @override
  String tevBackgroundAdded(Object name) {
    return '«$name» добавлен как фон документа.';
  }

  @override
  String get cfpUploadTooltip => 'Загрузить свой шрифт (.ttf / .otf)';

  @override
  String get cfpManageTooltip => 'Управление загруженными шрифтами';

  @override
  String get cfpNotice =>
      'Загруженные шрифты хранятся только на устройстве и сразу используются здесь и при печати — без интернета.';

  @override
  String get cfpMyFonts => 'Мои шрифты';

  @override
  String get cfpNoFonts => 'Шрифты ещё не загружены';

  @override
  String get cfpBuiltinOption => 'Нет (встроенный шрифт)';

  @override
  String get cfpGroupBuiltin => 'Встроенные шрифты';

  @override
  String get cfpGroupUploaded => 'Мои загруженные шрифты';

  @override
  String get cfpGroupSystem => 'Системные шрифты';

  @override
  String get cfpSearchHint => 'Поиск шрифтов…';

  @override
  String get cfpNoMatch => 'Нет подходящих шрифтов.';

  @override
  String get cfpPickTitle => 'Выберите файл шрифта (TTF или OTF)';

  @override
  String cfpPickerError(Object error) {
    return 'Не удалось открыть выбор файлов: $error';
  }

  @override
  String cfpReadError(Object name, Object error) {
    return 'Не удалось прочитать \"$name\": $error';
  }

  @override
  String get cfpFontAdded => 'Шрифт добавлен и сразу применён.';

  @override
  String cfpFontsAdded(Object count) {
    return 'Добавлено шрифтов: $count.';
  }

  @override
  String get cfpLibraryTitle => 'Моя библиотека шрифтов';

  @override
  String get cfpLibraryNotice =>
      'Все шрифты хранятся только на устройстве. Внимание: удаление используемого шаблоном шрифта вернёт шаблон к встроенному шрифту, а не приведёт к ошибке.';

  @override
  String get cfpEmpty => 'Загруженных шрифтов пока нет.';

  @override
  String get cfpCoverageFull => 'Полное покрытие арабского';

  @override
  String get cfpCoveragePartial => 'Частичное покрытие арабского';

  @override
  String get cfpUploadNew => 'Загрузить новый шрифт';

  @override
  String get ptpPrepError =>
      'Не удалось подготовить предпросмотр. Проверьте файл шаблона.';

  @override
  String ptpElapsedSize(Object ms, Object kb) {
    return '$ms мс — $kb КБ';
  }

  @override
  String get ptpGeneratingNote => '— предпросмотр обновляется автоматически';

  @override
  String get ptpGenerateFailedTitle => 'Не удалось создать предпросмотр';

  @override
  String get ptpPreparingTitle => 'Подготовка движка…';

  @override
  String get ptpPreparingMessage =>
      'Загружаются встроенные шрифты и создаётся первая версия файла.';

  @override
  String get ptpShowFailedTitle => 'Не удалось показать предпросмотр';

  @override
  String cfgOverride(Object override) {
    return 'Сборка с явными значениями переопределяет файл: $override';
  }

  @override
  String get tevBackgroundTitle => 'Фон документа из моей библиотеки';

  @override
  String get tevAddElement => 'Добавить элемент';

  @override
  String get commonUndo => 'Отменить';

  @override
  String get bpTitle => 'Массовая генерация из Excel';

  @override
  String get bpSubtitle =>
      'Импортируйте файл .xlsx или .csv, сопоставьте столбцы с полями шаблона и создайте PDF со страницей на запись — всё на устройстве, офлайн.';

  @override
  String get bpStepTemplate => '1) Шаблон';

  @override
  String get bpLoadingSampleTemplate => 'Загрузка шаблона-образца…';

  @override
  String bpTemplateInfo(Object name) {
    return 'Шаблон: $name • обязательные поля:';
  }

  @override
  String get bpLoadingTemplates => 'Загрузка ваших шаблонов…';

  @override
  String get bpNoTemplates =>
      'Сохранённых шаблонов пока нет — создайте в редакторе или импортируйте из библиотеки.';

  @override
  String get bpTemplateFromMine => 'Шаблон из моих шаблонов';

  @override
  String get bpSampleTemplatesHeader => '— шаблоны-образцы —';

  @override
  String bpTemplateEntry(Object title, Object source) {
    return '$title  •  $source';
  }

  @override
  String get bpSourceCloud => 'Облако';

  @override
  String get bpSourceLocal => 'Локальный';

  @override
  String get bpStepDataFile => '2) Файл данных';

  @override
  String get bpReadingFile => 'Чтение файла…';

  @override
  String get bpNoFileChosen => 'Файл ещё не выбран — поддерживаемые форматы:';

  @override
  String bpFileSummary(Object name, Object rows, Object cols) {
    return '$name — $rows строк, $cols столбцов';
  }

  @override
  String bpSheetSuffix(Object name) {
    return ' (лист: $name)';
  }

  @override
  String get bpChooseFile => 'Выбрать файл';

  @override
  String get bpRemove => 'Убрать';

  @override
  String get bpHeaderRow => 'Строка заголовков';

  @override
  String bpAutoRow(Object n) {
    return 'Автоматически (строка $n)';
  }

  @override
  String bpRow(Object n) {
    return 'Строка $n';
  }

  @override
  String bpAutoRowLong(Object n) {
    return 'Автоматически — строка $n';
  }

  @override
  String bpRowPreview(Object n, Object preview) {
    return 'Строка $n: $preview';
  }

  @override
  String get bpEmptyRow => '(пустая строка)';

  @override
  String get bpWorksheet => 'Лист';

  @override
  String get bpPickDataFile => 'Выберите файл данных (Excel или CSV)';

  @override
  String bpReadFileError(Object error) {
    return 'Не удалось прочитать файл: $error';
  }

  @override
  String bpFileReadRows(Object rows, Object cols) {
    return 'Файл прочитан локально: $rows строк и $cols столбцов.';
  }

  @override
  String bpSaveError(Object error) {
    return 'Не удалось сохранить изменение в шаблоне: $error';
  }

  @override
  String get bpMapFieldTitle => 'Назначить динамическое поле этому элементу';

  @override
  String get bpMapFieldBody =>
      'Заменится только текст этого элемента; другие элементы не затрагиваются.';

  @override
  String get bpUndoConvert => 'Преобразование отменено.';

  @override
  String get bpUndoConvertSaved =>
      'Преобразование отменено, текст восстановлен в шаблоне.';

  @override
  String bpRestoreError(Object error) {
    return 'Не удалось восстановить текст в шаблоне: $error';
  }

  @override
  String bpGeneratedReport(Object count) {
    return 'Создано записей: $count';
  }

  @override
  String bpSkippedSuffix(Object count) {
    return ' и пропущено $count';
  }

  @override
  String get bpReadyToSave => 'Файл готов к сохранению.';

  @override
  String get bpStepMapping => '3) Сопоставить столбцы с полями';

  @override
  String get bpChooseFileFirst =>
      'Сначала выберите файл, чтобы показать таблицу сопоставления.';

  @override
  String get bpNoDynamicFields => 'В текущем шаблоне нет динамических полей.';

  @override
  String bpMappedCount(Object mapped, Object total) {
    return 'Сопоставлено $mapped из $total столбцов';
  }

  @override
  String get bpAutoMapHint =>
      'После выбора файла предлагается умное автосопоставление; каждый столбец можно изменить.';

  @override
  String get bpNoFieldsHelp =>
      'В выбранном шаблоне нет динамических полей, поэтому сопоставлять нечего. Откройте шаблон в редакторе, вставьте «динамическое поле» в слот имени, сохраните и повторите.';

  @override
  String get bpAutoMap => 'Автосопоставление';

  @override
  String get bpClearMapping => 'Очистить сопоставление';

  @override
  String get bpNameFieldWarning =>
      'В этом шаблоне нет динамического поля имени — не сопоставляйте столбец имени с полем даты или номера, иначе имя может напечататься не там. Выберите ключ имени из списка столбца или преобразуйте фиксированный текст имени в редакторе в динамическое поле.';

  @override
  String bpStaticNameHints(Object preview) {
    return 'Фиксированный текст, похожий на имя: «$preview» — ни одно динамическое поле его не заменяет.';
  }

  @override
  String get bpConvertToNameField => 'Преобразовать в поле имени участника';

  @override
  String bpDuplicateField(Object field) {
    return 'Поле «$field» сопоставлено нескольким столбцам. Сопоставьте каждое поле одному столбцу.';
  }

  @override
  String bpUnmappedColumns(Object count) {
    return '$count столбцов без сопоставления — их данные не будут использованы.';
  }

  @override
  String bpColumn(Object n) {
    return 'Столбец $n';
  }

  @override
  String get bpEmptyCell => '(пусто)';

  @override
  String get bpUnmapped => '— не сопоставлено —';

  @override
  String get bpStepMissing => '4) Пустые ячейки и недостающие данные';

  @override
  String get bpNoNotes => 'Нет замечаний до выбора файла.';

  @override
  String get bpStepGenerate => '5) Генерация';

  @override
  String bpGenerating(Object progress) {
    return 'Генерация… $progress';
  }

  @override
  String get bpGenerateHint => 'Один PDF-файл, страница на каждую запись.';

  @override
  String get bpGeneratePickFile =>
      'Сначала выберите файл данных, чтобы включить генерацию.';

  @override
  String get bpMappingInvalid =>
      'Сопоставление неверно — одно поле сопоставлено двум столбцам.';

  @override
  String get bpMapAtLeastOne =>
      'Сопоставьте хотя бы один столбец с полем шаблона, чтобы включить генерацию.';

  @override
  String get bpGenerateCertificates => 'Создать сертификаты';

  @override
  String get bpRegenerate => 'Перегенерировать';

  @override
  String get bpStatGenerated => 'Создано';

  @override
  String get bpStatSkipped => 'Пропущено';

  @override
  String get bpStatPages => 'Страницы';

  @override
  String get bpStatSize => 'Размер';

  @override
  String bpKilobytes(Object value) {
    return '$value КБ';
  }

  @override
  String get bpStatTime => 'Время';

  @override
  String bpMilliseconds(Object value) {
    return '$value мс';
  }

  @override
  String bpCompletion(Object pct, Object total) {
    return 'Завершено $pct% из $total строк.';
  }

  @override
  String get bpSkippedRows => 'Строки без генерации:';

  @override
  String bpRowSkipReason(Object n, Object reason) {
    return 'Строка $n: $reason';
  }

  @override
  String get bpPreviewHere => 'Предпросмотр появится здесь';

  @override
  String get bpPreviewHint =>
      'Выберите файл данных, настройте сопоставление и нажмите «Создать сертификаты» — первая страница появится здесь.';

  @override
  String get bpAssignByTapTitle => 'Назначайте поля касанием';

  @override
  String get bpAssignByTapBody =>
      'Нажмите любой текст в шаблоне, чтобы назначить его динамическому полю. Другие элементы не затрагиваются — ни дата, ни имя руководителя, ни фиксированный текст.';

  @override
  String get bpNoTexts => 'В этом шаблоне нет текстов.';

  @override
  String get bpEmptyText => '(пустой текст)';

  @override
  String get bpDynamicFieldTap => 'Динамическое поле — нажмите, чтобы изменить';

  @override
  String get bpStaticTextTap =>
      'Фиксированный текст — нажмите, чтобы назначить';

  @override
  String get bpAssignField => 'Назначить поле';

  @override
  String get bpKindCertificate => 'Сертификат';

  @override
  String get bpKindContract => 'Договор';

  @override
  String bpLoadSampleError(Object error) {
    return 'Не удалось загрузить шаблон-образец: $error';
  }

  @override
  String bpReadSheetError(Object error) {
    return 'Не удалось прочитать лист: $error';
  }

  @override
  String bpUpdateHeaderRowError(Object error) {
    return 'Не удалось обновить строку заголовков: $error';
  }

  @override
  String get bpChooseTemplateFirst =>
      'Выберите шаблон (сертификат или договор) перед генерацией.';

  @override
  String bpBatchTitle(Object kind) {
    return '$kind массово — JoodCraft';
  }

  @override
  String bpGenerateError(Object error) {
    return 'Не удалось выполнить массовую генерацию: $error';
  }

  @override
  String get bpWarnNoDynamicFields =>
      'В этом шаблоне нет динамических полей — данные не будут меняться между записями. Добавьте поле «имя участника» из панели редактора и сохраните шаблон.';

  @override
  String get bpWarnNoNameField =>
      'В этом шаблоне нет динамического поля имени — столбец имени может сопоставиться с полем даты или номера, и имя напечатается не там. Преобразуйте фиксированный текст в поле или измените шаблон.';

  @override
  String bpAssignedTemp(Object token) {
    return 'Этот элемент назначен $token для текущей генерации — остальные элементы не затронуты. Сохраните шаблон, чтобы закрепить изменение.';
  }

  @override
  String bpAssignedSaved(Object token) {
    return 'Этот элемент назначен $token, изменение сохранено в шаблоне. Остальные элементы не затронуты.';
  }

  @override
  String get commonShow => 'Показать';

  @override
  String get commonHide => 'Скрыть';

  @override
  String get themeSwitchToLight => 'Переключить на светлую тему';

  @override
  String get themeSwitchToDark => 'Переключить на тёмную тему';

  @override
  String commonComingSoonPhase(Object phase) {
    return 'В процессе — этап $phase';
  }

  @override
  String get cbNewCertificateTitle => 'Новый сертификат';

  @override
  String get cbNewContractTitle => 'Новый договор';

  @override
  String get cbBeneficiaryDataTitle => 'Данные получателя (образец)';

  @override
  String get cbContractDataTitle => 'Данные договора (образец)';
}
