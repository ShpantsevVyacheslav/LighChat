'use client';
    
import { useState, useEffect } from 'react';
import {
  DocumentReference,
  onSnapshot,
  DocumentData,
  FirestoreError,
  DocumentSnapshot,
} from 'firebase/firestore';
import { FirestorePermissionError } from '@/firebase/errors';
import { scheduleFirestoreListen } from '@/firebase/schedule-firestore-listen';
import { logFirestorePermissionDenied } from '@/lib/firestore-permission-debug';

/** Utility type to add an 'id' field to a given type T. */
type WithId<T> = T & { id: string };

/**
 * Interface for the return value of the useDoc hook.
 * @template T Type of the document data.
 */
export interface UseDocResult<T> {
  data: WithId<T> | null; // Document data with ID, or null.
  isLoading: boolean;       // True if loading.
  error: FirestoreError | Error | null; // Error object, or null.
}

/**
 * React hook to subscribe to a single Firestore document for real-time updates.
 *
 * IMPORTANT! YOU MUST MEMOIZE the inputted memoizedDocRef or BAD THINGS WILL HAPPEN
 * use useMemoFirebase to memoize it per React guidance.
 *
 * @template T Optional type for document data. Defaults to any.
 * @param {DocumentReference<DocumentData> | null | undefined} memoizedDocRef -
 * The Firestore DocumentReference. Waits if null/undefined.
 * @returns {UseDocResult<T>} Object with data, isLoading, error.
 */
export function useDoc<T = any>(
  memoizedDocRef: (DocumentReference<DocumentData> & {__memo?: boolean}) | null | undefined
): UseDocResult<T> {
  type StateDataType = WithId<T> | null;

  const [data, setData] = useState<StateDataType>(null);
  const [isLoading, setIsLoading] = useState<boolean>(!!memoizedDocRef);
  const [error, setError] = useState<FirestoreError | Error | null>(null);

  useEffect(() => {
    let isMounted = true;

    if (!memoizedDocRef) {
      setData(null);
      setIsLoading(false);
      setError(null);
      return;
    }

    setIsLoading(true);
    setError(null);

    let unsubscribeCombined: (() => void) | undefined;

    try {
      unsubscribeCombined = scheduleFirestoreListen(() =>
        onSnapshot(
          memoizedDocRef,
          (snapshot: DocumentSnapshot<DocumentData>) => {
            if (!isMounted) return;
            if (snapshot.exists()) {
              setData({ ...(snapshot.data() as T), id: snapshot.id });
            } else {
              setData(null);
            }
            setError(null);
            setIsLoading(false);
          },
          (err: FirestoreError) => {
            if (!isMounted) return;
            console.error("useDoc (real-time) error:", err);
            if (err.code === 'permission-denied') {
              logFirestorePermissionDenied({
                source: 'useDoc',
                operation: 'get (onSnapshot)',
                path: memoizedDocRef.path,
                firestore: memoizedDocRef.firestore,
                error: err,
              });
            }
            const contextualError = new FirestorePermissionError({ operation: 'get', path: memoizedDocRef.path });
            setError(contextualError);
            setData(null);
            setIsLoading(false);
          }
        )
      );
    } catch (err: any) {
      if (isMounted) {
        console.error("Failed to establish Firestore document listener:", err);
        setError(err);
        setIsLoading(false);
      }
    }
    
    return () => {
      isMounted = false;
      if (typeof unsubscribeCombined === 'function') {
        try {
          unsubscribeCombined();
        } catch (e) {
          console.warn("Firestore document listener cleanup warning:", e);
        }
      }
    };
    
  }, [memoizedDocRef]); // Re-run if the target changes.

  if (memoizedDocRef && !memoizedDocRef.__memo) {
    throw new Error(memoizedDocRef + ' was not properly memoized using useMemoFirebase');
  }

  return { data, isLoading, error };
}