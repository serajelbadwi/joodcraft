/// خطوة إدخال كود القرية — بوابة الدخول الوحيدة إلى نموذج التسجيل.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/village_validators.dart';
import '../village_theme.dart';
import 'village_input_formatters.dart';

class VillageCodeGate extends StatelessWidget {
  const VillageCodeGate({
    super.key,
    required this.controller,
    required this.busy,
    required this.errorText,
    required this.onSubmit,
  });

  final TextEditingController controller;

  /// جارٍ التحقق من الكود على السيرفر.
  final bool busy;

  /// رسالة خطأ الكود (من التحقق المحلي أو من الخادم).
  final String? errorText;

  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('village-code-gate'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(
          VillageText.codeTitle,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: VillageColors.white,
            height: 1.6,
          ),
        ),
        const SizedBox(height: VillageMetrics.space8),
        const Text(
          VillageText.codeHint,
          style: TextStyle(
            fontSize: 13.5,
            color: VillageColors.muted,
            height: 1.8,
          ),
        ),
        const SizedBox(height: VillageMetrics.space20),
        TextField(
          key: const ValueKey<String>('village-code-field'),
          controller: controller,
          enabled: !busy,
          autofocus: true,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          textInputAction: TextInputAction.go,
          keyboardType: TextInputType.visiblePassword,
          inputFormatters: <TextInputFormatter>[
            const VillageCodeFormatter(),
            LengthLimitingTextInputFormatter(9),
          ],
          onSubmitted: (_) => busy ? null : onSubmit(),
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
            color: VillageColors.white,
          ),
          decoration: InputDecoration(
            labelText: VillageText.codeLabel,
            hintText: VillageText.villageCode,
            errorText: errorText,
            prefixIcon: const Icon(Icons.key_rounded),
          ),
        ),
        const SizedBox(height: VillageMetrics.space20),
        FilledButton(
          key: const ValueKey<String>('village-code-submit'),
          onPressed: busy ? null : onSubmit,
          child: busy
              ? const _BusyLabel(label: VillageText.codeChecking)
              : const Text(VillageText.codeSubmit),
        ),
      ],
    );
  }
}

/// تسمية مع مؤشّر تحميل — تُستخدم في كل أزرار التدفّق.
class _BusyLabel extends StatelessWidget {
  const _BusyLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
        const SizedBox(width: VillageMetrics.space12),
        Text(label),
      ],
    );
  }
}
