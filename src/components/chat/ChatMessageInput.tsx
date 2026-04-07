'use client';

import React, { useState, useRef, useCallback, useEffect, useMemo, forwardRef, useImperativeHandle } from 'react';
import { ref as storageRef, uploadBytesResumable, getDownloadURL } from 'firebase/storage';
import { useStorage, useFirestore } from '@/firebase';
import type {
  User,
  Conversation,
  ReplyContext,
  ChatMessage,
  ChatAttachment,
  ChatLocationShare,
  ChatLocationSendMeta,
} from '@/lib/types';
import { cn } from '@/lib/utils';
import { useToast } from '@/hooks/use-toast';

import { ChatStickerGifPanel } from '@/components/chat/ChatStickerGifPanel';
import { Button } from '@/components/ui/button';
import { ScrollArea, ScrollBar } from '@/components/ui/scroll-area';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { Separator } from '@/components/ui/separator';
import { 
    SendHorizonal, Paperclip, X, Reply, Mic, StopCircle, Video, 
    File as FileIcon, Trash2, Pencil, UserX, Loader2, Type, MapPin, BarChart3, SmilePlus
} from 'lucide-react';
import { deleteDocumentNonBlocking, setDocumentNonBlocking, useAuth } from '@/firebase';
import { doc } from 'firebase/firestore';
import { compressImage } from '@/lib/image-compression';
import { getImageMetadata } from '@/lib/media-utils';
import { LinkPreview } from './LinkPreview';
import { FormattingToolbar } from './editor/FormattingToolbar';
import { MessageEditor, replaceActiveMentionWithLabel } from './editor/MessageEditor';
import { buildGroupMentionCandidates } from '@/lib/group-mention-utils';
import { buildMentionBoundaryNameList } from '@/lib/mention-editor-query';
import { MessageInputEmojiPicker } from '@/components/chat/MessageInputEmojiPicker';
import { GroupMentionSuggestionsPortal } from '@/components/chat/GroupMentionSuggestionsPortal';
import { ImageEditorModal } from './ImageEditorModal';
import { VideoEditorModal } from './VideoEditorModal';
import { ChatAttachLocationDialog } from '@/components/chat/ChatAttachLocationDialog';
import { ChatAttachPollDialog, type ChatPollCreateInput } from '@/components/chat/ChatAttachPollDialog';
import { AudioMessagePreviewBar } from '@/components/chat/AudioMessagePreviewBar';
import { normalizeFilesAsStickersIfApplicable } from '@/lib/ios-sticker-detect';

/** Не чаще ~2.5–3 раз/с обновлять документ «печатает» в Firestore. */
const TYPING_WRITE_THROTTLE_MS = 350;

export async function uploadFile(file: File, path: string, storage: any): Promise<ChatAttachment> {
  let metadata: { width?: number; height?: number; thumbHash?: string | null } = {};
  if (file.type.startsWith('image/') && !file.type.includes('svg')) {
      const res = await getImageMetadata(file);
      metadata = { width: res.width, height: res.height, thumbHash: res.thumbHash };
  }
  return new Promise((resolve, reject) => {
    const fileRef = storageRef(storage, path);
    const uploadTask = uploadBytesResumable(fileRef, file);
    uploadTask.on('state_changed', null, (err) => reject(err), async () => {
        const url = await getDownloadURL(uploadTask.snapshot.ref);
        resolve({ url, name: file.name, type: file.type, size: file.size, ...metadata });
    });
  });
};

function dataURLtoFile(dataurl: string, filename: string): File {
    const arr = dataurl.split(',');
    const mimeMatch = arr[0].match(/:(.*?);/);
    if (!mimeMatch) throw new Error('Invalid data URL');
    const mime = mimeMatch[1];
    const bstr = atob(arr[1]);
    let n = bstr.length;
    const u8arr = new Uint8Array(n);
    while (n--) u8arr[n] = bstr.charCodeAt(n);
    return new File([u8arr], filename, { type: mime });
}

export type ChatMessageInputHandle = {
  /** Добавить файлы в черновик (с нормализацией стикеров iOS). */
  addDraftFiles: (files: File[]) => void;
};

const ChatMessageInputInner = (
  {
    onSendMessage,
    onSendLocationShare,
    onSendPoll,
    onUpdateMessage,
    replyingTo,
    onCancelReply,
    editingMessage,
    onCancelEdit,
    conversation,
    currentUser,
    allUsers,
    isPartnerDeleted = false,
  }: ChatMessageInputProps,
  ref: React.ForwardedRef<ChatMessageInputHandle>
) => {
    const [attachments, setAttachments] = useState<File[]>([]);
    const [isAttachmentMenuOpen, setIsAttachmentMenuOpen] = useState(false);
    const [showFormatting, setShowFormatting] = useState(false);
    const [isSending, setIsSending] = useState(false);
    const [showMentions, setShowMentions] = useState(false);
    const [mentionSearch, setMentionSearch] = useState('');
    const [videoPreview, setVideoPreview] = useState<{ url: string; blob: Blob } | null>(null);
    const [isVideoRecording, setIsVideoRecording] = useState(false);
    const [detectedUrl, setDetectedUrl] = useState<string | null>(null);
    const [editingFileIndex, setEditingFileIndex] = useState<number | null>(null);
    const [hasContent, setHasContent] = useState(false);
    const [isAudioRecording, setIsAudioRecording] = useState(false);
    const [audioRecordingTime, setAudioRecordingTime] = useState(0);
    const [audioPreview, setAudioPreview] = useState<{ url: string; file: File } | null>(null);
    const [locationDialogOpen, setLocationDialogOpen] = useState(false);
    const [pollDialogOpen, setPollDialogOpen] = useState(false);
    const [attachmentSubview, setAttachmentSubview] = useState<'main' | 'sticker-gif'>('main');

    const editorInstance = useRef<any>(null);
    const mentionAnchorRef = useRef<HTMLDivElement>(null);
    const audioRecorderRef = useRef<MediaRecorder | null>(null);
    const audioChunksRef = useRef<Blob[]>([]);
    const audioStreamRef = useRef<MediaStream | null>(null);
    const audioTimerRef = useRef<NodeJS.Timeout | null>(null);
    const videoPreviewRef = useRef<HTMLVideoElement>(null);
    const videoRecorderRef = useRef<MediaRecorder | null>(null);
    const videoChunksRef = useRef<Blob[]>([]);
    const videoStreamRef = useRef<MediaStream | null>(null);
    const fileInputRef = useRef<HTMLInputElement>(null);
    const typingTimeoutRef = useRef<NodeJS.Timeout | null>(null);
    const typingThrottleTimerRef = useRef<NodeJS.Timeout | null>(null);
    const lastTypingWriteAtRef = useRef(0);
    
    const { toast } = useToast();
    const firestore = useFirestore();
    const storage = useStorage();
    const firebaseAuth = useAuth();

    const groupMentionCandidates = useMemo((): User[] => {
        return buildGroupMentionCandidates(conversation, allUsers, currentUser.id).map(
            (c) =>
                ({
                    id: c.id,
                    name: c.name,
                    username: c.username,
                    email: '',
                    avatar: c.avatar || '',
                    phone: '',
                    bio: '',
                    role: 'worker' as const,
                    deletedAt: null,
                    createdAt: '',
                }) as User
        );
    }, [conversation, allUsers, currentUser.id]);

    /** Имена и username для границы @: после «полное имя + пробел» дальше не ищем участников. */
    const mentionBoundaryNames = useMemo(() => {
        if (!conversation.isGroup) return [] as string[];
        const parts: string[] = [];
        for (const u of groupMentionCandidates) {
            if (u.name?.trim()) parts.push(u.name.trim());
            if (u.username?.trim()) parts.push(u.username.trim());
        }
        return buildMentionBoundaryNameList(parts);
    }, [conversation.isGroup, groupMentionCandidates]);

    const filteredMentionList = useMemo(() => {
        const q = mentionSearch.trim().toLowerCase();
        return groupMentionCandidates.filter((u) => {
            const nameL = (u.name || '').toLowerCase();
            const userL = (u.username || '').toLowerCase();
            return !q || nameL.includes(q) || userL.includes(q);
        });
    }, [groupMentionCandidates, mentionSearch]);

    useEffect(() => {
        return () => {
            if (audioPreview?.url) URL.revokeObjectURL(audioPreview.url);
        };
    }, [audioPreview?.url]);

    useEffect(() => {
        if (editingMessage && editorInstance.current) {
            editorInstance.current.commands.setContent(editingMessage.text);
            editorInstance.current.commands.focus('end');
        }
    }, [editingMessage]);

    /**
     * Только Firebase Auth uid: fallback на currentUser.id давал путь typing/{profileId} при ещё не готовом auth,
     * а правила требуют typingUserId == request.auth.uid → permission-denied на delete при размонтировании.
     */
    const typingAuthUid = firebaseAuth.currentUser?.uid ?? null;
    const typingDocRef = useMemo(() => {
        if (!firestore || !conversation || !typingAuthUid) return null;
        return doc(firestore, 'conversations', conversation.id, 'typing', typingAuthUid);
    }, [firestore, conversation?.id, typingAuthUid]);

    const flushTypingDocument = useCallback(
        (active: boolean) => {
            if (!typingDocRef || isPartnerDeleted) return;
            const uid = firebaseAuth.currentUser?.uid;
            if (!active) {
                if (uid && typingDocRef.id === uid) {
                    deleteDocumentNonBlocking(typingDocRef);
                }
                return;
            }
            if (!uid || typingDocRef.id !== uid) return;
            setDocumentNonBlocking(typingDocRef, { at: new Date().toISOString() }, { merge: true });
        },
        [typingDocRef, isPartnerDeleted, firebaseAuth]
    );

    const updateTypingStatus = useCallback(
        (isTyping: boolean) => {
            if (!firestore || !conversation || isPartnerDeleted || !typingDocRef) return;
            if (!isTyping) {
                if (typingThrottleTimerRef.current) {
                    clearTimeout(typingThrottleTimerRef.current);
                    typingThrottleTimerRef.current = null;
                }
                lastTypingWriteAtRef.current = 0;
                flushTypingDocument(false);
                return;
            }
            const now = Date.now();
            const elapsed = now - lastTypingWriteAtRef.current;
            const sendPulse = () => {
                lastTypingWriteAtRef.current = Date.now();
                flushTypingDocument(true);
                typingThrottleTimerRef.current = null;
            };
            if (elapsed >= TYPING_WRITE_THROTTLE_MS) {
                sendPulse();
            } else if (!typingThrottleTimerRef.current) {
                typingThrottleTimerRef.current = setTimeout(sendPulse, TYPING_WRITE_THROTTLE_MS - elapsed);
            }
        },
        [firestore, conversation, isPartnerDeleted, typingDocRef, flushTypingDocument]
    );

    useEffect(() => {
        return () => {
            if (typingThrottleTimerRef.current) clearTimeout(typingThrottleTimerRef.current);
            const uid = firebaseAuth.currentUser?.uid;
            if (typingDocRef && !isPartnerDeleted && uid && typingDocRef.id === uid) {
                deleteDocumentNonBlocking(typingDocRef);
            }
        };
    }, [typingDocRef, isPartnerDeleted, firebaseAuth]);

    const handleSend = async () => {
        const editor = editorInstance.current;
        if (isSending || isPartnerDeleted || !editor) return;
        
        const text = editor.getHTML();
        const hasText = editor.getText().trim().length > 0;
        
        if (!hasText && attachments.length === 0 && !videoPreview) return;

        // Фиксируем текущие данные для отправки перед очисткой UI
        const finalFiles = [...attachments];
        const currentVideoPreview = videoPreview;
        const currentReplyingTo = replyingTo;

        // МГНОВЕННО очищаем строку ввода и вложения
        editor.commands.clearContent();
        setHasContent(false);
        setAttachments([]);
        setVideoPreview(null);
        setDetectedUrl(null);
        if (currentReplyingTo) onCancelReply();

        setIsSending(true);
        updateTypingStatus(false);
        if (typingTimeoutRef.current) clearTimeout(typingTimeoutRef.current);
        try {
            if (editingMessage) {
                await onUpdateMessage(editingMessage.id, text, editingMessage.attachments);
                onCancelEdit();
            } else {
                let preparedFiles = [...finalFiles];
                if (currentVideoPreview) {
                    const videoFile = new File([currentVideoPreview.blob], `video-circle_${Date.now()}.webm`, { type: 'video/webm' });
                    preparedFiles.push(videoFile);
                }
                await onSendMessage(hasText ? text : undefined, preparedFiles, currentReplyingTo, undefined);
            }
        } catch (error) {
            console.error("Failed to send message:", error);
        } finally {
            setIsSending(false);
        }
    };

    const syncMentionUiFromQuery = useCallback(
        (mentionQuery: string | null) => {
            if (conversation.isGroup && mentionQuery !== null) {
                setMentionSearch(mentionQuery);
                setShowMentions(true);
            } else {
                setShowMentions(false);
            }
        },
        [conversation.isGroup]
    );

    const handleEditorUpdate = (html: string, text: string, hasMeaningfulContent: boolean, mentionQuery: string | null) => {
        setHasContent(hasMeaningfulContent);
        const urlMatch = text.match(/https?:\/\/[^\s<"']+/g);
        setDetectedUrl(urlMatch ? urlMatch[urlMatch.length - 1].replace(/[.,!?;:)}\]]+$/, '') : null);

        syncMentionUiFromQuery(mentionQuery);

        updateTypingStatus(true);
        if (typingTimeoutRef.current) clearTimeout(typingTimeoutRef.current);
        typingTimeoutRef.current = setTimeout(() => updateTypingStatus(false), 3000);
    };

    const applyMention = (participant: User) => {
        const editor = editorInstance.current;
        if (!editor) return;
        replaceActiveMentionWithLabel(editor, participant.name, participant.id);
        setShowMentions(false);
    };

    /** `applyKeyboardStickerHeuristic`: только для вставки из буфера (стикеры iOS с клавиатуры). Галерея / файл / drag-drop — без авто-`sticker_`. */
    const ingestAttachmentFiles = useCallback(async (raw: File[], applyKeyboardStickerHeuristic: boolean) => {
        if (!raw.length || isPartnerDeleted) return;
        const next = await normalizeFilesAsStickersIfApplicable(raw, applyKeyboardStickerHeuristic);
        setAttachments((prev) => [...prev, ...next]);
    }, [isPartnerDeleted]);

    useImperativeHandle(ref, () => ({
        addDraftFiles: (files: File[]) => {
            void ingestAttachmentFiles(files, false);
        },
    }), [ingestAttachmentFiles]);

    const handlePasteFiles = (files: File[]) => {
        void ingestAttachmentFiles(files, true);
    };

    const handleStartVideoRecording = async () => {
        setIsAttachmentMenuOpen(false);
        setAttachmentSubview('main');
        try {
            const stream = await navigator.mediaDevices.getUserMedia({ video: { width: 480, height: 480 }, audio: true });
            videoStreamRef.current = stream;
            setIsVideoRecording(true);
            setTimeout(() => { if (videoPreviewRef.current) videoPreviewRef.current.srcObject = stream; }, 100);
            const recorder = new MediaRecorder(stream, { mimeType: 'video/webm' });
            videoRecorderRef.current = recorder; videoChunksRef.current = [];
            recorder.ondataavailable = (e) => videoChunksRef.current.push(e.data);
            recorder.onstop = () => setVideoPreview({ url: URL.createObjectURL(new Blob(videoChunksRef.current, { type: 'video/webm' })), blob: new Blob(videoChunksRef.current, { type: 'video/webm' }) });
            recorder.start();
        } catch (err) { toast({ variant: "destructive", title: "Ошибка камеры" }); }
    };

    const stopVideoRecording = () => {
        if (videoRecorderRef.current?.state === "recording") videoRecorderRef.current.stop();
        videoStreamRef.current?.getTracks().forEach(t => t.stop());
        setIsVideoRecording(false);
    };

    const removeAttachment = (index: number) => {
        setAttachments(prev => prev.filter((_, i) => i !== index));
    };

    const handleEditedFile = (editedFile: File | File[], captionFromEditor?: string) => {
        if (editingFileIndex === null) return;
        
        setAttachments(prev => {
            const next = [...prev];
            if (Array.isArray(editedFile)) {
                next[editingFileIndex] = editedFile[0];
            } else {
                next[editingFileIndex] = editedFile;
            }
            return next;
        });

        if (captionFromEditor) {
            editorInstance.current?.commands.setContent(captionFromEditor);
        }
        setEditingFileIndex(null);
    };

    const discardAudioPreview = useCallback(() => {
        setAudioPreview((prev) => {
            if (prev?.url) URL.revokeObjectURL(prev.url);
            return null;
        });
    }, []);

    const handleSendAudioPreview = async () => {
        if (!audioPreview || isSending || isPartnerDeleted) return;
        const { file, url } = audioPreview;
        const currentReplyingTo = replyingTo;
        URL.revokeObjectURL(url);
        setAudioPreview(null);
        if (currentReplyingTo) onCancelReply();
        setIsSending(true);
        try {
            await onSendMessage(undefined, [file], currentReplyingTo, undefined);
        } catch (error) {
            console.error("Failed to send audio:", error);
        } finally {
            setIsSending(false);
        }
    };

    const handleStartAudioRecording = async () => {
        try {
            setAudioPreview((prev) => {
                if (prev?.url) URL.revokeObjectURL(prev.url);
                return null;
            });
            const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
            audioStreamRef.current = stream;
            const recorder = new MediaRecorder(stream, { mimeType: MediaRecorder.isTypeSupported('audio/webm') ? 'audio/webm' : 'audio/mp4' });
            audioRecorderRef.current = recorder;
            audioChunksRef.current = [];
            recorder.ondataavailable = (e) => { if (e.data.size > 0) audioChunksRef.current.push(e.data); };
            recorder.onstop = () => {
                audioStreamRef.current?.getTracks().forEach(t => t.stop());
            };
            recorder.start();
            setIsAudioRecording(true);
            setAudioRecordingTime(0);
            audioTimerRef.current = setInterval(() => setAudioRecordingTime(t => t + 1), 1000);
        } catch (err) {
            toast({ variant: "destructive", title: "Нет доступа к микрофону" });
        }
    };

    const handleStopAudioRecording = () => {
        if (audioTimerRef.current) {
            clearInterval(audioTimerRef.current);
            audioTimerRef.current = null;
        }
        const rec = audioRecorderRef.current;
        if (!rec || rec.state !== "recording") return;
        rec.onstop = () => {
            audioStreamRef.current?.getTracks().forEach(t => t.stop());
            const mimeType = rec.mimeType || "audio/webm";
            const ext = mimeType.includes("mp4") ? "mp4" : "webm";
            const blob = new Blob(audioChunksRef.current, { type: mimeType });
            audioChunksRef.current = [];
            if (blob.size < 100) {
                setIsAudioRecording(false);
                setAudioRecordingTime(0);
                toast({ variant: "destructive", title: "Слишком короткая запись" });
                return;
            }
            const url = URL.createObjectURL(blob);
            const file = new File([blob], `audio_${Date.now()}.${ext}`, { type: mimeType });
            setAudioPreview({ url, file });
            setIsAudioRecording(false);
            setAudioRecordingTime(0);
        };
        rec.stop();
    };

    const handleCancelAudioRecording = () => {
        if (audioTimerRef.current) {
            clearInterval(audioTimerRef.current);
            audioTimerRef.current = null;
        }
        if (audioRecorderRef.current) {
            audioRecorderRef.current.ondataavailable = null;
            audioRecorderRef.current.onstop = () => {
                audioStreamRef.current?.getTracks().forEach(t => t.stop());
            };
            if (audioRecorderRef.current.state === "recording") audioRecorderRef.current.stop();
        } else {
            audioStreamRef.current?.getTracks().forEach(t => t.stop());
        }
        audioChunksRef.current = [];
        setIsAudioRecording(false);
        setAudioRecordingTime(0);
    };

    const formatRecordingTime = (seconds: number) => {
        const m = Math.floor(seconds / 60).toString().padStart(2, '0');
        const s = (seconds % 60).toString().padStart(2, '0');
        return `${m}:${s}`;
    };

    const currentFileToEdit = editingFileIndex !== null ? attachments[editingFileIndex] : null;

    return (
        <div className="w-full px-4 pb-6 pt-1 relative bg-transparent overflow-visible">
            <div className="flex flex-col gap-1.5 shrink-0">
                {isPartnerDeleted ? (
                    <div className="p-4 bg-muted/50 rounded-2xl flex items-center justify-center gap-2 text-muted-foreground">
                        <UserX className="h-4 w-4" /><p className="text-sm font-medium">Пользователь удален</p>
                    </div>
                ) : isVideoRecording ? (
                    <div className="p-2 flex flex-col items-center justify-center gap-4 bg-muted/30 rounded-[2.5rem] mb-2">
                        <div className="relative w-48 h-48 rounded-full overflow-hidden border-4 border-primary/20">
                            <video ref={videoPreviewRef} autoPlay muted playsInline className="w-full h-full object-cover -scale-x-100" />
                        </div>
                        <Button variant="destructive" size="icon" className="rounded-full h-12 w-12" onClick={stopVideoRecording}><StopCircle className="h-6 w-6" /></Button>
                    </div>
                ) : videoPreview ? (
                    <div className="p-4 flex flex-col items-center justify-center gap-4 bg-muted/30 rounded-[2.5rem] mb-2">
                        <div className="relative w-48 h-48 rounded-full overflow-hidden border-4 border-green-500/20 shadow-2xl">
                            <video src={videoPreview.url} autoPlay loop playsInline className="w-full h-full object-cover" />
                        </div>
                        <div className="flex items-center gap-4">
                            <Button variant="ghost" size="icon" className="rounded-full h-12 w-12 text-destructive" onClick={() => setVideoPreview(null)}><Trash2 className="h-6 w-6" /></Button>
                            <Button size="icon" className="rounded-full h-14 w-14 bg-primary shadow-xl" onClick={handleSend}><SendHorizonal className="h-7 w-7" /></Button>
                        </div>
                    </div>
                ) : audioPreview ? (
                    <AudioMessagePreviewBar
                        src={audioPreview.url}
                        onDiscard={discardAudioPreview}
                        onSend={handleSendAudioPreview}
                        isSending={isSending}
                    />
                ) : (
                    <>
                        {(replyingTo || editingMessage) && (
                            <div className="bg-muted/50 rounded-t-[1.25rem] p-2 px-4 flex items-center justify-between border-b border-black/5 animate-in slide-in-from-bottom-2 duration-300">
                                <div className="flex items-center gap-3 min-w-0">
                                    <div className="p-2 bg-primary/10 rounded-full shrink-0">
                                        {replyingTo ? <Reply className="h-3.5 w-3.5 text-primary" /> : <Pencil className="h-3.5 w-3.5 text-primary" />}
                                    </div>
                                    <div className="min-w-0 flex-1">
                                        <p className="text-[9px] font-black uppercase text-primary tracking-[0.1em] opacity-80 leading-none mb-1">
                                            {replyingTo ? 'Ответ пользователю' : 'Редактирование сообщения'}
                                        </p>
                                        <p className="text-xs text-muted-foreground truncate font-medium">
                                            {replyingTo ? (
                                                <><span className="font-bold text-foreground/80">{replyingTo.senderName}:</span> {replyingTo.text}</>
                                            ) : (
                                                editingMessage.text?.replace(/<[^>]*>/g, '') || 'Без текста'
                                            )}
                                        </p>
                                    </div>
                                    {replyingTo?.mediaPreviewUrl && (
                                        <div className="h-10 w-10 rounded-lg overflow-hidden shrink-0 border border-black/5 bg-black/20 ml-2">
                                            {replyingTo.mediaType === 'video' || replyingTo.mediaType === 'video-circle' ? (
                                                <video src={replyingTo.mediaPreviewUrl} className="h-full w-full object-cover" muted />
                                            ) : (
                                                <img src={replyingTo.mediaPreviewUrl} className={cn("h-full w-full object-cover", replyingTo.mediaType === 'sticker' && "object-contain p-1")} alt="" />
                                            )}
                                        </div>
                                    )}
                                </div>
                                <Button variant="ghost" size="icon" className="h-8 w-8 rounded-full shrink-0 hover:bg-black/5" onClick={replyingTo ? onCancelReply : onCancelEdit}>
                                    <X className="h-4 w-4" />
                                </Button>
                            </div>
                        )}
                        {detectedUrl && !editingMessage && (
                            <div className="bg-muted/50 rounded-2xl p-1 animate-in slide-in-from-bottom-2">
                                <div className="flex justify-between items-center px-3 pt-1">
                                    <span className="text-[10px] font-bold uppercase text-muted-foreground">Превью ссылки</span>
                                    <Button variant="ghost" size="icon" className="h-5 w-5" onClick={() => setDetectedUrl(null)}><X className="h-3 w-3" /></Button>
                                </div>
                                <LinkPreview url={detectedUrl} isLive />
                            </div>
                        )}
                        
                        {attachments.length > 0 && !editingMessage && (
                            <div className="bg-muted/30 rounded-t-2xl border-b border-black/5">
                                <ScrollArea className="w-full">
                                    <div className="flex gap-2 p-3 overflow-x-auto no-scrollbar">
                                        {attachments.map((file, idx) => {
                                            const isEditable = file.type.startsWith('image/') || file.type.startsWith('video/');
                                            return (
                                                <div key={idx} className="relative h-16 w-16 rounded-xl overflow-hidden border border-black/10 shrink-0 animate-in zoom-in-95 duration-200 group/item">
                                                    {file.type.startsWith('image/') ? (
                                                        <img src={URL.createObjectURL(file)} className="h-full w-full object-cover" alt="" />
                                                    ) : (
                                                        <div className="h-full w-full flex flex-col items-center justify-center bg-background text-[8px] font-bold uppercase p-1 text-center">
                                                            <FileIcon className="h-5 w-5 text-primary mb-1" />
                                                            <span className="truncate w-full">{file.name.split('.').pop()}</span>
                                                        </div>
                                                    )}
                                                    
                                                    <Button variant="ghost" size="icon" className="absolute top-0.5 right-0.5 h-5 w-5 rounded-full bg-black/50 text-white hover:bg-red-500 z-10" onClick={() => removeAttachment(idx)}>
                                                        <X className="h-3 w-3" />
                                                    </Button>

                                                    {isEditable && (
                                                        <Button 
                                                            variant="ghost" 
                                                            size="icon" 
                                                            className="absolute bottom-0.5 right-0.5 h-5 w-5 rounded-full bg-black/50 text-white hover:bg-primary z-10 opacity-0 group-hover/item:opacity-100 transition-opacity" 
                                                            onClick={() => setEditingFileIndex(idx)}
                                                        >
                                                            <Pencil className="h-3 w-3" />
                                                        </Button>
                                                    )}
                                                </div>
                                            );
                                        })}
                                    </div>
                                    <ScrollBar orientation="horizontal" className="opacity-0" />
                                </ScrollArea>
                            </div>
                        )}

                        <div className="flex items-end gap-1.5 pb-0.5">
                            {isAudioRecording ? (
                                <div className="flex flex-1 items-center gap-2 p-1 px-3 bg-muted/50 rounded-[1.25rem] backdrop-blur-xl min-w-0 overflow-hidden">
                                    <Button variant="ghost" size="icon" className="h-9 w-9 shrink-0 text-destructive" onClick={handleCancelAudioRecording}>
                                        <Trash2 className="h-4 w-4" />
                                    </Button>
                                    <div className="flex items-center gap-2 flex-1 min-w-0">
                                        <span className="h-2.5 w-2.5 rounded-full bg-destructive animate-pulse shrink-0" />
                                        <span className="text-sm font-medium tabular-nums">{formatRecordingTime(audioRecordingTime)}</span>
                                    </div>
                                    <Button size="icon" className="h-9 w-9 shrink-0 rounded-full bg-primary" onClick={handleStopAudioRecording}>
                                        <SendHorizonal className="h-4 w-4" />
                                    </Button>
                                </div>
                            ) : (
                                <div className={cn(
                                    /* overflow-visible — иначе панель @ обрезается и клики ломаются */
                                    "flex flex-1 items-center gap-1 p-1 bg-muted/50 rounded-[1.25rem] backdrop-blur-xl min-w-0 overflow-visible",
                                    (replyingTo || editingMessage || attachments.length > 0) && "rounded-t-none"
                                )}>
                                    <Popover
                                        open={isAttachmentMenuOpen}
                                        onOpenChange={(open) => {
                                            setIsAttachmentMenuOpen(open);
                                            if (!open) setAttachmentSubview('main');
                                        }}
                                    >
                                        <PopoverTrigger asChild><Button variant="ghost" size="icon" className="h-9 w-9 shrink-0"><Paperclip className="h-4 w-4" /></Button></PopoverTrigger>
                                        <PopoverContent
                                            className={cn(
                                                attachmentSubview === 'sticker-gif' ? 'w-[min(100vw-1.5rem,20rem)]' : 'w-64',
                                                'p-2 rounded-2xl mb-1 text-popover-foreground',
                                                'border border-white/30 dark:border-white/15',
                                                'bg-background/50 dark:bg-background/40 backdrop-blur-xl backdrop-saturate-150',
                                                'shadow-[0_12px_40px_-8px_rgba(0,0,0,0.25)] dark:shadow-[0_12px_48px_-8px_rgba(0,0,0,0.65)]',
                                                'ring-1 ring-black/5 dark:ring-white/10'
                                            )}
                                            side="top"
                                            align="start"
                                        >
                                            {showFormatting ? (
                                                <FormattingToolbar editor={editorInstance.current} onBack={() => setShowFormatting(false)} />
                                            ) : attachmentSubview === 'sticker-gif' ? (
                                                <div className="space-y-2">
                                                    <Button
                                                        type="button"
                                                        variant="ghost"
                                                        className="h-9 w-full justify-start rounded-xl text-xs font-bold uppercase tracking-wide text-muted-foreground"
                                                        onClick={() => setAttachmentSubview('main')}
                                                    >
                                                        ← Меню вложений
                                                    </Button>
                                                    <ChatStickerGifPanel
                                                        userId={currentUser.id}
                                                        onPickStickerAttachment={(att) => {
                                                            void onSendMessage(undefined, [], replyingTo, [att]);
                                                            setIsAttachmentMenuOpen(false);
                                                            setAttachmentSubview('main');
                                                        }}
                                                        onPickGifAttachment={(att) => {
                                                            void onSendMessage(undefined, [], replyingTo, [att]);
                                                            setIsAttachmentMenuOpen(false);
                                                            setAttachmentSubview('main');
                                                        }}
                                                    />
                                                </div>
                                            ) : (
                                                <div className="space-y-0.5">
                                                    <Button
                                                        variant="ghost"
                                                        onClick={() => {
                                                            setIsAttachmentMenuOpen(false);
                                                            setAttachmentSubview('main');
                                                            fileInputRef.current?.click();
                                                        }}
                                                        className="w-full justify-start rounded-xl h-11"
                                                    >
                                                        <FileIcon className="mr-3 h-4 w-4" />Файл
                                                    </Button>
                                                    <Button
                                                        variant="ghost"
                                                        onClick={handleStartVideoRecording}
                                                        className="w-full justify-start rounded-xl h-11 hover:bg-white/25 dark:hover:bg-white/10 active:bg-white/35 dark:active:bg-white/15"
                                                    >
                                                        <Video className="mr-3 h-4 w-4 text-sky-600 dark:text-sky-400" />
                                                        Кружок
                                                    </Button>
                                                    {onSendLocationShare && (
                                                        <Button
                                                            variant="ghost"
                                                            type="button"
                                                            disabled={isPartnerDeleted}
                                                            onClick={() => { setIsAttachmentMenuOpen(false); setLocationDialogOpen(true); }}
                                                            className="w-full justify-start rounded-xl h-11"
                                                        >
                                                            <MapPin className="mr-3 h-4 w-4 text-emerald-600" />
                                                            Локация
                                                        </Button>
                                                    )}
                                                    {onSendPoll && (
                                                        <Button
                                                            variant="ghost"
                                                            type="button"
                                                            disabled={isPartnerDeleted}
                                                            onClick={() => { setIsAttachmentMenuOpen(false); setPollDialogOpen(true); }}
                                                            className="w-full justify-start rounded-xl h-11"
                                                        >
                                                            <BarChart3 className="mr-3 h-4 w-4 text-violet-600" />
                                                            Опрос
                                                        </Button>
                                                    )}
                                                    <Button
                                                        type="button"
                                                        variant="ghost"
                                                        disabled={isPartnerDeleted}
                                                        onClick={() => setAttachmentSubview('sticker-gif')}
                                                        className="w-full justify-start rounded-xl h-11"
                                                    >
                                                        <SmilePlus className="mr-3 h-4 w-4 opacity-70" />
                                                        Стикеры и GIF
                                                    </Button>
                                                    <Separator className="my-1" />
                                                    <Button variant="ghost" onClick={() => setShowFormatting(true)} className="w-full justify-start rounded-xl h-11"><Type className="mr-3 h-4 w-4" />Форматировать</Button>
                                                </div>
                                            )}
                                        </PopoverContent>
                                    </Popover>

                                    <MessageInputEmojiPicker editorRef={editorInstance} disabled={isPartnerDeleted} />

                                    <div ref={mentionAnchorRef} className="relative flex-1 min-w-0 min-h-0">
                                        <GroupMentionSuggestionsPortal
                                            open={showMentions && conversation.isGroup}
                                            anchorRef={mentionAnchorRef}
                                            participants={filteredMentionList}
                                            onPick={applyMention}
                                        />
                                        <MessageEditor
                                            onUpdate={handleEditorUpdate}
                                            onMentionQueryCursor={syncMentionUiFromQuery}
                                            onEnter={handleSend}
                                            editorRef={editorInstance}
                                            onPasteFiles={handlePasteFiles}
                                            shouldBlockEnter={() => showMentions && conversation.isGroup}
                                            mentionBoundaryNames={mentionBoundaryNames}
                                        />
                                    </div>

                                    {(hasContent || attachments.length > 0 || editingMessage) ? (
                                        <Button
                                            type="button"
                                            size="icon"
                                            className="h-9 w-9 shrink-0 rounded-full bg-primary text-primary-foreground hover:bg-primary/90 shadow-sm"
                                            onClick={handleSend}
                                            disabled={isSending}
                                        >
                                            {isSending ? <Loader2 className="h-4 w-4 animate-spin" /> : <SendHorizonal className="h-4 w-4" />}
                                        </Button>
                                    ) : (
                                        <Button
                                            type="button"
                                            variant="ghost"
                                            size="icon"
                                            className="h-9 w-9 shrink-0 rounded-full text-muted-foreground hover:text-foreground hover:bg-muted"
                                            onClick={handleStartAudioRecording}
                                        >
                                            <Mic className="h-4 w-4" />
                                        </Button>
                                    )}
                                </div>
                            )}
                        </div>
                    </>
                )}
            </div>
            <input
                ref={fileInputRef}
                type="file"
                multiple
                className="hidden"
                onChange={(e) => {
                    if (!e.target.files?.length) return;
                    const list = Array.from(e.target.files);
                    void ingestAttachmentFiles(list, false);
                    setIsAttachmentMenuOpen(false);
                    setAttachmentSubview('main');
                    e.target.value = '';
                }}
            />

            {currentFileToEdit && currentFileToEdit.type.startsWith('image/') && (
                <ImageEditorModal 
                    files={[currentFileToEdit]}
                    initialIndex={0}
                    onClose={() => setEditingFileIndex(null)}
                    onDeleteImage={() => { removeAttachment(editingFileIndex!); setEditingFileIndex(null); }}
                    onSave={(editedFiles, caption) => handleEditedFile(editedFiles, caption)}
                />
            )}

            {currentFileToEdit && currentFileToEdit.type.startsWith('video/') && (
                <VideoEditorModal 
                    file={currentFileToEdit}
                    onClose={() => setEditingFileIndex(null)}
                    onSave={(editedFile, caption) => handleEditedFile(editedFile, caption)}
                />
            )}

            {onSendLocationShare && (
                <ChatAttachLocationDialog
                    open={locationDialogOpen}
                    onOpenChange={setLocationDialogOpen}
                    onShare={({ share, meta }) => onSendLocationShare(share, replyingTo, meta)}
                />
            )}
            {onSendPoll && (
                <ChatAttachPollDialog
                    open={pollDialogOpen}
                    onOpenChange={setPollDialogOpen}
                    onCreate={(input: ChatPollCreateInput) => onSendPoll(input, replyingTo)}
                />
            )}
        </div>
    );
};

export const ChatMessageInput = forwardRef(ChatMessageInputInner);
ChatMessageInput.displayName = 'ChatMessageInput';

export interface ChatMessageInputProps {
    onSendMessage: (
        text?: string,
        attachments?: File[],
        replyTo?: ReplyContext | null,
        prebuiltAttachments?: ChatAttachment[]
    ) => Promise<void>;
    /** Геолокация в чат (Google Maps + Static Maps при наличии ключа). */
    onSendLocationShare?: (
      share: ChatLocationShare,
      replyTo: ReplyContext | null,
      meta: ChatLocationSendMeta
    ) => Promise<void>;
    /** Опрос в чате (документы в conversations/.../polls). */
    onSendPoll?: (input: ChatPollCreateInput, replyTo: ReplyContext | null) => Promise<void>;
    onUpdateMessage: (id: string, text: string, attachments?: ChatAttachment[]) => Promise<void>;
    replyingTo: ReplyContext | null;
    onCancelReply: () => void;
    editingMessage: any | null;
    onCancelEdit: () => void;
    conversation: Conversation;
    currentUser: User;
    allUsers: User[];
    isPartnerDeleted?: boolean;
}