'use client';

import { useState, useCallback } from 'react';
import { Database, Loader2 } from 'lucide-react';
import { useFirebaseApp } from '@/firebase';
import { getFunctions, httpsCallable, type HttpsCallableResult } from 'firebase/functions';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { useToast } from '@/hooks/use-toast';
import { useI18n } from '@/hooks/use-i18n';

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
  const { t } = useI18n();
  const firebaseApp = useFirebaseApp();
  const { toast } = useToast();
  const [isRunning, setIsRunning] = useState(false);
  const [lastLog, setLastLog] = useState<string | null>(null);

  const runBackfill = useCallback(async () => {
    if (!firebaseApp) {
      toast({ variant: 'destructive', title: t('admin.backfill.firebaseNotReady'), description: t('admin.backfill.firebaseNotReadyDesc') });
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
          t('admin.backfill.batchLog').replace('{batch}', String(batches)).replace('{synced}', String(d.syncedConversations ?? 0)).replace('{scanned}', String(d.scanned ?? 0)).replace('{done}', String(d.done)),
        );
        console.info('[backfillConversationMembers]', d);

        if (d.done) break;
        cursor = d.nextCursor;
        if (cursor == null) break;
      }

      toast({
        title: t('admin.backfill.done'),
        description: t('admin.backfill.doneDesc').replace('{batches}', String(batches)).replace('{synced}', String(totalSynced)),
      });
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      console.error('[backfillConversationMembers]', e);
      toast({
        variant: 'destructive',
        title: t('admin.backfill.backfillError'),
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
          {t('admin.backfill.title')}
        </CardTitle>
        <CardDescription>
          {t('admin.backfill.description')}
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
              {t('admin.backfill.syncing')}
            </>
          ) : (
            t('admin.backfill.runBtn')
          )}
        </Button>
        {lastLog ? <p className="text-xs text-muted-foreground font-mono break-all">{lastLog}</p> : null}
      </CardContent>
    </Card>
  );
}
