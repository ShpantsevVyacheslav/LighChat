import { NextResponse } from 'next/server';
import { buildServerIcePayload } from '@/lib/webrtc-ice-server-side';

export async function GET() {
  const payload = await buildServerIcePayload();
  const hasMeteredEnv = Boolean(process.env.METERED_DOMAIN?.trim() && process.env.METERED_API_KEY?.trim());

  return NextResponse.json(
    {
      ok: true,
      source: payload.source,
      reason: payload.reason || null,
      hasMeteredEnv,
      iceServerCount: payload.iceServers.length,
    },
    {
      status: 200,
      headers: { 'Cache-Control': 'no-store' },
    },
  );
}
