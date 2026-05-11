import { describe, expect, it } from 'vitest';
import {
  chatDraftStorageKey,
  chatDraftPlainFromHtml,
} from '@/lib/chat-message-draft-storage';

/**
 * [audit M-013] Pure helpers из draft-storage. Тесты на localStorage
 * операции пропущены — требуют jsdom (`npm i -D jsdom` отдельной задачей).
 */

describe('chatDraftStorageKey', () => {
  it('включает namespace + userId', () => {
    expect(chatDraftStorageKey('alice')).toBe('lighchat:chatDrafts:v1:alice');
    expect(chatDraftStorageKey('bob')).toBe('lighchat:chatDrafts:v1:bob');
  });

  it('версия v1 в namespace — для будущей миграции', () => {
    expect(chatDraftStorageKey('u')).toContain(':v1:');
  });

  it('SECURITY: разные uid → разные keys (изоляция между юзерами)', () => {
    expect(chatDraftStorageKey('alice')).not.toBe(chatDraftStorageKey('bob'));
  });
});

describe('chatDraftPlainFromHtml', () => {
  it('strip простой HTML', () => {
    expect(chatDraftPlainFromHtml('<p>Hello world</p>')).toBe('Hello world');
  });

  it('strip nested tags', () => {
    expect(chatDraftPlainFromHtml('<p><strong>Bold</strong> <em>italic</em></p>')).toBe('Bold italic');
  });

  it('пустой HTML → пустая строка', () => {
    expect(chatDraftPlainFromHtml('')).toBe('');
  });

  it('strip self-closing tags', () => {
    expect(chatDraftPlainFromHtml('Line1<br/>Line2')).toMatch(/Line1.*Line2/);
  });

  it('SECURITY: не выполняет script (просто strip тегов)', () => {
    // Это plain text extractor, не sanitizer — но если script-теги
    // попадут в HTML, они должны быть просто удалены вместе с тегами.
    const dangerous = '<script>alert(1)</script>безопасно';
    const r = chatDraftPlainFromHtml(dangerous);
    expect(r).not.toContain('<script>');
    expect(r).not.toContain('</script>');
  });
});
