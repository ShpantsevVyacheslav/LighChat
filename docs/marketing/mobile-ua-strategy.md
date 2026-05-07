# LighChat — Mobile User Acquisition Strategy

> **Mobile-first** стратегия привлечения пользователей. Каналы, бенчмарки CPI/CPA, attribution, виральные механики, retention.  
> Период: первые 90 дней + проекция на 6 месяцев.

---

## Оглавление

1. [Стратегические принципы](#principles)
2. [Каналы по приоритету и регионам](#channels)
3. [CPI бенчмарки 2025–2026](#cpi)
4. [Attribution & Analytics стек](#attribution)
5. [Виральность: механики для LighChat](#virality)
6. [Push & Retention](#push)
7. [Бюджеты и распределение](#budgets)
8. [PWA как fallback](#pwa)

---

<a id="principles"></a>

## 1. Стратегические принципы

1. **Не пытаемся конкурировать с WhatsApp/Telegram по бюджету.** У них десятки $млрд маркетинга. У нас — точечные ниши.
2. **CAC должен быть ниже LTV в 3 раза.** Пока LTV неизвестен, целимся в CAC ≤ $1.50 в РФ/СНГ и ≤ $3.00 в LatAm/SEA/MENA. Если выше — оптимизируем.
3. **Виральность > paid acquisition.** Цель — K-factor ≥ 0.5 уже к концу 90 дня. QR-deep-link приглашения — наш главный рычаг.
4. **Mobile-first креативы.** Все ad creatives — вертикальное видео 9:16 (Reels, TikTok, Shorts).
5. **Localized > translated.** Не переводить с русского — снимать локальные креативы в каждом топ-регионе.
6. **Привязка к stores:** все ad campaigns ведут на конкретный store по геолокации (RuStore для РФ, Google Play для остальных).

---

<a id="channels"></a>

## 2. Каналы — по приоритету и регионам

### 2.1. РФ — приоритетная конфигурация

| Канал | Доступен в РФ? | Аудитория | Приоритет | Бенчмарки CPI |
|---|---|---|---|---|
| **VK Ads** (бывший myTarget) | ✅ | Молодежь VK + работающие | **P0** | ₽15–35 ($0.20–$0.45) |
| **Yandex.Direct mobile + Яндекс.Дзен** | ✅ | Search intent + контент | **P0** | ₽30–80 ($0.40–$1.00) |
| **Telegram Ads** | ✅ | Активная аудитория Telegram | **P0** | €0.50–€2.00 (~$0.55–$2.20) |
| **MyTarget Mobile** | ✅ | Mass-market | P1 | ₽20–50 |
| **TikTok Ads** | ✅ (для РФ работает через TikTok Russia) | 14–34 лет | P1 | ₽40–100 ($0.50–$1.30) |
| **Apple Search Ads** | ❌ заблокировано | iOS-аудитория | — | (недоступен) |
| **Google App Campaigns (UAC)** | ⚠️ частично работает | Android | P2 | ₽50–150 ($0.65–$1.95) |
| **Meta Ads (FB/Insta)** | ❌ заблокировано | — | — | (недоступен) |
| **Дзен.Промо** | ✅ | Контент-читатели | P2 | ₽40–100 |

**Стратегия для РФ:**
- 60% бюджета: VK Ads + Yandex.Direct (search + display) + Дзен.
- 25% бюджета: Telegram Ads (активная пользовательская база, релевантная аудитория).
- 15% бюджета: TikTok Ads (короткие вертикальные креативы).

### 2.2. СНГ (Казахстан, Узбекистан, Беларусь, Армения, Грузия)

| Канал | Приоритет | CPI |
|---|---|---|
| **Google App Campaigns (UAC)** | **P0** | $0.20–$0.80 |
| **Apple Search Ads** | P1 (для KZ — работает) | $0.80–$1.50 |
| **TikTok Ads** | P0 (особенно молодёжь) | $0.30–$1.00 |
| **Локальные сети (Kaspi Promo для KZ)** | P1 | договорное |
| **Telegram Ads** | P1 | €0.50–€2.00 |

### 2.3. ЮВА (Индонезия, Вьетнам, Филиппины, Таиланд)

| Канал | Приоритет | CPI |
|---|---|---|
| **Google App Campaigns (UAC)** | **P0** | $0.20–$0.80 |
| **Meta Ads** | **P0** (доминирующий в SEA) | $0.40–$1.20 |
| **TikTok Ads** | **P0** (глобально лидер у молодежи) | $0.30–$1.00 |
| **Apple Search Ads** | P1 (для платёжеспособных) | $1.50–$3.00 |
| **In-app networks (Unity Ads, AppLovin)** | P2 | $0.20–$0.50 |

### 2.4. ЛатАм (Бразилия, Мексика, Аргентина)

| Канал | Приоритет | CPI |
|---|---|---|
| **Google App Campaigns (UAC)** | **P0** | $0.50–$1.20 |
| **Meta Ads** | **P0** (доминирующий) | $0.60–$1.50 |
| **TikTok Ads** | **P0** | $0.50–$1.50 |
| **Apple Search Ads** | P1 | $2.00–$4.00 |

### 2.5. MENA (ОАЭ, Саудовская Аравия, Турция, Египет)

| Канал | Приоритет | CPI |
|---|---|---|
| **Google App Campaigns (UAC)** | **P0** | $0.40–$2.00 (Турция дёшево, ОАЭ дорого) |
| **Meta Ads** | **P0** | $0.50–$3.00 |
| **TikTok Ads** | **P0** | $0.50–$2.00 |
| **Apple Search Ads** | P1 (ОАЭ премиум) | $2.00–$5.00 |
| **Snapchat Ads** | P2 (Saudi молодежь) | $0.60–$1.50 |

---

<a id="cpi"></a>

## 3. CPI бенчмарки — категория Social/Communication, 2025–2026

| Регион | iOS CPI | Android CPI | Источник |
|---|---:|---:|---|
| US | $4.06 (Apple Search Ads, 2025) | $2.50–$3.50 | SplitMetrics, Apptweak |
| EU (West) | $2.50–$3.50 | $1.50–$2.50 | Apptweak |
| РФ | (Apple Search Ads недоступен) | $0.40–$1.20 (UAC) | Mapendo |
| СНГ (KZ, UZ) | $0.80–$1.50 | $0.20–$0.80 | Mapendo, Business of Apps |
| Турция | $1.50–$2.50 | $0.50–$1.20 | Apptweak |
| ЛатАм | $2.00–$4.00 | $0.50–$1.50 | Mapendo |
| ЮВА | $1.50–$3.00 | $0.20–$1.20 | Mapendo (общий benchmark $1.20 для Android) |
| MENA premium (UAE, KSA) | $3.00–$5.00 | $1.00–$2.50 | Apptweak |

**Apple Search Ads общий тренд (SplitMetrics 2025):** средний CPT (cost-per-tap) вырос до $2.50 (с $1.59 в 2023), median CPI $4.06 в US. **Социальные приложения дешевле игр**, но дороже utility.

**Целевой CAC LighChat (с учётом виральности):**
- РФ/СНГ: ≤ $1.50 paid + 1.5x organic = blended ≤ $0.60
- ЮВА: ≤ $1.00 paid + 2x organic = blended ≤ $0.35
- Турция/ЛатАм: ≤ $2.50 paid + 1.5x organic = blended ≤ $1.00

---

<a id="attribution"></a>

## 4. Attribution & Analytics стек

### 4.1. Рекомендуемый стек для LighChat

| Слой | Решение | Почему |
|---|---|---|
| **Mobile attribution** | **AppsFlyer** | #1 на рынке, поддерживает все каналы (включая VK Ads, Yandex, TikTok), есть free tier до 12K conversions/мес. |
| **Альтернатива** | Adjust | Хорош для премиум-сегмента, дороже. |
| **Альтернатива (бюджетная)** | Firebase Analytics + GA4 + own UTM | Бесплатно, но без deduplication между каналами. |
| **Product analytics** | **Amplitude** (free до 10M events/мес) | Понимание retention, funnels, cohorts. |
| **Альтернатива** | Mixpanel, PostHog (self-hosted) | |
| **Crash reporting** | **Firebase Crashlytics** | Уже есть в стеке (Firebase backend). |
| **Push delivery** | **Firebase Cloud Messaging (FCM)** + **APNs** напрямую для iOS | Бесплатно, нативно. |
| **Push для РФ** | RuStore Push (для устройств без Google Services) | Обязательно для AppGallery / GetApps. |
| **In-app A/B** | **Firebase Remote Config + A/B Testing** | Бесплатно. |
| **Web analytics** | **Yandex.Metrika** (для РФ) + **Plausible** или **Matomo** (privacy-friendly) | Метрика обязательна для лендинга в РФ. |

### 4.2. Ключевые события для трекинга (минимум)

| Event | Параметры | Когда |
|---|---|---|
| `app_install` | source, campaign, medium | первый запуск |
| `signup_started` | method (phone/email) | начало регистрации |
| `signup_completed` | method, time_to_complete | успешная регистрация |
| `qr_scan_login` | from_device | вход через QR на новом устройстве |
| `first_message_sent` | chat_type | первое сообщение |
| `first_call_started` | call_type (audio/video) | первый звонок |
| `invite_sent` | channel (whatsapp/sms/copylink) | приглашение друга |
| `invite_accepted` | source | друг присоединился |
| `theme_customized` | chat_id | использование USP |
| `notification_opened` | notification_type | retention |

### 4.3. SKAdNetwork (iOS) — критично

С iOS 14.5+ (2021) и AppTrackingTransparency требуются consent + SKAdNetwork. AppsFlyer обрабатывает это автоматически. **Conversion value mapping** для LighChat:
- 0: install only
- 1: signup completed
- 2: first message
- 3: first call
- 4: invite sent
- 5: 7-day retention
- 6+: monetization (если будет)

---

<a id="virality"></a>

## 5. Виральность — механики для LighChat

### 5.1. QR-deep-link приглашения (P0 — главный USP)

**Механика:** в LighChat есть QR-вход для собственных устройств. **Расширяем эту фичу до приглашения друга**:

1. В чате/настройках — кнопка «Пригласить друга».
2. Открывается экран с QR-кодом + ссылкой `lighchat.app/invite/{user_id}`.
3. Друг сканирует QR (через камеру или загрузить фото) — открывается App Clip (iOS) / Instant App (Android) → быстрая установка.
4. После установки — друг автоматически добавлен в контакты.
5. **Bonus:** обоим даётся уникальный стикерпак как награда (gamification без денег).

**Ожидаемый K-factor:** 0.4–0.7 (агрессивная инвайт-механика для мессенджера).

### 5.2. Реферальная программа

| Механика | Награда |
|---|---|
| Пригласи 1 друга | 1 эксклюзивный стикерпак |
| Пригласи 5 друзей | Кастомная цветовая палитра |
| Пригласи 25 друзей | «Pioneer» бейдж + ранний доступ к новым фичам |
| Пригласи 100 друзей | Лимитированный мерч + личный доступ к команде |

### 5.3. Share-to-install

- **Universal Links / App Links** на все ссылки `lighchat.com/u/{username}` и `lighchat.com/g/{group_invite}`.
- Если у получателя приложение установлено → открывается чат.
- Если нет → лендинг с большим CTA «Установить» + Smart App Banner.

### 5.4. Contact-sync

- При onboarding — опционально (с явным consent) синхронизировать контакты.
- Показывать «X из ваших контактов уже в LighChat» — социальное доказательство.
- Возможность пригласить через SMS/WhatsApp с pre-fill сообщением.

### 5.5. Группа = вирусный вектор

- Создание группы → автогенерация invite link (`lighchat.com/g/{invite_id}`).
- Приглашённый видит онбординг с упоминанием группы.
- **Каждая созданная группа в среднем приводит 3–5 новых пользователей** (бенчмарк WhatsApp/Telegram).

---

<a id="push"></a>

## 6. Push & Retention

### 6.1. Lifecycle messaging

| Stage | Trigger | Сообщение | Канал |
|---|---|---|---|
| **Onboarding D0** | install — 24h без signup | «Завершите регистрацию за 30 секунд → начните общаться» | local notification |
| **Onboarding D1** | signup — 0 контактов | «Пригласите друга по QR — получите стикерпак» | push |
| **D3 win-back** | 0 messages sent | «Ваш чат ждёт — попробуйте кастомные темы» | push |
| **D7 win-back** | uninstall risk | «Что мы можем улучшить? Расскажите нам» | email/push |
| **D30 deep win-back** | inactive | «Возвращайтесь — мы добавили [новая фича]» | push |
| **Hero notification** | важное событие (новый друг присоединился, missed call) | rich push с кнопкой «Ответить» | push |

### 6.2. Opt-in best practices

- **iOS:** не запрашивать `UNUserNotificationCenter.requestAuthorization` сразу при первом запуске. **Запрашивать после первого положительного события** (отправил сообщение, получил приглашение). CR-ratio +25–40%.
- **Android:** Android 13+ требует runtime permission `POST_NOTIFICATIONS`. Запрашивать после первого signup.
- **Web/PWA:** Push API — запрашивать после явного действия пользователя.

### 6.3. Метрики retention (целевые)

| Метрика | Цель D0–D30 | Цель D30–D90 |
|---|---|---|
| D1 retention | ≥ 35% | ≥ 45% (после улучшений) |
| D7 retention | ≥ 18% | ≥ 25% |
| D30 retention | ≥ 10% | ≥ 18% |
| MAU/DAU ratio | ≥ 0.20 | ≥ 0.30 (мессенджер должен быть daily-use) |
| Stickiness (DAU/MAU) | ≥ 20% | ≥ 35% |

---

<a id="budgets"></a>

## 7. Бюджеты и распределение — первые 90 дней

### Сценарий A — минимальный ($5,000/мес = $15,000 на 90 дней)

| Канал | Доля | Сумма | Регион |
|---|---:|---:|---|
| VK Ads | 30% | $4,500 | РФ |
| Yandex.Direct + Дзен | 20% | $3,000 | РФ |
| Telegram Ads | 15% | $2,250 | РФ + СНГ |
| Google App Campaigns | 20% | $3,000 | СНГ + ЮВА |
| TikTok Ads | 10% | $1,500 | РФ + СНГ |
| ASO tools (App Radar / AppTweak подписка) | 5% | $750 | глобально |
| **Итого** | 100% | **$15,000** | |

**Ожидаемый результат:** 25,000–40,000 установок (blended CPI $0.40–$0.60), MAU ~12,000–20,000 (с retention 50%).

### Сценарий B — оптимальный ($15,000/мес = $45,000 на 90 дней)

| Канал | Доля | Сумма | Регион |
|---|---:|---:|---|
| VK Ads + MyTarget | 25% | $11,250 | РФ |
| Yandex.Direct + Дзен | 20% | $9,000 | РФ |
| Telegram Ads | 15% | $6,750 | РФ + СНГ + EN |
| Google App Campaigns | 20% | $9,000 | глобально |
| TikTok Ads | 10% | $4,500 | глобально |
| Influencer marketing | 5% | $2,250 | РФ + 2 топ-страны |
| ASO tools | 3% | $1,350 | |
| Attribution (AppsFlyer) | 2% | $900 | |
| **Итого** | 100% | **$45,000** | |

**Ожидаемый результат:** 75,000–125,000 установок (blended CPI $0.36–$0.60), MAU ~40,000–70,000.

### Сценарий C — агрессивный ($50,000/мес = $150,000 на 90 дней)

— масштабирование сценария B + добавление Apple Search Ads (в доступных регионах) + полноценная influencer-кампания + Meta Ads в ЛатАм/ЮВА.

**Ожидаемый результат:** 250,000–400,000 установок, MAU ~150,000–250,000.

---

<a id="pwa"></a>

## 8. PWA как fallback

### Когда PWA — основной канал

- **Китай** — App Store недоступен для российской audience.com, Google Play отсутствует.
- **Иран, Северная Корея, Куба** — санкционные ограничения.
- **Технические пользователи в РФ**, не желающие ставить через RuStore/Google Play.
- **Мобильный веб-маркетинг** — ссылки в Яндекс.Метрике или Telegram, ведущие в браузер.

### Требования к LighChat PWA

- ✅ Service Worker — offline support.
- ✅ Web Push API — работает в Chromium-based браузерах (Android Chrome, iOS Safari 16.4+).
- ✅ `manifest.json` с `display: standalone` — добавляется на главный экран как иконка.
- ✅ WebRTC для звонков — браузер сам справляется.
- ✅ IndexedDB для локальной истории.
- ⚠️ iOS Safari ограничения: нет фоновых задач, push требует разрешения от iOS 16.4+.

### Маркетинг PWA

- На лендинге `lighchat.com` — кнопка «Использовать в браузере» в дополнение к store-кнопкам.
- Smart App Banner: если у iOS Safari пользователь ещё не установил, показывать `<meta name="apple-itunes-app">`.
- Для Android: meta `<link rel="manifest">` + window.matchMedia('display-mode: standalone').

---

> ⏭ **Дальше:** см. [action-plan-90d.md](action-plan-90d.md) для пошагового плана на 90 дней по спринтам.
