import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/template_document.dart';
import 'template_draft.dart';
import 'template_localization.dart';
import 'template_record.dart';

/// المجموعة الدلالية للقالب — أدقّ من تصنيف قاعدة البيانات (شهادة/عقد) وتُستخدم
/// لتنظيم مكتبة القوالب وتصفيتها (شهادات تقدير، عقود عمل، إفادات…).
enum TemplateCollection {
  appreciation('شهادات تقدير', TemplateCategory.certificate,
      Icons.workspace_premium_rounded),
  completion('دورات وإتمام', TemplateCategory.certificate,
      Icons.school_rounded),
  excellence('شهادات تفوق', TemplateCategory.certificate,
      Icons.emoji_events_rounded),
  experience('إفادات ونصوص', TemplateCategory.certificate,
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
    required String layoutJson,
  })  : _layoutJson = layoutJson,
        _document = null,
        tags = List<String>.unmodifiable(tags);

  /// نسخة تُبنى من [TemplateDocument] **برمجياً** بدل JSON نصّي.
  ///
  /// تُستخدم لقوالب المعرض المولَّدة بالكود (حيث يُبنى المستند بعناصر مكتوبة
  /// النوع بلا مخاطرة أخطاء JSON اليدوي)، بينما يبقى المسار النصّي للقوالب
  /// الأصلية كما هو بلا أي تغيير.
  PresetTemplate.fromDocument({
    required this.id,
    required this.titleAr,
    required this.descriptionAr,
    required this.collection,
    required this.orientation,
    required List<String> tags,
    required TemplateDocument document,
  })  : _layoutJson = null,
        _document = document,
        tags = List<String>.unmodifiable(tags);

  /// معرّف ثابت داخل الفهرس (بلا بادئة السجل).
  final String id;

  final String titleAr;
  final String descriptionAr;
  final TemplateCollection collection;

  /// الاتجاه الافتراضي — مطابق لما في حمولة JSON.
  final PageOrientation orientation;

  /// كلمات مفتاحية للبحث والتصفية.
  final List<String> tags;

  /// الحمولة النصّية (JSON) إن بُني القالب منها، وإلا `null` للبناء البرمجي.
  final String? _layoutJson;

  /// المستند المزوَّد مباشرةً في البناء البرمجي إن وُجد.
  final TemplateDocument? _document;

  /// المستند الجاهز للتحرير/الطباعة — يُبنى مرة واحدة ويُخزَّن.
  late final TemplateDocument document =
      _document ?? TemplateDocument.fromJsonString(_layoutJson!);

  TemplateCategory get category => collection.category;

  /// بادئة معرّفات القوالب الجاهزة داخل سجلات المكتبة.
  static const String recordIdPrefix = 'preset:';

  /// `user_id` رمزي يميّز القوالب الجاهزة عن قوالب المستخدم.
  static const String presetUserId = 'preset';

  String get recordId => '$recordIdPrefix$id';

  static bool isPresetRecordId(String id) => id.startsWith(recordIdPrefix);

  /// مستند القالب بمحتوى اللغة المطلوبة.
  ///
  /// للعربية (أو أي لغة بلا حزمة) يُعاد المستند الأصلي كما هو؛ ولغات مثل
  /// الإنجليزية والفرنسية تُترجم النصوص الثابتة وتُستبدل البيانات التجريبية
  /// بأسماء وصيغ البلد — بلا أي تغيير في الهندسة أو الألوان.
  TemplateDocument documentFor(String? languageCode) =>
      TemplateLocalization.localize(document, languageCode);

  /// عنوان القالب باللغة المطلوبة (مع الرجوع إلى العنوان العربي).
  String titleFor(String? languageCode) =>
      TemplateLocalization.text(languageCode, titleAr);

  /// مسودة جاهزة لفتح القالب في المحرّر بلا معرّف سجل (حفظ كقالب جديد).
  TemplateDraft toDraft({String? languageCode}) => TemplateDraft(
        title: titleFor(languageCode),
        category: category,
        document: documentFor(languageCode),
      );

  /// تحويل القالب الجاهز إلى سجل قالب عادي (تُوحَّد كل مصادر المكتبة).
  TemplateRecord toRecord({String? languageCode}) => TemplateRecord(
        id: recordId,
        userId: presetUserId,
        title: titleFor(languageCode),
        category: category,
        orientation: orientation,
        layoutData: documentFor(languageCode).toJson(),
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
