'use client';

import { useEffect, useState } from 'react';
import { isElectron } from '@/lib/utils';

type ElectronApi = {
  getCachedMediaUrl?: (remoteUrl: string) => Promise<string | null>;
};

function getElectronApi(): ElectronApi | null {
  if (typeof window === 'undefined') return null;
  return (window as any).electronAPI ?? null;
}

const resolvedElectronMediaUrlCache = new Map<string, string>();
const inFlightElectronMediaUrlCache = new Map<string, Promise<string | null>>();

/**
 * Electron-only helper: resolves a remote https? URL to a stable local protocol cache URL.
 * Falls back to the original URL if caching is unavailable or fails.
 */
export function useElectronCachedUrl(remoteUrl: string | null | undefined): string {
  const [url, setUrl] = useState(() => {
    if (!remoteUrl) return '';
    return resolvedElectronMediaUrlCache.get(remoteUrl) ?? remoteUrl;
  });

  useEffect(() => {
    if (!remoteUrl) {
      setUrl('');
      return;
    }

    const knownResolved = resolvedElectronMediaUrlCache.get(remoteUrl);
    setUrl(knownResolved ?? remoteUrl);
    if (knownResolved) return;

    if (!isElectron()) return;
    if (!/^https?:\/\//i.test(remoteUrl)) return;

    const api = getElectronApi();
    if (!api?.getCachedMediaUrl) return;

    let cancelled = false;
    void (async () => {
      try {
        let inFlight = inFlightElectronMediaUrlCache.get(remoteUrl);
        if (!inFlight) {
          inFlight = api.getCachedMediaUrl!(remoteUrl);
          inFlightElectronMediaUrlCache.set(remoteUrl, inFlight);
        }

        const cached = await inFlight;
        if (cancelled) return;
        if (cached && typeof cached === 'string') {
          resolvedElectronMediaUrlCache.set(remoteUrl, cached);
          setUrl(cached);
        }
      } catch (e) {
        console.warn('[Electron] media cache failed; using remote url.', e);
      } finally {
        inFlightElectronMediaUrlCache.delete(remoteUrl);
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [remoteUrl]);

  return url;
}
