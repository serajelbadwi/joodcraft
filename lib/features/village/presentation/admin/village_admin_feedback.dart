/// رسائل اللوحة الموحّدة — امتداد على [BuildContext] فوق `UiFeedback`.
///
/// تجميع تحويل الاستثناء إلى رسالة عربية هنا يمنع تكرار `try/catch` المتشابه
/// في الشاشات الست، ويضمن أن أي خطأ غير متوقّع يظهر بالنص العام لا برموز
/// خام. ويُعاد تصدير `UiFeedback` معه، فتصبح الشاشة سطر استيراد واحد تحصل
/// بها على `showAdminError` و`showSuccess` و`showError` معاً.
library;

import 'package:flutter/material.dart';

import '../../../../core/utils/ui_feedback.dart';
import '../../data/village_repository.dart';
import '../../domain/village_admin_text.dart';

export '../../../../core/utils/ui_feedback.dart';

extension VillageAdminFeedback on BuildContext {
  /// رسالة خطأ عربية لاستثناء عمليات اللوحة.
  void showAdminError(Object error) => showError(adminErrorText(error));
}

/// نصّ الخطأ العربي لاستثناء عمليات اللوحة.
String adminErrorText(Object error) =>
    error is VillageException ? error.message : VillageAdminText.genericError;
