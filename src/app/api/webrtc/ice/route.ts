import { NextResponse } from 'next/server';
import { buildServerIcePayload } from '@/lib/webrtc-ice-server-side';

export async function GET() {
  const payload = await buildServerIcePayload();
  return NextResponse.json(payload, {
    status: 200,
    headers: {
      'Cache-Control': payload.source === 'metered' ? 'private, max-age=30' : 'no-store',
    },
  });
}
