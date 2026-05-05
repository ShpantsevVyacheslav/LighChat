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

const STATUS_LABELS: Record<TicketStatus, string> = {
  open: 'Открыто',
  in_progress: 'В работе',
  resolved: 'Решено',
  closed: 'Закрыто',
};

const STATUS_COLORS: Record<TicketStatus, string> = {
  open: 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400',
  in_progress: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400',
  resolved: 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400',
  closed: 'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-400',
};

const PRIORITY_LABELS: Record<string, string> = {
  low: 'Низкий',
  medium: 'Средний',
  high: 'Высокий',
};

const CATEGORY_LABELS: Record<string, string> = {
  bug: 'Баг',
  account: 'Аккаунт',
  feature: 'Предложение',
  other: 'Другое',
};

export function AdminSupportInbox() {
  const firebaseAuth = useFirebaseAuth();
  const [tickets, setTickets] = useState<SupportTicket[]>([]);
  const [loading, setLoading] = useState(true);
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
    const res = await fetchSupportTicketsAction({
      idToken: token,
      statusFilter: statusFilter !== 'all' ? statusFilter : undefined,
    });
    if (res.ok) setTickets(res.tickets);
    setLoading(false);
  }, [firebaseAuth, statusFilter]);

  useEffect(() => { loadTickets(); }, [loadTickets]);

  const openTicket = async (ticket: SupportTicket) => {
    setSelectedTicket(ticket);
    const token = await firebaseAuth?.currentUser?.getIdToken();
    if (!token) return;
    setLoadingMessages(true);
    const res = await fetchTicketMessagesAction({ idToken: token, ticketId: ticket.id });
    if (res.ok) setMessages(res.messages);
    setLoadingMessages(false);
  };

  const sendReply = async () => {
    if (!reply.trim() || !selectedTicket) return;
    const token = await firebaseAuth?.currentUser?.getIdToken();
    if (!token) return;
    setSending(true);
    const res = await replyToTicketAction({ idToken: token, ticketId: selectedTicket.id, text: reply.trim() });
    if (res.ok) {
      setReply('');
      await openTicket(selectedTicket);
    }
    setSending(false);
  };

  const changeStatus = async (status: TicketStatus) => {
    if (!selectedTicket) return;
    const token = await firebaseAuth?.currentUser?.getIdToken();
    if (!token) return;
    await updateTicketStatusAction({ idToken: token, ticketId: selectedTicket.id, status });
    setSelectedTicket({ ...selectedTicket, status });
    loadTickets();
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
                {selectedTicket.userName} &middot; {CATEGORY_LABELS[selectedTicket.category]} &middot; {formatDate(selectedTicket.createdAt)}
              </CardDescription>
            </div>
            <Select value={selectedTicket.status} onValueChange={(v) => changeStatus(v as TicketStatus)}>
              <SelectTrigger className="w-[130px] rounded-xl">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {(Object.keys(STATUS_LABELS) as TicketStatus[]).map((s) => (
                  <SelectItem key={s} value={s}>{STATUS_LABELS[s]}</SelectItem>
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
                    {m.senderRole === 'admin' && <Badge variant="secondary" className="text-[10px] px-1.5 py-0">Админ</Badge>}
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
              placeholder="Ответ..."
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
          Обращения пользователей
        </CardTitle>
        <CardDescription>Тикеты поступают от пользователей из раздела «Помощь».</CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <Select value={statusFilter} onValueChange={(v) => setStatusFilter(v as TicketStatus | 'all')}>
          <SelectTrigger className="w-[180px] rounded-xl">
            <SelectValue placeholder="Все статусы" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Все статусы</SelectItem>
            {(Object.keys(STATUS_LABELS) as TicketStatus[]).map((s) => (
              <SelectItem key={s} value={s}>{STATUS_LABELS[s]}</SelectItem>
            ))}
          </SelectContent>
        </Select>

        {loading ? (
          <div className="flex justify-center py-8"><Loader2 className="h-6 w-6 animate-spin text-muted-foreground" /></div>
        ) : tickets.length === 0 ? (
          <p className="text-center text-sm text-muted-foreground py-8">Обращений пока нет.</p>
        ) : (
          <div className="space-y-2">
            {tickets.map((t) => (
              <button
                key={t.id}
                onClick={() => openTicket(t)}
                className="w-full text-left rounded-2xl border p-3 hover:bg-muted/50 transition-colors"
              >
                <div className="flex items-center gap-2 mb-1">
                  <span className="font-medium text-sm truncate flex-1">{t.subject}</span>
                  <Badge variant="secondary" className={`text-[10px] ${STATUS_COLORS[t.status]}`}>
                    {STATUS_LABELS[t.status]}
                  </Badge>
                </div>
                <div className="flex items-center gap-2 text-xs text-muted-foreground">
                  <span>{t.userName}</span>
                  <span>&middot;</span>
                  <span>{CATEGORY_LABELS[t.category]}</span>
                  <span>&middot;</span>
                  <span>{PRIORITY_LABELS[t.priority]}</span>
                  <span className="ml-auto">{formatDate(t.createdAt)}</span>
                </div>
              </button>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
