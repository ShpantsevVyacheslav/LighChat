/**
 * Каталог продуктовой аналитики LighChat (server-side).
 *
 * Source-of-truth координируется с:
 *   src/lib/analytics/events.ts (web)
 *   mobile/app/lib/features/analytics/analytics_events.dart (flutter)
 */

export const AnalyticsEvents = {
  // Category 1
  appFirstOpen: "app_first_open",
  landingView: "landing_view",
  ctaClick: "cta_click",
  authScreenView: "auth_screen_view",
  signUpAttempt: "sign_up_attempt",
  signUpSuccess: "sign_up_success",
  signUpFailure: "sign_up_failure",
  loginAttempt: "login_attempt",
  loginSuccess: "login_success",
  loginFailure: "login_failure",
  profileCompletionStep: "profile_completion_step",
  pwaInstallPromptShown: "pwa_install_prompt_shown",
  pwaInstalled: "pwa_installed",

  // Category 2
  chatCreated: "chat_created",
  chatOpened: "chat_opened",
  messageSent: "message_sent",
  messageFirstSentInChat: "message_first_sent_in_chat",
  reactionAdded: "reaction_added",
  pollCreated: "poll_created",
  callStarted: "call_started",
  callEnded: "call_ended",
  meetingCreated: "meeting_created",
  meetingJoined: "meeting_joined",
  meetingLeft: "meeting_left",
  gameStarted: "game_started",
  gameFinished: "game_finished",
  secretChatEnabled: "secret_chat_enabled",
  e2eePairingCompleted: "e2ee_pairing_completed",
  contactAdded: "contact_added",
  fileShared: "file_shared",
  voiceMessageRecorded: "voice_message_recorded",
  settingsChanged: "settings_changed",

  // Category 3
  pageView: "page_view",
  screenView: "screen_view",
  searchPerformed: "search_performed",
  notificationReceived: "notification_received",
  notificationOpened: "notification_opened",
  deepLinkOpened: "deep_link_opened",
  tabSwitched: "tab_switched",

  // Category 4
  sessionStart: "session_start",
  appOpen: "app_open",
  appBackgrounded: "app_backgrounded",
  crash: "crash",
  featureUnavailable: "feature_unavailable",
  permissionPrompt: "permission_prompt",
  appUpdateAvailable: "app_update_available",
  appUpdated: "app_updated",

  // Category 5
  contactShared: "contact_shared",
  chatInviteLinkCreated: "chat_invite_link_created",
  chatInviteLinkOpened: "chat_invite_link_opened",
  chatInviteLinkRedeemed: "chat_invite_link_redeemed",
  externalInviteSent: "external_invite_sent",
  externalInviteAccepted: "external_invite_accepted",
  referralSignup: "referral_signup",
  meetingGuestJoined: "meeting_guest_joined",
  meetingGuestCount: "meeting_guest_count",
  qrScanned: "qr_scanned",

  // Category 6
  errorOccurred: "error_occurred",
  networkOfflineEntered: "network_offline_entered",
  networkOfflineExited: "network_offline_exited",
  firestorePermissionDenied: "firestore_permission_denied",
  mediaUploadFailure: "media_upload_failure",
  callConnectionFailure: "call_connection_failure",
  callQualityReport: "call_quality_report",
  webrtcReconnect: "webrtc_reconnect",
  pushDeliveryFailed: "push_delivery_failed",
  e2eeFailure: "e2ee_failure",

  // Category 7
  languageChanged: "language_changed",
  themeChanged: "theme_changed",
  notificationSettingsChanged: "notification_settings_changed",
  accountDeleted: "account_deleted",
  logout: "logout",

  // Category 8
  messageEdited: "message_edited",
  messageDeleted: "message_deleted",
  messagePinned: "message_pinned",
  messageForwarded: "message_forwarded",
  messageReplied: "message_replied",
  voiceMessagePlayed: "voice_message_played",
  mediaViewed: "media_viewed",
  mediaDownloaded: "media_downloaded",
  searchZeroResults: "search_zero_results",
  messageTranslated: "message_translated",

  // Category 9
  screenShareStarted: "screen_share_started",
  screenShareStopped: "screen_share_stopped",
  micToggled: "mic_toggled",
  cameraToggled: "camera_toggled",
  bgBlurToggled: "bg_blur_toggled",
  meetingPollVoted: "meeting_poll_voted",
  meetingJoinRequestSent: "meeting_join_request_sent",
  meetingJoinRequestDecision: "meeting_join_request_decision",

  // Category 10
  paywallViewed: "paywall_viewed",
  planSelected: "plan_selected",
  purchaseStarted: "purchase_started",
  purchaseCompleted: "purchase_completed",
  purchaseFailed: "purchase_failed",
  subscriptionRenewed: "subscription_renewed",
  subscriptionCancelled: "subscription_cancelled",
  storageQuotaWarning: "storage_quota_warning",
  storageQuotaExceeded: "storage_quota_exceeded",

  // Category 11
  botCommandUsed: "bot_command_used",
  botAddedToChat: "bot_added_to_chat",
  featureFlagExposed: "feature_flag_exposed",
  cspViolationReceived: "csp_violation_received",
  adminActionPerformed: "admin_action_performed",
} as const;

export type AnalyticsEventName =
  (typeof AnalyticsEvents)[keyof typeof AnalyticsEvents];

export const ALLOWED_EVENTS: ReadonlySet<string> = new Set(
  Object.values(AnalyticsEvents),
);

export const ALLOWED_PLATFORMS: ReadonlySet<string> = new Set([
  "web",
  "pwa",
  "ios",
  "android",
  "macos",
  "windows",
  "linux",
]);

export function durationBucketMs(ms: number): string {
  if (ms < 10_000) return "lt_10s";
  if (ms < 60_000) return "lt_1m";
  if (ms < 5 * 60_000) return "lt_5m";
  if (ms < 30 * 60_000) return "lt_30m";
  return "gte_30m";
}

export function countBucket(n: number): string {
  if (n <= 0) return "0";
  if (n === 1) return "1";
  if (n <= 5) return "2_5";
  if (n <= 20) return "6_20";
  if (n <= 100) return "21_100";
  return "gt_100";
}

export function daysBucket(days: number): string {
  if (days <= 0) return "d0";
  if (days === 1) return "d1";
  if (days <= 7) return "d2_7";
  if (days <= 30) return "d8_30";
  if (days <= 90) return "d31_90";
  return "gt_90";
}
