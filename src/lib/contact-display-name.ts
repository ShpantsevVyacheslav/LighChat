import type { UserContactLocalProfile } from '@/lib/types';

export function buildContactDisplayName(input: {
  firstName?: string | null;
  lastName?: string | null;
}): string {
  const first = (input.firstName ?? '').trim();
  const last = (input.lastName ?? '').trim();
  return [first, last].filter(Boolean).join(' ').trim();
}

export function resolveContactDisplayName(
  contactProfiles: Record<string, UserContactLocalProfile> | null | undefined,
  contactUserId: string | null | undefined,
  fallbackName: string
): string {
  const id = (contactUserId ?? '').trim();
  if (!id || !contactProfiles) return fallbackName;
  const local = contactProfiles[id];
  if (!local) return fallbackName;
  const display = (local.displayName ?? '').trim();
  if (display) return display;
  const composed = buildContactDisplayName({
    firstName: local.firstName,
    lastName: local.lastName,
  });
  return composed || fallbackName;
}

export function splitNameForContactForm(sourceName: string): {
  firstName: string;
  lastName: string;
} {
  const normalized = sourceName.replace(/\s+/g, ' ').trim();
  if (!normalized) return { firstName: '', lastName: '' };
  const parts = normalized.split(' ');
  if (parts.length === 1) return { firstName: parts[0] ?? '', lastName: '' };
  return {
    firstName: parts.slice(0, 1).join(' ').trim(),
    lastName: parts.slice(1).join(' ').trim(),
  };
}
