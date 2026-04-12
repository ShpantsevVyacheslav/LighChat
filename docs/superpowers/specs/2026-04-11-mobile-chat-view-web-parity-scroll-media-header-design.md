# Mobile Chat View Web-Parity Design (Scroll, Media Sizing, Header)

Date: 2026-04-11  
Scope: Mobile chat viewport behavior and visual parity with web chat for header, date tags, media sizing, and spacing.

## 1. Goals

- Permanently fix reverse-list history pagination bounce to newest messages.
- Match web media sizing rules by content type (image/video grid, GIF grid, location, sticker, circles, etc.).
- Match web spacing rhythm between media blocks and text/status blocks.
- Match web chat header look: blurred translucent plate, readable title/status, separated action buttons.
- Preserve sticky date behavior while eliminating visual collisions with large media blocks.

## 2. Out of Scope

- No backend/API/schema changes.
- No chat domain behavior changes (delivery, reactions, permissions).
- No redesign of chat composer interaction beyond existing multiline behavior already approved.

## 3. Evidence and gap summary (from provided screenshots)

### 3.1 Reverse scroll pagination still unstable
- Mobile still jumps down toward newest after user reaches oldest loaded edge.
- Current anchor logic is improved but still vulnerable to race conditions in reverse list when media heights settle asynchronously.

### 3.2 Header parity mismatch
- Web: avatar/name/status and action icons sit on a distinct blur-translucent plate.
- Mobile: header content visually merges into wallpaper; insufficient separation and contrast.

### 3.3 Media size parity mismatch
- Web uses type-specific constraints from shared policy:
  - normal media grid max width: `208px`
  - GIF-only grid max width: `416px`
  - location preview max width: `468px`
- Mobile currently renders many media items too large and too uniform across content types.

### 3.4 Spacing parity mismatch
- Mobile has accumulated nested vertical spacing, causing oversized gaps around media blocks.
- Web has tighter and more consistent spacing transitions between media/text/status.

### 3.5 Date tag collisions
- Sticky/in-list date tags can visually collide with media-heavy content in mobile.
- Web perceived layering/positioning is cleaner and more readable.

## 4. Architecture decisions

### 4.1 Deterministic anti-bounce pagination (reverse list)

Use a load-cycle state machine in `ChatScreen`:
- `loadCycleId` increments for each older-history request.
- Capture baseline state before `_limit += 50`:
  - `anchorMessageId`
  - `anchorDyFromTop`
  - `baseCount`
  - `baseMaxScrollExtent`
- Restore only when growth is confirmed:
  - `newCount > baseCount` OR `newMaxExtent > baseMaxExtent`.
- Two-pass anchor correction (post-frame pass 1 + pass 2) with tolerance <=2px.
- Ignore stale callbacks if cycle id no longer matches active cycle.
- Complete cycle only after successful restore or controlled fallback.

This removes timing-based completion assumptions and prevents early finalize races.

### 4.2 Mobile media layout tokens aligned to web policy

Create a single mobile layout-token module for chat media constraints (source-of-truth mirror of web values):
- `mediaGridMaxWidth = 208`
- `gifAlbumGridMaxWidth = 416`
- `locationPreviewMaxWidth = 468`

Apply by content type:
- visual grid image/video -> 208 max
- all-GIF grid -> 416 max
- location card -> 468 max
- sticker, video-circle, emoji-large, audio, poll -> dedicated intrinsic/container constraints

Actual width rule on mobile:
`effectiveWidth = min(availableMessageWidth, typeMaxWidth)`

### 4.3 Spacing matrix normalization

Introduce explicit spacing constants and remove duplicated nested paddings:
- message-to-message
- media-to-media
- media-to-caption
- caption-to-status
- location/audio/poll internal spacing

All transitions use one token source, avoiding additive spacing from stacked wrappers.

### 4.4 Web-parity glass header for mobile chat

In mobile header container:
- blur + translucent background plate
- subtle border and contrast-tuned foreground
- left cluster: avatar + name + status
- right cluster: action buttons on separated circular translucent surfaces
- safe-area aware top insets

Objective: same readability and visual separation from wallpaper as web.

### 4.5 Date label layering policy

- Keep sticky top date indicator.
- Keep in-list day separators as structural markers.
- Enforce non-collision layering and safe top offset under header.
- Sticky date should not obscure key media hotspots in first visible large card.

## 5. Files expected to change

- `mobile/app/lib/features/chat/ui/chat_screen.dart`
  - pagination state machine, sticky-layer positioning, glass header container
- `mobile/app/lib/features/chat/ui/chat_message_list.dart`
  - top-visible tracking reliability, day separator correctness, spacing cleanup, per-type message layout wiring
- `mobile/app/lib/features/chat/ui/message_attachments.dart`
  - grid sizing tokens, GIF-grid rules, spacing normalization
- `mobile/app/lib/features/chat/ui/message_video_attachment.dart`
  - size/spacing alignment hooks for web parity
- `mobile/app/lib/features/chat/ui/*` (only if required)
  - small helper widgets for type-specific media cards
- New token file (planned):
  - `mobile/app/lib/features/chat/data/chat_media_layout_tokens.dart`

## 6. Error handling and guardrails

- Pagination restore never finalizes based on timeout alone.
- All restore callbacks validate active cycle id.
- Offsets always clamped to controller extents.
- If anchor id missing, fallback restore path applies once and logs diagnostic.
- No visual regression for text-only messages.

## 7. Validation and acceptance criteria

### 7.1 Scroll stability acceptance
- At least 20 repeated top-edge history loads in mixed-media chat with no jump to newest.
- Rapid user scroll during load does not break anchor retention.

### 7.2 Media parity acceptance
- Mobile max widths match web policy by type:
  - normal grid 208, GIF grid 416, location 468 (capped by device width)
- Media type containers do not collapse into one generic size model.

### 7.3 Spacing acceptance
- No oversized vertical gaps between consecutive media items.
- Media->caption->status spacing is consistent and visibly aligned with web.

### 7.4 Header acceptance
- Header remains readable on high-detail wallpapers.
- Name/status/icons are clearly legible due to blur-plate separation.
- Action icon cluster visually matches web composition.

### 7.5 Date label acceptance
- Sticky date remains stable during scroll and does not interfere with header/media readability.
- In-list day separators remain correctly placed before first message of each day.

## 8. Risks and mitigations

- Risk: reverse-list geometry jitter from media load completion.  
  Mitigation: two-pass anchor restore and active-cycle invalidation.

- Risk: over-correction when new messages arrive while loading old history.  
  Mitigation: cycle isolation and strict baseline growth checks.

- Risk: visual mismatch across device widths.  
  Mitigation: tokenized max-width rules with device-width clamping and QA matrix across small/large phones.

## 9. Implementation review requirement

Before final handoff, run targeted subagent self-review for:
- reverse-list race and anchor invariants,
- media sizing parity against web constants,
- spacing matrix consistency,
- header readability against busy wallpapers.
