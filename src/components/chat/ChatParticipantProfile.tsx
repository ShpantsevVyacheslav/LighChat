'use client';

import type { User, Conversation, ChatMessage, ChatAttachment, UserRole, ProfileTab, UserContactsIndex } from '@/lib/types';
import { ROLES } from '@/lib/constants';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetDescription, SheetClose } from '@/components/ui/sheet';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { ScrollArea } from '@/components/ui/scroll-area';
import { File as FileIcon, Image as ImageIcon, Link as LinkIcon, Download, Mic, X, Play, ArrowLeft, Users, Edit, Mail, ShieldCheck, Cake, LogOut, MessageSquare, Clock, Video, Smartphone, UserRound, MapPin, UserPlus, Loader2, ChevronDown } from 'lucide-react';
import Link from 'next/link';
import { useMemo, useState, useRef, useEffect, useCallback } from 'react';
import { Button } from '../ui/button';
import { cn, formatDuration } from '@/lib/utils';
import { Separator } from '../ui/separator';
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from '@/components/ui/collapsible';
import { Badge } from '../ui/badge';
import { format, isToday, isYesterday, parseISO } from 'date-fns';
import { ru } from 'date-fns/locale';
import { useRouter } from 'next/navigation';
import { Dialog, DialogContent, DialogTrigger, DialogClose, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog";
import { useDoc, useFirestore, useMemoFirebase } from '@/firebase';
import { doc } from 'firebase/firestore';
import { VideoCirclePlayer } from './VideoCirclePlayer';
import { formatPhoneNumberForDisplay } from '@/lib/phone-utils';
import { isProfileFieldVisibleToOthers } from '@/lib/profile-field-visibility';
import { isSavedMessagesChat } from '@/lib/saved-messages-chat';
import { isLiveShareVisible } from '@/lib/live-location-utils';
import { LiveLocationMapDialog } from '@/components/location/LiveLocationMapDialog';
import { sanitizeMessageHtml } from '@/lib/sanitize-message-html';
import { userAvatarListUrl } from '@/lib/user-avatar-display';
import { useToast } from '@/hooks/use-toast';
import { addContactId } from '@/lib/contacts-client-actions';
import { canStartDirectChat } from '@/lib/user-chat-policy';

const isOnlyEmojis = (text: string) => {
    if (!text) return false;
    const emojiRegex = /^(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff]|\s)+$/g;
    return emojiRegex.test(text.trim());
};

const extractUrls = (text: string): string[] => {
  if (!text) return [];
  const urlRegex = /(https?:\/\/[^\s]+)/g;
  return text.match(urlRegex) || [];
};

function VideoThumbnailWithDuration({ video, onClick }: { video: ChatAttachment, onClick: () => void }) {
    const [duration, setDuration] = useState<number | null>(null);
    const videoRef = useRef<HTMLVideoElement>(null);

    useEffect(() => {
        const v = videoRef.current;
        if (!v) return;
        
        const handleLoadedMetadata = () => {
            if (v.duration && isFinite(v.duration)) {
                setDuration(v.duration);
            }
        };
        
        if (v.readyState >= 1) {
            handleLoadedMetadata();
        } else {
            v.addEventListener('loadedmetadata', handleLoadedMetadata);
        }
        
        return () => v.removeEventListener('loadedmetadata', handleLoadedMetadata);
    }, [video.url]);

    const formatTime = (time: number) => {
        if (isNaN(time) || !isFinite(time) || time === 0) return '0:00';
        const minutes = Math.floor(time / 60);
        const seconds = Math.floor(time % 60);
        return `${minutes}:${seconds.toString().padStart(2, '0')}`;
    };

    return (
        <div 
            className="relative aspect-square bg-muted overflow-hidden cursor-pointer group rounded-xl"
            onClick={onClick}
        >
            <video ref={videoRef} src={`${video.url}#t=0.1`} className="absolute inset-0 w-full h-full object-cover" preload="metadata" muted />
            <div className="absolute inset-0 flex items-center justify-center bg-black/20 group-hover:bg-black/40 transition-colors">
                <Play className="h-6 w-6 text-white fill-white opacity-80" />
            </div>
            {duration !== null && (
                <div className="absolute bottom-1.5 right-1.5 flex items-center gap-1 bg-black/60 backdrop-blur-md px-1.5 py-0.5 rounded text-[10px] font-bold text-white shadow-sm font-mono border border-white/10">
                    <span>{formatTime(duration)}</span>
                </div>
            )}
        </div>
    );
}

interface ChatParticipantProfileProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  conversation: Conversation;
  allUsers: User[];
  currentUser: User;
  messages: ChatMessage[];
  onImageClick: (image: ChatAttachment) => void;
  onSelectConversation: (conversationId: string) => void;
  onEditGroup: (conversation: Conversation) => void;
  onOpenThread: (message: ChatMessage) => void;
  initialTab?: ProfileTab;
  /** В группе: показать шапку и поля выбранного участника (клик по @). */
  focusUserId?: string | null;
  onClearProfileFocus?: () => void;
}

export function ChatParticipantProfile({ 
    open, 
    onOpenChange, 
    conversation, 
    allUsers, 
    currentUser, 
    messages, 
    onImageClick, 
    onSelectConversation, 
    onEditGroup,
    onOpenThread,
    initialTab = 'threads',
    focusUserId = null,
    onClearProfileFocus,
}: ChatParticipantProfileProps) {
  const [isParticipantsListOpen, setIsParticipantsOpen] = useState(false);
  const [activeCircleUrl, setActiveCircleUrl] = useState<string | null>(null);
  const [liveMapOpen, setLiveMapOpen] = useState(false);
  const router = useRouter();
  const firestore = useFirestore();
  const isGroup = conversation.isGroup;
  const isSelfSavedChat = useMemo(
    () => !isGroup && isSavedMessagesChat(conversation, currentUser.id),
    [isGroup, conversation, currentUser.id]
  );

  const touchStartX = useRef<number | null>(null);
  const touchStartY = useRef<number | null>(null);

  const otherId = useMemo(() => {
    if (isGroup) return null;
    if (isSelfSavedChat) return currentUser.id;
    return conversation.participantIds.find((id) => id !== currentUser.id) ?? null;
  }, [isGroup, isSelfSavedChat, conversation.participantIds, currentUser.id]);

  const showMemberFocus =
    isGroup &&
    !!focusUserId &&
    conversation.participantIds.includes(focusUserId);

  const profileDocId = useMemo(() => {
    if (isGroup) {
      if (focusUserId && conversation.participantIds.includes(focusUserId)) return focusUserId;
      return null;
    }
    if (focusUserId && conversation.participantIds.includes(focusUserId)) return focusUserId;
    return otherId;
  }, [isGroup, focusUserId, conversation.participantIds, otherId]);

  const participantRef = useMemoFirebase(
    () => (firestore && profileDocId ? doc(firestore, 'users', profileDocId) : null),
    [firestore, profileDocId]
  );
  
  const { data: freshParticipant } = useDoc<User>(participantRef);

  const userContactsRef = useMemoFirebase(
    () => (firestore && currentUser?.id ? doc(firestore, 'userContacts', currentUser.id) : null),
    [firestore, currentUser?.id]
  );
  const { data: contactsIndex } = useDoc<UserContactsIndex>(userContactsRef);
  const contactIds = contactsIndex?.contactIds ?? [];
  const isContact = Boolean(profileDocId && contactIds.includes(profileDocId));

  /**
   * Участник для политики «добавить в контакты»: live-документ, список allUsers или минимальный User
   * из participantInfo — иначе до прихода Firestore кнопка пропадала (contactTargetUser === null).
   */
  const contactTargetUser = useMemo((): User | null => {
    if (!profileDocId) return null;
    if (freshParticipant && freshParticipant.id === profileDocId) return freshParticipant;
    const fromList = allUsers.find((u) => u.id === profileDocId);
    if (fromList) return fromList;
    const info = conversation.participantInfo[profileDocId];
    return {
      id: profileDocId,
      name: info?.name || 'Пользователь',
      username: '',
      email: '',
      avatar: info?.avatar || '',
      phone: '',
      deletedAt: null,
      createdAt: '',
      role: undefined,
    };
  }, [profileDocId, freshParticipant, allUsers, conversation.participantInfo]);

  const canShowAddToContacts = useMemo(() => {
    if (!profileDocId || profileDocId === currentUser.id || isSelfSavedChat) return false;
    if (isGroup && !showMemberFocus) return false;
    if (!contactTargetUser || contactTargetUser.deletedAt) return false;
    if (isContact) return true;
    return canStartDirectChat(currentUser, contactTargetUser);
  }, [
    profileDocId,
    currentUser,
    isSelfSavedChat,
    contactTargetUser,
    isContact,
    isGroup,
    showMemberFocus,
  ]);

  const { toast } = useToast();
  const [addContactBusy, setAddContactBusy] = useState(false);

  const handleAddToContacts = useCallback(async () => {
    if (!firestore || !profileDocId || !contactTargetUser || isContact) return;
    setAddContactBusy(true);
    try {
      await addContactId(firestore, currentUser.id, profileDocId);
      toast({ title: 'Добавлено в контакты', description: contactTargetUser.name });
    } catch (e) {
      console.warn('[LighChat:contacts] add from participant profile', e);
      toast({ title: 'Не удалось добавить в контакты', variant: 'destructive' });
    } finally {
      setAddContactBusy(false);
    }
  }, [firestore, profileDocId, contactTargetUser, isContact, currentUser.id, toast]);

  const displayParticipantInfo = useMemo(() => {
    if (!profileDocId) return null;
    const info = conversation.participantInfo[profileDocId];
    return {
      name: freshParticipant?.name || info?.name || 'Пользователь',
      avatar: freshParticipant?.avatar || info?.avatar || '',
      email: freshParticipant?.email || '',
      phone: freshParticipant?.phone || '',
      bio: freshParticipant?.bio || '',
      role: freshParticipant?.role || '',
      online: freshParticipant?.online || false,
      lastSeen: freshParticipant?.lastSeen || '',
      dateOfBirth: freshParticipant?.dateOfBirth || null,
      deletedAt: freshParticipant?.deletedAt || null
    };
  }, [profileDocId, conversation.participantInfo, freshParticipant]);

  /** Строки блока «контакты / о себе» — показываем один сворачиваемый блок вместо длинного списка. */
  const hasContactDetailsRows = useMemo(() => {
    if (!displayParticipantInfo || isSelfSavedChat || (isGroup && !showMemberFocus)) return false;
    const dpi = displayParticipantInfo;
    if (dpi.role && dpi.role !== 'worker') return true;
    if (!freshParticipant) return false;
    const fp = freshParticipant;
    if (isProfileFieldVisibleToOthers(fp, 'email') && dpi.email) return true;
    if (isProfileFieldVisibleToOthers(fp, 'phone') && dpi.phone?.trim()) return true;
    if (isProfileFieldVisibleToOthers(fp, 'dateOfBirth') && dpi.dateOfBirth) return true;
    if (isProfileFieldVisibleToOthers(fp, 'bio') && dpi.bio?.trim()) return true;
    return false;
  }, [displayParticipantInfo, freshParticipant, isSelfSavedChat, isGroup, showMemberFocus]);

  const { media, files, links, audios, stickers, threadMessages, circles } = useMemo(() => {
    const files: ChatAttachment[] = [];
    const links: { url: string; messageId: string }[] = [];
    const audios: ChatAttachment[] = [];
    const stickers: ChatAttachment[] = [];
    const media: ChatAttachment[] = [];
    const circles: (ChatAttachment & { senderId: string; createdAt: string })[] = [];
    const threadMessages: ChatMessage[] = [];

    messages.forEach(msg => {
      if (msg.isDeleted) return;
      
      if (msg.threadCount && msg.threadCount > 0) {
          threadMessages.push(msg);
      }

      if (msg.text && isOnlyEmojis(msg.text)) return;

      if (msg.attachments) {
        msg.attachments.forEach(att => {
          const isSticker = att.name.startsWith('sticker_') || att.type.includes('svg');
          const isVideoCircle = att.name.startsWith('video-circle_');

          if (isSticker) {
            stickers.push(att);
          } else if (isVideoCircle) {
            circles.push({ ...att, senderId: msg.senderId, createdAt: msg.createdAt });
          } else if (att.type.startsWith('image/') || att.type.startsWith('video/')) {
            media.push(att);
          } else if (att.type.startsWith('audio/')) {
            audios.push(att);
          } else {
            files.push(att);
          }
        });
      }
      if (msg.text) {
        const foundUrls = extractUrls(msg.text);
        foundUrls.forEach(url => links.push({ url, messageId: msg.id }));
      }
    });

    const uniqueMedia = media.filter((att, index, self) => index === self.findIndex(t => t.url === att.url));
    const uniqueFiles = files.filter((att, index, self) => index === self.findIndex(t => t.url === att.url));
    const uniqueLinks = links.filter((link, index, self) => index === self.findIndex(t => t.url === link.url));
    const uniqueAudios = audios.filter((att, index, self) => index === self.findIndex(t => t.url === att.url));
    const uniqueStickers = stickers.filter((att, index, self) => index === self.findIndex(t => t.name === att.name));
    const uniqueCircles = circles.filter((att, index, self) => index === self.findIndex(t => t.url === att.url));

    return { 
        media: uniqueMedia, 
        files: uniqueFiles, 
        links: uniqueLinks, 
        audios: uniqueAudios, 
        stickers: uniqueStickers,
        circles: uniqueCircles,
        threadMessages: threadMessages.sort((a,b) => {
            const timeA = parseISO(a.lastThreadMessageTimestamp || a.createdAt).getTime();
            const timeB = parseISO(b.lastThreadMessageTimestamp || b.createdAt).getTime();
            return timeB - timeA;
        })
    };
  }, [messages]);

  const handleTouchStart = (e: React.TouchEvent) => {
    e.stopPropagation(); // Prevent global back swipe
    touchStartX.current = e.touches[0].clientX;
    touchStartY.current = e.touches[0].clientY;
  };

  const handleTouchEnd = (e: React.TouchEvent) => {
    e.stopPropagation(); // Prevent global back swipe
    if (touchStartX.current === null || touchStartY.current === null) return;
    const touchEndX = e.changedTouches[0].clientX;
    const touchEndY = e.changedTouches[0].clientY;
    
    const dx = touchEndX - touchStartX.current;
    const dy = Math.abs(touchEndY - touchStartY.current);
    
    // SWIPE RIGHT (Left to right) to Close
    if (dx > 100 && dy < 60) {
        onOpenChange(false);
    }
    
    touchStartX.current = null;
    touchStartY.current = null;
  };

  const showLiveLocationBadge =
    !!profileDocId &&
    !isSelfSavedChat &&
    profileDocId !== currentUser.id &&
    !!freshParticipant?.liveLocationShare &&
    isLiveShareVisible(freshParticipant.liveLocationShare);

  const isPartnerDeleted = !isGroup && !isSelfSavedChat && !!displayParticipantInfo?.deletedAt;
  const name =
    showMemberFocus && displayParticipantInfo
      ? displayParticipantInfo.name
      : isGroup && !showMemberFocus
        ? conversation.name
        : isSelfSavedChat
          ? conversation.name || 'Избранное'
          : displayParticipantInfo?.name || 'Чат';
  const avatar =
    showMemberFocus && displayParticipantInfo
      ? displayParticipantInfo.avatar
      : isGroup && !showMemberFocus
        ? conversation.photoUrl
        : isSelfSavedChat
          ? currentUser.avatar
          : displayParticipantInfo?.avatar;
  
  const isAdmin = useMemo(() => {
      if (!isGroup || !currentUser) return false;
      if (conversation.createdByUserId === currentUser.id) return true;
      return conversation.adminIds?.includes(currentUser.id) || false;
  }, [conversation, currentUser, isGroup]);

  const statusText = useMemo(() => {
    if (!displayParticipantInfo) return '';
    if (isGroup && !showMemberFocus) return '';
    if (displayParticipantInfo.deletedAt) return '';
    if (!showMemberFocus && isPartnerDeleted) return '';
    if (displayParticipantInfo.online) return 'В сети';
    if (displayParticipantInfo.lastSeen) {
      try {
        const { formatDistanceToNow } = require('date-fns');
        const lastSeenDate = typeof displayParticipantInfo.lastSeen === 'string' 
            ? parseISO(displayParticipantInfo.lastSeen) 
            : (displayParticipantInfo.lastSeen as any).toDate?.() || new Date(displayParticipantInfo.lastSeen);
        const distance = formatDistanceToNow(lastSeenDate, { addSuffix: true, locale: ru });
        return `Был(а) ${distance.charAt(0).toLowerCase() + distance.slice(1)}`;
      } catch (e) {
        return 'Был(а) в сети недавно';
      }
    }
    return 'Не в сети';
  }, [isGroup, showMemberFocus, displayParticipantInfo, isPartnerDeleted]);
  
  const currentDescription = showMemberFocus
    ? statusText
    : isGroup
      ? conversation.description || `${conversation.participantIds.length} участников`
      : isSelfSavedChat
        ? 'Сообщения и заметки только для вас'
        : statusText;

  const groupParticipants = useMemo(() => {
    if (!isGroup) return [];
    const uniqueParticipantIds = [...new Set(conversation.participantIds)];
    return uniqueParticipantIds.map(id => {
      if (id === currentUser.id) return currentUser;
      return allUsers.find(u => u.id === id);
    }).filter((u): u is User => !!u);
  }, [isGroup, conversation.participantIds, allUsers, currentUser]);

  const formatLastThreadTime = (dateStr?: string) => {
    if (!dateStr) return '';
    const date = parseISO(dateStr);
    if (isToday(date)) return format(date, 'HH:mm');
    if (isYesterday(date)) return 'Вчера';
    return format(date, 'dd.MM.yy');
  };

  if (!open) return null;
  
  return (
    <>
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent 
        className="w-full sm:max-w-lg p-0 flex flex-col sm:rounded-l-[2.5rem] border-none shadow-2xl touch-pan-y pt-[env(safe-area-inset-top,0px)]" 
        side="right" 
        showCloseButton={false}
        onTouchStart={handleTouchStart}
        onTouchEnd={handleTouchEnd}
      >
        <SheetHeader className="sr-only">
            <SheetTitle>{name}</SheetTitle>
            <SheetDescription>Профиль участника и медиафайлы беседы</SheetDescription>
        </SheetHeader>
        <ScrollArea className="flex-1 h-full">
          <div className="relative h-[370px] w-full flex-shrink-0">
            <div className="absolute inset-0 bg-muted" />
            <Dialog>
                <DialogTrigger asChild disabled={!avatar}>
                    <div className="absolute inset-0 cursor-pointer overflow-hidden group">
                        {avatar ? (
                            <img
                                src={avatar}
                                alt={name || 'Chat photo'}
                                className="absolute inset-0 w-full h-full object-cover !object-center group-hover:scale-105 transition-transform duration-700"
                            />
                        ) : (
                            <div className="h-full w-full bg-muted flex items-center justify-center">
                                <Users className="w-24 h-24 text-muted-foreground" />
                            </div>
                        )}
                    </div>
                </DialogTrigger>
                <DialogContent 
                    showCloseButton={false}
                    className="z-[110] flex max-h-[100dvh] w-screen flex-col items-center justify-center rounded-none border-none bg-black/90 p-0 shadow-none backdrop-blur-sm h-[100dvh] max-w-full">
                    <DialogHeader className="sr-only">
                        <DialogTitle>{name}</DialogTitle>
                        <DialogDescription>Полноэкранный просмотр аватара</DialogDescription>
                    </DialogHeader>
                    <header className="absolute top-0 left-0 right-0 z-50 box-border flex min-h-[5.5rem] items-start justify-between gap-3 bg-gradient-to-b from-black/70 to-transparent px-4 pb-2 pt-[calc(1rem+env(safe-area-inset-top,0px))] text-white">
                        <div className="font-semibold">{name}</div>
                        <DialogClose asChild>
                            <Button variant="ghost" size="icon" className="text-white hover:bg-white/20 hover:text-white" aria-label="Закрыть">
                                <X className="h-6 w-6" />
                            </Button>
                        </DialogClose>
                    </header>
                    <div className="relative mx-auto h-[calc(100dvh-env(safe-area-inset-top,0px)-env(safe-area-inset-bottom,0px)-6.5rem)] w-[95vw] max-w-full pl-[env(safe-area-inset-left,0px)] pr-[env(safe-area-inset-right,0px)]">
                        {avatar && <img src={avatar} alt={name || 'Avatar'} className="h-full w-full object-contain" />}
                    </div>
                </DialogContent>
            </Dialog>

            <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/30 to-black/10 pointer-events-none" />
            <div className="absolute bottom-0 left-0 p-6 sm:p-8 text-white pointer-events-none w-full">
                 <h2 className="text-2xl sm:text-3xl font-bold truncate leading-tight drop-shadow-lg">{name}</h2>
                 <p className="text-sm text-white/80 font-medium">{currentDescription}</p>
            </div>
            <div className="absolute left-4 top-4 z-10">
                {showMemberFocus && onClearProfileFocus ? (
                    <Button
                        type="button"
                        variant="ghost"
                        size="icon"
                        className="rounded-full bg-black/30 text-white backdrop-blur-md hover:bg-black/50 hover:text-white transition-all active:scale-95 border-none shadow-none"
                        onClick={() => onClearProfileFocus()}
                        aria-label="Назад к группе"
                    >
                        <ArrowLeft className="h-5 w-5" />
                    </Button>
                ) : (
                    <SheetClose asChild>
                        <Button variant="ghost" size="icon" className="rounded-full bg-black/30 text-white backdrop-blur-md hover:bg-black/50 hover:text-white transition-all active:scale-95 border-none shadow-none">
                            <ArrowLeft className="h-5 w-5" />
                        </Button>
                    </SheetClose>
                )}
            </div>
            {showLiveLocationBadge && profileDocId && (
              <>
                <div className="absolute right-4 top-4">
                  <Button
                    type="button"
                    variant="ghost"
                    size="icon"
                    className="rounded-full bg-emerald-600/90 text-white shadow-lg backdrop-blur-md hover:bg-emerald-500 hover:text-white border border-white/20 animate-pulse"
                    aria-label="Открыть карту с геолокацией"
                    onClick={() => setLiveMapOpen(true)}
                  >
                    <MapPin className="h-5 w-5" />
                  </Button>
                </div>
                <LiveLocationMapDialog
                  open={liveMapOpen}
                  onOpenChange={setLiveMapOpen}
                  userId={profileDocId}
                  displayName={displayParticipantInfo?.name ?? name ?? 'Пользователь'}
                />
              </>
            )}
          </div>

          <div className="p-4 space-y-6">
                {hasContactDetailsRows && displayParticipantInfo && (
                    <div
                      className={cn(
                        'flex items-stretch gap-2',
                        !canShowAddToContacts && 'w-full'
                      )}
                    >
                      <Collapsible
                        defaultOpen={false}
                        className={cn('space-y-2', canShowAddToContacts ? 'min-w-0 flex-1' : 'w-full')}
                      >
                        <CollapsibleTrigger asChild>
                          <Button
                            type="button"
                            variant="ghost"
                            className="group flex h-12 w-full items-center justify-between gap-2 rounded-2xl bg-muted/20 px-3 font-bold text-sm shadow-none hover:bg-muted/30 border-none sm:px-4"
                          >
                            <span className="min-w-0 truncate text-left">Контакты и данные</span>
                            <ChevronDown
                              className="h-4 w-4 shrink-0 text-muted-foreground transition-transform duration-200 group-data-[state=open]:rotate-180"
                              aria-hidden
                            />
                          </Button>
                        </CollapsibleTrigger>
                        <CollapsibleContent className="space-y-4 pt-1">
                            {freshParticipant && isProfileFieldVisibleToOthers(freshParticipant, 'email') && displayParticipantInfo.email && (
                                <div className="flex items-center gap-4 px-2">
                                    <div className="p-2.5 bg-blue-500/10 rounded-full flex-shrink-0">
                                        <Mail className="h-4 w-4 text-blue-500" />
                                    </div>
                                    <div className="flex flex-col min-w-0">
                                        <div className="text-[10px] uppercase font-bold text-muted-foreground tracking-[0.1em]">Электронная почта</div>
                                        <div className="font-bold text-sm leading-tight truncate">{displayParticipantInfo.email}</div>
                                    </div>
                                </div>
                            )}

                            {freshParticipant && isProfileFieldVisibleToOthers(freshParticipant, 'phone') && displayParticipantInfo.phone?.trim() && (
                                <div className="flex items-center gap-4 px-2">
                                    <div className="p-2.5 bg-emerald-500/10 rounded-full flex-shrink-0">
                                        <Smartphone className="h-4 w-4 text-emerald-500" />
                                    </div>
                                    <div className="flex flex-col min-w-0">
                                        <div className="text-[10px] uppercase font-bold text-muted-foreground tracking-[0.1em]">Телефон</div>
                                        <div className="font-bold text-sm leading-tight truncate">{formatPhoneNumberForDisplay(displayParticipantInfo.phone)}</div>
                                    </div>
                                </div>
                            )}

                            {freshParticipant && isProfileFieldVisibleToOthers(freshParticipant, 'dateOfBirth') && displayParticipantInfo.dateOfBirth && (
                                <div className="flex items-center gap-4 px-2">
                                    <div className="p-2.5 bg-purple-500/10 rounded-full flex-shrink-0">
                                        <Cake className="h-4 w-4 text-purple-500" />
                                    </div>
                                    <div className="flex flex-col min-w-0">
                                        <div className="text-[10px] uppercase font-bold text-muted-foreground tracking-[0.1em]">День рождения</div>
                                        <div className="font-bold text-sm leading-tight truncate">{displayParticipantInfo.dateOfBirth}</div>
                                    </div>
                                </div>
                            )}

                            {freshParticipant && isProfileFieldVisibleToOthers(freshParticipant, 'bio') && displayParticipantInfo.bio?.trim() && (
                                <div className="flex items-start gap-4 px-2">
                                    <div className="p-2.5 bg-muted rounded-full flex-shrink-0">
                                        <UserRound className="h-4 w-4 text-muted-foreground" />
                                    </div>
                                    <div className="flex flex-col min-w-0 gap-1">
                                        <div className="text-[10px] uppercase font-bold text-muted-foreground tracking-[0.1em]">О себе</div>
                                        <p className="text-sm leading-relaxed whitespace-pre-wrap break-words">{displayParticipantInfo.bio}</p>
                                    </div>
                                </div>
                            )}

                            {displayParticipantInfo.role && displayParticipantInfo.role !== 'worker' && (
                                <div className="flex items-center gap-4 px-2">
                                    <div className="p-2.5 bg-primary/10 rounded-full flex-shrink-0">
                                        <ShieldCheck className="h-4 w-4 text-primary" />
                                    </div>
                                    <div className="flex flex-col min-w-0">
                                        <div className="text-[10px] uppercase font-bold text-muted-foreground tracking-[0.1em]">Роль в системе</div>
                                        <div className="font-bold text-sm leading-tight truncate">{ROLES[displayParticipantInfo.role as UserRole] || displayParticipantInfo.role}</div>
                                    </div>
                                </div>
                            )}
                        </CollapsibleContent>
                      </Collapsible>

                      {canShowAddToContacts ? (
                        <Button
                          type="button"
                          variant="secondary"
                          className="inline-flex h-12 shrink-0 flex-row items-center justify-center gap-1.5 rounded-2xl px-2.5 font-bold shadow-none sm:px-3"
                          disabled={isContact || addContactBusy}
                          onClick={() => void handleAddToContacts()}
                          title={isContact ? 'В контактах' : 'Добавить в контакты'}
                          aria-label={isContact ? 'В контактах' : 'Добавить в контакты'}
                        >
                          {addContactBusy ? (
                            <Loader2 className="h-5 w-5 shrink-0 animate-spin" aria-hidden />
                          ) : (
                            <UserPlus className="h-5 w-5 shrink-0" aria-hidden />
                          )}
                          <span className="max-w-[5rem] truncate text-left text-[11px] leading-none sm:max-w-[6.5rem] sm:text-sm">
                            {isContact ? 'В контактах' : 'В контакты'}
                          </span>
                        </Button>
                      ) : null}
                    </div>
                )}

                {isGroup && !showMemberFocus && (
                    <div className="space-y-2">
                        <Button 
                            variant="ghost" 
                            className="w-full rounded-2xl justify-between h-14 px-5 bg-muted/20 hover:bg-muted/30 border-none transition-all active:scale-[0.98] shadow-none"
                            onClick={() => setIsParticipantsOpen(true)}
                        >
                            <span className="flex items-center gap-3 font-bold text-sm">
                                <Users className="h-5 w-5 text-primary" /> Участники
                            </span>
                            <Badge variant="secondary" className="rounded-full px-3 py-1 font-bold text-xs bg-primary text-white border-none shadow-sm">{groupParticipants.length}</Badge>
                        </Button>
                        {isAdmin && (
                            <Button 
                                variant="ghost" 
                                className="w-full rounded-2xl justify-start h-14 px-5 bg-muted/20 hover:bg-muted/30 border-none shadow-none transition-all active:scale-[0.98]" 
                                onClick={() => onEditGroup(conversation)}
                            >
                                <Edit className="mr-3 h-5 w-5 text-primary" /> 
                                <span className="font-bold text-sm">Редактировать группу</span>
                            </Button>
                        )}
                    </div>
                )}

                {canShowAddToContacts && !hasContactDetailsRows ? (
                  <div className="px-2 pb-1">
                    <Button
                      type="button"
                      variant="secondary"
                      className="h-12 w-full justify-center gap-2 rounded-2xl font-bold shadow-none"
                      disabled={isContact || addContactBusy}
                      onClick={() => void handleAddToContacts()}
                    >
                      {addContactBusy ? (
                        <Loader2 className="h-5 w-5 shrink-0 animate-spin" aria-hidden />
                      ) : (
                        <UserPlus className="h-5 w-5 shrink-0" aria-hidden />
                      )}
                      {isContact ? 'В контактах' : 'Добавить в контакты'}
                    </Button>
                  </div>
                ) : null}

                <div className="pt-2">
                    <h3 className="font-bold text-[10px] uppercase tracking-[0.3em] text-muted-foreground mb-2 px-1 opacity-60">Файлы и медиа</h3>
                    <div className="bg-transparent overflow-hidden">
                        <Tabs defaultValue={initialTab} className="flex-1 flex flex-col min-h-0">
                            <div className="px-0 py-1 flex-shrink-0">
                                <TabsList className="flex w-full items-center justify-between h-auto bg-muted/20 p-1 rounded-full gap-1 border-none shadow-none overflow-x-auto no-scrollbar scroll-smooth">
                                    <TabsTrigger value="threads" className="flex-1 rounded-full px-2 py-1.5 text-[10px] uppercase font-bold tracking-tighter data-[state=active]:bg-white/10 data-[state=active]:text-primary border border-transparent data-[state=active]:border-white/5 transition-all whitespace-nowrap shadow-none">Ветки</TabsTrigger>
                                    <TabsTrigger value="media" className="flex-1 rounded-full px-2 py-1.5 text-[10px] uppercase font-bold tracking-tighter data-[state=active]:bg-white/10 data-[state=active]:text-primary border border-transparent data-[state=active]:border-white/5 transition-all whitespace-nowrap shadow-none">Медиа</TabsTrigger>
                                    <TabsTrigger value="circles" className="flex-1 rounded-full px-2 py-1.5 text-[10px] uppercase font-bold tracking-tighter data-[state=active]:bg-white/10 data-[state=active]:text-primary border border-transparent data-[state=active]:border-white/5 transition-all whitespace-nowrap shadow-none">Кружки</TabsTrigger>
                                    <TabsTrigger value="files" className="flex-1 rounded-full px-2 py-1.5 text-[10px] uppercase font-bold tracking-tighter data-[state=active]:bg-white/10 data-[state=active]:text-primary border border-transparent data-[state=active]:border-white/5 transition-all whitespace-nowrap shadow-none">Файлы</TabsTrigger>
                                    <TabsTrigger value="links" className="flex-1 rounded-full px-2 py-1.5 text-[10px] uppercase font-bold tracking-tighter data-[state=active]:bg-white/10 data-[state=active]:text-primary border border-transparent data-[state=active]:border-white/5 transition-all whitespace-nowrap shadow-none">Ссылки</TabsTrigger>
                                    <TabsTrigger value="audios" className="flex-1 rounded-full px-2 py-1.5 text-[10px] uppercase font-bold tracking-tighter data-[state=active]:bg-white/10 data-[state=active]:text-primary border border-transparent data-[state=active]:border-white/5 transition-all whitespace-nowrap shadow-none">Аудио</TabsTrigger>
                                </TabsList>
                            </div>
                            
                            <TabsContent value="threads" className="p-0 mt-2 outline-none">
                                {threadMessages.length > 0 ? (
                                    <div className="space-y-2 pb-4 px-1">
                                        {threadMessages.map((msg) => {
                                            const unreadCount = msg.unreadThreadCounts?.[currentUser.id] || 0;
                                            const lastSender = allUsers.find(u => u.id === msg.lastThreadMessageSenderId);
                                            const lastSenderName = lastSender ? (lastSender.id === currentUser.id ? 'Вы' : lastSender.name.split(' ')[0]) : 'Участник';
                                            
                                            return (
                                                <div 
                                                    key={msg.id} 
                                                    role="button" 
                                                    tabIndex={0} 
                                                    onClick={() => { onOpenThread(msg); onOpenChange(false); }} 
                                                    className="w-full flex items-start gap-3 p-4 bg-muted/20 hover:bg-muted/40 rounded-3xl transition-all group text-left cursor-pointer border border-transparent hover:border-border/50 shadow-sm active:scale-[0.98] min-w-0"
                                                >
                                                    <div className="p-3 bg-primary/10 rounded-2xl group-hover:bg-primary/20 transition-colors shrink-0">
                                                        <MessageSquare className="h-5 w-5 text-primary" />
                                                    </div>
                                                    <div className="flex-1 min-w-0">
                                                        <div 
                                                            className="text-sm font-bold leading-tight mb-1 break-words break-all [&_p]:inline [&_p]:m-0" 
                                                            dangerouslySetInnerHTML={{ __html: msg.text ? sanitizeMessageHtml(msg.text) : 'Вложение' }} 
                                                        />
                                                        
                                                        {msg.lastThreadMessageText && (
                                                            <p className="text-xs text-muted-foreground mb-2 opacity-80 break-words break-all line-clamp-2">
                                                                <span className="font-semibold text-foreground/70">{lastSenderName}:</span> {msg.lastThreadMessageText}
                                                            </p>
                                                        )}

                                                        <div className="flex items-center justify-between gap-2">
                                                            <div className="flex items-center gap-2">
                                                                <Badge variant="secondary" className="h-5 px-2 text-[10px] font-bold uppercase tracking-tight bg-primary text-white border-none shadow-none rounded-full">
                                                                    {(msg.threadCount ?? 0)} {(msg.threadCount ?? 0) === 1 ? 'ответ' : [2,3,4].includes((msg.threadCount ?? 0) % 10) ? 'ответа' : 'ответов'}
                                                                </Badge>
                                                                {unreadCount > 0 && (
                                                                    <Badge className="h-5 px-2 text-[10px] font-bold bg-red-500 text-white border-none shadow-none rounded-full animate-in zoom-in-50">
                                                                        +{unreadCount}
                                                                    </Badge>
                                                                )}
                                                            </div>
                                                            <div className="flex items-center gap-1.5 text-[10px] font-bold text-muted-foreground uppercase opacity-60">
                                                                <Clock className="h-3 w-3" />
                                                                {formatLastThreadTime(msg.lastThreadMessageTimestamp || msg.createdAt)}
                                                            </div>
                                                        </div>
                                                    </div>
                                                </div>
                                            )
                                        })}
                                    </div>
                                ) : (
                                    <div className="flex flex-col items-center justify-center py-12 text-muted-foreground opacity-40">
                                        <MessageSquare className="h-10 w-10 mb-2" />
                                        <p className="text-xs font-medium">Обсуждения не найдены</p>
                                    </div>
                                )}
                            </TabsContent>
                            <TabsContent value="media" className="p-0 mt-2 outline-none">
                                {media.length > 0 ? (
                                <div className="grid grid-cols-3 gap-1 pb-4">
                                    {media.map((item, index) => (
                                        item.type.startsWith('image/') ? (
                                            <div 
                                                key={index} 
                                                className="relative aspect-square bg-muted overflow-hidden cursor-pointer group rounded-xl"
                                                onClick={() => onImageClick(item)}
                                            >
                                                <img src={item.url} alt={item.name} className="absolute inset-0 w-full h-full object-cover group-hover:scale-110 transition-transform duration-500" />
                                            </div>
                                        ) : (
                                            <VideoThumbnailWithDuration key={index} video={item} onClick={() => onImageClick(item)} />
                                        )
                                    ))}
                                </div>
                                ) : (
                                <div className="flex flex-col items-center justify-center py-12 text-muted-foreground opacity-40">
                                    <ImageIcon className="h-10 w-10 mb-2" />
                                    <p className="text-xs font-medium">Нет медиафайлов</p>
                                </div>
                                )}
                            </TabsContent>
                            <TabsContent value="circles" className="p-0 mt-2 outline-none">
                                {circles.length > 0 ? (
                                    <div className="grid grid-cols-3 gap-4 pb-10">
                                        {circles.map((circle, index) => {
                                            const isActive = activeCircleUrl === circle.url;
                                            return (
                                                <div 
                                                    key={index} 
                                                    className={cn(
                                                        "transition-all duration-500 flex justify-center items-center aspect-square",
                                                        isActive ? "col-span-3 py-4" : "col-span-1"
                                                    )}
                                                >
                                                    <VideoCirclePlayer 
                                                        attachment={circle} 
                                                        isCurrentUser={circle.senderId === currentUser.id} 
                                                        createdAt={circle.createdAt || new Date().toISOString()} 
                                                        readAt={null} 
                                                        hideTimestamp={true}
                                                        onClick={() => {
                                                            if (isActive) setActiveCircleUrl(null);
                                                            else setActiveCircleUrl(circle.url);
                                                        }}
                                                    />
                                                </div>
                                            );
                                        })}
                                    </div>
                                ) : (
                                    <div className="flex flex-col items-center justify-center py-12 text-muted-foreground opacity-40">
                                        <Video className="h-10 w-10 mb-2" />
                                        <p className="text-xs font-medium">Кружки отсутствуют</p>
                                    </div>
                                )}
                            </TabsContent>
                            <TabsContent value="files" className="p-0 mt-2 outline-none">
                                {files.length > 0 ? (
                                    <div className="space-y-2 pb-4">
                                        {files.map((file, index) => (
                                            <div key={index} className="flex items-center gap-3 p-3 bg-muted/20 border border-border/10 rounded-2xl group hover:bg-muted/30 transition-colors">
                                                <div className="p-2 bg-primary/10 rounded-xl group-hover:bg-primary/20 transition-colors">
                                                    <FileIcon className="h-5 w-5 text-primary flex-shrink-0" />
                                                </div>
                                                <div className="flex-1 min-w-0">
                                                    <p className="text-sm font-bold truncate leading-tight">{file.name}</p>
                                                    <p className="text-[10px] font-bold text-muted-foreground uppercase mt-0.5">{(file.size / 1024).toFixed(1)} KB</p>
                                                </div>
                                                <Button variant="ghost" size="icon" className="rounded-full h-9 w-9 border-none shadow-none" asChild>
                                                    <a href={file.url} download={file.name} target="_blank" rel="noopener noreferrer">
                                                        <Download className="h-4 w-4" />
                                                    </a>
                                                </Button>
                                            </div>
                                        ))}
                                    </div>
                                ) : (
                                    <div className="flex flex-col items-center justify-center py-12 text-muted-foreground opacity-40">
                                        <FileIcon className="h-10 w-10 mb-2" />
                                        <p className="text-xs font-medium">Нет файлов</p>
                                    </div>
                                )}
                            </TabsContent>
                            <TabsContent value="links" className="p-0 mt-2 outline-none">
                                {links.length > 0 ? (
                                    <div className="space-y-2 pb-4">
                                        {links.map((link) => (
                                            <div key={link.url} className="p-3 bg-muted/20 rounded-2xl hover:bg-muted/30 transition-colors group">
                                                <div className="flex items-center gap-3">
                                                    <div className="p-2 bg-blue-500/10 rounded-xl group-hover:bg-blue-500/20 transition-colors">
                                                        <LinkIcon className="h-4 w-4 text-blue-500" />
                                                    </div>
                                                    <Link href={link.url} target="_blank" rel="noopener noreferrer" className="text-sm font-medium text-primary hover:underline break-all line-clamp-2 leading-snug">
                                                        {link.url}
                                                    </Link>
                                                </div>
                                            </div>
                                        ))}
                                    </div>
                                ) : (
                                    <div className="flex flex-col items-center justify-center py-12 text-muted-foreground opacity-40">
                                        <LinkIcon className="h-10 w-10 mb-2" />
                                        <p className="text-xs font-medium">Нет ссылок</p>
                                    </div>
                                )}
                            </TabsContent>
                            <TabsContent value="audios" className="p-0 mt-2 outline-none">
                                {audios.length > 0 ? (
                                    <div className="space-y-2 pb-4">
                                        {audios.map((audio, index) => (
                                            <div key={index} className="p-3 bg-muted/20 rounded-2xl">
                                                <div className="flex items-center gap-3">
                                                    <div className="p-2 bg-indigo-500/10 rounded-xl">
                                                        <Mic className="h-4 w-4 text-indigo-500" />
                                                    </div>
                                                    <div className="flex-1 min-w-0">
                                                        <audio src={audio.url} controls className="w-full h-8" />
                                                    </div>
                                                </div>
                                            </div>
                                        ))}
                                    </div>
                                ) : (
                                    <div className="flex flex-col items-center justify-center py-12 text-muted-foreground opacity-40">
                                        <Mic className="h-10 w-10 mb-2" />
                                        <p className="text-xs font-medium">Нет аудиосообщений</p>
                                    </div>
                                )}
                            </TabsContent>
                        </Tabs>
                    </div>
                </div>

                {isGroup && !showMemberFocus && (
                    <div className="space-y-2 pt-4 pb-10">
                        <Button variant="ghost" className="w-full rounded-2xl h-12 font-bold text-sm transition-all active:scale-[0.98] bg-muted/20 hover:bg-muted/30 border-none shadow-none" onClick={() => router.push(`/dashboard/chat/${conversation.id}/leave`)}>
                            <LogOut className="mr-2 h-4 w-4" />Покинуть группу
                        </Button>
                    </div>
                )}
          </div>
        </ScrollArea>
      </SheetContent>
    </Sheet>

    <Dialog open={isParticipantsListOpen} onOpenChange={setIsParticipantsOpen}>
        <DialogContent className="max-w-md rounded-[2.5rem] p-0 flex flex-col h-[80vh] overflow-hidden border-none shadow-2xl">
            <DialogHeader className="p-6 border-b flex-shrink-0 bg-muted/30">
                <DialogTitle className="flex items-center gap-2 font-bold text-lg">
                    <Users className="text-primary h-5 w-5" /> Участники ({groupParticipants.length})
                </DialogTitle>
                <DialogDescription>Все пользователи, состоящие в этой группе.</DialogDescription>
            </DialogHeader>
            <ScrollArea className="flex-1">
                <div className="p-4 space-y-1">
                    {groupParticipants.map(p => (
                        <div key={p.id} className="flex items-center justify-between p-3 hover:bg-muted rounded-2xl cursor-pointer transition-colors group"
                            onClick={() => {
                                if (p.id !== currentUser.id) {
                                    const personalConvId = [currentUser.id, p.id].sort().join('_');
                                    onSelectConversation(personalConvId);
                                    setIsParticipantsOpen(false);
                                    onOpenChange(false);
                                }
                            }}
                        >
                            <div className="flex items-center gap-3 min-w-0">
                                <Avatar className="h-11 w-11 relative border border-border/50 shadow-sm">
                                    <AvatarImage src={userAvatarListUrl(p)} className="object-cover" />
                                    <AvatarFallback>{p.name.charAt(0)}</AvatarFallback>
                                    {p.online && !p.deletedAt && <div className="absolute bottom-0.5 right-0.5 w-2.5 h-2.5 bg-green-500 border-2 border-background rounded-full" />}
                                </Avatar>
                                <div className="flex flex-col min-w-0">
                                    <div className="font-bold text-sm truncate leading-tight group-hover:text-primary transition-colors">{p.name}</div>
                                    {p.role && p.role !== 'worker' && !p.deletedAt && <div className="text-[10px] text-muted-foreground uppercase tracking-wider font-medium">{ROLES[p.role]}</div>}
                                </div>
                            </div>
                            <div className='flex items-center gap-2'>
                                {p.id === conversation.createdByUserId ? (
                                    <Badge variant="secondary" className="rounded-full px-2 py-0.5 text-[9px] uppercase font-bold bg-amber-500/10 text-amber-600 border-amber-500/20">Создатель</Badge>
                                ) : conversation.adminIds?.includes(p.id) ? (
                                    <Badge variant="outline" className="rounded-full px-2 py-0.5 text-[9px] uppercase font-bold">Админ</Badge>
                                ) : null}
                            </div>
                        </div>
                    ))}
                </div>
            </ScrollArea>
            <div className="p-4 border-t bg-muted/10 flex justify-center">
                <Button variant="ghost" onClick={() => setIsParticipantsOpen(false)} className="rounded-full font-bold h-11 px-8 hover:bg-muted border-none shadow-none">Закрыть</Button>
            </div>
        </DialogContent>
    </Dialog>
    </>
  );
}
