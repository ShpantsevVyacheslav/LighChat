/// Normalizes chat links entered by users.
///
/// - Keeps links with an explicit scheme as-is.
/// - Adds `https://` for bare domains like `dzen.ru`.
/// - Supports scheme-relative links (`//example.com`) as `https://...`.
String normalizeChatLinkUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  final parsed = Uri.tryParse(trimmed);
  if (parsed == null) return trimmed;
  if (parsed.hasScheme) return trimmed;
  if (trimmed.startsWith('//')) return 'https:$trimmed';
  return 'https://$trimmed';
}

/// Parses a normalized chat link and accepts only web URLs.
Uri? tryParseHttpChatLink(String raw) {
  final normalized = normalizeChatLinkUrl(raw);
  if (normalized.isEmpty) return null;
  final uri = Uri.tryParse(normalized);
  if (uri == null) return null;
  if (!(uri.isScheme('http') || uri.isScheme('https'))) return null;
  if (uri.host.trim().isEmpty) return null;
  return uri;
}
