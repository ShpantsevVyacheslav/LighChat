'use client';

import { useMemo, useState, useCallback } from 'react';
import { collection, doc, updateDoc, arrayRemove } from 'firebase/firestore';
import { ArrowLeft, Loader2, UserX } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { useCollection, useDoc, useFirestore, useMemoFirebase } from '@/firebase';
import type { User } from '@/lib/types';
import { normalizeBlockedUserIds } from '@/lib/user-block-utils';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Button } from '@/components/ui/button';
import { useToast } from '@/hooks/use-toast';
import { userAvatarListUrl } from '@/lib/user-avatar-display';

type BlockedUsersPageClientProps = {
  currentUserId: string;
};

export function BlockedUsersPageClient({ currentUserId }: BlockedUsersPageClientProps) {
  const firestore = useFirestore();
  const router = useRouter();
  const { toast } = useToast();
  const [busyId, setBusyId] = useState<string | null>(null);

  const selfRef = useMemoFirebase(
    () => (firestore && currentUserId ? doc(firestore, 'users', currentUserId) : null),
    [firestore, currentUserId]
  );
  const { data: selfDoc, isLoading: selfLoading } = useDoc<User>(selfRef);

  const usersQuery = useMemoFirebase(
    () => (firestore ? collection(firestore, 'users') : null),
    [firestore]
  );
  const { data: allUsers, isLoading: usersLoading } = useCollection<User>(usersQuery);

  const blockedIds = useMemo(
    () => normalizeBlockedUserIds(selfDoc?.blockedUserIds),
    [selfDoc?.blockedUserIds]
  );

  const rows = useMemo(() => {
    const list = allUsers ?? [];
    return blockedIds.map((id) => {
      const u = list.find((x) => x.id === id);
      return { id, user: u ?? null };
    });
  }, [blockedIds, allUsers]);

  const handleUnblock = useCallback(
    async (targetId: string) => {
      if (!firestore || busyId) return;
      setBusyId(targetId);
      try {
        await updateDoc(doc(firestore, 'users', currentUserId), {
          blockedUserIds: arrayRemove(targetId),
        });
        toast({ title: 'Пользователь разблокирован' });
      } catch (e) {
        console.error('[BlockedUsersPageClient] unblock', e);
        toast({ variant: 'destructive', title: 'Не удалось разблокировать' });
      } finally {
        setBusyId(null);
      }
    },
    [firestore, busyId, currentUserId, toast]
  );

  const loading = selfLoading || usersLoading;

  return (
    <div className="mx-auto max-w-2xl space-y-6 pb-10">
      <div className="flex items-center gap-3">
        <Button type="button" variant="ghost" size="icon" className="shrink-0" onClick={() => router.back()}>
          <ArrowLeft className="h-5 w-5" />
          <span className="sr-only">Назад</span>
        </Button>
        <div className="min-w-0">
          <h1 className="text-2xl font-bold tracking-tight">Заблокированные</h1>
          <p className="text-sm text-muted-foreground">
            Учётные записи, с которыми недоступны личные сообщения и звонки, пока они в списке.
          </p>
        </div>
      </div>

      {loading ? (
        <div className="flex justify-center py-16 text-muted-foreground">
          <Loader2 className="h-8 w-8 animate-spin" aria-hidden />
        </div>
      ) : rows.length === 0 ? (
        <div className="rounded-2xl border border-dashed border-muted-foreground/30 p-8 text-center text-sm text-muted-foreground">
          Список пуст. Заблокировать пользователя можно из профиля чата (меню «Заблокировать»).
        </div>
      ) : (
        <ul className="divide-y rounded-2xl border bg-card">
          {rows.map(({ id, user }) => {
            const name = user?.name?.trim() || 'Пользователь';
            const avatarUrl = user ? userAvatarListUrl(user) : '';
            const initial = name.slice(0, 1).toUpperCase();
            return (
              <li key={id} className="flex items-center gap-3 p-4">
                <Avatar className="h-11 w-11 shrink-0">
                  {avatarUrl ? <AvatarImage src={avatarUrl} alt="" /> : null}
                  <AvatarFallback>{initial}</AvatarFallback>
                </Avatar>
                <div className="min-w-0 flex-1">
                  <p className="truncate font-medium">{name}</p>
                  {!user ? (
                    <p className="text-xs text-muted-foreground">Профиль недоступен для просмотра</p>
                  ) : null}
                </div>
                <Button
                  type="button"
                  variant="secondary"
                  size="sm"
                  className="shrink-0 gap-1.5"
                  disabled={busyId !== null}
                  onClick={() => void handleUnblock(id)}
                >
                  {busyId === id ? (
                    <Loader2 className="h-4 w-4 animate-spin" aria-hidden />
                  ) : (
                    <UserX className="h-4 w-4" aria-hidden />
                  )}
                  Разблокировать
                </Button>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
