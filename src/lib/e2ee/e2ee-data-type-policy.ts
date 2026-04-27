import type { E2eeEncryptedDataTypes } from '@/lib/types';

export const DEFAULT_E2EE_ENCRYPTED_DATA_TYPES: E2eeEncryptedDataTypes = {
  text: true,
  media: true,
  replyPreview: true, // derived (== text), kept for backward compatibility
};

export function parseE2eeEncryptedDataTypes(raw: unknown): E2eeEncryptedDataTypes {
  if (!raw || typeof raw !== 'object') return DEFAULT_E2EE_ENCRYPTED_DATA_TYPES;
  const m = raw as Record<string, unknown>;
  const read = (k: keyof E2eeEncryptedDataTypes) =>
    typeof m[k] === 'boolean' ? (m[k] as boolean) : DEFAULT_E2EE_ENCRYPTED_DATA_TYPES[k];
  const text = read('text');
  return {
    text,
    media: read('media'),
    // Reply preview follows text encryption automatically.
    replyPreview: text,
  };
}

export function resolveEffectiveE2eeEncryptedDataTypes(opts: {
  global: E2eeEncryptedDataTypes;
  override?: E2eeEncryptedDataTypes | null;
}): E2eeEncryptedDataTypes {
  const eff = opts.override ?? opts.global;
  return { ...eff, replyPreview: eff.text };
}

