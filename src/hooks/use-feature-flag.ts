'use client';

import { useEffect, useState } from 'react';
import { doc, onSnapshot } from 'firebase/firestore';
import { useFirestore } from '@/firebase';
import type { PlatformSettingsDoc } from '@/lib/types';

const cache: { flags: Record<string, boolean> } = { flags: {} };
const subscribers = new Set<() => void>();
let initialized = false;

export function useFeatureFlag(name: string): boolean {
  const firestore = useFirestore();
  const [enabled, setEnabled] = useState<boolean>(cache.flags[name] ?? false);

  useEffect(() => {
    if (!firestore || initialized) {
      const update = () => setEnabled(cache.flags[name] ?? false);
      subscribers.add(update);
      return () => { subscribers.delete(update); };
    }

    initialized = true;
    const ref = doc(firestore, 'platformSettings', 'main');
    const unsub = onSnapshot(ref, (snap) => {
      const data = snap.data() as PlatformSettingsDoc | undefined;
      const flagsMap: Record<string, boolean> = {};
      if (data?.featureFlags) {
        for (const [k, v] of Object.entries(data.featureFlags)) {
          flagsMap[k] = v.enabled;
        }
      }
      cache.flags = flagsMap;
      subscribers.forEach((fn) => fn());
      setEnabled(flagsMap[name] ?? false);
    });

    const update = () => setEnabled(cache.flags[name] ?? false);
    subscribers.add(update);
    return () => {
      subscribers.delete(update);
      unsub();
    };
  }, [firestore, name]);

  return enabled;
}
