# iOS Media Viewer Zoom Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore pinch zoom and stable pan in fullscreen chat media viewer on iOS while keeping swipe-to-close and desktop behavior intact.

**Architecture:** Keep current `MediaViewer` and `react-zoom-pan-pinch` integration, but split touch handling into two scopes: media zone and overlay zone. Media-zone touches bypass container-level dismissal logic; overlay touches keep the existing vertical dismiss gesture. Preserve existing double-tap toggle behavior and carousel logic.

**Tech Stack:** React 18, Next.js 14, TypeScript, `react-zoom-pan-pinch`, shadcn Dialog/Carousel.

---

## File Structure

- Modify: `src/components/chat/media-viewer.tsx`
  - Add gesture scope detection by touch target.
  - Keep overlay swipe-to-close only outside interactive media area.
  - Preserve double-tap zoom toggle behavior.
- Modify: `docs/arcitecture/04-runtime-flows.md`
  - Document iOS media-viewer touch-gating logic in runtime behavior section.

### Task 1: Add media-vs-overlay gesture scoping in MediaViewer

**Files:**
- Modify: `src/components/chat/media-viewer.tsx`
- Test: Manual iOS checks (fullscreen image pinch/pan/dismiss)

- [ ] **Step 1: Add refs/state for gesture scope and media zone**

```tsx
// near existing refs in MediaViewer
const mediaInteractiveRef = useRef<HTMLDivElement | null>(null);
const gestureScopeRef = useRef<'none' | 'media' | 'overlay'>('none');

const isTouchFromMediaZone = (target: EventTarget | null): boolean => {
  const node = target as Node | null;
  return !!node && !!mediaInteractiveRef.current?.contains(node);
};
```

- [ ] **Step 2: Update touchstart to set scope before dismiss logic**

```tsx
const onTouchStart = (e: React.TouchEvent) => {
  const fromMedia = isTouchFromMediaZone(e.target);
  gestureScopeRef.current = fromMedia ? 'media' : 'overlay';

  if (isZoomed) return;
  if (fromMedia) return;

  e.stopPropagation();
  const touch = e.touches[0];
  touchStartRef.current = { x: touch.clientX, y: touch.clientY };
  swipeDirectionRef.current = 'none';
};
```

- [ ] **Step 3: Update touchmove/touchend to ignore media scope**

```tsx
const onTouchMove = (e: React.TouchEvent) => {
  if (gestureScopeRef.current === 'media') return;
  if (isZoomed || !touchStartRef.current) return;

  e.stopPropagation();
  const touch = e.touches[0];
  const deltaX = touch.clientX - touchStartRef.current.x;
  const deltaY = touch.clientY - touchStartRef.current.y;

  if (swipeDirectionRef.current === 'none') {
    if (Math.abs(deltaY) > Math.abs(deltaX) && Math.abs(deltaY) > 10) swipeDirectionRef.current = 'vertical';
    else if (Math.abs(deltaX) > Math.abs(deltaY) && Math.abs(deltaX) > 10) swipeDirectionRef.current = 'horizontal';
  }

  if (swipeDirectionRef.current === 'vertical') {
    setTranslateY(deltaY);
    if (e.cancelable) e.preventDefault();
  }
};

const onTouchEnd = (e: React.TouchEvent) => {
  if (gestureScopeRef.current === 'media') {
    touchStartRef.current = null;
    swipeDirectionRef.current = 'none';
    gestureScopeRef.current = 'none';
    return;
  }

  if (!isZoomed && swipeDirectionRef.current === 'vertical') {
    e.stopPropagation();
    if (Math.abs(translateY) > 120) onOpenChange(false);
    else setTranslateY(0);
  } else if (swipeDirectionRef.current === 'horizontal') {
    e.stopPropagation();
  }

  touchStartRef.current = null;
  swipeDirectionRef.current = 'none';
  gestureScopeRef.current = 'none';
};
```

- [ ] **Step 4: Attach media ref to transform wrapper area**

```tsx
<TransformComponent
  wrapperClass="!w-screen !h-screen overflow-hidden"
  contentClass="w-screen h-screen flex items-center justify-center"
>
  <div ref={mediaInteractiveRef} className="w-screen h-screen flex items-center justify-center touch-auto">
    {/* existing img / VideoPlayer content */}
  </div>
</TransformComponent>
```

- [ ] **Step 5: Keep double-tap behavior unchanged and verify no logic drift**

```tsx
// must stay logically equivalent:
if (scale > ZOOMED_EPS) {
  tref.resetTransform(200);
} else {
  tref.zoomIn(0.7, 200);
}
```

- [ ] **Step 6: Run type check**

Run: `npm run typecheck`
Expected: PASS

- [ ] **Step 7: Commit media viewer fix**

```bash
git add src/components/chat/media-viewer.tsx
git commit -m "fix: restore iOS fullscreen media pinch zoom with gesture scoping"
```

### Task 2: Manual regression verification on iOS and desktop parity

**Files:**
- Modify: none
- Test: iOS/desktop manual checks

- [ ] **Step 1: Verify iOS pinch and pan in fullscreen image**

```text
1) Open chat image in MediaViewer fullscreen.
2) Pinch-in and pinch-out on image.
3) Pan while zoomed-in.
Expected: Zoom and pan work; viewer does not close unexpectedly.
```

- [ ] **Step 2: Verify double-tap toggle parity**

```text
1) Double-tap image once -> zoom in.
2) Double-tap again -> reset to scale 1.
Expected: Same behavior as desktop.
```

- [ ] **Step 3: Verify overlay swipe-to-close still works**

```text
1) Start swipe-down from overlay/header area (outside media zone).
2) Exceed dismiss threshold.
Expected: Viewer closes with existing animation.
```

- [ ] **Step 4: Verify video controls are unaffected**

```text
1) Open video in MediaViewer.
2) Play/pause/seek and fullscreen button.
Expected: Controls work as before.
```

### Task 3: Update runtime documentation for touch gesture policy

**Files:**
- Modify: `docs/arcitecture/04-runtime-flows.md`

- [ ] **Step 1: Add runtime note for media viewer touch routing**

```md
<!-- append to iOS/PWA performance guards or relevant flow section -->
- В fullscreen media viewer (chat) на iOS жесты разделены по зонам: media-зона отдаёт touch/pinch в `react-zoom-pan-pinch`, а swipe-down закрытия работает только из overlay-зоны.
```

- [ ] **Step 2: Commit docs sync**

```bash
git add docs/arcitecture/04-runtime-flows.md
git commit -m "docs: describe iOS media viewer gesture zone routing"
```
