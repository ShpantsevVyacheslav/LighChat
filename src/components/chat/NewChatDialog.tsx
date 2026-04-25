
'use client';

import React, { useState, useMemo } from 'react';
import { useFirestore } from '@/firebase';
import type { User } from '@/lib/types';
import { ROLES } from '@/lib/constants';
import { createOrOpenDirectChat } from '@/lib/direct-chat';
import { autoEnableE2eeForNewDirectChat } from '@/lib/e2ee';
import { useSettings } from '@/hooks/use-settings';
import { doc, getDoc } from 'firebase/firestore';
import type { PlatformSettingsDoc } from '@/lib/types';
import { canStartDirectChat } from '@/lib/user-chat-policy';
import {
  atUsernameLabel,
  userMatchesChatSearchQuery,
  splitUsersByContactsAndGlobalVisibility,
} from '@/lib/chat-user-search';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogTrigger } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { ScrollArea } from '@/components/ui/scroll-area';
import { PenSquare, Users, Loader2 } from 'lucide-react';
import { cn } from '@/lib/utils';
import { userAvatarListUrl } from '@/lib/user-avatar-display';

export function NewChatDialog({
  users,
  contactIds = [],
  contactDisplayNames = {},
  currentUser,
  onSelectConversation,
  onGroupCreateClick,
  triggerClassName,
}: {
  users: User[];
  /** id из userContacts — показываются первыми в поиске нового чата. */
  contactIds?: string[];
  /** Локальные имена контактов текущего пользователя (id -> displayName). */
  contactDisplayNames?: Record<string, string>;
  currentUser: User;
  onSelectConversation: (conversationId: string) => void;
  onGroupCreateClick: () => void;
  /** className для кнопки-триггера (рядом с поиском). */
  triggerClassName?: string;
}) {
  const [isOpen, setIsOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [isCreating, setIsCreating] = useState(false);
  const firestore = useFirestore();
  const { privacySettings } = useSettings();

  const { fromContacts, fromGlobal } = useMemo(() => {
    const matched = (users || []).filter(
      (u) =>
        userMatchesChatSearchQuery(u, searchTerm, contactDisplayNames[u.id]) &&
        canStartDirectChat(currentUser, u)
    );
    return splitUsersByContactsAndGlobalVisibility(
      matched,
      currentUser,
      contactIds,
      contactDisplayNames
    );
  }, [users, searchTerm, currentUser, contactIds, contactDisplayNames]);

  const handleSelectUser = async (user: User) => {
    if (!firestore || isCreating) return;
    setIsCreating(true);

    try {
        const id = await createOrOpenDirectChat(firestore, currentUser, user);
        let platformWants = false;
        try {
          const ps = await getDoc(doc(firestore, 'platformSettings', 'main'));
          const p = ps.data() as PlatformSettingsDoc | undefined;
          platformWants = !!p?.e2eeDefaultForNewDirectChats;
        } catch {
          /* ignore */
        }
        await autoEnableE2eeForNewDirectChat(firestore, id, currentUser.id, {
          userWants: privacySettings.e2eeForNewDirectChats === true,
          platformWants,
        });
        onSelectConversation(id);
        setIsOpen(false);
    } catch (error) {
        console.error("Failed to start/recreate chat:", error);
    } finally {
        setIsCreating(false);
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={setIsOpen}>
      <DialogTrigger asChild>
        <Button
          variant="ghost"
          size="icon"
          className={cn(
            /* Стеклянная кнопка у поиска: без сплошного primary, как поле ввода */
            'h-9 w-9 shrink-0 rounded-xl border border-black/10 bg-background/45 text-foreground shadow-none backdrop-blur-md',
            'hover:bg-background/55 dark:border-white/12 dark:bg-white/[0.08] dark:hover:bg-white/[0.13]',
            'transition-colors active:scale-[0.97]',
            '[&_svg]:h-[18px] [&_svg]:w-[18px]',
            triggerClassName
          )}
          disabled={isCreating}
          aria-label="Новый чат"
        >
          {isCreating ? (
            <Loader2 className="h-5 w-5 animate-spin" />
          ) : (
            <PenSquare className="h-[18px] w-[18px]" strokeWidth={2.1} />
          )}
        </Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-md rounded-2xl border-none shadow-2xl">
        <DialogHeader>
          <DialogTitle>Новый чат</DialogTitle>
          <DialogDescription>
            Выберите пользователя чтобы начать диалог или создайте группу.
          </DialogDescription>
        </DialogHeader>
        <div className="py-4 space-y-4">
          <Input
            placeholder="Имя, ник или @username…"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="rounded-full"
            disabled={isCreating}
          />
          <Button variant="outline" className="w-full rounded-full border-none bg-muted/50 hover:bg-muted" onClick={() => { setIsOpen(false); onGroupCreateClick(); }} disabled={isCreating}>
            <Users className="mr-2 h-4 w-4" />
            Создать группу
          </Button>
          <ScrollArea className="h-64">
            <div className="space-y-1 pr-2">
              {fromContacts.length > 0 && (
                <>
                  <p className="px-2 pt-1 text-[10px] font-bold uppercase tracking-wider text-muted-foreground">
                    Контакты
                  </p>
                  {fromContacts.map((user) => {
                    const displayName = (contactDisplayNames[user.id] ?? '').trim() || user.name;
                    const login = atUsernameLabel(user.username);
                    return (
                    <div
                      key={user.id}
                      onClick={() => handleSelectUser(user)}
                      className={cn(
                        'group flex cursor-pointer items-center gap-3 rounded-lg p-2 transition-colors hover:bg-muted',
                        isCreating && 'pointer-events-none opacity-50'
                      )}
                    >
                      <Avatar>
                        <AvatarImage src={userAvatarListUrl(user)} alt={displayName} />
                        <AvatarFallback>{displayName.charAt(0)}</AvatarFallback>
                      </Avatar>
                      <div className="min-w-0">
                        <p className="font-semibold transition-colors group-hover:text-primary truncate">
                          {displayName}
                        </p>
                        {login ? (
                          <p className="text-xs text-muted-foreground truncate">{login}</p>
                        ) : null}
                        {user.role && user.role !== 'worker' && (
                          <p className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">
                            {ROLES[user.role]}
                          </p>
                        )}
                      </div>
                    </div>
                    );
                  })}
                </>
              )}
              {fromGlobal.length > 0 && (
                <>
                  <p
                    className={cn(
                      'px-2 pt-2 text-[10px] font-bold uppercase tracking-wider text-muted-foreground',
                      fromContacts.length === 0 && 'pt-1'
                    )}
                  >
                    Все пользователи
                  </p>
                  {fromGlobal.map((user) => {
                    const displayName = (contactDisplayNames[user.id] ?? '').trim() || user.name;
                    const login = atUsernameLabel(user.username);
                    return (
                    <div
                      key={user.id}
                      onClick={() => handleSelectUser(user)}
                      className={cn(
                        'group flex cursor-pointer items-center gap-3 rounded-lg p-2 transition-colors hover:bg-muted',
                        isCreating && 'pointer-events-none opacity-50'
                      )}
                    >
                      <Avatar>
                        <AvatarImage src={userAvatarListUrl(user)} alt={displayName} />
                        <AvatarFallback>{displayName.charAt(0)}</AvatarFallback>
                      </Avatar>
                      <div className="min-w-0">
                        <p className="font-semibold transition-colors group-hover:text-primary truncate">
                          {displayName}
                        </p>
                        {login ? (
                          <p className="text-xs text-muted-foreground truncate">{login}</p>
                        ) : null}
                        {user.role && user.role !== 'worker' && (
                          <p className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">
                            {ROLES[user.role]}
                          </p>
                        )}
                      </div>
                    </div>
                    );
                  })}
                </>
              )}
              {fromContacts.length === 0 && fromGlobal.length === 0 && (
                <p className="py-8 text-center text-sm text-muted-foreground">Никого не найдено</p>
              )}
            </div>
          </ScrollArea>
        </div>
      </DialogContent>
    </Dialog>
  );
}
