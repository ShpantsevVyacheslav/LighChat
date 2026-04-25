
export type UserRole = "admin" | "worker";

export type User = {
  id: string;
  name: string;
  username: string;
  role: UserRole;
  email: string;
  avatar: string;
  avatarThumb?: string;
  phone: string;
  bio?: string;
  deletedAt: string | null;
  fcmTokens?: string[];
  voipTokens?: string[];
  online?: boolean;
  lastSeen?: string;
  dateOfBirth?: string | null;
};

export type Notification = {
  id: string;
  userId: string;
  title: string;
  body: string;
  link: string;
  createdAt: string;
  isRead: boolean;
};

export type ChatAttachment = {
  url: string;
  name: string;
  type: string;
  size: number;
};

export type PinnedMessage = {
  messageId: string;
  text: string;
  senderName: string;
  senderId: string;
  messageCreatedAt?: string;
};

export type Conversation = {
  id: string;
  isGroup: boolean;
  name?: string;
  description?: string;
  photoUrl?: string;
  createdByUserId?: string;
  adminIds: string[];
  participantIds: string[];
  participantInfo: {
    [key: string]: {
      name: string;
      avatar?: string;
      avatarThumb?: string;
    };
  };
  lastMessageText?: string;
  lastMessageTimestamp?: string;
  lastMessageSenderId?: string;
  unreadCounts?: {
    [key: string]: number;
  };
  typing?: {
    [key: string]: boolean;
  };
  pinnedMessage?: PinnedMessage | null;
  pinnedMessages?: PinnedMessage[];
};

export type ReplyContext = {
  messageId: string;
  senderName: string;
  text: string;
};

export type ChatMessage = {
  id: string;
  senderId: string;
  text?: string;
  /** Сквозное шифрование; push-функции не читают ciphertext. */
  e2ee?: {
    protocolVersion: string;
    epoch: number;
    iv: string;
    ciphertext: string;
  };
  createdAt: string;
  readAt: string | null;
  updatedAt?: string | null;
  attachments?: ChatAttachment[];
  replyTo?: ReplyContext;
  deliveryStatus?: "sending" | "sent" | "failed";
  isDeleted?: boolean;
  forwardedFrom?: {
    name: string;
  };
};

export type UserChatIndex = {
  conversationIds: string[];
  folderPins?: Record<string, string[]>;
  /** Порядок папок в боковой колонке чата (клиент). */
  sidebarFolderOrder?: string[];
};

export type MeetingJoinRequest = {
  id?: string;
  userId: string;
  name: string;
  avatar: string;
  status: 'pending' | 'approved' | 'denied';
  createdAt: string | unknown;
  requestId?: string;
  lastSeen?: string;
};
