'use client';

import { useCallback, useMemo, useState, type ReactNode } from 'react';
import { collection, doc, limit, orderBy, query } from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';
import { getFunctions } from 'firebase/functions';
import { ArrowLeft, ChevronRight, Layers3, PlusCircle, Settings2, Swords, Trophy } from 'lucide-react';

import { useCollection, useDoc, useFirestore, useMemoFirebase } from '@/firebase';
import type { User } from '@/lib/types';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { useToast } from '@/hooks/use-toast';
import { useI18n } from '@/hooks/use-i18n';
import { cn } from '@/lib/utils';

type GameLobbyIndexDoc = {
  id?: string;
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
  totalGames?: number;
  finishedGameIds?: string[];
  gameIds?: string[];
  createdAt?: string;
};

type TournamentGameDoc = {
  id?: string;
  gameId?: string;
  status?: string;
  playerIds?: string[];
  placements?: { uids: string[] }[];
  loserUid?: string | null;
  createdAt?: string;
};

type DurakSettings = {
  maxPlayers: number;
  deckSize: 36 | 52;
  mode: 'podkidnoy' | 'perevodnoy';
  withJokers: boolean;
  turnTimeSec: number | null;
  throwInPolicy: 'all' | 'neighbors';
  shulerEnabled: boolean;
};

const defaultDurakSettings: DurakSettings = {
  maxPlayers: 6,
  deckSize: 36,
  mode: 'podkidnoy',
  withJokers: false,
  turnTimeSec: null,
  throwInPolicy: 'all',
  shulerEnabled: false,
};

function nameOfUid(uid: string, allUsers: User[]) {
  return allUsers.find((u) => u.id === uid)?.name ?? uid;
}

export function ConversationGamesPanel({
  conversationId,
  allUsers,
  isGroup,
  onCreatedGameLobby,
}: {
  conversationId: string;
  allUsers: User[];
  isGroup: boolean;
  onCreatedGameLobby?: (gameId: string) => void;
}) {
  const firestore = useFirestore();
  const { toast } = useToast();
  const { t } = useI18n();
  const [selectedGame, setSelectedGame] = useState<'durak' | null>(null);
  const [selectedTournamentId, setSelectedTournamentId] = useState<string | null>(null);
  const [showSingleSettings, setShowSingleSettings] = useState(false);
  const [showTournamentSettings, setShowTournamentSettings] = useState(false);
  const [tournamentTotalGames, setTournamentTotalGames] = useState<number>(3);
  const [settings, setSettings] = useState<DurakSettings>(() => ({
    ...defaultDurakSettings,
    maxPlayers: isGroup ? 6 : 2,
  }));
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
        ? query(collection(firestore, `tournaments/${selectedTournamentId}/games`), orderBy('createdAt', 'desc'), limit(30))
        : null,
    [firestore, selectedTournamentId]
  );
  const { data: tournamentGamesRows } = useCollection<TournamentGameDoc>(gamesQuery);
  const tournamentGames = useMemo(() => tournamentGamesRows ?? [], [tournamentGamesRows]);

  const createSingleLobby = useCallback(async () => {
    if (!firestore) return;
    setBusy('createLobby');
    try {
      const fn = httpsCallable(getFunctions(firestore.app, 'us-central1'), 'createGameLobby');
      const res = await fn({
        conversationId,
        gameKey: 'durak',
        settings: { ...settings, maxPlayers: isGroup ? settings.maxPlayers : 2 },
      });
      const gameId = (res.data as any)?.gameId as string | undefined;
      if (gameId) {
        toast({ title: t('gamesPanel.gameCreated') });
        onCreatedGameLobby?.(gameId);
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : t('gamesPanel.createFailed');
      toast({ variant: 'destructive', title: t('gamesPanel.error'), description: msg });
    } finally {
      setBusy(null);
    }
  }, [conversationId, firestore, isGroup, onCreatedGameLobby, settings, t, toast]);

  const createTournament = useCallback(async () => {
    if (!firestore) return;
    setBusy('createTournament');
    try {
      const fn = httpsCallable(getFunctions(firestore.app, 'us-central1'), 'createDurakTournament');
      const res = await fn({ conversationId, totalGames: tournamentTotalGames });
      const tid = (res.data as any)?.tournamentId as string | undefined;
      if (tid) setSelectedTournamentId(tid);
      toast({ title: t('gamesPanel.tournamentCreated') });
      setShowTournamentSettings(false);
    } catch (e) {
      const msg = e instanceof Error ? e.message : t('gamesPanel.createFailed');
      toast({ variant: 'destructive', title: t('gamesPanel.error'), description: msg });
    } finally {
      setBusy(null);
    }
  }, [conversationId, firestore, toast, tournamentTotalGames]);

  const createTournamentGame = useCallback(async () => {
    if (!firestore || !selectedTournamentId) return;
    setBusy('createTournamentGame');
    try {
      const fn = httpsCallable(getFunctions(firestore.app, 'us-central1'), 'createTournamentGameLobby');
      const res = await fn({
        tournamentId: selectedTournamentId,
        settings: { ...settings, maxPlayers: isGroup ? settings.maxPlayers : 2 },
      });
      const gameId = (res.data as any)?.gameId as string | undefined;
      if (gameId) {
        toast({ title: t('gamesPanel.roundCreated') });
        onCreatedGameLobby?.(gameId);
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : t('gamesPanel.createFailed');
      toast({ variant: 'destructive', title: t('gamesPanel.error'), description: msg });
    } finally {
      setBusy(null);
    }
  }, [firestore, isGroup, onCreatedGameLobby, selectedTournamentId, settings, t, toast]);

  const finishDurakGame = useCallback(
    async (gameId: string) => {
      if (!firestore || !gameId) return;
      setBusy(`finish:${gameId}`);
      try {
        const fn = httpsCallable(getFunctions(firestore.app, 'us-central1'), 'makeDurakMove');
        await fn({
          gameId,
          clientMoveId: `${Date.now()}_${Math.random().toString(16).slice(2)}`,
          actionType: 'surrender',
          payload: null,
        });
        toast({ title: t('gamesPanel.gameFinished') });
      } catch (e) {
        const msg = e instanceof Error ? e.message : t('gamesPanel.finishFailed');
        toast({ variant: 'destructive', title: t('gamesPanel.error'), description: msg });
      } finally {
        setBusy(null);
      }
    },
    [firestore, toast]
  );

  if (!selectedGame) {
    return (
      <div className="space-y-3">
        <button
          type="button"
          onClick={() => setSelectedGame('durak')}
          className="flex w-full items-center gap-3 rounded-2xl border border-border/70 bg-card/70 p-4 text-left transition hover:bg-card"
        >
          <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-emerald-500/12 text-emerald-500">
            <Swords className="h-5 w-5" />
          </div>
          <div className="min-w-0 flex-1">
            <div className="text-sm font-bold text-foreground">{t('gamesPanel.durakTitle')}</div>
            <div className="text-xs text-muted-foreground">{t('gamesPanel.durakSubtitle')}</div>
          </div>
          <ChevronRight className="h-5 w-5 text-muted-foreground" />
        </button>
      </div>
    );
  }

  if (selectedTournamentId) {
    const tourney = selectedTournament;
    const pointsByUid = tourney?.pointsByUid ?? {};
    const playedByUid = tourney?.gamesPlayedByUid ?? {};
    const standingsUids = Array.from(new Set([...Object.keys(pointsByUid), ...Object.keys(playedByUid)].filter(Boolean)));
    standingsUids.sort((a, b) => {
      const pa = pointsByUid[a] ?? 0;
      const pb = pointsByUid[b] ?? 0;
      if (pa !== pb) return pb - pa;
      return (playedByUid[b] ?? 0) - (playedByUid[a] ?? 0);
    });

    return (
      <div className="space-y-4">
        <div className="flex items-center justify-between gap-2">
          <Button variant="ghost" size="sm" onClick={() => setSelectedTournamentId(null)} className="gap-2">
            <ArrowLeft className="h-4 w-4" />
            {t('gamesPanel.back')}
          </Button>
          <Button
            onClick={createTournamentGame}
            disabled={
              busy != null ||
              tourney?.status === 'finished' ||
              (typeof tourney?.totalGames === 'number' &&
                tourney.totalGames > 0 &&
                (tourney?.gameIds?.length ?? 0) >= tourney.totalGames)
            }
            className="gap-2"
          >
            <PlusCircle className="h-4 w-4" />
            {t('gamesPanel.newGame')}
          </Button>
        </div>

        <div className="rounded-2xl border border-border/70 bg-card/70 p-4">
          <div className="mb-1 flex items-center gap-2">
            <Trophy className="h-5 w-5 text-amber-500" />
            <div className="text-sm font-bold">{selectedTournament?.title ?? t('gamesPanel.tournament')}</div>
            <Badge variant="secondary" className="ml-auto">{tourney?.status ?? 'active'}</Badge>
          </div>
          {typeof tourney?.totalGames === 'number' && tourney.totalGames > 0 ? (
            <div className="mt-1 text-xs text-muted-foreground">
              {t('gamesPanel.playedNofM', { n: tourney?.finishedGameIds?.length ?? 0, m: tourney.totalGames })}
            </div>
          ) : null}
          <div className="mt-3 space-y-2">
            {standingsUids.length === 0 ? (
              <div className="text-xs text-muted-foreground">{t('gamesPanel.noResults')}</div>
            ) : (
              standingsUids.map((uid) => (
                <div key={uid} className="flex items-center justify-between gap-2 text-sm">
                  <div className="min-w-0 truncate">{nameOfUid(uid, allUsers)}</div>
                  <div className="shrink-0 text-muted-foreground">{t('gamesPanel.ptsGames', { pts: pointsByUid[uid] ?? 0, games: playedByUid[uid] ?? 0 })}</div>
                </div>
              ))
            )}
          </div>
        </div>

        <div className="space-y-2">
          <div className="text-xs font-bold uppercase text-muted-foreground">{t('gamesPanel.rounds')}</div>
          {tournamentGames.length === 0 ? (
            <div className="text-xs text-muted-foreground">{t('gamesPanel.noRounds')}</div>
          ) : (
            tournamentGames.map((g, idx) => {
              const status = g.status ?? '';
              const players = (g.playerIds ?? []).map((u) => nameOfUid(u, allUsers)).join(', ');
              const loser = g.loserUid ? nameOfUid(g.loserUid, allUsers) : '';
              return (
                <button
                  key={`${g.gameId ?? g.id ?? idx}-${status}`}
                  type="button"
                  onClick={() => onCreatedGameLobby?.((g.gameId ?? g.id) as string)}
                  className="w-full rounded-2xl border border-border/70 bg-card/70 p-4 text-left transition hover:bg-card"
                >
                  <div className="flex items-center gap-2">
                    <Swords className="h-4 w-4 text-emerald-500" />
                    <div className="text-sm font-bold">{t('gamesPanel.durakTitle')}</div>
                    <Badge variant="secondary" className="ml-auto">{status}</Badge>
                  </div>
                  {players && <div className="mt-2 text-xs text-muted-foreground">{t('gamesPanel.players')} {players}</div>}
                  {status === 'finished' && (
                    <div className="mt-1 text-xs text-muted-foreground">{t('gamesPanel.result')} {loser ? t('gamesPanel.loserResult', { name: loser }) : t('gamesPanel.draw')}</div>
                  )}
                </button>
              );
            })
          )}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <Button variant="ghost" size="sm" onClick={() => setSelectedGame(null)} className="gap-2">
        <ArrowLeft className="h-4 w-4" />
        {t('gamesPanel.toGames')}
      </Button>

      <div className="rounded-2xl border border-border/70 bg-card/70 p-4">
        <div className="mb-3 flex items-center gap-2">
          <Swords className="h-5 w-5 text-emerald-500" />
          <div className="text-sm font-bold">{t('gamesPanel.durakTitle')}</div>
        </div>
        <div className="grid gap-2">
          <Button onClick={() => setShowSingleSettings((v) => !v)} className="justify-start gap-2">
            <Settings2 className="h-4 w-4" />
            {t('gamesPanel.singleGame')}
          </Button>
          <Button variant="outline" onClick={() => setShowTournamentSettings((v) => !v)} className="justify-start gap-2">
            <Trophy className="h-4 w-4" />
            {t('gamesPanel.tournament')}
          </Button>
        </div>
        {showTournamentSettings ? (
          <div className="mt-4 space-y-3 rounded-2xl border border-border/60 bg-background/45 p-3">
            <label className="block text-xs font-bold uppercase text-muted-foreground">
              {t('gamesPanel.gamesInTournament')}
            </label>
            <div className="flex items-center gap-2">
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={() => setTournamentTotalGames((n) => Math.max(1, n - 1))}
                disabled={busy != null || tournamentTotalGames <= 1}
              >
                −
              </Button>
              <input
                type="number"
                min={1}
                max={50}
                value={tournamentTotalGames}
                onChange={(e) => {
                  const n = Math.floor(Number(e.target.value));
                  if (Number.isFinite(n)) setTournamentTotalGames(Math.min(50, Math.max(1, n)));
                }}
                className="w-20 rounded-md border border-border/60 bg-background/60 px-3 py-1 text-center text-sm"
              />
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={() => setTournamentTotalGames((n) => Math.min(50, n + 1))}
                disabled={busy != null || tournamentTotalGames >= 50}
              >
                +
              </Button>
              <span className="text-xs text-muted-foreground">{t('gamesPanel.nGames')}</span>
            </div>
            <Button onClick={createTournament} disabled={busy != null} className="w-full gap-2">
              <Trophy className="h-4 w-4" />
              {t('gamesPanel.createTournament')}
            </Button>
          </div>
        ) : null}
        {showSingleSettings ? (
          <DurakSettingsForm
            value={settings}
            isGroup={isGroup}
            disabled={busy != null}
            onChange={setSettings}
            onCreate={createSingleLobby}
          />
        ) : null}
      </div>

      <ListSection title={t('gamesPanel.activeLobbies')} empty={t('gamesPanel.noActiveLobbies')}>
        {durakLobbies.map((l, idx) => {
          const gameId = (l.gameId ?? l.id ?? '') || '';
          const status = String(l.status ?? '');
          return (
            <div
              key={`${gameId || idx}-${status}`}
              className="flex w-full items-center gap-3 rounded-2xl border border-border/70 bg-card/70 p-4"
            >
              <button
                type="button"
                disabled={!gameId}
                onClick={() => gameId && onCreatedGameLobby?.(gameId)}
                className="flex min-w-0 flex-1 items-center gap-3 text-left disabled:opacity-60"
              >
                <Swords className="h-5 w-5 text-emerald-500" />
                <div className="min-w-0 flex-1">
                  <div className="truncate text-sm font-bold">{t('gamesPanel.durakTitle')}</div>
                  <div className="text-xs text-muted-foreground">{status} · {l.playerCount ?? 0}/{l.maxPlayers ?? 0}</div>
                </div>
                <ChevronRight className="h-5 w-5 text-muted-foreground" />
              </button>
              <Button
                variant="outline"
                size="sm"
                disabled={!gameId || busy === `finish:${gameId}`}
                onClick={() => gameId && void finishDurakGame(gameId)}
                className="shrink-0"
              >
                {t('gamesPanel.finish')}
              </Button>
            </div>
          );
        })}
      </ListSection>

      <ListSection title={t('gamesPanel.tournaments')} empty={isLoadingTournaments && !tournamentIndexRows ? t('gamesPanel.loading') : t('gamesPanel.noTournaments')}>
        {tournaments.map((row: any) => (
          <button
            key={row.tournamentId ?? row.id}
            type="button"
            onClick={() => setSelectedTournamentId((row.tournamentId ?? row.id) as string)}
            className="flex w-full items-center gap-3 rounded-2xl border border-border/70 bg-card/70 p-4 text-left transition hover:bg-card"
          >
            <Trophy className="h-5 w-5 text-amber-500" />
            <div className="min-w-0 flex-1">
              <div className="truncate text-sm font-bold">{row.title ?? t('gamesPanel.tournament')}</div>
              <div className="text-xs text-muted-foreground">{row.status ?? 'active'}</div>
            </div>
            <ChevronRight className="h-5 w-5 text-muted-foreground" />
          </button>
        ))}
      </ListSection>
    </div>
  );
}

function ListSection({ title, empty, children }: { title: string; empty: string; children: ReactNode }) {
  const list = Array.isArray(children) ? children.filter(Boolean) : children;
  const isEmpty = Array.isArray(list) ? list.length === 0 : !list;
  return (
    <div className="space-y-2">
      <div className="text-xs font-bold uppercase text-muted-foreground">{title}</div>
      {isEmpty ? <div className="text-xs text-muted-foreground">{empty}</div> : <div className="space-y-2">{list}</div>}
    </div>
  );
}

function DurakSettingsForm({
  value,
  isGroup,
  disabled,
  onChange,
  onCreate,
}: {
  value: DurakSettings;
  isGroup: boolean;
  disabled: boolean;
  onChange: (v: DurakSettings) => void;
  onCreate: () => void;
}) {
  const { t } = useI18n();
  const update = (patch: Partial<DurakSettings>) => onChange({ ...value, ...patch, maxPlayers: isGroup ? (patch.maxPlayers ?? value.maxPlayers) : 2 });
  return (
    <div className="mt-4 space-y-3 rounded-2xl border border-border/60 bg-background/45 p-3">
      <Segmented
        label={t('gamesPanel.mode')}
        value={value.mode}
        options={[
          ['podkidnoy', t('gamesPanel.throwIn')],
          ['perevodnoy', t('gamesPanel.transfer')],
        ]}
        onChange={(mode) => update({ mode: mode as DurakSettings['mode'] })}
      />
      <Segmented
        label={t('gamesPanel.deck')}
        value={String(value.deckSize)}
        options={[
          ['36', '36'],
          ['52', '52'],
        ]}
        onChange={(deckSize) => update({ deckSize: Number(deckSize) === 52 ? 52 : 36 })}
      />
      <Segmented
        label={t('gamesPanel.playersLabel')}
        value={String(isGroup ? value.maxPlayers : 2)}
        disabled={!isGroup}
        options={['2', '3', '4', '5', '6'].map((n) => [n, n] as [string, string])}
        onChange={(maxPlayers) => update({ maxPlayers: Number(maxPlayers) })}
      />
      <Segmented
        label={t('gamesPanel.tossers')}
        value={value.throwInPolicy}
        options={[
          ['all', t('gamesPanel.all')],
          ['neighbors', t('gamesPanel.neighbors')],
        ]}
        onChange={(throwInPolicy) => update({ throwInPolicy: throwInPolicy as DurakSettings['throwInPolicy'] })}
      />
      <Segmented
        label={t('gamesPanel.timer')}
        value={String(value.turnTimeSec ?? 'off')}
        options={[
          ['off', t('gamesPanel.timerOff')],
          ['30', '30s'],
          ['60', '60s'],
          ['90', '90s'],
        ]}
        onChange={(turnTimeSec) => update({ turnTimeSec: turnTimeSec === 'off' ? null : Number(turnTimeSec) })}
      />
      <div className="grid grid-cols-2 gap-2">
        <ToggleTile active={value.withJokers} onClick={() => update({ withJokers: !value.withJokers })}>
          {t('gamesPanel.jokers')}
        </ToggleTile>
        <ToggleTile active={value.shulerEnabled} onClick={() => update({ shulerEnabled: !value.shulerEnabled })}>
          {t('gamesPanel.cheater')}
        </ToggleTile>
      </div>
      <Button onClick={onCreate} disabled={disabled} className="w-full gap-2">
        <PlusCircle className="h-4 w-4" />
        {t('gamesPanel.createGame')}
      </Button>
    </div>
  );
}

function Segmented({
  label,
  value,
  options,
  disabled = false,
  onChange,
}: {
  label: string;
  value: string;
  options: [string, string][];
  disabled?: boolean;
  onChange: (v: string) => void;
}) {
  return (
    <div>
      <div className="mb-1 text-[11px] font-bold uppercase text-muted-foreground">{label}</div>
      <div className="flex flex-wrap gap-1">
        {options.map(([id, text]) => (
          <button
            key={id}
            type="button"
            disabled={disabled}
            onClick={() => onChange(id)}
            className={cn(
              'rounded-xl border px-3 py-2 text-xs font-bold transition',
              value === id ? 'border-primary bg-primary text-primary-foreground' : 'border-border bg-background/55 text-foreground hover:bg-muted',
              disabled && 'opacity-50'
            )}
          >
            {text}
          </button>
        ))}
      </div>
    </div>
  );
}

function ToggleTile({ active, onClick, children }: { active: boolean; onClick: () => void; children: ReactNode }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        'flex items-center justify-center gap-2 rounded-xl border px-3 py-2 text-xs font-bold transition',
        active ? 'border-emerald-500 bg-emerald-500/12 text-emerald-600' : 'border-border bg-background/55'
      )}
    >
      <Layers3 className="h-4 w-4" />
      {children}
    </button>
  );
}
