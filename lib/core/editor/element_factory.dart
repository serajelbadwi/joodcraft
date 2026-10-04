import 'dart:ui';

import '../assets/asset_type_ui.dart';
import '../assets/user_asset.dart';
import '../constants/app_constants.dart';
import '../constants/dynamic_fields.dart';
import '../models/template_element.dart';
import '../pdf/pdf_font_catalog.dart';

/// أنواع العناصر التي يمكن إضافتها من شريط أدوات المحرر.
enum NewElementKind {
  /// نص حر.
  text,

  /// عنوان كبير (نص بحجم أكبر ومحاذاة وسطية).
  heading,

  /// حقل ديناميكي `{{...}}` جاهز للربط بـ Excel.
  dynamicField,

  /// مستطيل/برواز.
  rectangle,

  /// خط فاصل.
  divider,

  /// ختم ذهبي متجهي.
  seal,

  /// شعار/توقيع (صورة).
  image,

  /// كتلة توقيعات متعددة (حتى ثلاثة توقيعات جنباً إلى جنب).
  signature,

  /// رمز تحقّق QR.
  qr,
}

/// إنشاء العناصر الجديدة بقيم افتراضية متناسقة مع حجم الورقة.
///
/// القيم نسبية من أبعاد مساحة التصميم حتى تبدو مناسبة على A4 الأفقي
/// (الشهادة) والرأسي (العقد) بلا ضبط يدوي.
abstract final class ElementFactory {
  const ElementFactory._();

  /// إنشاء عنصر جديد نوعه [kind] في ورقة أبعادها [design].
  ///
  /// [index] ترتيب الإنشاء — يُستخدم لإزاحة العناصر المتتالية قليلاً حتى لا
  /// تتكدّس فوق بعضها.
  static TemplateElement create({
    required NewElementKind kind,
    required Size design,
    int index = 0,
  }) {
    final double stagger = (index % 6) * 10;
    final double shortSide = design.width < design.height
        ? design.width
        : design.height;

    switch (kind) {
      case NewElementKind.text:
        return TextElement(
          id: nextId(index, 'text'),
          box: ElementBox(
            x: design.width * 0.18 + stagger,
            y: design.height * 0.42 + stagger,
            width: design.width * 0.64,
            height: shortSide * 0.09,
          ),
          text: 'نص جديد',
          fontSize: shortSide * 0.032,
          align: ElementTextAlign.center,
          verticalAlign: ElementVerticalAlign.middle,
        );

      case NewElementKind.heading:
        return TextElement(
          id: nextId(index, 'heading'),
          box: ElementBox(
            x: design.width * 0.15 + stagger,
            y: design.height * 0.18 + stagger,
            width: design.width * 0.7,
            height: shortSide * 0.13,
          ),
          text: 'عنوان المستند',
          weight: PdfFontWeight.bold,
          fontSize: shortSide * 0.05,
          align: ElementTextAlign.center,
          verticalAlign: ElementVerticalAlign.middle,
        );

      case NewElementKind.dynamicField:
        return TextElement(
          id: nextId(index, 'field'),
          box: ElementBox(
            x: design.width * 0.2 + stagger,
            y: design.height * 0.55 + stagger,
            width: design.width * 0.6,
            height: shortSide * 0.08,
          ),
          text: DynamicFields.token(DynamicFields.certificate.first.key),
          fontSize: shortSide * 0.03,
          colorHex: '#1B2539',
          align: ElementTextAlign.center,
          verticalAlign: ElementVerticalAlign.middle,
        );

      case NewElementKind.rectangle:
        return ShapeElement(
          id: nextId(index, 'rect'),
          kind: ShapeKind.rect,
          box: ElementBox(
            x: design.width * 0.06 + stagger,
            y: design.height * 0.06 + stagger,
            width: design.width * 0.88,
            height: design.height * 0.88,
          ),
          strokeHex: '#C7A26B',
          strokeWidth: 2,
          radius: 6,
        );

      case NewElementKind.divider:
        return ShapeElement(
          id: nextId(index, 'line'),
          kind: ShapeKind.line,
          box: ElementBox(
            x: design.width * 0.2 + stagger,
            y: design.height * 0.34 + stagger,
            width: design.width * 0.6,
            height: 1,
          ),
          fillHex: '#C7A26B',
          strokeHex: '#C7A26B',
          strokeWidth: 2,
        );

      case NewElementKind.seal:
        final double size = shortSide * 0.22;
        return SealElement(
          id: nextId(index, 'seal'),
          box: ElementBox(
            x: design.width * 0.74 + stagger,
            y: design.height * 0.66 + stagger,
            width: size,
            height: size,
          ),
        );

      case NewElementKind.image:
        final double size = shortSide * 0.2;
        return ImageElement(
          id: nextId(index, 'image'),
          box: ElementBox(
            x: design.width * 0.1 + stagger,
            y: design.height * 0.62 + stagger,
            width: size,
            height: size,
          ),
          sourceKind: ImageSourceKind.asset,
          path: '',
        );

      case NewElementKind.signature:
        return createSignature(design: design, index: index);

      case NewElementKind.qr:
        final double size = shortSide * 0.18;
        return QrElement(
          id: nextId(index, 'qr'),
          box: ElementBox(
            x: design.width * 0.08 + stagger,
            y: design.height * 0.72 + stagger,
            width: size,
            height: size,
          ),
          data: DynamicFields.token('رابط_التحقق'),
        );
    }
  }

  /// أدوار التوقيعات الافتراضية في الكتلة الجديدة.
  ///
  /// الأدوار نص ثابت (تتكرّر في كل المستندات)، وأسماء أصحابها تُولَّد بحقول
  /// ديناميكية حيث يوجد حقل مطابق في [DynamicFields] فتُربط بأعمدة Excel.
  static const List<SignatureSlot> defaultSignatureSlots = <SignatureSlot>[
    SignatureSlot(role: 'مدرب البرنامج', name: '{{المدرب}}'),
    SignatureSlot(role: 'الموارد البشرية'),
    SignatureSlot(role: 'المدير العام'),
  ];

  /// كتلة توقيعات جديدة (3 خانات افتراضياً) أسفل المستند.
  ///
  /// توزّع على 84% من عرض الورقة بتباعد تلقائي، وتُحجَّم خطوطها نسبياً من
  /// أبعاد الورقة فتبدو مناسبة على A4 الأفقي والرأسي بلا ضبط يدوي.
  static SignatureElement createSignature({
    required Size design,
    int index = 0,
    int slotCount = 3,
    List<SignatureSlot>? slots,
  }) {
    final double shortSide =
        design.width < design.height ? design.width : design.height;
    return SignatureElement(
      id: nextId(index, 'signature'),
      box: ElementBox(
        x: design.width * 0.08,
        y: design.height * 0.72,
        width: design.width * 0.84,
        height: design.height * 0.2,
      ),
      slots: slots ?? defaultSignatureSlots.take(slotCount).toList(),
      roleFontSize: shortSide * 0.016,
      nameFontSize: shortSide * 0.021,
      spacing: design.width * 0.03,
    );
  }

  /// بناء عنصر صورة يشير إلى أصل من مكتبة أصولي (`ImageSourceKind.userAsset`).
  ///
  /// * أصل من نوع «إطار» → يغطي الصفحة كاملة (`fill`) ليصلح كخلفية.
  /// * [asBackground] = true → يفرض تغطية الصفحة كاملة (`cover` للشعار) ليعمل
  ///   كخلفية للمستند خلف كل العناصر الأخرى.
  /// * أي أصل آخر → حجم معقول مع الملاءمة الافتراضية لنوعه.
  ///
  /// [embedData] = true (الافتراضي) → تُضمّن نسخة Base64 داخل العنصر كنسخة
  /// احتياطية، فلا يخرج الإطار أبيض في الـ PDF لو حُذف الأصل من المكتبة لاحقاً.
  static ImageElement fromUserAsset({
    required UserAsset asset,
    required Size design,
    int index = 0,
    bool asBackground = false,
    bool embedData = true,
  }) {
    final String? embedded =
        embedData && asset.base64Data.trim().isNotEmpty ? asset.base64Data : null;
    final bool isFrame = asset.type == AssetType.border;
    if (isFrame || asBackground) {
      return ImageElement(
        id: nextId(index, isFrame ? 'frame' : 'bg'),
        box: ElementBox(
          x: 0,
          y: 0,
          width: design.width,
          height: design.height,
        ),
        sourceKind: ImageSourceKind.userAsset,
        path: asset.id,
        fit: isFrame ? ImageFit.fill : ImageFit.cover,
        data: embedded,
      );
    }

    final double shortSide =
        design.width < design.height ? design.width : design.height;
    final double size = shortSide * 0.2;
    return ImageElement(
      id: nextId(index, 'asset'),
      box: ElementBox(
        x: design.width * 0.1,
        y: design.height * 0.62,
        width: size,
        height: size,
      ),
      sourceKind: ImageSourceKind.userAsset,
      path: asset.id,
      fit: asset.type.defaultFit,
      data: embedded,
    );
  }

  static int _counter = 0;

  /// معرّف فريد غير متعارض مع معرّفات القوالب المحمّلة (طابع زمني + عدّاد).
  static String nextId(int index, String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${++_counter}_$index';
}
