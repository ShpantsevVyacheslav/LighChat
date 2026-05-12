'use client';

import React, { useEffect, useState } from 'react';
import { doc, getDoc } from 'firebase/firestore';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { useFirestore } from '@/firebase';
import { useRouter } from 'next/navigation';
import type { User } from '@/lib/types';
import { isAccountBlocked } from '@/lib/account-block-utils';
import { Loader2, Ban, Edit, Mail, Phone, Shield, ShieldOff } from 'lucide-react';
import { logger } from '@/lib/logger';

/**
 * Read-only профиль пользователя для админа: открывается из любых
 * мест с user.id (модерация — клик по имени, users-таблица — клик
 * по строке). Quick-actions «Редактировать» и «Список пользователей»
 * ведут на существующие маршруты.
 */
type Props = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  userId: string | null;
};

function formatDate(iso: string | undefined | null): string {
  if (!iso) return '—';
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return '—';
  return d.toLocaleString('ru-RU', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

export function AdminUserProfileDialog({ open, onOpenChange, userId }: Props) {
  const firestore = useFirestore();
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!open || !userId || !firestore) {
      setUser(null);
      setError(null);
      return;
    }
    let cancelled = false;
    setLoading(true);
    setError(null);
    (async () => {
      try {
        const snap = await getDoc(doc(firestore, 'users', userId));
        if (cancelled) return;
        if (!snap.exists()) {
          setError('Пользователь не найден');
          setUser(null);
          return;
        }
        setUser({ id: snap.id, ...(snap.data() as Omit<User, 'id'>) });
      } catch (e) {
        logger.error('admin-user-profile', 'load profile failed', e);
        if (!cancelled) setError('Не удалось загрузить профиль');
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [firestore, open, userId]);

  const blocked = user ? isAccountBlocked(user) : false;
  const isDeleted = user?.deletedAt != null;
  const initials = (user?.name ?? '')
    .split(' ')
    .map((p) => p[0])
    .filter(Boolean)
    .slice(0, 2)
    .join('')
    .toUpperCase();

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="rounded-3xl max-w-md">
        <DialogHeader>
          <DialogTitle>Профиль пользователя</DialogTitle>
          <DialogDescription>Сведения из коллекции users.</DialogDescription>
        </DialogHeader>

        {loading && (
          <div className="flex justify-center py-8">
            <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
          </div>
        )}

        {error && !loading && (
          <p className="text-sm text-destructive text-center py-6">{error}</p>
        )}

        {user && !loading && (
          <div className="space-y-4">
            <div className="flex items-center gap-3">
              <Avatar className="h-16 w-16">
                {user.avatar ? <AvatarImage src={user.avatarThumb || user.avatar} alt={user.name} /> : null}
                <AvatarFallback>{initials || '?'}</AvatarFallback>
              </Avatar>
              <div className="min-w-0">
                <p className="text-lg font-semibold truncate">{user.name || '(без имени)'}</p>
                <p className="text-sm text-muted-foreground truncate">
                  {user.username ? `@${user.username}` : user.id}
                </p>
                <div className="flex gap-1 mt-1 flex-wrap">
                  {user.role === 'admin' && (
                    <Badge variant="secondary" className="text-[10px]">
                      <Shield className="h-3 w-3 mr-1" /> Администратор
                    </Badge>
                  )}
                  {blocked && (
                    <Badge variant="destructive" className="text-[10px]">
                      <Ban className="h-3 w-3 mr-1" /> Заблокирован
                    </Badge>
                  )}
                  {isDeleted && (
                    <Badge variant="secondary" className="text-[10px]">Удалён</Badge>
                  )}
                  {user.online && !blocked && !isDeleted && (
                    <Badge variant="default" className="text-[10px] bg-emerald-500/15 text-emerald-700 dark:text-emerald-400">
                      онлайн
                    </Badge>
                  )}
                </div>
              </div>
            </div>

            <div className="space-y-1.5 text-sm">
              {user.email && (
                <div className="flex items-center gap-2">
                  <Mail className="h-3.5 w-3.5 text-muted-foreground" />
                  <span className="truncate">{user.email}</span>
                  {user.pendingEmail && (
                    <Badge variant="outline" className="text-[10px]">
                      ожидает: {user.pendingEmail}
                    </Badge>
                  )}
                </div>
              )}
              {user.phone && (
                <div className="flex items-center gap-2">
                  <Phone className="h-3.5 w-3.5 text-muted-foreground" />
                  <span>{user.phone}</span>
                </div>
              )}
              {user.bio && (
                <p className="text-muted-foreground text-xs italic">«{user.bio}»</p>
              )}
            </div>

            <div className="grid grid-cols-2 gap-3 text-xs">
              <div className="rounded-xl border p-2.5">
                <p className="text-muted-foreground">Создан</p>
                <p className="font-medium">{formatDate(user.createdAt)}</p>
              </div>
              <div className="rounded-xl border p-2.5">
                <p className="text-muted-foreground">Последний визит</p>
                <p className="font-medium">{formatDate(user.lastSeen)}</p>
              </div>
            </div>

            {blocked && user.accountBlock && (
              <div className="rounded-xl border border-destructive/40 bg-destructive/5 p-3 text-xs space-y-1">
                <p className="font-semibold text-destructive flex items-center gap-1">
                  <Ban className="h-3 w-3" /> Аккаунт заблокирован
                </p>
                {user.accountBlock.reason && (
                  <p><span className="text-muted-foreground">Причина:</span> {user.accountBlock.reason}</p>
                )}
                <p>
                  <span className="text-muted-foreground">До:</span>{' '}
                  {user.accountBlock.until ? formatDate(user.accountBlock.until) : 'бессрочно'}
                </p>
                <p>
                  <span className="text-muted-foreground">Заблокирован:</span>{' '}
                  {formatDate(user.accountBlock.blockedAt)}
                </p>
              </div>
            )}

            <div className="flex flex-wrap gap-2 pt-1">
              <Button
                size="sm"
                variant="outline"
                className="rounded-xl"
                onClick={() => {
                  onOpenChange(false);
                  router.push(`/dashboard/users/${user.id}/edit`);
                }}
              >
                <Edit className="h-3.5 w-3.5 mr-1" /> Редактировать
              </Button>
              {blocked ? (
                <Badge variant="outline" className="px-2 py-1 text-xs">
                  <ShieldOff className="h-3 w-3 mr-1" /> разблокировать — в таблице
                </Badge>
              ) : null}
            </div>

            <p className="text-[10px] text-muted-foreground font-mono">{user.id}</p>
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}
