/// شاشة تسجيل أهل القرية — تدفّق كامل في صفحة واحدة:
/// **كود القرية** ← **بيانات المزارع** ← **النجاح ودعوة تطبيق فرح**.
///
/// وإلى جانب التدفّق: قسم **فيديوهات القرية** (جدول `videos`) يُجلب صامتاً في
/// `initState` ويظهر وحده حين تعود فيديوهات — فإن فشل الجلب بقي القسم مخفياً
/// ولم يتأثر التسجيل إطلاقاً.
///
/// كل حالة الخطوة في هذه الشاشة، وطبقة البيانات خلف [VillageRepository] وحدها،
/// فيمكن اختبار التدفّق كاملاً بمستودع وهمي بلا شبكة.
library;

import 'package:flutter/material.dart';

import '../../data/village_repository.dart';
import '../../domain/national_id.dart';
import '../../domain/village.dart';
import '../../domain/village_validators.dart';
import '../../domain/village_video.dart';
import '../village_theme.dart';
import '../widgets/village_about_card.dart';
import '../widgets/village_code_gate.dart';
import '../widgets/village_footer.dart';
import '../widgets/village_header.dart';
import '../widgets/village_map_embed.dart';
import '../widgets/village_member_form.dart';
import '../widgets/village_section_card.dart';
import '../widgets/village_success_card.dart';
import '../widgets/village_videos_section.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';

/// خطوات التدفّق.
enum VillageStep { code, form, done }

class VillageRegistrationScreen extends StatefulWidget {
  const VillageRegistrationScreen({
    super.key,
    required this.repository,
    this.villageNameFallback = VillageText.villageName,
    this.initialVillageCode = VillageText.villageCode,
  });

  /// مستودع البيانات (Supabase في الواقع، وهمي في الاختبارات).
  final VillageRepository repository;

  /// اسم القرية قبل قبول الكود (يُستبدل باسم القرية الفعلي بعده).
  final String villageNameFallback;

  /// كود القرية التي تُجلب فيديوهاتها الصفحة قبل أن يُدخل الزائر كوده.
  final String initialVillageCode;

  @override
  State<VillageRegistrationScreen> createState() =>
      _VillageRegistrationScreenState();
}

class _VillageRegistrationScreenState extends State<VillageRegistrationScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nationalIdController = TextEditingController();

  VillageStep _step = VillageStep.code;
  Village? _village;
  NationalIdParse? _nationalIdParse;
  String? _codeError;
  String? _nameError;
  String? _phoneError;
  String? _nationalIdError;
  String? _formError;
  bool _busy = false;
  String _registeredName = '';

  /// الموافقة على الشروط والخصوصية — إلزامية قبل الإرسال (قانون 151/2020).
  bool _agreedTerms = false;

  /// فيديوهات القرية المعروضة — خاليةً قبل أول جلب ناجح أو عند فشله.
  List<VillageVideo> _videos = const <VillageVideo>[];

  /// الكود الذي جُلبت فيديوهاته بنجاح (يمنع إعادة جلب بلا داعٍ).
  String _videosCode = '';

  /// رقم آخر طلب — يبطل نتيجة الجلب القديم إن تبدّل الكود أثناء الرحلة.
  int _videosRequest = 0;

  @override
  void initState() {
    super.initState();
    // الفيديوهات قسم زينة مستقل عن التسجيل: تبدأ الصفحة بجلب فيديو قريتها
    // (البذرة)، ولا تنتظر إدخال الكود — فإن فشل الجلب بقي القسم مخفياً وحده.
    _loadVideos(widget.initialVillageCode);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }

  String get _villageName => _village?.name ?? widget.villageNameFallback;

  // ==========================================================================
  //  فيديوهات القرية — جلب صامت لا يعطّل الصفحة أبداً
  // ==========================================================================
  Future<void> _loadVideos(String villageCode) async {
    if (!widget.repository.isAvailable) return;
    if (villageCode.isEmpty || villageCode == _videosCode) return;

    final int request = ++_videosRequest;
    try {
      final List<VillageVideo> videos =
          await widget.repository.fetchVideos(villageCode: villageCode);
      if (!mounted || request != _videosRequest) return;
      _videosCode = villageCode;
      setState(() => _videos = videos);
    } catch (_) {
      // أي فشل (جدول غير منشأ/شبكة/صلاحيات) يعني عدم ظهور القسم فقط:
      // الصفحة كلها سليمة، ويُسمح بإعادة المحاولة عند الكود التالي.
    }
  }

  // ==========================================================================
  //  الخطوة 1 — التحقق من كود القرية
  // ==========================================================================
  Future<void> _submitCode() async {
    if (_busy) return;

    final String? localError = VillageValidators.code(_codeController.text);
    if (localError != null) {
      // سجلّ الكونسول: يُظهر إن رُفض الكود محلياً قبل أي نداء للسيرفر.
      debugPrint('[village] code rejected locally: "$localError"');
      setState(() => _codeError = localError);
      return;
    }

    setState(() {
      _busy = true;
      _codeError = null;
    });

    debugPrint(
      '[village] lookup start: raw="${_codeController.text}" '
      'available=${widget.repository.isAvailable}',
    );

    try {
      final Village? village =
          await widget.repository.lookupVillage(_codeController.text);
      if (!mounted) return;
      if (village == null) {
        debugPrint('[village] lookup → null (الكود غير موجود في قاعدة البيانات)');
        setState(() {
          _busy = false;
          _codeError = VillageText.codeNotFound;
        });
        return;
      }
      debugPrint('[village] lookup → ${village.name} (${village.code})');
      setState(() {
        _busy = false;
        _village = village;
        _step = VillageStep.form;
      });
      // كود مختلف عن كود الصفحة ⇒ فيديوهات القرية الجديدة تحلّ محلّ القديمة.
      _loadVideos(village.code);
    } on VillageException catch (error) {
      debugPrint(
        '[village] lookup VillageException: kind=${error.kind.name} '
        'message=${error.message} cause=${error.cause}',
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _codeError = error.message;
      });
    } catch (error, trace) {
      debugPrint('[village] lookup FAILED: $error\n$trace');
      if (!mounted) return;
      setState(() {
        _busy = false;
        _codeError = VillageText.genericError;
      });
    }
  }

  // ==========================================================================
  //  الخطوة 2 — تسجيل العضو
  // ==========================================================================
  void _onNationalIdChanged(String value) {
    setState(() {
      _nationalIdError = null;
      _formError = null;
      _nationalIdParse = value.trim().isEmpty
          ? null
          : NationalIdValidator.validate(value);
    });
  }

  Future<void> _submitForm() async {
    if (_busy) return;
    // الزر معطّل بلا موافقة، وهذه حماية ثانية تمنع أي إرسال عرضي.
    if (!_agreedTerms) return;

    final String? nameError = VillageValidators.name(_nameController.text);
    final String? phoneError = VillageValidators.phone(_phoneController.text);
    final NationalIdParse parse =
        NationalIdValidator.validate(_nationalIdController.text);
    final String? idError = parse.isValid ? null : parse.message;

    setState(() {
      _nameError = nameError;
      _phoneError = phoneError;
      _nationalIdError = idError;
      _formError = null;
      if (parse.isValid) _nationalIdParse = parse;
    });

    if (nameError != null || phoneError != null || !parse.isValid) return;

    setState(() => _busy = true);

    try {
      await widget.repository.registerMember(
        villageCode: _village?.code ?? '',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        nationalId: parse.value!.digits,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _registeredName = _nameController.text.trim();
        _step = VillageStep.done;
      });
    } on VillageException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _formError = error.message;
        if (error.kind == VillageErrorKind.duplicate) {
          _nationalIdError = error.message;
        } else if (error.kind == VillageErrorKind.notFound) {
          // انتهت صلاحية الكود/حُذفت القرية — نُعيده لخطوة الكود.
          _codeError = error.message;
          _step = VillageStep.code;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _formError = VillageText.genericError;
      });
    }
  }

  /// فتح صفحتي الشروط والخصوصية من رابَطي الموافقة — رجوع بلا فقدان النموذج.
  void _openTerms() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const TermsScreen(),
      ),
    );
  }

  void _openPrivacy() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const PrivacyPolicyScreen(),
      ),
    );
  }

  /// إعادة التدفّق لتسجيل فرد آخر (نفس القرية).
  void _registerAnother() {
    setState(() {
      _nameController.clear();
      _phoneController.clear();
      _nationalIdController.clear();
      _nationalIdParse = null;
      _nameError = null;
      _phoneError = null;
      _nationalIdError = null;
      _formError = null;
      _registeredName = '';
      // الموافقة شخصية لكل تسجيل: تُصفَّر ليعود المربّع غير مفعّل.
      _agreedTerms = false;
      _step = VillageStep.form;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          const _VillageBackground(),
          SafeArea(
            // التوسيط **خارج** شريط التمرير وبحدّ أقصى للعرض:
            // الغلّاف نفسه هو المُوسَّط فلا يتجاوز محتواه عرض النافذة أبداً،
            // ولو جاء عنصر أعرض (مثل iframe الخريطة) حُجز داخل هذا العرض
            // بدل أن يوسّع المستند ويفرّغ جهةً من الصفحة (الفراغ الأبيض).
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: VillageMetrics.maxContentWidth,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VillageMetrics.space20,
                    vertical: VillageMetrics.space32,
                  ),
                  child: Column(
                    key: const ValueKey<String>('village-page'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      VillageHeader(villageName: _villageName),
                      const SizedBox(height: VillageMetrics.space32),
                      const VillageAboutCard(),
                      const SizedBox(height: VillageMetrics.space24),
                      const VillageMapSection(),
                      // القسم يظهر وحده حين تعود فيديوهات منشورة — لا فراغ
                      // ولا بطاقة فارغة قبل جلب أول فيديو.
                      if (_videos.isNotEmpty) ...<Widget>[
                        const SizedBox(height: VillageMetrics.space24),
                        VillageVideosSection(videos: _videos),
                      ],
                      const SizedBox(height: VillageMetrics.space24),
                      _buildRegistrationSection(),
                      const VillageFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationSection() {
    return VillageSectionCard(
      title: VillageText.formTitle,
      icon: Icons.how_to_reg_rounded,
      subtitle: _step == VillageStep.form ? _villageName : null,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: VillageMetrics.maxFormWidth,
          ),
          // الخدمة غير مُهيّأة (لا مفاتيح Supabase) ⇒ توضيح بدل نموذج لا يعمل.
          child: widget.repository.isAvailable
              ? _buildFlow()
              : const _ServiceUnavailableNote(),
        ),
      ),
    );
  }

  Widget _buildFlow() {
    switch (_step) {
      case VillageStep.code:
        return VillageCodeGate(
          controller: _codeController,
          busy: _busy,
          errorText: _codeError,
          onSubmit: _submitCode,
        );
      case VillageStep.form:
        return VillageMemberForm(
          villageName: _villageName,
          nameController: _nameController,
          phoneController: _phoneController,
          nationalIdController: _nationalIdController,
          nationalIdParse: _nationalIdParse,
          nameError: _nameError,
          phoneError: _phoneError,
          nationalIdError: _nationalIdError,
          errorMessage: _formError,
          busy: _busy,
          agreed: _agreedTerms,
          onAgreedChanged: (bool? value) =>
              setState(() => _agreedTerms = value ?? false),
          onOpenTerms: _openTerms,
          onOpenPrivacy: _openPrivacy,
          onNationalIdChanged: _onNationalIdChanged,
          onSubmit: _submitForm,
        );
      case VillageStep.done:
        return VillageSuccessCard(
          memberName: _registeredName,
          villageName: _villageName,
          onRegisterAnother: _registerAnother,
        );
    }
  }
}

/// خلفية الصفحة: تدرّج داكن + هالتان لونيتان (تركواز/ذهبي) بلمسة واحدة.
class _VillageBackground extends StatelessWidget {
  const _VillageBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFF404040), Color(0xFF353535)],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -140,
              right: -100,
              child: _Glow(color: VillageColors.teal, size: 460),
            ),
            Positioned(
              bottom: -160,
              left: -120,
              child: _Glow(color: VillageColors.gold, size: 420),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              color.withValues(alpha: 0.16),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

/// توضيح حالة عدم تهيئة الخدمة (لا مفاتيح Supabase).
class _ServiceUnavailableNote extends StatelessWidget {
  const _ServiceUnavailableNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('village-service-unavailable'),
      padding: const EdgeInsets.all(VillageMetrics.space20),
      decoration: BoxDecoration(
        color: VillageColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(VillageMetrics.radiusMd),
        border: Border.all(color: VillageColors.danger.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: const <Widget>[
              Icon(
                Icons.cloud_off_rounded,
                color: VillageColors.danger,
                size: 22,
              ),
              SizedBox(width: VillageMetrics.space12),
              Text(
                VillageText.serviceTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: VillageColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: VillageMetrics.space12),
          const Text(
            VillageText.serviceBody,
            style: TextStyle(
              fontSize: 13.5,
              color: VillageColors.inkSoft,
              height: 1.9,
            ),
          ),
        ],
      ),
    );
  }
}
