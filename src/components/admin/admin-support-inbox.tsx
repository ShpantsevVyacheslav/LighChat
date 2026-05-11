'use client';

import React, { useCallback, useEffect, useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Textarea } from '@/components/ui/textarea';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { MessageSquare, Loader2, ArrowLeft, Send } from 'lucide-react';
import { useAuth as useFirebaseAuth } from '@/firebase';
import {
  fetchSupportTicketsAction,
  fetchTicketMessagesAction,
  replyToTicketAction,
  updateTicketStatusAction,
} from '@/actions/support-ticket-actions';
import type { SupportTicket, SupportTicketMessage, TicketStatus } from '@/lib/types';
import { useI18n } from '@/hooks/use-i18n';
import { useToast } from '@/hooks/use-toast';

const STATUS_LABEL_KEYS: Record<TicketStatus, string> = {
  open: 'adminPage.supportStatusLabels.open',
  in_progress: 'adminPage.supportStatusLabels.in_progress',
  resolved: 'adminPage.supportStatusLabels.resolved',
  closed: 'adminPage.supportStatusLabels.closed',
};

const STATUS_COLORS: Record<TicketStatus, string> = {
  open: 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400',
  in_progress: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400',
  resolved: 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400',
  closed: 'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-400',
};

const PRIORITY_LABEL_KEYS: Record<string, string> = {
  low: 'adminPage.supportPriorityLabels.low',
  medium: 'adminPage.supportPriorityLabels.medium',
  high: 'adminPage.supportPriorityLabels.high',
};

const CATEGORY_LABEL_KEYS: Record<string, string> = {
  bug: 'adminPage.supportCategoryLabels.bug',
  account: 'adminPage.supportCategoryLabels.account',
  feature: 'adminPage.supportCategoryLabels.feature',
  other: 'adminPage.supportCategoryLabels.other',
};

export function AdminSupportInbox() {
  const { t } = useI18n();
  const { toast } = useToast();
  const firebaseAuth = useFirebaseAuth();
  const [tickets, setTickets] = useState<SupportTicket[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [nextCursor, setNextCursor] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState<TicketStatus | 'all'>('all');
  const [selectedTicket, setSelectedTicket] = useState<SupportTicket | null>(null);
  const [messages, setMessages] = useState<SupportTicketMessage[]>([]);
  const [loadingMessages, setLoadingMessages] = useState(false);
  const [reply, setReply] = useState('');
  const [sending, setSending] = useState(false);

  const loadTickets = useCallback(async () => {
    const token = await firebaseAuth?.currentUser?.getIdToken();
    if (!token) return;
    setLoading(true);
    try {
      const res = await fetchSupportTicketsAction({
        idToken: token,
        statusFilter: statusFilter !== 'all' ? statusFilter : undefined,
      });
      if (res.ok) {
        setTickets(res.tickets);
        setNextCursor(res.nextCursor);
      } else {
        toast({ variant: 'destructive', title: res.error || 'Не удалось загрузить тикеты' });
      }
    } catch (e) {
      console.error('[AdminSupportInbox] loadTickets', e);
      toast({ variant: 'destructive', title: 'Не удалось загрузить тикеты' });
    } finally {
      setLoading(false);
    }
  }, [firebaseAuth, statusFilter, toast]);

  const loadMore = useCallback(async () => {
    if (!nextCursor) return;
    const token = await firebaseAuth?.currentUser?.getIdToken();
    if (!token) return;
    setLoadingMore(true);
    try {
      const res = await fetchSupportTicketsAction({
        idToken: token,
        statusFilter: statusFilter !== 'all' ? statusFilter : undefined,
        cursor: nextCursor,
      });
      if (res.ok) {
        setTickets((prev) => [...prev, ...res.tickets]);
        setNextCursor(res.nextCursor);
      } else {
        toast({ variant: 'destructive', title: res.error || 'Не удалось загрузить ещё' });
      }
    } catch (e) {
      console.error('[AdminSupportInbox] loadMore', e);
      toast({ variant: 'destructive', title: 'Не удалось загрузить ещё' });
    } finally {
      setLoadingMore(false);
    }
  }, [firebaseAuth, statusFilter, nextCursor, toast]);

  useEffect(() => { loadTickets(); }, [loadTickets]);

  const openTicket = async (ticket: SupportTicket) => {
    setSelectedTicket(ticket);
    const token = await firebaseAuth?.currentUser?.getIdToken();
    if (!token) return;
    setLoadingMessages(true);
    try {
      const res = await fetchTicketMessagesAction({ idToken: token, ticketId: ticket.id });
      if (res.ok) {
        setMessages(res.messages);
      } else {
        toast({ variant: 'destructive', title: res.error || 'Не удалось загрузить сообщения тикета' });
      }
    } catch (e) {
      console.error('[AdminSupportInbox] openTicket', e);
      toast({ variant: 'destructive', title: 'Не удалось загрузить сообщения тикета' });
    } finally {
      setLoadingMessages(false);
    }
  };

  const sendReply = async () => {
    if (!reply.trim() || !selectedTicket) return;
    const token = await firebaseAuth?.currentUser?.getIdToken();
    if (!token) return;
    setSending(true);
    try {
      const res = await replyToTicketAction({ idToken: token, ticketId: selectedTicket.id, text: reply.trim() });
      if (res.ok) {
        setReply('');
        await openTicket(selectedTicket);
      } else {
        toast({ variant: 'destructive', title: res.error || 'Не удалось отправить ответ' });
      }
    } catch (e) {
      console.error('[AdminSupportInbox] sendReply', e);
      toast({ variant: 'destructive', title: 'Не удалось отправить ответ' });
    } finally {
      setSending(false);
    }
  };

  const changeStatus = async (status: TicketStatus) => {
    if (!selectedTicket) return;
    const token = await firebaseAuth?.currentUser?.getIdToken();
    if (!token) return;
    try {
      const res = await updateTicketStatusAction({ idToken: token, ticketId: selectedTicket.id, status });
      if (!res.ok) {
        toast({ variant: 'destructive', title: res.error || 'Не удалось изменить статус' });
        return;
      }
      setSelectedTicket({ ...selectedTicket, status });
      loadTickets();
    } catch (e) {
      console.error('[AdminSupportInbox] changeStatus', e);
      toast({ variant: 'destructive', title: 'Не удалось изменить статус' });
    }
  };

  const formatDate = (iso: string) => {
    const d = new Date(iso);
    return d.toLocaleString('ru-RU', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' });
  };

  if (selectedTicket) {
    return (
      <Card className="rounded-3xl">
        <CardHeader>
          <div className="flex items-center gap-2">
            <Button variant="ghost" size="icon" className="rounded-xl" onClick={() => setSelectedTicket(null)}>
              <ArrowLeft className="h-4 w-4" />
            </Button>
            <div className="min-w-0 flex-1">
              <CardTitle className="text-lg truncate">{selectedTicket.subject}</CardTitle>
              <CardDescription>
                {selectedTicket.userName} &middot; {t(CATEGORY_LABEL_KEYS[selectedTicket.category])} &middot; {formatDate(selectedTicket.createdAt)}
              </CardDescription>
            </div>
            <Select value={selectedTicket.status} onValueChange={(v) => changeStatus(v as TicketStatus)}>
              <SelectTrigger className="w-[130px] rounded-xl">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {(Object.keys(STATUS_LABEL_KEYS) as TicketStatus[]).map((s) => (
                  <SelectItem key={s} value={s}>{t(STATUS_LABEL_KEYS[s])}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          {loadingMessages ? (
            <div className="flex justify-center py-6"><Loader2 className="h-5 w-5 animate-spin" /></div>
          ) : (
            <div className="space-y-3 max-h-[400px] overflow-y-auto">
              {messages.map((m) => (
                <div key={m.id} className={`rounded-2xl p-3 text-sm ${m.senderRole === 'admin' ? 'bg-primary/10 ml-8' : 'bg-muted mr-8'}`}>
                  <div className="flex items-center gap-2 mb-1">
                    <span className="font-medium text-xs">{m.senderName}</span>
                    <span className="text-xs text-muted-foreground">{formatDate(m.createdAt)}</span>
                    {m.senderRole === 'admin' && <Badge variant="secondary" className="text-[10px] px-1.5 py-0">{t('adminPage.support.adminLabel')}</Badge>}
                  </div>
                  <p className="whitespace-pre-wrap">{m.text}</p>
                </div>
              ))}
            </div>
          )}

          <div className="flex gap-2">
            <Textarea
              value={reply}
              onChange={(e) => setReply(e.target.value)}
              placeholder={t('adminPage.support.replyPlaceholder')}
              className="rounded-xl min-h-[60px] resize-none"
            />
            <Button
              onClick={sendReply}
              disabled={!reply.trim() || sending}
              size="icon"
              className="rounded-xl h-auto self-end"
            >
              {sending ? <Loader2 className="h-4 w-4 animate-spin" /> : <Send className="h-4 w-4" />}
            </Button>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="rounded-3xl">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-lg">
          <MessageSquare className="h-5 w-5 text-primary" />
          {t('adminPage.support.title')}
        </CardTitle>
        <CardDescription>{t('adminPage.support.description')}</CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <Select value={statusFilter} onValueChange={(v) => setStatusFilter(v as TicketStatus | 'all')}>
          <SelectTrigger className="w-[180px] rounded-xl">
            <SelectValue placeholder={t('adminPage.support.allStatuses')} />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">{t('adminPage.support.allStatuses')}</SelectItem>
            {(Object.keys(STATUS_LABEL_KEYS) as TicketStatus[]).map((s) => (
              <SelectItem key={s} value={s}>{t(STATUS_LABEL_KEYS[s])}</SelectItem>
            ))}
          </SelectContent>
        </Select>

        {loading ? (
          <div className="flex justify-center py-8"><Loader2 className="h-6 w-6 animate-spin text-muted-foreground" /></div>
        ) : tickets.length === 0 ? (
          <p className="text-center text-sm text-muted-foreground py-8">{t('adminPage.support.noTickets')}</p>
        ) : (
          <div className="space-y-2">
            {tickets.map((ticket) => (
              <button
                key={ticket.id}
                onClick={() => openTicket(ticket)}
                className="w-full text-left rounded-2xl border p-3 hover:bg-muted/50 transition-colors"
              >
                <div className="flex items-center gap-2 mb-1">
                  <span className="font-medium text-sm truncate flex-1">{ticket.subject}</span>
                  <Badge variant="secondary" className={`text-[10px] ${STATUS_COLORS[ticket.status]}`}>
                    {t(STATUS_LABEL_KEYS[ticket.status])}
                  </Badge>
                </div>
                <div className="flex items-center gap-2 text-xs text-muted-foreground">
                  <span>{ticket.userName}</span>
                  <span>&middot;</span>
                  <span>{t(CATEGORY_LABEL_KEYS[ticket.category])}</span>
                  <span>&middot;</span>
                  <span>{t(PRIORITY_LABEL_KEYS[ticket.priority])}</span>
                  <span className="ml-auto">{formatDate(ticket.createdAt)}</span>
                </div>
              </button>
            ))}
            {nextCursor && (
              <div className="flex justify-center pt-2">
                <Button
                  variant="outline"
                  size="sm"
                  className="rounded-xl"
                  onClick={loadMore}
                  disabled={loadingMore}
                >
                  {loadingMore ? <Loader2 className="h-3 w-3 animate-spin mr-1" /> : null}
                  Показать ещё
                </Button>
              </div>
            )}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
