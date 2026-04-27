import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @settings_language_title.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get settings_language_title;

  /// No description provided for @settings_language_system.
  ///
  /// In ru, this message translates to:
  /// **'Системный'**
  String get settings_language_system;

  /// No description provided for @settings_language_ru.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get settings_language_ru;

  /// No description provided for @settings_language_en.
  ///
  /// In ru, this message translates to:
  /// **'English'**
  String get settings_language_en;

  /// No description provided for @settings_language_hint_system.
  ///
  /// In ru, this message translates to:
  /// **'При выборе «Системный» язык соответствует настройкам устройства.'**
  String get settings_language_hint_system;

  /// No description provided for @account_menu_profile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get account_menu_profile;

  /// No description provided for @account_menu_chat_settings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки чатов'**
  String get account_menu_chat_settings;

  /// No description provided for @account_menu_notifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get account_menu_notifications;

  /// No description provided for @account_menu_privacy.
  ///
  /// In ru, this message translates to:
  /// **'Конфиденциальность'**
  String get account_menu_privacy;

  /// No description provided for @account_menu_language.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get account_menu_language;

  /// No description provided for @account_menu_theme.
  ///
  /// In ru, this message translates to:
  /// **'Тема'**
  String get account_menu_theme;

  /// No description provided for @account_menu_sign_out.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get account_menu_sign_out;

  /// No description provided for @common_soon.
  ///
  /// In ru, this message translates to:
  /// **'Скоро'**
  String get common_soon;

  /// No description provided for @common_theme_prefix.
  ///
  /// In ru, this message translates to:
  /// **'Тема: {label}'**
  String common_theme_prefix(Object label);

  /// No description provided for @common_error_cannot_save_theme.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить тему: {error}'**
  String common_error_cannot_save_theme(Object error);

  /// No description provided for @common_error_cannot_sign_out.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выйти: {error}'**
  String common_error_cannot_sign_out(Object error);

  /// No description provided for @account_error_profile.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка профиля: {error}'**
  String account_error_profile(Object error);

  /// No description provided for @notifications_title.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get notifications_title;

  /// No description provided for @notifications_section_main.
  ///
  /// In ru, this message translates to:
  /// **'Основные'**
  String get notifications_section_main;

  /// No description provided for @notifications_mute_all_title.
  ///
  /// In ru, this message translates to:
  /// **'Отключить все'**
  String get notifications_mute_all_title;

  /// No description provided for @notifications_mute_all_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Полностью выключить уведомления.'**
  String get notifications_mute_all_subtitle;

  /// No description provided for @notifications_sound_title.
  ///
  /// In ru, this message translates to:
  /// **'Звук'**
  String get notifications_sound_title;

  /// No description provided for @notifications_sound_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Воспроизводить звук при новом сообщении.'**
  String get notifications_sound_subtitle;

  /// No description provided for @notifications_preview_title.
  ///
  /// In ru, this message translates to:
  /// **'Предпросмотр'**
  String get notifications_preview_title;

  /// No description provided for @notifications_preview_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Показывать текст сообщения в уведомлении.'**
  String get notifications_preview_subtitle;

  /// No description provided for @notifications_section_quiet_hours.
  ///
  /// In ru, this message translates to:
  /// **'Тихие часы'**
  String get notifications_section_quiet_hours;

  /// No description provided for @notifications_quiet_hours_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления не будут беспокоить в указанный период.'**
  String get notifications_quiet_hours_subtitle;

  /// No description provided for @notifications_quiet_hours_enable_title.
  ///
  /// In ru, this message translates to:
  /// **'Включить тихие часы'**
  String get notifications_quiet_hours_enable_title;

  /// No description provided for @notifications_reset_button.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить настройки'**
  String get notifications_reset_button;

  /// No description provided for @notifications_error_cannot_save.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить настройки: {error}'**
  String notifications_error_cannot_save(Object error);

  /// No description provided for @notifications_error_load.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки уведомлений: {error}'**
  String notifications_error_load(Object error);

  /// No description provided for @privacy_title.
  ///
  /// In ru, this message translates to:
  /// **'Конфиденциальность'**
  String get privacy_title;

  /// No description provided for @privacy_error_cannot_save.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить настройки: {error}'**
  String privacy_error_cannot_save(Object error);

  /// No description provided for @privacy_error_load.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки конфиденциальности: {error}'**
  String privacy_error_load(Object error);

  /// No description provided for @privacy_e2ee_section.
  ///
  /// In ru, this message translates to:
  /// **'Сквозное шифрование'**
  String get privacy_e2ee_section;

  /// No description provided for @privacy_e2ee_enable_for_all_chats.
  ///
  /// In ru, this message translates to:
  /// **'Включить шифрование (E2E) для всех чатов'**
  String get privacy_e2ee_enable_for_all_chats;

  /// No description provided for @privacy_e2ee_what_encrypt.
  ///
  /// In ru, this message translates to:
  /// **'Что шифруем в E2EE чатах'**
  String get privacy_e2ee_what_encrypt;

  /// No description provided for @privacy_e2ee_text.
  ///
  /// In ru, this message translates to:
  /// **'Текст сообщений'**
  String get privacy_e2ee_text;

  /// No description provided for @privacy_e2ee_media.
  ///
  /// In ru, this message translates to:
  /// **'Вложения (медиа/файлы)'**
  String get privacy_e2ee_media;

  /// No description provided for @privacy_my_devices_title.
  ///
  /// In ru, this message translates to:
  /// **'Мои устройства'**
  String get privacy_my_devices_title;

  /// No description provided for @privacy_my_devices_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Список устройств с опубликованным ключом. Переименовать или отозвать.'**
  String get privacy_my_devices_subtitle;

  /// No description provided for @privacy_key_backup_title.
  ///
  /// In ru, this message translates to:
  /// **'Резервное копирование и передача ключа'**
  String get privacy_key_backup_title;

  /// No description provided for @privacy_key_backup_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Создать backup паролем или передать ключ другому устройству по QR.'**
  String get privacy_key_backup_subtitle;

  /// No description provided for @privacy_visibility_section.
  ///
  /// In ru, this message translates to:
  /// **'Видимость'**
  String get privacy_visibility_section;

  /// No description provided for @privacy_online_title.
  ///
  /// In ru, this message translates to:
  /// **'Статус онлайн'**
  String get privacy_online_title;

  /// No description provided for @privacy_online_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Другие пользователи видят, что вы в сети.'**
  String get privacy_online_subtitle;

  /// No description provided for @privacy_last_seen_title.
  ///
  /// In ru, this message translates to:
  /// **'Последний визит'**
  String get privacy_last_seen_title;

  /// No description provided for @privacy_last_seen_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Показывать время последнего посещения.'**
  String get privacy_last_seen_subtitle;

  /// No description provided for @privacy_read_receipts_title.
  ///
  /// In ru, this message translates to:
  /// **'Индикатор прочтения'**
  String get privacy_read_receipts_title;

  /// No description provided for @privacy_read_receipts_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Показывать отправителям, что вы прочитали сообщение.'**
  String get privacy_read_receipts_subtitle;

  /// No description provided for @privacy_group_invites_section.
  ///
  /// In ru, this message translates to:
  /// **'Приглашения в группы'**
  String get privacy_group_invites_section;

  /// No description provided for @privacy_group_invites_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Кто может добавлять вас в групповой чат.'**
  String get privacy_group_invites_subtitle;

  /// No description provided for @privacy_group_invites_everyone.
  ///
  /// In ru, this message translates to:
  /// **'Все пользователи'**
  String get privacy_group_invites_everyone;

  /// No description provided for @privacy_group_invites_contacts.
  ///
  /// In ru, this message translates to:
  /// **'Только контакты'**
  String get privacy_group_invites_contacts;

  /// No description provided for @privacy_group_invites_nobody.
  ///
  /// In ru, this message translates to:
  /// **'Никто'**
  String get privacy_group_invites_nobody;

  /// No description provided for @privacy_global_search_section.
  ///
  /// In ru, this message translates to:
  /// **'Поиск собеседников'**
  String get privacy_global_search_section;

  /// No description provided for @privacy_global_search_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Кто может найти вас по имени среди всех пользователей приложения.'**
  String get privacy_global_search_subtitle;

  /// No description provided for @privacy_global_search_title.
  ///
  /// In ru, this message translates to:
  /// **'Глобальный поиск'**
  String get privacy_global_search_title;

  /// No description provided for @privacy_global_search_hint.
  ///
  /// In ru, this message translates to:
  /// **'Если выключено, вы не отображаетесь в списке «Все пользователи» при создании чата. В блоке «Контакты» вы по-прежнему видны тем, кто добавил вас в контакты.'**
  String get privacy_global_search_hint;

  /// No description provided for @privacy_profile_for_others_section.
  ///
  /// In ru, this message translates to:
  /// **'Профиль для других'**
  String get privacy_profile_for_others_section;

  /// No description provided for @privacy_profile_for_others_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Что показывать в карточке контакта и в профиле из беседы.'**
  String get privacy_profile_for_others_subtitle;

  /// No description provided for @privacy_email_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Адрес почты в профиле собеседника.'**
  String get privacy_email_subtitle;

  /// No description provided for @privacy_phone_title.
  ///
  /// In ru, this message translates to:
  /// **'Номер телефона'**
  String get privacy_phone_title;

  /// No description provided for @privacy_phone_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'В профиле и в списке контактов у других.'**
  String get privacy_phone_subtitle;

  /// No description provided for @privacy_birthdate_title.
  ///
  /// In ru, this message translates to:
  /// **'Дата рождения'**
  String get privacy_birthdate_title;

  /// No description provided for @privacy_birthdate_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Поле «День рождения» в профиле.'**
  String get privacy_birthdate_subtitle;

  /// No description provided for @privacy_about_title.
  ///
  /// In ru, this message translates to:
  /// **'О себе'**
  String get privacy_about_title;

  /// No description provided for @privacy_about_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Текст биографии в профиле.'**
  String get privacy_about_subtitle;

  /// No description provided for @privacy_reset_button.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить настройки'**
  String get privacy_reset_button;

  /// No description provided for @common_cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get common_cancel;

  /// No description provided for @common_delete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get common_delete;

  /// No description provided for @common_choose.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать'**
  String get common_choose;

  /// No description provided for @common_nothing_found.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено'**
  String get common_nothing_found;

  /// No description provided for @common_retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get common_retry;

  /// No description provided for @settings_chats_title.
  ///
  /// In ru, this message translates to:
  /// **'Настройки чатов'**
  String get settings_chats_title;

  /// No description provided for @settings_chats_preview.
  ///
  /// In ru, this message translates to:
  /// **'Предпросмотр'**
  String get settings_chats_preview;

  /// No description provided for @settings_chats_outgoing.
  ///
  /// In ru, this message translates to:
  /// **'Исходящие сообщения'**
  String get settings_chats_outgoing;

  /// No description provided for @settings_chats_incoming.
  ///
  /// In ru, this message translates to:
  /// **'Входящие сообщения'**
  String get settings_chats_incoming;

  /// No description provided for @settings_chats_font_size.
  ///
  /// In ru, this message translates to:
  /// **'Размер шрифта'**
  String get settings_chats_font_size;

  /// No description provided for @settings_chats_font_small.
  ///
  /// In ru, this message translates to:
  /// **'Мелкий'**
  String get settings_chats_font_small;

  /// No description provided for @settings_chats_font_medium.
  ///
  /// In ru, this message translates to:
  /// **'Средний'**
  String get settings_chats_font_medium;

  /// No description provided for @settings_chats_font_large.
  ///
  /// In ru, this message translates to:
  /// **'Крупный'**
  String get settings_chats_font_large;

  /// No description provided for @settings_chats_bubble_shape.
  ///
  /// In ru, this message translates to:
  /// **'Форма пузырьков'**
  String get settings_chats_bubble_shape;

  /// No description provided for @settings_chats_bubble_rounded.
  ///
  /// In ru, this message translates to:
  /// **'Округлённые'**
  String get settings_chats_bubble_rounded;

  /// No description provided for @settings_chats_bubble_square.
  ///
  /// In ru, this message translates to:
  /// **'Квадратные'**
  String get settings_chats_bubble_square;

  /// No description provided for @settings_chats_chat_background.
  ///
  /// In ru, this message translates to:
  /// **'Фон чата'**
  String get settings_chats_chat_background;

  /// No description provided for @settings_chats_chat_background_pick_hint.
  ///
  /// In ru, this message translates to:
  /// **'Выберите фото из галереи или настройте'**
  String get settings_chats_chat_background_pick_hint;

  /// No description provided for @settings_chats_advanced.
  ///
  /// In ru, this message translates to:
  /// **'Дополнительно'**
  String get settings_chats_advanced;

  /// No description provided for @settings_chats_show_time.
  ///
  /// In ru, this message translates to:
  /// **'Показывать время'**
  String get settings_chats_show_time;

  /// No description provided for @settings_chats_show_time_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Время отправки под сообщениями'**
  String get settings_chats_show_time_subtitle;

  /// No description provided for @settings_chats_reset.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить настройки'**
  String get settings_chats_reset;

  /// No description provided for @settings_chats_error_cannot_save.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить: {error}'**
  String settings_chats_error_cannot_save(Object error);

  /// No description provided for @settings_chats_error_wallpaper_load.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки фона: {error}'**
  String settings_chats_error_wallpaper_load(Object error);

  /// No description provided for @settings_chats_error_wallpaper_delete.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка удаления фона: {error}'**
  String settings_chats_error_wallpaper_delete(Object error);

  /// No description provided for @settings_chats_wallpaper_delete_confirm_title.
  ///
  /// In ru, this message translates to:
  /// **'Удалить фон?'**
  String get settings_chats_wallpaper_delete_confirm_title;

  /// No description provided for @settings_chats_wallpaper_delete_confirm_body.
  ///
  /// In ru, this message translates to:
  /// **'Этот фон будет удалён из вашего списка.'**
  String get settings_chats_wallpaper_delete_confirm_body;

  /// No description provided for @settings_chats_icon_picker_title.
  ///
  /// In ru, this message translates to:
  /// **'Иконка: «{label}»'**
  String settings_chats_icon_picker_title(Object label);

  /// No description provided for @settings_chats_icon_picker_search_hint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск по названию…'**
  String get settings_chats_icon_picker_search_hint;

  /// No description provided for @settings_chats_icon_color.
  ///
  /// In ru, this message translates to:
  /// **'Цвет иконки'**
  String get settings_chats_icon_color;

  /// No description provided for @settings_chats_reset_icon_size.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить размер'**
  String get settings_chats_reset_icon_size;

  /// No description provided for @settings_chats_reset_icon_stroke.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить толщину'**
  String get settings_chats_reset_icon_stroke;

  /// No description provided for @settings_chats_tile_background.
  ///
  /// In ru, this message translates to:
  /// **'Фон плитки под иконкой'**
  String get settings_chats_tile_background;

  /// No description provided for @settings_chats_default_gradient.
  ///
  /// In ru, this message translates to:
  /// **'Градиент по умолчанию'**
  String get settings_chats_default_gradient;

  /// No description provided for @settings_chats_inherit_global.
  ///
  /// In ru, this message translates to:
  /// **'Наследовать от глобальных'**
  String get settings_chats_inherit_global;

  /// No description provided for @settings_chats_no_background.
  ///
  /// In ru, this message translates to:
  /// **'Без фона'**
  String get settings_chats_no_background;

  /// No description provided for @settings_chats_no_background_on.
  ///
  /// In ru, this message translates to:
  /// **'Без фона (вкл.)'**
  String get settings_chats_no_background_on;

  /// No description provided for @chat_list_title.
  ///
  /// In ru, this message translates to:
  /// **'Чаты'**
  String get chat_list_title;

  /// No description provided for @chat_list_search_hint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск…'**
  String get chat_list_search_hint;

  /// No description provided for @chat_list_loading_connecting.
  ///
  /// In ru, this message translates to:
  /// **'Подключение к аккаунту…'**
  String get chat_list_loading_connecting;

  /// No description provided for @chat_list_loading_conversations.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка бесед…'**
  String get chat_list_loading_conversations;

  /// No description provided for @chat_list_loading_list.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка списка чатов…'**
  String get chat_list_loading_list;

  /// No description provided for @chat_list_loading_sign_out.
  ///
  /// In ru, this message translates to:
  /// **'Выход…'**
  String get chat_list_loading_sign_out;

  /// No description provided for @chat_list_empty_search_title.
  ///
  /// In ru, this message translates to:
  /// **'Чаты не найдены'**
  String get chat_list_empty_search_title;

  /// No description provided for @chat_list_empty_search_body.
  ///
  /// In ru, this message translates to:
  /// **'Попробуйте изменить запрос. Поиск работает по имени пользователя и логину.'**
  String get chat_list_empty_search_body;

  /// No description provided for @chat_list_empty_folder_title.
  ///
  /// In ru, this message translates to:
  /// **'В этой папке пока пусто'**
  String get chat_list_empty_folder_title;

  /// No description provided for @chat_list_empty_folder_body.
  ///
  /// In ru, this message translates to:
  /// **'Переключитесь на другую папку или создайте новый чат через кнопку вверху.'**
  String get chat_list_empty_folder_body;

  /// No description provided for @chat_list_empty_all_title.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет чатов'**
  String get chat_list_empty_all_title;

  /// No description provided for @chat_list_empty_all_body.
  ///
  /// In ru, this message translates to:
  /// **'Создайте новый чат, чтобы начать переписку.'**
  String get chat_list_empty_all_body;

  /// No description provided for @chat_list_action_new_folder.
  ///
  /// In ru, this message translates to:
  /// **'Новая папка'**
  String get chat_list_action_new_folder;

  /// No description provided for @chat_list_action_new_chat.
  ///
  /// In ru, this message translates to:
  /// **'Новый чат'**
  String get chat_list_action_new_chat;

  /// No description provided for @chat_list_action_create.
  ///
  /// In ru, this message translates to:
  /// **'Создать'**
  String get chat_list_action_create;

  /// No description provided for @chat_list_action_close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get chat_list_action_close;

  /// No description provided for @chat_list_folders_title.
  ///
  /// In ru, this message translates to:
  /// **'Папки'**
  String get chat_list_folders_title;

  /// No description provided for @chat_list_folders_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Выберите папки для этого чата.'**
  String get chat_list_folders_subtitle;

  /// No description provided for @chat_list_folders_empty.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет кастомных папок.'**
  String get chat_list_folders_empty;

  /// No description provided for @chat_list_create_folder_title.
  ///
  /// In ru, this message translates to:
  /// **'Новая папка'**
  String get chat_list_create_folder_title;

  /// No description provided for @chat_list_create_folder_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Создайте папку для быстрой фильтрации чатов.'**
  String get chat_list_create_folder_subtitle;

  /// No description provided for @chat_list_create_folder_name_label.
  ///
  /// In ru, this message translates to:
  /// **'НАЗВАНИЕ ПАПКИ'**
  String get chat_list_create_folder_name_label;

  /// No description provided for @chat_list_create_folder_chats_label.
  ///
  /// In ru, this message translates to:
  /// **'ЧАТЫ ({count})'**
  String chat_list_create_folder_chats_label(Object count);

  /// No description provided for @chat_list_create_folder_select_all.
  ///
  /// In ru, this message translates to:
  /// **'ВЫБРАТЬ ВСЁ'**
  String get chat_list_create_folder_select_all;

  /// No description provided for @chat_list_create_folder_reset.
  ///
  /// In ru, this message translates to:
  /// **'СБРОСИТЬ'**
  String get chat_list_create_folder_reset;

  /// No description provided for @chat_list_create_folder_search_hint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск по названию…'**
  String get chat_list_create_folder_search_hint;

  /// No description provided for @chat_list_create_folder_no_matches.
  ///
  /// In ru, this message translates to:
  /// **'Подходящие чаты не найдены'**
  String get chat_list_create_folder_no_matches;

  /// No description provided for @chat_list_folder_default_starred.
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get chat_list_folder_default_starred;

  /// No description provided for @chat_list_folder_default_all.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get chat_list_folder_default_all;

  /// No description provided for @chat_list_folder_default_new.
  ///
  /// In ru, this message translates to:
  /// **'Новые'**
  String get chat_list_folder_default_new;

  /// No description provided for @chat_list_folder_default_direct.
  ///
  /// In ru, this message translates to:
  /// **'Личные'**
  String get chat_list_folder_default_direct;

  /// No description provided for @chat_list_folder_default_groups.
  ///
  /// In ru, this message translates to:
  /// **'Группы'**
  String get chat_list_folder_default_groups;

  /// No description provided for @chat_list_yesterday.
  ///
  /// In ru, this message translates to:
  /// **'Вчера'**
  String get chat_list_yesterday;

  /// No description provided for @chat_list_snackbar_history_cleared.
  ///
  /// In ru, this message translates to:
  /// **'История очищена.'**
  String get chat_list_snackbar_history_cleared;

  /// No description provided for @chat_list_snackbar_marked_read.
  ///
  /// In ru, this message translates to:
  /// **'Чат помечен как прочитанный.'**
  String get chat_list_snackbar_marked_read;

  /// No description provided for @chat_list_error_generic.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка: {error}'**
  String chat_list_error_generic(Object error);

  /// No description provided for @new_chat_title.
  ///
  /// In ru, this message translates to:
  /// **'Новый чат'**
  String get new_chat_title;

  /// No description provided for @new_chat_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Выберите пользователя, чтобы начать диалог, или создайте группу.'**
  String get new_chat_subtitle;

  /// No description provided for @new_chat_search_hint.
  ///
  /// In ru, this message translates to:
  /// **'Имя, ник или @username…'**
  String get new_chat_search_hint;

  /// No description provided for @new_chat_create_group.
  ///
  /// In ru, this message translates to:
  /// **'Создать группу'**
  String get new_chat_create_group;

  /// No description provided for @new_chat_section_phone_contacts.
  ///
  /// In ru, this message translates to:
  /// **'КОНТАКТЫ ТЕЛЕФОНА'**
  String get new_chat_section_phone_contacts;

  /// No description provided for @new_chat_section_contacts.
  ///
  /// In ru, this message translates to:
  /// **'КОНТАКТЫ'**
  String get new_chat_section_contacts;

  /// No description provided for @new_chat_section_all_users.
  ///
  /// In ru, this message translates to:
  /// **'ВСЕ ПОЛЬЗОВАТЕЛИ'**
  String get new_chat_section_all_users;

  /// No description provided for @new_chat_empty_no_users.
  ///
  /// In ru, this message translates to:
  /// **'Нет пользователей, с которыми можно начать чат.'**
  String get new_chat_empty_no_users;

  /// No description provided for @new_chat_empty_not_found.
  ///
  /// In ru, this message translates to:
  /// **'Никого не найдено.'**
  String get new_chat_empty_not_found;

  /// No description provided for @new_chat_error_contacts.
  ///
  /// In ru, this message translates to:
  /// **'Контакты: {error}'**
  String new_chat_error_contacts(Object error);

  /// No description provided for @invite_subject.
  ///
  /// In ru, this message translates to:
  /// **'Приглашение в LighChat'**
  String get invite_subject;

  /// No description provided for @invite_text.
  ///
  /// In ru, this message translates to:
  /// **'Поставь LighChat: https://lighchat.online\\nПриглашаю тебя в LighChat — вот ссылка на установку.'**
  String get invite_text;

  /// No description provided for @new_group_title.
  ///
  /// In ru, this message translates to:
  /// **'Создать группу'**
  String get new_group_title;

  /// No description provided for @new_group_search_hint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск пользователей…'**
  String get new_group_search_hint;

  /// No description provided for @new_group_pick_photo_tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите, чтобы выбрать фото группы. Удерживайте, чтобы убрать.'**
  String get new_group_pick_photo_tooltip;

  /// No description provided for @new_group_name_label.
  ///
  /// In ru, this message translates to:
  /// **'Название группы'**
  String get new_group_name_label;

  /// No description provided for @new_group_name_hint.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get new_group_name_hint;

  /// No description provided for @new_group_description_label.
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get new_group_description_label;

  /// No description provided for @new_group_description_hint.
  ///
  /// In ru, this message translates to:
  /// **'Необязательно'**
  String get new_group_description_hint;

  /// No description provided for @new_group_members_count.
  ///
  /// In ru, this message translates to:
  /// **'Участники ({count})'**
  String new_group_members_count(Object count);

  /// No description provided for @new_group_add_members_section.
  ///
  /// In ru, this message translates to:
  /// **'ДОБАВИТЬ УЧАСТНИКОВ'**
  String get new_group_add_members_section;

  /// No description provided for @new_group_empty_no_users.
  ///
  /// In ru, this message translates to:
  /// **'Нет пользователей для добавления.'**
  String get new_group_empty_no_users;

  /// No description provided for @new_group_empty_not_found.
  ///
  /// In ru, this message translates to:
  /// **'Никого не найдено.'**
  String get new_group_empty_not_found;

  /// No description provided for @new_group_error_name_required.
  ///
  /// In ru, this message translates to:
  /// **'Введите название группы.'**
  String get new_group_error_name_required;

  /// No description provided for @new_group_error_members_required.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте хотя бы одного участника.'**
  String get new_group_error_members_required;

  /// No description provided for @new_group_action_create.
  ///
  /// In ru, this message translates to:
  /// **'Создать'**
  String get new_group_action_create;

  /// No description provided for @auth_brand_tagline.
  ///
  /// In ru, this message translates to:
  /// **'Безопасный мессенджер'**
  String get auth_brand_tagline;

  /// No description provided for @auth_firebase_not_ready.
  ///
  /// In ru, this message translates to:
  /// **'Firebase не готов. Проверь `firebase_options.dart` и GoogleService-Info.plist.'**
  String get auth_firebase_not_ready;

  /// No description provided for @auth_redirecting_to_chats.
  ///
  /// In ru, this message translates to:
  /// **'Переходим в чаты...'**
  String get auth_redirecting_to_chats;

  /// No description provided for @auth_or.
  ///
  /// In ru, this message translates to:
  /// **'или'**
  String get auth_or;

  /// No description provided for @auth_create_account.
  ///
  /// In ru, this message translates to:
  /// **'Создать аккаунт'**
  String get auth_create_account;

  /// No description provided for @auth_privacy_policy.
  ///
  /// In ru, this message translates to:
  /// **'Политика конфиденциальности'**
  String get auth_privacy_policy;

  /// No description provided for @auth_error_open_privacy_policy.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть политику конфиденциальности'**
  String get auth_error_open_privacy_policy;

  /// No description provided for @chat_messages_title.
  ///
  /// In ru, this message translates to:
  /// **'Сообщения'**
  String get chat_messages_title;

  /// No description provided for @chat_call_decline.
  ///
  /// In ru, this message translates to:
  /// **'Отклонить'**
  String get chat_call_decline;

  /// No description provided for @chat_call_open.
  ///
  /// In ru, this message translates to:
  /// **'Открыть'**
  String get chat_call_open;

  /// No description provided for @chat_call_accept.
  ///
  /// In ru, this message translates to:
  /// **'Принять'**
  String get chat_call_accept;

  /// No description provided for @chat_delete_message_title_single.
  ///
  /// In ru, this message translates to:
  /// **'Удалить сообщение?'**
  String get chat_delete_message_title_single;

  /// No description provided for @chat_delete_message_title_multi.
  ///
  /// In ru, this message translates to:
  /// **'Удалить сообщения?'**
  String get chat_delete_message_title_multi;

  /// No description provided for @chat_delete_message_body_single.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение будет скрыто у всех.'**
  String get chat_delete_message_body_single;

  /// No description provided for @chat_delete_message_body_multi.
  ///
  /// In ru, this message translates to:
  /// **'Будет удалено сообщений: {count}'**
  String chat_delete_message_body_multi(Object count);

  /// No description provided for @chat_delete_file_title.
  ///
  /// In ru, this message translates to:
  /// **'Удалить файл?'**
  String get chat_delete_file_title;

  /// No description provided for @chat_delete_file_body.
  ///
  /// In ru, this message translates to:
  /// **'Будет удалён только этот файл из сообщения.'**
  String get chat_delete_file_body;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
