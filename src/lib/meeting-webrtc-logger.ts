/**
 * Диагностика mesh WebRTC встреч (веб `use-meeting-webrtc`).
 *
 * Включение подробных логов:
 * - dev-сборка: по умолчанию **включено** (`NODE_ENV === 'development'`);
 * - prod: `NEXT_PUBLIC_MEETING_WEBRTC_LOG=1` в env при сборке;
 * - отключить везде: `NEXT_PUBLIC_MEETING_WEBRTC_LOG=0`.
 *
 * Ошибки и предупреждения (`warn`/`error`) пишутся всегда (без флага).
 */

function verboseEnabled(): boolean {
  if (typeof process === 'undefined') return false;
  const v = process.env.NEXT_PUBLIC_MEETING_WEBRTC_LOG;
  if (v === '0' || v === 'false') return false;
  if (v === '1' || v === 'true') return true;
  return process.env.NODE_ENV === 'development';
}

function prefix(meetingId: string, selfId: string): string {
  const m = meetingId.length > 10 ? `${meetingId.slice(0, 10)}…` : meetingId;
  const u = selfId.length > 10 ? `${selfId.slice(0, 10)}…` : selfId;
  return `[MeetingWebRTC ${new Date().toISOString()} meeting=${m} self=${u}]`;
}

export function summarizeRtcConfiguration(config: RTCConfiguration): Record<string, unknown> {
  const servers = config.iceServers ?? [];
  const urlsPreview = servers.map((s) => {
    const u = s.urls;
    if (typeof u === 'string') return u.split(':')[0];
    if (Array.isArray(u)) return u.map((x) => String(x).split(':')[0]).join(',');
    return '?';
  });
  return {
    iceServerCount: servers.length,
    iceTransportPolicy: config.iceTransportPolicy ?? 'all',
    iceCandidatePoolSize: config.iceCandidatePoolSize ?? null,
    urlsPreview,
  };
}

/** Краткое описание simple-peer / RTCSessionDescription без утечки полного SDP в консоль */
export function summarizeSignalPayload(data: unknown): Record<string, unknown> {
  if (data == null) return { kind: 'null' };
  if (typeof data !== 'object') return { kind: typeof data };
  const d = data as Record<string, unknown>;
  const t = d.type;
  if (t === 'offer' || t === 'answer') {
    const sdp = typeof d.sdp === 'string' ? d.sdp : '';
    return {
      type: t,
      sdpLength: sdp.length,
      sdpLineCount: sdp ? sdp.split(/\r?\n/).length : 0,
    };
  }
  if (d.candidate != null) {
    const c = String(d.candidate);
    return { type: 'candidate', candidateLen: c.length, candidateHead: c.slice(0, 96) };
  }
  return { type: String(t ?? 'unknown'), keys: Object.keys(d) };
}

export const meetingWebRtcLog = {
  v(meetingId: string, selfId: string, area: string, message: string, extra?: Record<string, unknown>): void {
    if (!verboseEnabled()) return;
    const p = prefix(meetingId, selfId);
    if (extra && Object.keys(extra).length > 0) {
      console.debug(`${p} [${area}] ${message}`, extra);
    } else {
      console.debug(`${p} [${area}] ${message}`);
    }
  },

  /**
   * [audit H-005] info-уровень тоже гейтим verboseEnabled() — раньше всегда
   * печатал в console участников + extra (snapshot keys, peer state),
   * что в prod-консоли пользователя засоряет логи и добавляет лишний
   * footprint при копировании в баг-репорт. warn/error остаются всегда.
   */
  info(meetingId: string, selfId: string, area: string, message: string, extra?: Record<string, unknown>): void {
    if (!verboseEnabled()) return;
    const p = prefix(meetingId, selfId);
    if (extra && Object.keys(extra).length > 0) {
      console.info(`${p} [${area}] ${message}`, extra);
    } else {
      console.info(`${p} [${area}] ${message}`);
    }
  },

  warn(meetingId: string, selfId: string, area: string, message: string, extra?: Record<string, unknown>): void {
    const p = prefix(meetingId, selfId);
    console.warn(`${p} [${area}] ${message}`, extra ?? '');
  },

  error(
    meetingId: string,
    selfId: string,
    area: string,
    message: string,
    err?: unknown,
    extra?: Record<string, unknown>,
  ): void {
    const p = prefix(meetingId, selfId);
    console.error(`${p} [${area}] ${message}`, err ?? '', extra ?? '');
  },
};
