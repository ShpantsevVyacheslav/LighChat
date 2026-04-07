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
      if (process.env.NODE_ENV === "development") {
        console.warn("[LighChat] typing doc write denied (deploy firestore rules or check membership)", docRef.path);
      }
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
    .catch(error => {
      const permissionError = new FirestorePermissionError({
        path: docRef.path,
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
      if (process.env.NODE_ENV === "development") {
        console.warn("[LighChat] typing doc delete denied (deploy firestore rules or check auth)", docRef.path);
      }
      return;
    }
    const permissionError = new FirestorePermissionError({
      path: docRef.path,
      operation: "delete",
    });
    errorEmitter.emit("permission-error", permissionError);
  });
}
