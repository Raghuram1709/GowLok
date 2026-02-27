import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onSuffixIconPressed;
  final bool enabled;

  const AuthTextField({
    Key? key,
    required this.controller,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.onSuffixIconPressed,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // start with the global inputDecorationTheme so we inherit the correct
    // filled/fillColor/border values for light vs dark mode.  Then override
    // the text-specific bits that are unique to this widget.
    // ThemeData.inputDecorationTheme currently returns a concrete
    // InputDecorationThemeData type, so avoid a strict annotation here.
    final base = theme.inputDecorationTheme;    InputDecoration decoration = InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null
          ? Icon(
              prefixIcon,
              color: theme.iconTheme.color?.withValues(alpha: 0.6),
            )
          : null,
      suffixIcon: suffixIcon != null
          ? IconButton(
              onPressed: onSuffixIconPressed,
              icon: Icon(suffixIcon),
              color: theme.iconTheme.color?.withValues(alpha: 0.6),
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    ).applyDefaults(base);

    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      validator: validator,
      decoration: decoration,
    );
  }
}
