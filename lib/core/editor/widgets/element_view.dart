import 'package:flutter/material.dart';

import '../../assets/asset_image_cache.dart';
import '../../assets/assets_controller.dart';
import '../../assets/embedded_assets.dart';
import '../../assets/user_asset.dart';
import '../../models/template_document.dart';
import '../../models/template_element.dart';
import '../../models/text_flow.dart';
import '../../pdf/pdf_font_catalog.dart';
import '../../utils/hex_color.dart';
import 'element_painters.dart';

/// اسم عائلة الخط داخل فلاتر مقابل عائلة الخط في محرّك الـ PDF.
String editorFontFamily(PdfFontFamily family) => family.uiFamily;

/// اسم الخط الفعلي للعنصر: الخط المخصص (إن وُجد ومسجَّل) وإلا المضمّن.
String editorFontFamilyOf(TextElement text) {
  final String? custom = text.customFont;
  if (custom != null && custom.trim().isNotEmpty) return custom.trim();
  return editorFontFamily(text.family);
}

/// نمط نص العنصر كما يظهر في المحرر (يُستخدم أيضاً في قياس الارتفاع التلقائي).
TextStyle editorTextStyle(TextElement text, double scale) {
  return TextStyle(
    fontFamily: editorFontFamilyOf(text),
    fontSize: text.fontSize * scale,
    fontWeight: switch (text.weight) {
      PdfFontWeight.regular => FontWeight.w400,
      PdfFontWeight.semiBold => FontWeight.w600,
      PdfFontWeight.bold => FontWeight.w700,
    },
    color: colorFromHex(text.colorHex, fallback: Colors.black),
    height: text.lineHeight,
    letterSpacing: text.letterSpacing * scale,
    backgroundColor: text.backgroundHex == null
        ? null
        : colorFromHex(text.backgroundHex, fallback: Colors.white),
  );
}

/// اتجاه النص الفعلي (بعد حلّ `auto` حسب محتوى النص) — عبر الحلّ المشترك مع
/// محرّك الطباعة حتى لا يختلف الاتجاه بين المحرر والـ PDF.
bool editorTextIsRtl(TextElement text, String resolved) =>
    TextFlow.resolvesRtl(text.direction, resolved);

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
  });

  final TemplateElement element;
  final TemplateDocument document;

  /// بكسلات الشاشة لكل وحدة تصميم.
  final double scale;

  @override
  Widget build(BuildContext context) {
    return switch (element) {
      final TextElement text => _buildText(text),
      final ShapeElement shape => _buildShape(shape),
      final SealElement seal => _buildSeal(seal),
      final ImageElement image => _buildImage(image),
      final QrElement qr => _buildQr(qr),
      final UnknownElement unknown => _buildUnknown(unknown),
    };
  }

  // --------------------------------------------------------------------------
  //  النص
  // --------------------------------------------------------------------------
  Widget _buildText(TextElement text) {
    final String resolved = document.resolveFields(
      text.text,
      null,
      keepUnknownTokens: true,
    );

    final bool rtl = editorTextIsRtl(text, resolved);

    return Opacity(
      opacity: text.opacity.clamp(0, 1),
      child: Align(
        alignment: switch (text.verticalAlign) {
          ElementVerticalAlign.top => Alignment.topCenter,
          ElementVerticalAlign.middle => Alignment.center,
          ElementVerticalAlign.bottom => Alignment.bottomCenter,
        },
        child: Text(
          resolved,
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          textAlign: editorTextAlign(text.align),
          maxLines: text.maxLines,
          overflow: TextOverflow.clip,
          style: _textStyle(text, scale),
        ),
      ),
    );
  }

  TextStyle _textStyle(TextElement text, double scale) =>
      editorTextStyle(text, scale);

  // --------------------------------------------------------------------------
  //  الأشكال
  // --------------------------------------------------------------------------
  Widget _buildShape(ShapeElement shape) {
    final Color? fill =
        shape.fillHex == null ? null : colorFromHex(shape.fillHex);
    final Color? stroke =
        shape.strokeHex == null ? null : colorFromHex(shape.strokeHex);

    if (shape.kind == ShapeKind.line) {
      return Opacity(
        opacity: shape.opacity.clamp(0, 1),
        child: Align(
          alignment: Alignment.center,
          child: Container(
            height: (shape.strokeWidth > 0 ? shape.strokeWidth : 1) * scale,
            color: stroke ?? fill ?? Colors.black,
          ),
        ),
      );
    }

    return Opacity(
      opacity: shape.opacity.clamp(0, 1),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          shape: shape.kind == ShapeKind.ellipse
              ? BoxShape.circle
              : BoxShape.rectangle,
          borderRadius: shape.kind == ShapeKind.rect && shape.radius > 0
              ? BorderRadius.circular(shape.radius * scale)
              : null,
          border: stroke == null || shape.strokeWidth <= 0
              ? null
              : Border.all(
                  color: stroke,
                  width: shape.strokeWidth * scale,
                ),
        ),
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
  //  الصورة
  // --------------------------------------------------------------------------
  Widget _buildImage(ImageElement image) {
    final BoxFit fit = switch (image.fit) {
      ImageFit.contain => BoxFit.contain,
      ImageFit.cover => BoxFit.cover,
      ImageFit.fill => BoxFit.fill,
    };

    late final Widget child;
    if (image.path.trim().isEmpty) {
      child = const _MissingAssetHint(
        icon: Icons.add_photo_alternate_outlined,
        label: 'لم يُحدَّد ملف',
        detail: 'اختر صورة من مكتبة الأصول',
      );
    } else if (image.sourceKind == ImageSourceKind.userAsset) {
      final UserAsset? asset = AssetsController.instance.byId(image.path);
      if (asset != null) {
        // البايتات والموفّر مفكوكان ومخزّنان مرة واحدة — لا فكّ Base64 ولا
        // إعادة رَستَرة في كل إطار أثناء السحب.
        child = _memoryImage(
          AssetImageCache.instance.providerForAsset(asset),
          fit,
        );
      } else {
        // نسخة Base64 مضمّنة (احتياطية) تُعرض رغم غياب الأصل من المكتبة.
        final String? inline = inlineImageBase64(image, document);
        child = inline == null
            ? const _MissingAssetHint(
                icon: Icons.image_not_supported_outlined,
                label: 'أصل محذوف',
                detail: 'أعد اختيار الإطار/الأصل من المكتبة',
              )
            : _imageFromBase64(inline, fit);
      }
    } else if (image.sourceKind == ImageSourceKind.dataUri) {
      // بيانات Base64 مضمّنة داخل `path` — تُعرض مباشرةً بلا مصدر خارجي.
      child = _imageFromBase64(image.path, fit);
    } else if (image.sourceKind == ImageSourceKind.file) {
      child = const _MissingAssetHint(
        icon: Icons.link_off_rounded,
        label: 'ملف محلي',
        detail: 'ارفع الصورة إلى مكتبة الأصول',
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
          label: 'صورة غير موجودة',
          detail: image.path,
        ),
      );
    }

    return Opacity(opacity: image.opacity.clamp(0, 1), child: child);
  }

  Widget _memoryImage(ImageProvider provider, BoxFit fit) => Image(
        image: provider,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) =>
            const _MissingAssetHint(
          icon: Icons.broken_image_outlined,
          label: 'صورة غير صالحة',
          detail: 'تعذّر عرض البيانات',
        ),
      );

  /// عرض صورة من بيانات Base64 — مع بطاقة تنبيه إن كانت البيانات تالفة.
  Widget _imageFromBase64(String base64, BoxFit fit) {
    try {
      return _memoryImage(
        AssetImageCache.instance.providerForBase64(base64),
        fit,
      );
    } catch (_) {
      return const _MissingAssetHint(
        icon: Icons.broken_image_outlined,
        label: 'بيانات غير صالحة',
        detail: 'تعذّر فك ترميز الصورة',
      );
    }
  }

  // --------------------------------------------------------------------------
  //  رمز QR
  // --------------------------------------------------------------------------
  Widget _buildQr(QrElement qr) {
    final String resolved = document.resolveFields(
      qr.data,
      null,
      keepUnknownTokens: true,
    );
    if (resolved.trim().isEmpty) {
      return const _MissingAssetHint(
        icon: Icons.qr_code_2_rounded,
        label: 'رمز فارغ',
        detail: 'أدخل قيمة الرمز في شريط الخصائص',
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
  Widget _buildUnknown(UnknownElement unknown) {
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
