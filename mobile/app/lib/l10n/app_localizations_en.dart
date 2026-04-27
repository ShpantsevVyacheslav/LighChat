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
  String get account_menu_language => 'Language';

  @override
  String get account_menu_theme => 'Theme';

  @override
  String get account_menu_sign_out => 'Sign out';

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
  String get common_nothing_found => 'Nothing found';

  @override
  String get common_retry => 'Retry';

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
  String get chat_list_snackbar_history_cleared => 'History cleared.';

  @override
  String get chat_list_snackbar_marked_read => 'Marked as read.';

  @override
  String chat_list_error_generic(Object error) {
    return 'Error: $error';
  }

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
  String get chat_messages_title => 'Messages';

  @override
  String get chat_call_decline => 'Decline';

  @override
  String get chat_call_open => 'Open';

  @override
  String get chat_call_accept => 'Accept';

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
}
