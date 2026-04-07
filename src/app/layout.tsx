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
});

const fontMontserrat = Montserrat({
  subsets: ['latin', 'cyrillic'],
  variable: '--font-montserrat',
  display: 'swap',
  weight: ['600', '700'],
});

export const metadata: Metadata = {
  title: 'LighChat',
  description: 'Messenger & Video Conferencing',
  /** Вкладка: прозрачный фавикон (`favicon-*.png`). Рабочий стол / PWA: `manifest` и apple-touch — знак с белым полем ~18% (`scripts/shrink-pwa-icon.mjs`). Сборка: `npm run brand:mark` / `npm run icons:pwa`. */
  icons: {
    icon: [
      { url: '/pwa/favicon-192.png', sizes: '192x192', type: 'image/png' },
      { url: '/pwa/favicon-512.png', sizes: '512x512', type: 'image/png' },
    ],
    apple: [{ url: '/apple-touch-icon.png', sizes: '180x180', type: 'image/png' }],
  },
  applicationName: 'LighChat',
  manifest: '/manifest.json',
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
