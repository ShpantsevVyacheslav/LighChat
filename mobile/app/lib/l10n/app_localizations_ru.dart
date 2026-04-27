// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get settings_language_title => 'Язык';

  @override
  String get settings_language_system => 'Системный';

  @override
  String get settings_language_ru => 'Русский';

  @override
  String get settings_language_en => 'English';

  @override
  String get settings_language_hint_system =>
      'При выборе «Системный» язык соответствует настройкам устройства.';

  @override
  String get account_menu_profile => 'Профиль';

  @override
  String get account_menu_chat_settings => 'Настройки чатов';

  @override
  String get account_menu_notifications => 'Уведомления';

  @override
  String get account_menu_privacy => 'Конфиденциальность';

  @override
  String get account_menu_blacklist => 'Черный список';

  @override
  String get account_menu_language => 'Язык';

  @override
  String get account_menu_theme => 'Тема';

  @override
  String get account_menu_sign_out => 'Выйти';

  @override
  String get profile_delete_account => 'Удалить аккаунт';

  @override
  String get profile_delete_account_confirm_title =>
      'Удалить аккаунт безвозвратно?';

  @override
  String get profile_delete_account_confirm_body =>
      'Ваш аккаунт будет удалён из Firebase Auth и все ваши документы в Firestore будут удалены без возможности восстановления. У собеседников останутся ваши чаты в режиме только чтение.';

  @override
  String get profile_delete_account_confirm_action => 'Удалить аккаунт';

  @override
  String profile_delete_account_error(Object error) {
    return 'Не удалось удалить аккаунт: $error';
  }

  @override
  String get chat_readonly_deleted_user =>
      'Аккаунт удалён. Чат доступен только для чтения.';

  @override
  String get blacklist_empty => 'Нет заблокированных пользователей';

  @override
  String get blacklist_action_unblock => 'Разблокировать';

  @override
  String get blacklist_unblock_confirm_title => 'Разблокировать?';

  @override
  String get blacklist_unblock_confirm_body =>
      'Пользователь снова сможет писать вам (если политика контактов позволит) и видеть ваш профиль в поиске.';

  @override
  String get blacklist_unblock_success => 'Пользователь разблокирован';

  @override
  String blacklist_unblock_error(Object error) {
    return 'Не удалось разблокировать: $error';
  }

  @override
  String get common_soon => 'Скоро';

  @override
  String common_theme_prefix(Object label) {
    return 'Тема: $label';
  }

  @override
  String common_error_cannot_save_theme(Object error) {
    return 'Не удалось сохранить тему: $error';
  }

  @override
  String common_error_cannot_sign_out(Object error) {
    return 'Не удалось выйти: $error';
  }

  @override
  String account_error_profile(Object error) {
    return 'Ошибка профиля: $error';
  }

  @override
  String get notifications_title => 'Уведомления';

  @override
  String get notifications_section_main => 'Основные';

  @override
  String get notifications_mute_all_title => 'Отключить все';

  @override
  String get notifications_mute_all_subtitle =>
      'Полностью выключить уведомления.';

  @override
  String get notifications_sound_title => 'Звук';

  @override
  String get notifications_sound_subtitle =>
      'Воспроизводить звук при новом сообщении.';

  @override
  String get notifications_preview_title => 'Предпросмотр';

  @override
  String get notifications_preview_subtitle =>
      'Показывать текст сообщения в уведомлении.';

  @override
  String get notifications_section_quiet_hours => 'Тихие часы';

  @override
  String get notifications_quiet_hours_subtitle =>
      'Уведомления не будут беспокоить в указанный период.';

  @override
  String get notifications_quiet_hours_enable_title => 'Включить тихие часы';

  @override
  String get notifications_reset_button => 'Сбросить настройки';

  @override
  String notifications_error_cannot_save(Object error) {
    return 'Не удалось сохранить настройки: $error';
  }

  @override
  String notifications_error_load(Object error) {
    return 'Ошибка загрузки уведомлений: $error';
  }

  @override
  String get privacy_title => 'Конфиденциальность';

  @override
  String privacy_error_cannot_save(Object error) {
    return 'Не удалось сохранить настройки: $error';
  }

  @override
  String privacy_error_load(Object error) {
    return 'Ошибка загрузки конфиденциальности: $error';
  }

  @override
  String get privacy_e2ee_section => 'Сквозное шифрование';

  @override
  String get privacy_e2ee_enable_for_all_chats =>
      'Включить шифрование (E2E) для всех чатов';

  @override
  String get privacy_e2ee_what_encrypt => 'Что шифруем в E2EE чатах';

  @override
  String get privacy_e2ee_text => 'Текст сообщений';

  @override
  String get privacy_e2ee_media => 'Вложения (медиа/файлы)';

  @override
  String get privacy_my_devices_title => 'Мои устройства';

  @override
  String get privacy_my_devices_subtitle =>
      'Список устройств с опубликованным ключом. Переименовать или отозвать.';

  @override
  String get privacy_key_backup_title =>
      'Резервное копирование и передача ключа';

  @override
  String get privacy_key_backup_subtitle =>
      'Создать backup паролем или передать ключ другому устройству по QR.';

  @override
  String get privacy_visibility_section => 'Видимость';

  @override
  String get privacy_online_title => 'Статус онлайн';

  @override
  String get privacy_online_subtitle =>
      'Другие пользователи видят, что вы в сети.';

  @override
  String get privacy_last_seen_title => 'Последний визит';

  @override
  String get privacy_last_seen_subtitle =>
      'Показывать время последнего посещения.';

  @override
  String get privacy_read_receipts_title => 'Индикатор прочтения';

  @override
  String get privacy_read_receipts_subtitle =>
      'Показывать отправителям, что вы прочитали сообщение.';

  @override
  String get privacy_group_invites_section => 'Приглашения в группы';

  @override
  String get privacy_group_invites_subtitle =>
      'Кто может добавлять вас в групповой чат.';

  @override
  String get privacy_group_invites_everyone => 'Все пользователи';

  @override
  String get privacy_group_invites_contacts => 'Только контакты';

  @override
  String get privacy_group_invites_nobody => 'Никто';

  @override
  String get privacy_global_search_section => 'Поиск собеседников';

  @override
  String get privacy_global_search_subtitle =>
      'Кто может найти вас по имени среди всех пользователей приложения.';

  @override
  String get privacy_global_search_title => 'Глобальный поиск';

  @override
  String get privacy_global_search_hint =>
      'Если выключено, вы не отображаетесь в списке «Все пользователи» при создании чата. В блоке «Контакты» вы по-прежнему видны тем, кто добавил вас в контакты.';

  @override
  String get privacy_profile_for_others_section => 'Профиль для других';

  @override
  String get privacy_profile_for_others_subtitle =>
      'Что показывать в карточке контакта и в профиле из беседы.';

  @override
  String get privacy_email_subtitle => 'Адрес почты в профиле собеседника.';

  @override
  String get privacy_phone_title => 'Номер телефона';

  @override
  String get privacy_phone_subtitle =>
      'В профиле и в списке контактов у других.';

  @override
  String get privacy_birthdate_title => 'Дата рождения';

  @override
  String get privacy_birthdate_subtitle => 'Поле «День рождения» в профиле.';

  @override
  String get privacy_about_title => 'О себе';

  @override
  String get privacy_about_subtitle => 'Текст биографии в профиле.';

  @override
  String get privacy_reset_button => 'Сбросить настройки';

  @override
  String get common_cancel => 'Отмена';

  @override
  String get common_delete => 'Удалить';

  @override
  String get common_choose => 'Выбрать';

  @override
  String get common_save => 'Сохранить';

  @override
  String get common_nothing_found => 'Ничего не найдено';

  @override
  String get common_retry => 'Повторить';

  @override
  String get auth_login_email_label => 'Email';

  @override
  String get auth_login_password_label => 'Пароль';

  @override
  String get auth_login_password_hint => 'Пароль';

  @override
  String get auth_login_sign_in => 'Войти';

  @override
  String get auth_login_forgot_password => 'Забыли пароль?';

  @override
  String get auth_login_error_enter_email_for_reset =>
      'Введите email для восстановления пароля';

  @override
  String get profile_title => 'Профиль';

  @override
  String get profile_edit_tooltip => 'Редактировать';

  @override
  String get profile_full_name_label => 'ФИО';

  @override
  String get profile_full_name_hint => 'Имя';

  @override
  String get profile_username_label => 'Логин';

  @override
  String get profile_email_label => 'Email';

  @override
  String get profile_phone_label => 'Телефон';

  @override
  String get profile_birthdate_label => 'Дата рождения';

  @override
  String get profile_about_label => 'О себе';

  @override
  String get profile_about_hint => 'Кратко о себе';

  @override
  String get profile_password_toggle_show => 'Изменить пароль';

  @override
  String get profile_password_toggle_hide => 'Скрыть смену пароля';

  @override
  String get profile_password_new_label => 'Новый пароль';

  @override
  String get profile_password_confirm_label => 'Повторите пароль';

  @override
  String get profile_password_tooltip_show => 'Показать пароль';

  @override
  String get profile_password_tooltip_hide => 'Скрыть';

  @override
  String get settings_chats_title => 'Настройки чатов';

  @override
  String get settings_chats_preview => 'Предпросмотр';

  @override
  String get settings_chats_outgoing => 'Исходящие сообщения';

  @override
  String get settings_chats_incoming => 'Входящие сообщения';

  @override
  String get settings_chats_font_size => 'Размер шрифта';

  @override
  String get settings_chats_font_small => 'Мелкий';

  @override
  String get settings_chats_font_medium => 'Средний';

  @override
  String get settings_chats_font_large => 'Крупный';

  @override
  String get settings_chats_bubble_shape => 'Форма пузырьков';

  @override
  String get settings_chats_bubble_rounded => 'Округлённые';

  @override
  String get settings_chats_bubble_square => 'Квадратные';

  @override
  String get settings_chats_chat_background => 'Фон чата';

  @override
  String get settings_chats_chat_background_pick_hint =>
      'Выберите фото из галереи или настройте';

  @override
  String get settings_chats_advanced => 'Дополнительно';

  @override
  String get settings_chats_show_time => 'Показывать время';

  @override
  String get settings_chats_show_time_subtitle =>
      'Время отправки под сообщениями';

  @override
  String get settings_chats_reset => 'Сбросить настройки';

  @override
  String settings_chats_error_cannot_save(Object error) {
    return 'Не удалось сохранить: $error';
  }

  @override
  String settings_chats_error_wallpaper_load(Object error) {
    return 'Ошибка загрузки фона: $error';
  }

  @override
  String settings_chats_error_wallpaper_delete(Object error) {
    return 'Ошибка удаления фона: $error';
  }

  @override
  String get settings_chats_wallpaper_delete_confirm_title => 'Удалить фон?';

  @override
  String get settings_chats_wallpaper_delete_confirm_body =>
      'Этот фон будет удалён из вашего списка.';

  @override
  String settings_chats_icon_picker_title(Object label) {
    return 'Иконка: «$label»';
  }

  @override
  String get settings_chats_icon_picker_search_hint => 'Поиск по названию…';

  @override
  String get settings_chats_icon_color => 'Цвет иконки';

  @override
  String get settings_chats_reset_icon_size => 'Сбросить размер';

  @override
  String get settings_chats_reset_icon_stroke => 'Сбросить толщину';

  @override
  String get settings_chats_tile_background => 'Фон плитки под иконкой';

  @override
  String get settings_chats_default_gradient => 'Градиент по умолчанию';

  @override
  String get settings_chats_inherit_global => 'Наследовать от глобальных';

  @override
  String get settings_chats_no_background => 'Без фона';

  @override
  String get settings_chats_no_background_on => 'Без фона (вкл.)';

  @override
  String get chat_list_title => 'Чаты';

  @override
  String get chat_list_search_hint => 'Поиск…';

  @override
  String get chat_list_loading_connecting => 'Подключение к аккаунту…';

  @override
  String get chat_list_loading_conversations => 'Загрузка бесед…';

  @override
  String get chat_list_loading_list => 'Загрузка списка чатов…';

  @override
  String get chat_list_loading_sign_out => 'Выход…';

  @override
  String get chat_list_empty_search_title => 'Чаты не найдены';

  @override
  String get chat_list_empty_search_body =>
      'Попробуйте изменить запрос. Поиск работает по имени пользователя и логину.';

  @override
  String get chat_list_empty_folder_title => 'В этой папке пока пусто';

  @override
  String get chat_list_empty_folder_body =>
      'Переключитесь на другую папку или создайте новый чат через кнопку вверху.';

  @override
  String get chat_list_empty_all_title => 'Пока нет чатов';

  @override
  String get chat_list_empty_all_body =>
      'Создайте новый чат, чтобы начать переписку.';

  @override
  String get chat_list_action_new_folder => 'Новая папка';

  @override
  String get chat_list_action_new_chat => 'Новый чат';

  @override
  String get chat_list_action_create => 'Создать';

  @override
  String get chat_list_action_close => 'Закрыть';

  @override
  String get chat_list_folders_title => 'Папки';

  @override
  String get chat_list_folders_subtitle => 'Выберите папки для этого чата.';

  @override
  String get chat_list_folders_empty => 'Пока нет кастомных папок.';

  @override
  String get chat_list_create_folder_title => 'Новая папка';

  @override
  String get chat_list_create_folder_subtitle =>
      'Создайте папку для быстрой фильтрации чатов.';

  @override
  String get chat_list_create_folder_name_label => 'НАЗВАНИЕ ПАПКИ';

  @override
  String chat_list_create_folder_chats_label(Object count) {
    return 'ЧАТЫ ($count)';
  }

  @override
  String get chat_list_create_folder_select_all => 'ВЫБРАТЬ ВСЁ';

  @override
  String get chat_list_create_folder_reset => 'СБРОСИТЬ';

  @override
  String get chat_list_create_folder_search_hint => 'Поиск по названию…';

  @override
  String get chat_list_create_folder_no_matches => 'Подходящие чаты не найдены';

  @override
  String get chat_list_folder_default_starred => 'Избранное';

  @override
  String get chat_list_folder_default_all => 'Все';

  @override
  String get chat_list_folder_default_new => 'Новые';

  @override
  String get chat_list_folder_default_direct => 'Личные';

  @override
  String get chat_list_folder_default_groups => 'Группы';

  @override
  String get chat_list_yesterday => 'Вчера';

  @override
  String get chat_list_folder_delete_action => 'Удалить';

  @override
  String get chat_list_folder_delete_title => 'Удалить папку?';

  @override
  String chat_list_folder_delete_body(Object name) {
    return 'Папка \"$name\" будет удалена. Чаты останутся на месте.';
  }

  @override
  String chat_list_error_open_starred(Object error) {
    return 'Не удалось открыть Избранное: $error';
  }

  @override
  String chat_list_error_delete_folder(Object error) {
    return 'Не удалось удалить папку: $error';
  }

  @override
  String get chat_list_pin_not_available =>
      'В этой папке закрепление недоступно.';

  @override
  String chat_list_pin_pinned_in_folder(Object name) {
    return 'Чат закреплен в папке \"$name\"';
  }

  @override
  String chat_list_pin_unpinned_in_folder(Object name) {
    return 'Чат откреплен из папки \"$name\"';
  }

  @override
  String chat_list_error_toggle_pin(Object error) {
    return 'Не удалось изменить закрепление: $error';
  }

  @override
  String chat_list_error_update_folder(Object error) {
    return 'Не удалось обновить папку: $error';
  }

  @override
  String get chat_list_clear_history_title => 'Очистить историю?';

  @override
  String get chat_list_clear_history_body =>
      'Сообщения исчезнут только из вашего окна чата. У собеседника история останется.';

  @override
  String get chat_list_clear_history_confirm => 'Очистить';

  @override
  String chat_list_error_clear_history(Object error) {
    return 'Не удалось очистить историю: $error';
  }

  @override
  String chat_list_error_mark_read(Object error) {
    return 'Не удалось пометить чат как прочитанный: $error';
  }

  @override
  String get chat_list_delete_chat_title => 'Удалить чат?';

  @override
  String get chat_list_delete_chat_body =>
      'Переписка будет безвозвратно удалена для всех участников. Это действие нельзя отменить.';

  @override
  String get chat_list_delete_chat_confirm => 'Удалить';

  @override
  String chat_list_error_delete_chat(Object error) {
    return 'Не удалось удалить чат: $error';
  }

  @override
  String get chat_list_context_folders => 'Папки';

  @override
  String get chat_list_context_unpin => 'Открепить чат';

  @override
  String get chat_list_context_pin => 'Закрепить чат';

  @override
  String get chat_list_context_mark_all_read => 'Прочитать все';

  @override
  String get chat_list_context_clear_history => 'Очистить историю';

  @override
  String get chat_list_context_delete_chat => 'Удалить чат';

  @override
  String get chat_list_snackbar_history_cleared => 'История очищена.';

  @override
  String get chat_list_snackbar_marked_read => 'Чат помечен как прочитанный.';

  @override
  String chat_list_error_generic(Object error) {
    return 'Ошибка: $error';
  }

  @override
  String chat_list_item_draft_line(Object line) {
    return 'Черновик · $line';
  }

  @override
  String get chat_list_item_chat_created => 'Чат создан';

  @override
  String get chat_list_item_no_messages_yet => 'Пока нет сообщений';

  @override
  String get chat_list_item_history_cleared => 'История очищена';

  @override
  String get chat_list_firebase_not_configured => 'Firebase ещё не настроен.';

  @override
  String get new_chat_title => 'Новый чат';

  @override
  String get new_chat_subtitle =>
      'Выберите пользователя, чтобы начать диалог, или создайте группу.';

  @override
  String get new_chat_search_hint => 'Имя, ник или @username…';

  @override
  String get new_chat_create_group => 'Создать группу';

  @override
  String get new_chat_section_phone_contacts => 'КОНТАКТЫ ТЕЛЕФОНА';

  @override
  String get new_chat_section_contacts => 'КОНТАКТЫ';

  @override
  String get new_chat_section_all_users => 'ВСЕ ПОЛЬЗОВАТЕЛИ';

  @override
  String get new_chat_empty_no_users =>
      'Нет пользователей, с которыми можно начать чат.';

  @override
  String get new_chat_empty_not_found => 'Никого не найдено.';

  @override
  String new_chat_error_contacts(Object error) {
    return 'Контакты: $error';
  }

  @override
  String get invite_subject => 'Приглашение в LighChat';

  @override
  String get invite_text =>
      'Поставь LighChat: https://lighchat.online\\nПриглашаю тебя в LighChat — вот ссылка на установку.';

  @override
  String get new_group_title => 'Создать группу';

  @override
  String get new_group_search_hint => 'Поиск пользователей…';

  @override
  String get new_group_pick_photo_tooltip =>
      'Нажмите, чтобы выбрать фото группы. Удерживайте, чтобы убрать.';

  @override
  String get new_group_name_label => 'Название группы';

  @override
  String get new_group_name_hint => 'Название';

  @override
  String get new_group_description_label => 'Описание';

  @override
  String get new_group_description_hint => 'Необязательно';

  @override
  String new_group_members_count(Object count) {
    return 'Участники ($count)';
  }

  @override
  String get new_group_add_members_section => 'ДОБАВИТЬ УЧАСТНИКОВ';

  @override
  String get new_group_empty_no_users => 'Нет пользователей для добавления.';

  @override
  String get new_group_empty_not_found => 'Никого не найдено.';

  @override
  String get new_group_error_name_required => 'Введите название группы.';

  @override
  String get new_group_error_members_required =>
      'Добавьте хотя бы одного участника.';

  @override
  String get new_group_action_create => 'Создать';

  @override
  String get auth_brand_tagline => 'Безопасный мессенджер';

  @override
  String get auth_firebase_not_ready =>
      'Firebase не готов. Проверь `firebase_options.dart` и GoogleService-Info.plist.';

  @override
  String get auth_redirecting_to_chats => 'Переходим в чаты...';

  @override
  String get auth_or => 'или';

  @override
  String get auth_create_account => 'Создать аккаунт';

  @override
  String get auth_privacy_policy => 'Политика конфиденциальности';

  @override
  String get auth_error_open_privacy_policy =>
      'Не удалось открыть политику конфиденциальности';

  @override
  String get voice_transcript_show => 'Показать текст';

  @override
  String get voice_transcript_hide => 'Скрыть текст';

  @override
  String get voice_transcript_copy => 'Копировать';

  @override
  String get voice_transcript_loading => 'Транскрибация…';

  @override
  String get voice_transcript_failed => 'Не удалось получить текст.';

  @override
  String voice_transcript_error(Object error) {
    return 'Не удалось сделать транскрибацию: $error';
  }

  @override
  String get chat_messages_title => 'Сообщения';

  @override
  String get chat_call_decline => 'Отклонить';

  @override
  String get chat_call_open => 'Открыть';

  @override
  String get chat_call_accept => 'Принять';

  @override
  String video_call_error_init(Object error) {
    return 'Ошибка видеозвонка: $error';
  }

  @override
  String get video_call_ended => 'Звонок завершён';

  @override
  String get video_call_status_missed => 'Пропущенный звонок';

  @override
  String get video_call_status_cancelled => 'Звонок отменён';

  @override
  String get video_call_error_offer_not_ready =>
      'Оффер ещё не готов, попробуйте снова';

  @override
  String get video_call_error_invalid_call_data => 'Некорректные данные звонка';

  @override
  String video_call_error_accept_failed(Object error) {
    return 'Не удалось принять звонок: $error';
  }

  @override
  String get video_call_incoming => 'Входящий видеозвонок';

  @override
  String get video_call_connecting => 'Видеозвонок…';

  @override
  String get video_call_pip_tooltip => 'Картинка в картинке';

  @override
  String get video_call_mini_window_tooltip => 'Мини-окно';

  @override
  String get chat_delete_message_title_single => 'Удалить сообщение?';

  @override
  String get chat_delete_message_title_multi => 'Удалить сообщения?';

  @override
  String get chat_delete_message_body_single =>
      'Сообщение будет скрыто у всех.';

  @override
  String chat_delete_message_body_multi(Object count) {
    return 'Будет удалено сообщений: $count';
  }

  @override
  String get chat_delete_file_title => 'Удалить файл?';

  @override
  String get chat_delete_file_body =>
      'Будет удалён только этот файл из сообщения.';

  @override
  String get forward_title => 'Переслать';

  @override
  String get forward_empty_no_messages => 'Нет сообщений для пересылки';

  @override
  String get forward_error_not_authorized => 'Не авторизован';

  @override
  String get forward_empty_no_recipients =>
      'Нет контактов и чатов для пересылки';

  @override
  String get forward_search_hint => 'Поиск контактов…';

  @override
  String get forward_empty_no_available_recipients =>
      'Доступных получателей нет.\nМожно пересылать только контактам и в ваши активные чаты.';

  @override
  String get forward_empty_not_found => 'Ничего не найдено';

  @override
  String get forward_action_pick_recipients => 'Выберите получателей';

  @override
  String get forward_action_send => 'Отправить';

  @override
  String forward_error_generic(Object error) {
    return 'Ошибка: $error';
  }

  @override
  String get forward_sender_fallback => 'Участник';

  @override
  String get forward_error_profiles_load =>
      'Не удалось загрузить профили для открытия чата';

  @override
  String get forward_error_send_no_permissions =>
      'Не удалось переслать: нет прав на выбранные чаты или чат больше недоступен.';

  @override
  String get forward_error_send_forbidden_chat =>
      'Не удалось переслать: доступ к одному из чатов запрещён.';

  @override
  String get devices_title => 'Мои устройства';

  @override
  String get devices_subtitle =>
      'Список устройств, на которых опубликован ваш публичный ключ шифрования. Отзыв автоматически создаёт новую эпоху ключей во всех зашифрованных чатах — отозванное устройство больше не увидит новые сообщения.';

  @override
  String get devices_empty => 'Устройств пока нет.';

  @override
  String devices_progress_rekeying(Object done, Object total) {
    return 'Обновление чатов: $done / $total';
  }

  @override
  String get devices_chip_current => 'Это устройство';

  @override
  String get devices_chip_revoked => 'Отозвано';

  @override
  String devices_meta_created_activity(Object createdAt, Object lastSeenAt) {
    return 'Создано: $createdAt  •  Активность: $lastSeenAt';
  }

  @override
  String devices_meta_revoked_at(Object revokedAt) {
    return 'Отозвано: $revokedAt';
  }

  @override
  String get devices_action_rename => 'Переименовать';

  @override
  String get devices_action_revoke => 'Отозвать';

  @override
  String get devices_dialog_rename_title => 'Переименовать устройство';

  @override
  String get devices_dialog_rename_hint => 'Например, iPhone 15 — Safari';

  @override
  String devices_error_rename_failed(Object error) {
    return 'Не удалось переименовать: $error';
  }

  @override
  String get devices_dialog_revoke_title => 'Отозвать устройство?';

  @override
  String get devices_dialog_revoke_body_current =>
      'Вы собираетесь отозвать ТЕКУЩЕЕ устройство. После этого вы не сможете читать новые сообщения в зашифрованных чатах с этого клиента.';

  @override
  String get devices_dialog_revoke_body_other =>
      'Устройство больше не сможет читать новые сообщения в зашифрованных чатах. Старые сообщения останутся доступны на нём.';

  @override
  String devices_snackbar_revoked(Object rekeyed, Object suffix) {
    return 'Устройство отозвано. Обновлено чатов: $rekeyed$suffix';
  }

  @override
  String devices_snackbar_failed_suffix(Object count) {
    return ', ошибок: $count';
  }

  @override
  String devices_error_revoke_failed(Object error) {
    return 'Ошибка revoke: $error';
  }

  @override
  String get e2ee_recovery_title => 'E2EE — резервирование';

  @override
  String get e2ee_password_label => 'Пароль';

  @override
  String get e2ee_password_confirm_label => 'Повторите пароль';

  @override
  String e2ee_password_min_length(Object count) {
    return 'Минимум $count символов';
  }

  @override
  String get e2ee_password_mismatch => 'Пароли не совпадают';

  @override
  String get e2ee_backup_create_title => 'Создать backup ключа';

  @override
  String get e2ee_backup_restore_title => 'Восстановить по паролю';

  @override
  String get e2ee_backup_restore_action => 'Восстановить';

  @override
  String e2ee_backup_create_error(Object error) {
    return 'Не удалось создать backup: $error';
  }

  @override
  String e2ee_backup_restore_error(Object error) {
    return 'Не удалось восстановить: $error';
  }

  @override
  String get e2ee_backup_wrong_password => 'Неверный пароль';

  @override
  String get e2ee_backup_not_found => 'Backup не найден';

  @override
  String e2ee_recovery_error_generic(Object error) {
    return 'Ошибка: $error';
  }

  @override
  String get e2ee_backup_password_card_title => 'Backup паролем';

  @override
  String get e2ee_backup_password_card_description =>
      'Создайте зашифрованный backup приватного ключа. Если потеряете все устройства, сможете восстановить его на новом, зная только пароль. Пароль нельзя восстановить — записывайте надёжно.';

  @override
  String get e2ee_backup_overwrite => 'Перезаписать backup';

  @override
  String get e2ee_backup_create => 'Создать backup';

  @override
  String get e2ee_backup_restore => 'Восстановить из backup';

  @override
  String get e2ee_backup_already_have => 'У меня уже есть backup';

  @override
  String get e2ee_qr_transfer_title => 'Передача ключа по QR';

  @override
  String get e2ee_qr_transfer_description =>
      'На новом устройстве показываем QR, на старом сканируем камерой. Сверяете 6-значный код — приватный ключ переносится безопасно.';

  @override
  String get e2ee_qr_transfer_open => 'Открыть QR-pairing';

  @override
  String get media_viewer_action_reply => 'Ответить';

  @override
  String get media_viewer_action_forward => 'Переслать';

  @override
  String get media_viewer_action_send => 'Отправить';

  @override
  String get media_viewer_action_save => 'Сохранить';

  @override
  String get media_viewer_action_show_in_chat => 'Показать в чате';

  @override
  String get media_viewer_action_delete => 'Удалить';

  @override
  String get media_viewer_error_no_gallery_access =>
      'Нет доступа к сохранению в галерею';

  @override
  String get media_viewer_error_share_unavailable_web =>
      'Шаринг недоступен в веб-версии';

  @override
  String media_viewer_error_save_failed(Object error) {
    return 'Не удалось сохранить: $error';
  }

  @override
  String media_viewer_error_send_failed(Object error) {
    return 'Не удалось отправить: $error';
  }

  @override
  String get media_viewer_video_playback_speed => 'Скорость воспроизведения';

  @override
  String get media_viewer_video_quality => 'Качество';

  @override
  String get media_viewer_error_quality_switch_failed =>
      'Не удалось переключить качество';

  @override
  String get media_viewer_error_pip_open_failed => 'Не удалось открыть PiP';

  @override
  String get media_viewer_pip_not_supported =>
      'Картинка в картинке не поддерживается на этом устройстве.';

  @override
  String get media_viewer_video_processing =>
      'Видео обрабатывается на сервере и скоро станет доступно.';

  @override
  String get media_viewer_video_playback_failed =>
      'Не удалось воспроизвести видео.';
}
