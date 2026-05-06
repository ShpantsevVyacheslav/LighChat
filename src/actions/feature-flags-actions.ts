'use server';

import { adminDb } from '@/firebase/admin';
import { assertAdminByIdToken } from '@/actions/admin-actions';
import { logAdminAction } from '@/lib/server/audit-log';
import type { FeatureFlag } from '@/lib/types';

export async function setFeatureFlagAction(input: {
  idToken: string;
  flagName: string;
  enabled: boolean;
  description?: string;
}): Promise<{ ok: true } | { ok: false; error: string }> {
  try {
    const actor = await assertAdminByIdToken(input.idToken);

    const flag: FeatureFlag = {
      enabled: input.enabled,
      description: input.description,
      updatedAt: new Date().toISOString(),
      updatedBy: actor.uid,
    };

    await adminDb.collection('platformSettings').doc('main').set(
      { featureFlags: { [input.flagName]: flag } },
      { merge: true }
    );

    await logAdminAction({
      actorId: actor.uid,
      actorName: actor.name,
      action: 'feature_flag.update',
      target: { type: 'system', id: input.flagName },
      details: { enabled: input.enabled },
    });

    return { ok: true };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === 'FORBIDDEN' || msg === 'UNAUTHORIZED') return { ok: false, error: 'Недостаточно прав' };
    console.error('[setFeatureFlagAction]', e);
    return { ok: false, error: 'Ошибка обновления флага' };
  }
}

export async function deleteFeatureFlagAction(input: {
  idToken: string;
  flagName: string;
}): Promise<{ ok: true } | { ok: false; error: string }> {
  try {
    const actor = await assertAdminByIdToken(input.idToken);

    const { FieldValue } = await import('firebase-admin/firestore');
    await adminDb.collection('platformSettings').doc('main').update({
      [`featureFlags.${input.flagName}`]: FieldValue.delete(),
    });

    await logAdminAction({
      actorId: actor.uid,
      actorName: actor.name,
      action: 'feature_flag.update',
      target: { type: 'system', id: input.flagName },
      details: { deleted: true },
    });

    return { ok: true };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === 'FORBIDDEN' || msg === 'UNAUTHORIZED') return { ok: false, error: 'Недостаточно прав' };
    console.error('[deleteFeatureFlagAction]', e);
    return { ok: false, error: 'Ошибка удаления флага' };
  }
}
