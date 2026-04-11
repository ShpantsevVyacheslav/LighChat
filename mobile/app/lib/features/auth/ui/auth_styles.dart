import 'package:flutter/material.dart';

InputDecoration authGlassInputDecoration(
  BuildContext context, {
  required String label,
  String? hint,
}) {
  final scheme = Theme.of(context).colorScheme;
  final dark = scheme.brightness == Brightness.dark;

  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: (dark ? Colors.white : Colors.white).withValues(alpha: dark ? 0.08 : 0.45),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: dark ? 0.12 : 0.35)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: dark ? 0.12 : 0.35)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.55), width: 1.2),
    ),
  );
}

ButtonStyle authPrimaryButtonStyle(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return FilledButton.styleFrom(
    minimumSize: const Size.fromHeight(44),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    backgroundColor: scheme.primary,
    foregroundColor: scheme.onPrimary,
  );
}

ButtonStyle authOutlineButtonStyle(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final dark = scheme.brightness == Brightness.dark;

  return OutlinedButton.styleFrom(
    minimumSize: const Size.fromHeight(44),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    side: BorderSide(color: Colors.white.withValues(alpha: dark ? 0.18 : 0.50)),
    backgroundColor: (dark ? Colors.white : Colors.white).withValues(alpha: dark ? 0.06 : 0.30),
    foregroundColor: scheme.onSurface,
  );
}

