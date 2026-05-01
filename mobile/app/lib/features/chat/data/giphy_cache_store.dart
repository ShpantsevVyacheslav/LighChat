import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'giphy_gif_search.dart';

/// Локальный кеш GIPHY-выдач:
/// - trending по умолчанию (TTL 24 часа)
/// - последние 30 «просмотренных» (отправленных) GIF
///
/// Хранится в `SharedPreferences` как JSON. Ничего не отправляет на сервер
/// без явного запроса.
class GiphyCacheStore {
  GiphyCacheStore._();
  static final instance = GiphyCacheStore._();

  static const _kTrendingGifsKey = 'giphy_trending_gifs_v1';
  static const _kTrendingStickersKey = 'giphy_trending_stickers_v1';
  static const _kRecentGifsKey = 'giphy_recent_gifs_v1';
  static const Duration _kTrendingTtl = Duration(hours: 24);
  static const int _kRecentMax = 30;

  String _key(GiphyType type) => switch (type) {
        GiphyType.gifs => _kTrendingGifsKey,
        GiphyType.stickers => _kTrendingStickersKey,
      };

  /// Возвращает trending из кеша, если он не старше 24h, иначе null.
  Future<List<GiphyGifItem>?> getTrending(GiphyType type) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(type));
    if (raw == null || raw.isEmpty) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (m['ts'] as num?)?.toInt();
      if (ts == null) return null;
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      if (age > _kTrendingTtl.inMilliseconds) return null;
      final list = m['items'] as List?;
      if (list == null) return null;
      return list
          .whereType<Map<String, dynamic>>()
          .map(_fromMap)
          .whereType<GiphyGifItem>()
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTrending(GiphyType type, List<GiphyGifItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final body = jsonEncode({
      'ts': DateTime.now().millisecondsSinceEpoch,
      'items': items.map(_toMap).toList(),
    });
    await prefs.setString(_key(type), body);
  }

  /// Последние просмотренные GIF (по убыванию новизны).
  Future<List<GiphyGifItem>> getRecent() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kRecentGifsKey);
    if (raw == null || raw.isEmpty) return [];
    final out = <GiphyGifItem>[];
    for (final s in raw) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        final item = _fromMap(m);
        if (item != null) out.add(item);
      } catch (_) {}
    }
    return out;
  }

  Future<void> addRecent(GiphyGifItem item) async {
    final list = await getRecent();
    list.removeWhere((a) => a.url == item.url || a.id == item.id);
    list.insert(0, item);
    if (list.length > _kRecentMax) list.removeRange(_kRecentMax, list.length);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kRecentGifsKey,
      list.map((a) => jsonEncode(_toMap(a))).toList(),
    );
  }

  static Map<String, Object?> _toMap(GiphyGifItem a) => {
        'id': a.id,
        'url': a.url,
        'width': a.width,
        'height': a.height,
      };

  static GiphyGifItem? _fromMap(Map<String, dynamic> m) {
    final id = m['id'];
    final url = m['url'];
    if (id is! String || url is! String || id.isEmpty || url.isEmpty) {
      return null;
    }
    final w = m['width'];
    final h = m['height'];
    return GiphyGifItem(
      id: id,
      url: url,
      width: w is int ? w : (w is num ? w.toInt() : null),
      height: h is int ? h : (h is num ? h.toInt() : null),
    );
  }
}
