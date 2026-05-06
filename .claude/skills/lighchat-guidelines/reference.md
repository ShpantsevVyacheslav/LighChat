# LighChat — Reference Guide

## Critical File Map

| Purpose | Path |
|---|---|
| Non-blocking Firestore helpers | `src/firebase/non-blocking-updates.tsx` |
| Firebase provider & `useMemoFirebase` | `src/firebase/provider.tsx` |
| Firestore `useDoc` hook | `src/firebase/firestore/use-doc.tsx` |
| Firestore `useCollection` hook | `src/firebase/firestore/use-collection.tsx` |
| Main chat window | `src/components/chat/ChatWindow.tsx` |
| Thread window | `src/components/chat/ThreadWindow.tsx` |
| Media rendering (images/video) | `src/components/chat/parts/MessageMedia.tsx` |
| Link preview card | `src/components/chat/LinkPreview.tsx` |
| Participant profile | `src/components/chat/ChatParticipantProfile.tsx` |
| Chat page entry | `src/app/dashboard/chat/page.tsx` |
| Forward message page | `src/app/dashboard/chat/forward/page.tsx` |
| Meetings room | `src/components/meetings/MeetingRoom.tsx` |
| Meetings polls | `src/components/meetings/MeetingPolls.tsx` |
| Notification bell | `src/components/notification-bell.tsx` |
| Unread counts hook | `src/hooks/use-unread-counts.ts` |

## Firebase Patterns

### Non-Blocking Write — Full Example

```typescript
import { doc } from "firebase/firestore";
import { nonBlockingUpdateDoc } from "@/firebase/non-blocking-updates";
import { db } from "@/firebase/provider";

function markAsRead(chatId: string, userId: string) {
  const ref = doc(db, "chats", chatId, "members", userId);
  nonBlockingUpdateDoc(ref, { lastRead: new Date() });
}
```

### Memoized Query — Full Example

```typescript
import { collection, query, where, orderBy, limit } from "firebase/firestore";
import { useMemoFirebase } from "@/firebase/provider";
import { useCollection } from "@/firebase/firestore/use-collection";

function useChatMessages(chatId: string) {
  const q = useMemoFirebase(
    () =>
      query(
        collection(db, "chats", chatId, "messages"),
        orderBy("createdAt", "desc"),
        limit(100)
      ),
    [chatId]
  );

  return useCollection(q);
}
```

## CLS Protection — Examples

### Image / Video in MessageMedia.tsx

```tsx
<div
  style={{ aspectRatio: `${width} / ${height}` }}
  className="max-w-[320px] overflow-hidden rounded-lg"
>
  <img src={url} alt="" className="h-full w-full object-cover" />
</div>
```

### Video with First-Frame Prefetch

```tsx
<video src={`${videoUrl}#t=0.1`} preload="metadata" />
```

### LinkPreview Fixed Height

```tsx
<div className="h-[80px] overflow-hidden rounded border">
  {/* preview content */}
</div>
```

## Pagination Strategy

```
┌────────────────────────────────────┐
│  onSnapshot (latest 100 messages)  │  ← Live window, real-time
├────────────────────────────────────┤
│  getDocs batch 1 (50 messages)     │  ← Loaded on scroll-up
├────────────────────────────────────┤
│  getDocs batch 2 (50 messages)     │  ← Loaded on next scroll-up
└────────────────────────────────────┘
```

- The live `onSnapshot` listener covers the most recent 100 messages.
- When the user scrolls past these, fetch older pages with `getDocs` in chunks of 50.
- Use `react-virtuoso` `firstItemIndex` to maintain scroll position.

## Protected Features (DO NOT Remove)

The following features must never be deleted or broken without explicit instruction:

1. **Reactions** — emoji reactions on messages
2. **Threads** — threaded replies (`ThreadWindow.tsx`)
3. **Calls / Meetings** — video/audio calls (`MeetingRoom.tsx`)
4. **Pins** — pinned messages
5. **Bulk Actions** — multi-select message operations
6. **Gestures** — swipe-to-reply, long-press menus
