'use client';

import { useState, useCallback } from 'react';
import { Database, Loader2 } from 'lucide-react';
import { useFirebaseApp } from '@/firebase';
import { getFunctions, httpsCallable, type HttpsCallableResult } from 'firebase/functions';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { useToast } from '@/hooks/use-toast';

type BackfillResponse = {
  ok: boolean;
  syncedConversations: number;
  scanned: number;
  nextCursor: string | null;
  done: boolean;
};

/**
 * Вызов Cloud Function `backfillConversationMembers`: синхронизация
 * `conversations/{id}/members/{uid}` с participantIds для существующих чатов.
 * Только для пользователя с role === 'admin' (проверка на сервере).
 */
export function AdminBackfillConversationMembersPanel() {
  const firebaseApp = useFirebaseApp();
  const { toast } = useToast();
  const [isRunning, setIsRunning] = useState(false);
  const [lastLog, setLastLog] = useState<string | null>(null);

  const runBackfill = useCallback(async () => {
    if (!firebaseApp) {
      toast({ variant: 'destructive', title: 'Firebase не готов', description: 'Перезагрузите страницу.' });
      return;
    }

    setIsRunning(true);
    setLastLog(null);

    const fn = httpsCallable<{ cursor?: string | null }, BackfillResponse>(
      getFunctions(firebaseApp, 'us-central1'),
      'backfillConversationMembers',
    );

    let cursor: string | null = null;
    let totalSynced = 0;
    let batches = 0;

    try {
      for (;;) {
        const res: HttpsCallableResult<BackfillResponse> = await fn({ cursor });
        const d = res.data;
        batches += 1;
        totalSynced += d.syncedConversations ?? 0;
        setLastLog(
          `Пакет ${batches}: обработано чатов с members ${d.syncedConversations ?? 0}, просмотрено документов ${d.scanned ?? 0}, done=${d.done}`,
        );
        console.info('[backfillConversationMembers]', d);

        if (d.done) break;
        cursor = d.nextCursor;
        if (cursor == null) break;
      }

      toast({
        title: 'Готово',
        description: `Синхронизация members завершена. Всего пакетов: ${batches}, чатов с обновлённым индексом (сумма по пакетам): ${totalSynced}.`,
      });
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      console.error('[backfillConversationMembers]', e);
      toast({
        variant: 'destructive',
        title: 'Ошибка backfill',
        description: msg,
      });
    } finally {
      setIsRunning(false);
    }
  }, [firebaseApp, toast]);

  return (
    <Card className="rounded-3xl">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-lg">
          <Database className="h-5 w-5 text-primary" />
          Индекс участников чатов (Firestore)
        </CardTitle>
        <CardDescription>
          Однократно или после смены правил: создаёт документы{' '}
          <code className="text-xs">conversations/&lt;id&gt;/members/&lt;uid&gt;</code> по полю{' '}
          <code className="text-xs">participantIds</code> для всех чатов (пакетами). Нужны задеплоенные
          Cloud Functions и роль администратора.
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-3">
        <Button
          type="button"
          className="rounded-full"
          disabled={isRunning || !firebaseApp}
          onClick={() => void runBackfill()}
        >
          {isRunning ? (
            <>
              <Loader2 className="mr-2 h-4 w-4 animate-spin" aria-hidden />
              Синхронизация…
            </>
          ) : (
            'Заполнить members для всех чатов'
          )}
        </Button>
        {lastLog ? <p className="text-xs text-muted-foreground font-mono break-all">{lastLog}</p> : null}
      </CardContent>
    </Card>
  );
}
