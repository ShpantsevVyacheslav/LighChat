import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { describe, expect, it, vi } from 'vitest';
import { ChatMessageItem } from '@/components/chat/ChatMessageItem';
import type {
  ChatAttachment,
  ChatMessage,
  Conversation,
  ReplyContext,
  User,
} from '@/lib/types';

function buildBaseConversation(): Conversation {
  return {
    id: 'c1',
    isGroup: false,
    adminIds: ['u1'],
    participantIds: ['u1', 'u2'],
    participantInfo: {
      u1: { name: 'Alice' },
      u2: { name: 'Bob' },
    },
  };
}

function buildBaseUsers(): { currentUser: User; allUsers: User[] } {
  const currentUser: User = {
    id: 'u2',
    name: 'Bob',
    username: 'bob',
    email: 'bob@example.com',
    avatar: '',
    phone: '',
    deletedAt: null,
    createdAt: '2026-05-07T00:00:00.000Z',
  };
  const sender: User = {
    id: 'u1',
    name: 'Alice',
    username: 'alice',
    email: 'alice@example.com',
    avatar: '',
    phone: '',
    deletedAt: null,
    createdAt: '2026-05-07T00:00:00.000Z',
  };
  return { currentUser, allUsers: [sender, currentUser] };
}

function buildMessage(attachment: ChatAttachment): ChatMessage {
  return {
    id: 'm1',
    senderId: 'u1',
    createdAt: '2026-05-07T10:00:00.000Z',
    readAt: null,
    text: '',
    attachments: [attachment],
    reactions: {},
  };
}

function renderMessageItem(message: ChatMessage): string {
  const { currentUser, allUsers } = buildBaseUsers();
  const conversation = buildBaseConversation();
  return renderToStaticMarkup(
    React.createElement(ChatMessageItem, {
      message,
      currentUser,
      allUsers,
      conversation,
      isSelected: false,
      isSelectionActive: false,
      editingMessage: null as { id: string; text: string; attachments?: ChatAttachment[] } | null,
      onToggleSelection: vi.fn(),
      onEdit: vi.fn(),
      onUpdateMessage: async () => undefined,
      onDelete: vi.fn(),
      onCopy: vi.fn(),
      onPin: vi.fn(),
      onReply: vi.fn((_: ReplyContext) => undefined),
      onForward: vi.fn(),
      onNavigateToMessage: vi.fn(),
      onOpenImageViewer: vi.fn(),
      onOpenVideoViewer: vi.fn(),
      onReact: vi.fn(),
    }),
  );
}

describe('ChatMessageItem file attachments', () => {
  it('renders a document row for non-media files (pdf)', () => {
    const message = buildMessage({
      url: 'https://example.com/report.pdf',
      name: 'report.pdf',
      type: 'application/pdf',
      size: 2048,
    });

    const html = renderMessageItem(message);

    expect(html).toContain('report.pdf');
    expect(html).toContain('2.0 KB');
  });
});

