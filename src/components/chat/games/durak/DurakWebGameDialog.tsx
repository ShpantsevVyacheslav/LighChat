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
import type { DurakCard, DurakGameSession, User } from '@/lib/types';
import { cn } from '@/lib/utils';

import { cardLabel, isJoker } from './durak-cards';

type HandDoc = {
  uid: string;
  cards: DurakCard[];
};

type DragState = {
  card: DurakCard;
  index: number;
  startX: number;
  startY: number;
  x: number;
  y: number;
};

const suitSymbol: Record<string, string> = {
  S: '♠',
  H: '♥',
  D: '♦',
  C: '♣',
};

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
}: {
  open: boolean;
  onOpenChange: (v: boolean) => void;
  gameId: string;
  currentUser: User;
  allUsers: User[];
}) {
  const firestore = useFirestore();
  const { toast } = useToast();
  const [busy, setBusy] = useState<string | null>(null);
  const [selectedCardIdx, setSelectedCardIdx] = useState<number | null>(null);
  const [selectedAttackIndex, setSelectedAttackIndex] = useState(0);
  const [drag, setDrag] = useState<DragState | null>(null);
  const dragRef = useRef<DragState | null>(null);
  const moveInFlightRef = useRef(false);

  const gameRef = useMemoFirebase(
    () => (firestore && gameId ? doc(firestore, 'games', gameId) : null),
    [firestore, gameId]
  );
  const { data: game, error: gameError, isLoading: gameLoading } = useDoc<DurakGameSession>(gameRef);

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
      if (!firestore) return;
      if (name === 'makeDurakMove' && moveInFlightRef.current) return;
      if (name === 'makeDurakMove') moveInFlightRef.current = true;
      setBusy(name);
      try {
        const fn = httpsCallable(getFunctions(firestore.app, 'us-central1'), name);
        await fn(data);
      } catch (e) {
        const msg = e instanceof Error ? e.message : 'Ошибка';
        toast({ variant: 'destructive', title: 'Ошибка', description: msg });
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
  const makeMove = useCallback(
    (actionType: string, payload?: Record<string, unknown>) =>
      call('makeDurakMove', {
        gameId,
        clientMoveId: `${Date.now()}_${Math.random().toString(16).slice(2)}`,
        actionType,
        payload: payload ?? null,
      }),
    [call, gameId]
  );

  const publicView = game?.publicView ?? null;
  const status = game?.status ?? '';
  const isOwner = game?.createdBy === currentUser.id;
  const attacks = publicView?.table?.attacks ?? [];
  const defenses = publicView?.table?.defenses ?? [];
  const trumpSuit = String(publicView?.trumpSuit ?? '');
  const myCards = hand?.cards ?? [];
  const selectedCard = selectedCardIdx == null ? null : myCards[selectedCardIdx] ?? null;
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
  const canFinishTurn = publicView?.canFinishTurn ?? fallbackCanFinishTurn();

  function fallbackCurrentThrower(): string | null {
    if (attacks.length === 0) return null;
    const throwers = publicView?.throwerUids ?? seats.filter((u) => u !== defenderUid);
    const attackerIdx = seats.indexOf(attackerUid);
    const ordered = attackerIdx < 0 ? seats : [...seats.slice(attackerIdx), ...seats.slice(0, attackerIdx)];
    return ordered.find((u) => throwers.includes(u) && !passedUids.has(u) && (handCounts[u] ?? 0) > 0) ?? null;
  }

  function fallbackCanFinishTurn(): boolean {
    return attacks.length > 0 && defenses.length === attacks.length && defenses.every(Boolean) && currentThrowerUid == null;
  }

  const defenseSlotOpen = (idx: number) => idx >= 0 && idx < attacks.length && !defenses[idx];

  const canAttackCard = useCallback(
    (card: DurakCard) => {
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
    [attackerUid, attacks.length, currentThrowerUid, currentUser.id, defenderUid, handCounts, publicView, status, tableRanks]
  );

  const canDefendCardAt = useCallback(
    (card: DurakCard, idx: number) => {
      if (status !== 'active' || currentUser.id !== defenderUid || !trumpSuit || !defenseSlotOpen(idx)) return false;
      const attack = attacks[idx];
      return Boolean(attack && beats({ attack, defense: card, trumpSuit }));
    },
    [attacks, currentUser.id, defenderUid, status, trumpSuit]
  );

  const canTransferCard = useCallback(
    (card: DurakCard) => {
      if (status !== 'active' || currentUser.id !== defenderUid || game?.publicView == null) return false;
      const mode = (game as any)?.settings?.mode ?? 'podkidnoy';
      if (mode !== 'perevodnoy' || attacks.length === 0 || defenses.some(Boolean)) return false;
      const defenderCount = handCounts[defenderUid] ?? 0;
      const roundLimit = publicView?.roundDefenderHandLimit ?? (defenderCount > 0 ? defenderCount : 6);
      if (attacks.length >= 6 || attacks.length >= roundLimit) return false;
      return isJoker(card) || tableRanks.has(rankKey(card));
    },
    [attacks.length, currentUser.id, defenderUid, defenses, game, handCounts, publicView, status, tableRanks]
  );

  const handleCardTap = useCallback(
    (card: DurakCard, idx: number) => {
      const actions = [
        canAttackCard(card) ? 'attack' : '',
        canTransferCard(card) ? 'transfer' : '',
        canDefendCardAt(card, selectedAttackIndex) ? 'defend' : '',
      ].filter(Boolean);
      if (actions.length === 1) {
        const action = actions[0];
        if (action === 'attack') void makeMove('attack', { card });
        if (action === 'transfer') void makeMove('transfer', { card });
        if (action === 'defend') void makeMove('defend', { attackIndex: selectedAttackIndex, card });
        return;
      }
      setSelectedCardIdx((old) => (old === idx ? null : idx));
    },
    [canAttackCard, canDefendCardAt, canTransferCard, makeMove, selectedAttackIndex]
  );

  const playDrop = useCallback(
    async (dropEl: Element | null, d: DragState) => {
      const target = dropEl?.closest<HTMLElement>('[data-durak-drop]');
      if (!target) {
        toast({ title: 'Карта вернулась в руку', description: 'Перетащи карту на подсвеченную зону стола.' });
        return;
      }
      const kind = target.dataset.durakDrop;
      if (kind === 'attack' && canAttackCard(d.card)) {
        await makeMove('attack', { card: d.card });
        return;
      }
      if (kind === 'transfer' && canTransferCard(d.card)) {
        await makeMove('transfer', { card: d.card });
        return;
      }
      if (kind === 'defense') {
        const idx = Number(target.dataset.attackIndex ?? -1);
        if (Number.isFinite(idx) && canDefendCardAt(d.card, idx)) {
          await makeMove('defend', { attackIndex: idx, card: d.card });
          return;
        }
      }
      toast({ variant: 'destructive', title: 'Ход недоступен', description: 'Эту карту нельзя сыграть в выбранную зону.' });
    },
    [canAttackCard, canDefendCardAt, canTransferCard, makeMove, toast]
  );

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
    if (attacks.length === 0 && currentUser.id === attackerUid && currentUser.id !== defenderUid) return 'Твой ход';
    if (currentUser.id === defenderUid && attacks.length > 0) return 'Твой ход';
    if (currentUser.id === currentThrowerUid) return 'Твой ход';
    if (canFinishTurn && currentUser.id === attackerUid) return 'Твой ход';
    return '';
  }, [attackerUid, attacks.length, canFinishTurn, currentThrowerUid, currentUser.id, defenderUid, status]);

  const primaryLabel = useMemo(() => {
    if (status !== 'active') return '';
    if (currentUser.id === defenderUid) return attacks.length > 0 ? 'Беру' : '';
    if (canFinishTurn && currentUser.id === attackerUid) return 'Бито';
    if (attacks.length === 0 && currentUser.id === attackerUid && currentUser.id !== defenderUid) return 'Твой ход';
    if (currentUser.id === currentThrowerUid) return 'Пас';
    return '';
  }, [attackerUid, attacks.length, canFinishTurn, currentThrowerUid, currentUser.id, defenderUid, status]);

  const enabledCard = (card: DurakCard) =>
    canAttackCard(card) || canTransferCard(card) || canDefendCardAt(card, selectedAttackIndex);

  const gameBody = () => {
    if (gameLoading) return <div className="text-sm text-white/70">Загрузка…</div>;
    if (gameError) {
      return (
        <div className="max-w-md rounded-2xl bg-white/10 p-5 text-sm text-white/75">
          Нет доступа к игре. Если это лобби, попробуй присоединиться из карточки приглашения.
        </div>
      );
    }
    if (!game) return <div className="text-sm text-white/70">Игра не найдена</div>;

    if (status !== 'active') {
      return (
        <div className="mx-auto flex w-full max-w-xl flex-col gap-4 rounded-[28px] border border-white/12 bg-white/10 p-5 text-white shadow-2xl backdrop-blur-xl">
          <div className="flex items-center gap-3">
            <Swords className="h-6 w-6 text-emerald-300" />
            <div>
              <div className="text-lg font-black">Лобби “Дурак”</div>
              <div className="text-sm text-white/60">{gamePlayerIds.length} игроков · статус: {status}</div>
            </div>
          </div>
          <div className="flex flex-wrap gap-2">
            {!inGame ? (
              <Button onClick={joinLobby} disabled={busy != null || status !== 'lobby'} className="gap-2">
                <LogOut className="h-4 w-4" />
                Присоединиться
              </Button>
            ) : (
              <Badge className="bg-white/15 text-white">Ты в игре</Badge>
            )}
            <Button
              onClick={startGame}
              disabled={busy != null || status !== 'lobby' || !inGame || !isOwner || gamePlayerIds.length < 2}
              className="gap-2"
            >
              <Play className="h-4 w-4" />
              Старт
            </Button>
            <Button variant="outline" onClick={cancelLobby} disabled={busy != null || status !== 'lobby' || !isOwner}>
              Завершить ожидание
            </Button>
          </div>
        </div>
      );
    }

    return (
      <div className="relative h-full min-h-0 overflow-hidden rounded-[30px] border border-white/10 bg-[#496f88] text-white shadow-[inset_0_0_80px_rgba(0,0,0,0.22)]">
        <div className="absolute inset-0 opacity-[0.16] [background-image:radial-gradient(circle_at_20%_20%,white_0_1px,transparent_1px),linear-gradient(135deg,rgba(255,255,255,.16),transparent_30%,rgba(0,0,0,.18))] [background-size:7px_7px,100%_100%]" />

        <div className="relative z-10 flex h-full flex-col">
          <div className="flex shrink-0 items-center justify-between gap-3 px-4 py-3">
            <Button
              type="button"
              size="icon"
              className="h-11 w-11 rounded-xl bg-white/16 text-white hover:bg-white/24"
              onClick={() => void makeMove('surrender')}
              disabled={busy != null}
              title="Сдаться"
            >
              <Flag className="h-5 w-5" />
            </Button>
            <div className="flex min-w-0 flex-1 items-center justify-center gap-3">
              {seats.filter((u) => u !== currentUser.id).slice(0, 5).map((uid) => (
                <PlayerSeat
                  key={uid}
                  uid={uid}
                  allUsers={allUsers}
                  count={handCounts[uid] ?? 0}
                  active={uid === defenderUid || uid === attackerUid || uid === currentThrowerUid}
                  role={uid === defenderUid ? 'БЬЕТ' : uid === attackerUid ? 'ХОД' : uid === currentThrowerUid ? 'ПОДК' : ''}
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
            <div className="absolute left-4 top-6 flex items-center gap-2">
              <div className="relative h-24 w-16 rotate-[-14deg] rounded-xl border border-white/40 bg-[repeating-linear-gradient(45deg,#d9efe2_0_4px,#87b999_4px_7px,#f7fff9_7px_10px)] shadow-lg" />
              <DurakCardView card={{ r: 6, s: trumpSuit as any }} compact muted />
              <div className="text-lg font-black drop-shadow">{publicView?.deckCount ?? 0}</div>
            </div>

            <div className="absolute inset-x-4 top-[20%] flex flex-wrap items-center justify-center gap-8">
              {attacks.map((attack, idx) => (
                <div
                  key={`${cardLabel(attack)}-${idx}`}
                  className={cn(
                    'relative h-32 w-24 cursor-pointer',
                    idx === selectedAttackIndex && 'drop-shadow-[0_0_18px_rgba(255,255,255,.45)]'
                  )}
                  onClick={() => setSelectedAttackIndex(idx)}
                >
                  <div className="absolute left-0 top-0 -rotate-3">
                    <DurakCardView card={attack} />
                  </div>
                  <div
                    data-durak-drop="defense"
                    data-attack-index={idx}
                    className={cn(
                      'absolute left-8 top-7 h-[104px] w-[74px] rounded-xl border-2 border-dashed border-white/45',
                      defenseSlotOpen(idx) && 'bg-white/10'
                    )}
                  >
                    {defenses[idx] ? (
                      <DurakCardView card={defenses[idx] as DurakCard} className="rotate-6" />
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
                Ход
              </div>
              {selectedCard && canTransferCard(selectedCard) ? (
                <div
                  data-durak-drop="transfer"
                  className="flex h-32 w-24 items-center justify-center rounded-2xl border-2 border-dashed border-amber-100 bg-amber-200/12 text-sm font-black text-amber-50"
                >
                  Перевод
                </div>
              ) : null}
            </div>
          </div>

          <div className="relative z-20 shrink-0 rounded-t-[28px] bg-white/88 px-4 pb-4 pt-3 text-[#db4a68] shadow-[0_-18px_40px_rgba(0,0,0,.18)] backdrop-blur-xl">
            <div className="mb-2 flex items-center gap-3">
              {primaryLabel ? (
                <button
                  type="button"
                  className="min-w-[150px] rounded-2xl bg-white px-5 py-3 text-2xl font-semibold shadow-md disabled:cursor-default disabled:opacity-100"
                  disabled={busy != null || primaryLabel === 'Твой ход'}
                  onClick={() => {
                    if (primaryLabel === 'Беру') void makeMove('take');
                    if (primaryLabel === 'Бито') void makeMove('finishTurn');
                    if (primaryLabel === 'Пас') void makeMove('pass');
                  }}
                >
                  {primaryLabel}
                </button>
              ) : null}
              {myTurnLabel && primaryLabel !== 'Твой ход' ? (
                <div className="rounded-2xl border border-emerald-200/40 bg-emerald-100 px-4 py-3 text-lg font-black text-emerald-700 shadow-md">
                  {myTurnLabel}
                </div>
              ) : null}
              <div className="flex items-center gap-2 rounded-xl border border-[#db4a68]/20 bg-white px-3 py-2 text-sm text-zinc-600">
                <span className="font-black text-[#db4a68]">{displayName(currentUser.id, allUsers)}</span>
                <span>{myCards.length} карт</span>
              </div>
              <Button
                type="button"
                variant="outline"
                className="border-[#db4a68]/35 bg-white text-[#db4a68] hover:bg-[#fff6f8]"
                disabled={busy != null || status !== 'active'}
                onClick={() => void makeMove('surrender')}
              >
                Завершить игру
              </Button>
            </div>
            <div className="relative h-[118px] overflow-visible">
              <div className="absolute left-1/2 top-2 flex -translate-x-1/2 items-end justify-center">
                {myCards.map((card, idx) => {
                  const enabled = enabledCard(card);
                  const selected = idx === selectedCardIdx;
                  const offset = idx - (myCards.length - 1) / 2;
                  return (
                    <button
                      key={`${cardLabel(card)}-${idx}`}
                      type="button"
                      className={cn(
                        'relative -ml-3 first:ml-0 touch-none transition-transform',
                        enabled ? 'cursor-grab active:cursor-grabbing' : 'opacity-60',
                        selected && '-translate-y-4'
                      )}
                      style={{ transform: `translateY(${selected ? -18 : Math.abs(offset) * 2}px) rotate(${offset * 3}deg)` }}
                      onPointerDown={(e) => {
                        if (!enabled) return;
                        e.preventDefault();
                        setSelectedCardIdx(idx);
                        setDrag({ card, index: idx, startX: e.clientX, startY: e.clientY, x: e.clientX, y: e.clientY });
                      }}
                    >
                      <DurakCardView card={card} />
                    </button>
                  );
                })}
              </div>
            </div>
          </div>
        </div>

        {drag ? (
          <div
            className="pointer-events-none fixed z-[160] -translate-x-1/2 -translate-y-1/2 opacity-95 drop-shadow-2xl"
            style={{ left: drag.x, top: drag.y }}
          >
            <DurakCardView card={drag.card} />
          </div>
        ) : null}
      </div>
    );
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent
        showCloseButton={false}
        overlayClassName="bg-black/86"
        className="h-[100dvh] max-h-[100dvh] w-[100dvw] max-w-none overflow-hidden rounded-none border-0 bg-[#263d4d] p-2 shadow-none sm:rounded-none"
      >
        <DialogHeader className="sr-only">
          <DialogTitle>Дурак</DialogTitle>
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
  role,
}: {
  uid: string;
  allUsers: User[];
  count: number;
  active: boolean;
  role: string;
}) {
  const avatar = avatarUrl(uid, allUsers);
  return (
    <div className="flex min-w-[78px] flex-col items-center gap-1">
      <div className="relative">
        <div className={cn('h-16 w-16 rounded-xl border-4 bg-white/20 p-1 shadow-lg', active ? 'border-lime-400' : 'border-white/20')}>
          {avatar ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={avatar} alt="" className="h-full w-full rounded-lg object-cover" />
          ) : (
            <div className="flex h-full w-full items-center justify-center rounded-lg bg-zinc-300 text-zinc-600">
              {displayName(uid, allUsers).slice(0, 1).toUpperCase()}
            </div>
          )}
        </div>
        <div className="absolute -right-2 -top-2 rounded-full bg-white px-1.5 py-0.5 text-[10px] font-black text-zinc-700">
          {count}
        </div>
      </div>
      <div className="max-w-[92px] truncate rounded bg-black/25 px-2 py-0.5 text-[11px] font-bold text-white">
        {displayName(uid, allUsers)}
      </div>
      {role ? <div className="text-[10px] font-black text-white/72">{role}</div> : null}
    </div>
  );
}

function DurakCardView({
  card,
  compact = false,
  muted = false,
  className,
}: {
  card: DurakCard;
  compact?: boolean;
  muted?: boolean;
  className?: string;
}) {
  const label = cardLabel(card);
  const red = isRed(card);
  const rank = label.replace(/[♠♥♦♣]/g, '');
  const suit = isJoker(card) ? '★' : suitSymbol[String(card.s)] ?? card.s;
  return (
    <div
      className={cn(
        'relative rounded-xl border border-black/10 bg-[#fbfbff] shadow-[0_10px_20px_rgba(0,0,0,.22)]',
        compact ? 'h-20 w-14' : 'h-[104px] w-[74px]',
        muted && 'opacity-90',
        className
      )}
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
