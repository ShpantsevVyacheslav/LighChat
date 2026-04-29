'use client';

import React, { useState, useMemo, useEffect } from 'react';
import { useFirestore } from '@/firebase';
import { doc, updateDoc } from 'firebase/firestore';
import type { User, Conversation, ChatFolder, UserChatIndex } from '@/lib/types';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Loader2, Search, Trash2, FolderEdit } from 'lucide-react';
import { Label } from '@/components/ui/label';
import { cn } from '@/lib/utils';
import { useToast } from '@/hooks/use-toast';
import { isSavedMessagesChat } from '@/lib/saved-messages-chat';
import { participantListAvatarUrl } from '@/lib/user-avatar-display';
import { ruEnSubstringMatch } from '@/lib/ru-latin-search-normalize';

interface FolderManagerDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  conversations: Conversation[];
  currentUser: User;
  userChatIndex?: UserChatIndex | null;
  allUsers: User[];
  editingFolder: ChatFolder | null;
  onFolderSaved: (folderId: string) => void;
}

export function FolderManagerDialog({
  open,
  onOpenChange,
  conversations,
  currentUser,
  userChatIndex,
  allUsers,
  editingFolder,
  onFolderSaved
}: FolderManagerDialogProps) {
  const [folderName, setFolderName] = useState('');
  const [selectedConvIds, setSelectedConvIds] = useState<Set<string>>(new Set());
  const [searchTerm, setSearchTerm] = useState('');
  const [isSaving, setIsSaving] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  
  const firestore = useFirestore();
  const { toast } = useToast();

  const savedMessagesConvId = useMemo(
    () => conversations.find((c) => isSavedMessagesChat(c, currentUser.id))?.id,
    [conversations, currentUser.id]
  );

  useEffect(() => {
    if (open) {
      if (editingFolder) {
        setFolderName(editingFolder.name);
        setSelectedConvIds(
          new Set(
            savedMessagesConvId
              ? editingFolder.conversationIds.filter((id) => id !== savedMessagesConvId)
              : editingFolder.conversationIds
          )
        );
      } else {
        setFolderName('');
        setSelectedConvIds(new Set());
      }
      setSearchTerm('');
    }
  }, [open, editingFolder, savedMessagesConvId]);

  const filteredChatList = useMemo(() => {
    return conversations
      .filter((conv) => !isSavedMessagesChat(conv, currentUser.id))
      .filter((conv) => {
        const otherId = conv.participantIds.find((id) => id !== currentUser.id);
        const name = conv.isGroup
          ? conv.name
          : otherId
            ? allUsers.find((u) => u.id === otherId)?.name || conv.participantInfo[otherId]?.name || ''
            : '';
        return ruEnSubstringMatch(name || '', searchTerm);
      });
  }, [conversations, searchTerm, currentUser.id, allUsers]);

  const toggleSelect = (id: string) => {
    setSelectedConvIds(prev => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const handleSelectAllFiltered = () => {
    setSelectedConvIds(prev => {
        const next = new Set(prev);
        filteredChatList.forEach(c => next.add(c.id));
        return next;
    });
  };

  const handleDeselectAllFiltered = () => {
    setSelectedConvIds(prev => {
        const next = new Set(prev);
        filteredChatList.forEach(c => next.delete(c.id));
        return next;
    });
  };

  const handleSave = async () => {
    if (!folderName.trim() || !firestore) return;
    setIsSaving(true);

    try {
      const currentFolders = userChatIndex?.folders || [];
      let updatedFolders: ChatFolder[];

      const ids = Array.from(selectedConvIds).filter((id) => id !== savedMessagesConvId);
      const newFolder: ChatFolder = {
        id: editingFolder?.id || `folder_${Date.now()}`,
        name: folderName.trim(),
        conversationIds: ids,
        type: 'custom'
      };

      if (editingFolder) {
        updatedFolders = currentFolders.map(f => f.id === editingFolder.id ? newFolder : f);
      } else {
        updatedFolders = [...currentFolders, newFolder];
      }

      const foldersWithoutSaved =
        savedMessagesConvId != null
          ? updatedFolders.map((f) => ({
              ...f,
              conversationIds: f.conversationIds.filter((id) => id !== savedMessagesConvId),
            }))
          : updatedFolders;

      const indexRef = doc(firestore, 'userChats', currentUser.id);
      await updateDoc(indexRef, { folders: foldersWithoutSaved });
      
      toast({ title: editingFolder ? 'Папка обновлена' : 'Папка создана' });
      onFolderSaved(newFolder.id);
    } catch (e: unknown) {
      const message =
        typeof e === 'object' &&
        e != null &&
        'message' in e &&
        typeof (e as { message?: unknown }).message === 'string'
          ? (e as { message: string }).message
          : 'Не удалось сохранить папку.';
      toast({ variant: 'destructive', title: 'Ошибка сохранения', description: message });
    } finally {
      setIsSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!editingFolder || !firestore) return;
    setIsDeleting(true);

    try {
      const currentFolders = userChatIndex?.folders || [];
      const updatedFolders = currentFolders.filter(f => f.id !== editingFolder.id);

      const indexRef = doc(firestore, 'userChats', currentUser.id);
      await updateDoc(indexRef, { folders: updatedFolders });
      
      toast({ title: 'Папка удалена' });
      onFolderSaved('all');
    } catch (e: unknown) {
      const message =
        typeof e === 'object' &&
        e != null &&
        'message' in e &&
        typeof (e as { message?: unknown }).message === 'string'
          ? (e as { message: string }).message
          : 'Не удалось удалить папку.';
      toast({ variant: 'destructive', title: 'Ошибка удаления', description: message });
    } finally {
      setIsDeleting(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={(o) => !isSaving && !isDeleting && onOpenChange(o)}>
      <DialogContent showCloseButton={false} className="sm:max-w-md rounded-[2.5rem] p-0 flex flex-col h-[85vh] bg-background backdrop-blur-2xl border-0 shadow-2xl overflow-hidden ring-1 ring-foreground/5 dark:ring-white/5">
        <DialogHeader className="p-4 pb-2 bg-muted/20 flex-shrink-0">
          <DialogTitle className="flex items-center gap-2 font-black text-xl tracking-tight">
            <FolderEdit className="h-6 w-6 text-primary" />
            {editingFolder ? 'Настройка папки' : 'Новая папка'}
          </DialogTitle>
          <DialogDescription className="text-foreground/60 font-medium text-xs pb-2">
            {editingFolder ? 'Измените название или список чатов в папке.' : 'Создайте папку для быстрой фильтрации чатов.'}
          </DialogDescription>
        </DialogHeader>

        <div className="px-4 py-2 space-y-3 flex-1 flex flex-col min-h-0">
          <div className="space-y-0.5">
            <Label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground ml-1 opacity-60">Название папки</Label>
            <Input
              placeholder="Напр: Работа, Семья..."
              value={folderName}
              onChange={e => setFolderName(e.target.value)}
              className="h-11 rounded-2xl bg-muted border-none px-4 font-bold text-base focus-visible:ring-primary shadow-inner"
              autoFocus
            />
          </div>

          <div className="flex-1 flex flex-col min-h-0 gap-2">
            <div className="flex items-center justify-between px-1">
                <Label className="text-[10px] font-black uppercase tracking-widest text-muted-foreground opacity-60">Чаты ({selectedConvIds.size})</Label>
                <div className="flex gap-1.5">
                    <Button variant="ghost" size="sm" onClick={handleSelectAllFiltered} className="h-7 px-3 text-[9px] font-black uppercase bg-muted/40 hover:bg-muted border-0 rounded-full transition-all active:scale-95 shadow-none">
                        Выбрать все
                    </Button>
                    <Button variant="ghost" size="sm" onClick={handleDeselectAllFiltered} className="h-7 px-3 text-[9px] font-black uppercase bg-muted/40 hover:bg-muted border-0 rounded-full transition-all active:scale-95 shadow-none">
                        Сбросить
                    </Button>
                </div>
            </div>

            <div className="relative group">
              <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground group-focus-within:text-primary transition-colors" />
              <Input
                placeholder="Поиск по названию..."
                value={searchTerm}
                onChange={e => setSearchTerm(e.target.value)}
                className="h-10 rounded-2xl pl-10 bg-muted border-none text-sm font-medium focus-visible:ring-primary/50"
              />
            </div>

            <ScrollArea className="flex-1 rounded-[2rem] bg-muted/25 dark:bg-muted/15 shadow-inner border-0">
              <div className="p-2 space-y-1.5">
                {filteredChatList.map(conv => {
                  const isSelected = selectedConvIds.has(conv.id);
                  const otherId = conv.participantIds.find((id) => id !== currentUser.id);
                  const displayName = conv.isGroup
                    ? conv.name
                    : otherId
                      ? allUsers.find((u) => u.id === otherId)?.name || conv.participantInfo[otherId]?.name || 'Чат'
                      : 'Чат';
                  const liveOther = otherId ? allUsers.find((u) => u.id === otherId) : undefined;
                  const avatar = conv.isGroup
                    ? conv.photoUrl
                    : otherId
                      ? participantListAvatarUrl(liveOther, conv.participantInfo[otherId])
                      : '';

                  return (
                    <div
                      key={conv.id}
                      onClick={() => toggleSelect(conv.id)}
                      className={cn(
                        "flex items-center justify-between p-1.5 px-3 rounded-2xl cursor-pointer transition-all active:scale-[0.98] group border-0",
                        isSelected ? "bg-primary/15 ring-1 ring-primary/25" : "hover:bg-muted/60 bg-muted/20 text-foreground/70"
                      )}
                    >
                      <div className="flex items-center gap-3 min-w-0">
                        <Avatar className="h-9 w-9 border-0 shadow-sm ring-1 ring-foreground/5 dark:ring-white/10">
                          <AvatarImage src={avatar} className="object-cover" />
                          <AvatarFallback className="bg-muted text-foreground text-xs font-black">{displayName?.charAt(0)}</AvatarFallback>
                        </Avatar>
                        <div className="flex flex-col min-w-0">
                            <span className={cn("text-sm font-bold truncate transition-colors", isSelected ? "text-primary" : "text-foreground")}>
                                {displayName}
                            </span>
                            {conv.isGroup && <span className={cn("text-[9px] font-black uppercase tracking-wider opacity-60", isSelected ? "text-primary/60" : "text-muted-foreground")}>Группа</span>}
                        </div>
                      </div>
                    </div>
                  );
                })}
                {filteredChatList.length === 0 && (
                    <div className="p-12 text-center text-muted-foreground opacity-30 flex flex-col items-center gap-3">
                        <Search className="h-10 w-10" />
                        <p className="text-[10px] font-black uppercase tracking-widest">Ничего не найдено</p>
                    </div>
                )}
              </div>
            </ScrollArea>
          </div>
        </div>

        <DialogFooter className="p-4 pt-3 bg-muted/15 flex-shrink-0 border-0">
          <div className="flex items-center justify-between w-full gap-2">
            {/* Left corner: Trash icon */}
            <div className="flex items-center">
                {editingFolder && (
                    <Button
                        variant="ghost"
                        size="icon"
                        onClick={handleDelete}
                        disabled={isSaving || isDeleting}
                        className="rounded-full text-red-500 hover:bg-red-500/10 h-9 w-9 border-none transition-all active:scale-95 shadow-none"
                    >
                        {isDeleting ? <Loader2 className="h-4 w-4 animate-spin" /> : <Trash2 className="h-4 w-4" />}
                    </Button>
                )}
            </div>
            
            {/* Right side: Action buttons grouped */}
            <div className="flex items-center gap-2">
                <Button 
                    variant="ghost" 
                    onClick={() => onOpenChange(false)} 
                    disabled={isSaving || isDeleting} 
                    className="rounded-full font-bold h-9 px-4 text-xs border-none shadow-none hover:bg-muted transition-all active:scale-95"
                >
                    Отмена
                </Button>
                <Button 
                    onClick={handleSave} 
                    disabled={isSaving || isDeleting || !folderName.trim()} 
                    className="rounded-full px-8 font-bold h-9 text-xs border-none transition-all active:scale-95 shadow-none bg-primary text-white hover:bg-primary/90"
                >
                    {isSaving && <Loader2 className="h-3 w-3 animate-spin mr-2" />}
                    {editingFolder ? 'Сохранить' : 'Создать'}
                </Button>
            </div>
          </div>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
