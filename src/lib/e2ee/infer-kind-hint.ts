/**
 * Определяет `kindHint` для E2EE media envelope'а по имени файла.
 *
 * Зачем: `mapMimeToKind` в `media-upload-v2.ts` различает только по MIME
 * (`video/*` → `video`, `audio/*` → `voice`), поэтому «видео-кружок»
 * (`video/webm`) и обычное видео (`video/mp4`) сливаются в один kind.
 *
 * Наш клиент именует файлы при отправке детерминированно:
 *   - `video-circle_<ts>.webm` — видео-кружок
 *   - `voice_<ts>.m4a`          — голосовое
 *   - `sticker_<...>`           — стикер (не шифруется, см. isEncryptableMimeV2)
 *   - `gif_<...>`               — GIF (не шифруется)
 *
 * Используя этот helper, `ChatWindow` / `ThreadWindow` прокидывают `kindHint`
 * в `useE2eeMediaAttachments.encryptAndUploadForSend`, после чего envelope
 * несёт корректный `kind` и получатель может правильно классифицировать
 * вложение (пузырь/кружок, audio-плеер и т.п.).
 */

import type { ChatMessageE2eeAttachmentEnvelopeV2 } from '@/lib/types';

export function inferKindHintFromFileName(
  name: string
): ChatMessageE2eeAttachmentEnvelopeV2['kind'] | undefined {
  const n = (name || '').toLowerCase();
  if (n.startsWith('video-circle_')) return 'videoCircle';
  if (n.startsWith('voice_') || n.startsWith('audio_')) return 'voice';
  return undefined;
}
