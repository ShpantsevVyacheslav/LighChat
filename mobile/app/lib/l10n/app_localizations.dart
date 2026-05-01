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

  /// No description provided for @secret_chat_title.
  ///
  /// In ru, this message translates to:
  /// **'Секретный чат'**
  String get secret_chat_title;

  /// No description provided for @secret_chats_title.
  ///
  /// In ru, this message translates to:
  /// **'Секретные чаты'**
  String get secret_chats_title;

  /// No description provided for @secret_chat_locked_title.
  ///
  /// In ru, this message translates to:
  /// **'Секретный чат заблокирован'**
  String get secret_chat_locked_title;

  /// No description provided for @secret_chat_locked_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Введите PIN-код, чтобы открыть чат и посмотреть сообщения.'**
  String get secret_chat_locked_subtitle;

  /// No description provided for @secret_chat_unlock_title.
  ///
  /// In ru, this message translates to:
  /// **'Открыть секретный чат'**
  String get secret_chat_unlock_title;

  /// No description provided for @secret_chat_unlock_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Для открытия чата требуется PIN-код.'**
  String get secret_chat_unlock_subtitle;

  /// No description provided for @secret_chat_unlock_action.
  ///
  /// In ru, this message translates to:
  /// **'Открыть'**
  String get secret_chat_unlock_action;

  /// No description provided for @secret_chat_set_pin_and_unlock.
  ///
  /// In ru, this message translates to:
  /// **'Установить PIN и открыть'**
  String get secret_chat_set_pin_and_unlock;

  /// No description provided for @secret_chat_pin_label.
  ///
  /// In ru, this message translates to:
  /// **'PIN-код (4 цифры)'**
  String get secret_chat_pin_label;

  /// No description provided for @secret_chat_pin_invalid.
  ///
  /// In ru, this message translates to:
  /// **'Введите 4 цифры'**
  String get secret_chat_pin_invalid;

  /// No description provided for @secret_chat_already_exists.
  ///
  /// In ru, this message translates to:
  /// **'Секретный чат с этим пользователем уже существует.'**
  String get secret_chat_already_exists;

  /// No description provided for @secret_chat_exists_badge.
  ///
  /// In ru, this message translates to:
  /// **'Создан'**
  String get secret_chat_exists_badge;

  /// No description provided for @secret_chat_unlock_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть. Попробуйте ещё раз.'**
  String get secret_chat_unlock_failed;

  /// No description provided for @secret_chat_action_not_allowed.
  ///
  /// In ru, this message translates to:
  /// **'Это действие запрещено в секретном чате'**
  String get secret_chat_action_not_allowed;

  /// No description provided for @secret_chat_remember_pin.
  ///
  /// In ru, this message translates to:
  /// **'Запомнить PIN на этом устройстве'**
  String get secret_chat_remember_pin;

  /// No description provided for @secret_chat_unlock_biometric.
  ///
  /// In ru, this message translates to:
  /// **'Открыть с помощью биометрии'**
  String get secret_chat_unlock_biometric;

  /// No description provided for @secret_chat_biometric_reason.
  ///
  /// In ru, this message translates to:
  /// **'Открыть секретный чат'**
  String get secret_chat_biometric_reason;

  /// No description provided for @secret_chat_biometric_no_saved_pin.
  ///
  /// In ru, this message translates to:
  /// **'Введите PIN один раз, чтобы включить биометрию'**
  String get secret_chat_biometric_no_saved_pin;

  /// No description provided for @secret_chat_ttl_title.
  ///
  /// In ru, this message translates to:
  /// **'Срок жизни секретного чата'**
  String get secret_chat_ttl_title;

  /// No description provided for @secret_chat_settings_title.
  ///
  /// In ru, this message translates to:
  /// **'Настройки секретного чата'**
  String get secret_chat_settings_title;

  /// No description provided for @secret_chat_settings_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Срок жизни, доступ и ограничения'**
  String get secret_chat_settings_subtitle;

  /// No description provided for @secret_chat_settings_not_secret.
  ///
  /// In ru, this message translates to:
  /// **'Этот чат не является секретным'**
  String get secret_chat_settings_not_secret;

  /// No description provided for @secret_chat_settings_ttl.
  ///
  /// In ru, this message translates to:
  /// **'Срок жизни'**
  String get secret_chat_settings_ttl;

  /// No description provided for @secret_chat_settings_time_left.
  ///
  /// In ru, this message translates to:
  /// **'Осталось: {value}'**
  String secret_chat_settings_time_left(Object value);

  /// No description provided for @secret_chat_settings_expires_at.
  ///
  /// In ru, this message translates to:
  /// **'Истекает: {iso}'**
  String secret_chat_settings_expires_at(Object iso);

  /// No description provided for @secret_chat_settings_unlock_grant_ttl.
  ///
  /// In ru, this message translates to:
  /// **'Длительность открытия'**
  String get secret_chat_settings_unlock_grant_ttl;

  /// No description provided for @secret_chat_settings_unlock_grant_ttl_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Сколько действует доступ после открытия'**
  String get secret_chat_settings_unlock_grant_ttl_subtitle;

  /// No description provided for @secret_chat_settings_no_copy.
  ///
  /// In ru, this message translates to:
  /// **'Запретить копирование'**
  String get secret_chat_settings_no_copy;

  /// No description provided for @secret_chat_settings_no_forward.
  ///
  /// In ru, this message translates to:
  /// **'Запретить пересылку'**
  String get secret_chat_settings_no_forward;

  /// No description provided for @secret_chat_settings_no_save.
  ///
  /// In ru, this message translates to:
  /// **'Запретить сохранение медиа'**
  String get secret_chat_settings_no_save;

  /// No description provided for @secret_chat_settings_screenshot_protection.
  ///
  /// In ru, this message translates to:
  /// **'Защита от скриншотов (Android)'**
  String get secret_chat_settings_screenshot_protection;

  /// No description provided for @secret_chat_settings_media_views.
  ///
  /// In ru, this message translates to:
  /// **'Лимиты просмотров медиа'**
  String get secret_chat_settings_media_views;

  /// No description provided for @secret_chat_settings_media_views_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Best-effort лимиты просмотров у получателя'**
  String get secret_chat_settings_media_views_subtitle;

  /// No description provided for @secret_chat_media_type_image.
  ///
  /// In ru, this message translates to:
  /// **'Изображения'**
  String get secret_chat_media_type_image;

  /// No description provided for @secret_chat_media_type_video.
  ///
  /// In ru, this message translates to:
  /// **'Видео'**
  String get secret_chat_media_type_video;

  /// No description provided for @secret_chat_media_type_voice.
  ///
  /// In ru, this message translates to:
  /// **'Голосовые'**
  String get secret_chat_media_type_voice;

  /// No description provided for @secret_chat_media_type_location.
  ///
  /// In ru, this message translates to:
  /// **'Локация'**
  String get secret_chat_media_type_location;

  /// No description provided for @secret_chat_media_type_file.
  ///
  /// In ru, this message translates to:
  /// **'Файлы'**
  String get secret_chat_media_type_file;

  /// No description provided for @secret_chat_media_views_unlimited.
  ///
  /// In ru, this message translates to:
  /// **'Безлимит'**
  String get secret_chat_media_views_unlimited;

  /// No description provided for @secret_chat_compose_create.
  ///
  /// In ru, this message translates to:
  /// **'Создать секретный чат'**
  String get secret_chat_compose_create;

  /// No description provided for @secret_chat_compose_vault_pin_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Необязательно: 4-цифровой PIN для доступа к списку секретных чатов (сохраняется на устройстве для биометрии).'**
  String get secret_chat_compose_vault_pin_subtitle;

  /// No description provided for @secret_chat_compose_require_unlock_pin.
  ///
  /// In ru, this message translates to:
  /// **'Требовать PIN при открытии чата'**
  String get secret_chat_compose_require_unlock_pin;

  /// No description provided for @secret_chat_settings_read_only_hint.
  ///
  /// In ru, this message translates to:
  /// **'Параметры задаются при создании и дальше не меняются.'**
  String get secret_chat_settings_read_only_hint;

  /// No description provided for @secret_chat_settings_delete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить секретный чат'**
  String get secret_chat_settings_delete;

  /// No description provided for @secret_chat_settings_delete_confirm_title.
  ///
  /// In ru, this message translates to:
  /// **'Удалить этот секретный чат?'**
  String get secret_chat_settings_delete_confirm_title;

  /// No description provided for @secret_chat_settings_delete_confirm_body.
  ///
  /// In ru, this message translates to:
  /// **'Сообщения и медиа будут удалены у обоих участников.'**
  String get secret_chat_settings_delete_confirm_body;

  /// No description provided for @privacy_secret_vault_title.
  ///
  /// In ru, this message translates to:
  /// **'Секретное хранилище'**
  String get privacy_secret_vault_title;

  /// No description provided for @privacy_secret_vault_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Глобальный PIN и биометрия для входа в секретные чаты.'**
  String get privacy_secret_vault_subtitle;

  /// No description provided for @privacy_secret_vault_change_pin.
  ///
  /// In ru, this message translates to:
  /// **'Установить или сменить PIN хранилища'**
  String get privacy_secret_vault_change_pin;

  /// No description provided for @privacy_secret_vault_change_pin_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Если PIN уже есть, подтвердите старым PIN или биометрией.'**
  String get privacy_secret_vault_change_pin_subtitle;

  /// No description provided for @privacy_secret_vault_bio_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Проверить биометрию и валидировать локально сохраненный PIN.'**
  String get privacy_secret_vault_bio_subtitle;

  /// No description provided for @privacy_secret_vault_bio_reason.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите доступ к секретным чатам'**
  String get privacy_secret_vault_bio_reason;

  /// No description provided for @privacy_secret_vault_current_pin.
  ///
  /// In ru, this message translates to:
  /// **'Текущий PIN'**
  String get privacy_secret_vault_current_pin;

  /// No description provided for @privacy_secret_vault_new_pin.
  ///
  /// In ru, this message translates to:
  /// **'Новый PIN'**
  String get privacy_secret_vault_new_pin;

  /// No description provided for @privacy_secret_vault_repeat_pin.
  ///
  /// In ru, this message translates to:
  /// **'Повторите новый PIN'**
  String get privacy_secret_vault_repeat_pin;

  /// No description provided for @privacy_secret_vault_pin_mismatch.
  ///
  /// In ru, this message translates to:
  /// **'PIN-коды не совпадают'**
  String get privacy_secret_vault_pin_mismatch;

  /// No description provided for @privacy_secret_vault_pin_updated.
  ///
  /// In ru, this message translates to:
  /// **'PIN хранилища обновлен'**
  String get privacy_secret_vault_pin_updated;

  /// No description provided for @privacy_secret_vault_bio_unavailable.
  ///
  /// In ru, this message translates to:
  /// **'Биометрия недоступна на этом устройстве'**
  String get privacy_secret_vault_bio_unavailable;

  /// No description provided for @privacy_secret_vault_bio_verified.
  ///
  /// In ru, this message translates to:
  /// **'Проверка биометрии пройдена'**
  String get privacy_secret_vault_bio_verified;

  /// No description provided for @privacy_secret_vault_setup_required.
  ///
  /// In ru, this message translates to:
  /// **'Сначала настройте PIN или биометрию в разделе Конфиденциальность.'**
  String get privacy_secret_vault_setup_required;

  /// No description provided for @privacy_secret_vault_network_timeout.
  ///
  /// In ru, this message translates to:
  /// **'Таймаут сети. Попробуйте снова.'**
  String get privacy_secret_vault_network_timeout;

  /// No description provided for @privacy_secret_vault_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка секретного хранилища: {error}'**
  String privacy_secret_vault_error(Object error);

  /// No description provided for @tournament_title.
  ///
  /// In ru, this message translates to:
  /// **'Турнир'**
  String get tournament_title;

  /// No description provided for @tournament_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Турнирная таблица и серии партий'**
  String get tournament_subtitle;

  /// No description provided for @tournament_new_game.
  ///
  /// In ru, this message translates to:
  /// **'Новая партия'**
  String get tournament_new_game;

  /// No description provided for @tournament_standings.
  ///
  /// In ru, this message translates to:
  /// **'Таблица'**
  String get tournament_standings;

  /// No description provided for @tournament_standings_empty.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет результатов'**
  String get tournament_standings_empty;

  /// No description provided for @tournament_games.
  ///
  /// In ru, this message translates to:
  /// **'Партии'**
  String get tournament_games;

  /// No description provided for @tournament_games_empty.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет партий'**
  String get tournament_games_empty;

  /// No description provided for @tournament_points.
  ///
  /// In ru, this message translates to:
  /// **'{pts} очков'**
  String tournament_points(Object pts);

  /// No description provided for @tournament_games_played.
  ///
  /// In ru, this message translates to:
  /// **'{n} игр'**
  String tournament_games_played(Object n);

  /// No description provided for @tournament_create_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось создать турнир: {err}'**
  String tournament_create_failed(Object err);

  /// No description provided for @tournament_create_game_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось создать партию: {err}'**
  String tournament_create_game_failed(Object err);

  /// No description provided for @tournament_game_players.
  ///
  /// In ru, this message translates to:
  /// **'Игроки: {names}'**
  String tournament_game_players(Object names);

  /// No description provided for @tournament_game_result_draw.
  ///
  /// In ru, this message translates to:
  /// **'Результат: ничья'**
  String get tournament_game_result_draw;

  /// No description provided for @tournament_game_result_loser.
  ///
  /// In ru, this message translates to:
  /// **'Результат: дурак — {name}'**
  String tournament_game_result_loser(Object name);

  /// No description provided for @tournament_game_place.
  ///
  /// In ru, this message translates to:
  /// **'Место {place}'**
  String tournament_game_place(Object place);

  /// No description provided for @durak_dm_lobby_banner.
  ///
  /// In ru, this message translates to:
  /// **'Собеседник создал лобби «Дурак» — присоединиться'**
  String get durak_dm_lobby_banner;

  /// No description provided for @durak_dm_lobby_open.
  ///
  /// In ru, this message translates to:
  /// **'Открыть лобби'**
  String get durak_dm_lobby_open;

  /// No description provided for @conversation_game_lobby_cancel.
  ///
  /// In ru, this message translates to:
  /// **'Завершить ожидание'**
  String get conversation_game_lobby_cancel;

  /// No description provided for @conversation_game_lobby_cancel_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось завершить ожидание: {err}'**
  String conversation_game_lobby_cancel_failed(Object err);

  /// No description provided for @secret_chat_media_views_count.
  ///
  /// In ru, this message translates to:
  /// **'{count} просмотров'**
  String secret_chat_media_views_count(Object count);

  /// No description provided for @secret_chat_settings_load_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить: {error}'**
  String secret_chat_settings_load_failed(Object error);

  /// No description provided for @secret_chat_settings_save_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить: {error}'**
  String secret_chat_settings_save_failed(Object error);

  /// No description provided for @secret_chat_settings_reset_strict.
  ///
  /// In ru, this message translates to:
  /// **'Сброс к строгим настройкам'**
  String get secret_chat_settings_reset_strict;

  /// No description provided for @secret_chat_settings_reset_strict_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Включит все запреты и установит лимит просмотров медиа = 1'**
  String get secret_chat_settings_reset_strict_subtitle;

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

  /// No description provided for @account_menu_blacklist.
  ///
  /// In ru, this message translates to:
  /// **'Черный список'**
  String get account_menu_blacklist;

  /// No description provided for @account_menu_language.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get account_menu_language;

  /// No description provided for @account_menu_storage.
  ///
  /// In ru, this message translates to:
  /// **'Хранилище'**
  String get account_menu_storage;

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

  /// No description provided for @storage_settings_title.
  ///
  /// In ru, this message translates to:
  /// **'Хранилище'**
  String get storage_settings_title;

  /// No description provided for @storage_settings_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Управляйте локальным кэшем на устройстве: что хранить, что чистить и сколько места выделять.'**
  String get storage_settings_subtitle;

  /// No description provided for @storage_settings_total_label.
  ///
  /// In ru, this message translates to:
  /// **'Занято на устройстве'**
  String get storage_settings_total_label;

  /// No description provided for @storage_settings_budget_label.
  ///
  /// In ru, this message translates to:
  /// **'Целевой лимит кэша: {mb} МБ'**
  String storage_settings_budget_label(Object mb);

  /// No description provided for @storage_settings_clear_all_button.
  ///
  /// In ru, this message translates to:
  /// **'Очистить весь кэш'**
  String get storage_settings_clear_all_button;

  /// No description provided for @storage_settings_trim_button.
  ///
  /// In ru, this message translates to:
  /// **'Поджать до лимита'**
  String get storage_settings_trim_button;

  /// No description provided for @storage_settings_policy_title.
  ///
  /// In ru, this message translates to:
  /// **'Что хранить локально'**
  String get storage_settings_policy_title;

  /// No description provided for @storage_settings_budget_slider_title.
  ///
  /// In ru, this message translates to:
  /// **'Лимит кэша'**
  String get storage_settings_budget_slider_title;

  /// No description provided for @storage_settings_breakdown_title.
  ///
  /// In ru, this message translates to:
  /// **'Разбивка по типам'**
  String get storage_settings_breakdown_title;

  /// No description provided for @storage_settings_breakdown_empty.
  ///
  /// In ru, this message translates to:
  /// **'Локальный кэш пока пуст.'**
  String get storage_settings_breakdown_empty;

  /// No description provided for @storage_settings_chats_title.
  ///
  /// In ru, this message translates to:
  /// **'Разбивка по чатам'**
  String get storage_settings_chats_title;

  /// No description provided for @storage_settings_chats_empty.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет кэша, привязанного к чатам.'**
  String get storage_settings_chats_empty;

  /// No description provided for @storage_settings_chat_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'{count} элементов · {size}'**
  String storage_settings_chat_subtitle(Object count, Object size);

  /// No description provided for @storage_settings_general_title.
  ///
  /// In ru, this message translates to:
  /// **'Кэш без привязки к чату'**
  String get storage_settings_general_title;

  /// No description provided for @storage_settings_general_hint.
  ///
  /// In ru, this message translates to:
  /// **'Записи, которые не удалось однозначно связать с конкретным чатом (legacy/глобальный кэш).'**
  String get storage_settings_general_hint;

  /// No description provided for @storage_settings_general_empty.
  ///
  /// In ru, this message translates to:
  /// **'Общий кэш пуст.'**
  String get storage_settings_general_empty;

  /// No description provided for @storage_settings_chat_files_empty.
  ///
  /// In ru, this message translates to:
  /// **'Локальных файлов для этого чата пока нет.'**
  String get storage_settings_chat_files_empty;

  /// No description provided for @storage_settings_clear_chat_action.
  ///
  /// In ru, this message translates to:
  /// **'Очистить кэш чата'**
  String get storage_settings_clear_chat_action;

  /// No description provided for @storage_settings_clear_all_title.
  ///
  /// In ru, this message translates to:
  /// **'Очистить локальный кэш?'**
  String get storage_settings_clear_all_title;

  /// No description provided for @storage_settings_clear_all_body.
  ///
  /// In ru, this message translates to:
  /// **'Будут удалены кэшированные файлы, превью, черновики и офлайн-снимки списка чатов на этом устройстве.'**
  String get storage_settings_clear_all_body;

  /// No description provided for @storage_settings_clear_chat_title.
  ///
  /// In ru, this message translates to:
  /// **'Очистить кэш «{chat}»?'**
  String storage_settings_clear_chat_title(Object chat);

  /// No description provided for @storage_settings_clear_chat_body.
  ///
  /// In ru, this message translates to:
  /// **'Удалится только локальный кэш этого чата. Облачные сообщения не затрагиваются.'**
  String get storage_settings_clear_chat_body;

  /// No description provided for @storage_settings_snackbar_cleared.
  ///
  /// In ru, this message translates to:
  /// **'Локальный кэш очищен'**
  String get storage_settings_snackbar_cleared;

  /// No description provided for @storage_settings_snackbar_budget_already_ok.
  ///
  /// In ru, this message translates to:
  /// **'Кэш уже укладывается в лимит'**
  String get storage_settings_snackbar_budget_already_ok;

  /// No description provided for @storage_settings_snackbar_budget_trimmed.
  ///
  /// In ru, this message translates to:
  /// **'Освобождено: {size}'**
  String storage_settings_snackbar_budget_trimmed(Object size);

  /// No description provided for @storage_settings_error_empty.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось собрать статистику хранилища'**
  String get storage_settings_error_empty;

  /// No description provided for @storage_category_e2ee_media.
  ///
  /// In ru, this message translates to:
  /// **'E2EE медиа-кэш'**
  String get storage_category_e2ee_media;

  /// No description provided for @storage_category_e2ee_media_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Расшифрованные медиа секретных чатов для быстрого повторного открытия.'**
  String get storage_category_e2ee_media_subtitle;

  /// No description provided for @storage_category_e2ee_text.
  ///
  /// In ru, this message translates to:
  /// **'E2EE текст-кэш'**
  String get storage_category_e2ee_text;

  /// No description provided for @storage_category_e2ee_text_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Расшифрованный текст сообщений по чатам для мгновенного рендера.'**
  String get storage_category_e2ee_text_subtitle;

  /// No description provided for @storage_category_drafts.
  ///
  /// In ru, this message translates to:
  /// **'Черновики сообщений'**
  String get storage_category_drafts;

  /// No description provided for @storage_category_drafts_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Неотправленные черновики по чатам.'**
  String get storage_category_drafts_subtitle;

  /// No description provided for @storage_category_chat_list_snapshot.
  ///
  /// In ru, this message translates to:
  /// **'Офлайн-список чатов'**
  String get storage_category_chat_list_snapshot;

  /// No description provided for @storage_category_chat_list_snapshot_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Последний снимок списка чатов для быстрого старта без сети.'**
  String get storage_category_chat_list_snapshot_subtitle;

  /// No description provided for @storage_category_profile_cards.
  ///
  /// In ru, this message translates to:
  /// **'Мини-кэш профилей'**
  String get storage_category_profile_cards;

  /// No description provided for @storage_category_profile_cards_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Имена и аватары для ускорения интерфейса.'**
  String get storage_category_profile_cards_subtitle;

  /// No description provided for @storage_category_video_downloads.
  ///
  /// In ru, this message translates to:
  /// **'Кэш загруженных видео'**
  String get storage_category_video_downloads;

  /// No description provided for @storage_category_video_downloads_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Локальные копии видео из просмотрщика медиа.'**
  String get storage_category_video_downloads_subtitle;

  /// No description provided for @storage_category_video_thumbs.
  ///
  /// In ru, this message translates to:
  /// **'Превью-кадры видео'**
  String get storage_category_video_thumbs;

  /// No description provided for @storage_category_video_thumbs_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Сгенерированные первые кадры для видео.'**
  String get storage_category_video_thumbs_subtitle;

  /// No description provided for @profile_delete_account.
  ///
  /// In ru, this message translates to:
  /// **'Удалить аккаунт'**
  String get profile_delete_account;

  /// No description provided for @profile_delete_account_confirm_title.
  ///
  /// In ru, this message translates to:
  /// **'Удалить аккаунт безвозвратно?'**
  String get profile_delete_account_confirm_title;

  /// No description provided for @profile_delete_account_confirm_body.
  ///
  /// In ru, this message translates to:
  /// **'Ваш аккаунт будет удалён из Firebase Auth и все ваши документы в Firestore будут удалены без возможности восстановления. У собеседников останутся ваши чаты в режиме только чтение.'**
  String get profile_delete_account_confirm_body;

  /// No description provided for @profile_delete_account_confirm_action.
  ///
  /// In ru, this message translates to:
  /// **'Удалить аккаунт'**
  String get profile_delete_account_confirm_action;

  /// No description provided for @profile_delete_account_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось удалить аккаунт: {error}'**
  String profile_delete_account_error(Object error);

  /// No description provided for @chat_readonly_deleted_user.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт удалён. Чат доступен только для чтения.'**
  String get chat_readonly_deleted_user;

  /// No description provided for @blacklist_empty.
  ///
  /// In ru, this message translates to:
  /// **'Нет заблокированных пользователей'**
  String get blacklist_empty;

  /// No description provided for @blacklist_action_unblock.
  ///
  /// In ru, this message translates to:
  /// **'Разблокировать'**
  String get blacklist_action_unblock;

  /// No description provided for @blacklist_unblock_confirm_title.
  ///
  /// In ru, this message translates to:
  /// **'Разблокировать?'**
  String get blacklist_unblock_confirm_title;

  /// No description provided for @blacklist_unblock_confirm_body.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь снова сможет писать вам (если политика контактов позволит) и видеть ваш профиль в поиске.'**
  String get blacklist_unblock_confirm_body;

  /// No description provided for @blacklist_unblock_success.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь разблокирован'**
  String get blacklist_unblock_success;

  /// No description provided for @blacklist_unblock_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось разблокировать: {error}'**
  String blacklist_unblock_error(Object error);

  /// No description provided for @partner_profile_block_confirm_title.
  ///
  /// In ru, this message translates to:
  /// **'Заблокировать пользователя?'**
  String get partner_profile_block_confirm_title;

  /// No description provided for @partner_profile_block_confirm_body.
  ///
  /// In ru, this message translates to:
  /// **'Он не увидит чат с вами, не сможет найти вас в поиске и добавить в контакты. У него вы пропадёте из контактов. Вы сохраните переписку, но не сможете писать ему, пока он в списке заблокированных.'**
  String get partner_profile_block_confirm_body;

  /// No description provided for @partner_profile_block_action.
  ///
  /// In ru, this message translates to:
  /// **'Заблокировать'**
  String get partner_profile_block_action;

  /// No description provided for @partner_profile_block_success.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь заблокирован'**
  String get partner_profile_block_success;

  /// No description provided for @partner_profile_block_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось заблокировать: {error}'**
  String partner_profile_block_error(Object error);

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

  /// No description provided for @common_create.
  ///
  /// In ru, this message translates to:
  /// **'Создать'**
  String get common_create;

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

  /// No description provided for @common_save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get common_save;

  /// No description provided for @common_close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get common_close;

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

  /// No description provided for @auth_login_email_label.
  ///
  /// In ru, this message translates to:
  /// **'Email'**
  String get auth_login_email_label;

  /// No description provided for @auth_login_password_label.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get auth_login_password_label;

  /// No description provided for @auth_login_password_hint.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get auth_login_password_hint;

  /// No description provided for @auth_login_sign_in.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get auth_login_sign_in;

  /// No description provided for @auth_login_forgot_password.
  ///
  /// In ru, this message translates to:
  /// **'Забыли пароль?'**
  String get auth_login_forgot_password;

  /// No description provided for @auth_login_error_enter_email_for_reset.
  ///
  /// In ru, this message translates to:
  /// **'Введите email для восстановления пароля'**
  String get auth_login_error_enter_email_for_reset;

  /// No description provided for @profile_title.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get profile_title;

  /// No description provided for @profile_edit_tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать'**
  String get profile_edit_tooltip;

  /// No description provided for @profile_full_name_label.
  ///
  /// In ru, this message translates to:
  /// **'ФИО'**
  String get profile_full_name_label;

  /// No description provided for @profile_full_name_hint.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get profile_full_name_hint;

  /// No description provided for @profile_username_label.
  ///
  /// In ru, this message translates to:
  /// **'Логин'**
  String get profile_username_label;

  /// No description provided for @profile_email_label.
  ///
  /// In ru, this message translates to:
  /// **'Email'**
  String get profile_email_label;

  /// No description provided for @profile_phone_label.
  ///
  /// In ru, this message translates to:
  /// **'Телефон'**
  String get profile_phone_label;

  /// No description provided for @profile_birthdate_label.
  ///
  /// In ru, this message translates to:
  /// **'Дата рождения'**
  String get profile_birthdate_label;

  /// No description provided for @profile_about_label.
  ///
  /// In ru, this message translates to:
  /// **'О себе'**
  String get profile_about_label;

  /// No description provided for @profile_about_hint.
  ///
  /// In ru, this message translates to:
  /// **'Кратко о себе'**
  String get profile_about_hint;

  /// No description provided for @profile_password_toggle_show.
  ///
  /// In ru, this message translates to:
  /// **'Изменить пароль'**
  String get profile_password_toggle_show;

  /// No description provided for @profile_password_toggle_hide.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть смену пароля'**
  String get profile_password_toggle_hide;

  /// No description provided for @profile_password_new_label.
  ///
  /// In ru, this message translates to:
  /// **'Новый пароль'**
  String get profile_password_new_label;

  /// No description provided for @profile_password_confirm_label.
  ///
  /// In ru, this message translates to:
  /// **'Повторите пароль'**
  String get profile_password_confirm_label;

  /// No description provided for @profile_password_tooltip_show.
  ///
  /// In ru, this message translates to:
  /// **'Показать пароль'**
  String get profile_password_tooltip_show;

  /// No description provided for @profile_password_tooltip_hide.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть'**
  String get profile_password_tooltip_hide;

  /// No description provided for @profile_placeholder_username.
  ///
  /// In ru, this message translates to:
  /// **'username'**
  String get profile_placeholder_username;

  /// No description provided for @profile_placeholder_email.
  ///
  /// In ru, this message translates to:
  /// **'name@example.com'**
  String get profile_placeholder_email;

  /// No description provided for @profile_placeholder_phone.
  ///
  /// In ru, this message translates to:
  /// **'+7900 000-00-00'**
  String get profile_placeholder_phone;

  /// No description provided for @profile_placeholder_birthdate.
  ///
  /// In ru, this message translates to:
  /// **'ДД.ММ.ГГГГ'**
  String get profile_placeholder_birthdate;

  /// No description provided for @profile_placeholder_password_dots.
  ///
  /// In ru, this message translates to:
  /// **'••••••••'**
  String get profile_placeholder_password_dots;

  /// No description provided for @profile_password_error_fill_both.
  ///
  /// In ru, this message translates to:
  /// **'Заполните новый пароль и повтор.'**
  String get profile_password_error_fill_both;

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

  /// No description provided for @chat_list_folder_delete_action.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get chat_list_folder_delete_action;

  /// No description provided for @chat_list_folder_delete_title.
  ///
  /// In ru, this message translates to:
  /// **'Удалить папку?'**
  String get chat_list_folder_delete_title;

  /// No description provided for @chat_list_folder_delete_body.
  ///
  /// In ru, this message translates to:
  /// **'Папка \"{name}\" будет удалена. Чаты останутся на месте.'**
  String chat_list_folder_delete_body(Object name);

  /// No description provided for @chat_list_error_open_starred.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть Избранное: {error}'**
  String chat_list_error_open_starred(Object error);

  /// No description provided for @chat_list_error_delete_folder.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось удалить папку: {error}'**
  String chat_list_error_delete_folder(Object error);

  /// No description provided for @chat_list_pin_not_available.
  ///
  /// In ru, this message translates to:
  /// **'В этой папке закрепление недоступно.'**
  String get chat_list_pin_not_available;

  /// No description provided for @chat_list_pin_pinned_in_folder.
  ///
  /// In ru, this message translates to:
  /// **'Чат закреплен в папке \"{name}\"'**
  String chat_list_pin_pinned_in_folder(Object name);

  /// No description provided for @chat_list_pin_unpinned_in_folder.
  ///
  /// In ru, this message translates to:
  /// **'Чат откреплен из папки \"{name}\"'**
  String chat_list_pin_unpinned_in_folder(Object name);

  /// No description provided for @chat_list_error_toggle_pin.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось изменить закрепление: {error}'**
  String chat_list_error_toggle_pin(Object error);

  /// No description provided for @chat_list_error_update_folder.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обновить папку: {error}'**
  String chat_list_error_update_folder(Object error);

  /// No description provided for @chat_list_clear_history_title.
  ///
  /// In ru, this message translates to:
  /// **'Очистить историю?'**
  String get chat_list_clear_history_title;

  /// No description provided for @chat_list_clear_history_body.
  ///
  /// In ru, this message translates to:
  /// **'Сообщения исчезнут только из вашего окна чата. У собеседника история останется.'**
  String get chat_list_clear_history_body;

  /// No description provided for @chat_list_clear_history_confirm.
  ///
  /// In ru, this message translates to:
  /// **'Очистить'**
  String get chat_list_clear_history_confirm;

  /// No description provided for @chat_list_error_clear_history.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось очистить историю: {error}'**
  String chat_list_error_clear_history(Object error);

  /// No description provided for @chat_list_error_mark_read.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось пометить чат как прочитанный: {error}'**
  String chat_list_error_mark_read(Object error);

  /// No description provided for @chat_list_delete_chat_title.
  ///
  /// In ru, this message translates to:
  /// **'Удалить чат?'**
  String get chat_list_delete_chat_title;

  /// No description provided for @chat_list_delete_chat_body.
  ///
  /// In ru, this message translates to:
  /// **'Переписка будет безвозвратно удалена для всех участников. Это действие нельзя отменить.'**
  String get chat_list_delete_chat_body;

  /// No description provided for @chat_list_delete_chat_confirm.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get chat_list_delete_chat_confirm;

  /// No description provided for @chat_list_error_delete_chat.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось удалить чат: {error}'**
  String chat_list_error_delete_chat(Object error);

  /// No description provided for @chat_list_context_folders.
  ///
  /// In ru, this message translates to:
  /// **'Папки'**
  String get chat_list_context_folders;

  /// No description provided for @chat_list_context_unpin.
  ///
  /// In ru, this message translates to:
  /// **'Открепить чат'**
  String get chat_list_context_unpin;

  /// No description provided for @chat_list_context_pin.
  ///
  /// In ru, this message translates to:
  /// **'Закрепить чат'**
  String get chat_list_context_pin;

  /// No description provided for @chat_list_context_mark_all_read.
  ///
  /// In ru, this message translates to:
  /// **'Прочитать все'**
  String get chat_list_context_mark_all_read;

  /// No description provided for @chat_list_context_clear_history.
  ///
  /// In ru, this message translates to:
  /// **'Очистить историю'**
  String get chat_list_context_clear_history;

  /// No description provided for @chat_list_context_delete_chat.
  ///
  /// In ru, this message translates to:
  /// **'Удалить чат'**
  String get chat_list_context_delete_chat;

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

  /// No description provided for @chat_calls_title.
  ///
  /// In ru, this message translates to:
  /// **'Звонки'**
  String get chat_calls_title;

  /// No description provided for @chat_calls_search_hint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск по имени…'**
  String get chat_calls_search_hint;

  /// No description provided for @chat_calls_empty.
  ///
  /// In ru, this message translates to:
  /// **'История звонков пуста.'**
  String get chat_calls_empty;

  /// No description provided for @chat_calls_nothing_found.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено.'**
  String get chat_calls_nothing_found;

  /// No description provided for @chat_calls_error_load.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить звонки:\n{error}'**
  String chat_calls_error_load(Object error);

  /// No description provided for @chat_reply_cancel_tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Отменить ответ'**
  String get chat_reply_cancel_tooltip;

  /// No description provided for @voice_preview_tooltip_cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отменить'**
  String get voice_preview_tooltip_cancel;

  /// No description provided for @voice_preview_tooltip_send.
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get voice_preview_tooltip_send;

  /// No description provided for @profile_qr_title.
  ///
  /// In ru, this message translates to:
  /// **'Мой QR-код'**
  String get profile_qr_title;

  /// No description provided for @profile_qr_tooltip_close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get profile_qr_tooltip_close;

  /// No description provided for @profile_qr_share_title.
  ///
  /// In ru, this message translates to:
  /// **'Мой профиль в LighChat'**
  String get profile_qr_share_title;

  /// No description provided for @profile_qr_share_subject.
  ///
  /// In ru, this message translates to:
  /// **'Профиль LighChat'**
  String get profile_qr_share_subject;

  /// No description provided for @chat_media_norm_pending_title.
  ///
  /// In ru, this message translates to:
  /// **'Обрабатываем {mediaKind}…'**
  String chat_media_norm_pending_title(Object mediaKind);

  /// No description provided for @chat_media_norm_failed_title.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обработать {mediaKind}'**
  String chat_media_norm_failed_title(Object mediaKind);

  /// No description provided for @chat_media_norm_pending_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Файл станет доступен после серверной нормализации.'**
  String get chat_media_norm_pending_subtitle;

  /// No description provided for @chat_media_norm_failed_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Попробуйте запустить обработку повторно.'**
  String get chat_media_norm_failed_subtitle;

  /// No description provided for @conversation_threads_title.
  ///
  /// In ru, this message translates to:
  /// **'Обсуждения'**
  String get conversation_threads_title;

  /// No description provided for @conversation_threads_empty.
  ///
  /// In ru, this message translates to:
  /// **'Нет обсуждений'**
  String get conversation_threads_empty;

  /// No description provided for @conversation_threads_root_attachment.
  ///
  /// In ru, this message translates to:
  /// **'Вложение'**
  String get conversation_threads_root_attachment;

  /// No description provided for @conversation_threads_root_message.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение'**
  String get conversation_threads_root_message;

  /// No description provided for @conversation_threads_snippet_you.
  ///
  /// In ru, this message translates to:
  /// **'Вы: {text}'**
  String conversation_threads_snippet_you(Object text);

  /// No description provided for @conversation_threads_day_today.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get conversation_threads_day_today;

  /// No description provided for @conversation_threads_day_yesterday.
  ///
  /// In ru, this message translates to:
  /// **'Вчера'**
  String get conversation_threads_day_yesterday;

  /// No description provided for @conversation_threads_replies_badge.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} ответ} few{{count} ответа} many{{count} ответов} other{{count} ответов}}'**
  String conversation_threads_replies_badge(num count);

  /// No description provided for @chat_meetings_title.
  ///
  /// In ru, this message translates to:
  /// **'Видеовстречи'**
  String get chat_meetings_title;

  /// No description provided for @chat_meetings_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Создавайте конференции и управляйте доступом участников'**
  String get chat_meetings_subtitle;

  /// No description provided for @chat_meetings_section_new.
  ///
  /// In ru, this message translates to:
  /// **'Новая встреча'**
  String get chat_meetings_section_new;

  /// No description provided for @chat_meetings_field_title_label.
  ///
  /// In ru, this message translates to:
  /// **'Название встречи'**
  String get chat_meetings_field_title_label;

  /// No description provided for @chat_meetings_field_title_hint.
  ///
  /// In ru, this message translates to:
  /// **'Напр. Обсуждение логистики'**
  String get chat_meetings_field_title_hint;

  /// No description provided for @chat_meetings_field_duration_label.
  ///
  /// In ru, this message translates to:
  /// **'Длительность'**
  String get chat_meetings_field_duration_label;

  /// No description provided for @chat_meetings_duration_unlimited.
  ///
  /// In ru, this message translates to:
  /// **'Без ограничения'**
  String get chat_meetings_duration_unlimited;

  /// No description provided for @chat_meetings_duration_15m.
  ///
  /// In ru, this message translates to:
  /// **'15 минут'**
  String get chat_meetings_duration_15m;

  /// No description provided for @chat_meetings_duration_30m.
  ///
  /// In ru, this message translates to:
  /// **'30 минут'**
  String get chat_meetings_duration_30m;

  /// No description provided for @chat_meetings_duration_1h.
  ///
  /// In ru, this message translates to:
  /// **'1 час'**
  String get chat_meetings_duration_1h;

  /// No description provided for @chat_meetings_duration_90m.
  ///
  /// In ru, this message translates to:
  /// **'1,5 часа'**
  String get chat_meetings_duration_90m;

  /// No description provided for @chat_meetings_field_access_label.
  ///
  /// In ru, this message translates to:
  /// **'Тип доступа'**
  String get chat_meetings_field_access_label;

  /// No description provided for @chat_meetings_access_private.
  ///
  /// In ru, this message translates to:
  /// **'Закрытая'**
  String get chat_meetings_access_private;

  /// No description provided for @chat_meetings_access_public.
  ///
  /// In ru, this message translates to:
  /// **'Открытая'**
  String get chat_meetings_access_public;

  /// No description provided for @chat_meetings_waiting_room_title.
  ///
  /// In ru, this message translates to:
  /// **'Зал ожидания'**
  String get chat_meetings_waiting_room_title;

  /// No description provided for @chat_meetings_waiting_room_desc.
  ///
  /// In ru, this message translates to:
  /// **'В режиме зала ожидания вы полностью контролируете список участников. Пока вы не нажмёте «Принять», гость будет видеть экран ожидания.'**
  String get chat_meetings_waiting_room_desc;

  /// No description provided for @chat_meetings_backgrounds_title.
  ///
  /// In ru, this message translates to:
  /// **'Виртуальные фоны'**
  String get chat_meetings_backgrounds_title;

  /// No description provided for @chat_meetings_backgrounds_desc.
  ///
  /// In ru, this message translates to:
  /// **'Загружайте фоны и размывайте задний план при желании. Изображение из галереи. Также доступна загрузка собственных фонов.'**
  String get chat_meetings_backgrounds_desc;

  /// No description provided for @chat_meetings_waiting_room_toggle.
  ///
  /// In ru, this message translates to:
  /// **'Добавить комнату ожидания'**
  String get chat_meetings_waiting_room_toggle;

  /// No description provided for @chat_meetings_waiting_room_toggle_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Только хозяин комнаты может дать разрешение на подключение и блокировать'**
  String get chat_meetings_waiting_room_toggle_subtitle;

  /// No description provided for @chat_meetings_create_button.
  ///
  /// In ru, this message translates to:
  /// **'Создать встречу'**
  String get chat_meetings_create_button;

  /// No description provided for @chat_meetings_snackbar_enter_title.
  ///
  /// In ru, this message translates to:
  /// **'Укажите название встречи'**
  String get chat_meetings_snackbar_enter_title;

  /// No description provided for @chat_meetings_snackbar_auth_required.
  ///
  /// In ru, this message translates to:
  /// **'Нужна авторизация для создания встречи'**
  String get chat_meetings_snackbar_auth_required;

  /// No description provided for @chat_meetings_error_create_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось создать встречу: {error}'**
  String chat_meetings_error_create_failed(Object error);

  /// No description provided for @chat_meetings_history_title.
  ///
  /// In ru, this message translates to:
  /// **'Ваша история'**
  String get chat_meetings_history_title;

  /// No description provided for @chat_meetings_history_empty.
  ///
  /// In ru, this message translates to:
  /// **'История встреч пуста'**
  String get chat_meetings_history_empty;

  /// No description provided for @chat_meetings_history_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить историю встреч: {error}'**
  String chat_meetings_history_error(Object error);

  /// No description provided for @chat_meetings_status_live.
  ///
  /// In ru, this message translates to:
  /// **'идёт'**
  String get chat_meetings_status_live;

  /// No description provided for @chat_meetings_status_finished.
  ///
  /// In ru, this message translates to:
  /// **'завершена'**
  String get chat_meetings_status_finished;

  /// No description provided for @chat_meetings_badge_private.
  ///
  /// In ru, this message translates to:
  /// **'закрытая'**
  String get chat_meetings_badge_private;

  /// No description provided for @chat_contacts_search_hint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск контактов...'**
  String get chat_contacts_search_hint;

  /// No description provided for @chat_contacts_permission_denied.
  ///
  /// In ru, this message translates to:
  /// **'Доступ к контактам не предоставлен.'**
  String get chat_contacts_permission_denied;

  /// No description provided for @chat_contacts_sync_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка синхронизации контактов: {error}'**
  String chat_contacts_sync_error(Object error);

  /// No description provided for @chat_contacts_invite_prepare_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось подготовить приглашение: {error}'**
  String chat_contacts_invite_prepare_failed(Object error);

  /// No description provided for @chat_contacts_matches_not_found.
  ///
  /// In ru, this message translates to:
  /// **'Совпадений не найдено.'**
  String get chat_contacts_matches_not_found;

  /// No description provided for @chat_contacts_added_count.
  ///
  /// In ru, this message translates to:
  /// **'Добавлено контактов: {count}.'**
  String chat_contacts_added_count(Object count);

  /// No description provided for @chat_contacts_invite_text.
  ///
  /// In ru, this message translates to:
  /// **'Поставь LighChat: https://lighchat.online\nПриглашаю тебя в LighChat — вот ссылка на установку.'**
  String get chat_contacts_invite_text;

  /// No description provided for @chat_contacts_invite_subject.
  ///
  /// In ru, this message translates to:
  /// **'Приглашение в LighChat'**
  String get chat_contacts_invite_subject;

  /// No description provided for @chat_contacts_error_load.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки контактов: {error}'**
  String chat_contacts_error_load(Object error);

  /// No description provided for @chat_list_item_draft_line.
  ///
  /// In ru, this message translates to:
  /// **'Черновик · {line}'**
  String chat_list_item_draft_line(Object line);

  /// No description provided for @chat_list_item_chat_created.
  ///
  /// In ru, this message translates to:
  /// **'Чат создан'**
  String get chat_list_item_chat_created;

  /// No description provided for @chat_list_item_no_messages_yet.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет сообщений'**
  String get chat_list_item_no_messages_yet;

  /// No description provided for @chat_list_item_history_cleared.
  ///
  /// In ru, this message translates to:
  /// **'История очищена'**
  String get chat_list_item_history_cleared;

  /// No description provided for @chat_list_firebase_not_configured.
  ///
  /// In ru, this message translates to:
  /// **'Firebase ещё не настроен.'**
  String get chat_list_firebase_not_configured;

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

  /// No description provided for @new_chat_fallback_user_display_name.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь'**
  String get new_chat_fallback_user_display_name;

  /// No description provided for @new_group_role_badge_admin.
  ///
  /// In ru, this message translates to:
  /// **'АДМИН'**
  String get new_group_role_badge_admin;

  /// No description provided for @new_group_role_badge_worker.
  ///
  /// In ru, this message translates to:
  /// **'СОТРУДНИК'**
  String get new_group_role_badge_worker;

  /// No description provided for @new_group_error_auth_session.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка авторизации: {error}'**
  String new_group_error_auth_session(Object error);

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

  /// No description provided for @group_members_title.
  ///
  /// In ru, this message translates to:
  /// **'Участники'**
  String get group_members_title;

  /// No description provided for @group_members_invite_link.
  ///
  /// In ru, this message translates to:
  /// **'Пригласить по ссылке'**
  String get group_members_invite_link;

  /// No description provided for @group_members_admin_badge.
  ///
  /// In ru, this message translates to:
  /// **'АДМИН'**
  String get group_members_admin_badge;

  /// No description provided for @group_members_invite_text.
  ///
  /// In ru, this message translates to:
  /// **'Присоединяйся к группе {groupName} в LighChat: {inviteLink}'**
  String group_members_invite_text(Object groupName, Object inviteLink);

  /// No description provided for @group_members_error_min_admin.
  ///
  /// In ru, this message translates to:
  /// **'В группе должен остаться хотя бы один администратор.'**
  String get group_members_error_min_admin;

  /// No description provided for @group_members_error_cannot_remove_creator.
  ///
  /// In ru, this message translates to:
  /// **'Нельзя снять права администратора с создателя группы.'**
  String get group_members_error_cannot_remove_creator;

  /// No description provided for @group_members_remove_admin.
  ///
  /// In ru, this message translates to:
  /// **'Администратор снят'**
  String get group_members_remove_admin;

  /// No description provided for @group_members_make_admin.
  ///
  /// In ru, this message translates to:
  /// **'Назначен администратор'**
  String get group_members_make_admin;

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

  /// No description provided for @voice_transcript_show.
  ///
  /// In ru, this message translates to:
  /// **'Показать текст'**
  String get voice_transcript_show;

  /// No description provided for @voice_transcript_hide.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть текст'**
  String get voice_transcript_hide;

  /// No description provided for @voice_transcript_copy.
  ///
  /// In ru, this message translates to:
  /// **'Копировать'**
  String get voice_transcript_copy;

  /// No description provided for @voice_transcript_loading.
  ///
  /// In ru, this message translates to:
  /// **'Транскрибация…'**
  String get voice_transcript_loading;

  /// No description provided for @voice_transcript_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось получить текст.'**
  String get voice_transcript_failed;

  /// No description provided for @voice_attachment_media_kind_audio.
  ///
  /// In ru, this message translates to:
  /// **'аудио'**
  String get voice_attachment_media_kind_audio;

  /// No description provided for @voice_attachment_load_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить'**
  String get voice_attachment_load_failed;

  /// No description provided for @voice_attachment_title_voice_message.
  ///
  /// In ru, this message translates to:
  /// **'Голосовое сообщение'**
  String get voice_attachment_title_voice_message;

  /// No description provided for @voice_transcript_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сделать транскрибацию: {error}'**
  String voice_transcript_error(Object error);

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

  /// No description provided for @video_call_error_init.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка видеозвонка: {error}'**
  String video_call_error_init(Object error);

  /// No description provided for @video_call_ended.
  ///
  /// In ru, this message translates to:
  /// **'Звонок завершён'**
  String get video_call_ended;

  /// No description provided for @video_call_status_missed.
  ///
  /// In ru, this message translates to:
  /// **'Пропущенный звонок'**
  String get video_call_status_missed;

  /// No description provided for @video_call_status_cancelled.
  ///
  /// In ru, this message translates to:
  /// **'Звонок отменён'**
  String get video_call_status_cancelled;

  /// No description provided for @video_call_error_offer_not_ready.
  ///
  /// In ru, this message translates to:
  /// **'Оффер ещё не готов, попробуйте снова'**
  String get video_call_error_offer_not_ready;

  /// No description provided for @video_call_error_invalid_call_data.
  ///
  /// In ru, this message translates to:
  /// **'Некорректные данные звонка'**
  String get video_call_error_invalid_call_data;

  /// No description provided for @video_call_error_accept_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось принять звонок: {error}'**
  String video_call_error_accept_failed(Object error);

  /// No description provided for @video_call_incoming.
  ///
  /// In ru, this message translates to:
  /// **'Входящий видеозвонок'**
  String get video_call_incoming;

  /// No description provided for @video_call_connecting.
  ///
  /// In ru, this message translates to:
  /// **'Видеозвонок…'**
  String get video_call_connecting;

  /// No description provided for @video_call_pip_tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Картинка в картинке'**
  String get video_call_pip_tooltip;

  /// No description provided for @video_call_mini_window_tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Мини-окно'**
  String get video_call_mini_window_tooltip;

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

  /// No description provided for @forward_title.
  ///
  /// In ru, this message translates to:
  /// **'Переслать'**
  String get forward_title;

  /// No description provided for @forward_empty_no_messages.
  ///
  /// In ru, this message translates to:
  /// **'Нет сообщений для пересылки'**
  String get forward_empty_no_messages;

  /// No description provided for @forward_error_not_authorized.
  ///
  /// In ru, this message translates to:
  /// **'Не авторизован'**
  String get forward_error_not_authorized;

  /// No description provided for @forward_empty_no_recipients.
  ///
  /// In ru, this message translates to:
  /// **'Нет контактов и чатов для пересылки'**
  String get forward_empty_no_recipients;

  /// No description provided for @forward_search_hint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск контактов…'**
  String get forward_search_hint;

  /// No description provided for @forward_empty_no_available_recipients.
  ///
  /// In ru, this message translates to:
  /// **'Доступных получателей нет.\nМожно пересылать только контактам и в ваши активные чаты.'**
  String get forward_empty_no_available_recipients;

  /// No description provided for @forward_empty_not_found.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено'**
  String get forward_empty_not_found;

  /// No description provided for @forward_action_pick_recipients.
  ///
  /// In ru, this message translates to:
  /// **'Выберите получателей'**
  String get forward_action_pick_recipients;

  /// No description provided for @forward_action_send.
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get forward_action_send;

  /// No description provided for @forward_error_generic.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка: {error}'**
  String forward_error_generic(Object error);

  /// No description provided for @forward_sender_fallback.
  ///
  /// In ru, this message translates to:
  /// **'Участник'**
  String get forward_sender_fallback;

  /// No description provided for @forward_error_profiles_load.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить профили для открытия чата'**
  String get forward_error_profiles_load;

  /// No description provided for @forward_error_send_no_permissions.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось переслать: нет прав на выбранные чаты или чат больше недоступен.'**
  String get forward_error_send_no_permissions;

  /// No description provided for @forward_error_send_forbidden_chat.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось переслать: доступ к одному из чатов запрещён.'**
  String get forward_error_send_forbidden_chat;

  /// No description provided for @devices_title.
  ///
  /// In ru, this message translates to:
  /// **'Мои устройства'**
  String get devices_title;

  /// No description provided for @devices_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Список устройств, на которых опубликован ваш публичный ключ шифрования. Отзыв автоматически создаёт новую эпоху ключей во всех зашифрованных чатах — отозванное устройство больше не увидит новые сообщения.'**
  String get devices_subtitle;

  /// No description provided for @devices_empty.
  ///
  /// In ru, this message translates to:
  /// **'Устройств пока нет.'**
  String get devices_empty;

  /// No description provided for @devices_progress_rekeying.
  ///
  /// In ru, this message translates to:
  /// **'Обновление чатов: {done} / {total}'**
  String devices_progress_rekeying(Object done, Object total);

  /// No description provided for @devices_chip_current.
  ///
  /// In ru, this message translates to:
  /// **'Это устройство'**
  String get devices_chip_current;

  /// No description provided for @devices_chip_revoked.
  ///
  /// In ru, this message translates to:
  /// **'Отозвано'**
  String get devices_chip_revoked;

  /// No description provided for @devices_meta_created_activity.
  ///
  /// In ru, this message translates to:
  /// **'Создано: {createdAt}  •  Активность: {lastSeenAt}'**
  String devices_meta_created_activity(Object createdAt, Object lastSeenAt);

  /// No description provided for @devices_meta_revoked_at.
  ///
  /// In ru, this message translates to:
  /// **'Отозвано: {revokedAt}'**
  String devices_meta_revoked_at(Object revokedAt);

  /// No description provided for @devices_action_rename.
  ///
  /// In ru, this message translates to:
  /// **'Переименовать'**
  String get devices_action_rename;

  /// No description provided for @devices_action_revoke.
  ///
  /// In ru, this message translates to:
  /// **'Отозвать'**
  String get devices_action_revoke;

  /// No description provided for @devices_dialog_rename_title.
  ///
  /// In ru, this message translates to:
  /// **'Переименовать устройство'**
  String get devices_dialog_rename_title;

  /// No description provided for @devices_dialog_rename_hint.
  ///
  /// In ru, this message translates to:
  /// **'Например, iPhone 15 — Safari'**
  String get devices_dialog_rename_hint;

  /// No description provided for @devices_error_rename_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось переименовать: {error}'**
  String devices_error_rename_failed(Object error);

  /// No description provided for @devices_dialog_revoke_title.
  ///
  /// In ru, this message translates to:
  /// **'Отозвать устройство?'**
  String get devices_dialog_revoke_title;

  /// No description provided for @devices_dialog_revoke_body_current.
  ///
  /// In ru, this message translates to:
  /// **'Вы собираетесь отозвать ТЕКУЩЕЕ устройство. После этого вы не сможете читать новые сообщения в зашифрованных чатах с этого клиента.'**
  String get devices_dialog_revoke_body_current;

  /// No description provided for @devices_dialog_revoke_body_other.
  ///
  /// In ru, this message translates to:
  /// **'Устройство больше не сможет читать новые сообщения в зашифрованных чатах. Старые сообщения останутся доступны на нём.'**
  String get devices_dialog_revoke_body_other;

  /// No description provided for @devices_snackbar_revoked.
  ///
  /// In ru, this message translates to:
  /// **'Устройство отозвано. Обновлено чатов: {rekeyed}{suffix}'**
  String devices_snackbar_revoked(Object rekeyed, Object suffix);

  /// No description provided for @devices_snackbar_failed_suffix.
  ///
  /// In ru, this message translates to:
  /// **', ошибок: {count}'**
  String devices_snackbar_failed_suffix(Object count);

  /// No description provided for @devices_error_revoke_failed.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка revoke: {error}'**
  String devices_error_revoke_failed(Object error);

  /// No description provided for @e2ee_recovery_title.
  ///
  /// In ru, this message translates to:
  /// **'E2EE — резервирование'**
  String get e2ee_recovery_title;

  /// No description provided for @e2ee_password_label.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get e2ee_password_label;

  /// No description provided for @e2ee_password_confirm_label.
  ///
  /// In ru, this message translates to:
  /// **'Повторите пароль'**
  String get e2ee_password_confirm_label;

  /// No description provided for @e2ee_password_min_length.
  ///
  /// In ru, this message translates to:
  /// **'Минимум {count} символов'**
  String e2ee_password_min_length(Object count);

  /// No description provided for @e2ee_password_mismatch.
  ///
  /// In ru, this message translates to:
  /// **'Пароли не совпадают'**
  String get e2ee_password_mismatch;

  /// No description provided for @e2ee_backup_create_title.
  ///
  /// In ru, this message translates to:
  /// **'Создать backup ключа'**
  String get e2ee_backup_create_title;

  /// No description provided for @e2ee_backup_restore_title.
  ///
  /// In ru, this message translates to:
  /// **'Восстановить по паролю'**
  String get e2ee_backup_restore_title;

  /// No description provided for @e2ee_backup_restore_action.
  ///
  /// In ru, this message translates to:
  /// **'Восстановить'**
  String get e2ee_backup_restore_action;

  /// No description provided for @e2ee_backup_create_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось создать backup: {error}'**
  String e2ee_backup_create_error(Object error);

  /// No description provided for @e2ee_backup_restore_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось восстановить: {error}'**
  String e2ee_backup_restore_error(Object error);

  /// No description provided for @e2ee_backup_wrong_password.
  ///
  /// In ru, this message translates to:
  /// **'Неверный пароль'**
  String get e2ee_backup_wrong_password;

  /// No description provided for @e2ee_backup_not_found.
  ///
  /// In ru, this message translates to:
  /// **'Backup не найден'**
  String get e2ee_backup_not_found;

  /// No description provided for @e2ee_recovery_error_generic.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка: {error}'**
  String e2ee_recovery_error_generic(Object error);

  /// No description provided for @e2ee_backup_password_card_title.
  ///
  /// In ru, this message translates to:
  /// **'Backup паролем'**
  String get e2ee_backup_password_card_title;

  /// No description provided for @e2ee_backup_password_card_description.
  ///
  /// In ru, this message translates to:
  /// **'Создайте зашифрованный backup приватного ключа. Если потеряете все устройства, сможете восстановить его на новом, зная только пароль. Пароль нельзя восстановить — записывайте надёжно.'**
  String get e2ee_backup_password_card_description;

  /// No description provided for @e2ee_backup_overwrite.
  ///
  /// In ru, this message translates to:
  /// **'Перезаписать backup'**
  String get e2ee_backup_overwrite;

  /// No description provided for @e2ee_backup_create.
  ///
  /// In ru, this message translates to:
  /// **'Создать backup'**
  String get e2ee_backup_create;

  /// No description provided for @e2ee_backup_restore.
  ///
  /// In ru, this message translates to:
  /// **'Восстановить из backup'**
  String get e2ee_backup_restore;

  /// No description provided for @e2ee_backup_already_have.
  ///
  /// In ru, this message translates to:
  /// **'У меня уже есть backup'**
  String get e2ee_backup_already_have;

  /// No description provided for @e2ee_qr_transfer_title.
  ///
  /// In ru, this message translates to:
  /// **'Передача ключа по QR'**
  String get e2ee_qr_transfer_title;

  /// No description provided for @e2ee_qr_transfer_description.
  ///
  /// In ru, this message translates to:
  /// **'На новом устройстве показываем QR, на старом сканируем камерой. Сверяете 6-значный код — приватный ключ переносится безопасно.'**
  String get e2ee_qr_transfer_description;

  /// No description provided for @e2ee_qr_transfer_open.
  ///
  /// In ru, this message translates to:
  /// **'Открыть QR-pairing'**
  String get e2ee_qr_transfer_open;

  /// No description provided for @media_viewer_action_reply.
  ///
  /// In ru, this message translates to:
  /// **'Ответить'**
  String get media_viewer_action_reply;

  /// No description provided for @media_viewer_action_forward.
  ///
  /// In ru, this message translates to:
  /// **'Переслать'**
  String get media_viewer_action_forward;

  /// No description provided for @media_viewer_action_send.
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get media_viewer_action_send;

  /// No description provided for @media_viewer_action_save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get media_viewer_action_save;

  /// No description provided for @media_viewer_action_show_in_chat.
  ///
  /// In ru, this message translates to:
  /// **'Показать в чате'**
  String get media_viewer_action_show_in_chat;

  /// No description provided for @media_viewer_action_delete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get media_viewer_action_delete;

  /// No description provided for @media_viewer_error_no_gallery_access.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступа к сохранению в галерею'**
  String get media_viewer_error_no_gallery_access;

  /// No description provided for @media_viewer_error_share_unavailable_web.
  ///
  /// In ru, this message translates to:
  /// **'Шаринг недоступен в веб-версии'**
  String get media_viewer_error_share_unavailable_web;

  /// No description provided for @media_viewer_error_file_not_found.
  ///
  /// In ru, this message translates to:
  /// **'Файл не найден'**
  String get media_viewer_error_file_not_found;

  /// No description provided for @media_viewer_error_bad_media_url.
  ///
  /// In ru, this message translates to:
  /// **'Неверная ссылка на медиа'**
  String get media_viewer_error_bad_media_url;

  /// No description provided for @media_viewer_error_bad_url.
  ///
  /// In ru, this message translates to:
  /// **'Неверная ссылка'**
  String get media_viewer_error_bad_url;

  /// No description provided for @media_viewer_error_unsupported_media_scheme.
  ///
  /// In ru, this message translates to:
  /// **'Неподдерживаемый тип медиа'**
  String get media_viewer_error_unsupported_media_scheme;

  /// No description provided for @media_viewer_error_http_status.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка сервера (HTTP {status})'**
  String media_viewer_error_http_status(Object status);

  /// No description provided for @media_viewer_error_save_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить: {error}'**
  String media_viewer_error_save_failed(Object error);

  /// No description provided for @media_viewer_error_send_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить: {error}'**
  String media_viewer_error_send_failed(Object error);

  /// No description provided for @media_viewer_video_playback_speed.
  ///
  /// In ru, this message translates to:
  /// **'Скорость воспроизведения'**
  String get media_viewer_video_playback_speed;

  /// No description provided for @media_viewer_video_quality.
  ///
  /// In ru, this message translates to:
  /// **'Качество'**
  String get media_viewer_video_quality;

  /// No description provided for @media_viewer_video_quality_auto.
  ///
  /// In ru, this message translates to:
  /// **'Авто'**
  String get media_viewer_video_quality_auto;

  /// No description provided for @media_viewer_error_quality_switch_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось переключить качество'**
  String get media_viewer_error_quality_switch_failed;

  /// No description provided for @media_viewer_error_pip_open_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть PiP'**
  String get media_viewer_error_pip_open_failed;

  /// No description provided for @media_viewer_pip_not_supported.
  ///
  /// In ru, this message translates to:
  /// **'Картинка в картинке не поддерживается на этом устройстве.'**
  String get media_viewer_pip_not_supported;

  /// No description provided for @media_viewer_video_processing.
  ///
  /// In ru, this message translates to:
  /// **'Видео обрабатывается на сервере и скоро станет доступно.'**
  String get media_viewer_video_processing;

  /// No description provided for @media_viewer_video_playback_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось воспроизвести видео.'**
  String get media_viewer_video_playback_failed;

  /// No description provided for @common_none.
  ///
  /// In ru, this message translates to:
  /// **'Нет'**
  String get common_none;

  /// No description provided for @group_member_role_admin.
  ///
  /// In ru, this message translates to:
  /// **'Администратор'**
  String get group_member_role_admin;

  /// No description provided for @group_member_role_worker.
  ///
  /// In ru, this message translates to:
  /// **'Участник'**
  String get group_member_role_worker;

  /// No description provided for @profile_no_photo_to_view.
  ///
  /// In ru, this message translates to:
  /// **'Нет фото профиля для просмотра.'**
  String get profile_no_photo_to_view;

  /// No description provided for @profile_chat_id_copied_toast.
  ///
  /// In ru, this message translates to:
  /// **'Идентификатор чата скопирован'**
  String get profile_chat_id_copied_toast;

  /// No description provided for @auth_register_error_open_link.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть ссылку'**
  String get auth_register_error_open_link;

  /// No description provided for @new_chat_error_self_profile_not_found.
  ///
  /// In ru, this message translates to:
  /// **'Не найден профиль в каталоге. Попробуйте выйти и войти снова.'**
  String get new_chat_error_self_profile_not_found;

  /// No description provided for @disappearing_messages_title.
  ///
  /// In ru, this message translates to:
  /// **'Исчезающие сообщения'**
  String get disappearing_messages_title;

  /// No description provided for @disappearing_messages_intro.
  ///
  /// In ru, this message translates to:
  /// **'Новые сообщения автоматически удаляются из базы после выбранного времени (от момента отправки). Уже отправленные не меняются.'**
  String get disappearing_messages_intro;

  /// No description provided for @disappearing_messages_admin_only.
  ///
  /// In ru, this message translates to:
  /// **'Только администраторы группы могут менять этот параметр. Сейчас: {summary}.'**
  String disappearing_messages_admin_only(Object summary);

  /// No description provided for @disappearing_messages_snackbar_off.
  ///
  /// In ru, this message translates to:
  /// **'Исчезающие сообщения выключены.'**
  String get disappearing_messages_snackbar_off;

  /// No description provided for @disappearing_messages_snackbar_updated.
  ///
  /// In ru, this message translates to:
  /// **'Таймер обновлён.'**
  String get disappearing_messages_snackbar_updated;

  /// No description provided for @disappearing_preset_off.
  ///
  /// In ru, this message translates to:
  /// **'Выключено'**
  String get disappearing_preset_off;

  /// No description provided for @disappearing_preset_1h.
  ///
  /// In ru, this message translates to:
  /// **'1 ч'**
  String get disappearing_preset_1h;

  /// No description provided for @disappearing_preset_24h.
  ///
  /// In ru, this message translates to:
  /// **'24 ч'**
  String get disappearing_preset_24h;

  /// No description provided for @disappearing_preset_7d.
  ///
  /// In ru, this message translates to:
  /// **'7 дн.'**
  String get disappearing_preset_7d;

  /// No description provided for @disappearing_preset_30d.
  ///
  /// In ru, this message translates to:
  /// **'30 дн.'**
  String get disappearing_preset_30d;

  /// No description provided for @disappearing_ttl_summary_off.
  ///
  /// In ru, this message translates to:
  /// **'Выкл'**
  String get disappearing_ttl_summary_off;

  /// No description provided for @disappearing_ttl_minutes.
  ///
  /// In ru, this message translates to:
  /// **'{count} мин'**
  String disappearing_ttl_minutes(Object count);

  /// No description provided for @disappearing_ttl_hours.
  ///
  /// In ru, this message translates to:
  /// **'{count} ч'**
  String disappearing_ttl_hours(Object count);

  /// No description provided for @disappearing_ttl_days.
  ///
  /// In ru, this message translates to:
  /// **'{count} дн.'**
  String disappearing_ttl_days(Object count);

  /// No description provided for @disappearing_ttl_weeks.
  ///
  /// In ru, this message translates to:
  /// **'{count} нед.'**
  String disappearing_ttl_weeks(Object count);

  /// No description provided for @conversation_profile_e2ee_on.
  ///
  /// In ru, this message translates to:
  /// **'Вкл'**
  String get conversation_profile_e2ee_on;

  /// No description provided for @conversation_profile_e2ee_off.
  ///
  /// In ru, this message translates to:
  /// **'Выкл'**
  String get conversation_profile_e2ee_off;

  /// No description provided for @conversation_profile_e2ee_subtitle_on.
  ///
  /// In ru, this message translates to:
  /// **'Сквозное шифрование включено. Нажмите для подробностей.'**
  String get conversation_profile_e2ee_subtitle_on;

  /// No description provided for @conversation_profile_e2ee_subtitle_off.
  ///
  /// In ru, this message translates to:
  /// **'Сквозное шифрование выключено. Нажмите, чтобы включить.'**
  String get conversation_profile_e2ee_subtitle_off;

  /// No description provided for @partner_profile_title_fallback_group.
  ///
  /// In ru, this message translates to:
  /// **'Групповой чат'**
  String get partner_profile_title_fallback_group;

  /// No description provided for @partner_profile_title_fallback_saved.
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get partner_profile_title_fallback_saved;

  /// No description provided for @partner_profile_title_fallback_chat.
  ///
  /// In ru, this message translates to:
  /// **'Чат'**
  String get partner_profile_title_fallback_chat;

  /// No description provided for @partner_profile_subtitle_group_member_count.
  ///
  /// In ru, this message translates to:
  /// **'{count} участников'**
  String partner_profile_subtitle_group_member_count(Object count);

  /// No description provided for @partner_profile_subtitle_saved_messages.
  ///
  /// In ru, this message translates to:
  /// **'Сообщения и заметки только для вас'**
  String get partner_profile_subtitle_saved_messages;

  /// No description provided for @partner_profile_error_cannot_contact_user.
  ///
  /// In ru, this message translates to:
  /// **'С этим пользователем нельзя связаться.'**
  String get partner_profile_error_cannot_contact_user;

  /// No description provided for @partner_profile_error_open_chat.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть чат: {error}'**
  String partner_profile_error_open_chat(Object error);

  /// No description provided for @partner_profile_call_peer_fallback.
  ///
  /// In ru, this message translates to:
  /// **'Собеседник'**
  String get partner_profile_call_peer_fallback;

  /// No description provided for @partner_profile_chat_not_created.
  ///
  /// In ru, this message translates to:
  /// **'Чат ещё не создан'**
  String get partner_profile_chat_not_created;

  /// No description provided for @partner_profile_notifications_muted.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления отключены'**
  String get partner_profile_notifications_muted;

  /// No description provided for @partner_profile_notifications_unmuted.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления включены'**
  String get partner_profile_notifications_unmuted;

  /// No description provided for @partner_profile_notifications_change_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось изменить уведомления'**
  String get partner_profile_notifications_change_failed;

  /// No description provided for @partner_profile_removed_from_contacts.
  ///
  /// In ru, this message translates to:
  /// **'Удалено из контактов'**
  String get partner_profile_removed_from_contacts;

  /// No description provided for @partner_profile_remove_contact_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось удалить из контактов'**
  String get partner_profile_remove_contact_failed;

  /// No description provided for @partner_profile_contact_sent.
  ///
  /// In ru, this message translates to:
  /// **'Контакт отправлен'**
  String get partner_profile_contact_sent;

  /// No description provided for @partner_profile_share_failed_copied.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть шаринг. Текст контакта скопирован.'**
  String get partner_profile_share_failed_copied;

  /// No description provided for @partner_profile_share_contact_header.
  ///
  /// In ru, this message translates to:
  /// **'Контакт в LighChat'**
  String get partner_profile_share_contact_header;

  /// No description provided for @partner_profile_share_avatar_line.
  ///
  /// In ru, this message translates to:
  /// **'Аватар: {url}'**
  String partner_profile_share_avatar_line(Object url);

  /// No description provided for @partner_profile_share_profile_line.
  ///
  /// In ru, this message translates to:
  /// **'Профиль: {url}'**
  String partner_profile_share_profile_line(Object url);

  /// No description provided for @partner_profile_share_contact_subject.
  ///
  /// In ru, this message translates to:
  /// **'Контакт LighChat: {name}'**
  String partner_profile_share_contact_subject(Object name);

  /// No description provided for @partner_profile_tooltip_back.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get partner_profile_tooltip_back;

  /// No description provided for @partner_profile_tooltip_close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get partner_profile_tooltip_close;

  /// No description provided for @partner_profile_edit_contact_short.
  ///
  /// In ru, this message translates to:
  /// **'Изм.'**
  String get partner_profile_edit_contact_short;

  /// No description provided for @partner_profile_tooltip_copy_chat_id.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать ID чата'**
  String get partner_profile_tooltip_copy_chat_id;

  /// No description provided for @partner_profile_action_chats.
  ///
  /// In ru, this message translates to:
  /// **'Чаты'**
  String get partner_profile_action_chats;

  /// No description provided for @partner_profile_action_voice_call.
  ///
  /// In ru, this message translates to:
  /// **'Звонок'**
  String get partner_profile_action_voice_call;

  /// No description provided for @partner_profile_action_video.
  ///
  /// In ru, this message translates to:
  /// **'Видео'**
  String get partner_profile_action_video;

  /// No description provided for @partner_profile_action_share.
  ///
  /// In ru, this message translates to:
  /// **'Поделиться'**
  String get partner_profile_action_share;

  /// No description provided for @partner_profile_action_notifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get partner_profile_action_notifications;

  /// No description provided for @partner_profile_menu_members.
  ///
  /// In ru, this message translates to:
  /// **'Участники'**
  String get partner_profile_menu_members;

  /// No description provided for @partner_profile_menu_edit_group.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать группу'**
  String get partner_profile_menu_edit_group;

  /// No description provided for @partner_profile_menu_media_links_files.
  ///
  /// In ru, this message translates to:
  /// **'Медиа, ссылки и файлы'**
  String get partner_profile_menu_media_links_files;

  /// No description provided for @partner_profile_menu_starred.
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get partner_profile_menu_starred;

  /// No description provided for @partner_profile_menu_threads.
  ///
  /// In ru, this message translates to:
  /// **'Обсуждения'**
  String get partner_profile_menu_threads;

  /// No description provided for @partner_profile_menu_games.
  ///
  /// In ru, this message translates to:
  /// **'Игры'**
  String get partner_profile_menu_games;

  /// No description provided for @partner_profile_menu_block.
  ///
  /// In ru, this message translates to:
  /// **'Заблокировать'**
  String get partner_profile_menu_block;

  /// No description provided for @partner_profile_menu_unblock.
  ///
  /// In ru, this message translates to:
  /// **'Разблокировать'**
  String get partner_profile_menu_unblock;

  /// No description provided for @partner_profile_menu_notifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get partner_profile_menu_notifications;

  /// No description provided for @partner_profile_menu_chat_theme.
  ///
  /// In ru, this message translates to:
  /// **'Тема чата'**
  String get partner_profile_menu_chat_theme;

  /// No description provided for @partner_profile_menu_advanced_privacy.
  ///
  /// In ru, this message translates to:
  /// **'Расширенная приватность чата'**
  String get partner_profile_menu_advanced_privacy;

  /// No description provided for @partner_profile_privacy_trailing_default.
  ///
  /// In ru, this message translates to:
  /// **'По умолчанию'**
  String get partner_profile_privacy_trailing_default;

  /// No description provided for @partner_profile_menu_encryption.
  ///
  /// In ru, this message translates to:
  /// **'Шифрование'**
  String get partner_profile_menu_encryption;

  /// No description provided for @partner_profile_no_common_groups.
  ///
  /// In ru, this message translates to:
  /// **'НЕТ ОБЩИХ ГРУПП'**
  String get partner_profile_no_common_groups;

  /// No description provided for @partner_profile_create_group_with.
  ///
  /// In ru, this message translates to:
  /// **'Создать группу с {name}'**
  String partner_profile_create_group_with(Object name);

  /// No description provided for @partner_profile_leave_group.
  ///
  /// In ru, this message translates to:
  /// **'Покинуть группу'**
  String get partner_profile_leave_group;

  /// No description provided for @partner_profile_contacts_and_data.
  ///
  /// In ru, this message translates to:
  /// **'Контакты и данные'**
  String get partner_profile_contacts_and_data;

  /// No description provided for @partner_profile_field_system_role.
  ///
  /// In ru, this message translates to:
  /// **'Роль в системе'**
  String get partner_profile_field_system_role;

  /// No description provided for @partner_profile_field_email.
  ///
  /// In ru, this message translates to:
  /// **'Электронная почта'**
  String get partner_profile_field_email;

  /// No description provided for @partner_profile_field_phone.
  ///
  /// In ru, this message translates to:
  /// **'Телефон'**
  String get partner_profile_field_phone;

  /// No description provided for @partner_profile_field_birthday.
  ///
  /// In ru, this message translates to:
  /// **'День рождения'**
  String get partner_profile_field_birthday;

  /// No description provided for @partner_profile_field_bio.
  ///
  /// In ru, this message translates to:
  /// **'О себе'**
  String get partner_profile_field_bio;

  /// No description provided for @partner_profile_add_to_contacts.
  ///
  /// In ru, this message translates to:
  /// **'Добавить в контакты'**
  String get partner_profile_add_to_contacts;

  /// No description provided for @partner_profile_remove_from_contacts.
  ///
  /// In ru, this message translates to:
  /// **'Удалить из контактов'**
  String get partner_profile_remove_from_contacts;

  /// No description provided for @thread_search_hint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск в обсуждении…'**
  String get thread_search_hint;

  /// No description provided for @thread_search_tooltip_clear.
  ///
  /// In ru, this message translates to:
  /// **'Очистить'**
  String get thread_search_tooltip_clear;

  /// No description provided for @thread_search_tooltip_search.
  ///
  /// In ru, this message translates to:
  /// **'Поиск'**
  String get thread_search_tooltip_search;

  /// No description provided for @thread_reply_count.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} ответ} few{{count} ответа} many{{count} ответов} other{{count} ответов}}'**
  String thread_reply_count(int count);

  /// No description provided for @thread_message_not_found.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение не найдено'**
  String get thread_message_not_found;

  /// No description provided for @thread_screen_title_fallback.
  ///
  /// In ru, this message translates to:
  /// **'Обсуждение'**
  String get thread_screen_title_fallback;

  /// No description provided for @thread_load_replies_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка ветки: {error}'**
  String thread_load_replies_error(Object error);

  /// No description provided for @chat_message_empty_placeholder.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение'**
  String get chat_message_empty_placeholder;

  /// No description provided for @chat_sender_you.
  ///
  /// In ru, this message translates to:
  /// **'Вы'**
  String get chat_sender_you;

  /// No description provided for @chat_clipboard_nothing_to_paste.
  ///
  /// In ru, this message translates to:
  /// **'Нечего вставлять из буфера'**
  String get chat_clipboard_nothing_to_paste;

  /// No description provided for @chat_clipboard_paste_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось вставить содержимое буфера: {error}'**
  String chat_clipboard_paste_failed(Object error);

  /// No description provided for @chat_send_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить: {error}'**
  String chat_send_failed(Object error);

  /// No description provided for @chat_send_video_circle_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить кружок: {error}'**
  String chat_send_video_circle_failed(Object error);

  /// No description provided for @chat_service_unavailable.
  ///
  /// In ru, this message translates to:
  /// **'Сервис недоступен'**
  String get chat_service_unavailable;

  /// No description provided for @chat_repository_unavailable.
  ///
  /// In ru, this message translates to:
  /// **'Сервис чата недоступен'**
  String get chat_repository_unavailable;

  /// No description provided for @chat_still_loading.
  ///
  /// In ru, this message translates to:
  /// **'Чат ещё загружается'**
  String get chat_still_loading;

  /// No description provided for @chat_no_participants.
  ///
  /// In ru, this message translates to:
  /// **'Нет участников чата'**
  String get chat_no_participants;

  /// No description provided for @chat_location_ios_geolocator_missing.
  ///
  /// In ru, this message translates to:
  /// **'Геолокация не подключена в iOS-сборке. В каталоге mobile/app/ios выполните pod install и пересоберите приложение.'**
  String get chat_location_ios_geolocator_missing;

  /// No description provided for @chat_location_services_disabled.
  ///
  /// In ru, this message translates to:
  /// **'Включите службу геолокации'**
  String get chat_location_services_disabled;

  /// No description provided for @chat_location_permission_denied.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступа к геолокации'**
  String get chat_location_permission_denied;

  /// No description provided for @chat_location_send_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить геолокацию: {error}'**
  String chat_location_send_failed(Object error);

  /// No description provided for @chat_poll_send_timeout.
  ///
  /// In ru, this message translates to:
  /// **'Опрос не отправлен: таймаут'**
  String get chat_poll_send_timeout;

  /// No description provided for @chat_poll_send_firebase.
  ///
  /// In ru, this message translates to:
  /// **'Опрос не отправлен (Firestore): {details}'**
  String chat_poll_send_firebase(Object details);

  /// No description provided for @chat_poll_send_known_error.
  ///
  /// In ru, this message translates to:
  /// **'Опрос не отправлен: {details}'**
  String chat_poll_send_known_error(Object details);

  /// No description provided for @chat_poll_send_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить опрос: {error}'**
  String chat_poll_send_failed(Object error);

  /// No description provided for @chat_delete_action_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось удалить: {error}'**
  String chat_delete_action_failed(Object error);

  /// No description provided for @chat_media_transcode_retry_started.
  ///
  /// In ru, this message translates to:
  /// **'Повторная обработка запущена'**
  String get chat_media_transcode_retry_started;

  /// No description provided for @chat_media_transcode_retry_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось запустить обработку: {error}'**
  String chat_media_transcode_retry_failed(Object error);

  /// No description provided for @chat_parent_load_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка: {error}'**
  String chat_parent_load_error(Object error);

  /// No description provided for @chat_message_not_found_in_loaded_history.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение не найдено в загруженной истории'**
  String get chat_message_not_found_in_loaded_history;

  /// No description provided for @chat_finish_editing_first.
  ///
  /// In ru, this message translates to:
  /// **'Сначала завершите редактирование'**
  String get chat_finish_editing_first;

  /// No description provided for @chat_send_voice_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить голосовое: {error}'**
  String chat_send_voice_failed(Object error);

  /// No description provided for @chat_starred_removed.
  ///
  /// In ru, this message translates to:
  /// **'Удалено из избранного'**
  String get chat_starred_removed;

  /// No description provided for @chat_starred_added.
  ///
  /// In ru, this message translates to:
  /// **'Добавлено в избранное'**
  String get chat_starred_added;

  /// No description provided for @chat_starred_toggle_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось изменить избранное: {error}'**
  String chat_starred_toggle_failed(Object error);

  /// No description provided for @chat_reaction_toggle_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось поставить реакцию: {error}'**
  String chat_reaction_toggle_failed(Object error);

  /// No description provided for @chat_emoji_burst_sync_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось синхронизировать эффект эмодзи: {error}'**
  String chat_emoji_burst_sync_failed(Object error);

  /// No description provided for @chat_pin_already_pinned.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение уже закреплено'**
  String get chat_pin_already_pinned;

  /// No description provided for @chat_pin_limit_reached.
  ///
  /// In ru, this message translates to:
  /// **'Лимит закреплённых ({count})'**
  String chat_pin_limit_reached(int count);

  /// No description provided for @chat_pin_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось закрепить: {error}'**
  String chat_pin_failed(Object error);

  /// No description provided for @chat_unpin_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открепить: {error}'**
  String chat_unpin_failed(Object error);

  /// No description provided for @chat_text_copied.
  ///
  /// In ru, this message translates to:
  /// **'Текст скопирован'**
  String get chat_text_copied;

  /// No description provided for @chat_edit_attachments_not_allowed.
  ///
  /// In ru, this message translates to:
  /// **'При редактировании вложения недоступны'**
  String get chat_edit_attachments_not_allowed;

  /// No description provided for @chat_edit_text_empty.
  ///
  /// In ru, this message translates to:
  /// **'Текст не может быть пустым'**
  String get chat_edit_text_empty;

  /// No description provided for @chat_e2ee_unavailable.
  ///
  /// In ru, this message translates to:
  /// **'Шифрование недоступно: {code}'**
  String chat_e2ee_unavailable(Object code);

  /// No description provided for @chat_save_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить: {error}'**
  String chat_save_failed(Object error);

  /// No description provided for @chat_load_messages_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки сообщений: {error}'**
  String chat_load_messages_error(Object error);

  /// No description provided for @chat_conversation_error.
  ///
  /// In ru, this message translates to:
  /// **'Conversation error: {error}'**
  String chat_conversation_error(Object error);

  /// No description provided for @chat_auth_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка авторизации: {error}'**
  String chat_auth_error(Object error);

  /// No description provided for @chat_poll_label.
  ///
  /// In ru, this message translates to:
  /// **'Опрос'**
  String get chat_poll_label;

  /// No description provided for @chat_location_label.
  ///
  /// In ru, this message translates to:
  /// **'Локация'**
  String get chat_location_label;

  /// No description provided for @chat_attachment_label.
  ///
  /// In ru, this message translates to:
  /// **'Вложение'**
  String get chat_attachment_label;

  /// No description provided for @chat_media_pick_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выбрать медиа: {error}'**
  String chat_media_pick_failed(Object error);

  /// No description provided for @chat_file_pick_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выбрать файл: {error}'**
  String chat_file_pick_failed(Object error);

  /// No description provided for @chat_call_ongoing_video.
  ///
  /// In ru, this message translates to:
  /// **'Идёт видеозвонок'**
  String get chat_call_ongoing_video;

  /// No description provided for @chat_call_ongoing_audio.
  ///
  /// In ru, this message translates to:
  /// **'Идёт аудиозвонок'**
  String get chat_call_ongoing_audio;

  /// No description provided for @chat_call_incoming_video.
  ///
  /// In ru, this message translates to:
  /// **'Входящий видеозвонок'**
  String get chat_call_incoming_video;

  /// No description provided for @chat_call_incoming_audio.
  ///
  /// In ru, this message translates to:
  /// **'Входящий аудиозвонок'**
  String get chat_call_incoming_audio;

  /// No description provided for @message_menu_action_reply.
  ///
  /// In ru, this message translates to:
  /// **'Ответить'**
  String get message_menu_action_reply;

  /// No description provided for @message_menu_action_thread.
  ///
  /// In ru, this message translates to:
  /// **'Обсудить'**
  String get message_menu_action_thread;

  /// No description provided for @message_menu_action_copy.
  ///
  /// In ru, this message translates to:
  /// **'Копировать'**
  String get message_menu_action_copy;

  /// No description provided for @message_menu_action_edit.
  ///
  /// In ru, this message translates to:
  /// **'Изменить'**
  String get message_menu_action_edit;

  /// No description provided for @message_menu_action_pin.
  ///
  /// In ru, this message translates to:
  /// **'Закрепить'**
  String get message_menu_action_pin;

  /// No description provided for @message_menu_action_star_add.
  ///
  /// In ru, this message translates to:
  /// **'Добавить в избранное'**
  String get message_menu_action_star_add;

  /// No description provided for @message_menu_action_star_remove.
  ///
  /// In ru, this message translates to:
  /// **'Убрать из избранного'**
  String get message_menu_action_star_remove;

  /// No description provided for @message_menu_action_forward.
  ///
  /// In ru, this message translates to:
  /// **'Переслать'**
  String get message_menu_action_forward;

  /// No description provided for @message_menu_action_select.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать'**
  String get message_menu_action_select;

  /// No description provided for @message_menu_action_delete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get message_menu_action_delete;

  /// No description provided for @message_menu_initiator_deleted.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение удалено'**
  String get message_menu_initiator_deleted;

  /// No description provided for @message_menu_header_sent.
  ///
  /// In ru, this message translates to:
  /// **'ОТПРАВЛЕНО:'**
  String get message_menu_header_sent;

  /// No description provided for @message_menu_header_read.
  ///
  /// In ru, this message translates to:
  /// **'ПРОЧИТАНО:'**
  String get message_menu_header_read;

  /// No description provided for @message_menu_header_expire_at.
  ///
  /// In ru, this message translates to:
  /// **'ИСЧЕЗНЕТ:'**
  String get message_menu_header_expire_at;

  /// No description provided for @chat_header_search_hint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск сообщений…'**
  String get chat_header_search_hint;

  /// No description provided for @chat_header_tooltip_threads.
  ///
  /// In ru, this message translates to:
  /// **'Обсуждения'**
  String get chat_header_tooltip_threads;

  /// No description provided for @chat_header_tooltip_search.
  ///
  /// In ru, this message translates to:
  /// **'Поиск'**
  String get chat_header_tooltip_search;

  /// No description provided for @chat_header_tooltip_video_call.
  ///
  /// In ru, this message translates to:
  /// **'Видеозвонок'**
  String get chat_header_tooltip_video_call;

  /// No description provided for @chat_header_tooltip_audio_call.
  ///
  /// In ru, this message translates to:
  /// **'Аудиозвонок'**
  String get chat_header_tooltip_audio_call;

  /// No description provided for @conversation_games_title.
  ///
  /// In ru, this message translates to:
  /// **'Игры'**
  String get conversation_games_title;

  /// No description provided for @conversation_games_durak.
  ///
  /// In ru, this message translates to:
  /// **'Дурак'**
  String get conversation_games_durak;

  /// No description provided for @conversation_games_durak_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Создать лобби'**
  String get conversation_games_durak_subtitle;

  /// No description provided for @conversation_game_lobby_title.
  ///
  /// In ru, this message translates to:
  /// **'Лобби'**
  String get conversation_game_lobby_title;

  /// No description provided for @conversation_game_lobby_not_found.
  ///
  /// In ru, this message translates to:
  /// **'Игра не найдена'**
  String get conversation_game_lobby_not_found;

  /// No description provided for @conversation_game_lobby_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка: {error}'**
  String conversation_game_lobby_error(Object error);

  /// No description provided for @conversation_game_lobby_create_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось создать игру: {error}'**
  String conversation_game_lobby_create_failed(Object error);

  /// No description provided for @conversation_game_lobby_game_id.
  ///
  /// In ru, this message translates to:
  /// **'ID: {id}'**
  String conversation_game_lobby_game_id(Object id);

  /// No description provided for @conversation_game_lobby_status.
  ///
  /// In ru, this message translates to:
  /// **'Статус: {status}'**
  String conversation_game_lobby_status(Object status);

  /// No description provided for @conversation_game_lobby_players.
  ///
  /// In ru, this message translates to:
  /// **'Игроки: {count}/{max}'**
  String conversation_game_lobby_players(Object count, Object max);

  /// No description provided for @conversation_game_lobby_join.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get conversation_game_lobby_join;

  /// No description provided for @conversation_game_lobby_start.
  ///
  /// In ru, this message translates to:
  /// **'Начать'**
  String get conversation_game_lobby_start;

  /// No description provided for @conversation_game_lobby_join_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось войти: {error}'**
  String conversation_game_lobby_join_failed(Object error);

  /// No description provided for @conversation_game_lobby_start_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось начать игру: {error}'**
  String conversation_game_lobby_start_failed(Object error);

  /// No description provided for @conversation_game_send_test_move.
  ///
  /// In ru, this message translates to:
  /// **'Тестовый ход'**
  String get conversation_game_send_test_move;

  /// No description provided for @conversation_game_move_failed.
  ///
  /// In ru, this message translates to:
  /// **'Ход не принят: {error}'**
  String conversation_game_move_failed(Object error);

  /// No description provided for @conversation_durak_table_title.
  ///
  /// In ru, this message translates to:
  /// **'Стол'**
  String get conversation_durak_table_title;

  /// No description provided for @conversation_durak_hand_title.
  ///
  /// In ru, this message translates to:
  /// **'Рука'**
  String get conversation_durak_hand_title;

  /// No description provided for @conversation_durak_role_attacker.
  ///
  /// In ru, this message translates to:
  /// **'Атакуете'**
  String get conversation_durak_role_attacker;

  /// No description provided for @conversation_durak_role_defender.
  ///
  /// In ru, this message translates to:
  /// **'Защищаетесь'**
  String get conversation_durak_role_defender;

  /// No description provided for @conversation_durak_role_thrower.
  ///
  /// In ru, this message translates to:
  /// **'Подкидываете'**
  String get conversation_durak_role_thrower;

  /// No description provided for @conversation_durak_action_attack.
  ///
  /// In ru, this message translates to:
  /// **'Атаковать'**
  String get conversation_durak_action_attack;

  /// No description provided for @conversation_durak_action_defend.
  ///
  /// In ru, this message translates to:
  /// **'Отбить'**
  String get conversation_durak_action_defend;

  /// No description provided for @conversation_durak_action_take.
  ///
  /// In ru, this message translates to:
  /// **'Взять'**
  String get conversation_durak_action_take;

  /// No description provided for @conversation_durak_action_beat.
  ///
  /// In ru, this message translates to:
  /// **'Бито'**
  String get conversation_durak_action_beat;

  /// No description provided for @conversation_durak_action_transfer.
  ///
  /// In ru, this message translates to:
  /// **'Перевести'**
  String get conversation_durak_action_transfer;

  /// No description provided for @conversation_durak_action_pass.
  ///
  /// In ru, this message translates to:
  /// **'Пас'**
  String get conversation_durak_action_pass;

  /// No description provided for @conversation_durak_badge_taking.
  ///
  /// In ru, this message translates to:
  /// **'Беру'**
  String get conversation_durak_badge_taking;

  /// No description provided for @conversation_durak_game_finished_title.
  ///
  /// In ru, this message translates to:
  /// **'Игра завершена'**
  String get conversation_durak_game_finished_title;

  /// No description provided for @conversation_durak_game_finished_no_loser.
  ///
  /// In ru, this message translates to:
  /// **'В этот раз без проигравшего.'**
  String get conversation_durak_game_finished_no_loser;

  /// No description provided for @conversation_durak_game_finished_loser.
  ///
  /// In ru, this message translates to:
  /// **'Проиграл: {uid}'**
  String conversation_durak_game_finished_loser(Object uid);

  /// No description provided for @conversation_durak_game_finished_winners.
  ///
  /// In ru, this message translates to:
  /// **'Победили: {uids}'**
  String conversation_durak_game_finished_winners(Object uids);

  /// No description provided for @conversation_durak_drop_zone.
  ///
  /// In ru, this message translates to:
  /// **'Перетащи карту сюда, чтобы сыграть'**
  String get conversation_durak_drop_zone;

  /// No description provided for @durak_settings_mode.
  ///
  /// In ru, this message translates to:
  /// **'Режим'**
  String get durak_settings_mode;

  /// No description provided for @durak_mode_podkidnoy.
  ///
  /// In ru, this message translates to:
  /// **'Подкидной'**
  String get durak_mode_podkidnoy;

  /// No description provided for @durak_mode_perevodnoy.
  ///
  /// In ru, this message translates to:
  /// **'Переводной'**
  String get durak_mode_perevodnoy;

  /// No description provided for @durak_settings_max_players.
  ///
  /// In ru, this message translates to:
  /// **'Игроков'**
  String get durak_settings_max_players;

  /// No description provided for @durak_settings_deck.
  ///
  /// In ru, this message translates to:
  /// **'Колода'**
  String get durak_settings_deck;

  /// No description provided for @durak_deck_36.
  ///
  /// In ru, this message translates to:
  /// **'36 карт'**
  String get durak_deck_36;

  /// No description provided for @durak_deck_52.
  ///
  /// In ru, this message translates to:
  /// **'52 карты'**
  String get durak_deck_52;

  /// No description provided for @durak_settings_with_jokers.
  ///
  /// In ru, this message translates to:
  /// **'Джокеры'**
  String get durak_settings_with_jokers;

  /// No description provided for @durak_settings_turn_timer.
  ///
  /// In ru, this message translates to:
  /// **'Таймер хода'**
  String get durak_settings_turn_timer;

  /// No description provided for @durak_turn_timer_off.
  ///
  /// In ru, this message translates to:
  /// **'Выкл'**
  String get durak_turn_timer_off;

  /// No description provided for @durak_settings_throw_in_policy.
  ///
  /// In ru, this message translates to:
  /// **'Кто может подкидывать'**
  String get durak_settings_throw_in_policy;

  /// No description provided for @durak_throw_in_policy_all.
  ///
  /// In ru, this message translates to:
  /// **'Все (кроме защитника)'**
  String get durak_throw_in_policy_all;

  /// No description provided for @durak_throw_in_policy_neighbors.
  ///
  /// In ru, this message translates to:
  /// **'Только соседи защитника'**
  String get durak_throw_in_policy_neighbors;

  /// No description provided for @durak_settings_shuler.
  ///
  /// In ru, this message translates to:
  /// **'Режим шулера'**
  String get durak_settings_shuler;

  /// No description provided for @durak_settings_shuler_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Разрешает нелегальные ходы, пока кто-то не крикнет «Фолл!»'**
  String get durak_settings_shuler_subtitle;

  /// No description provided for @conversation_durak_action_foul.
  ///
  /// In ru, this message translates to:
  /// **'Фолл!'**
  String get conversation_durak_action_foul;

  /// No description provided for @conversation_durak_action_resolve.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить «Бито»'**
  String get conversation_durak_action_resolve;

  /// No description provided for @conversation_durak_foul_toast.
  ///
  /// In ru, this message translates to:
  /// **'Фолл! Шулер наказан.'**
  String get conversation_durak_foul_toast;

  /// No description provided for @durak_phase_prefix.
  ///
  /// In ru, this message translates to:
  /// **'Фаза'**
  String get durak_phase_prefix;

  /// No description provided for @durak_phase_attack.
  ///
  /// In ru, this message translates to:
  /// **'Атака'**
  String get durak_phase_attack;

  /// No description provided for @durak_phase_defense.
  ///
  /// In ru, this message translates to:
  /// **'Защита'**
  String get durak_phase_defense;

  /// No description provided for @durak_phase_throw_in.
  ///
  /// In ru, this message translates to:
  /// **'Подкид'**
  String get durak_phase_throw_in;

  /// No description provided for @durak_phase_resolution.
  ///
  /// In ru, this message translates to:
  /// **'Розыгрыш'**
  String get durak_phase_resolution;

  /// No description provided for @durak_phase_finished.
  ///
  /// In ru, this message translates to:
  /// **'Завершено'**
  String get durak_phase_finished;

  /// No description provided for @durak_phase_pending_foul.
  ///
  /// In ru, this message translates to:
  /// **'Ожидание фолла после «Бито»'**
  String get durak_phase_pending_foul;

  /// No description provided for @durak_phase_pending_foul_hint_attacker.
  ///
  /// In ru, this message translates to:
  /// **'Ждём фолл. Если никто не нажмёт — подтверди «Бито».'**
  String get durak_phase_pending_foul_hint_attacker;

  /// No description provided for @durak_phase_pending_foul_hint_other.
  ///
  /// In ru, this message translates to:
  /// **'Ждём фолл. Нажми «Фолл!», если заметил шулерство.'**
  String get durak_phase_pending_foul_hint_other;

  /// No description provided for @durak_phase_hint_can_throw_in.
  ///
  /// In ru, this message translates to:
  /// **'Можно подкидывать'**
  String get durak_phase_hint_can_throw_in;

  /// No description provided for @durak_phase_hint_wait.
  ///
  /// In ru, this message translates to:
  /// **'Ждите свой ход'**
  String get durak_phase_hint_wait;

  /// No description provided for @durak_now_throwing_in.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас подкидывает: {name}'**
  String durak_now_throwing_in(Object name);

  /// No description provided for @chat_selection_selected_count.
  ///
  /// In ru, this message translates to:
  /// **'{count} выбрано'**
  String chat_selection_selected_count(int count);

  /// No description provided for @chat_selection_tooltip_forward.
  ///
  /// In ru, this message translates to:
  /// **'Переслать'**
  String get chat_selection_tooltip_forward;

  /// No description provided for @chat_selection_tooltip_delete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get chat_selection_tooltip_delete;

  /// No description provided for @chat_composer_hint_message.
  ///
  /// In ru, this message translates to:
  /// **'Введите сообщение…'**
  String get chat_composer_hint_message;

  /// No description provided for @chat_composer_tooltip_stickers.
  ///
  /// In ru, this message translates to:
  /// **'Стикеры'**
  String get chat_composer_tooltip_stickers;

  /// No description provided for @chat_composer_tooltip_attachments.
  ///
  /// In ru, this message translates to:
  /// **'Вложения'**
  String get chat_composer_tooltip_attachments;

  /// No description provided for @chat_list_unread_separator.
  ///
  /// In ru, this message translates to:
  /// **'Непрочитанные сообщения'**
  String get chat_list_unread_separator;

  /// No description provided for @chat_e2ee_decrypt_failed_open_devices.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось расшифровать. Откройте Настройки → Устройства'**
  String get chat_e2ee_decrypt_failed_open_devices;

  /// No description provided for @chat_e2ee_encrypted_message_placeholder.
  ///
  /// In ru, this message translates to:
  /// **'Зашифрованное сообщение'**
  String get chat_e2ee_encrypted_message_placeholder;

  /// No description provided for @chat_forwarded_from.
  ///
  /// In ru, this message translates to:
  /// **'Переслано от {name}'**
  String chat_forwarded_from(Object name);

  /// No description provided for @chat_outbox_retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get chat_outbox_retry;

  /// No description provided for @chat_outbox_remove.
  ///
  /// In ru, this message translates to:
  /// **'Убрать'**
  String get chat_outbox_remove;

  /// No description provided for @chat_outbox_cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отменить'**
  String get chat_outbox_cancel;

  /// No description provided for @chat_message_edited_badge_short.
  ///
  /// In ru, this message translates to:
  /// **'изм.'**
  String get chat_message_edited_badge_short;

  /// No description provided for @register_error_enter_name.
  ///
  /// In ru, this message translates to:
  /// **'Введите имя.'**
  String get register_error_enter_name;

  /// No description provided for @register_error_enter_username.
  ///
  /// In ru, this message translates to:
  /// **'Введите логин.'**
  String get register_error_enter_username;

  /// No description provided for @register_error_enter_phone.
  ///
  /// In ru, this message translates to:
  /// **'Введите номер телефона.'**
  String get register_error_enter_phone;

  /// No description provided for @register_error_invalid_phone.
  ///
  /// In ru, this message translates to:
  /// **'Введите корректный номер телефона.'**
  String get register_error_invalid_phone;

  /// No description provided for @register_error_enter_email.
  ///
  /// In ru, this message translates to:
  /// **'Введите email.'**
  String get register_error_enter_email;

  /// No description provided for @register_error_enter_password.
  ///
  /// In ru, this message translates to:
  /// **'Введите пароль.'**
  String get register_error_enter_password;

  /// No description provided for @register_error_repeat_password.
  ///
  /// In ru, this message translates to:
  /// **'Повторите пароль.'**
  String get register_error_repeat_password;

  /// No description provided for @register_error_dob_format.
  ///
  /// In ru, this message translates to:
  /// **'Укажите дату рождения в формате дд.мм.гггг'**
  String get register_error_dob_format;

  /// No description provided for @register_error_accept_privacy_policy.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите согласие с политикой конфиденциальности'**
  String get register_error_accept_privacy_policy;

  /// No description provided for @register_privacy_required.
  ///
  /// In ru, this message translates to:
  /// **'Требуется согласие с политикой конфиденциальности'**
  String get register_privacy_required;

  /// No description provided for @register_label_name.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get register_label_name;

  /// No description provided for @register_hint_name.
  ///
  /// In ru, this message translates to:
  /// **'Введите имя'**
  String get register_hint_name;

  /// No description provided for @register_label_username.
  ///
  /// In ru, this message translates to:
  /// **'Логин'**
  String get register_label_username;

  /// No description provided for @register_hint_username.
  ///
  /// In ru, this message translates to:
  /// **'Введите логин'**
  String get register_hint_username;

  /// No description provided for @register_label_phone.
  ///
  /// In ru, this message translates to:
  /// **'Телефон'**
  String get register_label_phone;

  /// No description provided for @register_hint_choose_country.
  ///
  /// In ru, this message translates to:
  /// **'Выберите страну'**
  String get register_hint_choose_country;

  /// No description provided for @register_label_email.
  ///
  /// In ru, this message translates to:
  /// **'Email'**
  String get register_label_email;

  /// No description provided for @register_hint_email.
  ///
  /// In ru, this message translates to:
  /// **'Введите email'**
  String get register_hint_email;

  /// No description provided for @register_label_password.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get register_label_password;

  /// No description provided for @register_hint_password.
  ///
  /// In ru, this message translates to:
  /// **'Введите пароль'**
  String get register_hint_password;

  /// No description provided for @register_label_confirm_password.
  ///
  /// In ru, this message translates to:
  /// **'Повтор пароля'**
  String get register_label_confirm_password;

  /// No description provided for @register_hint_confirm_password.
  ///
  /// In ru, this message translates to:
  /// **'Повторите пароль'**
  String get register_hint_confirm_password;

  /// No description provided for @register_label_dob.
  ///
  /// In ru, this message translates to:
  /// **'Дата рождения'**
  String get register_label_dob;

  /// No description provided for @register_hint_dob.
  ///
  /// In ru, this message translates to:
  /// **'дд.мм.гггг'**
  String get register_hint_dob;

  /// No description provided for @register_label_bio.
  ///
  /// In ru, this message translates to:
  /// **'О себе'**
  String get register_label_bio;

  /// No description provided for @register_hint_bio.
  ///
  /// In ru, this message translates to:
  /// **'Расскажите о себе...'**
  String get register_hint_bio;

  /// No description provided for @register_privacy_prefix.
  ///
  /// In ru, this message translates to:
  /// **'Я принимаю '**
  String get register_privacy_prefix;

  /// No description provided for @register_privacy_link_text.
  ///
  /// In ru, this message translates to:
  /// **'Согласия на обработку персональных данных'**
  String get register_privacy_link_text;

  /// No description provided for @register_privacy_and.
  ///
  /// In ru, this message translates to:
  /// **' и '**
  String get register_privacy_and;

  /// No description provided for @register_terms_link_text.
  ///
  /// In ru, this message translates to:
  /// **'Пользовательское соглашение политики конфиденциальности'**
  String get register_terms_link_text;

  /// No description provided for @register_button_create_account.
  ///
  /// In ru, this message translates to:
  /// **'Создать аккаунт'**
  String get register_button_create_account;

  /// No description provided for @register_country_search_hint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск страны или кода'**
  String get register_country_search_hint;

  /// No description provided for @register_date_picker_help.
  ///
  /// In ru, this message translates to:
  /// **'Дата рождения'**
  String get register_date_picker_help;

  /// No description provided for @register_date_picker_cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get register_date_picker_cancel;

  /// No description provided for @register_date_picker_confirm.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать'**
  String get register_date_picker_confirm;

  /// No description provided for @register_pick_avatar_title.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать аватар'**
  String get register_pick_avatar_title;

  /// No description provided for @edit_group_title.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать группу'**
  String get edit_group_title;

  /// No description provided for @edit_group_save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get edit_group_save;

  /// No description provided for @edit_group_cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get edit_group_cancel;

  /// No description provided for @edit_group_name_label.
  ///
  /// In ru, this message translates to:
  /// **'Название группы'**
  String get edit_group_name_label;

  /// No description provided for @edit_group_name_hint.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get edit_group_name_hint;

  /// No description provided for @edit_group_description_label.
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get edit_group_description_label;

  /// No description provided for @edit_group_description_hint.
  ///
  /// In ru, this message translates to:
  /// **'Необязательно'**
  String get edit_group_description_hint;

  /// No description provided for @edit_group_pick_photo_tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите, чтобы выбрать фото группы. Удерживайте, чтобы убрать.'**
  String get edit_group_pick_photo_tooltip;

  /// No description provided for @edit_group_error_name_required.
  ///
  /// In ru, this message translates to:
  /// **'Пожалуйста, введите название группы.'**
  String get edit_group_error_name_required;

  /// No description provided for @edit_group_error_save_failed.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка при сохранении группы'**
  String get edit_group_error_save_failed;

  /// No description provided for @edit_group_error_not_found.
  ///
  /// In ru, this message translates to:
  /// **'Группа не найдена'**
  String get edit_group_error_not_found;

  /// No description provided for @edit_group_error_permission_denied.
  ///
  /// In ru, this message translates to:
  /// **'У вас нет прав для редактирования этой группы'**
  String get edit_group_error_permission_denied;

  /// No description provided for @edit_group_success.
  ///
  /// In ru, this message translates to:
  /// **'Группа обновлена'**
  String get edit_group_success;

  /// No description provided for @edit_group_privacy_section.
  ///
  /// In ru, this message translates to:
  /// **'КОНФИДЕНЦИАЛЬНОСТЬ'**
  String get edit_group_privacy_section;

  /// No description provided for @edit_group_privacy_forwarding.
  ///
  /// In ru, this message translates to:
  /// **'Пересылка сообщений'**
  String get edit_group_privacy_forwarding;

  /// No description provided for @edit_group_privacy_forwarding_desc.
  ///
  /// In ru, this message translates to:
  /// **'Разрешить участникам пересылать сообщения из этой группы.'**
  String get edit_group_privacy_forwarding_desc;

  /// No description provided for @edit_group_privacy_screenshots.
  ///
  /// In ru, this message translates to:
  /// **'Скриншоты'**
  String get edit_group_privacy_screenshots;

  /// No description provided for @edit_group_privacy_screenshots_desc.
  ///
  /// In ru, this message translates to:
  /// **'Разрешить скриншоты внутри группы (ограничение зависит от платформы).'**
  String get edit_group_privacy_screenshots_desc;

  /// No description provided for @edit_group_privacy_copy.
  ///
  /// In ru, this message translates to:
  /// **'Копирование текста'**
  String get edit_group_privacy_copy;

  /// No description provided for @edit_group_privacy_copy_desc.
  ///
  /// In ru, this message translates to:
  /// **'Разрешить копирование текста сообщений.'**
  String get edit_group_privacy_copy_desc;

  /// No description provided for @edit_group_privacy_save_media.
  ///
  /// In ru, this message translates to:
  /// **'Сохранение медиа'**
  String get edit_group_privacy_save_media;

  /// No description provided for @edit_group_privacy_save_media_desc.
  ///
  /// In ru, this message translates to:
  /// **'Разрешить сохранять фото и видео на устройство.'**
  String get edit_group_privacy_save_media_desc;

  /// No description provided for @edit_group_privacy_share_media.
  ///
  /// In ru, this message translates to:
  /// **'Поделиться медиа'**
  String get edit_group_privacy_share_media;

  /// No description provided for @edit_group_privacy_share_media_desc.
  ///
  /// In ru, this message translates to:
  /// **'Разрешить делиться медиафайлами вне приложения.'**
  String get edit_group_privacy_share_media_desc;
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
