'use client';

import React, { useState, useMemo, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import {
  useFirestore,
  useMemoFirebase,
  useDoc,
  useConversationsByDocumentIds,
  useUsersByDocumentIds,
} from '@/firebase';
import { collection, doc, increment, writeBatch } from 'firebase/firestore';
import type { User, Conversation, ChatMessage, UserChatIndex } from '@/lib/types';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Loader2, SendHorizonal, ArrowLeft, Search, MessageSquare, Quote, Check } from 'lucide-react';
import { ScrollArea } from '@/components/ui/scroll-area';
import { useToast } from '@/hooks/use-toast';
import { useAuth } from '@/hooks/use-auth';
import { cn } from '@/lib/utils';
import { participantListAvatarUrl } from '@/lib/user-avatar-display';
import { Card, CardContent } from '@/components/ui/card';

function ForwardingMessagePreview({ messages, allUsers }: { messages: Partial<ChatMessage>[], allUsers: User[] }) {
    const stripHtml = (html?: string) => {
        if (!html) return '';
        return html.replace(/<[^>]*>/g, '').replace(/&nbsp;/g, ' ').trim();
    };

    return (
        <Card className="border-none shadow-sm bg-white overflow-hidden rounded-2xl border">
            <CardContent className="p-0">
                <div className="border-l-4 border-primary bg-primary/5 p-4">
                    {messages.map((message, idx) => {
                        const sender = allUsers.find(u => u.id === message.senderId);
                        return (
                            <div key={idx} className={cn("text-sm", idx > 0 && "mt-3 pt-3 border-t border-primary/10")}>
                                <div className="flex items-center gap-2 mb-1">
                                    <Quote className="h-3 w-3 text-primary/40 rotate-180" />
                                    <p className="font-bold text-foreground">
                                        {sender?.name || 'Неизвестный'}
                                    </p>
                                </div>
                                <p className="text-muted-foreground break-words pl-5 italic">
                                    {message.text ? stripHtml(message.text) : 'Вложение'}
                                </p>
                            </div>
                        );
                    })}
                </div>
            </CardContent>
        </Card>
    );
}

export default function ForwardPage() {
    const [messages, setMessages] = useState<Partial<ChatMessage>[]>([]);
    const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
    const [isSending, setIsSending] = useState(false);
    const [searchTerm, setSearchTerm] = useState('');
    
    const { user: currentUser } = useAuth();
    const firestore = useFirestore();
    const router = useRouter();
    const { toast } = useToast();

    const userChatIndexRef = useMemoFirebase(
        () => (firestore && currentUser ? doc(firestore, 'userChats', currentUser.id) : null),
        [firestore, currentUser?.id]
    );
    const { data: userChatIndex } = useDoc<UserChatIndex>(userChatIndexRef);
    const forwardConversationIds = useMemo(
        () => userChatIndex?.conversationIds || [],
        [userChatIndex?.conversationIds]
    );
    const { data: rawConversations, isLoading: isLoadingConversations } = useConversationsByDocumentIds(
        firestore,
        forwardConversationIds
    );

    const userIdsForForwardPage = useMemo(() => {
        const ids = new Set<string>();
        if (currentUser?.id) ids.add(currentUser.id);
        rawConversations?.forEach((conv) => {
            conv.participantIds.forEach((id) => {
                if (id) ids.add(id);
            });
        });
        messages.forEach((m) => {
            if (m.senderId) ids.add(m.senderId);
        });
        return [...ids];
    }, [currentUser?.id, rawConversations, messages]);

    const { usersById, isLoading: isLoadingUsers } = useUsersByDocumentIds(firestore, userIdsForForwardPage);
    const allUsers = useMemo(() => [...usersById.values()], [usersById]);

    useEffect(() => {
        try {
            const data = sessionStorage.getItem('forwardMessages');
            if (data) {
                const parsedMessages: Partial<ChatMessage>[] = JSON.parse(data);
                setMessages(parsedMessages);
            } else {
                toast({ variant: 'destructive', title: 'Нет сообщений для пересылки' });
                router.back();
            }
        } catch (error) {
            console.error("Failed to parse messages from session storage", error);
            toast({ variant: 'destructive', title: 'Ошибка загрузки сообщений' });
            router.back();
        }
    }, [router, toast]);
    
    const handleGoBack = useCallback(() => {
        sessionStorage.removeItem('forwardMessages');
        router.back();
    }, [router]);

    const conversations = useMemo(() => {
        if (!rawConversations || !currentUser || !allUsers) return [];
        
        const uniqueMap = new Map<string, Conversation>();
        
        rawConversations.forEach(conv => {
            if (!conv.participantIds.includes(currentUser.id)) return;

            if (conv.isGroup) {
                uniqueMap.set(conv.id, conv);
            } else {
                const otherId = conv.participantIds.find(id => id !== currentUser.id);
                if (otherId) {
                    const otherUser = allUsers.find(u => u.id === otherId);
                    if (otherUser && !otherUser.deletedAt) {
                        const existing = uniqueMap.get(otherId);
                        if (!existing || (conv.lastMessageTimestamp && existing.lastMessageTimestamp && conv.lastMessageTimestamp > existing.lastMessageTimestamp)) {
                            uniqueMap.set(otherId, conv);
                        }
                    }
                }
            }
        });
        
        return Array.from(uniqueMap.values());
    }, [rawConversations, currentUser, allUsers]);

    const filteredConversations = useMemo(() => {
        return conversations.filter(conv => {
            const otherParticipantId = conv.participantIds.find(id => id !== currentUser?.id);
            const otherUser = allUsers?.find(u => u.id === otherParticipantId);
            const name = conv.isGroup 
                ? conv.name 
                : (otherUser?.name || conv.participantInfo[otherParticipantId || '']?.name || '');
            return name?.toLowerCase().includes(searchTerm.toLowerCase());
        });
    }, [conversations, searchTerm, currentUser, allUsers]);

    const toggleSelect = (id: string) => {
        const newSelected = new Set(selectedIds);
        if (newSelected.has(id)) {
            newSelected.delete(id);
        } else {
            newSelected.add(id);
        }
        setSelectedIds(newSelected);
    };

    const handleBulkForward = async () => {
        if (!firestore || !currentUser || !allUsers || !messages.length || selectedIds.size === 0) return;

        setIsSending(true);

        try {
            const batch = writeBatch(firestore);
            const now = new Date().toISOString();

            for (const convId of Array.from(selectedIds)) {
                const conversation = conversations?.find(c => c.id === convId);
                if (!conversation) continue;

                messages.forEach(message => {
                    const senderInfo = allUsers.find(u => u.id === message.senderId);

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
                const unreadCountsUpdate: { [key: string]: any; } = {};
                conversation.participantIds.forEach(id => {
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
            toast({ title: 'Сообщения пересланы', description: `Отправлено в ${selectedIds.size} чат(ов)` });
            handleGoBack();
        } catch (e: any) {
            console.error(`Failed to bulk forward:`, e);
            toast({ variant: 'destructive', title: 'Ошибка пересылки', description: e.message });
            setIsSending(false);
        }
    };
    
    const isLoading = isLoadingUsers || isLoadingConversations;

    return (
        <div className="h-full flex flex-col max-w-4xl mx-auto px-4 relative">
            <header className="flex items-center gap-4 py-6">
                <button onClick={handleGoBack} className="flex-shrink-0 p-2 hover:bg-muted rounded-full transition-colors">
                    <ArrowLeft className="h-6 w-6" />
                </button>
                <h1 className="text-xl font-bold">Выберите получателей</h1>
            </header>
            
            <main className="flex-1 min-h-0 flex flex-col gap-6 pb-24">
                <div className="space-y-3">
                    <h2 className="text-xs font-bold text-muted-foreground ml-1 uppercase tracking-wider">
                        Пересылаемые сообщения ({messages.length})
                    </h2>
                    {allUsers && <ForwardingMessagePreview messages={messages} allUsers={allUsers} />}
                </div>

                <div className="relative group">
                    <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground group-focus-within:text-primary transition-colors" />
                    <Input
                        placeholder="Поиск контактов и групп..."
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        className="rounded-full pl-12 h-12 bg-white border-none shadow-sm focus-visible:ring-2 focus-visible:ring-primary"
                    />
                </div>

                <ScrollArea className="flex-1 -mx-4 px-4">
                    <div className="space-y-1 pb-10">
                        {isLoading ? (
                            <div className="flex justify-center items-center h-40"><Loader2 className="h-8 w-8 animate-spin text-primary/50"/></div>
                        ) : filteredConversations.length > 0 ? (
                            filteredConversations.map(conv => {
                                const isSelected = selectedIds.has(conv.id);
                                const otherParticipantId = conv.participantIds.find(id => id !== currentUser?.id);
                                const otherUser = allUsers?.find(u => u.id === otherParticipantId);
                                
                                const displayName = conv.isGroup 
                                    ? conv.name 
                                    : (otherUser?.name || conv.participantInfo[otherParticipantId || '']?.name || 'Неизвестный чат');
                                
                                const avatar = conv.isGroup
                                    ? conv.photoUrl
                                    : participantListAvatarUrl(
                                        otherUser,
                                        conv.participantInfo[otherParticipantId || ''],
                                      );
                                
                                return (
                                    <div 
                                        key={conv.id} 
                                        onClick={() => toggleSelect(conv.id)}
                                        className={cn(
                                            "flex items-center justify-between p-3 rounded-2xl cursor-pointer transition-all group relative",
                                            isSelected ? "bg-primary/10 ring-1 ring-primary/20" : "hover:bg-muted/80"
                                        )}
                                    >
                                        <div className="flex items-center gap-4 min-w-0 flex-1">
                                            <div className="relative">
                                                <Avatar className="h-12 w-12 border-2 border-background shadow-sm">
                                                    <AvatarImage src={avatar} alt={displayName} />
                                                    <AvatarFallback>{displayName?.charAt(0)}</AvatarFallback>
                                                </Avatar>
                                                {isSelected && (
                                                    <div className="absolute -top-1 -right-1 bg-primary text-white rounded-full p-0.5 shadow-md">
                                                        <Check className="h-3 w-3" />
                                                    </div>
                                                )}
                                            </div>
                                            <div className="min-w-0">
                                                <p className={cn("font-bold truncate", isSelected && "text-primary")}>{displayName}</p>
                                            </div>
                                        </div>
                                        
                                        <div className="flex-shrink-0 ml-4">
                                            <div className={cn(
                                                "h-6 w-6 rounded-full border-2 transition-all flex items-center justify-center",
                                                isSelected ? "bg-primary border-primary" : "border-muted-foreground/30"
                                            )}>
                                                {isSelected && <Check className="h-4 w-4 text-white" />}
                                            </div>
                                        </div>
                                    </div>
                                );
                            })
                        ) : (
                            <div className="text-center text-muted-foreground py-20 bg-muted/20 rounded-3xl border-2 border-dashed">
                                <MessageSquare className="mx-auto h-12 w-12 opacity-20" />
                                <p className="mt-4 font-medium">Ничего не найдено</p>
                            </div>
                        )}
                    </div>
                </ScrollArea>
            </main>

            {selectedIds.size > 0 && (
                <div className="fixed bottom-6 left-1/2 -translate-x-1/2 w-full max-w-sm px-4 z-50 animate-in slide-in-from-bottom-10 duration-300">
                    <Button 
                        size="lg" 
                        onClick={handleBulkForward}
                        disabled={isSending}
                        className="w-full rounded-full shadow-2xl h-14 text-lg font-bold gap-3"
                    >
                        {isSending ? (
                            <Loader2 className="h-6 w-6 animate-spin" />
                        ) : (
                            <SendHorizonal className="h-6 w-6" />
                        )}
                        <span>Переслать в {selectedIds.size} {selectedIds.size === 1 ? 'чат' : 'чата'}</span>
                    </Button>
                </div>
            )}
        </div>
    );
}
