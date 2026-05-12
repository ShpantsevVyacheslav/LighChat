import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lighchat_mobile/core/app_logger.dart';
import 'user_profile.dart';

const kUserProfileDiskCacheKeyPrefix = 'mobile_user_profile_cache_v1_';

String userProfileDiskCacheKey(String userId) =>
    '$kUserProfileDiskCacheKeyPrefix$userId';

/// Последние известные профили (имя, аватар, username) для мгновенного UI без сети.
Future<Map<String, UserProfile>> loadCachedProfiles(
  Iterable<String> userIds,
) async {
  final out = <String, UserProfile>{};
  try {
    final prefs = await SharedPreferences.getInstance();
    for (final rawId in userIds) {
      final id = rawId.trim();
      if (id.isEmpty) continue;
      final s = prefs.getString(userProfileDiskCacheKey(id));
      if (s == null || s.trim().isEmpty) continue;
      final decoded = jsonDecode(s);
      if (decoded is! Map) continue;
      final m = decoded.map((k, v) => MapEntry(k.toString(), v));
      final p = UserProfile.fromJson(id, m);
      if (p != null) out[id] = p;
    }
  } catch (e, st) {
    if (kDebugMode) {
      appLogger.w('loadCachedProfiles failed', error: e, stackTrace: st);
    }
  }
  return out;
}

Future<void> persistProfile(UserProfile profile) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final m = <String, Object?>{
      'name': profile.name,
      if (profile.username != null && profile.username!.trim().isNotEmpty)
        'username': profile.username,
      if (profile.avatar != null && profile.avatar!.trim().isNotEmpty)
        'avatar': profile.avatar,
      if (profile.avatarThumb != null && profile.avatarThumb!.trim().isNotEmpty)
        'avatarThumb': profile.avatarThumb,
      if (profile.role != null && profile.role!.trim().isNotEmpty)
        'role': profile.role,
      if (profile.online != null) 'online': profile.online,
      if (profile.lastSeenAt != null)
        'lastSeen': profile.lastSeenAt!.toUtc().toIso8601String(),
    };
    await prefs.setString(userProfileDiskCacheKey(profile.id), jsonEncode(m));
  } catch (e, st) {
    if (kDebugMode) {
      appLogger.w('persistProfile failed', error: e, stackTrace: st);
    }
  }
}
