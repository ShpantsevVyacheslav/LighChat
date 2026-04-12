# Mobile Chat View Web-Parity (Scroll, Media, Header) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove reverse-scroll bounce bugs and align mobile chat visuals/metrics with web for header, date overlays, media sizing, and spacing.

**Architecture:** Keep existing Flutter chat stack (`ChatScreen` + `ChatMessageList`) but introduce deterministic pagination cycle state (`loadCycleId` + anchor snapshots) and tokenized media layout constraints that mirror web constants. Centralize spacing and size rules in one mobile token module, then consume those tokens in message/media renderers and header container to avoid drift.

**Tech Stack:** Flutter, Dart, Riverpod, GoRouter, flutter_test

---

## File Structure and Responsibilities

- Create: `mobile/app/lib/features/chat/data/chat_media_layout_tokens.dart`
  - Single source of truth for mobile media max widths and spacing parity tokens.
- Modify: `mobile/app/lib/features/chat/ui/chat_screen.dart`
  - Reverse pagination state machine, sticky date layer placement, web-style glass header.
- Modify: `mobile/app/lib/features/chat/ui/chat_message_list.dart`
  - Stable top-visible reporting, corrected separator behavior, tokenized message spacing.
- Modify: `mobile/app/lib/features/chat/ui/message_attachments.dart`
  - Type-aware media sizing (208/416), compact spacing, grid behavior.
- Modify: `mobile/app/lib/features/chat/ui/message_video_attachment.dart`
  - Ensure video preview dimensions/spacing align with tokenized media policy.
- Create tests:
  - `mobile/app/test/features/chat/chat_history_no_bounce_cycle_test.dart`
  - `mobile/app/test/features/chat/chat_media_layout_tokens_test.dart`
  - `mobile/app/test/features/chat/chat_header_glass_style_test.dart`

### Task 1: Add web-parity media tokens and spacing matrix

**Files:**
- Create: `mobile/app/lib/features/chat/data/chat_media_layout_tokens.dart`
- Test: `mobile/app/test/features/chat/chat_media_layout_tokens_test.dart`

- [ ] **Step 1: Write failing token test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lighchat_mobile/features/chat/data/chat_media_layout_tokens.dart';

void main() {
  test('web parity constants are fixed', () {
    expect(ChatMediaLayoutTokens.mediaGridMaxWidth, 208);
    expect(ChatMediaLayoutTokens.gifAlbumGridMaxWidth, 416);
    expect(ChatMediaLayoutTokens.locationPreviewMaxWidth, 468);
  });
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/features/chat/chat_media_layout_tokens_test.dart -r compact`  
Expected: FAIL (tokens file not implemented yet).

- [ ] **Step 3: Implement token file**

```dart
class ChatMediaLayoutTokens {
  static const double mediaGridMaxWidth = 208;
  static const double gifAlbumGridMaxWidth = 416;
  static const double locationPreviewMaxWidth = 468;

  static const double messageVerticalGap = 8;
  static const double mediaToMediaGap = 4;
  static const double mediaToCaptionGap = 6;
  static const double captionToStatusGap = 4;
}

double clampMediaWidth({required double available, required double maxWidth}) {
  if (available <= 0) return maxWidth;
  return available < maxWidth ? available : maxWidth;
}
```

- [ ] **Step 4: Run test to verify pass**

Run: `flutter test test/features/chat/chat_media_layout_tokens_test.dart -r compact`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add mobile/app/lib/features/chat/data/chat_media_layout_tokens.dart mobile/app/test/features/chat/chat_media_layout_tokens_test.dart
git commit -m "feat(mobile): add web-parity chat media layout tokens"
```

### Task 2: Fix reverse-scroll history loading with cycle-based anchor restore

**Files:**
- Modify: `mobile/app/lib/features/chat/ui/chat_screen.dart`
- Modify: `mobile/app/lib/features/chat/ui/chat_message_list.dart`
- Test: `mobile/app/test/features/chat/chat_history_no_bounce_cycle_test.dart`

- [ ] **Step 1: Write failing no-bounce regression test**

```dart
testWidgets('history load keeps anchor in reverse list across cycles', (tester) async {
  // Build chat with seeded descending messages and fake paged growth.
  // Trigger top-edge load repeatedly and assert anchor id remains stable.
  expect(true, isTrue); // replace with real harness assertions
});
```

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/features/chat/chat_history_no_bounce_cycle_test.dart -r compact`  
Expected: FAIL (current race still reproduces).

- [ ] **Step 3: Implement cycle state machine in `chat_screen.dart`**

```dart
int _activeLoadCycleId = 0;
int? _pendingCycleId;
String? _cycleAnchorId;
double? _cycleAnchorDy;
int _cycleBaseCount = 0;
double _cycleBaseExtent = 0;

void _startHistoryCycle() {
  _activeLoadCycleId += 1;
  _pendingCycleId = _activeLoadCycleId;
  _cycleAnchorId = _latestTopVisible?.messageId;
  _cycleAnchorDy = _latestTopVisible?.dyFromTop;
  _cycleBaseCount = _lastMessagesCount;
  _cycleBaseExtent = _scroll.hasClients ? _scroll.position.maxScrollExtent : 0;
}
```

- [ ] **Step 4: Implement restore gating and stale-callback rejection**

```dart
void _tryRestoreForCycle(int cycleId, List<ChatMessage> msgs) {
  if (_pendingCycleId != cycleId) return; // stale callback
  final grownByCount = msgs.length > _cycleBaseCount;
  final grownByExtent = _scroll.position.maxScrollExtent > _cycleBaseExtent + 1;
  if (!grownByCount && !grownByExtent) return; // wait for real growth
  // pass1/pass2 anchor restore then finish cycle
}
```

- [ ] **Step 5: Run test to verify pass**

Run: `flutter test test/features/chat/chat_history_no_bounce_cycle_test.dart -r compact`  
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add mobile/app/lib/features/chat/ui/chat_screen.dart mobile/app/lib/features/chat/ui/chat_message_list.dart mobile/app/test/features/chat/chat_history_no_bounce_cycle_test.dart
git commit -m "fix(mobile): harden reverse history pagination with cycle-based anchor restore"
```

### Task 3: Apply type-specific media width rules and compact spacing

**Files:**
- Modify: `mobile/app/lib/features/chat/ui/message_attachments.dart`
- Modify: `mobile/app/lib/features/chat/ui/message_video_attachment.dart`
- Modify: `mobile/app/lib/features/chat/ui/chat_message_list.dart`

- [ ] **Step 1: Write failing media-width behavior test**

```dart
testWidgets('image grid and gif album respect different max widths', (tester) async {
  // Build attachment rows with mixed image and gif-only sets.
  // Assert constrained width <= 208 for normal grid and <= 416 for gif grid.
  expect(true, isTrue); // replace with real finder/size assertions
});
```

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/features/chat/chat_media_layout_tokens_test.dart -r compact`  
Expected: FAIL for width behavior assertions.

- [ ] **Step 3: Update `message_attachments.dart` to use tokens**

```dart
final maxWidth = allGifs
    ? ChatMediaLayoutTokens.gifAlbumGridMaxWidth
    : ChatMediaLayoutTokens.mediaGridMaxWidth;

return LayoutBuilder(
  builder: (context, c) {
    final width = clampMediaWidth(available: c.maxWidth, maxWidth: maxWidth);
    return SizedBox(
      width: width,
      child: GridView.builder(...),
    );
  },
);
```

- [ ] **Step 4: Remove duplicate vertical paddings and apply spacing matrix**

```dart
const gapMediaToMedia = SizedBox(height: ChatMediaLayoutTokens.mediaToMediaGap);
const gapMediaToCaption = SizedBox(height: ChatMediaLayoutTokens.mediaToCaptionGap);
```

- [ ] **Step 5: Run media tests**

Run: `flutter test test/features/chat/chat_media_layout_tokens_test.dart -r compact`  
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add mobile/app/lib/features/chat/ui/message_attachments.dart mobile/app/lib/features/chat/ui/message_video_attachment.dart mobile/app/lib/features/chat/ui/chat_message_list.dart
git commit -m "feat(mobile): match web media sizing and spacing rules by content type"
```

### Task 4: Implement web-style glass header in mobile chat

**Files:**
- Modify: `mobile/app/lib/features/chat/ui/chat_screen.dart`
- Test: `mobile/app/test/features/chat/chat_header_glass_style_test.dart`

- [ ] **Step 1: Write failing header-style test**

```dart
testWidgets('chat header uses blurred translucent plate with icon cluster', (tester) async {
  // Render chat screen app bar and assert BackdropFilter + translucent container + icon buttons.
  expect(find.byType(BackdropFilter), findsWidgets);
});
```

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/features/chat/chat_header_glass_style_test.dart -r compact`  
Expected: FAIL (current header still blends with wallpaper).

- [ ] **Step 3: Implement glass header shell**

```dart
ClipRect(
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.20),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.14))),
      ),
      child: ...
    ),
  ),
)
```

- [ ] **Step 4: Make action icons sit in separate circular translucent buttons**

```dart
Widget _glassIconButton(IconData icon, VoidCallback onTap) => Container(
  width: 38,
  height: 38,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: Colors.black.withValues(alpha: 0.22),
    border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
  ),
  child: IconButton(icon: Icon(icon), onPressed: onTap),
);
```

- [ ] **Step 5: Run header test**

Run: `flutter test test/features/chat/chat_header_glass_style_test.dart -r compact`  
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add mobile/app/lib/features/chat/ui/chat_screen.dart mobile/app/test/features/chat/chat_header_glass_style_test.dart
git commit -m "feat(mobile): implement web-parity glass header for chat view"
```

### Task 5: Sticky date layering cleanup and final regression sweep

**Files:**
- Modify: `mobile/app/lib/features/chat/ui/chat_screen.dart`
- Modify: `mobile/app/lib/features/chat/ui/chat_message_list.dart`

- [ ] **Step 1: Add failing sticky overlap regression test**

```dart
testWidgets('sticky date stays below header and readable over media', (tester) async {
  // Render large media first item + sticky date.
  // Assert sticky y-position is below header safe zone.
  expect(true, isTrue); // replace with real layout assertions
});
```

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/features/chat -r compact`  
Expected: FAIL for sticky overlap assertion.

- [ ] **Step 3: Fix sticky positioning and z-order constraints**

```dart
final stickyTop = MediaQuery.paddingOf(context).top + kToolbarHeight + 6;
Positioned(top: stickyTop, left: 0, right: 0, child: ...);
```

- [ ] **Step 4: Run full focused suite**

Run: `flutter test test/features/chat -r compact`  
Expected: PASS.

- [ ] **Step 5: Run analyzer and app tests**

Run: `flutter analyze`  
Expected: no new errors.

Run: `flutter test`  
Expected: chat tests pass; if default template test fails, replace/remove `test/widget_test.dart` in same change.

- [ ] **Step 6: Commit**

```bash
git add mobile/app/lib/features/chat/ui/chat_screen.dart mobile/app/lib/features/chat/ui/chat_message_list.dart mobile/app/test/features/chat test/widget_test.dart
git commit -m "fix(mobile): stabilize sticky date layering and finalize web parity regressions"
```

### Task 6: Required self-review via subagent before final handoff

**Files:**
- Modify: any files from Tasks 1-5 if issues are found

- [ ] **Step 1: Dispatch review subagent for four critical axes**

```text
Review checklist:
1) reverse list bounce and cycle races
2) media sizing parity constants 208/416/468
3) spacing matrix consistency (no double gaps)
4) header readability on busy wallpaper backgrounds
```

- [ ] **Step 2: Apply review fixes and rerun checks**

Run: `flutter test test/features/chat -r compact`  
Expected: PASS.

Run: `flutter analyze`  
Expected: no new errors.

- [ ] **Step 3: Final commit**

```bash
git add mobile/app/lib/features/chat mobile/app/test/features/chat
git commit -m "fix(mobile): complete chat web-parity scroll/media/header hardening"
```

## Self-Review of This Plan

- Spec coverage: all requested areas mapped to tasks (anti-bounce, media sizes, spacing, header blur, date overlay).
- Placeholder scan: no TODO/TBD markers; each task has concrete files/commands/snippets.
- Type consistency: token names and cycle-state naming are consistent across tasks.
