
'use client';

import React, { useRef, useEffect, useState, useMemo } from 'react';
import { Virtuoso, type VirtuosoHandle } from 'react-virtuoso';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Button } from '@/components/ui/button';
import { 
  X, UserX, MicOff, VideoOff, 
  ShieldCheck, ShieldOff, Loader2, Trash2
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { useFirestore, useStorage } from '@/firebase';
import { collection, doc, setDoc, updateDoc, deleteDoc, serverTimestamp, query, orderBy, onSnapshot } from 'firebase/firestore';
import { ref as storageRef, uploadBytesResumable, getDownloadURL } from 'firebase/storage';
import { compressImage } from '@/lib/image-compression';
import { useToast } from '@/hooks/use-toast';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog';
import type { ChatAttachment, MeetingMessage, User } from '@/lib/types';
import { format, parseISO, isToday, isYesterday } from 'date-fns';
import { ru } from 'date-fns/locale';
import { Badge } from '../ui/badge';
import { MeetingChatMessageItem } from './MeetingChatMessageItem';
import { MeetingChatMessageInput } from './MeetingChatMessageInput';
import { userAvatarListUrl } from '@/lib/user-avatar-display';

interface ParticipantState {
  id: string;
  name: string;
  avatar: string;
  avatarThumb?: string;
  role?: string;
  isAudioMuted?: boolean;
  isVideoMuted?: boolean;
  isHandRaised?: boolean;
  isScreenSharing?: boolean;
}

interface MeetingSidebarProps {
  activeTab: 'participants' | 'polls' | 'chat' | null;
  onActiveTabChange: (tab: 'participants' | 'polls' | 'chat' | null) => void;
  onClose: () => void;
  currentUser: { id: string; name: string; avatar: string; avatarThumb?: string; role?: string };
  chatMessages: MeetingMessage[];
  newMessageText: string;
  setNewMessageText: (text: string) => void;
  onSendMessage: (e?: React.FormEvent) => void;
  participants: ParticipantState[];
  isHost: boolean;
  hostId: string;
  adminIds: string[];
  onForceMuteAudio: (id: string) => void;
  onForceMuteVideo: (id: string) => void;
  onKick: (id: string) => void;
  onToggleAdmin: (id: string) => void;
  requestsNode?: React.ReactNode;
  pollsNode?: React.ReactNode;
  chatEndRef?: React.RefObject<HTMLDivElement>;
  meetingId?: string;
}

type FlatItem = { type: 'date'; date: string } | { type: 'message'; message: MeetingMessage };

export function MeetingSidebar({
  activeTab,
  onActiveTabChange,
  onClose,
  currentUser,
  chatMessages,
  newMessageText,
  setNewMessageText,
  participants,
  isHost,
  hostId,
  adminIds,
  onForceMuteAudio,
  onForceMuteVideo,
  onKick,
  onToggleAdmin,
  requestsNode,
  pollsNode,
  meetingId,
}: MeetingSidebarProps) {
  const isOpen = activeTab !== null;
  const virtuosoRef = useRef<VirtuosoHandle>(null);
  const [isUploading, setIsUploading] = useState(false);
  const [editingMessage, setEditingMessage] = useState<MeetingMessage | null>(null);
  const [previewImage, setPreviewImage] = useState<ChatAttachment | null>(null);
  const [topVisibleDate, setTopVisibleDate] = useState<string | null>(null);
  
  const firestore = useFirestore();
  const storage = useStorage();
  const { toast } = useToast();

  const flatItems = useMemo(() => {
    const items: FlatItem[] = [];
    let lastDate = "";
    
    chatMessages.forEach(msg => {
      const date = format(
        typeof msg.createdAt === 'string' ? parseISO(msg.createdAt) : msg.createdAt?.toDate?.() || new Date(), 
        'yyyy-MM-dd'
      );
      if (date !== lastDate) {
        items.push({ type: 'date', date });
        lastDate = date;
      }
      items.push({ type: 'message', message: msg });
    });
    
    return items;
  }, [chatMessages]);

  const handleCancelEdit = () => {
    setEditingMessage(null);
    setNewMessageText('');
  };

  useEffect(() => {
    if (activeTab === 'chat' && flatItems.length > 0) {
      const scrollToEnd = () => {
        virtuosoRef.current?.scrollToIndex({
          index: flatItems.length - 1,
          align: 'end',
          behavior: 'auto'
        });
      };
      
      const timer = setTimeout(scrollToEnd, 150);
      return () => clearTimeout(timer);
    }
  }, [activeTab, flatItems.length]);

  const uploadFile = (file: File, path: string): Promise<ChatAttachment> => {
    return new Promise((resolve, reject) => {
      const fileRef = storageRef(storage, path);
      const uploadTask = uploadBytesResumable(fileRef, file);
      uploadTask.on('state_changed', null, (error) => reject(error), async () => {
        const downloadURL = await getDownloadURL(uploadTask.snapshot.ref);
        resolve({ url: downloadURL, name: file.name, type: file.type, size: file.size });
      });
    });
  };

  const handleSend = async (text: string, files: File[]) => {
    if (!meetingId || !firestore) return;
    
    setIsUploading(true);
    try {
        if (editingMessage) {
            const msgRef = doc(firestore, `meetings/${meetingId}/messages`, editingMessage.id);
            await updateDoc(msgRef, {
                text: text,
                updatedAt: new Date().toISOString()
            });
            setEditingMessage(null);
            setNewMessageText('');
        } else {
            const uploadedAttachments: ChatAttachment[] = [];
            for (const file of files) {
                let fileToUpload = file;
                if (file.type.startsWith('image/')) {
                    try {
                        const compressed = await compressImage(file, 0.8, 1280);
                        const res = await fetch(compressed);
                        const blob = await res.blob();
                        fileToUpload = new File([blob], file.name, { type: file.type });
                    } catch (err) {}
                }
                const path = `meeting-attachments/${meetingId}/${Date.now()}_${file.name.replace(/\s+/g, '_')}`;
                const uploaded = await uploadFile(fileToUpload, path);
                uploadedAttachments.push(uploaded);
            }

            const messagesCollection = collection(firestore, `meetings/${meetingId}/messages`);
            
            const messageData: any = {
                senderId: currentUser.id,
                senderName: currentUser.name,
                attachments: uploadedAttachments,
                createdAt: serverTimestamp(),
            };
            
            if (text && text.trim()) {
                messageData.text = text.trim();
            }

            await setDoc(doc(messagesCollection), messageData);

            setNewMessageText('');
        }
    } catch (err: any) {
        toast({ variant: 'destructive', title: 'Ошибка отправки', description: err.message });
    } finally {
        setIsUploading(false);
    }
  };

  const handleOpenViewer = (att: ChatAttachment) => {
    setPreviewImage(att);
  };

  const formatDateLabel = (dateStr: string) => {
    const date = parseISO(dateStr);
    if (isToday(date)) return 'Сегодня';
    if (isYesterday(date)) return 'Вчера';
    return format(date, 'd MMMM', { locale: ru });
  };

  return (
    <>
    <div className={cn("fixed top-6 bottom-8 right-6 z-50 transition-transform duration-500 ease-out flex flex-col", isOpen ? "w-[380px] translate-x-0" : "w-[380px] translate-x-[calc(100%+24px)] pointer-events-none")}>
        <div className="h-full bg-slate-900/40 backdrop-blur-3xl border border-white/10 rounded-3xl flex flex-col overflow-hidden shadow-2xl">
            <Tabs value={activeTab || 'chat'} onValueChange={(v: any) => onActiveTabChange(v)} className="flex-1 flex flex-col min-h-0">
                <div className="px-6 pt-4 pb-2 shrink-0">
                    <div className="flex items-center justify-between mb-3">
                        <h2 className="text-[10px] font-black uppercase tracking-[0.3em] text-white/40">Конференция</h2>
                        <Button variant="ghost" size="icon" className="h-8 w-8 rounded-full bg-white/5 hover:bg-white/15 text-white/50 hover:text-white border-none shadow-none" onClick={onClose}><X className="h-4 w-4" /></Button>
                    </div>
                    <TabsList className="grid w-full grid-cols-3 bg-white/5 p-1 rounded-2xl h-11 border border-white/5">
                        <TabsTrigger value="participants" className="rounded-xl text-[9px] font-black uppercase tracking-wider data-[state=active]:bg-white/10 data-[state=active]:text-primary transition-all shadow-none">Участники</TabsTrigger>
                        <TabsTrigger value="polls" className="rounded-xl text-[9px] font-black uppercase tracking-wider data-[state=active]:bg-white/10 data-[state=active]:text-primary transition-all shadow-none">Опросы</TabsTrigger>
                        <TabsTrigger value="chat" className="rounded-xl text-[9px] font-black uppercase tracking-wider data-[state=active]:bg-white/10 data-[state=active]:text-primary transition-all shadow-none">Чат</TabsTrigger>
                    </TabsList>
                </div>
                <div className="flex-1 min-h-0 overflow-hidden">
                    <TabsContent value="participants" className="h-full m-0 outline-none">
                        <ScrollArea className="h-full">
                            <div className="px-6 pb-10 space-y-6">
                                {requestsNode}
                                <div className="space-y-1">
                                    <h4 className="text-[9px] font-black uppercase tracking-[0.2em] text-white/20 px-2 mb-3">В комнате</h4>
                                    <ParticipantRow name={`${currentUser.name} (Вы)`} avatar={currentUser.avatar} avatarThumb={currentUser.avatarThumb} role={getRoleLabel(currentUser.id, hostId, adminIds)} isMe />
                                    {participants.map(p => {
                                        const isAlreadyAdmin = adminIds.includes(p.id);
                                        const isParticipantHost = p.id === hostId;
                                        return (
                                            <ParticipantRow 
                                                key={p.id} name={p.name} avatar={p.avatar} avatarThumb={p.avatarThumb} role={getRoleLabel(p.id, hostId, adminIds)} isAudioMuted={p.isAudioMuted} isVideoMuted={p.isVideoMuted} isHost={isHost}
                                                controls={isHost && p.id !== currentUser.id && !isParticipantHost && (
                                                    <div className="flex items-center gap-1">
                                                        <Button variant="ghost" size="icon" onClick={() => onToggleAdmin(p.id)} className={cn("h-8 w-8 rounded-full hover:bg-primary/20", isAlreadyAdmin ? "text-primary" : "text-white/30")} title={isAlreadyAdmin ? "Убрать админа" : "Сделать админом"}>{isAlreadyAdmin ? <ShieldOff className="h-3.5 w-3.5" /> : <ShieldCheck className="h-3.5 w-3.5" />}</Button>
                                                        <Button variant="ghost" size="icon" onClick={() => onForceMuteAudio(p.id)} className={cn("h-8 w-8 rounded-full hover:bg-red-500/20", p.isAudioMuted ? "text-red-500" : "text-white/30")} title="Заглушить"><MicOff className="h-3.5 w-3.5" /></Button>
                                                        <Button variant="ghost" size="icon" onClick={() => onForceMuteVideo(p.id)} className={cn("h-8 w-8 rounded-full hover:bg-red-500/20", p.isVideoMuted ? "text-red-500" : "text-white/30")} title="Выключить камеру"><VideoOff className="h-3.5 w-3.5" /></Button>
                                                        <Button variant="ghost" size="icon" onClick={() => onKick(p.id)} className="h-8 w-8 rounded-full hover:bg-red-500/20 text-white/30 hover:text-red-500" title="Исключить"><UserX className="h-3.5 w-3.5" /></Button>
                                                    </div>
                                                )}
                                            />
                                        )
                                    })}
                                </div>
                            </div>
                        </ScrollArea>
                    </TabsContent>
                    <TabsContent value="polls" className="h-full m-0 outline-none">{pollsNode}</TabsContent>
                    <TabsContent value="chat" className="h-full m-0 flex flex-col outline-none">
                        <div className="flex-1 min-h-0 relative">
                            {/* Floating Date Tag */}
                            {topVisibleDate && (
                                <div className="absolute top-2 left-0 right-0 z-40 flex justify-center pointer-events-none animate-in fade-in duration-300">
                                    <Badge variant="outline" className="bg-background/80 backdrop-blur-md px-4 py-1 rounded-full text-[10px] font-bold uppercase tracking-widest text-muted-foreground border-white/5 shadow-sm pointer-events-auto">
                                        {formatDateLabel(topVisibleDate)}
                                    </Badge>
                                </div>
                            )}

                            <Virtuoso 
                                ref={virtuosoRef}
                                data={flatItems} 
                                followOutput="auto" 
                                alignToBottom 
                                className="custom-scrollbar" 
                                rangeChanged={(range) => {
                                    const firstItem = flatItems[range.startIndex];
                                    if (firstItem) {
                                        setTopVisibleDate(firstItem.type === 'date' ? firstItem.date : format(
                                            typeof firstItem.message.createdAt === 'string' 
                                                ? parseISO(firstItem.message.createdAt) 
                                                : firstItem.message.createdAt?.toDate?.() || new Date(), 
                                            'yyyy-MM-dd'
                                        ));
                                    }
                                }}
                                itemContent={(index, item) => {
                                    if (item.type === 'date') {
                                        return <div className="h-10 w-full shrink-0" />;
                                    }
                                    const msg = item.message;
                                    return (
                                        <MeetingChatMessageItem 
                                            key={msg.id} 
                                            message={msg} 
                                            currentUser={currentUser as any} 
                                            onEdit={(m) => { setEditingMessage(m); setNewMessageText(m.text || ''); }}
                                            onDelete={() => {
                                                if (meetingId) {
                                                    const ref = doc(firestore!, `meetings/${meetingId}/messages`, msg.id);
                                                    updateDoc(ref, { isDeleted: true });
                                                }
                                            }}
                                            onOpenImage={handleOpenViewer}
                                        />
                                    );
                                }}
                            />
                        </div>
                        <MeetingChatMessageInput 
                            value={newMessageText}
                            onChange={setNewMessageText}
                            onSend={handleSend}
                            isUploading={isUploading}
                            editingMessage={editingMessage}
                            onCancelEdit={handleCancelEdit}
                        />
                    </TabsContent>
                </div>
            </Tabs>
        </div>
    </div>

    {/* Light Image Preview Dialog */}
    <Dialog open={!!previewImage} onOpenChange={(open) => !open && setPreviewImage(null)}>
        <DialogContent className="max-w-[90vw] sm:max-w-lg p-0 bg-transparent border-none shadow-none z-[200] overflow-visible" showCloseButton={false}>
            <DialogHeader className="sr-only">
                <DialogTitle>Просмотр изображения</DialogTitle>
                <DialogDescription>Полноэкранный просмотр изображения из чата.</DialogDescription>
            </DialogHeader>
            <div className="relative aspect-auto max-h-[85vh] w-full flex items-center justify-center">
                {previewImage && (
                    <img 
                        src={previewImage.url} 
                        alt={previewImage.name} 
                        className="max-w-full max-h-full object-contain rounded-2xl shadow-2xl" 
                    />
                )}
                <Button 
                    variant="ghost" 
                    size="icon" 
                    className="absolute top-2 right-2 rounded-full bg-black/50 text-white hover:bg-white/20 border-none h-10 w-10 shadow-xl"
                    onClick={() => setPreviewImage(null)}
                >
                    <X className="h-6 w-6" />
                </Button>
            </div>
        </DialogContent>
    </Dialog>
    </>
  );
}

function ParticipantRow({ name, avatar, avatarThumb, role, isMe, controls, isAudioMuted, isVideoMuted }: { name: string; avatar: string; avatarThumb?: string; role?: string | null; isMe?: boolean; controls?: React.ReactNode; isAudioMuted?: boolean; isVideoMuted?: boolean; isHost?: boolean }) {
    const avatarSrc = userAvatarListUrl({ avatar, avatarThumb });
    return (
        <div className="flex items-center justify-between p-3 bg-white/5 rounded-2xl border border-white/5 transition-all hover:bg-white/10 group mb-2">
            <div className="flex items-center gap-3 min-w-0">
                <Avatar className="h-10 w-10 shrink-0 border-2 border-white/5 shadow-md">
                    <AvatarImage src={avatarSrc} className="object-cover" />
                    <AvatarFallback className="font-black text-xs">{name[0]}</AvatarFallback>
                </Avatar>
                <div className="min-w-0">
                    <div className="flex items-center gap-2">
                        <p className="text-sm font-bold text-white/90 leading-tight truncate">{name}</p>
                        {isAudioMuted && <MicOff className="h-3 w-3 text-red-500" />}
                        {isVideoMuted && <VideoOff className="h-3 w-3 text-red-500" />}
                    </div>
                    {role && <p className="text-[8px] font-black text-primary uppercase tracking-[0.15em] mt-0.5 break-words">{role}</p>}
                </div>
            </div>
            <div className="flex items-center gap-1 shrink-0">{controls}</div>
        </div>
    );
}

function getRoleLabel(uid: string, hostId: string, adminIds: string[]) {
    if (uid === hostId) return 'Организатор';
    if (adminIds?.includes(uid)) return 'Администратор';
    return null;
}
