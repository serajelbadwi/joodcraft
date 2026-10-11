import 'package:flutter/material.dart';

import '../../../../core/templates/invitation_gallery.dart';
import '../../../../core/templates/template_draft.dart';
import '../../../../core/templates/template_record.dart';
import '../../../../core/templates/template_repository.dart';
import '../../../certificate_builder/presentation/screens/template_editor_screen.dart';

/// «محرك الدعوات» — **نفس** محرّر الشهادات والعقود، وبعرضها كاملاً.
///
/// لماذا هذه الشاشة بدل شاشة عرض نماذج منفصلة؟ كان محرك الدعوات يفتح
/// `InvitationsScreen` (قائمة نماذج فقط) بينما يفتح محركان آخران
/// `CertificateTemplateEditorScreen` بمحرّره الكامل. هنا يُعاد التوحيد:
///
/// * المحرّك هو `CertificateTemplateEditorScreen` نفسه — نفس الأدوات والحفظ
///   والتصدير ونظام التبويبات المتعددة، **على كامل عرض المساحة**.
/// * القوالب السبعة تُفتح من **المكتبة** (كما في محركي الشهادات والعقود):
///   مسار `/invitations` يقبل `record`/`draft`/`invitation` من المكتبة، وكلٌّ
///   يُفتح تبويباً في المحرّر.
///
/// لماذا أُزيلت لوحة الاختيار الجانبية (`InvitationPickerPanel`، عرض 268px)؟
/// كانت **مكرِّرة**: القوالب نفسها متاحة من المكتبة، وكانت تقتطع عموداً
/// كاملاً من عرض المحرّر بلا فائدة تُضاف. الملف محفوظ في مكانه غير مستدعى.
///
/// `InvitationsScreen` (شاشة العرض القديمة) محفوظ بلا استدعاء من هذا المسار.
class InvitationsEditorScreen extends StatefulWidget {
  const InvitationsEditorScreen({
    super.key,
    this.repository,
    this.record,
    this.draft,
    this.invitation,
  });

  /// مستودع القوالب نفسه الذي يستخدمه محرّك الشهادات.
  final TemplateRepository? repository;

  /// سجل قالب ممرَّر من المكتبة (يتقدّم على كل ما سواه).
  final TemplateRecord? record;

  /// مسودة جاهزة (مثل مكتبة القوالب أو «مستند جديد»).
  final TemplateDraft? draft;

  /// قالب دعوة مختار من لوحة المكتبة — يُترجم إلى مسوّدة.
  final InvitationTemplate? invitation;

  @override
  State<InvitationsEditorScreen> createState() =>
      _InvitationsEditorScreenState();
}

class _InvitationsEditorScreenState extends State<InvitationsEditorScreen> {
  /// ذاكرة مسوّدات: إعادة فتح نفس القالب لا تُعيد بناء مسوّدة مطابقة.
  final Map<String, TemplateDraft> _draftCache = <String, TemplateDraft>{};

  /// المسودة التي تُمرَّر للمحرّر — بأولوية واضحة:
  /// 1. قالب الدعوة الممرَّر من المكتبة (يتقدّم على كل ما سواه).
  /// 2. مسوّدة المكتبة الممرَّرة عبر المسار.
  /// 3. السجل وحده (`null` هنا) — يبقى التبويب الأول كما هو.
  /// 4. أوّل قالب دعوة جاهز كي يفتح المحرّك على محتوى لا فراغ.
  TemplateDraft? get _editorDraft {
    final InvitationTemplate? invitation = widget.invitation;
    if (invitation != null) return _draftFor(invitation);
    final TemplateDraft? draft = widget.draft;
    if (draft != null) return draft;
    if (widget.record != null) return null;
    return _draftFor(InvitationTemplates.all.first);
  }

  /// السجل يُمرَّر للمحرّر ما لم يأتِ المستخدم بقالب دعوة من المكتبة — عندها
  /// يسقط السجل من المعاملات كي لا يلتقط `didUpdateWidget` التبويب القديم
  /// (فحص التكرار) ويمنع فتح مسودة القالب كتبويب جديد.
  bool get _passRecord => widget.record != null && widget.invitation == null;

  TemplateDraft _draftFor(InvitationTemplate template) =>
      _draftCache.putIfAbsent(template.id, () => template.toPreset().toDraft());

  @override
  Widget build(BuildContext context) {
    // بلا `Row` ولا لوحة جانبية: المحرّر يأخذ المساحة كاملة.
    return CertificateTemplateEditorScreen(
      // مفتاح ثابت: نفس الحالة تبقي المحرّر حياً، وقوالب المكتبة تمرّ
      // عبر `didUpdateWidget` فيُفتح تبويب جديد (لا إعادة بناء).
      key: const ValueKey<String>('invitations_workspace'),
      repository: widget.repository,
      record: _passRecord ? widget.record : null,
      draft: _editorDraft,
    );
  }
}
