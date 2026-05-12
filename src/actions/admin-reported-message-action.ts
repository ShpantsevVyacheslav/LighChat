'use server';

import { z } from 'zod';

import { adminDb } from '@/firebase/admin';
import { assertAdminByIdToken } from '@/actions/admin-actions';
import type { ChatAttachment, MessageHiddenByAdmin } from '@/lib/types';

const FirestoreIdSchema = z
  .string()
  .min(1)
  .max(256)
  .refine((s) => !s.includes('/'), 'invalid_id: slash forbidden')
  .refine((s) => s !== '.' && s !== '..', 'invalid_id: dot/dotdot forbidden');

const InputSchema = z.object({
  idToken: z.string().min(1),
  conversationId: FirestoreIdSchema,
  messageId: FirestoreIdSchema,
});

export type ReportedMessageDetails = {
  /** HTML текст сообщения, как лежит в Firestore (TipTap rich text). */
  textHtml: string;
  attachments: ChatAttachment[];
  hiddenByAdmin: MessageHiddenByAdmin | null;
  /** Зашифровано ли сообщение E2EE v2 — тогда plaintext не виден даже админу. */
  isE2ee: boolean;
  createdAt: string | null;
};

/**
 * Возвращает админу деталь репортнутого сообщения: оригинальный HTML-текст
 * для plain-стрипа в UI и массив вложений с URL/типом для превью. Идёт
 * через server action, чтобы не давать админу прямой Firestore-read на
 * `conversations/{cid}/messages/{mid}` (правила требуют участия в чате).
 *
 * E2EE-сообщения: возвращаем `isE2ee=true` без plaintext, т.к. ключи у
 * клиента.
 */
export async function fetchReportedMessageDetailsAction(input: {
  idToken: string;
  conversationId: string;
  messageId: string;
}): Promise<
  | { ok: true; details: ReportedMessageDetails }
  | { ok: false; error: string }
> {
  const parsed = InputSchema.safeParse(input);
  if (!parsed.success) {
    return { ok: false, error: 'Некорректные параметры' };
  }
  try {
    await assertAdminByIdToken(parsed.data.idToken);

    const snap = await adminDb
      .collection('conversations')
      .doc(parsed.data.conversationId)
      .collection('messages')
      .doc(parsed.data.messageId)
      .get();

    if (!snap.exists) {
      return { ok: false, error: 'Сообщение не найдено или удалено' };
    }

    const data = snap.data() ?? {};
    const e2ee = data.e2ee as { protocolVersion?: string } | undefined;
    const isE2ee = !!(e2ee && typeof e2ee === 'object' && typeof e2ee.protocolVersion === 'string'
      && e2ee.protocolVersion.startsWith('v2-'));

    const rawAttachments = Array.isArray(data.attachments) ? data.attachments : [];
    const attachments: ChatAttachment[] = rawAttachments
      .filter((a: unknown): a is Record<string, unknown> => !!a && typeof a === 'object')
      .map((a) => ({
        url: typeof a.url === 'string' ? a.url : '',
        name: typeof a.name === 'string' ? a.name : '',
        type: typeof a.type === 'string' ? a.type : '',
        size: typeof a.size === 'number' ? a.size : 0,
        width: typeof a.width === 'number' ? a.width : undefined,
        height: typeof a.height === 'number' ? a.height : undefined,
      }))
      .filter((a) => a.url);

    return {
      ok: true,
      details: {
        textHtml: isE2ee ? '' : (typeof data.text === 'string' ? data.text : ''),
        attachments: isE2ee ? [] : attachments,
        hiddenByAdmin: (data.hiddenByAdmin ?? null) as MessageHiddenByAdmin | null,
        isE2ee,
        createdAt: typeof data.createdAt === 'string' ? data.createdAt : null,
      },
    };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === 'FORBIDDEN' || msg === 'UNAUTHORIZED') return { ok: false, error: 'Недостаточно прав' };
    console.error('[fetchReportedMessageDetailsAction]', e);
    return { ok: false, error: 'Не удалось загрузить сообщение' };
  }
}
