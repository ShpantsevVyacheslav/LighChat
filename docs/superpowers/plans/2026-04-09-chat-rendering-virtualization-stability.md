# Chat Rendering Virtualization Stability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Убрать дергание и повторные загрузки медиа при длинном скролле в чате/тредах (особенно в Electron), сохранив текущий UX и `react-virtuoso`.

**Architecture:** Стабилизируем текущий pipeline без немедленной миграции виртуализатора: (1) дедуп/идемпотентность пагинации вверх, (2) снижение remount/decode churn, (3) унификация media URL/caching policy, (4) измеряемые KPI и только затем решение о миграции. Данные и рендер отделяются: отдельные guard-модули для top-load, observer-pool для read-by-viewport, режимы качества превью-медиа.

**Tech Stack:** Next.js 14, React 18, TypeScript, react-virtuoso, Firebase Firestore, Electron media-cache IPC.

---

### Task 1: Baseline Profiling And Guardrails

**Files:**
- Modify: `src/components/chat/ChatWindow.tsx`
- Modify: `src/components/chat/ThreadWindow.tsx`
- Create: `src/components/chat/chat-performance-metrics.ts`
- Create: `docs/perf/chat-scroll-baseline-2026-04-09.md`

- [ ] **Step 1: Add lightweight runtime metrics hooks for chat scroll and media loads**

Capture at minimum:
- scroll FPS (p50/p95)
- long frames count (`>16.7ms`, `>33ms`)
- media load/decode timings per type (image/video/gif)
- top pagination trigger counts per source (`startReached`, `rangeChanged`, `scroll`)

- [ ] **Step 2: Record baseline on Web and Electron**

Run manual scenario:
1. Open conversation with 300+ mixed messages.
2. Scroll up/down continuously for 2-3 minutes.
3. Open media viewer for a large gallery, navigate 20+ items.

Expected result: `docs/perf/chat-scroll-baseline-2026-04-09.md` contains numeric baseline for later A/B.

- [ ] **Step 3: Add debug counters for message-row remounts and observer count**

Expose counters in dev-only mode to detect regressions when changing overscan or observer strategy.


### Task 2: Single Source Of Truth For Top Pagination

**Files:**
- Modify: `src/components/chat/ChatWindow.tsx`
- Modify: `src/components/chat/ThreadWindow.tsx`

- [ ] **Step 1: Keep only one pagination trigger path (recommended: `startReached`)**

Remove duplicate top-load initiation from `rangeChanged` and raw `scroll` fallback where possible, keeping one deterministic trigger path and one emergency fallback behind strict guard.

- [ ] **Step 2: Add synchronous idempotency lock around `handleLoadMore`**

Use a ref lock (`loadMoreInFlightRef`) in addition to React state so two triggers in one frame cannot increment `displayLimit` twice.

- [ ] **Step 3: Validate no-jump prepend behavior after dedup**

Preserve existing prepend compensation (`scrollTop/scrollHeight` delta) and verify visually that top pagination remains smooth.

- [ ] **Step 4: Re-profile trigger counts**

Expected: duplicate load triggers per top reach drop to near 1.


### Task 3: Reduce Render Churn In Viewport Read Tracking

**Files:**
- Modify: `src/components/chat/message-read-on-viewport.tsx`
- Modify: `src/components/chat/ChatWindow.tsx`
- Modify: `src/components/chat/ThreadWindow.tsx`

- [ ] **Step 1: Replace observer-per-row with pooled/shared observer strategy**

Implement a shared `IntersectionObserver` keyed by scroller root. Rows register/unregister callbacks.

- [ ] **Step 2: Narrow effect dependencies to stable primitives**

Avoid using whole `message` object as dependency where only `senderId/readAt` are required.

- [ ] **Step 3: Verify read semantics parity**

Ensure behavior remains unchanged for:
- unread separator logic
- initial scroll-to-unread gate
- thread and main chat read marking


### Task 4: Media URL And Preview Policy Hardening (Electron + Web)

**Files:**
- Modify: `src/components/chat/parts/MessageMedia.tsx`
- Modify: `src/components/chat/ChatMessageItem.tsx`
- Modify: `src/components/chat/use-chat-attachment-display-src.ts`
- Modify: `src/components/chat/chat-media-session-cache.ts`
- Modify: `src/components/chat/media-viewer.tsx`

- [ ] **Step 1: Ensure GIF/video preview paths use cached display URL strategy**

Unify URL resolution so Electron path (`lighchat-media://`) is used consistently for inline video/gif/image previews, not just selected image flows.

- [ ] **Step 2: Introduce preview-quality mode for inline chat (not fullscreen)**

In chat list only, render low-quality placeholder/thumbnail first and defer full decode until scroll settles or item is near viewport.

- [ ] **Step 3: Window media viewer slide rendering**

Render only current slide and nearby neighbors (for example `current ±1`), keep distant slides lightweight to avoid memory/decode burst.

- [ ] **Step 4: Add lifecycle management for object URLs**

Apply bounded cache/eviction and `URL.revokeObjectURL` policy for converted HEIC and optimistic blob previews.


### Task 5: Overscan Tuning By Platform Profile

**Files:**
- Modify: `src/components/chat/virtuoso-chat-config.ts`
- Modify: `src/components/chat/ChatWindow.tsx`
- Modify: `src/components/chat/ThreadWindow.tsx`

- [ ] **Step 1: Split overscan config by runtime profile**

Keep existing aggressive profile as fallback, but add Electron/mobile-safe profile with reduced `increaseViewportBy`.

- [ ] **Step 2: Run A/B measurement against baseline**

Compare:
- remount count
- dropped frames
- memory growth over 3-minute scroll

- [ ] **Step 3: Lock default values by KPI, not intuition**

Pick config that satisfies smoothness and memory budget simultaneously.


### Task 6: Storage/Data Pipeline For Cached Reopen And Offline

**Files:**
- Modify: `src/firebase/index.ts`
- Create: `src/lib/chat-local-cache/*`
- Modify: `src/components/chat/ChatWindow.tsx`
- Modify: `src/components/chat/ThreadWindow.tsx`
- Modify: `electron/media-cache.js`

- [ ] **Step 1: Define two-level cache contract**

L1 (memory window) + L2 (local persistent: IndexedDB on web/PWA, local store on Electron/mobile) with conversation/time cursors.

- [ ] **Step 2: Implement fast restore path on chat open**

Render from local cached message window first, then reconcile with network snapshot without full scroll reset.

- [ ] **Step 3: Add media cache governance**

Introduce disk quota + LRU cleanup for Electron media cache to prevent uncontrolled growth.


### Task 7: Regression Tests, KPI Gates, And Migration Decision

**Files:**
- Create: `docs/perf/chat-scroll-after-optimization.md`
- Create: `docs/perf/chat-virtualization-decision-memo.md`

- [ ] **Step 1: Execute regression checklist**

Validate flows:
- mixed message types (text/image/sticker/video/gif/file/location/poll/reply/deleted)
- top pagination no-jump
- unread separator and mark-read correctness
- thread parity
- Electron reopen and offline preview behavior

- [ ] **Step 2: Record post-change metrics and compare to baseline**

Pass criteria (target):
- p95 scroll frame time improved materially vs baseline
- duplicate load trigger rate near zero
- media re-fetch count on back-scroll reduced
- memory growth stabilized for long sessions

- [ ] **Step 3: Final migration decision gate**

If KPI still unacceptable after Tasks 1-6, start controlled PoC on `@tanstack/react-virtual` in one surface (`ThreadWindow`) before any full migration.
