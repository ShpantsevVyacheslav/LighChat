// SECURITY: shared helpers for App Router route handlers (src/app/api/**).
//
// Without these, /api/* routes were anonymous proxies that any unauthenticated
// site could hit:
//   - /api/giphy/search burned the project's GIPHY quota for any visitor on
//     any domain (DoS on billing).
//   - /api/webrtc/ice handed out paid Metered TURN credentials to anyone (a
//     free relay service for the open internet).
// Even with App Check at the Firestore/Functions layer, these REST routes
// don't go through callable, so they need their own gate. The pattern is:
//
//     const auth = await requireUserFromRequest(req);
//     if (!auth.ok) return auth.response;
//     const rl = await consumeRouteRateLimit(...);
//     if (!rl.allowed) return new NextResponse(null, { status: 429 });
//
// We trust the Bearer ID token (verifyIdToken on the Admin SDK side); the
// caller is whoever Firebase Auth says it is.

import { NextRequest, NextResponse } from 'next/server';

import { adminAuth } from '@/firebase/admin';

export type RouteAuthOk = {
  ok: true;
  uid: string;
  email: string | null;
};
export type RouteAuthFail = {
  ok: false;
  response: NextResponse;
};

function unauthorized(): NextResponse {
  return NextResponse.json(
    { ok: false, error: 'unauthorized' },
    { status: 401, headers: { 'WWW-Authenticate': 'Bearer realm="lighchat"' } },
  );
}

/**
 * Extract and verify a Firebase ID token from the Authorization header.
 * Returns either the trusted identity or a 401 response that the route
 * handler should return verbatim.
 */
export async function requireUserFromRequest(
  request: NextRequest,
): Promise<RouteAuthOk | RouteAuthFail> {
  const auth = request.headers.get('authorization') ?? request.headers.get('Authorization');
  if (!auth || !auth.toLowerCase().startsWith('bearer ')) {
    return { ok: false, response: unauthorized() };
  }
  const token = auth.slice(7).trim();
  if (!token || token.length < 16) {
    return { ok: false, response: unauthorized() };
  }
  try {
    const decoded = await adminAuth.verifyIdToken(token);
    return {
      ok: true,
      uid: decoded.uid,
      email: typeof decoded.email === 'string' ? decoded.email : null,
    };
  } catch {
    return { ok: false, response: unauthorized() };
  }
}

/**
 * Best-effort caller IP for rate-limit keys. App Hosting / Cloud Run sit
 * behind Google's frontend, so we trust the leftmost X-Forwarded-For.
 */
export function callerIpFromRequest(request: NextRequest): string {
  const xff = request.headers.get('x-forwarded-for');
  if (xff) {
    const first = xff.split(',')[0]?.trim();
    if (first) return first;
  }
  const real = request.headers.get('x-real-ip');
  if (real) return real.trim();
  // NextRequest doesn't expose the raw remote address at the edge runtime;
  // fall through to a constant so we still rate-limit globally.
  return 'unknown';
}
