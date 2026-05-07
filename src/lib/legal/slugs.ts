export const LEGAL_SLUGS = [
  'privacy-policy',
  'terms-of-service',
  'cookie-policy',
  'eula',
  'data-processing-agreement',
  'children-policy',
  'content-moderation-policy',
  'acceptable-use-policy',
] as const;

export type LegalSlug = (typeof LEGAL_SLUGS)[number];

export function isLegalSlug(value: string): value is LegalSlug {
  return (LEGAL_SLUGS as readonly string[]).includes(value);
}
