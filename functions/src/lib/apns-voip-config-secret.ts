import type { ApnsVoipConfig } from "./apns-voip";

function emptyApnsVoipConfig(): ApnsVoipConfig {
  return {
    keyId: "",
    teamId: "",
    bundleId: "",
    privateKeyPem: "",
    useSandbox: false,
  };
}

function parseUseSandbox(raw: unknown): boolean {
  if (typeof raw === "boolean") return raw;
  const s = String(raw ?? "").trim().toLowerCase();
  return s === "1" || s === "true" || s === "yes";
}

/**
 * Один секрет `APNS_VOIP_CONFIG` (JSON), чтобы `firebase deploy` не требовал пять отдельных GSM-секретов.
 * Пустые поля → `isApnsVoipConfigured` = false, VoIP пропускается.
 */
export function apnsVoipConfigFromJsonSecret(raw: string): ApnsVoipConfig {
  const trimmed = raw.trim();
  if (!trimmed) return emptyApnsVoipConfig();
  try {
    const j = JSON.parse(trimmed) as Record<string, unknown>;
    return {
      keyId: String(j.keyId ?? "").trim(),
      teamId: String(j.teamId ?? "").trim(),
      bundleId: String(j.bundleId ?? "").trim(),
      privateKeyPem: String(j.privateKeyPem ?? "")
        .replace(/\\n/g, "\n")
        .trim(),
      useSandbox: parseUseSandbox(j.useSandbox),
    };
  } catch {
    return emptyApnsVoipConfig();
  }
}
