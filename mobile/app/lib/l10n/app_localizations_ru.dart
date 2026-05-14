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
  String get account_menu_features => 'Возможности';

  @override
  String get account_menu_chat_settings => 'Настройки чатов';

  @override
  String get account_menu_notifications => 'Уведомления';

  @override
  String get account_menu_privacy => 'Конфиденциальность';

  @override
  String get account_menu_devices => 'Устройства';

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
  String storage_settings_budget_label(Object gb) {
    return 'Лимит кэша: $gb ГБ';
  }

  @override
  String get storage_unit_gb => 'ГБ';

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
  String get storage_category_chat_images => 'Фото в чатах';

  @override
  String get storage_category_chat_images_subtitle =>
      'Кэшированные фотографии и стикеры из открытых чатов.';

  @override
  String get storage_category_stickers_gifs_emoji => 'Стикеры, GIF, эмодзи';

  @override
  String get storage_category_stickers_gifs_emoji_subtitle =>
      'Кэш недавних стикеров, GIPHY (gifs/stickers/emoji) и анимированных эмодзи.';

  @override
  String get storage_category_network_images => 'Кэш сетевых картинок';

  @override
  String get storage_category_network_images_subtitle =>
      'Аватары, превью и прочие изображения, скачанные из сети (libCachedImageData).';

  @override
  String get storage_media_type_video => 'Видео';

  @override
  String get storage_media_type_photo => 'Фотографии';

  @override
  String get storage_media_type_audio => 'Аудио';

  @override
  String get storage_media_type_files => 'Файлы';

  @override
  String get storage_media_type_other => 'Другое';

  @override
  String storage_settings_device_usage(Object pct) {
    return 'Занимает $pct% от лимита кэша';
  }

  @override
  String get storage_settings_clear_all_hint =>
      'Все медиа останутся в облаке. При необходимости вы сможете загрузить их снова.';

  @override
  String get storage_settings_categories_title => 'По категориям';

  @override
  String storage_settings_clear_category_title(String category) {
    return 'Очистить «$category»?';
  }

  @override
  String storage_settings_clear_category_body(String size) {
    return 'Будет освобождено около $size. Действие нельзя отменить.';
  }

  @override
  String get storage_auto_delete_title => 'Автоудаление кэшированных медиа';

  @override
  String get storage_auto_delete_personal => 'Личные чаты';

  @override
  String get storage_auto_delete_groups => 'Группы';

  @override
  String get storage_auto_delete_never => 'Никогда';

  @override
  String get storage_auto_delete_3_days => '3 дня';

  @override
  String get storage_auto_delete_1_week => '1 нед.';

  @override
  String get storage_auto_delete_1_month => '1 месяц';

  @override
  String get storage_auto_delete_3_months => '3 месяца';

  @override
  String get storage_auto_delete_hint =>
      'Фотографии, видео и другие файлы, которые вы не открывали в течение этого срока, будут удалены с устройства для экономии места.';

  @override
  String storage_chat_detail_share(Object pct) {
    return 'На этот чат приходится $pct% кэша';
  }

  @override
  String get storage_chat_detail_media_tab => 'Медиа';

  @override
  String get storage_chat_detail_select_all => 'Выбрать все';

  @override
  String get storage_chat_detail_deselect_all => 'Снять все';

  @override
  String storage_chat_detail_clear_button(Object size) {
    return 'Очистить кэш $size';
  }

  @override
  String get storage_chat_detail_clear_button_empty =>
      'Выберите файлы для удаления';

  @override
  String get storage_chat_detail_tab_empty => 'В этой вкладке ничего нет.';

  @override
  String get storage_chat_detail_delete_title => 'Удалить выбранные файлы?';

  @override
  String storage_chat_detail_delete_body(Object count, Object size) {
    return '$count файлов ($size) будет удалено с устройства. Облачные копии не затрагиваются.';
  }

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
  String get privacy_title => 'Приватность чата';

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
  String get chat_list_create_folder_name_hint => 'Название папки';

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
  String get auth_entry_sign_in => 'Войти';

  @override
  String get auth_entry_sign_up => 'Создать аккаунт';

  @override
  String get auth_qr_title => 'Войти по QR';

  @override
  String get auth_qr_hint =>
      'Откройте LighChat на устройстве, где вы уже вошли → Настройки → Устройства → Подключить новое устройство, и наведите камеру на этот код.';

  @override
  String auth_qr_refresh_in(int seconds) {
    return 'Обновится через $secondsс';
  }

  @override
  String get auth_qr_other_method => 'Войти другим способом';

  @override
  String get auth_qr_approving => 'Входим…';

  @override
  String get auth_qr_rejected => 'Запрос отклонён';

  @override
  String get auth_qr_retry => 'Повторить';

  @override
  String get auth_qr_unknown_error => 'Не удалось сгенерировать QR-код.';

  @override
  String get auth_qr_use_qr_login => 'Войти по QR';

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
  String get voice_transcript_retry => 'Повторить транскрибацию';

  @override
  String get voice_transcript_summary_show => 'Показать резюме';

  @override
  String get voice_transcript_summary_hide => 'Показать полный текст';

  @override
  String voice_transcript_stats(int words, int wpm) {
    return '$words слов · $wpm сл/мин';
  }

  @override
  String get voice_attachment_skip_silence => 'Пропускать тишину';

  @override
  String get voice_karaoke_title => 'Караоке';

  @override
  String get voice_karaoke_prompt_title => 'Режим караоке';

  @override
  String get voice_karaoke_prompt_body =>
      'Открыть голосовое сообщение в полноэкранном режиме с подсветкой слов?';

  @override
  String get voice_karaoke_prompt_open => 'Открыть';

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
  String get voice_transcript_permission_denied =>
      'Распознавание речи запрещено. Включите его в системных настройках.';

  @override
  String get voice_transcript_unsupported_lang =>
      'Этот язык не поддерживается локальным распознаванием на устройстве.';

  @override
  String get voice_transcript_no_model =>
      'Установите офлайн-пакет распознавания речи в системных настройках.';

  @override
  String get voice_translate_action => 'Перевести';

  @override
  String get voice_translate_show_original => 'Оригинал';

  @override
  String get voice_translate_in_progress => 'Перевожу…';

  @override
  String get voice_translate_downloading_model => 'Скачиваю модель…';

  @override
  String get voice_translate_unsupported =>
      'Перевод недоступен для этой языковой пары.';

  @override
  String voice_translate_failed(Object error) {
    return 'Не удалось перевести: $error';
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
  String get share_picker_title => 'Поделиться в LighChat';

  @override
  String get share_picker_empty_payload => 'Нет содержимого для отправки';

  @override
  String get share_picker_summary_text_only => 'Текст';

  @override
  String share_picker_summary_files_count(int count) {
    return 'Файлов: $count';
  }

  @override
  String share_picker_summary_files_with_text(int count) {
    return 'Файлов: $count + текст';
  }

  @override
  String get devices_title => 'Мои устройства';

  @override
  String get devices_subtitle =>
      'Список устройств, на которых опубликован ваш публичный ключ шифрования. Отзыв автоматически создаёт новую эпоху ключей во всех зашифрованных чатах — отозванное устройство больше не увидит новые сообщения.';

  @override
  String get devices_empty => 'Устройств пока нет.';

  @override
  String get devices_connect_new_device => 'Подключить новое устройство';

  @override
  String get devices_approve_title => 'Разрешить вход на этом устройстве?';

  @override
  String get devices_approve_body_hint =>
      'Убедитесь, что это ваше устройство, на котором вы только что показали QR.';

  @override
  String get devices_approve_allow => 'Разрешить';

  @override
  String get devices_approve_deny => 'Отклонить';

  @override
  String get devices_handover_progress_title =>
      'Синхронизация зашифрованных чатов…';

  @override
  String devices_handover_progress_body(int done, int total) {
    return 'Обработано $done из $total';
  }

  @override
  String get devices_handover_progress_starting => 'Начинаем…';

  @override
  String get devices_handover_success_title => 'Устройство подключено';

  @override
  String devices_handover_success_body(String label) {
    return 'Устройство $label получило доступ к зашифрованным чатам.';
  }

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
  String get message_menu_action_translate => 'Перевести';

  @override
  String get message_menu_action_show_original => 'Показать оригинал';

  @override
  String get message_menu_action_edit => 'Изменить';

  @override
  String get message_menu_action_pin => 'Закрепить';

  @override
  String get message_menu_action_star_add => 'Добавить в избранное';

  @override
  String get message_menu_action_star_remove => 'Убрать из избранного';

  @override
  String get message_menu_action_create_sticker => 'Создать стикер';

  @override
  String get message_menu_action_save_to_my_stickers =>
      'Добавить в мои стикеры';

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
  String get conversation_durak_winner => 'Победитель!';

  @override
  String get conversation_durak_play_again => 'Сыграть ещё раз';

  @override
  String get conversation_durak_back_to_chat => 'Вернуться в чат';

  @override
  String get conversation_game_lobby_waiting_opponent => 'Ожидание соперника…';

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

  @override
  String get schedule_message_sheet_title => 'Запланировать сообщение';

  @override
  String get schedule_message_long_press_hint => 'Запланировать отправку';

  @override
  String schedule_message_preset_today_at(String time) {
    return 'Сегодня в $time';
  }

  @override
  String schedule_message_preset_tomorrow_at(String time) {
    return 'Завтра в $time';
  }

  @override
  String schedule_message_will_send_at(String datetime) {
    return 'Будет отправлено: $datetime';
  }

  @override
  String get schedule_message_must_be_in_future =>
      'Время должно быть в будущем (минимум через минуту).';

  @override
  String get schedule_message_e2ee_warning =>
      'Это E2EE-чат. Отложенное сообщение будет сохранено в открытом виде на сервере и опубликовано без шифрования.';

  @override
  String get schedule_message_cancel => 'Отмена';

  @override
  String get schedule_message_confirm => 'Запланировать';

  @override
  String get schedule_message_save => 'Сохранить';

  @override
  String get schedule_message_text_required => 'Сначала введите текст';

  @override
  String get schedule_message_attachments_unsupported_mobile =>
      'Планирование вложений пока поддерживается только в веб-клиенте';

  @override
  String schedule_message_scheduled_toast(String datetime) {
    return 'Запланировано: $datetime';
  }

  @override
  String schedule_message_failed_toast(String error) {
    return 'Не удалось запланировать: $error';
  }

  @override
  String get scheduled_messages_screen_title => 'Запланированные сообщения';

  @override
  String get scheduled_messages_empty_title => 'Нет запланированных сообщений';

  @override
  String get scheduled_messages_empty_hint =>
      'Удерживайте кнопку «Отправить», чтобы запланировать.';

  @override
  String scheduled_messages_load_failed(String error) {
    return 'Не удалось загрузить: $error';
  }

  @override
  String get scheduled_messages_e2ee_notice =>
      'В E2EE-чате запланированные сообщения хранятся и публикуются в открытом виде.';

  @override
  String get scheduled_messages_cancel_dialog_title => 'Отменить отправку?';

  @override
  String get scheduled_messages_cancel_dialog_body =>
      'Запланированное сообщение будет удалено.';

  @override
  String get scheduled_messages_cancel_dialog_keep => 'Не отменять';

  @override
  String get scheduled_messages_cancel_dialog_confirm => 'Отменить';

  @override
  String get scheduled_messages_canceled_toast => 'Отменено';

  @override
  String scheduled_messages_time_changed_toast(String datetime) {
    return 'Время изменено: $datetime';
  }

  @override
  String scheduled_messages_action_failed_toast(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get scheduled_messages_tile_edit_tooltip => 'Изменить время';

  @override
  String get scheduled_messages_tile_cancel_tooltip => 'Отменить';

  @override
  String scheduled_messages_preview_poll(String question) {
    return 'Опрос: $question';
  }

  @override
  String get scheduled_messages_preview_location => 'Локация';

  @override
  String get scheduled_messages_preview_attachment => 'Вложение';

  @override
  String scheduled_messages_preview_attachment_count(int count) {
    return 'Вложение (×$count)';
  }

  @override
  String get scheduled_messages_preview_message => 'Сообщение';

  @override
  String get chat_header_tooltip_scheduled => 'Запланированные сообщения';

  @override
  String get schedule_date_label => 'Дата';

  @override
  String get schedule_time_label => 'Время';

  @override
  String get common_done => 'Готово';

  @override
  String get common_send => 'Отправить';

  @override
  String get common_open => 'Открыть';

  @override
  String get common_add => 'Добавить';

  @override
  String get common_search => 'Поиск';

  @override
  String get common_edit => 'Редактировать';

  @override
  String get common_next => 'Далее';

  @override
  String get common_ok => 'OK';

  @override
  String get common_confirm => 'Подтвердить';

  @override
  String get common_ready => 'Готово';

  @override
  String get common_error => 'Ошибка';

  @override
  String get common_yes => 'Да';

  @override
  String get common_no => 'Нет';

  @override
  String get common_back => 'Назад';

  @override
  String get common_continue => 'Продолжить';

  @override
  String get common_loading => 'Загрузка…';

  @override
  String get common_copy => 'Скопировать';

  @override
  String get common_share => 'Поделиться';

  @override
  String get common_settings => 'Настройки';

  @override
  String get common_today => 'Сегодня';

  @override
  String get common_yesterday => 'Вчера';

  @override
  String get e2ee_qr_title => 'QR-pairing ключа';

  @override
  String get e2ee_qr_uid_error => 'Не удалось получить uid пользователя.';

  @override
  String get e2ee_qr_session_ended_error =>
      'Сессия завершилась до ответа от второго устройства.';

  @override
  String get e2ee_qr_no_data_error => 'Нет данных для применения ключа.';

  @override
  String get e2ee_qr_key_transferred_toast =>
      'Ключ перенесён. Перезайдите в чаты, чтобы обновить сессии.';

  @override
  String get e2ee_qr_wrong_account_error =>
      'QR сгенерирован под другой аккаунт.';

  @override
  String get e2ee_qr_explainer_title => 'Что это';

  @override
  String get e2ee_qr_explainer_text =>
      'Передача приватного ключа с одного вашего устройства на другое по ECDH + QR. Обе стороны видят 6-значный код для ручной сверки.';

  @override
  String get e2ee_qr_show_qr_label => 'Я на новом устройстве — показать QR';

  @override
  String get e2ee_qr_scan_qr_label => 'У меня уже есть ключ — сканировать QR';

  @override
  String get e2ee_qr_scan_hint =>
      'Отсканируйте QR на старом устройстве, где уже есть ключ.';

  @override
  String get e2ee_qr_verify_code_label =>
      'Сверьте 6-значный код со старым устройством:';

  @override
  String e2ee_qr_transfer_from_device_label(String label) {
    return 'Перенос с устройства: $label';
  }

  @override
  String get e2ee_qr_code_match_apply_label => 'Код совпал — применить';

  @override
  String get e2ee_qr_key_success_label =>
      'Ключ успешно перенесён на это устройство. Перезайдите в чаты.';

  @override
  String get e2ee_qr_unknown_error => 'Неизвестная ошибка';

  @override
  String get e2ee_qr_back_to_pick_label => 'К выбору';

  @override
  String get e2ee_qr_donor_scan_hint =>
      'Наведите камеру на QR, показанный на новом устройстве.';

  @override
  String get e2ee_qr_donor_verify_code_label =>
      'Сверьте код с новым устройством:';

  @override
  String get e2ee_qr_donor_verify_hint =>
      'Если код совпадает — подтвердите на новом устройстве. Если нет, немедленно нажмите «Отмена».';

  @override
  String get e2ee_encrypt_title => 'Шифрование';

  @override
  String get e2ee_encrypt_enable_dialog_title => 'Включить шифрование?';

  @override
  String get e2ee_encrypt_enable_dialog_body =>
      'Новые сообщения будут доступны только на ваших устройствах и у собеседника. Старые сообщения останутся как есть.';

  @override
  String get e2ee_encrypt_enable_label => 'Включить';

  @override
  String get e2ee_encrypt_disable_dialog_title => 'Отключить шифрование?';

  @override
  String get e2ee_encrypt_disable_dialog_body =>
      'Новые сообщения пойдут без сквозного шифрования. Ранее отправленные зашифрованные сообщения останутся в ленте.';

  @override
  String get e2ee_encrypt_disable_label => 'Отключить';

  @override
  String get e2ee_encrypt_status_on =>
      'Сквозное шифрование включено для этого чата.';

  @override
  String get e2ee_encrypt_status_off => 'Сквозное шифрование выключено.';

  @override
  String get e2ee_encrypt_description =>
      'Когда шифрование включено, содержимое новых сообщений доступно только участникам чата на их устройствах. Отключение влияет только на новые сообщения.';

  @override
  String get e2ee_encrypt_switch_title => 'Включить шифрование';

  @override
  String e2ee_encrypt_switch_on(int epoch) {
    return 'Включено (эпоха ключа: $epoch)';
  }

  @override
  String get e2ee_encrypt_switch_off => 'Выключено';

  @override
  String get e2ee_encrypt_already_on_toast =>
      'Шифрование уже включено или не удалось создать ключи. Проверьте сеть и наличие ключей у собеседника.';

  @override
  String get e2ee_encrypt_no_device_toast =>
      'Не удалось включить: у собеседника нет активного устройства с ключом.';

  @override
  String e2ee_encrypt_enable_failed_toast(String error) {
    return 'Не удалось включить шифрование: $error';
  }

  @override
  String e2ee_encrypt_disable_failed_toast(String error) {
    return 'Не удалось отключить: $error';
  }

  @override
  String get e2ee_encrypt_data_types_title => 'Типы данных';

  @override
  String get e2ee_encrypt_data_types_description =>
      'Настройка не меняет протокол. Она управляет тем, какие типы данных отправлять в зашифрованном виде.';

  @override
  String get e2ee_encrypt_override_title =>
      'Настройки шифрования для этого чата';

  @override
  String get e2ee_encrypt_override_on => 'Используются чатовые настройки.';

  @override
  String get e2ee_encrypt_override_off => 'Наследуются глобальные настройки.';

  @override
  String get e2ee_encrypt_text_title => 'Текст сообщений';

  @override
  String get e2ee_encrypt_media_title => 'Вложения (медиа/файлы)';

  @override
  String get e2ee_encrypt_override_hint =>
      'Чтобы изменить для этого чата — включите «Переопределить».';

  @override
  String get sticker_default_pack_name => 'Мой пак';

  @override
  String get sticker_new_pack_dialog_title => 'Новый стикерпак';

  @override
  String get sticker_pack_name_hint => 'Название';

  @override
  String get sticker_save_to_pack => 'Сохранить в стикерпак';

  @override
  String get sticker_no_packs_hint =>
      'Нет паков. Создайте пак на вкладке «Стикеры».';

  @override
  String get sticker_new_pack_option => 'Новый пак…';

  @override
  String get sticker_pick_image_or_gif => 'Выберите изображение или GIF';

  @override
  String sticker_send_failed(String error) {
    return 'Не удалось отправить: $error';
  }

  @override
  String get sticker_saved_to_pack => 'Сохранено в стикерпак';

  @override
  String get sticker_save_gif_failed => 'Не удалось скачать или сохранить GIF';

  @override
  String get sticker_delete_pack_title => 'Удалить пак?';

  @override
  String sticker_delete_pack_body(String name) {
    return '«$name» и все стикеры в нём будут удалены.';
  }

  @override
  String get sticker_pack_deleted => 'Пак удалён';

  @override
  String get sticker_pack_delete_failed => 'Не удалось удалить пак';

  @override
  String get sticker_tab_emoji => 'ЭМОДЗИ';

  @override
  String get sticker_tab_stickers => 'СТИКЕРЫ';

  @override
  String get sticker_tab_gif => 'GIF';

  @override
  String get sticker_scope_my => 'Мои';

  @override
  String get sticker_scope_public => 'Общие';

  @override
  String get sticker_new_pack_tooltip => 'Новый пак';

  @override
  String get sticker_pack_created => 'Стикерпак создан';

  @override
  String get sticker_no_packs_create => 'Нет стикерпаков. Создайте новый.';

  @override
  String get sticker_public_packs_empty => 'Общие паки не настроены';

  @override
  String get sticker_section_recent => 'НЕДАВНИЕ';

  @override
  String get sticker_pack_empty_hint =>
      'Пак пуст. Добавьте с устройства (вкладка GIF — «В мой пак»).';

  @override
  String get sticker_delete_sticker_title => 'Удалить стикер?';

  @override
  String get sticker_deleted => 'Удалено';

  @override
  String get sticker_gallery => 'Галерея';

  @override
  String get sticker_gallery_subtitle =>
      'Фото, PNG, GIF с устройства — сразу в чат';

  @override
  String get gif_search_hint => 'Поиск GIF…';

  @override
  String gif_translated_hint(String query) {
    return 'Искали: $query';
  }

  @override
  String get gif_search_unavailable => 'Поиск GIF временно недоступен.';

  @override
  String get gif_filter_all => 'Все';

  @override
  String get sticker_section_animated => 'АНИМИРОВАННЫЕ';

  @override
  String get sticker_emoji_unavailable =>
      'Эмодзи в текст недоступны для этого окна.';

  @override
  String get sticker_create_pack_hint => 'Создайте пак кнопкой +';

  @override
  String get sticker_public_packs_unavailable => 'Общие паки пока недоступны';

  @override
  String get composer_link_title => 'Ссылка';

  @override
  String get composer_link_apply => 'Применить';

  @override
  String get composer_attach_title => 'Прикрепить';

  @override
  String get composer_attach_photo_video => 'Фото/Видео';

  @override
  String get composer_attach_files => 'Файлы';

  @override
  String get composer_attach_video_circle => 'Кружок';

  @override
  String get composer_attach_location => 'Локация';

  @override
  String get composer_attach_poll => 'Опрос';

  @override
  String get composer_attach_stickers => 'Стикеры';

  @override
  String get composer_attach_clipboard => 'Буфер';

  @override
  String get composer_attach_text => 'Текст';

  @override
  String get meeting_create_poll => 'Создать опрос';

  @override
  String get meeting_min_two_options => 'Минимум 2 варианта ответа';

  @override
  String meeting_error_with_details(String details) {
    return 'Ошибка: $details';
  }

  @override
  String meeting_polls_load_error(String details) {
    return 'Не удалось загрузить опросы: $details';
  }

  @override
  String get meeting_no_polls_yet => 'Пока нет опросов';

  @override
  String get meeting_question_label => 'Вопрос';

  @override
  String get meeting_options_label => 'Варианты';

  @override
  String meeting_option_hint(int index) {
    return 'Вариант $index';
  }

  @override
  String get meeting_add_option => 'Добавить вариант';

  @override
  String get meeting_anonymous => 'Анонимно';

  @override
  String get meeting_anonymous_subtitle => 'Кто увидит выбор других';

  @override
  String get meeting_save_as_draft => 'В черновики';

  @override
  String get meeting_publish => 'Опубликовать';

  @override
  String get meeting_action_start => 'Запустить';

  @override
  String get meeting_action_change_vote => 'Изменить голос';

  @override
  String get meeting_action_restart => 'Перезапустить';

  @override
  String get meeting_action_stop => 'Остановить';

  @override
  String meeting_vote_failed(String details) {
    return 'Голос не засчитан: $details';
  }

  @override
  String get meeting_status_ended => 'Завершено';

  @override
  String get meeting_status_draft => 'Черновик';

  @override
  String get meeting_status_active => 'Активно';

  @override
  String get meeting_status_public => 'Публичное';

  @override
  String meeting_votes_count(int count) {
    return '$count голосов';
  }

  @override
  String meeting_goal_count(int count) {
    return 'Цель: $count';
  }

  @override
  String get meeting_hide => 'Скрыть';

  @override
  String get meeting_who_voted => 'Кто голосовал';

  @override
  String meeting_participants_tab(int count) {
    return 'Участники ($count)';
  }

  @override
  String meeting_polls_tab_active(int count) {
    return 'Опросы ($count)';
  }

  @override
  String get meeting_polls_tab => 'Опросы';

  @override
  String meeting_chat_tab_unread(int count) {
    return 'Чат ($count)';
  }

  @override
  String get meeting_chat_tab => 'Чат';

  @override
  String meeting_requests_tab(int count) {
    return 'Заявки ($count)';
  }

  @override
  String meeting_you_suffix(String name) {
    return '$name (Вы)';
  }

  @override
  String get meeting_host_label => 'Хост';

  @override
  String get meeting_force_mute_mic => 'Выключить микрофон';

  @override
  String get meeting_force_mute_camera => 'Выключить камеру';

  @override
  String get meeting_kick_from_room => 'Удалить из комнаты';

  @override
  String meeting_chat_load_error(Object error) {
    return 'Не удалось загрузить чат: $error';
  }

  @override
  String get meeting_no_requests => 'Нет новых заявок';

  @override
  String get meeting_no_messages_yet => 'Пока нет сообщений';

  @override
  String meeting_file_too_large(String name) {
    return 'Файл слишком большой: $name';
  }

  @override
  String meeting_send_failed(String details) {
    return 'Не удалось отправить: $details';
  }

  @override
  String get meeting_edit_message_title => 'Изменить сообщение';

  @override
  String meeting_save_failed(String details) {
    return 'Не удалось сохранить: $details';
  }

  @override
  String get meeting_delete_message_title => 'Удалить сообщение?';

  @override
  String get meeting_delete_message_body =>
      'Участники увидят «Сообщение удалено».';

  @override
  String meeting_delete_failed(String details) {
    return 'Не удалось удалить: $details';
  }

  @override
  String get meeting_message_hint => 'Сообщение…';

  @override
  String get meeting_message_deleted => 'Сообщение удалено';

  @override
  String get meeting_message_edited => '• изм.';

  @override
  String get meeting_copy_action => 'Копировать';

  @override
  String get meeting_edit_action => 'Изменить';

  @override
  String get meeting_join_title => 'Присоединиться';

  @override
  String meeting_loading_error(String details) {
    return 'Ошибка загрузки митинга: $details';
  }

  @override
  String get meeting_not_found => 'Митинг не найден или закрыт';

  @override
  String get meeting_private_description =>
      'Приватная встреча: после заявки хост решит, пустить ли вас.';

  @override
  String get meeting_public_description =>
      'Открытая встреча: присоединяйтесь по ссылке без ожидания.';

  @override
  String get meeting_your_name_label => 'Ваше имя';

  @override
  String get meeting_enter_name_error => 'Укажите имя';

  @override
  String get meeting_guest_name => 'Гость';

  @override
  String get meeting_enter_room => 'Войти в комнату';

  @override
  String get meeting_request_join => 'Попросить присоединиться';

  @override
  String get meeting_approved_title => 'Одобрено';

  @override
  String get meeting_approved_subtitle => 'Перенаправляем в комнату…';

  @override
  String get meeting_denied_title => 'Отклонено';

  @override
  String get meeting_denied_subtitle => 'Хост отклонил вашу заявку.';

  @override
  String get meeting_pending_title => 'Ожидаем подтверждения';

  @override
  String get meeting_pending_subtitle =>
      'Хост увидит вашу заявку и решит, когда впустить.';

  @override
  String meeting_load_error(String details) {
    return 'Не удалось загрузить митинг: $details';
  }

  @override
  String meeting_init_error(Object error) {
    return 'Ошибка инициализации: $error';
  }

  @override
  String meeting_participants_error(Object error) {
    return 'Участники: $error';
  }

  @override
  String meeting_bg_unavailable(Object error) {
    return 'Фон недоступен: $error';
  }

  @override
  String get meeting_leave => 'Выйти';

  @override
  String get meeting_screen_share_ios =>
      'Демонстрация экрана на iOS требует Broadcast Extension (будет в следующем релизе)';

  @override
  String meeting_screen_share_failed(String details) {
    return 'Не удалось запустить демонстрацию: $details';
  }

  @override
  String get meeting_tooltip_speaker_mode => 'Режим спикера';

  @override
  String get meeting_tooltip_grid_mode => 'Режим сетки';

  @override
  String get meeting_tooltip_copy_link =>
      'Скопировать ссылку (вход с браузера)';

  @override
  String get meeting_mic_on => 'Включить';

  @override
  String get meeting_mic_off => 'Выключить';

  @override
  String get meeting_camera_on => 'Камера вкл';

  @override
  String get meeting_camera_off => 'Камера выкл';

  @override
  String get meeting_switch_camera => 'Сменить';

  @override
  String get meeting_hand_lower => 'Опустить';

  @override
  String get meeting_hand_raise => 'Рука';

  @override
  String get meeting_reaction => 'Реакция';

  @override
  String get meeting_screen_stop => 'Стоп';

  @override
  String get meeting_screen_label => 'Экран';

  @override
  String get meeting_bg_off => 'Фон';

  @override
  String get meeting_bg_blur => 'Размытие';

  @override
  String get meeting_bg_image => 'Картинка';

  @override
  String get meeting_participants_button => 'Участники';

  @override
  String get meeting_notifications_button => 'Активность';

  @override
  String get meeting_pip_button => 'Свернуть';

  @override
  String get settings_chats_bottom_nav_icons_title => 'Иконки нижнего меню';

  @override
  String get settings_chats_bottom_nav_icons_subtitle =>
      'Выбор иконок и визуального стиля как на вебе.';

  @override
  String get settings_chats_nav_colorful => 'Цветные';

  @override
  String get settings_chats_nav_minimal => 'Минимализм';

  @override
  String get settings_chats_nav_global_title => 'Для всех иконок';

  @override
  String get settings_chats_nav_global_subtitle =>
      'Общий слой: цвет, размер, толщина и фон плитки.';

  @override
  String get settings_chats_reset_tooltip => 'Сброс';

  @override
  String get settings_chats_collapse => 'Скрыть';

  @override
  String get settings_chats_customize => 'Настроить';

  @override
  String get settings_chats_reset_item_tooltip => 'Сбросить';

  @override
  String get settings_chats_style_tooltip => 'Стиль';

  @override
  String get settings_chats_icon_size => 'Размер иконки';

  @override
  String get settings_chats_stroke_width => 'Толщина линии';

  @override
  String get settings_chats_default => 'По умолчанию';

  @override
  String get settings_chats_icon_search_hint_en =>
      'Поиск по названию (англ.)...';

  @override
  String get settings_chats_emoji_effects => 'Эффекты эмодзи';

  @override
  String get settings_chats_emoji_effects_subtitle =>
      'Профиль анимации fullscreen-эмодзи при тапе по одиночному эмодзи в чате.';

  @override
  String get settings_chats_emoji_lite_desc =>
      'Lite: минимум нагрузки и максимально плавно на слабых устройствах.';

  @override
  String get settings_chats_emoji_balanced_desc =>
      'Balanced: автоматический компромисс между производительностью и выразительностью.';

  @override
  String get settings_chats_emoji_cinematic_desc =>
      'Cinematic: максимум частиц и глубины для вау-эффекта.';

  @override
  String get settings_chats_preview_incoming_msg => 'Привет! Как дела?';

  @override
  String get settings_chats_preview_outgoing_msg => 'Отлично, спасибо!';

  @override
  String get settings_chats_preview_hello => 'Привет';

  @override
  String get chat_theme_title => 'Тема чата';

  @override
  String chat_theme_error_save(String error) {
    return 'Не удалось сохранить фон: $error';
  }

  @override
  String chat_theme_error_upload(String error) {
    return 'Ошибка загрузки фона: $error';
  }

  @override
  String get chat_theme_delete_title => 'Удалить фон из галереи?';

  @override
  String get chat_theme_delete_body =>
      'Изображение пропадёт из списка своих фонов. Для этого чата можно выбрать другой.';

  @override
  String chat_theme_error_delete(String error) {
    return 'Ошибка удаления: $error';
  }

  @override
  String get chat_theme_banner =>
      'Фон этой переписки только для вас. Общие настройки чатов в разделе «Настройки чатов» не меняются.';

  @override
  String get chat_theme_current_bg => 'Текущий фон';

  @override
  String get chat_theme_default_global => 'По умолчанию (общие настройки)';

  @override
  String get chat_theme_presets => 'Пресеты';

  @override
  String get chat_theme_global_tile => 'Общие';

  @override
  String get chat_theme_pick_hint => 'Выберите пресет или фото из галереи';

  @override
  String get contacts_title => 'Контакты';

  @override
  String get contacts_add_phone_prompt =>
      'Добавьте телефон в профиле, чтобы искать контакты по номеру.';

  @override
  String get contacts_fallback_profile => 'Профиль';

  @override
  String get contacts_fallback_user => 'Пользователь';

  @override
  String get contacts_status_online => 'онлайн';

  @override
  String get contacts_status_recently => 'Был (а) недавно';

  @override
  String contacts_status_today_at(String time) {
    return 'Был (а) в $time';
  }

  @override
  String get contacts_status_yesterday => 'Был (а) вчера';

  @override
  String get contacts_status_year_ago => 'Был (а) год назад';

  @override
  String contacts_status_years_ago(String years) {
    return 'Был (а) $years назад';
  }

  @override
  String contacts_status_date(String date) {
    return 'Был (а) $date';
  }

  @override
  String get contacts_empty_state =>
      'Контакты не найдены.\nНажмите кнопку справа, чтобы синхронизировать телефонную книгу.';

  @override
  String get add_contact_title => 'Новый контакт';

  @override
  String get add_contact_sync_off => 'Синхронизация выключена в приложении.';

  @override
  String get add_contact_enable_system_access =>
      'Включите доступ к контактам для LighChat в настройках системы.';

  @override
  String get add_contact_sync_on => 'Синхронизация включена';

  @override
  String get add_contact_sync_failed =>
      'Не удалось включить синхронизацию контактов';

  @override
  String get add_contact_invalid_phone => 'Введите корректный номер телефона';

  @override
  String get add_contact_not_found_by_phone =>
      'Контакт по этому номеру не найден';

  @override
  String get add_contact_found => 'Контакт найден';

  @override
  String add_contact_search_error(String error) {
    return 'Не удалось выполнить поиск: $error';
  }

  @override
  String get add_contact_qr_no_profile => 'QR-код не содержит профиль LighChat';

  @override
  String get add_contact_qr_own_profile => 'Это ваш собственный профиль';

  @override
  String get add_contact_qr_profile_not_found => 'Профиль из QR-кода не найден';

  @override
  String get add_contact_qr_found => 'Контакт найден по QR-коду';

  @override
  String add_contact_qr_read_error(String error) {
    return 'Не удалось прочитать QR-код: $error';
  }

  @override
  String get add_contact_cannot_add_user =>
      'Нельзя добавить этого пользователя';

  @override
  String add_contact_add_error(String error) {
    return 'Не удалось добавить контакт: $error';
  }

  @override
  String get add_contact_country_search_hint => 'Поиск страны или кода';

  @override
  String get add_contact_sync_with_phone => 'Синхронизировать с телефоном';

  @override
  String get add_contact_add_by_qr => 'Добавить по QR-коду';

  @override
  String get add_contact_results_unavailable => 'Результаты пока недоступны';

  @override
  String add_contact_profile_load_error(String error) {
    return 'Ошибка загрузки контакта: $error';
  }

  @override
  String get add_contact_profile_not_found => 'Профиль не найден';

  @override
  String get add_contact_badge_already_added => 'Уже в контактах';

  @override
  String get add_contact_badge_new => 'Новый контакт';

  @override
  String get add_contact_badge_unavailable => 'Недоступно';

  @override
  String get add_contact_open_contact => 'Открыть контакт';

  @override
  String get add_contact_add_to_contacts => 'Добавить в контакты';

  @override
  String get add_contact_add_unavailable => 'Добавление недоступно';

  @override
  String get add_contact_searching => 'Ищем контакт...';

  @override
  String get add_contact_scan_qr_title => 'Сканировать QR-код';

  @override
  String get add_contact_flash_tooltip => 'Вспышка';

  @override
  String get add_contact_scan_qr_hint =>
      'Наведите камеру на QR-код профиля LighChat';

  @override
  String get contacts_edit_enter_name => 'Введите имя контакта.';

  @override
  String contacts_edit_save_error(String error) {
    return 'Не удалось сохранить контакт: $error';
  }

  @override
  String get contacts_edit_first_name_hint => 'Имя';

  @override
  String get contacts_edit_last_name_hint => 'Фамилия';

  @override
  String get contacts_edit_name_disclaimer =>
      'Это имя видно только вам: в чатах, поиске и списке контактов.';

  @override
  String contacts_edit_error(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get chat_settings_color_default => 'По умолчанию';

  @override
  String get chat_settings_color_lilac => 'Лиловый';

  @override
  String get chat_settings_color_pink => 'Розовый';

  @override
  String get chat_settings_color_green => 'Зелёный';

  @override
  String get chat_settings_color_coral => 'Коралловый';

  @override
  String get chat_settings_color_mint => 'Мята';

  @override
  String get chat_settings_color_sky => 'Небесный';

  @override
  String get chat_settings_color_purple => 'Фиолетовый';

  @override
  String get chat_settings_color_crimson => 'Малиновый';

  @override
  String get chat_settings_color_tiffany => 'Тифани';

  @override
  String get chat_settings_color_yellow => 'Жёлтый';

  @override
  String get chat_settings_color_powder => 'Пудра';

  @override
  String get chat_settings_color_turquoise => 'Бирюза';

  @override
  String get chat_settings_color_blue => 'Голубой';

  @override
  String get chat_settings_color_sunset => 'Закат';

  @override
  String get chat_settings_color_tender => 'Нежный';

  @override
  String get chat_settings_color_lime => 'Лайм';

  @override
  String get chat_settings_color_graphite => 'Графит';

  @override
  String get chat_settings_color_no_bg => 'Без фона';

  @override
  String get chat_settings_icon_color => 'Цвет иконки';

  @override
  String get chat_settings_icon_size => 'Размер иконки';

  @override
  String get chat_settings_stroke_width => 'Толщина линии';

  @override
  String get chat_settings_tile_background => 'Фон плитки под иконкой';

  @override
  String get chat_settings_bottom_nav_icons => 'Иконки нижнего меню';

  @override
  String get chat_settings_bottom_nav_description =>
      'Выбор иконок и визуального стиля как на вебе.';

  @override
  String get chat_settings_bottom_nav_global_description =>
      'Общий слой: цвет, размер, толщина и фон плитки.';

  @override
  String get chat_settings_colorful => 'Цветные';

  @override
  String get chat_settings_minimalism => 'Минимализм';

  @override
  String get chat_settings_for_all_icons => 'Для всех иконок';

  @override
  String get chat_settings_customize => 'Настроить';

  @override
  String get chat_settings_hide => 'Скрыть';

  @override
  String get chat_settings_reset => 'Сброс';

  @override
  String get chat_settings_reset_item => 'Сбросить';

  @override
  String get chat_settings_style => 'Стиль';

  @override
  String get chat_settings_select => 'Выбрать';

  @override
  String get chat_settings_reset_size => 'Сбросить размер';

  @override
  String get chat_settings_reset_stroke => 'Сбросить толщину';

  @override
  String get chat_settings_default_gradient => 'Градиент по умолчанию';

  @override
  String get chat_settings_inherit_global => 'Наследовать от глобальных';

  @override
  String get chat_settings_no_bg_on => 'Без фона (вкл.)';

  @override
  String get chat_settings_no_bg => 'Без фона';

  @override
  String get chat_settings_outgoing_messages => 'Исходящие сообщения';

  @override
  String get chat_settings_incoming_messages => 'Входящие сообщения';

  @override
  String get chat_settings_font_size => 'Размер шрифта';

  @override
  String get chat_settings_font_small => 'Мелкий';

  @override
  String get chat_settings_font_medium => 'Средний';

  @override
  String get chat_settings_font_large => 'Крупный';

  @override
  String get chat_settings_bubble_shape => 'Форма пузырьков';

  @override
  String get chat_settings_bubble_rounded => 'Округлённые';

  @override
  String get chat_settings_bubble_square => 'Квадратные';

  @override
  String get chat_settings_chat_background => 'Фон чата';

  @override
  String get chat_settings_background_hint =>
      'Выберите фото из галереи или настройте';

  @override
  String get chat_settings_builtin_wallpapers_heading => 'Фирменные обои';

  @override
  String get chat_settings_emoji_effects => 'Эффекты эмодзи';

  @override
  String get chat_settings_emoji_description =>
      'Профиль анимации fullscreen-эмодзи при тапе по одиночному эмодзи в чате.';

  @override
  String get chat_settings_emoji_lite =>
      'Lite: минимум нагрузки и максимально плавно на слабых устройствах.';

  @override
  String get chat_settings_emoji_cinematic =>
      'Cinematic: максимум частиц и глубины для вау-эффекта.';

  @override
  String get chat_settings_emoji_balanced =>
      'Balanced: автоматический компромисс между производительностью и выразительностью.';

  @override
  String get chat_settings_additional => 'Дополнительно';

  @override
  String get chat_settings_show_time => 'Показывать время';

  @override
  String get chat_settings_show_time_hint => 'Время отправки под сообщениями';

  @override
  String get chat_settings_reset_all => 'Сбросить настройки';

  @override
  String get chat_settings_preview_incoming => 'Привет! Как дела?';

  @override
  String get chat_settings_preview_outgoing => 'Отлично, спасибо!';

  @override
  String get chat_settings_preview_hello => 'Привет';

  @override
  String chat_settings_icon_picker_title(String label) {
    return 'Иконка: «$label»';
  }

  @override
  String get chat_settings_search_hint => 'Поиск по названию (англ.)...';

  @override
  String meeting_tab_participants(Object count) {
    return 'Участники ($count)';
  }

  @override
  String get meeting_tab_polls => 'Опросы';

  @override
  String meeting_tab_polls_count(Object count) {
    return 'Опросы ($count)';
  }

  @override
  String get meeting_tab_chat => 'Чат';

  @override
  String meeting_tab_chat_count(Object count) {
    return 'Чат ($count)';
  }

  @override
  String meeting_tab_requests(Object count) {
    return 'Заявки ($count)';
  }

  @override
  String get meeting_kick => 'Удалить из комнаты';

  @override
  String meeting_file_too_big(Object name) {
    return 'Файл слишком большой: $name';
  }

  @override
  String meeting_send_error(Object error) {
    return 'Не удалось отправить: $error';
  }

  @override
  String meeting_save_error(Object error) {
    return 'Не удалось сохранить: $error';
  }

  @override
  String meeting_delete_error(Object error) {
    return 'Не удалось удалить: $error';
  }

  @override
  String get meeting_no_messages => 'Пока нет сообщений';

  @override
  String get meeting_join_enter_name => 'Укажите имя';

  @override
  String get meeting_join_guest => 'Гость';

  @override
  String get meeting_join_as_label => 'Вы войдёте как';

  @override
  String get meeting_lobby_camera_blocked =>
      'Доступ к камере не выдан. Вы войдёте с выключенной камерой.';

  @override
  String get meeting_join_button => 'Присоединиться';

  @override
  String meeting_join_load_error(Object error) {
    return 'Ошибка загрузки митинга: $error';
  }

  @override
  String get meeting_private_hint =>
      'Приватная встреча: после заявки хост решит, пустить ли вас.';

  @override
  String get meeting_public_hint =>
      'Открытая встреча: присоединяйтесь по ссылке без ожидания.';

  @override
  String get meeting_name_label => 'Ваше имя';

  @override
  String get meeting_waiting_title => 'Ожидаем подтверждения';

  @override
  String get meeting_waiting_subtitle =>
      'Хост увидит вашу заявку и решит, когда впустить.';

  @override
  String get meeting_screen_share_ios_hint =>
      'Демонстрация экрана на iOS требует Broadcast Extension (в разработке).';

  @override
  String meeting_screen_share_error(Object error) {
    return 'Не удалось запустить демонстрацию: $error';
  }

  @override
  String get meeting_speaker_mode => 'Режим спикера';

  @override
  String get meeting_grid_mode => 'Режим сетки';

  @override
  String get meeting_copy_link_tooltip =>
      'Скопировать ссылку (вход с браузера)';

  @override
  String get group_members_subtitle_creator => 'Создатель группы';

  @override
  String get group_members_subtitle_admin => 'Администратор';

  @override
  String get group_members_subtitle_member => 'Участник';

  @override
  String group_members_total_count(int count) {
    return 'Всего: $count';
  }

  @override
  String get group_members_copy_invite_tooltip =>
      'Скопировать ссылку-приглашение';

  @override
  String get group_members_add_member_tooltip => 'Добавить участника';

  @override
  String get group_members_invite_copied => 'Ссылка-приглашение скопирована';

  @override
  String group_members_copy_link_error(String error) {
    return 'Не удалось скопировать ссылку: $error';
  }

  @override
  String get group_members_added => 'Участники добавлены';

  @override
  String get group_members_revoke_admin_title => 'Снять права администратора?';

  @override
  String group_members_revoke_admin_body(String name) {
    return 'У $name будут сняты права администратора. Участник останется в группе как обычный член.';
  }

  @override
  String get group_members_grant_admin_title => 'Назначить администратором?';

  @override
  String group_members_grant_admin_body(String name) {
    return '$name получит права администратора: сможет редактировать группу, исключать участников и управлять сообщениями.';
  }

  @override
  String get group_members_revoke_admin_action => 'Снять права';

  @override
  String get group_members_grant_admin_action => 'Назначить';

  @override
  String get group_members_remove_title => 'Исключить участника?';

  @override
  String group_members_remove_body(String name) {
    return '$name будет удалён из группы. Это действие можно отменить, добавив участника заново.';
  }

  @override
  String get group_members_remove_action => 'Исключить';

  @override
  String get group_members_removed => 'Участник исключён';

  @override
  String get group_members_menu_revoke_admin => 'Снять админа';

  @override
  String get group_members_menu_grant_admin => 'Сделать админом';

  @override
  String get group_members_menu_remove => 'Исключить из группы';

  @override
  String get group_members_creator_badge => 'СОЗДАТЕЛЬ';

  @override
  String get group_members_add_title => 'Добавить участников';

  @override
  String get group_members_search_contacts => 'Поиск среди контактов';

  @override
  String get group_members_all_in_group => 'Все ваши контакты уже в группе.';

  @override
  String get group_members_nobody_found => 'Никого не найдено.';

  @override
  String get group_members_user_fallback => 'Пользователь';

  @override
  String get group_members_select_members => 'Выберите участников';

  @override
  String group_members_add_count(int count) {
    return 'Добавить ($count)';
  }

  @override
  String group_members_contacts_load_error(String error) {
    return 'Не удалось загрузить контакты: $error';
  }

  @override
  String group_members_auth_error(String error) {
    return 'Ошибка авторизации: $error';
  }

  @override
  String group_members_add_failed(String error) {
    return 'Не удалось добавить участников: $error';
  }

  @override
  String get group_not_found => 'Группа не найдена.';

  @override
  String get group_not_member => 'Вы не являетесь участником этой группы.';

  @override
  String get poll_create_title => 'Опрос в чате';

  @override
  String get poll_question_label => 'Вопрос';

  @override
  String get poll_question_hint => 'Например: Во сколько встречаемся?';

  @override
  String get poll_description_label => 'Пояснение (необязательно)';

  @override
  String get poll_options_title => 'Варианты';

  @override
  String poll_option_hint(int index) {
    return 'Вариант $index';
  }

  @override
  String get poll_add_option => 'Добавить вариант';

  @override
  String get poll_switch_anonymous => 'Анонимное голосование';

  @override
  String get poll_switch_anonymous_sub => 'Не показывать, кто за что голосовал';

  @override
  String get poll_switch_multi => 'Несколько ответов';

  @override
  String get poll_switch_multi_sub => 'Можно выбрать несколько вариантов';

  @override
  String get poll_switch_add_options => 'Добавление вариантов';

  @override
  String get poll_switch_add_options_sub =>
      'Участники могут предложить свой вариант';

  @override
  String get poll_switch_revote => 'Можно изменить голос';

  @override
  String get poll_switch_revote_sub => 'Переголосование до закрытия';

  @override
  String get poll_switch_shuffle => 'Перемешать варианты';

  @override
  String get poll_switch_shuffle_sub => 'Свой порядок у каждого участника';

  @override
  String get poll_switch_quiz => 'Режим викторины';

  @override
  String get poll_switch_quiz_sub => 'Один правильный ответ';

  @override
  String get poll_correct_option_label => 'Правильный вариант';

  @override
  String get poll_quiz_explanation_label => 'Пояснение (необязательно)';

  @override
  String get poll_close_by_time => 'Закрыть по времени';

  @override
  String get poll_close_not_set => 'Не задано';

  @override
  String get poll_close_reset => 'Сбросить срок';

  @override
  String get poll_publish => 'Опубликовать';

  @override
  String get poll_error_empty_question => 'Введите вопрос';

  @override
  String get poll_error_min_options => 'Нужно минимум 2 варианта';

  @override
  String get poll_error_select_correct => 'Выберите правильный вариант';

  @override
  String get poll_error_future_time => 'Время закрытия должно быть в будущем';

  @override
  String get poll_unavailable => 'Опрос недоступен';

  @override
  String get poll_loading => 'Загрузка опроса…';

  @override
  String get poll_not_found => 'Опрос не найден';

  @override
  String get poll_status_cancelled => 'Отменён';

  @override
  String get poll_status_ended => 'Завершён';

  @override
  String get poll_status_draft => 'Черновик';

  @override
  String get poll_status_active => 'Активен';

  @override
  String get poll_badge_public => 'Публично';

  @override
  String get poll_badge_multi => 'Несколько ответов';

  @override
  String get poll_badge_quiz => 'Викторина';

  @override
  String get poll_menu_restart => 'Перезапустить';

  @override
  String get poll_menu_end => 'Завершить';

  @override
  String get poll_menu_delete => 'Удалить';

  @override
  String get poll_submit_vote => 'Отправить голос';

  @override
  String get poll_suggest_option_hint => 'Предложить вариант';

  @override
  String get poll_revote => 'Переголосовать';

  @override
  String poll_votes_count(int count) {
    return '$count голосов';
  }

  @override
  String get poll_show_voters => 'Кто голосовал';

  @override
  String get poll_hide_voters => 'Скрыть';

  @override
  String get poll_vote_error => 'Ошибка при голосовании';

  @override
  String get poll_add_option_error => 'Не удалось добавить вариант';

  @override
  String get poll_error_generic => 'Ошибка';

  @override
  String get durak_your_turn => 'Твой ход';

  @override
  String get durak_winner_label => 'Победитель';

  @override
  String get durak_rematch => 'Сыграть ещё раз';

  @override
  String get durak_surrender_tooltip => 'Завершить игру';

  @override
  String get durak_close_tooltip => 'Закрыть';

  @override
  String get durak_fx_took => 'Взял';

  @override
  String get durak_fx_beat => 'Бито';

  @override
  String get durak_opponent_role_defend => 'БЬЕТ';

  @override
  String get durak_opponent_role_attack => 'ХОД';

  @override
  String get durak_opponent_role_throwin => 'ПОДК';

  @override
  String get durak_foul_banner_title => 'Шулер! Не заметили:';

  @override
  String get durak_pending_resolution_attacker =>
      'Ожидание фолла… Нажми «Подтвердить Бито», если все согласны.';

  @override
  String get durak_pending_resolution_other =>
      'Ожидание фолла… Теперь можно нажать «Фолл!», если заметил шулерство.';

  @override
  String durak_tournament_played(int finished, int total) {
    return 'Сыграно $finished из $total';
  }

  @override
  String get durak_tournament_finished => 'Турнир завершён';

  @override
  String get durak_tournament_next => 'Следующая партия турнира';

  @override
  String get durak_single_game => 'Одиночная партия';

  @override
  String get durak_tournament_total_games_title => 'Сколько игр в турнире?';

  @override
  String get durak_finish_game_tooltip => 'Завершить игру';

  @override
  String get durak_lobby_game_unavailable => 'Игра недоступна или была удалена';

  @override
  String get durak_lobby_back_tooltip => 'Назад';

  @override
  String get durak_lobby_waiting => 'Ожидание соперника…';

  @override
  String get durak_lobby_start => 'Начать игру';

  @override
  String get durak_lobby_waiting_short => 'Ждём…';

  @override
  String get durak_lobby_ready => 'Готов';

  @override
  String get durak_lobby_empty_slot => 'Ждём…';

  @override
  String get durak_settings_timer_subtitle => 'По умолчанию 15 секунд';

  @override
  String get durak_dm_game_active => 'Партия \"Дурак\" идёт';

  @override
  String get durak_dm_game_created => 'Игра \"Дурак\" создана';

  @override
  String get game_durak_subtitle => 'Одиночная партия или турнир';

  @override
  String get group_member_write_dm => 'Написать лично';

  @override
  String get group_member_open_dm_hint => 'Открыть личный чат с участником';

  @override
  String get group_member_profile_not_loaded =>
      'Профиль участника ещё не загружен.';

  @override
  String group_member_open_dm_error(String error) {
    return 'Не удалось открыть личный чат: $error';
  }

  @override
  String get group_avatar_photo_title => 'Фото группы';

  @override
  String get group_avatar_add_photo => 'Добавить фото';

  @override
  String get group_avatar_change => 'Сменить аватар';

  @override
  String get group_avatar_remove => 'Убрать аватар';

  @override
  String group_avatar_process_error(String error) {
    return 'Не удалось обработать фото: $error';
  }

  @override
  String get group_mention_no_matches => 'Нет совпадений';

  @override
  String get durak_error_defense_does_not_beat => 'Эта карта не бьет атакующую';

  @override
  String get durak_error_only_attacker_first => 'Первым ходит атакующий игрок';

  @override
  String get durak_error_defender_cannot_attack =>
      'Отбивающийся сейчас не подкидывает';

  @override
  String get durak_error_not_allowed_throwin =>
      'Вы не можете подкинуть в этом раунде';

  @override
  String get durak_error_throwin_not_your_turn =>
      'Сейчас подкидывает другой игрок';

  @override
  String get durak_error_rank_not_allowed =>
      'Подкинуть можно только карту того же ранга';

  @override
  String get durak_error_cannot_throw_in => 'Больше карт подкинуть нельзя';

  @override
  String get durak_error_card_not_in_hand => 'Этой карты уже нет в руке';

  @override
  String get durak_error_already_defended => 'Эта карта уже отбита';

  @override
  String get durak_error_bad_attack_index =>
      'Выберите атакующую карту для защиты';

  @override
  String get durak_error_only_defender => 'Сейчас отбивается другой игрок';

  @override
  String get durak_error_defender_already_taking =>
      'Отбивающийся уже берет карты';

  @override
  String get durak_error_game_not_active => 'Партия уже не активна';

  @override
  String get durak_error_not_in_lobby => 'Лобби уже стартовало';

  @override
  String get durak_error_game_already_active => 'Партия уже началась';

  @override
  String get durak_error_active_game_exists =>
      'В этом чате уже есть активная партия';

  @override
  String get durak_error_resolution_pending => 'Сначала завершите спорный ход';

  @override
  String get durak_error_rematch_failed =>
      'Не удалось подготовить реванш. Попробуйте еще раз';

  @override
  String get durak_error_unauthenticated => 'Нужно войти в аккаунт';

  @override
  String get durak_error_permission_denied => 'Это действие вам недоступно';

  @override
  String get durak_error_invalid_argument => 'Некорректный ход';

  @override
  String get durak_error_failed_precondition => 'Ход сейчас недоступен';

  @override
  String get durak_error_server =>
      'Не удалось выполнить ход. Попробуйте еще раз';

  @override
  String pinned_count(int count) {
    return 'Закреплено: $count';
  }

  @override
  String get pinned_single => 'Закреплено';

  @override
  String get pinned_unpin_tooltip => 'Открепить';

  @override
  String get pinned_type_image => 'Изображение';

  @override
  String get pinned_type_video => 'Видео';

  @override
  String get pinned_type_video_circle => 'Видеокружок';

  @override
  String get pinned_type_voice => 'Голосовое сообщение';

  @override
  String get pinned_type_poll => 'Опрос';

  @override
  String get pinned_type_link => 'Ссылка';

  @override
  String get pinned_type_location => 'Локация';

  @override
  String get pinned_type_sticker => 'Стикер';

  @override
  String get pinned_type_file => 'Файл';

  @override
  String get call_entry_login_required_title => 'Необходим вход';

  @override
  String get call_entry_login_required_subtitle =>
      'Откройте приложение и войдите в аккаунт.';

  @override
  String get call_entry_not_found_title => 'Звонок не найден';

  @override
  String get call_entry_not_found_subtitle =>
      'Вызов уже завершён или удалён. Возвращаемся к звонкам…';

  @override
  String get call_entry_to_calls => 'К звонкам';

  @override
  String get call_entry_ended_title => 'Звонок завершён';

  @override
  String get call_entry_ended_subtitle =>
      'Этот вызов уже недоступен. Возвращаемся к звонкам…';

  @override
  String get call_entry_caller_fallback => 'Собеседник';

  @override
  String get call_entry_opening_title => 'Открываем звонок…';

  @override
  String get call_entry_connecting_video => 'Подключение к видеозвонку';

  @override
  String get call_entry_connecting_audio => 'Подключение к аудиозвонку';

  @override
  String get call_entry_loading_subtitle => 'Загрузка данных вызова';

  @override
  String get call_entry_error_title => 'Ошибка открытия звонка';

  @override
  String chat_theme_save_error(Object error) {
    return 'Не удалось сохранить фон: $error';
  }

  @override
  String chat_theme_load_error(Object error) {
    return 'Ошибка загрузки фона: $error';
  }

  @override
  String chat_theme_delete_error(Object error) {
    return 'Ошибка удаления: $error';
  }

  @override
  String get chat_theme_description =>
      'Фон этой переписки только для вас. Общие настройки чатов в разделе «Настройки чатов» не меняются.';

  @override
  String get chat_theme_default_bg => 'По умолчанию (общие настройки)';

  @override
  String get chat_theme_global_label => 'Общие';

  @override
  String get chat_theme_hint => 'Выберите пресет или фото из галереи';

  @override
  String get date_today => 'Сегодня';

  @override
  String get date_yesterday => 'Вчера';

  @override
  String get date_month_1 => 'января';

  @override
  String get date_month_2 => 'февраля';

  @override
  String get date_month_3 => 'марта';

  @override
  String get date_month_4 => 'апреля';

  @override
  String get date_month_5 => 'мая';

  @override
  String get date_month_6 => 'июня';

  @override
  String get date_month_7 => 'июля';

  @override
  String get date_month_8 => 'августа';

  @override
  String get date_month_9 => 'сентября';

  @override
  String get date_month_10 => 'октября';

  @override
  String get date_month_11 => 'ноября';

  @override
  String get date_month_12 => 'декабря';

  @override
  String get video_circle_camera_unavailable => 'Камера недоступна';

  @override
  String video_circle_camera_error(Object error) {
    return 'Не удалось открыть камеру: $error';
  }

  @override
  String video_circle_record_error(Object error) {
    return 'Ошибка записи: $error';
  }

  @override
  String get video_circle_file_not_found => 'Файл записи не найден';

  @override
  String get video_circle_play_error => 'Не удалось воспроизвести запись';

  @override
  String video_circle_send_error(Object error) {
    return 'Не удалось отправить: $error';
  }

  @override
  String video_circle_switch_error(Object error) {
    return 'Не удалось переключить камеру: $error';
  }

  @override
  String video_circle_pause_error_detail(Object description, Object code) {
    return 'Пауза записи недоступна: $description ($code)';
  }

  @override
  String video_circle_pause_error(Object error) {
    return 'Пауза записи: $error';
  }

  @override
  String get video_circle_camera_fallback_error => 'Ошибка камеры';

  @override
  String get video_circle_retry => 'Повторить';

  @override
  String get video_circle_sending => 'Отправка...';

  @override
  String get video_circle_recorded => 'Кружок записан';

  @override
  String get video_circle_swipe_cancel => 'Влево - отмена';

  @override
  String media_screen_error(Object error) {
    return 'Ошибка загрузки медиа: $error';
  }

  @override
  String get media_screen_title => 'Медиа, ссылки и файлы';

  @override
  String get media_tab_media => 'Медиа';

  @override
  String get media_tab_circles => 'Кружки';

  @override
  String get media_tab_files => 'Файлы';

  @override
  String get media_tab_links => 'Ссылки';

  @override
  String get media_tab_audio => 'Аудио';

  @override
  String get media_empty_files => 'Нет файлов';

  @override
  String get media_empty_media => 'Нет медиа';

  @override
  String get media_attachment_fallback => 'Вложение';

  @override
  String get media_empty_circles => 'Нет кружков';

  @override
  String get media_empty_links => 'Нет ссылок';

  @override
  String get media_empty_audio => 'Нет аудио';

  @override
  String get media_sender_you => 'Вы';

  @override
  String get media_sender_fallback => 'Участник';

  @override
  String get call_detail_login_required => 'Необходим вход.';

  @override
  String get call_detail_not_found => 'Звонок не найден или нет доступа.';

  @override
  String get call_detail_unknown => 'Неизвестный';

  @override
  String get call_detail_title => 'Сведения о звонке';

  @override
  String get call_detail_video => 'Видеозвонок';

  @override
  String get call_detail_audio => 'Аудиозвонок';

  @override
  String get call_detail_outgoing => 'Исходящий';

  @override
  String get call_detail_incoming => 'Входящий';

  @override
  String get call_detail_date_label => 'Дата:';

  @override
  String get call_detail_duration_label => 'Длительность:';

  @override
  String get call_detail_call_button => 'Позвонить';

  @override
  String get call_detail_video_button => 'Видео';

  @override
  String call_detail_error(Object error) {
    return 'Ошибка: $error';
  }

  @override
  String get durak_took => 'Взял';

  @override
  String get durak_beaten => 'Бито';

  @override
  String get durak_end_game_tooltip => 'Завершить игру';

  @override
  String get durak_role_beats => 'БЬЕТ';

  @override
  String get durak_role_move => 'ХОД';

  @override
  String get durak_role_throw => 'ПОДК';

  @override
  String get durak_cheater_label => 'Шулер! Не заметили:';

  @override
  String get durak_waiting_foll_confirm =>
      'Ожидание фолла… Нажми «Подтвердить Бито», если все согласны.';

  @override
  String get durak_waiting_foll_call =>
      'Ожидание фолла… Теперь можно нажать «Фолл!», если заметил шулерство.';

  @override
  String get durak_winner => 'Победитель';

  @override
  String get durak_play_again => 'Сыграть ещё раз';

  @override
  String durak_games_progress(Object finished, Object total) {
    return 'Сыграно $finished из $total';
  }

  @override
  String get durak_next_round => 'Следующая партия турнира';

  @override
  String audio_call_error(Object error) {
    return 'Ошибка звонка: $error';
  }

  @override
  String get audio_call_ended => 'Звонок завершён';

  @override
  String get audio_call_missed => 'Пропущенный звонок';

  @override
  String get audio_call_cancelled => 'Звон��к отменен';

  @override
  String get audio_call_offer_not_ready =>
      'Оффер ещё не готов, попробуйте снова';

  @override
  String get audio_call_invalid_data => 'Некорректные данные звонка';

  @override
  String audio_call_accept_error(Object error) {
    return 'Не удалось принять звонок: $error';
  }

  @override
  String get audio_call_incoming => 'Входящий аудиозвонок';

  @override
  String get audio_call_calling => 'Аудиозвонок…';

  @override
  String privacy_save_error(Object error) {
    return 'Не удалось сохранить настройки: $error';
  }

  @override
  String privacy_load_error(Object error) {
    return 'Ошибка загрузки приватности: $error';
  }

  @override
  String get privacy_visibility => 'Видимость';

  @override
  String get privacy_online_status => 'Статус онлайн';

  @override
  String get privacy_last_visit => 'Последний визит';

  @override
  String get privacy_read_receipts => 'Индикатор прочтения';

  @override
  String get privacy_profile_info => 'Информация профиля';

  @override
  String get privacy_phone_number => 'Номер телефона';

  @override
  String get privacy_birthday => 'Дата рождения';

  @override
  String get privacy_about => 'О себе';

  @override
  String starred_load_error(Object error) {
    return 'Ошибка загрузки избранного: $error';
  }

  @override
  String get starred_title => 'Избранное';

  @override
  String get starred_empty => 'В этом чате нет избранных сообщений';

  @override
  String get starred_message_fallback => 'Сообщение';

  @override
  String get starred_sender_you => 'Вы';

  @override
  String get starred_sender_fallback => 'Участник';

  @override
  String get starred_type_poll => 'Опрос';

  @override
  String get starred_type_location => 'Локация';

  @override
  String get starred_type_attachment => 'Вложение';

  @override
  String starred_today_prefix(Object time) {
    return 'Сегодня, $time';
  }

  @override
  String get contact_edit_name_required => 'Введите имя контакта.';

  @override
  String contact_edit_save_error(Object error) {
    return 'Не удалось сохранить контакт: $error';
  }

  @override
  String get contact_edit_user_fallback => 'Пользователь';

  @override
  String get contact_edit_first_name_hint => 'Имя';

  @override
  String get contact_edit_last_name_hint => 'Фамилия';

  @override
  String get contact_edit_description =>
      'Это имя видно только вам: в чатах, поиске и списке контактов.';

  @override
  String contact_edit_error(Object error) {
    return 'Ошибка: $error';
  }

  @override
  String get voice_no_mic_access => 'Не�� доступа к микрофону';

  @override
  String get voice_start_error => 'Не удалось начать запись';

  @override
  String get voice_file_not_received => 'Файл записи не получен';

  @override
  String get voice_stop_error => 'Не удалось завершить запись';

  @override
  String get voice_title => 'Голосовое сообщение';

  @override
  String get voice_recording => 'Идёт запись';

  @override
  String get voice_ready => 'Запись готова';

  @override
  String get voice_stop_button => 'Остановить';

  @override
  String get voice_record_again => 'Записать снова';

  @override
  String get attach_photo_video => 'Фото/Видео';

  @override
  String get attach_files => 'Файлы';

  @override
  String get attach_circle => 'Кружок';

  @override
  String get attach_location => 'Локация';

  @override
  String get attach_poll => 'Опрос';

  @override
  String get attach_stickers => 'Стикеры';

  @override
  String get attach_clipboard => 'Буфер';

  @override
  String get attach_text => 'Текст';

  @override
  String get attach_title => 'Прикрепить';

  @override
  String notif_save_error(Object error) {
    return 'Не удалось сохранить: $error';
  }

  @override
  String get notif_title => 'Уведомления в этом чате';

  @override
  String get notif_description =>
      'Настройки ниже действуют только для этой беседы и не меняют общие уведомления приложения.';

  @override
  String get notif_this_chat => 'Этот чат';

  @override
  String get notif_mute_title => 'Без звука и скрытые оповещения';

  @override
  String get notif_mute_subtitle =>
      'Не беспокоить по этому чату на этом устройстве.';

  @override
  String get notif_preview_title => 'Показывать превью текста';

  @override
  String get notif_preview_subtitle =>
      'Если выключено — заголовок без фрагмента сообщения (где это поддерживается).';

  @override
  String get poll_create_enter_question => 'Введите вопрос';

  @override
  String get poll_create_min_options => 'Нужно минимум 2 варианта';

  @override
  String get poll_create_select_correct => 'Выберите правильный вариант';

  @override
  String get poll_create_future_time => 'Время закрытия должно быть в будущем';

  @override
  String get poll_create_question_label => 'Вопрос';

  @override
  String get poll_create_question_hint => 'Например: Во сколько встречаемся?';

  @override
  String get poll_create_explanation_label => 'Пояснение (необязательно)';

  @override
  String get poll_create_options_title => 'Варианты';

  @override
  String poll_create_option_hint(Object index) {
    return 'Вариант $index';
  }

  @override
  String get poll_create_add_option => 'Добавить вариант';

  @override
  String get poll_create_anonymous_title => 'Анонимное голосование';

  @override
  String get poll_create_anonymous_subtitle =>
      'Не показывать, кто за что голосовал';

  @override
  String get poll_create_multi_title => 'Несколько ответов';

  @override
  String get poll_create_multi_subtitle => 'Можно выбрать несколько вариантов';

  @override
  String get poll_create_user_options_title => 'Добавление вариантов';

  @override
  String get poll_create_user_options_subtitle =>
      'Участники могут предложить свой вариант';

  @override
  String get poll_create_revote_title => 'Можно изменить голос';

  @override
  String get poll_create_revote_subtitle => 'Переголосование до закрытия';

  @override
  String get poll_create_shuffle_title => 'Перемешать варианты';

  @override
  String get poll_create_shuffle_subtitle => 'Свой порядок у каждого участника';

  @override
  String get poll_create_quiz_title => 'Режим викторины';

  @override
  String get poll_create_quiz_subtitle => 'Один правильный ответ';

  @override
  String get poll_create_correct_option_label => 'Правильный вариант';

  @override
  String get poll_create_close_by_time => 'Закрыть по времени';

  @override
  String get poll_create_not_set => 'Не задано';

  @override
  String get poll_create_reset_deadline => 'Сбросить срок';

  @override
  String get poll_create_publish => 'Опубликовать';

  @override
  String get poll_error => 'Ошибка';

  @override
  String get poll_status_finished => 'Завершён';

  @override
  String get poll_restart => 'Перезапустить';

  @override
  String get poll_finish => 'Завершить';

  @override
  String get poll_suggest_hint => 'Предложить вариант';

  @override
  String get poll_voters_toggle_hide => 'Скрыть';

  @override
  String get poll_voters_toggle_show => 'Кто голосовал';

  @override
  String get e2ee_disable_title => 'Отключить шифрование?';

  @override
  String get e2ee_disable_body =>
      'Новые сообщения пойдут без сквозного шифрования. Ранее отправленные зашифрованные сообщения останутся в ленте.';

  @override
  String get e2ee_disable_button => 'Отключить';

  @override
  String e2ee_disable_error(Object error) {
    return 'Не удалось отключить: $error';
  }

  @override
  String get e2ee_screen_title => 'Шифрование';

  @override
  String get e2ee_enabled_description =>
      'Сквозное шифрование включено для этого чата.';

  @override
  String get e2ee_disabled_description => 'Сквозное шифрование выключено.';

  @override
  String get e2ee_info_text =>
      'Когда шифрование включено, содержимое новых сообщений доступно только участникам чата на их устройствах. Отключение влияет только на новые сообщения.';

  @override
  String get e2ee_enable_title => 'Включить шифрование';

  @override
  String e2ee_status_enabled(Object epoch) {
    return 'Включено (эпоха ключа: $epoch)';
  }

  @override
  String get e2ee_status_disabled => 'Выключено';

  @override
  String get e2ee_data_types_title => 'Типы данных';

  @override
  String get e2ee_data_types_info =>
      'Настройка не меняет протокол. Она управляет тем, какие типы данных отправлять в зашифрованном виде.';

  @override
  String get e2ee_chat_settings_title => 'Настройки шифрования для этого чата';

  @override
  String get e2ee_chat_settings_override => 'Используются чатовые настройки.';

  @override
  String get e2ee_chat_settings_global => 'Наследуются глобальные настройки.';

  @override
  String get e2ee_text_messages => 'Текст сообщений';

  @override
  String get e2ee_attachments => 'Вложения (медиа/файлы)';

  @override
  String get e2ee_override_hint =>
      'Чтобы изменить для этого чата — включите «Переопределить».';

  @override
  String get group_member_fallback => 'Участник';

  @override
  String get group_role_creator => 'Создатель группы';

  @override
  String get group_role_admin => 'Администратор';

  @override
  String group_total_count(Object count) {
    return 'Всего: $count';
  }

  @override
  String get group_copy_invite_tooltip => 'Скопировать ссылку-приглашение';

  @override
  String get group_add_member_tooltip => 'Добавить участника';

  @override
  String get group_invite_copied => 'Ссылка-приглашение скопирована';

  @override
  String group_copy_invite_error(Object error) {
    return 'Не удалось скопировать ссылку: $error';
  }

  @override
  String get group_demote_confirm => 'Снять права администратора?';

  @override
  String get group_promote_confirm => 'Назначить администратором?';

  @override
  String group_demote_body(Object name) {
    return 'У $name будут сняты права администратора. Участник останется в группе как обычный член.';
  }

  @override
  String get group_demote_button => 'Снять права';

  @override
  String get group_promote_button => 'Назначить';

  @override
  String get group_kick_confirm => 'Исключить участника?';

  @override
  String get group_kick_button => 'Исключить';

  @override
  String get group_member_kicked => 'Участник исключён';

  @override
  String get group_badge_creator => 'СО��ДАТЕЛЬ';

  @override
  String get group_demote_action => 'Снять админа';

  @override
  String get group_promote_action => 'Сделать админом';

  @override
  String get group_kick_action => 'Исключить из группы';

  @override
  String group_contacts_load_error(Object error) {
    return 'Не удалось загрузить контакты: $error';
  }

  @override
  String get group_add_members_title => 'Добавить участников';

  @override
  String get group_search_contacts_hint => 'Поиск среди конта��тов';

  @override
  String get group_all_contacts_in_group => 'Все ваши контакты уже в группе.';

  @override
  String get group_nobody_found => 'Никого не найдено.';

  @override
  String get group_user_fallback => 'Пользователь';

  @override
  String get group_select_members => 'Выберите участников';

  @override
  String group_add_count(Object count) {
    return 'Добавить ($count)';
  }

  @override
  String group_auth_error(Object error) {
    return 'Ошибка авторизации: $error';
  }

  @override
  String group_add_error(Object error) {
    return 'Не удалось добавить участников: $error';
  }

  @override
  String get add_contact_own_profile => 'Это ваш собственный профиль';

  @override
  String get add_contact_qr_not_found => '��рофиль из QR-кода не найден';

  @override
  String add_contact_qr_error(Object error) {
    return 'Не удалось прочитать QR-код: $error';
  }

  @override
  String get add_contact_not_allowed => 'Нельзя добавить этого пользователя';

  @override
  String add_contact_save_error(Object error) {
    return 'Не удалось добавить контакт: $error';
  }

  @override
  String get add_contact_country_search => 'Поиск страны или кода';

  @override
  String get add_contact_sync_phone => 'С��нхронизировать с телефоном';

  @override
  String get add_contact_qr_button => 'Д��бавить по QR-коду';

  @override
  String add_contact_load_error(Object error) {
    return 'Ошибка загрузки контакта: $error';
  }

  @override
  String get add_contact_user_fallback => 'Пользователь';

  @override
  String get add_contact_already_in_contacts => 'Уже в контактах';

  @override
  String get add_contact_new => 'Новый контакт';

  @override
  String get add_contact_unavailable => 'Недоступно';

  @override
  String get add_contact_scan_qr => 'Сканировать QR-код';

  @override
  String get add_contact_scan_hint =>
      'Наведите камеру на QR-код профиля LighChat';

  @override
  String get auth_validate_name_min_length =>
      'Имя должно быть не менее 2 символов';

  @override
  String get auth_validate_username_min_length =>
      'Имя пользователя должно быть не менее 3 символов';

  @override
  String get auth_validate_username_max_length =>
      'Имя пользователя не должно превышать 30 символов';

  @override
  String get auth_validate_username_format =>
      'Имя пользователя содержит недопустимые символы';

  @override
  String get auth_validate_phone_11_digits =>
      'Номер телефона должен содержать 11 цифр';

  @override
  String get auth_validate_email_format => 'Введите корректный email';

  @override
  String get auth_validate_dob_invalid => 'Некорректная дата рождения';

  @override
  String get auth_validate_bio_max_length =>
      'Описание не должно превышать 200 символов';

  @override
  String get auth_validate_password_min_length =>
      'Пароль должен быть не менее 6 символов';

  @override
  String get auth_validate_passwords_mismatch => 'Пароли не совпадают';

  @override
  String get sticker_new_pack => 'Новый пак…';

  @override
  String get sticker_select_image_or_gif => 'Выберите изображение или GIF';

  @override
  String sticker_send_error(Object error) {
    return 'Не удалось отправить: $error';
  }

  @override
  String get sticker_saved => 'Сохранено в стикерпак';

  @override
  String get sticker_save_failed => 'Не удалось скачать или сохранить GIF';

  @override
  String get sticker_tab_my => 'Мои';

  @override
  String get sticker_tab_shared => 'Общие';

  @override
  String get sticker_no_packs => 'Нет стикерпаков. Создайте новый.';

  @override
  String get sticker_shared_not_configured => 'Общие паки не настроены';

  @override
  String get sticker_recent => 'НЕДАВНИЕ';

  @override
  String get sticker_gallery_description =>
      'Фото, PNG, GIF с устройства — сразу в чат';

  @override
  String get sticker_shared_unavailable => 'Общие паки пока недоступны';

  @override
  String get sticker_gif_search_hint => 'Поиск GIF…';

  @override
  String sticker_gif_searched(Object query) {
    return 'Искали: $query';
  }

  @override
  String get sticker_gif_search_unavailable => 'Поиск GIF временно недоступен.';

  @override
  String get sticker_gif_nothing_found => 'Ничего не найдено';

  @override
  String get sticker_gif_all => 'Все';

  @override
  String get sticker_gif_animated => 'АНИМИРОВАННЫЕ';

  @override
  String get sticker_emoji_text_unavailable =>
      'Эмодзи в текст недоступны для этого окна.';

  @override
  String get wallpaper_sender => 'Собеседник';

  @override
  String get wallpaper_incoming => 'Это входящее сообщение.';

  @override
  String get wallpaper_outgoing => 'Это исходящее сообщение.';

  @override
  String get wallpaper_incoming_time => '11:40';

  @override
  String get wallpaper_outgoing_time => '11:41';

  @override
  String get wallpaper_system => 'Вы сменили обои чата';

  @override
  String get wallpaper_you => 'Вы';

  @override
  String get wallpaper_today => 'Сегодня';

  @override
  String system_event_e2ee_enabled(Object epoch) {
    return 'Сквозное шифрование включено (эпоха ключа: $epoch)';
  }

  @override
  String get system_event_e2ee_disabled => 'Сквозное шифрование отключено';

  @override
  String get system_event_unknown => 'Системное событие';

  @override
  String get system_event_group_created => 'Группа создана';

  @override
  String system_event_member_added(Object name) {
    return '$name добавлен(а)';
  }

  @override
  String system_event_member_removed(Object name) {
    return '$name удалён(а)';
  }

  @override
  String system_event_member_left(Object name) {
    return '$name покинул(а) группу';
  }

  @override
  String system_event_name_changed(Object name) {
    return 'Название изменено на «$name»';
  }

  @override
  String get image_editor_title => 'Редактор';

  @override
  String get image_editor_undo => 'Отменить';

  @override
  String get image_editor_clear => 'Очистить';

  @override
  String get image_editor_pen => 'Кисть';

  @override
  String get image_editor_text => 'Текст';

  @override
  String get image_editor_crop => 'Кадрирование';

  @override
  String get image_editor_rotate => 'Поворот';

  @override
  String get location_title => 'Отправить местоположение';

  @override
  String get location_loading => 'Загрузка карты…';

  @override
  String get location_send_button => 'Отправить';

  @override
  String get location_live_label => 'Трансляция';

  @override
  String get location_error => 'Не удалось загрузить карту';

  @override
  String get location_no_permission => 'Нет доступа к местоположению';

  @override
  String get group_member_admin => 'Администратор';

  @override
  String get group_member_creator => 'Создатель';

  @override
  String get group_member_member => 'Участник';

  @override
  String get group_member_open_chat => 'Написать';

  @override
  String get group_member_open_profile => 'Профиль';

  @override
  String get group_member_remove => 'Исключить';

  @override
  String get durak_lobby_title => 'Дурак';

  @override
  String get durak_lobby_new_game => 'Новая игра';

  @override
  String get durak_lobby_decline => 'Отклонить';

  @override
  String get durak_lobby_accept => 'Принять';

  @override
  String get durak_lobby_invite_sent => 'Приглашение отправлено';

  @override
  String get voice_preview_cancel => 'Отмена';

  @override
  String get voice_preview_send => 'Отправить';

  @override
  String get voice_preview_recorded => 'Записано';

  @override
  String get voice_preview_playing => 'Воспроизведение…';

  @override
  String get voice_preview_paused => 'Пауза';

  @override
  String get group_avatar_camera => 'Камера';

  @override
  String get group_avatar_gallery => 'Галерея';

  @override
  String get group_avatar_upload_error => 'Ошибка загрузки';

  @override
  String get avatar_picker_title => 'Аватар';

  @override
  String get avatar_picker_camera => 'Камера';

  @override
  String get avatar_picker_gallery => 'Галерея';

  @override
  String get avatar_picker_crop => 'Обрезка';

  @override
  String get avatar_picker_save => 'Сохранить';

  @override
  String get avatar_picker_remove => 'Удалить аватар';

  @override
  String get avatar_picker_error => 'Не удалось загрузить аватар';

  @override
  String get avatar_picker_crop_error => 'Ошибка обрезки';

  @override
  String get webview_telegram_title => 'Вход через Telegram';

  @override
  String get webview_telegram_loading => 'Загрузка…';

  @override
  String get webview_telegram_error => 'Не удалось загрузить страницу';

  @override
  String get webview_telegram_back => 'Назад';

  @override
  String get webview_telegram_retry => 'Повторить';

  @override
  String get webview_telegram_close => 'Закрыть';

  @override
  String get webview_telegram_no_url => 'Не указан URL для авторизации';

  @override
  String get webview_yandex_title => 'Вход через Яндекс';

  @override
  String get webview_yandex_loading => 'Загрузка…';

  @override
  String get webview_yandex_error => 'Не удалось загрузить страницу';

  @override
  String get webview_yandex_back => 'Назад';

  @override
  String get webview_yandex_retry => 'Повторить';

  @override
  String get webview_yandex_close => 'Закрыть';

  @override
  String get webview_yandex_no_url => 'Не указан URL для авторизации';

  @override
  String get google_profile_title => 'Заполните профиль';

  @override
  String get google_profile_name => 'Имя';

  @override
  String get google_profile_username => 'Имя пользователя';

  @override
  String get google_profile_phone => 'Телефон';

  @override
  String get google_profile_email => 'Email';

  @override
  String get google_profile_dob => 'Дата рождения';

  @override
  String get google_profile_bio => 'О себе';

  @override
  String get google_profile_save => 'Сохранить';

  @override
  String get google_profile_error => 'Не удалось сохранить профиль';

  @override
  String get system_event_e2ee_epoch_rotated => 'Ключ шифрования обновлён';

  @override
  String system_event_e2ee_device_added(String actor, String device) {
    return '$actor добавил устройство «$device»';
  }

  @override
  String system_event_e2ee_device_revoked(String actor, String device) {
    return '$actor отозвал устройство «$device»';
  }

  @override
  String system_event_e2ee_fingerprint_changed(String actor) {
    return 'Отпечаток безопасности у $actor изменился';
  }

  @override
  String get system_event_game_lobby_created => 'Создано лобби игры';

  @override
  String get system_event_game_started => 'Игра началась';

  @override
  String get system_event_call_missed => 'Пропущенный звонок';

  @override
  String get system_event_call_cancelled => 'Звонок отклонён';

  @override
  String get system_event_default_actor => 'Пользователь';

  @override
  String get system_event_default_device => 'устройство';

  @override
  String get image_editor_add_caption => 'Добавить подпись...';

  @override
  String get image_editor_crop_failed => 'Не удалось обрезать изображение';

  @override
  String get image_editor_draw_hint =>
      'Режим рисования: проведите пальцем по изображению';

  @override
  String get image_editor_crop_title => 'Обрезка';

  @override
  String get location_preview_title => 'Местоположение';

  @override
  String get location_preview_accuracy_unknown => 'Точность: —';

  @override
  String location_preview_accuracy_meters(String meters) {
    return 'Точность: ~$meters м';
  }

  @override
  String location_preview_accuracy_km(String km) {
    return 'Точность: ~$km км';
  }

  @override
  String get group_member_profile_default_name => 'Участник';

  @override
  String get group_member_profile_dm => 'Написать лично';

  @override
  String get group_member_profile_dm_hint => 'Открыть личный чат с участником';

  @override
  String group_member_profile_dm_failed(Object error) {
    return 'Не удалось открыть личный чат: $error';
  }

  @override
  String get conversation_game_lobby_unavailable =>
      'Игра недоступна или была удалена';

  @override
  String get conversation_game_lobby_back => 'Назад';

  @override
  String get conversation_game_lobby_waiting =>
      'Ждём, пока подключится соперник…';

  @override
  String get conversation_game_lobby_start_game => 'Начать игру';

  @override
  String get conversation_game_lobby_waiting_short => 'Ждём…';

  @override
  String get conversation_game_lobby_ready => 'Готов';

  @override
  String get voice_preview_trim_confirm_title =>
      'Оставить только выбранный фрагмент?';

  @override
  String get voice_preview_trim_confirm_body =>
      'Всё, кроме выделенного фрагмента, будет удалено. Запись сообщения продолжится сразу после нажатия кнопки.';

  @override
  String get voice_preview_continue => 'Продолжить';

  @override
  String get voice_preview_continue_recording => 'Продолжить запись';

  @override
  String get group_avatar_change_short => 'Сменить';

  @override
  String get avatar_picker_cancel => 'Отмена';

  @override
  String get avatar_picker_choose => 'Выбрать аватар';

  @override
  String get avatar_picker_delete_photo => 'Удалить фото';

  @override
  String get avatar_picker_loading => 'Загрузка…';

  @override
  String get avatar_picker_choose_avatar => 'Выбрать аватар';

  @override
  String get avatar_picker_change_avatar => 'Сменить аватар';

  @override
  String get avatar_picker_remove_tooltip => 'Убрать';

  @override
  String get telegram_sign_in_title => 'Вход через Telegram';

  @override
  String get telegram_sign_in_open_in_browser => 'Открыть в браузере';

  @override
  String get telegram_sign_in_open_telegram_failed =>
      'Не удалось открыть Telegram. Установите приложение Telegram.';

  @override
  String get telegram_sign_in_page_load_error => 'Ошибка загрузки страницы';

  @override
  String get telegram_sign_in_login_error => 'Ошибка входа через Telegram.';

  @override
  String get telegram_sign_in_firebase_not_ready => 'Firebase не готов.';

  @override
  String get telegram_sign_in_browser_failed => 'Не удалось открыть браузер.';

  @override
  String telegram_sign_in_login_failed(Object error) {
    return 'Не удалось войти: $error';
  }

  @override
  String get yandex_sign_in_title => 'Вход через Яндекс';

  @override
  String get yandex_sign_in_open_in_browser => 'Открыть в браузере';

  @override
  String get yandex_sign_in_page_load_error => 'Ошибка загрузки страницы';

  @override
  String get yandex_sign_in_login_error => 'Ошибка входа через Яндекс.';

  @override
  String get yandex_sign_in_firebase_not_ready => 'Firebase не готов.';

  @override
  String get yandex_sign_in_browser_failed => 'Не удалось открыть браузер.';

  @override
  String yandex_sign_in_login_failed(Object error) {
    return 'Не удалось войти: $error';
  }

  @override
  String get google_complete_title => 'Завершите регистрацию';

  @override
  String get google_complete_subtitle =>
      'После входа через Google нужно заполнить профиль, как в веб-версии.';

  @override
  String get google_complete_name_label => 'Имя';

  @override
  String get google_complete_username_label => 'Логин (@username)';

  @override
  String get google_complete_phone_label => 'Телефон (11 цифр)';

  @override
  String get google_complete_email_label => 'Email';

  @override
  String get google_complete_email_hint => 'you@example.com';

  @override
  String get google_complete_dob_label =>
      'Дата рождения (YYYY-MM-DD, опционально)';

  @override
  String get google_complete_bio_label =>
      'О себе (до 200 символов, опционально)';

  @override
  String get google_complete_save => 'Сохранить и продолжить';

  @override
  String get google_complete_back => 'Вернуться к авторизации';

  @override
  String get game_error_defense_not_beat => 'Эта карта не бьет атакующую';

  @override
  String get game_error_attacker_first => 'Первым ходит атакующий игрок';

  @override
  String get game_error_defender_no_attack =>
      'Отбивающийся сейчас не подкидывает';

  @override
  String get game_error_not_allowed_throwin =>
      'Вы не можете подкинуть в этом раунде';

  @override
  String get game_error_throwin_not_turn => 'Сейчас подкидывает другой игрок';

  @override
  String get game_error_rank_not_allowed =>
      'Подкинуть можно только карту того же ранга';

  @override
  String get game_error_cannot_throw_in => 'Больше карт подкинуть нельзя';

  @override
  String get game_error_card_not_in_hand => 'Этой карты уже нет в руке';

  @override
  String get game_error_already_defended => 'Эта карта уже отбита';

  @override
  String get game_error_bad_attack_index =>
      'Выберите атакующую карту для защиты';

  @override
  String get game_error_only_defender => 'Сейчас отбивается другой игрок';

  @override
  String get game_error_defender_taking => 'Отбивающийся уже берет карты';

  @override
  String get game_error_game_not_active => 'Партия уже не активна';

  @override
  String get game_error_not_in_lobby => 'Лобби уже стартовало';

  @override
  String get game_error_game_already_active => 'Партия уже началась';

  @override
  String get game_error_active_exists => 'В этом чате уже есть активная партия';

  @override
  String get game_error_round_pending => 'Сначала завершите спорный ход';

  @override
  String get game_error_rematch_failed =>
      'Не удалось подготовить реванш. Попробуйте ��ще раз';

  @override
  String get game_error_unauthenticated => 'Нужно войти в аккаунт';

  @override
  String get game_error_permission_denied => 'Это действие вам недоступно';

  @override
  String get game_error_invalid_argument => 'Некорректный ход';

  @override
  String get game_error_precondition => 'Ход сейчас недоступен';

  @override
  String get game_error_server =>
      'Не удалось выполнить ход. Попробуйте еще раз';

  @override
  String get reply_sticker => 'Стикер';

  @override
  String get reply_gif => 'GIF';

  @override
  String get reply_video_circle => 'Кружок';

  @override
  String get reply_voice_message => 'Голосовое сообщение';

  @override
  String get reply_video => 'Видео';

  @override
  String get reply_photo => 'Фотография';

  @override
  String get reply_file => 'Файл';

  @override
  String get reply_location => 'Локация';

  @override
  String get reply_poll => 'Опрос';

  @override
  String get reply_link => 'Ссылка';

  @override
  String get reply_message => 'Сообщение';

  @override
  String get reply_sender_you => 'Вы';

  @override
  String get reply_sender_member => 'Участник';

  @override
  String get call_format_today => 'Сегодня';

  @override
  String get call_format_yesterday => 'Вчера';

  @override
  String get call_format_second_short => 'с';

  @override
  String get call_format_minute_short => 'м';

  @override
  String get call_format_hour_short => 'ч';

  @override
  String get call_format_day_short => 'д';

  @override
  String get call_month_january => 'января';

  @override
  String get call_month_february => 'февраля';

  @override
  String get call_month_march => 'марта';

  @override
  String get call_month_april => 'апреля';

  @override
  String get call_month_may => 'мая';

  @override
  String get call_month_june => 'июня';

  @override
  String get call_month_july => 'июля';

  @override
  String get call_month_august => 'августа';

  @override
  String get call_month_september => 'сентября';

  @override
  String get call_month_october => 'октября';

  @override
  String get call_month_november => 'ноября';

  @override
  String get call_month_december => 'декабря';

  @override
  String get push_incoming_call => 'Входящий звонок';

  @override
  String get push_incoming_video_call => 'Входящий видеозвонок';

  @override
  String get push_new_message => 'Новое сообщение';

  @override
  String get push_channel_calls => 'Звонки';

  @override
  String get push_channel_messages => 'Сообщения';

  @override
  String contacts_years_one(Object count) {
    return '$count год';
  }

  @override
  String contacts_years_few(Object count) {
    return '$count года';
  }

  @override
  String contacts_years_many(Object count) {
    return '$count лет';
  }

  @override
  String contacts_years_other(Object count) {
    return '$count years';
  }

  @override
  String get durak_entry_single_game => 'Одиночная партия';

  @override
  String get durak_entry_finish_game_tooltip => 'Завершить игру';

  @override
  String get durak_entry_tournament_games_dialog_title =>
      'Сколько игр в турнире?';

  @override
  String get durak_entry_cancel => 'Отмена';

  @override
  String get durak_entry_create => 'Создать';

  @override
  String video_editor_load_failed(Object error) {
    return 'Не удалось загрузить видео: $error';
  }

  @override
  String video_editor_process_failed(Object error) {
    return 'Не удалось обработать видео: $error';
  }

  @override
  String video_editor_duration(Object duration) {
    return 'Длительность: $duration';
  }

  @override
  String get video_editor_brush => 'Кисть';

  @override
  String get video_editor_caption_hint => 'Добавить подпись...';

  @override
  String get video_effects_speed => 'Скорость';

  @override
  String get video_filter_none => 'Оригинал';

  @override
  String get video_filter_enhance => 'Улучшить';

  @override
  String get share_location_title => 'Поделиться геолокацией';

  @override
  String get share_location_how => 'Как делиться';

  @override
  String get share_location_cancel => 'Отмена';

  @override
  String get share_location_send => 'Отправить';

  @override
  String get photo_source_gallery => 'Галерея';

  @override
  String get photo_source_take_photo => 'Сделать фото';

  @override
  String get photo_source_record_video => 'Записать видео';

  @override
  String get video_attachment_media_kind => 'видео';

  @override
  String get video_attachment_title => 'Видео';

  @override
  String get video_attachment_playback_error =>
      'Не удалось воспроизвести видео. Проверьте ссылку и сеть.';

  @override
  String get location_card_broadcast_ended_mine =>
      'Трансляция геолокации завершена. Собеседник больше не видит ваше актуальное местоположение.';

  @override
  String get location_card_broadcast_ended_other =>
      'Трансляция геолокации у этого контакта завершена. Актуальная позиция недоступна.';

  @override
  String get location_card_title => 'Местоположение';

  @override
  String location_card_accuracy(Object meters) {
    return '±$meters м';
  }

  @override
  String get link_webview_copy_tooltip => 'Скопировать ссылку';

  @override
  String get link_webview_copied_snackbar => 'Ссылка скопирована';

  @override
  String get link_webview_open_browser_tooltip => 'Открыть в браузере';

  @override
  String get hold_record_pause => 'Пауза';

  @override
  String get hold_record_release_cancel => 'Отпустите — отмена';

  @override
  String get hold_record_slide_hints => 'Влево — отмена · Вверх — пауза';

  @override
  String get e2ee_badge_loading => 'Загружаем отпечаток…';

  @override
  String e2ee_badge_error(Object error) {
    return 'Не удалось получить отпечаток: $error';
  }

  @override
  String get e2ee_badge_label => 'Отпечаток E2EE';

  @override
  String e2ee_badge_label_with_user(Object user) {
    return 'Отпечаток E2EE • $user';
  }

  @override
  String e2ee_badge_devices(Object count) {
    return '$count устр.';
  }

  @override
  String get composer_link_cancel => 'Отмена';

  @override
  String message_search_results_count(Object count) {
    return 'РЕЗУЛЬТАТЫ ПОИСКА: $count';
  }

  @override
  String get message_search_not_found => 'НИЧЕГО НЕ НАЙДЕНО';

  @override
  String get message_search_participant_fallback => 'Участник';

  @override
  String get wallpaper_purple => 'Фиолетовый';

  @override
  String get wallpaper_pink => 'Розовый';

  @override
  String get wallpaper_blue => 'Голубой';

  @override
  String get wallpaper_green => 'Зелёный';

  @override
  String get wallpaper_sunset => 'Закат';

  @override
  String get wallpaper_tender => 'Нежный';

  @override
  String get wallpaper_lime => 'Лайм';

  @override
  String get wallpaper_graphite => 'Графит';

  @override
  String get avatar_crop_title => 'Настройка аватара';

  @override
  String get avatar_crop_hint =>
      'Перетащите и масштабируйте — так круг будет в списках и сообщениях; полный кадр остаётся для профиля.';

  @override
  String get avatar_crop_cancel => 'Отмена';

  @override
  String get avatar_crop_reset => 'Сбросить';

  @override
  String get avatar_crop_save => 'Сохранить';

  @override
  String get meeting_entry_connecting => 'Подключаемся к митингу…';

  @override
  String meeting_entry_auth_failed(Object error) {
    return 'Не удалось войти: $error';
  }

  @override
  String get meeting_entry_participant_fallback => 'Участник';

  @override
  String get meeting_entry_back => 'Назад';

  @override
  String get meeting_chat_copy => 'Копировать';

  @override
  String get meeting_chat_edit => 'Изменить';

  @override
  String get meeting_chat_delete => 'Удалить';

  @override
  String get meeting_chat_deleted => 'Сообщение удалено';

  @override
  String get meeting_chat_edited_mark => '• изм.';

  @override
  String get meeting_chat_reply => 'Ответить';

  @override
  String get meeting_chat_react => 'Реакция';

  @override
  String get meeting_chat_copied => 'Скопировано';

  @override
  String get meeting_chat_editing => 'Редактирование';

  @override
  String meeting_chat_reply_to(Object name) {
    return 'Ответ $name';
  }

  @override
  String get meeting_chat_attachment_placeholder => 'Вложение';

  @override
  String meeting_timer_remaining(Object time) {
    return 'Осталось $time';
  }

  @override
  String meeting_timer_elapsed(Object time) {
    return '$time';
  }

  @override
  String get meeting_back_to_chats => 'К чатам';

  @override
  String get meeting_open_chats => 'Открыть чаты';

  @override
  String get meeting_in_call_chat => 'Чат конференции';

  @override
  String get meeting_lobby_open_settings => 'Открыть настройки';

  @override
  String get meeting_lobby_retry => 'Повторить';

  @override
  String get meeting_minimized_resume => 'Нажмите, чтобы вернуться';

  @override
  String get e2ee_decrypt_image_failed => 'Не удалось расшифровать изображение';

  @override
  String get e2ee_decrypt_video_failed => 'Не удалось расшифровать видео';

  @override
  String get e2ee_decrypt_audio_failed => 'Не удалось расшифровать аудио';

  @override
  String get e2ee_decrypt_attachment_failed =>
      'Не удалось расшифровать вложение';

  @override
  String get search_preview_attachment => 'Вложение';

  @override
  String get search_preview_location => 'Геолокация';

  @override
  String get search_preview_message => 'Сообщение';

  @override
  String get outbox_attachment_singular => 'Вложение';

  @override
  String outbox_attachments_count(int count) {
    return 'Вложения ($count)';
  }

  @override
  String get outbox_chat_unavailable => 'Сервис чата недоступен';

  @override
  String outbox_encryption_error(String code) {
    return 'Шифрование: $code';
  }

  @override
  String get nav_chats => 'Чаты';

  @override
  String get nav_contacts => 'Контакты';

  @override
  String get nav_meetings => 'Конференции';

  @override
  String get nav_calls => 'Звонки';

  @override
  String get e2ee_media_decrypt_failed_image =>
      'Не удалось расшифровать изображение';

  @override
  String get e2ee_media_decrypt_failed_video => 'Не удалось расшифровать видео';

  @override
  String get e2ee_media_decrypt_failed_audio => 'Не удалось расшифровать аудио';

  @override
  String get e2ee_media_decrypt_failed_attachment =>
      'Не удалось расшифровать вложение';

  @override
  String get chat_search_snippet_attachment => 'Вложение';

  @override
  String get chat_search_snippet_location => 'Геолокация';

  @override
  String get chat_search_snippet_message => 'Сообщение';

  @override
  String get bottom_nav_chats => 'Чаты';

  @override
  String get bottom_nav_contacts => 'Контакты';

  @override
  String get bottom_nav_meetings => 'Конференции';

  @override
  String get bottom_nav_calls => 'Звонки';

  @override
  String get chat_list_swipe_folders => 'ПАПКИ';

  @override
  String get chat_list_swipe_clear => 'ОЧИСТИТЬ';

  @override
  String get chat_list_swipe_delete => 'УДАЛИТЬ';

  @override
  String get composer_editing_title => 'РЕДАКТИРОВАНИЕ СООБЩЕНИЯ';

  @override
  String get composer_editing_cancel_tooltip => 'Отменить редактирование';

  @override
  String get composer_formatting_title => 'ФОРМАТИРОВАНИЕ';

  @override
  String get composer_link_preview_loading => 'Загрузка превью…';

  @override
  String get composer_link_preview_hide_tooltip => 'Скрыть превью';

  @override
  String get chat_invite_button => 'Пригласить';

  @override
  String get forward_preview_unknown_sender => 'Неизвестный';

  @override
  String get forward_preview_attachment => 'Вложение';

  @override
  String get forward_preview_message => 'Сообщение';

  @override
  String get chat_mention_no_matches => 'Нет совпадений';

  @override
  String get live_location_sharing => 'Вы делитесь геолокацией';

  @override
  String get live_location_stop => 'Остановить';

  @override
  String get chat_message_deleted => 'Сообщение удалено';

  @override
  String get profile_qr_share => 'Поделиться';

  @override
  String get shared_location_open_browser_tooltip => 'Открыть в браузере';

  @override
  String get reply_preview_message_fallback => 'Сообщение';

  @override
  String get video_circle_media_kind => 'видео';

  @override
  String reactions_rated_count(int count) {
    return 'Оценили: $count';
  }

  @override
  String reactions_today_time(String time) {
    return 'Сегодня, $time';
  }

  @override
  String get durak_create_timer_subtitle => 'По умолчанию 15 секунд';

  @override
  String get dm_game_banner_active => 'Партия \"Дурак\" идёт';

  @override
  String get dm_game_banner_created => 'Игра \"Дурак\" создана';

  @override
  String get chat_folder_favorites => 'Избранное';

  @override
  String get chat_folder_new => 'Новая';

  @override
  String get contact_profile_user_fallback => 'Пользователь';

  @override
  String contact_profile_error(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get conversation_threads_loading_title => 'Обсуждения';

  @override
  String get theme_label_light => 'Светлая';

  @override
  String get theme_label_dark => 'Тёмная';

  @override
  String get theme_label_auto => 'Авто';

  @override
  String get chat_draft_reply_fallback => 'Ответ';

  @override
  String get mention_default_label => 'Участник';

  @override
  String get contacts_fallback_name => 'Контакт';

  @override
  String get sticker_pack_default_name => 'Мой пак';

  @override
  String get profile_error_phone_taken =>
      'Этот номер телефона уже зарегистрирован. Укажите другой номер.';

  @override
  String get profile_error_email_taken =>
      'Этот email уже занят. Укажите другой адрес.';

  @override
  String get profile_error_username_taken =>
      'Этот логин уже занят. Выберите другой.';

  @override
  String get e2ee_banner_default_context => 'Сообщение';

  @override
  String e2ee_banner_encrypted_chat_web_only(String prefix) {
    return '$prefix в зашифрованный чат пока можно отправить только с веб‑клиента.';
  }

  @override
  String get chat_attachment_decrypt_error =>
      'Не удалось расшифровать вложение';

  @override
  String get mention_fallback_label => 'участник';

  @override
  String get mention_fallback_label_capitalized => 'Участник';

  @override
  String get meeting_speaking_label => 'Говорит';

  @override
  String meeting_local_you_suffix(String name) {
    return '$name (Вы)';
  }

  @override
  String get video_crop_title => 'Обрезка';

  @override
  String video_crop_load_error(String error) {
    return 'Не удалось загрузить видео: $error';
  }

  @override
  String get gif_section_recent => 'НЕДАВНИЕ';

  @override
  String get gif_section_trending => 'TRENDING';

  @override
  String get auth_create_account_title => 'Создать аккаунт';

  @override
  String yandex_sign_in_yandex_error(String error) {
    return 'Яндекс: $error';
  }

  @override
  String get call_status_missed => 'Пропущен';

  @override
  String get call_status_cancelled => 'Отменен';

  @override
  String get call_status_ended => 'Завершен';

  @override
  String get presence_offline => 'Не в сети';

  @override
  String get presence_online => 'В сети';

  @override
  String get dm_title_fallback => 'Чат';

  @override
  String get dm_title_partner_fallback => 'Собеседник';

  @override
  String get group_title_fallback => 'Групповой чат';

  @override
  String get block_call_viewer_blocked =>
      'Вы заблокировали этого пользователя. Звонок недоступен — разблокируйте в Профиль → Заблокированные.';

  @override
  String get block_call_partner_blocked =>
      'Пользователь ограничил с вами общение. Звонок недоступен.';

  @override
  String get block_call_unavailable => 'Звонок недоступен.';

  @override
  String get block_composer_viewer_blocked =>
      'Вы заблокировали этого пользователя. Отправка недоступна — разблокируйте в Профиль → Заблокированные.';

  @override
  String get block_composer_partner_blocked =>
      'Пользователь ограничил с вами общение. Отправка недоступна.';

  @override
  String get forward_group_fallback => 'Группа';

  @override
  String get forward_unknown_user => 'Неизвестный';

  @override
  String get live_location_once => 'Одноразово (только это сообщение)';

  @override
  String get live_location_5min => '5 минут';

  @override
  String get live_location_15min => '15 минут';

  @override
  String get live_location_30min => '30 минут';

  @override
  String get live_location_1hour => '1 час';

  @override
  String get live_location_2hours => '2 часа';

  @override
  String get live_location_6hours => '6 часов';

  @override
  String get live_location_1day => '1 день';

  @override
  String get live_location_forever => 'Навсегда (пока не отключу)';

  @override
  String get e2ee_send_too_many_files =>
      'Слишком много вложений для зашифрованной отправки: максимум 5 файлов за сообщение.';

  @override
  String get e2ee_send_too_large =>
      'Слишком большой общий размер вложений: максимум 96 МБ для одного зашифрованного сообщения.';

  @override
  String get presence_last_seen_prefix => 'Был(а) ';

  @override
  String get presence_less_than_minute_ago => 'менее минуты назад';

  @override
  String get presence_yesterday => 'вчера';

  @override
  String get dm_fallback_title => 'Чат';

  @override
  String get dm_fallback_partner => 'Собеседник';

  @override
  String get group_fallback_title => 'Групповой чат';

  @override
  String get block_send_viewer_blocked =>
      'Вы заблокировали этого пользователя. Отправка недоступна — разблокируйте в Профиль → Заблокированные.';

  @override
  String get block_send_partner_blocked =>
      'Пользователь ограничил с вами общение. Отправка недоступна.';

  @override
  String get mention_fallback_name => 'Участник';

  @override
  String get profile_conflict_phone =>
      'Этот номер телефона уже зарегистрирован. Укажите другой номер.';

  @override
  String get profile_conflict_email =>
      'Этот email уже занят. Укажите другой адрес.';

  @override
  String get profile_conflict_username =>
      'Этот логин уже занят. Выберите другой.';

  @override
  String get mention_fallback_participant => 'Участник';

  @override
  String get sticker_gif_recent => 'НЕДАВНИЕ';

  @override
  String get meeting_screen_sharing => 'Экран';

  @override
  String get meeting_speaking => 'Говорит';

  @override
  String auth_sign_in_failed(Object error) {
    return 'Не удалось войти: $error';
  }

  @override
  String yandex_error_prefix(Object error) {
    return 'Яндекс: $error';
  }

  @override
  String auth_error_prefix(Object error) {
    return 'Ошибка авторизации: $error';
  }

  @override
  String presence_minutes_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count минут назад',
      many: '$count минут назад',
      few: '$count минуты назад',
      one: '$count минуту назад',
    );
    return '$_temp0';
  }

  @override
  String presence_hours_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count часов назад',
      many: '$count часов назад',
      few: '$count часа назад',
      one: '$count час назад',
    );
    return '$_temp0';
  }

  @override
  String presence_days_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дней назад',
      many: '$count дней назад',
      few: '$count дня назад',
      one: '$count день назад',
    );
    return '$_temp0';
  }

  @override
  String presence_months_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count месяцев назад',
      many: '$count месяцев назад',
      few: '$count месяца назад',
      one: '$count месяц назад',
    );
    return '$_temp0';
  }

  @override
  String presence_years_months_ago(int years, int months) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years лет',
      many: '$years лет',
      few: '$years года',
      one: '$years год',
    );
    String _temp1 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months месяцев назад',
      many: '$months месяцев назад',
      few: '$months месяца назад',
      one: '$months месяц назад',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String presence_years_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count лет назад',
      many: '$count лет назад',
      few: '$count года назад',
      one: '$count год назад',
    );
    return '$_temp0';
  }

  @override
  String get wallpaper_gradient_purple => 'Фиолетовый';

  @override
  String get wallpaper_gradient_pink => 'Розовый';

  @override
  String get wallpaper_gradient_blue => 'Голубой';

  @override
  String get wallpaper_gradient_green => 'Зелёный';

  @override
  String get wallpaper_gradient_sunset => 'Закат';

  @override
  String get wallpaper_gradient_gentle => 'Нежный';

  @override
  String get wallpaper_gradient_lime => 'Лайм';

  @override
  String get wallpaper_gradient_graphite => 'Графит';

  @override
  String get sticker_tab_recent => 'НЕДАВНИЕ';

  @override
  String get block_call_you_blocked =>
      'Вы заблокировали этого пользователя. Звонок недоступен — разблокируйте в Профиль → Заблокированные.';

  @override
  String get block_call_they_blocked =>
      'Пользователь ограничил с вами общение. Звонок недоступен.';

  @override
  String get block_call_generic => 'Звонок недоступен.';

  @override
  String get block_send_you_blocked =>
      'Вы заблокировали этого пользователя. Отправка недоступна — разблокируйте в Профиль → Заблокированные.';

  @override
  String get block_send_they_blocked =>
      'Пользователь ограничил с вами общение. Отправка недоступна.';

  @override
  String get forward_unknown_fallback => 'Неизвестный';

  @override
  String get dm_title_chat => 'Чат';

  @override
  String get dm_title_partner => 'Собеседник';

  @override
  String get dm_title_group => 'Групповой чат';

  @override
  String get e2ee_too_many_attachments =>
      'Слишком много вложений для зашифрованной отправки: максимум 5 файлов за сообщение.';

  @override
  String get e2ee_total_size_exceeded =>
      'Слишком большой общий размер вложений: максимум 96 МБ для одного зашифрованного сообщения.';

  @override
  String composer_limit_too_many_files(int current, int max, int diff) {
    return 'Слишком много вложений: $current/$max. Удалите $diff, чтобы отправить.';
  }

  @override
  String composer_limit_total_size_exceeded(String currentMb, String maxMb) {
    return 'Слишком большой размер вложений: $currentMb МБ / $maxMb МБ. Удалите часть, чтобы отправить.';
  }

  @override
  String get composer_limit_blocking_send => 'Превышен лимит вложений';

  @override
  String yandex_sign_in_error_prefix(String error) {
    return 'Яндекс: $error';
  }

  @override
  String get meeting_participant_screen => 'Экран';

  @override
  String get meeting_participant_speaking => 'Говорит';

  @override
  String get nav_error_title => 'Ошибка навигации';

  @override
  String get nav_error_invalid_secret_compose =>
      'Некорректная навигация секретного чата';

  @override
  String get sign_in_title => 'Вход';

  @override
  String get sign_in_firebase_ready => 'Firebase инициализирован. Можно войти.';

  @override
  String get sign_in_firebase_not_ready =>
      'Firebase не готов. Проверьте логи и firebase_options.dart.';

  @override
  String get sign_in_continue => 'Продолжить';

  @override
  String get sign_in_anonymously => 'Войти анонимно';

  @override
  String sign_in_auth_error(String error) {
    return 'Ошибка авторизации: $error';
  }

  @override
  String generic_error(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get storage_label_video => 'Видео';

  @override
  String get storage_label_photo => 'Фото';

  @override
  String get storage_label_audio => 'Аудио';

  @override
  String get storage_label_files => 'Файлы';

  @override
  String get storage_label_other => 'Другое';

  @override
  String get storage_label_recent_stickers => 'Недавние стикеры';

  @override
  String get storage_label_giphy_search => 'GIPHY · поисковый кэш';

  @override
  String get storage_label_giphy_recent => 'GIPHY · недавние GIF';

  @override
  String get storage_chat_unattributed => 'Без привязки к чату';

  @override
  String storage_label_draft(String key) {
    return 'Черновик · $key';
  }

  @override
  String get storage_label_offline_snapshot => 'Офлайн-снимок списка чатов';

  @override
  String storage_label_profile_cache(String name) {
    return 'Кэш профиля · $name';
  }

  @override
  String get call_mini_end => 'Завершить звонок';

  @override
  String get animation_quality_lite => 'Лёгкий';

  @override
  String get animation_quality_balanced => 'Сбалансированный';

  @override
  String get animation_quality_cinematic => 'Кинематографический';

  @override
  String get crop_aspect_original => 'Оригинал';

  @override
  String get crop_aspect_square => 'Квадрат';

  @override
  String get push_notification_title => 'Разрешить уведомления';

  @override
  String get push_notification_rationale =>
      'Для входящих звонков приложению нужны уведомления.';

  @override
  String get push_notification_required =>
      'Включите уведомления для отображения входящих звонков.';

  @override
  String get push_notification_grant => 'Разрешить';

  @override
  String get push_call_accept => 'Принять';

  @override
  String get push_call_decline => 'Отклонить';

  @override
  String get push_channel_incoming_calls => 'Входящие звонки';

  @override
  String get push_channel_missed_calls => 'Пропущенные звонки';

  @override
  String get push_channel_messages_desc => 'Новые сообщения в чатах';

  @override
  String get push_channel_silent => 'Сообщения без звука';

  @override
  String get push_channel_silent_desc => 'Push без звука';

  @override
  String get push_caller_unknown => 'Кто-то';

  @override
  String get outbox_attachment_single => 'Вложение';

  @override
  String outbox_attachment_count(int count) {
    return 'Вложения ($count)';
  }

  @override
  String get bottom_nav_label_chats => 'Чаты';

  @override
  String get bottom_nav_label_contacts => 'Контакты';

  @override
  String get bottom_nav_label_conferences => 'Конференции';

  @override
  String get bottom_nav_label_calls => 'Звонки';

  @override
  String get welcomeBubbleTitle => 'Добро пожаловать в LighChat';

  @override
  String get welcomeBubbleSubtitle => 'Маяк зажёгся';

  @override
  String get welcomeSkip => 'Пропустить';

  @override
  String get welcomeReplayDebugTile => 'Replay welcome animation (debug)';

  @override
  String get sticker_scope_library => 'Библиотека';

  @override
  String get sticker_library_search_hint => 'Поиск стикеров…';

  @override
  String get account_menu_energy_saving => 'Энергосбережение';

  @override
  String get energy_saving_title => 'Энергосбережение';

  @override
  String get energy_saving_section_mode => 'Режим энергосбережения';

  @override
  String get energy_saving_section_resource_heavy => 'Ресурсоёмкие процессы';

  @override
  String get energy_saving_threshold_off => 'Выкл.';

  @override
  String get energy_saving_threshold_always => 'Вкл.';

  @override
  String get energy_saving_threshold_off_full => 'Никогда';

  @override
  String get energy_saving_threshold_always_full => 'Всегда';

  @override
  String energy_saving_threshold_at(int percent) {
    return 'При заряде менее $percent%';
  }

  @override
  String get energy_saving_hint_off =>
      'Ресурсоёмкие эффекты никогда не отключаются автоматически.';

  @override
  String get energy_saving_hint_always =>
      'Ресурсоёмкие эффекты всегда отключены, независимо от уровня заряда.';

  @override
  String energy_saving_hint_threshold(int percent) {
    return 'Автоматически отключать все ресурсоёмкие процессы при заряде менее $percent%.';
  }

  @override
  String energy_saving_current_battery(int percent) {
    return 'Текущий заряд: $percent%';
  }

  @override
  String get energy_saving_active_now => 'режим активен';

  @override
  String get energy_saving_active_threshold =>
      'Заряд достиг порога — все эффекты ниже временно отключены.';

  @override
  String get energy_saving_active_system =>
      'Включён системный режим энергосбережения — все эффекты ниже временно отключены.';

  @override
  String get energy_saving_autoplay_video_title => 'Автозапуск видео';

  @override
  String get energy_saving_autoplay_video_subtitle =>
      'Автозапуск и повторение видеосообщений и видео в чатах.';

  @override
  String get energy_saving_autoplay_gif_title => 'Автозапуск GIF';

  @override
  String get energy_saving_autoplay_gif_subtitle =>
      'Автозапуск и повторение GIF в чатах и на клавиатуре.';

  @override
  String get energy_saving_animated_stickers_title => 'Анимированные стикеры';

  @override
  String get energy_saving_animated_stickers_subtitle =>
      'Повторяющаяся анимация стикеров и полноэкранные эффекты Premium-стикеров.';

  @override
  String get energy_saving_animated_emoji_title => 'Анимированные эмодзи';

  @override
  String get energy_saving_animated_emoji_subtitle =>
      'Повторяющаяся анимация эмодзи в сообщениях, реакциях и статусах.';

  @override
  String get energy_saving_interface_animations_title => 'Анимации интерфейса';

  @override
  String get energy_saving_interface_animations_subtitle =>
      'Эффекты и анимации, которые делают LighChat плавнее и выразительнее.';

  @override
  String get energy_saving_media_preload_title => 'Предзагрузка медиа';

  @override
  String get energy_saving_media_preload_subtitle =>
      'Запуск загрузки медиафайлов при входе в список чатов.';

  @override
  String get energy_saving_background_update_title => 'Обновление в фоне';

  @override
  String get energy_saving_background_update_subtitle =>
      'Быстрое обновление чатов при переключении между приложениями.';

  @override
  String get legal_index_title => 'Юридические документы';

  @override
  String get legal_index_subtitle =>
      'Политика конфиденциальности, пользовательское соглашение и другие юридические документы, регулирующие использование LighChat.';

  @override
  String get legal_settings_section_title => 'Правовая информация';

  @override
  String get legal_settings_section_subtitle =>
      'Политика конфиденциальности, пользовательское соглашение, EULA и другие документы.';

  @override
  String get legal_not_found => 'Документ не найден';

  @override
  String get legal_title_privacy_policy => 'Политика конфиденциальности';

  @override
  String get legal_title_terms_of_service => 'Пользовательское соглашение';

  @override
  String get legal_title_cookie_policy => 'Политика использования cookies';

  @override
  String get legal_title_eula => 'Лицензионное соглашение (EULA)';

  @override
  String get legal_title_dpa => 'Соглашение об обработке данных (DPA)';

  @override
  String get legal_title_children => 'Политика в отношении несовершеннолетних';

  @override
  String get legal_title_moderation => 'Политика модерации контента';

  @override
  String get legal_title_aup => 'Правила допустимого использования';

  @override
  String get chat_list_item_sender_you => 'Вы';

  @override
  String get chat_preview_message => 'Сообщение';

  @override
  String get chat_preview_sticker => 'Стикер';

  @override
  String get chat_preview_attachment => 'Вложение';

  @override
  String get contacts_disclosure_title => 'Поиск знакомых в LighChat';

  @override
  String get contacts_disclosure_body =>
      'LighChat считывает телефонные номера и email-адреса из вашей адресной книги, хэширует их и сверяет с нашим сервером, чтобы показать, кто из ваших контактов уже пользуется приложением. Сами контакты нигде не сохраняются.';

  @override
  String get contacts_disclosure_allow => 'Разрешить';

  @override
  String get contacts_disclosure_deny => 'Не сейчас';

  @override
  String get report_title => 'Пожаловаться';

  @override
  String get report_subtitle_message => 'На сообщение';

  @override
  String get report_subtitle_user => 'На пользователя';

  @override
  String get report_reason_spam => 'Спам';

  @override
  String get report_reason_offensive => 'Оскорбительный контент';

  @override
  String get report_reason_violence => 'Насилие или угрозы';

  @override
  String get report_reason_fraud => 'Мошенничество';

  @override
  String get report_reason_other => 'Другое';

  @override
  String get report_comment_hint => 'Дополнительные сведения (необязательно)';

  @override
  String get report_submit => 'Отправить';

  @override
  String get report_success => 'Жалоба отправлена. Спасибо!';

  @override
  String get report_error => 'Не удалось отправить жалобу';

  @override
  String get message_menu_action_report => 'Пожаловаться';

  @override
  String get partner_profile_menu_report => 'Пожаловаться на пользователя';

  @override
  String get call_bubble_voice_call => 'Голосовой звонок';

  @override
  String get call_bubble_video_call => 'Видеозвонок';

  @override
  String get chat_preview_poll => 'Опрос';

  @override
  String get chat_preview_forwarded => 'Пересланное сообщение';

  @override
  String get birthday_banner_celebrates => 'празднует день рождения!';

  @override
  String get birthday_banner_action => 'Поздравить →';

  @override
  String get birthday_screen_title_today => 'День рождения сегодня';

  @override
  String birthday_screen_age(int age) {
    return '$age лет';
  }

  @override
  String get birthday_section_actions => 'ПОЗДРАВИТЬ';

  @override
  String get birthday_action_template => 'Готовое поздравление';

  @override
  String get birthday_action_cake => 'Задуть свечу';

  @override
  String get birthday_action_confetti => 'Конфетти';

  @override
  String get birthday_action_serpentine => 'Серпантин';

  @override
  String get birthday_action_voice => 'Записать аудио-поздравление';

  @override
  String get birthday_action_remind_next_year =>
      'Напомнить заранее в следующем году';

  @override
  String get birthday_action_open_chat => 'Написать своё поздравление';

  @override
  String get birthday_cake_prompt => 'Тапни по свече, чтобы её задуть';

  @override
  String birthday_cake_wish_placeholder(Object name) {
    return 'Какое желание загадать для $name?';
  }

  @override
  String get birthday_cake_wish_hint =>
      'Например: пусть всё задуманное сбудется…';

  @override
  String get birthday_cake_send => 'Отправить';

  @override
  String birthday_cake_message(Object name, Object wish) {
    return '🎂 С днём рождения, $name! Моё пожелание для тебя: «$wish»';
  }

  @override
  String birthday_confetti_message(Object name) {
    return '🎉 Поздравляю с днём рождения, $name! 🎉';
  }

  @override
  String birthday_template_1(Object name) {
    return 'С днём рождения, $name! Пусть этот год будет лучшим!';
  }

  @override
  String birthday_template_2(Object name) {
    return '$name, поздравляю! Желаю радости, тепла и исполнения желаний 🎉';
  }

  @override
  String birthday_template_3(Object name) {
    return 'С праздником, $name! Здоровья, удачи и побольше счастливых моментов 🎂';
  }

  @override
  String birthday_template_4(Object name) {
    return '$name, с днём рождения! Пусть всё задуманное сбывается легко и быстро ✨';
  }

  @override
  String birthday_template_5(Object name) {
    return 'Поздравляю, $name! Спасибо, что ты есть. С днём рождения! 🎁';
  }

  @override
  String get birthday_toast_sent => 'Поздравление отправлено';

  @override
  String birthday_reminder_set(Object name) {
    return 'Напомним за день до дня рождения $name';
  }

  @override
  String get birthday_reminder_notif_title => 'Завтра день рождения 🎂';

  @override
  String birthday_reminder_notif_body(Object name) {
    return 'Не забудьте поздравить $name завтра';
  }

  @override
  String get birthday_empty => 'Сегодня нет именинников среди контактов';

  @override
  String get birthday_error_self => 'Не удалось загрузить ваш профиль';

  @override
  String get birthday_error_send =>
      'Не удалось отправить поздравление. Попробуйте ещё раз.';

  @override
  String get birthday_error_reminder => 'Не удалось установить напоминание';

  @override
  String get chat_empty_title => 'Сообщений пока нет';

  @override
  String get chat_empty_subtitle =>
      'Напишите первое сообщение — хранитель маяка уже ждёт';

  @override
  String get chat_empty_quick_greet => 'Поздороваться 👋';
}
