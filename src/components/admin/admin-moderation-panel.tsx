'use client';
import { useI18n } from '@/hooks/use-i18n';

import React, { useCallback, useEffect, useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { ShieldAlert, Loader2, EyeOff, Check, X } from 'lucide-react';
import { useAuth as useFirebaseAuth } from '@/firebase';
import { useToast } from '@/hooks/use-toast';
import {
  fetchPendingReportsAction,
  reviewReportAction,
  hideMessageAction,
} from '@/actions/moderation-actions';
import type { MessageReport, ReportStatus } from '@/lib/types';

const REASON_LABELS: Record<string, string> = {
  spam: 'Спам',
  harassment: 'Оскорбление',
  inappropriate: 'Неприемлемый контент',
  other: 'Другое',
};

const STATUS_LABELS: Record<ReportStatus, string> = {
  pending: 'Ожидает',
  reviewed: 'Просмотрено',
  action_taken: 'Приняты меры',
  dismissed: 'Отклонено',
};

const STATUS_COLORS: Record<ReportStatus, string> = {
  pending: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400',
  reviewed: 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400',
  action_taken: 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400',
  dismissed: 'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-400',
};

export function AdminModerationPanel() {
  const { t } = useI18n();
  const firebaseAuth = useFirebaseAuth();
  const { toast } = useToast();
  const [reports, setReports] = useState<MessageReport[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<ReportStatus | 'all'>('pending');
  const [acting, setActing] = useState<string | null>(null);

  const load = useCallback(async () => {
    const token = await firebaseAuth?.currentUser?.getIdToken();
    if (!token) return;
    setLoading(true);
    const res = await fetchPendingReportsAction({
      idToken: token,
      statusFilter: statusFilter !== 'all' ? statusFilter : undefined,
    });
    if (res.ok) setReports(res.reports);
    setLoading(false);
  }, [firebaseAuth, statusFilter]);

  useEffect(() => { load(); }, [load]);

  const handleHideAndReview = async (report: MessageReport) => {
    const token = await firebaseAuth?.currentUser?.getIdToken();
    if (!token) return;
    setActing(report.id);

    const hideRes = await hideMessageAction({
      idToken: token,
      conversationId: report.conversationId,
      messageId: report.messageId,
      reason: `Report: ${report.reason}`,
    });

    if (hideRes.ok) {
      await reviewReportAction({
        idToken: token,
        reportId: report.id,
        status: 'action_taken',
        actionTaken: 'hidden',
      });
      toast({ title: t('chat.moderationHidden') });
      load();
    } else {
      toast({ variant: 'destructive', title: hideRes.error });
    }
    setActing(null);
  };

  const handleDismiss = async (report: MessageReport) => {
    const token = await firebaseAuth?.currentUser?.getIdToken();
    if (!token) return;
    setActing(report.id);
    const res = await reviewReportAction({
      idToken: token,
      reportId: report.id,
      status: 'dismissed',
      actionTaken: 'none',
    });
    if (res.ok) {
      toast({ title: 'Жалоба отклонена' });
      load();
    }
    setActing(null);
  };

  const formatDate = (iso: string) => {
    const d = new Date(iso);
    return d.toLocaleString('ru-RU', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' });
  };

  return (
    <Card className="rounded-3xl">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-lg">
          <ShieldAlert className="h-5 w-5 text-primary" />
          Модерация контента
        </CardTitle>
        <CardDescription>Жалобы пользователей на сообщения в чатах.</CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <Select value={statusFilter} onValueChange={(v) => setStatusFilter(v as ReportStatus | 'all')}>
          <SelectTrigger className="w-[180px] rounded-xl">
            <SelectValue placeholder="Статус" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Все</SelectItem>
            <SelectItem value="pending">Ожидают</SelectItem>
            <SelectItem value="action_taken">Приняты меры</SelectItem>
            <SelectItem value="dismissed">Отклонено</SelectItem>
          </SelectContent>
        </Select>

        {loading ? (
          <div className="flex justify-center py-8"><Loader2 className="h-6 w-6 animate-spin text-muted-foreground" /></div>
        ) : reports.length === 0 ? (
          <p className="text-center text-sm text-muted-foreground py-8">Жалоб нет.</p>
        ) : (
          <div className="space-y-3">
            {reports.map((r) => (
              <div key={r.id} className="rounded-2xl border p-4 space-y-2">
                <div className="flex items-center gap-2 flex-wrap">
                  <Badge variant="secondary" className={`text-[10px] ${STATUS_COLORS[r.status]}`}>
                    {STATUS_LABELS[r.status]}
                  </Badge>
                  <Badge variant="outline" className="text-[10px]">
                    {REASON_LABELS[r.reason] ?? r.reason}
                  </Badge>
                  <span className="text-xs text-muted-foreground ml-auto">{formatDate(r.createdAt)}</span>
                </div>

                {r.messageText && (
                  <div className="bg-muted rounded-xl p-2.5 text-sm">
                    <p className="line-clamp-3">{r.messageText}</p>
                  </div>
                )}

                <div className="flex items-center gap-2 text-xs text-muted-foreground">
                  <span>Автор: <strong>{r.messageSenderName ?? r.messageSenderId}</strong></span>
                  <span>&middot;</span>
                  <span>Жалоба от: {r.reporterName}</span>
                </div>

                {r.description && (
                  <p className="text-xs text-muted-foreground italic">&laquo;{r.description}&raquo;</p>
                )}

                {r.status === 'pending' && (
                  <div className="flex gap-2 pt-1">
                    <Button
                      size="sm"
                      variant="destructive"
                      className="rounded-xl"
                      onClick={() => handleHideAndReview(r)}
                      disabled={acting === r.id}
                    >
                      {acting === r.id ? <Loader2 className="h-3 w-3 animate-spin mr-1" /> : <EyeOff className="h-3 w-3 mr-1" />}
                      Скрыть сообщение
                    </Button>
                    <Button
                      size="sm"
                      variant="outline"
                      className="rounded-xl"
                      onClick={() => handleDismiss(r)}
                      disabled={acting === r.id}
                    >
                      <X className="h-3 w-3 mr-1" /> Отклонить
                    </Button>
                  </div>
                )}

                {r.status === 'action_taken' && (
                  <div className="flex items-center gap-1 text-xs text-green-600">
                    <Check className="h-3 w-3" /> Меры приняты
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
