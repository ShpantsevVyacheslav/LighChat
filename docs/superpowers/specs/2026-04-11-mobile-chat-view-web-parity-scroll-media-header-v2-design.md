# Mobile Chat View Web-Parity Design v2 (Scroll, Date, Media, Video)

Date: 2026-04-11  
Scope: Mobile chat behavior parity with web, including final reverse-scroll fix, sticky date correctness, media alignment/sizing/aspect handling, rounded media containers, and video preview/viewer behavior.

## 1) Goals

- Permanently fix the top-edge reverse-scroll bug where reaching oldest loaded history can redirect viewport to newest messages.
- Ensure sticky date tag always reflects the actual top visible day while scrolling.
- Make media rendering parity-compliant with web:
  - sender-based alignment (mine right / incoming left),
  - type-based max widths,
  - realistic image/video preview aspect behavior,
  - consistent rounded containers,
  - compact spacing.
- Implement web-like video behavior in chat messages:
  - inline preview in list,
  - fullscreen viewer on tap,
  - preserve separate video-circle logic.

## 2) Non-goals

- No backend schema/rules/API changes.
- No redesign of message permissions, reactions, edit/delete semantics.
- No replacement of current architecture with sliver rewrite.

## 3) Problem statement update (from latest feedback)

- Even after prior fixes, reaching upper boundary can still jump down to latest message.
- Sticky date in header does not always update to the currently visible day.
- Media spacing remains too large.
- Outgoing media is rendered left-aligned instead of right-aligned.
- Preview rendering does not consistently reflect real media orientation (landscape/portrait/square).
- Media containers must be uniformly rounded and images should fit standard container rules.
- Video path should follow web model (preview in feed + fullscreen viewer), with circles handled by existing dedicated logic.

## 4) Architecture decisions

### 4.1 Final reverse-scroll hardening (keep anchor, prevent downward redirect)

Anchor remains required. Removing anchor would reintroduce viewport drift when older items are inserted at top in reverse list.

Add strict cycle invariants in `ChatScreen`:
- `historyCycleId` for each top-load attempt.
- Snapshot at load start:
  - `anchorMessageId`, `anchorDy`, `baseCount`, `baseExtent`.
- Global guard flag: `_suppressAutoScrollToBottom = true` during active top-load cycle.
- Any `animateTo(0)` / jump-to-bottom path must no-op while suppression is active.
- Restore runs only after real growth (`count > baseCount` OR `extent > baseExtent`).
- Two-pass restore with tolerance <=2px.
- Complete cycle only after restore/fallback completion, then clear suppression.

### 4.2 Sticky date as viewport truth

- Sticky date label is derived strictly from top-visible message in viewport.
- Recompute on scroll ticks + post-frame probe updates.
- Header date chip updates immediately on day transition.
- Sticky chip position reserved under glass header safe-zone to avoid overlap.

### 4.3 Media parity model

Tokenized max widths (web parity constants):
- normal media grid: `208`
- GIF-only grid: `416`
- location card: `468`

Apply width rule:
`effectiveWidth = min(availableMessageWidth, typeMaxWidth)`

Alignment:
- outgoing media block right-aligned,
- incoming media block left-aligned.

Aspect behavior:
- Use attachment `width/height` when present to derive preview ratio.
- Fallback ratio when metadata missing.
- Preserve orientation distinction (portrait/landscape/square).

Container styling:
- all image-based media containers rounded with unified radius token,
- content fit policy standardized (`cover` in bounded card, not unbounded stretch).

Spacing:
- remove nested additive margins/paddings,
- enforce compact matrix for media-to-media, media-to-caption, message-to-message.

### 4.4 Video behavior parity with web

- Standard video attachment in feed:
  - inline preview card with play affordance,
  - tap opens fullscreen video viewer route/dialog.
- Do not introduce heavy inline seek player for standard videos in list.
- Video-circle remains separate component/path (unchanged conceptually).

## 5) Files to change

- `mobile/app/lib/features/chat/ui/chat_screen.dart`
  - top-load cycle hardening, auto-scroll suppression, sticky date safety/updates.
- `mobile/app/lib/features/chat/ui/chat_message_list.dart`
  - top-visible event fidelity, sender-based media alignment, spacing cleanup.
- `mobile/app/lib/features/chat/ui/message_attachments.dart`
  - type-based width constraints and aspect-aware preview containers.
- `mobile/app/lib/features/chat/ui/message_video_attachment.dart`
  - standard video preview card tuning for list usage.
- `mobile/app/lib/features/chat/ui/chat_header.dart`
  - ensure sticky date/header composition remains readable in scroll states.
- `mobile/app/lib/features/chat/data/chat_media_layout_tokens.dart`
  - source-of-truth sizing/spacing/radius tokens.

## 6) Validation criteria

### Scroll stability
- 30 repeated top-edge loads without redirect to newest.
- no downward jump when user reaches oldest currently loaded message.

### Sticky date correctness
- date chip always matches top visible day during slow and fast scroll.

### Media parity
- outgoing media right, incoming media left.
- widths obey 208/416/468 policy by type.
- visible orientation fidelity (portrait/landscape/square) in previews.
- rounded containers applied consistently.
- spacing visually compact and web-like.

### Video parity
- standard video opens fullscreen viewer from inline preview.
- video-circle behavior remains isolated and functional.

## 7) Risks and mitigations

- Risk: hidden auto-scroll paths still force move to bottom.  
  Mitigation: centralized `_suppressAutoScrollToBottom` guard and grep-based audit of all scroll-to-bottom calls.

- Risk: orientation jitter while image dimensions resolve.  
  Mitigation: placeholder aspect fallback + stable bounded container.

- Risk: sticky date lag under high-frequency scroll.  
  Mitigation: combine scroll listener updates with post-frame top-visible reconciliation.

## 8) Required implementation self-review

Subagent self-review must explicitly verify:
- no-bounce invariant at top boundary,
- date chip correctness under aggressive scroll,
- outgoing/incoming media alignment correctness,
- aspect handling + rounded containers,
- video preview -> fullscreen flow parity and circle path non-regression.
