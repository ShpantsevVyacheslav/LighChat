/// Extracts the first http(s) URL from message plaintext.
///
/// We keep it intentionally conservative to avoid false positives.
String? extractFirstHttpUrl(String text) {
  final raw = text.trim();
  if (raw.isEmpty) return null;
  final re = RegExp(r'(https?:\/\/[^\s<>"\u0027]+)', caseSensitive: false);
  final m = re.firstMatch(raw);
  if (m == null) return null;
  final url = (m.group(0) ?? '').trim();
  if (url.isEmpty) return null;
  return url;
}

