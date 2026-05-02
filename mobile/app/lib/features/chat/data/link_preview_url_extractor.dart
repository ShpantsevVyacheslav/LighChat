// Detects http(s) URLs and bare-domain URLs (e.g. "lighchat.online") in
// plain message text.
//
// We support three forms:
//   1. https?://example.com[/...] — explicit scheme
//   2. www.example.com[/...] — implicit https
//   3. example.tld[/...] — bare domain, only when TLD is in the curated
//      allowlist below; this avoids false positives like file.dart.

class UrlMatch {
  const UrlMatch({
    required this.start,
    required this.end,
    required this.original,
    required this.normalized,
  });

  /// Position where the matched substring starts in the source text.
  final int start;

  /// Position right after the matched substring (excluding trailing
  /// punctuation that was stripped).
  final int end;

  /// The substring as it appears in the source text (display form).
  final String original;

  /// The same URL with `https://` prepended if the scheme was missing.
  /// Always safe to feed into [Uri.parse] / `launchUrl`.
  final String normalized;
}

/// Curated list of TLDs we recognize for bare-domain URLs.
///
/// Includes common ccTLDs (2 letters), legacy gTLDs (com/org/...) and the
/// most popular new gTLDs people actually use in messages. We intentionally
/// do *not* match every TLD that exists, because plenty of them collide with
/// file extensions / programming identifiers (`.dart`, `.go`, `.zip` etc.)
/// and would produce false links inside code-like text.
const Set<String> _kKnownTlds = {
  // ccTLDs
  'ae', 'am', 'ar', 'at', 'au', 'az', 'ba', 'bd', 'be', 'bg', 'br', 'by',
  'ca', 'cc', 'ch', 'cl', 'cn', 'co', 'cz', 'de', 'dk', 'dz', 'ec', 'ee',
  'eg', 'es', 'eu', 'fi', 'fr', 'ge', 'gr', 'hk', 'hr', 'hu', 'id', 'ie',
  'il', 'in', 'ir', 'is', 'it', 'jo', 'jp', 'ke', 'kg', 'kr', 'kw', 'kz',
  'lb', 'li', 'lk', 'lt', 'lu', 'lv', 'ma', 'md', 'me', 'mx', 'my', 'ng',
  'nl', 'no', 'nz', 'om', 'pe', 'ph', 'pk', 'pl', 'pt', 'qa', 'ro', 'rs',
  'ru', 'sa', 'se', 'sg', 'si', 'sk', 'su', 'th', 'tj', 'tn', 'tr', 'tv',
  'tw', 'ua', 'ug', 'uk', 'us', 'uz', 've', 'vn', 'za',
  // Legacy gTLDs
  'com', 'org', 'net', 'edu', 'gov', 'mil', 'int', 'info', 'biz', 'name',
  'pro', 'asia', 'mobi', 'tel', 'travel', 'jobs', 'aero', 'coop', 'museum',
  // Popular new gTLDs
  'agency', 'ai', 'app', 'art', 'best', 'blog', 'business', 'cafe', 'capital',
  'center', 'chat', 'city', 'click', 'cloud', 'club', 'community', 'company',
  'cool', 'dating', 'deals', 'design', 'dev', 'digital', 'email', 'events',
  'expert', 'family', 'fans', 'fashion', 'film', 'finance', 'fun', 'fund',
  'game', 'games', 'group', 'guru', 'help', 'home', 'host', 'io', 'life',
  'link', 'live', 'market', 'media', 'menu', 'money', 'news', 'one', 'online',
  'page', 'photo', 'photos', 'plus', 'press', 'review', 'reviews',
  'rocks', 'run', 'sale', 'school', 'services', 'shop', 'show', 'site',
  'social', 'software', 'solutions', 'space', 'store', 'studio', 'style',
  'support', 'systems', 'team', 'tech', 'technology', 'tickets', 'today',
  'tools', 'top', 'trade', 'video', 'vip', 'website', 'wiki', 'win',
  'works', 'world', 'xyz', 'zone',
};

bool isKnownTld(String tld) => _kKnownTlds.contains(tld.toLowerCase());

final RegExp _urlPattern = RegExp(
  // 1) explicit scheme
  r'(?:https?:\/\/)[^\s<>"' "'" r']+'
  r'|'
  // 2) www.X.Y[/...]
  r'www\.[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+(?:\/[^\s<>"' "'" r']*)?'
  r'|'
  // 3) bare domain X.tld[/...] — TLD validated separately
  r'[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?)*\.[a-zA-Z]{2,24}(?:\/[^\s<>"' "'" r']*)?',
  caseSensitive: false,
);

final RegExp _trailingPuncRe = RegExp(
  r'[.,!?;:)\]}’”»]+$',
);

/// Finds all URLs (explicit or bare-domain) in [text].
List<UrlMatch> findUrlMatches(String text) {
  final out = <UrlMatch>[];
  for (final m in _urlPattern.allMatches(text)) {
    final rawFull = m.group(0) ?? '';
    if (rawFull.isEmpty) continue;

    // Strip trailing punctuation that's almost never part of a URL but
    // commonly hugs one in a sentence: "see https://x.com." or "(x.com)".
    var raw = rawFull;
    final puncMatch = _trailingPuncRe.firstMatch(raw);
    if (puncMatch != null && puncMatch.start > 0) {
      raw = raw.substring(0, puncMatch.start);
    }
    if (raw.isEmpty) continue;

    final endOffset = m.start + raw.length;
    final lower = raw.toLowerCase();

    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      out.add(UrlMatch(
        start: m.start,
        end: endOffset,
        original: raw,
        normalized: raw,
      ));
      continue;
    }
    if (lower.startsWith('www.')) {
      out.add(UrlMatch(
        start: m.start,
        end: endOffset,
        original: raw,
        normalized: 'https://$raw',
      ));
      continue;
    }

    // Bare domain — guard against false positives.
    // Skip if preceded by '@' (looks like an email user@domain).
    if (m.start > 0 && text[m.start - 1] == '@') continue;
    // Skip if preceded by an alphanumeric (looks like a path segment or a
    // file like "src/file.dart" — would already be filtered, but for safety).
    if (m.start > 0) {
      final prev = text[m.start - 1];
      if (RegExp(r'[a-zA-Z0-9]').hasMatch(prev)) continue;
    }

    final hostPart = raw.split(RegExp(r'[\/?#]')).first;
    final hostLabels = hostPart.split('.');
    if (hostLabels.length < 2) continue;
    final tld = hostLabels.last;
    if (!isKnownTld(tld)) continue;

    out.add(UrlMatch(
      start: m.start,
      end: endOffset,
      original: raw,
      normalized: 'https://$raw',
    ));
  }
  return out;
}

/// Extracts the first http(s) or bare-domain URL from message plaintext,
/// returning a normalized URL (with `https://` prepended when needed).
String? extractFirstHttpUrl(String text) {
  final raw = text.trim();
  if (raw.isEmpty) return null;
  final matches = findUrlMatches(raw);
  if (matches.isEmpty) return null;
  return matches.first.normalized;
}
