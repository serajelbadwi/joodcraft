import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/widgets/pdf_template_preview.dart';

/// محرّك الشهادات — معاينة الشهادة (A4 أفقي) وطباعتها وتصديرها.
///
/// في المرحلة الثالثة سيُستبدل القالب النموذجي بمحرر القوالب البصري، وتبقى
/// هذه الشاشة كما هي لأنها تعتمد على أي `layout_data` صالح.
class CertificatePreviewScreen extends StatelessWidget {
  const CertificatePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PdfTemplatePreview(
      templateAssetPath: AppAssets.sampleCertificateTemplate,
      exportFileName: 'joodcraft-certificate.pdf',
      dataPanelTitle: 'بيانات المستفيد (تجريبية)',
    );
  }
}
