import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../assets/asset_image_cache.dart';
import '../../assets/assets_controller.dart';
import '../../assets/embedded_assets.dart';
import '../../assets/user_asset.dart';
import '../../constants/app_assets.dart';
import '../../gender/arabic_gender.dart';
import '../../models/template_document.dart';
import '../../models/template_element.dart';
import '../../models/text_flow.dart';
import '../../models/text_styling.dart';
import '../../pdf/pdf_font_catalog.dart';
import '../../l10n/app_l10n.dart';
import '../../utils/hex_color.dart';
import 'element_effects.dart';
import 'element_painters.dart';

/// اسم عائلة الخط داخل فلاتر مقابل عائلة الخط في محرّك الـ PDF.
String editorFontFamily(PdfFontFamily family) => family.uiFamily;

/// اسم الخط الفعلي للعنصر: الخط المخصص (إن وُجد ومسجَّل) وإلا المضمّن.
String editorFontFamilyOf(TextElement text) {
  final String? custom = text.customFont;
  if (custom != null && custom.trim().isNotEmpty) return custom.trim();
  return editorFontFamily(text.family);
}

/// ظل النص كما يفهمه فلاتر ([Shadow]) — لون + إزاحة + تمويه.
///
/// يُستخدم في **كل** مسارات رسم النص في المحرر: العنصر العادي، معاينة المحرر
/// الداخلية، والحقول الديناميكية المحلولة داخل النص - لأنها كلها تنتهي إلى
/// [editorTextStyle] نفسه.
///
/// ويضيف فوقه **التوهّج الخارجي** ([GlowEffect]) إن وُجد: تمويه بلا إزاحة
/// يحيط الحروف، ويتحوّل [GlowEffect.spread] إلى حلقة نسخ مُزاحة على محيط
/// دائرة لأنّ [Shadow] لا يعرف التوسيع.
List<Shadow>? editorTextShadows(
  TextShadow? shadow,
  double scale, {
  GlowEffect? outerGlow,
}) {
  final List<Shadow> layers = <Shadow>[];
  if (shadow != null && shadow.isVisible) {
    final Color color = colorFromHex(shadow.colorHex, fallback: Colors.black)
        .withValues(alpha: shadow.opacity.clamp(0, 1));
    final double blur = math.max(0, shadow.blurRadius) * scale;
    final Offset base = Offset(shadow.offsetX * scale, shadow.offsetY * scale);
    final double spread = math.max(0, shadow.spread) * scale;
    if (spread <= 0) {
      layers.add(Shadow(color: color, offset: base, blurRadius: blur));
    } else {
      // التوسيع: نسخة في المركز وأخرى على محيط دائرة نصف قطرها `spread`
      // فيبدو الظل منتفخاً من كل جهة كسلوك Photoshop.
      layers.add(Shadow(color: color, offset: base, blurRadius: blur));
      for (int i = 0; i < _spreadRingSteps; i++) {
        final double angle = 2 * math.pi * i / _spreadRingSteps;
        layers.add(Shadow(
          color: color,
          offset: base +
              Offset(math.cos(angle) * spread, math.sin(angle) * spread),
          blurRadius: blur,
        ));
      }
    }
  }
  if (outerGlow != null && outerGlow.isVisible) {
    final Color color = colorFromHex(outerGlow.colorHex, fallback: Colors.amber)
        .withValues(alpha: outerGlow.opacity.clamp(0, 1));
    final double blur = math.max(0, outerGlow.radius) * scale;
    final double spread = math.max(0, outerGlow.spread) * scale;
    layers.add(Shadow(color: color, blurRadius: blur));
    // حلقة التوسيع تُضاف فقط عند وجود توسيع فعلي — وإلا لتكرّرت النسخة
    // المركزية تسع مرّات بلا أي أثر بصري.
    if (spread > 0) {
      for (int i = 0; i < _spreadRingSteps; i++) {
        final double angle = 2 * math.pi * i / _spreadRingSteps;
        layers.add(Shadow(
          color: color,
          offset: Offset(math.cos(angle) * spread, math.sin(angle) * spread),
          blurRadius: blur,
        ));
      }
    }
  }
  return layers.isEmpty ? null : layers;
}

/// عدد نسخ الحلقة المستخدمة لإدراك التوسيع (spread) في ظلال النص.
const int _spreadRingSteps = 8;

/// نمط نص العنصر كما يظهر في المحرر (يُستخدم أيضاً في قياس الارتفاع التلقائي).
TextStyle editorTextStyle(TextElement text, double scale, {Paint? foreground}) {
  return TextStyle(
    fontFamily: editorFontFamilyOf(text),
    // خطوط نظام احتياطية (عربي + CJK) — فلا تظهر مربعات في معاينة القالب
    // حتى لو كان الخط المختار غير مغطٍّ. راجع AppAssets.uiFontFallback.
    fontFamilyFallback: AppAssets.uiFontFallback,
    fontSize: text.fontSize * scale,
    fontWeight: switch (text.weight) {
      PdfFontWeight.regular => FontWeight.w400,
      PdfFontWeight.semiBold => FontWeight.w600,
      PdfFontWeight.bold => FontWeight.w700,
    },
    // عند رسم طبقة التوهّج الداخلي يحلّ `foreground` محلّ اللون: لا يجوز
    // جمعهما في نمط واحد (فلاتر ترفض الاثنين معاً).
    color: foreground == null
        ? colorFromHex(text.colorHex, fallback: Colors.black)
        : null,
    foreground: foreground,
    height: text.lineHeight,
    letterSpacing: text.letterSpacing * scale,
    backgroundColor: text.backgroundHex == null
        ? null
        : colorFromHex(text.backgroundHex, fallback: Colors.white),
    shadows: editorTextShadows(text.shadow, scale, outerGlow: text.outerGlow),
  );
}

/// اتجاه النص الفعلي (بعد حلّ `auto` حسب محتوى النص) — عبر الحلّ المشترك مع
/// محرّك الطباعة حتى لا يختلف الاتجاه بين المحرر والـ PDF.
bool editorTextIsRtl(TextElement text, String resolved) =>
    TextFlow.resolvesRtl(text.direction, resolved);

/// نمط جزء واحد من النص ([run]) فوق نمط العنصر الأساسي.
///
/// نبني **طبقة رقيقة واحدة** فوق [base] فتُورّث الحقول غير المذكورة (الارتفاع،
/// تباعد الحروف، الظل…) تلقائياً — فلا يتكرّر التنسيق في كل قطعة ولا يمكن أن
/// ينحرف تباعد الأسطر بين كلمة ملوّنة وأخرى داخل السطر نفسه.
///
/// [applyColor] تُطفأ لطبقات التوهّج/الظل: هناك يحلّ `foreground` محل اللون،
/// وفلاتر ترفض الجمع بينهما في نمط واحد.
TextStyle editorSpanStyle(
  ResolvedSpanStyle run,
  TextStyle base, {
  bool applyColor = true,
}) {
  if (run.isBase) return base;
  return _spanStyleOnly(run, applyColor: applyColor);
}

TextStyle _spanStyleOnly(ResolvedSpanStyle run, {required bool applyColor}) {
  return TextStyle(
    inherit: true,
    fontFamily: run.customFont != null && run.customFont!.isNotEmpty
        ? run.customFont
        : (run.family == null ? null : editorFontFamily(run.family!)),
    fontWeight: run.weight == null
        ? null
        : switch (run.weight!) {
            PdfFontWeight.regular => FontWeight.w400,
            PdfFontWeight.semiBold => FontWeight.w600,
            PdfFontWeight.bold => FontWeight.w700,
          },
    fontStyle: run.italic ? FontStyle.italic : null,
    fontSize: run.size,
    color: applyColor && run.colorHex != null
        ? colorFromHex(run.colorHex!, fallback: Colors.black)
        : null,
    backgroundColor: run.backgroundHex == null
        ? null
        : colorFromHex(run.backgroundHex!, fallback: Colors.white),
    decoration: run.underline ? TextDecoration.underline : null,
  );
}

/// يبني شجرة [InlineSpan] لنصّ فيه تنسيق جزئي، من مقاطع [splitStyledRuns].
///
/// قطع [splitStyledRuns] تغطّي النص بالكامل بلا فجوات، فالناتج لا يختلف عن نصٍّ
/// موحّد إلا في التنسيق حرفياً.
InlineSpan editorTextSpan(
  String source,
  TextElement element,
  List<StyledTextSpan> spans,
  double scale, {
  Paint? foreground,

  /// معاينة خط حيّة: عائلة مؤقتة تُفرض على النمط الأساسي عند المرور فوق خيار
  /// خط في القوائم — لا تُمسّ الوثيقة وتزول بخروج المؤشر. نطاقات الخط الصريحة
  /// داخل النص تبقى أسبق منها.
  String? familyOverride,
}) {
  TextStyle base = editorTextStyle(element, scale, foreground: foreground);
  if (familyOverride != null && familyOverride.isNotEmpty) {
    base = base.copyWith(fontFamily: familyOverride, fontWeight: FontWeight.w400);
  }
  final List<StyledTextRun> runs = splitStyledRuns(source, spans);
  if (runs.length == 1 && runs.first.isBase) {
    return TextSpan(text: source, style: base);
  }
  return TextSpan(
    style: base,
    children: <InlineSpan>[
      for (final StyledTextRun run in runs)
        TextSpan(
          text: run.textOf(source),
          style: editorSpanStyle(run.style, base, applyColor: foreground == null),
        ),
    ],
  );
}

/// محاذاة النص كما يفهمها Flutter، مطابقة لقاعدة [TextFlow.anchorFor] المشتركة.
TextAlign editorTextAlign(ElementTextAlign align) => switch (align) {
      ElementTextAlign.start => TextAlign.start,
      ElementTextAlign.center => TextAlign.center,
      ElementTextAlign.end => TextAlign.end,
      ElementTextAlign.justify => TextAlign.justify,
    };

/// عرض عنصر واحد داخل لوحة المحرر.
///
/// الهدف: **مطابقة بصرية** لما سيخرج في الـ PDF (نفس الخط، نفس المحاذاة، نفس
/// الدوران، نفس الألوان) حتى لا يُفاجأ المستخدم بالنتيجة عند الطباعة.
class ElementView extends StatelessWidget {
  const ElementView({
    super.key,
    required this.element,
    required this.document,
    required this.scale,
    this.gender,
    this.rowData,
  });

  final TemplateElement element;
  final TemplateDocument document;
  final Map<String, String>? rowData;

  /// جنس المعاينة الحيّة — `null` يعني الاستنتاج التلقائي من
  /// الاسم/البيانات، وهو الوضع الافتراضي. يُمرَّر من مبدّل الجنس في الشريط
  /// العلوي لمعاينة الصياغة المؤنّثة فوراً على اللوحة.
  final Gender? gender;

  /// بكسلات الشاشة لكل وحدة تصميم.
  final double scale;

  @override
  Widget build(BuildContext context) {
    return switch (element) {
      final TextElement text => _buildText(text),
      final ShapeElement shape => _buildShape(shape),
      final SealElement seal => _buildSeal(seal),
      final DecorationElement decor => _buildDecoration(decor),
      final SignatureElement signature => _buildSignature(context, signature),
      final ImageElement image => _buildImage(context, image),
      final QrElement qr => _buildQr(context, qr),
      final UnknownElement unknown => _buildUnknown(context, unknown),
    };
  }

  // --------------------------------------------------------------------------
  //  النص
  // --------------------------------------------------------------------------
  Widget _buildText(TextElement text) {
    final String resolved = document.resolveFields(
      text.text,
      rowData,
      keepUnknownTokens: true,
      gender: gender,
    );

    final bool rtl = editorTextIsRtl(text, resolved);
    final TextDirection direction =
        rtl ? TextDirection.rtl : TextDirection.ltr;
    final TextAlign align = editorTextAlign(text.align);

    // التنسيق الجزئي يُطبَّق فقط إذا بقي النص بعد حلّ الحقول كما هو حرفياً —
    // وإلا لانزاحت الإزاحات عن كلماتها فصار اللون في موضع خاطئ. تحقّق بسيط
    // يمنع خطأً صامتاً بدل تخمين إزاحات.
    final bool useSpans = text.hasSpans && resolved == text.text;

    Widget content = useSpans
        ? RichText(
            text: editorTextSpan(resolved, text, text.spans, scale),
            textDirection: direction,
            textAlign: align,
            maxLines: text.maxLines,
            overflow: TextOverflow.clip,
          )
        : Text(
            resolved,
            textDirection: direction,
            textAlign: align,
            maxLines: text.maxLines,
            overflow: TextOverflow.clip,
            style: _textStyle(text, scale),
          );

    // التوهّج الداخلي: طبقة نص ثانية بنفس الحروف وحدّ مطموس إلى الداخل
    // (`BlurStyle.inner`) فوق الأصل — فيبقى التوهّج داخل الحروف وحدها.
    final Paint? innerGlow = editorTextInnerGlowPaint(text, scale);
    if (innerGlow != null) {
      content = Stack(
        fit: StackFit.passthrough,
        clipBehavior: Clip.none,
        children: <Widget>[
          content,
          Text(
            resolved,
            textDirection: direction,
            textAlign: align,
            maxLines: text.maxLines,
            overflow: TextOverflow.clip,
            style: _textStyle(text, scale, foreground: innerGlow),
          ),
        ],
      );
    }

    // عزل تأثيرات النص: ظل/توهّج خارجي يبقى داخل صندوق الفقرة + مسافة أثره
    // فقط، فلا يتسرّب التمويه إلى العناصر المجاورة أو إلى مساحة العمل.
    final double reach = _textEffectReach(text);
    if (reach > 0) {
      content = ClipRect(
        clipper: EffectBoundsClipper(reach: reach),
        child: content,
      );
    }

    return Opacity(
      opacity: text.opacity.clamp(0, 1),
      child: Align(
        alignment: switch (text.verticalAlign) {
          ElementVerticalAlign.top => Alignment.topCenter,
          ElementVerticalAlign.middle => Alignment.center,
          ElementVerticalAlign.bottom => Alignment.bottomCenter,
        },
        child: content,
      ),
    );
  }

  /// مسافة أثر ظل/توهّج النص خارج صندوق الفقرة (بكسلات الشاشة).
  ///
  /// تُحتسب كأقصى مسافة يبلغها التمويه فعلياً: الإزاحة + الانتشار + مدى
  /// التمويه ([blurReach]). يُؤخذ `blurRadius` كأنه انحراف معياريّ كامل حتى
  /// لا يُقتطع الظلّ مهما كان مقياس تحويل فلاتر لنص إلى σ.
  ///
  /// تُعيد `0` إن لم يكن للنص تأثير خارجي، فلا تُضاف طبقة قصّ زائدة أصلاً.
  double _textEffectReach(TextElement text) {
    double reach = 0;
    final TextShadow? shadow = text.shadow;
    if (shadow != null && shadow.isVisible) {
      final double blur = math.max(0, shadow.blurRadius) * scale;
      reach = math.max(
        reach,
        math.max(shadow.offsetX.abs(), shadow.offsetY.abs()) * scale +
            math.max(0, shadow.spread) * scale +
            blurReach(blur),
      );
    }
    final GlowEffect? glow = text.outerGlow;
    if (glow != null && glow.isVisible) {
      reach = math.max(
        reach,
        math.max(0, glow.spread) * scale +
            blurReach(math.max(0, glow.radius) * scale),
      );
    }
    return reach;
  }

  TextStyle _textStyle(TextElement text, double scale, {Paint? foreground}) =>
      editorTextStyle(text, scale, foreground: foreground);

  // --------------------------------------------------------------------------
  //  الأشكال
  // --------------------------------------------------------------------------
  Widget _buildShape(ShapeElement shape) {
    // الرسم عبر [ShapePainter] — نفس هندسة محرّك الـ PDF تماماً (التعبئة/
    // التدرّج/الإطار المتقطّع/الظل/القلب/الدمج المنطقي).
    return Opacity(
      opacity: shape.opacity.clamp(0, 1),
      child: CustomPaint(
        painter: ShapePainter(shape: shape, scale: scale),
        child: const SizedBox.expand(),
      ),
    );
  }

  // --------------------------------------------------------------------------
  //  الختم
  // --------------------------------------------------------------------------
  Widget _buildSeal(SealElement seal) {
    return Opacity(
      opacity: seal.opacity.clamp(0, 1),
      child: CustomPaint(
        painter: SealPainter(
          fillHex: seal.fillHex,
          ringHex: seal.ringHex,
          starHex: seal.starHex,
          starRatio: seal.starRatio,
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  //  الزخرفة المتجهية
  // --------------------------------------------------------------------------
  Widget _buildDecoration(DecorationElement decor) {
    return Opacity(
      opacity: decor.opacity.clamp(0, 1),
      child: CustomPaint(painter: DecorationPainter(spec: decor.spec)),
    );
  }

  // --------------------------------------------------------------------------
  //  التوقيعات المتعددة
  // --------------------------------------------------------------------------
  Widget _buildSignature(BuildContext context, SignatureElement signature) {
    final List<SignatureSlot> slots = signature.orderedSlots;
    if (slots.isEmpty) {
      return _MissingAssetHint(
        icon: Icons.draw_rounded,
        label: context.l10n?.evSignatureEmptyLabel ?? 'توقيعات فارغة',
        detail: context.l10n?.evSignatureEmptyDetail ?? 'أضف دوراً واسماً وصورة توقيع',
      );
    }

    return Opacity(
      opacity: signature.opacity.clamp(0, 1),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // العرض بالوحدات التصميمية: صندوق العنصر إن حُدّد، وإلا نستنتجه من
          // مقاس اللوحة الفعلي ÷ معامل التحويل (الصندوق 0 = امتداد).
          final double designWidth = signature.box.width > 0
              ? signature.box.width
              : (scale <= 0
                  ? constraints.maxWidth
                  : constraints.maxWidth / scale);
          final List<SignatureSlotRect> rects = signature.slotLayout(
            designWidth,
            slotCountOverride: slots.length,
          );
          final bool boundedHeight = constraints.maxHeight.isFinite;
          return Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              for (int i = 0; i < rects.length && i < slots.length; i++)
                Positioned(
                  left: rects[i].left * scale,
                  top: 0,
                  width: rects[i].width * scale,
                  height: boundedHeight ? constraints.maxHeight : null,
                  child:
                      _signatureSlot(context, signature, slots[i], rects[i].width),
                ),
            ],
          );
        },
      ),
    );
  }

  /// خانة واحدة: صورة التوقيع ← خط التوقيع ← الاسم ← الدور (ويُوسَّط رأسياً).
  ///
  /// [slotWidth] عرض الخانة بالوحدات التصميمية (من `slotLayout`) — يُستخدم
  /// لحساب ارتفاع الصورة بنفس قاعدة الـ PDF تماماً.
  Widget _signatureSlot(
    BuildContext context,
    SignatureElement element,
    SignatureSlot slot,
    double slotWidth,
  ) {
    final String role = document.resolveFields(
      slot.role,
      rowData,
      keepUnknownTokens: true,
      gender: gender,
    );
    final String name = document.resolveFields(
      slot.name,
      rowData,
      keepUnknownTokens: true,
      gender: gender,
    );
    final bool rtl = TextFlow.resolvesRtl(element.direction, '$name $role');
    final TextDirection textDirection =
        rtl ? TextDirection.rtl : TextDirection.ltr;
    final TextAlign textAlign = switch (element.align) {
      SignatureAlign.start => TextAlign.start,
      SignatureAlign.center => TextAlign.center,
      SignatureAlign.end => TextAlign.end,
    };
    final double imageHeight = element.imageHeightFor(
      slotWidth,
      boxHeight: element.box.height,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (slot.hasImage)
          SizedBox(
            height: imageHeight * scale,
            width: double.infinity,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6 * scale),
              child: _signatureImage(context, slot),
            ),
          ),
        if (element.showDivider)
          Padding(
            padding: EdgeInsets.only(
              top: (slot.hasImage ? 4 : 0) * scale,
              left: 12 * scale,
              right: 12 * scale,
              bottom: 5 * scale,
            ),
            child: Container(height: 1, color: const Color(0xFF6B7280)),
          ),
        if (name.trim().isNotEmpty)
          Text(
            name,
            textDirection: textDirection,
            textAlign: textAlign,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _signatureTextStyle(
              element: element,
              fontSize: element.nameFontSize,
              colorHex: element.nameColorHex,
              weight: PdfFontWeight.semiBold,
            ),
          ),
        if (role.trim().isNotEmpty)
          Text(
            role,
            textDirection: textDirection,
            textAlign: textAlign,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _signatureTextStyle(
              element: element,
              fontSize: element.roleFontSize,
              colorHex: element.roleColorHex,
              weight: PdfFontWeight.regular,
            ),
          ),
      ],
    );
  }

  TextStyle _signatureTextStyle({
    required SignatureElement element,
    required double fontSize,
    required String colorHex,
    required PdfFontWeight weight,
  }) {
    final String? custom = element.customFont;
    return TextStyle(
      fontFamily: custom != null && custom.trim().isNotEmpty
          ? custom.trim()
          : editorFontFamily(element.family),
      fontFamilyFallback: AppAssets.uiFontFallback,
      fontSize: fontSize * scale,
      fontWeight: switch (weight) {
        PdfFontWeight.regular => FontWeight.w400,
        PdfFontWeight.semiBold => FontWeight.w600,
        PdfFontWeight.bold => FontWeight.w700,
      },
      color: colorFromHex(colorHex, fallback: Colors.black),
      height: 1.3,
    );
  }

  /// صورة توقيع خانة — نفس قواعد عرض [ImageElement] (أصل حيّ ← Base64 ← تنبيه).
  Widget _signatureImage(BuildContext context, SignatureSlot slot) {
    const BoxFit fit = BoxFit.contain;
    if (slot.imageSource == ImageSourceKind.userAsset) {
      final UserAsset? asset = AssetsController.instance.byId(slot.imagePath);
      if (asset != null) {
        return _memoryImage(
          context,
          AssetImageCache.instance.providerForAsset(asset),
          fit,
        );
      }
      final String? inline = inlineSlotBase64(slot, document);
      return inline == null
          ? _MissingAssetHint(
              icon: Icons.image_not_supported_outlined,
              label: context.l10n?.evSignatureMissingLabel ?? 'توقيع محذوف',
              detail: context.l10n?.assetPickerTitle ?? 'اختر صورة من مكتبة أصولي',
            )
          : _imageFromBase64(context, inline, fit);
    }
    if (slot.imageSource == ImageSourceKind.dataUri) {
      return _imageFromBase64(context, slot.imagePath, fit);
    }
    if (slot.imageSource == ImageSourceKind.file) {
      return _MissingAssetHint(
        icon: Icons.link_off_rounded,
        label: context.l10n?.imageSourceLocalFile ?? 'ملف محلي',
        detail: context.l10n?.evUploadToLibraryDetail ?? 'ارفع الصورة إلى مكتبة الأصول',
      );
    }
    return Image.asset(
      slot.imagePath,
      fit: fit,
      errorBuilder: (
        BuildContext context,
        Object error,
        StackTrace? stackTrace,
      ) =>
          _MissingAssetHint(
        icon: Icons.broken_image_outlined,
        label: context.l10n?.evImageNotFoundLabel ?? 'صورة غير موجودة',
        detail: slot.imagePath,
      ),
    );
  }

  // --------------------------------------------------------------------------
  //  الصورة
  // --------------------------------------------------------------------------
  Widget _buildImage(BuildContext context, ImageElement image) {
    final BoxFit fit = switch (image.fit) {
      ImageFit.contain => BoxFit.contain,
      ImageFit.cover => BoxFit.cover,
      ImageFit.fill => BoxFit.fill,
    };

    late final Widget child;
    if (image.path.trim().isEmpty) {
      child = _MissingAssetHint(
        icon: Icons.add_photo_alternate_outlined,
        label: context.l10n?.evNoFileLabel ?? 'لم يُحدَّد ملف',
        detail: context.l10n?.evChooseFromAssetsDetail ?? 'اختر صورة من مكتبة الأصول',
      );
    } else if (image.sourceKind == ImageSourceKind.userAsset) {
      final UserAsset? asset = AssetsController.instance.byId(image.path);
      if (asset != null) {
        // البايتات والموفّر مفكوكان ومخزّنان مرة واحدة — لا فكّ Base64 ولا
        // إعادة رَستَرة في كل إطار أثناء السحب.
        child = _memoryImage(
          context,
          AssetImageCache.instance.providerForAsset(asset),
          fit,
        );
      } else {
        // نسخة Base64 مضمّنة (احتياطية) تُعرض رغم غياب الأصل من المكتبة.
        final String? inline = inlineImageBase64(image, document);
        child = inline == null
            ? _MissingAssetHint(
                icon: Icons.image_not_supported_outlined,
                label: context.l10n?.evAssetMissingLabel ?? 'أصل محذوف',
                detail: context.l10n?.evReselectAssetDetail ??
                    'أعد اختيار الإطار/الأصل من المكتبة',
              )
            : _imageFromBase64(context, inline, fit);
      }
    } else if (image.sourceKind == ImageSourceKind.dataUri) {
      // بيانات Base64 مضمّنة داخل `path` — تُعرض مباشرةً بلا مصدر خارجي.
      child = _imageFromBase64(context, image.path, fit);
    } else if (image.sourceKind == ImageSourceKind.file) {
      child = _MissingAssetHint(
        icon: Icons.link_off_rounded,
        label: context.l10n?.imageSourceLocalFile ?? 'ملف محلي',
        detail: context.l10n?.evUploadToLibraryDetail ?? 'ارفع الصورة إلى مكتبة الأصول',
      );
    } else {
      child = Image.asset(
        image.path,
        fit: fit,
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) =>
            _MissingAssetHint(
          icon: Icons.broken_image_outlined,
          label: context.l10n?.evImageNotFoundLabel ?? 'صورة غير موجودة',
          detail: image.path,
        ),
      );
    }

    // الضبط اللوني يُطبَّق على بكسلات الصورة **قبل** الظل والتوهّج، فيرسم
    // الظل حدود الصورة بعد الضبط (نفس ترتيب Photoshop).
    final ColorFilter? adjustments = elementAdjustmentFilter(image.adjustments);
    Widget content =
        adjustments == null
            ? child
            : ColorFiltered(colorFilter: adjustments, child: child);

    final bool hasEffects =
        (image.shadow != null && image.shadow!.isVisible) ||
            (image.outerGlow != null && image.outerGlow!.isVisible);

    return Opacity(
      opacity: image.opacity.clamp(0, 1),
      child: _maybeTinted(
        image,
        // عزل الطبقات الظلّية داخل `wrapRasterEffects`: صندوق العنصر +
        // مسافة أثر التأثير تحديداً، فلا يتسرّب التمويه إلى مساحة العمل.
        hasEffects
            ? wrapRasterEffects(
                child: content,
                scale: scale,
                shadow: image.shadow,
                outerGlow: image.outerGlow,
              )
            : content,
      ),
    );
  }

  /// يلوّن صورة العنصر إن كان له لون (`tintHex`).
  ///
  /// `BlendMode.srcIn` يستبدل **لون كل بكسل مرسوم** بلون التلوين ويأخذ قناة
  /// الشفافية من الصورة نفسها — فتتحول الخطوط/الزخرفة الداكنة إلى اللون المختار
  /// وتبقى الخلفية الشفافة شفافة تماماً (لا يزحف اللون إلى الفراغ). وعند غياب
  /// اللون يعود العنصر ببكسلاته الأصلية بلا أي طبقة إضافية.
  Widget _maybeTinted(ImageElement image, Widget child) {
    if (!image.hasTint) return child;
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        colorFromHex(image.tintHex!.trim()),
        BlendMode.srcIn,
      ),
      child: child,
    );
  }

  Widget _memoryImage(
    BuildContext context,
    ImageProvider provider,
    BoxFit fit,
  ) =>
      Image(
        image: provider,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) =>
            _MissingAssetHint(
          icon: Icons.broken_image_outlined,
          label: context.l10n?.evInvalidImageLabel ?? 'صورة غير صالحة',
          detail: context.l10n?.evRenderDataFailedDetail ?? 'تعذّر عرض البيانات',
        ),
      );

  /// عرض صورة من بيانات Base64 — مع بطاقة تنبيه إن كانت البيانات تالفة.
  Widget _imageFromBase64(BuildContext context, String base64, BoxFit fit) {
    try {
      return _memoryImage(
        context,
        AssetImageCache.instance.providerForBase64(base64),
        fit,
      );
    } catch (_) {
      return _MissingAssetHint(
        icon: Icons.broken_image_outlined,
        label: context.l10n?.evInvalidDataLabel ?? 'بيانات غير صالحة',
        detail: context.l10n?.evDecodeFailedDetail ?? 'تعذّر فك ترميز الصورة',
      );
    }
  }

  // --------------------------------------------------------------------------
  //  رمز QR
  // --------------------------------------------------------------------------
  Widget _buildQr(BuildContext context, QrElement qr) {
    final String resolved = document.resolveFields(
      qr.data,
      rowData,
      keepUnknownTokens: true,
      gender: gender,
    );
    if (resolved.trim().isEmpty) {
      return _MissingAssetHint(
        icon: Icons.qr_code_2_rounded,
        label: context.l10n?.evEmptyQrLabel ?? 'رمز فارغ',
        detail: context.l10n?.evEmptyQrDetail ?? 'أدخل قيمة الرمز في شريط الخصائص',
      );
    }
    return CustomPaint(
      painter: QrCodePainter(
        data: resolved,
        colorHex: qr.colorHex,
        backgroundHex: qr.backgroundHex,
      ),
    );
  }

  // --------------------------------------------------------------------------
  //  عنصر غير معروف (من إصدار أحدث) — يُحفظ ولا يُرسم
  // --------------------------------------------------------------------------
  Widget _buildUnknown(BuildContext context, UnknownElement unknown) {
    return CustomPaint(
      painter: const DashedRectPainter(color: EditorColors.unknown),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: FittedBox(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.help_outline_rounded,
                    size: 16, color: EditorColors.unknown),
                const SizedBox(height: 2),
                Text(
                  context.l10n?.evUnknownElementLabel(unknown.typeName) ??
                      'عنصر غير مدعوم: ${unknown.typeName}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: EditorColors.unknown,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// تنبيه بصري لأصل مفقود أو غير مدعوم.
class _MissingAssetHint extends StatelessWidget {
  const _MissingAssetHint({
    required this.icon,
    required this.label,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const DashedRectPainter(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: FittedBox(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 18, color: const Color(0xFF6B7280)),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
