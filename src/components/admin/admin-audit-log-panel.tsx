'use client';

import React, { useCallback, useEffect, useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { ScrollText, Loader2, ChevronLeft, ChevronRight } from 'lucide-react';
import { useAuth as useFirebaseAuth } from '@/firebase';
import { fetchAuditLogAction } from '@/actions/audit-log-actions';
import type { AuditAction, AuditLogEntry } from '@/lib/types';

const ACTION_LABELS: Record<AuditAction, string> = {
  'user.create': 'Создание пользователя',
  'user.delete': 'Удаление пользователя',
  'user.block': 'Блокировка',
  'user.unblock': 'Разблокировка',
  'user.role.change': 'Смена роли',
  'user.password.reset': 'Сброс пароля',
  'user.update': 'Обновление профиля',
  'storage.settings.update': 'Настройки хранилища',
  'storage.quota.user': 'Квота пользователя',
  'storage.quota.conversation': 'Квота чата',
  'notification.broadcast': 'Рассылка уведомлений',
  'backfill.run': 'Синхронизация участников',
  'moderation.hide_message': 'Скрытие сообщения',
  'moderation.unhide_message': 'Восстановление сообщения',
  'moderation.review_report': 'Рассмотрение жалобы',
  'ticket.status_change': 'Статус обращения',
  'feature_flag.update': 'Feature flag',
  'announcement.create': 'Создание объявления',
  'announcement.update': 'Обновление объявления',
  'session.terminate': 'Завершение сессии',
};

const ACTION_COLORS: Record<string, string> = {
  'user.create': 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400',
  'user.delete': 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400',
  'user.block': 'bg-orange-100 text-orange-800 dark:bg-orange-900/30 dark:text-orange-400',
  'user.unblock': 'bg-teal-100 text-teal-800 dark:bg-teal-900/30 dark:text-teal-400',
  'user.role.change': 'bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-400',
  'user.password.reset': 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400',
  'notification.broadcast': 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400',
};

export function AdminAuditLogPanel() {
  const firebaseAuth = useFirebaseAuth();
  const [entries, setEntries] = useState<AuditLogEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [hasMore, setHasMore] = useState(false);
  const [actionFilter, setActionFilter] = useState<AuditAction | 'all'>('all');
  const [cursors, setCursors] = useState<string[]>([]);
  const [page, setPage] = useState(0);

  const load = useCallback(async (startAfter?: string, filter?: AuditAction | 'all') => {
    const token = await firebaseAuth?.currentUser?.getIdToken();
    if (!token) return;
    setLoading(true);
    const res = await fetchAuditLogAction({
      idToken: token,
      limit: 20,
      startAfter,
      actionFilter: filter && filter !== 'all' ? filter : undefined,
    });
    if (res.ok) {
      setEntries(res.entries);
      setHasMore(res.hasMore);
    }
    setLoading(false);
  }, [firebaseAuth]);

  useEffect(() => {
    load(undefined, actionFilter);
    setCursors([]);
    setPage(0);
  }, [load, actionFilter]);

  const goNext = () => {
    const last = entries[entries.length - 1];
    if (!last) return;
    setCursors((prev) => [...prev, last.createdAt]);
    setPage((p) => p + 1);
    load(last.createdAt, actionFilter);
  };

  const goPrev = () => {
    if (page <= 0) return;
    const newCursors = cursors.slice(0, -1);
    setCursors(newCursors);
    setPage((p) => p - 1);
    load(newCursors[newCursors.length - 1], actionFilter);
  };

  const formatDate = (iso: string) => {
    const d = new Date(iso);
    return d.toLocaleString('ru-RU', { day: '2-digit', month: '2-digit', year: '2-digit', hour: '2-digit', minute: '2-digit' });
  };

  return (
    <Card className="rounded-3xl">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-lg">
          <ScrollText className="h-5 w-5 text-primary" />
          Журнал действий
        </CardTitle>
        <CardDescription>История административных операций на платформе.</CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="flex items-center gap-3">
          <Select
            value={actionFilter}
            onValueChange={(v) => setActionFilter(v as AuditAction | 'all')}
          >
            <SelectTrigger className="w-[240px] rounded-xl">
              <SelectValue placeholder="Все действия" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Все действия</SelectItem>
              {(Object.keys(ACTION_LABELS) as AuditAction[]).map((key) => (
                <SelectItem key={key} value={key}>
                  {ACTION_LABELS[key]}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        {loading ? (
          <div className="flex justify-center py-8">
            <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
          </div>
        ) : entries.length === 0 ? (
          <p className="text-center text-sm text-muted-foreground py-8">Записей пока нет.</p>
        ) : (
          <>
            <div className="rounded-xl border overflow-hidden">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="w-[140px]">Время</TableHead>
                    <TableHead className="w-[140px]">Кто</TableHead>
                    <TableHead>Действие</TableHead>
                    <TableHead>Цель</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {entries.map((entry) => (
                    <TableRow key={entry.id}>
                      <TableCell className="text-xs text-muted-foreground whitespace-nowrap">
                        {formatDate(entry.createdAt)}
                      </TableCell>
                      <TableCell className="text-sm font-medium">{entry.actorName}</TableCell>
                      <TableCell>
                        <Badge
                          variant="secondary"
                          className={`text-xs ${ACTION_COLORS[entry.action] ?? ''}`}
                        >
                          {ACTION_LABELS[entry.action] ?? entry.action}
                        </Badge>
                      </TableCell>
                      <TableCell className="text-sm text-muted-foreground">
                        {entry.target.name || entry.target.id}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>

            <div className="flex items-center justify-between">
              <Button
                variant="outline"
                size="sm"
                className="rounded-xl"
                onClick={goPrev}
                disabled={page === 0}
              >
                <ChevronLeft className="h-4 w-4 mr-1" /> Назад
              </Button>
              <span className="text-xs text-muted-foreground">Стр. {page + 1}</span>
              <Button
                variant="outline"
                size="sm"
                className="rounded-xl"
                onClick={goNext}
                disabled={!hasMore}
              >
                Далее <ChevronRight className="h-4 w-4 ml-1" />
              </Button>
            </div>
          </>
        )}
      </CardContent>
    </Card>
  );
}
