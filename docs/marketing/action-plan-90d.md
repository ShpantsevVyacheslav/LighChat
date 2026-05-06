# LighChat — План действий на 90 дней (mobile-first)

> **Период:** 6 спринтов по 2 недели = 90 дней с момента старта.  
> **Приоритеты:** P0 (must), P1 (should), P2 (nice).  
> **Роли:** PM (product manager), Mobile (Flutter dev), Backend, ASO/Marketing, Designer, DevOps.

---

## Стратегические цели на 90 дней

| Метрика | Старт (D0) | Цель (D90) |
|---|---:|---:|
| Установки (всего) | 0 | **75,000+** (Сценарий B) |
| MAU | 0 | **40,000+** |
| D7 retention | 0 | **≥ 18%** |
| K-factor (виральность) | 0 | **≥ 0.4** |
| Сторов с публикацией | 0 | **5** (App Store, Google Play, RuStore, AppGallery, NashStore) |
| Локализаций | 1–2 | **6+** (RU, EN, KZ, UZ, ID, ES, PT, TR) |
| Рейтинг в App Store / Google Play | — | **≥ 4.4** |

---

## Sprint 1 — Дни 1–14: Foundation & Stores

### Цель: запустить во всех 5 сторах + аналитика + первые ASO

| # | Задача | Роль | Приоритет | Метрика успеха |
|---|---|---|---|---|
| 1.1 | Зарегистрировать аккаунты разработчика во всех сторах: App Store ($99/год), Google Play ($25 одноразово), RuStore (бесплатно), NashStore (бесплатно), AppGallery (бесплатно), GetApps Xiaomi (бесплатно) | PM | **P0** | 5 активных аккаунтов |
| 1.2 | Подготовить metadata по ASO-recommendations: title, subtitle, descriptions, keywords для всех сторов и 6 локалей | ASO | **P0** | 6 локалей × 5 сторов = 30 листингов готовы |
| 1.3 | Создать 8 скриншотов (8 девайсов: iPhone Pro, iPad, Android phone, Android tablet) — итого 32 скриншота на локаль | Designer | **P0** | 32 × 6 локалей = 192 скриншота |
| 1.4 | Снять App Preview видео (3 шт по 30 сек) для App Store + 1 видео для Google Play | Designer | P1 | 4 видео готовы |
| 1.5 | Подготовить иконку в 3 вариантах для A/B тестов | Designer | P1 | 3 варианта × 6 локалей |
| 1.6 | Подключить AppsFlyer (или Adjust) для attribution | Mobile + Backend | **P0** | События отправляются, dashboard работает |
| 1.7 | Подключить Amplitude для product analytics | Mobile | **P0** | 10 ключевых событий трекаются |
| 1.8 | Настроить Firebase Crashlytics + Performance Monitoring | Mobile | **P0** | Crash rate < 0.5%, ANR < 0.3% |
| 1.9 | Настроить Yandex.Metrika на лендинге lighchat.com | Marketing | **P0** | События лендинга трекаются |
| 1.10 | Внедрить Universal Links (iOS) и App Links (Android) для домена lighchat.com | Mobile | **P0** | Тест — клик на `lighchat.com/u/test` открывает приложение |
| 1.11 | Опубликовать первые билды во все 5 сторов | Mobile | **P0** | 5 листингов в статусе "В обзоре" |

**Riepilogo Sprint 1:** все основы готовы, аналитика работает, метаданные оптимизированы.

---

## Sprint 2 — Дни 15–28: Growth Mechanics + Soft Launch

### Цель: внедрить виральные механики и запустить soft launch с минимальным бюджетом

| # | Задача | Роль | Приоритет | Метрика успеха |
|---|---|---|---|---|
| 2.1 | Реализовать **QR-deep-link приглашения** друзьям (расширение существующей QR-фичи) | Mobile + Backend | **P0** | Пользователь может сгенерировать QR-приглашение |
| 2.2 | Реализовать **App Clip (iOS) / Instant App (Android)** для быстрой установки через QR | Mobile | P1 | App Clip работает — друг видит preview без установки |
| 2.3 | Реализовать contact-sync (опционально, с явным consent) | Mobile + Backend | **P0** | После consent — список «X из ваших контактов уже в LighChat» |
| 2.4 | Реализовать share-to-install через Universal Links | Mobile | **P0** | Ссылка на профиль или группу открывает соответствующее место |
| 2.5 | Реализовать lifecycle push: onboarding D0 + D1 + D3 win-back | Backend + Mobile | **P0** | 3 push-события работают |
| 2.6 | Запустить **Soft launch** в Казахстане + Узбекистане (бюджет $1,500) — Google App Campaigns | Marketing | **P0** | 3,000–5,000 установок, CPI ≤ $0.50 |
| 2.7 | Запустить рекламу в Telegram Ads (РФ + EN) ($1,000) | Marketing | P1 | 1,500–3,000 установок |
| 2.8 | Подать заявку на featured в RuStore | Marketing | P1 | Заявка отправлена |
| 2.9 | Запустить A/B тест #1: иконка V1 vs V3 в Google Play (Listing Experiments) | ASO | P1 | Тест запущен, ждём 1000+ visitors |

**Sprint 2 metrics:** ~5,000 установок, K-factor ≥ 0.2, D1 retention ≥ 30%.

---

## Sprint 3 — Дни 29–42: Russia Push + Performance Optimization

### Цель: масштабирование в РФ + retention-оптимизация

| # | Задача | Роль | Приоритет | Метрика успеха |
|---|---|---|---|---|
| 3.1 | Запустить **VK Ads** в РФ ($3,000) — таргет на молодёжь и privacy-аудиторию | Marketing | **P0** | 6,000–10,000 установок, CPI ≤ $0.50 |
| 3.2 | Запустить **Yandex.Direct mobile** в РФ ($2,000) — search intent на «альтернатива WhatsApp» и долгие хвосты | Marketing | **P0** | 3,000–5,000 установок |
| 3.3 | Запустить **Дзен.Промо** ($500) — нативные статьи о приватности | Marketing | P1 | 500–1,000 установок |
| 3.4 | Анализ retention curves в Amplitude — выявить drop-off points | PM + Mobile | **P0** | Документ с топ-3 проблем onboarding |
| 3.5 | Реализовать улучшения onboarding на основе анализа | Mobile + Designer | **P0** | D1 retention +5–10pp |
| 3.6 | Реализовать **Hero notifications** для входящих звонков и приглашений | Mobile + Backend | **P0** | Push с rich-content и кнопками |
| 3.7 | Запустить TikTok Ads в РФ + СНГ ($1,500) — короткие вертикальные креативы про QR-вход и темы | Marketing | P1 | 2,000–4,000 установок |
| 3.8 | Внедрить in-app-rating prompt после положительного события (отправил >5 сообщений) | Mobile | P1 | Рейтинг в Google Play растёт |
| 3.9 | A/B тест #2: subtitle «Шифрование» vs «Альтернатива WhatsApp» (Apple PPO) | ASO | P1 | Тест запущен |

**Sprint 3 metrics:** общий total ~25,000 установок, MAU ~14,000, D7 retention ≥ 18%.

---

## Sprint 4 — Дни 43–56: International Expansion + Content

### Цель: запуск в Турции и Индонезии + контент-маркетинг

| # | Задача | Роль | Приоритет | Метрика успеха |
|---|---|---|---|---|
| 4.1 | Локализовать на турецкий + индонезийский (UI + ASO + email + push) | Mobile + ASO | **P0** | UI работает на TR + ID, listings обновлены |
| 4.2 | Запустить кампанию в Турции ($3,000) — Google App Campaigns + TikTok Ads | Marketing | **P0** | 3,000–5,000 установок |
| 4.3 | Запустить кампанию в Индонезии ($3,000) — Google App Campaigns + Meta Ads + TikTok Ads | Marketing | **P0** | 5,000–10,000 установок |
| 4.4 | Завести Telegram-канал на 3 языках (RU, EN, ID) — ежедневные посты о фичах | Marketing | P1 | Канал создан, ≥10 постов в первые 2 нед |
| 4.5 | Завести YouTube-канал — 5 видео-туториалов (по 1–2 минуты) на RU + EN | Marketing | P1 | 5 видео опубликовано |
| 4.6 | Запустить блог на lighchat.com — 6 SEO-статей (по 1500–2000 слов) | Marketing | P1 | 6 статей опубликовано, проиндексированы Google + Яндекс |
| 4.7 | Внедрить iOS Live Activities для текущих звонков (iOS 16.1+) | Mobile | P2 | Live Activity отображается во время звонка |
| 4.8 | Подать заявку на Apple App Store Featured (через nominate@apple.com) | Marketing | P2 | Заявка отправлена |

**Sprint 4 metrics:** total ~40,000 установок, MAU ~22,000, D7 retention ≥ 20%.

---

## Sprint 5 — Дни 57–70: PR + Influencer + Optimization

### Цель: PR-волна, инфлюенсеры, A/B оптимизация

| # | Задача | Роль | Приоритет | Метрика успеха |
|---|---|---|---|---|
| 5.1 | Опубликовать продуктовую статью на Habr (RU) — фокус на технические детали (Flutter + Firebase + WebRTC) | Marketing | **P0** | Статья в топ-50 Habr за день |
| 5.2 | Опубликовать продуктовую статью на vc.ru (RU) — фокус на бизнес и USP | Marketing | **P0** | Статья ≥ 5K просмотров |
| 5.3 | Опубликовать на Pikabu — нативный контент про privacy и QR-вход | Marketing | P1 | ≥ 3K просмотров |
| 5.4 | Запустить на Product Hunt с английским лендингом | Marketing | **P0** | Top-5 of the day, 500+ upvotes |
| 5.5 | Опубликовать в r/privacytools, r/messengers (Reddit, EN) — органические посты | Marketing | P1 | ≥ 200 upvotes |
| 5.6 | Подключить 5 русскоязычных tech-инфлюенсеров (Telegram-каналы 50K+) для нативной интеграции | Marketing | **P0** | 5 коллабораций, ~10,000 установок суммарно |
| 5.7 | Подключить 3 турецких + 3 индонезийских tech-инфлюенсера | Marketing | P1 | 6 коллабораций, ~5,000 установок |
| 5.8 | A/B тест #3: feature graphic в Google Play | ASO | P1 | Тест запущен |
| 5.9 | A/B тест #4: video preview в App Store (USP-фокус vs feature-обзор) | ASO | P1 | Тест запущен |
| 5.10 | Реализовать App Intents (Siri integration: «отправить через LighChat») | Mobile | P2 | Siri-команда работает |

**Sprint 5 metrics:** total ~55,000 установок, MAU ~30,000, рейтинг ≥ 4.4.

---

## Sprint 6 — Дни 71–90: Scale & LatAm Test + Retention Deep Dive

### Цель: масштабирование на LatAm, дополнительная оптимизация retention

| # | Задача | Роль | Приоритет | Метрика успеха |
|---|---|---|---|---|
| 6.1 | Локализовать на бразильский португальский + испанский (Mexico) | Mobile + ASO | **P0** | UI и listings готовы |
| 6.2 | Тестовая кампания в Бразилии ($2,000) + Мексике ($1,500) — Google + TikTok | Marketing | **P0** | 4,000–7,000 установок суммарно |
| 6.3 | Деep retention analysis — cohort study D30/D60/D90 | PM | **P0** | Документ с инсайтами по retention |
| 6.4 | Реализовать D7 + D30 win-back push с персонализацией (Firebase Remote Config + Amplitude cohorts) | Mobile + Backend | **P0** | D30 retention +3–5pp |
| 6.5 | Запустить реферальную программу (бейджи + стикерпаки за приглашения) | Mobile + Designer | **P0** | K-factor +0.1–0.2 |
| 6.6 | Внедрить **embedded share-card** — при отправке ссылки на профиль/группу формируется красивое preview-card в Telegram/WhatsApp | Backend + Designer | P1 | Preview работает в TG/WA |
| 6.7 | Запросить отзывы у активных пользователей (push + in-app) | Marketing + Mobile | P1 | Average rating ≥ 4.4 |
| 6.8 | Расширить ASO ключевыми словами на основе данных из Amplitude (что искали пользователи) | ASO | P1 | Listings обновлены |
| 6.9 | Подать заявку на Google Play Editorial Featured | Marketing | P2 | Заявка отправлена |
| 6.10 | Финальный отчёт за 90 дней + план на следующие 90 | PM | **P0** | Документ `marketing-90d-results.md` |

**Sprint 6 / финал metrics:** total **~75,000+ установок**, MAU **~40,000+**, D7 retention **≥ 18%**, K-factor **≥ 0.4**.

---

## Sprint Summary Table

| Sprint | Дни | Focus | Бюджет UA | Cumulative installs target | Cumulative MAU |
|---|---|---|---:|---:|---:|
| 1 | 1–14 | Stores + Analytics | $0 | 0 | 0 |
| 2 | 15–28 | Virality + Soft Launch | $2,500 | 5,000 | 3,000 |
| 3 | 29–42 | Russia Push | $7,000 | 25,000 | 14,000 |
| 4 | 43–56 | TR + ID + Content | $7,000 | 40,000 | 22,000 |
| 5 | 57–70 | PR + Influencer | $5,000 | 55,000 | 30,000 |
| 6 | 71–90 | LatAm + Retention | $5,000 | **75,000+** | **40,000+** |
| **Итого** | **90** | | **$26,500** + ASO/tools $5,000 = **$31,500** | | |

> Бюджет на 90 дней при сценарии B (~$45K) включает дополнительные средства на инфлюенсеров и ASO-tools.

---

## Метрики dashboard (трекать ежедневно)

| Метрика | Где смотреть | Частота |
|---|---|---|
| Daily installs (по каналам и сторам) | AppsFlyer | ежедневно |
| CPI / CPA по каналам | AppsFlyer + ad platforms | ежедневно |
| Daily MAU / DAU / Stickiness | Amplitude | ежедневно |
| D1 / D7 / D30 retention | Amplitude cohorts | еженедельно |
| K-factor (invites sent / accepted) | Amplitude funnels | еженедельно |
| ASO ranking (топ-50 keywords) | App Radar / AppTweak | еженедельно |
| Crash rate / ANR | Firebase Crashlytics | ежедневно |
| Rating + review velocity | Store Console | ежедневно |
| Push delivery rate / open rate | Firebase / FCM | еженедельно |

---

## Риски и митигации

| Риск | Вероятность | Импакт | Митигация |
|---|---|---|---|
| Apple отклонит первый билд из-за политики | Средняя | Высокий | Заранее изучить App Store Review Guidelines, особенно по messaging apps |
| RuStore медленно одобряет publication | Низкая | Средний | Связаться с RuStore Developer Relations заранее |
| WhatsApp / Telegram запустят аналог QR-multidevice | Высокая | Высокий | Двигаться быстро — наш USP должен быть выпущен и закреплён в маркетинге как «изобретение LighChat» |
| Регуляторные ограничения в РФ ужесточатся | Высокая | Средний | Иметь готовое решение по 152-ФЗ (Yandex.Cloud / VK Cloud для российских пользователей) |
| CPI окажется выше прогноза | Средняя | Высокий | Постоянная оптимизация креативов; быстрое отключение неэффективных кампаний (правило: KPI не достигнут за 7 дней — стоп) |
| K-factor ниже 0.3 | Средняя | Высокий | Усиление виральных механик: больше gamification, эксклюзивные награды за приглашения |
| Отрицательные отзывы в RU из-за политики | Средняя | Средний | Активная работа с support, быстрые ответы на 100% reviews |

---

## После 90 дней — следующие шаги (preview)

1. **D90–D180:** Углубление в выбранные топ-3 рынка + первые попытки монетизации (Premium-функции, business-аккаунты).
2. **Бизнес-инфраструктура:** создание dedicated marketing department, hire performance marketer.
3. **Расширение функционала:** каналы, боты, платежи (партнёрство с Yandex Pay / СБП).
4. **Featured campaigns:** активные заявки на Apple App Store, Google Play Editorial, RuStore.

---

> ⏭ **Дальше:** см. [README.md](README.md) для executive summary всего пакета документов.
