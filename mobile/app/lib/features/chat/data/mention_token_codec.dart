import 'dart:convert';

/// Encodes a group mention in the composer WITHOUT embedding HTML.
///
/// We store mentions as a token:
///   \uE000 base64url(json) \uE001
///
/// This guarantees:
/// - no `<span ...>` ever appears in the TextField value
/// - we can render it as `@label` in the composer
/// - we can convert it to HTML on send
class MentionTokenCodec {
  MentionTokenCodec._();

  static const String tokenStart = '\uE000';
  static const String tokenEnd = '\uE001';

  static bool containsToken(String text) {
    return text.contains(tokenStart) && text.contains(tokenEnd);
  }

  static String buildToken({required String userId, required String label}) {
    final payload = <String, String>{
      'userId': userId.trim(),
      'label': label.trim(),
    };
    final raw = utf8.encode(jsonEncode(payload));
    final b64 = base64Url.encode(raw);
    return '$tokenStart$b64$tokenEnd';
  }

  static ({String userId, String label})? tryDecodeToken(String token) {
    final s = token;
    if (!s.startsWith(tokenStart) || !s.endsWith(tokenEnd)) return null;
    final b64 = s.substring(tokenStart.length, s.length - tokenEnd.length);
    if (b64.isEmpty) return null;
    try {
      final raw = base64Url.decode(b64);
      final map = jsonDecode(utf8.decode(raw));
      if (map is! Map) return null;
      final uid = (map['userId'] ?? '').toString().trim();
      final label = (map['label'] ?? '').toString().trim();
      if (uid.isEmpty) return null;
      return (userId: uid, label: label.isEmpty ? 'Участник' : label);
    } catch (_) {
      return null;
    }
  }
}

