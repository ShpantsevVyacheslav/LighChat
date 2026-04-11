'use client';

type PerfBucket = {
  counters: Record<string, number>;
  marks: Record<string, number>;
};

const PERF_KEY = '__lighchatChatPerf';

function isDevClient(): boolean {
  return typeof window !== 'undefined' && process.env.NODE_ENV !== 'production';
}

function ensureBucket(): PerfBucket | null {
  if (!isDevClient()) return null;
  const w = window as Window & { [PERF_KEY]?: PerfBucket };
  if (!w[PERF_KEY]) {
    w[PERF_KEY] = {
      counters: {},
      marks: {},
    };
  }
  return w[PERF_KEY] ?? null;
}

export function incrementChatPerfCounter(name: string, by = 1): void {
  const bucket = ensureBucket();
  if (!bucket) return;
  bucket.counters[name] = (bucket.counters[name] ?? 0) + by;
}

export function markChatPerf(name: string): void {
  const bucket = ensureBucket();
  if (!bucket) return;
  bucket.marks[name] = performance.now();
}

export function measureChatPerf(fromMark: string, counterName: string): void {
  const bucket = ensureBucket();
  if (!bucket) return;
  const startedAt = bucket.marks[fromMark];
  if (startedAt == null) return;
  const elapsedMs = performance.now() - startedAt;
  const roundedBucket = `${counterName}:${Math.round(elapsedMs / 50) * 50}ms`;
  incrementChatPerfCounter(roundedBucket);
}
