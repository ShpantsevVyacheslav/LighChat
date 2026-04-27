import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_block_utils.dart';

/// Соответствует web `PrivacySettings` (флаги видимости полей для других).
class UserPrivacySettings {
  const UserPrivacySettings({
    this.showOnlineStatus,
    this.showLastSeen,
    this.showReadReceipts,
    this.showEmailToOthers,
    this.showPhoneToOthers,
    this.showBioToOthers,
    this.showDateOfBirthToOthers,
    this.showInGlobalUserSearch,
  });

  final bool? showOnlineStatus;
  final bool? showLastSeen;
  final bool? showReadReceipts;
  final bool? showEmailToOthers;
  final bool? showPhoneToOthers;
  final bool? showBioToOthers;
  final bool? showDateOfBirthToOthers;

  /// Web `privacySettings.showInGlobalUserSearch` — листинг в «все пользователи» при новом чате.
  final bool? showInGlobalUserSearch;

  static UserPrivacySettings? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = raw.map((k, v) => MapEntry(k.toString(), v));
    return UserPrivacySettings(
      showOnlineStatus: m['showOnlineStatus'] is bool
          ? m['showOnlineStatus'] as bool
          : null,
      showLastSeen: m['showLastSeen'] is bool
          ? m['showLastSeen'] as bool
          : null,
      showReadReceipts: m['showReadReceipts'] is bool
          ? m['showReadReceipts'] as bool
          : null,
      showEmailToOthers: m['showEmailToOthers'] is bool
          ? m['showEmailToOthers'] as bool
          : null,
      showPhoneToOthers: m['showPhoneToOthers'] is bool
          ? m['showPhoneToOthers'] as bool
          : null,
      showBioToOthers: m['showBioToOthers'] is bool
          ? m['showBioToOthers'] as bool
          : null,
      showDateOfBirthToOthers: m['showDateOfBirthToOthers'] is bool
          ? m['showDateOfBirthToOthers'] as bool
          : null,
      showInGlobalUserSearch: m['showInGlobalUserSearch'] is bool
          ? m['showInGlobalUserSearch'] as bool
          : null,
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    this.username,
    this.avatar,
    this.avatarThumb,
    this.profileQrLink,
    this.email,
    this.phone,
    this.bio,
    this.role,
    this.online,
    this.lastSeenAt,
    this.dateOfBirth,
    this.deletedAt,
    this.privacySettings,
    this.blockedUserIds = const <String>[],
  });

  final String id;
  final String name;
  final String? username;
  final String? avatar;
  final String? avatarThumb;
  final String? profileQrLink;
  final String? email;
  final String? phone;
  final String? bio;

  /// Web `UserRole`: `admin` | `worker`.
  final String? role;
  final bool? online;
  final DateTime? lastSeenAt;
  final String? dateOfBirth;
  final String? deletedAt;
  final UserPrivacySettings? privacySettings;

  /// Web `users.blockedUserIds` — uid, которых этот пользователь заблокировал.
  final List<String> blockedUserIds;

  static DateTime? _parseLastSeen(Object? raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    return null;
  }

  static String? _parseDeletedAt(Object? raw) {
    if (raw == null) return null;
    if (raw is String) return raw.isEmpty ? null : raw;
    if (raw is Timestamp) return raw.toDate().toIso8601String();
    return null;
  }

  static UserProfile? fromJson(String id, Map<String, Object?> json) {
    final name = json['name'];
    if (name is! String || name.trim().isEmpty) return null;
    final username = json['username'] is String
        ? json['username'] as String
        : null;
    final avatar = json['avatar'] is String ? json['avatar'] as String : null;
    final avatarThumb = json['avatarThumb'] is String
        ? json['avatarThumb'] as String
        : null;
    final profileQrLink = json['profileQrLink'] is String
        ? json['profileQrLink'] as String
        : null;
    final email = json['email'] is String ? json['email'] as String : null;
    final phone = json['phone'] is String ? json['phone'] as String : null;
    final bio = json['bio'] is String ? json['bio'] as String : null;
    final role = json['role'] is String ? json['role'] as String : null;
    final online = json['online'] is bool ? json['online'] as bool : null;
    final lastSeenAt = _parseLastSeen(json['lastSeen']);
    final dateOfBirth = json['dateOfBirth'] is String
        ? json['dateOfBirth'] as String
        : null;
    final deletedAt = _parseDeletedAt(json['deletedAt']);
    final privacySettings = UserPrivacySettings.fromJson(
      json['privacySettings'],
    );
    final blockedUserIds = normalizeBlockedUserIds(json['blockedUserIds']);

    return UserProfile(
      id: id,
      name: name.trim(),
      username: username,
      avatar: avatar,
      avatarThumb: avatarThumb,
      profileQrLink: profileQrLink,
      email: email,
      phone: phone,
      bio: bio,
      role: role,
      online: online,
      lastSeenAt: lastSeenAt,
      dateOfBirth: dateOfBirth,
      deletedAt: deletedAt,
      privacySettings: privacySettings,
      blockedUserIds: blockedUserIds,
    );
  }
}
