# Chat History Pagination No-Jump Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix upward chat history loading so older pages always load correctly and preserve viewport position without layout jumps.

**Architecture:** Keep realtime `onSnapshot` for the live tail window of messages and add a separate cursor-based one-shot older-page loader (`getDocs + startAfter`). Merge `olderMessages` with live messages using id deduplication and chronological sort. Use anchor-preserving scroll compensation after prepend to keep the visible viewport stable.

**Tech Stack:** Next.js 14, React 18, TypeScript, Firebase Firestore (`onSnapshot`, `getDocs`, `query`, `startAfter`, `limit`), `react-virtuoso`.

---

## File Structure

- Modify: `src/components/chat/ChatWindow.tsx`
  - Split message sources into live and older paged history.
  - Implement cursor-based older fetch path.
  - Implement anchor-preserving prepend compensation.
  - Fix loader visibility condition to avoid infinite spinner.
- Modify: `src/components/chat/ThreadWindow.tsx`
  - Apply same pagination strategy to thread history.
- Modify: `docs/arcitecture/04-runtime-flows.md`
  - Document hybrid pagination behavior and no-jump guarantee.

### Task 1: Refactor ChatWindow state into live + older sources

**Files:**
- Modify: `src/components/chat/ChatWindow.tsx`

- [ ] **Step 1: Replace monolithic messages state with split sources**

```tsx
// before
const [messages, setMessages] = useState<ChatMessage[]>([]);

// after
const [liveMessages, setLiveMessages] = useState<ChatMessage[]>([]);
const [olderMessages, setOlderMessages] = useState<ChatMessage[]>([]);
const [hasMore, setHasMore] = useState(true);
const [isLoadingOlder, setIsLoadingOlder] = useState(false);
```

- [ ] **Step 2: Keep snapshot query pinned to initial live window**

```tsx
// in firestore listener effect
const q = query(msgCollection, orderBy('createdAt', 'desc'), limit(INITIAL_MESSAGE_LIMIT));

onSnapshot(q, (snap) => {
  const nextLive = snap.docs.map((d) => ({ ...d.data(), id: d.id } as ChatMessage)).reverse();
  setLiveMessages(nextLive);
  setIsFullyReady(true);
});
```

- [ ] **Step 3: Rebuild merged list with dedup and chronological order**

```tsx
const mergedMessages = useMemo(() => {
  const byId = new Map<string, ChatMessage>();
  for (const m of [...olderMessages, ...liveMessages, ...optimisticMessages]) {
    if (!byId.has(m.id)) byId.set(m.id, m);
  }
  return Array.from(byId.values()).sort((a, b) =>
    new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime()
  );
}, [olderMessages, liveMessages, optimisticMessages]);
```

- [ ] **Step 4: Wire existing list pipeline to mergedMessages**

```tsx
const messagesForList = useMemo(() => {
  const clearedAt = conversation.clearedAt?.[currentUser.id];
  return clearedAt
    ? mergedMessages.filter((m) => new Date(m.createdAt) > new Date(clearedAt))
    : mergedMessages;
}, [mergedMessages, conversation.clearedAt, currentUser.id]);
```

- [ ] **Step 5: Reset live/older state on conversation switch**

```tsx
if (prevConvIdRef.current !== conversation.id) {
  setLiveMessages([]);
  setOlderMessages([]);
  setHasMore(true);
  setIsLoadingOlder(false);
  // keep existing resets
}
```

- [ ] **Step 6: Run type check**

Run: `npm run typecheck`
Expected: PASS

- [ ] **Step 7: Commit Task 1**

```bash
git add src/components/chat/ChatWindow.tsx
git commit -m "refactor: split chat messages into live and older history sources"
```

### Task 2: Implement cursor-based older pagination in ChatWindow

**Files:**
- Modify: `src/components/chat/ChatWindow.tsx`

- [ ] **Step 1: Add helper to get oldest loaded cursor safely**

```tsx
const oldestLoadedMessage = useMemo(() => {
  const source = messagesForList;
  return source.length > 0 ? source[0] : null;
}, [messagesForList]);
```

- [ ] **Step 2: Implement older-page fetch function with page+1 strategy**

```tsx
const fetchOlderPage = useCallback(async () => {
  if (!firestore || !conversation.id) return;
  if (isLoadingOlder || !hasMore) return;
  if (!oldestLoadedMessage) return;

  setIsLoadingOlder(true);
  try {
    const msgCollection = collection(firestore, `conversations/${conversation.id}/messages`);
    const q = query(
      msgCollection,
      orderBy('createdAt', 'desc'),
      startAfter(oldestLoadedMessage.createdAt),
      limit(HISTORY_PAGE_SIZE + 1)
    );
    const snap = await getDocs(q);
    const page = snap.docs.map((d) => ({ ...d.data(), id: d.id } as ChatMessage));
    const hasNext = page.length > HISTORY_PAGE_SIZE;
    const toAppend = page.slice(0, HISTORY_PAGE_SIZE).reverse();

    if (toAppend.length > 0) {
      setOlderMessages((prev) => {
        const byId = new Map(prev.map((m) => [m.id, m]));
        for (const m of toAppend) if (!byId.has(m.id)) byId.set(m.id, m);
        return Array.from(byId.values()).sort((a, b) =>
          new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime()
        );
      });
    }

    setHasMore(hasNext);
  } finally {
    setIsLoadingOlder(false);
  }
}, [firestore, conversation.id, isLoadingOlder, hasMore, oldestLoadedMessage]);
```

- [ ] **Step 3: Rewire `startReached` to new fetch function**

```tsx
const handleLoadMore = useCallback(() => {
  void fetchOlderPage();
}, [fetchOlderPage]);
```

- [ ] **Step 4: Fix Virtuoso Header loader condition**

```tsx
Header: () =>
  isLoadingOlder ? (
    <div className="p-4 flex items-center justify-center text-muted-foreground">
      <Loader2 className="h-5 w-5 animate-spin mr-2" />
      <span className="text-[10px] font-black uppercase tracking-widest">Загрузка истории...</span>
    </div>
  ) : null,
```

- [ ] **Step 5: Run type check**

Run: `npm run typecheck`
Expected: PASS

- [ ] **Step 6: Commit Task 2**

```bash
git add src/components/chat/ChatWindow.tsx
git commit -m "fix: load older chat history via cursor pagination"
```

### Task 3: Add no-jump anchor compensation in ChatWindow prepend flow

**Files:**
- Modify: `src/components/chat/ChatWindow.tsx`

- [ ] **Step 1: Capture anchor before older fetch**

```tsx
const prependAnchorRef = useRef<{ messageId: string; top: number } | null>(null);

const capturePrependAnchor = useCallback(() => {
  const items = flatItemsRef.current;
  const { startIndex } = currentVisibleRange.current;
  const firstVisible = items[startIndex];
  if (!firstVisible || firstVisible.type !== 'message') {
    prependAnchorRef.current = null;
    return;
  }
  const scroller = viewportScrollerRef.current;
  const el = document.getElementById(`msg-${firstVisible.message.id}`);
  if (!scroller || !el) {
    prependAnchorRef.current = null;
    return;
  }
  prependAnchorRef.current = {
    messageId: firstVisible.message.id,
    top: el.getBoundingClientRect().top - scroller.getBoundingClientRect().top,
  };
}, []);
```

- [ ] **Step 2: Restore anchor after prepend commit**

```tsx
const restorePrependAnchor = useCallback(() => {
  const anchor = prependAnchorRef.current;
  if (!anchor) return;
  const scroller = viewportScrollerRef.current;
  const el = document.getElementById(`msg-${anchor.messageId}`);
  if (!scroller || !el) {
    prependAnchorRef.current = null;
    return;
  }
  const nextTop = el.getBoundingClientRect().top - scroller.getBoundingClientRect().top;
  const delta = nextTop - anchor.top;
  if (Math.abs(delta) > 0.5) scroller.scrollBy({ top: delta, behavior: 'auto' });
  prependAnchorRef.current = null;
}, []);
```

- [ ] **Step 3: Integrate capture/restore around older page insertion**

```tsx
// before fetch
capturePrependAnchor();

// after setOlderMessages (in same flow)
requestAnimationFrame(() => {
  requestAnimationFrame(() => {
    restorePrependAnchor();
  });
});
```

- [ ] **Step 4: Run type check**

Run: `npm run typecheck`
Expected: PASS

- [ ] **Step 5: Commit Task 3**

```bash
git add src/components/chat/ChatWindow.tsx
git commit -m "fix: preserve chat scroll anchor when prepending history"
```

### Task 4: Mirror pagination fix for ThreadWindow

**Files:**
- Modify: `src/components/chat/ThreadWindow.tsx`

- [ ] **Step 1: Apply split-source message model in thread window**

```tsx
const [liveMessages, setLiveMessages] = useState<ChatMessage[]>([]);
const [olderMessages, setOlderMessages] = useState<ChatMessage[]>([]);
```

- [ ] **Step 2: Replace displayLimit growth with cursor-based older fetch**

```tsx
const q = query(threadCollection, orderBy('createdAt', 'desc'), limit(INITIAL_MESSAGE_LIMIT));
// snapshot -> liveMessages
// startReached -> getDocs(startAfter(oldest.createdAt), limit(HISTORY_PAGE_SIZE + 1))
```

- [ ] **Step 3: Apply same header loading condition (`isLoadingOlder` only)**

```tsx
Header: () => (isLoadingOlder ? <LoaderRow /> : null)
```

- [ ] **Step 4: Add anchor-preserving prepend in thread list as in ChatWindow**

```tsx
capturePrependAnchor();
// prepend older thread page
requestAnimationFrame(() => requestAnimationFrame(restorePrependAnchor));
```

- [ ] **Step 5: Run type check**

Run: `npm run typecheck`
Expected: PASS

- [ ] **Step 6: Commit Task 4**

```bash
git add src/components/chat/ThreadWindow.tsx
git commit -m "fix: restore thread history pagination with stable prepend scroll"
```

### Task 5: Runtime doc sync and manual verification

**Files:**
- Modify: `docs/arcitecture/04-runtime-flows.md`

- [ ] **Step 1: Update runtime flow doc for hybrid pagination**

```md
- Chat history uses hybrid loading: realtime listener for the latest window and cursor-based page fetch for older history on upward scroll.
- Older pages are prepended with anchor compensation to avoid visual layout jumps.
- Loader in history header is shown only during active older-page fetch.
```

- [ ] **Step 2: Execute manual acceptance checklist**

```text
1) Open a long chat: initial window loads without infinite loader.
2) Scroll to top: one older page loads and loader disappears.
3) Repeat multiple times: each top reach loads next page until history ends.
4) During prepend, visible viewport stays stable (no jump).
5) End of history: no extra fetch loop and no stuck loader.
6) Send/receive new messages after older pagination: live tail behavior still correct.
7) Repeat key checks in thread window.
```

- [ ] **Step 3: Commit docs sync**

```bash
git add docs/arcitecture/04-runtime-flows.md
git commit -m "docs: describe hybrid chat history pagination and no-jump prepend"
```
