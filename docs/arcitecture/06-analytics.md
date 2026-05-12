# 06: Product Analytics

## Что это

Единая система продуктовой и маркетинговой телеметрии LighChat. Источники — все клиенты (web, PWA, Flutter mobile, Flutter desktop) и Cloud Functions. Транспорт — Firebase Analytics → GA4 → BigQuery (free daily export). Внутренний admin-дашборд (`src/app/dashboard/admin`) читает rollup в Firestore `platformStats/daily/entries`, который наполняет ежесуточный scheduler `rollupDailyAnalytics`.

## Архитектура

```
Web (Next.js) ──┐
PWA           ──┤── firebase/analytics ──┐
Flutter ios/  ──┤── firebase_analytics ──┤── Firebase Analytics (GA4) ── BigQuery (daily)
android/macos ──┘                        │
                                         │
Flutter win/  ── callable ──┐            │
linux           logAnalyticsEvent ──── recordAnalyticsEvent ──┴──── analyticsEvents (Firestore)
                                            ▲                                │
Cloud Functions triggers ───────────────────┘                                ▼
(onUserCreated, onMessageCreated, onCallCreated, ...)                rollupDailyAnalytics
                                                                             │
                                                                             ▼
                                                                     platformStats/daily/*
                                                                             │
                                                                             ▼
                                                                     admin AnalyticsTab
```

## Ключевые файлы

- **Каталог событий (источники истины — должны совпадать):**
  - [src/lib/analytics/events.ts](../../src/lib/analytics/events.ts)
  - [mobile/app/lib/features/analytics/analytics_events.dart](../../mobile/app/lib/features/analytics/analytics_events.dart)
  - [functions/src/analytics/events.ts](../../functions/src/analytics/events.ts)
- **Web SDK обёртка:** [src/lib/analytics/index.ts](../../src/lib/analytics/index.ts), [firebase-sink.ts](../../src/lib/analytics/firebase-sink.ts), [server-sink.ts](../../src/lib/analytics/server-sink.ts), [AnalyticsProvider.tsx](../../src/components/analytics/AnalyticsProvider.tsx)
- **Web server ingest:** [src/app/api/analytics/event/route.ts](../../src/app/api/analytics/event/route.ts) — REST приёмник для серверной двойной записи и Safari-fallback.
- **Flutter SDK обёртка:** [analytics_service.dart](../../mobile/app/lib/features/analytics/analytics_service.dart), [analytics_provider.dart](../../mobile/app/lib/features/analytics/analytics_provider.dart), [analytics_observer.dart](../../mobile/app/lib/features/analytics/analytics_observer.dart), [analytics_consent_screen.dart](../../mobile/app/lib/features/analytics/analytics_consent_screen.dart)
- **Серверный helper:** [functions/src/analytics/recordEvent.ts](../../functions/src/analytics/recordEvent.ts) — запись в Firestore + forward в GA4 Measurement Protocol.
- **Desktop callable:** [functions/src/triggers/http/logAnalyticsEvent.ts](../../functions/src/triggers/http/logAnalyticsEvent.ts) — для Flutter Windows/Linux (нет нативного SDK).
- **Rollup:** [functions/src/triggers/scheduler/rollupDailyAnalytics.ts](../../functions/src/triggers/scheduler/rollupDailyAnalytics.ts) — каждый день в 03:00 UTC.
- **Admin actions:** [src/actions/analytics-actions.ts](../../src/actions/analytics-actions.ts)

## Каталог событий

Полный перечень — в `events.ts`/`events.dart`. Категории:

1. **Acquisition & Auth** — `landing_view`, `cta_click`, `sign_up_attempt/success/failure`, `login_*`, `pwa_install*`.
2. **Engagement** — `chat_created`, `chat_opened`, `message_sent`, `call_*`, `meeting_*`, `game_*`, `file_shared`, `reaction_added`, `secret_chat_enabled`, `e2ee_pairing_completed`, `contact_added`.
3. **Navigation & Funnels** — `page_view` (web), `screen_view` (flutter), `search_performed`, `deep_link_opened`, `notification_opened`.
4. **Retention & Platform** — `session_start`, `app_open`, `app_backgrounded`, `crash`, `permission_prompt`, `app_update*`.
5. **Sharing & Invites** — `contact_shared`, `external_invite_sent/accepted`, `chat_invite_link_*`, `meeting_guest_*`, `qr_scanned`, `referral_signup`.
6. **Errors & Quality** — `error_occurred`, `network_offline_*`, `call_quality_report`, `webrtc_reconnect`, `media_upload_failure`, `push_delivery_failed`, `e2ee_failure`.
7. **Localization & Settings** — `language_changed`, `theme_changed`, `notification_settings_changed`, `account_deleted`, `logout`.
8. **Messaging Deep** — `message_edited/deleted/pinned/forwarded/replied`, `voice_message_played`, `media_viewed/downloaded`, `search_zero_results`.
9. **Call/Meeting Deep** — `screen_share_*`, `mic_toggled`, `camera_toggled`, `bg_blur_toggled`, `meeting_poll_voted`, `meeting_join_request_*`.
10. **Monetization** — `paywall_viewed`, `plan_selected`, `purchase_*`, `subscription_*`, `storage_quota_*` (skeleton, готовим заранее).
11. **Bots & Platform** — `bot_command_used`, `bot_added_to_chat`, `feature_flag_exposed`, `csp_violation_received`, `admin_action_performed`.

## User properties

Устанавливаются на signup/login/события смены настроек:

`signup_method`, `signup_country`, `primary_platform`, `is_admin`, `has_premium`, `account_age_days_bucket`, `total_chats_bucket`, `e2ee_enabled`, `app_language`, `app_theme`, `os_version_major`, `notification_perm_state`, `is_referred_user`, `active_subscription_plan`, `subscription_channel`.

GA4 автоматически даёт разбивку **любого** события по этим user-properties — например, `chat_created` × `app_language`.

## Правила (PII safety)

1. **Никаких email/phone/name/uid в params** в plain виде. Только хэш (sha256 first-8) или `_bucket`.
2. **Никаких длинных id** (chatId, messageId, conversationId) — GA4 имеет лимит cardinality.
3. **Значения параметров — enum-литералы либо bucket'ы** (см. helpers `durationBucket`/`sizeBucket`/`countBucket`/`daysBucket`).
4. **Параметров на событие ≤ 24** (GA4 лимит 25, один зарезервирован под `platform`).
5. **Имена событий ≤ 40 символов**, имена параметров ≤ 40, значения строк ≤ 100 — режется автоматически в `sanitizeParams`.

## Consent (GDPR)

- **Web**: [cookie-banner.tsx](../../src/components/landing/cookie-banner.tsx) при accept вызывает `setConsent('all'|'required')` из `@/lib/analytics`. До accept — `setAnalyticsCollectionEnabled(false)`, `firebase/analytics` не загружается в bundle.
- **Flutter**: [analytics_consent_screen.dart](../../mobile/app/lib/features/analytics/analytics_consent_screen.dart) показывается в onboarding до auth. Решение хранится в `SharedPreferences`-ключе `lc_analytics_consent_v1`.
- **`required`-consent**: клиентский GA4 SDK отключён, но критичные конверсии (`sign_up_success`, `login_success`, `purchase_completed`, `error_occurred`, `account_deleted`) идут через server-side ingest как legitimate interest (без `user_id`, только pseudo-id).
- **iOS ATT**: `NSUserTrackingUsageDescription` нужно добавить в Info.plist для платного маркетинга на iOS (IDFA). Сейчас аналитика работает с IDFV — ATT не обязательна.
- **Legal**: соответствующая секция — `/legal/privacy-policy` и `/legal/cookie-policy`.

## Конфигурация GA4 Measurement Protocol (server-side)

`recordAnalyticsEvent` форвардит события в GA4 если в Firestore документе `platformSettings/main` есть поле:

```json
{
  "analytics": {
    "measurementId": "G-XXXXXXXXXX",
    "apiSecret": "...stream-secret..."
  }
}
```

Получить — GA4 Admin → Data Streams → Web/iOS/Android → Measurement Protocol API secrets. Без конфига события всё равно пишутся в Firestore `analyticsEvents` и попадают во внутренний дашборд, но не уходят в GA4/BigQuery.

## Как добавить новое событие

1. Добавить enum-имя в **три** файла (web/flutter/functions). Имя должно совпадать.
2. Добавить имя в `ALLOWED_EVENTS` в `src/app/api/analytics/event/route.ts` (web REST whitelist).
3. На клиенте: `track(AnalyticsEvents.myEvent, { ... })` (web) / `service.logEvent(AnalyticsEvents.myEvent, { ... })` (flutter).
4. На сервере: `await recordAnalyticsEvent({ event: AnalyticsEvents.myEvent, uid, params, platform: 'server' })`.
5. Документ обновить — добавить событие в каталог выше.
6. (Опционально) Если событие добавляется в admin-дашборд — расширить `src/actions/analytics-actions.ts` и `rollupDailyAnalytics.ts`.

## Тестирование

- **GA4 DebugView**: `Firebase Console → Analytics → DebugView`. Включается через debug-флаг:
  - Web: добавить `?firebase_debug=1` к URL **или** установить cookie `_fpc` (Firebase Analytics автоматически переключит).
  - Flutter: `FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true)` + флаг `firebase_debug=true` в `<intent-filter>` (Android) / `FIRDebugEnabled` в Info.plist (iOS).
- **Локальный smoke**: Firestore emulator + `firebase emulators:start`. Создать пользователя → проверить `analyticsEvents` коллекцию.
- **Контракт-тест**: убедиться что enum-имена в трёх каталогах совпадают (TODO: добавить статическую проверку в CI).

## Где смотреть данные

- **GA4 Console**: realtime + reports + funnels + retention.
- **Looker Studio**: подключить как datasource BigQuery `analytics_<projectId>.events_*`.
- **Внутренний admin**: `/dashboard/admin` → таб «Аналитика» (расширение существующей панели).
- **Firestore Console**: `platformStats/daily/entries/{YYYY-MM-DD}` — агрегированные дневные метрики.

## Известные ограничения

- **Flutter Windows/Linux**: события идут через callable, не через нативный SDK → нет автоматических `session_start`, `screen_view`, `first_open`. Шлём их вручную.
- **GA4 cardinality**: не передаём raw ID; bucket'ы только.
- **BigQuery free tier**: 1 ТБ обработки + 10 ГБ хранения в месяц — на текущем объёме хватает с запасом.
- **Дубли client+server**: server события — canonical для бизнес-метрик; client события для UX-funnels (composer_open и т.п.). Если оба отправляют одно имя — обращайте внимание на параметр `source` в Firestore (`web_client` / `callable` / `server`).
