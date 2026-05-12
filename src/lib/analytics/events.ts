/**
 * Каталог продуктовой аналитики LighChat (web).
 *
 * Единый источник истины — координируется с:
 *   mobile/app/lib/features/analytics/analytics_events.dart
 *   functions/src/analytics/events.ts
 *
 * Правила:
 *   - snake_case, < 40 символов, GA4-совместимо;
 *   - НИКАКОЙ PII в параметрах (никаких email/phone/name/uid в plain — только хэш или `_bucket`);
 *   - значения параметров — enum-литералы либо bucket'ы (см. `Bucket*` ниже);
 *   - крупные кардинальности (chatId/messageId/etc.) запрещены — GA4 имеет лимит cardinality.
 */

export type Platform = 'web' | 'pwa' | 'ios' | 'android' | 'macos' | 'windows' | 'linux';

export type ChatType = 'personal' | 'group' | 'secret';
export type CallType = 'audio' | 'video';
export type MessageKind = 'text' | 'media' | 'voice' | 'file' | 'poll' | 'sticker';
export type SignupMethod =
  | 'email'
  | 'google'
  | 'apple'
  | 'telegram'
  | 'yandex'
  | 'qr'
  | 'phone_otp';

export type DurationBucket = 'lt_10s' | 'lt_1m' | 'lt_5m' | 'lt_30m' | 'gte_30m';
export type SizeBucket = 'lt_100kb' | 'lt_1mb' | 'lt_10mb' | 'lt_100mb' | 'gte_100mb';
export type CountBucket = '0' | '1' | '2_5' | '6_20' | '21_100' | 'gt_100';
export type DaysBucket = 'd0' | 'd1' | 'd2_7' | 'd8_30' | 'd31_90' | 'gt_90';

export type ErrorCategory =
  | 'auth'
  | 'network'
  | 'firestore'
  | 'webrtc'
  | 'media_upload'
  | 'media_decrypt'
  | 'push'
  | 'payment'
  | 'e2ee'
  | 'unknown';

export type InviteChannel =
  | 'sms'
  | 'email'
  | 'copy_link'
  | 'share_sheet'
  | 'whatsapp'
  | 'telegram'
  | 'other';

export type PurchaseChannel = 'stripe' | 'appstore' | 'playstore';

/* ------------------------------------------------------------------ */
/* Event names                                                         */
/* ------------------------------------------------------------------ */

export const AnalyticsEvents = {
  // Category 1: Acquisition & Auth
  appFirstOpen: 'app_first_open',
  landingView: 'landing_view',
  ctaClick: 'cta_click',
  authScreenView: 'auth_screen_view',
  signUpAttempt: 'sign_up_attempt',
  signUpSuccess: 'sign_up_success',
  signUpFailure: 'sign_up_failure',
  loginAttempt: 'login_attempt',
  loginSuccess: 'login_success',
  loginFailure: 'login_failure',
  profileCompletionStep: 'profile_completion_step',
  pwaInstallPromptShown: 'pwa_install_prompt_shown',
  pwaInstalled: 'pwa_installed',

  // Category 2: Engagement
  chatCreated: 'chat_created',
  chatOpened: 'chat_opened',
  messageSent: 'message_sent',
  messageFirstSentInChat: 'message_first_sent_in_chat',
  reactionAdded: 'reaction_added',
  pollCreated: 'poll_created',
  callStarted: 'call_started',
  callEnded: 'call_ended',
  meetingCreated: 'meeting_created',
  meetingJoined: 'meeting_joined',
  meetingLeft: 'meeting_left',
  gameStarted: 'game_started',
  gameFinished: 'game_finished',
  secretChatEnabled: 'secret_chat_enabled',
  e2eePairingCompleted: 'e2ee_pairing_completed',
  contactAdded: 'contact_added',
  fileShared: 'file_shared',
  voiceMessageRecorded: 'voice_message_recorded',
  settingsChanged: 'settings_changed',

  // Category 3: Navigation & Funnels
  pageView: 'page_view',
  screenView: 'screen_view',
  searchPerformed: 'search_performed',
  notificationReceived: 'notification_received',
  notificationOpened: 'notification_opened',
  deepLinkOpened: 'deep_link_opened',
  tabSwitched: 'tab_switched',

  // Category 4: Retention & Platform
  sessionStart: 'session_start',
  appOpen: 'app_open',
  appBackgrounded: 'app_backgrounded',
  crash: 'crash',
  featureUnavailable: 'feature_unavailable',
  permissionPrompt: 'permission_prompt',
  appUpdateAvailable: 'app_update_available',
  appUpdated: 'app_updated',

  // Category 5: Sharing & Invites
  contactShared: 'contact_shared',
  chatInviteLinkCreated: 'chat_invite_link_created',
  chatInviteLinkOpened: 'chat_invite_link_opened',
  chatInviteLinkRedeemed: 'chat_invite_link_redeemed',
  externalInviteSent: 'external_invite_sent',
  externalInviteAccepted: 'external_invite_accepted',
  referralSignup: 'referral_signup',
  meetingGuestJoined: 'meeting_guest_joined',
  meetingGuestCount: 'meeting_guest_count',
  qrScanned: 'qr_scanned',

  // Category 6: Errors & Quality
  errorOccurred: 'error_occurred',
  networkOfflineEntered: 'network_offline_entered',
  networkOfflineExited: 'network_offline_exited',
  firestorePermissionDenied: 'firestore_permission_denied',
  mediaUploadFailure: 'media_upload_failure',
  callConnectionFailure: 'call_connection_failure',
  callQualityReport: 'call_quality_report',
  webrtcReconnect: 'webrtc_reconnect',
  pushDeliveryFailed: 'push_delivery_failed',
  e2eeFailure: 'e2ee_failure',

  // Category 7: Localization & Settings
  languageChanged: 'language_changed',
  themeChanged: 'theme_changed',
  notificationSettingsChanged: 'notification_settings_changed',
  accountDeleted: 'account_deleted',
  logout: 'logout',

  // Category 8: Messaging Deep
  messageEdited: 'message_edited',
  messageDeleted: 'message_deleted',
  messagePinned: 'message_pinned',
  messageForwarded: 'message_forwarded',
  messageReplied: 'message_replied',
  voiceMessagePlayed: 'voice_message_played',
  mediaViewed: 'media_viewed',
  mediaDownloaded: 'media_downloaded',
  searchZeroResults: 'search_zero_results',
  messageTranslated: 'message_translated',

  // Category 9: Call/Meeting Deep
  screenShareStarted: 'screen_share_started',
  screenShareStopped: 'screen_share_stopped',
  micToggled: 'mic_toggled',
  cameraToggled: 'camera_toggled',
  bgBlurToggled: 'bg_blur_toggled',
  meetingPollVoted: 'meeting_poll_voted',
  meetingJoinRequestSent: 'meeting_join_request_sent',
  meetingJoinRequestDecision: 'meeting_join_request_decision',

  // Category 10: Monetization
  paywallViewed: 'paywall_viewed',
  planSelected: 'plan_selected',
  purchaseStarted: 'purchase_started',
  purchaseCompleted: 'purchase_completed',
  purchaseFailed: 'purchase_failed',
  subscriptionRenewed: 'subscription_renewed',
  subscriptionCancelled: 'subscription_cancelled',
  storageQuotaWarning: 'storage_quota_warning',
  storageQuotaExceeded: 'storage_quota_exceeded',

  // Category 11: Bots & Platform
  botCommandUsed: 'bot_command_used',
  botAddedToChat: 'bot_added_to_chat',
  featureFlagExposed: 'feature_flag_exposed',
  cspViolationReceived: 'csp_violation_received',
  adminActionPerformed: 'admin_action_performed',
} as const;

export type AnalyticsEventName = (typeof AnalyticsEvents)[keyof typeof AnalyticsEvents];

/* ------------------------------------------------------------------ */
/* User properties                                                     */
/* ------------------------------------------------------------------ */

export const UserProperties = {
  signupMethod: 'signup_method',
  signupCountry: 'signup_country',
  primaryPlatform: 'primary_platform',
  isAdmin: 'is_admin',
  hasPremium: 'has_premium',
  accountAgeDaysBucket: 'account_age_days_bucket',
  totalChatsBucket: 'total_chats_bucket',
  e2eeEnabled: 'e2ee_enabled',
  appLanguage: 'app_language',
  appTheme: 'app_theme',
  osVersionMajor: 'os_version_major',
  notificationPermState: 'notification_perm_state',
  isReferredUser: 'is_referred_user',
  activeSubscriptionPlan: 'active_subscription_plan',
  subscriptionChannel: 'subscription_channel',
} as const;

export type UserPropertyName = (typeof UserProperties)[keyof typeof UserProperties];

/* ------------------------------------------------------------------ */
/* Param shape (loose — typing is enforced by helper wrappers, not by  */
/* the raw transport. GA4 supports up to 25 params per event.)         */
/* ------------------------------------------------------------------ */

export type AnalyticsParams = Record<
  string,
  string | number | boolean | undefined | null
>;

/* ------------------------------------------------------------------ */
/* Helpers                                                             */
/* ------------------------------------------------------------------ */

export function durationBucket(ms: number): DurationBucket {
  if (ms < 10_000) return 'lt_10s';
  if (ms < 60_000) return 'lt_1m';
  if (ms < 5 * 60_000) return 'lt_5m';
  if (ms < 30 * 60_000) return 'lt_30m';
  return 'gte_30m';
}

export function sizeBucket(bytes: number): SizeBucket {
  if (bytes < 100 * 1024) return 'lt_100kb';
  if (bytes < 1024 * 1024) return 'lt_1mb';
  if (bytes < 10 * 1024 * 1024) return 'lt_10mb';
  if (bytes < 100 * 1024 * 1024) return 'lt_100mb';
  return 'gte_100mb';
}

export function countBucket(n: number): CountBucket {
  if (n <= 0) return '0';
  if (n === 1) return '1';
  if (n <= 5) return '2_5';
  if (n <= 20) return '6_20';
  if (n <= 100) return '21_100';
  return 'gt_100';
}

export function daysBucket(days: number): DaysBucket {
  if (days <= 0) return 'd0';
  if (days === 1) return 'd1';
  if (days <= 7) return 'd2_7';
  if (days <= 30) return 'd8_30';
  if (days <= 90) return 'd31_90';
  return 'gt_90';
}

export function detectWebPlatform(): Platform {
  if (typeof window === 'undefined') return 'web';
  const mql = window.matchMedia?.('(display-mode: standalone)');
  if (mql?.matches || (window.navigator as { standalone?: boolean }).standalone) {
    return 'pwa';
  }
  return 'web';
}
