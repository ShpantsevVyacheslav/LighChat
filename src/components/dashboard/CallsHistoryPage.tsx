'use client';

import React, { useMemo, useState } from 'react';
import { useAuth } from '@/hooks/use-auth';
import type { User, Call, UserCallsIndex } from '@/lib/types';
import {
  useDoc,
  useFirestore,
  useMemoFirebase,
  useCallsByDocumentIds,
  useUsersByDocumentIds,
  useUser as useFirebaseAuthUser,
} from '@/firebase';
import { doc } from 'firebase/firestore';
import { cn, formatDuration } from '@/lib/utils';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
  Phone,
  Video,
  ArrowUpRight,
  ArrowDownLeft,
  Search,
  Calendar as CalendarIcon,
  Clock,
  HelpCircle,
} from 'lucide-react';
import Link from 'next/link';
import { format, isToday, isYesterday, parseISO, differenceInSeconds } from 'date-fns';
import { ru } from 'date-fns/locale';
import { Skeleton } from '@/components/ui/skeleton';
import { Separator } from '@/components/ui/separator';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog';
import { initiateCall } from '@/components/chat/AudioCallOverlay';
import { useToast } from '@/hooks/use-toast';
/**
 * История звонков (завершённые и отклонённые). Доступ с нижней навигации «Звонки».
 */
export function CallsHistoryPage() {
  const { user: currentUser } = useAuth();
  const { user: firebaseAuthUser } = useFirebaseAuthUser();
  const authUid = firebaseAuthUser?.uid ?? currentUser?.id ?? null;
  const currentUserForFirestore = useMemo((): User | null => {
    if (!currentUser) return null;
    if (!authUid) return currentUser;
    if (currentUser.id === authUid) return currentUser;
    return { ...currentUser, id: authUid };
  }, [currentUser, authUid]);

  const firestore = useFirestore();
  const { toast } = useToast();
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCall, setSelectedCall] = useState<Call | null>(null);

  const userCallsIndexRef = useMemoFirebase(() => {
    if (!firestore || !authUid) return null;
    return doc(firestore, 'userCalls', authUid);
  }, [firestore, authUid]);
  const { data: userCallsIndex } = useDoc<UserCallsIndex>(userCallsIndexRef);
  const callIds = useMemo(() => userCallsIndex?.callIds || [], [userCallsIndex]);

  const { data: rawCalls, isLoading: isLoadingCalls } = useCallsByDocumentIds(firestore, callIds);

  const userIdsFromCalls = useMemo(() => {
    const ids = new Set<string>();
    if (authUid) ids.add(authUid);
    rawCalls?.forEach((call) => {
      if (call.callerId) ids.add(call.callerId);
      if (call.receiverId) ids.add(call.receiverId);
    });
    return [...ids];
  }, [authUid, rawCalls]);

  const { usersById, isLoading: isLoadingUsers } = useUsersByDocumentIds(firestore, userIdsFromCalls);
  const allUsers = useMemo(() => [...usersById.values()], [usersById]);

  const calls = useMemo(() => {
    if (!rawCalls) return [];
    return [...rawCalls]
      .filter((call) => call.status === 'ended' || call.status === 'rejected')
      .sort((a, b) => parseISO(b.createdAt).getTime() - parseISO(a.createdAt).getTime());
  }, [rawCalls]);

  const filteredCalls = useMemo(() => {
    if (!calls || !authUid) return [];
    return calls.filter((call) => {
      const isOutgoing = call.callerId === authUid;
      const otherId = isOutgoing ? call.receiverId : call.callerId;
      const foundUser = allUsers.find((u) => u.id === otherId);
      const name =
        foundUser?.name || (isOutgoing ? call.receiverName : call.callerName) || 'Неизвестный';
      return name.toLowerCase().includes(searchTerm.toLowerCase());
    });
  }, [calls, searchTerm, allUsers, authUid]);

  const formatCallDate = (dateStr: string) => {
    const date = parseISO(dateStr);
    if (isToday(date)) return format(date, 'HH:mm');
    if (isYesterday(date)) return 'Вчера';
    return format(date, 'dd.MM.yy');
  };

  const handleCallUser = async (targetUserId: string, isVideo: boolean) => {
    if (!firestore || !currentUserForFirestore) return;
    const peer = allUsers.find((u) => u.id === targetUserId);
    if (!peer) {
      toast({
        variant: 'destructive',
        title: 'Не удалось начать звонок',
        description: 'Данные пользователя не загружены.',
      });
      return;
    }
    await initiateCall(firestore, currentUserForFirestore, peer, isVideo, toast);
  };

  const listLoading = isLoadingUsers || isLoadingCalls;

  const callDetailsPeer = useMemo(() => {
    if (!selectedCall || !authUid) return null;
    const peerId =
      selectedCall.callerId === authUid ? selectedCall.receiverId : selectedCall.callerId;
    const peer = allUsers.find((u) => u.id === peerId);
    const peerName =
      peer?.name ||
      (selectedCall.callerId === authUid ? selectedCall.receiverName : selectedCall.callerName) ||
      'Неизвестный';
    return { peerId, peerName, peerAvatar: peer?.avatar };
  }, [selectedCall, authUid, allUsers]);

  return (
    <div className="mx-auto flex h-full min-h-0 w-full max-w-2xl flex-col">
      <div className="shrink-0 border-b border-border/60 px-1 pb-3 pt-1">
        <div className="flex items-center justify-between gap-2 px-2 pb-2 pt-1">
          <h1 className="text-lg font-bold tracking-tight">Звонки</h1>
          <Link
            href="/dashboard/calls/help"
            className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
            aria-label="Справка по звонкам"
          >
            <HelpCircle className="h-5 w-5" />
          </Link>
        </div>
        <div className="relative min-w-0 px-2">
          <Search className="pointer-events-none absolute left-5 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            placeholder="Поиск по имени..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="h-10 w-full rounded-full border-black/10 bg-background/50 pl-10 text-sm backdrop-blur-sm dark:border-white/12"
          />
        </div>
      </div>

      <div className="min-h-0 flex-1 overflow-y-auto scrolling-touch scrollbar-hide">
        <div className="p-2">
          {listLoading ? (
            <div className="space-y-3 p-2">
              {[...Array(6)].map((_, i) => (
                <div key={i} className="flex items-center gap-3">
                  <Skeleton className="h-12 w-12 rounded-full" />
                  <div className="space-y-2">
                    <Skeleton className="h-4 w-32" />
                    <Skeleton className="h-3 w-24" />
                  </div>
                </div>
              ))}
            </div>
          ) : filteredCalls.length === 0 ? (
            <div className="p-12 text-center text-muted-foreground">
              <p className="text-sm">История звонков пуста.</p>
            </div>
          ) : (
            filteredCalls.map((call) => {
              const isOutgoing = call.callerId === authUid;
              const otherId = isOutgoing ? call.receiverId : call.callerId;
              const foundUser = allUsers.find((u) => u.id === otherId);
              const displayName =
                foundUser?.name || (isOutgoing ? call.receiverName : call.callerName) || 'Неизвестный';
              const avatar = foundUser?.avatar;
              const isRejected = call.status === 'rejected';
              const isMissed = !isOutgoing && isRejected;

              return (
                    <div
                      key={call.id}
                      className="group flex w-full cursor-pointer items-center gap-3 rounded-xl p-2 transition-colors hover:bg-white/10 dark:hover:bg-white/[0.06]"
                      onClick={() => setSelectedCall(call)}
                    >
                      <Avatar className="h-12 w-12 shrink-0">
                        <AvatarImage src={avatar} alt={displayName} className="object-cover" />
                        <AvatarFallback>{displayName.charAt(0)}</AvatarFallback>
                      </Avatar>
                      <div className="flex min-w-0 flex-1 items-center justify-between">
                        <div className="min-w-0">
                          <p className={cn('truncate text-sm font-semibold', isMissed && 'text-destructive')}>
                            {displayName}
                          </p>
                          <div className="flex items-center gap-1 text-[10px] text-muted-foreground">
                            {isOutgoing ? (
                              <ArrowUpRight
                                className={cn('h-3 w-3', isRejected ? 'text-destructive' : 'text-blue-500')}
                              />
                            ) : (
                              <ArrowDownLeft
                                className={cn('h-3 w-3', isMissed ? 'text-destructive' : 'text-green-500')}
                              />
                            )}
                            <span>{formatCallDate(call.createdAt)}</span>
                            <Separator orientation="vertical" className="mx-1 h-2" />
                            {call.isVideo ? <Video className="h-2.5 w-2.5" /> : <Phone className="h-2.5 w-2.5" />}
                            {isRejected && (
                              <span className="ml-1 font-medium text-destructive">
                                {isOutgoing ? 'Отклонен' : 'Пропущен'}
                              </span>
                            )}
                          </div>
                        </div>
                        <div className="flex shrink-0 items-center gap-1">
                          <Button
                            variant="ghost"
                            size="icon"
                            className="h-8 w-8 rounded-full border-none text-primary shadow-none hover:bg-primary/10"
                            onClick={(e) => {
                              e.stopPropagation();
                              void handleCallUser(otherId, false);
                            }}
                          >
                            <Phone className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="icon"
                            className="h-8 w-8 rounded-full border-none text-primary shadow-none hover:bg-primary/10"
                            onClick={(e) => {
                              e.stopPropagation();
                              void handleCallUser(otherId, true);
                            }}
                          >
                            <Video className="h-4 w-4" />
                          </Button>
                        </div>
                      </div>
                    </div>
              );
            })
          )}
        </div>
      </div>

      <Dialog open={!!selectedCall} onOpenChange={(open) => !open && setSelectedCall(null)}>
        <DialogContent className="rounded-2xl border-none shadow-2xl sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Сведения о звонке</DialogTitle>
            <DialogDescription>Детальная статистика вызова</DialogDescription>
          </DialogHeader>
          {selectedCall && authUid && callDetailsPeer && (
            <div className="space-y-6 py-4">
              <div className="flex flex-col items-center gap-4">
                <Avatar className="h-20 w-20">
                  <AvatarImage
                    src={callDetailsPeer.peerAvatar}
                    alt={callDetailsPeer.peerName}
                    className="object-cover"
                  />
                  <AvatarFallback>{callDetailsPeer.peerName.charAt(0)}</AvatarFallback>
                </Avatar>
                <div className="text-center">
                  <h3 className="text-xl font-bold">{callDetailsPeer.peerName}</h3>
                  <div className="mt-1 flex items-center justify-center gap-2">
                    <span className="inline-flex items-center rounded-full border px-2 py-0.5 text-xs">
                      {selectedCall.isVideo ? (
                        <Video className="mr-1 h-3 w-3" />
                      ) : (
                        <Phone className="mr-1 h-3 w-3" />
                      )}
                      {selectedCall.isVideo ? 'Видеозвонок' : 'Аудиозвонок'}
                    </span>
                    <span
                      className={cn(
                        'inline-flex rounded-full px-2 py-0.5 text-xs text-white',
                        selectedCall.status === 'rejected' ? 'bg-destructive' : 'bg-green-500'
                      )}
                    >
                      {selectedCall.status === 'rejected'
                        ? selectedCall.callerId === authUid
                          ? 'Отклонен'
                          : 'Пропущен'
                        : 'Завершен'}
                    </span>
                  </div>
                </div>
              </div>
              <div className="grid gap-4 rounded-2xl bg-muted/50 p-4 text-sm">
                <div className="flex items-center justify-between">
                  <span className="flex items-center gap-2 text-muted-foreground">
                    <CalendarIcon className="h-4 w-4" /> Дата:
                  </span>
                  <span className="font-semibold">
                    {format(parseISO(selectedCall.createdAt), 'dd MMMM yyyy', { locale: ru })}
                  </span>
                </div>
                {selectedCall.startedAt && selectedCall.endedAt && (
                  <div className="flex items-center justify-between border-t border-border/20 pt-2">
                    <span className="flex items-center gap-2 text-muted-foreground">
                      <Clock className="h-4 w-4" /> Длительность:
                    </span>
                    <span className="font-bold text-primary">
                      {formatDuration(
                        differenceInSeconds(parseISO(selectedCall.endedAt), parseISO(selectedCall.startedAt))
                      )}
                    </span>
                  </div>
                )}
              </div>
              <div className="flex gap-2">
                <Button
                  className="h-12 flex-1 rounded-full font-bold"
                  onClick={() => {
                    const otherId =
                      selectedCall.callerId === authUid ? selectedCall.receiverId : selectedCall.callerId;
                    void handleCallUser(otherId, false);
                    setSelectedCall(null);
                  }}
                >
                  <Phone className="mr-2 h-4 w-4" /> Позвонить
                </Button>
                <Button
                  variant="secondary"
                  className="h-12 flex-1 rounded-full font-bold"
                  onClick={() => {
                    const otherId =
                      selectedCall.callerId === authUid ? selectedCall.receiverId : selectedCall.callerId;
                    void handleCallUser(otherId, true);
                    setSelectedCall(null);
                  }}
                >
                  <Video className="mr-2 h-4 w-4" /> Видео
                </Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
