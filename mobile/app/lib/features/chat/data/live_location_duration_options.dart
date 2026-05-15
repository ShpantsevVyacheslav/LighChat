import '../../../l10n/app_localizations.dart';

/// Паритет `src/lib/live-location-durations.ts` (веб-диалог «Поделиться геолокацией»).
class LiveLocationDurationOption {
  const LiveLocationDurationOption({
    required this.id,
    required this.label,
    required this.durationMs,
  });

  final String id;
  final String label;
  /// null для `once` и `forever`
  final int? durationMs;
}

/// Constant IDs + durations (labels are placeholder — use [liveLocationDurationOptions] for display).
const List<LiveLocationDurationOption> kLiveLocationDurationOptions = [
  LiveLocationDurationOption(id: 'once', label: '', durationMs: null),
  LiveLocationDurationOption(id: 'm5', label: '', durationMs: 5 * 60 * 1000),
  LiveLocationDurationOption(id: 'm15', label: '', durationMs: 15 * 60 * 1000),
  LiveLocationDurationOption(id: 'm30', label: '', durationMs: 30 * 60 * 1000),
  LiveLocationDurationOption(id: 'h1', label: '', durationMs: 60 * 60 * 1000),
  LiveLocationDurationOption(id: 'h2', label: '', durationMs: 2 * 60 * 60 * 1000),
  LiveLocationDurationOption(id: 'h6', label: '', durationMs: 6 * 60 * 60 * 1000),
  LiveLocationDurationOption(id: 'd1', label: '', durationMs: 24 * 60 * 60 * 1000),
  LiveLocationDurationOption(id: 'forever', label: '', durationMs: null),
];

/// Returns duration options with localized labels. Включает
/// `until_end_of_day` — параллель Apple Messages «Until End of Day»,
/// durationMs не задан (вычисляется динамически в
/// [liveLocationExpiresAtForDurationId]).
List<LiveLocationDurationOption> liveLocationDurationOptions(AppLocalizations l10n) {
  return [
    LiveLocationDurationOption(id: 'once', label: l10n.live_location_once, durationMs: null),
    LiveLocationDurationOption(id: 'm5', label: l10n.live_location_5min, durationMs: 5 * 60 * 1000),
    LiveLocationDurationOption(id: 'm15', label: l10n.live_location_15min, durationMs: 15 * 60 * 1000),
    LiveLocationDurationOption(id: 'm30', label: l10n.live_location_30min, durationMs: 30 * 60 * 1000),
    LiveLocationDurationOption(id: 'h1', label: l10n.live_location_1hour, durationMs: 60 * 60 * 1000),
    LiveLocationDurationOption(id: 'h2', label: l10n.live_location_2hours, durationMs: 2 * 60 * 60 * 1000),
    LiveLocationDurationOption(id: 'h6', label: l10n.live_location_6hours, durationMs: 6 * 60 * 60 * 1000),
    LiveLocationDurationOption(id: 'd1', label: l10n.live_location_1day, durationMs: 24 * 60 * 60 * 1000),
    LiveLocationDurationOption(
      id: 'until_end_of_day',
      label: l10n.share_location_action_until_end_of_day,
      durationMs: null,
    ),
    LiveLocationDurationOption(id: 'forever', label: l10n.live_location_forever, durationMs: null),
  ];
}

/// ISO UTC окончания трансляции; `null` для `once` и `forever`.
String? liveLocationExpiresAtForDurationId(String id) {
  if (id == 'once' || id == 'forever') return null;
  if (id == 'until_end_of_day') {
    // 23:59:59 в локальном таймзоне юзера → переводим в UTC ISO.
    // Параллель с Apple Messages «Until End of Day».
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return endOfDay.toUtc().toIso8601String();
  }
  LiveLocationDurationOption? opt;
  for (final o in kLiveLocationDurationOptions) {
    if (o.id == id) {
      opt = o;
      break;
    }
  }
  final ms = opt?.durationMs;
  if (ms == null) return null;
  return DateTime.now().toUtc().add(Duration(milliseconds: ms)).toIso8601String();
}

bool liveLocationDurationActivatesUserShare(String id) => id != 'once';
