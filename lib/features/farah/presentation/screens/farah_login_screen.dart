/// شاشة دخول «فرح» — **برقم التليفون فقط وبلا OTP** (كما صُمِّمت الصفحة):
/// الرقم هو المفتاح، ومنه يستخرج السيرفر اسم العضو الكامل ومعرّفه وقريته.
///
/// إن لم يكن الرقم في `members` تظهر رسالة «سجّل في صفحة القرية أولاً» —
/// فلا يُفتح التطبيق لمن ليس من أهل القرية.
///
/// التليفون الذي نجح دخوله يُحفظ في الجهاز فلا يكتبه صاحبه ثانيةً في المرة
/// القادمة (و«خروج» من الرئيسية يمحوه).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_assets.dart';
import '../../data/farah_repository.dart';
import '../../domain/farah_models.dart';
import '../../domain/farah_text.dart';
import '../../../village/domain/village_validators.dart';
import '../../../village/presentation/village_theme.dart';
import '../../../village/presentation/widgets/village_input_formatters.dart';
import '../farah_theme.dart';
import '../widgets/farah_common.dart';
import 'farah_home_screen.dart';

/// مفتاح حفظ التليفون في الجهاز.
const String farahPhonePrefsKey = 'farah_phone';

class FarahLoginScreen extends StatefulWidget {
  const FarahLoginScreen({super.key, required this.repository});

  final FarahRepository repository;

  @override
  State<FarahLoginScreen> createState() => _FarahLoginScreenState();
}

class _FarahLoginScreenState extends State<FarahLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();

  String? _phoneError;
  String? _errorMessage;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _restorePhone();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /// استرجاع آخر تليفون استُخدم على هذا الجهاز (إن غاب المخزن نكمل عادي).
  Future<void> _restorePhone() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String saved = prefs.getString(farahPhonePrefsKey) ?? '';
      if (saved.isNotEmpty && mounted) {
        setState(() => _phoneController.text = saved);
      }
    } catch (_) {
      // المخزن غير متاح — نكتفي بحقل فارغ.
    }
  }

  Future<void> _rememberPhone(String phone) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(farahPhonePrefsKey, phone);
    } catch (_) {
      // فشل الحفظ لا يمنع الدخول.
    }
  }

  Future<void> _submit() async {
    if (_busy) return;

    final String? localError = VillageValidators.phone(_phoneController.text);
    setState(() {
      _phoneError = localError;
      _errorMessage = null;
    });
    if (localError != null) return;

    setState(() => _busy = true);
    debugPrint('[farah] login start');

    try {
      final FarahSession session =
          await widget.repository.login(_phoneController.text);
      await _rememberPhone(session.phone);
      if (!mounted) return;
      setState(() => _busy = false);
      // ندفع الرئيسية فلا يستطيع «رجوع» العودة إلى حقل الدخول بجهة.
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => FarahHomeScreen(
            repository: widget.repository,
            session: session,
          ),
        ),
      );
    } on FarahException catch (error) {
      debugPrint('[farah] login FarahException: ${error.kind.name}');
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorMessage = error.message;
      });
    } catch (error, trace) {
      debugPrint('[farah] login FAILED: $error\n$trace');
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorMessage = FarahText.genericError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FarahShell(
      key: const ValueKey<String>('farah-login'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: VillageMetrics.space24),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              // الشعار مربّع ‎1254×1254‎ فيُقيَّد بعرضه: ‎60%‎ من الشاشة
              // بحدّ أقصى ‎300px‎ — فلا يبتلع الدخول على الهواتف ولا يضيع
              // على الشاشات العريضة.
              final double logoWidth =
                  (constraints.maxWidth * 0.6).clamp(160.0, 300.0);
              return Center(
                child: Image.asset(
                  AppAssets.farahLogoImage,
                  key: const ValueKey<String>('farah-logo'),
                  width: logoWidth,
                  fit: BoxFit.contain,
                  // الاسم يبقى لقارئ الشاشة رغم أنه لم يُعرض نصّاً — الصورة
                  // «شعار» في سمعة الجهاز لا «رسم بلا معنى».
                  semanticLabel: FarahText.appName,
                  // الأصل غائب من الحزمة (خطأ توزيع): يظهر اسم التطبيق
                  // نصّاً بدل مربّع فارغ — لا تنكسر شاشة الدخول أبداً.
                  errorBuilder: (
                    BuildContext context,
                    Object error,
                    StackTrace? stackTrace,
                  ) =>
                      const Text(
                    'فرح',
                    style: TextStyle(
                      fontFamily: AppAssets.amiriFont,
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: VillageColors.gold,
                      height: 1.3,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: VillageMetrics.space4),
          const Center(
            child: Text(
              FarahText.appTagline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: VillageColors.muted,
                height: 1.7,
              ),
            ),
          ),
          const SizedBox(height: VillageMetrics.space32),
          const FarahNote(message: FarahText.loginHint),
          const SizedBox(height: VillageMetrics.space24),
          TextField(
            key: const ValueKey<String>('farah-login-phone-field'),
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
              labelText: FarahText.phoneLabel,
              hintText: '01xxxxxxxxx',
              errorText: _phoneError,
              prefixIcon: const Icon(Icons.phone_rounded),
            ),
          ),
          if (_errorMessage != null) ...<Widget>[
            const SizedBox(height: VillageMetrics.space20),
            FarahErrorBanner(message: _errorMessage!),
          ],
          const SizedBox(height: VillageMetrics.space24),
          FilledButton(
            key: const ValueKey<String>('farah-login-submit'),
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const FarahBusyLabel(label: FarahText.loginSubmitting)
                : const Text(FarahText.loginSubmit),
          ),
        ],
      ),
    );
  }
}
