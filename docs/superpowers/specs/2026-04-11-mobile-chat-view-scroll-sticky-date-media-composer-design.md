# Mobile Chat View Stability & UX Parity Design

Date: 2026-04-11  
Scope: `mobile/app` chat message viewport behavior, date tag behavior, media bubble policy, composer multiline growth.

## 1) Goals and non-goals

### Goals
- Eliminate scroll "bounce to newest" when user reaches oldest loaded message and pagination loads older history.
- Make date label behavior correct and predictable: sticky date tag at top while scrolling, and per-day separators before first message of day.
- Render media without chat bubble background; for `media + text`, keep media free and render text/time in compact bubble below media.
- Make composer handle long text naturally (line wrap, growth up to 6 lines, then internal input scroll).
- Add explicit implementation requirement for self-review via subagent focused on scroll invariants and reverse-list edge cases.

### Non-goals
- No backend schema/rules changes.
- No new message types introduced in this task.
- No redesign of full chat header/actions/selection flows beyond what is necessary for the 4 goals.

## 2) Current issues summary

- Current pagination anchor uses `pixels/maxScrollExtent` delta strategy only; in reverse list with variable-height rows (media, async layout), this can drift and jump to newest.
- Date separator logic in reverse list is not aligned with "first message of day" semantics.
- Message bubble currently wraps media and text together; this violates parity requirement for media presentation.
- Composer uses single-line behavior and send-on-submit pattern not suitable for long multiline text composition.

## 3) Design overview

The change is a targeted refactor in existing chat UI files:
- `mobile/app/lib/features/chat/ui/chat_screen.dart`
- `mobile/app/lib/features/chat/ui/chat_message_list.dart`
- `mobile/app/lib/features/chat/ui/message_attachments.dart` (only if minor style hooks required)

Core strategy:
1. Replace fragile offset-only pagination restore with message-anchor restore (`anchorMessageId + anchorDyFromTop`) and two-pass correction.
2. Introduce sticky date overlay computed from top visible message in viewport.
3. Split message rendering into explicit variants (`text-only`, `media-only`, `media+text`) with hybrid policy.
4. Convert composer input to multiline growing field (`minLines=1`, `maxLines=6`).

## 4) Detailed component design

### 4.1 Pagination without jump (reverse list)

#### New invariant
After loading older history, the same previously top-visible message remains at the same visual offset from top viewport (within ~2 px tolerance).

#### State additions in `ChatScreen`
- `_historyLoadInFlight` (bool) to block parallel history loads.
- `_pendingAnchorMessageId` (String?) and `_pendingAnchorDy` (double?) captured before increasing `_limit`.
- `_pendingAnchorRestorePass` (int) for up to 2 post-frame restore attempts.

#### Flow
1. On near-oldest threshold, capture anchor from message list (top-visible message id + dy).
2. Set loading flag, increase `_limit`.
3. After new frame with loaded messages:
   - Find anchor message in new dataset.
   - Compute target offset to place anchor at captured dy.
   - `jumpTo(clamped)`.
4. Schedule second post-frame correction if delta remains > 1-2 px.
5. Clear pending anchor state.

#### Fallbacks
- If anchor id not found: use previous maxExtent delta fallback.
- If controller has no clients during restore: defer to next frame once.

### 4.2 Sticky date tag + correct day separators

#### Day separator rule
In timeline terms (ascending time), separator is rendered before first message of each day.
Reverse-list index math is fixed accordingly.

#### Sticky tag
- Add overlay in `ChatScreen` stack (`Positioned(top: 8, left/right centered)`).
- Text reflects day of top visible message in viewport.
- Hidden for empty list.
- Animated swap (`AnimatedSwitcher`, short fade/slide).

#### Source of truth
- Top visible message id/index tracked from list item geometry callback.
- Sticky label derived from that message `createdAt` (local date).

### 4.3 Media rendering policy (hybrid)

#### Variants
- `text-only`: existing text bubble style.
- `media-only`: no bubble background around media; optional lightweight time label outside bubble.
- `media+text`: media block first (bubble-less), compact text bubble below containing text/time/edited mark.

#### Interaction parity
- Selection and long-press gestures apply to whole message block, not only text bubble.
- Selected state shown with outer highlight stroke around full message block.

### 4.4 Composer multiline growth

In `_ChatComposer` input `TextField`:
- `minLines: 1`
- `maxLines: 6`
- `keyboardType: TextInputType.multiline`
- `textInputAction: TextInputAction.newline`

Behavior:
- Enter inserts newline.
- Send happens only by send button.
- Field grows up to 6 lines, then internal scroll.

## 5) Data flow and state transitions

### Pagination path
`scroll near oldest` -> `capture anchor` -> `_limit += 50` -> provider emits larger set -> post-frame anchor restore (1-2 passes) -> stable viewport.

### Sticky date path
`scroll` -> top visible message changes -> sticky day label recomputed -> animated label update.

### Message rendering path
`ChatMessage` content classification -> render variant tree (`text-only` / `media-only` / `media+text`) -> common gesture/select wrappers.

## 6) Error handling and safeguards

- Guard against duplicate pagination triggers while a load is active.
- Clamp all restored offsets to controller min/max extents.
- If geometry unavailable for anchor restore, fallback strategy is used and no hard failure is thrown.
- For media render failures, existing attachment-level placeholders remain unchanged.

## 7) Testing strategy

### Manual QA matrix (required)
1. Scroll to oldest loaded message repeatedly (5-10 cycles) in chats with mixed text/media; verify no jump to newest.
2. Verify sticky date follows top viewport day while scrolling up/down across multiple days.
3. Verify day separator appears before first message of each day (not under last message).
4. Verify media-only messages have no bubble background.
5. Verify media+text renders media first and compact text bubble below.
6. Verify composer growth from 1 to 6 lines and then internal scrolling.

### Implementation self-review (required by request)
Run a dedicated subagent self-review focused on:
- reverse list anchor invariants;
- race conditions between pagination restore and new incoming messages;
- sticky date correctness under rapid scrolling;
- selection/gesture regressions after media layout split.

## 8) Acceptance criteria

- No reproducible bounce-to-newest when loading older history at top edge.
- Sticky date tag is visible and correct during scroll across days.
- Per-day separator placement is correct (before first message of day).
- Media content has no bubble background.
- `media+text` uses hybrid layout (media then compact text bubble below).
- Composer supports multiline wrapping and growth up to 6 lines.

## 9) Rollout notes

- Changes are client-only (`mobile/app`).
- No migration or server deploy required.
- Keep architecture docs unchanged unless implementation introduces structure/runtime-flow changes beyond this scope.
