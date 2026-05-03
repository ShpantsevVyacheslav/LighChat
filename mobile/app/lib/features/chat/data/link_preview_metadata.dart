import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

class LinkPreviewMetadata {
  const LinkPreviewMetadata({
    required this.url,
    required this.title,
    this.description,
    this.imageUrl,
    this.siteName,
    this.videoUrl,
    this.videoType,
  });

  final String url;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? siteName;

  /// Direct media URL from `og:video` / `og:video:secure_url` / `og:video:url`.
  /// May point to an mp4 stream or to an HTML player page.
  final String? videoUrl;

  /// MIME from `og:video:type` (e.g. `video/mp4`, `text/html`). Used to decide
  /// between `video_player` (mp4/webm) and a fallback image+open-in-browser.
  final String? videoType;
}

/// In-memory cache for link previews.
///
/// - Caches in-flight requests to dedupe parallel renders.
/// - Negative results are cached too (as null) to avoid re-fetch loops.
/// - Хранит **именно `Future`** (не голое значение) и переиспользует его на любые
///   повторные `get(url)` — после ресолва тоже. Это важно для `FutureBuilder`:
///   при смене идентичности `widget.future` он сбрасывает `_snapshot` в
///   `ConnectionState.waiting` (и наш билдер показывает skeleton), даже если
///   данные уже в памяти. На каждом ребилде ленты карточка моргала бы
///   skeleton↔контент, ломая высоту строки в `CustomScrollView`. Стабильная
///   ссылка убирает мерцание (см. `FutureBuilderState._subscribe`).
class LinkPreviewMetadataCache {
  LinkPreviewMetadataCache({this.timeout = const Duration(seconds: 6)});

  final Duration timeout;
  final Map<String, Future<LinkPreviewMetadata?>> _futures = {};

  Future<LinkPreviewMetadata?> get(String url) {
    final key = _normalizeUrlKey(url);
    if (key == null) return Future.value(null);

    final existing = _futures[key];
    if (existing != null) return existing;

    final future = _fetchAndParse(key);
    _futures[key] = future;
    return future;
  }

  void clear() {
    _futures.clear();
  }

  String? _normalizeUrlKey(String raw) {
    final u = Uri.tryParse(raw.trim());
    if (u == null) return null;
    if (!u.hasScheme) return null;
    if (!(u.isScheme('http') || u.isScheme('https'))) return null;
    // Drop fragment; keep query (some sites require it).
    return u.replace(fragment: '').toString();
  }

  Future<LinkPreviewMetadata?> _fetchAndParse(String url) async {
    try {
      final resp = await http
          .get(
            Uri.parse(url),
            headers: const {
              // facebookexternalhit token is what Telegram/Slack/Discord
              // imitate to get OpenGraph from social sites (IG/FB/Twitter).
              'User-Agent':
                  'Mozilla/5.0 (compatible; LighChatBot/1.0; +https://ligh.chat) '
                  'facebookexternalhit/1.1',
              'Accept':
                  'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            },
          )
          .timeout(timeout);

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        if (kDebugMode) {
          debugPrint('[link_preview] $url -> HTTP ${resp.statusCode}');
        }
        return null;
      }

      final body = resp.body;
      if (body.trim().isEmpty) return null;

      final doc = html_parser.parse(body);
      final head = doc.head;
      if (head == null) return null;

      String? og(String property) {
        final el = head.querySelector('meta[property="$property"]');
        final content = el?.attributes['content']?.trim();
        return (content == null || content.isEmpty) ? null : content;
      }

      String? name(String metaName) {
        final el = head.querySelector('meta[name="$metaName"]');
        final content = el?.attributes['content']?.trim();
        return (content == null || content.isEmpty) ? null : content;
      }

      String? title = og('og:title') ?? name('twitter:title');
      title ??= _textOrNull(head.querySelector('title'));
      if (title == null || title.trim().isEmpty) return null;

      final desc = og('og:description') ?? name('description');
      final siteName = og('og:site_name') ?? name('application-name');
      final image = og('og:image') ?? name('twitter:image');
      final resolvedImage = _resolveMaybeRelative(url, image);

      // og:video — Twitter/X, TikTok, Reddit, YouTube Shorts, sometimes IG.
      // Prefer secure_url > url > video; respect og:video:type when present.
      final video = og('og:video:secure_url') ??
          og('og:video:url') ??
          og('og:video') ??
          name('twitter:player:stream');
      final videoType = og('og:video:type') ??
          name('twitter:player:stream:content_type');
      final resolvedVideo = _resolveMaybeRelative(url, video);

      return LinkPreviewMetadata(
        url: url,
        title: title.trim(),
        description: (desc == null || desc.trim().isEmpty) ? null : desc.trim(),
        imageUrl: resolvedImage,
        siteName:
            (siteName == null || siteName.trim().isEmpty) ? null : siteName.trim(),
        videoUrl: resolvedVideo,
        videoType: (videoType == null || videoType.trim().isEmpty)
            ? null
            : videoType.trim().toLowerCase(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[link_preview] $url -> error: $e');
      }
      return null;
    }
  }

  String? _resolveMaybeRelative(String baseUrl, String? maybe) {
    if (maybe == null) return null;
    final s = maybe.trim();
    if (s.isEmpty) return null;
    final u = Uri.tryParse(s);
    if (u != null && u.hasScheme) return u.toString();
    final base = Uri.tryParse(baseUrl);
    if (base == null) return null;
    return base.resolve(s).toString();
  }

  String? _textOrNull(dom.Element? el) {
    if (el == null) return null;
    final t = el.text.trim();
    return t.isEmpty ? null : t;
  }
}

