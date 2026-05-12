import { NextResponse, type NextRequest } from 'next/server';
import admin from 'firebase-admin';
import { adminDb } from '@/firebase/admin';
import { logger } from '@/lib/logger';

/**
 * [audit H-009] CSP violation reporting endpoint.
 *
 * Зачем:
 *  - Сейчас CSP в Report-Only mode (см. `src/middleware.ts`). Без `report-uri`
 *    violations пишутся только в DevTools console пользователя — мы их
 *    не видим. До переключения на Enforce нужна observation period (~неделя)
 *    с реальными метриками: какие ресурсы блокируются, на каких страницах,
 *    с какой частотой.
 *  - Endpoint собирает violation reports (две версии формата — `application/
 *    csp-report` для CSP 2.0 и `application/reports+json` для Reporting API
 *    Level 1) и дедупает их в Firestore `cspViolations/{hash}`.
 *
 * Контракт:
 *  - POST без авторизации (CSP reports никогда не несут cookies/auth).
 *  - Body parsed как JSON. Игнорим невалидный JSON / неверные shapes.
 *  - Возвращаем 204 (No Content) даже на parse-failure, чтобы браузер
 *    не retry'ил.
 *
 * SECURITY:
 *  - Endpoint публичный → потенциальный спам-вектор. Защита:
 *    1) Throttle на (hash, day) — каждое уникальное violation пишется
 *       max 1 раз в день (Firestore-level через transaction).
 *    2) Лимит `samples` — храним последние 10 примеров на hash;
 *       старые ротируются.
 *    3) Размер payload ограничен runtime'ом Next (10MB body), достаточно.
 *
 * Где смотреть результаты:
 *  - Firestore Console → `cspViolations` коллекция, sort by `lastSeenAt desc`.
 *  - (TODO) Admin panel `/dashboard/admin/csp` с UI для filter/dismiss.
 */

export const runtime = 'nodejs'; // firebase-admin несовместим с edge runtime
export const dynamic = 'force-dynamic'; // отключить cache

type CspReport = {
  'document-uri'?: string;
  'documentURL'?: string; // CSP 3.0 / Reporting API uses camelCase variant
  'violated-directive'?: string;
  'effectiveDirective'?: string;
  'blocked-uri'?: string;
  'blockedURL'?: string;
  'source-file'?: string;
  'sourceFile'?: string;
  'line-number'?: number;
  'lineNumber'?: number;
  'column-number'?: number;
  'columnNumber'?: number;
  'script-sample'?: string;
  'sample'?: string;
  disposition?: 'enforce' | 'report';
  referrer?: string;
};

function normalize(raw: unknown): CspReport | null {
  if (!raw || typeof raw !== 'object') return null;
  const obj = raw as Record<string, unknown>;
  // CSP 2.0 wraps под `csp-report`; Reporting API передаёт массив `[{type, body}, ...]`.
  if ('csp-report' in obj && typeof obj['csp-report'] === 'object') {
    return obj['csp-report'] as CspReport;
  }
  if ('body' in obj && typeof obj.body === 'object' && obj.body) {
    return obj.body as CspReport;
  }
  if ('blocked-uri' in obj || 'blockedURL' in obj || 'violated-directive' in obj) {
    return obj as CspReport;
  }
  return null;
}

function pick<T extends string | number>(...vals: Array<T | undefined>): T | undefined {
  for (const v of vals) if (v !== undefined && v !== null && v !== '') return v;
  return undefined;
}

/** SHA-256 → first 16 hex chars. Достаточно для dedupe в нашем масштабе. */
async function shortHash(input: string): Promise<string> {
  const bytes = new TextEncoder().encode(input);
  const hash = await crypto.subtle.digest('SHA-256', bytes);
  const hex = Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
  return hex.slice(0, 16);
}

export async function POST(request: NextRequest) {
  let parsed: unknown;
  try {
    parsed = await request.json();
  } catch {
    // Невалидный JSON — игнорим, чтобы браузер не retry'ил.
    return new NextResponse(null, { status: 204 });
  }

  // Reporting API шлёт array, CSP 2.0 шлёт object. Нормализуем в массив.
  const items = Array.isArray(parsed) ? parsed : [parsed];

  const userAgent = request.headers.get('user-agent') ?? '';

  for (const item of items) {
    const r = normalize(item);
    if (!r) continue;

    const directive = pick<string>(
      r['violated-directive'],
      r['effectiveDirective'],
    ) ?? 'unknown';
    const blockedUri = pick<string>(r['blocked-uri'], r['blockedURL']) ?? '';
    const documentUri = pick<string>(r['document-uri'], r['documentURL']) ?? '';
    const sourceFile = pick<string>(r['source-file'], r['sourceFile']) ?? '';
    const lineNumber = pick<number>(r['line-number'], r['lineNumber']);
    const scriptSample = pick<string>(r['script-sample'], r['sample']) ?? '';

    // Hash: directive + base-blockedUri (без path) + base-documentUri (route)
    //   → дедупит «один и тот же CDN на одной странице» в один документ.
    const blockedBase = blockedUri.split('?')[0]?.replace(/\/[^/]+$/, '') ?? blockedUri;
    const docPath = (() => {
      try { return new URL(documentUri).pathname; } catch { return documentUri; }
    })();
    const hashInput = `${directive}|${blockedBase}|${docPath}`;
    let hash: string;
    try {
      hash = await shortHash(hashInput);
    } catch (e) {
      logger.warn('csp-report', 'hash failed', e);
      continue;
    }

    const doc = adminDb.collection('cspViolations').doc(hash);
    try {
      // Транзакция: throttle до 1 write per hash per day,
      // ротация samples до 10 последних.
      await adminDb.runTransaction(async (tx) => {
        const snap = await tx.get(doc);
        const now = admin.firestore.Timestamp.now();
        const today = new Date().toISOString().slice(0, 10); // YYYY-MM-DD
        if (snap.exists) {
          const data = snap.data() ?? {};
          if (data.lastSeenDay === today) {
            // throttle: уже видели сегодня, увеличиваем counter без write samples
            tx.update(doc, {
              count: admin.firestore.FieldValue.increment(1),
              lastSeenAt: now,
            });
            return;
          }
          const samples: unknown[] = Array.isArray(data.samples) ? data.samples : [];
          const next = [...samples, { sourceFile, lineNumber, scriptSample, userAgent, blockedUri, documentUri, at: now }];
          // Только последние 10
          const trimmed = next.slice(Math.max(0, next.length - 10));
          tx.update(doc, {
            count: admin.firestore.FieldValue.increment(1),
            lastSeenAt: now,
            lastSeenDay: today,
            samples: trimmed,
          });
        } else {
          tx.set(doc, {
            hash,
            directive,
            blockedBase,
            docPath,
            count: 1,
            firstSeenAt: now,
            lastSeenAt: now,
            lastSeenDay: today,
            samples: [{ sourceFile, lineNumber, scriptSample, userAgent, blockedUri, documentUri, at: now }],
          });
        }
      });
    } catch (e) {
      // Если Admin SDK недоступен (local dev без ADC) — лог в server console.
      logger.warn('csp-report', 'firestore write failed', { error: e, directive, blockedUri });
    }

    // Analytics-bridge: дублируем уникальные CSP-violations как
    // `csp_violation_received` событие — попадает в общий рейтинг ошибок
    // (admin product analytics → Errors). Только blocked host (без path) —
    // PII safety.
    try {
      const blockedHost = (() => {
        try { return new URL(blockedUri).host; } catch { return blockedBase.slice(0, 100); }
      })();
      await adminDb.collection('analyticsEvents').add({
        event: 'csp_violation_received',
        params: { directive, blocked_uri_host: blockedHost, doc_path: docPath.slice(0, 80) },
        platform: 'web',
        uid: null,
        ts: new Date().toISOString(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        source: 'csp_endpoint',
      });
    } catch (e) {
      logger.debug('csp-report', 'analytics bridge write failed', e);
    }
  }

  return new NextResponse(null, { status: 204 });
}

// Reporting API делает POST с типом `application/reports+json`, традиционный
// CSP — `application/csp-report`. Next route handlers пропускают оба mime,
// `request.json()` десериализует JSON независимо от Content-Type.
export async function OPTIONS() {
  return new NextResponse(null, {
    status: 204,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    },
  });
}
