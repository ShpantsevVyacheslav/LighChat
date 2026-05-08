'use client';

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { doc } from 'firebase/firestore';
import { Flag, LogOut, Play, Shield, Swords, X } from 'lucide-react';
import { getFunctions, httpsCallable } from 'firebase/functions';

import { useFirestore, useDoc, useMemoFirebase } from '@/firebase';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { useToast } from '@/hooks/use-toast';
import { useI18n } from '@/hooks/use-i18n';
import type { DurakCard, DurakGameSession, DurakLegalMoves, User } from '@/lib/types';
import { cn } from '@/lib/utils';

import { cardLabel, isJoker } from './durak-cards';

type HandDoc = {
  uid: string;
  cards: DurakCard[];
  legalMoves?: DurakLegalMoves;
};

type DragState = {
  card: DurakCard;
  index: number;
  startX: number;
  startY: number;
  x: number;
  y: number;
};

type PendingMove = {
  clientMoveId: string;
  actionType: 'attack' | 'transfer' | 'defend';
  card: DurakCard;
  attackIndex?: number;
  baseRevision: number;
};

const suitSymbol: Record<string, string> = {
  S: '♠',
  H: '♥',
  D: '♦',
  C: '♣',
};

const suitOrder: Record<string, number> = { S: 0, C: 1, D: 2, H: 3 };

function rankValue(c: DurakCard): number {
  if (isJoker(c)) return 100;
  return Number(c.r) || 0;
}

function beats({ attack, defense, trumpSuit }: { attack: DurakCard; defense: DurakCard; trumpSuit: string }) {
  if (isJoker(defense)) return true;
  if (isJoker(attack)) return false;
  if (!attack.s || !defense.s) return false;
  if (defense.s === attack.s) return rankValue(defense) > rankValue(attack);
  return defense.s === trumpSuit && attack.s !== trumpSuit;
}

function rankKey(c: DurakCard): string {
  return isJoker(c) ? 'JOKER' : String(c.r);
}

function cardKey(c: DurakCard): string {
  return isJoker(c) ? 'JOKER' : `${c.s}:${c.r}`;
}

function isRed(c: DurakCard) {
  return c.s === 'H' || c.s === 'D';
}

function displayName(uid: string, allUsers: User[]) {
  return allUsers.find((u) => u.id === uid)?.name ?? (uid.length > 8 ? `${uid.slice(0, 8)}…` : uid);
}

function avatarUrl(uid: string, allUsers: User[]) {
  const u = allUsers.find((x) => x.id === uid);
  return u?.avatarThumb || u?.avatar || '';
}

export function DurakWebGameDialog({
  open,
  onOpenChange,
  gameId,
  currentUser,
  allUsers,
  standalone = false,
}: {
  open: boolean;
  onOpenChange: (v: boolean) => void;
  gameId: string;
  currentUser: User;
  allUsers: User[];
  standalone?: boolean;
}) {
  const firestore = useFirestore();
  const { toast } = useToast();
  const { t } = useI18n();
  const [busy, setBusy] = useState<string | null>(null);
  const [selectedCardIdx, setSelectedCardIdx] = useState<number | null>(null);
  const [selectedAttackIndex, setSelectedAttackIndex] = useState(0);
  const [drag, setDrag] = useState<DragState | null>(null);
  const [nowMs, setNowMs] = useState(() => Date.now());
  const [pendingMove, setPendingMove] = useState<PendingMove | null>(null);
  const [emojiBurst, setEmojiBurst] = useState(false);
  const lastCheatPassedRef = useRef('');
  const dragRef = useRef<DragState | null>(null);
  const moveInFlightRef = useRef(false);

  const gameRef = useMemoFirebase(
    () => (firestore && gameId ? doc(firestore, 'games', gameId) : null),
    [firestore, gameId]
  );
  const { data: game, error: gameError, isLoading: gameLoading } = useDoc<DurakGameSession>(gameRef);

  const tournamentId = (game as any)?.tournamentId as string | undefined;
  const tournamentRef = useMemoFirebase(
    () => (firestore && tournamentId ? doc(firestore, 'tournaments', tournamentId) : null),
    [firestore, tournamentId]
  );
  const { data: tournament } = useDoc<{
    status?: string;
    totalGames?: number;
    finishedGameIds?: string[];
    gameIds?: string[];
  }>(tournamentRef);

  const gamePlayerIds = game?.playerIds ?? [];
  const inGame = gamePlayerIds.includes(currentUser.id);

  const handRef = useMemoFirebase(
    () =>
      firestore && gameId && inGame
        ? doc(firestore, `games/${gameId}/privateHands/${currentUser.id}`)
        : null,
    [firestore, gameId, currentUser.id, inGame]
  );
  const { data: hand } = useDoc<HandDoc>(handRef);

  const call = useCallback(
    async (name: string, data: Record<string, unknown>) => {
      if (!firestore) return false;
      if (name === 'makeDurakMove' && moveInFlightRef.current) return false;
      if (name === 'makeDurakMove') moveInFlightRef.current = true;
      setBusy(name);
      try {
        const fn = httpsCallable(getFunctions(firestore.app, 'us-central1'), name);
        await fn(data);
        return true;
      } catch (e) {
        const msg = e instanceof Error ? e.message : t('durak.error');
        toast({ variant: 'destructive', title: t('durak.error'), description: msg });
        return false;
      } finally {
        if (name === 'makeDurakMove') moveInFlightRef.current = false;
        setBusy(null);
      }
    },
    [firestore, toast]
  );

  const joinLobby = useCallback(() => call('joinGameLobby', { gameId }), [call, gameId]);
  const startGame = useCallback(() => call('startDurakGame', { gameId }), [call, gameId]);
  const cancelLobby = useCallback(() => call('cancelGameLobby', { gameId }), [call, gameId]);
  const openInPopup = useCallback(
    (nextGameId: string) => {
      onOpenChange(false);
      window.open(
        `/games/durak/${encodeURIComponent(nextGameId)}`,
        `durak_${nextGameId}`,
        'popup=yes,width=980,height=760,resizable=yes,scrollbars=no'
      );
    },
    [onOpenChange]
  );
  const nextTournamentGame = useCallback(async () => {
    if (!firestore) return;
    const tournamentId = (game as any)?.tournamentId as string | undefined;
    if (!tournamentId) return;
    setBusy('createTournamentGameLobby');
    try {
      const fn = httpsCallable(getFunctions(firestore.app, 'us-central1'), 'createTournamentGameLobby');
      const res = await fn({ tournamentId, settings: (game as any)?.settings ?? undefined });
      const nextGameId = (res.data as any)?.gameId as string | undefined;
      if (nextGameId) openInPopup(nextGameId);
    } catch (e) {
      const msg = e instanceof Error ? e.message : t('durak.error');
      toast({ variant: 'destructive', title: t('durak.error'), description: msg });
    } finally {
      setBusy(null);
    }
  }, [firestore, game, openInPopup, t, toast]);
  const rematch = useCallback(async () => {
    if (!firestore) return;
    setBusy('createDurakRematch');
    try {
      const fn = httpsCallable(getFunctions(firestore.app, 'us-central1'), 'createDurakRematch');
      const res = await fn({ gameId });
      const nextGameId = (res.data as any)?.gameId as string | undefined;
      if (nextGameId) {
        if (nextGameId === gameId) return;
        openInPopup(nextGameId);
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : t('durak.error');
      toast({ variant: 'destructive', title: t('durak.error'), description: msg });
    } finally {
      setBusy(null);
    }
  }, [firestore, gameId, onOpenChange, t, toast]);
  const publicView = game?.publicView ?? null;
  const status = game?.status ?? '';
  const isOwner = game?.createdBy === currentUser.id;
  const attacks = publicView?.table?.attacks ?? [];
  const defenses = publicView?.table?.defenses ?? [];
  const publicRevision = Number(publicView?.revision ?? -1);

  const makeMove = useCallback(
    async (
      actionType: string,
      payload?: Record<string, unknown>,
      optimistic?: Omit<PendingMove, 'clientMoveId' | 'baseRevision' | 'actionType'> & {
        actionType: PendingMove['actionType'];
      }
    ) => {
      const clientMoveId = `${Date.now()}_${Math.random().toString(16).slice(2)}`;
      if (optimistic) {
        setPendingMove({
          clientMoveId,
          actionType: optimistic.actionType,
          card: optimistic.card,
          attackIndex: optimistic.attackIndex,
          baseRevision: publicRevision,
        });
        setSelectedCardIdx(null);
      }
      const ok = await call('makeDurakMove', {
        gameId,
        clientMoveId,
        actionType,
        payload: payload ?? null,
      });
      if (!ok && optimistic) setPendingMove(null);
    },
    [call, gameId, publicRevision]
  );

  useEffect(() => {
    if (pendingMove && publicRevision > pendingMove.baseRevision) {
      setPendingMove(null);
    }
  }, [pendingMove, publicRevision]);
  const trumpSuit = String(publicView?.trumpSuit ?? '');
  const myCards = hand?.cards ?? [];
  const sortedMyCards = useMemo(() => {
    const sorted = [...myCards];
    sorted.sort((a, b) => {
      const aj = isJoker(a);
      const bj = isJoker(b);
      if (aj !== bj) return aj ? 1 : -1;
      const at = a.s === trumpSuit;
      const bt = b.s === trumpSuit;
      if (at !== bt) return at ? 1 : -1;
      const sa = a.s != null ? (suitOrder[a.s] ?? 9) : 9;
      const sb = b.s != null ? (suitOrder[b.s] ?? 9) : 9;
      if (sa !== sb) return sa - sb;
      return rankValue(a) - rankValue(b);
    });
    return sorted;
  }, [myCards, trumpSuit]);
  const visibleMyCards = useMemo(() => {
    if (!pendingMove) return sortedMyCards;
    let removed = false;
    return sortedMyCards.filter((card) => {
      if (!removed && cardKey(card) === cardKey(pendingMove.card)) {
        removed = true;
        return false;
      }
      return true;
    });
  }, [sortedMyCards, pendingMove]);
  const optimisticTable = useMemo(() => {
    if (!pendingMove) return { attacks, defenses };
    const nextAttacks = [...attacks];
    const nextDefenses = [...defenses];
    if (pendingMove.actionType === 'attack' || pendingMove.actionType === 'transfer') {
      nextAttacks.push(pendingMove.card);
      nextDefenses.push(null);
    }
    if (pendingMove.actionType === 'defend' && pendingMove.attackIndex != null) {
      const idx = pendingMove.attackIndex;
      if (idx >= 0 && idx < nextAttacks.length) {
        while (nextDefenses.length <= idx) nextDefenses.push(null);
        nextDefenses[idx] = pendingMove.card;
      }
    }
    return { attacks: nextAttacks, defenses: nextDefenses };
  }, [attacks, defenses, pendingMove]);
  const legalMoves = hand?.legalMoves ?? null;
  const legalAttackKeys = useMemo(() => new Set(legalMoves?.attackCardKeys ?? []), [legalMoves]);
  const legalTransferKeys = useMemo(() => new Set(legalMoves?.transferCardKeys ?? []), [legalMoves]);
  const legalDefenseTargets = useMemo(() => {
    const map = new Map<number, Set<string>>();
    for (const target of legalMoves?.defenseTargets ?? []) {
      map.set(target.attackIndex, new Set(target.cardKeys));
    }
    return map;
  }, [legalMoves]);
  const selectedCard = selectedCardIdx == null ? null : visibleMyCards[selectedCardIdx] ?? null;
  const seats = publicView?.seats?.length ? publicView.seats : gamePlayerIds;
  const attackerUid = publicView?.attackerUid ?? '';
  const defenderUid = publicView?.defenderUid ?? '';
  const passedUids = new Set(publicView?.passedUids ?? []);
  const handCounts = publicView?.handCounts ?? {};
  const currentThrowerUid =
    publicView && Object.prototype.hasOwnProperty.call(publicView, 'currentThrowerUid')
      ? publicView.currentThrowerUid ?? null
      : fallbackCurrentThrower();
  const tableRanks = new Set([...attacks, ...defenses.filter(Boolean)].map((c) => rankKey(c as DurakCard)));
  const serverTurnKind = publicView?.turnKind ?? '';
  const hasUndefendedAttacks = attacks.some((_, idx) => !defenses[idx]);
  const shuler = publicView?.shuler;
  const shulerEnabled = shuler?.enabled === true;

  function fallbackCurrentThrower(): string | null {
    if (attacks.length === 0) return null;
    const throwers = publicView?.throwerUids ?? seats.filter((u) => u !== defenderUid);
    const attackerIdx = seats.indexOf(attackerUid);
    const ordered = attackerIdx < 0 ? seats : [...seats.slice(attackerIdx), ...seats.slice(0, attackerIdx)];
    return ordered.find((u) => throwers.includes(u) && !passedUids.has(u) && (handCounts[u] ?? 0) > 0) ?? null;
  }

  const defenseSlotOpen = (idx: number) => idx >= 0 && idx < attacks.length && !defenses[idx];
  const renderDefenseSlotOpen = (idx: number) =>
    idx >= 0 && idx < optimisticTable.attacks.length && !optimisticTable.defenses[idx];

  const canAttackCard = useCallback(
    (card: DurakCard) => {
      if (pendingMove) return false;
      if (legalMoves) return legalAttackKeys.has(cardKey(card));
      if (status !== 'active') return false;
      if (currentUser.id === defenderUid) return false;
      if (attacks.length === 0) {
        // First attack: prefer attackerUid, but keep compatibility with
        // older/transition public views where currentThrowerUid is authoritative.
        return currentUser.id === attackerUid || currentUser.id === currentThrowerUid;
      }
      const defenderCount = handCounts[defenderUid] ?? 0;
      const roundLimit = publicView?.roundDefenderHandLimit ?? (defenderCount > 0 ? defenderCount : 6);
      const canThrow = attacks.length < 6 && attacks.length < roundLimit;
      return (
        canThrow &&
        currentUser.id !== defenderUid &&
        currentUser.id === currentThrowerUid &&
        (isJoker(card) || tableRanks.has(rankKey(card)))
      );
    },
    [attackerUid, attacks.length, currentThrowerUid, currentUser.id, defenderUid, handCounts, legalAttackKeys, legalMoves, pendingMove, publicView, status, tableRanks]
  );

  const canDefendCardAt = useCallback(
    (card: DurakCard, idx: number) => {
      if (pendingMove) return false;
      if (legalMoves) return legalDefenseTargets.get(idx)?.has(cardKey(card)) ?? false;
      if (status !== 'active' || currentUser.id !== defenderUid || !trumpSuit || !defenseSlotOpen(idx)) return false;
      const attack = attacks[idx];
      return Boolean(attack && beats({ attack, defense: card, trumpSuit }));
    },
    [attacks, currentUser.id, defenderUid, legalDefenseTargets, legalMoves, pendingMove, status, trumpSuit]
  );

  const canTransferCard = useCallback(
    (card: DurakCard) => {
      if (pendingMove) return false;
      if (legalMoves) return legalTransferKeys.has(cardKey(card));
      if (status !== 'active' || currentUser.id !== defenderUid || game?.publicView == null) return false;
      const mode = (game as any)?.settings?.mode ?? 'podkidnoy';
      if (mode !== 'perevodnoy' || attacks.length === 0 || defenses.some(Boolean)) return false;
      const defenderCount = handCounts[defenderUid] ?? 0;
      const roundLimit = publicView?.roundDefenderHandLimit ?? (defenderCount > 0 ? defenderCount : 6);
      if (attacks.length >= 6 || attacks.length >= roundLimit) return false;
      return isJoker(card) || tableRanks.has(rankKey(card));
    },
    [attacks.length, currentUser.id, defenderUid, defenses, game, handCounts, legalMoves, legalTransferKeys, pendingMove, publicView, status, tableRanks]
  );

  const firstDefenseIndexForCard = useCallback(
    (card: DurakCard): number | null => {
      for (const [idx, keys] of legalDefenseTargets.entries()) {
        if (keys.has(cardKey(card))) return idx;
      }
      for (let i = 0; i < attacks.length; i++) {
        if (canDefendCardAt(card, i)) return i;
      }
      return null;
    },
    [attacks.length, canDefendCardAt, legalDefenseTargets]
  );

  const handleCardTap = useCallback(
    (card: DurakCard, idx: number) => {
      const defenseIndex = firstDefenseIndexForCard(card);
      const actions = [
        canAttackCard(card) ? 'attack' : '',
        canTransferCard(card) ? 'transfer' : '',
        defenseIndex != null ? 'defend' : '',
      ].filter(Boolean);
      if (actions.length === 1) {
        const action = actions[0];
        if (action === 'attack') void makeMove('attack', { card }, { actionType: 'attack', card });
        if (action === 'transfer') void makeMove('transfer', { card }, { actionType: 'transfer', card });
        if (action === 'defend' && defenseIndex != null) {
          void makeMove(
            'defend',
            { attackIndex: defenseIndex, card },
            { actionType: 'defend', card, attackIndex: defenseIndex }
          );
        }
        return;
      }
      setSelectedCardIdx((old) => (old === idx ? null : idx));
    },
    [canAttackCard, canTransferCard, firstDefenseIndexForCard, makeMove]
  );

  const playDrop = useCallback(
    async (dropEl: Element | null, d: DragState) => {
      const target = dropEl?.closest<HTMLElement>('[data-durak-drop]');
      if (!target) {
        toast({ title: t('durak.cardReturned'), description: t('durak.cardReturnedDesc') });
        return;
      }
      const kind = target.dataset.durakDrop;
      if (kind === 'attack' && canAttackCard(d.card)) {
        await makeMove('attack', { card: d.card }, { actionType: 'attack', card: d.card });
        return;
      }
      if (kind === 'transfer' && canTransferCard(d.card)) {
        await makeMove('transfer', { card: d.card }, { actionType: 'transfer', card: d.card });
        return;
      }
      if (kind === 'defense') {
        const idx = Number(target.dataset.attackIndex ?? -1);
        if (Number.isFinite(idx) && canDefendCardAt(d.card, idx)) {
          await makeMove(
            'defend',
            { attackIndex: idx, card: d.card },
            { actionType: 'defend', card: d.card, attackIndex: idx }
          );
          return;
        }
      }
      toast({ variant: 'destructive', title: t('durak.moveUnavailable'), description: t('durak.moveUnavailableDesc') });
    },
    [canAttackCard, canDefendCardAt, canTransferCard, makeMove, toast]
  );

  useEffect(() => {
    const id = window.setInterval(() => setNowMs(Date.now()), 500);
    return () => window.clearInterval(id);
  }, []);

  const cheatPassedUid = shuler?.cheatPassedUid ?? '';
  useEffect(() => {
    if (cheatPassedUid && cheatPassedUid !== lastCheatPassedRef.current) {
      lastCheatPassedRef.current = cheatPassedUid;
      setEmojiBurst(true);
      const t = window.setTimeout(() => setEmojiBurst(false), 3000);
      return () => window.clearTimeout(t);
    }
  }, [cheatPassedUid]);

  useEffect(() => {
    dragRef.current = drag;
  }, [drag]);

  useEffect(() => {
    if (!drag) return;
    let handled = false;
    const move = (e: PointerEvent) => {
      setDrag((prev) => (prev ? { ...prev, x: e.clientX, y: e.clientY } : prev));
    };
    const up = (e: PointerEvent) => {
      if (handled) return;
      handled = true;
      const current = dragRef.current;
      dragRef.current = null;
      setDrag(null);
      if (!current) return;
      const moved = Math.hypot(e.clientX - current.startX, e.clientY - current.startY);
      if (moved < 8) {
        handleCardTap(current.card, current.index);
        return;
      }
      const el = document.elementFromPoint(e.clientX, e.clientY);
      void playDrop(el, current);
    };
    window.addEventListener('pointermove', move);
    window.addEventListener('pointerup', up, { once: true });
    window.addEventListener('pointercancel', up, { once: true });
    return () => {
      window.removeEventListener('pointermove', move);
      window.removeEventListener('pointerup', up);
      window.removeEventListener('pointercancel', up);
    };
  }, [drag, handleCardTap, playDrop]);

  const myTurnLabel = useMemo(() => {
    if (status !== 'active') return '';
    if (publicView?.turnUid === currentUser.id && serverTurnKind !== 'wait') return t('durak.yourTurn');
    if (attacks.length === 0 && currentUser.id === attackerUid && currentUser.id !== defenderUid) return t('durak.yourTurn');
    if (currentUser.id === defenderUid && attacks.length > 0) return t('durak.yourTurn');
    if (currentUser.id === currentThrowerUid) return t('durak.yourTurn');
    return '';
  }, [attackerUid, attacks.length, currentThrowerUid, currentUser.id, defenderUid, publicView?.turnUid, serverTurnKind, status, t]);

  const primaryLabel = useMemo(() => {
    if (status !== 'active') return '';
    const isTaking = publicView?.phase === 'throwIn';
    if (legalMoves?.canTake && hasUndefendedAttacks && !isTaking) return t('durak.take');
    if (legalMoves?.canPass) return t('durak.pass');
    if (serverTurnKind === 'attack' && publicView?.turnUid === currentUser.id) return t('durak.yourTurn');
    if (currentUser.id === defenderUid) return (hasUndefendedAttacks && !isTaking) ? t('durak.take') : '';
    if (attacks.length === 0 && currentUser.id === attackerUid && currentUser.id !== defenderUid) return t('durak.yourTurn');
    if (currentUser.id === currentThrowerUid) return t('durak.pass');
    return '';
  }, [attackerUid, attacks.length, currentThrowerUid, currentUser.id, defenderUid, hasUndefendedAttacks, legalMoves, publicView?.phase, publicView?.turnUid, serverTurnKind, status, t]);

  const enabledCard = (card: DurakCard) =>
    canAttackCard(card) || canTransferCard(card) || firstDefenseIndexForCard(card) != null;

  const gameBody = () => {
    if (gameLoading) return <div className="text-sm text-white/70">{t('durak.loading')}</div>;
    if (gameError) {
      return (
        <div className="max-w-md rounded-2xl bg-white/10 p-5 text-sm text-white/75">
          {t('durak.noAccessDesc')}
        </div>
      );
    }
    if (!game) return <div className="text-sm text-white/70">{t('durak.gameNotFound')}</div>;

    if (status === 'finished' || publicView?.phase === 'finished' || publicView?.result) {
      const winners = publicView?.result?.winners ?? game.result?.winners ?? [];
      const loserUid = publicView?.result?.loserUid ?? game.result?.loserUid ?? null;
      return (
        <div className="mx-auto flex w-full max-w-xl flex-col items-center gap-4 rounded-[28px] border border-white/12 bg-white/10 p-6 text-center text-white shadow-2xl backdrop-blur-xl">
          <div className="flex -space-x-3">
            {winners.slice(0, 4).map((uid) => {
              const avatar = avatarUrl(uid, allUsers);
              return (
                <div key={uid} className="h-16 w-16 overflow-hidden rounded-full border-4 border-lime-300 bg-white/20">
                  {avatar ? <img src={avatar} alt="" className="h-full w-full object-cover" /> : null}
                </div>
              );
            })}
          </div>
          <Badge className="bg-lime-300 text-lime-950">{t('durak.winner')}</Badge>
          <div className="text-xl font-black">
            {winners.map((uid) => displayName(uid, allUsers)).join(', ') || t('durak.noWinners')}
          </div>
          {loserUid ? <div className="text-sm text-white/70">{t('durak.loser')} {displayName(loserUid, allUsers)}</div> : null}
          {tournamentId ? (
            (() => {
              const totalGames = tournament?.totalGames ?? 0;
              const finishedCount = tournament?.finishedGameIds?.length ?? 0;
              const createdCount = tournament?.gameIds?.length ?? 0;
              const limitReached =
                tournament?.status === 'finished' ||
                (totalGames > 0 && createdCount >= totalGames);
              return (
                <div className="mt-2 flex flex-col items-center gap-2">
                  {totalGames > 0 ? (
                    <div className="text-xs text-white/60">
                      {t('durak.playedNofM', { n: finishedCount, m: totalGames })}
                    </div>
                  ) : null}
                  {limitReached ? (
                    <div className="text-sm text-white/70">{t('durak.tournamentFinished')}</div>
                  ) : (
                    <Button
                      onClick={() => void nextTournamentGame()}
                      disabled={busy != null}
                    >
                      {t('durak.nextRound')}
                    </Button>
                  )}
                </div>
              );
            })()
          ) : (
            <Button onClick={() => void rematch()} disabled={busy != null} className="mt-2">
              {t('durak.playAgain')}
            </Button>
          )}
          <button
            type="button"
            className="mt-1 text-sm font-semibold text-white/60 transition hover:text-white/90"
            onClick={() => {
              if (standalone) window.close();
              else onOpenChange(false);
            }}
          >
            {t('durak.backToChat')}
          </button>
        </div>
      );
    }

    if (status !== 'active') {
      const readyUids = Array.isArray((game as any).readyUids) ? ((game as any).readyUids as string[]) : [];
      const iAmReady = readyUids.includes(currentUser.id);
      const maxPlayers = Number((game as any)?.settings?.maxPlayers ?? 2) || 2;
      const allReady =
        gamePlayerIds.length > 0 && readyUids.length >= gamePlayerIds.length;
      const canStart =
        inGame && status === 'lobby' && gamePlayerIds.length >= 2 && allReady;
      const canJoin =
        !inGame && status === 'lobby' && gamePlayerIds.length < maxPlayers;
      const slots: (string | null)[] = [];
      for (let i = 0; i < maxPlayers; i++) {
        slots.push(gamePlayerIds[i] ?? null);
      }
      return (
        <div className="relative h-full min-h-0 overflow-hidden rounded-[30px] border border-white/10 text-white shadow-[inset_0_0_80px_rgba(0,0,0,0.32)]">
          <div className="absolute inset-0 [background:radial-gradient(circle_at_30%_25%,#5f86a1_0%,#253f52_55%,#0e1620_100%)]" />
          <div className="relative z-10 flex h-full flex-col">
            <div className="flex items-center justify-between px-4 py-4">
              <div className="w-12" />
              <div className="text-base font-extrabold tracking-wide text-white">
                {t('durak.lobby')}
              </div>
              {isOwner ? (
                <Button
                  size="icon"
                  variant="ghost"
                  className="h-10 w-10 rounded-xl bg-white/10 text-white hover:bg-white/18"
                  onClick={cancelLobby}
                  disabled={busy != null || status !== 'lobby'}
                  title={t('durak.cancelWaitTitle')}
                >
                  <X className="h-5 w-5" />
                </Button>
              ) : (
                <div className="w-12" />
              )}
            </div>

            <div className="flex flex-wrap items-start justify-center gap-6 px-6 pt-6">
              {slots.map((uid, idx) => {
                if (uid == null) {
                  return (
                    <div key={`empty-${idx}`} className="flex w-24 flex-col items-center gap-2">
                      <div className="flex h-[70px] w-[70px] items-center justify-center rounded-full border-2 border-dashed border-white/30 text-white/55">
                        <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M5 22h14"/><path d="M5 2h14"/><path d="M17 22v-4.172a2 2 0 0 0-.586-1.414L12 12l-4.414 4.414A2 2 0 0 0 7 17.828V22"/><path d="M7 2v4.172a2 2 0 0 0 .586 1.414L12 12l4.414-4.414A2 2 0 0 0 17 6.172V2"/></svg>
                      </div>
                      <div className="text-xs font-semibold text-white/55">
                        {t('durak.waiting')}
                      </div>
                    </div>
                  );
                }
                const ready = readyUids.includes(uid);
                const isMe = uid === currentUser.id;
                const av = avatarUrl(uid, allUsers);
                return (
                  <div key={uid} className="flex w-24 flex-col items-center gap-2">
                    <div className="relative">
                      <div
                        className={cn(
                          'h-[70px] w-[70px] overflow-hidden rounded-full border-[3px]',
                          ready ? 'border-lime-400' : 'border-white/45'
                        )}
                      >
                        {av ? (
                          // eslint-disable-next-line @next/next/no-img-element
                          <img src={av} alt="" className="h-full w-full object-cover" />
                        ) : (
                          <div className="flex h-full w-full items-center justify-center bg-white/15 text-2xl font-extrabold text-white">
                            {displayName(uid, allUsers).slice(0, 1).toUpperCase()}
                          </div>
                        )}
                      </div>
                      {ready ? (
                        <div className="absolute -bottom-1 -right-1 flex h-6 w-6 items-center justify-center rounded-full bg-lime-400 text-[#173217]">
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
                        </div>
                      ) : null}
                    </div>
                    <div
                      className={cn(
                        'max-w-[88px] truncate text-xs font-extrabold',
                        isMe ? 'text-white' : 'text-white/85'
                      )}
                    >
                      {displayName(uid, allUsers)}
                    </div>
                  </div>
                );
              })}
            </div>

            <div className="mt-10 flex justify-center">
              <div className="relative h-28 w-24">
                {[0, 1, 2, 3].map((i) => (
                  <div
                    key={i}
                    className="absolute h-24 w-16 rounded-xl border border-white/15 bg-gradient-to-br from-[#2c3e66] to-[#1a2540] shadow-md"
                    style={{
                      left: 14 + i * 3,
                      top: 6 + i * 2,
                      transform: `rotate(${-0.05 + i * 0.025}rad)`,
                    }}
                  />
                ))}
              </div>
            </div>

            <div className="mt-auto flex flex-col items-center gap-3 px-6 pb-6">
              {inGame && gamePlayerIds.length < 2 ? (
                <div className="text-sm text-white/60">
                  {t('durak.waitingForOpponent')}
                </div>
              ) : null}
              <button
                type="button"
                disabled={
                  busy != null ||
                  (!canJoin && !canStart && (!inGame || iAmReady))
                }
                onClick={() => {
                  if (canJoin) void joinLobby();
                  else void startGame();
                }}
                className={cn(
                  'h-14 w-full max-w-md rounded-full text-base font-extrabold shadow-lg transition disabled:cursor-not-allowed disabled:opacity-60',
                  canStart
                    ? 'bg-lime-400 text-[#173217] hover:bg-lime-300'
                    : iAmReady
                      ? 'bg-[#4b6477] text-white'
                      : 'bg-[#8fb2c8] text-white hover:bg-[#9fc1d6]'
                )}
              >
                {canJoin
                  ? t('durak.enterGame')
                  : canStart
                    ? t('durak.startGame')
                    : iAmReady
                      ? t('durak.waiting')
                      : t('durak.ready')}
              </button>
            </div>
          </div>
        </div>
      );
    }

    return (
      <div className="relative h-full min-h-0 overflow-hidden rounded-[30px] border border-white/10 text-white shadow-[inset_0_0_80px_rgba(0,0,0,0.32)]">
        <div className="absolute inset-0 [background:radial-gradient(circle_at_30%_25%,#5f86a1_0%,#253f52_55%,#0e1620_100%)]" />

        <div className="relative z-10 flex h-full flex-col">
          <div className="flex shrink-0 items-center justify-between gap-3 px-4 py-3">
            <div className="flex shrink-0 items-center gap-2">
              <Button
                type="button"
                size="icon"
                className="h-11 w-11 rounded-xl bg-white/16 text-white hover:bg-white/24"
                onClick={() => void makeMove('surrender')}
                disabled={busy != null}
                title={t('durak.surrenderTitle')}
              >
                <Flag className="h-5 w-5" />
              </Button>
              <Button
                type="button"
                size="icon"
                variant="ghost"
                className="h-11 w-11 rounded-xl bg-white/10 text-white hover:bg-white/18"
                onClick={() => void makeMove('surrender')}
                disabled={busy != null || status !== 'active'}
                title={t('durak.endGameTitle')}
              >
                <LogOut className="h-5 w-5" />
              </Button>
            </div>
            <div className="flex min-w-0 flex-1 items-center justify-center gap-3">
              {seats.filter((u) => u !== currentUser.id).slice(0, 5).map((uid) => (
                <PlayerSeat
                  key={uid}
                  uid={uid}
                  allUsers={allUsers}
                  count={handCounts[uid] ?? 0}
                  active={uid === defenderUid || uid === attackerUid || uid === currentThrowerUid}
                  timerActive={publicView?.turnUid === uid}
                  turnStartedAt={publicView?.turnStartedAt ?? null}
                  turnDeadlineAt={publicView?.turnDeadlineAt ?? null}
                  nowMs={nowMs}
                  role={uid === defenderUid ? t('durak.beats') : uid === attackerUid ? t('durak.moves') : uid === currentThrowerUid ? t('durak.toss') : ''}
                  showHandBacks
                />
              ))}
            </div>
            <Button
              type="button"
              size="icon"
              variant="ghost"
              className="h-11 w-11 rounded-xl bg-white/10 text-white hover:bg-white/18"
              onClick={() => onOpenChange(false)}
            >
              <X className="h-5 w-5" />
            </Button>
          </div>

          <div className="relative min-h-0 flex-1">
            {(publicView?.deckCount ?? 0) > 0 ? (
              <div className="absolute left-4 top-6 flex items-center gap-2">
                <DurakCardBackView compact className="rotate-[-14deg]" />
                {publicView?.trumpCard ? (
                  <DurakCardView card={publicView.trumpCard} compact />
                ) : trumpSuit ? (
                  <DurakCardView card={{ r: 6, s: trumpSuit as any }} compact />
                ) : null}
                <div className="text-lg font-black drop-shadow">{publicView?.deckCount ?? 0}</div>
              </div>
            ) : trumpSuit ? (
              <div className="absolute left-4 top-6 flex items-center gap-2 rounded-xl bg-black/20 px-3 py-2 backdrop-blur-sm">
                <span className={cn('text-2xl font-black', (trumpSuit === 'H' || trumpSuit === 'D') ? 'text-red-400' : 'text-white')}>
                  {suitSymbol[trumpSuit] ?? trumpSuit}
                </span>
              </div>
            ) : null}
            {(publicView?.discardCount ?? 0) > 0 ? (
              <div className="absolute right-4 top-6 flex items-center">
                {Array.from({ length: Math.min(5, publicView?.discardCount ?? 0) }).map((_, i) => (
                  <div
                    key={i}
                    className="-ml-6 first:ml-0"
                    style={{ transform: `translateY(${i * 2}px) rotate(${-12 + i * 5}deg)` }}
                  >
                    <DurakCardBackView compact />
                  </div>
                ))}
              </div>
            ) : null}

            <div className="absolute inset-x-4 top-[20%] flex flex-wrap items-center justify-center gap-8">
              {optimisticTable.attacks.map((attack, idx) => (
                <div
                  key={`${cardLabel(attack)}-${idx}`}
                  className={cn(
                    'relative h-32 w-24 cursor-pointer',
                    idx === selectedAttackIndex && 'drop-shadow-[0_0_18px_rgba(255,255,255,.45)]'
                  )}
                  onClick={() => {
                    if (shulerEnabled && status === 'active') {
                      void makeMove('foul', { card: attack });
                    }
                    setSelectedAttackIndex(idx);
                  }}
                >
                  <div className="absolute left-0 top-0 -rotate-3">
                    <DurakCardView card={attack} />
                  </div>
                  <div
                    data-durak-drop="defense"
                    data-attack-index={idx}
                    className={cn(
                      'absolute left-8 top-7 h-[104px] w-[74px] rounded-xl border-2 border-dashed border-white/45',
                      renderDefenseSlotOpen(idx) && 'bg-white/10'
                    )}
                  >
                    {optimisticTable.defenses[idx] ? (
                      <div
                        className="cursor-pointer"
                        onClick={(e) => {
                          if (shulerEnabled && status === 'active') {
                            e.stopPropagation();
                            void makeMove('foul', { card: optimisticTable.defenses[idx] });
                          }
                        }}
                      >
                        <DurakCardView card={optimisticTable.defenses[idx] as DurakCard} className="rotate-6" />
                      </div>
                    ) : (
                      <div className="flex h-full items-center justify-center text-xs font-black text-white/55">
                        <Shield className="h-5 w-5" />
                      </div>
                    )}
                  </div>
                </div>
              ))}
              <div
                data-durak-drop="attack"
                className={cn(
                  'flex h-32 w-24 items-center justify-center rounded-2xl border-2 border-dashed border-white/50 bg-white/8 text-sm font-black uppercase tracking-wide text-white/70',
                  selectedCard && canAttackCard(selectedCard) && 'border-emerald-200 bg-emerald-200/12 text-emerald-50'
                )}
              >
                {t('durak.moveAction')}
              </div>
              {selectedCard && canTransferCard(selectedCard) ? (
                <div
                  data-durak-drop="transfer"
                  className="flex h-32 w-24 items-center justify-center rounded-2xl border-2 border-dashed border-amber-100 bg-amber-200/12 text-sm font-black text-amber-50"
                >
                  {t('durak.transferAction')}
                </div>
              ) : null}
            </div>
          </div>

          <div className="relative z-20 shrink-0 rounded-t-[28px] bg-white/88 px-4 pb-4 pt-3 text-[#db4a68] shadow-[0_-18px_40px_rgba(0,0,0,.18)] backdrop-blur-xl">
            <div className="mb-2 flex items-center gap-3">
              <PlayerSeat
                uid={currentUser.id}
                allUsers={allUsers}
                count={visibleMyCards.length}
                active={publicView?.turnUid === currentUser.id || currentUser.id === attackerUid || currentUser.id === defenderUid}
                timerActive={publicView?.turnUid === currentUser.id}
                turnStartedAt={publicView?.turnStartedAt ?? null}
                turnDeadlineAt={publicView?.turnDeadlineAt ?? null}
                nowMs={nowMs}
                role={currentUser.id === defenderUid ? t('durak.iAttack') : currentUser.id === attackerUid ? t('durak.iMove') : currentUser.id === currentThrowerUid ? t('durak.iToss') : ''}
                tone="panel"
              />
              {primaryLabel ? (
                <button
                  type="button"
                  className="min-w-[150px] rounded-2xl bg-white px-5 py-3 text-2xl font-semibold shadow-md disabled:cursor-default disabled:opacity-100"
                  disabled={busy != null || primaryLabel === t('durak.yourTurn')}
                  onClick={() => {
                    if (primaryLabel === t('durak.take')) void makeMove('take');
                    if (primaryLabel === t('durak.pass')) void makeMove('pass');
                  }}
                >
                  {primaryLabel}
                </button>
              ) : null}
              {myTurnLabel && primaryLabel !== t('durak.yourTurn') ? (
                <div className="rounded-2xl border border-emerald-200/40 bg-emerald-100 px-4 py-3 text-lg font-black text-emerald-700 shadow-md">
                  {myTurnLabel}
                </div>
              ) : null}
            </div>
            <div className="relative h-[118px] overflow-visible">
              <div className="absolute left-1/2 top-2 flex -translate-x-1/2 items-end justify-center">
                {visibleMyCards.map((card, idx) => {
                  const enabled = enabledCard(card);
                  const selected = idx === selectedCardIdx;
                  const draggingThisCard = drag?.index === idx && cardKey(drag.card) === cardKey(card);
                  const offset = idx - (visibleMyCards.length - 1) / 2;
                  const cardWidth = Math.max(50, Math.min(74, 960 / Math.max(8, visibleMyCards.length + 5)));
                  const cardHeight = cardWidth * (104 / 74);
                  const margin = visibleMyCards.length > 10 ? -Math.max(20, cardWidth * 0.42) : -12;
                  return (
                    <button
                      key={`${cardLabel(card)}-${idx}`}
                      type="button"
                      className={cn(
                        'relative first:ml-0 touch-none transition-transform',
                        enabled ? 'cursor-grab active:cursor-grabbing' : 'cursor-default',
                        selected && 'drop-shadow-[0_0_12px_rgba(110,231,183,.65)]',
                        draggingThisCard && 'opacity-0'
                      )}
                      style={{
                        marginLeft: idx === 0 ? 0 : margin,
                        transform: `translateY(${Math.abs(offset) * 2}px) rotate(${offset * 3}deg)`,
                      }}
                      onPointerDown={(e) => {
                        if (!enabled) return;
                        e.preventDefault();
                        setSelectedCardIdx(idx);
                        setDrag({ card, index: idx, startX: e.clientX, startY: e.clientY, x: e.clientX, y: e.clientY });
                      }}
                    >
                      <DurakCardView card={card} width={cardWidth} height={cardHeight} selected={selected} isTrump={!isJoker(card) && card.s === trumpSuit} />
                    </button>
                  );
                })}
              </div>
            </div>
          </div>
        </div>

        {emojiBurst ? <EmojiBurstOverlay /> : null}

        {drag ? (
          <div
            className="pointer-events-none fixed z-[160] -translate-x-1/2 -translate-y-1/2 drop-shadow-2xl"
            style={{ left: drag.x, top: drag.y }}
          >
            <DurakCardView card={drag.card} />
          </div>
        ) : null}
      </div>
    );
  };

  if (standalone) {
    return (
      <main className="h-[100dvh] w-[100dvw] overflow-hidden bg-[#263d4d] p-0">
        {gameBody()}
      </main>
    );
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent
        showCloseButton={false}
        overlayClassName="bg-black/86"
        className="h-[100dvh] max-h-[100dvh] w-[100dvw] max-w-none overflow-hidden rounded-none border-0 bg-[#263d4d] p-2 shadow-none sm:rounded-none"
      >
        <DialogHeader className="sr-only">
          <DialogTitle>{t('durak.dialogTitle')}</DialogTitle>
        </DialogHeader>
        {gameBody()}
      </DialogContent>
    </Dialog>
  );
}

function PlayerSeat({
  uid,
  allUsers,
  count,
  active,
  timerActive,
  turnStartedAt,
  turnDeadlineAt,
  nowMs,
  role,
  showHandBacks = false,
  tone = 'felt',
}: {
  uid: string;
  allUsers: User[];
  count: number;
  active: boolean;
  timerActive: boolean;
  turnStartedAt: string | null;
  turnDeadlineAt: string | null;
  nowMs: number;
  role: string;
  showHandBacks?: boolean;
  tone?: 'felt' | 'panel';
}) {
  const avatar = avatarUrl(uid, allUsers);
  const handBacks = Math.max(0, Math.min(6, Number(count) || 0));
  const panelTone = tone === 'panel';
  const startMs = turnStartedAt ? Date.parse(turnStartedAt) : Number.NaN;
  const endMs = turnDeadlineAt ? Date.parse(turnDeadlineAt) : Number.NaN;
  const progress =
    timerActive && Number.isFinite(startMs) && Number.isFinite(endMs) && endMs > startMs
      ? Math.max(0, Math.min(1, (nowMs - startMs) / (endMs - startMs)))
      : 0;
  const ring = timerActive
    ? {
        background: `conic-gradient(#a3e635 ${Math.round(progress * 360)}deg, rgba(255,255,255,.25) 0deg)`,
      }
    : undefined;
  const avatarSize = panelTone ? 48 : 70;
  const ringPadding = panelTone ? 3 : 4;
  return (
    <div className={cn('flex min-w-[78px] flex-col items-center gap-1', panelTone && 'min-w-[88px]')}>
      <div className={cn('relative', showHandBacks && 'pb-5')}>
        {showHandBacks ? (
          <div className="pointer-events-none absolute left-1/2 top-[78%] z-0 h-10 w-24 -translate-x-1/2">
            {Array.from({ length: handBacks }).map((_, i) => {
              const offset = i - (handBacks - 1) / 2;
              return (
                <div
                  // eslint-disable-next-line react/no-array-index-key
                  key={i}
                  className="absolute left-1/2 top-0 h-10 w-7 origin-top rounded-md border border-white/45 bg-[repeating-linear-gradient(45deg,#e8f7ef_0_4px,#8bbf9c_4px_7px,#f8fff9_7px_10px)] shadow-md"
                  style={{
                    transform: `translateX(-50%) translateX(${offset * 8}px) rotate(${offset * 6}deg)`,
                    zIndex: i,
                  }}
                />
              );
            })}
          </div>
        ) : null}
        <div
          className="relative rounded-full"
          style={{
            width: avatarSize + ringPadding * 2,
            height: avatarSize + ringPadding * 2,
            padding: ringPadding,
            background: timerActive
              ? `conic-gradient(#a3e635 ${Math.round(progress * 360)}deg, rgba(255,255,255,.18) 0deg)`
              : (active ? '#a3e635' : 'rgba(255,255,255,0.45)'),
          }}
        >
          <div
            className="relative z-10 h-full w-full overflow-hidden rounded-full"
            style={{ background: 'rgba(255,255,255,0.15)' }}
          >
            {avatar ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={avatar} alt="" className="h-full w-full rounded-full object-cover" />
            ) : (
              <div className="flex h-full w-full items-center justify-center rounded-full bg-white/15 text-white">
                {displayName(uid, allUsers).slice(0, 1).toUpperCase()}
              </div>
            )}
          </div>
        </div>
        <div
          className={cn(
            'absolute -right-1 -top-1 z-20 rounded-full bg-white px-1.5 py-0.5 text-[10px] font-black text-zinc-700',
          )}
        >
          {count}
        </div>
      </div>
      <div
        className={cn(
          'max-w-[92px] truncate rounded px-2 py-0.5 text-[11px] font-bold',
          panelTone ? 'bg-white text-[#db4a68] shadow-sm' : 'bg-black/25 text-white'
        )}
      >
        {displayName(uid, allUsers)}
      </div>
      {role ? (
        <div className={cn('text-[10px] font-black text-white/72', panelTone && 'text-[#db4a68]/72')}>
          {role}
        </div>
      ) : null}
    </div>
  );
}

function DurakCardBackView({ compact = false, className }: { compact?: boolean; className?: string }) {
  return (
    <div
      className={cn(
        'rounded-xl border border-white/45 bg-[repeating-linear-gradient(45deg,#e8f7ef_0_4px,#8bbf9c_4px_7px,#f8fff9_7px_10px)] shadow-lg',
        compact ? 'h-20 w-14' : 'h-[104px] w-[74px]',
        className
      )}
    >
      <div className="flex h-full w-full items-center justify-center rounded-[inherit] bg-white/10">
        <div className="h-6 w-6 rounded-full border border-emerald-800/20 bg-white/30" />
      </div>
    </div>
  );
}

function DurakCardView({
  card,
  compact = false,
  muted = false,
  selected = false,
  isTrump = false,
  width,
  height,
  className,
}: {
  card: DurakCard;
  compact?: boolean;
  muted?: boolean;
  selected?: boolean;
  isTrump?: boolean;
  width?: number;
  height?: number;
  className?: string;
}) {
  const label = cardLabel(card);
  const red = isRed(card);
  const rank = label.replace(/[♠♥♦♣]/g, '');
  const suit = isJoker(card) ? '★' : suitSymbol[String(card.s)] ?? card.s;
  return (
    <div
      className={cn(
        'relative rounded-xl border bg-[#fbfbff] shadow-[0_10px_20px_rgba(0,0,0,.22)]',
        compact ? 'h-20 w-14' : 'h-[104px] w-[74px]',
        selected && 'ring-2 ring-emerald-300',
        isTrump && !selected ? 'border-amber-400/50 shadow-[0_0_8px_rgba(251,191,36,.25)]' : 'border-black/10',
        className
      )}
      style={width && height ? { width, height } : undefined}
    >
      <div className={cn('absolute left-2 top-1 text-left font-black leading-none', red ? 'text-red-500' : 'text-zinc-950')}>
        <div className={compact ? 'text-base' : 'text-xl'}>{rank}</div>
        <div className={compact ? 'text-sm' : 'text-lg'}>{suit}</div>
      </div>
      <div className={cn('absolute inset-0 flex items-center justify-center font-black', red ? 'text-red-500' : 'text-zinc-950')}>
        <span className={compact ? 'text-2xl' : 'text-4xl'}>{suit}</span>
      </div>
      <div className={cn('absolute bottom-1 right-2 rotate-180 text-left font-black leading-none', red ? 'text-red-500' : 'text-zinc-950')}>
        <div className={compact ? 'text-base' : 'text-xl'}>{rank}</div>
        <div className={compact ? 'text-sm' : 'text-lg'}>{suit}</div>
      </div>
    </div>
  );
}

const BURST_EMOJIS = ['😂', '🤣', '😈', '🃏', '💀', '😏', '🫵', '🤡', '😹', '👺'];

function EmojiBurstOverlay() {
  const particles = useMemo(() => {
    return Array.from({ length: 30 }, (_, i) => ({
      id: i,
      emoji: BURST_EMOJIS[i % BURST_EMOJIS.length],
      left: Math.random() * 100,
      delay: Math.random() * 0.8,
      size: 20 + Math.random() * 28,
      drift: -30 + Math.random() * 60,
    }));
  }, []);

  return (
    <div className="pointer-events-none absolute inset-0 z-[200] overflow-hidden">
      {particles.map((p) => (
        <div
          key={p.id}
          className="absolute animate-[emojiBurst_2.5s_ease-out_forwards]"
          style={{
            left: `${p.left}%`,
            bottom: '-10%',
            fontSize: p.size,
            animationDelay: `${p.delay}s`,
            '--drift': `${p.drift}px`,
          } as React.CSSProperties}
        >
          {p.emoji}
        </div>
      ))}
      <style>{`
        @keyframes emojiBurst {
          0% { transform: translateY(0) translateX(0) rotate(0deg) scale(0.3); opacity: 1; }
          50% { opacity: 1; }
          100% { transform: translateY(-120vh) translateX(var(--drift, 0px)) rotate(360deg) scale(1); opacity: 0; }
        }
      `}</style>
    </div>
  );
}
