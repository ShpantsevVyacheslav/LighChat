# Chat History Top-Trigger Fallback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore reliable older-message loading when scrolling to top in chat and thread lists without introducing layout jumps.

**Architecture:** Keep existing `displayLimit + onSnapshot` pagination, retain `startReached`, and add a fallback trigger based on actual scroller top position (`scrollTop <= threshold`). Gate fallback with cooldown and existing loading guards to prevent duplicate loads. Preserve already implemented prepend scroll compensation logic.

**Tech Stack:** React 18, Next.js 14, TypeScript, Firebase Firestore realtime listeners, react-virtuoso.

---

## File Structure

- Modify: `src/components/chat/ChatWindow.tsx`
  - Add top-threshold fallback trigger (`scroll` + `rangeChanged`) for older load.
  - Add cooldown ref to avoid repeated triggering.
- Modify: `src/components/chat/ThreadWindow.tsx`
  - Mirror fallback trigger logic for thread history.
- Modify: `docs/arcitecture/04-runtime-flows.md`
  - Document fallback top-trigger in runtime flow notes.

### Task 1: Add top-threshold fallback trigger in ChatWindow

**Files:**
- Modify: `src/components/chat/ChatWindow.tsx`

- [ ] **Step 1: Add fallback constants and cooldown refs near load-more state**

```tsx
const TOP_LOAD_THRESHOLD_PX = 40;
const LOAD_MORE_COOLDOWN_MS = 600;
const loadMoreCooldownUntilRef = useRef(0);
```

- [ ] **Step 2: Add guarded helper that triggers existing handleLoadMore**

```tsx
const tryLoadMoreByTopPosition = useCallback(() => {
  const now = Date.now();
  if (now < loadMoreCooldownUntilRef.current) return;
  if (!hasMore || isLoadingOlder) return;
  const scroller = viewportScrollerRef.current;
  if (!scroller) return;
  if (scroller.scrollTop > TOP_LOAD_THRESHOLD_PX) return;
  loadMoreCooldownUntilRef.current = now + LOAD_MORE_COOLDOWN_MS;
  handleLoadMore();
}, [hasMore, isLoadingOlder, handleLoadMore]);
```

- [ ] **Step 3: Bind fallback helper to scroller scroll event**

```tsx
useEffect(() => {
  const scroller = viewportScrollerRef.current;
  if (!scroller) return;
  const onScroll = () => {
    tryLoadMoreByTopPosition();
  };
  scroller.addEventListener('scroll', onScroll, { passive: true });
  return () => scroller.removeEventListener('scroll', onScroll);
}, [tryLoadMoreByTopPosition]);
```

- [ ] **Step 4: Call fallback helper from rangeChanged pipeline as backup**

```tsx
const handleRangeChanged = useCallback((range: ListRange) => {
  currentVisibleRange.current = range;
  syncViewportCalendarDay(range.startIndex, range.endIndex);
  tryLoadMoreByTopPosition();
}, [syncViewportCalendarDay, tryLoadMoreByTopPosition]);
```

- [ ] **Step 5: Run typecheck**

Run: `npm run typecheck`
Expected: PASS

- [ ] **Step 6: Commit ChatWindow fallback**

```bash
git add src/components/chat/ChatWindow.tsx
git commit -m "fix: add top-position fallback trigger for chat history loading"
```

### Task 2: Mirror fallback trigger in ThreadWindow

**Files:**
- Modify: `src/components/chat/ThreadWindow.tsx`

- [ ] **Step 1: Add threshold/cooldown refs in thread window**

```tsx
const TOP_LOAD_THRESHOLD_PX = 40;
const LOAD_MORE_COOLDOWN_MS = 600;
const loadMoreCooldownUntilRef = useRef(0);
```

- [ ] **Step 2: Add thread helper that delegates to handleLoadMore**

```tsx
const tryLoadMoreByTopPosition = useCallback(() => {
  const now = Date.now();
  if (now < loadMoreCooldownUntilRef.current) return;
  if (!hasMore || isLoadingOlder) return;
  const scroller = viewportScrollerRef.current;
  if (!scroller) return;
  if (scroller.scrollTop > TOP_LOAD_THRESHOLD_PX) return;
  loadMoreCooldownUntilRef.current = now + LOAD_MORE_COOLDOWN_MS;
  handleLoadMore();
}, [hasMore, isLoadingOlder, handleLoadMore]);
```

- [ ] **Step 3: Bind helper to thread scroller scroll and rangeChanged backup**

```tsx
useEffect(() => {
  const scroller = viewportScrollerRef.current;
  if (!scroller) return;
  const onScroll = () => tryLoadMoreByTopPosition();
  scroller.addEventListener('scroll', onScroll, { passive: true });
  return () => scroller.removeEventListener('scroll', onScroll);
}, [tryLoadMoreByTopPosition]);

const handleRangeChanged = useCallback((range: ListRange) => {
  currentVisibleRange.current = range;
  syncViewportCalendarDay(range.startIndex, range.endIndex);
  tryLoadMoreByTopPosition();
}, [syncViewportCalendarDay, tryLoadMoreByTopPosition]);
```

- [ ] **Step 4: Run typecheck**

Run: `npm run typecheck`
Expected: PASS

- [ ] **Step 5: Commit ThreadWindow fallback**

```bash
git add src/components/chat/ThreadWindow.tsx
git commit -m "fix: add top-position fallback trigger for thread history loading"
```

### Task 3: Runtime doc sync and manual acceptance

**Files:**
- Modify: `docs/arcitecture/04-runtime-flows.md`

- [ ] **Step 1: Document startReached + top-threshold fallback behavior**

```md
- История в ChatWindow/ThreadWindow загружается по `startReached` и резервному top-threshold trigger (`scrollTop <= 40`) для кейсов, когда виртуализатор не эмитит событие стабильно на некоторых устройствах.
- Для предотвращения повторного спама используется cooldown и guard `isLoadingOlder`.
```

- [ ] **Step 2: Manual acceptance checks**

```text
1) Open long chat, scroll to top: older page loads reliably every time.
2) Loader appears only during actual loading.
3) No visual jump after prepend (scroll anchor preserved).
4) Stop at history end: no further fetch attempts.
5) Repeat in thread window.
```

- [ ] **Step 3: Commit docs sync**

```bash
git add docs/arcitecture/04-runtime-flows.md
git commit -m "docs: note top-threshold fallback for chat history loading"
```
