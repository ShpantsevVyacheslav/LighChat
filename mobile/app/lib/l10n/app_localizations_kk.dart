// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class AppLocalizationsKk extends AppLocalizations {
  AppLocalizationsKk([String locale = 'kk']) : super(locale);

  @override
  String get secret_chat_title => 'Құпия чат';

  @override
  String get secret_chats_title => 'Құпия чаттар';

  @override
  String get secret_chat_locked_title => 'Құпия чат бұғатталған';

  @override
  String get secret_chat_locked_subtitle =>
      'Енгізіңіз PIN-код, небы открыть чат және посмотреть хабарламалар.';

  @override
  String get secret_chat_unlock_title => 'Ашу құпия чат';

  @override
  String get secret_chat_unlock_subtitle =>
      'Для открытия чаттың қажет PIN-код.';

  @override
  String get secret_chat_unlock_action => 'Ашу';

  @override
  String get secret_chat_set_pin_and_unlock => 'Орнату PIN және открыть';

  @override
  String get secret_chat_pin_label => 'PIN-код (4 цифры)';

  @override
  String get secret_chat_pin_invalid => 'Енгізіңіз 4 цифры';

  @override
  String get secret_chat_already_exists =>
      'Құпия чат этим пользователем уже существует.';

  @override
  String get secret_chat_exists_badge => 'Создан';

  @override
  String get secret_chat_unlock_failed => 'Сәтсіз открыть. Қайталап көріңіз.';

  @override
  String get secret_chat_action_not_allowed =>
      'Бұл әрекет запрещебірақ в секретном чатта';

  @override
  String get secret_chat_remember_pin => 'Запомнить PIN на этом құрылғыда';

  @override
  String get secret_chat_unlock_biometric => 'Ашу помощью биометрии';

  @override
  String get secret_chat_biometric_reason => 'Ашу құпия чат';

  @override
  String get secret_chat_biometric_no_saved_pin =>
      'Енгізіңіз PIN один раз, небы включить биометрию';

  @override
  String get secret_chat_ttl_title => 'Срок жизнжәне құпия чаттың';

  @override
  String get secret_chat_settings_title => 'Параметрлер құпия чаттың';

  @override
  String get secret_chat_settings_subtitle =>
      'Срок жизни, қолжетімділік және ограничения';

  @override
  String get secret_chat_settings_not_secret => 'Осы чат не является секретным';

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
      'Сколько действует қолжетімділік после открытия';

  @override
  String get secret_chat_settings_no_copy => 'Тыйым салу копирование';

  @override
  String get secret_chat_settings_no_forward => 'Тыйым салу пересылку';

  @override
  String get secret_chat_settings_no_save => 'Тыйым салу сохранение медиа';

  @override
  String get secret_chat_settings_screenshot_protection =>
      'Защита скриншотов (Android)';

  @override
  String get secret_chat_settings_media_views => 'Лимиты қаралым медиа';

  @override
  String get secret_chat_settings_media_views_subtitle =>
      'Best-effort лимиты қаралым у получатталя';

  @override
  String get secret_chat_media_type_image => 'Суреттер';

  @override
  String get secret_chat_media_type_video => 'Видео';

  @override
  String get secret_chat_media_type_voice => 'Голососізе';

  @override
  String get secret_chat_media_type_location => 'Локация';

  @override
  String get secret_chat_media_type_file => 'Файлдар';

  @override
  String get secret_chat_media_views_unlimited => 'Безлимит';

  @override
  String get secret_chat_compose_create => 'Құпия чат құру';

  @override
  String get secret_chat_compose_vault_pin_subtitle =>
      'Міндетті емес: 4-цифровой PIN для қолжетімділіка тізімге секретных чатов (сохраняется на құрылғыда для биометрии).';

  @override
  String get secret_chat_compose_require_unlock_pin =>
      'Требовать PIN пржәне открытижәне чаттың';

  @override
  String get secret_chat_settings_read_only_hint =>
      'Параметры задаются пржәне созданижәне және дальше не меняются.';

  @override
  String get secret_chat_settings_delete => 'Жою құпия чат';

  @override
  String get secret_chat_settings_delete_confirm_title => 'Жою осы құпия чат?';

  @override
  String get secret_chat_settings_delete_confirm_body =>
      'Хабарламалар және медиа будут удалены у обоих усағаттников.';

  @override
  String get privacy_secret_vault_title => 'Секретное қойма';

  @override
  String get privacy_secret_vault_subtitle =>
      'Глобальный PIN және биометрия для вжүріса в құпия чаттар.';

  @override
  String get privacy_secret_vault_change_pin =>
      'Орнату немесе сменить PIN храннемесеща';

  @override
  String get privacy_secret_vault_change_pin_subtitle =>
      'Еслжәне PIN уже бар, подтвердите старым PIN немесе биометрией.';

  @override
  String get privacy_secret_vault_bio_subtitle =>
      'Проверить биометрию және валидировать локальбірақ сохраненный PIN.';

  @override
  String get privacy_secret_vault_bio_reason =>
      'Подтвердите қолжетімділік секретным чаттыңм';

  @override
  String get privacy_secret_vault_current_pin => 'Текущий PIN';

  @override
  String get privacy_secret_vault_new_pin => 'Носізй PIN';

  @override
  String get privacy_secret_vault_repeat_pin => 'Повторите носізй PIN';

  @override
  String get privacy_secret_vault_pin_mismatch => 'PIN-кодтар не совпадают';

  @override
  String get privacy_secret_vault_pin_updated => 'PIN храннемесеща обновлен';

  @override
  String get privacy_secret_vault_bio_unavailable =>
      'Биометрия неқолжетімділікна на этом құрылғыда';

  @override
  String get privacy_secret_vault_bio_verified =>
      'Проверка биометрижәне пройдена';

  @override
  String get privacy_secret_vault_setup_required =>
      'Сначала настройте PIN немесе биометрию в разделе Құпиялылық.';

  @override
  String get privacy_secret_vault_network_timeout =>
      'Таймаут сети. Попробуйте снова.';

  @override
  String privacy_secret_vault_error(Object error) {
    return 'Қате секретного храннемесеща: $error';
  }

  @override
  String get tournament_title => 'Турнир';

  @override
  String get tournament_subtitle => 'Турнирная таблица және серижәне партий';

  @override
  String get tournament_new_game => 'Жаңа партия';

  @override
  String get tournament_standings => 'Таблица';

  @override
  String get tournament_standings_empty => 'Әзірге жоқ результатов';

  @override
  String get tournament_games => 'Партии';

  @override
  String get tournament_games_empty => 'Әзірге жоқ партий';

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
    return 'Сәтсіз создать турнир: $err';
  }

  @override
  String tournament_create_game_failed(Object err) {
    return 'Сәтсіз создать партию: $err';
  }

  @override
  String tournament_game_players(Object names) {
    return 'Ойыншылар: $names';
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
      'Собеседник создал лоббжәне «Дурак» — қосылу';

  @override
  String get durak_dm_lobby_open => 'Ашу лобби';

  @override
  String get conversation_game_lobby_cancel => 'Завершить ожидание';

  @override
  String conversation_game_lobby_cancel_failed(Object err) {
    return 'Сәтсіз завершить ожидание: $err';
  }

  @override
  String secret_chat_media_views_count(Object count) {
    return '$count қаралым';
  }

  @override
  String secret_chat_settings_load_failed(Object error) {
    return 'Сәтсіз загрузить: $error';
  }

  @override
  String secret_chat_settings_save_failed(Object error) {
    return 'Сәтсіз сохранить: $error';
  }

  @override
  String get secret_chat_settings_reset_strict => 'Сброс строгим настройкам';

  @override
  String get secret_chat_settings_reset_strict_subtitle =>
      'Қосулыючит барлығы запреты және установит лимит қаралым медиа = 1';

  @override
  String get settings_language_title => 'Тіл';

  @override
  String get settings_language_system => 'Системный';

  @override
  String get settings_language_ru => 'Русский';

  @override
  String get settings_language_en => 'English';

  @override
  String get settings_language_hint_system =>
      'Пржәне сізборе «Системный» тіл соответствует настройкам құрылғылар.';

  @override
  String get account_menu_profile => 'Профиль';

  @override
  String get account_menu_features => 'Возможности';

  @override
  String get account_menu_chat_settings => 'Параметрлер чатов';

  @override
  String get account_menu_notifications => 'Хабарландырулар';

  @override
  String get account_menu_privacy => 'Құпиялылық';

  @override
  String get account_menu_devices => 'Құрылғылар';

  @override
  String get account_menu_blacklist => 'Черный тізім';

  @override
  String get account_menu_language => 'Тіл';

  @override
  String get account_menu_storage => 'Қойма';

  @override
  String get account_menu_theme => 'Солқырып';

  @override
  String get account_menu_sign_out => 'Шығу';

  @override
  String get storage_settings_title => 'Қойма';

  @override
  String get storage_settings_subtitle =>
      'Управляйте локальным кэшем на құрылғыда: не хранить, не чистить және сколько места сізделять.';

  @override
  String get storage_settings_total_label => 'Бос емес на құрылғыда';

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
  String get storage_settings_policy_title => 'Не хранить локально';

  @override
  String get storage_settings_budget_slider_title => 'Лимит кэша';

  @override
  String get storage_settings_breakdown_title => 'Разбивка по типам';

  @override
  String get storage_settings_breakdown_empty => 'Локальный кэш әзірге пуст.';

  @override
  String get storage_settings_chats_title => 'Разбивка по чаттыңм';

  @override
  String get storage_settings_chats_empty =>
      'Әзірге жоқ кэша, привязанного чаттыңм.';

  @override
  String storage_settings_chat_subtitle(Object count, Object size) {
    return '$count элементов · $size';
  }

  @override
  String get storage_settings_general_title => 'Кэш без привязкжәне чатқа';

  @override
  String get storage_settings_general_hint =>
      'Записи, которые сәтсіз однозначбірақ связать конкретным чатом (legacy/глобальный кэш).';

  @override
  String get storage_settings_general_empty => 'Общий кэш пуст.';

  @override
  String get storage_settings_chat_files_empty =>
      'Локальных файлов для этого чаттың әзірге жоқ.';

  @override
  String get storage_settings_clear_chat_action => 'Очистить кэш чаттың';

  @override
  String get storage_settings_clear_all_title => 'Очистить локальный кэш?';

  @override
  String get storage_settings_clear_all_body =>
      'Будут удалены кэшированные файлдар, превью, черновикжәне және офлайн-снимкжәне тізімнің чатов на этом құрылғыда.';

  @override
  String storage_settings_clear_chat_title(Object chat) {
    return 'Очистить кэш «$chat»?';
  }

  @override
  String get storage_settings_clear_chat_body =>
      'Удалится только локальный кэш этого чаттың. Облачные хабарламалар не затрагиваются.';

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
      'Сәтсіз собрать статистику храннемесеща';

  @override
  String get storage_category_e2ee_media => 'E2EE медиа-кэш';

  @override
  String get storage_category_e2ee_media_subtitle =>
      'Расшифрованные медиа секретных чатов для быстрого повторного открытия.';

  @override
  String get storage_category_e2ee_text => 'E2EE текст-кэш';

  @override
  String get storage_category_e2ee_text_subtitle =>
      'Расшифрованный текст хабарламалар по чаттыңм для мгновенного рендера.';

  @override
  String get storage_category_drafts => 'Черновикжәне хабарламалар';

  @override
  String get storage_category_drafts_subtitle =>
      'Неотправленные черновикжәне по чаттыңм.';

  @override
  String get storage_category_chat_list_snapshot => 'Офлайн-тізім чатов';

  @override
  String get storage_category_chat_list_snapshot_subtitle =>
      'Соңғы снимок тізімнің чатов для быстрого старта без сети.';

  @override
  String get storage_category_profile_cards => 'Мини-кэш профилей';

  @override
  String get storage_category_profile_cards_subtitle =>
      'Имена және аватары для ускорения интерфейса.';

  @override
  String get storage_category_video_downloads => 'Кэш загруженных видео';

  @override
  String get storage_category_video_downloads_subtitle =>
      'Локальные копижәне видео из просмотрщика медиа.';

  @override
  String get storage_category_video_thumbs => 'Превью-кадры видео';

  @override
  String get storage_category_video_thumbs_subtitle =>
      'Сгенерированные персізе кадры для видео.';

  @override
  String get storage_category_chat_images => 'Фото в чаттыңх';

  @override
  String get storage_category_chat_images_subtitle =>
      'Кэшированные фотографижәне және стикеры из открытых чатов.';

  @override
  String get storage_category_stickers_gifs_emoji => 'Стикерлер, GIF, эмодзи';

  @override
  String get storage_category_stickers_gifs_emoji_subtitle =>
      'Соңғы стикерлер мен GIPHY кэші (gif/sticker/animated emoji).';

  @override
  String get storage_category_network_images => 'Желідегі сурет кэші';

  @override
  String get storage_category_network_images_subtitle =>
      'Аватарлар, превьюлер және желіден жүктелген басқа суреттер (libCachedImageData).';

  @override
  String get storage_media_type_video => 'Видео';

  @override
  String get storage_media_type_photo => 'Фотографии';

  @override
  String get storage_media_type_audio => 'Аудио';

  @override
  String get storage_media_type_files => 'Файлдар';

  @override
  String get storage_media_type_other => 'Басқа';

  @override
  String storage_settings_device_usage(Object pct) {
    return 'Занимает $pct% лимита кэша';
  }

  @override
  String get storage_settings_clear_all_hint =>
      'Барлығы медиа останутся в облаке. Пржәне необжүрісимостжәне сіз сможете загрузить их снова.';

  @override
  String get storage_settings_categories_title => 'Санат бойынша';

  @override
  String storage_settings_clear_category_title(String category) {
    return '«$category» тазалау керек пе?';
  }

  @override
  String storage_settings_clear_category_body(String size) {
    return '$size шамасында орын босайды. Бұл әрекетті қайтару мүмкін емес.';
  }

  @override
  String get storage_auto_delete_title => 'Автоудаление кэшированных медиа';

  @override
  String get storage_auto_delete_personal => 'Личные чаттар';

  @override
  String get storage_auto_delete_groups => 'Топтар';

  @override
  String get storage_auto_delete_never => 'Ешқашан';

  @override
  String get storage_auto_delete_3_days => '3 күн';

  @override
  String get storage_auto_delete_1_week => '1 нед.';

  @override
  String get storage_auto_delete_1_month => '1 ай';

  @override
  String get storage_auto_delete_3_months => '3 ай';

  @override
  String get storage_auto_delete_hint =>
      'Фотографии, видео және басқа файлдар, которые сіз не открывалжәне в течение этого срока, будут удалены құрылғылар для экономижәне места.';

  @override
  String storage_chat_detail_share(Object pct) {
    return 'На осы чат прижүрісится $pct% кэша';
  }

  @override
  String get storage_chat_detail_media_tab => 'Медиа';

  @override
  String get storage_chat_detail_select_all => 'Сізбрать барлығы';

  @override
  String get storage_chat_detail_deselect_all => 'Снять барлығы';

  @override
  String storage_chat_detail_clear_button(Object size) {
    return 'Очистить кэш $size';
  }

  @override
  String get storage_chat_detail_clear_button_empty =>
      'Сізберите файлдар для удаления';

  @override
  String get storage_chat_detail_tab_empty => 'В этой вкладке ничего жоқ.';

  @override
  String get storage_chat_detail_delete_title => 'Жою сізбранные файлдар?';

  @override
  String storage_chat_detail_delete_body(Object count, Object size) {
    return '$count файлов ($size) болады удалебірақ құрылғылар. Облачные копижәне не затрагиваются.';
  }

  @override
  String get profile_delete_account => 'Жою аккаунт';

  @override
  String get profile_delete_account_confirm_title =>
      'Жою аккаунт безвозвратно?';

  @override
  String get profile_delete_account_confirm_body =>
      'Сіздің аккаунт болады удалён из Firebase Auth және барлығы сіздіңжәне құжаттар в Firestore будут удалены без возможностжәне восстановления. У собеседников останутся сіздіңжәне чаттар в режиме только чтение.';

  @override
  String get profile_delete_account_confirm_action => 'Жою аккаунт';

  @override
  String profile_delete_account_error(Object error) {
    return 'Сәтсіз удалить аккаунт: $error';
  }

  @override
  String get chat_readonly_deleted_user =>
      'Аккаунт удалён. Чат қолжетімділікен только для чтения.';

  @override
  String get blacklist_empty => 'Жоқ бұғатталғанных пользователей';

  @override
  String get blacklist_action_unblock => 'Бұғаттан шығару';

  @override
  String get blacklist_unblock_confirm_title => 'Бұғаттан шығару?';

  @override
  String get blacklist_unblock_confirm_body =>
      'Пользователь снова сможет писать вам (еслжәне политика контактілер позволит) және видеть сіздің профиль в поиске.';

  @override
  String get blacklist_unblock_success => 'Пользователь разблокирован';

  @override
  String blacklist_unblock_error(Object error) {
    return 'Сәтсіз бұғаттан шығару: $error';
  }

  @override
  String get partner_profile_block_confirm_title => 'Бұғаттау пользователя?';

  @override
  String get partner_profile_block_confirm_body =>
      'Он не увидит чат вами, не сможет найтжәне вас в поиске және добавить в контактілер. У него сіз пропадёте из контактілер. Сіз сохраните переписку, бірақ не сможете писать ему, әзірге он в тізімде бұғатталғанных.';

  @override
  String get partner_profile_block_action => 'Бұғаттау';

  @override
  String get partner_profile_block_success => 'Пользователь бұғатталған';

  @override
  String partner_profile_block_error(Object error) {
    return 'Сәтсіз бұғаттау: $error';
  }

  @override
  String get common_soon => 'Скоро';

  @override
  String common_theme_prefix(Object label) {
    return 'Солқырып: $label';
  }

  @override
  String common_error_cannot_save_theme(Object error) {
    return 'Сәтсіз сохранить тему: $error';
  }

  @override
  String common_error_cannot_sign_out(Object error) {
    return 'Сәтсіз сізйти: $error';
  }

  @override
  String account_error_profile(Object error) {
    return 'Қате профиля: $error';
  }

  @override
  String get notifications_title => 'Хабарландырулар';

  @override
  String get notifications_section_main => 'Основные';

  @override
  String get notifications_mute_all_title => 'Отключить барлығы';

  @override
  String get notifications_mute_all_subtitle =>
      'Полностью сізключить хабарландырулар.';

  @override
  String get notifications_sound_title => 'Дыбыс';

  @override
  String get notifications_sound_subtitle =>
      'Воспроизводить дыбыс пржәне новом хабарламада.';

  @override
  String get notifications_preview_title => 'Предпросмотр';

  @override
  String get notifications_preview_subtitle =>
      'Показывать текст хабарламалар в уведомлении.';

  @override
  String get notifications_section_quiet_hours => 'Тихие сағаты';

  @override
  String get notifications_quiet_hours_subtitle =>
      'Хабарландырулар не будут беспокоить в указанный период.';

  @override
  String get notifications_quiet_hours_enable_title => 'Қосу тихие сағаты';

  @override
  String get notifications_reset_button => 'Сбросить настройки';

  @override
  String notifications_error_cannot_save(Object error) {
    return 'Сәтсіз сохранить настройки: $error';
  }

  @override
  String notifications_error_load(Object error) {
    return 'Қате загрузкжәне хабарландырулар: $error';
  }

  @override
  String get privacy_title => 'Приватность чаттың';

  @override
  String privacy_error_cannot_save(Object error) {
    return 'Сәтсіз сохранить настройки: $error';
  }

  @override
  String privacy_error_load(Object error) {
    return 'Қате загрузкжәне конфиденциальности: $error';
  }

  @override
  String get privacy_e2ee_section => 'Сквозное шифрлау';

  @override
  String get privacy_e2ee_enable_for_all_chats =>
      'Қосу шифрлау (E2E) для барлығых чатов';

  @override
  String get privacy_e2ee_what_encrypt => 'Не шифруем в E2EE чаттыңх';

  @override
  String get privacy_e2ee_text => 'Текст хабарламалар';

  @override
  String get privacy_e2ee_media => 'Вложения (медиа/файлдар)';

  @override
  String get privacy_my_devices_title => 'Можәне құрылғылар';

  @override
  String get privacy_my_devices_subtitle =>
      'Тізім құрылғылар опубликованным ключом. Переименовать немесе отозвать.';

  @override
  String get privacy_key_backup_title =>
      'Резервное копирование және передача ключа';

  @override
  String get privacy_key_backup_subtitle =>
      'Құру backup паролем немесе передать ключ другому құрылғыға по QR.';

  @override
  String get privacy_visibility_section => 'Видимость';

  @override
  String get privacy_online_title => 'Мәртебе онлайн';

  @override
  String get privacy_online_subtitle =>
      'Басқа пользователжәне видят, не сіз в сети.';

  @override
  String get privacy_last_seen_title => 'Соңғы визит';

  @override
  String get privacy_last_seen_subtitle =>
      'Показывать время последнего посещения.';

  @override
  String get privacy_read_receipts_title => 'Индикатор прочтения';

  @override
  String get privacy_read_receipts_subtitle =>
      'Показывать отправителям, не сіз прочиталжәне хабарлама.';

  @override
  String get privacy_group_invites_section => 'Шақырулар в топтар';

  @override
  String get privacy_group_invites_subtitle =>
      'Кім мүмкін добавлять вас в групповой чат.';

  @override
  String get privacy_group_invites_everyone => 'Барлығы пользователи';

  @override
  String get privacy_group_invites_contacts => 'Только контактілер';

  @override
  String get privacy_group_invites_nobody => 'Ешкім';

  @override
  String get privacy_global_search_section => 'Іздеу собеседников';

  @override
  String get privacy_global_search_subtitle =>
      'Кім мүмкін найтжәне вас по именжәне среджәне барлығых пользователей приложения.';

  @override
  String get privacy_global_search_title => 'Глобальный поиск';

  @override
  String get privacy_global_search_hint =>
      'Еслжәне сізключено, сіз не отображаетесь в тізімде «Барлығы пользователи» пржәне созданижәне чаттың. В блоке «Контактілер» сіз по-прежнему видны тем, кім добавил вас в контактілер.';

  @override
  String get privacy_profile_for_others_section => 'Профиль для других';

  @override
  String get privacy_profile_for_others_subtitle =>
      'Не показывать в карточке контакта және в профиле из беседы.';

  @override
  String get privacy_email_subtitle => 'Адрес почты в профиле собеседника.';

  @override
  String get privacy_phone_title => 'Телефон нөмірі';

  @override
  String get privacy_phone_subtitle =>
      'В профиле және в тізімде контактілер у других.';

  @override
  String get privacy_birthdate_title => 'Жәнеәсол рождения';

  @override
  String get privacy_birthdate_subtitle => 'Поле «День рождения» в профиле.';

  @override
  String get privacy_about_title => 'О себе';

  @override
  String get privacy_about_subtitle => 'Текст биографижәне в профиле.';

  @override
  String get privacy_reset_button => 'Сбросить настройки';

  @override
  String get common_cancel => 'Болдырмау';

  @override
  String get common_create => 'Құру';

  @override
  String get common_delete => 'Жою';

  @override
  String get common_choose => 'Сізбрать';

  @override
  String get common_save => 'Сақтау';

  @override
  String get common_close => 'Жабу';

  @override
  String get common_nothing_found => 'Ничего не найдено';

  @override
  String get common_retry => 'Қайталап көру';

  @override
  String get auth_login_email_label => 'Электрондық пошта';

  @override
  String get auth_login_password_label => 'Құпиясөз';

  @override
  String get auth_login_password_hint => 'Құпиясөз';

  @override
  String get auth_login_sign_in => 'Кіру';

  @override
  String get auth_login_forgot_password => 'Забылжәне құпиясөз?';

  @override
  String get auth_login_error_enter_email_for_reset =>
      'Енгізіңіз email для восстановления пароля';

  @override
  String get profile_title => 'Профиль';

  @override
  String get profile_edit_tooltip => 'Өңдеу';

  @override
  String get profile_full_name_label => 'ФИО';

  @override
  String get profile_full_name_hint => 'Аты';

  @override
  String get profile_username_label => 'Логин';

  @override
  String get profile_email_label => 'Электрондық пошта';

  @override
  String get profile_phone_label => 'Телефон';

  @override
  String get profile_birthdate_label => 'Жәнеәсол рождения';

  @override
  String get profile_about_label => 'О себе';

  @override
  String get profile_about_hint => 'Кратко о себе';

  @override
  String get profile_password_toggle_show => 'Өзгерту құпиясөз';

  @override
  String get profile_password_toggle_hide => 'Скрыть смену пароля';

  @override
  String get profile_password_new_label => 'Носізй құпиясөз';

  @override
  String get profile_password_confirm_label => 'Повторите құпиясөз';

  @override
  String get profile_password_tooltip_show => 'Показать құпиясөз';

  @override
  String get profile_password_tooltip_hide => 'Скрыть';

  @override
  String get profile_placeholder_username => 'пайдаланушы аты';

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
      'Заполните носізй құпиясөз және повтор.';

  @override
  String get settings_chats_title => 'Параметрлер чатов';

  @override
  String get settings_chats_preview => 'Предпросмотр';

  @override
  String get settings_chats_outgoing => 'Исжүрісящие хабарламалар';

  @override
  String get settings_chats_incoming => 'Вжүрісящие хабарламалар';

  @override
  String get settings_chats_font_size => 'Өлшем шрифта';

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
  String get settings_chats_chat_background => 'Фон чаттың';

  @override
  String get settings_chats_chat_background_pick_hint =>
      'Сізберите фото из галережәне немесе настройте';

  @override
  String get settings_chats_advanced => 'Дополнительно';

  @override
  String get settings_chats_show_time => 'Показывать время';

  @override
  String get settings_chats_show_time_subtitle =>
      'Время отправкжәне под хабарламаларми';

  @override
  String get settings_chats_reset => 'Сбросить настройки';

  @override
  String settings_chats_error_cannot_save(Object error) {
    return 'Сәтсіз сохранить: $error';
  }

  @override
  String settings_chats_error_wallpaper_load(Object error) {
    return 'Қате загрузкжәне фона: $error';
  }

  @override
  String settings_chats_error_wallpaper_delete(Object error) {
    return 'Қате удаления фона: $error';
  }

  @override
  String get settings_chats_wallpaper_delete_confirm_title => 'Жою фон?';

  @override
  String get settings_chats_wallpaper_delete_confirm_body =>
      'Осы фон болады удалён из сіздіңего тізімнің.';

  @override
  String settings_chats_icon_picker_title(Object label) {
    return 'Иконка: «$label»';
  }

  @override
  String get settings_chats_icon_picker_search_hint => 'Іздеу по названию…';

  @override
  String get settings_chats_icon_color => 'Цвет иконки';

  @override
  String get settings_chats_reset_icon_size => 'Сбросить өлшем';

  @override
  String get settings_chats_reset_icon_stroke => 'Сбросить толщину';

  @override
  String get settings_chats_tile_background => 'Фон плиткжәне под иконкой';

  @override
  String get settings_chats_default_gradient => 'Градиент по умолчанию';

  @override
  String get settings_chats_inherit_global => 'Наследовать глобальных';

  @override
  String get settings_chats_no_background => 'Без фона';

  @override
  String get settings_chats_no_background_on => 'Без фона (вкл.)';

  @override
  String get chat_list_title => 'Чаттар';

  @override
  String get chat_list_search_hint => 'Іздеу…';

  @override
  String get chat_list_loading_connecting => 'Қосылуда аккаунту…';

  @override
  String get chat_list_loading_conversations => 'Жүктелуде бесед…';

  @override
  String get chat_list_loading_list => 'Жүктелуде тізімнің чатов…';

  @override
  String get chat_list_loading_sign_out => 'Сізжүріс…';

  @override
  String get chat_list_empty_search_title => 'Чаттар не найдены';

  @override
  String get chat_list_empty_search_body =>
      'Попробуйте изменить запрос. Іздеу работает по именжәне пользователя және логину.';

  @override
  String get chat_list_empty_folder_title => 'В этой папке әзірге бос';

  @override
  String get chat_list_empty_folder_body =>
      'Переключитесь на другую папку немесе создайте носізй чат через кнопку вверху.';

  @override
  String get chat_list_empty_all_title => 'Әзірге жоқ чатов';

  @override
  String get chat_list_empty_all_body =>
      'Создайте носізй чат, небы начать переписку.';

  @override
  String get chat_list_action_new_folder => 'Жаңа папка';

  @override
  String get chat_list_action_new_chat => 'Носізй чат';

  @override
  String get chat_list_action_create => 'Құру';

  @override
  String get chat_list_action_close => 'Жабу';

  @override
  String get chat_list_folders_title => 'Папки';

  @override
  String get chat_list_folders_subtitle =>
      'Сізберите папкжәне для этого чаттың.';

  @override
  String get chat_list_folders_empty => 'Әзірге жоқ кастомных папок.';

  @override
  String get chat_list_create_folder_title => 'Жаңа папка';

  @override
  String get chat_list_create_folder_subtitle =>
      'Создайте папку для быстрой фильтрацижәне чатов.';

  @override
  String get chat_list_create_folder_name_label => 'НАЗВАНИЕ ПАПКИ';

  @override
  String get chat_list_create_folder_name_hint => 'Қалта атауы';

  @override
  String chat_list_create_folder_chats_label(Object count) {
    return 'ЧАТЫ ($count)';
  }

  @override
  String get chat_list_create_folder_select_all => 'Таңдау ВСЁ';

  @override
  String get chat_list_create_folder_reset => 'СБРОСИТЬ';

  @override
  String get chat_list_create_folder_search_hint => 'Іздеу по названию…';

  @override
  String get chat_list_create_folder_no_matches =>
      'Поджүрісящие чаттар не найдены';

  @override
  String get chat_list_folder_default_starred => 'Таңдаулылар';

  @override
  String get chat_list_folder_default_all => 'Барлығы';

  @override
  String get chat_list_folder_default_new => 'Носізе';

  @override
  String get chat_list_folder_default_direct => 'Личные';

  @override
  String get chat_list_folder_default_groups => 'Топтар';

  @override
  String get chat_list_yesterday => 'Кеше';

  @override
  String get chat_list_folder_delete_action => 'Жою';

  @override
  String get chat_list_folder_delete_title => 'Жою папку?';

  @override
  String chat_list_folder_delete_body(Object name) {
    return 'Папка \"$name\" болады удалена. Чаттар останутся на месте.';
  }

  @override
  String chat_list_error_open_starred(Object error) {
    return 'Сәтсіз открыть Таңдаулылар: $error';
  }

  @override
  String chat_list_error_delete_folder(Object error) {
    return 'Сәтсіз удалить папку: $error';
  }

  @override
  String get chat_list_pin_not_available =>
      'В этой папке закрепление неқолжетімділікно.';

  @override
  String chat_list_pin_pinned_in_folder(Object name) {
    return 'Чат закреплен в папке \"$name\"';
  }

  @override
  String chat_list_pin_unpinned_in_folder(Object name) {
    return 'Чат откреплен из папкжәне \"$name\"';
  }

  @override
  String chat_list_error_toggle_pin(Object error) {
    return 'Сәтсіз изменить закрепление: $error';
  }

  @override
  String chat_list_error_update_folder(Object error) {
    return 'Сәтсіз жаңарту папку: $error';
  }

  @override
  String get chat_list_clear_history_title => 'Очистить историю?';

  @override
  String get chat_list_clear_history_body =>
      'Хабарламалар исчезнут только из сіздіңего окна чаттың. У собеседника история останется.';

  @override
  String get chat_list_clear_history_confirm => 'Тазалау';

  @override
  String chat_list_error_clear_history(Object error) {
    return 'Сәтсіз очистить историю: $error';
  }

  @override
  String chat_list_error_mark_read(Object error) {
    return 'Сәтсіз пометить чат қалай прочитанный: $error';
  }

  @override
  String get chat_list_delete_chat_title => 'Чатты жою?';

  @override
  String get chat_list_delete_chat_body =>
      'Переписка болады безвозвратбірақ удалена для барлығых усағаттников. Бұл әрекет болмайды отменить.';

  @override
  String get chat_list_delete_chat_confirm => 'Жою';

  @override
  String chat_list_error_delete_chat(Object error) {
    return 'Сәтсіз удалить чат: $error';
  }

  @override
  String get chat_list_context_folders => 'Папки';

  @override
  String get chat_list_context_unpin => 'Босату чат';

  @override
  String get chat_list_context_pin => 'Бекіту чат';

  @override
  String get chat_list_context_mark_all_read => 'Оқу барлығы';

  @override
  String get chat_list_context_clear_history => 'Очистить историю';

  @override
  String get chat_list_context_delete_chat => 'Чатты жою';

  @override
  String get chat_list_snackbar_history_cleared => 'История очищена.';

  @override
  String get chat_list_snackbar_marked_read => 'Чат помечен қалай прочитанный.';

  @override
  String chat_list_error_generic(Object error) {
    return 'Қате: $error';
  }

  @override
  String get chat_calls_title => 'Қоңыраулар';

  @override
  String get chat_calls_search_hint => 'Іздеу по имени…';

  @override
  String get chat_calls_empty => 'История звонков пуста.';

  @override
  String get chat_calls_nothing_found => 'Ничего не найдено.';

  @override
  String chat_calls_error_load(Object error) {
    return 'Сәтсіз загрузить қоңыраулар:\n$error';
  }

  @override
  String get chat_reply_cancel_tooltip => 'Болдырмау ответ';

  @override
  String get voice_preview_tooltip_cancel => 'Болдырмау';

  @override
  String get voice_preview_tooltip_send => 'Жіберу';

  @override
  String get profile_qr_title => 'Мой QR-код';

  @override
  String get profile_qr_tooltip_close => 'Жабу';

  @override
  String get profile_qr_share_title => 'Мой профиль в LighChat';

  @override
  String get profile_qr_share_subject => 'LighChat профилі';

  @override
  String chat_media_norm_pending_title(Object mediaKind) {
    return 'Обрабатываем $mediaKind…';
  }

  @override
  String chat_media_norm_failed_title(Object mediaKind) {
    return 'Сәтсіз обработать $mediaKind';
  }

  @override
  String get chat_media_norm_pending_subtitle =>
      'Файл станет қолжетімділікен после серверной нормализации.';

  @override
  String get chat_media_norm_failed_subtitle =>
      'Попробуйте запустить обработку повторно.';

  @override
  String get conversation_threads_title => 'Обсуждения';

  @override
  String get conversation_threads_empty => 'Жоқ обсуждений';

  @override
  String get conversation_threads_root_attachment => 'Вложение';

  @override
  String get conversation_threads_root_message => 'Хабарлама';

  @override
  String conversation_threads_snippet_you(Object text) {
    return 'Сіз: $text';
  }

  @override
  String get conversation_threads_day_today => 'Бүгін';

  @override
  String get conversation_threads_day_yesterday => 'Кеше';

  @override
  String conversation_threads_replies_badge(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count жауап',
      one: '$count жауап',
    );
    return '$_temp0';
  }

  @override
  String get chat_meetings_title => 'Видеокездесулер';

  @override
  String get chat_meetings_subtitle =>
      'Создавайте конференцижәне және управляйте қолжетімділіком усағаттников';

  @override
  String get chat_meetings_section_new => 'Жаңа кездесу';

  @override
  String get chat_meetings_field_title_label => 'Название кездесулер';

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
  String get chat_meetings_duration_1h => '1 сағат';

  @override
  String get chat_meetings_duration_90m => '1,5 сағат';

  @override
  String get chat_meetings_field_access_label => 'Тип қолжетімділіка';

  @override
  String get chat_meetings_access_private => 'Закрытая';

  @override
  String get chat_meetings_access_public => 'Открытая';

  @override
  String get chat_meetings_waiting_room_title => 'Зал ожидания';

  @override
  String get chat_meetings_waiting_room_desc =>
      'В режиме зала ожидания сіз полностью контролируете тізім усағаттников. Әзірге сіз не нажмёте «Қабылдау», гость болады видеть экран ожидания.';

  @override
  String get chat_meetings_backgrounds_title => 'Виртуальные фоны';

  @override
  String get chat_meetings_backgrounds_desc =>
      'Загружайте фоны және размывайте задний план пржәне желании. Сурет из галереи. Также қолжетімділікна загрузка собственных фонов.';

  @override
  String get chat_meetings_create_button => 'Кездесу құру';

  @override
  String get chat_meetings_snackbar_enter_title =>
      'Укажите название кездесулер';

  @override
  String get chat_meetings_snackbar_auth_required =>
      'Нужна авторизация для создания кездесулер';

  @override
  String chat_meetings_error_create_failed(Object error) {
    return 'Сәтсіз создать встречу: $error';
  }

  @override
  String get chat_meetings_history_title => 'Сіздіңа история';

  @override
  String get chat_meetings_history_empty => 'История встреч пуста';

  @override
  String chat_meetings_history_error(Object error) {
    return 'Сәтсіз загрузить историю встреч: $error';
  }

  @override
  String get chat_meetings_status_live => 'идёт';

  @override
  String get chat_meetings_status_finished => 'завершена';

  @override
  String get chat_meetings_badge_private => 'закрытая';

  @override
  String get chat_contacts_search_hint => 'Іздеу контактілер...';

  @override
  String get chat_contacts_permission_denied =>
      'Қолжетімділік контактам не предоставлен.';

  @override
  String chat_contacts_sync_error(Object error) {
    return 'Қате синхронизацижәне контактілер: $error';
  }

  @override
  String chat_contacts_invite_prepare_failed(Object error) {
    return 'Сәтсіз подготовить шақыру: $error';
  }

  @override
  String get chat_contacts_matches_not_found => 'Совпадений не найдено.';

  @override
  String chat_contacts_added_count(Object count) {
    return 'Қосылды контактілер: $count.';
  }

  @override
  String get chat_contacts_invite_text =>
      'Поставь LighChat: https://lighchat.online\nПриглашаю тебя в LighChat — вот сілтеме на установку.';

  @override
  String get chat_contacts_invite_subject => 'Шақыру в LighChat';

  @override
  String chat_contacts_error_load(Object error) {
    return 'Қате загрузкжәне контактілер: $error';
  }

  @override
  String chat_list_item_draft_line(Object line) {
    return 'Черновик · $line';
  }

  @override
  String get chat_list_item_chat_created => 'Чат создан';

  @override
  String get chat_list_item_no_messages_yet => 'Әзірге жоқ хабарламалар';

  @override
  String get chat_list_item_history_cleared => 'История очищена';

  @override
  String get chat_list_firebase_not_configured => 'Firebase ещё не бапталды.';

  @override
  String get new_chat_title => 'Носізй чат';

  @override
  String get new_chat_subtitle =>
      'Сізберите пользователя, небы начать диалог, немесе создайте топты.';

  @override
  String get new_chat_search_hint => 'Аты, ник немесе @username…';

  @override
  String get new_chat_create_group => 'Топ құру';

  @override
  String get new_chat_section_phone_contacts => 'КОНТАКТЫ ТЕЛЕФОНА';

  @override
  String get new_chat_section_contacts => 'КОНТАКТЫ';

  @override
  String get new_chat_section_all_users => 'ВСЕ ПОЛЬЗОВАТЕЛИ';

  @override
  String get new_chat_empty_no_users =>
      'Жоқ пользователей, которымжәне можбірақ начать чат.';

  @override
  String get new_chat_empty_not_found => 'Никого не найдено.';

  @override
  String new_chat_error_contacts(Object error) {
    return 'Контактілер: $error';
  }

  @override
  String get new_chat_fallback_user_display_name => 'Пользователь';

  @override
  String get new_group_role_badge_admin => 'Әкімші';

  @override
  String get new_group_role_badge_worker => 'СОТРУДНИК';

  @override
  String new_group_error_auth_session(Object error) {
    return 'Қате авторизации: $error';
  }

  @override
  String get invite_subject => 'Шақыру в LighChat';

  @override
  String get invite_text =>
      'Поставь LighChat: https://lighchat.online\\nПриглашаю тебя в LighChat — вот сілтеме на установку.';

  @override
  String get new_group_title => 'Топ құру';

  @override
  String get new_group_search_hint => 'Іздеу пользователей…';

  @override
  String get new_group_pick_photo_tooltip =>
      'Нажмите, небы сізбрать фото топтар. Удерживайте, небы убрать.';

  @override
  String get new_group_name_label => 'Название топтар';

  @override
  String get new_group_name_hint => 'Название';

  @override
  String get new_group_description_label => 'Сипаттама';

  @override
  String get new_group_description_hint => 'Міндетті емес';

  @override
  String new_group_members_count(Object count) {
    return 'Усағаттникжәне ($count)';
  }

  @override
  String get new_group_add_members_section => 'ДОБАВИТЬ УЧАСТНИКОВ';

  @override
  String get new_group_empty_no_users => 'Жоқ пользователей для добавления.';

  @override
  String get new_group_empty_not_found => 'Никого не найдено.';

  @override
  String get new_group_error_name_required => 'Енгізіңіз название топтар.';

  @override
  String get new_group_error_members_required =>
      'Добавьте хотя бы одного усағаттника.';

  @override
  String get new_group_action_create => 'Құру';

  @override
  String get group_members_title => 'Усағаттники';

  @override
  String get group_members_invite_link => 'Шақыру по сілтемеде';

  @override
  String get group_members_admin_badge => 'Әкімші';

  @override
  String group_members_invite_text(Object groupName, Object inviteLink) {
    return 'Присоединяйся группе $groupName в LighChat: $inviteLink';
  }

  @override
  String get group_members_error_min_admin =>
      'В группе должен остаться хотя бы один әкімші.';

  @override
  String get group_members_error_cannot_remove_creator =>
      'Болмайды снять права әкімшіні создателя топтар.';

  @override
  String get group_members_remove_admin => 'Әкімші снят';

  @override
  String get group_members_make_admin => 'Назначен әкімші';

  @override
  String get auth_brand_tagline => 'Безопасный мессенджер';

  @override
  String get auth_firebase_not_ready =>
      'Firebase не готов. Проверь `firebase_options.dart` және GoogleService-Info.plist.';

  @override
  String get auth_redirecting_to_chats => 'Пережүрісим в чаттар...';

  @override
  String get auth_or => 'немесе';

  @override
  String get auth_create_account => 'Аккаунт құру';

  @override
  String get auth_entry_sign_in => 'Кіру';

  @override
  String get auth_entry_sign_up => 'Аккаунт құру';

  @override
  String get auth_qr_title => 'Кіру по QR';

  @override
  String get auth_qr_hint =>
      'Откройте LighChat на құрылғыда, қайда сіз уже вошлжәне → Параметрлер → Құрылғылар → Подключить жаңа құрылғы, және наведите камеру на осы код.';

  @override
  String auth_qr_refresh_in(int seconds) {
    return 'Обновится через $secondsс';
  }

  @override
  String get auth_qr_other_method => 'Кіру другим способом';

  @override
  String get auth_qr_approving => 'Вжүрісим…';

  @override
  String get auth_qr_rejected => 'Запрос отклонён';

  @override
  String get auth_qr_retry => 'Повторить';

  @override
  String get auth_qr_unknown_error => 'Сәтсіз сгенерировать QR-код.';

  @override
  String get auth_qr_use_qr_login => 'Кіру по QR';

  @override
  String get auth_privacy_policy => 'Политика конфиденциальности';

  @override
  String get auth_error_open_privacy_policy =>
      'Сәтсіз открыть политику конфиденциальности';

  @override
  String get voice_transcript_show => 'Показать текст';

  @override
  String get voice_transcript_hide => 'Скрыть текст';

  @override
  String get voice_transcript_copy => 'Көшіру';

  @override
  String get voice_transcript_loading => 'Транскрибация…';

  @override
  String get voice_transcript_failed => 'Сәтсіз получить текст.';

  @override
  String get voice_attachment_media_kind_audio => 'аудио';

  @override
  String get voice_attachment_load_failed => 'Сәтсіз загрузить';

  @override
  String get voice_attachment_title_voice_message => 'Голосовое хабарлама';

  @override
  String voice_transcript_error(Object error) {
    return 'Сәтсіз сделать транскрибацию: $error';
  }

  @override
  String get chat_messages_title => 'Хабарламалар';

  @override
  String get chat_call_decline => 'Қабылдамау';

  @override
  String get chat_call_open => 'Ашу';

  @override
  String get chat_call_accept => 'Қабылдау';

  @override
  String video_call_error_init(Object error) {
    return 'Қате видеозвонка: $error';
  }

  @override
  String get video_call_ended => 'Қоңырау завершён';

  @override
  String get video_call_status_missed => 'Пропущенный қоңырау';

  @override
  String get video_call_status_cancelled => 'Қоңырау отменён';

  @override
  String get video_call_error_offer_not_ready =>
      'Оффер ещё не готов, попробуйте снова';

  @override
  String get video_call_error_invalid_call_data =>
      'Некорректные деректер звонка';

  @override
  String video_call_error_accept_failed(Object error) {
    return 'Сәтсіз принять қоңырау: $error';
  }

  @override
  String get video_call_incoming => 'Вжүрісящий видеоқоңырау';

  @override
  String get video_call_connecting => 'Видеоқоңырау…';

  @override
  String get video_call_pip_tooltip => 'Картинка в картинке';

  @override
  String get video_call_mini_window_tooltip => 'Мини-окно';

  @override
  String get chat_delete_message_title_single => 'Хабарламаны жою?';

  @override
  String get chat_delete_message_title_multi => 'Жою хабарламалар?';

  @override
  String get chat_delete_message_body_single =>
      'Хабарлама болады скрыто у барлығых.';

  @override
  String chat_delete_message_body_multi(Object count) {
    return 'Болады удалебірақ хабарламалар: $count';
  }

  @override
  String get chat_delete_file_title => 'Жою файл?';

  @override
  String get chat_delete_file_body =>
      'Болады удалён только осы файл из хабарламалар.';

  @override
  String get forward_title => 'Переслать';

  @override
  String get forward_empty_no_messages => 'Жоқ хабарламалар для пересылки';

  @override
  String get forward_error_not_authorized => 'Не авторизован';

  @override
  String get forward_empty_no_recipients =>
      'Жоқ контактілер және чатов для пересылки';

  @override
  String get forward_search_hint => 'Іздеу контактілер…';

  @override
  String get forward_empty_no_available_recipients =>
      'Қолжетімділікных получатталей жоқ.\nМожбірақ пересылать только контактам және в сіздіңжәне активные чаттар.';

  @override
  String get forward_empty_not_found => 'Ничего не найдено';

  @override
  String get forward_action_pick_recipients => 'Сізберите получатталей';

  @override
  String get forward_action_send => 'Жіберу';

  @override
  String forward_error_generic(Object error) {
    return 'Қате: $error';
  }

  @override
  String get forward_sender_fallback => 'Усағаттник';

  @override
  String get forward_error_profiles_load =>
      'Сәтсіз загрузить профнемесе для открытия чаттың';

  @override
  String get forward_error_send_no_permissions =>
      'Сәтсіз переслать: жоқ прав на сізбранные чаттар немесе чат көбірек неқолжетімділікен.';

  @override
  String get forward_error_send_forbidden_chat =>
      'Сәтсіз переслать: қолжетімділік одному из чатов запрещён.';

  @override
  String get share_picker_title => 'LighChat-қа бөлісу';

  @override
  String get share_picker_empty_payload => 'Бөлісетін мазмұн жоқ';

  @override
  String get share_picker_summary_text_only => 'Мәтін';

  @override
  String share_picker_summary_files_count(int count) {
    return 'Файлдар: $count';
  }

  @override
  String share_picker_summary_files_with_text(int count) {
    return 'Файлдар: $count + мәтін';
  }

  @override
  String get devices_title => 'Можәне құрылғылар';

  @override
  String get devices_subtitle =>
      'Тізім құрылғылар, на которых опубликован сіздің публичный ключ шифрования. Отзыв автоматическжәне создаёт новую эпоху ключей во барлығых зашифрованных чаттыңх — отозванное құрылғы көбірек не увидит носізе хабарламалар.';

  @override
  String get devices_empty => 'Құрылғылар әзірге жоқ.';

  @override
  String get devices_connect_new_device => 'Подключить жаңа құрылғы';

  @override
  String get devices_approve_title => 'Рұқсат беру вжүріс на этом құрылғыда?';

  @override
  String get devices_approve_body_hint =>
      'Убедитесь, не бұл сіздіңе құрылғы, на котором сіз жаңа ғана показалжәне QR.';

  @override
  String get devices_approve_allow => 'Рұқсат беру';

  @override
  String get devices_approve_deny => 'Қабылдамау';

  @override
  String get devices_handover_progress_title =>
      'Синхронизация зашифрованных чатов…';

  @override
  String devices_handover_progress_body(int done, int total) {
    return 'Обработабірақ $done из $total';
  }

  @override
  String get devices_handover_progress_starting => 'Начинаем…';

  @override
  String get devices_handover_success_title => 'Құрылғы қосылды';

  @override
  String devices_handover_success_body(String label) {
    return 'Құрылғы $label получило қолжетімділік зашифрованным чаттыңм.';
  }

  @override
  String devices_progress_rekeying(Object done, Object total) {
    return 'Жаңарту чатов: $done / $total';
  }

  @override
  String get devices_chip_current => 'Бұл құрылғы';

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
  String get devices_dialog_rename_title => 'Переименовать құрылғы';

  @override
  String get devices_dialog_rename_hint => 'Например, iPhone 15 — Safari';

  @override
  String devices_error_rename_failed(Object error) {
    return 'Сәтсіз переименовать: $error';
  }

  @override
  String get devices_dialog_revoke_title => 'Отозвать құрылғы?';

  @override
  String get devices_dialog_revoke_body_current =>
      'Сіз собираетесь отозвать ТЕКУЩЕЕ құрылғы. После этого сіз не сможете читать носізе хабарламалар в зашифрованных чаттыңх этого клиента.';

  @override
  String get devices_dialog_revoke_body_other =>
      'Құрылғы көбірек не сможет читать носізе хабарламалар в зашифрованных чаттыңх. Ескі хабарламалар останутся қолжетімділікны на нём.';

  @override
  String devices_snackbar_revoked(Object rekeyed, Object suffix) {
    return 'Құрылғы отозвано. Обновлебірақ чатов: $rekeyed$suffix';
  }

  @override
  String devices_snackbar_failed_suffix(Object count) {
    return ', қателер: $count';
  }

  @override
  String devices_error_revoke_failed(Object error) {
    return 'Қате revoke: $error';
  }

  @override
  String get e2ee_recovery_title => 'E2EE — резервирование';

  @override
  String get e2ee_password_label => 'Құпиясөз';

  @override
  String get e2ee_password_confirm_label => 'Повторите құпиясөз';

  @override
  String e2ee_password_min_length(Object count) {
    return 'Ең аз $count символов';
  }

  @override
  String get e2ee_password_mismatch => 'Паролжәне не совпадают';

  @override
  String get e2ee_backup_create_title => 'Құру backup ключа';

  @override
  String get e2ee_backup_restore_title => 'Восстановить по паролю';

  @override
  String get e2ee_backup_restore_action => 'Восстановить';

  @override
  String e2ee_backup_create_error(Object error) {
    return 'Сәтсіз создать backup: $error';
  }

  @override
  String e2ee_backup_restore_error(Object error) {
    return 'Сәтсіз восстановить: $error';
  }

  @override
  String get e2ee_backup_wrong_password => 'Неверный құпиясөз';

  @override
  String get e2ee_backup_not_found => 'Backup не найден';

  @override
  String e2ee_recovery_error_generic(Object error) {
    return 'Қате: $error';
  }

  @override
  String get e2ee_backup_password_card_title => 'Backup паролем';

  @override
  String get e2ee_backup_password_card_description =>
      'Создайте зашифрованный backup приватного ключа. Еслжәне потеряете барлығы құрылғылар, сможете восстановить его на новом, зная только құпиясөз. Құпиясөз болмайды восстановить — записывайте надёжно.';

  @override
  String get e2ee_backup_overwrite => 'Перезаписать backup';

  @override
  String get e2ee_backup_create => 'Құру backup';

  @override
  String get e2ee_backup_restore => 'Восстановить из backup';

  @override
  String get e2ee_backup_already_have => 'У меня уже бар backup';

  @override
  String get e2ee_qr_transfer_title => 'Передача ключа по QR';

  @override
  String get e2ee_qr_transfer_description =>
      'На новом құрылғыда показываем QR, на старом сканируем камерой. Сверяете 6-значный код — приватный ключ переносится безопасно.';

  @override
  String get e2ee_qr_transfer_open => 'Ашу QR-pairing';

  @override
  String get media_viewer_action_reply => 'Ответить';

  @override
  String get media_viewer_action_forward => 'Переслать';

  @override
  String get media_viewer_action_send => 'Жіберу';

  @override
  String get media_viewer_action_save => 'Сақтау';

  @override
  String get media_viewer_action_show_in_chat => 'Показать в чатта';

  @override
  String get media_viewer_action_delete => 'Жою';

  @override
  String get media_viewer_error_no_gallery_access =>
      'Жоқ қолжетімділіка сохранению в галерею';

  @override
  String get media_viewer_error_share_unavailable_web =>
      'Шаринг неқолжетімділікен в веб-нұсқа';

  @override
  String get media_viewer_error_file_not_found => 'Файл не найден';

  @override
  String get media_viewer_error_bad_media_url => 'Неверная сілтеме на медиа';

  @override
  String get media_viewer_error_bad_url => 'Неверная сілтеме';

  @override
  String get media_viewer_error_unsupported_media_scheme =>
      'Неподдерживаемый тип медиа';

  @override
  String media_viewer_error_http_status(Object status) {
    return 'Қате сервера (HTTP $status)';
  }

  @override
  String media_viewer_error_save_failed(Object error) {
    return 'Сәтсіз сохранить: $error';
  }

  @override
  String media_viewer_error_send_failed(Object error) {
    return 'Сәтсіз отправить: $error';
  }

  @override
  String get media_viewer_video_playback_speed => 'Скорость воспроизведения';

  @override
  String get media_viewer_video_quality => 'Качество';

  @override
  String get media_viewer_video_quality_auto => 'Авто';

  @override
  String get media_viewer_error_quality_switch_failed =>
      'Сәтсіз переключить качество';

  @override
  String get media_viewer_error_pip_open_failed => 'Сәтсіз открыть PiP';

  @override
  String get media_viewer_pip_not_supported =>
      'Картинка в картинке не поддерживается на этом құрылғыда.';

  @override
  String get media_viewer_video_processing =>
      'Видео обрабатывается на сервере және скоро станет қолжетімділікно.';

  @override
  String get media_viewer_video_playback_failed =>
      'Сәтсіз воспроизвестжәне видео.';

  @override
  String get common_none => 'Жоқ';

  @override
  String get group_member_role_admin => 'Әкімші';

  @override
  String get group_member_role_worker => 'Усағаттник';

  @override
  String get profile_no_photo_to_view => 'Жоқ фото профиля для просмотра.';

  @override
  String get profile_chat_id_copied_toast => 'Идентификатор чаттың скопирован';

  @override
  String get auth_register_error_open_link => 'Сәтсіз открыть сілтемені';

  @override
  String get new_chat_error_self_profile_not_found =>
      'Не найден профиль в каталоге. Попробуйте сізйтжәне және войтжәне снова.';

  @override
  String get disappearing_messages_title => 'Исчезающие хабарламалар';

  @override
  String get disappearing_messages_intro =>
      'Носізе хабарламалар автоматическжәне удаляются из базы после сізбранного временжәне (от момента отправки). Уже отправленные не меняются.';

  @override
  String disappearing_messages_admin_only(Object summary) {
    return 'Только әкімшілер топтар могут менять осы параметр. Қазір: $summary.';
  }

  @override
  String get disappearing_messages_snackbar_off =>
      'Исчезающие хабарламалар сізключены.';

  @override
  String get disappearing_messages_snackbar_updated => 'Таймер обновлён.';

  @override
  String get disappearing_preset_off => 'Өшірулі';

  @override
  String get disappearing_preset_1h => '1 ч';

  @override
  String get disappearing_preset_24h => '24 ч';

  @override
  String get disappearing_preset_7d => '7 дн.';

  @override
  String get disappearing_preset_30d => '30 дн.';

  @override
  String get disappearing_ttl_summary_off => 'Өшірулі';

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
  String get conversation_profile_e2ee_on => 'Қосулы';

  @override
  String get conversation_profile_e2ee_off => 'Өшірулі';

  @override
  String get conversation_profile_e2ee_subtitle_on =>
      'Сквозное шифрлау включено. Нажмите для подробностей.';

  @override
  String get conversation_profile_e2ee_subtitle_off =>
      'Сквозное шифрлау сізключено. Нажмите, небы включить.';

  @override
  String get partner_profile_title_fallback_group => 'Групповой чат';

  @override
  String get partner_profile_title_fallback_saved => 'Таңдаулылар';

  @override
  String get partner_profile_title_fallback_chat => 'Чат';

  @override
  String partner_profile_subtitle_group_member_count(Object count) {
    return '$count усағаттников';
  }

  @override
  String get partner_profile_subtitle_saved_messages =>
      'Хабарламалар және заметкжәне только для вас';

  @override
  String get partner_profile_error_cannot_contact_user =>
      'С этим пользователем болмайды связаться.';

  @override
  String partner_profile_error_open_chat(Object error) {
    return 'Сәтсіз открыть чат: $error';
  }

  @override
  String get partner_profile_call_peer_fallback => 'Собеседник';

  @override
  String get partner_profile_chat_not_created => 'Чат ещё не создан';

  @override
  String get partner_profile_notifications_muted => 'Хабарландырулар отключены';

  @override
  String get partner_profile_notifications_unmuted =>
      'Хабарландырулар включены';

  @override
  String get partner_profile_notifications_change_failed =>
      'Сәтсіз изменить хабарландырулар';

  @override
  String get partner_profile_removed_from_contacts => 'Жойылды из контактілер';

  @override
  String get partner_profile_remove_contact_failed =>
      'Сәтсіз удалить из контактілер';

  @override
  String get partner_profile_contact_sent => 'Контакт отправлен';

  @override
  String get partner_profile_share_failed_copied =>
      'Сәтсіз открыть шаринг. Текст контакта скопирован.';

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
  String get partner_profile_tooltip_back => 'Артқа';

  @override
  String get partner_profile_tooltip_close => 'Жабу';

  @override
  String get partner_profile_edit_contact_short => 'Изм.';

  @override
  String get partner_profile_tooltip_copy_chat_id => 'Көшіру ID чаттың';

  @override
  String get partner_profile_action_chats => 'Чаттар';

  @override
  String get partner_profile_action_voice_call => 'Қоңырау';

  @override
  String get partner_profile_action_video => 'Видео';

  @override
  String get partner_profile_action_share => 'Бөлісу';

  @override
  String get partner_profile_action_notifications => 'Хабарландырулар';

  @override
  String get partner_profile_menu_members => 'Усағаттники';

  @override
  String get partner_profile_menu_edit_group => 'Өңдеу топты';

  @override
  String get partner_profile_menu_media_links_files =>
      'Медиа, ссылкжәне және файлдар';

  @override
  String get partner_profile_menu_starred => 'Таңдаулылар';

  @override
  String get partner_profile_menu_threads => 'Обсуждения';

  @override
  String get partner_profile_menu_games => 'Ойындар';

  @override
  String get partner_profile_menu_block => 'Бұғаттау';

  @override
  String get partner_profile_menu_unblock => 'Бұғаттан шығару';

  @override
  String get partner_profile_menu_notifications => 'Хабарландырулар';

  @override
  String get partner_profile_menu_chat_theme => 'Солқырып чаттың';

  @override
  String get partner_profile_menu_advanced_privacy =>
      'Расширенная приватность чаттың';

  @override
  String get partner_profile_privacy_trailing_default => 'По умолчанию';

  @override
  String get partner_profile_menu_encryption => 'Шифрлау';

  @override
  String get partner_profile_no_common_groups => 'Жоқ ОБЩИХ ГРУПП';

  @override
  String partner_profile_create_group_with(Object name) {
    return 'Топ құру $name';
  }

  @override
  String get partner_profile_leave_group => 'Шығу топты';

  @override
  String get partner_profile_contacts_and_data => 'Контактілер және деректер';

  @override
  String get partner_profile_field_system_role => 'Роль в системе';

  @override
  String get partner_profile_field_email => 'Электрондық пошта';

  @override
  String get partner_profile_field_phone => 'Телефон';

  @override
  String get partner_profile_field_birthday => 'День рождения';

  @override
  String get partner_profile_field_bio => 'О себе';

  @override
  String get partner_profile_add_to_contacts => 'Қосу в контактілер';

  @override
  String get partner_profile_remove_from_contacts => 'Жою из контактілер';

  @override
  String get thread_search_hint => 'Іздеу в обсуждении…';

  @override
  String get thread_search_tooltip_clear => 'Очистить';

  @override
  String get thread_search_tooltip_search => 'Іздеу';

  @override
  String thread_reply_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count жауап',
      one: '$count жауап',
      zero: '$count жауап',
    );
    return '$_temp0';
  }

  @override
  String get thread_message_not_found => 'Хабарлама не найдено';

  @override
  String get thread_screen_title_fallback => 'Обсуждение';

  @override
  String thread_load_replies_error(Object error) {
    return 'Қате ветки: $error';
  }

  @override
  String get chat_message_empty_placeholder => 'Хабарлама';

  @override
  String get chat_sender_you => 'Сіз';

  @override
  String get chat_clipboard_nothing_to_paste => 'Нечего вставлять из буфера';

  @override
  String chat_clipboard_paste_failed(Object error) {
    return 'Сәтсіз вставить содержимое буфера: $error';
  }

  @override
  String chat_send_failed(Object error) {
    return 'Сәтсіз отправить: $error';
  }

  @override
  String chat_send_video_circle_failed(Object error) {
    return 'Сәтсіз отправить кружок: $error';
  }

  @override
  String get chat_service_unavailable => 'Сервис неқолжетімділікен';

  @override
  String get chat_repository_unavailable => 'Сервис чаттың неқолжетімділікен';

  @override
  String get chat_still_loading => 'Чат ещё загружается';

  @override
  String get chat_no_participants => 'Жоқ усағаттников чаттың';

  @override
  String get chat_location_ios_geolocator_missing =>
      'Геолокация не подключена в iOS-сборке. В каталоге mobile/app/ios сізполните pod install және пересоберите приложение.';

  @override
  String get chat_location_services_disabled => 'Қосулыючите службу геолокации';

  @override
  String get chat_location_permission_denied => 'Жоқ қолжетімділіка геолокации';

  @override
  String chat_location_send_failed(Object error) {
    return 'Сәтсіз отправить геолокацию: $error';
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
    return 'Сәтсіз отправить опрос: $error';
  }

  @override
  String chat_delete_action_failed(Object error) {
    return 'Сәтсіз удалить: $error';
  }

  @override
  String get chat_media_transcode_retry_started =>
      'Повторная обработка запущена';

  @override
  String chat_media_transcode_retry_failed(Object error) {
    return 'Сәтсіз запустить обработку: $error';
  }

  @override
  String chat_parent_load_error(Object error) {
    return 'Қате: $error';
  }

  @override
  String get chat_message_not_found_in_loaded_history =>
      'Хабарлама не найдебірақ в загруженной истории';

  @override
  String get chat_finish_editing_first => 'Сначала завершите редактирование';

  @override
  String chat_send_voice_failed(Object error) {
    return 'Сәтсіз отправить голосовое: $error';
  }

  @override
  String get chat_starred_removed => 'Жойылды из избранного';

  @override
  String get chat_starred_added => 'Қосылды в таңдаулылар';

  @override
  String chat_starred_toggle_failed(Object error) {
    return 'Сәтсіз изменить таңдаулылар: $error';
  }

  @override
  String chat_reaction_toggle_failed(Object error) {
    return 'Сәтсіз поставить реакцию: $error';
  }

  @override
  String chat_emoji_burst_sync_failed(Object error) {
    return 'Сәтсіз синхронизировать эффект эмодзи: $error';
  }

  @override
  String get chat_pin_already_pinned => 'Хабарлама уже бекітілді';

  @override
  String chat_pin_limit_reached(int count) {
    return 'Лимит закреплённых ($count)';
  }

  @override
  String chat_pin_failed(Object error) {
    return 'Сәтсіз бекіту: $error';
  }

  @override
  String chat_unpin_failed(Object error) {
    return 'Сәтсіз босату: $error';
  }

  @override
  String get chat_text_copied => 'Текст скопирован';

  @override
  String get chat_edit_attachments_not_allowed =>
      'Пржәне редактированижәне вложения неқолжетімділікны';

  @override
  String get chat_edit_text_empty => 'Текст не мүмкін быть пустым';

  @override
  String chat_e2ee_unavailable(Object code) {
    return 'Шифрлау неқолжетімділікно: $code';
  }

  @override
  String chat_save_failed(Object error) {
    return 'Сәтсіз сохранить: $error';
  }

  @override
  String chat_load_messages_error(Object error) {
    return 'Қате загрузкжәне хабарламалар: $error';
  }

  @override
  String chat_conversation_error(Object error) {
    return 'Әңгімелесу қатесі: $error';
  }

  @override
  String chat_auth_error(Object error) {
    return 'Қате авторизации: $error';
  }

  @override
  String get chat_poll_label => 'Опрос';

  @override
  String get chat_location_label => 'Локация';

  @override
  String get chat_attachment_label => 'Вложение';

  @override
  String chat_media_pick_failed(Object error) {
    return 'Сәтсіз сізбрать медиа: $error';
  }

  @override
  String chat_file_pick_failed(Object error) {
    return 'Сәтсіз сізбрать файл: $error';
  }

  @override
  String get chat_call_ongoing_video => 'Идёт видеоқоңырау';

  @override
  String get chat_call_ongoing_audio => 'Идёт аудиоқоңырау';

  @override
  String get chat_call_incoming_video => 'Вжүрісящий видеоқоңырау';

  @override
  String get chat_call_incoming_audio => 'Вжүрісящий аудиоқоңырау';

  @override
  String get message_menu_action_reply => 'Ответить';

  @override
  String get message_menu_action_thread => 'Обсудить';

  @override
  String get message_menu_action_copy => 'Көшіру';

  @override
  String get message_menu_action_edit => 'Өзгерту';

  @override
  String get message_menu_action_pin => 'Бекіту';

  @override
  String get message_menu_action_star_add => 'Қосу в таңдаулылар';

  @override
  String get message_menu_action_star_remove => 'Убрать из избранного';

  @override
  String get message_menu_action_create_sticker => 'Стикер жасау';

  @override
  String get message_menu_action_save_to_my_stickers => 'Стикерлеріме сақтау';

  @override
  String get message_menu_action_forward => 'Переслать';

  @override
  String get message_menu_action_select => 'Сізбрать';

  @override
  String get message_menu_action_delete => 'Жою';

  @override
  String get message_menu_initiator_deleted => 'Хабарлама удалено';

  @override
  String get message_menu_header_sent => 'ОТПРАВЛЕНО:';

  @override
  String get message_menu_header_read => 'Оқылды:';

  @override
  String get message_menu_header_expire_at => 'ИСЧЕЗНЕТ:';

  @override
  String get chat_header_search_hint => 'Іздеу хабарламалар…';

  @override
  String get chat_header_tooltip_threads => 'Обсуждения';

  @override
  String get chat_header_tooltip_search => 'Іздеу';

  @override
  String get chat_header_tooltip_video_call => 'Видеоқоңырау';

  @override
  String get chat_header_tooltip_audio_call => 'Аудиоқоңырау';

  @override
  String get conversation_games_title => 'Ойындар';

  @override
  String get conversation_games_durak => 'Дурак';

  @override
  String get conversation_games_durak_subtitle => 'Құру лобби';

  @override
  String get conversation_game_lobby_title => 'Лобби';

  @override
  String get conversation_game_lobby_not_found => 'Ойын не найдена';

  @override
  String conversation_game_lobby_error(Object error) {
    return 'Қате: $error';
  }

  @override
  String conversation_game_lobby_create_failed(Object error) {
    return 'Сәтсіз создать игру: $error';
  }

  @override
  String conversation_game_lobby_game_id(Object id) {
    return 'ID: $id';
  }

  @override
  String conversation_game_lobby_status(Object status) {
    return 'Мәртебе: $status';
  }

  @override
  String conversation_game_lobby_players(Object count, Object max) {
    return 'Ойыншылар: $count/$max';
  }

  @override
  String get conversation_game_lobby_join => 'Кіру';

  @override
  String get conversation_game_lobby_start => 'Начать';

  @override
  String conversation_game_lobby_join_failed(Object error) {
    return 'Сәтсіз войти: $error';
  }

  @override
  String conversation_game_lobby_start_failed(Object error) {
    return 'Сәтсіз начать игру: $error';
  }

  @override
  String get conversation_game_send_test_move => 'Тестосізй жүріс';

  @override
  String conversation_game_move_failed(Object error) {
    return 'Жүріс не принят: $error';
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
  String get conversation_durak_action_defend => 'Отшабу';

  @override
  String get conversation_durak_action_take => 'Взять';

  @override
  String get conversation_durak_action_beat => 'Бито';

  @override
  String get conversation_durak_action_transfer => 'Аудару';

  @override
  String get conversation_durak_action_pass => 'Пас';

  @override
  String get conversation_durak_badge_taking => 'Беру';

  @override
  String get conversation_durak_game_finished_title => 'Ойын завершена';

  @override
  String get conversation_durak_game_finished_no_loser =>
      'В осы раз без проойынвшего.';

  @override
  String conversation_durak_game_finished_loser(Object uid) {
    return 'Проойынл: $uid';
  }

  @override
  String conversation_durak_game_finished_winners(Object uids) {
    return 'Победнемесе: $uids';
  }

  @override
  String get conversation_durak_winner => 'Жеңімпаз!';

  @override
  String get conversation_durak_play_again => 'Сыграть ещё раз';

  @override
  String get conversation_durak_back_to_chat => 'Вернуться в чат';

  @override
  String get conversation_game_lobby_waiting_opponent => 'Ожидание соперника…';

  @override
  String get conversation_durak_drop_zone =>
      'Перетащжәне карту сюда, небы сыграть';

  @override
  String get durak_settings_mode => 'Режим';

  @override
  String get durak_mode_podkidnoy => 'Подкидной';

  @override
  String get durak_mode_perevodnoy => 'Переводной';

  @override
  String get durak_settings_max_players => 'Ойыншыов';

  @override
  String get durak_settings_deck => 'Бума';

  @override
  String get durak_deck_36 => '36 карт';

  @override
  String get durak_deck_52 => '52 карталар';

  @override
  String get durak_settings_with_jokers => 'Джокерлер';

  @override
  String get durak_settings_turn_timer => 'Таймер жүріса';

  @override
  String get durak_turn_timer_off => 'Өшірулі';

  @override
  String get durak_settings_throw_in_policy => 'Кім мүмкін подкидывать';

  @override
  String get durak_throw_in_policy_all => 'Барлығы (кроме защитника)';

  @override
  String get durak_throw_in_policy_neighbors => 'Только соседжәне защитника';

  @override
  String get durak_settings_shuler => 'Режим шулера';

  @override
  String get durak_settings_shuler_subtitle =>
      'Разрешает нелегальные жүрісы, әзірге кім-сол не крикнет «Фолл!»';

  @override
  String get conversation_durak_action_foul => 'Фолл!';

  @override
  String get conversation_durak_action_resolve => 'Растау «Бито»';

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
      'Ждём фолл. Еслжәне ешкім не нажмёт — подтверджәне «Бито».';

  @override
  String get durak_phase_pending_foul_hint_other =>
      'Ждём фолл. Нажмжәне «Фолл!», еслжәне заметил шулерство.';

  @override
  String get durak_phase_hint_can_throw_in => 'Можбірақ подкидывать';

  @override
  String get durak_phase_hint_wait => 'Ждите свой жүріс';

  @override
  String durak_now_throwing_in(Object name) {
    return 'Қазір подкидывает: $name';
  }

  @override
  String chat_selection_selected_count(int count) {
    return '$count таңдалды';
  }

  @override
  String get chat_selection_tooltip_forward => 'Переслать';

  @override
  String get chat_selection_tooltip_delete => 'Жою';

  @override
  String get chat_composer_hint_message => 'Енгізіңіз хабарлама…';

  @override
  String get chat_composer_tooltip_stickers => 'Стикеры';

  @override
  String get chat_composer_tooltip_attachments => 'Вложения';

  @override
  String get chat_list_unread_separator => 'Непрочитанные хабарламалар';

  @override
  String get chat_e2ee_decrypt_failed_open_devices =>
      'Сәтсіз шифрды ашу. Откройте Параметрлер → Құрылғылар';

  @override
  String get chat_e2ee_encrypted_message_placeholder =>
      'Зашифрованное хабарлама';

  @override
  String chat_forwarded_from(Object name) {
    return 'Переслабірақ $name';
  }

  @override
  String get chat_outbox_retry => 'Повторить';

  @override
  String get chat_outbox_remove => 'Убрать';

  @override
  String get chat_outbox_cancel => 'Болдырмау';

  @override
  String get chat_message_edited_badge_short => 'изм.';

  @override
  String get register_error_enter_name => 'Енгізіңіз аты.';

  @override
  String get register_error_enter_username => 'Енгізіңіз логин.';

  @override
  String get register_error_enter_phone => 'Енгізіңіз телефон нөмірі.';

  @override
  String get register_error_invalid_phone =>
      'Енгізіңіз корректный телефон нөмірі.';

  @override
  String get register_error_enter_email => 'Енгізіңіз email.';

  @override
  String get register_error_enter_password => 'Енгізіңіз құпиясөз.';

  @override
  String get register_error_repeat_password => 'Повторите құпиясөз.';

  @override
  String get register_error_dob_format =>
      'Укажите дату рождения в формате дд.мм.гггг';

  @override
  String get register_error_accept_privacy_policy =>
      'Подтвердите согласие политикой конфиденциальности';

  @override
  String get register_privacy_required =>
      'Қажет согласие политикой конфиденциальности';

  @override
  String get register_label_name => 'Аты';

  @override
  String get register_hint_name => 'Енгізіңіз аты';

  @override
  String get register_label_username => 'Логин';

  @override
  String get register_hint_username => 'Енгізіңіз логин';

  @override
  String get register_label_phone => 'Телефон';

  @override
  String get register_hint_choose_country => 'Сізберите страну';

  @override
  String get register_label_email => 'Электрондық пошта';

  @override
  String get register_hint_email => 'Енгізіңіз email';

  @override
  String get register_label_password => 'Құпиясөз';

  @override
  String get register_hint_password => 'Енгізіңіз құпиясөз';

  @override
  String get register_label_confirm_password => 'Повтор пароля';

  @override
  String get register_hint_confirm_password => 'Повторите құпиясөз';

  @override
  String get register_label_dob => 'Жәнеәсол рождения';

  @override
  String get register_hint_dob => 'дд.мм.гггг';

  @override
  String get register_label_bio => 'О себе';

  @override
  String get register_hint_bio => 'Расскажите о себе...';

  @override
  String get register_privacy_prefix => 'Мен принимаю ';

  @override
  String get register_privacy_link_text =>
      'Согласия на обработку персональных деректер';

  @override
  String get register_privacy_and => ' және ';

  @override
  String get register_terms_link_text =>
      'Пользовательское соглашение политикжәне конфиденциальности';

  @override
  String get register_button_create_account => 'Аккаунт құру';

  @override
  String get register_country_search_hint => 'Іздеу страны немесе кода';

  @override
  String get register_date_picker_help => 'Жәнеәсол рождения';

  @override
  String get register_date_picker_cancel => 'Болдырмау';

  @override
  String get register_date_picker_confirm => 'Сізбрать';

  @override
  String get register_pick_avatar_title => 'Сізбрать аватар';

  @override
  String get edit_group_title => 'Өңдеу топты';

  @override
  String get edit_group_save => 'Сақтау';

  @override
  String get edit_group_cancel => 'Болдырмау';

  @override
  String get edit_group_name_label => 'Название топтар';

  @override
  String get edit_group_name_hint => 'Название';

  @override
  String get edit_group_description_label => 'Сипаттама';

  @override
  String get edit_group_description_hint => 'Міндетті емес';

  @override
  String get edit_group_pick_photo_tooltip =>
      'Нажмите, небы сізбрать фото топтар. Удерживайте, небы убрать.';

  @override
  String get edit_group_error_name_required =>
      'Өтінеміз, енгізіңіз название топтар.';

  @override
  String get edit_group_error_save_failed => 'Қате пржәне сохраненижәне топтар';

  @override
  String get edit_group_error_not_found => 'Топ не найдена';

  @override
  String get edit_group_error_permission_denied =>
      'У вас жоқ прав для редактирования этой топтар';

  @override
  String get edit_group_success => 'Топ обновлена';

  @override
  String get edit_group_privacy_section => 'КОНФИДЕНЦИАЛЬНОСТЬ';

  @override
  String get edit_group_privacy_forwarding => 'Пересылка хабарламалар';

  @override
  String get edit_group_privacy_forwarding_desc =>
      'Рұқсат беру усағаттникам пересылать хабарламалар из этой топтар.';

  @override
  String get edit_group_privacy_screenshots => 'Скриншоты';

  @override
  String get edit_group_privacy_screenshots_desc =>
      'Рұқсат беру скриншоты внутржәне топтар (ограничение зависит платформы).';

  @override
  String get edit_group_privacy_copy => 'Копирование текста';

  @override
  String get edit_group_privacy_copy_desc =>
      'Рұқсат беру копирование текста хабарламалар.';

  @override
  String get edit_group_privacy_save_media => 'Сохранение медиа';

  @override
  String get edit_group_privacy_save_media_desc =>
      'Рұқсат беру сохранять фото және видео на құрылғы.';

  @override
  String get edit_group_privacy_share_media => 'Бөлісу медиа';

  @override
  String get edit_group_privacy_share_media_desc =>
      'Рұқсат беру делиться медиафайламжәне вне приложения.';

  @override
  String get schedule_message_sheet_title => 'Запланировать хабарлама';

  @override
  String get schedule_message_long_press_hint => 'Запланировать отправку';

  @override
  String schedule_message_preset_today_at(String time) {
    return 'Бүгін в $time';
  }

  @override
  String schedule_message_preset_tomorrow_at(String time) {
    return 'Ертең в $time';
  }

  @override
  String schedule_message_will_send_at(String datetime) {
    return 'Болады отправлено: $datetime';
  }

  @override
  String get schedule_message_must_be_in_future =>
      'Время должбірақ быть в будущем (ең аз через минут).';

  @override
  String get schedule_message_e2ee_warning =>
      'Бұл E2EE-чат. Отложенное хабарлама болады сохранебірақ в открытом виде на сервере және опубликовабірақ без шифрования.';

  @override
  String get schedule_message_cancel => 'Болдырмау';

  @override
  String get schedule_message_confirm => 'Запланировать';

  @override
  String get schedule_message_save => 'Сақтау';

  @override
  String get schedule_message_text_required => 'Сначала енгізіңіз текст';

  @override
  String get schedule_message_attachments_unsupported_mobile =>
      'Планирование вложений әзірге поддерживается только в веб-клиенте';

  @override
  String schedule_message_scheduled_toast(String datetime) {
    return 'Запланировано: $datetime';
  }

  @override
  String schedule_message_failed_toast(String error) {
    return 'Сәтсіз запланировать: $error';
  }

  @override
  String get scheduled_messages_screen_title => 'Запланированные хабарламалар';

  @override
  String get scheduled_messages_empty_title =>
      'Жоқ запланированных хабарламалар';

  @override
  String get scheduled_messages_empty_hint =>
      'Удерживайте кнопку «Жіберу», небы запланировать.';

  @override
  String scheduled_messages_load_failed(String error) {
    return 'Сәтсіз загрузить: $error';
  }

  @override
  String get scheduled_messages_e2ee_notice =>
      'В E2EE-чатта запланированные хабарламалар хранятся және публикуются в открытом виде.';

  @override
  String get scheduled_messages_cancel_dialog_title => 'Болдырмау отправку?';

  @override
  String get scheduled_messages_cancel_dialog_body =>
      'Запланированное хабарлама болады удалено.';

  @override
  String get scheduled_messages_cancel_dialog_keep => 'Не отменять';

  @override
  String get scheduled_messages_cancel_dialog_confirm => 'Болдырмау';

  @override
  String get scheduled_messages_canceled_toast => 'Отменено';

  @override
  String scheduled_messages_time_changed_toast(String datetime) {
    return 'Время изменено: $datetime';
  }

  @override
  String scheduled_messages_action_failed_toast(String error) {
    return 'Қате: $error';
  }

  @override
  String get scheduled_messages_tile_edit_tooltip => 'Өзгерту время';

  @override
  String get scheduled_messages_tile_cancel_tooltip => 'Болдырмау';

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
  String get scheduled_messages_preview_message => 'Хабарлама';

  @override
  String get chat_header_tooltip_scheduled => 'Запланированные хабарламалар';

  @override
  String get schedule_date_label => 'Жәнеәсол';

  @override
  String get schedule_time_label => 'Время';

  @override
  String get common_done => 'Дайын';

  @override
  String get common_send => 'Жіберу';

  @override
  String get common_open => 'Ашу';

  @override
  String get common_add => 'Қосу';

  @override
  String get common_search => 'Іздеу';

  @override
  String get common_edit => 'Өңдеу';

  @override
  String get common_next => 'Әрі қарай';

  @override
  String get common_ok => 'ОК';

  @override
  String get common_confirm => 'Растау';

  @override
  String get common_ready => 'Жәнеәйын';

  @override
  String get common_error => 'Қате';

  @override
  String get common_yes => 'Иә';

  @override
  String get common_no => 'Жоқ';

  @override
  String get common_back => 'Артқа';

  @override
  String get common_continue => 'Жалғастыру';

  @override
  String get common_loading => 'Жүктелуде…';

  @override
  String get common_copy => 'Көшіру';

  @override
  String get common_share => 'Бөлісу';

  @override
  String get common_settings => 'Параметрлер';

  @override
  String get common_today => 'Бүгін';

  @override
  String get common_yesterday => 'Кеше';

  @override
  String get e2ee_qr_title => 'QR-pairing ключа';

  @override
  String get e2ee_qr_uid_error => 'Сәтсіз получить uid пользователя.';

  @override
  String get e2ee_qr_session_ended_error =>
      'Сессия завершилась до ответа второго құрылғылар.';

  @override
  String get e2ee_qr_no_data_error => 'Жоқ деректер для применения ключа.';

  @override
  String get e2ee_qr_key_transferred_toast =>
      'Ключ перенесён. Перезайдите в чаттар, небы жаңарту сессии.';

  @override
  String get e2ee_qr_wrong_account_error =>
      'QR сгенерирован под басқа аккаунт.';

  @override
  String get e2ee_qr_explainer_title => 'Не бұл';

  @override
  String get e2ee_qr_explainer_text =>
      'Передача приватного ключа одного сіздіңего құрылғылар на басқа по ECDH + QR. Обе стороны видят 6-значный код для ручной сверки.';

  @override
  String get e2ee_qr_show_qr_label => 'Мен на новом құрылғыда — показать QR';

  @override
  String get e2ee_qr_scan_qr_label => 'У меня уже бар ключ — сканировать QR';

  @override
  String get e2ee_qr_scan_hint =>
      'Отсканируйте QR на старом құрылғыда, қайда уже бар ключ.';

  @override
  String get e2ee_qr_verify_code_label =>
      'Сверьте 6-значный код со старым устройством:';

  @override
  String e2ee_qr_transfer_from_device_label(String label) {
    return 'Перенос құрылғылар: $label';
  }

  @override
  String get e2ee_qr_code_match_apply_label => 'Код совпал — применить';

  @override
  String get e2ee_qr_key_success_label =>
      'Ключ успешбірақ перенесён на бұл құрылғы. Перезайдите в чаттар.';

  @override
  String get e2ee_qr_unknown_error => 'Неизвестная қате';

  @override
  String get e2ee_qr_back_to_pick_label => 'К сізбору';

  @override
  String get e2ee_qr_donor_scan_hint =>
      'Наведите камеру на QR, показанный на новом құрылғыда.';

  @override
  String get e2ee_qr_donor_verify_code_label =>
      'Сверьте код носізм устройством:';

  @override
  String get e2ee_qr_donor_verify_hint =>
      'Еслжәне код совпадает — подтвердите на новом құрылғыда. Еслжәне жоқ, немедленбірақ нажмите «Болдырмау».';

  @override
  String get e2ee_encrypt_title => 'Шифрлау';

  @override
  String get e2ee_encrypt_enable_dialog_title => 'Қосу шифрлау?';

  @override
  String get e2ee_encrypt_enable_dialog_body =>
      'Носізе хабарламалар будут қолжетімділікны только на сіздіңих устройствах және у собеседника. Ескі хабарламалар останутся қалай бар.';

  @override
  String get e2ee_encrypt_enable_label => 'Қосу';

  @override
  String get e2ee_encrypt_disable_dialog_title => 'Отключить шифрлау?';

  @override
  String get e2ee_encrypt_disable_dialog_body =>
      'Носізе хабарламалар пойдут без сквозного шифрования. Ранее отправленные зашифрованные хабарламалар останутся в ленте.';

  @override
  String get e2ee_encrypt_disable_label => 'Отключить';

  @override
  String get e2ee_encrypt_status_on =>
      'Сквозное шифрлау включебірақ для этого чаттың.';

  @override
  String get e2ee_encrypt_status_off => 'Сквозное шифрлау сізключено.';

  @override
  String get e2ee_encrypt_description =>
      'Қашан шифрлау включено, содержимое носізх хабарламалар қолжетімділікбірақ только усағаттникам чаттың на их устройствах. Отключение влияет только на носізе хабарламалар.';

  @override
  String get e2ee_encrypt_switch_title => 'Қосу шифрлау';

  @override
  String e2ee_encrypt_switch_on(int epoch) {
    return 'Қосулы (эпоха ключа: $epoch)';
  }

  @override
  String get e2ee_encrypt_switch_off => 'Өшірулі';

  @override
  String get e2ee_encrypt_already_on_toast =>
      'Шифрлау уже включебірақ немесе сәтсіз создать ключи. Проверьте сеть және наличие ключей у собеседника.';

  @override
  String get e2ee_encrypt_no_device_toast =>
      'Сәтсіз включить: у собеседника жоқ активного құрылғылар ключом.';

  @override
  String e2ee_encrypt_enable_failed_toast(String error) {
    return 'Сәтсіз включить шифрлау: $error';
  }

  @override
  String e2ee_encrypt_disable_failed_toast(String error) {
    return 'Сәтсіз отключить: $error';
  }

  @override
  String get e2ee_encrypt_data_types_title => 'Типы деректер';

  @override
  String get e2ee_encrypt_data_types_description =>
      'Баптау не меняет протокол. Она управляет тем, қалайие типы деректер отправлять в зашифрованном виде.';

  @override
  String get e2ee_encrypt_override_title =>
      'Параметрлер шифрования для этого чаттың';

  @override
  String get e2ee_encrypt_override_on => 'Используются чатосізе настройки.';

  @override
  String get e2ee_encrypt_override_off => 'Наследуются глобальные настройки.';

  @override
  String get e2ee_encrypt_text_title => 'Текст хабарламалар';

  @override
  String get e2ee_encrypt_media_title => 'Вложения (медиа/файлдар)';

  @override
  String get e2ee_encrypt_override_hint =>
      'Небы изменить для этого чаттың — включите «Переопределить».';

  @override
  String get sticker_default_pack_name => 'Мой пак';

  @override
  String get sticker_new_pack_dialog_title => 'Носізй стикерпак';

  @override
  String get sticker_pack_name_hint => 'Название';

  @override
  String get sticker_save_to_pack => 'Сақтау в стикерпак';

  @override
  String get sticker_no_packs_hint =>
      'Жоқ паков. Создайте пак на вкладке «Стикеры».';

  @override
  String get sticker_new_pack_option => 'Носізй пак…';

  @override
  String get sticker_pick_image_or_gif => 'Сізберите сурет немесе GIF';

  @override
  String sticker_send_failed(String error) {
    return 'Сәтсіз отправить: $error';
  }

  @override
  String get sticker_saved_to_pack => 'Сақталды в стикерпак';

  @override
  String get sticker_save_gif_failed => 'Сәтсіз скачать немесе сохранить GIF';

  @override
  String get sticker_delete_pack_title => 'Жою пак?';

  @override
  String sticker_delete_pack_body(String name) {
    return '«$name» және барлығы стикеры в нём будут удалены.';
  }

  @override
  String get sticker_pack_deleted => 'Пак удалён';

  @override
  String get sticker_pack_delete_failed => 'Сәтсіз удалить пак';

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
  String get sticker_new_pack_tooltip => 'Носізй пак';

  @override
  String get sticker_pack_created => 'Стикерпак создан';

  @override
  String get sticker_no_packs_create => 'Жоқ стикерпаков. Создайте носізй.';

  @override
  String get sticker_public_packs_empty => 'Общие пакжәне не настроены';

  @override
  String get sticker_section_recent => 'НЕДАВНИЕ';

  @override
  String get sticker_pack_empty_hint =>
      'Пак пуст. Добавьте құрылғылар (вкладка GIF — «В мой пак»).';

  @override
  String get sticker_delete_sticker_title => 'Жою стикер?';

  @override
  String get sticker_deleted => 'Жойылды';

  @override
  String get sticker_gallery => 'Галерея';

  @override
  String get sticker_gallery_subtitle =>
      'Фото, PNG, GIF құрылғылар — сразу в чат';

  @override
  String get gif_search_hint => 'Іздеу GIF…';

  @override
  String gif_translated_hint(String query) {
    return 'Искали: $query';
  }

  @override
  String get gif_search_unavailable =>
      'Іздеу GIF временбірақ неқолжетімділікен.';

  @override
  String get gif_filter_all => 'Барлығы';

  @override
  String get sticker_section_animated => 'АНИМИРОВАННЫЕ';

  @override
  String get sticker_emoji_unavailable =>
      'Эмодзжәне в текст неқолжетімділікны для этого окна.';

  @override
  String get sticker_create_pack_hint => 'Создайте пак кнопкой +';

  @override
  String get sticker_public_packs_unavailable =>
      'Общие пакжәне әзірге неқолжетімділікны';

  @override
  String get composer_link_title => 'Сілтеме';

  @override
  String get composer_link_apply => 'Применить';

  @override
  String get composer_attach_title => 'Прикрепить';

  @override
  String get composer_attach_photo_video => 'Фото/Видео';

  @override
  String get composer_attach_files => 'Файлдар';

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
  String get meeting_create_poll => 'Құру опрос';

  @override
  String get meeting_min_two_options => 'Ең аз 2 варианта ответа';

  @override
  String meeting_error_with_details(String details) {
    return 'Қате: $details';
  }

  @override
  String meeting_polls_load_error(String details) {
    return 'Сәтсіз загрузить опросы: $details';
  }

  @override
  String get meeting_no_polls_yet => 'Әзірге жоқ опросов';

  @override
  String get meeting_question_label => 'Вопрос';

  @override
  String get meeting_options_label => 'Варианты';

  @override
  String meeting_option_hint(int index) {
    return 'Вариант $index';
  }

  @override
  String get meeting_add_option => 'Қосу вариант';

  @override
  String get meeting_anonymous => 'Анонимно';

  @override
  String get meeting_anonymous_subtitle => 'Кім увидит сізбор других';

  @override
  String get meeting_save_as_draft => 'В черновики';

  @override
  String get meeting_publish => 'Жариялау';

  @override
  String get meeting_action_start => 'Запустить';

  @override
  String get meeting_action_change_vote => 'Өзгерту голос';

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
  String get meeting_who_voted => 'Кім голосовал';

  @override
  String meeting_participants_tab(int count) {
    return 'Усағаттникжәне ($count)';
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
    return 'Заявкжәне ($count)';
  }

  @override
  String meeting_you_suffix(String name) {
    return '$name (Сіз)';
  }

  @override
  String get meeting_host_label => 'Хост';

  @override
  String get meeting_force_mute_mic => 'Өшіру микрофон';

  @override
  String get meeting_force_mute_camera => 'Өшіру камеру';

  @override
  String get meeting_kick_from_room => 'Жою из комнаты';

  @override
  String meeting_chat_load_error(Object error) {
    return 'Сәтсіз загрузить чат: $error';
  }

  @override
  String get meeting_no_requests => 'Жоқ носізх заявок';

  @override
  String get meeting_no_messages_yet => 'Әзірге жоқ хабарламалар';

  @override
  String meeting_file_too_large(String name) {
    return 'Файл слишком большой: $name';
  }

  @override
  String meeting_send_failed(String details) {
    return 'Сәтсіз отправить: $details';
  }

  @override
  String get meeting_edit_message_title => 'Өзгерту хабарлама';

  @override
  String meeting_save_failed(String details) {
    return 'Сәтсіз сохранить: $details';
  }

  @override
  String get meeting_delete_message_title => 'Хабарламаны жою?';

  @override
  String get meeting_delete_message_body =>
      'Усағаттникжәне увидят «Хабарлама удалено».';

  @override
  String meeting_delete_failed(String details) {
    return 'Сәтсіз удалить: $details';
  }

  @override
  String get meeting_message_hint => 'Хабарлама…';

  @override
  String get meeting_message_deleted => 'Хабарлама удалено';

  @override
  String get meeting_message_edited => '• изм.';

  @override
  String get meeting_copy_action => 'Көшіру';

  @override
  String get meeting_edit_action => 'Өзгерту';

  @override
  String get meeting_join_title => 'Қосылу';

  @override
  String meeting_loading_error(String details) {
    return 'Қате загрузкжәне митинга: $details';
  }

  @override
  String get meeting_not_found => 'Митинг не найден немесе закрыт';

  @override
  String get meeting_private_description =>
      'Приватная кездесу: после заявкжәне хост решит, пустить лжәне вас.';

  @override
  String get meeting_public_description =>
      'Открытая кездесу: присоединяйтесь по сілтемеде без ожидания.';

  @override
  String get meeting_your_name_label => 'Сіздіңе аты';

  @override
  String get meeting_enter_name_error => 'Укажите аты';

  @override
  String get meeting_guest_name => 'Гость';

  @override
  String get meeting_enter_room => 'Кіру в комнату';

  @override
  String get meeting_request_join => 'Попросить қосылу';

  @override
  String get meeting_approved_title => 'Одобрено';

  @override
  String get meeting_approved_subtitle => 'Перенаправляем в комнату…';

  @override
  String get meeting_denied_title => 'Отклонено';

  @override
  String get meeting_denied_subtitle => 'Хост отклонил сіздіңу заявку.';

  @override
  String get meeting_pending_title => 'Ожидаем подтверждения';

  @override
  String get meeting_pending_subtitle =>
      'Хост увидит сіздіңу заявку және решит, қашан впустить.';

  @override
  String meeting_load_error(String details) {
    return 'Сәтсіз загрузить митинг: $details';
  }

  @override
  String meeting_init_error(Object error) {
    return 'Қате инициализации: $error';
  }

  @override
  String meeting_participants_error(Object error) {
    return 'Усағаттники: $error';
  }

  @override
  String meeting_bg_unavailable(Object error) {
    return 'Фон неқолжетімділікен: $error';
  }

  @override
  String get meeting_leave => 'Шығу';

  @override
  String get meeting_screen_share_ios =>
      'Экранды бөлісу на iOS требует Broadcast Extension (болады в следующем релизе)';

  @override
  String meeting_screen_share_failed(String details) {
    return 'Сәтсіз запустить демонстрацию: $details';
  }

  @override
  String get meeting_tooltip_speaker_mode => 'Режим спикера';

  @override
  String get meeting_tooltip_grid_mode => 'Режим сетки';

  @override
  String get meeting_tooltip_copy_link => 'Сілтемені көшіру (браузерден кіру)';

  @override
  String get meeting_mic_on => 'Дыбысын қосу';

  @override
  String get meeting_mic_off => 'Өшіру';

  @override
  String get meeting_camera_on => 'Камера вкл';

  @override
  String get meeting_camera_off => 'Камера сізкл';

  @override
  String get meeting_switch_camera => 'Ауыстыру';

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
  String get meeting_participants_button => 'Усағаттники';

  @override
  String get meeting_notifications_button => 'Белсенділік';

  @override
  String get meeting_pip_button => 'Кішірейту';

  @override
  String get settings_chats_bottom_nav_icons_title => 'Иконкжәне нижнего меню';

  @override
  String get settings_chats_bottom_nav_icons_subtitle =>
      'Сізбор иконок және визуального стиля қалай на вебе.';

  @override
  String get settings_chats_nav_colorful => 'Цветные';

  @override
  String get settings_chats_nav_minimal => 'Минимализм';

  @override
  String get settings_chats_nav_global_title => 'Для барлығых иконок';

  @override
  String get settings_chats_nav_global_subtitle =>
      'Общий слой: цвет, өлшем, толщина және фон плитки.';

  @override
  String get settings_chats_reset_tooltip => 'Сброс';

  @override
  String get settings_chats_collapse => 'Скрыть';

  @override
  String get settings_chats_customize => 'Баптау';

  @override
  String get settings_chats_reset_item_tooltip => 'Сбросить';

  @override
  String get settings_chats_style_tooltip => 'Стиль';

  @override
  String get settings_chats_icon_size => 'Өлшем иконки';

  @override
  String get settings_chats_stroke_width => 'Толщина линии';

  @override
  String get settings_chats_default => 'По умолчанию';

  @override
  String get settings_chats_icon_search_hint_en =>
      'Іздеу по названию (англ.)...';

  @override
  String get settings_chats_emoji_effects => 'Эффекты эмодзи';

  @override
  String get settings_chats_emoji_effects_subtitle =>
      'Профиль анимацижәне fullscreen-эмодзжәне пржәне тапе по одиночному эмодзжәне в чатта.';

  @override
  String get settings_chats_emoji_lite_desc =>
      'Lite: ең аз нагрузкжәне және максимальбірақ плавбірақ на слабых устройствах.';

  @override
  String get settings_chats_emoji_balanced_desc =>
      'Balanced: автоматический компромисс между производительностью және сізразительностью.';

  @override
  String get settings_chats_emoji_cinematic_desc =>
      'Cinematic: ең көп сағаттиц және глубины для вау-эффекта.';

  @override
  String get settings_chats_preview_incoming_msg => 'Сәлем! Қалай дела?';

  @override
  String get settings_chats_preview_outgoing_msg => 'Тамаша, рахмет!';

  @override
  String get settings_chats_preview_hello => 'Сәлем';

  @override
  String get chat_theme_title => 'Солқырып чаттың';

  @override
  String chat_theme_error_save(String error) {
    return 'Сәтсіз сохранить фон: $error';
  }

  @override
  String chat_theme_error_upload(String error) {
    return 'Қате загрузкжәне фона: $error';
  }

  @override
  String get chat_theme_delete_title => 'Жою фон из галереи?';

  @override
  String get chat_theme_delete_body =>
      'Сурет пропадёт из тізімнің своих фонов. Для этого чаттың можбірақ сізбрать басқа.';

  @override
  String chat_theme_error_delete(String error) {
    return 'Қате удаления: $error';
  }

  @override
  String get chat_theme_banner =>
      'Фон этой перепискжәне только для вас. Общие настройкжәне чатов в разделе «Параметрлер чатов» не меняются.';

  @override
  String get chat_theme_current_bg => 'Текущий фон';

  @override
  String get chat_theme_default_global => 'По умолчанию (общие настройки)';

  @override
  String get chat_theme_presets => 'Пресеты';

  @override
  String get chat_theme_global_tile => 'Общие';

  @override
  String get chat_theme_pick_hint => 'Сізберите пресет немесе фото из галереи';

  @override
  String get contacts_title => 'Контактілер';

  @override
  String get contacts_add_phone_prompt =>
      'Добавьте телефон в профиле, небы искать контактілер по нөміру.';

  @override
  String get contacts_fallback_profile => 'Профиль';

  @override
  String get contacts_fallback_user => 'Пользователь';

  @override
  String get contacts_status_online => 'онлайн';

  @override
  String get contacts_status_recently => 'Болды (а) жақында';

  @override
  String contacts_status_today_at(String time) {
    return 'Болды (а) в $time';
  }

  @override
  String get contacts_status_yesterday => 'Болды (а) кеше';

  @override
  String get contacts_status_year_ago => 'Болды (а) жыл назад';

  @override
  String contacts_status_years_ago(String years) {
    return 'Болды (а) $years назад';
  }

  @override
  String contacts_status_date(String date) {
    return 'Болды (а) $date';
  }

  @override
  String get contacts_empty_state =>
      'Контактілер не найдены.\nНажмите кнопку справа, небы синхронизировать телефонную книгу.';

  @override
  String get add_contact_title => 'Носізй контакт';

  @override
  String get add_contact_sync_off => 'Синхронизация сізключена в приложении.';

  @override
  String get add_contact_enable_system_access =>
      'Қосулыючите қолжетімділік контактам для LighChat в настройках систақырыптар.';

  @override
  String get add_contact_sync_on => 'Синхронизация включена';

  @override
  String get add_contact_sync_failed =>
      'Сәтсіз включить синхронизацию контактілер';

  @override
  String get add_contact_invalid_phone => 'Енгізіңіз корректный телефон нөмірі';

  @override
  String get add_contact_not_found_by_phone =>
      'Контакт по этому нөміру не найден';

  @override
  String get add_contact_found => 'Контакт найден';

  @override
  String add_contact_search_error(String error) {
    return 'Сәтсіз сізполнить поиск: $error';
  }

  @override
  String get add_contact_qr_no_profile => 'QR-код не содержит профиль LighChat';

  @override
  String get add_contact_qr_own_profile => 'Бұл сіздің собственный профиль';

  @override
  String get add_contact_qr_profile_not_found => 'Профиль из QR-кода не найден';

  @override
  String get add_contact_qr_found => 'Контакт найден по QR-коду';

  @override
  String add_contact_qr_read_error(String error) {
    return 'Сәтсіз оқу QR-код: $error';
  }

  @override
  String get add_contact_cannot_add_user =>
      'Болмайды добавить этого пользователя';

  @override
  String add_contact_add_error(String error) {
    return 'Сәтсіз добавить контакт: $error';
  }

  @override
  String get add_contact_country_search_hint => 'Іздеу страны немесе кода';

  @override
  String get add_contact_sync_with_phone => 'Синхронизировать телефоном';

  @override
  String get add_contact_add_by_qr => 'Қосу по QR-коду';

  @override
  String get add_contact_results_unavailable =>
      'Результаты әзірге неқолжетімділікны';

  @override
  String add_contact_profile_load_error(String error) {
    return 'Қате загрузкжәне контакта: $error';
  }

  @override
  String get add_contact_profile_not_found => 'Профиль не найден';

  @override
  String get add_contact_badge_already_added => 'Уже в контактах';

  @override
  String get add_contact_badge_new => 'Носізй контакт';

  @override
  String get add_contact_badge_unavailable => 'Неқолжетімділікно';

  @override
  String get add_contact_open_contact => 'Ашу контакт';

  @override
  String get add_contact_add_to_contacts => 'Қосу в контактілер';

  @override
  String get add_contact_add_unavailable => 'Добавление неқолжетімділікно';

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
  String get contacts_edit_enter_name => 'Енгізіңіз аты контакта.';

  @override
  String contacts_edit_save_error(String error) {
    return 'Сәтсіз сохранить контакт: $error';
  }

  @override
  String get contacts_edit_first_name_hint => 'Аты';

  @override
  String get contacts_edit_last_name_hint => 'Тегі';

  @override
  String get contacts_edit_name_disclaimer =>
      'Бұл аты видбірақ только вам: в чаттыңх, поиске және тізімде контактілер.';

  @override
  String contacts_edit_error(String error) {
    return 'Қате: $error';
  }

  @override
  String get chat_settings_color_default => 'По умолчанию';

  @override
  String get chat_settings_color_lilac => 'Лилосізй';

  @override
  String get chat_settings_color_pink => 'Розосізй';

  @override
  String get chat_settings_color_green => 'Зелёный';

  @override
  String get chat_settings_color_coral => 'Кораллосізй';

  @override
  String get chat_settings_color_mint => 'Мята';

  @override
  String get chat_settings_color_sky => 'Небесный';

  @override
  String get chat_settings_color_purple => 'Фиожылосізй';

  @override
  String get chat_settings_color_crimson => 'Малиносізй';

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
  String get chat_settings_icon_size => 'Өлшем иконки';

  @override
  String get chat_settings_stroke_width => 'Толщина линии';

  @override
  String get chat_settings_tile_background => 'Фон плиткжәне под иконкой';

  @override
  String get chat_settings_bottom_nav_icons => 'Иконкжәне нижнего меню';

  @override
  String get chat_settings_bottom_nav_description =>
      'Сізбор иконок және визуального стиля қалай на вебе.';

  @override
  String get chat_settings_bottom_nav_global_description =>
      'Общий слой: цвет, өлшем, толщина және фон плитки.';

  @override
  String get chat_settings_colorful => 'Цветные';

  @override
  String get chat_settings_minimalism => 'Минимализм';

  @override
  String get chat_settings_for_all_icons => 'Для барлығых иконок';

  @override
  String get chat_settings_customize => 'Баптау';

  @override
  String get chat_settings_hide => 'Скрыть';

  @override
  String get chat_settings_reset => 'Сброс';

  @override
  String get chat_settings_reset_item => 'Сбросить';

  @override
  String get chat_settings_style => 'Стиль';

  @override
  String get chat_settings_select => 'Сізбрать';

  @override
  String get chat_settings_reset_size => 'Сбросить өлшем';

  @override
  String get chat_settings_reset_stroke => 'Сбросить толщину';

  @override
  String get chat_settings_default_gradient => 'Градиент по умолчанию';

  @override
  String get chat_settings_inherit_global => 'Наследовать глобальных';

  @override
  String get chat_settings_no_bg_on => 'Без фона (вкл.)';

  @override
  String get chat_settings_no_bg => 'Без фона';

  @override
  String get chat_settings_outgoing_messages => 'Исжүрісящие хабарламалар';

  @override
  String get chat_settings_incoming_messages => 'Вжүрісящие хабарламалар';

  @override
  String get chat_settings_font_size => 'Өлшем шрифта';

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
  String get chat_settings_chat_background => 'Фон чаттың';

  @override
  String get chat_settings_background_hint =>
      'Сізберите фото из галережәне немесе настройте';

  @override
  String get chat_settings_emoji_effects => 'Эффекты эмодзи';

  @override
  String get chat_settings_emoji_description =>
      'Профиль анимацижәне fullscreen-эмодзжәне пржәне тапе по одиночному эмодзжәне в чатта.';

  @override
  String get chat_settings_emoji_lite =>
      'Lite: ең аз нагрузкжәне және максимальбірақ плавбірақ на слабых устройствах.';

  @override
  String get chat_settings_emoji_cinematic =>
      'Cinematic: ең көп сағаттиц және глубины для вау-эффекта.';

  @override
  String get chat_settings_emoji_balanced =>
      'Balanced: автоматический компромисс между производительностью және сізразительностью.';

  @override
  String get chat_settings_additional => 'Дополнительно';

  @override
  String get chat_settings_show_time => 'Показывать время';

  @override
  String get chat_settings_show_time_hint =>
      'Время отправкжәне под хабарламаларми';

  @override
  String get chat_settings_reset_all => 'Сбросить настройки';

  @override
  String get chat_settings_preview_incoming => 'Сәлем! Қалай дела?';

  @override
  String get chat_settings_preview_outgoing => 'Тамаша, рахмет!';

  @override
  String get chat_settings_preview_hello => 'Сәлем';

  @override
  String chat_settings_icon_picker_title(String label) {
    return 'Иконка: «$label»';
  }

  @override
  String get chat_settings_search_hint => 'Іздеу по названию (англ.)...';

  @override
  String meeting_tab_participants(Object count) {
    return 'Усағаттникжәне ($count)';
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
    return 'Заявкжәне ($count)';
  }

  @override
  String get meeting_kick => 'Жою из комнаты';

  @override
  String meeting_file_too_big(Object name) {
    return 'Файл слишком большой: $name';
  }

  @override
  String meeting_send_error(Object error) {
    return 'Сәтсіз отправить: $error';
  }

  @override
  String meeting_save_error(Object error) {
    return 'Сәтсіз сохранить: $error';
  }

  @override
  String meeting_delete_error(Object error) {
    return 'Сәтсіз удалить: $error';
  }

  @override
  String get meeting_no_messages => 'Әзірге жоқ хабарламалар';

  @override
  String get meeting_join_enter_name => 'Укажите аты';

  @override
  String get meeting_join_guest => 'Гость';

  @override
  String get meeting_join_as_label => 'Сіз мына атпен қосыласыз';

  @override
  String get meeting_lobby_camera_blocked =>
      'Камераға рұқсат берілмеген. Сіз камера өшірулі күйде қосыласыз.';

  @override
  String get meeting_join_button => 'Қосылу';

  @override
  String meeting_join_load_error(Object error) {
    return 'Қате загрузкжәне митинга: $error';
  }

  @override
  String get meeting_private_hint =>
      'Приватная кездесу: после заявкжәне хост решит, пустить лжәне вас.';

  @override
  String get meeting_public_hint =>
      'Открытая кездесу: присоединяйтесь по сілтемеде без ожидания.';

  @override
  String get meeting_name_label => 'Сіздіңе аты';

  @override
  String get meeting_waiting_title => 'Ожидаем подтверждения';

  @override
  String get meeting_waiting_subtitle =>
      'Хост увидит сіздіңу заявку және решит, қашан впустить.';

  @override
  String get meeting_screen_share_ios_hint =>
      'Экранды бөлісу на iOS требует Broadcast Extension (в разработке).';

  @override
  String meeting_screen_share_error(Object error) {
    return 'Сәтсіз запустить демонстрацию: $error';
  }

  @override
  String get meeting_speaker_mode => 'Режим спикера';

  @override
  String get meeting_grid_mode => 'Режим сетки';

  @override
  String get meeting_copy_link_tooltip => 'Сілтемені көшіру (вжүріс браузера)';

  @override
  String get group_members_subtitle_creator => 'Создатель топтар';

  @override
  String get group_members_subtitle_admin => 'Әкімші';

  @override
  String get group_members_subtitle_member => 'Усағаттник';

  @override
  String group_members_total_count(int count) {
    return 'Барлығыго: $count';
  }

  @override
  String get group_members_copy_invite_tooltip => 'Сілтемені көшіру-шақыру';

  @override
  String get group_members_add_member_tooltip => 'Қосу усағаттника';

  @override
  String get group_members_invite_copied => 'Сілтеме-шақыру скопирована';

  @override
  String group_members_copy_link_error(String error) {
    return 'Сәтсіз скопировать сілтемені: $error';
  }

  @override
  String get group_members_added => 'Усағаттникжәне добавлены';

  @override
  String get group_members_revoke_admin_title => 'Снять права әкімшіні?';

  @override
  String group_members_revoke_admin_body(String name) {
    return 'У $name будут сняты права әкімшіні. Усағаттник останется в группе қалай обычный член.';
  }

  @override
  String get group_members_grant_admin_title => 'Назначить администратором?';

  @override
  String group_members_grant_admin_body(String name) {
    return '$name получит права әкімшіні: сможет редактировать топты, исключать усағаттников және управлять хабарламаларми.';
  }

  @override
  String get group_members_revoke_admin_action => 'Снять права';

  @override
  String get group_members_grant_admin_action => 'Назначить';

  @override
  String get group_members_remove_title => 'Исключить усағаттника?';

  @override
  String group_members_remove_body(String name) {
    return '$name болады удалён из топтар. Бұл әрекет можбірақ отменить, добавив усағаттника заново.';
  }

  @override
  String get group_members_remove_action => 'Исключить';

  @override
  String get group_members_removed => 'Усағаттник исключён';

  @override
  String get group_members_menu_revoke_admin => 'Снять админа';

  @override
  String get group_members_menu_grant_admin => 'Сделать админом';

  @override
  String get group_members_menu_remove => 'Исключить из топтар';

  @override
  String get group_members_creator_badge => 'СОЗДАТЕЛЬ';

  @override
  String get group_members_add_title => 'Қосу усағаттников';

  @override
  String get group_members_search_contacts => 'Іздеу среджәне контактілер';

  @override
  String get group_members_all_in_group =>
      'Барлығы сіздіңжәне контактілер уже в группе.';

  @override
  String get group_members_nobody_found => 'Никого не найдено.';

  @override
  String get group_members_user_fallback => 'Пользователь';

  @override
  String get group_members_select_members => 'Сізберите усағаттников';

  @override
  String group_members_add_count(int count) {
    return 'Қосу ($count)';
  }

  @override
  String group_members_contacts_load_error(String error) {
    return 'Сәтсіз загрузить контактілер: $error';
  }

  @override
  String group_members_auth_error(String error) {
    return 'Қате авторизации: $error';
  }

  @override
  String group_members_add_failed(String error) {
    return 'Сәтсіз добавить усағаттников: $error';
  }

  @override
  String get group_not_found => 'Топ не найдена.';

  @override
  String get group_not_member => 'Сіз не являетесь усағаттником этой топтар.';

  @override
  String get poll_create_title => 'Опрос в чатта';

  @override
  String get poll_question_label => 'Вопрос';

  @override
  String get poll_question_hint => 'Например: Во сколько кездесуемся?';

  @override
  String get poll_description_label => 'Пояснение (міндетті емес)';

  @override
  String get poll_options_title => 'Варианты';

  @override
  String poll_option_hint(int index) {
    return 'Вариант $index';
  }

  @override
  String get poll_add_option => 'Қосу вариант';

  @override
  String get poll_switch_anonymous => 'Анонимное голосование';

  @override
  String get poll_switch_anonymous_sub => 'Не показывать, кім за не голосовал';

  @override
  String get poll_switch_multi => 'Несколько ответов';

  @override
  String get poll_switch_multi_sub => 'Можбірақ сізбрать несколько вариантов';

  @override
  String get poll_switch_add_options => 'Добавление вариантов';

  @override
  String get poll_switch_add_options_sub =>
      'Усағаттникжәне могут предложить свой вариант';

  @override
  String get poll_switch_revote => 'Можбірақ изменить голос';

  @override
  String get poll_switch_revote_sub => 'Переголосование до закрытия';

  @override
  String get poll_switch_shuffle => 'Перемешать варианты';

  @override
  String get poll_switch_shuffle_sub => 'Свой порядок у каждого усағаттника';

  @override
  String get poll_switch_quiz => 'Режим викімрины';

  @override
  String get poll_switch_quiz_sub => 'Один правильный ответ';

  @override
  String get poll_correct_option_label => 'Правильный вариант';

  @override
  String get poll_quiz_explanation_label => 'Пояснение (міндетті емес)';

  @override
  String get poll_close_by_time => 'Жабу по времени';

  @override
  String get poll_close_not_set => 'Не задано';

  @override
  String get poll_close_reset => 'Сбросить срок';

  @override
  String get poll_publish => 'Жариялау';

  @override
  String get poll_error_empty_question => 'Енгізіңіз вопрос';

  @override
  String get poll_error_min_options => 'Нужбірақ ең аз 2 варианта';

  @override
  String get poll_error_select_correct => 'Сізберите правильный вариант';

  @override
  String get poll_error_future_time =>
      'Время закрытия должбірақ быть в будущем';

  @override
  String get poll_unavailable => 'Опрос неқолжетімділікен';

  @override
  String get poll_loading => 'Жүктелуде опроса…';

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
  String get poll_badge_quiz => 'Викімрина';

  @override
  String get poll_menu_restart => 'Перезапустить';

  @override
  String get poll_menu_end => 'Завершить';

  @override
  String get poll_menu_delete => 'Жою';

  @override
  String get poll_submit_vote => 'Жіберу голос';

  @override
  String get poll_suggest_option_hint => 'Предложить вариант';

  @override
  String get poll_revote => 'Переголосовать';

  @override
  String poll_votes_count(int count) {
    return '$count голосов';
  }

  @override
  String get poll_show_voters => 'Кім голосовал';

  @override
  String get poll_hide_voters => 'Скрыть';

  @override
  String get poll_vote_error => 'Қате пржәне голосовании';

  @override
  String get poll_add_option_error => 'Сәтсіз добавить вариант';

  @override
  String get poll_error_generic => 'Қате';

  @override
  String get durak_your_turn => 'Твой жүріс';

  @override
  String get durak_winner_label => 'Жеңімпаз';

  @override
  String get durak_rematch => 'Сыграть ещё раз';

  @override
  String get durak_surrender_tooltip => 'Завершить игру';

  @override
  String get durak_close_tooltip => 'Жабу';

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
  String get durak_foul_banner_title => 'Шулер! Не заметнемесе:';

  @override
  String get durak_pending_resolution_attacker =>
      'Ожидание фолла… Нажмжәне «Растау Бито», еслжәне барлығы согласны.';

  @override
  String get durak_pending_resolution_other =>
      'Ожидание фолла… Енді можбірақ нажать «Фолл!», еслжәне заметил шулерство.';

  @override
  String durak_tournament_played(int finished, int total) {
    return 'Сыграбірақ $finished из $total';
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
  String get durak_lobby_game_unavailable =>
      'Ойын неқолжетімділікна немесе болды удалена';

  @override
  String get durak_lobby_back_tooltip => 'Артқа';

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
  String get durak_dm_game_created => 'Ойын \"Дурак\" создана';

  @override
  String get game_durak_subtitle => 'Одиночная партия немесе турнир';

  @override
  String get group_member_write_dm => 'Написать лично';

  @override
  String get group_member_open_dm_hint => 'Ашу личный чат усағаттником';

  @override
  String get group_member_profile_not_loaded =>
      'Профиль усағаттника ещё не загружен.';

  @override
  String group_member_open_dm_error(String error) {
    return 'Сәтсіз открыть личный чат: $error';
  }

  @override
  String get group_avatar_photo_title => 'Фото топтар';

  @override
  String get group_avatar_add_photo => 'Қосу фото';

  @override
  String get group_avatar_change => 'Ауыстыру аватар';

  @override
  String get group_avatar_remove => 'Убрать аватар';

  @override
  String group_avatar_process_error(String error) {
    return 'Сәтсіз обработать фото: $error';
  }

  @override
  String get group_mention_no_matches => 'Жоқ совпадений';

  @override
  String get durak_error_defense_does_not_beat => 'Осы карта не бьет атакующую';

  @override
  String get durak_error_only_attacker_first =>
      'Персізм жүрісит атакующий ойыншы';

  @override
  String get durak_error_defender_cannot_attack =>
      'Отбивающийся қазір не подкидывает';

  @override
  String get durak_error_not_allowed_throwin =>
      'Сіз не можете тастау в этом раунде';

  @override
  String get durak_error_throwin_not_your_turn =>
      'Қазір подкидывает басқа ойыншы';

  @override
  String get durak_error_rank_not_allowed =>
      'Тастау можбірақ только карту того же ранга';

  @override
  String get durak_error_cannot_throw_in => 'Көбірек карт тастау болмайды';

  @override
  String get durak_error_card_not_in_hand => 'Этой карталар уже жоқ в руке';

  @override
  String get durak_error_already_defended => 'Осы карта уже отбита';

  @override
  String get durak_error_bad_attack_index =>
      'Сізберите атакующую карту для защиты';

  @override
  String get durak_error_only_defender => 'Қазір отбивается басқа ойыншы';

  @override
  String get durak_error_defender_already_taking =>
      'Отбивающийся уже берет карталар';

  @override
  String get durak_error_game_not_active => 'Партия уже не активна';

  @override
  String get durak_error_not_in_lobby => 'Лоббжәне уже стартовало';

  @override
  String get durak_error_game_already_active => 'Партия уже началась';

  @override
  String get durak_error_active_game_exists =>
      'В этом чатта уже бар активная партия';

  @override
  String get durak_error_resolution_pending =>
      'Сначала завершите спорный жүріс';

  @override
  String get durak_error_rematch_failed =>
      'Сәтсіз подготовить реванш. Попробуйте еще раз';

  @override
  String get durak_error_unauthenticated => 'Нужбірақ войтжәне в аккаунт';

  @override
  String get durak_error_permission_denied =>
      'Бұл әрекет вам неқолжетімділікно';

  @override
  String get durak_error_invalid_argument => 'Некорректный жүріс';

  @override
  String get durak_error_failed_precondition => 'Жүріс қазір неқолжетімділікен';

  @override
  String get durak_error_server =>
      'Сәтсіз сізполнить жүріс. Попробуйте еще раз';

  @override
  String pinned_count(int count) {
    return 'Бекітілді: $count';
  }

  @override
  String get pinned_single => 'Бекітілді';

  @override
  String get pinned_unpin_tooltip => 'Босату';

  @override
  String get pinned_type_image => 'Сурет';

  @override
  String get pinned_type_video => 'Видео';

  @override
  String get pinned_type_video_circle => 'Видеокружок';

  @override
  String get pinned_type_voice => 'Голосовое хабарлама';

  @override
  String get pinned_type_poll => 'Опрос';

  @override
  String get pinned_type_link => 'Сілтеме';

  @override
  String get pinned_type_location => 'Локация';

  @override
  String get pinned_type_sticker => 'Стикер';

  @override
  String get pinned_type_file => 'Файл';

  @override
  String get call_entry_login_required_title => 'Необжүрісим вжүріс';

  @override
  String get call_entry_login_required_subtitle =>
      'Откройте приложение және войдите в аккаунт.';

  @override
  String get call_entry_not_found_title => 'Қоңырау не найден';

  @override
  String get call_entry_not_found_subtitle =>
      'Сіззов уже завершён немесе удалён. Возвращаемся звонкам…';

  @override
  String get call_entry_to_calls => 'К звонкам';

  @override
  String get call_entry_ended_title => 'Қоңырау завершён';

  @override
  String get call_entry_ended_subtitle =>
      'Осы сіззов уже неқолжетімділікен. Возвращаемся звонкам…';

  @override
  String get call_entry_caller_fallback => 'Собеседник';

  @override
  String get call_entry_opening_title => 'Открываем қоңырау…';

  @override
  String get call_entry_connecting_video => 'Қосылуда видеозвонку';

  @override
  String get call_entry_connecting_audio => 'Қосылуда аудиозвонку';

  @override
  String get call_entry_loading_subtitle => 'Жүктелуде деректер сіззова';

  @override
  String get call_entry_error_title => 'Қате открытия звонка';

  @override
  String chat_theme_save_error(Object error) {
    return 'Сәтсіз сохранить фон: $error';
  }

  @override
  String chat_theme_load_error(Object error) {
    return 'Қате загрузкжәне фона: $error';
  }

  @override
  String chat_theme_delete_error(Object error) {
    return 'Қате удаления: $error';
  }

  @override
  String get chat_theme_description =>
      'Фон этой перепискжәне только для вас. Общие настройкжәне чатов в разделе «Параметрлер чатов» не меняются.';

  @override
  String get chat_theme_default_bg => 'По умолчанию (общие настройки)';

  @override
  String get chat_theme_global_label => 'Общие';

  @override
  String get chat_theme_hint => 'Сізберите пресет немесе фото из галереи';

  @override
  String get date_today => 'Бүгін';

  @override
  String get date_yesterday => 'Кеше';

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
  String get video_circle_camera_unavailable => 'Камера неқолжетімділікна';

  @override
  String video_circle_camera_error(Object error) {
    return 'Сәтсіз открыть камеру: $error';
  }

  @override
  String video_circle_record_error(Object error) {
    return 'Қате записи: $error';
  }

  @override
  String get video_circle_file_not_found => 'Файл записжәне не найден';

  @override
  String get video_circle_play_error => 'Сәтсіз воспроизвестжәне запись';

  @override
  String video_circle_send_error(Object error) {
    return 'Сәтсіз отправить: $error';
  }

  @override
  String video_circle_switch_error(Object error) {
    return 'Сәтсіз переключить камеру: $error';
  }

  @override
  String video_circle_pause_error_detail(Object description, Object code) {
    return 'Пауза записжәне неқолжетімділікна: $description ($code)';
  }

  @override
  String video_circle_pause_error(Object error) {
    return 'Пауза записи: $error';
  }

  @override
  String get video_circle_camera_fallback_error => 'Қате камеры';

  @override
  String get video_circle_retry => 'Повторить';

  @override
  String get video_circle_sending => 'Жіберу...';

  @override
  String get video_circle_recorded => 'Кружок записан';

  @override
  String get video_circle_swipe_cancel => 'Влево - отмена';

  @override
  String media_screen_error(Object error) {
    return 'Қате загрузкжәне медиа: $error';
  }

  @override
  String get media_screen_title => 'Медиа, ссылкжәне және файлдар';

  @override
  String get media_tab_media => 'Медиа';

  @override
  String get media_tab_circles => 'Кружки';

  @override
  String get media_tab_files => 'Файлдар';

  @override
  String get media_tab_links => 'Сілтемелер';

  @override
  String get media_tab_audio => 'Аудио';

  @override
  String get media_empty_files => 'Жоқ файлов';

  @override
  String get media_empty_media => 'Жоқ медиа';

  @override
  String get media_attachment_fallback => 'Вложение';

  @override
  String get media_empty_circles => 'Жоқ кружков';

  @override
  String get media_empty_links => 'Жоқ ссылок';

  @override
  String get media_empty_audio => 'Дауыстық хабарламалар жоқ';

  @override
  String get media_sender_you => 'Сіз';

  @override
  String get media_sender_fallback => 'Усағаттник';

  @override
  String get call_detail_login_required => 'Необжүрісим вжүріс.';

  @override
  String get call_detail_not_found =>
      'Қоңырау не найден немесе жоқ қолжетімділіка.';

  @override
  String get call_detail_unknown => 'Неизвестный';

  @override
  String get call_detail_title => 'Сведения о звонке';

  @override
  String get call_detail_video => 'Видеоқоңырау';

  @override
  String get call_detail_audio => 'Аудиоқоңырау';

  @override
  String get call_detail_outgoing => 'Исжүрісящий';

  @override
  String get call_detail_incoming => 'Вжүрісящий';

  @override
  String get call_detail_date_label => 'Жәнеәсол:';

  @override
  String get call_detail_duration_label => 'Длительность:';

  @override
  String get call_detail_call_button => 'Қоңырау шалу';

  @override
  String get call_detail_video_button => 'Видео';

  @override
  String call_detail_error(Object error) {
    return 'Қате: $error';
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
  String get durak_cheater_label => 'Шулер! Не заметнемесе:';

  @override
  String get durak_waiting_foll_confirm =>
      'Ожидание фолла… Нажмжәне «Растау Бито», еслжәне барлығы согласны.';

  @override
  String get durak_waiting_foll_call =>
      'Ожидание фолла… Енді можбірақ нажать «Фолл!», еслжәне заметил шулерство.';

  @override
  String get durak_winner => 'Жеңімпаз';

  @override
  String get durak_play_again => 'Сыграть ещё раз';

  @override
  String durak_games_progress(Object finished, Object total) {
    return 'Сыграбірақ $finished из $total';
  }

  @override
  String get durak_next_round => 'Следующая партия турнира';

  @override
  String audio_call_error(Object error) {
    return 'Қате звонка: $error';
  }

  @override
  String get audio_call_ended => 'Қоңырау завершён';

  @override
  String get audio_call_missed => 'Пропущенный қоңырау';

  @override
  String get audio_call_cancelled => 'Звон��к отменен';

  @override
  String get audio_call_offer_not_ready =>
      'Оффер ещё не готов, попробуйте снова';

  @override
  String get audio_call_invalid_data => 'Некорректные деректер звонка';

  @override
  String audio_call_accept_error(Object error) {
    return 'Сәтсіз принять қоңырау: $error';
  }

  @override
  String get audio_call_incoming => 'Вжүрісящий аудиоқоңырау';

  @override
  String get audio_call_calling => 'Аудиоқоңырау…';

  @override
  String privacy_save_error(Object error) {
    return 'Сәтсіз сохранить настройки: $error';
  }

  @override
  String privacy_load_error(Object error) {
    return 'Қате загрузкжәне приватности: $error';
  }

  @override
  String get privacy_visibility => 'Видимость';

  @override
  String get privacy_online_status => 'Мәртебе онлайн';

  @override
  String get privacy_last_visit => 'Соңғы визит';

  @override
  String get privacy_read_receipts => 'Индикатор прочтения';

  @override
  String get privacy_profile_info => 'Ақпарат профиля';

  @override
  String get privacy_phone_number => 'Телефон нөмірі';

  @override
  String get privacy_birthday => 'Жәнеәсол рождения';

  @override
  String get privacy_about => 'О себе';

  @override
  String starred_load_error(Object error) {
    return 'Қате загрузкжәне избранного: $error';
  }

  @override
  String get starred_title => 'Таңдаулылар';

  @override
  String get starred_empty => 'В этом чатта жоқ избранных хабарламалар';

  @override
  String get starred_message_fallback => 'Хабарлама';

  @override
  String get starred_sender_you => 'Сіз';

  @override
  String get starred_sender_fallback => 'Усағаттник';

  @override
  String get starred_type_poll => 'Опрос';

  @override
  String get starred_type_location => 'Локация';

  @override
  String get starred_type_attachment => 'Вложение';

  @override
  String starred_today_prefix(Object time) {
    return 'Бүгін, $time';
  }

  @override
  String get contact_edit_name_required => 'Енгізіңіз аты контакта.';

  @override
  String contact_edit_save_error(Object error) {
    return 'Сәтсіз сохранить контакт: $error';
  }

  @override
  String get contact_edit_user_fallback => 'Пользователь';

  @override
  String get contact_edit_first_name_hint => 'Аты';

  @override
  String get contact_edit_last_name_hint => 'Тегі';

  @override
  String get contact_edit_description =>
      'Бұл аты видбірақ только вам: в чаттыңх, поиске және тізімде контактілер.';

  @override
  String contact_edit_error(Object error) {
    return 'Қате: $error';
  }

  @override
  String get voice_no_mic_access => 'Не�� қолжетімділіка микрофону';

  @override
  String get voice_start_error => 'Сәтсіз начать запись';

  @override
  String get voice_file_not_received => 'Файл записжәне не получен';

  @override
  String get voice_stop_error => 'Сәтсіз завершить запись';

  @override
  String get voice_title => 'Голосовое хабарлама';

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
  String get attach_files => 'Файлдар';

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
    return 'Сәтсіз сохранить: $error';
  }

  @override
  String get notif_title => 'Хабарландырулар в этом чатта';

  @override
  String get notif_description =>
      'Параметрлер ниже действуют только для этой беседы және не меняют общие хабарландырулар приложения.';

  @override
  String get notif_this_chat => 'Осы чат';

  @override
  String get notif_mute_title => 'Без дыбыс және скрытые оповещения';

  @override
  String get notif_mute_subtitle =>
      'Не беспокоить по этому чатқа на этом құрылғыда.';

  @override
  String get notif_preview_title => 'Показывать превью текста';

  @override
  String get notif_preview_subtitle =>
      'Еслжәне сізключебірақ — заголовок без фрагмента хабарламалар (қайда бұл поддерживается).';

  @override
  String get poll_create_enter_question => 'Енгізіңіз вопрос';

  @override
  String get poll_create_min_options => 'Нужбірақ ең аз 2 варианта';

  @override
  String get poll_create_select_correct => 'Сізберите правильный вариант';

  @override
  String get poll_create_future_time =>
      'Время закрытия должбірақ быть в будущем';

  @override
  String get poll_create_question_label => 'Вопрос';

  @override
  String get poll_create_question_hint => 'Например: Во сколько кездесуемся?';

  @override
  String get poll_create_explanation_label => 'Пояснение (міндетті емес)';

  @override
  String get poll_create_options_title => 'Варианты';

  @override
  String poll_create_option_hint(Object index) {
    return 'Вариант $index';
  }

  @override
  String get poll_create_add_option => 'Қосу вариант';

  @override
  String get poll_create_anonymous_title => 'Анонимное голосование';

  @override
  String get poll_create_anonymous_subtitle =>
      'Не показывать, кім за не голосовал';

  @override
  String get poll_create_multi_title => 'Несколько ответов';

  @override
  String get poll_create_multi_subtitle =>
      'Можбірақ сізбрать несколько вариантов';

  @override
  String get poll_create_user_options_title => 'Добавление вариантов';

  @override
  String get poll_create_user_options_subtitle =>
      'Усағаттникжәне могут предложить свой вариант';

  @override
  String get poll_create_revote_title => 'Можбірақ изменить голос';

  @override
  String get poll_create_revote_subtitle => 'Переголосование до закрытия';

  @override
  String get poll_create_shuffle_title => 'Перемешать варианты';

  @override
  String get poll_create_shuffle_subtitle =>
      'Свой порядок у каждого усағаттника';

  @override
  String get poll_create_quiz_title => 'Режим викімрины';

  @override
  String get poll_create_quiz_subtitle => 'Один правильный ответ';

  @override
  String get poll_create_correct_option_label => 'Правильный вариант';

  @override
  String get poll_create_close_by_time => 'Жабу по времени';

  @override
  String get poll_create_not_set => 'Не задано';

  @override
  String get poll_create_reset_deadline => 'Сбросить срок';

  @override
  String get poll_create_publish => 'Жариялау';

  @override
  String get poll_error => 'Қате';

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
  String get poll_voters_toggle_show => 'Кім голосовал';

  @override
  String get e2ee_disable_title => 'Отключить шифрлау?';

  @override
  String get e2ee_disable_body =>
      'Носізе хабарламалар пойдут без сквозного шифрования. Ранее отправленные зашифрованные хабарламалар останутся в ленте.';

  @override
  String get e2ee_disable_button => 'Отключить';

  @override
  String e2ee_disable_error(Object error) {
    return 'Сәтсіз отключить: $error';
  }

  @override
  String get e2ee_screen_title => 'Шифрлау';

  @override
  String get e2ee_enabled_description =>
      'Сквозное шифрлау включебірақ для этого чаттың.';

  @override
  String get e2ee_disabled_description => 'Сквозное шифрлау сізключено.';

  @override
  String get e2ee_info_text =>
      'Қашан шифрлау включено, содержимое носізх хабарламалар қолжетімділікбірақ только усағаттникам чаттың на их устройствах. Отключение влияет только на носізе хабарламалар.';

  @override
  String get e2ee_enable_title => 'Қосу шифрлау';

  @override
  String e2ee_status_enabled(Object epoch) {
    return 'Қосулы (эпоха ключа: $epoch)';
  }

  @override
  String get e2ee_status_disabled => 'Өшірулі';

  @override
  String get e2ee_data_types_title => 'Типы деректер';

  @override
  String get e2ee_data_types_info =>
      'Баптау не меняет протокол. Она управляет тем, қалайие типы деректер отправлять в зашифрованном виде.';

  @override
  String get e2ee_chat_settings_title =>
      'Параметрлер шифрования для этого чаттың';

  @override
  String get e2ee_chat_settings_override => 'Используются чатосізе настройки.';

  @override
  String get e2ee_chat_settings_global => 'Наследуются глобальные настройки.';

  @override
  String get e2ee_text_messages => 'Текст хабарламалар';

  @override
  String get e2ee_attachments => 'Вложения (медиа/файлдар)';

  @override
  String get e2ee_override_hint =>
      'Небы изменить для этого чаттың — включите «Переопределить».';

  @override
  String get group_member_fallback => 'Усағаттник';

  @override
  String get group_role_creator => 'Создатель топтар';

  @override
  String get group_role_admin => 'Әкімші';

  @override
  String group_total_count(Object count) {
    return 'Барлығыго: $count';
  }

  @override
  String get group_copy_invite_tooltip => 'Сілтемені көшіру-шақыру';

  @override
  String get group_add_member_tooltip => 'Қосу усағаттника';

  @override
  String get group_invite_copied => 'Сілтеме-шақыру скопирована';

  @override
  String group_copy_invite_error(Object error) {
    return 'Сәтсіз скопировать сілтемені: $error';
  }

  @override
  String get group_demote_confirm => 'Снять права әкімшіні?';

  @override
  String get group_promote_confirm => 'Назначить администратором?';

  @override
  String group_demote_body(Object name) {
    return 'У $name будут сняты права әкімшіні. Усағаттник останется в группе қалай обычный член.';
  }

  @override
  String get group_demote_button => 'Снять права';

  @override
  String get group_promote_button => 'Назначить';

  @override
  String get group_kick_confirm => 'Исключить усағаттника?';

  @override
  String get group_kick_button => 'Исключить';

  @override
  String get group_member_kicked => 'Усағаттник исключён';

  @override
  String get group_badge_creator => 'СО��ДАТЕЛЬ';

  @override
  String get group_demote_action => 'Снять админа';

  @override
  String get group_promote_action => 'Сделать админом';

  @override
  String get group_kick_action => 'Исключить из топтар';

  @override
  String group_contacts_load_error(Object error) {
    return 'Сәтсіз загрузить контактілер: $error';
  }

  @override
  String get group_add_members_title => 'Қосу усағаттников';

  @override
  String get group_search_contacts_hint => 'Іздеу среджәне конта��тов';

  @override
  String get group_all_contacts_in_group =>
      'Барлығы сіздіңжәне контактілер уже в группе.';

  @override
  String get group_nobody_found => 'Никого не найдено.';

  @override
  String get group_user_fallback => 'Пользователь';

  @override
  String get group_select_members => 'Сізберите усағаттников';

  @override
  String group_add_count(Object count) {
    return 'Қосу ($count)';
  }

  @override
  String group_auth_error(Object error) {
    return 'Қате авторизации: $error';
  }

  @override
  String group_add_error(Object error) {
    return 'Сәтсіз добавить усағаттников: $error';
  }

  @override
  String get add_contact_own_profile => 'Бұл сіздің собственный профиль';

  @override
  String get add_contact_qr_not_found => '��рофиль из QR-кода не найден';

  @override
  String add_contact_qr_error(Object error) {
    return 'Сәтсіз оқу QR-код: $error';
  }

  @override
  String get add_contact_not_allowed => 'Болмайды добавить этого пользователя';

  @override
  String add_contact_save_error(Object error) {
    return 'Сәтсіз добавить контакт: $error';
  }

  @override
  String get add_contact_country_search => 'Іздеу страны немесе кода';

  @override
  String get add_contact_sync_phone => 'С��нхронизировать телефоном';

  @override
  String get add_contact_qr_button => 'Д��бавить по QR-коду';

  @override
  String add_contact_load_error(Object error) {
    return 'Қате загрузкжәне контакта: $error';
  }

  @override
  String get add_contact_user_fallback => 'Пользователь';

  @override
  String get add_contact_already_in_contacts => 'Уже в контактах';

  @override
  String get add_contact_new => 'Носізй контакт';

  @override
  String get add_contact_unavailable => 'Неқолжетімділікно';

  @override
  String get add_contact_scan_qr => 'Сканировать QR-код';

  @override
  String get add_contact_scan_hint =>
      'Наведите камеру на QR-код профиля LighChat';

  @override
  String get auth_validate_name_min_length =>
      'Аты должбірақ быть не менее 2 символов';

  @override
  String get auth_validate_username_min_length =>
      'Аты пользователя должбірақ быть не менее 3 символов';

  @override
  String get auth_validate_username_max_length =>
      'Аты пользователя не должбірақ пресізшать 30 символов';

  @override
  String get auth_validate_username_format =>
      'Аты пользователя содержит недопустимые символы';

  @override
  String get auth_validate_phone_11_digits =>
      'Телефон нөмірі должен содержать 11 цифр';

  @override
  String get auth_validate_email_format => 'Енгізіңіз корректный email';

  @override
  String get auth_validate_dob_invalid => 'Некорректная дата рождения';

  @override
  String get auth_validate_bio_max_length =>
      'Сипаттама не должбірақ пресізшать 200 символов';

  @override
  String get auth_validate_password_min_length =>
      'Құпиясөз должен быть не менее 6 символов';

  @override
  String get auth_validate_passwords_mismatch => 'Паролжәне не совпадают';

  @override
  String get sticker_new_pack => 'Носізй пак…';

  @override
  String get sticker_select_image_or_gif => 'Сізберите сурет немесе GIF';

  @override
  String sticker_send_error(Object error) {
    return 'Сәтсіз отправить: $error';
  }

  @override
  String get sticker_saved => 'Сақталды в стикерпак';

  @override
  String get sticker_save_failed => 'Сәтсіз скачать немесе сохранить GIF';

  @override
  String get sticker_tab_my => 'Мои';

  @override
  String get sticker_tab_shared => 'Общие';

  @override
  String get sticker_no_packs => 'Жоқ стикерпаков. Создайте носізй.';

  @override
  String get sticker_shared_not_configured => 'Общие пакжәне не настроены';

  @override
  String get sticker_recent => 'НЕДАВНИЕ';

  @override
  String get sticker_gallery_description =>
      'Фото, PNG, GIF құрылғылар — сразу в чат';

  @override
  String get sticker_shared_unavailable =>
      'Общие пакжәне әзірге неқолжетімділікны';

  @override
  String get sticker_gif_search_hint => 'Іздеу GIF…';

  @override
  String sticker_gif_searched(Object query) {
    return 'Искали: $query';
  }

  @override
  String get sticker_gif_search_unavailable =>
      'Іздеу GIF временбірақ неқолжетімділікен.';

  @override
  String get sticker_gif_nothing_found => 'Ничего не найдено';

  @override
  String get sticker_gif_all => 'Барлығы';

  @override
  String get sticker_gif_animated => 'АНИМИРОВАННЫЕ';

  @override
  String get sticker_emoji_text_unavailable =>
      'Эмодзжәне в текст неқолжетімділікны для этого окна.';

  @override
  String get wallpaper_sender => 'Собеседник';

  @override
  String get wallpaper_incoming => 'Бұл вжүрісящее хабарлама.';

  @override
  String get wallpaper_outgoing => 'Бұл исжүрісящее хабарлама.';

  @override
  String get wallpaper_incoming_time => '11:40';

  @override
  String get wallpaper_outgoing_time => '11:41';

  @override
  String get wallpaper_system => 'Сіз сменнемесе обожәне чаттың';

  @override
  String get wallpaper_you => 'Сіз';

  @override
  String get wallpaper_today => 'Бүгін';

  @override
  String system_event_e2ee_enabled(Object epoch) {
    return 'Сквозное шифрлау включебірақ (эпоха ключа: $epoch)';
  }

  @override
  String get system_event_e2ee_disabled => 'Сквозное шифрлау ажыратылды';

  @override
  String get system_event_unknown => 'Системное событие';

  @override
  String get system_event_group_created => 'Топ создана';

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
    return '$name покинул(а) топты';
  }

  @override
  String system_event_name_changed(Object name) {
    return 'Название изменебірақ на «$name»';
  }

  @override
  String get image_editor_title => 'Редакімр';

  @override
  String get image_editor_undo => 'Болдырмау';

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
  String get location_title => 'Жіберу местоположение';

  @override
  String get location_loading => 'Жүктелуде карталар…';

  @override
  String get location_send_button => 'Жіберу';

  @override
  String get location_live_label => 'Трансляция';

  @override
  String get location_error => 'Сәтсіз загрузить карту';

  @override
  String get location_no_permission => 'Жоқ қолжетімділіка местоположению';

  @override
  String get group_member_admin => 'Әкімші';

  @override
  String get group_member_creator => 'Создатель';

  @override
  String get group_member_member => 'Усағаттник';

  @override
  String get group_member_open_chat => 'Написать';

  @override
  String get group_member_open_profile => 'Профиль';

  @override
  String get group_member_remove => 'Исключить';

  @override
  String get durak_lobby_title => 'Дурак';

  @override
  String get durak_lobby_new_game => 'Жаңа ойын';

  @override
  String get durak_lobby_decline => 'Қабылдамау';

  @override
  String get durak_lobby_accept => 'Қабылдау';

  @override
  String get durak_lobby_invite_sent => 'Шақыру отправлено';

  @override
  String get voice_preview_cancel => 'Болдырмау';

  @override
  String get voice_preview_send => 'Жіберу';

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
  String get group_avatar_upload_error => 'Қате загрузки';

  @override
  String get avatar_picker_title => 'Аватар';

  @override
  String get avatar_picker_camera => 'Камера';

  @override
  String get avatar_picker_gallery => 'Галерея';

  @override
  String get avatar_picker_crop => 'Обрезка';

  @override
  String get avatar_picker_save => 'Сақтау';

  @override
  String get avatar_picker_remove => 'Жою аватар';

  @override
  String get avatar_picker_error => 'Сәтсіз загрузить аватар';

  @override
  String get avatar_picker_crop_error => 'Қате обрезки';

  @override
  String get webview_telegram_title => 'Вжүріс через Telegram';

  @override
  String get webview_telegram_loading => 'Жүктелуде…';

  @override
  String get webview_telegram_error => 'Сәтсіз загрузить страницу';

  @override
  String get webview_telegram_back => 'Артқа';

  @override
  String get webview_telegram_retry => 'Повторить';

  @override
  String get webview_telegram_close => 'Жабу';

  @override
  String get webview_telegram_no_url => 'Не указан URL для авторизации';

  @override
  String get webview_yandex_title => 'Вжүріс через Менндекс';

  @override
  String get webview_yandex_loading => 'Жүктелуде…';

  @override
  String get webview_yandex_error => 'Сәтсіз загрузить страницу';

  @override
  String get webview_yandex_back => 'Артқа';

  @override
  String get webview_yandex_retry => 'Повторить';

  @override
  String get webview_yandex_close => 'Жабу';

  @override
  String get webview_yandex_no_url => 'Не указан URL для авторизации';

  @override
  String get google_profile_title => 'Заполните профиль';

  @override
  String get google_profile_name => 'Аты';

  @override
  String get google_profile_username => 'Аты пользователя';

  @override
  String get google_profile_phone => 'Телефон';

  @override
  String get google_profile_email => 'Электрондық пошта';

  @override
  String get google_profile_dob => 'Жәнеәсол рождения';

  @override
  String get google_profile_bio => 'О себе';

  @override
  String get google_profile_save => 'Сақтау';

  @override
  String get google_profile_error => 'Сәтсіз сохранить профиль';

  @override
  String get system_event_e2ee_epoch_rotated => 'Ключ шифрования обновлён';

  @override
  String system_event_e2ee_device_added(String actor, String device) {
    return '$actor добавил құрылғы «$device»';
  }

  @override
  String system_event_e2ee_device_revoked(String actor, String device) {
    return '$actor отозвал құрылғы «$device»';
  }

  @override
  String system_event_e2ee_fingerprint_changed(String actor) {
    return 'Отпечаток безопасностжәне у $actor изменился';
  }

  @override
  String get system_event_game_lobby_created => 'Создабірақ лоббжәне ойындар';

  @override
  String get system_event_game_started => 'Ойын началась';

  @override
  String get system_event_default_actor => 'Пользователь';

  @override
  String get system_event_default_device => 'құрылғы';

  @override
  String get image_editor_add_caption => 'Қосу подпись...';

  @override
  String get image_editor_crop_failed => 'Сәтсіз обрезать сурет';

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
  String get group_member_profile_default_name => 'Усағаттник';

  @override
  String get group_member_profile_dm => 'Написать лично';

  @override
  String get group_member_profile_dm_hint => 'Ашу личный чат усағаттником';

  @override
  String group_member_profile_dm_failed(Object error) {
    return 'Сәтсіз открыть личный чат: $error';
  }

  @override
  String get conversation_game_lobby_unavailable =>
      'Ойын неқолжетімділікна немесе болды удалена';

  @override
  String get conversation_game_lobby_back => 'Артқа';

  @override
  String get conversation_game_lobby_waiting =>
      'Ждём, әзірге подключится соперник…';

  @override
  String get conversation_game_lobby_start_game => 'Начать игру';

  @override
  String get conversation_game_lobby_waiting_short => 'Ждём…';

  @override
  String get conversation_game_lobby_ready => 'Готов';

  @override
  String get voice_preview_trim_confirm_title =>
      'Оставить только сізбранный фрагмент?';

  @override
  String get voice_preview_trim_confirm_body =>
      'Всё, кроме сізделенного фрагмента, болады удалено. Запись хабарламалар продолжится сразу после нажатия кнопки.';

  @override
  String get voice_preview_continue => 'Жалғастыру';

  @override
  String get voice_preview_continue_recording => 'Жалғастыру запись';

  @override
  String get group_avatar_change_short => 'Ауыстыру';

  @override
  String get avatar_picker_cancel => 'Болдырмау';

  @override
  String get avatar_picker_choose => 'Сізбрать аватар';

  @override
  String get avatar_picker_delete_photo => 'Жою фото';

  @override
  String get avatar_picker_loading => 'Жүктелуде…';

  @override
  String get avatar_picker_choose_avatar => 'Сізбрать аватар';

  @override
  String get avatar_picker_change_avatar => 'Ауыстыру аватар';

  @override
  String get avatar_picker_remove_tooltip => 'Убрать';

  @override
  String get telegram_sign_in_title => 'Вжүріс через Telegram';

  @override
  String get telegram_sign_in_open_in_browser => 'Ашу в браузере';

  @override
  String get telegram_sign_in_open_telegram_failed =>
      'Сәтсіз открыть Telegram. Установите приложение Telegram.';

  @override
  String get telegram_sign_in_page_load_error => 'Қате загрузкжәне страницы';

  @override
  String get telegram_sign_in_login_error => 'Қате вжүріса через Telegram.';

  @override
  String get telegram_sign_in_firebase_not_ready => 'Firebase не готов.';

  @override
  String get telegram_sign_in_browser_failed => 'Сәтсіз открыть браузер.';

  @override
  String telegram_sign_in_login_failed(Object error) {
    return 'Сәтсіз войти: $error';
  }

  @override
  String get yandex_sign_in_title => 'Вжүріс через Менндекс';

  @override
  String get yandex_sign_in_open_in_browser => 'Ашу в браузере';

  @override
  String get yandex_sign_in_page_load_error => 'Қате загрузкжәне страницы';

  @override
  String get yandex_sign_in_login_error => 'Қате вжүріса через Менндекс.';

  @override
  String get yandex_sign_in_firebase_not_ready => 'Firebase не готов.';

  @override
  String get yandex_sign_in_browser_failed => 'Сәтсіз открыть браузер.';

  @override
  String yandex_sign_in_login_failed(Object error) {
    return 'Сәтсіз войти: $error';
  }

  @override
  String get google_complete_title => 'Завершите регистрацию';

  @override
  String get google_complete_subtitle =>
      'После вжүріса через Google нужбірақ заполнить профиль, қалай в веб-нұсқа.';

  @override
  String get google_complete_name_label => 'Аты';

  @override
  String get google_complete_username_label => 'Логин (@username)';

  @override
  String get google_complete_phone_label => 'Телефон (11 цифр)';

  @override
  String get google_complete_email_label => 'Электрондық пошта';

  @override
  String get google_complete_email_hint => 'you@example.com';

  @override
  String get google_complete_dob_label =>
      'Жәнеәсол рождения (YYYY-MM-DD, опционально)';

  @override
  String get google_complete_bio_label =>
      'О себе (до 200 символов, опционально)';

  @override
  String get google_complete_save => 'Сақтау және продолжить';

  @override
  String get google_complete_back => 'Вернуться авторизации';

  @override
  String get game_error_defense_not_beat => 'Осы карта не бьет атакующую';

  @override
  String get game_error_attacker_first => 'Персізм жүрісит атакующий ойыншы';

  @override
  String get game_error_defender_no_attack =>
      'Отбивающийся қазір не подкидывает';

  @override
  String get game_error_not_allowed_throwin =>
      'Сіз не можете тастау в этом раунде';

  @override
  String get game_error_throwin_not_turn => 'Қазір подкидывает басқа ойыншы';

  @override
  String get game_error_rank_not_allowed =>
      'Тастау можбірақ только карту того же ранга';

  @override
  String get game_error_cannot_throw_in => 'Көбірек карт тастау болмайды';

  @override
  String get game_error_card_not_in_hand => 'Этой карталар уже жоқ в руке';

  @override
  String get game_error_already_defended => 'Осы карта уже отбита';

  @override
  String get game_error_bad_attack_index =>
      'Сізберите атакующую карту для защиты';

  @override
  String get game_error_only_defender => 'Қазір отбивается басқа ойыншы';

  @override
  String get game_error_defender_taking => 'Отбивающийся уже берет карталар';

  @override
  String get game_error_game_not_active => 'Партия уже не активна';

  @override
  String get game_error_not_in_lobby => 'Лоббжәне уже стартовало';

  @override
  String get game_error_game_already_active => 'Партия уже началась';

  @override
  String get game_error_active_exists => 'В этом чатта уже бар активная партия';

  @override
  String get game_error_round_pending => 'Сначала завершите спорный жүріс';

  @override
  String get game_error_rematch_failed =>
      'Сәтсіз подготовить реванш. Попробуйте ��ще раз';

  @override
  String get game_error_unauthenticated => 'Нужбірақ войтжәне в аккаунт';

  @override
  String get game_error_permission_denied => 'Бұл әрекет вам неқолжетімділікно';

  @override
  String get game_error_invalid_argument => 'Некорректный жүріс';

  @override
  String get game_error_precondition => 'Жүріс қазір неқолжетімділікен';

  @override
  String get game_error_server => 'Сәтсіз сізполнить жүріс. Попробуйте еще раз';

  @override
  String get reply_sticker => 'Стикер';

  @override
  String get reply_gif => 'GIF';

  @override
  String get reply_video_circle => 'Кружок';

  @override
  String get reply_voice_message => 'Голосовое хабарлама';

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
  String get reply_link => 'Сілтеме';

  @override
  String get reply_message => 'Хабарлама';

  @override
  String get reply_sender_you => 'Сіз';

  @override
  String get reply_sender_member => 'Усағаттник';

  @override
  String get call_format_today => 'Бүгін';

  @override
  String get call_format_yesterday => 'Кеше';

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
  String get push_incoming_call => 'Вжүрісящий қоңырау';

  @override
  String get push_incoming_video_call => 'Вжүрісящий видеоқоңырау';

  @override
  String get push_new_message => 'Жаңа хабарлама';

  @override
  String get push_channel_calls => 'Қоңыраулар';

  @override
  String get push_channel_messages => 'Хабарламалар';

  @override
  String contacts_years_one(Object count) {
    return '$count жыл';
  }

  @override
  String contacts_years_few(Object count) {
    return '$count жыл';
  }

  @override
  String contacts_years_many(Object count) {
    return '$count жыл';
  }

  @override
  String contacts_years_other(Object count) {
    return '$count жыл';
  }

  @override
  String get durak_entry_single_game => 'Одиночная партия';

  @override
  String get durak_entry_finish_game_tooltip => 'Завершить игру';

  @override
  String get durak_entry_tournament_games_dialog_title =>
      'Сколько игр в турнире?';

  @override
  String get durak_entry_cancel => 'Болдырмау';

  @override
  String get durak_entry_create => 'Құру';

  @override
  String video_editor_load_failed(Object error) {
    return 'Сәтсіз загрузить видео: $error';
  }

  @override
  String video_editor_process_failed(Object error) {
    return 'Сәтсіз обработать видео: $error';
  }

  @override
  String video_editor_duration(Object duration) {
    return 'Длительность: $duration';
  }

  @override
  String get video_editor_brush => 'Кисть';

  @override
  String get video_editor_caption_hint => 'Қосу подпись...';

  @override
  String get video_effects_speed => 'Скорость';

  @override
  String get video_filter_none => 'Оригинал';

  @override
  String get video_filter_enhance => 'Улучшить';

  @override
  String get share_location_title => 'Бөлісу геолокацией';

  @override
  String get share_location_how => 'Қалай делиться';

  @override
  String get share_location_cancel => 'Болдырмау';

  @override
  String get share_location_send => 'Жіберу';

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
      'Сәтсіз воспроизвестжәне видео. Проверьте сілтемені және сеть.';

  @override
  String get location_card_broadcast_ended_mine =>
      'Трансляция геолокацижәне завершена. Собеседник көбірек не видит сіздіңе актуальное местоположение.';

  @override
  String get location_card_broadcast_ended_other =>
      'Трансляция геолокацижәне у этого контакта завершена. Актуальная позиция неқолжетімділікна.';

  @override
  String get location_card_title => 'Местоположение';

  @override
  String location_card_accuracy(Object meters) {
    return '±$meters м';
  }

  @override
  String get link_webview_copy_tooltip => 'Сілтемені көшіру';

  @override
  String get link_webview_copied_snackbar => 'Сілтеме скопирована';

  @override
  String get link_webview_open_browser_tooltip => 'Ашу в браузере';

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
    return 'Сәтсіз получить отпечаток: $error';
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
  String get composer_link_cancel => 'Болдырмау';

  @override
  String message_search_results_count(Object count) {
    return 'РЕЗУЛЬТАТЫ ПОИСКА: $count';
  }

  @override
  String get message_search_not_found => 'НИЧЕГО НЕ НАЙДЕНО';

  @override
  String get message_search_participant_fallback => 'Усағаттник';

  @override
  String get wallpaper_purple => 'Фиожылосізй';

  @override
  String get wallpaper_pink => 'Розосізй';

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
  String get avatar_crop_title => 'Баптау аватара';

  @override
  String get avatar_crop_hint =>
      'Перетащите және масштабируйте — так круг болады в списках және хабарламаларх; полный кадр остаётся для профиля.';

  @override
  String get avatar_crop_cancel => 'Болдырмау';

  @override
  String get avatar_crop_reset => 'Сбросить';

  @override
  String get avatar_crop_save => 'Сақтау';

  @override
  String get meeting_entry_connecting => 'Подключаемся митингу…';

  @override
  String meeting_entry_auth_failed(Object error) {
    return 'Сәтсіз войти: $error';
  }

  @override
  String get meeting_entry_participant_fallback => 'Усағаттник';

  @override
  String get meeting_entry_back => 'Артқа';

  @override
  String get meeting_chat_copy => 'Көшіру';

  @override
  String get meeting_chat_edit => 'Өзгерту';

  @override
  String get meeting_chat_delete => 'Жою';

  @override
  String get meeting_chat_deleted => 'Хабарлама удалено';

  @override
  String get meeting_chat_edited_mark => '• изм.';

  @override
  String get e2ee_decrypt_image_failed => 'Сәтсіз шифрды ашу сурет';

  @override
  String get e2ee_decrypt_video_failed => 'Сәтсіз шифрды ашу видео';

  @override
  String get e2ee_decrypt_audio_failed => 'Сәтсіз шифрды ашу аудио';

  @override
  String get e2ee_decrypt_attachment_failed => 'Сәтсіз шифрды ашу вложение';

  @override
  String get search_preview_attachment => 'Вложение';

  @override
  String get search_preview_location => 'Геолокация';

  @override
  String get search_preview_message => 'Хабарлама';

  @override
  String get outbox_attachment_singular => 'Вложение';

  @override
  String outbox_attachments_count(int count) {
    return 'Вложения ($count)';
  }

  @override
  String get outbox_chat_unavailable => 'Сервис чаттың неқолжетімділікен';

  @override
  String outbox_encryption_error(String code) {
    return 'Шифрлау: $code';
  }

  @override
  String get nav_chats => 'Чаттар';

  @override
  String get nav_contacts => 'Контактілер';

  @override
  String get nav_meetings => 'Конференции';

  @override
  String get nav_calls => 'Қоңыраулар';

  @override
  String get e2ee_media_decrypt_failed_image => 'Сәтсіз шифрды ашу сурет';

  @override
  String get e2ee_media_decrypt_failed_video => 'Сәтсіз шифрды ашу видео';

  @override
  String get e2ee_media_decrypt_failed_audio => 'Сәтсіз шифрды ашу аудио';

  @override
  String get e2ee_media_decrypt_failed_attachment =>
      'Сәтсіз шифрды ашу вложение';

  @override
  String get chat_search_snippet_attachment => 'Вложение';

  @override
  String get chat_search_snippet_location => 'Геолокация';

  @override
  String get chat_search_snippet_message => 'Хабарлама';

  @override
  String get bottom_nav_chats => 'Чаттар';

  @override
  String get bottom_nav_contacts => 'Контактілер';

  @override
  String get bottom_nav_meetings => 'Конференции';

  @override
  String get bottom_nav_calls => 'Қоңыраулар';

  @override
  String get chat_list_swipe_folders => 'ПАПКИ';

  @override
  String get chat_list_swipe_clear => 'ОЧИСТИТЬ';

  @override
  String get chat_list_swipe_delete => 'УДАЛИТЬ';

  @override
  String get composer_editing_title => 'РЕДАКТИРОВАНИЕ СООБЩЕНИМен';

  @override
  String get composer_editing_cancel_tooltip => 'Болдырмау редактирование';

  @override
  String get composer_formatting_title => 'ФОРМАТИРОВАНИЕ';

  @override
  String get composer_link_preview_loading => 'Жүктелуде превью…';

  @override
  String get composer_link_preview_hide_tooltip => 'Скрыть превью';

  @override
  String get chat_invite_button => 'Шақыру';

  @override
  String get forward_preview_unknown_sender => 'Неизвестный';

  @override
  String get forward_preview_attachment => 'Вложение';

  @override
  String get forward_preview_message => 'Хабарлама';

  @override
  String get chat_mention_no_matches => 'Жоқ совпадений';

  @override
  String get live_location_sharing => 'Сіз делитесь геолокацией';

  @override
  String get live_location_stop => 'Остановить';

  @override
  String get chat_message_deleted => 'Хабарлама удалено';

  @override
  String get profile_qr_share => 'Бөлісу';

  @override
  String get shared_location_open_browser_tooltip => 'Ашу в браузере';

  @override
  String get reply_preview_message_fallback => 'Хабарлама';

  @override
  String get video_circle_media_kind => 'видео';

  @override
  String reactions_rated_count(int count) {
    return 'Оценнемесе: $count';
  }

  @override
  String reactions_today_time(String time) {
    return 'Бүгін, $time';
  }

  @override
  String get durak_create_timer_subtitle => 'По умолчанию 15 секунд';

  @override
  String get dm_game_banner_active => 'Партия \"Дурак\" идёт';

  @override
  String get dm_game_banner_created => 'Ойын \"Дурак\" создана';

  @override
  String get chat_folder_favorites => 'Таңдаулылар';

  @override
  String get chat_folder_new => 'Жаңа';

  @override
  String get contact_profile_user_fallback => 'Пользователь';

  @override
  String contact_profile_error(String error) {
    return 'Қате: $error';
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
  String get mention_default_label => 'Усағаттник';

  @override
  String get contacts_fallback_name => 'Контакт';

  @override
  String get sticker_pack_default_name => 'Мой пак';

  @override
  String get profile_error_phone_taken =>
      'Осы телефон нөмірі уже зарегистрирован. Укажите басқа нөмір.';

  @override
  String get profile_error_email_taken =>
      'Осы email уже занят. Укажите басқа адрес.';

  @override
  String get profile_error_username_taken =>
      'Осы логин уже занят. Сізберите басқа.';

  @override
  String get e2ee_banner_default_context => 'Хабарлама';

  @override
  String e2ee_banner_encrypted_chat_web_only(String prefix) {
    return '$prefix в зашифрованный чат әзірге можбірақ отправить только веб‑клиента.';
  }

  @override
  String get chat_attachment_decrypt_error => 'Сәтсіз шифрды ашу вложение';

  @override
  String get mention_fallback_label => 'усағаттник';

  @override
  String get mention_fallback_label_capitalized => 'Усағаттник';

  @override
  String get meeting_speaking_label => 'Говорит';

  @override
  String meeting_local_you_suffix(String name) {
    return '$name (Сіз)';
  }

  @override
  String get video_crop_title => 'Обрезка';

  @override
  String video_crop_load_error(String error) {
    return 'Сәтсіз загрузить видео: $error';
  }

  @override
  String get gif_section_recent => 'НЕДАВНИЕ';

  @override
  String get gif_section_trending => 'ТРЕНДІ';

  @override
  String get auth_create_account_title => 'Аккаунт құру';

  @override
  String yandex_sign_in_yandex_error(String error) {
    return 'Менндекс: $error';
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
      'Сіз заблокировалжәне этого пользователя. Қоңырау неқолжетімділікен — разблокируйте в Профиль → Бұғатталғанные.';

  @override
  String get block_call_partner_blocked =>
      'Пользователь ограничил вамжәне общение. Қоңырау неқолжетімділікен.';

  @override
  String get block_call_unavailable => 'Қоңырау неқолжетімділікен.';

  @override
  String get block_composer_viewer_blocked =>
      'Сіз заблокировалжәне этого пользователя. Жіберу неқолжетімділікна — разблокируйте в Профиль → Бұғатталғанные.';

  @override
  String get block_composer_partner_blocked =>
      'Пользователь ограничил вамжәне общение. Жіберу неқолжетімділікна.';

  @override
  String get forward_group_fallback => 'Топ';

  @override
  String get forward_unknown_user => 'Неизвестный';

  @override
  String get live_location_once => 'Одноразово (только бұл хабарлама)';

  @override
  String get live_location_5min => '5 минут';

  @override
  String get live_location_15min => '15 минут';

  @override
  String get live_location_30min => '30 минут';

  @override
  String get live_location_1hour => '1 сағат';

  @override
  String get live_location_2hours => '2 сағат';

  @override
  String get live_location_6hours => '6 сағат';

  @override
  String get live_location_1day => '1 күн';

  @override
  String get live_location_forever => 'Наәрқашан (әзірге не отключу)';

  @override
  String get e2ee_send_too_many_files =>
      'Слишком көп вложений для зашифрованной отправки: ең көп 5 файлов за хабарлама.';

  @override
  String get e2ee_send_too_large =>
      'Слишком большой общий өлшем вложений: ең көп 96 МБ для одного зашифрованного хабарламалар.';

  @override
  String get presence_last_seen_prefix => 'Болды(а) ';

  @override
  String get presence_less_than_minute_ago => 'менее минут назад';

  @override
  String get presence_yesterday => 'кеше';

  @override
  String get dm_fallback_title => 'Чат';

  @override
  String get dm_fallback_partner => 'Собеседник';

  @override
  String get group_fallback_title => 'Групповой чат';

  @override
  String get block_send_viewer_blocked =>
      'Сіз заблокировалжәне этого пользователя. Жіберу неқолжетімділікна — разблокируйте в Профиль → Бұғатталғанные.';

  @override
  String get block_send_partner_blocked =>
      'Пользователь ограничил вамжәне общение. Жіберу неқолжетімділікна.';

  @override
  String get mention_fallback_name => 'Усағаттник';

  @override
  String get profile_conflict_phone =>
      'Осы телефон нөмірі уже зарегистрирован. Укажите басқа нөмір.';

  @override
  String get profile_conflict_email =>
      'Осы email уже занят. Укажите басқа адрес.';

  @override
  String get profile_conflict_username =>
      'Осы логин уже занят. Сізберите басқа.';

  @override
  String get mention_fallback_participant => 'Усағаттник';

  @override
  String get sticker_gif_recent => 'НЕДАВНИЕ';

  @override
  String get meeting_screen_sharing => 'Экран';

  @override
  String get meeting_speaking => 'Говорит';

  @override
  String auth_sign_in_failed(Object error) {
    return 'Сәтсіз войти: $error';
  }

  @override
  String yandex_error_prefix(Object error) {
    return 'Менндекс: $error';
  }

  @override
  String auth_error_prefix(Object error) {
    return 'Қате авторизации: $error';
  }

  @override
  String presence_minutes_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count минут назад',
      many: '$count минут назад',
      few: '$count минут назад',
      one: '$count минут назад',
    );
    return '$_temp0';
  }

  @override
  String presence_hours_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сағат назад',
      many: '$count сағат назад',
      few: '$count сағат назад',
      one: '$count сағат назад',
    );
    return '$_temp0';
  }

  @override
  String presence_days_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count күн назад',
      many: '$count күн назад',
      few: '$count күн назад',
      one: '$count күн назад',
    );
    return '$_temp0';
  }

  @override
  String presence_months_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ай назад',
      many: '$count ай назад',
      few: '$count ай назад',
      one: '$count ай назад',
    );
    return '$_temp0';
  }

  @override
  String presence_years_months_ago(int years, int months) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years жыл',
      many: '$years жыл',
      few: '$years жыл',
      one: '$years жыл',
    );
    String _temp1 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months ай назад',
      many: '$months ай назад',
      few: '$months ай назад',
      one: '$months ай назад',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String presence_years_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count жыл назад',
      many: '$count жыл назад',
      few: '$count жыл назад',
      one: '$count жыл назад',
    );
    return '$_temp0';
  }

  @override
  String get wallpaper_gradient_purple => 'Фиожылосізй';

  @override
  String get wallpaper_gradient_pink => 'Розосізй';

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
      'Сіз заблокировалжәне этого пользователя. Қоңырау неқолжетімділікен — разблокируйте в Профиль → Бұғатталғанные.';

  @override
  String get block_call_they_blocked =>
      'Пользователь ограничил вамжәне общение. Қоңырау неқолжетімділікен.';

  @override
  String get block_call_generic => 'Қоңырау неқолжетімділікен.';

  @override
  String get block_send_you_blocked =>
      'Сіз заблокировалжәне этого пользователя. Жіберу неқолжетімділікна — разблокируйте в Профиль → Бұғатталғанные.';

  @override
  String get block_send_they_blocked =>
      'Пользователь ограничил вамжәне общение. Жіберу неқолжетімділікна.';

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
      'Слишком көп вложений для зашифрованной отправки: ең көп 5 файлов за хабарлама.';

  @override
  String get e2ee_total_size_exceeded =>
      'Слишком большой общий өлшем вложений: ең көп 96 МБ для одного зашифрованного хабарламалар.';

  @override
  String composer_limit_too_many_files(int current, int max, int diff) {
    return 'Тым көп тіркеме: $current/$max. Жіберу үшін $diff жойыңыз.';
  }

  @override
  String composer_limit_total_size_exceeded(String currentMb, String maxMb) {
    return 'Тіркемелер тым үлкен: $currentMb МБ / $maxMb МБ. Жіберу үшін кейбірін жойыңыз.';
  }

  @override
  String get composer_limit_blocking_send => 'Тіркеме шегі асырылды';

  @override
  String yandex_sign_in_error_prefix(String error) {
    return 'Менндекс: $error';
  }

  @override
  String get meeting_participant_screen => 'Экран';

  @override
  String get meeting_participant_speaking => 'Говорит';

  @override
  String get nav_error_title => 'Қате навигации';

  @override
  String get nav_error_invalid_secret_compose =>
      'Некорректная навигация құпия чаттың';

  @override
  String get sign_in_title => 'Вжүріс';

  @override
  String get sign_in_firebase_ready =>
      'Firebase инициализирован. Можбірақ войти.';

  @override
  String get sign_in_firebase_not_ready =>
      'Firebase не готов. Проверьте логжәне және firebase_options.dart.';

  @override
  String get sign_in_continue => 'Жалғастыру';

  @override
  String get sign_in_anonymously => 'Кіру анонимно';

  @override
  String sign_in_auth_error(String error) {
    return 'Қате авторизации: $error';
  }

  @override
  String generic_error(String error) {
    return 'Қате: $error';
  }

  @override
  String get storage_label_video => 'Видео';

  @override
  String get storage_label_photo => 'Фото';

  @override
  String get storage_label_audio => 'Аудио';

  @override
  String get storage_label_files => 'Файлдар';

  @override
  String get storage_label_other => 'Басқа';

  @override
  String get storage_label_recent_stickers => 'Соңғы стикерлер';

  @override
  String get storage_label_giphy_search => 'GIPHY · іздеу кэші';

  @override
  String get storage_label_giphy_recent => 'GIPHY · соңғы GIF-тер';

  @override
  String get storage_chat_unattributed => 'Чатқа байланыстырылмаған';

  @override
  String storage_label_draft(String key) {
    return 'Черновик · $key';
  }

  @override
  String get storage_label_offline_snapshot => 'Офлайн-снимок тізімнің чатов';

  @override
  String storage_label_profile_cache(String name) {
    return 'Кэш профиля · $name';
  }

  @override
  String get call_mini_end => 'Завершить қоңырау';

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
  String get push_notification_title => 'Рұқсат беру хабарландырулар';

  @override
  String get push_notification_rationale =>
      'Для вжүрісящих звонков приложению нужны хабарландырулар.';

  @override
  String get push_notification_required =>
      'Қосулыючите хабарландырулар для отображения вжүрісящих звонков.';

  @override
  String get push_notification_grant => 'Рұқсат беру';

  @override
  String get push_call_accept => 'Қабылдау';

  @override
  String get push_call_decline => 'Қабылдамау';

  @override
  String get push_channel_incoming_calls => 'Вжүрісящие қоңыраулар';

  @override
  String get push_channel_missed_calls => 'Пропущенные қоңыраулар';

  @override
  String get push_channel_messages_desc => 'Носізе хабарламалар в чаттыңх';

  @override
  String get push_channel_silent => 'Хабарламалар без дыбыс';

  @override
  String get push_channel_silent_desc => 'Push без дыбыс';

  @override
  String get push_caller_unknown => 'Кім-сол';

  @override
  String get outbox_attachment_single => 'Вложение';

  @override
  String outbox_attachment_count(int count) {
    return 'Вложения ($count)';
  }

  @override
  String get bottom_nav_label_chats => 'Чаттар';

  @override
  String get bottom_nav_label_contacts => 'Контактілер';

  @override
  String get bottom_nav_label_conferences => 'Конференции';

  @override
  String get bottom_nav_label_calls => 'Қоңыраулар';

  @override
  String get welcomeBubbleTitle => 'Добро пожаловать в LighChat';

  @override
  String get welcomeBubbleSubtitle => 'Маяк зажёгся';

  @override
  String get welcomeSkip => 'Өткізіп жіберу';

  @override
  String get welcomeReplayDebugTile =>
      'Сәлемдесу анимациясын қайталау (отладка)';

  @override
  String get sticker_scope_library => 'Библиотека';

  @override
  String get sticker_library_search_hint => 'Стикерлерді іздеу…';

  @override
  String get account_menu_energy_saving => 'Қуатты үнемдеу';

  @override
  String get energy_saving_title => 'Энергосбережение';

  @override
  String get energy_saving_section_mode => 'Режим энергосбережения';

  @override
  String get energy_saving_section_resource_heavy => 'Ресурсоёмкие процессы';

  @override
  String get energy_saving_threshold_off => 'Өшірулі';

  @override
  String get energy_saving_threshold_always => 'Қосулы';

  @override
  String get energy_saving_threshold_off_full => 'Ешқашан';

  @override
  String get energy_saving_threshold_always_full => 'Әрқашан';

  @override
  String energy_saving_threshold_at(int percent) {
    return 'Пржәне заряде менее $percent%';
  }

  @override
  String get energy_saving_hint_off =>
      'Ресурсоёмкие эффекты ешқашан не отключаются автоматически.';

  @override
  String get energy_saving_hint_always =>
      'Ресурсоёмкие эффекты әрқашан отключены, независимо уровня заряда.';

  @override
  String energy_saving_hint_threshold(int percent) {
    return 'Автоматическжәне отключать барлығы ресурсоёмкие процессы пржәне заряде менее $percent%.';
  }

  @override
  String energy_saving_current_battery(int percent) {
    return 'Текущий заряд: $percent%';
  }

  @override
  String get energy_saving_active_now => 'режим активен';

  @override
  String get energy_saving_active_threshold =>
      'Заряд достиг порога — барлығы эффекты ниже временбірақ отключены.';

  @override
  String get energy_saving_active_system =>
      'Қосулыючён системный режим энергосбережения — барлығы эффекты ниже временбірақ отключены.';

  @override
  String get energy_saving_autoplay_video_title => 'Автозапуск видео';

  @override
  String get energy_saving_autoplay_video_subtitle =>
      'Автозапуск және повторение видеохабарламалар және видео в чаттыңх.';

  @override
  String get energy_saving_autoplay_gif_title => 'Автозапуск GIF';

  @override
  String get energy_saving_autoplay_gif_subtitle =>
      'Автозапуск және повторение GIF в чаттыңх және на клавиатуре.';

  @override
  String get energy_saving_animated_stickers_title => 'Анимированные стикеры';

  @override
  String get energy_saving_animated_stickers_subtitle =>
      'Повторяющаяся анимация стикеров және полноэкранные эффекты Premium-стикеров.';

  @override
  String get energy_saving_animated_emoji_title => 'Анимированные эмодзи';

  @override
  String get energy_saving_animated_emoji_subtitle =>
      'Повторяющаяся анимация эмодзжәне в хабарламаларх, реакциях және статусах.';

  @override
  String get energy_saving_interface_animations_title =>
      'Анимацижәне интерфейса';

  @override
  String get energy_saving_interface_animations_subtitle =>
      'Эффекты және анимации, которые делают LighChat плавнее және сізразительнее.';

  @override
  String get energy_saving_media_preload_title => 'Предзагрузка медиа';

  @override
  String get energy_saving_media_preload_subtitle =>
      'Запуск загрузкжәне медиафайлов пржәне вжүрісе в тізім чатов.';

  @override
  String get energy_saving_background_update_title => 'Жаңарту в фоне';

  @override
  String get energy_saving_background_update_subtitle =>
      'Быстрое жаңарту чатов пржәне переключенижәне между приложениями.';

  @override
  String get legal_index_title => 'Заңды құжаттар';

  @override
  String get legal_index_subtitle =>
      'Құпиялылық саясаты, қызмет көрсету шарттары және LighChat пайдалануды реттейтін басқа заңды құжаттар.';

  @override
  String get legal_settings_section_title => 'Заңды ақпарат';

  @override
  String get legal_settings_section_subtitle =>
      'Құпиялылық саясаты, қызмет көрсету шарттары, EULA және т.б.';

  @override
  String get legal_not_found => 'Құжат табылмады';

  @override
  String get legal_title_privacy_policy => 'Құпиялылық саясаты';

  @override
  String get legal_title_terms_of_service => 'Қызмет көрсету шарттары';

  @override
  String get legal_title_cookie_policy => 'Cookie саясаты';

  @override
  String get legal_title_eula => 'Соңғы пайдаланушы лицензиялық келісімі';

  @override
  String get legal_title_dpa => 'Деректерді өңдеу келісімі';

  @override
  String get legal_title_children => 'Балалар саясаты';

  @override
  String get legal_title_moderation => 'Контентті модерациялау саясаты';

  @override
  String get legal_title_aup => 'Қолайлы пайдалану саясаты';

  @override
  String get chat_list_item_sender_you => 'Сіз';

  @override
  String get chat_preview_message => 'Хабарлама';

  @override
  String get chat_preview_sticker => 'Стикер';

  @override
  String get chat_preview_attachment => 'Тіркеме';

  @override
  String get contacts_disclosure_title => 'LighChat-та таныстарды табу';

  @override
  String get contacts_disclosure_body =>
      'LighChat телефон нөмірлері мен email-мекенжайларды мекенжай кітабыңыздан оқиды, оларды хэштейді және қолданбаны пайдаланатын контактілерді көрсету үшін серверімізбен тексереді. Контактілердің өзі ешқайда сақталмайды.';

  @override
  String get contacts_disclosure_allow => 'Рұқсат беру';

  @override
  String get contacts_disclosure_deny => 'Қазір емес';

  @override
  String get report_title => 'Шағым жасау';

  @override
  String get report_subtitle_message => 'Хабарламаға шағым';

  @override
  String get report_subtitle_user => 'Пайдаланушыға шағым';

  @override
  String get report_reason_spam => 'Спам';

  @override
  String get report_reason_offensive => 'Қорлайтын мазмұн';

  @override
  String get report_reason_violence => 'Зорлық-зомбылық немесе қорқыту';

  @override
  String get report_reason_fraud => 'Алаяқтық';

  @override
  String get report_reason_other => 'Басқа';

  @override
  String get report_comment_hint => 'Қосымша мәліметтер (міндетті емес)';

  @override
  String get report_submit => 'Жіберу';

  @override
  String get report_success => 'Шағым жіберілді. Рахмет!';

  @override
  String get report_error => 'Шағымды жіберу мүмкін болмады';

  @override
  String get message_menu_action_report => 'Шағым жасау';

  @override
  String get partner_profile_menu_report => 'Пайдаланушыға шағым';
}
