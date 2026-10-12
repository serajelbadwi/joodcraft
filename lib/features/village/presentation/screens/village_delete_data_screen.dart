/// صفحة **حذف بياناتي** — تنفيذ «حقّ الحذف» الموعود في سياسة الخصوصية
/// (قانون حماية البيانات الشخصية المصري 151/2020).
///
/// التدفّق في صفحة واحدة: تحذير صريح (لا تراجع بعد الحذف) ← الرقم القومي
/// ورقم التليفون ← مطابقة على السيرفر عبر دالة `village_delete_member` التي
/// تحذف عند تطابق الاثنين وتعيد `false` حين لا تتطابق ← لوحة نجاح. الفشل
/// (شبكة/خدمة غير مُهيّأة) يُعرض كنصّ عربي واضح ولا يُغيّر شيئاً في السجل.
///
/// تُفتح من الزرّ «حذف بياناتي من السجل» أسفل نموذج التسجيل
/// (مفتاح `village-delete-data-button`)، وتُغلق بالزرّ «إلغاء» أو «رجوع».
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_assets.dart';
import '../../data/village_repository.dart';
import '../../domain/national_id.dart';
import '../../domain/village_legal.dart';
import '../../domain/village_validators.dart';
import '../village_theme.dart';
import '../widgets/village_input_formatters.dart';

/// لون النصّ فوق زرّ الحذف الأحمر (نفس `onError` في مظهر القرية).
const Color _onDanger = Color(0xFF3A0A06);

class VillageDeleteDataScreen extends StatefulWidget {
  const VillageDeleteDataScreen({super.key, required this.repository});

  /// مستودع البيانات (Supabase في الواقع، وهمي في الاختبارات).
  final VillageRepository repository;

  @override
  State<VillageDeleteDataScreen> createState() =>
      _VillageDeleteDataScreenState();
}

class _VillageDeleteDataScreenState extends State<VillageDeleteDataScreen> {
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _nationalIdError;
  String? _phoneError;
  String? _errorMessage;
  bool _busy = false;
  bool _done = false;

  @override
  void dispose() {
    _nationalIdController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;

    // تحقّق محلي أوّلاً: لا نداء للسيرفر بصيغة خاطئة.
    final String? phoneError = VillageValidators.phone(_phoneController.text);
    final NationalIdParse parse =
        NationalIdValidator.validate(_nationalIdController.text);
    final String? idError = parse.isValid ? null : parse.message;

    setState(() {
      _phoneError = phoneError;
      _nationalIdError = idError;
      _errorMessage = null;
    });
    if (phoneError != null || !parse.isValid) return;

    setState(() => _busy = true);
    debugPrint('[village] deleteMember: إرسال طلب الحذف (بلا بيانات شخصية)');

    try {
      final bool deleted = await widget.repository.deleteMember(
        nationalId: parse.value!.digits,
        phone: _phoneController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _done = deleted;
        _errorMessage = deleted ? null : VillageText.deleteNotFound;
      });
    } on VillageException catch (error) {
      debugPrint('[village] deleteMember VillageException: ${error.kind.name}');
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorMessage = _messageFor(error);
      });
    } catch (error, trace) {
      debugPrint('[village] deleteMember FAILED: $error\n$trace');
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorMessage = VillageText.deleteGenericError;
      });
    }
  }

  /// رسالة خطأ الحذف بنوع الفشل — تُترجم طبقة البيانات رسائل السيرفر، وما
  /// بقي (شبكة/تهيئة/غامض) يأخذ نصّ الحذف بدل نصّ التسجيل.
  String _messageFor(VillageException error) {
    switch (error.kind) {
      case VillageErrorKind.network:
        return VillageText.deleteNetworkError;
      case VillageErrorKind.unavailable:
      case VillageErrorKind.unknown:
        return VillageText.deleteGenericError;
      case VillageErrorKind.notFound:
      case VillageErrorKind.duplicate:
      case VillageErrorKind.invalid:
        // رسالة السيرفر بالعربية (تحقق من صيغة الرقم) — أنفع من رسالة عامة.
        return error.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VillageColors.background,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: _DeleteGlow()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: VillageMetrics.maxFormWidth,
                ),
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VillageMetrics.space20,
                    vertical: VillageMetrics.space24,
                  ),
                  children: <Widget>[
                    const _BackBar(),
                    const SizedBox(height: VillageMetrics.space8),
                    const Text(
                      VillageText.deleteTitle,
                      style: TextStyle(
                        fontFamily: AppAssets.amiriFont,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: VillageColors.gold,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: VillageMetrics.space16),
                    const _WarningCard(),
                    const SizedBox(height: VillageMetrics.space16),
                    if (!widget.repository.isAvailable) ...<Widget>[
                      const _ServiceUnavailableNote(),
                    ] else if (_done) ...<Widget>[
                      const _SuccessPanel(),
                    ] else ...<Widget>[
                      _buildForm(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      key: const ValueKey<String>('village-delete-form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(
          VillageText.deleteFormHint,
          style: TextStyle(
            fontSize: 13.5,
            color: VillageColors.muted,
            height: 1.8,
          ),
        ),
        const SizedBox(height: VillageMetrics.space20),
        TextField(
          key: const ValueKey<String>('village-delete-national-id-field'),
          controller: _nationalIdController,
          enabled: !_busy,
          textDirection: TextDirection.ltr,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            const VillageDigitsFormatter(),
            LengthLimitingTextInputFormatter(NationalIdValidator.length),
          ],
          decoration: InputDecoration(
            labelText: VillageText.nationalIdLabel,
            hintText: '2xxxxxxxxxxxxx',
            errorText: _nationalIdError,
            prefixIcon: const Icon(Icons.credit_card_rounded),
          ),
        ),
        const SizedBox(height: VillageMetrics.space20),
        TextField(
          key: const ValueKey<String>('village-delete-phone-field'),
          controller: _phoneController,
          enabled: !_busy,
          textDirection: TextDirection.ltr,
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.phone,
          onSubmitted: (_) => _busy ? null : _submit(),
          inputFormatters: <TextInputFormatter>[
            const VillageDigitsFormatter(),
            LengthLimitingTextInputFormatter(VillageValidators.phoneLength),
          ],
          decoration: InputDecoration(
            labelText: VillageText.phoneLabel,
            hintText: '01xxxxxxxxx',
            errorText: _phoneError,
            prefixIcon: const Icon(Icons.phone_rounded),
          ),
        ),
        if (_errorMessage != null) ...<Widget>[
          const SizedBox(height: VillageMetrics.space20),
          _ErrorBanner(message: _errorMessage!),
        ],
        const SizedBox(height: VillageMetrics.space24),
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton(
                key: const ValueKey<String>('village-delete-confirm'),
                style: FilledButton.styleFrom(
                  backgroundColor: VillageColors.danger,
                  foregroundColor: _onDanger,
                  disabledBackgroundColor: VillageColors.danger.withValues(
                    alpha: 0.35,
                  ),
                ),
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const _DeletingLabel()
                    : const Text(VillageText.deleteSubmit),
              ),
            ),
            const SizedBox(width: VillageMetrics.space12),
            OutlinedButton(
              key: const ValueKey<String>('village-delete-cancel'),
              onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
              child: const Text(VillageText.deleteCancel),
            ),
          ],
        ),
        const SizedBox(height: VillageMetrics.space16),
        // بديلة للحذف من هنا: التواصل مع المكتب (نفس بند التواصل في
        // سياسة الخصوصية).
        Text(
          'إن تعذّر عليك الحذف من هنا، تواصل مع المكتب على: '
          '${VillageLegal.contactEmail}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12.5,
            color: VillageColors.muted,
            height: 1.7,
          ),
        ),
      ],
    );
  }
}

/// شريط «جارٍ الحذف…» داخل زرّ الحذف أثناء الطلب.
class _DeletingLabel extends StatelessWidget {
  const _DeletingLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const <Widget>[
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: _onDanger,
          ),
        ),
        SizedBox(width: VillageMetrics.space12),
        Text(VillageText.deleteSubmitting),
      ],
    );
  }
}

/// التحذير الصريح أعلى الصفحة: لا تراجع بعد الحذف.
class _WarningCard extends StatelessWidget {
  const _WarningCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('village-delete-warning'),
      padding: const EdgeInsets.symmetric(
        horizontal: VillageMetrics.space16,
        vertical: VillageMetrics.space16,
      ),
      decoration: BoxDecoration(
        color: VillageColors.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(VillageMetrics.radiusMd),
        border: Border.all(
          color: VillageColors.danger.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(
                Icons.warning_amber_rounded,
                color: VillageColors.danger,
                size: 22,
              ),
              const SizedBox(width: VillageMetrics.space12),
              Expanded(
                child: Text(
                  VillageText.deleteWarningTitle,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: VillageColors.danger,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: VillageMetrics.space12),
          const Text(
            VillageText.deleteWarningBody,
            style: TextStyle(
              fontSize: 14,
              color: VillageColors.inkSoft,
              height: 1.9,
            ),
          ),
        ],
      ),
    );
  }
}

/// لوحة النجاح بعد الحذف — تُحلّ محلّ النموذج في المكان نفسه.
class _SuccessPanel extends StatelessWidget {
  const _SuccessPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('village-delete-success'),
      padding: const EdgeInsets.symmetric(
        horizontal: VillageMetrics.space20,
        vertical: VillageMetrics.space24,
      ),
      decoration: BoxDecoration(
        color: VillageColors.success.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(VillageMetrics.radiusMd),
        border: Border.all(
          color: VillageColors.success.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Icon(
            Icons.check_circle_rounded,
            color: VillageColors.success,
            size: 44,
          ),
          const SizedBox(height: VillageMetrics.space12),
          const Text(
            VillageText.deleteSuccessTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: VillageColors.success,
              height: 1.6,
            ),
          ),
          const SizedBox(height: VillageMetrics.space8),
          const Text(
            VillageText.deleteSuccessBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              color: VillageColors.inkSoft,
              height: 1.9,
            ),
          ),
          const SizedBox(height: VillageMetrics.space20),
          FilledButton(
            key: const ValueKey<String>('village-delete-done'),
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text(VillageText.deleteDone),
          ),
        ],
      ),
    );
  }
}

/// شريط خطأ عام أسفل الحقول (عدم تطابق/شبكة/تهيئة).
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('village-delete-error'),
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
        crossAxisAlignment: CrossAxisAlignment.start,
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

/// توضيح حالة عدم تهيئة الخدمة (لا مفاتيح Supabase) — لا نموذج لا يعمل.
class _ServiceUnavailableNote extends StatelessWidget {
  const _ServiceUnavailableNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('village-delete-service-unavailable'),
      padding: const EdgeInsets.all(VillageMetrics.space20),
      decoration: BoxDecoration(
        color: VillageColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(VillageMetrics.radiusMd),
        border: Border.all(color: VillageColors.danger.withValues(alpha: 0.45)),
      ),
      child: const Text(
        VillageText.serviceBody,
        style: TextStyle(
          fontSize: 13.5,
          color: VillageColors.inkSoft,
          height: 1.9,
        ),
      ),
    );
  }
}

/// زرّ «رجوع» أعلى الصفحة (نفس زرّ الصفحتين القانونيتين).
class _BackBar extends StatelessWidget {
  const _BackBar();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        key: const ValueKey<String>('village-delete-back'),
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_forward_rounded, size: 20),
        label: const Text('رجوع'),
      ),
    );
  }
}

/// هالتان لونيتان خفيفتان تتّحدان مع خلفية الصفحة الرئيسية.
class _DeleteGlow extends StatelessWidget {
  const _DeleteGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -120,
            right: -90,
            child: _glow(VillageColors.teal, 380),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: _glow(VillageColors.gold, 340),
          ),
        ],
      ),
    );
  }

  Widget _glow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[
            color.withValues(alpha: 0.14),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
