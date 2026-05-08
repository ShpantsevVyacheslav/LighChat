'use client';

import React, { useMemo, useState, useCallback } from 'react';
import { doc, updateDoc } from 'firebase/firestore';
import type { User, Conversation } from '@/lib/types';
import { ROLES } from '@/lib/constants';
import { useFirestore } from '@/firebase';
import { useToast } from '@/hooks/use-toast';
import { userAvatarListUrl } from '@/lib/user-avatar-display';
import {
  adminIdsForFirestoreWrite,
  buildGroupMemberRemovalUpdate,
  effectiveGroupAdminIds,
} from '@/lib/group-chat-member-updates';
import { createOrOpenDirectChat } from '@/lib/direct-chat';
import {
  collectParticipantDevicesV2,
  createE2eeSessionDocV2,
  getOrCreateDeviceIdentityV2,
  publishE2eeDeviceV2,
} from '@/lib/e2ee';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { ScrollArea } from '@/components/ui/scroll-area';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { ArrowLeft, Crown, MessageCircle, MoreVertical, ShieldOff, UserX } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';
import { canShowOnlineStatus } from '@/lib/presence-visibility';

function resolveGroupMemberUser(
  id: string,
  allUsers: User[],
  currentUser: User,
  participantInfo: Conversation['participantInfo']
): User {
  const fromList = allUsers.find((u) => u.id === id);
  if (fromList) return fromList;
  if (id === currentUser.id) return currentUser;
  const info = participantInfo[id];
  return {
    id,
    name: info?.name ?? 'Member',
    username: '',
    email: '',
    avatar: info?.avatar ?? '',
    phone: '',
    deletedAt: null,
    createdAt: '',
    role: undefined,
  };
}

type GroupChatParticipantsManageViewProps = {
  conversation: Conversation;
  allUsers: User[];
  currentUser: User;
  isGroupAdmin: boolean;
  onBack: () => void;
  onSelectPersonalChat: (conversationId: string) => void;
  onCloseProfileSheet: () => void;
};

/**
 * Полноэкранный слой внутри sheet профиля группы: список участников с действиями админа.
 */
export function GroupChatParticipantsManageView({
  conversation,
  allUsers,
  currentUser,
  isGroupAdmin,
  onBack,
  onSelectPersonalChat,
  onCloseProfileSheet,
}: GroupChatParticipantsManageViewProps) {
  const firestore = useFirestore();
  const { toast } = useToast();
  const { t } = useI18n();
  const [busyId, setBusyId] = useState<string | null>(null);

  const rows = useMemo(() => {
    const ids = [...new Set(conversation.participantIds)];
    return ids.map((id) => resolveGroupMemberUser(id, allUsers, currentUser, conversation.participantInfo));
  }, [conversation.participantIds, conversation.participantInfo, allUsers, currentUser]);

  const runWithBusy = useCallback(
    async (uid: string, fn: () => Promise<void>) => {
      if (!firestore) return;
      setBusyId(uid);
      try {
        await fn();
      } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : t('chat.groupMembers.actionFailed');
        toast({ variant: 'destructive', title: t('common.error'), description: msg });
      } finally {
        setBusyId(null);
      }
    },
    [firestore, toast]
  );

  const handleRemove = (memberId: string) => {
    if (memberId === conversation.createdByUserId) {
      toast({
        variant: 'destructive',
        title: t('chat.groupMembers.cannotRemoveCreatorTitle'),
        description: t('chat.groupMembers.cannotRemoveCreatorDesc'),
      });
      return;
    }
    void runWithBusy(memberId, async () => {
      if (!firestore) return;
      const payload = buildGroupMemberRemovalUpdate(conversation, memberId);
      // Phase 0 safety fix (v2 variant): при исключении участника из
      // E2EE-группы создаём новый v2 session-doc с обёртками свежего ключа
      // ТОЛЬКО для оставшихся участников. Без этого: эпоху подняли,
      // но нового ключа нет → отправка падает на unwrap; либо, что хуже,
      // исключённый участник может расшифровывать будущие сообщения под
      // старым ключом.
      //
      // Порядок важен: сначала публикуем session-doc, потом update. Если
      // update упадёт — останется «сиротский» session для нового эпоха, но
      // эпоха не взведена, и чат продолжает работать на старом ключе.
      if (conversation.e2eeEnabled) {
        const nextEpoch = (conversation.e2eeKeyEpoch ?? 0) + 1;
        const remaining = (payload.participantIds as string[]) ?? [];
        const uid = currentUser.id;
        if (!remaining.includes(uid)) {
          throw new Error('E2EE: creator is unexpectedly missing from remaining participants');
        }
        const identity = await getOrCreateDeviceIdentityV2();
        await publishE2eeDeviceV2(firestore, uid, identity);
        const bundles = await collectParticipantDevicesV2(firestore, remaining);
        await createE2eeSessionDocV2(
          firestore,
          conversation.id,
          nextEpoch,
          identity,
          uid,
          bundles
        );
      }
      await updateDoc(doc(firestore, 'conversations', conversation.id), payload);
      toast({ title: t('chat.groupMembers.memberRemoved') });
    });
  };

  const handleToggleAdminRole = (targetId: string) => {
    if (targetId === conversation.createdByUserId) {
      toast({
        variant: 'destructive',
        title: t('chat.groupMembers.actionForbiddenTitle'),
        description: t('chat.groupMembers.actionForbiddenDesc'),
      });
      return;
    }
    const eff = effectiveGroupAdminIds(conversation);
    const wasAdmin = eff.has(targetId);
    if (wasAdmin && eff.size <= 1) {
      toast({
        variant: 'destructive',
        title: t('chat.groupMembers.needAdminTitle'),
        description: t('chat.groupMembers.needAdminDesc'),
      });
      return;
    }
    if (wasAdmin) eff.delete(targetId);
    else eff.add(targetId);
    const toWrite = adminIdsForFirestoreWrite(conversation, eff);
    void runWithBusy(targetId, async () => {
      if (!firestore) return;
      await updateDoc(doc(firestore, 'conversations', conversation.id), { adminIds: toWrite });
      toast({ title: wasAdmin ? t('chat.groupMembers.adminDemoted') : t('chat.groupMembers.adminPromoted') });
    });
  };

  const handleWritePrivate = (p: User) => {
    if (!firestore || p.id === currentUser.id) return;
    void (async () => {
      try {
        const id = await createOrOpenDirectChat(firestore, currentUser, p);
        onSelectPersonalChat(id);
        onCloseProfileSheet();
      } catch (e) {
        console.error(e);
        toast({ variant: 'destructive', title: t('chat.groupMembers.chatOpenError') });
      }
    })();
  };

  return (
    <div className="flex h-full min-h-0 flex-1 flex-col bg-background">
      <div className="flex shrink-0 items-center gap-2 border-b px-3 py-3 pr-4 pt-[max(0.75rem,env(safe-area-inset-top,0px))]">
        <Button
          type="button"
          variant="ghost"
          size="icon"
          className="shrink-0 rounded-full"
          onClick={onBack}
          aria-label={t('chat.groupMembers.backAria')}
        >
          <ArrowLeft className="h-5 w-5" />
        </Button>
        <div className="min-w-0 flex-1">
          <h2 className="truncate text-lg font-bold">{t('chat.groupMembers.title')} ({rows.length})</h2>
          <p className="truncate text-xs text-muted-foreground">{t('chat.groupMembers.subtitle')}</p>
        </div>
      </div>
      <ScrollArea className="min-h-0 flex-1">
        <div className="space-y-1 p-3 pb-[max(1rem,env(safe-area-inset-bottom,0px))]">
          {rows.map((p) => {
            const isCreator = p.id === conversation.createdByUserId;
            const isElevatedAdmin =
              isCreator || (conversation.adminIds || []).includes(p.id);
            const eff = effectiveGroupAdminIds(conversation);
            const isTargetAdmin = eff.has(p.id);
            const showAdminMenu =
              isGroupAdmin && p.id !== currentUser.id && !p.deletedAt;
            const loading = busyId === p.id;

            return (
              <div
                key={p.id}
                role="button"
                tabIndex={0}
                className={cn(
                  'flex items-center justify-between gap-2 rounded-2xl p-3 transition-colors',
                  p.id !== currentUser.id && 'cursor-pointer hover:bg-muted/70 active:bg-muted'
                )}
                onClick={() => {
                  if (p.id !== currentUser.id) handleWritePrivate(p);
                }}
                onKeyDown={(e) => {
                  if (e.key !== 'Enter' && e.key !== ' ') return;
                  e.preventDefault();
                  if (p.id !== currentUser.id) handleWritePrivate(p);
                }}
              >
                <div className="flex min-w-0 items-center gap-3">
                  <Avatar className="relative h-11 w-11 shrink-0 border border-border/40 shadow-sm">
                    <AvatarImage src={userAvatarListUrl(p)} className="object-cover" />
                    <AvatarFallback>{p.name.charAt(0)}</AvatarFallback>
                    {p.online && canShowOnlineStatus(p) && !p.deletedAt && (
                      <div className="absolute bottom-0.5 right-0.5 h-2.5 w-2.5 rounded-full border-2 border-background bg-green-500" />
                    )}
                  </Avatar>
                  <div className="min-w-0">
                    <div className="truncate text-sm font-bold leading-tight">{p.name}</div>
                    {p.role && p.role !== 'worker' && !p.deletedAt ? (
                      <div className="text-[10px] font-medium uppercase tracking-wider text-muted-foreground">
                        {ROLES[p.role]}
                      </div>
                    ) : null}
                  </div>
                </div>
                <div className="flex shrink-0 items-center gap-1.5">
                  {isCreator ? (
                    <Badge
                      variant="secondary"
                      className="rounded-full border border-amber-500/25 bg-amber-500/10 px-2 py-0.5 text-[9px] font-bold uppercase text-amber-700 dark:text-amber-400"
                    >
                      {t('chat.groupMembers.creator')}
                    </Badge>
                  ) : isElevatedAdmin && !isCreator ? (
                    <Badge variant="outline" className="rounded-full px-2 py-0.5 text-[9px] font-bold uppercase">
                      {t('chat.groupMembers.admin')}
                    </Badge>
                  ) : null}
                  {showAdminMenu ? (
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button
                          type="button"
                          variant="ghost"
                          size="icon"
                          disabled={loading}
                          className="h-9 w-9 shrink-0 rounded-full"
                          aria-label={t('chat.groupMembers.actionsAria')}
                          onClick={(e) => e.stopPropagation()}
                        >
                          <MoreVertical className="h-4 w-4" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end" className="rounded-xl" onClick={(e) => e.stopPropagation()}>
                        <DropdownMenuItem
                          onSelect={() => handleWritePrivate(p)}
                          className="cursor-pointer rounded-lg"
                        >
                          <MessageCircle className="mr-2 h-4 w-4" />
                          {t('chat.groupMembers.writePrivate')}
                        </DropdownMenuItem>
                        <DropdownMenuItem
                          onSelect={() => handleToggleAdminRole(p.id)}
                          disabled={isCreator}
                          className="cursor-pointer rounded-lg"
                        >
                          {isTargetAdmin ? (
                            <>
                              <ShieldOff className="mr-2 h-4 w-4" />
                              {t('chat.groupMembers.demoteAdmin')}
                            </>
                          ) : (
                            <>
                              <Crown className="mr-2 h-4 w-4" />
                              {t('chat.groupMembers.promoteAdmin')}
                            </>
                          )}
                        </DropdownMenuItem>
                        <DropdownMenuItem
                          onSelect={() => handleRemove(p.id)}
                          disabled={isCreator}
                          className="cursor-pointer rounded-lg text-destructive focus:text-destructive"
                        >
                          <UserX className="mr-2 h-4 w-4" />
                          {t('chat.groupMembers.removeFromGroup')}
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  ) : null}
                </div>
              </div>
            );
          })}
        </div>
      </ScrollArea>
    </div>
  );
}
