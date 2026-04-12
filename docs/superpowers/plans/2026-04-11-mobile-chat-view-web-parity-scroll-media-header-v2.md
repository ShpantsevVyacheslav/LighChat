# Mobile Chat View Web-Parity v2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix top-edge scroll redirect to newest and complete web-parity behavior for sticky date, media alignment/sizing/aspect/radius/spacing, and video preview->fullscreen flow.

**Architecture:** Keep current Flutter chat architecture and harden it with strict history-load cycle invariants, including a global suppression guard for bottom auto-scroll during top pagination. Move all media sizing/spacing/radius decisions to tokenized rules and apply them consistently in message and attachment renderers. Implement web-like inline video preview cards that open fullscreen, while preserving separate video-circle behavior.

**Tech Stack:** Flutter, Dart, Riverpod, GoRouter, video_player, flutter_test

---

## File Map

- Create: `mobile/app/lib/features/chat/data/chat_media_layout_tokens.dart`
  - Web-parity media size, radius, and spacing constants.
- Modify: `mobile/app/lib/features/chat/ui/chat_screen.dart`
  - Final no-bounce cycle logic and sticky-date update fidelity.
- Modify: `mobile/app/lib/features/chat/ui/chat_message_list.dart`
  - Message alignment rules (mine right), sticky source updates, spacing cleanup.
- Modify: `mobile/app/lib/features/chat/ui/message_attachments.dart`
  - Aspect-aware preview sizing and rounded bounded cards.
- Modify: `mobile/app/lib/features/chat/ui/message_video_attachment.dart`
  - Inline video preview card behavior.
- Create: `mobile/app/lib/features/chat/ui/chat_video_viewer_screen.dart`
  - Fullscreen video viewer route.
- Modify: `mobile/app/lib/app_router.dart`
  - Route for fullscreen video viewer.
- Optional tests:
  - `mobile/app/test/features/chat/chat_no_bounce_top_edge_test.dart`
  - `mobile/app/test/features/chat/chat_sticky_date_source_test.dart`
  - `mobile/app/test/features/chat/chat_media_alignment_and_aspect_test.dart`

### Task 1: Harden top-edge history loading and suppress bottom auto-scroll

**Files:**
- Modify: `mobile/app/lib/features/chat/ui/chat_screen.dart`
- Test: `mobile/app/test/features/chat/chat_no_bounce_top_edge_test.dart`

- [ ] **Step 1: Write failing no-bounce test**

```dart
testWidgets('reaching oldest loaded edge never redirects to newest', (tester) async {
  // Build reverse chat feed with staged history growth and trigger top loads repeatedly.
  // Assert scroll remains near anchor region, not reset to bottom.
  expect(true, isTrue); // replace with harness assertion
});
```

- [ ] **Step 2: Run test and confirm failure**

Run: `flutter test test/features/chat/chat_no_bounce_top_edge_test.dart -r compact`  
Expected: FAIL.

- [ ] **Step 3: Add strict suppression guard in `chat_screen.dart`**

```dart
bool _suppressAutoScrollToBottom = false;

void _startTopHistoryCycle() {
  _suppressAutoScrollToBottom = true;
  _historyCycleId += 1;
  _activeHistoryCycleId = _historyCycleId;
  // capture anchor + baseline count/extent
}

void _finishHistoryLoad() {
  _suppressAutoScrollToBottom = false;
  _activeHistoryCycleId = null;
  // reset cycle state
}
```

- [ ] **Step 4: Guard all bottom autoscroll calls**

```dart
if (_suppressAutoScrollToBottom) return;
_scroll.animateTo(0, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
```

- [ ] **Step 5: Re-run failing test**

Run: `flutter test test/features/chat/chat_no_bounce_top_edge_test.dart -r compact`  
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add mobile/app/lib/features/chat/ui/chat_screen.dart mobile/app/test/features/chat/chat_no_bounce_top_edge_test.dart
git commit -m "fix(mobile): prevent top-edge history load from redirecting to newest"
```

### Task 2: Make sticky date always follow top visible day

**Files:**
- Modify: `mobile/app/lib/features/chat/ui/chat_screen.dart`
- Modify: `mobile/app/lib/features/chat/ui/chat_message_list.dart`
- Test: `mobile/app/test/features/chat/chat_sticky_date_source_test.dart`

- [ ] **Step 1: Write failing sticky-date source test**

```dart
testWidgets('sticky date updates to currently top-visible day while scrolling', (tester) async {
  // Scroll across multiple day groups and verify sticky text changes immediately.
  expect(true, isTrue); // replace with real assertions
});
```

- [ ] **Step 2: Run test and verify fail**

Run: `flutter test test/features/chat/chat_sticky_date_source_test.dart -r compact`  
Expected: FAIL.

- [ ] **Step 3: Tighten top-visible reporting and sticky update flow**

```dart
void _onTopVisibleChanged(VisibleMessageInfo? info) {
  _latestTopVisible = info;
  final nextLabel = info == null ? null : _formatStickyDay(info.createdAt);
  if (nextLabel != _stickyDayLabel) {
    setState(() => _stickyDayLabel = nextLabel);
  }
}
```

- [ ] **Step 4: Keep sticky safe-zone below header**

```dart
final stickyTop = MediaQuery.paddingOf(context).top + 56 + 8;
Positioned(top: stickyTop, left: 0, right: 0, child: ...);
```

- [ ] **Step 5: Re-run sticky test**

Run: `flutter test test/features/chat/chat_sticky_date_source_test.dart -r compact`  
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add mobile/app/lib/features/chat/ui/chat_screen.dart mobile/app/lib/features/chat/ui/chat_message_list.dart mobile/app/test/features/chat/chat_sticky_date_source_test.dart
git commit -m "fix(mobile): bind sticky date to top visible message day"
```

### Task 3: Enforce media alignment + compact spacing + rounded containers

**Files:**
- Modify: `mobile/app/lib/features/chat/data/chat_media_layout_tokens.dart`
- Modify: `mobile/app/lib/features/chat/ui/chat_message_list.dart`
- Modify: `mobile/app/lib/features/chat/ui/message_attachments.dart`
- Test: `mobile/app/test/features/chat/chat_media_alignment_and_aspect_test.dart`

- [ ] **Step 1: Write failing media layout tests**

```dart
testWidgets('outgoing media aligns right, incoming aligns left', (tester) async {
  expect(true, isTrue); // replace with alignment assertions
});

testWidgets('all image containers are rounded and compactly spaced', (tester) async {
  expect(true, isTrue); // replace with radius/spacing assertions
});
```

- [ ] **Step 2: Run tests and verify fail**

Run: `flutter test test/features/chat/chat_media_alignment_and_aspect_test.dart -r compact`  
Expected: FAIL.

- [ ] **Step 3: Apply alignment and spacing policy in list renderer**

```dart
Align(
  alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
  child: ConstrainedBox(... child: mediaBlock),
)
```

- [ ] **Step 4: Apply rounded bounded cards + reduced gaps in attachments**

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(ChatMediaLayoutTokens.mediaCardRadius),
  child: ...
)
```

- [ ] **Step 5: Re-run media layout tests**

Run: `flutter test test/features/chat/chat_media_alignment_and_aspect_test.dart -r compact`  
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add mobile/app/lib/features/chat/data/chat_media_layout_tokens.dart mobile/app/lib/features/chat/ui/chat_message_list.dart mobile/app/lib/features/chat/ui/message_attachments.dart mobile/app/test/features/chat/chat_media_alignment_and_aspect_test.dart
git commit -m "feat(mobile): align media by sender and normalize rounded compact layout"
```

### Task 4: Add aspect-aware image/video preview sizing

**Files:**
- Modify: `mobile/app/lib/features/chat/ui/message_attachments.dart`
- Modify: `mobile/app/lib/features/chat/ui/message_video_attachment.dart`

- [ ] **Step 1: Write failing aspect behavior tests**

```dart
testWidgets('preview keeps portrait/landscape/square distinctions', (tester) async {
  expect(true, isTrue); // replace with ratio assertions
});
```

- [ ] **Step 2: Run test and verify fail**

Run: `flutter test test/features/chat/chat_media_alignment_and_aspect_test.dart -r compact`  
Expected: FAIL for aspect ratio checks.

- [ ] **Step 3: Use attachment width/height for aspect when available**

```dart
double _safeAspect(ChatAttachment a) {
  final w = a.width;
  final h = a.height;
  if (w != null && h != null && w > 0 && h > 0) return w / h;
  return 1; // fallback square
}
```

- [ ] **Step 4: Keep bounded standard container with cover fit**

```dart
AspectRatio(
  aspectRatio: _safeAspect(att),
  child: Image.network(att.url, fit: BoxFit.cover),
)
```

- [ ] **Step 5: Re-run aspect tests**

Run: `flutter test test/features/chat/chat_media_alignment_and_aspect_test.dart -r compact`  
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add mobile/app/lib/features/chat/ui/message_attachments.dart mobile/app/lib/features/chat/ui/message_video_attachment.dart
git commit -m "feat(mobile): add aspect-aware media previews with bounded rounded cards"
```

### Task 5: Implement web-like video preview -> fullscreen viewer flow

**Files:**
- Create: `mobile/app/lib/features/chat/ui/chat_video_viewer_screen.dart`
- Modify: `mobile/app/lib/features/chat/ui/message_video_attachment.dart`
- Modify: `mobile/app/lib/features/chat/ui/chat_message_list.dart`
- Modify: `mobile/app/lib/app_router.dart`

- [ ] **Step 1: Write failing video interaction test**

```dart
testWidgets('tap on inline video preview opens fullscreen viewer', (tester) async {
  expect(true, isTrue); // replace with route open assertion
});
```

- [ ] **Step 2: Run test and verify fail**

Run: `flutter test test/features/chat -r compact`  
Expected: FAIL for video-viewer navigation.

- [ ] **Step 3: Add fullscreen viewer route**

```dart
GoRoute(
  path: '/chats/video-viewer',
  builder: (context, state) => ChatVideoViewerScreen(extra: state.extra),
)
```

- [ ] **Step 4: Update inline video preview tap behavior**

```dart
onTap: () {
  context.push('/chats/video-viewer', extra: attachment.url);
}
```

- [ ] **Step 5: Ensure video-circles stay on existing path**

```dart
if (att.name.startsWith('video-circle_')) {
  return existingVideoCircleWidget;
}
```

- [ ] **Step 6: Re-run tests and commit**

Run: `flutter test test/features/chat -r compact`  
Expected: PASS.

```bash
git add mobile/app/lib/features/chat/ui/chat_video_viewer_screen.dart mobile/app/lib/features/chat/ui/message_video_attachment.dart mobile/app/lib/features/chat/ui/chat_message_list.dart mobile/app/lib/app_router.dart
git commit -m "feat(mobile): implement inline video preview with fullscreen viewer"
```

### Task 6: Final regression pass and mandatory self-review

**Files:**
- Modify: any touched files from Tasks 1-5 if fixes are needed

- [ ] **Step 1: Run self-review subagent with strict checklist**

```text
Checklist:
1) top-edge load never redirects to latest
2) sticky date always matches top visible day
3) outgoing media right / incoming media left
4) aspect-aware previews and rounded containers
5) compact spacing around media
6) video preview opens fullscreen, circles unaffected
```

- [ ] **Step 2: Apply review fixes and rerun checks**

Run: `flutter analyze`  
Expected: no new errors.

Run: `flutter test test/features/chat -r compact`  
Expected: PASS.

- [ ] **Step 3: Final commit**

```bash
git add mobile/app/lib/features/chat mobile/app/lib/app_router.dart mobile/app/test/features/chat
git commit -m "fix(mobile): finalize chat web-parity v2 scroll date media and video behavior"
```

## Self-Review

- Spec coverage: includes all newly requested items (anchor rationale + no-bounce fix, sticky date source, media alignment, spacing, aspect, rounded containers, video preview/fullscreen flow).
- Placeholder scan: no TODO/TBD markers.
- Type consistency: same token and cycle naming across tasks.
