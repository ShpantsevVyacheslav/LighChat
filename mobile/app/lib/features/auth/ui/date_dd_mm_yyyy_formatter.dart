import 'package:flutter/services.dart';

class DateDdMmYyyyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    final clipped = digits.length > 8 ? digits.substring(0, 8) : digits;
    final b = StringBuffer();
    for (var i = 0; i < clipped.length; i++) {
      if (i == 2 || i == 4) b.write('.');
      b.write(clipped[i]);
    }
    final text = b.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: TextRange.empty,
    );
  }
}
