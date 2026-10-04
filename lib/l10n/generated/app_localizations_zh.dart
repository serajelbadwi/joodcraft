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
}
