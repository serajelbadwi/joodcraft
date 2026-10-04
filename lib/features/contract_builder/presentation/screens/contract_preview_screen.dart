import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/widgets/pdf_template_preview.dart';

/// محرّك العقود — معاينة العقد (A4 رأسي) وطباعته وتصديره.
class ContractPreviewScreen extends StatelessWidget {
  const ContractPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PdfTemplatePreview(
      templateAssetPath: AppAssets.sampleContractTemplate,
      exportFileName: 'joodcraft-contract.pdf',
      dataPanelTitle:
          context.l10n?.cbContractDataTitle ?? 'بيانات العقد (تجريبية)',
    );
  }
}
