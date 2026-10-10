import '../constants/app_constants.dart';
import '../models/template_document.dart';
import 'preset_template.dart';
import 'template_draft.dart';
import 'template_record.dart';

/// مدخل موحّد في مكتبة القوالب: قالب جاهز أو محلي أو سحابي.
///
/// توحيد المصادر الثلاثة خلف واجهة واحدة يجعل البحث والتصفية والترتيب منطقاً
/// واحداً، وتتباين الإجراءات المتاحة حسب [source] فقط.
class TemplateLibraryEntry {
  const TemplateLibraryEntry({
    required this.record,
    required this.source,
    this.collection,
    this.preset,
  });

  final TemplateRecord record;
  final TemplateSource source;

  /// المجموعة الدلالية (متاحة للقوالب الجاهزة دائماً).
  final TemplateCollection? collection;

  /// القالب الجاهز الأصلي (إن كان المصدر جاهزاً).
  final PresetTemplate? preset;

  bool get isPreset => source == TemplateSource.preset;
  bool get isLocal => source == TemplateSource.local;
  bool get isCloud => source == TemplateSource.cloud;

  String get id => record.id;
  String get title => record.title;
  TemplateCategory get category => record.category;
  PageOrientation get orientation => record.orientation;
  String? get presetId => preset?.id;

  TemplateDocument toDocument() => record.toDocument();

  /// مسودة لفتح القالب في المحرّر بلا معرّف سجل (حفظ كقالب جديد).
  ///
  /// [languageCode] يترجم محتوى القوالب **الجاهزة** فقط (شهادات وعقود) إلى
  /// نصوص البلد؛ القوالب المحفوظة تبقى كما حرّرها المستخدم.
  TemplateDraft toDraft({String? languageCode}) {
    final PresetTemplate? preset = this.preset;
    if (preset != null) return preset.toDraft(languageCode: languageCode);
    return TemplateDraft(
      title: title,
      category: category,
      document: toDocument(),
    );
  }

  /// سجل القالب بمحتوى اللغة المطلوبة (يُستخدم في التوليد الجماعي).
  TemplateRecord toRecord({String? languageCode}) {
    final PresetTemplate? preset = this.preset;
    if (preset == null) return record;
    return preset.toRecord(languageCode: languageCode);
  }

  /// هل يطابق عامل تصفية المجموعة؟
  ///
  /// القوالب المحفوظة ليس لها مجموعة صريحة، فتُطابَق بلا تصنيفها (شهادة/عقد)
  /// حتى لا تختفي عند اختيار مجموعة قريبة منها.
  bool matchesCollection(TemplateCollection? filter) {
    if (filter == null) return true;
    final TemplateCollection? own = collection;
    if (own != null) return own == filter;
    return category == filter.category;
  }

  /// هل يطابق نص البحث (العنوان أو وصف القالب الجاهز/وسومه)؟
  bool matchesQuery(String needle) {
    final String query = needle.trim().toLowerCase();
    if (query.isEmpty) return true;
    final PresetTemplate? preset = this.preset;
    if (preset != null) return preset.matches(query);
    return title.toLowerCase().contains(query);
  }
}
