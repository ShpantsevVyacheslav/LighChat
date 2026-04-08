'use client';

import React, { useState, useMemo } from 'react';
import { doc, updateDoc, deleteDoc, serverTimestamp } from 'firebase/firestore';
import { useFirestore, useDoc, useMemoFirebase } from '@/firebase';
import type { Conversation, MeetingPoll, User } from '@/lib/types';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { cn } from '@/lib/utils';
import { useToast } from '@/hooks/use-toast';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
  DropdownMenuPortal,
  DropdownMenuSeparator,
} from '@/components/ui/dropdown-menu';
import {
  MoreVertical,
  StopCircle,
  Trash2,
  RotateCcw,
  Loader2,
  Activity,
  ChevronDown,
  ChevronUp,
} from 'lucide-react';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { userAvatarListUrl } from '@/lib/user-avatar-display';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';
import { canModerateChatPoll, conversationMembersAsUsers } from '@/lib/chat-poll-utils';
import { CHAT_GLASS_MENTION_LIST } from '@/lib/chat-glass-styles';

interface MessagePollInlineProps {
  conversationId: string;
  pollId: string;
  currentUser: User;
  conversation: Conversation;
  allUsers: User[];
  isCurrentUser: boolean;
}

export function MessagePollInline(props: MessagePollInlineProps) {
  const { conversationId, pollId, currentUser, conversation, allUsers } = props;
  const firestore = useFirestore();
  const { toast } = useToast();
  const [expanded, setExpanded] = useState(false);

  const pollRef = useMemoFirebase(() => {
    if (!firestore || !conversationId || !pollId) return null;
    return doc(firestore, `conversations/${conversationId}/polls`, pollId);
  }, [firestore, conversationId, pollId]);

  const { data: poll, isLoading } = useDoc<MeetingPoll>(pollRef);

  const allParticipants = useMemo(
    () => conversationMembersAsUsers(conversation, allUsers),
    [conversation, allUsers]
  );
  const participantsCount = conversation.participantIds.length;
  const canModerate = poll ? canModerateChatPoll(conversation, currentUser.id, poll) : false;

  const handleVote = async (optionIdx: number) => {
    if (!firestore || !poll || poll.status !== 'active') return;
    try {
      const newVotes = { ...(poll.votes || {}), [currentUser.id]: optionIdx };
      const totalVotes = Object.keys(newVotes).length;
      const updateData: Record<string, unknown> = { votes: newVotes };
      if (participantsCount > 0 && totalVotes >= participantsCount) {
        updateData.status = 'ended';
      }
      await updateDoc(pollRef!, updateData);
    } catch {
      toast({ variant: 'destructive', title: 'Ошибка при голосовании' });
    }
  };

  const handleAction = async (action: 'start' | 'end' | 'delete' | 'restart' | 'revote') => {
    if (!firestore || !pollRef || !poll) return;
    try {
      switch (action) {
        case 'start':
          await updateDoc(pollRef, { status: 'active', createdAt: serverTimestamp() });
          break;
        case 'end':
          await updateDoc(pollRef, { status: 'ended' });
          break;
        case 'delete':
          await deleteDoc(pollRef);
          break;
        case 'restart':
          await updateDoc(pollRef, { status: 'active', votes: {}, createdAt: serverTimestamp() });
          break;
        case 'revote': {
          const newVotes = { ...(poll.votes || {}) };
          delete newVotes[currentUser.id];
          await updateDoc(pollRef, { votes: newVotes });
          break;
        }
      }
    } catch {
      toast({ variant: 'destructive', title: 'Ошибка' });
    }
  };

  if (isLoading || !poll) {
    return (
      <div className={cn(CHAT_GLASS_MENTION_LIST, 'mt-1 flex items-center gap-2 px-3 py-3 text-sm text-muted-foreground')}>
        <Loader2 className="h-4 w-4 shrink-0 animate-spin" />
        {isLoading ? 'Загрузка опроса…' : 'Опрос недоступен'}
      </div>
    );
  }

  const votes = poll.votes || {};
  const totalVotes = Object.keys(votes).length;
  const hasVoted = votes[currentUser.id] !== undefined;
  const isEnded = poll.status === 'ended';
  const isDraft = poll.status === 'draft';
  const isCancelled = poll.status === 'cancelled';

  if (isDraft && poll.creatorId !== currentUser.id && !canModerate) {
    return null;
  }

  return (
    <div className={cn(CHAT_GLASS_MENTION_LIST, 'mt-1 space-y-3 p-3')}>
      <div className="flex justify-between gap-2">
        <div className="min-w-0 flex-1">
          <h4 className="text-sm font-bold leading-snug text-foreground">{poll.question}</h4>
          <div className="mt-1.5 flex flex-wrap gap-1.5">
            <Badge
              variant="outline"
              className={cn(
                'h-5 rounded-full border-0 px-2 text-[9px] font-bold uppercase tracking-wide',
                isEnded || isCancelled
                  ? 'bg-muted text-muted-foreground'
                  : isDraft
                    ? 'bg-amber-500/15 text-amber-700 dark:text-amber-400'
                    : 'bg-primary/15 text-primary'
              )}
            >
              {isCancelled ? 'Отменён' : isEnded ? 'Завершён' : isDraft ? 'Черновик' : 'Активен'}
            </Badge>
            {!poll.isAnonymous && (
              <Badge variant="outline" className="h-5 rounded-full border-0 bg-primary/10 px-2 text-[9px] font-bold uppercase text-primary">
                Публично
              </Badge>
            )}
          </div>
        </div>
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button size="icon" variant="ghost" className="h-8 w-8 shrink-0 rounded-full text-muted-foreground hover:bg-black/5 hover:text-foreground dark:hover:bg-white/10">
              <MoreVertical className="h-4 w-4" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuPortal>
            <DropdownMenuContent align="end" className="z-[300] w-52 rounded-xl p-1">
              {isDraft && canModerate && (
                <DropdownMenuItem onSelect={() => handleAction('start')} className="rounded-lg text-xs">
                  Запустить
                </DropdownMenuItem>
              )}
              {hasVoted && !isEnded && !isDraft && (
                <DropdownMenuItem onSelect={() => handleAction('revote')} className="rounded-lg text-xs">
                  <RotateCcw className="mr-2 h-3.5 w-3.5" />
                  Изменить голос
                </DropdownMenuItem>
              )}
              {isEnded && canModerate && (
                <DropdownMenuItem onSelect={() => handleAction('restart')} className="rounded-lg text-xs">
                  <RotateCcw className="mr-2 h-3.5 w-3.5" />
                  Перезапустить
                </DropdownMenuItem>
              )}
              {canModerate && !isEnded && !isDraft && (
                <DropdownMenuItem onSelect={() => handleAction('end')} className="rounded-lg text-xs text-amber-600">
                  <StopCircle className="mr-2 h-3.5 w-3.5" />
                  Завершить
                </DropdownMenuItem>
              )}
              {canModerate && (
                <>
                  <DropdownMenuSeparator />
                  <DropdownMenuItem onSelect={() => handleAction('delete')} className="rounded-lg text-xs text-destructive">
                    <Trash2 className="mr-2 h-3.5 w-3.5" />
                    Удалить
                  </DropdownMenuItem>
                </>
              )}
            </DropdownMenuContent>
          </DropdownMenuPortal>
        </DropdownMenu>
      </div>

      <div className="grid gap-2">
        {poll.options.map((opt, idx) => {
          const count = Object.values(votes).filter((v) => v === idx).length;
          const percent = totalVotes > 0 ? Math.round((count / totalVotes) * 100) : 0;
          const votedForThis = votes[currentUser.id] === idx;
          const votersForOption = !poll.isAnonymous
            ? Object.entries(votes)
                .filter(([, vIdx]) => vIdx === idx)
                .map(([uId]) => allParticipants.find((p) => p.id === uId) || ({ id: uId, name: 'Участник', avatar: '' } as User))
            : [];

          return (
            <div key={idx} className="space-y-1.5">
              <button
                type="button"
                disabled={isEnded || isDraft || isCancelled || (hasVoted && !isEnded)}
                onClick={() => handleVote(idx)}
                className={cn(
                  'relative w-full overflow-hidden rounded-xl p-3 text-left transition-colors',
                  votedForThis ? 'bg-primary/15 dark:bg-primary/20' : 'bg-black/[0.06] hover:bg-black/[0.10] dark:bg-white/[0.08] dark:hover:bg-white/[0.12]'
                )}
              >
                <div className="relative z-10 flex flex-col gap-1">
                  <div className="flex items-center justify-between gap-2">
                    <span className="truncate text-xs font-semibold text-foreground">{opt}</span>
                    <span className="shrink-0 text-[10px] font-bold text-muted-foreground">
                      {percent}%
                    </span>
                  </div>
                  <div className="h-1 w-full overflow-hidden rounded-full bg-muted dark:bg-white/15">
                    <div className="h-full bg-primary transition-all duration-500" style={{ width: `${percent}%` }} />
                  </div>
                </div>
              </button>
              {expanded && !poll.isAnonymous && votersForOption.length > 0 && (
                <div className="flex flex-wrap gap-1 px-1">
                  <TooltipProvider delayDuration={0}>
                    {votersForOption.map((voter) => (
                      <Tooltip key={voter.id}>
                        <TooltipTrigger asChild>
                          <Avatar className="h-6 w-6 border">
                            <AvatarImage src={userAvatarListUrl(voter)} />
                            <AvatarFallback className="text-[8px]">{voter.name[0]}</AvatarFallback>
                          </Avatar>
                        </TooltipTrigger>
                        <TooltipContent className="text-xs font-medium">{voter.name}</TooltipContent>
                      </Tooltip>
                    ))}
                  </TooltipProvider>
                </div>
              )}
            </div>
          );
        })}
      </div>

      <div className="flex items-center justify-between px-0.5 text-[9px] font-bold uppercase tracking-wider text-muted-foreground">
        <span className="flex items-center gap-1.5">
          <Activity className="h-3 w-3" />
          {totalVotes} голосов
          {!isEnded && !isDraft && !isCancelled && <span className="opacity-70">· цель {participantsCount}</span>}
        </span>
        {!poll.isAnonymous && totalVotes > 0 && (
          <Button
            type="button"
            variant="ghost"
            size="sm"
            className="h-7 gap-1 rounded-full px-2 text-[9px] font-bold uppercase text-muted-foreground hover:bg-black/5 hover:text-foreground dark:hover:bg-white/10"
            onClick={() => setExpanded((e) => !e)}
          >
            {expanded ? <ChevronUp className="h-3 w-3" /> : <ChevronDown className="h-3 w-3" />}
            Кто голосовал
          </Button>
        )}
      </div>
    </div>
  );
}
