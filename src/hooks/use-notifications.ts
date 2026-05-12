'use client';

import { useState, useEffect, useCallback } from 'react';
import { getMessaging, getToken, onMessage, isSupported } from 'firebase/messaging';
import { useFirebase, useUser, updateDocumentNonBlocking } from '@/firebase';
import { doc, arrayUnion, getDoc } from 'firebase/firestore';
import {
  parseConversationIdFromDashboardChatLink,
  shouldSuppressForegroundChatPush,
} from '@/lib/push-notification-policy';
import { useToast } from './use-toast';
import {
  ensureFcmServiceWorkerRegistered,
  fcmServiceWorkerReadyTimeoutMs,
} from '@/lib/fcm-service-worker';
import { fcmSubscribeUserMessage } from '@/lib/fcm-subscribe-user-message';
import { logger } from '@/lib/logger';

// СЮДА ВСТАВЬТЕ ВАШ VAPID KEY ИЗ КОНСОЛИ FIREBASE
const VAPID_KEY = 'BO5th519pVXQkMoTXHWEU6WSHt75hV2l4dFn5Ohs_zMxOQ-eY8zHewWXSMZIDaa4vSmWyL6Z5vAy8lWACdjHIzU';

/** После активации SW — запас на ответ FCM / сеть (особенно iOS PWA). */
const FCM_GET_TOKEN_AFTER_SW_MS = 45_000;

function withTimeout<T>(promise: Promise<T>, ms: number, message: string): Promise<T> {
  return new Promise((resolve, reject) => {
    const t = setTimeout(() => reject(new Error(message)), ms);
    promise
      .then((v) => {
        clearTimeout(t);
        resolve(v);
      })
      .catch((e) => {
        clearTimeout(t);
        reject(e);
      });
  });
}

async function getFCMToken(firebaseApp: any) {
  if (typeof window === 'undefined' || !('serviceWorker' in navigator)) {
    throw new Error('Service Worker не поддерживается вашим браузером.');
  }

  if (!(await isSupported())) {
    throw new Error(
      'Push в этом окне недоступен. На iPhone откройте сайт из установленного на экран «Домой» приложения или используйте Chrome/Firefox для веб-push.',
    );
  }

  const messaging = getMessaging(firebaseApp);

  const swTimeout = fcmServiceWorkerReadyTimeoutMs();
  const registration = await withTimeout(
    ensureFcmServiceWorkerRegistered(),
    swTimeout,
    'FCM: service worker не активировался вовремя. Закройте приложение и откройте снова с экрана «Домой» (только установленное PWA получает push на iPhone).'
  );

  const token = await withTimeout(
    getToken(messaging, {
      serviceWorkerRegistration: registration,
      vapidKey: VAPID_KEY || undefined,
    }),
    FCM_GET_TOKEN_AFTER_SW_MS,
    'FCM: получение токена заняло слишком долго. Проверьте сеть и повторите позже.'
  );

  return token;
}

export function useNotifications() {
  const { firebaseApp, firestore } = useFirebase();
  const { user } = useUser();
  const { toast } = useToast();
  const [permission, setPermission] = useState<NotificationPermission | null>(null);
  const [isSubscribing, setIsSubscribing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (typeof window !== 'undefined' && 'Notification' in window) {
      setPermission(Notification.permission);
    }
  }, []);
  
  useEffect(() => {
    if (!firebaseApp || permission !== 'granted') return;

    let unsubscribeOnMessage: undefined | (() => void);
    let cancelled = false;

    void (async () => {
      try {
        if (!(await isSupported())) return;
        if (cancelled) return;
        const messaging = getMessaging(firebaseApp);
        unsubscribeOnMessage = onMessage(messaging, (payload) => {
          logger.debug('notifications', 'Foreground message received', payload);

          const title = payload.data?.title || payload.notification?.title || 'Уведомление';
          const body = payload.data?.body || payload.notification?.body || '';

          void (async () => {
            const authUid = user?.uid;
            if (!firestore || !authUid) {
              toast({ title, description: body });
              return;
            }
            try {
              const userSnap = await getDoc(doc(firestore, 'users', authUid));
              const userData = (userSnap.exists() ? userSnap.data() : {}) as Record<string, unknown>;
              const convId = parseConversationIdFromDashboardChatLink(payload.data?.link);
              let chatPrefs: Record<string, unknown> | undefined;
              if (convId) {
                const prefSnap = await getDoc(
                  doc(firestore, 'users', authUid, 'chatConversationPrefs', convId)
                );
                chatPrefs = prefSnap.exists() ? (prefSnap.data() as Record<string, unknown>) : undefined;
              }
              if (shouldSuppressForegroundChatPush({ userData, chatPrefs })) {
                return;
              }
            } catch (e) {
              logger.warn('notifications', 'foreground policy', e);
            }
            toast({ title, description: body });
          })();
        });
      } catch (e) {
        logger.warn('notifications', 'FCM foreground listener недоступен', e);
      }
    })();

    return () => {
      cancelled = true;
      unsubscribeOnMessage?.();
    };
  }, [firebaseApp, firestore, user?.uid, toast, permission]);
  
  const subscribe = useCallback(async (options?: { silent?: boolean }) => {
    const silent = options?.silent === true;
    if (!firebaseApp || !user || !firestore) {
      setError("Сервисы Firebase недоступны.");
      return;
    }
    
    setIsSubscribing(true);
    setError(null);
    
    try {
      if (typeof window === 'undefined' || typeof Notification === 'undefined') {
        throw new Error(
          'Push в этом окне недоступен. На iPhone откройте установленное приложение с экрана «Домой». В обычной вкладке Safari web-push может быть недоступен.'
        );
      }

      // Запрашиваем разрешение
      const currentPermission = await Notification.requestPermission();
      setPermission(currentPermission);

      if (currentPermission !== 'granted') {
          throw new Error("Разрешение на уведомления не получено.");
      }

      const token = await getFCMToken(firebaseApp);
      if (token) {
        const userDocRef = doc(firestore, 'users', user.uid);
        await updateDocumentNonBlocking(userDocRef, {
            fcmTokens: arrayUnion(token)
        });
        if (!silent) {
          toast({ title: "Уведомления включены", description: "Вы будете получать оповещения о важных событиях." });
        }
      }
    } catch (err) {
        logger.error('notifications', 'Error subscribing to notifications', err);
        const message = fcmSubscribeUserMessage(err);
        setError(message);
        if (!silent) {
          toast({ 
            variant: 'destructive', 
            title: 'Ошибка уведомлений', 
            description: message || 'Не удалось активировать пуш-уведомления.'
          });
        }
    } finally {
        setIsSubscribing(false);
    }
  }, [firebaseApp, user, firestore, toast]);

  return { permission, subscribe, isSubscribing, error };
}
