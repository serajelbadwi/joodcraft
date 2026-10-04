// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTagline => '离线生成官方证书和合同';

  @override
  String get navDashboard => '仪表板';

  @override
  String get navCertificates => '证书设计器';

  @override
  String get navContracts => '合同设计器';

  @override
  String get navBatch => '批量生成';

  @override
  String get navTemplates => '模板库';

  @override
  String get navAssets => '资源与签名';

  @override
  String get actionSignOut => '退出登录';

  @override
  String get actionBackToDashboard => '返回仪表板';

  @override
  String get offlineProcessingLabel => '本地处理';

  @override
  String get themeTooltip => '切换主题';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get languageTooltip => '更改语言';

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
  String get configMissingKeysTitle => '未找到连接密钥';

  @override
  String get configMissingKeysBody =>
      '启动时，应用会依次在三个来源中查找密钥：--dart-define 标志、磁盘上的 env.json 文件（根目录或 assets/env/），以及应用内置的副本——但均未找到。请创建该文件并填写一次，然后无需任何标志即可运行：';

  @override
  String get configEnvNote =>
      '构建包将 assets/env/ 声明为资源，因此缺少文件不会导致干净构建失败。请从 env.example.json 创建，或运行：dart run tool/ensure_env.dart — 仅需 anon/public 密钥；service_role 绝不会在应用中使用。';

  @override
  String get routeNotFoundTitle => '页面未找到';

  @override
  String get routeNotFoundBody => '应用未定义所请求的路由：';

  @override
  String get editorPrecisionTitle => '精确控制';

  @override
  String get editorNudgeStep => '微移步长';

  @override
  String get editorNudgeStepHint => '画布上的箭头也按 Shift = 10px 微移。';

  @override
  String get editorNudgeUp => '上移';

  @override
  String get editorNudgeLeft => '左移';

  @override
  String get editorNudgeDown => '下移';

  @override
  String get editorNudgeRight => '右移';

  @override
  String get editorScale => '缩放';

  @override
  String get editorScaleHint => '围绕元素中心相对缩放（在按钮上滚动可获得更细的步长）。';

  @override
  String get editorScaleUp => '放大';

  @override
  String get editorScaleDown => '缩小';

  @override
  String get editorDecorTitle => '矢量装饰';

  @override
  String get editorDecorKind => '装饰类型';

  @override
  String get editorDecorPalette => '配色';

  @override
  String get editorDecorLayers => '层数';

  @override
  String get editorDecorSeed => '随机种子';

  @override
  String get editorDecorThickness => '粗细';

  @override
  String get editorDecorPrimary => '主色';

  @override
  String get editorDecorSecondary => '辅色';

  @override
  String get editorDecorAccent => '点缀色';

  @override
  String get editorDecorGradient => '层渐变';

  @override
  String get editorDecorGallery => '预设图库';

  @override
  String get editorDecorGalleryTitle => '现成装饰图库';

  @override
  String get editorClose => '关闭';

  @override
  String get editorDecorPaletteCustom => '自定义';

  @override
  String get decorKindModernWave => '现代波浪';

  @override
  String get decorKindPaperCut => '多层剪纸';

  @override
  String get decorKindClassicCorner => '经典花纹边框';

  @override
  String get decorKindGuilloche => '纽索纹';

  @override
  String get decorKindRibbonBanner => '绶带';

  @override
  String get decorPaletteRoyalGold => '皇家金';

  @override
  String get decorPaletteRoyalBlue => '皇家蓝';

  @override
  String get decorPaletteEmerald => '祖母绿';

  @override
  String get decorPaletteBurgundy => '酒红';

  @override
  String get decorPaletteMidnight => '午夜蓝';

  @override
  String get decorPaletteMono => '单色灰';

  @override
  String get editorSignatureTitle => '签名区';

  @override
  String get editorSignatureCount => '签名数量';

  @override
  String get signatureCountOne => '一个签名';

  @override
  String get signatureCountTwo => '两个签名';

  @override
  String get signatureCountThree => '三个签名';

  @override
  String get editorSignatureOrder => '签名顺序';

  @override
  String get editorSignatureOrderHint => '阿拉伯文稿中第一个签名位于最右侧。';

  @override
  String get editorSignatureFirstRight => '第一个在右';

  @override
  String get editorSignatureFirstLeft => '第一个在左';

  @override
  String get editorDirectionAuto => '自动';

  @override
  String get editorSignatureImageAlign => '图像对齐';

  @override
  String get editorAlignStart => '起始';

  @override
  String get editorAlignCenter => '居中';

  @override
  String get editorAlignEnd => '末尾';

  @override
  String get editorSignatureDivider => '签名线';

  @override
  String get editorVisible => '显示';

  @override
  String get editorHidden => '隐藏';

  @override
  String get editorSignatureNameSize => '姓名大小';

  @override
  String get editorSignatureRoleSize => '职务大小';

  @override
  String get editorSignatureSpacing => '间距';

  @override
  String get editorSignatureImageSize => '图像大小';

  @override
  String get editorSignatureNameColor => '姓名颜色';

  @override
  String get editorSignatureRoleColor => '职务颜色';

  @override
  String get editorFont => '字体';

  @override
  String get editorImageSource => '图像来源';

  @override
  String get imageSourceAppAssets => '应用内置资源';

  @override
  String get imageSourceMyLibrary => '我的素材库';

  @override
  String get imageSourceLocalFile => '本地文件';

  @override
  String get imageSourceEmbedded => '内嵌数据';

  @override
  String get editorSignatureChangeImage => '更换签名图片';

  @override
  String get editorSignatureAddImage => '添加签名图片';

  @override
  String get editorSignatureRemoveImage => '移除签名图片';

  @override
  String get editorSignaturePickImageTitle => '从我的素材库中选择签名图片';

  @override
  String get editorSignatureSlot => '位置';

  @override
  String get editorSignatureRoleField => '职务（例如：总经理）';

  @override
  String get editorSignatureNameField => '签署人姓名（支持动态字段）';

  @override
  String get editorFromMyLibrary => '从我的素材库';

  @override
  String get paletteSignatureBlock => '签名';

  @override
  String get editorInsertFromLibraryTooltip => '直接插入已上传的边框或标志';

  @override
  String get unsupportedElementVersionNote => '此元素来自更新版本的编辑器——将按原样保留，无法在此编辑。';

  @override
  String editorSelectedCount(Object count) {
    return '已选 $count';
  }

  @override
  String get editorClearSelection => '取消选择';

  @override
  String get editorGroup => '分组';

  @override
  String get editorOpacity => '不透明度';

  @override
  String get editorBringToFront => '置于顶层';

  @override
  String get editorSendToBack => '置于底层';

  @override
  String get editorDuplicate => '复制';

  @override
  String get editorDeleteSelected => '删除所选';

  @override
  String get editorGroupDragHint =>
      '用鼠标拖动分组，用方向键微调（Shift = 10px），按住 Ctrl 单击可调整选择。';

  @override
  String get editorBringForward => '上移一层';

  @override
  String get editorDuplicateElement => '复制元素';

  @override
  String get editorDeleteElement => '删除元素';

  @override
  String get editorPageSettings => '页面设置';

  @override
  String get editorPageSize => '尺寸';

  @override
  String get editorUnit => '单位';

  @override
  String get editorWidth => '宽度';

  @override
  String get editorHeight => '高度';

  @override
  String get editorLabelText => '文本';

  @override
  String get editorLabelShape => '形状';

  @override
  String get editorLabelSeal => '印章';

  @override
  String get editorLabelDecoration => '矢量装饰';

  @override
  String get editorLabelSignature => '签名区';

  @override
  String get editorLabelImage => '图片/标志';

  @override
  String get editorLabelQr => '二维码';

  @override
  String get editorLabelUnknown => '不支持的元素';

  @override
  String get editorLabelDynamicField => '动态字段';

  @override
  String get editorPositionAndSize => '位置和大小';

  @override
  String get editorPosX => 'X';

  @override
  String get editorPosY => 'Y';

  @override
  String get editorRotation => '旋转';

  @override
  String get editorTextFormat => '文本格式';

  @override
  String get editorConvertToField => '转换为动态字段';

  @override
  String get editorFontWeight => '字重';

  @override
  String get editorWeightRegular => '常规';

  @override
  String get editorWeightSemiBold => '中等';

  @override
  String get editorWeightBold => '粗体';

  @override
  String get editorFontSize => '字号';

  @override
  String get editorLetterSpacing => '字距';

  @override
  String get editorLineHeight => '行高';

  @override
  String get editorTextColor => '文字颜色';

  @override
  String get editorTextBackground => '文字背景';

  @override
  String get editorTextAlign => '对齐';

  @override
  String get editorAlignJustify => '两端对齐';

  @override
  String get editorJustifyMode => '对齐方式';

  @override
  String get editorJustifyHint => '连字（Kashida）在 PDF 文件中应用（预览显示空格对齐）';

  @override
  String get editorJustifySpaces => '空格';

  @override
  String get editorJustifyKashida => '连字';

  @override
  String get editorVerticalAlign => '垂直对齐';

  @override
  String get editorVerticalTop => '顶部';

  @override
  String get editorVerticalBottom => '底部';

  @override
  String get editorDirection => '方向';

  @override
  String get editorDirectionHint => '切换快捷键：Ctrl+Shift+D';

  @override
  String get editorDirectionRtl => '阿拉伯语（RTL）';

  @override
  String get editorDirectionLtr => '拉丁语（LTR）';

  @override
  String get editorImage => '图片';

  @override
  String get editorSource => '来源';

  @override
  String get editorImageFit => '图片适配';

  @override
  String get editorFitContain => '包含';

  @override
  String get editorFitCover => '覆盖';

  @override
  String get editorFitFill => '拉伸';

  @override
  String get assetPickerEmptyHint => '您尚未上传任何资源。上传标志、签名或印章，即可在此处和打印时使用。';

  @override
  String get assetPickerNoneOption => '无（其他来源）';

  @override
  String get assetPickerTitle => '从我的素材库中选择图片';

  @override
  String assetUploadType(Object type) {
    return '上传$type';
  }

  @override
  String get editorSeal => '印章';

  @override
  String get editorSealColor => '印章颜色';

  @override
  String get editorSealRingColor => '圆环颜色';

  @override
  String get editorSealStarColor => '星形颜色';

  @override
  String get editorSealStarSize => '星形大小';

  @override
  String get editorShape => '形状';

  @override
  String get editorFillColor => '填充颜色';

  @override
  String get editorBorderColor => '边框颜色';

  @override
  String get editorBorderWidth => '边框宽度';

  @override
  String get editorCornerRadius => '圆角半径';

  @override
  String get editorQrVerify => '验证码';

  @override
  String get editorQrData => '编码数据';

  @override
  String get editorQrColor => '二维码颜色';

  @override
  String get editorQrBackground => '二维码背景';

  @override
  String editorConvertDialogMessage(Object text) {
    return '转换会将文本“$text”变为可在批量生成中绑定的动态标记。';
  }

  @override
  String get editorFieldKeyHint => '字段键（例如：姓名、日期、编号）';

  @override
  String get editorCustomKeyHint => '输入自定义键（不含括号——将自动添加）';

  @override
  String get editorCancel => '取消';

  @override
  String get editorConvert => '转换';

  @override
  String get editorPath => '路径';

  @override
  String get editorTextContent => '文本内容';

  @override
  String editorInsertFieldToken(Object token) {
    return '插入 $token';
  }

  @override
  String editorAddLabel(Object label) {
    return '添加 $label';
  }

  @override
  String assetInsertedSnack(Object name) {
    return '已将“$name”插入模板。';
  }

  @override
  String get paletteHeading => '标题';

  @override
  String get paletteFrame => '矩形/边框';

  @override
  String get paletteDivider => '分隔线';

  @override
  String get paletteLogo => '标志/签名';

  @override
  String get evSignatureEmptyLabel => '空签名';

  @override
  String get evSignatureEmptyDetail => '添加职务、姓名和签名图片';

  @override
  String get evSignatureMissingLabel => '缺少签名';

  @override
  String get evUploadToLibraryDetail => '将图片上传到素材库';

  @override
  String get evImageNotFoundLabel => '找不到图片';

  @override
  String get evNoFileLabel => '未选择文件';

  @override
  String get evChooseFromAssetsDetail => '从素材库中选择图片';

  @override
  String get evAssetMissingLabel => '缺少素材';

  @override
  String get evReselectAssetDetail => '从素材库重新选择边框/素材';

  @override
  String get evInvalidImageLabel => '无效图片';

  @override
  String get evRenderDataFailedDetail => '无法显示数据';

  @override
  String get evInvalidDataLabel => '无效数据';

  @override
  String get evDecodeFailedDetail => '无法解码图片';

  @override
  String get evEmptyQrLabel => '空编码';

  @override
  String get evEmptyQrDetail => '在属性栏中输入编码值';

  @override
  String evUnknownElementLabel(Object type) {
    return '不支持的元素：$type';
  }

  @override
  String get alpFilterAll => '全部';

  @override
  String get alpEmptyHint => '所需类型的已上传素材为空。请从“素材与签名”部分上传边框或标志，然后重试。';

  @override
  String alpNoFilteredAssets(Object type) {
    return '没有“$type”类型的素材。';
  }

  @override
  String get authWelcomeBack => '欢迎使用 JoodCraft。';

  @override
  String get authResetLinkSent => '重置链接已发送。请检查您的电子邮箱。';

  @override
  String get authLogin => '登录';

  @override
  String get authLoginSubtitle => '您的电子邮箱和密码，继续进入控制面板。';

  @override
  String get authNoAccount => '还没有账户？';

  @override
  String get authCreateAccountLink => '创建新账户';

  @override
  String get authConfirmEmailThenLogin => '您的账户已创建。请先确认电子邮箱，然后登录。';

  @override
  String get authEmail => '电子邮箱';

  @override
  String get authPassword => '密码';

  @override
  String get authForgotPassword => '忘记密码？';

  @override
  String get authEnterDashboard => '进入控制面板';

  @override
  String get authResetPassword => '重置密码';

  @override
  String get authResetPasswordHint => '输入您的电子邮箱，我们将向您发送密码重置链接。';

  @override
  String get authSendLink => '发送链接';

  @override
  String get authConfirmEmailMessage => '您的账户已创建。请查收邮件确认账户，然后登录。';

  @override
  String get authAccountCreatedWelcome => '您的账户已创建。欢迎使用 JoodCraft。';

  @override
  String get authCreateAccount => '创建账户';

  @override
  String get authRegisterSubtitle => '您的账户会保存模板和素材（标志、签名、印章），以便在所有项目中重复使用。';

  @override
  String get authHaveAccount => '已经有账户？';

  @override
  String get authFullName => '全名';

  @override
  String get authFullNameHint => '例如：阿卜杜拉·艾哈迈德';

  @override
  String get authName => '姓名';

  @override
  String get authOrgName => '机构名称（可选）';

  @override
  String get authOrgNameHint => '例如：Jood 慈善协会';

  @override
  String get authOrgHelper => '自动打印在证书和合同上。';

  @override
  String get authOrgNameShort => '机构名称';

  @override
  String get authPasswordHint => '至少 8 个字符';

  @override
  String authPasswordRule(Object min) {
    return '使用至少 $min 个字符，包含数字和符号。';
  }

  @override
  String get authConfirmPassword => '确认密码';

  @override
  String get authCreateAccountButton => '创建账户';

  @override
  String get authFeatureLocalExcel => 'Excel 文件全程本地处理——数据绝不离开设备';

  @override
  String get authFeaturePdf => '使用高质量阿拉伯字体生成 PDF，全面支持 RTL';

  @override
  String get authFeatureTemplates => '您的模板保存在账户中，随时可重复使用';

  @override
  String get authTagline => '您的正式证书和合同……放心打印。';

  @override
  String authVersion(Object name, Object version) {
    return '$name • 版本 $version';
  }

  @override
  String get dashModules => '平台模块';

  @override
  String dashWelcome(Object name) {
    return '欢迎，$name';
  }

  @override
  String dashSubscription(Object tier) {
    return '订阅：$tier';
  }

  @override
  String dashOrg(Object name) {
    return '机构：$name';
  }

  @override
  String get dashOrgMissing => '您尚未设置机构名称——它将自动打印在证书和合同上。';

  @override
  String get dashOpenModule => '打开模块';

  @override
  String get dashRoadmapSupabase => '搭建 Supabase 数据库（表 + RLS + 触发器）';

  @override
  String get dashRoadmapModular => '可扩展的模块化 Feature-First 架构';

  @override
  String get dashRoadmapTheme => '品牌视觉主题，使用 Cairo 字体并支持 RTL';

  @override
  String get dashRoadmapAuth => '身份验证：登录、创建账户和重置密码';

  @override
  String get dashPhaseOneDone => '第一阶段已完成';

  @override
  String get dashNextPhase => '接下来：离线 PDF 引擎和阿拉伯字体，然后是可视化模板编辑器。';

  @override
  String get destDashboard => '控制面板';

  @override
  String get destDashboardDesc => '项目和模板概览。';

  @override
  String get destCertificates => '证书引擎';

  @override
  String get destCertificatesDesc => '从可编辑模板设计横向证书。';

  @override
  String get destContracts => '合同引擎';

  @override
  String get destContractsDesc => '使用动态字段起草纵向合同。';

  @override
  String get destBatch => '批量生成';

  @override
  String get destBatchDesc => '在本地读取 Excel 文件，一次生成数百份证书。';

  @override
  String get destTemplates => '模板库';

  @override
  String get destTemplatesDesc => '管理、分类并重复使用已保存的模板。';

  @override
  String get destAssets => '素材与签名';

  @override
  String get destAssetsDesc => '您的标志、印章、签名和边框。';

  @override
  String get dashUser => '用户';

  @override
  String get dashLogoutSuccess => '您已成功退出登录。';

  @override
  String get dashLogoutError => '无法退出登录。请重试。';

  @override
  String get commonSave => '保存';

  @override
  String get commonPreview => '预览';

  @override
  String get commonOptions => '选项';

  @override
  String get tplDelete => '删除';

  @override
  String get tplSortRecentlyUpdated => '最近修改';

  @override
  String get tplSortTitleAsc => '名称（A–Z）';

  @override
  String get tplSortLabel => '排序';

  @override
  String get tplSubtitle => '专业现成模板 + 您保存的模板——搜索、筛选、打开和导入，完全离线。';

  @override
  String get tplRefreshTooltip => '刷新列表';

  @override
  String get tplSearchHint => '搜索模板……';

  @override
  String get tplNoResultsTitle => '无匹配结果';

  @override
  String get tplNoResultsMessage => '尝试其他搜索词或重置筛选条件。';

  @override
  String tplAddedToLocal(Object title) {
    return '已将“$title”添加到您的本地模板。';
  }

  @override
  String get tplCloudRequiresConnection => '将模板保存到云端需要连接 Supabase 项目。请改为保存在本地。';

  @override
  String tplSavedToCloud(Object title) {
    return '已将“$title”保存到云端。';
  }

  @override
  String get tplRenamed => '模板已重命名。';

  @override
  String tplCopySuffix(Object title) {
    return '$title（副本）';
  }

  @override
  String tplCopyCreated(Object title) {
    return '已创建“$title”的副本。';
  }

  @override
  String get tplNowPrivate => '模板现在为私有。';

  @override
  String get tplNowPublic => '模板现在为公开（他人只读）。';

  @override
  String tplConfirmCloudDelete(Object title) {
    return '将从云端永久删除“$title”。此操作不可撤销。';
  }

  @override
  String tplCloudDeleted(Object title) {
    return '模板“$title”已删除。';
  }

  @override
  String tplConfirmLocalDelete(Object title) {
    return '将从本设备删除“$title”。原始现成模板仍可在模板库中使用。';
  }

  @override
  String tplLocalDeleted(Object title) {
    return '本地模板“$title”已删除。';
  }

  @override
  String get tplDeleteTitle => '删除模板';

  @override
  String get tplRenameTitle => '模板标题';

  @override
  String get tplFieldTitle => '标题';

  @override
  String tplPreviewLabel(Object title) {
    return '预览：$title';
  }

  @override
  String tplCount(Object count) {
    return '$count 个模板';
  }

  @override
  String tplCloudLoadError(Object message) {
    return '无法加载云端模板：$message';
  }

  @override
  String get tplPublicBadge => '公开模板';

  @override
  String get tplOrientationLandscape => '横向';

  @override
  String get tplOrientationPortrait => '纵向';

  @override
  String get tplPresetOffline => '现成模板 • 可离线使用';

  @override
  String tplSchemaVersion(Object version) {
    return '架构 v$version';
  }

  @override
  String get tplOpenAsTemplate => '作为模板打开';

  @override
  String get tplOpen => '打开';

  @override
  String get tplUseInBatch => '用于批量生成';

  @override
  String get tplImportLocal => '本地导入';

  @override
  String get tplSaveToCloud => '保存到云端';

  @override
  String get tplDeleteLocal => '本地删除';

  @override
  String get tplRename => '重命名';

  @override
  String get tplMakePrivate => '设为私有';

  @override
  String get tplMakePublic => '设为公开';

  @override
  String get tplNoDate => '无日期';

  @override
  String get amSubtitle => '一次上传标志、印章和签名，然后插入到任意模板——保存在设备上并离线复用。';

  @override
  String get amSearchHint => '搜索素材……';

  @override
  String get amTypeLabel => '类型';

  @override
  String get amUploadTooltip => '上传新素材';

  @override
  String get amUpload => '上传素材';

  @override
  String get amEmptyTitle => '还没有素材';

  @override
  String get amEmptyMessage => '上传您机构的标志、签名或印章，然后从图片属性栏插入任意模板。';

  @override
  String get amNoResultsMessage => '尝试其他名称或重置筛选条件。';

  @override
  String get amRenamed => '素材已重命名。';

  @override
  String amMovedToType(Object type) {
    return '素材已移至“$type”。';
  }

  @override
  String get amDeleteTitle => '删除素材';

  @override
  String amConfirmDelete(Object name) {
    return '将从本设备删除“$name”。使用它的模板将丢失图片（不会导致打印失败）。';
  }

  @override
  String amDeleted(Object name) {
    return '素材“$name”已删除。';
  }

  @override
  String get amRenameTitle => '重命名素材';

  @override
  String amCount(Object count) {
    return '$count 个素材';
  }

  @override
  String amMakeType(Object type) {
    return '设为类型：$type';
  }

  @override
  String get commonRetry => '重试';

  @override
  String get commonPrint => '打印';

  @override
  String get commonExportPdf => '导出 PDF';

  @override
  String get commonExportFailed => '无法导出 PDF 文件。';

  @override
  String get commonPrintFailed => '无法将文件发送到打印机。';

  @override
  String commonExportReady(Object name) {
    return '文件已准备好另存为 $name。';
  }

  @override
  String get commonGenerating => '正在生成……';

  @override
  String get commonDataPanelTitle => '示例数据';

  @override
  String evElementCount(Object count) {
    return '$count 个元素';
  }

  @override
  String get evStatusDynamicFields => ' • 动态字段';

  @override
  String get evStatusUnsaved => ' • 未保存的更改';

  @override
  String get tevNewTemplateTitle => '新模板';

  @override
  String get tevUnsavedTitle => '未保存的更改';

  @override
  String tevUnsavedMessage(Object title) {
    return '您对“$title”有未保存的更改。要在离开前保存吗？';
  }

  @override
  String get tevLeaveWithoutSaving => '不保存离开';

  @override
  String get tevSaveAndLeave => '保存并离开';

  @override
  String get tevViewMode => '视图模式';

  @override
  String get tevModeEditor => '编辑器';

  @override
  String get tevModePreview => 'PDF 预览';

  @override
  String get tevPaperDirection => '纸张方向';

  @override
  String get tevWidthCm => '宽度 (cm)';

  @override
  String get tevHeightCm => '高度 (cm)';

  @override
  String get tevUndo => '撤销 (Ctrl+Z)';

  @override
  String get tevRedo => '重做 (Ctrl+Y)';

  @override
  String get tevSnapGrid => '吸附网格';

  @override
  String get tevGuidesOn => '智能参考线：开启（关闭）';

  @override
  String get tevGuidesOff => '智能参考线：关闭（开启）';

  @override
  String get tevZoom => '缩放';

  @override
  String get tevDocumentBackground => '文档背景';

  @override
  String get tevFrameFromLibrary => '来自我的素材库的边框';

  @override
  String get tevChangeTitle => '更改模板标题';

  @override
  String get tevMyTemplates => '我的模板';

  @override
  String get tevSaveAs => '另存为';

  @override
  String get tevSaveTemplate => '保存模板';

  @override
  String get tevSaveUnavailable => '保存不可用';

  @override
  String get tevSaveNeedsSupabase =>
      '保存需要连接 Supabase 项目。请使用项目密钥（env.json）运行应用以保存模板。';

  @override
  String tevMissingAssets(Object list) {
    return '缺少素材：$list——请从“我的素材库”重新选择边框/素材，以免空白。';
  }

  @override
  String get tevTemplateLibraryNeedsSupabase => '模板库需要连接 Supabase 项目。';

  @override
  String tevOpenedTemplate(Object title) {
    return '已打开“$title”。';
  }

  @override
  String get tevTitleHint => '例如：项目管理课程结业证书';

  @override
  String get tevContinue => '继续';

  @override
  String get tevSavedTemplates => '我保存的模板';

  @override
  String get tevNoSavedTemplates => '还没有已保存的模板。请通过“保存模板”按钮保存。';

  @override
  String get ecIncrease => '增加';

  @override
  String get ecDecrease => '减少';

  @override
  String get ecQuickPalette => '快捷调色板';

  @override
  String get ecFullPicker => '完整取色器';

  @override
  String get ecRemoveColor => '移除颜色';

  @override
  String get ecNone => '无';

  @override
  String get ecPickColorTitle => '选择颜色';

  @override
  String get ecApply => '应用';

  @override
  String tevBackgroundAdded(Object name) {
    return '已将“$name”添加为文档背景。';
  }

  @override
  String get cfpUploadTooltip => '上传自定义字体（.ttf / .otf）';

  @override
  String get cfpManageTooltip => '管理已上传字体';

  @override
  String get cfpNotice => '上传的字体仅保存在您的设备上，并立即在此处和打印中使用——无需联网。';

  @override
  String get cfpMyFonts => '我的自定义字体';

  @override
  String get cfpNoFonts => '尚未上传字体';

  @override
  String get cfpBuiltinOption => '无（内置字体）';

  @override
  String get cfpPickTitle => '选择字体文件（TTF 或 OTF）';

  @override
  String cfpPickerError(Object error) {
    return '无法打开文件选择器：$error';
  }

  @override
  String cfpReadError(Object name, Object error) {
    return '无法读取“$name”：$error';
  }

  @override
  String get cfpFontAdded => '字体已添加并立即应用。';

  @override
  String cfpFontsAdded(Object count) {
    return '已添加 $count 个字体。';
  }

  @override
  String get cfpLibraryTitle => '我的自定义字体库';

  @override
  String get cfpLibraryNotice =>
      '所有字体仅保存在您的设备上。警告：删除模板使用的字体会使该模板回退到内置字体，而不会失败。';

  @override
  String get cfpEmpty => '还没有上传的字体。';

  @override
  String get cfpCoverageFull => '完整阿拉伯语覆盖';

  @override
  String get cfpCoveragePartial => '部分阿拉伯语覆盖';

  @override
  String get cfpUploadNew => '上传新字体';

  @override
  String get ptpPrepError => '无法准备预览。请检查模板文件。';

  @override
  String ptpElapsedSize(Object ms, Object kb) {
    return '$ms 毫秒 — $kb KB';
  }

  @override
  String get ptpGeneratingNote => '— 预览会自动更新';

  @override
  String get ptpGenerateFailedTitle => '无法生成预览';

  @override
  String get ptpPreparingTitle => '正在准备引擎……';

  @override
  String get ptpPreparingMessage => '正在加载内置字体并生成文件的第一版。';

  @override
  String get ptpShowFailedTitle => '无法显示预览';

  @override
  String cfgOverride(Object override) {
    return '使用显式值的替代构建会覆盖该文件：$override';
  }

  @override
  String get tevBackgroundTitle => '来自我的素材库的文档背景';

  @override
  String get tevAddElement => '添加元素';

  @override
  String get commonUndo => '撤销';

  @override
  String get bpTitle => '从 Excel 批量生成';

  @override
  String get bpSubtitle =>
      '导入 .xlsx 或 .csv 文件，将其列映射到模板字段，然后生成每条记录一页的 PDF——全程在您的设备上离线完成。';

  @override
  String get bpStepTemplate => '1) 模板';

  @override
  String get bpLoadingSampleTemplate => '正在加载示例模板……';

  @override
  String bpTemplateInfo(Object name) {
    return '模板：$name • 必填字段：';
  }

  @override
  String get bpLoadingTemplates => '正在加载您的模板……';

  @override
  String get bpNoTemplates => '还没有已保存的模板——请在编辑器中创建或从模板库导入。';

  @override
  String get bpTemplateFromMine => '来自我的模板';

  @override
  String get bpSampleTemplatesHeader => '— 示例模板 —';

  @override
  String bpTemplateEntry(Object title, Object source) {
    return '$title  •  $source';
  }

  @override
  String get bpSourceCloud => '云端';

  @override
  String get bpSourceLocal => '本地';

  @override
  String get bpStepDataFile => '2) 数据文件';

  @override
  String get bpReadingFile => '正在读取文件……';

  @override
  String get bpNoFileChosen => '尚未选择文件——支持的格式：';

  @override
  String bpFileSummary(Object name, Object rows, Object cols) {
    return '$name — $rows 行，$cols 列';
  }

  @override
  String bpSheetSuffix(Object name) {
    return '（工作表：$name）';
  }

  @override
  String get bpChooseFile => '选择文件';

  @override
  String get bpRemove => '移除';

  @override
  String get bpHeaderRow => '标题行';

  @override
  String bpAutoRow(Object n) {
    return '自动（第 $n 行）';
  }

  @override
  String bpRow(Object n) {
    return '第 $n 行';
  }

  @override
  String bpAutoRowLong(Object n) {
    return '自动——第 $n 行';
  }

  @override
  String bpRowPreview(Object n, Object preview) {
    return '第 $n 行：$preview';
  }

  @override
  String get bpEmptyRow => '（空行）';

  @override
  String get bpWorksheet => '工作表';

  @override
  String get bpPickDataFile => '选择数据文件（Excel 或 CSV）';

  @override
  String bpReadFileError(Object error) {
    return '无法读取文件：$error';
  }

  @override
  String bpFileReadRows(Object rows, Object cols) {
    return '文件已在本地读取：$rows 行，$cols 列。';
  }

  @override
  String bpSaveError(Object error) {
    return '无法将更改保存到模板：$error';
  }

  @override
  String get bpMapFieldTitle => '为此元素指定动态字段';

  @override
  String get bpMapFieldBody => '只有此元素的文本会被替换为字段，其他元素不受影响。';

  @override
  String get bpUndoConvert => '已撤销转换。';

  @override
  String get bpUndoConvertSaved => '已撤销转换并在模板中恢复文本。';

  @override
  String bpRestoreError(Object error) {
    return '无法在模板中恢复文本：$error';
  }

  @override
  String bpGeneratedReport(Object count) {
    return '已生成 $count 条记录';
  }

  @override
  String bpSkippedSuffix(Object count) {
    return ' 并跳过 $count';
  }

  @override
  String get bpReadyToSave => '文件已准备好保存。';

  @override
  String get bpStepMapping => '3) 将列映射到字段';

  @override
  String get bpChooseFileFirst => '请先选择文件以显示映射表。';

  @override
  String get bpNoDynamicFields => '当前模板中没有动态字段。';

  @override
  String bpMappedCount(Object mapped, Object total) {
    return '已映射 $mapped/$total 列';
  }

  @override
  String get bpAutoMapHint => '选择文件后会建议智能自动映射；您可以编辑每一列。';

  @override
  String get bpNoFieldsHelp =>
      '所选模板没有动态字段，因此无可映射到文件列的内容。请在编辑器中打开模板，在姓名位置插入“动态字段”，保存后重试。';

  @override
  String get bpAutoMap => '自动映射';

  @override
  String get bpClearMapping => '清除映射';

  @override
  String get bpNameFieldWarning =>
      '此模板没有动态姓名字段——请勿将姓名列映射到日期或编号字段，否则姓名可能打印在错误位置。请从列列表中选择姓名键，或在编辑器中将固定姓名文本转换为动态字段。';

  @override
  String bpStaticNameHints(Object preview) {
    return '看起来像姓名的固定文本：“$preview”——没有动态字段会替换它。';
  }

  @override
  String get bpConvertToNameField => '将其转换为学员姓名字段';

  @override
  String bpDuplicateField(Object field) {
    return '字段“$field”映射到多列。请将每个字段映射到一列。';
  }

  @override
  String bpUnmappedColumns(Object count) {
    return '$count 列未映射——其数据不会用于证书。';
  }

  @override
  String bpColumn(Object n) {
    return '第 $n 列';
  }

  @override
  String get bpEmptyCell => '（空）';

  @override
  String get bpUnmapped => '— 未映射 —';

  @override
  String get bpStepMissing => '4) 空单元格和缺失数据';

  @override
  String get bpNoNotes => '选择文件前没有备注。';

  @override
  String get bpStepGenerate => '5) 生成';

  @override
  String bpGenerating(Object progress) {
    return '正在生成……$progress';
  }

  @override
  String get bpGenerateHint => '单个 PDF 文件，每条生成记录一页。';

  @override
  String get bpGeneratePickFile => '请先选择数据文件以启用生成。';

  @override
  String get bpMappingInvalid => '映射无效——同一字段映射到两列。';

  @override
  String get bpMapAtLeastOne => '请至少将一列映射到模板字段以启用生成。';

  @override
  String get bpGenerateCertificates => '生成证书';

  @override
  String get bpRegenerate => '重新生成';

  @override
  String get bpStatGenerated => '已生成';

  @override
  String get bpStatSkipped => '已跳过';

  @override
  String get bpStatPages => '页数';

  @override
  String get bpStatSize => '大小';

  @override
  String bpKilobytes(Object value) {
    return '$value KB';
  }

  @override
  String get bpStatTime => '时间';

  @override
  String bpMilliseconds(Object value) {
    return '$value 毫秒';
  }

  @override
  String bpCompletion(Object pct, Object total) {
    return '已完成 $pct%/%$total 行。';
  }

  @override
  String get bpSkippedRows => '未生成的行：';

  @override
  String bpRowSkipReason(Object n, Object reason) {
    return '第 $n 行：$reason';
  }

  @override
  String get bpPreviewHere => '预览显示在此处';

  @override
  String get bpPreviewHint => '选择数据文件，调整映射，然后按“生成证书”——生成文件的第一页将直接显示在此处。';

  @override
  String get bpAssignByTapTitle => '点按指定字段';

  @override
  String get bpAssignByTapBody =>
      '点按模板中的任意文本即可自行指定为动态字段。其他元素不受影响——无论是日期、管理者姓名还是任何固定文本。';

  @override
  String get bpNoTexts => '此模板中没有文本。';

  @override
  String get bpEmptyText => '（空文本）';

  @override
  String get bpDynamicFieldTap => '动态字段——点按以更改';

  @override
  String get bpStaticTextTap => '固定文本——点按以指定';

  @override
  String get bpAssignField => '指定字段';

  @override
  String get bpKindCertificate => '证书';

  @override
  String get bpKindContract => '合同';

  @override
  String bpLoadSampleError(Object error) {
    return '无法加载示例模板：$error';
  }

  @override
  String bpReadSheetError(Object error) {
    return '无法读取工作表：$error';
  }

  @override
  String bpUpdateHeaderRowError(Object error) {
    return '无法更新标题行：$error';
  }

  @override
  String get bpChooseTemplateFirst => '生成前请选择模板（证书或合同）。';

  @override
  String bpBatchTitle(Object kind) {
    return '$kind 批量 — JoodCraft';
  }

  @override
  String bpGenerateError(Object error) {
    return '无法运行批量生成：$error';
  }

  @override
  String get bpWarnNoDynamicFields =>
      '此模板没有动态字段——记录之间数据不会变化。请从编辑器工具栏添加“学员姓名”字段，然后保存模板。';

  @override
  String get bpWarnNoNameField =>
      '此模板没有动态姓名字段——姓名列可能映射到日期或编号字段，导致姓名打印在错误位置。请将固定姓名文本转换为字段，或重新设计模板。';

  @override
  String bpAssignedTemp(Object token) {
    return '此元素已为当前生成指定到 $token——其他元素不受影响。保存模板以永久保留更改。';
  }

  @override
  String bpAssignedSaved(Object token) {
    return '此元素已指定到 $token，更改已保存到模板。其他元素不受影响。';
  }

  @override
  String get commonShow => '显示';

  @override
  String get commonHide => '隐藏';

  @override
  String get themeSwitchToLight => '切换到浅色主题';

  @override
  String get themeSwitchToDark => '切换到深色主题';

  @override
  String commonComingSoonPhase(Object phase) {
    return '进行中 — 阶段 $phase';
  }

  @override
  String get cbNewCertificateTitle => '新证书';

  @override
  String get cbNewContractTitle => '新合同';

  @override
  String get cbBeneficiaryDataTitle => '受益人数据（示例）';

  @override
  String get cbContractDataTitle => '合同数据（示例）';
}
