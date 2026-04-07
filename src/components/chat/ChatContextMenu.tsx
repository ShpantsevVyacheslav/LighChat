'use client';

import React from 'react';
import { useRouter } from 'next/navigation';
import { Eraser, Trash2, FolderEdit, Pin, PinOff } from 'lucide-react';
import type { Conversation, User } from '@/lib/types';
import { isSavedMessagesChat } from '@/lib/saved-messages-chat';

interface ChatContextMenuProps {
    x: number;
    y: number;
    conv: Conversation;
    currentUser: User;
    onClose: () => void;
    onManageFolders?: (conv: Conversation) => void;
    isPinnedInFolder: boolean;
    onToggleFolderPin: (conversationId: string) => void;
}

export function ChatContextMenu({
    x,
    y,
    conv,
    currentUser,
    onClose,
    onManageFolders,
    isPinnedInFolder,
    onToggleFolderPin,
}: ChatContextMenuProps) {
    const router = useRouter();

    const isAlreadyCleared = conv.clearedAt?.[currentUser.id] && 
        (!conv.lastMessageTimestamp || new Date(conv.clearedAt[currentUser.id]) >= new Date(conv.lastMessageTimestamp));

    const isSavedChat = isSavedMessagesChat(conv, currentUser.id);

    const menuTop = Math.min(y, typeof window !== 'undefined' ? window.innerHeight - 220 : y);
    const menuLeft = Math.min(x, typeof window !== 'undefined' ? window.innerWidth - 240 : x);

    return (
        <div 
            className="fixed z-[100] w-56 rounded-2xl bg-popover/90 backdrop-blur-xl border border-white/10 shadow-2xl overflow-hidden animate-in zoom-in-95 duration-200"
            style={{ top: menuTop, left: menuLeft }}
            onClick={(e) => e.stopPropagation()}
        >
            <div className="p-1.5 space-y-0.5">
                {!isSavedChat && (
                    <button
                        onClick={() => {
                            onManageFolders?.(conv);
                            onClose();
                        }}
                        className="w-full flex items-center px-3 py-2 text-sm hover:bg-white/10 rounded-xl transition-colors text-left font-medium"
                    >
                        <FolderEdit className="mr-3 h-4 w-4 opacity-60 text-primary" /> Папки
                    </button>
                )}

                {/* «Избранное»: папки недоступны, но закрепление в текущей папке списка и очистка — как у обычного чата */}
                <button
                    type="button"
                    onClick={() => {
                        onToggleFolderPin(conv.id);
                        onClose();
                    }}
                    className="w-full flex items-center px-3 py-2 text-sm hover:bg-white/10 rounded-xl transition-colors text-left font-medium"
                >
                    {isPinnedInFolder ? (
                        <>
                            <PinOff className="mr-3 h-4 w-4 opacity-60 text-amber-500" /> Открепить в этой папке
                        </>
                    ) : (
                        <>
                            <Pin className="mr-3 h-4 w-4 opacity-60 text-amber-500" /> Закрепить в этой папке
                        </>
                    )}
                </button>
                
                <button 
                    disabled={!!isAlreadyCleared}
                    onClick={() => { router.push(`/dashboard/chat/${conv.id}/clear`); onClose(); }}
                    className="w-full flex items-center px-3 py-2 text-sm hover:bg-white/10 rounded-xl transition-colors disabled:opacity-30 disabled:cursor-not-allowed text-left"
                >
                    <Eraser className="mr-3 h-4 w-4 opacity-60" /> Очистить историю
                </button>
                {!conv.isGroup && !isSavedMessagesChat(conv, currentUser.id) && (
                    <button 
                        onClick={() => { router.push(`/dashboard/chat/${conv.id}/delete`); onClose(); }}
                        className="w-full flex items-center px-3 py-2 text-sm hover:bg-red-500/20 text-destructive rounded-xl transition-colors font-bold text-left"
                    >
                        <Trash2 className="mr-3 h-4 w-4" /> Удалить чат
                    </button>
                )}
            </div>
        </div>
    );
}
