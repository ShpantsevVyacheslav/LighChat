import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum LocalStorageCategory {
  e2eeMedia,
  e2eeText,
  chatDrafts,
  chatListSnapshot,
  profileCards,
  videoDownloads,
  videoThumbs,
}

class LocalStoragePreferences {
  const LocalStoragePreferences({
    required this.e2eeMediaEnabled,
    required this.e2eeTextEnabled,
    required this.chatDraftsEnabled,
    required this.chatListSnapshotEnabled,
    required this.profileCardsEnabled,
    required this.videoDownloadsEnabled,
    required this.videoThumbsEnabled,
    required this.cacheBudgetMb,
  });

  final bool e2eeMediaEnabled;
  final bool e2eeTextEnabled;
  final bool chatDraftsEnabled;
  final bool chatListSnapshotEnabled;
  final bool profileCardsEnabled;
  final bool videoDownloadsEnabled;
  final bool videoThumbsEnabled;
  final int cacheBudgetMb;

  static const int minCacheBudgetMb = 128;
  static const int maxCacheBudgetMb = 8192;

  factory LocalStoragePreferences.defaults() {
    return const LocalStoragePreferences(
      e2eeMediaEnabled: true,
      e2eeTextEnabled: true,
      chatDraftsEnabled: true,
      chatListSnapshotEnabled: true,
      profileCardsEnabled: true,
      videoDownloadsEnabled: true,
      videoThumbsEnabled: true,
      cacheBudgetMb: 1024,
    );
  }

  LocalStoragePreferences copyWith({
    bool? e2eeMediaEnabled,
    bool? e2eeTextEnabled,
    bool? chatDraftsEnabled,
    bool? chatListSnapshotEnabled,
    bool? profileCardsEnabled,
    bool? videoDownloadsEnabled,
    bool? videoThumbsEnabled,
    int? cacheBudgetMb,
  }) {
    return LocalStoragePreferences(
      e2eeMediaEnabled: e2eeMediaEnabled ?? this.e2eeMediaEnabled,
      e2eeTextEnabled: e2eeTextEnabled ?? this.e2eeTextEnabled,
      chatDraftsEnabled: chatDraftsEnabled ?? this.chatDraftsEnabled,
      chatListSnapshotEnabled:
          chatListSnapshotEnabled ?? this.chatListSnapshotEnabled,
      profileCardsEnabled: profileCardsEnabled ?? this.profileCardsEnabled,
      videoDownloadsEnabled:
          videoDownloadsEnabled ?? this.videoDownloadsEnabled,
      videoThumbsEnabled: videoThumbsEnabled ?? this.videoThumbsEnabled,
      cacheBudgetMb: (cacheBudgetMb ?? this.cacheBudgetMb).clamp(
        minCacheBudgetMb,
        maxCacheBudgetMb,
      ),
    );
  }

  bool enabledFor(LocalStorageCategory category) {
    switch (category) {
      case LocalStorageCategory.e2eeMedia:
        return e2eeMediaEnabled;
      case LocalStorageCategory.e2eeText:
        return e2eeTextEnabled;
      case LocalStorageCategory.chatDrafts:
        return chatDraftsEnabled;
      case LocalStorageCategory.chatListSnapshot:
        return chatListSnapshotEnabled;
      case LocalStorageCategory.profileCards:
        return profileCardsEnabled;
      case LocalStorageCategory.videoDownloads:
        return videoDownloadsEnabled;
      case LocalStorageCategory.videoThumbs:
        return videoThumbsEnabled;
    }
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'e2eeMediaEnabled': e2eeMediaEnabled,
      'e2eeTextEnabled': e2eeTextEnabled,
      'chatDraftsEnabled': chatDraftsEnabled,
      'chatListSnapshotEnabled': chatListSnapshotEnabled,
      'profileCardsEnabled': profileCardsEnabled,
      'videoDownloadsEnabled': videoDownloadsEnabled,
      'videoThumbsEnabled': videoThumbsEnabled,
      'cacheBudgetMb': cacheBudgetMb,
    };
  }

  factory LocalStoragePreferences.fromJson(Map<String, Object?> raw) {
    final defaults = LocalStoragePreferences.defaults();
    final budgetRaw = raw['cacheBudgetMb'];
    final budget = budgetRaw is int
        ? budgetRaw
        : budgetRaw is num
        ? budgetRaw.toInt()
        : defaults.cacheBudgetMb;
    return LocalStoragePreferences(
      e2eeMediaEnabled: raw['e2eeMediaEnabled'] is bool
          ? raw['e2eeMediaEnabled'] as bool
          : defaults.e2eeMediaEnabled,
      e2eeTextEnabled: raw['e2eeTextEnabled'] is bool
          ? raw['e2eeTextEnabled'] as bool
          : defaults.e2eeTextEnabled,
      chatDraftsEnabled: raw['chatDraftsEnabled'] is bool
          ? raw['chatDraftsEnabled'] as bool
          : defaults.chatDraftsEnabled,
      chatListSnapshotEnabled: raw['chatListSnapshotEnabled'] is bool
          ? raw['chatListSnapshotEnabled'] as bool
          : defaults.chatListSnapshotEnabled,
      profileCardsEnabled: raw['profileCardsEnabled'] is bool
          ? raw['profileCardsEnabled'] as bool
          : defaults.profileCardsEnabled,
      videoDownloadsEnabled: raw['videoDownloadsEnabled'] is bool
          ? raw['videoDownloadsEnabled'] as bool
          : defaults.videoDownloadsEnabled,
      videoThumbsEnabled: raw['videoThumbsEnabled'] is bool
          ? raw['videoThumbsEnabled'] as bool
          : defaults.videoThumbsEnabled,
      cacheBudgetMb: budget.clamp(minCacheBudgetMb, maxCacheBudgetMb),
    );
  }
}

class LocalStoragePreferencesStore {
  LocalStoragePreferencesStore._();

  static const String _prefsKey = 'mobile_local_storage_preferences_v1';

  static LocalStoragePreferences _cached = LocalStoragePreferences.defaults();
  static bool _loaded = false;

  static LocalStoragePreferences currentSync() => _cached;

  static Future<LocalStoragePreferences> load() async {
    if (_loaded) return _cached;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.trim().isEmpty) {
      _cached = LocalStoragePreferences.defaults();
      _loaded = true;
      return _cached;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        _cached = LocalStoragePreferences.defaults();
        _loaded = true;
        return _cached;
      }
      _cached = LocalStoragePreferences.fromJson(
        decoded.map((k, v) => MapEntry(k.toString(), v)),
      );
    } catch (_) {
      _cached = LocalStoragePreferences.defaults();
    }
    _loaded = true;
    return _cached;
  }

  static Future<LocalStoragePreferences> save(
    LocalStoragePreferences value,
  ) async {
    _cached = value;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(value.toJson()));
    return _cached;
  }
}
