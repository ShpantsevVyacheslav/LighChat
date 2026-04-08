export type UserRole = "admin" | "worker";

/** Тема всего приложения (меню профиля): светлая, тёмная или по цветам фона из «Настроек чата». */
export type AppThemePreference = "light" | "dark" | "chat";

export type User = {
  id: string;
  name: string;
  username: string;
  role?: UserRole;
  email: string;
  /** Полноразмерный URL (просмотр в профиле и т.д.). */
  avatar: string;
  /** Круглое превью (~512×512) для списков чатов и миниатюр; иначе UI использует `avatar`. */
  avatarThumb?: string;
  phone: string;
  bio?: string;
  deletedAt: string | null;
  fcmTokens?: string[];
  online?: boolean;
  lastSeen?: string;
  dateOfBirth?: string | null;
  createdAt: string;
  customBackgrounds?: string[];
  chatSettings?: ChatSettings;
  notificationSettings?: NotificationSettings;
  privacySettings?: PrivacySettings;
  /**
   * Активная «живая» геолокация: видна другим в профиле (значок карты), обновляется в фоне.
   * Удаляется или active:false при отзыве или по истечении expiresAt.
   */
  liveLocationShare?: UserLiveLocationShare | null;
  /** Блокировка входа (только админ). */
  accountBlock?: UserAccountBlock | null;
  /** Лимит хранилища для пользователя, байт; null/отсутствует — общий политикой (см. platformSettings). */
  storageQuotaBytes?: number | null;
  /** Сохраняется в Firestore; синхронизируется с next-themes при входе. */
  appTheme?: AppThemePreference;
};

/** Блокировка учётной записи. until: null — навсегда (пока админ не снимет). */
export type UserAccountBlock = {
  active: boolean;
  until: string | null;
  reason?: string;
  blockedAt: string;
  blockedBy?: string;
};

/** Данные трансляции геолокации в документе users/{userId}. */
export type UserLiveLocationShare = {
  active: boolean;
  /** ISO; null — «навсегда», пока пользователь не отзовёт. */
  expiresAt: string | null;
  lat: number;
  lng: number;
  accuracyM?: number;
  updatedAt: string;
  startedAt: string;
};

export type Meeting = {
  id: string;
  name: string;
  hostId: string;
  adminIds?: string[];
  createdAt: string;
  expiresAt?: string | null;
  status: 'active' | 'ended';
  isRecording?: boolean;
  isPrivate?: boolean;
};

export type MeetingPoll = {
  id: string;
  question: string;
  options: string[];
  creatorId: string;
  status: 'active' | 'ended' | 'cancelled' | 'draft';
  isAnonymous: boolean;
  createdAt: any;
  votes: Record<string, number>;
};

export type MeetingJoinRequest = {
  id?: string;
  userId: string;
  name: string;
  avatar: string;
  status: 'pending' | 'approved' | 'denied';
  createdAt: string | any;
  requestId?: string;
  lastSeen?: string;
};

export type MeetingJoinRequestWithId = MeetingJoinRequest & { id: string };

export type MeetingSignal = {
  id?: string;
  from: string;
  to: string;
  type: 'offer' | 'answer' | 'candidate';
  data: any;
  createdAt: any;
};

export type UserMeetingsIndex = {
  meetingIds: string[];
};

export type CallStatus = "calling" | "ongoing" | "ended" | "rejected";

export type Call = {
  id: string;
  callerId: string;
  receiverId: string;
  callerName: string;
  /**
   * Устаревшее поле: раньше писалось в документ звонка. Новые звонки не сохраняют аватары —
   * брать актуальный URL из `users/{callerId|receiverId}`.
   */
  callerAvatar?: string;
  /** Имя получателя на момент звонка (для подписи, пока профиль не загружен). */
  receiverName?: string;
  /** @deprecated См. `callerAvatar` — только для старых документов. */
  receiverAvatar?: string;
  status: CallStatus;
  isVideo: boolean;
  offer?: any;
  answer?: any;
  createdAt: string;
  startedAt?: string;
  endedAt?: string;
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
  width?: number;
  height?: number;
  thumbHash?: string | null;
};

export type PinnedMessage = {
  messageId: string;
  text: string;
  senderName: string;
  senderId: string;
  mediaPreviewUrl?: string | null;
  mediaType?: 'image' | 'video' | 'video-circle' | 'sticker' | 'file' | null;
  /** ISO — порядок и позиция в ленте, если сообщения ещё нет в загруженном окне. */
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
  /** Снимок имён на момент правок группы; аватар не храним — брать из `users/{id}`. */
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
  lastMessageIsThread?: boolean;
  unreadCounts?: {
    [key: string]: number;
  };
  unreadThreadCounts?: {
    [key: string]: number;
  };
  typing?: {
    [key: string]: boolean;
  };
  /** @deprecated Предпочтение — pinnedMessages; оставлено для старых документов. */
  pinnedMessage?: PinnedMessage | null;
  /** Закрепы (порядок в UI задаётся сортировкой по времени сообщения). */
  pinnedMessages?: PinnedMessage[];
  lastReactionEmoji?: string | null;
  lastReactionTimestamp?: string | null;
  lastReactionSenderId?: string | null;
  lastReactionMessageId?: string | null;
  lastReactionParentId?: string | null;
  lastReactionSeenAt?: Record<string, string>;
  clearedAt?: Record<string, string>;
  /** Участники группы с непросмотренным @-упоминанием (очищается при открытии чата). */
  usersWithPendingGroupMention?: string[];
  /** Лимит хранилища для группового чата, байт (задаёт админ). */
  storageQuotaBytes?: number | null;
};

/** Документ Firestore: platformSettings/main */
export type PlatformStoragePolicy = {
  /** Удаление медиа в Storage старше N дней от даты отправки (нужна Cloud Function + индексация дат). */
  mediaRetentionDays: number | null;
  /** Общий лимит проекта в Гб; при превышении — FIFO по старым файлам (нужна CF). */
  totalQuotaGb: number | null;
  /** Оценка стоимости в панели статистики: USD за 1 Гб·мес (не из биллинга GCP). */
  estimatedPricePerGbMonthUsd?: number | null;
  updatedAt?: string;
  updatedBy?: string;
};

/** Ответ server action статистики вложений по сообщениям Firestore. */
export type AdminChatStorageStatsRow = {
  conversationId: string;
  title: string;
  isGroup: boolean;
  bytes: number;
  messageDocs: number;
};

export type AdminChatStorageStatsResult = {
  ok: true;
  /** Сумма вложений в чатах (conversations), байт */
  chatTotalBytes: number;
  groupChatsBytes: number;
  directChatsBytes: number;
  /** Вложения в сообщениях конференций (коллекция meetings) */
  meetingsBytes: number;
  scannedMainMessageDocs: number;
  scannedThreadDocs: number;
  scannedMeetingMessageDocs: number;
  skippedUndatedInRange: number;
  byConversation: AdminChatStorageStatsRow[];
  /** Сообщения без поля size у вложений (старые данные) */
  attachmentsMissingSize: number;
} | { ok: false; error: string };

export type PlatformSettingsDoc = {
  storage: PlatformStoragePolicy;
};

export type ReplyContext = {
  messageId: string;
  senderName: string;
  text: string;
  mediaPreviewUrl?: string | null;
  mediaType?: 'image' | 'video' | 'video-circle' | 'sticker' | 'file' | null;
};

export type ReactionDetail = {
  userId: string;
  timestamp: string;
};

/** Геолокация в сообщении чата (ссылка на Google Maps + опционально Static Maps). */
export type ChatLocationShare = {
  lat: number;
  lng: number;
  accuracyM?: number;
  mapsUrl: string;
  /** URL превью от Google Static Maps API; может отсутствовать без ключа. */
  staticMapUrl?: string | null;
  capturedAt: string;
  /** Сообщение привязано к живой трансляции (см. users/{senderId}.liveLocationShare). */
  liveSession?: {
    expiresAt: string | null;
  };
};

/** Режим отправки из диалога «Локация». */
export type ChatLocationSendMeta =
  | { kind: 'once' }
  | { kind: 'live'; expiresAt: string | null };

export type ChatMessage = {
  id: string;
  senderId: string;
  text?: string;
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
  reactions?: Record<string, (string | ReactionDetail)[]>;
  lastReactionTimestamp?: string;
  threadCount?: number;
  unreadThreadCounts?: Record<string, number>;
  lastThreadMessageText?: string;
  lastThreadMessageSenderId?: string;
  lastThreadMessageTimestamp?: string;
  locationShare?: ChatLocationShare;
  /** Документ: conversations/{conversationId}/polls/{chatPollId} (структура как MeetingPoll). */
  chatPollId?: string;
};

export type MeetingMessage = {
  id: string;
  senderId: string;
  senderName: string;
  text?: string;
  attachments?: ChatAttachment[];
  createdAt: any;
  updatedAt?: string;
  isDeleted?: boolean;
};

export type ChatFolder = {
  id: string;
  name: string;
  conversationIds: string[];
  type: 'all' | 'personal' | 'groups' | 'custom' | 'favorites';
};

export type UserChatIndex = {
  conversationIds: string[];
  folders?: ChatFolder[];
  /** Закреплённые чаты по id папки (порядок в массиве = порядок сверху в списке). */
  folderPins?: Record<string, string[]>;
  /** Порядок папок в боковой колонке (id: all, unread, personal, groups, …custom). */
  sidebarFolderOrder?: string[];
};

/** Индекс контактов текущего пользователя (без подтверждения со стороны контакта). */
export type UserContactsIndex = {
  contactIds?: string[];
  /** ISO-время, когда пользователь согласился на синхронизацию с контактами устройства */
  deviceSyncConsentAt?: string | null;
  /** Пользователь отклонил предложение импорта телефонной книги (PWA, первый вход). */
  phoneBookOfferDismissedAt?: string | null;
};

export type UserCallsIndex = {
  callIds: string[];
};

export type ProfileTab = 'media' | 'files' | 'links' | 'threads' | 'audios' | 'circles';

/** Доп. оформление иконки пункта нижней навигации (цвет, штрих, фон плитки). */
export type BottomNavIconVisualStyle = {
  /** CSS-цвет обводки/заливки иконки (режим «цветной» и «минимальный»). */
  iconColor?: string | null;
  /** Толщина линии Lucide stroke (около 1–3). */
  strokeWidth?: number | null;
  /** Произвольный фон плитки в режиме «цветной» (hex/rgb); пусто — градиент по умолчанию. */
  tileBackground?: string | null;
};

export type ChatSettings = {
  fontSize: 'small' | 'medium' | 'large';
  bubbleColor: string | null;
  incomingBubbleColor: string | null;
  chatWallpaper: string | null;
  /** 2 пресета; устаревшие значения из БД нормализуются в `normalizeBubbleRadius` */
  bubbleRadius: "rounded" | "square";
  showTimestamps: boolean;
  /**
   * Внешний вид нижней навигации: цветные градиентные плитки или монохромные иконки.
   */
  bottomNavAppearance?: 'colorful' | 'minimal';
  /**
   * Переопределение иконок: href пункта меню → имя иконки Lucide (kebab-case), см. lucide.dev.
   */
  bottomNavIconNames?: Record<string, string>;
  /**
   * Универсальное оформление всех иконок нижнего меню (цвет, штрих, фон плитки).
   * Переопределения по `bottomNavIconStyles[href]` имеют приоритет.
   */
  bottomNavIconGlobalStyle?: BottomNavIconVisualStyle;
  /**
   * Оформление по href: цвет иконки, толщина штриха и фон плитки (см. BottomNavIconVisualStyle).
   */
  bottomNavIconStyles?: Record<string, BottomNavIconVisualStyle>;
};

export type NotificationSettings = {
  soundEnabled: boolean;
  showPreview: boolean;
  muteAll: boolean;
  quietHoursEnabled: boolean;
  quietHoursStart: string;
  quietHoursEnd: string;
};

/**
 * Кто может добавить пользователя в групповой чат (обычные пользователи; роль admin в приложении не ограничена).
 */
export type GroupInvitePolicy = "everyone" | "contacts" | "none";

export type PrivacySettings = {
  showOnlineStatus: boolean;
  showLastSeen: boolean;
  showReadReceipts: boolean;
  /** Показывать другим в карточке профиля / списках (по умолчанию true, если не задано). */
  showEmailToOthers?: boolean;
  showPhoneToOthers?: boolean;
  showBioToOthers?: boolean;
  showDateOfBirthToOthers?: boolean;
  /**
   * Участвовать в глобальном поиске при выборе собеседника (блок «Все пользователи»).
   * false — не показывать там; в списке «Контакты» у тех, кто вас добавил, вы по-прежнему можете отображаться.
   */
  showInGlobalUserSearch?: boolean;
  /**
   * Приглашения в группы: everyone — без ограничения; contacts — только если вы в контактах у приглашающего; none — никто.
   */
  groupInvitePolicy?: GroupInvitePolicy;
};
