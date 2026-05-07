import 'package:flutter/services.dart' show rootBundle;

const List<String> legalSlugs = [
  'privacy-policy',
  'terms-of-service',
  'cookie-policy',
  'eula',
  'data-processing-agreement',
  'children-policy',
  'content-moderation-policy',
  'acceptable-use-policy',
];

bool isLegalSlug(String value) => legalSlugs.contains(value);

/// Loads a legal document Markdown body from bundled assets.
///
/// Tries the requested locale first, falls back to the other language,
/// returns `null` if neither exists.
Future<String?> loadLegalMarkdown({
  required String slug,
  required String locale,
}) async {
  final primary = await _tryLoad('assets/legal/$locale/$slug.md');
  if (primary != null) return primary;
  final fallback = locale == 'ru' ? 'en' : 'ru';
  return _tryLoad('assets/legal/$fallback/$slug.md');
}

Future<String?> _tryLoad(String path) async {
  try {
    return await rootBundle.loadString(path);
  } catch (_) {
    return null;
  }
}
