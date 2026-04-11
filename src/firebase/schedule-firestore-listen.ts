/**
 * Откладывает вызов onSnapshot на следующий microtask.
 * React 18 Strict Mode в dev дважды монтирует эффекты: синхронный subscribe → immediate unsubscribe
 * иногда приводит к FIRESTORE INTERNAL ASSERTION FAILED (WatchChangeAggregator / Unexpected state).
 *
 * @param onSetupFailed — если startListen() синхронно бросает, вызывается здесь (сбросить isLoading и т.п.).
 */
export function scheduleFirestoreListen(
  startListen: () => () => void,
  onSetupFailed?: (error: unknown) => void
): () => void {
  let cancelled = false;
  let innerUnsub: (() => void) | undefined;

  const run = () => {
    if (cancelled) return;
    try {
      innerUnsub = startListen();
    } catch (e) {
      console.error("[LighChat] Firestore listen failed:", e);
      onSetupFailed?.(e);
    }
  };

  if (typeof queueMicrotask === "function") {
    queueMicrotask(run);
  } else {
    void Promise.resolve().then(run);
  }

  return () => {
    cancelled = true;
    try {
      innerUnsub?.();
    } catch (e) {
      console.warn("[LighChat] Firestore listen cleanup warning:", e);
    }
  };
}
