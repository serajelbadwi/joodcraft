// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get editorDone => '完成';

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
  String get actionOpenMenu => '菜单';

  @override
  String get editorFitToScreen => '适应屏幕';

  @override
  String get editorNewTemplate => '新建模板';

  @override
  String get editorNewConfirm => '新模板将从默认设计开始；未保存的更改仍保留在撤销历史中。继续？';

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
  String get destBrand => '品牌与资料';

  @override
  String get destBrandDesc => '您的标志、印章、签名和品牌色。';

  @override
  String get brandTitle => '品牌与资料设置';

  @override
  String get brandTabVisuals => '视觉识别';

  @override
  String get brandTabText => '文本数据';

  @override
  String get brandTabColors => '颜色与字体';

  @override
  String get brandTabPreview => '品牌预览';

  @override
  String get brandPrimaryLogo => '主标志';

  @override
  String get brandWatermarkLogo => '水印标志';

  @override
  String get brandSeals => '官方印章';

  @override
  String get brandAddSeal => '添加印章';

  @override
  String get brandSealName => '印章名称';

  @override
  String get brandSignatures => '授权签名';

  @override
  String get brandAddSignature => '添加签名';

  @override
  String get brandSignatureName => '签署人姓名';

  @override
  String get brandSignatureTitle => '职务';

  @override
  String get brandRemove => '移除';

  @override
  String get brandNoSeals => '还没有添加印章。';

  @override
  String get brandNoSignatures => '还没有添加签名。';

  @override
  String get brandOrgNameAr => '机构名称（阿拉伯语）';

  @override
  String get brandOrgNameEn => '机构名称（英语）';

  @override
  String get brandHeaderText => '页眉文本';

  @override
  String get brandFooterText => '页脚文本';

  @override
  String get brandRegNumber => '税号 / 注册号';

  @override
  String get brandPrimaryColor => '主色';

  @override
  String get brandSecondaryColor => '辅色';

  @override
  String get brandAccentColor => '强调色';

  @override
  String get brandHeaderFont => '标题字体';

  @override
  String get brandBodyFont => '正文字体';

  @override
  String get brandClear => '清除品牌';

  @override
  String get brandClearConfirm => '将删除所有已保存的品牌内容。继续吗？';

  @override
  String get brandSaved => '品牌已保存。';

  @override
  String get brandPresets => '品牌元素';

  @override
  String get brandInsertHeader => '插入标准页眉';

  @override
  String get brandInsertFooter => '插入标准页脚';

  @override
  String get brandApplyColors => '应用品牌色';

  @override
  String get brandQuickSeals => '印章';

  @override
  String get brandQuickSignatures => '签名';

  @override
  String get brandNoBrand => '您还没有设置品牌。';

  @override
  String get brandOpenSettings => '打开品牌设置';

  @override
  String get brandHeaderInserted => '已插入标准页眉。';

  @override
  String get brandFooterInserted => '已插入标准页脚。';

  @override
  String get brandColorsApplied => '已应用品牌色。';

  @override
  String get brandSealInserted => '已插入印章。';

  @override
  String get brandSignatureInserted => '已插入签名。';

  @override
  String get brandFontDefault => '默认';

  @override
  String get paletteShapes => '形状';

  @override
  String get paletteRoundedRect => '圆角矩形';

  @override
  String get paletteEllipse => '圆形 / 椭圆';

  @override
  String get editorFillOpacity => '填充不透明度';

  @override
  String get editorCollapsePanel => '折叠侧栏';

  @override
  String get editorExpandPanel => '显示侧栏';

  @override
  String get editorCustomSize => '自定义尺寸';

  @override
  String get editorStandardSize => '标准尺寸';

  @override
  String get editorBackgroundTitle => '页面背景';

  @override
  String get editorGradientFrom => '从';

  @override
  String get editorGradientTo => '到';

  @override
  String get editorGradientDirection => '方向';

  @override
  String get editorGradientNone => '无渐变';

  @override
  String get editorGradientVertical => '垂直';

  @override
  String get editorGradientHorizontal => '水平';

  @override
  String get editorGradientDiagonal => '对角';

  @override
  String get editorLayersTitle => '图层';

  @override
  String get editorLayerShow => '显示元素';

  @override
  String get editorLayerHide => '隐藏元素';

  @override
  String get editorLayerLock => '锁定元素';

  @override
  String get editorLayerUnlock => '解锁元素';

  @override
  String get editorLayersEmpty => '此页面还没有元素。';

  @override
  String get editorGroupSelected => '组合所选';

  @override
  String get editorUngroupSelected => '取消组合';

  @override
  String get editorAlignLeft => '左对齐';

  @override
  String get editorAlignCenterH => '水平居中';

  @override
  String get editorAlignRight => '右对齐';

  @override
  String get editorAlignTop => '顶对齐';

  @override
  String get editorAlignCenterV => '垂直居中';

  @override
  String get editorAlignBottom => '底对齐';

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
  String get editorImageTint => '图片着色';

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
  String get amCacheLabel => '磁盘上的图片缓存';

  @override
  String amCacheUsage(Object count, Object size) {
    return '$count 个文件 · $size';
  }

  @override
  String amCacheUsageOf(Object count, Object used, Object limit) {
    return '$count 个文件 · $used / $limit';
  }

  @override
  String get amCacheEmpty => '尚无磁盘缓存';

  @override
  String get amCacheClear => '清除缓存';

  @override
  String get amCacheCleared => '已清除磁盘上的图片缓存。';

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
  String get cfpGroupBuiltin => '内置字体';

  @override
  String get cfpGroupUploaded => '我上传的字体';

  @override
  String get cfpGroupSystem => '系统字体';

  @override
  String get cfpSearchHint => '搜索字体…';

  @override
  String get cfpNoMatch => '没有匹配的字体。';

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

  @override
  String get editorSendBackward => '后移';

  @override
  String get editorRotateLeft => '左转 90°';

  @override
  String get editorRotateRight => '右转 90°';

  @override
  String get editorFlipH => '水平翻转';

  @override
  String get editorFlipV => '垂直翻转';

  @override
  String get editorTransform => '变换';

  @override
  String get editorToolSelect => '选择';

  @override
  String get editorToolShapes => '形状';

  @override
  String get editorFillType => '填充类型';

  @override
  String get editorFillSolid => '纯色';

  @override
  String get editorGradientLinear => '线性渐变';

  @override
  String get editorGradientRadial => '径向渐变';

  @override
  String get editorGradientAngle => '渐变角度';

  @override
  String get editorShadowEnable => '添加阴影';

  @override
  String get editorShadowColor => '阴影颜色';

  @override
  String get editorShadowBlur => '阴影模糊';

  @override
  String get editorShadowOffsetX => 'X 偏移';

  @override
  String get editorShadowOffsetY => 'Y 偏移';

  @override
  String get editorShadowSpread => '扩散';

  @override
  String get editorShadowRemove => '移除阴影';

  @override
  String get editorPoints => '点数';

  @override
  String get editorInnerRadius => '内半径';

  @override
  String get editorCornerTopLeft => '左上';

  @override
  String get editorCornerTopRight => '右上';

  @override
  String get editorCornerBottomRight => '右下';

  @override
  String get editorCornerBottomLeft => '左下';

  @override
  String get editorDashPattern => '虚线样式';

  @override
  String get editorBooleanOps => '布尔运算';

  @override
  String get editorBooleanUnion => '合并';

  @override
  String get editorBooleanSubtract => '减去';

  @override
  String get editorBooleanIntersect => '相交';

  @override
  String get editorBooleanUngroup => '分离';

  @override
  String get paletteStar => '星形';

  @override
  String get palettePolygon => '多边形';

  @override
  String get editorBooleanExclude => '排除';

  @override
  String get editorBooleanHint => '合并后的路径是单一的布尔结果（无内部边框），可随时拆分。';

  @override
  String get editorDockTools => '工具面板';

  @override
  String get editorDockAnchor => '停靠位置';

  @override
  String get editorDockTopBar => '顶部栏';

  @override
  String get editorDockInspector => '侧面板';

  @override
  String get editorDockLeftRail => '侧边栏';

  @override
  String get editorDockFloating => '浮动';

  @override
  String get editorDockCollapse => '收起工具';

  @override
  String get editorDockExpand => '展开工具';

  @override
  String get editorDockResize => '拖动以调整大小';

  @override
  String get editorDockDropHint => '松开以停靠到';

  @override
  String get editorMoreTools => '更多工具';

  @override
  String get editorDocumentProperties => '文档属性';

  @override
  String get editorDockReset => '恢复默认停靠';

  @override
  String get editorTextShadow => '文字阴影';

  @override
  String get editorTextShadowAdd => '添加文字阴影';

  @override
  String get editorShadowOpacity => '阴影不透明度';

  @override
  String get genderMale => '男性';

  @override
  String get genderFemale => '女性';

  @override
  String get genderPreviewAutoHint => '点击取消强制（自动）';

  @override
  String get genderPresetCompleted => '“completed”（阳/阴）';

  @override
  String get genderPresetPassed => '“passed”（阳/阴）';

  @override
  String get genderPresetForStudent => '“for the student”（阳/阴）';

  @override
  String get genderPresetStudent => '“the student”（阳/阴）';

  @override
  String get genderPresetToHim => '“to him / to her”';

  @override
  String get genderPresetHonoring => '“the outstanding trainee”（阳/阴）';

  @override
  String get editorGenderSnippet => '插入条件片段';

  @override
  String get editorGenderSnippetHint => '插入会根据收件人性别自动切换的短语。';

  @override
  String get bpGenderReviewTitle => '性别审核（男性/女性）';

  @override
  String get bpGenderReviewSubtitle => '性别从姓名或“Gender”列推断 — 打印前请修正边界情况。';

  @override
  String get bpGenderRow => '行';

  @override
  String get bpGenderDetected => '推断';

  @override
  String get bpGenderEffective => '应用';

  @override
  String get bpGenderNameColumn => '姓名';

  @override
  String get bpGenderEditName => '编辑姓名';

  @override
  String get bpGenderNameHint => '输入正确的姓名';

  @override
  String get bpGenderClearOverrides => '清除修正';

  @override
  String get bpGenderOverridden => '已手动修正';

  @override
  String get bpGenderUnknownName => '—';

  @override
  String get bpOutputTitle => '证书保存位置';

  @override
  String get bpOutputHint => '选择保存生成的 PDF 的文件夹，或以默认位置开始。';

  @override
  String get bpOutputPickFolder => '选择文件夹…';

  @override
  String get bpOutputStart => '开始生成';

  @override
  String get bpOutputPathLabel => '已选文件夹';

  @override
  String get bpOutputNoFolder => '未选择文件夹 — 仅打印和导出。';

  @override
  String get bpOpenFolder => '打开文件夹';

  @override
  String get bpOutputSavedTitle => 'PDF 文件已保存';

  @override
  String get bpOpenFolderFailed => '无法打开文件夹。';

  @override
  String get bpOutputNameLabel => '导出文件名';

  @override
  String get bpOutputNameHint => '输入不带扩展名的名称';

  @override
  String get bpOutputNamePreviewLabel => '将保存为';

  @override
  String get bpOutputModeLabel => '保存模式';

  @override
  String get bpOutputModeCombined => '单个合并文件';

  @override
  String get bpOutputModeIndividual => '每人单独文件';

  @override
  String get hubTitle => '新建项目';

  @override
  String get hubSubtitle => '选择现成尺寸或自定义尺寸——画布将以精确尺寸和比例打开。';

  @override
  String get hubKindSingle => '单页印刷品与文档';

  @override
  String get hubKindMulti => '多页书籍与出版物';

  @override
  String get hubKindSingleHint => '单页：证书、合同、卡片、座号、贺卡。';

  @override
  String get hubKindMultiHint => '多页：书籍、杂志、小册子、报告、目录。';

  @override
  String get hubGroupCertificates => '证书与合同';

  @override
  String get hubGroupCards => '卡片与证件';

  @override
  String get hubGroupSeat => '座号与标签';

  @override
  String get hubGroupGreeting => '贺卡';

  @override
  String get hubGroupPublications => '书籍与出版物';

  @override
  String get hubGroupCustom => '自定义尺寸';

  @override
  String get hubDigitalBadge => '数字';

  @override
  String get hubCreate => '创建';

  @override
  String get hubCustomCardBody => '输入任意单位的尺寸，立即以你的尺寸开始设计。';

  @override
  String get hubCustomName => '项目名称';

  @override
  String get hubCustomNameHint => '例如：邀请卡';

  @override
  String get hubCustomPreview => '最终尺寸';

  @override
  String get hubCustomCreate => '创建画布';

  @override
  String get hubCustomType => '项目类型';

  @override
  String get hubSearchHint => '搜索尺寸…';

  @override
  String get hubNoResults => '没有匹配的尺寸——试试其他关键词。';

  @override
  String get hubAspectRatio => '比例';

  @override
  String get destNewProject => '新建项目';

  @override
  String get destNewProjectDesc => '选择现成或自定义尺寸，立即开始设计。';

  @override
  String get ptpImpositionToggle => '拼版打印';

  @override
  String get ptpImpositionNoFit => '纸张放不下该项目——请缩小页边距或选择更大的纸张。';

  @override
  String get editorEffectsTitle => '效果与颜色调整';

  @override
  String get editorShadowGroup => '阴影';

  @override
  String get editorOuterGlow => '外发光';

  @override
  String get editorInnerGlow => '内发光';

  @override
  String get editorGlowAdd => '添加发光';

  @override
  String get editorGlowRemove => '移除发光';

  @override
  String get editorGlowColor => '发光颜色';

  @override
  String get editorGlowRadius => '发光半径';

  @override
  String get editorGlowSpread => '发光扩展';

  @override
  String get editorGlowOpacity => '发光不透明度';

  @override
  String get editorAdjustGroup => '颜色调整';

  @override
  String get editorAdjustBrightness => '亮度';

  @override
  String get editorAdjustContrast => '对比度';

  @override
  String get editorAdjustSaturation => '饱和度';

  @override
  String get editorAdjustHue => '色相';

  @override
  String get editorAdjustReset => '重置';

  @override
  String get bpOutputSavedFolderTitle => '文件已保存到专用文件夹';

  @override
  String get hubDetailsTitle => '尺寸详情';

  @override
  String get hubDetailsHint => '已预填默认规格 — 从网格中选择尺寸，或直接修改宽高。';

  @override
  String get hubFilterAll => '全部';

  @override
  String get hubFilterRecent => '最近尺寸';

  @override
  String get hubFilterSeat => '座位号';

  @override
  String get hubFilterGreeting => '贺卡与屏幕';

  @override
  String get hubRecentEmpty => '暂无最近尺寸 — 你创建的任何项目都会显示在这里。';

  @override
  String get hubDocTitle => '项目名称';

  @override
  String get hubDocTitleHint => '新建项目 - 1';

  @override
  String get hubWidth => '宽度';

  @override
  String get hubHeight => '高度';

  @override
  String get hubUnitLabel => '单位';

  @override
  String get hubOrientationLabel => '方向';

  @override
  String get hubPortrait => '纵向';

  @override
  String get hubLandscape => '横向';

  @override
  String get hubVariantLabel => '类型';

  @override
  String get hubResolutionLabel => '分辨率';

  @override
  String get hubResolutionUnitLabel => '分辨率单位';

  @override
  String get hubColorModeLabel => '颜色模式';

  @override
  String get hubBackgroundLabel => '背景颜色';

  @override
  String get hubBackgroundWhite => '白色';

  @override
  String get hubBackgroundTransparent => '透明';

  @override
  String get hubBackgroundBlack => '黑色';

  @override
  String get hubBackgroundCustom => '自定义颜色';

  @override
  String get hubCreateProject => '创建项目';

  @override
  String get hubCustomFamilyTitle => '自定义尺寸';

  @override
  String get newDocTitle => '新建文档';

  @override
  String get newDocScopeSocial => '屏幕与贺卡';

  @override
  String get newDocFilterCertificates => '证书';

  @override
  String get newDocFilterCards => '卡片';

  @override
  String get newDocFilterGreeting => '贺卡';

  @override
  String get newDocFilterPublications => '出版物';

  @override
  String get menuFile => '文件';

  @override
  String get menuEdit => '编辑';

  @override
  String get menuView => '视图';

  @override
  String get menuTools => '工具';

  @override
  String get menuHelp => '帮助';

  @override
  String get menuNewDocument => '新建文档…';

  @override
  String get menuPurgeRecent => '清除最近使用的尺寸';

  @override
  String get menuPurgeImageCache => '清除图像缓存';

  @override
  String get menuPreviewCertificate => '预览示例证书';

  @override
  String get menuPreviewContract => '预览示例合同';

  @override
  String get menuAbout => '关于 JoodCraft';

  @override
  String get actionNewShort => '+ 新建';

  @override
  String get dashLocalMode => '本地';

  @override
  String get dashLocalStorage => '保存在本设备本地——项目不会上传到服务器。';

  @override
  String get dashRecentProjects => '最近的项目';

  @override
  String get dashRecentEmpty => '此设备上还没有已保存的项目——新建文档后会立即显示在这里。';

  @override
  String get dashRecentOpen => '打开项目';

  @override
  String get dashRoadmapLocal => '本地项目数据库（projects 表），100% 离线保存';

  @override
  String get dashRoadmapOffline => '完全离线运行：无需上传项目，也不需要网络';

  @override
  String get editorTransformPosition => '变换与位置';

  @override
  String get editorTransformPositionHint => '位置、尺寸和旋转角度';

  @override
  String get editorAppearanceEffects => '外观与效果';

  @override
  String get editorAppearanceEffectsHint => '填充、描边、发光和阴影';

  @override
  String get editorTypographyHint => '字体、字号、对齐和间距';

  @override
  String get editorPageSettingsHint => '尺寸和度量单位';

  @override
  String get editorBackgroundHint => '页面颜色或渐变';

  @override
  String get editorPrecisionHint => '微移和缩放';

  @override
  String get joodExportProject => '导出项目 (.jood)';

  @override
  String get joodImportProject => '打开项目 (.jood)';

  @override
  String get joodExportReady => '项目文件已准备好保存。';

  @override
  String get joodExportFailed => '无法导出项目文件。';

  @override
  String get joodImportOpened => '已打开导入的项目。';

  @override
  String get joodImportFailed => '无法打开项目文件。';

  @override
  String get joodRecoveryTitle => '未保存的草稿';

  @override
  String get joodRecoveryMessage => '存在上次会话未保存的草稿。是否要恢复？';

  @override
  String get joodRecoveryRestore => '恢复';

  @override
  String get joodRecoveryDiscard => '忽略';

  @override
  String get joodRecoveryRestored => '草稿已恢复。';

  @override
  String get joodAutosaveSaved => '已自动保存';

  @override
  String get joodAutosaveSaving => '正在保存…';

  @override
  String get editorConfirm => '确认';

  @override
  String get admTitle => '本地管理员管理';

  @override
  String get admRefresh => '刷新';

  @override
  String get admTabAdmins => '管理员';

  @override
  String get admTabTransfer => '设备间转移';

  @override
  String get admTabAudit => '导出日志';

  @override
  String get admListTitle => '此设备上的管理员账户';

  @override
  String get admAdd => '添加管理员';

  @override
  String get admNoAdmins => '暂无管理员账户。';

  @override
  String get admLoading => '正在加载此设备上的管理员账户…';

  @override
  String get admRoleOwner => '主管理员';

  @override
  String get admCurrent => '你';

  @override
  String get admCurrentCardTitle => '此设备上的当前账户';

  @override
  String get admRoleAdmin => '管理员';

  @override
  String get admSwitchTitle => '快速切换账户';

  @override
  String get admSwitchPrompt =>
      '选择此设备上子管理员的本地用户名并输入其本地密码，即可立即切换到其会话——打开的项目草稿会先被保存，主授权不受影响。';

  @override
  String get admSwitchNoOthers => '此设备上没有其他子管理员。请先在管理员页面添加一个新管理员。';

  @override
  String get admSwitchPick => '本地用户名';

  @override
  String get admSwitchPassword => '所选账户的本地密码';

  @override
  String get admSwitchPickPassword => '请选择用户名并输入密码。';

  @override
  String get admSwitchWrongPassword => '密码不正确。';

  @override
  String get admSwitchFailed => '无法切换账户。请重试。';

  @override
  String get admSwitchSuccess => '账户切换成功。';

  @override
  String get admSwitchAccount => '切换账户';

  @override
  String get admSwitchAction => '立即切换';

  @override
  String get admColAdmin => '管理员';

  @override
  String get admColUsername => '本地用户名';

  @override
  String get admColRole => '角色';

  @override
  String get admColCreated => '添加日期';

  @override
  String get admColActions => '操作';

  @override
  String get destJoodWriter => 'Jood 写作';

  @override
  String get destJoodWriterDesc => '自动分页的文本文档与报告。';

  @override
  String get admCreatedAt => '创建时间';

  @override
  String get admEdit => '编辑资料';

  @override
  String get admChangePassword => '更改密码';

  @override
  String get admPromote => '提升为主管理员';

  @override
  String get admDemote => '降为管理员';

  @override
  String get admDelete => '删除账户';

  @override
  String admDeleteConfirm(Object name) {
    return '“$name”将从此设备永久删除。此操作无法撤销。';
  }

  @override
  String get admPromoted => '已提升为主管理员。';

  @override
  String get admDemoted => '已降为管理员。';

  @override
  String get admDeleted => '账户已删除。';

  @override
  String get admCreated => '已添加新管理员。';

  @override
  String get admUpdated => '管理员资料已更新。';

  @override
  String get admPasswordChanged => '密码已更改。';

  @override
  String get admTransferInfoTitle => '转移如何运作？';

  @override
  String get admTransferInfo1 => '账户表（含密码哈希，绝不含密码本身）会导出到你自定义口令加密的文件中。';

  @override
  String get admTransferInfo2 => '将文件或代码移到另一台设备，使用相同口令导入，账户即可用相同权限登录。';

  @override
  String get admTransferInfo3 => '不会向任何服务器发送任何内容：转移完全在本地设备之间手动完成。';

  @override
  String get admExport => '导出账户';

  @override
  String get admExportPassphrase => '导出口令';

  @override
  String get admPassphraseConfirm => '确认口令';

  @override
  String get admExportRisk => '我明白任何持有此代码及其口令的人都能用这些账户登录，因此我会谨慎分享。';

  @override
  String get admExportGenerate => '生成加密代码';

  @override
  String get admExportFile => '保存到专用文件';

  @override
  String get admExportDone => '已生成加密代码。请复制或保存为文件。';

  @override
  String get admExportFileSaved => '加密账户文件已保存。';

  @override
  String get admPassphraseTooShort => '口令至少使用 6 个字符。';

  @override
  String get admPassphraseMismatch => '两次输入的口令不一致。';

  @override
  String get admAcceptRiskRequired => '请先确认你了解分享代码的风险。';

  @override
  String admFileError(Object error) {
    return '无法处理该文件：$error';
  }

  @override
  String get admImport => '导入账户';

  @override
  String get admImportCode => '账户代码';

  @override
  String get admImportPassphrase => '文件口令';

  @override
  String get admImportReplace => '替换现有账户的密码';

  @override
  String get admImportPick => '选择文件';

  @override
  String get admImportRun => '立即导入';

  @override
  String get admImportCodeRequired => '请先粘贴代码或选择文件。';

  @override
  String get admImportPassphraseRequired => '请输入文件口令。';

  @override
  String admImportDone(int added, int updated, int skipped) {
    return '已导入：新增 $added，更新 $updated，跳过 $skipped。';
  }

  @override
  String get admAuditTitle => '已签发证书与文档日志';

  @override
  String get admAuditClear => '清空日志';

  @override
  String get admAuditEmpty => '暂无导出记录。你导出的每份证书或合同都会连同日期和签发管理员记录在此。';

  @override
  String get admAuditBy => '操作人';

  @override
  String get admAuditPages => '页';

  @override
  String get admAuditClearConfirm => '整个导出日志将从此设备删除。此操作无法撤销。';

  @override
  String get admAuditCleared => '日志已清空。';

  @override
  String get admUnavailableTitle => '管理功能当前不可用';

  @override
  String get admUnavailableBody =>
      '当应用以本地账户（LocalAuthRepository）运行时，管理员管理才可用，因此账户从本设备读取。';
}
