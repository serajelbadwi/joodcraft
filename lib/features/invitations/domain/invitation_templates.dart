import 'dart:math' as math;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/template_document.dart';
import '../../../../core/models/template_element.dart';
import '../../../../core/pdf/pdf_font_catalog.dart';
import '../../../../core/templates/preset_template.dart';
import 'invitation_group.dart';
import 'invitation_size.dart';

/// معرّف عنصر اسم صاحب الدعوة (`{{الاسم}}`) داخل كل القوالب.
const String invitationNameElementId = 'recipient_name';

/// معرّف عنصر نص الرسالة القابل للتعديل.
const String invitationMessageElementId = 'message';

/// قالب دعوة واحد: هندسة جاهزة + مجموعة + مقاس + رسالة افتراضية.
class InvitationTemplate {
  const InvitationTemplate({
    required this.id,
    required this.group,
    required this.size,
    required this.titleAr,
    required this.titleKey,
    required this.descriptionAr,
    required this.tags,
    required this.message,
    required this.document,
  });

  final String id;
  final InvitationGroup group;
  final InvitationSize size;
  final String titleAr;
  final String titleKey;
  final String descriptionAr;
  final List<String> tags;
  final String message;
  final TemplateDocument document;

  /// المجموعة الدلالية في مكتبة القوالب.
  TemplateCollection get collection => switch (group) {
        InvitationGroup.ramadan => TemplateCollection.ramadan,
        InvitationGroup.eid => TemplateCollection.eid,
        InvitationGroup.wedding => TemplateCollection.wedding,
      };

  TemplateCategory get category => TemplateCategory.certificate;

  PageOrientation get orientation => document.orientation;

  bool get isDigital => size.isDigital;

  /// الاسم الكامل بعد التعقيم ليس مطلوباً هنا — الاسم العربي هو المعرّف.
  bool matches(String needle) {
    final String query = needle.trim().toLowerCase();
    if (query.isEmpty) return true;
    return titleAr.toLowerCase().contains(query) ||
        descriptionAr.toLowerCase().contains(query) ||
        group.labelAr.contains(query) ||
        tags.any((String tag) => tag.toLowerCase().contains(query));
  }

  /// المستند بعد استبدال نص الرسالة (بقية العناصر كما هي).
  TemplateDocument withMessage(String nextMessage) {
    return document.copyWith(
      elements: <TemplateElement>[
        for (final TemplateElement element in document.elements)
          if (element is TextElement && element.id == invitationMessageElementId)
            element.copyWith(text: nextMessage)
          else
            element,
      ],
    );
  }

  /// تحويل إلى قالب مكتبة جاهز (`PresetTemplate`) بنفس الهوية.
  PresetTemplate toPreset() => PresetTemplate.fromDocument(
        id: id,
        titleAr: titleAr,
        descriptionAr: descriptionAr,
        collection: collection,
        orientation: orientation,
        tags: tags,
        document: document,
      );
}

/// القوالب السبعة الجاهزة + أدوات البناء المشتركة.
abstract final class InvitationTemplates {
  const InvitationTemplates._();

  /// القيمة التجريبية الوحيدة المطلوبة: حقل الاسم.
  static const Map<String, String> sampleData = <String, String>{
    'الاسم': 'أحمد محمد',
  };

  /// كل القوالب بترتيب العرض: رمضان، عيد، زفاف.
  static const List<InvitationTemplate> all = <InvitationTemplate>[
    ramadanClassic,
    ramadanStory,
    eidClassic,
    eidStory,
    weddingClassic,
    weddingModern,
    weddingStory,
  ];

  static List<InvitationTemplate> forGroup(InvitationGroup group) => all
      .where((InvitationTemplate template) => template.group == group)
      .toList(growable: false);

  static InvitationTemplate? byId(String? id) {
    for (final InvitationTemplate template in all) {
      if (template.id == id) return template;
    }
    return null;
  }

  /// نفس القوالب جاهزة للتسجيل في فهرس المكتبة.
  static List<PresetTemplate> get presets => <PresetTemplate>[
        for (final InvitationTemplate template in all) template.toPreset(),
      ];
}
