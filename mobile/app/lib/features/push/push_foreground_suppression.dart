// Паритет с `src/lib/push-notification-policy.ts` — `shouldSuppressForegroundChatPush`
// (muteAll, тихие часы IANA, mute чата).

import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

bool _tzInitialized = false;

void ensureTimezoneDataLoaded() {
  if (_tzInitialized) return;
  tzdata.initializeTimeZones();
  _tzInitialized = true;
}

class _MergedNs {
  const _MergedNs({
    required this.muteAll,
    required this.quietHoursEnabled,
    required this.quietHoursStart,
    required this.quietHoursEnd,
    required this.quietHoursTimeZone,
  });

  final bool muteAll;
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;
  final String quietHoursTimeZone;
}

_MergedNs _mergeNotificationSettings(Map<String, dynamic>? raw) {
  const defaults = _MergedNs(
    muteAll: false,
    quietHoursEnabled: false,
    quietHoursStart: '23:00',
    quietHoursEnd: '07:00',
    quietHoursTimeZone: 'UTC',
  );
  if (raw == null || raw.isEmpty) return defaults;
  final tzName = raw['quietHoursTimeZone'];
  final tzStr = tzName is String && tzName.trim().isNotEmpty
      ? tzName.trim()
      : defaults.quietHoursTimeZone;
  return _MergedNs(
    muteAll: raw['muteAll'] == true,
    quietHoursEnabled: raw['quietHoursEnabled'] == true,
    quietHoursStart: raw['quietHoursStart'] is String
        ? raw['quietHoursStart'] as String
        : defaults.quietHoursStart,
    quietHoursEnd: raw['quietHoursEnd'] is String
        ? raw['quietHoursEnd'] as String
        : defaults.quietHoursEnd,
    quietHoursTimeZone: tzStr,
  );
}

int? _parseHmToMinutes(String s) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$').firstMatch(s.trim());
  if (m == null) return null;
  final hh = int.tryParse(m.group(1)!);
  final mm = int.tryParse(m.group(2)!);
  if (hh == null || mm == null) return null;
  if (hh < 0 || hh > 23 || mm < 0 || mm > 59) return null;
  return hh * 60 + mm;
}

bool _isQuietHours(_MergedNs ns, DateTime nowUtc) {
  if (!ns.quietHoursEnabled || ns.muteAll) return false;
  final start = _parseHmToMinutes(ns.quietHoursStart);
  final end = _parseHmToMinutes(ns.quietHoursEnd);
  if (start == null || end == null || start == end) return false;
  ensureTimezoneDataLoaded();
  late final tz.Location loc;
  try {
    loc = tz.getLocation(ns.quietHoursTimeZone);
  } catch (_) {
    loc = tz.getLocation('UTC');
  }
  final zoned = tz.TZDateTime.from(nowUtc, loc);
  final cur = zoned.hour * 60 + zoned.minute;
  if (start < end) {
    return cur >= start && cur < end;
  }
  return cur >= start || cur < end;
}

/// Не показывать in-app / локальный toast при тех же условиях, что и web foreground.
bool shouldSuppressForegroundChatPush({
  required Map<String, dynamic> userData,
  Map<String, dynamic>? chatPrefs,
  DateTime? now,
}) {
  final nowUtc = (now ?? DateTime.now()).toUtc();
  final raw = userData['notificationSettings'];
  final map = raw is Map
      ? raw.map((k, v) => MapEntry(k.toString(), v))
      : const <String, dynamic>{};
  final ns = _mergeNotificationSettings(map);
  if (ns.muteAll) return true;
  if (_isQuietHours(ns, nowUtc)) return true;
  if (chatPrefs != null && chatPrefs['notificationsMuted'] == true) {
    return true;
  }
  return false;
}
