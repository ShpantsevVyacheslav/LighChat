import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:lighchat_models/lighchat_models.dart';

import 'giphy_proxy_config.dart';

class GiphyGifItem {
  const GiphyGifItem({
    required this.id,
    required this.url,
    this.emoji,
    this.width,
    this.height,
  });

  final String id;
  final String url;
  final String? emoji;
  final int? width;
  final int? height;
}

/// Паритет ответа `src/app/api/giphy/search/route.ts`.
class GiphySearchOutcome {
  const GiphySearchOutcome({
    required this.items,
    this.missingKey = false,
    this.offset = 0,
    this.total = 0,
    this.serverHasMore,
    this.translatedFrom,
    this.effectiveQuery,
  });

  final List<GiphyGifItem> items;
  final bool missingKey;

  /// Смещение текущей страницы (echo от сервера).
  final int offset;

  /// Общее число доступных результатов на сервере (если известно).
  final int total;

  /// Явный флаг с сервера. Для cursor-based pagination (GIPHY v2/emoji)
  /// total недоступен, но сервер ставит hasMore=true когда есть next_cursor.
  final bool? serverHasMore;

  /// Если запрос был переведён на английский — здесь оригинал пользователя
  /// (например "котики"), иначе null.
  final String? translatedFrom;

  /// Что реально ушло в GIPHY (на английском, если был перевод).
  final String? effectiveQuery;

  /// Можно ли загрузить ещё страницу.
  bool get hasMore => serverHasMore ?? (offset + items.length < total);
}

String _normalizeBaseUrl(String raw) {
  var s = raw.trim();
  while (s.endsWith('/')) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}

enum GiphyType { gifs, stickers, emoji }

String _typeParam(GiphyType type) {
  switch (type) {
    case GiphyType.gifs:
      return 'gifs';
    case GiphyType.stickers:
      return 'stickers';
    case GiphyType.emoji:
      return 'emoji';
  }
}

/// Запрос к веб-прокси GIF (`GIPHY_PROXY_BASE_URL`).
/// При пустом запросе возвращает trending GIF.
/// [type] = stickers даёт анимированные эмодзи/стикеры GIPHY.
/// [offset] — смещение для пагинации (страница = 24 элемента).
Future<GiphySearchOutcome> searchGifs(
  String query, {
  GiphyType type = GiphyType.gifs,
  int offset = 0,
}) async {
  final base = _normalizeBaseUrl(kGiphyProxyBaseUrl);
  if (base.isEmpty) {
    return const GiphySearchOutcome(items: []);
  }
  final q = query.trim();
  final params = <String, String>{
    if (q.isNotEmpty) 'q': q,
    if (type != GiphyType.gifs) 'type': _typeParam(type),
    if (offset > 0) 'offset': '$offset',
  };
  final uri = Uri.parse(
    '$base/api/giphy/search',
  ).replace(queryParameters: params.isEmpty ? null : params);

  // SECURITY: /api/giphy/search now requires a Firebase ID token. Without
  // it the route returns 401 and the picker stays empty. We attach the
  // current user's token; for anonymous flows (rare in mobile) we send no
  // header and accept the 401.
  final headers = <String, String>{};
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
  } catch (_) {
    // best-effort: token fetch may fail on cold start, fall through.
  }
  try {
    final res = await http
        .get(uri, headers: headers.isEmpty ? null : headers)
        .timeout(const Duration(seconds: 20));
    final body = jsonDecode(res.body);
    if (body is! Map<String, dynamic>) {
      return const GiphySearchOutcome(items: []);
    }
    final err = body['error'];
    if (err == 'missing_key') {
      return const GiphySearchOutcome(items: [], missingKey: true);
    }
    final rawItems = body['items'];
    if (rawItems is! List) {
      return GiphySearchOutcome(
        items: const [],
        missingKey: err == 'missing_key',
      );
    }
    final out = <GiphyGifItem>[];
    for (final e in rawItems) {
      if (e is! Map<String, dynamic>) continue;
      final id = e['id'];
      final url = e['url'];
      if (id is! String || url is! String || id.isEmpty || url.isEmpty) {
        continue;
      }
      final w = e['width'];
      final h = e['height'];
      final emojiRaw = e['emoji'];
      out.add(
        GiphyGifItem(
          id: id,
          url: url,
          emoji: emojiRaw is String && emojiRaw.trim().isNotEmpty
              ? emojiRaw.trim()
              : null,
          width: w is int ? w : (w is num ? w.toInt() : null),
          height: h is int ? h : (h is num ? h.toInt() : null),
        ),
      );
    }
    final off = body['offset'];
    final total = body['total'];
    final hasMoreRaw = body['hasMore'];
    final translatedFrom = body['translatedFrom'];
    final effectiveQuery = body['query'];
    return GiphySearchOutcome(
      items: out,
      missingKey: err == 'missing_key',
      offset: off is num ? off.toInt() : offset,
      total: total is num ? total.toInt() : out.length,
      serverHasMore: hasMoreRaw is bool ? hasMoreRaw : null,
      translatedFrom: translatedFrom is String ? translatedFrom : null,
      effectiveQuery: effectiveQuery is String ? effectiveQuery : null,
    );
  } catch (_) {
    return const GiphySearchOutcome(items: []);
  }
}

/// Преобразует GIPHY GIF/sticker/emoji в `ChatAttachment` для отправки.
///
/// Префиксы имени файла различаются по визуальному размеру у получателя:
///   - `gif_*`                 — inline GIF (обычный размер картинки в чате)
///   - `sticker_giphy_*`       — стикер из GIPHY-библиотеки (200px без пузыря)
///   - `sticker_emoji_giphy_*` — анимированный эмодзи (~76px, как unicode)
///
/// Детекторы в `message_attachments.dart` различают эти три случая
/// по префиксу. Поэтому важно не путать `asSticker` и `asAnimatedEmoji`.
ChatAttachment giphyItemToSendAttachment(
  GiphyGifItem item, {
  bool asSticker = false,
  bool asAnimatedEmoji = false,
}) {
  final String prefix;
  if (asAnimatedEmoji) {
    prefix = 'sticker_emoji_giphy_';
  } else if (asSticker) {
    prefix = 'sticker_giphy_';
  } else {
    prefix = 'gif_';
  }
  return ChatAttachment(
    url: item.url,
    name: '$prefix${item.id}.gif',
    type: 'image/gif',
    size: 0,
    width: item.width,
    height: item.height,
  );
}

String? giphyItemToEmojiText(GiphyGifItem item) {
  final direct = item.emoji?.trim();
  if (direct != null && direct.isNotEmpty) return direct;
  // Fallback: иногда id у emoji endpoint похож на hex-последовательность
  // codepoints: "1f44d" или "1f469-200d-1f4bb".
  final m = RegExp(
    r'([0-9a-fA-F]{4,6}(?:-[0-9a-fA-F]{4,6}){0,9})',
  ).firstMatch(item.id);
  if (m == null) return null;
  final seq = m.group(1);
  if (seq == null || seq.isEmpty) return null;
  final parts = seq.split('-');
  final cps = <int>[];
  for (final p in parts) {
    final cp = int.tryParse(p, radix: 16);
    if (cp == null || cp <= 0 || cp > 0x10FFFF) return null;
    cps.add(cp);
  }
  if (cps.isEmpty) return null;
  return String.fromCharCodes(cps);
}
