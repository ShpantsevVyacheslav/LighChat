export type DurakGameMode = "podkidnoy" | "perevodnoy";

export type DurakThrowInPolicy = "all" | "neighbors";

export type DurakGameSettings = {
  mode: DurakGameMode;
  maxPlayers: number; // 2..6
  deckSize: 36 | 52;
  withJokers: boolean;
  turnTimeSec: number | null; // null = no limit
  throwInPolicy: DurakThrowInPolicy;
  shulerEnabled: boolean;
};

export function normalizeDurakSettings(raw: unknown): DurakGameSettings {
  const obj = raw && typeof raw === "object" ? (raw as Record<string, unknown>) : {};

  const modeRaw = typeof obj.mode === "string" ? obj.mode.trim().toLowerCase() : "";
  const mode: DurakGameMode = modeRaw === "perevodnoy" ? "perevodnoy" : "podkidnoy";

  const mpRaw = typeof obj.maxPlayers === "number" ? obj.maxPlayers : null;
  const maxPlayers = mpRaw == null ? 6 : Math.max(2, Math.min(6, Math.floor(mpRaw)));

  const dsRaw = typeof obj.deckSize === "number" ? Math.floor(obj.deckSize) : null;
  const deckSize: 36 | 52 = dsRaw === 52 ? 52 : 36;

  const withJokers = obj.withJokers === true;

  const tRaw = typeof obj.turnTimeSec === "number" ? obj.turnTimeSec : null;
  const turnTimeSec =
    tRaw == null ? null : Math.max(10, Math.min(600, Math.floor(tRaw)));

  const tipRaw = typeof obj.throwInPolicy === "string" ? obj.throwInPolicy.trim().toLowerCase() : "";
  const throwInPolicy: DurakThrowInPolicy = tipRaw === "neighbors" ? "neighbors" : "all";

  const shulerEnabled = obj.shulerEnabled === true;

  return { mode, maxPlayers, deckSize, withJokers, turnTimeSec, throwInPolicy, shulerEnabled };
}

