'use client';

/**
 * E2EE v2 — Phase 9: гидратация расшифрованных медиа-вложений в массив
 * сообщений перед рендером.
 *
 * Контракт:
 *  - читает `message.e2ee.attachments[]` (envelopes);
 *  - для каждого не-null envelope вызывает `mediaApi.resolveForView` (lazy,
 *    один раз на messageId+fileId; blob-URL кэшируется внутри
 *    `useE2eeMediaAttachments`);
 *  - возвращает новый массив сообщений, в котором `.attachments`
 *    дополнен расшифрованными `ChatAttachment` (blob-URL + mime + name).
 *    Плейнтекст-вложения (stickers/GIFs) остаются на своих местах, т.к.
 *    для них envelope в параллельном массиве будет `null`.
 *
 * Контракт гарантирует идентичность ссылок, когда декрипт ещё не завершён —
 * исходный объект `message` возвращается как есть. Только при появлении
 * новых blob-URL хук выдаёт свежий массив (чтобы React выполнил повторный
 * рендер).
 *
 * Fallback-подписи (для UI) пока формируются как минимальные:
 *   - name = `<kind>_<fileId>.<ext>`
 *   - width/height/thumbHash не восстанавливаются из envelope (в v1-ом
 *     wire-формате у нас их нет; добавление — отдельная итерация).
 */

import { useEffect, useMemo, useRef, useState } from 'react';
import type {
  ChatAttachment,
  ChatMessage,
  ChatMessageE2eeAttachmentEnvelopeV2,
} from '@/lib/types';

/** Внешне необходимый мини-API. Чтобы хук не знал про Storage напрямую. */
export type E2eeMediaResolver = {
  resolveForView: (opts: {
    messageId: string;
    envelope: ChatMessageE2eeAttachmentEnvelopeV2;
    messageEpoch: number;
  }) => Promise<{ objectUrl: string; mime: string }>;
};

type ResolvedEntry = {
  objectUrl: string;
  mime: string;
};

function mimeToExt(mime: string, fallback = 'bin'): string {
  const m = (mime || '').toLowerCase();
  if (!m) return fallback;
  if (m === 'image/jpeg') return 'jpg';
  if (m === 'audio/mp4') return 'm4a';
  if (m === 'video/quicktime') return 'mov';
  const parts = m.split('/');
  return parts[1]?.split(';')[0] || fallback;
}

function envelopeToResolvedAttachment(
  env: ChatMessageE2eeAttachmentEnvelopeV2,
  resolved: ResolvedEntry
): ChatAttachment {
  const ext = mimeToExt(env.mime);
  const prefix =
    env.kind === 'voice'
      ? 'voice_'
      : env.kind === 'videoCircle'
        ? 'video-circle_'
        : env.kind === 'video'
          ? 'video_'
          : env.kind === 'image'
            ? 'image_'
            : 'file_';
  return {
    url: resolved.objectUrl,
    name: `${prefix}${env.fileId}.${ext}`,
    type: env.mime,
    size: env.size,
  };
}

/**
 * Превращает список сообщений в список сообщений с расшифрованными
 * E2EE-вложениями. Ленивый декрипт: каждый envelope запускается один раз,
 * результаты складываются в внутренний `Map` и отдают блоб-URL в render.
 *
 * Возвращает референсно-стабильный массив, если ничего не изменилось.
 */
export function useE2eeHydratedMessages<T extends ChatMessage>(
  messages: T[],
  resolver: E2eeMediaResolver | null
): T[] {
  const [resolved, setResolved] = useState<Map<string, ResolvedEntry>>(
    () => new Map()
  );
  const inFlightRef = useRef<Set<string>>(new Set());

  useEffect(() => {
    if (!resolver) return;
    const pending: Array<{
      key: string;
      messageId: string;
      envelope: ChatMessageE2eeAttachmentEnvelopeV2;
      epoch: number;
    }> = [];
    for (const msg of messages) {
      const envelopes = msg.e2ee?.attachments;
      if (!envelopes || envelopes.length === 0) continue;
      for (const env of envelopes) {
        if (!env) continue;
        const key = `${msg.id}:${env.fileId}`;
        if (resolved.has(key)) continue;
        if (inFlightRef.current.has(key)) continue;
        pending.push({
          key,
          messageId: msg.id,
          envelope: env,
          epoch: msg.e2ee?.epoch ?? 0,
        });
      }
    }
    if (pending.length === 0) return;

    let cancelled = false;

    void (async () => {
      for (const task of pending) {
        inFlightRef.current.add(task.key);
        try {
          const res = await resolver.resolveForView({
            messageId: task.messageId,
            envelope: task.envelope,
            messageEpoch: task.epoch,
          });
          if (cancelled) return;
          setResolved((prev) => {
            if (prev.has(task.key)) return prev;
            const next = new Map(prev);
            next.set(task.key, { objectUrl: res.objectUrl, mime: res.mime });
            return next;
          });
        } catch (err) {
          console.warn('[e2ee] media resolve failed', {
            messageId: task.messageId,
            fileId: task.envelope.fileId,
            err,
          });
        } finally {
          inFlightRef.current.delete(task.key);
        }
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [messages, resolver, resolved]);

  return useMemo(() => {
    let didChange = false;
    const hydrated = messages.map((msg) => {
      const envelopes = msg.e2ee?.attachments;
      if (!envelopes || envelopes.length === 0) return msg;
      // Pending-вложения НЕ добавляем в `.attachments` — иначе renderer
      // получает `<img src="">` и рисует иконку «битая картинка». Вместо
      // этого рисуем только уже расшифрованные envelope'ы, а MessageMedia
      // сам покажет skeleton/blur по числу ещё не-разрешённых слотов
      // (см. `message.e2ee.attachments.length - resolvedCount`).
      const extra: ChatAttachment[] = [];
      for (const env of envelopes) {
        if (!env) continue;
        const key = `${msg.id}:${env.fileId}`;
        const hit = resolved.get(key);
        if (hit) extra.push(envelopeToResolvedAttachment(env, hit));
      }
      if (extra.length === 0) return msg;
      didChange = true;
      const base = msg.attachments ?? [];
      const merged = base.length > 0 ? [...base, ...extra] : extra;
      return { ...msg, attachments: merged };
    });
    return didChange ? hydrated : messages;
  }, [messages, resolved]);
}
