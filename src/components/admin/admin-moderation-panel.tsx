'use client';

import React, { useEffect, useState } from 'react';
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
import { ShieldAlert, Loader2, EyeOff, Check, X, Ban, User as UserIcon, Flag } from 'lucide-react';
import {
  collection,
  doc,
  getDoc,
  limit as fsLimit,
  onSnapshot,
  orderBy,
  query,
  where,
} from 'firebase/firestore';
import { useAuth as useFirebaseAuth, useFirestore } from '@/firebase';
import { useAuth } from '@/hooks/use-auth';
import { useToast } from '@/hooks/use-toast';
import {
  reviewReportAction,
  reviewAndHideReportAction,
} from '@/actions/moderation-actions';
import type { MessageReport, ReportStatus, User } from '@/lib/types';
import { useI18n } from '@/hooks/use-i18n';
import { UserBlockDialog } from '@/components/admin/user-block-dialog';

const REASON_LABEL_KEYS: Record<string, string> = {
  spam: 'admin.moderation.reasonSpam',
  harassment: 'admin.moderation.reasonHarassment',
  inappropriate: 'admin.moderation.reasonInappropriate',
  offensive: 'admin.moderation.reasonOffensive',
  violence: 'admin.moderation.reasonViolence',
  fraud: 'admin.moderation.reasonFraud',
  other: 'admin.moderation.reasonOther',
};

const STATUS_LABEL_KEYS: Record<ReportStatus, string> = {
  pending: 'admin.moderation.statusPending',
  reviewed: 'admin.moderation.statusReviewed',
  action_taken: 'admin.moderation.statusActionTaken',
  dismissed: 'admin.moderation.statusDismissed',
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
  const firestore = useFirestore();
  const { user: currentUser } = useAuth();
  const { toast } = useToast();
  const [reports, setReports] = useState<MessageReport[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<ReportStatus | 'all'>('pending');
  const [acting, setActing] = useState<string | null>(null);
  const [blockTarget, setBlockTarget] = useState<User | null>(null);
  const [pendingBlockReportId, setPendingBlockReportId] = useState<string | null>(null);
  // Растущее окно для live-подписки. При нажатии "Показать ещё" увеличиваем
  // лимит на REPORTS_PAGE; onSnapshot переподписывается на новый запрос.
  const REPORTS_PAGE = 50;
  const [reportsLimit, setReportsLimit] = useState(REPORTS_PAGE);
  const [hasMore, setHasMore] = useState(false);

  useEffect(() => {
    setReportsLimit(REPORTS_PAGE);
    setHasMore(false);
  }, [statusFilter]);

  useEffect(() => {
    if (!firestore) return;
    setLoading(true);
    const base = collection(firestore, 'messageReports');
    const q = statusFilter === 'all'
      ? query(base, orderBy('createdAt', 'desc'), fsLimit(reportsLimit))
      : query(base, where('status', '==', statusFilter), orderBy('createdAt', 'desc'), fsLimit(reportsLimit));
    return onSnapshot(
      q,
      (snap) => {
        // Перезаписываем `id` из doc.id: старые жалобы могли быть созданы
        // до того, как мы стали сохранять id в самом документе, и тогда
        // report.id остаётся undefined → server action валидирует поле
        // как FirestoreIdSchema и возвращает «Некорректные параметры».
        setReports(snap.docs.map((d) => ({ ...(d.data() as MessageReport), id: d.id })));
        setHasMore(snap.docs.length >= reportsLimit);
        setLoading(false);
      },
      (err) => {
        console.error('[AdminModerationPanel] onSnapshot', err);
        setLoading(false);
      },
    );
  }, [firestore, statusFilter, reportsLimit]);

  const handleHideAndReview = async (report: MessageReport) => {
    const token = await firebaseAuth?.currentUser?.getIdToken();
    if (!token) return;
    if (!report.messageId) {
      toast({ variant: 'destructive', title: 'У этой жалобы нет конкретного сообщения — её можно только отклонить' });
      return;
    }
    setActing(report.id);
    try {
      const res = await reviewAndHideReportAction({
        idToken: token,
        reportId: report.id,
        conversationId: report.conversationId,
        messageId: report.messageId,
        reason: `Report: ${report.reason}`,
      });
      if (res.ok) {
        toast({ title: t('admin.moderation.messageHiddenToast') });
      } else {
        toast({ variant: 'destructive', title: res.error });
      }
    } catch (e) {
      console.error('[AdminModerationPanel] handleHideAndReview', e);
      toast({ variant: 'destructive', title: 'Не удалось обработать жалобу' });
    } finally {
      setActing(null);
    }
  };

  const handleDismiss = async (report: MessageReport) => {
    const token = await firebaseAuth?.currentUser?.getIdToken();
    if (!token) return;
    setActing(report.id);
    try {
      const res = await reviewReportAction({
        idToken: token,
        reportId: report.id,
        status: 'dismissed',
        actionTaken: 'none',
      });
      if (res.ok) {
        toast({ title: t('admin.moderation.reportDismissed') });
      } else {
        toast({ variant: 'destructive', title: res.error });
      }
    } catch (e) {
      console.error('[AdminModerationPanel] handleDismiss', e);
      toast({ variant: 'destructive', title: 'Не удалось отклонить жалобу' });
    } finally {
      setActing(null);
    }
  };

  const handleOpenBlock = async (report: MessageReport) => {
    if (!firestore) return;
    setActing(report.id);
    try {
      const snap = await getDoc(doc(firestore, 'users', report.messageSenderId));
      if (!snap.exists()) {
        toast({ variant: 'destructive', title: 'Пользователь не найден' });
        return;
      }
      setBlockTarget({ id: snap.id, ...(snap.data() as Omit<User, 'id'>) });
      setPendingBlockReportId(report.id);
    } catch (e) {
      console.error('[AdminModerationPanel] load user for block', e);
      toast({ variant: 'destructive', title: 'Не удалось загрузить пользователя' });
    } finally {
      setActing(null);
    }
  };

  const handleBlockDone = async () => {
    if (!pendingBlockReportId) return;
    const token = await firebaseAuth?.currentUser?.getIdToken();
    if (token) {
      await reviewReportAction({
        idToken: token,
        reportId: pendingBlockReportId,
        status: 'action_taken',
        actionTaken: 'user_blocked',
      });
    }
    setPendingBlockReportId(null);
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
          {t('admin.moderation.title')}
        </CardTitle>
        <CardDescription>{t('admin.moderation.description')}</CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <Select value={statusFilter} onValueChange={(v) => setStatusFilter(v as ReportStatus | 'all')}>
          <SelectTrigger className="w-[180px] rounded-xl">
            <SelectValue placeholder={t('admin.moderation.statusPlaceholder')} />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">{t('admin.moderation.statusAll')}</SelectItem>
            <SelectItem value="pending">{t('admin.moderation.statusPending')}</SelectItem>
            <SelectItem value="action_taken">{t('admin.moderation.statusActionTaken')}</SelectItem>
            <SelectItem value="dismissed">{t('admin.moderation.statusDismissed')}</SelectItem>
          </SelectContent>
        </Select>

        {loading ? (
          <div className="flex justify-center py-8"><Loader2 className="h-6 w-6 animate-spin text-muted-foreground" /></div>
        ) : reports.length === 0 ? (
          <p className="text-center text-sm text-muted-foreground py-8">{t('admin.moderation.noReports')}</p>
        ) : (
          <div className="space-y-3">
            {reports.map((r) => (
              <div key={r.id} className="rounded-2xl border p-4 space-y-2">
                <div className="flex items-center gap-2 flex-wrap">
                  <Badge variant="secondary" className={`text-[10px] ${STATUS_COLORS[r.status]}`}>
                    {t(STATUS_LABEL_KEYS[r.status])}
                  </Badge>
                  <Badge variant="outline" className="text-[10px]">
                    {REASON_LABEL_KEYS[r.reason] ? t(REASON_LABEL_KEYS[r.reason]) : r.reason}
                  </Badge>
                  <span className="text-xs text-muted-foreground ml-auto">{formatDate(r.createdAt)}</span>
                </div>

                {r.messageText && (
                  <div className="bg-muted rounded-xl p-2.5 text-sm">
                    <p className="line-clamp-3">{r.messageText}</p>
                  </div>
                )}

                <div className="space-y-1 text-xs text-muted-foreground">
                  <div className="flex items-center gap-1.5">
                    <UserIcon className="h-3 w-3 shrink-0" />
                    <span>{t('admin.moderation.authorLabel')}</span>
                    <strong className="text-foreground">{r.messageSenderName ?? r.messageSenderId}</strong>
                  </div>
                  <div className="flex items-center gap-1.5">
                    <Flag className="h-3 w-3 shrink-0" />
                    <span>{t('admin.moderation.reportedByLabel')}</span>
                    <strong className="text-foreground">{r.reporterName}</strong>
                  </div>
                </div>

                {r.description && (
                  <p className="text-xs text-muted-foreground italic">&laquo;{r.description}&raquo;</p>
                )}

                {r.status === 'pending' && (
                  <div className="flex flex-wrap gap-2 pt-1">
                    <Button
                      size="sm"
                      variant="destructive"
                      className="rounded-xl"
                      onClick={() => handleHideAndReview(r)}
                      disabled={acting === r.id || !r.messageId}
                      title={!r.messageId ? 'У этой жалобы нет конкретного сообщения — её можно только отклонить' : undefined}
                    >
                      {acting === r.id ? <Loader2 className="h-3 w-3 animate-spin mr-1" /> : <EyeOff className="h-3 w-3 mr-1" />}
                      {t('admin.moderation.hideMessage')}
                    </Button>
                    <Button
                      size="sm"
                      variant="destructive"
                      className="rounded-xl"
                      onClick={() => handleOpenBlock(r)}
                      disabled={acting === r.id || !currentUser?.id}
                    >
                      <Ban className="h-3 w-3 mr-1" /> {t('admin.usersList.block')}
                    </Button>
                    <Button
                      size="sm"
                      variant="outline"
                      className="rounded-xl"
                      onClick={() => handleDismiss(r)}
                      disabled={acting === r.id}
                    >
                      <X className="h-3 w-3 mr-1" /> {t('admin.moderation.dismiss')}
                    </Button>
                  </div>
                )}

                {r.status === 'action_taken' && (
                  <div className="flex items-center gap-1 text-xs text-green-600">
                    <Check className="h-3 w-3" /> {t('admin.moderation.actionTakenLabel')}
                  </div>
                )}
              </div>
            ))}
            {hasMore && (
              <div className="flex justify-center pt-2">
                <Button
                  variant="outline"
                  size="sm"
                  className="rounded-xl"
                  onClick={() => setReportsLimit((n) => n + REPORTS_PAGE)}
                >
                  Показать ещё
                </Button>
              </div>
            )}
          </div>
        )}
      </CardContent>

      {currentUser?.id && (
        <UserBlockDialog
          open={!!blockTarget}
          onOpenChange={(open) => {
            if (!open) {
              setBlockTarget(null);
              setPendingBlockReportId(null);
            }
          }}
          firestore={firestore}
          target={blockTarget}
          blockedById={currentUser.id}
          onDone={handleBlockDone}
        />
      )}
    </Card>
  );
}
