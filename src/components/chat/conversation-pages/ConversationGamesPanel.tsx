'use client';

import { useMemo, useState, useCallback } from 'react';
import { collection, doc, limit, orderBy, query } from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';
import { getFunctions } from 'firebase/functions';
import { Trophy, PlusCircle, ChevronRight, Swords } from 'lucide-react';

import { useCollection, useDoc, useFirestore, useMemoFirebase } from '@/firebase';
import type { User } from '@/lib/types';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { useToast } from '@/hooks/use-toast';

type GameLobbyIndexDoc = {
  gameId?: string;
  type?: string;
  status?: string;
  createdAt?: string;
  createdBy?: string;
  playerCount?: number;
  maxPlayers?: number;
};

type TournamentDoc = {
  id: string;
  type: 'durak';
  title?: string;
  status?: string;
  conversationId: string;
  pointsByUid?: Record<string, number>;
  gamesPlayedByUid?: Record<string, number>;
  createdAt?: string;
};

type TournamentGameDoc = {
  status?: string;
  playerIds?: string[];
  placements?: { uids: string[] }[];
  loserUid?: string | null;
  createdAt?: string;
};

function nameOfUid(uid: string, allUsers: User[]) {
  return allUsers.find((u) => u.id === uid)?.name ?? uid;
}

export function ConversationGamesPanel({
  conversationId,
  currentUser,
  allUsers,
  onCreatedGameLobby,
}: {
  conversationId: string;
  currentUser: User;
  allUsers: User[];
  onCreatedGameLobby?: (gameId: string) => void;
}) {
  const firestore = useFirestore();
  const { toast } = useToast();
  const [selectedTournamentId, setSelectedTournamentId] = useState<string | null>(null);
  const [busy, setBusy] = useState<string | null>(null);

  const lobbiesQuery = useMemoFirebase(
    () =>
      firestore && conversationId
        ? query(
            collection(firestore, `conversations/${conversationId}/gameLobbies`),
            orderBy('createdAt', 'desc'),
            limit(10)
          )
        : null,
    [firestore, conversationId]
  );
  const { data: lobbyIndexRows } = useCollection<GameLobbyIndexDoc>(lobbiesQuery);
  const durakLobbies = useMemo(() => {
    const rows = lobbyIndexRows ?? [];
    return rows.filter((r) => (r.type ?? '') === 'durak' && ['lobby', 'active'].includes(String(r.status ?? '')));
  }, [lobbyIndexRows]);

  const tournamentsQuery = useMemoFirebase(
    () =>
      firestore && conversationId
        ? query(
            collection(firestore, `conversations/${conversationId}/tournaments`),
            orderBy('createdAt', 'desc'),
            limit(20)
          )
        : null,
    [firestore, conversationId]
  );
  const { data: tournamentIndexRows, isLoading: isLoadingTournaments } = useCollection<any>(tournamentsQuery);
  const tournaments = useMemo(() => tournamentIndexRows ?? [], [tournamentIndexRows]);

  const selectedTournamentRef = useMemoFirebase(
    () => (firestore && selectedTournamentId ? doc(firestore, 'tournaments', selectedTournamentId) : null),
    [firestore, selectedTournamentId]
  );
  const { data: selectedTournament } = useDoc<TournamentDoc>(selectedTournamentRef);

  const gamesQuery = useMemoFirebase(
    () =>
      firestore && selectedTournamentId
        ? query(
            collection(firestore, `tournaments/${selectedTournamentId}/games`),
            orderBy('createdAt', 'desc'),
            limit(30)
          )
        : null,
    [firestore, selectedTournamentId]
  );
  const { data: tournamentGamesRows } = useCollection<TournamentGameDoc>(gamesQuery);
  const tournamentGames = useMemo(() => tournamentGamesRows ?? [], [tournamentGamesRows]);

  const createTournament = useCallback(async () => {
    if (!firestore) return;
    setBusy('createTournament');
    try {
      const fn = httpsCallable(getFunctions(firestore.app, 'us-central1'), 'createDurakTournament');
      const res = await fn({ conversationId });
      const tid = (res.data as any)?.tournamentId as string | undefined;
      if (tid) setSelectedTournamentId(tid);
      toast({ title: 'Турнир создан' });
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'Не удалось создать турнир';
      toast({ variant: 'destructive', title: 'Ошибка', description: msg });
    } finally {
      setBusy(null);
    }
  }, [conversationId, firestore, toast]);

  const createTournamentGame = useCallback(async () => {
    if (!firestore || !selectedTournamentId) return;
    setBusy('createTournamentGame');
    try {
      const fn = httpsCallable(getFunctions(firestore.app, 'us-central1'), 'createTournamentGameLobby');
      const res = await fn({
        tournamentId: selectedTournamentId,
        settings: {
          maxPlayers: 6,
          deckSize: 36,
          mode: 'podkidnoy',
          withJokers: false,
          turnTimeSec: null,
          throwInPolicy: 'all',
          shulerEnabled: false,
        },
      });
      const gameId = (res.data as any)?.gameId as string | undefined;
      if (gameId) {
        toast({ title: 'Партия создана', description: `gameId: ${gameId}` });
        onCreatedGameLobby?.(gameId);
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'Не удалось создать партию';
      toast({ variant: 'destructive', title: 'Ошибка', description: msg });
    } finally {
      setBusy(null);
    }
  }, [firestore, onCreatedGameLobby, selectedTournamentId, toast]);

  if (selectedTournamentId) {
    const t = selectedTournament;
    const pointsByUid = t?.pointsByUid ?? {};
    const playedByUid = t?.gamesPlayedByUid ?? {};
    const standingsUids = Array.from(
      new Set([...Object.keys(pointsByUid), ...Object.keys(playedByUid)].filter(Boolean))
    );
    standingsUids.sort((a, b) => {
      const pa = pointsByUid[a] ?? 0;
      const pb = pointsByUid[b] ?? 0;
      if (pa !== pb) return pb - pa;
      const ga = playedByUid[a] ?? 0;
      const gb = playedByUid[b] ?? 0;
      return gb - ga;
    });

    return (
      <div className="space-y-4">
        <div className="flex items-center justify-between gap-2">
          <Button variant="ghost" onClick={() => setSelectedTournamentId(null)}>
            ← Назад
          </Button>
          <Button
            onClick={createTournamentGame}
            disabled={busy != null}
            className="gap-2"
          >
            <PlusCircle className="h-4 w-4" />
            Новая партия
          </Button>
        </div>

        <div className="rounded-3xl border border-zinc-800/60 bg-zinc-900/30 p-4">
          <div className="mb-1 flex items-center gap-2">
            <Trophy className="h-5 w-5 text-amber-400" />
            <div className="text-sm font-bold text-zinc-100">{t?.title ?? 'Турнир'}</div>
            <Badge variant="secondary" className="ml-auto">
              {t?.status ?? 'active'}
            </Badge>
          </div>
          <div className="mt-3 space-y-2">
            {standingsUids.length === 0 ? (
              <div className="text-xs text-zinc-500">Пока нет результатов</div>
            ) : (
              standingsUids.map((uid) => (
                <div key={uid} className="flex items-center justify-between gap-2 text-sm">
                  <div className="min-w-0 truncate text-zinc-200">{nameOfUid(uid, allUsers)}</div>
                  <div className="shrink-0 text-zinc-400">
                    {pointsByUid[uid] ?? 0} pts · {playedByUid[uid] ?? 0} игр
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        <div className="space-y-2">
          <div className="text-xs font-bold uppercase text-zinc-500">Партии</div>
          {tournamentGames.length === 0 ? (
            <div className="text-xs text-zinc-500">Пока нет партий</div>
          ) : (
            tournamentGames.map((g, idx) => {
              const status = g.status ?? '';
              const players = (g.playerIds ?? []).map((u) => nameOfUid(u, allUsers)).join(', ');
              const loser = g.loserUid ? nameOfUid(g.loserUid, allUsers) : '';
              const placements = (g.placements ?? [])
                .map((grp, i) => {
                  const start = grp.uids.length === 1 ? `${i + 1}` : `${i + 1}-${i + grp.uids.length}`;
                  const names = grp.uids.map((u) => nameOfUid(u, allUsers)).join(', ');
                  return `Место ${start}: ${names}`;
                })
                .join(' · ');
              return (
                <div
                  key={`${idx}-${status}-${players}`}
                  className="rounded-3xl border border-zinc-800/60 bg-zinc-900/40 p-4"
                >
                  <div className="flex items-center gap-2">
                    <Swords className="h-4 w-4 text-emerald-400" />
                    <div className="text-sm font-bold text-zinc-100">Дурак</div>
                    <Badge variant="secondary" className="ml-auto">
                      {status}
                    </Badge>
                  </div>
                  {players && <div className="mt-2 text-xs text-zinc-400">Игроки: {players}</div>}
                  {status === 'finished' && (
                    <>
                      <div className="mt-1 text-xs text-zinc-400">
                        Результат: {loser ? `дурак — ${loser}` : 'ничья'}
                      </div>
                      {placements && <div className="mt-1 text-xs text-zinc-500">{placements}</div>}
                    </>
                  )}
                </div>
              );
            })
          )}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-3">
      <div className="space-y-2">
        <div className="text-xs font-bold uppercase text-zinc-500">Лобби</div>
        {durakLobbies.length === 0 ? (
          <div className="text-xs text-zinc-500">Активных лобби нет</div>
        ) : (
          <div className="space-y-2">
            {durakLobbies.map((l, idx) => {
              const gameId = (l.gameId ?? '') || '';
              const status = String(l.status ?? '');
              const pc = typeof l.playerCount === 'number' ? l.playerCount : 0;
              const mp = typeof l.maxPlayers === 'number' ? l.maxPlayers : 0;
              const canOpen = Boolean(gameId);
              return (
                <div
                  key={`${gameId || idx}-${status}`}
                  className="flex items-center justify-between gap-3 rounded-3xl border border-zinc-800/60 bg-zinc-900/40 p-4"
                >
                  <div className="min-w-0">
                    <div className="flex items-center gap-2">
                      <Swords className="h-4 w-4 text-emerald-400" />
                      <div className="truncate text-sm font-bold text-zinc-100">Дурак</div>
                      <Badge variant="secondary">{status}</Badge>
                      <Badge variant="secondary" className="ml-auto">
                        {pc}/{mp}
                      </Badge>
                    </div>
                    {gameId && <div className="mt-1 text-xs text-zinc-500">gameId: {gameId}</div>}
                  </div>
                  <Button
                    size="sm"
                    disabled={!canOpen}
                    onClick={() => {
                      if (!gameId) return;
                      onCreatedGameLobby?.(gameId);
                    }}
                    className="gap-2"
                  >
                    Открыть
                    <ChevronRight className="h-4 w-4" />
                  </Button>
                </div>
              );
            })}
          </div>
        )}
      </div>

      <div className="flex items-center justify-between gap-2">
        <div className="text-sm font-bold text-zinc-100">Игры</div>
        <Button onClick={createTournament} disabled={busy != null} className="gap-2">
          <Trophy className="h-4 w-4" />
          Создать турнир
        </Button>
      </div>

      <div className="text-xs text-zinc-500">Турниры</div>
      {isLoadingTournaments && !tournamentIndexRows ? (
        <div className="text-xs text-zinc-500">Загрузка…</div>
      ) : tournaments.length === 0 ? (
        <div className="text-xs text-zinc-500">Пока нет турниров</div>
      ) : (
        <div className="space-y-2">
          {tournaments.map((row: any) => (
            <button
              key={row.tournamentId ?? row.id}
              type="button"
              onClick={() => setSelectedTournamentId((row.tournamentId ?? row.id) as string)}
              className="flex w-full items-center gap-3 rounded-3xl border border-zinc-800/60 bg-zinc-900/40 p-4 text-left transition-all hover:border-zinc-700 hover:bg-zinc-900/70 active:scale-[0.99]"
            >
              <Trophy className="h-5 w-5 text-amber-400" />
              <div className="min-w-0 flex-1">
                <div className="truncate text-sm font-bold text-zinc-100">
                  {row.title ?? 'Турнир'}
                </div>
                <div className="text-xs text-zinc-500">{row.status ?? 'active'}</div>
              </div>
              <ChevronRight className="h-5 w-5 text-zinc-500" />
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

