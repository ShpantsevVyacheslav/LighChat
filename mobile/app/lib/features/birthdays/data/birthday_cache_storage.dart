import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lighchat_mobile/core/app_logger.dart';

/// Локальный кэш дат рождения контактов: одно SharedPreferences-значение на пользователя
/// со словарём `{ contactId: { dob: 'YYYY-MM-DD'|null, fetchedAt: iso } }`. Когда
/// `fetchedAt` старше TTL (24 часа) или записи нет — провайдер делает один read
/// в `users/{contactId}` и кэширует результат. `dob: null` означает, что мы уже
/// проверили и контакт либо скрыл ДР, либо не задал — это валидный негативный
/// результат, его тоже кэшируем, чтобы не долбить Firestore.
const _kBirthdayCacheKeyPrefix = 'mobile_contact_birthday_cache_v1_';
const Duration kBirthdayCacheTtl = Duration(hours: 24);

String birthdayCacheKey(String ownerUserId) =>
    '$_kBirthdayCacheKeyPrefix$ownerUserId';

class BirthdayCacheEntry {
  const BirthdayCacheEntry({required this.dob, required this.fetchedAt});

  /// Дата рождения в формате `YYYY-MM-DD` или `null` если контакт скрыл ДР /
  /// не задал. Год может отсутствовать (формат `YYYY-MM-DD` всегда, но 1900
  /// или подобный sentinel допустимо в исходных данных — UI игнорирует).
  final String? dob;
  final DateTime fetchedAt;

  bool get isFresh =>
      DateTime.now().toUtc().difference(fetchedAt) < kBirthdayCacheTtl;

  Map<String, Object?> toJson() => {
        'dob': dob,
        'fetchedAt': fetchedAt.toUtc().toIso8601String(),
      };

  static BirthdayCacheEntry? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = raw.map((k, v) => MapEntry(k.toString(), v));
    final fetched = DateTime.tryParse('${m['fetchedAt'] ?? ''}');
    if (fetched == null) return null;
    final dob = m['dob'];
    return BirthdayCacheEntry(
      dob: dob is String && dob.isNotEmpty ? dob : null,
      fetchedAt: fetched,
    );
  }
}

class BirthdayCacheStorage {
  const BirthdayCacheStorage();

  Future<Map<String, BirthdayCacheEntry>> load(String ownerUserId) async {
    final owner = ownerUserId.trim();
    if (owner.isEmpty) return const {};
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(birthdayCacheKey(owner));
      if (raw == null || raw.trim().isEmpty) return const {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      final out = <String, BirthdayCacheEntry>{};
      for (final e in decoded.entries) {
        final entry = BirthdayCacheEntry.fromJson(e.value);
        if (entry == null) continue;
        out[e.key.toString()] = entry;
      }
      return out;
    } catch (e, st) {
      if (kDebugMode) {
        appLogger.w('BirthdayCacheStorage.load failed',
            error: e, stackTrace: st);
      }
      return const {};
    }
  }

  Future<void> save(
    String ownerUserId,
    Map<String, BirthdayCacheEntry> entries,
  ) async {
    final owner = ownerUserId.trim();
    if (owner.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(
        entries.map((k, v) => MapEntry(k, v.toJson())),
      );
      await prefs.setString(birthdayCacheKey(owner), encoded);
    } catch (e, st) {
      if (kDebugMode) {
        appLogger.w('BirthdayCacheStorage.save failed',
            error: e, stackTrace: st);
      }
    }
  }
}

/// Дата дисмисса плашки — хранится одним ключом `YYYY-MM-DD` в локальной зоне.
/// Если совпадает с сегодняшней — плашку не показываем.
const String kDismissedBirthdayBannerKey =
    'mobile_birthday_banner_dismissed_date_v1';

Future<String?> loadBirthdayBannerDismissedDate() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kDismissedBirthdayBannerKey);
  } catch (_) {
    return null;
  }
}

Future<void> saveBirthdayBannerDismissedDate(String localYmd) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kDismissedBirthdayBannerKey, localYmd);
  } catch (_) {
    // ignore: best-effort persistence
  }
}
