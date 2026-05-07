import { NextRequest, NextResponse } from 'next/server';
import { buildServerIcePayload } from '@/lib/webrtc-ice-server-side';
import { requireUserFromRequest } from '@/lib/server/route-auth';
import { consumeRouteRateLimit } from '@/lib/server/route-rate-limit';

export const runtime = 'nodejs';

export async function GET(req: NextRequest) {
  // SECURITY: hands out paid TURN credentials. Anonymous access turned this
  // into a free relay service for the public internet — anyone could grab
  // creds and bounce arbitrary traffic through Metered on our bill. Require
  // a Firebase ID token, and rate-limit per uid (callers cycle credentials
  // every ~hour; 12 req / 5 min is plenty for legitimate sessions).
  const auth = await requireUserFromRequest(req);
  if (!auth.ok) return auth.response;
  const rl = await consumeRouteRateLimit({
    key: `webrtc-ice:uid:${auth.uid}`,
    limit: 12,
    windowSec: 5 * 60,
  });
  if (!rl.allowed) {
    return NextResponse.json(
      { error: 'rate_limited' },
      { status: 429, headers: { 'Retry-After': String(rl.retryAfterSec) } },
    );
  }

  const payload = await buildServerIcePayload();
  return NextResponse.json(payload, {
    status: 200,
    headers: {
      'Cache-Control': payload.source === 'metered' ? 'private, max-age=30' : 'no-store',
    },
  });
}
