'use server';

import { adminDb } from '@/firebase/admin';
import { assertAdminByIdToken } from '@/actions/admin-actions';
import { logAdminAction } from '@/actions/audit-log-actions';
import type { Announcement, AnnouncementType, UserRole } from '@/lib/types';

export async function createAnnouncementAction(input: {
  idToken: string;
  title: string;
  body: string;
  type: AnnouncementType;
  isActive: boolean;
  expiresAt?: string;
  targetRoles?: UserRole[];
  dismissible: boolean;
}): Promise<{ ok: true; id: string } | { ok: false; error: string }> {
  try {
    const actor = await assertAdminByIdToken(input.idToken);
    const ref = adminDb.collection('announcements').doc();

    const announcement: Announcement = {
      id: ref.id,
      title: input.title,
      body: input.body,
      type: input.type,
      isActive: input.isActive,
      priority: 0,
      expiresAt: input.expiresAt,
      targetRoles: input.targetRoles,
      createdAt: new Date().toISOString(),
      createdBy: actor.uid,
      dismissible: input.dismissible,
    };
    await ref.set(announcement);

    await logAdminAction({
      actorId: actor.uid,
      actorName: actor.name,
      action: 'announcement.create',
      target: { type: 'system', id: ref.id, name: input.title },
    });

    return { ok: true, id: ref.id };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === 'FORBIDDEN' || msg === 'UNAUTHORIZED') return { ok: false, error: 'Недостаточно прав' };
    console.error('[createAnnouncementAction]', e);
    return { ok: false, error: 'Ошибка создания объявления' };
  }
}

export async function updateAnnouncementAction(input: {
  idToken: string;
  id: string;
  patch: Partial<Pick<Announcement, 'title' | 'body' | 'type' | 'isActive' | 'expiresAt' | 'dismissible'>>;
}): Promise<{ ok: true } | { ok: false; error: string }> {
  try {
    const actor = await assertAdminByIdToken(input.idToken);

    await adminDb.collection('announcements').doc(input.id).update(input.patch);

    await logAdminAction({
      actorId: actor.uid,
      actorName: actor.name,
      action: 'announcement.update',
      target: { type: 'system', id: input.id },
      details: { patch: Object.keys(input.patch) },
    });

    return { ok: true };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === 'FORBIDDEN' || msg === 'UNAUTHORIZED') return { ok: false, error: 'Недостаточно прав' };
    console.error('[updateAnnouncementAction]', e);
    return { ok: false, error: 'Ошибка обновления' };
  }
}

export async function deleteAnnouncementAction(input: {
  idToken: string;
  id: string;
}): Promise<{ ok: true } | { ok: false; error: string }> {
  try {
    const actor = await assertAdminByIdToken(input.idToken);
    await adminDb.collection('announcements').doc(input.id).delete();

    await logAdminAction({
      actorId: actor.uid,
      actorName: actor.name,
      action: 'announcement.update',
      target: { type: 'system', id: input.id },
      details: { deleted: true },
    });

    return { ok: true };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === 'FORBIDDEN' || msg === 'UNAUTHORIZED') return { ok: false, error: 'Недостаточно прав' };
    console.error('[deleteAnnouncementAction]', e);
    return { ok: false, error: 'Ошибка удаления' };
  }
}
