import 'package:flutter/services.dart';

String phoneDigitsOnly(String raw) => raw.replaceAll(RegExp(r'\D'), '');

String _ruNational10FromAny(String raw) {
  final digits = phoneDigitsOnly(raw);
  if (digits.isEmpty) return '';

  if (digits.startsWith('7') || digits.startsWith('8')) {
    final tail = digits.length > 1 ? digits.substring(1) : '';
    return tail.length > 10 ? tail.substring(0, 10) : tail;
  }

  return digits.length > 10 ? digits.substring(0, 10) : digits;
}

String formatPhoneRuForDisplay(String raw) {
  final d = _ruNational10FromAny(raw);
  final b = StringBuffer('+7');

  if (d.isEmpty) return b.toString();
  b.write(' (');
  final p1End = d.length < 3 ? d.length : 3;
  b.write(d.substring(0, p1End));
  if (d.length >= 3) b.write(')');

  if (d.length > 3) {
    b.write(' ');
    final p2End = d.length < 6 ? d.length : 6;
    b.write(d.substring(3, p2End));
  }
  if (d.length > 6) {
    b.write('-');
    final p3End = d.length < 8 ? d.length : 8;
    b.write(d.substring(6, p3End));
  }
  if (d.length > 8) {
    b.write('-');
    final p4End = d.length < 10 ? d.length : 10;
    b.write(d.substring(8, p4End));
  }
  return b.toString();
}

String normalizePhoneRuToE164(String raw) {
  final digits = phoneDigitsOnly(raw);
  if (digits.length == 11 && digits.startsWith('8')) {
    return '+7${digits.substring(1)}';
  }
  if (digits.length == 11 && digits.startsWith('7')) {
    return '+$digits';
  }
  if (digits.length == 10) {
    return '+7$digits';
  }
  return raw.trim();
}

class PhoneRuMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;

    // При удалении форматирующего символа (скобка, тире, пробел) маска тут же
    // возвращала его обратно — пользователь не мог уменьшить число цифр и
    // застревал, например, на «+7 (909)». Если backspace убрал только
    // форматирующий символ, дополнительно отбрасываем последнюю цифру.
    if (oldValue.text.length > newValue.text.length) {
      final oldDigits = phoneDigitsOnly(oldValue.text);
      final newDigits = phoneDigitsOnly(newValue.text);
      if (oldDigits == newDigits && newDigits.isNotEmpty) {
        text = newDigits.substring(0, newDigits.length - 1);
      }
    }

    final masked = formatPhoneRuForDisplay(text);
    return TextEditingValue(
      text: masked,
      selection: TextSelection.collapsed(offset: masked.length),
      composing: TextRange.empty,
    );
  }
}
