'use client';

import React, { useState, useRef, useCallback, useEffect, useMemo, forwardRef, useImperativeHandle } from 'react';
import { ref as storageRef, uploadBytesResumable, getDownloadURL, type FirebaseStorage } from 'firebase/storage';
import { useFirestore } from '@/firebase';
import type {
  User,
  Conversation,
  ReplyContext,
  ChatAttachment,
  ChatLocationShare,
  ChatLocationSendMeta,
  UserContactLocalProfile,
} from '@/lib/types';
import { cn } from '@/lib/utils';
import { useToast } from '@/hooks/use-toast';
import { useI18n } from '@/hooks/use-i18n';

import { Button } from '@/components/ui/button';
import { ScrollArea, ScrollBar } from '@/components/ui/scroll-area';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { Separator } from '@/components/ui/separator';
import { 
    SendHorizonal, Paperclip, X, Reply, Mic, StopCircle, Video, 
    File as FileIcon, Trash2, Pencil, UserX, Loader2, Type, MapPin, BarChart3, Ban
} from 'lucide-react';
import { deleteDocumentNonBlocking, setDocumentNonBlocking, useAuth } from '@/firebase';
import { doc } from 'firebase/firestore';
import { getImageMetadata } from '@/lib/media-utils';
import { LinkPreview } from './LinkPreview';
import { FormattingToolbar } from './editor/FormattingToolbar';
import { MessageEditor, replaceActiveMentionWithLabel } from './editor/MessageEditor';
import { buildGroupMentionCandidates } from '@/lib/group-mention-utils';
import { buildMentionBoundaryNameList } from '@/lib/mention-editor-query';
import { ComposerStickerGifPopover } from '@/components/chat/ComposerStickerGifPopover';
import { GroupMentionSuggestionsPortal } from '@/components/chat/GroupMentionSuggestionsPortal';
import { ImageEditorModal } from './ImageEditorModal';
import { VideoEditorModal } from './VideoEditorModal';
import { ChatAttachLocationDialog } from '@/components/chat/ChatAttachLocationDialog';
import { ChatAttachPollDialog, type ChatPollCreateInput } from '@/components/chat/ChatAttachPollDialog';
import { ChatScheduleMessageDialog } from '@/components/chat/ChatScheduleMessageDialog';
import { AudioMessagePreviewBar } from '@/components/chat/AudioMessagePreviewBar';
import { normalizeFilesAsStickersIfApplicable } from '@/lib/ios-sticker-detect';
import { logger } from '@/lib/logger';
import { AnalyticsEvents, track } from '@/lib/analytics';
import { durationBucket } from '@/lib/analytics/events';
import { chatDraftPlainFromHtml,
  clearChatMessageDraft,
  getChatMessageDraft,
  saveChatMessageDraft,
} from '@/lib/chat-message-draft-storage';
import type { Editor } from '@tiptap/core';

/** Не чаще ~2.5–3 раз/с обновлять документ «печатает» в Firestore. */
const TYPING_WRITE_THROTTLE_MS = 350;

export async function uploadFile(file: File, path: string, storage: FirebaseStorage): Promise<ChatAttachment> {
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

export type ChatMessageInputHandle = {
  /** Добавить файлы в черновик (с нормализацией стикеров iOS). */
  addDraftFiles: (files: File[]) => void;
};

const ChatMessageInputInner = (
  {
    onSendMessage,
    onSendLocationShare,
    onSendPoll,
    onScheduleMessage,
    onUpdateMessage,
    replyingTo,
    onCancelReply,
    editingMessage,
    onCancelEdit,
    conversation,
    currentUser,
    allUsers,
    contactProfiles,
    isPartnerDeleted = false,
    composerLocked = false,
    composerLockedHint,
    draftScopeKey,
    onRestoreDraftReply,
    e2eeEnabled = false,
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
    const [scheduleDialogOpen, setScheduleDialogOpen] = useState(false);

    const draftKey = draftScopeKey ?? conversation.id;

    const editorInstance = useRef<Editor | null>(null);
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
    const longPressTimerRef = useRef<NodeJS.Timeout | null>(null);
    const longPressTriggeredRef = useRef(false);
    const editingMessageRef = useRef(editingMessage);
    editingMessageRef.current = editingMessage;
    const replyingToRef = useRef(replyingTo);
    replyingToRef.current = replyingTo;
    const attachmentsRef = useRef<File[]>([]);
    attachmentsRef.current = attachments;
    /** Превью «кружка» до отправки — участвует в решении, сохранять ли черновик. */
    const circleVideoDraftRef = useRef<typeof videoPreview>(null);
    circleVideoDraftRef.current = videoPreview;
    const onRestoreDraftReplyRef = useRef(onRestoreDraftReply);
    onRestoreDraftReplyRef.current = onRestoreDraftReply;
    const typingTimeoutRef = useRef<NodeJS.Timeout | null>(null);
    const typingThrottleTimerRef = useRef<NodeJS.Timeout | null>(null);
    const lastTypingWriteAtRef = useRef(0);
    
    const { toast } = useToast();
    const { t } = useI18n();
    const firestore = useFirestore();
    const firebaseAuth = useAuth();

    const inputFrozen = isPartnerDeleted || composerLocked;

    const groupMentionCandidates = useMemo((): User[] => {
        return buildGroupMentionCandidates(conversation, allUsers, currentUser.id, {
            contactProfiles,
        }).map(
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
    }, [conversation, allUsers, currentUser.id, contactProfiles]);

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

    // Preview URL must not be created inside render loop; keep lifecycle explicit.
    const attachmentPreviewUrls = useMemo(
        () => attachments.map((file) => (file.type.startsWith('image/') ? URL.createObjectURL(file) : null)),
        [attachments]
    );

    useEffect(() => {
        return () => {
            for (const url of attachmentPreviewUrls) {
                if (url) URL.revokeObjectURL(url);
            }
        };
    }, [attachmentPreviewUrls]);

    useEffect(() => {
        return () => {
            if (audioPreview?.url) URL.revokeObjectURL(audioPreview.url);
        };
    }, [audioPreview?.url]);

    useEffect(() => {
        if (editingMessage && editorInstance.current) {
            editorInstance.current.commands.setContent(editingMessage.text ?? '');
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
            if (!typingDocRef || inputFrozen) return;
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
        [typingDocRef, inputFrozen, firebaseAuth]
    );

    const updateTypingStatus = useCallback(
        (isTyping: boolean) => {
            if (!firestore || !conversation || inputFrozen || !typingDocRef) return;
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
        [firestore, conversation, inputFrozen, typingDocRef, flushTypingDocument]
    );

    useEffect(() => {
        return () => {
            if (typingThrottleTimerRef.current) clearTimeout(typingThrottleTimerRef.current);
            const uid = firebaseAuth.currentUser?.uid;
            if (typingDocRef && !inputFrozen && uid && typingDocRef.id === uid) {
                deleteDocumentNonBlocking(typingDocRef);
            }
        };
    }, [typingDocRef, inputFrozen, firebaseAuth]);

    const flushDraftToStorageForKey = useCallback(
        (scopeKey: string) => {
            const uid = currentUser.id;
            if (!uid || typeof window === 'undefined') return;
            if (editingMessageRef.current) return;
            const ed = editorInstance.current;
            const html = ed?.getHTML() ?? '';
            const plain = chatDraftPlainFromHtml(html);
            const reply = replyingToRef.current;
            if (!plain && !reply) {
                clearChatMessageDraft(uid, scopeKey);
                return;
            }
            saveChatMessageDraft(uid, scopeKey, {
                html,
                replyTo: reply,
                updatedAt: Date.now(),
            });
        },
        [currentUser.id]
    );

    useEffect(() => {
        const keyAtMount = draftKey;
        const onPageHide = () => flushDraftToStorageForKey(keyAtMount);
        window.addEventListener('pagehide', onPageHide);
        return () => {
            window.removeEventListener('pagehide', onPageHide);
            flushDraftToStorageForKey(keyAtMount);
        };
    }, [draftKey, flushDraftToStorageForKey]);

    useEffect(() => {
        if (editingMessage) return;
        let cancelled = false;
        const id = window.setInterval(() => {
            const ed = editorInstance.current;
            if (!ed || cancelled) return;
            window.clearInterval(id);
            const draft = getChatMessageDraft(currentUser.id, draftKey);
            if (!draft) return;
            const plain = chatDraftPlainFromHtml(draft.html);
            if (!plain && !draft.replyTo) return;
            ed.commands.setContent(draft.html?.trim() ? draft.html : '<p></p>');
            onRestoreDraftReplyRef.current?.(draft.replyTo ?? null);
            setHasContent(plain.length > 0);
        }, 24);
        const to = window.setTimeout(() => {
            cancelled = true;
            window.clearInterval(id);
        }, 4000);
        return () => {
            cancelled = true;
            window.clearInterval(id);
            window.clearTimeout(to);
        };
    }, [draftKey, currentUser.id, editingMessage]);

    const canScheduleNow = useCallback(() => {
        if (!onScheduleMessage || isSending || inputFrozen || editingMessage) return false;
        const editor = editorInstance.current;
        if (!editor) return false;
        const hasText = editor.getText().trim().length > 0;
        return hasText || attachments.length > 0 || !!videoPreview;
    }, [onScheduleMessage, isSending, inputFrozen, editingMessage, attachments, videoPreview]);

    const handleOpenScheduleDialog = useCallback(() => {
        if (!canScheduleNow()) return;
        setScheduleDialogOpen(true);
    }, [canScheduleNow]);

    const handleConfirmSchedule = async (sendAt: Date) => {
        const editor = editorInstance.current;
        if (!editor || !onScheduleMessage) return;
        const text = editor.getHTML();
        const hasText = editor.getText().trim().length > 0;
        if (!hasText && attachments.length === 0 && !videoPreview) return;

        const finalFiles = [...attachments];
        if (videoPreview) {
            const videoFile = new File([videoPreview.blob], `video-circle_${Date.now()}.webm`, { type: 'video/webm' });
            finalFiles.push(videoFile);
        }
        const currentReplyingTo = replyingTo;

        try {
            await onScheduleMessage(
                hasText ? text : undefined,
                finalFiles,
                currentReplyingTo,
                undefined,
                sendAt,
            );
            editor.commands.clearContent();
            setHasContent(false);
            setAttachments([]);
            setVideoPreview(null);
            setDetectedUrl(null);
            if (currentReplyingTo) onCancelReply();
            clearChatMessageDraft(currentUser.id, draftKey);
        } catch (e) {
            logger.error('composer', 'schedule message failed', e);
        }
    };

    const handleSendButtonPointerDown = (e: React.PointerEvent) => {
        if (!onScheduleMessage || e.button !== 0) return;
        longPressTriggeredRef.current = false;
        if (longPressTimerRef.current) clearTimeout(longPressTimerRef.current);
        longPressTimerRef.current = setTimeout(() => {
            if (canScheduleNow()) {
                longPressTriggeredRef.current = true;
                handleOpenScheduleDialog();
            }
        }, 450);
    };

    const handleSendButtonPointerUp = () => {
        if (longPressTimerRef.current) {
            clearTimeout(longPressTimerRef.current);
            longPressTimerRef.current = null;
        }
    };

    const handleSendButtonContextMenu = (e: React.MouseEvent) => {
        if (!onScheduleMessage) return;
        e.preventDefault();
        if (canScheduleNow()) handleOpenScheduleDialog();
    };

    const handleSend = async () => {
        const editor = editorInstance.current;
        if (isSending || inputFrozen || !editor) return;

        // long-press уже открыл диалог — не отправляем как обычное сообщение.
        if (longPressTriggeredRef.current) {
            longPressTriggeredRef.current = false;
            return;
        }

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
                const preparedFiles = [...finalFiles];
                if (currentVideoPreview) {
                    const videoFile = new File([currentVideoPreview.blob], `video-circle_${Date.now()}.webm`, { type: 'video/webm' });
                    preparedFiles.push(videoFile);
                }
                await onSendMessage(hasText ? text : undefined, preparedFiles, currentReplyingTo, undefined);
            }
            clearChatMessageDraft(currentUser.id, draftKey);
        } catch (error) {
            logger.error('composer', 'send message failed', error);
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

        if (inputFrozen) return;
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

    /** `applyKeyboardStickerHeuristic`: PNG/WebP/JPEG — только вставка с клавиатуры. HEIC/HEIF всегда проверяются на малый «стикерный» размер и при успехе конвертируются в PNG + `sticker_`. */
    const ingestAttachmentFiles = useCallback(async (raw: File[], applyKeyboardStickerHeuristic: boolean) => {
        if (!raw.length || inputFrozen) return;
        const next = await normalizeFilesAsStickersIfApplicable(raw, applyKeyboardStickerHeuristic);
        setAttachments((prev) => [...prev, ...next]);
    }, [inputFrozen]);

    useImperativeHandle(ref, () => ({
        addDraftFiles: (files: File[]) => {
            void ingestAttachmentFiles(files, false);
        },
    }), [ingestAttachmentFiles]);

    const handlePasteFiles = (files: File[]) => {
        void ingestAttachmentFiles(files, true);
    };

    const handleStartVideoRecording = async () => {
        if (inputFrozen) return;
        setIsAttachmentMenuOpen(false);
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
        } catch { toast({ variant: "destructive", title: t('chat.composer.cameraError') }); }
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
        if (!audioPreview || isSending || inputFrozen) return;
        const { file, url } = audioPreview;
        const currentReplyingTo = replyingTo;
        URL.revokeObjectURL(url);
        setAudioPreview(null);
        if (currentReplyingTo) onCancelReply();
        setIsSending(true);
        try {
            await onSendMessage(undefined, [file], currentReplyingTo, undefined);
        } catch (error) {
            logger.error('composer', 'send audio failed', error);
        } finally {
            setIsSending(false);
        }
    };

    const handleStartAudioRecording = async () => {
        if (inputFrozen) return;
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
        } catch {
            toast({ variant: "destructive", title: t('chat.composer.noMicAccess') });
        }
    };

    const handleStopAudioRecording = () => {
        if (audioTimerRef.current) {
            clearInterval(audioTimerRef.current);
            audioTimerRef.current = null;
        }
        const rec = audioRecorderRef.current;
        if (!rec || rec.state !== "recording") return;
        const durationAtStopSec = audioRecordingTime;
        rec.onstop = () => {
            audioStreamRef.current?.getTracks().forEach(t => t.stop());
            const mimeType = rec.mimeType || "audio/webm";
            const ext = mimeType.includes("mp4") ? "mp4" : "webm";
            const blob = new Blob(audioChunksRef.current, { type: mimeType });
            audioChunksRef.current = [];
            if (blob.size < 100) {
                setIsAudioRecording(false);
                setAudioRecordingTime(0);
                toast({ variant: "destructive", title: t('chat.composer.recordingTooShort') });
                return;
            }
            const url = URL.createObjectURL(blob);
            const file = new File([blob], `audio_${Date.now()}.${ext}`, { type: mimeType });
            setAudioPreview({ url, file });
            setIsAudioRecording(false);
            setAudioRecordingTime(0);
            // Analytics: voice_message_recorded — успешная остановка записи
            // (blob >= 100 байт, preview готов к отправке). Это не «sent» —
            // юзер ещё может отменить превью. Параметры: длительность по
            // bucket'ам + кодек.
            track(AnalyticsEvents.voiceMessageRecorded, {
                duration_bucket: durationBucket(durationAtStopSec * 1000),
                codec: mimeType.includes('mp4') ? 'mp4' : 'webm',
            });
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
                        <UserX className="h-4 w-4" /><p className="text-sm font-medium">{t('chat.composer.userDeleted')}</p>
                    </div>
                ) : composerLocked ? (
                    <div className="flex gap-3 rounded-2xl bg-muted/50 p-4 text-muted-foreground">
                        <Ban className="mt-0.5 h-4 w-4 shrink-0" aria-hidden />
                        <p className="text-sm font-medium leading-snug">
                          {composerLockedHint?.trim() || t('chat.composer.communicationUnavailable')}
                        </p>
                    </div>
                ) : isVideoRecording ? (
                    <div className="mb-2 flex flex-row items-center justify-center gap-3 sm:gap-4">
                        <div className="h-14 w-14 shrink-0" aria-hidden />
                        <div className="relative h-48 w-48 shrink-0 rounded-full overflow-hidden border-4 border-primary/20">
                            <video ref={videoPreviewRef} autoPlay muted playsInline className="pointer-events-none h-full w-full object-cover -scale-x-100" />
                        </div>
                        <Button type="button" variant="destructive" size="icon" className="h-14 w-14 shrink-0 rounded-full" onClick={stopVideoRecording} aria-label={t('chat.composer.stopRecording')}>
                            <StopCircle className="h-7 w-7" />
                        </Button>
                    </div>
                ) : videoPreview ? (
                    <div className="mb-2 flex flex-row items-center justify-center gap-3 sm:gap-4">
                        <Button
                            type="button"
                            variant="ghost"
                            size="icon"
                            className="h-14 w-14 shrink-0 rounded-full text-destructive hover:text-destructive hover:bg-destructive/10"
                            onClick={() => setVideoPreview(null)}
                            aria-label={t('chat.composer.deleteVideoCircle')}
                        >
                            <Trash2 className="h-7 w-7" />
                        </Button>
                        <div className="relative h-48 w-48 shrink-0 rounded-full overflow-hidden border-4 border-green-500/20 shadow-2xl">
                            <video src={videoPreview.url} autoPlay loop playsInline className="pointer-events-none h-full w-full object-cover" />
                        </div>
                        <Button type="button" size="icon" className="h-14 w-14 shrink-0 rounded-full bg-primary shadow-xl" onClick={handleSend} aria-label={t('chat.composer.send')}>
                            <SendHorizonal className="h-7 w-7" />
                        </Button>
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
                                            {replyingTo ? t('chat.composer.replyToUser') : t('chat.composer.editingMessage')}
                                        </p>
                                        <p className="text-xs text-muted-foreground truncate font-medium">
                                            {replyingTo ? (
                                                <><span className="font-bold text-foreground/80">{replyingTo.senderName}:</span> {replyingTo.text}</>
                                            ) : (
                                                editingMessage?.text?.replace(/<[^>]*>/g, '') || t('chat.composer.noText')
                                            )}
                                        </p>
                                    </div>
                                    {replyingTo?.mediaPreviewUrl && (
                                        <div
                                            className={cn(
                                                'ml-2 h-10 w-10 shrink-0 overflow-hidden rounded-lg border border-black/5',
                                                replyingTo.mediaType === 'sticker' ? 'bg-transparent' : 'bg-muted/30 dark:bg-black/20',
                                            )}
                                        >
                                            {replyingTo.mediaType === 'video' || replyingTo.mediaType === 'video-circle' ? (
                                                <video src={replyingTo.mediaPreviewUrl} className="pointer-events-none h-full w-full object-cover" muted playsInline />
                                            ) : (
                                                <img
                                                    src={replyingTo.mediaPreviewUrl}
                                                    className={cn(
                                                        'h-full w-full',
                                                        replyingTo.mediaType === 'sticker' ? 'object-contain p-1' : 'object-cover',
                                                    )}
                                                    alt=""
                                                />
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
                                    <span className="text-[10px] font-bold uppercase text-muted-foreground">{t('chat.composer.linkPreview')}</span>
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
                                                        <img src={attachmentPreviewUrls[idx] ?? ''} className="h-full w-full object-cover" alt="" />
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
                                        onOpenChange={setIsAttachmentMenuOpen}
                                    >
                                    <PopoverTrigger asChild>
                                      <Button variant="ghost" size="icon" className="h-9 w-9 shrink-0" disabled={inputFrozen}>
                                        <Paperclip className="h-4 w-4" />
                                      </Button>
                                    </PopoverTrigger>
                                        <PopoverContent
                                            className={cn(
                                                'w-64 p-2 rounded-2xl mb-1 text-popover-foreground',
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
                                        ) : (
                                            <div className="space-y-0.5">
                                                    <Button
                                                        variant="ghost"
                                                        onClick={() => {
                                                            setIsAttachmentMenuOpen(false);
                                                                                                                fileInputRef.current?.click();
                                                        }}
                                                        className="w-full justify-start rounded-xl h-11"
                                                    >
                                                        <FileIcon className="mr-3 h-4 w-4" />{t('chat.composer.file')}
                                                    </Button>
                                                    <Button
                                                        variant="ghost"
                                                        onClick={handleStartVideoRecording}
                                                        className="w-full justify-start rounded-xl h-11 hover:bg-white/25 dark:hover:bg-white/10 active:bg-white/35 dark:active:bg-white/15"
                                                    >
                                                        <Video className="mr-3 h-4 w-4 text-sky-600 dark:text-sky-400" />
                                                        {t('chat.composer.videoCircle')}
                                                    </Button>
                                                    {onSendLocationShare && (
                                                        <Button
                                                            variant="ghost"
                                                            type="button"
                                                            disabled={inputFrozen}
                                                            onClick={() => { setIsAttachmentMenuOpen(false); setLocationDialogOpen(true); }}
                                                            className="w-full justify-start rounded-xl h-11"
                                                        >
                                                            <MapPin className="mr-3 h-4 w-4 text-emerald-600" />
                                                            {t('chat.composer.location')}
                                                        </Button>
                                                    )}
                                                    {onSendPoll && (
                                                        <Button
                                                            variant="ghost"
                                                            type="button"
                                                            disabled={inputFrozen}
                                                            onClick={() => { setIsAttachmentMenuOpen(false); setPollDialogOpen(true); }}
                                                            className="w-full justify-start rounded-xl h-11"
                                                        >
                                                            <BarChart3 className="mr-3 h-4 w-4 text-violet-600" />
                                                            {t('chat.composer.poll')}
                                                        </Button>
                                                    )}
                                                <Separator className="my-1" />
                                                <Button variant="ghost" onClick={() => setShowFormatting(true)} className="w-full justify-start rounded-xl h-11"><Type className="mr-3 h-4 w-4" />{t('chat.composer.format')}</Button>
                                            </div>
                                        )}
                                    </PopoverContent>
                                </Popover>
                                
                                    <ComposerStickerGifPopover
                                        userId={currentUser.id}
                                        editorRef={editorInstance}
                                        disabled={inputFrozen}
                                        onPickStickerAttachment={(att) => {
                                            void onSendMessage(undefined, [], replyingTo, [att]);
                                        }}
                                        onPickGifAttachment={(att) => {
                                            void onSendMessage(undefined, [], replyingTo, [att]);
                                        }}
                                    />

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
                                    {inputFrozen ? (
                                      <div className="pointer-events-none absolute inset-0 rounded-[1.25rem] bg-muted/20" aria-hidden />
                                    ) : null}
                                    </div>

                                    {(hasContent || attachments.length > 0 || editingMessage) ? (
                                        <Button
                                            type="button"
                                            size="icon"
                                            className="h-9 w-9 shrink-0 rounded-full bg-primary text-primary-foreground hover:bg-primary/90 shadow-sm"
                                            onClick={handleSend}
                                            onPointerDown={handleSendButtonPointerDown}
                                            onPointerUp={handleSendButtonPointerUp}
                                            onPointerLeave={handleSendButtonPointerUp}
                                            onContextMenu={handleSendButtonContextMenu}
                                            disabled={isSending || inputFrozen}
                                            title={onScheduleMessage && !editingMessage ? t('chat.composer.sendHoldToSchedule') : undefined}
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
                                            disabled={inputFrozen}
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
                tabIndex={-1}
                className="hidden"
                onChange={(e) => {
                    if (!e.target.files?.length) return;
                    const list = Array.from(e.target.files);
                    void ingestAttachmentFiles(list, false);
                    setIsAttachmentMenuOpen(false);
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
            {onScheduleMessage && (
                <ChatScheduleMessageDialog
                    open={scheduleDialogOpen}
                    onOpenChange={setScheduleDialogOpen}
                    showE2eeWarning={e2eeEnabled}
                    onConfirm={handleConfirmSchedule}
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
    /**
     * Запланировать сообщение на дату/время (long-press на send-кнопке).
     * Если пропс не передан — long-press отключён.
     */
    onScheduleMessage?: (
        text: string | undefined,
        attachments: File[],
        replyTo: ReplyContext | null,
        prebuiltAttachments: ChatAttachment[] | undefined,
        sendAt: Date,
    ) => Promise<void>;
    onUpdateMessage: (id: string, text: string, attachments?: ChatAttachment[]) => Promise<void>;
    replyingTo: ReplyContext | null;
    onCancelReply: () => void;
    /** Черновик редактирования — только поля, нужные композеру (совпадает с состоянием чата/треда). */
    editingMessage: { id: string; text: string; attachments?: ChatAttachment[] } | null;
    onCancelEdit: () => void;
    conversation: Conversation;
    currentUser: User;
    allUsers: User[];
    /** Локальные имена контактов текущего пользователя для @-подсказок. */
    contactProfiles?: Record<string, UserContactLocalProfile>;
    isPartnerDeleted?: boolean;
    /** Личный чат: блокировка (взаимная или односторонняя) — как «удалён», но с отдельным текстом. */
    composerLocked?: boolean;
    composerLockedHint?: string;
    /** Ключ в localStorage; по умолчанию `conversation.id`. Для треда: `t:{conversationId}:{parentMessageId}`. */
    draftScopeKey?: string;
    /** Восстановить «Ответ» из черновика при открытии чата. */
    onRestoreDraftReply?: (reply: ReplyContext | null) => void;
    /** В E2EE-чате диалог планирования покажет предупреждение про plaintext. */
    e2eeEnabled?: boolean;
}
