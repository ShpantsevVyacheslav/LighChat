export const SECRET_CHAT_TTL_PRESETS_SEC = [
  300, // 5m
  900, // 15m
  1800, // 30m
  3600, // 1h
  7200, // 2h
  21600, // 6h
  43200, // 12h
  86400, // 24h
] as const;

export type SecretChatTtlPresetSec = (typeof SECRET_CHAT_TTL_PRESETS_SEC)[number];

export function isSecretChatTtlPresetSec(v: number): v is SecretChatTtlPresetSec {
  return (SECRET_CHAT_TTL_PRESETS_SEC as readonly number[]).includes(v);
}

