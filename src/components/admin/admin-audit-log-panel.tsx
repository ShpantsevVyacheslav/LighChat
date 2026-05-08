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
import { useI18n } from '@/hooks/use-i18n';

/** i18n keys for ACTION_LABELS — translated at render via t() */
const ACTION_LABEL_KEYS: Record<AuditAction, string> = {
  'user.create': 'adminPage.auditActionLabels.user.create',
  'user.delete': 'adminPage.auditActionLabels.user.delete',
  'user.block': 'adminPage.auditActionLabels.user.block',
  'user.unblock': 'adminPage.auditActionLabels.user.unblock',
  'user.role.change': 'adminPage.auditActionLabels.user.role.change',
  'user.password.reset': 'adminPage.auditActionLabels.user.password.reset',
  'user.update': 'adminPage.auditActionLabels.user.update',
  'storage.settings.update': 'adminPage.auditActionLabels.storage.settings.update',
  'storage.quota.user': 'adminPage.auditActionLabels.storage.quota.user',
  'storage.quota.conversation': 'adminPage.auditActionLabels.storage.quota.conversation',
  'notification.broadcast': 'adminPage.auditActionLabels.notification.broadcast',
  'backfill.run': 'adminPage.auditActionLabels.backfill.run',
  'moderation.hide_message': 'adminPage.auditActionLabels.moderation.hide_message',
  'moderation.unhide_message': 'adminPage.auditActionLabels.moderation.unhide_message',
  'moderation.review_report': 'adminPage.auditActionLabels.moderation.review_report',
  'ticket.status_change': 'adminPage.auditActionLabels.ticket.status_change',
  'feature_flag.update': 'adminPage.auditActionLabels.feature_flag.update',
  'announcement.create': 'adminPage.auditActionLabels.announcement.create',
  'announcement.update': 'adminPage.auditActionLabels.announcement.update',
  'session.terminate': 'adminPage.auditActionLabels.session.terminate',
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
  const { t } = useI18n();
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
          {t('adminPage.audit.title')}
        </CardTitle>
        <CardDescription>{t('adminPage.audit.description')}</CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="flex items-center gap-3">
          <Select
            value={actionFilter}
            onValueChange={(v) => setActionFilter(v as AuditAction | 'all')}
          >
            <SelectTrigger className="w-[240px] rounded-xl">
              <SelectValue placeholder={t('adminPage.audit.allActions')} />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">{t('adminPage.audit.allActions')}</SelectItem>
              {(Object.keys(ACTION_LABEL_KEYS) as AuditAction[]).map((key) => (
                <SelectItem key={key} value={key}>
                  {t(ACTION_LABEL_KEYS[key])}
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
          <p className="text-center text-sm text-muted-foreground py-8">{t('adminPage.audit.noRecords')}</p>
        ) : (
          <>
            <div className="rounded-xl border overflow-hidden">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="w-[140px]">{t('adminPage.audit.colTime')}</TableHead>
                    <TableHead className="w-[140px]">{t('adminPage.audit.colWho')}</TableHead>
                    <TableHead>{t('adminPage.audit.colAction')}</TableHead>
                    <TableHead>{t('adminPage.audit.colTarget')}</TableHead>
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
                          {t(ACTION_LABEL_KEYS[entry.action]) || entry.action}
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
                <ChevronLeft className="h-4 w-4 mr-1" /> {t('adminPage.audit.prev')}
              </Button>
              <span className="text-xs text-muted-foreground">{t('adminPage.audit.pageN', { n: page + 1 })}</span>
              <Button
                variant="outline"
                size="sm"
                className="rounded-xl"
                onClick={goNext}
                disabled={!hasMore}
              >
                {t('adminPage.audit.next')} <ChevronRight className="h-4 w-4 ml-1" />
              </Button>
            </div>
          </>
        )}
      </CardContent>
    </Card>
  );
}
