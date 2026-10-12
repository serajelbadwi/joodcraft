/// شاشة «كود التفعيل» — تحويل عضو عادي إلى **صاحب فرح**: 100 حرف لكل
/// مدعو بلا حدّ يومي.
///
/// الكود يُسلَّم من مكتب القرية (يُولَّد في SQL Editor)، والتفعيل يُنفَّذ
/// على السيرفر (`farah_activate`) الذي يتحقّق من الكود ومن قريته ومن ألا
/// يكون مُفعَّلاً لعضو آخر — وتُعاد الجلسة المحدّثة إلى الرئيسية فتحصل
/// على صلاحياته بلا خروج.
library;

import 'package:flutter/material.dart';

import '../../data/farah_repository.dart';
import '../../domain/farah_models.dart';
import '../../domain/farah_text.dart';
import '../../../village/presentation/village_theme.dart';
import '../farah_theme.dart';
import '../widgets/farah_common.dart';

class FarahLicenseScreen extends StatefulWidget {
  const FarahLicenseScreen({
    super.key,
    required this.repository,
    required this.session,
  });

  final FarahRepository repository;
  final FarahSession session;

  @override
  State<FarahLicenseScreen> createState() => _FarahLicenseScreenState();
}

class _FarahLicenseScreenState extends State<FarahLicenseScreen> {
  final TextEditingController _codeController = TextEditingController();

  String? _codeError;
  String? _errorMessage;
  bool _busy = false;
  bool _activated = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;

    final String code = _codeController.text.trim();
    setState(() {
      _codeError = code.isEmpty ? 'اكتب كود التفعيل' : null;
      _errorMessage = null;
    });
    if (code.isEmpty) return;

    setState(() => _busy = true);
    debugPrint('[farah] activate start');

    try {
      final bool ok = await widget.repository.activateLicense(
        phone: widget.session.phone,
        code: code,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _activated = ok;
      });
      if (ok) {
        // إرجاع الجلسة المحدّثة إلى الرئيسية (تفعيل فوري بلا خروج).
        Navigator.of(context).pop(widget.session.copyWith(isOwner: true));
      }
    } on FarahException catch (error) {
      debugPrint('[farah] activate FarahException: ${error.kind.name}');
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorMessage = error.message;
      });
    } catch (_) {
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
      key: const ValueKey<String>('farah-license'),
      appBar: const FarahAppBar(title: FarahText.licenseTitle),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FarahNote(
            message: widget.session.isOwner
                ? FarahText.licenseAlreadyOwner
                : FarahText.licenseHint,
            icon: Icons.workspace_premium_rounded,
          ),
          const SizedBox(height: VillageMetrics.space24),
          TextField(
            key: const ValueKey<String>('farah-license-code-field'),
            controller: _codeController,
            enabled: !_busy,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _busy ? null : _submit(),
            decoration: InputDecoration(
              labelText: FarahText.licenseLabel,
              hintText: 'FARAH-0001',
              errorText: _codeError,
              prefixIcon: const Icon(Icons.vpn_key_rounded),
            ),
          ),
          if (_errorMessage != null) ...<Widget>[
            const SizedBox(height: VillageMetrics.space20),
            FarahErrorBanner(message: _errorMessage!),
          ],
          const SizedBox(height: VillageMetrics.space24),
          FilledButton(
            key: const ValueKey<String>('farah-license-submit'),
            onPressed: (_busy || widget.session.isOwner) ? null : _submit,
            child: _busy
                ? const FarahBusyLabel(label: FarahText.licenseActivating)
                : const Text(FarahText.licenseSubmit),
          ),
          if (_activated) ...<Widget>[
            const SizedBox(height: VillageMetrics.space16),
            const FarahNote(
              message: FarahText.licenseActivated,
              icon: Icons.check_circle_rounded,
            ),
          ],
        ],
      ),
    );
  }
}
