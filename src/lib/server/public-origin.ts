// SECURITY: helper for resolving the canonical public origin of an inbound
// request. OAuth flows in particular MUST NOT trust X-Forwarded-Host
// unconditionally — an attacker who controls a CDN edge or who can spoof the
// header can steer `redirect_uri` to their own host and steal authorization
// codes / custom tokens (a classic Host-header injection takeover).
//
// Resolution order:
//   1. LIGHCHAT_PUBLIC_ORIGIN env (operator-controlled, trusted) — fixed.
//   2. X-Forwarded-Host, but ONLY if its origin is in the static allow-list.
//   3. request.nextUrl.origin — Next's parsed view of the request URL.

import type { NextRequest } from 'next/server';

const STATIC_ALLOWED_ORIGINS = new Set<string>([
  'https://lighchat.online',
  'https://www.lighchat.online',
  'https://project-72b24.web.app',
  'https://project-72b24.firebaseapp.com',
  // Local dev — only matters when running against a local Yandex OAuth app.
  'http://localhost:3000',
  'http://localhost:3434',
]);

function envPublicOrigin(): string | null {
  const raw = (process.env.LIGHCHAT_PUBLIC_ORIGIN ?? '').trim();
  if (!raw) return null;
  try {
    const u = new URL(raw);
    return `${u.protocol}//${u.host}`;
  } catch {
    return null;
  }
}

/**
 * Returns the canonical https origin to use when constructing OAuth
 * redirect_uri values, password-reset links, etc. Prefer the env var; only
 * fall back to forwarded headers if the value matches a static allow-list.
 */
export function resolvePublicOrigin(request: NextRequest): string {
  const fromEnv = envPublicOrigin();
  if (fromEnv && STATIC_ALLOWED_ORIGINS.has(fromEnv)) return fromEnv;
  if (fromEnv) return fromEnv; // operator explicitly set a non-listed origin — trust it

  const fwdHost = request.headers.get('x-forwarded-host');
  const fwdProto = request.headers.get('x-forwarded-proto');
  if (fwdHost) {
    const proto = (fwdProto?.split(',')[0]?.trim() || 'https').toLowerCase();
    const host = fwdHost.split(',')[0].trim().toLowerCase();
    const candidate = `${proto}://${host}`;
    if (STATIC_ALLOWED_ORIGINS.has(candidate)) return candidate;
    // Forwarded host did not match the allow-list — refuse it. Falling through
    // to nextUrl.origin is safer than honoring an attacker-supplied header.
  }

  return request.nextUrl.origin;
}
