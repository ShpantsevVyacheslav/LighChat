// SECURITY: route-handler rate limiter. Mirrors
// functions/src/lib/rate-limit.ts but lives on the web side so server-action
// + App Router routes can use it without dragging the functions package in.
//
// Same Firestore-backed sliding-window construction, same fail-open posture
// on Firestore failure (transient outage shouldn't take the route down).
// One-time setup: enable Firestore TTL on collection `rateLimits`, field
// `expireAt`. Same collection as the functions limiter — entries are
// disjoint by `key` so they don't collide.

import * as admin from 'firebase-admin';

import { adminDb } from '@/firebase/admin';

export type RouteRateLimitOptions = {
  key: string;
  limit: number;
  windowSec: number;
  ttlMultiplier?: number;
  failOpen?: boolean;
};

export type RouteRateLimitResult =
  | { allowed: true; remaining: number; resetAtMs: number }
  | { allowed: false; remaining: 0; resetAtMs: number; retryAfterSec: number };

function sanitizeDocId(key: string): string {
  const safe = key.replace(/[\/ ]/g, '_');
  if (safe.length <= 256) return safe;
  // Lazy require to keep crypto out of edge bundles when this file isn't used.
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const { createHash } = require('node:crypto') as typeof import('node:crypto');
  return createHash('sha256').update(safe).digest('hex');
}

export async function consumeRouteRateLimit(
  opts: RouteRateLimitOptions,
): Promise<RouteRateLimitResult> {
  const { key, limit, windowSec } = opts;
  const failOpen = opts.failOpen !== false;
  const ttlMultiplier = opts.ttlMultiplier ?? 4;
  const docId = sanitizeDocId(key);
  const ref = adminDb.collection('rateLimits').doc(docId);
  const nowMs = Date.now();
  const windowMs = windowSec * 1000;

  try {
    return await adminDb.runTransaction<RouteRateLimitResult>(async (tx) => {
      const snap = await tx.get(ref);
      const data = snap.exists ? snap.data() ?? {} : {};
      const startMs = typeof data.windowStartMs === 'number' ? data.windowStartMs : 0;
      const count = typeof data.count === 'number' ? data.count : 0;

      if (nowMs - startMs >= windowMs) {
        const expireAt = admin.firestore.Timestamp.fromMillis(
          nowMs + windowMs * ttlMultiplier,
        );
        tx.set(ref, { windowStartMs: nowMs, count: 1, expireAt });
        return { allowed: true, remaining: limit - 1, resetAtMs: nowMs + windowMs };
      }

      const resetAtMs = startMs + windowMs;
      if (count >= limit) {
        const retryAfterSec = Math.max(1, Math.ceil((resetAtMs - nowMs) / 1000));
        return { allowed: false, remaining: 0, resetAtMs, retryAfterSec };
      }
      tx.update(ref, { count: count + 1 });
      return { allowed: true, remaining: limit - 1 - count, resetAtMs };
    });
  } catch {
    if (failOpen) {
      return { allowed: true, remaining: limit, resetAtMs: nowMs + windowMs };
    }
    return {
      allowed: false,
      remaining: 0,
      resetAtMs: nowMs + windowMs,
      retryAfterSec: windowSec,
    };
  }
}
