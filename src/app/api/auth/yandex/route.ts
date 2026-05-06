import { randomBytes } from "crypto";
import { NextRequest, NextResponse } from "next/server";

import { buildYandexAuthorizeUrl } from "@/lib/server/yandex-oauth";
import { resolvePublicOrigin } from "@/lib/server/public-origin";

export const runtime = "nodejs";

const STATE_COOKIE = "lc_yndx_state";
const STATE_MAX_AGE_SEC = 600;

function getYandexClientId(): string {
  return (
    process.env.YANDEX_CLIENT_ID ??
    process.env.NEXT_PUBLIC_YANDEX_CLIENT_ID ??
    ""
  ).trim();
}

function getYandexClientSecret(): string {
  return (process.env.YANDEX_CLIENT_SECRET ?? "").trim();
}

function getYandexScope(): string | undefined {
  const raw = (process.env.YANDEX_SCOPE ?? "").trim();
  return raw.length > 0 ? raw : undefined;
}

/**
 * Старт OAuth: редирект на Яндекс + HttpOnly cookie с state (CSRF).
 *
 * SECURITY: redirect_uri is built against the result of resolvePublicOrigin
 * (env-driven + static allow-list). Previously we trusted x-forwarded-host
 * unconditionally — a host-header-injection attacker could redirect Яндекс to
 * an attacker-owned host and steal the authorization code at callback.
 */
export async function GET(request: NextRequest) {
  const clientId = getYandexClientId();
  const clientSecret = getYandexClientSecret();
  if (!clientId || !clientSecret) {
    return NextResponse.json(
      {
        error:
          "Yandex OAuth is not configured (YANDEX_CLIENT_ID, YANDEX_CLIENT_SECRET).",
      },
      { status: 503 }
    );
  }

  const origin = resolvePublicOrigin(request);
  const redirectUri = `${origin}/api/auth/yandex/callback`;
  const state = randomBytes(24).toString("hex");
  const url = buildYandexAuthorizeUrl({
    clientId,
    redirectUri,
    state,
    scope: getYandexScope(),
  });

  const res = NextResponse.redirect(url);
  res.cookies.set(STATE_COOKIE, state, {
    httpOnly: true,
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
    path: "/",
    maxAge: STATE_MAX_AGE_SEC,
  });
  return res;
}
