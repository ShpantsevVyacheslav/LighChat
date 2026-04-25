import { cookies } from "next/headers";
import { NextRequest, NextResponse } from "next/server";

import {
  yandexExchangeAuthorizationCode,
  yandexFetchLoginInfo,
} from "@/lib/server/yandex-oauth";
import { issueFirebaseCustomTokenForYandexProfile } from "@/lib/server/yandex-firebase-custom-token";

export const runtime = "nodejs";

const STATE_COOKIE = "lc_yndx_state";

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

function publicOrigin(request: NextRequest): string {
  const forwardedProto = request.headers.get("x-forwarded-proto");
  const forwardedHost = request.headers.get("x-forwarded-host");
  if (forwardedHost) {
    const proto = forwardedProto?.split(",")[0]?.trim() || "https";
    return `${proto}://${forwardedHost.split(",")[0].trim()}`;
  }
  return request.nextUrl.origin;
}

function redirectWithError(request: NextRequest, code: string): NextResponse {
  const origin = publicOrigin(request);
  const url = new URL("/", origin);
  url.searchParams.set("yandex_error", code);
  const res = NextResponse.redirect(url);
  res.cookies.delete(STATE_COOKIE);
  return res;
}

/**
 * Callback Яндекс OAuth: обмен code, выпуск Firebase custom token, редирект на /auth/yandex#customToken=…
 */
export async function GET(request: NextRequest) {
  try {
    const clientId = getYandexClientId();
    const clientSecret = getYandexClientSecret();
    if (!clientId || !clientSecret) {
      return redirectWithError(request, "not_configured");
    }

    const url = request.nextUrl;
    const err = url.searchParams.get("error");
    if (err) {
      return redirectWithError(request, err);
    }

    const code = url.searchParams.get("code");
    const state = url.searchParams.get("state");
    if (!code || !state) {
      return redirectWithError(request, "missing_code");
    }

    const jar = cookies();
    const expected = jar.get(STATE_COOKIE)?.value;
    if (!expected || expected !== state) {
      return redirectWithError(request, "bad_state");
    }

    const origin = publicOrigin(request);
    const redirectUri = `${origin}/api/auth/yandex/callback`;

    const { access_token } = await yandexExchangeAuthorizationCode({
      code,
      clientId,
      clientSecret,
      redirectUri,
    });
    const info = await yandexFetchLoginInfo(access_token);
    const { customToken } = await issueFirebaseCustomTokenForYandexProfile(info);

    const finish = new URL("/auth/yandex", origin);
    finish.hash = `customToken=${encodeURIComponent(customToken)}`;
    const res = NextResponse.redirect(finish.toString());
    res.cookies.delete(STATE_COOKIE);
    return res;
  } catch (e: unknown) {
    console.error("[yandex/callback] unhandled error", e);
    return redirectWithError(request, "server");
  }
}
