import type { E2eeEncryptedDataTypes } from '@/lib/types';

export const DEFAULT_E2EE_ENCRYPTED_DATA_TYPES: E2eeEncryptedDataTypes = {
  text: true,
  media: true,
  replyPreview: true,
};

export function parseE2eeEncryptedDataTypes(raw: unknown): E2eeEncryptedDataTypes {
  if (!raw || typeof raw !== 'object') return DEFAULT_E2EE_ENCRYPTED_DATA_TYPES;
  const m = raw as Record<string, unknown>;
  const read = (k: keyof E2eeEncryptedDataTypes) =>
    typeof m[k] === 'boolean' ? (m[k] as boolean) : DEFAULT_E2EE_ENCRYPTED_DATA_TYPES[k];
  return {
    text: read('text'),
    media: read('media'),
    replyPreview: read('replyPreview'),
  };
}

export function resolveEffectiveE2eeEncryptedDataTypes(opts: {
  global: E2eeEncryptedDataTypes;
  override?: E2eeEncryptedDataTypes | null;
}): E2eeEncryptedDataTypes {
  return opts.override ?? opts.global;
}

