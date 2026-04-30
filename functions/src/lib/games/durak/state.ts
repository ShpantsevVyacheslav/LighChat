import type { Card, Suit } from "./cards";
import type { DurakGameSettings } from "../gameSettings";

export type DurakStatus = "lobby" | "active" | "finished" | "cancelled";

export type DurakPhase =
  | "attack" // initial attack card(s) being placed
  | "defense" // defender is beating attacks
  | "throwIn" // attackers/others may throw-in while defense continues
  | "resolution" // round resolved: beat/take + draw + rotate
  | "finished";

export type DurakTable = {
  attacks: Card[];
  defenses: (Card | null)[];
};

export type DurakPrivateHandDoc = {
  uid: string;
  cards: Card[];
  legalMoves?: DurakLegalMoves;
  updatedAt: string;
};

export type DurakGameResult =
  | {
      kind: "finished";
      finishedAt: string;
      winners: string[]; // uids who got rid of all cards
      loserUid: string | null; // "durak" if exists
      placements?: { uids: string[] }[]; // order of exit; ties are grouped
    }
  | null;

export type DurakPublicView = {
  revision: number;
  phase: DurakPhase;
  trumpSuit: Suit;
  trumpCard?: Card | null;
  deckCount: number;
  discardCount: number;
  seats?: string[]; // uid order (clockwise)
  attackerUid: string;
  defenderUid: string;
  table: DurakTable;
  handCounts: Record<string, number>;
  lastMoveAt: string;
  throwerUids?: string[];
  passedUids?: string[];
  currentThrowerUid?: string | null;
  turnUid?: string | null;
  turnKind?: DurakTurnKind;
  turnStartedAt?: string | null;
  turnDeadlineAt?: string | null;
  turnTimeSec?: number | null;
  roundDefenderHandLimit?: number | null;
  canFinishTurn?: boolean;
  shuler?: {
    enabled: boolean;
    lastCheatUid: string | null;
    lastCheatAt?: string;
    foulEvent?: {
      at: string;
      byUid: string;
      cheaterUid: string;
      missedUids: string[];
      penaltyCards: number;
    };
    pendingResolution?: {
      kind: "discard";
      at: string;
      byUid: string;
    };
  };
  result?: DurakGameResult;
};

export type DurakTurnKind =
  | "attack"
  | "defend"
  | "throwIn"
  | "takeOrDefend"
  | "finishTurn"
  | "wait"
  | "finished";

export type DurakLegalMoves = {
  revision: number;
  canTake: boolean;
  canPass: boolean;
  canFinishTurn: boolean;
  attackCardKeys: string[];
  transferCardKeys: string[];
  defenseTargets: { attackIndex: number; cardKeys: string[] }[];
};

export type DurakServerState = {
  schemaVersion?: 1;
  revision: number;
  trumpSuit: Suit;
  deck: Card[]; // top is at end
  discard: Card[];
  attackerUid: string;
  defenderUid: string;
  table: DurakTable;
  seats: string[]; // uids in play order
  lastMoveAt: string;

  // Round tracking (server authoritative). Optional for backward compatibility.
  phase?: DurakPhase;
  // UIDs who are allowed to throw-in right now (excludes defender).
  throwerUids?: string[];
  // UIDs who already passed on throw-in for this round.
  passedUids?: string[];
  // Canonical throw-in limit: min(6, defender hand size at round start).
  // Reset at the beginning of each round and when defender changes via transfer.
  roundDefenderHandLimit?: number;
  // Canon: if defender has chosen to take, defense stops; throw-in may continue.
  taking?: boolean;
  // Canon: who may throw-in in 3–6 players. Set from lobby settings at game start.
  throwInPolicy?: "all" | "neighbors";
  // "Шулера" mode: server accepts otherwise-illegal moves (but still requires card-in-hand).
  shulerEnabled?: boolean;
  lastCheat?: {
    uid: string;
    actionType: "attack" | "defend" | "transfer";
    card: Card;
    attackIndex?: number;
    prevDefenderUid?: string;
    prevThrowerUids?: string[];
    prevPassedUids?: string[];
    prevRoundDefenderHandLimit?: number;
    at: string;
  } | null;
  foulEvent?: {
    at: string;
    byUid: string;
    cheaterUid: string;
    missedUids: string[];
    penaltyCards: number;
  } | null;

  // Shuler: when a cheated round is beaten ("Бито"), we pause resolution to allow foul.
  pendingResolution?: {
    kind: "discard";
    at: string;
    byUid: string; // attacker who pressed beat
  } | null;

  /**
   * Tournament placements tracking (server-side): groups of uids who "went out" together.
   * Only used when the deck is empty and the table is resolved.
   */
  finishGroups?: string[][];
};

export type GameDoc = {
  id: string;
  type: "durak";
  status: DurakStatus;
  createdAt: string;
  createdBy: string;
  conversationId: string;
  isGroup: boolean;
  playerIds: string[];
  settings: DurakGameSettings;
  tournamentId?: string;
  serverState?: DurakServerState;
  publicView?: DurakPublicView;
  result?: DurakGameResult;
  startedAt?: string;
  finishedAt?: string;
  lastUpdatedAt?: string;
};
