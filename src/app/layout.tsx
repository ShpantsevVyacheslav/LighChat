import type {Metadata, Viewport} from 'next';
import './globals.css';
import { Toaster } from "@/components/ui/toaster"
import { Providers } from '@/components/providers';
import { cn } from '@/lib/utils';
import { FirebaseClientProvider } from '@/firebase/client-provider';
import { ThemeProvider } from '@/components/theme-provider';
import { Inter, Space_Grotesk, Montserrat } from 'next/font/google';

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

const fontMontserrat = Montserrat({
  subsets: ['latin', 'cyrillic'],
  variable: '--font-montserrat',
  display: 'swap',
  weight: ['600', '700'],
  preload: false,
});

const SITE_URL = 'https://lighchat.online';
const SITE_TITLE = 'LighChat — безопасный мессенджер с шифрованием и QR-входом';
const SITE_DESCRIPTION =
  'LighChat — приватный мессенджер с E2E-шифрованием, мульти-девайс через QR-код, кастомными темами и HD-видеозвонками. Альтернатива WhatsApp и Telegram. Бесплатно для iOS, Android, Web и Desktop.';
const SITE_DESCRIPTION_SHORT =
  'Приватный мессенджер с E2E-шифрованием. Мульти-девайс через QR. HD-видеозвонки. Альтернатива WhatsApp и Telegram. Бесплатно.';

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
    images: [
      {
        url: '/og/og-1200x630.png',
        width: 1200,
        height: 630,
        alt: 'LighChat — безопасный мессенджер с шифрованием и QR-входом',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    site: '@lighchat',
    creator: '@lighchat',
    title: SITE_TITLE,
    description: SITE_DESCRIPTION_SHORT,
    images: ['/og/og-1200x630.png'],
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

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="ru"
      suppressHydrationWarning
      className={cn(fontInter.variable, fontSpaceGrotesk.variable, fontMontserrat.variable)}
    >
      <head>
        {/* Automatic recovery from ChunkLoadError */}
        <script
          dangerouslySetInnerHTML={{
            __html: `
              window.addEventListener('error', function(event) {
                if (event.message && (event.message.indexOf('ChunkLoadError') !== -1 || event.message.indexOf('Loading chunk') !== -1)) {
                  window.location.reload();
                }
              });
            `,
          }}
        />
      </head>
      <body className={cn("font-body antialiased", "min-h-screen bg-background")}>
        <ThemeProvider
          attribute="class"
          defaultTheme="dark"
          enableSystem={false}
          themes={['light', 'dark', 'chat']}
          disableTransitionOnChange
        >
          <FirebaseClientProvider>
            <Providers>
              {children}
            </Providers>
          </FirebaseClientProvider>
          <Toaster />
        </ThemeProvider>
      </body>
    </html>
  );
}
