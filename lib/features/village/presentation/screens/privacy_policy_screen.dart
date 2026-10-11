/// صفحة سياسة الخصوصية — الامتثال لقانون حماية البيانات الشخصية المصري
/// رقم 151 لسنة 2020: إخطار صاحب البيانات بما يُجمع منه ولماذا وكيف يُحمى،
/// وحقّه في الحذف والاطّلاع، مع قسم «معالجة البيانات» الذي يشرح معالجتها
/// ومدّة التخزين وطريقة حذفها.
///
/// تُفتح من رابط الموافقة في نموذج التسجيل (مفتاح `village-privacy-policy`)
/// وتعود بالزر «رجوع» إلى النموذج دون فقدان ما فيه.
library;

import 'package:flutter/material.dart';

import '../../domain/village_legal.dart';
import '../widgets/village_legal_page.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VillageLegalPage(
      key: const ValueKey<String>('village-privacy-policy'),
      title: VillageLegal.privacyTitle,
      version: VillageLegal.privacyVersion,
      lead: VillageLegal.privacyLead,
      sections: const <VillageLegalSection>[
        VillageLegalSection(
          title: VillageLegal.privacyCollectedTitle,
          body: VillageLegal.privacyCollectedBody,
        ),
        VillageLegalSection(
          title: VillageLegal.privacyPurposeTitle,
          body: VillageLegal.privacyPurposeBody,
        ),
        VillageLegalSection(
          title: VillageLegal.privacyProcessingTitle,
          body: VillageLegal.privacyProcessingBody,
        ),
        VillageLegalSection(
          title: VillageLegal.privacyRetentionTitle,
          body: VillageLegal.privacyRetentionBody,
        ),
        VillageLegalSection(
          title: VillageLegal.privacyDeletionTitle,
          body: VillageLegal.privacyDeletionBody,
        ),
        VillageLegalSection(
          title: VillageLegal.privacySharingTitle,
          body: VillageLegal.privacySharingBody,
        ),
        VillageLegalSection(
          title: VillageLegal.privacySecurityTitle,
          body: VillageLegal.privacySecurityBody,
        ),
        VillageLegalSection(
          title: VillageLegal.privacyRightsTitle,
          body: VillageLegal.privacyRightsBody,
        ),
        VillageLegalSection(
          title: VillageLegal.contactSectionTitle,
          body: VillageLegal.contactBody,
        ),
      ],
    );
  }
}
