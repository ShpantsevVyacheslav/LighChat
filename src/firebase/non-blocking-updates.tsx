'use client';
    
import {
  setDoc,
  addDoc,
  updateDoc,
  deleteDoc,
  CollectionReference,
  DocumentReference,
  SetOptions,
} from 'firebase/firestore';
import { errorEmitter } from '@/firebase/error-emitter';
import { FirestorePermissionError } from '@/firebase/errors';
import { logger } from '@/lib/logger';

/**
 * Initiates a setDoc operation for a document reference.
 * Does NOT await the write operation internally.
 */
export function setDocumentNonBlocking(docRef: DocumentReference, data: any, options: SetOptions = {}) {
  return setDoc(docRef, data, options).catch((error: unknown) => {
    const code =
      error && typeof error === "object" && "code" in error
        ? String((error as { code: string }).code)
        : "";
    /** Heartbeat typing — не роняем UI при deny до деплоя правил или гонках. */
    if (code === "permission-denied" && docRef.path.includes("/typing/")) {
      logger.debug('non-blocking', 'typing doc write denied (deploy firestore rules or check membership)', docRef.path);
      return;
    }
    const permissionError = new FirestorePermissionError({
      path: docRef.path,
      operation: 'write',
      requestResourceData: data,
    });
    errorEmitter.emit('permission-error', permissionError);
  });
}


/**
 * Initiates an addDoc operation for a collection reference.
 * Does NOT await the write operation internally.
 */
export function addDocumentNonBlocking(colRef: CollectionReference, data: any) {
  return addDoc(colRef, data)
    .catch(error => {
      const permissionError = new FirestorePermissionError({
        path: colRef.path,
        operation: 'create',
        requestResourceData: data,
      });
      errorEmitter.emit('permission-error', permissionError);
    });
}


/**
 * Initiates an updateDoc operation for a document reference.
 */
export function updateDocumentNonBlocking(docRef: DocumentReference, data: any) {
  return updateDoc(docRef, data)
    .catch((error: unknown) => {
      const code =
        error && typeof error === 'object' && 'code' in error
          ? String((error as { code: string }).code)
          : '';
      const path = docRef.path;
      const isPresenceWrite =
        path.startsWith('users/')
        && data
        && typeof data === 'object'
        && Object.keys(data).every((k) => k === 'online' || k === 'lastSeen');
      const isTypingWrite = path.includes('/typing/');
      /**
       * Не роняем UI на permission-denied для нон-критичных fire-and-forget путей:
       * - presence (online/lastSeen на users/{uid}) — может фейлиться, если профиль ещё
       *   не создан onUserCreated после QR-handover, или если правила режут гостя
       *   (`!isAnonymousGuest()` в firestore.rules:416);
       * - typing — то же, см. deleteDocumentNonBlocking.
       * Иначе FirebaseErrorListener бросает FirestorePermissionError, который ловит
       * Next.js global-error.tsx → весь app падает в «Критическую ошибку».
       */
      if (code === 'permission-denied' && (isPresenceWrite || isTypingWrite)) {
        logger.debug('non-blocking', 'permission-denied skipped', { path });
        return;
      }
      const permissionError = new FirestorePermissionError({
        path,
        operation: 'update',
        requestResourceData: data,
      });
      errorEmitter.emit('permission-error', permissionError);
    });
}


/**
 * Initiates a deleteDoc operation for a document reference.
 */
export function deleteDocumentNonBlocking(docRef: DocumentReference) {
  return deleteDoc(docRef).catch((error: unknown) => {
    const code =
      error && typeof error === "object" && "code" in error
        ? String((error as { code: string }).code)
        : "";
    /** Не роняем весь UI: очистка typing часто идёт при смене чата; до деплоя правил возможен deny. */
    if (code === "permission-denied" && docRef.path.includes("/typing/")) {
      logger.debug('non-blocking', 'typing doc delete denied (deploy firestore rules or check auth)', docRef.path);
      return;
    }
    const permissionError = new FirestorePermissionError({
      path: docRef.path,
      operation: "delete",
    });
    errorEmitter.emit("permission-error", permissionError);
  });
}
