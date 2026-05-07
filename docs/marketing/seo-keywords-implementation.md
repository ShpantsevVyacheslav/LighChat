# LighChat — SEO/ASO ключи в коде: где и что менять

> **Практический документ.** Где в репозитории живут ключевые слова и как их внедрить, чтобы LighChat ранжировался выше в Google, Яндекс, App Store, Google Play и сторах СНГ.  
> **Все изменения проверены на текущем состоянии репозитория** (май 2026).  
> **Связь:** ключи берутся из [aso-keywords-recommendations.md](aso-keywords-recommendations.md). Здесь — куда их вкладывать в код.

---

## Карта мест, где нужны ключи

| # | Файл | Где влияет | Текущее состояние | Приоритет |
|---|---|---|---|---|
| 1 | `src/app/layout.tsx` | Google + Яндекс SEO веб-версии | ❌ минимально | **P0** |
| 2 | `src/app/page.tsx` | Главная страница (структурные h1/h2) | ⚠️ это login, не лендинг | **P0** |
| 3 | `public/manifest.json` | PWA install + Google Play TWA | ⚠️ короткое описание | **P0** |
| 4 | `mobile/app/pubspec.yaml` | Метаданные Flutter-проекта, GitHub | ❌ `"A new Flutter project."` (DEFAULT) | **P0** |
| 5 | `mobile/app/web/manifest.json` | Flutter Web PWA | ❌ DEFAULT (`lighchat_mobile`) | **P0** |
| 6 | `mobile/app/ios/Runner/Info.plist` | iOS App Store + системные диалоги | ⚠️ `CFBundleName: lighchat_mobile` | **P0** |
| 7 | `mobile/app/ios/Runner/*.lproj/InfoPlist.strings` | iOS локализованные имена в App Store | ❌ файлов нет | **P1** |
| 8 | `mobile/app/android/app/src/main/AndroidManifest.xml` | Android Google Play | ❌ `android:label="lighchat_mobile"` | **P0** |
| 9 | `mobile/app/android/app/src/main/res/values*/strings.xml` | Android локализованные имена | ❌ файлов нет | **P1** |
| 10 | `mobile/app/android/app/build.gradle.kts` | applicationId, namespace | ⚠️ нужно проверить | **P1** |
| 11 | `package.json` (root) | npm metadata, GitHub | ⚠️ нет description | **P1** |
| 12 | `README.md` (root) | GitHub поиск, Google индексация публичного репо | ⚠️ только RU, без structure | **P1** |
| 13 | `description` (файл) | apphosting.yaml / GitHub About | ⚠️ нужно проверить | **P2** |
| 14 | `public/robots.txt` | Контроль индексации Google/Yandex | ❌ файла нет | **P0** |
| 15 | `src/app/sitemap.ts` (Next.js) | Sitemap для Google/Yandex | ❌ файла нет | **P0** |
| 16 | `src/app/page.tsx` — JSON-LD `SoftwareApplication` | Rich snippets в Google | ❌ нет | **P1** |
| 17 | Apple Smart App Banner / Android Web App Banner | Конверсия web → install | ❌ нет | **P0** после публикации в сторах |
| 18 | OpenGraph + Twitter Cards meta | Превью при шаринге в TG/WA/X/FB | ❌ нет | **P0** |

---

## 1. Web SEO — `src/app/layout.tsx` (главное!)

### Текущее состояние (упрощённо)

```tsx
export const metadata: Metadata = {
  title: 'LighChat',
  description: 'Messenger & Video Conferencing',
  applicationName: 'LighChat',
  manifest: '/manifest.json',
  // ... icons, appleWebApp
};
```

**Проблемы:** title слишком короткий, description без ключей, лангоднозначно (lang="ru" но description EN), **нет** `keywords`, `OpenGraph`, `Twitter Card`, `alternates.languages` для hreflang.

### Что нужно сделать

```tsx
const SITE_URL = 'https://lighchat.com';

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: {
    default: 'LighChat — безопасный мессенджер с шифрованием и QR-входом',
    template: '%s | LighChat',
  },
  description:
    'LighChat — приватный мессенджер с E2E-шифрованием, мульти-девайс через QR-код, кастомными темами и HD-видеозвонками. Альтернатива WhatsApp и Telegram. Бесплатно для iOS, Android, Web и Desktop.',
  keywords: [
    'мессенджер',
    'безопасный мессенджер',
    'приватный мессенджер',
    'мессенджер с шифрованием',
    'альтернатива whatsapp',
    'альтернатива telegram',
    'видеозвонки',
    'видеоконференции',
    'e2e шифрование',
    'мессенджер на нескольких устройствах',
    'qr вход',
    'мульти-девайс мессенджер',
    'кастомные темы чатов',
    'messenger',
    'private messenger',
    'secure messaging',
    'encrypted chat',
    'whatsapp alternative',
    'telegram alternative',
    'multi device messenger',
    'video conferencing',
  ],
  authors: [{ name: 'LighChat Team', url: SITE_URL }],
  creator: 'LighChat',
  publisher: 'LighChat',
  applicationName: 'LighChat',
  category: 'communication',
  classification: 'Communication, Social Networking, Productivity',
  manifest: '/manifest.json',
  alternates: {
    canonical: SITE_URL,
    languages: {
      'ru-RU': `${SITE_URL}/ru`,
      'en-US': `${SITE_URL}/en`,
      'kk-KZ': `${SITE_URL}/kk`,
      'uz-UZ': `${SITE_URL}/uz`,
      'tr-TR': `${SITE_URL}/tr`,
      'id-ID': `${SITE_URL}/id`,
      'pt-BR': `${SITE_URL}/pt-br`,
      'es-MX': `${SITE_URL}/es-mx`,
      'x-default': SITE_URL,
    },
  },
  openGraph: {
    type: 'website',
    locale: 'ru_RU',
    alternateLocale: ['en_US', 'kk_KZ', 'uz_UZ', 'tr_TR', 'id_ID', 'pt_BR', 'es_MX'],
    url: SITE_URL,
    siteName: 'LighChat',
    title: 'LighChat — безопасный мессенджер с шифрованием и QR-входом',
    description:
      'Приватный мессенджер с E2E-шифрованием. Мульти-девайс через QR-код. HD-видеозвонки. Альтернатива WhatsApp и Telegram. Бесплатно.',
    images: [
      {
        url: '/og/og-1200x630.png',
        width: 1200,
        height: 630,
        alt: 'LighChat — безопасный мессенджер',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    site: '@lighchat',
    creator: '@lighchat',
    title: 'LighChat — безопасный мессенджер с шифрованием и QR-входом',
    description:
      'Приватный мессенджер с E2E-шифрованием. Мульти-девайс через QR. Альтернатива WhatsApp и Telegram. Бесплатно.',
    images: ['/og/twitter-1200x630.png'],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-image-preview': 'large',
      'max-snippet': -1,
      'max-video-preview': -1,
    },
  },
  verification: {
    google: 'TODO_GOOGLE_SEARCH_CONSOLE_TOKEN',
    yandex: 'TODO_YANDEX_WEBMASTER_TOKEN',
    other: {
      'msvalidate.01': 'TODO_BING_WEBMASTER_TOKEN',
    },
  },
  icons: {
    icon: [
      { url: '/pwa/favicon-192.png', sizes: '192x192', type: 'image/png' },
      { url: '/pwa/favicon-512.png', sizes: '512x512', type: 'image/png' },
    ],
    apple: [{ url: '/apple-touch-icon.png', sizes: '180x180', type: 'image/png' }],
  },
  appleWebApp: {
    capable: true,
    statusBarStyle: 'black-translucent',
    title: 'LighChat',
  },
  // Smart App Banner для iOS Safari (после публикации в App Store)
  // см. itunes-app meta тег
  other: {
    'apple-itunes-app': 'app-id=YOUR_APP_ID, app-argument=lighchat://',
    'google-play-app': 'app-id=com.lighchat.mobile',
  },
};
```

**Активы для подготовки:**
- `/og/og-1200x630.png` — фон с логотипом и USP
- `/og/twitter-1200x630.png` — то же для X/Twitter
- `/apple-touch-icon.png` — уже есть

---

## 2. JSON-LD structured data (rich snippets в Google)

Добавить в `src/app/page.tsx` (если используется как лендинг) или в новый `src/app/(marketing)/page.tsx`:

```tsx
const jsonLd = {
  '@context': 'https://schema.org',
  '@type': 'SoftwareApplication',
  name: 'LighChat',
  applicationCategory: 'CommunicationApplication',
  operatingSystem: 'iOS, Android, Windows, macOS, Linux, Web',
  description: 'Приватный мессенджер с E2E-шифрованием, мульти-девайс через QR и кастомными темами',
  offers: {
    '@type': 'Offer',
    price: '0',
    priceCurrency: 'RUB',
  },
  aggregateRating: {
    '@type': 'AggregateRating',
    ratingValue: '4.6',
    ratingCount: '1234',
  },
  // ↑ Заполнить после первых отзывов; до этого — убрать блок
  url: 'https://lighchat.com',
  publisher: {
    '@type': 'Organization',
    name: 'LighChat',
    url: 'https://lighchat.com',
  },
};

// в JSX:
<script
  type="application/ld+json"
  dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
/>
```

---

## 3. PWA `public/manifest.json` — расширить

### Текущее состояние

```json
{
  "name": "LighChat",
  "short_name": "LighChat",
  "description": "Мессенджер и видеоконференции",
  ...
}
```

### Что добавить

```json
{
  "name": "LighChat — безопасный мессенджер с QR-входом",
  "short_name": "LighChat",
  "description": "Приватный мессенджер с E2E-шифрованием. Мульти-девайс через QR. HD-видеозвонки. Альтернатива WhatsApp и Telegram.",
  "lang": "ru-RU",
  "dir": "ltr",
  "categories": ["social", "communication", "productivity"],
  "start_url": "/dashboard",
  "scope": "/",
  "display": "standalone",
  "display_override": ["window-controls-overlay", "standalone", "minimal-ui"],
  "background_color": "#0a0e17",
  "theme_color": "#0a0e17",
  "orientation": "portrait",
  "id": "/",
  "icons": [ /* как сейчас */ ],
  "screenshots": [
    {
      "src": "/screenshots/desktop-1.png",
      "sizes": "1280x800",
      "type": "image/png",
      "form_factor": "wide",
      "label": "Чаты в LighChat"
    },
    {
      "src": "/screenshots/mobile-1.png",
      "sizes": "390x844",
      "type": "image/png",
      "form_factor": "narrow",
      "label": "Мобильная версия LighChat"
    }
  ],
  "shortcuts": [ /* как сейчас + add labels */ ],
  "prefer_related_applications": true,
  "related_applications": [
    {
      "platform": "play",
      "url": "https://play.google.com/store/apps/details?id=com.lighchat.mobile",
      "id": "com.lighchat.mobile"
    },
    {
      "platform": "itunes",
      "url": "https://apps.apple.com/app/lighchat/idTODO"
    },
    {
      "platform": "rustore",
      "url": "https://www.rustore.ru/catalog/app/com.lighchat.mobile"
    }
  ]
}
```

> `categories: ["social", "communication", "productivity"]` — критично для Google Play TWA-обёртки и для PWA-каталогов (например, [appsco.pe](https://appsco.pe)).

---

## 4. Flutter — `mobile/app/pubspec.yaml`

### Текущее (плохо)

```yaml
name: lighchat_mobile
description: "A new Flutter project."
```

### Должно быть

```yaml
name: lighchat_mobile
description: "LighChat — приватный мессенджер с E2E-шифрованием, QR-мульти-девайс, кастомными темами и HD-видеозвонками. Альтернатива WhatsApp и Telegram для iOS и Android."
homepage: https://lighchat.com
repository: https://github.com/ShpantsevVyacheslav/LighChat
issue_tracker: https://github.com/ShpantsevVyacheslav/LighChat/issues
documentation: https://lighchat.com/docs
```

> Description в `pubspec.yaml` влияет на: GitHub-индексацию, pub.dev (если опубликовано), внутренние мета.

---

## 5. Flutter Web — `mobile/app/web/manifest.json` + `index.html`

### Текущее (DEFAULT, плохо!)

```json
{
  "name": "lighchat_mobile",
  "short_name": "lighchat_mobile",
  "description": "A new Flutter project.",
  ...
}
```

### Должно быть

```json
{
  "name": "LighChat — безопасный мессенджер",
  "short_name": "LighChat",
  "description": "Приватный мессенджер с E2E-шифрованием. Мульти-девайс через QR. HD-видеозвонки. Альтернатива WhatsApp и Telegram.",
  "lang": "ru-RU",
  "categories": ["social", "communication", "productivity"],
  "start_url": ".",
  "display": "standalone",
  "background_color": "#0a0e17",
  "theme_color": "#0a0e17",
  "orientation": "portrait-primary",
  "prefer_related_applications": false,
  "icons": [ /* как сейчас */ ]
}
```

И в `mobile/app/web/index.html` — добавить meta-теги аналогично Next.js layout.

---

## 6. iOS `Info.plist` + локализация

### Текущее

```xml
<key>CFBundleDisplayName</key>
<string>Lighchat Mobile</string>
<key>CFBundleName</key>
<string>lighchat_mobile</string>
```

### Должно быть

```xml
<key>CFBundleDisplayName</key>
<string>LighChat</string>
<key>CFBundleName</key>
<string>LighChat</string>
<!-- ↓ опционально для App Store -->
<key>NSHumanReadableCopyright</key>
<string>© 2026 LighChat. Все права защищены.</string>
```

### Локализация имени приложения по странам

Создать файлы:

`mobile/app/ios/Runner/ru.lproj/InfoPlist.strings`:
```
"CFBundleDisplayName" = "LighChat";
"CFBundleName" = "LighChat";
```

`mobile/app/ios/Runner/en.lproj/InfoPlist.strings`:
```
"CFBundleDisplayName" = "LighChat";
"CFBundleName" = "LighChat";
```

И добавить в `Info.plist`:
```xml
<key>CFBundleLocalizations</key>
<array>
  <string>ru</string>
  <string>en</string>
  <string>kk</string>
  <string>uz</string>
  <string>tr</string>
  <string>id</string>
</array>
<key>CFBundleDevelopmentRegion</key>
<string>ru</string>
```

> **Важно:** `CFBundleDisplayName` — это что пользователь видит на home screen. App Store вытягивает name отдельно из App Store Connect (см. [aso-keywords-recommendations.md](aso-keywords-recommendations.md)).

---

## 7. Android — `AndroidManifest.xml` + локализованные strings.xml

### Текущее

```xml
<application android:label="lighchat_mobile" ...>
```

### Должно быть

```xml
<application android:label="@string/app_name" ...>
```

### `app/src/main/res/values/strings.xml` (default)

```xml
<resources>
    <string name="app_name">LighChat</string>
    <string name="app_description">Приватный мессенджер с E2E-шифрованием</string>
</resources>
```

### `app/src/main/res/values-ru/strings.xml`

```xml
<resources>
    <string name="app_name">LighChat</string>
    <string name="app_description">Безопасный мессенджер с QR-входом</string>
</resources>
```

### `app/src/main/res/values-en/strings.xml`

```xml
<resources>
    <string name="app_name">LighChat</string>
    <string name="app_description">Secure messenger with QR login</string>
</resources>
```

### Аналогично для `values-kk`, `values-uz`, `values-tr`, `values-id`, `values-pt-rBR`, `values-es-rMX`

> `android:label` индексируется Google Play — оптимально оставить просто «LighChat» без ключевых слов в label (выглядит как спам). Ключи — в Google Play Console.

---

## 8. `package.json` (root) — npm/GitHub metadata

### Сейчас

```json
{
  "name": "lighchat",
  ...
}
```

### Добавить

```json
{
  "name": "lighchat",
  "description": "LighChat — приватный мессенджер с E2E-шифрованием, мульти-девайс через QR и кастомными темами для веб, PWA, Electron и мобильных платформ.",
  "homepage": "https://lighchat.com",
  "repository": {
    "type": "git",
    "url": "https://github.com/ShpantsevVyacheslav/LighChat"
  },
  "bugs": {
    "url": "https://github.com/ShpantsevVyacheslav/LighChat/issues"
  },
  "keywords": [
    "messenger",
    "chat",
    "video-conferencing",
    "e2e-encryption",
    "webrtc",
    "flutter",
    "nextjs",
    "firebase",
    "pwa",
    "electron",
    "qr-auth",
    "private-messenger"
  ],
  "license": "AGPL-3.0-or-later",
  "author": "LighChat Team"
}
```

> `keywords` в package.json индексируется на pub.dev / npm + GitHub-поиск.

---

## 9. GitHub README — структура для SEO

GitHub README индексируется Google. Сейчас он на русском без EN-секции.

### Рекомендация:

1. **Поместить badges в самый верх:**
   ```markdown
   <p align="center">
     <a href="https://lighchat.com">
       <img src="docs/branding/lighchat-banner.png" width="600" alt="LighChat — приватный мессенджер">
     </a>
   </p>

   <p align="center">
     <strong>Безопасный мессенджер с E2E-шифрованием, QR-мульти-девайс и HD-видеозвонками</strong>
   </p>

   <p align="center">
     <a href="https://github.com/ShpantsevVyacheslav/LighChat/stargazers"><img src="https://img.shields.io/github/stars/ShpantsevVyacheslav/LighChat?style=social" alt="GitHub stars"></a>
     <a href="https://github.com/ShpantsevVyacheslav/LighChat/blob/main/LICENSE"><img src="https://img.shields.io/github/license/ShpantsevVyacheslav/LighChat" alt="License"></a>
     <a href="https://lighchat.com"><img src="https://img.shields.io/badge/website-lighchat.com-blue" alt="Website"></a>
   </p>

   <p align="center">
     <a href="#quick-start">Быстрый старт</a> •
     <a href="#features">Функции</a> •
     <a href="#download">Скачать</a> •
     <a href="https://lighchat.com/docs">Документация</a> •
     <a href="#contributing">Contributing</a> •
     <a href="README.en.md">English</a>
   </p>
   ```

2. **Добавить ключевые слова в первый абзац:**
   ```markdown
   **LighChat** — это open-source мессенджер с end-to-end шифрованием, мульти-девайс синхронизацией через QR-код, HD-видеозвонками и кастомными темами чатов. Безопасная альтернатива WhatsApp и Telegram для iOS, Android, Windows, macOS, Linux и веба.
   ```

3. **Создать `README.en.md`** — английская версия для международной аудитории.

4. **Добавить `CONTRIBUTING.md`, `LICENSE`, `SECURITY.md`** — повышают «профессиональный» рейтинг GitHub.

5. **Settings → About** на GitHub — заполнить description и tags:
   - Description: `Secure messenger with E2E encryption, QR multi-device login, HD video calls. Alternative to WhatsApp and Telegram.`
   - Topics: `messenger`, `chat`, `e2e-encryption`, `webrtc`, `video-conferencing`, `flutter`, `nextjs`, `firebase`, `pwa`, `electron`, `qr-login`, `multi-device`, `privacy`, `secure-messaging`

---

## 10. `robots.txt` + `sitemap.xml`

### Создать `public/robots.txt`

```txt
User-agent: *
Allow: /
Disallow: /dashboard/
Disallow: /api/
Disallow: /_next/
Disallow: /auth/

User-agent: Yandex
Allow: /
Disallow: /dashboard/
Disallow: /api/
Disallow: /auth/

Sitemap: https://lighchat.com/sitemap.xml
Host: lighchat.com
```

### Создать `src/app/sitemap.ts` (Next.js native)

```ts
import type { MetadataRoute } from 'next';

export default function sitemap(): MetadataRoute.Sitemap {
  const base = 'https://lighchat.com';
  const lastModified = new Date();

  // Главная + локализованные версии
  const homePages = ['', '/ru', '/en', '/kk', '/uz', '/tr', '/id', '/pt-br', '/es-mx'].map((path) => ({
    url: `${base}${path}`,
    lastModified,
    changeFrequency: 'weekly' as const,
    priority: 1.0,
  }));

  // Фичи
  const featurePages = [
    '/features/encryption',
    '/features/multi-device',
    '/features/themes',
    '/features/calls',
  ].map((path) => ({
    url: `${base}${path}`,
    lastModified,
    changeFrequency: 'monthly' as const,
    priority: 0.8,
  }));

  // Блог (когда появится)
  // const blogPosts = await getBlogPosts(); // динамически

  return [...homePages, ...featurePages];
}
```

---

## 11. Smart App Banner и App Install Banner

### iOS Safari Smart App Banner (в `<head>`)

После публикации в App Store добавить в `src/app/layout.tsx → metadata.other`:

```tsx
other: {
  'apple-itunes-app': 'app-id=YOUR_APP_ID, app-argument=lighchat://',
}
```

→ Когда пользователь iPhone заходит на `lighchat.com` через Safari, видит баннер «Открыть в App Store».

### Android Chrome — через `manifest.json` + `prefer_related_applications: true`

Уже включено в манифест выше. Chrome автоматически предложит установить нативное приложение.

---

## 12. Точечные patch-предложения по приоритетам

### P0 — сделать в первую очередь (1–2 часа суммарно)

| Файл | Действие |
|---|---|
| `src/app/layout.tsx` | Расширить metadata: title, description с ключами, OpenGraph, Twitter, robots |
| `public/manifest.json` | Добавить categories, screenshots, lang, related_applications |
| `mobile/app/pubspec.yaml` | Заменить description с DEFAULT на маркетинговое |
| `mobile/app/web/manifest.json` | Заменить весь файл на корректный |
| `mobile/app/ios/Runner/Info.plist` | CFBundleDisplayName / CFBundleName → `LighChat` |
| `mobile/app/android/app/src/main/AndroidManifest.xml` | `android:label="@string/app_name"` |
| `mobile/app/android/app/src/main/res/values/strings.xml` | Создать с `app_name` |
| `public/robots.txt` | Создать |
| `src/app/sitemap.ts` | Создать |
| GitHub repo Settings | Заполнить description + topics |

### P1 — после P0 (3–6 часов)

| Файл | Действие |
|---|---|
| Локализованные `strings.xml` для Android (ru, en, kk, uz, tr, id, pt-rBR, es-rMX) | Создать |
| Локализованные `InfoPlist.strings` для iOS | Создать |
| `package.json` | Добавить keywords, description, homepage |
| `README.md` | Полировать с badges и SEO-структурой |
| `README.en.md` | Создать английскую версию |
| `src/app/page.tsx` | Добавить JSON-LD SoftwareApplication |
| OG images `public/og/og-1200x630.png` | Создать |

### P2 — позже

- Apple Smart App Banner — после публикации в App Store.
- Полная локализация лендинга (отдельные страницы `/ru`, `/en`, `/kk`).
- Блог `lighchat.com/blog` с SEO-статьями.
- Yandex.Webmaster verification + Google Search Console verification (вставить токены в `verification` поле metadata).

---

## 13. Куда вставлять ключи — резюме одной таблицей

| Ключевое слово (RU) | Файл/место |
|---|---|
| `мессенджер` | layout.tsx description, manifest.json description, README.md, OG description |
| `безопасный мессенджер` | layout.tsx title, manifest.json description, App Store keyword field |
| `шифрование` | layout.tsx keywords, JSON-LD description |
| `альтернатива WhatsApp` | layout.tsx description (sweet spot — высокий поиск 2026), README.md, OG description, блог-статьи |
| `мессенджер на нескольких устройствах` | layout.tsx keywords, OG description (USP) |
| `QR вход` / `qr login` | layout.tsx keywords, manifest.json, OG description |
| `видеозвонки` / `video calls` | layout.tsx keywords, JSON-LD applicationCategory |
| `приватный мессенджер` | layout.tsx description, App Store keyword field, manifest.json |
| `e2e шифрование` | layout.tsx keywords, JSON-LD description |
| `кастомные темы` | layout.tsx keywords, OG description |

> В одном поле (например, title 30 симв) — **только 2–3 главных ключа**. Остальные — распределяются по другим полям. Не перегружать одно место.

---

## 14. Чек-лист «как проверить, что ключи работают»

После внесения P0:

```bash
# Локально проверить корректность HTML-метатегов
npm run dev
# Открыть в браузере, View Source, искать <meta name="description">, <meta property="og:*">

# Проверить manifest.json
curl http://localhost:3000/manifest.json | jq

# Проверить robots.txt
curl http://localhost:3000/robots.txt

# Проверить sitemap
curl http://localhost:3000/sitemap.xml
```

После деплоя на `lighchat.com`:

- [ ] [PageSpeed Insights](https://pagespeed.web.dev/) → проверить SEO score (цель: ≥ 90)
- [ ] [Yandex Webmaster](https://webmaster.yandex.ru/) → добавить сайт, верифицировать, отправить sitemap
- [ ] [Google Search Console](https://search.google.com/search-console) → то же самое
- [ ] [Rich Results Test](https://search.google.com/test/rich-results) → проверить JSON-LD
- [ ] [Open Graph Debugger](https://www.opengraph.xyz/) → проверить превью при шаринге в TG/WA/X
- [ ] [Lighthouse](https://developer.chrome.com/docs/lighthouse/overview) → score SEO + Performance + Accessibility ≥ 90 каждый

После публикации в сторах:

- [ ] App Store Connect → ключевое слово field 100 символов оптимизирован
- [ ] Google Play Console → описание содержит ключи органично
- [ ] RuStore Console → метаданные на русском с ключами
- [ ] Внести `apple-itunes-app` мета в layout.tsx

---

## 15. Запрещённые практики (за это банят)

❌ **Keyword stuffing** в title или description — Google Play и App Store фильтруют такие приложения.  
❌ **Скрытый текст** (white-on-white, off-screen positioning) — Google Search Console предупредит и понизит ранг.  
❌ **Спам в `keywords` meta-теге** (200+ слов) — игнорируется Google, может вызвать понижение в Yandex.  
❌ **Использование чужих брендов** в keywords (`whatsapp competitor`) — допустимо как «alternative to WhatsApp», но не как название.  
❌ **Cloaking** (показывать поисковику одно, пользователю другое) — мгновенный бан.  

---

## 16. Если не хочешь делать вручную — приоритет минимум

Если только 30 минут на ASO/SEO в 1-ю неделю:

1. **`mobile/app/pubspec.yaml`** — заменить `"A new Flutter project."` на нормальное description (5 минут)
2. **`mobile/app/web/manifest.json`** — заменить DEFAULT (5 минут)
3. **`src/app/layout.tsx`** — расширить metadata минимально (10 минут)
4. **`public/manifest.json`** — добавить categories (5 минут)
5. **GitHub repo Settings → About** — description + topics (5 минут)

Это даст ~70% эффекта от полного списка.

---

> ⏭ **Связанные документы:**
> - [aso-keywords-recommendations.md](aso-keywords-recommendations.md) — готовые строки для сторов
> - [bootstrap-plan-90d.md](bootstrap-plan-90d.md) — куда встраивается этот SEO-слой в общий план
> - [mobile-ua-strategy.md](mobile-ua-strategy.md) — связка SEO с UA
