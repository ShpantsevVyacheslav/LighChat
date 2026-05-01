import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
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

/// Categories the user can toggle on/off (heavy files).
const kUserToggleableCategories = <LocalStorageCategory>[
  LocalStorageCategory.e2eeMedia,
  LocalStorageCategory.videoDownloads,
];

/// Categories always kept locally (lightweight data, no user toggle).
const kAlwaysOnCategories = <LocalStorageCategory>[
  LocalStorageCategory.e2eeText,
  LocalStorageCategory.chatDrafts,
  LocalStorageCategory.chatListSnapshot,
  LocalStorageCategory.profileCards,
  LocalStorageCategory.videoThumbs,
];

class LocalStoragePreferences {
  const LocalStoragePreferences({
    required this.e2eeMediaEnabled,
    required this.videoDownloadsEnabled,
    required this.cacheBudgetGb,
  });

  final bool e2eeMediaEnabled;
  final bool videoDownloadsEnabled;
  final int cacheBudgetGb;

  static const int minCacheBudgetGb = 1;
  static const int defaultMaxCacheBudgetGb = 128;

  static int _detectedMaxGb = defaultMaxCacheBudgetGb;
  static bool _maxDetected = false;

  static int get maxCacheBudgetGb => _detectedMaxGb;

  static Future<void> detectDeviceStorage() async {
    if (_maxDetected) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final result = await Process.run('df', ['-k', dir.path]);
      if (result.exitCode == 0) {
        final lines = (result.stdout as String).split('\n');
        if (lines.length >= 2) {
          final parts = lines[1].trim().split(RegExp(r'\s+'));
          if (parts.length >= 2) {
            final totalKb = int.tryParse(parts[1]);
            if (totalKb != null && totalKb > 0) {
              _detectedMaxGb = (totalKb / (1024 * 1024)).ceil().clamp(1, 2048);
            }
          }
        }
      }
    } catch (_) {}
    _maxDetected = true;
  }

  factory LocalStoragePreferences.defaults() {
    return const LocalStoragePreferences(
      e2eeMediaEnabled: true,
      videoDownloadsEnabled: true,
      cacheBudgetGb: 8,
    );
  }

  LocalStoragePreferences copyWith({
    bool? e2eeMediaEnabled,
    bool? videoDownloadsEnabled,
    int? cacheBudgetGb,
  }) {
    return LocalStoragePreferences(
      e2eeMediaEnabled: e2eeMediaEnabled ?? this.e2eeMediaEnabled,
      videoDownloadsEnabled: videoDownloadsEnabled ?? this.videoDownloadsEnabled,
      cacheBudgetGb: (cacheBudgetGb ?? this.cacheBudgetGb).clamp(
        minCacheBudgetGb,
        maxCacheBudgetGb,
      ),
    );
  }

  bool enabledFor(LocalStorageCategory category) {
    switch (category) {
      case LocalStorageCategory.e2eeMedia:
        return e2eeMediaEnabled;
      case LocalStorageCategory.videoDownloads:
        return videoDownloadsEnabled;
      case LocalStorageCategory.e2eeText:
      case LocalStorageCategory.chatDrafts:
      case LocalStorageCategory.chatListSnapshot:
      case LocalStorageCategory.profileCards:
      case LocalStorageCategory.videoThumbs:
        return true;
    }
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'e2eeMediaEnabled': e2eeMediaEnabled,
      'videoDownloadsEnabled': videoDownloadsEnabled,
      'cacheBudgetGb': cacheBudgetGb,
    };
  }

  factory LocalStoragePreferences.fromJson(Map<String, Object?> raw) {
    final defaults = LocalStoragePreferences.defaults();

    int budget = defaults.cacheBudgetGb;
    if (raw['cacheBudgetGb'] is num) {
      budget = (raw['cacheBudgetGb'] as num).toInt();
    } else if (raw['cacheBudgetMb'] is num) {
      budget = ((raw['cacheBudgetMb'] as num) / 1024).ceil().clamp(1, 2048);
    }

    return LocalStoragePreferences(
      e2eeMediaEnabled: raw['e2eeMediaEnabled'] is bool
          ? raw['e2eeMediaEnabled'] as bool
          : defaults.e2eeMediaEnabled,
      videoDownloadsEnabled: raw['videoDownloadsEnabled'] is bool
          ? raw['videoDownloadsEnabled'] as bool
          : defaults.videoDownloadsEnabled,
      cacheBudgetGb: budget.clamp(minCacheBudgetGb, maxCacheBudgetGb),
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
    await LocalStoragePreferences.detectDeviceStorage();
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
