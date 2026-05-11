'use client';
import { useI18n } from '@/hooks/use-i18n';

import type { User, Conversation, ChatMessage, UserRole, UserContactsIndex } from '@/lib/types';
import { ROLES } from '@/lib/constants';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetDescription, SheetClose } from '@/components/ui/sheet';
import { Image as ImageIcon, X, ArrowLeft, Users, Edit, Mail, ShieldCheck, Cake, LogOut, MessageSquare, Smartphone, UserRound, MapPin, UserPlus, ChevronDown, Share2, Star, Bell, Palette, History, Shield, PlusCircle, Video, Phone, Ban, Unlock, Swords, LockKeyhole, Flag } from 'lucide-react';
import { useMemo, useState, useRef, useEffect, useCallback } from 'react';
import { GroupChatFormPanel } from '@/components/chat/GroupChatFormPanel';
import { GroupChatParticipantsManageView } from '@/components/chat/GroupChatParticipantsManageView';
import { Button } from '../ui/button';
import { cn } from '@/lib/utils';
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from '@/components/ui/collapsible';
import { Badge } from '../ui/badge';
import { useRouter } from 'next/navigation';
import { Dialog, DialogContent, DialogTrigger, DialogClose, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog";
import { useDoc, useFirestore, useMemoFirebase } from '@/firebase';
import { doc, getDoc, setDoc, updateDoc, arrayUnion, arrayRemove } from 'firebase/firestore';
import { formatPhoneNumberForDisplay } from '@/lib/phone-utils';
import { isProfileFieldVisibleToOthers } from '@/lib/profile-field-visibility';
import { isSavedMessagesChat } from '@/lib/saved-messages-chat';
import { isLiveShareVisible } from '@/lib/live-location-utils';
import { resolveContactDisplayName } from '@/lib/contact-display-name';
import { LiveLocationMapDialog } from '@/components/location/LiveLocationMapDialog';
import { useToast } from '@/hooks/use-toast';
import { canStartDirectChat } from '@/lib/user-chat-policy';
import { categorizeAttachmentsFromMessages } from '@/lib/chat-attachments-from-messages';
import { useStarredInConversation } from '@/hooks/use-starred-in-conversation';
import { useChatConversationPrefs } from '@/hooks/use-chat-conversation-prefs';
import { useSettings } from '@/hooks/use-settings';
import { buildDashboardChatOpenUrl } from '@/lib/dashboard-conversation-url';
import { createOrOpenDirectChat } from '@/lib/direct-chat';
import { autoEnableE2eeForNewDirectChat } from '@/lib/e2ee';
import { initiateCall } from '@/components/chat/AudioCallOverlay';
import { resolvePresenceLabel } from '@/lib/presence-visibility';
import {
  WA_PROFILE_BG,
  WA_PROFILE_MUTED,
  WA_CONVERSATION_UTILITY_SHEET_CONTENT_CLASS,
  WaQuickActionButton,
  WaQuickActionRow,
  WaMenuSection,
  WaMenuRow,
  WaFooterCaption,
} from '@/components/chat/profile/ParticipantProfileWhatsAppLayout';
import { ConversationMediaPanel } from '@/components/chat/conversation-pages/ConversationMediaPanel';
import { ConversationStarredPanel } from '@/components/chat/conversation-pages/ConversationStarredPanel';
import { ConversationThreadsPanel } from '@/components/chat/conversation-pages/ConversationThreadsPanel';
import { ConversationGamesPanel } from '@/components/chat/conversation-pages/ConversationGamesPanel';
import { ConversationNotificationsPanel } from '@/components/chat/conversation-pages/ConversationNotificationsPanel';
import { ConversationThemePanel } from '@/components/chat/conversation-pages/ConversationThemePanel';
import { ConversationPrivacyPanel } from '@/components/chat/conversation-pages/ConversationPrivacyPanel';
import { ConversationEncryptionPanel } from '@/components/chat/conversation-pages/ConversationEncryptionPanel';
import { ConversationDisappearingMessagesPanel } from '@/components/chat/conversation-pages/ConversationDisappearingMessagesPanel';
import { formatDisappearingTtlSummary } from '@/lib/disappearing-messages-presets';
import { LeaveGroupPanel } from '@/components/chat/conversation-pages/LeaveGroupPanel';
import { normalizeBlockedUserIds } from '@/lib/user-block-utils';
import { SecretChatComposeDialog } from '@/components/chat/SecretChatComposeDialog';
import { SecretChatSettingsDialog } from '@/components/chat/SecretChatSettingsDialog';
import { ReportMessageDialog } from '@/components/chat/report-message-dialog';
import { buildSecretDirectConversationId } from '@/lib/secret-chat/secret-chat-create';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog';

export type ChatProfileSubMenu =
  | 'media'
  | 'starred'
  | 'threads'
  | 'games'
  | 'notifications'
  | 'theme'
  | 'privacy'
  | 'encryption'
  | 'disappearing'
  | 'leave';

export type ChatProfileSource = 'contacts' | 'mention' | 'sender' | 'chat';

const PROFILE_SUBMENU_KEYS: Record<ChatProfileSubMenu, string> = {
  media: 'chat.profile.mediaLinksFiles',
  starred: 'chat.profile.starred',
  threads: 'chat.profile.discussions',
  games: 'chat.profile.games',
  notifications: 'chat.profile.notificationsInChat',
  theme: 'chat.profile.chatTheme',
  privacy: 'chat.profile.chatPrivacy',
  encryption: 'chat.profile.encryptionLabel',
  disappearing: 'chat.profile.disappearingMessages',
  leave: 'chat.profile.leaveGroup',
};

interface ChatParticipantProfileProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  conversation: Conversation;
  allUsers: User[];
  currentUser: User;
  messages: ChatMessage[];
  onSelectConversation: (conversationId: string) => void;
  /** В группе: показать шапку и поля выбранного участника (клик по @). */
  focusUserId?: string | null;
  onClearProfileFocus?: () => void;
  /** Программно открыть конкретный подраздел профиля (например, "Обсуждения" из шапки чата). */
  initialSubMenu?: ChatProfileSubMenu | null;
  onInitialSubMenuConsumed?: () => void;
  profileSource?: ChatProfileSource;
}

export function ChatParticipantProfile({ 
    open, 
    onOpenChange, 
    conversation, 
    allUsers, 
    currentUser, 
    messages, 
    onSelectConversation, 
    focusUserId = null,
    onClearProfileFocus,
    initialSubMenu = null,
    onInitialSubMenuConsumed,
    profileSource = 'chat',
}: ChatParticipantProfileProps) {
  const { t } = useI18n();
  type GroupProfileLayer = 'main' | 'participants' | 'edit';
  const [groupProfileLayer, setGroupProfileLayer] = useState<GroupProfileLayer>('main');
  const [liveMapOpen, setLiveMapOpen] = useState(false);
  const [profileSubMenu, setProfileSubMenu] = useState<ChatProfileSubMenu | null>(null);
  const [quickActionBusy, setQuickActionBusy] = useState<string | null>(null);
  const [blockDialogOpen, setBlockDialogOpen] = useState(false);
  const [unblockDialogOpen, setUnblockDialogOpen] = useState(false);
  const [blockBusy, setBlockBusy] = useState(false);
  const [reportDialogOpen, setReportDialogOpen] = useState(false);
  const [secretComposePeer, setSecretComposePeer] = useState<User | null>(null);
  const [secretSettingsOpen, setSecretSettingsOpen] = useState(false);
  const router = useRouter();
  const firestore = useFirestore();
  const { starredCount } = useStarredInConversation(currentUser.id, conversation.id);
  const { prefs: conversationPrefs, updatePrefs } = useChatConversationPrefs(currentUser.id, conversation.id);
  const { privacySettings } = useSettings();
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
  
  const {
    data: freshParticipant,
    error: profileParticipantError,
    isLoading: profileParticipantLoading,
  } = useDoc<User>(participantRef);

  const selfUserRef = useMemoFirebase(
    () => (firestore && currentUser?.id ? doc(firestore, 'users', currentUser.id) : null),
    [firestore, currentUser?.id]
  );
  const { data: selfLive } = useDoc<User>(selfUserRef);

  const myBlockedIds = useMemo(
    () => normalizeBlockedUserIds(selfLive?.blockedUserIds ?? currentUser.blockedUserIds),
    [selfLive?.blockedUserIds, currentUser.blockedUserIds]
  );

  const partnerDocDenied = Boolean(
    profileDocId &&
      profileDocId !== currentUser.id &&
      profileParticipantError &&
      !profileParticipantLoading
  );

  const effectiveCurrentUser = useMemo(
    (): User => ({ ...currentUser, blockedUserIds: myBlockedIds }),
    [currentUser, myBlockedIds]
  );

  const showBlockUserRow = Boolean(
    profileDocId &&
      profileDocId !== currentUser.id &&
      !isSelfSavedChat &&
      (!isGroup || showMemberFocus)
  );

  const isPartnerBlockedByMe = Boolean(profileDocId && myBlockedIds.includes(profileDocId));

  const userContactsRef = useMemoFirebase(
    () => (firestore && currentUser?.id ? doc(firestore, 'userContacts', currentUser.id) : null),
    [firestore, currentUser?.id]
  );
  const { data: contactsIndex } = useDoc<UserContactsIndex>(userContactsRef);
  const contactIds = contactsIndex?.contactIds ?? [];
  const isContact = Boolean(profileDocId && contactIds.includes(profileDocId));

  const handleSheetOpenChange = useCallback(
    (next: boolean) => {
      if (!next) {
        setGroupProfileLayer('main');
        setProfileSubMenu(null);
      }
      onOpenChange(next);
    },
    [onOpenChange]
  );

  useEffect(() => {
    if (!open) setGroupProfileLayer('main');
  }, [open]);

  useEffect(() => {
    if (focusUserId) setGroupProfileLayer('main');
  }, [focusUserId]);

  useEffect(() => {
    if (!open) setProfileSubMenu(null);
  }, [open]);

  useEffect(() => {
    if (!open || !initialSubMenu) return;
    setGroupProfileLayer('main');
    setProfileSubMenu(initialSubMenu);
    onInitialSubMenuConsumed?.();
  }, [open, initialSubMenu, onInitialSubMenuConsumed]);

  useEffect(() => {
    if (groupProfileLayer !== 'main') setProfileSubMenu(null);
  }, [groupProfileLayer]);

  useEffect(() => {
    setProfileSubMenu(null);
  }, [focusUserId]);

  const closeProfileSubMenu = useCallback(() => setProfileSubMenu(null), []);

  const openStarredMessageFromProfile = useCallback(
    (messageId: string) => {
      router.push(buildDashboardChatOpenUrl(conversation.id, { focusMessageId: messageId }));
      handleSheetOpenChange(false);
    },
    [router, conversation.id, handleSheetOpenChange]
  );

  const afterThreadOpenFromProfile = useCallback(() => {
    handleSheetOpenChange(false);
  }, [handleSheetOpenChange]);

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
      name: info?.name || t('chat.userLabel'),
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
    if (partnerDocDenied) return false;
    if (!contactTargetUser || contactTargetUser.deletedAt) return false;
    if (isContact) return true;
    return canStartDirectChat(effectiveCurrentUser, contactTargetUser);
  }, [
    profileDocId,
    effectiveCurrentUser,
    isSelfSavedChat,
    contactTargetUser,
    isContact,
    isGroup,
    showMemberFocus,
    partnerDocDenied,
  ]);
  const { toast } = useToast();

  const canRunDirectQuickActions = useMemo(() => {
    if (!profileDocId || profileDocId === currentUser.id || isSelfSavedChat) return false;
    if (isGroup && !showMemberFocus) return false;
    if (partnerDocDenied) return false;
    if (!contactTargetUser || contactTargetUser.deletedAt) return false;
    return canStartDirectChat(effectiveCurrentUser, contactTargetUser);
  }, [
    profileDocId,
    effectiveCurrentUser,
    isSelfSavedChat,
    isGroup,
    showMemberFocus,
    contactTargetUser,
    partnerDocDenied,
  ]);

  const showChatsQuickAction = profileSource === 'contacts' && canRunDirectQuickActions;

  const currentDirectConversationId = useMemo(() => {
    if (isGroup || isSelfSavedChat) return null;
    if (!profileDocId || profileDocId !== otherId) return null;
    return conversation.id;
  }, [isGroup, isSelfSavedChat, profileDocId, otherId, conversation.id]);

  const muteInCurrentDirect = currentDirectConversationId === conversation.id
    ? conversationPrefs?.notificationsMuted === true
    : false;

  const ensureDirectConversationForProfile = useCallback(async (): Promise<{ id: string; target: User } | null> => {
    if (!firestore || !profileDocId || !contactTargetUser) return null;
    if (partnerDocDenied) return null;
    if (!canStartDirectChat(effectiveCurrentUser, contactTargetUser)) return null;
    if (!isGroup && !isSelfSavedChat && profileDocId === otherId) {
      return { id: conversation.id, target: contactTargetUser };
    }
    const id = await createOrOpenDirectChat(firestore, effectiveCurrentUser, contactTargetUser);
    let platformWants = false;
    try {
      const ps = await getDoc(doc(firestore, 'platformSettings', 'main'));
      const p = ps.data() as { e2eeDefaultForNewDirectChats?: boolean } | undefined;
      platformWants = !!p?.e2eeDefaultForNewDirectChats;
    } catch {
      /* ignore */
    }
    await autoEnableE2eeForNewDirectChat(firestore, id, effectiveCurrentUser.id, {
      userWants: privacySettings.e2eeForNewDirectChats === true,
      platformWants,
    });
    return { id, target: contactTargetUser };
  }, [
    firestore,
    profileDocId,
    contactTargetUser,
    effectiveCurrentUser,
    partnerDocDenied,
    isGroup,
    isSelfSavedChat,
    otherId,
    conversation.id,
    privacySettings.e2eeForNewDirectChats,
  ]);

  const handleConfirmBlockUser = useCallback(async () => {
    if (!firestore || !profileDocId || blockBusy) return;
    setBlockBusy(true);
    try {
      await updateDoc(doc(firestore, 'users', currentUser.id), {
        blockedUserIds: arrayUnion(profileDocId),
      });
      toast({ title: t('chat.profile.blocked') });
      setBlockDialogOpen(false);
    } catch (e) {
      console.error('[ChatParticipantProfile] block user', e);
      toast({ variant: 'destructive', title: t('chat.profile.blockFailed') });
    } finally {
      setBlockBusy(false);
    }
  }, [firestore, profileDocId, blockBusy, currentUser.id, toast]);

  const handleConfirmUnblockUser = useCallback(async () => {
    if (!firestore || !profileDocId || blockBusy) return;
    setBlockBusy(true);
    try {
      await updateDoc(doc(firestore, 'users', currentUser.id), {
        blockedUserIds: arrayRemove(profileDocId),
      });
      toast({ title: t('chat.profile.unblocked') });
      setUnblockDialogOpen(false);
    } catch (e) {
      console.error('[ChatParticipantProfile] unblock user', e);
      toast({ variant: 'destructive', title: t('chat.profile.unblockFailed') });
    } finally {
      setBlockBusy(false);
    }
  }, [firestore, profileDocId, blockBusy, currentUser.id, toast]);

  const openDirectChatFromProfile = useCallback(async () => {
    if (quickActionBusy || !canRunDirectQuickActions) return;
    setQuickActionBusy('chat');
    try {
      const direct = await ensureDirectConversationForProfile();
      if (!direct) return;
      onSelectConversation(direct.id);
      handleSheetOpenChange(false);
    } catch (e) {
      console.error('[ChatParticipantProfile] openDirectChatFromProfile failed', e);
      toast({ title: t('chat.profile.openChatFailed'), variant: 'destructive' });
    } finally {
      setQuickActionBusy(null);
    }
  }, [
    quickActionBusy,
    canRunDirectQuickActions,
    ensureDirectConversationForProfile,
    onSelectConversation,
    handleSheetOpenChange,
    toast,
  ]);

  const startDirectCallFromProfile = useCallback(async (video: boolean) => {
    if (quickActionBusy || !canRunDirectQuickActions || !firestore) return;
    setQuickActionBusy(video ? 'video' : 'call');
    try {
      const direct = await ensureDirectConversationForProfile();
      if (!direct) return;
      onSelectConversation(direct.id);
      initiateCall(firestore, effectiveCurrentUser, direct.target, video, toast);
      handleSheetOpenChange(false);
    } catch (e) {
      console.error('[ChatParticipantProfile] startDirectCallFromProfile failed', e);
      toast({ title: t('chat.profile.startCallFailed'), variant: 'destructive' });
    } finally {
      setQuickActionBusy(null);
    }
  }, [
    quickActionBusy,
    canRunDirectQuickActions,
    firestore,
    ensureDirectConversationForProfile,
    onSelectConversation,
    effectiveCurrentUser,
    toast,
    handleSheetOpenChange,
  ]);

  const toggleDirectNotificationsFromProfile = useCallback(async () => {
    if (quickActionBusy || !canRunDirectQuickActions || !firestore) return;
    setQuickActionBusy('mute');
    try {
      const direct = await ensureDirectConversationForProfile();
      if (!direct) return;
      if (direct.id === conversation.id) {
        const next = !(conversationPrefs?.notificationsMuted === true);
        updatePrefs({ notificationsMuted: next });
        toast({
          title: next ? t('chat.profile.notificationsMuted') : t('chat.profile.notificationsEnabled'),
        });
      } else {
        const prefsRef = doc(firestore, 'users', currentUser.id, 'chatConversationPrefs', direct.id);
        const snap = await getDoc(prefsRef);
        const currentMuted = !!(snap.data() as { notificationsMuted?: boolean } | undefined)?.notificationsMuted;
        const next = !currentMuted;
        await setDoc(
          prefsRef,
          {
            conversationId: direct.id,
            notificationsMuted: next,
            updatedAt: new Date().toISOString(),
          },
          { merge: true }
        );
        onSelectConversation(direct.id);
        toast({
          title: next ? t('chat.profile.notificationsMuted') : t('chat.profile.notificationsEnabled'),
        });
      }
    } catch (e) {
      console.error('[ChatParticipantProfile] toggleDirectNotificationsFromProfile failed', e);
      toast({ title: t('chat.profile.notificationsChangeFailed'), variant: 'destructive' });
    } finally {
      setQuickActionBusy(null);
    }
  }, [
    quickActionBusy,
    canRunDirectQuickActions,
    firestore,
    ensureDirectConversationForProfile,
    conversation.id,
    conversationPrefs?.notificationsMuted,
    updatePrefs,
    currentUser.id,
    onSelectConversation,
    toast,
  ]);

  const handleOpenContactEditor = useCallback(() => {
    if (!profileDocId || !contactTargetUser) return;
    const encodedId = encodeURIComponent(profileDocId);
    handleSheetOpenChange(false);
    router.push(`/dashboard/contacts/${encodedId}/edit`);
  }, [profileDocId, contactTargetUser, handleSheetOpenChange, router]);

  const displayParticipantInfo = useMemo(() => {
    if (!profileDocId) return null;
    const info = conversation.participantInfo[profileDocId];
    const fallbackName = freshParticipant?.name || info?.name || t('chat.userLabel');
    const resolvedName = resolveContactDisplayName(
      contactsIndex?.contactProfiles,
      profileDocId,
      fallbackName
    );
    return {
      name: resolvedName,
      avatar: freshParticipant?.avatar || info?.avatar || '',
      email: freshParticipant?.email || '',
      phone: freshParticipant?.phone || '',
      bio: freshParticipant?.bio || '',
      role: freshParticipant?.role || '',
      online: freshParticipant?.online || false,
      lastSeen: freshParticipant?.lastSeen || '',
      showOnlineStatus: freshParticipant?.privacySettings?.showOnlineStatus !== false,
      showLastSeen: freshParticipant?.privacySettings?.showLastSeen !== false,
      dateOfBirth: freshParticipant?.dateOfBirth || null,
      deletedAt: freshParticipant?.deletedAt || null
    };
  }, [profileDocId, conversation.participantInfo, freshParticipant, contactsIndex?.contactProfiles]);

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

  const { media, files, links, threadMessages } = useMemo(
    () => categorizeAttachmentsFromMessages(messages),
    [messages]
  );

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
        handleSheetOpenChange(false);
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
          ? conversation.name || t('chatList.previewSavedMessages')
          : displayParticipantInfo?.name || t('chat.chatLabel');
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
    return resolvePresenceLabel({
      online: displayParticipantInfo.online,
      lastSeen: displayParticipantInfo.lastSeen,
      privacySettings: {
        showOnlineStatus: displayParticipantInfo.showOnlineStatus,
        showLastSeen: displayParticipantInfo.showLastSeen,
      },
    });
  }, [isGroup, showMemberFocus, displayParticipantInfo, isPartnerDeleted]);
  
  const currentDescription = showMemberFocus
    ? statusText
    : isGroup
    ? conversation.description || `${conversation.participantIds.length} ${t('chat.profile.participantsCount')}` 
      : isSelfSavedChat
        ? t('chat.profile.savedNotesHint')
    : statusText;

  const groupParticipantCount = useMemo(
    () => new Set(conversation.participantIds).size,
    [conversation.participantIds]
  );

  const allUsersForGroupForm = useMemo(
    () => allUsers.filter((u) => u.id !== currentUser.id && !u.deletedAt),
    [allUsers, currentUser.id]
  );

  const handleQuickShare = useCallback(async () => {
    try {
      if (typeof navigator !== 'undefined' && navigator.share) {
        await navigator.share({
          title: name || 'LighChat',
          text: name ? `${name} — LighChat` : 'LighChat',
          url: window.location.href,
        });
      } else {
        await navigator.clipboard.writeText(window.location.href);
        toast({ title: t('chat.profile.chatLinkCopied') });
      }
    } catch {
      toast({ title: t('chat.profile.shareFailed'), variant: 'destructive' });
    }
  }, [name, toast]);

  const mediaDocsCount = media.length + files.length + links.length;
  const mediaDocsLabel = mediaDocsCount === 0 ? t('chat.profile.none') : String(mediaDocsCount);

  /** Раньше при наличии username показывали только ~nick — строка «последний вход» пропадала. */
  const profileHeaderSubtitles = useMemo(() => {
    if (isGroup && !showMemberFocus) {
      return { line1: currentDescription, line2: null as string | null };
    }
    const u = freshParticipant?.username?.trim();
    if (u) {
      const second = currentDescription?.trim() ? currentDescription : null;
      return { line1: `~${u}`, line2: second };
    }
    return { line1: currentDescription, line2: null };
  }, [isGroup, showMemberFocus, currentDescription, freshParticipant?.username]);

  const discussionsCount = threadMessages.length;
  const discussionsLabel = discussionsCount === 0 ? t('chat.profile.none') : String(discussionsCount);
  const starredLabel = starredCount === 0 ? t('chat.profile.none') : String(starredCount);
  const privacySummaryLabel =
    conversationPrefs?.suppressReadReceipts === true ? t('chat.profile.customSettings') : t('chat.profile.defaultSettings');

  const showEncryptionMenuRow = !isGroup && !isSelfSavedChat;
  /** Личный чат или основной профиль группы (не карточка участника). */
  const showDisappearingMessagesRow =
    !isSelfSavedChat &&
    conversation.secretChat?.enabled !== true &&
    (!isGroup || (isGroup && !showMemberFocus));
  const isSecretConversation = conversation.secretChat?.enabled === true;
  const e2eeSummaryOn = !!(conversation.e2eeEnabled && (conversation.e2eeKeyEpoch ?? 0) > 0);
  const encryptionSummaryLabel = e2eeSummaryOn ? t('chat.profile.on') : t('chat.profile.off');
  const encryptionRowDescription = e2eeSummaryOn
    ? t('chat.profile.encryptionOnHint')
    : t('chat.profile.encryptionOffHint');

  if (!open) return null;
  
  return (
    <Sheet open={open} onOpenChange={handleSheetOpenChange}>
      <SheetContent className={cn(WA_CONVERSATION_UTILITY_SHEET_CONTENT_CLASS)} side="right" showCloseButton={false}>
        <SheetHeader className="sr-only">
            <SheetTitle>{name}</SheetTitle>
            <SheetDescription>{t('chat.profile.sheetDescription')}</SheetDescription>
        </SheetHeader>
        {isGroup && groupProfileLayer === 'participants' ? (
          <GroupChatParticipantsManageView
            conversation={conversation}
            allUsers={allUsers}
            currentUser={currentUser}
            isGroupAdmin={isAdmin}
            onBack={() => setGroupProfileLayer('main')}
            onSelectPersonalChat={onSelectConversation}
            onCloseProfileSheet={() => handleSheetOpenChange(false)}
          />
        ) : isGroup && groupProfileLayer === 'edit' && isAdmin ? (
          <div className="flex min-h-0 flex-1 flex-col overflow-hidden">
            <GroupChatFormPanel
              open
              toolbar={
                <div className="flex items-center gap-3 px-3 py-3">
                  <Button
                    type="button"
                    variant="ghost"
                    size="icon"
                    className="shrink-0 rounded-full"
                    onClick={() => setGroupProfileLayer('main')}
                    aria-label={t('chat.profile.backToGroupProfile')}
                  >
                    <ArrowLeft className="h-5 w-5" />
                  </Button>
                  <div className="min-w-0">
                    <p className="truncate font-bold leading-tight">{t('chat.profile.editGroup')}</p>
                    <p className="truncate text-xs text-muted-foreground">{conversation.name}</p>
                  </div>
                </div>
              }
              allUsers={allUsersForGroupForm}
              contactIds={contactIds}
              currentUser={currentUser}
              initialData={conversation}
              onCancel={() => setGroupProfileLayer('main')}
              onGroupCreated={() => {}}
              onEditSaved={() => setGroupProfileLayer('main')}
            />
          </div>
        ) : profileSubMenu ? (
          <div className="flex min-h-0 flex-1 flex-col overflow-hidden">
            <div
              className={cn(
                'flex shrink-0 items-center gap-2 px-2 py-3 pt-[max(0.5rem,env(safe-area-inset-top))]',
                WA_PROFILE_BG,
              )}
              onTouchStart={handleTouchStart}
              onTouchEnd={handleTouchEnd}
            >
              <Button
                type="button"
                variant="ghost"
                size="icon"
                className="shrink-0 rounded-full text-foreground hover:bg-muted"
                onClick={closeProfileSubMenu}
                aria-label={t('chat.profile.backToProfile')}
              >
                <ArrowLeft className="h-5 w-5" />
              </Button>
              <h2 className="min-w-0 flex-1 truncate text-base font-semibold text-foreground">
                {t(PROFILE_SUBMENU_KEYS[profileSubMenu])}
              </h2>
            </div>
            <div
              className="min-h-0 flex-1 basis-0 overflow-y-auto overscroll-y-contain touch-pan-y"
              style={{ WebkitOverflowScrolling: 'touch' }}
            >
              <div
                className={cn(
                  'pb-[max(2.5rem,env(safe-area-inset-bottom))]',
                  profileSubMenu === 'media' ? 'px-0 pt-0' : 'p-4',
                )}
              >
                {profileSubMenu === 'media' ? (
                  <ConversationMediaPanel
                    conversationId={conversation.id}
                    currentUser={currentUser}
                    allUsers={allUsers}
                    allowForward={conversation.secretChat?.restrictions?.noForward !== true}
                    allowSave={conversation.secretChat?.restrictions?.noSave !== true}
                  />
                ) : null}
                {profileSubMenu === 'starred' ? (
                  <ConversationStarredPanel
                    conversationId={conversation.id}
                    userId={currentUser.id}
                    onOpenStarredMessage={openStarredMessageFromProfile}
                  />
                ) : null}
                {profileSubMenu === 'threads' ? (
                  <ConversationThreadsPanel
                    conversationId={conversation.id}
                    currentUser={currentUser}
                    allUsers={allUsers}
                    onAfterThreadNavigate={afterThreadOpenFromProfile}
                  />
                ) : null}
                {profileSubMenu === 'games' ? (
                  <ConversationGamesPanel
                    conversationId={conversation.id}
                    allUsers={allUsers}
                    isGroup={isGroup}
                    onCreatedGameLobby={(gameId) => {
                      onSelectConversation(conversation.id);
                      const url = `/games/durak/${encodeURIComponent(gameId)}`;
                      if (typeof window !== 'undefined') {
                        const popup = window.open(url, `durak_${gameId}`, 'popup=yes,width=980,height=760,resizable=yes,scrollbars=no');
                        if (!popup) router.push(url);
                      } else {
                        router.push(url);
                      }
                      onOpenChange(false);
                    }}
                  />
                ) : null}
                {profileSubMenu === 'notifications' ? (
                  <ConversationNotificationsPanel conversationId={conversation.id} userId={currentUser.id} />
                ) : null}
                {profileSubMenu === 'theme' ? (
                  <ConversationThemePanel conversationId={conversation.id} userId={currentUser.id} />
                ) : null}
                {profileSubMenu === 'privacy' ? (
                  <ConversationPrivacyPanel conversationId={conversation.id} userId={currentUser.id} />
                ) : null}
                {profileSubMenu === 'encryption' ? (
                  <ConversationEncryptionPanel conversation={conversation} currentUserId={currentUser.id} />
                ) : null}
                {profileSubMenu === 'disappearing' ? (
                  <ConversationDisappearingMessagesPanel
                    conversation={conversation}
                    currentUserId={currentUser.id}
                    canEdit={!isGroup || isAdmin}
                  />
                ) : null}
                {profileSubMenu === 'leave' && isGroup && !showMemberFocus ? (
                  <LeaveGroupPanel
                    conversationId={conversation.id}
                    currentUser={currentUser}
                    onCancel={closeProfileSubMenu}
                  />
                ) : null}
              </div>
            </div>
          </div>
        ) : (
          <div
            className="min-h-0 flex-1 basis-0 overflow-y-auto overscroll-y-contain touch-pan-y"
            style={{ WebkitOverflowScrolling: 'touch' }}
          >
          <div
            className={cn(
              WA_PROFILE_BG,
              'pb-[max(1.5rem,env(safe-area-inset-bottom))]',
            )}
          >
            <div
              className={cn(
                'sticky top-0 z-20 flex items-center gap-0.5 px-2 pb-3 pt-[max(0.5rem,env(safe-area-inset-top))]',
                WA_PROFILE_BG,
              )}
              onTouchStart={handleTouchStart}
              onTouchEnd={handleTouchEnd}
            >
              {showMemberFocus && onClearProfileFocus ? (
                <Button
                  type="button"
                  variant="ghost"
                  size="icon"
                  className="rounded-full text-foreground hover:bg-muted"
                  onClick={() => onClearProfileFocus()}
                  aria-label={t('chat.profile.backToGroup')}
                >
                  <ArrowLeft className="h-5 w-5" />
                </Button>
              ) : (
                <SheetClose asChild>
                  <Button variant="ghost" size="icon" className="rounded-full text-foreground hover:bg-muted" aria-label={t('common.close')}>
                    <ArrowLeft className="h-5 w-5" />
                  </Button>
                </SheetClose>
              )}
              <Button
                type="button"
                variant="ghost"
                size="icon"
                className="h-9 w-9 shrink-0 rounded-full text-emerald-500 hover:bg-muted hover:text-emerald-400"
                aria-label={t('chat.profile.share')}
                onClick={() => void handleQuickShare()}
              >
                <Share2 className="h-[18px] w-[18px]" strokeWidth={2} />
              </Button>
                    </div>

            <div className="flex flex-col items-center px-4 pb-2 pt-4 text-center">
              <div className="relative mx-auto w-fit">
                <Dialog>
                  <DialogTrigger asChild disabled={!avatar}>
                    <button
                      type="button"
                      className="relative rounded-full focus:outline-none focus-visible:ring-2 focus-visible:ring-emerald-500 focus-visible:ring-offset-2 focus-visible:ring-offset-background disabled:opacity-60"
                    >
                      <Avatar className="h-28 w-28 border-2 border-border shadow-xl sm:h-32 sm:w-32">
                        <AvatarImage src={avatar || undefined} alt={name || ''} className="object-cover" />
                        <AvatarFallback className="bg-muted text-3xl text-muted-foreground">
                          {(name || '?').charAt(0).toUpperCase()}
                        </AvatarFallback>
                      </Avatar>
                    </button>
                </DialogTrigger>
                <DialogContent 
                    showCloseButton={false}
                    className="z-[110] flex max-h-[100dvh] w-screen flex-col items-center justify-center rounded-none border-none bg-black/90 p-0 shadow-none backdrop-blur-sm h-[100dvh] max-w-full"
                  >
                    <DialogHeader className="sr-only">
                        <DialogTitle>{name}</DialogTitle>
                        <DialogDescription>{t('chat.profile.avatarFullscreen')}</DialogDescription>
                    </DialogHeader>
                    <header className="absolute top-0 left-0 right-0 z-50 box-border flex min-h-[5.5rem] items-start justify-between gap-3 bg-gradient-to-b from-black/70 to-transparent px-4 pb-2 pt-[calc(1rem+env(safe-area-inset-top,0px))] text-white">
                        <div className="font-semibold">{name}</div>
                        <DialogClose asChild>
                        <Button
                          variant="ghost"
                          size="icon"
                          className="text-white hover:bg-white/20 hover:text-white"
                          aria-label={t('common.close')}
                        >
                                <X className="h-6 w-6" />
                            </Button>
                        </DialogClose>
                    </header>
                    <div className="relative mx-auto h-[calc(100dvh-env(safe-area-inset-top,0px)-env(safe-area-inset-bottom,0px)-6.5rem)] w-[95vw] max-w-full pl-[env(safe-area-inset-left,0px)] pr-[env(safe-area-inset-right,0px)]">
                      {avatar && <img src={avatar} alt={name || 'Avatar'} className="h-full w-full object-contain" />}
                    </div>
                </DialogContent>
            </Dialog>
                {showLiveLocationBadge && profileDocId && (
                  <>
                    <Button
                      type="button"
                      variant="ghost"
                      size="icon"
                      className="absolute -bottom-0.5 -right-0.5 h-10 w-10 rounded-full border-2 border-background bg-emerald-600 text-white shadow-lg hover:bg-emerald-500 hover:text-white"
                      aria-label={t('chat.profile.openLocationMap')}
                      onClick={() => setLiveMapOpen(true)}
                    >
                      <MapPin className="h-5 w-5" />
                    </Button>
                    <LiveLocationMapDialog
                      open={liveMapOpen}
                      onOpenChange={setLiveMapOpen}
                      userId={profileDocId}
                      displayName={displayParticipantInfo?.name ?? name ?? t('chat.userLabel')}
                    />
                  </>
                )}
              </div>
              <h3 className="mt-5 max-w-[min(100%,280px)] text-xl font-bold leading-tight text-foreground sm:text-2xl">
                {name}
              </h3>
              <div className="mt-1 max-w-xs text-center">
                <p className={cn(WA_PROFILE_MUTED, 'text-sm')}>{profileHeaderSubtitles.line1}</p>
                {profileHeaderSubtitles.line2 ? (
                  <p className={cn(WA_PROFILE_MUTED, 'mt-0.5 text-xs leading-snug')}>
                    {profileHeaderSubtitles.line2}
                  </p>
                ) : null}
            </div>
          </div>

            <div className="mt-3 space-y-1 px-2 sm:px-3">
              {(canRunDirectQuickActions || showChatsQuickAction) && (
                <div className="pb-1">
                  <WaQuickActionRow>
                    {showChatsQuickAction ? (
                      <WaQuickActionButton
                        icon={<MessageSquare />}
                        label={t('nav.chats')}
                        onClick={() => void openDirectChatFromProfile()}
                        disabled={quickActionBusy !== null}
                      />
                    ) : null}
                    {canRunDirectQuickActions ? (
                      <>
                        <WaQuickActionButton
                          icon={<Phone />}
                          label={t('chat.profile.callAction')}
                          onClick={() => void startDirectCallFromProfile(false)}
                          disabled={quickActionBusy !== null}
                        />
                        <WaQuickActionButton
                          icon={<Video />}
                          label={t('chat.profile.videoAction')}
                          onClick={() => void startDirectCallFromProfile(true)}
                          disabled={quickActionBusy !== null}
                        />
                        <WaQuickActionButton
                          icon={<Share2 />}
                          label={t('chat.profile.share')}
                          onClick={() => void handleQuickShare()}
                          disabled={quickActionBusy !== null}
                        />
                        {!isSecretConversation ? (
                          <WaQuickActionButton
                            icon={<LockKeyhole />}
                            label={t('chat.profile.secretAction')}
                            onClick={async () => {
                              if (!contactTargetUser || quickActionBusy) return;
                              setQuickActionBusy('secret');
                              try {
                                const sid = buildSecretDirectConversationId(currentUser.id, contactTargetUser.id);
                                const snap = await getDoc(doc(firestore, 'conversations', sid));
                                const existsSecret =
                                  snap.exists() &&
                                  ((snap.data() as Conversation | undefined)?.secretChat?.enabled === true);
                                if (existsSecret) {
                                  onSelectConversation(sid);
                                  handleSheetOpenChange(false);
                                  return;
                                }
                                setSecretComposePeer(contactTargetUser);
                              } finally {
                                setQuickActionBusy(null);
                              }
                            }}
                            disabled={quickActionBusy !== null}
                          />
                        ) : null}
                        <WaQuickActionButton
                          icon={<Bell />}
                          label={muteInCurrentDirect ? t('chat.profile.soundMuted') : t('chat.profile.soundOn')}
                          onClick={() => void toggleDirectNotificationsFromProfile()}
                          disabled={quickActionBusy !== null}
                          accentClassName={muteInCurrentDirect ? 'text-amber-500' : 'text-emerald-500'}
                        />
                      </>
                    ) : null}
                  </WaQuickActionRow>
                </div>
              )}
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
                        className="group flex h-10 w-full items-center justify-between gap-2 rounded-lg border-none bg-transparent px-2 text-sm font-semibold text-foreground shadow-none hover:bg-muted/60 sm:px-2.5"
                      >
                        <span className="min-w-0 truncate text-left">{t('chat.profile.contactsAndData')}</span>
                        <ChevronDown
                          className="h-4 w-4 shrink-0 text-muted-foreground transition-transform duration-200 group-data-[state=open]:rotate-180"
                          aria-hidden
                        />
                      </Button>
                    </CollapsibleTrigger>
                    <CollapsibleContent className="space-y-4 pt-1">
                      {freshParticipant && isProfileFieldVisibleToOthers(freshParticipant, 'email') && displayParticipantInfo.email && (
                                <div className="flex items-center gap-4 px-2">
                          <div className="flex-shrink-0 rounded-full bg-blue-500/10 p-2.5">
                                        <Mail className="h-4 w-4 text-blue-500" />
                                    </div>
                          <div className="flex min-w-0 flex-col">
                            <div className="text-[10px] font-bold uppercase tracking-[0.1em] text-muted-foreground">
                              {t('chat.profile.emailLabel')}
                            </div>
                            <div className="truncate text-sm font-bold leading-tight">{displayParticipantInfo.email}</div>
                          </div>
                        </div>
                      )}

                      {freshParticipant && isProfileFieldVisibleToOthers(freshParticipant, 'phone') && displayParticipantInfo.phone?.trim() && (
                        <div className="flex items-center gap-4 px-2">
                          <div className="flex-shrink-0 rounded-full bg-emerald-500/10 p-2.5">
                            <Smartphone className="h-4 w-4 text-emerald-500" />
                          </div>
                          <div className="flex min-w-0 flex-col">
                            <div className="text-[10px] font-bold uppercase tracking-[0.1em] text-muted-foreground">{t('chat.profile.phoneLabel')}</div>
                            <div className="truncate text-sm font-bold leading-tight">
                              {formatPhoneNumberForDisplay(displayParticipantInfo.phone)}
                            </div>
                                    </div>
                                </div>
                            )}

                      {freshParticipant && isProfileFieldVisibleToOthers(freshParticipant, 'dateOfBirth') && displayParticipantInfo.dateOfBirth && (
                                <div className="flex items-center gap-4 px-2">
                          <div className="flex-shrink-0 rounded-full bg-purple-500/10 p-2.5">
                                        <Cake className="h-4 w-4 text-purple-500" />
                                    </div>
                          <div className="flex min-w-0 flex-col">
                            <div className="text-[10px] font-bold uppercase tracking-[0.1em] text-muted-foreground">{t('chat.profile.birthdayLabel')}</div>
                            <div className="truncate text-sm font-bold leading-tight">{displayParticipantInfo.dateOfBirth}</div>
                          </div>
                        </div>
                      )}

                      {freshParticipant && isProfileFieldVisibleToOthers(freshParticipant, 'bio') && displayParticipantInfo.bio?.trim() && (
                        <div className="flex items-start gap-4 px-2">
                          <div className="flex-shrink-0 rounded-full bg-muted p-2.5">
                            <UserRound className="h-4 w-4 text-muted-foreground" />
                          </div>
                          <div className="flex min-w-0 flex-col gap-1">
                            <div className="text-[10px] font-bold uppercase tracking-[0.1em] text-muted-foreground">{t('chat.profile.bioLabel')}</div>
                            <p className="break-words text-sm leading-relaxed whitespace-pre-wrap">{displayParticipantInfo.bio}</p>
                                    </div>
                                </div>
                            )}

                            {displayParticipantInfo.role && displayParticipantInfo.role !== 'worker' && (
                                <div className="flex items-center gap-4 px-2">
                          <div className="flex-shrink-0 rounded-full bg-primary/10 p-2.5">
                                        <ShieldCheck className="h-4 w-4 text-primary" />
                                    </div>
                          <div className="flex min-w-0 flex-col">
                            <div className="text-[10px] font-bold uppercase tracking-[0.1em] text-muted-foreground">{t('chat.profile.roleLabel')}</div>
                            <div className="truncate text-sm font-bold leading-tight">
                              {ROLES[displayParticipantInfo.role as UserRole] || displayParticipantInfo.role}
                                    </div>
                                </div>
                        </div>
                      )}
                    </CollapsibleContent>
                  </Collapsible>

                  {canShowAddToContacts ? (
                    <Button
                      type="button"
                      variant="secondary"
                      className="inline-flex h-12 shrink-0 flex-row items-center justify-center gap-1.5 rounded-2xl border-border bg-muted px-2.5 font-bold text-foreground shadow-none hover:bg-muted/80 sm:px-3"
                      onClick={handleOpenContactEditor}
                      title={isContact ? t('chat.profile.editContact') : t('chat.profile.addToContacts')}
                      aria-label={isContact ? t('chat.profile.editContact') : t('chat.profile.addToContacts')}
                    >
                      {isContact ? (
                        <Edit className="h-5 w-5 shrink-0" aria-hidden />
                      ) : (
                        <UserPlus className="h-5 w-5 shrink-0" aria-hidden />
                      )}
                      <span className="max-w-[5rem] truncate text-left text-[11px] leading-none sm:max-w-[6.5rem] sm:text-sm">
                        {isContact ? t('chat.profile.editContactShort') : t('chat.profile.addToContactsShort')}
                      </span>
                    </Button>
                  ) : null}
                    </div>
                )}

              {canShowAddToContacts && !hasContactDetailsRows ? (
                <div className="px-2 pb-1">
                  <Button
                    type="button"
                    variant="secondary"
                    className="h-12 w-full justify-center gap-2 rounded-2xl border-border bg-muted font-bold text-foreground shadow-none hover:bg-muted/80"
                    onClick={handleOpenContactEditor}
                  >
                    {isContact ? (
                      <Edit className="h-5 w-5 shrink-0" aria-hidden />
                    ) : (
                      <UserPlus className="h-5 w-5 shrink-0" aria-hidden />
                    )}
                    {isContact ? t('chat.profile.editContact') : t('chat.profile.addToContacts')}
                  </Button>
                </div>
              ) : null}

              {isGroup && !showMemberFocus && (
                    <div className="space-y-0.5 pb-0.5">
                        <Button 
                            variant="ghost" 
                    className="h-10 w-full justify-between rounded-lg border-none bg-transparent px-2 text-sm font-medium text-foreground shadow-none hover:bg-muted/60 active:scale-[0.99]"
                    onClick={() => setGroupProfileLayer('participants')}
                        >
                    <span className="flex items-center gap-2.5">
                      <Users className="h-[18px] w-[18px] shrink-0 text-emerald-500" /> {t('chat.profile.participants')}
                            </span>
                    <Badge
                      variant="secondary"
                      className="rounded-full border-none bg-emerald-600 px-2 py-0.5 text-[10px] font-bold text-white shadow-none"
                    >
                      {groupParticipantCount}
                    </Badge>
                        </Button>
                        {isAdmin && (
                            <Button 
                                variant="ghost" 
                      className="h-10 w-full justify-start rounded-lg border-none bg-transparent px-2 text-sm font-medium text-foreground shadow-none hover:bg-muted/60 active:scale-[0.99]"
                      onClick={() => setGroupProfileLayer('edit')}
                            >
                      <Edit className="mr-2.5 h-[18px] w-[18px] shrink-0 text-emerald-500" />
                      {t('chat.profile.editGroup')}
                            </Button>
                        )}
                    </div>
                )}

              {showBlockUserRow ? (
                <WaMenuSection className="pb-0.5">
                  {/* H-2 [audit] жалоба на пользователя — паритет с mobile report_sheet.dart.
                      Условие показа = showBlockUserRow (1-on-1 чат / focus на участника
                      группы, не self-saved, не я). Бэкенд — тот же createMessageReportAction,
                      но без messageId — попадает как user-level report в админ-панель. */}
                  <WaMenuRow
                    icon={<Flag className="h-[18px] w-[18px] shrink-0 text-destructive" />}
                    title={t('chat.profile.reportUser')}
                    onClick={() => setReportDialogOpen(true)}
                  />
                  <WaMenuRow
                    icon={
                      isPartnerBlockedByMe ? (
                        <Unlock className="h-[18px] w-[18px] shrink-0 text-amber-600" />
                      ) : (
                        <Ban className="h-[18px] w-[18px] shrink-0 text-destructive" />
                      )
                    }
                    title={isPartnerBlockedByMe ? t('chat.profile.unblock') : t('chat.profile.block')}
                    onClick={() =>
                      isPartnerBlockedByMe ? setUnblockDialogOpen(true) : setBlockDialogOpen(true)
                    }
                  />
                </WaMenuSection>
              ) : null}

              <div className="space-y-0.5 pt-0.5">
              <WaMenuSection>
                <WaMenuRow
                  icon={<ImageIcon />}
                  title={t('chat.profile.mediaLinksFiles')}
                  right={<span className="text-xs tabular-nums text-muted-foreground">{mediaDocsLabel}</span>}
                  onClick={() => setProfileSubMenu('media')}
                />
                <WaMenuRow
                  icon={<Star />}
                  title={t('chat.profile.starred')}
                  right={<span className="text-xs tabular-nums text-muted-foreground">{starredLabel}</span>}
                  onClick={() => setProfileSubMenu('starred')}
                />
                <WaMenuRow
                  icon={<MessageSquare />}
                  title={t('chat.profile.discussions')}
                  right={<span className="text-xs tabular-nums text-muted-foreground">{discussionsLabel}</span>}
                  onClick={() => setProfileSubMenu('threads')}
                />
                <WaMenuRow
                  icon={<Swords />}
                  title={t('chat.profile.games')}
                  onClick={() => setProfileSubMenu('games')}
                />
              </WaMenuSection>
              <WaMenuSection className="mt-0.5">
                <WaMenuRow
                  icon={<Bell />}
                  title={t('chat.profile.notificationsInChat')}
                  onClick={() => setProfileSubMenu('notifications')}
                />
                <WaMenuRow
                  icon={<Palette />}
                  title={t('chat.profile.chatTheme')}
                  onClick={() => setProfileSubMenu('theme')}
                />
              </WaMenuSection>
              <WaMenuSection className="mt-0.5">
                {isSecretConversation ? (
                  <WaMenuRow
                    icon={<LockKeyhole />}
                    title={t('chat.profile.secretChatSettings')}
                    description={t('chat.profile.secretChatSettingsDesc')}
                    onClick={() => setSecretSettingsOpen(true)}
                  />
                ) : null}
                {showDisappearingMessagesRow ? (
                  <WaMenuRow
                    icon={<History />}
                    title={t('chat.profile.disappearingMessages')}
                    right={
                      <span className="text-xs text-muted-foreground">
                        {formatDisappearingTtlSummary(conversation.disappearingMessageTtlSec)}
                      </span>
                    }
                    onClick={() => setProfileSubMenu('disappearing')}
                  />
                ) : null}
                <WaMenuRow
                  icon={<Shield />}
                  title={t('chat.profile.chatPrivacy')}
                  right={<span className="text-xs text-muted-foreground">{privacySummaryLabel}</span>}
                  onClick={() => setProfileSubMenu('privacy')}
                />
                {showEncryptionMenuRow ? (
                  <WaMenuRow
                    icon={<ShieldCheck />}
                    title={t('chat.profile.encryptionLabel')}
                    description={encryptionRowDescription}
                    right={<span className="text-xs text-muted-foreground">{encryptionSummaryLabel}</span>}
                    onClick={() => setProfileSubMenu('encryption')}
                  />
                ) : null}
              </WaMenuSection>
                                                            </div>
              {!isSelfSavedChat && (showMemberFocus || !isGroup) ? (
                <>
                  <WaFooterCaption>{t('chat.profile.noCommonGroups')}</WaFooterCaption>
                  <button
                    type="button"
                    className="flex w-full items-center gap-2 rounded-lg px-1 py-1.5 text-left text-sm text-foreground transition-colors hover:bg-muted/60 active:bg-muted/80 [-webkit-tap-highlight-color:transparent]"
                    onClick={() =>
                      toast({
                        title: t('chat.profile.comingSoon'),
                        description: t('chat.profile.comingSoonGroupHint'),
                      })
                    }
                  >
                    <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full border border-dashed border-muted-foreground/45 text-muted-foreground">
                      <PlusCircle className="h-4 w-4" />
                    </span>
                    <span>
                      {t('chat.profile.createGroupWith')}{' '}
                      {showMemberFocus ? displayParticipantInfo?.name ?? name : name}
                    </span>
                  </button>
                </>
              ) : null}
                </div>

            {isGroup && !showMemberFocus && (
              <div className="space-y-1 px-2 pb-10 pt-2 sm:px-3">
                <Button
                  variant="ghost"
                  className="h-10 w-full rounded-lg border-none bg-transparent text-sm font-medium text-foreground shadow-none hover:bg-muted/60 active:scale-[0.99]"
                  onClick={() => setProfileSubMenu('leave')}
                >
                  <LogOut className="mr-2 h-4 w-4" />
                  {t('chat.profile.leaveGroup')}
                        </Button>
                    </div>
                )}
          </div>
        </div>
        )}
      </SheetContent>

      <AlertDialog open={blockDialogOpen} onOpenChange={setBlockDialogOpen}>
        <AlertDialogContent className="rounded-2xl">
          <AlertDialogHeader>
            <AlertDialogTitle>{t('chat.profile.blockDialogTitle')}</AlertDialogTitle>
            <AlertDialogDescription>
              {t('chat.profile.blockDialogDesc')}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={blockBusy}>{t('common.cancel')}</AlertDialogCancel>
            <AlertDialogAction
              disabled={blockBusy}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
              onClick={(e) => {
                e.preventDefault();
                void handleConfirmBlockUser();
              }}
            >
              {t('chat.profile.block')}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      <AlertDialog open={unblockDialogOpen} onOpenChange={setUnblockDialogOpen}>
        <AlertDialogContent className="rounded-2xl">
          <AlertDialogHeader>
            <AlertDialogTitle>{t('chat.profile.unblockDialogTitle')}</AlertDialogTitle>
            <AlertDialogDescription>
              {t('chat.profile.unblockDialogDesc')}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={blockBusy}>{t('common.cancel')}</AlertDialogCancel>
            <AlertDialogAction
              disabled={blockBusy}
              onClick={(e) => {
                e.preventDefault();
                void handleConfirmUnblockUser();
              }}
            >
              {t('chat.profile.unblock')}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      {secretComposePeer ? (
        <SecretChatComposeDialog
          open={!!secretComposePeer}
          onOpenChange={(next) => {
            if (!next) setSecretComposePeer(null);
          }}
          currentUser={currentUser}
          peerUser={secretComposePeer}
          onCreated={(conversationId) => {
            setSecretComposePeer(null);
            onSelectConversation(conversationId);
            handleSheetOpenChange(false);
          }}
        />
      ) : null}

      {isSecretConversation ? (
        <SecretChatSettingsDialog
          open={secretSettingsOpen}
          onOpenChange={setSecretSettingsOpen}
          conversation={conversation}
          onDeleted={() => {
            handleSheetOpenChange(false);
            router.replace('/dashboard/chat');
          }}
        />
      ) : null}

      {/* H-2 [audit] user-report диалог. `messageId` не передаём — диалог
          показывает заголовок «Пожаловаться на пользователя»; на бэке
          report пишется без messageId и в админке кнопка «Скрыть сообщение»
          для него дизейблится (см. admin-moderation-panel.tsx). */}
      {showBlockUserRow && profileDocId ? (
        <ReportMessageDialog
          open={reportDialogOpen}
          onOpenChange={setReportDialogOpen}
          conversationId={conversation.id}
          messageSenderId={profileDocId}
          messageSenderName={displayParticipantInfo?.name}
        />
      ) : null}
    </Sheet>
  );
}
