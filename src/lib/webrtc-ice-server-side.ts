const DEFAULT_STUN_SERVERS = ['stun:stun1.l.google.com:19302', 'stun:stun2.l.google.com:19302'];
const FETCH_TIMEOUT_MS = 5000;

export type IceConfigSource = 'metered' | 'fallback-stun';

export type ServerIcePayload = {
  iceServers: RTCIceServer[];
  source: IceConfigSource;
  reason?: string;
};

type MeteredIceServer = {
  urls?: string | string[];
  username?: string;
  credential?: string;
};

function normalizeMeteredDomain(raw: string | undefined): string | null {
  const candidate = raw?.trim();
  if (!candidate) return null;
  return candidate.replace(/^https?:\/\//, '').replace(/\/+$/, '');
}

function toIceServer(raw: unknown): RTCIceServer | null {
  if (!raw || typeof raw !== 'object') return null;
  const candidate = raw as MeteredIceServer;
  const urls = candidate.urls;

  if (typeof urls === 'string' && urls.trim()) {
    return {
      urls: urls.trim(),
      username: candidate.username,
      credential: candidate.credential,
    };
  }

  if (Array.isArray(urls)) {
    const parsedUrls = urls
      .filter((value): value is string => typeof value === 'string')
      .map((value) => value.trim())
      .filter(Boolean);

    if (parsedUrls.length > 0) {
      return {
        urls: parsedUrls,
        username: candidate.username,
        credential: candidate.credential,
      };
    }
  }

  return null;
}

function fallbackPayload(reason?: string): ServerIcePayload {
  return {
    iceServers: [{ urls: DEFAULT_STUN_SERVERS }],
    source: 'fallback-stun',
    reason,
  };
}

function parseIceServers(payload: unknown): RTCIceServer[] {
  if (Array.isArray(payload)) {
    return payload.map(toIceServer).filter((item): item is RTCIceServer => !!item);
  }

  if (payload && typeof payload === 'object') {
    const objectPayload = payload as { iceServers?: unknown; data?: unknown };
    if (Array.isArray(objectPayload.iceServers)) {
      return objectPayload.iceServers
        .map(toIceServer)
        .filter((item): item is RTCIceServer => !!item);
    }
    if (Array.isArray(objectPayload.data)) {
      return objectPayload.data.map(toIceServer).filter((item): item is RTCIceServer => !!item);
    }
  }

  return [];
}

async function fetchMeteredCredentials(
  domain: string,
  apiKey: string,
  signal: AbortSignal,
): Promise<{ ok: true; payload: unknown } | { ok: false; status: number; mode: 'query' | 'header' }> {
  const endpoint = new URL(`https://${domain}/api/v1/turn/credentials`);
  endpoint.searchParams.set('apiKey', apiKey);

  const queryAuth = await fetch(endpoint.toString(), {
    method: 'GET',
    cache: 'no-store',
    signal,
    headers: { Accept: 'application/json' },
  });

  if (queryAuth.ok) {
    return { ok: true, payload: (await queryAuth.json()) as unknown };
  }

  const headerAuth = await fetch(`https://${domain}/api/v1/turn/credentials`, {
    method: 'GET',
    cache: 'no-store',
    signal,
    headers: {
      Accept: 'application/json',
      'x-api-key': apiKey,
    },
  });

  if (headerAuth.ok) {
    return { ok: true, payload: (await headerAuth.json()) as unknown };
  }

  return {
    ok: false,
    status: queryAuth.status || headerAuth.status,
    mode: queryAuth.status ? 'query' : 'header',
  };
}

export async function buildServerIcePayload(): Promise<ServerIcePayload> {
  const domain = normalizeMeteredDomain(process.env.METERED_DOMAIN);
  const apiKey = process.env.METERED_API_KEY?.trim();

  if (!domain || !apiKey) {
    return fallbackPayload('missing_metered_env');
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);

  try {
    const upstream = await fetchMeteredCredentials(domain, apiKey, controller.signal);
    if (!upstream.ok) {
      if (upstream.status === 401) {
        console.warn('[webrtc/ice] Metered unauthorized. Check METERED_DOMAIN/METERED_API_KEY pairing.');
        return fallbackPayload('metered_unauthorized');
      }
      console.warn('[webrtc/ice] Metered response not ok:', upstream.status);
      return fallbackPayload(`metered_status_${upstream.status}`);
    }

    const json = upstream.payload;
    const iceServers = parseIceServers(json);

    if (iceServers.length === 0) {
      console.warn('[webrtc/ice] Metered returned empty credentials payload');
      return fallbackPayload('metered_empty_payload');
    }

    return {
      iceServers,
      source: 'metered',
    };
  } catch (err) {
    console.warn('[webrtc/ice] Metered fetch failed:', err);
    return fallbackPayload('metered_fetch_failed');
  } finally {
    clearTimeout(timeout);
  }
}
