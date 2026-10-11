/// صفحة شروط الاستخدام — ما يُسمح به في صفحة القرية ومسؤوليّات المُسجَّل
/// وحقوق المكتب في تعديل الشروط، وكلّها متسقة مع سياسة الخصوصية وقانون
/// حماية البيانات الشخصية المصري 151/2020.
///
/// تُفتح من رابط الموافقة في نموذج التسجيل (مفتاح `village-terms`) وتعود
/// بالزر «رجوع» إلى النموذج دون فقدان ما فيه.
library;

import 'package:flutter/material.dart';

import '../../domain/village_legal.dart';
import '../widgets/village_legal_page.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VillageLegalPage(
      key: const ValueKey<String>('village-terms'),
      title: VillageLegal.termsTitle,
      version: VillageLegal.termsVersion,
      lead: VillageLegal.termsLead,
      sections: const <VillageLegalSection>[
        VillageLegalSection(
          title: VillageLegal.termsUsageTitle,
          body: VillageLegal.termsUsageBody,
        ),
        VillageLegalSection(
          title: VillageLegal.termsAccuracyTitle,
          body: VillageLegal.termsAccuracyBody,
        ),
        VillageLegalSection(
          title: VillageLegal.termsNoDuplicateTitle,
          body: VillageLegal.termsNoDuplicateBody,
        ),
        VillageLegalSection(
          title: VillageLegal.termsAccountTitle,
          body: VillageLegal.termsAccountBody,
        ),
        VillageLegalSection(
          title: VillageLegal.termsChangesTitle,
          body: VillageLegal.termsChangesBody,
        ),
        VillageLegalSection(
          title: VillageLegal.contactSectionTitle,
          body: VillageLegal.contactBody,
        ),
      ],
    );
  }
}
