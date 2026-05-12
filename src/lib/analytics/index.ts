'use client';

import type { FirebaseApp } from 'firebase/app';
import type { Auth } from 'firebase/auth';

import { logger } from '@/lib/logger';
import {
  AnalyticsEvents,
  type AnalyticsEventName,
  type AnalyticsParams,
  type Platform,
  type UserPropertyName,
  detectWebPlatform,
} from './events';
import { fbLogEvent, fbSetCollectionEnabled, fbSetUserId, fbSetUserProperty } from './firebase-sink';
import { serverLogEvent } from './server-sink';

const CONSENT_KEY = 'lc_cookie_consent_v1';

export type Consent = 'all' | 'required' | null;

type AnalyticsState = {
  app: FirebaseApp | null;
  auth: Auth | null;
  consent: Consent;
  platform: Platform;
  appVersion: string;
  locale: string;
  /** Set когда `chat_opened` уже был залогирован хотя бы раз для конкретного chatId. */
  openedChats: Set<string>;
};

const state: AnalyticsState = {
  app: null,
  auth: null,
  consent: null,
  platform: 'web',
  appVersion: process.env.NEXT_PUBLIC_APP_VERSION ?? 'dev',
  locale: typeof navigator !== 'undefined' ? navigator.language.slice(0, 2) : 'en',
  openedChats: new Set(),
};

function readConsent(): Consent {
  if (typeof window === 'undefined') return null;
  try {
    const v = window.localStorage.getItem(CONSENT_KEY);
    return v === 'all' || v === 'required' ? v : null;
  } catch {
    return null;
  }
}

/** Стартует на bootstrap — но реально ничего не делает, пока consent не получен. */
export function initAnalytics(opts: { app: FirebaseApp; auth: Auth }): void {
  state.app = opts.app;
  state.auth = opts.auth;
  state.platform = detectWebPlatform();
  state.consent = readConsent();
  if (state.consent === 'all') {
    void fbSetCollectionEnabled(opts.app, true);
  }
}

/** Вызывает cookie-banner после accept. */
export function setConsent(decision: 'all' | 'required'): void {
  state.consent = decision;
  if (!state.app) return;
  if (decision === 'all') {
    void fbSetCollectionEnabled(state.app, true);
    // Сразу засветим session_start — иначе первое событие отстаёт.
    track(AnalyticsEvents.sessionStart, {});
  } else {
    void fbSetCollectionEnabled(state.app, false);
  }
}

function withCommonParams(params: AnalyticsParams): AnalyticsParams {
  return {
    ...params,
    platform: state.platform,
    app_version: state.appVersion,
    locale: state.locale,
  };
}

/** Список событий, которые отправляются даже при consent='required' (server-side). */
const ALWAYS_SERVER_EVENTS = new Set<AnalyticsEventName>([
  AnalyticsEvents.signUpSuccess,
  AnalyticsEvents.signUpFailure,
  AnalyticsEvents.loginSuccess,
  AnalyticsEvents.errorOccurred,
  AnalyticsEvents.accountDeleted,
  AnalyticsEvents.purchaseCompleted,
  AnalyticsEvents.purchaseFailed,
]);

export function track(event: AnalyticsEventName, params: AnalyticsParams = {}): void {
  const enriched = withCommonParams(params);

  if (state.consent === 'all' && state.app) {
    void fbLogEvent(state.app, event, enriched);
  }

  if (state.consent === 'all' || (state.consent === 'required' && ALWAYS_SERVER_EVENTS.has(event))) {
    const idToken$ = state.auth?.currentUser?.getIdToken().catch(() => null) ?? Promise.resolve(null);
    void idToken$.then((tok) => serverLogEvent(event, enriched, tok, state.platform));
  } else {
    logger.debug('analytics', `dropped ${event}: no consent`);
  }
}

export function identify(uid: string | null): void {
  if (!state.app) return;
  if (state.consent === 'all') {
    void fbSetUserId(state.app, uid);
  }
}

export function setUserProperty(
  name: UserPropertyName,
  value: string | number | boolean | null,
): void {
  if (!state.app) return;
  if (state.consent === 'all') {
    void fbSetUserProperty(state.app, name, value);
  }
}

/** Идемпотентный хелпер: первое открытие конкретного чата → `is_first_open=true`. */
export function trackChatOpened(chatId: string, params: AnalyticsParams = {}): void {
  const isFirst = !state.openedChats.has(chatId);
  state.openedChats.add(chatId);
  track(AnalyticsEvents.chatOpened, { ...params, is_first_open: isFirst });
}

export { AnalyticsEvents } from './events';
