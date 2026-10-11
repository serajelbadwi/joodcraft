/// نصوص قوالب الدعوات المترجمة — مصدر واحد يشاركانِه اللوحة الجانبية والشاشة
/// (فلا يختلف تسمية قالب بين موضعين).
library;

import 'package:flutter/widgets.dart';

import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/templates/invitation_gallery.dart';
import '../../../../core/templates/invitation_group.dart';
import '../../../../core/templates/invitation_size.dart';

/// عنوان القالب بلغة الواجهة (أو العربي احتياطاً).
String invitationTitleText(BuildContext context, InvitationTemplate template) {
  return switch (template.titleKey) {
    'invRamadan1Title' =>
      context.l10n?.invRamadan1Title ?? template.titleAr,
    'invRamadan2Title' =>
      context.l10n?.invRamadan2Title ?? template.titleAr,
    'invEid1Title' => context.l10n?.invEid1Title ?? template.titleAr,
    'invEid2Title' => context.l10n?.invEid2Title ?? template.titleAr,
    'invWedding1Title' =>
      context.l10n?.invWedding1Title ?? template.titleAr,
    'invWedding2Title' =>
      context.l10n?.invWedding2Title ?? template.titleAr,
    'invWedding3Title' =>
      context.l10n?.invWedding3Title ?? template.titleAr,
    _ => template.titleAr,
  };
}

/// وصف المقاس بلغة الواجهة.
String invitationSizeText(BuildContext context, InvitationSize size) {
  return switch (size.labelKey) {
    'invSizeA6Portrait' =>
      context.l10n?.invSizeA6Portrait ?? size.labelAr,
    'invSizeA6Landscape' =>
      context.l10n?.invSizeA6Landscape ?? size.labelAr,
    'invSizeSquare148' => context.l10n?.invSizeSquare148 ?? size.labelAr,
    'invSizeA5Folded' => context.l10n?.invSizeA5Folded ?? size.labelAr,
    'invSizeInstagramSquare' =>
      context.l10n?.invSizeInstagramSquare ?? size.labelAr,
    'invSizeInstagramPortrait' =>
      context.l10n?.invSizeInstagramPortrait ?? size.labelAr,
    'invSizeInstagramStory' =>
      context.l10n?.invSizeInstagramStory ?? size.labelAr,
    'invSizeWhatsAppStatus' =>
      context.l10n?.invSizeWhatsAppStatus ?? size.labelAr,
    'invSizeFacebookPost' =>
      context.l10n?.invSizeFacebookPost ?? size.labelAr,
    _ => size.labelAr,
  };
}

/// اسم المجموعة (رمضان/عيد/زفاف) بلغة الواجهة.
String invitationGroupText(BuildContext context, InvitationGroup group) {
  return switch (group.labelKey) {
    'invCategoryRamadan' => context.l10n?.invCategoryRamadan ?? group.labelAr,
    'invCategoryEid' => context.l10n?.invCategoryEid ?? group.labelAr,
    'invCategoryWedding' =>
      context.l10n?.invCategoryWedding ?? group.labelAr,
    _ => group.labelAr,
  };
}
