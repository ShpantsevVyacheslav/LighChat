/**
 * Политика push для сообщений: muteAll, тихие часы (IANA TZ), превью, mute чата.
 * Дублируется в `functions/src/lib/push-notification-policy.ts` — правки вносить в оба файла.
 */

export type MergedNotificationSettings = {
  soundEnabled: boolean;
  showPreview: boolean;
  muteAll: boolean;
  quietHoursEnabled: boolean;
  quietHoursStart: string;
  quietHoursEnd: string;
  quietHoursTimeZone: string;
};

export function mergeNotificationSettings(raw: unknown): MergedNotificationSettings {
  const defaults: MergedNotificationSettings = {
    soundEnabled: true,
    showPreview: true,
    muteAll: false,
    quietHoursEnabled: false,
    quietHoursStart: "23:00",
    quietHoursEnd: "07:00",
    quietHoursTimeZone: "UTC",
  };
  if (!raw || typeof raw !== "object") return defaults;
  const o = raw as Record<string, unknown>;
  const tz =
    typeof o.quietHoursTimeZone === "string" && o.quietHoursTimeZone.trim().length > 0 ?
      o.quietHoursTimeZone.trim() :
      defaults.quietHoursTimeZone;
  return {
    soundEnabled: o.soundEnabled !== false,
    showPreview: o.showPreview !== false,
    muteAll: o.muteAll === true,
    quietHoursEnabled: o.quietHoursEnabled === true,
    quietHoursStart: typeof o.quietHoursStart === "string" ? o.quietHoursStart : defaults.quietHoursStart,
    quietHoursEnd: typeof o.quietHoursEnd === "string" ? o.quietHoursEnd : defaults.quietHoursEnd,
    quietHoursTimeZone: tz,
  };
}

export function getClockMinutesInTimeZone(date: Date, timeZone: string): number {
  try {
    const dtf = new Intl.DateTimeFormat("en-GB", {
      timeZone,
      hour: "2-digit",
      minute: "2-digit",
      hour12: false,
    });
    const parts = dtf.formatToParts(date);
    const h = parseInt(parts.find((p) => p.type === "hour")?.value ?? "0", 10);
    const m = parseInt(parts.find((p) => p.type === "minute")?.value ?? "0", 10);
    let hour = h;
    if (hour === 24) hour = 0;
    return hour * 60 + m;
  } catch {
    return getClockMinutesInTimeZone(date, "UTC");
  }
}

function parseHmToMinutes(s: string): number | null {
  const m = /^(\d{1,2}):(\d{2})(?::\d{2})?$/.exec(s.trim());
  if (!m) return null;
  const hh = parseInt(m[1], 10);
  const mm = parseInt(m[2], 10);
  if (hh < 0 || hh > 23 || mm < 0 || mm > 59) return null;
  return hh * 60 + mm;
}

export function isQuietHours(ns: MergedNotificationSettings, now: Date): boolean {
  if (!ns.quietHoursEnabled || ns.muteAll) return false;
  const start = parseHmToMinutes(ns.quietHoursStart);
  const end = parseHmToMinutes(ns.quietHoursEnd);
  if (start === null || end === null || start === end) return false;
  const cur = getClockMinutesInTimeZone(now, ns.quietHoursTimeZone);
  if (start < end) {
    return cur >= start && cur < end;
  }
  return cur >= start || cur < end;
}

export function effectiveShowPreview(
  ns: MergedNotificationSettings,
  chatPrefs: Record<string, unknown> | undefined
): boolean {
  const v = chatPrefs?.notificationShowPreview;
  if (v === true || v === false) return v;
  return ns.showPreview;
}

export type ChatPushEval =
  | { deliver: false; reason: string }
  | { deliver: true; body: string; silent: boolean };

export function evaluateChatMessagePush(options: {
  userData: Record<string, unknown>;
  chatPrefs: Record<string, unknown> | undefined;
  plainBody: string;
  noPreviewBody: string;
  now?: Date;
}): ChatPushEval {
  const now = options.now ?? new Date();
  const ns = mergeNotificationSettings(options.userData.notificationSettings);
  if (ns.muteAll) return { deliver: false, reason: "muteAll" };
  if (isQuietHours(ns, now)) return { deliver: false, reason: "quietHours" };
  if (options.chatPrefs?.notificationsMuted === true) return { deliver: false, reason: "conversationMuted" };

  const show = effectiveShowPreview(ns, options.chatPrefs);
  const body = show ? options.plainBody : options.noPreviewBody;
  const silent = !ns.soundEnabled;
  return { deliver: true, body, silent };
}

export function evaluateSimpleNotificationPush(options: {
  userData: Record<string, unknown>;
  plainBody: string;
  noPreviewBody: string;
  now?: Date;
}): ChatPushEval {
  const now = options.now ?? new Date();
  const ns = mergeNotificationSettings(options.userData.notificationSettings);
  if (ns.muteAll) return { deliver: false, reason: "muteAll" };
  if (isQuietHours(ns, now)) return { deliver: false, reason: "quietHours" };

  const body = ns.showPreview ? options.plainBody : options.noPreviewBody;
  const silent = !ns.soundEnabled;
  return { deliver: true, body, silent };
}

export function parseConversationIdFromDashboardChatLink(link: string | undefined): string | null {
  if (!link) return null;
  try {
    const u = link.includes("://") ? new URL(link) : new URL(link, "https://dummy.local");
    return u.searchParams.get("conversationId");
  } catch {
    return null;
  }
}

/**
 * Foreground: текст уже отфильтрован на сервере — только решаем, показывать ли toast.
 */
export function shouldSuppressForegroundChatPush(options: {
  userData: Record<string, unknown>;
  chatPrefs: Record<string, unknown> | undefined;
  now?: Date;
}): boolean {
  const now = options.now ?? new Date();
  const ns = mergeNotificationSettings(options.userData.notificationSettings);
  if (ns.muteAll) return true;
  if (isQuietHours(ns, now)) return true;
  if (options.chatPrefs?.notificationsMuted === true) return true;
  return false;
}
