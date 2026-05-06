// SECURITY: SSRF guard for Cloud Functions outbound fetches. Mirrors the
// web-side guard in src/lib/server/ssrf-guard.ts but lives here so functions
// don't depend on the Next package layout. Used wherever we fetch a URL that
// the client originally chose (attachment URLs, link previews, etc.).
//
// Without this check, a participant in a chat can post a message with
// `attachments[i].url = "http://169.254.169.254/computeMetadata/v1/..."` and
// our transcribe/transcode flow happily fetches GCP metadata using the
// Cloud Functions service-account context. That returns an OAuth bearer
// token capable of impersonating the function — full project takeover.

import { lookup as dnsLookupCb } from "node:dns";
import { promisify } from "node:util";

const dnsLookup = promisify(dnsLookupCb);

export class SsrfGuardError extends Error {
  readonly code: string;
  constructor(code: string, message?: string) {
    super(message ?? code);
    this.code = code;
    this.name = "SsrfGuardError";
  }
}

export function isPrivateIp(addr: string, family: number): boolean {
  if (!addr) return true;
  if (family === 4) {
    const parts = addr.split(".").map((n) => parseInt(n, 10));
    if (parts.length !== 4 || parts.some((n) => Number.isNaN(n) || n < 0 || n > 255)) return true;
    const [a, b] = parts;
    if (a === 10) return true;
    if (a === 127) return true;
    if (a === 0) return true;
    if (a === 169 && b === 254) return true;
    if (a === 172 && b >= 16 && b <= 31) return true;
    if (a === 192 && b === 168) return true;
    if (a === 100 && b >= 64 && b <= 127) return true;
    if (a >= 224) return true;
    return false;
  }
  const lower = String(addr).toLowerCase();
  if (lower === "::1" || lower === "::") return true;
  if (lower.startsWith("fe80:") || lower.startsWith("fe80::")) return true;
  if (/^f[cd][0-9a-f]{2}:/.test(lower)) return true;
  if (lower.startsWith("ff")) return true;
  const mapped = lower.match(/^::ffff:([0-9.]+)$/);
  if (mapped) return isPrivateIp(mapped[1], 4);
  return false;
}

export type AssertSafeUrlOptions = {
  allowedSchemes?: string[];
  allowedHostsExact?: Set<string>;
  allowedHostSuffixes?: string[];
};

/**
 * Allow-list for "media" URLs we fetch on the user's behalf — Firebase
 * Storage download URLs and Google's signed URLs. Anything else (Dropbox,
 * arbitrary CDNs, attacker-controlled hosts) is rejected.
 */
export const FIREBASE_MEDIA_HOSTS_EXACT = new Set<string>([
  "firebasestorage.googleapis.com",
  "storage.googleapis.com",
]);
export const FIREBASE_MEDIA_HOST_SUFFIXES: string[] = [
  ".googleusercontent.com",
  ".firebasestorage.app",
];

export async function assertSafeUrl(
  rawUrl: string,
  opts: AssertSafeUrlOptions = {}
): Promise<URL> {
  if (typeof rawUrl !== "string" || rawUrl.length === 0 || rawUrl.length > 4096) {
    throw new SsrfGuardError("BAD_URL", "empty or too long");
  }
  let parsed: URL;
  try {
    parsed = new URL(rawUrl);
  } catch {
    throw new SsrfGuardError("BAD_URL", "unparseable");
  }

  const schemes = opts.allowedSchemes ?? ["https:"];
  if (!schemes.includes(parsed.protocol)) throw new SsrfGuardError("BAD_SCHEME", parsed.protocol);
  if (parsed.username || parsed.password) throw new SsrfGuardError("USERINFO_NOT_ALLOWED");

  const hostname = parsed.hostname;
  if (!hostname) throw new SsrfGuardError("NO_HOST");

  const literalV4 = /^(\d{1,3}\.){3}\d{1,3}$/.test(hostname);
  const literalV6 = hostname.startsWith("[") && hostname.endsWith("]");
  if (literalV4 || literalV6) {
    const ip = literalV6 ? hostname.slice(1, -1) : hostname;
    const family = literalV6 ? 6 : 4;
    if (isPrivateIp(ip, family)) throw new SsrfGuardError("PRIVATE_IP", `literal ${ip}`);
    if (opts.allowedHostsExact || opts.allowedHostSuffixes) {
      throw new SsrfGuardError("HOST_NOT_ALLOWED", `literal ${ip}`);
    }
    return parsed;
  }

  const allowExact = opts.allowedHostsExact;
  const allowSuffix = opts.allowedHostSuffixes;
  if (allowExact || allowSuffix) {
    const h = hostname.toLowerCase();
    const ok =
      (allowExact && allowExact.has(h)) ||
      (allowSuffix && allowSuffix.some((s) => h.endsWith(s)));
    if (!ok) throw new SsrfGuardError("HOST_NOT_ALLOWED", hostname);
  }

  const results = await dnsLookup(hostname, { all: true, verbatim: true });
  const list = Array.isArray(results) ? results : [results];
  if (list.length === 0) throw new SsrfGuardError("DNS_NO_ANSWER", hostname);
  for (const r of list) {
    if (isPrivateIp(r.address, r.family)) {
      throw new SsrfGuardError("PRIVATE_IP", `${hostname} -> ${r.address}`);
    }
  }
  return parsed;
}
