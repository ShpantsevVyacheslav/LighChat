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

const List<LiveLocationDurationOption> kLiveLocationDurationOptions = [
  LiveLocationDurationOption(
    id: 'once',
    label: 'Одноразово (только это сообщение)',
    durationMs: null,
  ),
  LiveLocationDurationOption(id: 'm5', label: '5 минут', durationMs: 5 * 60 * 1000),
  LiveLocationDurationOption(id: 'm15', label: '15 минут', durationMs: 15 * 60 * 1000),
  LiveLocationDurationOption(id: 'm30', label: '30 минут', durationMs: 30 * 60 * 1000),
  LiveLocationDurationOption(id: 'h1', label: '1 час', durationMs: 60 * 60 * 1000),
  LiveLocationDurationOption(id: 'h2', label: '2 часа', durationMs: 2 * 60 * 60 * 1000),
  LiveLocationDurationOption(id: 'h6', label: '6 часов', durationMs: 6 * 60 * 60 * 1000),
  LiveLocationDurationOption(id: 'd1', label: '1 день', durationMs: 24 * 60 * 60 * 1000),
  LiveLocationDurationOption(
    id: 'forever',
    label: 'Навсегда (пока не отключу)',
    durationMs: null,
  ),
];

/// ISO UTC окончания трансляции; `null` для `once` и `forever`.
String? liveLocationExpiresAtForDurationId(String id) {
  if (id == 'once' || id == 'forever') return null;
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
