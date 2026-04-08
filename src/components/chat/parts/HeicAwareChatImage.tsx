'use client';

import type { ComponentPropsWithoutRef } from 'react';
import type { ChatAttachment } from '@/lib/types';
import { useChatAttachmentDisplaySrc } from '@/components/chat/use-chat-attachment-display-src';

type HeicAwareChatImageProps = Omit<ComponentPropsWithoutRef<'img'>, 'src'> & {
  attachment: ChatAttachment;
};

/**
 * `<img>` для вложения чата: HEIC/HEIF подменяется на PNG в памяти, чтобы не показывать битую иконку.
 */
export function HeicAwareChatImage({ attachment, alt = '', ...rest }: HeicAwareChatImageProps) {
  const src = useChatAttachmentDisplaySrc(attachment);
  return <img src={src} alt={alt} {...rest} />;
}
