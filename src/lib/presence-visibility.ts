import { parseISO } from "date-fns";

import { formatLastSeenStatusRu } from "@/lib/last-seen-relative-ru";

type PresenceSubject = {
  online?: boolean | null;
  lastSeen?: string | null;
  privacySettings?: {
    showOnlineStatus?: boolean | null;
    showLastSeen?: boolean | null;
  } | null;
};

/** По умолчанию флаги считаются включёнными (обратная совместимость со старыми профилями). */
export function canShowOnlineStatus(subject: PresenceSubject | null | undefined): boolean {
  return subject?.privacySettings?.showOnlineStatus !== false;
}

/** По умолчанию флаг last seen считается включённым. */
export function canShowLastSeen(subject: PresenceSubject | null | undefined): boolean {
  return subject?.privacySettings?.showLastSeen !== false;
}

/** Унифицированная строка присутствия пользователя для шапок/профиля. */
export function resolvePresenceLabel(subject: PresenceSubject | null | undefined): string {
  if (!subject) return "Не в сети";
  if (subject.online && canShowOnlineStatus(subject)) return "В сети";
  const rawLastSeen = (subject.lastSeen ?? "").trim();
  if (!rawLastSeen || !canShowLastSeen(subject)) return "Не в сети";
  try {
    const lastSeenDate = parseISO(rawLastSeen);
    if (Number.isNaN(lastSeenDate.getTime())) return "Не в сети";
    return formatLastSeenStatusRu(lastSeenDate);
  } catch {
    return "Не в сети";
  }
}
