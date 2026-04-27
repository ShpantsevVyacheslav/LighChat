import type { AppMessages } from '@/lib/i18n/messages/en';

export function translate(
  messages: AppMessages,
  path: string,
  params?: Record<string, string | number>
): string {
  const keys = path.split('.');
  let node: unknown = messages;
  for (const k of keys) {
    if (node === null || typeof node !== 'object') return path;
    node = (node as Record<string, unknown>)[k];
  }
  if (typeof node !== 'string') return path;
  if (!params) return node;
  return node.replace(/\{(\w+)\}/g, (_, name: string) =>
    params[name] !== undefined ? String(params[name]) : `{${name}}`
  );
}
