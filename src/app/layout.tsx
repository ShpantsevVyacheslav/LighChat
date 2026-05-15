import type {Metadata, Viewport} from 'next';
import { headers } from 'next/headers';
import './globals.css';
import { Toaster } from "@/components/ui/toaster"
import { Providers } from '@/components/providers';
import { cn } from '@/lib/utils';
import { FirebaseClientProvider } from '@/firebase/client-provider';
import { ThemeProvider } from '@/components/theme-provider';
import { AnalyticsProvider } from '@/components/analytics/AnalyticsProvider';
import { CookieBanner } from '@/components/landing/cookie-banner';
import { Inter, Space_Grotesk, Outfit } from 'next/font/google';

/** Локальная выдача шрифтов (без fonts.googleapis.com) — снимает таймауты в сетях без доступа к Google. */
const fontInter = Inter({
  subsets: ['latin', 'cyrillic'],
  variable: '--font-inter',
  display: 'swap',
  weight: ['400', '500', '600', '700'],
});

const fontSpaceGrotesk = Space_Grotesk({
  subsets: ['latin'],
  variable: '--font-space-grotesk',
  display: 'swap',
  weight: ['400', '500', '700'],
  /** Не все страницы используют шрифт сразу — убирает предупреждение preload в консоли. */
  preload: false,
});

const fontOutfit = Outfit({
  subsets: ['latin'],
  variable: '--font-outfit',
  display: 'swap',
  weight: ['700', '800'],
  preload: false,
});

const SITE_URL = 'https://lighchat.online';
const SITE_TITLE = 'LighChat — безопасный мессенджер с шифрованием и QR-входом';
const SITE_DESCRIPTION =
  'LighChat — приватный мессенджер с E2E-шифрованием, мульти-девайс через QR-код, аудио и видеозвонками, видеоконференциями, играми в чате и секретными чатами. Альтернатива WhatsApp и Telegram. Бесплатно для iOS, Android, Web и Desktop.';
const SITE_DESCRIPTION_SHORT =
  'Приватный мессенджер с E2E-шифрованием. Мульти-девайс через QR. Звонки, видеоконференции, игры, секретные чаты. Бесплатно.';

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: {
    default: SITE_TITLE,
    template: '%s | LighChat',
  },
  description: SITE_DESCRIPTION,
  keywords: [
    'мессенджер',
    'безопасный мессенджер',
    'приватный мессенджер',
    'мессенджер с шифрованием',
    'альтернатива whatsapp',
    'альтернатива telegram',
    'видеозвонки',
    'аудиозвонки',
    'видеоконференции',
    'видеовстречи онлайн',
    'видеоконференция бесплатно',
    'e2e шифрование',
    'секретные чаты',
    'игры в чате',
    'мессенджер с играми',
    'мессенджер на нескольких устройствах',
    'qr вход',
    'мульти-девайс мессенджер',
    'кастомные темы чатов',
    'дурак онлайн',
    'messenger',
    'private messenger',
    'secure messaging',
    'encrypted chat',
    'secret chats',
    'in-chat games',
    'video conferencing',
    'video meetings',
    'free video conference',
    'whatsapp alternative',
    'telegram alternative',
    'multi device messenger',
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
      'ru-RU': SITE_URL,
      'en-US': SITE_URL,
      'x-default': SITE_URL,
    },
  },
  openGraph: {
    type: 'website',
    locale: 'ru_RU',
    alternateLocale: ['en_US'],
    url: SITE_URL,
    siteName: 'LighChat',
    title: SITE_TITLE,
    description: SITE_DESCRIPTION_SHORT,
    /** Картинка предоставляется через `src/app/opengraph-image.tsx` (динамическая генерация). */
  },
  twitter: {
    card: 'summary_large_image',
    site: '@lighchat',
    creator: '@lighchat',
    title: SITE_TITLE,
    description: SITE_DESCRIPTION_SHORT,
    /** Картинка предоставляется через `src/app/twitter-image.tsx` (если нужна отдельная) — пока используется OG-картинка. */
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
  /** Вкладка: прозрачный фавикон (`favicon-*.png`). Рабочий стол / PWA: `manifest` и apple-touch — знак с белым полем ~18% (`scripts/shrink-pwa-icon.mjs`). Сборка: `npm run brand:mark` / `npm run icons:pwa`. */
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
};

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
  /** iPhone «чёлка» / PWA: вьюпорт на весь экран, иначе сверху чёрная полоса вместо фона. */
  viewportFit: 'cover',
  themeColor: '#0a0e17', // Matches background for status bar blending
};

export default async function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  // SECURITY: per-request nonce set by src/middleware.ts. Both inline script
  // helpers and next-themes' bootstrap script must carry this nonce so they
  // remain executable under our `script-src 'self' 'nonce-XXX' 'strict-dynamic'`.
  // If middleware didn't run (e.g. a path excluded by its matcher), we fall
  // back to undefined — the script tags below render without the attribute,
  // and only `script-src 'self'` applies.
  // [next 15] headers() теперь async — RSC должен быть async-функцией.
  const nonce = (await headers()).get('x-nonce') ?? undefined;
  return (
    <html
      lang="ru"
      suppressHydrationWarning
      className={cn(fontInter.variable, fontSpaceGrotesk.variable, fontOutfit.variable)}
    >
      <head>
        {/** JSON-LD: SoftwareApplication schema для rich-snippets в Google. */}
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{
            __html: JSON.stringify({
              '@context': 'https://schema.org',
              '@type': 'SoftwareApplication',
              name: 'LighChat',
              applicationCategory: 'CommunicationApplication',
              operatingSystem: 'iOS, Android, Windows, macOS, Linux, Web',
              description:
                'Приватный мессенджер с E2E-шифрованием, мульти-девайс через QR, аудио и видеозвонками, видеоконференциями, играми в чате и секретными чатами. Альтернатива WhatsApp и Telegram.',
              url: SITE_URL,
              offers: {
                '@type': 'Offer',
                price: '0',
                priceCurrency: 'RUB',
              },
              publisher: {
                '@type': 'Organization',
                name: 'LighChat',
                url: SITE_URL,
              },
              featureList: [
                'End-to-end encryption',
                'QR multi-device login',
                'Audio and video calls',
                'Video conferencing (meetings)',
                'Secret chats',
                'In-chat games',
                'Custom chat themes',
                'Cross-platform (iOS, Android, Web, Desktop)',
              ],
            }),
          }}
        />
        {/* Automatic recovery from ChunkLoadError. Externalised to a self-
            hosted file so we don't need 'unsafe-inline' just for this snippet. */}
        <script src="/chunk-recovery.js" nonce={nonce} async />
      </head>
      <body className={cn("font-body antialiased", "min-h-screen bg-background")}>
        <ThemeProvider
          attribute="class"
          defaultTheme="dark"
          enableSystem={false}
          themes={['light', 'dark', 'chat']}
          disableTransitionOnChange
          nonce={nonce}
        >
          <FirebaseClientProvider>
            <AnalyticsProvider>
              <Providers>
                {children}
              </Providers>
              {/* Cookie consent — глобально на всех страницах, не только
                  landing. Без consent='all' 95% событий аналитики
                  молча дропается (см. analytics/index.ts → ALWAYS_SERVER_EVENTS).
                  Сам баннер показывает себя только при пустом
                  localStorage `lc_cookie_consent_v1`, поэтому overhead
                  на уже залогиненных юзеров нулевой. */}
              <CookieBanner />
            </AnalyticsProvider>
          </FirebaseClientProvider>
          <Toaster />
        </ThemeProvider>
      </body>
    </html>
  );
}
