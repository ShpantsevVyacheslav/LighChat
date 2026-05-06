/** @type {import('next').NextConfig} */
const isDesktopBuild = process.env.LIGHCHAT_DESKTOP_BUILD === '1';

const nextConfig = {
  // Standalone даёт отдельный server bundle в `.next/standalone` — для Firebase
  // Web Frameworks это заметно уменьшает ZIP Cloud Function (см. deploy 408 при
  // загрузке ~100+ МБ). Desktop по-прежнему использует отдельный `distDir`.
  output: 'standalone',
  ...(isDesktopBuild ? { distDir: '.next-desktop' } : {}),
  /**
   * OAuth popup (Google gapi / Firebase signInWithPopup) вызывает window.close() в дочернем окне.
   * COOP: same-origin блокирует это и шумит в консоли. same-origin-allow-popups — рекомендуемый
   * компромисс для приложений с входом через всплывающее окно.
   */
  /**
   * Кэширование: Safari иначе может долго держать HTML документа, а `/_next/static/*`
   * при следующем деплое уже другие — смесь версий даёт долгую загрузку / Firestore-ошибки
   * до «Разработка → Очистить кэши». Правило для static — первым (первое совпадение в Next).
   */
  async headers() {
    return [
      {
        source: '/_next/static/:path*',
        headers: [
          {
            key: 'Cache-Control',
            value: 'public, max-age=31536000, immutable',
          },
        ],
      },
      {
        source: '/:path*',
        headers: [
          {
            key: 'Cross-Origin-Opener-Policy',
            value: 'same-origin-allow-popups',
          },
          {
            key: 'Cache-Control',
            value: 'no-store, max-age=0, must-revalidate',
          },
          // SECURITY: defense-in-depth response headers. Without these, an XSS
          // anywhere in the chat (e.g. via a future regression in DOMPurify)
          // has the maximum possible blast radius. We deliberately do NOT add
          // a strict Content-Security-Policy yet — the app still has inline
          // bootstrap scripts in layout.tsx and dynamic Tailwind styles, and
          // adding CSP without nonces would either neuter it (`unsafe-inline`)
          // or break the app. CSP is tracked separately in
          // docs/security-audit-2026-05-followups.md.
          {
            // Force browsers to honor server-declared Content-Type and never
            // sniff. Closes "image-served-as-script" and similar tricks.
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            // Block clickjacking by refusing to be framed by anyone. Prevents
            // a malicious site from iframing our app and overlaying a fake UI
            // to trick the user into actions on their real session.
            key: 'X-Frame-Options',
            value: 'DENY',
          },
          {
            // Lock the browser into HTTPS for two years; preload-eligible
            // configuration. Mitigates SSL-strip / first-visit downgrade.
            // Safe because we only ship over HTTPS in production; this header
            // is harmless on http://localhost during dev (browsers ignore it
            // for non-secure responses).
            key: 'Strict-Transport-Security',
            value: 'max-age=63072000; includeSubDomains; preload',
          },
          {
            // Don't leak the full referring URL (which often contains chat
            // ids, OAuth state, etc.) to third-party hosts. Keep origin only
            // for cross-site, full URL for same-site so analytics still work.
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin',
          },
          {
            // Default-deny powerful browser APIs we don't need globally.
            // Calls/meeting screens that DO use camera/microphone/display-
            // capture / geolocation are same-origin (`self`) and unaffected.
            // FLoC is killed by `interest-cohort=()`.
            key: 'Permissions-Policy',
            value:
              'camera=(self), microphone=(self), geolocation=(self), ' +
              'display-capture=(self), payment=(), usb=(), bluetooth=(), ' +
              'serial=(), midi=(), magnetometer=(), gyroscope=(), ' +
              'accelerometer=(), interest-cohort=()',
          },
        ],
      },
    ];
  },
  typescript: {
    ignoreBuildErrors: false,
  },
  // ESLint при `next build` валит сборку при любых Error-правилах; в проекте ещё много
  // legacy `any`/unused — пока чистим постепенно, не блокируем прод-сборку.
  // Локально/в CI: `npm run lint` и `npm run typecheck`.
  eslint: {
    ignoreDuringBuilds: true,
  },
  images: {
    dangerouslyAllowSVG: true,
    contentSecurityPolicy: "default-src 'self'; script-src 'none'; sandbox;",
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'api.dicebear.com',
        pathname: '/**',
      },
      {
        protocol: 'https',
        hostname: 'placehold.co',
      },
      {
        protocol: 'https',
        hostname: 'images.unsplash.com',
      },
      {
        protocol: 'https',
        hostname: 'picsum.photos',
      },
      {
        protocol: 'https',
        hostname: 'i.pravatar.cc',
      },
      {
        protocol: 'https',
        hostname: 'firebasestorage.googleapis.com',
      },
      {
        protocol: 'https',
        hostname: 'www.google.com',
        pathname: '/s2/favicons/**',
      },
    ],
  },
  webpack: (config) => {
    // Игнорируем модуль 'canvas', который Konva пытается импортировать.
    // Это стандартное решение для Next.js при использовании библиотек на базе Konva.
    config.externals = [...(config.externals || []), { canvas: 'canvas' }];
    return config;
  },
};

module.exports = nextConfig;