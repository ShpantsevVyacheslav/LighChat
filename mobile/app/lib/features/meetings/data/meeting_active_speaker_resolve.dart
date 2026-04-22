import 'meeting_models.dart';

/// Выбор uid «активного спикера» по сырым дельтам пакетов и флагам mute.
///
/// [minScore] — порог «тишины» (пакетов за тик сэмплера ~280 мс).
/// [stickiness] — если предыдущий лидер всё ещё ≥ stickiness × max, не переключаемся.
String? resolveActiveSpeaker({
  required Map<String, double> scores,
  required List<MeetingParticipant> participants,
  String? previous,
  double minScore = 2.0,
  double stickiness = 0.72,
}) {
  if (participants.isEmpty) return null;

  final byId = <String, MeetingParticipant>{
    for (final p in participants) p.id: p,
  };

  var bestId = '';
  var best = 0.0;
  for (final p in participants) {
    if (p.isAudioMuted) continue;
    final s = scores[p.id] ?? 0.0;
    if (s > best) {
      best = s;
      bestId = p.id;
    }
  }

  if (best < minScore) return null;

  final prev = previous;
  if (prev != null && prev.isNotEmpty) {
    final prevP = byId[prev];
    if (prevP != null && !prevP.isAudioMuted) {
      final prevScore = scores[prev] ?? 0.0;
      if (prevScore >= best * stickiness) {
        return prev;
      }
    }
  }

  return bestId.isEmpty ? null : bestId;
}
