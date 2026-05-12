import 'package:flutter/material.dart';

/// Цвет таймера длительности митинга в шапке: при countdown'е <1 мин —
/// красный, <5 мин — амбер, иначе — нейтрально-белый. Для elapsed
/// (без `expiresAt`) — всегда нейтрально-белый.
enum MeetingTimerLevel { normal, warning, danger }

class MeetingTimerState {
  const MeetingTimerState({
    required this.formatted,
    required this.isCountdown,
    required this.level,
  });

  final String formatted;
  final bool isCountdown;
  final MeetingTimerLevel level;
}

/// Вычисляет состояние таймера для шапки митинга.
///
/// Чистая функция (получает `now` явно) — даёт детерминированные unit-тесты.
/// UI-обёртка ([_MeetingDurationBadge]) дёргает её каждую секунду из
/// [Timer.periodic].
///
/// Правила:
///   - Если `expiresAt != null`: countdown = `expiresAt - now`. Может быть
///     отрицательным (митинг истёк) — тогда форматируем `-mm:ss`.
///   - Иначе: elapsed = `now - createdAt`.
///   - Формат: `mm:ss` при <1 ч, иначе `h:mm:ss`.
///   - Уровень:
///     * `danger`  — countdown активен и осталось ≤ 60 с (но не истекло);
///     * `warning` — countdown активен и осталось < 5 мин;
///     * `normal`  — во всех остальных случаях.
MeetingTimerState computeMeetingTimer({
  required DateTime now,
  required DateTime createdAt,
  required DateTime? expiresAt,
}) {
  final nowUtc = now.toUtc();
  if (expiresAt != null) {
    final remaining = expiresAt.toUtc().difference(nowUtc);
    MeetingTimerLevel level;
    if (!remaining.isNegative && remaining.inSeconds <= 60) {
      level = MeetingTimerLevel.danger;
    } else if (!remaining.isNegative && remaining.inMinutes < 5) {
      level = MeetingTimerLevel.warning;
    } else {
      level = MeetingTimerLevel.normal;
    }
    return MeetingTimerState(
      formatted: _formatDuration(remaining),
      isCountdown: true,
      level: level,
    );
  }
  final elapsed = nowUtc.difference(createdAt.toUtc());
  return MeetingTimerState(
    formatted: _formatDuration(elapsed),
    isCountdown: false,
    level: MeetingTimerLevel.normal,
  );
}

String _formatDuration(Duration d) {
  final neg = d.isNegative;
  final v = d.abs();
  final h = v.inHours;
  final m = v.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = v.inSeconds.remainder(60).toString().padLeft(2, '0');
  final body = h > 0 ? '$h:$m:$s' : '$m:$s';
  return neg ? '-$body' : body;
}

/// Маппинг уровня → цвет текста таймера в шапке.
Color meetingTimerColorFor(MeetingTimerLevel level) {
  switch (level) {
    case MeetingTimerLevel.danger:
      return const Color(0xFFF87171);
    case MeetingTimerLevel.warning:
      return const Color(0xFFFBBF24);
    case MeetingTimerLevel.normal:
      return Colors.white.withValues(alpha: 0.65);
  }
}
