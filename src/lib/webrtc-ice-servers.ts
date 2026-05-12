import { logger } from '@/lib/logger';
import { analyzeIceServers, type IceTransportStats } from '@/lib/webrtc/ice-analyze';

const DEFAULT_STUN_SERVERS = ['stun:stun1.l.google.com:19302', 'stun:stun2.l.google.com:19302'];
const ICE_CONFIG_FETCH_TIMEOUT_MS = 4000;
const ICE_CONFIG_CACHE_MS = 60_000;

type IceConfigResponse = {
  iceServers?: RTCIceServer[];
  source?: 'metered' | 'fallback-stun';
  reason?: string;
};

type IceHealthResponse = {
  source?: 'metered' | 'fallback-stun';
  reason?: string | null;
  hasMeteredEnv?: boolean;
  iceServerCount?: number;
};

let cachedIceConfig: { value: RTCConfiguration; expiresAt: number } | null = null;
let lastLoggedSource: string | null = null;

/**
 * Последняя посчитанная диагностика ICE-конфигурации.
 * Доступна через `getWebRtcIceDiagnostics()` — UI может прочитать `hasTurn`
 * и показать админу баннер, если TURN недоступен (тогда пиры за NAT не
 * соберутся, и это надо чинить в env, а не в коде).
 */
export type WebRtcIceDiagnostics = {
  source: string;
  reason?: string;
  serverCount: number;
  transports: IceTransportStats;
};
let lastDiagnostics: WebRtcIceDiagnostics | null = null;

export function getWebRtcIceDiagnostics(): WebRtcIceDiagnostics | null {
  return lastDiagnostics;
}

function parseTurnUrls(raw: string | undefined): string[] {
  if (!raw) return [];
  return raw
    .split(/[\s,;]+/)
    .map((value) => value.trim())
    .filter(Boolean);
}

function normalizeIceServer(raw: unknown): RTCIceServer | null {
  if (!raw || typeof raw !== 'object') return null;
  const candidate = raw as { urls?: unknown; username?: unknown; credential?: unknown };
  const urlsRaw = candidate.urls;

  let urls: string | string[] | undefined;
  if (typeof urlsRaw === 'string') {
    const trimmed = urlsRaw.trim();
    if (trimmed) urls = trimmed;
  } else if (Array.isArray(urlsRaw)) {
    const parsed = urlsRaw
      .filter((value): value is string => typeof value === 'string')
      .map((value) => value.trim())
      .filter(Boolean);
    if (parsed.length > 0) urls = parsed;
  }

  if (!urls) return null;

  const normalized: RTCIceServer = { urls };
  if (typeof candidate.username === 'string' && candidate.username.trim()) {
    normalized.username = candidate.username.trim();
  }
  if (typeof candidate.credential === 'string' && candidate.credential.trim()) {
    normalized.credential = candidate.credential.trim();
  }
  return normalized;
}

function getEnvTurnIceServers(): RTCIceServer[] {
  const turnUrls = parseTurnUrls(
    process.env.NEXT_PUBLIC_WEBRTC_TURN_URLS || process.env.NEXT_PUBLIC_WEBRTC_TURN_URL,
  );
  const turnUsername = process.env.NEXT_PUBLIC_WEBRTC_TURN_USERNAME?.trim();
  const turnCredential = process.env.NEXT_PUBLIC_WEBRTC_TURN_CREDENTIAL?.trim();

  if (turnUrls.length > 0 && turnUsername && turnCredential) {
    return [{
      urls: turnUrls,
      username: turnUsername,
      credential: turnCredential,
    }];
  }

  return [];
}

function fallbackIceConfig(): RTCConfiguration {
  return {
    iceServers: [{ urls: DEFAULT_STUN_SERVERS }, ...getEnvTurnIceServers()],
    iceCandidatePoolSize: 10,
  };
}

function logIceSource(source: string, reason: string | undefined, config: RTCConfiguration): void {
  const servers = config.iceServers || [];
  const transports = analyzeIceServers(servers);
  lastDiagnostics = {
    source,
    reason,
    serverCount: servers.length,
    transports,
  };

  const transportSummary = `stun=${transports.stun + transports.stuns} turn=${transports.turn} turns=${transports.turns}`;
  const sourceKey = `${source}|${transports.hasTurn}|${transports.hasTurns}`;
  if (lastLoggedSource === sourceKey) return;
  lastLoggedSource = sourceKey;

  if (!transports.hasTurn && !transports.hasTurns) {
    // Без TURN-relay пиры за симметричным NAT не соберутся — это самый частый
    // источник цикла «Connection failed» в проде.
    logger.warn(
      'webrtc-ice',
      `no TURN available — peers behind symmetric NAT will fail. source=${source} servers=${servers.length} (${transportSummary})`,
      reason ? { reason } : undefined,
    );
    return;
  }

  if (reason) {
    logger.debug('webrtc-ice', `source=${source} servers=${servers.length} (${transportSummary})`, { reason });
    return;
  }
  logger.debug('webrtc-ice', `source=${source} servers=${servers.length} (${transportSummary})`);
}

async function fetchIceConfigFromApi(): Promise<{ config: RTCConfiguration; source: string; reason?: string } | null> {
  if (typeof window === 'undefined') return null;
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), ICE_CONFIG_FETCH_TIMEOUT_MS);

  try {
    // SECURITY: /api/webrtc/ice now requires a Firebase ID token (paid TURN
    // creds were a free relay otherwise). Attach it; on anonymous flows
    // (no current user) the route 401s and we fall back to public STUN.
    const headers: Record<string, string> = { Accept: 'application/json' };
    try {
      const { getAuth } = await import('firebase/auth');
      const u = getAuth().currentUser;
      if (u) headers.Authorization = `Bearer ${await u.getIdToken()}`;
    } catch {
      // best-effort
    }
    const res = await fetch('/api/webrtc/ice', {
      method: 'GET',
      cache: 'no-store',
      signal: ctrl.signal,
      headers,
    });
    if (!res.ok) {
      logger.warn('webrtc-ice', `ICE API /api/webrtc/ice returned ${res.status}`);
      return null;
    }
    const payload = (await res.json()) as IceConfigResponse;
    const servers = Array.isArray(payload.iceServers)
      ? payload.iceServers.map(normalizeIceServer).filter((s): s is RTCIceServer => !!s)
      : [];
    if (servers.length === 0) {
      logger.warn('webrtc-ice', 'ICE API returned empty iceServers payload');
      return null;
    }
    return {
      config: { iceServers: servers, iceCandidatePoolSize: 10 },
      source: payload.source || 'api-unknown',
      reason: payload.reason,
    };
  } catch (err) {
    logger.warn('webrtc-ice', 'ICE API fetch failed', err);
    return null;
  } finally {
    clearTimeout(timer);
  }
}

async function fetchIceHealthHint(): Promise<void> {
  if (typeof window === 'undefined') return;
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), 2000);
  try {
    const res = await fetch('/api/webrtc/ice/health', {
      method: 'GET',
      cache: 'no-store',
      signal: ctrl.signal,
      headers: { Accept: 'application/json' },
    });
    if (!res.ok) return;
    const health = (await res.json()) as IceHealthResponse;
    logger.debug(
      'webrtc-ice',
      `health: source=${health.source || 'unknown'} reason=${health.reason || 'none'} env=${health.hasMeteredEnv ? 'set' : 'missing'} servers=${health.iceServerCount ?? 'n/a'}`,
    );
  } catch {
  } finally {
    clearTimeout(timer);
  }
}

export async function getWebRtcIceConfig(): Promise<RTCConfiguration> {
  const now = Date.now();
  if (cachedIceConfig && cachedIceConfig.expiresAt > now) {
    return cachedIceConfig.value;
  }

  const remote = await fetchIceConfigFromApi();
  const value = remote?.config || fallbackIceConfig();

  if (remote) {
    logIceSource(remote.source, remote.reason, value);
  } else {
    void fetchIceHealthHint();
    logIceSource('fallback-local', undefined, value);
  }

  cachedIceConfig = {
    value,
    expiresAt: now + ICE_CONFIG_CACHE_MS,
  };

  return value;
}
