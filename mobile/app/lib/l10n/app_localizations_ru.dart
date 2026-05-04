// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get secret_chat_title => 'Секретный чат';

  @override
  String get secret_chats_title => 'Секретные чаты';

  @override
  String get secret_chat_locked_title => 'Секретный чат заблокирован';

  @override
  String get secret_chat_locked_subtitle =>
      'Введите PIN-код, чтобы открыть чат и посмотреть сообщения.';

  @override
  String get secret_chat_unlock_title => 'Открыть секретный чат';

  @override
  String get secret_chat_unlock_subtitle =>
      'Для открытия чата требуется PIN-код.';

  @override
  String get secret_chat_unlock_action => 'Открыть';

  @override
  String get secret_chat_set_pin_and_unlock => 'Установить PIN и открыть';

  @override
  String get secret_chat_pin_label => 'PIN-код (4 цифры)';

  @override
  String get secret_chat_pin_invalid => 'Введите 4 цифры';

  @override
  String get secret_chat_already_exists =>
      'Секретный чат с этим пользователем уже существует.';

  @override
  String get secret_chat_exists_badge => 'Создан';

  @override
  String get secret_chat_unlock_failed =>
      'Не удалось открыть. Попробуйте ещё раз.';

  @override
  String get secret_chat_action_not_allowed =>
      'Это действие запрещено в секретном чате';

  @override
  String get secret_chat_remember_pin => 'Запомнить PIN на этом устройстве';

  @override
  String get secret_chat_unlock_biometric => 'Открыть с помощью биометрии';

  @override
  String get secret_chat_biometric_reason => 'Открыть секретный чат';

  @override
  String get secret_chat_biometric_no_saved_pin =>
      'Введите PIN один раз, чтобы включить биометрию';

  @override
  String get secret_chat_ttl_title => 'Срок жизни секретного чата';

  @override
  String get secret_chat_settings_title => 'Настройки секретного чата';

  @override
  String get secret_chat_settings_subtitle =>
      'Срок жизни, доступ и ограничения';

  @override
  String get secret_chat_settings_not_secret =>
      'Этот чат не является секретным';

  @override
  String get secret_chat_settings_ttl => 'Срок жизни';

  @override
  String secret_chat_settings_time_left(Object value) {
    return 'Осталось: $value';
  }

  @override
  String secret_chat_settings_expires_at(Object iso) {
    return 'Истекает: $iso';
  }

  @override
  String get secret_chat_settings_unlock_grant_ttl => 'Длительность открытия';

  @override
  String get secret_chat_settings_unlock_grant_ttl_subtitle =>
      'Сколько действует доступ после открытия';

  @override
  String get secret_chat_settings_no_copy => 'Запретить копирование';

  @override
  String get secret_chat_settings_no_forward => 'Запретить пересылку';

  @override
  String get secret_chat_settings_no_save => 'Запретить сохранение медиа';

  @override
  String get secret_chat_settings_screenshot_protection =>
      'Защита от скриншотов (Android)';

  @override
  String get secret_chat_settings_media_views => 'Лимиты просмотров медиа';

  @override
  String get secret_chat_settings_media_views_subtitle =>
      'Best-effort лимиты просмотров у получателя';

  @override
  String get secret_chat_media_type_image => 'Изображения';

  @override
  String get secret_chat_media_type_video => 'Видео';

  @override
  String get secret_chat_media_type_voice => 'Голосовые';

  @override
  String get secret_chat_media_type_location => 'Локация';

  @override
  String get secret_chat_media_type_file => 'Файлы';

  @override
  String get secret_chat_media_views_unlimited => 'Безлимит';

  @override
  String get secret_chat_compose_create => 'Создать секретный чат';

  @override
  String get secret_chat_compose_vault_pin_subtitle =>
      'Необязательно: 4-цифровой PIN для доступа к списку секретных чатов (сохраняется на устройстве для биометрии).';

  @override
  String get secret_chat_compose_require_unlock_pin =>
      'Требовать PIN при открытии чата';

  @override
  String get secret_chat_settings_read_only_hint =>
      'Параметры задаются при создании и дальше не меняются.';

  @override
  String get secret_chat_settings_delete => 'Удалить секретный чат';

  @override
  String get secret_chat_settings_delete_confirm_title =>
      'Удалить этот секретный чат?';

  @override
  String get secret_chat_settings_delete_confirm_body =>
      'Сообщения и медиа будут удалены у обоих участников.';

  @override
  String get privacy_secret_vault_title => 'Секретное хранилище';

  @override
  String get privacy_secret_vault_subtitle =>
      'Глобальный PIN и биометрия для входа в секретные чаты.';

  @override
  String get privacy_secret_vault_change_pin =>
      'Установить или сменить PIN хранилища';

  @override
  String get privacy_secret_vault_change_pin_subtitle =>
      'Если PIN уже есть, подтвердите старым PIN или биометрией.';

  @override
  String get privacy_secret_vault_bio_subtitle =>
      'Проверить биометрию и валидировать локально сохраненный PIN.';

  @override
  String get privacy_secret_vault_bio_reason =>
      'Подтвердите доступ к секретным чатам';

  @override
  String get privacy_secret_vault_current_pin => 'Текущий PIN';

  @override
  String get privacy_secret_vault_new_pin => 'Новый PIN';

  @override
  String get privacy_secret_vault_repeat_pin => 'Повторите новый PIN';

  @override
  String get privacy_secret_vault_pin_mismatch => 'PIN-коды не совпадают';

  @override
  String get privacy_secret_vault_pin_updated => 'PIN хранилища обновлен';

  @override
  String get privacy_secret_vault_bio_unavailable =>
      'Биометрия недоступна на этом устройстве';

  @override
  String get privacy_secret_vault_bio_verified => 'Проверка биометрии пройдена';

  @override
  String get privacy_secret_vault_setup_required =>
      'Сначала настройте PIN или биометрию в разделе Конфиденциальность.';

  @override
  String get privacy_secret_vault_network_timeout =>
      'Таймаут сети. Попробуйте снова.';

  @override
  String privacy_secret_vault_error(Object error) {
    return 'Ошибка секретного хранилища: $error';
  }

  @override
  String get tournament_title => 'Турнир';

  @override
  String get tournament_subtitle => 'Турнирная таблица и серии партий';

  @override
  String get tournament_new_game => 'Новая партия';

  @override
  String get tournament_standings => 'Таблица';

  @override
  String get tournament_standings_empty => 'Пока нет результатов';

  @override
  String get tournament_games => 'Партии';

  @override
  String get tournament_games_empty => 'Пока нет партий';

  @override
  String tournament_points(Object pts) {
    return '$pts очков';
  }

  @override
  String tournament_games_played(Object n) {
    return '$n игр';
  }

  @override
  String tournament_create_failed(Object err) {
    return 'Не удалось создать турнир: $err';
  }

  @override
  String tournament_create_game_failed(Object err) {
    return 'Не удалось создать партию: $err';
  }

  @override
  String tournament_game_players(Object names) {
    return 'Игроки: $names';
  }

  @override
  String get tournament_game_result_draw => 'Результат: ничья';

  @override
  String tournament_game_result_loser(Object name) {
    return 'Результат: дурак — $name';
  }

  @override
  String tournament_game_place(Object place) {
    return 'Место $place';
  }

  @override
  String get durak_dm_lobby_banner =>
      'Собеседник создал лобби «Дурак» — присоединиться';

  @override
  String get durak_dm_lobby_open => 'Открыть лобби';

  @override
  String get conversation_game_lobby_cancel => 'Завершить ожидание';

  @override
  String conversation_game_lobby_cancel_failed(Object err) {
    return 'Не удалось завершить ожидание: $err';
  }

  @override
  String secret_chat_media_views_count(Object count) {
    return '$count просмотров';
  }

  @override
  String secret_chat_settings_load_failed(Object error) {
    return 'Не удалось загрузить: $error';
  }

  @override
  String secret_chat_settings_save_failed(Object error) {
    return 'Не удалось сохранить: $error';
  }

  @override
  String get secret_chat_settings_reset_strict => 'Сброс к строгим настройкам';

  @override
  String get secret_chat_settings_reset_strict_subtitle =>
      'Включит все запреты и установит лимит просмотров медиа = 1';

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
  String get account_menu_storage => 'Хранилище';

  @override
  String get account_menu_theme => 'Тема';

  @override
  String get account_menu_sign_out => 'Выйти';

  @override
  String get storage_settings_title => 'Хранилище';

  @override
  String get storage_settings_subtitle =>
      'Управляйте локальным кэшем на устройстве: что хранить, что чистить и сколько места выделять.';

  @override
  String get storage_settings_total_label => 'Занято на устройстве';

  @override
  String storage_settings_budget_label(Object mb) {
    return 'Целевой лимит кэша: $mb МБ';
  }

  @override
  String get storage_settings_clear_all_button => 'Очистить весь кэш';

  @override
  String get storage_settings_trim_button => 'Поджать до лимита';

  @override
  String get storage_settings_policy_title => 'Что хранить локально';

  @override
  String get storage_settings_budget_slider_title => 'Лимит кэша';

  @override
  String get storage_settings_breakdown_title => 'Разбивка по типам';

  @override
  String get storage_settings_breakdown_empty => 'Локальный кэш пока пуст.';

  @override
  String get storage_settings_chats_title => 'Разбивка по чатам';

  @override
  String get storage_settings_chats_empty =>
      'Пока нет кэша, привязанного к чатам.';

  @override
  String storage_settings_chat_subtitle(Object count, Object size) {
    return '$count элементов · $size';
  }

  @override
  String get storage_settings_general_title => 'Кэш без привязки к чату';

  @override
  String get storage_settings_general_hint =>
      'Записи, которые не удалось однозначно связать с конкретным чатом (legacy/глобальный кэш).';

  @override
  String get storage_settings_general_empty => 'Общий кэш пуст.';

  @override
  String get storage_settings_chat_files_empty =>
      'Локальных файлов для этого чата пока нет.';

  @override
  String get storage_settings_clear_chat_action => 'Очистить кэш чата';

  @override
  String get storage_settings_clear_all_title => 'Очистить локальный кэш?';

  @override
  String get storage_settings_clear_all_body =>
      'Будут удалены кэшированные файлы, превью, черновики и офлайн-снимки списка чатов на этом устройстве.';

  @override
  String storage_settings_clear_chat_title(Object chat) {
    return 'Очистить кэш «$chat»?';
  }

  @override
  String get storage_settings_clear_chat_body =>
      'Удалится только локальный кэш этого чата. Облачные сообщения не затрагиваются.';

  @override
  String get storage_settings_snackbar_cleared => 'Локальный кэш очищен';

  @override
  String get storage_settings_snackbar_budget_already_ok =>
      'Кэш уже укладывается в лимит';

  @override
  String storage_settings_snackbar_budget_trimmed(Object size) {
    return 'Освобождено: $size';
  }

  @override
  String get storage_settings_error_empty =>
      'Не удалось собрать статистику хранилища';

  @override
  String get storage_category_e2ee_media => 'E2EE медиа-кэш';

  @override
  String get storage_category_e2ee_media_subtitle =>
      'Расшифрованные медиа секретных чатов для быстрого повторного открытия.';

  @override
  String get storage_category_e2ee_text => 'E2EE текст-кэш';

  @override
  String get storage_category_e2ee_text_subtitle =>
      'Расшифрованный текст сообщений по чатам для мгновенного рендера.';

  @override
  String get storage_category_drafts => 'Черновики сообщений';

  @override
  String get storage_category_drafts_subtitle =>
      'Неотправленные черновики по чатам.';

  @override
  String get storage_category_chat_list_snapshot => 'Офлайн-список чатов';

  @override
  String get storage_category_chat_list_snapshot_subtitle =>
      'Последний снимок списка чатов для быстрого старта без сети.';

  @override
  String get storage_category_profile_cards => 'Мини-кэш профилей';

  @override
  String get storage_category_profile_cards_subtitle =>
      'Имена и аватары для ускорения интерфейса.';

  @override
  String get storage_category_video_downloads => 'Кэш загруженных видео';

  @override
  String get storage_category_video_downloads_subtitle =>
      'Локальные копии видео из просмотрщика медиа.';

  @override
  String get storage_category_video_thumbs => 'Превью-кадры видео';

  @override
  String get storage_category_video_thumbs_subtitle =>
      'Сгенерированные первые кадры для видео.';

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
  String get partner_profile_block_confirm_title =>
      'Заблокировать пользователя?';

  @override
  String get partner_profile_block_confirm_body =>
      'Он не увидит чат с вами, не сможет найти вас в поиске и добавить в контакты. У него вы пропадёте из контактов. Вы сохраните переписку, но не сможете писать ему, пока он в списке заблокированных.';

  @override
  String get partner_profile_block_action => 'Заблокировать';

  @override
  String get partner_profile_block_success => 'Пользователь заблокирован';

  @override
  String partner_profile_block_error(Object error) {
    return 'Не удалось заблокировать: $error';
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
  String get common_create => 'Создать';

  @override
  String get common_delete => 'Удалить';

  @override
  String get common_choose => 'Выбрать';

  @override
  String get common_save => 'Сохранить';

  @override
  String get common_close => 'Закрыть';

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
  String get profile_placeholder_username => 'username';

  @override
  String get profile_placeholder_email => 'name@example.com';

  @override
  String get profile_placeholder_phone => '+7900 000-00-00';

  @override
  String get profile_placeholder_birthdate => 'ДД.ММ.ГГГГ';

  @override
  String get profile_placeholder_password_dots => '••••••••';

  @override
  String get profile_password_error_fill_both =>
      'Заполните новый пароль и повтор.';

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
  String get chat_calls_title => 'Звонки';

  @override
  String get chat_calls_search_hint => 'Поиск по имени…';

  @override
  String get chat_calls_empty => 'История звонков пуста.';

  @override
  String get chat_calls_nothing_found => 'Ничего не найдено.';

  @override
  String chat_calls_error_load(Object error) {
    return 'Не удалось загрузить звонки:\n$error';
  }

  @override
  String get chat_reply_cancel_tooltip => 'Отменить ответ';

  @override
  String get voice_preview_tooltip_cancel => 'Отменить';

  @override
  String get voice_preview_tooltip_send => 'Отправить';

  @override
  String get profile_qr_title => 'Мой QR-код';

  @override
  String get profile_qr_tooltip_close => 'Закрыть';

  @override
  String get profile_qr_share_title => 'Мой профиль в LighChat';

  @override
  String get profile_qr_share_subject => 'Профиль LighChat';

  @override
  String chat_media_norm_pending_title(Object mediaKind) {
    return 'Обрабатываем $mediaKind…';
  }

  @override
  String chat_media_norm_failed_title(Object mediaKind) {
    return 'Не удалось обработать $mediaKind';
  }

  @override
  String get chat_media_norm_pending_subtitle =>
      'Файл станет доступен после серверной нормализации.';

  @override
  String get chat_media_norm_failed_subtitle =>
      'Попробуйте запустить обработку повторно.';

  @override
  String get conversation_threads_title => 'Обсуждения';

  @override
  String get conversation_threads_empty => 'Нет обсуждений';

  @override
  String get conversation_threads_root_attachment => 'Вложение';

  @override
  String get conversation_threads_root_message => 'Сообщение';

  @override
  String conversation_threads_snippet_you(Object text) {
    return 'Вы: $text';
  }

  @override
  String get conversation_threads_day_today => 'Сегодня';

  @override
  String get conversation_threads_day_yesterday => 'Вчера';

  @override
  String conversation_threads_replies_badge(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ответов',
      many: '$count ответов',
      few: '$count ответа',
      one: '$count ответ',
    );
    return '$_temp0';
  }

  @override
  String get chat_meetings_title => 'Видеовстречи';

  @override
  String get chat_meetings_subtitle =>
      'Создавайте конференции и управляйте доступом участников';

  @override
  String get chat_meetings_section_new => 'Новая встреча';

  @override
  String get chat_meetings_field_title_label => 'Название встречи';

  @override
  String get chat_meetings_field_title_hint => 'Напр. Обсуждение логистики';

  @override
  String get chat_meetings_field_duration_label => 'Длительность';

  @override
  String get chat_meetings_duration_unlimited => 'Без ограничения';

  @override
  String get chat_meetings_duration_15m => '15 минут';

  @override
  String get chat_meetings_duration_30m => '30 минут';

  @override
  String get chat_meetings_duration_1h => '1 час';

  @override
  String get chat_meetings_duration_90m => '1,5 часа';

  @override
  String get chat_meetings_field_access_label => 'Тип доступа';

  @override
  String get chat_meetings_access_private => 'Закрытая';

  @override
  String get chat_meetings_access_public => 'Открытая';

  @override
  String get chat_meetings_waiting_room_title => 'Зал ожидания';

  @override
  String get chat_meetings_waiting_room_desc =>
      'В режиме зала ожидания вы полностью контролируете список участников. Пока вы не нажмёте «Принять», гость будет видеть экран ожидания.';

  @override
  String get chat_meetings_backgrounds_title => 'Виртуальные фоны';

  @override
  String get chat_meetings_backgrounds_desc =>
      'Загружайте фоны и размывайте задний план при желании. Изображение из галереи. Также доступна загрузка собственных фонов.';

  @override
  String get chat_meetings_waiting_room_toggle => 'Добавить комнату ожидания';

  @override
  String get chat_meetings_waiting_room_toggle_subtitle =>
      'Только хозяин комнаты может дать разрешение на подключение и блокировать';

  @override
  String get chat_meetings_create_button => 'Создать встречу';

  @override
  String get chat_meetings_snackbar_enter_title => 'Укажите название встречи';

  @override
  String get chat_meetings_snackbar_auth_required =>
      'Нужна авторизация для создания встречи';

  @override
  String chat_meetings_error_create_failed(Object error) {
    return 'Не удалось создать встречу: $error';
  }

  @override
  String get chat_meetings_history_title => 'Ваша история';

  @override
  String get chat_meetings_history_empty => 'История встреч пуста';

  @override
  String chat_meetings_history_error(Object error) {
    return 'Не удалось загрузить историю встреч: $error';
  }

  @override
  String get chat_meetings_status_live => 'идёт';

  @override
  String get chat_meetings_status_finished => 'завершена';

  @override
  String get chat_meetings_badge_private => 'закрытая';

  @override
  String get chat_contacts_search_hint => 'Поиск контактов...';

  @override
  String get chat_contacts_permission_denied =>
      'Доступ к контактам не предоставлен.';

  @override
  String chat_contacts_sync_error(Object error) {
    return 'Ошибка синхронизации контактов: $error';
  }

  @override
  String chat_contacts_invite_prepare_failed(Object error) {
    return 'Не удалось подготовить приглашение: $error';
  }

  @override
  String get chat_contacts_matches_not_found => 'Совпадений не найдено.';

  @override
  String chat_contacts_added_count(Object count) {
    return 'Добавлено контактов: $count.';
  }

  @override
  String get chat_contacts_invite_text =>
      'Поставь LighChat: https://lighchat.online\nПриглашаю тебя в LighChat — вот ссылка на установку.';

  @override
  String get chat_contacts_invite_subject => 'Приглашение в LighChat';

  @override
  String chat_contacts_error_load(Object error) {
    return 'Ошибка загрузки контактов: $error';
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
  String get new_chat_fallback_user_display_name => 'Пользователь';

  @override
  String get new_group_role_badge_admin => 'АДМИН';

  @override
  String get new_group_role_badge_worker => 'СОТРУДНИК';

  @override
  String new_group_error_auth_session(Object error) {
    return 'Ошибка авторизации: $error';
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
  String get group_members_title => 'Участники';

  @override
  String get group_members_invite_link => 'Пригласить по ссылке';

  @override
  String get group_members_admin_badge => 'АДМИН';

  @override
  String group_members_invite_text(Object groupName, Object inviteLink) {
    return 'Присоединяйся к группе $groupName в LighChat: $inviteLink';
  }

  @override
  String get group_members_error_min_admin =>
      'В группе должен остаться хотя бы один администратор.';

  @override
  String get group_members_error_cannot_remove_creator =>
      'Нельзя снять права администратора с создателя группы.';

  @override
  String get group_members_remove_admin => 'Администратор снят';

  @override
  String get group_members_make_admin => 'Назначен администратор';

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
  String get voice_attachment_media_kind_audio => 'аудио';

  @override
  String get voice_attachment_load_failed => 'Не удалось загрузить';

  @override
  String get voice_attachment_title_voice_message => 'Голосовое сообщение';

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
  String get media_viewer_error_file_not_found => 'Файл не найден';

  @override
  String get media_viewer_error_bad_media_url => 'Неверная ссылка на медиа';

  @override
  String get media_viewer_error_bad_url => 'Неверная ссылка';

  @override
  String get media_viewer_error_unsupported_media_scheme =>
      'Неподдерживаемый тип медиа';

  @override
  String media_viewer_error_http_status(Object status) {
    return 'Ошибка сервера (HTTP $status)';
  }

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
  String get media_viewer_video_quality_auto => 'Авто';

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

  @override
  String get common_none => 'Нет';

  @override
  String get group_member_role_admin => 'Администратор';

  @override
  String get group_member_role_worker => 'Участник';

  @override
  String get profile_no_photo_to_view => 'Нет фото профиля для просмотра.';

  @override
  String get profile_chat_id_copied_toast => 'Идентификатор чата скопирован';

  @override
  String get auth_register_error_open_link => 'Не удалось открыть ссылку';

  @override
  String get new_chat_error_self_profile_not_found =>
      'Не найден профиль в каталоге. Попробуйте выйти и войти снова.';

  @override
  String get disappearing_messages_title => 'Исчезающие сообщения';

  @override
  String get disappearing_messages_intro =>
      'Новые сообщения автоматически удаляются из базы после выбранного времени (от момента отправки). Уже отправленные не меняются.';

  @override
  String disappearing_messages_admin_only(Object summary) {
    return 'Только администраторы группы могут менять этот параметр. Сейчас: $summary.';
  }

  @override
  String get disappearing_messages_snackbar_off =>
      'Исчезающие сообщения выключены.';

  @override
  String get disappearing_messages_snackbar_updated => 'Таймер обновлён.';

  @override
  String get disappearing_preset_off => 'Выключено';

  @override
  String get disappearing_preset_1h => '1 ч';

  @override
  String get disappearing_preset_24h => '24 ч';

  @override
  String get disappearing_preset_7d => '7 дн.';

  @override
  String get disappearing_preset_30d => '30 дн.';

  @override
  String get disappearing_ttl_summary_off => 'Выкл';

  @override
  String disappearing_ttl_minutes(Object count) {
    return '$count мин';
  }

  @override
  String disappearing_ttl_hours(Object count) {
    return '$count ч';
  }

  @override
  String disappearing_ttl_days(Object count) {
    return '$count дн.';
  }

  @override
  String disappearing_ttl_weeks(Object count) {
    return '$count нед.';
  }

  @override
  String get conversation_profile_e2ee_on => 'Вкл';

  @override
  String get conversation_profile_e2ee_off => 'Выкл';

  @override
  String get conversation_profile_e2ee_subtitle_on =>
      'Сквозное шифрование включено. Нажмите для подробностей.';

  @override
  String get conversation_profile_e2ee_subtitle_off =>
      'Сквозное шифрование выключено. Нажмите, чтобы включить.';

  @override
  String get partner_profile_title_fallback_group => 'Групповой чат';

  @override
  String get partner_profile_title_fallback_saved => 'Избранное';

  @override
  String get partner_profile_title_fallback_chat => 'Чат';

  @override
  String partner_profile_subtitle_group_member_count(Object count) {
    return '$count участников';
  }

  @override
  String get partner_profile_subtitle_saved_messages =>
      'Сообщения и заметки только для вас';

  @override
  String get partner_profile_error_cannot_contact_user =>
      'С этим пользователем нельзя связаться.';

  @override
  String partner_profile_error_open_chat(Object error) {
    return 'Не удалось открыть чат: $error';
  }

  @override
  String get partner_profile_call_peer_fallback => 'Собеседник';

  @override
  String get partner_profile_chat_not_created => 'Чат ещё не создан';

  @override
  String get partner_profile_notifications_muted => 'Уведомления отключены';

  @override
  String get partner_profile_notifications_unmuted => 'Уведомления включены';

  @override
  String get partner_profile_notifications_change_failed =>
      'Не удалось изменить уведомления';

  @override
  String get partner_profile_removed_from_contacts => 'Удалено из контактов';

  @override
  String get partner_profile_remove_contact_failed =>
      'Не удалось удалить из контактов';

  @override
  String get partner_profile_contact_sent => 'Контакт отправлен';

  @override
  String get partner_profile_share_failed_copied =>
      'Не удалось открыть шаринг. Текст контакта скопирован.';

  @override
  String get partner_profile_share_contact_header => 'Контакт в LighChat';

  @override
  String partner_profile_share_avatar_line(Object url) {
    return 'Аватар: $url';
  }

  @override
  String partner_profile_share_profile_line(Object url) {
    return 'Профиль: $url';
  }

  @override
  String partner_profile_share_contact_subject(Object name) {
    return 'Контакт LighChat: $name';
  }

  @override
  String get partner_profile_tooltip_back => 'Назад';

  @override
  String get partner_profile_tooltip_close => 'Закрыть';

  @override
  String get partner_profile_edit_contact_short => 'Изм.';

  @override
  String get partner_profile_tooltip_copy_chat_id => 'Скопировать ID чата';

  @override
  String get partner_profile_action_chats => 'Чаты';

  @override
  String get partner_profile_action_voice_call => 'Звонок';

  @override
  String get partner_profile_action_video => 'Видео';

  @override
  String get partner_profile_action_share => 'Поделиться';

  @override
  String get partner_profile_action_notifications => 'Уведомления';

  @override
  String get partner_profile_menu_members => 'Участники';

  @override
  String get partner_profile_menu_edit_group => 'Редактировать группу';

  @override
  String get partner_profile_menu_media_links_files => 'Медиа, ссылки и файлы';

  @override
  String get partner_profile_menu_starred => 'Избранное';

  @override
  String get partner_profile_menu_threads => 'Обсуждения';

  @override
  String get partner_profile_menu_games => 'Игры';

  @override
  String get partner_profile_menu_block => 'Заблокировать';

  @override
  String get partner_profile_menu_unblock => 'Разблокировать';

  @override
  String get partner_profile_menu_notifications => 'Уведомления';

  @override
  String get partner_profile_menu_chat_theme => 'Тема чата';

  @override
  String get partner_profile_menu_advanced_privacy =>
      'Расширенная приватность чата';

  @override
  String get partner_profile_privacy_trailing_default => 'По умолчанию';

  @override
  String get partner_profile_menu_encryption => 'Шифрование';

  @override
  String get partner_profile_no_common_groups => 'НЕТ ОБЩИХ ГРУПП';

  @override
  String partner_profile_create_group_with(Object name) {
    return 'Создать группу с $name';
  }

  @override
  String get partner_profile_leave_group => 'Покинуть группу';

  @override
  String get partner_profile_contacts_and_data => 'Контакты и данные';

  @override
  String get partner_profile_field_system_role => 'Роль в системе';

  @override
  String get partner_profile_field_email => 'Электронная почта';

  @override
  String get partner_profile_field_phone => 'Телефон';

  @override
  String get partner_profile_field_birthday => 'День рождения';

  @override
  String get partner_profile_field_bio => 'О себе';

  @override
  String get partner_profile_add_to_contacts => 'Добавить в контакты';

  @override
  String get partner_profile_remove_from_contacts => 'Удалить из контактов';

  @override
  String get thread_search_hint => 'Поиск в обсуждении…';

  @override
  String get thread_search_tooltip_clear => 'Очистить';

  @override
  String get thread_search_tooltip_search => 'Поиск';

  @override
  String thread_reply_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ответов',
      many: '$count ответов',
      few: '$count ответа',
      one: '$count ответ',
    );
    return '$_temp0';
  }

  @override
  String get thread_message_not_found => 'Сообщение не найдено';

  @override
  String get thread_screen_title_fallback => 'Обсуждение';

  @override
  String thread_load_replies_error(Object error) {
    return 'Ошибка ветки: $error';
  }

  @override
  String get chat_message_empty_placeholder => 'Сообщение';

  @override
  String get chat_sender_you => 'Вы';

  @override
  String get chat_clipboard_nothing_to_paste => 'Нечего вставлять из буфера';

  @override
  String chat_clipboard_paste_failed(Object error) {
    return 'Не удалось вставить содержимое буфера: $error';
  }

  @override
  String chat_send_failed(Object error) {
    return 'Не удалось отправить: $error';
  }

  @override
  String chat_send_video_circle_failed(Object error) {
    return 'Не удалось отправить кружок: $error';
  }

  @override
  String get chat_service_unavailable => 'Сервис недоступен';

  @override
  String get chat_repository_unavailable => 'Сервис чата недоступен';

  @override
  String get chat_still_loading => 'Чат ещё загружается';

  @override
  String get chat_no_participants => 'Нет участников чата';

  @override
  String get chat_location_ios_geolocator_missing =>
      'Геолокация не подключена в iOS-сборке. В каталоге mobile/app/ios выполните pod install и пересоберите приложение.';

  @override
  String get chat_location_services_disabled => 'Включите службу геолокации';

  @override
  String get chat_location_permission_denied => 'Нет доступа к геолокации';

  @override
  String chat_location_send_failed(Object error) {
    return 'Не удалось отправить геолокацию: $error';
  }

  @override
  String get chat_poll_send_timeout => 'Опрос не отправлен: таймаут';

  @override
  String chat_poll_send_firebase(Object details) {
    return 'Опрос не отправлен (Firestore): $details';
  }

  @override
  String chat_poll_send_known_error(Object details) {
    return 'Опрос не отправлен: $details';
  }

  @override
  String chat_poll_send_failed(Object error) {
    return 'Не удалось отправить опрос: $error';
  }

  @override
  String chat_delete_action_failed(Object error) {
    return 'Не удалось удалить: $error';
  }

  @override
  String get chat_media_transcode_retry_started =>
      'Повторная обработка запущена';

  @override
  String chat_media_transcode_retry_failed(Object error) {
    return 'Не удалось запустить обработку: $error';
  }

  @override
  String chat_parent_load_error(Object error) {
    return 'Ошибка: $error';
  }

  @override
  String get chat_message_not_found_in_loaded_history =>
      'Сообщение не найдено в загруженной истории';

  @override
  String get chat_finish_editing_first => 'Сначала завершите редактирование';

  @override
  String chat_send_voice_failed(Object error) {
    return 'Не удалось отправить голосовое: $error';
  }

  @override
  String get chat_starred_removed => 'Удалено из избранного';

  @override
  String get chat_starred_added => 'Добавлено в избранное';

  @override
  String chat_starred_toggle_failed(Object error) {
    return 'Не удалось изменить избранное: $error';
  }

  @override
  String chat_reaction_toggle_failed(Object error) {
    return 'Не удалось поставить реакцию: $error';
  }

  @override
  String chat_emoji_burst_sync_failed(Object error) {
    return 'Не удалось синхронизировать эффект эмодзи: $error';
  }

  @override
  String get chat_pin_already_pinned => 'Сообщение уже закреплено';

  @override
  String chat_pin_limit_reached(int count) {
    return 'Лимит закреплённых ($count)';
  }

  @override
  String chat_pin_failed(Object error) {
    return 'Не удалось закрепить: $error';
  }

  @override
  String chat_unpin_failed(Object error) {
    return 'Не удалось открепить: $error';
  }

  @override
  String get chat_text_copied => 'Текст скопирован';

  @override
  String get chat_edit_attachments_not_allowed =>
      'При редактировании вложения недоступны';

  @override
  String get chat_edit_text_empty => 'Текст не может быть пустым';

  @override
  String chat_e2ee_unavailable(Object code) {
    return 'Шифрование недоступно: $code';
  }

  @override
  String chat_save_failed(Object error) {
    return 'Не удалось сохранить: $error';
  }

  @override
  String chat_load_messages_error(Object error) {
    return 'Ошибка загрузки сообщений: $error';
  }

  @override
  String chat_conversation_error(Object error) {
    return 'Conversation error: $error';
  }

  @override
  String chat_auth_error(Object error) {
    return 'Ошибка авторизации: $error';
  }

  @override
  String get chat_poll_label => 'Опрос';

  @override
  String get chat_location_label => 'Локация';

  @override
  String get chat_attachment_label => 'Вложение';

  @override
  String chat_media_pick_failed(Object error) {
    return 'Не удалось выбрать медиа: $error';
  }

  @override
  String chat_file_pick_failed(Object error) {
    return 'Не удалось выбрать файл: $error';
  }

  @override
  String get chat_call_ongoing_video => 'Идёт видеозвонок';

  @override
  String get chat_call_ongoing_audio => 'Идёт аудиозвонок';

  @override
  String get chat_call_incoming_video => 'Входящий видеозвонок';

  @override
  String get chat_call_incoming_audio => 'Входящий аудиозвонок';

  @override
  String get message_menu_action_reply => 'Ответить';

  @override
  String get message_menu_action_thread => 'Обсудить';

  @override
  String get message_menu_action_copy => 'Копировать';

  @override
  String get message_menu_action_edit => 'Изменить';

  @override
  String get message_menu_action_pin => 'Закрепить';

  @override
  String get message_menu_action_star_add => 'Добавить в избранное';

  @override
  String get message_menu_action_star_remove => 'Убрать из избранного';

  @override
  String get message_menu_action_forward => 'Переслать';

  @override
  String get message_menu_action_select => 'Выбрать';

  @override
  String get message_menu_action_delete => 'Удалить';

  @override
  String get message_menu_initiator_deleted => 'Сообщение удалено';

  @override
  String get message_menu_header_sent => 'ОТПРАВЛЕНО:';

  @override
  String get message_menu_header_read => 'ПРОЧИТАНО:';

  @override
  String get message_menu_header_expire_at => 'ИСЧЕЗНЕТ:';

  @override
  String get chat_header_search_hint => 'Поиск сообщений…';

  @override
  String get chat_header_tooltip_threads => 'Обсуждения';

  @override
  String get chat_header_tooltip_search => 'Поиск';

  @override
  String get chat_header_tooltip_video_call => 'Видеозвонок';

  @override
  String get chat_header_tooltip_audio_call => 'Аудиозвонок';

  @override
  String get conversation_games_title => 'Игры';

  @override
  String get conversation_games_durak => 'Дурак';

  @override
  String get conversation_games_durak_subtitle => 'Создать лобби';

  @override
  String get conversation_game_lobby_title => 'Лобби';

  @override
  String get conversation_game_lobby_not_found => 'Игра не найдена';

  @override
  String conversation_game_lobby_error(Object error) {
    return 'Ошибка: $error';
  }

  @override
  String conversation_game_lobby_create_failed(Object error) {
    return 'Не удалось создать игру: $error';
  }

  @override
  String conversation_game_lobby_game_id(Object id) {
    return 'ID: $id';
  }

  @override
  String conversation_game_lobby_status(Object status) {
    return 'Статус: $status';
  }

  @override
  String conversation_game_lobby_players(Object count, Object max) {
    return 'Игроки: $count/$max';
  }

  @override
  String get conversation_game_lobby_join => 'Войти';

  @override
  String get conversation_game_lobby_start => 'Начать';

  @override
  String get conversation_game_lobby_ready => 'Готов';

  @override
  String get conversation_game_lobby_waiting => 'Ждём…';

  @override
  String get conversation_game_lobby_start_game => 'Начать игру';

  @override
  String get conversation_durak_play_again => 'Сыграть ещё раз';

  @override
  String get conversation_durak_back_to_chat => 'Вернуться в чат';

  @override
  String get conversation_game_lobby_waiting_opponent => 'Ждём, пока подключится соперник…';

  @override
  String get conversation_durak_winner => 'Победитель';

  @override
  String conversation_durak_loser(Object name) {
    return 'Проиграл: $name';
  }

  @override
  String conversation_game_lobby_join_failed(Object error) {
    return 'Не удалось войти: $error';
  }

  @override
  String conversation_game_lobby_start_failed(Object error) {
    return 'Не удалось начать игру: $error';
  }

  @override
  String get conversation_game_send_test_move => 'Тестовый ход';

  @override
  String conversation_game_move_failed(Object error) {
    return 'Ход не принят: $error';
  }

  @override
  String get conversation_durak_table_title => 'Стол';

  @override
  String get conversation_durak_hand_title => 'Рука';

  @override
  String get conversation_durak_role_attacker => 'Атакуете';

  @override
  String get conversation_durak_role_defender => 'Защищаетесь';

  @override
  String get conversation_durak_role_thrower => 'Подкидываете';

  @override
  String get conversation_durak_action_attack => 'Атаковать';

  @override
  String get conversation_durak_action_defend => 'Отбить';

  @override
  String get conversation_durak_action_take => 'Взять';

  @override
  String get conversation_durak_action_beat => 'Бито';

  @override
  String get conversation_durak_action_transfer => 'Перевести';

  @override
  String get conversation_durak_action_pass => 'Пас';

  @override
  String get conversation_durak_badge_taking => 'Беру';

  @override
  String get conversation_durak_game_finished_title => 'Игра завершена';

  @override
  String get conversation_durak_game_finished_no_loser =>
      'В этот раз без проигравшего.';

  @override
  String conversation_durak_game_finished_loser(Object uid) {
    return 'Проиграл: $uid';
  }

  @override
  String conversation_durak_game_finished_winners(Object uids) {
    return 'Победили: $uids';
  }

  @override
  String get conversation_durak_drop_zone =>
      'Перетащи карту сюда, чтобы сыграть';

  @override
  String get durak_settings_mode => 'Режим';

  @override
  String get durak_mode_podkidnoy => 'Подкидной';

  @override
  String get durak_mode_perevodnoy => 'Переводной';

  @override
  String get durak_settings_max_players => 'Игроков';

  @override
  String get durak_settings_deck => 'Колода';

  @override
  String get durak_deck_36 => '36 карт';

  @override
  String get durak_deck_52 => '52 карты';

  @override
  String get durak_settings_with_jokers => 'Джокеры';

  @override
  String get durak_settings_turn_timer => 'Таймер хода';

  @override
  String get durak_turn_timer_off => 'Выкл';

  @override
  String get durak_settings_throw_in_policy => 'Кто может подкидывать';

  @override
  String get durak_throw_in_policy_all => 'Все (кроме защитника)';

  @override
  String get durak_throw_in_policy_neighbors => 'Только соседи защитника';

  @override
  String get durak_settings_shuler => 'Режим шулера';

  @override
  String get durak_settings_shuler_subtitle =>
      'Разрешает нелегальные ходы, пока кто-то не крикнет «Фолл!»';

  @override
  String get conversation_durak_action_foul => 'Фолл!';

  @override
  String get conversation_durak_action_resolve => 'Подтвердить «Бито»';

  @override
  String get conversation_durak_foul_toast => 'Фолл! Шулер наказан.';

  @override
  String get durak_phase_prefix => 'Фаза';

  @override
  String get durak_phase_attack => 'Атака';

  @override
  String get durak_phase_defense => 'Защита';

  @override
  String get durak_phase_throw_in => 'Подкид';

  @override
  String get durak_phase_resolution => 'Розыгрыш';

  @override
  String get durak_phase_finished => 'Завершено';

  @override
  String get durak_phase_pending_foul => 'Ожидание фолла после «Бито»';

  @override
  String get durak_phase_pending_foul_hint_attacker =>
      'Ждём фолл. Если никто не нажмёт — подтверди «Бито».';

  @override
  String get durak_phase_pending_foul_hint_other =>
      'Ждём фолл. Нажми «Фолл!», если заметил шулерство.';

  @override
  String get durak_phase_hint_can_throw_in => 'Можно подкидывать';

  @override
  String get durak_phase_hint_wait => 'Ждите свой ход';

  @override
  String durak_now_throwing_in(Object name) {
    return 'Сейчас подкидывает: $name';
  }

  @override
  String chat_selection_selected_count(int count) {
    return '$count выбрано';
  }

  @override
  String get chat_selection_tooltip_forward => 'Переслать';

  @override
  String get chat_selection_tooltip_delete => 'Удалить';

  @override
  String get chat_composer_hint_message => 'Введите сообщение…';

  @override
  String get chat_composer_tooltip_stickers => 'Стикеры';

  @override
  String get chat_composer_tooltip_attachments => 'Вложения';

  @override
  String get chat_list_unread_separator => 'Непрочитанные сообщения';

  @override
  String get chat_e2ee_decrypt_failed_open_devices =>
      'Не удалось расшифровать. Откройте Настройки → Устройства';

  @override
  String get chat_e2ee_encrypted_message_placeholder =>
      'Зашифрованное сообщение';

  @override
  String chat_forwarded_from(Object name) {
    return 'Переслано от $name';
  }

  @override
  String get chat_outbox_retry => 'Повторить';

  @override
  String get chat_outbox_remove => 'Убрать';

  @override
  String get chat_outbox_cancel => 'Отменить';

  @override
  String get chat_message_edited_badge_short => 'изм.';

  @override
  String get register_error_enter_name => 'Введите имя.';

  @override
  String get register_error_enter_username => 'Введите логин.';

  @override
  String get register_error_enter_phone => 'Введите номер телефона.';

  @override
  String get register_error_invalid_phone =>
      'Введите корректный номер телефона.';

  @override
  String get register_error_enter_email => 'Введите email.';

  @override
  String get register_error_enter_password => 'Введите пароль.';

  @override
  String get register_error_repeat_password => 'Повторите пароль.';

  @override
  String get register_error_dob_format =>
      'Укажите дату рождения в формате дд.мм.гггг';

  @override
  String get register_error_accept_privacy_policy =>
      'Подтвердите согласие с политикой конфиденциальности';

  @override
  String get register_privacy_required =>
      'Требуется согласие с политикой конфиденциальности';

  @override
  String get register_label_name => 'Имя';

  @override
  String get register_hint_name => 'Введите имя';

  @override
  String get register_label_username => 'Логин';

  @override
  String get register_hint_username => 'Введите логин';

  @override
  String get register_label_phone => 'Телефон';

  @override
  String get register_hint_choose_country => 'Выберите страну';

  @override
  String get register_label_email => 'Email';

  @override
  String get register_hint_email => 'Введите email';

  @override
  String get register_label_password => 'Пароль';

  @override
  String get register_hint_password => 'Введите пароль';

  @override
  String get register_label_confirm_password => 'Повтор пароля';

  @override
  String get register_hint_confirm_password => 'Повторите пароль';

  @override
  String get register_label_dob => 'Дата рождения';

  @override
  String get register_hint_dob => 'дд.мм.гггг';

  @override
  String get register_label_bio => 'О себе';

  @override
  String get register_hint_bio => 'Расскажите о себе...';

  @override
  String get register_privacy_prefix => 'Я принимаю ';

  @override
  String get register_privacy_link_text =>
      'Согласия на обработку персональных данных';

  @override
  String get register_privacy_and => ' и ';

  @override
  String get register_terms_link_text =>
      'Пользовательское соглашение политики конфиденциальности';

  @override
  String get register_button_create_account => 'Создать аккаунт';

  @override
  String get register_country_search_hint => 'Поиск страны или кода';

  @override
  String get register_date_picker_help => 'Дата рождения';

  @override
  String get register_date_picker_cancel => 'Отмена';

  @override
  String get register_date_picker_confirm => 'Выбрать';

  @override
  String get register_pick_avatar_title => 'Выбрать аватар';

  @override
  String get edit_group_title => 'Редактировать группу';

  @override
  String get edit_group_save => 'Сохранить';

  @override
  String get edit_group_cancel => 'Отмена';

  @override
  String get edit_group_name_label => 'Название группы';

  @override
  String get edit_group_name_hint => 'Название';

  @override
  String get edit_group_description_label => 'Описание';

  @override
  String get edit_group_description_hint => 'Необязательно';

  @override
  String get edit_group_pick_photo_tooltip =>
      'Нажмите, чтобы выбрать фото группы. Удерживайте, чтобы убрать.';

  @override
  String get edit_group_error_name_required =>
      'Пожалуйста, введите название группы.';

  @override
  String get edit_group_error_save_failed => 'Ошибка при сохранении группы';

  @override
  String get edit_group_error_not_found => 'Группа не найдена';

  @override
  String get edit_group_error_permission_denied =>
      'У вас нет прав для редактирования этой группы';

  @override
  String get edit_group_success => 'Группа обновлена';

  @override
  String get edit_group_privacy_section => 'КОНФИДЕНЦИАЛЬНОСТЬ';

  @override
  String get edit_group_privacy_forwarding => 'Пересылка сообщений';

  @override
  String get edit_group_privacy_forwarding_desc =>
      'Разрешить участникам пересылать сообщения из этой группы.';

  @override
  String get edit_group_privacy_screenshots => 'Скриншоты';

  @override
  String get edit_group_privacy_screenshots_desc =>
      'Разрешить скриншоты внутри группы (ограничение зависит от платформы).';

  @override
  String get edit_group_privacy_copy => 'Копирование текста';

  @override
  String get edit_group_privacy_copy_desc =>
      'Разрешить копирование текста сообщений.';

  @override
  String get edit_group_privacy_save_media => 'Сохранение медиа';

  @override
  String get edit_group_privacy_save_media_desc =>
      'Разрешить сохранять фото и видео на устройство.';

  @override
  String get edit_group_privacy_share_media => 'Поделиться медиа';

  @override
  String get edit_group_privacy_share_media_desc =>
      'Разрешить делиться медиафайлами вне приложения.';
}
