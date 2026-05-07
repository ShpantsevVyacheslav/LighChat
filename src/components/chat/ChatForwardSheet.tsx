'use client';

import React, { useState, useMemo, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { useI18n } from '@/hooks/use-i18n';
import {
  useFirestore,
  useMemoFirebase,
  useDoc,
  useConversationsByDocumentIds,
  useUsersByDocumentIds,
} from '@/firebase';
import { collection, doc, getDoc, increment, writeBatch } from 'firebase/firestore';
import type {
  User,
  Conversation,
  ChatMessage,
  UserChatIndex,
  UserContactsIndex,
} from '@/lib/types';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
  Loader2,
  SendHorizonal,
  ArrowLeft,
  Search,
  MessageSquare,
  Quote,
  Check,
  ListChecks,
  ListX,
} from 'lucide-react';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Sheet, SheetContent } from '@/components/ui/sheet';
import { useToast } from '@/hooks/use-toast';
import { useAuth } from '@/hooks/use-auth';
import { cn } from '@/lib/utils';
import { participantListAvatarUrl } from '@/lib/user-avatar-display';
import { ruEnSubstringMatch } from '@/lib/ru-latin-search-normalize';
import { Card, CardContent } from '@/components/ui/card';
import { createOrOpenDirectChat } from '@/lib/direct-chat';

const CONTACT_KEY_PREFIX = 'contact:';

function contactSelectionKey(userId: string): string {
  return `${CONTACT_KEY_PREFIX}${userId}`;
}

function isContactSelectionKey(key: string): boolean {
  return key.startsWith(CONTACT_KEY_PREFIX);
}

function ForwardingMessagePreview({
  messages,
  allUsers,
}: {
  messages: Partial<ChatMessage>[];
  allUsers: User[];
}) {
  const { t } = useI18n();
  const stripHtml = (html?: string) => {
    if (!html) return '';
    return html.replace(/<[^>]*>/g, '').replace(/&nbsp;/g, ' ').trim();
  };

  return (
    <Card className="overflow-hidden rounded-2xl border border-primary/10 bg-white shadow-sm">
      <CardContent className="p-0">
        <div className="border-l-4 border-primary bg-primary/5 p-3 sm:p-4">
          {messages.map((message, idx) => {
            const sender = allUsers.find((u) => u.id === message.senderId);
            return (
              <div
                key={idx}
                className={cn(
                  'text-sm',
                  idx > 0 && 'mt-3 border-t border-primary/10 pt-3',
                )}
              >
                <div className="mb-1 flex items-center gap-2">
                  <Quote className="h-3 w-3 rotate-180 text-primary/40" />
                  <p className="font-bold text-foreground">{sender?.name || t('calls.unknownContact')}</p>
                </div>
                <p className="break-words pl-5 italic text-muted-foreground">
                  {message.e2ee?.ciphertext
                    ? t('chat.encryptedSyncingBanner')
                    : message.text
                      ? stripHtml(message.text)
                      : t('chatList.previewAttachment')}
                </p>
              </div>
            );
          })}
        </div>
      </CardContent>
    </Card>
  );
}

type ForwardRecipientRow =
  | {
      kind: 'conversation';
      selectionKey: string;
      conversation: Conversation;
      displayName: string;
      avatar?: string | null;
    }
  | {
      kind: 'contact';
      selectionKey: string;
      user: User;
      displayName: string;
      avatar?: string | null;
    };

/**
 * Шторка выбора получателей для пересылки: справа на десктопе, на мобильных — на весь экран (как отдельная страница).
 * Список включает чаты из индекса и контакты без существующего личного чата; поддерживается «Выбрать всех» по отфильтрованному списку.
 */
export function ChatForwardSheet() {
  const { t } = useI18n();
  const [messages, setMessages] = useState<Partial<ChatMessage>[]>([]);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [isSending, setIsSending] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [sheetOpen, setSheetOpen] = useState(true);
  const [sessionReady, setSessionReady] = useState(false);

  const { user: currentUser } = useAuth();
  const firestore = useFirestore();
  const router = useRouter();
  const { toast } = useToast();

  const userChatIndexRef = useMemoFirebase(
    () => (firestore && currentUser ? doc(firestore, 'userChats', currentUser.id) : null),
    [firestore, currentUser?.id],
  );
  const { data: userChatIndex } = useDoc<UserChatIndex>(userChatIndexRef);

  const userContactsRef = useMemoFirebase(
    () => (firestore && currentUser ? doc(firestore, 'userContacts', currentUser.id) : null),
    [firestore, currentUser?.id],
  );
  const { data: userContactsIndex } = useDoc<UserContactsIndex>(userContactsRef);

  const contactIds = useMemo(
    () => userContactsIndex?.contactIds?.filter(Boolean) ?? [],
    [userContactsIndex?.contactIds],
  );

  const forwardConversationIds = useMemo(
    () => userChatIndex?.conversationIds || [],
    [userChatIndex?.conversationIds],
  );
  const { data: rawConversations, isLoading: isLoadingConversations } = useConversationsByDocumentIds(
    firestore,
    forwardConversationIds,
  );

  const userIdsForForwardPage = useMemo(() => {
    const ids = new Set<string>();
    if (currentUser?.id) ids.add(currentUser.id);
    contactIds.forEach((id) => ids.add(id));
    rawConversations?.forEach((conv) => {
      conv.participantIds.forEach((id) => {
        if (id) ids.add(id);
      });
    });
    messages.forEach((m) => {
      if (m.senderId) ids.add(m.senderId);
    });
    return [...ids];
  }, [currentUser?.id, contactIds, rawConversations, messages]);

  const { usersById, isLoading: isLoadingUsers } = useUsersByDocumentIds(
    firestore,
    userIdsForForwardPage,
  );
  const allUsers = useMemo(() => [...usersById.values()], [usersById]);

  const conversations = useMemo(() => {
    if (!rawConversations || !currentUser) return [];

    const uniqueMap = new Map<string, Conversation>();

    rawConversations.forEach((conv) => {
      if (!conv.participantIds.includes(currentUser.id)) return;

      if (conv.isGroup) {
        uniqueMap.set(conv.id, conv);
      } else {
        const otherId = conv.participantIds.find((id) => id !== currentUser.id);
        if (otherId) {
          const otherUser = allUsers.find((u) => u.id === otherId);
          if (otherUser && !otherUser.deletedAt) {
            const existing = uniqueMap.get(otherId);
            if (
              !existing ||
              (conv.lastMessageTimestamp &&
                existing.lastMessageTimestamp &&
                conv.lastMessageTimestamp > existing.lastMessageTimestamp)
            ) {
              uniqueMap.set(otherId, conv);
            }
          }
        }
      }
    });

    return Array.from(uniqueMap.values());
  }, [rawConversations, currentUser, allUsers]);

  const dmPeerIds = useMemo(() => {
    const s = new Set<string>();
    conversations.forEach((conv) => {
      if (conv.isGroup) return;
      const peer = conv.participantIds.find((id) => id !== currentUser?.id);
      if (peer) s.add(peer);
    });
    return s;
  }, [conversations, currentUser?.id]);

  const contactOnlyUsers = useMemo(() => {
    if (!currentUser?.id) return [];
    const out: User[] = [];
    for (const cid of contactIds) {
      if (cid === currentUser.id || dmPeerIds.has(cid)) continue;
      const u = allUsers.find((x) => x.id === cid);
      if (u && !u.deletedAt) out.push(u);
    }
    return out;
  }, [contactIds, currentUser?.id, dmPeerIds, allUsers]);

  const recipientRows: ForwardRecipientRow[] = useMemo(() => {
    const rows: ForwardRecipientRow[] = [];

    for (const conv of conversations) {
      const otherParticipantId = conv.participantIds.find((id) => id !== currentUser?.id);
      const otherUser = allUsers.find((u) => u.id === otherParticipantId);
      const displayName = conv.isGroup
        ? conv.name || 'Группа'
        : otherUser?.name ||
          conv.participantInfo[otherParticipantId || '']?.name ||
          'Неизвестный чат';
      const avatar = conv.isGroup
        ? conv.photoUrl
        : participantListAvatarUrl(
            otherUser,
            conv.participantInfo[otherParticipantId || ''],
          );
      rows.push({
        kind: 'conversation',
        selectionKey: conv.id,
        conversation: conv,
        displayName,
        avatar,
      });
    }

    for (const user of contactOnlyUsers) {
      rows.push({
        kind: 'contact',
        selectionKey: contactSelectionKey(user.id),
        user,
        displayName: user.name || 'Контакт',
        avatar: user.avatarThumb || user.avatar,
      });
    }

    rows.sort((a, b) =>
      (a.displayName ?? '').localeCompare(b.displayName ?? '', 'ru', {
        sensitivity: 'base',
      }),
    );
    return rows;
  }, [conversations, contactOnlyUsers, currentUser?.id, allUsers]);

  const filteredRows = useMemo(() => {
    return recipientRows.filter((row) =>
      ruEnSubstringMatch(row.displayName || '', searchTerm),
    );
  }, [recipientRows, searchTerm]);

  useEffect(() => {
    try {
      const data = sessionStorage.getItem('forwardMessages');
      if (data) {
        const parsedMessages: Partial<ChatMessage>[] = JSON.parse(data);
        setMessages(parsedMessages);
        setSessionReady(true);
      } else {
        toast({ variant: 'destructive', title: 'Нет сообщений для пересылки' });
        router.back();
      }
    } catch (error) {
      console.error('Failed to parse messages from session storage', error);
      toast({ variant: 'destructive', title: 'Ошибка загрузки сообщений' });
      router.back();
    }
  }, [router, toast]);

  const handleClose = useCallback(() => {
    sessionStorage.removeItem('forwardMessages');
    router.back();
  }, [router]);

  const handleOpenChange = useCallback(
    (open: boolean) => {
      setSheetOpen(open);
      if (!open) handleClose();
    },
    [handleClose],
  );

  const handleGoBack = useCallback(() => {
    handleClose();
  }, [handleClose]);

  const toggleSelect = (id: string) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const selectAllFiltered = useCallback(() => {
    setSelectedIds(new Set(filteredRows.map((r) => r.selectionKey)));
  }, [filteredRows]);

  const clearSelection = useCallback(() => {
    setSelectedIds(new Set());
  }, []);

  const allFilteredSelected =
    filteredRows.length > 0 &&
    filteredRows.every((r) => selectedIds.has(r.selectionKey));

  const resolveConversationForForward = useCallback(
    async (selectionKey: string): Promise<Conversation | null> => {
      if (!firestore || !currentUser) return null;

      if (isContactSelectionKey(selectionKey)) {
        const uid = selectionKey.slice(CONTACT_KEY_PREFIX.length);
        const otherUser = allUsers.find((u) => u.id === uid);
        if (!otherUser) {
          console.warn('[ChatForwardSheet] contact user not loaded', uid);
          return null;
        }
        const convId = await createOrOpenDirectChat(firestore, currentUser, otherUser);
        const snap = await getDoc(doc(firestore, 'conversations', convId));
        if (!snap.exists()) return null;
        return { id: snap.id, ...(snap.data() as Omit<Conversation, 'id'>) };
      }

      const fromList = conversations.find((c) => c.id === selectionKey);
      if (fromList) return fromList;

      const snap = await getDoc(doc(firestore, 'conversations', selectionKey));
      if (!snap.exists()) return null;
      return { id: snap.id, ...(snap.data() as Omit<Conversation, 'id'>) };
    },
    [firestore, currentUser, allUsers, conversations],
  );

  const handleBulkForward = async () => {
    if (!firestore || !currentUser || !messages.length || selectedIds.size === 0) return;

    if (messages.some((m) => m.e2ee?.ciphertext)) {
      toast({
        variant: 'destructive',
        title: 'Пересылка недоступна',
        description: 'Сообщения со сквозным шифрованием нельзя переслать.',
      });
      return;
    }

    setIsSending(true);

    try {
      const convById = new Map<string, Conversation>();

      for (const key of selectedIds) {
        const conv = await resolveConversationForForward(key);
        if (conv?.id && !convById.has(conv.id)) convById.set(conv.id, conv);
      }

      const targets = [...convById.keys()];
      if (targets.length === 0) {
        toast({
          variant: 'destructive',
          title: 'Не удалось подготовить чаты',
          description: 'Проверьте подключение и попробуйте снова.',
        });
        setIsSending(false);
        return;
      }

      const batch = writeBatch(firestore);
      const now = new Date().toISOString();

      for (const convId of targets) {
        const conversation = convById.get(convId);
        if (!conversation) continue;

        messages.forEach((message) => {
          const senderInfo = allUsers.find((u) => u.id === message.senderId);

          const forwardedMessageData: Partial<ChatMessage> = {
            senderId: currentUser.id,
            createdAt: new Date().toISOString(),
            isDeleted: false,
            readAt: null,
            forwardedFrom: {
              name: senderInfo?.name || 'Неизвестный',
            },
            ...(message.text && { text: message.text }),
            ...(message.attachments && { attachments: message.attachments }),
          };

          const newMessageRef = doc(collection(firestore, `conversations/${convId}/messages`));
          batch.set(newMessageRef, forwardedMessageData);
        });

        const lastMessage = messages[messages.length - 1];
        let lastMessageText = 'Пересланное сообщение';
        if (messages.length > 1) {
          lastMessageText = `Переслано ${messages.length} сообщений`;
        } else if (lastMessage.text) {
          const plainText = lastMessage.text.replace(/<[^>]*>/g, '').replace(/&nbsp;/g, ' ').trim();
          lastMessageText = `Переслано: ${plainText.slice(0, 50)}${plainText.length > 50 ? '...' : ''}`;
        } else if (lastMessage.attachments?.length) {
          lastMessageText = 'Пересланное вложение';
        }

        const conversationRef = doc(firestore, 'conversations', convId);
        const unreadCountsUpdate: Record<string, unknown> = {};
        conversation.participantIds.forEach((id) => {
          if (id !== currentUser.id) {
            unreadCountsUpdate[`unreadCounts.${id}`] = increment(messages.length);
          }
        });

        batch.update(conversationRef, {
          lastMessageText,
          lastMessageTimestamp: now,
          lastMessageSenderId: currentUser.id,
          lastMessageIsThread: false,
          ...unreadCountsUpdate,
        });
      }

      await batch.commit();
      toast({
        title: 'Сообщения пересланы',
        description: `Отправлено в ${targets.length} чат(ов)`,
      });
      handleClose();
    } catch (e: unknown) {
      const message = e instanceof Error ? e.message : String(e);
      console.error('Failed to bulk forward:', e);
      toast({ variant: 'destructive', title: 'Ошибка пересылки', description: message });
      setIsSending(false);
    }
  };

  const isLoading = !sessionReady || isLoadingUsers || isLoadingConversations;

  const recipientCountLabel =
    selectedIds.size === 0
      ? ''
      : selectedIds.size === 1
        ? '1 чат'
        : `${selectedIds.size} чатов`;

  return (
    <Sheet open={sheetOpen} onOpenChange={handleOpenChange}>
      <SheetContent
        side="right"
        showCloseButton={false}
        className={cn(
          'flex h-full max-h-[100dvh] w-full max-w-full flex-col gap-0 border-0 p-0 shadow-2xl sm:max-w-lg md:max-w-xl',
          'rounded-none data-[state=open]:duration-300 sm:rounded-l-3xl',
        )}
      >
        <div
          className="flex min-h-0 flex-1 flex-col overflow-hidden"
          style={{
            paddingTop: 'max(1rem, env(safe-area-inset-top))',
            paddingBottom: 'max(1rem, env(safe-area-inset-bottom))',
          }}
        >
          <header className="flex shrink-0 items-center gap-3 border-b border-border/60 px-4 pb-3">
            <Button
              type="button"
              variant="ghost"
              size="icon"
              onClick={handleGoBack}
              className="shrink-0 rounded-full"
              aria-label="Назад"
            >
              <ArrowLeft className="h-5 w-5" />
            </Button>
            <div className="min-w-0 flex-1">
              <h1 className="truncate text-lg font-bold sm:text-xl">Переслать</h1>
              <p className="truncate text-xs text-muted-foreground">
                Чаты и контакты · сообщений: {messages.length}
              </p>
            </div>
          </header>

          <div className="flex min-h-0 flex-1 flex-col gap-3 px-4 pt-3">
            <div className="flex min-h-0 max-h-[min(42vh,320px)] shrink-0 flex-col gap-2">
              <h2 className="shrink-0 text-xs font-bold uppercase tracking-wider text-muted-foreground">
                Предпросмотр
              </h2>
              {allUsers.length > 0 && messages.length > 0 ? (
                <ScrollArea className="min-h-[100px] flex-1 pr-2">
                  <ForwardingMessagePreview messages={messages} allUsers={allUsers} />
                </ScrollArea>
              ) : (
                <div className="flex min-h-[80px] items-center justify-center rounded-2xl border border-dashed bg-muted/30">
                  {isLoading ? (
                    <Loader2 className="h-6 w-6 animate-spin text-primary/50" />
                  ) : null}
                </div>
              )}
            </div>

            <div className="group relative shrink-0">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground transition-colors group-focus-within:text-primary" />
              <Input
                placeholder="Поиск чатов и контактов…"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="h-11 rounded-full border border-border/80 bg-background pl-10 shadow-sm focus-visible:ring-2 focus-visible:ring-primary"
              />
            </div>

            <div className="flex shrink-0 flex-wrap items-center gap-2">
              <Button
                type="button"
                variant="outline"
                size="sm"
                className="gap-1.5 rounded-full"
                disabled={filteredRows.length === 0 || allFilteredSelected}
                onClick={selectAllFiltered}
              >
                <ListChecks className="h-4 w-4" />
                Выбрать всех ({filteredRows.length})
              </Button>
              <Button
                type="button"
                variant="ghost"
                size="sm"
                className="gap-1.5 rounded-full"
                disabled={selectedIds.size === 0}
                onClick={clearSelection}
              >
                <ListX className="h-4 w-4" />
                Снять выделение
              </Button>
            </div>

            <ScrollArea className="min-h-0 flex-1 pr-2">
              <div className="space-y-1 pb-4">
                {isLoading ? (
                  <div className="flex h-40 items-center justify-center">
                    <Loader2 className="h-8 w-8 animate-spin text-primary/50" />
                  </div>
                ) : filteredRows.length > 0 ? (
                  filteredRows.map((row) => {
                    const isSelected = selectedIds.has(row.selectionKey);
                    return (
                      <div
                        key={row.selectionKey}
                        role="button"
                        tabIndex={0}
                        onClick={() => toggleSelect(row.selectionKey)}
                        onKeyDown={(e) => {
                          if (e.key === 'Enter' || e.key === ' ') {
                            e.preventDefault();
                            toggleSelect(row.selectionKey);
                          }
                        }}
                        className={cn(
                          'group relative flex cursor-pointer items-center justify-between rounded-2xl p-3 transition-all',
                          isSelected
                            ? 'bg-primary/10 ring-1 ring-primary/20'
                            : 'hover:bg-muted/80',
                        )}
                      >
                        <div className="flex min-w-0 flex-1 items-center gap-3">
                          <div className="relative shrink-0">
                            <Avatar className="h-11 w-11 border-2 border-background shadow-sm sm:h-12 sm:w-12">
                              <AvatarImage src={row.avatar ?? undefined} alt={row.displayName} />
                              <AvatarFallback>{row.displayName?.charAt(0)}</AvatarFallback>
                            </Avatar>
                            {isSelected ? (
                              <div className="absolute -right-1 -top-1 rounded-full bg-primary p-0.5 shadow-md text-primary-foreground">
                                <Check className="h-3 w-3" />
                              </div>
                            ) : null}
                          </div>
                          <div className="min-w-0">
                            <p
                              className={cn(
                                'truncate font-bold',
                                isSelected && 'text-primary',
                              )}
                            >
                              {row.displayName}
                            </p>
                            {row.kind === 'contact' ? (
                              <p className="truncate text-xs text-muted-foreground">В контактах</p>
                            ) : row.conversation.isGroup ? (
                              <p className="truncate text-xs text-muted-foreground">Группа</p>
                            ) : null}
                          </div>
                        </div>

                        <div
                          className={cn(
                            'ml-3 flex h-6 w-6 shrink-0 items-center justify-center rounded-full border-2 transition-all',
                            isSelected ? 'border-primary bg-primary' : 'border-muted-foreground/30',
                          )}
                        >
                          {isSelected ? <Check className="h-4 w-4 text-white" /> : null}
                        </div>
                      </div>
                    );
                  })
                ) : (
                  <div className="rounded-3xl border-2 border-dashed bg-muted/20 py-16 text-center text-muted-foreground">
                    <MessageSquare className="mx-auto h-12 w-12 opacity-20" />
                    <p className="mt-4 font-medium">Ничего не найдено</p>
                  </div>
                )}
              </div>
            </ScrollArea>
          </div>

          <div className="shrink-0 border-t border-border/60 px-4 pt-3">
            <Button
              size="lg"
              className="h-12 w-full gap-2 rounded-full text-base font-bold shadow-lg"
              disabled={isSending || selectedIds.size === 0}
              onClick={() => void handleBulkForward()}
            >
              {isSending ? (
                <Loader2 className="h-5 w-5 animate-spin" />
              ) : (
                <SendHorizonal className="h-5 w-5" />
              )}
              {selectedIds.size === 0
                ? 'Выберите получателей'
                : `Переслать · ${recipientCountLabel}`}
            </Button>
          </div>
        </div>
      </SheetContent>
    </Sheet>
  );
}
