'use server';

import { z } from 'zod';

import { adminDb } from '@/firebase/admin';
import { assertAdminByIdToken } from '@/actions/admin-actions';
import { logAdminAction } from '@/lib/server/audit-log';
import type { FeatureFlag } from '@/lib/types';

// SECURITY: flagName is interpolated into Firestore field paths
// (`featureFlags.${flagName}`) and used as a map key. A `.` in the value
// would split the dot-path and write to a NESTED key — for delete that means
// nuking an unintended subtree of platformSettings. A `/` would be rejected
// by Firestore but still surfaces as a 500. We restrict to a strict
// alphanumeric + underscore identifier with a length cap.
const FlagNameSchema = z
  .string()
  .trim()
  .min(1, 'flagName_required')
  .max(64, 'flagName_too_long')
  .regex(/^[a-zA-Z][a-zA-Z0-9_]*$/, 'flagName_invalid');

const SetFlagSchema = z.object({
  idToken: z.string().min(1),
  flagName: FlagNameSchema,
  enabled: z.boolean(),
  description: z.string().max(500).optional(),
});

const DeleteFlagSchema = z.object({
  idToken: z.string().min(1),
  flagName: FlagNameSchema,
});

export async function setFeatureFlagAction(input: {
  idToken: string;
  flagName: string;
  enabled: boolean;
  description?: string;
}): Promise<{ ok: true } | { ok: false; error: string }> {
  const parsed = SetFlagSchema.safeParse(input);
  if (!parsed.success) {
    return { ok: false, error: 'Некорректное имя флага' };
  }
  try {
    const actor = await assertAdminByIdToken(parsed.data.idToken);

    const flag: FeatureFlag = {
      enabled: parsed.data.enabled,
      description: parsed.data.description,
      updatedAt: new Date().toISOString(),
      updatedBy: actor.uid,
    };

    await adminDb.collection('platformSettings').doc('main').set(
      { featureFlags: { [parsed.data.flagName]: flag } },
      { merge: true }
    );

    await logAdminAction({
      actorId: actor.uid,
      actorName: actor.name,
      action: 'feature_flag.update',
      target: { type: 'system', id: parsed.data.flagName },
      details: { enabled: parsed.data.enabled },
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
  const parsed = DeleteFlagSchema.safeParse(input);
  if (!parsed.success) {
    return { ok: false, error: 'Некорректное имя флага' };
  }
  try {
    const actor = await assertAdminByIdToken(parsed.data.idToken);

    const { FieldValue } = await import('firebase-admin/firestore');
    await adminDb.collection('platformSettings').doc('main').update({
      [`featureFlags.${parsed.data.flagName}`]: FieldValue.delete(),
    });

    await logAdminAction({
      actorId: actor.uid,
      actorName: actor.name,
      action: 'feature_flag.update',
      target: { type: 'system', id: parsed.data.flagName },
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
