'use client';

import React, { useState, useEffect, useRef, useMemo } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { ref as storageRef, uploadBytesResumable, getDownloadURL } from 'firebase/storage';
import { doc, setDoc, updateDoc } from 'firebase/firestore';

import type { User, Conversation } from '@/lib/types';
import { canStartDirectChat } from '@/lib/user-chat-policy';
import { userMatchesChatSearchQuery, splitUsersByContactsAndGlobalVisibility } from '@/lib/chat-user-search';
import { useStorage, useFirestore, useFirebaseApp } from '@/firebase';
import { checkGroupInvitesAllowed } from '@/lib/check-group-invites-allowed';
import { compressImage } from '@/lib/image-compression';
import { PlaceHolderImages } from '@/lib/placeholder-images';
import { useToast } from '@/hooks/use-toast';

import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from '@/components/ui/dialog';
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Camera, Loader2, Users, Crown, ShieldOff, UserX, MoreVertical } from 'lucide-react';
import { Badge } from '../ui/badge';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { ROLES } from '@/lib/constants';
import { cn } from '@/lib/utils';

const groupChatFormSchema = z.object({
  name: z.string().min(1, 'Название группы обязательно'),
  description: z.string().optional(),
});

export function GroupChatFormDialog({
  open,
  onOpenChange,
  allUsers,
  contactIds = [],
  currentUser,
  onGroupCreated,
  initialData,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  allUsers: User[];
  contactIds?: string[];
  currentUser: User;
  onGroupCreated: (conversationId: string) => void;
  initialData?: Conversation | null;
}) {
  const [isEditing, setIsEditing] = useState(!!initialData);
  const form = useForm<z.infer<typeof groupChatFormSchema>>({
    resolver: zodResolver(groupChatFormSchema),
  });

  const [participants, setParticipants] = useState<User[]>([]);
  const [adminIds, setAdminIds] = useState<Set<string>>(new Set());

  const [isProcessing, setIsProcessing] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [avatarFile, setAvatarFile] = useState<File | null>(null);
  const [avatarPreview, setAvatarPreview] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const firestore = useFirestore();
  const storage = useStorage();
  const firebaseApp = useFirebaseApp();
  const { toast } = useToast();

  useEffect(() => {
    if (open) {
      const editing = !!initialData;
      setIsEditing(editing);
      if (editing) {
        form.reset({
          name: initialData.name || '',
          description: initialData.description || '',
        });
        const uniqueParticipantIds = [...new Set(initialData.participantIds)];
        const currentParticipants = uniqueParticipantIds
          .map(id => allUsers.find(u => u.id === id) || (id === currentUser.id ? currentUser : null))
          .filter((u): u is User => !!u);
        setParticipants(currentParticipants);
        
        const initialAdmins = new Set(initialData.adminIds || []);
        if (initialData.createdByUserId) {
            initialAdmins.add(initialData.createdByUserId);
        }
        setAdminIds(initialAdmins);

        setAvatarPreview(initialData.photoUrl || null);
      } else {
        form.reset({ name: '', description: '' });
        setParticipants([currentUser]);
        setAdminIds(new Set([currentUser.id]));
        setAvatarPreview(null);
      }
      setAvatarFile(null);
      setSearchTerm('');
    }
  }, [open, initialData, form, currentUser, allUsers]);

  const participantIdsSet = useMemo(() => new Set(participants.map(p => p.id)), [participants]);
  
  const { fromContacts: addFromContacts, fromGlobal: addFromGlobal } = useMemo(() => {
    const matched = allUsers.filter((u) => {
      if (participantIdsSet.has(u.id)) return false;
      if (!userMatchesChatSearchQuery(u, searchTerm)) return false;
      return canStartDirectChat(currentUser, u);
    });
    return splitUsersByContactsAndGlobalVisibility(matched, currentUser, contactIds);
  }, [allUsers, searchTerm, participantIdsSet, currentUser, contactIds]);

  const handleAvatarUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    setIsProcessing(true);
    try {
      const compressedDataUri = await compressImage(file, 0.8, 512);
      setAvatarPreview(compressedDataUri);
      const response = await fetch(compressedDataUri);
      const blob = await response.blob();
      setAvatarFile(new File([blob], file.name, { type: 'image/jpeg' }));
    } catch (e) {
      toast({ variant: 'destructive', title: 'Ошибка обработки фото' });
    } finally {
      setIsProcessing(false);
    }
  };

  const uploadAvatar = async (file: File, conversationId: string): Promise<string> => {
    const filePath = `group-avatars/${conversationId}/${Date.now()}_${file.name.replace(/\s/g, '_')}`;
    const fileRef = storageRef(storage, filePath);
    await uploadBytesResumable(fileRef, file);
    return getDownloadURL(fileRef);
  };
  
  const handleRemoveParticipant = (userIdToRemove: string) => {
    if (userIdToRemove === initialData?.createdByUserId) {
        toast({ variant: 'destructive', title: 'Невозможно удалить создателя группы' });
        return;
    }
    setParticipants(prev => prev.filter(p => p.id !== userIdToRemove));
    setAdminIds(prev => {
        const newAdmins = new Set(prev);
        newAdmins.delete(userIdToRemove);
        return newAdmins;
    });
  };
  
  const handleAddParticipant = (user: User) => {
    if (!participantIdsSet.has(user.id)) {
      setParticipants(prev => [...prev, user]);
    }
  };

  const handleToggleAdmin = (userIdToToggle: string) => {
    if (isEditing && userIdToToggle === initialData?.createdByUserId) {
      toast({ variant: 'destructive', title: 'Действие запрещено', description: 'Невозможно изменить права создателя группы.' });
      return;
    }
    
    if (adminIds.has(userIdToToggle) && adminIds.size === 1) {
        toast({ variant: 'destructive', title: 'Невозможно убрать последнего администратора' });
        return;
    }
    setAdminIds(prev => {
        const newAdmins = new Set(prev);
        if (newAdmins.has(userIdToToggle)) {
            newAdmins.delete(userIdToToggle);
        } else {
            newAdmins.add(userIdToToggle);
        }
        return newAdmins;
    });
  };


  const onSubmit = async (data: z.infer<typeof groupChatFormSchema>) => {
    if (!firestore) return;
    
    if (participants.length < (isEditing ? 1 : 2)) {
        toast({ variant: 'destructive', title: 'Недостаточно участников', description: 'В группе должно быть хотя бы 2 человека.' });
        return;
    }
    if (adminIds.size === 0) {
        toast({ variant: 'destructive', title: 'Нет администратора', description: 'В группе должен быть хотя бы один администратор.' });
        return;
    }

    setIsProcessing(true);

    try {
      const newMemberIds =
        isEditing && initialData
          ? participants
              .map((p) => p.id)
              .filter((id) => !initialData.participantIds.includes(id))
          : participants
              .map((p) => p.id)
              .filter((id) => id !== currentUser.id);

      if (newMemberIds.length > 0) {
        try {
          const { ok, denied } = await checkGroupInvitesAllowed(
            firebaseApp,
            newMemberIds
          );
          if (!ok) {
            const details = denied
              .map((d) => {
                const name =
                  participants.find((p) => p.id === d.uid)?.name ??
                  allUsers.find((u) => u.id === d.uid)?.name ??
                  "Участник";
                return d.reason === "none"
                  ? `${name} не принимает приглашения в группы`
                  : `${name} разрешает групповые приглашения только от людей из своих контактов`;
              })
              .join(" ");
            toast({
              variant: "destructive",
              title: "Не удалось добавить в группу",
              description: details,
            });
            setIsProcessing(false);
            return;
          }
        } catch (checkErr) {
          console.error("checkGroupInvitesAllowed:", checkErr);
          toast({
            variant: "destructive",
            title: "Проверка не выполнена",
            description:
              "Не удалось проверить настройки конфиденциальности. Попробуйте позже.",
          });
          setIsProcessing(false);
          return;
        }
      }

      let finalPhotoUrl = initialData?.photoUrl || avatarPreview || '';
      const conversationId = initialData?.id || `group_${Date.now()}`;

      if (avatarFile) {
        finalPhotoUrl = await uploadAvatar(avatarFile, conversationId);
      } else if (!isEditing && !finalPhotoUrl) {
        const placeholder = PlaceHolderImages.find(p => p.id === 'group-avatar-placeholder');
        finalPhotoUrl = placeholder?.imageUrl || '';
      }
      
      const finalParticipantIds = participants.map(p => p.id);
      const finalAdminIdsForDb = Array.from(adminIds).filter(id => id !== (initialData?.createdByUserId || currentUser.id));

      const participantInfo: Conversation['participantInfo'] = {};
      
      allUsers.concat([currentUser]).forEach((user) => {
        if (finalParticipantIds.includes(user.id)) {
          participantInfo[user.id] = { name: user.name };
        }
      });
        
      if (isEditing && initialData) {
        await updateDoc(doc(firestore, 'conversations', initialData.id), {
          name: data.name,
          description: data.description,
          photoUrl: finalPhotoUrl,
          participantIds: finalParticipantIds,
          adminIds: finalAdminIdsForDb,
          participantInfo: participantInfo,
        });
        toast({ title: 'Группа обновлена' });
      } else {
        const newConversation: Omit<Conversation, 'id'> = {
          isGroup: true,
          name: data.name,
          description: data.description,
          photoUrl: finalPhotoUrl,
          participantIds: finalParticipantIds,
          adminIds: finalAdminIdsForDb,
          participantInfo,
          createdByUserId: currentUser.id,
          lastMessageTimestamp: new Date().toISOString(),
          lastMessageText: `${currentUser.name} создал(а) группу`,
          unreadCounts: Object.fromEntries(finalParticipantIds.map(id => [id, 0])),
          typing: {},
        };
        await setDoc(doc(firestore, 'conversations', conversationId), newConversation);
        onGroupCreated(conversationId);
      }
      onOpenChange(false);
    } catch (e: any) {
      console.error(e);
      toast({ variant: 'destructive', title: isEditing ? 'Ошибка обновления' : 'Ошибка создания группы', description: e.message });
    } finally {
      setIsProcessing(false);
    }
  };


  return (
    <Dialog open={open} onOpenChange={(open) => !isProcessing && onOpenChange(false)}>
      <DialogContent className="sm:max-w-md rounded-2xl p-0 flex flex-col h-[90vh] border-none shadow-2xl">
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="flex flex-col flex-1 min-h-0">
            <DialogHeader className="p-6 pb-4 flex-shrink-0 bg-muted/30">
              <DialogTitle>{isEditing ? 'Управление группой' : 'Создать группу'}</DialogTitle>
            </DialogHeader>

            <ScrollArea className="flex-1 px-6">
              <div className="space-y-4 py-4">
                <div className="flex flex-col items-center gap-4">
                  <Avatar className="h-24 w-24 relative group/avatar shadow-lg border-none">
                    <AvatarImage src={avatarPreview || undefined} alt={form.getValues('name')} />
                    <AvatarFallback><Users className="h-10 w-10" /></AvatarFallback>
                    <Button type="button" variant="ghost" size="icon" className="absolute inset-0 bg-black/30 text-white opacity-0 group-hover/avatar:opacity-100 rounded-full h-full w-full shadow-none border-none" onClick={() => fileInputRef.current?.click()}>
                      <Camera className="h-8 w-8" />
                    </Button>
                  </Avatar>
                  <input type="file" disabled={isProcessing} ref={fileInputRef} className="hidden" accept="image/*" onChange={handleAvatarUpload} />
                </div>
                <FormField control={form.control} name="name" render={({ field }) => (
                  <FormItem><FormLabel>Название группы</FormLabel><FormControl><Input {...field} className="rounded-xl" /></FormControl><FormMessage /></FormItem>
                )} />
                <FormField control={form.control} name="description" render={({ field }) => (
                  <FormItem><FormLabel>Описание</FormLabel><FormControl><Textarea {...field} className="rounded-xl" /></FormControl><FormMessage /></FormItem>
                )} />
                
                <div className="space-y-2">
                    <h3 className="text-lg font-medium">Участники ({participants.length})</h3>
                    <ScrollArea className="h-40 rounded-xl border">
                        <div className="p-2 space-y-1">
                            {participants.map(p => (
                                <div key={p.id} className="flex items-center justify-between p-2 hover:bg-muted rounded-lg transition-colors">
                                    <div className="flex items-center gap-3">
                                        <Avatar className="h-9 w-9 border-none">
                                            <AvatarImage src={p.avatar} />
                                            <AvatarFallback>{p.name.charAt(0)}</AvatarFallback>
                                        </Avatar>
                                        <div>
                                            <p className="font-semibold text-sm leading-tight">{p.name}</p>
                                            {p.role && p.role !== 'worker' && <p className="text-[10px] text-muted-foreground uppercase font-bold tracking-wider">{adminIds.has(p.id) ? 'Администратор' : ROLES[p.role]}</p>}
                                            {p.role === 'worker' && adminIds.has(p.id) && <p className="text-[10px] text-muted-foreground uppercase font-bold tracking-wider">Администратор</p>}
                                        </div>
                                    </div>
                                    {isEditing && p.id !== currentUser.id && adminIds.has(currentUser.id) && (
                                         <DropdownMenu>
                                            <DropdownMenuTrigger asChild><Button variant="ghost" size="icon" className="rounded-full h-8 w-8 shadow-none border-none"><MoreVertical className="h-4 w-4" /></Button></DropdownMenuTrigger>
                                            <DropdownMenuContent align="end" className="rounded-xl">
                                                <DropdownMenuItem onSelect={() => handleToggleAdmin(p.id)} disabled={p.id === initialData?.createdByUserId}>
                                                    {adminIds.has(p.id) ? <ShieldOff className="mr-2 h-4 w-4"/> : <Crown className="mr-2 h-4 w-4"/>}
                                                    {adminIds.has(p.id) ? 'Разжаловать' : 'Сделать админом'}
                                                </DropdownMenuItem>
                                                <DropdownMenuItem className="text-destructive" onSelect={() => handleRemoveParticipant(p.id)} disabled={p.id === initialData?.createdByUserId}>
                                                    <UserX className="mr-2 h-4 w-4" /> Удалить из группы
                                                </DropdownMenuItem>
                                            </DropdownMenuContent>
                                        </DropdownMenu>
                                    )}
                                </div>
                            ))}
                        </div>
                    </ScrollArea>
                </div>
                
                <div className="space-y-2">
                  <h3 className="text-lg font-medium">Добавить участников</h3>
                  <div className="relative">
                    <Input placeholder="Поиск пользователей..." value={searchTerm} onChange={e => setSearchTerm(e.target.value)} className="rounded-full h-11" />
                  </div>
                  <ScrollArea className="h-40 border rounded-xl overflow-hidden">
                    <div className="space-y-0.5 p-1">
                      {addFromContacts.length > 0 && (
                        <>
                          <p className="px-2 py-1 text-[9px] font-bold uppercase tracking-wider text-muted-foreground">
                            Контакты
                          </p>
                          {addFromContacts.map((user) => (
                            <div
                              key={user.id}
                              className="flex cursor-pointer items-center gap-3 rounded-lg p-2 transition-colors hover:bg-muted"
                              onClick={() => {
                                handleAddParticipant(user);
                                setSearchTerm('');
                              }}
                            >
                              <Avatar className="h-8 w-8 border-none">
                                <AvatarImage src={user.avatar} />
                                <AvatarFallback>{user.name.charAt(0)}</AvatarFallback>
                              </Avatar>
                              <div>
                                <span className="block text-sm font-medium leading-tight">{user.name}</span>
                                {user.role && user.role !== 'worker' && (
                                  <span className="text-[9px] font-bold uppercase tracking-wider text-muted-foreground">
                                    {ROLES[user.role]}
                                  </span>
                                )}
                              </div>
                            </div>
                          ))}
                        </>
                      )}
                      {addFromGlobal.length > 0 && (
                        <>
                          <p
                            className={cn(
                              'px-2 py-1 text-[9px] font-bold uppercase tracking-wider text-muted-foreground',
                              addFromContacts.length === 0 ? 'pt-0.5' : 'pt-1'
                            )}
                          >
                            Все пользователи
                          </p>
                          {addFromGlobal.map((user) => (
                            <div
                              key={user.id}
                              className="flex cursor-pointer items-center gap-3 rounded-lg p-2 transition-colors hover:bg-muted"
                              onClick={() => {
                                handleAddParticipant(user);
                                setSearchTerm('');
                              }}
                            >
                              <Avatar className="h-8 w-8 border-none">
                                <AvatarImage src={user.avatar} />
                                <AvatarFallback>{user.name.charAt(0)}</AvatarFallback>
                              </Avatar>
                              <div>
                                <span className="block text-sm font-medium leading-tight">{user.name}</span>
                                {user.role && user.role !== 'worker' && (
                                  <span className="text-[9px] font-bold uppercase tracking-wider text-muted-foreground">
                                    {ROLES[user.role]}
                                  </span>
                                )}
                              </div>
                            </div>
                          ))}
                        </>
                      )}
                      {addFromContacts.length === 0 && addFromGlobal.length === 0 && (
                        <p className="p-4 text-center text-xs text-muted-foreground">Нет доступных пользователей</p>
                      )}
                    </div>
                  </ScrollArea>
                </div>
              </div>
            </ScrollArea>
            
            <DialogFooter className="flex-shrink-0 p-6 pt-4 border-t flex flex-row justify-end w-full bg-muted/10">
                <Button type="button" variant="ghost" onClick={() => onOpenChange(false)} disabled={isProcessing} className="rounded-full font-bold shadow-none border-none">Отмена</Button>
                <Button type="submit" disabled={isProcessing} className="rounded-full font-bold shadow-lg shadow-primary/20 min-w-[120px]">
                    {isProcessing ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : (isEditing ? 'Сохранить' : 'Создать')}
                </Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  );
}
