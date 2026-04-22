import { NextResponse } from 'next/server';
import { analyzeIceServers, buildServerIcePayload } from '@/lib/webrtc-ice-server-side';

/**
 * Диагностика WebRTC ICE-конфигурации.
 *
 * Возвращает не только источник (`metered` vs `fallback-stun`), но и:
 *   - разбивку транспортов (stun/stuns/turn/turns);
 *   - флаги `hasTurn`/`hasTurns` — без них симметричный NAT переборется не будет;
 *   - `warning`, если набор STUN-only (UI может показать баннер админу).
 *
 * Без аутентификации — содержимое не раскрывает credentials Metered,
 * только метаданные по транспортам.
 */
export async function GET() {
  const payload = await buildServerIcePayload();
  const hasMeteredEnv = Boolean(process.env.METERED_DOMAIN?.trim() && process.env.METERED_API_KEY?.trim());
  const transports = analyzeIceServers(payload.iceServers);
  const warning =
    !transports.hasTurn && !transports.hasTurns
      ? 'no_turn_available'
      : null;

  return NextResponse.json(
    {
      ok: true,
      source: payload.source,
      reason: payload.reason || null,
      hasMeteredEnv,
      iceServerCount: payload.iceServers.length,
      transports,
      hasTurn: transports.hasTurn,
      hasTurns: transports.hasTurns,
      warning,
    },
    {
      status: 200,
      headers: { 'Cache-Control': 'no-store' },
    },
  );
}
