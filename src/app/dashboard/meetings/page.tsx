
'use client';

import React, { useState, useMemo } from 'react';
import { useAuth } from '@/hooks/use-auth';
import { useFirestore, useCollection, useDoc, useMemoFirebase } from '@/firebase';
import { collection, query, where, documentId, doc, setDoc } from 'firebase/firestore';
import type { Meeting, UserMeetingsIndex } from '@/lib/types';
import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Loader2, Plus, Link as LinkIcon, Users, History, ArrowRight, Settings, ShieldCheck, ShieldAlert, MoreVertical, Trash2, Video, Clock, Calendar as CalendarIcon, Ban } from 'lucide-react';
import { format, parseISO, addMinutes, isAfter } from 'date-fns';
import { ru } from 'date-fns/locale';
import { Skeleton } from '@/components/ui/skeleton';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Switch } from '@/components/ui/switch';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useToast } from '@/hooks/use-toast';
import { Label } from '@/components/ui/label';
import { Card, CardHeader, CardTitle, CardDescription, CardFooter } from '@/components/ui/card';
const DURATION_OPTIONS = [
  { label: '15 минут', value: '15' },
  { label: '30 минут', value: '30' },
  { label: '1 час', value: '60' },
  { label: '2 часа', value: '120' },
  { label: '4 часа', value: '240' },
  { label: 'Без ограничений', value: 'infinity' },
];

export default function MeetingsDashboardPage() {
  const [meetingName, setMeetingName] = useState('');
  const [duration, setDuration] = useState('60');
  const [isPrivate, setIsPrivate] = useState(false);
  const [isCreating, setIsCreating] = useState(false);
  
  const { user, isLoading: isAuthLoading } = useAuth();
  const firestore = useFirestore();
  const router = useRouter();
  const { toast } = useToast();

  const userMeetingsIndexRef = useMemoFirebase(() => {
    if (!firestore || !user || !user.id) return null;
    return doc(firestore, 'userMeetings', user.id);
  }, [firestore, user]);
  
  const { data: userMeetingsIndex, isLoading: isIndexLoading } = useDoc<UserMeetingsIndex>(userMeetingsIndexRef);
  const meetingIds = useMemo(() => userMeetingsIndex?.meetingIds || [], [userMeetingsIndex]);

  const meetingsQuery = useMemoFirebase(() => {
    if (!firestore || !user || meetingIds.length === 0) return null;
    return query(
      collection(firestore, 'meetings'),
      where(documentId(), 'in', meetingIds.slice(-30))
    );
  }, [firestore, user, meetingIds]);

  const { data: historyMeetings, isLoading: isHistoryLoading } = useCollection<Meeting>(meetingsQuery);

  const sortedHistory = useMemo(() => {
    if (!historyMeetings) return [];
    return [...historyMeetings].sort((a, b) => parseISO(b.createdAt).getTime() - parseISO(a.createdAt).getTime());
  }, [historyMeetings]);

  const handleCreateMeeting = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!meetingName.trim() || !user || !firestore) return;

    setIsCreating(true);
    const meetingId = `meet-${Date.now()}`;
    const createdAt = new Date();
    let expiresAt: Date | null = null;
    
    if (duration !== 'infinity') {
        expiresAt = addMinutes(createdAt, parseInt(duration, 10));
    }
    
    try {
      const meetingData: Meeting = {
        id: meetingId,
        name: meetingName.trim(),
        hostId: user.id,
        createdAt: createdAt.toISOString(),
        expiresAt: expiresAt?.toISOString() || null,
        status: 'active',
        isPrivate: isPrivate,
      };

      await setDoc(doc(firestore, 'meetings', meetingId), meetingData);
      toast({ title: 'Встреча создана', description: 'Перенаправляем в комнату...' });
      router.push(`/meetings/${meetingId}`);
    } catch (error: unknown) {
      console.error("Meeting creation error:", error);
      const message =
        typeof error === 'object' &&
        error != null &&
        'message' in error &&
        typeof (error as { message?: unknown }).message === 'string'
          ? (error as { message: string }).message
          : 'Unknown error';
      toast({ variant: 'destructive', title: 'Ошибка', description: message });
      setIsCreating(false);
    }
  };

  if (isAuthLoading) {
      return (
          <div className="flex h-[60vh] items-center justify-center">
              <Loader2 className="h-8 w-8 animate-spin text-primary" />
          </div>
      );
  }

  return (
    <div className="max-w-5xl mx-auto space-y-8 pb-20 font-body">
      <div className="flex items-center gap-2">
        <div className="min-w-0">
          <h1 className="text-2xl sm:text-3xl font-bold flex items-center gap-2 leading-tight">
            <Video className="text-primary h-6 w-6 sm:h-8 sm:w-8" /> Видеовстречи
          </h1>
          <p className="text-xs sm:text-sm text-muted-foreground">Создавайте конференции и управляйте доступом участников.</p>
        </div>
      </div>

      <div className="grid md:grid-cols-2 gap-8">
        <section className="space-y-4">
          <h2 className="text-lg font-semibold leading-none tracking-tight">Новая встреча</h2>
            <form onSubmit={handleCreateMeeting} className="space-y-6">
              <div className="space-y-2">
                <Label htmlFor="name">Название встречи</Label>
                <Input 
                  id="name" 
                  placeholder="Напр: Обсуждение логистики" 
                  value={meetingName}
                  onChange={(e) => setMeetingName(e.target.value)}
                  className="rounded-2xl h-12"
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                    <Label>Длительность</Label>
                    <Select value={duration} onValueChange={setDuration}>
                    <SelectTrigger className="rounded-2xl h-12">
                        <SelectValue placeholder="Выберите" />
                    </SelectTrigger>
                    <SelectContent className="rounded-2xl">
                        {DURATION_OPTIONS.map((opt) => (
                        <SelectItem key={opt.value} value={opt.value}>{opt.label}</SelectItem>
                        ))}
                    </SelectContent>
                    </Select>
                </div>
                <div className="space-y-2">
                    <Label>Тип доступа</Label>
                    <div className="flex items-center gap-3 h-12 bg-muted/30 rounded-2xl px-4 border">
                        {isPrivate ? <ShieldAlert className="h-4 w-4 text-amber-500" /> : <ShieldCheck className="h-4 w-4 text-green-500" />}
                        <span className="text-sm font-medium flex-1">{isPrivate ? 'Приватная' : 'Открытая'}</span>
                        <Switch checked={isPrivate} onCheckedChange={setIsPrivate} />
                    </div>
                </div>
              </div>
              
              <div className="p-3 bg-muted/50 rounded-2xl space-y-1">
                <p className="text-[10px] text-muted-foreground flex items-center gap-1.5 font-bold uppercase tracking-wider">
                    {isPrivate ? <ShieldAlert className="h-3 w-3" /> : <ShieldCheck className="h-3 w-3" />} 
                    Особенности {isPrivate ? 'приватной' : 'открытой'} комнаты:
                </p>
                <p className="text-[11px] text-muted-foreground">
                    {isPrivate 
                        ? 'Новые участники попадают в зал ожидания. Хост должен одобрить их вход вручную.' 
                        : 'Любой человек, имеющий ссылку, может сразу присоединиться к беседе.'}
                </p>
              </div>

              <Button type="submit" className="w-full rounded-2xl gap-2 h-14 text-lg font-bold shadow-lg shadow-primary/20" disabled={isCreating || !meetingName.trim()}>
                {isCreating ? <Loader2 className="h-5 w-5 animate-spin" /> : <Plus className="h-5 w-5" />}
                Создать встречу
              </Button>
            </form>
        </section>

        <div className="space-y-8">
          <section className="space-y-3">
            <h2 className="text-lg font-semibold leading-none tracking-tight flex items-center gap-2">
              <LinkIcon className="h-5 w-5 text-primary shrink-0" /> Зал ожидания
            </h2>
            <p className="text-sm text-muted-foreground font-medium opacity-90 leading-relaxed">
              В приватных комнатах вы полностью контролируете список участников. Пока вы не нажмете «Принять», гость будет видеть экран ожидания.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="text-lg font-semibold leading-none tracking-tight flex items-center gap-2">
              <Users className="h-5 w-5 shrink-0" /> Виртуальные фоны
            </h2>
            <p className="text-sm text-muted-foreground font-medium opacity-90 leading-relaxed">
              Участники могут размыть задний план или выбрать изображение из галереи. Также доступна загрузка собственных фонов.
            </p>
          </section>
        </div>
      </div>

      <div className="pt-8 border-t">
        <h2 className="text-xl font-bold flex items-center gap-2 mb-6">
            <History className="text-muted-foreground h-5 w-5" /> Ваша история
        </h2>

        {isIndexLoading || isHistoryLoading ? (
            <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
                {[...Array(3)].map((_, i) => (
                    <div key={i} className="space-y-3 py-1">
                        <Skeleton className="h-6 w-3/4 rounded-lg" />
                        <Skeleton className="h-4 w-1/2 rounded-lg" />
                        <Skeleton className="h-10 w-full rounded-xl" />
                    </div>
                ))}
            </div>
        ) : sortedHistory.length > 0 ? (
            <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
                {sortedHistory.map((m) => {
                    const isExpired = m.expiresAt ? isAfter(new Date(), parseISO(m.expiresAt)) : false;
                    
                    return (
                    <Card key={m.id} className={cn("rounded-3xl hover:border-primary/50 transition-all border shadow-sm flex flex-col relative group", isExpired && "opacity-60 grayscale-[0.5]")}>
                        <div className="absolute top-2 right-2 opacity-0 group-hover:opacity-100 transition-opacity">
                            <DropdownMenu>
                                <DropdownMenuTrigger asChild>
                                    <Button variant="ghost" size="icon" className="rounded-full h-8 w-8 bg-background/50 backdrop-blur-sm hover:bg-background/80">
                                        <MoreVertical className="h-4 w-4" />
                                    </Button>
                                </DropdownMenuTrigger>
                                <DropdownMenuContent align="end" className="rounded-xl shadow-xl border-border/50">
                                    {!isExpired && (
                                        <DropdownMenuItem className="rounded-xl cursor-pointer" asChild>
                                            <Link href={`/dashboard/meetings/${m.id}/edit`}>
                                                <Settings className="h-4 w-4 mr-2" /> Настройки
                                            </Link>
                                        </DropdownMenuItem>
                                    )}
                                    {(m.hostId === user?.id || isExpired) && (
                                        <DropdownMenuItem className="rounded-xl text-destructive focus:text-destructive cursor-pointer" asChild>
                                            <Link href={`/dashboard/meetings/${m.id}/delete`}>
                                                <Trash2 className="h-4 w-4 mr-2" /> Удалить
                                            </Link>
                                        </DropdownMenuItem>
                                    )}
                                </DropdownMenuContent>
                            </DropdownMenu>
                        </div>
                        <CardHeader className="pb-2">
                            <CardTitle className="text-lg truncate pr-6 leading-tight flex items-center gap-2">
                                {m.name}
                                {m.isPrivate && (
                                  <div title="Приватная">
                                    <ShieldAlert className="h-3.5 w-3.5 text-amber-500 shrink-0" />
                                  </div>
                                )}
                            </CardTitle>
                            <CardDescription className="flex items-center gap-1.5 font-medium opacity-70">
                                <Clock className="h-3 w-3" />
                                {format(parseISO(m.createdAt), 'dd MMMM, HH:mm', { locale: ru })}
                            </CardDescription>
                        </CardHeader>
                        <CardFooter className="mt-auto pt-4">
                            {isExpired ? (
                                <Button variant="outline" disabled className="w-full rounded-2xl h-11 border-dashed text-muted-foreground font-bold">
                                    <Ban className="mr-2 h-4 w-4" /> Срок истек
                                </Button>
                            ) : (
                                <Button variant="secondary" className="w-full rounded-2xl h-11 font-bold group/btn active:scale-95 transition-all" asChild>
                                    <Link href={`/meetings/${m.id}`}>
                                        Войти <ArrowRight className="ml-2 h-4 w-4 transition-transform group-hover/btn:translate-x-1" />
                                    </Link>
                                </Button>
                            )}
                        </CardFooter>
                    </Card>
                )})}
            </div>
        ) : (
            <div className="p-16 border-2 border-dashed rounded-[3rem] flex flex-col items-center justify-center text-center text-muted-foreground bg-muted/5">
                <div className="p-4 bg-muted rounded-full mb-4 opacity-40">
                    <CalendarIcon className="h-12 w-12" />
                </div>
                <p className="font-medium text-lg">История встреч пуста</p>
                <p className="text-sm opacity-60">Здесь будут отображаться ваши недавние конференции</p>
            </div>
        )}
      </div>
    </div>
  );
}
