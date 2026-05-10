import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'giphy_gif_search.dart';

/// SharedPreferences-ключ агрегированного кеша GIPHY-выдач (gifs / stickers /
/// emoji). Экспортирован для интеграции с экраном «Хранилище» — чтобы можно
/// было оценить размер и при необходимости очистить.
const String kGiphyQueryCachePrefsKey = 'giphy_query_cache_v2';

/// SharedPreferences-ключ списка последних отправленных GIF.
const String kGiphyRecentGifsPrefsKey = 'giphy_recent_gifs_v1';

/// Локальный кеш GIPHY-выдач:
/// - **query-cache**: результаты поиска по любой паре `(type, query)` с TTL 24h
///   (trending = пустой query). LRU-лимит на 20 ключей чтобы кеш не разросся.
/// - **recent**: последние 30 «просмотренных» (отправленных) GIF.
///
/// Хранится в `SharedPreferences` как JSON.
class GiphyCacheStore {
  GiphyCacheStore._();
  static final instance = GiphyCacheStore._();

  static const _kQueryCacheKey = kGiphyQueryCachePrefsKey;
  static const _kRecentGifsKey = kGiphyRecentGifsPrefsKey;
  static const Duration _kTtl = Duration(hours: 24);
  static const int _kMaxKeys = 20;
  static const int _kRecentMax = 30;

  String _cacheKey(GiphyType type, String query) {
    final t = switch (type) {
      GiphyType.gifs => 'gifs',
      GiphyType.stickers => 'stickers',
      GiphyType.emoji => 'emoji',
    };
    return '$t:${query.trim()}';
  }

  /// Возвращает закешированные items для пары `(type, query)`, если запись
  /// не старше 24h. Иначе null.
  ///
  /// **Исключение**: для `GiphyType.emoji` (анимированные эмодзи) TTL
  /// не применяется — каталог GIPHY-эмодзи стабильный, новые позиции
  /// добираются только через пагинацию (см. `_loadMoreAnimEmojis`),
  /// а старые остаются в кеше навсегда.
  Future<List<GiphyGifItem>?> get(GiphyType type, String query) async {
    final all = await _loadAll();
    final entry = all[_cacheKey(type, query)];
    if (entry == null) return null;
    if (type != GiphyType.emoji &&
        DateTime.now().millisecondsSinceEpoch - entry.ts >
            _kTtl.inMilliseconds) {
      return null;
    }
    return entry.items;
  }

  /// Сохраняет items по `(type, query)`. LRU: если ключей больше 20 —
  /// удаляем самый старый по `ts` (а не по позиции).
  Future<void> save(
    GiphyType type,
    String query,
    List<GiphyGifItem> items,
  ) async {
    if (items.isEmpty) return;
    final all = await _loadAll();
    final key = _cacheKey(type, query);
    all[key] = _CacheEntry(
      ts: DateTime.now().millisecondsSinceEpoch,
      items: items,
    );
    if (all.length > _kMaxKeys) {
      // Эмодзи-ключи (`emoji:*`) защищены от LRU-вытеснения — каталог
      // эмодзи строится навсегда, его нельзя терять.
      final sorted =
          all.entries.where((e) => !e.key.startsWith('emoji:')).toList()
            ..sort((a, b) => a.value.ts.compareTo(b.value.ts));
      final toRemove = all.length - _kMaxKeys;
      for (var i = 0; i < toRemove && i < sorted.length; i++) {
        all.remove(sorted[i].key);
      }
    }
    await _saveAll(all);
  }

  // ---- Backward-compatible trending API ----

  /// Возвращает trending (`q=''`) из кеша.
  Future<List<GiphyGifItem>?> getTrending(GiphyType type) => get(type, '');

  /// Сохраняет trending (`q=''`).
  Future<void> saveTrending(GiphyType type, List<GiphyGifItem> items) =>
      save(type, '', items);

  // ---- Recent (отправленные пользователем) ----

  Future<List<GiphyGifItem>> getRecent() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kRecentGifsKey);
    if (raw == null || raw.isEmpty) return [];
    final out = <GiphyGifItem>[];
    for (final s in raw) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        final item = _itemFromMap(m);
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
      list.map((a) => jsonEncode(_itemToMap(a))).toList(),
    );
  }

  // ---- Internal ----

  Future<Map<String, _CacheEntry>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kQueryCacheKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final out = <String, _CacheEntry>{};
      m.forEach((k, v) {
        if (v is! Map) return;
        final entry = _CacheEntry.fromMap(v.cast<String, dynamic>());
        if (entry != null) out[k] = entry;
      });
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveAll(Map<String, _CacheEntry> all) async {
    final prefs = await SharedPreferences.getInstance();
    final m = <String, Object?>{};
    all.forEach((k, v) => m[k] = v.toMap());
    await prefs.setString(_kQueryCacheKey, jsonEncode(m));
  }

  static Map<String, Object?> _itemToMap(GiphyGifItem a) => {
    'id': a.id,
    'url': a.url,
    'emoji': a.emoji,
    'label': a.label,
    'width': a.width,
    'height': a.height,
  };

  static GiphyGifItem? _itemFromMap(Map<String, dynamic> m) {
    final id = m['id'];
    final url = m['url'];
    if (id is! String || url is! String || id.isEmpty || url.isEmpty) {
      return null;
    }
    final w = m['width'];
    final h = m['height'];
    final emoji = m['emoji'];
    final label = m['label'];
    return GiphyGifItem(
      id: id,
      url: url,
      emoji: emoji is String && emoji.trim().isNotEmpty ? emoji.trim() : null,
      label: label is String && label.trim().isNotEmpty ? label.trim() : null,
      width: w is int ? w : (w is num ? w.toInt() : null),
      height: h is int ? h : (h is num ? h.toInt() : null),
    );
  }
}

class _CacheEntry {
  _CacheEntry({required this.ts, required this.items});
  final int ts;
  final List<GiphyGifItem> items;

  Map<String, Object?> toMap() => {
    'ts': ts,
    'items': items.map(GiphyCacheStore._itemToMap).toList(),
  };

  static _CacheEntry? fromMap(Map<String, dynamic> m) {
    final ts = m['ts'];
    final raw = m['items'];
    if (ts is! num || raw is! List) return null;
    final items = <GiphyGifItem>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final it = GiphyCacheStore._itemFromMap(e.cast<String, dynamic>());
      if (it != null) items.add(it);
    }
    return _CacheEntry(ts: ts.toInt(), items: items);
  }
}
