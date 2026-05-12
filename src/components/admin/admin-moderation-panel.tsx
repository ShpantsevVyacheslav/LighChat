'use client';

import React, { useCallback, useEffect, useMemo, useState } from 'react';
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
import {
  ShieldAlert,
  Loader2,
  EyeOff,
  Check,
  X,
  Ban,
  User as UserIcon,
  Flag,
  Image as ImageIcon,
  Video,
  FileAudio,
  FileIcon,
  ExternalLink,
} from 'lucide-react';
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
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { ruEnSubstringMatch } from '@/lib/ru-latin-search-normalize';
import {
  reviewReportAction,
  reviewAndHideReportAction,
} from '@/actions/moderation-actions';
import {
  fetchReportedMessageDetailsAction,
  type ReportedMessageDetails,
} from '@/actions/admin-reported-message-action';
import type { ChatAttachment, MessageReport, ReportReason, ReportStatus, User } from '@/lib/types';
import { useI18n } from '@/hooks/use-i18n';
import { logger } from '@/lib/logger';
import { UserBlockDialog } from '@/components/admin/user-block-dialog';
import { AdminUserProfileDialog } from '@/components/admin/admin-user-profile-dialog';
import { formatStorageBytes } from '@/lib/format-storage';

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

/** Стрипает HTML до plain-текста. Используем на клиенте, у нас есть DOM. */
function htmlToPlainText(html: string): string {
  if (!html) return '';
  if (typeof window === 'undefined') return html.replace(/<[^>]+>/g, '').trim();
  const tmp = document.createElement('div');
  tmp.innerHTML = html;
  return (tmp.textContent || tmp.innerText || '').trim();
}

function attachmentKind(att: ChatAttachment): 'image' | 'video' | 'audio' | 'file' {
  const t = (att.type || '').toLowerCase();
  if (t.startsWith('image/')) return 'image';
  if (t.startsWith('video/')) return 'video';
  if (t.startsWith('audio/')) return 'audio';
  return 'file';
}

function AttachmentPreview({ att }: { att: ChatAttachment }) {
  const kind = attachmentKind(att);
  if (kind === 'image') {
    return (
      <a
        href={att.url}
        target="_blank"
        rel="noopener noreferrer"
        className="block rounded-xl overflow-hidden border bg-muted/30 hover:opacity-80 transition-opacity"
      >
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src={att.url}
          alt={att.name || 'image'}
          className="max-h-48 w-auto object-contain"
          loading="lazy"
        />
      </a>
    );
  }
  if (kind === 'video') {
    return (
      <video
        src={att.url}
        controls
        preload="metadata"
        className="max-h-48 w-full rounded-xl border bg-black"
      />
    );
  }
  if (kind === 'audio') {
    return (
      <audio src={att.url} controls preload="metadata" className="w-full" />
    );
  }
  return (
    <a
      href={att.url}
      target="_blank"
      rel="noopener noreferrer"
      className="flex items-center gap-2 rounded-xl border p-2.5 text-sm hover:bg-muted/30 transition-colors"
    >
      <FileIcon className="h-4 w-4 text-muted-foreground" />
      <span className="truncate flex-1">{att.name || 'файл'}</span>
      {att.size > 0 && (
        <span className="text-xs text-muted-foreground">{formatStorageBytes(att.size)}</span>
      )}
      <ExternalLink className="h-3 w-3 text-muted-foreground" />
    </a>
  );
}

function AttachmentBadge({ kind }: { kind: ReturnType<typeof attachmentKind> }) {
  const Icon = kind === 'image' ? ImageIcon : kind === 'video' ? Video : kind === 'audio' ? FileAudio : FileIcon;
  return (
    <Badge variant="outline" className="text-[10px] gap-1">
      <Icon className="h-3 w-3" />
      {kind === 'image' ? 'изображение' : kind === 'video' ? 'видео' : kind === 'audio' ? 'аудио' : 'файл'}
    </Badge>
  );
}

type ReportCardProps = {
  report: MessageReport;
  acting: string | null;
  onHideAndReview: (r: MessageReport) => void;
  onDismiss: (r: MessageReport) => void;
  onOpenBlock: (r: MessageReport) => void;
  onOpenProfile: (userId: string) => void;
  currentUserId: string | undefined;
};

function ReportCard({
  report: r,
  acting,
  onHideAndReview,
  onDismiss,
  onOpenBlock,
  onOpenProfile,
  currentUserId,
}: ReportCardProps) {
  const { t } = useI18n();
  const firebaseAuth = useFirebaseAuth();
  const [details, setDetails] = useState<ReportedMessageDetails | null>(null);
  const [loadingDetails, setLoadingDetails] = useState(false);
  const [detailsError, setDetailsError] = useState<string | null>(null);

  useEffect(() => {
    if (!r.messageId) return;
    let cancelled = false;
    setLoadingDetails(true);
    (async () => {
      try {
        const token = await firebaseAuth?.currentUser?.getIdToken();
        if (!token) return;
        const res = await fetchReportedMessageDetailsAction({
          idToken: token,
          conversationId: r.conversationId,
          messageId: r.messageId!,
        });
        if (cancelled) return;
        if (res.ok) {
          setDetails(res.details);
        } else {
          setDetailsError(res.error);
        }
      } catch (e) {
        logger.error('admin-moderation', 'fetchReportedMessageDetailsAction', e);
        if (!cancelled) setDetailsError('Не удалось загрузить детали');
      } finally {
        if (!cancelled) setLoadingDetails(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [firebaseAuth, r.conversationId, r.messageId]);

  // Предпочитаем live-fetched HTML (актуальный), fallback — сохранённый
  // в жалобе snapshot. Оба варианта стрипаются до plain-текста.
  const liveText = details ? htmlToPlainText(details.textHtml) : '';
  const reportedText = r.messageText ? htmlToPlainText(r.messageText) : '';
  const displayText = liveText || reportedText;

  const attachments = details?.attachments ?? [];
  const hasAttachments = attachments.length > 0;
  const isUserLevel = !r.messageId;
  const formatDate = (iso: string) => {
    const d = new Date(iso);
    return d.toLocaleString('ru-RU', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' });
  };

  return (
    <div className="rounded-2xl border p-4 space-y-2">
      <div className="flex items-center gap-2 flex-wrap">
        <Badge variant="secondary" className={`text-[10px] ${STATUS_COLORS[r.status]}`}>
          {t(STATUS_LABEL_KEYS[r.status])}
        </Badge>
        <Badge variant="outline" className="text-[10px]">
          {REASON_LABEL_KEYS[r.reason] ? t(REASON_LABEL_KEYS[r.reason]) : r.reason}
        </Badge>
        {isUserLevel && (
          <Badge variant="outline" className="text-[10px]">
            жалоба на пользователя
          </Badge>
        )}
        {hasAttachments && (
          <>
            {attachments.slice(0, 3).map((a, idx) => (
              <AttachmentBadge key={idx} kind={attachmentKind(a)} />
            ))}
            {attachments.length > 3 && (
              <Badge variant="outline" className="text-[10px]">
                +{attachments.length - 3}
              </Badge>
            )}
          </>
        )}
        <span className="text-xs text-muted-foreground ml-auto">{formatDate(r.createdAt)}</span>
      </div>

      {displayText && (
        <div className="bg-muted rounded-xl p-2.5 text-sm">
          <p className="line-clamp-3 whitespace-pre-wrap break-words">{displayText}</p>
        </div>
      )}

      {hasAttachments && (
        <div className="space-y-2">
          {attachments.map((a, idx) => (
            <AttachmentPreview key={idx} att={a} />
          ))}
        </div>
      )}

      {details?.isE2ee && (
        <p className="text-[11px] text-muted-foreground italic">
          {reportedText
            ? 'Сообщение зашифровано E2E. Показан snapshot, отправленный автором жалобы; вложения недоступны.'
            : 'Сообщение зашифровано E2E — содержимое недоступно. Snapshot текста автор жалобы не приложил.'}
        </p>
      )}

      {loadingDetails && !details && r.messageId && (
        <p className="text-[11px] text-muted-foreground flex items-center gap-1">
          <Loader2 className="h-3 w-3 animate-spin" /> Загрузка содержимого…
        </p>
      )}

      {detailsError && !details && r.messageId && (
        <p className="text-[11px] text-destructive">Детали недоступны: {detailsError}</p>
      )}

      {details?.hiddenByAdmin && (
        <p className="text-[11px] text-muted-foreground italic">
          Сообщение уже скрыто администратором {formatDate(details.hiddenByAdmin.at)}.
        </p>
      )}

      <div className="space-y-1 text-xs text-muted-foreground">
        <div className="flex items-center gap-1.5">
          <UserIcon className="h-3 w-3 shrink-0" />
          <span>{t('admin.moderation.authorLabel')}</span>
          <button
            type="button"
            className="font-semibold text-foreground hover:underline"
            onClick={() => onOpenProfile(r.messageSenderId)}
          >
            {r.messageSenderName ?? r.messageSenderId}
          </button>
        </div>
        <div className="flex items-center gap-1.5">
          <Flag className="h-3 w-3 shrink-0" />
          <span>{t('admin.moderation.reportedByLabel')}</span>
          <button
            type="button"
            className="font-semibold text-foreground hover:underline"
            onClick={() => onOpenProfile(r.reporterId)}
          >
            {r.reporterName}
          </button>
        </div>
      </div>

      {r.description && (
        <p className="text-xs text-muted-foreground italic">&laquo;{r.description}&raquo;</p>
      )}

      {r.status === 'pending' && (
        <div className="flex flex-wrap gap-2 pt-1">
          {/* «Скрыть сообщение» — только для жалоб с конкретным
              messageId, и только если сообщение ещё не скрыто. */}
          {!isUserLevel && !details?.hiddenByAdmin && (
            <Button
              size="sm"
              variant="destructive"
              className="rounded-xl"
              onClick={() => onHideAndReview(r)}
              disabled={acting === r.id}
            >
              {acting === r.id ? <Loader2 className="h-3 w-3 animate-spin mr-1" /> : <EyeOff className="h-3 w-3 mr-1" />}
              {t('admin.moderation.hideMessage')}
            </Button>
          )}
          <Button
            size="sm"
            variant="destructive"
            className="rounded-xl"
            onClick={() => onOpenBlock(r)}
            disabled={acting === r.id || !currentUserId}
          >
            <Ban className="h-3 w-3 mr-1" /> {t('admin.usersList.block')}
          </Button>
          <Button
            size="sm"
            variant="outline"
            className="rounded-xl"
            onClick={() => onDismiss(r)}
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
  );
}

export function AdminModerationPanel() {
  const { t } = useI18n();
  const firebaseAuth = useFirebaseAuth();
  const firestore = useFirestore();
  const { user: currentUser } = useAuth();
  const { toast } = useToast();
  const [reports, setReports] = useState<MessageReport[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<ReportStatus | 'all'>('pending');
  const [reasonFilter, setReasonFilter] = useState<ReportReason | 'all'>('all');
  const [userSearch, setUserSearch] = useState('');
  // datetime-local значения: пустые == без ограничения
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [acting, setActing] = useState<string | null>(null);
  const [blockTarget, setBlockTarget] = useState<User | null>(null);
  const [pendingBlockReportId, setPendingBlockReportId] = useState<string | null>(null);
  const [profileUserId, setProfileUserId] = useState<string | null>(null);
  const REPORTS_PAGE = 50;
  const [reportsLimit, setReportsLimit] = useState(REPORTS_PAGE);
  const [hasMore, setHasMore] = useState(false);

  useEffect(() => {
    setReportsLimit(REPORTS_PAGE);
    setHasMore(false);
  }, [statusFilter]);

  const resetClientFilters = useCallback(() => {
    setReasonFilter('all');
    setUserSearch('');
    setDateFrom('');
    setDateTo('');
  }, []);

  // Клиент-сайд фильтрация по reason, пользователю и диапазону дат.
  // Status фильтруется серверно (Firestore where), а composite index с
  // reason/createdAt-range пришлось бы заводить отдельно — для админ-
  // панели объёмы небольшие, клиентского фильтра достаточно.
  const filteredReports = useMemo(() => {
    const fromMs = dateFrom ? Date.parse(dateFrom) : null;
    const toMs = dateTo ? Date.parse(dateTo) : null;
    const search = userSearch.trim();
    return reports.filter((r) => {
      if (reasonFilter !== 'all' && r.reason !== reasonFilter) return false;
      if (fromMs != null) {
        const t = Date.parse(r.createdAt);
        if (!Number.isFinite(t) || t < fromMs) return false;
      }
      if (toMs != null) {
        const t = Date.parse(r.createdAt);
        if (!Number.isFinite(t) || t > toMs) return false;
      }
      if (search) {
        const lower = search.toLowerCase();
        const haystacks: Array<string | undefined> = [
          r.messageSenderName,
          r.messageSenderId,
          r.reporterName,
          r.reporterId,
        ];
        const match = haystacks.some((h) =>
          h
            ? h.toLowerCase().includes(lower) || ruEnSubstringMatch(h, search)
            : false,
        );
        if (!match) return false;
      }
      return true;
    });
  }, [reports, reasonFilter, userSearch, dateFrom, dateTo]);

  const hasActiveClientFilter =
    reasonFilter !== 'all' || !!userSearch.trim() || !!dateFrom || !!dateTo;

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
        logger.error('admin-moderation', 'onSnapshot', err);
        setLoading(false);
      },
    );
  }, [firestore, statusFilter, reportsLimit]);

  const handleHideAndReview = useCallback(async (report: MessageReport) => {
    const token = await firebaseAuth?.currentUser?.getIdToken();
    if (!token) return;
    if (!report.messageId) return;
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
      logger.error('admin-moderation', 'handleHideAndReview', e);
      toast({ variant: 'destructive', title: 'Не удалось обработать жалобу' });
    } finally {
      setActing(null);
    }
  }, [firebaseAuth, t, toast]);

  const handleDismiss = useCallback(async (report: MessageReport) => {
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
      logger.error('admin-moderation', 'handleDismiss', e);
      toast({ variant: 'destructive', title: 'Не удалось отклонить жалобу' });
    } finally {
      setActing(null);
    }
  }, [firebaseAuth, t, toast]);

  const handleOpenBlock = useCallback(async (report: MessageReport) => {
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
      logger.error('admin-moderation', 'load user for block', e);
      toast({ variant: 'destructive', title: 'Не удалось загрузить пользователя' });
    } finally {
      setActing(null);
    }
  }, [firestore, toast]);

  const handleBlockDone = useCallback(async () => {
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
  }, [firebaseAuth, pendingBlockReportId]);

  const handleOpenProfile = useCallback((userId: string) => {
    setProfileUserId(userId);
  }, []);

  const currentUserId = useMemo(() => currentUser?.id, [currentUser?.id]);

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
        {/* Фильтры */}
        <div className="rounded-2xl border border-border/60 bg-muted/15 p-3 space-y-3">
          <div className="grid gap-3 sm:grid-cols-2">
            <div className="space-y-1">
              <Label className="text-xs text-muted-foreground">Статус</Label>
              <Select value={statusFilter} onValueChange={(v) => setStatusFilter(v as ReportStatus | 'all')}>
                <SelectTrigger className="rounded-xl">
                  <SelectValue placeholder={t('admin.moderation.statusPlaceholder')} />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">{t('admin.moderation.statusAll')}</SelectItem>
                  <SelectItem value="pending">{t('admin.moderation.statusPending')}</SelectItem>
                  <SelectItem value="action_taken">{t('admin.moderation.statusActionTaken')}</SelectItem>
                  <SelectItem value="dismissed">{t('admin.moderation.statusDismissed')}</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1">
              <Label className="text-xs text-muted-foreground">Причина</Label>
              <Select value={reasonFilter} onValueChange={(v) => setReasonFilter(v as ReportReason | 'all')}>
                <SelectTrigger className="rounded-xl">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Любая</SelectItem>
                  <SelectItem value="spam">{t('admin.moderation.reasonSpam')}</SelectItem>
                  <SelectItem value="harassment">{t('admin.moderation.reasonHarassment')}</SelectItem>
                  <SelectItem value="inappropriate">{t('admin.moderation.reasonInappropriate')}</SelectItem>
                  <SelectItem value="offensive">{t('admin.moderation.reasonOffensive')}</SelectItem>
                  <SelectItem value="violence">{t('admin.moderation.reasonViolence')}</SelectItem>
                  <SelectItem value="fraud">{t('admin.moderation.reasonFraud')}</SelectItem>
                  <SelectItem value="other">{t('admin.moderation.reasonOther')}</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          <div className="space-y-1">
            <Label className="text-xs text-muted-foreground">Поиск по пользователю</Label>
            <Input
              value={userSearch}
              onChange={(e) => setUserSearch(e.target.value)}
              placeholder="Имя или ID автора / пожаловавшегося"
              className="rounded-xl"
            />
          </div>
          <div className="grid gap-3 sm:grid-cols-2">
            <div className="space-y-1">
              <Label className="text-xs text-muted-foreground">С</Label>
              <Input
                type="datetime-local"
                value={dateFrom}
                onChange={(e) => setDateFrom(e.target.value)}
                className="rounded-xl"
              />
            </div>
            <div className="space-y-1">
              <Label className="text-xs text-muted-foreground">По</Label>
              <Input
                type="datetime-local"
                value={dateTo}
                onChange={(e) => setDateTo(e.target.value)}
                className="rounded-xl"
              />
            </div>
          </div>
          {hasActiveClientFilter && (
            <div className="flex justify-end">
              <Button type="button" variant="ghost" size="sm" className="rounded-xl text-xs" onClick={resetClientFilters}>
                <X className="h-3 w-3 mr-1" /> Сбросить фильтры
              </Button>
            </div>
          )}
        </div>

        {/* Счётчик */}
        {!loading && reports.length > 0 && (
          <p className="text-xs text-muted-foreground">
            Показано: <strong className="text-foreground">{filteredReports.length}</strong>
            {hasActiveClientFilter && reports.length !== filteredReports.length && (
              <> из {reports.length} загруженных</>
            )}
            {!hasActiveClientFilter && hasMore && <> · доступно ещё</>}
          </p>
        )}

        {loading ? (
          <div className="flex justify-center py-8"><Loader2 className="h-6 w-6 animate-spin text-muted-foreground" /></div>
        ) : filteredReports.length === 0 ? (
          <p className="text-center text-sm text-muted-foreground py-8">
            {hasActiveClientFilter
              ? 'Нет жалоб, соответствующих фильтрам.'
              : t('admin.moderation.noReports')}
          </p>
        ) : (
          <div className="space-y-3">
            {filteredReports.map((r) => (
              <ReportCard
                key={r.id}
                report={r}
                acting={acting}
                onHideAndReview={handleHideAndReview}
                onDismiss={handleDismiss}
                onOpenBlock={handleOpenBlock}
                onOpenProfile={handleOpenProfile}
                currentUserId={currentUserId}
              />
            ))}
            {hasMore && (
              <div className="flex justify-center pt-2">
                <Button
                  variant="outline"
                  size="sm"
                  className="rounded-xl"
                  onClick={() => setReportsLimit((n) => n + REPORTS_PAGE)}
                >
                  Показать ещё {REPORTS_PAGE}
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

      <AdminUserProfileDialog
        open={!!profileUserId}
        onOpenChange={(open) => {
          if (!open) setProfileUserId(null);
        }}
        userId={profileUserId}
      />
    </Card>
  );
}
