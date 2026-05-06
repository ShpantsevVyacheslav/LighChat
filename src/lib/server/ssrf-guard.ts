// SECURITY: server-side SSRF guard. Used for any place where we make outbound
// HTTP requests on behalf of the client (link previews, image proxies, push
// hooks, etc.). Without this, a server action that fetches a user-supplied URL
// could be steered to internal services — most dangerously
// `http://169.254.169.254/computeMetadata/v1/...` on App Hosting / GCP, which
// returns the runtime service-account token.
//
// Defense layers:
//   1. URL syntactically valid + scheme allow-list (https only by default).
//   2. (Optional) hostname suffix allow-list.
//   3. DNS resolve and reject if ANY A/AAAA record is private/loopback/
//      link-local/CG-NAT/multicast/reserved (defeats DNS-rebinding too).
//
// This file is intentionally framework-free so it can be reused by any server
// action / route handler / Cloud Function shim. It MUST NOT be imported from
// client code — it requires node:dns and runs network lookups.

import { lookup as dnsLookupCb } from 'node:dns';
import { promisify } from 'node:util';

const dnsLookup = promisify(dnsLookupCb);

export type AssertSafeUrlOptions = {
  /** Schemes considered acceptable. Defaults to ['https:']. */
  allowedSchemes?: string[];
  /**
   * If provided, hostname must either match exactly an entry in
   * `allowedHostsExact` OR end with one of the given suffixes (which MUST
   * include a leading dot, e.g. '.googleusercontent.com').
   */
  allowedHostsExact?: Set<string>;
  allowedHostSuffixes?: string[];
};

export class SsrfGuardError extends Error {
  readonly code: string;
  constructor(code: string, message?: string) {
    super(message ?? code);
    this.code = code;
    this.name = 'SsrfGuardError';
  }
}

/**
 * IPv4/IPv6 private/loopback/link-local/CG-NAT/multicast/reserved check.
 * Returns true (= "block") for any address that should not be reachable from
 * a server-side fetch initiated on behalf of an untrusted user.
 */
export function isPrivateIp(addr: string, family: number): boolean {
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
    if (a >= 224) return true;                          // multicast + reserved
    return false;
  }
  // IPv6
  const lower = String(addr).toLowerCase();
  if (lower === '::1' || lower === '::') return true;
  if (lower.startsWith('fe80:') || lower.startsWith('fe80::')) return true;
  if (/^f[cd][0-9a-f]{2}:/.test(lower)) return true;    // fc00::/7 unique-local
  if (lower.startsWith('ff')) return true;              // multicast
  // IPv4-mapped: ::ffff:a.b.c.d → check inner v4
  const mapped = lower.match(/^::ffff:([0-9.]+)$/);
  if (mapped) return isPrivateIp(mapped[1], 4);
  return false;
}

/**
 * Resolve all A/AAAA records and reject if ANY is private. Collapses the
 * DNS-rebinding window: even if an attacker rotates DNS to public IPs for the
 * pre-flight and private for the actual fetch, the multi-record check + a
 * second resolve at fetch time (caller's responsibility) makes this expensive.
 */
async function assertResolvesToPublicIp(hostname: string): Promise<void> {
  const results = await dnsLookup(hostname, { all: true, verbatim: true });
  const list = Array.isArray(results) ? results : [results];
  if (list.length === 0) {
    throw new SsrfGuardError('DNS_NO_ANSWER', `no A/AAAA for ${hostname}`);
  }
  for (const r of list) {
    if (isPrivateIp(r.address, r.family)) {
      throw new SsrfGuardError('PRIVATE_IP', `${hostname} → ${r.address} (private)`);
    }
  }
}

function isHostInAllowlist(
  hostname: string,
  exact: Set<string> | undefined,
  suffixes: string[] | undefined
): boolean {
  if (!exact && !suffixes) return true; // no allow-list => allow any public host
  const h = hostname.toLowerCase();
  if (exact && exact.has(h)) return true;
  if (suffixes && suffixes.some((s) => h.endsWith(s))) return true;
  return false;
}

/**
 * Validate that `rawUrl` is safe to fetch from the server. Throws on any
 * violation — caller should catch and treat as input rejection.
 *
 * Returns the parsed URL on success, ready to pass into fetch().
 *
 * Note: this validates ONE hop. If your fetcher follows redirects, also pass
 * `redirect: 'manual'` (or 'error') to the underlying fetch and re-validate
 * each hop's URL through this function.
 */
export async function assertSafeUrl(
  rawUrl: string,
  opts: AssertSafeUrlOptions = {}
): Promise<URL> {
  if (typeof rawUrl !== 'string' || rawUrl.length === 0 || rawUrl.length > 4096) {
    throw new SsrfGuardError('BAD_URL', 'empty or too long');
  }

  let parsed: URL;
  try {
    parsed = new URL(rawUrl);
  } catch {
    throw new SsrfGuardError('BAD_URL', 'unparseable');
  }

  const schemes = opts.allowedSchemes ?? ['https:'];
  if (!schemes.includes(parsed.protocol)) {
    throw new SsrfGuardError('BAD_SCHEME', parsed.protocol);
  }

  // Reject userinfo (https://user:pass@host) — not needed and confuses URL
  // parsers downstream.
  if (parsed.username || parsed.password) {
    throw new SsrfGuardError('USERINFO_NOT_ALLOWED');
  }

  const hostname = parsed.hostname;
  if (!hostname) throw new SsrfGuardError('NO_HOST');

  // If the URL host is a literal IP, check it directly (no DNS).
  const literalV4 = /^(\d{1,3}\.){3}\d{1,3}$/.test(hostname);
  const literalV6 = hostname.startsWith('[') && hostname.endsWith(']');
  if (literalV4 || literalV6) {
    const ip = literalV6 ? hostname.slice(1, -1) : hostname;
    const family = literalV6 ? 6 : 4;
    if (isPrivateIp(ip, family)) {
      throw new SsrfGuardError('PRIVATE_IP', `literal ${ip}`);
    }
    // Literal IP cannot satisfy a hostname-based allow-list.
    if (opts.allowedHostsExact || opts.allowedHostSuffixes) {
      throw new SsrfGuardError('HOST_NOT_ALLOWED', `literal ${ip}`);
    }
    return parsed;
  }

  if (!isHostInAllowlist(hostname, opts.allowedHostsExact, opts.allowedHostSuffixes)) {
    throw new SsrfGuardError('HOST_NOT_ALLOWED', hostname);
  }

  await assertResolvesToPublicIp(hostname);
  return parsed;
}
