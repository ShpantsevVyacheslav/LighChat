import type { SecretChatTtlPresetSec } from "@/lib/types";

export const SECRET_CHAT_TTL_PRESETS_SEC: ReadonlyArray<SecretChatTtlPresetSec> = [
  300,
  900,
  1800,
  3600,
  7200,
  21600,
  43200,
  86400,
] as const;

export function isSecretChatTtlPresetSec(v: number): v is SecretChatTtlPresetSec {
  return (SECRET_CHAT_TTL_PRESETS_SEC as readonly number[]).includes(v);
}

