import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lighchat_models/lighchat_models.dart';

import 'giphy_proxy_config.dart';

class GiphyGifItem {
  const GiphyGifItem({
    required this.id,
    required this.url,
    this.width,
    this.height,
  });

  final String id;
  final String url;
  final int? width;
  final int? height;
}

/// Паритет ответа `src/app/api/tenor/search/route.ts` (исторически endpoint
/// называется `tenor`, фактически это GIPHY API).
class GiphySearchOutcome {
  const GiphySearchOutcome({
    required this.items,
    this.missingKey = false,
  });

  final List<GiphyGifItem> items;
  final bool missingKey;
}

String _normalizeBaseUrl(String raw) {
  var s = raw.trim();
  while (s.endsWith('/')) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}

enum GiphyType { gifs, stickers }

/// Запрос к веб-прокси GIF (`GIPHY_PROXY_BASE_URL`).
/// При пустом запросе возвращает trending GIF.
/// [type] = stickers даёт анимированные эмодзи/стикеры GIPHY.
Future<GiphySearchOutcome> searchGifs(
  String query, {
  GiphyType type = GiphyType.gifs,
}) async {
  final base = _normalizeBaseUrl(kGiphyProxyBaseUrl);
  if (base.isEmpty) {
    return const GiphySearchOutcome(items: []);
  }
  final q = query.trim();
  final params = <String, String>{
    if (q.isNotEmpty) 'q': q,
    if (type == GiphyType.stickers) 'type': 'stickers',
  };
  final uri = Uri.parse('$base/api/giphy/search').replace(
    queryParameters: params.isEmpty ? null : params,
  );

  try {
    final res = await http.get(uri).timeout(const Duration(seconds: 20));
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
      out.add(GiphyGifItem(
        id: id,
        url: url,
        width: w is int ? w : (w is num ? w.toInt() : null),
        height: h is int ? h : (h is num ? h.toInt() : null),
      ));
    }
    return GiphySearchOutcome(items: out, missingKey: err == 'missing_key');
  } catch (_) {
    return const GiphySearchOutcome(items: []);
  }
}

ChatAttachment giphyItemToSendAttachment(GiphyGifItem item) {
  return ChatAttachment(
    url: item.url,
    name: 'gif_${item.id}.gif',
    type: 'image/gif',
    size: 0,
    width: item.width,
    height: item.height,
  );
}
