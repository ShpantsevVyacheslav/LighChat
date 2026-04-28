import type { Card, Suit } from "./cards";
import type { DurakGameSettings } from "../gameSettings";

export type DurakStatus = "lobby" | "active" | "finished" | "cancelled";

export type DurakTable = {
  attacks: Card[];
  defenses: (Card | null)[];
};

export type DurakPrivateHandDoc = {
  uid: string;
  cards: Card[];
  updatedAt: string;
};

export type DurakPublicView = {
  revision: number;
  phase: "defense"; // keep minimal for now
  trumpSuit: Suit;
  deckCount: number;
  discardCount: number;
  attackerUid: string;
  defenderUid: string;
  table: DurakTable;
  handCounts: Record<string, number>;
  lastMoveAt: string;
};

export type DurakServerState = {
  revision: number;
  trumpSuit: Suit;
  deck: Card[]; // top is at end
  discard: Card[];
  attackerUid: string;
  defenderUid: string;
  table: DurakTable;
  seats: string[]; // uids in play order
  lastMoveAt: string;
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
  serverState?: DurakServerState;
  publicView?: DurakPublicView;
  startedAt?: string;
  lastUpdatedAt?: string;
};

