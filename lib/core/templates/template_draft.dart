import '../constants/app_constants.dart';
import '../models/template_document.dart';

/// قالب غير محفوظ يُفتح في المحرّر (يأتي من مكتبة القوالب الجاهزة).
///
/// يختلف عن `TemplateRecord` بأنه **بلا معرّف سجل**، فيحفظه المحرّر كقالب
/// جديد عند أول حفظ بدل تحديث سجل قائم غير موجود.
class TemplateDraft {
  const TemplateDraft({
    required this.title,
    required this.category,
    required this.document,
  });

  final String title;
  final TemplateCategory category;
  final TemplateDocument document;
}
