// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get secret_chat_title => 'Secret chat';

  @override
  String get secret_chats_title => 'Secret Chats';

  @override
  String get secret_chat_locked_title => 'Secret chat is locked';

  @override
  String get secret_chat_locked_subtitle =>
      'Enter your PIN to unlock and view messages.';

  @override
  String get secret_chat_unlock_title => 'Unlock secret chat';

  @override
  String get secret_chat_unlock_subtitle =>
      'PIN is required to open this chat.';

  @override
  String get secret_chat_unlock_action => 'Unlock';

  @override
  String get secret_chat_set_pin_and_unlock => 'Set PIN and unlock';

  @override
  String get secret_chat_pin_label => 'PIN (4 digits)';

  @override
  String get secret_chat_pin_invalid => 'Enter a 4-digit PIN';

  @override
  String get secret_chat_already_exists =>
      'Secret chat with this user already exists.';

  @override
  String get secret_chat_exists_badge => 'Created';

  @override
  String get secret_chat_unlock_failed => 'Unable to unlock. Please try again.';

  @override
  String get secret_chat_action_not_allowed =>
      'This action is not allowed in a secret chat';

  @override
  String get secret_chat_remember_pin => 'Remember PIN on this device';

  @override
  String get secret_chat_unlock_biometric => 'Unlock with biometrics';

  @override
  String get secret_chat_biometric_reason => 'Unlock secret chat';

  @override
  String get secret_chat_biometric_no_saved_pin =>
      'Enter PIN once to enable biometric unlock';

  @override
  String get secret_chat_ttl_title => 'Secret chat lifetime';

  @override
  String get secret_chat_settings_title => 'Secret chat settings';

  @override
  String get secret_chat_settings_subtitle =>
      'Lifetime, access, and restrictions';

  @override
  String get secret_chat_settings_not_secret =>
      'This chat is not a secret chat';

  @override
  String get secret_chat_settings_ttl => 'Lifetime';

  @override
  String secret_chat_settings_time_left(Object value) {
    return 'Time left: $value';
  }

  @override
  String secret_chat_settings_expires_at(Object iso) {
    return 'Expires at: $iso';
  }

  @override
  String get secret_chat_settings_unlock_grant_ttl => 'Unlock duration';

  @override
  String get secret_chat_settings_unlock_grant_ttl_subtitle =>
      'How long access stays active after unlocking';

  @override
  String get secret_chat_settings_no_copy => 'Disable copying';

  @override
  String get secret_chat_settings_no_forward => 'Disable forwarding';

  @override
  String get secret_chat_settings_no_save => 'Disable saving media';

  @override
  String get secret_chat_settings_screenshot_protection =>
      'Screenshot protection (Android)';

  @override
  String get secret_chat_settings_media_views => 'Media view limits';

  @override
  String get secret_chat_settings_media_views_subtitle =>
      'Best-effort limits for recipient views';

  @override
  String get secret_chat_media_type_image => 'Images';

  @override
  String get secret_chat_media_type_video => 'Videos';

  @override
  String get secret_chat_media_type_voice => 'Voice messages';

  @override
  String get secret_chat_media_type_location => 'Location';

  @override
  String get secret_chat_media_type_file => 'Files';

  @override
  String get secret_chat_media_views_unlimited => 'Unlimited';

  @override
  String get secret_chat_compose_create => 'Create secret chat';

  @override
  String get secret_chat_compose_vault_pin_subtitle =>
      'Optional: set a 4-digit vault PIN used for secret inbox unlock (stored on this device for biometrics when enabled).';

  @override
  String get secret_chat_compose_require_unlock_pin =>
      'Require PIN to open this chat';

  @override
  String get secret_chat_settings_read_only_hint =>
      'These settings are fixed at creation and cannot be changed.';

  @override
  String get secret_chat_settings_delete => 'Delete secret chat';

  @override
  String get secret_chat_settings_delete_confirm_title =>
      'Delete this secret chat?';

  @override
  String get secret_chat_settings_delete_confirm_body =>
      'Messages and media will be removed for both participants.';

  @override
  String get privacy_secret_vault_title => 'Secret vault';

  @override
  String get privacy_secret_vault_subtitle =>
      'Global PIN and biometric checks for entering secret chats.';

  @override
  String get privacy_secret_vault_change_pin => 'Set or change vault PIN';

  @override
  String get privacy_secret_vault_change_pin_subtitle =>
      'If PIN already exists, confirm using old PIN or biometrics.';

  @override
  String get privacy_secret_vault_bio_subtitle =>
      'Run biometric check and validate saved local PIN.';

  @override
  String get privacy_secret_vault_bio_reason =>
      'Confirm access to secret chats';

  @override
  String get privacy_secret_vault_current_pin => 'Current PIN';

  @override
  String get privacy_secret_vault_new_pin => 'New PIN';

  @override
  String get privacy_secret_vault_repeat_pin => 'Repeat new PIN';

  @override
  String get privacy_secret_vault_pin_mismatch => 'PINs do not match';

  @override
  String get privacy_secret_vault_pin_updated => 'Vault PIN updated';

  @override
  String get privacy_secret_vault_bio_unavailable =>
      'Biometric authentication is not available on this device';

  @override
  String get privacy_secret_vault_bio_verified => 'Biometric check passed';

  @override
  String get privacy_secret_vault_setup_required =>
      'Set up PIN or biometric access in Privacy first.';

  @override
  String get privacy_secret_vault_network_timeout =>
      'Network timeout. Please try again.';

  @override
  String privacy_secret_vault_error(Object error) {
    return 'Secret vault error: $error';
  }

  @override
  String get tournament_title => 'Tournament';

  @override
  String get tournament_subtitle => 'Standings and game series';

  @override
  String get tournament_new_game => 'New game';

  @override
  String get tournament_standings => 'Standings';

  @override
  String get tournament_standings_empty => 'No results yet';

  @override
  String get tournament_games => 'Games';

  @override
  String get tournament_games_empty => 'No games yet';

  @override
  String tournament_points(Object pts) {
    return '$pts pts';
  }

  @override
  String tournament_games_played(Object n) {
    return '$n games';
  }

  @override
  String tournament_create_failed(Object err) {
    return 'Unable to create tournament: $err';
  }

  @override
  String tournament_create_game_failed(Object err) {
    return 'Unable to create game: $err';
  }

  @override
  String tournament_game_players(Object names) {
    return 'Players: $names';
  }

  @override
  String get tournament_game_result_draw => 'Result: draw';

  @override
  String tournament_game_result_loser(Object name) {
    return 'Result: durak — $name';
  }

  @override
  String tournament_game_place(Object place) {
    return 'Place $place';
  }

  @override
  String get durak_dm_lobby_banner =>
      'Your partner created a Durak lobby — join';

  @override
  String get durak_dm_lobby_open => 'Open lobby';

  @override
  String get conversation_game_lobby_cancel => 'End waiting';

  @override
  String conversation_game_lobby_cancel_failed(Object err) {
    return 'Unable to end waiting: $err';
  }

  @override
  String secret_chat_media_views_count(Object count) {
    return '$count views';
  }

  @override
  String secret_chat_settings_load_failed(Object error) {
    return 'Failed to load: $error';
  }

  @override
  String secret_chat_settings_save_failed(Object error) {
    return 'Failed to save: $error';
  }

  @override
  String get secret_chat_settings_reset_strict => 'Reset to strict defaults';

  @override
  String get secret_chat_settings_reset_strict_subtitle =>
      'Enables all restrictions and sets media view limits to 1';

  @override
  String get settings_language_title => 'Language';

  @override
  String get settings_language_system => 'System';

  @override
  String get settings_language_ru => 'Russian';

  @override
  String get settings_language_en => 'English';

  @override
  String get settings_language_hint_system =>
      'When “System” is selected, the app follows your device language settings.';

  @override
  String get account_menu_profile => 'Profile';

  @override
  String get account_menu_features => 'Features';

  @override
  String get account_menu_chat_settings => 'Chat settings';

  @override
  String get account_menu_notifications => 'Notifications';

  @override
  String get account_menu_privacy => 'Privacy';

  @override
  String get account_menu_devices => 'Devices';

  @override
  String get account_menu_blacklist => 'Blacklist';

  @override
  String get account_menu_language => 'Language';

  @override
  String get account_menu_storage => 'Storage';

  @override
  String get account_menu_theme => 'Theme';

  @override
  String get account_menu_sign_out => 'Sign out';

  @override
  String get storage_settings_title => 'Storage';

  @override
  String get storage_settings_subtitle =>
      'Control what data is cached on this device and clean up by chats or files.';

  @override
  String get storage_settings_total_label => 'Used on this device';

  @override
  String storage_settings_budget_label(Object gb) {
    return 'Cache limit: $gb GB';
  }

  @override
  String get storage_unit_gb => 'GB';

  @override
  String get storage_settings_clear_all_button => 'Clear all cache';

  @override
  String get storage_settings_trim_button => 'Trim to budget';

  @override
  String get storage_settings_policy_title => 'What to keep locally';

  @override
  String get storage_settings_budget_slider_title => 'Cache budget';

  @override
  String get storage_settings_breakdown_title => 'By data type';

  @override
  String get storage_settings_breakdown_empty => 'No local cached data yet.';

  @override
  String get storage_settings_chats_title => 'By chats';

  @override
  String get storage_settings_chats_empty => 'No chat-specific cache yet.';

  @override
  String storage_settings_chat_subtitle(Object count, Object size) {
    return '$count items · $size';
  }

  @override
  String get storage_settings_general_title => 'Unassigned cache';

  @override
  String get storage_settings_general_hint =>
      'Entries not linked to a specific chat (legacy/global cache).';

  @override
  String get storage_settings_general_empty => 'No shared cache entries.';

  @override
  String get storage_settings_chat_files_empty =>
      'No local files in this chat cache.';

  @override
  String get storage_settings_clear_chat_action => 'Clear chat cache';

  @override
  String get storage_settings_clear_all_title => 'Clear local cache?';

  @override
  String get storage_settings_clear_all_body =>
      'This will remove cached files, previews, drafts, and offline snapshots from this device.';

  @override
  String storage_settings_clear_chat_title(Object chat) {
    return 'Clear cache for “$chat”?';
  }

  @override
  String get storage_settings_clear_chat_body =>
      'Only this chat cache will be deleted. Messages in cloud stay intact.';

  @override
  String get storage_settings_snackbar_cleared => 'Local cache cleared';

  @override
  String get storage_settings_snackbar_budget_already_ok =>
      'Cache already fits the target budget';

  @override
  String storage_settings_snackbar_budget_trimmed(Object size) {
    return 'Freed: $size';
  }

  @override
  String get storage_settings_error_empty =>
      'Unable to build storage statistics';

  @override
  String get storage_category_e2ee_media => 'E2EE media cache';

  @override
  String get storage_category_e2ee_media_subtitle =>
      'Decrypted secret media files per chat for faster reopening.';

  @override
  String get storage_category_e2ee_text => 'E2EE text cache';

  @override
  String get storage_category_e2ee_text_subtitle =>
      'Decrypted text snippets per chat for instant rendering.';

  @override
  String get storage_category_drafts => 'Message drafts';

  @override
  String get storage_category_drafts_subtitle => 'Unsent draft text by chats.';

  @override
  String get storage_category_chat_list_snapshot => 'Offline chat list';

  @override
  String get storage_category_chat_list_snapshot_subtitle =>
      'Recent chat list snapshot for quick startup offline.';

  @override
  String get storage_category_profile_cards => 'Profile mini-cache';

  @override
  String get storage_category_profile_cards_subtitle =>
      'Names and avatars saved for faster UI.';

  @override
  String get storage_category_video_downloads => 'Downloaded video cache';

  @override
  String get storage_category_video_downloads_subtitle =>
      'Locally downloaded videos from gallery views.';

  @override
  String get storage_category_video_thumbs => 'Video preview frames';

  @override
  String get storage_category_video_thumbs_subtitle =>
      'Generated first-frame thumbnails for videos.';

  @override
  String get storage_category_chat_images => 'Chat photos';

  @override
  String get storage_category_chat_images_subtitle =>
      'Cached photos and stickers from open chats.';

  @override
  String get storage_category_stickers_gifs_emoji => 'Stickers, GIFs, emoji';

  @override
  String get storage_category_stickers_gifs_emoji_subtitle =>
      'Recent stickers and GIPHY (gifs/stickers/animated emoji) cache.';

  @override
  String get storage_category_network_images => 'Network image cache';

  @override
  String get storage_category_network_images_subtitle =>
      'Avatars, previews and other network-fetched images (libCachedImageData).';

  @override
  String get storage_media_type_video => 'Video';

  @override
  String get storage_media_type_photo => 'Photos';

  @override
  String get storage_media_type_audio => 'Audio';

  @override
  String get storage_media_type_files => 'Files';

  @override
  String get storage_media_type_other => 'Other';

  @override
  String storage_settings_device_usage(Object pct) {
    return 'Uses $pct% of cache budget';
  }

  @override
  String get storage_settings_clear_all_hint =>
      'All media will stay in cloud. You can re-download any time.';

  @override
  String get storage_settings_categories_title => 'By category';

  @override
  String storage_settings_clear_category_title(String category) {
    return 'Clear \"$category\"?';
  }

  @override
  String storage_settings_clear_category_body(String size) {
    return 'About $size will be freed. This cannot be undone.';
  }

  @override
  String get storage_auto_delete_title => 'Auto-delete cached media';

  @override
  String get storage_auto_delete_personal => 'Personal chats';

  @override
  String get storage_auto_delete_groups => 'Groups';

  @override
  String get storage_auto_delete_never => 'Never';

  @override
  String get storage_auto_delete_3_days => '3 days';

  @override
  String get storage_auto_delete_1_week => '1 week';

  @override
  String get storage_auto_delete_1_month => '1 month';

  @override
  String get storage_auto_delete_3_months => '3 months';

  @override
  String get storage_auto_delete_hint =>
      'Photos, videos and files you haven\'t opened during this period will be removed from the device to save space.';

  @override
  String storage_chat_detail_share(Object pct) {
    return 'This chat uses $pct% of your cache';
  }

  @override
  String get storage_chat_detail_media_tab => 'Media';

  @override
  String get storage_chat_detail_select_all => 'Select all';

  @override
  String get storage_chat_detail_deselect_all => 'Deselect all';

  @override
  String storage_chat_detail_clear_button(Object size) {
    return 'Clear cache $size';
  }

  @override
  String get storage_chat_detail_clear_button_empty => 'Select files to delete';

  @override
  String get storage_chat_detail_tab_empty => 'Nothing in this tab.';

  @override
  String get storage_chat_detail_delete_title => 'Delete selected files?';

  @override
  String storage_chat_detail_delete_body(Object count, Object size) {
    return '$count files ($size) will be removed from the device. Cloud copies stay intact.';
  }

  @override
  String get profile_delete_account => 'Delete account';

  @override
  String get profile_delete_account_confirm_title =>
      'Delete your account permanently?';

  @override
  String get profile_delete_account_confirm_body =>
      'Your account will be removed from Firebase Auth and all your Firestore documents will be deleted permanently. Your chats will remain visible to others in read-only mode.';

  @override
  String get profile_delete_account_confirm_action => 'Delete account';

  @override
  String profile_delete_account_error(Object error) {
    return 'Couldn’t delete the account: $error';
  }

  @override
  String get chat_readonly_deleted_user =>
      'Account deleted. This chat is read-only.';

  @override
  String get blacklist_empty => 'No blocked users';

  @override
  String get blacklist_action_unblock => 'Unblock';

  @override
  String get blacklist_unblock_confirm_title => 'Unblock?';

  @override
  String get blacklist_unblock_confirm_body =>
      'This user will be able to message you again (if contact policy allows) and see your profile in search.';

  @override
  String get blacklist_unblock_success => 'User unblocked';

  @override
  String blacklist_unblock_error(Object error) {
    return 'Couldn’t unblock: $error';
  }

  @override
  String get partner_profile_block_confirm_title => 'Block this user?';

  @override
  String get partner_profile_block_confirm_body =>
      'They won’t see a chat with you, can’t find you in search, or add you to contacts. You’ll disappear from their contacts. You’ll keep the chat history but can’t message them while they’re blocked.';

  @override
  String get partner_profile_block_action => 'Block';

  @override
  String get partner_profile_block_success => 'User blocked';

  @override
  String partner_profile_block_error(Object error) {
    return 'Couldn’t block: $error';
  }

  @override
  String get common_soon => 'Coming soon';

  @override
  String common_theme_prefix(Object label) {
    return 'Theme: $label';
  }

  @override
  String common_error_cannot_save_theme(Object error) {
    return 'Couldn’t save the theme: $error';
  }

  @override
  String common_error_cannot_sign_out(Object error) {
    return 'Couldn’t sign out: $error';
  }

  @override
  String account_error_profile(Object error) {
    return 'Profile error: $error';
  }

  @override
  String get notifications_title => 'Notifications';

  @override
  String get notifications_section_main => 'Main';

  @override
  String get notifications_mute_all_title => 'Turn off all';

  @override
  String get notifications_mute_all_subtitle => 'Disable all notifications.';

  @override
  String get notifications_sound_title => 'Sound';

  @override
  String get notifications_sound_subtitle => 'Play a sound for new messages.';

  @override
  String get notifications_preview_title => 'Preview';

  @override
  String get notifications_preview_subtitle =>
      'Show message text in notifications.';

  @override
  String get notifications_section_quiet_hours => 'Quiet hours';

  @override
  String get notifications_quiet_hours_subtitle =>
      'Notifications won’t bother you during this time window.';

  @override
  String get notifications_quiet_hours_enable_title => 'Enable quiet hours';

  @override
  String get notifications_reset_button => 'Reset settings';

  @override
  String notifications_error_cannot_save(Object error) {
    return 'Couldn’t save settings: $error';
  }

  @override
  String notifications_error_load(Object error) {
    return 'Couldn’t load notifications: $error';
  }

  @override
  String get privacy_title => 'Chat privacy';

  @override
  String privacy_error_cannot_save(Object error) {
    return 'Couldn’t save settings: $error';
  }

  @override
  String privacy_error_load(Object error) {
    return 'Couldn’t load privacy settings: $error';
  }

  @override
  String get privacy_e2ee_section => 'End‑to‑end encryption';

  @override
  String get privacy_e2ee_enable_for_all_chats => 'Enable E2EE for all chats';

  @override
  String get privacy_e2ee_what_encrypt => 'What gets encrypted in E2EE chats';

  @override
  String get privacy_e2ee_text => 'Message text';

  @override
  String get privacy_e2ee_media => 'Attachments (media/files)';

  @override
  String get privacy_my_devices_title => 'My devices';

  @override
  String get privacy_my_devices_subtitle =>
      'Devices with published keys. Rename or revoke access.';

  @override
  String get privacy_key_backup_title => 'Backup & key transfer';

  @override
  String get privacy_key_backup_subtitle =>
      'Create a password backup or transfer the key via QR.';

  @override
  String get privacy_visibility_section => 'Visibility';

  @override
  String get privacy_online_title => 'Online status';

  @override
  String get privacy_online_subtitle => 'Let others see when you’re online.';

  @override
  String get privacy_last_seen_title => 'Last seen';

  @override
  String get privacy_last_seen_subtitle => 'Show your last active time.';

  @override
  String get privacy_read_receipts_title => 'Read receipts';

  @override
  String get privacy_read_receipts_subtitle =>
      'Let senders know you’ve read a message.';

  @override
  String get privacy_group_invites_section => 'Group invites';

  @override
  String get privacy_group_invites_subtitle =>
      'Who can add you to group chats.';

  @override
  String get privacy_group_invites_everyone => 'Everyone';

  @override
  String get privacy_group_invites_contacts => 'Contacts only';

  @override
  String get privacy_group_invites_nobody => 'Nobody';

  @override
  String get privacy_global_search_section => 'Discoverability';

  @override
  String get privacy_global_search_subtitle =>
      'Who can find you by name among all users.';

  @override
  String get privacy_global_search_title => 'Global search';

  @override
  String get privacy_global_search_hint =>
      'If turned off, you won’t appear in “All users” when someone starts a new chat. You’ll still be visible to people who added you as a contact.';

  @override
  String get privacy_profile_for_others_section => 'Profile for others';

  @override
  String get privacy_profile_for_others_subtitle =>
      'What others can see in your profile.';

  @override
  String get privacy_email_subtitle => 'Your email address in your profile.';

  @override
  String get privacy_phone_title => 'Phone number';

  @override
  String get privacy_phone_subtitle => 'Shown in your profile and contacts.';

  @override
  String get privacy_birthdate_title => 'Date of birth';

  @override
  String get privacy_birthdate_subtitle => 'Your birthday field in profile.';

  @override
  String get privacy_about_title => 'About';

  @override
  String get privacy_about_subtitle => 'Your bio text in profile.';

  @override
  String get privacy_reset_button => 'Reset settings';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_create => 'Create';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_choose => 'Choose';

  @override
  String get common_save => 'Save';

  @override
  String get common_close => 'Close';

  @override
  String get common_nothing_found => 'Nothing found';

  @override
  String get common_retry => 'Retry';

  @override
  String get auth_login_email_label => 'Email';

  @override
  String get auth_login_password_label => 'Password';

  @override
  String get auth_login_password_hint => 'Password';

  @override
  String get auth_login_sign_in => 'Sign in';

  @override
  String get auth_login_forgot_password => 'Forgot password?';

  @override
  String get auth_login_error_enter_email_for_reset =>
      'Enter your email to reset your password';

  @override
  String get profile_title => 'Profile';

  @override
  String get profile_edit_tooltip => 'Edit';

  @override
  String get profile_full_name_label => 'Full name';

  @override
  String get profile_full_name_hint => 'Name';

  @override
  String get profile_username_label => 'Username';

  @override
  String get profile_email_label => 'Email';

  @override
  String get profile_phone_label => 'Phone';

  @override
  String get profile_birthdate_label => 'Date of birth';

  @override
  String get profile_about_label => 'About';

  @override
  String get profile_about_hint => 'A short bio';

  @override
  String get profile_password_toggle_show => 'Change password';

  @override
  String get profile_password_toggle_hide => 'Hide password change';

  @override
  String get profile_password_new_label => 'New password';

  @override
  String get profile_password_confirm_label => 'Confirm password';

  @override
  String get profile_password_tooltip_show => 'Show password';

  @override
  String get profile_password_tooltip_hide => 'Hide';

  @override
  String get profile_placeholder_username => 'username';

  @override
  String get profile_placeholder_email => 'name@example.com';

  @override
  String get profile_placeholder_phone => '+7900 000-00-00';

  @override
  String get profile_placeholder_birthdate => 'DD.MM.YYYY';

  @override
  String get profile_placeholder_password_dots => '••••••••';

  @override
  String get profile_password_error_fill_both =>
      'Fill in the new password and confirmation.';

  @override
  String get settings_chats_title => 'Chat settings';

  @override
  String get settings_chats_preview => 'Preview';

  @override
  String get settings_chats_outgoing => 'Outgoing messages';

  @override
  String get settings_chats_incoming => 'Incoming messages';

  @override
  String get settings_chats_font_size => 'Text size';

  @override
  String get settings_chats_font_small => 'Small';

  @override
  String get settings_chats_font_medium => 'Medium';

  @override
  String get settings_chats_font_large => 'Large';

  @override
  String get settings_chats_bubble_shape => 'Bubble shape';

  @override
  String get settings_chats_bubble_rounded => 'Rounded';

  @override
  String get settings_chats_bubble_square => 'Square';

  @override
  String get settings_chats_chat_background => 'Chat background';

  @override
  String get settings_chats_chat_background_pick_hint =>
      'Pick a photo or fine‑tune the background';

  @override
  String get settings_chats_advanced => 'Advanced';

  @override
  String get settings_chats_show_time => 'Show time';

  @override
  String get settings_chats_show_time_subtitle =>
      'Show message time under bubbles';

  @override
  String get settings_chats_reset => 'Reset settings';

  @override
  String settings_chats_error_cannot_save(Object error) {
    return 'Couldn’t save: $error';
  }

  @override
  String settings_chats_error_wallpaper_load(Object error) {
    return 'Couldn’t load background: $error';
  }

  @override
  String settings_chats_error_wallpaper_delete(Object error) {
    return 'Couldn’t delete background: $error';
  }

  @override
  String get settings_chats_wallpaper_delete_confirm_title =>
      'Delete background?';

  @override
  String get settings_chats_wallpaper_delete_confirm_body =>
      'This background will be removed from your list.';

  @override
  String settings_chats_icon_picker_title(Object label) {
    return 'Icon: “$label”';
  }

  @override
  String get settings_chats_icon_picker_search_hint => 'Search by name…';

  @override
  String get settings_chats_icon_color => 'Icon color';

  @override
  String get settings_chats_reset_icon_size => 'Reset size';

  @override
  String get settings_chats_reset_icon_stroke => 'Reset stroke';

  @override
  String get settings_chats_tile_background => 'Tile background';

  @override
  String get settings_chats_default_gradient => 'Default gradient';

  @override
  String get settings_chats_inherit_global => 'Use global settings';

  @override
  String get settings_chats_no_background => 'No background';

  @override
  String get settings_chats_no_background_on => 'No background (on)';

  @override
  String get chat_list_title => 'Chats';

  @override
  String get chat_list_search_hint => 'Search…';

  @override
  String get chat_list_loading_connecting => 'Connecting…';

  @override
  String get chat_list_loading_conversations => 'Loading conversations…';

  @override
  String get chat_list_loading_list => 'Loading chat list…';

  @override
  String get chat_list_loading_sign_out => 'Signing out…';

  @override
  String get chat_list_empty_search_title => 'No chats found';

  @override
  String get chat_list_empty_search_body =>
      'Try a different query. Search works by name and username.';

  @override
  String get chat_list_empty_folder_title => 'This folder is empty';

  @override
  String get chat_list_empty_folder_body =>
      'Switch folders or start a new chat using the button above.';

  @override
  String get chat_list_empty_all_title => 'No chats yet';

  @override
  String get chat_list_empty_all_body => 'Start a new chat to begin messaging.';

  @override
  String get chat_list_action_new_folder => 'New folder';

  @override
  String get chat_list_action_new_chat => 'New chat';

  @override
  String get chat_list_action_create => 'Create';

  @override
  String get chat_list_action_close => 'Close';

  @override
  String get chat_list_folders_title => 'Folders';

  @override
  String get chat_list_folders_subtitle => 'Pick folders for this chat.';

  @override
  String get chat_list_folders_empty => 'No custom folders yet.';

  @override
  String get chat_list_create_folder_title => 'New folder';

  @override
  String get chat_list_create_folder_subtitle =>
      'Create a folder to quickly filter your chats.';

  @override
  String get chat_list_create_folder_name_label => 'FOLDER NAME';

  @override
  String get chat_list_create_folder_name_hint => 'Folder name';

  @override
  String chat_list_create_folder_chats_label(Object count) {
    return 'CHATS ($count)';
  }

  @override
  String get chat_list_create_folder_select_all => 'SELECT ALL';

  @override
  String get chat_list_create_folder_reset => 'RESET';

  @override
  String get chat_list_create_folder_search_hint => 'Search by name…';

  @override
  String get chat_list_create_folder_no_matches => 'No matching chats';

  @override
  String get chat_list_folder_default_starred => 'Starred';

  @override
  String get chat_list_folder_default_all => 'All';

  @override
  String get chat_list_folder_default_new => 'New';

  @override
  String get chat_list_folder_default_direct => 'Direct';

  @override
  String get chat_list_folder_default_groups => 'Groups';

  @override
  String get chat_list_yesterday => 'Yesterday';

  @override
  String get chat_list_folder_delete_action => 'Delete';

  @override
  String get chat_list_folder_delete_title => 'Delete folder?';

  @override
  String chat_list_folder_delete_body(Object name) {
    return 'Folder \"$name\" will be deleted. Chats will remain intact.';
  }

  @override
  String chat_list_error_open_starred(Object error) {
    return 'Couldn’t open Starred: $error';
  }

  @override
  String chat_list_error_delete_folder(Object error) {
    return 'Couldn’t delete folder: $error';
  }

  @override
  String get chat_list_pin_not_available =>
      'Pinning isn’t available in this folder.';

  @override
  String chat_list_pin_pinned_in_folder(Object name) {
    return 'Chat pinned in \"$name\"';
  }

  @override
  String chat_list_pin_unpinned_in_folder(Object name) {
    return 'Chat unpinned from \"$name\"';
  }

  @override
  String chat_list_error_toggle_pin(Object error) {
    return 'Couldn’t change pin: $error';
  }

  @override
  String chat_list_error_update_folder(Object error) {
    return 'Couldn’t update folder: $error';
  }

  @override
  String get chat_list_clear_history_title => 'Clear history?';

  @override
  String get chat_list_clear_history_body =>
      'Messages will disappear only from your chat view. The other participant will keep the history.';

  @override
  String get chat_list_clear_history_confirm => 'Clear';

  @override
  String chat_list_error_clear_history(Object error) {
    return 'Couldn’t clear history: $error';
  }

  @override
  String chat_list_error_mark_read(Object error) {
    return 'Couldn’t mark chat as read: $error';
  }

  @override
  String get chat_list_delete_chat_title => 'Delete chat?';

  @override
  String get chat_list_delete_chat_body =>
      'The conversation will be permanently deleted for all participants. This can’t be undone.';

  @override
  String get chat_list_delete_chat_confirm => 'Delete';

  @override
  String chat_list_error_delete_chat(Object error) {
    return 'Couldn’t delete chat: $error';
  }

  @override
  String get chat_list_context_folders => 'Folders';

  @override
  String get chat_list_context_unpin => 'Unpin chat';

  @override
  String get chat_list_context_pin => 'Pin chat';

  @override
  String get chat_list_context_mark_all_read => 'Mark all as read';

  @override
  String get chat_list_context_clear_history => 'Clear history';

  @override
  String get chat_list_context_delete_chat => 'Delete chat';

  @override
  String get chat_list_snackbar_history_cleared => 'History cleared.';

  @override
  String get chat_list_snackbar_marked_read => 'Marked as read.';

  @override
  String chat_list_error_generic(Object error) {
    return 'Error: $error';
  }

  @override
  String get chat_calls_title => 'Calls';

  @override
  String get chat_calls_search_hint => 'Search by name…';

  @override
  String get chat_calls_empty => 'Your call history is empty.';

  @override
  String get chat_calls_nothing_found => 'Nothing found.';

  @override
  String chat_calls_error_load(Object error) {
    return 'Couldn’t load calls:\n$error';
  }

  @override
  String get chat_reply_cancel_tooltip => 'Cancel reply';

  @override
  String get voice_preview_tooltip_cancel => 'Cancel';

  @override
  String get voice_preview_tooltip_send => 'Send';

  @override
  String get profile_qr_title => 'My QR code';

  @override
  String get profile_qr_tooltip_close => 'Close';

  @override
  String get profile_qr_share_title => 'My LighChat profile';

  @override
  String get profile_qr_share_subject => 'LighChat profile';

  @override
  String chat_media_norm_pending_title(Object mediaKind) {
    return 'Processing $mediaKind…';
  }

  @override
  String chat_media_norm_failed_title(Object mediaKind) {
    return 'Couldn’t process $mediaKind';
  }

  @override
  String get chat_media_norm_pending_subtitle =>
      'The file will be available after server processing.';

  @override
  String get chat_media_norm_failed_subtitle =>
      'Try starting processing again.';

  @override
  String get conversation_threads_title => 'Threads';

  @override
  String get conversation_threads_empty => 'No threads yet';

  @override
  String get conversation_threads_root_attachment => 'Attachment';

  @override
  String get conversation_threads_root_message => 'Message';

  @override
  String conversation_threads_snippet_you(Object text) {
    return 'You: $text';
  }

  @override
  String get conversation_threads_day_today => 'Today';

  @override
  String get conversation_threads_day_yesterday => 'Yesterday';

  @override
  String conversation_threads_replies_badge(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count replies',
      one: '$count reply',
    );
    return '$_temp0';
  }

  @override
  String get chat_meetings_title => 'Meetings';

  @override
  String get chat_meetings_subtitle =>
      'Create conferences and manage participant access';

  @override
  String get chat_meetings_section_new => 'New meeting';

  @override
  String get chat_meetings_field_title_label => 'Meeting title';

  @override
  String get chat_meetings_field_title_hint => 'E.g., Logistics sync';

  @override
  String get chat_meetings_field_duration_label => 'Duration';

  @override
  String get chat_meetings_duration_unlimited => 'No limit';

  @override
  String get chat_meetings_duration_15m => '15 minutes';

  @override
  String get chat_meetings_duration_30m => '30 minutes';

  @override
  String get chat_meetings_duration_1h => '1 hour';

  @override
  String get chat_meetings_duration_90m => '1.5 hours';

  @override
  String get chat_meetings_field_access_label => 'Access';

  @override
  String get chat_meetings_access_private => 'Private';

  @override
  String get chat_meetings_access_public => 'Public';

  @override
  String get chat_meetings_waiting_room_title => 'Waiting room';

  @override
  String get chat_meetings_waiting_room_desc =>
      'In waiting room mode, you control who joins. Until you tap “Admit”, guests will stay on the waiting screen.';

  @override
  String get chat_meetings_backgrounds_title => 'Virtual backgrounds';

  @override
  String get chat_meetings_backgrounds_desc =>
      'Upload backgrounds and blur your background if you want. Pick an image from the gallery or upload your own backgrounds.';

  @override
  String get chat_meetings_create_button => 'Create meeting';

  @override
  String get chat_meetings_snackbar_enter_title => 'Enter a meeting title';

  @override
  String get chat_meetings_snackbar_auth_required =>
      'You need to be signed in to create a meeting';

  @override
  String chat_meetings_error_create_failed(Object error) {
    return 'Couldn’t create meeting: $error';
  }

  @override
  String get chat_meetings_history_title => 'Your history';

  @override
  String get chat_meetings_history_empty => 'Meeting history is empty';

  @override
  String chat_meetings_history_error(Object error) {
    return 'Couldn’t load meeting history: $error';
  }

  @override
  String get chat_meetings_status_live => 'live';

  @override
  String get chat_meetings_status_finished => 'finished';

  @override
  String get chat_meetings_badge_private => 'private';

  @override
  String get chat_contacts_search_hint => 'Search contacts…';

  @override
  String get chat_contacts_permission_denied =>
      'Contacts permission not granted.';

  @override
  String chat_contacts_sync_error(Object error) {
    return 'Couldn’t sync contacts: $error';
  }

  @override
  String chat_contacts_invite_prepare_failed(Object error) {
    return 'Couldn’t prepare invite: $error';
  }

  @override
  String get chat_contacts_matches_not_found => 'No matches found.';

  @override
  String chat_contacts_added_count(Object count) {
    return 'Contacts added: $count.';
  }

  @override
  String get chat_contacts_invite_text =>
      'Install LighChat: https://lighchat.online\nI’m inviting you to LighChat — here’s the install link.';

  @override
  String get chat_contacts_invite_subject => 'Invite to LighChat';

  @override
  String chat_contacts_error_load(Object error) {
    return 'Couldn’t load contacts: $error';
  }

  @override
  String chat_list_item_draft_line(Object line) {
    return 'Draft · $line';
  }

  @override
  String get chat_list_item_chat_created => 'Chat created';

  @override
  String get chat_list_item_no_messages_yet => 'No messages yet';

  @override
  String get chat_list_item_history_cleared => 'History cleared';

  @override
  String get chat_list_firebase_not_configured =>
      'Firebase isn’t configured yet.';

  @override
  String get new_chat_title => 'New chat';

  @override
  String get new_chat_subtitle =>
      'Pick someone to start a conversation, or create a group.';

  @override
  String get new_chat_search_hint => 'Name, username, or @handle…';

  @override
  String get new_chat_create_group => 'Create a group';

  @override
  String get new_chat_section_phone_contacts => 'PHONE CONTACTS';

  @override
  String get new_chat_section_contacts => 'CONTACTS';

  @override
  String get new_chat_section_all_users => 'ALL USERS';

  @override
  String get new_chat_empty_no_users => 'No one to start a chat with yet.';

  @override
  String get new_chat_empty_not_found => 'No matches found.';

  @override
  String new_chat_error_contacts(Object error) {
    return 'Contacts: $error';
  }

  @override
  String get new_chat_fallback_user_display_name => 'User';

  @override
  String get new_group_role_badge_admin => 'ADMIN';

  @override
  String get new_group_role_badge_worker => 'MEMBER';

  @override
  String new_group_error_auth_session(Object error) {
    return 'Couldn’t verify sign-in: $error';
  }

  @override
  String get invite_subject => 'Join me on LighChat';

  @override
  String get invite_text =>
      'Install LighChat: https://lighchat.online\\nI’m inviting you to LighChat — here’s the install link.';

  @override
  String get new_group_title => 'Create a group';

  @override
  String get new_group_search_hint => 'Search users…';

  @override
  String get new_group_pick_photo_tooltip =>
      'Tap to pick a group photo. Long‑press to remove it.';

  @override
  String get new_group_name_label => 'Group name';

  @override
  String get new_group_name_hint => 'Name';

  @override
  String get new_group_description_label => 'Description';

  @override
  String get new_group_description_hint => 'Optional';

  @override
  String new_group_members_count(Object count) {
    return 'Members ($count)';
  }

  @override
  String get new_group_add_members_section => 'ADD MEMBERS';

  @override
  String get new_group_empty_no_users => 'No one to add yet.';

  @override
  String get new_group_empty_not_found => 'No matches found.';

  @override
  String get new_group_error_name_required => 'Please enter a group name.';

  @override
  String get new_group_error_members_required => 'Add at least one member.';

  @override
  String get new_group_action_create => 'Create';

  @override
  String get group_members_title => 'Members';

  @override
  String get group_members_invite_link => 'Invite via link';

  @override
  String get group_members_admin_badge => 'ADMIN';

  @override
  String group_members_invite_text(Object groupName, Object inviteLink) {
    return 'Join the group $groupName on LighChat: $inviteLink';
  }

  @override
  String get group_members_error_min_admin =>
      'At least one administrator must remain in the group.';

  @override
  String get group_members_error_cannot_remove_creator =>
      'You can\'t remove admin rights from the group creator.';

  @override
  String get group_members_remove_admin => 'Admin rights removed';

  @override
  String get group_members_make_admin => 'User promoted to admin';

  @override
  String get auth_brand_tagline => 'A safer messenger';

  @override
  String get auth_firebase_not_ready =>
      'Firebase isn’t ready. Check `firebase_options.dart` and GoogleService-Info.plist.';

  @override
  String get auth_redirecting_to_chats => 'Taking you to chats…';

  @override
  String get auth_or => 'or';

  @override
  String get auth_create_account => 'Create account';

  @override
  String get auth_entry_sign_in => 'Sign in';

  @override
  String get auth_entry_sign_up => 'Create account';

  @override
  String get auth_qr_title => 'Sign in with QR';

  @override
  String get auth_qr_hint =>
      'Open LighChat on a device where you are already signed in → Settings → Devices → Connect new device, then scan this code.';

  @override
  String auth_qr_refresh_in(int seconds) {
    return 'Refreshes in ${seconds}s';
  }

  @override
  String get auth_qr_other_method => 'Sign in another way';

  @override
  String get auth_qr_approving => 'Signing in…';

  @override
  String get auth_qr_rejected => 'Request rejected';

  @override
  String get auth_qr_retry => 'Retry';

  @override
  String get auth_qr_unknown_error => 'Could not generate the QR code.';

  @override
  String get auth_qr_use_qr_login => 'Sign in with QR';

  @override
  String get auth_privacy_policy => 'Privacy policy';

  @override
  String get auth_error_open_privacy_policy =>
      'Couldn’t open the privacy policy';

  @override
  String get voice_transcript_show => 'Show text';

  @override
  String get voice_transcript_hide => 'Hide text';

  @override
  String get voice_transcript_copy => 'Copy';

  @override
  String get voice_transcript_loading => 'Transcribing…';

  @override
  String get voice_transcript_failed => 'Couldn’t get the text.';

  @override
  String get voice_attachment_media_kind_audio => 'audio';

  @override
  String get voice_attachment_load_failed => 'Couldn’t load';

  @override
  String get voice_attachment_title_voice_message => 'Voice message';

  @override
  String voice_transcript_error(Object error) {
    return 'Couldn’t transcribe: $error';
  }

  @override
  String get chat_messages_title => 'Messages';

  @override
  String get chat_call_decline => 'Decline';

  @override
  String get chat_call_open => 'Open';

  @override
  String get chat_call_accept => 'Accept';

  @override
  String video_call_error_init(Object error) {
    return 'Video call error: $error';
  }

  @override
  String get video_call_ended => 'Call ended';

  @override
  String get video_call_status_missed => 'Missed call';

  @override
  String get video_call_status_cancelled => 'Call cancelled';

  @override
  String get video_call_error_offer_not_ready =>
      'Offer isn’t ready yet. Try again.';

  @override
  String get video_call_error_invalid_call_data => 'Invalid call data';

  @override
  String video_call_error_accept_failed(Object error) {
    return 'Couldn’t accept the call: $error';
  }

  @override
  String get video_call_incoming => 'Incoming video call';

  @override
  String get video_call_connecting => 'Video call…';

  @override
  String get video_call_pip_tooltip => 'Picture in picture';

  @override
  String get video_call_mini_window_tooltip => 'Mini window';

  @override
  String get chat_delete_message_title_single => 'Delete message?';

  @override
  String get chat_delete_message_title_multi => 'Delete messages?';

  @override
  String get chat_delete_message_body_single =>
      'This message will be hidden for everyone.';

  @override
  String chat_delete_message_body_multi(Object count) {
    return 'Messages to delete: $count';
  }

  @override
  String get chat_delete_file_title => 'Delete file?';

  @override
  String get chat_delete_file_body =>
      'Only this file will be removed from the message.';

  @override
  String get forward_title => 'Forward';

  @override
  String get forward_empty_no_messages => 'No messages to forward';

  @override
  String get forward_error_not_authorized => 'Not signed in';

  @override
  String get forward_empty_no_recipients =>
      'No contacts or chats to forward to';

  @override
  String get forward_search_hint => 'Search contacts…';

  @override
  String get forward_empty_no_available_recipients =>
      'No available recipients.\nYou can only forward to contacts and your active chats.';

  @override
  String get forward_empty_not_found => 'Nothing found';

  @override
  String get forward_action_pick_recipients => 'Pick recipients';

  @override
  String get forward_action_send => 'Send';

  @override
  String forward_error_generic(Object error) {
    return 'Error: $error';
  }

  @override
  String get forward_sender_fallback => 'Participant';

  @override
  String get forward_error_profiles_load =>
      'Couldn’t load profiles to open chat';

  @override
  String get forward_error_send_no_permissions =>
      'Couldn’t forward: you don’t have access to one of the selected chats or the chat is no longer available.';

  @override
  String get forward_error_send_forbidden_chat =>
      'Couldn’t forward: access to one of the chats is denied.';

  @override
  String get share_picker_title => 'Share to LighChat';

  @override
  String get share_picker_empty_payload => 'Nothing to share';

  @override
  String get share_picker_summary_text_only => 'Text';

  @override
  String share_picker_summary_files_count(int count) {
    return 'Files: $count';
  }

  @override
  String share_picker_summary_files_with_text(int count) {
    return 'Files: $count + text';
  }

  @override
  String get devices_title => 'My devices';

  @override
  String get devices_subtitle =>
      'Devices where your encryption public key is published. Revoking creates a new key epoch for all encrypted chats — the revoked device won’t be able to read new messages.';

  @override
  String get devices_empty => 'No devices yet.';

  @override
  String get devices_connect_new_device => 'Connect new device';

  @override
  String get devices_approve_title => 'Allow this device to sign in?';

  @override
  String get devices_approve_body_hint =>
      'Make sure this is your own device that just showed the QR code.';

  @override
  String get devices_approve_allow => 'Allow';

  @override
  String get devices_approve_deny => 'Deny';

  @override
  String get devices_handover_progress_title => 'Syncing encrypted chats…';

  @override
  String devices_handover_progress_body(int done, int total) {
    return 'Updated $done of $total';
  }

  @override
  String get devices_handover_progress_starting => 'Starting…';

  @override
  String get devices_handover_success_title => 'New device linked';

  @override
  String devices_handover_success_body(String label) {
    return 'Device $label now has access to your encrypted chats.';
  }

  @override
  String devices_progress_rekeying(Object done, Object total) {
    return 'Updating chats: $done / $total';
  }

  @override
  String get devices_chip_current => 'This device';

  @override
  String get devices_chip_revoked => 'Revoked';

  @override
  String devices_meta_created_activity(Object createdAt, Object lastSeenAt) {
    return 'Created: $createdAt  •  Activity: $lastSeenAt';
  }

  @override
  String devices_meta_revoked_at(Object revokedAt) {
    return 'Revoked: $revokedAt';
  }

  @override
  String get devices_action_rename => 'Rename';

  @override
  String get devices_action_revoke => 'Revoke';

  @override
  String get devices_dialog_rename_title => 'Rename device';

  @override
  String get devices_dialog_rename_hint => 'e.g. iPhone 15 — Safari';

  @override
  String devices_error_rename_failed(Object error) {
    return 'Couldn’t rename: $error';
  }

  @override
  String get devices_dialog_revoke_title => 'Revoke device?';

  @override
  String get devices_dialog_revoke_body_current =>
      'You’re about to revoke THIS device. After that, you won’t be able to read new messages in end‑to‑end encrypted chats from this client.';

  @override
  String get devices_dialog_revoke_body_other =>
      'This device won’t be able to read new messages in end‑to‑end encrypted chats. Old messages will remain available on it.';

  @override
  String devices_snackbar_revoked(Object rekeyed, Object suffix) {
    return 'Device revoked. Chats updated: $rekeyed$suffix';
  }

  @override
  String devices_snackbar_failed_suffix(Object count) {
    return ', errors: $count';
  }

  @override
  String devices_error_revoke_failed(Object error) {
    return 'Revoke error: $error';
  }

  @override
  String get e2ee_recovery_title => 'E2EE — backup';

  @override
  String get e2ee_password_label => 'Password';

  @override
  String get e2ee_password_confirm_label => 'Confirm password';

  @override
  String e2ee_password_min_length(Object count) {
    return 'At least $count characters';
  }

  @override
  String get e2ee_password_mismatch => 'Passwords don’t match';

  @override
  String get e2ee_backup_create_title => 'Create key backup';

  @override
  String get e2ee_backup_restore_title => 'Restore with password';

  @override
  String get e2ee_backup_restore_action => 'Restore';

  @override
  String e2ee_backup_create_error(Object error) {
    return 'Couldn’t create backup: $error';
  }

  @override
  String e2ee_backup_restore_error(Object error) {
    return 'Couldn’t restore: $error';
  }

  @override
  String get e2ee_backup_wrong_password => 'Wrong password';

  @override
  String get e2ee_backup_not_found => 'Backup not found';

  @override
  String e2ee_recovery_error_generic(Object error) {
    return 'Error: $error';
  }

  @override
  String get e2ee_backup_password_card_title => 'Password backup';

  @override
  String get e2ee_backup_password_card_description =>
      'Create an encrypted backup of your private key. If you lose all devices, you can restore it on a new one using only the password. The password can’t be recovered — store it safely.';

  @override
  String get e2ee_backup_overwrite => 'Overwrite backup';

  @override
  String get e2ee_backup_create => 'Create backup';

  @override
  String get e2ee_backup_restore => 'Restore from backup';

  @override
  String get e2ee_backup_already_have => 'I already have a backup';

  @override
  String get e2ee_qr_transfer_title => 'Transfer key via QR';

  @override
  String get e2ee_qr_transfer_description =>
      'On the new device you show a QR, on the old one you scan it. Verify a 6‑digit code — the private key is transferred securely.';

  @override
  String get e2ee_qr_transfer_open => 'Open QR pairing';

  @override
  String get media_viewer_action_reply => 'Reply';

  @override
  String get media_viewer_action_forward => 'Forward';

  @override
  String get media_viewer_action_send => 'Send';

  @override
  String get media_viewer_action_save => 'Save';

  @override
  String get media_viewer_action_show_in_chat => 'Show in chat';

  @override
  String get media_viewer_action_delete => 'Delete';

  @override
  String get media_viewer_error_no_gallery_access =>
      'No permission to save to gallery';

  @override
  String get media_viewer_error_share_unavailable_web =>
      'Sharing isn’t available on web';

  @override
  String get media_viewer_error_file_not_found => 'File not found';

  @override
  String get media_viewer_error_bad_media_url => 'Bad media URL';

  @override
  String get media_viewer_error_bad_url => 'Bad URL';

  @override
  String get media_viewer_error_unsupported_media_scheme =>
      'Unsupported media type';

  @override
  String media_viewer_error_http_status(Object status) {
    return 'Server error (HTTP $status)';
  }

  @override
  String media_viewer_error_save_failed(Object error) {
    return 'Couldn’t save: $error';
  }

  @override
  String media_viewer_error_send_failed(Object error) {
    return 'Couldn’t send: $error';
  }

  @override
  String get media_viewer_video_playback_speed => 'Playback speed';

  @override
  String get media_viewer_video_quality => 'Quality';

  @override
  String get media_viewer_video_quality_auto => 'Auto';

  @override
  String get media_viewer_error_quality_switch_failed =>
      'Couldn’t switch quality';

  @override
  String get media_viewer_error_pip_open_failed => 'Couldn’t open PiP';

  @override
  String get media_viewer_pip_not_supported =>
      'Picture-in-picture isn’t supported on this device.';

  @override
  String get media_viewer_video_processing =>
      'This video is being processed on the server and will be available soon.';

  @override
  String get media_viewer_video_playback_failed => 'Couldn’t play the video.';

  @override
  String get common_none => 'None';

  @override
  String get group_member_role_admin => 'Administrator';

  @override
  String get group_member_role_worker => 'Member';

  @override
  String get profile_no_photo_to_view => 'No profile photo to view.';

  @override
  String get profile_chat_id_copied_toast => 'Chat ID copied';

  @override
  String get auth_register_error_open_link => 'Couldn’t open the link.';

  @override
  String get new_chat_error_self_profile_not_found =>
      'Your profile wasn’t found in the directory. Try signing out and back in.';

  @override
  String get disappearing_messages_title => 'Disappearing messages';

  @override
  String get disappearing_messages_intro =>
      'New messages are automatically removed from the server after the selected time (from the moment they’re sent). Messages already sent are not changed.';

  @override
  String disappearing_messages_admin_only(Object summary) {
    return 'Only group admins can change this. Current: $summary.';
  }

  @override
  String get disappearing_messages_snackbar_off =>
      'Disappearing messages turned off.';

  @override
  String get disappearing_messages_snackbar_updated => 'Timer updated.';

  @override
  String get disappearing_preset_off => 'Off';

  @override
  String get disappearing_preset_1h => '1 h';

  @override
  String get disappearing_preset_24h => '24 h';

  @override
  String get disappearing_preset_7d => '7 days';

  @override
  String get disappearing_preset_30d => '30 days';

  @override
  String get disappearing_ttl_summary_off => 'Off';

  @override
  String disappearing_ttl_minutes(Object count) {
    return '$count min';
  }

  @override
  String disappearing_ttl_hours(Object count) {
    return '$count h';
  }

  @override
  String disappearing_ttl_days(Object count) {
    return '$count days';
  }

  @override
  String disappearing_ttl_weeks(Object count) {
    return '$count wk';
  }

  @override
  String get conversation_profile_e2ee_on => 'On';

  @override
  String get conversation_profile_e2ee_off => 'Off';

  @override
  String get conversation_profile_e2ee_subtitle_on =>
      'End-to-end encryption is on. Tap for details.';

  @override
  String get conversation_profile_e2ee_subtitle_off =>
      'End-to-end encryption is off. Tap to enable.';

  @override
  String get partner_profile_title_fallback_group => 'Group chat';

  @override
  String get partner_profile_title_fallback_saved => 'Saved messages';

  @override
  String get partner_profile_title_fallback_chat => 'Chat';

  @override
  String partner_profile_subtitle_group_member_count(Object count) {
    return '$count members';
  }

  @override
  String get partner_profile_subtitle_saved_messages =>
      'Messages and notes for you only';

  @override
  String get partner_profile_error_cannot_contact_user =>
      'You can’t reach this user with the current contact settings.';

  @override
  String partner_profile_error_open_chat(Object error) {
    return 'Couldn’t open chat: $error';
  }

  @override
  String get partner_profile_call_peer_fallback => 'Peer';

  @override
  String get partner_profile_chat_not_created => 'The chat isn’t created yet';

  @override
  String get partner_profile_notifications_muted => 'Notifications muted';

  @override
  String get partner_profile_notifications_unmuted => 'Notifications unmuted';

  @override
  String get partner_profile_notifications_change_failed =>
      'Couldn’t update notifications';

  @override
  String get partner_profile_removed_from_contacts => 'Removed from contacts';

  @override
  String get partner_profile_remove_contact_failed =>
      'Couldn’t remove from contacts';

  @override
  String get partner_profile_contact_sent => 'Contact sent';

  @override
  String get partner_profile_share_failed_copied =>
      'Sharing failed. Contact text copied.';

  @override
  String get partner_profile_share_contact_header => 'Contact on LighChat';

  @override
  String partner_profile_share_avatar_line(Object url) {
    return 'Avatar: $url';
  }

  @override
  String partner_profile_share_profile_line(Object url) {
    return 'Profile: $url';
  }

  @override
  String partner_profile_share_contact_subject(Object name) {
    return 'LighChat contact: $name';
  }

  @override
  String get partner_profile_tooltip_back => 'Back';

  @override
  String get partner_profile_tooltip_close => 'Close';

  @override
  String get partner_profile_edit_contact_short => 'Edit';

  @override
  String get partner_profile_tooltip_copy_chat_id => 'Copy chat ID';

  @override
  String get partner_profile_action_chats => 'Chats';

  @override
  String get partner_profile_action_voice_call => 'Call';

  @override
  String get partner_profile_action_video => 'Video';

  @override
  String get partner_profile_action_share => 'Share';

  @override
  String get partner_profile_action_notifications => 'Alerts';

  @override
  String get partner_profile_menu_members => 'Members';

  @override
  String get partner_profile_menu_edit_group => 'Edit group';

  @override
  String get partner_profile_menu_media_links_files =>
      'Media, links, and files';

  @override
  String get partner_profile_menu_starred => 'Starred';

  @override
  String get partner_profile_menu_threads => 'Threads';

  @override
  String get partner_profile_menu_games => 'Games';

  @override
  String get partner_profile_menu_block => 'Block';

  @override
  String get partner_profile_menu_unblock => 'Unblock';

  @override
  String get partner_profile_menu_notifications => 'Notifications';

  @override
  String get partner_profile_menu_chat_theme => 'Chat theme';

  @override
  String get partner_profile_menu_advanced_privacy => 'Advanced chat privacy';

  @override
  String get partner_profile_privacy_trailing_default => 'Default';

  @override
  String get partner_profile_menu_encryption => 'Encryption';

  @override
  String get partner_profile_no_common_groups => 'NO SHARED GROUPS';

  @override
  String partner_profile_create_group_with(Object name) {
    return 'Create a group with $name';
  }

  @override
  String get partner_profile_leave_group => 'Leave group';

  @override
  String get partner_profile_contacts_and_data => 'Contact info';

  @override
  String get partner_profile_field_system_role => 'System role';

  @override
  String get partner_profile_field_email => 'Email';

  @override
  String get partner_profile_field_phone => 'Phone';

  @override
  String get partner_profile_field_birthday => 'Birthday';

  @override
  String get partner_profile_field_bio => 'About';

  @override
  String get partner_profile_add_to_contacts => 'Add to contacts';

  @override
  String get partner_profile_remove_from_contacts => 'Remove from contacts';

  @override
  String get thread_search_hint => 'Search in thread…';

  @override
  String get thread_search_tooltip_clear => 'Clear';

  @override
  String get thread_search_tooltip_search => 'Search';

  @override
  String thread_reply_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count replies',
      one: '$count reply',
      zero: '$count replies',
    );
    return '$_temp0';
  }

  @override
  String get thread_message_not_found => 'Message not found';

  @override
  String get thread_screen_title_fallback => 'Thread';

  @override
  String thread_load_replies_error(Object error) {
    return 'Thread error: $error';
  }

  @override
  String get chat_message_empty_placeholder => 'Message';

  @override
  String get chat_sender_you => 'You';

  @override
  String get chat_clipboard_nothing_to_paste =>
      'Nothing to paste from the clipboard';

  @override
  String chat_clipboard_paste_failed(Object error) {
    return 'Couldn’t paste from clipboard: $error';
  }

  @override
  String chat_send_failed(Object error) {
    return 'Couldn’t send: $error';
  }

  @override
  String chat_send_video_circle_failed(Object error) {
    return 'Couldn’t send video note: $error';
  }

  @override
  String get chat_service_unavailable => 'Service unavailable';

  @override
  String get chat_repository_unavailable => 'Chat service unavailable';

  @override
  String get chat_still_loading => 'Chat is still loading';

  @override
  String get chat_no_participants => 'No chat participants';

  @override
  String get chat_location_ios_geolocator_missing =>
      'Location isn’t linked in this iOS build. Run pod install in mobile/app/ios and rebuild.';

  @override
  String get chat_location_services_disabled => 'Turn on location services';

  @override
  String get chat_location_permission_denied => 'No permission to use location';

  @override
  String chat_location_send_failed(Object error) {
    return 'Couldn’t send location: $error';
  }

  @override
  String get chat_poll_send_timeout => 'Poll wasn’t sent: timed out';

  @override
  String chat_poll_send_firebase(Object details) {
    return 'Poll wasn’t sent (Firestore): $details';
  }

  @override
  String chat_poll_send_known_error(Object details) {
    return 'Poll wasn’t sent: $details';
  }

  @override
  String chat_poll_send_failed(Object error) {
    return 'Couldn’t send poll: $error';
  }

  @override
  String chat_delete_action_failed(Object error) {
    return 'Couldn’t delete: $error';
  }

  @override
  String get chat_media_transcode_retry_started => 'Transcode retry started';

  @override
  String chat_media_transcode_retry_failed(Object error) {
    return 'Couldn’t start transcode retry: $error';
  }

  @override
  String chat_parent_load_error(Object error) {
    return 'Error: $error';
  }

  @override
  String get chat_message_not_found_in_loaded_history =>
      'Message wasn’t found in the loaded history';

  @override
  String get chat_finish_editing_first => 'Finish editing first';

  @override
  String chat_send_voice_failed(Object error) {
    return 'Couldn’t send voice message: $error';
  }

  @override
  String get chat_starred_removed => 'Removed from Starred';

  @override
  String get chat_starred_added => 'Added to Starred';

  @override
  String chat_starred_toggle_failed(Object error) {
    return 'Couldn’t update Starred: $error';
  }

  @override
  String chat_reaction_toggle_failed(Object error) {
    return 'Couldn’t add reaction: $error';
  }

  @override
  String chat_emoji_burst_sync_failed(Object error) {
    return 'Couldn’t sync emoji effect: $error';
  }

  @override
  String get chat_pin_already_pinned => 'Message is already pinned';

  @override
  String chat_pin_limit_reached(int count) {
    return 'Pinned messages limit ($count)';
  }

  @override
  String chat_pin_failed(Object error) {
    return 'Couldn’t pin: $error';
  }

  @override
  String chat_unpin_failed(Object error) {
    return 'Couldn’t unpin: $error';
  }

  @override
  String get chat_text_copied => 'Text copied';

  @override
  String get chat_edit_attachments_not_allowed =>
      'Attachments aren’t available while editing';

  @override
  String get chat_edit_text_empty => 'Text can’t be empty';

  @override
  String chat_e2ee_unavailable(Object code) {
    return 'Encryption unavailable: $code';
  }

  @override
  String chat_save_failed(Object error) {
    return 'Couldn’t save: $error';
  }

  @override
  String chat_load_messages_error(Object error) {
    return 'Couldn’t load messages: $error';
  }

  @override
  String chat_conversation_error(Object error) {
    return 'Conversation error: $error';
  }

  @override
  String chat_auth_error(Object error) {
    return 'Auth error: $error';
  }

  @override
  String get chat_poll_label => 'Poll';

  @override
  String get chat_location_label => 'Location';

  @override
  String get chat_attachment_label => 'Attachment';

  @override
  String chat_media_pick_failed(Object error) {
    return 'Couldn’t pick media: $error';
  }

  @override
  String chat_file_pick_failed(Object error) {
    return 'Couldn’t pick file: $error';
  }

  @override
  String get chat_call_ongoing_video => 'Video call in progress';

  @override
  String get chat_call_ongoing_audio => 'Audio call in progress';

  @override
  String get chat_call_incoming_video => 'Incoming video call';

  @override
  String get chat_call_incoming_audio => 'Incoming audio call';

  @override
  String get message_menu_action_reply => 'Reply';

  @override
  String get message_menu_action_thread => 'Thread';

  @override
  String get message_menu_action_copy => 'Copy';

  @override
  String get message_menu_action_edit => 'Edit';

  @override
  String get message_menu_action_pin => 'Pin';

  @override
  String get message_menu_action_star_add => 'Add to Starred';

  @override
  String get message_menu_action_star_remove => 'Remove from Starred';

  @override
  String get message_menu_action_create_sticker => 'Create sticker';

  @override
  String get message_menu_action_save_to_my_stickers => 'Save to my stickers';

  @override
  String get message_menu_action_forward => 'Forward';

  @override
  String get message_menu_action_select => 'Select';

  @override
  String get message_menu_action_delete => 'Delete';

  @override
  String get message_menu_initiator_deleted => 'Message deleted';

  @override
  String get message_menu_header_sent => 'SENT:';

  @override
  String get message_menu_header_read => 'READ:';

  @override
  String get message_menu_header_expire_at => 'DISAPPEARS:';

  @override
  String get chat_header_search_hint => 'Search messages…';

  @override
  String get chat_header_tooltip_threads => 'Threads';

  @override
  String get chat_header_tooltip_search => 'Search';

  @override
  String get chat_header_tooltip_video_call => 'Video call';

  @override
  String get chat_header_tooltip_audio_call => 'Audio call';

  @override
  String get conversation_games_title => 'Games';

  @override
  String get conversation_games_durak => 'Durak';

  @override
  String get conversation_games_durak_subtitle => 'Create lobby';

  @override
  String get conversation_game_lobby_title => 'Lobby';

  @override
  String get conversation_game_lobby_not_found => 'Game not found';

  @override
  String conversation_game_lobby_error(Object error) {
    return 'Error: $error';
  }

  @override
  String conversation_game_lobby_create_failed(Object error) {
    return 'Couldn’t create game: $error';
  }

  @override
  String conversation_game_lobby_game_id(Object id) {
    return 'ID: $id';
  }

  @override
  String conversation_game_lobby_status(Object status) {
    return 'Status: $status';
  }

  @override
  String conversation_game_lobby_players(Object count, Object max) {
    return 'Players: $count/$max';
  }

  @override
  String get conversation_game_lobby_join => 'Join';

  @override
  String get conversation_game_lobby_start => 'Start';

  @override
  String conversation_game_lobby_join_failed(Object error) {
    return 'Couldn’t join: $error';
  }

  @override
  String conversation_game_lobby_start_failed(Object error) {
    return 'Couldn’t start the game: $error';
  }

  @override
  String get conversation_game_send_test_move => 'Test move';

  @override
  String conversation_game_move_failed(Object error) {
    return 'Move rejected: $error';
  }

  @override
  String get conversation_durak_table_title => 'Table';

  @override
  String get conversation_durak_hand_title => 'Hand';

  @override
  String get conversation_durak_role_attacker => 'Attacking';

  @override
  String get conversation_durak_role_defender => 'Defending';

  @override
  String get conversation_durak_role_thrower => 'Throwing in';

  @override
  String get conversation_durak_action_attack => 'Attack';

  @override
  String get conversation_durak_action_defend => 'Defend';

  @override
  String get conversation_durak_action_take => 'Take';

  @override
  String get conversation_durak_action_beat => 'Beat';

  @override
  String get conversation_durak_action_transfer => 'Transfer';

  @override
  String get conversation_durak_action_pass => 'Pass';

  @override
  String get conversation_durak_badge_taking => 'I\'ll take';

  @override
  String get conversation_durak_game_finished_title => 'Game finished';

  @override
  String get conversation_durak_game_finished_no_loser => 'No loser this time.';

  @override
  String conversation_durak_game_finished_loser(Object uid) {
    return 'Loser: $uid';
  }

  @override
  String conversation_durak_game_finished_winners(Object uids) {
    return 'Winners: $uids';
  }

  @override
  String get conversation_durak_winner => 'Winner!';

  @override
  String get conversation_durak_play_again => 'Play again';

  @override
  String get conversation_durak_back_to_chat => 'Back to chat';

  @override
  String get conversation_game_lobby_waiting_opponent =>
      'Waiting for opponent…';

  @override
  String get conversation_durak_drop_zone => 'Drop card here to play';

  @override
  String get durak_settings_mode => 'Mode';

  @override
  String get durak_mode_podkidnoy => 'Podkidnoy';

  @override
  String get durak_mode_perevodnoy => 'Perevodnoy';

  @override
  String get durak_settings_max_players => 'Players';

  @override
  String get durak_settings_deck => 'Deck';

  @override
  String get durak_deck_36 => '36 cards';

  @override
  String get durak_deck_52 => '52 cards';

  @override
  String get durak_settings_with_jokers => 'Jokers';

  @override
  String get durak_settings_turn_timer => 'Turn timer';

  @override
  String get durak_turn_timer_off => 'Off';

  @override
  String get durak_settings_throw_in_policy => 'Who can throw in';

  @override
  String get durak_throw_in_policy_all => 'All players (except defender)';

  @override
  String get durak_throw_in_policy_neighbors => 'Only defender\'s neighbors';

  @override
  String get durak_settings_shuler => 'Shuler mode';

  @override
  String get durak_settings_shuler_subtitle =>
      'Allows illegal moves unless someone calls foul.';

  @override
  String get conversation_durak_action_foul => 'Foul!';

  @override
  String get conversation_durak_action_resolve => 'Confirm Beat';

  @override
  String get conversation_durak_foul_toast => 'Foul! Cheater penalized.';

  @override
  String get durak_phase_prefix => 'Phase';

  @override
  String get durak_phase_attack => 'Attack';

  @override
  String get durak_phase_defense => 'Defense';

  @override
  String get durak_phase_throw_in => 'Throw-in';

  @override
  String get durak_phase_resolution => 'Resolution';

  @override
  String get durak_phase_finished => 'Finished';

  @override
  String get durak_phase_pending_foul => 'Pending foul after Beat';

  @override
  String get durak_phase_pending_foul_hint_attacker =>
      'Wait for foul. If nobody calls it, confirm Beat.';

  @override
  String get durak_phase_pending_foul_hint_other =>
      'Wait for foul. Call Foul! if you spotted cheating.';

  @override
  String get durak_phase_hint_can_throw_in => 'You can throw in';

  @override
  String get durak_phase_hint_wait => 'Wait for your turn';

  @override
  String durak_now_throwing_in(Object name) {
    return 'Now throwing in: $name';
  }

  @override
  String chat_selection_selected_count(int count) {
    return '$count selected';
  }

  @override
  String get chat_selection_tooltip_forward => 'Forward';

  @override
  String get chat_selection_tooltip_delete => 'Delete';

  @override
  String get chat_composer_hint_message => 'Type a message…';

  @override
  String get chat_composer_tooltip_stickers => 'Stickers';

  @override
  String get chat_composer_tooltip_attachments => 'Attachments';

  @override
  String get chat_list_unread_separator => 'Unread messages';

  @override
  String get chat_e2ee_decrypt_failed_open_devices =>
      'Couldn’t decrypt. Open Settings → Devices';

  @override
  String get chat_e2ee_encrypted_message_placeholder => 'Encrypted message';

  @override
  String chat_forwarded_from(Object name) {
    return 'Forwarded from $name';
  }

  @override
  String get chat_outbox_retry => 'Retry';

  @override
  String get chat_outbox_remove => 'Remove';

  @override
  String get chat_outbox_cancel => 'Cancel';

  @override
  String get chat_message_edited_badge_short => 'EDITED';

  @override
  String get register_error_enter_name => 'Enter your name.';

  @override
  String get register_error_enter_username => 'Enter a username.';

  @override
  String get register_error_enter_phone => 'Enter a phone number.';

  @override
  String get register_error_invalid_phone => 'Enter a valid phone number.';

  @override
  String get register_error_enter_email => 'Enter an email.';

  @override
  String get register_error_enter_password => 'Enter a password.';

  @override
  String get register_error_repeat_password => 'Repeat the password.';

  @override
  String get register_error_dob_format =>
      'Enter date of birth in dd.mm.yyyy format';

  @override
  String get register_error_accept_privacy_policy =>
      'Please confirm you accept the privacy policy';

  @override
  String get register_privacy_required =>
      'Privacy policy acceptance is required';

  @override
  String get register_label_name => 'Name';

  @override
  String get register_hint_name => 'Enter your name';

  @override
  String get register_label_username => 'Username';

  @override
  String get register_hint_username => 'Enter a username';

  @override
  String get register_label_phone => 'Phone';

  @override
  String get register_hint_choose_country => 'Choose a country';

  @override
  String get register_label_email => 'Email';

  @override
  String get register_hint_email => 'Enter your email';

  @override
  String get register_label_password => 'Password';

  @override
  String get register_hint_password => 'Enter your password';

  @override
  String get register_label_confirm_password => 'Confirm password';

  @override
  String get register_hint_confirm_password => 'Repeat your password';

  @override
  String get register_label_dob => 'Date of birth';

  @override
  String get register_hint_dob => 'dd.mm.yyyy';

  @override
  String get register_label_bio => 'About';

  @override
  String get register_hint_bio => 'Tell us about yourself…';

  @override
  String get register_privacy_prefix => 'I accept ';

  @override
  String get register_privacy_link_text => 'Personal data processing consent';

  @override
  String get register_privacy_and => ' and ';

  @override
  String get register_terms_link_text => 'Privacy policy user agreement';

  @override
  String get register_button_create_account => 'Create account';

  @override
  String get register_country_search_hint => 'Search by country or code';

  @override
  String get register_date_picker_help => 'Date of birth';

  @override
  String get register_date_picker_cancel => 'Cancel';

  @override
  String get register_date_picker_confirm => 'Select';

  @override
  String get register_pick_avatar_title => 'Choose avatar';

  @override
  String get edit_group_title => 'Edit group';

  @override
  String get edit_group_save => 'Save';

  @override
  String get edit_group_cancel => 'Cancel';

  @override
  String get edit_group_name_label => 'Group name';

  @override
  String get edit_group_name_hint => 'Name';

  @override
  String get edit_group_description_label => 'Description';

  @override
  String get edit_group_description_hint => 'Optional';

  @override
  String get edit_group_pick_photo_tooltip =>
      'Tap to pick a group photo. Long-press to remove it.';

  @override
  String get edit_group_error_name_required => 'Please enter a group name.';

  @override
  String get edit_group_error_save_failed => 'Failed to save group.';

  @override
  String get edit_group_error_not_found => 'Group not found.';

  @override
  String get edit_group_error_permission_denied =>
      'You don\'t have permission to edit this group.';

  @override
  String get edit_group_success => 'Group updated.';

  @override
  String get edit_group_privacy_section => 'PRIVACY';

  @override
  String get edit_group_privacy_forwarding => 'Message forwarding';

  @override
  String get edit_group_privacy_forwarding_desc =>
      'Allow members to forward messages from this group.';

  @override
  String get edit_group_privacy_screenshots => 'Screenshots';

  @override
  String get edit_group_privacy_screenshots_desc =>
      'Allow screenshots in this group (platform-dependent).';

  @override
  String get edit_group_privacy_copy => 'Text copying';

  @override
  String get edit_group_privacy_copy_desc => 'Allow copying message text.';

  @override
  String get edit_group_privacy_save_media => 'Save media';

  @override
  String get edit_group_privacy_save_media_desc =>
      'Allow saving photos and videos to the device.';

  @override
  String get edit_group_privacy_share_media => 'Share media';

  @override
  String get edit_group_privacy_share_media_desc =>
      'Allow sharing media files outside the app.';

  @override
  String get schedule_message_sheet_title => 'Schedule message';

  @override
  String get schedule_message_long_press_hint => 'Schedule send';

  @override
  String schedule_message_preset_today_at(String time) {
    return 'Today at $time';
  }

  @override
  String schedule_message_preset_tomorrow_at(String time) {
    return 'Tomorrow at $time';
  }

  @override
  String schedule_message_will_send_at(String datetime) {
    return 'Will be sent: $datetime';
  }

  @override
  String get schedule_message_must_be_in_future =>
      'Time must be in the future (at least one minute from now).';

  @override
  String get schedule_message_e2ee_warning =>
      'This is an E2EE chat. The scheduled message will be stored on the server in plaintext and published without encryption.';

  @override
  String get schedule_message_cancel => 'Cancel';

  @override
  String get schedule_message_confirm => 'Schedule';

  @override
  String get schedule_message_save => 'Save';

  @override
  String get schedule_message_text_required => 'Type a message first';

  @override
  String get schedule_message_attachments_unsupported_mobile =>
      'Scheduling attachments is currently supported only on web';

  @override
  String schedule_message_scheduled_toast(String datetime) {
    return 'Scheduled: $datetime';
  }

  @override
  String schedule_message_failed_toast(String error) {
    return 'Failed to schedule: $error';
  }

  @override
  String get scheduled_messages_screen_title => 'Scheduled messages';

  @override
  String get scheduled_messages_empty_title => 'No scheduled messages';

  @override
  String get scheduled_messages_empty_hint =>
      'Hold the Send button to schedule a message.';

  @override
  String scheduled_messages_load_failed(String error) {
    return 'Failed to load: $error';
  }

  @override
  String get scheduled_messages_e2ee_notice =>
      'In an E2EE chat, scheduled messages are stored and published in plaintext.';

  @override
  String get scheduled_messages_cancel_dialog_title => 'Cancel scheduled send?';

  @override
  String get scheduled_messages_cancel_dialog_body =>
      'The scheduled message will be deleted.';

  @override
  String get scheduled_messages_cancel_dialog_keep => 'Keep';

  @override
  String get scheduled_messages_cancel_dialog_confirm => 'Cancel';

  @override
  String get scheduled_messages_canceled_toast => 'Canceled';

  @override
  String scheduled_messages_time_changed_toast(String datetime) {
    return 'Time changed: $datetime';
  }

  @override
  String scheduled_messages_action_failed_toast(String error) {
    return 'Error: $error';
  }

  @override
  String get scheduled_messages_tile_edit_tooltip => 'Change time';

  @override
  String get scheduled_messages_tile_cancel_tooltip => 'Cancel';

  @override
  String scheduled_messages_preview_poll(String question) {
    return 'Poll: $question';
  }

  @override
  String get scheduled_messages_preview_location => 'Location';

  @override
  String get scheduled_messages_preview_attachment => 'Attachment';

  @override
  String scheduled_messages_preview_attachment_count(int count) {
    return 'Attachment (×$count)';
  }

  @override
  String get scheduled_messages_preview_message => 'Message';

  @override
  String get chat_header_tooltip_scheduled => 'Scheduled messages';

  @override
  String get schedule_date_label => 'Date';

  @override
  String get schedule_time_label => 'Time';

  @override
  String get common_done => 'Done';

  @override
  String get common_send => 'Send';

  @override
  String get common_open => 'Open';

  @override
  String get common_add => 'Add';

  @override
  String get common_search => 'Search';

  @override
  String get common_edit => 'Edit';

  @override
  String get common_next => 'Next';

  @override
  String get common_ok => 'OK';

  @override
  String get common_confirm => 'Confirm';

  @override
  String get common_ready => 'Ready';

  @override
  String get common_error => 'Error';

  @override
  String get common_yes => 'Yes';

  @override
  String get common_no => 'No';

  @override
  String get common_back => 'Back';

  @override
  String get common_continue => 'Continue';

  @override
  String get common_loading => 'Loading…';

  @override
  String get common_copy => 'Copy';

  @override
  String get common_share => 'Share';

  @override
  String get common_settings => 'Settings';

  @override
  String get common_today => 'Today';

  @override
  String get common_yesterday => 'Yesterday';

  @override
  String get e2ee_qr_title => 'QR key pairing';

  @override
  String get e2ee_qr_uid_error => 'Failed to get user uid.';

  @override
  String get e2ee_qr_session_ended_error =>
      'Session ended before the second device responded.';

  @override
  String get e2ee_qr_no_data_error => 'No data to apply the key.';

  @override
  String get e2ee_qr_key_transferred_toast =>
      'Key transferred. Re-enter chats to refresh sessions.';

  @override
  String get e2ee_qr_wrong_account_error =>
      'QR was generated for a different account.';

  @override
  String get e2ee_qr_explainer_title => 'What is this';

  @override
  String get e2ee_qr_explainer_text =>
      'Transfer a private key from one of your devices to another via ECDH + QR. Both sides see a 6-digit code for manual verification.';

  @override
  String get e2ee_qr_show_qr_label => 'I\'m on the new device — show QR';

  @override
  String get e2ee_qr_scan_qr_label => 'I already have a key — scan QR';

  @override
  String get e2ee_qr_scan_hint =>
      'Scan the QR on the old device that already has the key.';

  @override
  String get e2ee_qr_verify_code_label =>
      'Verify the 6-digit code with the old device:';

  @override
  String e2ee_qr_transfer_from_device_label(String label) {
    return 'Transfer from device: $label';
  }

  @override
  String get e2ee_qr_code_match_apply_label => 'Code matches — apply';

  @override
  String get e2ee_qr_key_success_label =>
      'Key successfully transferred to this device. Re-enter chats.';

  @override
  String get e2ee_qr_unknown_error => 'Unknown error';

  @override
  String get e2ee_qr_back_to_pick_label => 'Back to selection';

  @override
  String get e2ee_qr_donor_scan_hint =>
      'Point the camera at the QR shown on the new device.';

  @override
  String get e2ee_qr_donor_verify_code_label =>
      'Verify the code with the new device:';

  @override
  String get e2ee_qr_donor_verify_hint =>
      'If the code matches — confirm on the new device. If not, press Cancel immediately.';

  @override
  String get e2ee_encrypt_title => 'Encryption';

  @override
  String get e2ee_encrypt_enable_dialog_title => 'Enable encryption?';

  @override
  String get e2ee_encrypt_enable_dialog_body =>
      'New messages will only be available on your devices and your contact\'s. Old messages will remain as they are.';

  @override
  String get e2ee_encrypt_enable_label => 'Enable';

  @override
  String get e2ee_encrypt_disable_dialog_title => 'Disable encryption?';

  @override
  String get e2ee_encrypt_disable_dialog_body =>
      'New messages will be sent without end-to-end encryption. Previously sent encrypted messages will remain in the feed.';

  @override
  String get e2ee_encrypt_disable_label => 'Disable';

  @override
  String get e2ee_encrypt_status_on =>
      'End-to-end encryption is enabled for this chat.';

  @override
  String get e2ee_encrypt_status_off => 'End-to-end encryption is disabled.';

  @override
  String get e2ee_encrypt_description =>
      'When encryption is enabled, new message content is only available to chat participants on their devices. Disabling only affects new messages.';

  @override
  String get e2ee_encrypt_switch_title => 'Enable encryption';

  @override
  String e2ee_encrypt_switch_on(int epoch) {
    return 'Enabled (key epoch: $epoch)';
  }

  @override
  String get e2ee_encrypt_switch_off => 'Disabled';

  @override
  String get e2ee_encrypt_already_on_toast =>
      'Encryption is already enabled or key creation failed. Check the network and your contact\'s keys.';

  @override
  String get e2ee_encrypt_no_device_toast =>
      'Could not enable: the contact has no active device with a key.';

  @override
  String e2ee_encrypt_enable_failed_toast(String error) {
    return 'Failed to enable encryption: $error';
  }

  @override
  String e2ee_encrypt_disable_failed_toast(String error) {
    return 'Failed to disable: $error';
  }

  @override
  String get e2ee_encrypt_data_types_title => 'Data types';

  @override
  String get e2ee_encrypt_data_types_description =>
      'This setting does not change the protocol. It controls which data types are sent encrypted.';

  @override
  String get e2ee_encrypt_override_title => 'Encryption settings for this chat';

  @override
  String get e2ee_encrypt_override_on => 'Chat-level settings are used.';

  @override
  String get e2ee_encrypt_override_off => 'Global settings are inherited.';

  @override
  String get e2ee_encrypt_text_title => 'Message text';

  @override
  String get e2ee_encrypt_media_title => 'Attachments (media/files)';

  @override
  String get e2ee_encrypt_override_hint =>
      'To change for this chat — enable the override.';

  @override
  String get sticker_default_pack_name => 'My pack';

  @override
  String get sticker_new_pack_dialog_title => 'New sticker pack';

  @override
  String get sticker_pack_name_hint => 'Name';

  @override
  String get sticker_save_to_pack => 'Save to sticker pack';

  @override
  String get sticker_no_packs_hint =>
      'No packs. Create one on the Stickers tab.';

  @override
  String get sticker_new_pack_option => 'New pack…';

  @override
  String get sticker_pick_image_or_gif => 'Pick an image or GIF';

  @override
  String sticker_send_failed(String error) {
    return 'Failed to send: $error';
  }

  @override
  String get sticker_saved_to_pack => 'Saved to sticker pack';

  @override
  String get sticker_save_gif_failed => 'Could not download or save GIF';

  @override
  String get sticker_delete_pack_title => 'Delete pack?';

  @override
  String sticker_delete_pack_body(String name) {
    return '\"$name\" and all stickers inside will be deleted.';
  }

  @override
  String get sticker_pack_deleted => 'Pack deleted';

  @override
  String get sticker_pack_delete_failed => 'Failed to delete pack';

  @override
  String get sticker_tab_emoji => 'EMOJI';

  @override
  String get sticker_tab_stickers => 'STICKERS';

  @override
  String get sticker_tab_gif => 'GIF';

  @override
  String get sticker_scope_my => 'My';

  @override
  String get sticker_scope_public => 'Public';

  @override
  String get sticker_new_pack_tooltip => 'New pack';

  @override
  String get sticker_pack_created => 'Sticker pack created';

  @override
  String get sticker_no_packs_create => 'No sticker packs. Create one.';

  @override
  String get sticker_public_packs_empty => 'No public packs configured';

  @override
  String get sticker_section_recent => 'RECENT';

  @override
  String get sticker_pack_empty_hint =>
      'Pack is empty. Add from device (GIF tab — \"To my pack\").';

  @override
  String get sticker_delete_sticker_title => 'Delete sticker?';

  @override
  String get sticker_deleted => 'Deleted';

  @override
  String get sticker_gallery => 'Gallery';

  @override
  String get sticker_gallery_subtitle =>
      'Photos, PNG, GIF from device — straight to chat';

  @override
  String get gif_search_hint => 'Search GIF…';

  @override
  String gif_translated_hint(String query) {
    return 'Searched: $query';
  }

  @override
  String get gif_search_unavailable => 'GIF search is temporarily unavailable.';

  @override
  String get gif_filter_all => 'All';

  @override
  String get sticker_section_animated => 'ANIMATED';

  @override
  String get sticker_emoji_unavailable =>
      'Emoji-to-text is not available for this window.';

  @override
  String get sticker_create_pack_hint => 'Create a pack with the + button';

  @override
  String get sticker_public_packs_unavailable =>
      'Public packs not available yet';

  @override
  String get composer_link_title => 'Link';

  @override
  String get composer_link_apply => 'Apply';

  @override
  String get composer_attach_title => 'Attach';

  @override
  String get composer_attach_photo_video => 'Photo/Video';

  @override
  String get composer_attach_files => 'Files';

  @override
  String get composer_attach_video_circle => 'Video circle';

  @override
  String get composer_attach_location => 'Location';

  @override
  String get composer_attach_poll => 'Poll';

  @override
  String get composer_attach_stickers => 'Stickers';

  @override
  String get composer_attach_clipboard => 'Clipboard';

  @override
  String get composer_attach_text => 'Text';

  @override
  String get meeting_create_poll => 'Create poll';

  @override
  String get meeting_min_two_options => 'At least 2 answer options required';

  @override
  String meeting_error_with_details(String details) {
    return 'Error: $details';
  }

  @override
  String meeting_polls_load_error(String details) {
    return 'Failed to load polls: $details';
  }

  @override
  String get meeting_no_polls_yet => 'No polls yet';

  @override
  String get meeting_question_label => 'Question';

  @override
  String get meeting_options_label => 'Options';

  @override
  String meeting_option_hint(int index) {
    return 'Option $index';
  }

  @override
  String get meeting_add_option => 'Add option';

  @override
  String get meeting_anonymous => 'Anonymous';

  @override
  String get meeting_anonymous_subtitle => 'Who can see others\' choices';

  @override
  String get meeting_save_as_draft => 'Save as draft';

  @override
  String get meeting_publish => 'Publish';

  @override
  String get meeting_action_start => 'Start';

  @override
  String get meeting_action_change_vote => 'Change vote';

  @override
  String get meeting_action_restart => 'Restart';

  @override
  String get meeting_action_stop => 'Stop';

  @override
  String meeting_vote_failed(String details) {
    return 'Vote not counted: $details';
  }

  @override
  String get meeting_status_ended => 'Ended';

  @override
  String get meeting_status_draft => 'Draft';

  @override
  String get meeting_status_active => 'Active';

  @override
  String get meeting_status_public => 'Public';

  @override
  String meeting_votes_count(int count) {
    return '$count votes';
  }

  @override
  String meeting_goal_count(int count) {
    return 'Goal: $count';
  }

  @override
  String get meeting_hide => 'Hide';

  @override
  String get meeting_who_voted => 'Who voted';

  @override
  String meeting_participants_tab(int count) {
    return 'Members ($count)';
  }

  @override
  String meeting_polls_tab_active(int count) {
    return 'Polls ($count)';
  }

  @override
  String get meeting_polls_tab => 'Polls';

  @override
  String meeting_chat_tab_unread(int count) {
    return 'Chat ($count)';
  }

  @override
  String get meeting_chat_tab => 'Chat';

  @override
  String meeting_requests_tab(int count) {
    return 'Requests ($count)';
  }

  @override
  String meeting_you_suffix(String name) {
    return '$name (You)';
  }

  @override
  String get meeting_host_label => 'Host';

  @override
  String get meeting_force_mute_mic => 'Mute microphone';

  @override
  String get meeting_force_mute_camera => 'Turn off camera';

  @override
  String get meeting_kick_from_room => 'Remove from room';

  @override
  String meeting_chat_load_error(Object error) {
    return 'Couldn\'t load chat: $error';
  }

  @override
  String get meeting_no_requests => 'No new requests';

  @override
  String get meeting_no_messages_yet => 'No messages yet';

  @override
  String meeting_file_too_large(String name) {
    return 'File too large: $name';
  }

  @override
  String meeting_send_failed(String details) {
    return 'Failed to send: $details';
  }

  @override
  String get meeting_edit_message_title => 'Edit message';

  @override
  String meeting_save_failed(String details) {
    return 'Failed to save: $details';
  }

  @override
  String get meeting_delete_message_title => 'Delete message?';

  @override
  String get meeting_delete_message_body =>
      'Members will see \"Message deleted\".';

  @override
  String meeting_delete_failed(String details) {
    return 'Failed to delete: $details';
  }

  @override
  String get meeting_message_hint => 'Message…';

  @override
  String get meeting_message_deleted => 'Message deleted';

  @override
  String get meeting_message_edited => '• edited';

  @override
  String get meeting_copy_action => 'Copy';

  @override
  String get meeting_edit_action => 'Edit';

  @override
  String get meeting_join_title => 'Join';

  @override
  String meeting_loading_error(String details) {
    return 'Error loading meeting: $details';
  }

  @override
  String get meeting_not_found => 'Meeting not found or closed';

  @override
  String get meeting_private_description =>
      'Private meeting: the host will decide whether to let you in after your request.';

  @override
  String get meeting_public_description =>
      'Open meeting: join via link without waiting.';

  @override
  String get meeting_your_name_label => 'Your name';

  @override
  String get meeting_enter_name_error => 'Enter your name';

  @override
  String get meeting_guest_name => 'Guest';

  @override
  String get meeting_enter_room => 'Enter room';

  @override
  String get meeting_request_join => 'Request to join';

  @override
  String get meeting_approved_title => 'Approved';

  @override
  String get meeting_approved_subtitle => 'Redirecting to room…';

  @override
  String get meeting_denied_title => 'Denied';

  @override
  String get meeting_denied_subtitle => 'The host denied your request.';

  @override
  String get meeting_pending_title => 'Waiting for approval';

  @override
  String get meeting_pending_subtitle =>
      'The host will see your request and decide when to let you in.';

  @override
  String meeting_load_error(String details) {
    return 'Failed to load meeting: $details';
  }

  @override
  String meeting_init_error(Object error) {
    return 'Initialization error: $error';
  }

  @override
  String meeting_participants_error(Object error) {
    return 'Members: $error';
  }

  @override
  String meeting_bg_unavailable(Object error) {
    return 'Background unavailable: $error';
  }

  @override
  String get meeting_leave => 'Leave';

  @override
  String get meeting_screen_share_ios =>
      'Screen sharing on iOS requires Broadcast Extension (coming in the next release)';

  @override
  String meeting_screen_share_failed(String details) {
    return 'Failed to start screen sharing: $details';
  }

  @override
  String get meeting_tooltip_speaker_mode => 'Speaker mode';

  @override
  String get meeting_tooltip_grid_mode => 'Grid mode';

  @override
  String get meeting_tooltip_copy_link => 'Copy link (browser join)';

  @override
  String get meeting_mic_on => 'Unmute';

  @override
  String get meeting_mic_off => 'Mute';

  @override
  String get meeting_camera_on => 'Camera on';

  @override
  String get meeting_camera_off => 'Camera off';

  @override
  String get meeting_switch_camera => 'Switch';

  @override
  String get meeting_hand_lower => 'Lower';

  @override
  String get meeting_hand_raise => 'Hand';

  @override
  String get meeting_reaction => 'Reaction';

  @override
  String get meeting_screen_stop => 'Stop';

  @override
  String get meeting_screen_label => 'Screen';

  @override
  String get meeting_bg_off => 'BG';

  @override
  String get meeting_bg_blur => 'Blur';

  @override
  String get meeting_bg_image => 'Image';

  @override
  String get meeting_participants_button => 'Members';

  @override
  String get meeting_notifications_button => 'Activity';

  @override
  String get meeting_pip_button => 'Minimize';

  @override
  String get settings_chats_bottom_nav_icons_title => 'Bottom navigation icons';

  @override
  String get settings_chats_bottom_nav_icons_subtitle =>
      'Choose icons and visual style like on the web.';

  @override
  String get settings_chats_nav_colorful => 'Colorful';

  @override
  String get settings_chats_nav_minimal => 'Minimal';

  @override
  String get settings_chats_nav_global_title => 'For all icons';

  @override
  String get settings_chats_nav_global_subtitle =>
      'Global layer: color, size, stroke width, and tile background.';

  @override
  String get settings_chats_reset_tooltip => 'Reset';

  @override
  String get settings_chats_collapse => 'Collapse';

  @override
  String get settings_chats_customize => 'Customize';

  @override
  String get settings_chats_reset_item_tooltip => 'Reset';

  @override
  String get settings_chats_style_tooltip => 'Style';

  @override
  String get settings_chats_icon_size => 'Icon size';

  @override
  String get settings_chats_stroke_width => 'Stroke width';

  @override
  String get settings_chats_default => 'Default';

  @override
  String get settings_chats_icon_search_hint_en => 'Search by name...';

  @override
  String get settings_chats_emoji_effects => 'Emoji effects';

  @override
  String get settings_chats_emoji_effects_subtitle =>
      'Animation profile for fullscreen emoji when tapping a single emoji in chat.';

  @override
  String get settings_chats_emoji_lite_desc =>
      'Lite: minimum load and maximum smoothness on low-end devices.';

  @override
  String get settings_chats_emoji_balanced_desc =>
      'Balanced: automatic compromise between performance and expressiveness.';

  @override
  String get settings_chats_emoji_cinematic_desc =>
      'Cinematic: maximum particles and depth for wow-effect.';

  @override
  String get settings_chats_preview_incoming_msg => 'Hey! How are you?';

  @override
  String get settings_chats_preview_outgoing_msg => 'Great, thanks!';

  @override
  String get settings_chats_preview_hello => 'Hello';

  @override
  String get chat_theme_title => 'Chat theme';

  @override
  String chat_theme_error_save(String error) {
    return 'Failed to save background: $error';
  }

  @override
  String chat_theme_error_upload(String error) {
    return 'Background upload error: $error';
  }

  @override
  String get chat_theme_delete_title => 'Delete background from gallery?';

  @override
  String get chat_theme_delete_body =>
      'The image will be removed from your backgrounds list. You can choose another one for this chat.';

  @override
  String chat_theme_error_delete(String error) {
    return 'Delete error: $error';
  }

  @override
  String get chat_theme_banner =>
      'The background of this chat is only for you. Global chat settings in \"Chat Settings\" remain unchanged.';

  @override
  String get chat_theme_current_bg => 'Current background';

  @override
  String get chat_theme_default_global => 'Default (global settings)';

  @override
  String get chat_theme_presets => 'Presets';

  @override
  String get chat_theme_global_tile => 'Global';

  @override
  String get chat_theme_pick_hint => 'Choose a preset or photo from gallery';

  @override
  String get contacts_title => 'Contacts';

  @override
  String get contacts_add_phone_prompt =>
      'Add a phone number in your profile to search contacts by number.';

  @override
  String get contacts_fallback_profile => 'Profile';

  @override
  String get contacts_fallback_user => 'User';

  @override
  String get contacts_status_online => 'online';

  @override
  String get contacts_status_recently => 'Last seen recently';

  @override
  String contacts_status_today_at(String time) {
    return 'Last seen at $time';
  }

  @override
  String get contacts_status_yesterday => 'Last seen yesterday';

  @override
  String get contacts_status_year_ago => 'Last seen a year ago';

  @override
  String contacts_status_years_ago(String years) {
    return 'Last seen $years ago';
  }

  @override
  String contacts_status_date(String date) {
    return 'Last seen $date';
  }

  @override
  String get contacts_empty_state =>
      'No contacts found.\nTap the button on the right to sync your phone book.';

  @override
  String get add_contact_title => 'New contact';

  @override
  String get add_contact_sync_off => 'Sync is off in the app.';

  @override
  String get add_contact_enable_system_access =>
      'Enable contacts access for LighChat in system settings.';

  @override
  String get add_contact_sync_on => 'Sync is on';

  @override
  String get add_contact_sync_failed => 'Couldn\'t enable contact sync';

  @override
  String get add_contact_invalid_phone => 'Enter a valid phone number';

  @override
  String get add_contact_not_found_by_phone =>
      'No contact found for this number';

  @override
  String get add_contact_found => 'Contact found';

  @override
  String add_contact_search_error(String error) {
    return 'Search failed: $error';
  }

  @override
  String get add_contact_qr_no_profile =>
      'QR code doesn\'t contain a LighChat profile';

  @override
  String get add_contact_qr_own_profile => 'This is your own profile';

  @override
  String get add_contact_qr_profile_not_found =>
      'Profile from QR code not found';

  @override
  String get add_contact_qr_found => 'Contact found via QR code';

  @override
  String add_contact_qr_read_error(String error) {
    return 'Couldn\'t read QR code: $error';
  }

  @override
  String get add_contact_cannot_add_user => 'Cannot add this user';

  @override
  String add_contact_add_error(String error) {
    return 'Couldn\'t add contact: $error';
  }

  @override
  String get add_contact_country_search_hint => 'Search country or code';

  @override
  String get add_contact_sync_with_phone => 'Sync with phone';

  @override
  String get add_contact_add_by_qr => 'Add by QR code';

  @override
  String get add_contact_results_unavailable => 'Results not available yet';

  @override
  String add_contact_profile_load_error(String error) {
    return 'Couldn\'t load contact: $error';
  }

  @override
  String get add_contact_profile_not_found => 'Profile not found';

  @override
  String get add_contact_badge_already_added => 'Already added';

  @override
  String get add_contact_badge_new => 'New contact';

  @override
  String get add_contact_badge_unavailable => 'Unavailable';

  @override
  String get add_contact_open_contact => 'Open contact';

  @override
  String get add_contact_add_to_contacts => 'Add to contacts';

  @override
  String get add_contact_add_unavailable => 'Adding unavailable';

  @override
  String get add_contact_searching => 'Searching for contact...';

  @override
  String get add_contact_scan_qr_title => 'Scan QR code';

  @override
  String get add_contact_flash_tooltip => 'Flash';

  @override
  String get add_contact_scan_qr_hint =>
      'Point your camera at a LighChat profile QR code';

  @override
  String get contacts_edit_enter_name => 'Enter the contact name.';

  @override
  String contacts_edit_save_error(String error) {
    return 'Couldn\'t save contact: $error';
  }

  @override
  String get contacts_edit_first_name_hint => 'First name';

  @override
  String get contacts_edit_last_name_hint => 'Last name';

  @override
  String get contacts_edit_name_disclaimer =>
      'This name is visible only to you: in chats, search, and the contact list.';

  @override
  String contacts_edit_error(String error) {
    return 'Error: $error';
  }

  @override
  String get chat_settings_color_default => 'Default';

  @override
  String get chat_settings_color_lilac => 'Lilac';

  @override
  String get chat_settings_color_pink => 'Pink';

  @override
  String get chat_settings_color_green => 'Green';

  @override
  String get chat_settings_color_coral => 'Coral';

  @override
  String get chat_settings_color_mint => 'Mint';

  @override
  String get chat_settings_color_sky => 'Sky';

  @override
  String get chat_settings_color_purple => 'Purple';

  @override
  String get chat_settings_color_crimson => 'Crimson';

  @override
  String get chat_settings_color_tiffany => 'Tiffany';

  @override
  String get chat_settings_color_yellow => 'Yellow';

  @override
  String get chat_settings_color_powder => 'Powder';

  @override
  String get chat_settings_color_turquoise => 'Turquoise';

  @override
  String get chat_settings_color_blue => 'Blue';

  @override
  String get chat_settings_color_sunset => 'Sunset';

  @override
  String get chat_settings_color_tender => 'Tender';

  @override
  String get chat_settings_color_lime => 'Lime';

  @override
  String get chat_settings_color_graphite => 'Graphite';

  @override
  String get chat_settings_color_no_bg => 'No background';

  @override
  String get chat_settings_icon_color => 'Icon color';

  @override
  String get chat_settings_icon_size => 'Icon size';

  @override
  String get chat_settings_stroke_width => 'Stroke width';

  @override
  String get chat_settings_tile_background => 'Tile background';

  @override
  String get chat_settings_bottom_nav_icons => 'Bottom navigation icons';

  @override
  String get chat_settings_bottom_nav_description =>
      'Choose icons and visual style like on the web.';

  @override
  String get chat_settings_bottom_nav_global_description =>
      'Shared layer: color, size, stroke and tile background.';

  @override
  String get chat_settings_colorful => 'Colorful';

  @override
  String get chat_settings_minimalism => 'Minimal';

  @override
  String get chat_settings_for_all_icons => 'For all icons';

  @override
  String get chat_settings_customize => 'Customize';

  @override
  String get chat_settings_hide => 'Hide';

  @override
  String get chat_settings_reset => 'Reset';

  @override
  String get chat_settings_reset_item => 'Reset';

  @override
  String get chat_settings_style => 'Style';

  @override
  String get chat_settings_select => 'Select';

  @override
  String get chat_settings_reset_size => 'Reset size';

  @override
  String get chat_settings_reset_stroke => 'Reset stroke';

  @override
  String get chat_settings_default_gradient => 'Default gradient';

  @override
  String get chat_settings_inherit_global => 'Inherit from global';

  @override
  String get chat_settings_no_bg_on => 'No background (on)';

  @override
  String get chat_settings_no_bg => 'No background';

  @override
  String get chat_settings_outgoing_messages => 'Outgoing messages';

  @override
  String get chat_settings_incoming_messages => 'Incoming messages';

  @override
  String get chat_settings_font_size => 'Font size';

  @override
  String get chat_settings_font_small => 'Small';

  @override
  String get chat_settings_font_medium => 'Medium';

  @override
  String get chat_settings_font_large => 'Large';

  @override
  String get chat_settings_bubble_shape => 'Bubble shape';

  @override
  String get chat_settings_bubble_rounded => 'Rounded';

  @override
  String get chat_settings_bubble_square => 'Square';

  @override
  String get chat_settings_chat_background => 'Chat background';

  @override
  String get chat_settings_background_hint =>
      'Choose a photo from gallery or customize';

  @override
  String get chat_settings_emoji_effects => 'Emoji effects';

  @override
  String get chat_settings_emoji_description =>
      'Animation profile for fullscreen emoji burst on tap in chat.';

  @override
  String get chat_settings_emoji_lite =>
      'Lite: minimal load, smoothest on low-end devices.';

  @override
  String get chat_settings_emoji_cinematic =>
      'Cinematic: maximum particles and depth for a wow effect.';

  @override
  String get chat_settings_emoji_balanced =>
      'Balanced: automatic compromise between performance and expressiveness.';

  @override
  String get chat_settings_additional => 'Additional';

  @override
  String get chat_settings_show_time => 'Show time';

  @override
  String get chat_settings_show_time_hint => 'Sent time under messages';

  @override
  String get chat_settings_reset_all => 'Reset settings';

  @override
  String get chat_settings_preview_incoming => 'Hi! How are you?';

  @override
  String get chat_settings_preview_outgoing => 'Great, thanks!';

  @override
  String get chat_settings_preview_hello => 'Hello';

  @override
  String chat_settings_icon_picker_title(String label) {
    return 'Icon: \"$label\"';
  }

  @override
  String get chat_settings_search_hint => 'Search by name (eng.)...';

  @override
  String meeting_tab_participants(Object count) {
    return 'Members ($count)';
  }

  @override
  String get meeting_tab_polls => 'Polls';

  @override
  String meeting_tab_polls_count(Object count) {
    return 'Polls ($count)';
  }

  @override
  String get meeting_tab_chat => 'Chat';

  @override
  String meeting_tab_chat_count(Object count) {
    return 'Chat ($count)';
  }

  @override
  String meeting_tab_requests(Object count) {
    return 'Requests ($count)';
  }

  @override
  String get meeting_kick => 'Remove from room';

  @override
  String meeting_file_too_big(Object name) {
    return 'File too big: $name';
  }

  @override
  String meeting_send_error(Object error) {
    return 'Couldn\'t send: $error';
  }

  @override
  String meeting_save_error(Object error) {
    return 'Couldn\'t save: $error';
  }

  @override
  String meeting_delete_error(Object error) {
    return 'Couldn\'t delete: $error';
  }

  @override
  String get meeting_no_messages => 'No messages yet';

  @override
  String get meeting_join_enter_name => 'Enter your name';

  @override
  String get meeting_join_guest => 'Guest';

  @override
  String get meeting_join_as_label => 'You\'ll join as';

  @override
  String get meeting_lobby_camera_blocked =>
      'Camera permission is denied. You\'ll join with the camera off.';

  @override
  String get meeting_join_button => 'Join';

  @override
  String meeting_join_load_error(Object error) {
    return 'Meeting load error: $error';
  }

  @override
  String get meeting_private_hint =>
      'Private meeting: the host will decide whether to let you in after your request.';

  @override
  String get meeting_public_hint =>
      'Open meeting: join via link without waiting.';

  @override
  String get meeting_name_label => 'Your name';

  @override
  String get meeting_waiting_title => 'Waiting for approval';

  @override
  String get meeting_waiting_subtitle =>
      'The host will see your request and decide when to let you in.';

  @override
  String get meeting_screen_share_ios_hint =>
      'Screen sharing on iOS requires a Broadcast Extension (in development).';

  @override
  String meeting_screen_share_error(Object error) {
    return 'Couldn\'t start screen sharing: $error';
  }

  @override
  String get meeting_speaker_mode => 'Speaker mode';

  @override
  String get meeting_grid_mode => 'Grid mode';

  @override
  String get meeting_copy_link_tooltip => 'Copy link (browser entry)';

  @override
  String get group_members_subtitle_creator => 'Group creator';

  @override
  String get group_members_subtitle_admin => 'Administrator';

  @override
  String get group_members_subtitle_member => 'Member';

  @override
  String group_members_total_count(int count) {
    return 'Total: $count';
  }

  @override
  String get group_members_copy_invite_tooltip => 'Copy invite link';

  @override
  String get group_members_add_member_tooltip => 'Add member';

  @override
  String get group_members_invite_copied => 'Invite link copied';

  @override
  String group_members_copy_link_error(String error) {
    return 'Failed to copy link: $error';
  }

  @override
  String get group_members_added => 'Members added';

  @override
  String get group_members_revoke_admin_title => 'Revoke admin privileges?';

  @override
  String group_members_revoke_admin_body(String name) {
    return '$name will lose admin privileges. They will remain in the group as a regular member.';
  }

  @override
  String get group_members_grant_admin_title => 'Grant admin privileges?';

  @override
  String group_members_grant_admin_body(String name) {
    return '$name will receive admin privileges: can edit the group, remove members, and manage messages.';
  }

  @override
  String get group_members_revoke_admin_action => 'Revoke';

  @override
  String get group_members_grant_admin_action => 'Grant';

  @override
  String get group_members_remove_title => 'Remove member?';

  @override
  String group_members_remove_body(String name) {
    return '$name will be removed from the group. You can undo this by adding the member again.';
  }

  @override
  String get group_members_remove_action => 'Remove';

  @override
  String get group_members_removed => 'Member removed';

  @override
  String get group_members_menu_revoke_admin => 'Remove admin';

  @override
  String get group_members_menu_grant_admin => 'Make admin';

  @override
  String get group_members_menu_remove => 'Remove from group';

  @override
  String get group_members_creator_badge => 'CREATOR';

  @override
  String get group_members_add_title => 'Add members';

  @override
  String get group_members_search_contacts => 'Search contacts';

  @override
  String get group_members_all_in_group =>
      'All your contacts are already in the group.';

  @override
  String get group_members_nobody_found => 'Nobody found.';

  @override
  String get group_members_user_fallback => 'User';

  @override
  String get group_members_select_members => 'Select members';

  @override
  String group_members_add_count(int count) {
    return 'Add ($count)';
  }

  @override
  String group_members_contacts_load_error(String error) {
    return 'Failed to load contacts: $error';
  }

  @override
  String group_members_auth_error(String error) {
    return 'Authorization error: $error';
  }

  @override
  String group_members_add_failed(String error) {
    return 'Failed to add members: $error';
  }

  @override
  String get group_not_found => 'Group not found.';

  @override
  String get group_not_member => 'You are not a member of this group.';

  @override
  String get poll_create_title => 'Chat poll';

  @override
  String get poll_question_label => 'Question';

  @override
  String get poll_question_hint => 'E.g.: What time shall we meet?';

  @override
  String get poll_description_label => 'Description (optional)';

  @override
  String get poll_options_title => 'Options';

  @override
  String poll_option_hint(int index) {
    return 'Option $index';
  }

  @override
  String get poll_add_option => 'Add option';

  @override
  String get poll_switch_anonymous => 'Anonymous voting';

  @override
  String get poll_switch_anonymous_sub => 'Do not show who voted for what';

  @override
  String get poll_switch_multi => 'Multiple answers';

  @override
  String get poll_switch_multi_sub => 'Multiple options can be selected';

  @override
  String get poll_switch_add_options => 'Add options';

  @override
  String get poll_switch_add_options_sub =>
      'Participants can suggest their own options';

  @override
  String get poll_switch_revote => 'Can change vote';

  @override
  String get poll_switch_revote_sub => 'Revote allowed until poll closes';

  @override
  String get poll_switch_shuffle => 'Shuffle options';

  @override
  String get poll_switch_shuffle_sub => 'Different order for each participant';

  @override
  String get poll_switch_quiz => 'Quiz mode';

  @override
  String get poll_switch_quiz_sub => 'One correct answer';

  @override
  String get poll_correct_option_label => 'Correct option';

  @override
  String get poll_quiz_explanation_label => 'Explanation (optional)';

  @override
  String get poll_close_by_time => 'Close by time';

  @override
  String get poll_close_not_set => 'Not set';

  @override
  String get poll_close_reset => 'Reset deadline';

  @override
  String get poll_publish => 'Publish';

  @override
  String get poll_error_empty_question => 'Enter a question';

  @override
  String get poll_error_min_options => 'At least 2 options are required';

  @override
  String get poll_error_select_correct => 'Select the correct option';

  @override
  String get poll_error_future_time => 'Closing time must be in the future';

  @override
  String get poll_unavailable => 'Poll unavailable';

  @override
  String get poll_loading => 'Loading poll…';

  @override
  String get poll_not_found => 'Poll not found';

  @override
  String get poll_status_cancelled => 'Cancelled';

  @override
  String get poll_status_ended => 'Ended';

  @override
  String get poll_status_draft => 'Draft';

  @override
  String get poll_status_active => 'Active';

  @override
  String get poll_badge_public => 'Public';

  @override
  String get poll_badge_multi => 'Multiple answers';

  @override
  String get poll_badge_quiz => 'Quiz';

  @override
  String get poll_menu_restart => 'Restart';

  @override
  String get poll_menu_end => 'End';

  @override
  String get poll_menu_delete => 'Delete';

  @override
  String get poll_submit_vote => 'Submit vote';

  @override
  String get poll_suggest_option_hint => 'Suggest an option';

  @override
  String get poll_revote => 'Change vote';

  @override
  String poll_votes_count(int count) {
    return '$count votes';
  }

  @override
  String get poll_show_voters => 'Who voted';

  @override
  String get poll_hide_voters => 'Hide';

  @override
  String get poll_vote_error => 'Error while voting';

  @override
  String get poll_add_option_error => 'Failed to add option';

  @override
  String get poll_error_generic => 'Error';

  @override
  String get durak_your_turn => 'Your turn';

  @override
  String get durak_winner_label => 'Winner';

  @override
  String get durak_rematch => 'Play again';

  @override
  String get durak_surrender_tooltip => 'End game';

  @override
  String get durak_close_tooltip => 'Close';

  @override
  String get durak_fx_took => 'Took';

  @override
  String get durak_fx_beat => 'Beaten';

  @override
  String get durak_opponent_role_defend => 'DEF';

  @override
  String get durak_opponent_role_attack => 'ATK';

  @override
  String get durak_opponent_role_throwin => 'THR';

  @override
  String get durak_foul_banner_title => 'Cheater! Missed:';

  @override
  String get durak_pending_resolution_attacker =>
      'Waiting for foul check… Press \"Confirm Beaten\" if everyone agrees.';

  @override
  String get durak_pending_resolution_other =>
      'Waiting for foul check… You can press \"Foul!\" if you noticed cheating.';

  @override
  String durak_tournament_played(int finished, int total) {
    return 'Played $finished of $total';
  }

  @override
  String get durak_tournament_finished => 'Tournament finished';

  @override
  String get durak_tournament_next => 'Next tournament game';

  @override
  String get durak_single_game => 'Single game';

  @override
  String get durak_tournament_total_games_title =>
      'How many games in the tournament?';

  @override
  String get durak_finish_game_tooltip => 'End game';

  @override
  String get durak_lobby_game_unavailable =>
      'Game is unavailable or has been deleted';

  @override
  String get durak_lobby_back_tooltip => 'Back';

  @override
  String get durak_lobby_waiting => 'Waiting for opponent…';

  @override
  String get durak_lobby_start => 'Start game';

  @override
  String get durak_lobby_waiting_short => 'Waiting…';

  @override
  String get durak_lobby_ready => 'Ready';

  @override
  String get durak_lobby_empty_slot => 'Waiting…';

  @override
  String get durak_settings_timer_subtitle => '15 seconds by default';

  @override
  String get durak_dm_game_active => 'Durak game in progress';

  @override
  String get durak_dm_game_created => 'Durak game created';

  @override
  String get game_durak_subtitle => 'Single game or tournament';

  @override
  String get group_member_write_dm => 'Send direct message';

  @override
  String get group_member_open_dm_hint => 'Open direct chat with member';

  @override
  String get group_member_profile_not_loaded =>
      'Member profile not loaded yet.';

  @override
  String group_member_open_dm_error(String error) {
    return 'Failed to open direct chat: $error';
  }

  @override
  String get group_avatar_photo_title => 'Group photo';

  @override
  String get group_avatar_add_photo => 'Add photo';

  @override
  String get group_avatar_change => 'Change avatar';

  @override
  String get group_avatar_remove => 'Remove avatar';

  @override
  String group_avatar_process_error(String error) {
    return 'Failed to process photo: $error';
  }

  @override
  String get group_mention_no_matches => 'No matches';

  @override
  String get durak_error_defense_does_not_beat =>
      'This card does not beat the attacking card';

  @override
  String get durak_error_only_attacker_first => 'Attacker goes first';

  @override
  String get durak_error_defender_cannot_attack =>
      'Defender cannot throw in right now';

  @override
  String get durak_error_not_allowed_throwin =>
      'You cannot throw in this round';

  @override
  String get durak_error_throwin_not_your_turn =>
      'Another player is throwing in now';

  @override
  String get durak_error_rank_not_allowed =>
      'You can only throw in cards of the same rank';

  @override
  String get durak_error_cannot_throw_in => 'Cannot throw in more cards';

  @override
  String get durak_error_card_not_in_hand =>
      'This card is no longer in your hand';

  @override
  String get durak_error_already_defended => 'This card is already defended';

  @override
  String get durak_error_bad_attack_index =>
      'Select an attacking card to defend against';

  @override
  String get durak_error_only_defender => 'Another player is defending now';

  @override
  String get durak_error_defender_already_taking =>
      'Defender is already taking cards';

  @override
  String get durak_error_game_not_active => 'Game is no longer active';

  @override
  String get durak_error_not_in_lobby => 'Lobby has already started';

  @override
  String get durak_error_game_already_active => 'Game has already started';

  @override
  String get durak_error_active_game_exists =>
      'There is already an active game in this chat';

  @override
  String get durak_error_resolution_pending => 'Finish the disputed move first';

  @override
  String get durak_error_rematch_failed =>
      'Failed to prepare rematch. Please try again';

  @override
  String get durak_error_unauthenticated => 'You need to sign in';

  @override
  String get durak_error_permission_denied =>
      'This action is not available to you';

  @override
  String get durak_error_invalid_argument => 'Invalid move';

  @override
  String get durak_error_failed_precondition =>
      'Move is not available right now';

  @override
  String get durak_error_server => 'Failed to execute move. Please try again';

  @override
  String pinned_count(int count) {
    return 'Pinned: $count';
  }

  @override
  String get pinned_single => 'Pinned';

  @override
  String get pinned_unpin_tooltip => 'Unpin';

  @override
  String get pinned_type_image => 'Image';

  @override
  String get pinned_type_video => 'Video';

  @override
  String get pinned_type_video_circle => 'Video circle';

  @override
  String get pinned_type_voice => 'Voice message';

  @override
  String get pinned_type_poll => 'Poll';

  @override
  String get pinned_type_link => 'Link';

  @override
  String get pinned_type_location => 'Location';

  @override
  String get pinned_type_sticker => 'Sticker';

  @override
  String get pinned_type_file => 'File';

  @override
  String get call_entry_login_required_title => 'Login required';

  @override
  String get call_entry_login_required_subtitle =>
      'Open the app and sign in to your account.';

  @override
  String get call_entry_not_found_title => 'Call not found';

  @override
  String get call_entry_not_found_subtitle =>
      'The call has already ended or been deleted. Returning to calls…';

  @override
  String get call_entry_to_calls => 'To calls';

  @override
  String get call_entry_ended_title => 'Call ended';

  @override
  String get call_entry_ended_subtitle =>
      'This call is no longer available. Returning to calls…';

  @override
  String get call_entry_caller_fallback => 'Caller';

  @override
  String get call_entry_opening_title => 'Opening call…';

  @override
  String get call_entry_connecting_video => 'Connecting to video call';

  @override
  String get call_entry_connecting_audio => 'Connecting to audio call';

  @override
  String get call_entry_loading_subtitle => 'Loading call data';

  @override
  String get call_entry_error_title => 'Error opening call';

  @override
  String chat_theme_save_error(Object error) {
    return 'Failed to save background: $error';
  }

  @override
  String chat_theme_load_error(Object error) {
    return 'Error loading background: $error';
  }

  @override
  String chat_theme_delete_error(Object error) {
    return 'Deletion error: $error';
  }

  @override
  String get chat_theme_description =>
      'The background of this conversation is only visible to you. Global chat settings in the Chat Settings section are not affected.';

  @override
  String get chat_theme_default_bg => 'Default (global settings)';

  @override
  String get chat_theme_global_label => 'Global';

  @override
  String get chat_theme_hint => 'Choose a preset or photo from gallery';

  @override
  String get date_today => 'Today';

  @override
  String get date_yesterday => 'Yesterday';

  @override
  String get date_month_1 => 'January';

  @override
  String get date_month_2 => 'February';

  @override
  String get date_month_3 => 'March';

  @override
  String get date_month_4 => 'April';

  @override
  String get date_month_5 => 'May';

  @override
  String get date_month_6 => 'June';

  @override
  String get date_month_7 => 'July';

  @override
  String get date_month_8 => 'August';

  @override
  String get date_month_9 => 'September';

  @override
  String get date_month_10 => 'October';

  @override
  String get date_month_11 => 'November';

  @override
  String get date_month_12 => 'December';

  @override
  String get video_circle_camera_unavailable => 'Camera unavailable';

  @override
  String video_circle_camera_error(Object error) {
    return 'Failed to open camera: $error';
  }

  @override
  String video_circle_record_error(Object error) {
    return 'Recording error: $error';
  }

  @override
  String get video_circle_file_not_found => 'Recording file not found';

  @override
  String get video_circle_play_error => 'Failed to play recording';

  @override
  String video_circle_send_error(Object error) {
    return 'Failed to send: $error';
  }

  @override
  String video_circle_switch_error(Object error) {
    return 'Failed to switch camera: $error';
  }

  @override
  String video_circle_pause_error_detail(Object description, Object code) {
    return 'Pause unavailable: $description ($code)';
  }

  @override
  String video_circle_pause_error(Object error) {
    return 'Pause recording: $error';
  }

  @override
  String get video_circle_camera_fallback_error => 'Camera error';

  @override
  String get video_circle_retry => 'Retry';

  @override
  String get video_circle_sending => 'Sending...';

  @override
  String get video_circle_recorded => 'Circle recorded';

  @override
  String get video_circle_swipe_cancel => 'Swipe left to cancel';

  @override
  String media_screen_error(Object error) {
    return 'Error loading media: $error';
  }

  @override
  String get media_screen_title => 'Media, links and files';

  @override
  String get media_tab_media => 'Media';

  @override
  String get media_tab_circles => 'Circles';

  @override
  String get media_tab_files => 'Files';

  @override
  String get media_tab_links => 'Links';

  @override
  String get media_tab_audio => 'Audio';

  @override
  String get media_empty_files => 'No files';

  @override
  String get media_empty_media => 'No media';

  @override
  String get media_attachment_fallback => 'Attachment';

  @override
  String get media_empty_circles => 'No circles';

  @override
  String get media_empty_links => 'No links';

  @override
  String get media_empty_audio => 'No voice messages';

  @override
  String get media_sender_you => 'You';

  @override
  String get media_sender_fallback => 'Participant';

  @override
  String get call_detail_login_required => 'Login required.';

  @override
  String get call_detail_not_found => 'Call not found or no access.';

  @override
  String get call_detail_unknown => 'Unknown';

  @override
  String get call_detail_title => 'Call details';

  @override
  String get call_detail_video => 'Video call';

  @override
  String get call_detail_audio => 'Audio call';

  @override
  String get call_detail_outgoing => 'Outgoing';

  @override
  String get call_detail_incoming => 'Incoming';

  @override
  String get call_detail_date_label => 'Date:';

  @override
  String get call_detail_duration_label => 'Duration:';

  @override
  String get call_detail_call_button => 'Call';

  @override
  String get call_detail_video_button => 'Video';

  @override
  String call_detail_error(Object error) {
    return 'Error: $error';
  }

  @override
  String get durak_took => 'Took';

  @override
  String get durak_beaten => 'Beaten';

  @override
  String get durak_end_game_tooltip => 'End game';

  @override
  String get durak_role_beats => 'DEF';

  @override
  String get durak_role_move => 'MOVE';

  @override
  String get durak_role_throw => 'THR';

  @override
  String get durak_cheater_label => 'Cheater! Missed:';

  @override
  String get durak_waiting_foll_confirm =>
      'Waiting for foul call… Press \"Confirm Beaten\" if everyone agrees.';

  @override
  String get durak_waiting_foll_call =>
      'Waiting for foul call… You can now press \"Foul!\" if you noticed cheating.';

  @override
  String get durak_winner => 'Winner';

  @override
  String get durak_play_again => 'Play again';

  @override
  String durak_games_progress(Object finished, Object total) {
    return 'Played $finished of $total';
  }

  @override
  String get durak_next_round => 'Next tournament round';

  @override
  String audio_call_error(Object error) {
    return 'Call error: $error';
  }

  @override
  String get audio_call_ended => 'Call ended';

  @override
  String get audio_call_missed => 'Missed call';

  @override
  String get audio_call_cancelled => 'Call cancelled';

  @override
  String get audio_call_offer_not_ready => 'Offer not ready yet, try again';

  @override
  String get audio_call_invalid_data => 'Invalid call data';

  @override
  String audio_call_accept_error(Object error) {
    return 'Failed to accept call: $error';
  }

  @override
  String get audio_call_incoming => 'Incoming audio call';

  @override
  String get audio_call_calling => 'Audio call…';

  @override
  String privacy_save_error(Object error) {
    return 'Failed to save settings: $error';
  }

  @override
  String privacy_load_error(Object error) {
    return 'Error loading privacy: $error';
  }

  @override
  String get privacy_visibility => 'Visibility';

  @override
  String get privacy_online_status => 'Online status';

  @override
  String get privacy_last_visit => 'Last seen';

  @override
  String get privacy_read_receipts => 'Read receipts';

  @override
  String get privacy_profile_info => 'Profile info';

  @override
  String get privacy_phone_number => 'Phone number';

  @override
  String get privacy_birthday => 'Birthday';

  @override
  String get privacy_about => 'About';

  @override
  String starred_load_error(Object error) {
    return 'Error loading starred: $error';
  }

  @override
  String get starred_title => 'Starred';

  @override
  String get starred_empty => 'No starred messages in this chat';

  @override
  String get starred_message_fallback => 'Message';

  @override
  String get starred_sender_you => 'You';

  @override
  String get starred_sender_fallback => 'Participant';

  @override
  String get starred_type_poll => 'Poll';

  @override
  String get starred_type_location => 'Location';

  @override
  String get starred_type_attachment => 'Attachment';

  @override
  String starred_today_prefix(Object time) {
    return 'Today, $time';
  }

  @override
  String get contact_edit_name_required => 'Enter contact name.';

  @override
  String contact_edit_save_error(Object error) {
    return 'Failed to save contact: $error';
  }

  @override
  String get contact_edit_user_fallback => 'User';

  @override
  String get contact_edit_first_name_hint => 'First name';

  @override
  String get contact_edit_last_name_hint => 'Last name';

  @override
  String get contact_edit_description =>
      'This name is only visible to you: in chats, search and contacts list.';

  @override
  String contact_edit_error(Object error) {
    return 'Error: $error';
  }

  @override
  String get voice_no_mic_access => 'No microphone access';

  @override
  String get voice_start_error => 'Failed to start recording';

  @override
  String get voice_file_not_received => 'Recording file not received';

  @override
  String get voice_stop_error => 'Failed to stop recording';

  @override
  String get voice_title => 'Voice message';

  @override
  String get voice_recording => 'Recording';

  @override
  String get voice_ready => 'Recording ready';

  @override
  String get voice_stop_button => 'Stop';

  @override
  String get voice_record_again => 'Record again';

  @override
  String get attach_photo_video => 'Photo/Video';

  @override
  String get attach_files => 'Files';

  @override
  String get attach_circle => 'Circle';

  @override
  String get attach_location => 'Location';

  @override
  String get attach_poll => 'Poll';

  @override
  String get attach_stickers => 'Stickers';

  @override
  String get attach_clipboard => 'Clipboard';

  @override
  String get attach_text => 'Text';

  @override
  String get attach_title => 'Attach';

  @override
  String notif_save_error(Object error) {
    return 'Failed to save: $error';
  }

  @override
  String get notif_title => 'Notifications in this chat';

  @override
  String get notif_description =>
      'Settings below apply only to this conversation and do not change global app notifications.';

  @override
  String get notif_this_chat => 'This chat';

  @override
  String get notif_mute_title => 'Mute and hide notifications';

  @override
  String get notif_mute_subtitle =>
      'Do not disturb for this chat on this device.';

  @override
  String get notif_preview_title => 'Show text preview';

  @override
  String get notif_preview_subtitle =>
      'When off — notification title without message snippet (where supported).';

  @override
  String get poll_create_enter_question => 'Enter a question';

  @override
  String get poll_create_min_options => 'At least 2 options required';

  @override
  String get poll_create_select_correct => 'Select the correct option';

  @override
  String get poll_create_future_time => 'Close time must be in the future';

  @override
  String get poll_create_question_label => 'Question';

  @override
  String get poll_create_question_hint =>
      'For example: What time are we meeting?';

  @override
  String get poll_create_explanation_label => 'Explanation (optional)';

  @override
  String get poll_create_options_title => 'Options';

  @override
  String poll_create_option_hint(Object index) {
    return 'Option $index';
  }

  @override
  String get poll_create_add_option => 'Add option';

  @override
  String get poll_create_anonymous_title => 'Anonymous voting';

  @override
  String get poll_create_anonymous_subtitle => 'Don\'t show who voted for what';

  @override
  String get poll_create_multi_title => 'Multiple answers';

  @override
  String get poll_create_multi_subtitle => 'Can select multiple options';

  @override
  String get poll_create_user_options_title => 'User-submitted options';

  @override
  String get poll_create_user_options_subtitle =>
      'Participants can suggest their own option';

  @override
  String get poll_create_revote_title => 'Allow revote';

  @override
  String get poll_create_revote_subtitle => 'Can change vote until poll closes';

  @override
  String get poll_create_shuffle_title => 'Shuffle options';

  @override
  String get poll_create_shuffle_subtitle =>
      'Each participant sees a different order';

  @override
  String get poll_create_quiz_title => 'Quiz mode';

  @override
  String get poll_create_quiz_subtitle => 'One correct answer';

  @override
  String get poll_create_correct_option_label => 'Correct option';

  @override
  String get poll_create_close_by_time => 'Close by time';

  @override
  String get poll_create_not_set => 'Not set';

  @override
  String get poll_create_reset_deadline => 'Reset deadline';

  @override
  String get poll_create_publish => 'Publish';

  @override
  String get poll_error => 'Error';

  @override
  String get poll_status_finished => 'Finished';

  @override
  String get poll_restart => 'Restart';

  @override
  String get poll_finish => 'Finish';

  @override
  String get poll_suggest_hint => 'Suggest an option';

  @override
  String get poll_voters_toggle_hide => 'Hide';

  @override
  String get poll_voters_toggle_show => 'Who voted';

  @override
  String get e2ee_disable_title => 'Disable encryption?';

  @override
  String get e2ee_disable_body =>
      'New messages will be sent without end-to-end encryption. Previously sent encrypted messages will remain in the feed.';

  @override
  String get e2ee_disable_button => 'Disable';

  @override
  String e2ee_disable_error(Object error) {
    return 'Failed to disable: $error';
  }

  @override
  String get e2ee_screen_title => 'Encryption';

  @override
  String get e2ee_enabled_description =>
      'End-to-end encryption is enabled for this chat.';

  @override
  String get e2ee_disabled_description => 'End-to-end encryption is disabled.';

  @override
  String get e2ee_info_text =>
      'When encryption is enabled, the content of new messages is only available to chat participants on their devices. Disabling only affects new messages.';

  @override
  String get e2ee_enable_title => 'Enable encryption';

  @override
  String e2ee_status_enabled(Object epoch) {
    return 'Enabled (key epoch: $epoch)';
  }

  @override
  String get e2ee_status_disabled => 'Disabled';

  @override
  String get e2ee_data_types_title => 'Data types';

  @override
  String get e2ee_data_types_info =>
      'This setting does not change the protocol. It controls which data types to send encrypted.';

  @override
  String get e2ee_chat_settings_title => 'Encryption settings for this chat';

  @override
  String get e2ee_chat_settings_override => 'Using chat-specific settings.';

  @override
  String get e2ee_chat_settings_global => 'Inheriting global settings.';

  @override
  String get e2ee_text_messages => 'Text messages';

  @override
  String get e2ee_attachments => 'Attachments (media/files)';

  @override
  String get e2ee_override_hint =>
      'To change for this chat — enable \"Override\".';

  @override
  String get group_member_fallback => 'Participant';

  @override
  String get group_role_creator => 'Group creator';

  @override
  String get group_role_admin => 'Administrator';

  @override
  String group_total_count(Object count) {
    return 'Total: $count';
  }

  @override
  String get group_copy_invite_tooltip => 'Copy invite link';

  @override
  String get group_add_member_tooltip => 'Add member';

  @override
  String get group_invite_copied => 'Invite link copied';

  @override
  String group_copy_invite_error(Object error) {
    return 'Failed to copy link: $error';
  }

  @override
  String get group_demote_confirm => 'Remove admin rights?';

  @override
  String get group_promote_confirm => 'Make administrator?';

  @override
  String group_demote_body(Object name) {
    return '$name will have their admin rights removed. The member will remain in the group as a regular member.';
  }

  @override
  String get group_demote_button => 'Remove rights';

  @override
  String get group_promote_button => 'Promote';

  @override
  String get group_kick_confirm => 'Remove member?';

  @override
  String get group_kick_button => 'Remove';

  @override
  String get group_member_kicked => 'Member removed';

  @override
  String get group_badge_creator => 'CREATOR';

  @override
  String get group_demote_action => 'Remove admin';

  @override
  String get group_promote_action => 'Make admin';

  @override
  String get group_kick_action => 'Remove from group';

  @override
  String group_contacts_load_error(Object error) {
    return 'Failed to load contacts: $error';
  }

  @override
  String get group_add_members_title => 'Add members';

  @override
  String get group_search_contacts_hint => 'Search contacts';

  @override
  String get group_all_contacts_in_group =>
      'All your contacts are already in the group.';

  @override
  String get group_nobody_found => 'Nobody found.';

  @override
  String get group_user_fallback => 'User';

  @override
  String get group_select_members => 'Select members';

  @override
  String group_add_count(Object count) {
    return 'Add ($count)';
  }

  @override
  String group_auth_error(Object error) {
    return 'Authorization error: $error';
  }

  @override
  String group_add_error(Object error) {
    return 'Failed to add members: $error';
  }

  @override
  String get add_contact_own_profile => 'This is your own profile';

  @override
  String get add_contact_qr_not_found => 'Profile from QR code not found';

  @override
  String add_contact_qr_error(Object error) {
    return 'Failed to read QR code: $error';
  }

  @override
  String get add_contact_not_allowed => 'Cannot add this user';

  @override
  String add_contact_save_error(Object error) {
    return 'Failed to add contact: $error';
  }

  @override
  String get add_contact_country_search => 'Search country or code';

  @override
  String get add_contact_sync_phone => 'Sync with phone';

  @override
  String get add_contact_qr_button => 'Add by QR code';

  @override
  String add_contact_load_error(Object error) {
    return 'Error loading contact: $error';
  }

  @override
  String get add_contact_user_fallback => 'User';

  @override
  String get add_contact_already_in_contacts => 'Already in contacts';

  @override
  String get add_contact_new => 'New contact';

  @override
  String get add_contact_unavailable => 'Unavailable';

  @override
  String get add_contact_scan_qr => 'Scan QR code';

  @override
  String get add_contact_scan_hint =>
      'Point camera at LighChat profile QR code';

  @override
  String get auth_validate_name_min_length =>
      'Name must be at least 2 characters';

  @override
  String get auth_validate_username_min_length =>
      'Username must be at least 3 characters';

  @override
  String get auth_validate_username_max_length =>
      'Username must not exceed 30 characters';

  @override
  String get auth_validate_username_format =>
      'Username contains invalid characters';

  @override
  String get auth_validate_phone_11_digits =>
      'Phone number must contain 11 digits';

  @override
  String get auth_validate_email_format => 'Enter a valid email';

  @override
  String get auth_validate_dob_invalid => 'Invalid date of birth';

  @override
  String get auth_validate_bio_max_length =>
      'Bio must not exceed 200 characters';

  @override
  String get auth_validate_password_min_length =>
      'Password must be at least 6 characters';

  @override
  String get auth_validate_passwords_mismatch => 'Passwords do not match';

  @override
  String get sticker_new_pack => 'New pack…';

  @override
  String get sticker_select_image_or_gif => 'Select an image or GIF';

  @override
  String sticker_send_error(Object error) {
    return 'Failed to send: $error';
  }

  @override
  String get sticker_saved => 'Saved to sticker pack';

  @override
  String get sticker_save_failed => 'Failed to download or save GIF';

  @override
  String get sticker_tab_my => 'My';

  @override
  String get sticker_tab_shared => 'Shared';

  @override
  String get sticker_no_packs => 'No sticker packs. Create a new one.';

  @override
  String get sticker_shared_not_configured => 'Shared packs not configured';

  @override
  String get sticker_recent => 'RECENT';

  @override
  String get sticker_gallery_description =>
      'Photos, PNG, GIF from device — straight to chat';

  @override
  String get sticker_shared_unavailable => 'Shared packs not yet available';

  @override
  String get sticker_gif_search_hint => 'Search GIF…';

  @override
  String sticker_gif_searched(Object query) {
    return 'Searched: $query';
  }

  @override
  String get sticker_gif_search_unavailable =>
      'GIF search temporarily unavailable.';

  @override
  String get sticker_gif_nothing_found => 'Nothing found';

  @override
  String get sticker_gif_all => 'All';

  @override
  String get sticker_gif_animated => 'ANIMATED';

  @override
  String get sticker_emoji_text_unavailable =>
      'Text emoji not available for this window.';

  @override
  String get wallpaper_sender => 'Contact';

  @override
  String get wallpaper_incoming => 'This is an incoming message.';

  @override
  String get wallpaper_outgoing => 'This is an outgoing message.';

  @override
  String get wallpaper_incoming_time => '11:40';

  @override
  String get wallpaper_outgoing_time => '11:41';

  @override
  String get wallpaper_system => 'You changed chat wallpaper';

  @override
  String get wallpaper_you => 'You';

  @override
  String get wallpaper_today => 'Today';

  @override
  String system_event_e2ee_enabled(Object epoch) {
    return 'End-to-end encryption enabled (key epoch: $epoch)';
  }

  @override
  String get system_event_e2ee_disabled => 'End-to-end encryption disabled';

  @override
  String get system_event_unknown => 'System event';

  @override
  String get system_event_group_created => 'Group created';

  @override
  String system_event_member_added(Object name) {
    return '$name was added';
  }

  @override
  String system_event_member_removed(Object name) {
    return '$name was removed';
  }

  @override
  String system_event_member_left(Object name) {
    return '$name left the group';
  }

  @override
  String system_event_name_changed(Object name) {
    return 'Name changed to \"$name\"';
  }

  @override
  String get image_editor_title => 'Editor';

  @override
  String get image_editor_undo => 'Undo';

  @override
  String get image_editor_clear => 'Clear';

  @override
  String get image_editor_pen => 'Brush';

  @override
  String get image_editor_text => 'Text';

  @override
  String get image_editor_crop => 'Crop';

  @override
  String get image_editor_rotate => 'Rotate';

  @override
  String get location_title => 'Send location';

  @override
  String get location_loading => 'Loading map…';

  @override
  String get location_send_button => 'Send';

  @override
  String get location_live_label => 'Live';

  @override
  String get location_error => 'Failed to load map';

  @override
  String get location_no_permission => 'No location access';

  @override
  String get group_member_admin => 'Admin';

  @override
  String get group_member_creator => 'Creator';

  @override
  String get group_member_member => 'Member';

  @override
  String get group_member_open_chat => 'Message';

  @override
  String get group_member_open_profile => 'Profile';

  @override
  String get group_member_remove => 'Remove';

  @override
  String get durak_lobby_title => 'Durak';

  @override
  String get durak_lobby_new_game => 'New game';

  @override
  String get durak_lobby_decline => 'Decline';

  @override
  String get durak_lobby_accept => 'Accept';

  @override
  String get durak_lobby_invite_sent => 'Invitation sent';

  @override
  String get voice_preview_cancel => 'Cancel';

  @override
  String get voice_preview_send => 'Send';

  @override
  String get voice_preview_recorded => 'Recorded';

  @override
  String get voice_preview_playing => 'Playing…';

  @override
  String get voice_preview_paused => 'Paused';

  @override
  String get group_avatar_camera => 'Camera';

  @override
  String get group_avatar_gallery => 'Gallery';

  @override
  String get group_avatar_upload_error => 'Upload error';

  @override
  String get avatar_picker_title => 'Avatar';

  @override
  String get avatar_picker_camera => 'Camera';

  @override
  String get avatar_picker_gallery => 'Gallery';

  @override
  String get avatar_picker_crop => 'Crop';

  @override
  String get avatar_picker_save => 'Save';

  @override
  String get avatar_picker_remove => 'Remove avatar';

  @override
  String get avatar_picker_error => 'Failed to load avatar';

  @override
  String get avatar_picker_crop_error => 'Crop error';

  @override
  String get webview_telegram_title => 'Sign in with Telegram';

  @override
  String get webview_telegram_loading => 'Loading…';

  @override
  String get webview_telegram_error => 'Failed to load page';

  @override
  String get webview_telegram_back => 'Back';

  @override
  String get webview_telegram_retry => 'Retry';

  @override
  String get webview_telegram_close => 'Close';

  @override
  String get webview_telegram_no_url => 'No authorization URL provided';

  @override
  String get webview_yandex_title => 'Sign in with Yandex';

  @override
  String get webview_yandex_loading => 'Loading…';

  @override
  String get webview_yandex_error => 'Failed to load page';

  @override
  String get webview_yandex_back => 'Back';

  @override
  String get webview_yandex_retry => 'Retry';

  @override
  String get webview_yandex_close => 'Close';

  @override
  String get webview_yandex_no_url => 'No authorization URL provided';

  @override
  String get google_profile_title => 'Complete your profile';

  @override
  String get google_profile_name => 'Name';

  @override
  String get google_profile_username => 'Username';

  @override
  String get google_profile_phone => 'Phone';

  @override
  String get google_profile_email => 'Email';

  @override
  String get google_profile_dob => 'Date of birth';

  @override
  String get google_profile_bio => 'About';

  @override
  String get google_profile_save => 'Save';

  @override
  String get google_profile_error => 'Failed to save profile';

  @override
  String get system_event_e2ee_epoch_rotated => 'Encryption key rotated';

  @override
  String system_event_e2ee_device_added(String actor, String device) {
    return '$actor added device \"$device\"';
  }

  @override
  String system_event_e2ee_device_revoked(String actor, String device) {
    return '$actor revoked device \"$device\"';
  }

  @override
  String system_event_e2ee_fingerprint_changed(String actor) {
    return 'Security fingerprint for $actor changed';
  }

  @override
  String get system_event_game_lobby_created => 'Game lobby created';

  @override
  String get system_event_game_started => 'Game started';

  @override
  String get system_event_call_missed => 'Missed call';

  @override
  String get system_event_call_cancelled => 'Call rejected';

  @override
  String get system_event_default_actor => 'User';

  @override
  String get system_event_default_device => 'device';

  @override
  String get image_editor_add_caption => 'Add caption...';

  @override
  String get image_editor_crop_failed => 'Failed to crop image';

  @override
  String get image_editor_draw_hint => 'Drawing mode: swipe across the image';

  @override
  String get image_editor_crop_title => 'Crop';

  @override
  String get location_preview_title => 'Location';

  @override
  String get location_preview_accuracy_unknown => 'Accuracy: —';

  @override
  String location_preview_accuracy_meters(String meters) {
    return 'Accuracy: ~$meters m';
  }

  @override
  String location_preview_accuracy_km(String km) {
    return 'Accuracy: ~$km km';
  }

  @override
  String get group_member_profile_default_name => 'Member';

  @override
  String get group_member_profile_dm => 'Send direct message';

  @override
  String get group_member_profile_dm_hint =>
      'Open a direct chat with this member';

  @override
  String group_member_profile_dm_failed(Object error) {
    return 'Failed to open direct chat: $error';
  }

  @override
  String get conversation_game_lobby_unavailable =>
      'Game unavailable or was deleted';

  @override
  String get conversation_game_lobby_back => 'Back';

  @override
  String get conversation_game_lobby_waiting => 'Waiting for opponent to join…';

  @override
  String get conversation_game_lobby_start_game => 'Start game';

  @override
  String get conversation_game_lobby_waiting_short => 'Waiting…';

  @override
  String get conversation_game_lobby_ready => 'Ready';

  @override
  String get voice_preview_trim_confirm_title =>
      'Keep only the selected fragment?';

  @override
  String get voice_preview_trim_confirm_body =>
      'Everything except the selected fragment will be deleted. Recording will continue immediately after pressing the button.';

  @override
  String get voice_preview_continue => 'Continue';

  @override
  String get voice_preview_continue_recording => 'Continue recording';

  @override
  String get group_avatar_change_short => 'Change';

  @override
  String get avatar_picker_cancel => 'Cancel';

  @override
  String get avatar_picker_choose => 'Choose avatar';

  @override
  String get avatar_picker_delete_photo => 'Delete photo';

  @override
  String get avatar_picker_loading => 'Loading…';

  @override
  String get avatar_picker_choose_avatar => 'Choose avatar';

  @override
  String get avatar_picker_change_avatar => 'Change avatar';

  @override
  String get avatar_picker_remove_tooltip => 'Remove';

  @override
  String get telegram_sign_in_title => 'Sign in via Telegram';

  @override
  String get telegram_sign_in_open_in_browser => 'Open in browser';

  @override
  String get telegram_sign_in_open_telegram_failed =>
      'Failed to open Telegram. Please install the Telegram app.';

  @override
  String get telegram_sign_in_page_load_error => 'Page load error';

  @override
  String get telegram_sign_in_login_error => 'Telegram sign-in error.';

  @override
  String get telegram_sign_in_firebase_not_ready => 'Firebase not ready.';

  @override
  String get telegram_sign_in_browser_failed => 'Failed to open browser.';

  @override
  String telegram_sign_in_login_failed(Object error) {
    return 'Sign-in failed: $error';
  }

  @override
  String get yandex_sign_in_title => 'Sign in via Yandex';

  @override
  String get yandex_sign_in_open_in_browser => 'Open in browser';

  @override
  String get yandex_sign_in_page_load_error => 'Page load error';

  @override
  String get yandex_sign_in_login_error => 'Yandex sign-in error.';

  @override
  String get yandex_sign_in_firebase_not_ready => 'Firebase not ready.';

  @override
  String get yandex_sign_in_browser_failed => 'Failed to open browser.';

  @override
  String yandex_sign_in_login_failed(Object error) {
    return 'Sign-in failed: $error';
  }

  @override
  String get google_complete_title => 'Complete registration';

  @override
  String get google_complete_subtitle =>
      'After signing in with Google, please fill in your profile as on the web version.';

  @override
  String get google_complete_name_label => 'Name';

  @override
  String get google_complete_username_label => 'Username (@username)';

  @override
  String get google_complete_phone_label => 'Phone (11 digits)';

  @override
  String get google_complete_email_label => 'Email';

  @override
  String get google_complete_email_hint => 'you@example.com';

  @override
  String get google_complete_dob_label =>
      'Date of birth (YYYY-MM-DD, optional)';

  @override
  String get google_complete_bio_label =>
      'About (up to 200 characters, optional)';

  @override
  String get google_complete_save => 'Save and continue';

  @override
  String get google_complete_back => 'Back to sign in';

  @override
  String get game_error_defense_not_beat =>
      'This card doesn\'t beat the attacking card';

  @override
  String get game_error_attacker_first => 'The attacker moves first';

  @override
  String get game_error_defender_no_attack =>
      'The defender can\'t attack right now';

  @override
  String get game_error_not_allowed_throwin => 'You can\'t throw in this round';

  @override
  String get game_error_throwin_not_turn => 'Another player is throwing in now';

  @override
  String get game_error_rank_not_allowed =>
      'You can only throw in a card of the same rank';

  @override
  String get game_error_cannot_throw_in => 'No more cards can be thrown in';

  @override
  String get game_error_card_not_in_hand =>
      'This card is no longer in your hand';

  @override
  String get game_error_already_defended => 'This card is already defended';

  @override
  String get game_error_bad_attack_index =>
      'Select an attacking card to defend against';

  @override
  String get game_error_only_defender => 'Another player is defending now';

  @override
  String get game_error_defender_taking =>
      'The defender is already taking cards';

  @override
  String get game_error_game_not_active => 'The game is no longer active';

  @override
  String get game_error_not_in_lobby => 'The lobby has already started';

  @override
  String get game_error_game_already_active => 'The game has already started';

  @override
  String get game_error_active_exists =>
      'There is already an active game in this chat';

  @override
  String get game_error_round_pending => 'Finish the contested move first';

  @override
  String get game_error_rematch_failed =>
      'Failed to prepare rematch. Try again';

  @override
  String get game_error_unauthenticated => 'You need to sign in';

  @override
  String get game_error_permission_denied =>
      'This action is not available to you';

  @override
  String get game_error_invalid_argument => 'Invalid move';

  @override
  String get game_error_precondition => 'Move is not available right now';

  @override
  String get game_error_server => 'Failed to make move. Try again';

  @override
  String get reply_sticker => 'Sticker';

  @override
  String get reply_gif => 'GIF';

  @override
  String get reply_video_circle => 'Video circle';

  @override
  String get reply_voice_message => 'Voice message';

  @override
  String get reply_video => 'Video';

  @override
  String get reply_photo => 'Photo';

  @override
  String get reply_file => 'File';

  @override
  String get reply_location => 'Location';

  @override
  String get reply_poll => 'Poll';

  @override
  String get reply_link => 'Link';

  @override
  String get reply_message => 'Message';

  @override
  String get reply_sender_you => 'You';

  @override
  String get reply_sender_member => 'Member';

  @override
  String get call_format_today => 'Today';

  @override
  String get call_format_yesterday => 'Yesterday';

  @override
  String get call_format_second_short => 's';

  @override
  String get call_format_minute_short => 'm';

  @override
  String get call_format_hour_short => 'h';

  @override
  String get call_format_day_short => 'd';

  @override
  String get call_month_january => 'January';

  @override
  String get call_month_february => 'February';

  @override
  String get call_month_march => 'March';

  @override
  String get call_month_april => 'April';

  @override
  String get call_month_may => 'May';

  @override
  String get call_month_june => 'June';

  @override
  String get call_month_july => 'July';

  @override
  String get call_month_august => 'August';

  @override
  String get call_month_september => 'September';

  @override
  String get call_month_october => 'October';

  @override
  String get call_month_november => 'November';

  @override
  String get call_month_december => 'December';

  @override
  String get push_incoming_call => 'Incoming call';

  @override
  String get push_incoming_video_call => 'Incoming video call';

  @override
  String get push_new_message => 'New message';

  @override
  String get push_channel_calls => 'Calls';

  @override
  String get push_channel_messages => 'Messages';

  @override
  String contacts_years_one(Object count) {
    return '$count year';
  }

  @override
  String contacts_years_few(Object count) {
    return '$count years';
  }

  @override
  String contacts_years_many(Object count) {
    return '$count years';
  }

  @override
  String contacts_years_other(Object count) {
    return '$count years';
  }

  @override
  String get durak_entry_single_game => 'Single game';

  @override
  String get durak_entry_finish_game_tooltip => 'Finish game';

  @override
  String get durak_entry_tournament_games_dialog_title =>
      'How many games in tournament?';

  @override
  String get durak_entry_cancel => 'Cancel';

  @override
  String get durak_entry_create => 'Create';

  @override
  String video_editor_load_failed(Object error) {
    return 'Failed to load video: $error';
  }

  @override
  String video_editor_process_failed(Object error) {
    return 'Failed to process video: $error';
  }

  @override
  String video_editor_duration(Object duration) {
    return 'Duration: $duration';
  }

  @override
  String get video_editor_brush => 'Brush';

  @override
  String get video_editor_caption_hint => 'Add caption...';

  @override
  String get video_effects_speed => 'Speed';

  @override
  String get video_filter_none => 'Original';

  @override
  String get video_filter_enhance => 'Enhance';

  @override
  String get share_location_title => 'Share location';

  @override
  String get share_location_how => 'Sharing method';

  @override
  String get share_location_cancel => 'Cancel';

  @override
  String get share_location_send => 'Send';

  @override
  String get photo_source_gallery => 'Gallery';

  @override
  String get photo_source_take_photo => 'Take photo';

  @override
  String get photo_source_record_video => 'Record video';

  @override
  String get video_attachment_media_kind => 'video';

  @override
  String get video_attachment_title => 'Video';

  @override
  String get video_attachment_playback_error =>
      'Unable to play video. Check the link and network connection.';

  @override
  String get location_card_broadcast_ended_mine =>
      'Location broadcast ended. The other person can no longer see your current location.';

  @override
  String get location_card_broadcast_ended_other =>
      'This contact\'s location broadcast has ended. Current position is unavailable.';

  @override
  String get location_card_title => 'Location';

  @override
  String location_card_accuracy(Object meters) {
    return '±$meters m';
  }

  @override
  String get link_webview_copy_tooltip => 'Copy link';

  @override
  String get link_webview_copied_snackbar => 'Link copied';

  @override
  String get link_webview_open_browser_tooltip => 'Open in browser';

  @override
  String get hold_record_pause => 'Paused';

  @override
  String get hold_record_release_cancel => 'Release to cancel';

  @override
  String get hold_record_slide_hints => 'Slide left — cancel · Up — pause';

  @override
  String get e2ee_badge_loading => 'Loading fingerprint…';

  @override
  String e2ee_badge_error(Object error) {
    return 'Failed to get fingerprint: $error';
  }

  @override
  String get e2ee_badge_label => 'E2EE Fingerprint';

  @override
  String e2ee_badge_label_with_user(Object user) {
    return 'E2EE Fingerprint • $user';
  }

  @override
  String e2ee_badge_devices(Object count) {
    return '$count dev.';
  }

  @override
  String get composer_link_cancel => 'Cancel';

  @override
  String message_search_results_count(Object count) {
    return 'SEARCH RESULTS: $count';
  }

  @override
  String get message_search_not_found => 'NOTHING FOUND';

  @override
  String get message_search_participant_fallback => 'Participant';

  @override
  String get wallpaper_purple => 'Purple';

  @override
  String get wallpaper_pink => 'Pink';

  @override
  String get wallpaper_blue => 'Blue';

  @override
  String get wallpaper_green => 'Green';

  @override
  String get wallpaper_sunset => 'Sunset';

  @override
  String get wallpaper_tender => 'Tender';

  @override
  String get wallpaper_lime => 'Lime';

  @override
  String get wallpaper_graphite => 'Graphite';

  @override
  String get avatar_crop_title => 'Adjust avatar';

  @override
  String get avatar_crop_hint =>
      'Drag and zoom — the circle will appear in lists and messages; the full frame stays for the profile.';

  @override
  String get avatar_crop_cancel => 'Cancel';

  @override
  String get avatar_crop_reset => 'Reset';

  @override
  String get avatar_crop_save => 'Save';

  @override
  String get meeting_entry_connecting => 'Connecting to meeting…';

  @override
  String meeting_entry_auth_failed(Object error) {
    return 'Failed to sign in: $error';
  }

  @override
  String get meeting_entry_participant_fallback => 'Participant';

  @override
  String get meeting_entry_back => 'Back';

  @override
  String get meeting_chat_copy => 'Copy';

  @override
  String get meeting_chat_edit => 'Edit';

  @override
  String get meeting_chat_delete => 'Delete';

  @override
  String get meeting_chat_deleted => 'Message deleted';

  @override
  String get meeting_chat_edited_mark => '• edited';

  @override
  String get meeting_chat_reply => 'Reply';

  @override
  String get meeting_chat_react => 'React';

  @override
  String get meeting_chat_copied => 'Copied';

  @override
  String get meeting_chat_editing => 'Editing';

  @override
  String meeting_chat_reply_to(Object name) {
    return 'Reply to $name';
  }

  @override
  String get meeting_chat_attachment_placeholder => 'Attachment';

  @override
  String meeting_timer_remaining(Object time) {
    return 'Left $time';
  }

  @override
  String meeting_timer_elapsed(Object time) {
    return '$time';
  }

  @override
  String get meeting_back_to_chats => 'Back to chats';

  @override
  String get meeting_open_chats => 'Open chats';

  @override
  String get meeting_in_call_chat => 'In-call chat';

  @override
  String get meeting_lobby_open_settings => 'Open settings';

  @override
  String get meeting_lobby_retry => 'Try again';

  @override
  String get meeting_minimized_resume => 'Tap to return to call';

  @override
  String get e2ee_decrypt_image_failed => 'Failed to decrypt image';

  @override
  String get e2ee_decrypt_video_failed => 'Failed to decrypt video';

  @override
  String get e2ee_decrypt_audio_failed => 'Failed to decrypt audio';

  @override
  String get e2ee_decrypt_attachment_failed => 'Failed to decrypt attachment';

  @override
  String get search_preview_attachment => 'Attachment';

  @override
  String get search_preview_location => 'Location';

  @override
  String get search_preview_message => 'Message';

  @override
  String get outbox_attachment_singular => 'Attachment';

  @override
  String outbox_attachments_count(int count) {
    return 'Attachments ($count)';
  }

  @override
  String get outbox_chat_unavailable => 'Chat service unavailable';

  @override
  String outbox_encryption_error(String code) {
    return 'Encryption: $code';
  }

  @override
  String get nav_chats => 'Chats';

  @override
  String get nav_contacts => 'Contacts';

  @override
  String get nav_meetings => 'Meetings';

  @override
  String get nav_calls => 'Calls';

  @override
  String get e2ee_media_decrypt_failed_image => 'Failed to decrypt image';

  @override
  String get e2ee_media_decrypt_failed_video => 'Failed to decrypt video';

  @override
  String get e2ee_media_decrypt_failed_audio => 'Failed to decrypt audio';

  @override
  String get e2ee_media_decrypt_failed_attachment =>
      'Failed to decrypt attachment';

  @override
  String get chat_search_snippet_attachment => 'Attachment';

  @override
  String get chat_search_snippet_location => 'Location';

  @override
  String get chat_search_snippet_message => 'Message';

  @override
  String get bottom_nav_chats => 'Chats';

  @override
  String get bottom_nav_contacts => 'Contacts';

  @override
  String get bottom_nav_meetings => 'Meetings';

  @override
  String get bottom_nav_calls => 'Calls';

  @override
  String get chat_list_swipe_folders => 'FOLDERS';

  @override
  String get chat_list_swipe_clear => 'CLEAR';

  @override
  String get chat_list_swipe_delete => 'DELETE';

  @override
  String get composer_editing_title => 'EDITING MESSAGE';

  @override
  String get composer_editing_cancel_tooltip => 'Cancel editing';

  @override
  String get composer_formatting_title => 'FORMATTING';

  @override
  String get composer_link_preview_loading => 'Loading preview…';

  @override
  String get composer_link_preview_hide_tooltip => 'Hide preview';

  @override
  String get chat_invite_button => 'Invite';

  @override
  String get forward_preview_unknown_sender => 'Unknown';

  @override
  String get forward_preview_attachment => 'Attachment';

  @override
  String get forward_preview_message => 'Message';

  @override
  String get chat_mention_no_matches => 'No matches';

  @override
  String get live_location_sharing => 'You are sharing your location';

  @override
  String get live_location_stop => 'Stop';

  @override
  String get chat_message_deleted => 'Message deleted';

  @override
  String get profile_qr_share => 'Share';

  @override
  String get shared_location_open_browser_tooltip => 'Open in browser';

  @override
  String get reply_preview_message_fallback => 'Message';

  @override
  String get video_circle_media_kind => 'video';

  @override
  String reactions_rated_count(int count) {
    return 'Reacted: $count';
  }

  @override
  String reactions_today_time(String time) {
    return 'Today, $time';
  }

  @override
  String get durak_create_timer_subtitle => 'Default 15 seconds';

  @override
  String get dm_game_banner_active => 'Durak game in progress';

  @override
  String get dm_game_banner_created => 'Durak game created';

  @override
  String get chat_folder_favorites => 'Favorites';

  @override
  String get chat_folder_new => 'New';

  @override
  String get contact_profile_user_fallback => 'User';

  @override
  String contact_profile_error(String error) {
    return 'Error: $error';
  }

  @override
  String get conversation_threads_loading_title => 'Threads';

  @override
  String get theme_label_light => 'Light';

  @override
  String get theme_label_dark => 'Dark';

  @override
  String get theme_label_auto => 'Auto';

  @override
  String get chat_draft_reply_fallback => 'Reply';

  @override
  String get mention_default_label => 'Member';

  @override
  String get contacts_fallback_name => 'Contact';

  @override
  String get sticker_pack_default_name => 'My pack';

  @override
  String get profile_error_phone_taken =>
      'This phone number is already registered. Please use a different number.';

  @override
  String get profile_error_email_taken =>
      'This email is already taken. Please use a different address.';

  @override
  String get profile_error_username_taken =>
      'This username is already taken. Please choose another.';

  @override
  String get e2ee_banner_default_context => 'Message';

  @override
  String e2ee_banner_encrypted_chat_web_only(String prefix) {
    return '$prefix to an encrypted chat can only be sent from the web client for now.';
  }

  @override
  String get chat_attachment_decrypt_error => 'Failed to decrypt attachment';

  @override
  String get mention_fallback_label => 'member';

  @override
  String get mention_fallback_label_capitalized => 'Member';

  @override
  String get meeting_speaking_label => 'Speaking';

  @override
  String meeting_local_you_suffix(String name) {
    return '$name (You)';
  }

  @override
  String get video_crop_title => 'Crop';

  @override
  String video_crop_load_error(String error) {
    return 'Failed to load video: $error';
  }

  @override
  String get gif_section_recent => 'RECENT';

  @override
  String get gif_section_trending => 'TRENDING';

  @override
  String get auth_create_account_title => 'Create Account';

  @override
  String yandex_sign_in_yandex_error(String error) {
    return 'Yandex: $error';
  }

  @override
  String get call_status_missed => 'Missed';

  @override
  String get call_status_cancelled => 'Cancelled';

  @override
  String get call_status_ended => 'Ended';

  @override
  String get presence_offline => 'Offline';

  @override
  String get presence_online => 'Online';

  @override
  String get dm_title_fallback => 'Chat';

  @override
  String get dm_title_partner_fallback => 'Contact';

  @override
  String get group_title_fallback => 'Group chat';

  @override
  String get block_call_viewer_blocked =>
      'You blocked this user. Call unavailable — unblock in Profile → Blocked.';

  @override
  String get block_call_partner_blocked =>
      'This user restricted communication with you. Call unavailable.';

  @override
  String get block_call_unavailable => 'Call unavailable.';

  @override
  String get block_composer_viewer_blocked =>
      'You blocked this user. Sending unavailable — unblock in Profile → Blocked.';

  @override
  String get block_composer_partner_blocked =>
      'This user restricted communication with you. Sending unavailable.';

  @override
  String get forward_group_fallback => 'Group';

  @override
  String get forward_unknown_user => 'Unknown';

  @override
  String get live_location_once => 'One-time (this message only)';

  @override
  String get live_location_5min => '5 minutes';

  @override
  String get live_location_15min => '15 minutes';

  @override
  String get live_location_30min => '30 minutes';

  @override
  String get live_location_1hour => '1 hour';

  @override
  String get live_location_2hours => '2 hours';

  @override
  String get live_location_6hours => '6 hours';

  @override
  String get live_location_1day => '1 day';

  @override
  String get live_location_forever => 'Forever (until I turn it off)';

  @override
  String get e2ee_send_too_many_files =>
      'Too many attachments for encrypted send: maximum 5 files per message.';

  @override
  String get e2ee_send_too_large =>
      'Total attachment size too large: maximum 96 MB for one encrypted message.';

  @override
  String get presence_last_seen_prefix => 'Last seen ';

  @override
  String get presence_less_than_minute_ago => 'less than a minute ago';

  @override
  String get presence_yesterday => 'yesterday';

  @override
  String get dm_fallback_title => 'Chat';

  @override
  String get dm_fallback_partner => 'Contact';

  @override
  String get group_fallback_title => 'Group chat';

  @override
  String get block_send_viewer_blocked =>
      'You blocked this user. Sending unavailable — unblock in Profile → Blocked.';

  @override
  String get block_send_partner_blocked =>
      'This user restricted communication with you. Sending unavailable.';

  @override
  String get mention_fallback_name => 'Member';

  @override
  String get profile_conflict_phone =>
      'This phone number is already registered. Please use a different number.';

  @override
  String get profile_conflict_email =>
      'This email is already taken. Please use a different address.';

  @override
  String get profile_conflict_username =>
      'This username is already taken. Please choose a different one.';

  @override
  String get mention_fallback_participant => 'Participant';

  @override
  String get sticker_gif_recent => 'RECENT';

  @override
  String get meeting_screen_sharing => 'Screen';

  @override
  String get meeting_speaking => 'Speaking';

  @override
  String auth_sign_in_failed(Object error) {
    return 'Sign-in failed: $error';
  }

  @override
  String yandex_error_prefix(Object error) {
    return 'Yandex: $error';
  }

  @override
  String auth_error_prefix(Object error) {
    return 'Auth error: $error';
  }

  @override
  String presence_minutes_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: 'a minute ago',
    );
    return '$_temp0';
  }

  @override
  String presence_hours_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: 'an hour ago',
    );
    return '$_temp0';
  }

  @override
  String presence_days_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: 'a day ago',
    );
    return '$_temp0';
  }

  @override
  String presence_months_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months ago',
      one: 'a month ago',
    );
    return '$_temp0';
  }

  @override
  String presence_years_months_ago(int years, int months) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years years',
      one: '1 year',
    );
    String _temp1 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months months ago',
      one: '1 month ago',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String presence_years_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years ago',
      one: 'a year ago',
    );
    return '$_temp0';
  }

  @override
  String get wallpaper_gradient_purple => 'Purple';

  @override
  String get wallpaper_gradient_pink => 'Pink';

  @override
  String get wallpaper_gradient_blue => 'Blue';

  @override
  String get wallpaper_gradient_green => 'Green';

  @override
  String get wallpaper_gradient_sunset => 'Sunset';

  @override
  String get wallpaper_gradient_gentle => 'Gentle';

  @override
  String get wallpaper_gradient_lime => 'Lime';

  @override
  String get wallpaper_gradient_graphite => 'Graphite';

  @override
  String get sticker_tab_recent => 'RECENT';

  @override
  String get block_call_you_blocked =>
      'You blocked this user. Call unavailable — unblock in Profile → Blocked.';

  @override
  String get block_call_they_blocked =>
      'This user restricted communication with you. Call unavailable.';

  @override
  String get block_call_generic => 'Call unavailable.';

  @override
  String get block_send_you_blocked =>
      'You blocked this user. Sending unavailable — unblock in Profile → Blocked.';

  @override
  String get block_send_they_blocked =>
      'This user restricted communication with you. Sending unavailable.';

  @override
  String get forward_unknown_fallback => 'Unknown';

  @override
  String get dm_title_chat => 'Chat';

  @override
  String get dm_title_partner => 'Partner';

  @override
  String get dm_title_group => 'Group chat';

  @override
  String get e2ee_too_many_attachments =>
      'Too many attachments for encrypted sending: maximum 5 files per message.';

  @override
  String get e2ee_total_size_exceeded =>
      'Total attachment size too large: maximum 96 MB per encrypted message.';

  @override
  String composer_limit_too_many_files(int current, int max, int diff) {
    return 'Too many attachments: $current/$max. Remove $diff to send.';
  }

  @override
  String composer_limit_total_size_exceeded(String currentMb, String maxMb) {
    return 'Attachments too large: $currentMb MB / $maxMb MB. Remove some to send.';
  }

  @override
  String get composer_limit_blocking_send => 'Attachment limit exceeded';

  @override
  String yandex_sign_in_error_prefix(String error) {
    return 'Yandex: $error';
  }

  @override
  String get meeting_participant_screen => 'Screen';

  @override
  String get meeting_participant_speaking => 'Speaking';

  @override
  String get nav_error_title => 'Navigation error';

  @override
  String get nav_error_invalid_secret_compose =>
      'Invalid secret compose navigation';

  @override
  String get sign_in_title => 'Sign in';

  @override
  String get sign_in_firebase_ready => 'Firebase initialized. You can sign in.';

  @override
  String get sign_in_firebase_not_ready =>
      'Firebase is not ready. Check logs and firebase_options.dart.';

  @override
  String get sign_in_continue => 'Continue';

  @override
  String get sign_in_anonymously => 'Sign in anonymously';

  @override
  String sign_in_auth_error(String error) {
    return 'Auth error: $error';
  }

  @override
  String generic_error(String error) {
    return 'Error: $error';
  }

  @override
  String get storage_label_video => 'Video';

  @override
  String get storage_label_photo => 'Photo';

  @override
  String get storage_label_audio => 'Audio';

  @override
  String get storage_label_files => 'Files';

  @override
  String get storage_label_other => 'Other';

  @override
  String get storage_label_recent_stickers => 'Recent stickers';

  @override
  String get storage_label_giphy_search => 'GIPHY · search cache';

  @override
  String get storage_label_giphy_recent => 'GIPHY · recent GIFs';

  @override
  String get storage_chat_unattributed => 'Not attributed to a chat';

  @override
  String storage_label_draft(String key) {
    return 'Draft · $key';
  }

  @override
  String get storage_label_offline_snapshot => 'Offline chat list snapshot';

  @override
  String storage_label_profile_cache(String name) {
    return 'Profile cache · $name';
  }

  @override
  String get call_mini_end => 'End call';

  @override
  String get animation_quality_lite => 'Lite';

  @override
  String get animation_quality_balanced => 'Balanced';

  @override
  String get animation_quality_cinematic => 'Cinematic';

  @override
  String get crop_aspect_original => 'Original';

  @override
  String get crop_aspect_square => 'Square';

  @override
  String get push_notification_title => 'Allow notifications';

  @override
  String get push_notification_rationale =>
      'The app needs notifications for incoming calls.';

  @override
  String get push_notification_required =>
      'Enable notifications to display incoming calls.';

  @override
  String get push_notification_grant => 'Allow';

  @override
  String get push_call_accept => 'Accept';

  @override
  String get push_call_decline => 'Decline';

  @override
  String get push_channel_incoming_calls => 'Incoming calls';

  @override
  String get push_channel_missed_calls => 'Missed calls';

  @override
  String get push_channel_messages_desc => 'New messages in chats';

  @override
  String get push_channel_silent => 'Silent messages';

  @override
  String get push_channel_silent_desc => 'Push without sound';

  @override
  String get push_caller_unknown => 'Someone';

  @override
  String get outbox_attachment_single => 'Attachment';

  @override
  String outbox_attachment_count(int count) {
    return 'Attachments ($count)';
  }

  @override
  String get bottom_nav_label_chats => 'Chats';

  @override
  String get bottom_nav_label_contacts => 'Contacts';

  @override
  String get bottom_nav_label_conferences => 'Conferences';

  @override
  String get bottom_nav_label_calls => 'Calls';

  @override
  String get welcomeBubbleTitle => 'Welcome to LighChat';

  @override
  String get welcomeBubbleSubtitle => 'The lighthouse is lit';

  @override
  String get welcomeSkip => 'Skip';

  @override
  String get welcomeReplayDebugTile => 'Replay welcome animation (debug)';

  @override
  String get sticker_scope_library => 'Library';

  @override
  String get sticker_library_search_hint => 'Search stickers...';

  @override
  String get account_menu_energy_saving => 'Power saving';

  @override
  String get energy_saving_title => 'Power saving';

  @override
  String get energy_saving_section_mode => 'Power saving mode';

  @override
  String get energy_saving_section_resource_heavy => 'Resource-heavy processes';

  @override
  String get energy_saving_threshold_off => 'Off';

  @override
  String get energy_saving_threshold_always => 'On';

  @override
  String get energy_saving_threshold_off_full => 'Never';

  @override
  String get energy_saving_threshold_always_full => 'Always';

  @override
  String energy_saving_threshold_at(int percent) {
    return 'When battery is below $percent%';
  }

  @override
  String get energy_saving_hint_off =>
      'Resource-heavy effects are never auto-disabled.';

  @override
  String get energy_saving_hint_always =>
      'Resource-heavy effects are always disabled regardless of battery level.';

  @override
  String energy_saving_hint_threshold(int percent) {
    return 'Automatically disable all resource-heavy processes when battery drops below $percent%.';
  }

  @override
  String energy_saving_current_battery(int percent) {
    return 'Current battery: $percent%';
  }

  @override
  String get energy_saving_active_now => 'mode is active';

  @override
  String get energy_saving_active_threshold =>
      'Battery has reached the threshold — every effect below is temporarily disabled.';

  @override
  String get energy_saving_active_system =>
      'System power saving is on — every effect below is temporarily disabled.';

  @override
  String get energy_saving_autoplay_video_title => 'Autoplay videos';

  @override
  String get energy_saving_autoplay_video_subtitle =>
      'Autoplay and loop video messages and videos in chats.';

  @override
  String get energy_saving_autoplay_gif_title => 'Autoplay GIFs';

  @override
  String get energy_saving_autoplay_gif_subtitle =>
      'Autoplay and loop GIFs in chats and on the keyboard.';

  @override
  String get energy_saving_animated_stickers_title => 'Animated stickers';

  @override
  String get energy_saving_animated_stickers_subtitle =>
      'Looped sticker animations and full-screen Premium sticker effects.';

  @override
  String get energy_saving_animated_emoji_title => 'Animated emoji';

  @override
  String get energy_saving_animated_emoji_subtitle =>
      'Looped emoji animation in messages, reactions and statuses.';

  @override
  String get energy_saving_interface_animations_title => 'Interface animations';

  @override
  String get energy_saving_interface_animations_subtitle =>
      'Effects and animations that make LighChat smoother and more expressive.';

  @override
  String get energy_saving_media_preload_title => 'Media preload';

  @override
  String get energy_saving_media_preload_subtitle =>
      'Start downloading media files when opening the chat list.';

  @override
  String get energy_saving_background_update_title => 'Background update';

  @override
  String get energy_saving_background_update_subtitle =>
      'Quick chat updates when switching between apps.';

  @override
  String get legal_index_title => 'Legal documents';

  @override
  String get legal_index_subtitle =>
      'Privacy policy, terms of service and other legal documents that govern the use of LighChat.';

  @override
  String get legal_settings_section_title => 'Legal information';

  @override
  String get legal_settings_section_subtitle =>
      'Privacy policy, terms of service, EULA and more.';

  @override
  String get legal_not_found => 'Document not found';

  @override
  String get legal_title_privacy_policy => 'Privacy Policy';

  @override
  String get legal_title_terms_of_service => 'Terms of Service';

  @override
  String get legal_title_cookie_policy => 'Cookie Policy';

  @override
  String get legal_title_eula => 'End-User License Agreement';

  @override
  String get legal_title_dpa => 'Data Processing Agreement';

  @override
  String get legal_title_children => 'Children Policy';

  @override
  String get legal_title_moderation => 'Content Moderation Policy';

  @override
  String get legal_title_aup => 'Acceptable Use Policy';

  @override
  String get chat_list_item_sender_you => 'You';

  @override
  String get chat_preview_message => 'Message';

  @override
  String get chat_preview_sticker => 'Sticker';

  @override
  String get chat_preview_attachment => 'Attachment';

  @override
  String get contacts_disclosure_title => 'Find friends in LighChat';

  @override
  String get contacts_disclosure_body =>
      'LighChat reads phone numbers and email addresses from your address book, hashes them, and checks them against our server to show which of your contacts already use the app. Your contacts are never stored on our servers.';

  @override
  String get contacts_disclosure_allow => 'Allow';

  @override
  String get contacts_disclosure_deny => 'Not now';

  @override
  String get report_title => 'Report';

  @override
  String get report_subtitle_message => 'Report message';

  @override
  String get report_subtitle_user => 'Report user';

  @override
  String get report_reason_spam => 'Spam';

  @override
  String get report_reason_offensive => 'Offensive content';

  @override
  String get report_reason_violence => 'Violence or threats';

  @override
  String get report_reason_fraud => 'Fraud or scam';

  @override
  String get report_reason_other => 'Other';

  @override
  String get report_comment_hint => 'Additional details (optional)';

  @override
  String get report_submit => 'Submit';

  @override
  String get report_success => 'Report submitted. Thank you!';

  @override
  String get report_error => 'Failed to submit report';

  @override
  String get message_menu_action_report => 'Report';

  @override
  String get partner_profile_menu_report => 'Report user';
}
