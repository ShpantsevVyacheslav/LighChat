'use client';

import React, { useState, useEffect, type ReactNode } from 'react';
import { FirebaseProvider } from '@/firebase/provider';
import { initializeFirebase } from '@/firebase';
import type { FirebaseApp } from 'firebase/app';
import type { Auth } from 'firebase/auth';
import type { Firestore } from 'firebase/firestore';
import type { FirebaseStorage } from 'firebase/storage';
import { Icons } from '@/components/icons';
import { FCM_SERVICE_WORKER_PATH, isLocalDevHostname } from '@/lib/fcm-service-worker';
import { logger } from '@/lib/logger';

interface FirebaseClientProviderProps {
  children: ReactNode;
}

type FirebaseServices = {
  firebaseApp: FirebaseApp;
  auth: Auth;
  firestore: Firestore;
  storage: FirebaseStorage;
};

export function FirebaseClientProvider({ children }: FirebaseClientProviderProps) {
  const [firebaseServices, setFirebaseServices] = useState<FirebaseServices | null>(null);
  const [initError, setInitError] = useState<string | null>(null);

  useEffect(() => {
    // PWA/FCM: на localhost не регистрируем SW — иначе после смены билда кэш/скоуп иногда мешают,
    // а HTML всё ещё тянет старые `/_next/static/*` (404 на чанках и вечный спиннер).
    const isLocalDev = isLocalDevHostname();
    // Регистрируем сразу после монтирования, не ждём `load`: иначе FCM/onboarding на iOS
    // может вызвать `serviceWorker.ready` раньше `register` и зависнуть на таймауте.
    if ('serviceWorker' in navigator && !isLocalDev) {
      void navigator.serviceWorker
        .register(FCM_SERVICE_WORKER_PATH, { scope: '/' })
        .then((registration) => {
          logger.debug('client-provider', 'ServiceWorker (PWA + FCM) registration successful', { scope: registration.scope });
        })
        .catch((err) => {
          logger.error('client-provider', 'ServiceWorker registration failed', err);
        });
    }

    const initFirebase = async () => {
      try {
        const services = await initializeFirebase();
        setFirebaseServices(services);
        setInitError(null);
      } catch (e) {
        logger.error('client-provider', 'initializeFirebase failed after fallbacks', e);
        setInitError(e instanceof Error ? e.message : 'Ошибка инициализации Firebase');
      }
    };

    void initFirebase();
  }, []);

  if (initError) {
    return (
      <div className="flex h-screen w-full flex-col items-center justify-center gap-4 bg-background px-6 text-center">
        <p className="max-w-sm text-sm text-muted-foreground">{initError}</p>
        <button
          type="button"
          className="rounded-lg bg-primary px-4 py-2 text-sm font-medium text-primary-foreground"
          onClick={() => window.location.reload()}
        >
          Обновить страницу
        </button>
      </div>
    );
  }

  if (!firebaseServices) {
    return (
      <div className="flex h-screen w-full items-center justify-center bg-background">
        <Icons.spinner className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  return (
    <FirebaseProvider
      firebaseApp={firebaseServices.firebaseApp}
      auth={firebaseServices.auth}
      firestore={firebaseServices.firestore}
      storage={firebaseServices.storage}
    >
      {children}
    </FirebaseProvider>
  );
}
