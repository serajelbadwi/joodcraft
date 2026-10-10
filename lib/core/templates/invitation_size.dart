import 'package:flutter/foundation.dart' show immutable;

import '../constants/app_constants.dart';
import '../models/template_document.dart';
import '../models/template_element.dart';
import 'project_preset.dart';

/// مقاسات الدعوات الجاهزة — طباعة (ملم) وسوشيال ميديا (بكسل).
///
/// لكل مقاس هندسته الصريحة ومفتاح ترجمته في arb (`invSize*`). المقاسات
/// الرقمية تُبنى بدقّة الشاشة (72 نقطة/بوصة) ونمط RGB، والمطبوعة بدقّة 300
/// نقطة/بوصة ونمط CMYK — نفس اصطلاح [NewDocumentSpec] حتى لا يختلف مصدر
/// الحقيقة بين المسارين.
@immutable
class InvitationSize {
  const InvitationSize({
    required this.id,
    required this.width,
    required this.height,
    required this.unit,
    required this.labelKey,
    required this.labelAr,
    this.isDigital = false,
  });

  /// معرّف ثابت — يطابق معرّف المقاس في [ProjectPresetCatalog].
  final String id;

  /// العرض النهائي بوحدة [unit] كما يراه المستخدم.
  final double width;

  /// الارتفاع النهائي بوحدة [unit].
  final double height;

  final MeasurementUnit unit;

  /// مفتاح الترجمة في arb (مثل `invSizeInstagramStory`).
  final String labelKey;

  /// الاسم العربي الاحتياطي.
  final String labelAr;

  /// هل المقاس رقمي (للشاشة) لا مطبوع؟
  final bool isDigital;

  PageOrientation get orientation =>
      width > height ? PageOrientation.landscape : PageOrientation.portrait;

  /// أبعاد مصوغة كما تعرضها الواجهة.
  String get dimensionsLabel => unit == MeasurementUnit.px
      ? '${width.round()}×${height.round()} px'
      : '${ProjectPreset.formatDimension(width)}×'
          '${ProjectPreset.formatDimension(height)} mm';

  /// دقّة البناء المناسبة للمقاس (الشاشة 72، الطباعة 300).
  int get buildDpi => isDigital ? NewDocumentSpecDpi.screen : 300;

  /// مستند فارغ بهذه الهندسة — تُبنى عليه عناصر القالب.
  TemplateDocument toDocument() {
    final bool landscape = width > height;
    return TemplateDocument(
      elements: const <TemplateElement>[],
      orientation:
          landscape ? PageOrientation.landscape : PageOrientation.portrait,
      customPageSize: CustomPageSize(
        width: landscape ? height : width,
        height: landscape ? width : height,
        unit: unit,
      ),
      dpi: buildDpi,
      resolutionUnit: ResolutionUnit.ppi,
      colorMode: isDigital ? DocumentColorMode.rgb : DocumentColorMode.cmyk,
    );
  }

  /// المقاس القياسي في فهرس المشاريع (يظهر في «مستند جديد»).
  ProjectPreset? get preset => ProjectPresetCatalog.byId(id);
}

/// ثوابت الدقّة (مرتبطة بـ [NewDocumentSpec] بلا استيراد مباشر).
abstract final class NewDocumentSpecDpi {
  const NewDocumentSpecDpi._();

  /// دقّة الشاشة والويب.
  static const int screen = 72;
}

/// مقاسات الدعوات التسعة — الطباعة أولاً ثم السوشيال ميديا.
abstract final class InvitationSizes {
  const InvitationSizes._();

  static const InvitationSize a6Portrait = InvitationSize(
    id: 'invite.a6.portrait',
    width: 105,
    height: 148,
    unit: MeasurementUnit.mm,
    labelKey: 'invSizeA6Portrait',
    labelAr: 'A6 رأسي (105×148 mm)',
  );

  static const InvitationSize a6Landscape = InvitationSize(
    id: 'invite.a6.landscape',
    width: 148,
    height: 105,
    unit: MeasurementUnit.mm,
    labelKey: 'invSizeA6Landscape',
    labelAr: 'A6 أفقي (148×105 mm)',
  );

  static const InvitationSize square148 = InvitationSize(
    id: 'invite.square148',
    width: 148,
    height: 148,
    unit: MeasurementUnit.mm,
    labelKey: 'invSizeSquare148',
    labelAr: 'مربع للطباعة (148×148 mm)',
  );

  static const InvitationSize a5Folded = InvitationSize(
    id: 'invite.a5.folded',
    width: 105,
    height: 148,
    unit: MeasurementUnit.mm,
    labelKey: 'invSizeA5Folded',
    labelAr: 'A5 مطوي (105×148 mm)',
  );

  static const InvitationSize instagramSquare = InvitationSize(
    id: 'invite.instagram.square',
    width: 1080,
    height: 1080,
    unit: MeasurementUnit.px,
    isDigital: true,
    labelKey: 'invSizeInstagramSquare',
    labelAr: 'Instagram مربع (1080×1080)',
  );

  static const InvitationSize instagramPortrait = InvitationSize(
    id: 'invite.instagram.portrait',
    width: 1080,
    height: 1350,
    unit: MeasurementUnit.px,
    isDigital: true,
    labelKey: 'invSizeInstagramPortrait',
    labelAr: 'Instagram طولي (1080×1350)',
  );

  static const InvitationSize instagramStory = InvitationSize(
    id: 'invite.instagram.story',
    width: 1080,
    height: 1920,
    unit: MeasurementUnit.px,
    isDigital: true,
    labelKey: 'invSizeInstagramStory',
    labelAr: 'Instagram Story (1080×1920)',
  );

  static const InvitationSize whatsappStatus = InvitationSize(
    id: 'invite.whatsapp.status',
    width: 1080,
    height: 1920,
    unit: MeasurementUnit.px,
    isDigital: true,
    labelKey: 'invSizeWhatsAppStatus',
    labelAr: 'WhatsApp Status (1080×1920)',
  );

  static const InvitationSize facebookPost = InvitationSize(
    id: 'invite.facebook.post',
    width: 1200,
    height: 630,
    unit: MeasurementUnit.px,
    isDigital: true,
    labelKey: 'invSizeFacebookPost',
    labelAr: 'Facebook Post (1200×630)',
  );

  /// كل المقاسات بترتيب العرض (طباعة ثم سوشيال).
  static const List<InvitationSize> all = <InvitationSize>[
    a6Portrait,
    a6Landscape,
    square148,
    a5Folded,
    instagramSquare,
    instagramPortrait,
    instagramStory,
    whatsappStatus,
    facebookPost,
  ];

  static InvitationSize? byId(String? id) {
    for (final InvitationSize size in all) {
      if (size.id == id) return size;
    }
    return null;
  }
}
