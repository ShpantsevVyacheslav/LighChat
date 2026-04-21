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
  /** Пояснение под вопросом (чат, паритет Telegram). */
  description?: string | null;
  options: string[];
  creatorId: string;
  status: 'active' | 'ended' | 'cancelled' | 'draft';
  isAnonymous: boolean;
  createdAt: any;
  /** uid → индекс варианта или массив индексов при множественном выборе. */
  votes: Record<string, number | number[]>;
  allowMultipleAnswers?: boolean;
  allowAddingOptions?: boolean;
  /** false — нельзя изменить голос (по умолчанию клиенты считают true). */
  allowRevoting?: boolean;
  shuffleOptions?: boolean;
  quizMode?: boolean;
  correctOptionIndex?: number | null;
  quizExplanation?: string | null;
  /** ISO — авто-завершение по времени. */
  closesAt?: string | null;
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
  /** Сквозное шифрование (E2E): новые сообщения с полем `e2ee`, сервер не видит plaintext. */
  e2eeEnabled?: boolean;
  /** Номер эпохи ключа чата; при смене участников увеличивается. */
  e2eeKeyEpoch?: number;
  /** ISO: с этого момента новые сообщения в E2E-формате (гибрид со старым plaintext). */
  e2eeEnabledAt?: string | null;
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
  /** Если true — при создании нового личного чата клиент пытается включить E2E (если у обоих есть ключи). */
  e2eeDefaultForNewDirectChats?: boolean;
  /**
   * Переключатель протокола E2EE. См. RFC §8.2.
   *  - `v1` — пишем только v1-сессии/сообщения (legacy).
   *  - `v2` — все новые enable/rotate создают v2-сессии, сообщения пишутся v2.
   *  - `auto` (default) — если в чате уже есть v2-сессия, пишем v2, иначе v1.
   * Читатели поддерживают dual-read независимо от флага.
   */
  e2eeProtocolVersion?: 'v1' | 'v2' | 'auto';
};

export type ReplyContext = {
  messageId: string;
  senderName: string;
  /** Для E2E может отсутствовать — превью подставляется из расшифрованного родительского сообщения в UI. */
  text?: string;
  mediaPreviewUrl?: string | null;
  mediaType?: 'image' | 'video' | 'video-circle' | 'sticker' | 'file' | null;
};

/**
 * Версия протокола E2E.
 * - `v1-p256-aesgcm` — MVP: P-256 ECDH + AES-GCM, один публичный ключ на пользователя, wraps[uid].
 * - `v2-p256-aesgcm-multi` — multi-device: публичный ключ на устройство, wraps[uid][deviceId],
 *    HKDF wrap, AAD в AEAD, зашифрованные медиа-конверты. См. `docs/arcitecture/07-e2ee-v2-protocol.md`.
 */
export type E2eeProtocolVersion = 'v1-p256-aesgcm' | 'v2-p256-aesgcm-multi';

/** Зашифрованное тело сообщения в Firestore (plaintext только на клиенте). */
export type ChatMessageE2eePayload = {
  protocolVersion: E2eeProtocolVersion;
  epoch: number;
  iv: string;
  ciphertext: string;
  /**
   * v2: id устройства-источника. Отсутствует у v1-сообщений. Помогает UI показать «кто отправил с какого устройства»
   * и используется как часть AAD в декодере.
   */
  senderDeviceId?: string;
  /** v2: зашифрованные вложения, параллельный массив к `attachments`. Nullable — элемент может отсутствовать для sticker/gif. */
  attachments?: Array<ChatMessageE2eeAttachmentEnvelopeV2 | null>;
};

/**
 * v2 media envelope, лежит в `message.e2ee.attachments[i]`. См. RFC §5.5 и §6.4.
 * Данные в Storage лежат как зашифрованные чанки по 4 МиБ; polling/пре-превью
 * идёт через inline-зашифрованный `thumb`.
 */
export type ChatMessageE2eeAttachmentEnvelopeV2 = {
  fileId: string;
  kind: 'image' | 'video' | 'voice' | 'videoCircle' | 'file';
  mime: string;
  size: number;
  wrap: E2eeKeyWrapEntry;
  chunking: { chunkSizeBytes: 4194304; chunkCount: number };
  iv: { prefixB64: string };
  thumb?: {
    path?: string;
    ivB64: string;
    ciphertextB64: string;
    mime: string;
  };
  metadataEnc?: { ivB64: string; ciphertextB64: string };
};

export type ChatMediaNorm = {
  status: 'pending' | 'done' | 'failed';
  failedIndexes?: number[];
  updatedAt: string;
};

export type ChatEmojiBurstEvent = {
  eventId: string;
  emoji: string;
  by: string;
  at: string;
};

/**
 * Обёртка ключа чата для участника (одноразовый ephemeral ECDH + AES-GCM).
 * Документ эпохи: `conversations/{id}/e2eeSessions/{epoch}`.
 */
export type E2eeKeyWrapEntry = {
  ephPub: string;
  iv: string;
  ct: string;
};

/** Документ `conversations/{conversationId}/e2eeSessions/{epoch}` (v1/legacy). */
export type E2eeSessionDoc = {
  epoch: number;
  protocolVersion: E2eeProtocolVersion;
  createdAt: string;
  createdByUserId: string;
  wraps: Record<string, E2eeKeyWrapEntry>;
};

/**
 * v2-вариант документа эпохи. Главное отличие — `wraps` теперь вложенная мапа
 * `userId → deviceId → wrapEntry`. Лежит в той же коллекции
 * `conversations/{cid}/e2eeSessions/{epoch}`; версия распознаётся по полю
 * `protocolVersion`. Коллекция едина, чтобы читатели v2 могли dual-read.
 */
export type E2eeSessionDocV2 = {
  epoch: number;
  protocolVersion: 'v2-p256-aesgcm-multi';
  createdAt: string;
  createdByUserId: string;
  createdByDeviceId: string;
  participantIds: string[];
  wraps: Record<string, Record<string, E2eeKeyWrapEntry>>;
  wrapContext: string;
};

/** Публичный ключ устройства (v1): `users/{uid}/e2ee/device`. */
export type UserE2eePublicDoc = {
  publicKeySpki: string;
  updatedAt: string;
};

/**
 * v2 публичный ключ per-device: `users/{uid}/e2eeDevices/{deviceId}`.
 * Коллекция, а не единичный доc, чтобы пользователь мог иметь
 * много устройств параллельно. См. RFC §5.1.
 */
export type E2eeDeviceDocV2 = {
  deviceId: string;
  publicKeySpki: string;
  platform: 'web' | 'ios' | 'android';
  label: string;
  createdAt: string;
  lastSeenAt: string;
  revoked?: boolean;
  revokedAt?: string;
  revokedByDeviceId?: string;
  keyBundleVersion: 1;
};

/**
 * v2 password-backup приватника: `users/{uid}/e2eeBackups/{backupId}`.
 * Содержит обёртку PKCS#8 приватника, зашифрованного ключом из Argon2id(password, salt).
 * См. RFC §5.2.
 */
/**
 * KDF-параметры password-backup. Поддерживается два алгоритма (дискриминированный
 * union по `algorithm`):
 *  - `'argon2id'` — целевой по RFC §5.2 (memory-hard, лучше для GPU-устойчивости).
 *    Требует WASM-пакет на web и `argon2_ffi_base` на mobile.
 *  - `'pbkdf2-sha256'` — fallback через native WebCrypto.subtle: позволяет
 *    выкатить фичу без дополнительных web-deps. 600 000 итераций — OWASP-2023
 *    рекомендация, разумный компромисс по CPU-времени на старте сессии.
 *    Клиенты знают, как расшифровать оба формата (выбор по `algorithm`).
 */
export type E2eeBackupKdfParams =
  | {
      algorithm: 'argon2id';
      memKiB: number;
      iterations: number;
      parallelism: number;
      saltB64: string;
    }
  | {
      algorithm: 'pbkdf2-sha256';
      iterations: number;
      saltB64: string;
    };

export type E2eeBackupDocV2 = {
  backupId: string;
  backupVersion: 1;
  createdAt: string;
  kdf: E2eeBackupKdfParams;
  aead: {
    algorithm: 'AES-GCM';
    ivB64: string;
    ciphertextB64: string;
  };
  allowedDeviceLabels?: string[];
};

/**
 * v2 QR-pairing session: `users/{uid}/e2eePairingSessions/{sessionId}`.
 * Один из scenarios `donor → new device` передачи приватника. TTL → 10 мин.
 * См. RFC §5.3 и §6.7.
 */
export type E2eePairingSessionDocV2 = {
  sessionId: string;
  createdAt: string;
  expiresAt: string;
  state:
    | 'awaiting_scan'
    | 'awaiting_accept'
    | 'completed'
    | 'expired'
    | 'rejected';
  initiatorEphPubSpkiB64: string;
  donorPayload?: {
    donorEphPubSpkiB64: string;
    ivB64: string;
    ciphertextB64: string;
    deviceDraft: {
      deviceId: string;
      platform: 'web' | 'ios' | 'android';
      label: string;
      publicKeySpki: string;
    };
  };
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
  /** Сквозное шифрование; при наличии `text` с секретом не используется. */
  e2ee?: ChatMessageE2eePayload;
  createdAt: string;
  readAt: string | null;
  updatedAt?: string | null;
  attachments?: ChatAttachment[];
  /** Статус серверной нормализации медиа (webm/mov → mp4/m4a). */
  mediaNorm?: ChatMediaNorm;
  /** Одноразовое событие синхронизации fullscreen emoji-эффекта. */
  emojiBurst?: ChatEmojiBurstEvent;
  replyTo?: ReplyContext;
  deliveryStatus?: "sending" | "sent" | "failed";
  isDeleted?: boolean;
  forwardedFrom?: {
    name: string;
  };
  reactions?: Record<string, (string | ReactionDetail)[]>;
  lastReactionTimestamp?: string;
  threadCount?: number;
  /** Участники, которые уже отвечали в этой ветке (для аватаров рядом с меткой ответов). */
  threadParticipantIds?: string[];
  unreadThreadCounts?: Record<string, number>;
  lastThreadMessageText?: string;
  lastThreadMessageSenderId?: string;
  lastThreadMessageTimestamp?: string;
  locationShare?: ChatLocationShare;
  /** Документ: conversations/{conversationId}/polls/{chatPollId} (структура как MeetingPoll). */
  chatPollId?: string;
  /** Phase 8: system-event маркер (E2EE включен/ротация/устройства и т.п.).
   *  Рендерится вместо обычного bubble как разделитель в timeline. */
  systemEvent?: ChatSystemEvent;
};

/** Phase 8 (§9.4 RFC E2EE v2): типизированные system-маркеры timeline'а. */
export type ChatSystemEventType =
  | 'e2ee.v2.enabled'
  | 'e2ee.v2.epoch.rotated'
  | 'e2ee.v2.device.added'
  | 'e2ee.v2.device.revoked'
  | 'e2ee.v2.fingerprint.changed';

export type ChatSystemEvent = {
  type: ChatSystemEventType;
  /** Метаданные для рендера: имя актора, label устройства и пр. */
  data?: {
    actorUserId?: string;
    actorName?: string;
    deviceLabel?: string;
    deviceId?: string;
    epoch?: number;
    previousFingerprint?: string;
    nextFingerprint?: string;
  };
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

/** Избранные сообщения пользователя: `users/{userId}/starredChatMessages/{docId}` (id — см. `buildStarredMessageDocId`). */
export type StarredChatMessageDoc = {
  conversationId: string;
  messageId: string;
  createdAt: string;
  /** Обрезка текста на момент добавления (без HTML). */
  previewText?: string;
};

/**
 * Персональные настройки конкретной переписки: `users/{userId}/chatConversationPrefs/{conversationId}`.
 */
export type UserChatConversationPrefs = {
  conversationId: string;
  /** Не беспокоить по уведомлениям для этого чата (локально для аккаунта). */
  notificationsMuted?: boolean;
  /**
   * Показывать превью текста в уведомлениях для этого чата.
   * null/undefined — как в глобальных настройках уведомлений.
   */
  notificationShowPreview?: boolean | null;
  /** Фон этой переписки; null/пусто — наследовать из глобальных настроек чата. */
  chatWallpaper?: string | null;
  /** Не отправлять собеседнику отметки «прочитано» в этом чате. */
  suppressReadReceipts?: boolean;
  updatedAt?: string;
};

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
  /** IANA TZ для интерпретации тихих часов на сервере (подставляется с клиента). */
  quietHoursTimeZone?: string;
};

/**
 * Кто может добавить пользователя в групповой чат (обычные пользователи; роль admin в приложении не ограничена).
 */
export type GroupInvitePolicy = "everyone" | "contacts" | "none";

export type PrivacySettings = {
  showOnlineStatus: boolean;
  showLastSeen: boolean;
  showReadReceipts: boolean;
  /**
   * Новые личные чаты: при создании попытаться включить E2E, если у собеседника опубликован ключ.
   * Не гарантирует E2E без ключа у второй стороны.
   */
  e2eeForNewDirectChats?: boolean;
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
