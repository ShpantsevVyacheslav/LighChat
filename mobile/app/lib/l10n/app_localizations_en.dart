// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
  String get account_menu_theme => 'Theme';

  @override
  String get account_menu_sign_out => 'Sign out';

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
  String get common_delete => 'Delete';

  @override
  String get common_choose => 'Choose';

  @override
  String get common_save => 'Save';

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
}
