'use client';

import React, { useEffect, useMemo, useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { ShieldOff, Loader2, ChevronDown, ChevronRight } from 'lucide-react';
import { useFirestore } from '@/firebase';
import {
  collection,
  limit as fsLimit,
  onSnapshot,
  orderBy,
  query,
  Timestamp,
} from 'firebase/firestore';
import { logger } from '@/lib/logger';

/**
 * [audit H-009] Просмотр CSP violation reports перед переключением Report-Only
 * → Enforce. См. `docs/audits/H-009-CSP-enforce-migration.md` для процедуры
 * наблюдения и чеклиста переключения.
 *
 * Данные пишутся endpoint'ом `/api/csp-report` (см. `src/app/api/csp-report/
 * route.ts`) через Admin SDK. Чтение здесь — через клиентский SDK с rules
 * `isAdmin()` (см. `firestore.rules:cspViolations`).
 */

type CspViolationSample = {
  sourceFile?: string;
  lineNumber?: number;
  scriptSample?: string;
  userAgent?: string;
  blockedUri?: string;
  documentUri?: string;
  at?: Timestamp;
};

type CspViolationDoc = {
  hash: string;
  directive: string;
  blockedBase: string;
  docPath: string;
  count: number;
  firstSeenAt?: Timestamp;
  lastSeenAt?: Timestamp;
  lastSeenDay?: string;
  samples?: CspViolationSample[];
};

function tsToDate(ts: Timestamp | undefined): Date | null {
  if (!ts) return null;
  try {
    return ts.toDate();
  } catch {
    return null;
  }
}

function fmtDate(d: Date | null): string {
  if (!d) return '—';
  return d.toLocaleString('ru-RU', {
    day: '2-digit',
    month: '2-digit',
    year: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  });
}

/** Цвет директивы по серьёзности (script-src — самое страшное). */
function directiveColor(directive: string): string {
  const d = directive.toLowerCase();
  if (d.includes('script')) return 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400';
  if (d.includes('connect')) return 'bg-orange-100 text-orange-800 dark:bg-orange-900/30 dark:text-orange-400';
  if (d.includes('frame')) return 'bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-400';
  if (d.includes('img') || d.includes('media') || d.includes('font')) {
    return 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400';
  }
  return 'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-400';
}

export function AdminCspViolationsPanel() {
  const firestore = useFirestore();
  const [violations, setViolations] = useState<CspViolationDoc[]>([]);
  const [loading, setLoading] = useState(true);
  const [expanded, setExpanded] = useState<Set<string>>(new Set());

  useEffect(() => {
    if (!firestore) return;
    setLoading(true);
    const q = query(
      collection(firestore, 'cspViolations'),
      orderBy('lastSeenAt', 'desc'),
      fsLimit(200),
    );
    return onSnapshot(
      q,
      (snap) => {
        setViolations(snap.docs.map((d) => d.data() as CspViolationDoc));
        setLoading(false);
      },
      (err) => {
        logger.error('admin-csp', 'cspViolations subscription failed', err);
        setLoading(false);
      },
    );
  }, [firestore]);

  const totals = useMemo(() => {
    const byDirective = new Map<string, number>();
    for (const v of violations) {
      byDirective.set(v.directive, (byDirective.get(v.directive) ?? 0) + v.count);
    }
    const totalHits = violations.reduce((sum, v) => sum + v.count, 0);
    return { byDirective, totalHits };
  }, [violations]);

  const toggleExpanded = (hash: string) => {
    setExpanded((prev) => {
      const next = new Set(prev);
      if (next.has(hash)) next.delete(hash);
      else next.add(hash);
      return next;
    });
  };

  return (
    <Card className="rounded-3xl">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-lg">
          <ShieldOff className="h-5 w-5 text-primary" />
          CSP Violations (H-009 observation)
        </CardTitle>
        <CardDescription>
          Нарушения CSP с прода. Перед переключением Report-Only → Enforce — проверь, что все
          script-src/connect-src violations либо в whitelist (
          <code className="text-[10px]">src/middleware.ts</code>), либо classified как шум.
          Процедура: <code className="text-[10px]">docs/audits/H-009-CSP-enforce-migration.md</code>.
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Summary by directive */}
        <div className="flex flex-wrap gap-2">
          <Badge variant="secondary" className="text-[10px]">
            Всего hits: <strong className="ml-1">{totals.totalHits}</strong>
          </Badge>
          {Array.from(totals.byDirective.entries())
            .sort((a, b) => b[1] - a[1])
            .map(([dir, count]) => (
              <Badge key={dir} variant="secondary" className={`text-[10px] ${directiveColor(dir)}`}>
                {dir}: <strong className="ml-1">{count}</strong>
              </Badge>
            ))}
        </div>

        {loading ? (
          <div className="flex justify-center py-8">
            <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
          </div>
        ) : violations.length === 0 ? (
          <p className="py-8 text-center text-sm text-muted-foreground">
            CSP-нарушений пока нет. Либо CSP идеален, либо браузеры ещё не достучались до
            <code className="ml-1 text-[10px]">/api/csp-report</code>.
          </p>
        ) : (
          <div className="rounded-2xl border overflow-hidden">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-8" />
                  <TableHead>Directive</TableHead>
                  <TableHead>Blocked source</TableHead>
                  <TableHead>Page</TableHead>
                  <TableHead className="text-right">Hits</TableHead>
                  <TableHead>Last seen</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {violations.map((v) => {
                  const isOpen = expanded.has(v.hash);
                  return (
                    <React.Fragment key={v.hash}>
                      <TableRow
                        className="cursor-pointer hover:bg-muted/40"
                        onClick={() => toggleExpanded(v.hash)}
                      >
                        <TableCell className="w-8 pr-0">
                          {isOpen ? (
                            <ChevronDown className="h-3 w-3 text-muted-foreground" />
                          ) : (
                            <ChevronRight className="h-3 w-3 text-muted-foreground" />
                          )}
                        </TableCell>
                        <TableCell>
                          <Badge variant="secondary" className={`text-[10px] ${directiveColor(v.directive)}`}>
                            {v.directive}
                          </Badge>
                        </TableCell>
                        <TableCell className="font-mono text-[11px] max-w-[260px] truncate" title={v.blockedBase}>
                          {v.blockedBase || '—'}
                        </TableCell>
                        <TableCell className="font-mono text-[11px] max-w-[180px] truncate" title={v.docPath}>
                          {v.docPath || '—'}
                        </TableCell>
                        <TableCell className="text-right tabular-nums">{v.count}</TableCell>
                        <TableCell className="text-[11px] text-muted-foreground">
                          {fmtDate(tsToDate(v.lastSeenAt))}
                        </TableCell>
                      </TableRow>
                      {isOpen && (v.samples?.length ?? 0) > 0 && (
                        <TableRow className="bg-muted/20">
                          <TableCell colSpan={6} className="p-3">
                            <div className="space-y-2 text-[11px]">
                              <div className="text-muted-foreground">
                                First seen: {fmtDate(tsToDate(v.firstSeenAt))} · hash:{' '}
                                <code className="text-[10px]">{v.hash}</code>
                              </div>
                              <div className="max-h-56 overflow-auto rounded border bg-background p-2 font-mono">
                                {(v.samples ?? []).slice().reverse().map((s, idx) => (
                                  <div key={idx} className="border-b border-border/40 pb-1.5 pt-1.5 first:pt-0 last:border-b-0 last:pb-0">
                                    <div>
                                      <span className="text-muted-foreground">blocked:</span> {s.blockedUri || '—'}
                                    </div>
                                    {s.sourceFile && (
                                      <div>
                                        <span className="text-muted-foreground">source:</span> {s.sourceFile}
                                        {s.lineNumber ? `:${s.lineNumber}` : ''}
                                      </div>
                                    )}
                                    {s.scriptSample && (
                                      <div>
                                        <span className="text-muted-foreground">sample:</span>{' '}
                                        <code className="break-all">{s.scriptSample}</code>
                                      </div>
                                    )}
                                    {s.userAgent && (
                                      <div className="truncate" title={s.userAgent}>
                                        <span className="text-muted-foreground">UA:</span> {s.userAgent}
                                      </div>
                                    )}
                                    <div className="text-muted-foreground">{fmtDate(tsToDate(s.at))}</div>
                                  </div>
                                ))}
                              </div>
                            </div>
                          </TableCell>
                        </TableRow>
                      )}
                    </React.Fragment>
                  );
                })}
              </TableBody>
            </Table>
          </div>
        )}

        <p className="text-[10px] text-muted-foreground">
          Limit: 200 наиболее свежих по <code>lastSeenAt</code>. Throttle: 1 запись на violation
          в день. Для production-аудита открой Firestore Console → <code>cspViolations</code>.
        </p>
      </CardContent>
    </Card>
  );
}
