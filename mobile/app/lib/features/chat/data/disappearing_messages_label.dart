/// Сводка для `disappearingMessageTtlSec` (секунды), паритет с web `formatDisappearingTtlSummary`.
String formatDisappearingTtlSummary(int? ttlSec) {
  if (ttlSec == null || ttlSec <= 0) return 'Выкл';
  switch (ttlSec) {
    case 3600:
      return '1 ч';
    case 86400:
      return '24 ч';
    case 604800:
      return '7 дн.';
    case 2592000:
      return '30 дн.';
    default:
      if (ttlSec < 3600) return '${(ttlSec / 60).round()} мин';
      if (ttlSec < 86400) return '${(ttlSec / 3600).round()} ч';
      if (ttlSec < 604800) return '${(ttlSec / 86400).round()} дн.';
      return '${(ttlSec / 604800).round()} нед.';
  }
}
