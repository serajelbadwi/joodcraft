/// نموذج تسجيل المزارع: الاسم + التليفون + الرقم القومي (مع معاينة السن)
/// + **موافقة إلزامية على شروط الاستخدام وسياسة الخصوصية** قبل التسجيل.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/national_id.dart';
import '../../domain/village_legal.dart';
import '../../domain/village_validators.dart';
import '../village_theme.dart';
import 'village_input_formatters.dart';

class VillageMemberForm extends StatelessWidget {
  const VillageMemberForm({
    super.key,
    required this.villageName,
    required this.nameController,
    required this.phoneController,
    required this.nationalIdController,
    required this.nationalIdParse,
    required this.nameError,
    required this.phoneError,
    required this.nationalIdError,
    required this.errorMessage,
    required this.busy,
    required this.agreed,
    required this.onAgreedChanged,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
    required this.onNationalIdChanged,
    required this.onSubmit,
  });

  /// اسم القرية المقبولة بالكود — يُعرض في ترويسة النموذج.
  final String villageName;

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController nationalIdController;

  /// نتيجة تحليل الرقم القومي الحالية (للمعاينة الحيّة).
  final NationalIdParse? nationalIdParse;

  final String? nameError;
  final String? phoneError;
  final String? nationalIdError;

  /// خطأ عام من الخادم (تكرار/شبكة…).
  final String? errorMessage;

  final bool busy;

  /// هل وافق المُسجَّل على الشروط والخصوصية؟ (إلزامي قبل الإرسال)
  final bool agreed;

  final ValueChanged<bool?> onAgreedChanged;

  /// فتح صفحتي الشروط والخصوصية من رابطي الموافقة.
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;

  final ValueChanged<String> onNationalIdChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('village-form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(
              Icons.verified_rounded,
              color: VillageColors.success,
              size: 20,
            ),
            const SizedBox(width: VillageMetrics.space8),
            Expanded(
              child: Text(
                VillageText.welcomeVillage(villageName),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: VillageColors.inkSoft,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: VillageMetrics.space16),
        Text(
          VillageText.formHint,
          style: const TextStyle(
            fontSize: 13.5,
            color: VillageColors.muted,
            height: 1.8,
          ),
        ),
        const SizedBox(height: VillageMetrics.space24),
        TextField(
          key: const ValueKey<String>('village-name-field'),
          controller: nameController,
          enabled: !busy,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          maxLength: VillageValidators.maxNameLength,
          decoration: InputDecoration(
            labelText: VillageText.nameLabel,
            hintText: 'مثال: محمد أحمد عبد الله',
            errorText: nameError,
            counterText: '',
            prefixIcon: const Icon(Icons.person_rounded),
          ),
        ),
        const SizedBox(height: VillageMetrics.space20),
        TextField(
          key: const ValueKey<String>('village-phone-field'),
          controller: phoneController,
          enabled: !busy,
          textDirection: TextDirection.ltr,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.phone,
          inputFormatters: <TextInputFormatter>[
            const VillageDigitsFormatter(),
            LengthLimitingTextInputFormatter(VillageValidators.phoneLength),
          ],
          decoration: InputDecoration(
            labelText: VillageText.phoneLabel,
            hintText: '01xxxxxxxxx',
            errorText: phoneError,
            prefixIcon: const Icon(Icons.phone_rounded),
          ),
        ),
        const SizedBox(height: VillageMetrics.space20),
        TextField(
          key: const ValueKey<String>('village-national-id-field'),
          controller: nationalIdController,
          enabled: !busy,
          textDirection: TextDirection.ltr,
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.number,
          onChanged: onNationalIdChanged,
          onSubmitted: (_) => busy ? null : onSubmit(),
          inputFormatters: <TextInputFormatter>[
            const VillageDigitsFormatter(),
            LengthLimitingTextInputFormatter(NationalIdValidator.length),
          ],
          decoration: InputDecoration(
            labelText: VillageText.nationalIdLabel,
            hintText: '2xxxxxxxxxxxxx',
            errorText: nationalIdError,
            prefixIcon: const Icon(Icons.credit_card_rounded),
          ),
        ),
        const SizedBox(height: VillageMetrics.space12),
        _NationalIdPreview(
          parse: nationalIdParse,
          raw: nationalIdController.text,
        ),
        if (errorMessage != null) ...<Widget>[
          const SizedBox(height: VillageMetrics.space20),
          _ErrorBanner(message: errorMessage!),
        ],
        const SizedBox(height: VillageMetrics.space20),
        // الموافقة القانونية (قانون 151/2020): إلزامية، والروابط تفتح
        // النصّين كاملين قبل التأكيد.
        _ConsentRow(
          agreed: agreed,
          enabled: !busy,
          onChanged: onAgreedChanged,
          onOpenTerms: onOpenTerms,
          onOpenPrivacy: onOpenPrivacy,
        ),
        const SizedBox(height: VillageMetrics.space24),
        FilledButton(
          key: const ValueKey<String>('village-submit'),
          // الزر معطّل ما لم تُفعَّل الموافقة — الالتزام يسبق الإرسال.
          onPressed: (busy || !agreed) ? null : onSubmit,
          child: busy
              ? const _SubmittingLabel()
              : const Text(VillageText.submit),
        ),
      ],
    );
  }
}

/// معاينة حيّة لما استُخرج من الرقم القومي (تاريخ الميلاد والسن والمحافظة).
class _NationalIdPreview extends StatelessWidget {
  const _NationalIdPreview({required this.parse, required this.raw});

  final NationalIdParse? parse;
  final String raw;

  @override
  Widget build(BuildContext context) {
    final EgyptianNationalId? value = parse?.value;
    final bool hasInput = raw.trim().isNotEmpty;

    if (value == null) {
      if (!hasInput) return const SizedBox.shrink();
      final int digits = NationalIdValidator.normalize(raw).length;
      final int remaining = NationalIdValidator.length - digits;
      return _PreviewShell(
        icon: Icons.info_outline_rounded,
        color: VillageColors.muted,
        title: remaining > 0
            ? 'متبقٍ $remaining رقماً لإكمال الرقم القومي'
            : VillageText.nationalIdPreviewPrefix,
        detail: null,
      );
    }

    return _PreviewShell(
      icon: Icons.event_available_rounded,
      color: VillageColors.success,
      title: value.previewLabel,
      detail:
          'محافظة ${value.governorateName} · ${value.isMale ? 'ذكر' : 'أنثى'}',
    );
  }
}

class _PreviewShell extends StatelessWidget {
  const _PreviewShell({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('village-age-preview'),
      padding: const EdgeInsets.symmetric(
        horizontal: VillageMetrics.space16,
        vertical: VillageMetrics.space12,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(VillageMetrics.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color, size: 19),
          const SizedBox(width: VillageMetrics.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: color == VillageColors.muted
                        ? VillageColors.inkSoft
                        : color,
                    height: 1.6,
                  ),
                ),
                if (detail != null) ...<Widget>[
                  const SizedBox(height: VillageMetrics.space4),
                  Text(
                    detail!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: VillageColors.muted,
                      height: 1.6,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// شريط خطأ عام (من الخادم).
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('village-form-error'),
      padding: const EdgeInsets.symmetric(
        horizontal: VillageMetrics.space16,
        vertical: VillageMetrics.space12,
      ),
      decoration: BoxDecoration(
        color: VillageColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(VillageMetrics.radiusSm),
        border: Border.all(color: VillageColors.danger.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color: VillageColors.danger,
            size: 20,
          ),
          const SizedBox(width: VillageMetrics.space12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13.5,
                color: VillageColors.danger,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmittingLabel extends StatelessWidget {
  const _SubmittingLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const <Widget>[
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
        SizedBox(width: VillageMetrics.space12),
        Text(VillageText.submitting),
      ],
    );
  }
}

/// سطر الموافقة: مربّع اختيار + «أوافق على [شروط الاستخدام]
/// و[سياسة الخصوصية]» بروابط تفتح الصفحتين داخل التطبيق.
class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.agreed,
    required this.enabled,
    required this.onChanged,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
  });

  final bool agreed;
  final bool enabled;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VillageMetrics.space12,
        vertical: VillageMetrics.space4,
      ),
      decoration: BoxDecoration(
        color: VillageColors.surface,
        borderRadius: BorderRadius.circular(VillageMetrics.radiusMd),
        border: Border.all(
          color: VillageColors.border.withValues(alpha: 0.8),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Checkbox(
                key: const ValueKey<String>('village-terms-checkbox'),
                value: agreed,
                // المعطَّل أثناء الإرسال ⇐ onChanged = null يُعطّل المربّع.
                onChanged: enabled ? onChanged : null,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeColor: VillageColors.tealSoft,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: VillageMetrics.space12),
                  // الرتيب هنا هو ترتيب القراءة (RTL): يوافق ← شروط ← و ←
                  // خصوصية، والـ Wrap يوزّعها على السطر كما يلزم.
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: VillageMetrics.space4,
                    runSpacing: VillageMetrics.space4,
                    children: <Widget>[
                      const Text(
                        VillageLegal.consentAgree,
                        style: TextStyle(
                          fontSize: 14,
                          color: VillageColors.inkSoft,
                          height: 1.6,
                        ),
                      ),
                      _ConsentLink(
                        key: const ValueKey<String>('village-terms-link'),
                        label: VillageLegal.consentTerms,
                        onTap: onOpenTerms,
                      ),
                      const Text(
                        VillageLegal.consentAnd,
                        style: TextStyle(
                          fontSize: 14,
                          color: VillageColors.inkSoft,
                          height: 1.6,
                        ),
                      ),
                      _ConsentLink(
                        key: const ValueKey<String>('village-privacy-link'),
                        label: VillageLegal.consentPrivacy,
                        onTap: onOpenPrivacy,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            // الإزاحة جهة المربّع في RTL (start = يمين).
            padding: EdgeInsetsDirectional.only(
              start: VillageMetrics.space48,
              bottom: VillageMetrics.space8,
            ),
            child: Text(
              VillageLegal.consentHint,
              style: TextStyle(
                fontSize: 12,
                color: VillageColors.muted,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// رابط داخل سطر الموافقة — نصّ ذهبي مُسطَّر يستجيب لللمس.
class _ConsentLink extends StatelessWidget {
  const _ConsentLink({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: VillageColors.goldSoft,
          decoration: TextDecoration.underline,
          decorationColor: VillageColors.goldSoft,
          height: 1.6,
        ),
      ),
    );
  }
}
