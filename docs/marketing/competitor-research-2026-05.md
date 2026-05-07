# LighChat — Конкурентное исследование и mobile-first стратегия продвижения

> **Дата исследования:** май 2026  
> **Фокус:** мобильное приложение (iOS + Android на Flutter) как основной канал.  
> **Цель:** data-driven план ASO/SEO/UA для повышения позиций в поисковой выдаче и привлечения аудитории с приоритетом РФ + 5 топ-международных рынков.

---

## Оглавление

1. [TL;DR — ключевые выводы](#tldr)
2. [Контекст продукта LighChat](#context)
3. [Конкурентный анализ — mobile-first](#competitors)
4. [Российский рынок (приоритетный)](#russia)
5. [Топ-5 международных рынков](#international)
6. [USP и позиционирование](#usp)
7. [Источники](#sources)

> Сопутствующие документы: [aso-keywords-recommendations.md](aso-keywords-recommendations.md) · [mobile-ua-strategy.md](mobile-ua-strategy.md) · [action-plan-90d.md](action-plan-90d.md) · [README.md](README.md)

---

<a id="tldr"></a>

## 1. TL;DR — ключевые выводы

1. **Глобальный рынок мессенджеров крайне сконцентрирован.** WhatsApp (3.3 млрд MAU) и Telegram (1+ млрд MAU, март 2025) забирают ~80% мирового трафика. Прямая фронтальная конкуренция бесперспективна — **нужна нишевая стратегия**.
2. **Российский рынок переживает регуляторный шторм 2025–2026.** WhatsApp за год потерял ~9 млн MAU (с 94.5 → 80.3 млн), Max от VK вырос с 0 до 77.6 млн MAU за полгода благодаря обязательной предустановке (с 1 сентября 2025). Telegram удерживает позиции на ~95.7 млн MAU. **Окно для нишевого мессенджера в РФ открыто.**
3. **iOS App Store в РФ умирает как канал монетизации:** с 1 апреля 2026 платежи в App Store недоступны для российских пользователей; Apple Search Ads заблокированы с 2022; Apple Developer Enterprise Program закрыт для РФ. Но iOS-устройства остаются у платежеспособной аудитории — нужна **гибридная стратегия дистрибуции**.
4. **RuStore стал обязательным каналом** — с 1 сентября 2025 все Android-устройства, продаваемые в РФ, должны поддерживать RuStore; iOS-устройства обязаны поддерживать его установку. **Публикация LighChat в RuStore — P0 с дня 1.**
5. **Mobile-first стратегия требует:**
   - ASO в 5 сторах (App Store, Google Play, RuStore, NashStore, AppGallery)
   - Локализация под 6 языков (RU, EN, KZ, UZ, ID, ES, PT, TR)
   - Performance-маркетинг через Google UAC + VK Ads + Yandex.Direct + TikTok Ads (Apple Search Ads недоступен в РФ)
   - **Виральные механики через QR-deep-links** — нативная сила LighChat (мульти-девайс через QR), которой нет ни у одного конкурента.
6. **Топ-5 международных рынков** (в порядке потенциала): **Казахстан → Узбекистан → Турция → Индонезия → Бразилия**. Низкий CAC (~$0.30–$1.50), высокая Android-доля (>85%), русскоязычная диаспора в СНГ + растущий privacy-сегмент в SEA/LatAm.

---

<a id="context"></a>

## 2. Контекст продукта LighChat

| Параметр | Значение |
|---|---|
| Тип | Мультиплатформенный мессенджер |
| Платформы | iOS, Android (Flutter) — основные; Web/PWA (Next.js), Desktop (Electron) — secondary |
| Backend | Firebase (Firestore, Auth, Cloud Messaging, Functions) |
| Звонки | WebRTC + iOS CallKit + Android ConnectionService |
| Уникальные фичи | QR-авторизация для мульти-девайс; кастомные темы чатов; полная админ-панель (модерация, аналитика, тикеты, audit log, feature flags) |
| Безопасность | E2E-шифрование |
| Аудитория | **Mobile-first** — большая часть пользователей будет на iOS/Android |

---

<a id="competitors"></a>

## 3. Конкурентный анализ — mobile-first

### 3.1. Глобальная карта (топ-15)

| Мессенджер | MAU (2025–2026) | Лидер в регионах | Сильные стороны | Слабые стороны | Релевантность для LighChat |
|---|---:|---|---|---|---|
| **WhatsApp** | 3.3 млрд | Глобально (ex-Китай, ex-РФ снижается) | Универсальность, 180+ стран, статус-quo | Зависимость от Meta, регуляторные риски | Прямая конкуренция невозможна |
| **Telegram** | 1.0+ млрд (март 2025), прогноз 1.1 млрд в 2026 | РФ, Иран, СНГ, Ближний Восток | Каналы, боты, файлообмен, политическая нейтральность | Не E2E по умолчанию, споры с регуляторами | Главный референс по UX/feature-set |
| **WeChat / Weixin** | 1.41 млрд (июнь 2025) | Китай (монополия) | Super-app, платежи, mini-apps | Только Китай, сильный гос-контроль | Не релевантен (закрытый рынок) |
| **Viber** | 260+ млн | Восточная Европа, Балканы, Филиппины, Ирак | Кросс-платформа, паблик-чаты | Снижающаяся аудитория | Конкурент в СНГ, Восточной Европе |
| **Discord** | 200+ млн (оценки 2025) | Западные геймеры, англоязычные коммьюнити | Голосовые серверы, низкая латентность | Сложный для масс-аудитории | Не прямой конкурент (другая ниша) |
| **LINE** | 99 млн (2025) | **Япония (80.5%), Таиланд, Тайвань** | Стикеры, платежи, локализация | Только Восточная Азия | Не релевантен для LighChat |
| **Zalo** | 77.6 млн | **Вьетнам (#1)** | Локальные сервисы, мини-апы | Только Вьетнам | Конкурент при выходе во Вьетнам |
| **KakaoTalk** | 54.3 млн | **Южная Корея (95.1%)** | Платежи, такси, гипер-локально | Только Корея | Не релевантен |
| **Signal** | 70 млн (оценки 2025) | США, Европа, privacy-аудитория | Лучшая криптография, опен-сорс, репутация | Скудный feature-set, мало стикеров | Конкурент в нише privacy |
| **Threema** | ~10 млн | DACH (Германия, Австрия, Швейцария) | Анонимность (без телефона), B2B | Платный (~5€), мало пользователей | Конкурент в premium-privacy нише |
| **Element / Matrix** | ~3 млн (оценки) | Гики, IT-команды | Federation, опен-сорс, мосты | Сложный UX, метаданные на серверах | Не релевантен (тех-аудитория) |
| **Session** | ~1 млн | Privacy-параноики | Без телефона, on-device, P2P-маршрутизация | Сложный, медленный | Не прямой конкурент |
| **Max (VK)** | 85 млн (январь 2026) | **РФ (обязательная установка)** | Госпредустановка, платежи СБП, GigaChat | Доверие, политические риски | Главный конкурент в РФ |
| **VK Мессенджер** | 55.8 млн | РФ (молодежь VK) | Интеграция с VK | Слабый stand-alone | Конкурент в РФ |
| **imo** | ~10 млн в РФ (2025–2026) | **Растёт в РФ как «не-госальтернатива»** | Кросс-платформа, видеозвонки | Скромный feature-set | Удивительный feature — на нём учиться |

### 3.2. Mobile UX — глубокий разбор лидеров

| Параметр | Telegram (Android) | WhatsApp | Signal | Max |
|---|---|---|---|---|
| Размер APK | 80–100 MB | 65–80 MB | 60–80 MB | 90–120 MB |
| Размер IPA | 200+ MB | 200+ MB | 100+ MB | 150+ MB |
| Время онбординга | <60 сек (телефон + СМС) | <60 сек | <60 сек | <90 сек |
| Permissions при онбординге | контакты, уведомления (опц.) | контакты (обяз.), уведомления, фото | минимум | контакты, уведомления, push-предустановка |
| Push-стратегия | rich (превью, кнопки) | rich + group thread | минимум | агрессивная, обязательная |
| Deep links | t.me/ ссылки, app links | wa.me/ ссылки | signal.me/ | max.ru/ |
| Виральная механика | invite link, channels, bots | contact-sync, status | contact-sync | предустановка + СБП-переводы |

### 3.3. Возможности LighChat относительно лидеров

**Где LighChat может выиграть:**
- 🎨 **Кастомные темы** — у Telegram есть, но менее гибко; у WhatsApp/Signal/Viber/Max почти нет.
- 📱 **Мульти-девайс через QR** — WhatsApp Web и Telegram имеют, но переход через QR на новом устройстве — у Telegram он сложнее, у WhatsApp требует основного телефона. **LighChat может сделать seamless QR-onboarding на новом устройстве — это вирусная механика.**
- 🛡️ **Открытость кода + политическая нейтральность** — ниша между Signal (слишком аскетичный) и Telegram (политические риски).
- 🌍 **Кросс-региональность** — отсутствие зависимости от одной юрисдикции.

**Где LighChat НЕ должен пытаться выиграть (минимум 1 год):**
- ❌ Каналы и боты (Telegram — недостижимо без 5+ лет работы и денег).
- ❌ Платежи внутри мессенджера (требует банк-партнёров).
- ❌ Глобальная contact-sync виральность (требует критическую массу).

---

<a id="russia"></a>

## 4. Российский рынок (приоритетный)

### 4.1. Долевое распределение — Mediascope (февраль 2026)

| Мессенджер | MAU РФ | Динамика год к году |
|---|---:|---|
| **Telegram** | 95.7 млн | стабильно |
| **WhatsApp** | 80.3 млн | **−9.1 млн** (давление регуляторов) |
| **Max (VK)** | 77.6 млн | **+77.6 млн** с нуля за полгода |
| **VK Мессенджер** | 55.8 млн | стабильно |
| **Yandex Мессенджер** | 10–12 млн | медленный рост |
| **imo** (US) | ~10 млн (январь 2026) | **+10 млн за 6 мес** — flight from regulation |
| **Viber** | падает | значительные потери |
| **ICQ New** | <5 млн | стагнация |
| **TamTam** | <3 млн | стагнация |

**Вывод:** в РФ есть три устойчивых игрока (Telegram, WhatsApp, Max) и четыре нишевых (VK, Yandex, imo, Viber). **LighChat должен целиться в нишу `imo` — «не-государственная и не-западная» альтернатива** для пользователей, не доверяющих ни Max, ни WhatsApp/Meta.

### 4.2. Регуляторный ландшафт 2025–2026

- **152-ФЗ** — данные граждан РФ хранить на территории РФ. **Решение для LighChat:** Firebase (Google Cloud) европейский регион — формально не соответствует. Либо self-host Firebase emulator, либо переход на Yandex.Cloud / VK Cloud для российских пользователей.
- **Реестр ОРИ Роскомнадзора** — все мессенджеры, доступные в РФ, обязаны включаться в реестр (id пользователей, метаданные звонков). **Бизнес-решение:** регистрироваться или нет.
- **Закон о пред-установке (с 1 сентября 2025):** на всех Android-устройствах, продаваемых в РФ, обязателен RuStore. На iOS-устройствах обязательна **возможность установки** RuStore (sideload). С устройств производителями нельзя удалить из коробки 19 приложений, включая Max, RuStore, Госуслуги.
- **Apple App Store в РФ (статус апрель 2026):**
  - Платежи в App Store **недоступны** с 1 апреля 2026 (только баланс Apple Account).
  - Apple Search Ads **заблокированы с марта 2022**.
  - Apple Developer Enterprise Program **закрыт** для РФ-разработчиков (февраль 2025).
  - Альтернативные сторы (как в EU) **в РФ не разрешены Apple**.
  - **Способы оплаты разработческого аккаунта** — через зарубежные карты или партнёров.
- **Законопроекты 2025–2026:** ужесточение требований к мессенджерам по идентификации пользователей, маркировке спама, маркировке голосовых звонков.

### 4.3. Мобильная дистрибуция в РФ — 5 сторов

| Стор | Платформа | Доля рынка (РФ, 2026) | Особенности |
|---|---|---:|---|
| **Google Play** | Android | ~50% (но снижается из-за RuStore) | Платежи Google заблокированы с 2022 — только бесплатно или сторонние платежи |
| **App Store** | iOS | ~25% | Платежи недоступны, Search Ads заблокированы |
| **RuStore** | Android, iOS (sideload) | **обязательный с 09.2025** — быстрый рост | Поддержка СБП, Yandex Pay, нет комиссии Google |
| **AppGallery** | Huawei Android | ~10% (Huawei устройства) | Хорош для Huawei-пользователей в регионах РФ и СНГ |
| **NashStore** | Android | <5% | Специализируется на санкционно-чувствительных приложениях |
| **GetApps (Xiaomi)** | Xiaomi Android | ~5% | Только Xiaomi-устройства, но 25% всех Android в РФ — Xiaomi |
| **Прямой APK** | Android | <5% | Хорошо для технической аудитории |

**Приоритет публикации (с дня 1):**
1. **P0:** RuStore + Google Play + App Store — основной охват.
2. **P1:** AppGallery + GetApps (Xiaomi) — серьёзная доля Android в РФ.
3. **P2:** NashStore + прямой APK — нишевая аудитория.

### 4.4. Культурные особенности RU-пользователей на мобильных

| Что важно | Реализация в LighChat | Приоритет |
|---|---|---|
| Стикеры (rich, авторские) | Уже частично есть (кастомные темы), нужны стикерпаки | P1 |
| Голосовые сообщения | Стандарт, **обязательно нужно** | P0 |
| Каналы и боты | Telegram-killer feature — **не пытаться повторить в первый год** | — |
| Файлообмен без лимитов | Конкурентное преимущество (Telegram — 4 GB, Max — 4 GB) | P0 |
| СБП-переводы внутри чата | Сложно, требует партнёрства; нативно есть только у Max | P3 (отложить) |
| Каналы / приватность звонков | E2E + опционально без сохранения метаданных — позиционная фича | P0 |

### 4.5. Топ мобильных запросов в РФ (Яндекс.Wordstat + Google, май 2026, оценки)

| Запрос | Wordstat (мес.) | Google (мес.) | Конкурентность |
|---|---:|---:|---|
| мессенджер | 800K+ | 300K+ | очень высокая |
| мессенджер скачать | 250K | 90K | высокая |
| безопасный мессенджер | 70K | 25K | средняя |
| мессенджер для звонков | 60K | 20K | средняя |
| приватный мессенджер | 45K | 15K | средняя |
| альтернатива WhatsApp | 200K (2026 особенно) | 50K | **высокий потенциал** |
| мессенджер с шифрованием | 30K | 10K | низкая |
| мессенджер на нескольких устройствах | 20K | 8K | низкая (LighChat USP) |
| QR авторизация мессенджер | 5K | 2K | очень низкая (LighChat USP) |

**Выводы для контента:**
- Нацеливаться на «альтернатива WhatsApp» — траффик подскочил в 2025–2026.
- Использовать «безопасный / приватный мессенджер» как core — средняя конкурентность.
- Создавать контент вокруг long-tail USP — «мессенджер с QR-авторизацией», «мессенджер на нескольких устройствах», «кастомные темы для мессенджера».

---

<a id="international"></a>

## 5. Топ-5 международных рынков

Ранжировка по mobile-потенциалу для LighChat с учётом: насыщенность рынка, языковые барьеры, регуляторика, CAC, доступность сторов, размер русскоязычной диаспоры.

### 5.1. #1 — Казахстан (P0)

| Параметр | Значение |
|---|---|
| Население / smartphone penetration | 19.5 млн / ~88% |
| Доминирующие мессенджеры | WhatsApp (~70%), Telegram (~60% — overlap), Viber (~25%), VK (~15%) |
| iOS vs Android | ~15% / ~85% |
| Доминирующий стор | Google Play; App Store работает; RuStore работает (русскоязычная аудитория) |
| Языки | Казахский, русский (большинство мобильных пользователей) |
| Регуляторика | Сравнительно мягкая; локализация данных рекомендована, не обязательна |
| Платёжки | Kaspi.kz (доминирует), Visa/Mastercard работают |
| Оценочный CPI | $0.30–$0.80 |
| Why P0 | **Русскоязычный контент работает 1-в-1; русская диаспора уже там; конкуренты слабо локализованы; Kaspi — пример того, как локальный игрок может выиграть у глобальных** |

**Стратегия входа:** перевод на казахский, заметка о соответствии Kazakh data laws, реклама в Kaspi-связных каналах.

### 5.2. #2 — Узбекистан (P0)

| Параметр | Значение |
|---|---|
| Население / smartphone penetration | 36 млн / ~72% (быстрый рост) |
| Доминирующие мессенджеры | Telegram (~80% — №1!), WhatsApp (~50%), Viber (~10%) |
| iOS vs Android | ~5% / ~95% (Android-доминирующий) |
| Доминирующий стор | Google Play; AppGallery (Huawei сильна); прямой APK |
| Языки | Узбекский (кириллица + латиница), русский (старшее поколение, бизнес) |
| Регуляторика | Развивающаяся; периодически блокируют Telegram, но обычно недолго |
| Платёжки | Click, Payme, UzCard, Humo — локальные |
| Оценочный CPI | $0.20–$0.50 |
| Why P0 | **Telegram доминирует — это значит ниша для альтернативы открыта (privacy-фокус); русский язык работает; молодое население; растущий рынок** |

**Стратегия входа:** локализация на узбекский (латиница), сотрудничество с локальными tech-блогерами, акцент на «работает даже при блокировках» (PWA fallback).

### 5.3. #3 — Турция (P1)

| Параметр | Значение |
|---|---|
| Население / smartphone penetration | 85 млн / ~85% |
| Доминирующие мессенджеры | WhatsApp (~85%), Telegram (~50% — растёт), BIP (локальный, ~30%) |
| iOS vs Android | ~15% / ~85% |
| Доминирующий стор | Google Play, App Store; локальные альтернативы — нет крупных |
| Языки | Турецкий (основной), английский (молодёжь, городские) |
| Регуляторика | Жёсткая (KVKK = аналог GDPR); периодически блокируют |
| Платёжки | Iyzico, PayTR, локальные карты Troy |
| Оценочный CPI | $0.50–$1.50 |
| Why P1 | **Большой платёжеспособный рынок; растущая privacy-аудитория после нескольких скандалов с государством; есть привычка к мессенджерам с шифрованием** |

**Стратегия входа:** локализация на турецкий, KVKK compliance, акцент на безопасность.

### 5.4. #4 — Индонезия (P1)

| Параметр | Значение |
|---|---|
| Население / smartphone penetration | 280 млн / ~71% |
| Доминирующие мессенджеры | WhatsApp (~93%!), LINE (~28%), Telegram (~25% — растёт у молодежи) |
| iOS vs Android | ~14% / **~86.8%** |
| Доминирующий стор | Google Play (доминирует); App Store; AppGallery (Huawei сильна) |
| Языки | Bahasa Indonesia (обяз.), английский (молодежь) |
| Регуляторика | Растущая (UU PDP — аналог GDPR с 2024) |
| Платёжки | GoPay, OVO, DANA, ShopeePay |
| Оценочный CPI | $0.30–$0.80 |
| Why P1 | **Огромный рынок, мобильно-первый, дешёвый CAC, ниша для не-WhatsApp privacy-альтернативы есть** |

**Стратегия входа:** localizatcoba на Bahasa Indonesia, partnership с местными tech-инфлюенсерами, оптимизация под низкие диапазоны Android (Oppo, Vivo, Xiaomi доминируют).

### 5.5. #5 — Бразилия (P2)

| Параметр | Значение |
|---|---|
| Население / smartphone penetration | 215 млн / ~83% |
| Доминирующие мессенджеры | WhatsApp (~99%!! — суперпроникновение), Telegram (~50% — растёт быстро), Discord (молодежь) |
| iOS vs Android | ~17% / **~81.5%** |
| Доминирующий стор | Google Play, App Store |
| Языки | Португальский (бразильский) |
| Регуляторика | LGPD (аналог GDPR с 2020) |
| Платёжки | PIX (доминирует, моментальные переводы), Mercado Pago |
| Оценочный CPI | $0.50–$1.20 |
| Why P2 | **WhatsApp недоступно сильно — но это означает рынок огромный, и любой 1% = 2 млн пользователей. Telegram быстро рос в 2024–2025 — эту волну можно поймать.** |

**Стратегия входа:** localizatcoba на бразильский португальский, тестовая кампания через Meta Ads или TikTok Ads, акцент на молодежь (12–28 лет).

### 5.6. Honorable mentions — Беларусь, Армения, Грузия, Вьетнам, Польша

| Страна | Потенциал | Заметка |
|---|---|---|
| Беларусь | Высокий | Русскоязычная, малый рынок (~9 млн), но низкий CAC; политически чувствительные пользователи |
| Армения, Грузия | Средний | Русскоговорящая диаспора в IT, привычка к нескольким мессенджерам |
| Вьетнам | Низкий-Средний | Доминирует Zalo (локальный) — сложно входить; но Telegram там растёт |
| Польша | Низкий | Жёсткая конкуренция Messenger/WhatsApp/Signal; высокий CAC (~$2–4) |

---

<a id="usp"></a>

## 6. USP и позиционирование LighChat

### 6.1. Уникальные фичи LighChat (объективные)

1. **🔑 QR-авторизация для мульти-девайс** — единственный мессенджер, где переход на новое устройство = сканировать QR (без кода из СМС, без e-mail, без потери истории). У Telegram есть QR, но требует основного устройства; у WhatsApp Multi-Device — ограничен. **Это убойная виральная механика.**
2. **🎨 Кастомные темы чатов** — каждый чат может иметь свою тему; у Telegram есть, но менее гибко.
3. **🛡️ Полное E2E + админ-панель** — необычная комбинация (E2E у Signal/Threema; админка у Slack/Element). LighChat подходит для команд + личного использования одновременно.
4. **🌐 4 платформы, синхронизация** — iOS, Android, Web, Desktop с одинаковой функциональностью. У многих конкурентов desktop — клон веба.
5. **🚫 Политически нейтральный** — не аффилирован ни с одной страной, не подписывается под любую идеологию.

### 6.2. Tagline / value proposition (3 варианта × RU/EN, ≤30 символов)

| # | RU | EN | Аудитория |
|---|---|---|---|
| 1 | Ваши чаты, везде. | Your chats, everywhere. | Mass-market — простота, мульти-девайс |
| 2 | Шифрование без сложностей. | Encryption made simple. | Privacy-аудитория |
| 3 | Один QR — все устройства. | One QR. All devices. | Tech-аудитория, USP-led |

### 6.3. Позиционирование

**Россия:**
> «LighChat — независимый мессенджер для тех, кто хочет общаться без оглядки. E2E-шифрование, кастомные темы, мгновенный переход между устройствами через QR. Не аффилирован с государствами и корпорациями.»

**Международный рынок:**
> «LighChat — the multi-device messenger that just works. Move between iPhone, Android, web, and desktop with one QR scan. End-to-end encrypted. Not owned by Big Tech.»

---

<a id="sources"></a>

## 7. Источники

### Глобальные данные
- [Telegram Users Statistics 2026 (DemandSage)](https://www.demandsage.com/telegram-statistics/)
- [WhatsApp Statistics and News 2026 (CXWizard)](https://cxwizard.app/en/blog/whatsapp-statistics-and-news)
- [Most popular messaging apps 2025 (Statista)](https://www.statista.com/statistics/258749/most-popular-global-mobile-messenger-apps/)
- [Most popular messaging apps by country (Sinch)](https://sinch.com/blog/most-popular-messaging-apps-by-country/)
- [Sinch — popular messaging apps update 2025 (Netmill SMS)](https://netmillsms.com/the-most-popular-messaging-apps-in-the-world-by-country-2025-update/)
- [Asia messaging app battle (btrax)](https://blog.btrax.com/asias-battle-of-the-messaging-app-wechat-vs-line-vs-kakaotalk/)

### Российский рынок
- [Mediascope — MAX messenger daily audience Dec 2025 (Izvestia)](https://en.iz.ru/en/2015002/2025-12-25/mediascope-presented-data-daily-audience-max-messenger)
- [Telegram becomes Russia's most popular messenger (Caliber.Az)](https://caliber.az/en/post/telegram-becomes-russia-s-most-popular-messenger)
- [Russians flock to imo amid restrictions (Cryptopolitan)](https://www.cryptopolitan.com/russians-flock-to-us-messenger-imo/)
- [Max messenger Wikipedia](https://en.wikipedia.org/wiki/Max_(app))
- [BBC — Max, Kremlin-backed messenger](https://bbcrussian.substack.com/p/what-we-know-about-max-the-kremlin-backed-messenger)
- [VK — 50M+ users on MAX](https://vk.company/en/press/releases/12139/)
- [Mediascope Conference 2025 materials](https://mediascope.net/en/news/3218603/)

### Регуляторика и сторы РФ
- [RuStore Wikipedia](https://en.wikipedia.org/wiki/RuStore)
- [Russia mandates RuStore from Sept 2025 (Telecompaper)](https://www.telecompaper.com/news/russia-to-make-rustore-mandatory-on-iphones-ipads--1513337)
- [iPhones in Russia must ship with state-backed messenger preinstalled (9to5Mac)](https://9to5mac.com/2025/08/21/new-iphones-and-ipads-in-russia-must-ship-with-state-backed-messaging-app-preinstalled/)
- [Apple App Store Russia status April 2026 (Apple Support)](https://support.apple.com/en-us/126891)
- [Apple cuts off Russian Developer Enterprise Program (MacRumors)](https://www.macrumors.com/2025/02/25/apple-developer-enterprise-program-russia/)
- [Apple Search Ads suspended in Russia (TechCrunch)](https://techcrunch.com/2022/03/07/apple-suspends-search-ads-on-the-russian-app-store-until-further-notice/)

### ASO и mobile UA
- [ASO 2026 guide (ASOMobile)](https://asomobile.net/en/blog/aso-in-2026-the-complete-guide-to-app-optimization/)
- [ASO keyword research 2026 (MobileAction)](https://www.mobileaction.co/blog/aso-keyword-research/)
- [App Store Keywords Optimization 2025 (SplitMetrics)](https://splitmetrics.com/blog/app-store-keyword-optimization/)
- [SplitMetrics Apple Ads Search Results Benchmarks 2025](https://splitmetrics.com/apple-ads-search-results-benchmarks-2025/)
- [Apptweak Apple Ads benchmarks 2025](https://www.apptweak.com/en/aso-blog/apple-ads-benchmarks)
- [CPI by country 2025 (Mapendo)](https://mapendo.co/blog/cost-per-install-by-country-2025)
- [Cost per Install rates 2025 (Business of Apps)](https://www.businessofapps.com/ads/cpi/research/cost-per-install/)

### Smartphone penetration
- [Smartphone penetration by country (Wikipedia)](https://en.wikipedia.org/wiki/List_of_countries_by_smartphone_penetration)
- [Smartphone vendor market share 60 countries Q1 2025 (TechInsights)](https://www.techinsights.com/blog/smartphone-vendor-market-share-60-countries-q1-2025)
- [Mobile Operating System Market Share Indonesia (StatCounter)](https://gs.statcounter.com/os-market-share/mobile/indonesia)
- [Android Global Market Share Statistics 2026](https://commandlinux.com/android/android-global-market-share-statistics/)

---

> ⏭ **Дальше:** см. [aso-keywords-recommendations.md](aso-keywords-recommendations.md) для конкретных строк ASO, [mobile-ua-strategy.md](mobile-ua-strategy.md) для стратегии user acquisition, [action-plan-90d.md](action-plan-90d.md) для пошагового плана.
