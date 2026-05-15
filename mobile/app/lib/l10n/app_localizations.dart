import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_id.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uz.dart';

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
    Locale('es'),
    Locale('es', 'MX'),
    Locale('id'),
    Locale('kk'),
    Locale('pt'),
    Locale('pt', 'BR'),
    Locale('ru'),
    Locale('tr'),
    Locale('uz'),
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

  /// No description provided for @account_menu_features.
  ///
  /// In ru, this message translates to:
  /// **'Возможности'**
  String get account_menu_features;

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

  /// No description provided for @account_menu_devices.
  ///
  /// In ru, this message translates to:
  /// **'Устройства'**
  String get account_menu_devices;

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
  /// **'Лимит кэша: {gb} ГБ'**
  String storage_settings_budget_label(Object gb);

  /// No description provided for @storage_unit_gb.
  ///
  /// In ru, this message translates to:
  /// **'ГБ'**
  String get storage_unit_gb;

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

  /// No description provided for @storage_category_chat_images.
  ///
  /// In ru, this message translates to:
  /// **'Фото в чатах'**
  String get storage_category_chat_images;

  /// No description provided for @storage_category_chat_images_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Кэшированные фотографии и стикеры из открытых чатов.'**
  String get storage_category_chat_images_subtitle;

  /// No description provided for @storage_category_stickers_gifs_emoji.
  ///
  /// In ru, this message translates to:
  /// **'Стикеры, GIF, эмодзи'**
  String get storage_category_stickers_gifs_emoji;

  /// No description provided for @storage_category_stickers_gifs_emoji_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Кэш недавних стикеров, GIPHY (gifs/stickers/emoji) и анимированных эмодзи.'**
  String get storage_category_stickers_gifs_emoji_subtitle;

  /// No description provided for @storage_category_network_images.
  ///
  /// In ru, this message translates to:
  /// **'Кэш сетевых картинок'**
  String get storage_category_network_images;

  /// No description provided for @storage_category_network_images_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Аватары, превью и прочие изображения, скачанные из сети (libCachedImageData).'**
  String get storage_category_network_images_subtitle;

  /// No description provided for @storage_media_type_video.
  ///
  /// In ru, this message translates to:
  /// **'Видео'**
  String get storage_media_type_video;

  /// No description provided for @storage_media_type_photo.
  ///
  /// In ru, this message translates to:
  /// **'Фотографии'**
  String get storage_media_type_photo;

  /// No description provided for @storage_media_type_audio.
  ///
  /// In ru, this message translates to:
  /// **'Аудио'**
  String get storage_media_type_audio;

  /// No description provided for @storage_media_type_files.
  ///
  /// In ru, this message translates to:
  /// **'Файлы'**
  String get storage_media_type_files;

  /// No description provided for @storage_media_type_other.
  ///
  /// In ru, this message translates to:
  /// **'Другое'**
  String get storage_media_type_other;

  /// No description provided for @storage_settings_device_usage.
  ///
  /// In ru, this message translates to:
  /// **'Занимает {pct}% от лимита кэша'**
  String storage_settings_device_usage(Object pct);

  /// No description provided for @storage_settings_clear_all_hint.
  ///
  /// In ru, this message translates to:
  /// **'Все медиа останутся в облаке. При необходимости вы сможете загрузить их снова.'**
  String get storage_settings_clear_all_hint;

  /// No description provided for @storage_settings_categories_title.
  ///
  /// In ru, this message translates to:
  /// **'По категориям'**
  String get storage_settings_categories_title;

  /// No description provided for @storage_settings_clear_category_title.
  ///
  /// In ru, this message translates to:
  /// **'Очистить «{category}»?'**
  String storage_settings_clear_category_title(String category);

  /// No description provided for @storage_settings_clear_category_body.
  ///
  /// In ru, this message translates to:
  /// **'Будет освобождено около {size}. Действие нельзя отменить.'**
  String storage_settings_clear_category_body(String size);

  /// No description provided for @storage_auto_delete_title.
  ///
  /// In ru, this message translates to:
  /// **'Автоудаление кэшированных медиа'**
  String get storage_auto_delete_title;

  /// No description provided for @storage_auto_delete_personal.
  ///
  /// In ru, this message translates to:
  /// **'Личные чаты'**
  String get storage_auto_delete_personal;

  /// No description provided for @storage_auto_delete_groups.
  ///
  /// In ru, this message translates to:
  /// **'Группы'**
  String get storage_auto_delete_groups;

  /// No description provided for @storage_auto_delete_never.
  ///
  /// In ru, this message translates to:
  /// **'Никогда'**
  String get storage_auto_delete_never;

  /// No description provided for @storage_auto_delete_3_days.
  ///
  /// In ru, this message translates to:
  /// **'3 дня'**
  String get storage_auto_delete_3_days;

  /// No description provided for @storage_auto_delete_1_week.
  ///
  /// In ru, this message translates to:
  /// **'1 нед.'**
  String get storage_auto_delete_1_week;

  /// No description provided for @storage_auto_delete_1_month.
  ///
  /// In ru, this message translates to:
  /// **'1 месяц'**
  String get storage_auto_delete_1_month;

  /// No description provided for @storage_auto_delete_3_months.
  ///
  /// In ru, this message translates to:
  /// **'3 месяца'**
  String get storage_auto_delete_3_months;

  /// No description provided for @storage_auto_delete_hint.
  ///
  /// In ru, this message translates to:
  /// **'Фотографии, видео и другие файлы, которые вы не открывали в течение этого срока, будут удалены с устройства для экономии места.'**
  String get storage_auto_delete_hint;

  /// No description provided for @storage_chat_detail_share.
  ///
  /// In ru, this message translates to:
  /// **'На этот чат приходится {pct}% кэша'**
  String storage_chat_detail_share(Object pct);

  /// No description provided for @storage_chat_detail_media_tab.
  ///
  /// In ru, this message translates to:
  /// **'Медиа'**
  String get storage_chat_detail_media_tab;

  /// No description provided for @storage_chat_detail_select_all.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать все'**
  String get storage_chat_detail_select_all;

  /// No description provided for @storage_chat_detail_deselect_all.
  ///
  /// In ru, this message translates to:
  /// **'Снять все'**
  String get storage_chat_detail_deselect_all;

  /// No description provided for @storage_chat_detail_clear_button.
  ///
  /// In ru, this message translates to:
  /// **'Очистить кэш {size}'**
  String storage_chat_detail_clear_button(Object size);

  /// No description provided for @storage_chat_detail_clear_button_empty.
  ///
  /// In ru, this message translates to:
  /// **'Выберите файлы для удаления'**
  String get storage_chat_detail_clear_button_empty;

  /// No description provided for @storage_chat_detail_tab_empty.
  ///
  /// In ru, this message translates to:
  /// **'В этой вкладке ничего нет.'**
  String get storage_chat_detail_tab_empty;

  /// No description provided for @storage_chat_detail_delete_title.
  ///
  /// In ru, this message translates to:
  /// **'Удалить выбранные файлы?'**
  String get storage_chat_detail_delete_title;

  /// No description provided for @storage_chat_detail_delete_body.
  ///
  /// In ru, this message translates to:
  /// **'{count} файлов ({size}) будет удалено с устройства. Облачные копии не затрагиваются.'**
  String storage_chat_detail_delete_body(Object count, Object size);

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

  /// No description provided for @notifications_message_ringtone_label.
  ///
  /// In ru, this message translates to:
  /// **'Мелодия сообщений'**
  String get notifications_message_ringtone_label;

  /// No description provided for @notifications_call_ringtone_label.
  ///
  /// In ru, this message translates to:
  /// **'Мелодия звонков'**
  String get notifications_call_ringtone_label;

  /// No description provided for @notifications_meeting_hand_raise_title.
  ///
  /// In ru, this message translates to:
  /// **'Звук поднятия руки'**
  String get notifications_meeting_hand_raise_title;

  /// No description provided for @notifications_meeting_hand_raise_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Лёгкий сигнал, когда участник конференции поднимает руку.'**
  String get notifications_meeting_hand_raise_subtitle;

  /// No description provided for @ringtone_default.
  ///
  /// In ru, this message translates to:
  /// **'По умолчанию'**
  String get ringtone_default;

  /// No description provided for @ringtone_classic_chime.
  ///
  /// In ru, this message translates to:
  /// **'Классический перезвон'**
  String get ringtone_classic_chime;

  /// No description provided for @ringtone_gentle_bells.
  ///
  /// In ru, this message translates to:
  /// **'Мягкие колокольчики'**
  String get ringtone_gentle_bells;

  /// No description provided for @ringtone_marimba_tap.
  ///
  /// In ru, this message translates to:
  /// **'Маримба'**
  String get ringtone_marimba_tap;

  /// No description provided for @ringtone_soft_pulse.
  ///
  /// In ru, this message translates to:
  /// **'Мягкий пульс'**
  String get ringtone_soft_pulse;

  /// No description provided for @ringtone_ascending_chord.
  ///
  /// In ru, this message translates to:
  /// **'Восходящий аккорд'**
  String get ringtone_ascending_chord;

  /// No description provided for @ringtone_storage_original.
  ///
  /// In ru, this message translates to:
  /// **'Оригинальная (Storage)'**
  String get ringtone_storage_original;

  /// No description provided for @ringtone_preview_play.
  ///
  /// In ru, this message translates to:
  /// **'Прослушать'**
  String get ringtone_preview_play;

  /// No description provided for @ringtone_picker_messages_title.
  ///
  /// In ru, this message translates to:
  /// **'Мелодия сообщений'**
  String get ringtone_picker_messages_title;

  /// No description provided for @ringtone_picker_calls_title.
  ///
  /// In ru, this message translates to:
  /// **'Мелодия звонков'**
  String get ringtone_picker_calls_title;

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
  /// **'Приватность чата'**
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

  /// No description provided for @chat_list_create_folder_name_hint.
  ///
  /// In ru, this message translates to:
  /// **'Название папки'**
  String get chat_list_create_folder_name_hint;

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

  /// No description provided for @auth_entry_sign_in.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get auth_entry_sign_in;

  /// No description provided for @auth_entry_sign_up.
  ///
  /// In ru, this message translates to:
  /// **'Создать аккаунт'**
  String get auth_entry_sign_up;

  /// No description provided for @auth_qr_title.
  ///
  /// In ru, this message translates to:
  /// **'Войти по QR'**
  String get auth_qr_title;

  /// No description provided for @auth_qr_hint.
  ///
  /// In ru, this message translates to:
  /// **'Откройте LighChat на устройстве, где вы уже вошли → Настройки → Устройства → Подключить новое устройство, и наведите камеру на этот код.'**
  String get auth_qr_hint;

  /// No description provided for @auth_qr_refresh_in.
  ///
  /// In ru, this message translates to:
  /// **'Обновится через {seconds}с'**
  String auth_qr_refresh_in(int seconds);

  /// No description provided for @auth_qr_other_method.
  ///
  /// In ru, this message translates to:
  /// **'Войти другим способом'**
  String get auth_qr_other_method;

  /// No description provided for @auth_qr_approving.
  ///
  /// In ru, this message translates to:
  /// **'Входим…'**
  String get auth_qr_approving;

  /// No description provided for @auth_qr_rejected.
  ///
  /// In ru, this message translates to:
  /// **'Запрос отклонён'**
  String get auth_qr_rejected;

  /// No description provided for @auth_qr_retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get auth_qr_retry;

  /// No description provided for @auth_qr_unknown_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сгенерировать QR-код.'**
  String get auth_qr_unknown_error;

  /// No description provided for @auth_qr_use_qr_login.
  ///
  /// In ru, this message translates to:
  /// **'Войти по QR'**
  String get auth_qr_use_qr_login;

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

  /// No description provided for @voice_transcript_retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить транскрибацию'**
  String get voice_transcript_retry;

  /// No description provided for @voice_transcript_summary_show.
  ///
  /// In ru, this message translates to:
  /// **'Показать резюме'**
  String get voice_transcript_summary_show;

  /// No description provided for @voice_transcript_summary_hide.
  ///
  /// In ru, this message translates to:
  /// **'Показать полный текст'**
  String get voice_transcript_summary_hide;

  /// No description provided for @voice_transcript_stats.
  ///
  /// In ru, this message translates to:
  /// **'{words} слов · {wpm} сл/мин'**
  String voice_transcript_stats(int words, int wpm);

  /// No description provided for @voice_attachment_skip_silence.
  ///
  /// In ru, this message translates to:
  /// **'Пропускать тишину'**
  String get voice_attachment_skip_silence;

  /// No description provided for @voice_karaoke_title.
  ///
  /// In ru, this message translates to:
  /// **'Караоке'**
  String get voice_karaoke_title;

  /// No description provided for @voice_karaoke_prompt_title.
  ///
  /// In ru, this message translates to:
  /// **'Режим караоке'**
  String get voice_karaoke_prompt_title;

  /// No description provided for @voice_karaoke_prompt_body.
  ///
  /// In ru, this message translates to:
  /// **'Открыть голосовое сообщение в полноэкранном режиме с подсветкой слов?'**
  String get voice_karaoke_prompt_body;

  /// No description provided for @voice_karaoke_prompt_open.
  ///
  /// In ru, this message translates to:
  /// **'Открыть'**
  String get voice_karaoke_prompt_open;

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

  /// No description provided for @voice_transcript_permission_denied.
  ///
  /// In ru, this message translates to:
  /// **'Распознавание речи запрещено. Включите его в системных настройках.'**
  String get voice_transcript_permission_denied;

  /// No description provided for @voice_transcript_unsupported_lang.
  ///
  /// In ru, this message translates to:
  /// **'Этот язык не поддерживается локальным распознаванием на устройстве.'**
  String get voice_transcript_unsupported_lang;

  /// No description provided for @voice_transcript_no_model.
  ///
  /// In ru, this message translates to:
  /// **'Установите офлайн-пакет распознавания речи в системных настройках.'**
  String get voice_transcript_no_model;

  /// No description provided for @ai_action_summarize.
  ///
  /// In ru, this message translates to:
  /// **'Краткое содержание'**
  String get ai_action_summarize;

  /// No description provided for @ai_action_rewrite.
  ///
  /// In ru, this message translates to:
  /// **'Переписать (AI)'**
  String get ai_action_rewrite;

  /// No description provided for @ai_action_apply.
  ///
  /// In ru, this message translates to:
  /// **'Применить'**
  String get ai_action_apply;

  /// No description provided for @ai_action_thinking.
  ///
  /// In ru, this message translates to:
  /// **'Пишу…'**
  String get ai_action_thinking;

  /// No description provided for @ai_action_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обработать этот текст. Возможно, язык ещё не поддерживается on-device AI.'**
  String get ai_action_failed;

  /// No description provided for @ai_status_model_not_ready.
  ///
  /// In ru, this message translates to:
  /// **'Модель Apple Intelligence ещё загружается. Попробуйте через минуту.'**
  String get ai_status_model_not_ready;

  /// No description provided for @ai_status_not_enabled.
  ///
  /// In ru, this message translates to:
  /// **'Apple Intelligence не включён в Настройках.'**
  String get ai_status_not_enabled;

  /// No description provided for @ai_status_device_not_eligible.
  ///
  /// In ru, this message translates to:
  /// **'Это устройство не поддерживает Apple Intelligence.'**
  String get ai_status_device_not_eligible;

  /// No description provided for @ai_status_unsupported_os.
  ///
  /// In ru, this message translates to:
  /// **'Apple Intelligence требует iOS 26 или новее.'**
  String get ai_status_unsupported_os;

  /// No description provided for @ai_status_unknown.
  ///
  /// In ru, this message translates to:
  /// **'Apple Intelligence сейчас недоступен.'**
  String get ai_status_unknown;

  /// No description provided for @navigator_picker_title.
  ///
  /// In ru, this message translates to:
  /// **'Открыть в'**
  String get navigator_picker_title;

  /// No description provided for @calendar_picker_title.
  ///
  /// In ru, this message translates to:
  /// **'Добавить в календарь'**
  String get calendar_picker_title;

  /// No description provided for @calendar_picker_native_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Системный календарь со всеми вашими аккаунтами'**
  String get calendar_picker_native_subtitle;

  /// No description provided for @calendar_picker_web_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Откроется в приложении или браузере'**
  String get calendar_picker_web_subtitle;

  /// No description provided for @ai_style_friendly.
  ///
  /// In ru, this message translates to:
  /// **'Дружелюбнее'**
  String get ai_style_friendly;

  /// No description provided for @ai_style_formal.
  ///
  /// In ru, this message translates to:
  /// **'Формально'**
  String get ai_style_formal;

  /// No description provided for @ai_style_shorter.
  ///
  /// In ru, this message translates to:
  /// **'Короче'**
  String get ai_style_shorter;

  /// No description provided for @ai_style_longer.
  ///
  /// In ru, this message translates to:
  /// **'Подробнее'**
  String get ai_style_longer;

  /// No description provided for @ai_style_proofread.
  ///
  /// In ru, this message translates to:
  /// **'Орфография'**
  String get ai_style_proofread;

  /// No description provided for @ai_style_youth.
  ///
  /// In ru, this message translates to:
  /// **'Молодёжный'**
  String get ai_style_youth;

  /// No description provided for @ai_style_strict.
  ///
  /// In ru, this message translates to:
  /// **'Строгий'**
  String get ai_style_strict;

  /// No description provided for @ai_style_blatnoy.
  ///
  /// In ru, this message translates to:
  /// **'По-блатному'**
  String get ai_style_blatnoy;

  /// No description provided for @ai_style_funny.
  ///
  /// In ru, this message translates to:
  /// **'Шутливый'**
  String get ai_style_funny;

  /// No description provided for @ai_style_romantic.
  ///
  /// In ru, this message translates to:
  /// **'Романтичный'**
  String get ai_style_romantic;

  /// No description provided for @ai_style_sarcastic.
  ///
  /// In ru, this message translates to:
  /// **'Саркастичный'**
  String get ai_style_sarcastic;

  /// No description provided for @ai_rewrite_picker_title.
  ///
  /// In ru, this message translates to:
  /// **'Стиль переписывания'**
  String get ai_rewrite_picker_title;

  /// No description provided for @voice_translate_action.
  ///
  /// In ru, this message translates to:
  /// **'Перевести'**
  String get voice_translate_action;

  /// No description provided for @voice_translate_show_original.
  ///
  /// In ru, this message translates to:
  /// **'Оригинал'**
  String get voice_translate_show_original;

  /// No description provided for @voice_translate_in_progress.
  ///
  /// In ru, this message translates to:
  /// **'Перевожу…'**
  String get voice_translate_in_progress;

  /// No description provided for @voice_translate_downloading_model.
  ///
  /// In ru, this message translates to:
  /// **'Скачиваю модель…'**
  String get voice_translate_downloading_model;

  /// No description provided for @voice_translate_unsupported.
  ///
  /// In ru, this message translates to:
  /// **'Перевод недоступен для этой языковой пары.'**
  String get voice_translate_unsupported;

  /// No description provided for @voice_translate_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось перевести: {error}'**
  String voice_translate_failed(Object error);

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

  /// No description provided for @share_picker_title.
  ///
  /// In ru, this message translates to:
  /// **'Поделиться в LighChat'**
  String get share_picker_title;

  /// No description provided for @share_picker_empty_payload.
  ///
  /// In ru, this message translates to:
  /// **'Нет содержимого для отправки'**
  String get share_picker_empty_payload;

  /// No description provided for @share_picker_summary_text_only.
  ///
  /// In ru, this message translates to:
  /// **'Текст'**
  String get share_picker_summary_text_only;

  /// No description provided for @share_picker_summary_files_count.
  ///
  /// In ru, this message translates to:
  /// **'Файлов: {count}'**
  String share_picker_summary_files_count(int count);

  /// No description provided for @share_picker_summary_files_with_text.
  ///
  /// In ru, this message translates to:
  /// **'Файлов: {count} + текст'**
  String share_picker_summary_files_with_text(int count);

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

  /// No description provided for @devices_connect_new_device.
  ///
  /// In ru, this message translates to:
  /// **'Подключить новое устройство'**
  String get devices_connect_new_device;

  /// No description provided for @devices_approve_title.
  ///
  /// In ru, this message translates to:
  /// **'Разрешить вход на этом устройстве?'**
  String get devices_approve_title;

  /// No description provided for @devices_approve_body_hint.
  ///
  /// In ru, this message translates to:
  /// **'Убедитесь, что это ваше устройство, на котором вы только что показали QR.'**
  String get devices_approve_body_hint;

  /// No description provided for @devices_approve_allow.
  ///
  /// In ru, this message translates to:
  /// **'Разрешить'**
  String get devices_approve_allow;

  /// No description provided for @devices_approve_deny.
  ///
  /// In ru, this message translates to:
  /// **'Отклонить'**
  String get devices_approve_deny;

  /// No description provided for @devices_handover_progress_title.
  ///
  /// In ru, this message translates to:
  /// **'Синхронизация зашифрованных чатов…'**
  String get devices_handover_progress_title;

  /// No description provided for @devices_handover_progress_body.
  ///
  /// In ru, this message translates to:
  /// **'Обработано {done} из {total}'**
  String devices_handover_progress_body(int done, int total);

  /// No description provided for @devices_handover_progress_starting.
  ///
  /// In ru, this message translates to:
  /// **'Начинаем…'**
  String get devices_handover_progress_starting;

  /// No description provided for @devices_handover_success_title.
  ///
  /// In ru, this message translates to:
  /// **'Устройство подключено'**
  String get devices_handover_success_title;

  /// No description provided for @devices_handover_success_body.
  ///
  /// In ru, this message translates to:
  /// **'Устройство {label} получило доступ к зашифрованным чатам.'**
  String devices_handover_success_body(String label);

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

  /// No description provided for @media_viewer_action_live_text.
  ///
  /// In ru, this message translates to:
  /// **'Live Text'**
  String get media_viewer_action_live_text;

  /// No description provided for @media_viewer_action_subject_lift.
  ///
  /// In ru, this message translates to:
  /// **'Вырезать объект'**
  String get media_viewer_action_subject_lift;

  /// No description provided for @media_viewer_action_subject_send.
  ///
  /// In ru, this message translates to:
  /// **'В этот чат'**
  String get media_viewer_action_subject_send;

  /// No description provided for @media_viewer_action_subject_save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить в Фото'**
  String get media_viewer_action_subject_save;

  /// No description provided for @media_viewer_action_subject_share.
  ///
  /// In ru, this message translates to:
  /// **'Поделиться'**
  String get media_viewer_action_subject_share;

  /// No description provided for @media_viewer_subject_saved.
  ///
  /// In ru, this message translates to:
  /// **'Сохранено в Фото'**
  String get media_viewer_subject_saved;

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

  /// No description provided for @message_menu_action_translate.
  ///
  /// In ru, this message translates to:
  /// **'Перевести'**
  String get message_menu_action_translate;

  /// No description provided for @message_menu_action_show_original.
  ///
  /// In ru, this message translates to:
  /// **'Показать оригинал'**
  String get message_menu_action_show_original;

  /// No description provided for @message_menu_action_read_aloud.
  ///
  /// In ru, this message translates to:
  /// **'Прочитать вслух'**
  String get message_menu_action_read_aloud;

  /// No description provided for @tts_quality_hint.
  ///
  /// In ru, this message translates to:
  /// **'Голос звучит как робот? Установите Enhanced-голоса: Настройки → Универсальный доступ → Контент с речью → Голоса.'**
  String get tts_quality_hint;

  /// No description provided for @tts_quality_hint_cta.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get tts_quality_hint_cta;

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

  /// No description provided for @message_menu_action_create_sticker.
  ///
  /// In ru, this message translates to:
  /// **'Создать стикер'**
  String get message_menu_action_create_sticker;

  /// No description provided for @message_menu_action_save_to_my_stickers.
  ///
  /// In ru, this message translates to:
  /// **'Добавить в мои стикеры'**
  String get message_menu_action_save_to_my_stickers;

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

  /// No description provided for @conversation_durak_winner.
  ///
  /// In ru, this message translates to:
  /// **'Победитель!'**
  String get conversation_durak_winner;

  /// No description provided for @conversation_durak_play_again.
  ///
  /// In ru, this message translates to:
  /// **'Сыграть ещё раз'**
  String get conversation_durak_play_again;

  /// No description provided for @conversation_durak_back_to_chat.
  ///
  /// In ru, this message translates to:
  /// **'Вернуться в чат'**
  String get conversation_durak_back_to_chat;

  /// No description provided for @conversation_game_lobby_waiting_opponent.
  ///
  /// In ru, this message translates to:
  /// **'Ожидание соперника…'**
  String get conversation_game_lobby_waiting_opponent;

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

  /// No description provided for @schedule_message_sheet_title.
  ///
  /// In ru, this message translates to:
  /// **'Запланировать сообщение'**
  String get schedule_message_sheet_title;

  /// No description provided for @schedule_message_long_press_hint.
  ///
  /// In ru, this message translates to:
  /// **'Запланировать отправку'**
  String get schedule_message_long_press_hint;

  /// No description provided for @schedule_message_preset_today_at.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня в {time}'**
  String schedule_message_preset_today_at(String time);

  /// No description provided for @schedule_message_preset_tomorrow_at.
  ///
  /// In ru, this message translates to:
  /// **'Завтра в {time}'**
  String schedule_message_preset_tomorrow_at(String time);

  /// No description provided for @schedule_message_will_send_at.
  ///
  /// In ru, this message translates to:
  /// **'Будет отправлено: {datetime}'**
  String schedule_message_will_send_at(String datetime);

  /// No description provided for @schedule_message_must_be_in_future.
  ///
  /// In ru, this message translates to:
  /// **'Время должно быть в будущем (минимум через минуту).'**
  String get schedule_message_must_be_in_future;

  /// No description provided for @schedule_message_e2ee_warning.
  ///
  /// In ru, this message translates to:
  /// **'Это E2EE-чат. Отложенное сообщение будет сохранено в открытом виде на сервере и опубликовано без шифрования.'**
  String get schedule_message_e2ee_warning;

  /// No description provided for @schedule_message_cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get schedule_message_cancel;

  /// No description provided for @schedule_message_confirm.
  ///
  /// In ru, this message translates to:
  /// **'Запланировать'**
  String get schedule_message_confirm;

  /// No description provided for @schedule_message_save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get schedule_message_save;

  /// No description provided for @schedule_message_text_required.
  ///
  /// In ru, this message translates to:
  /// **'Сначала введите текст'**
  String get schedule_message_text_required;

  /// No description provided for @schedule_message_attachments_unsupported_mobile.
  ///
  /// In ru, this message translates to:
  /// **'Планирование вложений пока поддерживается только в веб-клиенте'**
  String get schedule_message_attachments_unsupported_mobile;

  /// No description provided for @schedule_message_scheduled_toast.
  ///
  /// In ru, this message translates to:
  /// **'Запланировано: {datetime}'**
  String schedule_message_scheduled_toast(String datetime);

  /// No description provided for @schedule_message_failed_toast.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось запланировать: {error}'**
  String schedule_message_failed_toast(String error);

  /// No description provided for @scheduled_messages_screen_title.
  ///
  /// In ru, this message translates to:
  /// **'Запланированные сообщения'**
  String get scheduled_messages_screen_title;

  /// No description provided for @scheduled_messages_empty_title.
  ///
  /// In ru, this message translates to:
  /// **'Нет запланированных сообщений'**
  String get scheduled_messages_empty_title;

  /// No description provided for @scheduled_messages_empty_hint.
  ///
  /// In ru, this message translates to:
  /// **'Удерживайте кнопку «Отправить», чтобы запланировать.'**
  String get scheduled_messages_empty_hint;

  /// No description provided for @scheduled_messages_load_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить: {error}'**
  String scheduled_messages_load_failed(String error);

  /// No description provided for @scheduled_messages_e2ee_notice.
  ///
  /// In ru, this message translates to:
  /// **'В E2EE-чате запланированные сообщения хранятся и публикуются в открытом виде.'**
  String get scheduled_messages_e2ee_notice;

  /// No description provided for @scheduled_messages_cancel_dialog_title.
  ///
  /// In ru, this message translates to:
  /// **'Отменить отправку?'**
  String get scheduled_messages_cancel_dialog_title;

  /// No description provided for @scheduled_messages_cancel_dialog_body.
  ///
  /// In ru, this message translates to:
  /// **'Запланированное сообщение будет удалено.'**
  String get scheduled_messages_cancel_dialog_body;

  /// No description provided for @scheduled_messages_cancel_dialog_keep.
  ///
  /// In ru, this message translates to:
  /// **'Не отменять'**
  String get scheduled_messages_cancel_dialog_keep;

  /// No description provided for @scheduled_messages_cancel_dialog_confirm.
  ///
  /// In ru, this message translates to:
  /// **'Отменить'**
  String get scheduled_messages_cancel_dialog_confirm;

  /// No description provided for @scheduled_messages_canceled_toast.
  ///
  /// In ru, this message translates to:
  /// **'Отменено'**
  String get scheduled_messages_canceled_toast;

  /// No description provided for @scheduled_messages_time_changed_toast.
  ///
  /// In ru, this message translates to:
  /// **'Время изменено: {datetime}'**
  String scheduled_messages_time_changed_toast(String datetime);

  /// No description provided for @scheduled_messages_action_failed_toast.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка: {error}'**
  String scheduled_messages_action_failed_toast(String error);

  /// No description provided for @scheduled_messages_tile_edit_tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Изменить время'**
  String get scheduled_messages_tile_edit_tooltip;

  /// No description provided for @scheduled_messages_tile_cancel_tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Отменить'**
  String get scheduled_messages_tile_cancel_tooltip;

  /// No description provided for @scheduled_messages_preview_poll.
  ///
  /// In ru, this message translates to:
  /// **'Опрос: {question}'**
  String scheduled_messages_preview_poll(String question);

  /// No description provided for @scheduled_messages_preview_location.
  ///
  /// In ru, this message translates to:
  /// **'Локация'**
  String get scheduled_messages_preview_location;

  /// No description provided for @scheduled_messages_preview_attachment.
  ///
  /// In ru, this message translates to:
  /// **'Вложение'**
  String get scheduled_messages_preview_attachment;

  /// No description provided for @scheduled_messages_preview_attachment_count.
  ///
  /// In ru, this message translates to:
  /// **'Вложение (×{count})'**
  String scheduled_messages_preview_attachment_count(int count);

  /// No description provided for @scheduled_messages_preview_message.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение'**
  String get scheduled_messages_preview_message;

  /// No description provided for @chat_header_tooltip_scheduled.
  ///
  /// In ru, this message translates to:
  /// **'Запланированные сообщения'**
  String get chat_header_tooltip_scheduled;

  /// No description provided for @schedule_date_label.
  ///
  /// In ru, this message translates to:
  /// **'Дата'**
  String get schedule_date_label;

  /// No description provided for @schedule_time_label.
  ///
  /// In ru, this message translates to:
  /// **'Время'**
  String get schedule_time_label;

  /// No description provided for @common_done.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get common_done;

  /// No description provided for @common_send.
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get common_send;

  /// No description provided for @common_open.
  ///
  /// In ru, this message translates to:
  /// **'Открыть'**
  String get common_open;

  /// No description provided for @common_add.
  ///
  /// In ru, this message translates to:
  /// **'Добавить'**
  String get common_add;

  /// No description provided for @common_search.
  ///
  /// In ru, this message translates to:
  /// **'Поиск'**
  String get common_search;

  /// No description provided for @common_edit.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать'**
  String get common_edit;

  /// No description provided for @common_next.
  ///
  /// In ru, this message translates to:
  /// **'Далее'**
  String get common_next;

  /// No description provided for @common_ok.
  ///
  /// In ru, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// No description provided for @common_confirm.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get common_confirm;

  /// No description provided for @common_ready.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get common_ready;

  /// No description provided for @common_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка'**
  String get common_error;

  /// No description provided for @common_yes.
  ///
  /// In ru, this message translates to:
  /// **'Да'**
  String get common_yes;

  /// No description provided for @common_no.
  ///
  /// In ru, this message translates to:
  /// **'Нет'**
  String get common_no;

  /// No description provided for @common_back.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get common_back;

  /// No description provided for @common_continue.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить'**
  String get common_continue;

  /// No description provided for @common_loading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка…'**
  String get common_loading;

  /// No description provided for @common_copy.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать'**
  String get common_copy;

  /// No description provided for @common_share.
  ///
  /// In ru, this message translates to:
  /// **'Поделиться'**
  String get common_share;

  /// No description provided for @common_settings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get common_settings;

  /// No description provided for @common_today.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get common_today;

  /// No description provided for @common_yesterday.
  ///
  /// In ru, this message translates to:
  /// **'Вчера'**
  String get common_yesterday;

  /// No description provided for @e2ee_qr_title.
  ///
  /// In ru, this message translates to:
  /// **'QR-pairing ключа'**
  String get e2ee_qr_title;

  /// No description provided for @e2ee_qr_uid_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось получить uid пользователя.'**
  String get e2ee_qr_uid_error;

  /// No description provided for @e2ee_qr_session_ended_error.
  ///
  /// In ru, this message translates to:
  /// **'Сессия завершилась до ответа от второго устройства.'**
  String get e2ee_qr_session_ended_error;

  /// No description provided for @e2ee_qr_no_data_error.
  ///
  /// In ru, this message translates to:
  /// **'Нет данных для применения ключа.'**
  String get e2ee_qr_no_data_error;

  /// No description provided for @e2ee_qr_key_transferred_toast.
  ///
  /// In ru, this message translates to:
  /// **'Ключ перенесён. Перезайдите в чаты, чтобы обновить сессии.'**
  String get e2ee_qr_key_transferred_toast;

  /// No description provided for @e2ee_qr_wrong_account_error.
  ///
  /// In ru, this message translates to:
  /// **'QR сгенерирован под другой аккаунт.'**
  String get e2ee_qr_wrong_account_error;

  /// No description provided for @e2ee_qr_explainer_title.
  ///
  /// In ru, this message translates to:
  /// **'Что это'**
  String get e2ee_qr_explainer_title;

  /// No description provided for @e2ee_qr_explainer_text.
  ///
  /// In ru, this message translates to:
  /// **'Передача приватного ключа с одного вашего устройства на другое по ECDH + QR. Обе стороны видят 6-значный код для ручной сверки.'**
  String get e2ee_qr_explainer_text;

  /// No description provided for @e2ee_qr_show_qr_label.
  ///
  /// In ru, this message translates to:
  /// **'Я на новом устройстве — показать QR'**
  String get e2ee_qr_show_qr_label;

  /// No description provided for @e2ee_qr_scan_qr_label.
  ///
  /// In ru, this message translates to:
  /// **'У меня уже есть ключ — сканировать QR'**
  String get e2ee_qr_scan_qr_label;

  /// No description provided for @e2ee_qr_scan_hint.
  ///
  /// In ru, this message translates to:
  /// **'Отсканируйте QR на старом устройстве, где уже есть ключ.'**
  String get e2ee_qr_scan_hint;

  /// No description provided for @e2ee_qr_verify_code_label.
  ///
  /// In ru, this message translates to:
  /// **'Сверьте 6-значный код со старым устройством:'**
  String get e2ee_qr_verify_code_label;

  /// No description provided for @e2ee_qr_transfer_from_device_label.
  ///
  /// In ru, this message translates to:
  /// **'Перенос с устройства: {label}'**
  String e2ee_qr_transfer_from_device_label(String label);

  /// No description provided for @e2ee_qr_code_match_apply_label.
  ///
  /// In ru, this message translates to:
  /// **'Код совпал — применить'**
  String get e2ee_qr_code_match_apply_label;

  /// No description provided for @e2ee_qr_key_success_label.
  ///
  /// In ru, this message translates to:
  /// **'Ключ успешно перенесён на это устройство. Перезайдите в чаты.'**
  String get e2ee_qr_key_success_label;

  /// No description provided for @e2ee_qr_unknown_error.
  ///
  /// In ru, this message translates to:
  /// **'Неизвестная ошибка'**
  String get e2ee_qr_unknown_error;

  /// No description provided for @e2ee_qr_back_to_pick_label.
  ///
  /// In ru, this message translates to:
  /// **'К выбору'**
  String get e2ee_qr_back_to_pick_label;

  /// No description provided for @e2ee_qr_donor_scan_hint.
  ///
  /// In ru, this message translates to:
  /// **'Наведите камеру на QR, показанный на новом устройстве.'**
  String get e2ee_qr_donor_scan_hint;

  /// No description provided for @e2ee_qr_donor_verify_code_label.
  ///
  /// In ru, this message translates to:
  /// **'Сверьте код с новым устройством:'**
  String get e2ee_qr_donor_verify_code_label;

  /// No description provided for @e2ee_qr_donor_verify_hint.
  ///
  /// In ru, this message translates to:
  /// **'Если код совпадает — подтвердите на новом устройстве. Если нет, немедленно нажмите «Отмена».'**
  String get e2ee_qr_donor_verify_hint;

  /// No description provided for @e2ee_encrypt_title.
  ///
  /// In ru, this message translates to:
  /// **'Шифрование'**
  String get e2ee_encrypt_title;

  /// No description provided for @e2ee_encrypt_enable_dialog_title.
  ///
  /// In ru, this message translates to:
  /// **'Включить шифрование?'**
  String get e2ee_encrypt_enable_dialog_title;

  /// No description provided for @e2ee_encrypt_enable_dialog_body.
  ///
  /// In ru, this message translates to:
  /// **'Новые сообщения будут доступны только на ваших устройствах и у собеседника. Старые сообщения останутся как есть.'**
  String get e2ee_encrypt_enable_dialog_body;

  /// No description provided for @e2ee_encrypt_enable_label.
  ///
  /// In ru, this message translates to:
  /// **'Включить'**
  String get e2ee_encrypt_enable_label;

  /// No description provided for @e2ee_encrypt_disable_dialog_title.
  ///
  /// In ru, this message translates to:
  /// **'Отключить шифрование?'**
  String get e2ee_encrypt_disable_dialog_title;

  /// No description provided for @e2ee_encrypt_disable_dialog_body.
  ///
  /// In ru, this message translates to:
  /// **'Новые сообщения пойдут без сквозного шифрования. Ранее отправленные зашифрованные сообщения останутся в ленте.'**
  String get e2ee_encrypt_disable_dialog_body;

  /// No description provided for @e2ee_encrypt_disable_label.
  ///
  /// In ru, this message translates to:
  /// **'Отключить'**
  String get e2ee_encrypt_disable_label;

  /// No description provided for @e2ee_encrypt_status_on.
  ///
  /// In ru, this message translates to:
  /// **'Сквозное шифрование включено для этого чата.'**
  String get e2ee_encrypt_status_on;

  /// No description provided for @e2ee_encrypt_status_off.
  ///
  /// In ru, this message translates to:
  /// **'Сквозное шифрование выключено.'**
  String get e2ee_encrypt_status_off;

  /// No description provided for @e2ee_encrypt_description.
  ///
  /// In ru, this message translates to:
  /// **'Когда шифрование включено, содержимое новых сообщений доступно только участникам чата на их устройствах. Отключение влияет только на новые сообщения.'**
  String get e2ee_encrypt_description;

  /// No description provided for @e2ee_encrypt_switch_title.
  ///
  /// In ru, this message translates to:
  /// **'Включить шифрование'**
  String get e2ee_encrypt_switch_title;

  /// No description provided for @e2ee_encrypt_switch_on.
  ///
  /// In ru, this message translates to:
  /// **'Включено (эпоха ключа: {epoch})'**
  String e2ee_encrypt_switch_on(int epoch);

  /// No description provided for @e2ee_encrypt_switch_off.
  ///
  /// In ru, this message translates to:
  /// **'Выключено'**
  String get e2ee_encrypt_switch_off;

  /// No description provided for @e2ee_encrypt_already_on_toast.
  ///
  /// In ru, this message translates to:
  /// **'Шифрование уже включено или не удалось создать ключи. Проверьте сеть и наличие ключей у собеседника.'**
  String get e2ee_encrypt_already_on_toast;

  /// No description provided for @e2ee_encrypt_no_device_toast.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось включить: у собеседника нет активного устройства с ключом.'**
  String get e2ee_encrypt_no_device_toast;

  /// No description provided for @e2ee_encrypt_enable_failed_toast.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось включить шифрование: {error}'**
  String e2ee_encrypt_enable_failed_toast(String error);

  /// No description provided for @e2ee_encrypt_disable_failed_toast.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отключить: {error}'**
  String e2ee_encrypt_disable_failed_toast(String error);

  /// No description provided for @e2ee_encrypt_data_types_title.
  ///
  /// In ru, this message translates to:
  /// **'Типы данных'**
  String get e2ee_encrypt_data_types_title;

  /// No description provided for @e2ee_encrypt_data_types_description.
  ///
  /// In ru, this message translates to:
  /// **'Настройка не меняет протокол. Она управляет тем, какие типы данных отправлять в зашифрованном виде.'**
  String get e2ee_encrypt_data_types_description;

  /// No description provided for @e2ee_encrypt_override_title.
  ///
  /// In ru, this message translates to:
  /// **'Настройки шифрования для этого чата'**
  String get e2ee_encrypt_override_title;

  /// No description provided for @e2ee_encrypt_override_on.
  ///
  /// In ru, this message translates to:
  /// **'Используются чатовые настройки.'**
  String get e2ee_encrypt_override_on;

  /// No description provided for @e2ee_encrypt_override_off.
  ///
  /// In ru, this message translates to:
  /// **'Наследуются глобальные настройки.'**
  String get e2ee_encrypt_override_off;

  /// No description provided for @e2ee_encrypt_text_title.
  ///
  /// In ru, this message translates to:
  /// **'Текст сообщений'**
  String get e2ee_encrypt_text_title;

  /// No description provided for @e2ee_encrypt_media_title.
  ///
  /// In ru, this message translates to:
  /// **'Вложения (медиа/файлы)'**
  String get e2ee_encrypt_media_title;

  /// No description provided for @e2ee_encrypt_override_hint.
  ///
  /// In ru, this message translates to:
  /// **'Чтобы изменить для этого чата — включите «Переопределить».'**
  String get e2ee_encrypt_override_hint;

  /// No description provided for @sticker_default_pack_name.
  ///
  /// In ru, this message translates to:
  /// **'Мой пак'**
  String get sticker_default_pack_name;

  /// No description provided for @sticker_new_pack_dialog_title.
  ///
  /// In ru, this message translates to:
  /// **'Новый стикерпак'**
  String get sticker_new_pack_dialog_title;

  /// No description provided for @sticker_pack_name_hint.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get sticker_pack_name_hint;

  /// No description provided for @sticker_save_to_pack.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить в стикерпак'**
  String get sticker_save_to_pack;

  /// No description provided for @sticker_no_packs_hint.
  ///
  /// In ru, this message translates to:
  /// **'Нет паков. Создайте пак на вкладке «Стикеры».'**
  String get sticker_no_packs_hint;

  /// No description provided for @sticker_new_pack_option.
  ///
  /// In ru, this message translates to:
  /// **'Новый пак…'**
  String get sticker_new_pack_option;

  /// No description provided for @sticker_pick_image_or_gif.
  ///
  /// In ru, this message translates to:
  /// **'Выберите изображение или GIF'**
  String get sticker_pick_image_or_gif;

  /// No description provided for @sticker_send_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить: {error}'**
  String sticker_send_failed(String error);

  /// No description provided for @sticker_saved_to_pack.
  ///
  /// In ru, this message translates to:
  /// **'Сохранено в стикерпак'**
  String get sticker_saved_to_pack;

  /// No description provided for @sticker_save_gif_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось скачать или сохранить GIF'**
  String get sticker_save_gif_failed;

  /// No description provided for @sticker_delete_pack_title.
  ///
  /// In ru, this message translates to:
  /// **'Удалить пак?'**
  String get sticker_delete_pack_title;

  /// No description provided for @sticker_delete_pack_body.
  ///
  /// In ru, this message translates to:
  /// **'«{name}» и все стикеры в нём будут удалены.'**
  String sticker_delete_pack_body(String name);

  /// No description provided for @sticker_pack_deleted.
  ///
  /// In ru, this message translates to:
  /// **'Пак удалён'**
  String get sticker_pack_deleted;

  /// No description provided for @sticker_pack_delete_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось удалить пак'**
  String get sticker_pack_delete_failed;

  /// No description provided for @sticker_tab_emoji.
  ///
  /// In ru, this message translates to:
  /// **'ЭМОДЗИ'**
  String get sticker_tab_emoji;

  /// No description provided for @sticker_tab_stickers.
  ///
  /// In ru, this message translates to:
  /// **'СТИКЕРЫ'**
  String get sticker_tab_stickers;

  /// No description provided for @sticker_tab_gif.
  ///
  /// In ru, this message translates to:
  /// **'GIF'**
  String get sticker_tab_gif;

  /// No description provided for @sticker_scope_my.
  ///
  /// In ru, this message translates to:
  /// **'Мои'**
  String get sticker_scope_my;

  /// No description provided for @sticker_scope_public.
  ///
  /// In ru, this message translates to:
  /// **'Общие'**
  String get sticker_scope_public;

  /// No description provided for @sticker_new_pack_tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Новый пак'**
  String get sticker_new_pack_tooltip;

  /// No description provided for @sticker_pack_created.
  ///
  /// In ru, this message translates to:
  /// **'Стикерпак создан'**
  String get sticker_pack_created;

  /// No description provided for @sticker_no_packs_create.
  ///
  /// In ru, this message translates to:
  /// **'Нет стикерпаков. Создайте новый.'**
  String get sticker_no_packs_create;

  /// No description provided for @sticker_public_packs_empty.
  ///
  /// In ru, this message translates to:
  /// **'Общие паки не настроены'**
  String get sticker_public_packs_empty;

  /// No description provided for @sticker_section_recent.
  ///
  /// In ru, this message translates to:
  /// **'НЕДАВНИЕ'**
  String get sticker_section_recent;

  /// No description provided for @sticker_pack_empty_hint.
  ///
  /// In ru, this message translates to:
  /// **'Пак пуст. Добавьте с устройства (вкладка GIF — «В мой пак»).'**
  String get sticker_pack_empty_hint;

  /// No description provided for @sticker_delete_sticker_title.
  ///
  /// In ru, this message translates to:
  /// **'Удалить стикер?'**
  String get sticker_delete_sticker_title;

  /// No description provided for @sticker_deleted.
  ///
  /// In ru, this message translates to:
  /// **'Удалено'**
  String get sticker_deleted;

  /// No description provided for @sticker_gallery.
  ///
  /// In ru, this message translates to:
  /// **'Галерея'**
  String get sticker_gallery;

  /// No description provided for @sticker_gallery_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Фото, PNG, GIF с устройства — сразу в чат'**
  String get sticker_gallery_subtitle;

  /// No description provided for @gif_search_hint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск GIF…'**
  String get gif_search_hint;

  /// No description provided for @gif_translated_hint.
  ///
  /// In ru, this message translates to:
  /// **'Искали: {query}'**
  String gif_translated_hint(String query);

  /// No description provided for @gif_search_unavailable.
  ///
  /// In ru, this message translates to:
  /// **'Поиск GIF временно недоступен.'**
  String get gif_search_unavailable;

  /// No description provided for @gif_filter_all.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get gif_filter_all;

  /// No description provided for @sticker_section_animated.
  ///
  /// In ru, this message translates to:
  /// **'АНИМИРОВАННЫЕ'**
  String get sticker_section_animated;

  /// No description provided for @sticker_emoji_unavailable.
  ///
  /// In ru, this message translates to:
  /// **'Эмодзи в текст недоступны для этого окна.'**
  String get sticker_emoji_unavailable;

  /// No description provided for @sticker_create_pack_hint.
  ///
  /// In ru, this message translates to:
  /// **'Создайте пак кнопкой +'**
  String get sticker_create_pack_hint;

  /// No description provided for @sticker_public_packs_unavailable.
  ///
  /// In ru, this message translates to:
  /// **'Общие паки пока недоступны'**
  String get sticker_public_packs_unavailable;

  /// No description provided for @composer_link_title.
  ///
  /// In ru, this message translates to:
  /// **'Ссылка'**
  String get composer_link_title;

  /// No description provided for @composer_link_apply.
  ///
  /// In ru, this message translates to:
  /// **'Применить'**
  String get composer_link_apply;

  /// No description provided for @composer_attach_title.
  ///
  /// In ru, this message translates to:
  /// **'Прикрепить'**
  String get composer_attach_title;

  /// No description provided for @composer_attach_photo_video.
  ///
  /// In ru, this message translates to:
  /// **'Фото/Видео'**
  String get composer_attach_photo_video;

  /// No description provided for @composer_attach_files.
  ///
  /// In ru, this message translates to:
  /// **'Файлы'**
  String get composer_attach_files;

  /// No description provided for @composer_attach_video_circle.
  ///
  /// In ru, this message translates to:
  /// **'Кружок'**
  String get composer_attach_video_circle;

  /// No description provided for @composer_attach_location.
  ///
  /// In ru, this message translates to:
  /// **'Локация'**
  String get composer_attach_location;

  /// No description provided for @composer_attach_poll.
  ///
  /// In ru, this message translates to:
  /// **'Опрос'**
  String get composer_attach_poll;

  /// No description provided for @composer_attach_stickers.
  ///
  /// In ru, this message translates to:
  /// **'Стикеры'**
  String get composer_attach_stickers;

  /// No description provided for @composer_attach_clipboard.
  ///
  /// In ru, this message translates to:
  /// **'Буфер'**
  String get composer_attach_clipboard;

  /// No description provided for @composer_attach_text.
  ///
  /// In ru, this message translates to:
  /// **'Текст'**
  String get composer_attach_text;

  /// No description provided for @meeting_create_poll.
  ///
  /// In ru, this message translates to:
  /// **'Создать опрос'**
  String get meeting_create_poll;

  /// No description provided for @meeting_min_two_options.
  ///
  /// In ru, this message translates to:
  /// **'Минимум 2 варианта ответа'**
  String get meeting_min_two_options;

  /// No description provided for @meeting_error_with_details.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка: {details}'**
  String meeting_error_with_details(String details);

  /// No description provided for @meeting_polls_load_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить опросы: {details}'**
  String meeting_polls_load_error(String details);

  /// No description provided for @meeting_no_polls_yet.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет опросов'**
  String get meeting_no_polls_yet;

  /// No description provided for @meeting_question_label.
  ///
  /// In ru, this message translates to:
  /// **'Вопрос'**
  String get meeting_question_label;

  /// No description provided for @meeting_options_label.
  ///
  /// In ru, this message translates to:
  /// **'Варианты'**
  String get meeting_options_label;

  /// No description provided for @meeting_option_hint.
  ///
  /// In ru, this message translates to:
  /// **'Вариант {index}'**
  String meeting_option_hint(int index);

  /// No description provided for @meeting_add_option.
  ///
  /// In ru, this message translates to:
  /// **'Добавить вариант'**
  String get meeting_add_option;

  /// No description provided for @meeting_anonymous.
  ///
  /// In ru, this message translates to:
  /// **'Анонимно'**
  String get meeting_anonymous;

  /// No description provided for @meeting_anonymous_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Кто увидит выбор других'**
  String get meeting_anonymous_subtitle;

  /// No description provided for @meeting_save_as_draft.
  ///
  /// In ru, this message translates to:
  /// **'В черновики'**
  String get meeting_save_as_draft;

  /// No description provided for @meeting_publish.
  ///
  /// In ru, this message translates to:
  /// **'Опубликовать'**
  String get meeting_publish;

  /// No description provided for @meeting_action_start.
  ///
  /// In ru, this message translates to:
  /// **'Запустить'**
  String get meeting_action_start;

  /// No description provided for @meeting_action_change_vote.
  ///
  /// In ru, this message translates to:
  /// **'Изменить голос'**
  String get meeting_action_change_vote;

  /// No description provided for @meeting_action_restart.
  ///
  /// In ru, this message translates to:
  /// **'Перезапустить'**
  String get meeting_action_restart;

  /// No description provided for @meeting_action_stop.
  ///
  /// In ru, this message translates to:
  /// **'Остановить'**
  String get meeting_action_stop;

  /// No description provided for @meeting_vote_failed.
  ///
  /// In ru, this message translates to:
  /// **'Голос не засчитан: {details}'**
  String meeting_vote_failed(String details);

  /// No description provided for @meeting_status_ended.
  ///
  /// In ru, this message translates to:
  /// **'Завершено'**
  String get meeting_status_ended;

  /// No description provided for @meeting_status_draft.
  ///
  /// In ru, this message translates to:
  /// **'Черновик'**
  String get meeting_status_draft;

  /// No description provided for @meeting_status_active.
  ///
  /// In ru, this message translates to:
  /// **'Активно'**
  String get meeting_status_active;

  /// No description provided for @meeting_status_public.
  ///
  /// In ru, this message translates to:
  /// **'Публичное'**
  String get meeting_status_public;

  /// No description provided for @meeting_votes_count.
  ///
  /// In ru, this message translates to:
  /// **'{count} голосов'**
  String meeting_votes_count(int count);

  /// No description provided for @meeting_goal_count.
  ///
  /// In ru, this message translates to:
  /// **'Цель: {count}'**
  String meeting_goal_count(int count);

  /// No description provided for @meeting_hide.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть'**
  String get meeting_hide;

  /// No description provided for @meeting_who_voted.
  ///
  /// In ru, this message translates to:
  /// **'Кто голосовал'**
  String get meeting_who_voted;

  /// No description provided for @meeting_participants_tab.
  ///
  /// In ru, this message translates to:
  /// **'Участники ({count})'**
  String meeting_participants_tab(int count);

  /// No description provided for @meeting_polls_tab_active.
  ///
  /// In ru, this message translates to:
  /// **'Опросы ({count})'**
  String meeting_polls_tab_active(int count);

  /// No description provided for @meeting_polls_tab.
  ///
  /// In ru, this message translates to:
  /// **'Опросы'**
  String get meeting_polls_tab;

  /// No description provided for @meeting_chat_tab_unread.
  ///
  /// In ru, this message translates to:
  /// **'Чат ({count})'**
  String meeting_chat_tab_unread(int count);

  /// No description provided for @meeting_chat_tab.
  ///
  /// In ru, this message translates to:
  /// **'Чат'**
  String get meeting_chat_tab;

  /// No description provided for @meeting_requests_tab.
  ///
  /// In ru, this message translates to:
  /// **'Заявки ({count})'**
  String meeting_requests_tab(int count);

  /// No description provided for @meeting_you_suffix.
  ///
  /// In ru, this message translates to:
  /// **'{name} (Вы)'**
  String meeting_you_suffix(String name);

  /// No description provided for @meeting_host_label.
  ///
  /// In ru, this message translates to:
  /// **'Хост'**
  String get meeting_host_label;

  /// No description provided for @meeting_force_mute_mic.
  ///
  /// In ru, this message translates to:
  /// **'Выключить микрофон'**
  String get meeting_force_mute_mic;

  /// No description provided for @meeting_force_mute_camera.
  ///
  /// In ru, this message translates to:
  /// **'Выключить камеру'**
  String get meeting_force_mute_camera;

  /// No description provided for @meeting_kick_from_room.
  ///
  /// In ru, this message translates to:
  /// **'Удалить из комнаты'**
  String get meeting_kick_from_room;

  /// No description provided for @meeting_chat_load_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить чат: {error}'**
  String meeting_chat_load_error(Object error);

  /// No description provided for @meeting_no_requests.
  ///
  /// In ru, this message translates to:
  /// **'Нет новых заявок'**
  String get meeting_no_requests;

  /// No description provided for @meeting_no_messages_yet.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет сообщений'**
  String get meeting_no_messages_yet;

  /// No description provided for @meeting_file_too_large.
  ///
  /// In ru, this message translates to:
  /// **'Файл слишком большой: {name}'**
  String meeting_file_too_large(String name);

  /// No description provided for @meeting_send_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить: {details}'**
  String meeting_send_failed(String details);

  /// No description provided for @meeting_edit_message_title.
  ///
  /// In ru, this message translates to:
  /// **'Изменить сообщение'**
  String get meeting_edit_message_title;

  /// No description provided for @meeting_save_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить: {details}'**
  String meeting_save_failed(String details);

  /// No description provided for @meeting_delete_message_title.
  ///
  /// In ru, this message translates to:
  /// **'Удалить сообщение?'**
  String get meeting_delete_message_title;

  /// No description provided for @meeting_delete_message_body.
  ///
  /// In ru, this message translates to:
  /// **'Участники увидят «Сообщение удалено».'**
  String get meeting_delete_message_body;

  /// No description provided for @meeting_delete_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось удалить: {details}'**
  String meeting_delete_failed(String details);

  /// No description provided for @meeting_message_hint.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение…'**
  String get meeting_message_hint;

  /// No description provided for @meeting_message_deleted.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение удалено'**
  String get meeting_message_deleted;

  /// No description provided for @meeting_message_edited.
  ///
  /// In ru, this message translates to:
  /// **'• изм.'**
  String get meeting_message_edited;

  /// No description provided for @meeting_copy_action.
  ///
  /// In ru, this message translates to:
  /// **'Копировать'**
  String get meeting_copy_action;

  /// No description provided for @meeting_edit_action.
  ///
  /// In ru, this message translates to:
  /// **'Изменить'**
  String get meeting_edit_action;

  /// No description provided for @meeting_join_title.
  ///
  /// In ru, this message translates to:
  /// **'Присоединиться'**
  String get meeting_join_title;

  /// No description provided for @meeting_loading_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки митинга: {details}'**
  String meeting_loading_error(String details);

  /// No description provided for @meeting_not_found.
  ///
  /// In ru, this message translates to:
  /// **'Митинг не найден или закрыт'**
  String get meeting_not_found;

  /// No description provided for @meeting_private_description.
  ///
  /// In ru, this message translates to:
  /// **'Приватная встреча: после заявки хост решит, пустить ли вас.'**
  String get meeting_private_description;

  /// No description provided for @meeting_public_description.
  ///
  /// In ru, this message translates to:
  /// **'Открытая встреча: присоединяйтесь по ссылке без ожидания.'**
  String get meeting_public_description;

  /// No description provided for @meeting_your_name_label.
  ///
  /// In ru, this message translates to:
  /// **'Ваше имя'**
  String get meeting_your_name_label;

  /// No description provided for @meeting_enter_name_error.
  ///
  /// In ru, this message translates to:
  /// **'Укажите имя'**
  String get meeting_enter_name_error;

  /// No description provided for @meeting_guest_name.
  ///
  /// In ru, this message translates to:
  /// **'Гость'**
  String get meeting_guest_name;

  /// No description provided for @meeting_enter_room.
  ///
  /// In ru, this message translates to:
  /// **'Войти в комнату'**
  String get meeting_enter_room;

  /// No description provided for @meeting_request_join.
  ///
  /// In ru, this message translates to:
  /// **'Попросить присоединиться'**
  String get meeting_request_join;

  /// No description provided for @meeting_approved_title.
  ///
  /// In ru, this message translates to:
  /// **'Одобрено'**
  String get meeting_approved_title;

  /// No description provided for @meeting_approved_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Перенаправляем в комнату…'**
  String get meeting_approved_subtitle;

  /// No description provided for @meeting_denied_title.
  ///
  /// In ru, this message translates to:
  /// **'Отклонено'**
  String get meeting_denied_title;

  /// No description provided for @meeting_denied_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Хост отклонил вашу заявку.'**
  String get meeting_denied_subtitle;

  /// No description provided for @meeting_pending_title.
  ///
  /// In ru, this message translates to:
  /// **'Ожидаем подтверждения'**
  String get meeting_pending_title;

  /// No description provided for @meeting_pending_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Хост увидит вашу заявку и решит, когда впустить.'**
  String get meeting_pending_subtitle;

  /// No description provided for @meeting_load_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить митинг: {details}'**
  String meeting_load_error(String details);

  /// No description provided for @meeting_init_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка инициализации: {error}'**
  String meeting_init_error(Object error);

  /// No description provided for @meeting_participants_error.
  ///
  /// In ru, this message translates to:
  /// **'Участники: {error}'**
  String meeting_participants_error(Object error);

  /// No description provided for @meeting_bg_unavailable.
  ///
  /// In ru, this message translates to:
  /// **'Фон недоступен: {error}'**
  String meeting_bg_unavailable(Object error);

  /// No description provided for @meeting_leave.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get meeting_leave;

  /// No description provided for @meeting_screen_share_ios.
  ///
  /// In ru, this message translates to:
  /// **'Демонстрация экрана на iOS требует Broadcast Extension (будет в следующем релизе)'**
  String get meeting_screen_share_ios;

  /// No description provided for @meeting_screen_share_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось запустить демонстрацию: {details}'**
  String meeting_screen_share_failed(String details);

  /// No description provided for @meeting_tooltip_speaker_mode.
  ///
  /// In ru, this message translates to:
  /// **'Режим спикера'**
  String get meeting_tooltip_speaker_mode;

  /// No description provided for @meeting_tooltip_grid_mode.
  ///
  /// In ru, this message translates to:
  /// **'Режим сетки'**
  String get meeting_tooltip_grid_mode;

  /// No description provided for @meeting_tooltip_copy_link.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать ссылку (вход с браузера)'**
  String get meeting_tooltip_copy_link;

  /// No description provided for @meeting_mic_on.
  ///
  /// In ru, this message translates to:
  /// **'Включить'**
  String get meeting_mic_on;

  /// No description provided for @meeting_mic_off.
  ///
  /// In ru, this message translates to:
  /// **'Выключить'**
  String get meeting_mic_off;

  /// No description provided for @meeting_camera_on.
  ///
  /// In ru, this message translates to:
  /// **'Камера вкл'**
  String get meeting_camera_on;

  /// No description provided for @meeting_camera_off.
  ///
  /// In ru, this message translates to:
  /// **'Камера выкл'**
  String get meeting_camera_off;

  /// No description provided for @meeting_switch_camera.
  ///
  /// In ru, this message translates to:
  /// **'Сменить'**
  String get meeting_switch_camera;

  /// No description provided for @meeting_hand_lower.
  ///
  /// In ru, this message translates to:
  /// **'Опустить'**
  String get meeting_hand_lower;

  /// No description provided for @meeting_hand_raise.
  ///
  /// In ru, this message translates to:
  /// **'Рука'**
  String get meeting_hand_raise;

  /// No description provided for @meeting_reaction.
  ///
  /// In ru, this message translates to:
  /// **'Реакция'**
  String get meeting_reaction;

  /// No description provided for @meeting_screen_stop.
  ///
  /// In ru, this message translates to:
  /// **'Стоп'**
  String get meeting_screen_stop;

  /// No description provided for @meeting_screen_label.
  ///
  /// In ru, this message translates to:
  /// **'Экран'**
  String get meeting_screen_label;

  /// No description provided for @meeting_bg_off.
  ///
  /// In ru, this message translates to:
  /// **'Фон'**
  String get meeting_bg_off;

  /// No description provided for @meeting_bg_blur.
  ///
  /// In ru, this message translates to:
  /// **'Размытие'**
  String get meeting_bg_blur;

  /// No description provided for @meeting_bg_image.
  ///
  /// In ru, this message translates to:
  /// **'Картинка'**
  String get meeting_bg_image;

  /// No description provided for @meeting_participants_button.
  ///
  /// In ru, this message translates to:
  /// **'Участники'**
  String get meeting_participants_button;

  /// No description provided for @meeting_notifications_button.
  ///
  /// In ru, this message translates to:
  /// **'Активность'**
  String get meeting_notifications_button;

  /// No description provided for @meeting_pip_button.
  ///
  /// In ru, this message translates to:
  /// **'Свернуть'**
  String get meeting_pip_button;

  /// No description provided for @settings_chats_bottom_nav_icons_title.
  ///
  /// In ru, this message translates to:
  /// **'Иконки нижнего меню'**
  String get settings_chats_bottom_nav_icons_title;

  /// No description provided for @settings_chats_bottom_nav_icons_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Выбор иконок и визуального стиля как на вебе.'**
  String get settings_chats_bottom_nav_icons_subtitle;

  /// No description provided for @settings_chats_nav_colorful.
  ///
  /// In ru, this message translates to:
  /// **'Цветные'**
  String get settings_chats_nav_colorful;

  /// No description provided for @settings_chats_nav_minimal.
  ///
  /// In ru, this message translates to:
  /// **'Минимализм'**
  String get settings_chats_nav_minimal;

  /// No description provided for @settings_chats_nav_global_title.
  ///
  /// In ru, this message translates to:
  /// **'Для всех иконок'**
  String get settings_chats_nav_global_title;

  /// No description provided for @settings_chats_nav_global_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Общий слой: цвет, размер, толщина и фон плитки.'**
  String get settings_chats_nav_global_subtitle;

  /// No description provided for @settings_chats_reset_tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Сброс'**
  String get settings_chats_reset_tooltip;

  /// No description provided for @settings_chats_collapse.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть'**
  String get settings_chats_collapse;

  /// No description provided for @settings_chats_customize.
  ///
  /// In ru, this message translates to:
  /// **'Настроить'**
  String get settings_chats_customize;

  /// No description provided for @settings_chats_reset_item_tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить'**
  String get settings_chats_reset_item_tooltip;

  /// No description provided for @settings_chats_style_tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Стиль'**
  String get settings_chats_style_tooltip;

  /// No description provided for @settings_chats_icon_size.
  ///
  /// In ru, this message translates to:
  /// **'Размер иконки'**
  String get settings_chats_icon_size;

  /// No description provided for @settings_chats_stroke_width.
  ///
  /// In ru, this message translates to:
  /// **'Толщина линии'**
  String get settings_chats_stroke_width;

  /// No description provided for @settings_chats_default.
  ///
  /// In ru, this message translates to:
  /// **'По умолчанию'**
  String get settings_chats_default;

  /// No description provided for @settings_chats_icon_search_hint_en.
  ///
  /// In ru, this message translates to:
  /// **'Поиск по названию (англ.)...'**
  String get settings_chats_icon_search_hint_en;

  /// No description provided for @settings_chats_emoji_effects.
  ///
  /// In ru, this message translates to:
  /// **'Эффекты эмодзи'**
  String get settings_chats_emoji_effects;

  /// No description provided for @settings_chats_emoji_effects_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Профиль анимации fullscreen-эмодзи при тапе по одиночному эмодзи в чате.'**
  String get settings_chats_emoji_effects_subtitle;

  /// No description provided for @settings_chats_emoji_lite_desc.
  ///
  /// In ru, this message translates to:
  /// **'Lite: минимум нагрузки и максимально плавно на слабых устройствах.'**
  String get settings_chats_emoji_lite_desc;

  /// No description provided for @settings_chats_emoji_balanced_desc.
  ///
  /// In ru, this message translates to:
  /// **'Balanced: автоматический компромисс между производительностью и выразительностью.'**
  String get settings_chats_emoji_balanced_desc;

  /// No description provided for @settings_chats_emoji_cinematic_desc.
  ///
  /// In ru, this message translates to:
  /// **'Cinematic: максимум частиц и глубины для вау-эффекта.'**
  String get settings_chats_emoji_cinematic_desc;

  /// No description provided for @settings_chats_preview_incoming_msg.
  ///
  /// In ru, this message translates to:
  /// **'Привет! Как дела?'**
  String get settings_chats_preview_incoming_msg;

  /// No description provided for @settings_chats_preview_outgoing_msg.
  ///
  /// In ru, this message translates to:
  /// **'Отлично, спасибо!'**
  String get settings_chats_preview_outgoing_msg;

  /// No description provided for @settings_chats_preview_hello.
  ///
  /// In ru, this message translates to:
  /// **'Привет'**
  String get settings_chats_preview_hello;

  /// No description provided for @chat_theme_title.
  ///
  /// In ru, this message translates to:
  /// **'Тема чата'**
  String get chat_theme_title;

  /// No description provided for @chat_theme_error_save.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить фон: {error}'**
  String chat_theme_error_save(String error);

  /// No description provided for @chat_theme_error_upload.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки фона: {error}'**
  String chat_theme_error_upload(String error);

  /// No description provided for @chat_theme_delete_title.
  ///
  /// In ru, this message translates to:
  /// **'Удалить фон из галереи?'**
  String get chat_theme_delete_title;

  /// No description provided for @chat_theme_delete_body.
  ///
  /// In ru, this message translates to:
  /// **'Изображение пропадёт из списка своих фонов. Для этого чата можно выбрать другой.'**
  String get chat_theme_delete_body;

  /// No description provided for @chat_theme_error_delete.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка удаления: {error}'**
  String chat_theme_error_delete(String error);

  /// No description provided for @chat_theme_banner.
  ///
  /// In ru, this message translates to:
  /// **'Фон этой переписки только для вас. Общие настройки чатов в разделе «Настройки чатов» не меняются.'**
  String get chat_theme_banner;

  /// No description provided for @chat_theme_current_bg.
  ///
  /// In ru, this message translates to:
  /// **'Текущий фон'**
  String get chat_theme_current_bg;

  /// No description provided for @chat_theme_default_global.
  ///
  /// In ru, this message translates to:
  /// **'По умолчанию (общие настройки)'**
  String get chat_theme_default_global;

  /// No description provided for @chat_theme_presets.
  ///
  /// In ru, this message translates to:
  /// **'Пресеты'**
  String get chat_theme_presets;

  /// No description provided for @chat_theme_global_tile.
  ///
  /// In ru, this message translates to:
  /// **'Общие'**
  String get chat_theme_global_tile;

  /// No description provided for @chat_theme_pick_hint.
  ///
  /// In ru, this message translates to:
  /// **'Выберите пресет или фото из галереи'**
  String get chat_theme_pick_hint;

  /// No description provided for @contacts_title.
  ///
  /// In ru, this message translates to:
  /// **'Контакты'**
  String get contacts_title;

  /// No description provided for @contacts_add_phone_prompt.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте телефон в профиле, чтобы искать контакты по номеру.'**
  String get contacts_add_phone_prompt;

  /// No description provided for @contacts_fallback_profile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get contacts_fallback_profile;

  /// No description provided for @contacts_fallback_user.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь'**
  String get contacts_fallback_user;

  /// No description provided for @contacts_status_online.
  ///
  /// In ru, this message translates to:
  /// **'онлайн'**
  String get contacts_status_online;

  /// No description provided for @contacts_status_recently.
  ///
  /// In ru, this message translates to:
  /// **'Был (а) недавно'**
  String get contacts_status_recently;

  /// No description provided for @contacts_status_today_at.
  ///
  /// In ru, this message translates to:
  /// **'Был (а) в {time}'**
  String contacts_status_today_at(String time);

  /// No description provided for @contacts_status_yesterday.
  ///
  /// In ru, this message translates to:
  /// **'Был (а) вчера'**
  String get contacts_status_yesterday;

  /// No description provided for @contacts_status_year_ago.
  ///
  /// In ru, this message translates to:
  /// **'Был (а) год назад'**
  String get contacts_status_year_ago;

  /// No description provided for @contacts_status_years_ago.
  ///
  /// In ru, this message translates to:
  /// **'Был (а) {years} назад'**
  String contacts_status_years_ago(String years);

  /// No description provided for @contacts_status_date.
  ///
  /// In ru, this message translates to:
  /// **'Был (а) {date}'**
  String contacts_status_date(String date);

  /// No description provided for @contacts_empty_state.
  ///
  /// In ru, this message translates to:
  /// **'Контакты не найдены.\nНажмите кнопку справа, чтобы синхронизировать телефонную книгу.'**
  String get contacts_empty_state;

  /// No description provided for @add_contact_title.
  ///
  /// In ru, this message translates to:
  /// **'Новый контакт'**
  String get add_contact_title;

  /// No description provided for @add_contact_sync_off.
  ///
  /// In ru, this message translates to:
  /// **'Синхронизация выключена в приложении.'**
  String get add_contact_sync_off;

  /// No description provided for @add_contact_enable_system_access.
  ///
  /// In ru, this message translates to:
  /// **'Включите доступ к контактам для LighChat в настройках системы.'**
  String get add_contact_enable_system_access;

  /// No description provided for @add_contact_sync_on.
  ///
  /// In ru, this message translates to:
  /// **'Синхронизация включена'**
  String get add_contact_sync_on;

  /// No description provided for @add_contact_sync_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось включить синхронизацию контактов'**
  String get add_contact_sync_failed;

  /// No description provided for @add_contact_invalid_phone.
  ///
  /// In ru, this message translates to:
  /// **'Введите корректный номер телефона'**
  String get add_contact_invalid_phone;

  /// No description provided for @add_contact_not_found_by_phone.
  ///
  /// In ru, this message translates to:
  /// **'Контакт по этому номеру не найден'**
  String get add_contact_not_found_by_phone;

  /// No description provided for @add_contact_found.
  ///
  /// In ru, this message translates to:
  /// **'Контакт найден'**
  String get add_contact_found;

  /// No description provided for @add_contact_search_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выполнить поиск: {error}'**
  String add_contact_search_error(String error);

  /// No description provided for @add_contact_qr_no_profile.
  ///
  /// In ru, this message translates to:
  /// **'QR-код не содержит профиль LighChat'**
  String get add_contact_qr_no_profile;

  /// No description provided for @add_contact_qr_own_profile.
  ///
  /// In ru, this message translates to:
  /// **'Это ваш собственный профиль'**
  String get add_contact_qr_own_profile;

  /// No description provided for @add_contact_qr_profile_not_found.
  ///
  /// In ru, this message translates to:
  /// **'Профиль из QR-кода не найден'**
  String get add_contact_qr_profile_not_found;

  /// No description provided for @add_contact_qr_found.
  ///
  /// In ru, this message translates to:
  /// **'Контакт найден по QR-коду'**
  String get add_contact_qr_found;

  /// No description provided for @add_contact_qr_read_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось прочитать QR-код: {error}'**
  String add_contact_qr_read_error(String error);

  /// No description provided for @add_contact_cannot_add_user.
  ///
  /// In ru, this message translates to:
  /// **'Нельзя добавить этого пользователя'**
  String get add_contact_cannot_add_user;

  /// No description provided for @add_contact_add_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось добавить контакт: {error}'**
  String add_contact_add_error(String error);

  /// No description provided for @add_contact_country_search_hint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск страны или кода'**
  String get add_contact_country_search_hint;

  /// No description provided for @add_contact_sync_with_phone.
  ///
  /// In ru, this message translates to:
  /// **'Синхронизировать с телефоном'**
  String get add_contact_sync_with_phone;

  /// No description provided for @add_contact_add_by_qr.
  ///
  /// In ru, this message translates to:
  /// **'Добавить по QR-коду'**
  String get add_contact_add_by_qr;

  /// No description provided for @add_contact_results_unavailable.
  ///
  /// In ru, this message translates to:
  /// **'Результаты пока недоступны'**
  String get add_contact_results_unavailable;

  /// No description provided for @add_contact_profile_load_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки контакта: {error}'**
  String add_contact_profile_load_error(String error);

  /// No description provided for @add_contact_profile_not_found.
  ///
  /// In ru, this message translates to:
  /// **'Профиль не найден'**
  String get add_contact_profile_not_found;

  /// No description provided for @add_contact_badge_already_added.
  ///
  /// In ru, this message translates to:
  /// **'Уже в контактах'**
  String get add_contact_badge_already_added;

  /// No description provided for @add_contact_badge_new.
  ///
  /// In ru, this message translates to:
  /// **'Новый контакт'**
  String get add_contact_badge_new;

  /// No description provided for @add_contact_badge_unavailable.
  ///
  /// In ru, this message translates to:
  /// **'Недоступно'**
  String get add_contact_badge_unavailable;

  /// No description provided for @add_contact_open_contact.
  ///
  /// In ru, this message translates to:
  /// **'Открыть контакт'**
  String get add_contact_open_contact;

  /// No description provided for @add_contact_add_to_contacts.
  ///
  /// In ru, this message translates to:
  /// **'Добавить в контакты'**
  String get add_contact_add_to_contacts;

  /// No description provided for @add_contact_add_unavailable.
  ///
  /// In ru, this message translates to:
  /// **'Добавление недоступно'**
  String get add_contact_add_unavailable;

  /// No description provided for @add_contact_searching.
  ///
  /// In ru, this message translates to:
  /// **'Ищем контакт...'**
  String get add_contact_searching;

  /// No description provided for @add_contact_scan_qr_title.
  ///
  /// In ru, this message translates to:
  /// **'Сканировать QR-код'**
  String get add_contact_scan_qr_title;

  /// No description provided for @add_contact_flash_tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Вспышка'**
  String get add_contact_flash_tooltip;

  /// No description provided for @add_contact_scan_qr_hint.
  ///
  /// In ru, this message translates to:
  /// **'Наведите камеру на QR-код профиля LighChat'**
  String get add_contact_scan_qr_hint;

  /// No description provided for @contacts_edit_enter_name.
  ///
  /// In ru, this message translates to:
  /// **'Введите имя контакта.'**
  String get contacts_edit_enter_name;

  /// No description provided for @contacts_edit_save_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить контакт: {error}'**
  String contacts_edit_save_error(String error);

  /// No description provided for @contacts_edit_first_name_hint.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get contacts_edit_first_name_hint;

  /// No description provided for @contacts_edit_last_name_hint.
  ///
  /// In ru, this message translates to:
  /// **'Фамилия'**
  String get contacts_edit_last_name_hint;

  /// No description provided for @contacts_edit_name_disclaimer.
  ///
  /// In ru, this message translates to:
  /// **'Это имя видно только вам: в чатах, поиске и списке контактов.'**
  String get contacts_edit_name_disclaimer;

  /// No description provided for @contacts_edit_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка: {error}'**
  String contacts_edit_error(String error);

  /// No description provided for @chat_settings_color_default.
  ///
  /// In ru, this message translates to:
  /// **'По умолчанию'**
  String get chat_settings_color_default;

  /// No description provided for @chat_settings_color_lilac.
  ///
  /// In ru, this message translates to:
  /// **'Лиловый'**
  String get chat_settings_color_lilac;

  /// No description provided for @chat_settings_color_pink.
  ///
  /// In ru, this message translates to:
  /// **'Розовый'**
  String get chat_settings_color_pink;

  /// No description provided for @chat_settings_color_green.
  ///
  /// In ru, this message translates to:
  /// **'Зелёный'**
  String get chat_settings_color_green;

  /// No description provided for @chat_settings_color_coral.
  ///
  /// In ru, this message translates to:
  /// **'Коралловый'**
  String get chat_settings_color_coral;

  /// No description provided for @chat_settings_color_mint.
  ///
  /// In ru, this message translates to:
  /// **'Мята'**
  String get chat_settings_color_mint;

  /// No description provided for @chat_settings_color_sky.
  ///
  /// In ru, this message translates to:
  /// **'Небесный'**
  String get chat_settings_color_sky;

  /// No description provided for @chat_settings_color_purple.
  ///
  /// In ru, this message translates to:
  /// **'Фиолетовый'**
  String get chat_settings_color_purple;

  /// No description provided for @chat_settings_color_crimson.
  ///
  /// In ru, this message translates to:
  /// **'Малиновый'**
  String get chat_settings_color_crimson;

  /// No description provided for @chat_settings_color_tiffany.
  ///
  /// In ru, this message translates to:
  /// **'Тифани'**
  String get chat_settings_color_tiffany;

  /// No description provided for @chat_settings_color_yellow.
  ///
  /// In ru, this message translates to:
  /// **'Жёлтый'**
  String get chat_settings_color_yellow;

  /// No description provided for @chat_settings_color_powder.
  ///
  /// In ru, this message translates to:
  /// **'Пудра'**
  String get chat_settings_color_powder;

  /// No description provided for @chat_settings_color_turquoise.
  ///
  /// In ru, this message translates to:
  /// **'Бирюза'**
  String get chat_settings_color_turquoise;

  /// No description provided for @chat_settings_color_blue.
  ///
  /// In ru, this message translates to:
  /// **'Голубой'**
  String get chat_settings_color_blue;

  /// No description provided for @chat_settings_color_sunset.
  ///
  /// In ru, this message translates to:
  /// **'Закат'**
  String get chat_settings_color_sunset;

  /// No description provided for @chat_settings_color_tender.
  ///
  /// In ru, this message translates to:
  /// **'Нежный'**
  String get chat_settings_color_tender;

  /// No description provided for @chat_settings_color_lime.
  ///
  /// In ru, this message translates to:
  /// **'Лайм'**
  String get chat_settings_color_lime;

  /// No description provided for @chat_settings_color_graphite.
  ///
  /// In ru, this message translates to:
  /// **'Графит'**
  String get chat_settings_color_graphite;

  /// No description provided for @chat_settings_color_no_bg.
  ///
  /// In ru, this message translates to:
  /// **'Без фона'**
  String get chat_settings_color_no_bg;

  /// No description provided for @chat_settings_icon_color.
  ///
  /// In ru, this message translates to:
  /// **'Цвет иконки'**
  String get chat_settings_icon_color;

  /// No description provided for @chat_settings_icon_size.
  ///
  /// In ru, this message translates to:
  /// **'Размер иконки'**
  String get chat_settings_icon_size;

  /// No description provided for @chat_settings_stroke_width.
  ///
  /// In ru, this message translates to:
  /// **'Толщина линии'**
  String get chat_settings_stroke_width;

  /// No description provided for @chat_settings_tile_background.
  ///
  /// In ru, this message translates to:
  /// **'Фон плитки под иконкой'**
  String get chat_settings_tile_background;

  /// No description provided for @chat_settings_bottom_nav_icons.
  ///
  /// In ru, this message translates to:
  /// **'Иконки нижнего меню'**
  String get chat_settings_bottom_nav_icons;

  /// No description provided for @chat_settings_bottom_nav_description.
  ///
  /// In ru, this message translates to:
  /// **'Выбор иконок и визуального стиля как на вебе.'**
  String get chat_settings_bottom_nav_description;

  /// No description provided for @chat_settings_bottom_nav_global_description.
  ///
  /// In ru, this message translates to:
  /// **'Общий слой: цвет, размер, толщина и фон плитки.'**
  String get chat_settings_bottom_nav_global_description;

  /// No description provided for @chat_settings_colorful.
  ///
  /// In ru, this message translates to:
  /// **'Цветные'**
  String get chat_settings_colorful;

  /// No description provided for @chat_settings_minimalism.
  ///
  /// In ru, this message translates to:
  /// **'Минимализм'**
  String get chat_settings_minimalism;

  /// No description provided for @chat_settings_for_all_icons.
  ///
  /// In ru, this message translates to:
  /// **'Для всех иконок'**
  String get chat_settings_for_all_icons;

  /// No description provided for @chat_settings_customize.
  ///
  /// In ru, this message translates to:
  /// **'Настроить'**
  String get chat_settings_customize;

  /// No description provided for @chat_settings_hide.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть'**
  String get chat_settings_hide;

  /// No description provided for @chat_settings_reset.
  ///
  /// In ru, this message translates to:
  /// **'Сброс'**
  String get chat_settings_reset;

  /// No description provided for @chat_settings_reset_item.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить'**
  String get chat_settings_reset_item;

  /// No description provided for @chat_settings_style.
  ///
  /// In ru, this message translates to:
  /// **'Стиль'**
  String get chat_settings_style;

  /// No description provided for @chat_settings_select.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать'**
  String get chat_settings_select;

  /// No description provided for @chat_settings_reset_size.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить размер'**
  String get chat_settings_reset_size;

  /// No description provided for @chat_settings_reset_stroke.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить толщину'**
  String get chat_settings_reset_stroke;

  /// No description provided for @chat_settings_default_gradient.
  ///
  /// In ru, this message translates to:
  /// **'Градиент по умолчанию'**
  String get chat_settings_default_gradient;

  /// No description provided for @chat_settings_inherit_global.
  ///
  /// In ru, this message translates to:
  /// **'Наследовать от глобальных'**
  String get chat_settings_inherit_global;

  /// No description provided for @chat_settings_no_bg_on.
  ///
  /// In ru, this message translates to:
  /// **'Без фона (вкл.)'**
  String get chat_settings_no_bg_on;

  /// No description provided for @chat_settings_no_bg.
  ///
  /// In ru, this message translates to:
  /// **'Без фона'**
  String get chat_settings_no_bg;

  /// No description provided for @chat_settings_outgoing_messages.
  ///
  /// In ru, this message translates to:
  /// **'Исходящие сообщения'**
  String get chat_settings_outgoing_messages;

  /// No description provided for @chat_settings_incoming_messages.
  ///
  /// In ru, this message translates to:
  /// **'Входящие сообщения'**
  String get chat_settings_incoming_messages;

  /// No description provided for @chat_settings_font_size.
  ///
  /// In ru, this message translates to:
  /// **'Размер шрифта'**
  String get chat_settings_font_size;

  /// No description provided for @chat_settings_font_small.
  ///
  /// In ru, this message translates to:
  /// **'Мелкий'**
  String get chat_settings_font_small;

  /// No description provided for @chat_settings_font_medium.
  ///
  /// In ru, this message translates to:
  /// **'Средний'**
  String get chat_settings_font_medium;

  /// No description provided for @chat_settings_font_large.
  ///
  /// In ru, this message translates to:
  /// **'Крупный'**
  String get chat_settings_font_large;

  /// No description provided for @chat_settings_bubble_shape.
  ///
  /// In ru, this message translates to:
  /// **'Форма пузырьков'**
  String get chat_settings_bubble_shape;

  /// No description provided for @chat_settings_bubble_rounded.
  ///
  /// In ru, this message translates to:
  /// **'Округлённые'**
  String get chat_settings_bubble_rounded;

  /// No description provided for @chat_settings_bubble_square.
  ///
  /// In ru, this message translates to:
  /// **'Квадратные'**
  String get chat_settings_bubble_square;

  /// No description provided for @chat_settings_chat_background.
  ///
  /// In ru, this message translates to:
  /// **'Фон чата'**
  String get chat_settings_chat_background;

  /// No description provided for @chat_settings_background_hint.
  ///
  /// In ru, this message translates to:
  /// **'Выберите фото из галереи или настройте'**
  String get chat_settings_background_hint;

  /// No description provided for @chat_settings_builtin_wallpapers_heading.
  ///
  /// In ru, this message translates to:
  /// **'Фирменные обои'**
  String get chat_settings_builtin_wallpapers_heading;

  /// No description provided for @chat_settings_show_all_wallpapers.
  ///
  /// In ru, this message translates to:
  /// **'Показать все'**
  String get chat_settings_show_all_wallpapers;

  /// No description provided for @chat_settings_animated_wallpapers_heading.
  ///
  /// In ru, this message translates to:
  /// **'Анимированные обои'**
  String get chat_settings_animated_wallpapers_heading;

  /// No description provided for @chat_settings_animated_wallpapers_hint.
  ///
  /// In ru, this message translates to:
  /// **'Проигрывается один раз при открытии чата'**
  String get chat_settings_animated_wallpapers_hint;

  /// No description provided for @chat_settings_emoji_effects.
  ///
  /// In ru, this message translates to:
  /// **'Эффекты эмодзи'**
  String get chat_settings_emoji_effects;

  /// No description provided for @chat_settings_emoji_description.
  ///
  /// In ru, this message translates to:
  /// **'Профиль анимации fullscreen-эмодзи при тапе по одиночному эмодзи в чате.'**
  String get chat_settings_emoji_description;

  /// No description provided for @chat_settings_emoji_lite.
  ///
  /// In ru, this message translates to:
  /// **'Lite: минимум нагрузки и максимально плавно на слабых устройствах.'**
  String get chat_settings_emoji_lite;

  /// No description provided for @chat_settings_emoji_cinematic.
  ///
  /// In ru, this message translates to:
  /// **'Cinematic: максимум частиц и глубины для вау-эффекта.'**
  String get chat_settings_emoji_cinematic;

  /// No description provided for @chat_settings_emoji_balanced.
  ///
  /// In ru, this message translates to:
  /// **'Balanced: автоматический компромисс между производительностью и выразительностью.'**
  String get chat_settings_emoji_balanced;

  /// No description provided for @chat_settings_additional.
  ///
  /// In ru, this message translates to:
  /// **'Дополнительно'**
  String get chat_settings_additional;

  /// No description provided for @chat_settings_show_time.
  ///
  /// In ru, this message translates to:
  /// **'Показывать время'**
  String get chat_settings_show_time;

  /// No description provided for @chat_settings_show_time_hint.
  ///
  /// In ru, this message translates to:
  /// **'Время отправки под сообщениями'**
  String get chat_settings_show_time_hint;

  /// No description provided for @chat_settings_auto_translate.
  ///
  /// In ru, this message translates to:
  /// **'Авто-перевод входящих'**
  String get chat_settings_auto_translate;

  /// No description provided for @chat_settings_auto_translate_hint.
  ///
  /// In ru, this message translates to:
  /// **'Сообщения на других языках переводятся on-device на ваш язык'**
  String get chat_settings_auto_translate_hint;

  /// No description provided for @message_auto_translated_label.
  ///
  /// In ru, this message translates to:
  /// **'Переведено'**
  String get message_auto_translated_label;

  /// No description provided for @message_show_original.
  ///
  /// In ru, this message translates to:
  /// **'Показать оригинал'**
  String get message_show_original;

  /// No description provided for @message_show_translation.
  ///
  /// In ru, this message translates to:
  /// **'Показать перевод'**
  String get message_show_translation;

  /// No description provided for @chat_settings_reset_all.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить настройки'**
  String get chat_settings_reset_all;

  /// No description provided for @chat_settings_preview_incoming.
  ///
  /// In ru, this message translates to:
  /// **'Привет! Как дела?'**
  String get chat_settings_preview_incoming;

  /// No description provided for @chat_settings_preview_outgoing.
  ///
  /// In ru, this message translates to:
  /// **'Отлично, спасибо!'**
  String get chat_settings_preview_outgoing;

  /// No description provided for @chat_settings_preview_hello.
  ///
  /// In ru, this message translates to:
  /// **'Привет'**
  String get chat_settings_preview_hello;

  /// No description provided for @chat_settings_icon_picker_title.
  ///
  /// In ru, this message translates to:
  /// **'Иконка: «{label}»'**
  String chat_settings_icon_picker_title(String label);

  /// No description provided for @chat_settings_search_hint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск по названию (англ.)...'**
  String get chat_settings_search_hint;

  /// No description provided for @meeting_tab_participants.
  ///
  /// In ru, this message translates to:
  /// **'Участники ({count})'**
  String meeting_tab_participants(Object count);

  /// No description provided for @meeting_tab_polls.
  ///
  /// In ru, this message translates to:
  /// **'Опросы'**
  String get meeting_tab_polls;

  /// No description provided for @meeting_tab_polls_count.
  ///
  /// In ru, this message translates to:
  /// **'Опросы ({count})'**
  String meeting_tab_polls_count(Object count);

  /// No description provided for @meeting_tab_chat.
  ///
  /// In ru, this message translates to:
  /// **'Чат'**
  String get meeting_tab_chat;

  /// No description provided for @meeting_tab_chat_count.
  ///
  /// In ru, this message translates to:
  /// **'Чат ({count})'**
  String meeting_tab_chat_count(Object count);

  /// No description provided for @meeting_tab_requests.
  ///
  /// In ru, this message translates to:
  /// **'Заявки ({count})'**
  String meeting_tab_requests(Object count);

  /// No description provided for @meeting_kick.
  ///
  /// In ru, this message translates to:
  /// **'Удалить из комнаты'**
  String get meeting_kick;

  /// No description provided for @meeting_file_too_big.
  ///
  /// In ru, this message translates to:
  /// **'Файл слишком большой: {name}'**
  String meeting_file_too_big(Object name);

  /// No description provided for @meeting_send_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить: {error}'**
  String meeting_send_error(Object error);

  /// No description provided for @meeting_save_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить: {error}'**
  String meeting_save_error(Object error);

  /// No description provided for @meeting_delete_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось удалить: {error}'**
  String meeting_delete_error(Object error);

  /// No description provided for @meeting_no_messages.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет сообщений'**
  String get meeting_no_messages;

  /// No description provided for @meeting_join_enter_name.
  ///
  /// In ru, this message translates to:
  /// **'Укажите имя'**
  String get meeting_join_enter_name;

  /// No description provided for @meeting_join_guest.
  ///
  /// In ru, this message translates to:
  /// **'Гость'**
  String get meeting_join_guest;

  /// No description provided for @meeting_join_as_label.
  ///
  /// In ru, this message translates to:
  /// **'Вы войдёте как'**
  String get meeting_join_as_label;

  /// No description provided for @meeting_lobby_camera_blocked.
  ///
  /// In ru, this message translates to:
  /// **'Доступ к камере не выдан. Вы войдёте с выключенной камерой.'**
  String get meeting_lobby_camera_blocked;

  /// No description provided for @meeting_join_button.
  ///
  /// In ru, this message translates to:
  /// **'Присоединиться'**
  String get meeting_join_button;

  /// No description provided for @meeting_join_load_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки митинга: {error}'**
  String meeting_join_load_error(Object error);

  /// No description provided for @meeting_private_hint.
  ///
  /// In ru, this message translates to:
  /// **'Приватная встреча: после заявки хост решит, пустить ли вас.'**
  String get meeting_private_hint;

  /// No description provided for @meeting_public_hint.
  ///
  /// In ru, this message translates to:
  /// **'Открытая встреча: присоединяйтесь по ссылке без ожидания.'**
  String get meeting_public_hint;

  /// No description provided for @meeting_name_label.
  ///
  /// In ru, this message translates to:
  /// **'Ваше имя'**
  String get meeting_name_label;

  /// No description provided for @meeting_waiting_title.
  ///
  /// In ru, this message translates to:
  /// **'Ожидаем подтверждения'**
  String get meeting_waiting_title;

  /// No description provided for @meeting_waiting_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Хост увидит вашу заявку и решит, когда впустить.'**
  String get meeting_waiting_subtitle;

  /// No description provided for @meeting_screen_share_ios_hint.
  ///
  /// In ru, this message translates to:
  /// **'Демонстрация экрана на iOS требует Broadcast Extension (в разработке).'**
  String get meeting_screen_share_ios_hint;

  /// No description provided for @meeting_screen_share_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось запустить демонстрацию: {error}'**
  String meeting_screen_share_error(Object error);

  /// No description provided for @meeting_speaker_mode.
  ///
  /// In ru, this message translates to:
  /// **'Режим спикера'**
  String get meeting_speaker_mode;

  /// No description provided for @meeting_grid_mode.
  ///
  /// In ru, this message translates to:
  /// **'Режим сетки'**
  String get meeting_grid_mode;

  /// No description provided for @meeting_copy_link_tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать ссылку (вход с браузера)'**
  String get meeting_copy_link_tooltip;

  /// No description provided for @group_members_subtitle_creator.
  ///
  /// In ru, this message translates to:
  /// **'Создатель группы'**
  String get group_members_subtitle_creator;

  /// No description provided for @group_members_subtitle_admin.
  ///
  /// In ru, this message translates to:
  /// **'Администратор'**
  String get group_members_subtitle_admin;

  /// No description provided for @group_members_subtitle_member.
  ///
  /// In ru, this message translates to:
  /// **'Участник'**
  String get group_members_subtitle_member;

  /// No description provided for @group_members_total_count.
  ///
  /// In ru, this message translates to:
  /// **'Всего: {count}'**
  String group_members_total_count(int count);

  /// No description provided for @group_members_copy_invite_tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать ссылку-приглашение'**
  String get group_members_copy_invite_tooltip;

  /// No description provided for @group_members_add_member_tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Добавить участника'**
  String get group_members_add_member_tooltip;

  /// No description provided for @group_members_invite_copied.
  ///
  /// In ru, this message translates to:
  /// **'Ссылка-приглашение скопирована'**
  String get group_members_invite_copied;

  /// No description provided for @group_members_copy_link_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось скопировать ссылку: {error}'**
  String group_members_copy_link_error(String error);

  /// No description provided for @group_members_added.
  ///
  /// In ru, this message translates to:
  /// **'Участники добавлены'**
  String get group_members_added;

  /// No description provided for @group_members_revoke_admin_title.
  ///
  /// In ru, this message translates to:
  /// **'Снять права администратора?'**
  String get group_members_revoke_admin_title;

  /// No description provided for @group_members_revoke_admin_body.
  ///
  /// In ru, this message translates to:
  /// **'У {name} будут сняты права администратора. Участник останется в группе как обычный член.'**
  String group_members_revoke_admin_body(String name);

  /// No description provided for @group_members_grant_admin_title.
  ///
  /// In ru, this message translates to:
  /// **'Назначить администратором?'**
  String get group_members_grant_admin_title;

  /// No description provided for @group_members_grant_admin_body.
  ///
  /// In ru, this message translates to:
  /// **'{name} получит права администратора: сможет редактировать группу, исключать участников и управлять сообщениями.'**
  String group_members_grant_admin_body(String name);

  /// No description provided for @group_members_revoke_admin_action.
  ///
  /// In ru, this message translates to:
  /// **'Снять права'**
  String get group_members_revoke_admin_action;

  /// No description provided for @group_members_grant_admin_action.
  ///
  /// In ru, this message translates to:
  /// **'Назначить'**
  String get group_members_grant_admin_action;

  /// No description provided for @group_members_remove_title.
  ///
  /// In ru, this message translates to:
  /// **'Исключить участника?'**
  String get group_members_remove_title;

  /// No description provided for @group_members_remove_body.
  ///
  /// In ru, this message translates to:
  /// **'{name} будет удалён из группы. Это действие можно отменить, добавив участника заново.'**
  String group_members_remove_body(String name);

  /// No description provided for @group_members_remove_action.
  ///
  /// In ru, this message translates to:
  /// **'Исключить'**
  String get group_members_remove_action;

  /// No description provided for @group_members_removed.
  ///
  /// In ru, this message translates to:
  /// **'Участник исключён'**
  String get group_members_removed;

  /// No description provided for @group_members_menu_revoke_admin.
  ///
  /// In ru, this message translates to:
  /// **'Снять админа'**
  String get group_members_menu_revoke_admin;

  /// No description provided for @group_members_menu_grant_admin.
  ///
  /// In ru, this message translates to:
  /// **'Сделать админом'**
  String get group_members_menu_grant_admin;

  /// No description provided for @group_members_menu_remove.
  ///
  /// In ru, this message translates to:
  /// **'Исключить из группы'**
  String get group_members_menu_remove;

  /// No description provided for @group_members_creator_badge.
  ///
  /// In ru, this message translates to:
  /// **'СОЗДАТЕЛЬ'**
  String get group_members_creator_badge;

  /// No description provided for @group_members_add_title.
  ///
  /// In ru, this message translates to:
  /// **'Добавить участников'**
  String get group_members_add_title;

  /// No description provided for @group_members_search_contacts.
  ///
  /// In ru, this message translates to:
  /// **'Поиск среди контактов'**
  String get group_members_search_contacts;

  /// No description provided for @group_members_all_in_group.
  ///
  /// In ru, this message translates to:
  /// **'Все ваши контакты уже в группе.'**
  String get group_members_all_in_group;

  /// No description provided for @group_members_nobody_found.
  ///
  /// In ru, this message translates to:
  /// **'Никого не найдено.'**
  String get group_members_nobody_found;

  /// No description provided for @group_members_user_fallback.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь'**
  String get group_members_user_fallback;

  /// No description provided for @group_members_select_members.
  ///
  /// In ru, this message translates to:
  /// **'Выберите участников'**
  String get group_members_select_members;

  /// No description provided for @group_members_add_count.
  ///
  /// In ru, this message translates to:
  /// **'Добавить ({count})'**
  String group_members_add_count(int count);

  /// No description provided for @group_members_contacts_load_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить контакты: {error}'**
  String group_members_contacts_load_error(String error);

  /// No description provided for @group_members_auth_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка авторизации: {error}'**
  String group_members_auth_error(String error);

  /// No description provided for @group_members_add_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось добавить участников: {error}'**
  String group_members_add_failed(String error);

  /// No description provided for @group_not_found.
  ///
  /// In ru, this message translates to:
  /// **'Группа не найдена.'**
  String get group_not_found;

  /// No description provided for @group_not_member.
  ///
  /// In ru, this message translates to:
  /// **'Вы не являетесь участником этой группы.'**
  String get group_not_member;

  /// No description provided for @poll_create_title.
  ///
  /// In ru, this message translates to:
  /// **'Опрос в чате'**
  String get poll_create_title;

  /// No description provided for @poll_question_label.
  ///
  /// In ru, this message translates to:
  /// **'Вопрос'**
  String get poll_question_label;

  /// No description provided for @poll_question_hint.
  ///
  /// In ru, this message translates to:
  /// **'Например: Во сколько встречаемся?'**
  String get poll_question_hint;

  /// No description provided for @poll_description_label.
  ///
  /// In ru, this message translates to:
  /// **'Пояснение (необязательно)'**
  String get poll_description_label;

  /// No description provided for @poll_options_title.
  ///
  /// In ru, this message translates to:
  /// **'Варианты'**
  String get poll_options_title;

  /// No description provided for @poll_option_hint.
  ///
  /// In ru, this message translates to:
  /// **'Вариант {index}'**
  String poll_option_hint(int index);

  /// No description provided for @poll_add_option.
  ///
  /// In ru, this message translates to:
  /// **'Добавить вариант'**
  String get poll_add_option;

  /// No description provided for @poll_switch_anonymous.
  ///
  /// In ru, this message translates to:
  /// **'Анонимное голосование'**
  String get poll_switch_anonymous;

  /// No description provided for @poll_switch_anonymous_sub.
  ///
  /// In ru, this message translates to:
  /// **'Не показывать, кто за что голосовал'**
  String get poll_switch_anonymous_sub;

  /// No description provided for @poll_switch_multi.
  ///
  /// In ru, this message translates to:
  /// **'Несколько ответов'**
  String get poll_switch_multi;

  /// No description provided for @poll_switch_multi_sub.
  ///
  /// In ru, this message translates to:
  /// **'Можно выбрать несколько вариантов'**
  String get poll_switch_multi_sub;

  /// No description provided for @poll_switch_add_options.
  ///
  /// In ru, this message translates to:
  /// **'Добавление вариантов'**
  String get poll_switch_add_options;

  /// No description provided for @poll_switch_add_options_sub.
  ///
  /// In ru, this message translates to:
  /// **'Участники могут предложить свой вариант'**
  String get poll_switch_add_options_sub;

  /// No description provided for @poll_switch_revote.
  ///
  /// In ru, this message translates to:
  /// **'Можно изменить голос'**
  String get poll_switch_revote;

  /// No description provided for @poll_switch_revote_sub.
  ///
  /// In ru, this message translates to:
  /// **'Переголосование до закрытия'**
  String get poll_switch_revote_sub;

  /// No description provided for @poll_switch_shuffle.
  ///
  /// In ru, this message translates to:
  /// **'Перемешать варианты'**
  String get poll_switch_shuffle;

  /// No description provided for @poll_switch_shuffle_sub.
  ///
  /// In ru, this message translates to:
  /// **'Свой порядок у каждого участника'**
  String get poll_switch_shuffle_sub;

  /// No description provided for @poll_switch_quiz.
  ///
  /// In ru, this message translates to:
  /// **'Режим викторины'**
  String get poll_switch_quiz;

  /// No description provided for @poll_switch_quiz_sub.
  ///
  /// In ru, this message translates to:
  /// **'Один правильный ответ'**
  String get poll_switch_quiz_sub;

  /// No description provided for @poll_correct_option_label.
  ///
  /// In ru, this message translates to:
  /// **'Правильный вариант'**
  String get poll_correct_option_label;

  /// No description provided for @poll_quiz_explanation_label.
  ///
  /// In ru, this message translates to:
  /// **'Пояснение (необязательно)'**
  String get poll_quiz_explanation_label;

  /// No description provided for @poll_close_by_time.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть по времени'**
  String get poll_close_by_time;

  /// No description provided for @poll_close_not_set.
  ///
  /// In ru, this message translates to:
  /// **'Не задано'**
  String get poll_close_not_set;

  /// No description provided for @poll_close_reset.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить срок'**
  String get poll_close_reset;

  /// No description provided for @poll_publish.
  ///
  /// In ru, this message translates to:
  /// **'Опубликовать'**
  String get poll_publish;

  /// No description provided for @poll_error_empty_question.
  ///
  /// In ru, this message translates to:
  /// **'Введите вопрос'**
  String get poll_error_empty_question;

  /// No description provided for @poll_error_min_options.
  ///
  /// In ru, this message translates to:
  /// **'Нужно минимум 2 варианта'**
  String get poll_error_min_options;

  /// No description provided for @poll_error_select_correct.
  ///
  /// In ru, this message translates to:
  /// **'Выберите правильный вариант'**
  String get poll_error_select_correct;

  /// No description provided for @poll_error_future_time.
  ///
  /// In ru, this message translates to:
  /// **'Время закрытия должно быть в будущем'**
  String get poll_error_future_time;

  /// No description provided for @poll_unavailable.
  ///
  /// In ru, this message translates to:
  /// **'Опрос недоступен'**
  String get poll_unavailable;

  /// No description provided for @poll_loading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка опроса…'**
  String get poll_loading;

  /// No description provided for @poll_not_found.
  ///
  /// In ru, this message translates to:
  /// **'Опрос не найден'**
  String get poll_not_found;

  /// No description provided for @poll_status_cancelled.
  ///
  /// In ru, this message translates to:
  /// **'Отменён'**
  String get poll_status_cancelled;

  /// No description provided for @poll_status_ended.
  ///
  /// In ru, this message translates to:
  /// **'Завершён'**
  String get poll_status_ended;

  /// No description provided for @poll_status_draft.
  ///
  /// In ru, this message translates to:
  /// **'Черновик'**
  String get poll_status_draft;

  /// No description provided for @poll_status_active.
  ///
  /// In ru, this message translates to:
  /// **'Активен'**
  String get poll_status_active;

  /// No description provided for @poll_badge_public.
  ///
  /// In ru, this message translates to:
  /// **'Публично'**
  String get poll_badge_public;

  /// No description provided for @poll_badge_multi.
  ///
  /// In ru, this message translates to:
  /// **'Несколько ответов'**
  String get poll_badge_multi;

  /// No description provided for @poll_badge_quiz.
  ///
  /// In ru, this message translates to:
  /// **'Викторина'**
  String get poll_badge_quiz;

  /// No description provided for @poll_menu_restart.
  ///
  /// In ru, this message translates to:
  /// **'Перезапустить'**
  String get poll_menu_restart;

  /// No description provided for @poll_menu_end.
  ///
  /// In ru, this message translates to:
  /// **'Завершить'**
  String get poll_menu_end;

  /// No description provided for @poll_menu_delete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get poll_menu_delete;

  /// No description provided for @poll_submit_vote.
  ///
  /// In ru, this message translates to:
  /// **'Отправить голос'**
  String get poll_submit_vote;

  /// No description provided for @poll_suggest_option_hint.
  ///
  /// In ru, this message translates to:
  /// **'Предложить вариант'**
  String get poll_suggest_option_hint;

  /// No description provided for @poll_revote.
  ///
  /// In ru, this message translates to:
  /// **'Переголосовать'**
  String get poll_revote;

  /// No description provided for @poll_votes_count.
  ///
  /// In ru, this message translates to:
  /// **'{count} голосов'**
  String poll_votes_count(int count);

  /// No description provided for @poll_show_voters.
  ///
  /// In ru, this message translates to:
  /// **'Кто голосовал'**
  String get poll_show_voters;

  /// No description provided for @poll_hide_voters.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть'**
  String get poll_hide_voters;

  /// No description provided for @poll_vote_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка при голосовании'**
  String get poll_vote_error;

  /// No description provided for @poll_add_option_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось добавить вариант'**
  String get poll_add_option_error;

  /// No description provided for @poll_error_generic.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка'**
  String get poll_error_generic;

  /// No description provided for @durak_your_turn.
  ///
  /// In ru, this message translates to:
  /// **'Твой ход'**
  String get durak_your_turn;

  /// No description provided for @durak_winner_label.
  ///
  /// In ru, this message translates to:
  /// **'Победитель'**
  String get durak_winner_label;

  /// No description provided for @durak_rematch.
  ///
  /// In ru, this message translates to:
  /// **'Сыграть ещё раз'**
  String get durak_rematch;

  /// No description provided for @durak_surrender_tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Завершить игру'**
  String get durak_surrender_tooltip;

  /// No description provided for @durak_close_tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get durak_close_tooltip;

  /// No description provided for @durak_fx_took.
  ///
  /// In ru, this message translates to:
  /// **'Взял'**
  String get durak_fx_took;

  /// No description provided for @durak_fx_beat.
  ///
  /// In ru, this message translates to:
  /// **'Бито'**
  String get durak_fx_beat;

  /// No description provided for @durak_opponent_role_defend.
  ///
  /// In ru, this message translates to:
  /// **'БЬЕТ'**
  String get durak_opponent_role_defend;

  /// No description provided for @durak_opponent_role_attack.
  ///
  /// In ru, this message translates to:
  /// **'ХОД'**
  String get durak_opponent_role_attack;

  /// No description provided for @durak_opponent_role_throwin.
  ///
  /// In ru, this message translates to:
  /// **'ПОДК'**
  String get durak_opponent_role_throwin;

  /// No description provided for @durak_foul_banner_title.
  ///
  /// In ru, this message translates to:
  /// **'Шулер! Не заметили:'**
  String get durak_foul_banner_title;

  /// No description provided for @durak_pending_resolution_attacker.
  ///
  /// In ru, this message translates to:
  /// **'Ожидание фолла… Нажми «Подтвердить Бито», если все согласны.'**
  String get durak_pending_resolution_attacker;

  /// No description provided for @durak_pending_resolution_other.
  ///
  /// In ru, this message translates to:
  /// **'Ожидание фолла… Теперь можно нажать «Фолл!», если заметил шулерство.'**
  String get durak_pending_resolution_other;

  /// No description provided for @durak_tournament_played.
  ///
  /// In ru, this message translates to:
  /// **'Сыграно {finished} из {total}'**
  String durak_tournament_played(int finished, int total);

  /// No description provided for @durak_tournament_finished.
  ///
  /// In ru, this message translates to:
  /// **'Турнир завершён'**
  String get durak_tournament_finished;

  /// No description provided for @durak_tournament_next.
  ///
  /// In ru, this message translates to:
  /// **'Следующая партия турнира'**
  String get durak_tournament_next;

  /// No description provided for @durak_single_game.
  ///
  /// In ru, this message translates to:
  /// **'Одиночная партия'**
  String get durak_single_game;

  /// No description provided for @durak_tournament_total_games_title.
  ///
  /// In ru, this message translates to:
  /// **'Сколько игр в турнире?'**
  String get durak_tournament_total_games_title;

  /// No description provided for @durak_finish_game_tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Завершить игру'**
  String get durak_finish_game_tooltip;

  /// No description provided for @durak_lobby_game_unavailable.
  ///
  /// In ru, this message translates to:
  /// **'Игра недоступна или была удалена'**
  String get durak_lobby_game_unavailable;

  /// No description provided for @durak_lobby_back_tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get durak_lobby_back_tooltip;

  /// No description provided for @durak_lobby_waiting.
  ///
  /// In ru, this message translates to:
  /// **'Ожидание соперника…'**
  String get durak_lobby_waiting;

  /// No description provided for @durak_lobby_start.
  ///
  /// In ru, this message translates to:
  /// **'Начать игру'**
  String get durak_lobby_start;

  /// No description provided for @durak_lobby_waiting_short.
  ///
  /// In ru, this message translates to:
  /// **'Ждём…'**
  String get durak_lobby_waiting_short;

  /// No description provided for @durak_lobby_ready.
  ///
  /// In ru, this message translates to:
  /// **'Готов'**
  String get durak_lobby_ready;

  /// No description provided for @durak_lobby_empty_slot.
  ///
  /// In ru, this message translates to:
  /// **'Ждём…'**
  String get durak_lobby_empty_slot;

  /// No description provided for @durak_settings_timer_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'По умолчанию 15 секунд'**
  String get durak_settings_timer_subtitle;

  /// No description provided for @durak_dm_game_active.
  ///
  /// In ru, this message translates to:
  /// **'Партия \"Дурак\" идёт'**
  String get durak_dm_game_active;

  /// No description provided for @durak_dm_game_created.
  ///
  /// In ru, this message translates to:
  /// **'Игра \"Дурак\" создана'**
  String get durak_dm_game_created;

  /// No description provided for @game_durak_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Одиночная партия или турнир'**
  String get game_durak_subtitle;

  /// No description provided for @group_member_write_dm.
  ///
  /// In ru, this message translates to:
  /// **'Написать лично'**
  String get group_member_write_dm;

  /// No description provided for @group_member_open_dm_hint.
  ///
  /// In ru, this message translates to:
  /// **'Открыть личный чат с участником'**
  String get group_member_open_dm_hint;

  /// No description provided for @group_member_profile_not_loaded.
  ///
  /// In ru, this message translates to:
  /// **'Профиль участника ещё не загружен.'**
  String get group_member_profile_not_loaded;

  /// No description provided for @group_member_open_dm_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть личный чат: {error}'**
  String group_member_open_dm_error(String error);

  /// No description provided for @group_avatar_photo_title.
  ///
  /// In ru, this message translates to:
  /// **'Фото группы'**
  String get group_avatar_photo_title;

  /// No description provided for @group_avatar_add_photo.
  ///
  /// In ru, this message translates to:
  /// **'Добавить фото'**
  String get group_avatar_add_photo;

  /// No description provided for @group_avatar_change.
  ///
  /// In ru, this message translates to:
  /// **'Сменить аватар'**
  String get group_avatar_change;

  /// No description provided for @group_avatar_remove.
  ///
  /// In ru, this message translates to:
  /// **'Убрать аватар'**
  String get group_avatar_remove;

  /// No description provided for @group_avatar_process_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обработать фото: {error}'**
  String group_avatar_process_error(String error);

  /// No description provided for @group_mention_no_matches.
  ///
  /// In ru, this message translates to:
  /// **'Нет совпадений'**
  String get group_mention_no_matches;

  /// No description provided for @durak_error_defense_does_not_beat.
  ///
  /// In ru, this message translates to:
  /// **'Эта карта не бьет атакующую'**
  String get durak_error_defense_does_not_beat;

  /// No description provided for @durak_error_only_attacker_first.
  ///
  /// In ru, this message translates to:
  /// **'Первым ходит атакующий игрок'**
  String get durak_error_only_attacker_first;

  /// No description provided for @durak_error_defender_cannot_attack.
  ///
  /// In ru, this message translates to:
  /// **'Отбивающийся сейчас не подкидывает'**
  String get durak_error_defender_cannot_attack;

  /// No description provided for @durak_error_not_allowed_throwin.
  ///
  /// In ru, this message translates to:
  /// **'Вы не можете подкинуть в этом раунде'**
  String get durak_error_not_allowed_throwin;

  /// No description provided for @durak_error_throwin_not_your_turn.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас подкидывает другой игрок'**
  String get durak_error_throwin_not_your_turn;

  /// No description provided for @durak_error_rank_not_allowed.
  ///
  /// In ru, this message translates to:
  /// **'Подкинуть можно только карту того же ранга'**
  String get durak_error_rank_not_allowed;

  /// No description provided for @durak_error_cannot_throw_in.
  ///
  /// In ru, this message translates to:
  /// **'Больше карт подкинуть нельзя'**
  String get durak_error_cannot_throw_in;

  /// No description provided for @durak_error_card_not_in_hand.
  ///
  /// In ru, this message translates to:
  /// **'Этой карты уже нет в руке'**
  String get durak_error_card_not_in_hand;

  /// No description provided for @durak_error_already_defended.
  ///
  /// In ru, this message translates to:
  /// **'Эта карта уже отбита'**
  String get durak_error_already_defended;

  /// No description provided for @durak_error_bad_attack_index.
  ///
  /// In ru, this message translates to:
  /// **'Выберите атакующую карту для защиты'**
  String get durak_error_bad_attack_index;

  /// No description provided for @durak_error_only_defender.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас отбивается другой игрок'**
  String get durak_error_only_defender;

  /// No description provided for @durak_error_defender_already_taking.
  ///
  /// In ru, this message translates to:
  /// **'Отбивающийся уже берет карты'**
  String get durak_error_defender_already_taking;

  /// No description provided for @durak_error_game_not_active.
  ///
  /// In ru, this message translates to:
  /// **'Партия уже не активна'**
  String get durak_error_game_not_active;

  /// No description provided for @durak_error_not_in_lobby.
  ///
  /// In ru, this message translates to:
  /// **'Лобби уже стартовало'**
  String get durak_error_not_in_lobby;

  /// No description provided for @durak_error_game_already_active.
  ///
  /// In ru, this message translates to:
  /// **'Партия уже началась'**
  String get durak_error_game_already_active;

  /// No description provided for @durak_error_active_game_exists.
  ///
  /// In ru, this message translates to:
  /// **'В этом чате уже есть активная партия'**
  String get durak_error_active_game_exists;

  /// No description provided for @durak_error_resolution_pending.
  ///
  /// In ru, this message translates to:
  /// **'Сначала завершите спорный ход'**
  String get durak_error_resolution_pending;

  /// No description provided for @durak_error_rematch_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось подготовить реванш. Попробуйте еще раз'**
  String get durak_error_rematch_failed;

  /// No description provided for @durak_error_unauthenticated.
  ///
  /// In ru, this message translates to:
  /// **'Нужно войти в аккаунт'**
  String get durak_error_unauthenticated;

  /// No description provided for @durak_error_permission_denied.
  ///
  /// In ru, this message translates to:
  /// **'Это действие вам недоступно'**
  String get durak_error_permission_denied;

  /// No description provided for @durak_error_invalid_argument.
  ///
  /// In ru, this message translates to:
  /// **'Некорректный ход'**
  String get durak_error_invalid_argument;

  /// No description provided for @durak_error_failed_precondition.
  ///
  /// In ru, this message translates to:
  /// **'Ход сейчас недоступен'**
  String get durak_error_failed_precondition;

  /// No description provided for @durak_error_server.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выполнить ход. Попробуйте еще раз'**
  String get durak_error_server;

  /// No description provided for @pinned_count.
  ///
  /// In ru, this message translates to:
  /// **'Закреплено: {count}'**
  String pinned_count(int count);

  /// No description provided for @pinned_single.
  ///
  /// In ru, this message translates to:
  /// **'Закреплено'**
  String get pinned_single;

  /// No description provided for @pinned_unpin_tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Открепить'**
  String get pinned_unpin_tooltip;

  /// No description provided for @pinned_type_image.
  ///
  /// In ru, this message translates to:
  /// **'Изображение'**
  String get pinned_type_image;

  /// No description provided for @pinned_type_video.
  ///
  /// In ru, this message translates to:
  /// **'Видео'**
  String get pinned_type_video;

  /// No description provided for @pinned_type_video_circle.
  ///
  /// In ru, this message translates to:
  /// **'Видеокружок'**
  String get pinned_type_video_circle;

  /// No description provided for @pinned_type_voice.
  ///
  /// In ru, this message translates to:
  /// **'Голосовое сообщение'**
  String get pinned_type_voice;

  /// No description provided for @pinned_type_poll.
  ///
  /// In ru, this message translates to:
  /// **'Опрос'**
  String get pinned_type_poll;

  /// No description provided for @pinned_type_link.
  ///
  /// In ru, this message translates to:
  /// **'Ссылка'**
  String get pinned_type_link;

  /// No description provided for @pinned_type_location.
  ///
  /// In ru, this message translates to:
  /// **'Локация'**
  String get pinned_type_location;

  /// No description provided for @pinned_type_sticker.
  ///
  /// In ru, this message translates to:
  /// **'Стикер'**
  String get pinned_type_sticker;

  /// No description provided for @pinned_type_file.
  ///
  /// In ru, this message translates to:
  /// **'Файл'**
  String get pinned_type_file;

  /// No description provided for @call_entry_login_required_title.
  ///
  /// In ru, this message translates to:
  /// **'Необходим вход'**
  String get call_entry_login_required_title;

  /// No description provided for @call_entry_login_required_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Откройте приложение и войдите в аккаунт.'**
  String get call_entry_login_required_subtitle;

  /// No description provided for @call_entry_not_found_title.
  ///
  /// In ru, this message translates to:
  /// **'Звонок не найден'**
  String get call_entry_not_found_title;

  /// No description provided for @call_entry_not_found_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Вызов уже завершён или удалён. Возвращаемся к звонкам…'**
  String get call_entry_not_found_subtitle;

  /// No description provided for @call_entry_to_calls.
  ///
  /// In ru, this message translates to:
  /// **'К звонкам'**
  String get call_entry_to_calls;

  /// No description provided for @call_entry_ended_title.
  ///
  /// In ru, this message translates to:
  /// **'Звонок завершён'**
  String get call_entry_ended_title;

  /// No description provided for @call_entry_ended_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Этот вызов уже недоступен. Возвращаемся к звонкам…'**
  String get call_entry_ended_subtitle;

  /// No description provided for @call_entry_caller_fallback.
  ///
  /// In ru, this message translates to:
  /// **'Собеседник'**
  String get call_entry_caller_fallback;

  /// No description provided for @call_entry_opening_title.
  ///
  /// In ru, this message translates to:
  /// **'Открываем звонок…'**
  String get call_entry_opening_title;

  /// No description provided for @call_entry_connecting_video.
  ///
  /// In ru, this message translates to:
  /// **'Подключение к видеозвонку'**
  String get call_entry_connecting_video;

  /// No description provided for @call_entry_connecting_audio.
  ///
  /// In ru, this message translates to:
  /// **'Подключение к аудиозвонку'**
  String get call_entry_connecting_audio;

  /// No description provided for @call_entry_loading_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка данных вызова'**
  String get call_entry_loading_subtitle;

  /// No description provided for @call_entry_error_title.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка открытия звонка'**
  String get call_entry_error_title;

  /// No description provided for @chat_theme_save_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить фон: {error}'**
  String chat_theme_save_error(Object error);

  /// No description provided for @chat_theme_load_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки фона: {error}'**
  String chat_theme_load_error(Object error);

  /// No description provided for @chat_theme_delete_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка удаления: {error}'**
  String chat_theme_delete_error(Object error);

  /// No description provided for @chat_theme_description.
  ///
  /// In ru, this message translates to:
  /// **'Фон этой переписки только для вас. Общие настройки чатов в разделе «Настройки чатов» не меняются.'**
  String get chat_theme_description;

  /// No description provided for @chat_theme_default_bg.
  ///
  /// In ru, this message translates to:
  /// **'По умолчанию (общие настройки)'**
  String get chat_theme_default_bg;

  /// No description provided for @chat_theme_global_label.
  ///
  /// In ru, this message translates to:
  /// **'Общие'**
  String get chat_theme_global_label;

  /// No description provided for @chat_theme_hint.
  ///
  /// In ru, this message translates to:
  /// **'Выберите пресет или фото из галереи'**
  String get chat_theme_hint;

  /// No description provided for @date_today.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get date_today;

  /// No description provided for @date_yesterday.
  ///
  /// In ru, this message translates to:
  /// **'Вчера'**
  String get date_yesterday;

  /// No description provided for @date_month_1.
  ///
  /// In ru, this message translates to:
  /// **'января'**
  String get date_month_1;

  /// No description provided for @date_month_2.
  ///
  /// In ru, this message translates to:
  /// **'февраля'**
  String get date_month_2;

  /// No description provided for @date_month_3.
  ///
  /// In ru, this message translates to:
  /// **'марта'**
  String get date_month_3;

  /// No description provided for @date_month_4.
  ///
  /// In ru, this message translates to:
  /// **'апреля'**
  String get date_month_4;

  /// No description provided for @date_month_5.
  ///
  /// In ru, this message translates to:
  /// **'мая'**
  String get date_month_5;

  /// No description provided for @date_month_6.
  ///
  /// In ru, this message translates to:
  /// **'июня'**
  String get date_month_6;

  /// No description provided for @date_month_7.
  ///
  /// In ru, this message translates to:
  /// **'июля'**
  String get date_month_7;

  /// No description provided for @date_month_8.
  ///
  /// In ru, this message translates to:
  /// **'августа'**
  String get date_month_8;

  /// No description provided for @date_month_9.
  ///
  /// In ru, this message translates to:
  /// **'сентября'**
  String get date_month_9;

  /// No description provided for @date_month_10.
  ///
  /// In ru, this message translates to:
  /// **'октября'**
  String get date_month_10;

  /// No description provided for @date_month_11.
  ///
  /// In ru, this message translates to:
  /// **'ноября'**
  String get date_month_11;

  /// No description provided for @date_month_12.
  ///
  /// In ru, this message translates to:
  /// **'декабря'**
  String get date_month_12;

  /// No description provided for @video_circle_camera_unavailable.
  ///
  /// In ru, this message translates to:
  /// **'Камера недоступна'**
  String get video_circle_camera_unavailable;

  /// No description provided for @video_circle_camera_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть камеру: {error}'**
  String video_circle_camera_error(Object error);

  /// No description provided for @video_circle_record_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка записи: {error}'**
  String video_circle_record_error(Object error);

  /// No description provided for @video_circle_file_not_found.
  ///
  /// In ru, this message translates to:
  /// **'Файл записи не найден'**
  String get video_circle_file_not_found;

  /// No description provided for @video_circle_play_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось воспроизвести запись'**
  String get video_circle_play_error;

  /// No description provided for @video_circle_send_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить: {error}'**
  String video_circle_send_error(Object error);

  /// No description provided for @video_circle_switch_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось переключить камеру: {error}'**
  String video_circle_switch_error(Object error);

  /// No description provided for @video_circle_pause_error_detail.
  ///
  /// In ru, this message translates to:
  /// **'Пауза записи недоступна: {description} ({code})'**
  String video_circle_pause_error_detail(Object description, Object code);

  /// No description provided for @video_circle_pause_error.
  ///
  /// In ru, this message translates to:
  /// **'Пауза записи: {error}'**
  String video_circle_pause_error(Object error);

  /// No description provided for @video_circle_camera_fallback_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка камеры'**
  String get video_circle_camera_fallback_error;

  /// No description provided for @video_circle_retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get video_circle_retry;

  /// No description provided for @video_circle_sending.
  ///
  /// In ru, this message translates to:
  /// **'Отправка...'**
  String get video_circle_sending;

  /// No description provided for @video_circle_recorded.
  ///
  /// In ru, this message translates to:
  /// **'Кружок записан'**
  String get video_circle_recorded;

  /// No description provided for @video_circle_swipe_cancel.
  ///
  /// In ru, this message translates to:
  /// **'Влево - отмена'**
  String get video_circle_swipe_cancel;

  /// No description provided for @media_screen_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки медиа: {error}'**
  String media_screen_error(Object error);

  /// No description provided for @media_screen_title.
  ///
  /// In ru, this message translates to:
  /// **'Медиа, ссылки и файлы'**
  String get media_screen_title;

  /// No description provided for @media_tab_media.
  ///
  /// In ru, this message translates to:
  /// **'Медиа'**
  String get media_tab_media;

  /// No description provided for @media_tab_circles.
  ///
  /// In ru, this message translates to:
  /// **'Кружки'**
  String get media_tab_circles;

  /// No description provided for @media_tab_files.
  ///
  /// In ru, this message translates to:
  /// **'Файлы'**
  String get media_tab_files;

  /// No description provided for @media_tab_links.
  ///
  /// In ru, this message translates to:
  /// **'Ссылки'**
  String get media_tab_links;

  /// No description provided for @media_tab_audio.
  ///
  /// In ru, this message translates to:
  /// **'Аудио'**
  String get media_tab_audio;

  /// No description provided for @media_empty_files.
  ///
  /// In ru, this message translates to:
  /// **'Нет файлов'**
  String get media_empty_files;

  /// No description provided for @media_empty_media.
  ///
  /// In ru, this message translates to:
  /// **'Нет медиа'**
  String get media_empty_media;

  /// No description provided for @media_attachment_fallback.
  ///
  /// In ru, this message translates to:
  /// **'Вложение'**
  String get media_attachment_fallback;

  /// No description provided for @media_empty_circles.
  ///
  /// In ru, this message translates to:
  /// **'Нет кружков'**
  String get media_empty_circles;

  /// No description provided for @media_empty_links.
  ///
  /// In ru, this message translates to:
  /// **'Нет ссылок'**
  String get media_empty_links;

  /// No description provided for @media_empty_audio.
  ///
  /// In ru, this message translates to:
  /// **'Нет аудио'**
  String get media_empty_audio;

  /// No description provided for @media_sender_you.
  ///
  /// In ru, this message translates to:
  /// **'Вы'**
  String get media_sender_you;

  /// No description provided for @media_sender_fallback.
  ///
  /// In ru, this message translates to:
  /// **'Участник'**
  String get media_sender_fallback;

  /// No description provided for @call_detail_login_required.
  ///
  /// In ru, this message translates to:
  /// **'Необходим вход.'**
  String get call_detail_login_required;

  /// No description provided for @call_detail_not_found.
  ///
  /// In ru, this message translates to:
  /// **'Звонок не найден или нет доступа.'**
  String get call_detail_not_found;

  /// No description provided for @call_detail_unknown.
  ///
  /// In ru, this message translates to:
  /// **'Неизвестный'**
  String get call_detail_unknown;

  /// No description provided for @call_detail_title.
  ///
  /// In ru, this message translates to:
  /// **'Сведения о звонке'**
  String get call_detail_title;

  /// No description provided for @call_detail_video.
  ///
  /// In ru, this message translates to:
  /// **'Видеозвонок'**
  String get call_detail_video;

  /// No description provided for @call_detail_audio.
  ///
  /// In ru, this message translates to:
  /// **'Аудиозвонок'**
  String get call_detail_audio;

  /// No description provided for @call_detail_outgoing.
  ///
  /// In ru, this message translates to:
  /// **'Исходящий'**
  String get call_detail_outgoing;

  /// No description provided for @call_detail_incoming.
  ///
  /// In ru, this message translates to:
  /// **'Входящий'**
  String get call_detail_incoming;

  /// No description provided for @call_detail_date_label.
  ///
  /// In ru, this message translates to:
  /// **'Дата:'**
  String get call_detail_date_label;

  /// No description provided for @call_detail_duration_label.
  ///
  /// In ru, this message translates to:
  /// **'Длительность:'**
  String get call_detail_duration_label;

  /// No description provided for @call_detail_call_button.
  ///
  /// In ru, this message translates to:
  /// **'Позвонить'**
  String get call_detail_call_button;

  /// No description provided for @call_detail_video_button.
  ///
  /// In ru, this message translates to:
  /// **'Видео'**
  String get call_detail_video_button;

  /// No description provided for @call_detail_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка: {error}'**
  String call_detail_error(Object error);

  /// No description provided for @durak_took.
  ///
  /// In ru, this message translates to:
  /// **'Взял'**
  String get durak_took;

  /// No description provided for @durak_beaten.
  ///
  /// In ru, this message translates to:
  /// **'Бито'**
  String get durak_beaten;

  /// No description provided for @durak_end_game_tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Завершить игру'**
  String get durak_end_game_tooltip;

  /// No description provided for @durak_role_beats.
  ///
  /// In ru, this message translates to:
  /// **'БЬЕТ'**
  String get durak_role_beats;

  /// No description provided for @durak_role_move.
  ///
  /// In ru, this message translates to:
  /// **'ХОД'**
  String get durak_role_move;

  /// No description provided for @durak_role_throw.
  ///
  /// In ru, this message translates to:
  /// **'ПОДК'**
  String get durak_role_throw;

  /// No description provided for @durak_cheater_label.
  ///
  /// In ru, this message translates to:
  /// **'Шулер! Не заметили:'**
  String get durak_cheater_label;

  /// No description provided for @durak_waiting_foll_confirm.
  ///
  /// In ru, this message translates to:
  /// **'Ожидание фолла… Нажми «Подтвердить Бито», если все согласны.'**
  String get durak_waiting_foll_confirm;

  /// No description provided for @durak_waiting_foll_call.
  ///
  /// In ru, this message translates to:
  /// **'Ожидание фолла… Теперь можно нажать «Фолл!», если заметил шулерство.'**
  String get durak_waiting_foll_call;

  /// No description provided for @durak_winner.
  ///
  /// In ru, this message translates to:
  /// **'Победитель'**
  String get durak_winner;

  /// No description provided for @durak_play_again.
  ///
  /// In ru, this message translates to:
  /// **'Сыграть ещё раз'**
  String get durak_play_again;

  /// No description provided for @durak_games_progress.
  ///
  /// In ru, this message translates to:
  /// **'Сыграно {finished} из {total}'**
  String durak_games_progress(Object finished, Object total);

  /// No description provided for @durak_next_round.
  ///
  /// In ru, this message translates to:
  /// **'Следующая партия турнира'**
  String get durak_next_round;

  /// No description provided for @audio_call_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка звонка: {error}'**
  String audio_call_error(Object error);

  /// No description provided for @audio_call_ended.
  ///
  /// In ru, this message translates to:
  /// **'Звонок завершён'**
  String get audio_call_ended;

  /// No description provided for @audio_call_missed.
  ///
  /// In ru, this message translates to:
  /// **'Пропущенный звонок'**
  String get audio_call_missed;

  /// No description provided for @audio_call_cancelled.
  ///
  /// In ru, this message translates to:
  /// **'Звон��к отменен'**
  String get audio_call_cancelled;

  /// No description provided for @audio_call_offer_not_ready.
  ///
  /// In ru, this message translates to:
  /// **'Оффер ещё не готов, попробуйте снова'**
  String get audio_call_offer_not_ready;

  /// No description provided for @audio_call_invalid_data.
  ///
  /// In ru, this message translates to:
  /// **'Некорректные данные звонка'**
  String get audio_call_invalid_data;

  /// No description provided for @audio_call_accept_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось принять звонок: {error}'**
  String audio_call_accept_error(Object error);

  /// No description provided for @audio_call_incoming.
  ///
  /// In ru, this message translates to:
  /// **'Входящий аудиозвонок'**
  String get audio_call_incoming;

  /// No description provided for @audio_call_calling.
  ///
  /// In ru, this message translates to:
  /// **'Аудиозвонок…'**
  String get audio_call_calling;

  /// No description provided for @privacy_save_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить настройки: {error}'**
  String privacy_save_error(Object error);

  /// No description provided for @privacy_load_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки приватности: {error}'**
  String privacy_load_error(Object error);

  /// No description provided for @privacy_visibility.
  ///
  /// In ru, this message translates to:
  /// **'Видимость'**
  String get privacy_visibility;

  /// No description provided for @privacy_online_status.
  ///
  /// In ru, this message translates to:
  /// **'Статус онлайн'**
  String get privacy_online_status;

  /// No description provided for @privacy_last_visit.
  ///
  /// In ru, this message translates to:
  /// **'Последний визит'**
  String get privacy_last_visit;

  /// No description provided for @privacy_read_receipts.
  ///
  /// In ru, this message translates to:
  /// **'Индикатор прочтения'**
  String get privacy_read_receipts;

  /// No description provided for @privacy_profile_info.
  ///
  /// In ru, this message translates to:
  /// **'Информация профиля'**
  String get privacy_profile_info;

  /// No description provided for @privacy_phone_number.
  ///
  /// In ru, this message translates to:
  /// **'Номер телефона'**
  String get privacy_phone_number;

  /// No description provided for @privacy_birthday.
  ///
  /// In ru, this message translates to:
  /// **'Дата рождения'**
  String get privacy_birthday;

  /// No description provided for @privacy_about.
  ///
  /// In ru, this message translates to:
  /// **'О себе'**
  String get privacy_about;

  /// No description provided for @starred_load_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки избранного: {error}'**
  String starred_load_error(Object error);

  /// No description provided for @starred_title.
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get starred_title;

  /// No description provided for @starred_empty.
  ///
  /// In ru, this message translates to:
  /// **'В этом чате нет избранных сообщений'**
  String get starred_empty;

  /// No description provided for @starred_message_fallback.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение'**
  String get starred_message_fallback;

  /// No description provided for @starred_sender_you.
  ///
  /// In ru, this message translates to:
  /// **'Вы'**
  String get starred_sender_you;

  /// No description provided for @starred_sender_fallback.
  ///
  /// In ru, this message translates to:
  /// **'Участник'**
  String get starred_sender_fallback;

  /// No description provided for @starred_type_poll.
  ///
  /// In ru, this message translates to:
  /// **'Опрос'**
  String get starred_type_poll;

  /// No description provided for @starred_type_location.
  ///
  /// In ru, this message translates to:
  /// **'Локация'**
  String get starred_type_location;

  /// No description provided for @starred_type_attachment.
  ///
  /// In ru, this message translates to:
  /// **'Вложение'**
  String get starred_type_attachment;

  /// No description provided for @starred_today_prefix.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня, {time}'**
  String starred_today_prefix(Object time);

  /// No description provided for @contact_edit_name_required.
  ///
  /// In ru, this message translates to:
  /// **'Введите имя контакта.'**
  String get contact_edit_name_required;

  /// No description provided for @contact_edit_save_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить контакт: {error}'**
  String contact_edit_save_error(Object error);

  /// No description provided for @contact_edit_user_fallback.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь'**
  String get contact_edit_user_fallback;

  /// No description provided for @contact_edit_first_name_hint.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get contact_edit_first_name_hint;

  /// No description provided for @contact_edit_last_name_hint.
  ///
  /// In ru, this message translates to:
  /// **'Фамилия'**
  String get contact_edit_last_name_hint;

  /// No description provided for @contact_edit_description.
  ///
  /// In ru, this message translates to:
  /// **'Это имя видно только вам: в чатах, поиске и списке контактов.'**
  String get contact_edit_description;

  /// No description provided for @contact_edit_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка: {error}'**
  String contact_edit_error(Object error);

  /// No description provided for @voice_no_mic_access.
  ///
  /// In ru, this message translates to:
  /// **'Не�� доступа к микрофону'**
  String get voice_no_mic_access;

  /// No description provided for @voice_start_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось начать запись'**
  String get voice_start_error;

  /// No description provided for @voice_file_not_received.
  ///
  /// In ru, this message translates to:
  /// **'Файл записи не получен'**
  String get voice_file_not_received;

  /// No description provided for @voice_stop_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось завершить запись'**
  String get voice_stop_error;

  /// No description provided for @voice_title.
  ///
  /// In ru, this message translates to:
  /// **'Голосовое сообщение'**
  String get voice_title;

  /// No description provided for @voice_recording.
  ///
  /// In ru, this message translates to:
  /// **'Идёт запись'**
  String get voice_recording;

  /// No description provided for @voice_ready.
  ///
  /// In ru, this message translates to:
  /// **'Запись готова'**
  String get voice_ready;

  /// No description provided for @voice_stop_button.
  ///
  /// In ru, this message translates to:
  /// **'Остановить'**
  String get voice_stop_button;

  /// No description provided for @voice_record_again.
  ///
  /// In ru, this message translates to:
  /// **'Записать снова'**
  String get voice_record_again;

  /// No description provided for @attach_photo_video.
  ///
  /// In ru, this message translates to:
  /// **'Фото/Видео'**
  String get attach_photo_video;

  /// No description provided for @attach_files.
  ///
  /// In ru, this message translates to:
  /// **'Файлы'**
  String get attach_files;

  /// No description provided for @attach_scan.
  ///
  /// In ru, this message translates to:
  /// **'Скан'**
  String get attach_scan;

  /// No description provided for @scanner_preview_title.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} страница} few{{count} страницы} other{{count} страниц}}'**
  String scanner_preview_title(int count);

  /// No description provided for @scanner_preview_send.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{Отправить страницу} few{Отправить {count} страницы} other{Отправить {count} страниц}}'**
  String scanner_preview_send(int count);

  /// No description provided for @scanner_preview_add.
  ///
  /// In ru, this message translates to:
  /// **'Сканировать ещё страницу'**
  String get scanner_preview_add;

  /// No description provided for @scanner_preview_retake.
  ///
  /// In ru, this message translates to:
  /// **'Снять заново'**
  String get scanner_preview_retake;

  /// No description provided for @scanner_preview_delete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить страницу'**
  String get scanner_preview_delete;

  /// No description provided for @scanner_preview_empty.
  ///
  /// In ru, this message translates to:
  /// **'Все страницы удалены. Нажмите + чтобы отсканировать новую.'**
  String get scanner_preview_empty;

  /// No description provided for @attach_circle.
  ///
  /// In ru, this message translates to:
  /// **'Кружок'**
  String get attach_circle;

  /// No description provided for @attach_location.
  ///
  /// In ru, this message translates to:
  /// **'Локация'**
  String get attach_location;

  /// No description provided for @attach_poll.
  ///
  /// In ru, this message translates to:
  /// **'Опрос'**
  String get attach_poll;

  /// No description provided for @attach_stickers.
  ///
  /// In ru, this message translates to:
  /// **'Стикеры'**
  String get attach_stickers;

  /// No description provided for @attach_clipboard.
  ///
  /// In ru, this message translates to:
  /// **'Буфер'**
  String get attach_clipboard;

  /// No description provided for @attach_text.
  ///
  /// In ru, this message translates to:
  /// **'Текст'**
  String get attach_text;

  /// No description provided for @attach_title.
  ///
  /// In ru, this message translates to:
  /// **'Прикрепить'**
  String get attach_title;

  /// No description provided for @notif_save_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить: {error}'**
  String notif_save_error(Object error);

  /// No description provided for @notif_title.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления в этом чате'**
  String get notif_title;

  /// No description provided for @notif_description.
  ///
  /// In ru, this message translates to:
  /// **'Настройки ниже действуют только для этой беседы и не меняют общие уведомления приложения.'**
  String get notif_description;

  /// No description provided for @notif_this_chat.
  ///
  /// In ru, this message translates to:
  /// **'Этот чат'**
  String get notif_this_chat;

  /// No description provided for @notif_mute_title.
  ///
  /// In ru, this message translates to:
  /// **'Без звука и скрытые оповещения'**
  String get notif_mute_title;

  /// No description provided for @notif_mute_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Не беспокоить по этому чату на этом устройстве.'**
  String get notif_mute_subtitle;

  /// No description provided for @notif_preview_title.
  ///
  /// In ru, this message translates to:
  /// **'Показывать превью текста'**
  String get notif_preview_title;

  /// No description provided for @notif_preview_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Если выключено — заголовок без фрагмента сообщения (где это поддерживается).'**
  String get notif_preview_subtitle;

  /// No description provided for @poll_create_enter_question.
  ///
  /// In ru, this message translates to:
  /// **'Введите вопрос'**
  String get poll_create_enter_question;

  /// No description provided for @poll_create_min_options.
  ///
  /// In ru, this message translates to:
  /// **'Нужно минимум 2 варианта'**
  String get poll_create_min_options;

  /// No description provided for @poll_create_select_correct.
  ///
  /// In ru, this message translates to:
  /// **'Выберите правильный вариант'**
  String get poll_create_select_correct;

  /// No description provided for @poll_create_future_time.
  ///
  /// In ru, this message translates to:
  /// **'Время закрытия должно быть в будущем'**
  String get poll_create_future_time;

  /// No description provided for @poll_create_question_label.
  ///
  /// In ru, this message translates to:
  /// **'Вопрос'**
  String get poll_create_question_label;

  /// No description provided for @poll_create_question_hint.
  ///
  /// In ru, this message translates to:
  /// **'Например: Во сколько встречаемся?'**
  String get poll_create_question_hint;

  /// No description provided for @poll_create_explanation_label.
  ///
  /// In ru, this message translates to:
  /// **'Пояснение (необязательно)'**
  String get poll_create_explanation_label;

  /// No description provided for @poll_create_options_title.
  ///
  /// In ru, this message translates to:
  /// **'Варианты'**
  String get poll_create_options_title;

  /// No description provided for @poll_create_option_hint.
  ///
  /// In ru, this message translates to:
  /// **'Вариант {index}'**
  String poll_create_option_hint(Object index);

  /// No description provided for @poll_create_add_option.
  ///
  /// In ru, this message translates to:
  /// **'Добавить вариант'**
  String get poll_create_add_option;

  /// No description provided for @poll_create_anonymous_title.
  ///
  /// In ru, this message translates to:
  /// **'Анонимное голосование'**
  String get poll_create_anonymous_title;

  /// No description provided for @poll_create_anonymous_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Не показывать, кто за что голосовал'**
  String get poll_create_anonymous_subtitle;

  /// No description provided for @poll_create_multi_title.
  ///
  /// In ru, this message translates to:
  /// **'Несколько ответов'**
  String get poll_create_multi_title;

  /// No description provided for @poll_create_multi_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Можно выбрать несколько вариантов'**
  String get poll_create_multi_subtitle;

  /// No description provided for @poll_create_user_options_title.
  ///
  /// In ru, this message translates to:
  /// **'Добавление вариантов'**
  String get poll_create_user_options_title;

  /// No description provided for @poll_create_user_options_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Участники могут предложить свой вариант'**
  String get poll_create_user_options_subtitle;

  /// No description provided for @poll_create_revote_title.
  ///
  /// In ru, this message translates to:
  /// **'Можно изменить голос'**
  String get poll_create_revote_title;

  /// No description provided for @poll_create_revote_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Переголосование до закрытия'**
  String get poll_create_revote_subtitle;

  /// No description provided for @poll_create_shuffle_title.
  ///
  /// In ru, this message translates to:
  /// **'Перемешать варианты'**
  String get poll_create_shuffle_title;

  /// No description provided for @poll_create_shuffle_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Свой порядок у каждого участника'**
  String get poll_create_shuffle_subtitle;

  /// No description provided for @poll_create_quiz_title.
  ///
  /// In ru, this message translates to:
  /// **'Режим викторины'**
  String get poll_create_quiz_title;

  /// No description provided for @poll_create_quiz_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Один правильный ответ'**
  String get poll_create_quiz_subtitle;

  /// No description provided for @poll_create_correct_option_label.
  ///
  /// In ru, this message translates to:
  /// **'Правильный вариант'**
  String get poll_create_correct_option_label;

  /// No description provided for @poll_create_close_by_time.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть по времени'**
  String get poll_create_close_by_time;

  /// No description provided for @poll_create_not_set.
  ///
  /// In ru, this message translates to:
  /// **'Не задано'**
  String get poll_create_not_set;

  /// No description provided for @poll_create_reset_deadline.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить срок'**
  String get poll_create_reset_deadline;

  /// No description provided for @poll_create_publish.
  ///
  /// In ru, this message translates to:
  /// **'Опубликовать'**
  String get poll_create_publish;

  /// No description provided for @poll_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка'**
  String get poll_error;

  /// No description provided for @poll_status_finished.
  ///
  /// In ru, this message translates to:
  /// **'Завершён'**
  String get poll_status_finished;

  /// No description provided for @poll_restart.
  ///
  /// In ru, this message translates to:
  /// **'Перезапустить'**
  String get poll_restart;

  /// No description provided for @poll_finish.
  ///
  /// In ru, this message translates to:
  /// **'Завершить'**
  String get poll_finish;

  /// No description provided for @poll_suggest_hint.
  ///
  /// In ru, this message translates to:
  /// **'Предложить вариант'**
  String get poll_suggest_hint;

  /// No description provided for @poll_voters_toggle_hide.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть'**
  String get poll_voters_toggle_hide;

  /// No description provided for @poll_voters_toggle_show.
  ///
  /// In ru, this message translates to:
  /// **'Кто голосовал'**
  String get poll_voters_toggle_show;

  /// No description provided for @e2ee_disable_title.
  ///
  /// In ru, this message translates to:
  /// **'Отключить шифрование?'**
  String get e2ee_disable_title;

  /// No description provided for @e2ee_disable_body.
  ///
  /// In ru, this message translates to:
  /// **'Новые сообщения пойдут без сквозного шифрования. Ранее отправленные зашифрованные сообщения останутся в ленте.'**
  String get e2ee_disable_body;

  /// No description provided for @e2ee_disable_button.
  ///
  /// In ru, this message translates to:
  /// **'Отключить'**
  String get e2ee_disable_button;

  /// No description provided for @e2ee_disable_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отключить: {error}'**
  String e2ee_disable_error(Object error);

  /// No description provided for @e2ee_screen_title.
  ///
  /// In ru, this message translates to:
  /// **'Шифрование'**
  String get e2ee_screen_title;

  /// No description provided for @e2ee_enabled_description.
  ///
  /// In ru, this message translates to:
  /// **'Сквозное шифрование включено для этого чата.'**
  String get e2ee_enabled_description;

  /// No description provided for @e2ee_disabled_description.
  ///
  /// In ru, this message translates to:
  /// **'Сквозное шифрование выключено.'**
  String get e2ee_disabled_description;

  /// No description provided for @e2ee_info_text.
  ///
  /// In ru, this message translates to:
  /// **'Когда шифрование включено, содержимое новых сообщений доступно только участникам чата на их устройствах. Отключение влияет только на новые сообщения.'**
  String get e2ee_info_text;

  /// No description provided for @e2ee_enable_title.
  ///
  /// In ru, this message translates to:
  /// **'Включить шифрование'**
  String get e2ee_enable_title;

  /// No description provided for @e2ee_status_enabled.
  ///
  /// In ru, this message translates to:
  /// **'Включено (эпоха ключа: {epoch})'**
  String e2ee_status_enabled(Object epoch);

  /// No description provided for @e2ee_status_disabled.
  ///
  /// In ru, this message translates to:
  /// **'Выключено'**
  String get e2ee_status_disabled;

  /// No description provided for @e2ee_data_types_title.
  ///
  /// In ru, this message translates to:
  /// **'Типы данных'**
  String get e2ee_data_types_title;

  /// No description provided for @e2ee_data_types_info.
  ///
  /// In ru, this message translates to:
  /// **'Настройка не меняет протокол. Она управляет тем, какие типы данных отправлять в зашифрованном виде.'**
  String get e2ee_data_types_info;

  /// No description provided for @e2ee_chat_settings_title.
  ///
  /// In ru, this message translates to:
  /// **'Настройки шифрования для этого чата'**
  String get e2ee_chat_settings_title;

  /// No description provided for @e2ee_chat_settings_override.
  ///
  /// In ru, this message translates to:
  /// **'Используются чатовые настройки.'**
  String get e2ee_chat_settings_override;

  /// No description provided for @e2ee_chat_settings_global.
  ///
  /// In ru, this message translates to:
  /// **'Наследуются глобальные настройки.'**
  String get e2ee_chat_settings_global;

  /// No description provided for @e2ee_text_messages.
  ///
  /// In ru, this message translates to:
  /// **'Текст сообщений'**
  String get e2ee_text_messages;

  /// No description provided for @e2ee_attachments.
  ///
  /// In ru, this message translates to:
  /// **'Вложения (медиа/файлы)'**
  String get e2ee_attachments;

  /// No description provided for @e2ee_override_hint.
  ///
  /// In ru, this message translates to:
  /// **'Чтобы изменить для этого чата — включите «Переопределить».'**
  String get e2ee_override_hint;

  /// No description provided for @group_member_fallback.
  ///
  /// In ru, this message translates to:
  /// **'Участник'**
  String get group_member_fallback;

  /// No description provided for @group_role_creator.
  ///
  /// In ru, this message translates to:
  /// **'Создатель группы'**
  String get group_role_creator;

  /// No description provided for @group_role_admin.
  ///
  /// In ru, this message translates to:
  /// **'Администратор'**
  String get group_role_admin;

  /// No description provided for @group_total_count.
  ///
  /// In ru, this message translates to:
  /// **'Всего: {count}'**
  String group_total_count(Object count);

  /// No description provided for @group_copy_invite_tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать ссылку-приглашение'**
  String get group_copy_invite_tooltip;

  /// No description provided for @group_add_member_tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Добавить участника'**
  String get group_add_member_tooltip;

  /// No description provided for @group_invite_copied.
  ///
  /// In ru, this message translates to:
  /// **'Ссылка-приглашение скопирована'**
  String get group_invite_copied;

  /// No description provided for @group_copy_invite_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось скопировать ссылку: {error}'**
  String group_copy_invite_error(Object error);

  /// No description provided for @group_demote_confirm.
  ///
  /// In ru, this message translates to:
  /// **'Снять права администратора?'**
  String get group_demote_confirm;

  /// No description provided for @group_promote_confirm.
  ///
  /// In ru, this message translates to:
  /// **'Назначить администратором?'**
  String get group_promote_confirm;

  /// No description provided for @group_demote_body.
  ///
  /// In ru, this message translates to:
  /// **'У {name} будут сняты права администратора. Участник останется в группе как обычный член.'**
  String group_demote_body(Object name);

  /// No description provided for @group_demote_button.
  ///
  /// In ru, this message translates to:
  /// **'Снять права'**
  String get group_demote_button;

  /// No description provided for @group_promote_button.
  ///
  /// In ru, this message translates to:
  /// **'Назначить'**
  String get group_promote_button;

  /// No description provided for @group_kick_confirm.
  ///
  /// In ru, this message translates to:
  /// **'Исключить участника?'**
  String get group_kick_confirm;

  /// No description provided for @group_kick_button.
  ///
  /// In ru, this message translates to:
  /// **'Исключить'**
  String get group_kick_button;

  /// No description provided for @group_member_kicked.
  ///
  /// In ru, this message translates to:
  /// **'Участник исключён'**
  String get group_member_kicked;

  /// No description provided for @group_badge_creator.
  ///
  /// In ru, this message translates to:
  /// **'СО��ДАТЕЛЬ'**
  String get group_badge_creator;

  /// No description provided for @group_demote_action.
  ///
  /// In ru, this message translates to:
  /// **'Снять админа'**
  String get group_demote_action;

  /// No description provided for @group_promote_action.
  ///
  /// In ru, this message translates to:
  /// **'Сделать админом'**
  String get group_promote_action;

  /// No description provided for @group_kick_action.
  ///
  /// In ru, this message translates to:
  /// **'Исключить из группы'**
  String get group_kick_action;

  /// No description provided for @group_contacts_load_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить контакты: {error}'**
  String group_contacts_load_error(Object error);

  /// No description provided for @group_add_members_title.
  ///
  /// In ru, this message translates to:
  /// **'Добавить участников'**
  String get group_add_members_title;

  /// No description provided for @group_search_contacts_hint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск среди конта��тов'**
  String get group_search_contacts_hint;

  /// No description provided for @group_all_contacts_in_group.
  ///
  /// In ru, this message translates to:
  /// **'Все ваши контакты уже в группе.'**
  String get group_all_contacts_in_group;

  /// No description provided for @group_nobody_found.
  ///
  /// In ru, this message translates to:
  /// **'Никого не найдено.'**
  String get group_nobody_found;

  /// No description provided for @group_user_fallback.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь'**
  String get group_user_fallback;

  /// No description provided for @group_select_members.
  ///
  /// In ru, this message translates to:
  /// **'Выберите участников'**
  String get group_select_members;

  /// No description provided for @group_add_count.
  ///
  /// In ru, this message translates to:
  /// **'Добавить ({count})'**
  String group_add_count(Object count);

  /// No description provided for @group_auth_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка авторизации: {error}'**
  String group_auth_error(Object error);

  /// No description provided for @group_add_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось добавить участников: {error}'**
  String group_add_error(Object error);

  /// No description provided for @add_contact_own_profile.
  ///
  /// In ru, this message translates to:
  /// **'Это ваш собственный профиль'**
  String get add_contact_own_profile;

  /// No description provided for @add_contact_qr_not_found.
  ///
  /// In ru, this message translates to:
  /// **'��рофиль из QR-кода не найден'**
  String get add_contact_qr_not_found;

  /// No description provided for @add_contact_qr_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось прочитать QR-код: {error}'**
  String add_contact_qr_error(Object error);

  /// No description provided for @add_contact_not_allowed.
  ///
  /// In ru, this message translates to:
  /// **'Нельзя добавить этого пользователя'**
  String get add_contact_not_allowed;

  /// No description provided for @add_contact_save_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось добавить контакт: {error}'**
  String add_contact_save_error(Object error);

  /// No description provided for @add_contact_country_search.
  ///
  /// In ru, this message translates to:
  /// **'Поиск страны или кода'**
  String get add_contact_country_search;

  /// No description provided for @add_contact_sync_phone.
  ///
  /// In ru, this message translates to:
  /// **'Синхронизировать с телефоном'**
  String get add_contact_sync_phone;

  /// No description provided for @add_contact_qr_button.
  ///
  /// In ru, this message translates to:
  /// **'Добавить по QR-коду'**
  String get add_contact_qr_button;

  /// No description provided for @add_contact_load_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки контакта: {error}'**
  String add_contact_load_error(Object error);

  /// No description provided for @add_contact_user_fallback.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь'**
  String get add_contact_user_fallback;

  /// No description provided for @add_contact_already_in_contacts.
  ///
  /// In ru, this message translates to:
  /// **'Уже в контактах'**
  String get add_contact_already_in_contacts;

  /// No description provided for @add_contact_new.
  ///
  /// In ru, this message translates to:
  /// **'Новый контакт'**
  String get add_contact_new;

  /// No description provided for @add_contact_unavailable.
  ///
  /// In ru, this message translates to:
  /// **'Недоступно'**
  String get add_contact_unavailable;

  /// No description provided for @add_contact_scan_qr.
  ///
  /// In ru, this message translates to:
  /// **'Сканировать QR-код'**
  String get add_contact_scan_qr;

  /// No description provided for @add_contact_scan_hint.
  ///
  /// In ru, this message translates to:
  /// **'Наведите камеру на QR-код профиля LighChat'**
  String get add_contact_scan_hint;

  /// No description provided for @auth_validate_name_min_length.
  ///
  /// In ru, this message translates to:
  /// **'Имя должно быть не менее 2 символов'**
  String get auth_validate_name_min_length;

  /// No description provided for @auth_validate_username_min_length.
  ///
  /// In ru, this message translates to:
  /// **'Имя пользователя должно быть не менее 3 символов'**
  String get auth_validate_username_min_length;

  /// No description provided for @auth_validate_username_max_length.
  ///
  /// In ru, this message translates to:
  /// **'Имя пользователя не должно превышать 30 символов'**
  String get auth_validate_username_max_length;

  /// No description provided for @auth_validate_username_format.
  ///
  /// In ru, this message translates to:
  /// **'Имя пользователя содержит недопустимые символы'**
  String get auth_validate_username_format;

  /// No description provided for @auth_validate_phone_11_digits.
  ///
  /// In ru, this message translates to:
  /// **'Номер телефона должен содержать 11 цифр'**
  String get auth_validate_phone_11_digits;

  /// No description provided for @auth_validate_email_format.
  ///
  /// In ru, this message translates to:
  /// **'Введите корректный email'**
  String get auth_validate_email_format;

  /// No description provided for @auth_validate_dob_invalid.
  ///
  /// In ru, this message translates to:
  /// **'Некорректная дата рождения'**
  String get auth_validate_dob_invalid;

  /// No description provided for @auth_validate_bio_max_length.
  ///
  /// In ru, this message translates to:
  /// **'Описание не должно превышать 200 символов'**
  String get auth_validate_bio_max_length;

  /// No description provided for @auth_validate_password_min_length.
  ///
  /// In ru, this message translates to:
  /// **'Пароль должен быть не менее 6 символов'**
  String get auth_validate_password_min_length;

  /// No description provided for @auth_validate_passwords_mismatch.
  ///
  /// In ru, this message translates to:
  /// **'Пароли не совпадают'**
  String get auth_validate_passwords_mismatch;

  /// No description provided for @sticker_new_pack.
  ///
  /// In ru, this message translates to:
  /// **'Новый пак…'**
  String get sticker_new_pack;

  /// No description provided for @sticker_select_image_or_gif.
  ///
  /// In ru, this message translates to:
  /// **'Выберите изображение или GIF'**
  String get sticker_select_image_or_gif;

  /// No description provided for @sticker_send_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить: {error}'**
  String sticker_send_error(Object error);

  /// No description provided for @sticker_saved.
  ///
  /// In ru, this message translates to:
  /// **'Сохранено в стикерпак'**
  String get sticker_saved;

  /// No description provided for @sticker_save_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось скачать или сохранить GIF'**
  String get sticker_save_failed;

  /// No description provided for @sticker_tab_my.
  ///
  /// In ru, this message translates to:
  /// **'Мои'**
  String get sticker_tab_my;

  /// No description provided for @sticker_tab_shared.
  ///
  /// In ru, this message translates to:
  /// **'Общие'**
  String get sticker_tab_shared;

  /// No description provided for @sticker_no_packs.
  ///
  /// In ru, this message translates to:
  /// **'Нет стикерпаков. Создайте новый.'**
  String get sticker_no_packs;

  /// No description provided for @sticker_shared_not_configured.
  ///
  /// In ru, this message translates to:
  /// **'Общие паки не настроены'**
  String get sticker_shared_not_configured;

  /// No description provided for @sticker_recent.
  ///
  /// In ru, this message translates to:
  /// **'НЕДАВНИЕ'**
  String get sticker_recent;

  /// No description provided for @sticker_gallery_description.
  ///
  /// In ru, this message translates to:
  /// **'Фото, PNG, GIF с устройства — сразу в чат'**
  String get sticker_gallery_description;

  /// No description provided for @sticker_shared_unavailable.
  ///
  /// In ru, this message translates to:
  /// **'Общие паки пока недоступны'**
  String get sticker_shared_unavailable;

  /// No description provided for @sticker_gif_search_hint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск GIF…'**
  String get sticker_gif_search_hint;

  /// No description provided for @sticker_gif_searched.
  ///
  /// In ru, this message translates to:
  /// **'Искали: {query}'**
  String sticker_gif_searched(Object query);

  /// No description provided for @sticker_gif_search_unavailable.
  ///
  /// In ru, this message translates to:
  /// **'Поиск GIF временно недоступен.'**
  String get sticker_gif_search_unavailable;

  /// No description provided for @sticker_gif_nothing_found.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено'**
  String get sticker_gif_nothing_found;

  /// No description provided for @sticker_gif_all.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get sticker_gif_all;

  /// No description provided for @sticker_gif_animated.
  ///
  /// In ru, this message translates to:
  /// **'АНИМИРОВАННЫЕ'**
  String get sticker_gif_animated;

  /// No description provided for @sticker_emoji_text_unavailable.
  ///
  /// In ru, this message translates to:
  /// **'Эмодзи в текст недоступны для этого окна.'**
  String get sticker_emoji_text_unavailable;

  /// No description provided for @wallpaper_sender.
  ///
  /// In ru, this message translates to:
  /// **'Собеседник'**
  String get wallpaper_sender;

  /// No description provided for @wallpaper_incoming.
  ///
  /// In ru, this message translates to:
  /// **'Это входящее сообщение.'**
  String get wallpaper_incoming;

  /// No description provided for @wallpaper_outgoing.
  ///
  /// In ru, this message translates to:
  /// **'Это исходящее сообщение.'**
  String get wallpaper_outgoing;

  /// No description provided for @wallpaper_incoming_time.
  ///
  /// In ru, this message translates to:
  /// **'11:40'**
  String get wallpaper_incoming_time;

  /// No description provided for @wallpaper_outgoing_time.
  ///
  /// In ru, this message translates to:
  /// **'11:41'**
  String get wallpaper_outgoing_time;

  /// No description provided for @wallpaper_system.
  ///
  /// In ru, this message translates to:
  /// **'Вы сменили обои чата'**
  String get wallpaper_system;

  /// No description provided for @wallpaper_you.
  ///
  /// In ru, this message translates to:
  /// **'Вы'**
  String get wallpaper_you;

  /// No description provided for @wallpaper_today.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get wallpaper_today;

  /// No description provided for @system_event_e2ee_enabled.
  ///
  /// In ru, this message translates to:
  /// **'Сквозное шифрование включено (эпоха ключа: {epoch})'**
  String system_event_e2ee_enabled(Object epoch);

  /// No description provided for @system_event_e2ee_disabled.
  ///
  /// In ru, this message translates to:
  /// **'Сквозное шифрование отключено'**
  String get system_event_e2ee_disabled;

  /// No description provided for @system_event_unknown.
  ///
  /// In ru, this message translates to:
  /// **'Системное событие'**
  String get system_event_unknown;

  /// No description provided for @system_event_group_created.
  ///
  /// In ru, this message translates to:
  /// **'Группа создана'**
  String get system_event_group_created;

  /// No description provided for @system_event_member_added.
  ///
  /// In ru, this message translates to:
  /// **'{name} добавлен(а)'**
  String system_event_member_added(Object name);

  /// No description provided for @system_event_member_removed.
  ///
  /// In ru, this message translates to:
  /// **'{name} удалён(а)'**
  String system_event_member_removed(Object name);

  /// No description provided for @system_event_member_left.
  ///
  /// In ru, this message translates to:
  /// **'{name} покинул(а) группу'**
  String system_event_member_left(Object name);

  /// No description provided for @system_event_name_changed.
  ///
  /// In ru, this message translates to:
  /// **'Название изменено на «{name}»'**
  String system_event_name_changed(Object name);

  /// No description provided for @image_editor_title.
  ///
  /// In ru, this message translates to:
  /// **'Редактор'**
  String get image_editor_title;

  /// No description provided for @image_editor_undo.
  ///
  /// In ru, this message translates to:
  /// **'Отменить'**
  String get image_editor_undo;

  /// No description provided for @image_editor_clear.
  ///
  /// In ru, this message translates to:
  /// **'Очистить'**
  String get image_editor_clear;

  /// No description provided for @image_editor_pen.
  ///
  /// In ru, this message translates to:
  /// **'Кисть'**
  String get image_editor_pen;

  /// No description provided for @image_editor_text.
  ///
  /// In ru, this message translates to:
  /// **'Текст'**
  String get image_editor_text;

  /// No description provided for @image_editor_crop.
  ///
  /// In ru, this message translates to:
  /// **'Кадрирование'**
  String get image_editor_crop;

  /// No description provided for @image_editor_rotate.
  ///
  /// In ru, this message translates to:
  /// **'Поворот'**
  String get image_editor_rotate;

  /// No description provided for @location_title.
  ///
  /// In ru, this message translates to:
  /// **'Отправить местоположение'**
  String get location_title;

  /// No description provided for @location_loading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка карты…'**
  String get location_loading;

  /// No description provided for @location_send_button.
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get location_send_button;

  /// No description provided for @location_live_label.
  ///
  /// In ru, this message translates to:
  /// **'Трансляция'**
  String get location_live_label;

  /// No description provided for @location_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить карту'**
  String get location_error;

  /// No description provided for @location_no_permission.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступа к местоположению'**
  String get location_no_permission;

  /// No description provided for @group_member_admin.
  ///
  /// In ru, this message translates to:
  /// **'Администратор'**
  String get group_member_admin;

  /// No description provided for @group_member_creator.
  ///
  /// In ru, this message translates to:
  /// **'Создатель'**
  String get group_member_creator;

  /// No description provided for @group_member_member.
  ///
  /// In ru, this message translates to:
  /// **'Участник'**
  String get group_member_member;

  /// No description provided for @group_member_open_chat.
  ///
  /// In ru, this message translates to:
  /// **'Написать'**
  String get group_member_open_chat;

  /// No description provided for @group_member_open_profile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get group_member_open_profile;

  /// No description provided for @group_member_remove.
  ///
  /// In ru, this message translates to:
  /// **'Исключить'**
  String get group_member_remove;

  /// No description provided for @durak_lobby_title.
  ///
  /// In ru, this message translates to:
  /// **'Дурак'**
  String get durak_lobby_title;

  /// No description provided for @durak_lobby_new_game.
  ///
  /// In ru, this message translates to:
  /// **'Новая игра'**
  String get durak_lobby_new_game;

  /// No description provided for @durak_lobby_decline.
  ///
  /// In ru, this message translates to:
  /// **'Отклонить'**
  String get durak_lobby_decline;

  /// No description provided for @durak_lobby_accept.
  ///
  /// In ru, this message translates to:
  /// **'Принять'**
  String get durak_lobby_accept;

  /// No description provided for @durak_lobby_invite_sent.
  ///
  /// In ru, this message translates to:
  /// **'Приглашение отправлено'**
  String get durak_lobby_invite_sent;

  /// No description provided for @voice_preview_cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get voice_preview_cancel;

  /// No description provided for @voice_preview_send.
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get voice_preview_send;

  /// No description provided for @voice_preview_recorded.
  ///
  /// In ru, this message translates to:
  /// **'Записано'**
  String get voice_preview_recorded;

  /// No description provided for @voice_preview_playing.
  ///
  /// In ru, this message translates to:
  /// **'Воспроизведение…'**
  String get voice_preview_playing;

  /// No description provided for @voice_preview_paused.
  ///
  /// In ru, this message translates to:
  /// **'Пауза'**
  String get voice_preview_paused;

  /// No description provided for @group_avatar_camera.
  ///
  /// In ru, this message translates to:
  /// **'Камера'**
  String get group_avatar_camera;

  /// No description provided for @group_avatar_gallery.
  ///
  /// In ru, this message translates to:
  /// **'Галерея'**
  String get group_avatar_gallery;

  /// No description provided for @group_avatar_upload_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки'**
  String get group_avatar_upload_error;

  /// No description provided for @avatar_picker_title.
  ///
  /// In ru, this message translates to:
  /// **'Аватар'**
  String get avatar_picker_title;

  /// No description provided for @avatar_picker_camera.
  ///
  /// In ru, this message translates to:
  /// **'Камера'**
  String get avatar_picker_camera;

  /// No description provided for @avatar_picker_gallery.
  ///
  /// In ru, this message translates to:
  /// **'Галерея'**
  String get avatar_picker_gallery;

  /// No description provided for @avatar_picker_crop.
  ///
  /// In ru, this message translates to:
  /// **'Обрезка'**
  String get avatar_picker_crop;

  /// No description provided for @avatar_picker_save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get avatar_picker_save;

  /// No description provided for @avatar_picker_remove.
  ///
  /// In ru, this message translates to:
  /// **'Удалить аватар'**
  String get avatar_picker_remove;

  /// No description provided for @avatar_picker_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить аватар'**
  String get avatar_picker_error;

  /// No description provided for @avatar_picker_crop_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка обрезки'**
  String get avatar_picker_crop_error;

  /// No description provided for @webview_telegram_title.
  ///
  /// In ru, this message translates to:
  /// **'Вход через Telegram'**
  String get webview_telegram_title;

  /// No description provided for @webview_telegram_loading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка…'**
  String get webview_telegram_loading;

  /// No description provided for @webview_telegram_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить страницу'**
  String get webview_telegram_error;

  /// No description provided for @webview_telegram_back.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get webview_telegram_back;

  /// No description provided for @webview_telegram_retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get webview_telegram_retry;

  /// No description provided for @webview_telegram_close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get webview_telegram_close;

  /// No description provided for @webview_telegram_no_url.
  ///
  /// In ru, this message translates to:
  /// **'Не указан URL для авторизации'**
  String get webview_telegram_no_url;

  /// No description provided for @webview_yandex_title.
  ///
  /// In ru, this message translates to:
  /// **'Вход через Яндекс'**
  String get webview_yandex_title;

  /// No description provided for @webview_yandex_loading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка…'**
  String get webview_yandex_loading;

  /// No description provided for @webview_yandex_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить страницу'**
  String get webview_yandex_error;

  /// No description provided for @webview_yandex_back.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get webview_yandex_back;

  /// No description provided for @webview_yandex_retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get webview_yandex_retry;

  /// No description provided for @webview_yandex_close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get webview_yandex_close;

  /// No description provided for @webview_yandex_no_url.
  ///
  /// In ru, this message translates to:
  /// **'Не указан URL для авторизации'**
  String get webview_yandex_no_url;

  /// No description provided for @google_profile_title.
  ///
  /// In ru, this message translates to:
  /// **'Заполните профиль'**
  String get google_profile_title;

  /// No description provided for @google_profile_name.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get google_profile_name;

  /// No description provided for @google_profile_username.
  ///
  /// In ru, this message translates to:
  /// **'Имя пользователя'**
  String get google_profile_username;

  /// No description provided for @google_profile_phone.
  ///
  /// In ru, this message translates to:
  /// **'Телефон'**
  String get google_profile_phone;

  /// No description provided for @google_profile_email.
  ///
  /// In ru, this message translates to:
  /// **'Email'**
  String get google_profile_email;

  /// No description provided for @google_profile_dob.
  ///
  /// In ru, this message translates to:
  /// **'Дата рождения'**
  String get google_profile_dob;

  /// No description provided for @google_profile_bio.
  ///
  /// In ru, this message translates to:
  /// **'О себе'**
  String get google_profile_bio;

  /// No description provided for @google_profile_save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get google_profile_save;

  /// No description provided for @google_profile_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить профиль'**
  String get google_profile_error;

  /// No description provided for @system_event_e2ee_epoch_rotated.
  ///
  /// In ru, this message translates to:
  /// **'Ключ шифрования обновлён'**
  String get system_event_e2ee_epoch_rotated;

  /// No description provided for @system_event_e2ee_device_added.
  ///
  /// In ru, this message translates to:
  /// **'{actor} добавил устройство «{device}»'**
  String system_event_e2ee_device_added(String actor, String device);

  /// No description provided for @system_event_e2ee_device_revoked.
  ///
  /// In ru, this message translates to:
  /// **'{actor} отозвал устройство «{device}»'**
  String system_event_e2ee_device_revoked(String actor, String device);

  /// No description provided for @system_event_e2ee_fingerprint_changed.
  ///
  /// In ru, this message translates to:
  /// **'Отпечаток безопасности у {actor} изменился'**
  String system_event_e2ee_fingerprint_changed(String actor);

  /// No description provided for @system_event_game_lobby_created.
  ///
  /// In ru, this message translates to:
  /// **'Создано лобби игры'**
  String get system_event_game_lobby_created;

  /// No description provided for @system_event_game_started.
  ///
  /// In ru, this message translates to:
  /// **'Игра началась'**
  String get system_event_game_started;

  /// No description provided for @system_event_call_missed.
  ///
  /// In ru, this message translates to:
  /// **'Пропущенный звонок'**
  String get system_event_call_missed;

  /// No description provided for @system_event_call_cancelled.
  ///
  /// In ru, this message translates to:
  /// **'Звонок отклонён'**
  String get system_event_call_cancelled;

  /// No description provided for @system_event_default_actor.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь'**
  String get system_event_default_actor;

  /// No description provided for @system_event_default_device.
  ///
  /// In ru, this message translates to:
  /// **'устройство'**
  String get system_event_default_device;

  /// No description provided for @image_editor_add_caption.
  ///
  /// In ru, this message translates to:
  /// **'Добавить подпись...'**
  String get image_editor_add_caption;

  /// No description provided for @image_editor_crop_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обрезать изображение'**
  String get image_editor_crop_failed;

  /// No description provided for @image_editor_draw_hint.
  ///
  /// In ru, this message translates to:
  /// **'Режим рисования: проведите пальцем по изображению'**
  String get image_editor_draw_hint;

  /// No description provided for @image_editor_crop_title.
  ///
  /// In ru, this message translates to:
  /// **'Обрезка'**
  String get image_editor_crop_title;

  /// No description provided for @location_preview_title.
  ///
  /// In ru, this message translates to:
  /// **'Местоположение'**
  String get location_preview_title;

  /// No description provided for @location_preview_accuracy_unknown.
  ///
  /// In ru, this message translates to:
  /// **'Точность: —'**
  String get location_preview_accuracy_unknown;

  /// No description provided for @location_preview_accuracy_meters.
  ///
  /// In ru, this message translates to:
  /// **'Точность: ~{meters} м'**
  String location_preview_accuracy_meters(String meters);

  /// No description provided for @location_preview_accuracy_km.
  ///
  /// In ru, this message translates to:
  /// **'Точность: ~{km} км'**
  String location_preview_accuracy_km(String km);

  /// No description provided for @group_member_profile_default_name.
  ///
  /// In ru, this message translates to:
  /// **'Участник'**
  String get group_member_profile_default_name;

  /// No description provided for @group_member_profile_dm.
  ///
  /// In ru, this message translates to:
  /// **'Написать лично'**
  String get group_member_profile_dm;

  /// No description provided for @group_member_profile_dm_hint.
  ///
  /// In ru, this message translates to:
  /// **'Открыть личный чат с участником'**
  String get group_member_profile_dm_hint;

  /// No description provided for @group_member_profile_dm_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть личный чат: {error}'**
  String group_member_profile_dm_failed(Object error);

  /// No description provided for @conversation_game_lobby_unavailable.
  ///
  /// In ru, this message translates to:
  /// **'Игра недоступна или была удалена'**
  String get conversation_game_lobby_unavailable;

  /// No description provided for @conversation_game_lobby_back.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get conversation_game_lobby_back;

  /// No description provided for @conversation_game_lobby_waiting.
  ///
  /// In ru, this message translates to:
  /// **'Ждём, пока подключится соперник…'**
  String get conversation_game_lobby_waiting;

  /// No description provided for @conversation_game_lobby_start_game.
  ///
  /// In ru, this message translates to:
  /// **'Начать игру'**
  String get conversation_game_lobby_start_game;

  /// No description provided for @conversation_game_lobby_waiting_short.
  ///
  /// In ru, this message translates to:
  /// **'Ждём…'**
  String get conversation_game_lobby_waiting_short;

  /// No description provided for @conversation_game_lobby_ready.
  ///
  /// In ru, this message translates to:
  /// **'Готов'**
  String get conversation_game_lobby_ready;

  /// No description provided for @voice_preview_trim_confirm_title.
  ///
  /// In ru, this message translates to:
  /// **'Оставить только выбранный фрагмент?'**
  String get voice_preview_trim_confirm_title;

  /// No description provided for @voice_preview_trim_confirm_body.
  ///
  /// In ru, this message translates to:
  /// **'Всё, кроме выделенного фрагмента, будет удалено. Запись сообщения продолжится сразу после нажатия кнопки.'**
  String get voice_preview_trim_confirm_body;

  /// No description provided for @voice_preview_continue.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить'**
  String get voice_preview_continue;

  /// No description provided for @voice_preview_continue_recording.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить запись'**
  String get voice_preview_continue_recording;

  /// No description provided for @group_avatar_change_short.
  ///
  /// In ru, this message translates to:
  /// **'Сменить'**
  String get group_avatar_change_short;

  /// No description provided for @avatar_picker_cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get avatar_picker_cancel;

  /// No description provided for @avatar_picker_choose.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать аватар'**
  String get avatar_picker_choose;

  /// No description provided for @avatar_picker_delete_photo.
  ///
  /// In ru, this message translates to:
  /// **'Удалить фото'**
  String get avatar_picker_delete_photo;

  /// No description provided for @avatar_picker_loading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка…'**
  String get avatar_picker_loading;

  /// No description provided for @avatar_picker_choose_avatar.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать аватар'**
  String get avatar_picker_choose_avatar;

  /// No description provided for @avatar_picker_change_avatar.
  ///
  /// In ru, this message translates to:
  /// **'Сменить аватар'**
  String get avatar_picker_change_avatar;

  /// No description provided for @avatar_picker_remove_tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Убрать'**
  String get avatar_picker_remove_tooltip;

  /// No description provided for @telegram_sign_in_title.
  ///
  /// In ru, this message translates to:
  /// **'Вход через Telegram'**
  String get telegram_sign_in_title;

  /// No description provided for @telegram_sign_in_open_in_browser.
  ///
  /// In ru, this message translates to:
  /// **'Открыть в браузере'**
  String get telegram_sign_in_open_in_browser;

  /// No description provided for @telegram_sign_in_open_telegram_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть Telegram. Установите приложение Telegram.'**
  String get telegram_sign_in_open_telegram_failed;

  /// No description provided for @telegram_sign_in_page_load_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки страницы'**
  String get telegram_sign_in_page_load_error;

  /// No description provided for @telegram_sign_in_login_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка входа через Telegram.'**
  String get telegram_sign_in_login_error;

  /// No description provided for @telegram_sign_in_firebase_not_ready.
  ///
  /// In ru, this message translates to:
  /// **'Firebase не готов.'**
  String get telegram_sign_in_firebase_not_ready;

  /// No description provided for @telegram_sign_in_browser_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть браузер.'**
  String get telegram_sign_in_browser_failed;

  /// No description provided for @telegram_sign_in_login_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось войти: {error}'**
  String telegram_sign_in_login_failed(Object error);

  /// No description provided for @yandex_sign_in_title.
  ///
  /// In ru, this message translates to:
  /// **'Вход через Яндекс'**
  String get yandex_sign_in_title;

  /// No description provided for @yandex_sign_in_open_in_browser.
  ///
  /// In ru, this message translates to:
  /// **'Открыть в браузере'**
  String get yandex_sign_in_open_in_browser;

  /// No description provided for @yandex_sign_in_page_load_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки страницы'**
  String get yandex_sign_in_page_load_error;

  /// No description provided for @yandex_sign_in_login_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка входа через Яндекс.'**
  String get yandex_sign_in_login_error;

  /// No description provided for @yandex_sign_in_firebase_not_ready.
  ///
  /// In ru, this message translates to:
  /// **'Firebase не готов.'**
  String get yandex_sign_in_firebase_not_ready;

  /// No description provided for @yandex_sign_in_browser_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть браузер.'**
  String get yandex_sign_in_browser_failed;

  /// No description provided for @yandex_sign_in_login_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось войти: {error}'**
  String yandex_sign_in_login_failed(Object error);

  /// No description provided for @google_complete_title.
  ///
  /// In ru, this message translates to:
  /// **'Завершите регистрацию'**
  String get google_complete_title;

  /// No description provided for @google_complete_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'После входа через Google нужно заполнить профиль, как в веб-версии.'**
  String get google_complete_subtitle;

  /// No description provided for @google_complete_name_label.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get google_complete_name_label;

  /// No description provided for @google_complete_username_label.
  ///
  /// In ru, this message translates to:
  /// **'Логин (@username)'**
  String get google_complete_username_label;

  /// No description provided for @google_complete_phone_label.
  ///
  /// In ru, this message translates to:
  /// **'Телефон (11 цифр)'**
  String get google_complete_phone_label;

  /// No description provided for @google_complete_email_label.
  ///
  /// In ru, this message translates to:
  /// **'Email'**
  String get google_complete_email_label;

  /// No description provided for @google_complete_email_hint.
  ///
  /// In ru, this message translates to:
  /// **'you@example.com'**
  String get google_complete_email_hint;

  /// No description provided for @google_complete_dob_label.
  ///
  /// In ru, this message translates to:
  /// **'Дата рождения (YYYY-MM-DD, опционально)'**
  String get google_complete_dob_label;

  /// No description provided for @google_complete_bio_label.
  ///
  /// In ru, this message translates to:
  /// **'О себе (до 200 символов, опционально)'**
  String get google_complete_bio_label;

  /// No description provided for @google_complete_save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить и продолжить'**
  String get google_complete_save;

  /// No description provided for @google_complete_back.
  ///
  /// In ru, this message translates to:
  /// **'Вернуться к авторизации'**
  String get google_complete_back;

  /// No description provided for @game_error_defense_not_beat.
  ///
  /// In ru, this message translates to:
  /// **'Эта карта не бьет атакующую'**
  String get game_error_defense_not_beat;

  /// No description provided for @game_error_attacker_first.
  ///
  /// In ru, this message translates to:
  /// **'Первым ходит атакующий игрок'**
  String get game_error_attacker_first;

  /// No description provided for @game_error_defender_no_attack.
  ///
  /// In ru, this message translates to:
  /// **'Отбивающийся сейчас не подкидывает'**
  String get game_error_defender_no_attack;

  /// No description provided for @game_error_not_allowed_throwin.
  ///
  /// In ru, this message translates to:
  /// **'Вы не можете подкинуть в этом раунде'**
  String get game_error_not_allowed_throwin;

  /// No description provided for @game_error_throwin_not_turn.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас подкидывает другой игрок'**
  String get game_error_throwin_not_turn;

  /// No description provided for @game_error_rank_not_allowed.
  ///
  /// In ru, this message translates to:
  /// **'Подкинуть можно только карту того же ранга'**
  String get game_error_rank_not_allowed;

  /// No description provided for @game_error_cannot_throw_in.
  ///
  /// In ru, this message translates to:
  /// **'Больше карт подкинуть нельзя'**
  String get game_error_cannot_throw_in;

  /// No description provided for @game_error_card_not_in_hand.
  ///
  /// In ru, this message translates to:
  /// **'Этой карты уже нет в руке'**
  String get game_error_card_not_in_hand;

  /// No description provided for @game_error_already_defended.
  ///
  /// In ru, this message translates to:
  /// **'Эта карта уже отбита'**
  String get game_error_already_defended;

  /// No description provided for @game_error_bad_attack_index.
  ///
  /// In ru, this message translates to:
  /// **'Выберите атакующую карту для защиты'**
  String get game_error_bad_attack_index;

  /// No description provided for @game_error_only_defender.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас отбивается другой игрок'**
  String get game_error_only_defender;

  /// No description provided for @game_error_defender_taking.
  ///
  /// In ru, this message translates to:
  /// **'Отбивающийся уже берет карты'**
  String get game_error_defender_taking;

  /// No description provided for @game_error_game_not_active.
  ///
  /// In ru, this message translates to:
  /// **'Партия уже не активна'**
  String get game_error_game_not_active;

  /// No description provided for @game_error_not_in_lobby.
  ///
  /// In ru, this message translates to:
  /// **'Лобби уже стартовало'**
  String get game_error_not_in_lobby;

  /// No description provided for @game_error_game_already_active.
  ///
  /// In ru, this message translates to:
  /// **'Партия уже началась'**
  String get game_error_game_already_active;

  /// No description provided for @game_error_active_exists.
  ///
  /// In ru, this message translates to:
  /// **'В этом чате уже есть активная партия'**
  String get game_error_active_exists;

  /// No description provided for @game_error_round_pending.
  ///
  /// In ru, this message translates to:
  /// **'Сначала завершите спорный ход'**
  String get game_error_round_pending;

  /// No description provided for @game_error_rematch_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось подготовить реванш. Попробуйте ��ще раз'**
  String get game_error_rematch_failed;

  /// No description provided for @game_error_unauthenticated.
  ///
  /// In ru, this message translates to:
  /// **'Нужно войти в аккаунт'**
  String get game_error_unauthenticated;

  /// No description provided for @game_error_permission_denied.
  ///
  /// In ru, this message translates to:
  /// **'Это действие вам недоступно'**
  String get game_error_permission_denied;

  /// No description provided for @game_error_invalid_argument.
  ///
  /// In ru, this message translates to:
  /// **'Некорректный ход'**
  String get game_error_invalid_argument;

  /// No description provided for @game_error_precondition.
  ///
  /// In ru, this message translates to:
  /// **'Ход сейчас недоступен'**
  String get game_error_precondition;

  /// No description provided for @game_error_server.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выполнить ход. Попробуйте еще раз'**
  String get game_error_server;

  /// No description provided for @reply_sticker.
  ///
  /// In ru, this message translates to:
  /// **'Стикер'**
  String get reply_sticker;

  /// No description provided for @reply_gif.
  ///
  /// In ru, this message translates to:
  /// **'GIF'**
  String get reply_gif;

  /// No description provided for @reply_video_circle.
  ///
  /// In ru, this message translates to:
  /// **'Кружок'**
  String get reply_video_circle;

  /// No description provided for @reply_voice_message.
  ///
  /// In ru, this message translates to:
  /// **'Голосовое сообщение'**
  String get reply_voice_message;

  /// No description provided for @reply_video.
  ///
  /// In ru, this message translates to:
  /// **'Видео'**
  String get reply_video;

  /// No description provided for @reply_photo.
  ///
  /// In ru, this message translates to:
  /// **'Фотография'**
  String get reply_photo;

  /// No description provided for @reply_file.
  ///
  /// In ru, this message translates to:
  /// **'Файл'**
  String get reply_file;

  /// No description provided for @reply_location.
  ///
  /// In ru, this message translates to:
  /// **'Локация'**
  String get reply_location;

  /// No description provided for @reply_poll.
  ///
  /// In ru, this message translates to:
  /// **'Опрос'**
  String get reply_poll;

  /// No description provided for @reply_link.
  ///
  /// In ru, this message translates to:
  /// **'Ссылка'**
  String get reply_link;

  /// No description provided for @reply_message.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение'**
  String get reply_message;

  /// No description provided for @reply_sender_you.
  ///
  /// In ru, this message translates to:
  /// **'Вы'**
  String get reply_sender_you;

  /// No description provided for @reply_sender_member.
  ///
  /// In ru, this message translates to:
  /// **'Участник'**
  String get reply_sender_member;

  /// No description provided for @call_format_today.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get call_format_today;

  /// No description provided for @call_format_yesterday.
  ///
  /// In ru, this message translates to:
  /// **'Вчера'**
  String get call_format_yesterday;

  /// No description provided for @call_format_second_short.
  ///
  /// In ru, this message translates to:
  /// **'с'**
  String get call_format_second_short;

  /// No description provided for @call_format_minute_short.
  ///
  /// In ru, this message translates to:
  /// **'м'**
  String get call_format_minute_short;

  /// No description provided for @call_format_hour_short.
  ///
  /// In ru, this message translates to:
  /// **'ч'**
  String get call_format_hour_short;

  /// No description provided for @call_format_day_short.
  ///
  /// In ru, this message translates to:
  /// **'д'**
  String get call_format_day_short;

  /// No description provided for @call_month_january.
  ///
  /// In ru, this message translates to:
  /// **'января'**
  String get call_month_january;

  /// No description provided for @call_month_february.
  ///
  /// In ru, this message translates to:
  /// **'февраля'**
  String get call_month_february;

  /// No description provided for @call_month_march.
  ///
  /// In ru, this message translates to:
  /// **'марта'**
  String get call_month_march;

  /// No description provided for @call_month_april.
  ///
  /// In ru, this message translates to:
  /// **'апреля'**
  String get call_month_april;

  /// No description provided for @call_month_may.
  ///
  /// In ru, this message translates to:
  /// **'мая'**
  String get call_month_may;

  /// No description provided for @call_month_june.
  ///
  /// In ru, this message translates to:
  /// **'июня'**
  String get call_month_june;

  /// No description provided for @call_month_july.
  ///
  /// In ru, this message translates to:
  /// **'июля'**
  String get call_month_july;

  /// No description provided for @call_month_august.
  ///
  /// In ru, this message translates to:
  /// **'августа'**
  String get call_month_august;

  /// No description provided for @call_month_september.
  ///
  /// In ru, this message translates to:
  /// **'сентября'**
  String get call_month_september;

  /// No description provided for @call_month_october.
  ///
  /// In ru, this message translates to:
  /// **'октября'**
  String get call_month_october;

  /// No description provided for @call_month_november.
  ///
  /// In ru, this message translates to:
  /// **'ноября'**
  String get call_month_november;

  /// No description provided for @call_month_december.
  ///
  /// In ru, this message translates to:
  /// **'декабря'**
  String get call_month_december;

  /// No description provided for @push_incoming_call.
  ///
  /// In ru, this message translates to:
  /// **'Входящий звонок'**
  String get push_incoming_call;

  /// No description provided for @push_incoming_video_call.
  ///
  /// In ru, this message translates to:
  /// **'Входящий видеозвонок'**
  String get push_incoming_video_call;

  /// No description provided for @push_new_message.
  ///
  /// In ru, this message translates to:
  /// **'Новое сообщение'**
  String get push_new_message;

  /// No description provided for @push_channel_calls.
  ///
  /// In ru, this message translates to:
  /// **'Звонки'**
  String get push_channel_calls;

  /// No description provided for @push_channel_messages.
  ///
  /// In ru, this message translates to:
  /// **'Сообщения'**
  String get push_channel_messages;

  /// No description provided for @contacts_years_one.
  ///
  /// In ru, this message translates to:
  /// **'{count} год'**
  String contacts_years_one(Object count);

  /// No description provided for @contacts_years_few.
  ///
  /// In ru, this message translates to:
  /// **'{count} года'**
  String contacts_years_few(Object count);

  /// No description provided for @contacts_years_many.
  ///
  /// In ru, this message translates to:
  /// **'{count} лет'**
  String contacts_years_many(Object count);

  /// No description provided for @contacts_years_other.
  ///
  /// In ru, this message translates to:
  /// **'{count} years'**
  String contacts_years_other(Object count);

  /// No description provided for @durak_entry_single_game.
  ///
  /// In ru, this message translates to:
  /// **'Одиночная партия'**
  String get durak_entry_single_game;

  /// No description provided for @durak_entry_finish_game_tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Завершить игру'**
  String get durak_entry_finish_game_tooltip;

  /// No description provided for @durak_entry_tournament_games_dialog_title.
  ///
  /// In ru, this message translates to:
  /// **'Сколько игр в турнире?'**
  String get durak_entry_tournament_games_dialog_title;

  /// No description provided for @durak_entry_cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get durak_entry_cancel;

  /// No description provided for @durak_entry_create.
  ///
  /// In ru, this message translates to:
  /// **'Создать'**
  String get durak_entry_create;

  /// No description provided for @video_editor_load_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить видео: {error}'**
  String video_editor_load_failed(Object error);

  /// No description provided for @video_editor_process_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обработать видео: {error}'**
  String video_editor_process_failed(Object error);

  /// No description provided for @video_editor_duration.
  ///
  /// In ru, this message translates to:
  /// **'Длительность: {duration}'**
  String video_editor_duration(Object duration);

  /// No description provided for @video_editor_brush.
  ///
  /// In ru, this message translates to:
  /// **'Кисть'**
  String get video_editor_brush;

  /// No description provided for @video_editor_caption_hint.
  ///
  /// In ru, this message translates to:
  /// **'Добавить подпись...'**
  String get video_editor_caption_hint;

  /// No description provided for @video_effects_speed.
  ///
  /// In ru, this message translates to:
  /// **'Скорость'**
  String get video_effects_speed;

  /// No description provided for @video_filter_none.
  ///
  /// In ru, this message translates to:
  /// **'Оригинал'**
  String get video_filter_none;

  /// No description provided for @video_filter_enhance.
  ///
  /// In ru, this message translates to:
  /// **'Улучшить'**
  String get video_filter_enhance;

  /// No description provided for @share_location_title.
  ///
  /// In ru, this message translates to:
  /// **'Поделиться геолокацией'**
  String get share_location_title;

  /// No description provided for @share_location_how.
  ///
  /// In ru, this message translates to:
  /// **'Как делиться'**
  String get share_location_how;

  /// No description provided for @share_location_cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get share_location_cancel;

  /// No description provided for @share_location_send.
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get share_location_send;

  /// No description provided for @photo_source_gallery.
  ///
  /// In ru, this message translates to:
  /// **'Галерея'**
  String get photo_source_gallery;

  /// No description provided for @photo_source_take_photo.
  ///
  /// In ru, this message translates to:
  /// **'Сделать фото'**
  String get photo_source_take_photo;

  /// No description provided for @photo_source_record_video.
  ///
  /// In ru, this message translates to:
  /// **'Записать видео'**
  String get photo_source_record_video;

  /// No description provided for @video_attachment_media_kind.
  ///
  /// In ru, this message translates to:
  /// **'видео'**
  String get video_attachment_media_kind;

  /// No description provided for @video_attachment_title.
  ///
  /// In ru, this message translates to:
  /// **'Видео'**
  String get video_attachment_title;

  /// No description provided for @video_attachment_playback_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось воспроизвести видео. Проверьте ссылку и сеть.'**
  String get video_attachment_playback_error;

  /// No description provided for @location_card_broadcast_ended_mine.
  ///
  /// In ru, this message translates to:
  /// **'Трансляция геолокации завершена. Собеседник больше не видит ваше актуальное местоположение.'**
  String get location_card_broadcast_ended_mine;

  /// No description provided for @location_card_broadcast_ended_other.
  ///
  /// In ru, this message translates to:
  /// **'Трансляция геолокации у этого контакта завершена. Актуальная позиция недоступна.'**
  String get location_card_broadcast_ended_other;

  /// No description provided for @location_card_title.
  ///
  /// In ru, this message translates to:
  /// **'Местоположение'**
  String get location_card_title;

  /// No description provided for @location_card_accuracy.
  ///
  /// In ru, this message translates to:
  /// **'±{meters} м'**
  String location_card_accuracy(Object meters);

  /// No description provided for @link_webview_copy_tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать ссылку'**
  String get link_webview_copy_tooltip;

  /// No description provided for @link_webview_copied_snackbar.
  ///
  /// In ru, this message translates to:
  /// **'Ссылка скопирована'**
  String get link_webview_copied_snackbar;

  /// No description provided for @link_webview_open_browser_tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Открыть в браузере'**
  String get link_webview_open_browser_tooltip;

  /// No description provided for @hold_record_pause.
  ///
  /// In ru, this message translates to:
  /// **'Пауза'**
  String get hold_record_pause;

  /// No description provided for @hold_record_release_cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отпустите — отмена'**
  String get hold_record_release_cancel;

  /// No description provided for @hold_record_slide_hints.
  ///
  /// In ru, this message translates to:
  /// **'Влево — отмена · Вверх — пауза'**
  String get hold_record_slide_hints;

  /// No description provided for @e2ee_badge_loading.
  ///
  /// In ru, this message translates to:
  /// **'Загружаем отпечаток…'**
  String get e2ee_badge_loading;

  /// No description provided for @e2ee_badge_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось получить отпечаток: {error}'**
  String e2ee_badge_error(Object error);

  /// No description provided for @e2ee_badge_label.
  ///
  /// In ru, this message translates to:
  /// **'Отпечаток E2EE'**
  String get e2ee_badge_label;

  /// No description provided for @e2ee_badge_label_with_user.
  ///
  /// In ru, this message translates to:
  /// **'Отпечаток E2EE • {user}'**
  String e2ee_badge_label_with_user(Object user);

  /// No description provided for @e2ee_badge_devices.
  ///
  /// In ru, this message translates to:
  /// **'{count} устр.'**
  String e2ee_badge_devices(Object count);

  /// No description provided for @composer_link_cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get composer_link_cancel;

  /// No description provided for @message_search_results_count.
  ///
  /// In ru, this message translates to:
  /// **'РЕЗУЛЬТАТЫ ПОИСКА: {count}'**
  String message_search_results_count(Object count);

  /// No description provided for @message_search_not_found.
  ///
  /// In ru, this message translates to:
  /// **'НИЧЕГО НЕ НАЙДЕНО'**
  String get message_search_not_found;

  /// No description provided for @message_search_participant_fallback.
  ///
  /// In ru, this message translates to:
  /// **'Участник'**
  String get message_search_participant_fallback;

  /// No description provided for @wallpaper_purple.
  ///
  /// In ru, this message translates to:
  /// **'Фиолетовый'**
  String get wallpaper_purple;

  /// No description provided for @wallpaper_pink.
  ///
  /// In ru, this message translates to:
  /// **'Розовый'**
  String get wallpaper_pink;

  /// No description provided for @wallpaper_blue.
  ///
  /// In ru, this message translates to:
  /// **'Голубой'**
  String get wallpaper_blue;

  /// No description provided for @wallpaper_green.
  ///
  /// In ru, this message translates to:
  /// **'Зелёный'**
  String get wallpaper_green;

  /// No description provided for @wallpaper_sunset.
  ///
  /// In ru, this message translates to:
  /// **'Закат'**
  String get wallpaper_sunset;

  /// No description provided for @wallpaper_tender.
  ///
  /// In ru, this message translates to:
  /// **'Нежный'**
  String get wallpaper_tender;

  /// No description provided for @wallpaper_lime.
  ///
  /// In ru, this message translates to:
  /// **'Лайм'**
  String get wallpaper_lime;

  /// No description provided for @wallpaper_graphite.
  ///
  /// In ru, this message translates to:
  /// **'Графит'**
  String get wallpaper_graphite;

  /// No description provided for @avatar_crop_title.
  ///
  /// In ru, this message translates to:
  /// **'Настройка аватара'**
  String get avatar_crop_title;

  /// No description provided for @avatar_crop_hint.
  ///
  /// In ru, this message translates to:
  /// **'Перетащите и масштабируйте — так круг будет в списках и сообщениях; полный кадр остаётся для профиля.'**
  String get avatar_crop_hint;

  /// No description provided for @avatar_crop_cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get avatar_crop_cancel;

  /// No description provided for @avatar_crop_reset.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить'**
  String get avatar_crop_reset;

  /// No description provided for @avatar_crop_save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get avatar_crop_save;

  /// No description provided for @meeting_entry_connecting.
  ///
  /// In ru, this message translates to:
  /// **'Подключаемся к митингу…'**
  String get meeting_entry_connecting;

  /// No description provided for @meeting_entry_auth_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось войти: {error}'**
  String meeting_entry_auth_failed(Object error);

  /// No description provided for @meeting_entry_participant_fallback.
  ///
  /// In ru, this message translates to:
  /// **'Участник'**
  String get meeting_entry_participant_fallback;

  /// No description provided for @meeting_entry_back.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get meeting_entry_back;

  /// No description provided for @meeting_chat_copy.
  ///
  /// In ru, this message translates to:
  /// **'Копировать'**
  String get meeting_chat_copy;

  /// No description provided for @meeting_chat_edit.
  ///
  /// In ru, this message translates to:
  /// **'Изменить'**
  String get meeting_chat_edit;

  /// No description provided for @meeting_chat_delete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get meeting_chat_delete;

  /// No description provided for @meeting_chat_deleted.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение удалено'**
  String get meeting_chat_deleted;

  /// No description provided for @meeting_chat_edited_mark.
  ///
  /// In ru, this message translates to:
  /// **'• изм.'**
  String get meeting_chat_edited_mark;

  /// No description provided for @meeting_chat_reply.
  ///
  /// In ru, this message translates to:
  /// **'Ответить'**
  String get meeting_chat_reply;

  /// No description provided for @meeting_chat_react.
  ///
  /// In ru, this message translates to:
  /// **'Реакция'**
  String get meeting_chat_react;

  /// No description provided for @meeting_chat_copied.
  ///
  /// In ru, this message translates to:
  /// **'Скопировано'**
  String get meeting_chat_copied;

  /// No description provided for @meeting_chat_editing.
  ///
  /// In ru, this message translates to:
  /// **'Редактирование'**
  String get meeting_chat_editing;

  /// No description provided for @meeting_chat_reply_to.
  ///
  /// In ru, this message translates to:
  /// **'Ответ {name}'**
  String meeting_chat_reply_to(Object name);

  /// No description provided for @meeting_chat_attachment_placeholder.
  ///
  /// In ru, this message translates to:
  /// **'Вложение'**
  String get meeting_chat_attachment_placeholder;

  /// No description provided for @meeting_timer_remaining.
  ///
  /// In ru, this message translates to:
  /// **'Осталось {time}'**
  String meeting_timer_remaining(Object time);

  /// No description provided for @meeting_timer_elapsed.
  ///
  /// In ru, this message translates to:
  /// **'{time}'**
  String meeting_timer_elapsed(Object time);

  /// No description provided for @meeting_back_to_chats.
  ///
  /// In ru, this message translates to:
  /// **'К чатам'**
  String get meeting_back_to_chats;

  /// No description provided for @meeting_open_chats.
  ///
  /// In ru, this message translates to:
  /// **'Открыть чаты'**
  String get meeting_open_chats;

  /// No description provided for @meeting_in_call_chat.
  ///
  /// In ru, this message translates to:
  /// **'Чат конференции'**
  String get meeting_in_call_chat;

  /// No description provided for @meeting_lobby_open_settings.
  ///
  /// In ru, this message translates to:
  /// **'Открыть настройки'**
  String get meeting_lobby_open_settings;

  /// No description provided for @meeting_lobby_retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get meeting_lobby_retry;

  /// No description provided for @meeting_minimized_resume.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите, чтобы вернуться'**
  String get meeting_minimized_resume;

  /// No description provided for @e2ee_decrypt_image_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось расшифровать изображение'**
  String get e2ee_decrypt_image_failed;

  /// No description provided for @e2ee_decrypt_video_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось расшифровать видео'**
  String get e2ee_decrypt_video_failed;

  /// No description provided for @e2ee_decrypt_audio_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось расшифровать аудио'**
  String get e2ee_decrypt_audio_failed;

  /// No description provided for @e2ee_decrypt_attachment_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось расшифровать вложение'**
  String get e2ee_decrypt_attachment_failed;

  /// No description provided for @search_preview_attachment.
  ///
  /// In ru, this message translates to:
  /// **'Вложение'**
  String get search_preview_attachment;

  /// No description provided for @search_preview_location.
  ///
  /// In ru, this message translates to:
  /// **'Геолокация'**
  String get search_preview_location;

  /// No description provided for @search_preview_message.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение'**
  String get search_preview_message;

  /// No description provided for @outbox_attachment_singular.
  ///
  /// In ru, this message translates to:
  /// **'Вложение'**
  String get outbox_attachment_singular;

  /// No description provided for @outbox_attachments_count.
  ///
  /// In ru, this message translates to:
  /// **'Вложения ({count})'**
  String outbox_attachments_count(int count);

  /// No description provided for @outbox_chat_unavailable.
  ///
  /// In ru, this message translates to:
  /// **'Сервис чата недоступен'**
  String get outbox_chat_unavailable;

  /// No description provided for @outbox_encryption_error.
  ///
  /// In ru, this message translates to:
  /// **'Шифрование: {code}'**
  String outbox_encryption_error(String code);

  /// No description provided for @nav_chats.
  ///
  /// In ru, this message translates to:
  /// **'Чаты'**
  String get nav_chats;

  /// No description provided for @nav_contacts.
  ///
  /// In ru, this message translates to:
  /// **'Контакты'**
  String get nav_contacts;

  /// No description provided for @nav_meetings.
  ///
  /// In ru, this message translates to:
  /// **'Конференции'**
  String get nav_meetings;

  /// No description provided for @nav_calls.
  ///
  /// In ru, this message translates to:
  /// **'Звонки'**
  String get nav_calls;

  /// No description provided for @e2ee_media_decrypt_failed_image.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось расшифровать изображение'**
  String get e2ee_media_decrypt_failed_image;

  /// No description provided for @e2ee_media_decrypt_failed_video.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось расшифровать видео'**
  String get e2ee_media_decrypt_failed_video;

  /// No description provided for @e2ee_media_decrypt_failed_audio.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось расшифровать аудио'**
  String get e2ee_media_decrypt_failed_audio;

  /// No description provided for @e2ee_media_decrypt_failed_attachment.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось расшифровать вложение'**
  String get e2ee_media_decrypt_failed_attachment;

  /// No description provided for @chat_search_snippet_attachment.
  ///
  /// In ru, this message translates to:
  /// **'Вложение'**
  String get chat_search_snippet_attachment;

  /// No description provided for @chat_search_snippet_location.
  ///
  /// In ru, this message translates to:
  /// **'Геолокация'**
  String get chat_search_snippet_location;

  /// No description provided for @chat_search_snippet_message.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение'**
  String get chat_search_snippet_message;

  /// No description provided for @bottom_nav_chats.
  ///
  /// In ru, this message translates to:
  /// **'Чаты'**
  String get bottom_nav_chats;

  /// No description provided for @bottom_nav_contacts.
  ///
  /// In ru, this message translates to:
  /// **'Контакты'**
  String get bottom_nav_contacts;

  /// No description provided for @bottom_nav_meetings.
  ///
  /// In ru, this message translates to:
  /// **'Конференции'**
  String get bottom_nav_meetings;

  /// No description provided for @bottom_nav_calls.
  ///
  /// In ru, this message translates to:
  /// **'Звонки'**
  String get bottom_nav_calls;

  /// No description provided for @chat_list_swipe_folders.
  ///
  /// In ru, this message translates to:
  /// **'ПАПКИ'**
  String get chat_list_swipe_folders;

  /// No description provided for @chat_list_swipe_clear.
  ///
  /// In ru, this message translates to:
  /// **'ОЧИСТИТЬ'**
  String get chat_list_swipe_clear;

  /// No description provided for @chat_list_swipe_delete.
  ///
  /// In ru, this message translates to:
  /// **'УДАЛИТЬ'**
  String get chat_list_swipe_delete;

  /// No description provided for @composer_editing_title.
  ///
  /// In ru, this message translates to:
  /// **'РЕДАКТИРОВАНИЕ СООБЩЕНИЯ'**
  String get composer_editing_title;

  /// No description provided for @composer_editing_cancel_tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Отменить редактирование'**
  String get composer_editing_cancel_tooltip;

  /// No description provided for @composer_formatting_title.
  ///
  /// In ru, this message translates to:
  /// **'ФОРМАТИРОВАНИЕ'**
  String get composer_formatting_title;

  /// No description provided for @composer_link_preview_loading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка превью…'**
  String get composer_link_preview_loading;

  /// No description provided for @composer_link_preview_hide_tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть превью'**
  String get composer_link_preview_hide_tooltip;

  /// No description provided for @chat_invite_button.
  ///
  /// In ru, this message translates to:
  /// **'Пригласить'**
  String get chat_invite_button;

  /// No description provided for @forward_preview_unknown_sender.
  ///
  /// In ru, this message translates to:
  /// **'Неизвестный'**
  String get forward_preview_unknown_sender;

  /// No description provided for @forward_preview_attachment.
  ///
  /// In ru, this message translates to:
  /// **'Вложение'**
  String get forward_preview_attachment;

  /// No description provided for @forward_preview_message.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение'**
  String get forward_preview_message;

  /// No description provided for @chat_mention_no_matches.
  ///
  /// In ru, this message translates to:
  /// **'Нет совпадений'**
  String get chat_mention_no_matches;

  /// No description provided for @live_location_sharing.
  ///
  /// In ru, this message translates to:
  /// **'Вы делитесь геолокацией'**
  String get live_location_sharing;

  /// No description provided for @live_location_stop.
  ///
  /// In ru, this message translates to:
  /// **'Остановить'**
  String get live_location_stop;

  /// No description provided for @chat_message_deleted.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение удалено'**
  String get chat_message_deleted;

  /// No description provided for @profile_qr_share.
  ///
  /// In ru, this message translates to:
  /// **'Поделиться'**
  String get profile_qr_share;

  /// No description provided for @shared_location_open_browser_tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Открыть в браузере'**
  String get shared_location_open_browser_tooltip;

  /// No description provided for @reply_preview_message_fallback.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение'**
  String get reply_preview_message_fallback;

  /// No description provided for @video_circle_media_kind.
  ///
  /// In ru, this message translates to:
  /// **'видео'**
  String get video_circle_media_kind;

  /// No description provided for @reactions_rated_count.
  ///
  /// In ru, this message translates to:
  /// **'Оценили: {count}'**
  String reactions_rated_count(int count);

  /// No description provided for @reactions_today_time.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня, {time}'**
  String reactions_today_time(String time);

  /// No description provided for @durak_create_timer_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'По умолчанию 15 секунд'**
  String get durak_create_timer_subtitle;

  /// No description provided for @dm_game_banner_active.
  ///
  /// In ru, this message translates to:
  /// **'Партия \"Дурак\" идёт'**
  String get dm_game_banner_active;

  /// No description provided for @dm_game_banner_created.
  ///
  /// In ru, this message translates to:
  /// **'Игра \"Дурак\" создана'**
  String get dm_game_banner_created;

  /// No description provided for @chat_folder_favorites.
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get chat_folder_favorites;

  /// No description provided for @chat_folder_new.
  ///
  /// In ru, this message translates to:
  /// **'Новая'**
  String get chat_folder_new;

  /// No description provided for @contact_profile_user_fallback.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь'**
  String get contact_profile_user_fallback;

  /// No description provided for @contact_profile_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка: {error}'**
  String contact_profile_error(String error);

  /// No description provided for @conversation_threads_loading_title.
  ///
  /// In ru, this message translates to:
  /// **'Обсуждения'**
  String get conversation_threads_loading_title;

  /// No description provided for @theme_label_light.
  ///
  /// In ru, this message translates to:
  /// **'Светлая'**
  String get theme_label_light;

  /// No description provided for @theme_label_dark.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная'**
  String get theme_label_dark;

  /// No description provided for @theme_label_auto.
  ///
  /// In ru, this message translates to:
  /// **'Авто'**
  String get theme_label_auto;

  /// No description provided for @chat_draft_reply_fallback.
  ///
  /// In ru, this message translates to:
  /// **'Ответ'**
  String get chat_draft_reply_fallback;

  /// No description provided for @mention_default_label.
  ///
  /// In ru, this message translates to:
  /// **'Участник'**
  String get mention_default_label;

  /// No description provided for @contacts_fallback_name.
  ///
  /// In ru, this message translates to:
  /// **'Контакт'**
  String get contacts_fallback_name;

  /// No description provided for @sticker_pack_default_name.
  ///
  /// In ru, this message translates to:
  /// **'Мой пак'**
  String get sticker_pack_default_name;

  /// No description provided for @profile_error_phone_taken.
  ///
  /// In ru, this message translates to:
  /// **'Этот номер телефона уже зарегистрирован. Укажите другой номер.'**
  String get profile_error_phone_taken;

  /// No description provided for @profile_error_email_taken.
  ///
  /// In ru, this message translates to:
  /// **'Этот email уже занят. Укажите другой адрес.'**
  String get profile_error_email_taken;

  /// No description provided for @profile_error_username_taken.
  ///
  /// In ru, this message translates to:
  /// **'Этот логин уже занят. Выберите другой.'**
  String get profile_error_username_taken;

  /// No description provided for @e2ee_banner_default_context.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение'**
  String get e2ee_banner_default_context;

  /// No description provided for @e2ee_banner_encrypted_chat_web_only.
  ///
  /// In ru, this message translates to:
  /// **'{prefix} в зашифрованный чат пока можно отправить только с веб‑клиента.'**
  String e2ee_banner_encrypted_chat_web_only(String prefix);

  /// No description provided for @chat_attachment_decrypt_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось расшифровать вложение'**
  String get chat_attachment_decrypt_error;

  /// No description provided for @mention_fallback_label.
  ///
  /// In ru, this message translates to:
  /// **'участник'**
  String get mention_fallback_label;

  /// No description provided for @mention_fallback_label_capitalized.
  ///
  /// In ru, this message translates to:
  /// **'Участник'**
  String get mention_fallback_label_capitalized;

  /// No description provided for @meeting_speaking_label.
  ///
  /// In ru, this message translates to:
  /// **'Говорит'**
  String get meeting_speaking_label;

  /// No description provided for @meeting_local_you_suffix.
  ///
  /// In ru, this message translates to:
  /// **'{name} (Вы)'**
  String meeting_local_you_suffix(String name);

  /// No description provided for @video_crop_title.
  ///
  /// In ru, this message translates to:
  /// **'Обрезка'**
  String get video_crop_title;

  /// No description provided for @video_crop_load_error.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить видео: {error}'**
  String video_crop_load_error(String error);

  /// No description provided for @gif_section_recent.
  ///
  /// In ru, this message translates to:
  /// **'НЕДАВНИЕ'**
  String get gif_section_recent;

  /// No description provided for @gif_section_trending.
  ///
  /// In ru, this message translates to:
  /// **'TRENDING'**
  String get gif_section_trending;

  /// No description provided for @auth_create_account_title.
  ///
  /// In ru, this message translates to:
  /// **'Создать аккаунт'**
  String get auth_create_account_title;

  /// No description provided for @yandex_sign_in_yandex_error.
  ///
  /// In ru, this message translates to:
  /// **'Яндекс: {error}'**
  String yandex_sign_in_yandex_error(String error);

  /// No description provided for @call_status_missed.
  ///
  /// In ru, this message translates to:
  /// **'Пропущен'**
  String get call_status_missed;

  /// No description provided for @call_status_cancelled.
  ///
  /// In ru, this message translates to:
  /// **'Отменен'**
  String get call_status_cancelled;

  /// No description provided for @call_status_ended.
  ///
  /// In ru, this message translates to:
  /// **'Завершен'**
  String get call_status_ended;

  /// No description provided for @presence_offline.
  ///
  /// In ru, this message translates to:
  /// **'Не в сети'**
  String get presence_offline;

  /// No description provided for @presence_online.
  ///
  /// In ru, this message translates to:
  /// **'В сети'**
  String get presence_online;

  /// No description provided for @dm_title_fallback.
  ///
  /// In ru, this message translates to:
  /// **'Чат'**
  String get dm_title_fallback;

  /// No description provided for @dm_title_partner_fallback.
  ///
  /// In ru, this message translates to:
  /// **'Собеседник'**
  String get dm_title_partner_fallback;

  /// No description provided for @group_title_fallback.
  ///
  /// In ru, this message translates to:
  /// **'Групповой чат'**
  String get group_title_fallback;

  /// No description provided for @block_call_viewer_blocked.
  ///
  /// In ru, this message translates to:
  /// **'Вы заблокировали этого пользователя. Звонок недоступен — разблокируйте в Профиль → Заблокированные.'**
  String get block_call_viewer_blocked;

  /// No description provided for @block_call_partner_blocked.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь ограничил с вами общение. Звонок недоступен.'**
  String get block_call_partner_blocked;

  /// No description provided for @block_call_unavailable.
  ///
  /// In ru, this message translates to:
  /// **'Звонок недоступен.'**
  String get block_call_unavailable;

  /// No description provided for @block_composer_viewer_blocked.
  ///
  /// In ru, this message translates to:
  /// **'Вы заблокировали этого пользователя. Отправка недоступна — разблокируйте в Профиль → Заблокированные.'**
  String get block_composer_viewer_blocked;

  /// No description provided for @block_composer_partner_blocked.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь ограничил с вами общение. Отправка недоступна.'**
  String get block_composer_partner_blocked;

  /// No description provided for @forward_group_fallback.
  ///
  /// In ru, this message translates to:
  /// **'Группа'**
  String get forward_group_fallback;

  /// No description provided for @forward_unknown_user.
  ///
  /// In ru, this message translates to:
  /// **'Неизвестный'**
  String get forward_unknown_user;

  /// No description provided for @live_location_once.
  ///
  /// In ru, this message translates to:
  /// **'Одноразово (только это сообщение)'**
  String get live_location_once;

  /// No description provided for @live_location_5min.
  ///
  /// In ru, this message translates to:
  /// **'5 минут'**
  String get live_location_5min;

  /// No description provided for @live_location_15min.
  ///
  /// In ru, this message translates to:
  /// **'15 минут'**
  String get live_location_15min;

  /// No description provided for @live_location_30min.
  ///
  /// In ru, this message translates to:
  /// **'30 минут'**
  String get live_location_30min;

  /// No description provided for @live_location_1hour.
  ///
  /// In ru, this message translates to:
  /// **'1 час'**
  String get live_location_1hour;

  /// No description provided for @live_location_2hours.
  ///
  /// In ru, this message translates to:
  /// **'2 часа'**
  String get live_location_2hours;

  /// No description provided for @live_location_6hours.
  ///
  /// In ru, this message translates to:
  /// **'6 часов'**
  String get live_location_6hours;

  /// No description provided for @live_location_1day.
  ///
  /// In ru, this message translates to:
  /// **'1 день'**
  String get live_location_1day;

  /// No description provided for @live_location_forever.
  ///
  /// In ru, this message translates to:
  /// **'Навсегда (пока не отключу)'**
  String get live_location_forever;

  /// No description provided for @e2ee_send_too_many_files.
  ///
  /// In ru, this message translates to:
  /// **'Слишком много вложений для зашифрованной отправки: максимум 5 файлов за сообщение.'**
  String get e2ee_send_too_many_files;

  /// No description provided for @e2ee_send_too_large.
  ///
  /// In ru, this message translates to:
  /// **'Слишком большой общий размер вложений: максимум 96 МБ для одного зашифрованного сообщения.'**
  String get e2ee_send_too_large;

  /// No description provided for @presence_last_seen_prefix.
  ///
  /// In ru, this message translates to:
  /// **'Был(а) '**
  String get presence_last_seen_prefix;

  /// No description provided for @presence_less_than_minute_ago.
  ///
  /// In ru, this message translates to:
  /// **'менее минуты назад'**
  String get presence_less_than_minute_ago;

  /// No description provided for @presence_yesterday.
  ///
  /// In ru, this message translates to:
  /// **'вчера'**
  String get presence_yesterday;

  /// No description provided for @dm_fallback_title.
  ///
  /// In ru, this message translates to:
  /// **'Чат'**
  String get dm_fallback_title;

  /// No description provided for @dm_fallback_partner.
  ///
  /// In ru, this message translates to:
  /// **'Собеседник'**
  String get dm_fallback_partner;

  /// No description provided for @group_fallback_title.
  ///
  /// In ru, this message translates to:
  /// **'Групповой чат'**
  String get group_fallback_title;

  /// No description provided for @block_send_viewer_blocked.
  ///
  /// In ru, this message translates to:
  /// **'Вы заблокировали этого пользователя. Отправка недоступна — разблокируйте в Профиль → Заблокированные.'**
  String get block_send_viewer_blocked;

  /// No description provided for @block_send_partner_blocked.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь ограничил с вами общение. Отправка недоступна.'**
  String get block_send_partner_blocked;

  /// No description provided for @mention_fallback_name.
  ///
  /// In ru, this message translates to:
  /// **'Участник'**
  String get mention_fallback_name;

  /// No description provided for @profile_conflict_phone.
  ///
  /// In ru, this message translates to:
  /// **'Этот номер телефона уже зарегистрирован. Укажите другой номер.'**
  String get profile_conflict_phone;

  /// No description provided for @profile_conflict_email.
  ///
  /// In ru, this message translates to:
  /// **'Этот email уже занят. Укажите другой адрес.'**
  String get profile_conflict_email;

  /// No description provided for @profile_conflict_username.
  ///
  /// In ru, this message translates to:
  /// **'Этот логин уже занят. Выберите другой.'**
  String get profile_conflict_username;

  /// No description provided for @mention_fallback_participant.
  ///
  /// In ru, this message translates to:
  /// **'Участник'**
  String get mention_fallback_participant;

  /// No description provided for @sticker_gif_recent.
  ///
  /// In ru, this message translates to:
  /// **'НЕДАВНИЕ'**
  String get sticker_gif_recent;

  /// No description provided for @meeting_screen_sharing.
  ///
  /// In ru, this message translates to:
  /// **'Экран'**
  String get meeting_screen_sharing;

  /// No description provided for @meeting_speaking.
  ///
  /// In ru, this message translates to:
  /// **'Говорит'**
  String get meeting_speaking;

  /// No description provided for @auth_sign_in_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось войти: {error}'**
  String auth_sign_in_failed(Object error);

  /// No description provided for @yandex_error_prefix.
  ///
  /// In ru, this message translates to:
  /// **'Яндекс: {error}'**
  String yandex_error_prefix(Object error);

  /// No description provided for @auth_error_prefix.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка авторизации: {error}'**
  String auth_error_prefix(Object error);

  /// No description provided for @presence_minutes_ago.
  ///
  /// In ru, this message translates to:
  /// **'{count,plural, one{{count} минуту назад} few{{count} минуты назад} many{{count} минут назад} other{{count} минут назад}}'**
  String presence_minutes_ago(int count);

  /// No description provided for @presence_hours_ago.
  ///
  /// In ru, this message translates to:
  /// **'{count,plural, one{{count} час назад} few{{count} часа назад} many{{count} часов назад} other{{count} часов назад}}'**
  String presence_hours_ago(int count);

  /// No description provided for @presence_days_ago.
  ///
  /// In ru, this message translates to:
  /// **'{count,plural, one{{count} день назад} few{{count} дня назад} many{{count} дней назад} other{{count} дней назад}}'**
  String presence_days_ago(int count);

  /// No description provided for @presence_months_ago.
  ///
  /// In ru, this message translates to:
  /// **'{count,plural, one{{count} месяц назад} few{{count} месяца назад} many{{count} месяцев назад} other{{count} месяцев назад}}'**
  String presence_months_ago(int count);

  /// No description provided for @presence_years_months_ago.
  ///
  /// In ru, this message translates to:
  /// **'{years,plural, one{{years} год} few{{years} года} many{{years} лет} other{{years} лет}} {months,plural, one{{months} месяц назад} few{{months} месяца назад} many{{months} месяцев назад} other{{months} месяцев назад}}'**
  String presence_years_months_ago(int years, int months);

  /// No description provided for @presence_years_ago.
  ///
  /// In ru, this message translates to:
  /// **'{count,plural, one{{count} год назад} few{{count} года назад} many{{count} лет назад} other{{count} лет назад}}'**
  String presence_years_ago(int count);

  /// No description provided for @wallpaper_gradient_purple.
  ///
  /// In ru, this message translates to:
  /// **'Фиолетовый'**
  String get wallpaper_gradient_purple;

  /// No description provided for @wallpaper_gradient_pink.
  ///
  /// In ru, this message translates to:
  /// **'Розовый'**
  String get wallpaper_gradient_pink;

  /// No description provided for @wallpaper_gradient_blue.
  ///
  /// In ru, this message translates to:
  /// **'Голубой'**
  String get wallpaper_gradient_blue;

  /// No description provided for @wallpaper_gradient_green.
  ///
  /// In ru, this message translates to:
  /// **'Зелёный'**
  String get wallpaper_gradient_green;

  /// No description provided for @wallpaper_gradient_sunset.
  ///
  /// In ru, this message translates to:
  /// **'Закат'**
  String get wallpaper_gradient_sunset;

  /// No description provided for @wallpaper_gradient_gentle.
  ///
  /// In ru, this message translates to:
  /// **'Нежный'**
  String get wallpaper_gradient_gentle;

  /// No description provided for @wallpaper_gradient_lime.
  ///
  /// In ru, this message translates to:
  /// **'Лайм'**
  String get wallpaper_gradient_lime;

  /// No description provided for @wallpaper_gradient_graphite.
  ///
  /// In ru, this message translates to:
  /// **'Графит'**
  String get wallpaper_gradient_graphite;

  /// No description provided for @sticker_tab_recent.
  ///
  /// In ru, this message translates to:
  /// **'НЕДАВНИЕ'**
  String get sticker_tab_recent;

  /// No description provided for @block_call_you_blocked.
  ///
  /// In ru, this message translates to:
  /// **'Вы заблокировали этого пользователя. Звонок недоступен — разблокируйте в Профиль → Заблокированные.'**
  String get block_call_you_blocked;

  /// No description provided for @block_call_they_blocked.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь ограничил с вами общение. Звонок недоступен.'**
  String get block_call_they_blocked;

  /// No description provided for @block_call_generic.
  ///
  /// In ru, this message translates to:
  /// **'Звонок недоступен.'**
  String get block_call_generic;

  /// No description provided for @block_send_you_blocked.
  ///
  /// In ru, this message translates to:
  /// **'Вы заблокировали этого пользователя. Отправка недоступна — разблокируйте в Профиль → Заблокированные.'**
  String get block_send_you_blocked;

  /// No description provided for @block_send_they_blocked.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь ограничил с вами общение. Отправка недоступна.'**
  String get block_send_they_blocked;

  /// No description provided for @forward_unknown_fallback.
  ///
  /// In ru, this message translates to:
  /// **'Неизвестный'**
  String get forward_unknown_fallback;

  /// No description provided for @dm_title_chat.
  ///
  /// In ru, this message translates to:
  /// **'Чат'**
  String get dm_title_chat;

  /// No description provided for @dm_title_partner.
  ///
  /// In ru, this message translates to:
  /// **'Собеседник'**
  String get dm_title_partner;

  /// No description provided for @dm_title_group.
  ///
  /// In ru, this message translates to:
  /// **'Групповой чат'**
  String get dm_title_group;

  /// No description provided for @e2ee_too_many_attachments.
  ///
  /// In ru, this message translates to:
  /// **'Слишком много вложений для зашифрованной отправки: максимум 5 файлов за сообщение.'**
  String get e2ee_too_many_attachments;

  /// No description provided for @e2ee_total_size_exceeded.
  ///
  /// In ru, this message translates to:
  /// **'Слишком большой общий размер вложений: максимум 96 МБ для одного зашифрованного сообщения.'**
  String get e2ee_total_size_exceeded;

  /// No description provided for @composer_limit_too_many_files.
  ///
  /// In ru, this message translates to:
  /// **'Слишком много вложений: {current}/{max}. Удалите {diff}, чтобы отправить.'**
  String composer_limit_too_many_files(int current, int max, int diff);

  /// No description provided for @composer_limit_total_size_exceeded.
  ///
  /// In ru, this message translates to:
  /// **'Слишком большой размер вложений: {currentMb} МБ / {maxMb} МБ. Удалите часть, чтобы отправить.'**
  String composer_limit_total_size_exceeded(String currentMb, String maxMb);

  /// No description provided for @composer_limit_blocking_send.
  ///
  /// In ru, this message translates to:
  /// **'Превышен лимит вложений'**
  String get composer_limit_blocking_send;

  /// No description provided for @yandex_sign_in_error_prefix.
  ///
  /// In ru, this message translates to:
  /// **'Яндекс: {error}'**
  String yandex_sign_in_error_prefix(String error);

  /// No description provided for @meeting_participant_screen.
  ///
  /// In ru, this message translates to:
  /// **'Экран'**
  String get meeting_participant_screen;

  /// No description provided for @meeting_participant_speaking.
  ///
  /// In ru, this message translates to:
  /// **'Говорит'**
  String get meeting_participant_speaking;

  /// No description provided for @nav_error_title.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка навигации'**
  String get nav_error_title;

  /// No description provided for @nav_error_invalid_secret_compose.
  ///
  /// In ru, this message translates to:
  /// **'Некорректная навигация секретного чата'**
  String get nav_error_invalid_secret_compose;

  /// No description provided for @sign_in_title.
  ///
  /// In ru, this message translates to:
  /// **'Вход'**
  String get sign_in_title;

  /// No description provided for @sign_in_firebase_ready.
  ///
  /// In ru, this message translates to:
  /// **'Firebase инициализирован. Можно войти.'**
  String get sign_in_firebase_ready;

  /// No description provided for @sign_in_firebase_not_ready.
  ///
  /// In ru, this message translates to:
  /// **'Firebase не готов. Проверьте логи и firebase_options.dart.'**
  String get sign_in_firebase_not_ready;

  /// No description provided for @sign_in_continue.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить'**
  String get sign_in_continue;

  /// No description provided for @sign_in_anonymously.
  ///
  /// In ru, this message translates to:
  /// **'Войти анонимно'**
  String get sign_in_anonymously;

  /// No description provided for @sign_in_auth_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка авторизации: {error}'**
  String sign_in_auth_error(String error);

  /// No description provided for @generic_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка: {error}'**
  String generic_error(String error);

  /// No description provided for @storage_label_video.
  ///
  /// In ru, this message translates to:
  /// **'Видео'**
  String get storage_label_video;

  /// No description provided for @storage_label_photo.
  ///
  /// In ru, this message translates to:
  /// **'Фото'**
  String get storage_label_photo;

  /// No description provided for @storage_label_audio.
  ///
  /// In ru, this message translates to:
  /// **'Аудио'**
  String get storage_label_audio;

  /// No description provided for @storage_label_files.
  ///
  /// In ru, this message translates to:
  /// **'Файлы'**
  String get storage_label_files;

  /// No description provided for @storage_label_other.
  ///
  /// In ru, this message translates to:
  /// **'Другое'**
  String get storage_label_other;

  /// No description provided for @storage_label_recent_stickers.
  ///
  /// In ru, this message translates to:
  /// **'Недавние стикеры'**
  String get storage_label_recent_stickers;

  /// No description provided for @storage_label_giphy_search.
  ///
  /// In ru, this message translates to:
  /// **'GIPHY · поисковый кэш'**
  String get storage_label_giphy_search;

  /// No description provided for @storage_label_giphy_recent.
  ///
  /// In ru, this message translates to:
  /// **'GIPHY · недавние GIF'**
  String get storage_label_giphy_recent;

  /// No description provided for @storage_chat_unattributed.
  ///
  /// In ru, this message translates to:
  /// **'Без привязки к чату'**
  String get storage_chat_unattributed;

  /// No description provided for @storage_label_draft.
  ///
  /// In ru, this message translates to:
  /// **'Черновик · {key}'**
  String storage_label_draft(String key);

  /// No description provided for @storage_label_offline_snapshot.
  ///
  /// In ru, this message translates to:
  /// **'Офлайн-снимок списка чатов'**
  String get storage_label_offline_snapshot;

  /// No description provided for @storage_label_profile_cache.
  ///
  /// In ru, this message translates to:
  /// **'Кэш профиля · {name}'**
  String storage_label_profile_cache(String name);

  /// No description provided for @call_mini_end.
  ///
  /// In ru, this message translates to:
  /// **'Завершить звонок'**
  String get call_mini_end;

  /// No description provided for @animation_quality_lite.
  ///
  /// In ru, this message translates to:
  /// **'Лёгкий'**
  String get animation_quality_lite;

  /// No description provided for @animation_quality_balanced.
  ///
  /// In ru, this message translates to:
  /// **'Баланс'**
  String get animation_quality_balanced;

  /// No description provided for @animation_quality_cinematic.
  ///
  /// In ru, this message translates to:
  /// **'Кино'**
  String get animation_quality_cinematic;

  /// No description provided for @crop_aspect_original.
  ///
  /// In ru, this message translates to:
  /// **'Оригинал'**
  String get crop_aspect_original;

  /// No description provided for @crop_aspect_square.
  ///
  /// In ru, this message translates to:
  /// **'Квадрат'**
  String get crop_aspect_square;

  /// No description provided for @push_notification_title.
  ///
  /// In ru, this message translates to:
  /// **'Разрешить уведомления'**
  String get push_notification_title;

  /// No description provided for @push_notification_rationale.
  ///
  /// In ru, this message translates to:
  /// **'Для входящих звонков приложению нужны уведомления.'**
  String get push_notification_rationale;

  /// No description provided for @push_notification_required.
  ///
  /// In ru, this message translates to:
  /// **'Включите уведомления для отображения входящих звонков.'**
  String get push_notification_required;

  /// No description provided for @push_notification_grant.
  ///
  /// In ru, this message translates to:
  /// **'Разрешить'**
  String get push_notification_grant;

  /// No description provided for @push_call_accept.
  ///
  /// In ru, this message translates to:
  /// **'Принять'**
  String get push_call_accept;

  /// No description provided for @push_call_decline.
  ///
  /// In ru, this message translates to:
  /// **'Отклонить'**
  String get push_call_decline;

  /// No description provided for @push_channel_incoming_calls.
  ///
  /// In ru, this message translates to:
  /// **'Входящие звонки'**
  String get push_channel_incoming_calls;

  /// No description provided for @push_channel_missed_calls.
  ///
  /// In ru, this message translates to:
  /// **'Пропущенные звонки'**
  String get push_channel_missed_calls;

  /// No description provided for @push_channel_messages_desc.
  ///
  /// In ru, this message translates to:
  /// **'Новые сообщения в чатах'**
  String get push_channel_messages_desc;

  /// No description provided for @push_channel_silent.
  ///
  /// In ru, this message translates to:
  /// **'Сообщения без звука'**
  String get push_channel_silent;

  /// No description provided for @push_channel_silent_desc.
  ///
  /// In ru, this message translates to:
  /// **'Push без звука'**
  String get push_channel_silent_desc;

  /// No description provided for @push_caller_unknown.
  ///
  /// In ru, this message translates to:
  /// **'Кто-то'**
  String get push_caller_unknown;

  /// No description provided for @outbox_attachment_single.
  ///
  /// In ru, this message translates to:
  /// **'Вложение'**
  String get outbox_attachment_single;

  /// No description provided for @outbox_attachment_count.
  ///
  /// In ru, this message translates to:
  /// **'Вложения ({count})'**
  String outbox_attachment_count(int count);

  /// No description provided for @bottom_nav_label_chats.
  ///
  /// In ru, this message translates to:
  /// **'Чаты'**
  String get bottom_nav_label_chats;

  /// No description provided for @bottom_nav_label_contacts.
  ///
  /// In ru, this message translates to:
  /// **'Контакты'**
  String get bottom_nav_label_contacts;

  /// No description provided for @bottom_nav_label_conferences.
  ///
  /// In ru, this message translates to:
  /// **'Конференции'**
  String get bottom_nav_label_conferences;

  /// No description provided for @bottom_nav_label_calls.
  ///
  /// In ru, this message translates to:
  /// **'Звонки'**
  String get bottom_nav_label_calls;

  /// No description provided for @welcomeBubbleTitle.
  ///
  /// In ru, this message translates to:
  /// **'Добро пожаловать в LighChat'**
  String get welcomeBubbleTitle;

  /// No description provided for @welcomeBubbleSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Маяк зажёгся'**
  String get welcomeBubbleSubtitle;

  /// No description provided for @welcomeSkip.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить'**
  String get welcomeSkip;

  /// No description provided for @welcomeReplayDebugTile.
  ///
  /// In ru, this message translates to:
  /// **'Replay welcome animation (debug)'**
  String get welcomeReplayDebugTile;

  /// No description provided for @sticker_scope_library.
  ///
  /// In ru, this message translates to:
  /// **'Библиотека'**
  String get sticker_scope_library;

  /// No description provided for @sticker_library_search_hint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск стикеров…'**
  String get sticker_library_search_hint;

  /// No description provided for @account_menu_energy_saving.
  ///
  /// In ru, this message translates to:
  /// **'Энергосбережение'**
  String get account_menu_energy_saving;

  /// No description provided for @energy_saving_title.
  ///
  /// In ru, this message translates to:
  /// **'Энергосбережение'**
  String get energy_saving_title;

  /// No description provided for @energy_saving_section_mode.
  ///
  /// In ru, this message translates to:
  /// **'Режим энергосбережения'**
  String get energy_saving_section_mode;

  /// No description provided for @energy_saving_section_resource_heavy.
  ///
  /// In ru, this message translates to:
  /// **'Ресурсоёмкие процессы'**
  String get energy_saving_section_resource_heavy;

  /// No description provided for @energy_saving_threshold_off.
  ///
  /// In ru, this message translates to:
  /// **'Выкл.'**
  String get energy_saving_threshold_off;

  /// No description provided for @energy_saving_threshold_always.
  ///
  /// In ru, this message translates to:
  /// **'Вкл.'**
  String get energy_saving_threshold_always;

  /// No description provided for @energy_saving_threshold_off_full.
  ///
  /// In ru, this message translates to:
  /// **'Никогда'**
  String get energy_saving_threshold_off_full;

  /// No description provided for @energy_saving_threshold_always_full.
  ///
  /// In ru, this message translates to:
  /// **'Всегда'**
  String get energy_saving_threshold_always_full;

  /// No description provided for @energy_saving_threshold_at.
  ///
  /// In ru, this message translates to:
  /// **'При заряде менее {percent}%'**
  String energy_saving_threshold_at(int percent);

  /// No description provided for @energy_saving_hint_off.
  ///
  /// In ru, this message translates to:
  /// **'Ресурсоёмкие эффекты никогда не отключаются автоматически.'**
  String get energy_saving_hint_off;

  /// No description provided for @energy_saving_hint_always.
  ///
  /// In ru, this message translates to:
  /// **'Ресурсоёмкие эффекты всегда отключены, независимо от уровня заряда.'**
  String get energy_saving_hint_always;

  /// No description provided for @energy_saving_hint_threshold.
  ///
  /// In ru, this message translates to:
  /// **'Автоматически отключать все ресурсоёмкие процессы при заряде менее {percent}%.'**
  String energy_saving_hint_threshold(int percent);

  /// No description provided for @energy_saving_current_battery.
  ///
  /// In ru, this message translates to:
  /// **'Текущий заряд: {percent}%'**
  String energy_saving_current_battery(int percent);

  /// No description provided for @energy_saving_active_now.
  ///
  /// In ru, this message translates to:
  /// **'режим активен'**
  String get energy_saving_active_now;

  /// No description provided for @energy_saving_active_threshold.
  ///
  /// In ru, this message translates to:
  /// **'Заряд достиг порога — все эффекты ниже временно отключены.'**
  String get energy_saving_active_threshold;

  /// No description provided for @energy_saving_active_system.
  ///
  /// In ru, this message translates to:
  /// **'Включён системный режим энергосбережения — все эффекты ниже временно отключены.'**
  String get energy_saving_active_system;

  /// No description provided for @energy_saving_autoplay_video_title.
  ///
  /// In ru, this message translates to:
  /// **'Автозапуск видео'**
  String get energy_saving_autoplay_video_title;

  /// No description provided for @energy_saving_autoplay_video_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Автозапуск и повторение видеосообщений и видео в чатах.'**
  String get energy_saving_autoplay_video_subtitle;

  /// No description provided for @energy_saving_autoplay_gif_title.
  ///
  /// In ru, this message translates to:
  /// **'Автозапуск GIF'**
  String get energy_saving_autoplay_gif_title;

  /// No description provided for @energy_saving_autoplay_gif_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Автозапуск и повторение GIF в чатах и на клавиатуре.'**
  String get energy_saving_autoplay_gif_subtitle;

  /// No description provided for @energy_saving_animated_stickers_title.
  ///
  /// In ru, this message translates to:
  /// **'Анимированные стикеры'**
  String get energy_saving_animated_stickers_title;

  /// No description provided for @energy_saving_animated_stickers_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Повторяющаяся анимация стикеров и полноэкранные эффекты Premium-стикеров.'**
  String get energy_saving_animated_stickers_subtitle;

  /// No description provided for @energy_saving_animated_emoji_title.
  ///
  /// In ru, this message translates to:
  /// **'Анимированные эмодзи'**
  String get energy_saving_animated_emoji_title;

  /// No description provided for @energy_saving_animated_emoji_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Повторяющаяся анимация эмодзи в сообщениях, реакциях и статусах.'**
  String get energy_saving_animated_emoji_subtitle;

  /// No description provided for @energy_saving_interface_animations_title.
  ///
  /// In ru, this message translates to:
  /// **'Анимации интерфейса'**
  String get energy_saving_interface_animations_title;

  /// No description provided for @energy_saving_interface_animations_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Эффекты и анимации, которые делают LighChat плавнее и выразительнее.'**
  String get energy_saving_interface_animations_subtitle;

  /// No description provided for @energy_saving_media_preload_title.
  ///
  /// In ru, this message translates to:
  /// **'Предзагрузка медиа'**
  String get energy_saving_media_preload_title;

  /// No description provided for @energy_saving_media_preload_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Запуск загрузки медиафайлов при входе в список чатов.'**
  String get energy_saving_media_preload_subtitle;

  /// No description provided for @energy_saving_background_update_title.
  ///
  /// In ru, this message translates to:
  /// **'Обновление в фоне'**
  String get energy_saving_background_update_title;

  /// No description provided for @energy_saving_background_update_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Быстрое обновление чатов при переключении между приложениями.'**
  String get energy_saving_background_update_subtitle;

  /// No description provided for @legal_index_title.
  ///
  /// In ru, this message translates to:
  /// **'Юридические документы'**
  String get legal_index_title;

  /// No description provided for @legal_index_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Политика конфиденциальности, пользовательское соглашение и другие юридические документы, регулирующие использование LighChat.'**
  String get legal_index_subtitle;

  /// No description provided for @legal_settings_section_title.
  ///
  /// In ru, this message translates to:
  /// **'Правовая информация'**
  String get legal_settings_section_title;

  /// No description provided for @legal_settings_section_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Политика конфиденциальности, пользовательское соглашение, EULA и другие документы.'**
  String get legal_settings_section_subtitle;

  /// No description provided for @legal_not_found.
  ///
  /// In ru, this message translates to:
  /// **'Документ не найден'**
  String get legal_not_found;

  /// No description provided for @legal_title_privacy_policy.
  ///
  /// In ru, this message translates to:
  /// **'Политика конфиденциальности'**
  String get legal_title_privacy_policy;

  /// No description provided for @legal_title_terms_of_service.
  ///
  /// In ru, this message translates to:
  /// **'Пользовательское соглашение'**
  String get legal_title_terms_of_service;

  /// No description provided for @legal_title_cookie_policy.
  ///
  /// In ru, this message translates to:
  /// **'Политика использования cookies'**
  String get legal_title_cookie_policy;

  /// No description provided for @legal_title_eula.
  ///
  /// In ru, this message translates to:
  /// **'Лицензионное соглашение (EULA)'**
  String get legal_title_eula;

  /// No description provided for @legal_title_dpa.
  ///
  /// In ru, this message translates to:
  /// **'Соглашение об обработке данных (DPA)'**
  String get legal_title_dpa;

  /// No description provided for @legal_title_children.
  ///
  /// In ru, this message translates to:
  /// **'Политика в отношении несовершеннолетних'**
  String get legal_title_children;

  /// No description provided for @legal_title_moderation.
  ///
  /// In ru, this message translates to:
  /// **'Политика модерации контента'**
  String get legal_title_moderation;

  /// No description provided for @legal_title_aup.
  ///
  /// In ru, this message translates to:
  /// **'Правила допустимого использования'**
  String get legal_title_aup;

  /// Label for current user as sender in chat list preview
  ///
  /// In ru, this message translates to:
  /// **'Вы'**
  String get chat_list_item_sender_you;

  /// Chat list preview: chat_preview_message
  ///
  /// In ru, this message translates to:
  /// **'Сообщение'**
  String get chat_preview_message;

  /// Chat list preview: chat_preview_sticker
  ///
  /// In ru, this message translates to:
  /// **'Стикер'**
  String get chat_preview_sticker;

  /// Chat list preview: chat_preview_attachment
  ///
  /// In ru, this message translates to:
  /// **'Вложение'**
  String get chat_preview_attachment;

  /// Contacts prominent disclosure dialog title
  ///
  /// In ru, this message translates to:
  /// **'Поиск знакомых в LighChat'**
  String get contacts_disclosure_title;

  /// Contacts prominent disclosure dialog body
  ///
  /// In ru, this message translates to:
  /// **'LighChat считывает телефонные номера и email-адреса из вашей адресной книги, хэширует их и сверяет с нашим сервером, чтобы показать, кто из ваших контактов уже пользуется приложением. Сами контакты нигде не сохраняются.'**
  String get contacts_disclosure_body;

  /// Contacts disclosure allow button
  ///
  /// In ru, this message translates to:
  /// **'Разрешить'**
  String get contacts_disclosure_allow;

  /// Contacts disclosure deny button
  ///
  /// In ru, this message translates to:
  /// **'Не сейчас'**
  String get contacts_disclosure_deny;

  /// report title
  ///
  /// In ru, this message translates to:
  /// **'Пожаловаться'**
  String get report_title;

  /// report subtitle message
  ///
  /// In ru, this message translates to:
  /// **'На сообщение'**
  String get report_subtitle_message;

  /// report subtitle user
  ///
  /// In ru, this message translates to:
  /// **'На пользователя'**
  String get report_subtitle_user;

  /// report reason spam
  ///
  /// In ru, this message translates to:
  /// **'Спам'**
  String get report_reason_spam;

  /// report reason offensive
  ///
  /// In ru, this message translates to:
  /// **'Оскорбительный контент'**
  String get report_reason_offensive;

  /// report reason violence
  ///
  /// In ru, this message translates to:
  /// **'Насилие или угрозы'**
  String get report_reason_violence;

  /// report reason fraud
  ///
  /// In ru, this message translates to:
  /// **'Мошенничество'**
  String get report_reason_fraud;

  /// report reason other
  ///
  /// In ru, this message translates to:
  /// **'Другое'**
  String get report_reason_other;

  /// report comment hint
  ///
  /// In ru, this message translates to:
  /// **'Дополнительные сведения (необязательно)'**
  String get report_comment_hint;

  /// report submit
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get report_submit;

  /// report success
  ///
  /// In ru, this message translates to:
  /// **'Жалоба отправлена. Спасибо!'**
  String get report_success;

  /// report error
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить жалобу'**
  String get report_error;

  /// message menu action report
  ///
  /// In ru, this message translates to:
  /// **'Пожаловаться'**
  String get message_menu_action_report;

  /// partner profile menu report
  ///
  /// In ru, this message translates to:
  /// **'Пожаловаться на пользователя'**
  String get partner_profile_menu_report;

  /// No description provided for @call_bubble_voice_call.
  ///
  /// In ru, this message translates to:
  /// **'Голосовой звонок'**
  String get call_bubble_voice_call;

  /// No description provided for @call_bubble_video_call.
  ///
  /// In ru, this message translates to:
  /// **'Видеозвонок'**
  String get call_bubble_video_call;

  /// No description provided for @chat_preview_poll.
  ///
  /// In ru, this message translates to:
  /// **'Опрос'**
  String get chat_preview_poll;

  /// No description provided for @chat_preview_forwarded.
  ///
  /// In ru, this message translates to:
  /// **'Пересланное сообщение'**
  String get chat_preview_forwarded;

  /// No description provided for @birthday_banner_celebrates.
  ///
  /// In ru, this message translates to:
  /// **'празднует день рождения!'**
  String get birthday_banner_celebrates;

  /// No description provided for @birthday_banner_action.
  ///
  /// In ru, this message translates to:
  /// **'Поздравить →'**
  String get birthday_banner_action;

  /// No description provided for @birthday_screen_title_today.
  ///
  /// In ru, this message translates to:
  /// **'День рождения сегодня'**
  String get birthday_screen_title_today;

  /// No description provided for @birthday_screen_age.
  ///
  /// In ru, this message translates to:
  /// **'{age} лет'**
  String birthday_screen_age(int age);

  /// No description provided for @birthday_section_actions.
  ///
  /// In ru, this message translates to:
  /// **'ПОЗДРАВИТЬ'**
  String get birthday_section_actions;

  /// No description provided for @birthday_action_template.
  ///
  /// In ru, this message translates to:
  /// **'Готовое поздравление'**
  String get birthday_action_template;

  /// No description provided for @birthday_action_cake.
  ///
  /// In ru, this message translates to:
  /// **'Задуть свечу'**
  String get birthday_action_cake;

  /// No description provided for @birthday_action_confetti.
  ///
  /// In ru, this message translates to:
  /// **'Конфетти'**
  String get birthday_action_confetti;

  /// No description provided for @birthday_action_serpentine.
  ///
  /// In ru, this message translates to:
  /// **'Серпантин'**
  String get birthday_action_serpentine;

  /// No description provided for @birthday_action_voice.
  ///
  /// In ru, this message translates to:
  /// **'Записать аудио-поздравление'**
  String get birthday_action_voice;

  /// No description provided for @birthday_action_remind_next_year.
  ///
  /// In ru, this message translates to:
  /// **'Напомнить заранее в следующем году'**
  String get birthday_action_remind_next_year;

  /// No description provided for @birthday_action_open_chat.
  ///
  /// In ru, this message translates to:
  /// **'Написать своё поздравление'**
  String get birthday_action_open_chat;

  /// No description provided for @birthday_cake_prompt.
  ///
  /// In ru, this message translates to:
  /// **'Тапни по свече, чтобы её задуть'**
  String get birthday_cake_prompt;

  /// No description provided for @birthday_cake_wish_placeholder.
  ///
  /// In ru, this message translates to:
  /// **'Какое желание загадать для {name}?'**
  String birthday_cake_wish_placeholder(Object name);

  /// No description provided for @birthday_cake_wish_hint.
  ///
  /// In ru, this message translates to:
  /// **'Например: пусть всё задуманное сбудется…'**
  String get birthday_cake_wish_hint;

  /// No description provided for @birthday_cake_send.
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get birthday_cake_send;

  /// No description provided for @birthday_cake_message.
  ///
  /// In ru, this message translates to:
  /// **'🎂 С днём рождения, {name}! Моё пожелание для тебя: «{wish}»'**
  String birthday_cake_message(Object name, Object wish);

  /// No description provided for @birthday_confetti_message.
  ///
  /// In ru, this message translates to:
  /// **'🎉 Поздравляю с днём рождения, {name}! 🎉'**
  String birthday_confetti_message(Object name);

  /// No description provided for @birthday_template_1.
  ///
  /// In ru, this message translates to:
  /// **'С днём рождения, {name}! Пусть этот год будет лучшим!'**
  String birthday_template_1(Object name);

  /// No description provided for @birthday_template_2.
  ///
  /// In ru, this message translates to:
  /// **'{name}, поздравляю! Желаю радости, тепла и исполнения желаний 🎉'**
  String birthday_template_2(Object name);

  /// No description provided for @birthday_template_3.
  ///
  /// In ru, this message translates to:
  /// **'С праздником, {name}! Здоровья, удачи и побольше счастливых моментов 🎂'**
  String birthday_template_3(Object name);

  /// No description provided for @birthday_template_4.
  ///
  /// In ru, this message translates to:
  /// **'{name}, с днём рождения! Пусть всё задуманное сбывается легко и быстро ✨'**
  String birthday_template_4(Object name);

  /// No description provided for @birthday_template_5.
  ///
  /// In ru, this message translates to:
  /// **'Поздравляю, {name}! Спасибо, что ты есть. С днём рождения! 🎁'**
  String birthday_template_5(Object name);

  /// No description provided for @birthday_toast_sent.
  ///
  /// In ru, this message translates to:
  /// **'Поздравление отправлено'**
  String get birthday_toast_sent;

  /// No description provided for @birthday_reminder_set.
  ///
  /// In ru, this message translates to:
  /// **'Напомним за день до дня рождения {name}'**
  String birthday_reminder_set(Object name);

  /// No description provided for @birthday_reminder_notif_title.
  ///
  /// In ru, this message translates to:
  /// **'Завтра день рождения 🎂'**
  String get birthday_reminder_notif_title;

  /// No description provided for @birthday_reminder_notif_body.
  ///
  /// In ru, this message translates to:
  /// **'Не забудьте поздравить {name} завтра'**
  String birthday_reminder_notif_body(Object name);

  /// No description provided for @birthday_empty.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня нет именинников среди контактов'**
  String get birthday_empty;

  /// No description provided for @birthday_error_self.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить ваш профиль'**
  String get birthday_error_self;

  /// No description provided for @birthday_error_send.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить поздравление. Попробуйте ещё раз.'**
  String get birthday_error_send;

  /// No description provided for @birthday_error_reminder.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось установить напоминание'**
  String get birthday_error_reminder;

  /// No description provided for @chat_empty_title.
  ///
  /// In ru, this message translates to:
  /// **'Сообщений пока нет'**
  String get chat_empty_title;

  /// No description provided for @chat_empty_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Напишите первое сообщение — хранитель маяка уже ждёт'**
  String get chat_empty_subtitle;

  /// No description provided for @chat_empty_quick_greet.
  ///
  /// In ru, this message translates to:
  /// **'Поздороваться 👋'**
  String get chat_empty_quick_greet;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'es',
    'id',
    'kk',
    'pt',
    'ru',
    'tr',
    'uz',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'es':
      {
        switch (locale.countryCode) {
          case 'MX':
            return AppLocalizationsEsMx();
        }
        break;
      }
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'id':
      return AppLocalizationsId();
    case 'kk':
      return AppLocalizationsKk();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
