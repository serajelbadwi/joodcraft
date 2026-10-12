/// شاشة «الدعوات» — المدخل الموعود من شاشة الرئيسية لدعوة أهل القرية إلى
/// فرحك.
///
/// هذه الشاشة **مسكَن مؤقّت** بلغة واضحة: بناء محرّك الدعوات داخل «فرح»
/// (تصميم دعوة باسم كل مدعو ثم إرسالها له) مساحة أكبر من هذه المهمة، وقد
/// ربطنا زرّ «الدعوات» بها الآن كي لا يكون الزرّ صامتاً. تنقّل حقيقي بعدها
/// إلى محرّك الدعوات في JoodCraft إن أردنا الدمج لاحقاً.
library;

import 'package:flutter/material.dart';

import '../../domain/farah_text.dart';
import '../../../village/presentation/village_theme.dart';
import '../farah_theme.dart';
import '../widgets/farah_common.dart';

class FarahInvitationsScreen extends StatelessWidget {
  const FarahInvitationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FarahShell(
      key: const ValueKey<String>('farah-invitations'),
      appBar: const FarahAppBar(title: FarahText.invitationsTitle),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const FarahNote(
            message: FarahText.invitationsBody,
            icon: Icons.mail_outline_rounded,
          ),
          const SizedBox(height: VillageMetrics.space24),
          FilledButton.icon(
            key: const ValueKey<String>('farah-invitations-back'),
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text(FarahText.invitationsCta),
          ),
        ],
      ),
    );
  }
}
