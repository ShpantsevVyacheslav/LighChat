import type { ComponentType } from 'react';
import type { LucideIcon } from 'lucide-react';
import {
  Lock,
  Timer,
  EyeOff,
  Clock,
  Gamepad2,
  Video,
  Phone,
  Folders,
  MapPin,
  Smartphone,
  Sticker,
  Shield,
} from 'lucide-react';

import { MockEncryption } from './illustrations/encryption';
import { MockSecretChats } from './illustrations/secret-chats';
import { MockDisappearing } from './illustrations/disappearing-messages';
import { MockScheduled } from './illustrations/scheduled-messages';
import { MockGames } from './illustrations/games';
import { MockMeetings } from './illustrations/meetings';
import { MockCalls } from './illustrations/calls';
import { MockFoldersThreads } from './illustrations/folders-threads';
import { MockLiveLocation } from './illustrations/live-location';
import { MockMultiDevice } from './illustrations/multi-device';
import { MockStickersMedia } from './illustrations/stickers-media';
import { MockPrivacy } from './illustrations/privacy';

export type FeatureTopicId =
  | 'encryption'
  | 'secret-chats'
  | 'disappearing-messages'
  | 'scheduled-messages'
  | 'games'
  | 'meetings'
  | 'calls'
  | 'folders-threads'
  | 'live-location'
  | 'multi-device'
  | 'stickers-media'
  | 'privacy';

export type FeatureAccent = 'primary' | 'coral' | 'emerald' | 'violet' | 'amber';

export type FeatureTopic = {
  id: FeatureTopicId;
  Mock: ComponentType<{ className?: string; compact?: boolean }>;
  icon: LucideIcon;
  accent: FeatureAccent;
  ctaHref?: string;
  highlight?: boolean;
};

export const FEATURE_TOPICS: ReadonlyArray<FeatureTopic> = [
  {
    id: 'encryption',
    Mock: MockEncryption,
    icon: Lock,
    accent: 'emerald',
    ctaHref: '/dashboard/settings/devices',
    highlight: true,
  },
  {
    id: 'secret-chats',
    Mock: MockSecretChats,
    icon: Timer,
    accent: 'violet',
    ctaHref: '/dashboard/chat',
    highlight: true,
  },
  {
    id: 'disappearing-messages',
    Mock: MockDisappearing,
    icon: EyeOff,
    accent: 'coral',
    ctaHref: '/dashboard/chat',
    highlight: true,
  },
  {
    id: 'scheduled-messages',
    Mock: MockScheduled,
    icon: Clock,
    accent: 'primary',
    ctaHref: '/dashboard/chat',
    highlight: true,
  },
  {
    id: 'games',
    Mock: MockGames,
    icon: Gamepad2,
    accent: 'amber',
    ctaHref: '/dashboard/chat',
    highlight: true,
  },
  {
    id: 'meetings',
    Mock: MockMeetings,
    icon: Video,
    accent: 'primary',
    ctaHref: '/dashboard/meetings',
  },
  {
    id: 'calls',
    Mock: MockCalls,
    icon: Phone,
    accent: 'emerald',
    ctaHref: '/dashboard/calls',
  },
  {
    id: 'folders-threads',
    Mock: MockFoldersThreads,
    icon: Folders,
    accent: 'violet',
    ctaHref: '/dashboard/chat',
  },
  {
    id: 'live-location',
    Mock: MockLiveLocation,
    icon: MapPin,
    accent: 'coral',
    ctaHref: '/dashboard/chat',
  },
  {
    id: 'multi-device',
    Mock: MockMultiDevice,
    icon: Smartphone,
    accent: 'primary',
    ctaHref: '/dashboard/settings/devices',
  },
  {
    id: 'stickers-media',
    Mock: MockStickersMedia,
    icon: Sticker,
    accent: 'amber',
    ctaHref: '/dashboard/chat',
  },
  {
    id: 'privacy',
    Mock: MockPrivacy,
    icon: Shield,
    accent: 'primary',
    ctaHref: '/dashboard/settings/privacy',
  },
] as const;

export const FEATURE_TOPICS_BY_ID: Record<FeatureTopicId, FeatureTopic> =
  FEATURE_TOPICS.reduce((acc, t) => {
    acc[t.id] = t;
    return acc;
  }, {} as Record<FeatureTopicId, FeatureTopic>);

export function isFeatureTopicId(value: string): value is FeatureTopicId {
  return value in FEATURE_TOPICS_BY_ID;
}

export const FEATURE_TOPIC_IDS: ReadonlyArray<FeatureTopicId> = FEATURE_TOPICS.map((t) => t.id);

/**
 * Tailwind-классы для акцентов. Подобраны под существующую палитру (см.
 * `globals.css` и `tailwind.config.ts`). Все цвета — пары для светлой/тёмной темы.
 */
export const ACCENT_CLASSES: Record<
  FeatureAccent,
  { ring: string; tint: string; text: string; gradient: string }
> = {
  primary: {
    ring: 'ring-primary/30',
    tint: 'bg-primary/10',
    text: 'text-primary',
    gradient: 'from-primary/40 via-primary/10 to-transparent',
  },
  coral: {
    ring: 'ring-rose-400/30',
    tint: 'bg-rose-400/10',
    text: 'text-rose-400',
    gradient: 'from-rose-400/40 via-rose-300/10 to-transparent',
  },
  emerald: {
    ring: 'ring-emerald-400/30',
    tint: 'bg-emerald-400/10',
    text: 'text-emerald-400',
    gradient: 'from-emerald-400/40 via-emerald-300/10 to-transparent',
  },
  violet: {
    ring: 'ring-violet-400/30',
    tint: 'bg-violet-400/10',
    text: 'text-violet-400',
    gradient: 'from-violet-400/40 via-violet-300/10 to-transparent',
  },
  amber: {
    ring: 'ring-amber-400/30',
    tint: 'bg-amber-400/10',
    text: 'text-amber-400',
    gradient: 'from-amber-400/40 via-amber-300/10 to-transparent',
  },
};
