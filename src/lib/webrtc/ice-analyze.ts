/**
 * Разбор набора `RTCIceServer` по транспортам — общий код для клиента и сервера.
 *
 * Вынесен из `webrtc-ice-server-side.ts`, чтобы клиентский путь
 * (`webrtc-ice-servers.ts`) тоже мог логировать разбивку без дублирования.
 *
 * `hasTurn`/`hasTurns` критичны: без relay-транспорта симметричный NAT
 * не пробивается, и пир будет крутиться в цикле disconnected/failed.
 */
export type IceTransportStats = {
  stun: number;
  stuns: number;
  turn: number;
  turns: number;
  hasStun: boolean;
  hasTurn: boolean;
  hasTurns: boolean;
};

export function analyzeIceServers(iceServers: RTCIceServer[]): IceTransportStats {
  const stats: IceTransportStats = {
    stun: 0, stuns: 0, turn: 0, turns: 0,
    hasStun: false, hasTurn: false, hasTurns: false,
  };
  for (const srv of iceServers) {
    const urls = typeof srv.urls === 'string' ? [srv.urls] : (srv.urls || []);
    for (const u of urls) {
      if (typeof u !== 'string') continue;
      const lower = u.toLowerCase();
      if (lower.startsWith('turns:')) stats.turns += 1;
      else if (lower.startsWith('turn:')) stats.turn += 1;
      else if (lower.startsWith('stuns:')) stats.stuns += 1;
      else if (lower.startsWith('stun:')) stats.stun += 1;
    }
  }
  stats.hasStun = stats.stun + stats.stuns > 0;
  stats.hasTurn = stats.turn > 0;
  stats.hasTurns = stats.turns > 0;
  return stats;
}
