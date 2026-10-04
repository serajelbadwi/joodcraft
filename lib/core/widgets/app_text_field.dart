import 'package:flutter/material.dart';

import '../l10n/app_l10n.dart';

/// حقل نصي موحّد الشكل لكل شاشات المنصة.
///
/// يوفّر: تسمية، تلميحاً، أيقونة، إظهار/إخفاء كلمة المرور، ومدقّقاً عربياً.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.obscure = false,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.enabled = true,
    this.maxLines = 1,
    this.autofocus = false,
    this.textInputFormatterEnabled = true,
    this.prefix,
    this.helperText,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final bool obscure;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final int maxLines;
  final bool autofocus;

  /// يمنع الإكمال التلقائي/التصحيح في الحقول الحساسة (كلمة المرور).
  final bool textInputFormatterEnabled;

  /// عنصر يوضع قبل الحقل (أيقونة علم مثلاً).
  final Widget? prefix;

  final String? helperText;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 8, right: 4),
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF1B2539),
                ),
          ),
        ),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscured,
          enabled: widget.enabled,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          autofocus: widget.autofocus,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator,
          autocorrect: widget.textInputFormatterEnabled,
          enableSuggestions: widget.textInputFormatterEnabled,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helperText,
            prefixIcon: widget.prefix ??
                (widget.prefixIcon == null
                    ? null
                    : Icon(widget.prefixIcon, size: 20)),
            suffixIcon: widget.obscure
                ? IconButton(
                    tooltip: _obscured
                        ? (context.l10n?.commonShow ?? 'إظهار')
                        : (context.l10n?.commonHide ?? 'إخفاء'),
                    icon: Icon(
                      _obscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscured = !_obscured),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
