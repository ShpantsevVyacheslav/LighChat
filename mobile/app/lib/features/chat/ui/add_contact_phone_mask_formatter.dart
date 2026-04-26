import 'package:flutter/services.dart';

/// National-number mask driven by [phoneHint] (digits in hint are placeholders).
///
/// Leading literals before the first placeholder (e.g. `(` in `(999)…`) are
/// inserted once there is at least one digit. [formatEditUpdate] keeps the caret
/// on the same logical digit index when possible.
class AddContactNationalPhoneMaskFormatter extends TextInputFormatter {
  const AddContactNationalPhoneMaskFormatter({
    required this.phoneHint,
    required this.maxNationalDigits,
  });

  final String phoneHint;
  final int maxNationalDigits;

  static bool _isDigit(String ch) => RegExp(r'\d').hasMatch(ch);

  static int _indexOfFirstDigitInHint(String phoneHint) {
    for (var i = 0; i < phoneHint.length; i++) {
      if (_isDigit(phoneHint[i])) return i;
    }
    return phoneHint.length;
  }

  static String formatDigits(String digits, {required String phoneHint}) {
    if (digits.isEmpty) return '';
    final cleaned = digits.replaceAll(RegExp(r'\D'), '');
    final firstDigitI = _indexOfFirstDigitInHint(phoneHint);
    final out = StringBuffer();
    if (cleaned.isNotEmpty && firstDigitI > 0) {
      out.write(phoneHint.substring(0, firstDigitI));
    }
    var di = 0;
    for (var i = firstDigitI; i < phoneHint.length; i++) {
      final ch = phoneHint[i];
      if (_isDigit(ch)) {
        if (di >= cleaned.length) break;
        out.write(cleaned[di]);
        di++;
      } else {
        if (di == 0) continue;
        out.write(ch);
      }
    }
    if (di < cleaned.length) {
      out.write(cleaned.substring(di));
    }
    return out.toString();
  }

  static int _digitsBeforeCursor(String text, int cursor) {
    final c = cursor.clamp(0, text.length);
    var n = 0;
    for (var i = 0; i < c; i++) {
      if (_isDigit(text[i])) n++;
    }
    return n;
  }

  static int _offsetAfterDigitIndex(String formatted, int digitIndex) {
    if (digitIndex <= 0) return 0;
    var di = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (_isDigit(formatted[i])) {
        di++;
        if (di >= digitIndex) return i + 1;
      }
    }
    return formatted.length;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final rawDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = rawDigits.length > maxNationalDigits
        ? rawDigits.substring(0, maxNationalDigits)
        : rawDigits;
    final nextText = formatDigits(limited, phoneHint: phoneHint);

    final sel = newValue.selection;
    final anchor = sel.isValid
        ? (sel.extentOffset.clamp(0, newValue.text.length))
        : newValue.text.length;
    var targetDigitIndex = _digitsBeforeCursor(newValue.text, anchor);
    targetDigitIndex = targetDigitIndex.clamp(0, limited.length);
    final newOffset = _offsetAfterDigitIndex(nextText, targetDigitIndex).clamp(
      0,
      nextText.length,
    );

    return TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: newOffset),
      composing: TextRange.empty,
    );
  }
}
