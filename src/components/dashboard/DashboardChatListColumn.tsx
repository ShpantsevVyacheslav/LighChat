'use client';

/**
 * Левая колонка дашборда: папки, поиск, список диалогов, нижнее меню разделов.
 * Состояние открытого чата задаётся родителем через URL (`conversationId`).
 */

import React, { useState, useMemo, useEffect, useRef, useCallback } from 'react';
import { useAuth } from '@/hooks/use-auth';
import {
  useDoc,
  useFirestore,
  useCollection,
  useMemoFirebase,
  useConversationsByDocumentIds,
  useUser as useFirebaseAuthUser,
} from '@/firebase';
import { collection, doc, updateDoc } from 'firebase/firestore';
import { ensureSavedMessagesChat, isSavedMessagesChat } from '@/lib/saved-messages-chat';
import { mergeSidebarFolderOrder } from '@/lib/chat-folder-order';
import type { User, Conversation, UserChatIndex, ChatFolder, UserContactsIndex } from '@/lib/types';
import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Loader2, Search, ArrowUp, ArrowDown, Pencil, Trash2 } from 'lucide-react';
import { Skeleton } from '@/components/ui/skeleton';
import { NewChatDialog } from '@/components/chat/NewChatDialog';
import { GroupChatFormDialog } from '@/components/chat/GroupChatFormDialog';
import { FolderManagerDialog } from '@/components/chat/FolderManagerDialog';
import { ChatFolderAssignmentDialog } from '@/components/chat/ChatFolderAssignmentDialog';
import { useToast } from '@/hooks/use-toast';
import { ConversationItem } from '@/components/chat/ConversationItem';
import { ChatFolderRail } from '@/components/chat/ChatFolderRail';
import { LighChatSidebarMarkButton } from '@/components/chat/LighChatSidebarMarkButton';
import { ChatContextMenu } from '@/components/chat/ChatContextMenu';
import { DashboardBottomNav } from '@/components/dashboard/DashboardBottomNav';
import { useIsMobile } from '@/hooks/use-mobile';
import { CHAT_SIDEBAR_SHELL } from '@/lib/chat-glass-styles';

export type DashboardChatListColumnProps = {
  openConversationId: string | null;
  onOpenConversation: (conversationId: string) => void;
  /**
   * На мобильном: список чатов иногда рендерится в главной колонке (`DashboardMainAndChatRail`);
   * нижняя панель уже есть снаружи — не дублировать `DashboardBottomNav` внутри aside.
   */
  omitEmbeddedBottomNav?: boolean;
};

export function DashboardChatListColumn({
  openConversationId,
  onOpenConversation,
  omitEmbeddedBottomNav = false,
}: DashboardChatListColumnProps) {
  const isMobile = useIsMobile();
  const { user: currentUser } = useAuth();
  const { user: firebaseAuthUser, isUserLoading: isFirebaseAuthLoading } = useFirebaseAuthUser();
  const authUid = firebaseAuthUser?.uid ?? currentUser?.id ?? null;
  const currentUserForFirestore = useMemo((): User | null => {
    if (!currentUser) return null;
    if (!authUid) return currentUser;
    if (currentUser.id === authUid) return currentUser;
    return { ...currentUser, id: authUid };
  }, [currentUser, authUid]);
  const firestore = useFirestore();
  const { toast } = useToast();
  const [isListCollapsed, setIsListCollapsed] = useState(false);
  const [chatSearchTerm, setChatSearchTerm] = useState('');
  const [isCreatingGroup, setIsCreatingGroup] = useState(false);
  const [activeFolderId, setActiveFolderId] = useState('all');
  const [isFolderManagerOpen, setIsFolderManagerOpen] = useState(false);
  const [editingFolder, setEditingFolder] = useState<ChatFolder | null>(null);
  const [chatToManageFolders, setChatToManageFolders] = useState<Conversation | null>(null);

  const [listWidth, setListWidth] = useState(340);
  const isResizing = useRef(false);
  const [contextMenu, setContextMenu] = useState<{ x: number; y: number; conv: Conversation } | null>(null);
  const [folderContextMenu, setFolderContextMenu] = useState<{
    x: number;
    y: number;
    folder: ChatFolder;
  } | null>(null);

  const { data: usersData, isLoading: isLoadingUsers } = useCollection<User>(
    useMemoFirebase(
      () => (firestore && firebaseAuthUser ? collection(firestore, 'users') : null),
      [firestore, firebaseAuthUser]
    )
  );
  const allUsers = useMemo(() => usersData || [], [usersData]);

  const userChatIndexRef = useMemoFirebase(() => {
    if (!firestore || !authUid) return null;
    return doc(firestore, 'userChats', authUid);
  }, [firestore, authUid]);
  const { data: userChatIndex, isLoading: isLoadingIndex } = useDoc<UserChatIndex>(userChatIndexRef);
  const conversationIds = useMemo(() => userChatIndex?.conversationIds || [], [userChatIndex]);

  const userContactsRef = useMemoFirebase(() => {
    if (!firestore || !authUid) return null;
    return doc(firestore, 'userContacts', authUid);
  }, [firestore, authUid]);
  const { data: userContactsIndex } = useDoc<UserContactsIndex>(userContactsRef);
  const contactIdsForSearch = useMemo(
    () => userContactsIndex?.contactIds ?? [],
    [userContactsIndex?.contactIds]
  );

  const { data: rawConversations, isLoading: isLoadingConversations } = useConversationsByDocumentIds(
    firestore,
    conversationIds
  );

  const conversations = useMemo(() => {
    if (!rawConversations) return [];
    return [...rawConversations].sort((a, b) => {
      const getTime = (ts: string | undefined | null) => (ts ? new Date(ts).getTime() : 0);
      const timeA = Math.max(getTime(a.lastMessageTimestamp), getTime(a.lastReactionTimestamp));
      const timeB = Math.max(getTime(b.lastMessageTimestamp), getTime(b.lastReactionTimestamp));
      return timeB - timeA;
    });
  }, [rawConversations]);

  const savedMessagesConv = useMemo(
    () =>
      currentUser && authUid
        ? conversations.find((c) => isSavedMessagesChat(c, authUid)) ?? null
        : null,
    [conversations, currentUser, authUid]
  );

  const conversationsForFolders = useMemo(() => {
    if (!currentUser || !authUid) return conversations;
    return conversations.filter((c) => !isSavedMessagesChat(c, authUid));
  }, [conversations, currentUser, authUid]);

  const foldersUnsorted = useMemo((): ChatFolder[] => {
    const savedId = savedMessagesConv?.id;
    const withSaved = (ids: string[]) =>
      savedId && !ids.includes(savedId) ? [...ids, savedId] : ids;
    const defaultFolders: ChatFolder[] = [
      {
        id: 'all',
        name: 'Все',
        conversationIds: withSaved(conversationsForFolders.map((c) => c.id)),
        type: 'all',
      },
      {
        id: 'unread',
        name: 'Новые',
        conversationIds: conversations
          .filter(
            (c) =>
              (c.unreadCounts?.[authUid || ''] || 0) > 0 ||
              (c.unreadThreadCounts?.[authUid || ''] || 0) > 0
          )
          .map((c) => c.id),
        type: 'all',
      },
      {
        id: 'personal',
        name: 'Личные',
        conversationIds: withSaved(conversationsForFolders.filter((c) => !c.isGroup).map((c) => c.id)),
        type: 'personal',
      },
      {
        id: 'groups',
        name: 'Групповые',
        conversationIds: conversationsForFolders.filter((c) => c.isGroup).map((c) => c.id),
        type: 'groups',
      },
    ];
    const customFolders = (userChatIndex?.folders || []).map((f) => ({
      ...f,
      conversationIds: savedId ? f.conversationIds.filter((id) => id !== savedId) : f.conversationIds,
    }));
    return [...defaultFolders, ...customFolders];
  }, [conversationsForFolders, userChatIndex?.folders, authUid, savedMessagesConv?.id]);

  const folders = useMemo(
    () => mergeSidebarFolderOrder(userChatIndex?.sidebarFolderOrder, foldersUnsorted),
    [userChatIndex?.sidebarFolderOrder, foldersUnsorted]
  );

  const activeFolder = useMemo(
    () => folders.find((f) => f.id === activeFolderId) || folders[0],
    [folders, activeFolderId]
  );

  const filteredConversations = useMemo(() => {
    if (!conversations || !currentUser || !authUid) return [];
    const folderConvIds = new Set(activeFolder?.conversationIds || []);
    const term = chatSearchTerm.toLowerCase();
    return conversations
      .filter((c) => folderConvIds.has(c.id))
      .filter((conv) => {
        const isSelfDm = isSavedMessagesChat(conv, authUid);
        const otherId = isSelfDm ? authUid : conv.participantIds.find((id) => id !== authUid);
        const name = conv.isGroup
          ? conv.name
          : isSelfDm
            ? conv.name || 'Избранное'
            : otherId
              ? allUsers.find((u) => u.id === otherId)?.name ||
                conv.participantInfo[otherId]?.name ||
                ''
              : '';
        return (name || '').toLowerCase().includes(term);
      });
  }, [conversations, chatSearchTerm, currentUser, authUid, allUsers, activeFolder]);

  const orderedFolderConversations = useMemo(() => {
    const pinsRaw = userChatIndex?.folderPins?.[activeFolderId] || [];
    const inFolder = new Set(filteredConversations.map((c) => c.id));
    const pinsOrdered = pinsRaw.filter((id) => inFolder.has(id));
    const pinSet = new Set(pinsOrdered);
    const pinned = pinsOrdered
      .map((id) => filteredConversations.find((c) => c.id === id))
      .filter((c): c is Conversation => !!c);
    const unpinned = filteredConversations.filter((c) => !pinSet.has(c.id));
    const byTime = (a: Conversation, b: Conversation) => {
      const getTime = (ts: string | undefined | null) => (ts ? new Date(ts).getTime() : 0);
      const timeA = Math.max(getTime(a.lastMessageTimestamp), getTime(a.lastReactionTimestamp));
      const timeB = Math.max(getTime(b.lastMessageTimestamp), getTime(b.lastReactionTimestamp));
      return timeB - timeA;
    };
    unpinned.sort(byTime);
    return [...pinned, ...unpinned];
  }, [filteredConversations, userChatIndex?.folderPins, activeFolderId]);

  const isInitialLoading = useMemo(() => {
    return (
      isFirebaseAuthLoading ||
      ((isLoadingUsers || isLoadingConversations || isLoadingIndex) &&
        orderedFolderConversations.length === 0)
    );
  }, [
    isFirebaseAuthLoading,
    isLoadingUsers,
    isLoadingConversations,
    isLoadingIndex,
    orderedFolderConversations.length,
  ]);

  const handleSelectConversation = (conversationId: string) => {
    onOpenConversation(conversationId);
  };

  useEffect(() => {
    if (!firestore || !currentUserForFirestore) return;
    ensureSavedMessagesChat(firestore, currentUserForFirestore).catch((err) =>
      console.error('[ensureSavedMessagesChat]', err)
    );
  }, [firestore, currentUserForFirestore]);

  useEffect(() => {
    if (activeFolderId === 'favorites') setActiveFolderId('all');
  }, [activeFolderId]);

  const persistSidebarFolderOrder = useCallback(
    async (orderedIds: string[]) => {
      if (!firestore || !authUid) return;
      try {
        await updateDoc(doc(firestore, 'userChats', authUid), {
          sidebarFolderOrder: orderedIds,
        });
      } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : 'Не удалось сохранить порядок папок';
        toast({ variant: 'destructive', title: 'Ошибка', description: msg });
      }
    },
    [firestore, authUid, toast]
  );

  const handleContextMenu = (e: React.MouseEvent, conv: Conversation) => {
    e.preventDefault();
    setContextMenu({ x: e.clientX, y: e.clientY, conv });
  };

  const handleEditFolder = (folder: ChatFolder) => {
    setEditingFolder(folder);
    setIsFolderManagerOpen(true);
  };

  const handleResizeStart = (startX: number) => {
    isResizing.current = true;
    const startWidth = listWidth;
    document.body.style.cursor = 'col-resize';
    document.body.style.userSelect = 'none';

    const onMove = (clientX: number) => {
      if (!isResizing.current) return;
      /* Ручка на правом краю левой колонки: тянем вправо — шире список. */
      const delta = clientX - startX;
      setListWidth(Math.max(260, Math.min(600, startWidth + delta)));
    };

    const onEnd = () => {
      isResizing.current = false;
      document.body.style.cursor = '';
      document.body.style.userSelect = '';
      document.removeEventListener('mousemove', onMouseMove);
      document.removeEventListener('mouseup', onEnd);
      document.removeEventListener('touchmove', onTouchMove);
      document.removeEventListener('touchend', onEnd);
    };

    const onMouseMove = (e: MouseEvent) => onMove(e.clientX);
    const onTouchMove = (e: TouchEvent) => onMove(e.touches[0].clientX);

    document.addEventListener('mousemove', onMouseMove);
    document.addEventListener('mouseup', onEnd);
    document.addEventListener('touchmove', onTouchMove, { passive: true });
    document.addEventListener('touchend', onEnd);
  };

  const moveFolderInCustomList = async (folderId: string, direction: 'up' | 'down') => {
    if (!firestore || !authUid) return;
    const customFolders = [...(userChatIndex?.folders || [])];
    const idx = customFolders.findIndex((f) => f.id === folderId);
    if (idx === -1) return;
    const newIdx = direction === 'up' ? idx - 1 : idx + 1;
    if (newIdx < 0 || newIdx >= customFolders.length) return;
    [customFolders[idx], customFolders[newIdx]] = [customFolders[newIdx], customFolders[idx]];
    try {
      await updateDoc(doc(firestore, 'userChats', authUid), { folders: customFolders });
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      toast({ variant: 'destructive', title: 'Ошибка', description: msg });
    }
  };

  const toggleFolderPin = async (conversationIdPin: string) => {
    if (!firestore || !authUid) return;
    const prev = userChatIndex?.folderPins || {};
    const list = [...(prev[activeFolderId] || [])];
    const idx = list.indexOf(conversationIdPin);
    if (idx >= 0) list.splice(idx, 1);
    else list.unshift(conversationIdPin);
    const folderPins = { ...prev, [activeFolderId]: list };
    try {
      await updateDoc(doc(firestore, 'userChats', authUid), { folderPins });
      toast({
        title: idx >= 0 ? 'Чат откреплён' : 'Чат закреплён',
        description: `Папка «${activeFolder?.name || activeFolderId}»`,
      });
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Не удалось изменить закрепление';
      toast({ variant: 'destructive', title: 'Ошибка', description: msg });
    }
  };

  const handleDeleteFolderDirect = async (folder: ChatFolder) => {
    if (!firestore || !authUid) return;
    try {
      const currentFolders = userChatIndex?.folders || [];
      const updatedFolders = currentFolders.filter((f) => f.id !== folder.id);
      await updateDoc(doc(firestore, 'userChats', authUid), { folders: updatedFolders });
      if (activeFolderId === folder.id) setActiveFolderId('all');
      toast({ title: 'Папка удалена' });
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      toast({ variant: 'destructive', title: 'Ошибка удаления', description: msg });
    }
  };

  return (
    <>
      <aside
        className={cn(
          CHAT_SIDEBAR_SHELL,
          'flex h-full w-full flex-col transition-none md:w-auto',
          isListCollapsed && 'md:!w-20'
        )}
        style={
          typeof window !== 'undefined' && window.innerWidth >= 768 && !isListCollapsed
            ? { width: listWidth }
            : undefined
        }
        onClick={() => {
          setContextMenu(null);
          setFolderContextMenu(null);
        }}
      >
        <div
          className={cn(
            'flex min-h-0 min-w-0 flex-1 flex-col',
            isMobile && 'pt-[env(safe-area-inset-top,0px)]'
          )}
        >
          {isMobile && !isListCollapsed && currentUser && authUid && (
            <ChatFolderRail
              layout="horizontal"
              folders={folders}
              activeFolderId={activeFolderId}
              savedMessagesConversationId={savedMessagesConv?.id ?? null}
              selectedConversationId={openConversationId}
              conversations={conversations}
              currentUserId={authUid}
              onSelectFolder={setActiveFolderId}
              onOpenSavedMessages={() => {
                if (savedMessagesConv?.id) {
                  onOpenConversation(savedMessagesConv.id);
                  setActiveFolderId('all');
                }
              }}
              onPersistFolderOrder={(orderedIds) => {
                void persistSidebarFolderOrder(orderedIds);
              }}
              onNewFolderClick={() => {
                setEditingFolder(null);
                setIsFolderManagerOpen(true);
              }}
              onCustomFolderContextMenu={(e, folder) => {
                e.preventDefault();
                setFolderContextMenu({ x: e.clientX, y: e.clientY, folder });
              }}
            />
          )}

          <div className="flex min-h-0 flex-1 flex-col overflow-hidden md:flex-row">
            {!isMobile && !isListCollapsed && currentUser && authUid && (
              <ChatFolderRail
                folders={folders}
                activeFolderId={activeFolderId}
                savedMessagesConversationId={savedMessagesConv?.id ?? null}
                selectedConversationId={openConversationId}
                conversations={conversations}
                currentUserId={authUid}
                onSelectFolder={setActiveFolderId}
                onOpenSavedMessages={() => {
                  if (savedMessagesConv?.id) {
                    onOpenConversation(savedMessagesConv.id);
                    setActiveFolderId('all');
                  }
                }}
                onPersistFolderOrder={(orderedIds) => {
                  void persistSidebarFolderOrder(orderedIds);
                }}
                onNewFolderClick={() => {
                  setEditingFolder(null);
                  setIsFolderManagerOpen(true);
                }}
                onCustomFolderContextMenu={(e, folder) => {
                  e.preventDefault();
                  setFolderContextMenu({ x: e.clientX, y: e.clientY, folder });
                }}
                onToggleSidebarCollapse={() => setIsListCollapsed((v) => !v)}
              />
            )}

            <div className="flex min-h-0 min-w-0 flex-1 flex-col">
              {!isMobile && isListCollapsed && (
                <div className="hidden shrink-0 justify-center border-b border-black/8 py-1 dark:border-white/10 md:flex">
                  <LighChatSidebarMarkButton
                    compact
                    onClick={() => setIsListCollapsed(false)}
                    title="Развернуть боковую панель"
                  />
                </div>
              )}
              {!isListCollapsed && (
                <div className="p-2">
                  <div className="flex items-center gap-2">
                    <div className="relative min-w-0 flex-1">
                      <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                      <Input
                        placeholder="Поиск..."
                        value={chatSearchTerm}
                        tabIndex={-1}
                        onChange={(e) => setChatSearchTerm(e.target.value)}
                        className="h-9 w-full rounded-full border-black/10 bg-background/40 pl-9 text-sm backdrop-blur-sm dark:border-white/12 dark:bg-background/25"
                      />
                    </div>
                    {currentUser && authUid && (
                      <NewChatDialog
                        users={allUsers.filter((u) => u.id !== authUid && !u.deletedAt)}
                        contactIds={contactIdsForSearch}
                        currentUser={currentUserForFirestore!}
                        onSelectConversation={handleSelectConversation}
                        onGroupCreateClick={() => setIsCreatingGroup(true)}
                      />
                    )}
                  </div>
                </div>
              )}

              <div className="min-h-0 flex-1 overflow-y-auto scrolling-touch bg-transparent scrollbar-hide">
                <div className="p-2">
                  {isInitialLoading ? (
                    <div className="space-y-3 p-2">
                      {[...Array(5)].map((_, i) => (
                        <div key={i} className="flex items-center gap-3">
                          <Skeleton className="h-10 w-10 rounded-full" />
                          <div className={cn('space-y-2', isListCollapsed && 'hidden')}>
                            <Skeleton className="h-4 w-24" />
                            <Skeleton className="h-3 w-32" />
                          </div>
                        </div>
                      ))}
                    </div>
                  ) : orderedFolderConversations.length === 0 ? (
                    <div className="p-8 text-center text-muted-foreground">
                      <p className="text-sm">В этой папке пока пусто.</p>
                      {activeFolder?.type === 'custom' && (
                        <Button
                          variant="link"
                          onClick={() => handleEditFolder(activeFolder)}
                          className="mt-2 h-auto p-0 text-xs font-bold text-primary"
                        >
                          Добавить чаты
                        </Button>
                      )}
                    </div>
                  ) : (
                    orderedFolderConversations.map((conv) => (
                      <ConversationItem
                        key={conv.id}
                        conv={conv}
                        isSelected={openConversationId === conv.id}
                        isMobile={isMobile}
                        isListCollapsed={isListCollapsed}
                        currentUser={currentUserForFirestore!}
                        allUsers={allUsers}
                        onSelect={handleSelectConversation}
                        onContextMenu={handleContextMenu}
                        onManageFolders={setChatToManageFolders}
                        isPinnedInFolder={(userChatIndex?.folderPins?.[activeFolderId] || []).includes(
                          conv.id
                        )}
                        isSavedMessages={authUid ? isSavedMessagesChat(conv, authUid) : false}
                      />
                    ))
                  )}
                </div>
              </div>
            </div>
          </div>

          {!omitEmbeddedBottomNav ? (
            <DashboardBottomNav variant="chatSidebar" sidebarCollapsed={isListCollapsed} />
          ) : null}
        </div>
      </aside>

      {!isListCollapsed && typeof window !== 'undefined' && window.innerWidth >= 768 && (
        <div
          className="hidden w-1.5 shrink-0 cursor-col-resize items-center justify-center transition-colors group hover:bg-primary/10 active:bg-primary/20 md:flex"
          onMouseDown={(e) => {
            e.preventDefault();
            handleResizeStart(e.clientX);
          }}
          onTouchStart={(e) => handleResizeStart(e.touches[0].clientX)}
        >
          <div className="h-8 w-0.5 rounded-full bg-border transition-colors group-hover:bg-primary/40 group-active:bg-primary" />
        </div>
      )}

      {folderContextMenu && (
        <div
          className="fixed z-50 min-w-[180px] rounded-xl border border-border bg-popover/95 p-1 shadow-lg backdrop-blur-xl"
          style={{ top: folderContextMenu.y, left: folderContextMenu.x }}
          onClick={(e) => e.stopPropagation()}
        >
          <button
            type="button"
            className="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-sm transition-colors hover:bg-muted"
            onClick={() => {
              handleEditFolder(folderContextMenu.folder);
              setFolderContextMenu(null);
            }}
          >
            <Pencil className="h-4 w-4" /> Редактировать
          </button>
          <button
            type="button"
            className="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-sm transition-colors hover:bg-muted disabled:opacity-40"
            onClick={() => {
              moveFolderInCustomList(folderContextMenu.folder.id, 'up');
              setFolderContextMenu(null);
            }}
            disabled={
              (userChatIndex?.folders || []).findIndex((f) => f.id === folderContextMenu.folder.id) ===
              0
            }
          >
            <ArrowUp className="h-4 w-4" /> Переместить вверх
          </button>
          <button
            type="button"
            className="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-sm transition-colors hover:bg-muted disabled:opacity-40"
            onClick={() => {
              moveFolderInCustomList(folderContextMenu.folder.id, 'down');
              setFolderContextMenu(null);
            }}
            disabled={
              (userChatIndex?.folders || []).findIndex((f) => f.id === folderContextMenu.folder.id) ===
              (userChatIndex?.folders || []).length - 1
            }
          >
            <ArrowDown className="h-4 w-4" /> Переместить вниз
          </button>
          <div className="my-1 h-px bg-border" />
          <button
            type="button"
            className="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-sm text-destructive transition-colors hover:bg-destructive/10"
            onClick={() => {
              handleDeleteFolderDirect(folderContextMenu.folder);
              setFolderContextMenu(null);
            }}
          >
            <Trash2 className="h-4 w-4" /> Удалить
          </button>
        </div>
      )}

      {contextMenu && (
        <ChatContextMenu
          x={contextMenu.x}
          y={contextMenu.y}
          conv={contextMenu.conv}
          currentUser={currentUserForFirestore!}
          onClose={() => setContextMenu(null)}
          onManageFolders={setChatToManageFolders}
          isPinnedInFolder={(userChatIndex?.folderPins?.[activeFolderId] || []).includes(
            contextMenu.conv.id
          )}
          onToggleFolderPin={toggleFolderPin}
        />
      )}

      {currentUserForFirestore && authUid && (
        <GroupChatFormDialog
          open={isCreatingGroup}
          onOpenChange={(open) => {
            if (!open) setIsCreatingGroup(false);
          }}
          allUsers={allUsers.filter((u) => u.id !== authUid && !u.deletedAt)}
          contactIds={contactIdsForSearch}
          currentUser={currentUserForFirestore}
          onGroupCreated={(id) => {
            setIsCreatingGroup(false);
            handleSelectConversation(id);
          }}
        />
      )}

      {currentUserForFirestore && (
        <>
          <FolderManagerDialog
            open={isFolderManagerOpen}
            onOpenChange={setIsFolderManagerOpen}
            conversations={conversations}
            currentUser={currentUserForFirestore}
            userChatIndex={userChatIndex}
            allUsers={allUsers}
            editingFolder={editingFolder}
            onFolderSaved={(id) => {
              setIsFolderManagerOpen(false);
              setEditingFolder(null);
              setActiveFolderId(id);
            }}
          />
          <ChatFolderAssignmentDialog
            open={!!chatToManageFolders}
            onOpenChange={(o) => !o && setChatToManageFolders(null)}
            conversation={chatToManageFolders}
            currentUser={currentUserForFirestore}
            userChatIndex={userChatIndex}
            allUsers={allUsers}
            onOpenFolderManager={() => setIsFolderManagerOpen(true)}
          />
        </>
      )}
    </>
  );
}
