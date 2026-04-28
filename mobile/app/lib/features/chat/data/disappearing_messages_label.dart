import '../../../l10n/app_localizations.dart';

/// Localized summary for `disappearingMessageTtlSec` (seconds); parity with web `formatDisappearingTtlSummary`.
String formatDisappearingTtlSummaryForLocale(
  AppLocalizations l10n,
  int? ttlSec,
) {
  if (ttlSec == null || ttlSec <= 0) return l10n.disappearing_ttl_summary_off;
  switch (ttlSec) {
    case 3600:
      return l10n.disappearing_preset_1h;
    case 86400:
      return l10n.disappearing_preset_24h;
    case 604800:
      return l10n.disappearing_preset_7d;
    case 2592000:
      return l10n.disappearing_preset_30d;
    default:
      if (ttlSec < 3600) {
        return l10n.disappearing_ttl_minutes((ttlSec / 60).round());
      }
      if (ttlSec < 86400) {
        return l10n.disappearing_ttl_hours((ttlSec / 3600).round());
      }
      if (ttlSec < 604800) {
        return l10n.disappearing_ttl_days((ttlSec / 86400).round());
      }
      return l10n.disappearing_ttl_weeks((ttlSec / 604800).round());
  }
}
