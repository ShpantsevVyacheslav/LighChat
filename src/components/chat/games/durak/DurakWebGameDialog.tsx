'use client';

import { useCallback, useMemo, useState } from 'react';
import { doc } from 'firebase/firestore';
import { getFunctions, httpsCallable } from 'firebase/functions';
import { useFirestore, useDoc, useMemoFirebase } from '@/firebase';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { useToast } from '@/hooks/use-toast';
import type { User } from '@/lib/types';

import type { Card } from './durak-cards';
import { cardLabel } from './durak-cards';

type GameDoc = {
  id: string;
  type: 'durak';
  status: 'lobby' | 'active' | 'finished' | 'cancelled';
  playerIds: string[];
  createdBy: string;
  publicView?: any;
};

type HandDoc = {
  uid: string;
  cards: Card[];
};

export function DurakWebGameDialog({
  open,
  onOpenChange,
  gameId,
  currentUser,
}: {
  open: boolean;
  onOpenChange: (v: boolean) => void;
  gameId: string;
  currentUser: User;
}) {
  const firestore = useFirestore();
  const { toast } = useToast();
  const [busy, setBusy] = useState<string | null>(null);

  const gameRef = useMemoFirebase(
    () => (firestore && gameId ? doc(firestore, 'games', gameId) : null),
    [firestore, gameId]
  );
  const { data: game, error: gameError, isLoading: gameLoading } = useDoc<GameDoc>(gameRef);

  const handRef = useMemoFirebase(
    () => (firestore && gameId ? doc(firestore, `games/${gameId}/privateHands/${currentUser.id}`) : null),
    [firestore, gameId, currentUser.id]
  );
  const { data: hand } = useDoc<HandDoc>(handRef);

  const call = useCallback(
    async (name: string, data: Record<string, unknown>) => {
      if (!firestore) return;
      setBusy(name);
      try {
        const fn = httpsCallable(getFunctions(firestore.app, 'us-central1'), name);
        await fn(data);
      } catch (e) {
        const msg = e instanceof Error ? e.message : 'Ошибка';
        toast({ variant: 'destructive', title: 'Ошибка', description: msg });
      } finally {
        setBusy(null);
      }
    },
    [firestore, toast]
  );

  const joinLobby = useCallback(() => call('joinGameLobby', { gameId }), [call, gameId]);
  const startGame = useCallback(() => call('startDurakGame', { gameId }), [call, gameId]);
  const cancelLobby = useCallback(async () => {
    await call('cancelGameLobby', { gameId });
  }, [call, gameId, onOpenChange]);

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
  const playerIds = game?.playerIds ?? [];
  const inGame = playerIds.includes(currentUser.id);
  const isOwner = game?.createdBy === currentUser.id;

  const attacks = (publicView?.table?.attacks ?? []) as Card[];
  const defenses = (publicView?.table?.defenses ?? []) as (Card | null)[];
  const trumpSuit = String(publicView?.trumpSuit ?? '');

  const myCards = hand?.cards ?? [];

  const [selectedCardIdx, setSelectedCardIdx] = useState<number | null>(null);
  const selectedCard = selectedCardIdx == null ? null : myCards[selectedCardIdx] ?? null;

  const header = useMemo(() => {
    if (!gameId) return 'Дурак';
    return `Дурак · ${gameId}`;
  }, [gameId]);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-3xl">
        <DialogHeader>
          <DialogTitle>{header}</DialogTitle>
        </DialogHeader>

        {gameLoading ? (
          <div className="text-sm text-zinc-500">Загрузка…</div>
        ) : gameError ? (
          <div className="text-sm text-zinc-500">
            Нет доступа к игре (скорее всего, ты ещё не в playerIds). Нажми «Присоединиться».
          </div>
        ) : !game ? (
          <div className="text-sm text-zinc-500">Игра не найдена</div>
        ) : (
          <div className="space-y-4">
            <div className="flex flex-wrap items-center gap-2">
              <Badge variant="secondary">status: {status}</Badge>
              <Badge variant="secondary">players: {playerIds.length}</Badge>
              <Badge variant="secondary">trump: {trumpSuit || '—'}</Badge>
              <div className="ml-auto flex items-center gap-2">
                <Button onClick={joinLobby} disabled={busy != null}>
                  Присоединиться
                </Button>
                <Button onClick={startGame} disabled={busy != null || status !== 'lobby' || !inGame}>
                  Старт
                </Button>
                <Button
                  variant="outline"
                  onClick={cancelLobby}
                  disabled={busy != null || status !== 'lobby' || !isOwner}
                >
                  Завершить ожидание
                </Button>
              </div>
            </div>

            {status === 'active' ? (
              <>
                <div className="rounded-2xl border border-zinc-800/60 bg-zinc-900/30 p-4">
                  <div className="mb-2 text-xs font-bold uppercase text-zinc-500">Стол</div>
                  <div className="grid grid-cols-1 gap-2">
                    {attacks.length === 0 ? (
                      <div className="text-sm text-zinc-500">Пусто</div>
                    ) : (
                      attacks.map((a, i) => (
                        <div key={i} className="flex items-center gap-3">
                          <div className="rounded-xl border border-zinc-800/60 bg-zinc-950/40 px-3 py-2 text-sm font-bold text-zinc-100">
                            {cardLabel(a)}
                          </div>
                          <div className="text-xs text-zinc-500">→</div>
                          <div className="rounded-xl border border-zinc-800/60 bg-zinc-950/40 px-3 py-2 text-sm font-bold text-zinc-100">
                            {defenses[i] ? cardLabel(defenses[i] as Card) : '—'}
                          </div>
                        </div>
                      ))
                    )}
                  </div>
                </div>

                <div className="rounded-2xl border border-zinc-800/60 bg-zinc-900/30 p-4">
                  <div className="mb-2 flex items-center justify-between gap-2">
                    <div className="text-xs font-bold uppercase text-zinc-500">Моя рука</div>
                    <div className="flex items-center gap-2">
                      <Button
                        size="sm"
                        onClick={() => selectedCard && makeMove('attack', { card: selectedCard })}
                        disabled={busy != null || !selectedCard}
                      >
                        Атака
                      </Button>
                      <Button
                        size="sm"
                        onClick={() => makeMove('take')}
                        disabled={busy != null}
                      >
                        Взять
                      </Button>
                      <Button
                        size="sm"
                        onClick={() => makeMove('pass')}
                        disabled={busy != null}
                      >
                        Пас
                      </Button>
                      <Button
                        size="sm"
                        onClick={() => makeMove('finishTurn')}
                        disabled={busy != null}
                      >
                        Бито
                      </Button>
                    </div>
                  </div>

                  <div className="flex flex-wrap gap-2">
                    {myCards.length === 0 ? (
                      <div className="text-sm text-zinc-500">Нет карт</div>
                    ) : (
                      myCards.map((c, idx) => {
                        const isSel = idx === selectedCardIdx;
                        return (
                          <button
                            key={idx}
                            type="button"
                            onClick={() => setSelectedCardIdx(isSel ? null : idx)}
                            className={[
                              'rounded-xl border px-3 py-2 text-sm font-bold',
                              isSel
                                ? 'border-amber-400 bg-amber-400/10 text-zinc-100'
                                : 'border-zinc-800/60 bg-zinc-950/40 text-zinc-200 hover:border-zinc-700',
                            ].join(' ')}
                          >
                            {cardLabel(c)}
                          </button>
                        );
                      })
                    )}
                  </div>
                </div>
              </>
            ) : status === 'cancelled' ? (
              <div className="rounded-2xl border border-zinc-800/60 bg-zinc-900/30 p-4">
                <div className="text-sm font-bold text-zinc-100">Лобби завершено</div>
                <div className="mt-1 text-sm text-zinc-500">
                  Создатель завершил ожидание. Это лобби больше недоступно для старта.
                </div>
                <div className="mt-3 flex items-center gap-2">
                  <Button variant="outline" onClick={() => onOpenChange(false)} disabled={busy != null}>
                    Закрыть
                  </Button>
                </div>
              </div>
            ) : (
              <div className="text-sm text-zinc-500">
                Открой лобби (join) и нажми «Старт», чтобы начать игру.
              </div>
            )}
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}

