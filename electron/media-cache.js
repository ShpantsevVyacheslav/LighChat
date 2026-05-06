const { app, ipcMain, net } = require('electron');
const path = require('path');
const fs = require('fs');
const fsp = require('fs/promises');
const crypto = require('crypto');
const dns = require('dns/promises');

const CHANNEL_GET_CACHED_MEDIA_URL = 'media-cache:getCachedMediaUrl';
const MEDIA_PROTOCOL_SCHEME = 'lighchat-media';
const inFlightCache = new Map();

// SECURITY hardening for SSRF and resource exhaustion. The IPC handler at the
// bottom of this file runs in the privileged main process with system cookies,
// proxy and auth — anything it fetches happens "as the user". An attacker that
// landed XSS in the renderer would otherwise pivot through this channel to
// internal services (cloud metadata at 169.254.169.254, LAN devices, etc.) or
// flood the disk. The constants below define the allow-list and limits.
const ALLOWED_RENDERER_ORIGINS = new Set([
  'http://localhost:3000', // dev
  'http://localhost:3434', // bundled-Next prod
]);
const ALLOWED_REMOTE_HOST_SUFFIXES = [
  '.firebasestorage.googleapis.com',
  '.googleusercontent.com',
  '.firebasestorage.app',
  '.appspot.com',
];
// Exact hosts (not suffixes — beware that ".firebasestorage.googleapis.com"
// suffix would match "evil.firebasestorage.googleapis.com" only because the
// leading dot guarantees a real subdomain boundary; same for the others).
const ALLOWED_REMOTE_HOSTS_EXACT = new Set([
  'firebasestorage.googleapis.com',
]);
const MAX_RESPONSE_BYTES = 100 * 1024 * 1024; // 100 MB
const REQUEST_TIMEOUT_MS = 30_000;
const ALLOWED_CONTENT_TYPE_PREFIXES = ['image/', 'video/', 'audio/'];

function sha256Hex(input) {
  return crypto.createHash('sha256').update(String(input)).digest('hex');
}

function guessExtensionFromContentType(contentType) {
  const ct = String(contentType || '').split(';')[0].trim().toLowerCase();
  if (ct === 'image/jpeg') return 'jpg';
  if (ct === 'image/png') return 'png';
  if (ct === 'image/webp') return 'webp';
  if (ct === 'image/gif') return 'gif';
  if (ct === 'video/mp4') return 'mp4';
  if (ct === 'video/webm') return 'webm';
  return null;
}

function toMediaProtocolUrl(filePath) {
  const normalized = path.resolve(filePath);
  return `${MEDIA_PROTOCOL_SCHEME}://local/${encodeURIComponent(normalized)}`;
}

function isHostnameInAllowlist(hostname) {
  const h = String(hostname || '').toLowerCase();
  if (!h) return false;
  if (ALLOWED_REMOTE_HOSTS_EXACT.has(h)) return true;
  return ALLOWED_REMOTE_HOST_SUFFIXES.some((suffix) => h.endsWith(suffix));
}

/**
 * Block private/loopback/link-local/multicast/reserved IPs to defeat DNS
 * rebinding and direct-IP SSRF. Covers both IPv4 and IPv6 (including
 * IPv4-mapped IPv6 like ::ffff:10.0.0.1).
 */
function isPrivateIp(addr, family) {
  if (!addr) return true;
  if (family === 4) {
    const parts = addr.split('.').map((n) => parseInt(n, 10));
    if (parts.length !== 4 || parts.some((n) => Number.isNaN(n) || n < 0 || n > 255)) return true;
    const [a, b] = parts;
    if (a === 10) return true;
    if (a === 127) return true;
    if (a === 0) return true;
    if (a === 169 && b === 254) return true; // link-local + cloud metadata
    if (a === 172 && b >= 16 && b <= 31) return true;
    if (a === 192 && b === 168) return true;
    if (a === 100 && b >= 64 && b <= 127) return true; // CG-NAT
    if (a >= 224) return true; // multicast + reserved
    return false;
  }
  // IPv6
  const lower = String(addr).toLowerCase();
  if (lower === '::1' || lower === '::') return true;
  if (lower.startsWith('fe80:') || lower.startsWith('fe80::')) return true;
  if (/^f[cd][0-9a-f]{2}:/.test(lower)) return true; // fc00::/7 unique-local
  if (lower.startsWith('ff')) return true; // multicast
  // IPv4-mapped: ::ffff:a.b.c.d  → check inner v4
  const mapped = lower.match(/^::ffff:([0-9.]+)$/);
  if (mapped) return isPrivateIp(mapped[1], 4);
  return false;
}

async function assertResolvesToPublicIp(hostname) {
  // Resolve all A/AAAA records and reject if ANY is private. This collapses
  // the DNS-rebinding window: if the host has even one suspect record, fail.
  const results = await dns.lookup(hostname, { all: true, verbatim: true });
  if (!Array.isArray(results) || results.length === 0) {
    throw new Error('DNS_NO_ANSWER');
  }
  for (const r of results) {
    if (isPrivateIp(r.address, r.family)) {
      throw new Error(`PRIVATE_IP:${r.address}`);
    }
  }
}

function isAllowedRendererSender(event) {
  try {
    const frame = event && event.senderFrame;
    if (!frame || !frame.url) return false;
    const url = new URL(frame.url);
    return ALLOWED_RENDERER_ORIGINS.has(`${url.protocol}//${url.host}`);
  } catch {
    return false;
  }
}

async function ensureDir(dirPath) {
  await fsp.mkdir(dirPath, { recursive: true });
}

async function statIfExists(filePath) {
  try {
    return await fsp.stat(filePath);
  } catch {
    return null;
  }
}

async function downloadToFile(url, targetPath) {
  await ensureDir(path.dirname(targetPath));

  return new Promise((resolve, reject) => {
    let settled = false;
    const settleReject = (err) => {
      if (settled) return;
      settled = true;
      try { request.abort(); } catch { /* ignore */ }
      reject(err);
    };
    const settleResolve = (val) => {
      if (settled) return;
      settled = true;
      resolve(val);
    };

    const request = net.request({
      url,
      method: 'GET',
      // SECURITY: do not follow redirects automatically — every hop must be
      // re-validated against the host allowlist + public-IP rule. We expose a
      // 'redirect' event hook below to cancel manually.
      redirect: 'manual',
    });
    const timeout = setTimeout(() => settleReject(new Error('REQUEST_TIMEOUT')), REQUEST_TIMEOUT_MS);
    const clearTimer = () => clearTimeout(timeout);

    request.on('redirect', () => {
      // Refuse redirects entirely; the renderer should ask for the final URL.
      settleReject(new Error('REDIRECT_BLOCKED'));
    });

    request.on('response', (response) => {
      if ((response.statusCode || 0) >= 400) {
        settleReject(new Error(`HTTP ${response.statusCode} for ${url}`));
        return;
      }

      // Validate content-type early.
      const ct = String(response.headers['content-type'] || '').split(';')[0].trim().toLowerCase();
      const isAllowedCt = ALLOWED_CONTENT_TYPE_PREFIXES.some((p) => ct.startsWith(p));
      if (!isAllowedCt) {
        settleReject(new Error(`CONTENT_TYPE_BLOCKED:${ct || 'unknown'}`));
        return;
      }

      // Honor Content-Length if present.
      const declaredLen = parseInt(String(response.headers['content-length'] || ''), 10);
      if (!Number.isNaN(declaredLen) && declaredLen > MAX_RESPONSE_BYTES) {
        settleReject(new Error(`RESPONSE_TOO_LARGE:${declaredLen}`));
        return;
      }

      const tmpPath = `${targetPath}.tmp.${process.pid}.${Date.now()}.${Math.random().toString(16).slice(2)}`;
      const fileStream = fs.createWriteStream(tmpPath);
      let receivedBytes = 0;
      const cleanupTmp = () => { void fsp.unlink(tmpPath).catch(() => {}); };
      const rejectAndCleanup = (error) => {
        cleanupTmp();
        settleReject(error);
      };
      response.on('error', rejectAndCleanup);
      fileStream.on('error', rejectAndCleanup);

      response.on('data', (chunk) => {
        receivedBytes += chunk.length;
        if (receivedBytes > MAX_RESPONSE_BYTES) {
          rejectAndCleanup(new Error(`RESPONSE_TOO_LARGE:${receivedBytes}`));
          try { response.destroy(); } catch { /* ignore */ }
        }
      });

      response.pipe(fileStream);
      fileStream.on('finish', async () => {
        clearTimer();
        try {
          await fsp.rename(tmpPath, targetPath);
          settleResolve({
            contentType: response.headers['content-type'],
          });
        } catch (e) {
          cleanupTmp();
          settleReject(e);
        }
      });
    });
    request.on('error', (e) => { clearTimer(); settleReject(e); });
    request.end();
  });
}

async function getCachePaths(remoteUrl) {
  const baseDir = path.join(app.getPath('userData'), 'media-cache');
  const key = sha256Hex(remoteUrl);
  const metaPath = path.join(baseDir, `${key}.json`);
  const defaultPath = path.join(baseDir, `${key}.bin`);
  return { baseDir, key, metaPath, defaultPath };
}

async function readMeta(metaPath) {
  try {
    const raw = await fsp.readFile(metaPath, 'utf8');
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

async function writeMeta(metaPath, meta) {
  await ensureDir(path.dirname(metaPath));
  await fsp.writeFile(metaPath, JSON.stringify(meta), 'utf8');
}

async function cacheRemoteUrl(remoteUrl, metaPath, defaultPath) {
  const result = await downloadToFile(remoteUrl, defaultPath);
  const ext = guessExtensionFromContentType(result?.contentType);
  const finalPath = ext ? defaultPath.replace(/\.bin$/, `.${ext}`) : defaultPath;

  if (finalPath !== defaultPath) {
    try {
      await fsp.rename(defaultPath, finalPath);
    } catch {
      // keep .bin if rename fails
    }
  }

  await writeMeta(metaPath, {
    remoteUrl,
    filePath: finalPath,
    cachedAt: Date.now(),
    contentType: result?.contentType || null,
  });

  return finalPath;
}

ipcMain.handle(CHANNEL_GET_CACHED_MEDIA_URL, async (event, remoteUrl) => {
  // SECURITY: reject calls from unknown frames. Without this, a navigated /
  // popped-up frame (or webview) inside Electron could pivot through this
  // privileged channel.
  if (!isAllowedRendererSender(event)) return null;

  if (!remoteUrl || typeof remoteUrl !== 'string') return null;
  if (remoteUrl.length > 4096) return null;

  let parsed;
  try {
    parsed = new URL(remoteUrl);
  } catch {
    return null;
  }
  // Force HTTPS — we do not cache plaintext media in the privileged main proc.
  if (parsed.protocol !== 'https:') return null;
  if (!isHostnameInAllowlist(parsed.hostname)) return null;

  // DNS-resolve and reject anything resolving to private IPs (defeats DNS
  // rebinding and SSRF via attacker-controlled DNS for a whitelisted host).
  try {
    await assertResolvesToPublicIp(parsed.hostname);
  } catch {
    return null;
  }

  const { metaPath, defaultPath } = await getCachePaths(remoteUrl);

  const existingMeta = await readMeta(metaPath);
  if (existingMeta?.filePath) {
    const s = await statIfExists(existingMeta.filePath);
    if (s?.isFile()) return toMediaProtocolUrl(existingMeta.filePath);
  }

  // If meta is missing, still try the default path.
  const defaultStat = await statIfExists(defaultPath);
  if (defaultStat?.isFile()) return toMediaProtocolUrl(defaultPath);

  let inFlight = inFlightCache.get(remoteUrl);
  if (!inFlight) {
    inFlight = cacheRemoteUrl(remoteUrl, metaPath, defaultPath);
    inFlightCache.set(remoteUrl, inFlight);
  }

  try {
    const finalPath = await inFlight;
    return toMediaProtocolUrl(finalPath);
  } catch (e) {
    console.warn('[media-cache] download rejected:', e && e.message);
    return null;
  } finally {
    if (inFlightCache.get(remoteUrl) === inFlight) {
      inFlightCache.delete(remoteUrl);
    }
  }
});

module.exports = {
  CHANNEL_GET_CACHED_MEDIA_URL,
  MEDIA_PROTOCOL_SCHEME,
};
