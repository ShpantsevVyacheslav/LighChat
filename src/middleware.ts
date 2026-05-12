import { NextRequest, NextResponse } from 'next/server';

// SECURITY: per-request nonce + Content-Security-Policy. The recommended Next
// 14 pattern: middleware generates a fresh base64 nonce, sets it on the
// outgoing request (so server components can read it via headers()) AND on
// the response as the actual CSP header.
//
// Why CSP at all: even with DOMPurify and our other input sanitisation, an
// XSS regression somewhere in the chat or a compromised third-party script
// would otherwise have unrestricted access to IndexedDB (Firebase Auth ID
// tokens), localStorage and the FCM service-worker. CSP turns that single
// finding into "needs another bypass to do anything useful" — the standard
// defense-in-depth posture for an app that hosts user-generated HTML.
//
// We deliberately deploy CSP in REPORT-ONLY mode first (header
// `Content-Security-Policy-Report-Only`). That's enforced by browsers as
// "log violations to console / report-uri but don't block". The hosting
// headers in firebase.json / next.config.js still provide HSTS / nosniff /
// X-Frame-Options / Referrer-Policy / Permissions-Policy unconditionally.
//
// To switch to enforcement: change the header name to
// `Content-Security-Policy`. Do that only after observing the violation log
// for ~1 week — third-party libraries occasionally add new inline handlers
// in minor versions and we want to catch those before they become outages.

const CSP_REPORT_ONLY = true;

// Hosts we know we load script/connect/frame/img from. Keep this list small
// — every entry is attack surface. Anything new must be reviewed.
const SCRIPT_SRC_EXTERNAL = [
  'https://www.gstatic.com',           // Firebase JS SDK (compat & service-worker importScripts)
  'https://apis.google.com',           // Google sign-in / GIS
  'https://accounts.google.com',       // Google sign-in
  'https://telegram.org',              // Telegram Login Widget
  'https://oauth.telegram.org',
];
const CONNECT_SRC_EXTERNAL = [
  'https://*.googleapis.com',          // Firestore, Storage, Functions, GIS
  'https://*.firebaseio.com',          // RTDB
  'https://*.cloudfunctions.net',
  'https://*.run.app',                 // App Hosting / Cloud Run callable
  'https://identitytoolkit.googleapis.com',
  'https://securetoken.googleapis.com',
  'https://api.giphy.com',
  'wss://*.firebaseio.com',
  'wss://*.googleapis.com',
];
const IMG_SRC_EXTERNAL = [
  'https://api.dicebear.com',
  'https://*.googleusercontent.com',
  'https://firebasestorage.googleapis.com',
  'https://media.giphy.com',
  'https://*.giphy.com',
  'https://placehold.co',
  'https://images.unsplash.com',
  'https://picsum.photos',
  'https://i.pravatar.cc',
];
const FRAME_SRC_EXTERNAL = [
  'https://accounts.google.com',
  'https://*.firebaseapp.com',
  'https://oauth.telegram.org',
  'https://www.youtube.com',           // link previews / embeds
  'https://www.google.com',            // maps
];
const FRAME_ANCESTORS = "'none'";       // matches X-Frame-Options: DENY

/**
 * [audit H-009] Endpoint для CSP violation reports. См. src/app/api/csp-report/route.ts.
 * Браузер шлёт сюда POST с JSON-описанием каждого блокированного ресурса.
 * После наблюдения ~1 неделю — переключаем `CSP_REPORT_ONLY = false`.
 */
const CSP_REPORT_URI = '/api/csp-report';

function buildCsp(nonce: string): string {
  const sScript = ["'self'", `'nonce-${nonce}'`, "'strict-dynamic'", ...SCRIPT_SRC_EXTERNAL].join(' ');
  // 'strict-dynamic' lets nonce'd scripts load further scripts without each
  // CDN being whitelisted (Firebase compat is the main beneficiary). Modern
  // browsers ignore the host list when 'strict-dynamic' is present, but old
  // ones use it as a fallback — so we keep both.
  const sConnect = ["'self'", ...CONNECT_SRC_EXTERNAL].join(' ');
  const sImg = ["'self'", 'data:', 'blob:', ...IMG_SRC_EXTERNAL].join(' ');
  const sFrame = ["'self'", ...FRAME_SRC_EXTERNAL].join(' ');
  // Tailwind generates inline <style> via Next CSS pipeline; without
  // 'unsafe-inline' those break. Style XSS is much lower impact than script
  // XSS — accepting this trade-off until we move to constructable
  // stylesheets / static-only CSS.
  const sStyle = ["'self'", "'unsafe-inline'", 'https://fonts.googleapis.com'].join(' ');
  const sFont = ["'self'", 'data:', 'https://fonts.gstatic.com'].join(' ');
  // Media (audio for calls, video for chat attachments). The streaming proto
  // uses https + blob; deny everything else.
  const sMedia = ["'self'", 'blob:', 'data:', 'https://firebasestorage.googleapis.com', 'https://*.googleusercontent.com'].join(' ');
  const sWorker = ["'self'", 'blob:'].join(' ');
  // Object/embed: deny — used only by malware-loader patterns.
  const directives = [
    `default-src 'self'`,
    `script-src ${sScript}`,
    `script-src-elem ${sScript}`,
    `connect-src ${sConnect}`,
    `img-src ${sImg}`,
    `style-src ${sStyle}`,
    `style-src-elem ${sStyle}`,
    `font-src ${sFont}`,
    `frame-src ${sFrame}`,
    `media-src ${sMedia}`,
    `worker-src ${sWorker}`,
    `object-src 'none'`,
    `base-uri 'none'`,
    `form-action 'self'`,
    `frame-ancestors ${FRAME_ANCESTORS}`,
  ];
  // `upgrade-insecure-requests` действительный директив только в enforcing-mode.
  // В Report-Only браузер ругается «directive is ignored ...» и шумит в console.
  // Включим обратно когда CSP_REPORT_ONLY станет false.
  if (!CSP_REPORT_ONLY) directives.push(`upgrade-insecure-requests`);
  // [audit H-009] report-uri работает и в Report-Only, и в Enforce. Браузер
  // POSTит JSON с описанием violation на этот endpoint при каждом блоке.
  // report-to (новый Reporting API) пока не добавляем — Safari/Firefox ещё
  // не support'ят consistently. report-uri покрывает Chrome / Edge / Yandex /
  // Safari / Firefox современных версий.
  directives.push(`report-uri ${CSP_REPORT_URI}`);
  return directives.join('; ');
}

function generateNonce(): string {
  // Web Crypto is available in the edge runtime where Next middleware runs.
  const bytes = new Uint8Array(16);
  crypto.getRandomValues(bytes);
  // base64 encode without Buffer (not in edge runtime).
  let s = '';
  for (let i = 0; i < bytes.length; i++) s += String.fromCharCode(bytes[i]);
  return btoa(s);
}

export function middleware(request: NextRequest) {
  const nonce = generateNonce();
  const csp = buildCsp(nonce);

  // Pass nonce to server components via request header so layout.tsx can
  // read it through `headers().get('x-nonce')`.
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set('x-nonce', nonce);
  // Some Next internals look for this exact header name to inject nonce on
  // generated <script> / <link> tags (preload, RSC payload bootstrap).
  requestHeaders.set(
    CSP_REPORT_ONLY ? 'content-security-policy-report-only' : 'content-security-policy',
    csp,
  );

  const response = NextResponse.next({ request: { headers: requestHeaders } });
  response.headers.set(
    CSP_REPORT_ONLY ? 'Content-Security-Policy-Report-Only' : 'Content-Security-Policy',
    csp,
  );
  return response;
}

export const config = {
  // Skip static assets (Next caches them aggressively; the CSP wouldn't
  // change their behaviour anyway and per-request nonce defeats caching).
  // Also skip Next /_next assets and the public/ root files served at "/".
  // [audit H-009] api/csp-report тоже скипаем: endpoint принимает POST от
  // браузера с CSP violations и сам не загружает скрипты — CSP на нём
  // бессмысленна, а попадание endpoint'а под matcher создаёт цикл
  // self-reporting (violation от response endpoint'а → новый POST → ...).
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|manifest.json|sw.js|firebase-messaging-sw.js|chunk-recovery.js|brand|icons|pwa|api/csp-report).*)',
  ],
};
