import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/editor/widgets/template_editor_view.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/templates/template_draft.dart';
import '../../../../core/templates/template_record.dart';
import '../../../../core/templates/template_repository.dart';

/// محرّر قوالب الشهادات — A4 **أفقي** بمحرك التحرير المركزي.
///
/// الشاشة طبقة رقيقة فوق [TemplateEditorView]: كل منطق التحرير والحفظ مشترك
/// مع محرّر العقود، والفرق هنا هو التصنيف واتجاه الورقة والقالب الابتدائي.
class CertificateTemplateEditorScreen extends StatelessWidget {
  const CertificateTemplateEditorScreen({
    super.key,
    this.repository,
    this.record,
    this.draft,
  });

  /// مستودع القوالب (يُحقن من الموجّه) — `null` إن لم يُربط Supabase.
  final TemplateRepository? repository;

  /// قالب محفوظ يُفتح مباشرةً من مكتبة القوالب (بدل القالب النموذجي).
  final TemplateRecord? record;

  /// قالب غير محفوظ (من المكتبة الجاهزة) يُفتح للحفظ كقالب جديد.
  final TemplateDraft? draft;

  @override
  Widget build(BuildContext context) {
    final TemplateDraft? draft = this.draft;
    if (draft != null) {
      return TemplateEditorView(
        category: draft.category,
        initialTemplateAsset: AppAssets.sampleCertificateTemplate,
        exportFileName: 'joodcraft-certificate.pdf',
        repository: repository,
        title: draft.title,
        document: draft.document,
      );
    }

    final TemplateRecord? record = this.record;
    return TemplateEditorView(
      category: TemplateCategory.certificate,
      initialTemplateAsset: AppAssets.sampleCertificateTemplate,
      exportFileName: 'joodcraft-certificate.pdf',
      repository: repository,
      title: record?.title ??
          (context.l10n?.cbNewCertificateTitle ?? 'شهادة جديدة'),
      document: record?.toDocument(),
      initialRecordId: record?.id,
    );
  }
}
