'use client';

import React, { useState, useMemo } from 'react';
import { useFirestore, useCollection, useMemoFirebase } from '@/firebase';
import { collection, doc, setDoc, updateDoc, serverTimestamp, orderBy, query, deleteDoc } from 'firebase/firestore';
import type { User, MeetingPoll } from '@/lib/types';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Badge } from '@/components/ui/badge';
import { Switch } from '@/components/ui/switch';
import { 
  Plus, MoreVertical, StopCircle, Trash2, RotateCcw, Loader2, PlayCircle, Activity, ChevronDown, ChevronUp
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { Label } from '../ui/label';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
  DropdownMenuPortal,
  DropdownMenuSeparator,
} from "@/components/ui/dropdown-menu";
import { useToast } from '@/hooks/use-toast';
import { Avatar, AvatarFallback, AvatarImage } from '../ui/avatar';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';

interface MeetingPollsProps {
  meetingId: string;
  currentUser: User;
  participantsCount: number;
  allParticipants: User[];
  isHost: boolean;
}

export function MeetingPolls({ meetingId, currentUser, participantsCount, allParticipants, isHost }: MeetingPollsProps) {
  const [isCreating, setIsCreating] = useState(false);
  const [question, setQuestion] = useState('');
  const [options, setOptions] = useState(['', '']);
  const [isAnonymous, setIsAnonymous] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [expandedPolls, setExpandedPolls] = useState<Set<string>>(new Set());
  
  const firestore = useFirestore();
  const { toast } = useToast();

  const pollsQuery = useMemoFirebase(() => {
    if (!firestore || !meetingId) return null;
    return query(collection(firestore, `meetings/${meetingId}/polls`), orderBy('createdAt', 'desc'));
  }, [firestore, meetingId]);

  const { data: polls } = useCollection<MeetingPoll>(pollsQuery);

  const toggleExpand = (pollId: string) => {
    setExpandedPolls(prev => {
        const next = new Set(prev);
        if (next.has(pollId)) next.delete(pollId);
        else next.add(pollId);
        return next;
    });
  };

  const handleVote = async (pollId: string, optionIdx: number) => {
    if (!firestore) return;
    const pollRef = doc(firestore, `meetings/${meetingId}/polls`, pollId);
    const poll = polls?.find(p => p.id === pollId);
    if (!poll || poll.status !== 'active') return;

    try {
        const newVotes = { ...(poll.votes || {}), [currentUser.id]: optionIdx };
        const totalVotes = Object.keys(newVotes).length;
        const updateData: any = { votes: newVotes };
        
        // Auto-end logic: if everyone has voted, mark as ended
        if (participantsCount > 0 && totalVotes >= participantsCount) {
            updateData.status = 'ended';
        }
        
        await updateDoc(pollRef, updateData);
    } catch (e) {
        toast({ variant: 'destructive', title: 'Ошибка при голосовании' });
    }
  };

  const handleAction = async (pollId: string, action: 'start' | 'end' | 'delete' | 'restart' | 'revote') => {
    if (!firestore) return;
    const pollRef = doc(firestore, `meetings/${meetingId}/polls`, pollId);
    try {
        switch (action) {
            case 'start': await updateDoc(pollRef, { status: 'active', createdAt: serverTimestamp() }); break;
            case 'end': await updateDoc(pollRef, { status: 'ended' }); break;
            case 'delete': await deleteDoc(pollRef); break;
            case 'restart': await updateDoc(pollRef, { status: 'active', votes: {}, createdAt: serverTimestamp() }); break;
            case 'revote':
                const poll = polls?.find(p => p.id === pollId);
                if (poll) {
                    const newVotes = { ...(poll.votes || {}) };
                    delete newVotes[currentUser.id];
                    await updateDoc(pollRef, { votes: newVotes });
                }
                break;
        }
    } catch (e) { toast({ variant: 'destructive', title: 'Ошибка действия' }); }
  };

  const handleCreatePoll = async (asDraft: boolean) => {
      if (!question.trim() || !firestore) return;
      const filteredOptions = options.filter(o => o.trim() !== '');
      if (filteredOptions.length < 2) { toast({ variant: 'destructive', title: 'Минимум 2 варианта ответа' }); return; }
      setIsSaving(true);
      try {
          const pollId = `poll-${Date.now()}`;
          await setDoc(doc(firestore, `meetings/${meetingId}/polls`, pollId), {
              id: pollId, question: question.trim(), options: filteredOptions,
              creatorId: currentUser.id, status: asDraft ? 'draft' : 'active',
              isAnonymous, createdAt: serverTimestamp(), votes: {}
          });
          setIsCreating(false); setQuestion(''); setOptions(['', '']); setIsAnonymous(true);
      } catch (e) { toast({ variant: 'destructive', title: 'Ошибка при создании' }); } finally { setIsSaving(false); }
  };

  return (
    <div className="flex flex-col h-full bg-transparent">
      {!isCreating && isHost && (
        <div className="px-6 py-2 shrink-0">
            <Button size="sm" variant="outline" onClick={() => setIsCreating(true)} className="w-full rounded-2xl h-12 bg-primary text-white border-none hover:bg-primary/90 font-black uppercase text-[10px] tracking-[0.2em] gap-3 shadow-lg shadow-primary/30">
                <Plus className="h-4 w-4" /> Создать опрос
            </Button>
        </div>
      )}

      <ScrollArea className="flex-1">
        <div className="p-6 space-y-6">
          {isCreating ? (
            <div className="bg-white/5 backdrop-blur-3xl p-6 rounded-[2.5rem] border border-white/10 space-y-6 shadow-2xl animate-in zoom-in-95 duration-500">
              <div className="space-y-2">
                <Label className="text-[10px] font-black uppercase tracking-[0.2em] text-white/40 px-1">Ваш вопрос</Label>
                <Input value={question} onChange={e => setQuestion(e.target.value)} placeholder="Напр: Когда начнем?" className="rounded-2xl h-12 bg-black/40 border-white/5 focus:ring-primary/50 text-sm border-none shadow-none" />
              </div>
              <div className="space-y-3">
                <Label className="text-[10px] font-black uppercase tracking-[0.2em] text-white/40 px-1">Варианты ответа</Label>
                {options.map((opt, idx) => (
                  <div key={idx} className="flex gap-2 group">
                    <Input value={opt} onChange={e => {
                        const newOpts = [...options]; newOpts[idx] = e.target.value; setOptions(newOpts);
                    }} placeholder={`Вариант ${idx + 1}`} className="rounded-xl h-11 bg-black/40 border-white/5 text-sm border-none shadow-none" />
                    {options.length > 2 && (
                        <Button variant="ghost" size="icon" className="shrink-0 h-11 w-11 rounded-xl hover:bg-red-500/20 border-none shadow-none" onClick={() => setOptions(options.filter((_, i) => i !== idx))}>
                            <Trash2 className="h-4 w-4 text-red-500/50" />
                        </Button>
                    )}
                  </div>
                ))}
                <Button variant="ghost" size="sm" onClick={() => setOptions([...options, ''])} className="w-full h-11 text-[9px] font-black uppercase tracking-widest border border-dashed border-white/10 rounded-2xl hover:bg-white/5 transition-all shadow-none">
                    <Plus className="h-3 w-3 mr-2" /> Добавить еще
                </Button>
              </div>
              <div className="flex items-center justify-between p-4 bg-black/20 rounded-2xl border border-white/5">
                  <div className="flex flex-col"><span className="text-xs font-bold">{isAnonymous ? 'Анонимно' : 'Публично'}</span><span className="text-[9px] text-white/30 uppercase tracking-wider mt-0.5">Кто увидит выбор</span></div>
                  <Switch checked={isAnonymous} onCheckedChange={setIsAnonymous} />
              </div>
              <div className="flex flex-col gap-2 pt-2">
                  <div className="flex gap-2">
                    <Button variant="ghost" onClick={() => setIsCreating(false)} className="flex-1 rounded-2xl h-12 border-none bg-white/5 font-bold text-xs">Отмена</Button>
                    <Button variant="outline" onClick={() => handleCreatePoll(true)} className="flex-1 rounded-2xl h-12 bg-white/5 border-white/10 font-bold text-xs" disabled={isSaving || !question.trim()}>В черновики</Button>
                  </div>
                  <Button onClick={() => handleCreatePoll(false)} className="w-full rounded-2xl h-14 font-black uppercase tracking-widest text-[10px] shadow-xl shadow-primary/20" disabled={isSaving || !question.trim()}>
                    {isSaving ? <Loader2 className="h-5 w-5 animate-spin" /> : 'Опубликовать'}
                  </Button>
              </div>
            </div>
          ) : (
            polls?.map(poll => {
              const votes = poll.votes || {};
              const totalVotes = Object.keys(votes).length;
              const hasVoted = votes[currentUser.id] !== undefined;
              const isEnded = poll.status === 'ended';
              const isDraft = poll.status === 'draft';
              const isExpanded = expandedPolls.has(poll.id);

              if (isDraft && poll.creatorId !== currentUser.id && !isHost) return null;

              return (
                <div key={poll.id} className={cn(
                    "p-6 rounded-[2.5rem] border transition-all duration-700 space-y-6 backdrop-blur-3xl shadow-xl",
                    isEnded ? "bg-black/40 border-white/5 opacity-80" : 
                    isDraft ? "bg-amber-500/5 border-amber-500/20" : "bg-white/5 border-white/10"
                )}>
                  <div className="flex justify-between items-start gap-4">
                      <div className="min-w-0 flex-1">
                          <h4 className="font-headline font-black text-sm leading-tight mb-2 text-white/90">{poll.question}</h4>
                          <div className="flex flex-wrap gap-2">
                              <Badge variant="outline" className={cn(
                                  "text-[8px] font-black uppercase tracking-widest rounded-full px-2.5 h-5 border-none",
                                  isEnded ? "bg-red-500/20 text-red-500" : isDraft ? "bg-amber-500/20 text-amber-500" : "bg-green-500/20 text-green-500"
                              )}>{isEnded ? 'Завершено' : isDraft ? 'Черновик' : 'Активно'}</Badge>
                              {!poll.isAnonymous && <Badge variant="outline" className="text-[8px] font-black uppercase tracking-widest rounded-full h-5 bg-primary/10 text-primary border-none shadow-none">Публичное</Badge>}
                          </div>
                      </div>
                      <DropdownMenu>
                          <DropdownMenuTrigger asChild>
                              <Button size="icon" variant="ghost" className="h-9 w-9 rounded-full bg-white/5 hover:bg-white/15 border-none shadow-none shrink-0"><MoreVertical className="h-4 w-4 text-white/40" /></Button>
                          </DropdownMenuTrigger>
                          <DropdownMenuPortal>
                              <DropdownMenuContent align="end" className="rounded-2xl bg-[#0a0e17]/95 backdrop-blur-3xl border-white/10 shadow-2xl z-[160] w-56 p-1.5">
                                  {isDraft && (poll.creatorId === currentUser.id || isHost) && (
                                      <DropdownMenuItem onSelect={() => handleAction(poll.id, 'start')} className="rounded-xl font-bold px-3 py-2.5 text-xs text-white">
                                          <PlayCircle className="h-4 w-4 mr-3 text-green-500" /> Запустить
                                      </DropdownMenuItem>
                                  )}
                                  {hasVoted && !isEnded && (
                                      <DropdownMenuItem onSelect={() => handleAction(poll.id, 'revote')} className="rounded-xl font-bold px-3 py-2.5 text-xs text-white">
                                          <RotateCcw className="h-4 w-4 mr-3 text-primary" /> Изменить голос
                                      </DropdownMenuItem>
                                  )}
                                  {isEnded && (isHost || poll.creatorId === currentUser.id) && (
                                      <DropdownMenuItem onSelect={() => handleAction(poll.id, 'restart')} className="rounded-xl font-bold px-3 py-2.5 text-xs text-white">
                                          <RotateCcw className="h-4 w-4 mr-3 text-primary" /> Перезапустить
                                      </DropdownMenuItem>
                                  )}
                                  {isHost && !isEnded && !isDraft && (
                                      <DropdownMenuItem onSelect={() => handleAction(poll.id, 'end')} className="rounded-xl font-bold px-3 py-2.5 text-xs text-amber-500">
                                          <StopCircle className="h-4 w-4 mr-3" /> Остановить
                                      </DropdownMenuItem>
                                  )}
                                  {(isHost || poll.creatorId === currentUser.id) && (
                                      <>
                                        <DropdownMenuSeparator className="bg-white/10" />
                                        <DropdownMenuItem onSelect={() => handleAction(poll.id, 'delete')} className="rounded-xl font-bold px-3 py-2.5 text-xs text-red-500">
                                            <Trash2 className="h-4 w-4 mr-3" /> Удалить
                                        </DropdownMenuItem>
                                      </>
                                  )}
                              </DropdownMenuContent>
                          </DropdownMenuPortal>
                      </DropdownMenu>
                  </div>

                  <div className="grid grid-cols-1 gap-2.5">
                      {poll.options.map((opt, idx) => {
                          const count = Object.values(votes).filter(v => v === idx).length;
                          const percent = totalVotes > 0 ? Math.round((count / totalVotes) * 100) : 0;
                          const votedForThis = votes[currentUser.id] === idx;
                          
                          // Get voters for this specific option
                          const votersForOption = !poll.isAnonymous ? Object.entries(votes)
                            .filter(([_, vIdx]) => vIdx === idx)
                            .map(([uId]) => allParticipants.find(p => p.id === uId) || { id: uId, name: 'Участник', avatar: '' })
                            : [];

                          return (
                              <div key={idx} className="space-y-2">
                                <button 
                                    disabled={isEnded || isDraft || (hasVoted && !isEnded)} 
                                    onClick={() => handleVote(poll.id, idx)} 
                                    className={cn(
                                        "w-full text-left p-4 rounded-[1.5rem] border transition-all duration-500 relative overflow-hidden group", 
                                        votedForThis ? "border-primary bg-primary/10 shadow-lg" : "border-white/5 bg-white/5 hover:bg-white/10"
                                    )}
                                >
                                    <div className="relative z-10 flex flex-col gap-1.5">
                                        <div className="flex justify-between items-center">
                                            <span className="text-xs font-bold truncate max-w-[80%] text-white/90">{opt}</span>
                                            <span className="text-[10px] font-black opacity-40">{percent}%</span>
                                        </div>
                                        <div className="h-1 w-full bg-white/5 rounded-full overflow-hidden">
                                            <div className="h-full bg-primary shadow-[0_0_10px_rgba(67,56,202,0.6)] transition-all duration-1000 ease-out" style={{ width: `${percent}%` }} />
                                        </div>
                                    </div>
                                </button>
                                
                                {isExpanded && !poll.isAnonymous && votersForOption.length > 0 && (
                                    <div className="flex flex-wrap gap-1 px-4 animate-in slide-in-from-top-2 duration-300">
                                        <TooltipProvider delayDuration={0}>
                                            {votersForOption.map(voter => (
                                                <Tooltip key={voter.id}>
                                                    <TooltipTrigger asChild>
                                                        <Avatar className="h-6 w-6 border border-white/10 ring-2 ring-background">
                                                            <AvatarImage src={voter.avatar} className="object-cover" />
                                                            <AvatarFallback className="text-[8px]">{voter.name[0]}</AvatarFallback>
                                                        </Avatar>
                                                    </TooltipTrigger>
                                                    <TooltipContent className="bg-black/80 backdrop-blur-md border-white/10 rounded-lg text-[10px] font-bold">
                                                        {voter.name}
                                                    </TooltipContent>
                                                </Tooltip>
                                            ))}
                                        </TooltipProvider>
                                    </div>
                                )}
                              </div>
                          );
                      })}
                  </div>

                  <div className="flex justify-between items-center px-1">
                      <div className="flex items-center gap-4 text-[8px] font-black text-white/20 uppercase tracking-[0.25em]">
                          <span className="flex items-center gap-2">
                              <Activity className="h-3 w-3" /> {totalVotes} голосов
                          </span>
                          {!isEnded && !isDraft && (
                              <span>Цель: {participantsCount}</span>
                          )}
                      </div>
                      
                      {!poll.isAnonymous && totalVotes > 0 && (
                          <Button 
                            variant="ghost" 
                            size="sm" 
                            onClick={() => toggleExpand(poll.id)}
                            className="h-7 rounded-full text-[9px] font-black uppercase tracking-widest text-white/40 hover:text-white hover:bg-white/5 border-none shadow-none"
                          >
                              {isExpanded ? <ChevronUp className="h-3 w-3 mr-1.5" /> : <ChevronDown className="h-3 w-3 mr-1.5" />}
                              Статистика
                          </Button>
                      )}
                  </div>
                </div>
              );
            })
          )}
        </div>
      </ScrollArea>
    </div>
  );
}