import { NextRequest, NextResponse } from "next/server";
import { logger } from "@/lib/logger";

const MAX_BYTES = 6 * 1024 * 1024;
const FETCH_MS = 12_000;

function isAllowedWallpaperHost(hostname: string): boolean {
  const h = hostname.toLowerCase();
  if (h === "firebasestorage.googleapis.com") return true;
  if (h === "storage.googleapis.com") return true;
  if (h.endsWith(".firebasestorage.app")) return true;
  return false;
}

/**
 * Прокси изображения обоев для темы «Авто»: серверный fetch без CORS, клиент рисует same-origin ответ в canvas.
 */
export async function GET(req: NextRequest) {
  const raw = req.nextUrl.searchParams.get("url");
  if (!raw?.trim()) {
    return NextResponse.json({ error: "missing url" }, { status: 400 });
  }

  let target: URL;
  try {
    target = new URL(raw);
  } catch {
    return NextResponse.json({ error: "invalid url" }, { status: 400 });
  }

  if (target.protocol !== "https:" && target.protocol !== "http:") {
    return NextResponse.json({ error: "invalid protocol" }, { status: 400 });
  }

  if (!isAllowedWallpaperHost(target.hostname)) {
    return NextResponse.json({ error: "host not allowed" }, { status: 403 });
  }

  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), FETCH_MS);

  try {
    const upstream = await fetch(target.toString(), {
      signal: ctrl.signal,
      cache: "no-store",
      headers: { Accept: "image/*,*/*" },
    });
    clearTimeout(timer);

    if (!upstream.ok) {
      logger.warn('wallpaper-fetch', 'upstream', { status: upstream.status, host: target.hostname });
      return NextResponse.json({ error: "upstream" }, { status: 502 });
    }

    const len = upstream.headers.get("content-length");
    if (len && Number(len) > MAX_BYTES) {
      return NextResponse.json({ error: "too large" }, { status: 413 });
    }

    const buf = await upstream.arrayBuffer();
    if (buf.byteLength > MAX_BYTES) {
      return NextResponse.json({ error: "too large" }, { status: 413 });
    }

    const ct = upstream.headers.get("content-type") || "application/octet-stream";
    const safeType = ct.startsWith("image/") ? ct : "image/jpeg";

    return new NextResponse(buf, {
      status: 200,
      headers: {
        "Content-Type": safeType,
        "Cache-Control": "private, max-age=3600",
      },
    });
  } catch (e) {
    clearTimeout(timer);
    logger.warn('wallpaper-fetch', 'fetch failed', e);
    return NextResponse.json({ error: "fetch failed" }, { status: 502 });
  }
}
