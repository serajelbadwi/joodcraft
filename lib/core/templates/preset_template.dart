import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/template_document.dart';
import 'template_draft.dart';
import 'template_record.dart';

/// المجموعة الدلالية للقالب — أدقّ من تصنيف قاعدة البيانات (شهادة/عقد) وتُستخدم
/// لتنظيم مكتبة القوالب وتصفيتها (شهادات تقدير، عقود عمل، إفادات…).
enum TemplateCollection {
  appreciation('شهادات تقدير', TemplateCategory.certificate,
      Icons.workspace_premium_rounded),
  completion('شهادات إتمام', TemplateCategory.certificate,
      Icons.school_rounded),
  excellence('شهادات تفوق', TemplateCategory.certificate,
      Icons.emoji_events_rounded),
  experience('إفادات خبرة', TemplateCategory.certificate,
      Icons.verified_user_rounded),
  employmentContract('عقود عمل', TemplateCategory.contract,
      Icons.badge_rounded),
  serviceContract('عقود خدمات', TemplateCategory.contract,
      Icons.handshake_rounded);

  const TemplateCollection(this.labelAr, this.category, this.icon);

  final String labelAr;

  /// تصنيف قاعدة البيانات المقابل — يحدّد محرّر الفتح (شهادات/عقود).
  final TemplateCategory category;

  final IconData icon;

  static TemplateCollection? fromLabel(String? value) {
    final String needle = (value ?? '').trim();
    if (needle.isEmpty) return null;
    for (final TemplateCollection item in values) {
      if (item.labelAr == needle) return item;
    }
    return null;
  }
}

/// مصدر القالب داخل المكتبة.
enum TemplateSource {
  /// قالب جاهز محزوم داخل التطبيق — متاح دائماً وبلا شبكة.
  preset('جاهز', Icons.auto_awesome_rounded),

  /// قالب محفوظ على هذا الجهاز (استيراد/حفظ محلي) — يُستعاد أوفلاين.
  local('محلي', Icons.smartphone_rounded),

  /// قالب محفوظ في السحابة (Supabase).
  cloud('سحابي', Icons.cloud_done_rounded);

  const TemplateSource(this.labelAr, this.icon);

  final String labelAr;
  final IconData icon;
}

/// قالب جاهز محزوم في التطبيق (Preset Template).
///
/// لا يُقرأ من الشبكة ولا من ملف خارجي: حمولته JSON مضمّنة في الكود، ولذلك
/// يبقى متاحاً في كل البيئات حتى بلا اتصال. عند الفتح/الحفظ يُترجم إلى
/// [TemplateRecord] أو [TemplateDocument] كأي قالب عادي.
class PresetTemplate {
  PresetTemplate({
    required this.id,
    required this.titleAr,
    required this.descriptionAr,
    required this.collection,
    required this.orientation,
    required List<String> tags,
    required this.layoutJson,
  }) : tags = List<String>.unmodifiable(tags);

  /// معرّف ثابت داخل الفهرس (بلا بادئة السجل).
  final String id;

  final String titleAr;
  final String descriptionAr;
  final TemplateCollection collection;

  /// الاتجاه الافتراضي — مطابق لما في حمولة JSON.
  final PageOrientation orientation;

  /// كلمات مفتاحية للبحث والتصفية.
  final List<String> tags;

  /// حمولة `layout_data` الكاملة (JSON مضمّن).
  final String layoutJson;

  /// المستند الجاهز للتحرير/الطباعة — يُبنى مرة واحدة ويُخزَّن.
  late final TemplateDocument document =
      TemplateDocument.fromJsonString(layoutJson);

  TemplateCategory get category => collection.category;

  /// بادئة معرّفات القوالب الجاهزة داخل سجلات المكتبة.
  static const String recordIdPrefix = 'preset:';

  /// `user_id` رمزي يميّز القوالب الجاهزة عن قوالب المستخدم.
  static const String presetUserId = 'preset';

  String get recordId => '$recordIdPrefix$id';

  static bool isPresetRecordId(String id) => id.startsWith(recordIdPrefix);

  /// مسودة جاهزة لفتح القالب في المحرّر بلا معرّف سجل (حفظ كقالب جديد).
  TemplateDraft toDraft() => TemplateDraft(
        title: titleAr,
        category: category,
        document: document,
      );

  /// تحويل القالب الجاهز إلى سجل قالب عادي (تُوحَّد كل مصادر المكتبة).
  TemplateRecord toRecord() => TemplateRecord(
        id: recordId,
        userId: presetUserId,
        title: titleAr,
        category: category,
        orientation: orientation,
        layoutData: document.toJson(),
        isPublic: true,
      );

  /// هل يطابق نص البحث (العنوان أو الوصف أو الوسوم)؟
  bool matches(String needle) {
    final String query = needle.trim().toLowerCase();
    if (query.isEmpty) return true;
    return titleAr.toLowerCase().contains(query) ||
        descriptionAr.toLowerCase().contains(query) ||
        tags.any((String tag) => tag.toLowerCase().contains(query));
  }
}
