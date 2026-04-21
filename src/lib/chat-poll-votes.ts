/** Нормализация значения голоса из Firestore (один вариант или несколько). */
export function normalizeUserVote(raw: unknown): number[] {
  if (raw == null) return [];
  if (typeof raw === 'number' && Number.isFinite(raw)) return [Math.floor(raw)];
  if (typeof raw === 'string') {
    const n = Number.parseInt(raw, 10);
    return Number.isFinite(n) ? [n] : [];
  }
  if (Array.isArray(raw)) {
    const out: number[] = [];
    for (const x of raw) {
      if (typeof x === 'number' && Number.isFinite(x)) out.push(Math.floor(x));
      else if (typeof x === 'string') {
        const n = Number.parseInt(x, 10);
        if (Number.isFinite(n)) out.push(n);
      }
    }
    return [...new Set(out)].sort((a, b) => a - b);
  }
  return [];
}

export function countVotesForOption(
  votes: Record<string, unknown> | undefined,
  optionIdx: number
): number {
  if (!votes) return 0;
  let n = 0;
  for (const raw of Object.values(votes)) {
    const sel = normalizeUserVote(raw);
    if (sel.includes(optionIdx)) n += 1;
  }
  return n;
}

export function userHasVoted(
  votes: Record<string, unknown> | undefined,
  userId: string
): boolean {
  if (!votes || !userId) return false;
  return normalizeUserVote(votes[userId]).length > 0;
}

export function userSelectedOption(
  votes: Record<string, unknown> | undefined,
  userId: string,
  optionIdx: number
): boolean {
  return normalizeUserVote(votes?.[userId]).includes(optionIdx);
}

/** Детерминированный порядок отображения вариантов для пользователя (shuffle). */
export function displayOptionIndices(
  pollId: string,
  userId: string,
  optionCount: number,
  shuffle: boolean
): number[] {
  const base = Array.from({ length: optionCount }, (_, i) => i);
  if (!shuffle || optionCount <= 1 || !userId) return base;
  const seed = _hashString(`${pollId}:${userId}`);
  const arr = [...base];
  let s = seed;
  for (let i = arr.length - 1; i > 0; i--) {
    s = (s * 1103515245 + 12345) & 0x7fffffff;
    const j = s % (i + 1);
    const t = arr[i]!;
    arr[i] = arr[j]!;
    arr[j] = t;
  }
  return arr;
}

function _hashString(str: string): number {
  let h = 0;
  for (let i = 0; i < str.length; i++) {
    h = (Math.imul(31, h) + str.charCodeAt(i)) | 0;
  }
  return Math.abs(h);
}
