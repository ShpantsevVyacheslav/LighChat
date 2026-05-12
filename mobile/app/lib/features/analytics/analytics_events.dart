/// Каталог продуктовой аналитики LighChat (Flutter).
///
/// Единый источник истины — синхронизируется с:
///   src/lib/analytics/events.ts (web)
///   functions/src/analytics/events.ts (server)
///
/// Правила:
///   - snake_case, < 40 символов, GA4-совместимо;
///   - НИКАКОЙ PII в параметрах;
///   - значения параметров — enum-литералы либо bucket'ы.
library analytics_events;

class AnalyticsEvents {
  AnalyticsEvents._();

  // Category 1: Acquisition & Auth
  static const appFirstOpen = 'app_first_open';
  static const landingView = 'landing_view';
  static const ctaClick = 'cta_click';
  static const authScreenView = 'auth_screen_view';
  static const signUpAttempt = 'sign_up_attempt';
  static const signUpSuccess = 'sign_up_success';
  static const signUpFailure = 'sign_up_failure';
  static const loginAttempt = 'login_attempt';
  static const loginSuccess = 'login_success';
  static const loginFailure = 'login_failure';
  static const profileCompletionStep = 'profile_completion_step';
  static const pwaInstallPromptShown = 'pwa_install_prompt_shown';
  static const pwaInstalled = 'pwa_installed';

  // Category 2: Engagement
  static const chatCreated = 'chat_created';
  static const chatOpened = 'chat_opened';
  static const messageSent = 'message_sent';
  static const messageFirstSentInChat = 'message_first_sent_in_chat';
  static const reactionAdded = 'reaction_added';
  static const pollCreated = 'poll_created';
  static const callStarted = 'call_started';
  static const callEnded = 'call_ended';
  static const meetingCreated = 'meeting_created';
  static const meetingJoined = 'meeting_joined';
  static const meetingLeft = 'meeting_left';
  static const gameStarted = 'game_started';
  static const gameFinished = 'game_finished';
  static const secretChatEnabled = 'secret_chat_enabled';
  static const e2eePairingCompleted = 'e2ee_pairing_completed';
  static const contactAdded = 'contact_added';
  static const fileShared = 'file_shared';
  static const voiceMessageRecorded = 'voice_message_recorded';
  static const settingsChanged = 'settings_changed';

  // Category 3: Navigation & Funnels
  static const pageView = 'page_view';
  static const screenView = 'screen_view';
  static const searchPerformed = 'search_performed';
  static const notificationReceived = 'notification_received';
  static const notificationOpened = 'notification_opened';
  static const deepLinkOpened = 'deep_link_opened';
  static const tabSwitched = 'tab_switched';

  // Category 4: Retention & Platform
  static const sessionStart = 'session_start';
  static const appOpen = 'app_open';
  static const appBackgrounded = 'app_backgrounded';
  static const crash = 'crash';
  static const featureUnavailable = 'feature_unavailable';
  static const permissionPrompt = 'permission_prompt';
  static const appUpdateAvailable = 'app_update_available';
  static const appUpdated = 'app_updated';

  // Category 5: Sharing & Invites
  static const contactShared = 'contact_shared';
  static const chatInviteLinkCreated = 'chat_invite_link_created';
  static const chatInviteLinkOpened = 'chat_invite_link_opened';
  static const chatInviteLinkRedeemed = 'chat_invite_link_redeemed';
  static const externalInviteSent = 'external_invite_sent';
  static const externalInviteAccepted = 'external_invite_accepted';
  static const referralSignup = 'referral_signup';
  static const meetingGuestJoined = 'meeting_guest_joined';
  static const meetingGuestCount = 'meeting_guest_count';
  static const qrScanned = 'qr_scanned';

  // Category 6: Errors & Quality
  static const errorOccurred = 'error_occurred';
  static const networkOfflineEntered = 'network_offline_entered';
  static const networkOfflineExited = 'network_offline_exited';
  static const firestorePermissionDenied = 'firestore_permission_denied';
  static const mediaUploadFailure = 'media_upload_failure';
  static const callConnectionFailure = 'call_connection_failure';
  static const callQualityReport = 'call_quality_report';
  static const webrtcReconnect = 'webrtc_reconnect';
  static const pushDeliveryFailed = 'push_delivery_failed';
  static const e2eeFailure = 'e2ee_failure';

  // Category 7: Localization & Settings
  static const languageChanged = 'language_changed';
  static const themeChanged = 'theme_changed';
  static const notificationSettingsChanged = 'notification_settings_changed';
  static const accountDeleted = 'account_deleted';
  static const logout = 'logout';

  // Category 8: Messaging Deep
  static const messageEdited = 'message_edited';
  static const messageDeleted = 'message_deleted';
  static const messagePinned = 'message_pinned';
  static const messageForwarded = 'message_forwarded';
  static const messageReplied = 'message_replied';
  static const voiceMessagePlayed = 'voice_message_played';
  static const mediaViewed = 'media_viewed';
  static const mediaDownloaded = 'media_downloaded';
  static const searchZeroResults = 'search_zero_results';
  static const messageTranslated = 'message_translated';

  // Category 9: Call/Meeting Deep
  static const screenShareStarted = 'screen_share_started';
  static const screenShareStopped = 'screen_share_stopped';
  static const micToggled = 'mic_toggled';
  static const cameraToggled = 'camera_toggled';
  static const bgBlurToggled = 'bg_blur_toggled';
  static const meetingPollVoted = 'meeting_poll_voted';
  static const meetingJoinRequestSent = 'meeting_join_request_sent';
  static const meetingJoinRequestDecision = 'meeting_join_request_decision';

  // Category 10: Monetization
  static const paywallViewed = 'paywall_viewed';
  static const planSelected = 'plan_selected';
  static const purchaseStarted = 'purchase_started';
  static const purchaseCompleted = 'purchase_completed';
  static const purchaseFailed = 'purchase_failed';
  static const subscriptionRenewed = 'subscription_renewed';
  static const subscriptionCancelled = 'subscription_cancelled';
  static const storageQuotaWarning = 'storage_quota_warning';
  static const storageQuotaExceeded = 'storage_quota_exceeded';

  // Category 11: Bots & Platform
  static const botCommandUsed = 'bot_command_used';
  static const botAddedToChat = 'bot_added_to_chat';
  static const featureFlagExposed = 'feature_flag_exposed';
  static const cspViolationReceived = 'csp_violation_received';
  static const adminActionPerformed = 'admin_action_performed';
}

class UserProperties {
  UserProperties._();
  static const signupMethod = 'signup_method';
  static const signupCountry = 'signup_country';
  static const primaryPlatform = 'primary_platform';
  static const isAdmin = 'is_admin';
  static const hasPremium = 'has_premium';
  static const accountAgeDaysBucket = 'account_age_days_bucket';
  static const totalChatsBucket = 'total_chats_bucket';
  static const e2eeEnabled = 'e2ee_enabled';
  static const appLanguage = 'app_language';
  static const appTheme = 'app_theme';
  static const osVersionMajor = 'os_version_major';
  static const notificationPermState = 'notification_perm_state';
  static const isReferredUser = 'is_referred_user';
  static const activeSubscriptionPlan = 'active_subscription_plan';
  static const subscriptionChannel = 'subscription_channel';
}

String durationBucketMs(int ms) {
  if (ms < 10000) return 'lt_10s';
  if (ms < 60000) return 'lt_1m';
  if (ms < 300000) return 'lt_5m';
  if (ms < 1800000) return 'lt_30m';
  return 'gte_30m';
}

String sizeBucketBytes(int bytes) {
  if (bytes < 100 * 1024) return 'lt_100kb';
  if (bytes < 1024 * 1024) return 'lt_1mb';
  if (bytes < 10 * 1024 * 1024) return 'lt_10mb';
  if (bytes < 100 * 1024 * 1024) return 'lt_100mb';
  return 'gte_100mb';
}

String countBucket(int n) {
  if (n <= 0) return '0';
  if (n == 1) return '1';
  if (n <= 5) return '2_5';
  if (n <= 20) return '6_20';
  if (n <= 100) return '21_100';
  return 'gt_100';
}

String daysBucket(int days) {
  if (days <= 0) return 'd0';
  if (days == 1) return 'd1';
  if (days <= 7) return 'd2_7';
  if (days <= 30) return 'd8_30';
  if (days <= 90) return 'd31_90';
  return 'gt_90';
}
