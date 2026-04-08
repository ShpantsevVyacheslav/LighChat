# Typing Indicator Compromise Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore "Печатает..." in chat list items without returning to always-on listeners for every conversation.

**Architecture:** Keep the existing typing data source (`conversations/{id}/typing`) and stale-window logic unchanged. Add UI-side gating in chat list items so typing listeners are enabled only for selected items or for items visible in viewport while the page is active. Use two focused hooks (viewport visibility and page visibility) and wire them into `ConversationItem`.

**Tech Stack:** Next.js 14, React 18, TypeScript, Firebase Firestore realtime listeners.

---

## File Structure

- Create: `src/hooks/use-element-in-viewport.ts`
  - Responsibility: report whether a DOM element is in viewport via `IntersectionObserver` with safe fallback.
- Create: `src/hooks/use-page-visibility.ts`
  - Responsibility: report whether the browser tab is active via `document.visibilityState`.
- Modify: `src/components/chat/ConversationItem.tsx`
  - Responsibility: compute `typingEnabled = isSelected || (isInViewport && isPageVisible)` and pass it to `useConversationTypingOthers`.
- Test (manual): `docs/superpowers/specs/2026-04-08-typing-indicator-compromise-design.md`
  - Responsibility: use the approved regression checklist as acceptance tests.

### Task 1: Add viewport visibility hook

**Files:**
- Create: `src/hooks/use-element-in-viewport.ts`
- Modify: `src/components/chat/ConversationItem.tsx`
- Test: Manual QA in browser

- [ ] **Step 1: Write failing integration expectation in-place (commented checklist item in work notes)**

```ts
// Expectation before code:
// When list item is in viewport and tab is active, typingEnabled should be true
// even if isSelected is false.
```

- [ ] **Step 2: Create hook with safe fallback and cleanup**

```ts
// src/hooks/use-element-in-viewport.ts
'use client';

import { useEffect, useState } from 'react';

export function useElementInViewport(
  target: Element | null,
  options: IntersectionObserverInit = { root: null, rootMargin: '0px', threshold: 0.01 }
): boolean {
  const [isInViewport, setIsInViewport] = useState(true);

  useEffect(() => {
    if (!target) {
      setIsInViewport(false);
      return;
    }

    if (typeof IntersectionObserver === 'undefined') {
      setIsInViewport(true);
      return;
    }

    const observer = new IntersectionObserver((entries) => {
      const first = entries[0];
      setIsInViewport(Boolean(first?.isIntersecting));
    }, options);

    observer.observe(target);
    return () => observer.disconnect();
  }, [target, options.root, options.rootMargin, options.threshold]);

  return isInViewport;
}
```

- [ ] **Step 3: Run type check to ensure new hook compiles**

Run: `npm run typecheck`
Expected: PASS (no new TypeScript errors from `use-element-in-viewport.ts`)

- [ ] **Step 4: Commit hook-only change**

```bash
git add src/hooks/use-element-in-viewport.ts
git commit -m "feat: add viewport visibility hook for chat item listener gating"
```

### Task 2: Add page visibility hook and wire typingEnabled

**Files:**
- Create: `src/hooks/use-page-visibility.ts`
- Modify: `src/components/chat/ConversationItem.tsx`
- Test: Manual QA in browser

- [ ] **Step 1: Write failing expectation for background tab behavior**

```ts
// Expectation before code:
// In background tab, non-selected chat items should disable typing listeners.
```

- [ ] **Step 2: Implement page visibility hook**

```ts
// src/hooks/use-page-visibility.ts
'use client';

import { useEffect, useState } from 'react';

export function usePageVisibility(): boolean {
  const [isVisible, setIsVisible] = useState(() => {
    if (typeof document === 'undefined') return true;
    return document.visibilityState === 'visible';
  });

  useEffect(() => {
    if (typeof document === 'undefined') return;

    const onVisibilityChange = () => {
      setIsVisible(document.visibilityState === 'visible');
    };

    document.addEventListener('visibilitychange', onVisibilityChange);
    return () => document.removeEventListener('visibilitychange', onVisibilityChange);
  }, []);

  return isVisible;
}
```

- [ ] **Step 3: Wire both hooks into ConversationItem**

```tsx
// key edits in src/components/chat/ConversationItem.tsx
import { useElementInViewport } from '@/hooks/use-element-in-viewport';
import { usePageVisibility } from '@/hooks/use-page-visibility';

const itemRef = useRef<HTMLButtonElement | null>(null);
const isInViewport = useElementInViewport(itemRef.current);
const isPageVisible = usePageVisibility();
const typingEnabled = isSelected || (isInViewport && isPageVisible);

const othersTypingFromSubcollection = useConversationTypingOthers(
  firestore,
  conv.id,
  currentUser.id,
  typingEnabled
);

// in JSX root button:
<button ref={itemRef} ...>
```

- [ ] **Step 4: Run type check and lint for touched files**

Run: `npm run typecheck && npm run lint`
Expected: PASS (or only pre-existing repo warnings unrelated to these files)

- [ ] **Step 5: Commit integration change**

```bash
git add src/hooks/use-page-visibility.ts src/components/chat/ConversationItem.tsx
git commit -m "perf: gate chat typing listeners by viewport and page visibility"
```

### Task 3: Validate behavior and update runtime documentation

**Files:**
- Modify: `docs/arcitecture/04-runtime-flows.md`
- Test: Manual QA in app

- [ ] **Step 1: Execute manual regression checklist from spec**

Run these checks in browser:

```text
1) Visible list items in active tab show "Печатает..." when peers type.
2) Items scrolled out of viewport stop receiving typing updates.
3) Background tab disables typing updates for non-selected items.
4) Returning to tab restores typing updates.
5) Selected chat keeps typing behavior regardless of viewport.
```

Expected: All 5 checks pass.

- [ ] **Step 2: Document listener gating in runtime flows**

```md
<!-- docs/arcitecture/04-runtime-flows.md -->
- Chat list typing indicators use `conversations/{id}/typing` realtime listeners.
- Listener activation is gated: selected chat is always enabled; non-selected items are enabled only when visible in viewport and while page is visible.
- This preserves UX while reducing background listener load on mobile/PWA.
```

- [ ] **Step 3: Re-run type check after docs/code final state**

Run: `npm run typecheck`
Expected: PASS

- [ ] **Step 4: Commit docs sync**

```bash
git add docs/arcitecture/04-runtime-flows.md
git commit -m "docs: describe viewport-gated typing listener flow"
```
