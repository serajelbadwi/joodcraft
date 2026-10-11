import 'package:flutter/material.dart';

import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/templates/invitation_gallery.dart';
import '../../../../core/templates/invitation_group.dart';
import '../l10n_labels.dart';

/// لوحة جانبية لاختيار قالب دعوة داخل «محرك الدعوات».
///
/// **مهمَل — غير مستدعى.** أُزيلت من `InvitationsEditorScreen` لأنها كانت
/// مكرِّرة (القوالب نفسها تُفتح من المكتبة) وكانت تقتطع 268px من عرض
/// المحرّر. الملف محفوظ هنا كمرجع ولا يُبنى من أي مسار.
///
/// تُعرض المجموعات الثلاث (رمضان/عيد/زفاف) كأقسام، وتحت كلٍّ قوالبه. الضغط
/// على قالب يفتحه **تبويباً جديداً** في المحرّر المجاور (نفس آلّة «اختر قالباً
/// من المكتبة» في محرّكي الشهادات والعقود) — فلا يُعاد بناء المحرّر.
class InvitationPickerPanel extends StatelessWidget {
  const InvitationPickerPanel({
    super.key,
    required this.selectedId,
    required this.onSelect,
  });

  /// معرّف القالب المختار حالياً (أو `null` قبل أي اختيار).
  final String? selectedId;

  /// يُستدعى عند اختيار قالب.
  final ValueChanged<InvitationTemplate> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 268,
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: AppColors.navyWash,
              border: Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.redeem_rounded,
                    size: 18, color: AppColors.navy),
                const SizedBox(width: AppTheme.space8),
                Expanded(
                  child: Text(
                    context.l10n?.navInvitationTemplates ??
                        'قوالب الدعوات',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.space8),
              children: <Widget>[
                for (final InvitationGroup group in InvitationGroup.values)
                  _GroupSection(
                    group: group,
                    templates:
                        InvitationTemplates.forGroup(group),
                    selectedId: selectedId,
                    onSelect: onSelect,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupSection extends StatelessWidget {
  const _GroupSection({
    required this.group,
    required this.templates,
    required this.selectedId,
    required this.onSelect,
  });

  final InvitationGroup group;
  final List<InvitationTemplate> templates;
  final String? selectedId;
  final ValueChanged<InvitationTemplate> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space4,
            vertical: AppTheme.space8,
          ),
          child: Row(
            children: <Widget>[
              Icon(group.icon, size: 15, color: AppColors.inkMuted),
              const SizedBox(width: AppTheme.space6),
              Text(
                invitationGroupText(context, group),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
        for (final InvitationTemplate template in templates)
          _TemplateTile(
            template: template,
            selected: template.id == selectedId,
            onTap: () => onSelect(template),
          ),
        const Divider(height: AppTheme.space12),
      ],
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  final InvitationTemplate template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.space8),
          decoration: BoxDecoration(
            color: selected ? AppColors.goldSoft : AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(
              color: selected ? AppColors.goldDeep : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                invitationTitleText(context, template),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.ink : AppColors.ink,
                ),
              ),
              const SizedBox(height: AppTheme.space2),
              Text(
                invitationSizeText(context, template.size),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
