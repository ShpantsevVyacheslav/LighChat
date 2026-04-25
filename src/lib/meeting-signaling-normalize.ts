import type { MeetingSignal } from '@/lib/types';

/**
 * Приводит payload из Firestore (`meetings/.../signals`) к формату, который ждёт
 * `simple-peer.signal()` в браузере.
 *
 * - Web→web: в `data` уже лежит тело из `emit('signal', …)` (вложенный `candidate`).
 * - Mobile (§3 wire-protocol): плоский `{ candidate: "<строка>", sdpMid?, sdpMLineIndex? }`.
 *   Для simple-peer нужно обернуть во `{ type: 'candidate', candidate: { candidate, … } }`.
 */
export function normalizeInboundSignalForSimplePeer(signal: MeetingSignal): unknown {
  const d = signal.data;
  if (d == null || typeof d !== 'object') return d;

  const obj = d as Record<string, unknown>;

  if (typeof obj.sdp === 'string') {
    const t =
      obj.type === 'offer' || obj.type === 'answer'
        ? obj.type
        : signal.type === 'offer' || signal.type === 'answer'
          ? signal.type
          : null;
    if (t) {
      return { type: t, sdp: obj.sdp };
    }
  }

  const candField = obj.candidate;

  if (typeof candField === 'string') {
    const sdpMLineIndex = parseSdpMLineIndex(obj.sdpMLineIndex);
    const sdpMid = typeof obj.sdpMid === 'string' ? obj.sdpMid : null;
    return {
      type: 'candidate',
      candidate: {
        candidate: candField,
        sdpMLineIndex,
        sdpMid,
      },
    };
  }

  if (
    candField &&
    typeof candField === 'object' &&
    typeof (candField as Record<string, unknown>).candidate === 'string'
  ) {
    return {
      type: 'candidate',
      candidate: candField,
    };
  }

  return d;
}

function parseSdpMLineIndex(v: unknown): number | null {
  if (typeof v === 'number' && Number.isFinite(v)) return v;
  if (typeof v === 'string' && v !== '') {
    const n = Number(v);
    if (Number.isFinite(n)) return n;
  }
  return null;
}
