'use client';

import React, { useState, useMemo } from 'react';
import { useFirestore } from '@/firebase';
import { doc, updateDoc } from 'firebase/firestore';
import type { User, Conversation, UserChatIndex } from '@/lib/types';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Check, Loader2, FolderHeart, Plus } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useToast } from '@/hooks/use-toast';
import { isSavedMessagesChat } from '@/lib/saved-messages-chat';

interface ChatFolderAssignmentDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  conversation: Conversation | null;
  currentUser: User;
  userChatIndex?: UserChatIndex | null;
  allUsers: User[];
  onOpenFolderManager: () => void;
}

export function ChatFolderAssignmentDialog({
  open,
  onOpenChange,
  conversation,
  currentUser,
  userChatIndex,
  allUsers,
  onOpenFolderManager
}: ChatFolderAssignmentDialogProps) {
  const [isSaving, setIsSaving] = useState(false);
  const firestore = useFirestore();
  const { toast } = useToast();

  const customFolders = useMemo(() => {
    return (userChatIndex?.folders || []).filter(f => f.type === 'custom');
  }, [userChatIndex?.folders]);

  if (!conversation) return null;

  const isSelfSaved = isSavedMessagesChat(conversation, currentUser.id);
  if (isSelfSaved) {
    return (
      <Dialog open={open} onOpenChange={(o) => onOpenChange(o)}>
        <DialogContent className="sm:max-w-xs rounded-[2.5rem] p-6 bg-background backdrop-blur-2xl border-0 shadow-2xl">
          <DialogHeader>
            <DialogTitle className="font-black text-lg">Избранное</DialogTitle>
            <DialogDescription className="text-foreground/70">
              «Избранное» всегда в списках «Все» и «Личные». Добавить его в пользовательскую папку нельзя — откройте через звёздочку в ленте папок.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter className="sm:justify-stretch pt-2">
            <Button className="w-full rounded-full font-bold" onClick={() => onOpenChange(false)}>
              Закрыть
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    );
  }

  const otherId = conversation.participantIds.find((id) => id !== currentUser.id)!;
  const displayName = conversation.isGroup
    ? conversation.name || 'Группа'
    : allUsers.find((u) => u.id === otherId)?.name || conversation.participantInfo[otherId]?.name || 'Чат';

  const toggleFolder = async (folderId: string) => {
    if (!firestore || !userChatIndex?.folders) return;
    setIsSaving(true);

    try {
      const updatedFolders = userChatIndex.folders.map(folder => {
        if (folder.id === folderId) {
          const hasChat = folder.conversationIds.includes(conversation.id);
          const newIds = hasChat 
            ? folder.conversationIds.filter(id => id !== conversation.id)
            : [...folder.conversationIds, conversation.id];
          return { ...folder, conversationIds: newIds };
        }
        return folder;
      });

      const indexRef = doc(firestore, 'userChats', currentUser.id);
      await updateDoc(indexRef, { folders: updatedFolders });
      
      const folderName = customFolders.find(f => f.id === folderId)?.name;
      const isAdded = updatedFolders.find(f => f.id === folderId)?.conversationIds.includes(conversation.id);
      
      toast({ 
        title: isAdded ? 'Добавлено в папку' : 'Удалено из папки',
        description: folderName
      });
    } catch (e: unknown) {
      const message =
        typeof e === 'object' &&
        e != null &&
        'message' in e &&
        typeof (e as { message?: unknown }).message === 'string'
          ? (e as { message: string }).message
          : 'Не удалось обновить папки.';
      toast({ variant: 'destructive', title: 'Ошибка обновления', description: message });
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={(o) => !isSaving && onOpenChange(o)}>
      <DialogContent className="sm:max-w-xs rounded-[2.5rem] p-0 flex flex-col overflow-hidden bg-background backdrop-blur-2xl border-0 shadow-2xl ring-1 ring-foreground/5 dark:ring-white/5">
        <DialogHeader className="p-6 pb-4 bg-muted/15 flex-shrink-0">
          <DialogTitle className="flex items-center gap-2 font-black text-xl tracking-tight">
            <FolderHeart className="h-6 w-6 text-primary" /> Папки чата
          </DialogTitle>
          <DialogDescription className="truncate text-foreground/60 font-medium">
            Для: <span className="font-bold text-foreground">{displayName}</span>
          </DialogDescription>
        </DialogHeader>

        <div className="flex-1 min-h-0">
          <ScrollArea className="max-h-[50vh]">
            <div className="p-4 space-y-2">
              {customFolders.length > 0 ? (
                customFolders.map(folder => {
                  const isInFolder = folder.conversationIds.includes(conversation.id);
                  return (
                    <button
                      key={folder.id}
                      onClick={() => toggleFolder(folder.id)}
                      disabled={isSaving}
                      className={cn(
                        "w-full flex items-center justify-between p-4 rounded-2xl transition-all active:scale-[0.98] group border border-transparent",
                        isInFolder ? "bg-primary text-primary-foreground shadow-lg shadow-primary/20" : "hover:bg-muted/70 bg-muted/30 text-foreground/80"
                      )}
                    >
                      <span className="font-bold text-sm truncate">{folder.name}</span>
                      <div className={cn(
                        "h-6 w-6 rounded-full flex items-center justify-center shrink-0 transition-all",
                        isInFolder ? "bg-primary-foreground shadow-md" : "ring-1 ring-foreground/10 group-hover:ring-primary/30"
                      )}>
                        {isInFolder ? (
                            <Check className="h-4 w-4 text-primary stroke-[4px] shrink-0" />
                        ) : isSaving ? (
                            <Loader2 className="h-3.5 w-3.5 animate-spin opacity-40" />
                        ) : null}
                      </div>
                    </button>
                  );
                })
              ) : (
                <div className="py-10 px-6 text-center space-y-5">
                    <p className="text-xs text-muted-foreground font-bold uppercase tracking-widest opacity-40 italic">У вас нет кастомных папок</p>
                    <Button 
                        variant="ghost" 
                        size="sm" 
                        onClick={() => { onOpenChange(false); onOpenFolderManager(); }}
                        className="rounded-full h-12 w-full font-bold border-0 bg-muted/40 hover:bg-muted/60 transition-all active:scale-95"
                    >
                        <Plus className="h-4 w-4 mr-2" /> Создать папку
                    </Button>
                </div>
              )}
            </div>
          </ScrollArea>
        </div>

        {customFolders.length > 0 && (
            <div className="p-4 pt-0">
                <Button 
                    variant="ghost" 
                    className="w-full rounded-2xl h-12 text-[10px] font-black uppercase tracking-widest text-muted-foreground hover:bg-muted/50 border-0 shadow-none transition-all active:scale-95"
                    onClick={() => { onOpenChange(false); onOpenFolderManager(); }}
                >
                    Управление папками
                </Button>
            </div>
        )}

        <DialogFooter className="p-4 bg-muted/10 flex-shrink-0 border-0">
          <Button variant="ghost" onClick={() => onOpenChange(false)} disabled={isSaving} className="w-full rounded-full font-bold h-12 border-0 hover:bg-muted/50 transition-all active:scale-95">
            Закрыть
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
