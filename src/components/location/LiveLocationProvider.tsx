'use client';

import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
} from 'react';
import { deleteField, doc, updateDoc } from 'firebase/firestore';
import { useFirestore, useDoc, useMemoFirebase } from '@/firebase';
import { useAuth } from '@/hooks/use-auth';
import type { User } from '@/lib/types';
import { isLiveShareExpired, isLiveShareVisible } from '@/lib/live-location-utils';
import { logger } from '@/lib/logger';

const THROTTLE_MS = 15_000;

/** Один watch на вкладку — переживает переходы между страницами дашборда. */
let moduleWatchId: number | null = null;
let lastThrottleWrite = 0;
let lastStartedAt: string | null = null;

function clearModuleWatch() {
  if (moduleWatchId != null && typeof navigator !== 'undefined' && navigator.geolocation) {
    navigator.geolocation.clearWatch(moduleWatchId);
    moduleWatchId = null;
  }
}

type LiveLocationContextValue = {
  stopSharing: () => Promise<void>;
  isSharing: boolean;
};

const LiveLocationContext = createContext<LiveLocationContextValue | null>(null);

export function useLiveLocationControl(): LiveLocationContextValue {
  const ctx = useContext(LiveLocationContext);
  if (!ctx) {
    return { stopSharing: async () => {}, isSharing: false };
  }
  return ctx;
}

export function LiveLocationProvider({ children }: { children: React.ReactNode }) {
  useEffect(() => () => clearModuleWatch(), []);

  const { user } = useAuth();
  const firestore = useFirestore();
  const userRef = useMemoFirebase(
    () => (firestore && user?.id ? doc(firestore, 'users', user.id) : null),
    [firestore, user?.id]
  );
  const { data: me } = useDoc<User>(userRef);

  const fsRef = useRef(firestore);
  const uidRef = useRef(user?.id);
  fsRef.current = firestore;
  uidRef.current = user?.id;

  const stopSharing = useCallback(async () => {
    clearModuleWatch();
    lastStartedAt = null;
    const fs = fsRef.current;
    const uid = uidRef.current;
    if (!fs || !uid) return;
    try {
      await updateDoc(doc(fs, 'users', uid), { liveLocationShare: deleteField() });
    } catch (e) {
      logger.error('live-location', 'stopSharing failed', e);
    }
  }, []);

  const share = me?.liveLocationShare ?? undefined;

  /** Старт/сброс watch при новой сессии (startedAt). */
  useEffect(() => {
    if (!share?.active || !firestore || !user?.id) {
      clearModuleWatch();
      lastStartedAt = null;
      return;
    }

    if (isLiveShareExpired(share)) {
      clearModuleWatch();
      lastStartedAt = null;
      updateDoc(doc(firestore, 'users', user.id), { liveLocationShare: deleteField() }).catch((e) =>
        logger.error('live-location', 'cleanup expired', e)
      );
      return;
    }

    if (lastStartedAt === share.startedAt && moduleWatchId != null) {
      return;
    }

    clearModuleWatch();
    lastStartedAt = share.startedAt;
    lastThrottleWrite = 0;

    if (!navigator.geolocation) return;

    moduleWatchId = navigator.geolocation.watchPosition(
      (pos) => {
        const now = Date.now();
        if (now - lastThrottleWrite < THROTTLE_MS) return;
        lastThrottleWrite = now;
        const fs = fsRef.current;
        const uid = uidRef.current;
        if (!fs || !uid) return;
        const lat = pos.coords.latitude;
        const lng = pos.coords.longitude;
        const accuracyM = pos.coords.accuracy;
        const updatedAt = new Date().toISOString();
        updateDoc(doc(fs, 'users', uid), {
          'liveLocationShare.lat': lat,
          'liveLocationShare.lng': lng,
          'liveLocationShare.accuracyM': accuracyM,
          'liveLocationShare.updatedAt': updatedAt,
        }).catch((e) => logger.error('live-location', 'watch update', e));
      },
      () => {},
      { enableHighAccuracy: false, maximumAge: 15_000 }
    );

    return () => {
      clearModuleWatch();
    };
  }, [share?.active, share?.startedAt, share?.expiresAt, firestore, user?.id]);

  /** Авто-стоп по таймеру expiresAt. */
  useEffect(() => {
    if (!share?.active || !share.expiresAt || !firestore || !user?.id) return;
    const ms = new Date(share.expiresAt).getTime() - Date.now();
    if (ms <= 0) {
      void stopSharing();
      return;
    }
    const t = window.setTimeout(() => void stopSharing(), ms);
    return () => window.clearTimeout(t);
  }, [share?.active, share?.expiresAt, share?.startedAt, firestore, user?.id, stopSharing]);

  const isSharing = !!(share && isLiveShareVisible(share));

  const value = useMemo(
    () => ({
      stopSharing,
      isSharing,
    }),
    [stopSharing, isSharing]
  );

  return <LiveLocationContext.Provider value={value}>{children}</LiveLocationContext.Provider>;
}
