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
  String get account_menu_chat_settings => 'Chat settings';

  @override
  String get account_menu_notifications => 'Notifications';

  @override
  String get account_menu_privacy => 'Privacy';

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
  String get privacy_title => 'Privacy';

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
  String get chat_meetings_waiting_room_toggle => 'Add waiting room';

  @override
  String get chat_meetings_waiting_room_toggle_subtitle =>
      'Only the host can admit participants and block access.';

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
  String get devices_title => 'My devices';

  @override
  String get devices_subtitle =>
      'Devices where your encryption public key is published. Revoking creates a new key epoch for all encrypted chats — the revoked device won’t be able to read new messages.';

  @override
  String get devices_empty => 'No devices yet.';

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
}
