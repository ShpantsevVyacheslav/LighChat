/**
 * Периодический сбор WebRTC-метрик качества по одному пиру.
 *
 * Что делает:
 *   - каждые `intervalMs` (по умолчанию 5 сек) вызывает `pc.getStats()`;
 *   - выделяет у входящих (remote -> local) видео/аудио треков долю потерь пакетов,
 *     jitter и RTT по candidate-pair;
 *   - мапит в перечисление качества: `good` / `poor` / `bad` / `unknown`;
 *   - уведомляет потребителя колбэком; если качество не изменилось — колбэк не вызывается.
 *
 * Где используется:
 *   - `src/hooks/use-meeting-webrtc.ts` — подписывает каждого peer и кладёт `connectionQuality`
 *     в `participants[remoteId]`, чтобы `ParticipantView` показал иконку «слабое соединение».
 *
 * Почему отдельный модуль:
 *   - чистая логика без зависимостей на React/Firestore — легко юнит-тестируется;
 *   - в mobile-клиенте (Dart) будет написан эквивалент поверх flutter_webrtc,
 *     с этими же порогами (см. docs/arcitecture/meetings-wire-protocol.md).
 */

export type PeerConnectionQuality = 'good' | 'poor' | 'bad' | 'unknown';

export interface PeerStatsThresholds {
  /** Доля потерь пакетов за интервал, при которой качество падает до 'poor'. */
  poorPacketLossRatio: number;
  /** Доля потерь пакетов, при которой качество падает до 'bad'. */
  badPacketLossRatio: number;
  /** RTT (мс) на candidate-pair, при котором качество не выше 'poor'. */
  poorRttMs: number;
  /** RTT (мс), при котором качество не выше 'bad'. */
  badRttMs: number;
}

export const DEFAULT_PEER_STATS_THRESHOLDS: PeerStatsThresholds = {
  poorPacketLossRatio: 0.03,
  badPacketLossRatio: 0.1,
  poorRttMs: 300,
  badRttMs: 700,
};

export interface PeerStatsSample {
  quality: PeerConnectionQuality;
  packetLossRatio: number;
  roundTripTimeMs: number | null;
  jitterMs: number | null;
}

interface PrevCounters {
  packetsReceived: number;
  packetsLost: number;
}

/**
 * Запустить слежку за качеством. Возвращает функцию отписки — обязательно вызывать при
 * уничтожении peer, чтобы не утекал интервал.
 */
export function watchPeerStats(
  pc: RTCPeerConnection,
  onSample: (sample: PeerStatsSample) => void,
  options: { intervalMs?: number; thresholds?: PeerStatsThresholds } = {}
): () => void {
  const intervalMs = options.intervalMs ?? 5000;
  const thresholds = options.thresholds ?? DEFAULT_PEER_STATS_THRESHOLDS;

  const prev: PrevCounters = { packetsReceived: 0, packetsLost: 0 };
  let lastQuality: PeerConnectionQuality = 'unknown';
  let disposed = false;

  const tick = async () => {
    if (disposed) return;
    if (pc.connectionState === 'closed' || pc.signalingState === 'closed') return;
    try {
      const reports = await pc.getStats();
      let packetsReceived = 0;
      let packetsLost = 0;
      let jitterSum = 0;
      let jitterSamples = 0;
      let rtt: number | null = null;

      // [audit L-006] RTCStats — base, конкретные поля зависят от `r.type`.
      // typeof-guard'ы ниже работают, потому что отчёты приходят как любые объекты.
      reports.forEach((r: RTCStats & Record<string, unknown>) => {
        if (r.type === 'inbound-rtp' && (r.kind === 'video' || r.kind === 'audio')) {
          if (typeof r.packetsReceived === 'number') packetsReceived += r.packetsReceived;
          if (typeof r.packetsLost === 'number') packetsLost += r.packetsLost;
          if (typeof r.jitter === 'number') {
            jitterSum += r.jitter;
            jitterSamples += 1;
          }
        }
        if (
          r.type === 'candidate-pair' &&
          (r.state === 'succeeded' || r.nominated === true) &&
          typeof r.currentRoundTripTime === 'number'
        ) {
          rtt = r.currentRoundTripTime * 1000;
        }
      });

      const deltaReceived = Math.max(0, packetsReceived - prev.packetsReceived);
      const deltaLost = Math.max(0, packetsLost - prev.packetsLost);
      prev.packetsReceived = packetsReceived;
      prev.packetsLost = packetsLost;

      const total = deltaReceived + deltaLost;
      const ratio = total > 0 ? deltaLost / total : 0;

      const quality = classifyQuality(ratio, rtt, thresholds);
      const jitterMs = jitterSamples > 0 ? (jitterSum / jitterSamples) * 1000 : null;

      if (quality !== lastQuality) {
        lastQuality = quality;
        onSample({ quality, packetLossRatio: ratio, roundTripTimeMs: rtt, jitterMs });
      }
    } catch (e) {
      // Молчаливо: getStats может упасть при закрытом pc, это штатная ситуация.
    }
  };

  const timer = setInterval(tick, intervalMs);
  // Первая выборка чуть раньше, чтобы быстрее отметить «плохие» пиры.
  const firstTimeout = setTimeout(tick, Math.min(1500, intervalMs));

  return () => {
    disposed = true;
    clearInterval(timer);
    clearTimeout(firstTimeout);
  };
}

function classifyQuality(
  ratio: number,
  rttMs: number | null,
  t: PeerStatsThresholds
): PeerConnectionQuality {
  if (ratio >= t.badPacketLossRatio || (rttMs !== null && rttMs >= t.badRttMs)) return 'bad';
  if (ratio >= t.poorPacketLossRatio || (rttMs !== null && rttMs >= t.poorRttMs)) return 'poor';
  return 'good';
}
