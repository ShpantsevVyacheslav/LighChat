import 'dart:convert';

import 'package:lighchat_models/lighchat_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kKey = 'recent_stickers_v1';
const _kMaxItems = 24;

class RecentStickersStore {
  RecentStickersStore._();
  static final instance = RecentStickersStore._();

  List<ChatAttachment>? _cache;

  Future<List<ChatAttachment>> getRecents() async {
    if (_cache != null) return _cache!;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kKey);
    if (raw == null || raw.isEmpty) {
      _cache = [];
      return _cache!;
    }
    final list = <ChatAttachment>[];
    for (final s in raw) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        list.add(ChatAttachment(
          url: m['url'] as String,
          name: m['name'] as String,
          type: m['type'] as String?,
          size: m['size'] as int?,
          width: m['width'] as int?,
          height: m['height'] as int?,
        ));
      } catch (_) {}
    }
    _cache = list;
    return list;
  }

  Future<void> addRecent(ChatAttachment att) async {
    final list = await getRecents();
    list.removeWhere((a) => a.url == att.url);
    list.insert(0, att);
    if (list.length > _kMaxItems) list.removeRange(_kMaxItems, list.length);
    _cache = list;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kKey,
      list.map((a) => jsonEncode(_toMap(a))).toList(),
    );
  }

  /// Сбросить in-memory кэш (после очистки SharedPreferences извне,
  /// например из «Хранилище» → «Стикеры/GIF/эмодзи»).
  void invalidateCache() {
    _cache = null;
  }

  static Map<String, Object?> _toMap(ChatAttachment a) => {
        'url': a.url,
        'name': a.name,
        'type': a.type,
        'size': a.size,
        'width': a.width,
        'height': a.height,
      };
}
