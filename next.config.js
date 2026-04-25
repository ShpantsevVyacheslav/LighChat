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
        ],
      },
    ];
  },
  typescript: {
    ignoreBuildErrors: false,
  },
  eslint: {
    ignoreDuringBuilds: false,
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