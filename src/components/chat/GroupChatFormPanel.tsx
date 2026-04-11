'use client';

import React, { useState, useEffect, useRef, useMemo } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { ref as storageRef, uploadBytesResumable, getDownloadURL } from 'firebase/storage';
import { doc, setDoc, updateDoc } from 'firebase/firestore';

import type { User, Conversation } from '@/lib/types';
import { canStartDirectChat } from '@/lib/user-chat-policy';
import {
  atUsernameLabel,
  userMatchesChatSearchQuery,
  splitUsersByContactsAndGlobalVisibility,
} from '@/lib/chat-user-search';
import { useStorage, useFirestore, useFirebaseApp } from '@/firebase';
import { checkGroupInvitesAllowed } from '@/lib/check-group-invites-allowed';
import { compressImage } from '@/lib/image-compression';
import { PlaceHolderImages } from '@/lib/placeholder-images';
import { useToast } from '@/hooks/use-toast';

import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Camera, Loader2, Users, Crown, ShieldOff, UserX, MoreVertical } from 'lucide-react';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { ROLES } from '@/lib/constants';
import { cn } from '@/lib/utils';
import { userAvatarListUrl } from '@/lib/user-avatar-display';

const groupChatFormSchema = z.object({
  name: z.string().min(1, 'Название группы обязательно'),
  description: z.string().optional(),
});

export type GroupChatFormPanelProps = {
  /** Синхронизация с внешним «открыт» (диалог / слой sheet). */
  open: boolean;
  allUsers: User[];
  contactIds?: string[];
  currentUser: User;
  initialData?: Conversation | null;
  onGroupCreated: (conversationId: string) => void;
  /** После успешного сохранения при редактировании */
  onEditSaved?: () => void;
  onCancel: () => void;
  /** Полоса над полями (например кнопка «Назад» в профиле группы). */
  toolbar?: React.ReactNode;
  /** Для блокировки закрытия диалога во время сохранения. */
  onBusyChange?: (busy: boolean) => void;
};

export function GroupChatFormPanel({
  open,
  allUsers,
  contactIds = [],
  currentUser,
  initialData,
  onGroupCreated,
  onEditSaved,
  onCancel,
  toolbar,
  onBusyChange,
}: GroupChatFormPanelProps) {
  const [isEditing, setIsEditing] = useState(!!initialData);
  const form = useForm<z.infer<typeof groupChatFormSchema>>({
    resolver: zodResolver(groupChatFormSchema),
  });

  const [participants, setParticipants] = useState<User[]>([]);
  const [adminIds, setAdminIds] = useState<Set<string>>(new Set());

  const [isProcessing, setIsProcessing] = useState(false);
  const [participantsHighlightError, setParticipantsHighlightError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [avatarFile, setAvatarFile] = useState<File | null>(null);
  const [avatarPreview, setAvatarPreview] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const participantsSectionRef = useRef<HTMLDivElement>(null);

  const firestore = useFirestore();
  const storage = useStorage();
  const firebaseApp = useFirebaseApp();
  const { toast } = useToast();

  useEffect(() => {
    onBusyChange?.(isProcessing);
  }, [isProcessing, onBusyChange]);

  const canManageParticipants =
    isEditing &&
    !!initialData &&
    (initialData.createdByUserId === currentUser.id ||
      (initialData.adminIds?.includes(currentUser.id) ?? false));

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
          .map((id) => allUsers.find((u) => u.id === id) || (id === currentUser.id ? currentUser : null))
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
      setParticipantsHighlightError(null);
    }
  }, [open, initialData, form, currentUser, allUsers]);

  useEffect(() => {
    if (!participantsHighlightError || !participantsSectionRef.current) return;
    participantsSectionRef.current.scrollIntoView({ behavior: 'smooth', block: 'center' });
  }, [participantsHighlightError]);

  const participantIdsSet = useMemo(() => new Set(participants.map((p) => p.id)), [participants]);

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
    setParticipants((prev) => prev.filter((p) => p.id !== userIdToRemove));
    setAdminIds((prev) => {
      const newAdmins = new Set(prev);
      newAdmins.delete(userIdToRemove);
      return newAdmins;
    });
  };

  const handleAddParticipant = (user: User) => {
    if (!participantIdsSet.has(user.id)) {
      setParticipants((prev) => [...prev, user]);
      setParticipantsHighlightError(null);
    }
  };

  const handleToggleAdmin = (userIdToToggle: string) => {
    if (isEditing && userIdToToggle === initialData?.createdByUserId) {
      toast({
        variant: 'destructive',
        title: 'Действие запрещено',
        description: 'Невозможно изменить права создателя группы.',
      });
      return;
    }

    if (adminIds.has(userIdToToggle) && adminIds.size === 1) {
      toast({ variant: 'destructive', title: 'Невозможно убрать последнего администратора' });
      return;
    }
    setAdminIds((prev) => {
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
      const description = isEditing
        ? 'В группе должен остаться хотя бы один участник.'
        : 'Добавьте хотя бы одного участника — группа не может состоять только из вас.';
      setParticipantsHighlightError(description);
      toast({ variant: 'destructive', title: 'Недостаточно участников', description });
      return;
    }
    setParticipantsHighlightError(null);
    if (adminIds.size === 0) {
      toast({
        variant: 'destructive',
        title: 'Нет администратора',
        description: 'В группе должен быть хотя бы один администратор.',
      });
      return;
    }

    setIsProcessing(true);

    try {
      const newMemberIds =
        isEditing && initialData
          ? participants.map((p) => p.id).filter((id) => !initialData.participantIds.includes(id))
          : participants.map((p) => p.id).filter((id) => id !== currentUser.id);

      if (newMemberIds.length > 0) {
        try {
          const { ok, denied } = await checkGroupInvitesAllowed(firebaseApp, newMemberIds);
          if (!ok) {
            const details = denied
              .map((d) => {
                const name =
                  participants.find((p) => p.id === d.uid)?.name ??
                  allUsers.find((u) => u.id === d.uid)?.name ??
                  'Участник';
                return d.reason === 'none'
                  ? `${name} не принимает приглашения в группы`
                  : `${name} разрешает групповые приглашения только от людей из своих контактов`;
              })
              .join(' ');
            toast({
              variant: 'destructive',
              title: 'Не удалось добавить в группу',
              description: details,
            });
            setIsProcessing(false);
            return;
          }
        } catch (checkErr) {
          console.error('checkGroupInvitesAllowed:', checkErr);
          toast({
            variant: 'destructive',
            title: 'Проверка не выполнена',
            description: 'Не удалось проверить настройки конфиденциальности. Попробуйте позже.',
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
        const placeholder = PlaceHolderImages.find((p) => p.id === 'group-avatar-placeholder');
        finalPhotoUrl = placeholder?.imageUrl || '';
      }

      const finalParticipantIds = participants.map((p) => p.id);
      const finalAdminIdsForDb = Array.from(adminIds).filter(
        (id) => id !== (initialData?.createdByUserId || currentUser.id)
      );

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
        onEditSaved?.();
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
          unreadCounts: Object.fromEntries(finalParticipantIds.map((id) => [id, 0])),
          typing: {},
        };
        await setDoc(doc(firestore, 'conversations', conversationId), newConversation);
        onGroupCreated(conversationId);
      }
      if (!isEditing) {
        onCancel();
      }
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      console.error(e);
      toast({
        variant: 'destructive',
        title: isEditing ? 'Ошибка обновления' : 'Ошибка создания группы',
        description: msg,
      });
    } finally {
      setIsProcessing(false);
    }
  };

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="flex min-h-0 flex-1 flex-col">
        {toolbar ? <div className="shrink-0 border-b bg-muted/20">{toolbar}</div> : null}
        <ScrollArea className="min-h-0 flex-1">
          <div className="space-y-4 px-6 py-4">
            <div className="flex flex-col items-center gap-4">
              <Avatar className="group/avatar relative h-24 w-24 border-none shadow-lg">
                <AvatarImage src={avatarPreview || undefined} alt={form.getValues('name')} />
                <AvatarFallback>
                  <Users className="h-10 w-10" />
                </AvatarFallback>
                <Button
                  type="button"
                  variant="ghost"
                  size="icon"
                  className="absolute inset-0 h-full w-full rounded-full border-none bg-black/30 text-white opacity-0 shadow-none group-hover/avatar:opacity-100"
                  onClick={() => fileInputRef.current?.click()}
                >
                  <Camera className="h-8 w-8" />
                </Button>
              </Avatar>
              <input
                type="file"
                disabled={isProcessing}
                ref={fileInputRef}
                className="hidden"
                accept="image/*"
                onChange={handleAvatarUpload}
              />
            </div>
            <FormField
              control={form.control}
              name="name"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Название группы</FormLabel>
                  <FormControl>
                    <Input {...field} className="rounded-xl" />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            <FormField
              control={form.control}
              name="description"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Описание</FormLabel>
                  <FormControl>
                    <Textarea {...field} className="rounded-xl" />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            <div
              ref={participantsSectionRef}
              role="group"
              aria-labelledby="group-form-participants-heading"
              aria-invalid={!!participantsHighlightError}
              aria-errormessage={
                participantsHighlightError ? 'group-form-participants-error' : undefined
              }
              className={cn(
                'space-y-2 rounded-xl transition-colors',
                participantsHighlightError && 'ring-2 ring-destructive/70 ring-offset-2 ring-offset-background'
              )}
            >
              <h3
                className={cn('text-lg font-medium', participantsHighlightError && 'text-destructive')}
                id="group-form-participants-heading"
              >
                Участники ({participants.length})
              </h3>
              {participantsHighlightError ? (
                <p id="group-form-participants-error" className="text-sm font-medium text-destructive" role="alert">
                  {participantsHighlightError}
                </p>
              ) : null}
              <ScrollArea className={cn('h-40 rounded-xl border', participantsHighlightError && 'border-destructive')}>
                <div className="space-y-1 p-2">
                  {participants.map((p) => {
                    const login = atUsernameLabel(p.username);
                    return (
                      <div key={p.id} className="flex items-center justify-between rounded-lg p-2 transition-colors hover:bg-muted">
                        <div className="flex min-w-0 items-center gap-3">
                          <Avatar className="h-9 w-9 shrink-0 border-none">
                            <AvatarImage src={userAvatarListUrl(p)} />
                            <AvatarFallback>{p.name.charAt(0)}</AvatarFallback>
                          </Avatar>
                          <div className="min-w-0">
                            <p className="truncate text-sm font-semibold leading-tight">{p.name}</p>
                            {login ? <p className="truncate text-xs text-muted-foreground">{login}</p> : null}
                            {p.role && p.role !== 'worker' ? (
                              <p className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">
                                {adminIds.has(p.id) ? 'Администратор' : ROLES[p.role]}
                              </p>
                            ) : null}
                            {p.role === 'worker' && adminIds.has(p.id) ? (
                              <p className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">
                                Администратор
                              </p>
                            ) : null}
                          </div>
                        </div>
                        {canManageParticipants && p.id !== currentUser.id ? (
                          <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                              <Button variant="ghost" size="icon" className="h-8 w-8 rounded-full border-none shadow-none">
                                <MoreVertical className="h-4 w-4" />
                              </Button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent align="end" className="rounded-xl">
                              <DropdownMenuItem onSelect={() => handleToggleAdmin(p.id)} disabled={p.id === initialData?.createdByUserId}>
                                {adminIds.has(p.id) ? (
                                  <ShieldOff className="mr-2 h-4 w-4" />
                                ) : (
                                  <Crown className="mr-2 h-4 w-4" />
                                )}
                                {adminIds.has(p.id) ? 'Разжаловать' : 'Сделать админом'}
                              </DropdownMenuItem>
                              <DropdownMenuItem
                                className="text-destructive"
                                onSelect={() => handleRemoveParticipant(p.id)}
                                disabled={p.id === initialData?.createdByUserId}
                              >
                                <UserX className="mr-2 h-4 w-4" /> Удалить из группы
                              </DropdownMenuItem>
                            </DropdownMenuContent>
                          </DropdownMenu>
                        ) : null}
                      </div>
                    );
                  })}
                </div>
              </ScrollArea>
            </div>

            <div className="space-y-2">
              <h3 className="text-lg font-medium">Добавить участников</h3>
              <div className="relative">
                <Input
                  placeholder="Поиск пользователей..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="h-11 rounded-full"
                />
              </div>
              <ScrollArea className="h-40 overflow-hidden rounded-xl border">
                <div className="space-y-0.5 p-1">
                  {addFromContacts.length > 0 ? (
                    <>
                      <p className="px-2 py-1 text-[9px] font-bold uppercase tracking-wider text-muted-foreground">
                        Контакты
                      </p>
                      {addFromContacts.map((user) => {
                        const login = atUsernameLabel(user.username);
                        return (
                          <div
                            key={user.id}
                            className="flex cursor-pointer items-center gap-3 rounded-lg p-2 transition-colors hover:bg-muted"
                            onClick={() => {
                              handleAddParticipant(user);
                              setSearchTerm('');
                            }}
                          >
                            <Avatar className="h-8 w-8 shrink-0 border-none">
                              <AvatarImage src={userAvatarListUrl(user)} />
                              <AvatarFallback>{user.name.charAt(0)}</AvatarFallback>
                            </Avatar>
                            <div className="min-w-0">
                              <span className="block truncate text-sm font-medium leading-tight">{user.name}</span>
                              {login ? (
                                <span className="block truncate text-xs text-muted-foreground">{login}</span>
                              ) : null}
                              {user.role && user.role !== 'worker' ? (
                                <span className="text-[9px] font-bold uppercase tracking-wider text-muted-foreground">
                                  {ROLES[user.role]}
                                </span>
                              ) : null}
                            </div>
                          </div>
                        );
                      })}
                    </>
                  ) : null}
                  {addFromGlobal.length > 0 ? (
                    <>
                      <p
                        className={cn(
                          'px-2 py-1 text-[9px] font-bold uppercase tracking-wider text-muted-foreground',
                          addFromContacts.length === 0 ? 'pt-0.5' : 'pt-1'
                        )}
                      >
                        Все пользователи
                      </p>
                      {addFromGlobal.map((user) => {
                        const login = atUsernameLabel(user.username);
                        return (
                          <div
                            key={user.id}
                            className="flex cursor-pointer items-center gap-3 rounded-lg p-2 transition-colors hover:bg-muted"
                            onClick={() => {
                              handleAddParticipant(user);
                              setSearchTerm('');
                            }}
                          >
                            <Avatar className="h-8 w-8 shrink-0 border-none">
                              <AvatarImage src={userAvatarListUrl(user)} />
                              <AvatarFallback>{user.name.charAt(0)}</AvatarFallback>
                            </Avatar>
                            <div className="min-w-0">
                              <span className="block truncate text-sm font-medium leading-tight">{user.name}</span>
                              {login ? (
                                <span className="block truncate text-xs text-muted-foreground">{login}</span>
                              ) : null}
                              {user.role && user.role !== 'worker' ? (
                                <span className="text-[9px] font-bold uppercase tracking-wider text-muted-foreground">
                                  {ROLES[user.role]}
                                </span>
                              ) : null}
                            </div>
                          </div>
                        );
                      })}
                    </>
                  ) : null}
                  {addFromContacts.length === 0 && addFromGlobal.length === 0 ? (
                    <p className="p-4 text-center text-xs text-muted-foreground">Нет доступных пользователей</p>
                  ) : null}
                </div>
              </ScrollArea>
            </div>
          </div>
        </ScrollArea>

        <div className="flex w-full shrink-0 flex-row justify-end gap-2 border-t bg-muted/10 p-6 pt-4">
          <Button
            type="button"
            variant="ghost"
            onClick={onCancel}
            disabled={isProcessing}
            className="rounded-full border-none font-bold shadow-none"
          >
            Отмена
          </Button>
          <Button type="submit" disabled={isProcessing} className="min-w-[120px] rounded-full font-bold shadow-lg shadow-primary/20">
            {isProcessing ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : isEditing ? 'Сохранить' : 'Создать'}
          </Button>
        </div>
      </form>
    </Form>
  );
}
