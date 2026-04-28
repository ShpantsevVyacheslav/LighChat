typedef JsonMap = Map<String, Object?>;

/// Conversation.secretChat config (shared schema with web).
class SecretChatConfig {
  const SecretChatConfig({
    required this.enabled,
    required this.createdAt,
    required this.createdBy,
    required this.expiresAt,
    required this.ttlPresetSec,
    required this.lockPolicy,
    required this.restrictions,
    this.mediaViewPolicy,
  });

  final bool enabled; // must be true when present
  final String createdAt;
  final String createdBy;
  final String expiresAt;
  final int ttlPresetSec;
  final SecretChatLockPolicy lockPolicy;
  final SecretChatRestrictions restrictions;
  final SecretChatMediaViewPolicy? mediaViewPolicy;

  static SecretChatConfig? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = raw.map((k, v) => MapEntry(k.toString(), v));
    if (m['enabled'] != true) return null;
    final createdAt = m['createdAt'];
    final createdBy = m['createdBy'];
    final expiresAt = m['expiresAt'];
    final ttl = m['ttlPresetSec'];
    if (createdAt is! String || createdAt.isEmpty) return null;
    if (createdBy is! String || createdBy.isEmpty) return null;
    if (expiresAt is! String || expiresAt.isEmpty) return null;
    final ttlSec = ttl is int ? ttl : (ttl is num ? ttl.toInt() : null);
    if (ttlSec == null || ttlSec <= 0) return null;
    final lock = SecretChatLockPolicy.fromJson(m['lockPolicy']);
    final restr = SecretChatRestrictions.fromJson(m['restrictions']);
    if (lock == null || restr == null) return null;
    final media = SecretChatMediaViewPolicy.fromJson(m['mediaViewPolicy']);
    return SecretChatConfig(
      enabled: true,
      createdAt: createdAt,
      createdBy: createdBy,
      expiresAt: expiresAt,
      ttlPresetSec: ttlSec,
      lockPolicy: lock,
      restrictions: restr,
      mediaViewPolicy: media,
    );
  }
}

class SecretChatLockPolicy {
  const SecretChatLockPolicy({required this.required, required this.grantTtlSec});

  final bool required;
  final int grantTtlSec;

  static SecretChatLockPolicy? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = raw.map((k, v) => MapEntry(k.toString(), v));
    final req = m['required'];
    final ttl = m['grantTtlSec'];
    if (req is! bool) return null;
    final ttlSec = ttl is int ? ttl : (ttl is num ? ttl.toInt() : null);
    if (ttlSec == null || ttlSec <= 0) return null;
    return SecretChatLockPolicy(required: req, grantTtlSec: ttlSec);
  }
}

class SecretChatRestrictions {
  const SecretChatRestrictions({
    required this.noForward,
    required this.noCopy,
    required this.noSave,
    required this.screenshotProtection,
  });

  final bool noForward;
  final bool noCopy;
  final bool noSave;
  final bool screenshotProtection;

  static SecretChatRestrictions? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = raw.map((k, v) => MapEntry(k.toString(), v));
    final noForward = m['noForward'];
    final noCopy = m['noCopy'];
    final noSave = m['noSave'];
    final screenshotProtection = m['screenshotProtection'];
    if (noForward is! bool) return null;
    if (noCopy is! bool) return null;
    if (noSave is! bool) return null;
    if (screenshotProtection is! bool) return null;
    return SecretChatRestrictions(
      noForward: noForward,
      noCopy: noCopy,
      noSave: noSave,
      screenshotProtection: screenshotProtection,
    );
  }
}

class SecretChatMediaViewPolicy {
  const SecretChatMediaViewPolicy({
    this.image,
    this.video,
    this.voice,
    this.file,
    this.location,
  });

  final int? image;
  final int? video;
  final int? voice;
  final int? file;
  final int? location;

  static SecretChatMediaViewPolicy? fromJson(Object? raw) {
    if (raw == null) return null;
    if (raw is! Map) return null;
    final m = raw.map((k, v) => MapEntry(k.toString(), v));
    int? asPosIntOrNull(Object? x) {
      if (x == null) return null;
      final v = x is int ? x : (x is num ? x.toInt() : null);
      if (v == null) return null;
      return v > 0 ? v : null;
    }

    return SecretChatMediaViewPolicy(
      image: asPosIntOrNull(m['image']),
      video: asPosIntOrNull(m['video']),
      voice: asPosIntOrNull(m['voice']),
      file: asPosIntOrNull(m['file']),
      location: asPosIntOrNull(m['location']),
    );
  }
}

