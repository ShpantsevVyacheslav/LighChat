'use client';
    
import { useState, useEffect, useRef } from 'react';
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
import { logger } from '@/lib/logger';

const TRANSIENT_DOC_ERROR_CODES = new Set<FirestoreError['code']>([
  'internal',
  'unavailable',
  'aborted',
  'deadline-exceeded',
  'cancelled',
  'unknown',
  'resource-exhausted',
]);
const MAX_TRANSIENT_DOC_RETRIES = 4;

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
  const [retryTick, setRetryTick] = useState(0);
  const transientRetryCountRef = useRef(0);

  useEffect(() => {
    let isMounted = true;

    if (!memoizedDocRef) {
      setData(null);
      setIsLoading(false);
      setError(null);
      transientRetryCountRef.current = 0;
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
            transientRetryCountRef.current = 0;
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
            logger.error('use-doc', 'real-time error', err);
            if (err.code === 'permission-denied') {
              transientRetryCountRef.current = 0;
              logFirestorePermissionDenied({
                source: 'useDoc',
                operation: 'get (onSnapshot)',
                path: memoizedDocRef.path,
                firestore: memoizedDocRef.firestore,
                error: err,
              });
              const contextualError = new FirestorePermissionError({ operation: 'get', path: memoizedDocRef.path });
              setError(contextualError);
              setData(null);
              setIsLoading(false);
              return;
            }

            if (TRANSIENT_DOC_ERROR_CODES.has(err.code)) {
              const retryCount = transientRetryCountRef.current;
              if (retryCount < MAX_TRANSIENT_DOC_RETRIES) {
                transientRetryCountRef.current = retryCount + 1;
                const delayMs = Math.min(4000, 300 * 2 ** retryCount);
                setError(err);
                setIsLoading(true);
                window.setTimeout(() => {
                  if (!isMounted) return;
                  setRetryTick((v) => v + 1);
                }, delayMs);
                return;
              }
            }

            transientRetryCountRef.current = 0;
            setError(err);
            setData(null);
            setIsLoading(false);
          }
        )
      );
    } catch (err: unknown) {
      if (isMounted) {
        logger.error('use-doc', 'Failed to establish Firestore document listener', err);
        setError(err instanceof Error ? err : null);
        setIsLoading(false);
      }
    }
    
    return () => {
      isMounted = false;
      if (typeof unsubscribeCombined === 'function') {
        try {
          unsubscribeCombined();
        } catch (e) {
          logger.warn('use-doc', 'cleanup warning', e);
        }
      }
    };
    
  }, [memoizedDocRef, retryTick]); // Re-run if the target changes or transient retry is triggered.

  if (memoizedDocRef && !memoizedDocRef.__memo) {
    throw new Error(memoizedDocRef + ' was not properly memoized using useMemoFirebase');
  }

  return { data, isLoading, error };
}
