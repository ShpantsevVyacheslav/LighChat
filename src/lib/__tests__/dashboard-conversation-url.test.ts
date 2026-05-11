import { describe, expect, it } from 'vitest';
import {
  buildDashboardChatOpenUrl,
  isDashboardChatUtilityPath,
  getEffectiveDashboardConversationId,
  buildPathWithConversation,
} from '@/lib/dashboard-conversation-url';

/**
 * [audit M-013] URL builder/parser, через который весь UI открывает чаты
 * и навигирует к сообщениям/тредам/профилям. Если когда-то регрессия
 * подменяет имя query-параметра — все deep-link'и сломаются молча.
 * Тесты фиксируют контракт.
 */

describe('buildDashboardChatOpenUrl', () => {
  it('минимальный URL только с conversationId', () => {
    expect(buildDashboardChatOpenUrl('c1')).toBe('/dashboard/chat?conversationId=c1');
  });

  it('добавляет focusMessageId', () => {
    expect(
      buildDashboardChatOpenUrl('c1', { focusMessageId: 'm42' }),
    ).toBe('/dashboard/chat?conversationId=c1&focusMessageId=m42');
  });

  it('добавляет threadRootMessageId', () => {
    expect(
      buildDashboardChatOpenUrl('c1', { threadRootMessageId: 't9' }),
    ).toBe('/dashboard/chat?conversationId=c1&threadRootMessageId=t9');
  });

  it('openProfile становится "1"', () => {
    expect(
      buildDashboardChatOpenUrl('c1', { openProfile: true }),
    ).toBe('/dashboard/chat?conversationId=c1&openProfile=1');
  });

  it('openProfile=false не добавляет параметр', () => {
    expect(
      buildDashboardChatOpenUrl('c1', { openProfile: false }),
    ).toBe('/dashboard/chat?conversationId=c1');
  });

  it('profileUserId + profileSource', () => {
    expect(
      buildDashboardChatOpenUrl('c1', {
        profileUserId: 'u7',
        profileSource: 'mention',
      }),
    ).toBe('/dashboard/chat?conversationId=c1&profileUserId=u7&profileSource=mention');
  });

  it('невалидный profileSource фильтруется (security: enum-allowlist)', () => {
    // Это важно: если в URL прокинуть произвольный source — он не должен
    // попасть в готовую ссылку. Защита от reflected-XSS через query.
    expect(
      buildDashboardChatOpenUrl('c1', {
        profileSource: 'evil' as unknown as 'contacts',
      }),
    ).toBe('/dashboard/chat?conversationId=c1');
  });

  it('null/undefined options не добавляются', () => {
    expect(
      buildDashboardChatOpenUrl('c1', {
        focusMessageId: null,
        threadRootMessageId: null,
        profileUserId: null,
        gameId: null,
      }),
    ).toBe('/dashboard/chat?conversationId=c1');
  });

  it('gameId', () => {
    expect(
      buildDashboardChatOpenUrl('c1', { gameId: 'g5' }),
    ).toBe('/dashboard/chat?conversationId=c1&gameId=g5');
  });

  it('экранирует спецсимволы в conversationId', () => {
    // dm_aa:bb должен попасть как dm_aa%3Abb (URLSearchParams)
    expect(buildDashboardChatOpenUrl('dm_aa:bb')).toBe(
      '/dashboard/chat?conversationId=dm_aa%3Abb',
    );
  });
});

describe('isDashboardChatUtilityPath', () => {
  it('false для базового /dashboard/chat', () => {
    expect(isDashboardChatUtilityPath('/dashboard/chat')).toBe(false);
  });

  it('true для /dashboard/chat/forward', () => {
    expect(isDashboardChatUtilityPath('/dashboard/chat/forward')).toBe(true);
  });

  it('true для /dashboard/chat/c1/delete', () => {
    expect(isDashboardChatUtilityPath('/dashboard/chat/c1/delete')).toBe(true);
  });

  it('false для /dashboard/profile', () => {
    expect(isDashboardChatUtilityPath('/dashboard/profile')).toBe(false);
  });

  it('false для /dashboard/contacts', () => {
    expect(isDashboardChatUtilityPath('/dashboard/contacts')).toBe(false);
  });
});

describe('getEffectiveDashboardConversationId', () => {
  const params = (q: string): URLSearchParams => new URLSearchParams(q);

  it('возвращает conversationId из query на /dashboard/chat', () => {
    expect(
      getEffectiveDashboardConversationId('/dashboard/chat', params('conversationId=c1')),
    ).toBe('c1');
  });

  it('null на utility path /dashboard/chat/forward', () => {
    expect(
      getEffectiveDashboardConversationId(
        '/dashboard/chat/forward',
        params('conversationId=c1'),
      ),
    ).toBeNull();
  });

  it('null если query пуст', () => {
    expect(getEffectiveDashboardConversationId('/dashboard/chat', params(''))).toBeNull();
  });
});

describe('buildPathWithConversation', () => {
  it('добавляет conversationId к пустому query', () => {
    expect(buildPathWithConversation('/dashboard/chat', '', 'c1')).toBe(
      '/dashboard/chat?conversationId=c1',
    );
  });

  it('заменяет существующий conversationId', () => {
    expect(
      buildPathWithConversation('/dashboard/chat', 'conversationId=old', 'new'),
    ).toBe('/dashboard/chat?conversationId=new');
  });

  it('удаляет conversationId если null', () => {
    expect(
      buildPathWithConversation('/dashboard/chat', 'conversationId=c1&foo=bar', null),
    ).toBe('/dashboard/chat?foo=bar');
  });

  it('сохраняет другие query-параметры', () => {
    expect(
      buildPathWithConversation('/dashboard/chat', 'foo=bar', 'c1'),
    ).toBe('/dashboard/chat?foo=bar&conversationId=c1');
  });

  it('пустой query при удалении единственного параметра — без `?`', () => {
    expect(
      buildPathWithConversation('/dashboard/chat', 'conversationId=c1', null),
    ).toBe('/dashboard/chat');
  });
});
