import { NextResponse, type NextRequest } from 'next/server';
import admin from 'firebase-admin';

import { adminAuth, adminDb } from '@/firebase/admin';
import { logger } from '@/lib/logger';

/**
 * Server-side analytics ingest. Принимает события из:
 *   1) Web клиента — двойная запись для критичных конверсий и фолбэк под Safari ITP / AdBlock.
 *   2) Flutter Windows/Linux desktop — где `firebase_analytics` SDK не доступен.
 *
 * Контракт:
 *   POST application/json {
 *     event:    snake_case enum-имя (валидируется по AnalyticsEvents);
 *     params:   плоский объект string/number/bool;
 *     platform: "web"|"pwa"|"ios"|"android"|"macos"|"windows"|"linux";
 *     ts:       Date.now() миллисекунды;
 *     idToken:  Firebase ID-токен; опционально (для анонимных событий).
 *   }
 *
 * Безопасность:
 *   - валидируется enum (whitelist) — клиент не может писать произвольные имена;
 *   - PII в params не проверяется по содержимому (доверяем code-review), но имя
 *     события — проверяется;
 *   - rate-limit per-uid: max 60 событий/мин (in-memory soft limit — для строгой
 *     защиты от спама endpoint всё равно прячется за App Check на проде).
 */

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const ALLOWED_EVENTS = new Set<string>([
  // mirror of src/lib/analytics/events.ts AnalyticsEvents values
  'app_first_open', 'landing_view', 'cta_click', 'auth_screen_view',
  'sign_up_attempt', 'sign_up_success', 'sign_up_failure',
  'login_attempt', 'login_success', 'login_failure',
  'profile_completion_step', 'pwa_install_prompt_shown', 'pwa_installed',
  'chat_created', 'chat_opened', 'message_sent', 'message_first_sent_in_chat',
  'reaction_added', 'poll_created', 'call_started', 'call_ended',
  'meeting_created', 'meeting_joined', 'meeting_left',
  'game_started', 'game_finished', 'secret_chat_enabled', 'e2ee_pairing_completed',
  'contact_added', 'file_shared', 'voice_message_recorded', 'settings_changed',
  'page_view', 'screen_view', 'search_performed',
  'notification_received', 'notification_opened', 'deep_link_opened', 'tab_switched',
  'session_start', 'app_open', 'app_backgrounded', 'crash',
  'feature_unavailable', 'permission_prompt', 'app_update_available', 'app_updated',
  'contact_shared', 'chat_invite_link_created', 'chat_invite_link_opened',
  'chat_invite_link_redeemed', 'external_invite_sent', 'external_invite_accepted',
  'referral_signup', 'meeting_guest_joined', 'meeting_guest_count', 'qr_scanned',
  'error_occurred', 'network_offline_entered', 'network_offline_exited',
  'firestore_permission_denied', 'media_upload_failure', 'call_connection_failure',
  'call_quality_report', 'webrtc_reconnect', 'push_delivery_failed', 'e2ee_failure',
  'language_changed', 'theme_changed', 'notification_settings_changed',
  'account_deleted', 'logout',
  'message_edited', 'message_deleted', 'message_pinned', 'message_forwarded',
  'message_replied', 'voice_message_played', 'media_viewed', 'media_downloaded',
  'search_zero_results', 'message_translated',
  'screen_share_started', 'screen_share_stopped', 'mic_toggled', 'camera_toggled',
  'bg_blur_toggled', 'meeting_poll_voted',
  'meeting_join_request_sent', 'meeting_join_request_decision',
  'paywall_viewed', 'plan_selected', 'purchase_started', 'purchase_completed',
  'purchase_failed', 'subscription_renewed', 'subscription_cancelled',
  'storage_quota_warning', 'storage_quota_exceeded',
  'bot_command_used', 'bot_added_to_chat', 'feature_flag_exposed',
  'csp_violation_received', 'admin_action_performed',
]);

const ALLOWED_PLATFORMS = new Set(['web', 'pwa', 'ios', 'android', 'macos', 'windows', 'linux']);

const rateBuckets = new Map<string, { count: number; resetAt: number }>();
const RATE_LIMIT_PER_MIN = 120;

function rateLimit(key: string): boolean {
  const now = Date.now();
  const b = rateBuckets.get(key);
  if (!b || b.resetAt < now) {
    rateBuckets.set(key, { count: 1, resetAt: now + 60_000 });
    return true;
  }
  b.count += 1;
  return b.count <= RATE_LIMIT_PER_MIN;
}

export async function POST(req: NextRequest): Promise<NextResponse> {
  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: 'invalid_json' }, { status: 400 });
  }

  if (!body || typeof body !== 'object') {
    return NextResponse.json({ error: 'invalid_body' }, { status: 400 });
  }

  const { event, params, platform, ts, idToken } = body as {
    event?: unknown;
    params?: unknown;
    platform?: unknown;
    ts?: unknown;
    idToken?: unknown;
  };

  if (typeof event !== 'string' || !ALLOWED_EVENTS.has(event)) {
    return NextResponse.json({ error: 'unknown_event' }, { status: 400 });
  }
  if (typeof platform !== 'string' || !ALLOWED_PLATFORMS.has(platform)) {
    return NextResponse.json({ error: 'invalid_platform' }, { status: 400 });
  }

  let uid: string | null = null;
  if (typeof idToken === 'string' && idToken.length > 0) {
    try {
      const decoded = await adminAuth.verifyIdToken(idToken);
      uid = decoded.uid;
    } catch {
      // не валим запрос — событие пишется анонимно
    }
  }

  const rateKey = uid ?? req.headers.get('x-forwarded-for') ?? 'anon';
  if (!rateLimit(rateKey)) {
    return new NextResponse(null, { status: 204 });
  }

  const tsNum = typeof ts === 'number' && Number.isFinite(ts) ? ts : Date.now();
  const safeParams = sanitizeParams(params);

  try {
    await adminDb.collection('analyticsEvents').add({
      event,
      params: safeParams,
      platform,
      uid,
      ts: new Date(tsNum).toISOString(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      source: 'web_client',
    });
  } catch (e) {
    logger.error('analytics-api', 'failed to write event', e);
    return new NextResponse(null, { status: 204 });
  }

  return new NextResponse(null, { status: 204 });
}

function sanitizeParams(params: unknown): Record<string, string | number | boolean | null> {
  if (!params || typeof params !== 'object') return {};
  const out: Record<string, string | number | boolean | null> = {};
  for (const [k, v] of Object.entries(params as Record<string, unknown>)) {
    if (typeof k !== 'string' || k.length > 40) continue;
    if (v === null) {
      out[k] = null;
    } else if (typeof v === 'string') {
      out[k] = v.slice(0, 100);
    } else if (typeof v === 'number' || typeof v === 'boolean') {
      out[k] = v;
    }
    // any other shape → drop
  }
  return out;
}
